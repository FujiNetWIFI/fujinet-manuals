# FujiNet NOS — An Introduction to the Network Operating System

*The GitHub-wiki twin of the print booklet
`fujinet-nos-introduction.pdf`. Content verified against
`fujinet-nhandler/nos/src/nos.s` (v0.8.0) and
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
copies them, and loads and saves programs. The difference is where
the files live. DOS keeps them on a diskette spinning a few inches
away. NOS keeps them anywhere at all — on the computer in your den,
or on a hobbyist server on the other side of the world.

One thing you won't find here is anything about floppy diskettes.
NOS doesn't use them. There is nothing to format, nothing to insert,
and nothing to fill up.

**Got everything?** You need: an ATARI home computer; a FujiNet
connected to your wireless network; and the NOS disk image,
`NOS.atr`, always available at **apps.irata.online** in the
`Atari_8-bit/DOS/` folder. NOS is young software, best suited to
workflows where your ATARI and a modern computer work together. Its
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
3. Boot the disk. You'll see the banner and prompt:

```
#FUJINET NOS v0.8.0
N1:▮
```

That `N1:` prompt is the whole user interface — it names the network
drive NOS is currently working with. The ATARI's full-screen editor
works here: cursor up to an old command, fix a character, press
RETURN to run it again.

**Leave the NOS disk in the drive.** Like DOS, NOS keeps only part of
itself in memory; less-used commands wait on the NOS disk image as
*overlays*, loaded the moment you call them. Unlike DOS, NOS never
swaps a menu program over your work — your program in memory is left
alone (there is no MEM.SAV in NOS because nothing needs saving).

## Network, Not Disk

Every disk operating system before this one was built around a piece
of spinning plastic. NOS is built around a connection. Once a network
drive is *mounted*, everything you know from DOS carries over.

**Where did D: go?** ATARI software talks to diskettes through a
device named `D:`. NOS contains no disk software at all — no File
Management System, no menus, no formatting — but it still answers
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

The mount command is **NCD** (alias **CD**). Hand it a URL:

```
NCD N1:TNFS://192.168.1.20/
```

No news is good news: the prompt returns and drive 1 is mounted. See
where a drive points with **NPWD** (alias **PWD**):

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
current drive by typing its name alone:

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

| Protocol | Example | DIR | Read | Write | DEL/REN/MKDIR |
|----------|---------|-----|------|-------|----------------|
| **TNFS** | `NCD N1:TNFS://192.168.1.20/` | ✔ | ✔ | ✔ | ✔ |
| **SD** | `NCD N1:SD://fujinet/` | ✔ | ✔ | ✔ | ✔ |
| **FTP** | `NCD N2:FTP://ftp.pigwa.net/atari/` | ✔ | ✔ | (1) | (1) |
| **HTTP/HTTPS** | `TYPE N3:HTTPS://fujinet.online/` | (2) | ✔ | (2) | (2) |
| **SMB** | `NCD N1:SMB://DEN-PC/ATARI/` | ✔ | ✔ | ✔ | ✔ |
| **NFS** | `NCD N1:NFS://192.168.1.9/export/atari/` | ✔ | ✔ | ✔ | ✔ |
| **GDRIVE** | `NCD N1:GDRIVE://drive/atari/` | ✔ | ✔ | ✔ | (3) |

(1) where the server permits its guests — NOS logs into FTP as an
*anonymous* guest. (2) needs a WebDAV server; plain web sites are
read-only. (3) everything except RENAME.

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

Folders are always listed, whatever the pattern. In NOS, wild cards
belong to **DIR alone** — DEL, NCOPY, and RENAME take one plain
filename at a time (see workarounds under "What NOS Doesn't Do").

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

**One exception:** BASIC's NOTE and POINT jump around inside a file
by sector; a network stream has no sectors, so programs built on them
won't run from `N:`. Sequential files are right at home.

## Loading Programs

- `LOAD JUMPMAN.XEX` (alias `X`) — loads standard ATARI binaries,
  honoring init and run addresses. Non-binaries stop with
  `NOT A BINARY FILE`. Translation is switched off automatically for
  the load.
- **The shortcut:** type a bare word NOS doesn't recognize and it
  tries `LOAD WORD.COM` from the current drive. Every `.COM` on the
  drive is, in effect, a NOS command.
- `REENTER` (alias `REE`) — jump back into the last loaded program
  (its run/init address). Save first; some programs re-initialize.
- `RUN A000` — call machine code by hex address (four digits, no
  `$`; lead small addresses with a zero: `RUN 0600`).
- `CAR` — to the cartridge (or built-in BASIC) with memory
  preserved; type `DOS` there to come back.
