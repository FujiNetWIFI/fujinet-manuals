-- walk.lua -- walk CONFIG (or a game) through its screens by what they say,
-- not by the clock, then snapshot one and judge it.
--
--   STEPS  "wait=FUJINET HOSTS;k8;fire;wait=/;pause=20;shot"
--          wait=TEXT   until TEXT is on the screen (WAITMAX frames at most)
--          gone=TEXT   until TEXT has left it
--          pause=N     N frames
--          pct=LO-HI   until the screen shows a percentage from LO to HI
--                      (fails if it passes HI first)
--          shot        print the screen, snapshot it, and finish
--          reset       the console's RESET (a soft reset: the cart keeps
--                      its state, as on the real console)
--          anything else is a key, pressed 8 frames and let go 8 frames:
--          k0-k9, fire (the same wire as k2), clr, ent, the disc's
--          up/down/left/right, and the console's start/select/option
--   WANT   "text|text" every piece on the screen at the shot, for PASS
--   ROWS   13 (CONFIG, the lobby) or 26 (the games' 26-line mode: rows
--          13-25 come from $1A00)
--   SWAP   "from=>to|..." text put over the screen just before the shot
--          (fujinet-pc's invented WiFi names, this computer's addresses)
--
-- The screen is read from the 2637's RAM: each byte is two colour bits and
-- a 6-bit glyph, read through the charset below ($38-$3F are the program's
-- own characters; CONFIG draws / - _ ( ) % ? : there). Frames, never
-- seconds: machine.time.seconds is an integer here.

local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local ports = manager.machine.ioport.ports
local ROWS = tonumber(os.getenv("ROWS") or "13")
local WAITMAX = tonumber(os.getenv("WAITMAX") or "3600")
local want = os.getenv("WANT")

local CH = " /\\#^|_|++++<>><0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ.,+$/-_()%?:"

local function addr(r, c)
  if r < 13 then return 0x1800 + r * 16 + c end
  return 0x1A00 + (r - 13) * 16 + c
end

