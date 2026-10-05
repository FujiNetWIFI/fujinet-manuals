#import "../lib.typ": *

= Booting an Image

#lead[A program can load another program: any NES cartridge image the
FujiNet can reach, up to 512K of PRG and 512K of CHR, fetched off the
network into the cartridge's own memory and started as if it had been
plugged in.]

== Four steps

#steps(
  [*MOUNT_HOST* the host the image is on.],
  [*SET_DEVICE_FULLPATH* -- device slot 0, that host, mode 1 (read), and the
   image's path.],
  [*MOUNT_IMAGE* device slot 0. The FujiNet sees from the file's extension
   that it is a cartridge image, and before it answers it pushes the whole
   file down the USB link into a staging store on the cartridge -- 256K of RAM,
   or 1.5 MB of flash for bigger images. Then BOOT_STATE says READY.],
  [*Boot*: store `$B5` to BOOTLOCK, turn interrupts, the PPU and the APU off,
   and jump to the loader ROM at `$5800`. It copies the staged image into the
   SRAMs, sets up its mapper, and starts it through its own reset vector.],
)

#fig(caption: [A network boot. The image crosses the link while MOUNT_IMAGE
is still waiting for its answer.],
  seq(("6502", "RP2354B", "ESP32-S3"),
    msg(0, 2, "MOUNT_HOST, SET_DEVICE_FULLPATH"),
    msg(0, 2, "MOUNT_IMAGE (slot 0, read)"),
    msg(2, 1, "image, 512 bytes at a time"),
    snote(1, [BOOT_STATE 1, BOOT_PCT 0-100, BOOT_GOT / BOOT_TOT]),
    msg(2, 1, "ACK", dashed: true),
    snote(1, [BOOT_STATE 2: ready; then ACKSEQ]),
    msg(0, 1, "STA $5511 = $B5; JMP $5800"),
    snote(1, [loader: 1K slices into PRG and CHR, then JMP (\$FFFC)]),
    w: 440pt))

== In C

#wholefile("listings/c/boot.c", "listings/c/boot.c")

`fuji_mount_disk_image()` is one transaction, and it does not come back until
the image is on the cartridge. `fuji_nes_boot()` does the rest: BOOTLOCK, the
interrupts and the PPU and APU off, and the jump.

#caution[fujinet-lib waits about twelve seconds for any transaction. The
cartridge gives MOUNT_IMAGE sixty. A large image on a slow network can take
longer than the library will wait: the call returns false while the image is
still arriving. For anything bigger than a few dozen kilobytes, start the
mount yourself and watch it, as the assembly version does.]

== In assembly, with progress

`boot.s` launches MOUNT_IMAGE with `fn_launch`, which commits and returns at
once, and then watches BOOT_PCT once a frame -- writing to the PPU only in
vblank, since the screen is on -- until `fn_done` says the answer is in:

#excerpt-at("listings/asm/boot.s: launch and watch", "listings/asm/boot.s",
  "        CALL    FNDEVF, FNCMIMG, 2", to: "bootfail:", size: 6.8pt)

#shots("boot-mid", "boot-done", caption: [`boot.s` loading, and the program it
loaded: `hello` from the SD card. A 40K image crosses the link in a quarter of
a second in emulation.])

It waits sixty-five seconds, so that a real timeout is reported by the
cartridge's ERR rather than by its own loop. CONFIG does the same, and draws
a bar from BOOT_PCT and a byte count from BOOT_GOT and BOOT_TOT.

From C, the same is done by starting the transaction by hand:

#codepanel("Starting MOUNT_IMAGE without waiting, in C",
"fn_regwr(FNR_DATA_RST, 0);
fn_regwr(FNR_DEVICE, 0x70);
fn_regwr(FNR_CMD, 0xF8);                  /* MOUNT_IMAGE */
fn_regwr(FNR_NPARAM, 2);
fn_tx(1); fn_tx(0);                       /* device slot 0 */
fn_tx(1); fn_tx(1);                       /* mode: read */
want = FN_ACKSEQ + 1;
if (want == 0)
  want = 1;
