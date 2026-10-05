#import "../lib.typ": *

= Pictures, Pads and Sound

#lead[A network program spends most of its time waiting. On the NES it has to
wait without disturbing a picture processor that will only take new data
for about two thousand cycles in every frame.]

== The PPU's rule

The PPU draws the screen out of its own memory -- the pattern tables in CHR,
the nametables, the palettes -- and the CPU reaches that memory only through
two registers, `$2006` (address) and `$2007` (data). While the PPU is drawing,
those registers are its own: a write lands in the wrong place and knocks the
scroll askew. A program may write to the PPU only

#stars(
  [with rendering off (`$2001` = 0) -- the screen goes black meanwhile; or],
  [during vblank, the 20 scan lines between frames, announced by the NMI.],
)

The programs in Chapters 5 to 9 take the first road for everything they draw
at the start, and turn the screen on last. Those that draw while running --
`boot.s` and `clock.s` -- wait for the NMI with `wait_vbl`, write a few dozen
bytes, and put the scroll back with `scroll0`, because every `$2006` write
disturbs it.

== cc65's queue

cc65's NES runtime takes the second road for you. `cputc()` and every other
conio routine does not write to the PPU at all: it puts an (address, value)
pair in a queue in `$0200-$04FF`, and cc65's NMI handler writes up to 70 of
them in each vblank, then resets the scroll. A C program can therefore draw
whenever it likes. Three consequences:

#runin(
  ("NMI first", [The queue is drained only by the NMI. Draw before NMI is on
   and a full queue waits forever. cc65's start-up turns NMI on; a game that
   sets up the PPU itself must turn it on before its first `cputc`.]),
  ("About 68 cells a frame", [A whole 32×24 screen is over 700 writes:
   eleven frames. The games keep a copy of the screen in RAM and queue only
   the cells that change; for a whole-screen redraw they turn rendering off
   and write straight to `$2007`.]),
  ("No scrolling", [cc65's NMI sets the scroll back to 0,0 every frame. The
   netcat in Appendix D scrolls its text by redrawing it from a copy in RAM.]),
)

#caution[cc65's own `waitvsync()` polls the vblank flag in `$2002`. A read
of `$2002` in the very cycle the flag rises suppresses that frame's NMI --
and with it that frame's queue flush and frame count. Wait instead for
`clock()`, which cc65's NMI handler increments every frame, to change.
Battleship, Fujitzee and every C program in this manual do; 5 Card Stud and
Texas Hold'em still call cc65's.]

#note[The NMI may land in the middle of a mailbox transaction; cc65's handler
writes only the PPU and RAM, so that is harmless. Your own handler must not
write `$5500-$57FF`.]

== Pattern tables and the claim on CHR

cc65's NES runtime always links its 8K console font into CHR, whether a
program uses conio or not. The games keep it at `$0000` and put their own tiles
in the other pattern table at `$1000`, pointing the background there with
`$2000`. The NES has no colour per character, only a palette per 16×16-pixel
block, so the games bake each glyph-and-colour pair into a tile of its own
with a Python script, `mkchr.py`, that writes the tile set as ca65 source. The
budget is 256 tiles: 5 Card Stud uses 233, Fujitzee 238, Battleship all 256.

== The cartridge's work RAM

The console has 2K of RAM, and cc65 takes most of it: zero page, the stack,
the PPU queue at `$0200-$04FF`, and its own parameter stack. The FujiNet
cartridge serves 8K more at `$6000-$7FFF`, and `nes-fujinet.cfg` puts all of a
C program's data and BSS there. That is where a game keeps its state, its
screen copy and its network buffers.

#caution[That 8K is lost when the power goes off. Keep anything that must
survive in an app key.]

== The controller

#fig(caption: [The NES controller. The FujiNet programs follow the same
conventions.], controller(w: 3.8in))

#legend(
  ([Control Pad], [Moves the cursor or the highlight.]),
  ([A button], [Chooses: the key under the cursor, the table, the move.]),
  ([B button], [Goes back, or deletes.]),
  ([START button], [Done; in the games, the menu.]),
  ([SELECT button], [Shift on the on-screen keyboard; in netcat, hang up.]),
)

Reading the controller is a write of 1 and then 0 to `$4016`, then eight reads,
one bit each, in the order A, B, Select, Start, Up, Down, Left, Right:

#excerpt-at("listings/netcat/pad.c", "listings/netcat/pad.c",
  "static uint8_t read_pad(void)", to: "uint8_t pad_poll(void)", size: 7pt)

`$4016` is not a mailbox page, so nothing here worries the one rule. A
program that also reads a Family BASIC keyboard shares the port with it; the
keyboard routines put it back the way they found it.

== Typing without a keyboard

Every FujiNet program on the NES that needs text -- a player's name, a
password, a URL -- puts a keyboard on the screen. The games use a ten-wide
grid of upper-case letters and digits; CONFIG and the netcat add lower case,
the punctuation a URL needs, and SHIFT, SPACE, DEL and DONE. The pad moves a
highlight, A presses the key under it, B deletes, Start is DONE.

#shotfig("netcat-url", caption: [The netcat's on-screen keyboard, with the
URL it will connect to above it.], w: 2.4in)

== Sound

The games make their sounds on the 2A03's two pulse channels, playing in
unison for volume, with the triangle and noise channels for explosions. A
pulse channel's 11-bit timer is the CPU clock over sixteen times the
frequency, less one -- `111861 / Hz - 1` -- which bottoms out about 55 Hz.

#caution[Leave the pulse channels' sweep units with the negate bit *set*
(`$4001` = `$08`), even when you are not sweeping. With it clear, the sweep
unit's overflow check silences low notes.]
