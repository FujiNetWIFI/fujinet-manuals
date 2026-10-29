#import "../lib.typ": *

= How the Mailbox Works <mailbox>

The Studio II’s cartridge socket was built for ROM. It carries the address, the data and the strobe for a read, and nothing for a write: there is no write line on the edge at all. A program cannot store a byte into the cartridge.

So the cartridge listens to *where* the console reads. Every read puts an address on the bus, and the cartridge sees all sixteen bits of it. A read of `$EB41` is a perfectly good way of saying `$41`: the high byte names what the byte is for, the low byte carries it. The FujiNet mailbox is built on that one idea.

== Writing by reading

The mailbox has three pages of _hotspots_. A read from any of them sends its low byte to the cartridge, and gives back `$FF`, which the program ignores.

#tbl((0.55in, 1fr),
  [*Page*], [*A read of `$pp`_vv_ sends vv as*],
  [`$E9`], [REGSEL: the number of the register the next byte goes to],
  [`$EA`], [REGDATA: the value for the register REGSEL named],
  [`$EB`], [one byte of the TX stream: parameters and payload],
)

Setting a register takes two reads, one of `$E900` plus the register number, then one of `$EA00` plus the value. A REGDATA read with no REGSEL read before it is ignored, and a REGSEL is good for one REGDATA. The runtime’s `fn_rw` makes the pair, with RF as the pointer, and leaves RF parked on page `$0B` so a stray read through it touches nothing:

#excerpt-at(auto, "listings/runtime/fujilib.inc", "fn_rw:", to: "; fn_txb")

#important[Read the hotspots with LDN only. An LDA through RF would step RF to the next address, and the next read through it would send a byte you never meant.]

== The registers

#tbl((0.72in, 0.34in, 1fr),
  [*Name*], [*No.*], [*A value written*],
  [DEVICE], [`$00`], [the FujiNet device: `$70` the FUJI device, `$71` a network channel ...],
  [CMD], [`$01`], [the command, such as `$C4`],
  [NPARAM], [`$02`], [how many parameters lead the TX stream; at most 8],
  [DATA_RST], [`$05`], [any value: the TX stream starts over],
  [SEQ], [`$10`], [a new sequence number: *launch*],
  [BOOTLOCK], [`$11`], [`$B5`: arm a staged image],
  [CONFIG], [`$14`], [`$C5`: stage CONFIG and arm it],
)

The whole table, with the two registers no program needs, is in The Cartridge Itself (page #pg(<ref-cart>)).

== The TX stream

After the registers, the program streams what the command takes. Each parameter is its size, 1, 2 or 4, then its value, low byte first: a one-byte 7 goes as `$01 $07`, a two-byte 512 as `$02 $00 $02`. After the parameters comes the payload, the command’s free-form bytes, such as a URL. The stream holds 320 bytes; the cartridge drops any more.

#tbl((0.95in, 1fr),
  [*Runtime call*], [*Streams*],
  [`fn_pb`], [a one-byte parameter, D],
  [`fn_pw`], [a two-byte parameter, R8],
  [`fn_txb`], [one byte, D, as it is],
  [`fn_path`], [a string at R8, padded with NULs to exactly 256 bytes],
  [`fn_str`], [a string at R8, as long as it is (`booklib.inc`)],
)

== The transaction

A command is a short conversation. The program names the device and the command, says how many parameters follow, streams them, and then writes a new sequence number. That last write launches the transaction. The cartridge sends the request to the ESP32-S3 over USB, waits for its reply, and paints it into the reply window, with a status page above it. The very last thing it paints is ACKSEQ, the sequence number the program wrote: when ACKSEQ matches, the whole reply is in place.

