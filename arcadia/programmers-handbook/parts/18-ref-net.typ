#import "../lib.typ": *

= Command Reference: The Network Device <ref-net>

Every command devices `$71-$78` answer, checked against the network device
every FujiNet shares, `NDevice.cpp`. Most of the codes are the ASCII letter
of their name, `'O'`pen, `'R'`ead, `'W'`rite, a habit from the Atari 8-bits.
What a devicespec can say, and how each protocol behaves, belongs to _The
FujiNet Network Protocol Handbook_; these are the cards. A READ’s answer
must fit the 1,024-byte reply, seen 256 bytes at a time, and a WRITE’s bytes
the 320-byte TX stream with the parameter in front of them.

The cartridge gives each OPEN, STATUS, READ and CLOSE 90 seconds, and `FNGO`
waits that long. The examples use channel 1, `DVNET` (`$71`); `netlib.inc`
has all five of the lifecycle as routines.

== The lifecycle

#cmd("NET_OPEN", code: "$4F 'O'", dev: "$71", nparam: "2",
  params: [bytes: mode (4 read, 8 write, 12 read and write, 13 POST), translation (0 none, 1 CR, 2 LF, 3 CR LF)],
  payload: [the devicespec, `N:` and the URL],
  reply: [ACK once the connection is set up],
  asm: "        FNBEGIN DVNET, NCOPEN, 2
        LODI,R2 NMRDWR          ; 12
        BSTA,UN FNPARB
        LODI,R2 NTRNONE
        BSTA,UN FNPARB
        SETFSTR URL             ; as long as it is
        BSTA,UN FNTXSTR
        BSTA,UN FNGO
        BCFA,EQ FAIL",
  [On HTTP, modes 4 and 12 are both GET; 12 also lets a program set headers
   (NET_SET_HTTP_MODE). The request itself waits for the first STATUS or
   READ. Other HTTP modes: 14 PUT with headers, 5 and 9 DELETE. On TCP, mode
   12 is a socket both ways, as NetCat uses it. Opening a channel that is
   already open closes the old connection first.])

#cmd("NET_STATUS", code: "$53 'S'", dev: "$71", nparam: "2",
  params: [two bytes of 0],
  reply: [4 bytes: bytes waiting (word), connected, status (1 good, 136 end of file)],
  asm: "        FNBEGIN DVNET, NCSTAT, 2
        LODI,R2 0
        BSTA,UN FNPARB
        LODI,R2 0
        BSTA,UN FNPARB
        BSTA,UN FNGO
        BCFA,EQ FAIL
        LODA,R0 *FRDP           ; bytes waiting, low...
        LODI,R1 1
        IORA,R0 *FRDP,R1        ; ...or high
        BCTA,EQ DONE            ; nothing yet",
  [The heartbeat. A terminal watches _connected_; a program that fetches and
   shows watches the status for the end of the file; every program reads the
   count, until two readings agree (Section 11). Copy the four bytes before
   the next transaction, as `NSTAT` does.])

#cmd("NET_READ", code: "$52 'R'", dev: "$71", nparam: "1",
  params: [*one word*: how many bytes, no more than are waiting and no more than 1,024],
  reply: [that many bytes],
  asm: "        FNBEGIN DVNET, NCREAD, 1
        LODI,R2 128             ; 128 bytes
        LODI,R3 0
        BSTA,UN FNPARW
        BSTA,UN FNGO            ; RXLEN bytes at $2B00
        BCFA,EQ FAIL",
  [A short or failed read is a NAK. Use the bytes, or copy them, before the
   next transaction paints over the window; past the first 256, `FNSLICE`.])

#cmd("NET_WRITE", code: "$57 'W'", dev: "$71", nparam: "1",
  params: [word: how many bytes],
  payload: [that many bytes],
  reply: [ACK],
  asm: "        FNBEGIN DVNET, NCWRITE, 1
        LODI,R2 5
        LODI,R3 0
        BSTA,UN FNPARW          ; the count...
        SETFSTR DATA            ; ...and the bytes
        LODI,R2 5
        BSTA,UN FNTXN
        BSTA,UN FNGO
        BCFA,EQ FAIL",
  [The count goes twice: as the parameter, and as the length of the
   payload. The parameter’s three bytes leave 317 for the data in one
   transaction.])

#cmd("NET_CLOSE", code: "$43 'C'", dev: "$71", nparam: "0",
  reply: [ACK],
  asm: "        FNBEGIN DVNET, NCCLOSE, 0
        BSTA,UN FNGO",
  [Close every connection you open, on the way out of a failure too; the
   adapter keeps it open otherwise, even after the console is switched
   off.])

== Parsers, parameters and line endings

