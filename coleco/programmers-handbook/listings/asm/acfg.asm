; ============================================================
; acfg.asm -- GET_ADAPTERCONFIG_EXTENDED, in Z80 assembly.
;
; The assembly-language counterpart to the C fujitest: the smallest program
; that runs one whole mailbox transaction and shows what came back. It is a
; hand-written ColecoVision cartridge with its own header, but for the screen
; it does what every client in this book does -- it uses OS7, the console's own
; BIOS, through its jump table at $1Fxx. MODE_1 lays out Graphics I, LOAD_ASCII
; fills the pattern generator with the BIOS font so a name-table byte is simply
; its ASCII code, and PUT_VRAM writes the text. No font of our own, no VDP
; register banging: the mailbox is the only thing this program does the hard
; way, because the mailbox is the only thing OS7 does not already know how to
; do.
;
; It asks the adapter for its extended configuration (device $70, command
; $C4), then prints the SSID, IP address and firmware version straight out of
; the reply window at $F800.
;
; Assemble with build.sh (z88dk-z80asm), which pads the image to 32768 bytes
; and stamps the "FUJI" claim; run it in the grafted MAME against a live
; fujinet-pc.
; ============================================================

; ---- OS7 BIOS entry points (the jump table at the top of the BIOS ROM) ----
MODE_1     equ $1F85            ; set up Graphics I tables
LOAD_ASCII equ $1F7F            ; load the BIOS ASCII font into the generator
FILL_VRAM  equ $1F82            ; HL=addr, DE=count, A=value
PUT_VRAM   equ $1FBE            ; A=table, DE=index, HL=data, IY=count

; PUT_VRAM table codes
VDP_NAME   equ 2                ; the pattern name table (the text screen)

; ---- OS7 RAM variables PUT_VRAM consults; a $55,$AA cart must clear them,
; because the BIOS title screen that normally would is skipped. ----
VDP_STATUS_BYTE equ $73C5
DEFER_WRITES    equ $73C6
MUX_SPRITES     equ $73C7

; ---- low-RAM scratch (the 1K at $6000 mirrors up to $73FF) ----
SPRITES equ $7000               ; header-required RAM pointers; unused here
SPRTORD equ $7080
WORKBUF equ $70A0
CTRLMAP equ $70C0
NPARAM  equ $70E0               ; the mailbox library's two scratch bytes
WANT    equ $70E1

; a name-table index is row*32 + column
COLS    equ 32

        org     $8000

; ============================================================
; Cartridge header. $55,$AA tells the BIOS to skip its title screen and jump
; straight to the address in $800A, so this program owns the machine from its
; first instruction -- and therefore has to set the screen up itself.
; ============================================================
        defb    $55,$AA         ; skip the BIOS title screen
        defw    SPRITES         ; sprite name table (RAM)
        defw    SPRTORD         ; sprite order table
        defw    WORKBUF         ; work buffer
        defw    CTRLMAP         ; controller map
        defw    START           ; entry point ($55,$AA jumps here)
        jp      RSTV            ; rst 08
        jp      RSTV            ; rst 10
        jp      RSTV            ; rst 18
        jp      RSTV            ; rst 20
        jp      RSTV            ; rst 28
        jp      RSTV            ; rst 30
        jp      RSTV            ; rst 38
        jp      NMIH            ; NMI (vblank) -- must be valid; see below

; ============================================================
; Entry.
; ============================================================
START:
        di                      ; the mailbox contract: no maskable interrupts
        ld      sp,$73B8        ; stack below the BIOS scratch at $73B9

        xor     a               ; clear the OS7 variables the skipped title
        ld      (VDP_STATUS_BYTE),a  ; screen would normally have initialised
        ld      (DEFER_WRITES),a
        ld      (MUX_SPRITES),a

        call    MODE_1          ; Graphics I
        call    LOAD_ASCII      ; BIOS font: name-table byte == ASCII code
        ld      hl,$2000        ; colour table: white on dark blue, all groups
        ld      de,32
        ld      a,$F4
        call    FILL_VRAM

        ld      hl,MTITLE       ; row 0: the title
        ld      de,0
        ld      iy,MTITLE_L
        call    SHOW

        call    FNPRES          ; is a FujiNet cartridge actually here?
        jr      nz,NOCART

        ld      d,$70           ; device: the Fuji adapter
        ld      e,$C4           ; command: GET_ADAPTERCONFIG_EXTENDED
        call    FNSTART
        call    FNCOMMIT
        jr      c,ETMO          ; carry: the cart never answered
        or      a
        jr      nz,EERR         ; FN_ERR nonzero: no link, timeout, bad frame
        call    FNACKED
        jr      nz,ENAK         ; the adapter refused the command

