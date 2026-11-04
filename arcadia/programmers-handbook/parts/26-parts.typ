#import "../lib.typ": *

= Parts List <parts>

Every program, figure and fact in this book comes from a source at a fixed
revision. `listings/VENDOR` names each file the book copies, and
`tools/vendorcheck.py` compares each with its source.

== The cartridge and the adapter

#dotdef(
  [Board], [FujiNet-Arcadia Rev0 (fujinet-hardware, `Emerson-Arcadia/FujiNet-Arcadia-Rev0`)],
  [Game chip], [RP2354A],
  [Network chip], [ESP32-S3],
  [Cartridge firmware, runtime, tools, MAME device], [fujinet-firmware `pico/arcadia`, `pico/common`, at `e3923e881` (pico/arcadia last changed `193d18f53`)],
  [Adapter firmware, command dispatch], [fujinet-firmware RS-232 build at `e3923e881`; the bench’s fujinet-pc is `f0b62cb09`, whose dispatch is the same],
  [The mailbox’s definition], [`pico/arcadia/firmware/include/fuji_mailbox.h`, `pico/common/include/fuji_mailbox_proto.h`],
)

== The programs

#dotdef(
  [CONFIG], [fujinet-config `arcadia/` at `6f0a60a`],
  [Battleship], [fujinet-battleship `arcadia/` at `3f2a548`],
  [5 Card Stud], [fujinet-5cardstud `arcadia/` at `d5db857`],
  [Game servers], [FujiNetWIFI/servers `fujinet-game-system` at `0945622`],
  [This book’s programs], [`listings/asm/`: `pads`, `netget`, `netcat`, `fujidir`, `appkey`, `clock`, `sprites`; and the runtime’s `hello`, `fujitest`, `fujiboot`, `fujibank`],
)

== The tools

#dotdef(
  [Assembler], [Macroassembler AS 1.42 Beta, build 306],
  [Emulator], [MAME `533800328a2` with the cartridge grafted in by `pico/arcadia/emu/apply.sh`],
  [Typesetting], [Typst 0.14.2],
  [Fonts], [Helvetica; Harry Obese; Nimbus Sans Narrow Bold; Source Code Pro],
)

== The checks

#tbl((1.45in, 1fr),
  [*Check*], [*Holds the book to*],
  [`snipcheck.py`], [every 2650 example in the text assembles, inside a program, and builds an image],
  [`cmdcheck.py`], [every command the adapter dispatches has a card in Sections 17--19, or is in a NAK list],
  [`cartcheck.py`], [every `FN_R_`, `FN_H_`, `FN_REG_`, `FN_HOT_` and `FN_BOOT_` name in the mailbox headers is in Section 20],
  [`defcheck.py`], [`fujilib.inc` and `bookdefs.inc` agree with the firmware’s headers],
  [`vendorcheck.py`], [every vendored file is what its source holds at its pin],
  [`depthcheck.py`], [no program goes more than eight calls deep, counting branches and fall-through],
  [`widows.py`], [no stranded head, widow or orphan],
  [`fontcheck.py`], [no font but the book’s four],
)

== Related publications

- _ARCADIA-2001 Owner’s Manual_ (Emerson, 1982), model ADV-1: the console.
- _FujiNet Owner’s Manual for the EMERSON ARCADIA-2001_: the cartridge,
  CONFIG and every game, for the player.
- _The FujiNet Network Protocol Handbook_: everything a devicespec can say.
- The Signetics _2650 Microprocessor_ manual: the instruction set.
- The Signetics _2637 Universal Video Interface_ data sheet: the video chip.
