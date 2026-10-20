#import "../lib.typ": *
= Command Reference: The Network Device

#ini[E]very command devices `$71`–`$78` answer, checked against the network device every FujiNet shares, `NDevice.cpp`. Most of the codes are the ASCII letter of their name — `'O'`pen, `'R'`ead, `'W'`rite — a habit from the Atari 8-bits. What a devicespec can say, and how each protocol behaves, belongs to _The FujiNet Network Protocol Handbook_; these are the cards. A READ’s answer must fit the 1K reply window, and a WRITE’s bytes the 320-byte TX stream with the parameter in front of them.

The assembly examples use `netdefs.inc`’s names; the C examples, fujinet-lib’s network calls, which take the devicespec every time; the BASIC examples, `FN_NET` (`$71`). Each network command may take the cartridge 90 seconds, so the examples raise the timeout.

#sect[The lifecycle]

#cmd("NET_OPEN", code: "$4F 'O'", dev: "$71", nparam: "2",
  params: [bytes: mode (4 read, 8 write, 12 read and write, 13 POST), translation (0 none, 1 CR, 2 LF, 3 CR LF)],
  payload: [the devicespec, `N:` and the URL],
  reply: [ACK once the connection is set up],
  asm: "        FNBEGIN NETDEV, NCOPEN, 2
        lda     #NMHTTPG
        jsr     fn_pb
        lda     #NTRNONE
        jsr     fn_pb
        ldy     #0
@url:   lda     url,y           ; the devicespec, as long as it is
        beq     @go
        jsr     fn_txb
        iny
        bne     @url
@go:    lda     #130
        sta     FN_TMO
        jsr     fn_go",
  c: "if (network_open(url, OPEN_MODE_HTTP_GET_H, OPEN_TRANS_NONE) != FN_ERR_OK)
    failed();",
  bas: " fn_dev = FN_NET : fn_cmd = $4F : fn_npr = 2
 gosub fn_beg
 fn_val = 12 : gosub fn_pb
 fn_val = 0 : gosub fn_pb
 last = url_length - 1
 for ix = 0 to last : FN_TX = url[ix] : next
 fn_tmo = 22
 gosub fn_go",
  [On HTTP, modes 4 and 12 are both GET; 12 also lets a program set headers (NET_SET_HTTP_MODE). The request itself waits for the first STATUS or READ. Other HTTP modes: 14 PUT with headers, 5 and 9 DELETE. Opening a channel that is already open closes the old connection first.])

#cmd("NET_STATUS", code: "$53 'S'", dev: "$71", nparam: "2",
  params: [two bytes of 0],
  reply: [4 bytes: bytes waiting (word), connected, status (1 good, 136 end of file)],
  asm: "        FNBEGIN NETDEV, NCSTAT, 2
        lda     #0
        jsr     fn_pb
        lda     #0
        jsr     fn_pb
        lda     #130
        sta     FN_TMO
        jsr     fn_go
        bne     failed
        lda     FN_REPLY+NSAVLO ; bytes waiting
        ora     FN_REPLY+NSAVHI
        beq     done            ; nothing yet",
  c: "if (network_status(url, &n, &count, &err) != FN_ERR_OK)
    failed();                    /* n waiting, count connected */",
  bas: " fn_dev = FN_NET : fn_cmd = $53 : fn_npr = 2
 gosub fn_beg
 fn_val = 0 : gosub fn_pb : gosub fn_pb
 fn_tmo = 22
 gosub fn_go
 avail = FN_REPLY[0]",
  [The heartbeat. A terminal watches _connected_; a program that fetches and shows watches the status for end of file; every program reads the count, until two readings agree (Section 11).])

#cmd("NET_READ", code: "$52 'R'", dev: "$71", nparam: "1",
  params: [*one word*: how many bytes, no more than are waiting and no more than 1024],
  reply: [that many bytes],
  asm: "        FNBEGIN NETDEV, NCREAD, 1
        lda     #<256           ; 256 bytes
        ldx     #>256
        jsr     fn_pw
        lda     #130
        sta     FN_TMO
        jsr     fn_go           ; the bytes at FN_REPLY, FN_RXLEN of them",
  c: "got = network_read(url, buf, 256);
