-- smoke.lua -- read the Atari 5200 screen out of RAM and give a verdict.
--
-- The shape of support/atari7800/smoke.lua. The client draws on a 40 x 26
-- screen of ANTIC internal codes at $3000 (src/atari5200/antic.s) in the
-- 8-bit client's font: letters and digits read as themselves, card art as
-- "#", the chip as "o", box rules as + | -, the table's corners and trim
-- as "~". A row player 2 underlines is noted under it.
--
--   FCS_AT      emulated seconds to settle before sampling; measured from the
--               end of FCS_SCRIPT when there is one
--   FCS_SETTLE  emulated seconds before the first press (default 8)
--   FCS_SCRIPT  comma-separated actions to play first: fire b2 (the top and
--               lower buttons), up down left right (the stick), k0-k9 star
--               hash start pause reset (the keypad), any of them as name*S to
--               hold for S seconds, waitN to idle N emulated seconds (default
--               1), ?TEXT to wait (up to FCS_UNTIL seconds, default 60) until
--               TEXT is on screen (?A|B for either), shot to print the screen
--               and save a snapshot
--   FCS_EXPECT  substring that must appear on screen; sets the exit verdict
--   FCS_QUIET   only print the verdict, not the screen

local AT      = tonumber(os.getenv("FCS_AT") or "8")
local EXPECT  = os.getenv("FCS_EXPECT")
if EXPECT == "" then EXPECT = nil end   -- make/env hand through an empty string
local QUIET   = os.getenv("FCS_QUIET")
local SCRIPT  = os.getenv("FCS_SCRIPT")
local UNTIL   = tonumber(os.getenv("FCS_UNTIL") or "60")

local COLS, ROWS = 40, 26
local SCREEN = 0x3000
local P2 = 0x3E00                       -- player 2: the underline

local function mem()
    return manager.machine.devices[":maincpu"].spaces["program"]
end

-- ANTIC internal code (+$80 the red variant) to what it reads as.
local function glyph(c)
    c = c & 0x7F
    if c == 0 then return " " end
    if c >= 16 and c <= 25 then return string.char(c + 32) end
    if c == 26 then return ":" end
    if c >= 27 and c <= 30 then return "+" end
    if c == 31 then return "|" end
    if c == 32 then return "-" end
    if c >= 33 and c <= 58 then return string.char(c + 32) end
    if c >= 89 and c <= 92 then return "~" end      -- corners and trim
    local named = { [111] = "o", [115] = ".", [116] = ",", [124] = "/",
                    [125] = "-", [120] = ">", [121] = "<", [122] = "@",
                    [123] = "*" }
    if named[c] then return named[c] end
    return "#"
end

