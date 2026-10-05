#import "../lib.typ": *

= The Cartridge Mailbox

#lead[Everything your program says to the FujiNet, and everything the
FujiNet says back, passes through 2K of addresses at \$5000. The console
writes into some of them; the cartridge paints the others.]

== Two directions

The cartridge edge carries the CPU's R/W line, so the mailbox can tell a
read from a write, and it uses that:

#runin(
  ("Console to cartridge", [is always a *write*, to one of three write-only
   pages. Reading those pages does nothing at all.]),
  ("Cartridge to console", [is always memory the cartridge has *painted*:
   the 1K reply window and the status page. Your program reads them like
   RAM.]),
)

#tbl((auto, auto, 1fr),
  th[Address], th[Direction], th[What it is],
  [`$5000-$53FF`], [read], [The reply window: the whole of the last reply, up to 1024 bytes.],
  [`$5400-$54FF`], [read], [The status page: sequence, error, length, boot progress.],
  [`$5500-$557F`], [write], [Registers. A store of value V to `$5500+n` sets register n to V.],
  [`$5580-$55FF`], [write], [One-shot operations (only `$55FE`, the loader's).],
  [`$5600-$56FF`], [write], [Raw REGDATA, kept for the firmware's shared decoder. Programs never use it.],
  [`$5700-$57FF`], [write], [The TX stream. A store anywhere in the page appends one byte.],
)

== The one rule

#caution[Only `STA`, `STX` and `STY` may touch `$5500-$57FF`, plain or
indexed. Never a read-modify-write instruction.]

`INC`, `DEC`, `ASL`, `LSR`, `ROL` and `ROR` with an absolute address -- and
the undocumented `SLO`, `RLA`, `SRE`, `RRA`, `DCP` and `ISC` -- read the
location, write the *old* value back, and then write the new one, on
consecutive cycles. On a page where every write is an event, the old value
lands as an event of its own: an `INC $5510` would launch two transactions.

An indexed store is safe. `STA $5700,X` spends an extra cycle reading the
target address before it writes, but reads of these pages are inert.

Three things stand guard. `checkrom.py` refuses an image with such an
instruction aimed at the mailbox. fujinet-lib's `nes-romstamp.py` does the
same. And the cartridge itself recognises the exact signature -- two writes to
one address on adjacent cycles -- drops the first, and counts it in
`DIAG_RMW` at `$5413`, so a program can show the count on screen while you
look for the culprit.

In C, the rule means never `++`, `--`, `|=` or the like on a mailbox address.
fujinet-lib keeps every mailbox store inside two tiny functions, `fn_regwr()`
and `fn_tx()`, so the compiler can only ever emit a plain `sta`.

== The status page

The cartridge paints these cells. Read them whenever you like.

#tbl((auto, auto, 1fr),
  th[Address], th[Name], th[Meaning],
  [`$5400`], [ACKSEQ], [The sequence number of the last transaction answered. Painted *last*.],
  [`$5401`], [STATUS], [Bit 0: the USB link to the FujiNet is up. Bit 1: busy.],
  [`$5402`], [ERR], [How the last transaction went: 0 OK, 1 no link, 2 timeout, 3 bad frame, 4 too big.],
  [`$5403`], [REPLY_CMD], [`$06` ACK, the FujiNet said yes; `$15` NAK, it said no.],
  [`$5404-$5405`], [RXLEN], [Length of the reply in the window, low byte first.],
  [`$5406`], [BOOT_STATE], [0 idle, 1 transferring, 2 ready, `$80` failed (Chapter 8).],
  [`$5407`], [BOOT_PCT], [0-100 while an image is pushed.],
  [`$5408`], [BOOT_ERR], [Why a load failed: 1 too big, 2 truncated, 3 no such mapper, 4 store busy.],
  [`$5409-$540A`], [MAGIC], [`'F'`, `'N'`: a FujiNet cartridge is present.],
  [`$540B`], [PROTO_VER], [The mailbox protocol version, 1.],
  [`$540C`], [SLICE_ECHO], [Always 0: the reply is never sliced on the NES.],
  [`$540D-$5411`], [LOAD\_\*], [The loader's half: state, destination, offset, sequence, percent.],
  [`$5412`], [SRAM_STATE], [1 once the SRAMs are switched on.],
  [`$5413`], [DIAG_RMW], [How many read-modify-write dummy writes the cartridge has dropped.],
  [`$5414`], [MAPPER], [The mapper number of the running image, low byte.],
  [`$5415`], [LINK], [1 once the FujiNet has ever been seen.],
  [`$5416-$5418`], [BOOT_GOT], [Image bytes received so far, 24 bits.],
  [`$5419-$541B`], [BOOT_TOT], [Image size, 24 bits; 0 until the image starts arriving.],
)

On an ordinary cartridge these addresses are open bus, so checking for the
magic bytes is how a program knows it has a FujiNet at all:

#pair("        lda     $5409           ; FN_MAG0
        cmp     #'F'
        bne     nocart
        lda     $540A           ; FN_MAG1
        cmp     #'N'
        bne     nocart",
"if (!fuji_nes_present())    /* 'F','N' and version 1 */
  no_cartridge();")

== The registers

#tbl((auto, auto, auto, 1fr),
  th[Register], th[Address], th[Name], th[Meaning],
  [`$00`], [`$5500`], [DEVICE], [The FujiBus device: `$70` Fuji, `$71-$78` network, `$45` clock ...],
  [`$01`], [`$5501`], [CMD], [The command.],
  [`$02`], [`$5502`], [NPARAM], [How many parameters are in the TX stream.],
  [`$05`], [`$5505`], [DATA_RST], [Any value: rewind the TX stream to empty.],
  [`$06`], [`$5506`], [RXSLICE], [Which slice of the reply to show. Always 0 on the NES.],
  [`$10`], [`$5510`], [SEQ], [Nonzero and not ACKSEQ: *send the transaction*.],
  [`$11`], [`$5511`], [BOOTLOCK], [`$B5`: arm the loader for a staged image.],
  [`$12-$13`], [`$5512-$5513`], [BOOTSEL], [`$B5` then `$4A`: reboot the RP2354B into its USB bootloader.],
  [`$14`], [`$5514`], [SLICE_ACK], [The loader has copied a slice. Programs never use it.],
)

