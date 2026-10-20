; s2defs.inc -- the devices and commands the
; bring-up's fujinet.inc does not name, for this
; handbook's programs. Values from the firmware's
; include/fujiDeviceID.h and fujiCommandID.h;
; tools/defcheck.py compares them. Kept apart so
; fujinet.inc stays verbatim. Include after
; fujinet.inc and s2macro.inc, before any ORG.

; ---- devices ----
DSKDEV  EQU     31H     ; D1: (D2:-D8: $32-$38)
PRNDEV  EQU     40H     ; P1:
CLKDEV  EQU     45H     ; the clock (APETIME)
MDMDEV  EQU     50H     ; R: the modem
NETDEV  EQU     71H     ; N1: (N2:-N8: $72-$78)

; ---- FUJI ($70) commands ----
FNCRST  EQU     0FFH    ; RESET
FNCGSSD EQU     0FEH    ; GET_SSID
FNCSCAN EQU     0FDH    ; SCAN_NETWORKS
FNCSCNR EQU     0FCH    ; GET_SCAN_RESULT
FNCSSSD EQU     0FBH    ; SET_SSID
FNCWIFI EQU     0FAH    ; GET_WIFISTATUS
FNCODIR EQU     0F7H    ; OPEN_DIRECTORY
FNCRDIR EQU     0F6H    ; READ_DIR_ENTRY
FNCCDIR EQU     0F5H    ; CLOSE_DIRECTORY
FNCRHST EQU     0F4H    ; READ_HOST_SLOTS
FNCWHST EQU     0F3H    ; WRITE_HOST_SLOTS
FNCRDEV EQU     0F2H    ; READ_DEVICE_SLOTS
FNCWDEV EQU     0F1H    ; WRITE_DEVICE_SLOTS
FNCWIEN EQU     0EAH    ; GET_WIFI_ENABLED
FNCUIMG EQU     0E9H    ; UNMOUNT_IMAGE
FNCADPC EQU     0E8H    ; GET_ADAPTERCONFIG
FNCNEWD EQU     0E7H    ; NEW_DISK
FNCUHST EQU     0E6H    ; UNMOUNT_HOST
FNCGDPS EQU     0E5H    ; GET_DIRECTORY_POSITION
FNCSDPS EQU     0E4H    ; SET_DIRECTORY_POSITION
FNCSHPX EQU     0E1H    ; SET_HOST_PREFIX
FNCGHPX EQU     0E0H    ; GET_HOST_PREFIX
FNCAKWR EQU     0DEH    ; WRITE_APPKEY
FNCAKRD EQU     0DDH    ; READ_APPKEY
FNCAKOP EQU     0DCH    ; OPEN_APPKEY
FNCAKCL EQU     0DBH    ; CLOSE_APPKEY
FNCGDFP EQU     0DAH    ; GET_DEVICE_FULLPATH
FNCCBOT EQU     0D9H    ; CONFIG_BOOT
FNCCOPY EQU     0D8H    ; COPY_FILE
FNCMALL EQU     0D7H    ; MOUNT_ALL
FNCSBM  EQU     0D6H    ; SET_BOOT_MODE
FNCRAND EQU     0D3H    ; RANDOM_NUMBER
FNCB64EI EQU    0D0H    ; BASE64_ENCODE_INPUT
FNCB64EC EQU    0CFH    ; BASE64_ENCODE_COMPUTE
FNCB64EL EQU    0CEH    ; BASE64_ENCODE_LENGTH
FNCB64EO EQU    0CDH    ; BASE64_ENCODE_OUTPUT
FNCB64DI EQU    0CCH    ; BASE64_DECODE_INPUT
FNCB64DC EQU    0CBH    ; BASE64_DECODE_COMPUTE
FNCB64DL EQU    0CAH    ; BASE64_DECODE_LENGTH
FNCB64DO EQU    0C9H    ; BASE64_DECODE_OUTPUT
FNCHSHI EQU     0C8H    ; HASH_INPUT
FNCHSHC EQU     0C7H    ; HASH_COMPUTE
FNCHSHL EQU     0C6H    ; HASH_LENGTH
FNCHSHO EQU     0C5H    ; HASH_OUTPUT
FNCHSHN EQU     0C3H    ; HASH_COMPUTE_NO_CLEAR
FNCHSHX EQU     0C2H    ; HASH_CLEAR
FNCQRO  EQU     0BFH    ; QRCODE_OUTPUT
FNCQRL  EQU     0BEH    ; QRCODE_LENGTH
FNCQRE  EQU     0BDH    ; QRCODE_ENCODE
FNCQRI  EQU     0BCH    ; QRCODE_INPUT
FNCGUID EQU     0BBH    ; GENERATE_GUID
FNCSTAT EQU     53H     ; STATUS
FNCRDY  EQU     00H     ; DEVICE_READY

