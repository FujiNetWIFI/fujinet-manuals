#import "../lib.typ": *
= Command Reference: The Network Device

Every command devices `$71`--`$78` answer, verified against the RS232 network dispatcher in `network.cpp`. Most opcodes are the ASCII letter of their name --- `'O'`pen, `'R'`ead, `'W'`rite --- a habit from the Atari. The connection, the devicespec grammar and each protocol's behaviour belong to _The FujiNet Network Protocol Handbook_; these are the cards. Cap a read at 512 bytes, one slice of the window, and a write's payload at what fits the 320-byte TX stream.

#sect[The lifecycle five]

#cmd("NET_OPEN", code: "$4F 'O'", dev: "$71", nparam: "2",
  params: [bytes: access mode (4 read, 8 write, 12 read/write), translation (0 none, 1 CR, 2 LF, 3 CR LF)],
  payload: [the devicespec, `N:` and the URL, at its own length],
  reply: [ACK when the connection is established],
  asm: "        lda     #NETDEV
        sta     FNDEV
        lda     #NCOPEN
        sta     FNCMD
        lda     #2
        sta     FNNPR
        jsr     FNBEG
        lda     #NMHTTPG        ; 12: GET, headers allowed
        jsr     FNPB
        lda     #NTRNONE
        jsr     FNPB
        ldy     #0
U1:     lda     TURL,y          ; \"N:https://...\"
        beq     U2
        sta     FNTX
        iny
        bne     U1
U2:     jsr     FNGO",
  bas: " dev = NETDEV
 cmd = NCOPEN
 npar = 2
 gosub fnbeg
 FNTX = 1
 FNTX = NMHTTPG
 FNTX = 1
 FNTX = NTRNONE
 for l = 0 to url_length - 1
 FNTX = url[l]
 next
 gosub fngo",
  [On HTTP, mode 4 and mode 12 are both GET --- 12 allows headers to be set through the channel modes --- and the fetch is deferred to the first STATUS. Modes 13 POST, 14 PUT with headers, 5 DELETE. A URL that streams from a cartridge path buffer goes in with `FNWRAW` or `FNH_PATHO = FP_TXRAW`, unpadded: padding in the middle of a URL corrupts the request.])

#cmd("NET_STATUS", code: "$53 'S'", dev: "$71", nparam: "2",
  params: [two zero bytes --- the build reads the request type from the second],
  reply: [4 bytes: `avail` (word), `connected`, `devstatus` (1 success, 136 end of file)],
  asm: "        lda     #NCSTAT
        sta     FNCMD
        lda     #2
        sta     FNNPR
        jsr     FNBEG
        lda     #0
        jsr     FNPB
        lda     #0
        jsr     FNPB
        jsr     FNGO
        lda     FNRPLY+NSAVLO   ; avail, low
        ldx     FNRPLY+NSAVHI   ; avail, high
        ldy     FNRPLY+NSDEVST  ; 1 = success",
  bas: " cmd = NCSTAT
 npar = 2
 gosub fnbeg
 FNTX = 1
 FNTX = 0
 FNTX = 1
 FNTX = 0
 gosub fngo
 avlo = FNRPLY[0]
 avhi = FNRPLY[1]
 if FNRPLY[3] <> 1 then goto fail",
  [The heartbeat. A terminal gates on `connected`; a fetch-and-render program gates on `devstatus`; everyone reads `avail`, and reads it until two readings agree.])

#cmd("NET_READ", code: "$52 'R'", dev: "$71", nparam: "1",
  params: [*one word*: the byte count --- clamp to `avail` and to 512],
  reply: [exactly that many bytes, in the reply window],
  asm: "        lda     #NCREAD
        sta     FNCMD
        lda     #1
        sta     FNNPR
        jsr     FNBEG
        lda     WANT            ; low
        ldx     #0              ; high
        jsr     FNPW
        jsr     FNGO
; the bytes are at FNRPLY; RXLEN says how many",
  bas: " cmd = NCREAD
 npar = 1
 gosub fnbeg
 FNTX = 2
 FNTX = want
 FNTX = 0
 gosub fngo",
  [The adapter sends exactly `want` bytes on ACK; a short or failed read comes back as a NAK. Render or copy before any other transaction repaints the window.])

#cmd("NET_WRITE", code: "$57 'W'", dev: "$71", nparam: "1",
  params: [word: the byte count],
  payload: [exactly that many bytes],
  reply: [ACK],
  asm: "        lda     #NCWRITE
        sta     FNCMD
        lda     #1
        sta     FNNPR
        jsr     FNBEG
        lda     #MSGE-MSG
        ldx     #0
        jsr     FNPW
        ldy     #0
W1:     lda     MSG,y
        sta     FNTX
        iny
        cpy     #MSGE-MSG
        bne     W1
        jsr     FNGO",
  bas: " cmd = NCWRITE
 npar = 1
 gosub fnbeg
 FNTX = 2
 FNTX = msg_length
 FNTX = 0
 for l = 0 to msg_length - 1
 FNTX = msg[l]
 next
 gosub fngo",
  [The count rides twice, as the parameter and as the payload the cartridge measures. Keep it well inside the 320-byte TX stream.])

#cmd("NET_CLOSE", code: "$43 'C'", dev: "$71", nparam: "0",
  reply: [ACK, and an empty reply window],
  bas: " cmd = NCCLOSE
 npar = 0
 gosub fnbeg
 gosub fngo",
  [Hang up. A program that reopens per request closes at the *start* of the next request, never between a READ and the rendering that follows it. The first close of a session earns a NAK, which is harmless.])

