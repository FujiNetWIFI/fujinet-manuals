#import "../lib.typ": *

#chapter(5, "FujiNet Software")

#section("The FujiNet Diskettes")[
The FujiNet's programs for the H89 come as two disk images, one for each operating system:

#stable((1.25in, 1fr),
  th[Disk Image], th[Holds],
  [FujiNet for HDOS], [CONFIG.ABS and FN.DVD],
  [FujiNet for CP/M], [CONFIG.COM and FNDISK.COM],
)

You can get both from the FujiNet project (see the inside front cover). Each is an .H8D image of a
single-sided H-17-1 diskette, so it can be written onto a real diskette for your Computer.

Write the image for your operating system onto a blank hard-sectored diskette, with whatever means
you already use to bring disk images to your H89: a program that sends them over a serial cable
from a personal computer, a floppy drive emulator that accepts .H8D images, or a friend's machine.
You need do this only once. When the FujiNet is running, you can copy any other disk image from a
FujiNet drive onto a diskette with HDOS or CP/M itself.

Neither diskette starts the Computer by itself. You start HDOS or CP/M from your own system diskette
as usual, and then run the FujiNet programs from the FujiNet diskette in your second drive. (You can
also copy them onto your system diskette.)

#sub("The Programs")
#stable((0.95in, 0.55in, 1fr),
  th[Program], th[For], th[What It Does],
  [CONFIG.ABS], [HDOS], [FujiNet CONFIG: joins your WiFi network, sets up host slots, and puts disk images in drives. See Page 6-1.],
  [FN.DVD], [HDOS], [The HDOS device driver for the FujiNet drives, FN0: through FN7:. See Page 7-2.],
  [CONFIG.COM], [CP/M], [FujiNet CONFIG for CP/M.],
  [FNDISK.COM], [CP/M], [Adds the FujiNet drives to CP/M as D: through K:. See Page 7-6.],
)

Each operating system needs a little preparation before its FujiNet drives can be used. HDOS needs
FN.DVD on its system diskette. CP/M needs to be made 2K smaller, so that FNDISK has room. Both jobs
are described below and need to be done only once.
]

#section("Preparing HDOS", balance: false)[
HDOS takes in the device drivers it finds on the system diskette (SY0:) as it starts. To make it
take in the FujiNet drives, you copy FN.DVD onto your system diskette and start HDOS again.

CAUTION: Always work on a copy of your HDOS system diskette, never on the distribution diskette.

#step[Make a working copy of your HDOS 2.0 system diskette, and start HDOS from it.]

NOTE: HDOS 2.0 cannot take a date after 1999. When it asks for the date, give it a year of 99 or
earlier, in the form DD-MMM-YY.

#step[Put the FujiNet for HDOS diskette in drive 1, and type #typed("MOUNT SY1:")#ret.]

#step[Type #typed("COPY SY0:FN.DVD=SY1:FN.DVD")#ret.]

If HDOS answers "1 FILES COPIED," go on to the next step. If it answers "NO FREE SPACE ON MEDIA," as
it will on a full distribution copy, make room. The stock system diskette carries DK.DVD, the driver
for the H47 eight-inch disk system; if you have no H47, it is not needed.

#step[If there was no room, type #typed("DELETE SY0:DK.DVD")#ret and then
#typed("COPY SY0:FN.DVD=SY1:FN.DVD")#ret again.]

#session("hdos-install", rows: (13, 22), cols: (0, 62))

#step[Push #key[SHIFT] and #key[RESET], and start HDOS again. (When it offers the date it has,
just push RETURN.)]

#step[Type #typed("STAT")#ret. Under DEVICE STATUS, HDOS should list FN: with the other devices.]

#session("hdos-stat", rows: (14, 23), cols: (0, 40))

HDOS now knows the FujiNet drives. It loads FN.DVD the first time you use one of them, and keeps it
until you start the system again.

You may also copy CONFIG.ABS onto your system diskette, if there is room, so that you can type
#typed("RUN CONFIG")#ret without the FujiNet diskette:

#align(center, block[#scr(">")#typed("COPY SY0:CONFIG.ABS=SY1:CONFIG.ABS")#ret])
]

#section("Making a 62K CP/M System", balance: false)[
FNDISK puts a small driver, about 2K, in memory above CP/M’s own BIOS. In a 64K CP/M system there
is no memory free above the BIOS, so you make your CP/M 2K smaller, a "62K system," with the
programs Heath supplies for the purpose. Your programs will have 2K less room, which few of them
will notice.

FNDISK needs Heath/Zenith CP/M version 2.2.04, the one with MOVCPM17 for H-17 disks.

CAUTION: Always work on a copy of your CP/M system diskette, never on the distribution diskette.

#step[Make a working copy of your CP/M 2.2.04 system diskette, and start CP/M from it.]

#step[Type #typed("MOVCPM17 62 *")#ret. MOVCPM17 builds a 62K CP/M in memory; it takes a few
seconds, and then says it is ready for SYSGEN.]

#step[Type #typed("SYSGEN")#ret. SYSGEN asks for a source drive. The new system is already in
memory, so just push RETURN.]

#step[SYSGEN asks for a destination drive. Type #typed("A"). When it says "DESTINATION ON A,
THEN TYPE RETURN," make sure the working copy is in drive A and push RETURN. SYSGEN writes the new
system onto the diskette and says FUNCTION COMPLETE.]

#session("cpm-sysgen", rows: (7, 20), cols: (0, 50), under: ((17, 45, 45),))

#step[SYSGEN asks for another destination. Push RETURN, and CP/M starts again from the diskette.]

The sign-on message now shows the new size:

#session("cpm-boot62", rows: (4, 7), cols: (0, 50))

This working copy is the system diskette to use with the FujiNet. Make another copy of it to keep.
]
