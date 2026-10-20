-- cfgshots.lua -- CONFIG's screens for the handbook: the status screen, the
-- host slots, /s2book/ on the SD card, adapter info, the WiFi networks and
-- the rename keyboard. Each step presses a key and waits for the screen to
-- answer it; then a snapshot. Nothing is changed on the adapter: the rename
-- is cancelled with 1.
local T = dofile(os.getenv("S2_EMU_DIR") .. "/s2screen.lua")

_G.cs = _G.cs or { i = 1, t0 = 0, acted = false }
local cs = _G.cs
local function title() return T.row(0) end
local function bar() return T.bar(1, 8, 2) end
local function press(k) T.press("A", k, 6) end

local steps = {
  { "status", nil, function() return T.find("FUJINET CONFIG") and T.find("WIFI CONNECTED") end, true },
  { "hosts", 5, function() return title():find("HOST SLOTS", 1, true) and bar() == 1 end, true },
  { "the SD", 5, function() return title():sub(1, 1) == "/" and T.find("s2book", 1, 8) end, false },
}
-- the bar down onto s2book, then into it
for _ = 1, 8 do
  steps[#steps + 1] = { "down", 8, function() return true end, false, function()
    local r = T.find("s2book", 1, 8)
    return r ~= nil and bar() == r
  end }
end
local more = {
  { "browse", 5, function() return title():find("/s2book/", 1, true) and T.row(1) ~= "" end, true },
  { "info", 3, function() return title() == "ADAPTER INFO" end, true },
  { "back", 5, function() return title() ~= "ADAPTER INFO" end, false },
  { "up", 0, function() return title() == "/" end, false },
  { "hosts again", 0, function() return title():find("HOST SLOTS", 1, true) end, false },
  { "wifi", 1, function() return title() == "WIFI NETWORKS" and T.row(1) ~= "" end, true },
  { "back to hosts", 0, function() return not title():find("WIFI", 1, true) end, false },
}
for _, s in ipairs(more) do steps[#steps + 1] = s end

T.every_frame(function()
  local t = T.now()
  local s = steps[cs.i]
  if not s then
    T.verdict(true, "CONFIG: " .. (cs.i - 1) .. " steps")
    return
  end
  if s[5] and s[5]() then                -- a skip: already there
    cs.i, cs.acted = cs.i + 1, false
    return
  end
  if not cs.acted then
    if #T.held == 0 and t - cs.t0 > 0.4 then
      if s[2] then press(s[2]) end
      cs.acted, cs.t0 = true, t
    end
    return
  end
  if t - cs.t0 > 0.3 and s[3]() then
    print(string.format("cfgshots: %s at %.1f s", s[1], t))
    if s[4] then print("SNAP " .. s[1]); T.snap() end
    cs.i, cs.acted, cs.t0 = cs.i + 1, false, t
  elseif t - cs.t0 > 15 then
    print(T.screen())
    T.verdict(false, "stuck at " .. s[1])
  end
end)
