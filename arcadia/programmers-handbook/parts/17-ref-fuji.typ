#import "../lib.typ": *

= Command Reference: The Fuji Device <ref-fuji>

Every command device `$70` answers, checked against the firmware the network
chip runs: the RS-232 build’s `rs232Fuji.cpp` and the four mixins every
FujiNet shares (app keys, base64, hashing, QR codes), at the revision in the
Parts List. On the cards, _nparam_ is the value for the NPARAM register, and
each parameter goes into the TX stream as its size and then its value: a
_byte_ is 1 and the byte, a _word_ 2 and two bytes, low first. The reply is
in the window at `$2B00`, 256 bytes at a time.

The examples use the runtime, `bookdefs.inc` and `booklib.inc`, and labels
of the program’s own such as `DONE` and the strings they name. Every one is
assembled by `tools/snipcheck.py`.

== WiFi and the adapter

#cmd("GET_ADAPTERCONFIG_EXTENDED / GET_ADAPTERCONFIG", code: "$C4 / $E8", dev: "$70", nparam: "0",
  reply: [`$C4`: 240 bytes, laid out in Section 10. `$E8`: the first 140, the addresses in binary only],
  asm: "        FNBEGIN FNDFUJI, FCACFGX, 0
        BSTA,UN FNGO
        BCFA,EQ FAIL
        SETSTR  FNRDATA+140     ; the IP address, as text
        LODI,R2 $90-1
        BSTA,UN DPRINT",
  [The first-contact command, and the one every status screen wants. It
   works before the WiFi is up, and its text fields print straight out of the
   window.])

#cmd("SCAN_NETWORKS", code: "$FD", dev: "$70", nparam: "0",
  reply: [1 byte: how many networks were found],
  asm: "        FNBEGIN FNDFUJI, FCSCAN, 0
        BSTA,UN FNGO
        BCFA,EQ FAIL
        LODA,R0 *FRDP           ; how many
        STRA,R0 NNETS",
  [Starts a fresh scan and answers when it is done, which takes seconds:
   inside the cartridge’s five, usually. Follow it with GET_SCAN_RESULT once
   for each network.])

#cmd("GET_SCAN_RESULT", code: "$FC", dev: "$70", nparam: "1",
  params: [byte: which result, from 0],
  reply: [34 bytes: the SSID (33, NUL-terminated), then the signal strength, a signed dBm],
  asm: "        FNBEGIN FNDFUJI, FCSCANR, 1
        LODA,R2 WHICH           ; which network
        BSTA,UN FNPARB
        BSTA,UN FNGO
        BCFA,EQ FAIL
        LODI,R1 33
        LODA,R0 *FRDP,R1        ; strength: negative dBm",
  [The strength is negative: closer to zero is stronger.])

#cmd("SET_SSID", code: "$FB", dev: "$70", nparam: "1",
  params: [byte: any value; *required but ignored*],
  payload: [*exactly 97 bytes*: the SSID (33) then the password (64), each NUL-padded],
  reply: [ACK],
  asm: "        FNBEGIN FNDFUJI, FCSSSID, 1
        LODI,R2 0
        BSTA,UN FNPARB          ; must be there
        SETFSTR SSIDPW          ; ssid[33], password[64]
        LODI,R2 97
        BSTA,UN FNTXN
        BSTA,UN FNGO
        BCFA,EQ FAIL",
  [Joins a network and saves it as the default. Two sharp edges: the
   parameter must be sent although nothing reads it, and the payload must be
   all 97 bytes; a short one fails. CONFIG builds the 97 bytes in the lower
   screen’s RAM.])

#cmd("GET_SSID", code: "$FE", dev: "$70", nparam: "0",
  reply: [97 bytes: the SSID (33) then the password (64)],
  asm: "        FNBEGIN FNDFUJI, FCGSSID, 0
        BSTA,UN FNGO            ; SSID at $2B00, password at $2B21
        BCFA,EQ FAIL",
  [The network the adapter is set to join, the password in clear.])

