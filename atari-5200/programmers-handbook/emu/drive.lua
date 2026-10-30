-- drive.lua -- press controller 1's keys and stick on a timetable, then read
-- the screen, save a snapshot and judge it.
--
--   PRESS   "t=a+b;t=-a;..."  at t seconds press a and b (held until
--           released), or release a with -a. Actions: fire (bottom
--           button), top, k0-k9, star, hash, start, pause, reset, and the
--           stick's left/right/up/down (an end of its travel) or x=NN/y=NN
--           (hex, 00-E4); -x / -y let it go back to the centre.
--   SHOT_AT seconds: then print the screen and snapshot (default 5)
--   WANT    "text|text|..." every piece must be on the screen for PASS
--
-- Times are emulated seconds. The keypad interrupt counts a held key once,
-- so press and release with at least 0.2 s between.
local T = dofile(os.getenv("A52_EMU_DIR") .. "/a52text.lua")
local shot_at = tonumber(os.getenv("SHOT_AT") or "5")
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
local AXES = { x = { ":analog_0", "AD Stick X" }, y = { ":analog_1", "AD Stick Y" } }
local ENDS = { left = { "x", 0x00 }, right = { "x", 0xE4 }, up = { "y", 0x00 }, down = { "y", 0xE4 } }

local function act(a, on)
  local ports = manager.machine.ioport.ports
  local k = KEYS[a]
  if k then
    ports[k[1]].fields[k[2]]:set_value(on and 1 or 0)
    return
  end
  local axis, val = a:match("^([xy])=(%x+)$")
  if not axis and ENDS[a] then axis, val = ENDS[a][1], string.format("%X", ENDS[a][2]) end
  if not axis and (a == "x" or a == "y") then axis = a end
  if axis then
    local f = ports[AXES[axis][1]].fields[AXES[axis][2]]
    if on and val then f:set_value(tonumber(val, 16)) else f:clear_value() end
    return
  end
  error("drive.lua: unknown action '" .. a .. "'")
end

local steps = {}
for t, acts in (os.getenv("PRESS") or ""):gmatch("([%d.]+)=([^;]+)") do
  steps[#steps + 1] = { t = tonumber(t), acts = acts, done = false }
end

_G.__drive_done = false
T.every_frame(function()
  if _G.__drive_done then return end
  local now = T.now()
  for _, s in ipairs(steps) do
    if not s.done and now >= s.t then
      s.done = true
      for a in s.acts:gmatch("[^+]+") do
        if a:sub(1, 1) == "-" then act(a:sub(2), false) else act(a, true) end
      end
    end
  end
  if now >= shot_at then
    _G.__drive_done = true
    local scr = T.screen()
    print(scr)
    manager.machine.screens[":screen"]:snapshot()
    if want then
      local missing = {}
      for piece in want:gmatch("[^|]+") do
        if not scr:find(piece, 1, true) then missing[#missing + 1] = piece end
      end
      T.verdict(#missing == 0, #missing == 0 and "all of WANT on screen"
        or ("missing: " .. table.concat(missing, " | ")))
    else
      manager.machine:exit()
    end
  end
end)
