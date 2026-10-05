; fujidefs.inc -- the rest of the FujiBus vocabulary.
;
; fujinet.inc (copied verbatim from the bring-up) names the mailbox and the
; handful of commands the bring-up clients needed. These are the others, from
; fujinet-firmware include/fujiDeviceID.h and include/fujiCommandID.h.

; ---------------- devices ----------------
FNDEVC    = $45                 ; the clock (APETIME)
FNDEVP    = $40                 ; the printer
FNDEVM    = $50                 ; the modem (no reply reaches the NES)
FNDEVD    = $31                 ; disk 1 ($31-$38)

; ---------------- Fuji device ($70) ----------------
; (fujinet.inc already has FNCADPX FNCMHST FNCMIMG FNCSDFP FNCRHST FNCODIR
;  FNCRDIR FNCCDIR FNCSDPS)
FNCRESET  = $FF                 ; RESET
FNCGSSID  = $FE                 ; GET_SSID
FNCSCAN   = $FD                 ; SCAN_NETWORKS
FNCSCNR   = $FC                 ; GET_SCAN_RESULT
FNCSSSID  = $FB                 ; SET_SSID
FNCWIFI   = $FA                 ; GET_WIFISTATUS
FNCWHST   = $F3                 ; WRITE_HOST_SLOTS
FNCRDEV   = $F2                 ; READ_DEVICE_SLOTS
FNCWDEV   = $F1                 ; WRITE_DEVICE_SLOTS
FNCWIFEN  = $EA                 ; GET_WIFI_ENABLED
FNCUIMG   = $E9                 ; UNMOUNT_IMAGE
FNCADP    = $E8                 ; GET_ADAPTERCONFIG
FNCNEWD   = $E7                 ; NEW_DISK
FNCUHST   = $E6                 ; UNMOUNT_HOST
FNCGDPS   = $E5                 ; GET_DIRECTORY_POSITION
FNCSPFX   = $E1                 ; SET_HOST_PREFIX
FNCGPFX   = $E0                 ; GET_HOST_PREFIX
FNCWKEY   = $DE                 ; WRITE_APPKEY
FNCRKEY   = $DD                 ; READ_APPKEY
FNCOKEY   = $DC                 ; OPEN_APPKEY
FNCCKEY   = $DB                 ; CLOSE_APPKEY
FNCGDFP   = $DA                 ; GET_DEVICE_FULLPATH
FNCCBOOT  = $D9                 ; CONFIG_BOOT
FNCCOPY   = $D8                 ; COPY_FILE
FNCMALL   = $D7                 ; MOUNT_ALL
FNCBMODE  = $D6                 ; SET_BOOT_MODE
FNCRAND   = $D3                 ; RANDOM_NUMBER
FNCB64EI  = $D0                 ; BASE64_ENCODE_INPUT
FNCB64EC  = $CF                 ; BASE64_ENCODE_COMPUTE
FNCB64EL  = $CE                 ; BASE64_ENCODE_LENGTH
FNCB64EO  = $CD                 ; BASE64_ENCODE_OUTPUT
FNCB64DI  = $CC                 ; BASE64_DECODE_INPUT
FNCB64DC  = $CB                 ; BASE64_DECODE_COMPUTE
FNCB64DL  = $CA                 ; BASE64_DECODE_LENGTH
FNCB64DO  = $C9                 ; BASE64_DECODE_OUTPUT
FNCHIN    = $C8                 ; HASH_INPUT
FNCHCMP   = $C7                 ; HASH_COMPUTE
FNCHLEN   = $C6                 ; HASH_LENGTH
FNCHOUT   = $C5                 ; HASH_OUTPUT
FNCHCNC   = $C3                 ; HASH_COMPUTE_NO_CLEAR
FNCHCLR   = $C2                 ; HASH_CLEAR
FNCQOUT   = $BF                 ; QRCODE_OUTPUT
FNCQLEN   = $BE                 ; QRCODE_LENGTH
FNCQENC   = $BD                 ; QRCODE_ENCODE
FNCQIN    = $BC                 ; QRCODE_INPUT
FNCGUID   = $BB                 ; GENERATE_GUID
FNCSTAT   = $53                 ; STATUS
FNCREADY  = $00                 ; DEVICE_READY

