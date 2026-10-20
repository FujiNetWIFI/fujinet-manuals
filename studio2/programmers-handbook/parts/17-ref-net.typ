#import "../lib.typ": *
#set page(columns: 1)
#refpage.update(true)

= Command Reference: The Network Device <ref-net>

#hang([], [Every command devices `$71`–`$78` answer, checked against the network device every FujiNet shares, `NDevice.cpp`. Most of the codes are the ASCII letter of their name, `'O'`pen, `'R'`ead, `'W'`rite, a habit from the Atari 8-bits. What a devicespec can say, and how each protocol behaves, belongs to _The FujiNet Network Protocol Handbook_; these are the cards. A READ’s answer must fit the 1K reply window, and a WRITE’s bytes the 320-byte TX stream with the parameter in front of them.

Each network command may take the cartridge 90 seconds, so the examples raise the wait with `SLOW 95`. They use channel 1, `NETDEV` (`$71`).])

#sect[The lifecycle]

#cmd("NET_OPEN", code: "$4F 'O'", dev: "$71", nparam: "2",
  params: [bytes: mode (4 read, 8 write, 12 read and write, 13 POST), translation (0 none, 1 CR, 2 LF, 3 CR LF)],
  payload: [the devicespec, `N:` and the URL],
  reply: [ACK once the connection is set up],
  asm: "        FNBEGIN NETDEV, NCOPEN, 2
        LDI     NMHTTPG         ; 12
        FCALL   fn_pb
        LDI     NTRNONE
        FCALL   fn_pb
        LDR     R8, url         ; as long as it is
        FCALL   fn_str
        SLOW    95
        GOACK",
  [On HTTP, modes 4 and 12 are both GET; 12 also lets a program set headers (NET_SET_HTTP_MODE). The request itself waits for the first STATUS or READ. Other HTTP modes: 14 PUT with headers, 5 and 9 DELETE. On TCP, mode 12 is a socket both ways, as the netcat uses it. Opening a channel that is already open closes the old connection first.])

#cmd("NET_STATUS", code: "$53 'S'", dev: "$71", nparam: "2",
  params: [two bytes of 0],
  reply: [4 bytes: bytes waiting (word), connected, status (1 good, 136 end of file)],
  asm: "        FNBEGIN NETDEV, NCSTAT, 2
        LDI     0
        FCALL   fn_pb
        LDI     0
        FCALL   fn_pb
        SLOW    95
        GOACK
        PEEK    FN_REPLY+NSAVLO ; bytes waiting
        STR     R2
        PEEK    FN_REPLY+NSAVHI
        OR
        BZ      done            ; nothing yet",
  [The heartbeat. A terminal watches _connected_; a program that fetches and shows watches the status for end of file; every program reads the count, until two readings agree (The Network Device).])

#cmd("NET_READ", code: "$52 'R'", dev: "$71", nparam: "1",
  params: [*one word*: how many bytes, no more than are waiting and no more than 1024],
  reply: [that many bytes],
  asm: "        FNBEGIN NETDEV, NCREAD, 1
        LDR     R8, 128         ; 128 bytes
        FCALL   fn_pw
        SLOW    95
        GOACK                   ; RXLEN bytes at $E400",
  [A short or failed read is a NAK. Use the bytes, or copy them, before the next transaction paints over the window.])

#cmd("NET_WRITE", code: "$57 'W'", dev: "$71", nparam: "1",
  params: [word: how many bytes],
  payload: [that many bytes],
  reply: [ACK],
  asm: "        FNBEGIN NETDEV, NCWRITE, 1
        LDR     R8, 5
        FCALL   fn_pw           ; the count...
        LDR     R8, data        ; ...and the bytes
        FCALL   fn_str
        SLOW    95
        GOACK",
  [The count goes twice: as the parameter, and as the length of the payload. The two parameter bytes and the count leave 317 bytes for the data in one transaction.])

#cmd("NET_CLOSE", code: "$43 'C'", dev: "$71", nparam: "0",
  reply: [ACK],
  asm: "        FNBEGIN NETDEV, NCCLOSE, 0
        SLOW    95
        GOACK",
  [Close every connection you open, including on the way out of a failure; the adapter keeps it open otherwise, even after the console is turned off.])

#sect[Parsers, parameters and line endings]

#cmd("NET_SET_PARSER / NET_PARSE / NET_QUERY", code: "$FC / $50 'P' / $51 'Q'", dev: "$71", nparam: "2 / 0 / 0",
  params: [SET_PARSER: byte (any), then the parser: 0 none, 1 JSON, 2 HTML, 3 XML],
  payload: [QUERY: the path, such as `/0/name`],
  reply: [QUERY: ACK; then STATUS and READ the value as text],
  asm: "        FNBEGIN NETDEV, NCPRSR, 2
        LDI     0
        FCALL   fn_pb
        LDI     NPJSON          ; the second one
        FCALL   fn_pb
        GOACK
        FNBEGIN NETDEV, NCPARSE, 0
        SLOW    95
        GOACK
        FNBEGIN NETDEV, NCQUERY, 0
        LDR     R8, query
        FCALL   fn_str
        GOACK                   ; then STATUS, READ",
  [Switch an open connection to one of the adapter’s parsers (the parser is the *second* parameter), parse the body, then ask for one value by its path.])

