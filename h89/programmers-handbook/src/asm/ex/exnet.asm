;-----------------------------------------------------------------------------
; EXNET -- the network device exerciser: every command the network units
; (71H-78H) answer, sent the way a program would send it, against the
; book's helper servers on 127.0.0.1 and the SD card. Each example is
; marked (;@ex KEY ... ;@end) and printed in Chapter 10; the frames it
; put on the bus are printed beside it.
;
;   unit 1  HTTP GET, translation, unit settings, errors
;   unit 2  JSON           unit 3  HTTP POST, PUT, DELETE
;   unit 4  HTTP headers   unit 5  TCP client (the test board, 7801)
;   unit 6  TCP server (7803)      unit 7  UDP (7804, answers to 7805)
;   unit 8  files on the SD card
;
; One source, two systems:
;   tools/asm.sh hdos EXNET src/asm/ex/exnet.asm  ->  EXNET.ABS (HDOS)
;   tools/asm.sh cpm  EXNET src/asm/ex/exnet.asm  ->  EXNET.COM (CP/M)
;
; Copyright (C) 2026 Thomas Cherryhomes
; SPDX-License-Identifier: GPL-3.0-or-later
;-----------------------------------------------------------------------------
INCLUDE "os.inc"
INCLUDE "fujinet.inc"

BUFSZ           equ     2048            ; the shared read buffer

main:
        call    card_on

;====================================================== unit 1: GET ====
        call    ex_m
        defm    "net.status.closed", 0
;@ex net.status.closed
        ld      hl,rq_status            ; nothing is open on unit 1,
        call    fn_call
        ld      a,(nstat+NS_ERR)        ;   so the error is 207,
        call    pdec8                   ;   NOT CONNECTED
;@end
        call    ex_show

        call    ex_m
        defm    "net.open", 0
;@ex net.open
        ld      hl,rq_open              ; GET a file from the server:
        call    fn_call                 ;   ACK, but nothing is sent yet
;@end
        call    ex_show

        call    ex_m
        defm    "net.status", 0
;@ex net.status
        ld      hl,rq_status            ; the first STATUS sends the GET
        call    fn_call                 ;   and waits for the answer
        ld      hl,(nstat+NS_AVAIL)     ; bytes waiting to be read
        call    pdec16
;@end
        call    ex_show

        call    ex_m
        defm    "net.read", 0
;@ex net.read
        ld      hl,rq_read              ; read what STATUS said waits
        call    getwait
        call    typeout                 ; and type it
;@end
        call    ex_show

        call    ex_m
        defm    "net.status.eof", 0
;@ex net.status.eof
        ld      hl,rq_status            ; all read: none waiting, not
        call    fn_call                 ;   connected, error 136 (end)
        ld      a,(nstat+NS_ERR)
        call    pdec8
;@end
        call    ex_show

        call    ex_m
        defm    "net.read.eof", 0
;@ex net.read.eof
        ld      hl,64                   ; a READ past the end
        ld      (rq_read+RQ_AUX1),hl
        ld      hl,rq_read
        call    fn_call                 ; NAK
;@end
        call    ex_show

        call    ex_m
        defm    "net.close", 0
;@ex net.close
        ld      hl,rq_close             ; done: free the unit
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.read.loop", 0
;@ex net.read.loop
        ld      hl,rq_opbin             ; GET a 3000-byte file
        call    fn_call
        ld      hl,0                    ; bytes so far
        ld      (total),hl
rl_next:
        ld      hl,rq_status            ; how many are waiting?
        call    fn_call
        ld      hl,(nstat+NS_AVAIL)
        ld      a,h
        or      l
        jr      nz,rl_read
        ld      a,(nstat+NS_CONN)       ; none: still coming?
        or      a
        jr      nz,rl_next
        jr      rl_done                 ; no: that was all
rl_read:
        ld      hl,rq_read              ; a buffer full at most
        call    getwait
        ld      hl,(total)              ; BC bytes came
        add     hl,bc
        ld      (total),hl
        jr      rl_next
rl_done:
        ld      hl,(total)
        call    pdec16
        ld      hl,rq_close
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.read.ahead", 0
;@ex net.read.ahead
        ld      hl,rq_opbin             ; the same file again, but
        call    fn_call
        ld      hl,2048                 ;   READ with no STATUS first:
        ld      (rq_read+RQ_AUX1),hl    ;   the GET goes out, and READ
        ld      hl,rq_read              ;   waits for all 2048 bytes
        call    fn_call
        call    pcount
        ld      hl,rq_read              ; ask for 2048 again: only 952
        call    fn_call                 ;   are left, and they come
        call    pcount
;@end
        call    ex_show
        call    ex_m
        defm    "_tidy", 0
        ld      hl,rq_close
        call    fn_call

;===================================================== unit 2: JSON ====
        call    ex_m
        defm    "net.open.json", 0
;@ex net.open.json
        ld      hl,rq_opjson            ; GET a JSON document on unit 2
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.set_parser", 0
;@ex net.set_parser
        ld      hl,rq_parser            ; treat it as JSON (after OPEN:
        call    fn_call                 ;   OPEN resets the parser)
;@end
        call    ex_show

        call    ex_m
        defm    "net.parse", 0
;@ex net.parse
        ld      hl,rq_parse             ; fetch it all and parse it
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.status.parsed", 0
;@ex net.status.parsed
        ld      hl,rq_st2               ; the body is used up: error
        call    fn_call                 ;   136 until a QUERY answers
        ld      a,(nstat+NS_ERR)
        call    pdec8
;@end
        call    ex_show

        call    ex_m
        defm    "net.query", 0
;@ex net.query
        ld      hl,rq_qname             ; the value of "name"
        call    fn_call
        call    answer                  ; "FujiNet", then 0AH
;@end
        call    ex_show

        call    ex_m
        defm    "net.query.array", 0
;@ex net.query.array
        ld      hl,rq_qport             ; the third of the "ports"
        call    fn_call                 ;   (they count from 0)
        call    answer                  ; "210", then 0AH
;@end
        call    ex_show

        call    ex_m
        defm    "net.set_parameter", 0
;@ex net.set_parameter
        ld      hl,rq_qeol              ; end answers with CR, not LF
        call    fn_call
        ld      hl,rq_qmach             ; the value of "machine"
        call    fn_call
        call    answer                  ; "H89", then 0DH
