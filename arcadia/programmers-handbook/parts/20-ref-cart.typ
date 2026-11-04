#import "../lib.typ": *

= Command Reference: The Cartridge Itself <ref-cart>

Everything the game chip does on its own account, by the names in the
firmware’s `pico/arcadia/firmware/include/fuji_mailbox.h` and the shared
`pico/common/include/fuji_mailbox_proto.h`, which every FujiNet cartridge
uses. `fujilib.inc` mirrors them by hand under shorter names, given in the
last column; `tools/defcheck.py` and `tools/cartcheck.py` hold this section
and the library to the headers.

== The image

#tbl((1.45in, 0.85in, 1fr, 0.75in),
  [*Name*], [*Value*], [*Is*], [*fujilib*],
  [`FN_WINDOW_SIZE`], [`0x2000`], [the image, 8,192 bytes: block 1 at `$0000`, block 2 at `$2000`], [],
  [`FN_ROM_TOP`], [`0x1B00`], [the client’s code and data end below this: 6,912 bytes], [],
  [`FN_R_CLAIM`], [`0x1CFC`], [`FUJI` here keeps the mailbox alive after a boot (`$2CFC`)], [],
  [`FN_R_CLAIM_SIG`], [`"FUJI"`], [the claim; `FN_R_CLAIM_LEN` is 4], [],
)

An image without the claim kills hotspot decode for the session: from then
on, the mailbox’s pages are plain ROM. `checkrom.py` also wants `$1F` (a
`BCTA,UN`) at `0x0000`, `$17` (`RETC,UN`) at `0x0003`, and zeros in
`0x1B00-0x1FFF` but for the claim.

== Hotspots: console to cartridge

#tbl((1.45in, 0.75in, 1fr, 0.75in),
  [*Name*], [*Console*], [*A read of it, plus _n_*], [*fujilib*],
  [`FN_H_REGSEL`], [`$2D00`], [_n_ under `$80`: arm register _n_], [`FNRSEL`],
  [`FN_H_REGDATA`], [`$2E00`], [the armed register = _n_, and disarm], [`FNRDAT`],
  [`FN_H_DATA`], [`$2F00`], [append _n_ to the TX stream], [`FNDATA`],
  [`FN_HOT_SWAP`], [`$2DFE`], [serve the staged image; only once armed], [`FNSWAP`],
  [`FN_HOT_BANK`], [`$2D80`], [_n_ under 32: the window shows page _n_ (to `FN_HOT_BANK_LAST`, `$2D9F`)], [`FNBANK`],
)

`FN_H_PAGE_MASK` (`0x1F00`) is how the decode tells the REGSEL page from the
others. REGSEL offsets `$80-$FF` are one-shot operations, not registers: the
swap and the bank selects.

*The gates against stray reads.* A REGDATA with no REGSEL just before it
does nothing (but `$2D80`+_n_ always selects); a transaction launches only
on a SEQ that is not 0 and not the last one answered; the swap fires only
after BOOTLOCK; an image without the claim kills the mailbox; and a hotspot
acts once for each stable state of the address lines, so the game chip
counts a read once however long the 2650 holds it.

== Registers

#tbl((1.45in, 0.45in, 1fr, 0.75in),
  [*Name*], [*No.*], [*A value written*], [*fujilib*],
  [`FN_REG_DEVICE`], [`$00`], [the FujiBus device], [`FRDEVIC`],
  [`FN_REG_CMD`], [`$01`], [the command], [`FRCMD`],
  [`FN_REG_NPARAM`], [`$02`], [the number of parameters, at most 8], [`FRNPARM`],
  [`FN_REG_DATA_RST`], [`$05`], [any value: rewind the TX stream], [`FRDATRS`],
  [`FN_REG_RXSLICE`], [`$06`], [the reply slice the window shows, 0--3], [`FRRXSLC`],
  [`FN_REG_SEQ`], [`$10`], [not 0 and not ACKSEQ: launch], [`FRSEQ`],
  [`FN_REG_BOOTLOCK`], [`$11`], [`FN_BOOTLOCK_MAGIC` (`$B5`): arm the staged image], [`FRBOOTL`],
  [`FN_REG_BOOTSEL_1`], [`$12`], [`FN_BOOTSEL_MAGIC1` (`$B5`), then...], [`FRBSEL1`],
  [`FN_REG_BOOTSEL_2`], [`$13`], [...`FN_BOOTSEL_MAGIC2` (`$4A`): restart the game chip into its USB loader, for new firmware], [`FRBSEL2`],
  [`FN_REG_PLATFORM`], [`$14`], [the first register a cartridge may define for itself], [],
  [`FN_REG_RAMPTR0`], [`$14`], [protocol 2: the cartridge RAM pointer = `0x000` + value; `$15`, `$16` and `FN_REG_RAMPTR3` (`$17`) for `0x100`, `0x200`, `0x300`], [`FRRAMP0`],
  [`FN_REG_RAMPOKE`], [`$18`], [protocol 2: each REGDATA after it stores and advances], [`FRRAMPK`],
)

BOOTSEL takes two register writes, each with its own magic, so that no single
stray read can trigger it.

== The TX stream

#tbl((1.45in, 0.85in, 1fr),
  [*Name*], [*Value*], [*Is*],
  [`FN_TX_MAX`], [320], [the stream’s length: NPARAM × (size, value, low first), then the payload],
  [`FN_STREAM_ROM`], [0], [the DBC push of the image itself],
  [`FN_STREAM_CFG`], [1], [the push of a `.cfg` sibling, whose `mapper=` line chooses a mapper on carts that have them; the Arcadia has none],
)

