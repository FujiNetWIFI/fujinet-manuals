#import "../lib.typ": *
= The Memory Map

#ini[T]he 7800 gives a cartridge all of `$4000`–`$FFFF`, and the FujiNet cartridge gives nearly all of that to your program. Its own business happens lower down, in space the console's design leaves to the cartridge and no other cartridge ever used: a 512-byte loader at `$0600`, and the mailbox from `$0800` to `$0FFF`.

#fig(memmap((
  (0x0000, 0x001F, "TIA", tint-c, [INPTCTRL is `$01`]),
  (0x0020, 0x003F, "MARIA", tint-c, [display, palettes, `CTRL`]),
  (0x0040, 0x00FF, "zero page", tint-d, [RAM, shared with `$2040`]),
  (0x0140, 0x01FF, "stack", tint-d, [RAM, shared with `$2140`]),
  (0x0280, 0x02FF, "RIOT", tint-c, [joysticks, switches]),
  (0x0450, 0x045F, "POKEY", tint-a, [the cartridge's sound]),
  (0x0600, 0x07FF, "loader", tint-a, [512 bytes, cartridge-served]),
  (0x0800, 0x0BFF, "reply", tint-a, [1K, read]),
  (0x0C00, 0x0CFF, "status", tint-a, [read]),
  (0x0D00, 0x0DFF, "registers", tint-b, [write]),
  (0x0E00, 0x0EFF, "(unused)", white, []),
  (0x0F00, 0x0FFF, "TX stream", tint-b, [write]),
  (0x1000, 0x17FF, "HSC RAM", panel, [when a High Score Cart is on]),
  (0x1800, 0x27FF, "console RAM", tint-d, [4K]),
  (0x3000, 0x3FFF, "HSC ROM", panel, [when a High Score Cart is on]),
  (0x4000, 0x7FFF, "cart RAM / ROM", tint-a, [16K RAM if the claim asks]),
  (0x8000, 0xFFFF, "program", tint-a, [ROM; claim at `$FF70`]),
), scale: 0.0011pt, minh: 13pt), caption: [The 7800 as a FujiNet program sees it. Magenta tints are the cartridge's; blue tints are pages it only listens to.])

The console's own pieces are the usual ones. TIA and MARIA share the bottom page. The 4K of RAM at `$1800`–`$27FF` is also seen at `$0040`–`$00FF` (the zero page) and `$0140`–`$01FF` (the stack). The RIOT's joystick and switch ports sit at `$0280`.

#sect[Four modes]

The cartridge serves different things at different times. The status page at `$0C12` says which mode it is in.

#tbl((auto, 1fr, 1fr, 1fr, 1fr),
  th[Range], th[BOOT (0)], th[LOAD (1)], th[GAME (2)], th[APP (3)],
  [`$0450`], [—], [—], [POKEY, if the game has one], [POKEY],
  [`$0600`], [loader], [loader], [—], [loader],
  [`$0800`–`$0FFF`], [mailbox], [mailbox], [—], [mailbox],
  [`$4000`–`$7FFF`], [—], [the load window], [as the board maps it], [as the board maps it; RAM if claimed],
  [`$8000`–`$EFFF`], [—], [—], [the image], [the image],
  [`$F000`–`$FFFF`], [signed boot block], [—], [the image], [the image],
)

- *BOOT* is power-on. The cartridge serves a 4K block the console's BIOS can verify; the block jumps to the loader.
- *LOAD* is the loader filling the cartridge's RAM, one 1K slice at a time, through the window at `$4000`.
- *GAME* is an ordinary 7800 cartridge: an image in the RAM, laid out as its own board would lay it out, and the mailbox gone. Nothing the game does can disturb the FujiNet.
- *APP* is a FujiNet program. The image runs exactly as a game would, but the loader and the mailbox stay where they are.

What separates GAME from APP is ten bytes in the program.

#sect[The claim]

A program that wants the mailbox says so at `$FF70`, just below the area the BIOS's signature check uses:

#bytefield(([`F`], 22pt), ([`U`], 22pt), ([`J`], 22pt), ([`I`], 22pt), ([ver 1], 32pt), ([kind+1], 40pt), ([flags], 34pt), ([0], 18pt), ([0], 18pt), ([0], 18pt))

- *Version* is 1.
- *Kind* names the board layout the image wants, plus one; 0 lets the cartridge decide. A program bigger than 48K says which bank scheme it uses here (Section 14).
- *Flags* bit 0 asks for 16K of cartridge RAM at `$4000`–`$7FFF`. fujinet-lib's C programs keep their variables and stack there; the bring-up's assembly programs keep their screen there.

The cartridge looks for the claim when it loads an image. If it is there, the image runs in APP mode, every FujiNet program may play sounds through the cartridge's POKEY at `$0450`, and the mailbox stays.

#note[The claim is all it takes. The same cartridge runs a commercial game and a FujiNet program the same way; the only difference is whether the program asked to keep the mailbox.]

#sect[The image]

An image is a whole number of kilobytes, laid so that it ends at `$FFFF`: a 32K program occupies `$8000`–`$FFFF`. Its reset vector must point at `$4000` or above. MAME wants the 128-byte `.a78` header in front; the cartridge takes either and strips the header.

How the cartridge maps a bigger image depends on what it can learn about it, in this order: a database of every known 7800 game by CRC; a `mapper=` line in a `.cfg` file beside the image; the `.a78` header's cartridge type; and the image's size. The claim's kind byte, when it is not 0, overrides all but the first two. Section 12 lists the ten board layouts.

#sect[No reset line]

The 7800’s cartridge edge carries the address and data buses, R/W, the clock, HALT, an interrupt line and audio. It has no reset. The console's RESET switch is a bit in `SWCHB` that your program reads. The cartridge notices only a power cycle (the clock stopping for 50 milliseconds), and then it goes back to BOOT and serves the boot block.

A program therefore cannot assume anything about the cartridge's state when it starts, except that it is in APP mode and its mailbox works. In particular, the sequence number in the status page survives a power cycle of the console, because the cartridge was not reset; Section 4 explains why that matters.

#sect[What every program must not do]

#steps(
  [*Never store to `$00`–`$1F` or its mirrors* until you mean to lock INPTCTRL. Until the first write that locks it, every store to the TIA's range rewrites INPTCTRL, which can switch off MARIA or switch the BIOS back on. A locked INPTCTRL also stops the cartridge from handing a game to the console's BIOS later (Section 12). So a FujiNet program plays its sound through the cartridge's POKEY, uses MARIA's `WSYNC` at `$24`, and leaves INPTCTRL alone. Reading the TIA's input ports is fine.],
  [*Never use a read-modify-write instruction on `$0D00`–`$0FFF`.* Section 4.],
  [*Never `JMP ($xxFF)`.* The 6502 fetches the high byte from the wrong page.],
  [*Set your own stack.* The loader leaves S at `$16`; the first `JSR` before `LDX #$FF` / `TXS` lands in the TIA.],
)

The build scripts check the first three rules on every program they build. `tools/checkrom.py` (from the cartridge's own tree) and fujinet-lib's `atari7800-romstamp.py` disassemble the program's code segments from the linker's map and refuse an absolute store into the TIA's range, a read-modify-write aimed at the mailbox, an indirect jump through `$xxFF`, a missing claim, or a reset vector below `$4000`. An indexed store into the TIA's range cannot be seen that way; the cartridge's status page reports INPTCTRL's state at run time (`$0C1C` and `$0C1D`).
