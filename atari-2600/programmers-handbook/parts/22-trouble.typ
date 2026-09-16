#import "../lib.typ": *
= Trouble Shooting Checklist

#sect[Building]

#symrem(
  ([`checkdefs` fails before anything assembles], [An equate in `fujinet.inc` no longer matches `fuji_mailbox.h`. Fix the equate; never the check.]),
  ([`checkrom`: an RMW or indirect store on the control pages], [Find the `INC`, `DEC`, shift or `STA (zp),Y` and replace it with a plain store. In BASIC, an arithmetic assignment to a mailbox name is the usual cause.]),
  ([`checkrom`: image size], [The image must be (N+1) × 2048 and a size MAME loads: 4K, 8K, 16K or 32K. Pad the bank count.]),
  ([Every `JSR` into the library lands at `$0000`--`$01FF`], [`fujilib.inc` was included before the `ORG`. Equates first, code inside the `ORG`.]),
  ([A bank assembles, the image is the right size, and code past `$17FF` is simply gone], [`p2bin` truncates in silence. Check the bank's extent in the assembler's listing, as Battleship's `checkbanks.py` does.]),
  ([batari Basic: "Origin Reverse-indexed"], [The program is over 2K. Trim with `default.inc`, `const noscore = 1`, or less BASIC.]),
  ([batari Basic: "EQU: Value mismatch"], [A `dim` or `const` redefines a name the kernel or the headers already own --- a single-letter variable, or an equate with a different value.]),
  ([batari Basic: an unresolved symbol at link time], [A name used in BASIC exists in no header. Check the spelling against `fujinet.h` and `fujibas.h`.]))

#sect[The mailbox]

#symrem(
  ([Magic `F`, `N` not at `$1F09`], [No cartridge, or MAME started with the wrong slot: `-cartslot fujinet`. The bring-up's plain slot serves the image but nothing paints.]),
  ([FLAGS bit 1 clear: the claim was not honoured], [`FUJI` is not at file offset (size − 2048) + `$710`. The build stamps it; a hand-built image must too.]),
  ([The program runs, draws, and no transaction ever completes], [The gate is closed: `$B5` to `$1DFC` then `$4A` to `$1DFD` before anything else. Or the control page is one page off --- see `checkdefs`.]),
  ([ERR = 2, timeout, on every transaction], [In BASIC: a value used without a `const`, so the device or command went out as a load from memory. In assembly: a parameter count that does not match the parameters written. In MAME: a stray MAME holding the bus-over-IP listener.]),
  ([ERR = 1, no link], [The USB link to the adapter is down, or `fujinet-pc` is not running. The cartridge waits three seconds for the link before its first transaction after a reset.]),
  ([REPLY_CMD = `$15`, a NAK, with ERR = 0], [The adapter refused the command: wrong parameter shape, a short 256-byte payload, a command this build does not dispatch, an unmounted host. The transport is fine.]),
  ([The first transaction after a RESET is ignored], [The program derived SEQ from a counter in RAM and collided with a sequence already answered. Use ACKSEQ + 1.]),
  ([The reply changes under the program], [Something launched a transaction or selected a slice. Read what you need before the next commit.]))

#sect[The display]

#symrem(
  ([Text, but the wrong characters in the wrong columns], [The positioning constants were changed. Restore `RNOP` 16, `R3` 1, `HM0` 15, `HM1` 0 and decode the raster to be sure.]),
  ([The last text line repeats down the blank lines], [The blank at the end of the kernel toggled `VDELP` instead of writing `GRP0`, `GRP1`, `GRP0`.]),
  ([A row shows part of the previous row's text], [The next row was composed before the render landed. Wait for TEXTGEN to change.]),
  ([One character of a row is stale after a blit], [Two blits in a row without waiting for BLITGEN.]),
  ([The picture rolls, in BASIC], [The frame is not 262 lines. Run `frames.lua`; fewer text rows, `pfrowheight` of 6, `noscore`, or a row per frame.]),
  ([The picture rolls once on a screen change], [More than a frame's worth of composing between two frames. Spread it, or accept it.]),
  ([`5` and `S`, `0` and `O` look alike in a test], [They are alike at 3 × 5 in most fonts; this one draws them apart. Compare rendered forms in harnesses, not decoded text.]))

#sect[The network]

#symrem(
  ([OPEN succeeds, STATUS says nothing is waiting], [The fetch is deferred to the first STATUS; take another reading. If the device status is not 1, the URL failed --- that is where an HTTP error shows.]),
  ([The first half of the page, then garbage], [STATUS was read once. Read until two readings agree.]),
  ([A URL from a path buffer fails], [It was emitted padded. Use the raw emit for a URL; padding lands inside the query.]),
  ([The screen goes blank after a READ], [CLOSE was sent after the READ. Close at the start of the next request.]),
  ([A count compare goes wrong past 127], [A signed branch. Compare through the carry.]))

#sect[Booting]

#symrem(
  ([BOOT_STATE goes to `$80`, BOOT_ERR = 1 or 3], [The image is larger than 32K, or its size is not a multiple of 2K.]),
  ([BOOT_STATE stays at 1], [The push is in progress; MOUNT_IMAGE has sixty seconds. A very slow host is a slow host.]),
  ([The swap does nothing], [BOOTLOCK was not committed, or was committed before BOOT_STATE was 2. It is honoured only once an image is staged.]),
  ([The booted game screams], [The stub did not silence `AUDV0` and `AUDV1`.]),
  ([The booted game cannot read its joystick], [The stub left `SWACNT` and `SWBCNT` as outputs.]),
  ([An 8K game runs the wrong banks], [It is E0, UA or FE and was served as F8. Put a `.cfg` with the scheme's name beside it.]),
  ([The mailbox is dead after the boot], [As it should be: the booted image has no claim.]))

#sect[The MAME bench]

#symrem(
  ([`Could not initialize SDL`], [No display: `SDL_VIDEODRIVER=dummy`, which `emu/run.sh` sets.]),
  ([The harness never runs], [MAME was not started from its own tree; `-autoboot_script` is silently ignored.]),
  ([A run hangs with no error], [A stray MAME holds the one-client bus-over-IP listener. `emu/run.sh` kills it first.]),
  ([A Lua write tap reports a request in bank 0 at frame 0], [That is the cold start clearing every zero-page cell, not a fetch.]),
  ([The server says "starting in 2" forever], [The run is unthrottled. The server's clocks are wall clock; throttled is not a performance choice.]))
