#import "../lib.typ": *
#import "../prog.typ": *

#chapter(4, "Assembly Language")

#section("General")[
The H89's processor is a Z80, and Z80 assembly language is the most direct way to drive the
FujiNet. This chapter shows how to write a FujiNet program in it, assemble it on a modern computer
with z88dk's assembler, carry it to the H89, and run it under HDOS or CP/M --- the same source file
for both.

It also introduces the book's assembly library: a handful of include files that hide the
differences between HDOS and CP/M, start the card, and make a complete FujiBus exchange with one
call. Every assembly program in this Manual uses it, and it is listed in full at the end of the
chapter.

Why assemble somewhere else? Neither HDOS nor CP/M came with a Z80 assembler: Heath's ASM and
Digital Research's ASM know only the 8080's instructions, which the Z80 runs but which cannot use
its extra registers and instructions. Chapter 5 shows how to use them anyway. A modern computer
also makes editing, and keeping your work, much easier, and the FujiNet makes moving the result to
the H89 a matter of seconds.
]

#section("Setting Up z88dk")[
z88dk is a free development kit for Z80 computers, with a C compiler (Chapter 6), an assembler and
linker (z88dk-z80asm), and tools for making disk images. It knows both HDOS and CP/M.

#steps(
  [Get z88dk from #text(font: f-sans, size: 0.9em)[z88dk.org]: a nightly build for Windows or macOS,
   or the source for Linux. This Manual used v2.4-1231.],
  [Put z88dk's `bin` directory on your `PATH`, and point `ZCCCFG` at its `lib/config` directory.
   On Linux, for example: \
   `export PATH=$HOME/z88dk/bin:$PATH` \
   `export ZCCCFG=$HOME/z88dk/lib/config`],
  [Check it: `z88dk-z80asm` with no arguments prints its options.],
  [Get the book's sources, which include the library in `src/asm/inc`, from the fujinet-manuals
   repository (see the inside front cover), in `h89/programmers-handbook`.],
)
]

#section("A First Program")[
Here is FNHELLO, the shortest useful FujiNet program. It starts the card, asks the FujiNet for its
adapter configuration (Chapter 8), and prints four things from the reply:

#plisting("fnhello", size: code-size)

Notice its shape, which every program in this Manual shares:

+ `os.inc` comes first. It sets where the program loads, writes the .ABS header for HDOS, and
  supplies the start-up code, which calls `main`.
+ `fujinet.inc` names the ports, the protocol's codes, and every device and command.
+ `main` is the program. When it returns, the program ends and the console is put back as it was.
+ The request is a block of data, `rq_config`, made with the `FNREQ` and `FNBUF` macros. `fn_call`
  sends it and takes the reply.
+ The library's code comes last: `card.inc`, `fujibus.inc`, `con.inc`, and `tail.inc`, which must
  be the very last, because it marks where the program ends.
]

#section("Assembling")[
One command makes the HDOS program, and another the CP/M one. From the `programmers-handbook`
directory:

#code("z88dk-z80asm -b -DHDOS -Isrc/asm/inc -oFNHELLO.ABS src/asm/hello/fnhello.asm
z88dk-z80asm -b -DCPM  -Isrc/asm/inc -oFNHELLO.COM src/asm/hello/fnhello.asm")

- `-b` makes a binary file, ready to run, rather than an object file to link.
- `-DHDOS` or `-DCPM` defines the symbol that `os.inc` tests, to choose the system.
- `-I` says where the include files are.
- `-o` names the output.

Add `-l` for a listing, which shows the address and bytes of every line; it is a great help when
something goes wrong. The book's `tools/asm.sh hdos FNHELLO src/asm/hello/fnhello.asm` does all
of this and puts the program in `build/bin/hdos/asm`.

#note[z88dk-z80asm writes numbers the modern way, 0x70 for hexadecimal, but it also accepts 70H
and the octal 160Q, so a line copied from a Heath listing assembles as it stands.]
]

#section("Carrying It to the H89")[
The program needs to be on a disk the H89 can read. There are two easy ways.

#sub("On a FujiNet drive")
Put the program on a disk image, put the image on the FujiNet's microSD card (or a TNFS server you
run), and mount it in a FujiNet drive with CONFIG. The book's tools make the images:

#code("tools/hdosdisk.sh FNHELLO.H8D \"BOOK PROGRAMS\" FNHELLO.ABS     (HDOS)
tools/cpmdisk.sh  FNHELLO.H8D FNHELLO.COM                       (CP/M)")

