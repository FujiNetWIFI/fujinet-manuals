#import "../lib.typ": *
= Your FujiNet Cartridge

#ini[T]he FujiNet cartridge for the ATARI 7800 ProSystem is a network adapter that plugs into the cartridge slot. Inside the shell are two computers and a memory chip. An RP2354B microcontroller and 512K of static RAM sit on the cartridge edge. The console reads the RAM itself: its address lines A0–A12 and its data lines go straight to the chip, and the RP2354B only decides, through a table in its PIO, which 8K page of the RAM each slot of the console's address space shows. Nothing stands in a game's way, so MARIA can read the cartridge as fast as it reads any other.

Behind the RP2354B, over a USB cable, an ESP32-S3 runs the FujiNet firmware. It carries the WiFi radio, the SD card, the network protocols and everything else a FujiNet does on every other computer it has been built for.

The console never sees the ESP32-S3. It sees a signed boot block when the power comes on, a 512-byte loader at `$0600`, a mailbox from `$0800` to `$0FFF`, a POKEY at `$0450`, a High Score Cart when one is installed, and up to 448K of program in the RAM, laid out the way any of ten real 7800 cartridge boards would lay it out. This handbook is about all of them.

#sect[What you should have]

- A FujiNet cartridge, or the FujiNet cartridge model grafted into MAME, which is what every program in this handbook was verified on.
- A FujiNet adapter to talk to: an ESP32-S3 running the `fujiversal-atari7800` firmware, or `fujinet-pc` on the same machine as MAME, listening on bus-over-IP.
- cc65 2.19: `ca65` and `ld65` for the assembly programs, `cc65` for the C ones.
- fujinet-lib, built for its `atari7800` target, for the C programs.
- 7800basic, for the BASIC programs.
- This handbook.

#note[The cartridge edge carries no reset line. The console's RESET switch is a bit in `SWCHB` that your program reads like a joystick; it does not reach the cartridge. Only a power cycle sends the cartridge back to its boot block.]

#important[The FujiNet 7800 board is a Rev0 design that has not yet been built. Everything in this handbook ran in host tests and in the MAME cartridge model. The first thing a real board must prove is that the console lets the cartridge answer at `$0600`–`$0FFF`, where the mailbox lives.]

#sect[How this handbook is organised]

Sections 3 through 9 are the machine: the memory map, the mailbox, the display, the memory you have to work in, and the three languages. Sections 10 through 15 are programs, each one written three times: in 6502 assembly, in C, and in 7800basic. Sections 16 through 19 are the command reference: every command the adapter answers, and everything the cartridge itself does. Section 20 walks through Battleship, a complete networked game, and Section 21 through CONFIG. The rest is what went wrong on the way, and how to tell when it is going wrong for you.
