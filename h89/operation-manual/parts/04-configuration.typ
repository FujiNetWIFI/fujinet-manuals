#import "../lib.typ": *
#import "../figs.typ": portmap

#chapter(4, "System Configuration")

#section("The FujiNet in Your System")[
This chapter of the Manual shows how the FujiNet card fits into your Computer: the I/O ports it
uses, the memory its programs need, and the settings of its jumpers. If you have set the jumpers as
described in "Set-Up and Testing" and the Communication Test passed, nothing here needs changing.
Read it before you add other accessories, or if you are using your Computer with non-Heath
equipment.

#sub("I/O Ports")
The card answers at four I/O ports, 320 through 323 octal (D0 through D3 hexadecimal). The
82C55A’s port A, at 320, carries the bytes between the Computer and the FujiNet in both directions;
its port C, at 322, carries the handshake and the lines that steer the bus transceiver; 323 is the
82C55A’s control register. Port 321 (port B) drives the card's eight lamps, D3 through D10, and the
header J12; the FujiNet does not use it.

The Computer's address decoder gives each accessory a group of eight ports, and the PORT SEL jumper
picks the group. JP1 picks the first four ports of the group (on 0) or the last four (on 4).

The card uses only four ports of its group, but no other accessory may use the same group. In a standard Heath system, the group 320--327 belongs to the second port of the
HA-88-3 serial interface (the DCE port HDOS uses as its alternate terminal). It is free unless that
port's 8250 is installed.

#sub("Memory")
The FujiNet uses no memory in the Computer. Its programs do:

- HDOS: CONFIG.ABS runs from 052200 (2A80 hexadecimal) up, and FN.DVD, the HDOS device driver,
  takes about 4.3K at the top of memory once it is loaded. A 64K Computer (HDOS says "56K") has
  room for both. A 48K Computer has room for CONFIG only until FN.DVD is loaded; after that, HDOS
  answers "NOT ENOUGH RAM FOR THIS PROGRAM" until you start the system again. On a 48K Computer,
  run CONFIG first, then use the FujiNet drives.
- CP/M: FNDISK.COM puts about 2K of driver above CP/M’s BIOS, in the space a 62K system leaves free
  in a 64K Computer. See "Making a 62K CP/M System" on Page 5-3.

#sub("Interrupts")
The FujiNet programs do not use interrupts; they watch the 82C55A’s status instead. Leave J3 with no
jumper. A jumper on J3 would tie the card to one of the Computer's interrupt levels, 3, 4 or 5,
which the console and other accessories already use.

#sub("Reset")
The Computer's RESET line resets the card's 82C55A, and nothing else on the card. So whenever you
push #key[SHIFT] and #key[RESET], the Computer loses touch with the FujiNet until the next FujiNet
program you run sets the 82C55A up again, which it does at once. The FujiNet itself keeps running,
with its drives in service.

The FujiNet starts afresh only when the Computer is turned on. Its settings, its host slots and
your choices of disk images are always kept; but after it starts, the drives are not put back in
service until you run CONFIG, unless you have told the FujiNet to do it by itself (see "When the
FujiNet Starts" on Page 6-12).
]

#wide-head("I/O Port Map")
#grid(columns: (1fr, 1fr), column-gutter: gutter,
  [The I/O Port Map shows the ports in a typical Heath H89, octal, with the FujiNet card's four
  marked. The ports between 200 and 317 are reserved for HDOS. A Z-89-37 soft-sectored floppy
  disk interface uses 170--173; that is why the card's 170Q PORT SEL position is not used.

  #v(0.6em)
  #sub("Jumper Settings")
  #stable((auto, auto, 1fr),
    th[Jumper], th[Position], th[Use],
    [PORT SEL (J1)], [320Q], [The group 320--327. *The position to use.*],
    [], [330Q], [The group 330--337 (the HA-88-3 DTE port's). Not used by present software.],
    [], [340Q], [The group 340--347 (the HA-88-3 LP port's). Not used by present software.],
    [], [170Q], [The group 170--177 (the Z-89-37’s). Not used by present software.],
    [JP1 (BA2)], [0], [The first four ports of the group: 320--323. *The position to use.*],
    [], [4], [The last four: 324--327. Not used by present software.],
    [J3], [none], [No interrupts. *The setting to use.*],
    [], [/INT3, /INT4, /INT5], [Interrupt level 3, 4 or 5. Not used by present software.],
  )
  #note[The FujiNet programs look for the card at 320 only. A card set to another position will
  not be found.]],
  align(center, pictorial(caption: [The I/O ports in an H89.], portmap())))
