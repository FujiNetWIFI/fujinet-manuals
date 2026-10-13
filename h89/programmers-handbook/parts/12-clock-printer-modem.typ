#import "../lib.typ": *
#import "../prog.typ": *

#chapter(12, "Clock, Printer and Modem")

#section("General")[
Three more devices complete the FujiNet: a clock (45H), which knows the time from the Internet; a
printer (40H), which turns what an H89 program prints into a file; and a modem (50H), which makes the
FujiNet look like a Hayes modem to programs written for one.

The clock is the useful one. The H89 has no clock of its own that survives being switched off ---
HDOS asks for the date every time it starts --- and the FujiNet's is set from the network. The
printer and the modem are there because the firmware is shared with other computers; on the H89 both
have serious faults, given below.
]

#section("The Clock", balance: false)[
The FujiNet keeps the time in Universal Time (UTC), from the Internet, and gives it in seven forms,
each as some other computer liked it. It also keeps two *time zones*: the *system* zone, saved in its
settings and set from its web page or by APETIME_SETTZ_ALT, and an *alternate* zone, kept only until
the FujiNet restarts, set by APETIME_SETTZ. Most of the commands take one field: 1 asks for the time
in the alternate zone, anything else (or nothing) in the system zone.

Time zones are written the POSIX way: `CST6CDT,M3.2.0,M11.1.0` is Central time, six hours behind UTC,
with summer time from the second Sunday of March to the first Sunday of November. `UTC0` is UTC.

The examples ran with the system zone UTC, and then set the alternate zone to Central time and the
system zone to Eastern; the times in the bytes are when they ran.

#cmdcard("Get Time", dev: 0x45, cmd: 0x93, equ: "APETIME_GETTIME",
  lines: (("Fields", [1 byte: 1 for the alternate zone]), ("Payload", [none]),
    ("Reply", [6 bytes: day, month, year since 2000, hour, minute, second])))
The time in six binary bytes, the simplest form for a Z80 program.

#warning[fujinet-lib's `clock_get_time()` puts a zero after the reply, so its buffer must be one byte
longer than the form's reply: 7 bytes here.]
#examples("clock.gettime")

#cmdcard("Get Time, Simple", dev: 0x45, cmd: 0x54, equ: "APETIME_SETTZ_ALT2",
  lines: (("Fields", [1 byte: 1 for the alternate zone]), ("Payload", [none]),
    ("Reply", [7 bytes: century, year, month, day, hour, minute, second])))
The time with the century: 20, 26, 10, 13 and so on. The firmware's name for 54H says it sets a time
zone, but on the H89 it is this form of the time.
#examples("clock.settz_alt2")

#cmdcard("Get Time, with Hundredths", dev: 0x45, cmd: 0x4D, equ: "APETIME_GET_SIMPLE_HUNDREDTHS",
  lines: (("Fields", [1 byte]), ("Payload", [none]), ("Reply", [8 bytes: as 54H, then hundredths])))
#examples("clock.get_simple_hundredths")

#cmdcard("Get Time, ProDOS", dev: 0x45, cmd: 0x50, equ: "APETIME_GET_PRODOS",
  lines: (("Fields", [1 byte]), ("Payload", [none]),
    ("Reply", [4 bytes: the date as a word, minute, hour])))
The Apple's ProDOS form: a word holding the year since 1900 (7 bits), month (4) and day (5), low
byte first, then the minute and hour.
#examples("clock.get_prodos")

#cmdcard("Get Time, SOS", dev: 0x45, cmd: 0x53, equ: "APETIME_GET_SOS",
  lines: (("Fields", [1 byte]), ("Payload", [none]),
    ("Reply", [19 bytes: `YYYYMMDD0HHMMSS000` and a zero])))
The Apple III's form, as digits. (The tenth digit is a weekday that is always 0.)
#examples("clock.get_sos")

#cmdcard("Get Time, ISO", dev: 0x45, cmd: 0x49, equ: "APETIME_GET_ISO_LOCAL",
  lines: (("Fields", [1 byte]), ("Payload", [none]),
    ("Reply", [25 bytes: `YYYY-MM-DDTHH:MM:SS+HHMM` and a zero])))
The international standard form, with the zone's distance from UTC at the end: the easiest to print.
#examples("clock.get_iso_local")

#cmdcard("Get Time, ISO, UTC", dev: 0x45, cmd: 0x5A, equ: "APETIME_GET_ISO_UTC",
  lines: (("Fields", [1 byte (ignored)]), ("Payload", [none]),
    ("Reply", [25 bytes: as 49H, always +0000])))
The same in UTC, whatever the zones say.
#examples("clock.get_iso_utc")

#cmdcard("Get Time Zone Length", dev: 0x45, cmd: 0x4C, equ: "APETIME_GETTZ_LEN",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [1 byte: the system zone's length + 1])))
How long the system zone's name is, counting the zero after it: ask this first, then APETIME_GET_GENERAL
for that many bytes. fujinet-lib has no function for it alone.
#examples("clock.gettz_len")

