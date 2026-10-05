#import "../lib.typ": *

= The Fuji Device

#lead[Device \$70 is the FujiNet itself: its WiFi, its eight host slots and
eight device slots, its directories, its app keys, and a handful of jobs it
will do for a 1.79 MHz CPU that would rather not.]

== Hosts, devices and paths

The FujiNet keeps two tables that every FujiNet computer shares.

#runin(
  ("Eight host slots", [name places files come from: `SD` for the
   FujiNet's own SD card, or the name of a TNFS server such as `ec.tnfs.io`.
   READ_HOST_SLOTS returns all eight, 32 bytes each.]),
  ("Eight device slots", [each name a file on one of those hosts, and a mode
   -- 1 read, 2 write. On the NES the slot that matters is device slot 0: it is
   where a cartridge image is mounted to be booted (Chapter 8).]),
)

Before you can list a host's files you MOUNT_HOST it. Slot numbers on the
wire are 0 to 7 -- what CONFIG shows as host 1 is slot 0.

== Listing a directory

#wholefile("listings/c/dir.c", "listings/c/dir.c")

OPEN_DIRECTORY takes the path and an optional filter as one 256-byte block --
the path, a NUL, the filter, a NUL. READ_DIR_ENTRY then returns one name at a
time, padded to the length you ask for, with a `/` on the end of a
directory's name. The end of the directory is a name that begins with `$7F`.

#excerpt-at("listings/asm/dir.s: the loop", "listings/asm/dir.s",
  "entry:  CALL", to: "close:  CALL", size: 6.8pt)

#shots("dir-c", "dir-asm", caption: [The top of `ec.tnfs.io`, in C and in
assembly. The host's name comes straight from READ_HOST_SLOTS.])

#note[`fuji_open_directory()` sends 256 bytes starting at the pointer you
give it, so give it a 256-byte buffer. And pass an empty string, not NULL, as
the filter to `fuji_open_directory_filter()`: it looks at the filter's first
byte.]

== App keys

An app key is up to 64 bytes the FujiNet keeps for your program on its SD
card, under `/FujiNet/`, named by three numbers: a *creator* (two bytes; zero
is not allowed), an *app* and a *key* (one byte each). Pick a creator number
of your own -- the FujiNet games use `$E41C` and `$BEBE`; the Lobby uses
creator 1, app 1, with key 0 holding the player's name.

#wholefile("listings/c/appkey.c", "listings/c/appkey.c")

Underneath, a key is always opened first, with a six-byte record:

#bytefield(("creator lo", 50pt), ("creator hi", 50pt), ("app", 34pt),
  ("key", 34pt), ("mode", 34pt), ("0", 30pt))
#align(center, text(size: 7pt)[mode 0 to read, 1 to write])

then READ or WRITE. On this bus the READ reply starts with the key's length,
two bytes, low first. A key that was never written reads back with a length
of zero -- READ_APPKEY never NAKs.

#excerpt-at("listings/asm/appkey.s: open, then read", "listings/asm/appkey.s",
  "        lda     #0                      ; mode 0: read", to: "count:  inc", size: 6.8pt)

#shots("appkey-c", "appkey-asm", caption: [The C program and then the
assembly one, run one after the other: they share the same key.])

== WiFi

#cmd("Get WiFi status", dev: "$70", code: "$FA",
  reply: [1 byte: 3 connected, 6 not connected. Nothing else is ever sent.],
  asm: "        CALL    FNDEVF, FNCWIFI, 0
        jsr     fn_go
        jne     fail
        lda     FN_RPLY
        cmp     #3              ; connected?",
  c: "if (fuji_get_wifi_status(&status)
    && status == 3)
  cputs(\"ONLINE\");")[]

#cmd("Get WiFi enabled", dev: "$70", code: "$EA",
  reply: [1 byte: 1 enabled, 0 disabled.],
  asm: "        CALL    FNDEVF, FNCWIFEN, 0
        jsr     fn_go",
  c: "if (!fuji_get_wifi_enabled())
  cputs(\"WIFI IS OFF\");")[]

