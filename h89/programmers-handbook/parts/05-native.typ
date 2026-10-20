#import "../lib.typ": *
#import "../prog.typ": *

#chapter(5, "Assembly on the H89 Itself")

#section("General")[
Both systems came with an assembler. HDOS's Software Tools diskette has Heath's ASM, and CP/M has
Digital Research's ASM and LOAD. With them a FujiNet program can be written, assembled and run
without leaving the H89, as programs were in 1980.

Both assemblers know only the 8080's instructions: the Z80 runs every one of them, but the Z80's own
additions --- relative jumps, DJNZ, the IX and IY registers, block moves, the two-byte `LD`
instructions --- are not available. So the programs in this chapter are written in 8080 code, which
is longer, and neither assembler has macros. But they talk to the FujiNet exactly as the Z80
programs do, and their output is byte for byte what the book's cross-assembler makes from the same
source.

This chapter shows one small program in each system's assembler: FNVERH for HDOS and FNVER for
CP/M. Each sets the card up, as `card_on` does (Chapter 2), and makes one complete FujiBus exchange
in 8080 code --- the request FUJI_GET_ADAPTERCONFIG, built, checksummed, framed and sent, and the
reply taken, unescaped and checked --- and prints the FujiNet's network and firmware version.
]

#section("Heath's ASM, Under HDOS")[
#sub("What you need")
- HDOS 2.0, and from the *Software Tools* diskette: ASM.ABS (issue \#104.06.00), HOSDEF.ACM, which
  names HDOS's system calls, and ASCII.ACM, which names the control characters.
- A diskette for your work, in SY1:, with room for the program, its listing, and those three files if
  SY0: has no room for them (the book's boot disk had none).

#sub("Assembling")
ASM takes an HDOS command line: the program to make, the listing, an equals sign, and the source:

#code("SY1:ASM SY1:FNVERH,SY1:FNVERH=SY1:FNVERH")

Each name takes its usual extension (.ABS, .LST, .ASM). With no listing named, ASM shows any errors on
the console; with one, they go in the listing, and the console shows only the totals. ASM makes the
.ABS file itself, header and all: there is no separate load step. Run with nothing after its name, it
shows its banner and asks with `*`.

#steps(
  [Mount the work diskette: #typed("MOUNT SY1:") #ret.],
  [Assemble: #typed("SY1:ASM SY1:FNVERH,SY1:FNVERH=SY1:FNVERH") #ret. ASM takes about 80
   seconds.],
  [Run it: #typed("SY1:FNVERH") #ret.],
)

#session("native-fnverh-run", rows: (13, 23))

HDOS prints the version in capitals: its console turns lower case to upper unless a program says
otherwise, and FNVERH leaves HDOS alone.

#sub("Heath's assembly language")
The book's programs keep to these rules, which differ from both z88dk's and Digital Research's:

- A label starts in column 1, and needs no colon. Labels may be up to 7 characters long, and may hold
  `.` and `$` (as HDOS's own `.PRINT` and `S.TIME` do). Use capitals: lower case is allowed only in
  quotes.
- A whole-line comment starts with `*` in column 1. After the operand, everything past the first blank
  is a comment, with no `;` --- so an operand may contain no blanks at all. `MVI A,HEX AND 0FH`
  quietly assembles as `MVI A,HEX`.
- Numbers are decimal unless they end in Q or O (octal), A (split octal: `42200A` is 042.200, which is
  2280H), B (binary) or H (hexadecimal, starting with a digit). The location counter is `*`.
- Expressions use `+ - * /`, worked strictly from left to right, with no parentheses.
- Strings are in single quotes. `DB 'X'+200Q` sets the top bit of the last character, which ends a
  string for HDOS's `.PRINT`.
- `SCALL` is built in: `SCALL .PRINT` assembles as RST 7 (377Q) and the call's number (003Q).
  HOSDEF.ACM only names the numbers, and it sets the location counter itself (`ORG 0`), so `XTEXT
  HOSDEF` must come *before* the program's own `ORG`.
- `END` must name the entry point.

#caution[Heath's `IF` assembles the lines that follow when its expression is *zero*, the opposite of
DRI's. The book's programs use no `IF`.]
]

#section("Digital Research's ASM, Under CP/M")[
Heath's CP/M 2.2.04 has ASM and LOAD on its system diskette. ASM reads the source and writes a .HEX
file and a .PRN listing; LOAD turns the .HEX into a .COM file to run.

#steps(
  [With the source in drive B, type #typed("ASM B:FNVER") #ret. ASM says what it is, the next free
   address after the program, how full its symbol table got, and END OF ASSEMBLY, with any errors
   above, a line each.],
  [Type #typed("LOAD B:FNVER") #ret. LOAD reports the program's first and last addresses and how
   many 128-byte records it wrote.],
  [Run it: #typed("B:FNVER") #ret.],
)

#session("native-fnver-run", rows: (5, 23))

The assembly took 30 seconds and the LOAD 8. DRI's language is the one most 8080 books use: labels as
long as you like, with a colon after an instruction label; `;` for comments, anywhere; `$` the
location counter; operators with the usual precedence and parentheses; `IF` and `ENDIF`.

#caution[DRI's ASM accepts `ELSE` without a word and does nothing with it: both branches are
assembled.]
]

