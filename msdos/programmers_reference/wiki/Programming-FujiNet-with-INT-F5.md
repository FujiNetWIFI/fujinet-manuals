# Programming FujiNet with INT F5 (MS-DOS)

This is the plain-text companion to the printed *Technical Reference*, which
is styled after the 1984 IBM PC *Technical Reference*. It documents the
**INT F5** interface — the software interrupt installed by the FujiNet device
driver (`FUJINET.SYS`) through which any program can command any FujiNet
device. It is the floor that the FujiNet C library (`fujinet-lib`) ultimately
calls; you can call it directly from assembler or C.

---

## Contents

- [The Device Model](#the-device-model)
- [The Calling Convention](#the-calling-convention)
- [The Field Descriptor](#the-field-descriptor)
- [Return Codes](#return-codes)
- [The C Wrappers](#the-c-wrappers)
- [The Devices](#the-devices)
- [Command Reference: Control Device (70h)](#command-reference-control-device-70h)
- [Command Reference: Network Adapters (71h–78h)](#command-reference-network-adapters-71h78h)
- [Command Reference: Disk Drives (31h–38h)](#command-reference-disk-drives-31h38h)
- [Command Reference: Clock (45h)](#command-reference-clock-45h)
- [Worked Example: NETCAT in Assembler](#worked-example-netcat-in-assembler)
- [Appendix: Network Error Codes](#appendix-network-error-codes)
- [Appendix: The FujiBus Frame](#appendix-the-fujibus-frame)

---

## The Device Model

The FujiNet presents itself as a small bus of **virtual devices**: eight disk
drives, eight network adapters, a real-time clock, a printer, and a control
device that manages them all. Every command is addressed to a **device**
(an ID in `AL`) and names a **command** (a code in `AH`). The same command
byte can mean different things to different devices, so the device ID always
travels with it.

You issue a command by loading registers and executing `INT F5h`. The driver
frames the command, sends it over the serial cable, waits for the reply,
copies any returned data into your buffer, and returns a one-character result
in `AL`.

---

## The Calling Convention

| Register | Holds |
|----------|-------|
| `DL` | Payload direction: `00h` none, `40h` read, `80h` write |
| `DH` | Field descriptor — how many AUX bytes to send (see below) |
| `AL` | Device ID |
| `AH` | Command code |
| `CL` | AUX1 — first parameter |
| `CH` | AUX2 — second parameter |
| `SI` | AUX3 (low byte) : AUX4 (high byte) |
| `ES:BX` | Far pointer to the payload buffer (read or write) |
| `DI` | Length of the payload buffer, in bytes |

`ES:BX` and `DI` are used only when `DL` is `40h` or `80h`.

**Direction (`DL`):**

| DL | Form | Meaning |
|----|------|---------|
| `00h` | None | Send the command alone; no data moves. |
| `40h` | Read | The FujiNet returns `DI` bytes into `ES:BX`. |
| `80h` | Write | Your `DI` bytes at `ES:BX` go to the FujiNet. |

> **Note:** The older `fujinet-bios.md` document describes an earlier layout
> (direction in `AH`, command in `CL`). This reference follows the **current**
> driver and `fujinet-lib`, which is what the firmware speaks.

---

## The Field Descriptor

A command's AUX bytes only reach the FujiNet if the field descriptor in `DH`
says how many to send. Set `DH` to match the command:

| Name | DH | Bytes | Sends |
|------|----|-------|-------|
| `FUJI_FIELD_NONE` | `00h` | 0 | no AUX |
| `FUJI_FIELD_A1` | `01h` | 1 | AUX1 |
| `FUJI_FIELD_A1_A2` | `02h` | 2 | AUX1, AUX2 (e.g. a 16-bit length) |
| `FUJI_FIELD_A1_A2_A3` | `03h` | 3 | AUX1–AUX3 |
| `FUJI_FIELD_A1_A2_A3_A4` | `04h` | 4 | AUX1–AUX4 |
| `FUJI_FIELD_C1234` | `07h` | 4 | AUX1–AUX4 as one 32-bit value |

A command whose AUX bytes you set in `CL`/`CH` but whose descriptor in `DH` is
left at `00h` reaches the FujiNet with **no** parameters, and is usually
rejected. Always set `DH` to match.

---

## Return Codes

On return, `AL` holds one character:

| AL | Meaning |
|----|---------|
| `'C'` | Complete — finished without error |
| `'E'` | Error — finished, but a problem occurred |
| `'N'` | NAK — the device did not recognize the command |

For network commands, the detailed error is the fourth byte of the next
STATUS reply (see the appendix).

---

## The C Wrappers

`fujinet-lib` exposes the interface as three functions, one per direction:

```c
unsigned char int_f5      (unsigned char dev, unsigned char cmd,
                           unsigned char aux1, unsigned char aux2);
unsigned char int_f5_read (unsigned char dev, unsigned char cmd,
                           unsigned char aux1, unsigned char aux2,
                           void *buf, unsigned short len);
unsigned char int_f5_write(unsigned char dev, unsigned char cmd,
                           unsigned char aux1, unsigned char aux2,
                           void *buf, unsigned short len);
```

They set `DH` and `SI` to zero; when a command needs AUX bytes (or AUX3/AUX4),
set `DH` (and `SI`) yourself — the assembler examples below show how. The
simplest call, resetting the FujiNet, needs neither payload nor parameters:

```asm
        MOV  DL,00h        ; direction: none
        MOV  AL,70h        ; device: FujiNet control
        MOV  AH,0FFh       ; command: RESET
        INT  0F5h          ; AL = 'C' on success
```

---

## The Devices

| AL | Device |
|----|--------|
| `31h`–`38h` | Disk drives 1–8 (block devices) |
| `40h`–`43h` | Printer (driven by `FUJIPRN.SYS` via INT 17h) |
| `45h` | Real-time clock (NTP) |
| `70h` | FujiNet control device |
| `71h`–`78h` | Network adapters 1–8 (character devices) |

---

## Command Reference: Control Device (70h)

The control device manages the FujiNet. The most-used commands:

| Cmd | Name | Dir | Field | Notes |
|-----|------|-----|-------|-------|
| `FFh` | RESET | none | — | Restart the FujiNet |
| `E8h` | GET ADAPTER CONFIG | read | — | 139-byte `AdapterConfig` |
| `FDh` | SCAN NETWORKS | read | — | Returns count of networks |
| `FCh` | GET SCAN RESULT | read | A1 | AUX1 = index; returns `SSIDInfo` |
| `FBh` | SET SSID | write | — | Payload `ssid[33]`+`password[64]` |
| `FAh` | GET WIFI STATUS | read | — | 1 byte; `3` = connected |
| `F9h` | MOUNT HOST | none | A1 | AUX1 = host slot |
| `F8h` | MOUNT IMAGE | none | A1_A2 | AUX1 = device slot, AUX2 = mode (1 R/O, 2 R/W) |
| `E9h` | UNMOUNT IMAGE | none | A1 | AUX1 = device slot |
| `F4h` / `F3h` | READ / WRITE HOST SLOTS | read/write | — | 8 × 32-byte names |
| `F2h` / `F1h` | READ / WRITE DEVICE SLOTS | read/write | — | 8 × `DeviceSlot` |
| `F7h` | OPEN DIRECTORY | write | A1 | AUX1 = host slot, payload = path |
| `F6h` | READ DIR ENTRY | read | A1_A2 | AUX1 = max len, AUX2 = options |
| `F5h` | CLOSE DIRECTORY | none | — | |
| `E7h` | NEW DISK | write | — | Payload = `NewDisk` struct |
| `D7h` | MOUNT ALL | none | — | Mount every selected slot |

Other commands: `BBh` GENERATE GUID, `C1h` GET HEAP, `D3h` RANDOM NUMBER,
`D2h` GET TIME, `D8h` COPY FILE, `D9h` CONFIG BOOT, `D6h` SET BOOT MODE,
`E2h`/`DAh` SET/GET DEVICE FULLPATH, `E1h`/`E0h` SET/GET HOST PREFIX,
`DCh`/`DBh`/`DEh`/`DDh` OPEN/CLOSE/WRITE/READ APPKEY, `C4h` GET ADAPTER CONFIG
EXTENDED, `EBh` SET BAUDRATE, `FEh` GET SSID, the HASH engine (`C2h`–`C8h`),
and the QR-code engine (`BCh`–`BFh`).

**Example — read the adapter configuration:**

```c
typedef struct {
    char  ssid[33];       unsigned char gateway[4];
    char  hostname[64];   unsigned char netmask[4];
    unsigned char localIP[4];  unsigned char dnsIP[4];
    unsigned char macAddress[6];
    unsigned char bssid[6];    char fn_version[15];
} AdapterConfig;

AdapterConfig ac;
int_f5_read(0x70, 0xE8, 0, 0, &ac, sizeof(ac));
```

---

## Command Reference: Network Adapters (71h–78h)

A network adapter is one connection. OPEN it with a URL (a *devicespec* such
as `N:TCP://host:1234/` or `N:HTTP://example.com/page`), READ and WRITE it as
a stream, and CLOSE it.

| Cmd | Name | Dir | Field | Notes |
|-----|------|-----|-------|-------|
| `4Fh` `'O'` | OPEN | write | A1_A2 | AUX1 = mode (4 R, 8 W, 0Ch RW), AUX2 = translation (0–3); payload = URL |
| `53h` `'S'` | STATUS | read | — | 4 bytes: bytes-waiting lo, hi, connected, error |
| `52h` `'R'` | READ | read | A1_A2 | AUX1/2 = count (lo/hi); returns data |
| `57h` `'W'` | WRITE | write | A1_A2 | AUX1/2 = count; payload = data |
| `43h` `'C'` | CLOSE | none | — | |
| `50h` `'P'` | PARSE | none | — | Parse last-read data as JSON |
| `51h` `'Q'` | QUERY | write | — | Payload = JSONPath query; STATUS then READ the result |
| `FCh` | CHANNEL MODE | — | A1_A2 | AUX2: 0 = stream, 1 = JSON |
| `25h` / `26h` | SEEK / TELL | — | — | 32-bit offset |
| `20h` `21h` `2Ah` `2Bh` | RENAME / DELETE / MKDIR / RMDIR | — | — | File-protocol operations |
| `FDh` / `FEh` | USERNAME / PASSWORD | write | — | Credentials for the next OPEN |

**Example — open a TCP connection (read/write, no translation):**

```asm
        MOV  DX,0280h      ; DH=02 (A1_A2), DL=80 (write)
        MOV  AX,4F71h      ; AH=4Fh 'O', AL=71h adapter 1
        MOV  CL,0Ch        ; AUX1 = read/write
        MOV  CH,00h        ; AUX2 = no translation
        LES  BX,[url]      ; ES:BX -> "N:TCP://host:port/"
        MOV  DI,256        ; length
        INT  0F5h          ; AL = 'C' on success
```

---

## Command Reference: Disk Drives (31h–38h)

A disk drive reads and writes 512-byte sectors of the image in its slot. The
sector number is a 32-bit value in AUX1–AUX4 with the `C1234` descriptor.

| Cmd | Name | Dir | Field | Notes |
|-----|------|-----|-------|-------|
| `52h` `'R'` | READ | read | C1234 | AUX1–4 = sector; returns 512 bytes |
| `57h` `'W'` | WRITE | write | C1234 | AUX1–4 = sector; payload = 512 bytes |
| `53h` `'S'` | STATUS | read | — | Mounted / read-write state |
| `50h` `'P'` | PUT | write | C1234 | Write a sector, no verify |
| `21h` | FORMAT | none | — | Format the mounted image |

**Example — read sector 0 of drive 1:**

```asm
        MOV  DX,0740h      ; DH=07 (C1234), DL=40 (read)
        MOV  AX,5231h      ; AH=52h 'R', AL=31h drive 1
        XOR  CX,CX         ; AUX1/2 = sector low word
        XOR  SI,SI         ; AUX3/4 = sector high word
        LES  BX,[buf]
        MOV  DI,512
        INT  0F5h
```

---

## Command Reference: Clock (45h)

| Cmd | Name | Dir | Returns |
|-----|------|-----|---------|
| `93h` | GET TIME | read | 6 bytes: year-1900, month, day, hour, min, sec |
| `5Ah` | GET TIME (ISO UTC) | read | ISO-8601 string, e.g. `2026-06-13T18:20:08Z` |
| `49h` | GET TIME (ISO local) | read | ISO-8601 local string |
| `99h` | SET TIMEZONE | write | Payload = POSIX TZ string (e.g. `CST6CDT`) |

```c
unsigned char t[6];
int_f5_read(0x45, 0x93, 0, 0, t, 6);   /* t[0]=year-1900 ... t[5]=sec */
```

---

## Worked Example: NETCAT in Assembler

A bare-bones netcat — opens a TCP connection, prints what it receives, and
sends what you type. `ESC` quits. Assemble with TASM (`TASM NETCAT` then
`TLINK /t NETCAT`) or MASM (`ML /AT NETCAT.ASM`) to make `NETCAT.COM`.

```asm
; NETCAT.ASM -- a tiny netcat for FujiNet, via INT F5h.
        .MODEL TINY
        .CODE
        ORG  100h
START:  MOV  AX,CS
        MOV  ES,AX
        MOV  DX,0280h          ; open: A1_A2 / write
        MOV  AX,4F71h          ; 'O', adapter 1
        MOV  CL,0Ch            ; read/write
        MOV  CH,00h            ; no translation
        MOV  BX,OFFSET SPEC
        MOV  DI,SPECLEN
        INT  0F5h
        CMP  AL,'C'
        JNE  QUIT
POLL:   MOV  DX,0040h          ; status
        MOV  AX,5371h
        MOV  BX,OFFSET STAT
        MOV  DI,4
        INT  0F5h
        CMP  BYTE PTR [STAT+2],0   ; connected?
        JE   DONE
        MOV  AX,WORD PTR [STAT]    ; bytes waiting
        OR   AX,AX
        JZ   KBD
        CMP  AX,128
        JBE  RLEN
        MOV  AX,128
RLEN:   MOV  CX,AX
        MOV  DI,AX
        MOV  DX,0240h          ; read: A1_A2 / read
        PUSH AX
        MOV  AX,5271h
        MOV  BX,OFFSET BUF
        INT  0F5h
        POP  CX
        MOV  BX,1              ; stdout
        MOV  DX,OFFSET BUF
        MOV  AH,40h
        INT  21h
KBD:    MOV  AH,0Bh            ; key ready?
        INT  21h
        OR   AL,AL
        JZ   POLL
        MOV  AH,08h            ; read key, no echo
        INT  21h
        CMP  AL,27             ; ESC quits
        JE   DONE
        MOV  [BUF],AL
        MOV  DX,0280h          ; write: A1_A2 / write
        MOV  AX,5771h
        MOV  CX,1
        MOV  BX,OFFSET BUF
        MOV  DI,1
        INT  0F5h
        JMP  POLL
DONE:   MOV  DX,0000h          ; close
        MOV  AX,4371h
        INT  0F5h
QUIT:   MOV  AX,4C00h
        INT  21h
SPEC    DB   'N:TCP://192.168.1.10:9000/',0
SPECLEN EQU  $-SPEC
STAT    DB   4 DUP(0)
BUF     DB   128 DUP(0)
        END  START
```

---

## Appendix: Network Error Codes

When a network command returns `'E'`, the detailed reason is the fourth byte
of the next STATUS reply:

| Code | Meaning | Code | Meaning |
|------|---------|------|---------|
| 1 | Success | 170 | File not found |
| 131 | Write-only | 200 | Connection refused |
| 132 | Invalid command | 201 | Network unreachable |
| 135 | Read-only | 202 | Socket timeout |
| 136 | End of file | 203 | Network down |
| 138 | General timeout | 204 | Connection reset |
| 144 | General error | 207 | Not connected |
| 146 | Not implemented | 208 | Server not running |
| 162 | No space on device | 210 | Service unavailable |
| 165 | Invalid devicespec | 212 | Bad username/password |
| 167 | Access denied | 255 | Could not allocate buffers |

---

## Appendix: The FujiBus Frame

The packet the driver builds and SLIP-encodes on the wire. Multi-byte fields
are little-endian.

| Field | Bytes | Meaning |
|-------|-------|---------|
| device | 1 | Destination device ID |
| command | 1 | Command code |
| length | 2 | Total packet length, including this header |
| checksum | 1 | Fold-add checksum of the whole packet |
| fields | 1 | Field descriptor (how many AUX bytes follow) |
| AUX | 0–4 | The AUX parameter bytes |
| payload | n | Command data, if any |

The reply carries the same header with the command byte set to `ACK` (`06h`)
on success, followed by any returned data. The driver checks the length,
checksum, and device before reporting `'C'`.

---

*Sources: `fujinet-msdos/sys` (intf5.c, fujicom.c, fuji_f5.h),
`fujinet-firmware/lib/device/rs232`, and `fujinet-lib/msdos`. Everything is
open: [github.com/FujiNetWIFI](https://github.com/FujiNetWIFI).*
