#import "../lib.typ": *
#import "../prog.typ": *

#chapter(9, "The Disk Drives")

#section("General")[
Devices 31H to 38H are the FujiNet's eight disk drives, one for each drive slot (Chapter 8): slot 0
is 31H, slot 7 is 38H. Each reads and writes the image mounted in its slot, sector by sector. FN.DVD
and FNDISK, the Operation Manual's drivers, use them to give HDOS and CP/M their FujiNet drives; a
program can use them directly too, to read an image that is not a disk HDOS or CP/M knows, or to
look at one byte by byte.

#caution[A drive FN.DVD or FNDISK is using belongs to the operating system. Writing its sectors
behind the system's back will confuse it, and may ruin the disk. Read freely; write only to a drive
you mounted yourself.]
]

#section("Sectors and Images")[
The FujiNet knows an image's kind by the end of its name:

- *.IMD* is an ImageDisk image, a copy of a real diskette with its own layout; each sector is the size
  it had on the diskette (128 to 512 bytes), and they are numbered from 0 in order.
- *.ROM, .BIN* and the other cartridge names of Chapter 8's warning are not disks at all. Don't.
- Anything else --- *.H8D*, *.IMG*, no extension --- is a plain file of 512-byte sectors: sector *n*
  is the 512 bytes starting at byte *n* × 512. A 100K H17 image (.H8D) is 200 of them, each holding
  two of the H17's 256-byte sectors.

Sector numbers count from 0. The examples mount the test image `test/disk.img`, whose sector *n* is
filled with the byte *n*, in drive slot 0, so the drive is 31H. Its setup, with three FujiNet
commands from Chapter 8 (mount the SD host, name the image, mount it), is in EXDISK.ASM and EXDISK.C
but not printed here.

fujinet-lib has no functions for the disk drives, so the C examples call `fuji_bus_call()`.
]

#section("The Commands", balance: false)[
#cmdcard("Read Sector", dev: "31H--38H", cmd: 0x52, equ: "DISK_READ",
  lines: (("Fields", [4 bytes: the sector number, low first]), ("Payload", [none]),
    ("Reply", [the sector: 512 bytes (an .IMD sector, its own size)])))
Reads one sector. NAK if no image is mounted, or the sector is past the end. The field may be any
size; the examples send a long, as fujinet-lib's shorthand would.

#note[An .IMD sector that the original diskette could not read is still returned, with ACK; only
DISK_STATUS (below) shows the error.]
#examples("disk.read")

#cmdcard("Write Sector", dev: "31H--38H", cmd: 0x57, equ: "DISK_WRITE",
  lines: (("Fields", [4 bytes: the sector number]), ("Payload", [the sector's bytes]),
    ("Reply", [ACK])))
Writes one sector, at once (the FujiNet flushes it to the file). A short payload is filled out with
zeros. NAK if the image was mounted read-only (FUJI_MOUNT_IMAGE's mode 01H), or the sector is past
the end: the image never grows. The example fills sector 5 with E5H, the byte CP/M formats with, and
reads it back.
#examples("disk.write")
#examples("disk.read.back")

#cmdcard("Put Sector", dev: "31H--38H", cmd: 0x50, equ: "DISK_PUT",
  lines: (("Fields", [4 bytes: the sector number]), ("Payload", [the sector's bytes]),
    ("Reply", [ACK])))
On other computers, a write without verifying. Here it is the same as DISK_WRITE.
#examples("disk.put")

#cmdcard("Status", dev: "31H--38H", cmd: 0x53, equ: "DISK_STATUS",
  lines: (("Fields", [1 byte (ignored)]), ("Payload", [none]), ("Reply", [4 bytes])))
The drive's status, in the Atari's form: a status byte, the controller's status (where an .IMD
sector's error shows: 08H a CRC error, 10H missing, 20H deleted), a timeout, and 0. For a plain image
it is normally 00 FF E0 00 --- even with nothing mounted, so don't use it to see whether a drive has
an image; read sector 0 instead.
#examples("disk.status")

#cmdcard("Format", dev: "31H--38H", cmd: 0x21, equ: "DISK_FORMAT",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [128 bytes: FFH FFH, then zeros])))
Meant to format the disk. It does nothing to the image: the FujiNet answers ACK with a 128-byte "bad
sector list" that says none are bad, and every sector is as it was --- sector 3 still reads 03H, as
the example shows. To blank an image, write its sectors. DISK_FORMAT_MEDIUM (22H) is the same.
#examples("disk.format")
#examples("disk.read.after_format")
#examples("disk.format_medium")

#cmdcard("Read Geometry", dev: "31H--38H", cmd: 0x4E, equ: "DISK_PERCOM_READ",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [12 bytes: the PERCOM block])))
The disk's geometry in the "PERCOM" form some disk controllers used: tracks, step rate, sectors per
track (a word, high byte first), sides less one, density, sector size (a word, high first), drive
present, and three spare bytes. For an .IMD it describes the diskette; for a plain image it is all
zeros.
#examples("disk.percom_read")

#cmdcard("Write Geometry", dev: "31H--38H", cmd: 0x4F, equ: "DISK_PERCOM_WRITE",
  lines: (("Fields", [none]), ("Payload", [12 bytes: a PERCOM block]), ("Reply", [ACK])))
Replaces the geometry the FujiNet reports. It changes nothing else: the image's sectors are still 512
bytes. Reading it back gives what was written, and a "sides" of 1 sets 40H in DISK_STATUS's first
byte.
#examples("disk.percom_write")
#examples("disk.percom_read.back")
#examples("disk.status.percom")
]

#section("When There Is No Disk", balance: false)[
#cmdcard("Reading Past the End", dev: "31H--38H", cmd: 0x52)
The test image has 16 sectors, 0 to 15. Sector 16 is past the end:
#examples("disk.read.past_end")
#examples("disk.write.past_end")

#cmdcard("Reading an Empty Drive", dev: "31H--38H", cmd: 0x52)
Drive 32H has never had an image:
#examples("disk.read.empty")

#cmdcard("After Unmounting", dev: "31H--38H", cmd: 0x52)
After FUJI_UNMOUNT_IMAGE, the drive refuses to read --- but STATUS still answers, as if the image
were there.
#examples("disk.read.unmounted")
#examples("disk.status.unmounted")
]
