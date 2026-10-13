#import "../lib.typ": *

#chapter(6, "FujiNet CONFIG")

#section("Starting CONFIG")[
FujiNet CONFIG is the program you use to set up the FujiNet: to join your WiFi network, to tell the
FujiNet where your disk images are, and to put disk images in its eight drives. It fills the H19’s
screen, and you work it from the keyboard. There is a version for each operating system; they look
and work alike.

#sub("Under HDOS")
#step[Start HDOS from your system diskette (the one with FN.DVD on it).]

#step[If any FujiNet drives are mounted, dismount them first: #typed("DISMOUNT FN0:")#ret, and so
on. (See Page 7-3.)]

#step[Put the FujiNet for HDOS diskette in drive 1 and type #typed("MOUNT SY1:")#ret. Then type
#typed("RUN SY1:CONFIG.ABS")#ret.]

If you copied CONFIG.ABS onto your system diskette, #typed("RUN CONFIG")#ret is enough.

NOTE: On a 48K Computer, CONFIG has room to run only before FN.DVD is loaded (by the first
#scr("MOUNT FN") or #scr("LOAD FN:")). Run CONFIG first after you start HDOS; to run it again
later, start HDOS again. A 64K Computer can run it at any time.

#sub("Under CP/M")
#step[Start CP/M from your 62K system diskette.]

#step[Put the FujiNet for CP/M diskette in drive B and type #typed("B:CONFIG")#ret.]

#sub("What You See First")
CONFIG draws its frame and says #scr("Contacting FujiNet...") while it starts the FujiNet and asks
it how things stand. That takes a few seconds after the Computer has been reset. Then:

- If the FujiNet has never been told about a WiFi network, CONFIG shows the WiFi Networks screen.
  See "Joining Your WiFi Network."
- If it knows a network, CONFIG joins it, and shows the Host Slots and Drive Slots: the main screen,
  where you will spend most of your time.
]

#wide(pictorial(caption: [CONFIG’s main screen, under HDOS.], crt("hosts", width: 6.2in)))

#section("The Screen", newpage: true)[
Every CONFIG screen has the same parts, as in Pictorial 6-1:

- The top line names the program and the operating system it is running under: H89 HDOS or H89
  CP/M.
- The upper and lower panes hold lists: here, the eight host slots and the eight drive slots. The
  name of the pane you are working in is shown in reverse video, and the selected line of it carries
  a bright bar with an arrow at its left.
- The line under the panes is the information line. CONFIG asks its questions here, and tells you
  what it is doing.
- The two lines below the frame show the keys you can use now. A key's name is shown in reverse
  video: #key[RET] means the RETURN key.
- The H19’s 25th line, at the very bottom, shows the WiFi network the FujiNet has joined, its
  address on that network, and the version of its firmware.

#sub("The Keys")
CONFIG uses the H19’s numeric keypad for moving about. It sets the keypad to its shifted mode while
it runs, so the arrow keys move the bar even without SHIFT; it puts the keypad back when you leave.

