#import "../lib.typ": *
#set page(columns: 1)
#refpage.update(true)

#let rows(..r) = tbl((1.45in, 0.6in, 1fr), [*Name*], [*Value*], [*Is*], ..r, size: 7.8pt)

= Command Reference: The Cartridge Itself <ref-cart>

#hang([], [Everything the cartridge answers by itself, with the names its firmware gives them: `pico/studio2/firmware/include/fuji_mailbox.h`, `s2_text.h` and the shared `pico/common/include/fuji_mailbox_proto.h`, at the revision in the Parts List. `tools/cartcheck.py` checks that every one of those names is on this page. The runtime’s own names, from `fujinet.inc`, are given beside them where they differ.])

#sect[The arena]

#hang([Pages `$E4`–`$EF`, served whenever the running image claims the mailbox.], rows(
  [`FN_R_DATA`], [`$E400`], [the reply window: the reply, `FN_R_SLICE_LEN` (`$400`) bytes; runtime `FN_REPLY`],
  [`FN_R_NSLICES`], [1], [slices of the reply: one, so the whole reply is always in the window],
  [`FN_R_BASE`], [`$E800`], [the status page, painted from here to `FN_R_PAINT_END` (`$E8FC`); runtime `FN_STATUS`],
  [REGSEL], [`$E9`_nn_], [select register nn (`$00`–`$7F`); runtime `FN_REGSEL`],
  [REGDATA], [`$EA`_vv_], [the selected register = vv; runtime `FN_REGDATA`],
  [TX], [`$EB`_bb_], [append bb to the TX stream, at most `FN_TX_MAX`, 320; runtime `FN_TXDATA`],
  [stub], [`$E9F0`], [`$EC $70 $23`: SEX RC; RET; and RET’s byte. The hand-over’s last step; runtime `FN_STUB`],
  [text], [`$EC`–`$EF`], [the text engine’s four pages, below],
))

#sect[The registers]

#hang([Set by a read of REGSEL, then one of REGDATA. A register is good for one write; a REGDATA read with no REGSEL before it does nothing.], rows(
  [`FN_REG_DEVICE`], [`$00`], [the FujiBus device],
  [`FN_REG_CMD`], [`$01`], [the command],
  [`FN_REG_NPARAM`], [`$02`], [how many parameters lead the TX stream; the cartridge takes 8 at most],
  [`FN_REG_DATA_RST`], [`$05`], [any value: the TX stream starts over],
  [`FN_REG_RXSLICE`], [`$06`], [which slice of the reply the window shows: always 0 here],
  [`FN_REG_SEQ`], [`$10`], [not 0 and not ACKSEQ: launch. ACKSEQ again: nothing],
  [`FN_REG_BOOTLOCK`], [`$11`], [`FN_BOOTLOCK_MAGIC` (`$B5`): arm the staged image, if BOOT_STATE is READY],
  [`FN_REG_BOOTSEL_1`], [`$12`], [`FN_BOOTSEL_MAGIC1` (`$B5`), then...],
  [`FN_REG_BOOTSEL_2`], [`$13`], [...`FN_BOOTSEL_MAGIC2` (`$4A`) at once: the RP2354B restarts into its USB loader, for new firmware],
  [`FN_REG_CONFIG`], [`$14`], [`FN_CONFIG_MAGIC` (`$C5`): stage the built-in CONFIG and arm it. The Studio II’s own],
))

#sect[The status page]

