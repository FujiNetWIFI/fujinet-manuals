#import "../lib.typ": *

#chapter(7, "Using FujiNet Drives")

#section("The FNDISK Drivers")[
Once CONFIG has put disk images in the FujiNet's drive slots, a driver lets the operating system use
them. Together, the two drivers are called FNDISK:

#stable((0.95in, 0.55in, 1fr),
  th[Driver], th[For], th[The Drives Are],
  [FN.DVD], [HDOS 2.0], [FN0: through FN7:, for drive slots 1 through 8.],
  [FNDISK.COM], [CP/M 2.2.04], [D: through K: (or eight drives from a letter you choose), for slots 1 through 8.],
)

Each FujiNet drive is a disk image in the H-17-1 format: 40 tracks of 10 sectors of 256 bytes,
102,400 bytes in all, the same as a single-sided H-17 diskette. The drivers check what is in a slot
before they use it, and refuse anything that is not an .H8D image, so a disk image for some other
computer can do no harm.

A FujiNet drive works like any other drive on your system. You can catalog it, copy files to and
from it, and run programs from it. An image on the microSD card answers quickest; one on a server
across the Internet answers as quickly as the Internet allows.

The drivers ask the FujiNet for each sector as it is needed, and write each sector back to the disk
image at once; nothing is held back waiting to be written.

NOTE: The H89 cannot start HDOS or CP/M from a FujiNet drive. Start your system from its own
diskette; the FujiNet drives join it once it is running.
]

#section("HDOS: FN0: to FN7:", balance: false)[
With FN.DVD on your system diskette (see "Preparing HDOS," Page 5-1), HDOS has eight more drives.
Drive slot 1 is FN0:, slot 2 is FN1:, and so on up to slot 8, FN7:. You mount them and dismount
them like the drives you already have.

#sub("Mounting a FujiNet Drive")
#step[Run CONFIG, put a disk image in drive slot 1, and push #key[ESC] to leave. (Or, if the
FujiNet puts its drives in service by itself, just start HDOS.)]

#step[Type #typed("MOUNT FN0:")#ret. HDOS loads FN.DVD if it has not done so already, reads the
disk's label and reports it.]

#step[Use the drive. For example: #typed("CAT FN0:")#ret, #typed("TYPE FN0:HELLO.TXT")#ret,
#typed("COPY FN0:PIP.ABS=SY0:PIP.ABS")#ret.]

#session("hdos-fn0", rows: (0, 23), cols: (0, 60))

You may load the driver before you need it with #typed("LOAD FN:")#ret. It stays in memory until
you start the system again, and uses about 4.3K.

#sub("Changing Disks")
HDOS, like any careful operating system, remembers what it knows about a mounted disk. So before
you change what is in a FujiNet drive, dismount it, and mount it again afterward:

#step[Type #typed("DISMOUNT FN0:")#ret.]

#step[Run CONFIG, change the disk image in slot 1, and push #key[ESC].]

#step[Type #typed("MOUNT FN0:")#ret.]

Do not use HDOS’s RESET command on a FujiNet drive. RESET waits for you to change a diskette in a
drive, and the FujiNet has no door to open; use DISMOUNT and MOUNT instead.

#sub("When HDOS Says No")
HDOS reports a FujiNet drive's troubles in its own words:

#session("hdos-errors", rows: (9, 19), cols: (0, 79), size: 6.6pt)

