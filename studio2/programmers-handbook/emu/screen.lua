-- screen.lua -- the handbook's checker: run a program, press its keys, and
-- at SHOT_AT seconds print the status page and the screen, take a snapshot,
-- and check TEXT_WANT. Reads the device's save items only (s2screen.lua):
-- a Lua read of the address space would fire the cartridge's hotspots.
--
-- TEXT_WANT is a list of checks separated by '|':
--   text          somewhere on the screen, any case
--   @r,c=HH       the character at row r, column c is $HH
--   @r,c=i        that cell is in inverse video
--   %r,c=AABBCC   that mosaic cell's three tile pairs
--   $name=v       a status field: ackseq, err, mode, swaps, bootstate
-- KEYS presses keys: "A5@2 B9@3" holds pad A key 5 at 2 s, B 9 at 3 s.
-- RASTER, if set, names a file for the 1024 raster bytes, in hex.
local T = dofile(os.getenv("S2_EMU_DIR") .. "/s2screen.lua")

local at = tonumber(os.getenv("SHOT_AT") or "6")
local want = os.getenv("TEXT_WANT") or ""
local status = { ackseq = 0x00, err = 0x02, replycmd = 0x03, bootstate = 0x06,
                 mode = 0x12, link = 0x15, swaps = 0x23 }

local keys = {}
for pad, k, t in (os.getenv("KEYS") or ""):gmatch("([AB])(%d)@([%d%.]+)") do
  keys[#keys + 1] = { pad = pad, key = tonumber(k), t = tonumber(t) }
end

local function all_text()
  local rows = {}
  for y = 0, T.rows - 1 do rows[#rows + 1] = T.row(y) end
  return table.concat(rows, "\n"):lower()
end

local function check(w)
  local r, c, v = w:match("^@(%d+),(%d+)=(%w+)$")
  if r then
    r, c = tonumber(r), tonumber(c)
    if v == "i" then return T.inv(r, c) end
    return T.char(r, c) == tonumber(v, 16)
  end
  r, c, v = w:match("^%%(%d+),(%d+)=(%x%x%x%x%x%x)$")
  if r then
    r, c = tonumber(r), tonumber(c)
    for k = 0, 2 do
      if T.mos(r, c, k) ~= tonumber(v:sub(2 * k + 1, 2 * k + 2), 16) then return false end
    end
    return true
  end
  local name, val = w:match("^%$(%w+)=(%x+)$")
  if name then return status[name] and T.status(status[name]) == tonumber(val, 16) end
  return all_text():find(w:lower(), 1, true) ~= nil
end

_G.sc = _G.sc or { done = false }
local sc = _G.sc

T.every_frame(function()
  local t = T.now()
  for _, k in ipairs(keys) do
    if not k.sent and t >= k.t then T.press(k.pad, k.key, 8); k.sent = true end
  end
  if sc.done or t < at then return end
  sc.done = true
  print(string.format("STATUS ackseq %02X err %02X reply %02X mode %02X boot %02X swaps %02X",
    T.status(0x00), T.status(0x02), T.status(0x03), T.status(0x12),
    T.status(0x06), T.status(0x23)))
  print(T.screen())
  local f = os.getenv("RASTER")
  if f then
    local out = io.open(f, "w")
    for i = 0, 1023 do
      out:write(string.format("%02X", T.raster(i)))
      if i % 8 == 7 then out:write("\n") end
    end
    out:close()
  end
  T.snap()
  local missing = {}
  for w in want:gmatch("[^|]+") do
    w = w:match("^%s*(.-)%s*$")
    if w ~= "" and not check(w) then missing[#missing + 1] = w end
  end
  if #missing == 0 then
    T.verdict(true, want)
  else
    T.verdict(false, "missing: " .. table.concat(missing, " | "))
  end
end)