#hang([Painted with every reply; ACKSEQ last. Offsets in the firmware count from the start of the arena, so `FN_R_ACKSEQ` is `$400` there and `$E800` to the console.], rows(
  [`FN_R_ACKSEQ`], [`$E800`], [the sequence number answered; runtime `FN_ACKSEQ`],
  [`FN_R_STATUS`], [`$E801`], [bit 0, `FN_R_STATUS_LINK`: the ESP32-S3 link is up. Bit 1, `FN_R_STATUS_BUSY`, is never set on this cartridge; runtime `FN_STAT`],
  [`FN_R_ERR`], [`$E802`], [the transaction’s error, below; runtime `FN_ERR`],
  [`FN_R_REPLY_CMD`], [`$E803`], [`$06` ACK or `$15` NAK; runtime `FN_REPLYCMD`],
  [`FN_R_RXLEN_LO`, `FN_R_RXLEN_HI`], [`$E804`], [the reply’s length, at most 1024; runtime `FN_RXLEN`],
  [`FN_R_BOOT_STATE`], [`$E806`], [a staged image: below],
  [`FN_R_BOOT_PCT`], [`$E807`], [how much of it has come: 0–100],
  [`FN_R_BOOT_ERR`], [`$E808`], [why it failed: below],
  [`FN_R_MAGIC0`, `FN_R_MAGIC1`], [`$E809`], [`'F'`, `'N'`: a FujiNet cartridge],
  [`FN_R_PROTO_VER`], [`$E80B`], [the mailbox’s version: 1],
  [`FN_R_SLICE_ECHO`], [`$E80C`], [the slice the window shows],
  [`FN_R_MODE`], [`$E812`], [what is being served: 0 the image from power-on (CONFIG), 2 a game, 3 a FujiNet program],
  [`FN_R_LINK`], [`$E815`], [1 while the ESP32-S3’s link is up. Not latched, whatever its comment says: it can fall back to 0],
  [`FN_R_BOOT_GOT0`], [`$E816`], [image bytes received, three bytes, low first],
  [`FN_R_BOOT_TOT0`], [`$E819`], [the image’s size as the FujiNet declared it, three bytes],
  [`FN_R_ARMED`], [`$E81C`], [1 once the swap is armed],
  [`FN_R_STAGED`], [`$E81D`], [the staged image: bit 0 ready, bit 1 it claims the mailbox, bit 2 it is CONFIG],
  [`FN_R_STAGED_CRC`], [`$E81F`], [its CRC-32, four bytes, low first],
  [`FN_R_SWAPS`], [`$E823`], [hand-overs since power-on, modulo 256],
  [`FN_R_FRAMES`], [`$E824`], [picture frames served, modulo 256],
  [`FN_R_PAINT_END`], [`$E8FC`], [where the painted page ends],
))

#sect[Codes]

#hang([ERR, BOOT_STATE and BOOT_ERR. Error and Status Codes, in Appendix B, has the runtime’s codes beside them.], rows(
  [`FN_ERR_OK`], [0], [the transaction went through],
  [`FN_ERR_NOLINK`], [1], [the ESP32-S3 is not there],
  [`FN_ERR_TIMEOUT`], [2], [no reply in time: 5 s, 60 s for a mount or copy, 90 s on a network channel],
  [`FN_ERR_BADFRAME`], [3], [a parameter size other than 1, 2 or 4, or a reply frame that fails its checks],
  [`FN_ERR_TOOBIG`], [4], [the request or its reply would not fit the cartridge’s buffers],
  [`FN_BOOT_IDLE`], [0], [nothing staged],
  [`FN_BOOT_XFER`], [1], [an image is coming],
  [`FN_BOOT_READY`], [2], [staged, ready to arm],
  [`FN_BOOT_FAILED`], [`$80`], [it failed: BOOT_ERR says why],
  [`FN_BOOT_ERR_TOOBIG`], [1], [larger than an ST2 can be, 16,640 bytes],
  [`FN_BOOT_ERR_TRUNCATED`], [2], [shorter than the FujiNet said it would be],
  [`FN_BOOT_ERR_NOMAP`], [3], [it names a page it may not use],
  [`FN_BOOT_ERR_STOREBUSY`], [4], [never on this cartridge],
))

#sect[The claim]

