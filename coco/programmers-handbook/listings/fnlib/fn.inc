***************************************************************
* FN.INC --- FujiNet equates for the TRS-80 Color Computer
*
* Every value here is transcribed from the FujiNet firmware:
*   opcodes  ... lib/bus/drivewire/opcode.h
*   commands ... include/fujiCommandID.h
*   errors   ... lib/network-protocol/status_error_codes.h
*
* Assemble with lwasm.  Include this before FNLOW.ASM.
***************************************************************

* --- DriveWire ROM vectors ----------------------------------
* Disk BASIC keeps the DriveWire entry points in two indirect
* vectors.  X holds the buffer, Y holds the count.
DWREADV EQU     $D93F           READ  --- JSR [DWREADV]
DWWRITV EQU     $D941           WRITE --- JSR [DWWRITV]

* --- DriveWire opcodes --------------------------------------
OPNOP   EQU     $00             do nothing
OPNAMOB EQU     $01             named object mount (Dragon)
OPTIME  EQU     $23             '#'  six-byte clock reply
OPSERRD EQU     $43             'C'  read a virtual serial byte
OPSGSTA EQU     $44             'D'  serial get status
OPSERIN EQU     $45             'E'  serial init
OPPRTFL EQU     $46             'F'  printer flush (ignored)
OPGSTAT EQU     $47             'G'  get status
OPINIT  EQU     $49             'I'  init
OPPRINT EQU     $50             'P'  one byte to the printer
OPSSTAT EQU     $53             'S'  set status
OPTERM  EQU     $54             'T'  terminate
OPWRITE EQU     $57             'W'  write one 256-byte block
OPDWINI EQU     $5A             'Z'  DWINIT --- replies $04
OPSERRM EQU     $63             'c'  serial read multiple
OPSERWM EQU     $64             serial write multiple
OPFASTW EQU     $80             $80-$8F fast write, vchan in low nybble
OPJEFF  EQU     $A5             replies with the string "FUJINET"
OPSERWR EQU     $C3             serial write one byte
OPSSSTA EQU     $C4             serial set status
OPSERTM EQU     $C5             serial terminate
OPREADX EQU     $D2             READEX --- read one 256-byte block
OPFUJI  EQU     $E2             the FujiNet control device
OPNET   EQU     $E3             the N: network devices
OPCPM   EQU     $E4             the CP/M console
OPCLOCK EQU     $E5             the clock device
OPRREDX EQU     $F2             re-read
OPRST3  EQU     $F8             reset
OPRST2  EQU     $FE             reset
OPRST1  EQU     $FF             reset

* --- the three bus meta-commands ----------------------------
* These are answered by the bus itself, ahead of any device.
FNREADY EQU     $00             are you there?     --- replies $01
FNRESP  EQU     $01             send the response
FNERROR EQU     $02             send the error byte

