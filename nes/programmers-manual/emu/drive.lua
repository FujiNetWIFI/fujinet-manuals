-- drive.lua -- press buttons on controller 1 from a script, then print the
-- screen and save a snapshot.
--   DRIVE  steps, separated by spaces:
--            w<secs>      wait
--            <BUTTON>[*n] press and release (A B Select Start Up Down Left Right)
--            Reset        the console's Reset button (the cartridge keeps running)
--   The screen is shot after the last step.
--
-- MAME runs the autoboot script again after a soft reset, with the Lua state
-- and the clock carrying on, so the script's progress lives in _G.
local T = dofile(os.getenv("NES_EMU_DIR") .. "/nestext.lua")
local pad = manager.machine.ioport.ports[":ctrl1:joypad:JOYPAD"]

if _G.__drive == nil then
  local steps = {}
  for tok in (os.getenv("DRIVE") or ""):gmatch("%S+") do
    local secs = tok:match("^w([%d.]+)$")
    if secs then
      steps[#steps + 1] = { wait = tonumber(secs) }
    else
      local b, n = tok:match("^(%a+)%*?(%d*)$")
      for _ = 1, tonumber(n) or 1 do steps[#steps + 1] = { button = b } end
    end
  end
  _G.__drive = { steps = steps, i = 1, phase = 0, until_t = 0 }
end
local D = _G.__drive

T.every_frame(function()
  local now = T.now()
  if now < D.until_t then return end
  local s = D.steps[D.i]
  if not s then
    if D.done then return end
    D.done = true
    print(T.screen())
    manager.machine.screens[":screen"]:snapshot()
    manager.machine:exit()
    return
  end
  if s.wait then
    D.until_t = now + s.wait; D.i = D.i + 1
  elseif s.button == "Reset" then
    D.until_t = now + 0.2; D.i = D.i + 1
    manager.machine:soft_reset()
  elseif D.phase == 0 then
    pad.fields["P1 " .. s.button]:set_value(1); D.phase = 1; D.until_t = now + 0.07
  else
    pad.fields["P1 " .. s.button]:set_value(0); D.phase = 0; D.until_t = now + 0.07
    D.i = D.i + 1
  end
end)