- `BASIC ON|OFF` (alias `ROM ON|OFF`) — XL/XE only: swap built-in
  BASIC in/out without rebooting while holding OPTION. The border
  stays gray while ROM is in, as a reminder. `BASIC ON` when already
  on behaves like CAR.
- `SAVE FILE,START,END[,INIT][,RUN]` — write a memory range as a
  binary file; skip INIT but give RUN with a double comma:
  `SAVE MYPROG,2000,2FFF,,2000`.

## Copying Files

```
NCOPY MYFILE,MYFILE2
NCOPY N1:GAME.XEX,N2:GAME.XEX
NCOPY N1:GAME.XEX,N2:
NCOPY GAME.XEX,N2:GAMES/
NCOPY DAY2.TXT,LOG.TXT,A
NCOPY NOTES.TXT,P:
NCOPY NOTES.TXT,E:
```

(Alias **COPY**.) One file per command, no wild cards. A destination
of a bare `Nn:` or ending in `/` keeps the source's name. `,A`
appends instead of replacing. `P:` prints, `E:` shows on screen.
Copying a file onto itself is refused (`SAME FILE?`). Two cautions:
active NTRANS translation alters what's copied (set mode 0 for
binaries), and network destinations are built over drive `N4:`.

## Deleting and Renaming

- `DEL FILE` (aliases `ERASE`, `ERA`) — one file, immediately, no
  confirmation, no wild cards, case-sensitive, no undelete.
- `RENAME OLDNAME,NEWNAME` (alias `REN`) — give the new name bare
  (no drive/path). Known rough edge in this version: renaming through
  a relative path misfires; NCD to the file's folder first.
- `MKDIR DIRNAME` / `RMDIR DIRNAME` — create/remove directories
  where the protocol allows; RMDIR removes only *empty* directories.

## Text Files and Line Endings

`TYPE FILE` shows a text file a screenful at a time (any key pages,
ESC stops), coping with CR/LF as it reads. Point it only at text — a
big binary can overrun its buffer and corrupt memory. It works on
anything a drive can read, including `TYPE N3:HTTPS://...`.

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

The DOS 2.0S menu, translated:

