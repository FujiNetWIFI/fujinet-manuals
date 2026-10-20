#import "../lib.typ": *
#set page(columns: 1)
#refpage.update(true)

= Command Reference: The Fuji Device <ref-fuji>

#hang([], [Every command device `$70` answers, checked against the firmware the cartridge’s ESP32-S3 runs: the RS-232 build’s `rs232Fuji.cpp` and the four mixins every FujiNet shares (app keys, base64, hashing, QR codes), at the revision in the Parts List. On the cards, _nparam_ is the value for the NPARAM register, and each parameter goes into the TX stream as its size and then its value: a _byte_ is 1 and the byte, a _word_ 2 and two bytes, low first. The reply is in the reply window at `$E400`.

The examples use the runtime, the handbook’s `s2defs.inc` and `booklib.inc`, and labels `failed` and `done` of the program’s own. Every one of them is assembled by `tools/snipcheck.py`.])

#sect[WiFi and the adapter]

#cmd("GET_ADAPTERCONFIG_EXTENDED / GET_ADAPTERCONFIG", code: "$C4 / $E8", dev: "$70", nparam: "0",
  reply: [`$C4`: 240 bytes, laid out in First Contact. `$E8`: the first 140, the addresses in binary only],
  asm: "        FNBEGIN FNDEVF, FNCADPX, 0
        FCALL   fn_go
        BNZ     failed
        LDR     R8, 140         ; the IP address, as text
        LDI     15
        FCALL   d_rpl           ; the cart prints it",
  [The first-contact command, and the one every status screen wants. It works before the WiFi is up, and its text fields go straight to the screen with PRINT.])

#cmd("SCAN_NETWORKS", code: "$FD", dev: "$70", nparam: "0",
  reply: [1 byte: how many networks were found],
  asm: "        FNBEGIN FNDEVF, FNCSCAN, 0
        FCALL   fn_go
        BNZ     failed
        PEEK    FN_REPLY        ; how many
        PLO     RA",
  [Starts a fresh scan and answers when it is done, which takes seconds: well inside the cartridge’s five. Follow it with GET_SCAN_RESULT once for each network.])

#cmd("GET_SCAN_RESULT", code: "$FC", dev: "$70", nparam: "1",
  params: [byte: which result, from 0],
  reply: [34 bytes: the SSID (33, NUL-terminated), then the signal strength, a signed dBm],
  asm: "        FNBEGIN FNDEVF, FNCSCNR, 1
        GLO     RA              ; which network
        FCALL   fn_pb
        FCALL   fn_go
        BNZ     failed
        PEEK    FN_REPLY+33     ; strength: negative dBm",
  [The strength is negative: closer to zero is stronger.])

#cmd("SET_SSID", code: "$FB", dev: "$70", nparam: "1",
  params: [byte: any value; *required but ignored*],
  payload: [*exactly 97 bytes*: the SSID (33) then the password (64), each NUL-padded],
  reply: [ACK],
  asm: "        FNBEGIN FNDEVF, FNCSSSD, 1
        LDI     0
        FCALL   fn_pb           ; must be there
        LDR     RA, ssidpw      ; ssid[33] + password[64]
        LDI     97
        PLO     RB
pw:     LDA     RA
        FCALL   fn_txb
        DEC     RB
        GLO     RB
        BNZ     pw
        FCALL   fn_go",
  [Joins a network and saves it as the default. Two sharp edges: the parameter must be sent although nothing reads it, and the payload must be all 97 bytes; a short one fails the transaction.])

#cmd("GET_SSID", code: "$FE", dev: "$70", nparam: "0",
  reply: [97 bytes: the SSID (33) then the password (64)],
  asm: "        FNBEGIN FNDEVF, FNCGSSD, 0
        FCALL   fn_go
        BNZ     failed          ; SSID at $E400, password +33",
  [The network the adapter is set to join, password in clear text.])

#cmd("GET_WIFISTATUS / GET_WIFI_ENABLED", code: "$FA / $EA", dev: "$70", nparam: "0",
  reply: [`$FA`: 1 byte, 3 when connected; `$EA`: 1 byte, 1 if the radio is on],
  asm: "        FNBEGIN FNDEVF, FNCWIFI, 0
        FCALL   fn_go
        BNZ     failed
        PEEK    FN_REPLY
        XRI     3               ; connected?
        BZ      done",
  [What to poll while a join is in progress. CONFIG polls it once a second.])

#cmd("RESET", code: "$FF", dev: "$70", nparam: "0",
  reply: [ACK, then the adapter restarts],
  [Restarts the ESP32-S3. The cartridge, its mailbox and your program carry on; the link bit of STAT, `$E801`, drops and comes back, and the cartridge waits up to three seconds for it before the next transaction.])

