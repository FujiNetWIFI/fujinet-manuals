-- status.lua -- after STATUS_AT seconds print the cart's status page (mode,
-- ACKSEQ, ERR, REPLY_CMD, RXLEN, INPTCTRL model) and snapshot the screen.
local at = tonumber(os.getenv("STATUS_AT") or "6")
_G.fn_status_done = _G.fn_status_done or false
local function sp() return manager.machine.devices[":maincpu"].spaces["program"] end
_G.fn_status_sub = emu.add_machine_frame_notifier(function()
  if _G.fn_status_done then return end
  if manager.machine.time:as_double() < at then return end
  _G.fn_status_done = true
  local s = sp()
  local function b(a) return s:read_u8(a) end
  print(string.format("STATUS magic=%c%c mode=%d ackseq=%d err=%d replycmd=$%02X rxlen=%d inptctrl=$%02X lock=%d handover=%d",
    b(0x0C09), b(0x0C0A), b(0x0C12), b(0x0C00), b(0x0C02), b(0x0C03),
    b(0x0C04) | b(0x0C05) << 8, b(0x0C1C), b(0x0C1D), b(0x0C25)))
  manager.machine.screens[":screen"]:snapshot()
  manager.machine:exit()
end)
