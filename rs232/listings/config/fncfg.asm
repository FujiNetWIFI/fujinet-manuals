;=====================================================================
; FNCFG.ASM -- CONFIG for the RS-232 FujiNet, in Z80 assembler
;
; A Teletype-friendly CONFIG: shows the network, the eight host slots
; and the eight disk slots, then lets the operator
;     H  name a host slot          B  browse a host and mount a disk
;     E  eject a disk slot         W  join a WiFi network
;     L  list everything again     Q  quit
;
; Plain scrolling text, no cursor addressing: it works the same on a
; glass terminal or an ASR-33.  Hardware lives in ALTAIR.INC (88-2SIO:
; terminal on port A, FujiNet on port B); the packet layer is
; FUJIBUS.INC.  Assemble:  z88dk-z80asm -b fncfg.asm
;=====================================================================

        ORG     0100h

FUJI    EQU     70h             ; the Fuji device
ENTLEN  EQU     64              ; directory entry length we ask for
PAGELEN EQU     16              ; entries shown per page

START:  LD      SP,STACK
        CALL    PINIT
        CALL    PRINT
        DEFB    13,10,"FUJINET CONFIG FOR RS-232",13,10,0
MLOOP:  CALL    SHOWALL
MPROMPT:CALL    PRINT
        DEFB    13,10,"H)OST B)ROWSE E)JECT W)IFI L)IST Q)UIT? ",0
        CALL    GETKEY
        PUSH    AF
        CALL    CONOUT
        CALL    CRLF
        POP     AF
        CP      'L'
        JR      Z,MLOOP
        CP      'H'
        JR      Z,MHOST
        CP      'B'
        JR      Z,MBROWSE
        CP      'E'
        JR      Z,MEJECT
        CP      'W'
        JR      Z,MWIFI
        CP      'Q'
        JP      Z,PEXIT
        JR      MPROMPT
MHOST:  CALL    DOHOST
        JR      MLOOP
MBROWSE:CALL    DOBROWSE
        JR      MLOOP
MEJECT: CALL    DOEJECT
        JR      MLOOP
MWIFI:  CALL    DOWIFI
        JR      MLOOP

;=====================================================================
; Talking to the Fuji device
;=====================================================================

; FCMD0 -- Fuji command A with no parameters
FCMD0:  LD      C,A
        LD      A,FUJI
        LD      B,00h           ; descriptor 0: no parameters
        CALL    FBNEW
        JR      FDONE

; FCMD1 -- Fuji command A with one u8 parameter in E
FCMD1:  LD      C,A
        LD      A,FUJI
        LD      B,01h           ; descriptor 1: one u8
        CALL    FBNEW
        LD      A,E
        CALL    FBBYTE
FDONE:  CALL    FBCALL
                                ; fall into CHECK

; CHECK -- report a failed FBCALL.  Carry clear (and HL, BC intact) on
; an ACK; otherwise prints why and returns carry set.
CHECK:  JR      C,CHK1
        RET     Z               ; ACK
        CALL    PRINT
        DEFB    "FUJINET SAID NAK",13,10,0
        SCF
        RET
CHK1:   CALL    PRINT
        DEFB    "NO REPLY FROM FUJINET (ERROR ",0
        LD      A,(FBERR)
        CALL    PRHEX
        CALL    PRINT
        DEFB    ")",13,10,0
        SCF
        RET

;=====================================================================
; SHOWALL -- network, host slots, disk slots
;=====================================================================
SHOWALL:
; GET_ADAPTERCONFIG (E8h) -> 140 bytes: SSID at +0, IP at +97,
; firmware version at +125
        LD      A,0E8h
        CALL    FCMD0
        RET     C
        PUSH    HL
        CALL    PRINT
        DEFB    13,10,"NETWORK  ",0
        LD      B,32
        CALL    PRSTRN          ; the SSID
        CALL    PRINT
        DEFB    "  IP ",0
        POP     HL
        PUSH    HL
        LD      DE,97
        ADD     HL,DE
        CALL    PRIP
        CALL    PRINT
        DEFB    13,10,"FIRMWARE ",0
        POP     HL
        LD      DE,125
        ADD     HL,DE
        LD      B,15
        CALL    PRSTRN
        CALL    CRLF

; READ_HOST_SLOTS (F4h) -> 8 x 32 bytes
        LD      A,0F4h
        CALL    FCMD0
        RET     C
        LD      DE,HOSTS
        LD      BC,256
        LDIR
        CALL    PRINT
        DEFB    13,10,"HOST SLOTS",13,10,0
        LD      HL,HOSTS
        LD      C,1
