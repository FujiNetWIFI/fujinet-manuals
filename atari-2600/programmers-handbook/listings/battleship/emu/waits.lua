-- waits.lua -- do the completion waits spin? Counts reads of FN_B_BLITGEN
-- and FN_B_TEXTGEN and the blit/row fires per frame, and prints the frames
-- where a wait read more than a few times per fire.
if os.getenv("DRIVE_LUA") then dofile(os.getenv("DRIVE_LUA")) end
local sp = manager.machine.devices[":maincpu"].spaces["program"]
local rb, rt, fb, ft = 0, 0, 0, 0
local shown = 0
_G._w1 = sp:install_read_tap(0x1F19, 0x1F19, "bgen", function(off, data, mask) rb = rb + 1 end)
_G._w2 = sp:install_read_tap(0x1F0D, 0x1F0D, "tgen", function(off, data, mask) rt = rt + 1 end)
_G._w3 = sp:install_write_tap(0x1DFA, 0x1DFA, "bgo", function(off, data, mask) fb = fb + 1 end)
_G._w4 = sp:install_write_tap(0x1DF2, 0x1DF2, "tend", function(off, data, mask) ft = ft + 1 end)
_G._w5 = sp:install_write_tap(0x00, 0x00, "vs", function(off, data, mask)
    if (data & 0x02) == 0 then return end
    if (fb > 0 or ft > 0) and shown < 15 then
        shown = shown + 1
        print(string.format("FRAME: %d blits, %d BLITGEN reads (%.1f each); %d rows, %d TEXTGEN reads (%.1f each); BLITGEN=%02X TEXTGEN=%02X",
              fb, rb, fb > 0 and rb / fb or 0, ft, rt, ft > 0 and rt / ft or 0,
              sp:readv_u8(0x1F19), sp:readv_u8(0x1F0D)))
    end
    rb, rt, fb, ft = 0, 0, 0, 0
end)