#cmd("Get SSID", dev: "$70", code: "$FE",
  reply: [97 bytes: the network name (33), then its password (64), in the
    clear.],
  asm: "        CALL    FNDEVF, FNCGSSID, 0
        jsr     fn_go           ; name at FN_RPLY",
  c: "fuji_get_ssid(&nc);
cputs(nc.ssid);")[]

#cmd("Scan networks", dev: "$70", code: "$FD",
  reply: [1 byte: how many networks were found.],
  asm: "        CALL    FNDEVF, FNCSCAN, 0
        jsr     fn_go
        jne     fail
        lda     FN_RPLY         ; count",
  c: "fuji_scan_for_networks(&count);")[
Takes several seconds -- the FujiNet scans before it answers.]

#cmd("Get scan result", dev: "$70", code: "$FC",
  params: [index (1), from 0.],
  reply: [34 bytes: the name (33), then the signal strength as a signed byte,
    in dBm. NAK for an index past the last scan's count.],
  asm: "        CALL    FNDEVF, FNCSCNR, 1
        lda     #0              ; the first
        jsr     fn_pb
        jsr     fn_go
        jne     fail
        lda     FN_RPLY+33      ; rssi, negative",
  c: "fuji_get_scan_result(0, &info);
cprintf(\"%s %d\", info.ssid, info.rssi);")[]

#cmd("Set SSID", dev: "$70", code: "$FB",
  payload: [97 bytes: the name, NUL-padded to 33, then the password,
    NUL-padded to 64.],
  reply: [none, once the FujiNet has joined. NAK if it could not.],
  asm: "        CALL    FNDEVF, FNCSSSID, 0
        ldx     #0
:       lda     ssidpw,x        ; 97 bytes, padded
        jsr     fn_txb
        inx
        cpx     #97
        bne     :-
        jsr     fn_go",
  c: "memset(&nc, 0, sizeof nc);
strcpy(nc.ssid, \"MyNetwork\");
strcpy(nc.password, \"secret\");
fuji_set_ssid(&nc);")[
#hilite("Caution"): send all 97 bytes. The FujiNet copies what you send over
a buffer it did not clear, so a short payload leaves garbage in the
password. The FujiNet saves the network to its configuration.]

== Hosts and device slots

#cmd("Read host slots", dev: "$70", code: "$F4",
  reply: [256 bytes: eight host names of 32 bytes.],
  asm: "        CALL    FNDEVF, FNCRHST, 0
        jsr     fn_go           ; slot n at FN_RPLY + n*32",
  c: "fuji_get_host_slots(hosts, 8);")[]

#cmd("Write host slots", dev: "$70", code: "$F3",
  payload: [256 bytes: all eight names.],
  reply: [none; the FujiNet saves its configuration.],
  asm: "        CALL    FNDEVF, FNCRHST, 0
        jsr     fn_go           ; read them first
        CALL    FNDEVF, FNCWHST, 0
        ldx     #0              ; and stream them back
:       lda     FN_RPLY,x
        jsr     fn_txb
        inx
        bne     :-",
  c: "strcpy((char *) hosts[3], \"ec.tnfs.io\");
fuji_put_host_slots(hosts, 8);")[
Send all eight. To change one, read the table, change your copy, and write it
all back -- or, as CONFIG does, stream seven of them straight out of the reply
window and the changed one from RAM.]

#cmd("Mount host", dev: "$70", code: "$F9",
  params: [host slot (1), 0-7.],
  reply: [none; NAK if the slot is empty or the host cannot be reached.],
  asm: "        CALL    FNDEVF, FNCMHST, 1
        lda     #0              ; host 1, the SD card
        jsr     fn_pb
        jsr     fn_go
        jne     fail
        jsr     fn_ack
        jne     fail",
  c: "if (!fuji_mount_host_slot(0))
  fail();")[]

#cmd("Unmount host", dev: "$70", code: "$E6",
  params: [host slot (1).],
  reply: [none; NAK if that host was not mounted.],
  asm: "        CALL    FNDEVF, FNCUHST, 1
        lda     #7
        jsr     fn_pb
        jsr     fn_go",
  c: "fuji_unmount_host_slot(7);")[
Also unmounts every device slot using that host.]

