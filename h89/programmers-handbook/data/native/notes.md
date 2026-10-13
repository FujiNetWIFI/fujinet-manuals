# Chapter 5 notes: assembling on the H89 itself

Everything here was done on FujiNet Go H89's headless machine (h89_session_run,
real-time, not --warp) against the book's rig (fujinet-pc built from fn-h89,
via tap.py), with the book's own boot disks. `tools/native.sh` redoes all of
it; `tools/native.sh check` redoes only the cross-check.

## What is where

| File | What |
|---|---|
| `src/native/FNON.ASM` | DRI ASM, CP/M. FujiNet Go H89's FNON (tools/disks/fnon, 8dc059d), code unchanged; two original lines are 75/76 columns. |
| `src/native/FNONH.ASM` | Heath ASM, HDOS. The same program; `.PRINT`, `.EXIT`. |
| `src/native/FNVER.ASM` | DRI ASM, CP/M. FUJI_GET_ADAPTERCONFIG, prints SSID + firmware version. 242 lines. |
| `src/native/FNVERH.ASM` | Heath ASM, HDOS. The same. 236 lines. |
| `data/native/*.LST, *.PRN` | The assemblers' listings, pulled off the work disks (NULs and ^Z removed; Heath's form feeds kept). |
| `data/native/timing.txt` | Emulated time of each assembly. |
| `data/native/xcheck.txt` | The z80asm cross-check. |
| `data/native/probes/` | Syntax probes: sources, listings, console screens (evidence for the facts below). |
| `screens/native-<name>-asm.json`, `-run.json` | The kept screens (fnon, fnver, fnonh, fnverh). |
| `build/native/` | FNON.COM/.HEX, FNVER.COM/.HEX, FNONH.ABS, FNVERH.ABS as they came off the disks; `z80asm/` the cross-check copies. |