;@end
        call    ex_show

        call    ex_m
        defm    "net.query.missing", 0
;@ex net.query.missing
        ld      hl,rq_qnone             ; a name that is not there:
        call    fn_call                 ;   still ACK,
        ld      hl,rq_st2
        call    fn_call
        ld      hl,(nstat+NS_AVAIL)     ;   but nothing to read
        call    pdec16
;@end
        call    ex_show
        call    ex_m
        defm    "_tidy", 0
        ld      hl,rq_close2
        call    fn_call

;======================================== unit 3: POST, PUT, DELETE ====
        call    ex_m
        defm    "net.open.http_post", 0
;@ex net.open.http_post
        ld      hl,rq_oppost            ; POST to the web server
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.set_http_mode", 0
;@ex net.set_http_mode
        ld      hl,rq_mpost             ; what is written now is the
        call    fn_call                 ;   body of the POST
;@end
        call    ex_show

        call    ex_m
        defm    "net.write.http_post", 0
;@ex net.write.http_post
        ld      hl,rq_wpost             ; the body
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.set_http_mode.body", 0
;@ex net.set_http_mode.body
        ld      hl,rq_mbody             ; back to the body mode: READ
        call    fn_call                 ;   now gets the answer
;@end
        call    ex_show

        call    ex_m
        defm    "net.status.http_post", 0
;@ex net.status.http_post
        ld      hl,rq_st3               ; this sends the POST
        call    fn_call
        ld      hl,(nstat+NS_AVAIL)     ; the answer's length
        call    pdec16
;@end
        call    ex_show

        call    ex_m
        defm    "net.read.http_post", 0
;@ex net.read.http_post
        ld      hl,rq_rd3               ; the server's answer
        call    getwait
        call    typeout
;@end
        call    ex_show
        call    ex_m
        defm    "_tidy", 0
        ld      hl,rq_close3
        call    fn_call

        call    ex_m
        defm    "net.open.http_put", 0
;@ex net.open.http_put
        ld      hl,rq_opput             ; PUT a file on the server
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.write.http_put", 0
;@ex net.write.http_put
        ld      hl,rq_wput              ; for PUT, plain writes are the
        call    fn_call                 ;   body; they wait for CLOSE
;@end
        call    ex_show

        call    ex_m
        defm    "net.close.http_put", 0
;@ex net.close.http_put
        ld      hl,rq_close3            ; this sends the PUT
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.open.http_delete", 0
;@ex net.open.http_delete
        ld      hl,rq_opdel             ; DELETE a file on the server
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.status.http_delete", 0
;@ex net.status.http_delete
        ld      hl,rq_st3               ; this sends the DELETE
        call    fn_call
        ld      hl,(nstat+NS_AVAIL)     ; the answer's length
        call    pdec16
;@end
        call    ex_show
        call    ex_m
        defm    "_tidy", 0
        ld      hl,rq_close3
        call    fn_call

        call    ex_m
        defm    "net.close.unsent", 0
;@ex net.close.unsent
        ld      hl,rq_opdel2            ; DELETE another file, but
        call    fn_call                 ;   CLOSE at once: with no
        ld      hl,rq_close3            ;   STATUS or READ between,
        call    fn_call                 ;   the DELETE is never sent
;@end
        call    ex_show

        call    ex_m
        defm    "net.open.http_put_h", 0
;@ex net.open.http_put_h
        ld      hl,rq_opputh            ; mode 14, "PUT with headers"
        call    fn_call
        ld      hl,rq_mpost             ; a body, as for POST
        call    fn_call
        ld      hl,rq_wputh
        call    fn_call
        ld      hl,rq_mbody
        call    fn_call
        ld      hl,rq_st3               ; sent -- but as a POST
        call    fn_call
;@end
        call    ex_show
        call    ex_m
        defm    "_tidy", 0
        ld      hl,rq_close3
        call    fn_call

;================================================== unit 4: headers ====
        call    ex_m
        defm    "net.open.http_get_h", 0
;@ex net.open.http_get_h
        ld      hl,rq_opgeth            ; mode 12: a GET whose headers
        call    fn_call                 ;   we can set and read
;@end
        call    ex_show

        call    ex_m
        defm    "net.set_http_mode.set_headers", 0
;@ex net.set_http_mode.set_headers
        ld      hl,rq_mseth             ; writes are request headers
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.write.header", 0
;@ex net.write.header
        ld      hl,rq_whead             ; one header, "Name: value"
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.set_http_mode.collect", 0
;@ex net.set_http_mode.collect
        ld      hl,rq_mcoll             ; writes name answer headers
        call    fn_call                 ;   to keep
;@end
        call    ex_show

        call    ex_m
        defm    "net.write.collect", 0
;@ex net.write.collect
        ld      hl,rq_wcoll1            ; keep these two
        call    fn_call
        ld      hl,rq_wcoll2
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.set_http_mode.get_headers", 0
;@ex net.set_http_mode.get_headers
        ld      hl,rq_mgeth             ; this sends the GET; reads
        call    fn_call                 ;   now give the kept headers
;@end
        call    ex_show

        call    ex_m
        defm    "net.read.header", 0
;@ex net.read.header
        ld      b,2                     ; two were kept
rh_next:
        push    bc
        ld      hl,rq_st4               ; the next one's length
        call    fn_call
        ld      hl,rq_rd4               ; its value, ended by 9BH
        call    getwait
        call    ptext
        call    crlf
        pop     bc
        djnz    rh_next
;@end
        call    ex_show
        call    ex_m
        defm    "_tidy", 0
        ld      hl,rq_close4
        call    fn_call

;=============================================== unit 5: TCP client ====
        call    ex_m
        defm    "net.open.tcp", 0
;@ex net.open.tcp
        ld      hl,rq_optcp             ; connect to the test board
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.status.tcp", 0
;@ex net.status.tcp
        ld      hl,rq_st5               ; wait up to 10 s for its
        ld      b,100                   ;   greeting
        call    waitin
        call    pdec16                  ; HL = bytes waiting
;@end
        call    ex_show

        call    ex_m
        defm    "net.read.tcp", 0
;@ex net.read.tcp
        ld      hl,rq_rd5               ; never more than STATUS said:
        call    getwait                 ;   a short TCP read is lost
        call    typeout
