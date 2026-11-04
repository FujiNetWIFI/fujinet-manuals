; net.inc -- the N: device round trip.
;
; A 2650 transcription of astrocade/net.inc's proven sequence (which is
; o2/net.inc's), over mailbox.inc. The rules it carries forward, learned
; the hard way on the Odyssey 2 and Intellivision:
;
;  * The CLOSE belongs at the START of the next request, never after the
;    READ: every transaction repaints the whole reply window, a CLOSE
;    reply is empty, and every screen renders straight out of the window
;    between polls.
;  * FNRXLL/FNRXLH belong to the most recent transaction, so the reply
;    length is captured immediately after the READ.
;  * The ESP32 reports STATUS as soon as SOME of the response has
;    arrived; poll until two consecutive readings agree (bounded) rather
;    than guessing a delay.
;  * The 4th STATUS reply byte is nDevStatus_t and checking it is not
;    optional: the HTTP GET is deferred until the first STATUS, and an
;    HTTP error page still has a readable body.
;  * Validate the reply length against what playerCount implies before
;    believing a byte of it.
;
; All routines return R0 = 0 on success, nonzero on failure; the load
; sets CC, so callers branch on the return directly. MCOMMIT clobbers
; every register, so loop counters live in page-0 RAM cells reached
; through the pointer words.

; NCLOSE: close the previous request's connection. A first call has
; nothing to close and earns a NAK; both results are ignored.
; Calls one down. Clobbers R0-R3.
NCLOSE: BSTA,UN MSTART
        LODI,R1 FRCMD
        LODI,R2 NCCLOSE
        BSTA,UN MREGWR
        LODI,R1 FRNPARM
        LODI,R2 0
        BSTA,UN MREGWR
        BSTA,UN MCOMMIT
        EORZ    R0
        RETC,UN

; NOPEN: OPEN the devicespec as HTTP GET, no translation.
; Calls two down (BLDURL -> FNTXSTR). Clobbers R0-R3, FSTRP.
NOPEN:  BSTA,UN MSTART
        LODI,R1 FRCMD
        LODI,R2 NCOPEN
        BSTA,UN MREGWR
        LODI,R1 FRNPARM
        LODI,R2 2
        BSTA,UN MREGWR
        LODI,R2 NMHTTPG
        BSTA,UN MPARB
        LODI,R2 NTRNONE
        BSTA,UN MPARB
        BSTA,UN BLDURL
        BSTA,UN MCOMMIT
        BCFR,EQ NOBAD
        LODA,R0 FNREPLY
        COMI,R0 FCACK
        BCFR,EQ NOBAD
        EORZ    R0
        RETC,UN
NOBAD:  LODI,R0 $FF
        RETC,UN

; NSTATUS: one STATUS poll. On success AVAIL = bytes waiting.
; Calls one down. Clobbers R0-R3.
NSTATUS: BSTA,UN MSTART
        LODI,R1 FRCMD
        LODI,R2 NCSTAT
        BSTA,UN MREGWR
        LODI,R1 FRNPARM
        LODI,R2 2
        BSTA,UN MREGWR
        LODI,R2 0
        BSTA,UN MPARB
        LODI,R2 0
        BSTA,UN MPARB
        BSTA,UN MCOMMIT
        BCFR,EQ NSBAD
        LODA,R0 FNREPLY
        COMI,R0 FCACK
        BCFR,EQ NSBAD
        LODA,R0 FNRDATA+NSDEVST
        COMI,R0 1               ; SUCCESS -- anything else is an HTTP error
        BCFR,EQ NSBAD
        LODA,R0 FNRDATA+NSAVLO
        STRA,R0 *PAVA0
        LODA,R0 FNRDATA+NSAVHI
        STRA,R0 *PAVA1
        EORZ    R0
        RETC,UN
NSBAD:  LODI,R0 $FF
        RETC,UN

; NREAD: READ min(AVAIL, GMAXLEN) bytes into the reply window, then
; capture the reply length and re-home the slice cache.
; Calls one down. Clobbers R0-R3.
NREAD:  BSTA,UN MSTART
        LODI,R1 FRCMD
        LODI,R2 NCREAD
        BSTA,UN MREGWR
        LODI,R1 FRNPARM
        LODI,R2 1
        BSTA,UN MREGWR
        LODI,R1 2               ; one 2-byte parameter: the length, LE
        LODA,R0 FNDATA,R1
        LODA,R0 *PAVA1
        COMI,R0 GMAXLEN>>8
        BCTR,GT NRCLMP
        BCFR,EQ NRTAKE          ; hi < clamp hi: take avail
        LODA,R0 *PAVA0
        COMI,R0 GMAXLEN&$FF
        BCTR,GT NRCLMP
