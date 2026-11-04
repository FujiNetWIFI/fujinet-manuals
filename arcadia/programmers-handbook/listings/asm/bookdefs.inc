; bookdefs.inc -- the devices and commands the runtime's fujilib.inc does
; not name, for this handbook's programs. Every equate's comment carries
; the firmware's own name (include/fujiDeviceID.h, fujiCommandID.h, at the
; book's pin); tools/defcheck.py compares the values. Kept apart so the
; runtime stays verbatim. Include after fujilib.inc.

; ---- devices --------------------------------------------------------
DVDISK  EQU     $31             ; DISK (D1:; D2:-D8: are $32-$38)
DVPRN   EQU     $40             ; PRINTER
DVCLOCK EQU     $45             ; CLOCK
DVMODEM EQU     $50             ; SERIAL
DVNET   EQU     $71             ; NETWORK (N1:; N2:-N8: are $72-$78)

; ---- FUJI ($70) commands fujilib.inc does not name -----------------
FCRESET EQU     $FF             ; RESET
FCGSSID EQU     $FE             ; GET_SSID
FCSCAN  EQU     $FD             ; SCAN_NETWORKS
FCSCANR EQU     $FC             ; GET_SCAN_RESULT
FCSSSID EQU     $FB             ; SET_SSID
FCWIFIS EQU     $FA             ; GET_WIFISTATUS
FCWHSL  EQU     $F3             ; WRITE_HOST_SLOTS
FCRDSL  EQU     $F2             ; READ_DEVICE_SLOTS
FCWDSL  EQU     $F1             ; WRITE_DEVICE_SLOTS
FCWIFIE EQU     $EA             ; GET_WIFI_ENABLED
FCUIMG  EQU     $E9             ; UNMOUNT_IMAGE
FCACFG  EQU     $E8             ; GET_ADAPTERCONFIG
FCNEWD  EQU     $E7             ; NEW_DISK
FCUHOST EQU     $E6             ; UNMOUNT_HOST
FCGDPOS EQU     $E5             ; GET_DIRECTORY_POSITION
FCSHPFX EQU     $E1             ; SET_HOST_PREFIX
FCGHPFX EQU     $E0             ; GET_HOST_PREFIX
FCAKWR  EQU     $DE             ; WRITE_APPKEY
FCAKRD  EQU     $DD             ; READ_APPKEY
FCAKOP  EQU     $DC             ; OPEN_APPKEY
FCAKCL  EQU     $DB             ; CLOSE_APPKEY
FCGDFP  EQU     $DA             ; GET_DEVICE_FULLPATH
FCCBOOT EQU     $D9             ; CONFIG_BOOT
FCCOPY  EQU     $D8             ; COPY_FILE
FCMALL  EQU     $D7             ; MOUNT_ALL
FCSBOOT EQU     $D6             ; SET_BOOT_MODE
FCRAND  EQU     $D3             ; RANDOM_NUMBER
FCB64EI EQU     $D0             ; BASE64_ENCODE_INPUT
FCB64EC EQU     $CF             ; BASE64_ENCODE_COMPUTE
FCB64EL EQU     $CE             ; BASE64_ENCODE_LENGTH
FCB64EO EQU     $CD             ; BASE64_ENCODE_OUTPUT
FCB64DI EQU     $CC             ; BASE64_DECODE_INPUT
FCB64DC EQU     $CB             ; BASE64_DECODE_COMPUTE
FCB64DL EQU     $CA             ; BASE64_DECODE_LENGTH
FCB64DO EQU     $C9             ; BASE64_DECODE_OUTPUT
FCHSHI  EQU     $C8             ; HASH_INPUT
FCHSHC  EQU     $C7             ; HASH_COMPUTE
FCHSHL  EQU     $C6             ; HASH_LENGTH
FCHSHO  EQU     $C5             ; HASH_OUTPUT
FCHSHN  EQU     $C3             ; HASH_COMPUTE_NO_CLEAR
FCHSHX  EQU     $C2             ; HASH_CLEAR
FCQRO   EQU     $BF             ; QRCODE_OUTPUT
FCQRL   EQU     $BE             ; QRCODE_LENGTH
FCQRE   EQU     $BD             ; QRCODE_ENCODE
FCQRI   EQU     $BC             ; QRCODE_INPUT
FCGUID  EQU     $BB             ; GENERATE_GUID
FCSTAT  EQU     $53             ; STATUS
FCREADY EQU     $00             ; DEVICE_READY

