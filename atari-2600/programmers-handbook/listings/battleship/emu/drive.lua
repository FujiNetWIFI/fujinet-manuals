-- drive.lua -- the whole game, against the live server.
--
-- Types a name if the keyboard comes up, picks BS_TABLE (default AI1) off
-- the table list BY READING THE SCREEN, readies up, places five ships, and
-- fires until a result comes back -- snapshotting the moments that matter
-- and, after every poll, reading the reply window's gamefields and the
-- cartridge's playfield tables back and requiring them to agree byte for
-- byte. That last check is the one nothing else can make: a board can look
-- right in a screenshot and be one row off.
--
-- Every wait is on the CLIENT'S OWN state -- the live bank at $1F0E and the
-- zero-page cells -- never on frame numbers. A network round trip takes as
-- long as the server takes. Inputs are edge-detected by the client, so every
-- press is released again with frames in between.
--
--   BS_TABLE=AI3 ./run.sh battleship drive       four seats
--   PLAY_FRAMES=3000                              how long to play
--   DRIVE_MODE=resetleave   once at the table: the RESET switch opens the
--                           menu, LEAVE sends /leave then /tables, the lobby
--                           comes back with a list on it
--   DRIVE_MODE=resettest    once at the table: soft_reset() the 6507 and
--                           prove the cartridge's sequence carried across
--   DRIVE_MODE=sounds       play, and log every cue that starts

package.path = (os.getenv("A2600_EMU") or ".") .. "/?.lua;" .. package.path
local font = require("vcsfont")

local want = (os.getenv("BS_TABLE") or "AI1"):upper():gsub("[^%w]", "")
local PLAY_FRAMES = tonumber(os.getenv("PLAY_FRAMES") or "6000")
local MODE = os.getenv("DRIVE_MODE") or "play"

-- soft_reset RE-RUNS this script, so the reset test's state lives in _G and
-- the second run of the script does only the checking.
_G._rt = _G._rt or { phase = "before" }
if MODE == "resettest" and _G._rt.phase == "after" then
    local ACKSEQ, BANK = 0x1F00, 0x1F0E
    local t = _G._rt
    t.n = 0
    _G._drive2 = emu.add_machine_frame_notifier(function()
        t.n = t.n + 1
        local sp = manager.machine.devices[":maincpu"].spaces["program"]
        if t.n == 1500 then
            -- The client makes several transactions on the way back to the
            -- lobby (the appkey, then /tables), so the sequence has moved on
            -- by more than one. What must be true: it moved on FROM where
            -- the cartridge had it, not from 1, and the lobby came back with
            -- a list on it -- a RAM counter's first transaction would have
            -- collided with an answered sequence and timed out.
            local now, before = sp:readv_u8(ACKSEQ), t.before
            local advanced = ((now - before) % 255) >= 1 and ((now - before) % 255) < 40
            local bank, cnt = sp:readv_u8(BANK), sp:readv_u8(0xAB)
            print(string.format("RESET: ACKSEQ %02X after the reset (was %02X), bank %d, %d tables",
                                now, before, bank, cnt))
            manager.machine.video:snapshot()
            print((advanced and bank == 0 and cnt > 0)
                  and "PASS -- the sequence came from the cartridge, not from RAM, and the lobby is back"
                  or "FAIL -- the client did not derive its sequence from the cart")
        elseif t.n == 1520 then
            manager.machine:exit()
        end
    end)
    return
end

local ZP = { ENT = 0xA3, CLASS = 0xB6, STAT = 0xA5, ACT = 0xA7, PCNT = 0xA4,
             CNT = 0xAB, SEL = 0xAA, CURX = 0xAC, CURY = 0xAD, CLK = 0xB1,
             MYST = 0xA6, POLL = 0xA1, MODE = 0xB4, LIVE = 0xB3, SHIP = 0xAB,
             SHIPS = 0xB7,
             REQ = 0x8F, ERR = 0x9A, STEP = 0x9B, ERR2 = 0xBE }
