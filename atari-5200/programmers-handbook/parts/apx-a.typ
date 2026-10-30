#import "../lib.typ": *
#set heading(numbering: "A.1")
#appendix.update(true)
#counter(heading).update(0)
= Mailbox Quick Reference

#sect[The map]

#tbl((auto, auto, 1fr),
  th[Address], th[Access], th[What],
  [`$B000`–`$B3FF`], [read], [Reply window, 1K],
  [`$B400`–`$B4FB`], [read], [Status page],
  [`$B500`+_n_], [read], [Select register _n_ (_n_ < `$80`)],
  [`$B5F0`–`$B5F2`], [`JMP`], [The stub: `JMP ($FFFC)`, swaps the armed image in],
  [`$B600`+_v_], [read], [Set the selected register to _v_],
  [`$B700`+_b_], [read], [TX stream: append the byte _b_],
  [`$BFC0`–`$BFFF`], [read], [Super Cart bank switch],
  [`$BFE0`–`$BFE6`], [—], [The claim: `"FUJI"`, version, kind + 1, flags],
)

#sect[A transaction]

#nsteps(
  [DEVICE, CMD, NPARAM; DATA_RST.],
  [Parameters (size, value, low first), then the payload.],
  [SEQ = `ACKSEQ` + 1 (255 wraps to 1).],
  [Wait for `ACKSEQ` = SEQ.],
  [`ERR` = 0, `REPLYCMD` = `$06`.],
  [Read `RXLEN` bytes from `$B000`.],
)

#sect[Registers]

#tbl((auto, auto, 1fr),
  th[Register], th[Read], th[Meaning],
  [`$00`], [`$B500`], [DEVICE],
  [`$01`], [`$B501`], [CMD],
  [`$02`], [`$B502`], [NPARAM, at most 8],
  [`$05`], [`$B505`], [DATA_RST: any value],
  [`$06`], [`$B506`], [RXSLICE: 0],
  [`$10`], [`$B510`], [SEQ: launch],
  [`$11`], [`$B511`], [BOOTLOCK: `$B5` arms the pushed image],
  [`$12`, `$13`], [`$B512`, `$B513`], [BOOTSEL: `$B5` then `$4A`],
  [`$14`], [`$B514`], [CONFIG: `$C5` arms CONFIG],
)

#sect[Rules]

- Hotspot pages: `LDA`/`LDX`/`LDY`/`BIT`, absolute or absolute-indexed, from a page-aligned base.
- No store, no read-modify-write, no `(zp),Y` in `$4000`–`$BFFF`; no `JMP ($xxFF)`.
- Never the same hotspot on two cycles in a row.
- No display list, screen or font in `$B000`–`$B7FF`.
- The claim at `$BFE0`, `$02` at `$BFE7`, `$FF` at `$BFFD`, the start at `$BFFE`.

#sect[Budgets]

#tbl((auto, auto),
  th[Seconds], th[For],
  [5], [Most commands],
  [60], [MOUNT_IMAGE, COPY_FILE],
  [90], [Network OPEN, CLOSE, STATUS, READ],
)
