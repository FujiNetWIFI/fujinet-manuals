#import "../lib.typ": *
= Command Reference: The Cartridge Itself

#ini[S]ome of what a FujiNet program can ask for never leaves the cartridge: its registers, its one-shot operations, the boot block and loader, the POKEY, the High Score Cart. This section is all of it, from the cartridge’s own `fuji_mailbox.h` and the shared `fuji_mailbox_proto.h`.

#sect[Registers]

A store of _V_ to `$0D00`+_n_ sets register _n_. Registers `$00`–`$13` are the protocol’s, shared by every FujiNet cartridge; `$14` and up are the 7800’s.

#tbl((auto, auto, 1fr),
  th[Register], th[Address], th[Meaning],
  [`$00` DEVICE], [`$0D00`], [FujiBus device of the next transaction.],
  [`$01` CMD], [`$0D01`], [Its command.],
  [`$02` NPARAM], [`$0D02`], [How many parameters the TX stream holds.],
  [`$05` DATA_RST], [`$0D05`], [Any value: rewind the TX stream.],
  [`$06` RXSLICE], [`$0D06`], [The reply slice shown; the 7800 has one, so 0.],
  [`$10` SEQ], [`$0D10`], [Non-zero and not the last one: launch.],
  [`$11` BOOTLOCK], [`$0D11`], [`$B5`: arm the staged image for the loader. Ignored until BOOT_STATE says READY.],
  [`$12`, `$13` BOOTSEL], [`$0D12`, `$0D13`], [`$B5` then `$4A`: restart the RP2354B in its USB boot mode, to load new firmware. Two stores, so no single stray write can do it.],
  [`$14` SLICE_ACK], [`$0D14`], [The loader’s: the slice numbered LOAD_SEQ is copied.],
  [`$15` TV], [`$0D15`], [0 NTSC, anything else PAL: a program’s own measurement, for the cartridge to keep.],
  [`$16` HSC], [`$0D16`], [The High Score Cart: 0 off, 1 on, 2 forget the ROM, 3 install the staged image as the ROM.],
)

#sect[One-shot operations]

Stores to `$0D80`–`$0DFF` are not registers; the address is the operation. Four do something, and only the loader should use them:

#tbl((auto, auto, 1fr),
  th[Address], th[Name], th[What it does],
  [`$0DFE`], [SWAP], [Into LOAD with the armed image, or CONFIG if none is armed. The loader’s entry at `$0600` does this.],
  [`$0DFD`], [GO], [Switch to the loaded image now: the loader’s last store, from zero page, before `JMP ($FFFC)`.],
  [`$0DFC`], [CONFIG], [Into LOAD with CONFIG, whatever is armed. The loader’s entry at `$0603`.],
  [`$0DFB`], [GO_BIOS], [Switch to the image when the BIOS is next mapped in: the BIOS hand-over.],
)

A program leaves by jumping to the loader, never by storing to these itself:

#trio(
"        sei                     ; back to CONFIG
        lda     #$7F            ; MARIA's DMA off
        sta     CTRL
        jmp     FN_LOADER_CONFIG",
"fuji_a7800_config();    /* back to CONFIG; does not return */",
" rem back to CONFIG
 asm
   sei
   lda #$7F
   sta CTRL
   jmp $0603
end")

#sect[The status page]

Everything the cartridge paints, `$0C00`–`$0CFB`. Section 4 introduced the first eleven.

#tbl((auto, auto, 1fr),
  th[Address], th[Name], th[Meaning],
  [`$0C00`], [ACKSEQ], [The last sequence number answered. Painted last.],
  [`$0C01`], [STATUS], [Bit 0: the link to the FujiNet is up.],
  [`$0C02`], [ERR], [0 OK, 1 no link, 2 timed out, 3 bad frame, 4 too big.],
  [`$0C03`], [REPLY_CMD], [`$06` ACK, `$15` NAK.],
  [`$0C04`–`$0C05`], [RXLEN], [The reply’s length.],
  [`$0C06`], [BOOT_STATE], [0 idle, 1 receiving, 2 ready, `$80` failed.],
  [`$0C07`], [BOOT_PCT], [0–100.],
  [`$0C08`], [BOOT_ERR], [1 too big, 2 truncated, 3 no layout fits, 4 store busy.],
  [`$0C09`–`$0C0A`], [MAGIC], [`'F'`, `'N'`.],
  [`$0C0B`], [PROTO_VER], [1.],
  [`$0C0C`], [SLICE_ECHO], [The reply slice shown.],
  [`$0C0D`], [LOAD_STATE], [0 idle, 1 a slice is waiting, 2 all loaded.],
  [`$0C0E`], [LOAD_DST], [High byte of where this slice goes.],
  [`$0C0F`], [LOAD_N], [Slices in this load, divided by 4.],
  [`$0C10`], [LOAD_SEQ], [Counts slices, 1–255.],
  [`$0C11`], [LOAD_PCT], [0–100 across the whole load.],
  [`$0C12`], [MODE], [0 BOOT, 1 LOAD, 2 GAME, 3 APP.],
  [`$0C14`], [MAPPER], [The running image’s board layout (Section 12).],
  [`$0C15`], [LINK], [1 once the link to the FujiNet has been seen.],
  [`$0C16`–`$0C18`], [BOOT_GOT], [Bytes of a push received.],
  [`$0C19`–`$0C1B`], [BOOT_TOT], [Bytes in the push.],
  [`$0C1C`], [INPTCTRL], [The cartridge’s model of INPTCTRL.],
  [`$0C1D`], [INPT_LOCK], [1 once something has locked it. Only a power cycle clears it.],
  [`$0C1E`], [TV], [0 NTSC, 1 PAL.],
  [`$0C1F`], [STAGED], [The pushed image: bit 0 ready, bit 1 a FujiNet app, bit 2 this console’s BIOS accepts it, bit 3 an HSC ROM.],
  [`$0C20`], [STAGED_KIND], [Its board layout.],
  [`$0C21`–`$0C24`], [STAGED_CRC], [Its CRC-32, low byte first.],
  [`$0C25`], [HANDOVER], [0 none yet, 1 by the BIOS, 2 by the loader.],
  [`$0C26`], [HSC], [Bit 0 ROM installed, bit 1 on, bit 2 last save reached the SD card, bit 3 scores unsaved.],
  [`$0C27`], [DIAG_RMW], [How many read-modify-write dummy writes the cartridge has thrown away. Should be 0.],
)

