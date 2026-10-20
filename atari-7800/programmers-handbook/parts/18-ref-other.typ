#import "../lib.typ": *
= Command Reference: Disk, Printer, Clock, Modem

#ini[T]he mailbox is a transport, not a translator: whatever byte goes into the DEVICE register goes onto the wire. Beyond the FUJI and network devices, the FujiNet answers four more for a 7800: disk drives, a printer, a clock and a Hayes-style modem. The clock is exercised by a program in this handbook (Section 13), and its replies below were measured on the bench. The others are reachable, transcribed from the firmware’s handlers, and offered as such.

#sect[Disk: devices `$31`–`$38`]

Eight virtual drives, `$31` plus the drive number, each serving the image mounted in its device slot. The sector size is the image’s. On the 7800 a mount also pushes the image into the cartridge (Section 12); reading it as a disk as well is possible, and rarely useful.

#cmd("DISK_READ / DISK_WRITE / DISK_PUT", code: "$52 / $57 / $50", dev: "$31", nparam: "1",
  params: [the sector number, as one parameter (two or four bytes)],
  payload: [WRITE and PUT: one sector], reply: [READ: one sector; WRITE and PUT: ACK],
  asm: "        FNBEGIN DSKDEV, $52, 1  ; DISK_READ, drive 1
        lda     #1              ; sector 1
        ldx     #0
        jsr     fn_pw
        jsr     fn_go           ; the sector at FN_REPLY",
  c: "if (!fuji_bus_call(0x31, 0x52, FUJI_FIELD_B12 | FUJI_FIELD_REPLY,
                   1, 0, 0, 0, buf, 512))
    failed();",
  bas: " fn_dev = $31 : fn_cmd = $52 : fn_npr = 1
 gosub fn_beg
 fn_val = 1 : fn_valhi = 0 : gosub fn_pw
 gosub fn_go",
  [With nothing mounted, READ answers NAK. WRITE verifies what it wrote; PUT does not.])

#cmd("DISK_STATUS", code: "$53", dev: "$31", nparam: "0 or 1",
  params: [optional byte: the kind of status],
  reply: [4 bytes: drive status, controller status, format timeout, 0],
  [The Atari-style status block, from whatever image is mounted.])

#cmd("DISK_FORMAT / FORMAT_MEDIUM / PERCOM_READ / PERCOM_WRITE", code: "$21 / $22 / $4E / $4F", dev: "$31", nparam: "0",
  reply: [FORMAT: a map of bad sectors; PERCOM_READ: a 12-byte geometry block],
  [Atari-drive commands the RS-232 build keeps; on an image they do little.])

#sect[Printer: device `$40`]

#cmd("PRINTER_WRITE / PRINTER_PUT / PRINTER_STATUS", code: "$57 / $50 / $53", dev: "$40", nparam: "0 / 0 / 1",
  params: [STATUS: byte, required but ignored],
  payload: [WRITE and PUT: the bytes to print, fewer than 255],
  reply: [WRITE and PUT: ACK; STATUS: 4 bytes],
  asm: "        FNBEGIN PRNDEV, $57, 0  ; PRINTER_WRITE
        ldy     #0
@p:     lda     data,y
        jsr     fn_txb
        iny
        cpy     #dataend-data
        bne     @p
        lda     #13             ; a carriage return
        jsr     fn_txb
        jsr     fn_go",
  c: "if (!fuji_bus_call(0x40, 0x57, FUJI_FIELD_DATA,
                   0, 0, 0, 0, data, 5))
    failed();",
  bas: " fn_dev = $40 : fn_cmd = $57 : fn_npr = 0
 gosub fn_beg
 last = value_length - 1
 for ix = 0 to last : FN_TX = value[ix] : next
 FN_TX = 13
 gosub fn_go",
  [The page goes to a file on the adapter, in the printer it is set to imitate, and comes out through its web interface. A printer switched off in the adapter’s settings does not answer at all, and the cartridge reports a timeout.])

#sect[Clock: device `$45`]

On by default. A read with a parameter of 1 uses the alternate time zone instead of the adapter’s own. The lengths below are what the bench’s `fujinet-pc` answered.

