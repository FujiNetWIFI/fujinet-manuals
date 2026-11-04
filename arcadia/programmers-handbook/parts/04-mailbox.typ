#import "../lib.typ": *

= How the Mailbox Works <mailbox>

The ARCADIA-2001’s cartridge slot was built for a mask ROM. It carries an
address and gets back a byte, and that is all it does: there is no line on
the connector a write could use. A program cannot store a byte into the
cartridge.

So the cartridge listens to _where_ the console reads. Every read puts an
address on the connector, and the game chip sees all fourteen lines of it.
A read of `$2F41` is a perfectly good way of saying `$41`: the high byte
names what the byte is for, the low byte carries it. Going the other way is
simpler still. The game chip paints its answers into the ROM it serves, and
by the time the console reads them they are just ROM. The FujiNet mailbox
is built on those two ideas.

== Writing by reading

The mailbox has three pages of _hotspots_. A read from any of them sends its
low byte to the cartridge; what it gives back the program ignores.

#tbl((0.7in, 1fr),
  [*Page*], [*A read of `$pp`_vv_ sends vv as*],
  [`$2D00`], [REGSEL: the number of the register the next byte goes to],
  [`$2E00`], [REGDATA: the value for the register REGSEL named],
  [`$2F00`], [one byte of the TX stream: the parameters, then the payload],
)

Setting a register takes two reads, one of `$2D00` plus the register
number, then one of `$2E00` plus the value. A REGDATA read with no REGSEL
just before it is ignored, and a REGSEL is good for one REGDATA. The
runtime’s `FNREGWR` makes the pair:

#excerpt-at(auto, "listings/runtime/fujilib.inc", "; Write mailbox register", to: "; Rewind the TX pointer")

The register number and the value ride in the _index_ registers, R1 and R2.
That is the 2650 idiom the whole mailbox is written in: `LODA,R0 *FSELP,R1`
reads the address the pointer word `FSELP` holds (`$2D00`), plus R1. The
byte read lands in R0 and nobody looks at it.

#note[Why the pointer word? The runtime lives in block 1, page 0 of the
2650’s address space, and the hotspots are in block 2, page 1. A 2650 load
reaches only its own 8K page, but an indirect address carries all fifteen
bits. Section 8 is about this rule; code in block 2 reads the hotspots
directly, as CONFIG does.]

== The registers

#tbl((0.95in, 0.45in, 1fr),
  [*Name*], [*No.*], [*A value written*],
  [DEVICE], [`$00`], [the FujiNet device: `$70` the Fuji device, `$71` the first network channel, `$45` the clock],
  [CMD], [`$01`], [the command, such as `$C4`],
  [NPARAM], [`$02`], [how many parameters lead the TX stream; at most 8],
  [DATA_RST], [`$05`], [any value: the TX stream starts over],
  [RXSLICE], [`$06`], [which 256 bytes of the reply the window shows, 0--3],
  [SEQ], [`$10`], [a new sequence number: *launch*],
  [BOOTLOCK], [`$11`], [`$B5`: arm a staged image (Section 13)],
)

The rest -- the two-step BOOTSEL and the cartridge RAM registers of
protocol 2 -- are in Section 20.

== The TX stream

After the registers, the program streams what the command takes. Each
parameter is its size, 1, 2 or 4, then its value, low byte first: a one-byte
7 goes as `$01 $07`, a two-byte 512 as `$02 $00 $02`. After the parameters
comes the payload, the command’s free-form bytes, such as a URL. The stream
holds 320 bytes; the cartridge drops any more.

#tbl((1in, 1fr),
  [*Routine*], [*Streams*],
  [`FNPARB`], [a one-byte parameter, the value in R2],
  [`FNPARW`], [a two-byte parameter, R2 the low byte, R3 the high (`booklib.inc`)],
  [`FNTXSTR`], [the NUL-terminated string at `(FSTRP)`, without its NUL],
  [`FNPATH`], [the same string, padded with NULs to exactly 256 bytes],
  [`FNTXN`], [R2 bytes from `(FSTRP)`, NULs and all (`booklib.inc`)],
)

To append a byte _v_ the program reads `$2F00` + _v_, so the byte to send must
be in an index register: `LODA,R0 *FTXP,R1` appends R1.

== The transaction

A command is a short conversation. The program names the device and the
command, says how many parameters follow, streams them, and writes a new
sequence number. That last write launches the transaction. The game chip
sends the request to the network chip over USB, waits for its reply, and
paints it into the window it serves: the first 256 bytes at `$2B00`, a status
page at `$2C00`. The very last byte it paints is ACKSEQ, the sequence number
the program wrote: when ACKSEQ matches, the whole reply is in place.

#seq(
  (([*ARCADIA-2001*], tint), ([*Game chip (RP2354A)*], paper), ([*Network chip (ESP32-S3)*], paper)),
  msg(0, 1, "read $2D05, $2E00; $2D00, $2E70   DATA_RST, DEVICE = $70"),
  msg(0, 1, "read $2D01, $2EC4; $2D02, $2E00   CMD = $C4, NPARAM = 0"),
  msg(0, 1, "read $2Fxx ...   parameters, payload"),
  msg(0, 1, "read $2D10, $2E02   SEQ = ACKSEQ + 1: launch"),
  msg(1, 2, "FujiBus request, over USB"),
  msg(2, 1, "the reply", dashed: true),
  snote(1, [reply to `$2B00`, status to `$2C00`, ACKSEQ last]),
  msg(1, 0, "read $2C00 = SEQ: done", dashed: true),
  w: measure-w - 10pt)

