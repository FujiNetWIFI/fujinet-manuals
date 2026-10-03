#import "../lib.typ": *

#part("III", "Software: the cartridge firmware",
  [`fujivcs`, the RP2040 firmware: how one core serves the 6507 bus and the
   other runs the mailbox, how a read is served and a store recovered, the
   window and its protocol, the glyph compositor, boot staging, the mappers,
   and the USB link to the adapter.])

= Two cores <ch-cores>
The RP2040 has two Cortex-M0+ cores, and the firmware gives one of them
to the bus and nothing else. The split is the first design decision in
the cartridge and every other one follows from it. #src[fuji\_cart.h:1-20]

#fig(
  {
    set text(size: 8pt)
    align(center, grid(columns: (auto, 44pt, auto), column-gutter: 0pt, align: horizon,
      nodebox("core1 — vcs_core1_main", sub: "SRAM-resident · interrupts off\nsettle · decode · drive or sample\nbank select · swap · path ops", fill: c-rp, w: 150pt, h: 70pt),
      stack(dir: ttb, spacing: 8pt,
        align(center, text(font: f-head, size: 6.2pt, fill: gray, "ring 1024 × u16")),
        biarrow(w: 44pt, one: true),
        align(center, text(font: f-head, size: 6.2pt, fill: gray, "flags: render, blit")),
        biarrow(w: 44pt, one: true)),
      nodebox("core0 — main", sub: "tud_task() · fuji_mailbox_service()\nfujimail protocol · FujiBus codec\nrender rows · blits · stage images", fill: c-esp, w: 150pt, h: 70pt),
    ))
    v(6pt)
    align(center, text(size: 8pt, fill: slate, [core0 writes replies and status into the window core1 is already serving; nothing crosses back but the painted bytes.]))
  },
  [The two cores. core1 produces events into a single-producer, single-consumer ring and raises two flags; core0 consumes them. Replies need no bus-loop involvement at all: the mailbox is painted into memory core1 serves.],
) <fig-cores>

== core1: the bus, and only the bus

`vcs_core1_main` is compiled with `__not_in_flash_func`, so the loop and
everything it calls is placed in SRAM, and its first act is to disable
interrupts for the life of the core. The build asserts this: `build-cart.sh`
runs `tools/checksram.py` against the ELF and fails if `vcs_core1_main`,
`fuji_cart_serve_staged` or `fuji_cart_poke` is not at a `0x2000xxxx`
address. The reason is the budget of #ref(<ch-timing>): a single XIP cache miss is
most of it, so the loop can never be allowed to fault to flash, and no
interrupt can be allowed to land in a bus cycle. The served image is for
the same reason never in flash either; it lives in two 32K SRAM buffers,
which is why 32K is the largest cartridge the design serves. #v-code
#src[vcs\_cart.c:1-8, 39-47; boards/fujivcs.cmake:11-19; tools/checksram.py]

== core0: everything else

core0's main loop is two calls: `tud_task()`, which services the TinyUSB
device stack, and `fuji_mailbox_service()`, which drains the ring into the
protocol engine and then does the deferred work. It is the only core that
talks to the ESP32-S3, the only one that runs `fujimail.c`, and the only
one that writes glyphs. #src[main.c:57-64; fujinet.c:135-165]

== What crosses between them

#tbl(
  tab((auto, auto, 1fr),
    th[Event], th[How it crosses], th[Why],
    [Register write (arm + commit)], [two ring entries: `REGSEL+n`, then `REGDATA+value`], [Expanded into the pair `fujimail.c` already decodes, so that file stays byte-identical to the sibling ports],
    [TX stream byte], [one ring entry: `DATA+byte`], [One store, one event],
    [Path buffer emit (`PATH_TX`, `PATH_TXRAW`)], [one marker entry], [core0 expands it into up to 256 `DATA` events. Doing that on core1 would cost microseconds against an 838 ns budget],
    [Bank select], [handled inline on core1], [The next fetch may already be from the new bank; it is one pointer assignment],
    [Swap to the staged image], [handled inline on core1], [Same reason (but see Finding 4)],
    [Text row render (`TEND`)], [a flag], [Composing a row writes 36 bytes through a font lookup, far longer than the next access],
    [Blit], [a flag plus the transform code], [Same; single-slot, no queue],
    [Path buffer edits (`PATH_CH`, `PATH_OP`)], [handled inline on core1, in `vcs_write`], [Appending is one byte; see Finding 5 for the operations that are not],
  ),
  [What core1 hands to core0 and what it keeps. #src[vcs\_cart.c:85-130; fuji\_cart.h:8-20]],
) <tbl-cross>

The ring holds 1024 16-bit entries. core1 writes `head`, core0 writes
`tail`, and neither touches the other's index; a full ring drops the event
and latches an `overflow` flag rather than blocking the bus loop. The size
is chosen from the protocol: one transaction is a dozen register writes,
each two entries, plus at most a 320-byte stream, and the console cannot
start another until it sees the acknowledgement, so the ring only ever has
to hold one transaction. #src[fuji\_cart.h:27-48, 70-96]

#finding(5)[
  Three path-buffer operations run inline on core1, inside `vcs_write`,
  between recovering the store and the next settle: `PATH_POP` walks back
  over the buffer to the previous separator, and `PATH_COMMIT` and
  `PATH_SEED` copy up to 256 bytes between the selected buffer and the
  scratch buffer. On a Cortex-M0+ at 250 MHz a 256-byte copy is on the
  order of a few microseconds; the console's next access --- the fetch of
  the instruction after the store, which is in the cartridge --- arrives
  about 838 ns after the store. The emulator model runs the same code
  inside the write handler, instantly, so nothing in Part VI exercises
  the gap. The `TEND` and blit cases already show the fix: a flag, with
  the work and the republished length done by core0.
  #v-design #src[vcs\_cart.h:371-424; vcs\_cart.c:85]
]

= Serving a read <ch-read>
@lst-loop is the bus loop in full. Everything the console ever receives
from the cartridge comes through its last five lines.

