#import "../lib.typ": *
= Command Reference: The Fuji Device <ch-ref-fuji>

Every command device `$70` answers, checked against the firmware the cartridge’s ESP32-S3 runs: the RS-232 build’s `rs232Fuji.cpp` and the four mixins every FujiNet shares (appkeys, Base64, hashing, QR codes). A command not on a card is answered with a NAK; the last section names them.

On the cards, _nparam_ is the value for the NPARAM register, and each parameter goes into the TX stream as its size and then its value: a _byte_ is 1 and the byte, a _word_ 2 and two bytes, low first. The reply is in the reply window at `$B000`. The assembly examples use the library of @ch-library and its `FNBEGIN` macro (`devdefs.inc`), which sets `FN_DEV`, `FN_CMD` and `FN_NPR` and calls `fn_beg`. The C examples use fujinet-lib where it has a call, and its bus layer where it does not. Every example is built by `tools/snipcheck.py`.

#sect[WiFi and the adapter]

#cmd("GET_ADAPTERCONFIG_EXTENDED / GET_ADAPTERCONFIG", code: "$C4 / $E8", dev: "$70", nparam: "0",
  reply: [`$C4`: 240 bytes, laid out in @ch-first. `$E8`: the first 140, addresses in binary only],
  asm: "        FNBEGIN FNDEVF, FNCADPX, 0
        jsr     fn_go
        bne     failed
        lda     FN_REPLY+140    ; the IP address, as text",
  c: "if (!fuji_get_adapter_config_extended(&ac))
    failed();
mt_text(ac.sLocalIP, 16);",
  [The first-contact command, and the one every status screen wants. It works before the WiFi is up, and its text fields save writing a routine to print an IP address.])

#cmd("SCAN_NETWORKS", code: "$FD", dev: "$70", nparam: "0",
  reply: [1 byte: how many networks were found],
  asm: "        FNBEGIN FNDEVF, FNCSCAN, 0
        jsr     fn_go
        bne     failed
        lda     FN_REPLY        ; how many
        sta     cnt",
  c: "if (!fuji_scan_for_networks(&count))
    failed();",
  [Starts a fresh scan and answers when it is done, which takes seconds; well inside the cartridge’s five. Follow it with GET_SCAN_RESULT once for each network.])

#cmd("GET_SCAN_RESULT", code: "$FC", dev: "$70", nparam: "1",
  params: [byte: which result, from 0],
  reply: [34 bytes: the SSID (33, NUL-terminated), then the signal strength, a signed dBm],
  asm: "        FNBEGIN FNDEVF, FNCSCNR, 1
        lda     idx             ; which network
        jsr     fn_pb
        jsr     fn_go
        bne     failed
        lda     FN_REPLY+33     ; signal strength, negative dBm",
  c: "if (!fuji_get_scan_result(idx, &si))
    failed();
mt_text(si.ssid, 24);           /* si.rssi: negative dBm */",
  [The strength is negative: closer to zero is stronger.])

#cmd("SET_SSID", code: "$FB", dev: "$70", nparam: "1",
  params: [byte: any value; *required but ignored*],
  payload: [*exactly 97 bytes*: the SSID (33) then the password (64), each NUL-padded],
  reply: [ACK],
  asm: "        FNBEGIN FNDEVF, FNCSSSD, 1
        lda     #0
        jsr     fn_pb           ; the parameter that must be there
        ldx     #0
@pw:    lda     ssidpw,x        ; ssid[33] + password[64]
        jsr     fn_txb
        inx
        cpx     #97
        bne     @pw
        jsr     fn_go",
  c: "strcpy(nc.ssid, ac.ssid);      /* nc: a NetConfig, 33 + 64 */
nc.password[0] = 0;
if (!fuji_set_ssid(&nc))
    failed();",
  [Joins a network and saves it as the default. Two sharp edges: the parameter must be sent although nothing reads it, and the payload must be all 97 bytes; a short one fails the transaction. The BASIC example joins `Dummy Cafe` with no password: ten bytes of name, then 87 NULs.])

#cmd("GET_SSID", code: "$FE", dev: "$70", nparam: "0",
  reply: [97 bytes: the SSID (33) then the password (64)],
  c: "if (!fuji_get_ssid(&nc))
    failed();",
  asm: "        FNBEGIN FNDEVF, FNCGSSD, 0
        jsr     fn_go
        bne     failed          ; SSID at FN_REPLY, password at +33",
  [The network the adapter is set to join, password in clear text.])

