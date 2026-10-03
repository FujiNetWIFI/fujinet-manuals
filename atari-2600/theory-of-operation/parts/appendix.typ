#import "../lib.typ": *

= Mailbox reference tables

== Blit transforms

Six stores: source offset into the reply window (`$1DF5`, `$1DF6`),
destination offset into the text planes (`$1DF7`, `$1DF8`), count
(`$1DF9`), then the transform to `$1DFA`, which fires it. What each field
means depends on the transform. BLITGEN at `$1F19` increments when it has
landed. #src[fuji\_mailbox.h:245-470]

#tbl(
  tab((auto, auto, 1fr),
    th[Code], th[Name], th[Effect],
    [0], [RAW], [copy `cnt` bytes from the reply to the planes unchanged],
    [1], [TEXT], [compose text row `dst` from up to twelve ASCII bytes at reply offset `src`],
    [2], [FIELD], [a 10 × 10 game field at reply offset `src` (0 sea, 1 hit, 2 miss) into ten text rows from `dst`, with a row digit in column 0; `cnt` = cursor cell or `$FF`],
    [3], [HULLS], [`cnt` ship placements at reply offset `src` as hull glyphs over the composed board, then paint from row `dst`],
    [4, 5, 6], [SEA, CELL, PAINT], [compose a board not in the reply: fill with sea; set `board[cnt]` to the low byte of `src`; paint into ten rows from `dst`],
    [7], [PATH], [`cnt` characters of the selected path buffer from offset `src` into text row `dst`],
    [8], [TCELL], [one character (low byte of `src`) into one cell; `dst` = row × 12 + column],
    [9], [CARD], [five playing cards from `hand[11]` at reply offset `src` across the two text rows from `dst`; `cnt` bit 0 draws the first face down],
    [10], [PFCLR], [clear the kinds in mask `src` in playfield slot `dst`],
    [11], [PFIELD], [a game field at reply offset `src` into playfield slot `dst`],
    [12], [PFHULL], [`cnt` placements at reply offset `src` OR-ed into slot `dst`'s hull tables],
    [13], [PFCELL], [one cell `cnt` of slot `dst`: set the kinds in mask `src`, or clear them if bit 7 is set],
    [14], [POKE], [`plane[dst]` = the low byte of `src`],
    [15], [PATHPOKE], [`plane[dst .. dst+cnt)` = `path[src .. src+cnt)`: a block of raw bytes out of a path buffer],
    [16], [PFTILE], [a packed 20 × 19 tile bitset at reply offset `src` into the playfield tables; `dst` = kind mask, `cnt` = rows (0 = all)],
    [17], [PFTCELL], [one tile: `dst` = kind mask, `cnt` = row, low byte of `src` = column; a clear bit in it clears],
    [18], [PATHTILE], [PFTILE out of the selected path buffer: `src` = byte offset into it],
    [19], [MULEMAP], [a 225-byte MuleMap at reply offset `src` into the planes; `dst` = flags],
  ),
  [The twenty blit transforms. 0--9 compose text and text-row boards; 10--13 and 16--18 compose the six playfield tables the Battleship and maze kernels read; 14--15 and 19 are raw plane writes.],
)

== Boot and error codes

#tbl(
  tab((auto, auto, 1fr),
    th[Cell], th[Value], th[Meaning],
    [BOOT_STATE `$1F06`], [0 / 1 / 2 / `$80`], [idle / transferring / ready (staged) / failed],
    [BOOT_ERR `$1F08`], [1 / 2 / 3 / 4], [too big (over 32K) / truncated (push aborted) / no mapper (not a whole number of 2K blocks) / store busy],
    [ERR `$1F02`], [0 / 1 / 2 / 3 / 4], [`FB_OK` / `FB_ENOLINK` no USB CDC connection / `FB_ETIMEOUT` / `FB_EBADFRAME` SLIP, length or checksum failed / `FB_ETOOBIG`],
    [REPLY_CMD `$1F03`], [`$06` / `$15`], [ACK / NAK from the adapter; a NAK is not a transport error],
    [STATUS `$1F01`], [bit 0 / bit 1], [link up / busy],
    [FLAGS `$1F0F`], [bit 0 / bit 1], [gate open / claim honoured],
  ),
  [Status values. #src[fuji\_mailbox.h:679-690; fujibus.h:43-49]],
)

