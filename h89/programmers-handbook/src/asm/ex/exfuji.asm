;-----------------------------------------------------------------------------
; EXFUJI -- the Fuji device (70H), every command it answers. One example of
; each of the 57 commands the H89 firmware dispatches on device 70H, in an
; order that builds what the next one needs: the adapter and its WiFi, the
; host slots, a directory on the SD card, the host prefix, the drive slots,
; copying, boot modes, an app key, Base64, a hash, a QR code, and last of
; all RESET, which never answers.
;
; Each example is marked ;@ex KEY ... ;@end and printed in the book; the
; marker (ex_m) and the report (ex_show) around it are not.
;
;   tools/asm.sh hdos EXFUJI src/asm/ex/exfuji.asm   ->  EXFUJI.ABS
;   tools/asm.sh cpm  EXFUJI src/asm/ex/exfuji.asm   ->  EXFUJI.COM
;
; Copyright (C) 2026 Thomas Cherryhomes
; SPDX-License-Identifier: GPL-3.0-or-later
;-----------------------------------------------------------------------------
INCLUDE "os.inc"
INCLUDE "fujinet.inc"

main:
        call    card_on

;----------------------------------------------------------- the adapter ----
        call    ex_m
        defm    "fuji.get_adapterconfig", 0
        call    crlf
;@ex fuji.get_adapterconfig
        ld      hl,rq_config            ; the adapter's configuration
        call    fn_call
        jr      nz,config_x
        ld      hl,cfg_ssid             ; the network it is on,
        call    print
        call    pspace
        ld      hl,cfg_ip               ; its address
        call    pip
        call    pspace
        ld      hl,cfg_ver              ; and its firmware
        call    print
config_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.get_adapterconfig_extended", 0
        call    crlf
;@ex fuji.get_adapterconfig_extended
        ld      hl,rq_configx           ; the same, with the numbers
        call    fn_call                 ;   as text too, ready to print
        jr      nz,configx_x
        ld      hl,cfgx_sip
        call    print
        call    pspace
        ld      hl,cfgx_smac
        call    print
configx_x:
;@end
        call    ex_show

;-------------------------------------------------------------- the WiFi ----
        call    ex_m
        defm    "fuji.get_wifi_enabled", 0
        call    crlf
;@ex fuji.get_wifi_enabled
        ld      hl,rq_wifien            ; is the WiFi switched on?
        call    fn_call
        jr      nz,wifien_x
        ld      a,(wifien)              ; 1 = yes, 0 = no
        call    pdec8
wifien_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.get_wifistatus", 0
        call    crlf
;@ex fuji.get_wifistatus
        ld      hl,rq_wifist            ; is it connected?
        call    fn_call
        jr      nz,wifist_x
        ld      a,(wifist)              ; 3 = connected, 6 = not
        call    pdec8
wifist_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.scan_networks", 0
        call    crlf
;@ex fuji.scan_networks
        ld      hl,rq_scan              ; look for networks
        call    fn_call
        jr      nz,scan_x
        ld      a,(nnets)               ; how many were found
        call    pdec8
scan_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.get_scan_result", 0
        call    crlf
;@ex fuji.get_scan_result
        ld      hl,rq_scanres           ; the first network found
        call    fn_call
        jr      nz,scanres_x
        ld      hl,net_ssid             ; its name (its signal follows,
        call    print                   ;   in dBm, a signed byte)
scanres_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.get_ssid", 0
        call    crlf
;@ex fuji.get_ssid
        ld      hl,rq_getssid           ; the network it is set to join
        call    fn_call
        jr      nz,getssid_x
        ld      hl,ssid                 ; (the passphrase follows it, in
        call    print                   ;   the clear)
getssid_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.set_ssid", 0
;@ex fuji.set_ssid
        ld      hl,rq_setssid           ; join a network, and keep it
        call    fn_call
;@end
        call    ex_show

;--------------------------------------------------------- the host slots ----
        call    ex_m
        defm    "fuji.read_host_slots", 0
        call    crlf
;@ex fuji.read_host_slots
        ld      hl,rq_hosts             ; the eight host slots
        call    fn_call
        jr      nz,hosts_x
        ld      hl,hosts                ; 32 bytes each, NUL-padded
        ld      b,8
hosts_1:
        push    hl
        call    print                   ; (an empty one prints nothing)
        call    pspace
        pop     hl
        ld      de,32
        add     hl,de
        djnz    hosts_1
hosts_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.write_host_slots", 0
;@ex fuji.write_host_slots
        ld      hl,p_host8              ; a name in slot 8
        ld      de,hosts+7*32
        ld      bc,p_host8n
        ldir
        ld      hl,rq_whosts            ; and all eight go back
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.mount_host", 0
;@ex fuji.mount_host
        ld      hl,rq_mounth            ; mount host slot 0, the SD card
        call    fn_call
