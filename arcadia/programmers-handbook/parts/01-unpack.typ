#import "../lib.typ": *

= Unpacking Your FujiNet Cartridge <unpack>

== Introduction

The FujiNet cartridge puts the EMERSON ARCADIA-2001 on the network. In the
console’s cartridge slot it is a cartridge like any other; inside it are two
small computers. The *game chip*, an RP2354A, answers every read the
console’s Signetics 2650 makes: it serves your program as a mask ROM would,
and beside it a _mailbox_ through which your program talks to the second
computer. The *network chip*, an ESP32-S3, is the FujiNet itself, the same
adapter that serves the Atari, the Apple II, the ColecoVision and a dozen
other machines, with its WiFi, its memory card and its network devices.

This handbook is for the programmer. It shows how a program written in 2650
assembly language reaches the network through that mailbox, one read at a
time, and it carries every command the FujiNet answers, each with a 2650
example. Assembly is the only language here because it is the only one there
is: no compiler, BASIC or C, has ever targeted the Arcadia.

#fig(labelled("images/render/board-inside.png", w: 2.4in,
  pad: (left: 1.6in, right: 1.6in, top: 4pt, bottom: 4pt), (
  (0.10, 0.045, -0.03, 0.03, [USB-C socket: power, \ and the network \ chip’s console], left),
  (0.11, 0.24, -0.03, 0.22, [microSD socket], left),
  (0.05, 0.49, -0.03, 0.47, [RESET and the \ service buttons], left),
  (0.48, 0.93, -0.03, 0.86, [Contacts: A0--A13, \ D0--D7, +5 V, ground], left),
  (0.81, 0.16, 1.03, 0.1, [Network chip \ (ESP32-S3): WiFi, \ the memory card, \ the FujiNet], right),
  (0.45, 0.26, 1.03, 0.29, [Lights], right),
  (0.57, 0.475, 1.03, 0.47, [Game chip (RP2354A): \ serves the console’s \ reads], right),
)), caption: [The FujiNet Arcadia board, Rev0, from the back])

== What you should have

- An ARCADIA-2001 and a FujiNet Arcadia cartridge -- or, until there is one,
  the FujiNet model of the cartridge in MAME (Section 2), which is what every
  program in this book was run on.
- A computer with Python 3 and the Macroassembler AS, which assembles the
  2650.
- A FujiNet to talk to: the cartridge’s own network chip, or fujinet-pc, the
  FujiNet firmware built to run on a computer, which is what MAME’s cartridge
  talks to.
- The listings that come with this handbook (`listings/`), which build every
  program it shows.

#note[No FujiNet Arcadia cartridge has been built yet. Everything in this
handbook was run on the cartridge’s model in MAME, which compiles the
cartridge’s own firmware sources, against a fujinet-pc built from the same
firmware. Where a real console may differ -- timing, mostly, and one bus
fight (Section 15) -- the text says so.]

== How this handbook is organised

*The machine*, Sections 2 to 9: the tools; the memory map; the mailbox, which
every later section leans on; the text display; the console’s 288 bytes of
RAM; the 2650 library the programs share; the 2650’s 8K pages, which shape
every program; and the hand controllers and the tone.

*The programs*, Sections 10 to 16, each built and run: first contact with
the adapter, the network device, a netcat, directories and booting, app keys
and the clock, programs bigger than the cartridge window, and the 2637 video
chip up close.

*The reference*, Sections 17 to 20: every command the FujiNet answers, with
the parameters it wants, the reply it sends and a 2650 example; then
everything the cartridge itself does.

*The games*, Sections 21 to 23: how Battleship, 5 Card Stud and CONFIG are
built. Then the things that cost real time, the Trouble Shooting Check List,
the Parts List, and four appendices with the quick reference, the codes and
the listings.

== Conventions

- Numbers with a `$` are hexadecimal, as AS writes them: `$2B00`.
- *The console* is the ARCADIA-2001; *the cartridge* is the FujiNet cartridge
  in its slot; *the adapter* is the network chip, or the fujinet-pc standing
  in for it.
- A *cell* is a place on the screen, row × 16 + column: cell `$A3` is row 10,
  column 3.
- The 2650’s registers are R0 to R3. The programs never select the second
  bank of R1 to R3.
- Every example in the text assembles: `tools/snipcheck.py` builds each one
  inside a program and checks the result (Section 26).
