#import "../lib.typ": *
= Banks and the Tail

A 2K bank holds a screen and a few transactions. A program that wants more --- CONFIG has seven screens, Battleship seven banks --- switches banks, and on this cartridge that is a store: `$1D80` plus the bank number, and the switch is complete before the console's next fetch. What makes it usable is the fixed tail, the 220 bytes at `$1F20`--`$1FFB` that every bank sees at the same address.

#sect[A switch is a jump]

A bank switch replaces every byte of `$1000`--`$17FF`. The instruction after the store is fetched from the new bank, so the store must be made from somewhere that does not change: the tail. Battleship's trampoline is the whole of it, and its stack reset is not decoration:

#excerpt-at("bscore.inc: the trampoline", "listings/battleship/src/bscore.inc", "BSGOTO", to: "; The cold stub", size: 6.6pt)

Nothing returns through a bank switch, and Battleship takes its switches from inside the per-frame hook, which the display loop reached with a `JSR`. Two bytes leaked per poll, a poll every ninety frames, and after thirty-five of them the stack had grown down out of its region and was overwriting the program's cells. The trampoline resets the stack on every switch, and because it is fetched from the fixed tail, the reset still executes after the bank has already changed.

"Where to carry on" is therefore data: Battleship keeps an entry code in a zero-page cell, and every bank's entry point dispatches on it.

#sect[The cold stub]

The RESET vector points at the tail, never into a bank, because the RESET switch restarts the 6507 with whatever bank was last selected still mapped. The stub is deliberately tiny --- the arming pair, because banking is a control-page operation and the control page decodes nothing until the pair has arrived, then bank 0 --- and it forces a cold entry:

#excerpt-at("bscore.inc: the cold stub", "listings/battleship/src/bscore.inc", "BSCOLD", to: "        ORG     $1FFC", size: 6.6pt)

The console does not clear RAM on a reset. A reset taken at Battleship's keyboard once came back into the lobby's warm path, which redrew a table list out of a reply window that was holding a game.

#sect[Every bank carries its own library]

There is no shared code region but the tail. The high 2K is the mailbox in its entirety, so each bank includes its own copy of the transport and the display kernel, about 600 bytes --- which is what F8 games have always done. Battleship puts the routines every bank calls in the tail (the transport, 151 bytes; the four text primitives, 24) and generates the equates for them from the tail's own listing, so that no hand-kept list can go stale; the rest is per bank, behind feature flags so that a bank carries only what it calls. A byte added to a shared include costs a byte in every bank that includes it.

#sect[Building a banked image]

The image is N banks of 2K then the fixed half, and N is 1, 3, 7 or 15 so that the size is one MAME will load; Battleship pads seven banks to eight. Each bank is assembled at `$1000`--`$17FF` and the tail at `$1800`--`$1FFF`, and the parts are concatenated in order. The bring-up's `build.sh` has a `build_banked` that does exactly this, and Battleship's has two checks it grew the hard way:

#caution[`p2bin` emits its whole address range whatever was assembled, so an over-long bank is truncated in silence: the image builds, the size is right, the static check passes, and the instructions past `$17FF` are simply gone. The assembler's listing is the only thing that knows, and Battleship's `checkbanks.py` asks it. Its `mktail.py` likewise fails a tail that runs past `$1FFB` into the vectors.]

Then the claim is stamped and `checkrom.py` scans every bank, because every bank is entered at `$1000` and every bank is code. Section 19 has Battleship's bank map and budget.

#sect[batari Basic]

A batari Basic program is one bank, and this section is why. Its own `bank` statements assume 4K banks with trampolines and vectors at the top of each, which is the mailbox; a program that outgrows 2K is written in assembly, or splits its work between the cartridge and the adapter. Most of what a 2K program cannot hold, it does not have to: the cartridge holds the strings and composes the screen, and the adapter does the network.