#cmdcard("Get Time Zone", dev: 0x45, cmd: 0x47, equ: "APETIME_GET_GENERAL",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [the system zone, and a zero])))
The system time zone, as text. fujinet-lib's `clock_get_tz()` asks the length first, then this.
#examples("clock.get_general")

#cmdcard("Set Alternate Time Zone", dev: 0x45, cmd: 0x99, equ: "APETIME_SETTZ",
  lines: (("Fields", [any (ignored)]), ("Payload", [the zone, as text]), ("Reply", [ACK])))
Sets the alternate zone, until the FujiNet restarts. The time commands then give it with their field 1.

#warning[The FujiNet answers ACK before it looks at the zone. One with a character it does not like
--- a CR, a zero at the start --- is quietly ignored, and the zone stays as it was; one that is
merely wrong is kept, and the times come out in UTC. Check with APETIME_GET_ISO_LOCAL.]
#examples("clock.settz")

#cmdcard("Get Time in the Alternate Zone", dev: 0x45, cmd: 0x9A, equ: "APETIME_GETTZTIME",
  lines: (("Fields", [any (ignored)]), ("Payload", [none]), ("Reply", [6 bytes, as 93H])))
APETIME_GETTIME in the alternate zone, whatever the field says. With no alternate zone set, the system
zone. fujinet-lib has no function for it.
#examples("clock.gettztime")

#cmdcard("The Forms in the Alternate Zone", dev: 0x45, cmd: 0x49)
The same commands with the field 1. Central time is five hours behind UTC in October:
#examples("clock.get_iso_local.alt")

The ISO UTC form ignores the field:
#examples("clock.get_iso_utc.alt")

#cmdcard("Set Time Zone", dev: 0x45, cmd: 0x74, equ: "APETIME_SETTZ_ALT",
  lines: (("Fields", [any (ignored)]), ("Payload", [the zone, as text]), ("Reply", [ACK])))
Sets the *system* zone, and saves it in the FujiNet's settings, so it lasts. (The names of 99H and
74H are the wrong way round for what they do.) The example sets Eastern time, then reads it back.
#examples("clock.settz_alt")
#examples("clock.get_general.new")
#examples("clock.get_iso_local.new")

#cmdcard("A Bad Time Zone", dev: 0x45, cmd: 0x74)
A zone with a CR in it is answered ACK, and ignored: the zone is still Eastern.
#examples("clock.settz_alt.bad")
#examples("clock.get_general.kept")
]

#section("The Printer", balance: false)[
The FujiNet's printer is not a machine: it turns what it is sent into a file called `paper`, on the
microSD card (or the FujiNet's own flash), which you fetch from the FujiNet's web page. The
FujiNet's settings choose a printer to imitate; the examples ran with type 1, which writes the bytes
as they come. (fujinet-pc keeps `paper` in its SD directory; the examples' output was checked there.)

#warning[If the printer is turned off in the FujiNet's settings, it does not answer at all: no ACK,
no NAK, nothing, and a program waits out its timeout.]

#cmdcard("Print", dev: 0x40, cmd: 0x57, equ: "PRINTER_WRITE", tags: ("Output checked on host",),
  lines: (("Fields", [none needed]), ("Payload", [the bytes to print, 1 to 255]), ("Reply", [ACK])))
Prints the payload. NAK if there is none. The example's line arrived in `paper` exactly as sent,
CR LF and all.

#warning[Keep each WRITE to 255 bytes or fewer. The firmware takes the length in eight bits: 256
bytes print nothing (and still ACK), 300 print only the first 44 --- as the example below shows. And
more than 320 bytes overruns the printer's buffer and corrupts the firmware's memory: never send
that much.]
#examples("printer.write")

#cmdcard("Print (PUT)", dev: 0x40, cmd: 0x50, equ: "PRINTER_PUT", tags: ("Output checked on host",),
  lines: (("Fields", [none needed]), ("Payload", [the bytes to print]), ("Reply", [ACK])))
The same as PRINTER_WRITE.
#examples("printer.put")

#cmdcard("Printing Too Much", dev: 0x40, cmd: 0x57)
Three hundred bytes, answered ACK: only the first 44 reached the paper. And 256 bytes print nothing:
#examples("printer.write.300")
#examples("printer.write.256")

#cmdcard("Printer Status", dev: 0x40, cmd: 0x53, equ: "PRINTER_STATUS",
  lines: (("Fields", [1 byte (any value, but send it)]), ("Payload", [none]), ("Reply", [4 bytes])))
Four bytes in the Atari's form; the third is a timeout (5). The second is never set by the firmware,
and is whatever was in memory (00H on fujinet-pc). NAK if the field is missing --- the one command
in this chapter that says so rather than stopping.
#examples("printer.status")
#examples("printer.status.nofield")
]

#section("The Modem", balance: false)[
The FujiNet's modem lets a program written for a Hayes modem --- a terminal program, a bulletin
board --- reach the Internet: `ATDT host:port` dials a TCP connection, and the bytes then pass both
ways, as over a telephone line. The FujiNet can also answer calls, listening on a port of its own.

On the H89, the modem is the strangest device of the six:

