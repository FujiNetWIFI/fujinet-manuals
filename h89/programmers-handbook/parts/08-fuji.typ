#import "../lib.typ": *
#import "../prog.typ": *

#chapter(8, "The FujiNet Device")

#section("General")[
Device 70H is the FujiNet itself. Through it a program can ask how the FujiNet is connected, join
another WiFi network, change the eight host slots and the eight drive slots, browse a host's
directories, mount disk images, keep a few bytes of its own on the FujiNet (an *app key*), and use
the FujiNet as a calculator for jobs too big for the H89: base64, cryptographic hashes and QR codes.
It answers 57 commands on the H89, and this chapter gives each a card.

The FujiNet keeps its settings in its configuration file, on its own flash or the microSD card, and
the commands that change them save the file at once. So a program that changes a host slot, or the
WiFi network, changes it for CONFIG, for FNDISK and for every program after it. Say so to the user
before doing it.
]

#section("The Examples in This Chapter")[
The examples come from two programs, EXFUJI.ASM and EXFUJI.C, which send every command in this
chapter in turn, in the order of the cards, and print what came back. Both were run under HDOS and
CP/M on FujiNet Go H89, with fujinet-pc as the FujiNet, and the bytes under each card are the
assembly version's, under HDOS.

A few things in those bytes come from the test set-up rather than from a real card:

- The WiFi network is fujinet-pc's stand-in: it is always "Dummy Cafe", always connected, and a scan
  finds "Dummy Cafe 0" to "Dummy Cafe 15". Cards whose replies show this are tagged STAND-IN WIFI.
- The FujiNet's name is the name of the computer fujinet-pc ran on (TMA-3), and its address is
  127.0.0.1. On a real card, both come from your network.
- The host slots are those of the test configuration: SD, tnfs.fujinet.online, apps.irata.online.
  The SD card is a directory on that computer, holding a `test` directory with three files.

The examples run one after another, so some depend on those before them: the directory examples
need the SD host mounted, and the drive examples use the `test` directory. Each card says what it
needs.
]

#section("Adapter and WiFi", balance: false)[
#cmdcard("Get Adapter Configuration", dev: 0x70, cmd: 0xE8, equ: "FUJI_GET_ADAPTERCONFIG",
  tags: ("Stand-in WiFi",),
  lines: (("Fields", [none]), ("Payload", [none]),
    ("Reply", [140 bytes: the network, the FujiNet's name and addresses, the firmware version])))
How the FujiNet is connected. FNHELLO (Chapter 4) is built round this command. The reply is
fujinet-lib's `AdapterConfig`:

#fields-table(
  [0], [33], [The network's name (SSID), padded with zeros. "NOT CONNECTED" if there is none.],
  [33], [64], [The FujiNet's host name. Empty if not connected.],
  [97], [4], [Its IP address, a byte at a time, most significant first: 192, 168, 1, 89.],
  [101], [4], [The gateway (router).],
  [105], [4], [The netmask.],
  [109], [4], [The name server (DNS).],
  [113], [6], [The FujiNet's MAC address.],
  [119], [6], [The access point's MAC address (BSSID).],
  [125], [15], [The firmware's version, ending in a zero (at most 14 characters).],
)
#examples("fuji.get_adapterconfig")

#cmdcard("Get Adapter Configuration, Extended", dev: 0x70, cmd: 0xC4,
  equ: "FUJI_GET_ADAPTERCONFIG_EXTENDED", tags: ("Stand-in WiFi",),
  lines: (("Fields", [none]), ("Payload", [none]),
    ("Reply", [240 bytes: the 140 above, then the addresses as text])))
The same, followed by the addresses already written out, which saves an H89 program the trouble:

#fields-table(
  [0], [140], [As FUJI_GET_ADAPTERCONFIG.],
  [140], [16], [The IP address as text, "192.168.1.89", ending in a zero.],
  [156], [16], [The gateway, as text.],
  [172], [16], [The netmask, as text.],
  [188], [16], [The name server, as text.],
  [204], [18], [The MAC address, "24:6F:28:1A:89:01".],
  [222], [18], [The access point's MAC address.],
)
The text fields are filled in even when the FujiNet is not connected (with zeros).
#examples("fuji.get_adapterconfig_extended")

#cmdcard("Get WiFi Status", dev: 0x70, cmd: 0xFA, equ: "FUJI_GET_WIFISTATUS",
  tags: ("Stand-in WiFi",),
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [1 byte: 3, connected; 6, not])))
Whether the FujiNet is on its network. The firmware only ever answers 3 (connected) or 6 (not
connected). fujinet-lib's `enum WifiStatus` has names for 1, 3, 4 and 5, but not for 6, so compare
with 3.
#examples("fuji.get_wifistatus")

#cmdcard("Get WiFi Enabled", dev: 0x70, cmd: 0xEA, equ: "FUJI_GET_WIFI_ENABLED",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [1 byte: 1 if WiFi is turned on])))
Whether WiFi is turned on in the FujiNet's settings (it can be turned off from its web page).

#warning[fujinet-lib's `fuji_get_wifi_enabled()` returns the answer of the *last* successful call
if this one fails, without saying it failed. Make the call with `fuji_bus_call()` if you need to
know.]
#examples("fuji.get_wifi_enabled")

#cmdcard("Scan for Networks", dev: 0x70, cmd: 0xFD, equ: "FUJI_SCAN_NETWORKS",
  tags: ("Stand-in WiFi",),
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [1 byte: how many networks were found])))
Looks for WiFi networks within reach, and answers how many it found. FUJI_GET_SCAN_RESULT then gives
them one at a time. On the card, the scan takes a few seconds, and drops the FujiNet's own
connection while it looks: don't scan while network channels are open.
#examples("fuji.scan_networks")