#cmd("Set / get host prefix", dev: "$70", code: "$E1 / $E0",
  params: [host slot (1).],
  payload: [SET: the prefix, NUL-terminated, up to 256 bytes.],
  reply: [GET: 256 bytes, the prefix.],
  asm: "        CALL    FNDEVF, FNCGPFX, 1
        lda     #0
        jsr     fn_pb
        jsr     fn_go",
  c: "fuji_get_host_prefix(0, path);")[
A prefix is a directory that paths on that host are taken relative to.]

#cmd("Read device slots", dev: "$70", code: "$F2",
  reply: [304 bytes: eight slots of 38 -- host slot (1, `$FF` empty), mode
    (1: 1 read, 2 write, plus `$40` when mounted), file name (36).],
  asm: "        CALL    FNDEVF, FNCRDEV, 0
        jsr     fn_go           ; slot n at FN_RPLY + n*38",
  c: "fuji_get_device_slots(slots, 8);")[]

#cmd("Write device slots", dev: "$70", code: "$F1",
  payload: [304 bytes: all eight slots.],
  asm: "        CALL    FNDEVF, FNCRDEV, 0
        jsr     fn_go           ; then stream 304 back
        CALL    FNDEVF, FNCWDEV, 0",
  c: "slots[1].hostSlot = 0xFF;   /* empty it */
fuji_put_device_slots(slots, 8);")[
304 bytes is under the 320 the TX stream holds, so it goes in one
transaction.]

#cmd("Set device full path", dev: "$70", code: "$E2",
  params: [device slot (1), host slot (1), mode (1).],
  payload: [The path, NUL-terminated, up to 256 bytes.],
  reply: [none; NAK for a bad slot. An empty path empties the slot.],
  asm: "        CALL    FNDEVF, FNCSDFP, 3
        lda     #0              ; device slot
        jsr     fn_pb
        lda     #0              ; host slot
        jsr     fn_pb
        lda     #1              ; read
        jsr     fn_pb
        lda     #<path
        sta     fn_ptr
        lda     #>path
        sta     fn_ptr+1
        jsr     fn_path
        jsr     fn_go",
  c: "strcpy(path, \"/nesbook/hello.bin\");
/* note the order: mode, host, device */
fuji_set_device_filename(1, 0, 0, path);")[
fujinet-lib's `fuji_set_device_filename(mode, host, device, path)` takes its
arguments in the opposite order to the wire, and always sends 256 bytes from
`path` -- so `path` must be a 256-byte buffer.]

#cmd("Get device full path", dev: "$70", code: "$DA",
  params: [device slot (1).],
  reply: [256 bytes: the path.],
  asm: "        CALL    FNDEVF, FNCGDFP, 1
        lda     #0
        jsr     fn_pb
        jsr     fn_go",
  c: "fuji_get_device_filename(0, path);")[]

#cmd("Unmount image", dev: "$70", code: "$E9",
  params: [device slot (1).],
  asm: "        CALL    FNDEVF, FNCUIMG, 1
        lda     #0
        jsr     fn_pb
        jsr     fn_go",
  c: "fuji_unmount_disk_image(0);")[]

#cmd("Mount all", dev: "$70", code: "$D7",
  reply: [none; NAK if any slot fails. A cartridge image in a slot is pushed
    to the cartridge, as MOUNT_IMAGE would.],
  asm: "        CALL    FNDEVF, FNCMALL, 0
        jsr     fn_go",
  c: "fuji_mount_all();")[]

MOUNT_IMAGE, `$F8`, which loads a cartridge image, has Chapter 8 to itself.

#cmd("New disk", dev: "$70", code: "$E7",
  payload: [262 bytes: sector count (2), sector size (2), host slot (1),
    device slot (1), file name (256).],
  reply: [none; NAK if the file exists or cannot be written.],
  asm: "        CALL    FNDEVF, FNCNEWD, 0
        lda     #<720           ; sectors
        jsr     fn_txb
        lda     #>720
        jsr     fn_txb
        ; then size, host, slot, 256-byte name",
  c: "/* no NES wrapper: NewDisk is not defined */
fuji_bus_call(FUJI_DEVICEID_FUJINET, 0xE7,
              FUJI_FIELD_DATA, 0, 0, 0, 0,
              buf, 262);")[