if (got < 0)
    failed();",
  bas: " fn_dev = FN_NET : fn_cmd = $52 : fn_npr = 1
 gosub fn_beg
 fn_val = avail : fn_valhi = 0 : gosub fn_pw
 fn_tmo = 22
 gosub fn_go",
  [A short or failed read is a NAK. Use the bytes, or copy them, before the next transaction paints over the window. fujinet-lib’s `network_read()` does the STATUS loop itself and returns how many it read; `network_read_nb()` reads only what is waiting.])

#cmd("NET_WRITE", code: "$57 'W'", dev: "$71", nparam: "1",
  params: [word: how many bytes],
  payload: [that many bytes],
  reply: [ACK],
  asm: "        FNBEGIN NETDEV, NCWRITE, 1
        lda     #dataend-data
        ldx     #0
        jsr     fn_pw
        ldy     #0
@w:     lda     data,y
        jsr     fn_txb
        iny
        cpy     #dataend-data
        bne     @w
        jsr     fn_go",
  c: "if (network_write(url, data, 5) != FN_ERR_OK)
    failed();",
  bas: " fn_dev = FN_NET : fn_cmd = $57 : fn_npr = 1
 gosub fn_beg
 fn_val = value_length : fn_valhi = 0 : gosub fn_pw
 last = value_length - 1
 for ix = 0 to last : FN_TX = value[ix] : next
 gosub fn_go",
  [The count goes twice: as the parameter, and as the length of the payload. The two parameter bytes and the count leave 317 bytes for the data in one transaction.])

#cmd("NET_CLOSE", code: "$43 'C'", dev: "$71", nparam: "0",
  reply: [ACK],
  asm: "        FNBEGIN NETDEV, NCCLOSE, 0
        lda     #130
        sta     FN_TMO
        jsr     fn_go",
  c: "network_close(url);",
  bas: " fn_dev = FN_NET : fn_cmd = $43 : fn_npr = 0
 gosub fn_beg
 fn_tmo = 22
 gosub fn_go",
  [Close every connection you open, including on the way out of a failure; the adapter keeps it open otherwise, even across a power cycle of the console.])

#sect[Parsers, parameters and line endings]

#cmd("NET_SET_PARSER / NET_PARSE / NET_QUERY", code: "$FC / $50 'P' / $51 'Q'", dev: "$71", nparam: "2 / 0 / 0",
  params: [SET_PARSER: byte (any), then the parser: 0 none, 1 JSON, 2 HTML, 3 XML],
  payload: [QUERY: the path, such as `/0/name`],
  reply: [QUERY: ACK; then STATUS and READ the value as text],
  asm: "        FNBEGIN NETDEV, NCPRSR, 2   ; JSON
        lda     #0
        jsr     fn_pb
        lda     #NPJSON
        jsr     fn_pb
        jsr     fn_go
        FNBEGIN NETDEV, NCPARSE, 0  ; parse what was fetched
        jsr     fn_go
        FNBEGIN NETDEV, NCQUERY, 0  ; ask for one value
        ldy     #0
@q:     lda     query,y
        beq     @go
        jsr     fn_txb
        iny
        bne     @q
@go:    jsr     fn_go           ; then STATUS and READ it",
  c: "if (network_json_parse(url) != FN_ERR_OK)
    failed();
got = network_json_query(url, query, (char *)buf);
if (got < 0)
    failed();",
  bas: " fn_dev = FN_NET : fn_cmd = $FC : fn_npr = 2
 gosub fn_beg
 fn_val = 0 : gosub fn_pb
 fn_val = 1 : gosub fn_pb
 gosub fn_go
 fn_cmd = $50 : fn_npr = 0 : gosub fn_beg
 gosub fn_go
 fn_cmd = $51 : gosub fn_beg
 last = query_length - 1
 for ix = 0 to last : FN_TX = query[ix] : next
 gosub fn_go",
  [Switch an open connection to one of the adapter’s parsers (the parser is the *second* parameter), parse the body, then ask for one value by its path. fujinet-lib’s `network_json_parse()` sets the parser and parses in one call, and `network_json_query()` does the query, STATUS and READ.])

#cmd("NET_SET_PARAMETER", code: "$FB", dev: "$71", nparam: "2",
  params: [bytes: which (0 the query flags, 1 the line ending), the value],
  reply: [ACK],
  [How the parser answers a query: flags remap characters and choose the output form; the line ending is the byte that ends each value. In C: `network_set_query_param()` and `network_set_line_ending()`.])