local BANK, RPLY, PLANES = 0x1F0E, 0x1B00, 0x1800
local BANKLOB, BANKGAM, BANKNET, BANKMNU, BANKNAM, BANKPLC, BANKCMP = 0, 1, 2, 3, 4, 5, 6

local sp
local n, phase, mark = 0, "boot", 0
local hold, held, gap = 0, nil, 0
local seq, seqi = nil, 1
local did, fails, checks = {}, 0, 0
local shots, results, readied = 0, 0, nil   -- readied: the frame it happened
local lastbank, lastreq = 0, nil
local snaps = 0
local lastclass, lastact, laststat = -1, -1, -1
local seenleave, seentables = false, false
local placing = false

sp = manager.machine.devices[":maincpu"].spaces["program"]
local function rd(a) return sp:readv_u8(a) end

local function read_row(row)
    local s = ""
    for col = 0, 11 do
        local plane, left, key = col // 2, (col % 2) == 0, 0
        for line = 0, 4 do
            local b = rd(PLANES + plane * 128 + row * 6 + line)
            local ink = left and ((b >> 5) & 7) or ((b >> 1) & 7)
            key = (key << 3) | ink
        end
        s = s .. (font.glyph[key] or "?")
    end
    return s
end

-- The fleet strips, text rows 3 and 4: six columns a seat, a space and five
-- pips, in slot order. What they must say is shipsLeft[5] of that seat's
-- record in the reply window -- '#' afloat, '=' sunk -- so read the strips
-- back through the font and compare, which is the only check that sees the
-- content rather than the geometry.
local PLOFSL = { [0] = 1, 2, 0, 3 }             -- slot -> player, quadrants
local fleetchecks = 0
local function check_fleets()
    local pc, stat = rd(ZP.PCNT), rd(ZP.STAT)
    if stat < 10 then return end                -- no gamefields yet
    fleetchecks = fleetchecks + 1
    for pair = 0, 1 do
        local got = read_row(pair == 0 and 3 or 4)
        local want = ""
        for half = 0, 1 do
            local p = PLOFSL[pair * 2 + half]
            if p >= pc then
                want = want .. "      "
            else
                want = want .. " "
                for j = 0, 4 do
                    want = want .. (rd(RPLY + 49 + p * 115 + 110 + j) ~= 0 and "#" or "=")
                end
            end
        end
        if got ~= want then
            fails = fails + 1
            print(string.format("FAIL: fleet row %d reads %q, want %q",
                                pair == 0 and 3 or 4, got, want))
        end
    end
end

local function snap(why)
    snaps = snaps + 1
    print(string.format("SNAP %d at frame %d: %s", snaps, n, why))
    manager.machine.video:snapshot()
end

local function press(name)
    local tag = name:match("^P1") and ":joyport1:joy:JOY" or ":SWB"
    manager.machine.ioport.ports[tag].fields[name]:set_value(1)
    hold, held = 6, { tag = tag, name = name }
end

local function release()
    if held then
        manager.machine.ioport.ports[held.tag].fields[held.name]:set_value(0)
        held = nil
        gap = 6
    end
end

-- The cartridge's playfield tables against the reply window: for every
-- player's gamefield, the HIT and MID bytes the bit map says, compared with
-- what the tables hold for that player's slot.
local REG_OF = { 0, 0, 1, 1, 1, 1, 2, 2, 2, 2 }
local BITS_OF = { 0x30, 0xC0, 0xC0, 0x30, 0x0C, 0x03, 0x03, 0x0C, 0x30, 0xC0 }
local SLOTMAP = { [0] = { 1, 0, 2, 3 }, [1] = { 2, 0, 1, 3 } }
local function check_tables()
    local pcnt, mode, stat = rd(ZP.PCNT), rd(ZP.MODE), rd(ZP.STAT)
    if stat < 10 then return end
    checks = checks + 1
    local bad = 0
    for p = 0, pcnt - 1 do
        local slot = SLOTMAP[mode][p + 1]
        local half, pair = slot & 1, slot >> 1
        local base = RPLY + 49 + p * 115 + 10
        for y = 0, 9 do
            local hit, mid = { 0, 0, 0 }, { 0, 0, 0 }
            for x = 0, 9 do
                local v = rd(base + y * 10 + x)
                local r = REG_OF[x + 1] + 1
                if v == 1 then hit[r] = hit[r] | BITS_OF[x + 1] end
                if v == 1 or v == 2 then mid[r] = mid[r] | BITS_OF[x + 1] end
            end
            for r = 1, 3 do
                local plane = (r - 1) + 3 * half
                local entry = pair * 10 + y
                local gh = rd(PLANES + plane * 128 + 30 + entry)
                local gm = rd(PLANES + plane * 128 + 30 + 20 + entry)
                if gh ~= hit[r] or gm ~= mid[r] then
                    bad = bad + 1
                    if bad <= 4 then
                        print(string.format("TABLE MISMATCH player %d slot %d row %d reg %d: hit %02X/%02X mid %02X/%02X",
                              p, slot, y, r - 1, gh, hit[r], gm, mid[r]))
                    end
                end
            end
        end
    end
    if bad > 0 then fails = fails + 1 end