;@end
        call    ex_show

;----------------------------------------------------------- a directory ----
        call    ex_m
        defm    "fuji.open_directory", 0
;@ex fuji.open_directory
        ld      hl,rq_opendir           ; open /test/ on host slot 0
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.read_dir_entry", 0
        call    crlf
;@ex fuji.read_dir_entry
dir_1:
        ld      hl,rq_readdir           ; the next name, padded to 32
        call    fn_call
        jr      nz,dir_x
        ld      a,(dirent)              ; 7FH 7FH: there are no more
        cp      0x7F
        jr      z,dir_x
        ld      hl,dirent
        call    print
        call    pspace
        jr      dir_1
dir_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.get_directory_position", 0
        call    crlf
;@ex fuji.get_directory_position
        ld      hl,rq_getpos            ; how far through are we?
        call    fn_call
        jr      nz,getpos_x
        ld      hl,(dirpos)             ; a word: the next entry
        call    pdec16
getpos_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.set_directory_position", 0
;@ex fuji.set_directory_position
        ld      hl,1                    ; on to the second entry (they
        ld      (rq_setpos+RQ_AUX1),hl  ;   count from 0)
        ld      hl,rq_setpos
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.read_dir_entry.ext", 0
        call    crlf
;@ex fuji.read_dir_entry.ext
        ld      hl,rq_readdirx          ; the next entry, 12 bytes of
        call    fn_call                 ;   details before its name
        jr      nz,dirx_x
        ld      hl,dirx_name
        call    print
        call    pspace
        ld      hl,(dirx_size)          ; its size, a long: low word
        call    pdec16
dirx_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.close_directory", 0
;@ex fuji.close_directory
        ld      hl,rq_closedir          ; done with the directory
        call    fn_call
;@end
        call    ex_show

;------------------------------------------------------- the host prefix ----
        call    ex_m
        defm    "fuji.set_host_prefix", 0
;@ex fuji.set_host_prefix
        ld      hl,rq_setpfx            ; paths on host slot 0 now start
        call    fn_call                 ;   in /test
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.get_host_prefix", 0
        call    crlf
;@ex fuji.get_host_prefix
        ld      hl,rq_getpfx            ; host slot 0's prefix
        call    fn_call
        jr      nz,getpfx_x
        ld      hl,prefix               ; NUL-terminated
        call    print
getpfx_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.set_host_prefix.clear", 0
;@ex fuji.set_host_prefix.clear
        ld      hl,rq_clrpfx            ; no prefix: paths start at the
        call    fn_call                 ;   top again
;@end
        call    ex_show

;-------------------------------------------------------- the drive slots ----
        call    ex_m
        defm    "fuji.set_device_fullpath", 0
;@ex fuji.set_device_fullpath
        ld      hl,rq_setpath           ; /test/disk.img into drive
        call    fn_call                 ;   slot 0 (not mounted yet)
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.get_device_fullpath", 0
        call    crlf
;@ex fuji.get_device_fullpath
        ld      hl,rq_getpath           ; what is in drive slot 0?
        call    fn_call
        jr      nz,getpath_x
        ld      hl,path
        call    print
getpath_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.mount_image", 0
;@ex fuji.mount_image
        ld      hl,rq_mount             ; mount it, read-only: it is now
        call    fn_call                 ;   the disk on device 31H
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.read_device_slots", 0
        call    crlf
;@ex fuji.read_device_slots
        ld      hl,rq_dslots            ; the eight drive slots, of 38
        call    fn_call                 ;   bytes each
        jr      nz,dslots_x
        ld      a,(slots+DS_HOST)       ; slot 0's host (FFH: empty)
        call    pdec8
        call    pspace
        ld      a,(slots+DS_MODE)       ; its mode (40H: mounted)
        call    phex8
        call    pspace
        ld      hl,slots+DS_NAME        ; and its file's name
        call    print
dslots_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.write_device_slots", 0
;@ex fuji.write_device_slots
        ld      a,2                     ; slot 0 read/write from now on
        ld      (slots+DS_MODE),a
        ld      hl,rq_wdslots           ; all eight go back (only host
        call    fn_call                 ;   and mode are used)
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.unmount_image", 0
;@ex fuji.unmount_image
        ld      hl,rq_unmount           ; empty drive slot 0
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.mount_all", 0
;@ex fuji.mount_all
        ld      hl,rq_mountall          ; mount whatever the drive slots
        call    fn_call                 ;   name
;@end
        call    ex_show