== The status page

The cartridge paints the status page, `$2C00-$2C0F`, with every reply:

#tbl((0.55in, 0.95in, 1fr),
  [*At*], [*Name*], [*Holds*],
  [`$2C00`], [ACKSEQ], [the sequence number answered; painted last],
  [`$2C01`], [STATUS], [bit 0: the link to the network chip is up],
  [`$2C02`], [ERR], [0 when the transaction went through (Appendix B)],
  [`$2C03`], [REPLY], [`$06` ACK or `$15` NAK: the FujiNet’s verdict],
  [`$2C04`], [RXLEN], [how long the reply is, two bytes, low first; at most 1,024],
  [`$2C06`], [BOOT_STATE], [the staged image: idle, coming, ready, failed (Section 13)],
  [`$2C07`], [BOOT_PCT], [how much of it has come, 0--100],
  [`$2C08`], [BOOT_ERR], [why staging failed],
  [`$2C09`], [MAGIC], [`'F'`, `'N'`: a FujiNet cartridge is there],
  [`$2C0B`], [PROTO_VER], [the mailbox’s version: 2],
  [`$2C0C`], [SLICE_ECHO], [which reply slice the window shows; painted last after a slice],
  [`$2C0E`], [TICK], [a 60 Hz count, two bytes (Section 15)],
)

`FNCHECK` reads the magic: R0 = 0 when the cartridge is a FujiNet. On an
ordinary 8K EPROM those two bytes are whatever the image holds there, which
is how `fujitest` tells you it is not on a FujiNet cartridge.

== The reply window

A reply can be up to 1,024 bytes, but the window at `$2B00` is 256: it shows
one _slice_ at a time. After a transaction it shows slice 0. To see bytes
256--511, write RXSLICE = 1 and wait for SLICE_ECHO to say 1 -- the repaint
takes a moment on the real cartridge, and SLICE_ECHO is painted after it.
`FNSLICE` does both, with the slice in R2:

#excerpt-at(auto, "listings/runtime/fujilib.inc", "; Select reply slice R2", to: "; R0 = 0 when the 'F','N' magic")

The reply and RXLEN change only when a transaction ends or a slice is
selected, so a program may read them as often as it likes, and print
straight out of the window. With 288 bytes of RAM, it usually must.

== The sequence number

The next sequence number is always the cartridge’s ACKSEQ plus one, with 255
followed by 1: zero is never used. Never keep a counter of your own. The
console’s RESET restarts your program but not the cartridge, which keeps
ACKSEQ, so a counter that starts at 1 again would write a number the
cartridge has already answered -- and writing that number does nothing at
all. `FNCOMMIT` reads ACKSEQ every time:

#excerpt-at(auto, "listings/runtime/fujilib.inc", "FNCOMMIT:", to: "FNCMO:")

== How long to wait

The cartridge gives the network chip 5 seconds to answer a command, 60 for
MOUNT_IMAGE and COPY_FILE, and 90 for a network channel’s OPEN, STATUS, READ
and CLOSE. When its time runs out, ERR says so (2, a timeout) and ACKSEQ is
painted as usual.

`FNCOMMIT` waits for ACKSEQ for about six seconds -- 65,536 polls of some
90 µs each -- and then returns `FETIMO` (`$FF`). That is enough for an
ordinary command and not for a slow one. The handbook’s `FNGO` keeps
polling the _same_ sequence number for another 90 seconds when `FNCOMMIT`
gives up, then checks ERR and REPLY:

#excerpt-at(auto, "listings/asm/booklib.inc", "FNGO:   BSTA,UN FNCOMMIT", to: "; WAITF")

#important[Never launch again after a timeout of your own. The transaction
is still running in the cartridge; a new sequence number would start a
second one behind it, and the reply to the first would arrive looking like
the answer to the second. Wait longer than the cartridge does, and the
question never comes up.]

#note[In MAME the whole transaction runs inside the read that writes SEQ: by
the next instruction ACKSEQ already matches. That is why a program that
waits too little works perfectly in MAME. Count on the times above, not on
what the emulator shows.]

== The recipe

#steps(
  [`FNCHECK` once at start: R0 = 0 if a FujiNet cartridge answers.],
  [`FNBEGIN device, command, nparam` (`booklib.inc`): DATA_RST, then the
   three registers.],
  [Stream the parameters, then the payload.],
  [`FNGO`: it launches with ACKSEQ + 1, waits as long as the cartridge may,
   and checks the reply. R0 = 0, CC EQ, on an ACK; otherwise ERR, `FETIMO`,
   or `FCNAK` (`$15`) when the FujiNet said no.],
  [The reply is at `$2B00`, RXLEN bytes; `FNSLICE` for any past the first
   256.],
)

Here is first contact (Section 10) in those five steps:

#asmp("        BSTA,UN FNCHECK         ; 1. a FujiNet cartridge?
        BCFA,EQ NOCART
        FNBEGIN FNDFUJI, FCACFGX, 0 ; 2. GET_ADAPTERCONFIG_EXTENDED
        BSTA,UN FNGO            ; 3. nothing to stream; 4. go
        BCFA,EQ FAIL
        SETSTR  FNRDATA         ; 5. the SSID is at $2B00
        LODI,R2 $40-1
        BSTA,UN DPRINT")
