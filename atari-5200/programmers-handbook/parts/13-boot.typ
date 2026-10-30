#import "../lib.typ": *
= Directories, Mount and Boot <ch-boot>

A FujiNet keeps up to eight *host slots*: places it can find files, such as its own SD card or a TNFS server on the network. This section lists a directory on one of them, and then does what CONFIG does with the file you pick: has the FujiNet push it into the cartridge, and hands the console to it.

#sect[Hosts and directories]

#tbl((auto, auto, 1fr),
  th[Command], th[Code], th[Parameters, payload, reply],
  [MOUNT_HOST], [`$F9`], [The host slot (one byte). Connects to the host.],
  [OPEN_DIRECTORY], [`$F7`], [The host slot; then exactly 256 bytes of payload: the path, a NUL, and optionally a filter pattern after the NUL, padded with NULs.],
  [READ_DIR_ENTRY], [`$F6`], [The longest name wanted, and flags (one byte each). Reply: the next name, or `$7F`,`$7F` when there are no more.],
  [CLOSE_DIRECTORY], [`$F5`], [None.],
  [SET_DIRECTORY_POSITION], [`$E4`], [A position (two bytes): where the next READ_DIR_ENTRY starts, for paging back and forth.],
  [READ_HOST_SLOTS], [`$F4`], [None. Reply: the eight hosts’ names, 32 bytes each.],
)

#caution[Do not ask READ_DIR_ENTRY for names of exactly 31 bytes. At that length the firmware puts icon bytes in front of the name. Every program here asks for 36.]

#shots("asm-dir", "c-dir", caption: [The directory of `SD:/a5200book/`, in assembly and in C. The font has no lower case, so `hello.a52` shows in capitals.])

#sect[In assembly]

`fn_path` streams the path and pads it to 256 bytes; READ_DIR_ENTRY’s reply is drawn straight from the reply window.

#ex((path: "listings/asm/fujidir.s", from: "        ; OPEN_DIRECTORY", to: "        ; CLOSE_DIRECTORY"), t-asm)

#sect[In C]

`fuji_open_directory()` sends 256 bytes from its pointer, so the path lives in a 256-byte buffer:

#ex((path: "listings/c/dir.c", from: "    strcpy(path", to: "    fuji_close_directory"), t-c)

#sect[Mounting and pushing]

To run a file, a program asks the FujiNet to *mount* it on one of its device slots. On the 5200 cartridge, mounting means more: the FujiNet reads the whole file and pushes it, while the MOUNT_IMAGE request is still outstanding, into the cartridge, which keeps it until the program says go.

#tbl((auto, auto, 1fr),
  th[Command], th[Code], th[Parameters],
  [MOUNT_HOST], [`$F9`], [The host slot.],
  [SET_DEVICE_FULLPATH], [`$E2`], [Device slot, host slot, mode (1 for read), one byte each; then 256 bytes of path.],
  [MOUNT_IMAGE], [`$F8`], [Device slot, mode. The cartridge allows 60 seconds.],
)

The FujiNet treats a file as a cartridge image by its extension: `.a52` or `.bin` for the 5200. If a file of the same name ending in `.cfg` sits beside it, it is pushed first, and a `mapper=` line in it tells the cartridge which board to serve the image as. While the push goes on, the status page reports it:

#tbl((auto, auto, 1fr),
  th[Address], th[Name], th[Meaning],
  [`$B406`], [BOOTSTATE], [0 idle, 1 arriving, 2 ready, `$80` failed.],
  [`$B407`], [BOOTPCT], [0–100, for a progress bar.],
  [`$B408`], [BOOTERR], [Why it failed: 1 too big, 2 cut short, 3 no board fits it, 4 the only room that fits it is in use.],
  [`$B416`, `$B419`], [BOOTGOT, BOOTTOT], [Bytes received, and the size (24 bits each, low first). Read each twice and keep a matching pair: the bytes can change between reads.],
  [`$B41D`], [STAGED], [What arrived: bit 0 ready, bit 1 it carries the FujiNet claim, bit 2 it is CONFIG.],
)

#sect[The boards]

A 5200 cartridge is one of four boards, and the cartridge serves each image the way its own board would. It decides which from, in order: a database of known images by checksum; a `.cfg` file’s `mapper=` line; the claim’s kind byte (@ch-map); and the size.

#tbl((auto, auto, 1fr),
  th[Board], th[Size], th[How it is laid out],
  [ROM], [up to 32K], [Straight in the window, repeated to fill it. 16K images are told apart from two-chip ones by tracing their code.],
  [Two chips], [16K], [Each 8K appears twice.],
  [Bounty Bob Strikes Back], [40K], [Two 4K windows that switch on reads near their top, and a fixed 8K.],
  [Super Cart], [64K or 128K], [32K banks, switched by reads of `$BFC0`–`$BFFF` (@ch-banks).],
)

Only a ROM image or a Super Cart can be a FujiNet APP: the other two boards have nowhere the mailbox could live. Anything bigger than 128K is refused.

#sect[Handing over]

The push can finish before MOUNT_IMAGE’s answer comes back, or after it. Wait for BOOTSTATE to read 2 (or `$80`, and then BOOTERR says why), then hand the console over:

#nsteps(
  [Write `$B5` to BOOTLOCK (register `$11`), and wait for ARMED at `$B41C` to read 1.],
  [Quiet the machine as a power-on leaves it: interrupts off, `NMIEN`, `DMACTL`, `GRACTL` and `IRQEN` to 0, wait for the last line of the frame, every chip register and all of RAM to 0.],
  [`JMP $B5F0`. The cartridge serves `JMP ($FFFC)` there; on the read of its last byte it swaps the new image in, and the jump lands in the BIOS’s reset code, which starts the new image as if the console had just been switched on.],
)

`fn_boot` in assembly and `fuji_a5200_boot()` in C do all three. Here is the middle of it:

#ex((path: "listings/common/fujilib.s", from: "armed:  sei", to: "ramlo:"), t-asm)

If the new image carries the claim, it finds the mailbox waiting, with the count started over. If not, it is a GAME: the mailbox is gone, and only a power cycle brings CONFIG back.

#shots("asm-boot", "c-boot", caption: [After `fujiboot` and `boot.c`: the pushed programs, the two `hello`s, running. Each found the mailbox still there.])

#sect[In assembly]

`fujiboot.s` is the bring-up’s, unchanged; the handbook’s build points it at `/a5200book/hello.a52`.

#ex((path: "listings/common/fujiboot.s", from: "; ---- SET_DEVICE_FULLPATH", to: "        lda     #2"), t-asm)
#ex((path: "listings/common/fujiboot.s", from: "; ---- wait for the staged image", to: "; ---- the failure screen"), t-asm)

#sect[In C]

#ex((path: "listings/c/boot.c", from: "    strcpy(path, BOOTPATH);", to: "}"), t-c)

#sect[Back to CONFIG]

A FujiNet APP can go back to CONFIG without a power cycle: write `$C5` to register `$14`, and the cartridge stages CONFIG and arms the swap; then hand over exactly as above. `fn_config` and `fuji_a5200_config()` do it, and the games call it when you quit.

#pair(
"        jsr     fn_config       ; does not come back...
        jmp     failed          ; ...unless the swap was never armed",
"fuji_a5200_config();             /* does not come back... */
failed();                        /* ...unless the swap was never armed */")
