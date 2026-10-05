#import "../lib.typ": *

#appendix.update(true)
#counter(heading).update(0)

= Error Codes

== The mailbox

After ACKSEQ matches, ERR at `$5402` is the cartridge's verdict on the trip and
REPLY_CMD at `$5403` is the FujiNet's on the request.

#tbl((auto, auto, 1fr),
  th[ERR], th[Name], th[Meaning],
  [0], [OK], [The FujiNet answered. Look at REPLY_CMD.],
  [1], [NOLINK], [No USB link to the FujiNet, even after waiting three seconds.],
  [2], [TIMEOUT], [No answer in 5 seconds (60 for MOUNT_IMAGE and COPY_FILE). Also: RESET, a disabled printer, and every modem command.],
  [3], [BADFRAME], [A size byte other than 1, 2 or 4 in the TX stream, or a reply that failed its checks.],
  [4], [TOOBIG], [The request or the reply would not fit the cartridge's buffers.],
)

#tbl((auto, auto, 1fr),
  th[REPLY_CMD], th[Name], th[Meaning],
  [`$06`], [ACK], [Yes. RXLEN bytes of reply are in the window.],
  [`$15`], [NAK], [No. A NAK never carries data.],
)

== The libraries

#tbl((auto, auto, 1fr),
  th[Value], th[Name], th[Meaning],
  [`$FF`], [`FNEWAIT`, `FN_EWAIT`], [The cartridge never answered: no claim, no FujiNet cartridge, or SEQ equal to ACKSEQ. Returned by `fn_go` and `fn_commit()`.],
  [`$EE`], [`FNENAK`], [`fn_ack`: the FujiNet said NAK.],
  [`$FD`], [`FNENOC`], [The bring-up programs' "no cartridge": the magic bytes are missing.],
  [0], [`FN_ERR_OK`], [fujinet-lib: success.],
  [1], [`FN_ERR_IO_ERROR`], [fujinet-lib: the transaction failed or was NAKed.],
  [2], [`FN_ERR_BAD_CMD`], [fujinet-lib: called with bad arguments.],
  [3-5], [`OFFLINE`, `WARNING`, `NO_DEVICE`], [fujinet-lib: not used on the NES.],
)

== Booting

#tbl((auto, auto, 1fr),
  th[BOOT_STATE], th[Name], th[Meaning],
  [0], [IDLE], [Nothing staged; also left by a MOUNT_IMAGE that NAKed.],
  [1], [XFER], [The image is arriving.],
  [2], [READY], [Staged. Arm BOOTLOCK and jump to `$5800`.],
  [`$80`], [FAILED], [See BOOT_ERR.],
)

#tbl((auto, auto, 1fr),
  th[BOOT_ERR], th[Name], th[Meaning],
  [1], [TOOBIG], [Too big for the staging store or for the SRAMs.],
  [2], [TRUNCATED], [The stream ended early.],
  [3], [NOMAP], [The cartridge does not implement the image's mapper.],
  [4], [STOREBUSY], [The staging store was in use.],
)

== The network device

The fourth byte of the network STATUS reply.

#tbl((auto, 1fr, auto, 1fr),
  th[Code], th[Meaning], th[Code], th[Meaning],
  [1], [Success], [200], [Connection refused],
  [131], [Write only], [201], [Network unreachable],
  [132], [Invalid command], [202], [Socket timeout],
  [135], [Read only], [203], [Network down],
  [136], [End of file], [204], [Connection reset],
  [138], [General timeout], [205], [Connection already in progress],
  [144], [General error], [206], [Address in use],
  [146], [Not implemented], [207], [Not connected],
  [151], [File exists], [208], [Server not running],
  [162], [No space on device], [209], [No connection waiting],
  [165], [Invalid devicespec], [210], [Service not available],
  [166], [Invalid point], [211], [Connection aborted],
  [167], [Access denied], [212], [Invalid username or password],
  [170], [File not found], [213], [Could not parse JSON],
  [], [], [214], [Client error],
  [], [], [215], [Server error],
  [], [], [255], [Could not allocate buffers],
)

An HTTP server's status code becomes one of these:

#tbl((auto, auto, auto, auto, auto, auto),
  th[HTTP], th[Error], th[HTTP], th[Error], th[HTTP], th[Error],
  [2xx], [1], [404, 410], [170], [423, 451], [167],
  [401-403, 407], [212], [405], [146], [other 4xx], [214],
  [408], [138], [5xx], [215], [no connection], [207],
)
