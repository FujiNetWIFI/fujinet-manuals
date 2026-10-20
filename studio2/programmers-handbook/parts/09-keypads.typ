#import "../lib.typ": *

#opener-art.update((sub: [2 players · both keypads · the beeper],
  art: tvrow("keys", w: 1.6in)))
= Keypads and Sound <keypads>

Each player has a ten-key pad: 1 to 9 in a square and 0 below them. The console reads them through a CD4515 decoder and two of the 1802’s flag lines, one key at a time, and the runtime’s `input.inc` does the reading.

#fig(stack(dir: ltr, spacing: 0.3in,
  keypad(name: [KEYPAD A], hot: (5,)), keypad(name: [KEYPAD B], hot: (9,))),
  caption: [Key 5 on keypad A reads as `$A5`, key 9 on keypad B as `$B9`.])

== Reading a key

`OUT 2` sends a key number, 0 to 9, to the decoder; EF3 then says whether that key is down on keypad A, and EF4 on keypad B. `in_scan` tries all ten and answers with the first one held:

#excerpt-at(auto, "listings/runtime/input.inc", "in_scan:", to: "isc2:")

`OUT` takes its byte from memory, M(R(X)), so X points at `V_KTMP` in RAM for the length of it, and back at the stack after. Never point it at the cartridge.

#tbl((1in, 1fr),
  [*Call*], [*Gives D =*],
  [`in_scan`], [the key held now: `KEY_A` + k, `KEY_B` + k, or 0],
  [`in_get`], [a key just pressed, or held long enough to repeat],
)

`in_get` waits 24 frames before a held key repeats, then repeats it every 6. A menu that must not fire twice, such as CONFIG’s, checks for a fresh press itself: its `key_wait` repeats only 2, 4, 6 and 8, the arrows.

== Sound

The Studio II has one sound: a tone, switched on and off by the 1802’s Q line. The runtime’s display interrupt runs it for you. While RD.0 is not zero it turns Q on and counts RD.0 down, once a frame; at zero it turns Q off. A beep is one instruction pair:

#asmp("        LDI     8               ; 8 frames, about 0.13 s
        PLO     RD              ; the interrupt does the rest")

#note[The interrupt turns Q off on every frame that RD.0 is 0, so a program’s own `SEQ` lasts until the next frame at most. Make every tone with RD.0; a longer one is a bigger count.]

== Both keypads

`keys.asm` draws both keypads, lights the last key pressed on each, shows its code on the bottom row and beeps: briefly for most keys, longer for 0. The main loop is `in_get`, a beep, and a choice of pad:

#excerpt-at(auto, "listings/asm/keys.asm", "loop:   FCALL   in_get", to: "; light --")

Each key’s cell is found from a table of ten row-and-column bytes, one for each key, added to the pad’s own column:

#excerpt-at(auto, "listings/asm/keys.asm", "; cell --", to: "; where each key")
