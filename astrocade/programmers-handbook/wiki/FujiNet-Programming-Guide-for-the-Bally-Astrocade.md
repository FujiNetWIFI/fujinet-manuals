# FujiNet Programming Guide for the Bally Astrocade

*How to program the FujiNet cartridge on the Bally Arcade/Astrocade (Bally Professional Arcade): an in-depth tutorial on the in-memory cartridge mailbox, client libraries in Z80 assembly and Z88DK C, a complete reference for every Fuji-device and network-device command the platform answers, and guided tours of five shipping programs — NETCAT, TEXAS HOLD'EM, BATTLESHIP, FUJITZEE, and CONFIG.*

> **PDF edition** — this page is the wiki rendering of the *FujiNet Professional Arcade Programmers Handbook*, a ~200-page booklet typeset in the style of the 1977 Bally Owners Manual, with full program listings. Source and PDF live in the `fujinet-manuals` repository under `astrocade/programmers-handbook/`.
>
> Every address, opcode, struct offset and code fragment here is transcribed from the live project sources: `fujinet-firmware` (`pico/astrocade/` and the RS232 device layer) at `20e89ead5`, `netcat/astrocade` at `b269a3d`, `fujinet-texasHoldEm/astrocade` at `6ed0b6e`, `fujinet-battleship/astrocade` at `5b1f976`, `fujinet-fujitzee/astrocade` at `d20d20e`, `fujinet-config/astrocade` at `d551e1a`, z88dk at `3bd06cad`.

See also: [FujiNet-Network-Protocol-Handbook](FujiNet-Network-Protocol-Handbook) · [FujiNet-Programming-Guide-for-the-Intellivision](FujiNet-Programming-Guide-for-the-Intellivision)

---

## Contents

