#import "../lib.typ": *
#set heading(numbering: "A.1")
#appendix.update(true)
#counter(heading).update(0)
= Mailbox Quick Reference

#sect[The map]

#tbl((auto, auto, 1fr),
  th[Address], th[Access], th[What],
  [`$0450`–`$045F`], [write; RANDOM read], [POKEY (APP mode, and games that have one)],
  [`$0600`], [`JMP`], [Loader: load the armed image (or CONFIG) and start it],
  [`$0603`], [`JMP`], [Loader: load CONFIG and start it],
  [`$0800`–`$0BFF`], [read], [Reply window, 1K],
  [`$0C00`–`$0CFB`], [read], [Status page],
  [`$0D00`–`$0D7F`], [write], [Registers: store _V_ at `$0D00`+_n_],
  [`$0D80`–`$0DFF`], [write], [One-shot operations (the loader’s)],
  [`$0F00`–`$0FFF`], [write], [TX stream: each store appends its byte],
  [`$1000`–`$17FF`], [read, write], [High Score Cart RAM, when on],
  [`$3000`–`$3FFF`], [read], [High Score Cart ROM, when on],
  [`$FF70`–`$FF79`], [in the image], [The claim: `"FUJI"`, version 1, kind+1, flags, 0, 0, 0],
)

#sect[Status page]

#tbl((auto, auto, auto, auto),
  th[Address], th[Name], th[Address], th[Name],
  [`$0C00`], [ACKSEQ], [`$0C12`], [MODE],
  [`$0C01`], [STATUS], [`$0C14`], [MAPPER],
  [`$0C02`], [ERR], [`$0C15`], [LINK],
  [`$0C03`], [REPLY_CMD], [`$0C16`–`18`], [BOOT_GOT],
  [`$0C04`–`05`], [RXLEN], [`$0C19`–`1B`], [BOOT_TOT],
  [`$0C06`], [BOOT_STATE], [`$0C1C`], [INPTCTRL],
  [`$0C07`], [BOOT_PCT], [`$0C1D`], [INPT_LOCK],
  [`$0C08`], [BOOT_ERR], [`$0C1E`], [TV],
  [`$0C09`–`0A`], [MAGIC `'F','N'`], [`$0C1F`], [STAGED],
  [`$0C0B`], [PROTO_VER], [`$0C20`], [STAGED_KIND],
  [`$0C0C`], [SLICE_ECHO], [`$0C21`–`24`], [STAGED_CRC],
  [`$0C0D`], [LOAD_STATE], [`$0C25`], [HANDOVER],
  [`$0C0E`], [LOAD_DST], [`$0C26`], [HSC],
  [`$0C0F`–`11`], [LOAD_N, _SEQ, _PCT], [`$0C27`], [DIAG_RMW],
)

#sect[Registers and one-shots]

#tbl((auto, auto, auto, 1fr),
  th[Store to], th[Register], th[Store to], th[Register],
  [`$0D00`], [DEVICE], [`$0D12`, `$0D13`], [BOOTSEL (`$B5`, `$4A`)],
  [`$0D01`], [CMD], [`$0D14`], [SLICE_ACK],
  [`$0D02`], [NPARAM], [`$0D15`], [TV],
  [`$0D05`], [DATA_RST], [`$0D16`], [HSC],
  [`$0D06`], [RXSLICE], [`$0DFB`], [GO_BIOS],
  [`$0D10`], [SEQ], [`$0DFC`], [CONFIG],
  [`$0D11`], [BOOTLOCK (`$B5`)], [`$0DFD`, `$0DFE`], [GO, SWAP],
)

#sect[The transaction]

#nsteps(
  [DEVICE, CMD, NPARAM; DATA_RST.],
  [Parameters into `$0F00`: size (1, 2, 4), then the value, low first. Then the payload. 320 bytes, eight parameters at most.],
  [SEQ = ACKSEQ + 1; 0 becomes 1.],
  [Wait for ACKSEQ = SEQ.],
  [ERR 0? REPLY_CMD `$06`? The reply is at `$0800`, RXLEN bytes.],
)

#sect[The names, in each language]

#tbl((auto, auto, auto, auto),
  th[What], th[Assembly], th[C], th[7800basic],
  [Reply], [`FN_REPLY`], [`FN_REPLY[i]`], [`FN_REPLY[ix]`],
  [ACKSEQ], [`FN_ACKSEQ`], [`FN_ACKSEQ`], [`FN_ACKSEQ`],
  [ERR], [`FN_ERR`], [`FN_ERRCODE`], [`FN_ERR`],
  [REPLY_CMD], [`FN_REPLYCMD`], [`FN_REPLYCMD`], [`FN_REPLYCMD`],
  [A register], [`sta FN_REGSEL+FN_REG_CMD`], [`fn_regwr(FNR_CMD, v)`], [`FN_CMD = v`],
  [TX], [`sta FN_TXDATA`, `fn_txb`], [`fn_tx(b)`], [`FN_TX = b`],
  [Launch and wait], [`fn_go`], [`fn_commit()`], [`gosub fn_go`],
)

#sect[The assembly library’s zero page]

#tbl((auto, auto, auto, auto),
  th[Address], th[Name], th[Address], th[Name],
  [`$E0`], [`FN_SEQ`], [`$E5`], [`FN_TMO`],
  [`$E1`], [`FN_CNT`], [`$E6`–`E7`], [`FN_PTR`],
  [`$E2`–`E4`], [`FN_DEV`, `FN_CMD`, `FN_NPR`], [`$E8`–`EB`], [`DISP_PTR`, `DISP_TMP`],
)
