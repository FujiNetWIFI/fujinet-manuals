#import "../lib.typ": *

= The Network Device <network>

The FujiNet has eight network channels, devices `$71` to `$78`. Each holds
one connection: an HTTP request, a TCP socket, a file on a TNFS or FTP
server, a UDP conversation. The devicespec says which, and the channel does
the rest; an Arcadia program only opens, asks, reads, writes and closes.

== The lifecycle

#steps(
  [*OPEN* (`$4F`): two one-byte parameters, the mode and the translation,
   then the devicespec as the payload: `N:` and a URL.],
  [*STATUS* (`$53`): two one-byte parameters of 0. Four bytes come back:
   how many bytes are waiting (two, low first), whether the connection is up,
   and the channel’s status, 1 when all is well.],
  [*READ* (`$52`): one two-byte parameter, the count. The bytes arrive in the
   reply window, RXLEN of them.],
  [*WRITE* (`$57`): one two-byte parameter, the count, then that many bytes
   as the payload.],
  [*CLOSE* (`$43`): no parameters.],
)

The cartridge gives a network channel 90 seconds for each of OPEN, STATUS,
READ and CLOSE, and `FNGO` waits that long (Section 4). `netlib.inc` wraps
the five; each returns R0 = 0 on an ACK.

#shot("netget", [netget: three lines over HTTP, from the bench’s web server])

== Opening

`netget` fetches a small text file over HTTP and shows it. The URL is the
bench’s; `build.sh` writes it into `build/gen/bookcfg.inc`, so the program
carries no address of its own:

#excerpt-at(auto, "listings/asm/netget.asm", "OPEN:   SETFSTR URL", n: 4)
#excerpt-at(auto, "listings/asm/netlib.inc", "NOPEN:  STRA,R2 NDST", to: "; NSTAT")

Mode 4 is a read: over HTTP, a GET. Mode 12 is a read and a write, which is
what a TCP connection wants (Section 12). Translation 0 leaves the bytes
alone; 1, 2 and 3 turn the line endings into CR, LF or CR LF. The
devicespec goes as the payload at its own length.

== How much is there?

The adapter answers OPEN as soon as it can, and an HTTP request is not even
sent until the first STATUS. STATUS says how many bytes are waiting _so far_,
so `netget` asks until two answers agree and are not zero, three frames
apart, thirty times at most:

#excerpt-at(auto, "listings/asm/netget.asm", "STAT1:  BSTA,UN NSTAT", to: "WAIT:   LODI,R3 3")

#note[In MAME, unthrottled, those thirty readings take a few milliseconds
of real time. Against a server across the internet they would run out
before it answered; against the bench’s own web server they do not. A
program for a real console asks for longer, or watches the tick (Section
15) rather than counting readings.]

== Reading

READ takes the bytes waiting, at most 192 here, a screen’s worth. The
window shows 256 at a time, and a reply can be 1,024 (Section 4):

#excerpt-at(auto, "listings/asm/netget.asm", "READ:   LODA,R2 NAVL", to: "; ---- show it")

Then the program walks the reply: a CR is skipped, an LF starts the next
row, anything else goes through `DXLAT` to the screen:

#excerpt-at(auto, "listings/asm/netget.asm", "SHOW1:  ADDI,R3 1", to: "SHOW2:")

== Closing

#excerpt-at(auto, "listings/asm/netget.asm", "CLOSE:  BSTA,UN NCLOSE", n: 4)

Close every channel you open, on the way out of a failure too: the adapter
keeps a connection open otherwise, even after the console is switched off.
A program that opens the same channel again closes it first; 5 Card Stud
puts the CLOSE of one request at the start of the next.

== JSON

The adapter can parse what it fetched and answer one value at a time, so a
program never holds a whole JSON document. Set the parser on the open
channel, parse, then query by path; the value comes back through STATUS and
READ like any other bytes:

#asmp("        FNBEGIN DVNET, NCPARSR, 2 ; SET_PARSER: JSON
        LODI,R2 0
        BSTA,UN FNPARB          ; ignored, but it must be there
        LODI,R2 NPJSON
        BSTA,UN FNPARB          ; the parser
        BSTA,UN FNGO
        BCFA,EQ FAIL
        FNBEGIN DVNET, NCPARSE, 0 ; PARSE the whole reply
        BSTA,UN FNGO
        BCFA,EQ FAIL
        FNBEGIN DVNET, NCQUERY, 0 ; QUERY one value
        SETFSTR QPATH           ; \"/0/name\"
        BSTA,UN FNTXSTR
        BSTA,UN FNGO            ; then NSTAT and NREAD
        BCFA,EQ FAIL")

#important[Read the whole of each query’s value before the next QUERY. A
value left half read makes the next queries come back empty.]