#hang([], rows(
  [`FN_R_CLAIM_SIG`], [`"FUJI"`], [at `$07FC`, `FN_R_CLAIM_LEN` (4) bytes: the image claims the mailbox; runtime `FN_CLAIM`, the `S2CLAIM` macro],
))

#sect[The text engine]

#hang([Pages `$EC` (cursor), `$ED` (PUTC), `$EE` (operation) and `$EF` (parameter): `S2T_H_CURSOR` to `S2T_H_PARAM`, the runtime’s `TX_CURSOR` to `TX_PARAM`. 16 columns, 10 rows, 16 parameters at most.], rows(
  [`S2T_OP_CLS`], [`$00`], [clear rows 0–9, cursor home, inverse off, marquee off],
  [`S2T_OP_INV_ON`], [`$01`], [inverse video on],
  [`S2T_OP_INV_OFF`], [`$02`], [inverse video off],
  [`S2T_OP_CLREOL`], [`$03`], [blank from the cursor to the end of the row],
  [`S2T_OP_SCROLL`], [`$04`], [rows 1–9 up one, row 9 blank; the cursor stays],
  [`S2T_OP_PRINT`], [`$10`], [offset low, offset high, the most (0: 256): reply text to a NUL],
  [`S2T_OP_PRINT_PAD`], [`$11`], [the same, then spaces to the most],
  [`S2T_OP_MARQUEE`], [`$20`], [the cursor’s row scrolls a PRINT too long for it: 250 ms a step, 64 characters],
  [`S2T_OP_MQ_OFF`], [`$21`], [the marquee off],
  [`S2T_OP_REPEAT`], [`$30`], [a character, a count],
  [`S2T_OP_GLYPH`], [`$40`], [a code `$80`–`$9F`, then 12 rows, bit 3 the left dot],
  [`S2T_OP_TILE`], [`$41`], [a tile 0–15, then 4 rows, bit 1 the left dot],
  [`S2T_OP_MOSAIC`], [`$42`], [three bytes a cell, up to five cells, at the cursor; the cell reads `$A0`],
  [`S2T_SYM_SPADE`], [`$01`], [#s2ch(1)],
  [`S2T_SYM_HEART`], [`$02`], [#s2ch(2)],
  [`S2T_SYM_DIAMOND`], [`$03`], [#s2ch(3)],
  [`S2T_SYM_CLUB`], [`$04`], [#s2ch(4)],
  [`S2T_SYM_BLOCK`], [`$05`], [#s2ch(5)],
  [`S2T_SYM_RIGHT`], [`$06`], [#s2ch(6)],
  [`S2T_SYM_LEFT`], [`$07`], [#s2ch(7)],
  [`S2T_SYM_UP`], [`$08`], [#s2ch(8)],
  [`S2T_SYM_DOWN`], [`$09`], [#s2ch(9)],
  [`S2T_SYM_TEN`], [`$0A`], [#s2ch(10), “10” in one cell],
  [`S2T_SYM_BACK`], [`$0B`], [#s2ch(11), a card’s back],
))

#sect[The image push]

#hang([], [MOUNT_IMAGE makes the FujiNet send the file to the cartridge on the same USB link, as three kinds of frame to a device of the cartridge’s own, `$FF`: an OPEN with the file’s size, WRITEs of the bytes, and a CLOSE. The cartridge answers each, refuses the OPEN of an image too large, and checks the pages when the CLOSE arrives. BOOT_STATE and the progress bar follow it. A program never sends these frames; it only watches the status page.])

#sect[Reset and power]

#hang([], [CLEAR resets the 1802 and the 1861, not the cartridge: the image and ACKSEQ survive, and a swap that is armed is taken on the BIOS’s first fetch. A read of `$0000` after 50 µs with no reads at all counts as a restart too. Power off, for longer than 10 ms, resets the cartridge’s bus engine: it lets go of the bus and serves CONFIG at the next power-on.])

#refpage.update(false)
