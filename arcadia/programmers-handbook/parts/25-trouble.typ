#import "../lib.typ": *

= Trouble Shooting Check List <trouble>

#symrem(
  ([NO FUJINET CART, or FAILED FE], (
    [The program is not on a FujiNet cartridge: an EPROM, or MAME without
     `-cartslot fujinet`.],
    [An image without the claim was booted earlier this session and killed
     the mailbox. Press the cartridge’s RESET.],
  )),
  ([FAILED FF on a console, never in MAME], (
    [The program waited less than the cartridge allows (5, 60 or 90 s) and
     gave up: MAME answers inside one read. Wait with `FNGO`.],
  )),
  ([FAILED 15], (
    [The FujiNet said NAK. Check the parameter count and sizes against the
     card in Sections 17--19: SET_SSID wants all 97 bytes, OPEN_DIRECTORY and
     SET_DEVICE_FULLPATH exactly 256, OPEN_APPKEY six, reserved byte and all.],
    [The command is one this build refuses (the end of Sections 17 and 18):
     RANDOM_NUMBER, UNMOUNT_HOST, NET_GET_ERROR and others.],
  )),
  ([FAILED 01], (
    [The USB link to the network chip is down: on a cartridge, its power or
     its firmware; in MAME, no fujinet-pc on `FUJINET_TCP`.],
  )),
  ([After the console’s RESET, nothing answers], (
    [The program keeps its own sequence counter and wrote a number the
     cartridge has already answered. Use ACKSEQ + 1 every time (`FNCOMMIT`
     does).],
  )),
  ([The text fills only the top half of the screen], (
    [Bit 7 of `$19F9` is set: 8 × 8 characters. `DINIT` sets it; write `$07`
     after it (`BKINIT`) for 8 × 16.],
  )),
  ([The rest of a row turns into blocks], (
    [A cell holds exactly `$C0`, a space with colour bits `11`. Paint spaces
     with other colour bits.],
  )),
  ([Wrong colours after reading the disc], (
    [The pot multiplexer was written without the rest of `$19F9`. Keep the
     register’s base value and OR bit 6 into it.],
  )),
  ([A menu scrolls down by itself], (
    [The left disc is read outside the vertical blank, where it reads `$FF`.
     Wait with `TPSU $80` first.],
  )),
  ([A slash or a dash prints as a sprite’s shape], (
    [The program uses sprites, whose images are characters `$38-$3B`, and
     prints with `fujidisp.inc`’s `/ - _ :` there.],
  )),
  ([The program returns somewhere it never called from], (
    [More than eight calls deep. `depthcheck.py` counts what `checkdepth.py`
     misses: branches and fall-through into a routine’s own labels.],
  )),
  ([AS: "target not on same page"], (
    [A load, store or ALU instruction names an address in the other 8K page.
     Go through a pointer word (Section 8), or move the code.],
  )),
  ([A pointer goes to the wrong address], (
    [It was written with `DW`, low byte first. Use `DWBE`.],
  )),
  ([`EORZ R1` did not clear R1], (
    [It acts on R0. Use `LODI,R1 0`.],
  )),
  ([A folder shows without its `/`], (
    [READ_DIR_ENTRY was asked for fewer than 36 characters.],
  )),
  ([A boot ends FAILED, BOOT_ERR 3], (
    [The image is over 8K and not 8,192 + _k_ × 2,048 bytes with the claim.],
  )),
  ([A protocol 2 program starts in the wrong page after RESET], (
    [RESET keeps the page. Select page 0 in the start code.],
  )),
  ([A test script’s keys are never seen], (
    [It counts MAME’s `machine.time.seconds`, which is whole seconds. Count
     frames.],
  )),
  ([A test against a server gives up early], (
    [MAME is unthrottled and burns the program’s waits in no real time. Run
     with `THROTTLE=1`.],
  )),
  ([Two test runs disturb each other], (
    [Two MAMEs on one fujinet-pc. Run one at a time, and stop strays by pid.],
  )),
  ([A program cannot get back to CONFIG], (
    [No ARCADIA-2001 program can. Press the cartridge’s RESET, then the
     console’s.],
  )),
)

== Where the sources disagree

#tbl((2.1in, 1fr),
  [*Where*], [*What*],
  [`pico/arcadia/tools/checkdepth.py`], [counts calls only, one node a label, so a fall-through (FNCOMMIT into FNCM1) or a branch (CHKACK to FAIL) runs at a depth it does not count. Its figure is a lower bound: `fujiboot` 3 where it is 4. Both game READMEs audit by hand for this reason.],
  [`testrom/fujidisp.inc`, `DINIT`], [writes `$87`, "8x8 chars": right, but the 13 rows then fill only the top half of the picture, unlike CONFIG’s screens.],
  [`testrom/fujidisp.inc`, its head], ["never emit color bits 11": only `$C0` itself, colour bits `11` and glyph 0, switches the row; blue on any other glyph is safe, and 5 Card Stud uses it.],
  [`testrom/*.asm`, `START`], [clears the upper status byte, leaving interrupts enabled behind the `$0003` guard; CONFIG sets `$20`, inhibited.],
  [`testrom/fujilib.inc`, `FNCOMMIT`], [waits about 6 s, CONFIG’s `MCOMMIT` 12, and the cartridge allows 60 or 90 for a mount or a network command.],
  [the Arcadia Battleship and 5 Card Stud], [do not read the shared player-name app key; they ask for a name each time.],
  [`include/fujiCommandID.h`], [names RANDOM_NUMBER (`$D3`), which the RS-232 build does not answer.],
)
