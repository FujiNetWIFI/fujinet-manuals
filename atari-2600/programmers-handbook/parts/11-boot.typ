#import "../lib.typ": *
= Directories, Mount and Boot

The FujiNet's other reason to exist: a cartridge that can be any cartridge. The adapter mounts hosts --- an SD card, a TNFS server across the room or across the world --- lists their directories, and streams an image to the cartridge, which stages it and, on the program's signal, becomes it.

#sect[Hosts and directories]

A host slot is one of eight configured hosts; `READ_HOST_SLOTS` answers all eight names, 32 bytes each, and `MOUNT_HOST` with a slot number connects one. Host slot 0 is the SD card on a standard `fujinet-pc`. Then:

#tbl((auto, auto, 1fr),
  th[Command], th[Params], th[Payload and reply],
  [OPEN_DIRECTORY `$F7`], [host slot], [256 bytes: the path, a NUL, an optional filter such as `*.BIN`, the rest NUL],
  [READ_DIR_ENTRY `$F6`], [maxlen, flags], [reply: one entry, NUL-terminated; a trailing `/` marks a directory; two `$7F` bytes mean the end],
  [SET_DIRECTORY_POSITION `$E4`], [one two-byte index], [seek; `GET_DIRECTORY_POSITION` `$E5` tells],
  [CLOSE_DIRECTORY `$F5`], [---], [---])

#caution[Ask for a `maxlen` of 30, not 31: at exactly 31 the firmware prepends icon bytes to the name. And stop at the two `$7F` bytes: past the end a `fujinet-pc` SD host answers `..` over and over, and every later seek is refused for the rest of the session.]

`fujidir.asm` is the bring-up's browser: it mounts host 0, opens `/`, reads an entry per row into the screen, and moves a cursor with the joystick. No name is ever held in RAM. The cursor is an index; moving it re-reads the listing --- instant in emulation, about a second a step on hardware, which is why CONFIG caches a page in the cartridge instead.

#excerpt-at("fujidir.asm: OPEN_DIRECTORY, and the 256-byte payload", "listings/asm/fujidir.asm", "ODIR:   lda", to: "; ---")

#excerpt-at("fujidir.asm: an entry per row", "listings/asm/fujidir.asm", "DRLOOP: stx", to: "DREND:")

#shot("asm-dir", caption: [`fujidir.asm` listing the SD card. The `>` is the cursor; there is no inverse video.])

`dir.bas` is the same browser in BASIC, and it keeps its working directory in the cartridge: path buffer 0 is set to `/` once, and the cartridge emits it, padded, into every OPEN_DIRECTORY with one store:

#excerpt-at("dir.bas: the path buffer, and the listing", "listings/bas/dir.bas", " rem the working directory", to: " FNH_TROW = 9")

#excerpt-at("dir.bas: OPEN_DIRECTORY and READ_DIR_ENTRY", "listings/bas/dir.bas", "draw", to: "show")

#shot("bas-dir", caption: [`dir.bas`. Twelve rows of listing under a one-line playfield, with the score kernel removed to pay for them.])

#sect[Mounting and booting]

Booting is three commands and a swap. `SET_DEVICE_FULLPATH` names the file for a device slot --- three one-byte parameters, device slot, host slot and mode, then the path as exactly 256 bytes. `MOUNT_IMAGE` mounts it --- device slot and mode --- and this is the command that takes real time: while its reply is outstanding, the adapter streams the image back to the cartridge over the same USB link, addressed to a device of its own (`$FF`, the "DBC" device) in NET_OPEN, NET_WRITE and NET_CLOSE frames the cartridge acknowledges itself, and the cartridge stages it in a second buffer. If a `.cfg` file with the image's name sits beside it, that arrives first and names the bank-switching scheme.

The program watches two cells. BOOT_STATE at `$1F06` goes 1 while the image is arriving, 2 when it is staged, `$80` if it failed, with a reason in BOOT_ERR; BOOT_PCT at `$1F07` counts 0 to 100 for a progress bar. Then:

#steps(
  [Commit `$B5` to the BOOTLOCK register (`$11`). This arms the swap, and only once an image is staged.],
  [Copy the swap stub into zero-page RAM and jump to it. The swap replaces every byte of the window, including the code that triggered it.],
  [The stub silences the sprites, the sound and the playfield; sets the RIOT ports back to inputs; blanks the screen; stores to `$1DFE`. The cartridge flips the window to the staged image between that store and the next fetch, which is safe because the next fetch is in RAM.],
  [The stub sets the stack pointer and jumps through `($1FFC)`: the new image's own reset vector, exactly what the 6507 fetches at power-on.])

#caution[Three stores in the stub are easy to leave out and each breaks a different thing: `AUDV0` and `AUDV1`, or a tone screams until the booted game's cold start; and `SWACNT` and `SWBCNT` back to zero, because almost no game writes them and a client that left the RIOT ports as outputs would brick every game booted after it. The library's `FNSWAP` has all three.]

#excerpt-at("fujiboot.asm: MOUNT_IMAGE, the wait, and the swap", "listings/asm/fujiboot.asm", "MIMG:   lda", to: "; ---- the failure screen")

#excerpt-at("fujilib.inc: the swap stub", "listings/common/fujilib.inc", "FNSWAP: ldx", to: "; -----")

In BASIC the stub is an `asm` block, and the wait is a loop that draws frames:

#excerpt-at("boot.bas: the wait and the swap", "listings/bas/boot.bas", " rem wait for the staged image", to: "fail")

#shot("bas-boot", w: 1.6in, caption: [`boot.bas`, a frame before the swap.])

A booted image with no claim at `$1F10` is a game, and the mailbox goes dead for it; the harness that verified these boots waits for the claim to vanish, then compares every one of the 4096 served bytes with the file. The SD's `hello.bin` is a 2K image, served mirrored, and the compare allows for that.

#sect[The mappers]

A game that arrives is served by its own bank-switching scheme. The cartridge implements the nine that MAME implements --- a scheme with no reference could not be verified against anything --- and works out which from the image's size, the Superchip signature, and the `.cfg` sibling if there is one.

#tbl((auto, auto, 1fr),
  th[Scheme], th[Image], th[How it switches],
  [FLAT], [2K or 4K], [never; a 2K image is mirrored],
  [F8], [8K], [reads of `$1FF8`--`$1FF9`],
  [F6], [16K], [`$1FF6`--`$1FF9`],
  [F4], [32K], [`$1FF4`--`$1FFB`],
  [FA], [12K], [`$1FF8`--`$1FFA`, plus 256 bytes of RAM],
  [E0], [8K in 1K slices], [`$1FE0`--`$1FF7`, the top slice fixed],
  [UA], [8K], [`$0200`--`$027F`: below A12, where the cartridge is not selected and only watches],
  [FE], [8K], [`$01FE` arms; the bank comes from D5 of the next access],
  [CV], [2K + 1K RAM], [never; the RAM is read low and written high])

An 8K F8, E0, UA and FE are all 8192 bytes and nothing inside the file tells them apart; the `.cfg` is how the adapter says which. Its content is the scheme's name --- `F8SC`, `E0`, `UA` --- and it is spent on the image it came with, so that a hint left standing is never applied to the next one.

#note[A bank-switch hotspot returns the *old* bank's byte. The access that switches still reads what was there before, and the switch applies to the next fetch. MAME's own memory system settled it, the ColecoVision found the same thing, and it is invisible until a game reads its own hotspot for data as well as for the side effect --- which several do.]
