-- 5cs.lua -- the live 5 Card Stud shots: the table list, a table with bots,
-- the purse overlay, the in-game menu -- and then LEAVE TABLE, so the seat is
-- given back with a /leave rather than held until the server's timeout.
--
-- Each snapshot is announced as "SNAP=<name>" in the log, in the order MAME
-- numbers the files, and tools/shots.sh copies them out by those names:
--   5cs-tables   the table list, once it has rows on it
--   5cs-banner   the end-of-hand banner, if one comes up before our turn
--   5cs-table    a table, on our turn: the move menu and its clock
--   5cs-purses   the same table with SELECT held: every seat's purse
--   5cs-menu     RESET at the table: the in-game menu
--
-- Waits on the client's own state, never on frame counts: the live bank at
-- $1F0E, CDENT at $BB, and the table fields the server fills. A shot is only
-- taken once the client has sat in one state for STEADY frames -- a snapshot
-- taken the frame a poll lands catches the compose bank half-way through.
-- Every input is edge-detected by the client: press, hold, release, gap.
--
-- Uses the shared username appkey as it finds it (it must already hold a
-- name: this harness does not type one, so it never writes the appkey).
local BANK, CDENT, CDSEL, CDCNT, CDNPLR = 0x1F0E, 0xBB, 0xAA, 0xAB, 0xAC
local CDACT, CDNMV, CDCLK, CDLRPG = 0xAE, 0xAF, 0xB1, 0xB4
local B_LOB, B_GAM, B_MNU, B_NAM = 0, 1, 3, 4
local ENGRUN, MILEAVE = 0x0A, 2
local STEADY = tonumber(os.getenv("STEADY") or "30")

local sp
local function ports(tag) return manager.machine.ioport.ports[tag] end
local F = {}
local function field(tag, name)
    local k = tag .. name
    F[k] = F[k] or ports(tag).fields[name]
    return F[k]
end
local KEY = {
    fire   = function() return field(":joyport1:joy:JOY", "P1 Button 1") end,
    down   = function() return field(":joyport1:joy:JOY", "P1 Down") end,
    select = function() return field(":SWB", "Select Game") end,
    reset  = function() return field(":SWB", "Reset Game") end,
}

local n, phase, mark, steady, last = 0, "list", 0, 0, ""
local held, gap = nil, 0
local function say(f, ...) print(string.format("5CS: f%d " .. f, n, ...)) end
local function snap(what)
    manager.machine.video:snapshot()
    say("SNAP=5cs-%s", what)
end
local function tap(k)
    KEY[k]():set_value(1)
    held = { k = k, until_ = n + 6 }
    gap = 12
end
local function go(p) phase, mark, steady = p, n, 0; say("-> %s", p) end

_G._fivecs = emu.add_machine_frame_notifier(function()
    n = n + 1
    sp = sp or manager.machine.devices[":maincpu"].spaces["program"]
    if held then
        if n >= held.until_ then KEY[held.k]():set_value(0); held = nil end
        return
    end
    if gap > 0 then gap = gap - 1; return end

    local bank, ent = sp:readv_u8(BANK), sp:readv_u8(CDENT)
    local state = bank .. "/" .. ent
    if state == last then steady = steady + 1 else steady = 0; last = state end

    if phase == "list" then
        if bank == B_NAM then
            say("the name keyboard came up: no username appkey; not typing one")
            go("exit")
        elseif n > 60 and bank == B_LOB and sp:readv_u8(CDCNT) > 0
               and steady >= STEADY then
            say("table list: %d tables", sp:readv_u8(CDCNT))
            snap("tables")
            tap("fire")                          -- sit at the first table
            go("sit")
        elseif n > 3600 then say("TIMEOUT: no table list"); go("exit") end

    elseif phase == "sit" then
        -- our turn: the client runs the move clock (CDCLK) only then
        if (n - mark) % 300 == 0 then
            say("bank=%d ent=%02X players=%d act=%02X moves=%d clock=%d",
                bank, ent, sp:readv_u8(CDNPLR), sp:readv_u8(CDACT),
                sp:readv_u8(CDNMV), sp:readv_u8(CDCLK))
        end
        local banner = sp:readv_u8(CDLRPG) ~= 0
        if banner and bank == B_GAM and steady >= STEADY and not _G._bnshot then
            _G._bnshot = true
            snap("banner")
        end
        if bank == B_GAM and ent == ENGRUN and sp:readv_u8(CDNPLR) > 0
           and sp:readv_u8(CDNMV) > 0 and sp:readv_u8(CDCLK) > 0
           and not banner and steady >= STEADY then
            say("our turn: %d players, %d moves, clock %d",
                sp:readv_u8(CDNPLR), sp:readv_u8(CDNMV), sp:readv_u8(CDCLK))
            snap("table")
            KEY.select():set_value(1)            -- held, not tapped
            go("purse")
        elseif n > mark + 5400 then say("TIMEOUT: never our turn"); go("menu0") end

    elseif phase == "purse" then
        if n >= mark + 40 and bank == B_GAM then
            snap("purses")
            KEY.select():set_value(0)
            gap = 20
            go("menu0")
        end

    elseif phase == "menu0" then
        if bank == B_GAM and ent == ENGRUN then tap("reset"); go("menu") end

    elseif phase == "menu" then
        if bank == B_MNU and steady >= STEADY and not _G._menushot then
            _G._menushot = true
            snap("menu")
        elseif _G._menushot then
            if sp:readv_u8(CDSEL) == MILEAVE then tap("fire"); go("leave")
            else tap("down") end
        elseif n > mark + 600 then say("TIMEOUT: no menu"); go("exit") end

    elseif phase == "leave" then
        if bank == B_LOB and sp:readv_u8(CDCNT) > 0 and steady >= STEADY then
            say("left the table; back at the list")
            go("exit")
        elseif n > mark + 1800 then say("TIMEOUT: leaving"); go("exit") end

    elseif phase == "exit" then
        if n >= mark + 20 then say("done"); manager.machine:exit() end
    end
end)
