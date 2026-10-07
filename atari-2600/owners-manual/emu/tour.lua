-- tour.lua -- play a list of steps at a cartridge and snapshot along the way.
--
-- One harness for every owner's-manual screenshot. The steps come from the
-- TOUR environment variable, whitespace separated, run in order:
--
--   w<N>             wait N frames
--   select reset     tap a console switch (pressed TAP frames, then released,
--                    then a TAP-frame gap: every client here edge-detects)
--   fire up down left right
--                    tap the left joystick (or the left paddle's button)
--   <tap>*<N>        the same tap N times, e.g. down*3
--   hold:<key>       press and keep holding; rel:<key> lets go
--   diff:<l|r>:<A|B> set a difficulty switch
--   pot:<1|2><x|y>:<0..255>
--                    set a paddle (port 1/2, paddle A = x, B = y)
--   until:<text>[@N] wait until <text> is on screen (compared by GLYPH FORM,
--                    since at 3x5 'S' and '5' are one picture); '_' = space.
--                    Gives up after N frames (default 1800) and says so
--   gone:<text>[@N]  wait until <text> is no longer on screen
--   snap             MAME snapshot (files are numbered in the order taken)
--   text             print every non-blank text row the cartridge composed
--   watch            from now on, print the screen whenever its text changes,
--                    with the frame number (for timings)
--   say:<words>      print a marker; '_' = space
--
-- After the last step it waits 15 frames and exits: the exit must not share a
-- frame with a snapshot or the file never flushes.
--
-- The text rows are read out of the cartridge's six composed text planes at
-- $1800 (12 columns x 21 rows, a 3x5 glyph in a 4x6 cell), so text, until,
-- gone and watch only mean something while a text screen is up.

package.path = (os.getenv("A2600_EMU") or ".") .. "/?.lua;"
            .. (os.getenv("A2600_FWEMU") or ".") .. "/?.lua;" .. package.path
local font = require("vcsfont")

local T_BASE, T_PLANE_LEN, T_CELL_H, T_COLS, T_ROWS = 0x1800, 0x80, 6, 12, 21
local TAP = tonumber(os.getenv("TAP") or "5")

local steps = {}
for tok in (os.getenv("TOUR") or "w180 snap"):gmatch("%S+") do
    local base, n = tok:match("^(.-)%*(%d+)$")
    if base then
        for _ = 1, tonumber(n) do steps[#steps + 1] = base end
    else
        steps[#steps + 1] = tok
    end
end

-- Fields CACHED ONCE: a field wrapper fetched at the moment of pressing is a
-- fresh object, and a set_value on a temporary can be lost.
local FIELDS = {}
local function field(tag, name)
    local k = tag .. "|" .. name
    if FIELDS[k] == nil then
        local p = manager.machine.ioport.ports[tag]
        FIELDS[k] = (p and p.fields[name]) or false
        if not FIELDS[k] then print("TOUR: no input " .. k) end
    end
    return FIELDS[k]
end

-- The left controller is a joystick or a pair of paddles (run.sh PORT1=pad).
local function ctl(name)
    if manager.machine.ioport.ports[":joyport1:joy:JOY"] then
        return field(":joyport1:joy:JOY", name)
    end
    return field(":joyport1:pad:JOY", name)
end

local KEYS = {
    select = function() return field(":SWB", "Select Game") end,
    reset  = function() return field(":SWB", "Reset Game") end,
    fire   = function() return ctl("P1 Button 1") end,
    up     = function() return ctl("P1 Up") end,
    down   = function() return ctl("P1 Down") end,
    left   = function() return ctl("P1 Left") end,
    right  = function() return ctl("P1 Right") end,
}

local sp
local function keys(row)
    local out = {}
    for col = 0, T_COLS - 1 do
        local plane, isleft, k = col // 2, (col % 2) == 0, 0
        for line = 0, 4 do
            local b = sp:readv_u8(T_BASE + plane * T_PLANE_LEN
                                         + row * T_CELL_H + line)
            local ink = isleft and ((b >> 5) & 7) or ((b >> 1) & 7)
            k = (k << 3) | ink
        end
        out[col] = k
    end
    return out
end

local function read_row(r)
    local kk, s = keys(r), ""
    for c = 0, T_COLS - 1 do s = s .. (font.glyph[kk[c]] or "?") end
    return s
end

local function screen()
    local t = {}
    for r = 0, T_ROWS - 1 do
        local s = read_row(r):gsub("%s+$", "")
        if s ~= "" then t[#t + 1] = string.format("  row %2d |%s|", r, s) end
    end
    return table.concat(t, "\n")
end

-- Is `want` anywhere on screen, comparing glyph forms?
local function has(want)
    local wk = {}
    for i = 1, #want do
        wk[i] = font.key[want:sub(i, i)] or font.key["?"]
    end
    for r = 0, T_ROWS - 1 do
        local kk = keys(r)
        for c0 = 0, T_COLS - #want do
            local ok = true
            for i = 1, #want do
                if kk[c0 + i - 1] ~= wk[i] then ok = false break end
            end
            if ok then return true end
        end
    end
    return false
end

local frame, idx, sub, snaps = 0, 1, 0, 0
local watching, last = false, nil
local held = {}
local finished_at

local function arg_text(s)
    local t, lim = s:match("^(.-)@(%d+)$")
    if not t then t, lim = s, "1800" end
    return t:gsub("_", " "), tonumber(lim)
end

_G._tour = emu.add_machine_frame_notifier(function()
    sp = sp or manager.machine.devices[":maincpu"].spaces["program"]
    frame = frame + 1

    if watching then
        local s = screen()
        if s ~= last then
            print(string.format("TOUR: f%d screen:\n%s", frame, s))
            last = s
        end
    end

    if finished_at then
        if frame >= finished_at + 15 then manager.machine:exit() end
        return
    end

    local tok = steps[idx]
    if tok == nil then
        print(string.format("TOUR: done at f%d, %d snapshot(s)", frame, snaps))
        finished_at = frame
        return
    end

    local function nxt() idx, sub = idx + 1, 0 end
    sub = sub + 1

    local n = tok:match("^w(%d+)$")
    if n then
        if sub >= tonumber(n) then nxt() end
        return
    end

    if KEYS[tok] then
        local f = KEYS[tok]()
        if sub == 1 then
            if f then f:set_value(1) end
        elseif sub == 1 + TAP then
            if f then f:set_value(0) end
        elseif sub >= 1 + 2 * TAP then
            nxt()
        end
        return
    end

    local verb, rest = tok:match("^(%a+):(.*)$")
    if tok == "snap" then
        manager.machine.video:snapshot()
        snaps = snaps + 1
        print(string.format("TOUR: snapshot %d at f%d", snaps, frame))
        nxt()
    elseif tok == "text" then
        print(string.format("TOUR: f%d screen:\n%s", frame, screen()))
        nxt()
    elseif tok == "watch" then
        watching = true
        nxt()
    elseif verb == "say" then
        print("TOUR: f" .. frame .. " " .. rest:gsub("_", " "))
        nxt()
    elseif verb == "hold" or verb == "rel" then
        local f = KEYS[rest] and KEYS[rest]()
        if f then f:set_value(verb == "hold" and 1 or 0) end
        held[rest] = (verb == "hold") or nil
        nxt()
    elseif verb == "diff" then
        local side, pos = rest:match("^(%a):(%a)$")
        local f = field(":SWB", side == "l" and "Left Diff. Switch"
                                           or "Right Diff. Switch")
        if f then f:set_value(pos == "A" and 1 or 0) end
        nxt()
    elseif verb == "pot" then
        local port, ax, v = rest:match("^(%d)(%a):(%d+)$")
        local f = field(":joyport" .. port .. ":pad:" ..
                        (ax == "x" and "POTX" or "POTY"), "Paddle")
        if f then f:set_value(tonumber(v)) end
        nxt()
    elseif verb == "until" or verb == "gone" then
        local want, lim = arg_text(rest)
        local present = has(want)
        if (verb == "until") == present then
            print(string.format("TOUR: f%d %s '%s' after %d frames",
                                frame, verb, want, sub))
            nxt()
        elseif sub >= lim then
            print(string.format("TOUR: f%d TIMEOUT %s '%s' after %d frames; screen:\n%s",
                                frame, verb, want, sub, screen()))
            nxt()
        end
    else
        print("TOUR: unknown step " .. tok)
        nxt()
    end
end)