#section("A FujiBus Exchange in 8080 Code", balance: false)[
FNVER and FNVERH do the whole of `fn_call`'s work, for one request, in about 220 lines. In order:

+ Set the card up, as `card_on` does: the mode word C0H, then a read of port A.
+ Build the packet `70 E8 06 00 00 00` and work out its checksum (an 8-bit sum with end-around carry:
  `ADD M`, then `ACI 0`), giving `70 E8 06 00 5F 00`.
+ Send it between two C0H bytes, escaping any C0H or DBH inside, a byte at a time, each when /OBF
  says the last was taken.
+ Take the reply up to its closing C0H, turning DB DC and DB DD back into C0H and DBH, giving up
  after 15 seconds of the 2 ms clock (7,500 ticks).
+ Check the reply: its length word against the bytes received, its checksum (with byte 4 counted as
  0), ACK rather than NAK, and at least 146 bytes.
+ Print the network's name (from offset 0 of the data) and the firmware's version (offset 125).

The reply the FujiNet sent contained the escape pair DB DC (a C0H in a MAC address), so the
unescaping was exercised.

#sub("From Z80 to 8080")
These are the substitutions the 8080 programs make for what the book's Z80 library does:

#stable((1.25in, 1.4in, 1fr), size: 7.2pt,
  th[Z80], th[8080], th[Note],
  [`JR`, `JR Z` ...], [`JMP`, `JZ` ...], [no relative jumps; 3 bytes each],
  [`DJNZ loop`], [`DCR B` / `JNZ loop`], [],
  [`IN A,(PORTC)`], [`IN PORTC`], [A and a fixed port only],
  [`LD (nn),SP`], [`LXI H,0` / `DAD SP` / `SHLD nn`], [],
  [`LD SP,(nn)`], [`LHLD nn` / `SPHL`], [],
  [`LD DE,(nn)`], [`XCHG` / `LHLD nn` / `XCHG`], [only HL loads a word directly],
  [`SBC HL,DE`], [six byte instructions], [or count down instead],
  [`LDIR`], [a loop], [],
  [`IX`, `IY`, `BIT n,r`], [memory; `ANI mask`], [],
  [`LD A,n`, `LD A,(HL)`], [`MVI A,n`, `MOV A,M`], [],
  [`CP n`], [`CPI n`], [8080 `CP` is *call if plus*],
  [`JP nn`], [`JMP nn`], [8080 `JP` is *jump if plus*],
  [`ADC A,0`], [`ACI 0`], [the checksum's carry],
  [`PUSH AF`], [`PUSH PSW`], [],
  [`EX DE,HL`], [`XCHG`], [],
  [SCALL macro], [`SCALL fn` (Heath only)], [neither ASM has macros],
)

#warning[The 8080's `JP` and `CP` are *jump if plus* and *call if plus*. A Z80 habit, `JP label` or
`CP 3`, assembles without a word of complaint and does something quite different.]

#sub("The same bytes")
Both programs were also assembled by z88dk-z80asm in 8080 mode (`-m8080`), from the same
source with only the dialect changed. The results are identical, byte for byte: every byte of ASM's
.HEX files and LOAD's .COM files, and every code byte of Heath ASM's .ABS files. (Heath's ASM also
writes the space reserved by `DS` into the .ABS file, filled with whatever was in its buffer, where
the others leave it out.)
]

#section("The Listings", balance: false)[
These are the assemblers' own listings, as they came off the work diskettes: FNVERH from Heath's ASM,
with its split-octal addresses, octal bytes and statement numbers (the lines of HOSDEF.ACM and
ASCII.ACM are not listed, so the numbers jump); FNVER from DRI's, in hexadecimal. In FNVERH, notice
`XTEXT` before `ORG`, the octal numbers, and `.PRINT` with its strings ending in `'...'+200Q` or
`ENL` (a new line with the top bit set).

#plisting("native-fnverh", size: 5.8pt)
#plisting("native-fnver", size: 6.2pt)
]
