#import "../lib.typ": *
= The Memory Map <ch-map>

The ATARI 5200 is an Atari 400 rearranged: the same 6502C at 1.79 MHz, the same ANTIC, GTIA and POKEY, 16K of RAM, and a 2K BIOS in place of the 400’s operating system. The chips sit at new addresses, and the cartridge has 32K of the address space to itself.

#fig(memmap((
  (0x0000, 0x3FFF, [RAM], tint-d, [16K: zero page, stack, vectors, your program’s data and screens]),
  (0x4000, 0xBFFF, [Cartridge], tint-a, [32K: the FujiNet cartridge (below)]),
  (0xC000, 0xCFFF, [GTIA], tint-b, [colours, players, triggers, `CONSOL`]),
  (0xD000, 0xDFFF, [ANTIC], tint-b, [at `$D400`: display lists, DMA, `WSYNC`, NMIs]),
  (0xE000, 0xE7FF, [], panel, [nothing]),
  (0xE800, 0xEFFF, [POKEY], tint-b, [sound, pots, keypad, random numbers, IRQs]),
  (0xF000, 0xFFFF, [BIOS], tint-c, [2K at `$F800`, with the 6502’s vectors]),
), scale: 0.0018pt, minh: 15pt), caption: [The console’s address space.])

The chip registers repeat through their pages: GTIA every 32 bytes, POKEY every 16. Use the base addresses in `fujinet.inc`; there is nothing to gain from the mirrors.

#sect[The cartridge window]

The cartridge answers every read from `$4000` to `$BFFF`. What it answers with depends on what it is serving, which it reports in `MODE` at `$B412`:

#tbl((auto, auto, 1fr),
  th[MODE], th[Name], th[What the console sees],
  [0], [BOOT], [CONFIG, from the cartridge’s own flash. This is what a power-on gives you.],
  [2], [GAME], [An image without the FujiNet claim: a game, served exactly as its own cartridge board would serve it. The mailbox is gone.],
  [3], [APP], [An image with the claim: your program, with the mailbox at `$B000`–`$B7FF` in every bank.],
)

Every program in this handbook is an APP. Its 32K are laid out like this:

#fig(memmap((
  (0x4000, 0xAFFF, [Program], tint-a, [28K of ROM: code, tables, display lists, fonts]),
  (0xB000, 0xB3FF, [Reply], tint-b, [the last reply, up to 1K (@ch-mailbox)]),
  (0xB400, 0xB4FF, [Status], tint-b, [sequence number, error, length, progress]),
  (0xB500, 0xB7FF, [Hotspots], tint-c, [read to say: registers and TX]),
  (0xB800, 0xBFDF, [Program], tint-a, [2K more of ROM]),
  (0xBFE0, 0xBFFF, [Claim + header], tint-d, [`FUJI`, then the BIOS’s header]),
), scale: 0.0034pt, minh: 15pt), caption: [An APP in the cartridge window.])

Your image is 32K, and the build fills `$B000`–`$B7FF` with `$FF`; the cartridge lays the mailbox over that part as it serves the image. Nothing you put there is ever seen.

#sect[The claim and the header]

The BIOS reads the top 24 bytes of the window at power-on. The FujiNet claim sits just below them:

#tbl((auto, auto, 1fr),
  th[Address], th[Bytes], th[What it is],
  [`$BFE0`], [4], [`"FUJI"`: the claim. Without it, the image runs as a GAME and the mailbox is switched off.],
  [`$BFE4`], [1], [The claim’s version: 1.],
  [`$BFE5`], [1], [The board to serve the image as, plus one; 0 lets the cartridge decide from the size. A Super Cart app may say 4.],
  [`$BFE6`], [1], [Flags: 0.],
  [`$BFE7`], [1], [`$02`: the two-port console’s BIOS reads this on a PAL machine and refuses a cartridge that does not say “PAL-compatible”. Not part of the claim.],
  [`$BFE8`], [20], [The title the BIOS would show. A FujiNet program never lets it.],
  [`$BFFC`], [1], [The year the BIOS would show.],
  [`$BFFD`], [1], [`$FF`: skip the BIOS’s title screen and start the program at once.],
  [`$BFFE`], [2], [The program’s start address.],
)

In assembly, `header.inc` lays all of this out for you; in C, MekkoGX’s start-up code does. Both checkers refuse an image without it.

#sect[How a program starts]

At power-on the cartridge serves CONFIG. When you pick a program, CONFIG has the FujiNet push it into the cartridge, quiets the console as a power-on leaves it, and jumps to a three-byte stub the cartridge serves at `$B5F0`: `JMP ($FFFC)`. The cartridge swaps your image in on the read of the stub’s last byte, so the jump takes the console into the BIOS’s own reset code with your program in the window. The BIOS sets up the chips, sees `$FF` at `$BFFD`, and jumps through `$BFFE`. @ch-boot shows a program doing the same for another one.

Your program starts with interrupts off, display DMA off, and nothing set up. The start-up code of either language does what the BIOS would have done, and keeps the BIOS’s zero page and vectors as the BIOS lays them out (@ch-ram).

#sect[No reset line, no read/write line]

The 5200’s cartridge edge carries the address lines, the data lines and two enables, one for each 16K half of the window, and that is all. Two things follow.

- *The cartridge cannot see a reset.* The #key("RESET") key is a key on the keypad, read like any other. A power cycle restarts the cartridge, and it comes back in CONFIG; nothing else does, except a program that asks (@ch-boot).
- *The cartridge cannot tell a read from a write.* Everything a program says to it is said with reads (@ch-mailbox), and a store anywhere in `$4000`–`$BFFF` is a mistake: the cartridge drives the data bus as if for a read, against the CPU.

The four-port console has no clock on the edge either. The cartridge decides that an access has happened when the address has held still long enough, so two reads of the same address on two cycles in a row look like one.

#sect[What every program must not do]

`tools/checkrom.py` and MekkoGX’s `atari5200-romstamp.py` check most of these on every build. The rest is up to you.

- Store anywhere in `$4000`–`$BFFF`.
- Use a read-modify-write instruction (`INC`, `DEC`, `ASL`, `LSR`, `ROL`, `ROR`) on the cartridge window.
- Read the hotspot pages `$B500`–`$B7FF` with anything but `LDA`, `LDX`, `LDY` or `BIT`, absolute or absolute-indexed, from a page-aligned base. An index that carries into the next page makes the 6502 read the wrong page first, and the cartridge counts that read.
- Read one hotspot address on two cycles in a row.
- Use `JMP ($xxFF)`, which fetches its high byte from the wrong page.
- Point ANTIC at the mailbox. A display list, a screen or a font in `$B000`–`$B7FF` would be read by DMA, and every DMA read of a hotspot is an event.
- Leave out the claim and the header.
