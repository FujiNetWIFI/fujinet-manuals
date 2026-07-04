# Programming the FujiNet for the Coleco ADAM

*A programmer's guide and command reference for talking to a FujiNet from Z80 assembly language over AdamNet — through the Elementary Operating System (EOS), and by driving the Device Control Blocks (DCBs) directly, as one must under CP/M.*

This is the developer companion to *[Getting Started with FujiNet CONFIG for the Coleco ADAM](FujiNet-CONFIG-Set-Up-Guide-for-the-Coleco-ADAM)*. That guide taught your fingers; this one teaches your assembler. By the last section you will have written a working *netcat* — open a socket, read it, write it — in a couple of pages of Z80.

> **Source-verified.** Every command byte, DCB layout, EOS entry point and error number here was read out of the FujiNet sources, not remembered: `fujinet-firmware` (`lib/bus/adamnet/`, `lib/device/adamnet/adamFuji.cpp`, `network.cpp`, `include/fujiCommandID.h`), the EOS C binding (`eos.h`), the `fujinet-lib` ADAM target, and the FujiNet ADAM CP/M library (`fujinet-adam-cpm-lib`).

---

## Contents

1. [The Shape of the Thing](#the-shape-of-the-thing)
2. [The AdamNet Connection](#the-adamnet-connection)
3. [Shaping a Transaction](#shaping-a-transaction)
4. [The Network Device (N:)](#the-network-device-n)
5. [The Fuji Control Device](#the-fuji-control-device)
6. [Telling Time](#telling-time)
7. [Error Codes](#error-codes)
8. [Command Quick Reference](#command-quick-reference)
9. [netcat in Z80](#netcat-in-z80)

---

## The Shape of the Thing

A FujiNet is, electrically, a small computer of its own — an ESP32 with Wi-Fi, a memory-card slot, and a wire that pretends to be a peripheral. To your ADAM, the FujiNet is not a network card and not a co-processor. It is a cluster of **AdamNet devices**: the same intelligent peripheral bus your keyboard, disk drives, and printer already hang from. Everything in this guide is, underneath, an AdamNet transaction.

You do not install a driver. You do not patch EOS. You ask AdamNet which devices are attached, and you find — alongside the keyboard, the tape drives, and the printer — a handful of devices that were never made of metal:

* **The FujiNet control device** (AdamNet id `$0F`) — mounts disk images, browses hosts, scans Wi-Fi, reads the clock, hashes data, and keeps the slots CONFIG shows you.
* **The Network devices** (ids `$09` and `$0A`) — the `N:` device. TCP, UDP, HTTP, TNFS, FTP, SMB, SSH and TELNET.
* **The FujiNet's disk drives** (ids `$04`–`$07`) and **printer** (id `$02`) — ordinary AdamNet block and character devices, mounted from images.

### Two ways in

There are two heights at which you can reach a device, and this guide teaches both, side by side.

* **The EOS road** is the one Coleco intended. EOS — resident in ROM, at the top of memory — publishes a jump table of device routines. You load a register or two and `CALL` a fixed address. Right for an EOS program, a SmartBASIC extension, or a cartridge.
* **The CP/M road** is the one you take when EOS is not there. A CP/M program has no jump table — but the Peripheral Control Block (PCB) and its DCBs still sit at `$FEC0`, and the master 6801 is still listening. You find the DCB yourself, poke it, and spin on its status byte.

Every command below is shown both ways: the EOS `CALL`, and the direct DCB poke. Learn the two primitives once and the rest is just payloads.

---

## The AdamNet Connection

### What AdamNet is

AdamNet is a daisy chain of intelligent devices on one three-wire cable: ground and a single bidirectional data line at **62,500 baud**, plus a reset line. Every device has an **address**, `0`–`15`, and answers only when spoken to.

| Id | Device |
|---|---|
| `$01` | keyboard |
| `$02` | printer |
| `$04`–`$07` | disk drives 1–4 |
| `$08` | tape (data pack) drive |
| `$09`–`$0A` | FujiNet Network devices (`N1:`, `N2:`) |
| `$0F` | FujiNet control device |

### The master, the Z80, and shared memory

Your Z80 is the ADAM's main processor, but it does **not** bit-bang AdamNet. A dedicated **master 6801** microcontroller owns the wire. The two processors meet in the Z80's RAM:

* A **Peripheral Control Block (PCB)** — a short header the master polls.
* A **Device Control Block (DCB)** for each device — 21 bytes describing one pending transaction.

You write into a DCB — buffer, length, and a command — and poke a byte. The master, forever polling the PCB, carries out the AdamNet transaction and writes a completion code back into that same status byte. **Programming AdamNet is programming the DCB.**

**PCB layout**

| Off | Bytes | Field |
|---|---|---|
| 0 | 1 | status / command |
| 1 | 2 | base address |
| 3 | 1 | number of active devices (DCBs) |

**DCB layout (21 bytes)**

| Off | Bytes | Field |
|---|---|---|
| 0 | 1 | status — you poke a request; master writes result |
| 1 | 2 | buffer pointer (low/high) |
| 3 | 2 | length (low/high) |
| 5 | 4 | block number (block devices only) |
| 9 | 1 | device number |
| 10 | 6 | reserved for the master |
| 16 | 1 | device id — **low nibble is the AdamNet address** |
| 18 | 2 | maximum length |
| 20 | 1 | device type / status |

> **The byte you care about most** is the DCB status at offset 0. You write a small number to request work (`3` = write, `4` = read); the master writes back a code with its high bit set — `$80` and up — when done. That single byte is the whole handshake.

### Finding the PCB — and the FujiNet's DCB (CP/M road)

Under EOS, `FIND_DCB` does this for you. Under CP/M there is no EOS, so you find it by hand. The PCB lives at `$FEC0`; the DCBs follow it, 21 bytes apiece, from `$FEC4`:

| Address | Holds |
|---|---|
| `$FEC0` | PCB status byte |
| `$FEC3` | count of DCBs |
| `$FEC4` | first DCB (then every 21 bytes) |

Walk the DCBs and match the low nibble of the device-id byte (offset 16) against `$0F`:

```z80
DCBBAS  equ  $FEC4         ; first DCB (PCB is $FEC0..$FEC3)
NDCBS   equ  $FEC3         ; count of DCBs, from the PCB
DCBSZ   equ  21            ; bytes per DCB
DEVFUJI equ  $0F           ; FujiNet control device address
;
; FINDDCB - locate the FujiNet control DCB.
;   exit: HL -> DCB, carry CLEAR if found; carry SET if not found.
FINDDCB ld   hl,DCBBAS
        ld   a,(NDCBS)
        or   a
        jr   z,FD_NONE
        ld   b,a           ; B = how many DCBs to scan
FD_LP   ld   de,16
        add  hl,de         ; HL -> device-id byte (offset 16)
        ld   a,(hl)
        and  $0F           ; low nibble = AdamNet address
        push af
        ld   de,-16
        add  hl,de         ; HL -> back to top of this DCB
        pop  af
        cp   DEVFUJI
        jr   z,FD_OK
        ld   de,DCBSZ
        add  hl,de         ; next DCB
        djnz FD_LP
FD_NONE scf
        ret
FD_OK   or   a             ; carry CLEAR = found
        ret
```

The network devices are found the same way — match `$09` for `N1:`, `$0A` for `N2:`.

---

## Shaping a Transaction

Every FujiNet command is the same two-beat rhythm: **write** a request to the device (a command byte and its arguments), then **read** the device's reply. The first byte you write is the command code; anything after it is arguments. You do **not** prefix a length — the length lives in the DCB (or the register you hand EOS), and the master 6801 adds the AdamNet length header on the wire for you.

| Beat | AdamNet | EOS call | DCB status you poke |
|---|---|---|---|
| write | SEND | `WR_CH_DEV` | `3` |
| read | RECEIVE | `RD_CH_DEV` | `4` |

### The EOS road

EOS keeps a jump table at the top of memory. The entries this guide uses:

| Addr | EOS routine | In / Out |
|---|---|---|
| `$FC54` | `FIND_DCB` | `A`=dev → `IY`=DCB, `Z`=ok |
| `$FC5A` | `FIND_PCB` | → `IY`=PCB |
| `$FC7E` | `REQUEST_DEV_STATUS` | `A`=dev → `IY`=DCB |
| `$FCA5` | `START_RD_CH_DEV` | `A`=dev, `DE`=buf, `BC`=len |
| `$FC48` | `END_RD_CH_DEV` | `A`=dev → `A`=status |
| `$FCAE` | `START_WR_CH_DEV` | `A`=dev, `HL`=buf, `BC`=len |
| `$FC51` | `END_WR_CH_DEV` | `A`=dev → `A`=status |

A write is a *start* followed by polling *end* until the master reports done. A value below `$80` means "still working"; `$9B` means the transaction timed out and should be retried.

```z80
STWRCH  equ  $FCAE         ; START_WR_CH_DEV : A=dev, HL=buf, BC=len
ENWRCH  equ  $FC51         ; END_WR_CH_DEV   : A=dev -> A=status
STRDCH  equ  $FCA5         ; START_RD_CH_DEV : A=dev, DE=buf, BC=len
ENRDCH  equ  $FC48         ; END_RD_CH_DEV   : A=dev -> A=status
;
FNDEV   db   $0F           ; the device we're talking to
FNBUF   dw   0             ; buffer pointer
FNLEN   dw   0             ; length
;
; FNWR - send (FNLEN) bytes at (FNBUF) to device (FNDEV).  A = result.
FNWR    ld   a,(FNDEV)
        ld   hl,(FNBUF)
        ld   bc,(FNLEN)
        call STWRCH
FNWRP   ld   a,(FNDEV)
        call ENWRCH
        cp   $80
        jr   c,FNWRP       ; < $80 : master still busy
        cp   $9B
        jr   z,FNWR        ; $9B timeout : re-issue
        ret
;
; FNRD - read up to (FNLEN) bytes into (FNBUF).  DCB length = bytes delivered.
FNRD    ld   a,(FNDEV)
        ld   de,(FNBUF)
        ld   bc,(FNLEN)
        call STRDCH
FNRDP   ld   a,(FNDEV)
        call ENRDCH
        cp   $80
        jr   c,FNRDP
        cp   $9B
        jr   z,FNRD
        ret
```

### The CP/M road

With no EOS jump table, do exactly what EOS would: find the DCB, write the buffer pointer and length into it, poke the status byte with `3` (write) or `4` (read), and spin until the master raises it to `$80`+.

```z80
; DCBWR - HL -> DCB, DE -> buffer, BC = length.  A = result.
DCBWR   push hl
        inc  hl
        ld   (hl),e        ; DCB+1 : buffer low
        inc  hl
        ld   (hl),d        ; DCB+2 : buffer high
        inc  hl
        ld   (hl),c        ; DCB+3 : length low
        inc  hl
        ld   (hl),b        ; DCB+4 : length high
        pop  hl
        ld   (hl),3        ; DCB+0 : status = 3 (write)
DCBWRP  ld   a,(hl)
        cp   $80
        jr   c,DCBWRP
        cp   $9B
        jr   z,DCBWR
        ret
;
; DCBRD - HL -> DCB, DE -> buffer, BC = max length.  A = result.
DCBRD   push hl
        inc  hl
        ld   (hl),e
        inc  hl
        ld   (hl),d
        inc  hl
        ld   (hl),c
        inc  hl
        ld   (hl),b
        pop  hl
        ld   (hl),4        ; status = 4 (read)
DCBRDP  ld   a,(hl)
        cp   $80
        jr   c,DCBRDP
        cp   $9B
        jr   z,DCBRD
        ret
```

> **The two roads are interchangeable.** Every command below is issued with `FNWR`/`FNRD`; to run the same example under CP/M, find the DCB once with `FINDDCB` and swap in `DCBWR`/`DCBRD`. The payloads are identical — only the plumbing differs.

### Reading the result

Both roads leave an AdamNet result code in `A`. Anything `$80` or higher means the transaction completed; `$80` is plain success.

| Code | Name | Means |
|---|---|---|
| `$80` | `ADAMNET_OK` | success |
| `$88` | `SEND_DATA_NACK` | device refused the data |
| `$9B` | `TIMEOUT` | no response — retry the transaction |

The **device's own** answer is separate — it comes back in the bytes you read.

---

## The Network Device (N:)

The Network device — id `$09` for `N1:`, `$0A` for `N2:` — opens TCP and UDP sockets, fetches URLs over HTTP/HTTPS, mounts remote filesystems over TNFS/FTP/SMB, and tunnels TELNET and SSH. The protocol is chosen by a **device spec** string; the verbs are command bytes that happen to be ASCII letters.

### The device spec

```
N[x]:PROTO://host[:port]/path
```

`x` is the channel (`1` or `2` on the ADAM), `PROTO` is a scheme, the rest is the resource. Schemes: `TCP`, `UDP`, `HTTP`, `HTTPS`, `TNFS`, `FTP`, `SMB`, `SSH`, `TELNET` (upper-case). On the ADAM the channel digit chooses the **device**: `N1:` = `$09`, `N2:` = `$0A`. Point `FNDEV` at the matching id before you operate on a channel.

### OPEN — `SEND 'O'` (`$4F`)

Instantiates the protocol and connects. Payload: command byte, access **mode**, translation **mode**, then the NUL-terminated spec.

| Offset | Bytes | Value |
|---|---|---|
| 0 | 1 | `$4F` (`'O'`) |
| 1 | 1 | access mode |
| 2 | 1 | translation mode |
| 3… | N+1 | device spec string, NUL-terminated |

| Mode | Access | | Trans | Line endings |
|---|---|---|---|---|
| `$04` | read | | `$00` | none (binary) |
| `$08` | write | | `$01` | CR |
| `$0C` | read/write | | `$02` | LF |
| `$0D` | HTTP POST | | `$03` | CR/LF |
| `$05` | HTTP DELETE | | | |

**Returns:** `$80` from the master; check the device's own error with a `STATUS`. *fujinet-lib:* `network_open()`.

```z80
; NETOPEN - open the spec at (SPEC) on N1: for read/write.
;   buffer = [ 'O', mode, trans, spec..., 0 ]
NETOPEN ld   a,$09
        ld   (FNDEV),a
        ld   hl,OPBUF
        ld   (FNBUF),hl
        ld   a,'O'
        ld   (OPBUF),a
        ld   a,$0C
        ld   (OPBUF+1),a       ; mode = read/write
        xor  a
        ld   (OPBUF+2),a       ; trans = none
        ld   hl,SPEC
        ld   de,OPBUF+3
        ld   bc,3
CPSPEC  ld   a,(hl)
        ld   (de),a
        inc  hl
        inc  de
        inc  bc
        or   a
        jr   nz,CPSPEC
        ld   (FNLEN),bc
        jp   FNWR
SPEC    db   "N1:TCP://192.168.1.5:9000/",0
OPBUF   ds   300
```

### CLOSE — `SEND 'C'` (`$43`)

A one-byte payload — just the command. *fujinet-lib:* `network_close()`.

### STATUS — `SEND 'S'` (`$53`)

Write the one-byte command `'S'`, then **read** four bytes back:

| Offset | Bytes | Returned value |
|---|---|---|
| 0–1 | 2 | bytes waiting to be read (low/high) |
| 2 | 1 | connected: 1 = open, 0 = far end closed |
| 3 | 1 | device error (1 = OK, **136 = EOF**) |

*fujinet-lib:* `network_status()`.

### READ — the RECEIVE beat

A read takes no command byte — it *is* the receive. Poll `STATUS` first; never request more than the device buffer (1024 bytes). The bytes land in your buffer and the DCB length tells you how many came. *fujinet-lib:* `network_read()`.

### WRITE — `SEND 'W'` (`$57`)

Payload is `'W'` followed by the data. *fujinet-lib:* `network_write()`.

### A complete exchange: HTTP GET

```z80
GET     call NETOPEN         ; SPEC = "N1:HTTP://...", mode = read
        ret  c
GLOOP   call NETSTAT
        ld   a,(NERR)
        cp   136             ; EOF ?
        jr   z,GDONE
        ld   hl,(BW)
        ld   a,h
        or   l
        jr   z,GLOOP         ; nothing waiting yet
        ; clamp BW to 1024 if larger (omitted)
        call NETREAD
        ld   hl,RXBUF
        ld   bc,(BW)
EMIT    ld   a,(hl)
        call COUT
        inc  hl
        dec  bc
        ld   a,b
        or   c
        jr   nz,EMIT
        jr   GLOOP
GDONE   jp   NETCLOSE
```

> **A read returns at most 1024 bytes**, so clamp `BW` to 1024 before reading when more than that is waiting.

### Credentials

For FTP and SMB, set username (`$FD`) and password (`$FE`) **before** `OPEN` — each is the command byte followed by the string.

### Filesystem operations

Each is the command byte, then a device spec naming the target.

| Code | Char | Operation | fujinet-lib |
|---|---|---|---|
| `$21` | `!` | delete file | `network_delete` |
| `$20` |  | rename (spec is from,to) | `network_rename` |
| `$23` | `#` | lock (make read-only) | `network_lock` |
| `$24` | `$` | unlock | `network_unlock` |
| `$2A` | `*` | make directory | `network_mkdir` |
| `$2B` | `+` | remove directory | `network_rmdir` |
| `$2C` | `,` | change directory | `network_chdir` |
| `$30` | `0` | get current directory | `network_getcwd` |

### Reading JSON

Open the resource, switch the channel into JSON mode (`$FC`, then mode byte `1`), parse (`$50` `'P'`), then set a JSONPath with `$51` (`'Q'`) and retrieve the value with a normal `STATUS` + read. *fujinet-lib:* `network_json_parse()`, `network_json_query()`.

### HTTP verbs and headers

The access mode chosen at `OPEN` selects the verb (read = GET, `$0D` = POST, `$05` = DELETE). Command byte `$4D` (`'M'`) steers the channel between body (`0`), collect request headers (`1`), read response headers (`2`); a header is then sent with an ordinary write. *fujinet-lib:* `network_http_set_channel_mode()`.

### TCP and UDP

* `$41` (`'A'`) — TCP accept a waiting client on a listening channel.
* `$63` (`'c'`) — TCP close the current client, keep the listener.
* `$44` (`'D'`) — UDP set destination `"host:port"` for the next writes.
* `$72` (`'r'`) — UDP get the last datagram sender's address.

---

## The Fuji Control Device

The device at id `$0F` is the one CONFIG talks to: the Wi-Fi radio, the host and disk-image mounts, the directory browser, app-key storage, the clock, and utilities. It uses the high-numbered `FUJICMD_` bytes from `fujiCommandID.h`. Set `FNDEV` to `$0F`, write the command, then read the reply.

> Not every code in `fujiCommandID.h` is serviced on the ADAM. Documented here are those `adamFuji.cpp` actually dispatches.

### The slots model

**Host slots** (8) name where disks live — a TNFS server, an SMB share, the SD card. **Disk slots** (4) are the drive bays, each mapping to an AdamNet drive `$04`–`$07`. Mounting is a two-step: mount a host, browse it, mount an image into a disk slot.

### SCAN NETWORKS — `SEND $FD`

Write the one-byte command; the read returns the count of access points found in the first byte. Shown both ways:

```z80
; --- the EOS road ---
SCAN    ld   a,$0F
        ld   (FNDEV),a
        ld   a,$FD
        ld   (SCMD),a
        ld   hl,SCMD
        ld   (FNBUF),hl
        ld   hl,1
        ld   (FNLEN),hl
        call FNWR            ; send SCAN
        ld   hl,RESP
        ld   (FNBUF),hl
        ld   hl,1024
        ld   (FNLEN),hl
        call FNRD            ; read reply
        ld   a,(RESP)        ; A = number of APs found
        ret
;
; --- the CP/M road: identical payload, DCB plumbing ---
SCANC   call FINDDCB         ; HL -> Fuji DCB
        ret  c
        push hl
        ld   de,SCMD
        ld   bc,1
        call DCBWR
        pop  hl
        ld   de,RESP
        ld   bc,1024
        call DCBRD
        ld   a,(RESP)
        ret
SCMD    db   $FD
RESP    ds   1024
```

### More Wi-Fi / adapter commands

| Command | Byte | Notes |
|---|---|---|
| GET SCAN RESULT | `$FC` | write `$FC`, index *n*; read 32-byte SSID + signed RSSI |
| SET SSID | `$FB` | write `$FB` + 32-byte SSID + 64-byte password |
| GET SSID | `$FE` | read the stored SSID/password pair |
| GET WIFI STATUS | `$FA` | read one byte: `3` = connected, `6` = disconnected |
| GET ADAPTER CONFIG | `$E8` | read the live config (see below) |

**GET ADAPTER CONFIG (`$E8`) reply**

| Offset | Bytes | Field |
|---|---|---|
| 0 | 32 | SSID |
| 32 | 64 | hostname |
| 96 | 4 | local IP |
| 100 | 4 | gateway |
| 104 | 4 | netmask |
| 108 | 4 | DNS IP |
| 112 | 6 | MAC address |
| 118 | 6 | BSSID |
| 124 | 15 | firmware version string |

### Hosts and disk slots

| Command | Byte | Notes |
|---|---|---|
| READ HOST SLOTS | `$F4` | read 8 × 32-byte names (256 bytes) |
| WRITE HOST SLOTS | `$F3` | write `$F3` + 256 bytes |
| READ DEVICE SLOTS | `$F2` | read the 38-byte-per-slot array |
| WRITE DEVICE SLOTS | `$F1` | write `$F1` + the array |
| MOUNT HOST | `$F9` | write `$F9` + host-slot number |
| UNMOUNT HOST | `$E6` | write `$E6` + host-slot number |
| MOUNT IMAGE | `$F8` | write `$F8` + disk slot + access mode (1=RO, 2=RW) |
| UNMOUNT IMAGE | `$E9` | write `$E9` + disk slot |
| MOUNT ALL | `$D7` | command byte only |
| SET DEVICE FILENAME | `$E2` | write `$E2` + disk slot + filename |
| GET DEVICE FILENAME | `$A0`–`$A9` | write `$A0+ds`; read the path |
| NEW DISK | `$E7` | write `$E7` + host + disk + 4-byte block count + 256-byte name |

**Device-slot record (38 bytes):** host slot (1), access mode (1: 1=read, 2=read/write), filename (36).

```z80
; Mount host slot 0, then image in disk slot 1, read/write
MOUNT   ld   a,$0F
        ld   (FNDEV),a
        ld   a,$F9
        ld   (MBUF),a
        xor  a
        ld   (MBUF+1),a      ; host slot 0
        ld   hl,MBUF
        ld   (FNBUF),hl
        ld   hl,2
        ld   (FNLEN),hl
        call FNWR
        ld   a,$F8
        ld   (MBUF),a
        ld   a,1
        ld   (MBUF+1),a      ; disk slot 1
        ld   a,2
        ld   (MBUF+2),a      ; mode = read/write
        ld   hl,3
        ld   (FNLEN),hl
        jp   FNWR
MBUF    ds   4
```

### Browsing a host

| Command | Byte | Notes |
|---|---|---|
| OPEN DIRECTORY | `$F7` | write `$F7` + host slot + path + NUL + optional filter |
| READ DIR ENTRY | `$F6` | write `$F6` + max length + flags (`$80` = append details); read one entry |
| CLOSE DIRECTORY | `$F5` | command byte only |
| GET/SET DIR POSITION | `$E5`/`$E4` | paging |

An entry whose first byte is `$7F` is the **end-of-directory** marker — stop reading. On the ADAM the firmware prepends two type-icon bytes (folder / DDP / DSK / ROM) to each filename; skip or render them.

```z80
; host slot 0 already mounted; FNDEV = $0F
LISTDIR ld   a,$0F
        ld   (FNDEV),a
        ld   a,$F7
        ld   (DBUF),a
        xor  a
        ld   (DBUF+1),a      ; host slot 0
        ld   a,'/'
        ld   (DBUF+2),a
        xor  a
        ld   (DBUF+3),a      ; NUL: no filter
        ld   hl,DBUF
        ld   (FNBUF),hl
        ld   hl,4
        ld   (FNLEN),hl
        call FNWR
LD_NEXT ld   a,$F6
        ld   (DBUF),a
        ld   a,40
        ld   (DBUF+1),a      ; max length
        xor  a
        ld   (DBUF+2),a      ; flags = 0
        ld   hl,DBUF
        ld   (FNBUF),hl
        ld   hl,3
        ld   (FNLEN),hl
        call FNWR
        ld   hl,ENTRY
        ld   (FNBUF),hl
        ld   hl,40
        ld   (FNLEN),hl
        call FNRD
        ld   a,(ENTRY)
        cp   $7F             ; end-of-directory?
        jr   z,LD_END
        ld   hl,ENTRY+2      ; skip the two icon bytes
PR_LP   ld   a,(hl)
        or   a
        jr   z,PR_EOL
        call COUT
        inc  hl
        jr   PR_LP
PR_EOL  ld   a,13
        call COUT
        jr   LD_NEXT
LD_END  ld   a,$F5           ; CLOSE DIRECTORY
        ld   (DBUF),a
        ld   hl,DBUF
        ld   (FNBUF),hl
        ld   hl,1
        ld   (FNLEN),hl
        jp   FNWR
DBUF    ds   8
ENTRY   ds   64
```

### App keys — saving state

A small block (up to 64 bytes) the FujiNet stores for your program, indexed by creator id, app id, and key id.

* **OPEN APPKEY (`$DC`)** — write `$DC` + creator id (2, little-endian) + app id (1) + key id (1) + mode (1: 0=read, 1=write).
* **READ APPKEY (`$DD`)** — after an open in read mode, write `$DD` then read the bytes.
* **WRITE APPKEY (`$DE`)** — after an open in write mode, write `$DE` + the data.

*fujinet-lib:* `fuji_read_appkey()`, `fuji_write_appkey()`.

### Housekeeping, hashing, Base64, QR

| Code | Action |
|---|---|
| `$D9` | enable/disable CONFIG boot (1 byte) |
| `$D6` | set boot mode (1 byte) |
| `$D5` / `$D4` | enable / disable a device (1 byte: device id) |
| `$D1` | device-enabled status (read 1 byte) |
| `$D8` | copy file between hosts |
| `$D3` | random number (read 2 bytes) |
| `$BB` | generate a GUID string |
| `$FF` | reset the FujiNet |
| `$C8 $C7 $C6 $C5 $C2` | hash: input, compute, length, output, clear |
| `$D0 $CF $CE $CD` | Base64 encode: input, compute, length, output |
| `$CC $CB $CA $C9` | Base64 decode: input, compute, length, output |
| `$BC $BD $BE $BF` | QR: input, encode, length, output |

For hashing, the algorithm goes in the byte after `$C7` (0 = MD5, 1 = SHA-1, 2 = SHA-256, 3 = SHA-512).

---

## Telling Time

The ADAM has never known what time it is. The FujiNet does. Unlike the Atari and Apple, which expose a separate clock device, the ADAM reads the clock straight from the Fuji control device.

### GET TIME — `SEND $D2`

Point `FNDEV` at `$0F`, write `$D2`, then read seven bytes:

| Offset | Bytes | Field |
|---|---|---|
| 0 | 1 | century (add to year; `$13` = 19) |
| 1 | 1 | year (0–99) |
| 2 | 1 | month (1–12) |
| 3 | 1 | day |
| 4 | 1 | hour (24h) |
| 5 | 1 | minute |
| 6 | 1 | second |

The time is in the FujiNet's configured zone (managed from CONFIG). *fujinet-lib:* `fuji_get_time()`.

```z80
GETTIME ld   a,$0F
        ld   (FNDEV),a
        ld   a,$D2
        ld   (TCMD),a
        ld   hl,TCMD
        ld   (FNBUF),hl
        ld   hl,1
        ld   (FNLEN),hl
        call FNWR
        ld   hl,NOW
        ld   (FNBUF),hl
        ld   hl,7
        ld   (FNLEN),hl
        call FNRD
        ret
TCMD    db   $D2
NOW     ds   7               ; cent, year, month, day, hour, min, sec
```

---

## Error Codes

### AdamNet master result codes

Land in the DCB status byte (high bit set) and in `A` from `FNWR`/`FNRD`:

| Code | Name | Meaning |
|---|---|---|
| `$80` | `ADAMNET_OK` | success |
| `$81` | `READY_TIMEOUT` | READY packet not answered in time |
| `$83` | `SEND_TIMEOUT` | SEND packet not answered in time |
| `$85` | `SEND_DATA_BREAK` | device broke off during a send |
| `$88` | `SEND_DATA_NACK` | device NACKed the sent data |
| `$89` | `RECEIVE_TIMEOUT` | RECEIVE packet not answered in time |
| `$8C` | `RECEIVE_NACK` | device NACKed a receive |
| `$8D` | `CLR_TIMEOUT` | device did not send its data in time |
| `$93` | `STAT_TIMEOUT` | STATUS packet not answered in time |
| `$9B` | `TIMEOUT` | general timeout — retry the transaction |

### EOS error codes

Strip the high bit (`AND $7F`) before comparing:

| Code | Meaning |
|---|---|
| 0 | no error |
| 1 | DCB not found |
| 2 | DCB busy |
| 3 | DCB idle |
| 5 | no file |
| 9 | bad file number |
| 10 | end of file |
| 13 | storage medium full |
| `$9B` | device timeout |

### Network device status codes

Read from byte 3 of a Network `STATUS` reply:

| Code | Meaning |
|---|---|
| 1 | normal — connected, no error |
| 136 | end of file — the resource is fully read |

### fujinet-lib error codes

| Code | Name | Meaning |
|---|---|---|
| `$00` | `FN_ERR_OK` | no error |
| `$01` | `FN_ERR_IO_ERROR` | an I/O problem with the device |
| `$02` | `FN_ERR_BAD_CMD` | called with bad arguments |
| `$03` | `FN_ERR_OFFLINE` | the device is offline |
| `$04` | `FN_ERR_WARNING` | non-fatal device warning |
| `$05` | `FN_ERR_NO_DEVICE` | no network device present |
| `$FF` | `FN_ERR_UNKNOWN` | an unmapped device error |

---

## Command Quick Reference

Codes are the **first byte** of the payload you write to the device.

**Devices**

| Id | AdamNet device | | Addr | EOS routine |
|---|---|---|---|---|
| `$01` | keyboard | | `$FC54` | `FIND_DCB` |
| `$02` | printer | | `$FC5A` | `FIND_PCB` |
| `$04`–`$07` | disk drives 1–4 | | `$FCA5` | `START_RD_CH_DEV` |
| `$08` | tape drive | | `$FC48` | `END_RD_CH_DEV` |
| `$09`–`$0A` | Network (`N1:`, `N2:`) | | `$FCAE` | `START_WR_CH_DEV` |
| `$0F` | Fuji control | | `$FC51` | `END_WR_CH_DEV` |

**DCB status requests:** poke `3` to write, `4` to read; `>= $80` is the master's completion code.

**Network device (id `$09` / `$0A`)**

| Code | Char | Operation |
|---|---|---|
| `$4F` | `O` | open connection (mode, trans, spec) |
| `$43` | `C` | close connection |
| `$53` | `S` | channel status (bw, conn, err) |
| `$57` | `W` | write bytes |
| — |  | read waiting bytes (RECEIVE beat) |
| `$FD`/`$FE` |  | set username / password |
| `$FC` |  | channel mode (0 protocol, 1 JSON) |
| `$50` | `P` | JSON parse |
| `$51` | `Q` | JSON query (then status + read) |
| `$2C` | `,` | change directory |
| `$30` | `0` | get current directory |
| `$20` |  | rename (spec is from,to) |
| `$21` | `!` | delete file |
| `$23` | `#` | lock file |
| `$24` | `$` | unlock file |
| `$2A` | `*` | make directory |
| `$2B` | `+` | remove directory |
| `$4D` | `M` | HTTP channel mode (body/headers) |
| `$41` | `A` | TCP accept connection |
| `$63` | `c` | TCP close client |
| `$44` | `D` | UDP set destination |
| `$72` | `r` | UDP get remote address |

**Fuji control device (id `$0F`)**

| Code | Operation |
|---|---|
| `$FF` | reset FujiNet |
| `$FE` / `$FB` | get / set SSID |
| `$FD` | scan networks (read returns count) |
| `$FC` | get scan result *n* |
| `$FA` | get Wi-Fi status |
| `$F9` / `$E6` | mount / unmount host slot |
| `$F8` / `$E9` | mount / unmount disk image |
| `$D7` | mount all |
| `$F4` / `$F3` | read / write host slots |
| `$F2` / `$F1` | read / write device slots |
| `$E2` | set device filename |
| `$A0`–`$A9` | get device filename (slot 0–9) |
| `$E7` | new (blank) disk |
| `$F7` | open directory |
| `$F6` | read directory entry |
| `$F5` | close directory |
| `$E5` / `$E4` | get / set directory position |
| `$E8` | get adapter config |
| `$DC` | open app key |
| `$DD` / `$DE` | read / write app key |
| `$D9` | enable CONFIG boot |
| `$D6` | set boot mode |
| `$D5` / `$D4` | enable / disable device |
| `$D1` | device enable status |
| `$D8` | copy file |
| `$D3` | random number |
| `$D2` | get time (7 bytes) |
| `$BB` | generate GUID |
| `$C8 $C7 $C6 $C5 $C2` | hash: input, compute, len, out, clear |
| `$BC $BD $BE $BF` | QR: input, encode, length, output |

---

## netcat in Z80

A *netcat* written for **CP/M** on the ADAM. It opens a raw TCP connection through the Network device, then pumps bytes both ways — the far end to the screen, the keyboard to the far end — until the connection drops or you press **ESC**.

It takes the **CP/M road** deliberately: no EOS, just the PCB at `$FEC0`, the network DCB found by hand, and CP/M's own BDOS for the console. Assemble with `FINDDCB` (match value changed to `$09` for `N1:`) and `DCBWR` / `DCBRD`, to a `.COM`, and run from the CP/M prompt.

```z80
; ============================================================
;  FUJINET NETCAT for the Coleco ADAM, under CP/M
;  socket <-> screen + keyboard, ESC to quit
;  assemble with FINDDCB (match $09), DCBWR, DCBRD
; ============================================================
BDOS    equ  $0005          ; CP/M entry
CONIO   equ  6              ; BDOS direct console I/O
;
        org  $0100          ; CP/M .COM load address
;
NETCAT  call FINDDCB        ; HL -> N1: DCB (match $09)
        jp   c,NODEV
        ld   (NETDCB),hl
;
        ld   hl,(NETDCB)    ; open TCP, read/write, no translation
        ld   de,OPENB
        ld   bc,OPENL
        call DCBWR
;
PUMP    call STATUS         ; how much is waiting? still up?
        ld   a,(CONNF)
        or   a
        jr   z,CLOSED
        ld   a,(NERRF)
        cp   136            ; EOF ?
        jr   z,CLOSED
        ld   hl,(BWCNT)
        ld   a,h
        or   l
        jr   z,KEYS
;
        ld   a,h            ; clamp request to 1024 bytes
        cp   4
        jr   c,RDOK
        ld   hl,1024
RDOK    ld   (RDLEN),hl
        ld   hl,(NETDCB)
        ld   de,RXBUF
        ld   bc,(RDLEN)
        call DCBRD
        ld   hl,(NETDCB)    ; DCB length = bytes delivered
        ld   de,3
        add  hl,de
        ld   c,(hl)
        inc  hl
        ld   b,(hl)         ; BC = count
        ld   hl,RXBUF
EMIT    ld   a,b
        or   c
        jr   z,KEYS
        ld   e,(hl)
        push hl
        push bc
        ld   c,CONIO
        call BDOS
        pop  bc
        pop  hl
        inc  hl
        dec  bc
        jr   EMIT
;
KEYS    ld   c,CONIO
        ld   e,$FF          ; $FF = input request
        call BDOS
        or   a
        jr   z,PUMP
        cp   $1B            ; ESC ?
        jr   z,QUIT
        ld   (ONEB),a       ; send this one byte, behind a 'W'
        ld   a,'W'
        ld   (WBUF),a
        ld   hl,(NETDCB)
        ld   de,WBUF
        ld   bc,2
        call DCBWR
        jr   PUMP
;
STATUS  ld   hl,(NETDCB)    ; write 'S', read 4 bytes, unpack
        ld   de,SCMD
        ld   bc,1
        call DCBWR
        ld   hl,(NETDCB)
        ld   de,STATB
        ld   bc,4
        call DCBRD
        ld   hl,(STATB)
        ld   (BWCNT),hl
        ld   a,(STATB+2)
        ld   (CONNF),a
        ld   a,(STATB+3)
        ld   (NERRF),a
        ret
;
CLOSED  ld   de,BYEMSG
        call PRSTR
QUIT    ld   hl,(NETDCB)
        ld   de,CLB
        ld   bc,1
        call DCBWR
        rst  0              ; warm boot back to CP/M
NODEV   ld   de,NOMSG
        call PRSTR
        rst  0
;
PRSTR   ld   c,9            ; BDOS print string
        jp   BDOS
;
OPENB   db   'O',$0C,$00,"N1:TCP://192.168.1.5:9000/",0
OPENL   equ  $-OPENB
SCMD    db   "S"
CLB     db   "C"
WBUF    db   0
ONEB    db   0
STATB   ds   4
BWCNT   dw   0
CONNF   db   0
NERRF   db   0
RDLEN   dw   0
NETDCB  dw   0
RXBUF   ds   1024
BYEMSG  db   13,10,"** CONNECTION CLOSED",13,10,"$"
NOMSG   db   13,10,"** NO FUJINET FOUND",13,10,"$"
```

On the other end, anything that speaks TCP will do — the classic test is the Unix `netcat` itself, listening on the port you named:

```
A>NETCAT

HELLO FROM THE ADAM
and hello back from your laptop
the quick brown fox jumped over

** CONNECTION CLOSED
A>
```

Type, and your keystrokes cross the room — or the world — and the reply paints onto a 3.58 MHz machine that predates the network it just joined. Find the DCB, write the command, read the reply, and the rest is just Z80.

---

*This guide is free software, part of the [`fujinet-manuals`](https://github.com/FujiNetWIFI/fujinet-manuals) repository, released under the GNU General Public License v3. Questions? The FujiNet community answers day and night on [Discord](https://discord.gg/7MfFTvD).*
