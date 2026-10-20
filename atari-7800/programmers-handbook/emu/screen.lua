-- screen.lua -- read the screen the way MARIA does, and check it.
--
-- Write taps catch where the program points MARIA's display-list list
-- (DPPH $2C, DPPL $30) and its CTRL ($3C). At SHOT_AT seconds the script
-- walks the DLL zone by zone and every display list in it, and turns each
-- INDIRECT object (character text: 320A one-byte, or 320B two-byte as the
-- tile engine uses) into text at its column: so the same reader serves the
-- assembly programs' fujidisp, the C programs' tile engine and 7800basic's
-- plotchars and plotmap. Codes 32-126 are text (two-byte codes are halved).
--
-- Prints the cartridge's status line and the screen, snapshots it, and with
-- TEXT_WANT="ONE|TWO|..." passes only if every piece appears on some row
-- (case does not matter: the assembly font has no lower case).
if _G.__screen then return end
_G.__screen = { dll = 0, ctrl = 0, done = false }
local S = _G.__screen
local at = tonumber(os.getenv("SHOT_AT") or "6")
local want = os.getenv("TEXT_WANT")
local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local function b(a) return mem:read_u8(a & 0xFFFF) end

S.tap = mem:install_write_tap(0x0020, 0x003F, "fn_screen", function(off, data)
  if off == 0x2C then S.dll = (S.dll & 0x00FF) | (data << 8)
  elseif off == 0x30 then S.dll = (S.dll & 0xFF00) | data
  elseif off == 0x3C then S.ctrl = data end
end)

-- one display list: { {col, text}, ... }
local function objects(dl)
  local out, a = {}, dl
  for _ = 1, 64 do
    local m = b(a + 1)
    if b(a) == 0 and m == 0 then break end
    if m & 0x5F == 0x40 then                      -- five-byte header
      local lo, hi, pw, hp = b(a), b(a + 2), b(a + 3), b(a + 4)
      if m & 0x20 ~= 0 then                       -- indirect: characters
        local w = 32 - (pw & 0x1F)
        if pw & 0x1F == 0 then w = 32 end
        local two = (S.ctrl & 0x10) ~= 0          -- two-byte characters
        local s = {}
        for i = 0, w - 1 do
          local c = b((hi << 8 | lo) + i)
          if two then c = c >> 1 end
          s[#s + 1] = (c >= 32 and c < 127) and string.char(c) or " "
        end
        local cols = two and 1 or 1
        out[#out + 1] = { (hp // 4) * cols, table.concat(s) }
      end
      a = a + 5
    elseif m == 0 then break
    else a = a + 4 end                              -- four-byte header: graphics
  end
  return out
end

local function screen()
  local rows, y = {}, 0
  for z = 0, 40 do
    local e = S.dll + 3 * z
    local h = (b(e) & 0x0F) + 1
    local dl = b(e + 1) << 8 | b(e + 2)
    local objs = objects(dl)
    if #objs > 0 then
      local line = {}
      for _, o in ipairs(objs) do
        local col, txt = o[1], o[2]
        while #line < col do line[#line + 1] = " " end
        for i = 1, #txt do line[col + i] = txt:sub(i, i) end
      end
      for i = 1, #line do line[i] = line[i] or " " end
      local s = table.concat(line):gsub("%s+$", "")
      if s ~= "" then rows[#rows + 1] = string.format("%3d %s", y, s) end
    end
    y = y + h
    if y >= 262 then break end
  end
  return rows
end

S.sub = emu.add_machine_frame_notifier(function()
  if S.done or manager.machine.time:as_double() < at then return end
  S.done = true
  print(string.format("STATUS magic=%c%c mode=%d ackseq=%d err=%d replycmd=$%02X rxlen=%d inptlock=%d",
    b(0x0C09), b(0x0C0A), b(0x0C12), b(0x0C00), b(0x0C02), b(0x0C03),
    b(0x0C04) | b(0x0C05) << 8, b(0x0C1D)))
  local rows = screen()
  for _, r in ipairs(rows) do print(r) end
  manager.machine.screens[":screen"]:snapshot()
  if want then
    local all = table.concat(rows, "\n"):upper()
    local missing = {}
    for piece in want:gmatch("[^|]+") do
      if not all:find(piece:upper(), 1, true) then missing[#missing + 1] = piece end
    end
    print(#missing == 0 and "VERDICT PASS" or ("VERDICT FAIL: missing " .. table.concat(missing, ", ")))
  end
  manager.machine:exit()
end)
