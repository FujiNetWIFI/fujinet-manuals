#import "../lib.typ": *
= The 6502 Library <ch-library>

The assembly programs in this handbook are built on the bring-up’s own client code, copied unchanged from the cartridge’s `testrom/` directory into `listings/common/`. Four files do the work, and three more of the handbook’s own name the commands the bring-up never needed.

#tbl((auto, 1fr),
  th[File], th[What it is],
  [`fujinet.inc`], [The mailbox’s addresses and registers, the 5200’s chip registers, the BIOS’s zero page and vectors, the library’s zero page and error codes. Mirrored by hand from the cartridge’s `fuji_mailbox.h`, and checked against it by the bring-up’s `checkdefs.py`.],
  [`fujilib.s`], [The transport: begin, append, launch and wait, check, hand over.],
  [`fujidisp.s`], [The 40 × 24 text screen (@ch-display).],
  [`a52init.s`], [Start-up: the chips, the vectors, the VBI and the keypad.],
  [`header.inc`], [The claim and the BIOS’s header (@ch-map).],
  [`devdefs.inc`], [The handbook’s: the other devices, every FUJI command by name, and the `FNBEGIN` macro.],
  [`netdefs.inc`], [The handbook’s: the network device’s commands, open modes and status layout.],
  [`book.inc`], [The handbook’s: its programs’ zero page, `PUTS` and `WAITFRAME`.],
)

#sect[The transport]

#tbl((auto, auto, 1fr),
  th[Routine], th[In / out], th[What it does],
  [`fn_chk`], [Z set if present], [Looks for `'F'`, `'N'` at `$B409`.],
  [`fn_beg`], [`FN_DEV`, `FN_CMD`, `FN_NPR`], [Writes the device, command and parameter count, then rewinds the TX stream. Sets `FN_TMO` to 12 seconds.],
  [`fn_pb`], [A], [Appends a one-byte parameter.],
  [`fn_pw`], [A low, X high], [Appends a two-byte parameter.],
  [`fn_txb`], [A], [Appends one byte of payload. Uses Y.],
  [`fn_path`], [`FN_PTR`], [Appends the NUL-terminated string at `FN_PTR`, padded with NULs to exactly 256 bytes, which is what OPEN_DIRECTORY and SET_DEVICE_FULLPATH read.],
  [`fn_go`], [A = result], [Launches the transaction with `ACKSEQ`+1 and waits up to `FN_TMO` seconds. Returns the cartridge’s error (0 is success), or `$FF` if it never answered.],
  [`fn_ack`], [A = result], [After `fn_go` returned 0: 0 if the FujiNet said yes, `$EE` if it said no.],
  [`fn_blk`], [—], [Arms a pushed image (BOOTLOCK).],
  [`fn_boot`], [A = `$FC`], [Arms the pushed image and hands the console to it (@ch-boot). Returns only if the cartridge never armed it.],
  [`fn_config`], [A = `$FC`], [Hands the console back to CONFIG. Returns only if the cartridge never armed it.],
  [`fn_rw`], [X register, A value], [One register write: two reads. The others are built on it.],
  [`fn_frames`, `fn_wait`], [A seconds; C], [A countdown in frames: `fn_frames` starts it, `fn_wait` returns C clear when it has run out.],
)

#warning[`fn_txb` carries its byte to the cartridge in the address of `LDA FN_TXDATA,Y`, so it changes Y. A loop that sends a string must count in X. `tools/snipcheck.py` rejects an example that counts in Y around it, because such a loop assembles cleanly and sends the wrong bytes.]

Every transaction in the handbook’s programs has the same shape:

#ex((path: "listings/asm/clock.s", from: "; ASK cmd, row", to: "        lda     #row"), t-asm)

and every failure goes to one place, through a `go_ack` that each program carries:

#ex((path: "listings/asm/netget.s", from: "; go_ack --", to: "; fail --"), t-asm)