#cmd("NET_SET_HTTP_MODE", code: "$4D 'M'", dev: "$71", nparam: "2",
  params: [byte (any), then the mode: 0 body, 1 collect headers, 2 get headers, 3 set headers, 4 POST data],
  reply: [ACK; NAK on a connection that is not HTTP],
  asm: "        FNBEGIN NETDEV, NCHTTPM, 2  ; from now, WRITE sets headers
        lda     #0
        jsr     fn_pb
        lda     #3
        jsr     fn_pb
        jsr     fn_go",
  c: "network_http_start_add_headers(url);
network_http_add_header(url, \"Accept: text/plain\");
network_http_end_add_headers(url);",
  bas: " fn_dev = FN_NET : fn_cmd = $4D : fn_npr = 2
 gosub fn_beg
 fn_val = 0 : gosub fn_pb
 fn_val = 3 : gosub fn_pb
 gosub fn_go",
  [HTTP only. In mode 3 each WRITE sets a request header; in mode 4 a WRITE supplies the body of a POST; in mode 2 a READ returns the headers collected in mode 1. Mode 0 is the page itself. Open with mode 12 to use it.])

#cmd("NET_SEEK / NET_TELL", code: "$25 '%' / $26 '&'", dev: "$71", nparam: "1 / 0",
  params: [SEEK: *one four-byte parameter*, the offset], reply: [TELL: 4 bytes, the position],
  [Random access where the protocol has it: TNFS and other files, HTTP ranges. In C: `network_seek()` and `network_tell()`.])

#cmd("NET_TRANSLATION / NET_SET_EOL / NET_SET_INT_RATE", code: "$54 'T' / $4C 'L' / $5A 'Z'", dev: "$71", nparam: "2 / 0 / 1",
  params: [TRANSLATION: byte (any), then the code; SET_INT_RATE: the rate],
  payload: [SET_EOL: the line ending, as a string; empty restores the default],
  reply: [ACK],
  [Line-ending translation and terminators after OPEN. SET_INT_RATE paces an interrupt line on computers that have one; the cartridge has no such line, so the command is accepted and does nothing. Polling `ACKSEQ` is the only way a 7800 program learns a transaction is done.])

#sect[Files, sockets and credentials]

#cmd("RENAME / DELETE / LOCK / UNLOCK / MKDIR / RMDIR", code: "$20 / $21 / $23 / $24 / $2A / $2B", dev: "$71", nparam: "2",
  params: [bytes: mode (4), and 0],
  payload: [the devicespec; RENAME: `N:…/old,new`],
  reply: [ACK],
  [File operations on the protocols that have files: TNFS, FTP, SMB and the SD card. Each one opens a connection just for itself and closes it again. In C: `network_fs_rename()` and the rest.])

#cmd("NET_CHDIR / NET_GETCWD", code: "$2C / $30", dev: "$71", nparam: "0",
  payload: [CHDIR: the path: absolute, relative, `..`, or a whole new `SCHEME://host/`],
  reply: [GETCWD: the prefix],
  [A working directory for the channel, put in front of every devicespec that does not name its own host.])

#cmd("NET_ACCEPT / NET_CLOSE_CLIENT", code: "$41 'A' / $63 'c'", dev: "$71", nparam: "0",
  reply: [ACK],
  [For a TCP server: a channel opened on `N:TCP://:port/` listens; ACCEPT takes the waiting client, and CLOSE_CLIENT hangs up on that client while the channel keeps listening. A 7800 can be the bulletin board.])

#cmd("NET_GET_REMOTE / NET_SET_DESTINATION / NET_USERNAME / NET_PASSWORD", code: "$72 'r' / $44 'D' / $FD / $FE", dev: "$71", nparam: "0",
  payload: [SET_DESTINATION: `host:port`; USERNAME and PASSWORD: the credential],
  reply: [GET_REMOTE: who sent the last UDP datagram],
  [UDP’s “who said that” and “talk to them instead”, and credentials for protocols that log in (FTP, SMB and others). Send the credentials before the OPEN.])

#sect[Answered with a NAK on this build]

In `fujiCommandID.h` but not in the network device’s table: `NET_GET_DSTATS_VALUE` (`$FF`), `NET_SET_UNIT` (`$FA`), `NET_SET_HSIO_INDEX` (`$E3`), `NET_QUERY_ALT` and `NET_PARSE_ALT` (`$81`, `$80`), `NET_GET_ERROR` (`$45`; STATUS’s fourth byte says what went wrong), and `NET_HSIO_INDEX` (`$3F`).