; ---------------- Network device ($71-$78) ----------------
NCOPEN    = 'O'                 ; $4F  open a URL
NCCLOSE   = 'C'                 ; $43  close
NCREAD    = 'R'                 ; $52  read n bytes
NCWRITE   = 'W'                 ; $57  write n bytes
NCSTAT    = 'S'                 ; $53  status: avail lo, avail hi, conn, err
NCPARSE   = 'P'                 ; $50  parse the response
NCQUERY   = 'Q'                 ; $51  select a path in the parsed response
NCPARSER  = $FC                 ; SET_PARSER: 0 none 1 JSON 2 HTML 3 XML
NCPARAM   = $FB                 ; SET_PARAMETER
NCTRANS   = 'T'                 ; $54  translation override
NCEOL     = 'L'                 ; $4C  set end-of-line bytes
NCINTR    = 'Z'                 ; $5A  interrupt rate (no use on the NES)
NCSEEK    = '%'                 ; $25
NCTELL    = '&'                 ; $26
NCGETCWD  = '0'                 ; $30
NCCHDIR   = ','                 ; $2C
NCUSER    = $FD                 ; username for the next OPEN
NCPASS    = $FE                 ; password for the next OPEN
NCRENAME  = $20
NCDELETE  = '!'                 ; $21
NCLOCK    = '#'                 ; $23
NCUNLOCK  = '$'                 ; $24
NCMKDIR   = '*'                 ; $2A
NCRMDIR   = '+'                 ; $2B
NCACCEPT  = 'A'                 ; $41
NCCLCLI   = 'c'                 ; $63  close the accepted client
NCHTTPM   = 'M'                 ; $4D  HTTP channel mode
NCREMOTE  = 'r'                 ; $72  UDP sender (NAKs on the ESP32)
NCDEST    = 'D'                 ; $44  UDP destination

; OPEN modes (param 0)
NMREAD    = 4                   ; read  (HTTP GET)
NMDEL     = 5                   ; HTTP DELETE
NMDIR     = 6                   ; directory
NMWRITE   = 8                   ; write (HTTP PUT)
NMAPPEND  = 9
NMRW      = 12                  ; read/write (TCP); HTTP GET with headers
NMPOST    = 13                  ; HTTP POST

; ---------------- Clock ($45) ----------------
CLKTIME   = $93                 ; GETTIME: 6 bytes D M Y H M S
CLKTZT    = $9A                 ; GETTZTIME: the same, alternate zone
CLKSIMP   = 'T'                 ; $54  simple: century Y M D h m s
CLKHUND   = 'M'                 ; $4D  simple + hundredths
CLKPRODOS = 'P'                 ; $50
CLKSOS    = 'S'                 ; $53
CLKISO    = 'I'                 ; $49  ISO 8601, FujiNet's zone
CLKUTC    = 'Z'                 ; $5A  ISO 8601, UTC
CLKGTZ    = 'G'                 ; $47  the zone string
CLKTZLEN  = 'L'                 ; $4C  its length + 1
CLKSETA   = $99                 ; SETTZ: the alternate zone (RAM only)
CLKSETS   = 't'                 ; $74  SETTZ_ALT: the system zone (saved)

; ---------------- Disk ($31-$38) and printer ($40) ----------------
DKREAD    = 'R'                 ; read a 512-byte sector
DKPUT     = 'P'                 ; write without verify
DKWRITE   = 'W'                 ; write with verify
PRWRITE   = 'W'                 ; print the payload
PRSTAT    = 'S'

; ---------------- replies ----------------
FNACK     = $06                 ; FN_RCMD after a good answer
FNNAK     = $15