#cmd("GET_WIFISTATUS / GET_WIFI_ENABLED", code: "$FA / $EA", dev: "$70", nparam: "0",
  reply: [`$FA`: 1 byte, 3 when connected; `$EA`: 1 byte, 1 if the radio is on],
  asm: "        FNBEGIN FNDFUJI, FCWIFIS, 0
        BSTA,UN FNGO
        BCFA,EQ FAIL
        LODA,R0 *FRDP
        COMI,R0 3               ; connected?
        BCTA,EQ DONE",
  [What to poll while a join is under way. CONFIG polls it once a second.])

#cmd("RESET", code: "$FF", dev: "$70", nparam: "0",
  reply: [ACK, then the adapter restarts],
  [Restarts the network chip. The game chip, its mailbox and your program
   carry on; the link bit of STATUS, `$2C01`, drops and comes back, and the
   cartridge waits up to three seconds for it before the next transaction.])

#cmd("STATUS / DEVICE_READY", code: "$53 / $00", dev: "$70", nparam: "1 / 0",
  params: [STATUS: byte, the kind of status wanted (1: mount times)],
  reply: [STATUS 1: four bytes a device slot, a time, 0 if nothing is mounted; DEVICE_READY: the bus test’s answer],
  [STATUS needs its parameter on this build. DEVICE_READY is a round trip
   with no other effect: it proves the mailbox, the game chip, the USB link
   and the adapter at once.])

== Hosts, slots and mounting

#cmd("READ_HOST_SLOTS", code: "$F4", dev: "$70", nparam: "0",
  reply: [256 bytes: eight host names of 32 bytes -- the whole window],
  asm: "        FNBEGIN FNDFUJI, FCRHSL, 0
        BSTA,UN FNGO
        BCFA,EQ FAIL
        SETSTR  FNRDATA+32      ; host 1's name
        LODI,R2 $30-1           ; row 3
        BSTA,UN DPRINT",
  [Slot 0 is the memory card on a standard fujinet-pc. A name longer than 16
   characters runs on to the next row: CONFIG cuts it.])

#cmd("WRITE_HOST_SLOTS", code: "$F3", dev: "$70", nparam: "0",
  payload: [256 bytes: all eight slots, 32 bytes each],
  reply: [ACK],
  [All or nothing: there is no command to write one slot. Read the table
   with READ_HOST_SLOTS and stream it back with the one slot changed. The
   reply window holds still until the next launch, so the stream can be read
   straight out of it -- `SETFSTR FNRDATA` and `FNTXN` -- with the changed
   slot sent from RAM in its place. CONFIG renames a host this way.])

#cmd("MOUNT_HOST", code: "$F9", dev: "$70", nparam: "1",
  params: [byte: the host slot, from 0],
  reply: [ACK; NAK if the host cannot be reached],
  asm: "        FNBEGIN FNDFUJI, FCMHOST, 1
        LODI,R2 0               ; host slot 0
        BSTA,UN FNPARB
        BSTA,UN FNGO
        BCFA,EQ FAIL",
  [Connects the host: SD, TNFS, SMB and the rest. Needed before
   OPEN_DIRECTORY or a mount. UNMOUNT_HOST (`$E6`) is not answered on this
   build.])

#cmd("READ_DEVICE_SLOTS / WRITE_DEVICE_SLOTS", code: "$F2 / $F1", dev: "$70", nparam: "0",
  reply: [`$F2`: the device-slot table: host slot, mode and file name for each slot; `$F1` takes the same table as its payload],
  [What is set up in each of the FujiNet’s virtual drives. The Arcadia boots
   images rather than reading drives, so CONFIG does not show them, but they
   answer.])