== Console-side names

The 6502 clients address the mailbox through hand-mirrored equates in
`testrom/fujinet.inc`; `tools/checkdefs.py` holds them to the header.

#tbl(
  tab((auto, auto, auto, auto),
    th[Equate], th[Cell], th[Equate], th[Cell],
    [`FNTEXT`], [`$1800`], [`FNRSEL`], [`$1D00` + n],
    [`FNRPLY`], [`$1B00`], [`FNCMT`], [`$1DFF`],
    [`FNACKS`], [`$1F00`], [`FNTX`], [`$1E00`],
    [`FNSTAT`], [`$1F01`], [`FR_DEV` / `FR_CMD` / `FR_NPAR`], [`$00` / `$01` / `$02`],
    [`FNERR`], [`$1F02`], [`FR_DRST` / `FR_RXSL`], [`$05` / `$06`],
    [`FNRCMD`], [`$1F03`], [`FR_SEQ` / `FR_BLCK`], [`$10` / `$11`],
    [`FNRXLO` / `FNRXHI`], [`$1F04` / `$1F05`], [`FH_BANK`], [`$80`],
    [`FNBST` / `FNBPC` / `FNBER`], [`$1F06`--`$1F08`], [`FH_TROW` / `FH_TCHR` / `FH_TEND`], [`$F0` / `$F1` / `$F2`],
    [`FNMAG0` / `FNMAG1`], [`$1F09` / `$1F0A`], [`FH_PATHC` / `FH_PATHO`], [`$F3` / `$F4`],
    [`FNPVER` / `FNSECH`], [`$1F0B` / `$1F0C`], [`FH_ARM1` / `FH_ARM2`], [`$FC` / `$FD`],
    [`FNBTXG` / `FNBBNK` / `FNBFLG`], [`$1F0D`--`$1F0F`], [`FH_SWAP`], [`$FE`],
    [`FNPLNL` / `FNPLNH`], [`$1F17` / `$1F18`], [`FNAM1` / `FNAM2`], [`$B5` / `$4A`],
  ),
  [The client equates. #src[testrom/fujinet.inc]],
)

= Cartridge schemes

#tbl(
  tab((auto, auto, auto, 1fr),
    th[`.cfg` name], th[Scheme], th[Size], th[Chosen by size alone?],
    [`FLAT`, `2K`, `4K`], [FLAT], [2048, 4096], [yes],
    [`F8`, `F8SC`], [F8 (+ Super Chip)], [8192], [yes, F8; SC by the first-256-bytes heuristic],
    [`F6`, `F6SC`], [F6], [16384], [yes],
    [`F4`, `F4SC`], [F4], [32768], [yes],
    [`FA`], [FA], [12288], [yes],
    [`E0`], [E0], [8192], [no: needs the `.cfg`],
    [`UA`], [UA], [8192], [no: needs the `.cfg`],
    [`FE`], [FE], [8192], [no: needs the `.cfg`],
    [`CV`], [CV], [2048 + 1K RAM], [no: needs the `.cfg`],
  ),
  [Scheme names accepted from a `.cfg` sibling, case-insensitive, with leading blanks and trailing text ignored. The hint is spent on the next image and that one only. Not served: F0, EF, DF, BF, SB (no MAME reference), ACE and ELF (ARM code), DPC and Supercharger (coprocessor or BIOS), 3E and 3F (data sampling below `$1000`). #src[vcsmap.h:14-23, 340-373]],
)

= Rev0 bill of materials, principal parts