#listed(
```c
for (;;) {
    while ((addr = ADDR_IN) != prev)       /* settle: two reads must agree */
        prev = addr;

    if (!(addr & 0x1000u)) {               /* A12 low: not ours ...        */
        if (fuji_mem.map.watch_low) {      /* ... unless UA or FE is mapped */
            data = 0; dprev = 0;
            while (ADDR_IN == addr) { dprev = data; data = (uint8_t)DATA_IN; }
            vcs_watch(&fuji_mem, (uint16_t)addr, dprev);
            prev = 0xFFFFFFFFu;
        }
        continue;
    }

    if (vcs_tristate((uint16_t)addr)) {    /* $1D or $1E: never drive     */
        data = 0; dprev = 0;
        while (ADDR_IN == addr) { dprev = data; data = (uint8_t)DATA_IN; }
        switch (vcs_write(&fuji_mem, (uint16_t)addr, dprev, &ev_a, &ev_b)) {
            /* ... queue, flag, or act inline (Table 10) ... */
        }
        prev = 0xFFFFFFFFu;                /* force a fresh settle        */
        continue;
    }

    DATA_OUT(vcs_read(&fuji_mem, (uint16_t)addr));   /* a page we drive  */
    DATA_DRIVE;
    while (ADDR_IN == addr)
        ;
    DATA_RELEASE;
    prev = 0xFFFFFFFFu;
}
```,
  [core1's loop, with the event switch elided. #src[vcs\_cart.c:49-143]],
) <lst-loop>

For a selected address on a page the cartridge drives, the sequence is:
look the byte up, put it on the data pins, enable the output drivers, spin
until the address changes, disable the drivers. `DATA_OUT` is a single
store to the SIO `gpio_togl` register of the XOR between the current
output word and the new byte masked to the eight data pins, so only those
pins change and nothing else on the port is disturbed; `DATA_DRIVE` and
`DATA_RELEASE` are single stores to `gpio_oe_set` and `gpio_oe_clr`. The
SIO path is used because it is the only one fast enough; the firmware
uses no PIO state machine and no DMA on the bus. #src[vcs\_pins.h:48-60]

Setting `prev` to an impossible value after every served access forces
the settle test to run again from scratch, so that two consecutive
accesses to the *same* address --- a read of a hotspot, say, followed by
the fetch that returns to it --- are not mistaken for one long access.

== The lookup

`vcs_read` is a static inline in a header, and that header is compiled
three times: by core1, by the MAME cartridge device, and by the host tests.
That is deliberate: the decode cannot drift between the thing that is
tested and the thing that runs. For a FujiNet client it is two
comparisons and an index. #src[vcs\_cart.h:199-226]

#listed(
```c
static inline uint8_t vcs_read_ex(const vcs_mem_t *m, uint16_t a, bool commit)
{
    if (!vcs_selected(a))                         return 0xFF;
    if (m->map.kind == VCSMAP_FUJI && vcs_tristate(a))
        return 0xFF;                               /* open bus: not ours to drive */
    if (m->map.kind != VCSMAP_FUJI) {              /* a booted game: its own board */
        int b = vcsmap_serve((vcsmap_t *)&m->map, a, 0xFFu, commit);
        return (b >= 0) ? (uint8_t)b : 0xFFu;
    }
    uint16_t off = vcs_off(a);
    if (off < FN_BANK_SIZE)
        return m->lowbank ? m->lowbank[off] : 0xFFu; /* the banked 2K        */
    return m->win[off];                              /* the fixed half, painted */
}
```,
  [The read decode, shared by core1, the emulator and the host tests. #src[vcs\_cart.h:199-221]],
) <lst-read>

The low 2K comes from `lowbank`, a pointer into the live image; the high
2K comes from `win`, a 4K working copy whose upper half holds the image's
fixed half with the mailbox painted over it. A bank switch is therefore
one pointer assignment, and it runs inline on core1 because the switch has
to be complete before the console's next fetch. The first version of the
firmware copied 2K into the window instead; it passed every test, because
the emulator's device has all the time in the world, and would have served
wrong bytes for microseconds on hardware. Every classic 2600 mapper swaps
a pointer, and so does this one now. #v-code #src[vcs\_cart.h:444-468; README-fujinet.md:221-226]

= Capturing a write with no R/W line <ch-write>
Two pages of the window, `$1D00`--`$1DFF` and `$1E00`--`$1EFF`, are declared
*write-only*. The cartridge never drives them. Not driving them is what
makes the rest possible: when the 6507 stores to one of those pages it
drives the data bus itself, the cartridge's data pins are inputs, and the
bus loop can simply watch.

#listed(
```c
while (ADDR_IN == addr) { dprev = data; data = (uint8_t)DATA_IN; }
/* ... dprev is the recovered byte ... */
```,
  [The recovery loop: park on the stable address, sample the data lines until the address changes, keep the second-to-last sample. The idiom is PlusROM's and the Super Chip's, verbatim. #src[vcs\_cart.c:80-83; vcs\_cart.h:153-173]],
)

#ref(<ch-timing>) explained why the second-to-last sample is the right one: the
6507 holds its write data at least as long as it holds the address, so the
last sample taken while the address was still stable is inside the data's
valid window, and the one before it is safely clear of the bus beginning
to turn over. What the chapter did not say is the consequence that shapes
the whole protocol.

#important[
  A *read* of a write-only page is bit-identical, at the connector, to a
  write of it. The cartridge sees an address on page `$1D`, samples a data
  bus that nobody is driving, and decodes whatever the floating bus held
  as the stored byte. Nothing on the console can tell it otherwise. The
  Channel F cartridge, which can tell a store from a fetch, is spared this
  class of hazard; this one is not, and three defences follow.
  #src[fuji\_mailbox.h:26-36]
]

== Defence one: arm, then commit

A register is never written with one store. The console stores to
`$1D00 + n` to *arm* register n --- the data byte of that store is ignored
--- and then stores the value to `$1DFF` to *commit* it. An arm carries no
value; a commit with nothing armed is discarded; a commit spends the arm.
One stray access to the control page therefore changes nothing: it either
arms a register that is never committed, or commits a value into nothing.
On the Channel F the same pair is protocol shape; here it is the defence,
and the disarm-after-one-use in `fujimail.c` does real work.
#v-host #src[vcs\_cart.h:332-338, 432-439; fuji\_mailbox.h:37-46]

== Defence two: the arming gate

Nothing on the control page decodes at all until two stores arrive in
order carrying two specific values: `$B5` to `$1DFC`, then `$4A` to
`$1DFD`. The precedent is the Atari 7800, whose BIOS probes cartridge
space at power-on and would trip a hotspot-based protocol; PlusCart
carries a gate at `$1FF4` for the same reason. This gate is stronger,
because the pages are always tri-stated: a probe reads the floating bus
and moves on, and the decode stays dead until an ordered pair no probe
produces. Every client opens the gate first; the fixed tail's cold stub
does it too, because bank selection is a control-page operation. The gate
closes again when an image without the claim boots. #v-host
#src[vcs\_cart.h:307-331; fuji\_mailbox.h:620-635]

