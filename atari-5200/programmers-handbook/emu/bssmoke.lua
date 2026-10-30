-- smoke.lua -- read the 5200 screen out of RAM and give a verdict.
--
-- Modelled on support/atari7800/smoke.lua. The screen is ANTIC mode 4, 40x26
-- at $3400 (src/atari5200/graphics.c), in the codes of support/atari/charset.fnt:
-- text is itself, art a lower-case letter or a symbol (~ sea, s ship, x hit,
-- o miss, m mark, p player, > active, a attack, c clock, + - = _ chrome,
-- # anything else). Bit 7 only picks the colour, so it is ignored.
--
--   FBS_AT      emulated seconds to settle before sampling; measured from the
--               end of FBS_SCRIPT when there is one
--   FBS_SETTLE  emulated seconds before the first step (default 8)
--   FBS_SCRIPT  comma-separated steps: fire back (the top and lower fire),
--               start pause reset star hash k0-k9 (the keypad), up down left
--               right (the stick), a chord like up+fire, waitN to idle N
--               emulated seconds, until:TEXT to wait (up to 120 s) for TEXT
--               on screen ('_' for a space, any case), BUTTON~TEXT to hold
--               BUTTON until TEXT shows (up to 10 s a press, then again: a
--               press made and let go inside a network call is never seen),
--               show to print the screen, snap to save a numbered PNG
--   FBS_EXPECT  substring that must appear on screen; sets the exit verdict
--   FBS_QUIET   only print the verdict, not the screen
--   FBS_SNAP    path of the final PNG; numbered "snap" steps derive from it
--   FBS_SCREEN  the screen's address (default 0x3400)

local AT      = tonumber(os.getenv("FBS_AT") or "8")
local EXPECT  = os.getenv("FBS_EXPECT")
if EXPECT == "" then EXPECT = nil end
local QUIET   = os.getenv("FBS_QUIET")
local SCRIPT  = os.getenv("FBS_SCRIPT")
local SETTLE  = tonumber(os.getenv("FBS_SETTLE") or "8")
local SNAP    = os.getenv("FBS_SNAP")
local SCREEN  = tonumber(os.getenv("FBS_SCREEN") or "0x3400")

local COLS, ROWS = 40, 26
local HOLD, GAP, LONG, RETRY, UNTIL_SECS = 0.15, 0.45, 10, 3, 120

-- What each charset code reads as.
local GLYPH = {}
for c = 0, 127 do GLYPH[c] = "#" end
GLYPH[0x00], GLYPH[0x40] = " ", " "
for c = 0x41, 0x5A do GLYPH[c] = string.char(c) end
for d = 0, 9 do
    GLYPH[0x10 + d] = tostring(d)
    GLYPH[0x70 + d] = tostring(d)       -- the clock's digits
end
GLYPH[0x01], GLYPH[0x0C], GLYPH[0x0D], GLYPH[0x0E], GLYPH[0x0F], GLYPH[0x1A] =
    "!", ",", "-", ".", "/", ":"
GLYPH[0x38] = "~"
GLYPH[0x39], GLYPH[0x1B], GLYPH[0x1C] = "x", "x", "x"
GLYPH[0x61] = "o"
for c = 0x32, 0x37 do GLYPH[c] = "s" end
GLYPH[0x2B], GLYPH[0x2A], GLYPH[0x5B], GLYPH[0x1D] = "m", "p", ">", "c"
GLYPH[0x3A] = "_"
for c = 0x3B, 0x3E do GLYPH[c] = "+" end
GLYPH[0x3F], GLYPH[0x62] = "-", "="
for c = 0x63, 0x68 do GLYPH[c] = "a" end

if _G.fbs_state == nil then
    _G.fbs_state = { step = 1, down = false, t_next = SETTLE, shots = 0 }
end
local st = _G.fbs_state

local function mem()
    return manager.machine.devices[":maincpu"].spaces["program"]
end

local function row(y)
    local m, s = mem(), {}
    for x = 0, COLS - 1 do
        s[#s + 1] = GLYPH[m:read_u8(SCREEN + y * COLS + x) & 0x7F]
    end
    return table.concat(s)
end

local function show(title)
    print(string.format("---- %s (%.1f s) ----", title, manager.machine.time:as_double()))
    for y = 0, ROWS - 1 do
        print(string.format("%2d|%s|", y, row(y)))
    end
end

local function on_screen(text)
    text = text:lower()
    for y = 0, ROWS - 1 do
        if row(y):lower():find(text, 1, true) then return true end
    end
    return false
end

local function snapshot(name)
    local err = manager.machine.screens[":screen"]:snapshot(name)
    emu.print_info("fbs: snap " .. name .. (err and (" FAILED: " .. tostring(err)) or ""))
end

local KEYS = {
    fire = { ":djoy_b", "P1 Button 1" }, back = { ":djoy_b", "P1 Button 2" },
    hash = { ":keypad.0", "[#]" }, star = { ":keypad.0", "[*]" }, k0 = { ":keypad.0", "[0]" },
    reset = { ":keypad.1", "Reset" }, k7 = { ":keypad.1", "[7]" },
    k8 = { ":keypad.1", "[8]" }, k9 = { ":keypad.1", "[9]" },
    pause = { ":keypad.2", "Pause" }, k4 = { ":keypad.2", "[4]" },
    k5 = { ":keypad.2", "[5]" }, k6 = { ":keypad.2", "[6]" },
    start = { ":keypad.3", "Start" }, k1 = { ":keypad.3", "[1]" },
    k2 = { ":keypad.3", "[2]" }, k3 = { ":keypad.3", "[3]" },
}
-- The stick: an analog axis pushed to an end, released to centre
local STICK = {
    up = { ":analog_1", "AD Stick Y", 0x00 }, down = { ":analog_1", "AD Stick Y", 0xE4 },
    left = { ":analog_0", "AD Stick X", 0x00 }, right = { ":analog_0", "AD Stick X", 0xE4 },
}

local function press(action, on)
    local ports = manager.machine.ioport.ports
    for b in action:gmatch("[^+]+") do
        local k, s = KEYS[b], STICK[b]
        if k then
            ports[k[1]].fields[k[2]]:set_value(on and 1 or 0)
        elseif s then
            local f = ports[s[1]].fields[s[2]]
            if on then f:set_value(s[3]) else f:clear_value() end
        else
            error("smoke.lua: unknown action '" .. b .. "'")
        end
    end
end

local script = {}
if SCRIPT then
    for a in SCRIPT:gmatch("[^,]+") do script[#script + 1] = a end
end

local function finish()
    if not QUIET then show("final") end
    local cpu = manager.machine.devices[":maincpu"]
    print(string.format("fbs: PC=%04X", cpu.state["PC"].value))
    if SNAP and SNAP ~= "" then snapshot(SNAP) end
    local ok = not st.failed
    if EXPECT then ok = ok and on_screen(EXPECT) end
    if EXPECT or st.failed then
        print("fbs: " .. (ok and "PASS" or "FAIL") .. (st.failed and (" " .. st.failed) or "")
              .. (EXPECT and (" expected " .. string.format("%q", EXPECT)) or ""))
    end
    manager.machine:exit()
end

-- Held over from the script chunk, or the next collection unsubscribes it.
_G.fbs_sub = emu.add_machine_frame_notifier(function()
    if st.done then return end
    local now = manager.machine.time:as_double()

    if st.step <= #script then
        if now < st.t_next then return end
        local a = script[st.step]
        local wait = a:match("^wait(%d*)$")
        local text = a:match("^until:(.*)$")
        local btn, want = a:match("^([%w+]+)~(.*)$")
        if btn then text = want end
        if a == "snap" or a == "show" then
            if a == "snap" then
                st.shots = st.shots + 1
                snapshot(((SNAP and SNAP ~= "") and SNAP or "snap.png"):gsub("%.png$", "")
                         .. "-" .. st.shots .. ".png")
            else
                show("step " .. st.step)
            end
            st.step = st.step + 1
        elseif wait then
            st.t_next = now + ((wait == "") and 1 or tonumber(wait))
            st.step = st.step + 1
        elseif text then
            text = text:gsub("_", " ")
            st.until_t0 = st.until_t0 or now
            local seen = on_screen(text)
            if st.down and (seen or now >= st.t_up) then
                press(btn, false)
                st.down = false
                if not seen then st.t_next = now + RETRY end
            elseif st.down then
                -- held: wait for the game
            elseif seen then
                print(string.format("fbs: saw %q at %.1f s", text, now))
                st.until_t0 = nil
                st.step = st.step + 1
                st.t_next = now + GAP
            elseif now - st.until_t0 > UNTIL_SECS then
                st.failed = "timed out waiting for " .. string.format("%q", text)
                st.done = true
                finish()
                return
            elseif btn then
                press(btn, true)
                st.down = true
                st.t_up = now + LONG
            end
        elseif st.down then
            press(a, false)
            st.down = false
            st.step = st.step + 1
            st.t_next = now + GAP
        else
            press(a, true)
            st.down = true
            st.t_next = now + HOLD
        end
        if st.step > #script then st.t_sample = math.max(now, st.t_next) + AT end
        return
    end

    if now < (st.t_sample or AT) then return end
    st.done = true
    finish()
end)