`go_ack` drops its caller’s return address on failure and jumps to the program’s `fail`, so a caller can treat each transaction as one line that either works or does not come back.

#sect[The wait]

`fn_go` is the recipe of @ch-mailbox with a timeout. The timeout is counted in frames, by the frame counter the VBI keeps at `RTCLOKL` (`$02`): `fn_frames` turns seconds into frames (64 a second, near enough), and `fn_wait` counts one off each time the counter moves.

#ex((path: "listings/common/fujilib.s", from: ".proc fn_go", to: "; fn_ack"), t-asm)

Because the count comes from the VBI, the wait is the same whatever the program is doing, and stops if the VBI does: never call `fn_go` with interrupts off. Raise `FN_TMO` after `fn_beg` for a command the cartridge allows longer: 66 for MOUNT_IMAGE and COPY_FILE, 96 for the network device’s OPEN, STATUS, READ and CLOSE.

#sect[The zero page]

#tbl((auto, auto, 1fr),
  th[Address], th[Name], th[What],
  [`$E0`], [`FN_SEQ`], [The sequence number being waited for.],
  [`$E1`–`$E2`], [`FN_CNT`], [Frames left.],
  [`$E3`–`$E5`], [`FN_DEV`, `FN_CMD`, `FN_NPR`], [The transaction `fn_beg` begins.],
  [`$E6`], [`FN_TMO`], [The timeout, in seconds.],
  [`$E7`], [`FN_LAST`], [`RTCLOKL` as `fn_wait` last saw it.],
  [`$E8`–`$E9`], [`FN_PTR`], [A string pointer, for `fn_path` and `disp_str`.],
  [`$EA`–`$ED`], [`DISP_PTR`, `DISP_TMP`], [The text cursor and scratch.],
)

#sect[The screen]

#tbl((auto, auto, 1fr),
  th[Routine], th[In], th[What it does],
  [`disp_init`], [—], [Clears the screen at `$1000`, points ANTIC at it, sets the colours, cursor home. The display stays off.],
  [`disp_on`], [—], [Turns the display on (`SDMCTL` = `$22`).],
  [`disp_at`], [A row, X column], [Moves the cursor.],
  [`disp_putc`], [A], [Prints one ASCII character and advances. Keeps Y.],
  [`disp_str`], [`FN_PTR`], [Prints a NUL-terminated string.],
  [`disp_hex`], [A], [Prints two hex digits.],
  [`disp_dec`], [A], [Prints up to three decimal digits.],
  [`disp_rpl`], [X offset, Y most], [Prints from the reply window at `$B000`+X, up to a NUL or Y characters: a reply field straight onto the screen.],
)

#sect[Start-up]

The header’s `$FF` at `$BFFD` sends the BIOS straight to `start`, with nothing set up. `a52init.s` does what the BIOS would have done, without depending on which of the two BIOS revisions it is:

#ex((path: "listings/common/a52init.s", from: ".proc start", to: ".endproc"), t-asm)

It clears every chip register, the zero page and page 2, fills the vectors with its own handlers, turns the keypad’s scan and interrupt on, and enables the VBI. The VBI is the BIOS’s, register for register: it counts frames, copies the display and colour shadows and the pots, and jumps through `VVBLKD`. The keypad handler is in @ch-pads.

#sect[Building]

`a52.cfg` lays out a 32K program: code from `$4000`, the arena at `$B000` filled with `$FF`, a second ROM area at `$B800`, the claim at `$BFE0` and the header at `$BFE8`; the zero page from `$19`; `BSS` from `$0300`. `listings/asm/build.sh` assembles a program with the three shared files, links it, and checks it with `checkrom.py`:

```
cd listings/asm
./build.sh netget            # build/netget.bin
```

The script finds a program in `listings/asm/` first and in `listings/common/` second, so the bring-up’s own `hello`, `fujitest`, `fujiboot` and `fujibank` build the same way.
