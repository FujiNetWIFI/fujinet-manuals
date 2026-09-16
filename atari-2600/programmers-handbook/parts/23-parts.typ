#import "../lib.typ": *
= Parts List

Everything in this handbook is transcribed from these, at these revisions. When ordering repair parts, always include the part number.

#sect[The cartridge]

#dotdef(
  ([The bring-up: mailbox spec, RP2040 firmware, MAME device, testroms, tools], [fn-2600/pico/atari-2600, 2026-09-15]),
  ([The single source of truth], [firmware/include/fuji_mailbox.h]),
  ([The client library], [testrom/fujinet.inc, fujilib.inc, fujidisp.inc, vcs.inc]),
  ([The static check and the equate check], [tools/checkrom.py, tools/checkdefs.py]),
  ([The font], [tools/vcsfont.py]),
  ([The MAME cartridge device], [emu/fujinet.cpp, emu/apply.sh]))

#sect[The adapter]

#dotdef(
  ([FujiNet firmware, RS232 build], [fujinet-firmware d38e32543]),
  ([The command ids and device ids], [include/fujiCommandID.h, fujiDeviceID.h]),
  ([The RS232 devices], [lib/device/rs232/]),
  ([The shared mixins: appkeys, base64, hash, QR], [lib/device/fujiDevice/]),
  ([fujinet-pc, the adapter on a PC], [fujinet-pc-rs232 2a9e2c23f, bus-over-IP 127.0.0.1:9995]))

#sect[The programs]

#dotdef(
  ([Battleship for the Atari 2600], [fujinet-battleship b59ec45]),
  ([The Battleship server], [battleship.carr-designs.com]),
  ([CONFIG for the Atari 2600], [fujinet-config b4e3805]),
  ([This handbook's examples], [fujinet-manuals/atari-2600/programmers-handbook/listings/]))

#sect[The tools]

#dotdef(
  ([Macroassembler AS], [asl, p2bin, Bld 305]),
  ([batari Basic], [v1.7 native binaries, source efd6dcd]),
  ([dasm], [2.20.16, c361b82]),
  ([MAME], [ea1dad92a34, with the FujiNet cartridge device grafted]),
  ([Typst], [0.15.1]),
  ([fontforge, for the screen font], [20251009]))

#sect[Further reading]

#dotdef(
  ([The FujiNet Network Protocol Handbook], [every scheme the N: device speaks]),
  ([The FujiNet Platform Bring-Up Guide], [how a cartridge like this one is made]),
  ([The FujiNet Programming Guides for the Intellivision, Bally Astrocade and ColecoVision], [the same mailbox on the siblings]),
  ([Stella Programmer's Guide, Steve Wright, 1979], [the TIA, from the people who built it]))

#v(1fr)
#align(center, text(size: 7pt, fill: gray)[LITHO IN THE FUJINET PROJECT])
