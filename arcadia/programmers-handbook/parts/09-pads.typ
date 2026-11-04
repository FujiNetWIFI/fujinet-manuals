#import "../lib.typ": *

= Hand Controllers and Sound <pads>

Each of the ARCADIA-2001’s two hand controllers has a 12-key keyboard, a
control disc and an Action button on each side. The console has START,
SELECT and OPTION (and RESET, which restarts the 2650 and cannot be read).
The 2637 makes a tone or a noise. `pads` shows all of it on one screen.

#shots(("pads-held", [5 and the disc held]), ("pads", [after a key, the disc and START]),
  caption: [pads])

== The keyboards

Each keyboard is read as three columns, one address each, active high, in
the low four bits:

#tbl((0.85in, 0.85in, 0.6in, 0.6in, 0.6in, 0.6in),
  [*Left*], [*Right*], [*bit 3*], [*bit 2*], [*bit 1*], [*bit 0*],
  [`$1900`], [`$1904`], [1], [4], [7], [CLEAR],
  [`$1901`], [`$1905`], [2, Action], [5], [8], [0],
  [`$1902`], [`$1906`], [3], [6], [9], [ENTER],
)

#important[The Action buttons are the keypad’s 2. Both are bit 3 of
`$1901` -- one wire -- so no program can tell them apart. CONFIG and every
FujiNet game treat that bit as "select", and never ask the player to type a
2 that means a 2.]

`pads` reads all 24 keys from a table of four bytes a key: the column’s
offset from `$1900`, the key’s bit, its cell on the screen, and its label.
A held key is drawn as a solid block:

#excerpt-at(auto, "listings/asm/pads.asm", "KEYS:   EORZ    R0", to: "; ---- the tone")

== The console’s buttons

`$1908` holds START in bit 0, OPTION in bit 1 and SELECT in bit 2, active
high. RESET is not there: it resets the 2650.

```
        LODA,R0 $1908
        TMI,R0  $01             ; START held?
        BCTA,EQ START1
```

`TMI` tests under a mask: CC is EQ when _every_ bit of the mask is 1.

== The discs

A disc is not four switches. It is two potentiometers, one an axis, and the
2637 turns them into numbers -- but only during the vertical blank. Read
outside it, a pot gives `$FF`.

#tbl((1.05in, 1fr),
  [*Address*], [*Holds*],
  [`$19FF`], [the left disc: vertical with bit 6 of `$19F9` clear, horizontal with it set],
  [`$19FE`], [the right disc, the same way],
)

Up and left read near `$00`, down and right near `$FF`, centred somewhere in
the middle (MAME gives `$6F` for the left disc). Anything under `$40` is one
way and anything over `$C0` the other.

The multiplexer, bit 6 of `$19F9`, shares its register with the character
height and both colours, so a program writes the whole register every time:
its base value with the bit, or without it. It reads one axis a frame,
keeps both, and decides from the kept pair -- deciding from the axis just
read would see "centred" on every other frame:

#excerpt-at(auto, "listings/asm/pads.asm", "MAIN:   TPSU    $80", to: "MKEYS:")

#note[Read outside the blank, the left disc’s vertical axis is `$FF`, which
looks like "down" held for ever. A menu that scrolls by itself is the
symptom. `fujidisp.inc`’s `SCAN` waits for the blank before it reads.]

== SCAN and GETKEY

For a menu, `fujidisp.inc` has the controller already decoded. `SCAN` waits
for the blank and returns the first control it finds held, as a code;
`GETKEY` waits for every control to be let go, then for a press, so a held
key steps once:

#tbl((0.85in, 0.4in, 1fr),
  [*Code*], [], [*Held*],
  [`KUP`], [1], [the disc up],
  [`KDOWN`], [2], [the disc down, or 8],
  [`KPGUP`], [3], [4],
  [`KPGDN`], [4], [6],
  [`KSEL`], [5], [an Action button (or 2), or ENTER],
  [`KBACK`], [6], [CLEAR],
)

== The tone

The 2637 has one tone generator and one noise generator, and two registers:

#tbl((0.8in, 1fr),
  [*Register*], [*Bits*],
  [`$18FD`], [0--6: the pitch, _n_; bit 7 is the colour mode, keep it 0],
  [`$18FE`], [0--2: loudness; 3: the tone on; 4: the noise on; 5--7: the screen’s scroll, keep them 0],
)

The tone’s frequency is 15,734 Hz ÷ (2 (_n_ + 1)): _n_ = 15 is about 490 Hz,
_n_ = 127 about 61 Hz. `pads` gives each key a pitch while it is held:

#excerpt-at(auto, "listings/asm/pads.asm", "TONE:   LODA,R0 ANYK", to: "; ---- the discs")

There are no envelopes and no second voice. A beep is a tone on for a few
frames; CONFIG’s key click is two frames.
