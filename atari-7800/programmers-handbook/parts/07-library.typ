#import "../lib.typ": *
= The 6502 Library

#ini[T]he assembly programs in this handbook are built on the bring-up’s own client code, copied unchanged from the cartridge’s `testrom/` directory into `listings/common/`. Four files do the work, and two more of the handbook’s own name the commands the bring-up never needed.

#tbl((auto, 1fr),
  th[File], th[What it is],
  [`fujinet.inc`], [The mailbox’s addresses and registers, the 7800’s hardware registers, the library’s zero page and error codes. Mirrored by hand from the cartridge’s `fuji_mailbox.h`.],
  [`fujilib.s`], [The transport: begin, append, launch and wait, check.],
  [`fujidisp.s`], [The 40 × 24 text screen (Section 5).],
  [`a78init.s`], [Reset: the stack, cleared memory, the claim, the vectors.],
  [`devdefs.inc`], [The handbook’s: the other devices, and every FUJI command by name.],
  [`netdefs.inc`], [The handbook’s: the network device’s commands, open modes and status layout.],
)

#sect[The transport]

#tbl((auto, auto, 1fr),
  th[Routine], th[In / out], th[What it does],
  [`fn_chk`], [Z set if present], [Looks for `'F'`, `'N'` at `$0C09`.],
  [`fn_beg`], [`FN_DEV`, `FN_CMD`, `FN_NPR`], [Writes the device, command and parameter count, then rewinds the TX stream. Sets `FN_TMO` to 16, about 11 seconds.],
  [`fn_pb`], [A], [Appends a one-byte parameter.],
  [`fn_pw`], [A low, X high], [Appends a two-byte parameter.],
  [`fn_txb`], [A], [Appends one byte: payload.],
  [`fn_path`], [`FN_PTR`], [Appends the NUL-terminated string at `FN_PTR`, padded with NULs to exactly 256 bytes, which is what OPEN_DIRECTORY and SET_DEVICE_FULLPATH read.],
  [`fn_go`], [A = result], [Launches the transaction with `ACKSEQ`+1 and waits up to `FN_TMO` × 0.7 seconds. Returns the cartridge’s error (0 is success), or `$FF` if it never answered.],
  [`fn_ack`], [A = result], [After `fn_go` returned 0: 0 if the FujiNet said yes, `$EE` if it said no.],
  [`fn_blk`], [—], [Arms a pushed image for the loader (BOOTLOCK).],
  [`fn_boot`], [—], [Interrupts and DMA off, then into the loader. Does not return.],
  [`fn_rw`], [X register, A value], [One register write. The others are built on it.],
)

Every transaction in the handbook’s programs has the same shape:

#ex((path: "listings/asm/clock.s", from: "; ASK cmd, row", to: "        lda     #row"), t-asm)

and every failure goes to one place, through a `go_ack` that each program carries:

#ex((path: "listings/asm/netget.s", from: "; go_ack --", to: "; fail --"), t-asm)

`go_ack` drops its caller’s return address on failure and jumps to the program’s `fail`, so a caller can treat each transaction as one line that either works or does not come back.

#sect[The wait]

`fn_go` is the recipe of Section 4 with a timeout: three nested loops of about 0.7 seconds each pass, counted in `FN_CNT`.

#ex((path: "listings/common/fujilib.s", from: ".proc fn_go", to: "; fn_ack"), t-asm)

The loops are counted, not timed, and MARIA’s DMA steals cycles from the 6502 while the display is on, so the real wait is longer than the count says. That errs the right way. Raise `FN_TMO` after `fn_beg` for a command the cartridge allows more time: 96 (about a minute) for MOUNT_IMAGE, 130 or more for the network device’s OPEN, STATUS, READ and CLOSE.

#sect[The zero page]

#tbl((auto, auto, 1fr),
  th[Address], th[Name], th[What],
  [`$E0`], [`FN_SEQ`], [The sequence number being waited for.],
  [`$E1`], [`FN_CNT`], [Timeout passes left.],
  [`$E2`–`$E4`], [`FN_DEV`, `FN_CMD`, `FN_NPR`], [The transaction `fn_beg` begins.],
  [`$E5`], [`FN_TMO`], [The timeout, in about 0.7-second passes.],
  [`$E6`–`$E7`], [`FN_PTR`], [A string pointer, for `fn_path` and `disp_str`.],
  [`$E8`–`$EB`], [`DISP_PTR`, `DISP_TMP`], [The text cursor and scratch.],
)

The linker gives the program’s own `ZEROPAGE` segment `$40`–`$DF`.

#sect[Start-up]

`a78init.s` is where the console arrives from the loader. It never stores below `$40`:

#ex((path: "listings/common/a78init.s", from: "reset:  sei", to: "irq:    rti"), t-asm)

Then the claim and the vectors: the claim with the RAM flag set (and, for a banked program, kind 5), the cartridge flags `$FF`, `$87` at `$FFF8`, and the NMI, reset and IRQ vectors. Every program supplies `main` and `nmi`; an `nmi` that is only `RTI` is enough while nothing turns display-list interrupts on.

#sect[Building]

`a78.cfg` lays out a 32K program: code from `$8000`, the claim at `$FF70`, the signature area left empty, the vectors at `$FFF8`; the zero page from `$40`; `BSS` in the cartridge’s RAM at `$4000`. `listings/asm/build.sh` assembles a program with the three shared files, links it, checks it with `checkrom.py`, and writes the `.a78`:

```
cd listings/asm
./build.sh netget            # build/netget.bin and build/netget.a78
```

The script finds a program in `listings/asm/` first and in `listings/common/` second, so the bring-up’s own `hello`, `fujitest`, `fujiboot` and `fujibank` build the same way.