#cmd("STATUS / DEVICE_READY", code: "$53 / $00", dev: "$70", nparam: "1 / 0",
  params: [STATUS: byte, the kind of status wanted (1: mount times)],
  reply: [STATUS 1: four bytes per device slot, a time, 0 if nothing is mounted; DEVICE_READY: the bus test’s answer],
  [STATUS needs its parameter on this build. DEVICE_READY is a round trip with no other effect: it proves the mailbox, the cartridge, the USB link and the adapter at once.])

#sect[Hosts, slots and mounting]

#cmd("READ_HOST_SLOTS", code: "$F4", dev: "$70", nparam: "0",
  reply: [256 bytes: eight host names of 32 bytes],
  asm: "        FNBEGIN FNDEVF, FNCRHST, 0
        FCALL   fn_go
        BNZ     failed
        LDI     20H             ; host 0's name, row 2
        FCALL   d_at
        LDR     R8, 0           ; reply + slot * 32
        LDI     16
        FCALL   d_rpl",
  [Slot 0 is the SD card on a standard `fujinet-pc`.])

#cmd("WRITE_HOST_SLOTS", code: "$F3", dev: "$70", nparam: "0",
  payload: [256 bytes: all eight slots, 32 bytes each],
  reply: [ACK],
  [All or nothing: there is no command to write one slot. Read the table with READ_HOST_SLOTS and stream it back with the one slot changed; the reply window holds still until the next launch, so the stream can be copied straight out of it with LDA. CONFIG renames a host this way.])

#cmd("MOUNT_HOST", code: "$F9", dev: "$70", nparam: "1",
  params: [byte: the host slot, from 0],
  reply: [ACK; NAK if the host cannot be reached],
  asm: "        FNBEGIN FNDEVF, FNCMHST, 1
        LDI     0               ; host slot 0
        FCALL   fn_pb
        FCALL   fn_go
        BNZ     failed
        FCALL   fn_ack
        BNZ     failed",
  [Connects the host: SD, TNFS, SMB and the rest. Needed before OPEN_DIRECTORY or a mount. UNMOUNT_HOST (`$E6`) is not answered on this build.])

#cmd("READ_DEVICE_SLOTS / WRITE_DEVICE_SLOTS", code: "$F2 / $F1", dev: "$70", nparam: "0",
  reply: [`$F2`: the device-slot table: host slot, mode and file name for each slot; `$F1` takes the same table as its payload],
  [What is set up in each of the FujiNet’s virtual drives. A Studio II boots images rather than reading drives, so CONFIG does not show them, but they answer.])

#cmd("SET_DEVICE_FULLPATH", code: "$E2", dev: "$70", nparam: "3",
  params: [bytes: device slot, host slot, mode (1 to read)],
  payload: [*256 bytes*: the path, NUL-padded],
  reply: [ACK],
  asm: "        FNBEGIN FNDEVF, FNCSDFP, 3
        LDI     0               ; device slot
        FCALL   fn_pb
        LDI     0               ; host slot
        FCALL   fn_pb
        LDI     FMREAD
        FCALL   fn_pb
        LDR     R8, file
        FCALL   fn_path         ; padded to 256
        GOACK",
  [Names the file for a device slot: the first half of booting.])

#cmd("MOUNT_IMAGE / UNMOUNT_IMAGE", code: "$F8 / $E9", dev: "$70", nparam: "2 / 1",
  params: [`$F8`: device slot, mode (1 to read); `$E9`: device slot],
  reply: [ACK when the mount completes],
  asm: "        FNBEGIN FNDEVF, FNCMIMG, 2
        LDI     0               ; device slot
        FCALL   fn_pb
        LDI     FMREAD
        FCALL   fn_pb
        SLOW    66              ; past the cart's 60
        GOACK
push:   PEEK    FN_BOOTSTATE    ; the image, staged?
        XRI     FN_BOOT_READY
        BNZ     push",
  [The second half of booting. Before it answers, the FujiNet pushes the file into the cartridge, and BOOT_STATE and BOOT_PCT report the progress; the cartridge allows sixty seconds. Directories, Mount and Boot has the rest.])

#cmd("MOUNT_ALL / SET_BOOT_MODE / CONFIG_BOOT", code: "$D7 / $D6 / $D9", dev: "$70", nparam: "0 / 1 / 1",
  params: [SET_BOOT_MODE: byte, the mode; CONFIG_BOOT: byte, on or off],
  reply: [ACK],
  [MOUNT_ALL mounts every slot that has a file; the other two choose what the adapter serves at power-on on computers that boot from its drives. On the Studio II the cartridge decides what boots, and CONFIG does not send them.])

#sect[Directories]

