-- bs.lua -- the live Battleship placement shot, and then LEAVE TABLE.
--
-- Picks BS_TABLE (default AI1, "AI - 1 on 1") off the table list by reading
-- the screen, sits, readies up (FIRE; /ready toggles, so it is pressed again
-- only if the status has not become READY after a while), waits for the
-- placement screen to come up with the rolled fleet on it, snapshots it as
-- SNAP=bs-place, then RESET for the menu, LEAVE TABLE, and back to the list:
-- the seat is given back with a /leave, not held until the server's timeout.
--
-- Waits on the client's own state (the live bank at $1F0E, BSENT, the
-- zero-page cells the Battleship port's emu/drive.lua documents), never on
-- frame counts. Reads the shared username appkey; never types one.
package.path = (os.getenv("A2600_EMU") or ".") .. "/?.lua;"
            .. (os.getenv("A2600_FWEMU") or ".") .. "/?.lua;" .. package.path
local font = require("vcsfont")

local ZP = { ENT = 0xA3, CNT = 0xAB, SEL = 0xAA, MYST = 0xA6, SHIPS = 0xB7 }
local BANK, PLANES = 0x1F0E, 0x1800
local B_LOB, B_GAM, B_MNU, B_NAM, B_PLC = 0, 1, 3, 4, 5
local ENLOBBY, MILEAVE, PSREADY = 1, 2, 3
local STEADY = tonumber(os.getenv("STEADY") or "30")
local want = (os.getenv("BS_TABLE") or "AI1"):upper():gsub("[^%w]", "")

local sp = manager.machine.devices[":maincpu"].spaces["program"]
local function rd(a) return sp:readv_u8(a) end
local F = {}
local function field(tag, name)
    F[tag .. name] = F[tag .. name] or manager.machine.ioport.ports[tag].fields[name]
    return F[tag .. name]
end
local KEY = {
    fire  = function() return field(":joyport1:joy:JOY", "P1 Button 1") end,
    down  = function() return field(":joyport1:joy:JOY", "P1 Down") end,
    reset = function() return field(":SWB", "Reset Game") end,
}

local function read_row(row)
    local s = ""
    for col = 0, 11 do
        local plane, left, key = col // 2, (col % 2) == 0, 0
        for line = 0, 4 do
            local b = rd(PLANES + plane * 128 + row * 6 + line)
            key = (key << 3) | (left and ((b >> 5) & 7) or ((b >> 1) & 7))
        end
        s = s .. (font.glyph[key] or "?")
    end
    return s
end

local n, phase, mark, steady, last = 0, "list", 0, 0, ""
local held, gap, todo, readied = nil, 0, {}, nil
local function say(f, ...) print(string.format("BS: f%d " .. f, n, ...)) end
local function go(p) phase, mark, steady = p, n, 0; say("-> %s", p) end
local function tap(k)
    KEY[k]():set_value(1)
    held = { k = k, at = n + 6 }
    gap = 12
end

_G._bs = emu.add_machine_frame_notifier(function()
    n = n + 1
    if held then
        if n >= held.at then KEY[held.k]():set_value(0); held = nil end
        return
    end
    if gap > 0 then gap = gap - 1; return end
    if #todo > 0 then tap(table.remove(todo, 1)); return end

    local bank, ent = rd(BANK), rd(ZP.ENT)
    local state = bank .. "/" .. ent
    if state == last then steady = steady + 1 else steady = 0; last = state end

    if phase == "list" then
        if bank == B_NAM then
            say("the name keyboard came up: no username appkey; not typing one")
            go("exit")
        elseif n > 60 and bank == B_LOB and ent == ENLOBBY and rd(ZP.CNT) > 0
               and steady >= STEADY then
            local target
            for r = 0, rd(ZP.CNT) - 1 do
                local t = read_row(3 + r)
                say("table %d: %q", r, t)
                if t:upper():gsub("[^%w]", ""):sub(1, #want) == want then target = r end
            end
            if not target then say("no table matching %s", want); go("exit"); return end
            for _ = 1, target do todo[#todo + 1] = "down" end
            todo[#todo + 1] = "fire"
            go("join")
        elseif n > 3600 then say("TIMEOUT: no table list"); go("exit") end

    elseif phase == "join" then
        if bank == B_PLC then
            go("place")
        elseif bank == B_GAM and rd(ZP.MYST) ~= PSREADY
               and (not readied or n - readied > 300) and steady >= STEADY then
            say("ready up (status %d)", rd(ZP.MYST))
            readied = n
            tap("fire")
        elseif n - mark > 5400 then say("TIMEOUT: no placement"); go("leave0") end

    elseif phase == "place" then
        -- the roll is one candidate a frame; SHIPS[4] is $FF until it is done
        if bank == B_PLC and rd(ZP.SHIPS + 4) ~= 0xFF and steady >= STEADY then
            manager.machine.video:snapshot()
            say("SNAP=bs-place")
            go("leave0")
        elseif n - mark > 1800 then say("TIMEOUT: the fleet never settled"); go("leave0") end

    elseif phase == "leave0" then
        tap("reset")
        go("menu")

    elseif phase == "menu" then
        if bank == B_MNU and steady >= 10 then
            if rd(ZP.SEL) == MILEAVE then tap("fire"); go("leave")
            else tap("down") end
        elseif n - mark > 600 then say("TIMEOUT: no menu"); go("exit") end

    elseif phase == "leave" then
        if bank == B_LOB and ent == ENLOBBY and rd(ZP.CNT) > 0 and steady >= STEADY then
            say("left the table; back at the list")
            go("exit")
        elseif n - mark > 1800 then say("TIMEOUT: leaving"); go("exit") end

    elseif phase == "exit" then
        if n >= mark + 20 then say("done"); manager.machine:exit() end
    end
end)
