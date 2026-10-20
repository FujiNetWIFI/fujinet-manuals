#import "../lib.typ": *
= 7800basic on the Mailbox

#ini[7]800basic compiles a BASIC program into 6502 assembly, assembles it with dasm, and produces an ordinary 7800 cartridge image. Nothing in it knows about the FujiNet. Three things make one of its programs a FujiNet program: names for the mailbox, a small library of subroutines, and ten bytes stamped into the finished image.

#sect[The names]

In 7800basic, `dim name = $address` makes a variable that *is* that address. So the mailbox needs no special statements at all: `fujinet.bas` names every cell and register a program uses, and a store to the name is a store to the mailbox.

#ex((path: "listings/bas/fujinet.bas", from: " rem cells the cartridge paints", to: " rem the library"), t-bas)

`FN_CMD = fn_cmd` compiles to exactly what Section 4 asks for:

```
  lda fn_cmd
  sta FN_CMD
```

Values that never change are `const`: `FN_FUJI`, `FN_NET`, `FN_OK` and the rest. A program brings the names in first, with `incbasic`, which pastes another BASIC file in where it stands:

```
 incbasic fujinet.bas
```

#sect[The library]

`fujilib.bas` is `fujilib.s` again, subroutine for subroutine, written in BASIC. Its subroutines take their arguments in the library’s own variables, `var90`–`var99`:

#tbl((auto, auto, 1fr),
  th[Subroutine], th[Takes], th[Does],
  [`fn_chk`], [—], [`fn_res` = 0 if a FujiNet cartridge answers, else `FN_ENOCART` (`$FD`).],
  [`fn_beg`], [`fn_dev`, `fn_cmd`, `fn_npr`], [Writes the registers and rewinds the TX stream. Sets `fn_tmo` to 3.],
  [`fn_pb`], [`fn_val`], [Appends a one-byte parameter.],
  [`fn_pw`], [`fn_val`, `fn_valhi`], [Appends a two-byte parameter.],
  [`fn_pad`], [`fn_i`], [Appends NULs until `fn_i` wraps: after a path of `fn_i` bytes, exactly 256.],
  [`fn_go`], [`fn_tmo`], [Launches and waits, calling `drawscreen` each frame so the picture stays up. `fn_res` = 0, the cartridge’s error, `FN_ENAK` (`$EE`) if the FujiNet said no, or `FN_EWAIT` (`$FF`) after `fn_tmo` × 256 frames.],
  [`fn_hex`], [`fn_val`], [Two hex digits into `fn_hexbuf`, for `plotchars`.],
)

The default timeout of 3 is about 13 seconds on NTSC and 15 on PAL. Set `fn_tmo` after `fn_beg` for a slow command: 16 for MOUNT_IMAGE, 22 for the network device. The library goes at the end of the program, after the main loop, where nothing falls into it:

```
main
 drawscreen
 goto main

 incbasic fujilib.bas
```

A transaction then reads like this:

#ex((path: "listings/bas/acfg.bas", from: " fn_dev = FN_FUJI", to: " for ix"), t-bas)

#sect[The claim]

7800basic fills the last 4K of the program upward from `$F000` with its own runtime and keeps `$FF7E`–`$FFFF` for a checksum, the signature and the vectors. The FujiNet claim goes at `$FF70`, so it fits whenever the runtime ends below that — which, in every program in this handbook, it does by more than 2K. `tools/basfix.py` checks and stamps it after dasm has built the image:

- it reads dasm’s own count of bytes left in the reserved area, and refuses if the code reaches `$FF70`;
- it stamps `"FUJI"`, version 1, kind 0 (let the cartridge decide), no flags;
- it reads every instruction in dasm’s listing, so graphics are never mistaken for code, and refuses a read-modify-write aimed at `$0D00`–`$0FFF`.

Then 7800basic’s own `7800header` writes the `.a78` header, with the bank scheme the program asked for.

#sect[Rules]

Every one of these was found the hard way, by a program in this handbook that compiled without a word and then did the wrong thing.

#steps(
  [*Do not name a variable with one letter.* `a` to `z` are 7800basic’s own variables, in zero page. `dim i = var2` fails the build with dasm’s “EQU: Value mismatch”.],
  [*No arithmetic on a mailbox name.* `FN_TX = FN_TX + 1` compiles to `LDA $0F00` / `ADC #1` / `STA $0F00`: it reads a write page, which holds nothing meaningful, and appends that, plus one. Use the names only on the left of a plain assignment, and the cells only on the right.],
  [*No expression inside an array index.* `line1[ix] = FN_REPLY[ix + 2]` compiles, silently, into nonsense: the listing shows `LDX i` (the variable `i`, not `ix`) and `ADC #2]`. Give the address its own name instead: `dim FN_R_VALUE = $0802`, then `FN_R_VALUE[ix]`.],
  [*No expression in a `for` bound.* `for ix = 0 to len - 1` compiles as if it said `to len`: the `- 1` disappears and the loop runs once too often. One extra byte in an appkey is how this was found. Compute the bound first: `last = len - 1`, then `for ix = 0 to last`.],
  [*Copy before you plot.* MARIA cannot read the mailbox (Section 5). Copy a string from the reply into an array in `$2200`–`$27FF`, and plot the array.],
  [*Index at most 255.* An array index is one byte. For a reply field past the first 256 bytes, `dim` a name at its address.],
)

#sect[INPTCTRL]

7800basic’s start-up locks INPTCTRL, as Atari’s guidelines asked every cartridge to. On the FujiNet cartridge that has one consequence: a game the program boots (Section 12) can no longer be handed to the console’s own BIOS, and the loader starts it directly instead. All 126 games the cartridge was tested with run that way too, so for most programs the lock does no harm.

A program that boots games can leave INPTCTRL unlocked with two constants that 7800basic’s start-up and sound code check but its documentation does not mention:

```
 const NOTIALOCK = 1
 const NOTIALOCKMUTE = 1
```

`NOTIALOCK` makes the start-up write `$06`, unlocked, instead of `$07`. `NOTIALOCKMUTE` silences every TIA sound statement, because with INPTCTRL unlocked any store to the TIA rewrites it. Sound then has to come from the POKEY. `boot.bas` does this; its status line shows INPTCTRL unlocked where every other BASIC program shows it locked.

#sect[Banks]

A program bigger than 48K uses 7800basic’s bank switching (`set romsize 128k`), and two things must live in the last bank, which never moves: the library, so every bank can call it, and the font, because MARIA reads it every line and a font in a switched bank turns to garbage while another bank is in. Section 14 shows both.

#sect[Building]

`listings/bas/build.sh` runs 7800basic’s steps directly — the preprocessor, the compiler, the post-processor and dasm — then `basfix.py` and `7800header`:

#ex((path: "listings/bas/build.sh", from: "    (", to: "done"), "SHELL")

```
cd listings/bas
./build.sh acfg                 # build/acfg.a78
```
