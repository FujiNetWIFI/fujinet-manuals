 rem appkey.bas -- read the shared FujiNet username, then write a key of
 rem our own and read it back. An appkey is a small file on the adapter's
 rem SD card named by creator, app and key; creator 1 / app 1 / key 0 is the
 rem slot every FujiNet game reads the player's name from.
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
 dim crlo = h
 dim crhi = j
 dim keyn = k
 dim mode = m
 dim src = n
 dim len = o
 data tname
 "USERNAME"
end
 data tours
 "KEY 2600:1:0"
end
 data tval
 "HELLO 2600"
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
 rem the shared username: creator 1, app 1, key 0
 FNH_TROW = 15
 for l = 0 to 7
 FNH_TCHR = tname[l]
 next
 gosub fnend
 crlo = AKCREAT
 crhi = 0
 keyn = AKKEY
 mode = AKMRD
 gosub akopen
 if err <> 0 then goto fail
 gosub akread
 if err <> 0 then goto fail
 FNH_TROW = 16
 gosub akshow
 rem our own key: creator $2600, app 1, key 0 -- write it, read it back
 FNH_TROW = 18
 for l = 0 to 11
 FNH_TCHR = tours[l]
 next
 gosub fnend
 crlo = $00
 crhi = $26
 keyn = 0
 mode = AKMWR
 gosub akopen
 if err <> 0 then goto fail
 dev = FNDEVF
 cmd = FNCAKWR
 npar = 1
 gosub fnbeg
 FNTX = 1
 FNTX = 10
 for l = 0 to 9
 FNTX = tval[l]
 next
 gosub fngo
 if err <> 0 then goto fail
 mode = AKMRD
 gosub akopen
 if err <> 0 then goto fail
 gosub akread
 if err <> 0 then goto fail
 FNH_TROW = 19
 gosub akshow
main
 drawscreen
 goto main
fail
 COLUBK = $34
 goto main
 rem akopen: OPEN_APPKEY -- the six-byte struct as the payload: creator
 rem (two bytes, low first), app, key, mode, and a reserved byte
akopen
 dev = FNDEVF
 cmd = FNCAKOP
 npar = 0
 gosub fnbeg
 FNTX = crlo
 FNTX = crhi
 FNTX = AKAPP
 FNTX = keyn
 FNTX = mode
 FNTX = 0
 gosub fngo
 return
 rem akread: READ_APPKEY -- the reply is a length word, then the value
akread
 dev = FNDEVF
 cmd = FNCAKRD
 npar = 0
 gosub fnbeg
 gosub fngo
 return
 rem akshow: the value just read into the row begun by the caller
akshow
 len = FNRPLY[0]
 if len > 12 then len = 12
 src = 2
 for l = 1 to len
 FNH_TCHR = FNRPLY[src]
 src = src + 1
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
