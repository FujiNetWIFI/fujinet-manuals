#import "../lib.typ": *
= C and fujinet-lib <ch-c>

A C program for the FujiNet 5200 is an ordinary cc65 program with three things added: MekkoGX’s start-up code and linker configuration in place of cc65’s, fujinet-lib for the FujiNet, and a check after the link. The C library is cc65’s own `atari5200` one, unchanged.

#sect[The start-up code]

cc65’s own start-up for the 5200 expects the BIOS to have run first, and a FujiNet program tells the BIOS not to (`$BFFD` = `$FF`). MekkoGX’s `atari5200-crt0.s` does the BIOS’s work itself:

#nsteps(
  [Interrupts and DMA off, the chip registers cleared, the stack set.],
  [The vectors at `$0200`–`$021B` filled with handlers that do what the BIOS’s do: a VBI that counts frames in `RTCLOK` and copies the display, colour and pot shadows; a keypad handler (@ch-pads).],
  [A blank display list, so the screen is quiet until the program sets its own.],
  [cc65’s own initialisation: the data copied from ROM, the BSS cleared, the constructors run.],
  [`main()`.],
)

It also lays down the claim and the BIOS header, so a C program never writes them. Because the zero page and vectors are the BIOS’s layout, cc65’s console, joystick driver and clock work as they would under the BIOS.

#sect[The linker configuration]

#tbl((auto, auto, 1fr),
  th[Area], th[Where], th[What goes there],
  [`ZP`], [`$1D`–`$FF`], [cc65’s zero page and yours.],
  [`RAM`], [`$021C` up], [`DATA` (copied from ROM at start-up), `BSS`, the heap.],
  [`STACK`], [1K under the reserve], [The C stack.],
  [`ROM`], [`$4000`–`$AFFF`], [Code, read-only data, display lists (`DLIST`, 1K-aligned).],
  [`ARENA`], [`$B000`–`$B7FF`], [Nothing: filled with `$FF`; the cartridge serves the mailbox here.],
  [`ROM2`], [`$B800`–`$BFDF`], [Fonts (`FONT`, 1K-aligned) and anything else that fits.],
  [`CLAIM`, `HDR`], [`$BFE0`–`$BFFF`], [The claim and the header, from the start-up code.],
)

`__RESERVED_MEMORY__` takes room off the top of RAM for screens. This handbook’s C programs reserve 1K for the screen at `$3C00`.

#sect[The checker]

`atari5200-romstamp.py` reads the image and the linker’s map, and refuses an image that is the wrong size, lacks the claim, `$02` at `$BFE7`, `$FF` at `$BFFD` or a start address, stores into the cartridge window, uses a read-modify-write instruction there, reads a hotspot page with an index from a base that is not page-aligned, or uses `JMP ($xxFF)`. This handbook’s build runs `checkrom.py` as well, which checks the same rules from the bring-up’s side.

#sect[What the library gives you]

Everything in `fujinet-fuji.h`, `fujinet-network.h` and `fujinet-clock.h` works as it does on every FujiNet computer: `fuji_get_adapter_config_extended()`, `network_open()`, `fuji_read_appkey()` and the rest. `fujinet-atari5200.h` adds what only a 5200 needs:

#tbl((1.15fr, 1fr),
  th[Call], th[What it does],
  [`fuji_a5200_present()`], [True if a FujiNet cartridge answers, with a protocol the library knows.],
  [`fuji_a5200_boot_state()`, `_percent()`, `_error()`, `_got()`, `_total()`], [The progress of an image being pushed (@ch-boot).],
  [`fuji_a5200_boot()`], [Hands the console to the pushed image. Returns false only if the cartridge never armed it.],
  [`fuji_a5200_config()`], [Hands the console back to CONFIG.],
  [`fuji_a5200_mode()`, `fuji_a5200_staged()`], [What the cartridge is serving, and what it has been pushed.],
  [`fuji_a5200_key`], [The last keypad key + 1, 0 for none (@ch-pads).],
  [`fn_default_timeout`], [Seconds to wait for an ordinary command; the library waits longer for the commands the cartridge gives longer.],
  [`fn_device_error`], [Why the last call failed: the cartridge’s error, `$FF` if it never answered, 144 for a NAK.],
)

#sect[Below the library]

For a command with no wrapper, `fuji_bus_call()` takes the device, the command, which of four one-byte parameters and a payload or reply buffer to use, and does the whole transaction. GET_ISO_LOCAL on the clock device, for example, takes nothing and answers with text:

#pair(none,
"if (!fuji_bus_call(0x45, 0x49, FUJI_FIELD_REPLY,
                   0, 0, 0, 0, when, sizeof when))
    failed();
mt_text((char *)when, 25);")

Below that is the bus layer itself, `fujinet-bus-atari5200.h`: `fn_regwr()` writes a register, `fn_tx()` appends a byte, and `fn_commit()` launches and waits, returning the cartridge’s error or `FN_EWAIT`. The reply is `FN_REPLY` and the status page has a name for every field. This is the recipe of @ch-mailbox, a step at a time:

#pair(none,
"fn_regwr(FNR_DATA_RST, 0);
fn_regwr(FNR_DEVICE, 0x70);      /* FUJI */
fn_regwr(FNR_CMD, 0xC4);         /* GET_ADAPTERCONFIG_EXTENDED */
fn_regwr(FNR_NPARAM, 0);
if (fn_commit() != FN_OK || FN_REPLYCMD != 0x06)
    failed();
for (n = 0; n < 16 && FN_REPLY[140 + n]; ++n)
    mt_put(FN_REPLY[140 + n]);   /* the IP address, as text */")

#sect[Rules for C]

- *Touch the hotspot pages only through `fn_regwr()` and `fn_tx()`.* They are assembly, so each byte is exactly one `LDA` from a page-aligned base. A C expression that reads `$B700`+_b_ may compile to `(zp),Y`, or read twice.
- *Never assign to an address in `$4000`–`$BFFF`.* There is nothing there to write, and the cartridge drives the bus against you.
- *Switch Super Cart banks in assembly.* A bank is chosen by reading a hotspot, and cc65’s optimiser drops a read whose value is unused, even an inline `lda`. Use a `bit` in an assembly file (@ch-banks).
- *Spell out CR and LF.* cc65’s Atari targets compile `'\n'` as `$9B`, the Atari’s end-of-line, not 10. Text from the network uses `0x0D` and `0x0A`.
- *Reserve the screens you use*, with `__RESERVED_MEMORY__` (@ch-display).

#sect[Building]

`listings/c/build.sh` compiles each program, links it with MekkoGX’s start-up code first on the line (so it, not cc65’s, is the start-up), `antic.c`, and the library, then runs both checkers:

```
cd listings/c
FNLIB=~/fujinet-lib MEKKO=~/MekkoGX/mekkogx ./build.sh netget
```

A project built the MekkoGX way gets the same from `make atari5200`, which reads `platforms/atari5200.mk`. That is how the games are built (@ch-bs).