#cmdcard("Get Scan Result", dev: 0x70, cmd: 0xFC, equ: "FUJI_GET_SCAN_RESULT",
  tags: ("Stand-in WiFi",),
  lines: (("Fields", [1 byte: which network, from 0]), ("Payload", [none]),
    ("Reply", [34 bytes: the network's name, then its signal strength])))
One network from the last scan:

#fields-table(
  [0], [33], [The network's name, padded with zeros.],
  [33], [1], [Its signal strength in dBm, a signed byte: -48 (D0H) is strong, -84 weak.],
)
NAK if the number is not less than the count the last scan gave, or if there has been no scan.
#examples("fuji.get_scan_result")

#cmdcard("Get SSID", dev: 0x70, cmd: 0xFE, equ: "FUJI_GET_SSID",
  lines: (("Fields", [none]), ("Payload", [none]),
    ("Reply", [97 bytes: the saved network name, then its password])))
The network the FujiNet is set to join, and its password, as saved:

#fields-table(
  [0], [33], [The network's name, padded with zeros.],
  [33], [64], [Its password, in plain text, padded with zeros.],
)

#caution[The password comes back as it is. Don't show it on the screen, or keep it in a file.]
#examples("fuji.get_ssid")

#cmdcard("Set SSID", dev: 0x70, cmd: 0xFB, equ: "FUJI_SET_SSID", tags: ("Stand-in WiFi",),
  lines: (("Fields", [1 byte: 0 (not used, but send it)]),
    ("Payload", [97 bytes: network name (33), password (64), each ending in a zero]),
    ("Reply", [ACK])))
Saves a new network and password, and joins it. The payload has the layout of FUJI_GET_SSID's reply;
send all 97 bytes, with zeros after each string, because a short payload leaves the rest of the
FujiNet's copy as it was in memory.

ACK means the FujiNet has started to join, not that it has joined: a wrong password is accepted and
saved. Wait a few seconds, then ask FUJI_GET_WIFISTATUS.

#warning[If the card's radio refuses at once, the FujiNet sends *two* NAKs. Take the whole of the
second one before the next request (the book's `fn_call` does). fujinet-pc's stand-in network always
accepts, so the example shows an ACK.]
#examples("fuji.set_ssid")
]

#section("Host Slots", balance: false)[
The FujiNet keeps eight *host slots*, numbered 0 to 7 on the bus (CONFIG shows them as 1 to 8).
Each holds the name of a place disk images come from: `SD` for the microSD card, a TNFS server's
name, or a URL such as `smb://den-pc/images`. A host is *mounted* before its directories can be read
or its images used.

#cmdcard("Read Host Slots", dev: 0x70, cmd: 0xF4, equ: "FUJI_READ_HOST_SLOTS",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [256 bytes: 8 names of 32 bytes])))
All eight host names, each in 32 bytes padded with zeros, slot 0 first. An empty slot is all zeros.

#warning[With fujinet-lib, always ask for all eight slots (`fuji_get_host_slots(slots, 8)`). The
reply is 256 bytes whatever you ask for, and a smaller buffer makes the call fail.]
#examples("fuji.read_host_slots")

#cmdcard("Write Host Slots", dev: 0x70, cmd: 0xF3, equ: "FUJI_WRITE_HOST_SLOTS",
  lines: (("Fields", [none]), ("Payload", [256 bytes: 8 names of 32]), ("Reply", [ACK])))
Replaces all eight host names and saves them. A slot whose name changes is unmounted, and so are the
others. The usual way to change one slot is to read all eight, change one, and write them back, as
the example does.

Send all 256 bytes: the FujiNet does not clear its buffer first, so a short payload fills the last
slots with whatever was in its memory.
#examples("fuji.write_host_slots")

#cmdcard("Mount Host", dev: 0x70, cmd: 0xF9, equ: "FUJI_MOUNT_HOST",
  lines: (("Fields", [1 byte: the host slot, 0 to 7]), ("Payload", [none]), ("Reply", [ACK])))
Connects to the host in a slot, so its directories can be read and its images mounted. For a TNFS or
other network host this reaches out over the network, and may take a moment; for `SD` it is
immediate. NAK if the slot is empty, or the host cannot be reached.

Once a slot has been mounted, mounting it again does nothing, even if the server has gone away since.
#examples("fuji.mount_host")

#cmdcard("Unmount Host", dev: 0x70, cmd: 0xE6, equ: "FUJI_UNMOUNT_HOST", tags: ("NAK",),
  lines: (("Fields", [1 byte: the host slot]), ("Payload", [none]), ("Reply", [ACK, or NAK])))
Disconnects from a host, first unmounting every drive slot that uses it.

