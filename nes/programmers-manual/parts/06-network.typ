#import "../lib.typ": *

= The Network Device

#lead[Eight network channels, N1: to N8:, each able to hold one open
connection to anything the FujiNet speaks -- a web page, a TCP socket, a
file on a TNFS server.]

== The life of a connection

The network channels are FujiBus devices `$71` to `$78`. N1: is `$71`. A
connection goes through five commands, always in this order:

#runin(
  ("OPEN", [names the thing to connect to, as a URL with an `N:` in front:
   `N:HTTP://example.com/file.txt`, `N:TCP://bbs.example.com:23/`,
   `N:TNFS://host/path`. OPEN closes whatever the channel had open before.]),
  ("STATUS", [says how many bytes are waiting to be read, whether the
   connection is still up, and the last error. For HTTP, the first STATUS is
   what actually sends the request.]),
  ("READ", [takes up to the number of bytes you ask for -- at most 1024, the
   size of the reply window.]),
  ("WRITE", [sends bytes -- at most 317 in one transaction on the NES.]),
  ("CLOSE", [hangs up.]),
)

A file is over when STATUS says nothing is waiting and its error byte says
136, END OF FILE. A TCP connection is over when STATUS says it is no longer
connected and nothing is waiting.

== Reading a file

Serve the two fixtures in `listings/fixture/` with any web server --
`python3 -m http.server 8765` in that directory will do -- and run `netget`:

#wholefile("listings/c/netget.c", "listings/c/netget.c")

`network_read()` loops inside the library, asking STATUS and READ until it
has the bytes it was asked for or the file has ended. In assembly the loop is
yours:

#excerpt-at("listings/asm/netget.s: the read loop", "listings/asm/netget.s",
  "next:   CALL", to: "eof:    CALL", size: 6.8pt)

Asking for no more than 255 bytes at a time keeps the whole reply within
reach of one index register. The bytes are drawn straight from the window;
a `$0A` moves the PPU cursor to the next line instead.

#shots("netget-c", "netget-asm", caption: [`netget`, C and assembly.])

== A JSON round trip

The FujiNet can parse what it fetches. Open the document, set the channel's
parser to JSON, PARSE, and then each QUERY with a path such as
`/mailbox/base` leaves that one value waiting to be read:

#wholefile("listings/c/json.c", "listings/c/json.c")

#excerpt-at("listings/asm/json.s: one field", "listings/asm/json.s",
  "        CALL    FNDEVN, NCQUERY, 0", to: "skip:   inc", size: 6.8pt)

A value comes back as text, ended by the parser's line ending -- a `$0A`
unless you change it with SET_PARAMETER. Numbers come back as their digits;
`true`, `false` and `null` as `TRUE`, `FALSE` and `NULL`. A path that does
not exist leaves nothing waiting.

#note[The assembly version reads the value's length out of the STATUS reply
*after* it has called `fn_beg` for the READ. That is safe: setting up a
transaction never repaints the window. Only the commit does.]

#shots("json-c", "json-asm", caption: [`json`, C and assembly. The paths are
on the left, the values the FujiNet found for them on the right.])

== Command reference

On every card, *params* are in the order they go into the TX stream, each
with its size in bytes. A parameter is never optional unless the card says
so: a missing one does not earn a NAK, it restarts the FujiNet. The device is
N1:, `$71`; use `$72-$78` for N2: to N8:.

#cmd("Open", dev: "$71", code: "$4F 'O'",
  params: [mode (1): 4 read / HTTP GET, 6 directory, 8 write / HTTP PUT,
    9 append, 12 read-write / HTTP GET with headers, 13 HTTP POST, 5 HTTP
    DELETE. trans (1): 0 none, 1 CR, 2 LF, 3 CRLF, 4 PETSCII.],
  payload: [The URL, `N:` optional, up to 256 bytes. It ends at a NUL, or at
    CR LF.],
  reply: [none; NAK if the URL is bad or the server refuses. STATUS then says
    why: 165 invalid devicespec, 144 general, or the protocol's own error.],
  asm: "        CALL    FNDEVN, NCOPEN, 2
        lda     #NMREAD         ; mode
        jsr     fn_pb
        lda     #0              ; no translation
        jsr     fn_pb
        lda     #<url
        sta     fn_ptr
        lda     #>url
        sta     fn_ptr+1
        jsr     fn_str          ; the URL, unpadded
        jsr     fn_go
        jne     fail
        jsr     fn_ack
        jne     fail",
  c: "if (network_open(url, OPEN_MODE_READ,
                 OPEN_TRANS_NONE) != FN_ERR_OK)
  fail();")[
