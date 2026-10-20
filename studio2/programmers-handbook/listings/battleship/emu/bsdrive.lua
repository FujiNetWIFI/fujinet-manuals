-- bsdrive.lua -- Battleship (fujinet-battleship studio2/) end to end against
-- a live server, through the cart's fujimail and a fujinet-pc: type a name on
-- the grid (when the appkey has none), list the tables, sit at one, ready up,
-- place the fleet (moving and turning the first ship, keeping the rest as
-- rolled), then aim and fire on every turn until the game is over. On the
-- third turn it visits the menu and comes back (1); after the game it leaves
-- the table through the menu (2) and passes on the table list.
--
--   ENDPOINT=http://127.0.0.1:8080/ make && SECS=1500 make drive
--
-- Env: S2_NAME (default S2TEST), BS_TABLE (the lobby row, default
-- "AI - 3 BOTS": four seats), BS_LIMIT (seconds, default 1440).
-- Runs throttled: the server's clocks (bot turns, the move timer) are real
-- time. It reads the cart's state through the device's save items, never the
-- address space: the reply window is m_arena's first 1K.
local T = dofile(os.getenv("S2_EMU_DIR") .. "/s2screen.lua")
manager.machine.video.throttled = true

local NAME = os.getenv("S2_NAME") or "S2TEST"
local TABLE = os.getenv("BS_TABLE") or "AI - 3 BOTS"
local LIMIT = tonumber(os.getenv("BS_LIMIT") or "1440")
local GRID = { "ABCDEFGHIJKLMNOP", "QRSTUVWXYZ012345", "6789-_." }
local ORG = { [1] = { 1, 0 }, [2] = { 1, 6 }, [3] = { 6, 6 } }   -- seat -> board row, col

local phase = "boot"
local pending
local hold = 0
local snapped = {}
local lastScreen = ""
local shots, turns, kept, refused = 0, 0, 0, 0
local placeMoves = 0
local lastKeep
local placeBefore, moved, turned

local function log(fmt, ...)
  print(string.format("[%7.2f] " .. fmt, T.now(), ...))
end

local function rb(k) return T.status(k - 0x400) end      -- reply byte k

