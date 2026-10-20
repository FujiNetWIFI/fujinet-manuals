#import "../lib.typ": *
#set page(columns: 1)
#refpage.update(true)

= Command Reference: Disk, Printer, Clock and Modem <ref-other>

#hang([], [The mailbox is a transport, not a translator: whatever byte goes into the DEVICE register goes onto the wire. Beyond the FUJI and network devices, the FujiNet answers four more for a Studio II: disk drives, a printer, a clock and a Hayes-style modem. The clock is exercised by a program in this handbook, and its replies below were measured on the bench. The others are reachable, transcribed from the firmware’s handlers, and offered as such.])

#sect[Disk: devices `$31`–`$38`]

#hang([], [Eight virtual drives, `$31` plus the drive number, each serving the image mounted in its device slot. The sector size is the image’s. On the Studio II a mount also pushes the image into the cartridge; reading it as a disk as well is possible, and a way for a program to read a file a sector at a time.])

#cmd("DISK_READ / DISK_WRITE / DISK_PUT", code: "$52 / $57 / $50", dev: "$31", nparam: "1",
  params: [the sector number, as one parameter (two or four bytes)],
  payload: [WRITE and PUT: one sector], reply: [READ: one sector; WRITE and PUT: ACK],
  asm: "        FNBEGIN DSKDEV, 52H, 1  ; DISK_READ, drive 1
        LDR     R8, 1           ; sector 1
        FCALL   fn_pw
        GOACK                   ; the sector at $E400",
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
  asm: "        FNBEGIN PRNDEV, 57H, 0  ; PRINTER_WRITE
        LDR     R8, val
        FCALL   fn_str
        LDI     0DH             ; a carriage return
        FCALL   fn_txb
        GOACK",
  [The page goes to a file on the adapter, in the printer it is set to imitate, and comes out through its web interface. A printer switched off in the adapter’s settings does not answer at all, and the cartridge reports a timeout.])

#sect[Clock: device `$45`]

#hang([], [On by default. A read with a parameter of 1 uses the alternate time zone instead of the adapter’s own. The lengths below are what the bench’s `fujinet-pc` answered.])

#cmd("GETTIME / GET_ISO_LOCAL / GET_ISO_UTC", code: "$93 / $49 'I' / $5A 'Z'", dev: "$45", nparam: "0 or 1",
  params: [optional byte: 1 for the alternate zone],
  reply: [GETTIME: 6 bytes: day, month, year (two digits), hour, minute, second. The ISO forms: `2026-10-20T09:57:25-0400` and a NUL, 25 bytes],
  asm: "        FNBEGIN CLKDEV, CKGTIME, 0
        FCALL   fn_go
        BNZ     failed
        PEEK    FN_REPLY+3      ; the hour
        PLO     RA",
  [App Keys, Clock and Utilities prints the ISO forms. GET_ISO_UTC ignores the alternate zone.])

#cmd("The other formats", code: "$54 $50 $53 $4D $47 $4C $9A", dev: "$45", nparam: "0 or 1",
  reply: [`$54` `'T'`: 7 bytes, century, year, month, day, hour, minute, second; `$50` `'P'`: 4 bytes, ProDOS; `$53` `'S'`: 19 characters, Apple III SOS; `$4D` `'M'`: the 7 bytes and hundredths; `$47` `'G'`: the zone’s name, NUL-terminated; `$4C` `'L'`: one byte, its length; `$9A`: GETTIME in the alternate zone],
  [Every format the FujiNet’s clock knows, and the zone. Each also has a lower-case twin, `$69` `'i'`, `$7A` `'z'`, `$70` `'p'`, `$73` `'s'` and `$61` `'a'` (the Atari’s own six bytes, also `$41`), that reads in the alternate zone. `$54` doubles as a write command on buses that have one; on this one it only reads.])

#cmd("SETTZ_ALT / SETTZ", code: "$74 't' / $99", dev: "$45", nparam: "0",
  payload: [a POSIX time-zone string, such as `EST5EDT`],
  reply: [ACK],
  asm: "        FNBEGIN CLKDEV, 74H, 0  ; the adapter's zone
        LDR     R8, tz
        FCALL   fn_str
        GOACK",
  [`$74` sets the zone the adapter uses for local time, and saves it; `$99` sets the *alternate* zone that a read with a parameter of 1 uses. A string that is not a valid zone is dropped without a word.])

#sect[Modem: device `$50`]

#hang([], [A Hayes-style modem that dials TCP instead of telephone lines: `ATDT host:port` opens a connection, and `ATNET1` runs it through telnet negotiation. Ten packet commands set it up and poll it; the characters themselves flow through WRITE and STATUS.])

#cmd("MODEM_STATUS / MODEM_WRITE / MODEM_STREAM", code: "$53 / $57 / $58", dev: "$50", nparam: "1 / 0 / 0",
  params: [STATUS: byte, required but ignored],
  payload: [WRITE: an AT command line, or data once connected],
  reply: [STATUS: 2 bytes, the second the handshake lines (`$CD` connected with data waiting, `$CC` connected, `$00` idle); WRITE: ACK; STREAM: a 9-byte baud table],
  [The other seven set the modem up: CONTROL `$41`, CONFIGURE `$42`, SET_DUMP `$44`, LISTEN `$4C`, UNLISTEN `$4D`, BAUDRATELOCK `$4E`, AUTOANSWER `$4F`; and `$3F`, `$40`, `$21` and `$26` answer the Atari’s handler loader and polls. Switched off in the adapter’s settings, the modem does not answer.])

#refpage.update(false)
