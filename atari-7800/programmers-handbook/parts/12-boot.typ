#import "../lib.typ": *
= Directories, Mount and Boot

#ini[A] FujiNet keeps up to eight *host slots*: places it can find files, such as its own SD card or a TNFS server on the network. This section lists a directory on one of them, and then does what CONFIG does with the file you pick: pushes it into the cartridge and runs it.

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

#caution[Do not ask READ_DIR_ENTRY for names of exactly 31 bytes. At that length the firmware puts icon bytes in front of the name. Every program here asks for 30 or 36.]

#fig(grid(columns: 3, column-gutter: 6pt,
  tvframe("images/screens/asm-fujidir.png", 1.2in),
  tvframe("images/screens/c-dir.png", 1.2in),
  tvframe("images/screens/bas-dir.png", 1.2in)),
  caption: [The directory of `SD:/a7800book/`, three ways.])

#sect[In assembly]

`fn_path` streams the path and pads it to 256 bytes; READ_DIR_ENTRY’s reply is drawn straight from the reply window.

#ex((path: "listings/asm/fujidir.s", from: "        ; OPEN_DIRECTORY", to: "        ; CLOSE_DIRECTORY"), t-asm)

#sect[In C]

`fuji_open_directory()` sends 256 bytes from its pointer, so the path lives in a 256-byte buffer:

#ex((path: "listings/c/dir.c", from: "    strcpy(path", to: "    fuji_close_directory"), t-c)

#sect[In 7800basic]

The path is copied byte by byte from an `alphadata` table, and `fn_pad` makes up the rest of the 256:

#ex((path: "listings/bas/dir.bas", from: " rem OPEN_DIRECTORY", to: " rem CLOSE_DIRECTORY"), t-bas)

#sect[Mounting and booting]

To run a file, a program asks the FujiNet to *mount* it on one of its device slots. On the 7800 cartridge, mounting means more: the FujiNet reads the whole file and pushes it, while the MOUNT_IMAGE request is still outstanding, into the cartridge, which keeps it until the program says go.

#tbl((auto, auto, 1fr),
  th[Command], th[Code], th[Parameters],
  [MOUNT_HOST], [`$F9`], [The host slot.],
  [SET_DEVICE_FULLPATH], [`$E2`], [Device slot, host slot, mode (1 for read), one byte each; then 256 bytes of path.],
  [MOUNT_IMAGE], [`$F8`], [Device slot, mode. The cartridge allows 60 seconds.],
)

Then the cartridge’s status page takes over:

#tbl((auto, auto, 1fr),
  th[Address], th[Name], th[Meaning],
  [`$0C06`], [BOOT_STATE], [0 idle, 1 receiving, 2 ready, `$80` failed.],
  [`$0C07`], [BOOT_PCT], [0–100, for a progress bar.],
  [`$0C08`], [BOOT_ERR], [Why it failed: 1 too big, 2 truncated, 3 no board layout fits it, 4 the only store that fits it is in use.],
  [`$0C16`–`$0C1B`], [BOOT_GOT, BOOT_TOT], [Bytes received, and the size (24 bits each, low first). Read each twice and keep a matching pair: the bytes can change between reads.],
  [`$0C1F`], [STAGED], [What arrived: bit 0 ready, bit 1 it is a FujiNet app, bit 2 this console’s BIOS will accept it, bit 3 it is a High Score Cart ROM.],
)

The push can finish before MOUNT_IMAGE’s answer comes back, or after it. Wait for BOOT_STATE to read 2 (or `$80`, and then BOOT_ERR says why), then:

#steps(
  [Store `$B5` to BOOTLOCK (`$0D11`).],
  [Turn interrupts and MARIA’s DMA off: `SEI`, then `$7F` to `CTRL`.],
  [`JMP $0600`. The loader takes the image in, a kilobyte at a time, and starts it. Nothing comes back.],
)

The cartridge keeps a pushed image in its own RAM (160K) or, if bigger, in its flash (512K), so a 448K image can be pushed into a 7800.

#fig(grid(columns: 2, column-gutter: 8pt,
  tvframe("images/screens/c-boot.png", 1.5in),
  tvframe("images/screens/bas-boot.png", 1.5in)),
  caption: [After `boot.c` and `boot.bas`: the pushed program, the bring-up’s `hello`, running. The BASIC booter left INPTCTRL unlocked (`06 00`), as Section 9 explains.])

#sect[In assembly]

`fujiboot.s` is the bring-up’s, unchanged; the handbook’s build points it at `/a7800book/hello.bin`.

#ex((path: "listings/common/fujiboot.s", from: "; ---- SET_DEVICE_FULLPATH", to: "        lda     #2"), t-asm)
#ex((path: "listings/common/fujiboot.s", from: "; ---- wait for the staged image", to: "; ---- the failure screen"), t-asm)

#sect[In C]

#ex((path: "listings/c/boot.c", from: "    strcpy(path, BOOTPATH);", to: "}"), t-c)

`fuji_a7800_boot()` does the last three steps: BOOTLOCK, interrupts and DMA off, POKEY quiet, the joystick ports back to inputs, and the jump.

#sect[In 7800basic]

#ex((path: "listings/bas/boot.bas", from: " rem the push may finish", to: "failed"), t-bas)

7800basic has no statement for “jump to the loader”, so the last three instructions are inline assembly, between `asm` and `end`.

#sect[How the image is started]

The loader starts an image in one of two ways, and the status page says which (`HANDOVER`, `$0C25`):

- *By the console’s own BIOS* (1): the cartridge maps the BIOS back in and lets it check and start the game exactly as at power-on. It does this only for an image that is not a FujiNet app, that this console’s BIOS is known to accept (the cartridge carries a verdict for every known game, NTSC and PAL), and only while INPTCTRL is still unlocked.
- *Directly* (2): the loader starts it, leaving what the BIOS leaves: X and S at `$16`, decimal and interrupts set, MARIA’s DMA off. A FujiNet app is always started this way.

A game that runs either way does not care. A game that reads something the BIOS leaves behind is better started by the BIOS, which is why a program that boots games should leave INPTCTRL alone.

#sect[Board layouts]

The cartridge serves a pushed image the way its own board would have, and says which layout it chose at `$0C14`:

#tbl((auto, auto, 1fr),
  th[Id], th[Layout], th[How it banks],
  [0], [plain ROM], [Up to 48K, ending at `$FFFF`; `$FF` below it.],
  [1], [ROM + POKEY], [As 0, with a POKEY at `$4000`.],
  [2], [SuperGame], [16K banks: any store to `$8000`–`$BFFF` picks the bank shown there; the last bank is fixed at `$C000`.],
  [3], [SuperGame + POKEY], [As 2, with a POKEY.],
  [4], [SuperGame + RAM], [As 2, with 16K of RAM at `$4000` (8K boards see it twice).],
  [5], [SuperGame, 9 banks], [144K: the bank picked is the value stored plus one.],
  [6], [RAM board], [RAM at `$4000`, address line 8 ignored.],
  [7], [Absolute], [A store to `$8000`: bit 0 or 1 picks the bank shown at `$4000`.],
  [8], [Activision], [A store at `$E000` or above: the address’s low 3 bits pick the bank; its halves appear at `$A000` and `$C000`.],
  [9], [High Score Cart], [The HSC itself (Section 13).],
)

The cartridge chooses in order: its database of every known game by CRC, a `mapper=` line in a `.cfg` file beside the image, the `.a78` header’s type, and the image’s size. A FujiNet app’s claim names its layout with the kind byte (Section 3), which counts unless the database or a `.cfg` file has spoken.
