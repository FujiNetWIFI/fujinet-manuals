#import "../lib.typ": *
= The Text Display <ch-display>

The 5200 draws its picture the way every Atari computer does. ANTIC reads a *display list*, a short program in memory that says, line by line, what kind of picture to make and where its data is; GTIA colours what ANTIC sends it. For text, the display list asks for ANTIC mode 2: 40 characters a row, each 8 × 8 pixels from a font of 128 characters, with bit 7 of a character code meaning reverse video. Twenty-four rows fill the screen.

Every program in this handbook writes its text the same way, into a 40 × 24 screen in RAM. There are three ways to get there.

#tbl((auto, auto, auto, 1fr),
  th[Road], th[Language], th[Screen], th[What it is],
  [`fujidisp.s`], [assembly], [`$1000`], [The bring-up’s: mode 2, a display list and a font in ROM, routines to place, print and show hex and decimal.],
  [`antic.c`], [C], [`$3C00`], [CONFIG’s: the same mode, a cursor, strings, fills, reverse video.],
  [cc65 conio], [C], [`$3E20`], [cc65’s own console: 20 × 24 in ANTIC mode 6, four colours, bigger letters.],
)

The first two give the same screen, from the same font, so the programs in this handbook look alike in both languages.

#sect[The display list]

`fujidisp.s` keeps its display list in ROM. Three instructions of eight blank lines push the picture down from the top of the television; the fourth says “mode 2, and load the memory counter” with the screen’s address; twenty-three more say “mode 2” and carry on from there; the last jumps back to the start and waits for the next frame.

#excerpt-at("6502 ASSEMBLY  ·  fujidisp.s", "listings/common/fujidisp.s", "dlist:  .byte", n: 6)

The font is in ROM too, 1K-aligned, because ANTIC finds it from the page number in `CHBASE` (`$D409`). Neither may sit in the mailbox at `$B000`–`$B7FF`: ANTIC would read the hotspots (@ch-map). The screen may go anywhere in RAM that does not cross a 4K boundary, where ANTIC’s memory counter wraps.

The BIOS keeps a shadow of each display register in zero page, and its vertical-blank interrupt copies them to the chips every frame. Both languages’ start-up code keeps that arrangement, so a program sets the shadows, not the chips:

#tbl((auto, auto, 1fr),
  th[Shadow], th[Copied to], th[In mode 2],
  [`SDLSTL/H` `$05/$06`], [`DLISTL/H` `$D402`], [The display list’s address.],
  [`SDMCTL` `$07`], [`DMACTL` `$D400`], [`$22`: a normal-width playfield and display-list DMA; 0 turns the picture off.],
  [`COLOR1` `$0D`], [`COLPF1` `$C017`], [The text’s brightness (its colour is the background’s).],
  [`COLOR2` `$0E`], [`COLPF2` `$C018`], [The background.],
  [`COLOR4` `$10`], [`COLBK` `$C01A`], [The border.],
)

Character codes are ANTIC’s, not ASCII: `$20`–`$5F` become `$00`–`$3F`, `$00`–`$1F` become `$40`–`$5F`, and `$60`–`$7F` stay as they are. Both libraries translate as they print, so programs pass ASCII.

#sect[hello]

The first program shows four lines: a title, whether a FujiNet cartridge is answering (`MAGIC` at `$B409`), the frame counter the VBI keeps, and the last key pressed on the keypad. It makes no transactions, so it runs with no adapter at all.

#shots("asm-hello", "c-hello", caption: [hello in assembly and in C.])

In assembly, `hello.s` is the bring-up’s own first program, unchanged. `disp_init` clears the screen and points ANTIC at it with the display still off; `disp_on` turns it on once the text is there, so nothing half-drawn is ever seen.

#ex((path: "listings/common/hello.s", from: ".proc main", to: ".endproc"), t-asm)

In C, `mt_init` does what `disp_init` and `disp_on` do together, and `mt_colours` sets the background and the text’s brightness:

#ex((path: "listings/c/hello.c", from: "void main(void)", to: "    for (;;) {"), t-c)

#sect[The third road: cc65’s console]

cc65’s `atari5200` library has a console of its own: `clrscr`, `gotoxy`, `cputs` and the rest of `conio.h`, on a 20 × 24 screen of big four-colour letters. It works under MekkoGX’s start-up code, because that code keeps the BIOS’s zero page and vectors where cc65 expects them. It has no keyboard input; read the keypad yourself (@ch-pads).

#ex((path: "listings/c/conio.c", from: "void main(void)", n: 9), t-c)

#caution[cc65 keeps the console’s screen at `$3E20`–`$3FFF`, at the very top of RAM, where MekkoGX’s linker configuration puts the C stack unless you reserve the room. Link with `-Wl -D,__RESERVED_MEMORY__=0x1E0` or more. With nothing reserved, the stack is built on the screen, and every call writes on it.]

#shots("c-conio", "c-conio0", caption: [The console with `0x1E0` reserved, and with nothing reserved: the two marks low on the right are the stack.])