#warning[The SD host cannot be unmounted: the FujiNet answers NAK --- but only *after* it has emptied
every drive slot that used the SD card. The example shows it. Only a host mounted with
FUJI_MOUNT_HOST can be unmounted; one mounted by FUJI_MOUNT_ALL or FUJI_COPY_FILE NAKs.]
#examples("fuji.unmount_host")

#cmdcard("Set Host Prefix", dev: 0x70, cmd: 0xE1, equ: "FUJI_SET_HOST_PREFIX",
  lines: (("Fields", [1 byte: the host slot]),
    ("Payload", [a directory, ending in a zero (at most 256 bytes)]), ("Reply", [ACK])))
Sets a host's *current directory*, which the FujiNet puts in front of every path used on that host
afterwards (directory listings, image names). A path beginning with `/` replaces the prefix; any
other is added to it, like `cd` on a modern computer; an empty one clears it. The prefix is not
saved, and is lost when the FujiNet restarts.

Send the zero after the path: the FujiNet does not clear its buffer.
#examples("fuji.set_host_prefix")

#cmdcard("Get Host Prefix", dev: 0x70, cmd: 0xE0, equ: "FUJI_GET_HOST_PREFIX",
  lines: (("Fields", [1 byte: the host slot]), ("Payload", [none]),
    ("Reply", [256 bytes: the prefix, ending in a zero])))
A host's current prefix. Everything after the zero is left over from the FujiNet's memory, as the
example's bytes show: stop at the zero.
#examples("fuji.get_host_prefix")

#cmdcard("Set Host Prefix (clearing it)", dev: 0x70, cmd: 0xE1)
An empty path clears the prefix. The example sends just the zero.
#examples("fuji.set_host_prefix.clear")
]

#section("Directories", balance: false)[
A program can list a mounted host's directories, a name at a time, as CONFIG does. One directory may
be open at a time on the whole FujiNet; opening another closes the first.

#cmdcard("Open Directory", dev: 0x70, cmd: 0xF7, equ: "FUJI_OPEN_DIRECTORY",
  lines: (("Fields", [1 byte: the host slot]),
    ("Payload", [the path, a zero, and optionally a pattern and a zero]), ("Reply", [ACK])))
Opens a directory on a mounted host for FUJI_READ_DIR_ENTRY. The path is relative to the host's
prefix. After the path's zero may come a pattern such as `*.H8D`, which only names matching it are
listed; without one, every name is. NAK if the host is not mounted (FUJI_MOUNT_HOST first), or the
directory cannot be opened.

#warning[The FujiNet reads whatever follows the path's zero as the pattern, up to the end of the
payload. Send the path and its zero and no more (as the Z80 example does), or clear the rest of the
buffer first: fujinet-lib's `fuji_open_directory()` always sends 256 bytes, so the C example clears
a 256-byte buffer before copying the path into it. `fuji_open_directory_filter()` with an empty
filter sends the caller's memory after the path, and the FujiNet takes that as the pattern.]
#examples("fuji.open_directory")

#cmdcard("Read Directory Entry", dev: 0x70, cmd: 0xF6, equ: "FUJI_READ_DIR_ENTRY",
  lines: (("Fields", [2 bytes: the reply's length, 1 to 255; 0 (or 80H, below)]),
    ("Payload", [none]), ("Reply", [that many bytes: the next name])))
The next name in the open directory, padded with zeros to the length asked for. A directory's name
ends in `/` if there is room. At the end of the directory the reply starts with 7FH 7FH. The example
reads the `test` directory's three names and then the end; here are the first and the last:
#examples("fuji.read_dir_entry", only: (0, 3))

#cmdcard("Read Directory Entry, with Details", dev: 0x70, cmd: 0xF6,
  lines: (("Fields", [2 bytes: the length, at least 14; 80H]),
    ("Reply", [a 12-byte header, then the name])))
With 80H in the second field, each name comes after a header of details:

#fields-table(
  [0], [1], [Year the file was changed, counting from 1970.],
  [1], [1], [Month, 1 to 12.],
  [2], [1], [Day, 1 to 31.],
  [3], [3], [Hour, minute, second (the FujiNet's local time).],
  [6], [4], [The file's size in bytes, low byte first.],
  [10], [1], [Flags: 01H a directory, 02H the name was cut short.],
  [11], [1], [The kind of image: 0 unknown (including .IMG), 2 a ROM, 3 an .IMD.],
  [12], [], [The name, ending in a zero.],
)

#warning[Ask for at least 14 bytes with 80H. The FujiNet takes 12 from the length for the header in an
8-bit sum, so a smaller length wraps round and the reply is cut off in the middle of the header. And
never send C0H in the second field: it asks for a "block mode" the H89 cannot take, and with no
entries per block the firmware divides by zero and stops.]

#note[The example ran on fujinet-pc, which (unlike the card) cannot find the details of a file in a
directory below the top of its SD card: its header reads 1969-12-31, size 0. On the card, the date
and size are those of the file.]
#examples("fuji.read_dir_entry.ext")

#cmdcard("Get Directory Position", dev: 0x70, cmd: 0xE5, equ: "FUJI_GET_DIRECTORY_POSITION",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [2 bytes: the entry number, low first])))
Where the next FUJI_READ_DIR_ENTRY will read from, counting from 0. CONFIG keeps it to go back a page.
NAK if no directory is open.
#examples("fuji.get_directory_position")

