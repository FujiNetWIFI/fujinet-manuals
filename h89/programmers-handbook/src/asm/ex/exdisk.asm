;-----------------------------------------------------------------------------
; EXDISK -- the exerciser for the disk drives (31H-38H). Mounts the SD
; card's /test/disk.img (sector n holds 512 bytes of n) in drive slot 0
; through the Fuji device, then sends the drive every command it knows,
; and some it refuses, and unmounts the image again.
;
; The book's disk cards are cut from this file: see tools/EXERCISERS.md.
;
; Copyright (C) 2026 Thomas Cherryhomes
; SPDX-License-Identifier: GPL-3.0-or-later
;-----------------------------------------------------------------------------
INCLUDE "os.inc"
INCLUDE "fujinet.inc"

main:
        call    card_on

; ---- the image in drive slot 0 (drive 31H) ---------------------------
        call    ex_m
        defm    "disk.setup.mount_host", 0
;@ex disk.setup.mount_host
        ld      hl,rq_mhost             ; host slot 0: the SD card
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "disk.setup.set_path", 0
;@ex disk.setup.set_path
        ld      hl,rq_path              ; which file drive slot 0 holds
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "disk.setup.mount", 0
;@ex disk.setup.mount
        ld      hl,rq_mount             ; open it: drive 31H has a disk
        call    fn_call
;@end
        call    ex_show

; ---- reading and writing ---------------------------------------------
        call    ex_m
        defm    "disk.read", 0
;@ex disk.read
        ld      hl,rq_read              ; read sector 3
        call    fn_call
        jr      nz,rd_x
        ld      hl,sector               ; the test image's sector n is
        ld      bc,512                  ;   512 bytes of n: check it
        ld      a,3
rd_1:
        cpi                             ; A = (HL)? HL+1, BC-1
        jr      nz,rd_x
        jp      pe,rd_1                 ; on to the end of the sector
        ld      hl,t_all3
        call    print
rd_x:
;@end
        call    ex_show

        call    ex_m
        defm    "disk.write", 0
;@ex disk.write
        ld      hl,sector               ; fill a sector with E5H, the
        ld      de,sector+1             ;   byte CP/M formats with
        ld      bc,511
        ld      (hl),0xE5
        ldir
        ld      hl,rq_write             ; and write it to sector 5
        call    fn_call
;@end
        call    ex_show

        ld      hl,sector               ; clear the buffer, so the read
        ld      de,sector+1             ;   back proves something
        ld      bc,511
        ld      (hl),0
        ldir
        call    ex_m
        defm    "disk.read.back", 0
;@ex disk.read.back
        ld      hl,rq_back              ; read sector 5 back: E5H again
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "disk.put", 0
;@ex disk.put
        ld      hl,rq_put               ; PUT writes as WRITE does: the
        call    fn_call                 ;   verify it skips, nobody does
;@end
        call    ex_show

        call    ex_m
        defm    "disk.write.past_end", 0
;@ex disk.write.past_end
        ld      hl,rq_wend              ; sector 16 of 16 (0-15): NAK,
        call    fn_call                 ;   and the file is left alone
;@end
        call    ex_show

        call    ex_m
        defm    "disk.read.past_end", 0
;@ex disk.read.past_end
        ld      hl,rq_rend              ; read past the end: NAK
        call    fn_call
;@end
        call    ex_show

; ---- status, format, PERCOM ------------------------------------------
        call    ex_m
        defm    "disk.status", 0
;@ex disk.status
        ld      hl,rq_dstat             ; drive, controller, format
        call    fn_call                 ;   timeout, and a 0
        jr      nz,ds_x
        call    crlf
        ld      hl,dstat
        ld      bc,4
        call    phexs
ds_x:
;@end
        call    ex_show

        call    ex_m
        defm    "disk.format", 0
;@ex disk.format
        ld      hl,rq_fmt               ; FORMAT formats nothing: it
        call    fn_call                 ;   ACKs, FF FF and 126 0s
;@end
        call    ex_show

        call    ex_m
        defm    "disk.read.after_format", 0
;@ex disk.read.after_format
        ld      hl,rq_read              ; sector 3 again: 03H as before
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "disk.format_medium", 0
;@ex disk.format_medium
        ld      hl,rq_fmtm              ; the same as FORMAT
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "disk.percom_read", 0
;@ex disk.percom_read
        ld      hl,rq_pcr               ; the geometry, 12 bytes: all
        call    fn_call                 ;   0 for a plain image
;@end
        call    ex_show

        call    ex_m
        defm    "disk.percom_write", 0
;@ex disk.percom_write
        ld      hl,rq_pcw               ; set it: the firmware keeps the
        call    fn_call                 ;   block, not the image
;@end
        call    ex_show

        call    ex_m
        defm    "disk.percom_read.back", 0
;@ex disk.percom_read.back
        ld      hl,rq_pcr               ; read it back
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "disk.status.percom", 0
;@ex disk.status.percom
        ld      hl,rq_dstat             ; two sides in the PERCOM block:
        call    fn_call                 ;   the status says 40H now
        jr      nz,dp_x
        call    crlf
        ld      hl,dstat
        ld      bc,4
        call    phexs
