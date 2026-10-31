-- walk.lua -- walk CONFIG through its screens by what they say, not by the
-- clock, then snapshot one and judge it.
--
--   STEPS  "wait=HOST SLOTS;k8;k8;hash;wait=/GAMES/;pause=0.4;shot"
--          wait=TEXT   until TEXT is on the screen (60 s at most)
--          gone=TEXT   until TEXT has left it
--          pause=S     S emulated seconds
--          pct=LO-HI   until the screen shows a percentage from LO to HI
--                      (fails if it passes HI first)
--          shot        print the screen, snapshot it, and finish
--          anything else is a key or stick action, as the Programmer's
--          Handbook's emu/drive.lua names them (fire, top, k0-k9, star,
--          hash, start, pause, reset, up, down, left, right): pressed for
--          0.16 s, then 0.16 s let go
--   WANT   "text|text" every piece on the screen at the shot, for PASS
--   A52_SCREEN, A52_ROWS  where the screen is and how tall (CONFIG's, or a
--          game's: 40 x 26 at $3000 or $3400); A52_GLYPHS=bs for Battleship
--   SWAP   "from=>to|..." text put over the screen just before the shot,
--          as emu/tour.lua (fujinet-pc's invented WiFi names, this
--          computer's addresses)
local T = dofile(os.getenv("A52_EMU_DIR") .. "/a52text.lua")
T.rows = tonumber(os.getenv("A52_ROWS") or "24")   -- the games draw 26 rows
-- Battleship keeps its letters as ASCII ($41-$5A) beside ANTIC-coded
-- digits and art: A52_GLYPHS=bs reads them so
if os.getenv("A52_GLYPHS") == "bs" then
  T.row = function(y)
    local s = {}
    for x = 0, T.cols - 1 do
      local c = T.space():read_u8(T.base + y * T.cols + x) & 0x7F
      local ch
      if c >= 0x41 and c <= 0x5A then ch = c
      elseif c >= 0x70 and c <= 0x79 then ch = c - 0x40
      elseif c >= 0x10 and c <= 0x19 then ch = c + 0x20
      elseif c == 0x00 or c == 0x40 then ch = 0x20
      elseif c < 0x40 then ch = 0x23
      else ch = 0x20 end
      s[#s + 1] = string.char(ch)
    end
    return (table.concat(s):gsub("%s+$", ""))
  end
end
local want = os.getenv("WANT")

local KEYS = {
  fire = { ":djoy_b", "P1 Button 1" }, top = { ":djoy_b", "P1 Button 2" },
  hash = { ":keypad.0", "[#]" }, star = { ":keypad.0", "[*]" }, k0 = { ":keypad.0", "[0]" },
  reset = { ":keypad.1", "Reset" }, k7 = { ":keypad.1", "[7]" },
  k8 = { ":keypad.1", "[8]" }, k9 = { ":keypad.1", "[9]" },
  pause = { ":keypad.2", "Pause" }, k4 = { ":keypad.2", "[4]" },
  k5 = { ":keypad.2", "[5]" }, k6 = { ":keypad.2", "[6]" },
  start = { ":keypad.3", "Start" }, k1 = { ":keypad.3", "[1]" },
  k2 = { ":keypad.3", "[2]" }, k3 = { ":keypad.3", "[3]" },
}
local AXES = { left = { ":analog_0", "AD Stick X", 0x00 }, right = { ":analog_0", "AD Stick X", 0xE4 },
               up = { ":analog_1", "AD Stick Y", 0x00 }, down = { ":analog_1", "AD Stick Y", 0xE4 } }

local function act(a, on)
  local ports = manager.machine.ioport.ports
  if KEYS[a] then
    ports[KEYS[a][1]].fields[KEYS[a][2]]:set_value(on and 1 or 0)
  elseif AXES[a] then
    local f = ports[AXES[a][1]].fields[AXES[a][2]]
    if on then f:set_value(AXES[a][3]) else f:clear_value() end
  else
    error("walk.lua: unknown action '" .. a .. "'")
  end
end

local swaps = {}
for from, to in (os.getenv("SWAP") or ""):gmatch("([^|]-)=>([^|]*)") do
  swaps[#swaps + 1] = { from, to .. string.rep(" ", math.max(0, #from - #to)) }
end
local function code(ch)
  local c = ch:byte()
  if c >= 0x20 and c < 0x60 then return c - 0x20 end
  return c
end
local function swap()
  local sp = T.space()
  for y = 0, T.rows - 1 do
    local row = T.row(y)
    for _, s in ipairs(swaps) do
      local i = row:find(s[1], 1, true)
      if i then
        for k = 1, #s[2] do
          local a = T.base + y * T.cols + (i - 1) + (k - 1)
          sp:write_u8(a, code(s[2]:sub(k, k)) | (sp:read_u8(a) & 0x80))
        end
        row = T.row(y)
      end
    end
  end
end

local steps = {}
for s in (os.getenv("STEPS") or "shot"):gmatch("[^;]+") do steps[#steps + 1] = s end
local i, t0, phase, held, swapping = 1, nil, "go", nil, false

local function finish(ok, msg)
  _G.__walk_done = true
  T.verdict(ok, msg)
end

_G.__walk_sub = emu.add_machine_frame_notifier(function()
  if _G.__walk_done then return end
  local now = T.now()
  if swapping then swap() end
  if t0 == nil then t0 = now end
  if held then
    if now - t0 >= 0.16 then act(held, false); held = nil; t0 = now end
    return
  end
  if now - t0 < 0.16 then return end
  local s = steps[i]
  if s == nil then return end
  local k, v = s:match("^(%a+)=(.*)$")
  if k == "wait" or k == "gone" then
    local here = T.screen():find(v, 1, true) ~= nil
    if (k == "wait") == here then i = i + 1; t0 = now
    elseif now > 60 + (_G.__walk_since or now) then
      print(T.screen()); finish(false, "timed out at " .. s)
    end
    _G.__walk_since = _G.__walk_since or now
    if (k == "wait") == here then _G.__walk_since = nil end
  elseif k == "pct" then
    local lo, hi = v:match("(%d+)-(%d+)")
    local p = tonumber(T.screen():match("(%d+)%%"))
    if p and p >= tonumber(lo) and p <= tonumber(hi) then i = i + 1; t0 = now
    elseif p and p > tonumber(hi) then print(T.screen()); finish(false, "passed " .. hi .. "%") end
  elseif k == "pause" then
    if now - t0 >= tonumber(v) then i = i + 1; t0 = now end
  elseif s == "shot" then
    if not swapping and #swaps > 0 then swapping = true; swap(); t0 = now; return end
    if now - t0 < 0.1 then return end
    local scr = T.screen()
    print(scr)
    manager.machine.screens[":screen"]:snapshot()
    local missing = {}
    for piece in (want or ""):gmatch("[^|]+") do
      if not scr:find(piece, 1, true) then missing[#missing + 1] = piece end
    end
    finish(#missing == 0, #missing == 0 and "all of WANT on screen"
      or ("missing: " .. table.concat(missing, " | ")))
  else
    act(s, true); held = s; t0 = now; i = i + 1
  end
end)
