#import "../lib.typ": *
= batari Basic on the Mailbox

batari Basic compiles BASIC into 6502 assembly around a kernel of its own: a playfield, two sprites, two missiles, a ball and a score. Everything the previous sections said about the mailbox is true for it too, because the mailbox is only memory, and BASIC can read and write memory. What is different is the shape of the program the compiler produces, and this section is about fitting that shape into the cartridge.

#sect[The 2K rule]

A batari Basic program is normally 4K, with its kernel at the bottom, its code in the middle, and its score font and vectors at the top --- at `$FF9C` and `$FFFC`, which on this cartridge is the status page, the claim and the fixed tail. That cannot work. What can is `set romsize 2k`:

- the image is exactly 2048 bytes, from `$F000` to `$F7FF`, which is the cartridge's bank 0;
- the program's entry point, `start`, is the first thing after the header, at `$F000`, which is `$1000`;
- nothing the compiler emits reaches `$F800` or above.

The build script appends the other half: a 2K fixed half from `fujitail.asm` that carries the claim at `$1F10`, a cold stub at `$1F20` that opens the gate, reselects bank 0 and jumps to `$1000`, and the vectors pointing at that stub. The result is a 4096-byte image the cartridge serves as bank 0 plus the fixed half, exactly like an assembly client.

#important[batari Basic's own bank switching --- `bank 2`, `goto label bank 3` --- cannot be used. Its trampolines and per-bank vectors live in the top 256 bytes of every bank, which on this cartridge is the mailbox. A batari Basic FujiNet client is one 2K bank, and this section ends with what that buys.]

#sect[The names]

batari Basic emits any name it does not know verbatim into the assembly, and dasm resolves it. So an assembler header of equates gives BASIC the mailbox under the same names assembly uses: `include fujinet.h` on the first lines of the program, then `fujibas.h`, which adds a name for every register's arm address and every one-shot hotspot, because BASIC cannot write `FNRSEL+FH_TROW`.

#tbl((1fr, 1fr),
  th[BASIC], th[Compiles to],
  [`FNH_TROW = 3`], [`LDA #3` / `STA $1DF0`],
  [`FNCMT = fnseq`], [`LDA fnseq` / `STA $1DFF`],
  [`ch = FNRPLY[i]`], [`LDX i` / `LDA $1B00,X` / `STA ch`],
  [`if FNACKS <> fnseq then goto wait`], [`LDA $1F00` / `CMP fnseq` / `BNE .wait`],
  [`FNTX = url[l]`], [`LDX l` / `LDA url,X` / `STA $1E00`])

An assignment to a mailbox name is a store; a mailbox name on the right is a load. Two rules come with that:

#caution[A name used as a *value* must be a batari Basic `const`, or the compiler treats it as memory: `FNCMT = FNDEVF` with `FNDEVF` known only to dasm compiles to `LDA $0070`, a load from the TIA, and the transaction goes out addressed to nobody. The build script prepends `fujiconst.bas`, generated from the headers, so every device id, command byte, register number, hotspot offset, blit kind, path operation and error code is a `const`. Addresses --- the window, the status cells --- are deliberately not, so they stay memory.]

#caution[Never `FNTX = FNTX + 1`, or any other arithmetic in place on a mailbox name: batari Basic compiles it to `INC` on the TX page, the one instruction the cartridge cannot sample. Compute in a variable, then assign. The static check catches it, after the fact.]

And a small one: do not `dim` a name onto a single letter you also use, and do not name a `dim` `c` or `i`; `a` to `z` are batari Basic's own variables, and redefining one is an assembler error about a value mismatch.

#sect[Where the variables go]

batari Basic's kernel owns `$80`--`$A3`; the RAM playfield is `var0`--`var47` at `$A4`--`$D3`; `a`--`z` are `$D4`--`$ED`; `aux1`--`aux6` at `$F0`--`$F5` are free unless the program uses playfield colours, heights, lives or the playfield score; and the stack is `$F6`--`$FF`, ten bytes, which is five nested `gosub`s. A FujiNet program needs about a dozen variables --- the sequence it is waiting for, an error, the device, command and count for the transaction helper, a generation for the render wait, and its own cursors --- and `a` to `z` hold them comfortably. The transport's state lives in the cartridge.

#sect[The helpers]

Every BASIC program in this handbook carries the same three subroutines at its end. They are the whole transport.