OPEN closes whatever the channel had open. A URL with no scheme is taken
relative to the channel's current directory (CHDIR). The schemes the FujiNet
knows include HTTP, HTTPS, TCP, UDP, TELNET, TNFS, FTP, SMB, NFS, SSH, SFTP,
WS and WSS.]

#cmd("Close", dev: "$71", code: "$43 'C'",
  reply: [none; NAK if the protocol's close failed. Once it has failed, CLOSE
    goes on NAKing until the next OPEN.],
  asm: "        CALL    FNDEVN, NCCLOSE, 0
        jsr     fn_go",
  c: "network_close(url);")[]

#cmd("Status", dev: "$71", code: "$53 'S'",
  reply: [4 bytes: bytes waiting (2, low first, at most 65535), connected
    (1: 1 yes, 0 no), error (1: 1 OK, 136 end of file, others in Appendix
    A). With no connection open: 0, 0, 207.],
  asm: "        CALL    FNDEVN, NCSTAT, 0
        jsr     fn_go
        jne     fail
        lda     FN_RPLY         ; bytes waiting, low
        ldx     FN_RPLY+1       ;   and high
        ldy     FN_RPLY+3       ; the error",
  c: "if (network_status(url, &avail, &conn,
                   &err) != FN_ERR_OK)
  fail();")[
On HTTP the first STATUS after OPEN is what sends the request and waits for
the response headers, so it may take a while.]

#cmd("Read", dev: "$71", code: "$52 'R'",
  params: [count (2), 1 or more.],
  reply: [Up to count bytes; fewer if fewer are waiting. NAK if count is 0,
    nothing is open, or the read failed.],
  asm: "        CALL    FNDEVN, NCREAD, 1
        lda     #<200
        ldx     #>200
        jsr     fn_pw
        jsr     fn_go
        jne     fail
        ; FN_RXLO/FN_RXHI bytes at FN_RPLY",
  c: "/* waits until len bytes or the end */
n16 = network_read(url, buf, 200);
/* one STATUS, then one READ */
n16 = network_read_nb(url, buf, 200);")[
The reply window holds 1024 bytes, so ask for no more than that. fujinet-lib
caps every READ at 1024 for you; `network_read()` keeps going until it has the
whole `len` or the file ends.]

#cmd("Write", dev: "$71", code: "$57 'W'",
  params: [count (2), 1 or more.],
  payload: [count bytes. Short? The rest are sent as zeros.],
  reply: [none; NAK if nothing is open or the write failed.],
  asm: "        CALL    FNDEVN, NCWRITE, 1
        lda     #5              ; count
        ldx     #0
        jsr     fn_pw
        ldx     #0
:       lda     data,x
        jsr     fn_txb
        inx
        cpx     #5
        bne     :-
        jsr     fn_go
        jne     fail",
  c: "if (network_write(url, (uint8_t *) \"HELLO\",
                  5) != FN_ERR_OK)
  fail();")[
The TX stream holds 320 bytes and the count parameter takes three of them,
so one WRITE carries at most 317. `network_write()` splits a longer buffer for
you.]

#cmd("Set parser", dev: "$71", code: "$FC",
  params: [ignored (1), then the parser (1): 0 none, 1 JSON, 2 HTML (CSS
    selectors), 3 XML (a subset of XPath).],
  reply: [none; NAK if the parser number is above 3.],
  asm: "        CALL    FNDEVN, NCPARSER, 2
        lda     #1
        jsr     fn_pb
        lda     #1              ; JSON
        jsr     fn_pb
        jsr     fn_go",
  c: "network_set_parser(url, PARSER_JSON);")[
Sets how PARSE and QUERY treat what the channel is reading. Parser 0 hands the
bytes through untouched, and every QUERY NAKs.]