SHH1:   CALL    SLOTNUM
        PUSH    HL
        LD      A,(HL)
        OR      A
        JR      NZ,SHH2
        CALL    PRINT
        DEFB    "(EMPTY)",0
        JR      SHH3
SHH2:   LD      B,32
        CALL    PRSTRN
SHH3:   CALL    CRLF
        POP     HL
        LD      DE,32
        ADD     HL,DE
        INC     C
        LD      A,C
        CP      9
        JR      NZ,SHH1

; READ_DEVICE_SLOTS (F2h) -> 8 x 38 bytes:
;   +0 host slot (FFh = none), +1 mode, +2 file name (36 bytes)
        LD      A,0F2h
        CALL    FCMD0
        RET     C
        LD      DE,SLOTS
        LD      BC,8*38
        LDIR
        CALL    PRINT
        DEFB    13,10,"DISK SLOTS",13,10,0
        LD      HL,SLOTS
        LD      C,1
SHD1:   CALL    SLOTNUM
        PUSH    HL
        LD      A,(HL)          ; host slot
        CP      0FFh
        JR      Z,SHD2
        INC     HL
        INC     HL
        LD      A,(HL)          ; file name
        DEC     HL
        DEC     HL
        OR      A
        JR      NZ,SHD3
SHD2:   CALL    PRINT
        DEFB    "(EMPTY)",0
        JR      SHD5
SHD3:   INC     HL              ; mode: bit 1 = write
        LD      A,(HL)
        DEC     HL
        AND     02h
        LD      A,'R'
        JR      Z,SHD4
        LD      A,'W'
SHD4:   CALL    CONOUT
        CALL    PRINT
        DEFB    "  HOST ",0
        LD      A,(HL)
        ADD     A,'1'
        CALL    CONOUT
        CALL    PRINT
        DEFB    "  ",0
        INC     HL
        INC     HL
        LD      B,36
        CALL    PRSTRN
SHD5:   CALL    CRLF
        POP     HL
        LD      DE,38
        ADD     HL,DE
        INC     C
        LD      A,C
        CP      9
        JR      NZ,SHD1
        RET

; SLOTNUM -- print " n  " for slot number C
SLOTNUM:CALL    SPACE
        LD      A,C
        ADD     A,'0'
        CALL    CONOUT
        CALL    SPACE
        JP      SPACE

; PRIP -- print the four bytes at (HL) as a dotted IP address
PRIP:   LD      B,4
PRIP1:  PUSH    HL
        LD      L,(HL)
        LD      H,0
        CALL    PRDEC
        POP     HL
        INC     HL
        DEC     B
        RET     Z
        LD      A,'.'
        CALL    CONOUT
        JR      PRIP1

;=====================================================================
; H -- name a host slot, then WRITE_HOST_SLOTS
;=====================================================================
DOHOST: LD      HL,PHOST
        LD      C,8
        CALL    ASKNUM
        RET     C
        LD      (CURH),A
        CALL    PRINT
        DEFB    "HOST NAME (RETURN TO CLEAR)? ",0
        LD      HL,LINE
        LD      B,31
        CALL    GETLN
        LD      A,(CURH)        ; DE = HOSTS + slot x 32
        LD      L,A
        LD      H,0
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        ADD     HL,HL
        LD      DE,HOSTS
        ADD     HL,DE
        EX      DE,HL
        LD      HL,LINE         ; copy the name, zero-filled to 32
        LD      B,32
DH1:    LD      A,(HL)
        LD      (DE),A
        OR      A
        JR      Z,DH2
        INC     HL
DH2:    INC     DE
        DJNZ    DH1
; WRITE_HOST_SLOTS (F3h): all 256 bytes in the payload
        LD      A,FUJI
        LD      C,0F3h
        LD      B,00h
        CALL    FBNEW
        LD      HL,HOSTS
        LD      BC,256
        CALL    FBMEM
        CALL    FBCALL
        JP      CHECK

;=====================================================================
; E -- eject (UNMOUNT_IMAGE) a disk slot
;=====================================================================
DOEJECT:LD      HL,PDRIVE
        LD      C,8
        CALL    ASKNUM
        RET     C
        LD      E,A
        LD      A,0E9h          ; UNMOUNT_IMAGE, p0 = disk slot
        JP      FCMD1

