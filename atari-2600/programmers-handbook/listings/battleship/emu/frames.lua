-- frames.lua -- every frame must be 262 lines.
--
-- Not by counting frames spent in a bank: that measures where the program is,
-- not whether anything is on screen. Not by sampling the screen either:
-- screen:pixel() reads a bitmap MAME updates on its own schedule. What is
-- unambiguous is the program's own VSYNC. Tap the write, measure the gap to
-- the previous one, and anything but 262 lines is a frame that moved the
-- picture -- a poll that blanked, a recompose that overran, a kernel line
-- that silently took two.
--
--   DRIVE_LUA=emu/drive.lua ./run.sh battleship frames
--
-- Without DRIVE_LUA it boots and sits wherever it lands.
if os.getenv("DRIVE_LUA") then dofile(os.getenv("DRIVE_LUA")) end

local FRAME = 1 / 59.92
local LINE  = FRAME / 262
local hist  = {}
local last, lastbank, n, bad = nil, 0, 0, 0

local function report()
    local keys = {}
    for k in pairs(hist) do keys[#keys+1] = k end
    table.sort(keys)
    local out = {}
    for _, k in ipairs(keys) do out[#out+1] = string.format("%d:%d", k, hist[k]) end
    print("LINES " .. table.concat(out, " "))
    print(string.format("FRAMES: %d of %d were not 262 lines", bad, n))
end

local sp = manager.machine.devices[":maincpu"].spaces["program"]
_G._frames = sp:install_write_tap(0x00, 0x00, "vsync", function(off, data, mask)
    if (data & 0x02) == 0 then return end          -- VSYNC going ON only
    local t = manager.machine.time:as_double()
    local bank = sp:readv_u8(0x1F0E)
    if last then
        local gap = t - last
        n = n + 1
        local lines = math.floor(gap / LINE + 0.5)
        hist[lines] = (hist[lines] or 0) + 1
        if lines ~= 262 then
            bad = bad + 1
            if bad <= 40 then
                print(string.format("BAD FRAME #%d: %d lines at %.2fs, bank %d -> %d",
                                    bad, lines, t, lastbank, bank))
            end
        end
        if n % 600 == 0 then report() end
    end
    last, lastbank = t, bank
end)
_G._frames_stop = emu.add_machine_stop_notifier(function() report() end)