;@end
        call    ex_show

        call    ex_m
        defm    "net.write", 0
;@ex net.write
        ld      hl,rq_wr5               ; send a line
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.read.tcp_reply", 0
;@ex net.read.tcp_reply
        ld      b,100                   ; wait up to 10 s for it,
rt_next:
        ld      hl,rq_st5
        call    waitin
        jr      z,rt_done
        ld      hl,rq_rd5               ; take what has come
        call    getwait
        call    typeout
        ld      b,5                     ; and more, until 0.5 s
        jr      rt_next                 ;   pass with none
rt_done:
;@end
        call    ex_show

        call    ex_m
        defm    "net.status.hangup", 0
;@ex net.status.hangup
        ld      hl,rq_wbye              ; BYE: the board hangs up
        call    fn_call
        ld      b,50                    ; watch for that, 5 s at most
rb_next:
        call    pause
        push    bc
        ld      hl,rq_st5
        call    fn_call
        pop     bc
        ld      a,(nstat+NS_CONN)       ; still connected?
        or      a
        jr      z,rb_gone
        djnz    rb_next
rb_gone:
        ld      a,(nstat+NS_ERR)        ; gone: error 136, but its
        call    pdec8                   ;   goodbye is still there
        call    pspace                  ;   to be read
        ld      hl,(nstat+NS_AVAIL)
        call    pdec16
;@end
        call    ex_show
        call    ex_m
        defm    "_tidy", 0
        ld      hl,rq_close5
        call    fn_call

;=============================================== unit 6: TCP server ====
        call    ex_m
        defm    "net.open.tcp_server", 0
;@ex net.open.tcp_server
        ld      hl,rq_opsrv             ; listen on port 7803
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.status.listen", 0
;@ex net.status.listen
        ld      hl,rq_st6               ; wait for a caller
        call    waitcall
;@end
        call    ex_show

        call    ex_m
        defm    "net.accept", 0
;@ex net.accept
        ld      hl,rq_accept            ; take the call
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.read.server", 0
;@ex net.read.server
        ld      hl,rq_st6               ; the caller says something
        ld      b,100
        call    waitin
        ld      hl,rq_rd6
        call    getwait
        call    typeout
;@end
        call    ex_show

        call    ex_m
        defm    "net.write.server", 0
;@ex net.write.server
        ld      hl,rq_wr6               ; and is answered
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.close_client", 0
;@ex net.close_client
        ld      hl,rq_st6               ; the next caller:
        call    waitcall
        ld      hl,rq_accept            ;   take the call
        call    fn_call
        ld      hl,rq_cclient           ;   and hang up. NAK: it WAS
        call    fn_call                 ;   done (the sense is inverted)
;@end
        call    ex_show

        call    ex_m
        defm    "net.close_client.none", 0
;@ex net.close_client.none
        ld      hl,rq_cclient           ; no one to hang up on: ACK
        call    fn_call
;@end
        call    ex_show
        call    ex_m
        defm    "_tidy", 0
        ld      hl,rq_close6
        call    fn_call

;====================================================== unit 7: UDP ====
        call    ex_m
        defm    "net.open.udp", 0
;@ex net.open.udp
        ld      hl,rq_opudp             ; take datagrams on port 7804
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.get_remote.early", 0
;@ex net.get_remote.early
        ld      hl,rq_remote            ; no datagram yet: the sender
        call    fn_call                 ;   is 255.255.255.255, port 0
        call    premote
;@end
        call    ex_show

        call    ex_m
        defm    "net.read.udp", 0
;@ex net.read.udp
        ld      b,30                    ; up to 3 s
ru_next:
        push    bc
        call    pause
        ld      hl,rq_st7               ; STATUS takes a datagram in
        call    fn_call                 ;   but counts only the NEXT
        ld      hl,rq_rd7               ;   one, so READ anyway: NAK
        call    fn_call                 ;   means none has come yet
        pop     bc
        jr      z,ru_got
        djnz    ru_next
        jr      ru_none
ru_got:
        ld      bc,(fn_len)             ; one datagram, BC bytes
        ld      hl,buf
        call    ptext
ru_none:
;@end
        call    ex_show

        call    ex_m
        defm    "net.get_remote", 0
;@ex net.get_remote
        ld      hl,rq_remote            ; who sent it?
        call    fn_call
        call    premote
;@end
        call    ex_show

        call    ex_m
        defm    "net.set_destination", 0
;@ex net.set_destination
        ld      hl,rq_dest              ; where writes go
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.write.udp", 0
;@ex net.write.udp
        ld      hl,rq_wr7               ; one datagram
        call    fn_call
;@end
        call    ex_show
        call    ex_m
        defm    "_tidy", 0
        ld      hl,rq_close7
        call    fn_call

;============================================== unit 8: the SD card ====
        call    ex_m
        defm    "net.open.dir", 0
;@ex net.open.dir
        ld      hl,rq_opdir             ; list a directory
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.read.dir", 0
;@ex net.read.dir
        ld      hl,rq_st8               ; the listing's length
        call    fn_call
        ld      hl,rq_rd8               ; read it: a line a file
        call    getwait
        call    typeout
;@end
        call    ex_show
        call    ex_m
        defm    "_tidy", 0
        ld      hl,rq_close8
        call    fn_call

        call    ex_m
        defm    "net.open.write", 0
;@ex net.open.write
        ld      hl,rq_opwr              ; make a new file
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.write.file", 0
;@ex net.write.file
        ld      hl,rq_wfile             ; a line of text into it
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.close.file", 0
;@ex net.close.file
        ld      hl,rq_close8            ; finish the file
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.open.file", 0
;@ex net.open.file
        ld      hl,rq_opimg             ; a disk image: 512-byte
        call    fn_call                 ;   sectors, sector n all n
;@end
        call    ex_show

        call    ex_m
        defm    "net.seek", 0
;@ex net.seek
        ld      hl,rq_seek              ; go to sector 3 (byte 1536)
        call    fn_call
        ld      hl,rq_rd8x              ; and read 8 bytes of it
        call    fn_call
        ld      hl,buf                  ; 03 03 03 ...
        call    phexs
;@end
        call    ex_show

        call    ex_m
        defm    "net.tell", 0
