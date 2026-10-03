#import "../lib.typ": *

#part("V", "Software: the console side",
  [What a client program is, how it talks to the mailbox from 128 bytes of
   RAM, how it draws, and four real programs: the bring-up's browser,
   CONFIG, Battleship, and the 1977 Combat patched for two consoles over the
   network.])

= What a client is <ch-client>

A FujiNet client for this cartridge is an image of N banks of 2K followed
by a fixed 2K half, so its size is (N+1) × 2048 bytes. MAME's cartridge
loader accepts only certain sizes, so N is 1, 3, 7 or 15: a 4K, 8K, 16K
or 32K image. A program that needs five banks pads to seven. Every bank is
assembled at `$1000`--`$17FF`, the fixed half at `$1800`--`$1FFF`, and the
parts are concatenated in order. #src[build.sh:87-121; fuji_cart.h:36-44]

#fig(
  {
    set text(size: 7.6pt)
    align(center, stack(dir: ltr, spacing: 3pt,
      ..range(4).map(i => box(width: 54pt, height: 34pt, fill: c-code, stroke: 0.7pt + ink, align(center + horizon, text(font: f-head, weight: 700)[bank #i\ 2K]))),
      box(width: 20pt, height: 34pt, align(center + horizon, text(fill: gray)[…])),
      box(width: 54pt, height: 34pt, fill: c-code, stroke: 0.7pt + ink, align(center + horizon, text(font: f-head, weight: 700)[bank N−1\ 2K])),
      box(width: 96pt, height: 34pt, fill: c-stat, stroke: 0.7pt + ink, align(center + horizon, text(font: f-head, weight: 700)[fixed half · 2K\ #text(weight: 400, size: 6.6pt)[only its last 256 bytes are served]]))))
  },
  [The image. Each bank is entered at `$1000`; the fixed half is the last 2K of the file whatever the size, and the cartridge paints the mailbox over all but its top page.],
) <fig-image>

Of the fixed half only its last 256 bytes reach the console: the rest of
its address range is the mailbox. @tbl-fixed is that page.

#tbl(
  tab((auto, auto, 1fr),
    th[Offset in the fixed half], th[Console], th[What is there],
    [`$700`--`$70C`], [`$1F00`--`$1F0C`], [painted by the cartridge: ACKSEQ, STATUS, ERR and the rest (#ref(<ch-mailbox>))],
    [`$70D`--`$70F`], [`$1F0D`--`$1F0F`], [published by the bus layer: TEXTGEN, BANK, FLAGS],
    [`$710`--`$713`], [`$1F10`], [the claim, `FUJI`, stamped by the build at file offset (size − 2048) + `$710`],
    [`$714`--`$716`], [`$1F14`], [the header: bank count, cell height, layout revision],
    [`$717`--`$719`], [`$1F17`--`$1F19`], [published by the bus layer: PATHLEN, BLITGEN],
    [`$720`--`$7FB`], [`$1F20`--`$1FFB`], [the fixed tail: 220 bytes of the client's code that every bank must reach at the same address],
    [`$7FC`--`$7FF`], [`$1FFC`], [the RESET and BRK vectors],
  ),
  [The top page of the fixed half. #src[fuji_mailbox.h:131-195; build.sh:48, 81]],
) <tbl-fixed>

== The fixed tail, and why the cold stub lives in it

A bank switch replaces every byte of `$1000`--`$17FF`. The store that
switches is the last instruction fetched from the old bank, so the
instruction after it must be fetched from somewhere that does not change:
the tail. And the RESET vector must point into the tail, never into a
bank, because the console's RESET switch restarts the 6507 with whatever
bank was last selected still mapped. A vector into bank 0 would reset
into the wrong code from any other bank. @lst-tail is Battleship's
version of both; CONFIG's and Combat's have the same shape.

#listed(
```
; The trampoline, at FNTAIL ($1F20). A = the bank to enter.
BSGOTO: clc
        adc     #FH_BANK
        tax
        sta     FNRSEL,x        ; the switch; this is the last fetch from the old bank
        ldx     #$FF            ; RESET THE STACK: nothing ever returns through a switch
        txs                     ;   (fetched from the fixed tail, so it still executes)
        jmp     $1000           ; every bank is entered here

; BSCOLD -- power-on and RESET. Deliberately tiny: only what cannot be
; anywhere else -- the arming pair, because banking is a control-page
; operation, and the bank switch itself.
BSCOLD: sei
        cld
        ldx     #$FF
        txs
        lda     #ENCOLD         ; force a cold entry: the console does not
        sta     BSENT           ;   clear RAM on a reset
        lda     #FNAM1
        sta     FNRSEL+FH_ARM1  ; $B5 ...
        lda     #FNAM2
        sta     FNRSEL+FH_ARM2  ; ... then $4A: the gate
        lda     #BANKLOB
        jmp     BSGOTO

        ORG     $1FFC
        DW      BSCOLD
        DW      BSCOLD
```,
  [Battleship's trampoline and cold stub. The stack reset is not decoration: the switches are taken from inside the per-frame hook, which the display loop reached with a `JSR`, and two bytes leaked per poll until the stack had grown down into the program's variables. #src[fujinet-battleship/atari2600/src/bscore.inc:25-80]],
) <lst-tail>

Cartridge state survives a RESET: ACKSEQ, the path buffers, the text
planes and the reply window are all exactly as they were. A cold stub
therefore empties the path buffers explicitly, and derives its first
sequence number from ACKSEQ rather than assuming zero (#ref(<ch-mailbox>)).
#v-emu

== Every bank carries its own library

There is no shared code region but the tail. Each bank includes its own
copy of the transport and the display kernel, about 600 bytes, which is
what F8 games have always done. Battleship puts the routines every bank
calls in the tail --- the transport at 151 bytes and the four text
primitives at 24 --- and generates the equates for them from the tail's
own listing so that no hand-kept list can go stale. A byte added to a
shared include costs a byte in every bank that includes it.
#src[fujinet-battleship/atari2600/README.md "Banks"]

= A transaction from the 6507's side <ch-txn>

The library, `fujilib.inc`, is built on one two-instruction routine, and
the whole transport is six steps around it. #src[testrom/fujilib.inc]

#listed(
```
; FNRW -- register X = A. The whole transport is built on this.
; `sta FNRSEL,x` is safe for any X: the base low byte is $00, so the index
; can never carry and the dummy read STA abs,X performs lands on the SAME
; address as the write -- one parked access, not two.
FNRW:   sta     FNRSEL,x
        sta     FNCMT
        rts

; FNARM -- open the decode gate: two stores, in order, two specific values.
FNARM:  lda     #FNAM1
        sta     FNRSEL+FH_ARM1
        lda     #FNAM2
        sta     FNRSEL+FH_ARM2
        rts
```,
  [The register write and the gate. #src[fujilib.inc:31-43]],
)

#listed(
```
        jsr     FNARM           ; open the gate (once)
        lda     #FNDEVF         ; 1. the device ($70) ...
        sta     FNDEV
        lda     #FNCADPX        ; 2. ... the command ($C4, GET_ADAPTERCONFIG_EXTENDED) ...
        sta     FNCMD
        lda     #0              ; 3. ... and the parameter count
        sta     FNNPR
        jsr     FNBEG           ; commit all three, rewind TX
                                ; 4. parameters and payload: none here
        jsr     FNGO            ; 5. SEQ = ACKSEQ+1, wait; A = 0 if answered
        bne     FAILED
        jsr     FNACK           ; 6. ACK or NAK?
        bne     FAILED
        lda     FNRPLY+0        ; the SSID starts at reply offset 0
```,
  [The six steps, for the first command every bring-up client sends. #src[testrom/fujitest.asm]],
)

#listed(
```
FNGO:   lda     FNACKS          ; the cartridge's OWN persisted ACKSEQ ...
        clc
        adc     #1              ; ... plus one ...
        bne     FNGO1
        lda     #1              ; ... skipping 0, which means "never used"
FNGO1:  sta     FNSEQ
        ldx     #FR_SEQ
        jsr     FNRW            ; launching it is this single commit
        lda     FNTMO
        sta     FNCNT
FNGO2:  ldy     #0
FNGO3:  ldx     #0
FNGO4:  lda     FNACKS          ; ACKSEQ is published LAST, so a match means
        cmp     FNSEQ           ;   everything behind it is already readable
        beq     FNGO5
        dex
        bne     FNGO4
        dey
        bne     FNGO3
        dec     FNCNT
        bne     FNGO2
        lda     #FNEWAIT
        rts
FNGO5:  lda     FNERR
        rts
```,
  [Launching and waiting. The timeout is sixteen quanta, about 9 s, deliberately longer than the cartridge's own 5 s so that a real timeout is reported as the cartridge's error and not the console's. In emulation the whole round trip happens inside the commit store and the first comparison matches; on hardware it takes as long as the network does. #src[fujilib.inc:108-134]],
)

Parameters are appended with one store each --- a size byte, then the
value bytes --- by `FNPB` and `FNPW`; a path payload is exactly 256 bytes,
NUL-padded, which is what the cartridge's `PATH_TX` emits in one store.
The reply is read in place at `FNRPLY,X`. Because the window is stable
until the next commit, the library streams it rather than copying it:
`FNRRPL` renders up to Y bytes of the reply at offset X into text row A,
`FNPRPL` appends them to the TX stream of the next request, `FNWRPL`
appends them to the selected path buffer. That is how a browser descends
into a directory whose name it has never held in RAM: `ldx #0 / ldy
#NAMELN / jsr FNWRPL`. #v-emu #src[fujilib.inc:78-97, 158-178, 302-316, 389-397]

= The display kernel <ch-kernel>

`fujidisp.inc` is two routines, shared by every client, and transcribed
rather than re-derived from batari Basic's proven kernel. `DINIT` sets the
TIA up once; `DLOOP` draws frames forever. #src[testrom/fujidisp.inc]

== Positioning

Two players with three copies each eight pixels apart (`NUSIZ` = `$03`),
so that P0 draws groups 0, 2 and 4 and P1 groups 1, 3 and 5, interleaving
into 48 contiguous pixels; vertical delay on both, which is what makes the
six-write sequence land in the right copies; then the positioning: sixteen
`NOP`s and one three-cycle store so that `RESP0` lands on cycle 38, `RESP1`
three cycles later, `HMP0` of `$F0` to pull player 0 right one pixel, and
an *early* `HMOVE` on the line after. #src[fujidisp.inc:20-24, 46-95]

#important[
  The four constants `RNOP` = 16, `R3` = 1, `HM0` = 15, `HM1` = 0 are the
  coordinates of a one-pixel-wide window. The six copies are 2.67 cycles
  apart and the kernel's stores are three, so where the block sits decides
  whether each update lands between copies or inside one, and every wrong
  setting still looks like text. They were found by decoding the raster
  back into plane bytes and comparing against the renderer, not by eye.
  #v-emu
]

== The frame

#tbl(
  tab((auto, auto, 1fr),
    th[Band], th[Lines], th[],
    [VSYNC], [3], [],
    [VBLANK], [37], [the client's per-frame hook `APPVBL` runs here, with the raster nowhere near the text; input scanning belongs here, and so does a transaction, with the caveat that a network round trip is far longer than a frame],
    [pad], [33], [],
    [text], [126], [21 rows × 6 lines, the kernel below],
    [pad], [33], [],
    [overscan], [30], [],
    [total], [262], [NTSC, every line timed by `WSYNC`],
  ),
  [The frame. #src[fujidisp.inc:37-42, 98-192]],
) <tbl-frame>

== The kernel

#listed(
```
        tsx
        stx     SAVSP
        ldy     #0
KERN:   sta     WSYNC
        lda     TP0,y           ; 4
        sta     GRP0            ; 3   ->  7   new GRP0 = group 0
        lda     TP1,y           ; 4   -> 11
        sta     GRP1            ; 3   -> 14   displays group 0
        lda     TP2,y           ; 4   -> 18
        sta     GRP0            ; 3   -> 21   displays group 1
        lda     TP4,y           ; 4   -> 25
        tax                     ; 2   -> 27
        txs                     ; 2   -> 29   park group 4 in S
        lda     TP3,y           ; 4   -> 33
        tax                     ; 2   -> 35
        lda     TP5,y           ; 4   -> 39
        stx     GRP1            ; 3   -> 42   displays group 2
        tsx                     ; 2   -> 44   recover group 4
        stx     GRP0            ; 3   -> 47   displays group 3
        sta     GRP1            ; 3   -> 50   displays group 4
        sty     GRP0            ; 3   -> 53   displays group 5; value unused
        iny
        cpy     #TLINES
        bne     KERN
        ldx     SAVSP
        txs
```,
  [The text kernel: 53 of the 76 cycles in a line. #src[fujidisp.inc:144-169]],
) <lst-kern>

Three things in it are not style. The stack pointer is a register: the
four late writes drift a full cycle across the block, recovering a byte
from zero page costs three cycles and `TSX` costs two, and that one cycle
is the difference between a schedule that closes and one that does not.
The seventh write, `STY GRP0`, exists because with vertical delay six data
bytes need seven writes; its value is a don't-care, so the scanline
counter serves and no register is spared for it. And nothing between the
`TXS` and the restore may touch the stack: no `JSR`, which is safe only
because the 6507 has no interrupts. After the last line both players are
blanked with three writes, not two --- with `VDELP` set, a write to `GRP0`
reloads only the delayed `GRP1` and vice versa --- and the obvious-looking
alternative, toggling `VDELP` off and on, restores the stale delayed
registers and redraws the last text line down the blank band. That was one
of the three bugs the raster comparison found. #src[fujidisp.inc:171-179]

== The pixel that cannot be drawn

The 48-pixel block is six player copies and seven writes; the four late
ones span 33 pixels, while the distance from the end of group 0 to the
start of group 5 is 32. No position serves all 48, so every position
loses exactly one pixel, and the least bad one to lose is pixel 7 --- bit
0 of plane 0, which the text renderer already spends as column 1's
inter-character gap. Text never notices. Anything else drawn through the
planes, such as the playing-card transform, has to know, and does: the
card bed starts at pixel 2. #src[fuji_mailbox.h "FN_CARD_X0"]

= Living in 128 bytes <ch-ram>

The console has 128 bytes of RAM at `$80`--`$FF`, and `$0100`--`$01FF`
mirrors it, so the stack is in the same 128 bytes. The library's own cells
are a sequence number, a timeout counter, the three register values of the
current request, a pointer and a count, and two input-scan bytes: fourteen
bytes at `$80`--`$8E` and `$A8`--`$A9`. The swap stub lands at `$80`--`$A6`
for the few microseconds it runs. Everything else a program might want to
hold is in the cartridge: the reply, the working directory, the text, the
board. The console holds a cursor and a handful of flags. #src[fujinet.inc:103-113; fujiboot.asm:205-207]

== The static check

Because the 6507 has no interrupts, every access a running program makes
comes from its own instruction stream, and a scan of the image can prove
things an emulator can only sample. `tools/checkrom.py` disassembles every
bank --- every bank is entered at `$1000` and every bank is code --- and
fails the build when:

- the image is not (N+1) × 2048 bytes, or not a size MAME will load;
- the claim is missing;
- the RESET vector does not point into the fixed half for a banked image,
  or anywhere in the window for a flat one;
- any of `INC`, `DEC`, `ASL`, `LSR`, `ROL`, `ROR` with an absolute or
  absolute,X operand reaches `$1D00`--`$1EFF`;
- an indirect `JMP` has a vector on a page boundary (the 6502's own bug);
- an indirect store, `STA (zp),Y` or `STA (zp,X)`, appears anywhere at
  all, since the scan cannot know what a zero-page pointer holds.
#src[tools/checkrom.py:94-160, 206-228, 267-323]

Two traps the build grew checks for are worth recording, because each
passed every test before it was caught. `p2bin` emits its whole address
range whatever was assembled, so an over-long bank is truncated in
silence: the image builds, the size is right, the static check passes,
and the instructions past `$17FF` are simply gone; CONFIG's and
Battleship's build scripts read the assembler's listing to catch it. And
the client equates are hand-mirrored from the header and once drifted by
a page; `tools/checkdefs.py` now holds all 39 to it before anything
assembles. #src[README-fujinet.md:227-237]

= Worked examples <ch-examples>

== The bring-up's browser

`fujidir` is a 4K flat image: it mounts host 0, opens `/`, reads an entry
per text row, and moves a cursor with the joystick. No name is ever held
in RAM; the cursor is an index, and moving it re-reads the listing, which
is instant in emulation and about a second a step on hardware. FIRE boots
the file under the cursor. It is the client baked into the firmware by
default. #v-emu #src[testrom/fujidir.asm:1-17, 216-390]

#fig(
  grid(columns: 2, column-gutter: 14pt, align: bottom,
    box(stroke: 0.6pt + ink, image("../images/screens/asm-dir.png", width: 2.0in)),
    box(stroke: 0.6pt + ink, image("../images/screens/config-hosts.png", width: 2.0in))),
  [Left: `fujidir` listing the SD card in the MAME model; the `>` is the cursor, since there is no inverse video. Right: CONFIG's host-slot screen. #v-emu],
)

== CONFIG

CONFIG for this console is a 16K image, seven banks and the fixed half,
built in `fujinet-config/atari-2600` with the same assembler and the same
checks, and baked into the cartridge in place of the browser. It has
feature parity with the Intellivision's: WiFi set-up, eight host slots,
browsing with paging and subfolders and a filter, host-to-host copy, the
Game Lobby, adapter information, and mount-and-boot with a progress bar.
#src[fujinet-config add-atari-2600:atari-2600/README.md]

#tbl(
  tab((auto, auto, 1fr),
    th[Bank], th[Screen], th[Controls],
    [0], [Host slots], [↑↓ move, FIRE mount and browse, SELECT menu: INFO, RENAME, WIFI, LOBBY],
    [1], [Browser], [↑↓ move, ←→ page, ← at page 0 goes up, FIRE descend or boot, SELECT menu: UP DIR, FILTER, INFO, COPY, COPY HERE],
    [2], [Adapter info], [FIRE or SELECT back],
    [3], [Keyboard], [a 12 × 8 grid, so the cursor position *is* the character: ch = 32 + row × 12 + col; SELECT menu: ACCEPT, CANCEL, CLEAR],
    [4], [WiFi], [↑↓ move, FIRE pick, SELECT skip],
    [5], [Boot], [progress bar from BOOT_PCT; FIRE dismisses a failure],
    [6], [Copy], [FIRE returns early],
  ),
  [CONFIG's banks. A joystick, one button, SELECT and RESET are the whole input; the console has no manual, so every action is on a menu that prints itself rather than on a chord.],
) <tbl-config>

Almost nothing lives in console RAM: about forty bytes are free, and the
working directory, the filter, a pending copy's source and the text being
typed are 256-byte strings in the cartridge. Six mailbox additions were
made for it --- the four path buffers, the single-character pop, the
seed-and-commit edit cycle, and the `PATH` and `TCELL` blits --- each
because the console could not afford the round trips or the bytes
otherwise. Moving a list cursor changes two characters; without a
one-cell poke it would cost two transactions per step on the WiFi screen,
whose text arrives one scan result at a time. #v-emu

== Battleship

Battleship is a 16K client in its own repository, playing the family's
`?bin=1&v=2` wire format against the live server at
`battleship.carr-designs.com` through N1: over HTTPS, with up to four
10 × 10 boards on screen at once in colour. Text is twelve columns of
white; a game board wants colour, and on this console colour comes from
the playfield: forty bits across the screen, one colour per scanline. A
cell is two playfield bits, so two boards side by side are the whole
asymmetric playfield, `PF0`, `PF1` and `PF2` rewritten twice a scanline,
and the colour of a mark is decided by *which line of the eight-line cell*
is being drawn: a different table in a different colour on each, so that a
hit is a red block with a white core, a miss a white dash, and a hull or
the cursor a pair of gold brackets. #src[fujinet-battleship/atari2600/README.md:1-30, 76-108]

#tbl(
  tab((auto, auto, auto),
    th[Bank], th[Module], th[Bytes],
    [0], [`bslobby`: the cold start and the table list], [1016],
    [1], [`bsgame`: the board kernel, the cursor, the cues, a shot], [1668],
    [2], [`bsnet`: one request, with the picture up, and back], [1993],
    [3], [`bsmenu`: the RESET menu, the help, leaving], [1092],
    [4], [`bsname`: the keyboard and the shared username], [1201],
    [5], [`bsplace`: the roll, the five ships], [2013],
    [6], [`bscomp`: compose the game screen, in passes], [2025],
  ),
  [Battleship's seven banks of 2048 bytes. #src[fujinet-battleship/atari2600/README.md "Banks"]],
) <tbl-bs>

The eighteen tables the kernel reads --- three kinds for each of six
registers, one entry per cell row --- live in the text-plane region, which
nothing but a text render ever writes, and the cartridge fills them
straight from the reply window with four blit transforms. Doing that on
the console would be four hundred reads through a 16-bit cursor in a bank
that has not got the bytes, into RAM it has not got at all; the blit costs
six stores. The four-seat frame is 262 lines with no slack --- 191 lines
of kernel in a band of 192 --- and `tools/pfcheck.py` reads every cell of
every board back from a snapshot and requires the colour the picture says.
Every frame of a whole game is held to 262 lines by a harness.
#v-emu

#fig(box(stroke: 0.6pt + ink, image("../images/screens/bs-lobby.png", width: 2.2in)),
  [Battleship's lobby, listing the server's tables. #v-emu])

= Combat, patched for two consoles <ch-combat>

The last example is the one that tests the design against a program not
written for it. _Combat_ (Atari, 1977; Larry Wagner and Joe Decuir) is
2K, deterministic, and reads its switches and sticks in exactly four
places. `fujinet-2600-combat` is a patch that makes two consoles, each
with its own cartridge, play one game of it over the network. It is
built from the published Dodgson–Bensema–Williams disassembly, which the
repository does not redistribute; the build audits every byte of the
result against the pristine ROM assembled at `$1000` and fails on any
difference that was not declared. 99 bytes were. #v-emu
#src[fujinet-2600-combat: README.md; PORTING.md; tools/check_patch.py; tools/patches.py]

== The model

The game is delay-based input lockstep through a relay that interprets
nothing. A simulation tick is four video frames, fifteen a second. On
each tick every console sends one packed input byte, stamped two ticks
ahead, and both consoles apply *both* players' inputs at the same tick.
Local input is delayed by the same two ticks, so the lag is symmetric,
about 133 ms, and neither side is authoritative: Combat has no random
number generator, so two copies given the same inputs in the same order
stay identical. #src[cbdefs.inc:147-154; README.md:58-62]

#tbl(
  tab((auto, auto, 1fr),
    th[Frame], th[Type], th[Payload],
    [HELLO], [`$01`], [version 2, TV standard, a 2--8 character name. Sent once by each console],
    [START], [`$05`], [role, seed, delay, variation, the opponent's name. The console checks that the delay equals its compiled two ticks and falls back to local play otherwise],
    [INPUT], [`$06`], [8 bytes, fixed: the target tick, then a window of *three* consecutive ticks' input bytes newest first, a state CRC, and a check byte. The window exists because the transport is not locked to the tick and a tick's record can go unsent],
    [PEER_LEFT], [`$0B`], [the relay's notice that the partner dropped],
  ),
  [The frames the ROM sends or parses. Each is `len, type, payload`; the relay forwards game frames verbatim, padded to 8 bytes, and the console reads only whole frames: `avail AND $F8`. #src[cbdefs.inc:333-354; cbnet.inc:98-180, 243-266; server/combat\_relay\_server.py:14-28, 83-88]],
) <tbl-combat-frames>

The input byte is the hardware's own bits, active low as on the ports:
trigger in bit 7, difficulty in bit 6, SELECT in 5, RESET in 4, the stick
in the low nibble. RESET and SELECT are ANDed between the two players'
bytes, so either can press them. That AND is also the desync repair: each
record carries a CRC over twelve bytes of game state, and a console that
sees a mismatch at the tick clears the RESET bit in its own next wire
byte --- a one-shot synthetic RESET --- so that both consoles restart the
round at the same tick. A state push would not do, because a tank's X
position is not in RAM at all: it lives in the TIA's `HMP0`/`HMP1`.
#src[cbdefs.inc:225-243; cbcrc.inc:394-408, 432-444; PORTING.md §4.26]

== What was changed in the 1977 ROM

#tbl(
  tab((auto, auto, auto, 1fr),
    th[Stock], th[Routine], th[Bytes], th[Change],
    [`$F014`], [MLOOP], [rewritten], [begins with `JSR CBSHIM`; if the tick has not advanced the game-logic chain is skipped and only the state loader and the score run, so a stalled frame still draws. `INC CLOCK` moves behind the gate, so the clock counts ticks that ran],
    [`$F05C`], [VOUT's vblank wait], [0], [`LDA INTIM / BNE` becomes `JSR CBWAIT / NOP / NOP`: size-neutral, so the cycle-exact kernel below it does not move],
    [`$F156`], [VOUT's final `RTS`], [+3], [`STA WSYNC`, then a bank switch back to the game bank],
    [`$F000`], [before START], [+7], [a warm entry: if the session is up, go straight to MLOOP],
    [`$F005`], [the RAM clear], [], [clears `$80`--`$E5` rather than `$80`--`$A2`, stopping where the netcode's cells begin],
    [`$F157`, `$F192`, `$F30E`, `$F59C`], [four reads of `SWCHB`], [0], [`LDA SWCHB` → `LDA >CBSWB`, the absolute form, so the length and the cycles are unchanged],
    [`$F313`, `$F36E`], [both reads of `SWCHA`], [0], [→ `LDA >CBJOY`: the synthetic stick, both nibbles; the local player's own read is patched too, so that it is delayed like the remote one],
    [`$F3BB`], [the trigger read], [0], [`LDA INPT4,X` → `LDA CBTRIG,X`],
    [`$F7F4`], [8 bytes of `$FF` filler], [8], [the tick-phase stepper],
  ),
  [The declared patches. Seven input sites, each the same length and the same cycles as the original; every other Combat byte keeps its stock offset, rebased from `$F000` to `$1000`. #src[tools/patches.py:22-252]],
) <tbl-combat-patch>

The result is an 8K FujiNet client: three 2K banks and the fixed half. The
boot bank holds the session and a text screen; the game bank holds START,
MLOOP and the game routines; the kernel bank holds VOUT, the score digits,
the playfield maps and the network machine. Each bank leaves the other
banks' regions empty, so the 1977 code never moves, and the netcode fills
the holes the moved regions left. The fixed tail carries the trampoline,
the shared transport, the cold stub and the vectors, with 18 bytes to
spare. #src[tools/mkbanks.py:41-49; src/cbgame.asm:28-62; src/cbtail.asm; build/tail.inc]

The RAM budget is the hardest constraint. Combat uses `$80`--`$E4` and its
stack is `$FA`--`$FF`, leaving 26 bytes. The input shadows take four of
them above the range the game's own clear touches; the netcode's state
takes six at `$E6`--`$EB`; and `$EC`--`$F9` is a union, the input rings
and the tick counters during play, the transport's cells during the
session set-up, because the two never run at once. Combat's own two
temporaries are borrowed inside single routines. #src[cbdefs.inc:6-131]

== Where the network runs

There is no overscan in Combat; the kernel runs to the last line. The
network machine therefore runs inside VOUT's vertical-blank wait, as
bounded micro-steps dispatched through a jump table, each taken only while
the RIOT timer shows at least 448 cycles left against a worst step of
about 310. The transport free-runs and is never blocked by the
simulation; a WRITE, a STATUS and a READ each cost one frame, so the input
exchange cycles at 20 Hz against a 15 Hz tick. Measured over a game, the
worst slack was 448 cycles, the average 960, and 0.4% of frames ran no
step. #v-emu #src[cbdefs.inc:283-308; cbnet.inc:24-63; PORTING.md:38-54, 763-765]

#listed(
```
CBWAIT:
        lda     CBENT
        and     #CBE_NET
        beq     CBWSPIN         ; no match: the stock spin, unchanged
CBWLOOP:
        lda     INTIM
        cmp     #CBGATE         ; 8: at least 448 cycles left
        bcc     CBWSPIN         ; through the CARRY: INTIM is unsigned
        jsr     CBNSTEP
        jmp     CBWLOOP
CBWSPIN:
        lda     INTIM
        bne     CBWSPIN
        rts
CBNSTEP:
        ldx     CBNST
        lda     CBJT+1,x        ; the state's handler, through RTS
        pha
        lda     CBJT,x
        pha
        rts
```,
  [The per-frame hook that replaced Combat's two-instruction vblank spin. #src[src/cbnet.inc:24-51]],
)

At each tick boundary `CBSHIM` advances the tick if the last one ran,
samples the state CRC, captures the local stick into the ring slot two
ticks ahead, and compares the tick the ring has reached against the one
the game needs. If the remote input for this tick has not arrived, the
frame stalls: it draws, the loader and the score run, the game logic does
not. A high nibble in the error cell counts consecutive stalled ticks and
saturates at fifteen, about a second; saturation --- or a PEER_LEFT frame,
which saturates it at once --- ends the session with "OPPONENT HAS LEFT,
PRESS RESET". A failure during set-up (no cartridge, the open refused, a
bad START, a delay mismatch, a 9 s timeout) shows "NO NETWORK, LOCAL PLAY"
for 90 frames and then plays plain Combat. #src[cbinput.inc:75-138; cbcap.inc:331-341; cbsess.inc:310-324, 423-439]

#fig(
  grid(columns: 4, column-gutter: 8pt,
    tv("COMBAT\nNET PLAY\nCONNECTING", size: 6.4pt, w: 1.45in),
    tv("WAITING FOR\nAN OPPONENT", size: 6.4pt, w: 1.45in),
    tv("PLAYING\nJOE", size: 6.4pt, w: 1.45in),
    tv("OPPONENT\nHAS LEFT\nPRESS RESET", size: 6.4pt, w: 1.45in)),
  [The session screens, drawn through the cartridge's text planes by the boot bank; the game bank then runs the 1977 kernel unchanged.],
)

== Matchmaking

The relay listens on TCP port 9600 and auto-pairs the first two idle
consoles; the one that waited longest is the host and the left tank. The
console reaches it through the N1: device --- `OPEN` on `N:TCP://host:9600/`
in read-write mode, then `WRITE`, `STATUS` and `READ` --- with the URL read
from a FujiNet app key that the FujiNet Lobby writes when a player picks
the room, and the player's name from app key 0. The relay registers itself
with the Lobby as platform `a2600` with two seats and the client's TNFS
URL, so that choosing the room from any FujiNet machine's CONFIG boots
this image and joins. Both players use joystick 1 on their own console;
the guest's byte is swapped into player 1's slot. #src[cbsess.inc:29-296, 373-390; cbcap.inc:253-275; server/combat\_relay\_server.py:271-299, 459-528]

== How it was verified

A two-console rig: two isolated copies of `fujinet-pc` on bus-over-IP
ports 19995 and 19996, the relay on 9600, and two headless MAMEs each
running the cartridge model with its own build of the ROM. The verdict
requires that the relay paired them, that no CRC mismatch was logged, that
both consoles' state snapshots at a chosen tick are identical, that the
game variation actually changed, that more than fifty ticks ran, and that
no transport error occurred. #src[test/run\_rig.sh:156-209]

#tbl(
  tab((auto, 1fr),
    th[Gate], th[Result],
    [`verify-org`], [the stock ROM rebuilt from the disassembly is byte-identical to the 1977 dump],
    [`combat`], [99 bytes changed, all declared; nothing undeclared],
    [`frames`], [263 lines every frame, through two bank switches a frame],
    [`det`], [1195 frames identical to the unpatched ROM when not in a match],
    [`inputs`], [four port reads in the whole image, all inside `CBSHIM`],
    [`rig`], [two consoles, 429 and 432 ticks, 0 CRC mismatches, byte-identical zero page at tick 150, through the 8-bit tick wrap],
    [`rig-play`], [581 ticks, identical state at every tick on both consoles],
    [`rig-repair`], [an injected desync is back in agreement within 4--8 ticks],
    [tick wrap], [the 8-bit tick wraps cleanly at 45 s],
  ),
  [Combat's gates, all run in MAME against `fujinet-pc`. #v-emu #src[PORTING.md:738-765]],
) <tbl-combat-gates>

Not done: no hardware; the Lobby app key for the relay URL is not yet
provisioned, so the build-time endpoint is used; Nagle's algorithm is on
in the adapter's TCP protocol adapter, which the 20 Hz exchange tolerates
but would rather not; the C transliteration of the relay has been checked
against the Python one by differential test but not through the rigs; and
the PAL build changes only the byte it sends in HELLO, not the kernel.
#src[README.md:121-127; PORTING.md §4.28]
