#import "../lib.typ": *
= How the Mailbox Works

The mailbox is the cartridge's half of a conversation. The console writes a request into it; the cartridge carries the request over USB to the adapter, waits for the answer, and paints the answer into memory the console can read. Every FujiNet cartridge in the family works this way. What makes the Video Computer System's different is the connector.

#sect[A connector with no write line]

The cartridge edge carries thirteen address lines, eight data lines, +5V and ground. There is no read/write line, no clock, and no chip select beyond A12. A cartridge sees an address and nothing else.

And yet the 6507 does write. During a store it drives the data bus, and the cartridge can see that bus. So the cartridge declares two pages write-only, never drives them, and recovers the stored byte by watching the address settle and keeping the second-to-last sample of the data lines:

```
while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
append(data_prev);
```

This is not new. It is how every PlusROM game talks to its cartridge, and how every Superchip cartridge implements its 128 bytes of RAM. The console side of it is simply a store: `STA $1E00` appends a byte to the request, and the cartridge's bus loop is fast enough --- 250 MHz against an 838-nanosecond bus cycle --- to watch it happen.

#important[A read of a write-only page is bit-identical to a write of it. A stray `LDA $1D10` decodes as a register access carrying whatever the floating bus held. Nothing on the console can tell the cartridge otherwise, so the protocol is shaped to survive it.]

#sect[Arm, then commit]

Because a stray read looks like a write, a register is never written in one store. It takes two:

```
        lda     #value
        sta     FNRSEL+n        ; arm register n; this store's data is ignored
        sta     FNCMT           ; commit: register n = value, and disarm
```

An arm carries no value. A commit with nothing armed is discarded. One stray access therefore changes nothing: it either arms a register that is never committed, or commits a value into nothing. On the Channel F the same pair is a matter of protocol shape; here it is the defence. The library's `FNRW` routine is exactly those two stores, and the whole transport is built on it.

#sect[The registers]

The arm addresses are `$1D00` plus the register number. Only the first `$80` bytes of the control page arm registers; the rest are one-shot operations, which Section 18 lists.

