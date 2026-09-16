#import "../lib.typ": *
#set heading(numbering: "A.1")
#appendix.update(true)
#counter(heading).update(0)
= Mailbox Quick Reference

#sect[The window]

#tbl((auto, 1fr),
  th[Address], th[Region],
  [`$1000`--`$17FF`], [the bank; `$1D80` + b selects],
  [`$1800`, `$1880`, `$1900`, `$1980`, `$1A00`, `$1A80`], [text planes 0--5, 128 bytes each; Y = row × 6 + line],
  [`$1B00`--`$1CFF`], [the reply window, 512 bytes; slice 0 or 1],
  [`$1D00`--`$1D7F`], [arm register n (write-only)],
  [`$1D80`--`$1DFF`], [one-shot operations (write-only)],
  [`$1E00`--`$1EFF`], [the TX stream: any store appends (write-only)],
  [`$1F00`--`$1F1F`], [status cells],
  [`$1F10`], [`FUJI`],
  [`$1F20`--`$1FFB`], [the fixed tail],
  [`$1FFC`, `$1FFE`], [RESET, BRK])

#sect[Status cells]

#tbl((auto, auto, auto, auto),
  th[Cell], th[Name], th[Cell], th[Name],
  [`$1F00`], [ACKSEQ], [`$1F09`--`$1F0A`], [`F`, `N`],
  [`$1F01`], [STATUS: bit 0 link, bit 1 busy], [`$1F0B`], [PROTO_VER = 2],
  [`$1F02`], [ERR], [`$1F0C`], [SLICE_ECHO],
  [`$1F03`], [REPLY_CMD `$06` / `$15`], [`$1F0D`], [TEXTGEN],
  [`$1F04`--`$1F05`], [RXLEN], [`$1F0E`], [BANK],
  [`$1F06`], [BOOT_STATE], [`$1F0F`], [FLAGS: bit 1 claim],
  [`$1F07`], [BOOT_PCT], [`$1F17`--`$1F18`], [PATHLEN],
  [`$1F08`], [BOOT_ERR], [`$1F19`], [BLITGEN])

#sect[Registers and one-shots]

#tbl((auto, 1fr, auto, 1fr),
  th[Reg], th[], th[Store], th[],
  [`$00`], [DEVICE], [`$1D80`+b], [bank b],
  [`$01`], [CMD], [`$1DF0`--`$1DF2`], [text row, char, render],
  [`$02`], [NPARAM], [`$1DF3`--`$1DF4`], [path char, path op],
  [`$05`], [DATA_RST], [`$1DF5`--`$1DFA`], [blit SL SH DL DH CNT GO],
  [`$06`], [RXSLICE], [`$1DFC`--`$1DFD`], [arm `$B5`, `$4A`],
  [`$10`], [SEQ], [`$1DFE`], [swap],
  [`$11`], [BOOTLOCK `$B5`], [`$1DFF`], [commit],
  [`$12`--`$13`], [BOOTSEL `$B5`, `$4A`], [], [])

#sect[Path operations and blits]

Path: 0 reset, 1 pop, 2 emit padded, 3 emit raw, 4 pop char, 5--8 select 0--3, 9 commit, 10 seed. Blits: 0 raw, 1 text, 2 field, 3 hulls, 4 sea, 5 cell, 6 paint, 7 path, 8 tcell, 9 card, 10 pfclr, 11 pfield, 12 pfhull, 13 pfcell.

#sect[The transaction]

DEVICE, CMD, NPARAM, DATA_RST; then NPARAM × (size, value) and the payload into `$1E00`; then SEQ = ACKSEQ + 1 (255 wraps to 1); wait for ACKSEQ; read ERR, REPLY_CMD, RXLEN, the window.

#sect[The library's zero page]

`$80` FNSEQ, `$81` PAD3, `$82` SAVSP, `$83` FNCNT, `$86` FNDEV, `$87` FNCMD, `$88` FNNPR, `$89` FNTMO, `$8A`--`$8B` FNPTRL/H, `$8E` FNPCNT, `$A8`--`$A9` INCUR/INPREV. The swap stub lands at `$80`--`$9D`.