#cmd("Parse", dev: "$71", code: "$50 'P'",
  reply: [none; NAK if nothing is open or the document would not parse
    (STATUS error 213 for bad JSON).],
  asm: "        CALL    FNDEVN, NCPARSE, 0
        jsr     fn_go
        jne     fail
        jsr     fn_ack
        jne     fail",
  c: "/* SET_PARSER(JSON) then PARSE */
if (network_json_parse(url) != FN_ERR_OK)
  fail();")[
Reads the whole response and parses it. After this the channel can no longer
be written to or seeked.]

#cmd("Query", dev: "$71", code: "$51 'Q'",
  payload: [The path, such as `/players/0/name` for JSON; trailing NULs are
    harmless. An empty path is the whole document.],
  reply: [none; NAK if there is no parser or the path is malformed. STATUS
    then gives the value's length, and READ fetches it.],
  asm: "        CALL    FNDEVN, NCQUERY, 0
        lda     #<path
        sta     fn_ptr
        lda     #>path
        sta     fn_ptr+1
        jsr     fn_str
        jsr     fn_go",
  c: "/* QUERY, then STATUS and READ until done */
n16 = network_json_query(url, \"/name\",
                         (char *) buf);")[]

#cmd("Set parameter", dev: "$71", code: "$FB",
  params: [which (1), value (1). Which 0: the query flags -- `$01` remap
    characters, `$02` remap ATASCII international, `$04` delete SGML tags,
    `$10` plain ASCII. Which 1: the parser's line ending, one character.],
  reply: [none; NAK if no parser is set, or for any other which.],
  asm: "        CALL    FNDEVN, NCPARAM, 2
        lda     #1              ; the line ending
        jsr     fn_pb
        lda     #0              ; NUL instead of LF
        jsr     fn_pb
        jsr     fn_go",
  c: "network_set_line_ending(url, 0);")[]

#cmd("Translation", dev: "$71", code: "$54 'T'",
  params: [ignored (1), translation (1): 0 none, 1 CR, 2 LF, 3 CRLF,
    4 PETSCII, `$FF` force none.],
  asm: "        CALL    FNDEVN, NCTRANS, 2
        lda     #0
        jsr     fn_pb
        lda     #2              ; CR LF -> LF
        jsr     fn_pb
        jsr     fn_go",
  c: "network_set_translation(url,
                        OPEN_TRANS_LF);")[
Overrides the end-of-line translation OPEN asked for. The FujiNet's own line
ending on this bus is CR LF, so with translation 0 nothing changes.]

#cmd("Set EOL", dev: "$71", code: "$4C 'L'",
  payload: [The end-of-line bytes, exactly; empty clears the override.],
  asm: "        CALL    FNDEVN, NCEOL, 0
        lda     #$0A
        jsr     fn_txb
        jsr     fn_go",
  c: "network_set_eol(url, \"\\n\");")[]

#cmd("HTTP channel mode", dev: "$71", code: "$4D 'M'",
  params: [ignored (1), mode (1): 0 body, 1 collect headers, 2 get headers,
    3 set headers, 4 set POST data.],
  reply: [none; NAK if the channel is not HTTP or the mode is above 4.],
  asm: "        CALL    FNDEVN, NCHTTPM, 2
        lda     #0
        jsr     fn_pb
        lda     #4              ; what I WRITE is the body
        jsr     fn_pb
        jsr     fn_go",
  c: "/* OPEN mode 13, then: */
network_http_post(url, \"name=fuji\");")[
A POST goes: OPEN with mode 13, mode 4, WRITE the body, mode 0, then STATUS
and READ the response. Mode 3 lets you WRITE request headers as
`Name: value`; mode 1 lets you WRITE the names of response headers to keep,
and mode 2 READs their values. Each change of mode empties both buffers.]

