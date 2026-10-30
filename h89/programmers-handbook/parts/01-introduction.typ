#import "../lib.typ": *
#import "../prog.typ": *

#pagebreak(to: "odd", weak: true)
#part-title("Introduction", gap: 0.7in)

#balanced[
This Manual is for the H89 owner who wants to write programs that use the FujiNet. Its companion,
the Operation Manual, shows how to install the card, join a network and put disk images in the
FujiNet drives. This one goes underneath. It shows how a program talks to the card, every command
the FujiNet answers, and the programs that use them.

Everything in it is shown three ways, so you can work the way you like best:

- In *Z80 assembly language*, assembled on another computer with z88dk's assembler and carried to
  the H89 on a disk image. One source file makes both an HDOS program and a CP/M program.
- In *C*, compiled on another computer with z88dk and the FujiNet project's library, fujinet-lib.
- As the *bytes* that went between the H89 and the FujiNet when the example ran, so you can
  write the program in any language you please, BASIC included.

If you would rather stay at the H89's own keyboard, Chapter 5 shows how to assemble a FujiNet
program with the 8080 assemblers that come with HDOS and with CP/M.

The Manual ends with whole programs, fully listed and explained:

- NETCAT, a terminal for bulletin boards and other computers on the network;
- NGET and NPUT, which copy files between your disks and the network;
- an ISS tracker that reads the space station's position from the Internet and plots it on the H19;
- three network games, *Texas Hold'em*, *Battleship* and *Fujitzee*, which you play against other
  people on other kinds of computers.
]

#section("What You Need")[
- An H89 (or H88, or Z-89) with the FujiNet card installed and working, as the Operation Manual
  describes. FujiNet Go H89, the H89 emulator, will do as well. Every example in this Manual was
  run on it.
- HDOS 2.0, or Heath/Zenith CP/M 2.2.04. The programs were run on a full-memory H89 (one HDOS
  reports as 56K). All but Fujitzee should fit a 48K machine, but were not tried in one; Fujitzee
  needs the full memory under HDOS.
- For Z80 assembly and C: a modern computer with z88dk (Linux, macOS or Windows). Chapter 4 shows
  how to set it up. For C, also fujinet-lib, which Chapter 6 shows how to build.
- A way to carry programs to the H89: the FujiNet itself (put the disk image on its microSD card or
  on a TNFS server, and mount it), or FujiNet Go H89's disk drives.
- For Chapter 5 only: the HDOS 2.0 Software Tools diskette, or the CP/M 2.2.04 distribution
  diskettes, which carry the 8080 assemblers.
]

#section("How This Manual Is Arranged")[
#set par(justify: false)
#let row(n, t, d) = grid(columns: (0.32in, 1fr), column-gutter: 0.4em,
  text(font: f-head, weight: "bold")[#n], [#text(weight: "bold", t). #d])
#for (n, t, d) in (
  ("2", "Programming Model", [The card as the H89 sees it: four ports, a handshake, a clock.]),
  ("3", "The FujiBus Protocol", [How a request and its reply are framed, byte by byte.]),
  ("4", "Assembly Language", [The book's Z80 library, and building programs for HDOS and CP/M.]),
  ("5", "Assembly on the H89", [The same, with Heath's assembler and Digital Research's.]),
  ("6", "C with z88dk", [The compiler, fujinet-lib, and getting a C program onto the H89.]),
  ("7", "fujinet-lib Reference", [Every function in the library.]),
  ("8", "The FujiNet Device", [Device 70H: WiFi, hosts, directories, drives, app keys and more.]),
  ("9", "The Disk Drives", [Devices 31H to 38H, sector by sector.]),
  ("10", "The Network Device", [Devices 71H to 78H: eight channels to the network.]),
  ("11", "Network Protocols", [The 28 kinds of place a channel can open.]),
  ("12", "Clock, Printer, Modem", [Devices 45H, 40H and 50H.]),
  ("13", "NETCAT", [A terminal program, in assembly and in C.]),
  ("14", "NGET and NPUT", [Copying files to and from the network.]),
  ("15", "ISS Tracker", [Reading JSON from a web service.]),
  ("16", "The Network Games", [How the three games work, and their server.]),
  ("17-19", "The Games", [Texas Hold'em, Battleship and Fujitzee, complete.]),
  ("20", "Appendix", [Error codes, a quick reference, the H19, HDOS and CP/M, errata.]),
) { block(above: 0.5em, below: 0.5em, row(n, t, d)) }
]

#section("Conventions")[
#sub("Numbers")
Heath wrote its numbers in octal, and the H89's front panel and monitor still do. The FujiNet's
firmware, and nearly everything written about it since, uses hexadecimal. This Manual leads with
hexadecimal and gives the octal beside it wherever an H89 owner would look for it:

- *70H* is hexadecimal: 7 sixteens and no units, 112 decimal.
- *160Q* is the same number in octal, as Heath's manuals write it.
- *042.200* is an address in Heath's *split octal*: the high byte and the low byte, each in octal.
  It is 2280H, where HDOS loads programs.

Numbers with no letter after them are decimal.

#sub("Names")
Every device and command is called by the name the FujiNet firmware gives it, such as DEV_FUJINET
and FUJI_GET_ADAPTERCONFIG. The same names are defined for you in the book's assembly library
(Chapter 4), so a program can say what it means. fujinet-lib has names of its own for the same
things; Chapter 7 gives both.

#sub("What you type")
In the sessions, what you type is #typed("underlined"), and #ret means press the RETURN key. The
screens are drawn in the H19's own characters, taken from its character generator ROM.

#sub("H89")
"H89" means the H88 and the Z-89 as well. They are the same computer to the FujiNet.
]

#section("Reading a Command Card")[
Chapters 8 through 12 give each FujiNet command a card, followed by what you need to know to use it.
In order, a card shows:

+ The command's name, and its number at the right.
+ The device it goes to and the command number, in hexadecimal and in octal, and the name the
  firmware and the book's library give it.
+ Any tags (see below).
+ FIELDS: the small numbers that go in the request's header (Chapter 3), in order.
+ PAYLOAD: the data that follows them, if any.
+ REPLY: what comes back.

Then come the command's description, and any NOTES and WARNINGS. Three examples close the entry:

- the command in Z80 assembly;
- the same in C;
- the bytes that went each way when the example ran, shaded to show which part of the frame each
  one is (the key is in Chapter 3).

All three are cut from the exerciser programs (Chapter 8), which were built and run for this Manual
under both HDOS and CP/M. Here is a short one, from Chapter 8:

#cmdcard("Get WiFi Status", dev: 0x70, cmd: 0xFA, tags: ("Stand-in WiFi",),
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [1 byte: 3, connected; 6, not])))
Whether the FujiNet is on its network.
#examples("fuji.get_wifistatus")

