 rem boot.bas -- mount a cartridge image over the network and boot it.
 rem MOUNT_HOST, SET_DEVICE_FULLPATH, MOUNT_IMAGE -- and while that last
 rem reply is outstanding the adapter streams the image to the cartridge,
 rem which stages it and reports BOOT_STATE. Then the swap: arm it, copy the
 rem stub into zero page and jump to it, because the swap replaces every byte
 rem of the window including this program.
 include fujinet.h
 include fujibas.h
 include devdefs.h
 include fujitext.asm
 set romsize 2k
 const FT_ROW0 = 18
 const FT_ROWS = 3
 const pfrowheight = 6
 dim fnseq = a
 dim err = b
 dim dev = c
 dim cmd = d
 dim npar = e
 dim gen = f
 dim tries = g
 dim state = h
 data title
 "FUJIBOOT"
end
 data path
 "/hello.bin"
end
 data msg1
 "MOUNTING"
end
 data msg2
 "FAILED"
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
 for l = 0 to 7
 FNH_TCHR = title[l]
 next
 gosub fnend
 FNH_TROW = 19
 for l = 0 to 7
 FNH_TCHR = msg1[l]
 next
 gosub fnend
 rem MOUNT_HOST(0)
 dev = FNDEVF
 cmd = FNCMHST
 npar = 1
 gosub fnbeg
 FNTX = 1
 FNTX = 0
 gosub fngo
 if err <> 0 then goto fail
 rem SET_DEVICE_FULLPATH(device 0, host 0, read, path): three parameters,
 rem then the path as EXACTLY 256 bytes -- built in cartridge path buffer 1
 rem and emitted, NUL-padded, by the cartridge
 FNH_PATHO = FP_SEL1
 FNH_PATHO = FP_RST
 for l = 0 to 9
 FNH_PATHC = path[l]
 next
 dev = FNDEVF
 cmd = FNCSDFP
 npar = 3
 gosub fnbeg
 FNTX = 1
 FNTX = 0
 FNTX = 1
 FNTX = 0
 FNTX = 1
 FNTX = FMREAD
 FNH_PATHO = FP_TX
 gosub fngo
 if err <> 0 then goto fail
 rem MOUNT_IMAGE(device 0, read): the one that takes real time
 dev = FNDEVF
 cmd = FNCMIMG
 npar = 2
 gosub fnbeg
 FNTX = 1
 FNTX = 0
 FNTX = 1
 FNTX = FMREAD
 gosub fngo
 if err <> 0 then goto fail
 rem wait for the staged image
 tries = 0
staged
 drawscreen
 state = FNBST
 if state = FNBRDY then goto swap
 if state = FNBFAIL then goto fail
 tries = tries + 1
 if tries <> 0 then goto staged
 goto fail
swap
 asm
        lda     #FNBLKM         ; arm the swap: BOOTLOCK = the magic
        sta     FNRSEL+FR_BLCK
        sta     FNCMT
        ldx     #bootstubend-bootstub-1
bootcopy
        lda     bootstub,x      ; the stub must run from RAM
        sta     $80,x
        dex
        bpl     bootcopy
        jmp     $0080
bootstub
        lda     #0
        sta     GRP0            ; silence the sprites
        sta     GRP1
        sta     AUDV0           ; and the sound, or a tone screams
        sta     AUDV1
        sta     PF0
        sta     PF1
        sta     PF2
        sta     WSYNC
        sta     SWACNT          ; RIOT ports back to inputs, or the next
        sta     SWBCNT          ;   game cannot read its joystick
        lda     #2
        sta     VBLANK          ; blank across the swap
        sta     VSYNC
        sta     FNRSEL+FH_SWAP  ; THE SWAP: the window flips before the
        ldx     #$FF            ;   next fetch, which is here, in RAM
        txs
        jmp     ($1FFC)         ; the new image's own reset vector
bootstubend
end
fail
 FNH_TROW = 20
 for l = 0 to 5
 FNH_TCHR = msg2[l]
 next
 gosub fnend
 COLUBK = $34
failed
 drawscreen
 goto failed
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
