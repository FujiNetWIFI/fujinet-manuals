#import "../lib.typ": *
#appendix.update(true)
#counter(heading).update(0)
#set heading(numbering: "A")

= Mailbox Quick Reference <apx-a>

#grid(columns: (1fr, 1fr), column-gutter: 0.3in, [
  #set text(size: 9.4pt)
  == Hotspots: a read sends
  #tbl((0.75in, 1fr), size: 9pt,
    [*Read*], [*Sends*],
    [`$2D00`+_n_], [REGSEL: arm register _n_],
    [`$2E00`+_v_], [REGDATA: the armed register = _v_],
    [`$2F00`+_b_], [TX: append _b_],
    [`$2D80`+_n_], [protocol 2: page _n_ in the window],
    [`$2DFE`], [the swap, once armed],
  )
  == Registers
  #tbl((0.5in, 0.85in, 1fr), size: 9pt,
    [*No.*], [*Name*], [*Value*],
    [`$00`], [DEVICE], [`$70` Fuji, `$71-$78` N:, `$45` clock],
    [`$01`], [CMD], [the command],
    [`$02`], [NPARAM], [0--8],
    [`$05`], [DATA_RST], [any],
    [`$06`], [RXSLICE], [0--3],
    [`$10`], [SEQ], [ACKSEQ + 1, never 0],
    [`$11`], [BOOTLOCK], [`$B5`],
    [`$12/$13`], [BOOTSEL], [`$B5`, then `$4A`],
    [`$14-$17`], [RAMPTR], [`0x000-0x300` + _v_],
    [`$18`], [RAMPOKE], [then one REGDATA a byte],
  )
], [
  #set text(size: 9.4pt)
  == Status page
  #tbl((0.6in, 1fr), size: 9pt,
    [*At*], [*Holds*],
    [`$2C00`], [ACKSEQ, painted last],
    [`$2C01`], [bit 0: the link],
    [`$2C02`], [ERR: 0 ok],
    [`$2C03`], [REPLY: `$06` ACK, `$15` NAK],
    [`$2C04`], [RXLEN, low, high],
    [`$2C06`], [BOOT_STATE: 0 1 2 `$80`],
    [`$2C07`], [BOOT_PCT],
    [`$2C08`], [BOOT_ERR],
    [`$2C09`], [`'F'`, `'N'`],
    [`$2C0B`], [version: 2],
    [`$2C0C`], [SLICE_ECHO],
    [`$2C0E`], [tick, low, high],
    [`$2B00`], [the reply, 256 at a time],
    [`$2CFC`], [`FUJI`: the claim],
  )
])

== The recipe

#steps(
  [`FNCHECK`: R0 = 0 on a FujiNet cartridge.],
  [`FNBEGIN dev, cmd, nparam`.],
  [Parameters: `FNPARB` (R2), `FNPARW` (R2, R3). Payload: `FNTXSTR`, `FNPATH`
   (256), `FNTXN` (R2 bytes).],
  [`FNGO`: R0 = 0 on an ACK.],
  [The reply at `$2B00`; `FNSLICE` for the rest.],
)

== The rules

- The next SEQ is ACKSEQ + 1, never a counter of your own.
- Wait as long as the cartridge may: 5 s, 60 for a mount or a copy, 90 for a
  network command. Never relaunch after a timeout of your own.
- Page-0 code reaches the mailbox only through `DWBE` pointer words; block-2
  code reads it directly.
- Never store into the cartridge’s space.
- An image without `FUJI` at `$2CFC` kills the mailbox when it boots.