== Defence three: the one rule the program must keep

The sampling model has an answer for a plain store and for an indexed
store, and no answer for anything else. @tbl-shapes is what the cartridge
sees for each 6507 access shape that can reach a write port.

#tbl(
  tab((auto, 1fr, auto),
    th[Access], th[Bus cycles at the port address], th[Recovered],
    [`STA abs`], [one cycle, the CPU driving data throughout], [the data #v-host],
    [`STA abs,X` with a page-aligned base], [a dummy read of the unindexed address, then the write. With a base low byte of `$00` the index can never carry, so both cycles land on the *same* address and the cartridge sees one long parked access: floating bus, then the driven data], [the data #v-host],
    [`INC`, `DEC`, `ASL`, `LSR`, `ROL`, `ROR` abs or abs,X], [three cycles: a read (floating bus), a write of the old value, a write of the new], [undefined: which value the address change falls after is not knowable without a clock],
    [`STA (zp),Y`, `STA (zp,X)`], [an indirect store performs a read at the target address first], [a stray access carrying floating-bus data, then the store],
  ),
  [What the write sampler sees for each addressing mode. #src[test\_busio.c:260-338; fuji\_mailbox.h:661-669]],
) <tbl-shapes>

Only `STA`, `STX` and `STY` may therefore target `$1D00`--`$1EFF`, and
indirect stores may not appear in a client at all, since a static scan
cannot know what a zero-page pointer holds. `tools/checkrom.py` disassembles
every bank of every client image and fails the build on either (#ref(<ch-ram>)).
This can be a proof rather than a heuristic because the 6507 has no
interrupts: every access comes from the program's own instruction stream.

= The window as served <ch-window>
#fig(memmap((
  (0x1000, 0x17FF, [BANKED CLIENT CODE · 2K], c-code, [one of up to 112 banks of the image; selected by a store to `$1D80` + bank]),
  (0x1800, 0x1AFF, [TEXT PLANES · 768], c-text, [six 128-byte planes, composed by the cartridge, read by the display kernel]),
  (0x1B00, 0x1CFF, [REPLY WINDOW · 512], c-reply, [one 512-byte slice of a reply of up to 1024; slice selected by a register]),
  (0x1D00, 0x1DFF, [CONTROL · write-only], c-ctl, [`$00`--`$7F` arm a register; `$80`--`$FF` one-shot operations; never driven]),
  (0x1E00, 0x1EFF, [TX STREAM · write-only], c-tx, [a store anywhere here appends its data byte; never driven]),
  (0x1F00, 0x1FFF, [STATUS · CLAIM · TAIL · VECTORS], c-stat, [`$1F00`--`$1F19` painted cells; `FUJI` at `$1F10`; the client's fixed tail at `$1F20`; RESET vector at `$1FFC`]),
), scale: 0.03pt, minh: 22pt),
  [The 4K window as a FujiNet client sees it. The low half is banked; the high half is the mailbox in its entirety, and the one region every bank sees at the same address. #src[fuji\_mailbox.h:53-60]],
) <fig-window>

Sixteen pages is not many, and three decisions in the map each buy a page
back.

/ Two of the three control "pages" are not console addresses.: The
  protocol engine, `fujimail.c`, decodes events by page number: it
  switches on `offset >> 8` and needs three *distinct* page numbers for
  register-select, register-data and stream-data. Only one of them,
  `$1D00`, exists on the bus. core1 synthesises the other two ---
  `FN_H_REGDATA` is `$2E00` and `FN_H_DATA` is `$2F00`, well outside the
  window --- when it turns a completed arm-and-commit into the pair of
  events the engine expects, and a TX store into a data event. Two pages
  of a sixteen-page machine are reclaimed by the choice.
  #src[fuji\_mailbox.h:70-77, 215-224; vcs\_cart.c:86-96]

/ The reply is 512, not 256 or 1024.: 1K would be four of the sixteen
  pages. 256 would fit in one, but the largest reply the flagship
  client reads --- a Battleship game record --- is 509 bytes, so 512 is the
  size at which it never pages a slice at all. Two slices keep the
  engine's 1024-byte maximum for everything else. #src[fuji\_mailbox.h:62-69]

/ The claim and the vectors live in the fixed half.: An image carrying
  the four bytes `FUJI` at `$1F10` promises that it is a FujiNet client
  whose mailbox pages are not its own code, and the decode stays live
  after it boots. A game carries no such promise and the mailbox goes dead
  for the session. Because the fixed half is never banked, `$1FFC` is
  reachable from every bank and a console RESET is survivable whatever is
  mapped low. #src[fuji\_mailbox.h:157-168; vcs\_cart.h:481-492]

= The mailbox protocol <ch-mailbox>
== Registers

Arm with a store to `$1D00` + n, commit with a store of the value to
`$1DFF`. The numbering is the family's, unchanged, so that `fujimail.c`
compiles here byte-identically to the ColecoVision and Channel F ports.
#src[fuji\_mailbox.h:637-652]

#tbl(
  tab((auto, auto, 1fr),
    th[Register], th[Name], th[Meaning],
    [`$00`], [DEVICE], [the FujiBus device id: `$70` for the FUJI device, `$71`--`$78` for N1:--N8:, `$45` for the clock],
    [`$01`], [CMD], [the command byte for that device],
    [`$02`], [NPARAM], [how many parameters head the TX stream],
    [`$05`], [DATA_RST], [any value: rewind the TX stream's write pointer],
    [`$06`], [RXSLICE], [which 512-byte slice of the reply the window shows],
    [`$10`], [SEQ], [nonzero and not equal to ACKSEQ: launch the transaction],
    [`$11`], [BOOTLOCK], [`$B5`: arm the ROM swap, honoured only once an image is staged],
    [`$12`, `$13`], [BOOTSEL_1, BOOTSEL_2], [`$B5` then `$4A` as consecutive writes: reboot the RP2040 into its USB bootloader],
  ),
  [The registers.],
) <tbl-regs>

== One-shot operations

The upper half of the control page is operations that take effect on the
store itself, with the data byte as operand and no commit. None of them
disturbs an armed register, so a stray in this half cannot break up a
legitimate pair in the other. #src[vcs\_cart.h:340-442]

#tbl(
  tab((auto, auto, 1fr),
    th[Store to], th[Name], th[Effect],
    [`$1D80` + b], [BANK], [serve bank b at `$1000`, b up to `$6F`; inline on core1],
    [`$1DF0`], [TROW], [begin composing text row = data; cursor to column 0],
    [`$1DF1`], [TCHR], [append the character; saturates at twelve],
    [`$1DF2`], [TEND], [render the row into the planes on core0; TEXTGEN changes when it has landed],
    [`$1DF3`], [PATH_CH], [append the character to the selected path buffer; saturates at 256],
    [`$1DF4`], [PATH_OP], [a path-buffer operation: RST, POP, TX, TXRAW, POPCH, SEL0--SEL3, COMMIT, SEED (@tbl-pathops)],
    [`$1DF5`--`$1DF9`], [BLIT_SL/SH/DL/DH/CNT], [the blit's source offset, destination offset and count],
    [`$1DFA`], [BLIT_GO], [fire the blit with transform = data, on core0; BLITGEN changes when it has landed],
    [`$1DFC`, `$1DFD`], [ARM1, ARM2], [`$B5` then `$4A`: open the decode gate],
    [`$1DFE`], [SWAP], [serve the staged image; inert unless BOOTLOCK has been honoured],
    [`$1DFF`], [COMMIT], [commit the armed register with the data],
  ),
  [The one-shot operations.],
) <tbl-oneshot>

#tbl(
  tab((auto, auto, 1fr),
    th[Value], th[Name], th[Effect],
    [0], [RST], [empty the selected buffer],
    [1], [POP], [drop the last path component, keeping the separator: `/a/b/c/` becomes `/a/b/`; `/` stays `/`],
    [2], [TX], [emit the buffer into the TX stream, NUL-padded to exactly 256 bytes],
    [3], [TXRAW], [emit just its bytes, unpadded (for a URL)],
    [4], [POPCH], [drop one character: a keyboard's backspace],
    [5--8], [SEL0--SEL3], [subsequent operations act on that buffer; 3 is the edit scratch],
    [9], [COMMIT], [selected ← scratch: accept an edit],
    [10], [SEED], [scratch ← selected: begin an edit; cancelling is simply never committing],
  ),
  [The path-buffer operations. Four 256-byte buffers live in the cartridge because the console has 128 bytes of RAM and a path is 256; the length of the selected buffer is republished at `$1F17` on every change. #src[fuji\_mailbox.h:603-618; vcs\_cart.h:363-424]],
) <tbl-pathops>

== The TX stream

Parameters and payload go through page `$1E`. A store anywhere in the
page appends its data byte --- the address low byte is ignored --- which
is what makes `STA $1E00,X` legal for any X. The stream has one shape,
identical to every sibling port's:

#bytefield(([NPARAM ×], 60pt), ([size 1|2|4], 60pt), ([value, LE], 70pt), ([... then the raw payload], 130pt))

Each parameter is a size byte, then that many value bytes little-endian;
after the last parameter comes the payload as raw bytes. The stream holds
320 bytes, more than any command needs; the two 256-byte path payloads
are the largest. #src[fuji\_mailbox.h:654-661; fujimail.c:199-210]

== The status cells

#tbl(
  tab((auto, auto, 1fr),
    th[Cell], th[Name], th[Meaning],
    [`$1F00`], [ACKSEQ], [echoes SEQ when the reply is ready; painted last],
    [`$1F01`], [STATUS], [bit 0: USB link to the adapter is up; bit 1: busy],
    [`$1F02`], [ERR], [transport verdict: 0 ok, 1 no link, 2 timeout, 3 bad frame, 4 too big],
    [`$1F03`], [REPLY_CMD], [`$06` if the adapter answered ACK, `$15` for NAK],
    [`$1F04`--`$1F05`], [RXLEN], [the reply's length, little-endian],
    [`$1F06`], [BOOT_STATE], [0 idle, 1 transferring, 2 ready, `$80` failed],
    [`$1F07`], [BOOT_PCT], [0--100 while an image arrives],
    [`$1F08`], [BOOT_ERR], [1 too big, 2 truncated, 3 no mapper, 4 store busy],
    [`$1F09`--`$1F0A`], [MAGIC], [`F`, `N`: a cartridge is answering],
    [`$1F0B`], [PROTO_VER], [2],
    [`$1F0C`], [SLICE_ECHO], [the slice number, painted last after a slice change],
    [`$1F0D`], [TEXTGEN], [the last text row rendered, plus a bit that toggles each time],
    [`$1F0E`], [BANK], [the bank currently served],
    [`$1F0F`], [FLAGS], [bit 0: gate open; bit 1: the claim was honoured],
    [`$1F10`--`$1F13`], [CLAIM], [`FUJI`, from the image],
    [`$1F14`], [HDR], [bank count, cell height, layout revision, from the image],
    [`$1F17`--`$1F18`], [PATHLEN], [length of the selected path buffer],
    [`$1F19`], [BLITGEN], [incremented after every blit has landed on the planes],
  ),
  [The status page. Everything here is a plain read. `$1F00`--`$1F0C` are painted by `fujimail.c`; `$1F0D` onward is published by the bus-serving layer, deliberately past the protocol engine's paint span so that it never clears them. #src[fuji\_mailbox.h:131-160, 170-195]],
) <tbl-status>

== Launching, and the interlock

A transaction runs when SEQ is committed with a value that is nonzero and
different from the cartridge's current acknowledged sequence. core0's
`run_transaction` unpacks the stream, waits up to 3 s for the USB link if
it is down (the console reaches its first transaction long before the
ESP32-S3 has enumerated, and the service runs once per SEQ, so a
permanent "no link" answer would otherwise be the result), sends the
packet, and waits 5 s for the reply --- 60 s for MOUNT_IMAGE and
COPY_FILE, whose acknowledgements arrive only when the network is done.
Then it paints, in this order: the reply into the window, REPLY_CMD, ERR,
RXLEN, STATUS, the slice echo, and *last of all* ACKSEQ.
#src[fujimail.c:6-8, 189-250]

#listed(
```c
poke(FN_R_REPLY_CMD, reply_cmd);
poke(FN_R_ERR, (uint8_t) st);
poke(FN_R_RXLEN_LO, (uint8_t)(rxlen & 0xFF));
poke(FN_R_RXLEN_HI, (uint8_t)(rxlen >> 8));
poke(FN_R_STATUS, port->link_up() ? FN_R_STATUS_LINK : 0);
rxslice = 0;
publish_slice();
/* Published LAST. This single store is the whole interlock: everything
 * the console reads is already in place before it can see the sequence
 * match. */
poke(FN_R_ACKSEQ, seq);
```,
  [The paint order at the end of a transaction. #src[fujimail.c:237-250]],
)

That single store is the whole interlock between the two sides. There is
no interrupt and no handshake line; the console polls `$1F00`, and by the
time it can see the match, everything behind it is already readable. A
NAK is not a transport error: ERR stays 0 and REPLY_CMD carries `$15`.
A reply longer than 1024 bytes is truncated, not refused. #v-emu

#seq((("CONSOLE", c-code), ("CARTRIDGE", c-text), ("ADAPTER", c-reply)),
  msg(0, 1, "arm+commit DEVICE, CMD, NPARAM, DATA_RST"),
  msg(0, 1, "STA $1E00 x N  (parameters, payload)"),
  msg(0, 1, "arm+commit SEQ = ACKSEQ+1"),
  snote(1, "core1 queues; core0 unpacks, waits for the link", span: 1),
  msg(1, 2, "FujiBus request, SLIP over USB CDC"),
  snote(2, "dispatch to the device; do the work"),
  msg(2, 1, "FujiBus reply: ACK or NAK, plus data"),
  snote(1, "paint reply, REPLY_CMD, ERR, RXLEN, STATUS ...", span: 1),
  msg(1, 0, "then ACKSEQ = SEQ, painted last", dashed: true),
  msg(0, 1, "LDA $1B00,X  (read the reply in place)"))

#caution[
  The next sequence number must come from the cartridge's own ACKSEQ cell
  plus one (wrapping 255 to 1; zero is reserved as "never used"), never
  from a counter in console RAM. A console RESET restarts the program and
  re-zeroes its variables, but it does not reset the cartridge: there is
  no reset line on the connector. A program-local counter would restart
  at 1, collide with a sequence the cartridge has already answered, and
  every later transaction would be dropped in silence. Every port in the
  family has paid for this once; here the RESET-survival test (#ref(<ch-mame>))
  checks it. #v-emu #src[fujilib.inc:100-116]
]

== The reply window and its slices

The reply lands in `$1B00`--`$1CFF`, 512 bytes at a time, and the
cartridge keeps up to 1024 in two slices; RXSLICE selects which the window
shows, and after a slice change SLICE_ECHO is painted last so that a
program can wait on it before trusting the bytes. The window is repainted
*only* by a SEQ commit or a slice select. Between those it is stable, and
that stability is a resource: a program streams bytes straight out of the
reply window into the TX page while building its next request, or into a
text row, or into a path buffer, with no copy through RAM. On a console
with 128 bytes of RAM that is not an optimisation. It is the only way a
directory browser fits. #src[fuji\_mailbox.h:200-207]

= The text composer <ch-text>
The 2600 has no framebuffer and no character generator. The processor
races the beam, and every scanline of the picture is built by hand in the
forty-odd cycles the kernel has before the next one begins. On every
other FujiNet console "draw a string" is a memory write; here it would be
a kernel, and one the console has neither the RAM nor the cycles to feed
with glyphs. So the cartridge draws. It keeps the font, renders ASCII into
bytes already in the exact shape a 48-pixel player kernel wants, and
publishes them in the window. The console streams those bytes into two
TIA registers on a cycle-exact schedule (#ref(<ch-kernel>)), and that is all it
does. #src[fuji\_mailbox.h:86-98]

== Six planes

Text is twelve columns by twenty-one rows. A glyph is three pixels wide
and five tall in a four-by-six cell; twelve cells are the 48 pixels that
two players with three copies each can cover. Each text row is six
scanlines, and each scanline of the 48-pixel block needs six bytes, one
per `GRP` write. The cartridge keeps those six bytes in six separate
planes of 128 bytes, indexed by the *absolute scanline*,
Y = row × 6 + line. #src[fuji\_mailbox.h:99-127]

#tbl(
  tab((auto, auto, auto, 1fr),
    th[Plane], th[Address], th[Kernel write], th[Text columns],
    [0], [`$1800`], [1st GRP0], [0--1],
    [1], [`$1880`], [1st GRP1], [2--3],
    [2], [`$1900`], [2nd GRP0], [4--5],
    [3], [`$1980`], [2nd GRP1], [6--7],
    [4], [`$1A00`], [3rd GRP0], [8--9],
    [5], [`$1A80`], [3rd GRP1], [10--11],
  ),
  [The six text planes.],
) <tbl-planes>

The 128-byte alignment is load-bearing. Because a plane is 128-aligned
and Y is always below 128, the address arithmetic can never carry:
`LDA $1800,Y` is always exactly four cycles, never five. A kernel that
spends an unpredictable number of cycles does not draw, it tears, so the
alignment is the difference between a display and a mess. It also means
the kernel needs no zero-page pointers and no per-row setup: Y simply
counts from 0 to 125 down the whole screen, and the rows are implicit in
the data. Within a byte, bit 7 is the leftmost pixel; the left column of
the pair occupies bits 7--5 with bit 4 as its inter-character gap, the
right column bits 3--1 with bit 0 as its gap.

#bytefield(([7], 22pt), ([6], 22pt), ([5], 22pt), ([4 gap], 34pt), ([3], 22pt), ([2], 22pt), ([1], 22pt), ([0 gap], 34pt))

#listed(
```c
for (g = 0; g < FN_T_PLANES; g++) {
    const uint8_t *l = glyph(2*g     < len ? text[2*g]     : ' ');
    const uint8_t *r = glyph(2*g + 1 < len ? text[2*g + 1] : ' ');
    uint8_t *p = win + (FN_T_PLANE(g) - FN_WINDOW_BASE) + row * FN_T_CELL_H;
    for (s = 0; s < FN_T_CELL_H; s++)
        p[s] = (s < VCS_FONT_INK_H) ? (uint8_t)((l[s] << 5) | (r[s] << 1)) : 0u;
}
```,
  [Composing one text row: for each plane, two glyphs packed into six bytes. The sixth byte of each cell is blank leading. #src[vcs\_render.c:23-46]],
)

== The font

The font is one Python table, `tools/vcsfont.py`, from which the build
generates the C header at configure time: 96 glyphs, `$20`--`$7F`.
Lowercase folds to uppercase and anything outside the table renders as
`?`. At three by five pixels several pairs of characters are identical in
most fonts and three were redrawn here: `0` is rounded against `O`'s
square, `S` curved against `5`'s flat top, `[` half-width against `C`.
That is not a curiosity in a filename browser: `SOAK.BIN` and `50AK.BIN`
were the same picture, to the decoder and to a person. The only remaining
collision is `?` against DEL, which is deliberate. #v-emu
#src[vcs\_render.c:9-21; README-fujinet.md:91-101; CMakeLists.txt:68-90]

#fig(
  grid(columns: 2, column-gutter: 14pt, align: bottom,
    box(stroke: 0.6pt + ink, image("../images/screens/asm-hello.png", width: 2.0in)),
    tv("FUJINET 2600\n\n !\"#$%&'()*+,\n-./012345678\n9:;<=>?@ABCD\nEFGHIJKLMNOP\nQRSTUVWXYZ[\\\n]^_`abcdefgh\nijklmnopqrst\nuvwxyz{|}~\n\n12 COLS X 21\nROWS, 3X5 IN\nA 4X6 CELL", size: 6.4pt, w: 2.0in)),
  [Left: the bring-up's first screen as the MAME model drew it, the whole font baked into the planes of a plain 4K image with no mailbox. Right: the 12 × 21 grid in the cartridge's own font, generated from the same table. Every one of the 756 plane bytes of the left image was decoded from the raster and byte-compared against the renderer. #v-emu],
)

== Composing a row, and the generation cell

A program never touches the planes to write text. It stores the row number
to TROW, the characters to TCHR, and anything to TEND; core1 collects the
characters in a twelve-byte buffer and raises a flag; core0 renders the
row and then publishes TEXTGEN with the row number in its low bits and its
top bit toggled. The publish comes *after* the render, so a program that
begins composing the next row before TEXTGEN changes would hand the render
a buffer already being overwritten --- on hardware. In the emulator the
render runs inside the store, and the cell has already changed by the
time the program looks. #src[fuji\_cart.c:82-94]

== The blit port

Beyond text rows, the cartridge moves and transforms bytes into the planes
on request: six stores --- a 16-bit source offset into the reply window, a
16-bit destination offset into the planes, a count, and a transform code
that fires it --- for a screenful the console has neither the RAM nor the
raster time to build itself. Twenty transforms exist (Appendix A). They
fall into four groups: raw and text copies from the reply; the 10 × 10
game-field renderings that put a Battleship board into text rows; the
*playfield* tables, which compose the six per-register tables the
Battleship board kernel reads (#ref(<ch-examples>)); and per-cell and path-buffer
pokes, which let a list move its cursor or show what has been typed
without recomposing a row. #src[fuji\_mailbox.h:240-470]

#caution[
  A blit is a single-slot request. core1 latches the transform and raises
  one flag; there is no queue, so a second blit fired before core0 has run
  the first overwrites its arguments and the first is lost --- on hardware.
  BLITGEN at `$1F19` is incremented after each blit has landed, and a
  program waits for it to change before the next. In emulation the blit
  runs inside the store and the wait is already satisfied. #src[fuji\_cart.c:96-131]
]

= Boot staging and the swap <ch-boot>
== Power-up

At power-up there is no network and nothing to load a program from, so a
client is compiled into the firmware. `build-cart.sh` assembles it, turns
the binary into a C array with `tools/mkromh.py`, and builds the UF2 around
it; `fuji_config_boot` copies it into image buffer 0 and serves it.
Whether the mailbox comes up is decided the same way it is for any image:
`vcs_set_image` looks for the claim where the fixed half puts it. The
default baked client is `fujidir`, the bring-up's directory browser; CONFIG
builds its own `rom.h` for the same slot. #v-code #src[fujiboot.c; build-cart.sh]

== The push

A client boots a game by three FujiNet commands: SET_DEVICE_FULLPATH
names the file for device slot 0, MOUNT_IMAGE mounts it, and the swap
follows. MOUNT_IMAGE is the one that takes real time, and it is the one
command whose reply carries no data at all: while its acknowledgement is
outstanding, the adapter streams the image back to the cartridge over the
same USB link, addressed to device `$FF` --- the "DBC" device, the bus
controller itself --- as unsolicited NET_OPEN, NET_WRITE and NET_CLOSE
frames that the cartridge acknowledges itself. Stream 0 is the image in
512-byte chunks; stream 1, sent first when it exists, is the `.cfg`
sibling that names the bank-switching scheme (#ref(<ch-mappers>)). #v-emu
#src[fujimail.c:90-185; fujinet.c:50-108; lib/media/rs232/diskTypeROM.cpp]

#seq((("CONSOLE", c-code), ("CARTRIDGE", c-text), ("ADAPTER", c-reply)),
  msg(0, 1, "MOUNT_IMAGE (slot 0, mode)  via SEQ"),
  msg(1, 2, "FujiBus request"),
  msg(2, 1, "DBC NET_OPEN stream 1 (size)  -- the .cfg"),
  msg(2, 1, "DBC NET_WRITE ... NET_CLOSE"),
  msg(2, 1, "DBC NET_OPEN stream 0 (size)  -- the image"),
  snote(1, "gate: whole 2K blocks, <= 32K; BOOT_STATE = 1, BOOT_PCT counts", span: 1),
  msg(2, 1, "DBC NET_WRITE x N (512-byte chunks), each ACKed"),
  msg(2, 1, "DBC NET_CLOSE; stage the buffer; BOOT_STATE = 2"),
  msg(2, 1, "ACK for MOUNT_IMAGE"),
  msg(1, 0, "ACKSEQ painted", dashed: true),
  msg(0, 1, "arm+commit BOOTLOCK = $B5"),
  msg(0, 1, "stub in zero page: STA $1DFE ... JMP ($1FFC)"))

The size gate runs at NET_OPEN rather than at close, so a file that can
never be served is refused before the adapter drags it across the network:
a whole number of 2K blocks, at most 32K. A client is (N+1) × 2K and a
game is whatever its board was, and the two are told apart only once the
bytes have arrived, by the claim. The image is written into whichever of
the two 32K buffers is *not* live, because the client that asked for it
may itself have been booted from the other one and is running out of it.
BOOT_STATE goes 1 while the image arrives, with BOOT_PCT counting, and 2
when it is staged; `$80` with a reason in BOOT_ERR if it failed.
#src[fujinet.c:31-46; fuji\_cart.h:36-44]

== The swap

Two doorbells remain. Committing `$B5` to BOOTLOCK arms the swap, and
only once an image is staged. A store to `$1DFE` then performs it, and it
is inert unless armed. The client copies a short stub into zero-page RAM
and jumps to it, because the swap replaces every byte of the window
including the code that triggered it:

#listed(
```
FNSTB:  lda     #0
        sta     GRP0            ; silence the sprites
        sta     GRP1
        sta     AUDV0           ; *** and the sound, or it screams ***
        sta     AUDV1
        sta     PF0
        sta     PF1
        sta     PF2
        sta     WSYNC           ; land on a line boundary
        sta     SWACNT          ; *** RIOT port A back to inputs ***
        sta     SWBCNT          ; *** and port B ***
        lda     #2
        sta     VBLANK          ; blank across the swap
        sta     VSYNC           ; a clean discontinuity, not a rolling frame
        sta     FNRSEL+FH_SWAP  ; THE SWAP. The next fetch is at $00xx, in
                                ;   RAM with A12 low, so the window may flip
                                ;   between this store and it.
        ldx     #$FF
        txs                     ; a clean stack for the new image
        jmp     ($1FFC)         ; the NEW image's own reset vector, exactly
                                ;   what the 6507 fetches at power-on
FNSTE:
```,
  [The swap stub, run from zero page. Three stores in it are easy to leave out and each breaks a different thing: the audio volumes, or a tone screams until the game's cold start; and the two RIOT direction registers, because almost no game writes them and a client that left the ports as outputs would brick every game booted after it. #src[fujilib.inc:254-276]],
) <lst-stub>

On core1 the swap is `fuji_cart_serve_staged`: flip the live-image index,
then `vcs_set_image` on the new buffer, which clears the 4K working window,
copies the image's last 2K into its upper half, tests for the claim,
resets the gate and the armed state, selects bank 0, and initialises the
mapper. For a game, the claim is absent, so `mailbox` is false, the decode
stays dead for the session, and the image is served by its own board.
The `.cfg` hint, if one arrived, is spent on this image and this one only.
#src[fuji\_cart.c:60-80; vcs\_cart.h:472-523]

#finding(4)[
  The swap runs inline on core1, and it is not cheap: a 4K `memset`, a 2K
  `memcpy` and, for a game, a 1K `memset` of the mapper's RAM. The stub
  gives it `LDX`, `TXS` and the three bytes of `JMP (abs)` --- seven cycles,
  about 6 µs --- before the 6507 reads the new image's reset vector from
  the cartridge. A Cortex-M0+ at 250 MHz moving 7K through memory
  routines is in the same range, and is plausibly over it. The stub's own
  comment covers only the first fetch after the store. The emulator model
  performs the swap instantly, so nothing in Part VI measures it. The fix
  is the one banking already uses: prepare the window on core0 and have
  core1 swap a pointer. #v-design #src[vcs\_cart.c:115-117; vcs\_cart.h:472-479; fujilib.inc:268-274]
]

= The mappers <ch-mappers>
A game that arrives is served by whichever bank-switching scheme it
shipped on, and the cartridge has to behave like that board. `vcsmap.h`
is the set, and like the window decode it is a header of static inlines
compiled by core1, the emulator device and the host tests alike.
#src[vcsmap.h:1-13]

#tbl(
  tab((auto, auto, 1fr),
    th[Scheme], th[Image], th[How it switches],
    [FLAT], [2K or 4K], [never; a 2K image is served mirrored],
    [F8], [8K, 2 banks], [an access to `$1FF8`--`$1FF9`],
    [F6], [16K, 4 banks], [`$1FF6`--`$1FF9`],
    [F4], [32K, 8 banks], [`$1FF4`--`$1FFB`],
    [FA], [12K, 3 banks], [`$1FF8`--`$1FFA`; 256 bytes of RAM written at `$1000`, read at `$1100`],
    [E0], [8K in 1K slices], [`$1FE0`--`$1FF7` select the three low slices; the top slice is fixed to slice 7, which keeps `$1FFC` in place across a RESET],
    [UA], [8K, 2 banks], [`$0200`--`$027F`: *below A12*, where the cartridge is not selected and only watches],
    [FE], [8K, 2 banks], [an access to `$01FE` arms it; the bank comes from bit 5 of the byte on the bus in the *next* access; the first after reset is ignored],
    [CV], [2K + 1K RAM], [never; RAM read at `$1000`, written at `$1400`],
    [Super Chip], [a flag on F8, F6, F4], [128 bytes of RAM read at `$1080`--`$10FF`, written at `$1000`--`$107F`],
  ),
  [The schemes served. Every one of them switches on a *read*, because real hardware cannot tell a read from a write and so every classic board keys on the address. #src[vcsmap.h:39-52, 165-290]],
) <tbl-mappers>

== Side effects after the read

A hotspot access returns the *old* bank's byte. The access that switches
the bank still reads what was there before, and the switch applies to the
next access. MAME's own memory system settled this: it installs a read
bank and a read *tap* over the same range and runs the tap after the read.
The firmware had it inverted until the MAME source decided it, and the
difference is invisible until a game reads its own hotspot for data as
well as for the side effect --- which several do. `vcsmap_serve` therefore
computes the byte first and applies the side effect second, and takes a
`commit` flag so that the emulator's debugger can peek without moving the
bank; core1 always commits. #v-host #src[vcsmap.h:24-32, 213-254; README-fujinet.md:213-220]

== Watching below A12

UA and FE are the two boards that make a cartridge watch the bus when it
is not selected. When either is mapped, `vcsmap_init` sets `watch_low`,
and core1's A12-low branch --- which is otherwise one predicted branch
and gone, on every zero-page and TIA access the game makes --- samples the
cycle the way a write port is sampled and hands it to the mapper. The
emulator device installs read-write taps on `$01FE`--`$01FF` and
`$0200`--`$027F` for the same purpose. #v-emu #src[vcs\_cart.c:57-74; vcs\_cart.h:250-267; emu/fujinet.cpp:205-221]

== Choosing a scheme

The claim decides client versus game. For a game the `.cfg` hint wins
where it exists; otherwise the scheme comes from the size alone --- 2K and
4K FLAT, 8K F8, 12K FA, 16K F6, 32K F4 --- plus MAME's Super Chip
heuristic, which is that the first 256 bytes of the image are all the
same byte, because a Super Chip cartridge leaves its RAM window as a
repeated pattern rather than code. An 8K F8, E0, UA and FE are all 8192
bytes and nothing inside the file tells them apart, which is why the
`.cfg` exists: its content is the scheme's name (`F8`, `F8SC`, `E0`, `UA`,
`FE`, `CV`, ...), case-insensitive, with anything after it ignored.
#v-emu #src[vcsmap.h:295-373; vcs\_cart.h:494-523]

== What is not served, and why

Only schemes MAME implements are here, because a scheme with no reference
cannot be verified against anything; transcribing another emulator's
version and testing it against itself would be theatre. That rules out
F0, EF, DF, BF and SB. ACE and ELF are ARM-code cartridges, DPC and the
Supercharger carry their own coprocessor or BIOS. 3E and 3F need the
cartridge to sample the data bus on an access *below* `$1000` --- doable
with the mailbox's own technique, but it would put the timing-critical
sampling into the serve path of every booted game rather than only into
the mailbox. #src[vcsmap.h:14-23]

#finding(3)[
  The RAM write halves of Super Chip, FA and CV are decoded in
  `vcsmap_write`, which core1 reaches only through `vcs_write`, which it
  calls only for the two mailbox pages. A game's store to `$1000`--`$107F`
  (or FA's `$1000`--`$10FF`, or CV's `$1400`--`$17FF`) takes the
  driven-read path instead: core1 serves a byte onto a bus the 6507 is
  driving, and the write never reaches the RAM. The emulator device has a
  separate write handler and so passes; the PlusCart firmware this port
  descends from samples these ranges exactly as the mailbox does.
  #v-code #src[vcs\_cart.c:76, 136; vcsmap.h:275-290]
]

#finding(2)[
  `vcs_tristate` tests the page and nothing else, and core1 calls it
  before it knows whether the image is a client or a game. For a booted
  game, pages `$1D` and `$1E` of its bank are therefore never driven: the
  game's own code and data there read as open bus. The read decode in
  `vcs_read_ex` has the mapper test, and the host test that checks a game
  is given its own `$1D00` goes through `vcs_read_ex`, which is why both
  it and the emulator pass. Nearly every 4K game has code in those pages.
  #v-code #src[vcs\_cart.h:186-193, 208-209; vcs\_cart.c:76; test\_busio.c:370-375]
]