#stable((0.95in, 1fr),
  th[Key], th[Does],
  [#key[8] / #key[2] (arrows)], [Move the bar up and down. Down from host slot 8 goes into the drive slots.],
  [#key[4] / #key[6] (arrows)], [In a list of files, turn to the previous or next page.],
  [#key[5] (HOME), #key[1] (IL)], [Go to the first or last line.],
  [#key[9] (DC), #key[3] (DL)], [Previous or next page of files.],
  [#key[1] to #key[8]], [On the main keyboard: pick that slot.],
  [#key[RETURN]], [Choose the selected line.],
  [#key[TAB]], [Move between the host slots and the drive slots.],
  [#key[ESC]], [Go back a step. On the main screen: mount the drives and leave CONFIG.],
  [#key[ERASE]], [In a list of drives: eject them all. When typing: clear the line.],
  [#key[BACK SPACE]], [When typing: rub out the last character. In a file list: go up a folder.],
  [Letters], [As shown on the key lines: E, R, W, C, F, N, S, Q.],
)
]

#section("Joining Your WiFi Network")[
The FujiNet keeps the name and password of one WiFi network and joins it whenever it starts. You set
them up once, with this screen. If CONFIG did not show it to you on its own, get to it from the main
screen by pushing #typed("C") (Info & WiFi) and then #typed("S") (Change WiFi network).

CONFIG has the FujiNet look for networks, and lists those it can hear, strongest first, with a
signal meter and the strength in dBm (nearer zero is stronger). The FujiNet hears only networks on
the 2.4 GHz band.

#step[Move the bar to your network and push RETURN.]

If your network does not announce its name, it will not be listed. Move the bar to #scr("<Enter a
network name>") at the bottom of the list, push RETURN, type the name exactly (capitals count) and
push RETURN.

If you don't see your network, push #typed("R") to look again. To leave this screen without joining
a network, push #key[ESC].

#step[CONFIG asks for the network's password. Type it, exactly, and push RETURN. CONFIG shows an
asterisk for each character. If your network has no password, just push RETURN.]

#crt("wifi-password", rows: (19, 24), cols: (0, 79))

CONFIG then shows "Connecting to" and the network's name while the FujiNet joins it. The
information line keeps you posted: #scr("PLEASE WAIT...(ESC TO ABORT)"), and then
#scr("CONNECTION SUCCESS!") and the main screen. If the FujiNet cannot join the network you will
see #scr("CONNECT FAILED") or #scr("UNABLE TO CONNECT"), and CONFIG goes back to the list: check the
password and try again. Joining can take up to 50 seconds; #key[ESC] gives up.

The FujiNet remembers the network. You will not see this screen again unless you ask for it, or the
network goes away.
]

#wide(pictorial(caption: [Choosing a WiFi network.], crt("wifi-scan", width: 6.2in)))

#section("Host Slots")[
A host is a place disk images come from. The FujiNet has eight host slots, each holding the name of
one host. Slot 1 is normally the microSD card, called SD, and two public FujiNet servers on the
Internet are set up in slots 2 and 3:

#align(center, block(scr("1 SD") + linebreak() + scr("2 tnfs.fujinet.online") + linebreak() + scr("3 apps.irata.online")))

#sub("Changing a Host Slot")
#step[On the main screen, pick the host slot with the arrow keys, or with its number on the main
keyboard.]

#step[Push #typed("E"). The information line asks for the host name, and the slot's line turns to
reverse video for you to type in. Type the host's name and push RETURN.]

#crt("host-edit", rows: (0, 10), cols: (0, 79))

Push #key[ERASE] to clear the line and start over, or #key[ESC] to leave the slot as it was. Pushing
RETURN on an empty slot starts the editing too.

What you type depends on the kind of host:

#stable((1.55in, 1fr),
  th[You Type], th[For],
  [#scr("SD")], [The microSD card in the FujiNet.],
  [#scr("tnfs.fujinet.online")], [A TNFS server (a plain name means TNFS).],
  [#scr("http://host/path/")], [A web server's folder (https:// works too).],
  [#scr("ftp://host/path/")], [An FTP server.],
  [#scr("smb://host/share/")], [A Windows or Samba share.],
  [#scr("nfs://host/export/")], [An NFS server.],
)

A name can be up to 31 characters. If you change the name in a slot, any drives using disk images
from that host are emptied.

#sub("The Public Servers")
tnfs.fujinet.online and apps.irata.online are run by FujiNet owners for everyone's use, and hold
software for many computers in folders named for them; look in the H89 folder. Like all TNFS hosts
on the Internet, they are read only: you can put their disk images in drives to read, but to write
on one, copy it to your microSD card first (see "Copying a File," Page 6-9).
]

#section("Browsing a Host")[
#step[On the main screen, pick a host slot and push RETURN.]

CONFIG has the FujiNet open the host and lists what is in it, a page of seventeen names at a time.
Names ending in a slash (#scr("/")) are folders. The top line of the pane shows the host and the
folder you are in.

#stable((0.95in, 1fr),
  th[Key], th[Does],
  [#key[RETURN]], [Open the folder, or choose the disk image.],
  [#key[BACK SPACE]], [Go up to the folder above.],
  [#key[\<] #key[\>] or arrows], [Previous or next page.],
  [#typed("F")], [Show only names that match a pattern.],
  [#typed("N")], [Make a new disk image here.],
  [#typed("C")], [Copy the selected file to another host.],
  [#key[ESC]], [Back to the main screen.],
)

A name marked with a #scr("+") is a link to another host; RETURN on it takes you there.

#sub("Showing Only Some Names")
Push #typed("F"), type a pattern, and push RETURN. An asterisk stands for any characters:
#typed("F*") shows the names that begin with F, and #typed("*.H8D") shows the H89 disk images.
Folders are always shown, so you can still move about. To show everything again, push F, then
#key[ERASE], then RETURN.
]

#wide(pictorial(caption: [The microSD card's top folder.], crt("browse-sd", width: 6.2in, rows: (0, 24))))

#section("Putting a Disk Image in a Drive", newpage: true)[
#step[Browse to the disk image you want, and push RETURN.]

CONFIG shows the image's host, folder, name, size and date, and the eight drive slots, and asks
#scr("Put it in which drive?")

#step[Pick a drive slot with the arrow keys or its number. Then push RETURN to put the image in
read only, or #typed("W") to put it in read/write.]

Choose read only unless you mean to write on the disk. A read-only image cannot be harmed, and an
image can be read only by more than one drive, or more than one FujiNet, at once. Images on public
servers can only be read.

CONFIG takes you back to the folder you were in, so you can choose another image for another drive.
The FujiNet notes your choice at once, but the drive is put in service only when you leave CONFIG
with #key[ESC] (see "Leaving CONFIG").

Use .H8D disk images only. The FujiNet drives under HDOS and CP/M read the H-17 diskette format, and
refuse anything else (see Page 7-1).
]

#wide(pictorial(caption: [Choosing a drive for a disk image.], crt("mount-image", width: 6.2in)))

#section("The Drive Slots")[
On the main screen, push #key[TAB] (or move down past host slot 8) to work in the drive slots. Each
line shows the slot's number, R/O or R/W, the disk image's name, and the host it comes from. The
information line shows the full name of the selected image.

#stable((0.95in, 1fr),
  th[Key], th[Does],
  [#typed("E")], [Eject: empty the drive slot.],
  [#typed("R")], [Make the drive read only.],
  [#typed("W")], [Make the drive read/write.],
  [#key[ERASE]], [Eject every drive.],
  [#key[TAB]], [Back to the host slots.],
)

Under HDOS, dismount a FujiNet drive before you change what is in it (see Page 7-3).
]

#wide(pictorial(caption: [Two drives in service: one read/write, one read only.], crt("drives", width: 6.2in)))

#section("New Disk Images")[
To make a new, empty disk image on a host you can write to (the microSD card, or your own server):

#step[Browse to the folder where it should go, and push #typed("N").]

#crt("newdisk-size", rows: (19, 24))

#step[Push #typed("1") for a 100K image. That is the size of an H-17-1 diskette and the only size
the FujiNet drives use. (The other sizes are for other computers.)]

#step[Type a name for the image, ending in .H8D, and push RETURN. Then pick a drive slot for it and
push RETURN.]

A new image is blank. Before HDOS can use it, it must be initialized; before CP/M can, its directory
must be cleared. See "Blank Disk Images" on Page 7-9.
]

#section("Copying a File")[
CONFIG can have the FujiNet copy a file from one host to another; the file goes straight from host
to host, without passing through the Computer. Use it to bring a disk image from a public server to
your microSD card, where you can write on it.

#step[Browse to the file and push #typed("C").]

#step[CONFIG asks #scr("Copy to which host?") Pick the host to copy to and push RETURN.]

#step[Browse to the folder where the copy should go, and push #typed("C") again.]

CONFIG shows #scr("Copying... this can take a while.") and then takes you back to where you
started. The host you copy to must be one you can write to.
]

#wide(pictorial(caption: [Choosing where a copy goes.], crt("copy-host", width: 6.2in)))

#section("The FujiNet's Information")[
On the main screen, push #typed("C") (Info & WiFi). CONFIG shows the network the FujiNet has joined,
its own name and address on the network, the address of your router and name server, its MAC
address (which some routers ask for), the version of its firmware, and the versions of CONFIG and
the library under it.

#crt("info", rows: (1, 14), cols: (0, 45))

The IP address is the one to type into a web browser on another computer to reach the FujiNet's
web page (see Page 8-2).

On this screen, #typed("S") changes the WiFi network (see "Joining Your WiFi Network") and
#typed("R") joins the same network again. Any other key takes you back to the main screen.
]

#section("Leaving CONFIG", balance: false)[
When the drive slots hold what you want, push #key[ESC] on the main screen. CONFIG puts each drive
in service and marks it #scr("OK"), or #scr("FAIL") if the disk image could not be opened. Then it
gives the Computer back to HDOS or CP/M and lists the drives:

#grid(columns: (1fr, 1fr), column-gutter: 1em,
  session("exit-hdos", rows: (0, 3), cols: (0, 26)),
  session("exit-cpm", rows: (0, 3), cols: (0, 26)))

HDOS prints the list in capitals, as it prints everything unless you tell it otherwise. The numbers
are the FujiNet's drive slots. Under HDOS, slot 1 is FN0:, slot 2 is FN1:, and so on. Under CP/M,
FNDISK shows you which letter each slot has (Page 7-6).

If a drive could not be put in service, CONFIG says #scr("A drive could not be mounted.") and waits
for a key. The usual reasons are an image that has gone from its host, a host that cannot be
reached, or an image put in read/write on a host that can only be read.

To leave CONFIG without putting drives in service, push #typed("Q") (Quit) instead. Your choices are
kept on the FujiNet for the next time.

#sub("When the FujiNet Starts")
Each time you turn on the Computer or push #key[SHIFT] and #key[RESET], the FujiNet starts afresh.
It joins your WiFi network and remembers its host slots and your choices of disk images. But as it
comes from the factory, it does not put the drives in service by itself: it waits for CONFIG. So,
after a reset, run CONFIG and push #key[ESC] before you use the FujiNet drives.

If you would rather the FujiNet put your drives in service by itself, open its web page (Page 8-2),
set "Enable CONFIG boot disk" to "No," and save. From then on, after a reset, you can go straight
to FN.DVD or FNDISK. CONFIG is still there whenever you want to change something.
]
