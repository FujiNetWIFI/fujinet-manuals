#import "../lib.typ": *

#chapter(13, "Appendix", gap: 0.5in)

#section("Quick Reference", balance: false)[
#sub("CONFIG: the Main Screen")
#stable((0.9in, 1fr),
  th[Key], th[Does],
  [arrows, #key[1]--#key[8]], [Pick a host slot or drive slot],
  [#key[RETURN]], [Browse the host (edit an empty slot)],
  [#typed("E")], [Edit a host slot; eject a drive slot],
  [#typed("R") / #typed("W")], [Drive slot: read only / read/write],
  [#key[ERASE]], [Eject all drives],
  [#key[TAB]], [Host slots / drive slots],
  [#typed("C")], [Info and WiFi],
  [#key[ESC]], [Put the drives in service and leave],
  [#typed("Q")], [Leave without putting them in service],
)

#sub("CONFIG: Browsing")
#stable((0.9in, 1fr),
  th[Key], th[Does],
  [#key[RETURN]], [Open a folder; choose an image],
  [#key[BACK SPACE]], [Up a folder],
  [#key[\<] #key[\>]], [Previous / next page],
  [#typed("F")], [Filter (\* for any characters)],
  [#typed("N")], [New disk image],
  [#typed("C")], [Copy to another host],
  [#key[ESC]], [Back to the main screen],
)
In "Put it in which drive?": #key[RETURN] read only, #typed("W") read/write.

#sub("HDOS")
#stable((1.45in, 1fr),
  th[Type], th[To],
  [#typed("RUN SY1:CONFIG.ABS")], [Run CONFIG],
  [#typed("LOAD FN:")], [Load FN.DVD now (optional)],
  [#typed("MOUNT FN0:")], [Use drive slot 1],
  [#typed("DISMOUNT FN0:")], [Before CONFIG changes slot 1],
  [#typed("CAT FN0:")], [List its files],
)

#sub("CP/M")
#stable((1.45in, 1fr),
  th[Type], th[To],
  [#typed("B:CONFIG")], [Run CONFIG],
  [#typed("B:FNDISK")], [Add drives D: to K:, or list them],
  [#typed("B:FNDISK G")], [Add them from G:],
  [#typed("MOVCPM17 62 *")], [Then SYSGEN: make a 62K system],
)

#sub("The Monitor")
#stable((1.45in, 1fr),
  th[Type], th[To],
  [#typed("S040100")#ret], [Substitute: SPACE next, - back, RETURN done],
  [#typed("G040100")#ret], [Run the program at 040100],
  [#typed("O323,300")#ret], [(MTR-90) Set up the 82C55A],
  [#typed("I322")#ret], [(MTR-90) Read port C: 200],
  [#typed("O322,004")#ret], [(MTR-90) FujiNet loading mode],
  [#key[SHIFT] #key[RESET]], [Reset; the FujiNet stops],
)
]

#section("The Communication Test", balance: false)[
This is the program you key in for the Communication Test (Page 3-5), as the assembler listed it.
The first column is the address, in split octal; the second, the numbers you enter. The program
uses the monitor's routine at 003302 to print a character, and ends with a halt, which the monitor
turns into a beep and its prompt.

#listing("acctest")

The program that puts the FujiNet in loading mode (Page 9-2):

#listing("flashmode")
]

#section("The FujiNet's Devices")[
Inside the FujiNet are a number of devices, each with an identifying number. A program reaches one
by sending a packet through port 320: the device's number, a command, the packet's length, a check
byte, a byte describing what follows, and then any parameters and data. Each packet travels between
two bytes of 300 octal (C0 hexadecimal), and the FujiNet answers with a packet of its own.

#stable((0.75in, 1fr),
  th[Device], th[Is],
  [70 hex], [The FujiNet itself: WiFi, hosts, slots, copying],
  [31--38 hex], [Disk drives, slots 1 through 8],
  [71--78 hex], [Network channels N1 through N8],
  [40 hex], [Printer],
  [45 hex], [Clock],
  [50 hex], [Modem],
)

The Communication Test sends the FujiNet device (70 hex) command E8 hex, "get adapter
configuration," whose answer holds the WiFi network's name, the FujiNet's name and addresses, and
its firmware version. The full description of every device and command is in the FujiNet Wiki and
in the FujiNet Network Protocol Handbook.
]

#section("Glossary")[
#let gl(t, d) = block(above: 0.55em, below: 0.55em)[#text(font: f-head, weight: "bold")[#t] -- #d]
#gl[Disk image][A file holding everything on a diskette, sector by sector. The FujiNet's drives use .H8D images.]
#gl[Drive slot][One of the FujiNet's eight drives. Under HDOS, FN0: to FN7:; under CP/M, D: to K:.]
#gl[Firmware][The program that runs on the FujiNet's ESP32.]
#gl[FNDISK][The FujiNet's drivers: FN.DVD for HDOS, FNDISK.COM for CP/M.]
#gl[H8D][The disk image format for the H-17-1 diskette: 102,400 bytes.]
#gl[Host][A place disk images come from: the microSD card, or a server.]
#gl[Host slot][One of the FujiNet's eight host names.]
#gl[MAC address][The FujiNet's own hardware address on the network.]
#gl[Mode 2][The 82C55A’s bidirectional, strobed mode, used by the card.]
#gl[Mount][Under HDOS, make a disk known to the system. In CONFIG, put a disk image in service.]
#gl[Read only, read/write][Whether a drive slot may be written to.]
#gl[SSID][A WiFi network's name.]
#gl[Split octal][The Heath way of writing a 16-bit address as two octal bytes: 040100.]
#gl[TNFS][Trivial Network File System, the file-server protocol most FujiNet hosts use.]
]

#wide-head("Getting Help")
#[#metadata("Getting Help") <toc2>]
#block(breakable: false, grid(columns: (1fr, 1fr), column-gutter: gutter, [
- fujinet.online: news, downloads, and the list of public servers.
- The FujiNet Discord (discord.gg/7MfFTvD): other owners, at any hour.
- github.com/FujiNetWIFI: the source of the firmware, CONFIG and the drivers, where you can report a
  problem.
- github.com/FujiNetWIFI/fujinet-manuals: report a mistake in this Manual.
], [
When you ask, say which Computer, monitor (MTR-88, -89 or -90), operating system and FujiNet
firmware you have, what you did, and exactly what the screen said.
]))

#pagebreak(weak: true)
#wide-head("My FujiNet", above: 0pt)
#[
#set text(font: f-sans, size: 8.5pt)
#let field(l) = block(above: 0.9em, below: 0.2em, grid(columns: (1.6in, 1fr), l, line(length: 100%, stroke: 0.4pt + ink)))
#grid(columns: (1fr, 1fr), column-gutter: 0.4in, [
  #field[WiFi network (SSID)]
  #field[FujiNet's IP address]
  #field[FujiNet's name]
  #field[MAC address]
  #field[Firmware version]
  #field[Card installed in sockets]
  #field[Date installed]
  #v(0.8em)
  #text(weight: "bold")[HOST SLOTS]
  #for i in range(1, 9) { field[#i] }
], [
  #text(weight: "bold")[FAVORITE DISK IMAGES]
  #for i in range(1, 15) { field[] }
])
]