;@ex net.tell
        ld      hl,rq_tell              ; where are we now?
        call    fn_call
        ld      hl,(pos)                ; 1544 (the low word of four)
        call    pdec16
;@end
        call    ex_show
        call    ex_m
        defm    "_tidy", 0
        ld      hl,rq_close8
        call    fn_call

        call    ex_m
        defm    "net.rename", 0
;@ex net.rename
        ld      hl,rq_rename            ; H89.TXT is now H89NEW.TXT
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.delete", 0
;@ex net.delete
        ld      hl,rq_delete            ; and now it is gone
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.mkdir", 0
;@ex net.mkdir
        ld      hl,rq_mkdir             ; a new directory
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.rmdir", 0
;@ex net.rmdir
        ld      hl,rq_rmdir             ; removed again (it is empty)
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.lock", 0
;@ex net.lock
        ld      hl,rq_lock              ; make a file read-only: the
        call    fn_call                 ;   SD card cannot (NAK)
;@end
        call    ex_show

        call    ex_m
        defm    "net.unlock", 0
;@ex net.unlock
        ld      hl,rq_unlock            ; nor this (NAK)
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.chdir", 0
;@ex net.chdir
        ld      hl,rq_chdir             ; names without a scheme now
        call    fn_call                 ;   start here
;@end
        call    ex_show

        call    ex_m
        defm    "net.getcwd", 0
;@ex net.getcwd
        ld      hl,rq_getcwd            ; where is that?
        call    fn_call
        ld      hl,cwd                  ; BC bytes, no NUL
        call    ptext
;@end
        call    ex_show

        call    ex_m
        defm    "net.open.relative", 0
;@ex net.open.relative
        ld      hl,rq_oprel             ; just a name: the directory
        call    fn_call                 ;   set by CHDIR goes before it
        ld      hl,rq_st8
        call    fn_call
        ld      hl,rq_rd8
        call    getwait
        call    typeout
;@end
        call    ex_show
        call    ex_m
        defm    "_tidy", 0
        ld      hl,rq_close8
        call    fn_call

;========================================= unit 1: settings, errors ====
        call    ex_m
        defm    "net.username", 0
;@ex net.username
        ld      hl,rq_user              ; for servers that ask
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.password", 0
;@ex net.password
        ld      hl,rq_pass
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.set_eol", 0
;@ex net.set_eol
        ld      hl,rq_seteol            ; our lines end with CR alone
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "net.translation", 0
;@ex net.translation
        ld      hl,rq_xlat              ; the network's end in CR LF:
        call    fn_call                 ;   later OPENs translate
;@end
        call    ex_show

        call    ex_m
        defm    "net.open.translated", 0
;@ex net.open.translated
        ld      hl,rq_open              ; the same GET as before
        call    fn_call
        ld      hl,rq_status
        call    fn_call
        ld      hl,rq_read              ; 53 bytes now, not 55: each
        call    getwait                 ;   CR LF came as CR
        call    ptext
;@end
        call    ex_show
        call    ex_m
        defm    "_tidy", 0
        ld      hl,rq_close
        call    fn_call
        ld      hl,rq_xlat0
        call    fn_call
        ld      hl,rq_eol0
        call    fn_call

        call    ex_m
        defm    "net.set_int_rate", 0
;@ex net.set_int_rate
        ld      hl,rq_irate             ; 100 ms (never 0: that
        call    fn_call                 ;   crashes the firmware)
;@end
        call    ex_show

        call    ex_m
        defm    "net.open.refused", 0
;@ex net.open.refused
        ld      hl,rq_opbad             ; a port no one listens on:
        call    fn_call                 ;   NAK
;@end
        call    ex_show

        call    ex_m
        defm    "net.status.refused", 0
;@ex net.status.refused
        ld      hl,rq_status            ; why: error 200, connection
        call    fn_call                 ;   refused
        ld      a,(nstat+NS_ERR)
        call    pdec8
;@end
        call    ex_show
        call    ex_m
        defm    "_tidy", 0
        ld      hl,rq_close             ; (CLOSE clears the error)
        call    fn_call

        call    ex_m
        defm    "net.get_error", 0
;@ex net.get_error
        ld      hl,rq_geterr            ; a command the network units
        call    fn_call                 ;   do not have: NAK
;@end
        call    ex_show

        jp      ex_done

;------------------------------------------------------ subroutines ----
;@ex net.read
; HL -> a READ request block. Read what the last STATUS said is
; waiting, a buffer full at most, into buf. HL = buf, BC = count.
getwait:
        push    hl
        pop     ix                      ; IX -> the block
        ld      hl,(nstat+NS_AVAIL)
        ld      de,BUFSZ
        or      a
        sbc     hl,de                   ; more than a buffer?
        add     hl,de
        jr      c,getw1
        ex      de,hl                   ; yes: a buffer full
getw1:
        ld      (ix+RQ_AUX1),l          ; the length to ask for
        ld      (ix+RQ_AUX2),h
        push    ix
        pop     hl
        call    fn_call                 ; BC = what really came
        ld      hl,buf
        ret

; type BC bytes from HL as they are, line ends and all
typeout:
        ld      a,b
        or      c
        ret     z
        ld      a,(hl)
        call    conout
        inc     hl
        dec     bc
        jr      typeout
;@end

;@ex net.query
; STATUS, then READ the answer QUERY left waiting, and show it
answer:
        ld      hl,rq_st2
        call    fn_call
        ld      hl,rq_rd2
        call    getwait
        jp      ptext
;@end

;@ex net.status.tcp
; HL -> a STATUS request block, B = how many tries. Ask every
; 0.1 s until bytes are waiting: NZ and HL = how many, or Z if
; none came.
waitin:
        ld      (wt_rq),hl
waiti1:
        call    pause                   ; give them time to come
        push    bc
        ld      hl,(wt_rq)
        call    fn_call
        pop     bc
        ld      hl,(nstat+NS_AVAIL)
        ld      a,h
        or      l
        ret     nz
        djnz    waiti1
        ret

; wait 0.1 s: 50 ticks of the 2 ms clock. Keeps BC.
pause:
        ld      de,(TICKS)
pause1:
        ld      hl,(TICKS)
        or      a
        sbc     hl,de
        ld      a,l
        cp      50
        jr      c,pause1
        ret
;@end

