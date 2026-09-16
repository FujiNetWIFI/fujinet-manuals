 rem clock.bas -- the time of day, from the adapter's clock (device $45).
 rem GET_ISO_LOCAL answers "2026-09-15T20:45:31" and a NUL; the date goes on
 rem one row and the time on the next, straight out of the reply window.
 include fujinet.h
 include fujibas.h
 include devdefs.h
 include fujitext.asm
 set romsize 2k
 const FT_ROW0 = 15
 const FT_ROWS = 6
 const pfrowheight = 6
 dim fnseq = a
 dim err = b
 dim dev = c
 dim cmd = d
 dim npar = e
 dim gen = f
 dim tries = g
 dim src = h
 dim row = j
 data tlocal
 "LOCAL"
end
 data tutc
 "UTC"
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
 FNH_TROW = 15
 for l = 0 to 4
 FNH_TCHR = tlocal[l]
 next
 gosub fnend
 cmd = CKISOL
 row = 16
 gosub showtime
 if err <> 0 then goto fail
 FNH_TROW = 18
 for l = 0 to 2
 FNH_TCHR = tutc[l]
 next
 gosub fnend
 cmd = CKISOU
 row = 19
 gosub showtime
 if err <> 0 then goto fail
main
 drawscreen
 goto main
fail
 COLUBK = $34
 goto main
 rem showtime: ask the clock (cmd), then the date on row, the time on row+1
showtime
 dev = CLKDEV
 npar = 0
 gosub fnbeg
 gosub fngo
 if err <> 0 then return
 FNH_TROW = row
 for src = 0 to 9
 FNH_TCHR = FNRPLY[src]
 next
 gosub fnend
 row = row + 1
 FNH_TROW = row
 for src = 11 to 18
 FNH_TCHR = FNRPLY[src]
 next
 gosub fnend
 return
fnbeg
 FNA_DEV = 0
 FNCMT = dev
 FNA_CMD = 0
 FNCMT = cmd
 FNA_NPAR = 0
 FNCMT = npar
 FNA_DRST = 0
 FNCMT = 0
 return
fngo
 fnseq = FNACKS + 1
 if fnseq = 0 then fnseq = 1
 FNA_SEQ = 0
 FNCMT = fnseq
 tries = 0
fngowait
 drawscreen
 if FNACKS = fnseq then goto fngodone
 tries = tries + 1
 if tries <> 0 then goto fngowait
 err = 255
 return
fngodone
 err = FNERR
 if err <> 0 then return
 if FNRCMD <> 6 then err = 255
 return
fnend
 gen = FNBTXG
 FNH_TEND = 0
 for l = 0 to 100
 if FNBTXG <> gen then return
 next
 return