| DOS menu | In NOS |
|----------|--------|
| A. Disk Directory | **DIR** |
| B. Run Cartridge | **CAR** (and **BASIC ON/OFF**) |
| C. Copy File | **NCOPY** |
| D. Delete File(s) | **DEL**, one file at a time |
| E. Rename File | **RENAME** |
| F./G. Lock/Unlock | not in NOS — permissions live on the server |
| H. Write DOS Files | not needed — NOS lives on its boot image |
| I. Format Disk | not needed — nothing to format |
| J. Duplicate Disk | not needed — copy files, or copy on the server |
| K. Binary Save | **SAVE** |
| L. Binary Load | **LOAD** (or **X**, or just the program's name) |
| M. Run At Address | **RUN** |
| N. Create MEM.SAV | not needed — NOS never overwrites your program |
| O. Duplicate File | **NCOPY** |

Everything missing has the same explanation: **NOS contains no File
Management System.** It cannot read or write diskettes or disk
images — not even the ones your FujiNet mounts in its disk slots.

- **No LOCK/UNLOCK** — whether a file may change is the server's
  decision; set permissions there. Write-protected files give a
  write error.
- **No wild cards in DEL/NCOPY/RENAME** — workaround: write a batch
  file (one line per file, cheap to make on a PC) and `SUBMIT` it.
- **No NOTE/POINT** — programs needing random access won't run from
  `N:`; sequential files are fine.
- **No diskettes at all** — when you need one: reboot into CONFIG
  and boot the disk image; or boot a classic DOS with the FujiNet
  `N:` handler (`n-handler.atr`) to copy between `D:` and `N:`
  side by side; or reach SD-card files directly with `SD://`.

And the ledger runs the other way: no diskette swapping, no 707-
sector ceiling, no menu crushing memory, directories that nest,
filenames that breathe, and drive 2 in another country.

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
| Error 170 | File not found — check case against DIR. Also what a mistyped bare command comes to (`WORD.COM` not found). |
| `NOT A BINARY FILE` | LOAD given a non-binary. |
| `SAME FILE?` | NCOPY refused to copy a file onto itself. |
| `NO CARTRIDGE` / `NO BUILT-IN BASIC` | CAR/BASIC found nothing to switch to. |
| `TOO MANY FILES OPEN` | No free IOCB channel. |

## Getting Help

```
HELP
HELP NOS
HELP NOS/MKDIR
HELP REF/ATASCII
```

HELP fetches articles over the network from the NOS project's GitHub
pages and shows them paged like TYPE. Topics: **NOS** (every
command), **MAP** (the ATARI memory map), **REF** (ATASCII, colors,
key codes, error codes), **ASM** (6502 reference), **DEV**, **UTL**.
Articles under a topic need the topic in the path (`HELP NOS/MKDIR`,
not `HELP MKDIR` — a 404 means the path was off). HELP reads over
drive `N4:`; a mount there can confuse it.

## Command Reference

Square brackets mark optional parts; `Nn:` means any drive `N1:`–
`N8:` (omitted = current drive). Commands may be typed in either
case.

| Command | Syntax | Aliases | Notes |
|---------|--------|---------|-------|
| **@NOSCREEN** | `@NOSCREEN` | | Stop echoing batch commands (the default state). |
| **@SCREEN** | `@SCREEN` | | Start echoing batch commands; `@` lines never echo. |
| **AUTORUN** | `AUTORUN URL` \| `?` \| `""` | | Full URL required; AppKey `/FujiNet/db790000.key` (max 64 chars); OPTION skips at boot. |
| **BASIC** | `BASIC ON\|OFF` | ROM | XL/XE built-in BASIC only; warmstarts; gray border while ROM in. |
| **CAR** | `CAR` | | To cartridge/BASIC, memory preserved; `NO CARTRIDGE` if none. |
| **CLS** | `CLS` | | Clear the screen. |
| **COLD** | `COLD` | | Coldstart; hold OPTION to keep BASIC out (XL/XE). |
| **DEL** | `DEL [Nn:][path/]file` | ERASE, ERA | One file; immediate; case-sensitive; quote spaces. |
| **DIR** | `DIR [Nn:][path/][pattern]` | | `*`/`?` patterns; dirs always listed; SPACE pauses, ESC stops. |
| **DUMP** | `DUMP START [END]` | | Hex dump, 8 bytes/line; 4 hex digits; ESC stops. |
| **FILL** | `FILL START END XX` | | Fill memory with byte XX. |
| **HELP** | `HELP [TOPIC[/ARTICLE]]` | | Fetched from GitHub over N4:. |
| **LOAD** | `LOAD [Nn:]file` | X | ATARI binaries; auto-disables translation; bare `WORD` = `LOAD WORD.COM`. |
| **MKDIR** | `MKDIR [Nn:][path/]dir` | | Where the protocol allows. |
| **NCD** | `NCD [Nn:]URL` \| `path` \| `..` \| `Nn:` | CD, CWD | Mount / navigate / unmount; no existence check; mounts shared. |
| **NCOPY** | `NCOPY FROM,TO[,A]` | COPY | One file; `,A` appends; bare `Nn:`/trailing `/` keeps name; `P:`/`E:` destinations; uses N4:. |
| **Nn:** | `Nn:` | | Make drive n (1–8) current; no mount check. |
| **NPWD** | `NPWD [Nn:]` | PWD | Show a drive's mount URL. |
| **NTRANS** | `NTRANS [Nn:] mode` | | 0 none, 1 CR, 2 LF, 3 CR/LF ⇄ EOL(155); text only. |
| **PASS** | `PASS password` | | Credential for protocols that log in; before the mount. |
| **PRINT** | `PRINT "string"` | | Show a message (batch files). |
| **REENTER** | `REENTER` | REE | Jump back into the last loaded program. |
| **REM** | `REM comment` | ', # | Ignored line (batch files). |
| **RENAME** | `RENAME [Nn:][path/]old,new` | REN | New name bare; avoid relative paths (known issue). |
| **RMDIR** | `RMDIR [Nn:][path/]dir` | | Empty directories only. |
| **RUN** | `RUN ADDR` | | 4 hex digits, no `$`; `RUN 0600`. |
| **SAVE** | `SAVE [Nn:]file,START,END[,INIT][,RUN]` | | Binary save; double comma skips INIT. |
| **SUBMIT** | `SUBMIT [Nn:]file` | @ | Runs commands from a text file; any line endings; quiet by default. |
| **TYPE** | `TYPE [Nn:]file` | | Paged text viewer; any key pages, ESC stops; text only. |
| **USER** | `USER name` | | Credential for protocols that log in; pair with PASS. |
| **WARM** | `WARM` | | Warmstart. |
| **XEP** | `XEP [40]` | | XEP80: 80-column screen, `XEP 40` back; load the handler first. |

---

*The complete `nos.s` source listing is printed in the back of the
PDF booklet, and lives at
`fujinet-nhandler/nos/src/nos.s`. NOS is by Thomas Cherryhomes and
Michael Sternberg, with optimizations by djaybee.*