#tbl((auto, auto, 1fr),
  th[Reg], th[Name], th[Meaning],
  [`$00`], [DEVICE], [the FujiBus device id: `$70` for the FUJI device, `$71` for N1:, `$45` for the clock],
  [`$01`], [CMD], [the command byte for that device],
  [`$02`], [NPARAM], [how many parameters the TX stream begins with],
  [`$05`], [DATA_RST], [any value: rewind the TX stream's write pointer],
  [`$06`], [RXSLICE], [which 512-byte slice of the reply the window shows],
  [`$10`], [SEQ], [nonzero and not the current ACKSEQ: launch the transaction],
  [`$11`], [BOOTLOCK], [`$B5`: arm the ROM swap, once an image is staged],
  [`$12`, `$13`], [BOOTSEL], [`$B5` then `$4A`, as consecutive writes: reboot the cartridge's RP2040 into its USB bootloader])

Register numbers `$00` to `$13` are the same on every cartridge in the family, so the firmware's `fujimail.c` compiles for this console byte-identically.

#sect[The TX stream]

Parameters and payload go through the TX page. A store anywhere in `$1E00`--`$1EFF` appends its data byte; the address low byte does not matter, which is what lets `STA $1E00,X` work for any X. The stream has a fixed shape:

#bytefield(([NPARAM ×], 60pt), ([size 1|2|4], 60pt), ([value, LE], 70pt), ([... then the raw payload], 120pt))

Each parameter is a size byte, then that many value bytes little-endian. After the last parameter comes the payload, as raw bytes. The stream holds up to 320 bytes, which is more than any command needs; the two 256-byte path payloads are the largest.

#note[SET_DIRECTORY_POSITION takes one parameter of two bytes, not two parameters of one byte, and getting that wrong produces a NAK with nothing to point at. The size byte is not decoration: it is how the adapter knows the shape.]

#sect[Launching, and the sequence number]

A transaction runs when the SEQ register is committed with a value that is nonzero and different from the cartridge's current ACKSEQ. The value to use is always ACKSEQ + 1, wrapping from 255 to 1; zero is reserved as "never used".

#caution[Derive the next sequence number from the cartridge's own ACKSEQ cell at `$1F00`, never from a counter in RAM. A console RESET restarts the program and re-zeroes its variables but does not reset the cartridge. A program-local counter would restart at 1, collide with a sequence already answered, and every later transaction would be dropped in silence. Every port in this family learned this the hard way.]

While the transaction runs, the cartridge frames the request as a FujiBus packet, sends it over USB to the adapter, and waits up to five seconds for the reply (sixty for MOUNT_IMAGE and COPY_FILE, which take as long as the network does). Then it paints, in this order: the reply into the window, the reply command (`$06` ACK or `$15` NAK), the error code, the reply length, the link status, and last of all ACKSEQ. That single store is the whole interlock: by the time the console can see ACKSEQ match, everything behind it is already in place.

#seq((("CONSOLE", lime), ("CARTRIDGE", cyan), ("ADAPTER", orange)),
  msg(0, 1, "arm+commit DEVICE, CMD, NPARAM, DATA_RST"),
  msg(0, 1, "STA $1E00 x N  (parameters, payload)"),
  msg(0, 1, "arm+commit SEQ = ACKSEQ+1"),
  msg(1, 2, "FujiBus frame over USB CDC (SLIP)"),
  snote(2, "the adapter does the work"),
  msg(2, 1, "reply frame: ACK/NAK + data"),
  snote(1, "paint reply, RXLEN, ERR, STATUS ...", span: 1),
  msg(1, 0, "then ACKSEQ = SEQ, painted LAST", dashed: true),
  msg(0, 1, "LDA $1B00,x  (read the reply in place)"))

The console's side of the wait is a loop comparing `$1F00` with the sequence it committed. In emulation the whole round trip happens inside the commit store, so the first comparison matches; on the cartridge it takes as long as the network does, and a program that wants to keep a picture up draws frames while it waits.

#sect[The status cells]

The cartridge paints these at the bottom of the status page. All of them are plain reads.

#tbl((auto, auto, 1fr),
  th[Cell], th[Name], th[Meaning],
  [`$1F00`], [ACKSEQ], [echoes SEQ when the reply is ready],
  [`$1F01`], [STATUS], [bit 0: the USB link to the adapter is up; bit 1: busy],
  [`$1F02`], [ERR], [the transport's verdict: 0 ok, 1 no link, 2 timeout, 3 bad frame, 4 too big],
  [`$1F03`], [REPLY_CMD], [`$06` if the adapter said ACK, `$15` for NAK],
  [`$1F04`, `$1F05`], [RXLEN], [the reply's length, little-endian],
  [`$1F06`], [BOOT_STATE], [0 idle, 1 transferring, 2 ready, `$80` failed],
  [`$1F07`], [BOOT_PCT], [0--100 while an image is arriving],
  [`$1F08`], [BOOT_ERR], [1 too big, 2 truncated, 3 no mapper, 4 store busy],
  [`$1F09`, `$1F0A`], [MAGIC], [`F`, `N`: a cartridge is answering],
  [`$1F0B`], [PROTO_VER], [2],
  [`$1F0C`], [SLICE_ECHO], [the slice number, painted last after a slice change],
  [`$1F0D`], [TEXTGEN], [the last text row rendered, plus a bit that toggles each time],
  [`$1F0E`], [BANK], [the bank currently served],
  [`$1F0F`], [FLAGS], [bit 1: the claim was honoured],
  [`$1F17`, `$1F18`], [PATHLEN], [how many bytes the active path buffer holds],
  [`$1F19`], [BLITGEN], [bumped after every blit has landed on the planes])

A NAK is not a transport error: ERR stays 0 and REPLY_CMD carries `$15`. The library's `FNACK` turns that into its own code, `$EE`. A reply longer than 1024 bytes is truncated, not refused.

#sect[The reply window and its slices]

The reply lands in `$1B00`--`$1CFF`, 512 bytes at a time. A reply of up to 1024 bytes is kept whole by the cartridge in two slices, and RXSLICE selects which one the window shows; after a slice change, SLICE_ECHO is painted last and a program polls it before trusting the bytes. In practice almost nothing needs the second slice: the largest reply any program in this handbook reads is Battleship's four-player game record, 509 bytes, and the window is 512 so that it never pages at all.

The window is repainted only by a SEQ commit or a slice select. Between those it is stable, and that stability is a resource: a program can stream bytes straight out of the reply window into the TX page while building its next request, or into a text row, or into a path buffer, with no copy through RAM. On a console with 128 bytes of RAM this is not an optimisation. It is the only way a directory browser fits.

#sect[The arming gate]

Nothing on the control page decodes until two stores arrive in order with two particular values: `$B5` to `$1DFC`, then `$4A` to `$1DFD`. A BIOS probing cartridge space at power-on cannot produce that pair, and until it arrives the write-only pages are tri-stated and inert. Every client opens the gate first thing; the fixed tail's cold stub does it too, because the bank select that follows is a control-page operation. Opening a gate that is already open does nothing.

#sect[The one rule that will bite]

#caution[Never use a read-modify-write instruction on the control page or the TX page. `INC`, `DEC`, `ASL`, `LSR`, `ROL` and `ROR` on an absolute address are three bus cycles at that address: a read, a write of the old value, and a write of the new one. The cartridge's "last value before the address changed" has no defined answer inside that burst, and it has no clock pin with which to do better. Only `STA`, `STX` and `STY` may target `$1D00`--`$1EFF`, and the build fails on anything else.]

In batari Basic the same trap is one keystroke away: `FNTX = FNTX + 1` compiles to an `INC` on the TX page. Compute in a variable, then assign.

#sect[Why the scan can be a proof]

The 6507 has no interrupts. MAME's own model of it says so: no NMI, no SO, no SYNC, and nothing on the console is wired to /IRQ. Only `BRK` reaches the vector at `$1FFE`. Every stray access on this console therefore comes from the program's own instruction stream, never from something that happened to fire mid-transaction, which is why the static check in Section 3 can be complete where the ColecoVision's, with a vblank NMI landing in the middle of every transaction, could only be a heuristic.

#sect[The recipe]

Every transaction in this handbook is the same six steps. Here they are once, in both languages, for GET_ADAPTERCONFIG_EXTENDED --- device `$70`, command `$C4`, no parameters --- whose 240-byte reply carries the adapter's SSID, IP address and firmware version.

#pair("        jsr     FNARM           ; open the gate (once)
        lda     #FNDEVF         ; 1. the device...
        sta     FNDEV
        lda     #FNCADPX        ; 2. ...the command...
        sta     FNCMD
        lda     #0              ; 3. ...and the parameter count
        sta     FNNPR
        jsr     FNBEG           ; commit all three, rewind TX
                                ; 4. (parameters and payload: none)
        jsr     FNGO            ; 5. SEQ = ACKSEQ+1, wait; A = 0 if answered
        bne     FAILED
        jsr     FNACK           ; 6. ACK or NAK?
        bne     FAILED
        lda     FNRPLY+0        ; the SSID starts at reply offset 0",
"  FNH_ARM1 = FNAM1 : rem open the gate (once)
  FNH_ARM2 = FNAM2
  FNA_DEV = 0 : rem 1. the device: arm, then commit
  FNCMT = FNDEVF
  FNA_CMD = 0 : rem 2. the command
  FNCMT = FNCADPX
  FNA_NPAR = 0 : rem 3. the parameter count
  FNCMT = 0
  FNA_DRST = 0 : rem rewind the TX stream
  FNCMT = 0
  rem 4. (parameters and payload: none)
  fnseq = FNACKS + 1 : rem 5. launch: SEQ = ACKSEQ + 1, wrapping
  if fnseq = 0 then fnseq = 1
  FNA_SEQ = 0
  FNCMT = fnseq
wait
  drawscreen
  if FNACKS <> fnseq then goto wait
  if FNERR <> 0 then goto fail
  if FNRCMD <> 6 then goto fail : rem 6. ACK or NAK?
  ch = FNRPLY[0] : rem the SSID starts at reply offset 0")

The BASIC version draws a frame per poll, so the picture stays up while the adapter works; the assembly version, as written, spins with the screen blanked, which is what the first-contact program in Section 9 does before it turns the display on. Battleship in Section 19 shows the assembly way of drawing frames while waiting.