; ---- app keys --------------------------------------------------------
; OPEN_APPKEY's payload is one six-byte struct: the creator (2 bytes,
; low first), the app, the key, the mode, and a reserved 0 that is not
; optional.
AKMREAD EQU     0               ; mode: read
AKMWRIT EQU     1               ; mode: write
AKCREAT EQU     $0001           ; the shared user-name key: creator 1,
AKAPP   EQU     $01             ; app 1, key 0, which every FujiNet game
AKKEY   EQU     $00             ; reads the player's name from

; ---- the clock ($45) ----------------------------------------------------
CKGTIME EQU     $93             ; GETTIME
CKISOL  EQU     $49             ; GET_ISO_LOCAL
CKISOU  EQU     $5A             ; GET_ISO_UTC
CKTZLEN EQU     $4C             ; GETTZ_LEN
CKSETTZ EQU     $99             ; SETTZ
CKSETTA EQU     $74             ; SETTZ_ALT
CKTZTIM EQU     $9A             ; GETTZTIME

; ---- hash algorithms (HASH_COMPUTE's parameter) ----------------------------
HAMD5   EQU     0
HASHA1  EQU     1
HASH256 EQU     3
HASH512 EQU     4

; ---- the N: device ($71-$78) ----------------------------------------------
NCOPEN  EQU     $4F             ; OPEN
NCCLOSE EQU     $43             ; CLOSE
NCREAD  EQU     $52             ; READ
NCWRITE EQU     $57             ; WRITE
NCSTAT  EQU     $53             ; STATUS
NCPARSE EQU     $50             ; PARSE
NCQUERY EQU     $51             ; QUERY
NCPARSR EQU     $FC             ; SET_PARSER
NCSETP  EQU     $FB             ; SET_PARAMETER
NCTRANS EQU     $54             ; TRANSLATION
NCEOL   EQU     $4C             ; SET_EOL
NCRATE  EQU     $5A             ; SET_INT_RATE
NCSEEK  EQU     $25             ; SEEK
NCTELL  EQU     $26             ; TELL
NCRENAM EQU     $20             ; RENAME
NCDEL   EQU     $21             ; DELETE
NCLOCK  EQU     $23             ; LOCK
NCUNLCK EQU     $24             ; UNLOCK
NCMKDIR EQU     $2A             ; MKDIR
NCRMDIR EQU     $2B             ; RMDIR
NCCHDIR EQU     $2C             ; CHDIR
NCGETCW EQU     $30             ; GETCWD
NCACCPT EQU     $41             ; ACCEPT
NCCCLI  EQU     $63             ; CLOSE_CLIENT
NCRMOTE EQU     $72             ; GET_REMOTE
NCDEST  EQU     $44             ; SET_DESTINATION
NCHTTPM EQU     $4D             ; SET_HTTP_MODE
NCGERR  EQU     $45             ; GET_ERROR
NCUSER  EQU     $FD             ; USERNAME
NCPASS  EQU     $FE             ; PASSWORD
NPNONE  EQU     0               ; parsers: none, JSON, HTML, XML
NPJSON  EQU     1
NPHTML  EQU     2
NPXML   EQU     3
NMREAD  EQU     4               ; OPEN modes: read (HTTP GET)
NMWRITE EQU     8               ;   write (HTTP PUT)
NMRDWR  EQU     12              ;   read and write (GET with headers)
NMPOST  EQU     13              ;   HTTP POST
NTRNONE EQU     0               ; translation: none, CR, LF, CR LF
NTRCR   EQU     1
NTRLF   EQU     2
NTRCRLF EQU     3
NSAVLO  EQU     0               ; STATUS reply: bytes waiting, low
NSAVHI  EQU     1               ;   bytes waiting, high
NSCONN  EQU     2               ;   connected (1) or not
NSDEVST EQU     3               ;   device status: 1 is fine
