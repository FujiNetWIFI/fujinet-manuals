 rem text.bas -- spike S3: the transaction, and the reply on screen through
 rem the cartridge's text planes and the fujitext minikernel.
 include fujinet.h
 include fujibas.h
 include devdefs.h
 include fujitext.asm
 set romsize 2k
 const FT_ROW0 = 18
 const FT_ROWS = 3
 dim fnseq = a
 dim ch = b
 dim src = c
 dim gen = d
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
 FNA_DEV = 0
 FNCMT = FNDEVF
 FNA_CMD = 0
 FNCMT = FNCADPX
 FNA_NPAR = 0
 FNCMT = 0
 FNA_DRST = 0
 FNCMT = 0
 fnseq = FNACKS + 1
 if fnseq = 0 then fnseq = 1
 FNA_SEQ = 0
 FNCMT = fnseq
wait
 drawscreen
 if FNACKS <> fnseq then goto wait
 if FNERR <> 0 then COLUBK = $34 : goto main
 rem the reply: SSID at 0, version at 125, IP at 140 -- one row each
 src = 0 : FNH_TROW = 18 : gosub putrow
 src = 140 : FNH_TROW = 19 : gosub putrow
 src = 125 : FNH_TROW = 20 : gosub putrow
main
 drawscreen
 goto main
 rem putrow: stream up to 12 bytes of the reply at src into the row begun by
 rem the caller, stopping at NUL, then render and wait for the render.
putrow
 for i = 0 to 11
 ch = FNRPLY[src]
 if ch = 0 then goto putend
 FNH_TCHR = ch
 src = src + 1
 next
putend
 gen = FNBTXG
 FNH_TEND = 0
 for i = 0 to 100
 if FNBTXG <> gen then goto putok
 next
putok
 return
