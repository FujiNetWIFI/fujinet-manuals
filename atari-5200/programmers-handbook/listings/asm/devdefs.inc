; devdefs.inc -- the other devices, and the FUJI commands the bring-up's
; fujinet.inc does not name. Values from include/fujiDeviceID.h and
; include/fujiCommandID.h; the appkey struct from lib/device/fujiDevice/
; AppKeyMixin.h. Kept apart from fujinet.inc so that file stays verbatim.

; ---------------- device ids ----------------
DSKDEV  =       $31             ; D1: (D2:-D8: are $32-$38)
PRNDEV  =       $40             ; P1:
CLKDEV  =       $45             ; the clock (APETIME)
MDMDEV  =       $50             ; R: the modem
CPMDEV  =       $5A             ; CP/M

; ---------------- FUJI ($70) commands ----------------
FNCRST  =       $FF             ; RESET
FNCGSSD =       $FE             ; GET_SSID
FNCSCAN =       $FD             ; SCAN_NETWORKS
FNCSCNR =       $FC             ; GET_SCAN_RESULT
FNCSSSD =       $FB             ; SET_SSID
FNCWIFI =       $FA             ; GET_WIFISTATUS
FNCRHST =       $F4             ; READ_HOST_SLOTS
FNCWHST =       $F3             ; WRITE_HOST_SLOTS
FNCRDEV =       $F2             ; READ_DEVICE_SLOTS
FNCWDEV =       $F1             ; WRITE_DEVICE_SLOTS
FNCWIEN =       $EA             ; GET_WIFI_ENABLED
FNCODIR =       $F7             ; OPEN_DIRECTORY
FNCRDIR =       $F6             ; READ_DIR_ENTRY
FNCCDIR =       $F5             ; CLOSE_DIRECTORY
FNCSDPS =       $E4             ; SET_DIRECTORY_POSITION
FNCUIMG =       $E9             ; UNMOUNT_IMAGE
FNCADPC =       $E8             ; GET_ADAPTERCONFIG
FNCNEWD =       $E7             ; NEW_DISK
FNCUHST =       $E6             ; UNMOUNT_HOST
FNCGDPS =       $E5             ; GET_DIRECTORY_POSITION
FNCSHPX =       $E1             ; SET_HOST_PREFIX
FNCGHPX =       $E0             ; GET_HOST_PREFIX
FNCAKWR =       $DE             ; WRITE_APPKEY
FNCAKRD =       $DD             ; READ_APPKEY
FNCAKOP =       $DC             ; OPEN_APPKEY
FNCAKCL =       $DB             ; CLOSE_APPKEY
FNCGDFP =       $DA             ; GET_DEVICE_FULLPATH
FNCCBOT =       $D9             ; CONFIG_BOOT
FNCCOPY =       $D8             ; COPY_FILE
FNCMALL =       $D7             ; MOUNT_ALL
FNCSBM  =       $D6             ; SET_BOOT_MODE
FNCRAND =       $D3             ; RANDOM_NUMBER
FNCB64EI =      $D0             ; BASE64_ENCODE_INPUT
FNCB64EC =      $CF             ; BASE64_ENCODE_COMPUTE
FNCB64EL =      $CE             ; BASE64_ENCODE_LENGTH
FNCB64EO =      $CD             ; BASE64_ENCODE_OUTPUT
FNCB64DI =      $CC             ; BASE64_DECODE_INPUT
FNCB64DC =      $CB             ; BASE64_DECODE_COMPUTE
FNCB64DL =      $CA             ; BASE64_DECODE_LENGTH
FNCB64DO =      $C9             ; BASE64_DECODE_OUTPUT
FNCHSHI =       $C8             ; HASH_INPUT
FNCHSHC =       $C7             ; HASH_COMPUTE
FNCHSHL =       $C6             ; HASH_LENGTH
FNCHSHO =       $C5             ; HASH_OUTPUT
FNCHSHN =       $C3             ; HASH_COMPUTE_NO_CLEAR
FNCHSHX =       $C2             ; HASH_CLEAR
FNCQRO  =       $BF             ; QRCODE_OUTPUT
FNCQRL  =       $BE             ; QRCODE_LENGTH
FNCQRE  =       $BD             ; QRCODE_ENCODE
FNCQRI  =       $BC             ; QRCODE_INPUT
FNCGUID =       $BB             ; GENERATE_GUID
FNCSTAT =       $53             ; STATUS
FNCRDY  =       $00             ; DEVICE_READY

; ---------------- appkeys ----------------
; OPEN_APPKEY's payload is ONE six-byte packed struct: creator (u16, little-
; endian), app, key, mode, and a reserved byte that is not optional.
AKMRD   =       0               ; mode: read
AKMWR   =       1               ; mode: write
AKCREAT =       1               ; the shared FujiNet username slot...
AKAPP   =       1               ; ...creator 1, app 1, key 0, which every
AKKEY   =       0               ; game in the family reads

; ---------------- the clock ($45) ----------------
CKGTIME =       $93             ; GETTIME: 7 bytes, binary
CKISOL  =       $49             ; 'I' GET_ISO_LOCAL: "YYYY-MM-DDTHH:MM:SS"...
CKISOU  =       $5A             ; 'Z' GET_ISO_UTC
CKGEN   =       $47             ; 'G' GET_GENERAL
CKTZLEN =       $4C             ; 'L' GETTZ_LEN
CKSETTZ =       $99             ; SETTZ: payload = the POSIX TZ string
CKTZTIM =       $9A             ; GETTZTIME

; ---------------- hash algorithms (HASH_COMPUTE's parameter) ----------------
HAMD5   =       0
HASHA1  =       1
HASHA256 =      3
HASHA512 =      4


; ---------------- FNBEGIN: the four stores before fn_beg ----------------
; FNBEGIN dev, cmd, nparam -- set up and begin a transaction (fn_beg).
.macro  FNBEGIN dev, cmd, npr
        lda     #dev
        sta     FN_DEV
        lda     #cmd
        sta     FN_CMD
        lda     #npr
        sta     FN_NPR
        jsr     fn_beg
.endmacro
