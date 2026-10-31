#import "../lib.typ": *
= How the Mailbox Works <ch-mailbox>

The 5200’s cartridge edge has no read/write line. The cartridge cannot tell a store from a load, and it never sees the byte a store puts on the bus. So everything the console sends to the FujiNet travels in the *address* of a read: the console reads `$B600`+_v_ to say “_v_”, and the cartridge, which sees every address, takes the byte from the low half of it. Everything the console learns, it reads from memory the cartridge paints. Five pages do all the work.

#tbl((auto, auto, 1fr),
  th[Address], th[Read it to], th[What it is],
  [`$B000`–`$B3FF`], [learn], [The reply window: up to 1024 bytes of the last reply.],
  [`$B400`–`$B4FB`], [learn], [The status page: sequence number, error, reply length, boot progress, the cartridge’s mode.],
  [`$B500`–`$B57F`], [say], [Register select. A read of `$B500`+_n_ picks register _n_.],
  [`$B600`–`$B6FF`], [say], [Register data. A read of `$B600`+_v_ sets the picked register to _v_.],
  [`$B700`–`$B7FF`], [say], [The TX stream. A read of `$B700`+_b_ appends the byte _b_.],
)

The value a read of `$B500`–`$B7FF` returns means nothing: the cartridge answers `$FF`. The top half of the select page, `$B580`–`$B5FF`, is the cartridge’s own; @ch-ref-cart lists what is there.

#sect[A register is two reads]

To set register _n_ to _v_, read `$B500`+_n_, then read `$B600`+_v_. With the value in `Y`, the second read is one indexed load. To set the device, the command and the parameter count, and to rewind the TX stream:

#pair(
"        ldx     #FN_REG_DEVICE
        lda     FN_REGSEL,x     ; pick register $00
        ldy     #$70            ; the FUJI device
        lda     FN_REGDATA,y    ; ...and set it
        ldx     #FN_REG_CMD
        lda     FN_REGSEL,x
        ldy     #$C4            ; GET_ADAPTERCONFIG_EXTENDED
        lda     FN_REGDATA,y
        ldx     #FN_REG_NPARAM
        lda     FN_REGSEL,x
        ldy     #0              ; no parameters
        lda     FN_REGDATA,y
        ldx     #FN_REG_DATA_RST
        lda     FN_REGSEL,x
        lda     FN_REGDATA,y    ; any value rewinds",
"fn_regwr(FNR_DEVICE, 0x70);      /* the FUJI device */
fn_regwr(FNR_CMD, 0xC4);         /* GET_ADAPTERCONFIG_EXTENDED */
fn_regwr(FNR_NPARAM, 0);         /* no parameters */
fn_regwr(FNR_DATA_RST, 0);")

The assembly library wraps the pair as `fn_rw`, register `X` = `A`. In C, `fn_regwr()` is fujinet-lib’s, written in assembly so that each half is exactly one `LDA` from a page-aligned base. A data read with no select read just before it does nothing at all.

#tbl((auto, auto, 1fr),
  th[Register], th[Select], th[Meaning],
  [`$00` DEVICE], [`$B500`], [The FujiBus device: `$70` the FujiNet itself, `$71`–`$78` the network devices, `$45` the clock.],
  [`$01` CMD], [`$B501`], [The command.],
  [`$02` NPARAM], [`$B502`], [How many parameters the TX stream holds.],
  [`$05` DATA_RST], [`$B505`], [Any value: rewind the TX stream to its start.],
  [`$06` RXSLICE], [`$B506`], [Which 1K slice the reply window shows. There is one slice; leave it 0.],
  [`$10` SEQ], [`$B510`], [Launch the transaction (below).],
  [`$11` BOOTLOCK], [`$B511`], [`$B5`: arm a pushed image for the hand-over (@ch-boot).],
  [`$12`, `$13`], [`$B512`–`$B513`], [`$B5` then `$4A`: reboot the cartridge’s RP2354B for a firmware update.],
  [`$14` CONFIG], [`$B514`], [`$C5`: stage CONFIG and arm the hand-over back to it.],
)

#caution[Read `$B500`–`$B7FF` only with `LDA`, `LDX`, `LDY` or `BIT`, absolute or absolute-indexed, from a page-aligned base. Never store there: with no read/write line, the cartridge counts a store as a read, and its buffer drives the bus against the CPU. Never use `INC`, `DEC`, `ASL`, `LSR`, `ROL`, `ROR` or `(zp),Y` on these pages: each makes extra accesses that the cartridge counts. Never read one hotspot address on two bus cycles in a row: on the 4-port console, which has no clock on the edge, the cartridge sees them as one. In C, never touch these pages except through `fn_regwr()` and `fn_tx()`.]

The build tools hold you to this. `checkrom.py` reads the assembler’s map and refuses an image that stores into the cartridge window, uses a read-modify-write instruction or `JMP ($xxFF)` there, or reads a hotspot page from a base that is not page-aligned. MekkoGX’s `atari5200-romstamp.py` makes the same checks on a C program.

#sect[The TX stream]

Parameters and payload go into the TX stream one read per byte. Each parameter is its size (1, 2 or 4) and then its value, low byte first. The payload, if the command takes one, follows the last parameter.

#bytefield(([size], 36pt), ([value…], 52pt), ([size], 36pt), ([value…], 52pt), ([…], 24pt), ([payload…], 70pt))

The stream holds 320 bytes and at most eight parameters. A parameter of any other size fails the transaction with error 3 before anything is sent; bytes past 320 are dropped. `DATA_RST` rewinds the stream, so write it before the first byte of every transaction.