;@ex net.status.listen
; HL -> a listener's STATUS request block. Ask every 0.5 s, for
; up to 15 s, until a caller waits ("connected" = 1): NZ if one
; does, Z if no one came.
waitcall:
        ld      (wt_rq),hl
        ld      b,30
waitc1:
        push    bc
        ld      hl,(wt_rq)
        call    fn_call
        pop     bc
        ld      a,(nstat+NS_CONN)
        or      a
        ret     nz
        ld      c,5
waitc2:
        call    pause
        dec     c
        jr      nz,waitc2
        djnz    waitc1
        ret
;@end

;@ex net.get_remote
; show GET_REMOTE's answer: "a.b.c.d:port", ended by 9BH
premote:
        ld      hl,remote
prem1:
        ld      a,(hl)
        cp      0x9B
        ret     z
        call    conout
        inc     hl
        jr      prem1
;@end

; HL = BC: how many bytes came
pcount:
        ld      h,b
        ld      l,c
        call    pdec16
        jp      pspace

;---------------------------------------------------------- unit 1 ----
;@ex net.open
rq_open:                                ; unit 1: mode 4 (GET), no
        FNREQ   DEV_NETWORK, NET_OPEN, F_A1_A2, 4,0,0,0
        FNBUF   p_hello, P_HELLO_LEN, 0, 0
p_hello:
        defm    "N1:HTTP://127.0.0.1:7802/hello.txt", 0
P_HELLO_LEN     equ     $ - p_hello
;@end
;@ex net.status
rq_status:                              ; 4 bytes back: waiting (a
        FNREQ   DEV_NETWORK, NET_STATUS, F_NONE, 0,0,0,0
        FNBUF   0, 0, nstat, 4          ; word), connected, error
;@end
;@ex net.read
rq_read:                                ; the length is set each time
        FNREQ   DEV_NETWORK, NET_READ, F_B12, 0,0,0,0
        FNBUF   0, 0, buf, BUFSZ
;@end
;@ex net.close
rq_close:
        FNREQ   DEV_NETWORK, NET_CLOSE, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex net.read.loop
rq_opbin:
        FNREQ   DEV_NETWORK, NET_OPEN, F_A1_A2, 4,0,0,0
        FNBUF   p_bin, P_BIN_LEN, 0, 0
p_bin:
        defm    "N1:HTTP://127.0.0.1:7802/data.bin", 0
P_BIN_LEN       equ     $ - p_bin
;@end

;---------------------------------------------------------- unit 2 ----
;@ex net.open.json
rq_opjson:
        FNREQ   DEV_NETWORK+1, NET_OPEN, F_A1_A2, 4,0,0,0
        FNBUF   p_json, P_JSON_LEN, 0, 0
p_json:
        defm    "N2:HTTP://127.0.0.1:7802/fuji.json", 0
P_JSON_LEN      equ     $ - p_json
;@end
;@ex net.set_parser
rq_parser:                              ; field 2: 1 = JSON
        FNREQ   DEV_NETWORK+1, NET_SET_PARSER, F_A1_A2, 0,1,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex net.parse
rq_parse:
        FNREQ   DEV_NETWORK+1, NET_PARSE, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex net.status.parsed
rq_st2:
        FNREQ   DEV_NETWORK+1, NET_STATUS, F_NONE, 0,0,0,0
        FNBUF   0, 0, nstat, 4
;@end
;@ex net.query
rq_qname:                               ; the payload is the query
        FNREQ   DEV_NETWORK+1, NET_QUERY, F_NONE, 0,0,0,0
        FNBUF   p_qname, P_QNAME_LEN, 0, 0
p_qname:
        defm    "/name"
P_QNAME_LEN     equ     $ - p_qname
rq_rd2:
        FNREQ   DEV_NETWORK+1, NET_READ, F_B12, 0,0,0,0
        FNBUF   0, 0, buf, BUFSZ
;@end
;@ex net.query.array
rq_qport:
        FNREQ   DEV_NETWORK+1, NET_QUERY, F_NONE, 0,0,0,0
        FNBUF   p_qport, P_QPORT_LEN, 0, 0
p_qport:
        defm    "/ports/2"
P_QPORT_LEN     equ     $ - p_qport
;@end
;@ex net.set_parameter
rq_qeol:                                ; parameter 1: the line end
        FNREQ   DEV_NETWORK+1, NET_SET_PARAMETER, F_A1_A2, 1,13,0,0
        FNBUF   0, 0, 0, 0
rq_qmach:
        FNREQ   DEV_NETWORK+1, NET_QUERY, F_NONE, 0,0,0,0
        FNBUF   p_qmach, P_QMACH_LEN, 0, 0
p_qmach:
        defm    "/machine"
P_QMACH_LEN     equ     $ - p_qmach
;@end
;@ex net.query.missing
rq_qnone:
        FNREQ   DEV_NETWORK+1, NET_QUERY, F_NONE, 0,0,0,0
        FNBUF   p_qnone, P_QNONE_LEN, 0, 0
p_qnone:
        defm    "/serial"
P_QNONE_LEN     equ     $ - p_qnone
;@end
rq_close2:
        FNREQ   DEV_NETWORK+1, NET_CLOSE, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0

;---------------------------------------------------------- unit 3 ----
;@ex net.open.http_post
rq_oppost:                              ; mode 13: POST
        FNREQ   DEV_NETWORK+2, NET_OPEN, F_A1_A2, 13,0,0,0
        FNBUF   p_post, P_POST_LEN, 0, 0
p_post:
        defm    "N3:HTTP://127.0.0.1:7802/post", 0
P_POST_LEN      equ     $ - p_post
;@end
;@ex net.set_http_mode
rq_mpost:                               ; mode 4: the POST data
        FNREQ   DEV_NETWORK+2, NET_SET_HTTP_MODE, F_A1_A2, 0,4,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex net.write.http_post
rq_wpost:
        FNREQ   DEV_NETWORK+2, NET_WRITE, F_B12, P_FORM_LEN,0,0,0
        FNBUF   p_form, P_FORM_LEN, 0, 0
p_form:
        defm    "name=H89&cpu=Z80"
P_FORM_LEN      equ     $ - p_form
;@end
;@ex net.set_http_mode.body
rq_mbody:                               ; mode 0: the body
        FNREQ   DEV_NETWORK+2, NET_SET_HTTP_MODE, F_A1_A2, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex net.status.http_post