#sect[Power-on and the boot block]

At power-on the cartridge serves a 4K block at `$F000`–`$FFFF`, signed so the console’s BIOS will start it. The block checks for `'F'`, `'N'` at `$0C09` and jumps to the loader at `$0600`; if the magic is missing — the console cannot see the cartridge’s pages below `$1000` — it turns the screen red instead of crashing. The block is only ever served in BOOT mode.

#sect[The loader]

The loader is 512 bytes of code the cartridge serves at `$0600`. Its two entries are `JMP`s, and neither returns:

- `$0600`: load the armed image, or CONFIG if nothing is armed, and start it.
- `$0603`: load CONFIG and start it.

It turns MARIA off, sets its own stack, and stores to SWAP or CONFIG. Then, for every 1K slice the cartridge offers, it copies the reply window to the page LOAD_DST names, in the 8K window at `$4000` the cartridge points at the right part of its RAM, and acknowledges with LOAD_SEQ into SLICE_ACK. When LOAD_STATE reads 2 it starts the image, by the BIOS or directly (Section 12), from a six-byte trampoline in zero page, so the arena can vanish beneath it. If the cartridge does not answer its first store within about two seconds, it turns the background yellow and keeps waiting: the console’s stores below `$1000` are not reaching the cartridge.

#sect[The push]

During MOUNT_IMAGE the FujiNet sends the image to the cartridge on device `$FF` as an OPEN (the stream — 0 the image, 1 a `.cfg` file whose `mapper=` line overrides the layout — and the size), WRITEs, and a CLOSE; a CLOSE carrying `$01` abandons it. The cartridge keeps the image in RAM (160K) or flash (512K), refuses one bigger than 448K, and reports through BOOT_STATE. A program never sends these; it only watches.

#sect[The POKEY]

Every FujiNet app may play sound through a POKEY the cartridge serves at `$0450`–`$045F`, the address 7800 sound cartridges have always used. Its registers are the usual ones; the cartridge synthesises the sound and sends it to the console on the cartridge edge’s audio line. Two differences from the chip: of the registers that read back, only RANDOM (`$045A`) is live (the rest read `$FF`), and it never raises an interrupt.

#trio(
"POKEY   = $0450
        lda     #0              ; SKCTL: reset, then run
        sta     POKEY+$0F
        lda     #3
        sta     POKEY+$0F
        lda     #0
        sta     POKEY+$08       ; AUDCTL: 64 kHz clock
        lda     #$50
        sta     POKEY+$00       ; AUDF1: the pitch
        lda     #$A8
        sta     POKEY+$01       ; AUDC1: pure tone, volume 8",
"#define POKEY ((volatile uint8_t *)0x0450)

POKEY[0x0F] = 0;                 /* SKCTL: reset, then run */
POKEY[0x0F] = 3;
POKEY[0x08] = 0;                 /* AUDCTL: 64 kHz clock */
POKEY[0x00] = 0x50;              /* AUDF1: the pitch */
POKEY[0x01] = 0xA8;              /* AUDC1: pure tone, volume 8 */",
" rem AUDF1 and AUDC1 are already the TIA's names
 dim PKSKCTL = $045F
 dim PKAUDCTL = $0458
 dim PKAUDF1 = $0450
 dim PKAUDC1 = $0451
 PKSKCTL = 0
 PKSKCTL = 3
 PKAUDCTL = 0
 PKAUDF1 = $50
 PKAUDC1 = $A8")

7800basic’s own POKEY sound engine works too, with `set pokeysupport $450`; its TIA statements must not be used by a program that leaves INPTCTRL unlocked (Section 9).

#sect[The High Score Cart]

Section 13 describes it; its controls are the HSC register above and the HSC byte of the status page. In C, `fuji_a7800_hsc()` and `fuji_a7800_hsc_op()`.
