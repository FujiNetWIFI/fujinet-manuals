#import "../lib.typ": *
= The Cartridge Window

The 6507 has thirteen address lines. Everything above `$0FFF` selects the cartridge, and since A13 to A15 do not exist, `$F000` and `$1000` are the same place. The cartridge has sixteen pages of 256 bytes, total, for everything: the program, the text it shows, the replies it reads, and the two pages it writes into. This section is the map.

#fig(memmap((
  (0x1000, 0x17FF, [BANKED CLIENT CODE, 2K], lime, [one of up to 112 banks; page selected by a store to `$1D80` + bank]),
  (0x1800, 0x1AFF, [TEXT PLANES, 768], cyan, [six 128-byte planes composed by the cartridge; the display kernel reads them]),
  (0x1B00, 0x1CFF, [REPLY WINDOW, 512], orange, [the adapter's reply, one 512-byte slice of up to two]),
  (0x1D00, 0x1DFF, [CONTROL PAGE], red, [write-only: arm a register (`$00`--`$7F`), or a one-shot operation (`$80`--`$FF`)]),
  (0x1E00, 0x1EFF, [TX STREAM], purple, [write-only: a store anywhere here appends its data byte]),
  (0x1F00, 0x1FFF, [STATUS, CLAIM, TAIL, VECTORS], magenta, [`$1F00`--`$1F1F` status cells; `FUJI` at `$1F10`; the client's fixed tail at `$1F20`; vectors at `$1FFC`]),
), minh: 20pt, scale: 0.026pt), caption: [The cartridge window. The low 2K is banked; the high 2K is the mailbox in its entirety.])

#sect[Two halves]

The low half, `$1000`--`$17FF`, is the program. It is a 2K bank, and the cartridge can serve any one of up to 112 of them there; a store to `$1D80` plus the bank number switches, and the switch is complete before the console's next fetch. A single-bank program simply never switches.

The high half, `$1800`--`$1FFF`, belongs to the mailbox. Nothing a program stores in that range of its image is ever served, except the last 256 bytes: the status page, where the cartridge paints its cells in the low part and serves the program's own bytes in the rest. That is where the claim, the fixed tail and the vectors live, and it is the one region every bank sees at the same address.

#sect[The image]

A client image is N banks of 2K followed by the 2K fixed half, so its size is (N+1) × 2048 bytes. MAME's cartridge loader accepts only certain sizes, so N is 1, 3, 7 or 15: a 4K, 8K, 16K or 32K image. A program that needs five banks pads to seven.

The fixed half is the last 2K of the file whatever the size, and only its top 256 bytes matter. Four of those are the claim:

#important[An image carrying the four bytes `FUJI` at `$1F10` promises that it is a FujiNet client, and the cartridge keeps the mailbox alive after it boots. An image without them is a game, and the mailbox goes dead for the session. The build scripts stamp the claim at file offset (size − 2048) + `$710`.]

#tbl((auto, 1fr),
  th[Offset in the fixed half], th[What is there],
  [`$700`--`$70F`], [painted by the cartridge: ACKSEQ, STATUS, ERR and the rest (Section 4)],
  [`$710`--`$713`], [the claim, `FUJI`],
  [`$714`--`$716`], [the header: bank count, cell height, layout revision],
  [`$717`--`$719`], [painted by the cartridge: the path buffer length and the blit generation],
  [`$720`--`$7FB`], [the fixed tail: 220 bytes of the client's code that every bank must reach at the same address --- the cold stub, the bank trampoline],
  [`$7FC`--`$7FF`], [the RESET and BRK vectors])

#sect[Reset survival]

The cartridge port has no reset line, and the console's RESET switch is a bit in a RIOT register that the cartridge never sees. A console restart therefore begins with whatever bank was last selected still mapped, and RAM as it was. Two rules follow, and every client in this handbook obeys them:

- The RESET vector points into the fixed half, at a cold stub that reselects bank 0 before it jumps to the program. A vector into a bank would reset into the wrong code from any other bank.
- The next sequence number comes from the cartridge, never from a counter in RAM. Section 4 explains why.

#sect[The static check]

Because the 6507 has no interrupts, every access a running program makes comes from its own instruction stream, and a scan of the image can prove things an emulator can only sample. `tools/checkrom.py` in the cartridge tree fails the build when:

- the image is not (N+1) × 2048 bytes, or not a size MAME will load;
- the claim is missing;
- the RESET vector does not point into the fixed half for a banked image, or anywhere in the window for a flat one;
- any of `INC`, `DEC`, `ASL`, `LSR`, `ROL`, `ROR` with an absolute or absolute,X operand reaches `$1D00`--`$1EFF`;
- an indirect `JMP` has a vector on a page boundary (the 6502's own bug);
- an indirect store, `STA (zp),Y` or `STA (zp,X)`, appears anywhere at all, since the scan cannot know what a zero-page pointer holds and an indirect store performs a read at the address it writes.

Every bank is scanned, because every bank is entered at `$1000` and every bank is code.

#note[batari Basic's own kernel contains two indirect stores, aimed at RAM and the TIA. The BASIC build script vouches for those two by address, below the program's own code, and holds the program to the rule.]