#cmd("GET_WIFISTATUS / GET_WIFI_ENABLED", code: "$FA / $EA", dev: "$70", nparam: "0",
  reply: [`$FA`: 1 byte, 3 when connected; `$EA`: 1 byte, 1 if the radio is on],
  asm: "        FNBEGIN FNDEVF, FNCWIFI, 0
        jsr     fn_go
        bne     failed
        lda     FN_REPLY
        cmp     #3              ; connected?
        beq     done",
  c: "if (fuji_get_wifi_status(&err) && err == 3)
    linked();",
  [What to poll while a join is in progress.])

#cmd("RESET", code: "$FF", dev: "$70", nparam: "0",
  reply: [ACK, then the adapter restarts],
  [Restarts the ESP32-S3. The cartridge, its mailbox and your program carry on; the link bit at `$B401` drops and comes back, and the cartridge waits up to three seconds for it before the next transaction.])

#cmd("STATUS / DEVICE_READY", code: "$53 / $00", dev: "$70", nparam: "1 / 0",
  params: [STATUS: byte, the kind of status wanted (1: mount times)],
  reply: [STATUS 1: four bytes per device slot, a time, 0 if nothing is mounted; DEVICE_READY: the bus test’s answer],
  [STATUS needs its parameter on this build. DEVICE_READY is a round trip with no other effect: it proves the mailbox, the cartridge, the USB link and the adapter at once.])

#sect[Hosts, slots and mounting]

#cmd("READ_HOST_SLOTS", code: "$F4", dev: "$70", nparam: "0",
  reply: [256 bytes: eight host names of 32 bytes],
  asm: "        FNBEGIN FNDEVF, FNCRHST, 0
        jsr     fn_go
        bne     failed
        lda     #4              ; host 0's name on row 4
        ldx     #2
        jsr     disp_at
        ldx     #0              ; FN_REPLY + slot * 32
        ldy     #32
        jsr     disp_rpl",
  c: "if (!fuji_get_host_slots(hosts, 8))
    failed();
mt_text((char *)hosts[0], 32);",
  [Slot 0 is the SD card on a standard `fujinet-pc`.])

#cmd("WRITE_HOST_SLOTS", code: "$F3", dev: "$70", nparam: "0",
  payload: [256 bytes: all eight slots, 32 bytes each],
  reply: [ACK],
  [All or nothing: there is no command to write one slot. Read the table with READ_HOST_SLOTS and stream it back with the one slot changed; the reply window holds still until the next launch, so the stream can be copied straight out of it.])

#cmd("MOUNT_HOST", code: "$F9", dev: "$70", nparam: "1",
  params: [byte: the host slot, from 0],
  reply: [ACK; NAK if the host cannot be reached],
  asm: "        FNBEGIN FNDEVF, FNCMHST, 1
        lda     #0              ; host slot 0
        jsr     fn_pb
        jsr     fn_go
        bne     failed
        jsr     fn_ack
        bne     refused",
  c: "if (!fuji_mount_host_slot(0))
    failed();",
  [Connects the host: SD, TNFS, SMB and the rest. Needed before OPEN_DIRECTORY or a mount. UNMOUNT_HOST (`$E6`) is not answered on this build.])

#cmd("READ_DEVICE_SLOTS / WRITE_DEVICE_SLOTS", code: "$F2 / $F1", dev: "$70", nparam: "0",
  reply: [`$F2`: the device-slot table: host slot, mode and file name for each slot; `$F1` takes the same table as its payload],
  [What is set up in each of the FujiNet’s virtual drives. A 5200 boots images rather than reading drives, so CONFIG does not show them, but they answer.])

#cmd("SET_DEVICE_FULLPATH", code: "$E2", dev: "$70", nparam: "3",
  params: [bytes: device slot, host slot, mode (1 to read)],
  payload: [*256 bytes*: the path, NUL-padded],
  reply: [ACK],
  asm: "        FNBEGIN FNDEVF, FNCSDFP, 3
        lda     #0              ; device slot
        jsr     fn_pb
        lda     #0              ; host slot
        jsr     fn_pb
        lda     #FMREAD
        jsr     fn_pb
        lda     #<file
        sta     FN_PTR
        lda     #>file
        sta     FN_PTR+1
        jsr     fn_path         ; padded to 256
        jsr     fn_go",
  c: "strcpy(path, \"/a5200book/hello.a52\");
