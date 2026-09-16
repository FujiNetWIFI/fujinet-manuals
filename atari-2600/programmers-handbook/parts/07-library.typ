#import "../lib.typ": *
= The 6502 Library

The cartridge bring-up ships a client library in three files, and every assembly program in this handbook is built on them verbatim. They are in `listings/common/`, and printed in full in Appendix C.

#tbl((auto, 1fr),
  th[File], th[What it is],
  [`vcs.inc`], [the TIA and RIOT registers, written from the hardware map (the usual `vcs.h` is a dasm companion file and may not be redistributed)],
  [`fujinet.inc`], [the mailbox equates: every cell, register, hotspot, device, command and error code, and the zero-page cells the library uses],
  [`fujilib.inc`], [the transport, the text and path helpers, the swap stub, the input scanner],
  [`fujidisp.inc`], [the display: `DINIT` and `DLOOP`],
  [`netdefs.inc`, `devdefs.inc`], [this handbook's additions: the N: device, the other devices, and the FUJI commands the testrom did not need])

#important[Equates and code go in different files, and the order is not optional. `fujinet.inc` is equates and is included before the `ORG`; `fujilib.inc` and `fujidisp.inc` are code and are included inside it. Including the code half early assembles the whole transport at `$0000`, and every `JSR` to it becomes `20 00 00` --- which assembles cleanly and fails at run time.]

The equates are hand-mirrored from the firmware's `fuji_mailbox.h` and will drift if nothing checks them; the bring-up's `checkdefs.py` does, before anything assembles, and the handbook's build runs it. The bug it exists for: a control page one page off comes up, draws a screen, and never arms the mailbox.

#sect[The transport]

#tbl((auto, 1fr, auto),
  th[Routine], th[What it does], th[In / out],
  [`FNRW`], [register X = A: the arm and the commit. The whole transport is built on it.], [A value, X reg],
  [`FNARM`], [open the decode gate: `$B5` then `$4A`], [---],
  [`FNCHK`], [Z set if a cartridge is answering (`F`, `N` at `$1F09`)], [Z],
  [`FNBEG`], [begin the transaction described by FNDEV, FNCMD and FNNPR; rewinds the TX stream last so parameters can follow at once; sets the timeout], [zero page],
  [`FNTXB`], [append A to the TX stream], [A],
  [`FNPB`], [append a one-byte parameter: the size byte 1, then A], [A (preserved)],
  [`FNPW`], [append a two-byte parameter: 2, then A low and X high], [A, X],
  [`FNGO`], [SEQ = ACKSEQ + 1, commit, spin until ACKSEQ matches or about nine seconds pass; A = 0 if the transaction completed, else the ERR cell or `$FF` for no answer], [A],
  [`FNACK`], [after a completed transaction: A = 0 for ACK, `$EE` for NAK], [A])

`FNGO` spins with nothing else happening, which is right for a program that talks before it turns the display on and wrong for one that wants to keep a picture up. Battleship's `NPGO` is the same launch with a frame drawn per poll, and draws one frame before its first look at the acknowledgement: in emulation the cartridge answers inside the commit, and without that frame a whole transaction and the next one's setup piled into one overscan.

#sect[Text]

#tbl((auto, 1fr, auto),
  th[Routine], th[What it does], th[In],
  [`FNROWA`], [begin composing text row A], [A],
  [`FNENDR`], [render the composed row], [---],
  [`FNRRPL`], [render up to Y bytes of the reply at offset X into row A, stopping at NUL; zero-copy, and the reason most screens in this handbook cost no RAM], [A, X, Y],
  [`FNRSTR`], [render the NUL-terminated string at FNPTRL/H into row A, at most twelve characters], [A, pointer],
  [`FNHEX`], [append A as two hex digits to the row being composed], [A])

`FNRRPL`'s offset is one byte, so it reaches the first 256 bytes of the reply, which is every field of the adapter configuration and every entry of a directory. Battleship reaches player records past 256 with a pointer.

#sect[Payloads and the path buffers]

#tbl((auto, 1fr, auto),
  th[Routine], th[What it does], th[In],
  [`FNPATH`], [append the string at FNPTRL/H to the TX stream, NUL-padded to exactly 256 bytes], [pointer],
  [`FNPBEG`, `FNPCH`, `FNPSTR`, `FNPRPL`, `FNPEND`], [build a 256-byte payload a piece at a time: start, one character, a string, bytes from the reply, and pad to 256], [various],
  [`FNWRST`, `FNWCH`, `FNWPOP`], [the cartridge path buffer: empty it, append A, drop the last component], [A],
  [`FNWTX`, `FNPWD`], [emit the path buffer into the TX stream: padded to 256, or raw with FNPCNT advanced by its length], [---],
  [`FNWSTR`, `FNWRPL`], [append a string, or bytes of the reply, to the path buffer], [pointer / X, Y],
  [`FNEOF`], [Z set if the reply is the `$7F`,`$7F` end-of-directory marker], [Z])

#caution[`OPEN_DIRECTORY` and `SET_DEVICE_FULLPATH` read exactly 256 bytes, and a short payload fails the server's read. Every path payload goes through `FNPATH`, `FNPEND` or `FNWTX`, which pad. And reading past the end of a directory poisons the session: a fujinet-pc SD host returns `..` over and over, and every later `SET_DIRECTORY_POSITION` is refused. Check `FNEOF` after every entry.]

#sect[Boot]

`FNBLK` arms the swap by committing `$B5` to the BOOTLOCK register. `FNSWAP` copies the stub into `$80` and jumps to it; it does not return. Section 11 has the sequence, and the three stores in the stub that are easy to leave out.

#sect[Input]

`INSCAN` folds joystick 0 and the console switches into one active-high byte and returns only what is newly pressed, so a held stick steps once: UP `$01`, DOWN `$02`, LEFT `$04`, RIGHT `$08`, FIRE `$10`, SELECT `$20`, RESET `$40`. It keeps its two cells at `$A8` and `$A9`, above the swap stub's landing ground.

#sect[The display]

`DINIT` sets the TIA up and positions the players; `DLOOP` draws frames forever and calls the client's `APPVBL` once per frame during the vertical blank, with the screen off and the raster nowhere near the text. Input scanning belongs there; so does a transaction, with the caveat that a round trip takes far longer than a frame and the picture will stall for it. A client defines two zero-page cells for the kernel, `PAD3` and `SAVSP`, and an `APPVBL`, which may be a bare `RTS`.

#sect[The dasm twin]

batari Basic assembles through dasm, and so does a good deal of the 2600 world. The same library exists in dasm syntax in `listings/dasm/`, generated from the AS sources by `tools/as2dasm.py` and checked against the committed copy on every build, so that the two can never drift. The translation is mechanical: labels lose their colons, `DB` and `DW` become `.byte` and `.word`, `REPT` becomes `REPEAT`, `LSR A` becomes `LSR`, the low and high byte idioms become `<` and `>`, and the library's zero-page equates are wrapped in `IFNCONST` so that a program can place them on cells of its own choosing before it includes the header --- which is what a batari Basic program has to do, since the library's cells are where batari Basic keeps its kernel. The translated first-contact program assembles to a working client, and was run against the adapter to prove it.
