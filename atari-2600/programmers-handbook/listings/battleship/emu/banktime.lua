-- banktime.lua -- where does a poll's time go? Timestamps every bank switch
-- (a store to the control page's bank hotspot) and every VSYNC, and prints
-- the gaps in scanlines around each frame that is not 262 lines.
--
--   DRIVE_LUA=emu/drive.lua ./run.sh battleship banktime
if os.getenv("DRIVE_LUA") then dofile(os.getenv("DRIVE_LUA")) end

local FRAME = 1 / 59.92
local LINE  = FRAME / 262
local sp = manager.machine.devices[":maincpu"].spaces["program"]
local events = {}
local lastv = nil
local shown = 0

local function now() return manager.machine.time:as_double() end

_G._bt_bank = sp:install_write_tap(0x1D80, 0x1D86, "bank", function(off, data, mask)
    events[#events + 1] = { t = now(), what = string.format("->bank %d", off - 0x1D80) }
end)
_G._bt_vsync = sp:install_write_tap(0x00, 0x00, "vsync", function(off, data, mask)
    if (data & 0x02) == 0 then return end
    local t = now()
    if lastv then
        local lines = math.floor((t - lastv) / LINE + 0.5)
        if lines ~= 262 and shown < 12 then
            shown = shown + 1
            local out = {}
            local prev = lastv
            for _, e in ipairs(events) do
                out[#out + 1] = string.format("%s at +%.1f lines", e.what, (e.t - prev) / LINE)
            end
            print(string.format("FRAME of %d lines: %s", lines, table.concat(out, "; ")))
        end
    end
    events = {}
    lastv = t
end)