#sub("Tags")
A few commands cannot be shown the ordinary way. Their cards say so with a tag:

#stable((1.3in, 1fr),
  th[Tag], th[Means],
  [#tag-box("Stand-in WiFi")], [The example ran on fujinet-pc, which has no radio of its own. The
    networks it reports stand in for real ones.],
  [#tag-box("Not sent, computed")], [The command would stop the example program, so its bytes were
    worked out rather than sent. What the FujiNet does with it is cited from the firmware's source.],
  [#tag-box("Unframed")], [The device answers with bare bytes rather than a FujiBus reply.],
  [#tag-box("Output checked on host")], [The command's effect is outside the H89 (paper, a file),
    and was checked there.],
  [#tag-box("NAK")], [The FujiNet refuses the command on the H89.],
)
]

#section("The Software This Manual Describes")[
The FujiNet for the H89 is new, and its software is still changing. This Manual describes these
versions, which are the ones its examples ran against:

#stable((1.25in, 1fr),
  th[Program], th[Version],
  [Firmware], [For the card: fujinet-firmware PR \#2232 (branch h89-remove-245), which wires port A
    straight to the ESP32 and no longer reads /OE or DIR. The examples ran on fujinet-pc built from
    branch h89-disk-fixes, 7ab84ae64, which reports itself as v1.6; the PC build has no pin map, so
    neither change reaches it.],
  [fujinet-lib], [branch h89-setup-after-reset, 7fc847b, which carries PR \#249 (no DIR or /OE); the
    H89 is not yet in a release. The library's examples ran with it. The programs of Chapters 13 to
    19 and the library's own tests ran with 9e6d4dd, which still set DIR and /OE and started the card
    the old way (L22 to L24).],
  [z88dk], [v2.4-1231 (3bd06cad56)],
  [FujiNet Go H89], [v0.4.0, whose card has no 74LVC245: port A runs straight to the ESP32, and PC0
    and PC1 steer nothing. The exercisers, FNHELLO, HELLO and the programs of Chapter 5 ran on it;
    those of Chapters 13 to 19 and the library's tests ran on v0.1.0-3 (8dc059d), which modelled the
    transceiver.],
  [FNDISK, FN.DVD], [fujinet-h89 main, caccd04 (PR \#6: no DIR or /OE)],
)

Where the firmware or the library does something it should not, the entry says so in a WARNING,
with what to do instead. The examples all work as printed. The Appendix lists every such case in one
place, with the line of source it comes from, so it can be checked against later versions.
]

#section("Changes in This Edition")[
This third edition is for the card without its 74LVC245 (fujinet-firmware \#2232, October 2026):
port A of the 82C55A runs straight to the ESP32, which decides which way its lines go. What
changed for a program:

- _Port C._ PC0 and PC1, once the transceiver's DIR and /OE, are connected to nothing, like PC2. A
  program never sets a direction (Chapter 2).
- _The book's library._ FUJIBUS.INC, CARD.INC and RAWBUS.C no longer set DIR or /OE. `card_present`
  still reads PC0 and PC1, which every mode word leaves at 0. Chapter 5's FNVER and FNVERH lost
  their DIR writes too.
- _The other software._ fujinet-lib (PR \#249), FN.DVD and FNDISK (fujinet-h89 PR \#6) dropped DIR
  and /OE as well, so a program built with them needs this card, or FujiNet Go H89 v0.4.0 (L24).
  They set the card up with mode word C2H, which leaves port B an input and the lamps dark (L23).
- _Versions._ The table above names the firmware, library and FujiNet Go H89 for this card.

The second edition was for the card as reworked for fujinet-firmware \#2042: the ESP32's EN, IO0 and
IO2 came off the card, the FujiNet runs from power-on, RESET resets the 82C55A only, port B drives
eight lamps, and FNON and FNONH, which existed to start the card, went.
]

#section("How the Examples Were Checked")[
Every program in this Manual was built from the source printed here and run on FujiNet Go H89 under
both HDOS 2.0 and CP/M 2.2.04. The emulator's card was connected to a FujiNet built from the
firmware above (fujinet-pc, the FujiNet that runs on a personal computer), through a small program
that recorded every byte in both directions. The byte strips printed with each command are those
recordings, unedited.

The programs that use the network talked to small servers on the same computer, so they give the
same answers every time. The screens in Chapters 13 through 19 were taken the same way.

Nothing in this Manual was run on a real H89 FujiNet card. The card and fujinet-pc run the same
firmware, built for the same bus, so they should agree; where they could differ (WiFi, the microSD
card, timing), the entry says so.
]