A register write is one store, so the library's routine for it is two
instructions long:

#excerpt-at("listings/common/fujilib.s", "listings/common/fujilib.s",
  "; fn_rw -- register X = A.", to: ".endproc", n: 4)

The register's number is in X and its value in A. The base address's low
byte is zero, so `$5500,X` never carries into the next page.

== The TX stream

The bytes you store at `$5700` make up, in order:

#steps(
  [NPARAM parameters, each a size byte -- 1, 2 or 4 -- followed by that many
   bytes of value, low byte first;],
  [then the payload, as raw bytes.],
)

There is room for 320 bytes in all, parameters included; stores past that
are silently dropped. Here is
SET_DEVICE_FULLPATH, which takes three one-byte parameters and a path:

#bytefield(("01", 22pt), ("00", 22pt), ("01", 22pt), ("00", 22pt),
  ("01", 22pt), ("01", 22pt), ("/nesbook/hello.bin", 110pt), ("00 ... 00", 50pt))
#align(center, text(size: 7pt)[size, slot #h(14pt) size, host #h(14pt) size,
mode #h(30pt) the path, padded with NULs to 256 bytes])

With NPARAM = 3 the cartridge reads three parameters and treats the rest as
the payload. Rewind the stream with DATA_RST before you start, and set
NPARAM to match what you stored.

== Committing a transaction

When the registers and the stream are ready, one store to SEQ sends the
transaction. The cartridge unpacks the stream, wraps it in a FujiBus packet,
sends it to the FujiNet over USB, and waits for the answer. Then it paints:

#fig(caption: [One transaction. ACKSEQ is painted last, so seeing it change
means everything else is already in place.],
  seq(("6502", "RP2354B", "ESP32-S3"),
    msg(0, 1, "STA $5500,$5501,$5502   device, command, nparam"),
    msg(0, 1, "STA $5700 ...           parameters, payload"),
    msg(0, 1, "STA $5510               SEQ = ACKSEQ+1"),
    msg(1, 2, "FujiBus packet over USB"),
    msg(2, 1, "ACK + reply data", dashed: true),
    snote(1, [paint \$5000 reply, RXLEN, ERR, REPLY_CMD -- then ACKSEQ]),
    msg(1, 0, "LDA $5400 = SEQ: done", dashed: true),
    w: 440pt))