;----------------------------------------------------- files, new disks ----
        call    ex_m
        defm    "fuji.copy_file", 0
;@ex fuji.copy_file
        ld      hl,rq_copy              ; copy a file on the SD card
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.new_disk", 0
;@ex fuji.new_disk
        ld      hl,rq_newdisk           ; make a new, blank disk image
        call    fn_call                 ;   (this firmware always NAKs)
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.unmount_host", 0
;@ex fuji.unmount_host
        ld      hl,rq_unmounth          ; let go of host slot 0 (the SD
        call    fn_call                 ;   card NAKs: it stays mounted)
;@end
        call    ex_show

;----------------------------------------------------------------- boot ----
        call    ex_m
        defm    "fuji.set_boot_mode", 0
;@ex fuji.set_boot_mode
        ld      hl,rq_bootmode          ; put the boot disk in drive 31H
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.config_boot", 0
;@ex fuji.config_boot
        ld      hl,rq_cfgboot           ; and take it out again
        call    fn_call
;@end
        call    ex_show

;-------------------------------------------------------------- app keys ----
        call    ex_m
        defm    "fuji.open_appkey", 0
;@ex fuji.open_appkey
        ld      hl,rq_akopen            ; open a key, to write it
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.write_appkey", 0
;@ex fuji.write_appkey
        ld      hl,rq_akwrite           ; up to 64 bytes; this closes
        call    fn_call                 ;   the key too
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.close_appkey", 0
;@ex fuji.close_appkey
        ld      hl,rq_akclose           ; done with the key
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.open_appkey.read", 0
;@ex fuji.open_appkey.read
        xor     a                       ; the same key, mode 0: to read
        ld      (p_akey+AK_MODE),a
        ld      hl,rq_akopen
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.read_appkey", 0
        call    crlf
;@ex fuji.read_appkey
        ld      hl,rq_akread            ; a word, the length, then the
        call    fn_call                 ;   key's bytes
        jr      nz,akread_x
        ld      bc,(akey)
        ld      hl,akey+2
        call    ptext
akread_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.close_appkey.read", 0
;@ex fuji.close_appkey.read
        ld      hl,rq_akclose           ; and close it
        call    fn_call
;@end
        call    ex_show

;---------------------------------------------------------------- Base64 ----
        call    ex_m
        defm    "fuji.base64_encode_input", 0
;@ex fuji.base64_encode_input
        ld      hl,rq_b64in             ; some bytes to encode
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.base64_encode_compute", 0
;@ex fuji.base64_encode_compute
        ld      hl,rq_b64enc            ; encode them
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.base64_encode_length", 0
        call    crlf
;@ex fuji.base64_encode_length
        ld      hl,rq_b64len            ; how long is the text? a long
        call    fn_call
        jr      nz,b64len_x
        ld      hl,(b64len)             ; (the low word will do)
        call    pdec16
b64len_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.base64_encode_output", 0
        call    crlf
;@ex fuji.base64_encode_output
        ld      hl,(b64len)             ; take all of it
        ld      (rq_b64out+RQ_AUX1),hl
        ld      hl,rq_b64out
        call    fn_call
        jr      nz,b64out_x
        ld      hl,b64buf               ; BC bytes, a newline last
        call    ptext
b64out_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.base64_decode_input", 0
;@ex fuji.base64_decode_input
        ld      hl,(b64len)             ; give the text back to decode
        ld      (rq_b64din+RQ_AUX1),hl
        ld      (rq_b64din+RQ_PLEN),hl
        ld      hl,rq_b64din
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.base64_decode_compute", 0
;@ex fuji.base64_decode_compute
        ld      hl,rq_b64dec            ; decode it
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.base64_decode_length", 0
        call    crlf
;@ex fuji.base64_decode_length
        ld      hl,rq_b64dlen           ; how many bytes? a long
        call    fn_call
        jr      nz,b64dlen_x
        ld      hl,(b64len)
        call    pdec16
b64dlen_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.base64_decode_output", 0
        call    crlf
;@ex fuji.base64_decode_output
        ld      hl,(b64len)             ; take them all
        ld      (rq_b64dout+RQ_AUX1),hl
        ld      hl,rq_b64dout
        call    fn_call
        jr      nz,b64dout_x
        ld      hl,b64buf
        call    ptext
b64dout_x:
;@end
        call    ex_show

;------------------------------------------------------------------ hash ----
        call    ex_m
        defm    "fuji.hash_input", 0
