#import "../lib.typ": *
= How the Mailbox Works

#ini[T]he 7800’s cartridge edge has a read/write line, so talking to the FujiNet is ordinary memory traffic. The console *stores* to pages the cartridge watches, and *reads* pages the cartridge paints. Four pages do all the work.

#tbl((auto, auto, 1fr),
  th[Address], th[Direction], th[What it is],
  [`$0800`–`$0BFF`], [read], [The reply window: up to 1024 bytes of the last reply.],
  [`$0C00`–`$0CFB`], [read], [The status page: sequence number, error, reply length, boot and load progress, the cartridge’s mode.],
  [`$0D00`–`$0D7F`], [write], [The registers. A store of _V_ to `$0D00`+_n_ sets register _n_ to _V_.],
  [`$0F00`–`$0FFF`], [write], [The TX stream. Every store anywhere in the page appends its byte.],
)

Reading a write page returns nothing useful, and `$0E00`–`$0EFF` is not used at all. Everything a program sends is a store; everything it learns is a load.

#sect[A register is one store]

There is no register-select dance. To set the device, the command and the parameter count, you store three bytes, then a fourth to rewind the TX stream:

#trio(
"        lda     #$70            ; the FUJI device
        sta     FN_REGSEL+FN_REG_DEVICE
        lda     #$C4            ; GET_ADAPTERCONFIG_EXTENDED
        sta     FN_REGSEL+FN_REG_CMD
        lda     #0              ; no parameters
        sta     FN_REGSEL+FN_REG_NPARAM
        sta     FN_REGSEL+FN_REG_DATA_RST",
"fn_regwr(FNR_DEVICE, 0x70);      /* the FUJI device */
fn_regwr(FNR_CMD, 0xC4);         /* GET_ADAPTERCONFIG_EXTENDED */
fn_regwr(FNR_NPARAM, 0);         /* no parameters */
fn_regwr(FNR_DATA_RST, 0);",
" FN_DEVICE = $70
 FN_CMD = $C4
 FN_NPARAM = 0
 FN_DATA_RST = 0")

In C, `fn_regwr()` is fujinet-lib’s one-store register write; writing `FN_REGSEL[FNR_CMD] = 0xC4` directly compiles to the same `STA $0D01`. In 7800basic, the name of a register is its address (Section 9).

#tbl((auto, auto, 1fr),
  th[Register], th[Store to], th[Meaning],
  [`$00` DEVICE], [`$0D00`], [The FujiBus device: `$70` the FujiNet itself, `$71`–`$78` the network devices, `$45` the clock.],
  [`$01` CMD], [`$0D01`], [The command.],
  [`$02` NPARAM], [`$0D02`], [How many parameters the TX stream holds.],
  [`$05` DATA_RST], [`$0D05`], [Any value: rewind the TX stream to its start.],
  [`$06` RXSLICE], [`$0D06`], [Which 1K slice the reply window shows. There is one slice; leave it 0.],
  [`$10` SEQ], [`$0D10`], [Launch the transaction (below).],
  [`$11` BOOTLOCK], [`$0D11`], [`$B5`: arm a pushed image for the loader (Section 12).],
  [`$12`, `$13`], [`$0D12`–`$0D13`], [`$B5` then `$4A`: reboot the cartridge’s RP2354B for a firmware update.],
  [`$14` SLICE_ACK], [`$0D14`], [The loader’s: a slice has been copied.],
  [`$15` TV], [`$0D15`], [Tell the cartridge NTSC (0) or PAL (non-zero).],
  [`$16` HSC], [`$0D16`], [The High Score Cart: 0 off, 1 on, 2 forget, 3 install (Section 13).],
)

Stores to `$0D80`–`$0DFF` are not registers. Four of them are one-shot operations the loader uses, listed in Section 19; the rest do nothing.

#caution[Never use a read-modify-write instruction on `$0D00`–`$0FFF`. `INC`, `DEC`, `ASL`, `LSR`, `ROL` and `ROR` write the old value back before the new one, and the cartridge counts both writes. In C, never `++` or `|=` a mailbox address; in 7800basic, never `FN_TX = FN_TX + 1`. An indexed store such as `STA $0F00,X` is safe as long as it does not cross a page.]