;=====================================================================
; B -- browse a host, pick an image, mount it
;=====================================================================
DOBROWSE:
        LD      HL,PHOST
        LD      C,8
        CALL    ASKNUM
        RET     C
        LD      (CURH),A
        LD      E,A
        LD      A,0F9h          ; MOUNT_HOST, p0 = host slot
        CALL    FCMD1
        RET     C
        LD      HL,PATH         ; start at the root
        LD      (HL),'/'
        INC     HL
        LD      (HL),0

; OPEN_DIRECTORY (F7h): p0 = host slot, payload = path, exactly 256
BROPEN: LD      A,FUJI
        LD      C,0F7h
        LD      B,01h
        CALL    FBNEW
        LD      A,(CURH)
        CALL    FBBYTE
        LD      HL,PATH
        LD      BC,256
        CALL    FBSTR
        CALL    FBCALL
        CALL    CHECK
        RET     C
        XOR     A
        LD      (ATEND),A

BRPAGE: CALL    PRINT
        DEFB    13,10,"HOST ",0
        LD      A,(CURH)
        ADD     A,'1'
        CALL    CONOUT
        CALL    PRINT
        DEFB    ": ",0
        LD      HL,PATH
        CALL    PRSTR
        CALL    CRLF
        XOR     A
        LD      (NENT),A
        LD      DE,PAGE
; READ_DIR_ENTRY (F6h): p0 = length wanted, p1 = flags (0 = name only)
BRNEXT: LD      A,(ATEND)
        OR      A
        JR      NZ,BRASK
        PUSH    DE
        LD      A,FUJI
        LD      C,0F6h
        LD      B,02h           ; descriptor 2: two u8s
        CALL    FBNEW
        LD      A,ENTLEN
        CALL    FBBYTE
        XOR     A
        CALL    FBBYTE
        CALL    FBCALL
        CALL    CHECK
        POP     DE
        JP      C,BRCLOSE
        LD      A,(HL)          ; 7F 7F = end of directory
        CP      7Fh
        JR      NZ,BRN1
        INC     HL
        CP      (HL)
        DEC     HL
        JR      NZ,BRN1
        LD      A,1
        LD      (ATEND),A
        JR      BRASK
BRN1:   PUSH    DE              ; keep the name in the page table
        LD      BC,ENTLEN
        LDIR
        XOR     A
        LD      (DE),A          ; and make sure it ends
        POP     HL              ; HL = the stored name
        LD      DE,ENTLEN+1
        EX      DE,HL
        ADD     HL,DE           ; DE = name, HL = next table slot
        EX      DE,HL
        PUSH    DE
        LD      A,(NENT)
        INC     A
        LD      (NENT),A
        PUSH    HL              ; print " nn  name"
        LD      L,A
        LD      H,0
        LD      B,3
        CALL    PRDECW
        CALL    SPACE
        CALL    SPACE
        POP     HL
        CALL    PRSTR
        CALL    CRLF
        POP     DE
        LD      A,(NENT)
        CP      PAGELEN
        JR      C,BRNEXT

BRASK:  LD      A,(ATEND)
        OR      A
        JR      Z,BRA1
        CALL    PRINT
        DEFB    "(END)",13,10,0
BRA1:   CALL    PRINT
        DEFB    "NUMBER, N)EXT, U)P, X)IT? ",0
        LD      HL,LINE
        LD      B,3
        CALL    GETLN
        LD      A,(LINE)
        CALL    UCASE
        CP      'N'
        JP      Z,BRPAGE
        CP      'U'
        JR      Z,BRUP
        CP      'X'
        JR      Z,BRCLOSE
        OR      A
        JR      Z,BRCLOSE
        LD      A,(NENT)
        LD      C,A
        CALL    PARSE           ; A = choice - 1
        JR      C,BRA1
        LD      L,A             ; HL = PAGE + A x (ENTLEN+1)
        LD      H,0
        LD      DE,ENTLEN+1
        CALL    MUL16
        LD      DE,PAGE
        ADD     HL,DE
        LD      (CHOSEN),HL
        CALL    STREND          ; a directory ends in '/'
        DEC     HL
        LD      A,(HL)
        CP      '/'
        JR      NZ,BRFILE
        LD      HL,PATH         ; descend: PATH = PATH + name
        CALL    STREND
        EX      DE,HL
        LD      HL,(CHOSEN)
        CALL    STRCPY
        JP      BROPEN

