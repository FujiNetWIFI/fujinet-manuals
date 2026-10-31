#import "../lib.typ": *
= Controllers, Keypad and Sound <ch-pads>

The 5200 controller is three inputs in one case: an analog stick, two buttons on each side, and a twelve-key keypad with #key("START"), #key("PAUSE") and #key("RESET") above it. The original console has four controller jacks; the later two-port console, two. Each part of the controller reaches the 6502 through a different chip.

#tbl((0.9fr, 1.1fr, 1.6fr),
  th[Part], th[Read from], th[How],
  [The stick], [POKEY’s pots, through `PADDL0`–`7`], [Two pots per controller. Controller 1’s X and Y are `PADDL0` and `PADDL1`, controller 2’s the next two, and so on. Near 0 at one end, 228 at the other, 114 at rest.],
  [The bottom buttons], [GTIA: `TRIG0`–`TRIG3`, `$C010`–`$C013`], [0 while held. The Owner’s Manual calls these the fire buttons for every game.],
  [The top buttons], [POKEY: `SKSTAT` bit 3, `$E80F`], [Clear while the top button of the selected controller is held.],
  [The keypad and START, PAUSE, RESET], [POKEY: `KBCODE`, `$E809`, by interrupt], [The selected controller’s keypad only.],
)

“Selected” means picked by `CONSOL` at `$C01F`, which on the 5200 is an output: bits 0 and 1 choose the controller whose keypad and top button POKEY scans, and bit 2 turns the pots on.

#important[Write `CONSOL` before you read the stick. Neither the BIOS nor either language’s start-up code sets bit 2, and with it clear the pots read nothing on a real console. MAME’s 5200 ignores the bit, so a program that forgets runs perfectly in the emulator. `$04` selects controller 1 with the pots on.]

#sect[The stick]

The VBI copies the eight pots into `PADDL0`–`PADDL7` (`$11`–`$18`) every frame and starts the next reading, so a program reads the shadows, never the pots. The stick springs back to the middle, and its middle is not exact: treat 64 to 164 as “not pushed”, as the games do.

#sect[The keypad]

POKEY scans the selected keypad on its own and raises an interrupt when it finds a key down; the handler reads `KBCODE`, turns its four key bits into a number through a table, and counts the press.

#tbl((auto, auto, auto, auto, auto, auto),
  th[Key], th[Code], th[Key], th[Code], th[Key], th[Code],
  [0–9], [`$00`–`$09`], [#key("*")], [`$0A`], [#key("#")], [`$0B`],
  [#key("START")], [`$0C`], [#key("PAUSE")], [`$0D`], [#key("RESET")], [`$0E`],
)

The library stores the code plus one, so that 0 means no key: `KEY` (`$19`) in assembly, `fuji_a5200_key` in C. Nothing clears it; a program takes a key by reading it and storing 0.

#caution[The BIOS runs POKEY’s keypad scan with debouncing off. That way POKEY interrupts on every pass over a key that is held down, and the key-down bit in `SKSTAT` drops between passes, so a handler that counts interrupts counts one press many times. Both start-up files count a key once, then ignore it until four frames have passed without it.]

#ex((path: "listings/common/a52init.s", from: ".proc kbd_done", to: ".endproc"), t-asm)

#sect[Sound]

POKEY has four voices. Each has a frequency register (`AUDF1`–`AUDF4`, `$E800`, `$E802`, `$E804`, `$E806`; higher is lower) and a control register (`AUDC1`–`AUDC4`, the odd addresses), whose top three bits choose the distortion and bottom four the volume: `$A8` is a pure tone at volume 8, 0 is silence. `AUDCTL` at `$E808` joins voices and changes clocks; 0 is the ordinary setting. POKEY makes no sound while `SKCTL` is 0, its reset state; both start-up files leave it at `$02`, with the keypad scan running.

#sect[pads]

`pads` shows everything controller 1 is doing: the stick’s two readings, both buttons, the last key on the keypad, and a tone from voice 1 while the bottom button is held.

#shots("asm-pads", "c-pads", caption: [pads in assembly and in C, the stick pushed down and to the left, both buttons held, 5 the last key.])

In assembly, the pots go on first, then every frame the stick, the buttons, the key and the voice:

#ex((path: "listings/asm/pads.s", from: "        lda     #$04            ; the pots on", n: 2), t-asm)
#ex((path: "listings/asm/pads.s", from: "loop:   WAITFRAME", to: "        lda     #10             ; the last key"), t-asm)

The key’s name comes from a table of string addresses indexed by `KEY` itself, so the “no key” entry is entry 0:

#ex((path: "listings/asm/pads.s", from: "        lda     #10             ; the last key", to: "        lda     #12             ; a tone"), t-asm)

In C the same reads are named registers, and the voice is two assignments:

#ex((path: "listings/c/pads.c", from: "    for (;;) {", to: "            mt_puts(\"ON \");"), t-c)

#note[The stick, buttons and keys in the figures were pressed by `emu/drive.lua`, which sets MAME’s controller inputs on a timetable: `PRESS="1=x=20+y=C0+fire+top+k5;2=-k5"` pushes the stick to X `$20`, Y `$C0`, holds both buttons, and taps 5.]
