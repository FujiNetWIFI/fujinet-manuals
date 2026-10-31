#import "../lib.typ": *
= Your FujiNet Cartridge <ch-unpack>

The FujiNet cartridge for the ATARI 5200 is a network adapter that plugs into the cartridge slot. Inside the shell are two computers. On the cartridge edge sits an RP2354B microcontroller. It answers every read the console makes of the cartridge, as a ROM chip would, and puts its byte on the bus through a 74HCT541 buffer that only the console’s own cartridge enables can open.

Behind the RP2354B, over a USB cable, an ESP32-S3 runs the FujiNet firmware. It carries the WiFi radio, the SD card, the network protocols and everything else a FujiNet does on every other computer it has been built for.

The console never sees the ESP32-S3. It sees CONFIG when the power comes on, a mailbox from `$B000` to `$B7FF`, and up to 128K of program, laid out the way a plain ROM, a two-chip board, Bounty Bob Strikes Back or a Super Cart would lay it out. This handbook is about all of them.

#sect[What you should have]

When you set up to work through this handbook, you will have:

- A FujiNet cartridge, or the FujiNet cartridge model grafted into MAME, which is what every program in this handbook was verified on.
- A FujiNet adapter to talk to: an ESP32-S3 running the `fujiversal-atari5200` firmware, or `fujinet-pc` on the same machine as MAME, listening on bus-over-IP.
- cc65 2.19: `ca65` and `ld65` for the assembly programs, `cc65` for the C ones.
- fujinet-lib, built for its `atari5200` target, and MekkoGX, which carries the start-up code and the linker configuration, for the C programs.
- This handbook.

#note[The cartridge edge carries no reset line and no read/write line. The #key("RESET") key on the controller is a keypad code that your program reads like any other; it does not reach the cartridge. Only a power cycle, or a program that asks for it, sends the cartridge back to CONFIG.]

#important[The FujiNet 5200 board is a Rev0 design that has not yet been built. Everything in this handbook ran in host tests and in the MAME cartridge model. The first things a real board must prove are its timing on a console with no clock on the edge, and that reads the console makes twice in a row are told apart.]

#sect[How this handbook is organised]

Sections 3 through 9 are the machine: the memory map, the mailbox, the display, the memory you have to work in, the two languages, and the controllers. Sections 10 through 16 are programs, each one written twice: in 6502 assembly and in C. Sections 17 through 20 are the command reference: every command the adapter answers, and everything the cartridge itself does. Sections 21 through 23 walk through Battleship and 5 Card Stud, two complete networked games, and CONFIG. The rest is what went wrong on the way, and how to tell when it is going wrong for you.

#shot("asm-hello", caption: [The first program in Section 5, running from the cartridge in the MAME model.])