local function row(r)
  local s, gfx = {}, false
  for c = 0, 15 do
    local b = mem:read_u8(addr(r, c))
    if b == 0xC0 then gfx = true end
    local ch
    if gfx then
      ch = (b == 0xC0) and " " or ((b & 0x3F) == 0 and "." or "=")
    else
      local g = b & 0x3F
      ch = CH:sub(g + 1, g + 1)
    end
    s[#s + 1] = ch
  end
  return table.concat(s)
end

local function screen()
  local t = {}
  for r = 0, ROWS - 1 do t[#t + 1] = row(r) end
  return table.concat(t, "\n")
end

local function dump()
  print("+----------------+")
  for r = 0, ROWS - 1 do
    local hex = ""
    if os.getenv("HEX") then
      local h = {}
      for c = 0, 15 do h[#h + 1] = string.format("%02X", mem:read_u8(addr(r, c))) end
      hex = " " .. table.concat(h, " ")
    end
    print("|" .. row(r) .. "|" .. hex)
  end
  print("+----------------+")
end

-- ---------- keys --------------------------------------------------------
local KEYS = {
  k1 = {":controller1_col1", "P1 Keypad 1"}, k4 = {":controller1_col1", "P1 Keypad 4"},
  k7 = {":controller1_col1", "P1 Keypad 7"}, clr = {":controller1_col1", "P1 Keypad Clear"},
  k2 = {":controller1_col2", "P1 Keypad 2/Button"}, fire = {":controller1_col2", "P1 Keypad 2/Button"},
  k5 = {":controller1_col2", "P1 Keypad 5"}, k8 = {":controller1_col2", "P1 Keypad 8"},
  k0 = {":controller1_col2", "P1 Keypad 0"},
  k3 = {":controller1_col3", "P1 Keypad 3"}, k6 = {":controller1_col3", "P1 Keypad 6"},
  k9 = {":controller1_col3", "P1 Keypad 9"}, ent = {":controller1_col3", "P1 Keypad Enter"},
  start = {":panel", "Start"}, option = {":panel", "Option"}, select = {":panel", "Select"},
}
local DISC = {up = 0x08, down = 0x04, left = 0x01, right = 0x02}

local function field(key)
  if DISC[key] then
    for _, f in pairs(ports[":joysticks"].fields) do
      if f.mask == DISC[key] then return f end
    end
  end
  local k = KEYS[key]
  if not k then error("walk.lua: unknown action '" .. key .. "'") end
  return ports[k[1]].fields[k[2]]
end

-- ---------- SWAP ------------------------------------------------------
local function glyph(ch)
  if ch == " " then return 0 end
  if ch:match("%d") then return 0x10 + tonumber(ch) end
  if ch:match("%a") then return 0x1A + (ch:upper():byte() - 65) end
  local i = CH:find(ch, 0x34, true)            -- . , + $ and the UDCs
  if i then return i - 1 end
  error("walk.lua: no glyph for '" .. ch .. "'")
end
local swaps = {}
for from, to in (os.getenv("SWAP") or ""):gmatch("([^|]-)=>([^|]*)") do
  swaps[#swaps + 1] = {from:upper(), to .. string.rep(" ", math.max(0, #from - #to))}
end
-- POKES "r,c,XX|..." raw screen bytes set with the SWAP (the signal cells)
local pokes = {}
for r, c, v in (os.getenv("POKES") or ""):gmatch("(%d+),(%d+),(%x%x)") do
  pokes[#pokes + 1] = {tonumber(r), tonumber(c), tonumber(v, 16)}
end
local function swap()
  for _, p in ipairs(pokes) do mem:write_u8(addr(p[1], p[2]), p[3]) end
  for r = 0, ROWS - 1 do
    local text = row(r)
    for _, s in ipairs(swaps) do
      local i = text:upper():find(s[1], 1, true)
      if i then
        -- every new cell takes the colour of the first one it replaces
        local ink = mem:read_u8(addr(r, i - 1)) & 0xC0
        for k = 1, #s[2] do
          local c = i - 1 + k - 1
          if c > 15 then break end
          mem:write_u8(addr(r, c), ink | glyph(s[2]:sub(k, k)))
        end
        text = row(r)
      end
    end
  end
end

-- ---------- the walk ----------------------------------------------------
local steps = {}
for s in (os.getenv("STEPS") or "shot"):gmatch("[^;]+") do steps[#steps + 1] = s end
local frame, i, held, phase, waited, swapping, pausing = 0, 1, nil, 0, 0, false, nil

local function finish(ok, msg)
  _G.__walk_done = true
  print("VERDICT " .. (ok and "PASS" or "FAIL") .. ": " .. msg .. " (frame " .. frame .. ")")
  manager.machine:exit()
end

_G.__walk_sub = emu.add_machine_frame_notifier(function()
  if _G.__walk_done then return end
  frame = frame + 1
  if frame < 30 then return end               -- ioports are not ready at once
  if swapping then swap() end
  if held then
    phase = phase + 1
    if phase == 8 then held:clear_value() end
    if phase < 16 then return end
    held = nil
  end
  local s = steps[i]
  if s == nil then return finish(false, "steps ran out before a shot") end
  local k, v = s:match("^(%a+)=(.*)$")
  if k == "wait" or k == "gone" then
    local here = screen():upper():find(v:upper(), 1, true) ~= nil
    if (k == "wait") == here then i = i + 1; waited = 0
    else
      waited = waited + 1
      if waited > WAITMAX then dump(); return finish(false, "timed out at " .. s) end
    end
  elseif k == "pct" then
    local lo, hi = v:match("(%d+)-(%d+)")
    local p = tonumber(screen():match("(%d+)%%"))
    if p and p >= tonumber(lo) and p <= tonumber(hi) then i = i + 1
    elseif p and p > tonumber(hi) then dump(); return finish(false, "passed " .. hi .. "%") end
  elseif k == "pause" then
    pausing = (pausing or tonumber(v)) - 1
    if pausing <= 0 then pausing = nil; i = i + 1 end
  elseif s == "reset" then
    manager.machine:soft_reset(); i = i + 1
  elseif s == "shot" then
    if not swapping and (#swaps > 0 or #pokes > 0) then swapping = true; swap(); pausing = 3; return end
    if pausing then pausing = pausing - 1; if pausing > 0 then return end end
    dump()
    manager.machine.video:snapshot()
    local scr = screen():upper()
    local missing = {}
    for piece in (want or ""):gmatch("[^|]+") do
      if not scr:find(piece:upper(), 1, true) then missing[#missing + 1] = piece end
    end
    return finish(#missing == 0, #missing == 0 and "all of WANT on screen"
      or ("missing: " .. table.concat(missing, " | ")))
  else
    held = field(s); held:set_value(1); phase = 0; i = i + 1
  end
end)