#pair(
"        lda     #1              ; a one-byte parameter...
        tay
        lda     FN_TXDATA,y     ; ...its size
        ldy     #$02            ; ...and its value
        lda     FN_TXDATA,y",
"fn_tx(1);                        /* a one-byte parameter: its size */
fn_tx(0x02);                     /* ...and its value */")

#sect[Launching, and the sequence number]

A transaction is launched by one more register write: the next sequence number into register `$10`. The cartridge sends the request to the FujiNet, waits for the answer, paints the reply into `$B000`, the error and the reply length into the status page, and then, *last*, copies your sequence number into `ACKSEQ` at `$B400`. The moment `ACKSEQ` equals your number, everything else is in place.

#fig(seq(
  (("CONSOLE", tint-a), ("CARTRIDGE", tint-b), ("ADAPTER", tint-c)),
  msg(0, 1, "LDA $B510, LDA $B600+SEQ"),
  msg(1, 2, "FujiBus request"),
  snote(0, "LDA $B400 until it matches"),
  msg(2, 1, "reply", dashed: true),
  snote(1, "paint $B000, ERR, RXLEN; then ACKSEQ"),
  msg(1, 0, "ACKSEQ = SEQ", dashed: true),
), caption: [A transaction. The console only ever reads.])

The next number is always the cartridge’s own `ACKSEQ` plus one, wrapping from 255 to 1. Zero is reserved, and a number equal to the last one does nothing at all, so a stray repeat cannot send a request twice. Take the number from the cartridge every time, never from a counter of your own. The cartridge starts its count over whenever a program starts, at power-on and at every hand-over (@ch-boot), and only the cartridge knows where it has got to.

#sect[The status page]

The cartridge paints the status page at `$B400` after every transaction and whenever its state changes. Read it in place; it is ordinary memory to the console.

#tbl((auto, auto, 1fr),
  th[Address], th[Name], th[Meaning],
  [`$B400`], [ACKSEQ], [Your sequence number, copied here last, when the reply is in place.],
  [`$B401`], [STAT], [Bit 0: the link to the FujiNet is up.],
  [`$B402`], [ERR], [The transaction’s error: 0 none, 1 no link, 2 the FujiNet did not answer in time, 3 a bad frame (a parameter of the wrong size), 4 too big.],
  [`$B403`], [REPLYCMD], [The FujiNet’s answer: `$06` ACK, `$15` NAK.],
  [`$B404`], [RXLEN], [The reply’s length in bytes, low byte first.],
  [`$B406`], [BOOTSTATE], [Booting another image: 0 idle, 1 arriving, 2 ready, `$80` failed (@ch-boot).],
  [`$B407`], [BOOTPCT], [How much of it has arrived, 0–100.],
  [`$B409`], [MAGIC], [`'F'`, `'N'`: a FujiNet cartridge is answering.],
  [`$B412`], [MODE], [0 BOOT, 2 GAME, 3 APP (@ch-map).],
)

@ch-ref-cart lists the rest. A program checks `MAGIC` once, at the start, before it trusts anything else: on a console with any other cartridge, or with none, the bytes there are something else.

#sect[The reply window]

The reply is painted at `$B000`, up to 1024 bytes, and `RXLEN` says how many are real. It stays until the next transaction replaces it, so a program can read it at leisure, but only until then. Copy anything you want to keep into RAM before you launch the next one.

#sect[How long to wait]

The cartridge gives every transaction a budget: five seconds for most commands, sixty for MOUNT_IMAGE and COPY_FILE, and ninety for a network device’s OPEN, CLOSE, STATUS and READ. When the budget runs out it reports error 2 and copies your sequence number anyway, so a program waiting on `ACKSEQ` always hears back from a cartridge that is there.

Wait a little longer than that budget yourself, for the case where nothing answers at all. The assembly library counts down `FN_TMO` seconds (12 unless you raise it after `fn_beg`) and returns `FNEWAIT` (`$FF`) when they run out. fujinet-lib waits at least as long as the cartridge would for each command, and reports `FN_EWAIT` the same way.

#sect[The recipe]

Every transaction is the same six steps:

#nsteps(
  [Set DEVICE, CMD and NPARAM, and rewind the TX stream.],
  [Append the parameters and the payload.],
  [Read `ACKSEQ`, add one (255 wraps to 1), and write it to SEQ.],
  [Wait for `ACKSEQ` to equal it.],
  [Check `ERR` for 0, then `REPLYCMD` for `$06`.],
  [Read the reply.],
)

In assembly, `fn_beg` does step 1 from `FN_DEV`, `FN_CMD` and `FN_NPR`; `fn_pb` and `fn_pw` do step 2; `fn_go` does steps 3 to 5 and returns `ERR`, or `FNEWAIT`; `fn_ack` checks `REPLYCMD`. In C, one fujinet-lib call does all six.

#pair(
"        lda     #FNDEVF         ; 1. the FUJI device...
        sta     FN_DEV
        lda     #FNCMHST        ;    ...MOUNT_HOST...
        sta     FN_CMD
        lda     #1              ;    ...one parameter
        sta     FN_NPR
        jsr     fn_beg
        lda     #0              ; 2. host slot 0
        jsr     fn_pb
        jsr     fn_go           ; 3-5. launch, wait, ERR
        bne     failed
        jsr     fn_ack          ;    REPLYCMD
        bne     refused",
"if (!fuji_mount_host_slot(0))    /* all six steps */
    failed();")