#tbl(
  tab((auto, auto, 1fr),
    th[Ref], th[Part], th[Role],
    [U1], [RP2040, QFN-56], [cartridge bus server, `fujivcs`],
    [U2], [W25Q16JVSSIQ], [2 MB QSPI flash for the RP2040],
    [U3, U4, U5], [74LVC245APW], [A0--A7, A8--A12 (fixed A→B) and D0--D7 (DIR on GP26) at 3.3 V],
    [U6], [ESP32-S3-WROOM-1-N16R8], [FujiNet, `fujiversal-atari2600`; USB host for U1],
    [U7], [CP2102N-A02-GQFN28], [USB-C to UART0, S3 flashing and console],
    [U8], [UMH3N], [esptool auto-program, DevKitC-1 style],
    [U9], [AP63203WU], [3.3 V / 2 A buck],
    [L1], [SWPA4030S 6.8 µH], [buck inductor],
    [D1], [BAT54C], [RESET steering: one button resets U1 (RUN) and U6 (EN)],
    [D2], [KT-0603G], [RP2040 activity LED, GP25],
    [D3], [WS2812B-2020-V6], [status LED on IO48; 3.3 V-rated part],
    [D4--D6], [ESD5Z5.0T1G], [ESD on USB D+, D− and VBUS],
    [D7, D8], [SS34], [console +5 V and VBUS OR-ing],
    [J1], [2×12 edge, 2.54 mm], [the cartridge connector (original footprint)],
    [J2], [TF-015], [microSD, push-push, SPI],
    [J3], [TYPE-C-31-M-12], [USB-C],
    [Y1], [ABM8 12 MHz], [RP2040 crystal, 15 pF loads],
    [SW1--SW4], [TL3342], [RESET (both), BOOTSEL (RP), S3 EN, S3 BOOT],
    [RN1], [4×10 k], [SD pull-ups],
  ),
  [Principal parts of Rev0. 78 parts are assembled, all on the component face. Every LCSC code was checked against stock. #src[Fujiversal-Atari2600-Rev0-BOM.csv]],
)

= FujiBus quick reference

#tbl(
  tab((auto, auto, 1fr),
    th[Symbol], th[Byte], th[Meaning],
    [`END`], [`$C0`], [frame delimiter, sent before and after every frame],
    [`ESC`], [`$DB`], [escape prefix],
    [`ESC_END`], [`$DC`], [after `ESC`: a literal `$C0`],
    [`ESC_ESC`], [`$DD`], [after `ESC`: a literal `$DB`],
  ),
  [SLIP framing. #src[FujiBusPacket.h:16-21]],
)

#tbl(
  tab((auto, auto, 1fr),
    th[Offset], th[Field], th[Meaning],
    [0], [`device`], [destination device id],
    [1], [`command`], [command id; in a reply, ACK `$06` or NAK `$15`],
    [2--3], [`length`], [total decoded packet length including the header, little-endian],
    [4], [`checksum`], [8-bit sum with end-around carry over the whole packet with this byte zeroed],
    [5], [`descr`], [first field descriptor; `$00` if there are no parameters],
  ),
  [The six-byte header. `static_assert(sizeof(fujibus_header) == 6)`. #src[FujiBusPacket.cpp:17-26]],
)

#tbl(
  tab((auto, auto, auto),
    th[`descr` & 7], th[Fields], th[Each],
    [0], [0], [---],
    [1--4], [1--4], [1 byte],
    [5], [1], [2 bytes],
    [6], [2], [2 bytes],
    [7], [1], [4 bytes],
  ),
  [Field descriptors. Bit 7 means another descriptor byte follows. Values are written little-endian after all descriptors; whatever remains is the payload. Tables: `numFieldsTable = {0,1,2,3,4,1,2,1}`, `fieldSizeTable = {0,1,1,1,1,2,2,4}`. #src[FujiBusPacket.cpp:28-35]],
)