The HDOS image comes from fujinet-h89's `hdosfs.py`; the CP/M one from z88dk's `z88dk-appmake
+cpmdisk -f hz89`, with fujinet-h89's `cpm-dir-fixup.py` to mark the empty directory entries the
way Heath's CP/M expects. Both make a 100K, 40-track H17 image.

#sub("On FujiNet Go H89")
The emulator takes the same images in its drives, or reads a host directory. Either way, the
program runs exactly as it will on the real machine.
]

#section("Running FNHELLO")[
#steps(
  [Boot HDOS. Mount the disk with FNHELLO on it: here it is in the H17's second drive.],
  [Type #typed("MOUNT SY1:") #ret, then #typed("RUN SY1:FNHELLO.ABS") #ret.],
)

#session("fnhello-hdos", rows: (14, 22))

#steps(
  [Under CP/M, with the disk in drive B, type #typed("B:FNHELLO") #ret.],
)

#session("fnhello-cpm", rows: (7, 12))

The network's name, the FujiNet's name and address, and the version of its firmware: the FujiNet
is answering. If FNHELLO says "No FujiNet card at 0D0H," the card is missing, or set to other
ports; if it says "The FujiNet did not answer," it is there but not talking. The Operation
Manual's troubleshooting chart covers both.
]

#section("The Program on HDOS")[
For HDOS, `os.inc` begins the program at 2278H with the eight-byte header HDOS expects of an
.ABS file, so that the code itself starts at 2280H, where HDOS loads programs:

#code("        org     0x2278                  ; HDOS loads programs at 2280H:
        defb    0xFF, 0x00              ; the .ABS header, 8 bytes, comes first
        defw    start                   ; load address
        defw    prog_end - start        ; length
        defw    start                   ; entry point")

HDOS's services are *system calls*: a `RST 38H` instruction followed by a byte that says which
service. The library's `SCALL` macro writes both. It uses these:

#stable((0.65in, 0.4in, 1fr),
  th[Call], th[Code], th[Does],
  [.EXIT], [00H], [Back to HDOS. A = 0.],
  [.SCIN], [01H], [A key from the console into A; carry set if none is waiting.],
  [.SCOUT], [02H], [The character in A to the console.],
  [.READ], [04H], [Read BC bytes (whole sectors) from channel A into DE; carry at the end.],
  [.WRITE], [05H], [Write BC bytes (whole sectors) from DE to channel A.],
  [.CONSL], [06H], [Set console bits: A = which byte, B = the bits, C = which bits to change.],
  [.OPENR], [22H], [Open file HL for reading on channel A; DE = default name parts.],
  [.OPENW], [23H], [Open file HL for writing on channel A.],
  [.CLOSE], [26H], [Close channel A.],
)

The Appendix lists the rest. At the start, `os.inc` saves the stack pointer, which HDOS leaves
pointing at the command line's arguments, and uses `.CONSL` to put the console in raw character
mode: no echo, no CTRL-C handling, no wrapping at 80 columns and no mapping of lower case to upper.
That lets a program send the H19 escape sequences and graphics characters untouched. `exit` puts
the console back as it found it.

HDOS files are read and written a 256-byte sector at a time; `f_read` and `f_write` move any
number of bytes through a sector buffer, and `f_close` pads the last sector with zeros.
]

#section("The Program on CP/M")[
For CP/M, `os.inc` begins the program at 0100H, as CP/M requires, and gives it its own 256-byte
stack: the one the CCP leaves is only a few words deep. The console goes through BDOS function 6,
"direct console I/O," which neither echoes nor stops for CTRL-S. `exit` jumps to 0000H, which
reloads the CCP.

CP/M files are read and written a 128-byte record at a time, through a file control block. `f_open`
and `f_create` fill one in from a name such as `B:FILE.TXT`; `f_close` pads the last record with
CTRL-Z (1AH), CP/M's end-of-text mark.
]

#section("The Library")[
These are the routines a program can call. Unless it says otherwise, a routine may change A and
the flags, and keeps BC, DE and HL.