end

local function board_text(p)
    local base = RPLY + 49 + p * 115 + 10
    local out = {}
    for y = 0, 9 do
        local s = ""
        for x = 0, 9 do
            local v = rd(base + y * 10 + x)
            s = s .. (v == 1 and "X" or v == 2 and "O" or ".")
        end
        out[#out + 1] = s
    end
    return table.concat(out, " ")
end

-- The cues, by the script offset SNDFIRE stores in SNDPTR: a step advance
-- never lands on another cue's first step, so these values are starts.
local CUES = { [1] = "move", [6] = "select", [15] = "place", [24] = "shot",
               [53] = "miss", [66] = "hit", [91] = "sunk", [120] = "turn",
               [133] = "tick", [138] = "error", [143] = "over", [156] = "join" }
local cues = {}
if MODE == "sounds" then
    _G._sndtap = sp:install_write_tap(0x9F, 0x9F, "snd", function(off, data, mask)
        local name = CUES[data]
        if name then
            cues[name] = (cues[name] or 0) + 1
            print(string.format("CUE %s at frame %d (class %d status %d active %d)",
                                name, n, rd(ZP.CLASS), rd(ZP.STAT), rd(ZP.ACT)))
        end
    end)
end

local function done(ok)
    if MODE == "sounds" then
        local out = {}
        for k, v in pairs(cues) do out[#out + 1] = k .. "=" .. v end
        table.sort(out)
        print("CUES: " .. table.concat(out, " "))
    end
    print(string.format("DID: %s", table.concat(did, "; ")))
    print(string.format("shots %d, results %d, table checks %d, mismatching %d",
                        shots, results, checks, fails))
    print(string.format("fleet strip checks %d", fleetchecks))
    print(ok and "PASS" or "FAIL")
    phase, mark = "exit", n
end

_G._reqtap = sp:install_write_tap(ZP.REQ, ZP.REQ, "req", function(off, data, mask)
    if data ~= lastreq then
        print(string.format("REQ %d at frame %d (bank %d)", data, n, rd(BANK)))
        lastreq = data
    end
    if data == 5 then seenleave = true end
    if data == 0 and seenleave then seentables = true end
end)

_G._drive = emu.add_machine_frame_notifier(function()
    n = n + 1
    if hold > 0 then
        hold = hold - 1
        if hold == 0 then release() end
        return
    end
    if gap > 0 then gap = gap - 1; return end

    local bank = rd(BANK)
    -- a poll just came back: the composer ran; check its work
    if lastbank == BANKCMP and bank == BANKGAM then check_tables() end
    lastbank = bank

    if phase == "boot" then
        if n < 120 then return end
        if bank == BANKNAM then
            seq, seqi = { "P1 Button 1", "P1 Right", "P1 Button 1", "P1 Right",
                          "P1 Button 1", "P1 Down", "P1 Down", "P1 Down",
                          "P1 Button 1" }, 1
            phase = "typing"
            did[#did + 1] = "typed a name"
        elseif bank == BANKLOB and rd(ZP.ENT) == 1 then
            phase = "lobby"
            did[#did + 1] = "the appkey had a name"
        elseif n > 1800 then
            print("FAIL: never reached the keyboard or the lobby; bank " .. bank)
            done(false)
        end
    elseif phase == "typing" then
        if seqi <= #seq then
            press(seq[seqi]); seqi = seqi + 1
        else
            phase, mark = "tolobby", n
        end
    elseif phase == "tolobby" then
        if bank == BANKLOB and rd(ZP.ENT) == 1 then
            phase = "lobby"
        elseif n - mark > 3600 then
            print("FAIL: the lobby never came up; bank " .. bank)
            done(false)
        end
    elseif phase == "lobby" then
        local cnt = rd(ZP.CNT)
        if cnt == 0 then
            if n - mark > 600 then print("FAIL: no tables listed"); done(false) end
            return
        end
        local target
        for r = 0, cnt - 1 do
            local t = read_row(3 + r):upper():gsub("[^%w]", "")
            print(string.format("  table %d: %q", r, read_row(3 + r)))
            if t:sub(1, #want) == want then target = r end
        end
        snap("the table list")
        if not target then
            print("FAIL: no table matching " .. want)
            done(false)
            return
        end
        seq, seqi = {}, 1
        for i = 1, target do seq[#seq + 1] = "P1 Down" end
        seq[#seq + 1] = "P1 Button 1"
        phase = "joining"
        did[#did + 1] = "joined row " .. target
    elseif phase == "joining" then
        if seqi <= #seq then
            press(seq[seqi]); seqi = seqi + 1
        elseif bank == BANKGAM or bank == BANKPLC then
            phase, mark = "game", n
        elseif n - mark > 3600 then
            print("FAIL: the game never came up; bank " .. bank)
            done(false)
        end
    elseif phase == "game" then
        local class, act, stat = rd(ZP.CLASS), rd(ZP.ACT), rd(ZP.STAT)
        if class ~= lastclass or stat ~= laststat or act ~= lastact then
            print(string.format("STATE frame %d: bank %d class %d status %d active %d players %d mode %d my %d clk %d",
                  n, bank, class, stat, act, rd(ZP.PCNT), rd(ZP.MODE), rd(ZP.MYST), rd(ZP.CLK)))
            print("  status row: " .. read_row(0) .. " | " .. read_row(1) .. " | " .. read_row(2))
            if stat ~= laststat and stat >= 11 and stat <= 13 then
                results = results + 1
                snap("result " .. stat)
            end
            if class ~= lastclass and class == 2 then snap("play began") end
            lastclass, lastact, laststat = class, act, stat
        end
        if n - mark > PLAY_FRAMES then
            snap("time is up")
            print("your board:  " .. board_text(0))
            print("enemy board: " .. board_text(1))
            done(results > 0 and fails == 0)
            return
        end
        if bank == BANKPLC then
            -- The fleet arrives rolled and legal, so the driver accepts it:
            -- five presses and nothing else. Walking the cursor would be
            -- wrong now as well as slower -- a blind step lands on another
            -- hull and the client refuses it, with a tone, and waits.
            if not placing then
                -- The roll is one candidate a frame and reads no input until
                -- the last ship is down, so WAIT for it: SHIPS[4] is $FF
                -- until then, and a press before that is simply not seen.
                if rd(ZP.SHIPS + 4) == 0xFF then return end
                placing = true
                seq, seqi = { "P1 Button 1", "P1 Button 1", "P1 Button 1",
                              "P1 Button 1", "P1 Button 1" }, 1
                did[#did + 1] = "accepted the rolled fleet"
                snap("placing")
                local ships, cells = {}, {}
                for i = 0, 4 do
                    local v = rd(ZP.SHIPS + i)
                    ships[#ships + 1] = v
                    local pos, dir = v % 100, v // 100
                    for k = 0, ({5, 4, 3, 3, 2})[i + 1] - 1 do
                        local c = pos + k * (dir == 1 and 10 or 1)
                        if cells[c] then
                            print("FAIL: rolled fleet overlaps at cell " .. c)
                            fails = fails + 1
                        end
                        cells[c] = true
                    end
                end
                print("  rolled: " .. table.concat(ships, " "))
            end
            if seqi <= #seq then press(seq[seqi]); seqi = seqi + 1 end
            return
        end
        -- The fleet strips are composed a frame behind the status row, so
        -- check them on a settled frame rather than on the state edge.
        if bank == BANKGAM and class == 2 and rd(ZP.MODE) == 1 and n % 64 == 0 then
            check_fleets()
        end
        if bank ~= BANKGAM then return end
        if MODE == "resetleave" then
            -- the RESET switch: menu, LEAVE, /leave, /tables, the lobby
            phase, mark = "rl_menu", n
            press("Reset Game")
            did[#did + 1] = "pressed RESET at the table"
            return
        elseif MODE == "resettest" then
            _G._rt.before = rd(0x1F00)
            _G._rt.phase = "after"
            print(string.format("RESET: ACKSEQ %02X before the reset, bank %d", _G._rt.before, bank))
            manager.machine:soft_reset()
            return
        end
        if class == 0 and rd(ZP.STAT) == 0 then
            -- /ready TOGGLES, and the server resets a finished table back to
            -- the lobby under us, so one press is not a guarantee of being
            -- ready. Press again if the status has not become PSREADY after
            -- a couple of polls -- a single shot left the run sitting in the
            -- lobby until it timed out, which reads exactly like a hang.
            if rd(ZP.MYST) ~= 3 then
                if not readied or n - readied > 300 then
                    press("P1 Button 1"); readied = n
                    did[#did + 1] = "readied up"
                end
            else
                readied = readied or n
            end
        elseif class == 2 then
            if act == 0 and rd(ZP.MYST) == 0 and rd(ZP.POLL) > 4 and rd(ZP.CLK) > 2 then
                -- our turn: walk the cursor to the first cell nobody has
                -- fired at on the enemy board, then fire
                if not seq or seqi > #seq then
                    local base = RPLY + 49 + 1 * 115 + 10
                    local tx, ty
                    for c = 0, 99 do
                        if rd(base + c) == 0 then tx, ty = c % 10, c // 10; break end
                    end
                    if not tx then
                        print("every enemy cell is resolved")
                        done(results > 0 and fails == 0)
                        return
                    end
                    local cx, cy = rd(ZP.CURX), rd(ZP.CURY)
                    seq, seqi = {}, 1
                    for i = 1, math.abs(tx - cx) do seq[#seq + 1] = tx > cx and "P1 Right" or "P1 Left" end
                    for i = 1, math.abs(ty - cy) do seq[#seq + 1] = ty > cy and "P1 Down" or "P1 Up" end
                    seq[#seq + 1] = "P1 Button 1"
                    shots = shots + 1
                    print(string.format("SHOT %d at (%d,%d) frame %d", shots, tx, ty, n))
                end
                if seqi <= #seq then press(seq[seqi]); seqi = seqi + 1 end
            end
        elseif class == 3 then
            snap("game over")
            print("enemy board: " .. board_text(1))
            done(shots > 0 and fails == 0)
            return
        end
    elseif phase == "rl_menu" then
        if bank == BANKMNU then
            snap("the menu")
            did[#did + 1] = "the menu opened"
            seq, seqi = { "P1 Down", "P1 Down", "P1 Button 1" }, 1
            phase, mark = "rl_leave", n
        elseif n - mark > 300 then
            print("FAIL: RESET did not open the menu; bank " .. bank)
            done(false)
        end
    elseif phase == "rl_leave" then
        if seqi <= #seq then
            press(seq[seqi]); seqi = seqi + 1
        elseif bank == BANKLOB and rd(ZP.ENT) == 1 then
            local cnt = rd(ZP.CNT)
            snap("back in the lobby")
            did[#did + 1] = "the lobby came back with " .. cnt .. " tables"
            done(cnt > 0 and seenleave and seentables)
        elseif n - mark > 3600 then
            print("FAIL: the lobby never came back; bank " .. bank)
            done(false)
        end
    elseif phase == "exit" then
        if n - mark > 20 then manager.machine:exit() end
    end
end)
