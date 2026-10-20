#import "../lib.typ": *

#opener-art.update((sub: [OPEN · STATUS · READ · CLOSE],
  art: tvrow("netget", w: 1.6in)))
= The Network Device <network>

The FujiNet has eight network channels, devices `$71` to `$78`. Each can hold one connection: an HTTP request, a TCP socket, a file on a TNFS or FTP server, a UDP conversation. The URL says which, and the channel does the rest; a Studio II program only opens, asks, reads, writes and closes.

== The lifecycle

#nsteps(
  [*OPEN* (`$4F`): two one-byte parameters, the mode and the translation, then the devicespec as the payload: `N:` and the URL.],
  [*STATUS* (`$53`): two parameters of 0. Four bytes come back: how many bytes are waiting (two), whether the connection is up, and an error code.],
  [*READ* (`$52`): one two-byte parameter, the count. The bytes arrive in the reply window.],
  [*WRITE* (`$57`): one two-byte parameter, the count, then that many bytes.],
  [*CLOSE* (`$43`): no parameters.],
)

Every one of them can take a while: the cartridge gives a network channel 90 seconds, so a program raises its own wait to 95 with `SLOW` after each `FNBEGIN`.

== Fetching a file

`netget.asm` fetches a small text file over HTTP and shows it. The URL is the bench’s; `build.sh` writes it into `build/gen/bookcfg.inc`, so the program carries no address of its own.

#excerpt-at(auto, "listings/asm/netget.asm", "open:   FNBEGIN NETDEV, NCOPEN, 2", to: "; ---- STATUS")

Mode 4 is a read: on HTTP, a GET. Translation 0 leaves the bytes alone; 1, 2 and 3 turn the line endings into CR, LF or CR LF. The devicespec goes as the payload at its own length, with `fn_str`.

== How much is there?

The adapter answers OPEN as soon as the connection is made, which can be before the whole reply has arrived. STATUS says how many bytes are waiting so far; `netget` asks until two answers agree and are not zero, three frames apart:

#excerpt-at(auto, "listings/asm/netget.asm", "stat1:  FNBEGIN NETDEV, NCSTAT, 2", n: 11)

Then READ takes them, at most 128 here: the reply window holds 1024.

#excerpt-at(auto, "listings/asm/netget.asm", "rd2:    GLO     R8", to: "; ---- show it")

== Showing it

The bytes are in the reply window, RXLEN of them. `netget` walks them with RA and LDA: a CR is skipped, an LF moves to the next row, anything else is drawn.

#excerpt-at(auto, "listings/asm/netget.asm", "show:   LDR     RA, FN_REPLY", to: "close:  FJMP")

#note[`d_putc` wraps at the 16th column by itself, so a long line runs on to the next row; `netget` moves down one more at its LF. The bench’s file has short lines.]

== JSON

The adapter can parse what it fetched and answer one value at a time, so a program never holds a whole JSON document. Set the parser on the open channel, parse, then query by path; the value comes back through STATUS and READ like any other bytes:

#asmp("        FNBEGIN NETDEV, NCPRSR, 2   ; JSON
        LDI     0
        FCALL   fn_pb
        LDI     NPJSON
        FCALL   fn_pb
        GOACK
        FNBEGIN NETDEV, NCPARSE, 0  ; parse it
        SLOW    95
        GOACK
        FNBEGIN NETDEV, NCQUERY, 0  ; one value
        LDR     R8, query           ; \"/0/name\"
        FCALL   fn_str
        GOACK                       ; then STATUS, READ")

The parser is the *second* parameter of SET_PARSER; the first is ignored.

== Closing

#excerpt-at(auto, "listings/asm/netget.asm", "close1: FNBEGIN NETDEV, NCCLOSE, 0", n: 4)

Close every channel you open, on the way out of a failure too: the adapter keeps a connection open otherwise, even after the console is turned off.