if (!fuji_set_device_filename(1, 0, 0, path))  /* mode, host, device */
    failed();",
  [Names the file for a device slot: the first half of booting. fujinet-lib’s call takes the mode first, the device slot last; the wire has the device slot first.])

#cmd("MOUNT_IMAGE / UNMOUNT_IMAGE", code: "$F8 / $E9", dev: "$70", nparam: "2 / 1",
  params: [`$F8`: device slot, mode (1 to read); `$E9`: device slot],
  reply: [ACK when the mount completes],
  asm: "        FNBEGIN FNDEVF, FNCMIMG, 2
        lda     #0              ; device slot
        jsr     fn_pb
        lda     #FMREAD
        jsr     fn_pb
        lda     #66             ; seconds: past the cartridge's 60
        sta     FN_TMO
        jsr     fn_go
        bne     failed
@push:  lda     FN_BOOTSTATE    ; then watch the push
        cmp     #FN_BOOT_READY
        bne     @push",
  c: "if (!fuji_mount_disk_image(0, 1))
    failed();
while (fuji_a5200_boot_state() != FUJI_A5200_BOOT_READY)
    mt_sync();",
  [The second half of booting. While it is outstanding the FujiNet pushes the file into the cartridge, and BOOT_STATE and BOOT_PCT report the progress; the cartridge allows sixty seconds. @ch-boot has the rest.])

#cmd("MOUNT_ALL / SET_BOOT_MODE / CONFIG_BOOT", code: "$D7 / $D6 / $D9", dev: "$70", nparam: "0 / 1 / 1",
  params: [SET_BOOT_MODE: byte, the mode; CONFIG_BOOT: byte, on or off],
  reply: [ACK],
  [MOUNT_ALL mounts every slot that has a file; the other two choose what the adapter serves at power-on on computers that boot from its drives. On the 5200 the cartridge decides what boots, and CONFIG does not send them.])

#sect[Directories]

#cmd("OPEN_DIRECTORY", code: "$F7", dev: "$70", nparam: "1",
  params: [byte: the host slot],
  payload: [*256 bytes*: the path, a NUL, then an optional filter such as `*.A78`, the rest NULs],
  reply: [ACK],
  asm: "        FNBEGIN FNDEVF, FNCODIR, 1
        lda     #0              ; host slot
        jsr     fn_pb
        lda     #<path
        sta     FN_PTR
        lda     #>path
        sta     FN_PTR+1
        jsr     fn_path
        jsr     fn_go
        bne     failed",
  c: "strcpy(path, \"/a5200book/\");
if (!fuji_open_directory(0, path))
    failed();",
  [Opens a directory on a mounted host. The adapter applies the filter, so a program never sees what it does not want. `fuji_open_directory2()` builds the path-and-filter payload for C.])

#cmd("READ_DIR_ENTRY", code: "$F6", dev: "$70", nparam: "2",
  params: [bytes: the longest name wanted (*never 31*), flags (0)],
  reply: [one name, NUL-terminated, a `/` at the end of a directory’s; *`$7F`, `$7F` when there are no more*],
  asm: "        FNBEGIN FNDEVF, FNCRDIR, 2
        lda     #36
        jsr     fn_pb
        lda     #0
        jsr     fn_pb
        jsr     fn_go
        bne     failed
        lda     FN_REPLY
        cmp     #$7F            ; the end?
        beq     done",
  c: "if (!fuji_read_directory(36, 0, buf))
    failed();
if (buf[0] == 0x7F && buf[1] == 0x7F)
    linked();                   /* the end */",
  [One name a call; the adapter moves on by itself. At a length of exactly 31 the firmware puts icon bytes in front of the name. Stop at the end marker: an SD host keeps answering `..` past it.])

#cmd("SET_DIRECTORY_POSITION / GET_DIRECTORY_POSITION", code: "$E4 / $E5", dev: "$70", nparam: "1 / 0",
  params: [`$E4`: *one word*, the entry number],
  reply: [`$E5`: a word, the current entry number; `$E4`: ACK],
  asm: "        FNBEGIN FNDEVF, FNCSDPS, 1
        lda     #20             ; entry 20: the second page
        ldx     #0
        jsr     fn_pw
        jsr     fn_go",
  c: "if (!fuji_set_directory_position(20))
    failed();",
  [Seek and tell for the open directory: paging in one command. The position is one two-byte parameter, not two one-byte ones.])

