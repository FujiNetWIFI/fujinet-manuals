#import "../lib.typ": *
= Command Reference: The Fuji Device

Every command device `$70` answers on this cartridge, verified against the firmware's dispatch tables: the RS232 switch in `rs232Fuji.cpp` and the four mixins every FujiNet shares (appkeys, base64, hashing, QR codes). Conventions: _nparam_ is the value written to the NPARAM register; a _byte_ parameter is a size byte of 1 then the value, a _word_ is 2 then two bytes little-endian. Replies land in the reply window at `$1B00`. Each card carries an example in 6502 assembly, using the library of Section 7, and in batari Basic, using the helpers of Section 8: `dev`, `cmd` and `npar` set, `gosub fnbeg`, the parameters and payload as stores to `FNTX`, `gosub fngo`. Any command not on a card is answered with a NAK on this build; the last section names them.

#sect[WiFi and the adapter]

#cmd("GET_ADAPTERCONFIG_EXTENDED", code: "$C4", dev: "$70", nparam: "0",
  reply: [240 bytes: `ssid[33]`, `hostname[64]`, binary `localIP`, `gateway`, `netmask`, `dnsIP` (4 each), `mac[6]`, `bssid[6]`, `fn_version[15]` at 125, then the text fields `sLocalIP[16]` at 140, `sGateway`, `sNetmask`, `sDnsIP`, `sMacAddress[18]` at 204, `sBssid` --- all NUL-terminated],
  asm: "        lda     #FNDEVF
        sta     FNDEV
        lda     #FNCADPX
        sta     FNCMD
        lda     #0
        sta     FNNPR
        jsr     FNBEG
        jsr     FNGO
; ssid at FNRPLY+0, version +125, ip text +140",
  bas: " dev = FNDEVF
 cmd = FNCADPX
 npar = 0
 gosub fnbeg
 gosub fngo
 ch = FNRPLY[140] : rem first digit of the IP",
  [The first-contact command, and the one every status screen wants: no parameters, works before WiFi is up, and its text fields save a print-an-IP routine. The compact `GET_ADAPTERCONFIG` (`$E8`) answers the first 140 bytes only, addresses in binary.])

#cmd("SCAN_NETWORKS", code: "$FD", dev: "$70", nparam: "0",
  reply: [1 byte: the number of networks found],
  [Starts a fresh scan and blocks until it finishes --- seconds. Follow with `GET_SCAN_RESULT` once per index. CONFIG shows a "scanning" row first.])

#cmd("GET_SCAN_RESULT", code: "$FC", dev: "$70", nparam: "1",
  params: [byte: result index, 0-based],
  reply: [34 bytes: `ssid[33]` then `rssi`, a signed dBm],
  asm: "        lda     #FNCSCNR
        sta     FNCMD
        lda     #1
        sta     FNNPR
        jsr     FNBEG
        lda     IDX             ; the index
        jsr     FNPB
        jsr     FNGO
; rssi at FNRPLY+33, signed",
  bas: " cmd = FNCSCNR
 npar = 1
 gosub fnbeg
 FNTX = 1
 FNTX = idx
 gosub fngo
 rssi = FNRPLY[33]",
  [One scanned network. The RSSI byte at offset 33 is a negative dBm --- closer to zero is stronger --- so bar-graph its magnitude.])

#cmd("SET_SSID", code: "$FB", dev: "$70", nparam: "1",
  params: [byte: any value --- *required but ignored*],
  payload: [*exactly 97 bytes*: `ssid[33]` then `password[64]`, NUL-padded],
  asm: "        lda     #FNCSSSD
        sta     FNCMD
        lda     #1
        sta     FNNPR
        jsr     FNBEG
        lda     #0
        jsr     FNPB            ; the dummy parameter
        ldx     #0
SS1:    lda     SSIDPW,x        ; 97 bytes: ssid[33] + password[64]
        sta     FNTX
        inx
        cpx     #97
        bne     SS1
        jsr     FNGO",
  bas: " cmd = FNCSSSD
 npar = 1
 gosub fnbeg
 FNTX = 1
 FNTX = 0
 for l = 0 to 96
 FNTX = ssidpw[l]
 next
 gosub fngo",
  [Joins a network and saves it as the default. Two sharp edges: the parameter that must be there, and the payload that must be 97 bytes --- a short one fails the transaction outright. CONFIG builds the two strings in the cartridge's path buffers 0 and 1 and emits them raw.])

#cmd("GET_SSID", code: "$FE", dev: "$70", nparam: "0",
  reply: [97 bytes: `ssid[33]` then `password[64]`, NUL-padded],
  [The current network configuration, password in clear text; the adapter is a trusted friend.])