#stable((1.6in, 1fr),
  th[HDOS Says], th[It Means],
  [?02 UNKNOWN DEVICE NAME], [HDOS has no FN.DVD: it is not on SY0:, or HDOS has not been started again since you copied it.],
  [?02 UNIT NOT AVAILABLE], [That drive slot is empty, the drives have not been put in service since the Computer was turned on (run CONFIG and push #key[ESC]), or the FujiNet is not answering.],
  [?02 UNABLE TO READ THIS DISK, IT PROBABLY HAS NOT BEEN PROPERLY INITIALIZED], [The slot holds something that is not an HDOS disk: another computer's image, a CP/M disk, or a blank image.],
  [?02 DEVICE IS INCAPABLE OF WRITE OPERATIONS (OR IS WRITE LOCKED)], [The image is in the slot read only. Dismount, put it in read/write with CONFIG, and mount it again.],
  [?02 READ FAILURE, ?02 WRITE FAILURE], [The FujiNet stopped answering, or could not reach the host (for a network host, check the WiFi).],
)
]

#section("CP/M: FNDISK", balance: false)[
Under CP/M, FNDISK.COM adds the FujiNet drives. Run it once each time you start CP/M, after CONFIG
has put your disk images in the drive slots. It needs Heath/Zenith CP/M 2.2.04, made into a 62K
system (see "Making a 62K CP/M System," Page 5-3).

#step[Start CP/M from your 62K system diskette.]

#step[If the drives are not in service yet, run CONFIG (#typed("B:CONFIG")#ret), put your disk images
in, and push #key[ESC].]

#step[Type #typed("B:FNDISK")#ret.]

FNDISK installs itself and lists the FujiNet drives, each with its drive slot and the disk image in
it:

#session("cpm-fndisk", rows: (4, 16), cols: (0, 50))

The drive letters start after the last one your BIOS uses. On an H-17 system, with drives A:, B:
and C:, that is D:. A slot with a dash in it is empty. FNDISK stays in memory until you start CP/M
again from its diskette (a warm boot, with CTRL-C, keeps it).

You can choose where the letters start by giving FNDISK a letter: #typed("B:FNDISK G")#ret puts slot
1 on G: and the others after it. All eight must fit by P:, so the latest starting letter is I:, and
the letter must not be one of your BIOS’s own drives.

#sub("Using the Drives")
#session("cpm-use", rows: (6, 23), cols: (0, 50))

Each FujiNet drive holds 92K, with room for 64 directory entries, the same as an H-17 diskette under
Heath CP/M.

To see which disk images are in the drives, run FNDISK again. It knows it is already installed, and
just lists them:

#session("cpm-again", rows: (11, 23), cols: (0, 50))

#sub("Changing Disks")
#step[Run CONFIG, change the disk images, and push #key[ESC].]

CONFIG gives the Computer back to CP/M with a warm boot, and CP/M looks at every drive afresh, so
the new disk images are ready to use. There is no need to run FNDISK again unless you have restarted
CP/M from its diskette.

#sub("When CP/M Says No")
CP/M’s own error messages tell you when a FujiNet drive cannot do what you ask. An empty drive slot
gives

#session("cpm-select", rows: (22, 23), cols: (0, 50))

Push RETURN to go on. Writing to a drive whose image is read only gives "Bad Sector":

#session("cpm-readonly", rows: (21, 23), cols: (0, 50))

CP/M waits for a key after a "Bad Sector." Push CTRL-C to give up and go back to the A> prompt; any
other key tries the write again, and will fail again.

FNDISK’s own messages:

#stable((1.6in, 1fr),
  th[FNDISK Says], th[It Means],
  [Installed.], [It is ready; the list follows.],
  [Already installed.], [It was installed before; the list follows.],
  [No room above the BIOS. Make a 62K system (MOVCPM17 62 \*, then SYSGEN) and boot that.], [Your CP/M is a 64K system. See Page 5-3.],
  [Needs Heath/Zenith CP/M 2.2.04.], [This is some other CP/M. FNDISK works only with 2.2.04.],
  [No FujiNet card (82C55 at 0D0H) found.], [Nothing answered at port 320: the card, its PORT SEL jumper, or another board at 320.],
  [The FujiNet isn't answering.], [The card is there but the FujiNet did not reply. Wait a moment and try again; if it still does not answer, turn the Computer off and on. See Page 10-4.],
  [No 8 free drive letters there.], [The letter you gave FNDISK is one of your BIOS’s drives, or is later than I:.],
)

#session("cpm-64k", rows: (4, 12), cols: (0, 50))
]

#section("A Typical Session", balance: false)[
Here is a whole working session, from power-on, under each operating system. These examples
assume the FujiNet is waiting for CONFIG after power-on (the way it comes); if you have told it to
put its drives in service by itself, skip the CONFIG steps.

#grid(columns: (1fr, 1fr), column-gutter: 1.2em,
  [
    #sub("HDOS")
    + Turn on the Computer and boot HDOS: #typed("B")#ret.
    + #typed("MOUNT SY1:")#ret (the FujiNet diskette).
    + #typed("RUN SY1:CONFIG.ABS")#ret. Check the drive slots; push #key[ESC].
    + #typed("MOUNT FN0:")#ret, and work.
    + Before running CONFIG again: #typed("DISMOUNT FN0:")#ret. (On a 48K Computer, start HDOS again instead.)
  ],
  [
    #sub("CP/M")
    + Turn on the Computer and boot CP/M: #typed("B")#ret.
    + #typed("B:CONFIG")#ret. Check the drive slots; push #key[ESC].
    + #typed("B:FNDISK")#ret.
    + Use D: through K:.
    + To change disks: #typed("B:CONFIG")#ret, change them, #key[ESC].
  ])
]

#section("Blank Disk Images", balance: false)[
The FujiNet drives can only use disk images that have been prepared for their operating system. A
new image made with CONFIG’s N key is blank, so prepare it first, or make a ready-to-use blank
image on your personal computer and copy it to the microSD card.

#sub("For CP/M")
An empty CP/M disk is one whose directory is filled with the byte E5 (hexadecimal). A
102,400-byte file filled with E5 bytes is a ready-to-use empty CP/M disk for FNDISK. On a personal
computer with a Unix shell, this command makes one:

#align(center, scr("head -c 102400 /dev/zero | tr '\\0' '\\345' > BLANK.H8D"))

#sub("For HDOS")
An HDOS disk must be initialized: it needs a label, a directory and its allocation tables. FN.DVD
does not initialize disks. Make your blank HDOS images with a disk image tool on your personal
computer, or initialize a diskette in your H-17 drive with HDOS’s INIT and copy its image. The
fujinet-h89 project includes such a tool, #scr("hdosfs.py"):

#align(center, scr("python3 hdosfs.py blank BLANK.H8D --label \"MY DISK\""))

#sub("Images in Other Forms")
H-17 disk images are also passed around as .H17DISK files, which record the diskette's tracks as
the drive saw them. #scr("hdosfs.py convert") turns a single-sided, 40-track .H17DISK into an .H8D
for the FujiNet:

#align(center, scr("python3 hdosfs.py convert GAMES.H17DISK GAMES.H8D"))
]
