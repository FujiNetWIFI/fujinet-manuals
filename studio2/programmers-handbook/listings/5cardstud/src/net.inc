; net.inc -- the N: device round trip, and the name appkey.
;
; A 1802 transcription of the Arcadia and Channel F sequence (which is the
; Astrocade's, which is the Odyssey 2's). The rules it carries forward, each
; learned the hard way on an earlier console:
;
;  * The CLOSE belongs at the START of the next request, never after the
;    READ: every transaction repaints the reply window, a CLOSE reply is
;    empty, and the screens render straight out of the window between polls.
;  * The reply length belongs to the latest transaction, so it is taken
;    immediately after the READ.
;  * The adapter reports STATUS as soon as SOME of the response is in: poll
;    until two readings agree AND at least a known minimum has arrived
;    (Channel F's sixth clause), bounded, rather than guessing a delay.
;  * STATUS byte 3 is nDevStatus_t and checking it is not optional: the GET
;    is deferred until the first STATUS, and an HTTP error page still has a
;    readable body.
;  * Validate the reply length against what playerCount implies before
;    believing a byte of it.
;
; Routines return D = 0 on success, nonzero on failure, and may clobber R8,
; R9, RB, RC and RA.0.

; nbeg -- begin an N1: transaction: R9.0 = command, D = parameter count.
; The timeout outlasts the cart's own 90 s, so the cart always answers.
nbeg:   PHI     R8
        LDI     NDEV
        PHI     R9
        GHI     R8
        FCALL   fn_beg
        SETV    V_TMO, NETTMO
        FRET

; ngo -- fujilib's fn_go and fn_ack in one, scanning the keypads while it
; waits. D = 0 on an ACK; FNEWAIT, FNENAK or the cart's FN_ERR otherwise.
; The sequence number is the cart's ACKSEQ + 1, never a counter in RAM.
        FIT     96
ngo:    PEEK    FN_ACKSEQ
        ADI     1
        BNZ     ngo1
        LDI     1                       ; 0 is "never used"
ngo1:   PUTV    V_SEQ
        LDI     FN_REG_SEQ
        PLO     R8
        GETV    V_SEQ
        FCALL   fn_rw                   ; this pair launches it
        GETV    V_TMO
        FCALL   fn_frames
ngo2:   PEEK    FN_ACKSEQ               ; published last, after the reply
        STR     R2
        GETV    V_SEQ
        XOR
        BZ      ngo3
        FCALL   kpoll
        FCALL   fn_tick
        BDF     ngo2
        LDI     FNEWAIT
        FRET
ngo3:   PEEK    FN_ERR
        BNZ     ngo9
        PEEK    FN_REPLYCMD
        XRI     06H
        BZ      ngo9
        LDI     FNENAK
ngo9:   FRET

; nclose -- close the previous request. The first one has nothing to close
; and earns a NAK; either way is fine.
nclose: LDI     NCCLOSE
        PLO     R9
        LDI     0
        FCALL   nbeg
        FCALL   ngo
        LDI     0
        FRET

; nopen -- OPEN the request V_REQ names as an HTTP GET, no translation.
nopen:  LDI     NCOPEN
        PLO     R9
        LDI     2
        FCALL   nbeg
        LDI     NMHTTPG
        FCALL   fn_pb
        LDI     NTRNONE
        FCALL   fn_pb
        FCALL   bldurl                  ; the devicespec is the payload
        FJMP    ngo

; nstatus -- one STATUS: V_AVL = bytes waiting.
        FIT     48
nstatus:
        LDI     NCSTAT
        PLO     R9
        LDI     0
        FCALL   nbeg
        FCALL   ngo
        BNZ     nst9
        PEEK    FN_REPLY+NSDEVST
        XRI     1
        BNZ     nst9                    ; anything but SUCCESS
        VAR     V_AVL
        PEEK    FN_REPLY
        STR     RA
        INC     RA
        PEEK    FN_REPLY+1
        STR     RA
        LDI     0
nst9:   FRET

; nsettle -- STATUS until V_AVL >= V_MIN and two readings agree, bounded.
        FIT     112
nsettle:
        SETV    V_TRY, 60
        VAR     V_PRV
        LDI     0
        STR     RA
        INC     RA
        STR     RA
nse1:   FCALL   nstatus
        BNZ     nse9
        LDI     HI(V_AVL)
        PHI     RB
        LDI     LO(V_AVL)
        PLO     RB
        VAR     V_MIN                   ; enough yet? avail - min, unsigned
        SEX     RA
        LDA     RB
        SM
        INC     RA
        LDN     RB
        SMB
        SEX     R2
        BNF     nse2
        DEC     RB                      ; and the same as the reading before?
        VAR     V_PRV
        SEX     RA
        LDA     RB
        XOR
        BNZ     nse2x
        INC     RA
        LDN     RB
        XOR
nse2x:  SEX     R2
        BZ      nse9                    ; D = 0: settled
nse2:   VAR     V_AVL                   ; remember this reading
        LDA     RA
        PLO     R8
        LDN     RA
        PHI     R8
        VAR     V_PRV
        GLO     R8
        STR     RA
        INC     RA
        GHI     R8
        STR     RA
        LDI     6                       ; 100 ms, not a handful of cycles
        FCALL   wframes
        VAR     V_TRY
        LDN     RA
        SMI     1
        STR     RA
        BNZ     nse1
        LDI     FE_STAT
nse9:   FRET

; nread -- READ min(V_AVL, V_CAP), then take the reply length.
        FIT     80
nread:  LDI     NCREAD
        PLO     R9
        LDI     1
        FCALL   nbeg
        LDI     HI(V_AVL)
        PHI     RB
        LDI     LO(V_AVL)
        PLO     RB
        VAR     V_CAP                   ; avail - cap: borrow means avail
        SEX     RA
        LDA     RB
        SM
        INC     RA
        LDN     RB
        SMB
        SEX     R2
        BNF     nrd1
        VAR     V_CAP
        LDA     RA
        PLO     R8
        LDN     RA
        PHI     R8
        BR      nrd2
nrd1:   DEC     RB
        LDA     RB
        PLO     R8
        LDN     RB
        PHI     R8
nrd2:   FCALL   fn_pw
        FCALL   ngo
        BNZ     nrd9
        VAR     V_RXL                   ; now: the next transaction replaces it
        PEEK    FN_RXLEN
        STR     RA
        INC     RA
        PEEK    FN_RXLEN+1
        STR     RA
        LDI     0
nrd9:   FRET

; nfetch -- the whole cycle for V_REQ: close the last request, open this
; one, let STATUS settle on V_MIN, read up to V_CAP. D = 0 or an FE_ code.
        FIT     40
nfetch: FCALL   nclose
        FCALL   nopen
        BNZ     nfo
        FCALL   nsettle
        BNZ     nfs
        FCALL   nread
        BNZ     nfr
        FRET
nfo:    LDI     FE_OPEN
        FRET
nfs:    LDI     FE_STAT
        FRET
nfr:    LDI     FE_READ
        FRET

; nleave -- tell the server we left V_TABLE. /leave?bin=1 answers no body
; at all, so this is OPEN and the one STATUS that runs the GET; no READ.
nleave: SETV    V_REQ, REQ_LEAVE
        FCALL   nclose
        FCALL   nopen
        FCALL   nstatus
        FCALL   nclose
        SETV    V_SEAT, 0
        FRET

; setlim -- V_MIN = R8, V_CAP = R9.
setlim: VAR     V_MIN
        GLO     R8
        STR     RA
        INC     RA
        GHI     R8
        STR     RA
        VAR     V_CAP
        GLO     R9
        STR     RA
        INC     RA
        GHI     R9
        STR     RA
        FRET

; vlen -- D = 0 if V_RXL == R8 + R9.0 * D (the count a header promised).
        FIT     40
vlen:   PLO     RC
vl1:    GLO     RC
        BZ      vl2
        GLO     R8
        STR     R2
        GLO     R9
        ADD
        PLO     R8
        GHI     R8
        ADCI    0
        PHI     R8
        DEC     RC
        BR      vl1
vl2:    VAR     V_RXL
        SEX     RA
        GLO     R8
        XOR
        BNZ     vl3
        INC     RA
        GHI     R8
        XOR
vl3:    SEX     R2
        FRET

; ---- the name appkey ----

; akopen -- OPEN_APPKEY for the shared username, mode D (AKREAD/AKWRITE).
; The payload is fujiDevice.h's packed struct appkey, all SIX bytes:
; creator (LE), app, key, mode, reserved. Five leaves the firmware waiting
; for a byte that never comes (the Odyssey 2 port's note).
akopen: PLO     RC
        LDI     FNDEVF
        PHI     R9
        LDI     FNCAKOP
        PLO     R9
        LDI     0
        FCALL   fn_beg
        LDI     1                       ; creator 1 (LE)
        FCALL   fn_txb
        LDI     0
        FCALL   fn_txb
        LDI     1                       ; app 1
        FCALL   fn_txb
        LDI     0                       ; key 0: the username
        FCALL   fn_txb
        GLO     RC
        FCALL   fn_txb
        LDI     0
        FCALL   fn_txb
        FJMP    ngo

; akread -- READ_APPKEY: the window holds u16 length, then the value.
akread: LDI     FNDEVF
        PHI     R9
        LDI     FNCAKRD
        PLO     R9
        LDI     0
        FCALL   fn_beg
        FJMP    ngo

; akwrite -- WRITE_APPKEY with V_NAME (its characters, no NUL).
akwrite:
        LDI     FNDEVF
        PHI     R9
        LDI     FNCAKWR
        PLO     R9
        LDI     0
        FCALL   fn_beg
        LDR     R8, V_NAME
        FCALL   txs
        FJMP    ngo