#stable((0.62in, 1fr),
  th[Routine], th[Does],
  [`main`], [Yours: the program. Return to end it.],
  [`exit`], [End the program now.],
  [`conout`], [A to the console, raw.],
  [`conin`], [A key into A, with carry clear; carry set if no key is waiting.],
  [`getkey`], [Wait for a key; A = the key.],
  [`print`], [HL points at NUL-terminated text: print it. HL is changed.],
  [`crlf`], [Carriage return and line feed.],
  [`getline`], [Read a line into HL (B = room), shown as typed, ended by RETURN, stored with a NUL.],
  [`args`], [HL points at the command line's arguments, NUL-terminated.],
  [`f_create`, `f_open`], [Open file HL (`SY1:NAME.EXT` or `B:NAME.EXT`) to write or read; carry if
    it failed.],
  [`f_write`], [Write BC bytes from DE.],
  [`f_read`], [Read up to BC bytes into DE; BC = how many came, 0 at the end of the file.],
  [`f_close`], [Finish and close the file.],
  [`phex8`, `phex16`], [Print A, or HL, in hexadecimal.],
  [`pdec8`, `pdec16`], [Print A, or HL, in decimal.],
  [`pip`], [Print the 4 bytes at HL as an IP address.],
  [`ptext`, `phexs`, `pdump`], [Print BC bytes at HL as text, as hex on one line, or as a dump.],
  [`strlen`], [BC = the length of the string at HL.],
  [`card_on`], [Set up the card unless a program already has (Chapter 2); face the bus toward the H89.],
  [`card_present`], [Z if the card is there and running.],
  [`fn_call`], [Make one FujiBus exchange (see below).],
  [`fn_send`], [Send a request and wait for no reply (the modem's, which are not framed).],
  [`fn_raw`], [Take unframed bytes (the modem's) into DE, BC = room, until 200 ms of quiet.],
)
]

#section("Making a Request")[
`fn_call` takes HL pointing at a *request block*, sends the request, and takes the whole reply. A
request block is two lines, which follow the order of the request's header:

#code("rq_name:
        FNREQ   device, command, descriptor, aux1, aux2, aux3, aux4
        FNBUF   payload, payload length, reply buffer, reply size")

- *descriptor* is one of `F_NONE` through `F_C1234` (Chapter 3), and says how many of aux1 to aux4
  are sent. A word goes in aux1 and aux2, low byte first, as `F_B12` sends it.
- *payload* and *payload length* give data to send after the fields: 0, 0 for none.
- *reply buffer* and *reply size* say where the reply's data goes and how much room there is:
  0, 0 if no data is expected.

`fn_call` returns:

#stable((0.55in, 1fr),
  th[], th[On return],
  [A], [`FN_OK` (0) for ACK, `FN_NAK` (1), `FN_TIMEOUT` (2) or `FN_BAD` (3), a reply that was
    garbled or from the wrong device.],
  [Z], [Set for ACK, so `jr nz,failed` follows a call.],
  [BC], [How many data bytes the reply carried, even if that was more than the buffer.],
  [Carry], [Set if the reply was longer than the buffer. The rest was read and dropped.],
)

`fn_res` and `fn_len` keep A and BC, and `fn_rep` the reply's six-byte header. Other registers are
changed.

A program that needs a different field or length each time stores it into the block before the
call. The offsets are named `RQ_DEV` through `RQ_RMAX` in `fujinet.inc`. NETCAT does this for every
read, with the length the FujiNet says is waiting:

#snip("netcat.loop", "asm", caption: [NETCAT.ASM --- the length goes into the request block])

If no reply comes, `fn_call` gives up (Chapter 2's table), and the next call first takes and
throws away anything that comes late. The FujiNet is never left half way through an exchange.
]

#section("Debugging")[
When a FujiNet program does not work, the first question is: what went over the bus? On FujiNet Go
H89 the answer is easy, because the emulator can log every byte. On a real H89 the FujiNet's own
log, over its USB port at 115,200 baud (Chapter 9 of the Operation Manual), shows every request
the firmware received and what it did.

For the program itself, HDOS has DBUG and CP/M has DDT. Both are 8080 debuggers: they will step
through Z80 code, but show the Z80's extra instructions as data. A listing from `-l` tells you
where to set breakpoints.

#chart(
  [The program hangs at its first request.], [The card was never started (call `card_on`), or it is
    set to other ports.],
  [Every request times out.], [A request is malformed --- usually the length --- so the FujiNet says
    nothing (Chapter 3).],
  [The FujiNet restarts (its drives disappear).], [A request was missing a field the command needs.],
  [Replies are shifted, or from the wrong command.], [A reply was not read to its end. Use `fn_call`,
    which always reads to the end.],
  [Text comes out in capitals under HDOS.], [The console is mapping lower case to upper. `os.inc`
    turns this off; a program that does its own start-up must too.],
  [Under CP/M, a program's first keys are lost.], [Heath's BIOS keeps no type-ahead while a program
    is busy. Poll the keyboard more often.],
)
]

#section("Listing of the Library", balance: false)[
#plisting("library")
]