#cmd("GET_WIFISTATUS / GET_WIFI_ENABLED", code: "$FA / $EA", dev: "$70", nparam: "0",
  reply: [`$FA`: 1 byte, 3 = connected; `$EA`: 1 byte, is the radio on],
  bas: " cmd = FNCWIFI
 npar = 0
 gosub fnbeg
 gosub fngo
 if FNRPLY[0] = 3 then goto connected",
  [The poll target while a join is in flight.])

#cmd("RESET", code: "$FF", dev: "$70", nparam: "0",
  reply: [ACK, then the adapter reboots],
  [Reboots the ESP32-S3. The RP2040 and the mailbox stay up while the link bit in STATUS drops and returns; the cartridge waits up to three seconds for the link before its first transaction after that.])

#cmd("STATUS / DEVICE_READY", code: "$53 / $00", dev: "$70", nparam: "1 / 0",
  params: [STATUS: byte, request type --- 1 for mount times],
  reply: [STATUS type 1: a 4-byte time per device slot, 0 = unmounted; DEVICE_READY: the bus self-test response],
  [`STATUS` requires its parameter on this build. `DEVICE_READY` is the round trip that proves the mailbox, the RP2040, the USB link and the adapter are all telling the truth.])

#sect[Hosts, slots and mounting]

#cmd("READ_HOST_SLOTS", code: "$F4", dev: "$70", nparam: "0",
  reply: [256 bytes: 8 slots × `hostname[32]`],
  asm: "        lda     #FNCRHST
        sta     FNCMD
        lda     #0
        sta     FNNPR
        jsr     FNBEG
        jsr     FNGO
        lda     #3              ; row 3: host 0's name
        ldx     #0              ; FNRPLY + slot*32
        ldy     #FNTCOL
        jsr     FNRRPL",
  bas: " cmd = FNCRHST
 npar = 0
 gosub fnbeg
 gosub fngo
 FNH_TROW = 3
 for l = 0 to 11
 FNH_TCHR = FNRPLY[l]
 next
 gosub fnend",
  [The host list, one transaction, rendered straight from the reply window. Slot 0 is the SD card on a standard `fujinet-pc`.])

#cmd("WRITE_HOST_SLOTS", code: "$F3", dev: "$70", nparam: "0",
  payload: [256 bytes: all 8 slots, full width],
  reply: [ACK],
  [All-or-nothing; there is no write-one-slot command. Read the table with `READ_HOST_SLOTS`, and stream it back out of the reply window into the TX page with the one edited slot substituted --- the window is stable until the commit.])

#cmd("MOUNT_HOST", code: "$F9", dev: "$70", nparam: "1",
  params: [byte: host slot, 0-based],
  reply: [ACK, or NAK if the host is unreachable],
  asm: "        lda     #FNCMHST
        sta     FNCMD
        lda     #1
        sta     FNNPR
        jsr     FNBEG
        lda     #0              ; host slot 0
        jsr     FNPB
        jsr     FNGO",
  bas: " cmd = FNCMHST
 npar = 1
 gosub fnbeg
 FNTX = 1
 FNTX = 0
 gosub fngo",
  [Connects the named host --- SD, TNFS, SMB and the rest. Required before `OPEN_DIRECTORY` or a boot. `UNMOUNT_HOST` (`$E6`) is not dispatched on this build.])

#cmd("READ_DEVICE_SLOTS / WRITE_DEVICE_SLOTS", code: "$F2 / $F1", dev: "$70", nparam: "0",
  reply: [`$F2`: the device-slot table, `hostSlot`, `mode`, `filename[]` per slot; `$F1` takes the same table back as its payload],
  [What is configured in each virtual drive. This console boots images rather than serving drives, so CONFIG leaves these screenless --- but they answer.])