;@ex fuji.hash_input
        ld      hl,rq_hashin            ; the bytes to hash
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.hash_compute_no_clear", 0
;@ex fuji.hash_compute_no_clear
        ld      hl,rq_md5               ; their MD5, keeping the bytes
        call    fn_call                 ;   for another digest
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.hash_compute", 0
;@ex fuji.hash_compute
        ld      hl,rq_sha1              ; their SHA-1; the bytes are
        call    fn_call                 ;   then let go
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.hash_length", 0
        call    crlf
;@ex fuji.hash_length
        ld      hl,rq_hashlen           ; how long is it, as hex text?
        call    fn_call
        jr      nz,hashlen_x
        ld      a,(hashlen)             ; one byte
        call    pdec8
hashlen_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.hash_output", 0
        call    crlf
;@ex fuji.hash_output
        ld      hl,rq_hashhex           ; the digest as hex text, no NUL
        call    fn_call
        jr      nz,hashhex_x
        ld      hl,digest               ; BC characters
        call    ptext
hashhex_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.hash_output.bin", 0
        call    crlf
;@ex fuji.hash_output.bin
        ld      hl,rq_hashbin           ; the same digest, as bytes
        call    fn_call
        jr      nz,hashbin_x
        ld      hl,digest               ; BC of them
        call    phexs
hashbin_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.hash_clear", 0
;@ex fuji.hash_clear
        ld      hl,rq_hashclr           ; start again: no bytes to hash
        call    fn_call
;@end
        call    ex_show

;--------------------------------------------------------------- QR code ----
        call    ex_m
        defm    "fuji.qrcode_input", 0
;@ex fuji.qrcode_input
        ld      hl,rq_qrin              ; what the code is to say
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.qrcode_encode", 0
;@ex fuji.qrcode_encode
        ld      hl,rq_qrenc             ; make the code
        call    fn_call
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.qrcode_length", 0
        call    crlf
;@ex fuji.qrcode_length
        ld      hl,rq_qrlen             ; as a bitmap: how many bytes?
        call    fn_call
        jr      nz,qrlen_x
        ld      hl,(qrlen)              ; a long; the low word will do
        call    pdec16
qrlen_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.qrcode_output", 0
        call    crlf
;@ex fuji.qrcode_output
        ld      hl,(qrlen)              ; take them all
        ld      (rq_qrout+RQ_AUX1),hl
        ld      hl,rq_qrout
        call    fn_call
        jr      nz,qrout_x
        ld      a,(qr)                  ; first, the modules on a side;
        call    pdec8                   ;   then the rows, a bit each
qrout_x:
;@end
        call    ex_show

;---------------------------------------------------------- odds and ends ----
        call    ex_m
        defm    "fuji.generate_guid", 0
        call    crlf
;@ex fuji.generate_guid
        ld      hl,rq_guid              ; a new GUID, as text
        call    fn_call
        jr      nz,guid_x
        ld      hl,guid
        call    print
guid_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.random_number", 0
        call    crlf
;@ex fuji.random_number
        ld      hl,rq_random            ; a random long
        call    fn_call
        jr      nz,random_x
        ld      hl,(rnd+2)              ; high word, then low
        call    phex16
        ld      hl,(rnd)
        call    phex16
random_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.status", 0
        call    crlf
;@ex fuji.status
        ld      hl,rq_status            ; four status bytes (all 0 on
        call    fn_call                 ;   the H89)
        jr      nz,status_x
        ld      hl,fstat
        call    phexs
status_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.device_ready", 0
        call    crlf
;@ex fuji.device_ready
        ld      hl,rq_ready             ; a link test: 512 'A's back
        call    fn_call
        jr      nz,ready_x
        ld      h,b                     ; count them
        ld      l,c
        call    pdec16
ready_x:
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.get_time", 0
;@ex fuji.get_time
        ld      hl,rq_ftime             ; not a command device 70H has:
        call    fn_call                 ;   NAK (the clock is 45H)
;@end
        call    ex_show

        call    ex_m
        defm    "fuji.reset", 0
;@ex fuji.reset
        ld      hl,rq_reset             ; restart the FujiNet; no reply
        call    fn_call                 ;   comes (TIMEOUT, after 15 s)
;@end
        call    ex_show
        jp      ex_done

;-----------------------------------------------------------------------------
; the requests, and the data each example sends
;-----------------------------------------------------------------------------
;@ex fuji.get_adapterconfig
rq_config:
        FNREQ   DEV_FUJINET, FUJI_GET_ADAPTERCONFIG, F_NONE, 0,0,0,0
        FNBUF   0, 0, cfg, 140
;@end
;@ex fuji.get_adapterconfig_extended
rq_configx:                             ; FNREQ in two lines (the name
        defb    DEV_FUJINET, FUJI_GET_ADAPTERCONFIG_EXTENDED
        defb    F_NONE, 0,0,0,0         ;   is too long for one)
        FNBUF   0, 0, cfgx, 240