= The link to the adapter <ch-link>
The cartridge is a USB device. TinyUSB runs on core0, the RP2040
enumerates as a CDC-ACM serial port with vendor id `0xCafe` and a product
id of `0x4000` plus one bit per compiled interface class, and the
ESP32-S3 is the host. Nothing on the cartridge initiates anything;
`fujibus_usb.c` reads and writes the CDC pipe TinyUSB gives it.
#src[usb\_descriptors.c:28-38; fujibus\_usb.c:1-5]

#listed(
```c
static void pump(void)
{
    tud_task();
    busy_wait_us(500);
}
```,
  [Every wait on the link pumps the USB stack with a 500 µs gap. core1's bus loop shares the SRAM fabric with core0, and calling `tud_task()` back to back turns a brief contention burst into continuous contention for the whole wait. On the Intellivision this was a hard failure; here the bus is roomier, but the gap costs nothing against a multi-second budget. #src[fujibus\_usb.c:35-45]],
)

== FujiBus

What crosses the link is FujiBus, the packet protocol every FujiNet
serial transport speaks; the cartridge's encoder is a line-for-line port
of the adapter's `FujiBusPacket.cpp`. A frame is SLIP-encoded: `$C0`
before and after, with `$C0` in the body sent as `$DB $DC` and `$DB` as
`$DB $DD`. Inside is a six-byte header, then descriptor bytes, parameters
and payload. #src[fujibus.c:87-92; lib/bus/rs232/FujiBusPacket.cpp:17-35]