#cmd("OPEN_DIRECTORY", code: "$F7", dev: "$70", nparam: "1",
  params: [byte: the host slot],
  payload: [*256 bytes*: the path, a NUL, then an optional filter such as `*.ST2`, the rest NULs],
  reply: [ACK],
  asm: "        FNBEGIN FNDEVF, FNCODIR, 1
        LDI     0               ; host slot
        FCALL   fn_pb
        LDR     R8, path
        FCALL   fn_path
        FCALL   fn_go
        BNZ     failed",
  [Opens a directory on a mounted host. The adapter applies the filter, so a program never sees what it does not want.])

#cmd("READ_DIR_ENTRY", code: "$F6", dev: "$70", nparam: "2",
  params: [bytes: the longest name wanted (*never 31*), flags (0)],
  reply: [one name, NUL-terminated, a `/` at the end of a directory’s; *`$7F`, `$7F` when there are no more*],
  asm: "        FNBEGIN FNDEVF, FNCRDIR, 2
        LDI     15
        FCALL   fn_pb
        LDI     0
        FCALL   fn_pb
        FCALL   fn_go
        BNZ     failed
        PEEK    FN_REPLY
        XRI     7FH             ; the end?
        BZ      done",
  [One name a call; the adapter moves on by itself. At a length of exactly 31 the firmware puts icon bytes in front of the name. Stop at the end marker: an SD host keeps answering `..` past it. CONFIG reads a whole page of names in one call, with flag bits that pack several entries into the reply.])

#cmd("SET_DIRECTORY_POSITION / GET_DIRECTORY_POSITION", code: "$E4 / $E5", dev: "$70", nparam: "1 / 0",
  params: [`$E4`: *one word*, the entry number],
  reply: [`$E5`: a word, the current entry number; `$E4`: ACK],
  asm: "        FNBEGIN FNDEVF, FNCSDPS, 1
        LDR     R8, 8           ; entry 8: page two
        FCALL   fn_pw
        FCALL   fn_go",
  [Seek and tell for the open directory: paging in one command. The position is one two-byte parameter, not two one-byte ones.])

#cmd("CLOSE_DIRECTORY", code: "$F5", dev: "$70", nparam: "0",
  reply: [ACK],
  asm: "        FNBEGIN FNDEVF, FNCCDIR, 0
        FCALL   fn_go",
  [Close what you open: the adapter has room for few open directories.])

#sect[Files, prefixes and paths]

#cmd("COPY_FILE", code: "$D8", dev: "$70", nparam: "2",
  params: [bytes: source host, destination host, *counting from 1*],
  payload: [`source|destination`; at its own length, or NUL-padded],
  reply: [ACK when the copy is done; the cartridge allows sixty seconds],
  asm: "        FNBEGIN FNDEVF, FNCCOPY, 2
        LDI     1               ; host 0, from 1
        FCALL   fn_pb
        LDI     1
        FCALL   fn_pb
        LDR     R8, spec        ; source|destination
        FCALL   fn_str
        SLOW    66
        GOACK",
  [Host to host, without a byte passing through the console. Its hosts count from 1, unlike every other slot number; 0 is refused. When the destination ends in `/`, the adapter adds the source’s file name. CONFIG’s Copy screen sends it at its own length.])

#cmd("SET_HOST_PREFIX / GET_HOST_PREFIX", code: "$E1 / $E0", dev: "$70", nparam: "1",
  params: [byte: the host slot; SET carries the prefix as its payload],
  reply: [GET: the prefix],
  [A working directory per host, put in front of relative paths.])

#cmd("GET_DEVICE_FULLPATH", code: "$DA", dev: "$70", nparam: "1",
  params: [byte: the device slot], reply: [the path SET_DEVICE_FULLPATH stored],
  [What a device slot holds, as one string.])

#sect[App keys]

#cmd("OPEN_APPKEY", code: "$DC", dev: "$70", nparam: "0",
  payload: [6 bytes: creator (word), app, key, mode (0 read, 1 write), and a reserved 0],
  reply: [ACK; NAK with no SD card, a creator of 0 or a bad mode],
  asm: "        FNBEGIN FNDEVF, FNCAKOP, 0
        LDI     02H             ; creator $1802, low first
        FCALL   fn_txb
        LDI     18H
        FCALL   fn_txb
        LDI     0FFH            ; app
        FCALL   fn_txb
        LDI     0               ; key
        FCALL   fn_txb
        LDI     AKMRD           ; mode
        FCALL   fn_txb
        LDI     0               ; reserved: required
        FCALL   fn_txb
        GOACK",
  [Chooses the key the next read or write uses. The payload is one packed structure; leave off the reserved byte and the adapter waits for it until the transaction times out. On the SD card the key is the file `/FujiNet/CCCCAAKK.key`; it holds 64 bytes at most.])