local function read_screen()
    local m = mem()
    local lines = {}
    for row = 0, ROWS - 1 do
        local chars = {}
        for col = 0, COLS - 1 do
            chars[#chars + 1] = glyph(m:read_u8(SCREEN + row * COLS + col))
        end
        lines[#lines + 1] = table.concat(chars)
    end
    return lines
end

local function screen_text()
    return table.concat(read_screen(), "\n")
end

local function on_screen(alternatives)
    local text = screen_text()
    for want in alternatives:gmatch("[^|]+") do
        if text:find(want, 1, true) then return true end
    end
    return false
end

-- The underline's first line for each row: the top of row r (row 0 is at
-- line 19), or for the status row a few lines under it.
local function bar_rows()
    local m = mem()
    local found = {}
    for row = 0, ROWS - 1 do
        local line = row == ROWS - 1 and 232 or 20 + row * 8
        local bits = m:read_u8(P2 + line)
        if bits ~= 0 then found[row] = bits end
    end
    return found
end

local function print_screen(title)
    local lines = read_screen()
    local bars = bar_rows()
    print(string.format("---- %s (%.1f s) ----", title, manager.machine.time:as_double()))
    print("+" .. string.rep("-", COLS) .. "+")
    for i, l in ipairs(lines) do
        print("|" .. l .. "|")
        if bars[i - 1] then
            print(string.format("  (underline under row %d, bits %02X)", i - 1, bars[i - 1]))
        end
    end
    print("+" .. string.rep("-", COLS) .. "+")
end

local KEYPAD = {
    k0 = { ":keypad.0", "[0]" }, star = { ":keypad.0", "[*]" }, hash = { ":keypad.0", "[#]" },
    reset = { ":keypad.1", "Reset" }, k7 = { ":keypad.1", "[7]" }, k8 = { ":keypad.1", "[8]" },
    k9 = { ":keypad.1", "[9]" },
    pause = { ":keypad.2", "Pause" }, k4 = { ":keypad.2", "[4]" }, k5 = { ":keypad.2", "[5]" },
    k6 = { ":keypad.2", "[6]" },
    start = { ":keypad.3", "Start" }, k1 = { ":keypad.3", "[1]" }, k2 = { ":keypad.3", "[2]" },
    k3 = { ":keypad.3", "[3]" },
    fire = { ":djoy_b", "P1 Button 1" }, b2 = { ":djoy_b", "P1 Button 2" },
}
local STICK = {
    up = { ":analog_1", "AD Stick Y", 0x00 }, down = { ":analog_1", "AD Stick Y", 0xE4 },
    left = { ":analog_0", "AD Stick X", 0x00 }, right = { ":analog_0", "AD Stick X", 0xE4 },
}

local function field(port, name)
    local p = manager.machine.ioport.ports[port]
    local f = p and p.fields[name]
    if f == nil then error("smoke.lua: no field " .. name .. " in " .. port) end
    return f
end

local function press(action, on)
    local name = action:gsub("%*.*$", "")
    local s = STICK[name]
    if s then
        local f = field(s[1], s[2])
        if on then f:set_value(s[3]) else f:clear_value() end
        return
    end
    local k = KEYPAD[name]
    if k == nil then error("smoke.lua: unknown action '" .. action .. "'") end
    field(k[1], k[2]):set_value(on and 1 or 0)
end

local function shot(title)
    print_screen(title)
    local scr = manager.machine.screens[":screen"]
    if scr then scr:snapshot() end
end

-- A keypad key has to be held for the keypad scan and released long enough
-- to count again; the stick's POT values latch once a frame.
local HOLD, GAP = 0.30, 0.45
local SETTLE = tonumber(os.getenv("FCS_SETTLE") or "8")

local script = {}
if SCRIPT then
    for a in SCRIPT:gmatch("[^,]+") do script[#script + 1] = a:match("^%s*(.-)%s*$") end
end

-- MAME re-runs this on every reset; the state lives in _G.
if _G.fcs_state == nil then
    _G.fcs_state = { fired = false, step = 1, down = false, t_next = SETTLE, shots = 0 }
end
local st = _G.fcs_state

local function next_step(now, delay)
    st.step = st.step + 1
    st.t_next = now + delay
    if st.step > #script then st.t_sample = st.t_next + AT end
end

local function status()
    local cpu = manager.machine.devices[":maincpu"]
    print(string.format("fcs: PC=%04X", cpu.state["PC"].value))
end

-- The subscription has to stay in a live global, or it is collected.
_G.fcs_sub = emu.add_machine_frame_notifier(function ()
    if st.fired then return end
    local now = manager.machine.time:as_double()

    if st.step <= #script then
        if now < st.t_next then return end
        local action = script[st.step]
        local n = action:match("^wait(%d*)$")
        if n then
            next_step(now, (n == "" and 1 or tonumber(n)))
        elseif action:sub(1, 1) == "?" then
            st.t_wait = st.t_wait or now
            if on_screen(action:sub(2)) then
                print(string.format("fcs: saw %q at %.1f s", action:sub(2), now))
                st.t_wait = nil
                next_step(now, 0)
            elseif now - st.t_wait > UNTIL then
                print_screen("timed out")
                print(string.format("fcs: FAIL never saw %q", action:sub(2)))
                status()
                st.fired = true
                manager.machine:exit()
            end
        elseif action == "shot" then
            st.shots = st.shots + 1
            shot("shot " .. st.shots)
            next_step(now, 0)
        elseif st.down then
            press(action, false)
            st.down = false
            next_step(now, GAP)
        else
            press(action, true)
            st.down = true
            st.t_next = now + (tonumber(action:match("%*([%d.]+)$")) or HOLD)
        end
        return
    end

    if now < (st.t_sample or AT) then return end
    st.fired = true

    if not QUIET then print_screen("sample") end
    status()

    if EXPECT then
        if screen_text():find(EXPECT, 1, true) then
            print("fcs: PASS")
        else
            print("fcs: FAIL expected " .. string.format("%q", EXPECT))
        end
    end
    manager.machine:exit()
end)
