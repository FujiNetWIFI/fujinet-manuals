#import "../lib.typ": *

= The 1802 Runtime <runtime>

Every program in this handbook starts with the same few hundred bytes: the runtime the cartridge’s own bring-up programs were written with, in the firmware’s `pico/studio2/testrom/`. The handbook carries it unchanged, in `listings/runtime/`, and adds two small files of its own.

#tbl((0.85in, 1fr),
  [*File*], [*Holds*],
  [`fujinet.inc`], [names: registers, the arena, the status page, the text engine],
  [`s2macro.inc`], [the macros and the runtime’s RAM],
  [`s2call.inc`], [the entry, the display interrupt, calls, the hand-over],
  [`fujilib.inc`], [the mailbox],
  [`fujidisp.inc`], [the text engine],
  [`input.inc`], [the keypads],
  [`s2defs.inc`], [the handbook’s: every device and command, and its macros],
  [`booklib.inc`], [the handbook’s: `go_ack`, `fn_str`, `pause`, `fail`],
)

== A program’s shape

#excerpt-at(auto, "listings/asm/clock.asm", "        CPU     1802", to: "; ASK cmd")

The equates come first, before any code. The runtime goes at `$0400`, where the BIOS starts a cartridge, and fills it to `$07FB`. The program’s own code starts at `$0C00`, and `S2CLAIM` puts `"FUJI"` at `$07FC` last of all.

== The registers

#tbl((0.5in, 1fr),
  [*Reg.*], [*Is*],
  [R0], [the 1861’s DMA pointer; only the interrupt sets it],
  [R1], [the interrupt routine],
  [R2], [the stack; X is 2],
  [R3], [the program counter],
  [R4, R5, R7], [call, return and jump],
  [R6], [the link: the caller’s return address],
  [R8, R9], [scratch: any routine may change them],
  [RA, RB, RC], [kept across calls: yours],
  [RD], [RD.0 counts the beep down; RD.1 is the runtime’s],
  [RE], [counts frames, sixty a second],
  [RF], [the hotspot pointer: the macros’ only],
)

== Starting up

The BIOS runs a cartridge by interpreting its first bytes in its own little language. The runtime’s first two, `$04 $02`, tell it to call machine code at `$0402`. From there `s2_entry` turns the interrupt off, sets up the registers above, points R1 at its own display interrupt and R0 at the cartridge’s picture, turns the interrupt back on and jumps to `main`.

== Calls

The 1802 has no call instruction. The runtime keeps three small routines for it, the _standard call and return technique_, in R4, R5 and R7:

#tbl((1.1in, 1fr),
  [*Macro*], [*Is*],
  [`FCALL adr`], [`SEP R4` and the address: a call. R6, the link, goes on the stack],
  [`FRET`], [`SEP R5`: back to the caller],
  [`FJMP adr`], [`SEP R7` and the address: a jump to anywhere],
)

D and DF go through a call and a return untouched, so a routine can take its argument and give its result in D.

== The display interrupt

The 1861 interrupts two scanlines before it starts fetching the picture. The runtime’s routine is shaped like the BIOS’s own, for the same reason: the first DMA fetch must find the 1802 between instructions.

#excerpt-at(auto, "listings/runtime/s2call.inc", "isrx:", n: 20)

It saves T and D, points R0 at the picture, counts the frame in RE and runs the beeper, then waits on EF1 until the 1861 has begun. The one `LBR` in it is marked `!3CYCLE`: it is the only long branch the runtime has, and it is where it is on purpose.

== The rules

The cartridge serves the bus in software, and a few things that are ordinary on other machines are wrong on this one. `checkrom.py` refuses each of them in every program it is shown:

- *No instruction from `$C0` to `$CF`.* The long branches and long skips, and `NOP`, take three machine cycles. If the 1861 asks for DMA during one, its line comes up a byte short. Leave a page with `FJMP` (Pages and Far Calls, page #pg(<pages>)).
- *No `IDL`* (`$00`). It reads memory through R0 on every cycle while it waits, and R0 points at the picture.
- *RF only with `LDN`.* The macros park RF on page `$0B` between hotspot reads. An `LDA`, `STR` or `SEX` through it would send the cartridge a byte you never meant.
- *X on console RAM.* `OUT` and `IRX` read M(R(X)); pointed at the cartridge, they read it.

== The mailbox calls

#tbl((0.8in, 1fr),
  [*Routine*], [*Does*],
  [`fn_chk`], [DF = 1 if a FujiNet cartridge answers],
  [`fn_beg`], [R9.1 device, R9.0 command, D parameters: begin],
  [`fn_pb`, `fn_pw`], [a one- or two-byte parameter, from D or R8],
  [`fn_txb`], [one byte of payload, from D],
  [`fn_path`], [a string from R8, padded to 256 bytes],
  [`fn_go`], [launch and wait: D = 0 or the error],
  [`fn_ack`], [D = 0 for ACK, `FNENAK` for NAK],
  [`fn_frames`, `fn_tick`], [a countdown in seconds, polled once a frame],
  [`fn_boot`], [arm a staged image and hand over],
  [`fn_config`], [back to CONFIG],
)

== The text calls

#tbl((0.8in, 1fr),
  [*Routine*], [*Does*],
  [`d_cls`], [clears the screen],
  [`d_at`], [the cursor to D: row in the high nibble],
  [`d_putc`, `d_puts`], [a character from D; a string from R8],
  [`d_hex`], [D as two hexadecimal digits],
  [`d_op`, `d_par`], [an operation; a parameter],
  [`d_rpl`, `d_rplpad`], [PRINT reply text: offset R8, at most D],
  [`in_scan`, `in_get`], [the key held; a key pressed],
)

== Building

`listings/asm/build.sh` builds a program in three steps: AS assembles it and writes a listing, `checkrom.py` reads the listing for the rules above, and `mkst2.py` packs the pages into `build/`_name_`.st2`. `./build.sh` alone builds them all.
