#import "../lib.typ": *
= First Contact

One transaction, and the adapter's name, address and firmware version on the screen. The assembly program is the bring-up's own `fujitest.asm`, unchanged; the BASIC program is `text.bas`. Both ask the FUJI device for `GET_ADAPTERCONFIG_EXTENDED`, whose 240-byte reply is the whole adapter configuration, and both put three of its fields into text rows straight from the reply window.

#sect[Build and run]

#steps(
  [Build: `cd listings/asm && ./build.sh fujitest`. The script checks the equates, assembles, makes a 4096-byte image, stamps the claim and runs the static check.],
  [Start `fujinet-pc` if it is not running, and run the image: `emu/run.sh listings/asm/build/fujitest.bin`.],
  [The screen below appears after the round trip. In emulation that is immediate; on the cartridge it is a blank frame or two, because this program talks before it turns the display on.],
  [Press the console's RESET switch. The program restarts, runs the transaction again, and the last row shows `02`: the cartridge kept its sequence across the reset, and the program derived the next one from it.],
  [Headless: `emu/run.sh listings/asm/build/fujitest.bin txn` prints the status cells and the reply's text fields and says `PASS`.])

#shot("asm-acfg", caption: [`fujitest.asm`. The last row is the sequence number, the evidence that the cartridge and not the program remembers it.])

#sect[The reply]

`GET_ADAPTERCONFIG_EXTENDED` needs no parameters and answers with one packed record. The text fields at the end are the ones to show; the binary ones in the middle are for programs that need to compute with an address.

#tbl((auto, auto, 1fr),
  th[Offset], th[Size], th[Field],
  [0], [33], [`ssid`, NUL-terminated],
  [33], [64], [`hostname`],
  [97], [4 × 4], [`localIP`, `gateway`, `netmask`, `dnsIP`, binary],
  [113], [6 + 6], [`mac`, `bssid`, binary],
  [125], [15], [`fn_version`, text],
  [140], [16 × 4], [`sLocalIP`, `sGateway`, `sNetmask`, `sDnsIP`, dotted text],
  [204], [18 × 2], [`sMacAddress`, `sBssid`, text])

Every field a program wants is below offset 256, which is why the library's one-byte reply offset reaches all of them.

#sect[The assembly program]

The cold start clears the TIA and RAM together --- `$00`--`$7F` is the TIA and `$80`--`$FF` is RAM, so one loop from `$FF` down does both --- blanks the screen, opens the gate and checks that a cartridge is answering. Then the transaction, exactly the recipe of Section 4:

#excerpt-at("fujitest.asm: the transaction", "listings/asm/fujitest.asm", "GOTCART:", to: "; ---------------- put it on screen")

The reply is rendered with `FNRSTR` for the labels, which live in ROM, and `FNRRPL` for the fields, which live in the reply window and never touch RAM:

#excerpt-at("fujitest.asm: the SSID row", "listings/asm/fujitest.asm", "SHOWOK:", n: 10)

The last row is the sequence number, rendered in hex from the cartridge's ACKSEQ cell:

#excerpt-at("fujitest.asm: the evidence", "listings/asm/fujitest.asm", "; The sequence number, in hex", to: "RUN:")

Then the display is turned on and the program draws frames forever. Its `APPVBL` is a bare `RTS`: nothing happens per frame.

#sect[The BASIC program]

`text.bas` does the same in BASIC, with batari Basic's playfield above and three rows of the cartridge's text below. The transaction is the recipe from Section 4 written out; the rows are one subroutine, called three times with a different reply offset, and each call is followed by a frame so that no frame runs long:

#excerpt-at("text.bas: the transaction and the rows", "listings/bas/text.bas", " FNH_ARM1 = FNAM1", to: "main")

#excerpt-at("text.bas: a row from the reply", "listings/bas/text.bas", "putrow", to: "putok")

#shot("bas-text", caption: [`text.bas`: the same three fields, through the minikernel.])

`arm.bas`, in the same directory, is the smallest version: it runs the transaction and turns the screen green if the transport reported no error, red otherwise. It is the program to try first when nothing else works.