#sect[The TX stream]

Parameters and payload go into `$0F00`, one store per byte. Each parameter is its size (1, 2 or 4) and then its value, low byte first. The payload, if the command takes one, follows the last parameter.

#bytefield(([size], 36pt), ([value…], 52pt), ([size], 36pt), ([value…], 52pt), ([…], 24pt), ([payload…], 70pt))

The stream holds 320 bytes and at most eight parameters. A parameter of any other size fails the transaction with error 3 before anything is sent; bytes past 320 are dropped. `DATA_RST` rewinds the stream, so write it before the first byte of every transaction. fujinet-lib writes it first of all; the assembly library writes it last of the four registers; the cartridge does not mind which.

#sect[Launching, and the sequence number]

A transaction is launched by one more store: the next sequence number into register `$10`. The cartridge sends the request to the FujiNet, waits for the answer, paints the reply into `$0800`, the error and the reply length into the status page, and then, *last*, copies your sequence number into `ACKSEQ` at `$0C00`. The moment `ACKSEQ` equals your number, everything else is in place.

#fig(seq(
  (("CONSOLE", tint-a), ("CARTRIDGE", tint-b), ("ADAPTER", tint-c)),
  msg(0, 1, "STA $0D10  SEQ = ACKSEQ+1"),
  msg(1, 2, "FujiBus request"),
  snote(0, "LDA $0C00 until it matches"),
  msg(2, 1, "reply", dashed: true),
  snote(1, "paint $0800, ERR, RXLEN; then ACKSEQ"),
  msg(1, 0, "ACKSEQ = SEQ", dashed: true),
), caption: [A transaction. The console only ever stores and loads.])

The next number is always the cartridge’s own `ACKSEQ` plus one, wrapping from 255 to 1. Zero is reserved, and a number equal to the last one does nothing at all, so a stray repeat cannot send a request twice.

#important[Never keep the sequence number in your own RAM. The console can be switched off and on without the cartridge being reset (there is no reset line), and a program that starts counting from 1 again will send a number the cartridge has just seen. It will be ignored, and the old reply will still be in the window. Read `ACKSEQ`, add one.]

#sect[The status page]

#tbl((0.82in, 0.95in, 1fr),
  th[Address], th[Name], th[Meaning],
  [`$0C00`], [ACKSEQ], [The last sequence number answered. Painted last.],
  [`$0C01`], [STATUS], [Bit 0: the link to the FujiNet is up.],
  [`$0C02`], [ERR], [How the transaction went: 0 completed, 1 no link, 2 timed out, 3 bad frame, 4 too big.],
  [`$0C03`], [REPLY_CMD], [`$06` the FujiNet said yes (ACK), `$15` no (NAK), 0 if nothing came back.],
  [`$0C04`–`$0C05`], [RXLEN], [The reply’s length, low byte first; at most 1024.],
  [`$0C06`–`$0C08`], [BOOT_STATE, BOOT_PCT, BOOT_ERR], [A pushed image’s progress (Section 12).],
  [`$0C09`–`$0C0A`], [MAGIC], [`'F'`, `'N'`: a FujiNet cartridge is answering.],
  [`$0C0B`], [PROTO_VER], [1.],
  [`$0C0D`–`$0C11`], [LOAD\_…], [The loader’s handshake (Section 19).],
  [`$0C12`], [MODE], [0 BOOT, 1 LOAD, 2 GAME, 3 APP.],
  [`$0C14`], [MAPPER], [The board layout of the running image.],
  [`$0C16`–`$0C1B`], [BOOT_GOT, BOOT_TOT], [Bytes of a push received, and expected; 24 bits each.],
  [`$0C1C`–`$0C1D`], [INPTCTRL, INPT_LOCK], [The cartridge’s model of INPTCTRL, and 1 if it has been locked.],
  [`$0C1E`], [TV], [0 NTSC, 1 PAL.],
  [`$0C1F`–`$0C24`], [STAGED…], [The pushed image: flags, kind and CRC (Section 19).],
  [`$0C25`], [HANDOVER], [How the last image was started: 1 by the BIOS, 2 by the loader.],
  [`$0C26`], [HSC], [The High Score Cart’s state (Section 13).],
)

