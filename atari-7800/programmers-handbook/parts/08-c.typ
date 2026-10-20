#import "../lib.typ": *
= C and fujinet-lib

#ini[T]he library every FujiNet C program uses, on every computer the FujiNet serves, is fujinet-lib: the same `fuji_get_adapter_config_extended()`, the same `network_open()`, whatever is underneath. Its `atari7800` target puts the mailbox underneath, and brings the start-up code, linker configuration and checker a 7800 program needs. A C program for the FujiNet cartridge is an ordinary cc65 program with three things swapped in.

#sect[What the target brings]

#tbl((auto, 1fr),
  th[File], th[What it does],
  [`bus/atari7800/crt0.s`], [Start-up, in place of cc65’s. It never stores to `$00`–`$1F` (cc65’s locks INPTCTRL), turns MARIA’s DMA off, sets both stacks, clears `BSS`, copies `DATA` into RAM, and points the NMI vector at a trampoline in RAM. It also carries the claim, with the RAM flag set.],
  [`makefiles/atari7800-fujinet.cfg`], [The linker configuration: 32K of ROM at `$8000`, the cartridge’s 16K of RAM at `$4000`.],
  [`makefiles/atari7800-romstamp.py`], [The checker: claim, vectors, no read-modify-write on the mailbox, no store to the TIA (Section 3).],
  [`bus/atari7800/fujinet-bus-atari7800.c`], [The transport: register writes, the TX stream, the wait.],
  [`include/fujinet-atari7800.h`], [What only a 7800 has: the cartridge’s mode, the boot, the TV standard, INPTCTRL, the High Score Cart.],
)

#tbl((auto, auto, 1fr),
  th[Memory], th[Where], th[What],
  [`ZP`], [`$40`–`$FF`], [cc65’s zero-page registers and the program’s `ZEROPAGE`.],
  [`CONSOLE`], [`$1800`–`$203F`], [The console’s RAM, for anything placed there by name (`#pragma bss-name`).],
  [`CRAM`], [`$4000`–`$77FF`], [`VIDEO` (page-aligned: the tile engine’s map and lists), `DATA`, `BSS`, the heap.],
  [`STACK`], [`$7800`–`$7FFF`], [cc65’s parameter stack, 2K.],
  [`ROM`], [`$8000`–`$FF6F`], [`TILES` (page-aligned, for `CHARBASE`), code, read-only data.],
  [`CLAIM`, `VEC`], [`$FF70`, `$FFF8`], [Filled by `crt0.s`.],
)

First Contact, built this way, uses 2K of tiles, 3K of code and 4.6K of the cartridge’s RAM for the tile engine. Most of the 32K is still free.

#sect[Calling the FujiNet]

The calls are fujinet-lib’s usual ones, and they behave the usual way: `true` for success, or `FN_ERR_OK` for the network and clock calls. On the 7800, most `fuji_*` calls are macros over one function, `fuji_bus_call()`, which writes the registers and TX stream, waits, and copies the reply into the buffer you gave it.

#tbl((auto, 1fr),
  th[Header], th[Calls],
  [`fujinet-fuji.h`], [The adapter, WiFi, host and device slots, directories, mounting, appkeys, hashing, Base64, GUIDs.],
  [`fujinet-network.h`], [The N: device: open, status, read, write, close, JSON, HTTP headers and POST, UDP.],
  [`fujinet-clock.h`], [The clock, in seven formats, and the time zone.],
  [`fujinet-atari7800.h`], [The cartridge itself (below).],
)

The library waits as long as the cartridge allows each call, plus a second: 15 seconds by default (`fn_default_timeout`), 61 for MOUNT_IMAGE and COPY_FILE, 91 for the network device’s OPEN, STATUS, READ and CLOSE. It counts vertical blanks, so the display does not change the timing. When a call fails, `fn_device_error` says why: the cartridge’s error (Section 4), `0xFF` if the cartridge never answered, or 144 if the FujiNet said no.

#sect[The 7800’s own calls]