rq_st3:
        FNREQ   DEV_NETWORK+2, NET_STATUS, F_NONE, 0,0,0,0
        FNBUF   0, 0, nstat, 4
;@end
;@ex net.read.http_post
rq_rd3:
        FNREQ   DEV_NETWORK+2, NET_READ, F_B12, 0,0,0,0
        FNBUF   0, 0, buf, BUFSZ
;@end
;@ex net.open.http_put
rq_opput:                               ; mode 8: PUT
        FNREQ   DEV_NETWORK+2, NET_OPEN, F_A1_A2, 8,0,0,0
        FNBUF   p_put, P_PUT_LEN, 0, 0
p_put:
        defm    "N3:HTTP://127.0.0.1:7802/put.txt", 0
P_PUT_LEN       equ     $ - p_put
;@end
;@ex net.write.http_put
rq_wput:
        FNREQ   DEV_NETWORK+2, NET_WRITE, F_B12, P_PUTB_LEN,0,0,0
        FNBUF   p_putb, P_PUTB_LEN, 0, 0
p_putb:
        defm    "PUT from an H89"
P_PUTB_LEN      equ     $ - p_putb
;@end
;@ex net.close.http_put
rq_close3:
        FNREQ   DEV_NETWORK+2, NET_CLOSE, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex net.open.http_delete
rq_opdel:                               ; mode 5: DELETE
        FNREQ   DEV_NETWORK+2, NET_OPEN, F_A1_A2, 5,0,0,0
        FNBUF   p_del, P_DEL_LEN, 0, 0
p_del:
        defm    "N3:HTTP://127.0.0.1:7802/old.txt", 0
P_DEL_LEN       equ     $ - p_del
;@end
;@ex net.close.unsent
rq_opdel2:
        FNREQ   DEV_NETWORK+2, NET_OPEN, F_A1_A2, 5,0,0,0
        FNBUF   p_del2, P_DEL2_LEN, 0, 0
p_del2:
        defm    "N3:HTTP://127.0.0.1:7802/never.txt", 0
P_DEL2_LEN      equ     $ - p_del2
;@end
;@ex net.open.http_put_h
rq_opputh:                              ; mode 14
        FNREQ   DEV_NETWORK+2, NET_OPEN, F_A1_A2, 14,0,0,0
        FNBUF   p_puth, P_PUTH_LEN, 0, 0
p_puth:
        defm    "N3:HTTP://127.0.0.1:7802/puth.txt", 0
P_PUTH_LEN      equ     $ - p_puth
rq_wputh:
        FNREQ   DEV_NETWORK+2, NET_WRITE, F_B12, P_PUTHB_LEN,0,0,0
        FNBUF   p_puthb, P_PUTHB_LEN, 0, 0
p_puthb:
        defm    "PUT or POST?"
P_PUTHB_LEN     equ     $ - p_puthb
;@end

;---------------------------------------------------------- unit 4 ----
;@ex net.open.http_get_h
rq_opgeth:                              ; mode 12: GET, headers
        FNREQ   DEV_NETWORK+3, NET_OPEN, F_A1_A2, 12,0,0,0
        FNBUF   p_geth, P_GETH_LEN, 0, 0
p_geth:
        defm    "N4:HTTP://127.0.0.1:7802/hello.txt", 0
P_GETH_LEN      equ     $ - p_geth
;@end
;@ex net.set_http_mode.set_headers
rq_mseth:                               ; mode 3: set headers
        FNREQ   DEV_NETWORK+3, NET_SET_HTTP_MODE, F_A1_A2, 0,3,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex net.write.header
rq_whead:                               ; one space after the colon
        FNREQ   DEV_NETWORK+3, NET_WRITE, F_B12, P_HEAD_LEN,0,0,0
        FNBUF   p_head, P_HEAD_LEN, 0, 0
p_head:
        defm    "X-Machine: H89"
P_HEAD_LEN      equ     $ - p_head
;@end
;@ex net.set_http_mode.collect
rq_mcoll:                               ; mode 1: collect headers
        FNREQ   DEV_NETWORK+3, NET_SET_HTTP_MODE, F_A1_A2, 0,1,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex net.write.collect
rq_wcoll1:
        FNREQ   DEV_NETWORK+3, NET_WRITE, F_B12, P_COLL1_LEN,0,0,0
        FNBUF   p_coll1, P_COLL1_LEN, 0, 0
p_coll1:
        defm    "X-Test-Server"
P_COLL1_LEN     equ     $ - p_coll1
rq_wcoll2:
        FNREQ   DEV_NETWORK+3, NET_WRITE, F_B12, P_COLL2_LEN,0,0,0
        FNBUF   p_coll2, P_COLL2_LEN, 0, 0
p_coll2:
        defm    "Content-Type"
P_COLL2_LEN     equ     $ - p_coll2
;@end
;@ex net.set_http_mode.get_headers
rq_mgeth:                               ; mode 2: get headers
        FNREQ   DEV_NETWORK+3, NET_SET_HTTP_MODE, F_A1_A2, 0,2,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex net.read.header
rq_st4:
        FNREQ   DEV_NETWORK+3, NET_STATUS, F_NONE, 0,0,0,0
        FNBUF   0, 0, nstat, 4
rq_rd4:
        FNREQ   DEV_NETWORK+3, NET_READ, F_B12, 0,0,0,0
        FNBUF   0, 0, buf, BUFSZ
;@end
rq_close4:
        FNREQ   DEV_NETWORK+3, NET_CLOSE, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0

;---------------------------------------------------------- unit 5 ----
;@ex net.open.tcp
rq_optcp:                               ; mode 12: read and write
        FNREQ   DEV_NETWORK+4, NET_OPEN, F_A1_A2, 12,0,0,0
        FNBUF   p_tcp, P_TCP_LEN, 0, 0
p_tcp:
        defm    "N5:TCP://127.0.0.1:7801/", 0
P_TCP_LEN       equ     $ - p_tcp
;@end
;@ex net.status.tcp
rq_st5:
        FNREQ   DEV_NETWORK+4, NET_STATUS, F_NONE, 0,0,0,0
        FNBUF   0, 0, nstat, 4
;@end
;@ex net.read.tcp
rq_rd5:
        FNREQ   DEV_NETWORK+4, NET_READ, F_B12, 0,0,0,0
        FNBUF   0, 0, buf, BUFSZ