The magic bytes are the presence test: a program that finds anything but `'F'`, `'N'` at `$0C09` is not running on a FujiNet cartridge, or not in APP mode, and must not wait for a reply.

#sect[The reply window]

The reply is at `$0800`, `RXLEN` bytes of it, read in place: it stays there until the next transaction. A reply never needs copying unless MARIA has to display it, since MARIA cannot read the mailbox (Section 5), or unless the next transaction would overwrite it before you are done.

#sect[How long to wait]

The cartridge gives each transaction a budget, and reports error 2 if the FujiNet has not answered by then:

#tbl((1fr, auto),
  th[Transaction], th[Cartridge’s budget],
  [Anything not below], [5 seconds],
  [MOUNT_IMAGE (`$F8`), COPY_FILE (`$D8`)], [60 seconds],
  [Network devices `$71`–`$78`: OPEN, CLOSE, STATUS, READ], [90 seconds],
  [If the link is down], [3 more seconds, first],
)

A program’s own wait must be longer, so that the cartridge’s timeout is the one reported. fujinet-lib does this for you; the assembly library waits about 11 seconds unless you raise `FN_TMO`; the 7800basic library waits about 13 unless you raise `fn_tmo`. Each section says when to raise it.

#note[In MAME the whole transaction happens inside the store to `$0D10`: the very next instruction already sees `ACKSEQ` change. On a real cartridge it takes milliseconds, or seconds for a network request. Write the wait loop as if it mattered, and it will.]

#sect[The recipe]

Everything a program does with the FujiNet is this sequence. Here it is in full, with nothing but the stores and loads, asking for the adapter’s configuration. It waits forever; each language’s library (Sections 7, 8 and 9) wraps the same steps with a timeout, and the rest of the handbook uses the libraries.

#trio(
"        lda     #$70            ; device, command, no parameters
        sta     FN_REGSEL+FN_REG_DEVICE
        lda     #$C4
        sta     FN_REGSEL+FN_REG_CMD
        lda     #0
        sta     FN_REGSEL+FN_REG_NPARAM
        sta     FN_REGSEL+FN_REG_DATA_RST
        lda     FN_ACKSEQ       ; the next sequence number
        clc
        adc     #1
        bne     @seq
        lda     #1              ; 0 is reserved
@seq:   sta     FN_REGSEL+FN_REG_SEQ   ; launch
@wait:  cmp     FN_ACKSEQ       ; painted last
        bne     @wait
        lda     FN_ERR          ; did it complete?
        bne     failed
        lda     FN_REPLYCMD     ; did the FujiNet say yes?
        cmp     #$06
        bne     refused         ; the reply is at FN_REPLY",
"uint8_t seq;

fn_regwr(FNR_DEVICE, 0x70);      /* device, command, no parameters */
fn_regwr(FNR_CMD, 0xC4);
fn_regwr(FNR_NPARAM, 0);
fn_regwr(FNR_DATA_RST, 0);
seq = FN_ACKSEQ + 1;             /* the next sequence number */
if (seq == 0)
    seq = 1;                     /* 0 is reserved */
fn_regwr(FNR_SEQ, seq);          /* launch */
while (FN_ACKSEQ != seq)         /* painted last */
    ;
if (FN_ERRCODE != FN_OK)         /* did it complete? */
    failed();
if (FN_REPLYCMD != 0x06)         /* did the FujiNet say yes? */
    refused();                   /* the reply is at FN_REPLY */",
" FN_DEVICE = $70
 FN_CMD = $C4
 FN_NPARAM = 0
 FN_DATA_RST = 0
 fn_seq = FN_ACKSEQ + 1
 if fn_seq = 0 then fn_seq = 1
 FN_SEQ = fn_seq
wait_ack
 if FN_ACKSEQ <> fn_seq then goto wait_ack
 if FN_ERR <> 0 then goto failed
 if FN_REPLYCMD <> $06 then goto refused
 rem the reply is at FN_REPLY")
