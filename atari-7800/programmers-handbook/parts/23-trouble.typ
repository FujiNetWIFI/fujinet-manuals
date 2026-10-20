#import "../lib.typ": *
= Troubleshooting Checklist

The following list is supplied to help you troubleshoot any possible problems in getting a program to talk to the FujiNet. Always rebuild, and run the program on the bench, before checking anything else.

#sect[Building]

#symrem(
  ([`checkrom: … a store to $01 rewrites INPTCTRL`.],
   ([The program stores to the TIA: its sound registers, its `WSYNC`, or INPTCTRL itself. Use the cartridge’s POKEY at `$0450` and MARIA’s `WSYNC` at `$24`, and leave INPTCTRL alone (Section 3).],)),
  ([A C program fails to link once it calls `clock()`, `cputs()` or another conio call.],
   [Those drag in cc65’s own start-up code, which collides with fujinet-lib’s. Use the tile engine for text and MARIA’s frame count for time.]),
  ([`romstamp: image is 65536 bytes: not whole KiB of at most 48K`.],
   [The program is banked. fujinet-lib’s checker takes 48K at most; check a banked image with `tools/checkbanks.py` (Section 14).]),
  ([dasm stops with `EQU: Value mismatch` on a 7800basic program.],
   ([A variable has a one-letter name, which is one of 7800basic’s own (`a`–`z`).],
    [A `dim` reuses a name 7800basic already has: `AUDF1` and `AUDC1` are the TIA’s. Prefix the POKEY’s names.])),
  ([`basfix: … no room for the claim at $FF70`.],
   [7800basic’s runtime has grown past `$FF6F`, into the ten bytes the claim needs. Move code into banks, or out of the last 4K.]),
  ([`basfix: … writes the old value first`.],
   [A read-modify-write on the mailbox: arithmetic on a mailbox name in BASIC, or `INC`, `DEC` or a shift on `$0D00`–`$0FFF` in assembly.]),
)

#sect[The mailbox]

#symrem(
  ([`fn_go` returns `$FD`, or `fuji_a7800_present()` is false.],
   ([The magic `'F','N'` is missing at `$0C09`. The program is not on a FujiNet cartridge, or MAME was started without `-cartslot fujinet`.],
    [The image has no claim at `$FF70`, so the cartridge started it as a GAME and turned the mailbox off.])),
  ([Every transaction after the first comes back `$FF`: no answer.],
   [The program keeps its own sequence number. Take the next one from `ACKSEQ` at `$0C00` every time (Section 4).]),
  ([ERR is 2, timed out, on a network command.],
   ([The server is slow to answer. The cartridge allows 90 seconds for OPEN, STATUS, READ and CLOSE; the program’s own wait must be longer (Sections 4, 7, 9).],
    [The adapter cannot reach the server. Check the devicespec, and that the server is up.])),
  ([ERR is 3, bad frame, before anything is sent.],
   [A parameter has a size other than 1, 2 or 4, or there are more than eight.]),
  ([REPLY_CMD is `$15`, NAK.],
   ([The command is not answered on this build (the lists at the ends of Sections 16 and 17).],
    [A parameter has the wrong shape: two one-byte parameters where one two-byte parameter belongs, as SET_DIRECTORY_POSITION’s.],
    [A required parameter is missing: SET_SSID’s, STATUS’s.])),
  ([OPEN_APPKEY times out.],
   [The payload is missing its sixth, reserved byte, and the adapter is still waiting for it.]),
  ([`DIAG_RMW` at `$0C27` is not 0.],
   [Something performed a read-modify-write on a write page. Find it: `checkrom.py` and `basfix.py` name the address.]),
)

#sect[The display]

#symrem(
  ([Text from a reply shows as garbage.],
   [MARIA is reading the mailbox. Copy the reply into RAM first (Section 5).]),
  ([A 7800basic program copies a reply and shows nothing, or the wrong bytes.],
   [An expression inside an array index, such as `FN_REPLY[ix + 2]`. Give the field its own `dim` at its address (Section 9).]),
  ([A 7800basic loop copies one byte too many.],
   [An expression in the `for` bound. Compute the bound into a variable first.]),
  ([The picture breaks up only while a banked program waits for the FujiNet.],
   [The font or tiles are in a switched bank. Put everything MARIA reads in the fixed bank (Section 14).]),
  ([Colours go wrong part of the way across a row on the tile engine.],
   [The row has more than twelve palette runs. Keep a string, and the cells around it, in one palette (Section 15).]),
)

#sect[The network]

#symrem(
  ([STATUS says 0 bytes waiting, forever.],
   ([The server never answered. Check the devicespec and the server.],
    [On the bench: the fixture server is not running on port 8765.])),
  ([READ comes back NAK.],
   [It asked for more than STATUS said was waiting, or for more than 1024 bytes.]),
  ([A second OPEN on the same channel gets the first one’s data.],
   [The first was never closed. Close every connection, including on the way out of a failure.]),
)

#sect[Booting]

#symrem(
  ([BOOT_STATE reads `$80`, failed.],
   [BOOT_ERR says why: 1 the image is bigger than 448K; 2 it arrived short; 3 no board layout fits it (add a `.cfg` beside it with a `mapper=` line); 4 the only store big enough is the one running the program.]),
  ([The screen turns yellow after a boot and stays yellow.],
   [The loader’s stores below `$1000` are not reaching the cartridge. On real hardware this is the first thing to check (Section 1).]),
  ([The screen is red at power-on.],
   [The boot block cannot see the cartridge’s magic at `$0C09`: the same fault, earlier.]),
  ([A game boots, but not through the console’s BIOS.],
   ([INPTCTRL is locked: 7800basic locks it at start-up unless told not to (Section 9).],
    [The image is a FujiNet app, which always starts directly.],
    [This console’s BIOS is not known to accept the image (STAGED bit 2).])),
  ([A banked FujiNet app runs as garbage.],
   [The cartridge took it for a plain 64K image. Name the bank scheme in the claim’s kind byte, or in an `.a78` header.]),
)

#sect[The bench]

#symrem(
  ([MAME ignores `-autoboot_script` and nothing is checked.],
   [MAME was not run from its own tree. `emu/run.sh` changes there first.]),
  ([The cartridge model never connects to the FujiNet.],
   ([`fujinet-pc` is not listening on the address in `FUJINET_TCP` (127.0.0.1:9995 by default).],
    [Another MAME is still connected; a listener takes one client. `emu/run.sh` stops a stale one first.])),
  ([A networked game stops at a countdown.],
   [The server counts real seconds and MAME is running unthrottled. Use `THROTTLE=1`.]),
  ([MAME will not start headless.],
   [Set `SDL_VIDEODRIVER=dummy`.]),
)