;@end
;@ex fuji.get_wifi_enabled
rq_wifien:
        FNREQ   DEV_FUJINET, FUJI_GET_WIFI_ENABLED, F_NONE, 0,0,0,0
        FNBUF   0, 0, wifien, 1
;@end
;@ex fuji.get_wifistatus
rq_wifist:
        FNREQ   DEV_FUJINET, FUJI_GET_WIFISTATUS, F_NONE, 0,0,0,0
        FNBUF   0, 0, wifist, 1
;@end
;@ex fuji.scan_networks
rq_scan:
        FNREQ   DEV_FUJINET, FUJI_SCAN_NETWORKS, F_NONE, 0,0,0,0
        FNBUF   0, 0, nnets, 1
;@end
;@ex fuji.get_scan_result
rq_scanres:                             ; which one: 0 to the count - 1
        FNREQ   DEV_FUJINET, FUJI_GET_SCAN_RESULT, F_A1, 0,0,0,0
        FNBUF   0, 0, net, 34
;@end
;@ex fuji.get_ssid
rq_getssid:
        FNREQ   DEV_FUJINET, FUJI_GET_SSID, F_NONE, 0,0,0,0
        FNBUF   0, 0, ssid, 97
;@end
;@ex fuji.set_ssid
rq_setssid:                             ; (the field is not used)
        FNREQ   DEV_FUJINET, FUJI_SET_SSID, F_A1, 0,0,0,0
        FNBUF   p_netcfg, 97, 0, 0
p_netcfg:
        defm    "Dummy Cafe"            ; the SSID, 33 bytes
        defs    33-10
        defm    "swordfish"             ; the passphrase, 64
        defs    64-9
;@end
;@ex fuji.read_host_slots
rq_hosts:
        FNREQ   DEV_FUJINET, FUJI_READ_HOST_SLOTS, F_NONE, 0,0,0,0
        FNBUF   0, 0, hosts, 256
;@end
;@ex fuji.write_host_slots
rq_whosts:                              ; 256 bytes, all eight slots
        FNREQ   DEV_FUJINET, FUJI_WRITE_HOST_SLOTS, F_NONE, 0,0,0,0
        FNBUF   hosts, 256, 0, 0
p_host8:
        defm    "localhost", 0
p_host8n        equ     $-p_host8
;@end
;@ex fuji.mount_host
rq_mounth:                              ; host slot 0
        FNREQ   DEV_FUJINET, FUJI_MOUNT_HOST, F_A1, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex fuji.open_directory
rq_opendir:                             ; host slot 0
        FNREQ   DEV_FUJINET, FUJI_OPEN_DIRECTORY, F_A1, 0,0,0,0
        FNBUF   p_dir, p_dirn, 0, 0
p_dir:  defm    "/test/", 0             ; the path; a wildcard pattern
p_dirn          equ     $-p_dir         ;   and a NUL may follow
;@end
;@ex fuji.read_dir_entry
rq_readdir:                             ; 32 bytes; no details
        FNREQ   DEV_FUJINET, FUJI_READ_DIR_ENTRY, F_A1_A2, 32,0,0,0
        FNBUF   0, 0, dirent, 32
;@end
;@ex fuji.get_directory_position
rq_getpos:
        FNREQ   DEV_FUJINET,FUJI_GET_DIRECTORY_POSITION,F_NONE,0,0,0,0
        FNBUF   0, 0, dirpos, 2
;@end
;@ex fuji.set_directory_position
rq_setpos:                              ; the entry's number, a word
        FNREQ   DEV_FUJINET, FUJI_SET_DIRECTORY_POSITION, F_B12, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex fuji.read_dir_entry.ext
rq_readdirx:                            ; 64 bytes; 80H: details first
        FNREQ   DEV_FUJINET, FUJI_READ_DIR_ENTRY, F_A1_A2, 64,0x80,0,0
        FNBUF   0, 0, dirx, 64
;@end
;@ex fuji.close_directory
rq_closedir:
        FNREQ   DEV_FUJINET, FUJI_CLOSE_DIRECTORY, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex fuji.set_host_prefix
rq_setpfx:                              ; host slot 0
        FNREQ   DEV_FUJINET, FUJI_SET_HOST_PREFIX, F_A1, 0,0,0,0
        FNBUF   p_pfx, p_pfxn, 0, 0
p_pfx:  defm    "/test", 0              ; send the NUL too
p_pfxn          equ     $-p_pfx
;@end
;@ex fuji.get_host_prefix
rq_getpfx:                              ; host slot 0
        FNREQ   DEV_FUJINET, FUJI_GET_HOST_PREFIX, F_A1, 0,0,0,0
        FNBUF   0, 0, prefix, 256
