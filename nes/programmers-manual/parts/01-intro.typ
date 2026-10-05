#import "../lib.typ": *

= Introduction

#lead[The FujiNet cartridge gives the Nintendo Entertainment System a network
adapter, a file server, a clock and a few hundred kilobytes of somebody else's
memory. This manual shows you how to use all of them from your own programs.]

== What you can do

Everything the FujiNet does for the Atari, the Apple II or the Intellivision,
it does for the NES. From a program running on the console you can:

#stars(
  [open a connection to any server on the Internet -- HTTP and HTTPS, TCP,
   UDP, Telnet, TNFS, FTP, SMB and more -- and read and write it a byte at a
   time;],
  [fetch a JSON document and pull single fields out of it, with the
   FujiNet doing the parsing;],
  [list the files on the SD card or on a network host, and load any NES
   cartridge image you find there into the cartridge's own memory and run it;],
  [keep a few bytes of your own -- a high score, a player name, a server
   address -- in an *app key* that survives a power cycle;],
  [read the time of day, generate a random number or a GUID, hash a block of
   data or turn it into a QR code;],
  [type on a Family BASIC or Subor keyboard, if you have one.],
)

== What you need

#runin(
  ("A FujiNet NES cartridge", [-- or something that behaves like one. At the
   time of writing the cartridge exists as firmware, a schematic and two
   emulators; no board has been built. Every program in this manual was run
   in an emulated NES talking to a real FujiNet firmware, and every screen
   shown was taken from it.]),
  ("cc65", [the 6502 C compiler, assembler and linker, version 2.19.]),
  ("fujinet-lib", [for the C programs: the `add-nes` branch of
   fujinet-lib-experimental, which carries the NES target.]),
  ("A FujiNet to talk to", [-- fujinet-pc, the FujiNet firmware built for a
   PC, or the one built into FujiNet Go NES Desktop.]),
)

Chapter 3 shows how to put them together.

== How this manual is arranged

Chapters 2 to 5 are the foundation: what the cartridge is, how to build a
program, the *mailbox* through which every byte passes, and a first program
that talks to the FujiNet. Read them in order.

Chapters 6 to 9 take the FujiNet's devices one at a time -- the network, the
Fuji device that manages WiFi, hosts, disks and app keys, the business of
booting an image, and the clock. Each command is described on a *command
card* with the parameters it takes and the reply it sends, followed by the
same call in assembly and in C.

Chapter 10 describes the two libraries, and Chapter 11 the things about the
NES itself -- the PPU, the vblank NMI and the controllers -- that every
network program runs into.

Chapters 12 to 16 take apart real programs: the four FujiNet network games
that have been ported to the NES, and CONFIG, the program the cartridge runs
when you turn the console on. The appendices hold the error codes, a quick
reference, the full listings with numbered callouts, and a network terminal
to finish with.

== The two roads

Every example in this manual is given twice, side by side:

#pair("; 6502 assembly, ca65
        CALL    FNDEVF, FNCADPX, 0
        jsr     fn_go
        jne     fail",
"/* C, cc65 and fujinet-lib */
if (!fuji_get_adapter_config_extended(&acx))
  fail();")

The assembly road talks to the mailbox directly, through a short library of
store-and-wait routines; you see every byte that goes to the cartridge. The C
road uses fujinet-lib, which hides the mailbox behind the same `fuji_` and
`network_` calls a FujiNet program uses on every other computer, so the code
moves between platforms. Neither road is the "real" one. The assembly road
is how the C library works inside.

== Conventions

Numbers written with a `$` are hexadecimal: `$5000` is 20480. Register
numbers, command numbers and device numbers are always given in hexadecimal,
as the firmware's own sources give them.

#hilite("Caution"): marks something that will cost you an afternoon if you
get it wrong.

#note[marks something worth knowing that will not hurt you.]

The programs in Chapters 5 to 9 are in the `listings/` directory beside this
manual, in `asm/` and `c/`, with a Makefile that builds all of them.