#cmd("READ_APPKEY / WRITE_APPKEY / CLOSE_APPKEY", code: "$DD / $DE / $DB", dev: "$70", nparam: "0 / 1 / 0",
  params: [WRITE: byte, the length],
  payload: [WRITE: the value, at most 64 bytes],
  reply: [READ: a word, the length, then the value; the others: ACK],
  asm: "        FNBEGIN FNDEVF, FNCAKRD, 0
        FCALL   fn_go
        BNZ     failed
        PEEK    FN_REPLY        ; the length
        BZ      done            ; empty
        LDR     R8, 2           ; the value: offset 2
        PEEK    FN_REPLY
        FCALL   d_rpl",
  [A write ends the selection, so each write needs its own OPEN in write mode. App Keys, Clock and Utilities has both directions.])

#sect[Utilities]

#cmd("GENERATE_GUID", code: "$BB", dev: "$70", nparam: "0",
  reply: [36 characters and a NUL],
  asm: "        FNBEGIN FNDEVF, FNCGUID, 0
        FCALL   fn_go
        BNZ     failed
        LDI     40H             ; rows 4 and 5, wrapped
        FCALL   d_at
        LDR     R8, 0
        LDI     32
        FCALL   d_rpl",
  [A fresh, printable, unique id: 36 characters, more than two rows of the screen. RANDOM_NUMBER (`$D3`) is not answered on this build; the adapter’s randomness reaches a program through a GUID or a hash.])

#cmd("HASH: INPUT, COMPUTE, LENGTH, OUTPUT", code: "$C8 / $C7 / $C6 / $C5", dev: "$70", nparam: "1",
  params: [INPUT: word, the byte count; COMPUTE: byte, the algorithm (0 MD5, 1 SHA-1, 3 SHA-256, 4 SHA-512); LENGTH and OUTPUT: byte, 1 for hex text, 0 for binary],
  payload: [INPUT: the bytes], reply: [LENGTH: the size; OUTPUT: the hash],
  asm: "        FNBEGIN FNDEVF, FNCHSHL, 1
        LDI     1               ; as text
        FCALL   fn_pb
        FCALL   fn_go
        BNZ     failed
        PEEK    FN_REPLY        ; 64 for SHA-256",
  [Four steps on the adapter: feed bytes with INPUT, as often as needed; COMPUTE; ask the LENGTH; read the OUTPUT. App Keys, Clock and Utilities has the whole sequence. HASH_COMPUTE_NO_CLEAR (`$C3`) keeps the input for another algorithm, and HASH_CLEAR (`$C2`) empties it.])

#cmd("BASE64: ENCODE and DECODE", code: "$D0–$CD / $CC–$C9", dev: "$70", nparam: "varies",
  params: [INPUT: word, the byte count; OUTPUT: word, how many bytes to read],
  payload: [INPUT: the bytes], reply: [LENGTH: 4 bytes, the size; OUTPUT: the result],
  [The same four steps as the hash. Encoding is INPUT `$D0`, COMPUTE `$CF`, LENGTH `$CE`, OUTPUT `$CD`; decoding is `$CC`, `$CB`, `$CA`, `$C9`.])

#cmd("QR CODE: INPUT, ENCODE, LENGTH, OUTPUT", code: "$BC / $BD / $BE / $BF", dev: "$70", nparam: "varies",
  params: [INPUT: word, the count; ENCODE: version (0 to choose), error correction (0–3), shorten; LENGTH: the output mode (0 bytes, 2 bitmap); OUTPUT: word, the count],
  payload: [INPUT: the text], reply: [LENGTH: 4 bytes, the size; OUTPUT: the modules],
  [The adapter draws a QR code’s matrix; a program only has to plot it. A version 1 code is 21 × 21 modules: with a mosaic cell of 2 × 3 squares, 11 cells by 7.])

#sect[Answered with a NAK on this build]

#hang([], [These are in `fujiCommandID.h` but fall through every table the RS-232 build dispatches, so they earn a NAK: `ENABLE_UDPSTREAM` (`$F0`), `SET_BAUDRATE` (`$EB`), `NEW_DISK` (`$E7`), `UNMOUNT_HOST` (`$E6`), `SET_HSIO_INDEX` (`$E3`), `SET_SIO_EXTERNAL_CLOCK` (`$DF`), `ENABLE_DEVICE` and `DISABLE_DEVICE` (`$D5`, `$D4`), `RANDOM_NUMBER` (`$D3`), `GET_TIME` (`$D2`; use the clock device), `DEVICE_ENABLE_STATUS` (`$D1`), `GET_HEAP` (`$C1`), `QRCODE_CLEAR` (`$BA`), `GET_DEVICE1..10_FULLPATH` (`$A0`–`$A9`), `UPDATE_FIRMWARE` (`$90`) and `HSIO_INDEX` (`$3F`). Most tune other computers’ buses.])

#refpage.update(false)
