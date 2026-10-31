#import "../lib.typ": *
= Parts List <ch-parts>

Every address, register, command and listing in this handbook was transcribed from these, at these revisions, and every program was built and run against them. When ordering repair parts, always include the part number.

#sect[The cartridge]

#dotdef(
  ([Mailbox, stub, boards, power-on], [fujinet-firmware pico/atari-5200 \@ 7a53805c8]),
  ([Shared mailbox protocol and fujimail], [fujinet-firmware pico/common \@ 7a53805c8]),
  ([Client library, start-up, text, test programs], [pico/atari-5200/testrom \@ 7a53805c8]),
  ([Checkers: checkrom.py, mkfont.py], [pico/atari-5200/tools \@ 7a53805c8]),
  ([MAME cartridge model], [pico/atari-5200/emu \@ 7a53805c8]),
  ([Baked CONFIG], [pico/atari-5200/firmware/baked \@ 7a53805c8]),
  ([Board], [fujinet-hardware ATARI-5200/FujiNet-5200-Rev0]),
)

#sect[The adapter]

#dotdef(
  ([Command dispatch: FUJI device and mixins], [lib/device/rs232, fujiDevice \@ f0b62cb09]),
  ([Network device], [lib/device/NDevice \@ f0b62cb09]),
  ([Clock], [lib/device/fujiClock \@ f0b62cb09]),
  ([fujinet-pc on the bench], [v1.6-f0b62cb09, RS232 build]),
  ([Bus-over-IP], [127.0.0.1:9952]),
)

#sect[The programs]

#dotdef(
  ([fujinet-lib, atari5200 target], [tschak909/fujinet-lib add-atari5200 \@ 7cf47dc (FujiNetWIFI/fujinet-lib PR 139)]),
  ([Start-up, linker configuration, romstamp], [tschak909/MekkoGX add-atari5200 \@ faeb3fd (FozzTexx/MekkoGX PR 27)]),
  ([fujinet-lib for CONFIG and the games], [fujinet-lib-experimental add-atari5200 \@ 7101377]),
  ([CONFIG, and the C text engine], [fujinet-config main \@ 1bd6ec8 (atari5200/ \@ cb44218)]),
  ([Battleship], [fujinet-battleship main \@ 3f2a548]),
  ([5 Card Stud], [fujinet-5cardstud main \@ d5db857]),
  ([Game servers], [fujinet-game-system \@ 19770c3]),
  ([This handbook’s programs], [listings/asm, listings/c]),
)

#sect[The tools]

#dotdef(
  ([cc65: ca65, ld65, cc65, cl65], [V2.19, 92fa7cb23]),
  ([MAME, single-driver a5200 build], [mamedev \@ 533800328a2, with the cartridge model grafted]),
  ([5200 BIOS], [MAME a5200.zip, co19156.u8]),
  ([Typesetting], [Typst 0.14.2]),
  ([Type], [Helvetica; ITC Avant Garde Gothic; Source Code Pro]),
  ([House style], [ATARI 5200 Owner’s Manual, 1982, CO 19277]),
)

#sect[This handbook]

#dotdef(
  ([Part number], [FN5200-PH REV. A]),
  ([Source], [fujinet-manuals atari-5200/programmers-handbook]),
)