#cmdcard("Set Directory Position", dev: 0x70, cmd: 0xE4, equ: "FUJI_SET_DIRECTORY_POSITION",
  lines: (("Fields", [a word: the entry number]), ("Payload", [none]), ("Reply", [ACK])))
Moves to an entry, so the next read returns it. The example goes back to entry 1.
#examples("fuji.set_directory_position")

#cmdcard("Close Directory", dev: 0x70, cmd: 0xF5, equ: "FUJI_CLOSE_DIRECTORY",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [ACK])))
Closes the open directory, if there is one.
#examples("fuji.close_directory")
]

#section("Drive Slots", balance: false)[
The FujiNet has eight *drive slots*, numbered 0 to 7 on the bus, which are the disk drives of
Chapter 9: slot 0 is device 31H, slot 7 is 38H. Each names an image (a host slot and a path) and how
it may be used (read only, or read and write). Putting an image in a drive is two steps: name it
with FUJI_SET_DEVICE_FULLPATH, then *mount* it with FUJI_MOUNT_IMAGE. FNDISK and FN.DVD then see it
as a drive.

#caution[Changing a drive slot that FNDISK or FN.DVD is using changes the drive under it. Unmount the
drive in HDOS or CP/M first, or warn the user.]

#cmdcard("Read Drive Slots", dev: 0x70, cmd: 0xF2, equ: "FUJI_READ_DEVICE_SLOTS",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [304 bytes: 8 slots of 38])))
All eight drive slots, slot 0 first, each fujinet-lib's `DeviceSlot`:

#fields-table(
  [0], [1], [The host slot the image is on; FFH if the drive is empty.],
  [1], [1], [Mode: 01H read only, 02H read and write; 40H added while the image is mounted.],
  [2], [36], [The image's name, without its directory, ending in a zero.],
)

#note[Stop at the zero in each name: the bytes after it may be the end of the full path, left over,
as in slot 0 of the example (`disk.img`, a zero, then `k.img`). An empty slot reads mode 01H.]
#examples("fuji.read_device_slots")

#cmdcard("Write Drive Slots", dev: 0x70, cmd: 0xF1, equ: "FUJI_WRITE_DEVICE_SLOTS",
  lines: (("Fields", [none]), ("Payload", [304 bytes, as Read Drive Slots]), ("Reply", [ACK])))
Sets each slot's host and mode, and saves them. The names in the payload are *ignored*: only
FUJI_SET_DEVICE_FULLPATH sets a path. The example reads the slots, changes slot 0 to read and write,
and writes them back.

#warning[Send all 304 bytes (the FujiNet does not clear its buffer), and only host slots 0 to 7 or
FFH: the firmware does not check, and FUJI_MOUNT_ALL then reads past the end of its host table. A
host of FFH also drops the slot's path from the saved settings.]
#examples("fuji.write_device_slots")

#cmdcard("Set Drive Slot Path", dev: 0x70, cmd: 0xE2, equ: "FUJI_SET_DEVICE_FULLPATH",
  lines: (("Fields", [3 bytes: drive slot, host slot, mode (01H read, 02H read/write)]),
    ("Payload", [the image's path, ending in a zero]), ("Reply", [ACK])))
Names the image for a drive slot, and saves it. It does not mount it, or check that it exists.

#warning[An empty path does not quite empty the slot. It sets the slot's host to FFH, but the old
path stays, and FUJI_GET_DEVICE_FULLPATH still returns it. A host slot of FFH in the request --- what
FUJI_READ_DEVICE_SLOTS reports for an empty slot --- is refused with NAK, even with an empty path. To
empty a slot, use FUJI_UNMOUNT_IMAGE (below). fujinet-lib's own test program puts an empty slot
back with this command, and fails.]

#note[fujinet-lib's `fuji_set_device_filename(mode, hs, ds, path)` takes its arguments in a different
order from the fields: mode, host, drive. It sends 256 bytes; clear the buffer first.]
#examples("fuji.set_device_fullpath")

#cmdcard("Get Drive Slot Path", dev: 0x70, cmd: 0xDA, equ: "FUJI_GET_DEVICE_FULLPATH",
  lines: (("Fields", [1 byte: the drive slot]), ("Payload", [none]),
    ("Reply", [256 bytes: the full path, padded with zeros])))
The whole path of a drive slot's image. After FUJI_MOUNT_IMAGE, it includes the host's prefix.
#examples("fuji.get_device_fullpath")

#cmdcard("Mount Image", dev: 0x70, cmd: 0xF8, equ: "FUJI_MOUNT_IMAGE",
  lines: (("Fields", [2 bytes: the drive slot; the mode (01H read, 02H read and write)]),
    ("Payload", [none]), ("Reply", [ACK])))
Opens the image a drive slot names and puts it in the drive (device 31H plus the slot). The slot's
host must be mounted first: FUJI_MOUNT_IMAGE does not do it. NAK if the slot is empty, the file
cannot be opened, or read and write is asked of a file that cannot be written.

#warning[Don't mount a file whose name ends in ROM or BIN (or INT, ITV, CHF, NES, SMS, A78, A52 or
ST2). The FujiNet treats it as a cartridge for another computer, and before it answers it
sends the whole file to device FFH, in frames the H89 does not expect, ahead of its reply. The H89's
next replies are then out of step. An H89 disk image named with BIN at the end will meet this.]
#examples("fuji.mount_image")