#cmd("NET_SET_PARAMETER", code: "$FB", dev: "$71", nparam: "2",
  params: [bytes: which (0 the query flags, 1 the line ending), the value],
  reply: [ACK],
  [How the parser answers a query: flags remap characters and choose the output form; the line ending is the byte that ends each value.])

#cmd("NET_SET_HTTP_MODE", code: "$4D 'M'", dev: "$71", nparam: "2",
  params: [byte (any), then the mode: 0 body, 1 collect headers, 2 get headers, 3 set headers, 4 POST data],
  reply: [ACK; NAK on a connection that is not HTTP],
  asm: "        FNBEGIN NETDEV, NCHTTPM, 2
        LDI     0
        FCALL   fn_pb
        LDI     3               ; WRITE sets headers
        FCALL   fn_pb
        GOACK",
  [HTTP only. In mode 3 each WRITE sets a request header; in mode 4 a WRITE supplies the body of a POST; in mode 2 a READ returns the headers collected in mode 1. Mode 0 is the page itself. Open with mode 12 to use it.])

#cmd("NET_SEEK / NET_TELL", code: "$25 '%' / $26 '&'", dev: "$71", nparam: "1 / 0",
  params: [SEEK: *one four-byte parameter*, the offset], reply: [TELL: 4 bytes, the position],
  [Random access where the protocol has it: TNFS and other files, HTTP ranges. The runtime has no four-byte helper: stream a 4 with `fn_txb`, then the four bytes, low first.])

#cmd("NET_TRANSLATION / NET_SET_EOL / NET_SET_INT_RATE", code: "$54 'T' / $4C 'L' / $5A 'Z'", dev: "$71", nparam: "2 / 0 / 1",
  params: [TRANSLATION: byte (any), then the code; SET_INT_RATE: the rate],
  payload: [SET_EOL: the line ending, as a string; empty restores the default],
  reply: [ACK],
  [Line-ending translation and terminators after OPEN. SET_INT_RATE paces an interrupt line on computers that have one; the cartridge has no such line, so the command is accepted and does nothing. Polling ACKSEQ is the only way a Studio II program learns a transaction is done.])

#sect[Files, sockets and credentials]

#cmd("RENAME / DELETE / LOCK / UNLOCK / MKDIR / RMDIR", code: "$20 / $21 / $23 / $24 / $2A / $2B", dev: "$71", nparam: "2",
  params: [bytes: mode (4), and 0],
  payload: [the devicespec; RENAME: `N:…/old,new`],
  reply: [ACK],
  [File operations on the protocols that have files: TNFS, FTP, SMB and the SD card. Each one opens a connection just for itself and closes it again.])

#cmd("NET_CHDIR / NET_GETCWD", code: "$2C / $30", dev: "$71", nparam: "0",
  payload: [CHDIR: the path: absolute, relative, `..`, or a whole new `SCHEME://host/`],
  reply: [GETCWD: the prefix],
  [A working directory for the channel, put in front of every devicespec that does not name its own host.])

#cmd("NET_ACCEPT / NET_CLOSE_CLIENT", code: "$41 'A' / $63 'c'", dev: "$71", nparam: "0",
  reply: [ACK],
  [For a TCP server: a channel opened on `N:TCP://:port/` listens; ACCEPT takes the waiting client, and CLOSE_CLIENT hangs up on that client while the channel keeps listening. A Studio II can be the bulletin board.])

#cmd("NET_GET_REMOTE / NET_SET_DESTINATION / NET_USERNAME / NET_PASSWORD", code: "$72 'r' / $44 'D' / $FD / $FE", dev: "$71", nparam: "0",
  payload: [SET_DESTINATION: `host:port`; USERNAME and PASSWORD: the credential],
  reply: [GET_REMOTE: who sent the last UDP datagram],
  [UDP’s “who said that” and “talk to them instead”, and credentials for protocols that log in (FTP, SMB and others). Send the credentials before the OPEN.])

#sect[Answered with a NAK on this build]

#hang([], [In `fujiCommandID.h` but not in the network device’s table: `NET_GET_DSTATS_VALUE` (`$FF`), `NET_SET_UNIT` (`$FA`), `NET_SET_HSIO_INDEX` (`$E3`), `NET_QUERY_ALT` and `NET_PARSE_ALT` (`$81`, `$80`), `NET_GET_ERROR` (`$45`; STATUS’s fourth byte says what went wrong), and `NET_HSIO_INDEX` (`$3F`).])

#refpage.update(false)