;@end
;@ex fuji.set_host_prefix.clear
rq_clrpfx:                              ; host slot 0: just a NUL
        FNREQ   DEV_FUJINET, FUJI_SET_HOST_PREFIX, F_A1, 0,0,0,0
        FNBUF   p_nopfx, 1, 0, 0
p_nopfx:
        defb    0
;@end
;@ex fuji.set_device_fullpath
rq_setpath:                             ; drive slot, host slot, mode
        FNREQ   DEV_FUJINET,FUJI_SET_DEVICE_FULLPATH,F_A1_A2_A3,0,0,1,0
        FNBUF   p_img, p_imgn, 0, 0     ; (mode 1: read, 2: read/write)
p_img:  defm    "/test/disk.img", 0
p_imgn          equ     $-p_img
;@end
;@ex fuji.get_device_fullpath
rq_getpath:                             ; drive slot 0
        FNREQ   DEV_FUJINET, FUJI_GET_DEVICE_FULLPATH, F_A1, 0,0,0,0
        FNBUF   0, 0, path, 256
;@end
;@ex fuji.mount_image
rq_mount:                               ; drive slot 0; mode 1: read
        FNREQ   DEV_FUJINET, FUJI_MOUNT_IMAGE, F_A1_A2, 0,1,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex fuji.read_device_slots
rq_dslots:
        FNREQ   DEV_FUJINET, FUJI_READ_DEVICE_SLOTS, F_NONE, 0,0,0,0
        FNBUF   0, 0, slots, 304
DS_HOST         equ     0               ; a slot: its host slot,
DS_MODE         equ     1               ;   its mode
DS_NAME         equ     2               ;   and 36 bytes of file name
;@end
;@ex fuji.write_device_slots
rq_wdslots:                             ; 304 bytes, all eight slots
        FNREQ   DEV_FUJINET, FUJI_WRITE_DEVICE_SLOTS, F_NONE, 0,0,0,0
        FNBUF   slots, 304, 0, 0
;@end
;@ex fuji.unmount_image
rq_unmount:                             ; drive slot 0
        FNREQ   DEV_FUJINET, FUJI_UNMOUNT_IMAGE, F_A1, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex fuji.mount_all
rq_mountall:
        FNREQ   DEV_FUJINET, FUJI_MOUNT_ALL, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex fuji.copy_file
rq_copy:                                ; host slots 1 and 1: COPY_FILE
        FNREQ   DEV_FUJINET, FUJI_COPY_FILE, F_A1_A2, 1,1,0,0
        FNBUF   p_copy, p_copyn, 0, 0   ;   counts them from 1, not 0
p_copy: defm    "/test/readme.txt|/test/copy.txt"
p_copyn         equ     $-p_copy        ; (no NUL)
;@end
;@ex fuji.new_disk
rq_newdisk:
        FNREQ   DEV_FUJINET, FUJI_NEW_DISK, F_NONE, 0,0,0,0
        FNBUF   p_newdisk, 262, 0, 0
p_newdisk:
        defw    400                     ; sectors,
        defw    256                     ;   of 256 bytes
        defb    0                       ; host slot
        defb    1                       ; drive slot
        defm    "/test/new.h8d", 0      ; the name, in 256 bytes
        defs    256-14
;@end
;@ex fuji.unmount_host
rq_unmounth:                            ; host slot 0
        FNREQ   DEV_FUJINET, FUJI_UNMOUNT_HOST, F_A1, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex fuji.set_boot_mode
rq_bootmode:                            ; 0: the firmware's autorun.img
        FNREQ   DEV_FUJINET, FUJI_SET_BOOT_MODE, F_A1, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex fuji.config_boot
rq_cfgboot:                             ; 0: off
        FNREQ   DEV_FUJINET, FUJI_CONFIG_BOOT, F_A1, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex fuji.open_appkey
rq_akopen:
        FNREQ   DEV_FUJINET, FUJI_OPEN_APPKEY, F_NONE, 0,0,0,0
        FNBUF   p_akey, 6, 0, 0
p_akey: defw    0x4889                  ; creator ("H89"), not 0
        defb    0x01                    ; the creator's app
        defb    0x00                    ; the app's key
        defb    1                       ; mode: 0 read, 1 write
        defb    0                       ; (reserved)
AK_MODE         equ     4               ; where the mode is
;@end
;@ex fuji.write_appkey
rq_akwrite:                             ; the payload is the key
        FNREQ   DEV_FUJINET, FUJI_WRITE_APPKEY, F_NONE, 0,0,0,0
        FNBUF   p_akdata, p_akdatan, 0, 0
