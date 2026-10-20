 rem dir.bas -- list a directory on a FujiNet host.
 rem MOUNT_HOST, OPEN_DIRECTORY with the path, READ_DIR_ENTRY until the
 rem $7F,$7F marker (or eight names), CLOSE_DIRECTORY. The names go into
 rem a 32 x 8 map in console RAM.
 incbasic fujinet.bas

 displaymode 320A
 set zoneheight 8
 incgraphic fujifont.png 320A
 characterset fujifont
 alphachars ASCII
 BACKGRND = $00
 P0C2 = $0F

 const HOSTSL = 0
 const NAMELN = 30
 const NAMELAST = 29
 dim names = $2200
 dim pos = var0
 dim ix = var1

 for ix = 0 to 255 : names[ix] = 32 : next
 clearscreen
 plotchars 'DIRECTORY OF SD:/A7800BOOK/' 0 8 2
 plotmap names 0 8 4 32 8
 gosub fn_chk
 if fn_res <> FN_OK then goto failed

 rem MOUNT_HOST: one parameter, the host slot
 fn_dev = FN_FUJI : fn_cmd = $F9 : fn_npr = 1
 gosub fn_beg
 fn_val = HOSTSL : gosub fn_pb
 gosub fn_go
 if fn_res <> FN_OK then goto failed

 rem OPEN_DIRECTORY: the host slot, then exactly 256 bytes of path
 fn_dev = FN_FUJI : fn_cmd = $F7 : fn_npr = 1
 gosub fn_beg
 fn_val = HOSTSL : gosub fn_pb
 fn_i = 0
open_path
 FN_TX = path[fn_i]
 fn_i = fn_i + 1
 if fn_i < path_length then goto open_path
 gosub fn_pad
 gosub fn_go
 if fn_res <> FN_OK then goto failed

 rem READ_DIR_ENTRY: the longest name wanted, and the flags
 pos = 0
entry
 fn_dev = FN_FUJI : fn_cmd = $F6 : fn_npr = 2
 gosub fn_beg
 fn_val = NAMELN : gosub fn_pb
 fn_val = 0 : gosub fn_pb
 gosub fn_go
 if fn_res <> FN_OK then goto failed
 if FN_REPLY[0] <> $7F then goto entry_show
 if FN_REPLY[1] = $7F then goto close
entry_show
 for ix = 0 to NAMELAST
   if FN_REPLY[ix] = 0 then goto entry_next
   names[pos] = FN_REPLY[ix]
   pos = pos + 1
 next
entry_next
 pos = pos & $E0
 pos = pos + 32
 if pos <> 0 then goto entry

 rem CLOSE_DIRECTORY: no parameters
close
 fn_dev = FN_FUJI : fn_cmd = $F5 : fn_npr = 0
 gosub fn_beg
 gosub fn_go
 goto main

failed
 fn_val = fn_res
 gosub fn_hex
 plotchars 'FAILED: E' 0 8 22
 plotchars fn_hexbuf 0 44 22 2

main
 drawscreen
 goto main

 alphadata path fujifont
 '/a7800book/'
end

 incbasic fujilib.bas
