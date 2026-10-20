#import "../lib.typ": *
= Banks and SuperGame

#ini[A] 7800 sees 48K of cartridge at most. Atari’s answer for bigger games was *SuperGame* banking: the image is cut into 16K banks, the last one sits at `$C000`–`$FFFF` for good, and any of the others can be shown at `$8000`–`$BFFF`. A store anywhere in `$8000`–`$BFFF` picks which. The FujiNet cartridge does SuperGame, with or without 16K of RAM at `$4000`, and the mailbox stays put through every switch.

#fig(memmap((
  (0x4000, 0x7FFF, "cartridge RAM (16K)", tint-d, [with SuperGame + RAM]),
  (0x8000, 0xBFFF, "bank 0, 1, 2 …", tint-b, [whichever was stored to `$8000`]),
  (0xC000, 0xFFFF, "last bank, fixed", tint-a, [start-up, library, font, claim]),
), scale: 0.0035pt, minh: 18pt), caption: [A SuperGame image. The mailbox, below `$1000`, never moves.])

#sect[What goes where]

Three rules decide what lives in the fixed bank:

#steps(
  [*The code that switches banks.* Code that stores to `$8000` from a switched bank switches itself out from under the 6502. Switch from the fixed bank, and call into the switched one.],
  [*Everything MARIA reads.* MARIA reads the font or tiles every line. If they live in a switched bank, the picture turns to garbage whenever another bank is in — and a program waiting for the FujiNet keeps the display running.],
  [*The mailbox library, and anything every bank calls.* A switched bank can always call the fixed one.],
)

And one to watch for: a *data* store into `$8000`–`$BFFF` switches banks too. A pointer that strays there does not write ROM; it changes what the 6502 is about to execute.

The cartridge has to know the image is SuperGame. A plain 64K or 128K image with no other clue would be taken for something else, so a FujiNet app says so in its claim’s kind byte: 3 for SuperGame (the layout id 2, plus one), 5 for SuperGame with RAM. An `.a78` header that says SuperGame works too, if the claim leaves the kind at 0.

#fig(grid(columns: 3, column-gutter: 6pt,
  tvframe("images/screens/asm-fujibank.png", 1.2in),
  tvframe("images/screens/c-bank.png", 1.2in),
  tvframe("images/screens/bas-bank.png", 1.2in)),
  caption: [A transaction from each of three banks, three ways.])

#sect[In assembly]

`fujibank.s` is the bring-up’s banked app: a 64K image, kind 5, three switched banks. Each bank’s code at `$8000` makes a transaction and returns its own number, so a wrong bank shows on the screen:

#ex((path: "listings/common/fujibank.s", from: ".macro  BANKCODE n", to: "        BANKCODE 0"), t-asm)

From the fixed bank, the program shows each bank and calls into it:

#ex((path: "listings/common/fujibank.s", from: "@b:     lda     bank", to: "@right: pha"), t-asm)

`a78bank.cfg` places the three banks at `$8000`, each its own 16K of the file, and everything else — start-up, the library, the font, the claim — in the fixed bank; `a78init.s` writes kind 5 when the build defines `BANKED`. After the three transactions the program boots `hello`, as `fujiboot` does, to show a banked app can.

#sect[In C]

A banked C program needs two things fujinet-lib does not provide. `bank.cfg` is the library’s linker configuration with the ROM split SuperGame’s way:

#ex((path: "listings/c/bank.cfg", from: "    BANK0:   file", to: "    CLAIM:   file"), "LD65 CONFIGURATION")

and `crt0bank.s` is the library’s start-up with one byte changed, the claim’s kind:

#ex((path: "listings/c/crt0bank.s", from: "        .segment \"CLAIM\"", to: "        .segment \"VECTORS\""), t-asm)

Because the program’s own `crt0bank.o` provides the start-up symbols, the linker never takes the library’s. In the program, `#pragma code-name` puts each bank’s function in its bank, and a small function in the fixed bank switches and calls:

#ex((path: "listings/c/bank.c", from: "/* SuperGame:", to: "void main"), t-c)

The C runtime, fujinet-lib and the tile engine’s tiles are all in the fixed bank by default, so a bank’s function can call any of them. Build it with the configuration and the extra file:

```
cd listings/c
CFG=bank.cfg EXTRA=crt0bank.s ./build.sh bank
```

fujinet-lib’s romstamp takes images of 48K at most, so for a bigger one `build.sh` runs `tools/checkbanks.py` instead: the same checks, with each bank scanned at its own place in the file.

#sect[In 7800basic]

7800basic does the banking itself. `set romsize 128k` makes eight 16K banks, bank 8 fixed; `bank` starts each bank’s code; `gosub label bankN` switches, calls and switches back when the subroutine ends with `return otherbank`. The library and the font go in bank 8:

#ex((path: "listings/bas/bank.bas", from: " gosub acfg", to: "failed"), t-bas)
#ex((path: "listings/bas/bank.bas", from: " bank 2", to: " incbasic fujilib.bas"), t-bas)

7800basic writes a SuperGame `.a78` header for a 128K program, and the claim’s kind stays 0, so the cartridge goes by the header. Without its own RAM flag the program has no cartridge RAM, and needs none.