Waiting is a loop that reads ACKSEQ until it equals the number you sent.
Here is the library's, which also gives up after about eleven seconds:

#excerpt-at("listings/common/fujilib.s: fn_go", "listings/common/fujilib.s",
  ".proc fn_go", to: ".endproc", n: 40, size: 6.8pt)

== Where the sequence number comes from

#caution[The next sequence number is the cartridge's own ACKSEQ plus one,
wrapping from 255 to 1. Zero means "never used". Never keep a counter of
your own.]

Pressing Reset restarts the CPU, and your program clears its RAM -- but the
cartridge has no reset line on the edge and keeps going. A program that
counts from 1 again after a Reset sends a sequence number the cartridge has
already answered. The cartridge ignores it, ACKSEQ already matches, and the
old reply still sitting in the window looks like a fresh success.

The cartridge ignores a SEQ of zero, and a SEQ equal to the last one it took.
`hello.s` in Chapter 5 prints ACKSEQ on the screen; press Reset and watch it
go up by one, not start again.

== The reply window

The reply is painted at `$5000` in one piece, RXLEN bytes long, up to 1024.
A longer reply is cut off at 1024.

The window holds still. The cartridge repaints it only when you commit the
next transaction -- or, while the loader is running, a slice. Until then you
can read it as often as you like, draw from it straight to the PPU, or stream
it back into the TX stream for the next transaction. CONFIG does exactly
that: it reads a directory entry out of the window and sends it back as the
path of the file to mount, without ever copying it into console RAM.

#note[Setting up the next transaction -- the registers, DATA_RST, the TX
stream -- does not touch the window. Only the commit does. So it is safe to
read a value out of one reply while you build the next request, as `json.s`
does in Chapter 6.]

== What can go wrong

After ACKSEQ matches, look at two cells:

#runin(
  ("ERR at $5402", [is the cartridge's own verdict on the trip. 0 means the
   FujiNet answered. 1 means the USB link was down (the cartridge waits up to
   three seconds for it). 2 means the FujiNet did not answer in time. 3 means
   the TX stream was malformed -- a size byte other than 1, 2 or 4 -- or the
   FujiNet's reply failed its checks. 4 means the request or the reply would not
   fit the cartridge's buffers.]),
  ("REPLY_CMD at $5403", [is the FujiNet's verdict on the request: `$06` ACK
   or `$15` NAK. A NAK carries no data.]),
)

If ACKSEQ never matches at all, the cartridge never saw your SEQ store: you
are running without the claim, on a cartridge that is not a FujiNet, or you
wrote SEQ equal to ACKSEQ. The library calls that `FNEWAIT`, `$FF`.

== How long to wait

The cartridge gives each transaction five seconds to come back from the
FujiNet, and sixty for MOUNT_IMAGE and COPY_FILE, which do not answer until
a whole file has been moved. It reports a TIMEOUT in ERR when the time runs
out -- so your own wait should be longer, or you will give up first and
never see the cartridge's error code.

#tbl((1fr, auto),
  th[Who waits], th[How long],
  [The cartridge, for an ordinary transaction], [5 s],
  [The cartridge, for MOUNT_IMAGE and COPY_FILE], [60 s],
  [The cartridge, for the USB link to come up], [3 s],
  [`fn_go` in fujilib.s (16 quanta of about 0.7 s)], [about 11 s],
  [`fn_commit()` in fujinet-lib], [about 12 s],
  [CONFIG, for a mount], [65 s],
)

#caution[Both libraries' waits are shorter than the cartridge's sixty
seconds for MOUNT_IMAGE. For a large image, launch the mount without waiting
and watch it yourself, as Chapter 8 shows.]

== The NMI

Because the console's half of the mailbox is writes and the cartridge's half
is reads, an interrupt can land anywhere in a transaction without harm. The
vblank NMI handler may read the status page -- or anything else -- as long as
it never *writes* to `$5500-$57FF`. cc65's own NMI handler touches only the
PPU and RAM, so a C program is safe without thinking about it.