#cmd("SET_DEVICE_FULLPATH", code: "$E2", dev: "$70", nparam: "3",
  params: [bytes: device slot, host slot, mode (1 to read)],
  payload: [*256 bytes*: the path, NUL-padded],
  reply: [ACK],
  asm: "        FNBEGIN FNDFUJI, FCSDFP, 3
        LODI,R2 0               ; device slot
        BSTA,UN FNPARB
        LODI,R2 0               ; host slot
        BSTA,UN FNPARB
        LODI,R2 FMREAD
        BSTA,UN FNPARB
        SETFSTR FILE
        BSTA,UN FNPATH          ; padded to 256
        BSTA,UN FNGO
        BCFA,EQ FAIL",
  [Names the file for a device slot: the first half of booting.])

#cmd("MOUNT_IMAGE / UNMOUNT_IMAGE", code: "$F8 / $E9", dev: "$70", nparam: "2 / 1",
  params: [`$F8`: device slot, mode (1 to read); `$E9`: device slot],
  reply: [ACK when the mount is done, the image staged in the cartridge],
  asm: "        FNBEGIN FNDFUJI, FCMIMG, 2
        LODI,R2 0               ; device slot
        BSTA,UN FNPARB
        LODI,R2 FMREAD
        BSTA,UN FNPARB
        BSTA,UN FNGO            ; up to 60 s
        BCFA,EQ FAIL
PUSH:   LODA,R0 *FBSTP          ; the image, staged?
        COMI,R0 FBREADY
        BCFR,EQ PUSH",
  [The second half of booting. Before it answers, the FujiNet pushes the
   file into the cartridge, and BOOT_STATE and BOOT_PCT report the
   progress; the cartridge allows sixty seconds. Section 13 has the rest.])

#cmd("MOUNT_ALL / SET_BOOT_MODE / CONFIG_BOOT", code: "$D7 / $D6 / $D9", dev: "$70", nparam: "0 / 1 / 1",
  params: [SET_BOOT_MODE: byte, the mode; CONFIG_BOOT: byte, on or off],
  reply: [ACK],
  [MOUNT_ALL mounts every slot that has a file; the other two choose what
   the adapter serves at power-on on computers that boot from its drives. On
   the Arcadia the cartridge decides what boots, and CONFIG does not send
   them.])

== Directories

#cmd("OPEN_DIRECTORY", code: "$F7", dev: "$70", nparam: "1",
  params: [byte: the host slot],
  payload: [*256 bytes*: the path, a NUL, then an optional filter such as `*.BIN`, the rest NULs],
  reply: [ACK],
  asm: "        FNBEGIN FNDFUJI, FCODIR, 1
        LODI,R2 0               ; host slot
        BSTA,UN FNPARB
        SETFSTR PATH
        BSTA,UN FNPATH
        BSTA,UN FNGO
        BCFA,EQ FAIL",
  [Opens a directory on a mounted host. The adapter applies the filter, so a
   program never sees what it does not want.])

#cmd("READ_DIR_ENTRY", code: "$F6", dev: "$70", nparam: "2",
  params: [bytes: the longest name wanted (*36 or more*), flags (0)],
  reply: [one name, NUL-terminated, a `/` at the end of a folder’s; *`$7F`, `$7F` when there are no more*],
  asm: "        FNBEGIN FNDFUJI, FCRDIR, 2
        LODI,R2 36
        BSTA,UN FNPARB
        LODI,R2 0
        BSTA,UN FNPARB
        BSTA,UN FNGO
        BCFA,EQ FAIL
        LODA,R0 *FRDP
        COMI,R0 $7F             ; the end?
        BCTA,EQ DONE",
  [One name a call; the adapter moves on by itself. The folder’s `/` is
   added only within the length asked for. At a length of exactly 31 the
   firmware puts icon bytes in front of the name. Stop at the end marker: an
   SD host goes on answering `..` past it.])

#cmd("SET_DIRECTORY_POSITION / GET_DIRECTORY_POSITION", code: "$E4 / $E5", dev: "$70", nparam: "1 / 0",
  params: [`$E4`: *one word*, the entry number],
  reply: [`$E5`: a word, the current entry number; `$E4`: ACK],
  asm: "        FNBEGIN FNDFUJI, FCSDPS, 1
        LODI,R2 8               ; entry 8: page two
        LODI,R3 0
        BSTA,UN FNPARW
        BSTA,UN FNGO
        BCFA,EQ FAIL",
  [Seek and tell for the open directory: paging in one command. The
   position is one two-byte parameter, not two one-byte ones.])