#cmd("Seek / Tell", dev: "$71", code: "$25 '%' / $26 '&'",
  params: [SEEK: offset (4).],
  reply: [TELL: the position, 4 bytes. With nothing open TELL returns four
    bytes of nonsense, and still ACKs.],
  asm: "        CALL    FNDEVN, NCTELL, 0
        jsr     fn_go
        jne     fail
        lda     FN_RPLY         ; position, low byte",
  c: "network_seek(url, 1024UL);
network_tell(url, &r32);")[]

#cmd("Chdir / Getcwd", dev: "$71", code: "$2C ',' / $30 '0'",
  payload: [CHDIR: the path. `..` or `<` goes up, `/` or `>` to the host's
    root; a full URL starts over.],
  reply: [GETCWD: the prefix, as text, no NUL.],
  asm: "        CALL    FNDEVN, NCGETCWD, 0
        jsr     fn_go           ; FN_RXLO bytes at FN_RPLY",
  c: "network_fs_pwd(url, (char *) buf);")[]

#cmd("Username / Password", dev: "$71", code: "$FD / $FE",
  payload: [The name or the password, up to 256 bytes.],
  asm: "        CALL    FNDEVN, NCUSER, 0
        lda     #<data
        sta     fn_ptr
        lda     #>data
        sta     fn_ptr+1
        jsr     fn_str
        jsr     fn_go",
  c: "network_set_username(url, \"guest\");
network_set_password(url, \"secret\");")[
Kept for the next OPEN on the channel.]

#cmd("File operations", dev: "$71",
  code: "$20 $21 $23 $24 $2A $2B",
  params: [mode (1), unused (1).],
  payload: [The URL; for RENAME, `old,new`.],
  reply: [none; NAK if the protocol has no file system or the operation
    failed.],
  asm: "        CALL    FNDEVN, NCDELETE, 2
        lda     #0
        jsr     fn_pb
        lda     #0
        jsr     fn_pb
        lda     #<url
        sta     fn_ptr
        lda     #>url
        sta     fn_ptr+1
        jsr     fn_str
        jsr     fn_go",
  c: "network_fs_delete(url);
network_fs_mkdir(\"N:TNFS://host/new/\");")[
`$20` RENAME, `$21 '!'` DELETE, `$23 '#'` LOCK, `$24 '$'` UNLOCK, `$2A '*'`
MKDIR, `$2B '+'` RMDIR. Each is done in one shot, and closes whatever the
channel had open.]

#cmd("Accept / Close client", dev: "$71", code: "$41 'A' / $63 'c'",
  reply: [none; NAK if the channel is not a listening TCP socket, or no client
    is waiting.],
  asm: "        CALL    FNDEVN, NCACCEPT, 0
        jsr     fn_go",
  c: "/* after OPEN N:TCP://:6502/ */
network_accept(url);
network_close_client(url);")[
A TCP URL with no host -- `N:TCP://:6502/` -- listens. When STATUS shows a
connection, ACCEPT takes it.]

#cmd("UDP destination / remote", dev: "$71", code: "$44 'D' / $72 'r'",
  payload: [SET_DESTINATION: `host:port`.],
  reply: [GET_REMOTE: 256 bytes, the sender as `ip:port`. On a real FujiNet
    (an ESP32) GET_REMOTE always NAKs; it works on fujinet-pc.],
  asm: "        CALL    FNDEVN, NCDEST, 0
        lda     #<data
        sta     fn_ptr
        lda     #>data
        sta     fn_ptr+1
        jsr     fn_str
        jsr     fn_go",
  c: "network_udp_set_destination(
    \"N:UDP://10.0.0.5:6502/\");")[]

#cmd("Interrupt rate", dev: "$71", code: "$5A 'Z'",
  params: [milliseconds (1).],
  asm: "        CALL    FNDEVN, NCINTR, 1
        lda     #100
        jsr     fn_pb
        jsr     fn_go",
  c: "network_set_interrupt_rate(url, 100);")[
Paces the FujiNet's "data waiting" interrupt line. The NES cartridge does not
carry that line to the 6502, so an NES program polls STATUS instead.]

The network device NAKs `$FF` GET_DSTATS, `$FA` SET_UNIT, `$81` and `$80`,
and `$45` GET_ERROR -- read the error byte of STATUS instead.
