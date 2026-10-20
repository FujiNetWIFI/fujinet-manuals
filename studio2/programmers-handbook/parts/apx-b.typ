#import "../lib.typ": *
#set page(columns: 1)
#refpage.update(true)
#set heading(numbering: "A")

= Error and Status Codes <apx-b>

#hang([What `fn_go`, `fn_ack` and the runtime return in D, and what the cartridge paints.], tbl((1.25in, 0.5in, 1fr), [*Name*], [*Value*], [*Means*],
  [`FNEOK`], [`$00`], [the transaction went through (FN_ERR_OK)],
  [`FN_ERR_NOLINK`], [`$01`], [no link to the ESP32-S3],
  [`FN_ERR_TIMEOUT`], [`$02`], [the FujiNet did not answer in time],
  [`FN_ERR_BADFRAME`], [`$03`], [a parameter size other than 1, 2 or 4; a reply that failed its checks],
  [`FN_ERR_TOOBIG`], [`$04`], [the request or the reply would not fit],
  [`FNENAK`], [`$EE`], [`fn_ack`: the FujiNet said NAK],
  [`FNENARM`], [`$FC`], [`fn_boot` / `fn_config`: the swap was never armed],
  [`FNENOC`], [`$FD`], [no FujiNet cartridge: the magic is missing],
  [`FNEWAIT`], [`$FF`], [`fn_go` gave up before the cartridge answered],
  [ACK], [`$06`], [REPLYCMD: the FujiNet agreed],
  [NAK], [`$15`], [REPLYCMD: the FujiNet refused],
  [BOOT_STATE 0], [`$00`], [nothing staged],
  [BOOT_STATE 1], [`$01`], [an image is coming],
  [BOOT_STATE 2], [`$02`], [staged and ready to arm],
  [BOOT_STATE `$80`], [`$80`], [failed: see BOOT_ERR],
  [BOOT_ERR 1], [`$01`], [larger than an ST2 can be],
  [BOOT_ERR 2], [`$02`], [shorter than declared],
  [BOOT_ERR 3], [`$03`], [it names a page a program may not use],
  [MODE 0], [`$00`], [serving the image from power-on: CONFIG],
  [MODE 2], [`$02`], [serving a game, the mailbox off],
  [MODE 3], [`$03`], [serving a FujiNet program],
  [NET STATUS 1], [`1`], [network channel status byte: all is well],
  [NET STATUS 136], [`$88`], [the end of the file],
))

#refpage.update(false)
