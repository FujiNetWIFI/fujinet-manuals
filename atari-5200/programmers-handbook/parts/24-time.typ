#import "../lib.typ": *
= Things That Cost Real Time <ch-time>

Every one of these cost somebody an afternoon, in the cartridge’s bring-up or in the writing of this handbook. Each is written down so it costs you nothing.

#sect[On the console]

- *A held key counts many times.* The BIOS scans the keypad with POKEY’s debouncing off, so POKEY interrupts on every pass over a held key, and the key-down bit drops between passes. A handler that counts interrupts sees one press as several; a held #key("#") once booted a random file in CONFIG. Count a key, then ignore it until it has been gone for four frames (@ch-pads).
- *The stick needs `CONSOL` bit 2.* The pots are switched off until a program writes `$04` (or more) to `CONSOL`, and neither the BIOS nor either start-up file does it. MAME does not model the switch, so a program that forgets runs in the emulator and not on a console. cc65’s joystick driver and the M.U.L.E. client set it; check your own.
- *Which button is which.* MAME and the Atari800 emulator call GTIA’s `TRIG` the first button and POKEY’s `SKSTAT` bit 3 the second; the Owner’s Manual says the bottom buttons are the fire buttons for every game. Some FujiNet ports call `TRIG0` the top button. Until someone checks on a controller, write programs that do not care.
- *MAME’s `CHBASE` comes once a mode line.* A display-list interrupt that changes the font late on a busy line shows the old font on the next row, in MAME only (@ch-antic).

#sect[On the cartridge]

- *There is no read/write line.* Every byte to the cartridge travels in an address. A store into the window is a fight for the bus, and an `INC` is two events (@ch-mailbox).
- *Two reads in a row can be one.* On the four-port console there is no clock on the edge, and the cartridge decides an access has happened when the address holds still; two cycles at the same address merge. Nothing in the mailbox ever reads one hotspot twice in a row.
- *Bounty Bob’s banks are where the hotspot is, not what it reads.* The bank a read of `$4FF6`–`$4FF9` picks is the address minus `$4FF6`. The cartridge’s first emulation of the board got it wrong in the same way the test that checked it did; an independent test from the documentation caught it.
- *An old fujinet-pc pushes nothing.* One built before the `.a52` extension was known mounts a 5200 image as a disk, says yes, and the cartridge waits for a push that never comes. CONFIG now says `?NOT A CARTRIDGE IMAGE` after three seconds instead of waiting a minute (@ch-config).
- *MAME runs a throttled cartridge on its own thread.* Under `-nothrottle` the model does each transaction inside the CPU’s read, so nothing moves during a push; throttled, it works as the real cartridge does, and the progress bar moves. Drive a program that talks to a live server with MAME throttled (`THROTTLE=1`), or it burns emulated seconds waiting.

#sect[In this handbook’s code]

- *`fn_txb` takes its byte in Y.* The assembly library carries the byte in the address of `LDA FN_TXDATA,Y`, so the 7800 programs this handbook’s were ported from, which counted their strings in Y, sent garbage, and assembled perfectly. Every loop round `fn_txb` counts in X, and `snipcheck.py` refuses one that does not.
- *The library’s timeout is in seconds.* The 7800’s counted loops; the 5200’s counts frames by the VBI, so its `FN_TMO` values are seconds: 66 for a mount, 96 for the network.
- *cc65 reads `'\n'` as `$9B`.* On the Atari targets, C’s newline is the Atari’s end-of-line. `netget.c` ignored every line ending until they were spelled `0x0A` and `0x0D`.
- *The assembly zero page starts on top of `KEY`.* `a52.cfg` gives the linker `$19` up, and `$19` is the keypad’s byte (@ch-ram).
- *cc65’s console lives where the C stack goes.* Its screen is at `$3E20`; reserve at least `$1E0` bytes or the stack writes on it (@ch-display).
- *cc65 drops a read it thinks is useless*, even an inline `lda` that switches a bank. Bank switches go in assembly files (@ch-banks).
- *The 5200 header moved.* fujinet-lib’s pull request for the 5200 keeps `fujinet-atari5200.h` in `bus/atari5200/`, and MekkoGX puts only `include/` on the path, so a program that includes it must add the other directory itself. This handbook’s build does; the games’ do not yet, and build against fujinet-lib-experimental.
- *The count starts over at every program.* The 5200 cartridge watches the console’s power and repaints its status page at every hand-over, so `ACKSEQ` is 0 whenever a program starts. Take the next number from it all the same (@ch-mailbox).
- *The bench’s `fnconfig.ini` has Windows line endings.* An edit that anchored on the end of the line changed nothing, and the private adapter came up on another bench’s port.