* --- FUJI device commands ($E2) -----------------------------
FCRESET EQU     $FF             reboot the adapter
FCGSSID EQU     $FE             get the stored SSID and password
FCSCAN  EQU     $FD             scan for networks
FCSCANR EQU     $FC             get one scan result
FCSSSID EQU     $FB             set SSID and password, and join
FCWIFST EQU     $FA             get WiFi status
FCMNTHS EQU     $F9             mount a host slot
FCMNTIM EQU     $F8             mount a disk image
FCOPNDR EQU     $F7             open a directory
FCRDDIR EQU     $F6             read one directory entry
FCCLSDR EQU     $F5             close the directory
FCRDHS  EQU     $F4             read the eight host slots
FCWRHS  EQU     $F3             write the eight host slots
FCRDDS  EQU     $F2             read the four device slots
FCWRDS  EQU     $F1             write the four device slots
FCWIFEN EQU     $EA             is WiFi enabled?
FCUNMIM EQU     $E9             unmount a disk image
FCADCFG EQU     $E8             get the adapter configuration
FCNEWDK EQU     $E7             create a new blank disk
FCUNMHS EQU     $E6             unmount a host slot
FCGDIRP EQU     $E5             get the directory position
FCSDIRP EQU     $E4             set the directory position
FCSDVFP EQU     $E2             set a device slot's full path
FCSHPFX EQU     $E1             set a host prefix
FCGHPFX EQU     $E0             get a host prefix
FCWRAPK EQU     $DE             write the open app key
FCRDAPK EQU     $DD             read the open app key
FCOPAPK EQU     $DC             open an app key
FCCLAPK EQU     $DB             close the app key
FCGDVFP EQU     $DA             get a device slot's full path
FCCFGBT EQU     $D9             enable or disable the CONFIG disk
FCCOPYF EQU     $D8             copy a file between hosts
FCMNTAL EQU     $D7             mount everything in the slots
FCSBOOT EQU     $D6             set the boot mode
FCRANDM EQU     $D3             get four random bytes
FCB64EI EQU     $D0             base64 encode: input
FCB64EC EQU     $CF             base64 encode: compute
FCB64EL EQU     $CE             base64 encode: length
FCB64EO EQU     $CD             base64 encode: output
FCB64DI EQU     $CC             base64 decode: input
FCB64DC EQU     $CB             base64 decode: compute
FCB64DL EQU     $CA             base64 decode: length
FCB64DO EQU     $C9             base64 decode: output
FCHASHI EQU     $C8             hash: input
FCHASHC EQU     $C7             hash: compute and clear
FCHASHL EQU     $C6             hash: length
FCHASHO EQU     $C5             hash: output
FCADCFX EQU     $C4             get the extended adapter config
FCHASHN EQU     $C3             hash: compute, keep the input
FCHASHZ EQU     $C2             hash: clear
FCQROUT EQU     $BF             QR code: output
FCQRLEN EQU     $BE             QR code: length
FCQRENC EQU     $BD             QR code: encode
FCQRINP EQU     $BC             QR code: input
FCGUID  EQU     $BB             generate a UUID
FCSTAT  EQU     $53             'S'  status (a four-byte stub)

* --- NETWORK device commands ($E3) --------------------------
NCRENAM EQU     $20             ' '  rename a file
NCDELET EQU     $21             '!'  delete a file
NCLOCK  EQU     $23             '#'  lock a file
NCUNLCK EQU     $24             '$'  unlock a file
NCSEEK  EQU     $25             '%'  seek
NCTELL  EQU     $26             '&'  tell
NCMKDIR EQU     $2A             '*'  make a directory
NCRMDIR EQU     $2B             '+'  remove a directory
NCCHDIR EQU     $2C             ','  change the prefix
NCGETCW EQU     $30             '0'  get the prefix
NCACCPT EQU     $41             'A'  accept a TCP connection
NCCLOSE EQU     $43             'C'  close the channel
NCSETDE EQU     $44             'D'  set the UDP destination
NCSETEL EQU     $4C             'L'  set the end-of-line string
NCHTTPM EQU     $4D             'M'  set the HTTP channel mode
NCOPEN  EQU     $4F             'O'  open a channel
NCPARSE EQU     $50             'P'  parse the channel contents
NCQUERY EQU     $51             'Q'  query the parsed document
NCREAD  EQU     $52             'R'  read from the channel
NCSTAT  EQU     $53             'S'  status
NCTRANS EQU     $54             'T'  set the translation mode
NCWRITE EQU     $57             'W'  write to the channel
NCINTRT EQU     $5A             'Z'  set the interrupt rate
NCCLCLI EQU     $63             'c'  close the accepted client
NCGTREM EQU     $72             'r'  get the UDP remote address
NCSPARM EQU     $FB             set a parser parameter
NCSPARS EQU     $FC             set the parser mode