#cmd("GETTIME / GET_ISO_LOCAL / GET_ISO_UTC", code: "$93 / $49 'I' / $5A 'Z'", dev: "$45", nparam: "0 or 1",
  params: [optional byte: 1 for the alternate zone],
  reply: [GETTIME: 6 bytes: day, month, year (two digits), hour, minute, second. The ISO forms: `2026-10-20T16:14:12+0000` and a NUL, 25 bytes],
  asm: "        FNBEGIN CLKDEV, CKGTIME, 0
        jsr     fn_go
        bne     failed
        lda     FN_REPLY+3      ; the hour
        sta     cnt",
  c: "if (clock_get_time(when, APETIME_BINARY))
    failed();                    /* when[3]: the hour */",
  bas: " fn_dev = FN_CLOCK : fn_cmd = $93 : fn_npr = 0
 gosub fn_beg
 gosub fn_go
 cnt = FN_REPLY[3] : rem the hour",
  [Section 13 has the ISO forms in all three languages. GET_ISO_UTC ignores the alternate zone.])

#cmd("The other formats", code: "$54 $50 $53 $4D $47 $4C $9A", dev: "$45", nparam: "0 or 1",
  reply: [`$54` `'T'`: 7 bytes, century, year, month, day, hour, minute, second; `$50` `'P'`: 4 bytes, ProDOS; `$53` `'S'`: 19 characters, Apple III SOS; `$4D` `'M'`: the 7 bytes and hundredths; `$47` `'G'`: the zone’s name, NUL-terminated; `$4C` `'L'`: one byte, its length; `$9A`: GETTIME in the alternate zone],
  [Every format fujinet-lib’s `clock_get_time()` offers, plus the zone. `$54` doubles as a write command on buses that have one; on this one it only reads.])

#cmd("SETTZ_ALT / SETTZ", code: "$74 't' / $99", dev: "$45", nparam: "0",
  payload: [a POSIX time-zone string, such as `CST6CDT`],
  reply: [ACK],
  asm: "        FNBEGIN CLKDEV, $74, 0  ; the adapter's own zone
        ldy     #0
@z:     lda     tz,y
        beq     @go
        jsr     fn_txb
        iny
        bne     @z
@go:    jsr     fn_go
        jmp     done
tz:     .byte   \"CST6CDT\", 0",
  c: "if (clock_set_tz(\"CST6CDT\"))
    failed();",
  bas: " fn_dev = FN_CLOCK : fn_cmd = $74 : fn_npr = 0
 gosub fn_beg
 FN_TX = $43 : FN_TX = $53 : FN_TX = $54 : FN_TX = $36
 gosub fn_go
 rem CST6: Central time, no daylight saving",
  [`$74` sets the zone the adapter uses for local time; `$99` sets the *alternate* zone that a read with a parameter of 1 uses. In C, `clock_set_tz()` sets the adapter’s, and `clock_get_time_tz()` reads in another zone without changing it.])

#sect[Modem: device `$50`]

A Hayes-style modem that dials TCP instead of telephone lines: `ATDT host:port` opens a connection, and `ATNET1` runs it through telnet negotiation. Ten packet commands set it up and poll it; the characters themselves flow through WRITE and STATUS.

#cmd("MODEM_STATUS / MODEM_WRITE / MODEM_STREAM", code: "$53 / $57 / $58", dev: "$50", nparam: "1 / 0 / 0",
  params: [STATUS: byte, required but ignored],
  payload: [WRITE: an AT command line, or data once connected],
  reply: [STATUS: 2 bytes, the second the handshake lines (`$CD` connected with data waiting, `$CC` connected, `$00` idle); WRITE: ACK; STREAM: a 9-byte baud table],
  [The other seven set the modem up: CONTROL `$41`, CONFIGURE `$42`, SET_DUMP `$44`, LISTEN `$4C`, UNLISTEN `$4D`, BAUDRATELOCK `$4E`, AUTOANSWER `$4F`. Switched off in the adapter’s settings, the modem does not answer.])
