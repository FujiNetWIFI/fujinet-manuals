; netdefs.inc -- the N: (network) device, for the client library.
;
; Device ids from include/fujiDeviceID.h, command bytes from
; include/fujiCommandID.h, open modes from lib/network-protocol/HTTP.cpp and
; the dispatch table and STATUS reply from lib/device/NDevice/NDevice.cpp.
; The bring-up's fujinet.inc covers the FUJI device only; this is the rest of
; what a client that talks to the network needs, kept separate so that file
; stays verbatim.
NETDEV  =       $71             ; N1: (N2:-N8: are $72-$78)
NCOPEN  =       $4F             ; 'O' open: params mode, translation; payload = devicespec
NCCLOSE =       $43             ; 'C' close
NCREAD  =       $52             ; 'R' read: ONE two-byte param, the count
NCWRITE =       $57             ; 'W' write: ONE two-byte param, then the payload
NCSTAT  =       $53             ; 'S' status: two one-byte params, both 0
NCPARSE =       $50             ; 'P' parse the reply as JSON
NCQUERY =       $51             ; 'Q' query a JSON path; payload = the path
NCPRSR  =       $FC             ; SET_PARSER: second param 0 none, 1 JSON, 2 HTML, 3 XML
NCJSON  =       NCPRSR
NCSETP  =       $FB             ; SET_PARAMETER: params type (0 query flags, 1 EOL), value
NCTRANS =       $54             ; 'T' translation: second param the code
NCEOL   =       $4C             ; 'L' set the EOL: payload the string
NCRATE  =       $5A             ; 'Z' interrupt rate: param the rate
NCSEEK  =       $25             ; '%' seek: ONE four-byte param, the offset
NCTELL  =       $26             ; '&' tell: reply 4 bytes
NCREN   =       $20             ; rename: params mode, 0; payload "N:...old,new"
NCDEL   =       $21             ; '!' delete      \
NCLOCK  =       $23             ; '#' lock         |
NCUNLK  =       $24             ; '$' unlock       | params mode, 0;
NCMKDIR =       $2A             ; '*' mkdir        | payload the devicespec
NCRMDIR =       $2B             ; '+' rmdir       /
NCCHDIR =       $2C             ; ',' chdir: payload the path
NCGETCW =       $30             ; '0' getcwd: reply the prefix
NCACCPT =       $41             ; 'A' accept a TCP client
NCCCLI  =       $63             ; 'c' close the TCP client
NCRMT   =       $72             ; 'r' UDP: who sent the last datagram
NCDEST  =       $44             ; 'D' UDP: payload host:port
NCUSER  =       $FD             ; payload the user name
NCPASS  =       $FE             ; payload the password
NPNONE  =       0               ; parsers
NPJSON  =       1
NPHTML  =       2
NPXML   =       3
NCHTTPM =       $4D             ; 'M' HTTP channel mode: second param 0 body, 1 collect
                                ;   headers, 2 get headers, 3 set headers, 4 POST data
NMREAD  =       4               ; open mode: read (HTTP GET)
NMWRITE =       8               ; write (HTTP PUT)
NMHTTPG =       12              ; read/write (HTTP GET, headers allowed)
NMPOST  =       13              ; HTTP POST
NTRNONE =       0               ; translation: none
NTRCR   =       1               ; CR to/from the host's EOL
NTRLF   =       2               ; LF
NTRCRLF =       3               ; CR LF
NSAVLO  =       0               ; STATUS reply: bytes waiting, low
NSAVHI  =       1               ;   high
NSCONN  =       2               ;   connected
NSDEVST =       3               ;   nDevStatus_t: 1 = success
