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
  [Firmware], [For the card: fujinet-firmware master from 7e8e647 (PR \#2042), which reads /OE and
    DIR on IO21 and IO22. The examples ran on fujinet-pc built from branch h89-disk-fixes, 7ab84ae64,
    which reports itself as v1.6; the PC build has no pin map.],
  [fujinet-lib], [branch h89-setup-after-reset, d08f584 (the H89 is not yet in a release). The
    programs of Chapters 13 to 19 and the library's own tests ran with 9e6d4dd, which differs only in
    how it starts the card (L22).],
  [z88dk], [v2.4-1231 (3bd06cad56)],
  [FujiNet Go H89], [branch card-rev11, 6ceac07, whose card is the reworked V1.1: the ESP32 runs
    from power-on, and RESET reaches only the 82C55A. The programs of Chapters 2, 4 and 5 and the
    exercisers ran on it; those of Chapters 13 to 19 and the library's tests ran on v0.1.0-3
    (8dc059d).],
  [FNDISK, FN.DVD], [fujinet-h89, branch card-setup-mark, 4cb0024],
)

Where the firmware or the library does something it should not, the entry says so in a WARNING,
with what to do instead. The examples all work as printed. The Appendix lists every such case in one
place, with the line of source it comes from, so it can be checked against later versions.
]

#section("Changes in This Edition")[
This second edition is for the card as reworked for fujinet-firmware \#2042 (October 2026). The
rework takes the ESP32's EN, IO0 and IO2 off the card, and the FujiNet now runs from power-on.
What changed for a program:

- _Port C._ PC2, once the ESP32's EN, is connected to nothing. PC1 (/OE) and PC0 (DIR) still steer
  the bus transceiver, and the ESP32 reads them on IO21 and IO22 (Chapter 2).
- _Setting the card up._ `card_on` is one mode word and a read of port A. It no longer looks for the
  mark in port B, raises EN or waits 200 ms, and a mode word is safe at any time between
  transactions. `card_present` checks /OE and DIR only. fujinet-lib, FN.DVD and FNDISK still do the
  old start-up, which costs them only time (L23).
- _Port B_ drives eight lamps on the card. It is no longer "wired to nothing."
- _RESET_ resets the 82C55A only. A program that wants the FujiNet restarted sends FUJI_RESET
  (Chapter 8).
- _Chapter 5_ has FNVER and FNVERH only. FNON and FNONH, which existed to start the card, are gone.
- _Versions._ The table above names the firmware with the new pin map and the FujiNet Go H89 that
  models the reworked card.
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