#cmdcard("Unmount Image", dev: 0x70, cmd: 0xE9, equ: "FUJI_UNMOUNT_IMAGE",
  lines: (("Fields", [1 byte: the drive slot]), ("Payload", [none]), ("Reply", [ACK])))
Takes the image out of a drive, and empties the slot: its path is forgotten, and the settings are
saved without it. To use the image again, name it again.
#examples("fuji.unmount_image")

#cmdcard("Mount All", dev: 0x70, cmd: 0xD7, equ: "FUJI_MOUNT_ALL",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [ACK, or NAK at the first failure])))
Mounts every drive slot that names an image, mounting its host first, as the FujiNet does at power
on. It stops at the first slot that fails, and NAKs; the slots after it are not tried. In the example
there is nothing left to mount (slot 0 was emptied above), so it simply answers ACK.
#examples("fuji.mount_all")

#cmdcard("New Disk", dev: 0x70, cmd: 0xE7, equ: "FUJI_NEW_DISK", tags: ("NAK",),
  lines: (("Fields", [none]),
    ("Payload", [262 bytes: sectors (word), sector size (word), host slot, drive slot, path (256)]),
    ("Reply", [NAK, always])))
Meant to make a new, empty disk image and put it in a drive.

#warning[On the H89 this always fails: the firmware's image code cannot create images for this
computer, and answers NAK. Worse, before it does, it creates an *empty* file of that name on the host
and names it in the drive slot. Delete the file, and empty the slot with FUJI_UNMOUNT_IMAGE, after
trying. To make a blank disk, copy one: `test/blank.h8d` in the example is one (FUJI_COPY_FILE,
next).]
#examples("fuji.new_disk")

#cmdcard("Copy File", dev: 0x70, cmd: 0xD8, equ: "FUJI_COPY_FILE",
  lines: (("Fields", [2 bytes: source host slot, destination host slot, *counting from 1*]),
    ("Payload", [`source|destination`]), ("Reply", [ACK, when the copy is done])))
Copies a file from one host to another, or within one, entirely inside the FujiNet. The H89 waits
for the ACK until the copy is done. The payload is the two paths with a `|` between; if the
destination ends in `/`, the source's name is added to it.

#warning[The host slots count from 1 here, unlike every other command. And the copy fails if either
host has a prefix longer than `/` (FUJI_SET_HOST_PREFIX): clear the prefixes first. The FujiNet does
not check that everything was copied.]

#warning[A large copy can take longer than the 15 seconds that fujinet-lib and the book's library
wait for a reply (Chapter 2). Copying a 161,280-byte disk image from `tnfs.fujinet.online` took
from 14.4 to 18.2 seconds in six runs, and four of them took more than 15. Each time,
`fuji_copy_file()` returned `false` although the copy went on and finished, and its late ACK was
taken as the reply to the program's next request, so every reply after it was one behind. For large
files, raise the limit: `RX_FIRST` in FUJIBUS.INC, or `TIMEOUT_SLOW` in fujinet-lib's
`bus/h89/fuji_bus_call.c` (and rebuild the library). With `TIMEOUT_SLOW` at 60 seconds, fujinet-lib's
own copy test passed under both systems (Chapter 6).]
#examples("fuji.copy_file")
]

#section("Booting", balance: false)[
Two commands concern starting a computer from the FujiNet. Other computers use them; the H89 starts
from its own diskette, and has little use for either.

#cmdcard("Set Boot Mode", dev: 0x70, cmd: 0xD6, equ: "FUJI_SET_BOOT_MODE",
  lines: (("Fields", [1 byte: 0 to 3]), ("Payload", [none]), ("Reply", [ACK])))
Puts a boot image in the first drive (device 31H) at once, read only: 0 the FujiNet's own
`autorun.img`, 1 `/mount-and-boot.img`, 2 the FujiNet project's lobby, 3 `/hisioboot-fujinet.img`.

#warning[On the H89, mode 0's image is an MS-DOS boot disk (the firmware for this bus is shared with
the IBM PC's), which an H89 cannot read --- and it takes the place of whatever FNDISK was using as
drive 31H. Modes 1 and 3 need files the FujiNet does not have, and do nothing. Every mode answers
ACK. FUJI_CONFIG_BOOT with 0 takes the image out again, as the example does next.]
#examples("fuji.set_boot_mode")

#cmdcard("Config Boot", dev: 0x70, cmd: 0xD9, equ: "FUJI_CONFIG_BOOT",
  lines: (("Fields", [1 byte: 0 or 1]), ("Payload", [none]), ("Reply", [ACK])))
Meant to turn the FujiNet's boot-to-CONFIG feature on and off. On the H89 it does one thing: with 0,
when drive slot 0 is empty, it takes a boot image put there by FUJI_SET_BOOT_MODE out of drive 31H.
Otherwise it does nothing at all, and saves nothing.
#examples("fuji.config_boot")
]

#section("App Keys", balance: false)[
An *app key* is a small file, up to 64 bytes, that the FujiNet keeps for a program on its microSD
card: a high score, a player's name, a setting. Any program on any computer can read it back, which
is how the games remember who you are. A key is named by three numbers:

- a *creator* (16 bits, not 0), for the person or group who wrote the program --- choose one of your
  own, and keep to it;
- an *application* (8 bits), for the program;
- a *key* (8 bits), for which of the program's keys.

The examples use creator 4889H, application 01H, key 00H, which the FujiNet keeps in
`/FujiNet/48890100.key` on its SD card. Each read or write is three requests: OPEN, then READ or
WRITE, then CLOSE.

#note[App keys need the microSD card. Without one, OPEN answers NAK.]

#cmdcard("Open App Key", dev: 0x70, cmd: 0xDC, equ: "FUJI_OPEN_APPKEY",
  lines: (("Fields", [none]), ("Payload", [6 bytes: creator (word), application, key, mode, 0]),
    ("Reply", [ACK])))
Chooses the key for the next READ or WRITE, and whether to read (mode 0) or write (mode 1). NAK if
the creator is 0 or there is no SD card. fujinet-lib has no function for this alone (its
`fuji_read_appkey()` and `fuji_write_appkey()` send it themselves), so the C example uses the bus
call.
#examples("fuji.open_appkey")

#cmdcard("Write App Key", dev: 0x70, cmd: 0xDE, equ: "FUJI_WRITE_APPKEY",
  lines: (("Fields", [none]), ("Payload", [the key's bytes, up to 64]), ("Reply", [ACK])))
Writes the key opened for writing, replacing what was there. The payload is the whole of the key;
bytes past 64 are dropped. The key is closed afterwards: open it again to write again.

#warning[A WRITE with no payload empties the key, and answers ACK.]

fujinet-lib's `fuji_write_appkey()` opens the key itself (with the creator and application set by
`fuji_set_appkey_details()`), so the C example's bytes show two exchanges, OPEN and WRITE.
#examples("fuji.write_appkey")

#cmdcard("Open App Key, to Read", dev: 0x70, cmd: 0xDC)
To read a key back, open it again, now with mode 0.
#examples("fuji.open_appkey.read")

#cmdcard("Read App Key", dev: 0x70, cmd: 0xDD, equ: "FUJI_READ_APPKEY",
  lines: (("Fields", [none]), ("Payload", [none]),
    ("Reply", [2-byte length (low first), then that many bytes])))
Reads the key opened for reading. The reply is the key's length and the key. A key that does not
exist reads as length 0: this command never NAKs, so check the length. The key stays open, and may be
read again.
#examples("fuji.read_appkey")

#cmdcard("Close App Key", dev: 0x70, cmd: 0xDB, equ: "FUJI_CLOSE_APPKEY",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [ACK])))
Forgets the open key. fujinet-lib has no function for it. Notice the command byte, DBH, which is
SLIP's ESC: it goes over the bus as the pair DB DD (Chapter 3). The exerciser closes the key after
writing it, and again after reading it.
#examples("fuji.close_appkey")
]

#section("Base64", balance: false)[
Base64 writes any bytes as letters, digits, `+` and `/`, four characters for every three bytes, so
they can travel where only text may: in e-mail, JSON, URLs. The FujiNet does the arithmetic. It
works in four steps --- put the input in, compute, ask the length, take the output --- in one
buffer that encoding and decoding share.

#warning[There is one buffer for both directions, and no command to empty it. Take *all* the output
of one job before starting the next, or what is left is put in front of the next job's input.]

#cmdcard("Base64 Encode: Input", dev: 0x70, cmd: 0xD0, equ: "FUJI_BASE64_ENCODE_INPUT",
  lines: (("Fields", [a word: how many bytes]), ("Payload", [that many bytes]), ("Reply", [ACK])))
Adds bytes to the input. May be sent several times, to encode more than one request can carry.
The example encodes the 12 characters "Heathkit H89".
#examples("fuji.base64_encode_input")

#cmdcard("Base64 Encode: Compute", dev: 0x70, cmd: 0xCF, equ: "FUJI_BASE64_ENCODE_COMPUTE",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [ACK])))
Encodes the input, replacing it with the text. The FujiNet adds a line feed after every 72 characters,
and one at the end.
#examples("fuji.base64_encode_compute")

#cmdcard("Base64 Encode: Length", dev: 0x70, cmd: 0xCE, equ: "FUJI_BASE64_ENCODE_LENGTH",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [4 bytes: the length, low first])))
How long the encoded text is, line feeds included: here 17, sixteen characters and a line feed.
#examples("fuji.base64_encode_length")

#cmdcard("Base64 Encode: Output", dev: 0x70, cmd: 0xCD, equ: "FUJI_BASE64_ENCODE_OUTPUT",
  lines: (("Fields", [a word: how many bytes]), ("Payload", [none]), ("Reply", [that many bytes])))
Takes text from the front of the buffer. NAK if more is asked for than is left. Take a long result in
pieces.
#examples("fuji.base64_encode_output")

#cmdcard("Base64 Decode: Input", dev: 0x70, cmd: 0xCC, equ: "FUJI_BASE64_DECODE_INPUT",
  lines: (("Fields", [a word: how many characters]), ("Payload", [the text]), ("Reply", [ACK])))
Adds base64 text to be decoded. The example gives back the text just made.
#examples("fuji.base64_decode_input")

