-- smoke.lua: headless boot of the C demo.  Press keypad 1 at the OS menu
-- (the demo registers as the first entry), then snapshot the adapter-
-- config screen.  Timed on emulated seconds; run with:
--   mame ... -autoboot_script emu/smoke.lua -video none -sound none \
--        -seconds_to_run 20 -snapshot_directory build
local pressed, released, shot = false, false, false
emu.register_frame(function()
    local t = manager.machine.time.seconds
    local port = manager.machine.ioport.ports[":KEYPAD3"]
    if port == nil then return end
    if not pressed and t >= 3 then
        emu.print_info("smoke.lua: pressing '1'")
        port:field(0x10):set_value(1)
        pressed = true
    elseif pressed and not released and t >= 5 then
        port:field(0x10):clear_value()
        released = true
    elseif released and not shot and t >= 14 then
        emu.print_info("smoke.lua: snapshot")
        manager.machine.video:snapshot()
        shot = true
    end
end)