- [The FujiNet cartridge](#the-fujinet-cartridge)
- [The mailbox](#the-mailbox)
- [First contact](#first-contact)
- [The Z80 library](#the-z80-library)
- [C with Z88DK](#c-with-z88dk)
- [The network device](#the-network-device)
- [The Fuji device](#the-fuji-device)
- [Boot, swap, and banking](#boot-swap-and-banking)
- [Command reference: the Fuji device](#command-reference-the-fuji-device)
- [Command reference: the network device](#command-reference-the-network-device)
- [The five programs](#the-five-programs)
- [Error and status codes](#error-and-status-codes)

---

## The FujiNet cartridge

The Astrocade cartridge port is the most asymmetric in the FujiNet family. It carries A0–A12, D0–D7, one pre-decoded *Enable* that asserts for **reads** in 2000H–3FFFH, and power. No /RD, no /WR, no /IORQ, no clock, no reset line. Writes anywhere in 0000H–3FFFH are eaten by the console's magic function generator — a cartridge on this port is, electrically, a read-only answering machine.

So both directions of the FujiNet protocol ride the read path, a trick with deep Astrocade roots (the 512K homebrew mapper banks with reads at 3F80H–3FFFH; AstroBASIC toggled its tape relay the same way):

1. **The console talks by reading.** Certain pages of the window are *hotspots*: the cartridge decodes which address was read, and **the low eight address bits are the payload**. Reading 3F41H "sends" the byte 41H.
2. **The cartridge talks by repainting.** It serves its 8K window from RAM on its own processor and simply changes the bytes it serves.

Inside the shell, two processors work in tandem: an **RP2040** on the cartridge edge serves the window at Z80 bus speed, decodes hotspots and repaints replies; it speaks over USB (as CDC device; the adapter is host) to an **ESP32-S3** running the stock FujiNet `BUILD_RS232` firmware — the same SLIP-framed FujiBus packets FujiNet speaks over a serial port elsewhere. Under MAME the cartridge device compiles the very same mailbox sources and forwards FujiBus over TCP (bus-over-IP, default `127.0.0.1:9995`) to a fujinet-pc process.

```
YOUR PROGRAM  <--mailbox-->  RP2040  <--USB CDC/SLIP-->  ESP32-S3  <--WiFi-->  the world
Z80, 2000H-3AFFH             window server               BUILD_RS232
```

**The layout contract** (from `fuji_mailbox.h`, the single source of truth compiled into both the RP2040 firmware and the MAME model):

- Program code and data stay **below 3B00H** — 6,912 bytes (cart offsets 0000H–1AFFH).
- 3B00H–3CFFH is the reply window the cartridge repaints.
- 3D00H–3FFFH are the hotspot pages.
- At cart offset 1CFCH the image carries the 4-byte claim signature `FUJI` — a promise that 1B00H–1FFFH holds no code or data, so the mailbox may stay alive after the image boots. Booting a claim-less image (an ordinary game) disables the mailbox for the session.
- A cartridge image is exactly 8,192 bytes and begins with the 7-byte menued-cartridge header: `55H`, `DW MENUST`, `DW name`, `DW entry`.

**Interrupts stay off** — `DI` at entry, never `EI`. With interrupts off the Z80's I register keeps its reset value of 0, refresh cycles land in on-board ROM space, and the refresh-stray hazard below never arises. Poll the keypad and hand controls directly from ports 10H–17H; the BIOS SENTRY system needs interrupts you cannot give it. One more BIOS gotcha, inherited from the bring-up: `EXIT` (the interpreter-leave macro) assembles to `XINTC` = 02H — any bit-7-set interpreter byte would vector through the uninitialized user macro table at 4FFDH.

## The mailbox

All addresses below are **console addresses** (cart offset + 2000H), exactly as a program uses them.

### The window

| Console address | Name | What lives there |
|---|---|---|
| `2000H-3AFFH` | — | your program: 6,912 bytes |
| `3B00H-3BFFH` | `FNRDATA` | reply slice: 256 bytes of the current reply |
| `3C00H-3C0CH` | status bytes | see below |
| `3CFCH-3CFFH` | claim | `FUJI` signature (cart offset 1CFCH) |
| `3D00H-3D7FH` | `FNREGSEL` | hotspot: read `+r` arms register r |
| `3D80H-3DEFH` | `FNBKSEL` | hotspot: read `+page` selects a bank (protocol v2) |
| `3DFEH` | `FNSWAP` | hotspot: serve the staged boot image (armed only) |
| `3E00H-3EFFH` | `FNREGDAT` | hotspot: read `+v` delivers v to the armed register |
| `3F00H-3FFFH` | `FNDATA` | hotspot: read `+v` appends v to the TX stream |

### The thirteen status bytes

| Address | Name | Meaning |
|---|---|---|
| `3C00H` | `FNACKSQ` | echoes your SEQ when the reply is ready |
| `3C01H` | `FNSTATS` | bit 0 link up, bit 1 busy |
| `3C02H` | `FNERR` | transport verdict of the last transaction |
| `3C03H` | `FNREPLY` | 06H ACK or 15H NAK |
| `3C04H/3C05H` | `FNRXLL/FNRXLH` | reply length, little-endian |
| `3C06H` | `FNBSTAT` | boot state: 0 idle, 1 transfer, 2 ready, 80H failed |
| `3C07H` | `FNBPCT` | boot progress 0–100 |
| `3C08H` | `FNBERR` | boot error |
| `3C09H/3C0AH` | `FNMAGF/FNMAGN` | the letters `F`, `N` — cartridge presence |
| `3C0BH` | `FNPVER` | mailbox protocol version (2 = banking) |
| `3C0CH` | `FNSECHO` | echoes the slice number, painted **last** |

### The registers

Reached through a REGSEL/REGDATA read pair. 00H–0FH mirror the Odyssey² mailbox numbering where meanings match; 10H up is Astrocade-specific.

| Register | Name | Use |
|---|---|---|
| `00H` | DEVICE | FujiBus device id: 70H Fuji, 71H–78H network |
| `01H` | COMMAND | FujiBus command id |
| `02H` | NPARAM | number of parameters in the TX stream |
| `05H` | DATA RST | any value: rewind the TX write pointer |
| `06H` | RXSLICE | which reply slice `FNRDATA` shows (0–3) |
| `10H` | SEQ | nonzero and ≠ last ACK: launch the transaction |
| `11H` | BOOTLOCK | magic 0B5H arms the ROM swap |
| `12H/13H` | BOOTSEL | magic 0B5H then 4AH: reboot the cart to UF2 mode |

### The TX stream

At most **320 bytes** per transaction: first NPARAM parameters, each a *size byte* (1, 2 or 4) followed by that many value bytes little-endian, then the raw payload — whose length is simply whatever remains.

### One whole transaction

1. **Begin** — rewind TX (register 05H), then DEVICE, COMMAND, NPARAM.
2. **Stream** — parameters, then payload, one `3F00H+v` read per byte.
3. **Commit** — read `FNACKSQ`, add 1 (wrap 255→1; 0 is reserved), write it to SEQ. The cart fires the stream at the ESP32-S3 as one FujiBus packet.
4. **Wait** — poll `FNACKSQ` until it equals what you wrote. Then check `FNERR` (transport verdict) and `FNREPLY` (ACK/NAK), and capture `FNRXLL/FNRXLH` **immediately** — they describe the most recent transaction only.
5. **Read** — slice 0 is already painted (every transaction republishes it). For longer replies write 1–3 to RXSLICE and poll `FNSECHO` until it echoes — the cart paints the echo **last**, so a match means the slice is whole. Replies run to 1,024 bytes (4 slices).

**The sequence rule.** Derive SEQ from the cartridge's own persisted `FNACKSQ`, never a local counter: console RESET restarts your program but **not** the cartridge (the cart edge carries no reset line). A local counter desynchronizes forever after the first RESET; ACKSEQ+1 cannot.

**Stray-read defenses**, in depth: a REGDATA read with no immediately-preceding REGSEL read is a no-op (arming disarms after one use); a transaction launches only on a SEQ that is nonzero *and* different from the last acknowledged; the swap trigger sits at REGSEL offset 0FEH (bit 7 set, unreachable by the R register) and works only after BOOTLOCK arms it; and a `DI`/I=0 program keeps refresh out of cart space entirely.

**Timeouts.** The libraries wait in quanta of 65,536 polls (~2 s at 1.789 MHz). The shipping clients' choices: OPEN 8, READ 8, STATUS 4, CLOSE 3, Fuji commands 8, MOUNT_IMAGE 60 (with a progress bar), slice select 1.

**The reply window is never cleared** — a short reply leaves the stale tail of an older, longer one. Capture the length, believe only that many bytes, validate before acting (see the three rules under [the network device](#the-network-device)).

## First contact

The smallest useful program: prove the cartridge is there, run one transaction, show the result. `GET_ADAPTERCONFIG_EXTENDED` (0C4H to device 70H) is the perfect first transaction — no parameters, works before WiFi is up, and its best fields sit in slice 0: SSID at offset 0, firmware version at 125, dotted-decimal IP text at 140.

Z80 (using `fujilib.inc`; this is the shape of the firmware's `testrom/fujitest.asm`):

```asm
        CALL    FNCHECK         ; Z set if 'F','N' painted
        JP      NZ,NOCARD

        LD      A,FNDFUJI       ; device 70H
        LD      E,FCACFGX       ; GET_ADAPTERCONFIG_EXTENDED, 0C4H
        LD      L,0             ; no parameters, no payload
        CALL    FNBEGIN
        LD      B,8             ; ~16 s: covers ESP32 enumeration
        CALL    FNCOMMIT
        JR      C,TMOUT         ; carry: the cart never answered
        OR      A
        JR      NZ,LERR         ; FNERR nonzero: no link, timeout...

        LD      HL,FNRDATA+0    ; the SSID, NUL-terminated
        LD      B,32
        CALL    SHOWSTR
```

C (from the c-demo, verbatim):

```c
    if (!fn_check()) {
        txt_puts(0, 2, "NO FUJINET CART");
        for (;;) ;
    }

    fn_begin(FN_DEV_FUJI, FUJI_GET_ADAPTERCONFIG_EXTENDED, 0);
    r = fn_commit(8);
    rx_home();
    if (r != FN_ERR_OK)     { txt_puts(0, 3, "ERR"); for (;;) ; }
    if (FN_REPLY != FN_ACK) { txt_puts(0, 3, "NAK"); for (;;) ; }

    rx_strn(buf, 0, 20);        /* ssid[33] at offset 0   */
    txt_puts(0, 4, buf);
    rx_strn(buf, 125, 15);      /* fn_version[15] at 125  */
    txt_puts(3, 5, buf);
    rx_strn(buf, 140, 16);      /* sLocalIP[16] at 140    */
    txt_puts(3, 6, buf);
```

Read the error paths as carefully as the happy one: **carry set** from commit means the cartridge never acknowledged (no cartridge, or the RP2040 never enumerated its ESP32); a **nonzero FNERR** means the transport under the cartridge failed (1 no link, 2 timeout, 3 bad frame, 4 too big); a **NAK** means everything carried perfectly and the FujiNet itself refused the command. Three layers, three bytes, three different remedies.

## The Z80 library

All five programs share one transport file, `fujilib.inc` (223 lines, byte-identical everywhere, vendored per-program so a client builds with no firmware checkout). Its routines:

| Routine | Contract |
|---|---|
| `FNREGWR` | write register: C = register, A = value; issues the REGSEL/REGDATA pair back to back |
| `FNTXBYT` | append A to the TX stream |
| `FNPARB` | append a 1-byte parameter (size byte 1, then A) |
| `FNTXSTR` | append the NUL-terminated string at HL (the NUL is **not** sent) |
| `FNBEGIN` | A = device, E = command, L = nparam; rewinds TX, writes the three registers |
| `FNCOMMIT` | B = timeout quanta; SEQ = ACKSEQ+1 wrap 255→1; carry on timeout, else A = FNERR with flags set |
| `FNSLICE` | A = slice 0–3; writes RXSLICE, polls `FNSECHO` until it echoes |
| `FNCHECK` | Z set if the `F`,`N` magic is painted |

The core of `FNCOMMIT` — the sequence rule in the flesh:

```asm
FNCOMMIT:
        LD      A,(FNACKSQ)
        INC     A
        JR      NZ,FNCMS
        INC     A               ; 255 wraps past the reserved 0
FNCMS:  LD      H,A             ; expected ACKSEQ
        LD      C,FRSEQ
        CALL    FNREGWR
FNCMO:  LD      DE,0            ; inner: 65536 polls, ~2 s at 1.789 MHz
FNCMI:  LD      A,(FNACKSQ)
        CP      H
        JR      Z,FNCMOK
        DEC     DE
        LD      A,D
        OR      E
        JR      NZ,FNCMI
        DJNZ    FNCMO
        SCF                     ; timed out
        RET
FNCMOK: LD      A,(FNERR)
        OR      A               ; clears carry
        RET
```

`state.inc` (54 lines, netcat + the games) folds the four slices into one flat 0–1023 space: `RXGETB` (offset in HL, one-byte slice cache), `RXGETW` (LE word), `RXSTRN` (bounded NUL-stopping copy). Because every transaction republishes slice 0, the round-trip code re-homes the cache to 0 after each commit.

**Building**: zmac 1.3, then pad to exactly 8,192 bytes, stamp `FUJI` at 0x1CFC, and enforce the layout with `checkrom.py` (size, 0x55 sentinel, claim present, nothing but zeros above 0x1B00). See any client's `build.sh`.

## C with Z88DK

No shipping Astrocade client is C — fujinet-lib has no Astrocade port and z88dk's `astrocde` target is marked *incomplete* (a correct crt0 and HVGLIB.H ship; the target C library does not). But the mailbox is nothing but memory reads, and the handbook's `listings/c-demo/` is a complete, working C client, verified end to end under MAME against a live fujinet-pc (`dev=70 cmd=C4 ... err=0 reply=06 rxlen=240`).

What makes the incomplete target usable:

1. a one-line `fputc_cons_native` stub (the classic runtime insists on a console driver; the demo paints screen RAM itself);
2. a tiny `port_out` in assembly (sccz80 has no port intrinsics here);
3. placement pragmas.

```sh
zcc +astrocde main.c text.c fujinet.c support.asm \
    -o build/cdemo.raw -m \
    -pragma-define:CRT_ENABLE_EIDI=1 \
    -pragma-define:REGISTER_SP=0x4fc0 \
    -pragma-define:CRT_ORG_BSS=0x4d00 \
    -pragma-define:CRT_MODEL=1
# then: pad to 8192, stamp FUJI at 0x1CFC, checkrom.py -- same as asm
```

`CRT_ENABLE_EIDI=1` runs `DI` before `main` (the mailbox contract); `CRT_MODEL=1` is the ROM model (initialized data copied to RAM at startup); BSS goes above the visible screen, the stack below the BIOS cells. The demo compiles to ~2.7K of the 6,912-byte budget.

The one idiom C needs — a hotspot "write" is a read whose address matters and whose result does not:

```c
static volatile unsigned char fn_sink;

#define FN_HOT(page, v) (fn_sink = (page)[v])

void fn_regwr(unsigned char reg, unsigned char val)
{
    FN_HOT(FN_REGSEL, reg);     /* arm the register    */
    FN_HOT(FN_REGDATA, val);    /* deliver the value   */
}
```

> **Compiler hazard, verified while building the demo:** sccz80 (z88dk `3bd06cad`, 2026-07) silently **miscompiles a constant subscript on a cast-constant pointer** — `FN_RDATA[2]` becomes the constant 2, not a memory read, with only a "value out of range" warning as the tell. Variable subscripts compile correctly, and so does a dereference of a constant sum. The demo's `fujinet.h` defines `FN_RDATA_B(i)` as `(*(volatile unsigned char *)(0x3b00 + (i)))` and uses it for every constant offset. Treat that warning as an error.

The rest of `fujinet.c` follows `fujilib.inc` line for line (`fn_begin`, `fn_commit`, `fn_slice`, `rx_getb/getw/strn`, then `net_open/close/status/read/write` in netcat's shape); `text.c` is CONFIG's byte-aligned 5×7 blitter in C (BIOS glyphs at 08E4H plus a lowercase table). A C timeout quantum runs a little longer than assembly's ~2 s; the counts above are already generous.

## The network device

Device `71H` is the first of eight network units (71H–78H). Give it a devicespec — `N:TELNET://BBS.FOZZTEXX.COM/`, `N:HTTPS://fujitzee.carr-designs.com/state?bin=1` — and it is a byte pipe with a status word. The scheme decides everything; the 28 schemes and their grammars are the [Network Protocol Handbook](FujiNet-Network-Protocol-Handbook)'s subject and apply here verbatim.

The lifecycle: OPEN (`4FH`) with mode and translation parameters and the devicespec payload — every client here uses mode 0CH (read/write; the same 12 performs GET on HTTP) and translation 0; STATUS (`53H`, two zero parameters) returning `avail lo, avail hi, connected, devstatus` (1 SUCCESS, 136 EOF); READ (`52H`, one 2-byte length parameter — capture `FNRXLL/FNRXLH` immediately); WRITE (`57H`, the count as a 2-byte parameter *and* implicitly as the payload length); CLOSE (`43H`).

Two different truth bits: the **games** gate rendering on `devstatus == 1` (an HTTP GET performs at read time, so an error page still has a readable body); **NETCAT** gates on `connected` (on a live socket EOF is a hangup, not an error).

**The three rules**, learned the hard way by every game client:

1. **CLOSE at the start of the next request, never after the read.** Every transaction repaints the whole reply window and a CLOSE reply is empty — the games render straight out of the reply window between polls. (NETCAT is the deliberate exception: it consumes each read immediately and holds its connection open.)
2. **The settle loop.** The ESP32 reports STATUS as soon as *some* of a response has arrived. Poll STATUS until two consecutive `avail` readings agree (bounded at 20, ~3 frames apart), then read. (NETCAT skips this: a live stream never settles.)
3. **Validate before believing (VALID8).** The reply window is never cleared. Check the captured length against the format's minimum, enums against ranges, counts against caps — then act.

The canonical round trip (battleship's `APICALL`, abridged):

```asm
APICALL: LD     (V_URL),A       ; which URL BLDURL builds
        CALL    NCLOSE          ; rule 1: the PREVIOUS connection
        CALL    NOPEN
        RET     C
        ...
        LD      B,20            ; rule 2: settle-loop bound
APSET:  CALL    NSTATUS
        ...                     ; poll until two avail readings agree
APRD:   CALL    NREAD
        JR      C,APCFL
        ; falls through into VALID8 -- rule 3
```

The `N:` device also speaks JSON channel mode (PARSE/QUERY), seek/tell, filesystem verbs, TCP server accept, and UDP addressing — see the [network command reference](#command-reference-the-network-device).

## The Fuji device

Device `70H` is the adapter itself; CONFIG is its natural habitat. The roads:

**WiFi**: `GET_WIFI_ENABLED` → `GET_WIFISTATUS` (3 = connected) → `GET_SSID` (97-byte reply); or `SCAN_NETWORKS` (count) + `GET_SCAN_RESULT` (index → `ssid[33]` + RSSI) + `SET_SSID`.

**The payload-shape rules** — the transaction layer's `transaction_get()` **fails a short read**, so:

- `OPEN_DIRECTORY` and `SET_DEVICE_FULLPATH` always send a full **256-byte NUL-padded** payload;
- `SET_SSID` sends **exactly 97 bytes** (`ssid[33] + password[64]`) and needs nparam ≥ 1 with the value ignored;
- `COPY_FILE` is the exception: its payload is read as a *string*, so exact length, no padding — and its host-slot parameters are **1-based**, alone in the family.

**Hosts and directories**: 8 host slots × 32 bytes — `READ_HOST_SLOTS` returns all 256, exactly slice 0. `MOUNT_HOST`, then `OPEN_DIRECTORY` / `SET_DIRECTORY_POSITION` (2-byte position) / `READ_DIR_ENTRY` (maxlen + flags; keep maxlen away from the magic 31) / `CLOSE_DIRECTORY`. Directory EOF is **exactly two 7FH bytes**; subdirectories arrive with a trailing `/`.

The idiom worth stealing from CONFIG (`hosts.inc`): to rename one host slot it does a fresh `READ_HOST_SLOTS`, then streams `WRITE_HOST_SLOTS`'s 256-byte payload **byte-for-byte out of the reply window itself**, substituting the edited slot in flight. No RAM mirror exists — with 4K of screen RAM total, the reply window *is* the state. The one rule: no transaction may run between the freshness read and the streamed write (CONFIG's editor is transaction-free by contract).

## Boot, swap, and banking

Picking a program from a network host and *becoming* it, in three acts:

**The push.** `SET_DEVICE_FULLPATH` (slot 0, host, mode 1, 256-padded path), then `MOUNT_IMAGE` — and while that transaction is still outstanding, the ESP32-S3 fetches the file and streams it to the RP2040 over a side channel: FujiBus frames to device 0FFH (DBC) — OPEN with a stream id and 32-bit size, WRITEs of sector-sized chunks, CLOSE to commit (CLOSE with a 1-byte payload aborts). Stream 0 is the ROM; stream 1, pushed first when present, is the `.cfg` sidecar. Your program watches `FNBSTAT` walk idle → transfer → ready (or 80H with the reason in `FNBERR`) and paints a progress bar from `FNBPCT`. Allow 60 quanta; passive reads only while it flies.

**The swap.** When ready: write BOOTLOCK (register 11H) = 0B5H, copy the stub to screen RAM, jump to it:

```asm
BREADY: LD      C,FRBOOTL
        LD      A,FNBLMAG       ; 0B5H
        CALL    FNREGWR         ; arm the trigger
        LD      HL,BSTUB
        LD      DE,STUB         ; STUB EQU 4FE0H: top of screen RAM
        LD      BC,BSTUBL
        LDIR
        JP      STUB
BSTUB:  LD      A,(FNSWAP)      ; 3DFEH: the cart flips between this
        JP      0               ; read and the next fetch
BSTUBL  EQU     $-BSTUB
```

The stub must run from RAM — the swap replaces every byte of the cartridge window, including the code that triggers it. `JP 0` cold-starts the OS, which walks the new image's 55H menu header.

**After.** A claimed image keeps the mailbox alive; an ordinary game image goes dark for the session and behaves exactly like a real cartridge, RESET included.

**Banking (protocol v2)** — two schemes, mutually exclusive by construction:

- **GAME** (mailbox dead): claim-less images of exactly 256K/512K use the established homebrew mapper, byte-compatible with MAME's `rom_256k`/`rom_512k`. 2000H–2FFFH is fixed to the last 4K bank; a read in 3FC0H–3FFFH (256K; 3F80H+ for 512K) selects `address & mask` and returns the bank number as the data byte. Those hotspots live inside the FNDATA page — which is exactly why game banking requires the mailbox dead.
- **APPBANK** (mailbox fully live): claimed images of 8K + k×4K, up to 112 extra pages. One read at `3D80H+page` maps image page 0–111 into 2000H–2FFFH; the high half never moves. The select completes before the next read; the byte returned is undefined. Never execute from the low half while switching away from the page the PC is in, and stamp every page with the 7-byte sentinel header whose start vector re-selects page 0 (`tools/mkbanked.py` does) — console RESET cannot restore page 0, because the cartridge never hears RESET.

## Command reference: the Fuji device

Everything device `70H` answers on this platform, from the firmware dispatch tables (`fujiDevice.cpp`, its four mixins, and the RS232 fall-through). A *byte* parameter is size-1, a *word* size-2 little-endian.

### WiFi and adapter

| Command | Code | nparam | Params / payload | Reply |
|---|---|---|---|---|
| RESET | `FF` | 0 | — | ACK, then the adapter reboots |
| GET_WIFI_ENABLED | `EA` | 0 | — | 1 byte: 1 = enabled |
| GET_WIFISTATUS | `FA` | 0 | — | 1 byte: 3 = connected |
| GET_SSID | `FE` | 0 | — | 97 bytes: `ssid[33]+password[64]` |
| SCAN_NETWORKS | `FD` | 0 | — | 1 byte: count |
| GET_SCAN_RESULT | `FC` | 1 | byte: index | 34 bytes: `ssid[33]` + RSSI (negative dBm) |
| SET_SSID | `FB` | 1 | byte (ignored); payload exactly 97 bytes | ACK on join |
| GET_ADAPTERCONFIG | `E8` | 0 | — | 140 bytes, binary addresses |
| GET_ADAPTERCONFIG_EXTENDED | `C4` | 0 | — | 240 bytes; text IP at 140, version at 125 |
| STATUS | `53` | 1 | byte: 0 conn-err, 1 mount times, 2 netmask, 3 gateway, 4 DNS | type 1: per-slot mount times; others 4 zero bytes |
| DEVICE_READY | `00` | 0 | — | 512 bytes of `A` — the bus test card |

### Hosts, slots, mounting

| Command | Code | nparam | Params / payload | Reply |
|---|---|---|---|---|
| READ_HOST_SLOTS | `F4` | 0 | — | 256 bytes: 8 × `hostname[32]` |
| WRITE_HOST_SLOTS | `F3` | 0 | payload: all 256 bytes | ACK |
| MOUNT_HOST | `F9` | 1 | byte: slot (0-based) | ACK |
| UNMOUNT_HOST | `E6` | 1 | byte: slot | ACK |
| SET/GET_HOST_PREFIX | `E1/E0` | 1 | byte: slot (+ prefix payload on SET) | GET: the prefix |
| READ_DEVICE_SLOTS | `F2` | 0 | — | 38 bytes per slot: host, mode, `filename[36]` |
| WRITE_DEVICE_SLOTS | `F1` | 0 | payload: the table | ACK |
| SET_DEVICE_FULLPATH | `E2` | 3 | bytes: device slot, host, mode; payload 256-padded path | ACK |
| GET_DEVICE_FULLPATH | `DA` | 1 | byte: device slot | the path |
| MOUNT_IMAGE | `F8` | 2 | bytes: device slot, mode (1 R, 2 W) | ACK; on this platform the ROM push rides inside it |
| UNMOUNT_IMAGE | `E9` | 1 | byte: device slot | ACK |
| MOUNT_ALL | `D7` | 0 | — | ACK |
| NEW_DISK | `E7` | 0 | payload 262 bytes: sectors (word), sector size (word), host, device, `filename[256]` | ACK |
| SET_BOOT_MODE | `D6` | 1 | byte: mode | ACK |
| CONFIG_BOOT | `D9` | 1 | byte | ACK — CONFIG deliberately never sends it |

### Directories and files

| Command | Code | nparam | Params / payload | Reply |
|---|---|---|---|---|
| OPEN_DIRECTORY | `F7` | 1 | byte: host; payload path + NUL + filter, 256-padded | ACK |
| READ_DIR_ENTRY | `F6` | 2 | bytes: maxlen (≠ 31!), flags (0) | name (+ `/` on dirs); EOF = `7F 7F` |
| SET_DIRECTORY_POSITION | `E4` | 1 | word: index | ACK |
| GET_DIRECTORY_POSITION | `E5` | 0 | — | word |
| CLOSE_DIRECTORY | `F5` | 0 | — | ACK |
| COPY_FILE | `D8` | 2 | bytes: src host, dst host (**1-based**); payload `src\|dst`, exact length | ACK |

### App keys, utilities

| Command | Code | nparam | Params / payload | Reply |
|---|---|---|---|---|
| OPEN_APPKEY | `DC` | 0 | payload 6 bytes: creator (word), app, key, mode (0 R / 1 W), reserved | ACK (NAK without SD) |
| READ_APPKEY | `DD` | 0 | — | 64 bytes |
| WRITE_APPKEY | `DE` | 0 | payload: the value, ≤ 64 bytes | ACK |
| CLOSE_APPKEY | `DB` | 0 | — | ACK |
| RANDOM_NUMBER | `D3` | 0 | — | 4 bytes, LE |
| GENERATE_GUID | `BB` | 0 | — | 37 bytes: UUID text + NUL |
| BASE64_ENCODE INPUT/COMPUTE/LENGTH/OUTPUT | `D0/CF/CE/CD` | 1/0/0/1 | INPUT: word count + payload; OUTPUT: word count | LENGTH: 4-byte size; OUTPUT: the text |
| BASE64_DECODE ... | `CC/CB/CA/C9` | same | same | decoded bytes |
| HASH INPUT/COMPUTE/NO_CLEAR/LENGTH/OUTPUT/CLEAR | `C8/C7/C3/C6/C5/C2` | 1 (CLEAR 0) | COMPUTE: byte algorithm 0 MD5, 1 SHA1, 2 SHA256, 3 SHA512, 4 SHA224, 5 SHA384; LENGTH/OUTPUT: byte 1 = hex | the digest |
| QR INPUT/ENCODE/LENGTH/OUTPUT | `BC/BD/BE/BF` | 1/3/1/1 | ENCODE: version, ECC 0–3, shorten flag | LENGTH: 4-byte size; OUTPUT: the module bitmap |

**Answered with a NAK on this platform**: ENABLE_UDPSTREAM (F0), SET_BAUDRATE (EB), SET_HSIO_INDEX (E3), SET_SIO_EXTERNAL_CLOCK (DF), ENABLE/DISABLE_DEVICE (D5/D4), GET_TIME (D2), DEVICE_ENABLE_STATUS (D1), GET_HEAP (C1), GET_DEVICE1–10_FULLPATH (A0–A9), UPDATE_FIRMWARE (90), HSIO_INDEX (3F), SEND_ERROR/SEND_RESPONSE (02/01).

## Command reference: the network device

Everything devices `71H`–`78H` answer, from `lib/device/rs232/network.cpp`. Most opcodes are the ASCII letter of their name.

| Command | Code | nparam | Params / payload | Notes |
|---|---|---|---|---|
| NET_OPEN | `4F 'O'` | 2 | bytes: mode, translation; payload devicespec | modes: 4 R, 8 W, 12 R/W (= HTTP GET, deferred to first READ), 13 POST, 14 PUT, 5 DELETE, 6 HEAD; translation 0 none, 1 CR, 2 LF, 3 CR/LF |
| NET_CLOSE | `43 'C'` | 0 | — | rule 1: send at the start of the *next* request |
| NET_READ | `52 'R'` | 1 | word: count | capture RXLEN immediately |
| NET_WRITE | `57 'W'` | 1 | word: count; payload the bytes | count rides twice |
| NET_STATUS | `53 'S'` | 2 | two zero bytes | reply: avail lo/hi, connected, devstatus (1 OK, 136 EOF) |
| NET_SET_CHANNEL_MODE | `4D 'M'` | 2 | bytes: 0, then mode (0 raw, 1 JSON) | on HTTP-family connections |
| NET_PARSE | `50 'P'` | 0 | — | JSON mode: parse the body |
| NET_QUERY | `51 'Q'` | 0 | payload: e.g. `N:/players/0/name` | then READ the result |
| NET_SEEK / NET_TELL | `25 '%'` / `26 '&'` | 1 / 0 | SEEK: 4-byte offset | TELL replies 4 bytes |
| NET_RENAME / DELETE / LOCK / UNLOCK | `20 / 21 / 23 / 24` | 0 | payload: target (RENAME: `old,new`) | filesystem protocols |
| NET_MKDIR / RMDIR / CHDIR / GETCWD | `2A / 2B / 2C / 30` | 0 | payload: path | GETCWD replies the path |
| NET_CONTROL / NET_CLOSE_CLIENT | `41 'A'` / `63 'c'` | 0 | — | TCP server: accept / drop client |
| NET_GET_REMOTE / NET_SET_DESTINATION | `72 'r'` / `44 'D'` | 0 | SET: payload `host:port` | UDP addressing |
| NET_USERNAME / NET_PASSWORD | `FD / FE` | 0 | payload: the credential | before OPEN on FTP/SSH/SMB |
| NET_TRANSLATION | `54 'T'` | 2 | bytes: 0, then code | change EOL translation after OPEN |
| NET_SET_EOL | `4C 'L'` | 2 | bytes: the pair; first 0 clears | custom terminators |
| NET_SET_INT_RATE | `5A 'Z'` | 2 | bytes: 0, then rate | irrelevant on a polled bus |

**NAK on this platform**: NET_GET_DSTATS_VALUE (FF), NET_CHANNEL_MODE getter (FC), NET_SET_PARAMETERS (FB), NET_SET_CHANNEL (FA), NET_SET_HSIO_INDEX (E3), NET_QUERY_ALT/PARSE_ALT (81/80), NET_GET_ERROR (45 — read the STATUS devstatus byte instead), NET_HSIO_INDEX (3F).

## The five programs

Full explanations with architecture walkthroughs and complete listings are in the PDF handbook; each repository's `astrocade/` directory carries the build system (zmac 1.3 → 8K cartridge image), MAME smoke tests, and a README.

### NETCAT — [github.com/FujiNetWIFI/netcat](https://github.com/FujiNetWIFI/netcat)

The family's terminal: opens any `N:` devicespec (default `N:TELNET://BBS.FOZZTEXX.COM/`) and pumps bytes between the connection and a scrolling 40×13 pane. Three firsts: holds a connection open, sends N: WRITE, scrolls (an `LDIR`, ~34 ms/line — no scroll register on this hardware). A 96-glyph lowercase 4×6 font, a 32×3 grid keyboard overlay with a 160-byte character shadow, and a compose-line editor. Its session loop gates on `connected` and deliberately skips the settle loop. 2,144 lines; 3,181 bytes of ROM.

### TEXAS HOLD'EM — [github.com/tschak909/fujinet-texasHoldEm](https://github.com/tschak909/fujinet-texasHoldEm)

Live multiplayer poker at `th.carr-designs.com`, cross-play with the whole FujiNet family. The server owns the rules: every legal move arrives over the wire with its label (`?bin=1` binary state, offsets documented in `fujinet.inc`). The simplest poll loop in the family, with one elegant trick — a staged move rides the next request, whose reply *is* the new state. 40×15 text over 160×90@2bpp, cards on an 8-pixel pitch, `DEMO=1` mock-table build. 2,977 lines; 4,607 bytes.

### BATTLESHIP — [github.com/FujiNetWIFI/fujinet-battleship](https://github.com/FujiNetWIFI/fujinet-battleship)

Up to four players at `battleship.carr-designs.com`; four 10×10 quadrants of 4×4-pixel cells (one byte per cell row — nothing ever shifts), 19 byte-columns of panel. `?bin=1&v=2` wire format (v2 is mandatory: v1 hides the winner). The `PENDACT` staged-action machine (state/ready/place/attack), per-poll turn-edge detection, ship placement with local overlap rejection, time-sliced targeting painted on every live enemy quadrant, and a 16-bit Galois LFSR with R folded into the output only. 3,354 lines; 5,598 bytes.

### FUJITZEE — [github.com/FujiNetWIFI/fujinet-fujitzee](https://github.com/FujiNetWIFI/fujinet-fujitzee)

Dice at `fujitzee.carr-designs.com`. The server computes `validScores[15]` — the exact points every open row would earn with the current dice — so the client renders choices, never rules. Procedural dice (three 3-bit pip masks per face: 18 bytes for all six), roll-edge detection (only a *decrease* in `rollsLeft` means dice landed), and the family's first use of the noise generator for the dice-cup rattle. The tightest ROM in the family: 3,746 lines; 6,070 of 6,912 bytes.

### CONFIG — [github.com/FujiNetWIFI/fujinet-config](https://github.com/FujiNetWIFI/fujinet-config)

The cartridge's own boot ROM (`make rom.h` packs it into the RP2040 firmware), and the only client that speaks to device 70H. WiFi setup with an on-screen password keyboard (own lowercase glyphs beside the BIOS font), eight host slots with rename, a stateless directory browser with paging and filters, host-to-host COPY_FILE, an info screen, and the network-boot road with a progress bar. Its editor is transaction-free by contract so the reply window survives an edit (`HWRITE` streams WRITE_HOST_SLOTS straight out of the READ_HOST_SLOTS reply). 2,859 lines; 5,501 bytes.

## Error and status codes

**FNERR (3C02H)** — 0 OK · 1 NOLINK (ESP32 not enumerated) · 2 TIMEOUT · 3 BADFRAME (SLIP/checksum) · 4 TOOBIG (reply over 1,024).

**FNREPLY (3C03H)** — 06H ACK · 15H NAK (the FujiNet refused the command).

**FNBSTAT (3C06H)** — 0 idle · 1 transfer (watch FNBPCT) · 2 ready (arm BOOTLOCK and swap) · 80H failed.

**FNBERR (3C08H)** — 1 TOOBIG · 2 TRUNCATED · 3 NOMAP (size fits no mapping) · 4 STOREBUSY.

**NET_STATUS devstatus** — 1 SUCCESS · 136 END_OF_FILE · others per-protocol (see the Network Protocol Handbook).

**GET_WIFISTATUS** — 3 connected · 6 disconnected · others transitional.

---

*The FujiNet Professional Arcade Programmers Handbook — wiki edition. The PDF and this page are kept in sync by hand; when in doubt, the firmware sources win.*