- Its replies are not FujiBus frames. Commands go as frames, but what comes back is bare bytes, with
  no header, checksum or END --- and an ACK or NAK sends nothing at all. A program sends a command and
  then simply reads what bytes come, until they stop. The book's library has `fn_send` (a request that
  waits for no reply) and `fn_raw` (take bytes until 200 ms of quiet) for this; fujinet-lib cannot do
  it, so the C examples use the book's `rawbus.c`. Every card in this section is tagged UNFRAMED.
- Bytes the H89 sends *outside* any frame go to the modem too, as if typed at it. Another way to send
  AT commands; and the reason a request that loses its opening END is taken as modem input.
- The modem never sends its result text. `AT` gets no `OK`; `ATDT` gets no `CONNECT` until well after
  the far end's first data has arrived. Only RING, CONNECT and NO CARRIER come back, and data.
- `+++`, to get back to command mode during a call, does not work: the bytes go to the far end.

#warning[Several things stop the firmware: a modem command with a field missing (SET_DUMP, LISTEN,
BAUDRATELOCK, AUTOANSWER and STATUS all need theirs); LISTEN on port 0; `ATCPM`; and an `ATDT` whose
port is not a number. None of these is sent in the examples.]

#cmdcard("Write", dev: 0x50, cmd: 0x57, equ: "MODEM_WRITE", tags: ("Unframed",),
  lines: (("Fields", [none]), ("Payload", [bytes for the modem]), ("Reply", [bare bytes, or none])))
Sends bytes to the modem: AT commands when it is idle, data during a call. Here `ATDT` dials the test
board: no `OK`, and the board's greeting arrives at once, with `CONNECT 2400` a second behind it.
#examples("modem.write")

#cmdcard("AT, Unanswered", dev: 0x50, cmd: 0x57)
`AT` alone, which on a real modem answers `OK`. Here, nothing comes back.
#examples("modem.write.at")

#cmdcard("During a Call", dev: 0x50, cmd: 0x57)
During the call, WRITE sends data, and what the far end sends comes back as bare bytes:
#examples("modem.write.online")

`+++` and `ATH` are not commands during a call, only data: the board echoes them.
#examples("modem.write.plus")
#examples("modem.write.ath")

#cmdcard("Status", dev: 0x50, cmd: 0x53, equ: "MODEM_STATUS", tags: ("Unframed",),
  lines: (("Fields", [1 byte (send it)]), ("Payload", [none]), ("Reply", [2 bare bytes])))
The modem's state in two bytes, the Atari 850's form: 00 00 when idle, 00 CCH connected, 00 CDH with
a caller waiting.
#examples("modem.status")
#examples("modem.status.online")

#cmdcard("Listen and Answer", dev: 0x50, cmd: 0x4C, equ: "MODEM_LISTEN", tags: ("Unframed",),
  lines: (("Fields", [a word: the port (not 0)]), ("Payload", [none]), ("Reply", [RING, when a call comes])))
Listens for calls on a TCP port. When one comes, the modem sends `RING` (and again every few
seconds), and STATUS shows a caller waiting. `ATA` (in a WRITE) answers: the caller's data arrives,
then `CONNECT`. MODEM_UNLISTEN (4DH) stops listening.
#examples("modem.listen")
#examples("modem.status.ring")
#examples("modem.write.ata")
#examples("modem.unlisten")

#cmdcard("Stream", dev: 0x50, cmd: 0x58, equ: "MODEM_STREAM", tags: ("Unframed",),
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [9 bare bytes])))
For the Atari's 850 interface, a description of the serial line; meaningless on the H89, and on
fujinet-pc on a real serial port it changes the port's speed. Shown for completeness.
#examples("modem.stream")

#cmdcard("Settings", dev: 0x50, cmd: 0x42, equ: "MODEM_CONFIGURE", tags: ("Unframed",),
  lines: (("Fields", [varies]), ("Payload", [none]), ("Reply", [nothing])))
Four commands set things up, and answer nothing: MODEM_CONFIGURE (42H, the line speed --- always
9600, whatever is asked), MODEM_CONTROL (41H, the handshake lines, which do nothing here),
MODEM_BAUDRATELOCK (4EH, two words: lock on, and the speed CONNECT reports) and MODEM_SET_DUMP
(44H, a byte: the traffic log on or off). MODEM_AUTOANSWER (4FH, a byte) answers calls without `ATA`.
#metadata("MODEM_CONTROL") <cmd-MODEM_CONTROL>
#metadata("MODEM_BAUDRATELOCK") <cmd-MODEM_BAUDRATELOCK>
#metadata("MODEM_SET_DUMP") <cmd-MODEM_SET_DUMP>
#metadata("MODEM_AUTOANSWER") <cmd-MODEM_AUTOANSWER>
#metadata("MODEM_UNLISTEN") <cmd-MODEM_UNLISTEN>
#examples("modem.configure")
#examples("modem.baudratelock")
#examples("modem.autoanswer")

#cmdcard("AT Commands Without a Frame", dev: 0x50)
The same `ATDT` sent as bare bytes, outside any frame, works as well; the FujiNet acts on it half a
second after the last byte, when it decides the bytes have stopped.
#examples("modem.write.raw_dial")
]
