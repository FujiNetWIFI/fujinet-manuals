# FujiNet NOS — An Introduction to the Network Operating System

*The GitHub-wiki twin of the print booklet
`fujinet-nos-introduction.pdf`. Content verified against
`fujinet-nhandler/nos/src/nos.s` (v1.0.0) and
`fujinet-firmware/lib/network-protocol`.*

---

## Introducing NOS

The Network Operating System (NOS) is a program that allows your
ATARI computer to work with your FujiNet and enables you to store and
retrieve information on **servers** — other computers on your network
and across the Internet. The information you save is still called a
"file," and NOS (pronounced "noss") still lets you give a name to
each file so you can call it up whenever you want it.

If you have used ATARI DOS with a disk drive, you already know most
of what NOS does. NOS lists your files, deletes them, renames them,
copies them, and loads and saves programs — and since 1.0 it greets
you with a DOS 2.0-style menu. The difference is where the files
live. DOS keeps them on a diskette spinning a few inches away. NOS
keeps them anywhere at all — on the computer in your den, or on a
hobbyist server on the other side of the world.

One thing you won't find here is anything about floppy diskettes.
NOS doesn't use them. There is nothing to format, nothing to insert,
and nothing to fill up.

**Got everything?** You need: an ATARI home computer; a FujiNet
connected to your wireless network; and the NOS disk image,
`NOS.atr`, always available at **apps.irata.online** in the
`Atari_8-bit/DOS/` folder. NOS is developed in the open; its
source code lives in the
[fujinet-nhandler](https://github.com/FujiNetWIFI/fujinet-nhandler)
repository, under `nos/`.

## Beginning with NOS

Programs are stored in the computer's memory, and the memory forgets
everything at power-off. Your FujiNet fixes that by sending your work
through the air to a server. The server holding your files is called
a **mount**, and the connection NOS makes to it is a **network
drive**. You have eight, named `N1:` through `N8:`.

**Loading NOS:**

1. Boot your FujiNet CONFIG program and navigate to the host
   `apps.irata.online`.
2. Find `NOS.atr` in `Atari_8-bit/DOS/` and mount it in **disk
   slot 1** (read-only is fine).
3. Boot the disk. You'll see the NOS menu — sixteen choices,
   waiting on one keystroke:

```
FUJINET NETWORK OPERATING SYSTEM 1.0
COPYLEFT 2026 FUJINET

 A. DIRECTORY         I. CHANGE DIR
 B. RUN CARTRIDGE     J. SHOW DIR
 C. COPY FILE         K. BINARY SAVE
 D. DELETE FILE(S)    L. BINARY LOAD
 E. RENAME FILE       M. RUN AT ADDR
 F. MAKE DIRECTORY    N. CHANGE DRIVE
 G. REMOVE DIRECTORY  O. TYPE FILE
 H. BASIC ON/OFF      P. COMMAND LINE

SELECT ITEM OR RETURN FOR MENU
```

Press a letter, answer the question it asks, and NOS does the rest.
The last item is a door: **P. COMMAND LINE** opens the NOS prompt
(`N1:`), where every menu item is a command you can type with more
say in the matter — plus a dozen commands that never made the menu.
Type `MENU` at the prompt whenever you want the menu back. The
ATARI's full-screen editor works at the prompt: cursor up to an old
command, fix a character, press RETURN to run it again.

**Leave the NOS disk in the drive.** Like DOS, NOS keeps only part of
itself in memory; the less-used commands — and the menu itself — wait
on the NOS disk image as *overlays*, loaded the moment you call them.
Where DOS swapped a whole menu program over your work (and invented
MEM.SAV to apologize for it), the NOS menu is ten small sectors
borrowing one small patch of free memory — and the command line
borrows nothing at all. See "Inside NOS" for the exact map.

## The Menu

Sixteen letters, and every one of them is a NOS command wearing a
nametag. Choose a letter and the menu asks one plain question — some
of them word for word the questions DOS 2.0 asked. Answer, and the
menu assembles the real command, runs it, and waits beneath the
result. Answer a question with a bare RETURN and the item runs plain
(item A with no search spec lists everything). Press RETURN alone at
`SELECT ITEM` and the whole menu redraws.

| Item | It asks | Runs |
|------|---------|------|
| A. Directory | `DIRECTORY-SEARCH SPEC?` | **DIR** |
| B. Run Cartridge | — runs at once — | **CAR** |
| C. Copy File | `COPY-FROM,TO?` | **NCOPY** |
| D. Delete File(s) | `DELETE FILE SPEC?` | **DEL** |
| E. Rename File | `RENAME-OLD,NEW?` | **RENAME** |
| F. Make Directory | `MAKE DIRECTORY?` | **MKDIR** |
| G. Remove Directory | `REMOVE DIRECTORY?` | **RMDIR** |
| H. BASIC On/Off | `BASIC ON OR OFF?` | **BASIC** |
| I. Change Dir | `CHANGE TO DIRECTORY?` | **NCD** |
| J. Show Dir | — runs at once — | **NPWD** |
| K. Binary Save | `SAVE-NAME,START,END?` | **SAVE** |
| L. Binary Load | `BINARY LOAD FILE?` | **LOAD** |
| M. Run At Addr | `RUN AT ADDRESS (HEX)?` | **RUN** |
| N. Change Drive | `CHANGE TO DRIVE (1-8)?` | **Nn:** |
| O. Type File | `TYPE FILE?` | **TYPE** |
| P. Command Line | — opens the prompt — | |

If you grew up on ATARI DOS, the letters you wore into muscle memory
still do what they always did. Only the chores that came with
diskettes gave up their letters: FORMAT DISK and DUPLICATE DISK are
gone (nothing to format, nothing to copy sector by sector), and LOCK,
UNLOCK, WRITE DOS FILES, and CREATE MEM.SAV went with them. Their
letters were handed to network work — directories to make and remove,
a drive to change, a file viewer, and the door to the command line.
And **D. DELETE FILE(S)** finally earns its plural: give it a wild
card and it works through the crowd, asking about each file by name.

**Where the menu lives:** the menu is not resident. Each time it
draws, NOS reads it fresh from `NOS.atr` — ten sectors — into free
memory at `$2600`, and your chosen command runs from *resident* code,
so a command that overwrites the menu can't get lost on the way home.
The honest price: a program tall enough to reach `$2600` (about 2.8K
past NOS's floor at `$1B00`) gets a corner stepped on when the menu
draws. The command line loads nothing up there at all.

## Network, Not Disk

Every disk operating system before this one was built around a piece
of spinning plastic. NOS is built around a connection. Once a network
drive is *mounted*, everything you know from DOS carries over.

**Where did D: go?** ATARI software talks to diskettes through a
device named `D:`. NOS contains no disk software at all — no File
Management System, no sectors, no formatting — but it still answers
calls to `D:`. When a program asks `D:` for a file, NOS quietly hands
the request to the network device, `N:` (`D1:` means `N1:`, `D2:`
means `N2:`, and so on). This is how a BASIC program written in 1982
can `SAVE "D:MYFILE"` and have MYFILE come to rest on a server in
another hemisphere.

Day to day, that means:

- Drive numbers name **connections**, not hardware.
- There are no handlers to load — NOS installs its `N:` handler at
  boot and maps `D:` to it.
- Physical and emulated diskettes are **not** reachable from NOS
  (see "What NOS Doesn't Do").

## Connecting to a Server

The mount command is **NCD** (alias **CD**; menu item **I. CHANGE
DIR**). Hand it a URL:

```
NCD N1:TNFS://192.168.1.20/
```

No news is good news: the prompt returns and drive 1 is mounted. See
where a drive points with **NPWD** (alias **PWD**; menu item **J**):

```
NPWD
N1:TNFS://192.168.1.20/
```

Once mounted, NCD moves through the server's folders; relative paths
work, and `..` walks up one:

```
NCD GAMES/ACTION
NCD ../PUZZLE
```

A trailing `/` is added for you if you leave it off. Paths with
spaces ride in double quotes:

```
NCD "N2:FTP://ftp.pigwa.net/stuff/holmes cd/"
```

To disconnect a drive, give NCD a bare drive name: `NCD N2:`

If the URL starts with a drive name, that drive is mounted; with a
bare protocol, the *current* drive is mounted.

**Caution:** NCD does not check that a new path really exists. If you
mistype, the mistake shows up later when DIR or LOAD comes back
empty-handed. When in doubt, DIR right after you arrive.

## The Eight Network Drives

Your FujiNet carries **eight** network devices, `N1:` through `N8:`,
each mountable somewhere different at the same time. Switch the
current drive with menu item **N** (`CHANGE TO DRIVE (1-8)?`) or by
typing its name alone at the prompt:

```
N3:
```

The prompt follows you. Switching is allowed even if the drive has no
mount; NOS doesn't check until you try to use it.

**The mounts live in the FujiNet, not in your computer.** NOS is only
one voice giving it instructions. Happy consequence: mounts survive —
load a program, quit back to NOS, and your drives are still
connected. Consequence to respect: the drives are **shared**. A BASIC
program that opens `N1:` sees exactly the same `N1:` the NOS prompt
sees. If you — or a batch file, or the program itself — `NCD` drive 1
somewhere else, it moves for *everyone*.

Advice for programmers:

- Pick your drives deliberately; keep NOS housekeeping off the drives
  your program uses.
- Be careful with `NCD`/`CD` inside programs and batch files — you
  are moving a shared drive.
- **Leave `N4:` to NOS when you can.** NOS borrows drive 4 as its
  service line: HELP fetches its articles over it, and NCOPY builds
  its network destinations there.
- Keep everyday file traffic on drives 1–4. All eight answer the
  drive commands (NCD, NPWD, DIR, DEL, RENAME, MKDIR, RMDIR, NTRANS,
  LOAD), but the resident `N:` handler provides stream buffers for
  units 1–4 — that's where TYPE, NCOPY, SAVE, SUBMIT, and your own
  OPEN statements should live.

## The Protocols

A **protocol** is the language a server speaks; you choose one in the
first word of every URL. Once mounted, every protocol looks the same:
files. (List derived from `fujinet-firmware/lib/network-protocol`.)

| Protocol | Example | DIR | Read | Write | DEL/REN/MKDIR | NOTE/POINT |
|----------|---------|-----|------|-------|----------------|------------|
| **TNFS** | `NCD N1:TNFS://192.168.1.20/` | ✔ | ✔ | ✔ | ✔ | ✔ |
| **SD** | `NCD N1:SD://fujinet/` | ✔ | ✔ | ✔ | ✔ | ✔ |
| **FTP** | `NCD N2:FTP://ftp.pigwa.net/atari/` | ✔ | ✔ | (1) | (1) | — |
| **HTTP/HTTPS** | `TYPE N3:HTTPS://fujinet.online/` | (2) | ✔ | (2) | (2) | (4) |
| **SMB** | `NCD N1:SMB://DEN-PC/ATARI/` | ✔ | ✔ | ✔ | ✔ | ✔ |
| **NFS** | `NCD N1:NFS://192.168.1.9/export/atari/` | ✔ | ✔ | ✔ | ✔ | ✔ |
| **GDRIVE** | `NCD N1:GDRIVE://drive/atari/` | ✔ | ✔ | ✔ | (3) | — |

(1) where the server permits its guests — NOS logs into FTP as an
*anonymous* guest. (2) needs a WebDAV server; plain web sites are
read-only. (3) everything except RENAME. (4) reading only — see
"Moving Around In a File."

Notes:

- **TNFS** is the home team: invented for machines like yours, tiny
  free servers (`tnfsd`) for PC/Mac/Linux, spoken by the public
  FujiNet libraries. Default port 16384 is filled in for you; add
  `:port` after the host only if the server listens somewhere
  unusual.
- **SD** is the microSD card inside your FujiNet — a server that
  never leaves home, no network needed.
- **SMB** shares that want credentials: give `USER name` and
  `PASS secret` *before* the NCD that mounts.
- **GDRIVE** is Google Drive by way of a relay at fujinet.online;
  authorize your Google account once in the FujiNet's web
  configuration page.
- The `N:` device also speaks **stream** protocols — `TCP:`, `UDP:`,
  `TELNET:`, `SSH:` — live conversations rather than filesystems.
  DIR won't work there, but programs can talk through them.
- **Mind your case:** most servers treat capital and small letters as
  different. `Jumpman.xex` and `JUMPMAN.XEX` are different files.

## Looking at the Directory

Menu item **A** (answer the search-spec question with a bare RETURN
for everything), or `DIR` at the prompt:

```
DIR
JUMPMAN.XEX                  25K
STAR.RAIDERS.XEX             33K
HELLO.BAS                    512
NOTES.TXT                   1201
GAMES/
UTILS/
```

Sizes appear in bytes, `K`, or `M`; folders end with `/`. Hold SPACE
to pause a long listing, ESC to stop it. Name a drive, a path, or
both: `DIR N2:`, `DIR GAMES/`, `DIR N2:GAMES/*.XEX`.

## Wild Cards

`*` stands for any run of characters, `?` for exactly one:

```
DIR *.BAS
DIR NAME?.DAT
```

Folders are always listed, whatever the pattern. Wild cards work in
**DIR** — and, new in NOS 1.0, in **DEL** and **COPY** too. Deleting
stays careful: every matched file is offered back by name, and only a
Y sends it away. Copying announces each file as it goes. **RENAME**
is the lone holdout: one plain filename at a time.

Fine print: NOS gathers the matched names into a 512-byte list — room
for a few dozen names per command. If a pattern catches more files
than that, run the command again; the list refills with the files
that remain.

## Filespecs and URLs

The full spec, when you need it:

```
N2:TNFS://192.168.1.20/GAMES/JUMPMAN.XEX
└┬┘└┬─┘   └────┬─────┘ └─┬──┘ └───┬────┘
drive protocol  host     path    file
```

- Names may be long; most servers are **case-sensitive**.
- Names with spaces ride in double quotes, device and all.
- Extenders still mean what they meant (`.BAS`, `.XEX`, `.COM`,
  `.TXT`).
- Paths use `/`; `..` walks up one folder.
- Once a drive is mounted, filespecs shrink back to the friendly old
  shape: `LOAD JUMPMAN.XEX`.

## Saving and Loading a BASIC Program

With a writable mount on drive 1, the 1050 manual's own exercise
works verbatim — because on this machine `D:` *is* `N1:`:

```basic
10 PRINT "HELLO NETWORK"
20 GOTO 10
```

`SAVE "D:MYFILE"` streams the program out through the FujiNet onto
the server. Power-cycle, boot NOS, and `LOAD "D:MYFILE"` brings it
home. `RUN "D:FILENAME"`, `LIST`/`ENTER`, `PRINT#`/`INPUT#` all work
the same way.

Even BASIC's NOTE and POINT — the commands that jump around inside a
file — work over the network now, wherever the protocol plays along;
see "Moving Around In a File." Everything that reads or writes
start-to-finish is right at home already.

## Loading Programs

- `LOAD JUMPMAN.XEX` (alias `X`; menu item **L**) — loads standard
  ATARI binaries, honoring init and run addresses. Non-binaries stop
  with `NOT A BINARY FILE`. Translation is switched off automatically
  for the load. Loading is quick: 128 bytes or more on the way move
  in single bursts of up to 8K, streamed straight into place (see
  "Inside NOS").
- **The shortcut:** type a bare word NOS doesn't recognize and it
  tries `LOAD WORD.COM` from the current drive. Every `.COM` on the
  drive is, in effect, a NOS command.
- `REENTER` (alias `REE`) — jump back into the last loaded program
  (its run/init address). Two cautions: exiting to NOS draws the
  menu, which borrows `$2600`–`$2AFF` — a program occupying that
  patch won't survive the round trip; and some programs re-initialize
  on entry. Save first.
- `RUN A000` (menu item **M**) — call machine code by hex address
  (four digits, no `$`; lead small addresses with a zero:
  `RUN 0600`).
- `CAR` (menu item **B**) — to the cartridge (or built-in BASIC) with
  memory preserved; type `DOS` there to come back. Caution for long
  programs: coming back draws the menu at `$2600` — room for about
  2.8K of BASIC program above NOS's floor. Longer than that, SAVE
  before you visit.
- `BASIC ON|OFF` (alias `ROM ON|OFF`; menu item **H**) — XL/XE only:
  swap built-in BASIC in/out without rebooting while holding OPTION.
  The border stays gray while ROM is in, as a reminder. `BASIC ON`
  when already on behaves like CAR.
- `SAVE FILE,START,END[,INIT][,RUN]` (menu item **K**) — write a
  memory range as a binary file; skip INIT but give RUN with a double
  comma: `SAVE MYPROG,2000,2FFF,,2000`.

## Copying Files

Menu item **C** asks `COPY-FROM,TO?`; at the prompt:

```
NCOPY MYFILE,MYFILE2
NCOPY N1:GAME.XEX,N2:GAME.XEX
NCOPY N1:GAME.XEX,N2:
NCOPY GAME.XEX,N2:GAMES/
COPY N2:GAMES/GAME.XEX
COPY *.BAS,N2:BACKUP/
NCOPY DAY2.TXT,LOG.TXT,A
NCOPY NOTES.TXT,P:
NCOPY NOTES.TXT,E:
```

(Alias **COPY**.) A destination of a bare `Nn:` or ending in `/`
keeps the source's name — and, new in 1.0, one lone argument means
"copy it *here*, onto the current drive" (that's the fifth example).
A wild-card source (sixth example) copies every match, echoing each
name as it goes — no confirmation. `,A` appends instead of replacing.
`P:` prints, `E:` shows on screen. Copying a file onto itself is
refused (`SAME FILE?`). Two cautions: active NTRANS translation
alters what's copied (set mode 0 for binaries), and network
destinations are built over drive `N4:`.

## Deleting and Renaming

- `DEL FILE` (aliases `ERASE`, `ERA`; menu item **D**) — a plain name
  deletes immediately: no confirmation, case-sensitive, no undelete.
- `DEL PATTERN` — new in 1.0: every matched file is offered with
  ` (Y/N)?`, one at a time; only Y deletes, anything else spares the
  file and moves on. `DEL *.*` is not the catastrophe it was on
  DOS 2.0 — it's an interview.
- `RENAME OLDNAME,NEWNAME` (alias `REN`; menu item **E**) — give the
  new name bare (no drive/path); one file at a time, no wild cards.
  Known rough edge in this version: renaming through a relative path
  misfires; NCD to the file's folder first.
- `MKDIR DIRNAME` / `RMDIR DIRNAME` (menu items **F** / **G**) —
  create/remove directories where the protocol allows; RMDIR removes
  only *empty* directories.

## Text Files and Line Endings

`TYPE FILE` (menu item **O**) shows a text file a screenful at a time
(any key pages, ESC stops), coping with CR/LF as it reads. Point it
only at text — a big binary can overrun its buffer and corrupt
memory. It works on anything a drive can read, including
`TYPE N3:HTTPS://...`.

Your ATARI ends lines with EOL (155); other computers use CR, LF, or
both. `NTRANS [Nn:] mode` sets a drive's in-flight translation:

| Mode | Translation |
|------|-------------|
| 0 | none — bytes pass untouched |
| 1 | CR ⇄ ATARI EOL |
| 2 | LF ⇄ ATARI EOL (Unix, Mac) |
| 3 | CR/LF ⇄ ATARI EOL (Windows) |

Translation is for text **only** — a binary hauled through mode 2
arrives broken. LOAD protects itself; NCOPY does not.

## Moving Around In a File

New in NOS 1.0: BASIC's NOTE and POINT — the commands that jump
around inside a file — work on network files. The dialect is
byte-counting, the way SpartaDOS speaks, not DOS 2's
sector-and-offset: a position is simply how many bytes into the file
you are, counted from zero. NOTE asks *where am I?* POINT says *go
there.*

```basic
100 OPEN #1,4,0,"D:BIG.DAT"
110 POINT #1,5000,0
120 GET #1,B
```

Line 110 jumps clean to byte 5,000 — no reading past the first 4,999
to get there. The two numbers make one position: **position = first +
65,536 × second**. For files under 64K the second number is simply 0,
and the first is the byte position, plain as a page number.

```basic
200 NOTE #1,A,B
210 REM READ ON A WHILE...
220 POINT #1,A,B
```

NOS keeps the books straight behind the scenes: NOTE answers with
*your program's* place — not the FujiNet's, which reads a little
ahead — and POINT throws the read-ahead away and starts fresh at the
new spot.

**From machine language:** NOTE is XIO 38 and POINT is XIO 37, the
same CIO commands every DOS answered. The position is 24 bits, riding
in the IOCB's auxiliary bytes — ICAX3 low, ICAX4 middle, ICAX5 high —
for a reach of 16 megabytes into any file.

**Where jumping works:**

| Protocol | NOTE and POINT |
|----------|----------------|
| TNFS, SD, SMB, NFS | jump anywhere, reading or writing |
| HTTP(S) | reading only |
| FTP, GDRIVE, streams | front to back only — no jumping |

On the web the jump is a Range request — the same trick download
managers use — and the FujiNet quietly reopens the connection to make
it. Fine for reading; there is no jumping while *writing* a web
resource. A protocol that can't jump answers POINT with **ERROR
166** — the same "invalid POINT" number DOS always reserved for the
complaint.

## Batch Files

`SUBMIT FILE` (alias `@`) runs the NOS commands in a text file as if
typed. Write batch files anywhere — ATARI editor or your PC — with
ATARI, LF, or CR/LF line endings; SUBMIT reads them all.

The batch toolkit: `PRINT "MESSAGE"` speaks; `REM` (or `'` or `#`)
comments; `@SCREEN` / `@NOSCREEN` start and stop command echo. A
batch file runs *quietly* unless you ask, and lines beginning with
`@` are never echoed.

```
REM -- MY MORNING SETUP --
PRINT "GOOD MORNING"
NCD N1:TNFS://192.168.1.20/WORK/
NCD N2:TNFS://APPS.IRATA.ONLINE/
NCD N3:SD://SCRATCH/
NTRANS N1: 2
PRINT "DRIVES 1-3 READY"
```

## AUTORUN: Starting Up Your Way

```
AUTORUN TNFS://192.168.1.20/SETUP.BAT
AUTORUN ?
AUTORUN ""
```

Names a batch file to SUBMIT automatically at every cold start. Give
a **full URL** — nothing is mounted yet at boot. `?` shows the
current setting, `""` clears it. Hold **OPTION** during boot to skip
it once.

**Where the setting lives:** NOS writes the URL into an **AppKey** —
a small named record the FujiNet keeps for programs (creator `$DB79`,
app 0, key 0) — stored on the microSD card *in the FujiNet itself*,
as `/FujiNet/db790000.key`. So the FujiNet needs a FAT32 SD card for
AUTORUN to stick. Because the setting rides in the FujiNet: it
survives power-off and doesn't care which disk booted; carry your
FujiNet to a friend's ATARI and your startup comes along; swap SD
cards and it stays with the card.

## What NOS Doesn't Do

Everything on this short list has the same explanation: **NOS
contains no File Management System.** It cannot read or write
diskettes or disk images — not even the ones your FujiNet mounts in
its disk slots. `D:` goes to the network, full stop.

- **No LOCK/UNLOCK** — whether a file may change is the server's
  decision; set permissions there. Write-protected files give a
  write error.
- **No wild cards in RENAME** — the only file command they haven't
  reached.
- **No MOVE** — copy, then delete.
- **No dates in DIR** — names and sizes only; servers know the
  dates, NOS doesn't ask yet.
- **No diskettes at all** — when you need one: reboot into CONFIG
  and boot the disk image; or boot a classic DOS with the FujiNet
  `N:` handler (`n-handler.atr`) to copy between `D:` and `N:`
  side by side; or reach SD-card files directly with `SD://`.

And the ledger runs the other way: no diskette swapping, no 707-
sector ceiling, a menu of ten sectors instead of a whole DUP.SYS,
directories that nest, filenames that breathe, and drive 2 in
another country.

## What To Do If It Doesn't Work

| Symptom | Meaning / cure |
|---------|----------------|
| `BOOT ERROR` | No bootable disk: FujiNet off, or `NOS.atr` not mounted in disk slot 1. |
| `CMD?` | NOS couldn't parse the line. |
| `FILE?` `PATH?` `Nn?` `ADDR? 0000..FFFF` | The command reminding you what it needs. |
| `MODE? 0=NONE, 1=CR, 2=LF, 3=CR/LF` | NTRANS showing its menu. |
| Error 136 | End of file — arriving unexpectedly, the connection closed or the mount was never made. NPWD the drive. |
| Error 138 | Timeout — FujiNet off, starting up, or lost the wireless network. |
| Error 144 | The server said no — permissions, read-only share, full disk. NOS prints the server's specific code when it has one. |
| Error 146 | The protocol doesn't do that (e.g., RENAME on GDRIVE, writing to a plain web server). |
| Error 165 | Malformed filespec — stray colon, misspelled protocol, missing quotes. |
| Error 166 | Invalid POINT — the protocol can't jump (see "Moving Around In a File"). |
| Error 170 | File not found — check case against DIR. Also what a mistyped bare command comes to (`WORD.COM` not found). |
| `NOT A BINARY FILE` | LOAD given a non-binary. |
| `SAME FILE?` | NCOPY refused to copy a file onto itself. |
| `NO CARTRIDGE` / `NO BUILT-IN BASIC` | CAR/BASIC found nothing to switch to. |
| `TOO MANY FILES OPEN` | No free IOCB channel. |
| `CANT READ DIR` | A wild-card DEL/COPY couldn't open the directory to match against. |

## Getting Help

```
HELP
HELP NOS
HELP NOS/MKDIR
HELP REF/ATASCII
```

HELP fetches articles over the network and shows them paged like
TYPE. Every article is a plain text file in the
[fujinet-nhandler](https://github.com/FujiNetWIFI/fujinet-nhandler)
repository under `nos/HELP/` — HELP reads them from GitHub's raw
pages the moment you ask, so what you see at the prompt is exactly
what the repository holds today. Fix a typo or write a missing
article, and every NOS in the world gets the improvement. Articles
under a topic need the topic in the path (`HELP NOS/MKDIR`, not
`HELP MKDIR` — a 404 means the path was off). HELP reads over drive
`N4:`; a mount there can confuse it.

**The card catalog** — more than 1,200 articles on six shelves:

| Shelf | Holds | Examples |
|-------|-------|----------|
| **NOS** | one card per NOS command | `HELP NOS/DIR`, `HELP NOS/COPY` |
| **ASM** | 6502 reference: instruction set, address modes, branching, loops, arithmetic, then one card per instruction | `HELP ASM/INSTR`, `HELP ASM/LDA` |
| **MAP** | the ATARI memory map — 1,082 cards set from *Mapping the ATARI* by Ian Chadwick; browse by letter, label, or address | `HELP MAP/S`, `HELP MAP/SAVMSC`, `HELP MAP/0230` |
| **REF** | ATASCII, colors, key codes, error tables — one card per error number | `HELP REF/ATASCII`, `HELP REF/ERROR/144` |
| **DEV** | development tools | `HELP DEV/ASMED` |
| **UTL** | utilities | `HELP UTL/TEDIT` |

One unlisted card: `HELP BUGS` is the project's standing confession —
the known bugs, kept honestly, straight from the repository.

## Inside NOS

For the reader who wants to know how the watch ticks. (Addresses
verified against the MADS label table for v1.0.0.)

**Memory.** At boot NOS hooks DOSVEC/DOSINI, installs its `N:`
handler (answering for `D:` too), and raises MEMLO to `$1B00` — a
resident cost of five kilobytes even (`$0700`–`$1AFF`), less than
DOS 2.0 asked. The top of the resident block is working space:
`OVLBUF` at `$1900` is a 256-byte window where overlays run, and two
128-byte buffers (`RBUF`/`TBUF`) sit above it. The command line lives
at `$0582`. Three tenants borrow free RAM only while on duty: the
menu (ten sectors at `$2600`), the wild-card machinery (scratch at
`$4000`, code at `$4300`), and NCOPY's 8K burst buffer just above
MEMLO.

**Overlays.** Two dozen commands are resident; the bigger ones —
AUTORUN, BASIC, DIR, DUMP, FILL, HELP, NCOPY, NTRANS, REENTER, SAVE,
XEP, and DEL's wild-card scanner — live on `NOS.atr` as overlays of
one or two sectors. Because the whole OS is one assembled image whose
ATR begins at `$0700`, a routine's assembled address *is* its place
on disk: `sector = address/128 − 13`. The resident dispatcher
(`DO_OVERLAY`) reads the overlay into OVLBUF and jumps to it,
remembering what it loaded so running DIR twice reads the disk once.
Overlays execute at `$1900` though assembled higher, so branches are
relative and absolute self-references are spelled
`OVLBUF-OVL_FOO+label`. A command too big for the window chains —
NCOPY is three overlays handing off. The menu and wild-card engine
are *transient modules* instead: assembled at their own run addresses
(`$2600`, `$4300`), loaded above MEMLO on demand, dispatched from
resident trampolines that reload them afterward.

**The disk.** `NOS.atr` maps as: sectors 1–36 boot + resident kernel;
37–40 buffer images; 41–62 command overlays; 63–72 the menu module;
73–78 the wild-card module; and at sector 360 a *fake* VTOC with a
hand-built directory in 361–368 whose entry names spell out the OS's
name — so disk tools see a healthy single-density diskette.

**The burst engine.** On a binary read of 128 bytes or more with data
waiting, NOS skips the byte-at-a-time bucket brigade: one SIO frame
carries min(bytes waiting, buffer, 8K) straight into the caller's
memory — the exact count requested. Writes mirror it. The last byte
of each burst rides through CIO so the bookkeeping stays honest.

**Rolling your own overlay.** Add the name to the `CMD_IDX` enum and
keyword table (`.CB "FOO"` + `CMD_IDX.FOO`) with `CMD_TAB_L/H`
entries pointing at `DO_FOO-1`; write a resident stub
(`DO_FOO: LDX #OVL_IDX.FOO / JMP DO_OVERLAY`); add the overlay's
sector and count to `OVL_SECT_TAB_L` / `OVL_SECT_CNT_TAB`
(`<(OVL_FOO/SECTOR_SIZE-$0D)` and
`[END_OVL_FOO-OVL_FOO]/SECTOR_SIZE`); then write the body between
`OVL_FOO:` and `END_OVL_FOO:`, padded with
`.ALIGN SECTOR_SIZE,$00`. Arguments arrive as offsets in `CMDSEP`
(commas pre-split); the kernel lends `PREPEND_DRIVE`, `DOSIOV`,
`CIOOPEN`/`CIOGET`/`CIOPUT`/`CIOCLOSE`, `PRINT_STRING`, and
`PRINT_ERROR`. Run `make` — MADS recomputes every sector number
itself.

## Command Reference

Square brackets mark optional parts; `Nn:` means any drive `N1:`–
`N8:` (omitted = current drive). Commands may be typed in either
case. The Menu column names the command's item on the NOS menu.

| Command | Syntax | Aliases | Menu | Notes |
|---------|--------|---------|------|-------|
| **@NOSCREEN** | `@NOSCREEN` | | | Stop echoing batch commands (the default state). |
| **@SCREEN** | `@SCREEN` | | | Start echoing batch commands; `@` lines never echo. |
| **AUTORUN** | `AUTORUN URL` \| `?` \| `""` | | | Full URL required; AppKey `/FujiNet/db790000.key` (max 64 chars); OPTION skips at boot. |
| **BASIC** | `BASIC ON\|OFF` | ROM | H | XL/XE built-in BASIC only; warmstarts; gray border while ROM in. |
| **CAR** | `CAR` | | B | To cartridge/BASIC, memory preserved; `NO CARTRIDGE` if none. |
| **CLS** | `CLS` | | | Clear the screen. |
| **COLD** | `COLD` | | | Coldstart; hold OPTION to keep BASIC out (XL/XE). |
| **DEL** | `DEL [Nn:][path/]file\|pattern` | ERASE, ERA | D | Plain name deletes immediately; a pattern asks ` (Y/N)?` per match (512-byte match list per run); case-sensitive. |
| **DIR** | `DIR [Nn:][path/][pattern]` | | A | `*`/`?` patterns; dirs always listed; SPACE pauses, ESC stops. |
| **DUMP** | `DUMP START [END]` | | | Hex dump, 8 bytes/line; 4 hex digits; ESC stops. |
| **FILL** | `FILL START END XX` | | | Fill memory with byte XX. |
| **HELP** | `HELP [TOPIC[/ARTICLE]]` | | | Fetched from GitHub over N4:. |
| **LOAD** | `LOAD [Nn:]file` | X | L | ATARI binaries; auto-disables translation; bare `WORD` = `LOAD WORD.COM`. |
| **MENU** | `MENU` | | | Back to the menu from the command line (reverse of item P). |
| **MKDIR** | `MKDIR [Nn:][path/]dir` | | F | Where the protocol allows. |
| **NCD** | `NCD [Nn:]URL` \| `path` \| `..` \| `Nn:` | CD, CWD | I | Mount / navigate / unmount; no existence check; mounts shared. |
| **NCOPY** | `NCOPY FROM[,TO][,A]` | COPY | C | One arg copies to current drive, same name; wild-card source copies all matches, echoing names; `,A` appends; bare `Nn:`/trailing `/` keeps name; `P:`/`E:` destinations; uses N4:. |
| **Nn:** | `Nn:` | | N | Make drive n (1–8) current; no mount check. |
| **NPWD** | `NPWD [Nn:]` | PWD | J | Show a drive's mount URL. |
| **NTRANS** | `NTRANS [Nn:] mode` | | | 0 none, 1 CR, 2 LF, 3 CR/LF ⇄ EOL(155); text only. |
| **PASS** | `PASS password` | | | Credential for protocols that log in; before the mount. |
| **PRINT** | `PRINT "string"` | | | Show a message (batch files). |
| **REENTER** | `REENTER` | REE | | Jump back into the last loaded program. |
| **REM** | `REM comment` | ', # | | Ignored line (batch files). |
| **RENAME** | `RENAME [Nn:][path/]old,new` | REN | E | New name bare; one file, no wild cards; avoid relative paths (known issue). |
| **RMDIR** | `RMDIR [Nn:][path/]dir` | | G | Empty directories only. |
| **RUN** | `RUN ADDR` | | M | 4 hex digits, no `$`; `RUN 0600`. |
| **SAVE** | `SAVE [Nn:]file,START,END[,INIT][,RUN]` | | K | Binary save; double comma skips INIT. |
| **SUBMIT** | `SUBMIT [Nn:]file` | @ | | Runs commands from a text file; any line endings; quiet by default. |
| **TYPE** | `TYPE [Nn:]file` | | O | Paged text viewer; any key pages, ESC stops; text only. |
| **USER** | `USER name` | | | Credential for protocols that log in; pair with PASS. |
| **WARM** | `WARM` | | | Warmstart. |
| **XEP** | `XEP [40]` | | | XEP80: 80-column screen, `XEP 40` back; load the handler first. |

NOTE and POINT are not typed commands — they are XIO 38 / XIO 37,
reached from BASIC as `NOTE #ch,A,B` and `POINT #ch,A,B` (see
"Moving Around In a File").

---

*The complete `nos.s` source listing is printed in the back of the
PDF booklet, and lives at
`fujinet-nhandler/nos/src/nos.s`. NOS is by Thomas Cherryhomes and
Michael Sternberg, with optimizations by djaybee.*