#cmd("CLOSE_DIRECTORY", code: "$F5", dev: "$70", nparam: "0",
  reply: [ACK],
  asm: "        FNBEGIN FNDFUJI, FCCDIR, 0
        BSTA,UN FNGO",
  [Close what you open: the adapter has room for few open directories.])

== Files, prefixes and paths

#cmd("COPY_FILE", code: "$D8", dev: "$70", nparam: "2",
  params: [bytes: source host, destination host, *counting from 1*],
  payload: [`source|destination`; at its own length, or NUL-padded],
  reply: [ACK when the copy is done; the cartridge allows sixty seconds],
  asm: "        FNBEGIN FNDFUJI, FCCOPY, 2
        LODI,R2 1               ; host 0, counted from 1
        BSTA,UN FNPARB
        LODI,R2 1
        BSTA,UN FNPARB
        SETFSTR SPEC            ; source|destination
        BSTA,UN FNTXSTR
        BSTA,UN FNGO
        BCFA,EQ FAIL",
  [Host to host, without a byte passing through the console. Its hosts
   count from 1, unlike every other slot number; 0 is refused. When the
   destination ends in `/`, the adapter adds the source’s file name.
   CONFIG’s copy screen sends it at its own length.])

#cmd("SET_HOST_PREFIX / GET_HOST_PREFIX", code: "$E1 / $E0", dev: "$70", nparam: "1",
  params: [byte: the host slot; SET carries the prefix as its payload],
  reply: [GET: the prefix],
  [A working directory for each host, put in front of relative paths.])

#cmd("GET_DEVICE_FULLPATH", code: "$DA", dev: "$70", nparam: "1",
  params: [byte: the device slot], reply: [the path SET_DEVICE_FULLPATH stored],
  [What a device slot holds, as one string.])

== App keys

#cmd("OPEN_APPKEY", code: "$DC", dev: "$70", nparam: "0",
  payload: [6 bytes: creator (word), app, key, mode (0 read, 1 write), and a reserved 0],
  reply: [ACK; NAK with no memory card, a creator of 0 or a bad mode],
  asm: "        FNBEGIN FNDFUJI, FCAKOP, 0
        SETFSTR KEYSEL          ; $50,$26,$FF,0,0,0:
        LODI,R2 6               ; creator $2650, app $FF,
        BSTA,UN FNTXN           ; key 0, read, reserved
        BSTA,UN FNGO
        BCFA,EQ FAIL",
  [Chooses the key the next read or write uses. The payload is one packed
   structure; leave off the reserved byte and the adapter waits for it until
   the transaction times out. On the memory card the key is the file
   `/FujiNet/CCCCAAKK.key`; it holds 64 bytes at most.])

#cmd("READ_APPKEY / WRITE_APPKEY / CLOSE_APPKEY", code: "$DD / $DE / $DB", dev: "$70", nparam: "0 / 1 / 0",
  params: [WRITE: byte, the length],
  payload: [WRITE: the value, at most 64 bytes],
  reply: [READ: a word, the length, then the value; the others: ACK],
  asm: "        FNBEGIN FNDFUJI, FCAKRD, 0
        BSTA,UN FNGO
        BCFA,EQ FAIL
        LODA,R0 *FRDP           ; the length
        BCTA,EQ DONE            ; empty
        STRA,R0 DRCNT
        LODI,R0 2               ; the value: from byte 2
        STRA,R0 DRPOS
        LODI,R2 $30-1
        BSTA,UN DREPLY",
  [A write ends the selection, so each write needs its own OPEN in write
   mode. Section 14 has both directions.])

== Utilities