local function cells()
  local out = {}
  for y = 0, 9 do
    local row = {}
    for x = 0, 10 do
      if T.char(y, x) == 0xA0 then
        row[#row + 1] = string.format("%02X%02X%02X", T.mos(y, x, 0), T.mos(y, x, 1), T.mos(y, x, 2))
      else
        row[#row + 1] = string.format("'%s'   ", string.char(T.char(y, x)))
      end
    end
    out[#out + 1] = string.format("%2d %s", y, table.concat(row, " "))
  end
  return table.concat(out, "\n")
end

local function snap(tag, force)
  if snapped[tag] and not force then return end
  snapped[tag] = true
  T.snap()
  log("SNAP %s\n%s\n%s", tag, T.screen(), cells())
end

local function sig()
  local inv = {}
  for y = 0, T.rows - 1 do
    for x = 0, T.cols - 1 do
      if T.inv(y, x) then inv[#inv + 1] = y * 16 + x end
    end
  end
  return T.screen() .. "|" .. table.concat(inv, ",")
end

-- the aiming cursor: the square holding tile 8-10 on a live opponent's board
local function cursor()
  for s = 1, 3 do
    local o = ORG[s]
    for tr = 0, 3 do
      for tc = 0, 4 do
        local y, x = o[1] + tr, o[2] + tc
        if T.char(y, x) == 0xA0 then
          for k = 0, 2 do
            local m = T.mos(y, x, k)
            local sy = 3 * tr + k - 1
            if (m >> 4) >= 8 and (m >> 4) <= 10 then return 2 * tc, sy end
            if (m & 15) >= 8 and (m & 15) <= 10 then return 2 * tc + 1, sy end
          end
        end
      end
    end
  end
end

-- our board's mosaic, rows 6-9 columns 0-4: what a placement key changes
local function ours()
  local t = {}
  for y = 6, 9 do
    for x = 0, 4 do
      for k = 0, 2 do t[#t + 1] = string.format("%02X", T.mos(y, x, k)) end
    end
  end
  return table.concat(t)
end

local function press(key, why, want)
  log("press %d (%s)", key, why or "")
  T.press("A", key, 8)
  pending = { scr = sig(), t = T.now() + 6, want = want }
end

local function edit()
  local typed = T.row(3):gsub("^%s+", ""):gsub("_$", "")
  if typed ~= NAME:sub(1, #typed) then return press(1, "delete") end
  if typed == NAME then snap("name"); return press(3, "done") end
  local c = NAME:sub(#typed + 1, #typed + 1)
  local ty, tx
  for y, s in ipairs(GRID) do
    local x = s:find(c, 1, true)
    if x then ty, tx = y - 1, x - 1 end
  end
  local cy, cx
  for y = 5, 7 do
    for x = 0, 15 do
      if T.inv(y, x) then cy, cx = y - 5, x end
    end
  end
  if not cy then return end
  if cy == ty and cx == tx then return press(5, "type " .. c) end
  if cy ~= ty then return press(cy < ty and 8 or 2, "row") end
  return press(((tx - cx) % 16) <= 8 and 6 or 4, "column")
end

-- is square p still open on some live opponent? (the client's own rule)
local function open(p)
  local pc = rb(0)
  for s = 1, pc - 1 do
    local base = 49 + 115 * s
    if rb(base + 9) == 0 and rb(base + 10 + p) == 0 then return true end
  end
  return false
end

local menuDone, result = false, nil

local function aim()
  local x, y = cursor()
  if not x then return end
  if turns == 2 and not menuDone then
    menuDone = "open"
    return press(0, "the menu, mid-turn")
  end
  if open(y * 10 + x) then
    turns = turns + 1
    shots = shots + 1
    if turns == 1 then snap("turn1") end
    if turns == 12 then snap("turn12") end
    phase = "fired"
    return press(5, string.format("fire at %d,%d", x, y))
  end
  -- reading order: right, and at the end of a row 9 (down-right, wrapping)
  pending = { cursor = y * 10 + x, t = T.now() + 3 }
  log("press %d (step from %d,%d)", x < 9 and 6 or 9, x, y)
  T.press("A", x < 9 and 6 or 9, 6)
end

local function place()
  local row1 = T.row(1)
  local n = tonumber(row1:sub(1, 1))
  if not n then return end
  snap("placement")
  -- a placement key changes only mosaic cells, so wait on our board's
  if n == 1 and placeMoves == 0 then
    placeMoves = 1
    placeBefore = ours()
    log("press 6 (move the carrier right)")
    T.press("A", 6, 8)
    pending = { board = placeBefore, t = T.now() + 3 }
    return
  elseif n == 1 and placeMoves == 1 then
    placeMoves = 2
    moved = ours() ~= placeBefore
    placeBefore = ours()
    log("press 1 (turn the carrier)")
    T.press("A", 1, 8)
    pending = { board = placeBefore, t = T.now() + 3 }
    return
  elseif n == 1 and placeMoves == 2 then
    placeMoves = 3
    turned = ours() ~= placeBefore
    log("carrier moved: %s, turned: %s (either may be refused at an edge)",
        tostring(moved), tostring(turned))
    snap("placement moved")
  end
  if pending == nil and phase == "keep" and lastKeep == row1 then
    refused = refused + 1
    phase = "place"
    return press(3, "kept refused: roll again")
  end
  phase = "keep"
  lastKeep = row1
  kept = kept + 1
  return press(5, "keep ship " .. n)
end

T.every_frame(function()
  local t = T.now()
  if t > LIMIT then
    T.verdict(false, string.format("%s: out of time (%d turns)\n%s", phase, turns, T.screen()))
    return
  end
  local scr = sig()
  if scr ~= lastScreen then
    lastScreen = scr
    hold = math.max(hold, t + 0.25)
  end
  if pending then
    if pending.board then
      if ours() ~= pending.board or t > pending.t then pending = nil; hold = t + 0.1 end
      return
    end
    if pending.cursor then
      local x, y = cursor()
      if (x and y * 10 + x ~= pending.cursor) or t > pending.t then pending = nil; hold = t + 0.1 end
      return
    end
    if scr ~= pending.scr or t > pending.t then
      if scr == pending.scr then log("no change after the press") end
      pending = nil
      hold = t + 0.3
    end
    return
  end
  if t < hold then return end
  scr = T.screen()

  if T.find("NET ERROR") or T.row(8):find("NET", 13, true) then log("net error shown\n%s", scr) end
  if T.row(0):find("^MENU") then
    snap("menu")
    if phase == "leave" then return press(2, "leave the table") end
    menuDone = true
    return press(1, "back to the game")
  elseif phase == "leave" and T.find("1-8 JOIN") then
    snap("left")
    T.verdict(true, result .. "; left the table")
    return
  elseif phase == "leave" then
    return
  end
  if T.find("YOUR NAME") then
    snap("editor")
    phase = "name"
    return edit()
  elseif T.find("1-8 JOIN") then
    snap("tables")
    local r = T.find(TABLE, 1, 8)
    if not r then
      T.verdict(false, "no table " .. TABLE .. " in the list:\n" .. scr)
      return
    end
    phase = "join"
    return press(r, "join " .. T.row(r))
  elseif T.row(9):find("^5 READY") then
    snap("waiting room")
    return press(5, "ready")
  elseif T.row(9):find("^5 UNREADY") then
    snap("ready")
  elseif T.row(0):find("^PLACE YOUR FLEET") then
    return place()
  elseif T.row(0):find("^FLEET PLACED") then
    snap("placed")
  elseif T.row(1):find("YOUR", 13, true) and T.row(2):find("TURN", 13, true) then
    phase = "aim"
    return aim()
  elseif T.row(2):find("WIN", 13, true) or T.row(2):find("OVER", 13, true) then
    snap("game over")
    result = string.format("name %s at %s: placed (moved %s, turned %s, %d kept, %d refused), %d turns, %d shots, menu %s; %s %s",
        NAME, TABLE, tostring(moved), tostring(turned), kept, refused, turns, shots,
        tostring(menuDone), T.row(1):sub(13), T.row(2):sub(13))
    log("%s", result)
    phase = "leave"
    return press(0, "the menu, to leave")
  elseif T.row(1):find("WAIT", 13, true) and turns > 0 and turns % 10 == 0 then
    snap("waiting " .. turns)
  end
end)
