#import "../lib.typ": *
#import "../prog.typ": *

#chapter(14, "NGET and NPUT")

#section("General")[
NGET copies a file from the network to one of your disks; NPUT copies one the other way. "The
network" means anything a channel can open: a web server, a TNFS or FTP server, a Windows share,
the FujiNet's own microSD card (Chapter 11). With the two of them, an H89 can fetch a program
from the Internet, or send its work to a modern computer, without a floppy disk changing hands.

Each comes in assembly language and in C, and each makes a program for HDOS and for CP/M. Like
NETCAT, they are written to be read: about 200 lines of assembly, 100 of C.
]

#section("Using NGET and NPUT")[
#code("NGET devicespec file          NPUT file devicespec")

#steps(
  [To fetch a web page into a file under HDOS: \
   #typed("NGET N:HTTP://FUJINET.ONLINE/ SY1:INDEX.HTM") #ret],
  [To send a file to a TNFS server under CP/M: \
   #typed("NPUT B:NOTES.TXT N:TNFS://MYSERVER/NOTES.TXT") #ret],
  [Or run either with nothing after its name, and it asks for the two names.],
)

#note[HDOS and CP/M turn a typed command line into capitals. Many servers --- web servers, and
TNFS or SMB servers on UNIX --- care about the case of a path, and `/DATA.BIN` is not `/data.bin`
to them. When a name needs small letters, run the program with nothing after its name and type the
names at its questions: what you type there is kept as you typed it.]

Here are NGET under HDOS and NPUT under CP/M, the first fetching 3,000 bytes from the book's test
server, the second sending a short text file to it:

#session("nget-hdos", rows: (18, 22), under: ((20, 19, 52), (21, 11, 22)))
#session("nput-cpm", rows: (7, 11), under: ((9, 14, 24), (10, 17, 48)))

The test server (`tools/helpers.py`) logged what NPUT sent: a PUT of 128 bytes, the file's two lines
followed by whatever filled the rest of its 128-byte record. Here that was E5H, the byte of an empty
diskette, because the book's tools put the file on the disk; a file saved by a CP/M program would
have ended in CTRL-Zs. Which brings us to file lengths.
]

#section("How Long Is a File?")[
Neither HDOS nor CP/M records how many bytes a file holds. HDOS knows how many 256-byte sectors it
has, and CP/M how many 128-byte records. So:

- *NGET* writes every byte it receives, and the file is rounded up to a whole sector or record:
  NGET.ASM's library fills the rest of the last HDOS sector with zeros, and of the last CP/M record
  with CTRL-Zs; NGET.C, through z88dk's file routines, fills both with CTRL-Zs. For a text file
  that does no harm: CTRL-Z is CP/M's end-of-text mark, and HDOS fills the end of a text file's
  last sector with zeros itself. For
  a program or a disk image it does no harm either, since the extra bytes are never used.
- *NPUT* sends the whole of the last sector or record, because it cannot tell where the data ended.
  A text file sent from CP/M arrives with CTRL-Zs on its end; one from HDOS, with zeros. Most modern
  editors show these, and are happy to delete them.

A program that knows its files are text could stop at the first CTRL-Z, or the first zero. NGET and
NPUT don't, because they cannot know.
]

#section("How NGET Works")[
NGET opens the devicespec on channel 1 for reading (mode 4), with no translation, so a binary file
arrives intact. Then it loops, much as NETCAT does: STATUS, and if bytes are waiting, READ them
--- never more than are waiting --- and write them to the file.

When nothing is waiting, the error byte of STATUS says why. 136 means *end of data*: the whole
file has come, and NGET is done. 1 means all is well, but nothing has come yet: a slow server, or
a long way away. Anything else is a failure, and NGET reports its number (the Appendix lists them).
NGET gives up if nothing at all comes for 30 seconds.

#snip("nget.loop", "asm", caption: [NGET.ASM --- the copying loop])

#note[For an HTTP channel, the request is sent when the program first asks for STATUS (or READ),
not when the channel is opened. So the first STATUS may take a moment: it waits for the server's
answer to begin.]

The C version is the same loop, with `fwrite()` for the file:

#snip("nget.loop", "c", caption: [NGET.C --- the copying loop])
]

#section("How NPUT Works")[
NPUT opens the devicespec for writing (mode 8) and sends the file in pieces of up to 512 bytes,
each in one WRITE request: its length goes in the request's field *and* is the length of its
payload.

#snip("nput.loop", "asm", caption: [NPUT.ASM --- sending the file])

Then it closes the channel. For most protocols the file is complete once the last WRITE is
answered; but HTTP sends a PUT request only when the channel closes, with everything written as its
body. Until CLOSE, nothing has reached the web server at all.

#warning[Don't ask a PUT channel for its STATUS before closing it. The FujiNet sends the PUT at the
first STATUS, and then again at CLOSE: the server gets the file twice, or, if more was written in
between, gets two different files. NPUT never asks.]

#snip("nput.close", "c", caption: [NPUT.C --- CLOSE is when an HTTP PUT is sent])
]

#section("Getting the Names")[
Both programs take their two names from the command line, or ask for them. The assembly versions
use two small routines from the book's `words.inc`: `word`, which takes the next word from the
command line, and `netspec`, which puts `N:` in front of a devicespec that lacks it. The C versions
use the same two, in `words.c`.

#snip("nget.args", "asm", caption: [NGET.ASM --- the names])
]

#section("Listings", balance: false)[
#plisting("nget-asm")
#plisting("nput-asm")
#plisting("nget-c")
#plisting("nput-c")
#plisting("words")
]