#sect[Structured channels, seek and line discipline]

#cmd("NET_CHANNEL_MODE / NET_PARSE / NET_QUERY", code: "$FC / $50 'P' / $51 'Q'", dev: "$71", nparam: "2 / 0 / 0",
  params: [CHANNEL_MODE: byte (ignored), then the mode (0 protocol, 1 JSON)],
  payload: [QUERY: the path, such as `/0/name`],
  reply: [QUERY: the value as text --- then STATUS and READ it],
  asm: "        lda     #NCJSON
        sta     FNCMD
        lda     #2
        sta     FNNPR
        jsr     FNBEG
        lda     #0
        jsr     FNPB
        lda     #1              ; JSON
        jsr     FNPB
        jsr     FNGO
        lda     #NCPARSE
        sta     FNCMD
        lda     #0
        sta     FNNPR
        jsr     FNBEG
        jsr     FNGO
        lda     #NCQUERY
        sta     FNCMD
        jsr     FNBEG
        ldy     #0
Q1:     lda     PATH,y          ; \"/0/name\"
        beq     Q2
        sta     FNTX
        iny
        bne     Q1
Q2:     jsr     FNGO            ; then STATUS, READ",
  bas: " cmd = NCJSON
 npar = 2
 gosub fnbeg
 FNTX = 1
 FNTX = 0
 FNTX = 1
 FNTX = 1
 gosub fngo
 cmd = NCPARSE
 npar = 0
 gosub fnbeg
 gosub fngo
 cmd = NCQUERY
 gosub fnbeg
 for l = 0 to path_length - 1
 FNTX = path[l]
 next
 gosub fngo",
  [Switch an open connection to the adapter's JSON parser (the mode is the *second* parameter), parse the body, then query one element: the difference between parsing JSON on a 6507 and not. The games in this family ask their servers for binary with `?bin=1` instead.])

#cmd("NET_SET_CHANNEL_MODE", code: "$4D 'M'", dev: "$71", nparam: "2",
  params: [byte (ignored), then the HTTP channel mode: 0 body, 1 collect headers, 2 get headers, 3 set headers, 4 POST data],
  reply: [ACK; NAK on a connection that is not HTTP],
  [The HTTP-only channel switch. In mode 3 a WRITE sets a request header; in mode 4 a WRITE supplies the POST body; in mode 2 a READ returns the collected response headers. Mode 0 is the page.])

#cmd("NET_SEEK / NET_TELL", code: "$25 '%' / $26 '&'", dev: "$71", nparam: "1 / 0",
  params: [SEEK: a 4-byte offset], reply: [TELL: a 4-byte position],
  [Random access where the protocol supports it: TNFS files, HTTP ranges.])

#cmd("NET_TRANSLATION / NET_SET_EOL / NET_SET_INT_RATE", code: "$54 'T' / $4C 'L' / $5A 'Z'", dev: "$71", nparam: "2",
  params: [TRANSLATION: byte (ignored) then the code; SET_EOL: the EOL pair, a first byte of 0 restores the default; SET_INT_RATE: byte (ignored) then the rate],
  reply: [ACK],
  [Line-ending translation and custom terminators after OPEN. `SET_INT_RATE` paces a bus interrupt on platforms that have one; the cartridge has no line back to the console, so it is accepted and irrelevant. Polling ACKSEQ is the only completion mechanism here.])

#sect[Filesystems, sockets and credentials]

#cmd("NET_RENAME / DELETE / LOCK / UNLOCK / MKDIR / RMDIR / CHDIR / GETCWD", code: "$20 $21 $23 $24 $2A $2B $2C $30", dev: "$71", nparam: "0",
  payload: [the target path; RENAME: `old,new`],
  reply: [ACK; GETCWD answers the path],
  [Filesystem verbs on the protocols that have files --- TNFS, FTP, SMB. `CHDIR` and `GETCWD` move and report the working directory.])

#cmd("NET_CONTROL / NET_CLOSE_CLIENT", code: "$41 'A' / $63 'c'", dev: "$71", nparam: "0",
  reply: [ACK],
  [TCP server duty: a listening `N:TCP://:port/` accepts a waiting client with `'A'` and hangs up on that client with `'c'` while keeping the listener. The console can be the BBS.])

#cmd("NET_GET_REMOTE / NET_SET_DESTINATION / NET_USERNAME / NET_PASSWORD", code: "$72 'r' / $44 'D' / $FD / $FE", dev: "$71", nparam: "0",
  payload: [SET_DESTINATION: `host:port`; USERNAME and PASSWORD: the credential],
  reply: [GET_REMOTE: the last datagram's sender],
  [UDP's who-said-that and talk-to-them-instead, plus stored credentials for the next OPEN on protocols that log in --- FTP, SSH, SMB. Send them before the OPEN.])

#sect[Answered with a NAK on this build]

Enumerated but not dispatched, so a NAK and no example: `NET_GET_DSTATS_VALUE` (`$FF`), `NET_SET_PARAMETERS` (`$FB`), `NET_SET_CHANNEL` (`$FA`), `NET_SET_HSIO_INDEX` (`$E3`), `NET_QUERY_ALT` and `NET_PARSE_ALT` (`$81`, `$80`), `NET_GET_ERROR` (`$45` --- read the STATUS device byte instead), and `NET_HSIO_INDEX` (`$3F`).