#cmd("NET_SET_PARSER / NET_PARSE / NET_QUERY", code: "$FC / $50 'P' / $51 'Q'", dev: "$71", nparam: "2 / 0 / 0",
  params: [SET_PARSER: byte (any), then the parser: 0 none, 1 JSON, 2 HTML, 3 XML],
  payload: [QUERY: the path, such as `/0/name`],
  reply: [QUERY: ACK; then STATUS and READ the value as text],
  [Switch an open connection to one of the adapter’s parsers (the parser is
   the *second* parameter), parse the body, then ask for one value by its
   path. Section 11 has the three in a row. Read each value to its end
   before the next QUERY.])

#cmd("NET_SET_PARAMETER", code: "$FB", dev: "$71", nparam: "2",
  params: [bytes: which (0 the query flags, 1 the line ending), the value],
  reply: [ACK],
  [How the parser answers a query: flags remap characters and choose the
   output form; the line ending is the byte that ends each value.])

#cmd("NET_SET_HTTP_MODE", code: "$4D 'M'", dev: "$71", nparam: "2",
  params: [byte (any), then the mode: 0 body, 1 collect headers, 2 get headers, 3 set headers, 4 POST data],
  reply: [ACK; NAK on a connection that is not HTTP],
  asm: "        FNBEGIN DVNET, NCHTTPM, 2
        LODI,R2 0
        BSTA,UN FNPARB
        LODI,R2 3               ; WRITE sets headers
        BSTA,UN FNPARB
        BSTA,UN FNGO
        BCFA,EQ FAIL",
  [HTTP only. In mode 3 each WRITE sets a request header; in mode 4 a WRITE
   supplies the body of a POST; in mode 2 a READ returns the headers
   collected in mode 1. Mode 0 is the page itself. Open with mode 12 to use
   it.])

#cmd("NET_SEEK / NET_TELL", code: "$25 '%' / $26 '&'", dev: "$71", nparam: "1 / 0",
  params: [SEEK: *one four-byte parameter*, the offset], reply: [TELL: 4 bytes, the position],
  [Random access where the protocol has it: TNFS and other files, HTTP
   ranges. The libraries have no four-byte helper: append a 4, then the
   four bytes, low first, each with `LODA,R0 *FTXP,R1`.])

#cmd("NET_TRANSLATION / NET_SET_EOL / NET_SET_INT_RATE", code: "$54 'T' / $4C 'L' / $5A 'Z'", dev: "$71", nparam: "2 / 0 / 1",
  params: [TRANSLATION: byte (any), then the code; SET_INT_RATE: the rate],
  payload: [SET_EOL: the line ending, as a string; empty restores the default],
  reply: [ACK],
  [Line-ending translation and terminators after OPEN. SET_INT_RATE paces an
   interrupt line on computers that have one; the cartridge has no such
   line, so the command is accepted and does nothing. Polling ACKSEQ is the
   only way an Arcadia program learns a transaction is done.])

== Files, sockets and credentials

#cmd("RENAME / DELETE / LOCK / UNLOCK / MKDIR / RMDIR", code: "$20 / $21 / $23 / $24 / $2A / $2B", dev: "$71", nparam: "2",
  params: [bytes: mode (4), and 0],
  payload: [the devicespec; RENAME: `N:…/old,new`],
  reply: [ACK],
  [File operations on the protocols that have files: TNFS, FTP, SMB and the
   memory card. Each opens a connection just for itself and closes it
   again.])

#cmd("NET_CHDIR / NET_GETCWD", code: "$2C / $30", dev: "$71", nparam: "0",
  payload: [CHDIR: the path: absolute, relative, `..`, or a whole new `SCHEME://host/`],
  reply: [GETCWD: the prefix],
  [A working directory for the channel, put in front of every devicespec
   that does not name its own host.])

#cmd("NET_ACCEPT / NET_CLOSE_CLIENT", code: "$41 'A' / $63 'c'", dev: "$71", nparam: "0",
  reply: [ACK],
  [For a TCP server: a channel opened on `N:TCP://:port/` listens; ACCEPT
   takes the waiting client, and CLOSE_CLIENT hangs up on that client while
   the channel keeps listening. An ARCADIA-2001 can be the bulletin board.])

#cmd("NET_GET_REMOTE / NET_SET_DESTINATION / NET_USERNAME / NET_PASSWORD", code: "$72 'r' / $44 'D' / $FD / $FE", dev: "$71", nparam: "0",
  payload: [SET_DESTINATION: `host:port`; USERNAME and PASSWORD: the credential],
  reply: [GET_REMOTE: who sent the last UDP datagram],
  [UDP’s "who said that" and "talk to them instead", and credentials for
   protocols that log in (FTP, SMB and others). Send the credentials before
   the OPEN.])

== Answered with a NAK on this build

In `fujiCommandID.h` but not in the network device’s table:
NET_GET_DSTATS_VALUE (`$FF`), NET_SET_UNIT (`$FA`), NET_SET_HSIO_INDEX
(`$E3`), NET_QUERY_ALT and NET_PARSE_ALT (`$81`, `$80`), NET_GET_ERROR (`$45`;
STATUS’s fourth byte says what went wrong), and NET_HSIO_INDEX (`$3F`).