#cmd("SET_DEVICE_FULLPATH", code: "$E2", dev: "$70", nparam: "3",
  params: [bytes: device slot, host slot, mode (1 = read)],
  payload: [*256 bytes*: the path, NUL-padded],
  reply: [ACK],
  asm: "        lda     #FNCSDFP
        sta     FNCMD
        lda     #3
        sta     FNNPR
        jsr     FNBEG
        lda     #0
        jsr     FNPB            ; device slot 0
        lda     #0
        jsr     FNPB            ; host slot 0
        lda     #FMREAD
        jsr     FNPB
        lda     #(PATH)&$FF
        sta     FNPTRL
        lda     #(PATH)>>8
        sta     FNPTRH
        jsr     FNPATH          ; padded to 256
        jsr     FNGO",
  bas: " cmd = FNCSDFP
 npar = 3
 gosub fnbeg
 FNTX = 1
 FNTX = 0
 FNTX = 1
 FNTX = 0
 FNTX = 1
 FNTX = FMREAD
 FNH_PATHO = FP_TX : rem path buffer, padded
 gosub fngo",
  [Names the file for a device slot: the first half of booting. The path is exactly 256 bytes; the library pads a ROM string, and the cartridge pads its own path buffer, which is where a browser has the name already.])

#cmd("MOUNT_IMAGE / UNMOUNT_IMAGE", code: "$F8 / $E9", dev: "$70", nparam: "2 / 1",
  params: [`$F8`: device slot, access mode (1 read); `$E9`: device slot],
  reply: [ACK when the mount --- and, on this console, the push --- completes],
  asm: "        lda     #FNCMIMG
        sta     FNCMD
        lda     #2
        sta     FNNPR
        jsr     FNBEG
        lda     #0
        jsr     FNPB
        lda     #FMREAD
        jsr     FNPB
        jsr     FNGO
W1:     lda     FNBST           ; then watch BOOT_STATE
        cmp     #FNBRDY
        bne     W1",
  bas: " cmd = FNCMIMG
 npar = 2
 gosub fnbeg
 FNTX = 1
 FNTX = 0
 FNTX = 1
 FNTX = FMREAD
 gosub fngo
staged
 drawscreen
 if FNBST <> FNBRDY then goto staged",
  [The second half of booting, and the cartridge's most theatrical command: while it is outstanding the adapter streams the image to the cartridge over the same link, and BOOT_STATE and BOOT_PCT narrate the progress. The cartridge allows it sixty seconds. Section 11 has the swap that follows.])

#cmd("MOUNT_ALL / SET_BOOT_MODE / CONFIG_BOOT", code: "$D7 / $D6 / $D9", dev: "$70", nparam: "0 / 1 / 1",
  reply: [ACK],
  [`MOUNT_ALL` mounts every configured slot; the other two select what the adapter offers at power-on on disk-serving platforms. On this console the claim, not a flag, decides who boots, and CONFIG never sends `CONFIG_BOOT`.])

#cmd("NEW_DISK", code: "$E7", dev: "$70", nparam: "0",
  payload: [`numSectors` (word), `sectorSize` (word), `hostSlot`, `deviceSlot`, `filename[256]`],
  reply: [ACK on creation],
  [Creates a blank image on a host: a full-struct payload with the 256-pad rule again.])

#sect[Directories]

#cmd("OPEN_DIRECTORY", code: "$F7", dev: "$70", nparam: "1",
  params: [byte: host slot],
  payload: [*256 bytes*: the path, a NUL, then an optional `*.BIN`-style filter, the rest NUL],
  reply: [ACK],
  asm: "        lda     #FNCODIR
        sta     FNCMD
        lda     #1
        sta     FNNPR
        jsr     FNBEG
        lda     #0
        jsr     FNPB            ; host slot
        jsr     FNWTX           ; the path buffer, padded to 256
        jsr     FNGO",
  bas: " cmd = FNCODIR
 npar = 1
 gosub fnbeg
 FNTX = 1
 FNTX = 0
 FNH_PATHO = FP_TX
 gosub fngo",
  [Opens a directory on a mounted host; the filter is applied on the adapter. CONFIG keeps the filter in path buffer 1 and the directory in 0, because the payload wants both in one block.])

#cmd("READ_DIR_ENTRY", code: "$F6", dev: "$70", nparam: "2",
  params: [bytes: maxlen (the width to crunch the name to --- *30, not 31*), flags (0)],
  reply: [one entry, NUL-terminated; a trailing `/` marks a subdirectory; *the end is two `$7F` bytes*],
  asm: "        lda     #FNCRDIR
        sta     FNCMD
        lda     #2
        sta     FNNPR
        jsr     FNBEG
        lda     #30
        jsr     FNPB
        lda     #0
        jsr     FNPB
        jsr     FNGO
        jsr     FNEOF           ; Z: the end",
  bas: " cmd = FNCRDIR
 npar = 2
 gosub fnbeg
 FNTX = 1
 FNTX = 30
 FNTX = 1
 FNTX = 0
 gosub fngo
 if FNRPLY[0] <> 127 then goto entry
 if FNRPLY[1] = 127 then goto atend