;@end
;@ex net.write
rq_wr5:                                 ; the length is a word field
        FNREQ   DEV_NETWORK+4, NET_WRITE, F_B12, P_LINE_LEN,0,0,0
        FNBUF   p_line, P_LINE_LEN, 0, 0
p_line:
        defm    "hello from the h89", 13
P_LINE_LEN      equ     $ - p_line
;@end
;@ex net.status.hangup
rq_wbye:
        FNREQ   DEV_NETWORK+4, NET_WRITE, F_B12, P_BYE_LEN,0,0,0
        FNBUF   p_bye, P_BYE_LEN, 0, 0
p_bye:
        defm    "BYE", 13
P_BYE_LEN       equ     $ - p_bye
;@end
rq_close5:
        FNREQ   DEV_NETWORK+4, NET_CLOSE, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0

;---------------------------------------------------------- unit 6 ----
;@ex net.open.tcp_server
rq_opsrv:                               ; no host: listen
        FNREQ   DEV_NETWORK+5, NET_OPEN, F_A1_A2, 12,0,0,0
        FNBUF   p_srv, P_SRV_LEN, 0, 0
p_srv:
        defm    "N6:TCP://:7803/", 0
P_SRV_LEN       equ     $ - p_srv
;@end
;@ex net.status.listen
rq_st6:
        FNREQ   DEV_NETWORK+5, NET_STATUS, F_NONE, 0,0,0,0
        FNBUF   0, 0, nstat, 4
;@end
;@ex net.accept
rq_accept:
        FNREQ   DEV_NETWORK+5, NET_ACCEPT, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex net.read.server
rq_rd6:
        FNREQ   DEV_NETWORK+5, NET_READ, F_B12, 0,0,0,0
        FNBUF   0, 0, buf, BUFSZ
;@end
;@ex net.write.server
rq_wr6:
        FNREQ   DEV_NETWORK+5, NET_WRITE, F_B12, P_PONG_LEN,0,0,0
        FNBUF   p_pong, P_PONG_LEN, 0, 0
p_pong:
        defm    "PONG", 13, 10
P_PONG_LEN      equ     $ - p_pong
;@end
;@ex net.close_client
rq_cclient:
        FNREQ   DEV_NETWORK+5, NET_CLOSE_CLIENT, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
rq_close6:
        FNREQ   DEV_NETWORK+5, NET_CLOSE, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0

;---------------------------------------------------------- unit 7 ----
;@ex net.open.udp
rq_opudp:                               ; no host: take datagrams
        FNREQ   DEV_NETWORK+6, NET_OPEN, F_A1_A2, 12,0,0,0
        FNBUF   p_udp, P_UDP_LEN, 0, 0
p_udp:
        defm    "N7:UDP://:7804/", 0
P_UDP_LEN       equ     $ - p_udp
;@end
;@ex net.get_remote
rq_remote:                              ; always 256 bytes back
        FNREQ   DEV_NETWORK+6, NET_GET_REMOTE, F_NONE, 0,0,0,0
        FNBUF   0, 0, remote, 256
;@end
;@ex net.read.udp
rq_st7:
        FNREQ   DEV_NETWORK+6, NET_STATUS, F_NONE, 0,0,0,0
        FNBUF   0, 0, nstat, 4
rq_rd7:                                 ; up to 512 bytes (0200H)
        FNREQ   DEV_NETWORK+6, NET_READ, F_B12, 0,2,0,0
        FNBUF   0, 0, buf, BUFSZ
;@end
;@ex net.set_destination
rq_dest:                                ; "N:host:port", with a NUL
        FNREQ   DEV_NETWORK+6, NET_SET_DESTINATION, F_NONE, 0,0,0,0
        FNBUF   p_dest, P_DEST_LEN, 0, 0
p_dest:
        defm    "N:127.0.0.1:7805", 0
P_DEST_LEN      equ     $ - p_dest
;@end
;@ex net.write.udp
rq_wr7:
        FNREQ   DEV_NETWORK+6, NET_WRITE, F_B12, P_UPONG_LEN,0,0,0
        FNBUF   p_upong, P_UPONG_LEN, 0, 0
p_upong:
        defm    "PONG"
P_UPONG_LEN     equ     $ - p_upong
;@end
rq_close7:
        FNREQ   DEV_NETWORK+6, NET_CLOSE, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0

;---------------------------------------------------------- unit 8 ----
;@ex net.open.dir
rq_opdir:                               ; mode 6: a directory; 0:
        FNREQ   DEV_NETWORK+7, NET_OPEN, F_A1_A2, 6,0,0,0
        FNBUF   p_dir, P_DIR_LEN, 0, 0  ; the short form
p_dir:
        defm    "N8:SD:/test/", 0
P_DIR_LEN       equ     $ - p_dir
;@end
;@ex net.read.dir
rq_st8:
        FNREQ   DEV_NETWORK+7, NET_STATUS, F_NONE, 0,0,0,0
        FNBUF   0, 0, nstat, 4
rq_rd8:
        FNREQ   DEV_NETWORK+7, NET_READ, F_B12, 0,0,0,0
        FNBUF   0, 0, buf, BUFSZ
;@end
;@ex net.open.write
rq_opwr:                                ; mode 8: write (a new file)
        FNREQ   DEV_NETWORK+7, NET_OPEN, F_A1_A2, 8,0,0,0
        FNBUF   p_wr, P_WR_LEN, 0, 0
p_wr:
        defm    "N8:SD:/test/h89.txt", 0
P_WR_LEN        equ     $ - p_wr
;@end
;@ex net.write.file
rq_wfile:
        FNREQ   DEV_NETWORK+7, NET_WRITE, F_B12, P_TEXT_LEN,0,0,0
        FNBUF   p_text, P_TEXT_LEN, 0, 0
p_text:
        defm    "Written by an H89.", 13, 10
P_TEXT_LEN      equ     $ - p_text
;@end
;@ex net.close.file
rq_close8:
        FNREQ   DEV_NETWORK+7, NET_CLOSE, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex net.open.file
rq_opimg:                               ; mode 4: read
        FNREQ   DEV_NETWORK+7, NET_OPEN, F_A1_A2, 4,0,0,0
        FNBUF   p_img, P_IMG_LEN, 0, 0
