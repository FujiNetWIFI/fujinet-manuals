#import "../lib.typ": *

= Quick Reference

== A transaction

#steps(
  [`$5505` ← anything: rewind the TX stream.],
  [`$5500` ← device, `$5501` ← command, `$5502` ← number of parameters.],
  [`$5700` ← for each parameter, its size (1, 2 or 4) and its bytes, low first;
   then the payload. At most 320 bytes.],
  [`$5510` ← ACKSEQ + 1, skipping 0.],
  [Wait until `$5400` reads the same.],
  [`$5402` = 0 and `$5403` = `$06`? The reply is `$5404-$5405` bytes at
   `$5000`.],
)

STA, STX and STY only. Never INC, DEC or a shift on `$5500-$57FF`. Claim the
mailbox with `FUJI` at `$FFF0`.

== Devices

#tbl((auto, 1fr, auto, 1fr),
  th[Device], th[What], th[Device], th[What],
  [`$70`], [The Fuji device (Chapter 7)], [`$45`], [The clock (Chapter 9)],
  [`$71-$78`], [Network N1:-N8: (Chapter 6)], [`$40`], [The printer],
  [`$31-$38`], [Disks: the device slots], [`$50`], [The modem: no reply reaches the NES],
)

== Network commands

#tbl((auto, auto, 1fr, auto, auto, 1fr),
  th[Cmd], th[Name], th[Params], th[Cmd], th[Name], th[Params],
  [`$4F`], [OPEN], [mode, trans + URL], [`$54`], [TRANSLATION], [x, trans],
  [`$43`], [CLOSE], [], [`$4C`], [SET_EOL], [+ bytes],
  [`$53`], [STATUS], [→ 4 bytes], [`$4D`], [HTTP MODE], [x, mode],
  [`$52`], [READ], [count(2)], [`$25`/`$26`], [SEEK/TELL], [offset(4) / →4],
  [`$57`], [WRITE], [count(2) + bytes], [`$2C`/`$30`], [CHDIR/GETCWD], [+ path / →text],
  [`$FC`], [SET_PARSER], [x, parser], [`$FD`/`$FE`], [USER/PASS], [+ text],
  [`$50`], [PARSE], [], [`$20-$2B`], [file ops], [mode, x + URL],
  [`$51`], [QUERY], [+ path], [`$41`/`$63`], [ACCEPT/CLOSE CLIENT], [],
  [`$FB`], [SET_PARAMETER], [which, value], [`$44`/`$72`], [UDP DEST/REMOTE], [+ host:port],
)

== Fuji commands

#tbl((auto, 1fr, auto, 1fr, auto, 1fr), size: 7.4pt,
  th[Cmd], th[Name], th[Cmd], th[Name], th[Cmd], th[Name],
  [`$FF`], [RESET (no reply)], [`$E8`], [GET_ADAPTERCONFIG], [`$D3`], [RANDOM_NUMBER],
  [`$FE`], [GET_SSID], [`$E7`], [NEW_DISK], [`$D0-$CD`], [BASE64 ENCODE],
  [`$FD`], [SCAN_NETWORKS], [`$E6`], [UNMOUNT_HOST], [`$CC-$C9`], [BASE64 DECODE],
  [`$FC`], [GET_SCAN_RESULT], [`$E5`/`$E4`], [GET/SET DIR POSITION], [`$C8-$C2`], [HASH],
  [`$FB`], [SET_SSID], [`$E2`], [SET_DEVICE_FULLPATH], [`$C4`], [GET_ADAPTERCONFIG_EXT],
  [`$FA`], [GET_WIFISTATUS], [`$E1`/`$E0`], [SET/GET HOST PREFIX], [`$BC-$BF`], [QR CODE],
  [`$F9`], [MOUNT_HOST], [`$DE`], [WRITE_APPKEY], [`$BB`], [GENERATE_GUID],
  [`$F8`], [MOUNT_IMAGE], [`$DD`], [READ_APPKEY], [`$53`], [STATUS],
  [`$F7`], [OPEN_DIRECTORY], [`$DC`], [OPEN_APPKEY], [`$00`], [DEVICE_READY],
  [`$F6`], [READ_DIR_ENTRY], [`$DB`], [CLOSE_APPKEY], [], [],
  [`$F5`], [CLOSE_DIRECTORY], [`$DA`], [GET_DEVICE_FULLPATH], [], [],
  [`$F4`/`$F3`], [READ/WRITE HOST SLOTS], [`$D9`], [CONFIG_BOOT], [], [],
  [`$F2`/`$F1`], [READ/WRITE DEVICE SLOTS], [`$D8`], [COPY_FILE], [], [],
  [`$EA`], [GET_WIFI_ENABLED], [`$D7`], [MOUNT_ALL], [], [],
  [`$E9`], [UNMOUNT_IMAGE], [`$D6`], [SET_BOOT_MODE], [], [],
)

== Clock commands

#tbl((auto, 1fr, auto, 1fr),
  th[Cmd], th[Reply], th[Cmd], th[Reply],
  [`$49` I], [ISO 8601, FujiNet's zone (25)], [`$50` P], [ProDOS (4)],
  [`$5A` Z], [ISO 8601, UTC (25)], [`$53` S], [SOS (19)],
  [`$93`], [D M Y H M S (6)], [`$47` G], [the zone],
  [`$9A`], [the same, alternate zone (6)], [`$4C` L], [the zone's length + 1],
  [`$54` T], [century Y M D h m s (7)], [`$74` t], [set the zone (saved)],
  [`$4D` M], [the same + hundredths (8)], [`$99`], [set the alternate zone],
)

== Sizes

#tbl((1fr, auto, 1fr, auto),
  th[What], th[Bytes], th[What], th[Bytes],
  [TX stream, everything], [320], [Reply window], [1024],
  [One network WRITE], [317], [One network READ], [1024],
  [Host slot name], [32], [Device slot], [38],
  [All host slots], [256], [All device slots], [304],
  [Path, OPEN_DIRECTORY, SET_DEVICE_FULLPATH], [256], [NetConfig (SSID + password)], [97],
  [App key], [64], [App key open record], [6],
  [AdapterConfig], [140], [AdapterConfigExtended], [240],
)

== Programs in this manual

#tbl((auto, 1fr, auto),
  th[Program], th[Shows], th[Chapter],
  [`hello`], [presence, GET_ADAPTERCONFIG_EXTENDED, ACKSEQ across Reset], [5],
  [`netget`], [OPEN, STATUS, READ, CLOSE over HTTP], [6],
  [`json`], [SET_PARSER, PARSE, QUERY], [6],
  [`dir`], [READ_HOST_SLOTS, MOUNT_HOST, the directory commands], [7],
  [`appkey`], [OPEN, READ and WRITE an app key], [7],
  [`boot`], [MOUNT_IMAGE, progress, the loader], [8],
  [`clock`], [the clock, drawn in vblank], [9],
  [`netcat`], [a terminal: TCP, an on-screen keyboard, a scrolling pane], [D],
)
