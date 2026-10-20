 rem hello.bas -- the smallest FujiNet program in 7800basic: a screen,
 rem some text, and proof the cartridge is there. No transaction yet.
 incbasic fujinet.bas

 displaymode 320A
 set zoneheight 8
 incgraphic fujifont.png 320A
 characterset fujifont
 alphachars ASCII
 BACKGRND = $00
 P0C2 = $0F

 clearscreen
 plotchars 'FUJINET ATARI 7800' 0 8 2
 plotchars 'HELLO, WORLD' 0 8 4
 gosub fn_chk
 if fn_res <> FN_OK then goto nocart
 plotchars 'A FUJINET CARTRIDGE ANSWERS' 0 8 6
 if FN_MODE = 3 then plotchars 'RUNNING AS AN APP' 0 8 7
 goto main
nocart
 plotchars 'NO FUJINET CARTRIDGE' 0 8 6

main
 drawscreen
 goto main

 incbasic fujilib.bas
