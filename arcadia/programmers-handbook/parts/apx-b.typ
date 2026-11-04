#import "../lib.typ": *
#set heading(numbering: "A")

= Error and Status Codes <apx-b>

== ERR, `$2C02`

#tbl((0.6in, 1.6in, 1fr),
  [*Value*], [*Name*], [*Means*],
  [0], [`FN_ERR_OK`], [the transaction went through; REPLY says what the FujiNet thought of it],
  [1], [`FN_ERR_NOLINK`], [the USB link to the network chip is down],
  [2], [`FN_ERR_TIMEOUT`], [the network chip did not answer in time (Section 20)],
  [3], [`FN_ERR_BADFRAME`], [the parameters were malformed: a size other than 1, 2 or 4],
  [4], [`FN_ERR_TOOBIG`], [the request or the reply did not fit],
)

== The libraries’ own

#tbl((0.6in, 1.6in, 1fr),
  [*Value*], [*Name*], [*Means*],
  [`$FF`], [`FETIMO`], [`FNCOMMIT` or `FNGO` waited and saw no answer],
  [`$15`], [`FCNAK`], [`FNGO`: the FujiNet said NAK],
  [`$FE`], [`FENOCRT`], [`FAIL`’s code: no FujiNet cartridge],
)

`fujiboot` shows ERR _c_ _dd_: _c_ is the step (1 MOUNT_HOST, 2
SET_DEVICE_FULLPATH, 3 MOUNT_IMAGE, 4 staging) and _dd_ the ERR, BOOT_ERR,
or `EE` for a NAK.

== REPLY, `$2C03`

`$06` ACK, `$15` NAK, 0 when there was no reply at all (ERR is not 0).

== BOOT_STATE, `$2C06`, and BOOT_ERR, `$2C08`

#tbl((0.6in, 1fr, 0.6in, 1fr),
  [*State*], [], [*Error*], [],
  [0], [idle], [1], [too big: over 71,680 bytes],
  [1], [coming], [2], [cut short],
  [2], [ready], [3], [not a size the cartridge can map],
  [`$80`], [failed], [4], [the store is busy],
)

== A network channel’s STATUS

The fourth byte: 1 when all is well, 136 at the end of the file; anything
else is the protocol’s error, and an HTTP error page is still readable.

== GET_WIFISTATUS

3 connected; anything else, not yet.
