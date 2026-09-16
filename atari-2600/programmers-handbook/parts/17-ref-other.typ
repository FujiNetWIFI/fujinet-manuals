#import "../lib.typ": *
= Command Reference: Disk, Printer, Clock, Modem

The mailbox is a transport, not a translator: whatever byte goes into the DEVICE register goes on the wire. Beyond the FUJI and network devices, the RS232 build answers four more --- disks, a printer, a clock and a Hayes-style modem. Only the clock is exercised by a program in this handbook; the others are reachable capability, documented as such, their behaviour transcribed from the RS232 handlers.

#sect[Disk --- devices `$31`--`$38`]

Eight disk devices, `$31` plus the drive number. On this build every sector is 512 bytes and the offset is `sector` × 512. Read and write name the sector in the first parameter; a missing parameter throws on the adapter, so always supply it.

#cmd("DISK_READ / DISK_WRITE / DISK_PUT", code: "$52 / $57 / $50", dev: "$31", nparam: "1",
  params: [the sector number, as one two-byte parameter],
  payload: [WRITE and PUT: 512 bytes], reply: [READ: 512 bytes; WRITE and PUT: ACK],
  asm: "        lda     #DSKDEV         ; disk 1
        sta     FNDEV
        lda     #$52            ; READ
        sta     FNCMD
        lda     #1
        sta     FNNPR
        jsr     FNBEG
        lda     SECLO
        ldx     SECHI
        jsr     FNPW
        jsr     FNGO
; 512 bytes at FNRPLY, one slice",
  bas: " dev = DSKDEV
 cmd = $52
 npar = 1
 gosub fnbeg
 FNTX = 2
 FNTX = seclo
 FNTX = sechi
 gosub fngo",
  [`$53` is not a status call on this build: it falls through into the write path, so never send it to a disk expecting a status. With no image mounted, READ answers NAK.])

#cmd("DISK_FORMAT / FORMAT_MEDIUM / PERCOM_READ / PERCOM_WRITE", code: "$21 / $22 / $4E / $4F", dev: "$31", nparam: "0",
  reply: [FORMAT: a bad-sector map; PERCOM_READ: a 12-byte geometry block],
  [Vestigial on this build: the two FORMATs write nothing to the image, and the PERCOM block is a 12-byte scratch area with no effect on geometry.])

#sect[Printer --- device `$40`]

#cmd("PRINTER_WRITE / PRINTER_PUT / PRINTER_STATUS", code: "$57 / $50 / $53", dev: "$40", nparam: "0 / 0 / 1",
  params: [STATUS: byte, request type, required but ignored],
  payload: [WRITE and PUT: the bytes to print, fewer than 255],
  reply: [WRITE and PUT: ACK; STATUS: 4 bytes],
  asm: "        lda     #PRNDEV
        sta     FNDEV
        lda     #$57            ; WRITE
        sta     FNCMD
        lda     #0
        sta     FNNPR
        jsr     FNBEG
        ldy     #0
P1:     lda     LINE,y
        beq     P2
        sta     FNTX
        iny
        bne     P1
P2:     jsr     FNGO",
  bas: " dev = PRNDEV
 cmd = $57
 npar = 0
 gosub fnbeg
 for l = 0 to line_length - 1
 FNTX = line[l]
 next
 gosub fngo",
  [Output goes to a paper file on the adapter, retrieved through its web interface, in whatever printer emulation is configured. A disabled printer does not reply at all, and the cartridge reports a timeout.])

#sect[Clock --- device `$45`]

Present when APETime is enabled in the adapter's configuration, which it is by default. Reads come in many formats; a parameter of 1 on a read selects the alternate zone set by `SETTZ`.

#cmd("GETTIME / GET_ISO_LOCAL / GET_ISO_UTC", code: "$93 / $49 'I' / $5A 'Z'", dev: "$45", nparam: "0",
  params: [optional byte: 1 = the alternate zone],
  reply: [GETTIME: 7 bytes, binary; the ISO forms: `2026-09-15T20:45:31+0000` and a NUL],
  asm: "        lda     #CLKDEV
        sta     FNDEV
        lda     #CKISOL
        sta     FNCMD
        lda     #0
        sta     FNNPR
        jsr     FNBEG
        jsr     FNGO
        lda     #3              ; the date, ten characters
        ldx     #0
        ldy     #10
        jsr     FNRRPL",
  bas: " dev = CLKDEV
 cmd = CKISOL
 npar = 0
 gosub fnbeg
 gosub fngo
 FNH_TROW = 3
 for l = 0 to 9
 FNH_TCHR = FNRPLY[l]
 next
 gosub fnend",
  [Section 12 shows both. The other formats: `GET_PRODOS` (`$50`, 4 bytes), `GET_SOS` (`$53`, text), `GET_SIMPLE_HUNDREDTHS` (`$4D`, 8 bytes), `GET_GENERAL` (`$47`, the zone string), `GETTZ_LEN` (`$4C`), and `GETTZTIME` (`$9A`).])

#cmd("SETTZ", code: "$99", dev: "$45", nparam: "0",
  payload: [a POSIX zone string, such as `CST6CDT`],
  reply: [ACK],
  [Sets the zone the local-time reads use. `SETTZ_ALT` (`$74`) and `SETTZ_ALT2` (`$54`) set the alternate zone the reads select with a parameter of 1.])

#sect[Modem --- device `$50`]

A Hayes-style virtual modem that dials TCP instead of phone lines: `ATDT host:port` opens a socket, `ATNET1` runs the session through telnet negotiation. Ten packet commands configure and poll it; the character stream itself is unframed. Reachable but unexercised on this console.

#cmd("MODEM_STATUS / MODEM_WRITE / MODEM_STREAM", code: "$53 / $57 / $58", dev: "$50", nparam: "1 / 0 / 0",
  params: [STATUS: byte, ignored but required],
  payload: [WRITE: an AT command line, or data once connected],
  reply: [STATUS: 2 bytes, the second carrying the handshake bits (`$CD` connected with data, `$CC` connected idle, `$00` idle); WRITE: ACK; STREAM: a 9-byte baud table],
  [The other seven --- `CONTROL` `$41`, `CONFIGURE` `$42`, `SET_DUMP` `$44`, `LISTEN` `$4C`, `UNLISTEN` `$4D`, `BAUDRATELOCK` `$4E`, `AUTOANSWER` `$4F` --- configure the virtual modem. Disabled in the configuration, it does not reply.])
