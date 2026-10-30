#import "../lib.typ": *

#pagebreak(to: "odd", weak: true)
#part-title("Introduction", gap: 0.7in)

#balanced[
Your FujiNet is a network adapter for the Heathkit H89 Computer. It is a single accessory circuit
board that plugs into one of the accessory sockets on the CPU logic circuit board, beside the
floppy disk interface, and it gives your Computer something no H89 had in 1979: a wireless
connection to the world's computers, and to the disk images on them.

To HDOS and to CP/M, the FujiNet looks like more disk drives. You choose a disk image -- from
the microSD card on the board, from a file server on your own network, or from one of the
public FujiNet servers on the Internet -- and put it in one of eight FujiNet drives. Then you
use it the way you use the diskette in drive SY0: or A:. You can catalog it, copy to it, run
programs from it and keep your work on it.

Some features of the FujiNet are:

- Eight FujiNet drives. Under HDOS they are FN0: through FN7:. Under CP/M they are D: through K:
  (or wherever you choose to put them).
- Eight host slots, each naming a place disk images come from: the microSD card, a TNFS server,
  or a web, FTP, SMB or NFS server.
- Wireless networking on 2.4 GHz WiFi, with the network's name and password kept on the
  FujiNet, so you set them up only once.
- A microSD card socket on the board, for your own library of disk images.
- FujiNet CONFIG, a full-screen program for the H19 terminal, to join your network, browse hosts
  and put disk images in drives. There is a version for HDOS and one for CP/M.
- FNDISK, the drivers that let HDOS and CP/M use the FujiNet drives: FN.DVD for HDOS 2.0 and
  FNDISK.COM for Heath/Zenith CP/M 2.2.04.
- A web page of its own, on your network, for settings you would rather make from another
  computer.
- An acceptance test you key into the monitor with the Substitute command, so you can check the
  card with nothing more than the H: prompt.
- Room to grow. The FujiNet also carries a printer, a modem, eight network channels and a clock,
  for H89 programs to use.

The FujiNet does not replace your floppy disk drives. The H89 still starts HDOS or CP/M from a
diskette in its own drive. Once your system is running, CONFIG and FNDISK bring in the FujiNet
drives beside the ones you already have. See "FujiNet Software" on Page 5-1.

This Manual takes you through the whole job in order. You set the card's jumpers, install it,
and check it with the acceptance test ("Set-Up and Testing," Page 3-1). You put the FujiNet
programs on a diskette and prepare your system for them ("FujiNet Software," Page 5-1). Then you
join your network and choose disk images with CONFIG (Page 6-1), and use the FujiNet drives from
HDOS and CP/M (Page 7-1). The chapters after those cover the microSD card and the web page,
firmware updates, troubleshooting, and how the card works.
]

#section("About This Manual")[
#sub("Steps")
Every step you perform is marked with a pair of parentheses, like this:

#step[Do the thing the step tells you to do, then make a check mark between the parentheses.]

If you are interrupted, the check marks show where you left off.

#sub("What You Type")
When this Manual shows you something to type, it is #typed("underlined"), and set in the same
characters the H19 shows you. The symbol #ret means "push the RETURN key." For example:

#align(center, block[#scr("H: ")#typed("G040100")#ret])

means that, at the monitor's H: prompt, you type G, 0, 4, 0, 1, 0, 0 and then push RETURN. The
monitor finishes the words it knows, so the screen will show "H: Go 040100." The parts the
Computer types for itself are not underlined.

Keys are named by the words on their caps: #key[RETURN], #key[ESC], #key[TAB], #key[ERASE],
#key[SHIFT], #key[RESET]. "Push #key[SHIFT] and #key[RESET]" means hold down the right-hand SHIFT key,
push RESET, and let go of both.

#sub("Numbers")
The Heath monitor works in octal. As in all Heath manuals, an address is written in _split octal_,
two octal bytes side by side: 040100 is the high byte 040 followed by the low byte 100 (2040 in
hexadecimal). Port numbers are octal too. The FujiNet card answers at ports 320 through 323, which
are D0 through D3 hexadecimal.

#sub("Pictorials and Pages")
Drawings are called Pictorials and are numbered by chapter. Page numbers are by chapter as well:
Page 6-3 is the third page of Chapter 6.

#sub("Which Software")
This Manual describes the first release of the FujiNet software for the H89. The FujiNet's
programs are improved all the time. If something on your screen differs from a picture in this
Manual, believe your screen, and look for news on the FujiNet Wiki (see the inside front cover).

#sub("Changes in This Edition")
#metadata("Changes in This Edition") <toc2>
This third edition covers the card without its 74LVC245 (fujinet-firmware \#2232, October 2026):
the 82C55A's port A now runs straight to the ESP32. What changed:

- _The card._ U3, the data transceiver, is gone, and so is R1, which held it off. The Computer no
  longer sets a direction for port A, and PC0 and PC1 are no longer used (Chapter 11).
- _Testing._ The Communication Test is 106 numbers long instead of 114 (Chapter 3).
- _Software._ CONFIG, FN.DVD, FNDISK and the Communication Test no longer set DIR and /OE. They
  need this card, or FujiNet Go H89 v0.4.0; older copies still work on it.

The second edition covered the V1.1 card, reworked for fujinet-firmware 7e8e647: a second
74LVC245 (U5) for the control lines, eight lamps on port B, the ESP32's EN, IO0 and IO2 off the
card, a FujiNet that runs from power-on and through a reset, and firmware updates over USB alone.
The first edition covered the V1.0 card.
]
