#import "../lib.typ": *
= Things That Cost Real Time

#ini[E]very fact in this handbook was bought with time, and some of them were expensive. Here are the expensive ones, so you do not have to pay again.

#sect[The milestones]

The cartridge was brought up in the FujiNet MAME model, one milestone at a time, each with a test that had to pass before the next began:

#tbl((auto, 1fr, 1fr),
  th[Milestone], th[What it proved], th[Exit test],
  [M0], [The boot block passes the BIOS’s signature check, on NTSC and PAL; the loader runs; MARIA shows text.], [`sigtest.lua`: the BIOS leaves by its success exit; a deliberately broken block fails.],
  [M1], [One real transaction, and the cartridge outliving a power cycle of the console.], [`fujitest` shows the live SSID; `powertest.lua` requires the next sequence number to be 2, not 1.],
  [M2], [Booting over the network, every board layout.], [`fujiboot` and `fujibank`; every image the database knows pushed and started.],
  [Tier A], [The cartridge serves each of 126 known games exactly as MAME’s own cartridge does.], [Frame-for-frame screenshots: 126 of 126.],
  [Tier C], [Each of the 126 pushed over the network, byte-exact in the RAM, started the right way.], [126 of 126, and again with every hand-over forced direct.],
  [POKEY], [The synthesiser sounds like MAME’s POKEY.], [`pokeycmp.py`: 13 of 13 test steps; Ballblazer and Commando within 0.97 of MAME’s loudness.],
  [HSC], [High scores survive a power cycle through the FujiNet’s SD card.], [`hscram.lua`: two MAME runs print the same HSC RAM.],
)

The BIOS verdicts the cartridge carries came from the same bench: of the 126 images, 72 pass both consoles’ signature checks, 51 only the PAL one, and 3 neither. Those three run only by the direct hand-over.

#sect[In the cartridge]

- *MARIA reads the cartridge too fast for a microcontroller.* Its DMA windows are 280 to 420 nanoseconds. That ruled out serving game ROM from the RP2354B and put a real SRAM on the edge, with the RP2354B only steering its upper address lines. It is also why nothing MARIA reads may live in the mailbox.
- *Only the first INPTCTRL lock counts.* A game writes TIA values with bit 0 set long after it locked the console; the cartridge’s model of INPTCTRL must stop at the first lock, or it believes every game turned 2600.
- *MAME hides the BIOS’s view of the cartridge.* Every mode change had to be triggered by a write, because MAME does not show the cartridge the BIOS’s reads of `$FFFC`.
- *MAME does not emulate the NTSC console’s fall back to 2600 mode,* so a broken signature can look fine in MAME. The negative test exists for that reason.
- *MAME runs an autoboot script again on every reset.* Harness state lives in `_G`, or it starts over halfway through.
- *Activision images* in the No-Intro set have their 8K halves the other way round from MAME’s. The database carries a flag for them.

#sect[In this handbook]

- *7800basic miscompiles two things without a word.* An expression in an array index (`A[ix + 2]`) and an expression in a `for` bound (`to n - 1`) both compile and both do the wrong thing. One extra byte in an appkey gave the second away. Section 9.
- *The vendored ITC Eras fonts report half their real cap height.* Typst set lines on top of one another until `tools/fixeras.py` wrote the true values in.
- *A smart quote after a digit is a prime*, which Eras does not have: `7800’s` must be typed with its apostrophe already curly, or a fallback font creeps into the book.
- *A game server counts real seconds.* Battleship sat at “STARTING IN 2” for sixteen seconds of emulated time, because MAME was running fifty times faster than the server’s clock. `THROTTLE=1`.
- *A comment can be out of date.* CONFIG’s notes say COPY_FILE must go at its exact length; on today’s firmware fujinet-lib’s padded payload copies the file perfectly well. The test took a minute; the claim would have stood for years.
- *The clock’s commands are not what their names say.* GETTIME answers six bytes; SETTZ sets the *alternate* zone. Measured on the bench, and Section 18 says so.
- *fujinet-lib’s romstamp checks only 32K and 48K images.* A banked C program needs `tools/checkbanks.py`, which scans each bank where it lies in the file.
- *A font in a switched bank* turns to garbage while another bank is in. MAME will not show it, because a transaction there finishes inside one store; on a real cartridge the display runs while the program waits. Section 14.