#wide(at: bottom, seq(
  (([*Studio II*], gold-lt), ([*Cartridge (RP2354B)*], white), ([*FujiNet (ESP32-S3)*], white)),
  msg(0, 1, "read $E900, $EA70   DEVICE = $70"),
  msg(0, 1, "read $E901, $EAC4   CMD = $C4"),
  msg(0, 1, "read $E902, $EA00; $E905, $EA00   NPARAM, DATA_RST"),
  msg(0, 1, "read $EBxx ...   parameters, payload"),
  msg(0, 1, "read $E910, $EA02   SEQ = ACKSEQ + 1: launch"),
  msg(1, 2, "FujiBus request, over USB"),
  msg(2, 1, "the reply", dashed: true),
  snote(1, [reply to `$E400`, status to `$E800`, ACKSEQ last]),
  msg(1, 0, "LDN $E800 = SEQ: done", dashed: true),
  w: 8.6in))

== The status page

The cartridge paints the status page, `$E800`, with every reply. The bytes a program reads after a transaction:

#tbl((0.42in, 0.78in, 1fr),
  [*At*], [*Name*], [*Holds*],
  [`+$00`], [ACKSEQ], [the sequence number answered; painted last],
  [`+$01`], [STAT], [bit 0: the link to the ESP32-S3 is up],
  [`+$02`], [ERR], [0 when the transaction went through (below)],
  [`+$03`], [REPLYCMD], [`$06` ACK or `$15` NAK: the FujiNet’s verdict],
  [`+$04`], [RXLEN], [how long the reply is, two bytes, low first],
  [`+$09`], [MAGIC], [`'F'`, `'N'`: a FujiNet cartridge],
)

Boot progress, the mode and a few counters live further up; The Cartridge Itself has them all.

== The reply window

The reply sits at `$E400`, up to 1024 bytes, RXLEN of them; past RXLEN the window reads 0. It stays until the next launch, so a program can read it as often as it likes, and the text engine can print from it directly, without the bytes crossing into the console at all. Launching the next transaction paints over it.

== The sequence number

The next sequence number is always the cartridge’s ACKSEQ plus one, skipping zero. Never keep a counter of your own: the cartridge keeps ACKSEQ across a press of CLEAR, so the first transaction after CLEAR is number 2, while turning the console off restarts the cartridge, and the first is number 1 again. Writing the number the cartridge already holds does nothing at all.

== How long to wait

The cartridge gives the FujiNet 5 seconds to answer a command, 60 for MOUNT_IMAGE and COPY_FILE, and 90 for a network channel’s OPEN, STATUS, READ and CLOSE. When the time runs out, ERR says so (`2`, a timeout) and ACKSEQ is painted as usual.

The runtime waits for ACKSEQ for 12 seconds by default; `fn_beg` sets it, in `V_TMO`. A slow command must raise it *above* the cartridge’s own limit, after `fn_beg`, as the `SLOW` macro does:

#asmp("        FNBEGIN NETDEV, NCOPEN, 2
        LDI     NMREAD
        FCALL   fn_pb
        LDI     NTRNONE
        FCALL   fn_pb
        LDR     R8, url
        FCALL   fn_str
        SLOW    95              ; past the cart's 90
        FCALL   fn_go
        BNZ     failed")

#important[If the runtime gives up first, it returns `FNEWAIT` (`$FF`) while the transaction is still running. Launching again with the same sequence number does nothing, and the reply that arrives later would look like the answer to the retry. Wait longer than the cartridge does, and the question never comes up.]

== The recipe

#nsteps(
  [`fn_chk` once at start: DF = 1 if a FujiNet cartridge answers.],
  [`FNBEGIN device, command, nparam`: the three registers and DATA_RST.],
  [Stream the parameters, then the payload.],
  [`SLOW` if the command can take longer than 12 seconds.],
  [`fn_go`: it launches with ACKSEQ + 1 and waits. D = 0 when the transaction went through, else the error.],
  [`fn_ack`: D = 0 if the FujiNet said ACK, `FNENAK` if it said no.],
  [The reply is at `$E400`, RXLEN bytes.],
)

`go_ack` in `booklib.inc` does steps 5 and 6, and the `GOACK` macro jumps to the failure screen if either says no; every program in this handbook is written with it.
