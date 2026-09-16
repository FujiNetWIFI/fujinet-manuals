-- probe.lua -- is a FujiNet cartridge answering, and did it honour the claim?
-- Reads the painted magic ('F','N' at $1F09/$1F0A) and FN_B_FLAGS ($1F0F,
-- bit1 = claim honoured), the live bank and ACKSEQ, then exits.
local sp = manager.machine.devices[":maincpu"].spaces["program"]
local n = 0
_G._probe = emu.add_machine_frame_notifier(function()
    n = n + 1
    if n ~= 120 then return end
    local f, nn = sp:readv_u8(0x1F09), sp:readv_u8(0x1F0A)
    local flags, bank, ack = sp:readv_u8(0x1F0F), sp:readv_u8(0x1F0E), sp:readv_u8(0x1F00)
    print(string.format("PROBE magic=%02X%02X flags=%02X bank=%02X ackseq=%02X",
                        f, nn, flags, bank, ack))
    if f == 0x46 and nn == 0x4E and (flags & 2) ~= 0 then
        print("PASS: cartridge answering, claim honoured")
    else
        print("FAIL: no cartridge / claim not honoured")
    end
    manager.machine:exit()
end)
