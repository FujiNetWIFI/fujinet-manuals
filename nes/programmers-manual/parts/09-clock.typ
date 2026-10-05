#import "../lib.typ": *

= The Clock and Other Devices

#lead[The NES has no clock of its own. The FujiNet has one, set from the
network, and it will tell you the time in any of seven formats.]

== What time is it?

#wholefile("listings/c/clock.c", "listings/c/clock.c")

`clock_get_time()` writes a NUL after the reply, so give it a buffer one byte
longer than the format. The ISO string is 25 characters -- with its own NUL,
26 -- so `now` is 26 bytes.

In assembly the time is drawn straight out of the reply window, in vblank,
since this program keeps the screen on while it waits:

#excerpt-at("listings/asm/clock.s: once a second", "listings/asm/clock.s",
  "loop:   CALL", to: "wait:   lda", size: 6.8pt)

#shots("clock-c", "clock-asm", caption: [The FujiNet's clock, in C and in
assembly. This FujiNet's zone is UTC.])

== The clock device

Every read command takes one optional parameter: 1 to give the time in the
*alternate* time zone set by SETTZ, `$99`, rather than the FujiNet's own.

#cmd("Get time, ISO 8601", dev: "$45", code: "$49 'I' / $5A 'Z'",
  params: [alternate zone (1), optional.],
  reply: [25 bytes: `2026-10-04T18:20:00-0500` and a NUL. `$49` in the
    FujiNet's zone, `$5A` in UTC.],
  asm: "        CALL    FNDEVC, CLKISO, 0
        jsr     fn_go
        jne     fail            ; the string at FN_RPLY",
  c: "clock_get_time(now, TZ_ISO_STRING);
clock_get_time(now, UTC_ISO_STRING);")[]

#cmd("Get time, binary", dev: "$45", code: "$93 / $9A",
  params: [alternate zone (1), optional.],
  reply: [6 bytes: day, month, year minus 2000, hour, minute, second. `$9A`
    always uses the alternate zone.],
  asm: "        CALL    FNDEVC, CLKTIME, 0
        jsr     fn_go
        jne     fail
        lda     FN_RPLY+3       ; the hour",
  c: "clock_get_time(now, APETIME_BINARY);")[]

#cmd("Get time, simple", dev: "$45", code: "$54 'T' / $4D 'M'",
  params: [alternate zone (1), optional.],
  reply: [`$54`: 7 bytes -- century (20), year, month, day, hour, minute,
    second. `$4D`: the same and hundredths of a second, 8 bytes.],
  asm: "        CALL    FNDEVC, CLKSIMP, 0
        jsr     fn_go",
  c: "clock_get_time(now, SIMPLE_BINARY);")[]

#cmd("Get time, ProDOS and SOS", dev: "$45", code: "$50 'P' / $53 'S'",
  params: [alternate zone (1), optional.],
  reply: [`$50`: ProDOS's 4-byte date and time. `$53`: Apple III SOS, 19
    bytes, `YYYYMMDD0HHMMSS000` and a NUL.],
  asm: "        CALL    FNDEVC, CLKPRODOS, 0
        jsr     fn_go",
  c: "clock_get_time(now, PRODOS_BINARY);")[]

#cmd("Get time zone", dev: "$45", code: "$47 'G' / $4C 'L'",
  reply: [`$47`: the zone string and a NUL, `UTC` if none is set. `$4C`: one
    byte, its length plus one.],
  asm: "        CALL    FNDEVC, CLKGTZ, 0
        jsr     fn_go",
  c: "clock_get_tz((char *) buf);")[]

#cmd("Set time zone", dev: "$45", code: "$74 't' / $99",
  payload: [A POSIX time zone such as `EST5EDT` or `CET-1CEST`.],
  reply: [none; NAK for an empty payload.],
  asm: "        CALL    FNDEVC, CLKSETS, 0
        ldx     #0
:       lda     data,x
        beq     :+
        jsr     fn_txb
        inx
        bne     :-
:       jsr     fn_go",
  c: "clock_set_tz(\"EST5EDT\");
clock_get_time_tz(now, \"CET-1CEST\",
                  TZ_ISO_STRING);")[
`$74` sets the FujiNet's own zone and saves it. `$99` sets the alternate
zone, in memory only, for reads that ask for it. A zone that does not make
sense is ignored -- but still answered with an ACK.]

The clock NAKs `$7A`, `$73`, `$70`, `$69`, `$61` and `$41`: those are
other computers' spellings. Use the alternate-zone parameter instead.

== Disks

Devices `$31` to `$38` are the eight device slots seen as disk drives, in
512-byte sectors. A NES program has little use for them, but they work. A
slot holding a cartridge image has no sectors: every command to it NAKs.

#cmd("Read sector", dev: "$31", code: "$52 'R'",
  params: [sector (4), from 0.],
  reply: [512 bytes; NAK past the end, or if nothing is mounted.],
  asm: "        CALL    FNDEVD, DKREAD, 1
        lda     #4              ; size: 4 bytes
        jsr     fn_txb
        lda     #0              ; sector 0
        jsr     fn_txb
        jsr     fn_txb
        jsr     fn_txb
        jsr     fn_txb
        jsr     fn_go",
  c: "fuji_bus_call(FUJI_DEVICEID_DISK, 'R',
              FUJI_FIELD_C1234 | FUJI_FIELD_REPLY,
              0, 0, 0, 0, buf, 512);")[]

#cmd("Write sector", dev: "$31", code: "$57 'W' / $50 'P'",
  params: [sector (4).],
  payload: [512 bytes.],
  reply: [none. `$57` verifies the write; `$50` does not.],
  asm: "        CALL    FNDEVD, DKWRITE, 1
        ; 4-byte sector, then 512 bytes:
        ; more than the TX stream holds",
  c: "/* 4 + 1 + 512 bytes: too many for one
   NES transaction */")[
#hilite("Caution"): a sector is bigger than the TX stream's 320 bytes. On the
NES a disk is in practice read-only.]

The other disk commands -- `$53` STATUS, which this firmware wrongly treats as
a write; `$21` and `$22` FORMAT, which return a sector of status; and `$4E`
and `$4F`, the PERCOM block -- are of no use to an NES program.

== The printer

#cmd("Print", dev: "$40", code: "$57 'W' / $50 'P'",
  payload: [The bytes to print, up to 320.],
  reply: [none. If the printer is switched off in the FujiNet's
    configuration there is no reply at all, and the transaction times out.],
  asm: "        CALL    FNDEVP, PRWRITE, 0
        ldx     #0
:       lda     data,x
        beq     :+
        jsr     fn_txb
        inx
        bne     :-
:       jsr     fn_go",
  c: "fuji_bus_call(FUJI_DEVICEID_PRINTER, 'W',
              FUJI_FIELD_DATA, 0, 0, 0, 0,
              \"HELLO\\r\\n\", 7);")[
The FujiNet's printer writes what it receives to a file, which you fetch from
its web page. STATUS, `$53`, takes one parameter and answers four bytes.]

== The modem

The FujiNet's modem, device `$50`, is there -- but its replies are sent as
raw, unframed bytes, the way a real modem talks, and a command whose reply
has no data sends nothing at all. The cartridge waits for a FujiBus frame that
never comes, and every modem command ends as a timeout. Use the network
device's TCP and Telnet channels instead.
