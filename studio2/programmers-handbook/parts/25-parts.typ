#import "../lib.typ": *
#set page(columns: 1)
#refpage.update(true)

= Parts List <parts>

#hang([], [Every address, register, command and listing in this handbook was transcribed from these, at these revisions, and every program was built and run against them. When ordering repair parts, always include the part number.])

#sect[The cartridge]

#hang([], dotdef(
  ([Window server, mailbox, text engine, loader], [fujinet-firmware pico/studio2 \@ 07e9bbaa9]),
  ([Shared mailbox protocol and fujimail], [fujinet-firmware pico/common \@ 07e9bbaa9]),
  ([Runtime and the bring-up programs], [pico/studio2/testrom \@ 07e9bbaa9]),
  ([Checkers: checkrom.py, mkst2.py, st2.py], [pico/studio2/tools \@ 07e9bbaa9]),
  ([MAME cartridge model and its Lua], [pico/studio2/emu \@ 07e9bbaa9]),
  ([ESP32-S3 board: fujiversal-studio2], [build-platforms, include/pinmap \@ 07e9bbaa9]),
  ([Board, Rev0: RP2354B, ESP32-S3, '541, CP2102N], [fujinet-hardware RCA-Studio-II/FujiNet-StudioII-Rev0 \@ 0e539b8]),
))

#sect[The adapter]

#hang([], dotdef(
  ([Command dispatch: FUJI device and mixins], [lib/device/rs232, fujiDevice \@ 07e9bbaa9]),
  ([Network device], [lib/device/NDevice \@ 07e9bbaa9]),
  ([Clock], [lib/device/fujiClock \@ 07e9bbaa9]),
  ([fujinet-pc on the bench], [v1.6-07e9bbaa9, RS232 build]),
  ([Bus-over-IP], [127.0.0.1:9973]),
))

#sect[The programs]

#hang([], dotdef(
  ([CONFIG], [fujinet-config studio2 \@ 86c763d]),
  ([5 Card Stud], [fujinet-5cardstud studio2 \@ 1008f9a]),
  ([Battleship], [fujinet-battleship studio2 \@ 87b8cc7]),
  ([Game servers], [servers fujinet-game-system \@ 19770c3]),
  ([This handbook’s programs], [listings/asm]),
))

#sect[The tools]

#hang([], dotdef(
  ([Macroassembler AS], [1.42 Beta, build 306]),
  ([MAME, studio2 driver], [533800328a2 + the cartridge graft]),
  ([Python], [3.14]),
  ([Typst], [0.14.2]),
  ([Fonts], [Helvetica; Adobe Bodoni Std Book Italic; Source Code Pro]),
))

#sect[Further reading]

#hang([], dotdef(
  ([The 1802 itself], [RCA MPM-201A, CDP1802 User Manual, 1976]),
  ([The console], [RCA Studio II Owner’s Manual, 1977]),
  ([Every protocol a devicespec can name], [The FujiNet Network Protocol Handbook]),
  ([The other consoles], [the FujiNet programmer’s handbooks for the 2600, 7800, Astrocade, ColecoVision, Intellivision and NES]),
))

#hang([], [FN-S2-PH. First edition, 2026.])

#refpage.update(false)