#cmd("GENERATE_GUID", code: "$BB", dev: "$70", nparam: "0",
  reply: [36 characters and a NUL],
  asm: "        FNBEGIN FNDFUJI, FCGUID, 0
        BSTA,UN FNGO
        BCFA,EQ FAIL
        SETSTR  FNRDATA         ; rows 4 to 6: it wraps
        LODI,R2 $40-1
        BSTA,UN DPRINT",
  [A fresh, printable, unique id: 36 characters, more than two rows of the
   screen (`DPRINT` does not stop at the edge; the next row is the next 16
   cells). RANDOM_NUMBER (`$D3`) is not answered on this build; the adapter’s
   randomness reaches a program through a GUID or a hash.])

#cmd("HASH: INPUT, COMPUTE, LENGTH, OUTPUT", code: "$C8 / $C7 / $C6 / $C5", dev: "$70", nparam: "1",
  params: [INPUT: word, the byte count; COMPUTE: byte, the algorithm (0 MD5, 1 SHA-1, 3 SHA-256, 4 SHA-512); LENGTH and OUTPUT: byte, 1 for hex text, 0 for binary],
  payload: [INPUT: the bytes], reply: [LENGTH: the size; OUTPUT: the hash],
  asm: "        FNBEGIN FNDFUJI, FCHSHL, 1
        LODI,R2 1               ; as text
        BSTA,UN FNPARB
        BSTA,UN FNGO
        BCFA,EQ FAIL
        LODA,R0 *FRDP           ; 64 for SHA-256",
  [Four steps on the adapter: feed bytes with INPUT, as often as needed;
   COMPUTE; ask the LENGTH; read the OUTPUT. Section 14 has the whole
   sequence. HASH_COMPUTE_NO_CLEAR (`$C3`) keeps the input for another
   algorithm, and HASH_CLEAR (`$C2`) empties it.])

#cmd("BASE64: ENCODE and DECODE", code: "$D0–$CD / $CC–$C9", dev: "$70", nparam: "varies",
  params: [INPUT: word, the byte count; OUTPUT: word, how many bytes to read],
  payload: [INPUT: the bytes], reply: [LENGTH: 4 bytes, the size; OUTPUT: the result],
  [The same four steps as the hash. Encoding is INPUT `$D0`, COMPUTE `$CF`,
   LENGTH `$CE`, OUTPUT `$CD`; decoding is `$CC`, `$CB`, `$CA`, `$C9`.])

#cmd("QR CODE: INPUT, ENCODE, LENGTH, OUTPUT", code: "$BC / $BD / $BE / $BF", dev: "$70", nparam: "varies",
  params: [INPUT: word, the count; ENCODE: version (0 to choose), error correction (0--3), shorten; LENGTH: the output mode (0 bytes, 2 bitmap); OUTPUT: word, the count],
  payload: [INPUT: the text], reply: [LENGTH: 4 bytes, the size; OUTPUT: the modules],
  [The adapter draws a QR code’s matrix; a program only has to plot it. A
   version 1 code is 21 × 21 modules: in block graphics, 3 × 2 blocks a cell,
   seven cells by eleven rows -- most of the screen.])

== Answered with a NAK on this build

These are in `fujiCommandID.h` but fall through every table the RS-232
build dispatches, so they earn a NAK: ENABLE_UDPSTREAM (`$F0`), SET_BAUDRATE
(`$EB`), NEW_DISK (`$E7`), UNMOUNT_HOST (`$E6`), SET_HSIO_INDEX (`$E3`),
SET_SIO_EXTERNAL_CLOCK (`$DF`), ENABLE_DEVICE and DISABLE_DEVICE (`$D5`,
`$D4`), RANDOM_NUMBER (`$D3`), GET_TIME (`$D2`; use the clock device),
DEVICE_ENABLE_STATUS (`$D1`), GET_HEAP (`$C1`), QRCODE_CLEAR (`$BA`),
GET_DEVICE1..10_FULLPATH (`$A0-$A9`), UPDATE_FIRMWARE (`$90`) and
HSIO_INDEX (`$3F`). Most of them tune other computers’ buses.
