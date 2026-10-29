-- ncdrive.lua -- netcat end to end: accept the URL, wait for the server's
-- greeting, type "hi" on the keyboard and send it, wait for the echo, then
-- 0 closes and goes back to CONFIG (the cartridge swaps once).
-- Snapshots: the greeting, the keyboard, the echo.
local T = dofile(os.getenv("S2_EMU_DIR") .. "/s2screen.lua")

_G.nc = _G.nc or { step = 1, t0 = 0, queue = {}, next = 0 }
local nc = _G.nc

local function has(s) return T.find(s) ~= nil end
local function snap_soon(tag)   -- the screen a moment later, settled
  nc.snapat, nc.snaptag = T.now() + 0.5, tag
end
local function keys(list)       -- "B9", "A6" ... pressed 0.25 s apart
  for _, k in ipairs(list) do nc.queue[#nc.queue + 1] = k end
end

local steps = {
  { "the URL editor", function() return has("5:ADD") and has("URL") end,
    function() snap_soon("url"); nc.next = T.now() + 0.8; keys({ "B9" }) end },
  { "the greeting", function() return has("NETCAT SAYS HI") end,
    function() snap_soon("greet"); nc.next = T.now() + 0.8; keys({ "A5" }) end },
  { "the line editor", function() return has("SEND") end,
    function() keys({ "A6", "A6", "A6", "A6", "A6", "A6", "A6", "A5", "A6", "A5" }) end },
  { "hi typed", function() return T.row(1):find("hi", 1, true) ~= nil end,
    function() snap_soon("typed"); nc.next = T.now() + 0.8; keys({ "A9" }) end },
  { "the echo", function() return has("ECHO HI") end,
    function() snap_soon("echo"); nc.next = T.now() + 0.8; keys({ "A0" }) end },
  { "back in CONFIG", function() return T.status(0x23) == 1 end,
    function() T.verdict(true, "netcat: greeting, typed hi, echo, CONFIG") end },
}

T.every_frame(function()
  local t = T.now()
  if nc.snapat and t >= nc.snapat then
    print("SNAP " .. nc.snaptag)
    T.snap()
    nc.snapat = nil
  end
  if #nc.queue > 0 and t >= nc.next then
    local k = table.remove(nc.queue, 1)
    T.press(k:sub(1, 1), tonumber(k:sub(2)), 6)
    nc.next = t + 0.25
    return
  end
  if #nc.queue > 0 then return end
  local s = steps[nc.step]
  if s[2]() then
    print(string.format("ncdrive: %s at %.1f s", s[1], t))
    nc.step, nc.t0 = nc.step + 1, t
    s[3]()
  elseif t - nc.t0 > 20 then
    print(T.screen())
    T.verdict(false, "stuck waiting for " .. s[1])
  end
end)
