#import "../lib.typ": *

#chapter(8, "More From Your FujiNet")

#section("The microSD Card")[
The microSD card is the FujiNet's own disk: the host called SD. Keep your library of H89 disk images
on it, in folders if you like, and put the images you want to write on there, since the public
servers can only be read.

- Use a card formatted FAT32. Cards of 32 gigabytes or smaller come that way; larger cards come
  formatted exFAT, which the FujiNet cannot read, and must be formatted FAT32 first.
- The FujiNet reads the card only when it starts. Put the card in, or take it out, only with the
  Computer turned off.
- To add disk images, turn off the Computer, take the card out, copy the images onto it with your
  personal computer, and put it back. Or copy them to it with CONFIG from another host (Page 6-9).
- The FujiNet also keeps a copy of its settings on the card, in a file named fnconfig.ini. Leave it
  there.

The card is not needed. Without one, the FujiNet works from its network hosts alone, and keeps its
settings in its own memory.
]

#section("The FujiNet's Web Page")[
Once the FujiNet has joined your network, it has a web page of its own. Any computer, tablet or
telephone on the same network can show it.

#step[Find the FujiNet's IP address on CONFIG’s Info screen (push #typed("C") on the main screen),
or on the 25th line of any CONFIG screen.]

#step[On the other computer, open a web browser and type #scr("http://") and the address: for
example, #scr("http://192.168.1.89"). Many computers can also find it as
#scr("http://fujinet.local").]

The page shows the FujiNet's version and network details, and lets you:

- Give the FujiNet a different name on your network.
- See the host slots and the disk images in the drive slots.
- Set the time zone the FujiNet's clock uses.
- Turn the printer and modem on or off, and choose the printer's type.
- See what has been printed.
- Choose whether the FujiNet puts its drives in service by itself when it starts ("Enable CONFIG
  boot disk": choose No for that; see Page 6-12).

The WiFi network is changed with CONFIG (Page 6-3), and the firmware with the FujiNet-Flasher
(Page 9-1).

Some settings on the page belong to FujiNets for other computers, and do nothing on the H89. The
serial port's speed is one: the H89 card talks to the Computer through its 82C55A, not a serial
port.
]

#section("File Servers", newpage: true)[
Any host slot can name a server on your own network or on the Internet. Most FujiNet owners use
TNFS, the "Trivial Network File System," a small protocol made for computers like the H89. You can
run a TNFS server on almost any personal computer: download it from fujinet.online, point it at a
folder of disk images, and type the computer's name or address into a host slot. Every FujiNet on
your network can then use the images in that folder, and write to them.

The FujiNet can also use folders shared from Windows and other computers by SMB, NFS exports, FTP
servers, and folders on web servers. See "Host Slots" on Page 6-5 for how to name each one.

#sub("Public Servers")
FujiNet owners run servers on the Internet for everyone. Two of them come set up in your host slots:

- tnfs.fujinet.online, the FujiNet project's own server.
- apps.irata.online, a library of programs for many computers.

Each server keeps software for each kind of computer in its own folder; look for the H89 folder.
The list of public servers, and whether each is running, is on fujinet.online.
]

#section("The FujiNet's Other Devices")[
The FujiNet is more than a set of drives. Like FujiNets for other computers, it carries:

- A printer, which turns what is printed into a file you can see on the web page, laid out as one of
  several printers of the day.
- A modem, Hayes compatible, which "dials" other computers over the Internet.
- Eight network channels, N1 through N8, that let a program fetch a web page, talk TELNET or SSH, or
  exchange data with another computer by TCP or UDP.
- A clock, set from the network, for programs that want the date and time.

These are there for H89 programs that use them, and such programs are being written. Watch
fujinet.online and the FujiNet Wiki for programs for the H89.

#sub("Writing Your Own")
If you write programs, all of the FujiNet is open to you. The Computer talks to the FujiNet by
sending small packets through the 82C55A at port 320, and the library that CONFIG and the FujiNet's
test programs are built on, fujinet-lib, is free to use from C with the z88dk compiler, for HDOS and
for CP/M. The Communication Test in Chapter 3, listed in the Appendix, shows the whole exchange in
129 bytes of 8080 code.

#sub("FujiNet Go H89")
FujiNet Go H89 is a program for Windows, macOS and Linux that is an H89 with an H19 and a FujiNet
built in: the same CONFIG, FNDISK and FN.DVD run on it, and its FujiNet joins the network through
your personal computer. It is a pleasant way to try out disk images, or this Manual, away from your
H89. It needs copies of the Heath ROMs, which it does not include. The screens in this Manual were
made with it.
]