#tbl((auto, 1fr),
  th[Call], th[What it does],
  [`fuji_a7800_present()`], [True if a FujiNet cartridge answers (the magic bytes).],
  [`fuji_a7800_mode()`], [`FUJI_A7800_MODE_BOOT`, `_LOAD`, `_GAME` or `_APP`.],
  [`fuji_a7800_boot_state()`, `_percent()`, `_error()`, `_got()`, `_total()`], [A pushed image’s progress (Section 12).],
  [`fuji_a7800_staged()`], [What the push left: ready, claimed, BIOS-OK, an HSC ROM.],
  [`fuji_a7800_boot()`], [Interrupts, DMA and POKEY off, joystick ports back to inputs, then into the loader to start the pushed image. Does not return.],
  [`fuji_a7800_config()`], [The same, back to CONFIG.],
  [`fuji_a7800_handover()`], [How the last image was started: by the BIOS or by the loader.],
  [`fuji_a7800_tv()`, `_set_tv()`, `_detect_tv()`], [The TV standard the cartridge believes; set it; or count MARIA’s lines (two frames) and tell it.],
  [`fuji_a7800_inptctrl()`, `_inpt_locked()`], [The cartridge’s model of INPTCTRL.],
  [`fuji_a7800_hsc()`, `_hsc_op()`], [The High Score Cart (Section 13).],
  [`fuji_a7800_nmi`], [Three bytes of RAM, `JMP` to the NMI handler. Store your handler’s address in bytes 1–2.],
)

#sect[Underneath: the bus layer]

The bus header, `fujinet-bus-atari7800.h`, is also a public interface; CONFIG uses it. It names every cell of the status page (`FN_ACKSEQ`, `FN_ERRCODE`, `FN_REPLYCMD`, `FN_BOOTSTAT`…), the reply (`FN_REPLY`), and the registers (`FNR_DEVICE`…), and it has three functions:

- `fn_regwr(reg, value)` — one register write, one `STA`;
- `fn_tx(byte)` — one byte into the TX stream;
- `fn_commit()` — launch with `ACKSEQ`+1 and wait; returns the cartridge’s error or `FN_EWAIT`.

With these, a C program can send a command fujinet-lib has no call for, or read a reply in place instead of copying it. Section 4’s recipe is written this way, and the command reference shows the lower road wherever the library has no wrapper. For any command, `fuji_bus_call()` is the general form:

```
fuji_bus_call(FUJI_DEVICEID_FUJINET, FUJICMD_GET_ADAPTERCONFIG_EXTENDED,
              FUJI_FIELD_REPLY, 0, 0, 0, 0, &ac, sizeof ac);
```

The third argument says what the call carries: `FUJI_FIELD_A1` up to `_A1_A2_A3_A4` for one to four one-byte parameters, `_B12` for one two-byte parameter (aux 1 and 2), `_B12_B34` for two, and `FUJI_FIELD_DATA` for a payload or `FUJI_FIELD_REPLY` for a reply in the buffer.

#sect[Rules]

#steps(
  [*No TIA.* Leave out cc65’s TIA sound, and do not call `clock()` or use conio: they drag in cc65’s own start-up code, which locks INPTCTRL, and the link fails. Make sound with the cartridge’s POKEY at `$0450`.],
  [*No read-modify-write on the mailbox.* Never `++`, `--`, `|=` or `&=` a mailbox cell; the romstamp refuses the program if you do.],
  [*Paths are 256 bytes.* `fuji_open_directory()` and `fuji_set_device_filename()` send exactly 256 bytes from the pointer you give them. Give them a 256-byte buffer, not a string literal.],
  [*A reply is the size of its buffer.* `fuji_read_appkey()` needs two bytes more than the key; read the header comment of any call you use.],
)

#sect[Building]

`listings/c/build.sh` compiles a program with `-t atari7800 -O`, the library’s two include directories and the tile engine, links it with the library’s configuration, then runs the romstamp, `checkrom.py` and `mka78.py`:

```
cd listings/c
FNLIB=~/fujinet-lib-experimental ./build.sh acfg
```

#ex((path: "listings/c/build.sh", from: "for p in", to: "done"), "SHELL")

A program bigger than 32K needs its own linker configuration, and its own claim; Section 14 builds one.