p_akdata:
        defm    "HIGH SCORE 12345"
p_akdatan       equ     $-p_akdata
;@end
;@ex fuji.close_appkey
rq_akclose:
        FNREQ   DEV_FUJINET, FUJI_CLOSE_APPKEY, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex fuji.read_appkey
rq_akread:                              ; a word and up to 64 bytes
        FNREQ   DEV_FUJINET, FUJI_READ_APPKEY, F_NONE, 0,0,0,0
        FNBUF   0, 0, akey, 66
;@end
;@ex fuji.base64_encode_input
rq_b64in:                               ; the length goes in a word
        FNREQ   DEV_FUJINET, FUJI_BASE64_ENCODE_INPUT, F_B12, 12,0,0,0
        FNBUF   p_b64, 12, 0, 0
p_b64:  defm    "Heathkit H89"
;@end
;@ex fuji.base64_encode_compute
rq_b64enc:
        FNREQ   DEV_FUJINET, FUJI_BASE64_ENCODE_COMPUTE, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex fuji.base64_encode_length
rq_b64len:
        FNREQ   DEV_FUJINET, FUJI_BASE64_ENCODE_LENGTH, F_NONE, 0,0,0,0
        FNBUF   0, 0, b64len, 4
;@end
;@ex fuji.base64_encode_output
rq_b64out:                              ; how many: set before the call
        FNREQ   DEV_FUJINET, FUJI_BASE64_ENCODE_OUTPUT, F_B12, 0,0,0,0
        FNBUF   0, 0, b64buf, 64
;@end
;@ex fuji.base64_decode_input
rq_b64din:                              ; how many: set before the call
        FNREQ   DEV_FUJINET, FUJI_BASE64_DECODE_INPUT, F_B12, 0,0,0,0
        FNBUF   b64buf, 0, 0, 0
;@end
;@ex fuji.base64_decode_compute
rq_b64dec:
        FNREQ   DEV_FUJINET, FUJI_BASE64_DECODE_COMPUTE, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex fuji.base64_decode_length
rq_b64dlen:
        FNREQ   DEV_FUJINET, FUJI_BASE64_DECODE_LENGTH, F_NONE, 0,0,0,0
        FNBUF   0, 0, b64len, 4
;@end
;@ex fuji.base64_decode_output
rq_b64dout:                             ; how many: set before the call
        FNREQ   DEV_FUJINET, FUJI_BASE64_DECODE_OUTPUT, F_B12, 0,0,0,0
        FNBUF   0, 0, b64buf, 64
;@end
;@ex fuji.hash_input
rq_hashin:                              ; the length goes in a word
        FNREQ   DEV_FUJINET, FUJI_HASH_INPUT, F_B12, 3,0,0,0
        FNBUF   p_abc, 3, 0, 0
p_abc:  defm    "abc"
;@end
;@ex fuji.hash_compute_no_clear
rq_md5:                                 ; 0 MD5, 1 SHA-1, 2 SHA-256,
        FNREQ   DEV_FUJINET, FUJI_HASH_COMPUTE_NO_CLEAR, F_A1, 0,0,0,0
        FNBUF   0, 0, 0, 0              ;   3 SHA-512
;@end
;@ex fuji.hash_compute
rq_sha1:                                ; 1: SHA-1
        FNREQ   DEV_FUJINET, FUJI_HASH_COMPUTE, F_A1, 1,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex fuji.hash_length
rq_hashlen:                             ; 1: as hex; 0: as bytes
        FNREQ   DEV_FUJINET, FUJI_HASH_LENGTH, F_A1, 1,0,0,0
        FNBUF   0, 0, hashlen, 1
;@end
;@ex fuji.hash_output
rq_hashhex:                             ; 1: as hex
        FNREQ   DEV_FUJINET, FUJI_HASH_OUTPUT, F_A1, 1,0,0,0
        FNBUF   0, 0, digest, 128
;@end
;@ex fuji.hash_output.bin
rq_hashbin:                             ; 0: as bytes
        FNREQ   DEV_FUJINET, FUJI_HASH_OUTPUT, F_A1, 0,0,0,0
        FNBUF   0, 0, digest, 128
;@end
;@ex fuji.hash_clear
rq_hashclr:
        FNREQ   DEV_FUJINET, FUJI_HASH_CLEAR, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end
;@ex fuji.qrcode_input
rq_qrin:                                ; the length goes in a word
        FNREQ   DEV_FUJINET, FUJI_QRCODE_INPUT, F_B12, p_urln,0,0,0
        FNBUF   p_url, p_urln, 0, 0
p_url:                                  ; capitals: a smaller code
        defm    "HTTPS://FUJINET.ONLINE/"