BRUP:   LD      HL,PATH         ; climb: drop the last "name/"
        CALL    STREND
        DEC     HL              ; the trailing '/'
BRU1:   LD      DE,PATH
        OR      A
        SBC     HL,DE
        ADD     HL,DE
        JP      Z,BROPEN        ; back at the root "/"
        DEC     HL
        LD      A,(HL)
        CP      '/'
        JR      NZ,BRU1
        INC     HL
        LD      (HL),0
        JP      BROPEN

BRCLOSE:LD      A,0F5h          ; CLOSE_DIRECTORY
        JP      FCMD0

; A file was chosen: close the directory, choose a slot and a mode,
; SET_DEVICE_FULLPATH, then MOUNT_IMAGE.
BRFILE: LD      A,0F5h
        CALL    FCMD0
        LD      HL,PDRIVE
        LD      C,8
        CALL    ASKNUM
        RET     C
        LD      (CURD),A
        CALL    PRINT
        DEFB    "R)EAD-ONLY OR W)RITE? ",0
        CALL    GETKEY
        PUSH    AF
        CALL    CONOUT
        CALL    CRLF
        POP     AF
        LD      B,1             ; mode 1 = read
        CP      'W'
        JR      NZ,BRF1
        LD      B,2             ; mode 2 = read/write
BRF1:   LD      A,B
        LD      (MODE),A
        LD      DE,FULL         ; FULL = PATH + name
        LD      HL,PATH
        CALL    STRCPY
        LD      HL,(CHOSEN)
        CALL    STRCPY
; SET_DEVICE_FULLPATH (E2h): p0 disk slot, p1 host slot, p2 mode,
; payload = the full path, exactly 256 bytes
        LD      A,FUJI
        LD      C,0E2h
        LD      B,03h           ; descriptor 3: three u8s
        CALL    FBNEW
        LD      A,(CURD)
        CALL    FBBYTE
        LD      A,(CURH)
        CALL    FBBYTE
        LD      A,(MODE)
        CALL    FBBYTE
        LD      HL,FULL
        LD      BC,256
        CALL    FBSTR
        CALL    FBCALL
        CALL    CHECK
        RET     C
; MOUNT_IMAGE (F8h): p0 disk slot, p1 mode
        LD      A,FUJI
        LD      C,0F8h
        LD      B,02h
        CALL    FBNEW
        LD      A,(CURD)
        CALL    FBBYTE
        LD      A,(MODE)
        CALL    FBBYTE
        CALL    FBCALL
        CALL    CHECK
        RET     C
        CALL    PRINT
        DEFB    "MOUNTED.",13,10,0
        RET

;=====================================================================
; W -- scan for networks and join one
;=====================================================================
DOWIFI: CALL    PRINT
        DEFB    "SCANNING...",13,10,0
        LD      A,0FDh          ; SCAN_NETWORKS -> 1 byte: count
        CALL    FCMD0
        RET     C
        LD      A,(HL)
        OR      A
        RET     Z
        CP      PAGELEN+1       ; show at most 16
        JR      C,DW1
        LD      A,PAGELEN
DW1:    LD      (NENT),A
        LD      C,0
DW2:    LD      E,C             ; GET_SCAN_RESULT (FCh), p0 = index
        PUSH    BC
        LD      A,0FCh
        CALL    FCMD1           ; -> 33-byte SSID, then signed RSSI
        POP     BC
        RET     C
        PUSH    BC
        PUSH    HL
        LD      L,C
        INC     L
        LD      H,0
        LD      B,3
        CALL    PRDECW
        CALL    SPACE
        CALL    SPACE
        POP     HL
        PUSH    HL
        LD      B,32
        CALL    PRSTRN
        CALL    PRINT
        DEFB    "  ",0
        POP     HL
        LD      DE,33
        ADD     HL,DE
        LD      A,(HL)          ; RSSI in dBm, negative
        OR      A
        JP      P,DW3
        NEG
        PUSH    AF
        LD      A,'-'
        CALL    CONOUT
        POP     AF
DW3:    LD      L,A
        LD      H,0
        CALL    PRDEC
        CALL    PRINT
        DEFB    " DBM",13,10,0
        POP     BC
        INC     C
        LD      A,(NENT)
        CP      C
        JR      NZ,DW2
        LD      HL,PNET
        LD      A,(NENT)
        LD      C,A
        CALL    ASKNUM
        RET     C
        LD      E,A             ; fetch that entry's SSID again
        LD      A,0FCh
        CALL    FCMD1
        RET     C
        LD      DE,SSID
        LD      BC,33
        LDIR
        CALL    PRINT
        DEFB    "PASSWORD? ",0
        LD      HL,PASS
        LD      B,63
        CALL    GETLN
