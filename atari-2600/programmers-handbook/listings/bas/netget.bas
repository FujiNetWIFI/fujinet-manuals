 rem netget.bas -- fetch a URL through the N: device and show the text.
 rem OPEN it as an HTTP GET, STATUS until the byte count settles, READ up to
 rem 240 bytes into the reply window, stream it into text rows a line at a
 rem time, CLOSE. Nothing of the reply ever lands in console RAM.
 include fujinet.h
 include fujibas.h
 include devdefs.h
 include netdefs.h
 include fujitext.asm
 set romsize 2k
 const FT_ROW0 = 16
 const FT_ROWS = 5
 const FT_END = 21
 const pfrowheight = 6
 dim fnseq = a
 dim ch = b
 dim src = c
 dim gen = d
 dim avlo = e
 dim avhi = f
 dim prlo = g
 dim prhi = h
 dim row = j
 dim tries = k
 dim col = m
 dim err = n
 data url
 "N:http://127.0.0.1:8765/hello.txt"
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
 rem OPEN: two one-byte parameters, mode and translation, then the devicespec
 FNA_DEV = 0
 FNCMT = NETDEV
 FNA_CMD = 0
 FNCMT = NCOPEN
 FNA_NPAR = 0
 FNCMT = 2
 FNA_DRST = 0
 FNCMT = 0
 FNTX = 1
 FNTX = NMHTTPG
 FNTX = 1
 FNTX = NTRNONE
 for l = 0 to url_length - 1
 FNTX = url[l]
 next
 gosub fngo
 if err <> 0 then goto fail
 rem STATUS until two readings agree and something is waiting
 prlo = 255
 prhi = 255
 tries = 0
status
 FNA_DEV = 0
 FNCMT = NETDEV
 FNA_CMD = 0
 FNCMT = NCSTAT
 FNA_NPAR = 0
 FNCMT = 2
 FNA_DRST = 0
 FNCMT = 0
 FNTX = 1
 FNTX = 0
 FNTX = 1
 FNTX = 0
 gosub fngo
 if err <> 0 then goto fail
 avlo = FNRPLY[0]
 avhi = FNRPLY[1]
 if avlo <> prlo then goto again
 if avhi <> prhi then goto again
 if avhi <> 0 then goto readit
 if avlo <> 0 then goto readit
again
 prlo = avlo
 prhi = avhi
 tries = tries + 1
 if tries = 30 then goto fail
 drawscreen
 drawscreen
 drawscreen
 goto status
readit
 rem READ: ONE two-byte parameter, the count, capped at 240 (twenty rows)
 if avhi <> 0 then avlo = 240
 if avlo > 240 then avlo = 240
 avhi = 0
 FNA_DEV = 0
 FNCMT = NETDEV
 FNA_CMD = 0
 FNCMT = NCREAD
 FNA_NPAR = 0
 FNCMT = 1
 FNA_DRST = 0
 FNCMT = 0
 FNTX = 2
 FNTX = avlo
 FNTX = avhi
 gosub fngo
 if err <> 0 then goto fail
 rem show it: a text row per line of the reply, a row per frame
 src = 0
 row = FT_ROW0
nextrow
 if row = FT_END then goto shown
 FNH_TROW = row
 col = 0
nextch
 if src = avlo then goto rowend
 ch = FNRPLY[src]
 src = src + 1
 if ch = 10 then goto rowend
 if ch = 13 then goto nextch
 if col = 12 then goto nextch
 FNH_TCHR = ch
 col = col + 1
 goto nextch
rowend
 gosub fnend
 drawscreen
 row = row + 1
 if src < avlo then goto nextrow
shown
 rem CLOSE, and the picture stays: the rows are on the planes now
 FNA_DEV = 0
 FNCMT = NETDEV
 FNA_CMD = 0
 FNCMT = NCCLOSE
 FNA_NPAR = 0
 FNCMT = 0
 FNA_DRST = 0
 FNCMT = 0
 gosub fngo
main
 drawscreen
 goto main
fail
 COLUBK = $34
 goto main
 rem fngo: launch (SEQ = ACKSEQ + 1), draw frames until the cartridge answers,
 rem err = 0 on ACK, else the transport's code or 255 for no answer / NAK
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
