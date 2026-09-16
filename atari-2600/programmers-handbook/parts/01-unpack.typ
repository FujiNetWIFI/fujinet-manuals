#import "../lib.typ": *
= Unpack the Cartridge

The FujiNet cartridge for the Atari Video Computer System is a network adapter that plugs into the Game Program slot. Inside the shell are two computers. An RP2040 microcontroller sits on the cartridge edge and does what a cartridge does: it answers the console's every fetch within the 838 nanoseconds the 6507 allows, and serves a 4K window of memory. Behind it, over a USB cable, an ESP32-S3 running the FujiNet firmware carries the WiFi radio, the SD card, the network protocols and everything else a FujiNet does on every other computer it has been built for.

The console never sees the ESP32-S3. It sees sixteen pages of cartridge memory, and this handbook is about what is in them.

#sect[What you should have]

- A FujiNet cartridge, or the FujiNet cartridge model grafted into MAME, which is what every program in this handbook was verified on.
- A FujiNet adapter to talk to: an ESP32-S3 running the `fujiversal-rs232` firmware, or `fujinet-pc-rs232` on the same machine as MAME, listening on bus-over-IP.
- Macroassembler AS, for the assembly language programs.
- batari Basic and dasm, for the BASIC programs.
- This handbook.

#note[There is no reset line on the Video Computer System's cartridge connector, and the console has no interrupts. Both facts shape everything that follows.]

#sect[How this handbook is organised]

Sections 3 through 8 are the machine: the window, the mailbox, the display, the memory, and the two languages. Sections 9 through 14 are programs, each in 6502 assembly and in batari Basic. Sections 15 through 18 are the command reference: every command the adapter answers, and every operation the cartridge itself performs. Section 19 walks through Battleship, a complete networked game, bank by bank. The rest is what went wrong on the way, and how to tell when it is going wrong for you.