p_urln          equ     $-p_url
;@end
;@ex fuji.qrcode_encode
rq_qrenc:                               ; version 0: the smallest that
        FNREQ   DEV_FUJINET, FUJI_QRCODE_ENCODE, F_A1_A2_A3, 0,0,0,0
        FNBUF   0, 0, 0, 0              ;   fits; ECC low; no short URL
;@end
;@ex fuji.qrcode_length
rq_qrlen:                               ; 2: a bitmap, 1 bit a module
        FNREQ   DEV_FUJINET, FUJI_QRCODE_LENGTH, F_A1, 2,0,0,0
        FNBUF   0, 0, qrlen, 4
;@end
;@ex fuji.qrcode_output
rq_qrout:                               ; how many: set before the call
        FNREQ   DEV_FUJINET, FUJI_QRCODE_OUTPUT, F_B12, 0,0,0,0
        FNBUF   0, 0, qr, 256
;@end
;@ex fuji.generate_guid
rq_guid:                                ; 36 characters and a NUL
        FNREQ   DEV_FUJINET, FUJI_GENERATE_GUID, F_NONE, 0,0,0,0
        FNBUF   0, 0, guid, 37
;@end
;@ex fuji.random_number
rq_random:
        FNREQ   DEV_FUJINET, FUJI_RANDOM_NUMBER, F_NONE, 0,0,0,0
        FNBUF   0, 0, rnd, 4
;@end
;@ex fuji.status
rq_status:                              ; (the field is not used)
        FNREQ   DEV_FUJINET, FUJI_STATUS, F_A1, 0,0,0,0
        FNBUF   0, 0, fstat, 4
;@end
;@ex fuji.device_ready
rq_ready:
        FNREQ   DEV_FUJINET, FUJI_DEVICE_READY, F_NONE, 0,0,0,0
        FNBUF   0, 0, buf, 512
;@end
;@ex fuji.get_time
rq_ftime:
        FNREQ   DEV_FUJINET, FUJI_GET_TIME, F_NONE, 0,0,0,0
        FNBUF   0, 0, buf, 7
;@end
;@ex fuji.reset
rq_reset:
        FNREQ   DEV_FUJINET, FUJI_RESET, F_NONE, 0,0,0,0
        FNBUF   0, 0, 0, 0
;@end

;-----------------------------------------------------------------------------
; the replies
;-----------------------------------------------------------------------------
cfg:                                    ; GET_ADAPTERCONFIG, 140 bytes
cfg_ssid:       defs    33              ; the WiFi network's name
cfg_host:       defs    64              ; the FujiNet's own name
cfg_ip:         defs    4               ; its address,
cfg_gw:         defs    4               ;   the router's,
cfg_mask:       defs    4               ;   the netmask
cfg_dns:        defs    4               ;   and the name server
cfg_mac:        defs    6
cfg_bssid:      defs    6
cfg_ver:        defs    15              ; the firmware version
cfgx:           defs    140             ; ..._EXTENDED: the same 140,
cfgx_sip:       defs    16              ;   then the address,
cfgx_sgw:       defs    16              ;   router,
cfgx_smask:     defs    16              ;   netmask,
cfgx_sdns:      defs    16              ;   name server,
cfgx_smac:      defs    18              ;   MAC
cfgx_sbssid:    defs    18              ;   and BSSID as text
wifien:         defs    1
wifist:         defs    1
nnets:          defs    1
net:                                    ; GET_SCAN_RESULT, 34 bytes
net_ssid:       defs    33
net_rssi:       defs    1
ssid:           defs    97              ; GET_SSID: SSID 33, passphrase 64
hosts:          defs    256             ; 8 host slots of 32
dirent:         defs    32
dirpos:         defs    2
dirx:                                   ; READ_DIR_ENTRY with details
dirx_date:      defs    6               ; year-1970, month, day, h, m, s
dirx_size:      defs    4               ; the size, a long
dirx_flags:     defs    1               ; 1: a directory, 2: name cut short
dirx_type:      defs    1               ; media type
dirx_name:      defs    52
prefix:         defs    256
path:           defs    256
slots:          defs    304             ; 8 drive slots of 38
akey:           defs    66              ; a word, then up to 64 bytes
b64len:         defs    4
b64buf:         defs    64
hashlen:        defs    1
digest:         defs    128
qrlen:          defs    4
qr:             defs    256
guid:           defs    37
rnd:            defs    4
fstat:          defs    4
buf:            defs    512

INCLUDE "mark.inc"
INCLUDE "card.inc"
INCLUDE "fujibus.inc"
INCLUDE "con.inc"
INCLUDE "tail.inc"
