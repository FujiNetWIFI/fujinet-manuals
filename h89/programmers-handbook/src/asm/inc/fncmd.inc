; fncmd.inc -- the FujiNet firmware's command numbers, made by
; tools/mkcmds.py from include/fujiCommandID.h (fn-h89). Do not edit.

DEV_FUJINET                      equ 0x70
DEV_DISK                         equ 0x31
DEV_DISK_LAST                    equ 0x3F
DEV_PRINTER                      equ 0x40
DEV_PRINTER_LAST                 equ 0x43
DEV_VOICE                        equ 0x43
DEV_CLOCK                        equ 0x45
DEV_SIO2BT_SMART                 equ 0x45
DEV_ASPEQT                       equ 0x46
DEV_SIO2BT_NET                   equ 0x4E
DEV_TYPE3POLL                    equ 0x4F
DEV_SERIAL                       equ 0x50
DEV_SERIAL_LAST                  equ 0x53
DEV_CPM                          equ 0x5A
DEV_CASSETTE                     equ 0x5F
DEV_PCLINK                       equ 0x6F
DEV_NETWORK                      equ 0x71
DEV_NETWORK_LAST                 equ 0x78
DEV_MIDI                         equ 0x99
DEV_DBC                          equ 0xFF

FUJI_RESET                       equ 0xFF
FUJI_GET_SSID                    equ 0xFE
FUJI_SCAN_NETWORKS               equ 0xFD
FUJI_GET_SCAN_RESULT             equ 0xFC
FUJI_SET_SSID                    equ 0xFB
FUJI_GET_WIFISTATUS              equ 0xFA
FUJI_MOUNT_HOST                  equ 0xF9
FUJI_MOUNT_IMAGE                 equ 0xF8
FUJI_OPEN_DIRECTORY              equ 0xF7
FUJI_READ_DIR_ENTRY              equ 0xF6
FUJI_CLOSE_DIRECTORY             equ 0xF5
FUJI_READ_HOST_SLOTS             equ 0xF4
FUJI_WRITE_HOST_SLOTS            equ 0xF3
FUJI_READ_DEVICE_SLOTS           equ 0xF2
FUJI_WRITE_DEVICE_SLOTS          equ 0xF1
FUJI_ENABLE_UDPSTREAM            equ 0xF0
FUJI_SET_BAUDRATE                equ 0xEB
FUJI_GET_WIFI_ENABLED            equ 0xEA
FUJI_UNMOUNT_IMAGE               equ 0xE9
FUJI_GET_ADAPTERCONFIG           equ 0xE8
FUJI_NEW_DISK                    equ 0xE7
FUJI_UNMOUNT_HOST                equ 0xE6
FUJI_GET_DIRECTORY_POSITION      equ 0xE5
FUJI_SET_DIRECTORY_POSITION      equ 0xE4
FUJI_SET_HSIO_INDEX              equ 0xE3
FUJI_SET_DEVICE_FULLPATH         equ 0xE2
FUJI_SET_HOST_PREFIX             equ 0xE1
FUJI_GET_HOST_PREFIX             equ 0xE0
FUJI_SET_SIO_EXTERNAL_CLOCK      equ 0xDF
FUJI_WRITE_APPKEY                equ 0xDE
FUJI_READ_APPKEY                 equ 0xDD
FUJI_OPEN_APPKEY                 equ 0xDC
FUJI_CLOSE_APPKEY                equ 0xDB
FUJI_GET_DEVICE_FULLPATH         equ 0xDA
FUJI_CONFIG_BOOT                 equ 0xD9
FUJI_COPY_FILE                   equ 0xD8
FUJI_MOUNT_ALL                   equ 0xD7
FUJI_SET_BOOT_MODE               equ 0xD6
FUJI_ENABLE_DEVICE               equ 0xD5
FUJI_DISABLE_DEVICE              equ 0xD4
FUJI_RANDOM_NUMBER               equ 0xD3
FUJI_GET_TIME                    equ 0xD2
FUJI_DEVICE_ENABLE_STATUS        equ 0xD1
FUJI_BASE64_ENCODE_INPUT         equ 0xD0
FUJI_BASE64_ENCODE_COMPUTE       equ 0xCF
FUJI_BASE64_ENCODE_LENGTH        equ 0xCE
FUJI_BASE64_ENCODE_OUTPUT        equ 0xCD
FUJI_BASE64_DECODE_INPUT         equ 0xCC
FUJI_BASE64_DECODE_COMPUTE       equ 0xCB
FUJI_BASE64_DECODE_LENGTH        equ 0xCA
FUJI_BASE64_DECODE_OUTPUT        equ 0xC9
FUJI_HASH_INPUT                  equ 0xC8
FUJI_HASH_COMPUTE                equ 0xC7
FUJI_HASH_LENGTH                 equ 0xC6
FUJI_HASH_OUTPUT                 equ 0xC5
FUJI_GET_ADAPTERCONFIG_EXTENDED  equ 0xC4
FUJI_HASH_COMPUTE_NO_CLEAR       equ 0xC3
FUJI_HASH_CLEAR                  equ 0xC2
FUJI_GET_HEAP                    equ 0xC1
FUJI_QRCODE_OUTPUT               equ 0xBF
FUJI_QRCODE_LENGTH               equ 0xBE
FUJI_QRCODE_ENCODE               equ 0xBD
FUJI_QRCODE_INPUT                equ 0xBC
FUJI_GENERATE_GUID               equ 0xBB
FUJI_GET_DEVICE10_FULLPATH       equ 0xA9
FUJI_GET_DEVICE9_FULLPATH        equ 0xA8
FUJI_GET_DEVICE8_FULLPATH        equ 0xA7
FUJI_GET_DEVICE7_FULLPATH        equ 0xA6
FUJI_GET_DEVICE6_FULLPATH        equ 0xA5
FUJI_GET_DEVICE5_FULLPATH        equ 0xA4
FUJI_GET_DEVICE4_FULLPATH        equ 0xA3
FUJI_GET_DEVICE3_FULLPATH        equ 0xA2
FUJI_GET_DEVICE2_FULLPATH        equ 0xA1
FUJI_GET_DEVICE1_FULLPATH        equ 0xA0
FUJI_UPDATE_FIRMWARE             equ 0x90
FUJI_STATUS                      equ 0x53    ; S
FUJI_HSIO_INDEX                  equ 0x3F    ; ?
FUJI_NAK                         equ 0x15    ; ASCII NAK
FUJI_ACK                         equ 0x06    ; ASCII ACK
FUJI_SEND_ERROR                  equ 0x02
FUJI_SEND_RESPONSE               equ 0x01
FUJI_DEVICE_READY                equ 0x00
DISK_HSIO_WRITE                  equ 0xD7
DISK_HSIO_STATUS                 equ 0xD3
DISK_HSIO_READ                   equ 0xD2
DISK_HSIO_PUT                    equ 0xD0
DISK_HSIO_FORMAT_MEDIUM          equ 0xA2
DISK_HSIO_FORMAT                 equ 0xA1
DISK_WRITE                       equ 0x57    ; W
DISK_STATUS                      equ 0x53    ; S
DISK_READ                        equ 0x52    ; R
DISK_PUT                         equ 0x50    ; P
DISK_PERCOM_WRITE                equ 0x4F    ; O
DISK_PERCOM_READ                 equ 0x4E    ; N
DISK_HSIO_INDEX                  equ 0x3F    ; ?
DISK_FORMAT_MEDIUM               equ 0x22    ; "
DISK_FORMAT                      equ 0x21    ; !
NET_GET_DSTATS_VALUE             equ 0xFF
NET_PASSWORD                     equ 0xFE
NET_USERNAME                     equ 0xFD
NET_SET_PARSER                   equ 0xFC
NET_SET_PARAMETER                equ 0xFB
NET_SET_UNIT                     equ 0xFA
NET_SET_HSIO_INDEX               equ 0xE3
NET_QUERY_ALT                    equ 0x81
NET_PARSE_ALT                    equ 0x80
NET_GET_REMOTE                   equ 0x72    ; r
NET_CLOSE_CLIENT                 equ 0x63    ; c
NET_SET_INT_RATE                 equ 0x5A    ; Z
NET_WRITE                        equ 0x57    ; W
NET_TRANSLATION                  equ 0x54    ; T
NET_STATUS                       equ 0x53    ; S
NET_READ                         equ 0x52    ; R
NET_QUERY                        equ 0x51    ; Q
NET_PARSE                        equ 0x50    ; P
NET_OPEN                         equ 0x4F    ; O
NET_SET_HTTP_MODE                equ 0x4D    ; M
NET_SET_EOL                      equ 0x4C    ; L
NET_GET_ERROR                    equ 0x45    ; E
NET_SET_DESTINATION              equ 0x44    ; D
NET_CLOSE                        equ 0x43    ; C
NET_ACCEPT                       equ 0x41    ; A
NET_HSIO_INDEX                   equ 0x3F    ; ?
NET_GETCWD                       equ 0x30    ; 0
NET_CHDIR                        equ 0x2C    ; ,
NET_RMDIR                        equ 0x2B    ; +
NET_MKDIR                        equ 0x2A    ; *
NET_TELL                         equ 0x26    ; &
NET_SEEK                         equ 0x25    ; %
NET_UNLOCK                       equ 0x24    ; $
NET_LOCK                         equ 0x23    ; #
NET_DELETE                       equ 0x21    ; !
NET_RENAME                       equ 0x20
MODEM_STREAM                     equ 0x58    ; X
MODEM_WRITE                      equ 0x57    ; W
MODEM_STATUS                     equ 0x53    ; S
MODEM_READ                       equ 0x52    ; R
MODEM_AUTOANSWER                 equ 0x4F    ; O
MODEM_BAUDRATELOCK               equ 0x4E    ; N
MODEM_UNLISTEN                   equ 0x4D    ; M
MODEM_LISTEN                     equ 0x4C    ; L
MODEM_SET_DUMP                   equ 0x44    ; D
MODEM_CONFIGURE                  equ 0x42    ; B
MODEM_CONTROL                    equ 0x41    ; A
MODEM_TYPE3_POLL                 equ 0x40    ; @
MODEM_TYPE1_POLL                 equ 0x3F    ; ?
MODEM_LOAD_HANDLER               equ 0x26    ; &
MODEM_LOAD_RELOCATOR             equ 0x21    ; !
APETIME_GETTZTIME                equ 0x9A
APETIME_SETTZ                    equ 0x99
APETIME_GETTIME                  equ 0x93
APETIME_GET_ISO_UTC_ALT          equ 0x7A    ; z
APETIME_SETTZ_ALT                equ 0x74    ; t
APETIME_GET_SOS_ALT              equ 0x73    ; s
APETIME_GET_PRODOS_ALT           equ 0x70    ; p
APETIME_GET_ISO_LOCAL_ALT        equ 0x69    ; i
APETIME_GET_ATARI_ALT            equ 0x61    ; a
APETIME_GET_ISO_UTC              equ 0x5A    ; Z
APETIME_SETTZ_ALT2               equ 0x54    ; T
APETIME_GET_SOS                  equ 0x53    ; S
APETIME_GET_PRODOS               equ 0x50    ; P
APETIME_GET_SIMPLE_HUNDREDTHS    equ 0x4D    ; M - simple binary + 1-byte hundredths (0-99)
APETIME_GETTZ_LEN                equ 0x4C    ; L
APETIME_GET_ISO_LOCAL            equ 0x49    ; I
APETIME_GET_GENERAL              equ 0x47    ; G
APETIME_GET_ATARI                equ 0x41    ; A
CPM_WRITE                        equ 0x57    ; W
CPM_STATUS                       equ 0x53    ; S
CPM_READ                         equ 0x52    ; R
CPM_INIT                         equ 0x47    ; G
CPM_BOOT                         equ 0x42    ; B
PRINTER_WRITE                    equ 0x57    ; W
PRINTER_STATUS                   equ 0x53    ; S
PRINTER_PUT                      equ 0x50    ; P
PCLINK_STATUS                    equ 0x53    ; S
PCLINK_EXEC                      equ 0x52    ; R
PCLINK_PARBLK                    equ 0x50    ; P
PCLINK_HSI                       equ 0x3F    ; ?
