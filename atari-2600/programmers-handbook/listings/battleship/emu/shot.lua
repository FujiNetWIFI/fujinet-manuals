-- Snapshot the screen after SHOT_FRAMES frames, then exit a few frames later.
-- The exit must not share a frame with the snapshot or the file never flushes.
-- SHOT_SELECT=1 taps the SELECT switch first, for the layout ROM's other mode.
local target = tonumber(os.getenv("SHOT_FRAMES") or "180")
local sel = os.getenv("SHOT_SELECT")
local n = 0
_G._shot_token = emu.add_machine_frame_notifier(function()
    n = n + 1
    if sel and n == 60 then
        manager.machine.ioport.ports[":SWB"].fields["Select Game"]:set_value(1)
    elseif sel and n == 64 then
        manager.machine.ioport.ports[":SWB"].fields["Select Game"]:set_value(0)
    end
    if n == target then
        manager.machine.video:snapshot()
    elseif n == target + 15 then
        manager.machine:exit()
    end
end)
