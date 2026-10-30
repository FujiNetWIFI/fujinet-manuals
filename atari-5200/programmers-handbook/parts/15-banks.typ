#import "../lib.typ": *
= Banks and the Super Cart <ch-banks>

A program that outgrows 32K can be a *Super Cart*: 64K or 128K, seen through the cartridge window 32K at a time. The cartridge serves a FujiNet app on a Super Cart with the mailbox over every bank, so a program can make transactions from any of them.

#sect[Switching]

The Super Cart switches the whole window at once, on a read of one of its top 64 bytes:

#tbl((auto, 1fr),
  th[Read], th[Selects],
  [`$BFE0`–`$BFFF`], [The last bank: bank 1 of a 64K cart, bank 3 of a 128K one. This is also the bank it powers on in.],
  [`$BFD0`, `$BFD4`, `$BFD8`, `$BFDC`], [Bank 0, 1, 2 or 3: address bits 2 and 3 are the bank number.],
  [`$BFC0`–`$BFCF`], [The high bits of the bank number, for carts bigger than 128K. Nothing, on the cartridge.],
)

Use `BIT` to make the read: it leaves A and X alone, so a far call keeps its arguments and its result. Two consequences of switching by reading are easy to miss:

- *The claim is in the switch.* `$BFE0` is both the start of the FujiNet claim and a hotspot, so anything that reads the claim selects the last bank.
- *ANTIC reads the window too.* A display list or a font in banked ROM is read from whichever bank is selected when ANTIC gets to it. Keep them where every bank has them.

#sect[Laying out the banks]

Because the whole window switches, code that runs during a switch must be at the same address in every bank, with the same bytes. Both of this handbook’s banked programs do it the same simple way: every bank is a copy of the last one, except for 4K at `$A000`–`$AFFF` that each bank has to itself. The common part holds the start-up code, the libraries, the interrupt handlers, the display list and the font, and the code that switches; the window at `$A000` holds what each bank adds.

#tbl((auto, auto, auto),
  th[], th[Bank 0], th[Bank 1 (last)],
  [`$4000`–`$9FFF`], [common], [common],
  [`$A000`–`$AFFF`], [bank 0’s own], [bank 1’s own],
  [`$B000`–`$B7FF`], [the mailbox], [the mailbox],
  [`$B800`–`$BFFF`], [common, claim, header], [common, claim, header],
)

The build links bank 1 as an ordinary 32K program, links bank 0’s 4K separately against bank 1’s addresses, makes bank 0 a copy of bank 1 with its own 4K laid in, and writes bank 0 first. The checker accepts 64K and 128K images.

#sect[A far call]

`far0` switches to bank 0, calls its entry at `$A000`, and switches back. It is in the common part, so the instruction after each `BIT` is fetched from the bank just selected, and is the same there:

#ex((path: "listings/asm/bank.s", from: "; far0 --", to: ".proc main"), t-asm)

In C the switch is in assembly too, in `supercart.s`, because cc65’s optimiser drops a read whose value is unused, even an inline `lda`. Bank 0’s code is ordinary C, put in its own segment with `#pragma code-name`:

#ex((path: "listings/c/supercart.s", from: ".proc _far_bank0", to: ".endproc"), t-asm)
#ex((path: "listings/c/bank0.c", from: "#pragma code-name (push, \"BANK0\")", to: "#pragma rodata-name (pop)"), t-c)

`bank.cfg`, the C program’s linker configuration, is MekkoGX’s with `$A000`–`$AFFF` cut out of the ROM twice: once for bank 1, in the image, and once for bank 0, in a file of its own that the build lays over the copy.

#sect[bank]

`bank` shows a byte that differs between the banks, makes a transaction from bank 1, calls bank 0 (which shows its own byte and makes a transaction of its own), and shows bank 1’s byte again on the way back.

#shots("asm-bank", "c-bank", caption: [bank in assembly and in C: `1`, then bank 0’s `0` and the SSID it fetched, then `1` again.])

#ex((path: "listings/common/bank0.s", from: "        jmp     entry", to: "tb0:"), t-asm)

#note[`bank.s` is the bring-up’s `fujibank.s` without its last step, which boots a game. `bank0.s` is the bring-up’s, unchanged.]