#cmd("CLOSE_DIRECTORY", code: "$F5", dev: "$70", nparam: "0",
  reply: [ACK],
  asm: "        FNBEGIN FNDEVF, FNCCDIR, 0
        jsr     fn_go",
  c: "fuji_close_directory();",
  [Close what you open: the adapter has room for few open directories.])

#sect[Files, prefixes and paths]

#cmd("COPY_FILE", code: "$D8", dev: "$70", nparam: "2",
  params: [bytes: source host, destination host, *counting from 1*],
  payload: [`source|destination`; at its own length, or NUL-padded],
  reply: [ACK when the copy is done; the cartridge allows sixty seconds],
  asm: "        FNBEGIN FNDEVF, FNCCOPY, 2
        lda     #1              ; host slot 0, counted from 1
        jsr     fn_pb
        lda     #1
        jsr     fn_pb
        ldx     #0              ; X: fn_txb takes its byte in Y
@spec:  lda     spec,x          ; source|destination
        beq     @go
        jsr     fn_txb
        inx
        bne     @spec
@go:    lda     #66             ; seconds: past the cartridge's 60
        sta     FN_TMO
        jsr     fn_go",
  c: "strcpy(path, \"/a5200book/readme.txt|/a5200book/copy.txt\");
if (!fuji_copy_file(1, 1, path))  /* hosts from 1 */
    failed();",
  [Host to host, without a byte passing through the console. Its hosts count from 1, unlike every other slot number; 0 is refused. When the destination ends in `/`, the adapter adds the source’s file name. fujinet-lib pads the payload to 256 bytes and CONFIG sends it at its own length; the firmware takes either.])

#cmd("SET_HOST_PREFIX / GET_HOST_PREFIX", code: "$E1 / $E0", dev: "$70", nparam: "1",
  params: [byte: the host slot; SET carries the prefix as its payload],
  reply: [GET: the prefix],
  [A working directory per host, put in front of relative paths.])

#cmd("GET_DEVICE_FULLPATH", code: "$DA", dev: "$70", nparam: "1",
  params: [byte: the device slot], reply: [the path SET_DEVICE_FULLPATH stored],
  [In C: `fuji_get_device_filename()`.])

#sect[Appkeys]

#cmd("OPEN_APPKEY", code: "$DC", dev: "$70", nparam: "0",
  payload: [6 bytes: creator (word), app, key, mode (0 read, 1 write), and a reserved 0],
  reply: [ACK; NAK with no SD card, a creator of 0 or a bad mode],
  asm: "        FNBEGIN FNDEVF, FNCAKOP, 0
        lda     #$00            ; creator $5200, low first
        jsr     fn_txb
        lda     #$52
        jsr     fn_txb
        lda     #$FF            ; app
        jsr     fn_txb
        lda     #0              ; key
        jsr     fn_txb
        lda     #AKMRD          ; mode
        jsr     fn_txb
        lda     #0              ; reserved, and required
        jsr     fn_txb
        jsr     fn_go",
  c: "fuji_set_appkey_details(0x5200, 0xFF, DEFAULT);
/* fuji_read_appkey() and fuji_write_appkey() each open the key */",
  [Chooses the key the next read or write uses. The payload is one packed structure; leave off the reserved byte and the adapter waits for it until the transaction times out. On the SD card the key is the file `/FujiNet/CCCCAAKK.key`; it holds 64 bytes at most.])

#cmd("READ_APPKEY / WRITE_APPKEY / CLOSE_APPKEY", code: "$DD / $DE / $DB", dev: "$70", nparam: "0 / 1 / 0",
  params: [WRITE: byte, the length],
  payload: [WRITE: the value, at most 64 bytes],
  reply: [READ: a word, the length, then the value; the others: ACK],
  asm: "        FNBEGIN FNDEVF, FNCAKRD, 0
        jsr     fn_go
        bne     failed
        lda     FN_REPLY        ; the length; the value from FN_REPLY+2
        beq     done            ; empty",
  c: "if (!fuji_read_appkey(0, &n, value))  /* value: the key + 2 */
    failed();",
  [A write ends the selection, so each write needs its own OPEN in write mode. @ch-keys has both directions in both languages.])

#sect[Utilities]