; SET_SSID (FBh): payload = SSID (33) + password (64), exactly 97
        LD      A,FUJI
        LD      C,0FBh
        LD      B,00h
        CALL    FBNEW
        LD      HL,SSID
        LD      BC,33
        CALL    FBSTR
        LD      HL,PASS
        LD      BC,64
        CALL    FBSTR
        LD      A,120           ; joining can take a while: allow 30 s
        LD      (FBWAIT),A
        CALL    FBCALL
        LD      A,40
        LD      (FBWAIT),A
        CALL    CHECK
        RET     C
        CALL    PRINT
        DEFB    "JOINED.",13,10,0
        RET

;=====================================================================
; Small helpers
;=====================================================================

; ASKNUM -- print the prompt at HL, read a number 1..C;
; A = number - 1 with carry clear, or carry set if blank or invalid
ASKNUM: CALL    PRSTR
        PUSH    BC
        LD      HL,LINE
        LD      B,3
        CALL    GETLN
        POP     BC
                                ; fall into PARSE
; PARSE -- the decimal number in LINE, 1..C -> A = number - 1
PARSE:  LD      HL,LINE
        LD      A,(HL)
        OR      A
        SCF
        RET     Z               ; blank
        LD      B,0             ; B = value
PA1:    LD      A,(HL)
        OR      A
        JR      Z,PA2
        SUB     '0'
        RET     C               ; not a digit
        CP      10
        CCF
        RET     C
        LD      D,A             ; B = B x 10 + digit
        LD      A,B
        ADD     A,A
        LD      E,A
        ADD     A,A
        ADD     A,A
        ADD     A,E
        ADD     A,D
        LD      B,A
        INC     HL
        JR      PA1
PA2:    LD      A,B
        OR      A
        SCF
        RET     Z               ; zero is not a choice
        CP      C
        JR      Z,PA3
        CCF
        RET     C               ; bigger than C
PA3:    DEC     A
        OR      A               ; clear carry
        RET

; STREND -- HL = address of the NUL ending the string at HL
STREND: LD      A,(HL)
        OR      A
        RET     Z
        INC     HL
        JR      STREND

; STRCPY -- copy the string at HL to DE, including its NUL; on return
; DE points at the copied NUL (so a second STRCPY appends)
STRCPY: LD      A,(HL)
        LD      (DE),A
        OR      A
        RET     Z
        INC     HL
        INC     DE
        JR      STRCPY

; MUL16 -- HL = HL x DE (low 16 bits)
MUL16:  PUSH    BC
        LD      B,H
        LD      C,L
        LD      HL,0
        LD      A,16
MU1:    ADD     HL,HL
        EX      DE,HL
        ADD     HL,HL
        EX      DE,HL
        JR      NC,MU2
        ADD     HL,BC
MU2:    DEC     A
        JR      NZ,MU1
        POP     BC
        RET

PHOST:  DEFB    "HOST SLOT (1-8)? ",0
PDRIVE: DEFB    "DISK SLOT (1-8)? ",0
PNET:   DEFB    "NETWORK NUMBER? ",0

        INCLUDE "../common/altair.inc"
        INCLUDE "../common/conio.inc"
        INCLUDE "../common/fujibus.inc"

;=====================================================================
; Variables and buffers
;=====================================================================
CURH:   DEFB    0               ; host slot being worked on (0-7)
CURD:   DEFB    0               ; disk slot being worked on (0-7)
MODE:   DEFB    0               ; 1 = read, 2 = read/write
NENT:   DEFB    0               ; entries on this page
ATEND:  DEFB    0               ; directory exhausted
CHOSEN: DEFW    0               ; the chosen entry's name
LINE:   DEFS    32
HOSTS:  DEFS    256             ; 8 x 32: the host slot names
SLOTS:  DEFS    8*38            ; 8 x 38: the disk slots
PATH:   DEFS    256             ; current directory, ends in '/'
FULL:   DEFS    256             ; directory + file name
SSID:   DEFS    33
PASS:   DEFS    64
PAGE:   DEFS    PAGELEN*(ENTLEN+1)
        DEFS    256
STACK:
