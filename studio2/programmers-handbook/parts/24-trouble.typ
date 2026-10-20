#import "../lib.typ": *
#set page(columns: 1)
#refpage.update(true)

= Troubleshooting Checklist <trouble>

#hang([], [If a program does not do what you expect, find the symptom below before you look anywhere else. Most of them were met while this handbook was written.])

#sect[Building]

#symrem(
  ([AS says “error in opening file” for an include that is there.], ([AS takes one include list: a second `-i` replaces the first. Give one `-i` with the folders separated by colons.], [A long list of absolute paths is cut short without a word. Make the paths relative.])),
  ([AS says a branch target is out of range, or off its page.], ([A short branch reaches only its own page. Put a `FIT` with the routine’s size before it, or leave the page with `FJMP`.])),
  ([`checkrom.py` refuses a 3-cycle opcode.], ([`LBR`, the long branches and skips, and `NOP` (`$C0`–`$CF`) cost the 1861 a byte of its line. Use a short branch on the page, or `FJMP` off it.])),
  ([`checkrom.py` refuses RF.], ([RF is the hotspot pointer, read only with `LDN`. Use another register for a pointer of your own.])),
  ([`mkst2.py` refuses a page.], ([Code landed on `$x000`–`$x3FF`, `$0B`, `$08`–`$09` or `$E4` and up. `RFIT` instead of `FIT` skips the low pages; an `ORG` puts code where it may go.])),
  ([`fitcheck.py` says a FIT is short.], ([The routine grew. Make the size what fitcheck measured: today it fits by luck.])),
  ([AS says `fn_go` (or `d_at`) is undefined.], ([The runtime’s includes go at `ORG 0400H`: `s2call.inc`, `fujilib.inc`, `fujidisp.inc`, and `input.inc` for the keypads.])),
)

#sect[The mailbox]

#symrem(
  ([The program says no FujiNet cartridge answers.], ([The image lacks `"FUJI"` at `$07FC`: end it with `S2CLAIM`. Without it the cartridge serves it as a game, with no mailbox.], [In MAME, `FUJINET=1` or `FUJINET_BOOT=` was not set, and the device is asleep.])),
  ([`fn_go` returns `$FF`, FNEWAIT.], ([The transaction outlived the program’s wait. `SLOW` above the cartridge’s own: 66 for a mount or copy, 95 on a network channel.], [MAME is talking to no `fujinet-pc`: set `FUJINET_TCP`. Unset, the model tries port 9995, which `run.sh`’s comment says it never uses.])),
  ([ERR is 1, NOLINK.], ([The cartridge cannot see the ESP32-S3. On the bench, `fujinet-pc` is not running, or another MAME holds its one connection.])),
  ([ERR is 2, a timeout.], ([The FujiNet did not answer in 5 seconds (60 for a mount, 90 for a network channel). A command that waits for a missing byte of payload times out: OPEN_APPKEY needs all six bytes, SET_SSID all 97.])),
  ([ERR is 3, BADFRAME.], ([A parameter’s size was not 1, 2 or 4. Stream parameters with `fn_pb` and `fn_pw`, and set NPARAM to their number.])),
  ([`fn_ack` says NAK.], ([The FujiNet refused the command: check its card in the Command Reference. Some are not answered on this build at all; their lists end each chapter.])),
  ([A reply’s bytes are wrong, or zero.], ([A later transaction painted over the window. Use the reply before the next launch, or copy what must last.])),
  ([The second transaction after a CLEAR is number 3.], ([Nothing is wrong: the cartridge kept ACKSEQ across CLEAR. Never count sequence numbers yourself.])),
  ([STAT’s link bit, or LINK at `$E815`, reads 0 after it was 1.], ([`FN_R_LINK` is not latched, whatever its comment says: it follows the link. A RESET of the FujiNet drops it for a moment.])),
)

#sect[The screen]

#symrem(
  ([The picture rolls, slips or shows stripes.], ([The program read `$F400`–`$FFFF`: the cartridge counted the reads as the 1861’s.], [The display interrupt was changed. R0 must be set in it, with its one long branch where it is.], [An `IDL` ran: it reads through R0 on every cycle. Look for a fall into a FIT’s gap of zeros.])),
  ([Text runs off the bottom and is lost.], ([PUTC never scrolls. Use SCROLL, as the netcat does.])),
  ([A PRINT shows nothing.], ([The offset or the most was wrong, or the reply has a NUL first. PRINT stops at a NUL.])),
  ([The marquee stops.], ([A transaction is running: the cartridge does one thing at a time. It goes on when the reply is in.])),
  ([The progress bar is still there after the image is ready.], ([The strip stays through READY, and goes with the swap or a failure, whatever `s2_text.h`’s comment says.])),
)

#sect[The keypads]

#symrem(
  ([Presses go missing.], ([The program waits between reads. Read the keypads every frame and do the slow work every few.])),
  ([Every key reads as pressed, or none.], ([`OUT 2` read the cartridge: X must point at console RAM, `V_KTMP`, while it runs.])),
  ([A key repeats when it should not.], ([`in_get` repeats any held key. Check for a fresh press, as CONFIG’s `key_wait` does for every key but the arrows.])),
)

#sect[Booting]

#symrem(
  ([`fujiboot` shows `FAILED 03E02`.], ([MOUNT_IMAGE timed out. The program’s wait must pass the cartridge’s 60 seconds.])),
  ([`FAILED 05E03`.], ([BOOT_ERR 3: the image names a page a FujiNet program may not use.])),
  ([`FAILED 05E01`.], ([BOOT_ERR 1: the image is larger than 16,640 bytes.])),
  ([`FAILED 06E`, anything.], ([The swap was never armed: BOOTLOCK was written before BOOT_STATE said READY.])),
  ([A game boots, and CONFIG cannot be reached again.], ([A game does not claim the mailbox. Turn the console off: power is the only way back.])),
)

#sect[The bench]

#symrem(
  ([MAME starts but the cartridge cannot connect.], ([`fujinet-pc` is down (`bench/up.sh`), on another port, or already talking to another MAME.])),
  ([A drive script against a game server times out.], ([MAME ran unthrottled and the server’s seconds are real. `THROTTLE=1`.])),
  ([A Lua test changes what it measures.], ([It read the address space and fired a hotspot. Read the device’s save items, as `s2screen.lua` does.])),
  ([The firmware README’s list of a program’s pages leaves out `$0A`.], ([The planner allows it, and this handbook follows the planner, `st2.py`.])),
)

#refpage.update(false)
