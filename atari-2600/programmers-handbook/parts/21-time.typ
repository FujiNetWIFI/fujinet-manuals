#import "../lib.typ": *
= Things That Cost Real Time

The bring-up was seven milestones, and each one found something no earlier console in the family had. This is what they were, and what they cost, kept here because every one of them is a thing you will otherwise pay for yourself.

#sect[The milestones]

#tbl((auto, 1fr, 1fr),
  th[], th[Milestone], th[The exit test],
  [M0], [the cartridge-composed display], [the raster decoded back into plane bytes: 756 of 756 match the renderer],
  [M-novel], [the bus decode and the write-sampling model], [a host test, because MAME structurally cannot test the sampling --- its cartridge device is handed a clean byte],
  [M1], [the mailbox round trip, and reset survival], [live SSID, IP and version on screen; ACKSEQ 01 and then 02 across a reset],
  [M2], [network boot, byte-identical], [4096 of 4096 served bytes match the file, and the booted image runs],
  [M3], [the directory browser], [navigates to a file by name, boots it, 4096 of 4096],
  [M4], [the RP2040 firmware, the ESP32 board, CI], [the firmware builds, core 1 is SRAM-resident, three CI jobs],
  [M5], [the real cartridge mappers], [nine schemes against MAME's own handlers, 200,000 fuzzed accesses each],
  [M6], [soak], [thirteen synthetic cartridges across all nine schemes, every bank byte-compared],
  [M7], [CONFIG and Battleship], [CONFIG browses and boots through a subfolder; Battleship plays a real game against the live server])

M0 was pulled forward deliberately: every sibling console had a character generator or a framebuffer, so the cartridge-composed display was the one component with no template anywhere in the family. M-novel came with it, because MAME cannot test the write sampling, so it had to be proven before anything depended on it.

#sect[Designing the mailbox]

- *Sixteen pages for everything.* Three decisions bought pages back. The REGDATA and DATA hotspots are not console addresses: the firmware's dispatcher only needs three distinct page numbers, so two of the three live outside the window and the bus layer synthesises the events. The reply is 512 bytes, not 256 or 1024, because 512 is the size at which the flagship client never pages a slice. And the claim and the vectors live in the fixed half, so a RESET is survivable whatever bank is mapped.
- *A read of a write port is a write.* The Channel F's cartridge can tell a store from a fetch and its register pages are inert to reads; this one cannot, so the arm-then-commit pair stayed, and here it is the defence. The disarm-after-one-use in the firmware does real work on this console.
- *The 6507 has no interrupts*, which is the one structural gift: it is what lets the static check be a proof.
- *A bank-switch hotspot returns the old bank's byte.* MAME installs a read bank and a read tap over the same range and runs the tap after the read, so the access that switches still returns what was there before. The port had it inverted until the MAME source settled it, and it is invisible until a game reads its own hotspot for data as well as for the side effect.
- *Banking is a pointer swap, never a copy.* The first version copied 2K into the window, which is microseconds against an 838-nanosecond bus, and it passed every test, because MAME's device has all the time in the world. Every real 2600 mapper swaps a pointer, and so does this one now.
- *UA and FE switch on addresses below A12*, where the cartridge is not selected at all and is only watching the bus. Neither the RP2040 loop nor the MAME device was looking there.
- *Size detection needs the `.cfg`.* An 8K F8, E0, UA and FE are all 8192 bytes and nothing inside the file tells them apart. And the hint has to be spent on the image it came with, or a hint left standing is applied to the next image --- the ColecoVision learned this the same way.
- *A blit is single-slot.* Battleship fired thirteen in a burst; on hardware most would be lost and in MAME none, so BLITGEN was published and the client waits for it. TEXTGEN is the same thing for a row.
- *The equates drift.* The spec put the control page at `$1D00` and the client's header said `$1C00`; every register write went to a page that decodes nothing, reads of it fell through to the served window, and the client came up, drew a screen, and never armed the mailbox. `checkdefs.py` cross-checks every equate against the header and the build runs it first.
- *Equates and code go in different include files.* Including the code half before the `ORG` assembles the whole transport at `$0000`, and every `JSR` to it becomes `20 00 00`.

#sect[The display]

Three real bugs came out of decoding the raster instead of squinting at it: a missing seventh `GRP` write, an end-of-frame drain that toggled `VDELP` off and on and so restored the stale registers, and a `LDX`-versus-`TSX` cycle --- the copies are 2.67 cycles apart and a zero-page store is 3, so the four late writes drift a full cycle and that one cycle decides whether the schedule closes at all. Three glyph pairs were bit-identical at 3 × 5 and had to be redrawn, because `SOAK.BIN` and `50AK.BIN` were the same picture. And harnesses that look for text on screen compare rendered forms, not decoded text, because decoding is lossy at this size and always will be.

#sect[The first programs]

- The `READ_DIR_ENTRY` width is 30, not 31; at 31 the firmware prepends icon bytes.
- `SET_DIRECTORY_POSITION` is one parameter of two bytes, not two of one.
- Reading past the end of a directory poisons the session on an SD host.
- `OPEN_DIRECTORY` and `SET_DEVICE_FULLPATH` read exactly 256 bytes; every port in this family has paid for a short payload once.
- `OPEN_APPKEY`'s struct has a sixth, reserved byte; without it the adapter waits for a byte that never comes.
- The swap stub must silence the sound and return the RIOT ports to inputs.
- In Battleship: the stack leaked two bytes per poll through the trampoline until it reset the stack; a bank's scratch aliased the settle loop's counter; a whole fleet did not fit in one overscan; a seam line that ran past cycle 76 silently cost a second scanline and a 278-line frame; the four-seat recompose was three lines too long and had been all along, because the frame test ran at two seats.

#sect[The MAME bench]

- `SDL_VIDEODRIVER=dummy` is required wherever there is no display, even under `-video none`, because SDL comes up before the video backend is chosen.
- MAME must run from its own tree or `-autoboot_script` is silently ignored.
- `fujinet-pc`'s bus-over-IP listener takes one client; a stray MAME starves the next run, and the symptom is a hang.
- MAME's Lua binds neither the beam position nor the cycle counter, and a write tap does not fire on the TIA range, so raster instrumentation comes from decoding snapshots.
- The grafted device must be re-applied after every edit to a shared source; MAME builds the copies.
- Without symbol prefixing, a MAME tree that already carries the Arcadia and Astrocade FujiNet devices links one `fujimail_paint()` for all three, and the rest paint the wrong offsets.

#sect[This handbook's own]

- A batari Basic program built for 4K puts its score font and vectors on the status page; `set romsize 2k` is the whole answer.
- A name batari Basic has not seen as a `const` compiles to a load from memory when used as a value: `FNCMT = FNDEVF` went out as `LDA $0070`, and the transaction, addressed to whatever the TIA read as, timed out. Every value is a `const` now, generated and prepended.
- A playfield under 120 lines wraps batari Basic's overscan timer and the frame comes out short --- 163 lines --- with nothing looking wrong in the source. `pfrowheight` of 6 is the knob; 5 is not.
- Composing three text rows between two frames makes one 268-line frame. A row per frame does not.
- `pkill -f "mame a2600"` in a run script matches any shell whose command line contains the pattern --- including the one running the script. Anchor it.
- The harness must resolve the image's path before it changes directory into MAME's tree.
