-- dragster.lua -- drive one Dragster run in local play, for the manual's shot.
--
-- The schedule is the Dragster port's own emu/drive.lua (how its controls were
-- worked out), shifted to start after the boot bank's NO NETWORK screen, and
-- driven like a person reading the tachometer: the stick pushed RIGHT stages
-- the race, the GEAR LEVER IS THE STICK PULLED LEFT (pull to arm a shift, let
-- go to take the gear -- which is also the launch), and the button is the
-- throttle. Shifts are taken when the revs reach SHIFT, so the engine is not
-- blown before the picture is taken.
--
--   DG_START  frame the game is on screen (default 120: after NO NETWORK)
--   SHIFT     rev count to shift at (RAM $A8; default 24 -- it blows at 32)
--   SNAPS     frames after the launch to snapshot at, comma separated
local mem
local F = {}
for _, port in pairs(manager.machine.ioport.ports) do
    for name, field in pairs(port.fields) do F[name] = field end
end
local function set(n, v) if F[n] then F[n]:set_value(v and 1 or 0) end end

local START = tonumber(os.getenv("DG_START") or "120")
local SHIFT = tonumber(os.getenv("SHIFT") or "24")    -- it blows at 32
local snaps = {}
for s in (os.getenv("SNAPS") or "60"):gmatch("%d+") do snaps[tonumber(s)] = true end
local last = 0
for k in pairs(snaps) do if k > last then last = k end end

local f, launched, lever, leverat, nsnap, seencd = 0, nil, false, 0, 0, false
local CD, GEAR, RPM, BLOWN, SEC, HUN = 0x8D, 0xCC, 0xA8, 0xCE, 0xB3, 0xB5

_G._dg = emu.add_machine_frame_notifier(function()
    mem = mem or manager.machine.devices[":maincpu"].spaces["program"]
    f = f + 1
    local t = f - START
    if t < 0 then return end
    set("P1 Right", t >= 0 and t < 30)             -- stage the race
    local cd, gear, rpm = mem:read_u8(CD), mem:read_u8(GEAR), mem:read_u8(RPM)
    if not launched then
        -- arm the lever early, let go the moment the tree runs out
        if cd ~= 0 then seencd = true end
        if t % 20 == 0 then print(string.format("DG: t%d cd=%02X", t, cd)) end
        if t >= 40 then set("P1 Left", true) end
        if t >= 40 and seencd and cd == 0 then
            set("P1 Left", false)
            set("P1 Button 1", true)
            launched = f
            print(string.format("DG: launched at f%d", f))
        elseif t > 1200 then
            print("DG: never launched"); manager.machine:exit()
        end
        return
    end
    local s = f - launched
    -- shift: pull and let go when the revs are up
    -- off the throttle while the lever is out: a clutch with the throttle
    -- down is a free-revving engine, and that is what blows it
    if lever and f >= leverat + 4 then
        set("P1 Left", false); set("P1 Button 1", true); lever = false
    elseif not lever and rpm >= SHIFT and f >= leverat + 20 and (gear & 0x7F) < 4 then
        set("P1 Button 1", false); set("P1 Left", true); lever = true; leverat = f
    end
    if s % 10 == 0 then
        print(string.format("DG: +%d gear=%02X rpm=%02X blown=%02X time=%02X.%02X",
            s, gear, rpm, mem:read_u8(BLOWN), mem:read_u8(SEC), mem:read_u8(HUN)))
    end
    if snaps[s] then
        manager.machine.video:snapshot()
        nsnap = nsnap + 1
        print(string.format("DG: snapshot %d at +%d (f%d)", nsnap, s, f))
    end
    if s >= last + 15 then manager.machine:exit() end
end)
