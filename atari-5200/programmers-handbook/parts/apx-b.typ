#import "../lib.typ": *
#set heading(numbering: "A.1")
= Error and Status Codes

#sect[ERR, at `$B402`]

#tbl((auto, 1fr),
  th[Value], th[Meaning],
  [0], [None.],
  [1], [No link to the FujiNet.],
  [2], [The FujiNet did not answer within the cartridge’s budget.],
  [3], [A bad frame: a parameter whose size is not 1, 2 or 4.],
  [4], [Too big.],
)

#sect[REPLYCMD, at `$B403`]

#tbl((auto, 1fr),
  th[Value], th[Meaning],
  [`$06`], [ACK: the FujiNet did it.],
  [`$15`], [NAK: the FujiNet refused.],
  [0], [The transaction never reached the FujiNet (see ERR).],
)

#sect[BOOTSTATE and BOOTERR, at `$B406` and `$B408`]

#tbl((auto, auto, 1fr),
  th[Field], th[Value], th[Meaning],
  [BOOTSTATE], [0], [Idle.],
  [], [1], [An image is arriving.],
  [], [2], [Ready: arm it with BOOTLOCK.],
  [], [`$80`], [Failed: see BOOTERR.],
  [BOOTERR], [1], [Bigger than 128K.],
  [], [2], [Shorter than its declared size.],
  [], [3], [No board fits it.],
  [], [4], [The only room that fits it is in use.],
)

#sect[MODE, at `$B412`]

#tbl((auto, 1fr),
  th[Value], th[Meaning],
  [0], [BOOT: CONFIG, at power-on.],
  [2], [GAME: an image without the claim; no mailbox.],
  [3], [APP: an image with the claim.],
)

#sect[The assembly library’s own]

#tbl((auto, auto, 1fr),
  th[Value], th[Name], th[Meaning],
  [0], [`FNEOK`], [Success.],
  [`$EE`], [`FNENAK`], [The FujiNet said no.],
  [`$FC`], [`FNENARM`], [The swap was never armed.],
  [`$FD`], [`FNENOC`], [No cartridge: `'F','N'` missing.],
  [`$FF`], [`FNEWAIT`], [The cartridge never answered.],
)

#sect[fujinet-lib’s]

#tbl((auto, auto, 1fr),
  th[Value], th[Name], th[Meaning],
  [0–4], [`FN_OK` … `FN_ETOOBIG`], [The cartridge’s ERR, in `fn_device_error`.],
  [`$FF`], [`FN_EWAIT`], [The cartridge never answered.],
  [144], [], [The FujiNet said no, in `fn_device_error`.],
)