#cmd("GENERATE_GUID", code: "$BB", dev: "$70", nparam: "0",
  reply: [36 characters and a NUL],
  asm: "        FNBEGIN FNDEVF, FNCGUID, 0
        jsr     fn_go
        bne     failed
        lda     #6
        ldx     #2
        jsr     disp_at
        ldx     #0
        ldy     #36
        jsr     disp_rpl",
  c: "if (!fuji_generate_guid(guid))
    failed();",
  [A fresh, printable, unique id. RANDOM_NUMBER (`$D3`) is not answered on this build; the adapter’s randomness reaches a program through a GUID or a hash.])

#cmd("HASH: INPUT, COMPUTE, LENGTH, OUTPUT", code: "$C8 / $C7 / $C6 / $C5", dev: "$70", nparam: "1",
  params: [INPUT: word, the byte count; COMPUTE: byte, the algorithm (0 MD5, 1 SHA-1, 3 SHA-256, 4 SHA-512); LENGTH and OUTPUT: byte, 1 for hex text, 0 for binary],
  payload: [INPUT: the bytes], reply: [LENGTH: the size; OUTPUT: the hash],
  asm: "        FNBEGIN FNDEVF, FNCHSHI, 1   ; feed it
        lda     #dataend-data
        ldx     #0
        jsr     fn_pw
        ldx     #0              ; X: fn_txb takes its byte in Y
@in:    lda     data,x
        jsr     fn_txb
        inx
        cpx     #dataend-data
        bne     @in
        jsr     fn_go
        FNBEGIN FNDEVF, FNCHSHC, 1   ; SHA-256
        lda     #HASHA256
        jsr     fn_pb
        jsr     fn_go
        FNBEGIN FNDEVF, FNCHSHO, 1   ; read it, as hex
        lda     #1
        jsr     fn_pb
        jsr     fn_go           ; 64 characters at FN_REPLY",
  c: "if (!fuji_hash_data(SHA256, (uint8_t *)data, 5, true, buf))
    failed();                    /* 64 hex characters */",
  [Four steps on the adapter: feed bytes with INPUT, as often as needed; COMPUTE; ask the LENGTH; read the OUTPUT. HASH_COMPUTE_NO_CLEAR (`$C3`) keeps the input for another algorithm, and HASH_CLEAR (`$C2`) empties it.])

#cmd("BASE64: ENCODE and DECODE", code: "$D0--$CD / $CC--$C9", dev: "$70", nparam: "varies",
  params: [INPUT: word, the byte count; OUTPUT: word, how many bytes to read],
  payload: [INPUT: the bytes], reply: [LENGTH: 4 bytes, the size; OUTPUT: the result],
  [The same four steps as the hash. Encoding is INPUT `$D0`, COMPUTE `$CF`, LENGTH `$CE`, OUTPUT `$CD`; decoding is `$CC`, `$CB`, `$CA`, `$C9`. In C, `fuji_base64_encode_input()` and its seven siblings.])

#cmd("QR CODE: INPUT, ENCODE, LENGTH, OUTPUT", code: "$BC / $BD / $BE / $BF", dev: "$70", nparam: "varies",
  params: [INPUT: word, the count; ENCODE: version (0 to choose), error correction (0–3), shorten; LENGTH: the output mode (0 bytes, 2 bitmap); OUTPUT: word, the count],
  payload: [INPUT: the text], reply: [LENGTH: 4 bytes, the size; OUTPUT: the modules],
  [The adapter draws a QR code’s matrix; a program only has to plot it. A version 1 code is 21 × 21 modules.])

#sect[Answered with a NAK on this build]

These are in `fujiCommandID.h` but fall through every table the RS-232 build dispatches, so they earn a NAK: `ENABLE_UDPSTREAM` (`$F0`), `SET_BAUDRATE` (`$EB`), `NEW_DISK` (`$E7`), `UNMOUNT_HOST` (`$E6`), `SET_HSIO_INDEX` (`$E3`), `SET_SIO_EXTERNAL_CLOCK` (`$DF`), `ENABLE_DEVICE` and `DISABLE_DEVICE` (`$D5`, `$D4`), `RANDOM_NUMBER` (`$D3`), `GET_TIME` (`$D2`; use the clock device), `DEVICE_ENABLE_STATUS` (`$D1`), `GET_HEAP` (`$C1`), `QRCODE_CLEAR` (`$BA`), `GET_DEVICE1..10_FULLPATH` (`$A0`–`$A9`), `UPDATE_FIRMWARE` (`$90`) and `HSIO_INDEX` (`$3F`). Most tune other computers’ buses.
