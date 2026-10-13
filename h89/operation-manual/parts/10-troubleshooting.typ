#import "../lib.typ": *

#chapter(10, "Troubleshooting", gap: 0.5in)

#notice("Important Notice")[
The FujiNet card, its firmware and its programs were designed to work together, and with Heath's own
H89, HDOS 2.0 and CP/M 2.2.04. Other monitors, operating systems and accessories may work, and many
owners will gladly help you find out, but the FujiNet project cannot promise it.

There is no factory to send your card to. There is something better: the community of FujiNet
owners, many of whom have Heath equipment on their benches. If the charts in this section do not
solve your problem, ask on the FujiNet Discord or forums (see the inside front cover). Say which
Computer, monitor, operating system and FujiNet firmware you have, what you did, and exactly what
the screen said.
]

#section("General Troubleshooting Information")[
Most troubles with a new FujiNet are in its installation: a jumper, a card not fully seated, or
another accessory answering at the same port. The tests in Chapter 3 find these, so when something
is wrong, run the Communication Test (Page 3-5) first. If it passes, the card and the Computer are
talking, and the trouble is in the settings or the software.

Remember these things the FujiNet does by design:

- Turning on the Computer, or pushing #key[SHIFT] and #key[RESET], stops the FujiNet. The next
  FujiNet program starts it again.
- After it starts, the FujiNet waits for CONFIG before it puts its drives in service, unless you have
  told it otherwise (Page 6-12).
- The FujiNet reads its microSD card only when it starts.
- It hears only 2.4 GHz WiFi networks.
- The H89 cannot start HDOS or CP/M from a FujiNet drive.
- Public servers on the Internet can only be read.
]

#section("Troubleshooting Charts", balance: false)[
The following charts list conditions and their possible causes. Find the condition that matches
what you see, and check each cause in turn.

#sub("Installation and Testing")
#chart(
  [The Computer does not give the #scr("H:") prompt with the card installed.],
  [The card is not fully seated, or is offset by a pin. Turn off the Computer, unplug it, and reseat the card. Switch SW501 is set for automatic booting or a memory test at power-up: push #key[SHIFT] and #key[RESET].],
  [Port Test reads 377.],
  [Nothing answered at port 322. The PORT SEL jumper is missing or not on 320Q; the card is not seated; the card is in the floppy disk interface's sockets (P506 and P512).],
  [Port Test reads something other than 200 (or 240), or the second reading is not 206 (or 246).],
  [Another accessory also answers at port 320 to 327: an HA-88-3 with the 8250 for its 320 port installed. Remove that 8250. Otherwise, a fault on the card (U1, U3).],
  [Communication Test: only #scr("H") (and a beep).],
  [As for "Port Test reads 377," above.],
  [Communication Test: #scr("1"), and nothing more.],
  [The FujiNet is not taking bytes. Its firmware is missing or is not the H89 firmware; it was left in loading mode after a firmware update (push #key[SHIFT] and #key[RESET]); no 3.3 volts on the ESP32 module; a fault in U2 (74LVC245) or the divider resistors at J2.],
  [Communication Test: #scr("12"), and nothing more.],
  [The FujiNet took the request but no answer came back: the wrong firmware, or a fault on the return path (U1’s port A strobe lines, U2).],
  [Communication Test: no beep, no #scr("H"), garbled screen.],
  [The program was keyed in wrong. Check every entry (Page 3-6). Make sure you ran it with #typed("G040100").],
  [Communication Test: #scr("12") and the firmware version, but no names.],
  [Normal until the FujiNet has joined a WiFi network. Run CONFIG.],
)

#sub("CONFIG and WiFi")
#chart(
  [CONFIG says "Contacting FujiNet..." for a long time, then shows empty slots.],
  [The FujiNet is not answering. Run the Communication Test.],
  [HDOS says "NOT ENOUGH RAM FOR THIS PROGRAM" for CONFIG.ABS.],
  [On a 48K Computer, FN.DVD has been loaded: start HDOS again and run CONFIG first (Page 4-1). Less than 48K of memory. A CONFIG.ABS from some other source: use the one on the FujiNet for HDOS diskette.],
  [No networks are listed, or not yours.],
  [Your network is on 5 GHz only: give the router's 2.4 GHz band its own name. The router is too far away (the antenna is inside the cabinet). The network hides its name: use #scr("<Enter a network name>").],
  [CONNECT FAILED or UNABLE TO CONNECT.],
  [The password is wrong; capitals count. Your router admits only computers it knows: give it the MAC address from the WiFi Networks screen.],
  [Opening a host flashes "COULD NOT MOUNT HOST SLOT." and goes back.],
  [The host's name is misspelled, the server is not running, or (for SD) there is no microSD card, or it is not FAT32.],
  ["A drive could not be mounted."],
  [The image is gone from its host, the host cannot be reached, or the image was put in read/write on a host that can only be read.],
  [Typing seems to drop letters under CP/M.],
  [Type a little more slowly. CP/M’s BIOS keeps no type-ahead while CONFIG redraws the screen.],
)

#sub("HDOS Drives")
#chart(
  [?02 UNKNOWN DEVICE NAME.],
  [FN.DVD is not on SY0:, or HDOS has not been started since it was copied there (Page 5-1).],
  [?02 UNIT NOT AVAILABLE.],
  [The slot is empty; the drives have not been put in service since the last reset (run CONFIG and push #key[ESC]); the FujiNet is not answering.],
  [?02 UNABLE TO READ THIS DISK...],
  [The slot holds something that is not an initialized HDOS disk.],
  [?02 DEVICE IS INCAPABLE OF WRITE OPERATIONS...],
  [The image is in read only. Dismount, change it to read/write with CONFIG, mount again.],
  [CAT shows the old disk after you changed it.],
  [The drive was not dismounted before CONFIG. DISMOUNT and MOUNT it.],
)

#sub("CP/M Drives")
#chart(
  [No room above the BIOS.],
  [Make a 62K system (Page 5-3).],
  [Needs Heath/Zenith CP/M 2.2.04.],
  [FNDISK works with CP/M 2.2.04 only.],
  [No FujiNet card (82C55 at 0D0H) found.],
  [See "Port Test reads 377," above.],
  [The FujiNet isn't answering.],
  [The FujiNet is starting, or was left in loading mode. Push #key[SHIFT] and #key[RESET], start CP/M, and run CONFIG, then FNDISK.],
  [Bdos Err On D: Select.],
  [The slot is empty, holds something that is not an .H8D image, or the drives have not been put in service since the last reset (run CONFIG).],
  [Bdos Err On D: Bad Sector, when writing.],
  [The image is in read only. Push CTRL-C; change it to read/write with CONFIG.],
  [Drives D: through K: are gone.],
  [CP/M was started from its diskette (or the Computer reset) since FNDISK ran. Run FNDISK again.],
)

#sub("Firmware Updates")
#chart(
  [The Flasher cannot connect.],
  [The FujiNet is not in loading mode; the USB cable carries only power; the CP210x driver is missing (Windows).],
  [After an update, the programs say the FujiNet is not answering.],
  [Push #key[SHIFT] and #key[RESET] to take it out of loading mode.],
)
]