#cmdcard("Base64 Decode: Compute", dev: 0x70, cmd: 0xCB, equ: "FUJI_BASE64_DECODE_COMPUTE",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [ACK])))
Decodes it, replacing it with the bytes.
#examples("fuji.base64_decode_compute")

#cmdcard("Base64 Decode: Length", dev: 0x70, cmd: 0xCA, equ: "FUJI_BASE64_DECODE_LENGTH",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [4 bytes: the length, low first])))
How many bytes the decoding made.
#examples("fuji.base64_decode_length")

#cmdcard("Base64 Decode: Output", dev: 0x70, cmd: 0xC9, equ: "FUJI_BASE64_DECODE_OUTPUT",
  lines: (("Fields", [a word: how many bytes]), ("Payload", [none]), ("Reply", [that many bytes])))
Takes the decoded bytes: "Heathkit H89" again.
#examples("fuji.base64_decode_output")
]

#section("Hashes", balance: false)[
A *hash* is a short fingerprint of any amount of data: change one bit of the data and the fingerprint
changes completely. Programs use hashes to check that a file arrived intact, and to sign requests to
web services. Working one out takes the H89 a long time; the FujiNet does it at once. Data goes in
with FUJI_HASH_INPUT, as many times as needed; FUJI_HASH_COMPUTE works out the hash; the result
comes back as text or as bytes.

#stable((0.5in, 0.6in, 1fr), size: 7.6pt,
  th[Code], th[Hash], th[Length (bytes, or hex characters)],
  [0], [MD5], [16, or 32],
  [1], [SHA-1], [20, or 40],
  [2], [SHA-256], [32, or 64],
  [3], [SHA-512], [64, or 128],
)

#cmdcard("Hash Input", dev: 0x70, cmd: 0xC8, equ: "FUJI_HASH_INPUT",
  lines: (("Fields", [a word: how many bytes]), ("Payload", [that many bytes]), ("Reply", [ACK])))
Adds data to be hashed. The example hashes "abc", whose hashes are published, so the answer can be
checked.
#examples("fuji.hash_input")

#cmdcard("Hash Compute, Keeping the Input", dev: 0x70, cmd: 0xC3, equ: "FUJI_HASH_COMPUTE_NO_CLEAR",
  lines: (("Fields", [1 byte: the hash, 0 to 3]), ("Payload", [none]), ("Reply", [ACK])))
Works out a hash of the data so far, and keeps the data, so another kind of hash can be made from it.
The example makes the MD5 hash, then (next) SHA-1 from the same data.
#examples("fuji.hash_compute_no_clear")

#cmdcard("Hash Compute", dev: 0x70, cmd: 0xC7, equ: "FUJI_HASH_COMPUTE",
  lines: (("Fields", [1 byte: the hash, 0 to 3]), ("Payload", [none]), ("Reply", [ACK])))
Works out a hash, then empties the data ready for the next.

#warning[Codes 4 and 5 (SHA-224 and SHA-384, which fujinet-lib names) are not available: the
FujiNet answers ACK, and the result is empty.]
#examples("fuji.hash_compute")

#cmdcard("Hash Length", dev: 0x70, cmd: 0xC6, equ: "FUJI_HASH_LENGTH",
  lines: (("Fields", [1 byte: 1 for text, 0 for bytes]), ("Payload", [none]),
    ("Reply", [1 byte: the length])))
How long the result is: here 28H, the 40 hex digits of an SHA-1 hash. Unlike the base64 and QR
lengths, this is one byte.
#examples("fuji.hash_length")

#cmdcard("Hash Output", dev: 0x70, cmd: 0xC5, equ: "FUJI_HASH_OUTPUT",
  lines: (("Fields", [1 byte: 1 for text, 0 for bytes]), ("Payload", [none]),
    ("Reply", [the hash, as text or bytes])))
The hash itself, as lower-case hexadecimal text (no zero at the end) or as bytes. It can be fetched
again, either way. The text here, `a9993e36...`, is the published SHA-1 of "abc", which shows the
data was kept by the compute before.
#examples("fuji.hash_output")

#cmdcard("Hash Output, as Bytes", dev: 0x70, cmd: 0xC5)
The same hash as 20 bytes.
#examples("fuji.hash_output.bin")

#cmdcard("Hash Clear", dev: 0x70, cmd: 0xC2, equ: "FUJI_HASH_CLEAR",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [ACK])))
Empties the data, keeping the last result.
#examples("fuji.hash_clear")
]

#section("QR Codes", balance: false)[
The FujiNet can turn text into a QR code, the square of dots a telephone's camera reads, so an H89
program can show a web address that a visitor can follow. The H19's graphics characters draw one
nicely: a quarter-square character for each two-by-two block of dots.

#cmdcard("QR Code Input", dev: 0x70, cmd: 0xBC, equ: "FUJI_QRCODE_INPUT",
  lines: (("Fields", [a word: how many bytes]), ("Payload", [that many bytes]), ("Reply", [ACK])))
Adds text to be encoded. The example uses `HTTPS://FUJINET.ONLINE/`. In capitals, it fits the QR code's
compact alphanumeric mode, which gives the smallest code, 21 by 21.
#examples("fuji.qrcode_input")

