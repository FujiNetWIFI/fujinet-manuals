 rem dir.bas -- list a directory of host slot 0, with a cursor.
 rem The working directory lives in the CARTRIDGE (path buffer 0): the
 rem console never holds a path or a filename, only a cursor index. Each
 rem entry is rendered straight from the reply window into a text row, so
 rem moving the cursor re-reads the listing -- instant in emulation, about a
 rem second on real hardware, and CONFIG's page cache is the cure.
 include fujinet.h
 include fujibas.h
 include devdefs.h
 include fujitext.asm
 set romsize 2k
 const FT_ROW0 = 9
 const FT_ROWS = 12
 const pfrowheight = 6
 const noscore = 1
 const ROW0 = 10
 const NROWS = 11
 dim fnseq = a
 dim err = b
 dim dev = c
 dim cmd = d
 dim npar = e
 dim gen = f
 dim ch = g
 dim src = h
 dim sel = j
 dim cnt = k
 dim row = m
 dim tries = n
 dim col = o
 data title
 "FUJINET DIR"
end
 COLUBK = 0
 COLUPF = $1A
 playfield:
 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
end
 FNH_ARM1 = FNAM1
 FNH_ARM2 = FNAM2
 rem the working directory: path buffer 0 holds "/"
 FNH_PATHO = FP_SEL0
 FNH_PATHO = FP_RST
 FNH_PATHC = 47
 rem MOUNT_HOST(0)
 dev = FNDEVF
 cmd = FNCMHST
 npar = 1
 gosub fnbeg
 FNTX = 1
 FNTX = 0
 gosub fngo
 if err <> 0 then goto fail
 FNH_TROW = 9
 for l = 0 to 10
 FNH_TCHR = title[l]
 next
 gosub fnend
 sel = 0
redraw
 gosub draw
 if err <> 0 then goto fail
main
 drawscreen
 if joy0down then goto down
 if joy0up then goto up
 goto main
down
 ch = sel + 1
 if ch = cnt then goto main
 sel = ch
 gosub release
 goto redraw
up
 if sel = 0 then goto main
 sel = sel - 1
 gosub release
 goto redraw
release
 drawscreen
 if joy0down then goto release
 if joy0up then goto release
 return
fail
 COLUBK = $34
 drawscreen
 goto fail
 rem draw: OPEN_DIRECTORY(host 0, the path buffer, no filter) -- one
 rem parameter, then the 256-byte path the cartridge emits and pads --
 rem then READ_DIR_ENTRY(30, 0) once a row until the $7F,$7F end marker.
draw
 dev = FNDEVF
 cmd = FNCODIR
 npar = 1
 gosub fnbeg
 FNTX = 1
 FNTX = 0
 FNH_PATHO = FP_TX
 gosub fngo
 if err <> 0 then return
 cnt = 0
entry
 dev = FNDEVF
 cmd = FNCRDIR
 npar = 2
 gosub fnbeg
 FNTX = 1
 FNTX = 30
 FNTX = 1
 FNTX = 0
 gosub fngo
 if err <> 0 then return
 if FNRPLY[0] <> 127 then goto show
 if FNRPLY[1] = 127 then goto blank
show
 row = cnt + ROW0
 FNH_TROW = row
 ch = 32
 if cnt = sel then ch = 62
 FNH_TCHR = ch
 src = 0
 col = 1
nextch
 ch = FNRPLY[src]
 if ch = 0 then goto rowend
 FNH_TCHR = ch
 src = src + 1
 col = col + 1
 if col < 12 then goto nextch
rowend
 gosub fnend
 cnt = cnt + 1
 if cnt < NROWS then goto entry
blank
 row = cnt + ROW0
blankrow
 if row = 21 then goto drawn
 FNH_TROW = row
 gosub fnend
 row = row + 1
 goto blankrow
drawn
 err = 0
 return
 rem fnbeg: begin a transaction from dev / cmd / npar
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
 rem fngo: launch (SEQ = ACKSEQ + 1), draw frames until the cartridge
 rem answers; err = 0 on ACK, the transport's code, or 255
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