entry",
  [One entry per transaction; the entry advances the cursor itself. At a `maxlen` of exactly 31 the firmware prepends icon bytes. Never read past the end: a `fujinet-pc` SD host answers `..` forever and every later seek is refused.])

#cmd("SET_DIRECTORY_POSITION / GET_DIRECTORY_POSITION", code: "$E4 / $E5", dev: "$70", nparam: "1 / 0",
  params: [`$E4`: *one word*, the absolute entry index],
  reply: [`$E5`: a word, the current index; `$E4`: ACK],
  asm: "        lda     #FNCSDPS
        sta     FNCMD
        lda     #1
        sta     FNNPR
        jsr     FNBEG
        lda     PAGE0           ; index, low
        ldx     #0              ; high
        jsr     FNPW            ; ONE param of TWO bytes
        jsr     FNGO",
  bas: " cmd = FNCSDPS
 npar = 1
 gosub fnbeg
 FNTX = 2
 FNTX = page0
 FNTX = 0
 gosub fngo",
  [Seek and tell for the open directory: paging in one command. The seek's parameter is one two-byte parameter, not two one-byte ones; the wrong shape is a NAK with nothing to point at.])

#cmd("CLOSE_DIRECTORY", code: "$F5", dev: "$70", nparam: "0",
  reply: [ACK],
  [Closes the walk. Directories are a scarce resource on the adapter; close what you open.])

#sect[Files, prefixes and paths]

#cmd("COPY_FILE", code: "$D8", dev: "$70", nparam: "2",
  params: [bytes: source host, destination host --- *both 1-based*],
  payload: [*exact length*, no padding: `sourcepath|destdir/`],
  reply: [ACK when the copy completes; the cartridge allows sixty seconds],
  [Host-to-host copy without a byte passing through the console. The payload is read as a string, so it goes at exact length --- one padding NUL would land inside the destination --- and its host parameters are 1-based, alone among slot parameters. When the destination ends in `/`, the adapter appends the source's basename itself, which is why CONFIG's working directory keeps its trailing slash.])

#cmd("SET_HOST_PREFIX / GET_HOST_PREFIX", code: "$E1 / $E0", dev: "$70", nparam: "1",
  params: [byte: host slot; SET carries the prefix as its payload],
  reply: [GET: the prefix],
  [A per-host working directory prepended to relative paths.])

#cmd("GET_DEVICE_FULLPATH", code: "$DA", dev: "$70", nparam: "1",
  params: [byte: device slot], reply: [the stored path],
  [Reads back what `SET_DEVICE_FULLPATH` stored.])

#sect[Appkeys]

#cmd("OPEN_APPKEY", code: "$DC", dev: "$70", nparam: "0",
  payload: [6 bytes: `creator` (word), `app`, `key`, `mode` (0 read, 1 write), `reserved`],
  reply: [ACK; NAK with no SD card, a creator of 0, or a bad mode],
  asm: "        lda     #FNCAKOP
        sta     FNCMD
        lda     #0
        sta     FNNPR
        jsr     FNBEG
        lda     #AKCREAT        ; creator, low then high
        sta     FNTX
        lda     #0
        sta     FNTX
        lda     #AKAPP
        sta     FNTX
        lda     #AKKEY
        sta     FNTX
        lda     #AKMRD          ; mode
        sta     FNTX
        lda     #0              ; reserved: not optional
        sta     FNTX
        jsr     FNGO",
  bas: " cmd = FNCAKOP
 npar = 0
 gosub fnbeg
 FNTX = AKCREAT
 FNTX = 0
 FNTX = AKAPP
 FNTX = AKKEY
 FNTX = AKMRD
 FNTX = 0
 gosub fngo",
  [Selects which key the next read or write touches. The payload is one packed struct; leave off the reserved byte and the adapter waits for it, which reads back as a timeout. The file is `/FujiNet/CCCCAAKK.key`; the value cap is 64 bytes.])

