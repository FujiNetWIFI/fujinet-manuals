#import "../lib.typ": *

#booklet.update(false)
#bandfile.update(none)
= Directories, Mount and Boot <boot>

A FujiNet host is a place files live: the memory card, a TNFS server, an
HTTP or SMB share. The adapter holds eight of them in _host slots_, numbered
from 0, and the commands below take a slot number. This section lists a
directory, then does what CONFIG does when you choose a game: mounts it,
streams it into the cartridge, and hands the console over.

== Listing a directory

#steps(
  [*MOUNT_HOST* (`$F9`), one byte: the host slot. For the memory card this
   is a formality; for a TNFS server it makes the connection.],
  [*OPEN_DIRECTORY* (`$F7`), one byte, the slot; then the path as the
   payload, padded with NULs to exactly *256 bytes*. A shorter payload is
   refused. A second string after the path’s NUL, inside the 256, is a
   filter such as `*.BIN`.],
  [*READ_DIR_ENTRY* (`$F6`), two bytes: the longest name to return, and 0.
   The reply is the name, NUL-terminated, with a `/` on the end of a folder.
   After the last entry the reply is two bytes of `$7F`.],
  [*CLOSE_DIRECTORY* (`$F5`), no parameters.],
)

#shot("fujidir", [fujidir: the first ten of the book’s own programs])

#excerpt-at(auto, "listings/asm/fujidir.asm", "NEXT:   FNBEGIN FNDFUJI, FCRDIR, 2", to: "SHOW:")

#important[Ask for 36 characters at least. The adapter adds a folder’s
`/` only when it fits within the length asked for, so a short maximum can
turn a long folder name into what looks like a file.]

`SET_DIRECTORY_POSITION` (`$E4`) moves to an entry by number, which is how
CONFIG pages through a long folder without reading every entry each time.

== Mounting an image

The boot is three commands and a wait:

#steps(
  [*MOUNT_HOST* (`$F9`): the slot the file is on.],
  [*SET_DEVICE_FULLPATH* (`$E2`): three bytes -- the device slot (0), the
   host slot and the mode (1, read) -- then the path, padded to 256 bytes.],
  [*MOUNT_IMAGE* (`$F8`): two bytes, the device slot and the mode. Before it
   answers, the network chip streams the image to the cartridge over the
   USB link’s DBC device, and the game chip stages it in the half of its
   memory it is not serving from.],
  [Wait until BOOT_STATE (`$2C06`) says READY.],
)

#excerpt-at(auto, "listings/runtime/fujiboot.asm", "; ---- SET_DEVICE_FULLPATH", to: "; ---- MOUNT_IMAGE")

#tbl((0.6in, 1.0in, 1fr),
  [*Value*], [*BOOT_STATE*], [*Means*],
  [`0`], [IDLE], [nothing staged],
  [`1`], [XFER], [the image is coming: BOOT_PCT, `$2C07`, says how much],
  [`2`], [READY], [staged and checked: the swap may be armed],
  [`$80`], [FAILED], [BOOT_ERR, `$2C08`, says why: 1 too big, 2 cut short, 3 not a size the cartridge can map, 4 the store busy],
)

The image may be up to 8,192 bytes: a smaller one (a 2K or 4K game) is
padded with `$FF`. A bigger one must have the shape of protocol 2, exactly
8,192 + _k_ × 2,048 bytes and the claim (Section 15); anything else fails
with BOOT_ERR 3.

#excerpt-at(auto, "listings/runtime/fujiboot.asm", "; ---- wait for the staged image", to: "; ---- ready: arm and swap")

#note[In MAME the image arrives all at once, inside MOUNT_IMAGE, and the
progress bar jumps from 0 to 100. On the cartridge it fills as the bytes
come.]

== The swap

The console cannot be told to "jump to the new cartridge": as far as it
knows the cartridge never changes. So the program arms the cartridge,
leaves the cartridge’s address space altogether, and from RAM reads the one
address that makes the game chip change images:

#steps(
  [Write BOOTLOCK (`$11`) = `$B5`. Only a READY image can be armed.],
  [Copy the 11-byte stub to RAM at `$18E0` and jump to it.],
  [The stub clears the status word, reads `$2DFE` through a pointer at
   `$18E9`, and the game chip flips to the staged image before the next
   read.],
  [The stub jumps to `$0000`, the new image’s header.],
)

#excerpt-at(auto, "listings/runtime/fujiboot.asm", "READY:  SETSTR  BOOTG", to: "; ---- helpers")

The stub’s bytes are `20 92 93 0C 98 E9 1F 00 00 2D FE`. It must run from
RAM: the instruction that reads `$2DFE` would otherwise be fetched from the
very image it replaces.

== After the swap

What the new image finds depends on its claim (Section 3):

- *An image with the claim* -- a FujiNet program -- finds the mailbox alive,
  and the status page and reply window as the program before left them: the
  same ACKSEQ, `F` and `N`, the version. It can begin a transaction at once.
- *An image without it* -- any of the console’s own games -- kills the
  mailbox for the rest of the session. The hotspots become plain ROM
  addresses, so the game can read anything it likes.

To leave either and come back to CONFIG, press the cartridge’s RESET (it
restarts both of its chips, and the game chip serves CONFIG again), then the
console’s.

#shots(("fujiboot", [fujiboot, after booting `hello.bin`]),
  caption: [The swap: `fujiboot`’s screen is replaced by the program it booted])