p_img:
        defm    "N8:SD:/test/disk.img", 0
P_IMG_LEN       equ     $ - p_img
;@end
;@ex net.seek
rq_seek:                                ; a long: 1536 = 00000600H
        FNREQ   DEV_NETWORK+7, NET_SEEK, F_C1234, 0,6,0,0
        FNBUF   0, 0, 0, 0
rq_rd8x:
        FNREQ   DEV_NETWORK+7, NET_READ, F_B12, 8,0,0,0
        FNBUF   0, 0, buf, BUFSZ
;@end
;@ex net.tell
rq_tell:                                ; a long back
        FNREQ   DEV_NETWORK+7, NET_TELL, F_NONE, 0,0,0,0
        FNBUF   0, 0, pos, 4
;@end
;@ex net.rename
rq_rename:                              ; old name, comma, new name
        FNREQ   DEV_NETWORK+7, NET_RENAME, F_A1_A2, 0,0,0,0
        FNBUF   p_ren, P_REN_LEN, 0, 0
p_ren:
        defm    "N8:SD:/test/h89.txt,h89new.txt", 0
P_REN_LEN       equ     $ - p_ren
;@end
;@ex net.delete
rq_delete:
        FNREQ   DEV_NETWORK+7, NET_DELETE, F_A1_A2, 0,0,0,0
        FNBUF   p_del3, P_DEL3_LEN, 0, 0
p_del3:
        defm    "N8:SD:/test/h89new.txt", 0
P_DEL3_LEN      equ     $ - p_del3
;@end
;@ex net.mkdir
rq_mkdir:
        FNREQ   DEV_NETWORK+7, NET_MKDIR, F_A1_A2, 0,0,0,0
        FNBUF   p_newdir, P_NEWDIR_LEN, 0, 0
p_newdir:
        defm    "N8:SD:/test/newdir", 0
P_NEWDIR_LEN    equ     $ - p_newdir
;@end
;@ex net.rmdir
rq_rmdir:
        FNREQ   DEV_NETWORK+7, NET_RMDIR, F_A1_A2, 0,0,0,0
        FNBUF   p_newdir, P_NEWDIR_LEN, 0, 0
;@end
;@ex net.lock
rq_lock:
        FNREQ   DEV_NETWORK+7, NET_LOCK, F_A1_A2, 0,0,0,0
        FNBUF   p_readme, P_README_LEN, 0, 0
p_readme:
        defm    "N8:SD:/test/readme.txt", 0
P_README_LEN    equ     $ - p_readme
;@end
;@ex net.unlock
rq_unlock:
        FNREQ   DEV_NETWORK+7, NET_UNLOCK, F_A1_A2, 0,0,0,0
        FNBUF   p_readme, P_README_LEN, 0, 0
;@end
;@ex net.chdir
rq_chdir:
        FNREQ   DEV_NETWORK+7, NET_CHDIR, F_NONE, 0,0,0,0
        FNBUF   p_test, P_TEST_LEN, 0, 0
p_test:
        defm    "N8:SD:/test/", 0
P_TEST_LEN      equ     $ - p_test
;@end
;@ex net.getcwd
rq_getcwd:
        FNREQ   DEV_NETWORK+7, NET_GETCWD, F_NONE, 0,0,0,0
        FNBUF   0, 0, cwd, 256
;@end
;@ex net.open.relative
rq_oprel:
        FNREQ   DEV_NETWORK+7, NET_OPEN, F_A1_A2, 4,0,0,0
        FNBUF   p_rel, P_REL_LEN, 0, 0
p_rel:
        defm    "N8:readme.txt", 0
P_REL_LEN       equ     $ - p_rel
;@end

;----------------------------------------------- unit 1: settings ----
;@ex net.username
rq_user:                                ; just the name
        FNREQ   DEV_NETWORK, NET_USERNAME, F_NONE, 0,0,0,0
        FNBUF   p_user, P_USER_LEN, 0, 0
p_user:
        defm    "h89user"
P_USER_LEN      equ     $ - p_user
;@end
;@ex net.password
rq_pass:
        FNREQ   DEV_NETWORK, NET_PASSWORD, F_NONE, 0,0,0,0
        FNBUF   p_pass, P_PASS_LEN, 0, 0
p_pass:
        defm    "swordfish"
P_PASS_LEN      equ     $ - p_pass
;@end
;@ex net.set_eol
rq_seteol:                              ; the payload is the line end
        FNREQ   DEV_NETWORK, NET_SET_EOL, F_NONE, 0,0,0,0
        FNBUF   p_cr, 1, 0, 0
p_cr:
        defb    13
;@end
;@ex net.translation
rq_xlat:                                ; field 2: 3 = CR LF
        FNREQ   DEV_NETWORK, NET_TRANSLATION, F_A1_A2, 0,3,0,0
        FNBUF   0, 0, 0, 0
;@end
rq_xlat0:
        FNREQ   DEV_NETWORK, NET_TRANSLATION, F_A1_A2, 0,0,0,0
        FNBUF   0, 0, 0, 0
rq_eol0:                                ; no payload: CR LF again
        FNREQ   DEV_NETWORK, NET_SET_EOL, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@ex net.set_int_rate
rq_irate:
        FNREQ   DEV_NETWORK, NET_SET_INT_RATE, F_A1, 100,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex net.open.refused
rq_opbad:
        FNREQ   DEV_NETWORK, NET_OPEN, F_A1_A2, 12,0,0,0
        FNBUF   p_bad, P_BAD_LEN, 0, 0
p_bad:
        defm    "N1:TCP://127.0.0.1:1/", 0
P_BAD_LEN       equ     $ - p_bad
;@end
;@ex net.get_error
rq_geterr:
        FNREQ   DEV_NETWORK, NET_GET_ERROR, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end

;------------------------------------------------------------- data ----
nstat:          defs    4               ; STATUS's answer
pos:            defs    4               ; TELL: the position
total:          defw    0
wt_rq:          defw    0
remote:         defs    256             ; GET_REMOTE's answer
cwd:            defs    256             ; GETCWD's answer
buf:            defs    BUFSZ

INCLUDE "mark.inc"
INCLUDE "card.inc"
INCLUDE "fujibus.inc"
INCLUDE "con.inc"
INCLUDE "tail.inc"