Creates a blank disk image. Of little use to a NES program, but there.]

#cmd("Copy file", dev: "$70", code: "$D8",
  params: [source host (1), destination host (1) -- counted from *1*.],
  payload: [`source|destination`. A destination ending in `/` gets the
    source's file name -- only if nothing follows the string.],
  reply: [none, once the copy is done. The cartridge allows it 60 seconds.],
  asm: "        CALL    FNDEVF, FNCCOPY, 2
        lda     #8              ; from host 8
        jsr     fn_pb
        lda     #1              ; to host 1
        jsr     fn_pb
        lda     #<data
        sta     fn_ptr
        lda     #>data
        sta     fn_ptr+1
        jsr     fn_str          ; exact length
        jsr     fn_go",
  c: "/* sends 256 bytes: give a full name */
fuji_copy_file(8, 1, (char *)
  \"/nes/x.nes|/nesbook/x.nes\");")[]

#cmd("Config boot", dev: "$70", code: "$D9",
  params: [enable (1).],
  asm: "        CALL    FNDEVF, FNCCBOOT, 1
        lda     #0
        jsr     fn_pb
        jsr     fn_go",
  c: "fuji_set_boot_config(0);")[
Whether the FujiNet serves CONFIG at boot. A successful MOUNT_IMAGE already
turns it off.]

#cmd("Set boot mode", dev: "$70", code: "$D6",
  params: [mode (1).],
  asm: "        CALL    FNDEVF, FNCBMODE, 1
        lda     #0
        jsr     fn_pb
        jsr     fn_go",
  c: "fuji_set_boot_mode(0);")[
Mounts one of the FujiNet's boot disks into device slot 0. Meant for disk
computers; meaningless on the NES.]

== Directories

#cmd("Open directory", dev: "$70", code: "$F7",
  params: [host slot (1).],
  payload: [Up to 256 bytes: the path, a NUL, and an optional filter such as
    `*.nes`, then a NUL.],
  reply: [none; NAK if the host is not mounted or the path does not exist.],
  asm: "        CALL    FNDEVF, FNCODIR, 1
        lda     #0
        jsr     fn_pb
        lda     #<path
        sta     fn_ptr
        lda     #>path
        sta     fn_ptr+1
        jsr     fn_path         ; 256, no filter
        jsr     fn_go",
  c: "memset(path, 0, sizeof path);
path[0] = '/';
fuji_open_directory(0, path);")[
Opening a directory closes any other.]

#cmd("Read directory entry", dev: "$70", code: "$F6",
  params: [length (1), flags (1).],
  reply: [Exactly *length* bytes: the name, NUL-padded, shortened with an
    ellipsis if it does not fit; a directory ends in `/`. `$7F $7F` is the
    end. NAK if no directory is open.],
  asm: "        CALL    FNDEVF, FNCRDIR, 2
        lda     #28             ; length
        jsr     fn_pb
        lda     #0              ; flags
        jsr     fn_pb
        jsr     fn_go
        lda     FN_RPLY
        cmp     #$7F            ; the end?",
  c: "if (fuji_read_directory(28, 0, buf)
    && buf[0] != 0x7F)
  cputs((char *) buf);")[
With flags bit 7 set, twelve bytes come first: year minus 1970, month, day,
hour, minute, second; the size (4 bytes); flags (bit 0 directory, bit 1 name
cut short); and a media type -- 0 unknown, 1 disk image, 2 cartridge image
(`.nes`, `.bin`, `.rom` and the like), 3 IMD.]

#cmd("Close directory", dev: "$70", code: "$F5",
  asm: "        CALL    FNDEVF, FNCCDIR, 0
        jsr     fn_go",
  c: "fuji_close_directory();")[]

#cmd("Get / set directory position", dev: "$70", code: "$E5 / $E4",
  params: [SET: position (2).],
  reply: [GET: 2 bytes, the position.],
  asm: "        CALL    FNDEVF, FNCSDPS, 1
        lda     #<16            ; entry 16
        ldx     #>16
        jsr     fn_pw
        jsr     fn_go",
  c: "fuji_set_directory_position(16);