The four programs are pure 8080 (z80asm -m8080 accepts every line).
FNVER/FNVERH: start the card if EN is low (FNON's code), send
`C0 70 E8 06 00 5F 00 C0` (checksum computed, every byte SLIP-escaped if
needed), take the reply until its closing END with SLIP unescaping, a 15 s
timeout counted in 2 ms TICKS, then check length word = bytes received,
checksum (byte 4 counted as 0), NAK (15H) vs ACK (06H), and >= 146 bytes;
print SSID (payload offset 0, 33 bytes) and fn_version (offset 125, 15
bytes), each up to its NUL. Messages: `No reply` / `Bad reply` /
`FujiNet said NAK`. The tap log (`build/runs/native-fnver*-asm/tap.jsonl`)
shows the request exactly as above and a 146-byte reply that contains
`DB DC` (an escaped C0H in the MAC/BSSID), so the unescape path ran.

## The sessions (typed text is after the prompt)

Work disks: HDOS, a 100K data disk in SY1: holding ASM.ABS, HOSDEF.ACM,
ASCII.ACM (from `HDOS_2_0_Software_Tools.h17disk`) and the source; CP/M, a
100K disk in B: holding only the source. Boot: `build/disks/hdos-fn.h8d`
(HDOS 2.0, 56K) or `build/disks/cpm62.h8d` (62K CP/M 2.2.04, has ASM.COM
and LOAD.COM).

HDOS (FNONH; FNVERH the same with its name):

    >MOUNT SY1:
    VOLUME 000, MOUNTED ON SY1:
    LABEL: NATIVE ASSEMBLY
    >SY1:ASM SY1:FNONH,SY1:FNONH=SY1:FNONH


    00154 STATEMENTS ASSEMBLED
    40215 BYTES FREE
     NO ERRORS DETECTED

    >SY1:FNONH
    FUJINET ENABLED
    >SY1:FNONH
    FUJINET ALREADY ON

    >SY1:ASM SY1:FNVERH,SY1:FNVERH=SY1:FNVERH
    00329 STATEMENTS ASSEMBLED
    39933 BYTES FREE
     NO ERRORS DETECTED
    >SY1:FNVERH
    NETWORK:  DUMMY CAFE          (screen kept as WORKSHOP)
    FIRMWARE: V1.6-7D7A3BA

ASM prints nothing but two blank lines and the three totals; the statement
count includes the XTEXT'd lines (HOSDEF 65, ASCII 28). The listing file
has the same totals in mixed case ("00154 Statements Assembled").

CP/M (FNVER; FNON the same):

    A>ASM B:FNVER
    CP/M ASSEMBLER - VER 2.0
    03E4
    002H USE FACTOR
    END OF ASSEMBLY

    A>LOAD B:FNVER
    FIRST ADDRESS 0100
    LAST  ADDRESS 02D9
    BYTES READ    01DA
    RECORDS WRITTEN 04

    A>B:FNVER
    Network:  Dummy Cafe          (screen kept as Workshop)
    Firmware: v1.6-7d7a3ba

FNON: `016A` / `000H USE FACTOR`; LOAD `LAST  ADDRESS 0169`,
`BYTES READ    006A`, `RECORDS WRITTEN 01`; runs `FujiNet enabled`, then
`FujiNet already on`.

`03E4` is the next free address after the program (here after its DS
areas, i.e. the top of FNVER's stack); USE FACTOR is how full ASM's symbol
table got (hex).

## How long (emulated)

From the RETURN that starts the command to the prompt coming back, read
from the emulated 2 ms timer with the debugger (`--debug timer`, which
counts whether or not the CPU takes the interrupt, so H17 I/O with
interrupts off is included). It includes loading the assembler.

| Program | Assembler | Assembly | LOAD |
|---|---|---|---|
| FNON (60 lines) | DRI ASM 2.0, CP/M | 8128 ticks = 16.3 s | 2944 ticks = 5.9 s |
| FNVER (242 lines) | DRI ASM 2.0, CP/M | 16064 ticks = 32.1 s | 3936 ticks = 7.9 s |
| FNONH (61 lines + 93 XTEXT'd) | Heath ASM, HDOS | 23736 ticks = 47.5 s | -- |
| FNVERH (236 lines + 93 XTEXT'd) | Heath ASM, HDOS | 43784 ticks = 87.6 s | -- |

(`data/native/timing.txt`. Repeat runs agree within a few ticks for CP/M;
an earlier HDOS run of the same programs with 3 fewer comment lines took
45.0 s and 85.3 s.)

Heath's ASM is much the slower: two passes, and HOSDEF.ACM and ASCII.ACM
are read again on each, all on the H17. Sizes: FNONH 101 bytes, FNVERH 439
bytes of code + 200 of DS; FNON 106 bytes (1 record), FNVER 474 bytes (4
records).

## Cross-check (z88dk-z80asm -m8080)

```
z88dk-z80asm -m8080 cross-check (Z80 Macro Assembler 25085-3bd06cad56-20260712)
compare FNON.COM: HEX 0100H-0169H (106 bytes), COM 128 bytes (1 records)
  HEX vs z80asm -m8080: identical
  COM vs HEX:           identical
  z80asm beyond 0169H:  0 bytes, all zero (the DS areas)
compare FNVER.COM: HEX 0100H-02D9H (474 bytes), COM 512 bytes (4 records)
  HEX vs z80asm -m8080: identical
  COM vs HEX:           identical
  z80asm beyond 02D9H:  266 bytes, all zero (the DS areas)
compare FNONH.ABS: header FF 00, load 2280H, length 101, entry 2280H
  code vs z80asm -m8080: identical (101 bytes compared, 0 in DS areas skipped)
  z80asm length 101, ABS length 101: same
compare FNVERH.ABS: header FF 00, load 2280H, length 639, entry 2280H
  code vs z80asm -m8080: identical (439 bytes compared, 200 in DS areas skipped)
  z80asm length 639, ABS length 639: same
FNON.COM: identical to FujiNet Go H89's shipped tools/disks/fnon/FNON.COM
```

All four: byte for byte identical.

The converted sources are in `build/native/z80asm/`. The conversion
(`tools/native.py z80 dri|heath`) changes only what the dialects force:
strings to double quotes, labels get colons, Heath's comment field gets a
`;`, Heath numbers to decimal, `SCALL x` to `RST 7`/`DB x`, XTEXT'd .ACM
files reduced to EQUs, END's operand dropped. z80asm takes Intel 8080
mnemonics in -m8080 mode unchanged.

What is compared: CP/M, every byte of ASM's .HEX against z80asm's byte at
that address, and LOAD's .COM against the .HEX (the .COM is padded to whole
128-byte records with whatever LOAD's buffer held). HDOS, the .ABS header
(FF 00, load 2280H, length, entry = END's operand) and its bytes, except the
DS areas: **Heath's ASM writes DS space into the .ABS** (FNVERH's length,
639, runs to the end of `REPLY DS RMAX`), filled with leftovers from its
output buffer; DRI's ASM leaves DS out of the .HEX.

## Heath ASM (HDOS 2.0 Software Tools, ASM.ABS #104.06.00)

Banner `HDOS ASSEMBLER ISSUE #104.06.00.`; listing header
`HEATH ASM #104.06.00` / `12-Oct-80  Page    1` (HDOS's date). ASM.ABS
loads at 2280H, 8071 bytes, entry 3B6CH. Evidence: the probes in
`data/native/probes/` (T2-T5, listings `*.LST`, screens `e4-*.txt`).

Running it
- HDOS command-line style: `ASM binary,listing=source`. The defaults are
  SY0: and .ABS / .LST / .ASM (the string `SY0ABSSY0LSTSY0ASM` in ASM.ABS;
  we always named the device and let the extensions default). We typed
  `SY1:ASM SY1:FNONH,SY1:FNONH=SY1:FNONH` (HDOS runs SY1:ASM.ABS by its
  name; no RUN needed) -> SY1:FNONH.ABS and SY1:FNONH.LST.
- No listing named (`ASM SY1:T4=SY1:T4`): the error lines are shown on the
  console (`F  042.202  000  00100  L8CHARSX  NOP`). With a listing, the
  console gets only the totals and the errors go to the listing.
- No arguments: the banner, then a `*` prompt; type the same
  `binary,listing=source` line (e4-asm-prompt.txt).
- Other switches seen in ASM.ABS's strings, not tried: /PAGE: /FORM: /WIDE
  /LARGE /ERR /LON: /LOF:, and an XREF run (XREF.ABS).
- .ABS written directly: `FF 00`, load address (the ORG), length, entry
  (END's operand). No LOAD step.
- Listing: split-octal address, up to 3 octal bytes, 5-digit statement
  number, the source; error letters in columns 1-2; XTEXT'd lines are not
  listed (numbers jump: FNVERH's XTEXT HOSDEF is 00017, the next line
  00083).

Source format
- Label in column 1, no colon needed (a colon is accepted and dropped:
  `COLON: NOP` defines COLON; `JMP COLON:` is an A error). A line without a
  label starts with a blank; ` INDENT NOP` makes INDENT the opcode (O).
- Labels: at most 7 characters (`L7CHARS` and `L7CHARX` are distinct; an
  8-character label is an F error and is cut to 7, so `B1234567`/`B1234568`
  collide, D). `.` and `$` are allowed (`.DOT`, `$DOL`, `LBL.X`), as in
  HDOS's own `.PRINT`, `S.TIME`, `$SAVALL`. The book's programs keep to 6.
- Upper case only: `mvi a,1` is an O error. Lower case is fine inside
  quotes (`'Ef lower'`, `'x'`).
- Comments: `*` in column 1 for a whole line. `;` in column 1 is NOT a
  comment (F O errors). After the operand, everything past the first blank
  is comment -- no `;` needed (Heath style uses none). Hence no blanks in an
  operand: `MVI B, 1` and `MVI B ,1` are A errors, and `MVI A,HEX AND 0FH`
  silently assembles as `MVI A,HEX`. Surplus operands are ignored without a
  word (`MOV A,B,C` = `MOV A,B`).
- Numbers: decimal by default; suffix D decimal, Q or O octal, A split
  octal (`42200A` = 042.200 = 2280H; `40A` = 32), B binary, H hex (must
  start with a digit: `0D0H`; `$D0` is an error). Character constants
  `'A'`; two characters make a word (`LXI H,'AB'` = 4142H).
- `*` is the location counter (`SYDD EQU *` in HOSEQU); `$` is not.
- Operators: `+ - * /` and unary minus, evaluated strictly LEFT TO RIGHT
  (`042200A-042200A/256*256` = 0, not 200Q). No parentheses (`(5+3)/2` is
  an A error); `& ! \ < >` are not operators (A). `#` took the low byte
  without complaint (`MVI A,#042201A` = 201Q) -- seen once, not relied on.
- A value too big for a byte is a V error (and assembled as the low byte).
- Strings: single quotes only, `''` for a quote; `"DQ"` is an A error.
  `DB 'X'+200Q` = 330Q (the high-bit terminator); `DB 'AB'+200Q` is a V
  error (a word).
- Pseudo-ops in ASM.ABS's table: ORG EQU SET DB DW DS END IF ELSE ENDIF
  ERRZR ERRNZ ERRPL ERRMI XTEXT SCALL TITLE STL SPACE EJECT LON LOF CODE
  INCLU... NOREF. No macros. Tried: ORG EQU SET DB DW DS END IF/ELSE/ENDIF
  ERRNZ (a P error when non-zero) XTEXT SCALL TITLE STL (they head the next
  listing page). `JE JNE CE CNE RE RNE` = JZ JNZ CZ CNZ RZ RNZ.
- `END` needs the entry address: a bare `END` is an A error.
- **`IF expr` assembles its lines when expr is ZERO** and skips to
  ELSE/ENDIF when it is not (IF 0 assembled; IF 1, IF 2, IF -1 skipped,
  ELSE part taken: T2, T3, T4). The opposite of DRI's ASM. The book's
  programs use no IF.
- Z80 mnemonics are O errors (`LD A,B`, `DJNZ *`).

XTEXT, HOSDEF and SCALL
- `XTEXT NAME` reads NAME.ACM. Found on SY0: (T5A: TINY.ACM only on SY0:)
  and on the source's disk (HOSDEF.ACM only on SY1:); a device may be named
  (`XTEXT SY0:TINY`, `XTEXT SY1:HOSDEF`).
- SCALL is built into ASM: `SCALL .PRINT` = `377Q 003Q` (RST 7, then the
  number). HOSDEF.ACM only names the numbers: .EXIT 0, .SCIN 1, .SCOUT 2,
  .PRINT 3, .READ 4, .WRITE 5, .CONSL 6, .CLRCO 7, .LOADO 8, .VERS 9;
  .LINK 40Q, .CTLC 41Q, .OPENR 42Q, .OPENW 43Q ... .CLOSE 46Q; .MOUNT 200Q.
  It does so with `ORG 0` / `DS 1` lines, so XTEXT HOSDEF BEFORE your own
  ORG: it leaves the location counter at 207Q.
- ASCII.ACM: NL 12Q, ENL = NL+200Q ("NL + END-OF-LINE-FLAG"), NULL 200Q
  ("PAD CHARACTER"), CR, LF, ESC 33Q, TAB, BELL, CTLC ...
- HOSEQU.ACM: USERFWA = 42200A (2280H), where programs load. MTR.ACM:
  `.TICCNT EQU 40033A  CLOCK TICK COUNTER` (201BH). FNVERH defines
  `TICKS EQU 40033A` itself rather than XTEXT the 14-sector MTR.ACM.

HDOS calls, as seen (T4, e4-print-run.txt)
- `.PRINT`: HL -> text, printed up to and including the first byte with
  bit 7 set (printed without it). `'AB',NULL` ends with nothing visible,
  `'CD',' '+200Q` ends with a space, `...,ENL` with a new line.
- `.SCOUT`: A = character; NL is a new line. FNVERH pushes HL/BC round it.
- `.EXIT` with A = 0.
- HDOS's console maps lower case to upper on output by default:
  `'Ef lower'` prints `EF LOWER`, `'x'` prints `X`. So FNVERH shows the
  version as `V1.6-7D7A3BA`. (The book's os.inc turns the mapping off with
  .CONSL; the native programs leave HDOS alone.)

## DRI ASM 2.0 and LOAD (Heath CP/M 2.2.04)

Evidence: `data/native/probes/C1.ASM`, `C1.PRN`, `e6-console.txt`.
- `ASM B:FNVER` reads B:FNVER.ASM, writes B:FNVER.HEX and B:FNVER.PRN.
  (The `ASM B:FNVER.ABC` drive letters -- source, HEX (Z none), PRN (X
  console, Z none) -- are DRI's documented form; not tried here.)
- Console: `CP/M ASSEMBLER - VER 2.0`, then one line per error (letter,
  address, bytes, source line), the next free address, `nnnH USE FACTOR`,
  `END OF ASSEMBLY`. Error letters seen: U undefined, V value too big, E
  expression, S syntax (`LD A,B`), L label (`DJNZ $`).
- `LOAD B:FNVER` writes B:FNVER.COM (the .HEX's drive), from 0100H, in
  whole records.
- Labels: long names fine (17-character labels differing only in the last
  character kept apart); EQU/SET names take no colon, instruction labels
  were written with one (as in FNON); lower case accepted (`label1: nop`);
  `;` comments anywhere; `*` in column 1 a comment line.
- `$` is the location counter; `$` inside a name or number is ignored
  (`D$O$L` = `DOL`, `1$000B` = 8).
- Numbers: H (leading digit), O/Q, B, D suffixes. Operators with
  precedence: `5+3*2` = 11; `(5+3)/2` = 4; `AND OR XOR NOT SHL SHR MOD`
  (`1 OR 2 XOR 3` = 0: OR and XOR rank equal, left to right). No HIGH/LOW
  (U). `NOT 0` in MVI is a V error (it is FFFFH).
- Strings: single quotes, `''` for a quote; `"DQ"` an E error.
- IF/ENDIF work (non-zero = assemble). **ELSE is accepted without a word
  and does nothing: both branches were assembled.** SET accepted. No
  macros (that is MAC).

## Gotchas

- The book's HDOS boot disk (hdos-fn.h8d) has one free group and the
  Software Tools disk none, so ASM.ABS, HOSDEF.ACM, ASCII.ACM go on the work
  disk with the source and ASM is run as `SY1:ASM`. A reader with room on
  SY0: types plain `ASM ...`.
- `.h17disk` images must be converted for hdosfs:
  `hdosfs.py convert HDOS_2_0_Software_Tools.h17disk tools.h8d`.
- File transfer onto images: HDOS `hdosfs.py put` (text with NL line ends,
  NUL padding is fine); CP/M `appmake +cpmdisk` (via rig.sh `cpmdisk`) with
  text as CR LF + ^Z (`native.py cpmtext`). appmake insists on a program
  first, so a one-byte STUB.COM goes first and is then erased with E5 in
  byte 0 only, as ERA does (`native.py cpmera`; a fully-E5 entry would end
  Heath CP/M's directory search -- see fujinet-h89 cpm-dir-fixup.py).
- Heath's CP/M BIOS keeps no type-ahead: the CCP lines are typed a key at a
  time (rig.sh `slow`, 120 ms a key). HDOS takes a typed-ahead line: typed
  while ASM was still loading, it was echoed at once and then read by
  ASM's `*` prompt.
- HDOS listings come off the disk NUL-padded to a sector, and Heath's ASM
  pads " No Errors" with two NULs; CP/M's PRN ends at ^Z. `native.py text`
  removes both.
- Heath ASM writes DS areas into the .ABS (see cross-check); DRI's .HEX
  leaves them out, and DS memory is whatever was there (FNVER/FNVERH write
  before they read: PKT+4 is computed, REPLY filled by RECV).
- HOSDEF moves the location counter: XTEXT it before ORG.
- IF is inverted between the two assemblers; ELSE is a no-op in DRI's ASM.
- Expressions: Heath left to right, DRI with precedence. Keep `*`/`/` out
  of mixed expressions (the converter refuses them).
- 8080 `JP` is jump-if-plus and `CP` is call-if-plus: a Z80 habit there
  assembles without error and does the wrong thing.
- HDOS 2.0 takes no year past 99 (the rig types 12-OCT-80). HDOS COPY wants
  an explicit target name (not needed here: files go on with hdosfs).
- The debugger's `mem 201B 2` refused its argument; `--debug timer` gives
  the 2 ms count.

## 8080 for Z80: the substitutions made

| Z80 (book library) | 8080 (these programs) | note |
|---|---|---|
| `JR`, `JR Z/NZ/C/NC` | `JMP`, `JZ`, `JNZ`, `JC`, `JNC` | no relative jumps; 3 bytes each |
| `DJNZ loop` | `DCR B` / `JNZ loop` | |
| `IN A,(PORTC)` / `OUT (PORTA),A` | `IN PORTC` / `OUT PORTA` | A and an immediate port only; no `IN r,(C)` |
| `LD (fn_sp),SP` | `LXI H,0` / `DAD SP` / `SHLD OLDSP` | FNVER (CP/M) keeps the CCP's SP this way |
| `LD SP,(fn_sp)` | `LHLD OLDSP` / `SPHL` | |
| `LD DE,(nn)` / `LD (nn),DE` | `XCHG` / `LHLD nn` / `XCHG` (or `SHLD`) | only HL loads/stores a word directly |
| `SBC HL,DE` | `MOV A,L` / `SUB E` / `MOV L,A` / `MOV A,H` / `SBB D` / `MOV H,A` | (fn_expired) -- FNVER avoids it by counting ticks down |
| `LDIR` | a loop | |
| `IX`, `IY`, `BIT n,r` | memory variables; `ANI mask` | |
| `LD A,n` / `LD r,r` / `LD A,(HL)` | `MVI A,n` / `MOV r,r` / `MOV A,M` | MVI, like LD, leaves the flags alone (used on purpose in SEND1 and RECV2) |
| `CP n` / `CP (HL)` | `CPI n` / `CMP M` | **8080 `CP` is "call if plus"** |
| `JP nn` | `JMP nn` | **8080 `JP` is "jump if plus"** |
| `OR A` / `XOR A` / `AND n` | `ORA A` / `XRA A` / `ANI n` | |
| `ADC A,0` | `ACI 0` | the end-around carry in CKSUM |
| `PUSH AF` | `PUSH PSW` | |
| `EX DE,HL` | `XCHG` | |
| `SCF` / `CCF` | `STC` / `CMC` | |
| `RST 0x38` + `DB fn` (SCALL macro) | `SCALL fn` (Heath ASM pseudo-op) = `377Q`, `fn` | |
| `macro ... endm` | none | neither ASM has macros (DRI's MAC does) |