#bytefield(
  ([device\ 1], 1fr), ([command\ 1], 1fr), ([length\ 2 (LE)], 1.5fr),
  ([checksum\ 1], 1fr), ([descr\ 1], 1fr), ([params…], 1.4fr), ([payload…], 1.8fr))

The length counts the whole decoded packet including the header. The
checksum is an 8-bit sum with end-around carry over the whole packet with
the checksum byte zeroed. The descriptor's low three bits say how many
parameters follow and how wide they are --- 1 to 4 one-byte values, one or
two 16-bit values, or one 32-bit value --- and bit 7 says another
descriptor byte follows, so that widths can be mixed. The reply is a full
packet of the same shape whose command byte is ACK (`$06`) or NAK (`$15`).
Appendix D has the tables.

The receive buffer is sized for the largest frame that can arrive, which
is not a mailbox reply but a DBC push chunk: a six-byte header plus 512
bytes is 518 decoded, and SLIP worst-case doubles that plus the two
delimiters, 1088. Undersizing it truncates every ROM push and both ends
see a timeout pointing nowhere near the cause. #src[fujibus\_usb.c:14-20]

== Budgets

#tbl(
  tab((auto, auto, 1fr),
    th[Wait], th[Budget], th[Where],
    [USB link to come up before the first transaction], [3 s], [`fujimail.c:8, 214-217`; the ESP32-S3 boots far slower than the console],
    [A reply], [5 s], [`fujimail.c:6`],
    [A reply to MOUNT_IMAGE or COPY_FILE], [60 s], [`fujimail.c:7, 219-227`; the image is pushed during the wait],
    [A frame write to the pipe], [2 s], [`fujibus_usb.c:48-66`],
    [The console's own timeout in `FNGO`], [≈9 s], [`fujilib.inc:55-56`; deliberately longer than the cartridge's, so a real timeout is reported as the cartridge's error],
  ),
  [Timeouts along the link.],
) <tbl-budgets>

== The bootloader doorbell

Writing `$B5` to register `$12` and then `$4A` to `$13`, as consecutive
register writes, calls the RP2040's ROM `reset_usb_boot`; the cartridge
reboots into its USB bootloader on the ESP32-S3's host port and a new
firmware can be written to it (#ref(<ch-flash>)). There is no acknowledgement
to poll. Two registers with two values, like the arming gate, so that no
stray can do it. #src[fujinet.c:111-114; fuji\_mailbox.h:647-652]
