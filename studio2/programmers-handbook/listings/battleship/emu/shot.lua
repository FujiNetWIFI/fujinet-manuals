-- shot.lua -- the DEMO build's four boards, headless: snapshots into
-- build/snap, the cell map on stdout, and a verdict on what the text engine
-- holds. `make shot` (it builds DEMO=1 first).
--
-- Frames, not seconds: machine.time.seconds is the integer second (the
-- Arcadia port's lesson). The demo needs no server; the cart is still asked
-- for its magic, so a fujinet-pc may as well be up, but nothing waits on it.
local T = dofile(os.getenv("S2_EMU_DIR") .. "/s2screen.lua")

local frame = 0
local problems = {}

local function check(ok, what)
  if not ok then problems[#problems + 1] = what end
end

-- A mosaic cell's six tiles, top-left to bottom-right, as a string of hex.
local function cell(y, x)
  if T.char(y, x) ~= 0xA0 then return string.format("'%s' ", string.char(T.char(y, x))) end
  local s = ""
  for k = 0, 2 do s = s .. string.format("%02X", T.mos(y, x, k)) end
  return s
end

local function dump()
  print(T.screen())
  for y = 0, 9 do
    local row = {}
    for x = 0, 10 do row[#row + 1] = cell(y, x) end
    print(string.format("%2d %s", y, table.concat(row, " ")))
  end
end

local function cursor_col(y)  -- the board column (0-9) holding a cursor tile on text row y, seat 1
  for x = 0, 4 do
    if T.char(y, x) == 0xA0 then
      for k = 0, 2 do
        local m = T.mos(y, x, k)
        if (m >> 4) >= 8 and (m >> 4) <= 10 then return x * 2 end
        if (m & 15) >= 8 and (m & 15) <= 10 then return x * 2 + 1 end
      end
    end
  end
end

T.every_frame(function()
  frame = frame + 1
  if frame == 300 then
    dump()
    T.snap()
    check(T.row(5):find("YOU", 1, true) == 1, "row 5 starts YOU")
    check(T.row(0):find("CLYDE", 1, true) == 1, "row 0 starts CLYDE")
    check(T.row(0):find("HULK", 1, true) == 7, "seat 2's name at column 6")
    check(T.row(5):find("JIM", 1, true) == 7, "seat 3's name at column 6")
    check(T.row(1):find("YOUR", 1, true) == 13 and T.row(2):find("TURN", 1, true) == 13,
          "the panel says YOUR TURN")
    check(T.row(4):find("HIT", 1, true) == 13, "the panel says HIT")
    for _, rc in ipairs({ {1, 0}, {4, 4}, {1, 6}, {4, 10}, {6, 0}, {9, 4}, {6, 6}, {9, 10} }) do
      check(T.char(rc[1], rc[2]) == 0xA0, string.format("cell %d,%d is a mosaic", rc[1], rc[2]))
    end
    check(T.inv(5, 0), "our name is in inverse: our move")
    -- the cursor starts at column 3, row 4: text row (4+1)//3 = 1 of each board
    check(cursor_col(2) == 3, "seat 1's cursor at column 3")
    T.press("A", 6, 4)                    -- right
  elseif frame == 330 then
    T.press("A", 3, 4)                    -- up and right
  elseif frame == 360 then
    dump()
    T.snap()
    check(cursor_col(2) == 5, "the cursor moved to column 5, row 3")
    T.verdict(#problems == 0, #problems == 0 and "four boards, names, panel, cursor"
              or table.concat(problems, "; "))
  end
end)
