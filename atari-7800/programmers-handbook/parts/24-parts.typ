#import "../lib.typ": *
= Parts List

Every address, register, command and listing in this handbook was transcribed from these, at these revisions, and every program was built and run against them. When ordering repair parts, always include the part number.

#sect[The cartridge]

#dotdef(
  ([Mailbox, loader, boot block, mappers, POKEY, HSC], [fujinet-firmware pico/atari-7800 \@ 07e9bbaa9]),
  ([Shared mailbox protocol and fujimail], [fujinet-firmware pico/common \@ 07e9bbaa9]),
  ([Client library, start-up, text, test programs], [pico/atari-7800/testrom \@ 07e9bbaa9]),
  ([Checkers: checkrom.py, mka78.py, mkfont.py], [pico/atari-7800/tools \@ 07e9bbaa9]),
  ([MAME cartridge model], [pico/atari-7800/emu \@ 07e9bbaa9]),
  ([Board], [fujinet-hardware ATARI-7800/FujiNet-7800-Rev0]),
)

#sect[The adapter]

#dotdef(
  ([Command dispatch: FUJI device and mixins], [lib/device/rs232, fujiDevice \@ 07e9bbaa9]),
  ([Network device], [lib/device/NDevice \@ 07e9bbaa9]),
  ([Clock], [lib/device/fujiClock \@ 07e9bbaa9]),
  ([fujinet-pc on the bench], [v1.6-5501c94a, RS232 build]),
  ([Bus-over-IP], [127.0.0.1:9986]),
)

#sect[The programs]

#dotdef(
  ([fujinet-lib, atari7800 target], [fujinet-lib-experimental add-atari7800 \@ 1ebf9d0 (PR 152)]),
  ([Tile engine, CONFIG], [fujinet-config atari7800 \@ f38ed1d]),
  ([Battleship], [fujinet-battleship \@ 87b8cc7]),
  ([Battleship server], [fujinet-game-system/battleship \@ 19770c3]),
  ([This handbook’s programs], [listings/asm, listings/c, listings/bas]),
)

#sect[The tools]

#dotdef(
  ([cc65: ca65, ld65, cc65, cl65], [V2.19, 92fa7cb23]),
  ([7800basic], [v0.41, e7c18d2]),
  ([dasm], [2.20.16]),
  ([MAME, a7800 driver with the cartridge], [533800328a2]),
  ([Typst], [0.14.2]),
  ([ITC Eras Std, Source Code Pro], [fonts/]),
)

#sect[Further reading]

#dotdef(
  ([Every devicespec and protocol], [The FujiNet Network Protocol Handbook]),
  ([MARIA, the DLL and display lists], [Atari 7800 Software Guide]),
  ([7800basic’s statements], [randomterrain.com/7800basic.html]),
  ([Style reference], [ATARI 7800 ProSystem Owner’s Manual, 1986]),
)

#v(1fr)
#align(center, text(size: 6.6pt, fill: gray)[FN7800-PH REV. A · PRINTED IN THE FUJINET PROJECT])
