; fujinet.inc -- N: device commands and reply offsets.
;
; The N: command values are hand-synchronised with the other Astrocade
; ports (fujinet-battleship/astrocade/fujinet.inc, whose o2/ family carries
; the documentation of WHY each is what it is); the canonical list is
; fujinet-firmware/include/fujiCommandID.h. The mailbox transport itself is
; fujilib.inc.
;
; NCWRITE is new here: every Astrocade client so far has been a one-shot
; HTTP GET, so none of them ever sent one. Its shape is transcribed from
; netcat/intv/fujinet.bas's net_write, the same mailbox family.

; ---- Network device (N:) ----------------------------------------------
NETDEV  EQU     71H             ; N1:
NCOPEN  EQU     4FH             ; 'O'
NCCLOSE EQU     43H             ; 'C'
NCREAD  EQU     52H             ; 'R'
NCSTAT  EQU     53H             ; 'S'
NCWRITE EQU     57H             ; 'W'

NMRDWR  EQU     0CH             ; open mode: read/write (the netcat mode;
                                ; the HTTP adapter reads the same 12 as GET)
NTRNONE EQU     0               ; translation: none -- we terminal ourselves

; NET_STATUS reply: 4 bytes in slice 0.
NSAVLO  EQU     0               ; bytes waiting, low
NSAVHI  EQU     1               ; bytes waiting, high
NSCONN  EQU     2               ; connected flag -- the session loop condition
NSDEVST EQU     3               ; nDevStatus_t: 1 SUCCESS, 136 END_OF_FILE.
                                ; NetworkProtocolTELNET derives from
                                ; NetworkProtocolTCP, whose status_client()
                                ; sets connected = client.connected() and
                                ; error = connected ? error : END_OF_FILE --
                                ; so NSCONN drives the loop and this only
                                ; tells a clean remote hangup from a fault.
NDSOK   EQU     1               ; NDEV_STATUS::SUCCESS
NDSEOF  EQU     136             ; NDEV_STATUS::END_OF_FILE

; ---- Sizes -------------------------------------------------------------
; The cart publishes replies through four 256-byte slices; state.inc's
; RXGETB gives a flat 0-1023 offset space over them.
RXMAX   EQU     1024            ; FUJIMAIL_RX_MAX: the READ clamp
TXMAX   EQU     128             ; our WRITE cap. FN_TX_MAX is 320 and a
                                ; write spends 3 bytes on the length
                                ; parameter, so this is far inside it.