```
 rem fnbeg: begin a transaction from dev / cmd / npar
fnbeg
 FNA_DEV = 0
 FNCMT = dev
 FNA_CMD = 0
 FNCMT = cmd
 FNA_NPAR = 0
 FNCMT = npar
 FNA_DRST = 0
 FNCMT = 0
 return
 rem fngo: launch (SEQ = ACKSEQ + 1), draw frames until the cartridge
 rem answers; err = 0 on ACK, the transport's code, or 255
fngo
 fnseq = FNACKS + 1
 if fnseq = 0 then fnseq = 1
 FNA_SEQ = 0
 FNCMT = fnseq
 tries = 0
fngowait
 drawscreen
 if FNACKS = fnseq then goto fngodone
 tries = tries + 1
 if tries <> 0 then goto fngowait
 err = 255
 return
fngodone
 err = FNERR
 if err <> 0 then return
 if FNRCMD <> 6 then err = 255
 return
 rem fnend: render the composed row and wait for it to land
fnend
 gen = FNBTXG
 FNH_TEND = 0
 for l = 0 to 100
 if FNBTXG <> gen then return
 next
 return
```

Parameters and payload go between `gosub fnbeg` and `gosub fngo`, as stores to `FNTX`: the size byte, then the value. `fngo` draws a frame per poll, so the picture stays up and the joystick stays readable while the adapter works, and it gives up after 255 frames --- about four seconds, less than the cartridge's own five-second budget, so a real timeout is reported by the cartridge as its error and not guessed at here.

#sect[Showing text]

The program's picture is batari Basic's: its playfield and sprites, drawn by its kernel. The cartridge's text comes through `fujitext.asm`, a minikernel that draws a band of rows from the planes between the playfield and the score, in the slot batari Basic's standard kernel offers one:

```
 include fujitext.asm
 const FT_ROW0 = 18      ' the first text row shown, 0-20
 const FT_ROWS = 3       ' how many
 const pfrowheight = 6   ' see the table below
```

The band costs 3 + 6 × `FT_ROWS` scanlines, and batari Basic's frame is timer-locked: those lines come out of the time the program has between frames unless the playfield gives them back. `pfrowheight` shortens the playfield's rows. The table is what `frames.lua` measured, and the only honest way to know whether a layout fits is to measure yours the same way.

#tbl((auto, auto, auto, 1fr),
  th[`pfrowheight`], th[score], th[rows that fit], th[note],
  [8 (default)], [yes], [3], [176-line playfield; the frame has 45 lines to spare and the score takes ten],
  [6], [yes], [10], [144-line playfield],
  [6], [`const noscore = 1`], [13], [the directory lister uses 12, for one row of slack],
  [5 or less], [---], [none], [a playfield under 120 lines wraps the overscan timer and the frame breaks])

Composing text costs time too: a row of twelve stores and the render wait is about a line and a half, so a program that composes several rows in one go between two `drawscreen`s produces one long frame, which the set shows as a roll. Compose a row per frame, as the programs here do, or accept one long frame on a screen change, as Battleship does.

#sect[The budget]

After the standard kernel there are about 800 bytes for the program. That is enough for a screen and a few transactions, and the numbers below are what each program in this handbook had left.

#tbl((auto, auto, 1fr),
  th[Program], th[Bytes free], th[Note],
  [`blank.bas`], [829], [the frame loop and nothing else],
  [`hello.bas`], [483], [three rows of text],
  [`clock.bas`], [643], [two transactions, four rows],
  [`appkey.bas`], [454], [five transactions, four rows],
  [`boot.bas`], [428], [three transactions, the swap stub in `asm`],
  [`netget.bas`], [---], [five transactions, a settle loop, five rows: over by five bytes with the stock modules, and comfortable with the trimmed list below],
  [`dir.bas`], [576], [a listing of twelve rows, with the cursor, on the trimmed list])

`listings/bas/default.inc` is batari Basic's module list without `pf_drawing.asm` and `pf_scrolling.asm`, which are the `pfpixel`, `pfhline`, `pfvline` and `pfscroll` statements and about 335 bytes; batari Basic uses a `default.inc` in the build directory in preference to its own. A program that draws its playfield from a `playfield:` block does not need them. `const noscore = 1` removes the score kernel and its font for about a hundred more, and its ten scanlines.

#sect[Building]

```
cd listings/bas
./build.sh hello        # -> build/hello.bin, 4096 bytes
```

The script prepends `fujiconst.bas`, compiles in `build/` where the headers, the minikernel and `default.inc` are reachable, checks that the result is 2048 bytes, appends the fixed half, and runs the cartridge's static check. batari Basic's own kernel contains two indirect stores, aimed at RAM and the TIA; the script vouches for those two, by address, and fails on anything at or above the program's own `game` label. Then it prints how many bytes are left. Run the result with `emu/run.sh`, exactly like an assembly client.

#shot("bas-hello", caption: [`hello.bas`: batari Basic's playfield above, three rows of the cartridge's text below, through the minikernel.])