dp_x:
;@end
        call    ex_show

; ---- an empty drive, and the end -------------------------------------
        call    ex_m
        defm    "disk.read.empty", 0
;@ex disk.read.empty
        ld      hl,rq_rnone             ; drive 32H has no disk: NAK
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "disk.setup.unmount", 0
;@ex disk.setup.unmount
        ld      hl,rq_umount            ; take the image out of slot 0
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "disk.read.unmounted", 0
;@ex disk.read.unmounted
        ld      hl,rq_read              ; drive 31H is empty now: NAK
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "disk.status.unmounted", 0
;@ex disk.status.unmounted
        ld      hl,rq_dstat             ; but STATUS still answers, from
        call    fn_call                 ;   the disk that was there
;@end
        call    ex_show

        jp      ex_done

; ---- requests --------------------------------------------------------
;@ex disk.setup.mount_host
rq_mhost:
        FNREQ   DEV_FUJINET, FUJI_MOUNT_HOST, F_A1, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex disk.setup.set_path
rq_path:                                ; drive slot 0, host 0, mode 2:
        FNREQ   DEV_FUJINET,FUJI_SET_DEVICE_FULLPATH,F_A1_A2_A3, 0,0,2,0
        FNBUF   p_path, p_pathe-p_path, 0, 0    ;   read and write
p_path: defm    "/test/disk.img"
p_pathe:
;@end
;@ex disk.setup.mount
rq_mount:                               ; drive slot 0, mode 2
        FNREQ   DEV_FUJINET, FUJI_MOUNT_IMAGE, F_A1_A2, 0,2,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex disk.read
rq_read:                                ; sector 3, counted from 0
        FNREQ   DEV_DISK, DISK_READ, F_C1234, 3,0,0,0
        FNBUF   0, 0, sector, 512
t_all3: defb    13, 10
        defm    "Sector 3 is 512 bytes of 03H."
        defb    0
;@end
;@ex disk.write
rq_write:                               ; sector 5, 512 bytes
        FNREQ   DEV_DISK, DISK_WRITE, F_C1234, 5,0,0,0
        FNBUF   sector, 512, 0, 0
;@end
;@ex disk.read.back
rq_back:
        FNREQ   DEV_DISK, DISK_READ, F_C1234, 5,0,0,0
        FNBUF   0, 0, sector, 512
;@end
;@ex disk.put
rq_put:                                 ; the same sector to sector 6
        FNREQ   DEV_DISK, DISK_PUT, F_C1234, 6,0,0,0
        FNBUF   sector, 512, 0, 0
;@end
;@ex disk.write.past_end
rq_wend:
        FNREQ   DEV_DISK, DISK_WRITE, F_C1234, 16,0,0,0
        FNBUF   sector, 512, 0, 0
;@end
;@ex disk.read.past_end
rq_rend:
        FNREQ   DEV_DISK, DISK_READ, F_C1234, 16,0,0,0
        FNBUF   0, 0, sector, 512
;@end
;@ex disk.status
rq_dstat:
        FNREQ   DEV_DISK, DISK_STATUS, F_NONE, 0,0,0,0
        FNBUF   0, 0, dstat, 4
;@end
;@ex disk.format
rq_fmt:
        FNREQ   DEV_DISK, DISK_FORMAT, F_NONE, 0,0,0,0
        FNBUF   0, 0, sector, 512
;@end
;@ex disk.format_medium
rq_fmtm:
        FNREQ   DEV_DISK, DISK_FORMAT_MEDIUM, F_NONE, 0,0,0,0
        FNBUF   0, 0, sector, 512
;@end
;@ex disk.percom_read
rq_pcr:
        FNREQ   DEV_DISK, DISK_PERCOM_READ, F_NONE, 0,0,0,0
        FNBUF   0, 0, percom, 12
;@end
;@ex disk.percom_write
rq_pcw:
        FNREQ   DEV_DISK, DISK_PERCOM_WRITE, F_NONE, 0,0,0,0
        FNBUF   p_percom, 12, 0, 0
p_percom:                               ; 80 tracks, step rate 1, 9
        defb    80, 1, 0, 9             ;   sectors a track (high byte
        defb    1, 4, 2, 0              ;   first), two sides, MFM, 512
        defb    0xFF, 0, 0, 0           ;   bytes a sector, present
;@end
;@ex disk.read.empty
rq_rnone:                               ; drive slot 1: drive 32H
        FNREQ   DEV_DISK+1, DISK_READ, F_C1234, 0,0,0,0
        FNBUF   0, 0, sector, 512
;@end
;@ex disk.setup.unmount
rq_umount:                              ; drive slot 0
        FNREQ   DEV_FUJINET, FUJI_UNMOUNT_IMAGE, F_A1, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end

dstat:          defs    4               ; STATUS's reply
percom:         defs    12              ; PERCOM READ's reply
sector:         defs    512             ; one sector

INCLUDE "mark.inc"
INCLUDE "card.inc"
INCLUDE "fujibus.inc"
INCLUDE "con.inc"
INCLUDE "tail.inc"