#cmdcard("QR Code Encode", dev: 0x70, cmd: 0xBD, equ: "FUJI_QRCODE_ENCODE",
  lines: (("Fields", [3 bytes: version (0 = smallest that fits), error correction (0 to 3), shorten (0)]),
    ("Payload", [none]), ("Reply", [ACK])))
Makes the code, and empties the input. The error correction is 0 (L, 7% of the code can be lost) to
3 (H, 30%). With "shorten" not 0, the FujiNet first registers the text as a short web address on its
own web server and encodes that instead.

#warning[Send all three fields.]
#examples("fuji.qrcode_encode")

#cmdcard("QR Code Length", dev: 0x70, cmd: 0xBE, equ: "FUJI_QRCODE_LENGTH",
  lines: (("Fields", [1 byte: the form wanted]), ("Payload", [none]),
    ("Reply", [4 bytes: the length, low first])))
How long the code is in the form asked for, which it is rendered in: 0, one bit per dot, rows run
together; 2, a bitmap, each row in whole bytes, leftmost dot in the top bit; 1 ANSI text, 3 SVG, 4
and 5 the Atari's and Commodore's character sets.

For forms 0 and 2 the FujiNet puts a byte in front, the number of dots on a side. So the example's
length is 64: that byte, then 21 rows of 3 bytes. (Notice the reply's checksum, C0H, sent as the
escape pair DB DC.)
#examples("fuji.qrcode_length")

#cmdcard("QR Code Output", dev: 0x70, cmd: 0xBF, equ: "FUJI_QRCODE_OUTPUT",
  lines: (("Fields", [a word: how many bytes]), ("Payload", [none]), ("Reply", [that many bytes])))
Takes the code, from the front: here 15H (21), then the rows. NAK if more is asked for than is left.
#examples("fuji.qrcode_output")
]

#section("Odds and Ends", balance: false)[
#cmdcard("Generate GUID", dev: 0x70, cmd: 0xBB, equ: "FUJI_GENERATE_GUID",
  lines: (("Fields", [none]), ("Payload", [none]),
    ("Reply", [37 bytes: a new random identifier, as text, ending in a zero])))
A new universally unique identifier (a version 4 UUID), such as a program might use to name itself
to a server.
#examples("fuji.generate_guid")

#cmdcard("Random Number", dev: 0x70, cmd: 0xD3, equ: "FUJI_RANDOM_NUMBER",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [4 bytes: a random number, low first])))
A random 32-bit number from the ESP32's hardware generator, far better than any an H89 program can
make for itself. The top bit is always 0. fujinet-lib has no function for it.
#examples("fuji.random_number")

#cmdcard("Status", dev: 0x70, cmd: 0x53, equ: "FUJI_STATUS",
  lines: (("Fields", [1 byte (ignored)]), ("Payload", [none]), ("Reply", [4 bytes, all zero])))
On other computers this reports the FujiNet's state. On the H89 it always answers four zero bytes.
#examples("fuji.status")

#cmdcard("Device Ready", dev: 0x70, cmd: 0x00, equ: "FUJI_DEVICE_READY",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [512 bytes of 41H])))
A test left in the firmware: it answers 512 letters A. A program can use it to check that long
replies arrive intact.
#examples("fuji.device_ready")

#cmdcard("Reset", dev: 0x70, cmd: 0xFF, equ: "FUJI_RESET",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [none: the FujiNet restarts])))
Restarts the FujiNet, as switching it off and on would: every drive is unmounted and every network
channel closed, and the FujiNet starts again from its saved settings.

#warning[There is no reply. A program sends RESET, and then waits for its own timeout (`fn_call`
gives up after 15 seconds, and so does fujinet-lib's `fuji_reset()`, which then returns `false`). Wait
a few seconds more before the next request, while the FujiNet starts.]
#examples("fuji.reset")
]

#section("Commands the H89 Does Not Have")[
The firmware's list of commands has others, for other computers; the table below lists them. Sent
to the H89's FujiNet, each is answered with a NAK. Here is the first of them, sent as an example:
#examples("fuji.get_time")
]

// across the page: the notes' long names do not fit a column
#stable((2.6in, 0.8in, 1fr), size: 7.4pt, breakable: false,
  th[Command], th[No.], th[Note],
  [FUJI_GET_TIME], [D2H], [fujinet-lib's `fuji_get_time()` sends it: use the clock (Chapter 12)],
  [FUJI_ENABLE_DEVICE, FUJI_DISABLE_DEVICE], [D5H, D4H], [`fuji_enable_device()`,
    `fuji_disable_device()` send them],
  [FUJI_DEVICE_ENABLE_STATUS], [D1H], [`fuji_get_device_enabled_status()` does not link],
  [FUJI_ENABLE_UDPSTREAM], [F0H], [`fuji_enable_udpstream()` does not link],
  [FUJI_SET_BAUDRATE], [EBH], [],
  [FUJI_SET_HSIO_INDEX, FUJI_SET_SIO_EXTERNAL_CLOCK], [E3H, DFH], [Atari only],
  [FUJI_GET_HEAP], [C1H], [],
  [FUJI_GET_DEVICE1_FULLPATH ... 10], [A0H--A9H], [use FUJI_GET_DEVICE_FULLPATH],
  [FUJI_UPDATE_FIRMWARE], [90H], [update through the USB port (Operation Manual)],
)
