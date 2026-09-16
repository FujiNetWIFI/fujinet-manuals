local n=0
_G._p = emu.add_machine_frame_notifier(function()
    n=n+1
    if n ~= 60 then return end
    for tag, p in pairs(manager.machine.ioport.ports) do
        for fname, f in pairs(p.fields) do
            print(string.format("PORT %s  FIELD %q", tag, fname))
        end
    end
    manager.machine:exit()
end)