== The status page: cartridge to console

#tbl((1.45in, 0.6in, 1fr, 0.75in),
  [*Name*], [*Console*], [*Holds*], [*fujilib*],
  [`FN_R_DATA`], [`$2B00`], [the reply, `FN_R_SLICE_LEN` (256) bytes of it; `FN_R_NSLICES` (4) slices], [`FNRDATA`],
  [`FN_R_BASE`], [`$2C00`], [the first painted status byte], [],
  [`FN_R_ACKSEQ`], [`$2C00`], [the SEQ answered: painted last], [`FNACKSQ`],
  [`FN_R_STATUS`], [`$2C01`], [bit 0 `FN_R_STATUS_LINK`, the USB link is up; bit 1 `FN_R_STATUS_BUSY`], [`FNSTATS`],
  [`FN_R_ERR`], [`$2C02`], [the transaction’s result (Appendix B)], [`FNERR`],
  [`FN_R_REPLY_CMD`], [`$2C03`], [`$06` ACK or `$15` NAK], [`FNREPLY`],
  [`FN_R_RXLEN_LO`], [`$2C04`], [the reply’s length, with `FN_R_RXLEN_HI` (`$2C05`)], [`FNRXLL`],
  [`FN_R_BOOT_STATE`], [`$2C06`], [the staged image (below)], [`FNBSTAT`],
  [`FN_R_BOOT_PCT`], [`$2C07`], [0--100, for a progress bar], [`FNBPCT`],
  [`FN_R_BOOT_ERR`], [`$2C08`], [why staging failed], [`FNBERR`],
  [`FN_R_MAGIC0`], [`$2C09`], [`'F'`, then `FN_R_MAGIC1` (`$2C0A`) `'N'`], [`FNMAGF`],
  [`FN_R_PROTO_VER`], [`$2C0B`], [`FN_PROTO_VER`: 2], [`FNPVER`],
  [`FN_R_SLICE_ECHO`], [`$2C0C`], [the slice the window shows, painted after it], [`FNSECHO`],
  [--], [`$2C0D`], [reserved: reads 0], [],
  [`FN_R_TICK_LO`], [`$2C0E`], [a 60 Hz count, with `FN_R_TICK_HI` (`$2C0F`)], [`FNTIKL`],
  [`FN_R_PAINT_END`], [`$2CFC`], [the painted page ends here, at the claim], [],
)

== Boot states and errors

#tbl((1.45in, 0.5in, 1fr, 0.75in),
  [*Name*], [*Value*], [*Means*], [*fujilib*],
  [`FN_BOOT_IDLE`], [0], [nothing staged], [`FBIDLE`],
  [`FN_BOOT_XFER`], [1], [an image is coming], [`FBXFER`],
  [`FN_BOOT_READY`], [2], [staged and checked: BOOTLOCK may arm it], [`FBREADY`],
  [`FN_BOOT_FAILED`], [`$80`], [staging failed: see BOOT_ERR], [`FBFAIL`],
  [`FN_BOOT_ERR_TOOBIG`], [1], [larger than the cartridge can hold (71,680)], [],
  [`FN_BOOT_ERR_TRUNCATED`], [2], [fewer bytes came than were promised], [],
  [`FN_BOOT_ERR_NOMAP`], [3], [over 8K but not 8K + _k_ × 2K, or with no claim], [],
  [`FN_BOOT_ERR_STOREBUSY`], [4], [the only store it would fit is being served from], [],
)

The game chip keeps two image stores. A push always lands in the one it is
not serving, and staging an image with the claim copies the live status page
and reply into it, so the program it boots finds `F`, `N`, the version and
ACKSEQ in place.

== Protocol 2

#tbl((1.45in, 0.85in, 1fr),
  [*Name*], [*Value*], [*Is*],
  [`FN_APP_WIN`], [`0x0800`], [the window, console `$0800-$0FFF`],
  [`FN_APP_PAGE`], [`0x0800`], [a page: 2,048 bytes],
  [`FN_APP_NPAGES`], [32], [page 0, in the base, and up to 31 more],
  [`FN_APP_MAX`], [`0x11800`], [the largest image: 71,680 bytes],
  [`FN_RAM_L`], [`0x0600`], [cartridge RAM, the low half, at console `$0600`],
  [`FN_RAM_H`], [`0x1900`], [the high half, at console `$2900`],
  [`FN_RAM_HALF`], [`0x0200`], [each half, 512 bytes; `FN_RAM_SIZE` `0x0400` in all],
)

Page _n_ is image `0x2000` + (_n_ -- 1) × `0x800`; a page that is not there
reads `$FF`; the swap maps page 0; a console RESET changes neither the page
nor the RAM. Section 15 has the whole of it.

== Timeouts

#tbl((2.4in, 0.75in, 1fr),
  [*Transaction*], [*Allowed*], [*Notes*],
  [MOUNT_IMAGE, COPY_FILE], [60 s], [],
  [a network channel’s OPEN, STATUS, READ, CLOSE], [90 s], [],
  [everything else], [5 s], [after waiting up to 3 s for the USB link, if it is down],
)

When one runs out, ERR is 2 (`FN_ERR_TIMEOUT`) and ACKSEQ is painted as for
any other answer.

== On the board

The game chip serves the bus from its second core: it watches A0--A13 and
answers combinationally, without the read strobe the connector does not
have, and counts a hotspot once per change of the full address, after two
samples 100 ns apart agree. The network chip is on the far side of a USB
link inside the cartridge, speaking FujiBus; the cartridge’s own RESET
restarts both. The pin map and the power path belong to the hardware
repository’s Rev0 design, which the Parts List names.