#tbl(
  tab((auto, auto, 1fr),
    th[Id], th[Symbol], th[Device],
    [`$31`--`$3F`], [DISK], [virtual disk drives],
    [`$40`--`$43`], [PRINTER], [printers],
    [`$45`], [CLOCK], [real-time clock],
    [`$50`--`$53`], [SERIAL], [modem / serial passthrough],
    [`$70`], [FUJINET], [the Fuji control device],
    [`$71`--`$78`], [NETWORK], [N1:--N8:],
    [`$FF`], [DBC], [the bus controller: the RP2040 itself, target of the ROM push],
  ),
  [Device ids. #src[include/fujiDeviceID.h]],
)

= Sources and glossary

#tbl(
  tab((auto, auto, 1fr),
    th[Repository], th[Revision], th[Used for],
    [`fujinet-firmware`], [branch `2600-experiment`, `7432186c0`, 2026-09-27], [`pico/atari-2600/`: `firmware/` (RP2040), `testrom/` (6502 clients and library), `emu/` (MAME device, harnesses), `host_test/`, `tools/`, `README-fujinet.md`; adapter side: `lib/bus/rs232/`, `lib/hardware/ACMChannel.*`, `lib/media/rs232/diskTypeROM.cpp`, `include/pinmap/fujiversal-atari2600.h`, `build-platforms/platformio-fujiversal-atari2600.ini`, `src/main.cpp`, `docs/fujiversal-flashing.md`],
    [`fujinet-hardware`], [branch `atari2600-rev0`, `84a8c09`, 2026-09-27], [`ATARI-2600/Fujiversal-Atari2600/`: README, BOM, KiCad project, `docs/` renders and schematic],
    [`fujinet-config`], [branch `add-atari-2600`, `b4e3805`, 2026-09-13], [`atari-2600/`: CONFIG and its README],
    [`fujinet-battleship`], [`9de5ef6`, 2026-09-16], [`atari2600/`: Battleship and its README],
    [`fujinet-manuals`], [`atari-2600/programmers-handbook`], [the programmer's view; its MAME screens are reused here],
    [MOS Technology], [6500 family datasheet AC characteristics], [t#sub[ADS], t#sub[HA], t#sub[DSU], t#sub[MDS], t#sub[HW] in #ref(<ch-timing>)],
  ),
  [Where every fact in this document comes from. Line numbers in the text refer to these revisions.],
)

#tbl(
  tab((auto, 1fr),
    th[Term], th[Meaning],
    [ACKSEQ], [the sequence number the cartridge last answered; `$1F00`, painted last],
    [arm / commit], [the two stores that make one register write: `$1D00`+n, then the value to `$1DFF`],
    [arming gate], [`$B5` to `$1DFC` then `$4A` to `$1DFD`; nothing on the control page decodes until it has arrived],
    [claim], [the four bytes `FUJI` at `$1F10`; present in a client, absent in a game],
    [DBC], [device `$FF`, the bus controller: the RP2040 as a FujiBus endpoint, target of the ROM push],
    [fixed half], [the last 2K of an image, served at `$1800`--`$1FFF` from every bank, with the mailbox painted over its lower 1.75K],
    [fixed tail], [`$1F20`--`$1FFB`, the 220 bytes of client code every bank reaches at the same address],
    [FujiBus], [the SLIP-framed packet protocol between the cartridge and the adapter, FEP-004],
    [hotspot], [an address whose access has a side effect: a bank switch, or on this cartridge a one-shot operation],
    [mailbox], [the whole console-facing protocol: control page, TX page, reply window, status page, text planes],
    [plane], [one of six 128-byte arrays of composed glyph bytes, one per `GRP` write of the kernel],
    [slice], [one 512-byte half of a reply of up to 1024 bytes],
    [swap], [replacing the served image with the staged one, on a store to `$1DFE` after BOOTLOCK],
    [TX stream], [the parameters and payload of a request, appended one byte per store to page `$1E`],
    [window], [the 4K of the 6507's address space with A12 high, `$1000`--`$1FFF`],
  ),
  [Glossary.],
)
