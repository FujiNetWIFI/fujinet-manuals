 rem boot.bas -- push a program from the SD card into the cartridge and
 rem run it. MOUNT_HOST, SET_DEVICE_FULLPATH, then MOUNT_IMAGE, which makes
 rem the FujiNet push the image into the cartridge's RAM. When BOOT_STATE
 rem says READY, arm BOOTLOCK and jump to the loader at $0600.
 incbasic fujinet.bas

 rem leave INPTCTRL unlocked, so a game can still be handed to the
 rem console's own BIOS, and so keep every TIA register untouched
 const NOTIALOCK = 1
 const NOTIALOCKMUTE = 1

 displaymode 320A
 set zoneheight 8
 incgraphic fujifont.png 320A
 characterset fujifont
 alphachars ASCII
 BACKGRND = $00
 P0C2 = $0F

 const HOSTSL = 0
 const DEVSL = 0
 const FMREAD = 1
 dim bar = $2200
 dim ix = var0
 dim shown = var1

 for ix = 0 to 24 : bar[ix] = 32 : next
 clearscreen
 plotchars 'BOOT /A7800BOOK/HELLO.BIN' 0 8 2
 plotchars bar 0 8 4 25
 gosub fn_chk
 if fn_res <> FN_OK then goto failed

 rem MOUNT_HOST: the host slot
 fn_dev = FN_FUJI : fn_cmd = $F9 : fn_npr = 1
 gosub fn_beg
 fn_val = HOSTSL : gosub fn_pb
 gosub fn_go
 if fn_res <> FN_OK then goto failed

 rem SET_DEVICE_FULLPATH: device slot, host slot, mode, then 256 of path
 fn_dev = FN_FUJI : fn_cmd = $E2 : fn_npr = 3
 gosub fn_beg
 fn_val = DEVSL : gosub fn_pb
 fn_val = HOSTSL : gosub fn_pb
 fn_val = FMREAD : gosub fn_pb
 fn_i = 0
set_path
 FN_TX = path[fn_i]
 fn_i = fn_i + 1
 if fn_i < path_length then goto set_path
 gosub fn_pad
 gosub fn_go
 if fn_res <> FN_OK then goto failed

 rem MOUNT_IMAGE: device slot and mode. The cartridge allows it 60
 rem seconds; wait a little longer than that.
 fn_dev = FN_FUJI : fn_cmd = $F8 : fn_npr = 2
 gosub fn_beg
 fn_val = DEVSL : gosub fn_pb
 fn_val = FMREAD : gosub fn_pb
 fn_tmo = 16
 gosub fn_go
 if fn_res <> FN_OK then goto failed

 rem the push may finish before or after MOUNT_IMAGE answers; a cell of
 rem the bar for every 4 per cent
 shown = 0
push
 ix = FN_BOOTPCT / 4
push_bar
 if shown >= ix then goto push_state
 bar[shown] = 35
 shown = shown + 1
 goto push_bar
push_state
 if FN_BOOTSTATE = FN_BOOT_READY then goto go
 if FN_BOOTSTATE = FN_BOOT_FAILED then fn_res = FN_BOOTERR : goto failed
 drawscreen
 goto push

go
 FN_BOOTLOCK = $B5
 asm
   sei
   lda #$7F
   sta CTRL
   jmp $0600
end

failed
 fn_val = fn_res
 gosub fn_hex
 plotchars 'FAILED: E' 0 8 22
 plotchars fn_hexbuf 0 44 22 2

main
 drawscreen
 goto main

 alphadata path fujifont
 '/a7800book/hello.bin'
end

 incbasic fujilib.bas