NRTAKE: LODA,R1 *PAVA0
        LODA,R0 FNDATA,R1
        LODA,R1 *PAVA1
        LODA,R0 FNDATA,R1
        BCTR,UN NRGO
NRCLMP: LODI,R1 GMAXLEN&$FF
        LODA,R0 FNDATA,R1
        LODI,R1 GMAXLEN>>8
        LODA,R0 FNDATA,R1
NRGO:   BSTA,UN MCOMMIT
        BCFR,EQ NRBAD
        LODA,R0 FNREPLY
        COMI,R0 FCACK
        BCFR,EQ NRBAD
        LODA,R0 FNRXLL          ; capture NOW: the next transaction's
        STRA,R0 *PRXL0          ; reply length would replace it
        LODA,R0 FNRXLH
        STRA,R0 *PRXL1
        EORZ    R0
        STRA,R0 *PCURSL         ; the cart republished slice 0
        RETC,UN
NRBAD:  LODI,R0 $FF
        RETC,UN

; ----------------------------------------------------------------------
; APICALL: R0 = request (0 tables, 1 state, 2 move, 3 leave). One full
; round trip; on success (R0 = 0) the reply is in the window with the
; slice cache homed, and stays valid until the next APICALL.
; Calls three down (NOPEN -> BLDURL -> FNTXSTR). Clobbers R0-R3 and the
; net RAM cells.
APICALL: STRA,R0 *PVURL
        BSTA,UN NCLOSE          ; the PREVIOUS request's connection
        BSTA,UN NOPEN
        BCFA,EQ APRET           ; open failed: report it (already closed)
        EORZ    R0
        STRA,R0 *PPRA0
        STRA,R0 *PPRA1
        LODI,R0 20              ; settle-loop bound
        STRA,R0 *PVTMP
APSET:  BSTA,UN NSTATUS
        BCFA,EQ APFAIL
        LODA,R0 *PAVA0
        BCFR,EQ APNZ
        LODA,R0 *PAVA1
        BCTR,EQ APAGN           ; nothing has arrived at all yet
APNZ:   LODA,R0 *PAVA0
        COMA,R0 *PPRA0
        BCFR,EQ APAGN
        LODA,R0 *PAVA1
        COMA,R0 *PPRA1
        BCTR,EQ APRD            ; two readings agree: it has landed
APAGN:  LODA,R0 *PAVA0
        STRA,R0 *PPRA0
        LODA,R0 *PAVA1
        STRA,R0 *PPRA1
        LODI,R3 3               ; ~3 frames between polls
APDLY:  BSTA,UN WAITVB
        BDRR,R3 APDLY
        LODA,R0 *PVTMP
        SUBI,R0 1
        STRA,R0 *PVTMP
        BCFA,EQ APSET
APFAIL: BSTA,UN NCLOSE          ; failed before the READ: nothing to keep
        LODI,R0 $FF
APRET:  RETC,UN
APRD:   BSTA,UN NREAD
        BCFA,EQ APFAIL
; Validation failure after the READ returns nonzero WITHOUT a close --
; the next APICALL's leading NCLOSE retires the connection, and closing
; here would wipe the window a caller may still be rendering the last
; good reply from. Falls through into VALID8.

; VALID8: sanity-check RXLEN for the request in V_URL. Tables: nonempty.
; Game: exactly 154 + 33*playerCount, playerCount < 9 (table-driven --
; pc*33 overflows 8 bits, the 9-entry DWBE table does not).
VALID8: LODA,R0 *PVURL
        BCFR,EQ VALGM
        LODA,R0 *PRXL0          ; tables: any nonzero length; the count
        BCFR,EQ VALOK           ; byte bounds the walk
        LODA,R0 *PRXL1
        BCFR,EQ VALOK
        BCTR,UN VALBAD
VALGM:  LODA,R0 FNRDATA+GOPLCNT
        COMI,R0 9
        BCFR,LT VALBAD          ; more seats than the server has
        RRL,R0                  ; pc*2: table index
        STRZ    R1
        LODA,R0 EXPTB,R1
        COMA,R0 *PRXL1
        BCFR,EQ VALBAD
        LODA,R0 EXPTB+1,R1
        COMA,R0 *PRXL0
        BCFR,EQ VALBAD
VALOK:  EORZ    R0
        RETC,UN
VALBAD: LODI,R0 $FF
        RETC,UN

EXPTB:  DWBE    GMINLEN+0*PLSTRID
        DWBE    GMINLEN+1*PLSTRID
        DWBE    GMINLEN+2*PLSTRID
        DWBE    GMINLEN+3*PLSTRID
        DWBE    GMINLEN+4*PLSTRID
        DWBE    GMINLEN+5*PLSTRID
        DWBE    GMINLEN+6*PLSTRID
        DWBE    GMINLEN+7*PLSTRID
        DWBE    GMINLEN+8*PLSTRID
