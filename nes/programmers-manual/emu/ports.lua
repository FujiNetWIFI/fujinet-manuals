local done=false
emu.register_frame_done(function()
  if done then return end
  done=true
  for tag,port in pairs(manager.machine.ioport.ports) do
    for name,f in pairs(port.fields) do print(tag.." | "..name) end
  end
  manager.machine:exit()
end)
