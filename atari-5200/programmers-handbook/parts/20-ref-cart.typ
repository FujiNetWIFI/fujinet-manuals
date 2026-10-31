#import "../lib.typ": *
= Command Reference: The Cartridge Itself <ch-ref-cart>

Some of what a FujiNet program can ask for never leaves the cartridge: its registers, the stub that hands the console over, the status page, the boards it serves. This section is all of it, from the cartridge’s own `fuji_mailbox.h` and the shared `fuji_mailbox_proto.h`.

#sect[The hotspot pages]

#tbl((auto, 1fr),
  th[Read], th[What it does],
  [`$B500`+_n_, _n_ < `$80`], [Picks register _n_ for the next read of `$B600`.],
  [`$B580`–`$B5FF`], [Not registers. Nothing happens, except at the stub (below).],
  [`$B600`+_v_], [Sets the picked register to _v_. With no register picked, nothing happens.],
  [`$B700`+_b_], [Appends the byte _b_ to the TX stream.],
)

Every hotspot read returns `$FF`, except the three bytes of the stub.

#sect[Registers]

Registers `$00`–`$13` are the protocol’s, shared by every FujiNet cartridge; `$14` is the 5200’s.

#tbl((auto, auto, 1fr),
  th[Register], th[Select], th[Meaning],
  [`$00` DEVICE], [`$B500`], [FujiBus device of the next transaction.],
  [`$01` CMD], [`$B501`], [Its command.],
  [`$02` NPARAM], [`$B502`], [How many parameters the TX stream holds, at most 8.],
  [`$05` DATA_RST], [`$B505`], [Any value: rewind the TX stream.],
  [`$06` RXSLICE], [`$B506`], [The reply slice shown; the 5200 has one, so 0.],
  [`$10` SEQ], [`$B510`], [Non-zero and not the last one: launch.],
  [`$11` BOOTLOCK], [`$B511`], [`$B5`: arm the staged image for the hand-over. Ignored until BOOTSTATE says READY.],
  [`$12`, `$13` BOOTSEL], [`$B512`, `$B513`], [`$B5` then `$4A`: restart the RP2354B in its USB boot mode, to load new firmware. Two writes, so no single stray read can do it.],
  [`$14` CONFIG], [`$B514`], [`$C5`: stage CONFIG and arm the hand-over to it.],
)

#sect[The stub]

`$B5F0`–`$B5F2` serve `$6C $FC $FF`: `JMP ($FFFC)`. The read of `$B5F2`, the instruction’s last byte, swaps in the armed image, so the jump reads the BIOS’s reset vector with the new image already in the window. Unarmed, the jump just restarts the BIOS with what is already there.

#sect[The status page]

Everything the cartridge paints, `$B400`–`$B4FB`. @ch-mailbox introduced the first ones.

#tbl((auto, auto, 1fr),
  th[Address], th[Name], th[Meaning],
  [`$B400`], [ACKSEQ], [The last sequence number answered. Painted last. 0 after every power-on and hand-over.],
  [`$B401`], [STAT], [Bit 0: the link to the FujiNet is up.],
  [`$B402`], [ERR], [The last transaction’s error (below).],
  [`$B403`], [REPLYCMD], [`$06` ACK, `$15` NAK; 0 if the transaction never reached the FujiNet.],
  [`$B404`–`$B405`], [RXLEN], [The reply’s length, low byte first; at most 1024.],
  [`$B406`], [BOOTSTATE], [0 idle, 1 arriving, 2 ready, `$80` failed.],
  [`$B407`], [BOOTPCT], [0–100.],
  [`$B408`], [BOOTERR], [Why the push failed (below).],
  [`$B409`–`$B40A`], [MAGIC], [`'F'`, `'N'`.],
  [`$B40B`], [PROTOVER], [The mailbox protocol’s version: 1.],
  [`$B40C`], [SLICE_ECHO], [The reply slice shown.],
  [`$B412`], [MODE], [0 BOOT, 2 GAME, 3 APP.],
  [`$B414`], [MAPPER], [The board the live image is served as (below).],
  [`$B415`], [LINK], [1 once the FujiNet has been seen.],
  [`$B416`–`$B418`], [BOOTGOT], [Bytes of the push received so far, 24 bits, low first.],
  [`$B419`–`$B41B`], [BOOTTOT], [The size the push declared, 24 bits; 0 until it starts.],
  [`$B41C`], [ARMED], [1 once a swap is armed: jump to the stub.],
  [`$B41D`], [STAGED], [The pushed image: bit 0 ready, bit 1 it carries the claim, bit 2 it is CONFIG.],
  [`$B41E`], [STAGEDKIND], [The board it will be served as.],
  [`$B41F`–`$B422`], [STAGEDCRC], [Its CRC-32, low byte first.],
  [`$B423`], [SWAPS], [Hand-overs since power-on, modulo 256.],
)

#sect[Codes]

#tbl((auto, auto, 1fr),
  th[Field], th[Value], th[Meaning],
  [ERR], [0], [None.],
  [], [1], [No link to the FujiNet.],
  [], [2], [The FujiNet did not answer within the cartridge’s budget.],
  [], [3], [A bad frame: a parameter whose size is not 1, 2 or 4.],
  [], [4], [Too big.],
  [BOOTERR], [1], [The image is bigger than 128K.],
  [], [2], [The push ended before the declared size.],
  [], [3], [No board fits the image.],
  [], [4], [The only room that fits it is the one being served.],
  [MAPPER, STAGEDKIND], [0], [ROM: up to 32K, repeated to fill the window.],
  [], [1], [Two chips: 16K, each 8K twice.],
  [], [2], [Bounty Bob Strikes Back: 40K.],
  [], [3], [Super Cart: 64K or 128K.],
)

The claim’s kind byte at `$BFE5` is the board plus one, or 0 for “decide from the size”.

#sect[The budgets]

#tbl((auto, 1fr),
  th[Seconds], th[For],
  [5], [Every command not below.],
  [60], [MOUNT_IMAGE and COPY_FILE.],
  [90], [OPEN, CLOSE, STATUS and READ on the network devices `$71`–`$78`.],
  [3], [Waiting for the link before the console’s first transaction.],
)

#sect[The push]

While MOUNT_IMAGE is outstanding, the FujiNet sends the image to the cartridge as device `$FF`, on the cartridge’s own link: an OPEN (`$4F`) with the stream number and the 32-bit size, WRITEs (`$57`) of the bytes in order, and a CLOSE (`$43`), whose payload `$01` means the push was abandoned. Stream 1, the image’s `.cfg` file, if there is one, comes first; stream 0 is the image. The console sees none of it, only BOOTSTATE, BOOTPCT, BOOTGOT and BOOTTOT moving.