; The reply is a 240-byte AdapterConfigExtended in the window at $F800. Its
; friendliest fields are text at fixed offsets: SSID at +0, the firmware
; version at +125, and the dotted-decimal IP at +140. FNLEN measures each one
; so PUT_VRAM writes only the real characters, not the NUL padding behind them.
        ld      hl,LSSID
        ld      de,2*COLS
        ld      iy,LSSID_L
        call    SHOW
        ld      hl,FN_REPLY+0
        ld      de,3*COLS+2
        ld      b,32
        call    SHOWFLD

        ld      hl,LIP
        ld      de,5*COLS
        ld      iy,LIP_L
        call    SHOW
        ld      hl,FN_REPLY+140
        ld      de,6*COLS+2
        ld      b,16
        call    SHOWFLD

        ld      hl,LFW
        ld      de,8*COLS
        ld      iy,LFW_L
        call    SHOW
        ld      hl,FN_REPLY+125
        ld      de,9*COLS+2
        ld      b,15
        call    SHOWFLD

        ld      hl,MOK
        ld      de,11*COLS
        ld      iy,MOK_L
        call    SHOW
HALT1:
        jr      HALT1

NOCART: ld      hl,MNOCART
        ld      iy,MNOCART_L
        jr      SHOWERR
ETMO:   ld      hl,MTMO
        ld      iy,MTMO_L
        jr      SHOWERR
EERR:   ld      hl,MERR
        ld      iy,MERR_L
        jr      SHOWERR
ENAK:   ld      hl,MNAK
        ld      iy,MNAK_L
SHOWERR:
        ld      de,2*COLS
        call    SHOW
        jr      HALT1

; ============================================================
; SHOW  -- PUT_VRAM a fixed-length string to the name table.
;   in: HL = data, DE = name index, IY = length      clobbers: everything
; SHOWFLD -- the same, but for a NUL-terminated field of at most B bytes out of
; the reply window: measure it first, then draw only that many.
;   in: HL = field, DE = name index, B = max length
; ============================================================
SHOW:
        ld      a,VDP_NAME
        call    PUT_VRAM
        ret

SHOWFLD:
        ; count characters up to a NUL or B, without disturbing HL/DE
        push    hl
        push    de
        ld      c,0             ; running length
SF1:
        ld      a,(hl)
        or      a
        jr      z,SF2
        inc     hl
        inc     c
        djnz    SF1
SF2:
        pop     de
        pop     hl
        ld      a,c
        or      a
        ret     z               ; empty field: draw nothing
        ld      iyl,c           ; IY = length for PUT_VRAM
        ld      iyh,0
        ld      a,VDP_NAME
        call    PUT_VRAM
        ret

; The vblank NMI cannot be masked, and the BIOS vectors it here. MODE_1 leaves
; the VDP interrupt disabled, so it should never fire -- but the connector
; carries no reset line and the VDP powers up in an unknown state, so the
; vector must be valid regardless. Reading the status port drops a latched
; interrupt.
NMIH:
        push    af
        in      a,($BF)
        pop     af
        retn

RSTV:
        ret

; ---- text (with assembled lengths, so SHOW needs no strlen) ----
MTITLE:  defm "FUJINET  ACFG DEMO"
MTITLE_L equ $ - MTITLE
LSSID:   defm "SSID"
LSSID_L  equ $ - LSSID
LIP:     defm "IP ADDRESS"
LIP_L    equ $ - LIP
LFW:     defm "FIRMWARE"
LFW_L    equ $ - LFW
MOK:     defm "OK"
MOK_L    equ $ - MOK
MNOCART: defm "NO FUJINET CART"
MNOCART_L equ $ - MNOCART
MTMO:    defm "TIMEOUT - NO ANSWER"
MTMO_L   equ $ - MTMO
MERR:    defm "TRANSPORT ERROR"
MERR_L   equ $ - MERR
MNAK:    defm "COMMAND REFUSED (NAK)"
MNAK_L   equ $ - MNAK

; The mailbox library.
        include "fujimail.inc"