fuji_get_directory_position(&pos);")[
How CONFIG pages: SET the position of the page's first entry, then sixteen
READs.]

== App key commands

#cmd("Open app key", dev: "$70", code: "$DC",
  payload: [6 bytes: creator (2), app (1), key (1), mode (1: 0 read, 1
    write), reserved (1).],
  reply: [none; NAK if creator is 0 or there is no SD card.],
  asm: "        CALL    FNDEVF, FNCOKEY, 0
        lda     #$5E            ; creator, low
        jsr     fn_txb
        lda     #$5E            ;   and high
        jsr     fn_txb
        lda     #1              ; app
        jsr     fn_txb
        lda     #0              ; key
        jsr     fn_txb
        lda     #0              ; mode: read
        jsr     fn_txb
        jsr     fn_txb          ; reserved
        jsr     fn_go",
  c: "/* fujinet-lib opens for you */
fuji_set_appkey_details(0x5E5E, 1, DEFAULT);")[
All six bytes, always: the FujiNet does not clear the record first.]

#cmd("Read app key", dev: "$70", code: "$DD",
  reply: [2 bytes of length, low first, then that many bytes, 0 to 64.],
  asm: "        CALL    FNDEVF, FNCRKEY, 0
        jsr     fn_go
        jne     fail
        lda     FN_RPLY         ; length, low
        ; the key from FN_RPLY+2",
  c: "if (fuji_read_appkey(0, &len, buf))
  buf[len] = 0;")[]

#cmd("Write app key", dev: "$70", code: "$DE",
  payload: [The key's new value, up to 64 bytes.],
  reply: [none; NAK unless it was opened for writing.],
  asm: "        CALL    FNDEVF, FNCWKEY, 0
        lda     #42
        jsr     fn_txb
        jsr     fn_go",
  c: "fuji_write_appkey(0, 5,
                  (uint8_t *) \"HELLO\");")[
A write, good or bad, ends the open: open again before the next one.]

#cmd("Close app key", dev: "$70", code: "$DB",
  asm: "        CALL    FNDEVF, FNCCKEY, 0
        jsr     fn_go",
  c: "/* no wrapper */
fuji_bus_call(FUJI_DEVICEID_FUJINET, 0xDB,
              FUJI_FIELD_NONE, 0, 0, 0, 0,
              NULL, 0);")[]

== The adapter

#cmd("Get adapter config", dev: "$70", code: "$E8 / $C4",
  reply: [`$E8`: 140 bytes. `$C4`, the extended form: 240 bytes, the same
    140 followed by the addresses as text. Laid out in Chapter 5.],
  asm: "        CALL    FNDEVF, FNCADPX, 0
        jsr     fn_go",
  c: "fuji_get_adapter_config(&ac);
fuji_get_adapter_config_extended(&acx);")[]

#cmd("Status", dev: "$70", code: "$53",
  reply: [4 bytes, always zero.],
  asm: "        CALL    FNDEVF, FNCSTAT, 0
        jsr     fn_go",
  c: "fuji_status((FNStatus *) buf);")[]

#cmd("Device ready", dev: "$70", code: "$00",
  reply: [512 bytes of `'A'`.],
  asm: "        CALL    FNDEVF, FNCREADY, 0
        jsr     fn_go           ; FN_RXLO/HI = 512",
  c: "fuji_bus_call(FUJI_DEVICEID_FUJINET, 0x00,
              FUJI_FIELD_REPLY, 0, 0, 0, 0,
              buf, 512);")[
A round-trip test of the link: a big, known reply.]

#cmd("Reset", dev: "$70", code: "$FF",
  reply: [none -- the FujiNet restarts without answering, so the
    transaction times out and the library reports failure.],
  asm: "        CALL    FNDEVF, FNCRESET, 0
        jsr     fn_go           ; returns ERR 2, timeout",
  c: "fuji_reset();   /* returns false */")[]

== Jobs for the coprocessor

#cmd("Random number", dev: "$70", code: "$D3",
  reply: [4 bytes, a random 32-bit number, low first.],
  asm: "        CALL    FNDEVF, FNCRAND, 0
        jsr     fn_go
        lda     FN_RPLY         ; four random bytes",
  c: "/* no wrapper */