* --- open modes, aux1 of NCOPEN -----------------------------
OMREAD  EQU     4               read
OMDIR   EQU     6               directory
OMDIRA  EQU     7               directory, alternate form
OMWRITE EQU     8               write
OMAPPND EQU     9               append
OMRW    EQU     12              read and write
* the same byte carries the HTTP method
OMHGET  EQU     4               GET
OMHDEL  EQU     5               DELETE
OMHPUT  EQU     8               PUT
OMHDELH EQU     9               DELETE, collecting headers
OMHGETH EQU     12              GET, collecting headers
OMHPOST EQU     13              POST
OMHPUTH EQU     14              PUT, collecting headers

* --- translation modes, aux2 of NCOPEN ----------------------
TRNONE  EQU     0               leave the bytes alone
TRCR    EQU     1               end lines with CR   --- the CoCo's own
TRLF    EQU     2               end lines with LF
TRCRLF  EQU     3               end lines with CR LF
TRPET   EQU     4               PETSCII

* --- parser modes, aux2 of NCSPARS --------------------------
PMNONE  EQU     0               no parser
PMJSON  EQU     1               JSON
PMHTML  EQU     2               HTML, queried with a CSS selector
PMXML   EQU     3               XML, queried with an XPath subset

* --- HTTP channel modes, aux2 of NCHTTPM --------------------
HMBODY  EQU     0               the response body
HMCOLL  EQU     1               collect response headers
HMGETH  EQU     2               read the collected headers
HMSETH  EQU     3               set a request header
HMPOSTD EQU     4               set the POST data

* --- hash algorithms, aux1 of FCHASHC -----------------------
HAMD5   EQU     0
HASHA1  EQU     1
HASHA256 EQU    2
HASHA512 EQU    3

* --- error codes returned by FNERROR ------------------------
ESUCC   EQU     1               success
EWRONLY EQU     131             the channel is write-only
EBADCMD EQU     132             invalid command
ERDONLY EQU     135             the channel is read-only
EEOF    EQU     136             end of file
ETIMOUT EQU     138             general timeout
EGENERL EQU     144             a fatal error
ENOTIMP EQU     146             not implemented
EEXISTS EQU     151             the file exists
ENOSPC  EQU     162             no space left on the device
EBADSPC EQU     165             the devicespec was not understood
EBADPT  EQU     166             invalid seek position
EACCESS EQU     167             access denied
ENOFILE EQU     170             file not found
ECONREF EQU     200             connection refused
ENETUNR EQU     201             network unreachable
ESOCKTO EQU     202             socket timeout
ENETDWN EQU     203             network down
ECONRST EQU     204             connection reset
ECONPRG EQU     205             connection already in progress
EADDRIN EQU     206             address in use
ENOTCON EQU     207             not connected
ENOSERV EQU     208             the server is not running
ENOWAIT EQU     209             no connection waiting
ENOSVC  EQU     210             service not available
ECONABT EQU     211             connection aborted
EBADLOG EQU     212             invalid username or password
EBADJSN EQU     213             could not parse the JSON
ECLIENT EQU     214             general client error
ESERVER EQU     215             general server error
ENOBUFS EQU     255             could not allocate buffers

* --- WiFi status, the reply to FCWIFST ----------------------
WFNOSSID EQU    1               no SSID available
WFCONN  EQU     3               connected
WFFAIL  EQU     4               connection failed
WFLOST  EQU     5               connection lost
WFDISC  EQU     6               disconnected

* --- sizes you will need ------------------------------------
SZHOSTS EQU     256             eight host slots, 32 bytes each
SZDEVS  EQU     152             four device slots, 38 bytes each
SZADCFG EQU     140             AdapterConfig
SZADCFX EQU     240             AdapterConfigExtended
SZSSID  EQU     97              ssid[33] + password[64]
SZSCANR EQU     34              ssid[33] + rssi
SZGUID  EQU     37              a UUID and its terminator
SZAPKEY EQU     64              an app key's payload
SZSPEC  EQU     256             a devicespec, a path, a prefix
