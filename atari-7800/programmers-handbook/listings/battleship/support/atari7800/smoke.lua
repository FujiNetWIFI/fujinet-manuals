-- smoke.lua -- read the 7800 screen out of the MARIA engine's map and give a
-- verdict.
--
-- Modelled on support/nes/smoke.lua and the firmware's
-- pico/atari-7800/emu/mtext.lua. The engine's 32x24 map (src/atari7800/maria.s
-- _mt_map) holds tile * 2 per cell, its palette selects 3 pages on. Tiles are
-- read through the table src/atari7800/mkchr.py writes
-- (support/atari7800/tilemap.lua): text is itself, art a lower-case letter or a symbol.
--
--   FBS_TILEMAP path to support/atari7800/tilemap.lua (required)
--   FBS_MAPFILE the ld65 map, to find _mt_map (default $4000)
--   FBS_AT      emulated seconds to settle before sampling; measured from the
--               end of FBS_SCRIPT when there is one
--   FBS_SETTLE  emulated seconds before the first step (default 8)
--   FBS_SCRIPT  comma-separated steps: fire back select pause reset up down
--               left right, a chord like select+fire, waitN to idle N
--               emulated seconds, until:TEXT to wait (up to 120 s) for TEXT
--               on screen ('_' for a space, any case), BUTTON~TEXT to hold
--               BUTTON until TEXT shows (up to 10 s a press, then again: a
--               press made and let go inside a network call is never seen),
--               show to print the screen, snap to save a numbered PNG
--   FBS_EXPECT  substring that must appear on screen; sets the exit verdict
--   FBS_QUIET   only print the verdict, not the screen
--   FBS_SNAP    path of the final PNG; numbered "snap" steps derive from it
--
-- Every printed screen also reports each row's palette runs: the engine
-- draws at most 12 (maria.h MT_MAXRUNS), so a row past it is a FAIL.

local AT      = tonumber(os.getenv("FBS_AT") or "8")
local EXPECT  = os.getenv("FBS_EXPECT")
if EXPECT == "" then EXPECT = nil end
local QUIET   = os.getenv("FBS_QUIET")
local TILEMAP = os.getenv("FBS_TILEMAP")
local MAPFILE = os.getenv("FBS_MAPFILE")
local SCRIPT  = os.getenv("FBS_SCRIPT")
local SETTLE  = tonumber(os.getenv("FBS_SETTLE") or "8")
local SNAP    = os.getenv("FBS_SNAP")

local COLS, ROWS, MAXRUNS = 32, 24, 12
local HOLD, GAP, LONG, RETRY, UNTIL_SECS = 0.15, 0.45, 10, 3, 120

local function mt_map()
    if MAPFILE then
        local f = io.open(MAPFILE)
        if f then
            local text = f:read("a")
            f:close()
            local a = text:match("_mt_map%s+(%x+)")
            if a then return tonumber(a, 16) end
        end
    end
    return 0x4000
end

if _G.fbs_state == nil then
    local tm = TILEMAP and loadfile(TILEMAP)
    _G.fbs_state = { step = 1, down = false, t_next = SETTLE, shots = 0,
                     map = mt_map(), tilemap = tm and tm() or nil, worst = 0 }
end
local st = _G.fbs_state

local function mem()
    return manager.machine.devices[":maincpu"].spaces["program"]
end

local function row(y)
    local m, s = mem(), {}
    for x = 0, COLS - 1 do
        s[#s + 1] = st.tilemap[m:read_u8(st.map + y * COLS + x) >> 1] or "?"
    end
    return table.concat(s)
end

local function runs(y)
    local m, n, last = mem(), 0, nil
    for x = 0, COLS - 1 do
        local p = m:read_u8(st.map + 0x300 + y * COLS + x) ~= 0
        if p ~= last then n, last = n + 1, p end
    end
    return n
end

local function show(title)
    print(string.format("---- %s (%.1f s) ----", title, manager.machine.time:as_double()))
    for y = 0, ROWS - 1 do
        local r = runs(y)
        if r > st.worst then st.worst = r end
        print(string.format("%2d|%s|%2d%s", y, row(y), r, r > MAXRUNS and " OVER" or ""))
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

local PORTS = {
    up = { ":JOYSTICKS", "P1 Up" }, down = { ":JOYSTICKS", "P1 Down" },
    left = { ":JOYSTICKS", "P1 Left" }, right = { ":JOYSTICKS", "P1 Right" },
    fire = { ":BUTTONS", "P1 Button 1" }, back = { ":BUTTONS", "P1 Button 2" },
    select = { ":CONSOLE", "Select" }, pause = { ":CONSOLE", "Pause" },
    reset = { ":CONSOLE", "Reset" },
}

local function press(action, on)
    for b in action:gmatch("[^+]+") do
        local p = PORTS[b]
        if p == nil then error("smoke.lua: unknown action '" .. b .. "'") end
        manager.machine.ioport.ports[p[1]].fields[p[2]]:set_value(on and 1 or 0)
    end
end

local script = {}
if SCRIPT then
    for a in SCRIPT:gmatch("[^,]+") do script[#script + 1] = a end
end

local function finish()
    if not QUIET then show("final") end
    local cpu = manager.machine.devices[":maincpu"]
    print(string.format("fbs: PC=%04X, most palette runs in a row %d", cpu.state["PC"].value,
                        st.worst))
    if SNAP and SNAP ~= "" then snapshot(SNAP) end
    local ok = st.worst <= MAXRUNS and not st.failed
    if EXPECT then ok = ok and on_screen(EXPECT) end
    if EXPECT or st.worst > MAXRUNS or st.failed then
        print("fbs: " .. (ok and "PASS" or "FAIL") .. (st.failed and (" " .. st.failed) or "")
              .. (EXPECT and (" expected " .. string.format("%q", EXPECT)) or ""))
    end
    manager.machine:exit()
end

-- Held over from the script chunk, or the next collection unsubscribes it.
_G.fbs_sub = emu.add_machine_frame_notifier(function()
    if st.done then return end
    if st.tilemap == nil then
        print("fbs: FAIL no FBS_TILEMAP")
        st.done = true
        manager.machine:exit()
        return
    end
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