fuji_bus_call(FUJI_DEVICEID_FUJINET, 0xD3,
              FUJI_FIELD_REPLY, 0, 0, 0, 0,
              &r32, 4);")[]

#cmd("Generate GUID", dev: "$70", code: "$BB",
  reply: [37 bytes: a version 4 UUID as text, lower-case, with its NUL.],
  asm: "        CALL    FNDEVF, FNCGUID, 0
        jsr     fn_go",
  c: "fuji_generate_guid(guid);")[]

#cmd("Base64", dev: "$70", code: "$D0-$C9",
  params: [INPUT and OUTPUT: length (2).],
  payload: [INPUT: the bytes.],
  reply: [LENGTH: 4 bytes. OUTPUT: the bytes, taken from the front.],
  asm: "        CALL    FNDEVF, FNCB64EI, 1
        lda     #5
        ldx     #0
        jsr     fn_pw
        ldx     #0
:       lda     data,x
        jsr     fn_txb
        inx
        cpx     #5
        bne     :-
        jsr     fn_go
        CALL    FNDEVF, FNCB64EC, 0
        jsr     fn_go",
  c: "fuji_base64_encode_input(\"HELLO\", 5);
fuji_base64_encode_compute();
fuji_base64_encode_length(&blen);
fuji_base64_encode_output(buf, 8);")[
Encoding is `$D0` input, `$CF` compute, `$CE` length, `$CD` output; decoding
is `$CC`, `$CB`, `$CA`, `$C9`. Both use one buffer on the FujiNet: INPUT adds
to it, COMPUTE replaces it with the result, OUTPUT takes from the front.]

#cmd("Hash", dev: "$70", code: "$C8-$C2",
  params: [INPUT: length (2). COMPUTE: algorithm (1): 0 MD5, 1 SHA-1,
    2 SHA-256, 3 SHA-512, 4 SHA-224, 5 SHA-384. LENGTH and OUTPUT: 1 for hex,
    0 for binary.],
  reply: [LENGTH: 1 byte. OUTPUT: the digest.],
  asm: "        CALL    FNDEVF, FNCHCMP, 1
        lda     #2              ; SHA-256
        jsr     fn_pb
        jsr     fn_go
        CALL    FNDEVF, FNCHOUT, 1
        lda     #1              ; as hex
        jsr     fn_pb
        jsr     fn_go",
  c: "fuji_hash_data(SHA256, (uint8_t *) \"HELLO\",
               5, true, buf);")[
`$C8` input, `$C7` compute (and forget the input), `$C3` compute and keep it,
`$C6` length, `$C5` output, `$C2` clear. fujinet-lib names only the first four
algorithms.]

#cmd("QR code", dev: "$70", code: "$BC-$BF",
  params: [INPUT and OUTPUT: length (2). ENCODE: version (1, 0 for the
    smallest), error correction (1: 0-3), shorten the URL (1). LENGTH: format
    (1): 0 binary, 1 ANSI, 2 bitmap, 3 SVG, 4 ATASCII, 5 PETSCII.],
  reply: [LENGTH: 4 bytes. OUTPUT: the code, from the front.],
  asm: "        CALL    FNDEVF, FNCQENC, 3
        lda     #0              ; version: auto
        jsr     fn_pb
        lda     #1              ; ecc: medium
        jsr     fn_pb
        lda     #0              ; don't shorten
        jsr     fn_pb
        jsr     fn_go",
  c: "n16 = qrcode_create(0, QR_ECC_MEDIUM, false,
        QR_OUTPUT_MODE_BINARY, \"FUJINET\", 7,
        buf, sizeof buf);")[
`$BC` input, `$BD` encode, `$BE` length, `$BF` output; in C, include
`fujinet-qrcode.h`. In binary format each
module is one byte, row by row. An OUTPUT is limited by the 1K reply window.]

The Fuji device NAKs `$F0`, `$EB`, `$E3`, `$DF`, `$D5`, `$D4`, `$D2`
(GET_TIME -- use the clock device), `$D1`, `$C1`, `$A0-$A9`, `$90` and `$3F`.
