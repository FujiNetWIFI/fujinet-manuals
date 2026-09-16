 rem hello.bas -- HELLO, WORLD: three rows of text, composed by the cartridge
 rem and shown under the playfield by the fujitext minikernel. No network,
 rem no transaction: the text rows are a one-shot operation on the control
 rem page, so all this needs is the gate open and three loops of stores.
 include fujinet.h
 include fujibas.h
 include devdefs.h
 include fujitext.asm
 set romsize 2k
 const FT_ROW0 = 18
 const FT_ROWS = 3
 const pfrowheight = 6
 dim gen = d
 data msg1
 "FUJINET 2600"
end
 data msg2
 "HELLO, WORLD"
end
 data msg3
 "BATARI BASIC"
end
 COLUBK = 0
 COLUPF = $84
 playfield:
 ................................
 ................................
 ....XXXXX.X...X.....X.XXXXX.....
 ....X.....X...X.....X...X.......
 ....XXXX..X...X.....X...X.......
 ....X.....X...X.X...X...X.......
 ....X.....XXXXX..XXX..XXXXX.....
 ................................
end
 FNH_ARM1 = FNAM1
 FNH_ARM2 = FNAM2
 FNH_TROW = 18
 for l = 0 to 11
 FNH_TCHR = msg1[l]
 next
 gosub fnend
 FNH_TROW = 19
 for l = 0 to 11
 FNH_TCHR = msg2[l]
 next
 gosub fnend
 FNH_TROW = 20
 for l = 0 to 11
 FNH_TCHR = msg3[l]
 next
 gosub fnend
main
 drawscreen
 goto main
 rem fnend: render the row, then wait (bounded) for the cartridge to say it
 rem has landed on the planes -- instant in emulation, a few bus cycles later
 rem on the real RP2040, which composes a row on its other core.
fnend
 gen = FNBTXG
 FNH_TEND = 0
 for l = 0 to 100
 if FNBTXG <> gen then return
 next
 return
