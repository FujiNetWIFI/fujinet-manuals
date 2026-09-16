-- txn.lua -- did the client complete one transaction, and what came back?
-- Waits on the cartridge's own state (the 'FN' magic, then ACKSEQ != 0),
-- never on a frame number; prints the status cells and the reply's first
-- bytes as text; PASS when the transport reported no error and the reply is
-- the 240-byte AdapterConfigExtended (SSID at 0, version at 125, IP at 140).
local sp = manager.machine.devices[":maincpu"].spaces["program"]
local waited, done = 0, false
local want = tonumber(os.getenv("TXN_RXLEN") or "240")
local function str(off, max)
    local s = ""
    for i = 0, max - 1 do
        local c = sp:readv_u8(0x1B00 + off + i)
        if c == 0 then break end
        if c < 0x20 or c > 0x7E then c = 0x3F end
        s = s .. string.char(c)
    end
    return s
end
_G._txn = emu.add_machine_frame_notifier(function()
    if done then return end
    if sp:readv_u8(0x1F09) ~= 0x46 or sp:readv_u8(0x1F0A) ~= 0x4E then
        waited = waited + 1
        if waited > 600 then print("FAIL: no cartridge answered"); done = true; manager.machine:exit() end
        return
    end
    local ack = sp:readv_u8(0x1F00)
    if ack == 0 then
        waited = waited + 1
        if waited > 900 then print("FAIL: no transaction completed"); done = true; manager.machine:exit() end
        return
    end
    done = true
    local err, rcmd = sp:readv_u8(0x1F02), sp:readv_u8(0x1F03)
    local rxlen = sp:readv_u8(0x1F04) + 256 * sp:readv_u8(0x1F05)
    print(string.format("TXN ackseq=%02X err=%d reply=%02X rxlen=%d status=%02X bank=%02X zp=%02X %02X %02X",
        ack, err, rcmd, rxlen, sp:readv_u8(0x1F01), sp:readv_u8(0x1F0E),
        sp:readv_u8(0xF0), sp:readv_u8(0xF1), sp:readv_u8(0xF2)))
    print("TXN ssid=" .. str(0, 33) .. " ver=" .. str(125, 15) .. " ip=" .. str(140, 16))
    if err == 0 and rcmd == 6 and rxlen == want then print("PASS") else print("FAIL") end
    manager.machine:exit()
end)