; ---- app keys (AppKeyMixin.h) ----
; OPEN_APPKEY's payload is one packed struct:
; creator (2 bytes, low first), app, key, mode,
; and a reserved byte that is not optional.
AKMRD   EQU     0       ; mode: read
AKMWR   EQU     1       ; mode: write
AKCREAT EQU     1       ; the shared user-name key:
AKAPP   EQU     1       ;   creator 1, app 1, key 0,
AKKEY   EQU     0       ;   which every game reads

; ---- the clock ($45) ----
CKGTIME EQU     93H     ; GETTIME: 6 bytes, binary
CKISOL  EQU     49H     ; 'I' GET_ISO_LOCAL
CKISOU  EQU     5AH     ; 'Z' GET_ISO_UTC
CKGEN   EQU     47H     ; 'G' GET_GENERAL
CKTZLEN EQU     4CH     ; 'L' GETTZ_LEN
CKSETTZ EQU     99H     ; SETTZ: payload the TZ
CKTZTIM EQU     9AH     ; GETTZTIME

; ---- hash algorithms (HASH_COMPUTE) ----
HAMD5   EQU     0
HASHA1  EQU     1
HASHA256 EQU    3
HASHA512 EQU    4

; ---- the N: device ($71-$78) ----
NCOPEN  EQU     4FH     ; 'O' mode, trans; spec
NCCLOSE EQU     43H     ; 'C'
NCREAD  EQU     52H     ; 'R' one 2-byte count
NCWRITE EQU     57H     ; 'W' 2-byte count; data
NCSTAT  EQU     53H     ; 'S' two 1-byte zeros
NCPARSE EQU     50H     ; 'P' parse as JSON
NCQUERY EQU     51H     ; 'Q' payload the path
NCPRSR  EQU     0FCH    ; SET_PARSER
NCSETP  EQU     0FBH    ; SET_PARAMETER
NCTRANS EQU     54H     ; 'T' translation
NCEOL   EQU     4CH     ; 'L' set the EOL
NCRATE  EQU     5AH     ; 'Z' interrupt rate
NCSEEK  EQU     25H     ; '%' one 4-byte offset
NCTELL  EQU     26H     ; '&' reply 4 bytes
NCREN   EQU     20H     ; rename "old,new"
NCDEL   EQU     21H     ; '!' delete
NCLOCK  EQU     23H     ; '#' lock
NCUNLK  EQU     24H     ; '$' unlock
NCMKDIR EQU     2AH     ; '*' mkdir
NCRMDIR EQU     2BH     ; '+' rmdir
NCCHDIR EQU     2CH     ; ',' chdir
NCGETCW EQU     30H     ; '0' getcwd
NCACCPT EQU     41H     ; 'A' accept a client
NCCCLI  EQU     63H     ; 'c' close the client
NCRMT   EQU     72H     ; 'r' UDP: who sent it
NCDEST  EQU     44H     ; 'D' UDP: host:port
NCHTTPM EQU     4DH     ; 'M' HTTP channel mode
NCUSER  EQU     0FDH    ; payload the user name
NCPASS  EQU     0FEH    ; payload the password
NPNONE  EQU     0       ; parsers
NPJSON  EQU     1
NPHTML  EQU     2
NPXML   EQU     3
NMREAD  EQU     4       ; open: read (HTTP GET)
NMWRITE EQU     8       ; write (HTTP PUT)
NMHTTPG EQU     12      ; read/write (GET+headers)
NMPOST  EQU     13      ; HTTP POST
NTRNONE EQU     0       ; translation: none
NTRCR   EQU     1       ; CR
NTRLF   EQU     2       ; LF
NTRCRLF EQU     3       ; CR LF
NSAVLO  EQU     0       ; STATUS: bytes waiting, lo
NSAVHI  EQU     1       ;   hi
NSCONN  EQU     2       ;   connected
NSDEVST EQU     3       ;   error (1 = fine)

; ---- macros ----
; FNBEGIN dev, cmd, nparam -- begin a transaction.
FNBEGIN MACRO   dev, cmd, np
        LDI     dev
        PHI     R9
        LDI     cmd
        PLO     R9
        LDI     np
        FCALL   fn_beg
        ENDM

; PUTS rc, str -- the cursor to rc, then a string.
PUTS    MACRO   rc, str
        LDI     rc
        FCALL   d_at
        LDR     R8, str
        FCALL   d_puts
        ENDM

; SLOW secs -- after fn_beg: wait up to secs.
SLOW    MACRO   secs
        LDR     R8, V_TMO
        LDI     secs
        STR     R8
        ENDM

; GOACK -- go_ack, and to `fail` unless it was 0.
GOACK   MACRO
        FCALL   go_ack
        BZ      $+5             ; over the FJMP
        FJMP    fail
        ENDM