#cmd("READ_APPKEY / WRITE_APPKEY / CLOSE_APPKEY", code: "$DD / $DE / $DB", dev: "$70", nparam: "0 / 1 / 0",
  params: [WRITE: byte, the length],
  payload: [WRITE: the value, up to 64 bytes],
  reply: [READ: a word length, then the value; the others ACK],
  asm: "        lda     #FNCAKRD
        sta     FNCMD
        lda     #0
        sta     FNNPR
        jsr     FNBEG
        jsr     FNGO
        lda     #3
        ldx     #2              ; past the length word
        ldy     #FNTCOL
        jsr     FNRRPL",
  bas: " cmd = FNCAKRD
 npar = 0
 gosub fnbeg
 gosub fngo
 len = FNRPLY[0]
 ch = FNRPLY[2] : rem the first byte of the value",
  [`READ_APPKEY`'s reply is length-prefixed on this bus. A successful write resets the selection, so each write needs a fresh open in write mode. Section 12 has both directions.])

#sect[Utilities]

#cmd("GENERATE_GUID", code: "$BB", dev: "$70", nparam: "0",
  reply: [a 36-character UUID and a NUL],
  bas: " cmd = FNCGUID
 npar = 0
 gosub fnbeg
 gosub fngo
 FNH_TROW = 5
 for l = 0 to 11
 FNH_TCHR = FNRPLY[l]
 next
 gosub fnend",
  [A fresh printable unique id. `RANDOM_NUMBER` (`$D3`) is not dispatched on this build; the adapter's entropy reaches the console through a hash, or a GUID.])

#cmd("BASE64 / HASH: INPUT, COMPUTE, LENGTH, OUTPUT", code: "$D0--$C9 / $C8--$C2", dev: "$70", nparam: "varies",
  params: [INPUT: word, the byte count; HASH COMPUTE: byte, the algorithm (0 MD5, 1 SHA-1, 3 SHA-256, 4 SHA-512); LENGTH and OUTPUT: byte, 1 = hex text],
  payload: [INPUT: the bytes], reply: [LENGTH: the size; OUTPUT: the result],
  [Four-step pipelines on the adapter: feed bytes with INPUT, as often as needed; COMPUTE; ask LENGTH; drain with OUTPUT. The hash set is `HASH_INPUT` `$C8`, `HASH_COMPUTE` `$C7`, `HASH_LENGTH` `$C6`, `HASH_OUTPUT` `$C5`; `HASH_COMPUTE_NO_CLEAR` (`$C3`) keeps the input for another algorithm and `HASH_CLEAR` (`$C2`) empties it. Base64 has an encode set --- `INPUT` `$D0`, `COMPUTE` `$CF`, `LENGTH` `$CE`, `OUTPUT` `$CD` --- and a decode set --- `$CC`, `$CB`, `$CA`, `$C9` --- of the same four steps. Section 12 has the hash in both languages.])

#cmd("QR CODE: INPUT, ENCODE, LENGTH, OUTPUT, CLEAR", code: "$BC / $BD / $BE / $BF / $BA", dev: "$70", nparam: "varies",
  params: [INPUT: word count; ENCODE: version (0 = auto), error-correction level (0--3), shorten; LENGTH: output mode (0 binary, 2 bitmap); OUTPUT: word count],
  payload: [INPUT: the text], reply: [LENGTH: a 4-byte size; OUTPUT: the module data],
  [The adapter renders a QR matrix. A version-1 code is 21 × 21 modules, and the playfield is 40 bits wide, so it fits, at two playfield bits per module and a row per pair of lines.])

#sect[Answered with a NAK on this build]

These `fujiCommandID.h` opcodes fall through every dispatch table in the RS232 build and earn a NAK: `ENABLE_UDPSTREAM` (`$F0`), `SET_BAUDRATE` (`$EB`), `UNMOUNT_HOST` (`$E6`), `SET_HSIO_INDEX` (`$E3`), `SET_SIO_EXTERNAL_CLOCK` (`$DF`), `ENABLE_DEVICE` and `DISABLE_DEVICE` (`$D5`, `$D4`), `RANDOM_NUMBER` (`$D3`), `GET_TIME` (`$D2` --- use the clock device), `DEVICE_ENABLE_STATUS` (`$D1`), `GET_HEAP` (`$C1`), `GET_DEVICE1..10_FULLPATH` (`$A0`--`$A9`), `UPDATE_FIRMWARE` (`$90`) and `HSIO_INDEX` (`$3F`). Most are other platforms' bus tuning.