fn_regwr(FNR_SEQ, want);                  /* sent */
while (FN_ACKSEQ != want) {
  waitvsync();
  draw_bar(fuji_nes_boot_percent());      /* 0-100 */
}")

== The command

#cmd("Mount image", dev: "$70", code: "$F8",
  params: [device slot (1), mode (1): 1 read, 2 write.],
  reply: [none -- after the whole image is on the cartridge. NAK for a bad
    slot, a file that will not open, or a push that failed.],
  asm: "        CALL    FNDEVF, FNCMIMG, 2
        lda     #0              ; device slot 0
        jsr     fn_pb
        lda     #1              ; read
        jsr     fn_pb
        jsr     fn_launch       ; then watch",
  c: "if (fuji_mount_disk_image(0, 1)
    && fuji_nes_boot_state()
       == FUJI_NES_BOOT_READY)
  fuji_nes_boot();")[
Starting a mount clears BOOT_STATE, BOOT_PCT, BOOT_ERR and the byte counts,
so whatever an earlier attempt left there cannot be mistaken for this one's
result. A mount that succeeds also turns off "boot CONFIG", so calling
`fuji_set_boot_config(0)` afterwards, as the games do, is harmless but not
needed.]

== Which files are images

The FujiNet decides by the file's extension. `.nes`, `.bin`, `.rom`, `.int`,
`.itv` and `.chf` are cartridge images; anything else mounts as a disk, and
BOOT_STATE never reaches READY.

#note[The `.nes` extension was added to the FujiNet firmware in October 2026.
The fujinet-pc these examples ran against predates it, which is why `boot`
loads `/nesbook/hello.bin` -- the same iNES file, renamed.]

An `.nes` image carries its own iNES header, and that is what the cartridge
reads to choose the mapper. If it names a mapper the cartridge does not
implement, the load fails.

== When it fails

#tbl((auto, auto, 1fr),
  th[BOOT_ERR], th[Name], th[Meaning],
  [1], [TOOBIG], [The image is bigger than the staging store, or than the SRAMs.],
  [2], [TRUNCATED], [The stream ended before the size it declared.],
  [3], [NOMAP], [The iNES header names a mapper this cartridge cannot do.],
  [4], [STOREBUSY], [The staging store was busy.],
)

BOOT_STATE `$80` means failed, and BOOT_ERR says why. A MOUNT_IMAGE that
NAKs leaves BOOT_STATE at 0.

== Inside the loader

You never need to drive the loader yourself -- `fn_boot` and
`fuji_nes_boot()` simply jump to it -- but it is short and instructive. It
lives in the cartridge at `$5800-$5FFF`, served by the RP2354B like the
mailbox, so the copy it performs cannot overwrite it, and nothing has to be
moved into console RAM first.

#steps(
  [It waits two vblanks, then stores to `$55FE` to ask for the load.],
  [The cartridge paints a 1K slice of the image into the reply window and
   then LOAD_SEQ. LOAD_DST says where it goes: 0 for PRG, to `$8000` plus
   LOAD_OFF kilobytes -- the cartridge has moved the PRG bank under that
   window -- or 1 for CHR, through `$2006` and `$2007`.],
  [The loader copies it, about 9.5 cycles a byte, and stores LOAD_SEQ to
   SLICE_ACK, `$5514`.],
  [At LOAD_STATE 2, done, it acks once more and jumps through the new image's
   reset vector at `$FFFC`.],
)

#excerpt-at("listings: loader.s, the copy loop", "listings/common/loader.s",
  "loop:   lda     FN_LSTATE", to: "; ---- PRG", size: 6.8pt)

== Coming back

There is no way back from a booted image except the power switch. When the
console is off, the cartridge sees the CPU's clock stop for a quarter of a
second, switches its SRAMs off, and on the next power-on loads CONFIG again.
Pressing Reset only restarts the image that is loaded.
