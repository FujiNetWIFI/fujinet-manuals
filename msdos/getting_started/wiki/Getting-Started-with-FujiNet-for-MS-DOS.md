# Getting Started with FujiNet for MS-DOS

Welcome! This guide will get the **RS-232 FujiNet** working on your IBM
Personal Computer (or close compatible) running MS-DOS. It is written for
the first-time FujiNet user — no knowledge of networks required. If you can
switch on your PC and use a diskette, you already know enough to begin.

This is the plain-text companion to the printed *Guide to Operations*, which
is styled as a tribute to the 1981 IBM PC manual of the same name.

---

## Contents

- [What Is FujiNet?](#what-is-fujinet)
- [What You Need](#what-you-need)
- [Know Your FujiNet](#know-your-fujinet)
- [Connecting the FujiNet](#connecting-the-fujinet)
- [Installing the Drivers](#installing-the-drivers)
- [First Power-On](#first-power-on)
- [Joining Your Wireless Network](#joining-your-wireless-network)
- [Host Slots and Drive Slots](#host-slots-and-drive-slots)
- [Loading a Disk](#loading-a-disk)
- [Leaving CONFIG](#leaving-config)
- [The Drive Letters](#the-drive-letters)
- [Mounting Disks from DOS (FMOUNT)](#mounting-disks-from-dos-fmount)
- [The Network Utilities](#the-network-utilities)
- [Mapping a Network Share (FNSHARE)](#mapping-a-network-share-fnshare)
- [The Printer](#the-printer)
- [Making and Copying Disks](#making-and-copying-disks)
- [Troubleshooting](#troubleshooting)
- [Reference Charts](#reference-charts)
- [Getting Help](#getting-help)

---

## What Is FujiNet?

The FujiNet is a small adapter that plugs into the **serial port** on the
back of your PC and gives it three new powers at once:

- **Virtual disk drives.** The FujiNet pretends to be a stack of diskette
  drives. Instead of physical floppies it reads **disk images** — exact
  copies of diskettes kept as files on a memory card or out on the network.
  DOS cannot tell the difference, and they appear as new drive letters
  (`C:`, `D:`, and beyond).
- **A network adapter.** A small radio joins your home wireless network.
  Plain-DOS utilities let any program copy files to and from the internet,
  and FujiNet-aware software can read the news, the weather, bulletin
  boards, and play games against real people worldwide.
- **A printer.** The FujiNet can stand in for the printer on `LPT1:`.
  Anything you print is captured and filed away as a finished document
  (by default, a PDF) you collect later.

No card to install, no case to open — it simply plugs onto the serial port.

---

## What You Need

- An **IBM PC, PC/XT, PC/AT, or compatible** running **MS-DOS / PC DOS 3.0
  or later**.
- A free **serial port** (COM port). Most PCs have one as a **9-pin**
  D-connector; some older machines have a **25-pin** connector, for which a
  cheap 9-to-25-pin adapter is used.
- A source of **USB power** for the FujiNet — a USB wall charger or a USB
  port. The FujiNet does **not** draw power from the serial port.
- A **2.4 GHz wireless network** and its password.
- *Optional:* a **microSD card** (64 GB or smaller, FAT32) for a disk
  library of your own.

> **Note:** The FujiNet's radio uses the 2.4 GHz band only. If your router
> shares one name across 2.4 GHz and 5 GHz bands and the FujiNet won't join,
> give the 2.4 GHz band its own name.

---

## Know Your FujiNet

Hold the FujiNet label-up, silver connector pointing away from you:

- **The serial connector** — the 9-pin D-connector at the front; this mates
  with your PC's serial port. A **knurled thumbscrew** at each side holds it
  on, finger-tight.
- **WiFi lamp (white)** — on top near the connector; glows steadily once on
  the network.
- **Bus lamp (orange)** — beside it; flickers when the PC and FujiNet are
  talking (like a drive's "in use" light).
- **Button A** — used only for firmware updates.
- **Reset button** — at the rear edge; restarts the FujiNet itself (not your
  PC). Safe to press.
- **USB-C jack** — rear edge; power, and firmware updates.
- **microSD slot** — rear edge; push to seat, push again to release.

---

## Connecting the FujiNet

> **Switch the PC OFF before connecting or disconnecting the FujiNet.**

1. Find the **9-pin serial (COM) port** on the back of the PC. On a machine
   with more than one, the first is **COM1**.
2. With the PC off, push the FujiNet squarely onto the port (it fits only
   one way) and turn the two thumbscrews finger-tight.
3. Connect **USB-C power**. The lamps flicker as it starts.
4. That's the whole hardware installation.

> **25-pin port?** Fit a 9-to-25-pin serial adapter between the FujiNet and
> the port, wiring the FujiNet to the 9-pin end.

---

## Installing the Drivers

The FujiNet's drivers and utilities — the **FujiNet Tools** — come on a
diskette image, or as a download from **fujinet.online**. Copy these onto
your everyday DOS start-up disk:

| File | What it is |
|------|-----------|
| `FUJINET.SYS` | the disk-drive driver (loads in `CONFIG.SYS`) |
| `FUJIPRN.SYS` | the printer driver (loads in `CONFIG.SYS`) |
| `CONFIG.EXE` | the CONFIG menu program |
| `FMOUNT.EXE` | mount/eject disk images from DOS |
| `NCOPY.EXE` `NGET.EXE` `NPUT.EXE` | copy files over the network |
| `FNSHARE.EXE` | map a network share to a drive letter |

Add two lines to **`CONFIG.SYS`**:

```
DEVICE=FUJINET.SYS FUJI_PORT=1 FUJI_BPS=115200
DEVICE=FUJIPRN.SYS
```

And one line to **`AUTOEXEC.BAT`** so CONFIG greets you at every start-up:

```
CONFIG.EXE
```

The settings on the `FUJINET.SYS` line:

- `FUJI_PORT` — the serial port: `1` for COM1, `2` for COM2, and so on. (For
  an unusual port: `FUJI_PORT=0x2F8,3`.)
- `FUJI_BPS` — the speed in bits per second. `115200` is standard and
  matches a FujiNet as it ships. Both ends must agree.
- Add `NOTIME` to the line if you do **not** want the FujiNet to set the DOS
  clock.

> **Note:** DOS itself must still boot from a diskette or hard disk the PC
> can already start from. The FujiNet's drives appear *after* DOS is running
> and the drivers have loaded.

---

## First Power-On

Restart the PC and watch the screen. As `CONFIG.SYS` is read, the driver
announces itself:

```
FujiNet driver 0.8 Open Watcom 2.0 on MS-DOS 6.2
```

That line means `FUJINET.SYS` loaded, found the FujiNet over the cable, and
added new drive letters beginning at `C:` (or the next free letter after
your real drives). When `AUTOEXEC.BAT` reaches `CONFIG.EXE`, the CONFIG
program fills the screen.

**Mini-test:** type `FMOUNT` at the DOS prompt. If it lists your FujiNet
drive letters, the adapter, cable, port, and drivers are all working:

```
▬▬▬ C: R 2:GAMES.IMG
    D: -- no disk selected --
```

---

## Joining Your Wireless Network

The first time CONFIG runs, it scans for networks. Signal strength is shown
by bars at the right (`▓▓▓` near, `░` far).

```
                            Welcome to FujiNet!
                       MAC: D0:1C:ED:C0:FF:EE
   ┌──────────────────── Available Networks ───────────────────┐
   │ HOMEBASE                                              ▓▓▓  │
   │ COCO-NUT                                              ▒▒   │
   │ RAINBOW-GUEST                                         ░    │
   │ <Enter a specific SSID>                                    │
   └────────────────────────────────────────────────────────────┘
              [ENTER] Select   [ESC] Re-scan   [S] Skip
```

- **↑ / ↓** move the bar; **[ENTER]** joins the highlighted network.
- **<Enter a specific SSID>** lets you type a hidden network's name.
- **[ESC]** re-scans; **[S]** skips WiFi for now.

Choose your network, type the password (capitals count) at the prompt, and
press **[ENTER]**. The white WiFi lamp comes on. The network and password
are remembered inside the FujiNet, so it reconnects by itself from now on.

Press **[C]** at any time to see the **Configuration screen** — the network
name, the IP address the FujiNet was given, and its firmware version. Note
the **IP Address**: typing it into a web browser on a modern computer or
phone opens the FujiNet's full settings page.

---

## Host Slots and Drive Slots

CONFIG's main screen is two short lists:

```
                              FujiNet Config
   ┌──────────────────────── HOST SLOTS ───────────────────────┐
   │ 1  SD                                                      │
   │ 2  apps.irata.online                                      │
   │ 3  tnfs.fujinet.online                                    │
   │ 4  Empty                                                  │
   └────────────────────────────────────────────────────────────┘
   ┌─────────────────────── DRIVE SLOTS ───────────────────────┐
   │ 2 1R C: GAMES.IMG                                         │
   │ 3 2R D: NEWS.IMG                                          │
   │   3  E: Empty                                             │
   └────────────────────────────────────────────────────────────┘
       [1-8] [E]dit  [RET] Browse  [C]onfig  [TAB] Drives  [ESC] Exit
```

- A **host** is any place disk images live: an internet library, a server on
  your own network, or the microSD card (always called `SD`). Eight host
  slots are remembered.
- A **drive slot** is one of the disk drives your PC sees. Each shows the
  **DOS drive letter** it answers to (`C:`, `D:`, …).

On the host list: **↑ ↓** or **[1]–[8]** to move, **[E]** to edit a slot's
host name, **[ENTER]** to browse it, **[TAB]** to switch to the drive list,
**[ESC]** to leave CONFIG. Good libraries to type into an empty slot:

- `tnfs.fujinet.online` — the community's main library
- `apps.irata.online` — applications and on-line services

---

## Loading a Disk

Move the bar to a host, press **[ENTER]**, and CONFIG opens its catalog.
Names ending in `/` are folders; step into the one for your machine (look for
`MSDOS/` or `PC/`).

```
                                Disk Images
   ┌────────────────────────────────────────────────────────────┐
   │ Host: tnfs.fujinet.online                                  │
   │ Fltr:                                                      │
   │ Path: /MSDOS/                                              │
   └────────────────────────────────────────────────────────────┘
   ┌────────────────────────────────────────────────────────────┐
   │    GAMES.IMG                                               │
   │    NEWS.IMG                                                │
   │    TOOLS.IMG                                               │
   └────────────────────────────────────────────────────────────┘
   [BKSP] Up Dir  [N]ew  [F]ilter  [C]opy  [ENTER] Choose  [ESC] Abort
```

- **↑ ↓** move the bar (keep going past the bottom to page through).
- **[ENTER]** opens a folder, or chooses a disk image.
- **[BKSP]** backs up a folder; **[F]** filters (e.g. `W*.IMG`).

Choose a disk image and CONFIG asks which **drive slot** it goes in,
showing the file's details:

- **↑ ↓** choose a slot.
- **[ENTER]** loads it **read-only** (safe; nothing can change it).
- **[W]** loads it **read/write** (programs can save onto it).
- **[E]** ejects whatever is in the slot.

> **Note:** Public libraries don't allow writing — load their disks
> read-only. Save **[W]** for disks on your own SD card or your own server.

---

## Leaving CONFIG

When your disks are loaded, press **[ESC]**. CONFIG shows
`Mounting all slots...` and hands control to DOS. Your disks wait at their
drive letters — type `DIR C:` and see.

---

## The Drive Letters

Each FujiNet drive slot answers to an ordinary DOS drive letter, handed out
after your real drives (usually `C:`, `D:`, …). They behave exactly like
diskette drives:

```
DIR C:
COPY C:*.* D:
C:
```

`DIR`, `COPY`, `TYPE`, `FORMAT`, and the rest all work on FujiNet drives. A
read/write disk accepts saves; a read-only disk politely refuses.

---

## Mounting Disks from DOS (FMOUNT)

You need not return to CONFIG to manage disks. `FMOUNT` does the same from
the DOS prompt. Typed alone it lists your FujiNet drives:

```
C:\> FMOUNT
▬▬▬ C: R 2:GAMES.IMG
─■─ D: R 3:NEWS.IMG
    E: -- no disk selected --
```

The mark at the left shows each drive's state: three bars = loaded and
ready, barred-dash = chosen but not yet mounted, blank = empty.

| Command | What it does |
|---------|--------------|
| `FMOUNT -a` | Mount every slot that has a disk chosen |
| `FMOUNT C:` | Mount the disk chosen for drive C: |
| `FMOUNT -w C:` | Mount drive C: read/write |
| `FMOUNT -e C:` | Eject the disk in drive C: |
| `FMOUNT -t 2` | Show which drive letter slot 2 became |

---

## The Network Utilities

Three small programs reach the network through **N: names** — a protocol, a
colon, and an address, such as `N:HTTP://` or `N:TNFS://`.

**NGET** — fetch one file:

```
C:\> NGET N:HTTP://example.com/files/manual.txt MANUAL.TXT
      4096 bytes transferred.
```

**NPUT** — send one file:

```
C:\> NPUT REPORT.TXT N:TNFS://192.168.1.10/uploads/REPORT.TXT
```

**NCOPY** — an interactive copy session on a host:

```
C:\> NCOPY N:TNFS://tnfs.fujinet.online/
ncopy> dir
ncopy> cd MSDOS
ncopy> get TOOLS.IMG TOOLS.IMG
ncopy> quit
```

Inside `NCOPY`: `dir` (or `ls`) lists, `cd` changes folder, `get` and `put`
copy, `quit` finishes. If the host needs a name and password, you'll be
asked.

The protocols the FujiNet understands include `HTTP`/`HTTPS`, `TNFS`, `FTP`,
`SMB`, `NFS`, `TCP`, `UDP`, `SSH`, and `TELNET`. Any may be used where an N:
address is asked for.

---

## Mapping a Network Share (FNSHARE)

`FNSHARE` makes a whole network folder appear as a DOS drive letter:

```
C:\> FNSHARE map L: N:TNFS://192.168.1.10/shared
FujiNet installed as L:
```

From then on, `L:` is the shared folder, usable by `DIR`, `COPY`, and your
programs. It stays resident after you run it, and prompts for a name and
password if the server asks.

> **Note:** `FNSHARE` maps a folder of ordinary files. To run software from
> a **disk image**, load it into a drive slot with CONFIG or `FMOUNT`
> instead.

---

## The Printer

Once `FUJIPRN.SYS` is loaded, anything sent to `LPT1:` goes to the FujiNet:

```
C:\> COPY README.TXT LPT1:
C:\> PRINT REPORT.TXT
```

You can also press **Shift-PrtSc** to print the screen, or use the **Print**
command in any program. The FujiNet collects whatever you send and turns it
into a tidy document — by default a PDF — waiting on its web page (the
address on the Configuration screen). The FujiNet can imitate several kinds
of printer; choose which from its web page.

---

## Making and Copying Disks

While browsing a host you can write to (your SD card, say):

- Press **[N]** to make a **new, blank disk image**. CONFIG offers the
  standard PC sizes — `[1] 360K`, `[2] 720K`, `[3] 1.2MB`, `[4] 1.44MB` —
  then asks for a name. Give the new image a file system with DOS `FORMAT`
  before first use.
- Highlight a file and press **[C]** to **copy** it. CONFIG asks which host
  to copy *to* (choose `SD`), lets you pick the folder, and copies it across
  with no help from the PC's memory.

---

## Troubleshooting

| Symptom | Try this |
|---------|----------|
| Driver says it can't find the FujiNet | Check power and the connector; confirm `FUJI_PORT` names the right COM port; make `FUJI_BPS` match the FujiNet (standard `115200`). |
| No drive letters, no driver message | Check `DEVICE=FUJINET.SYS` is in `CONFIG.SYS`, spelled right, and the file is on the start-up disk. |
| Garbled characters / bad copies | Speed mismatch or a flaky port — match `FUJI_BPS` at both ends, try a slower speed (`19200`), or another port. |
| Won't join WiFi | Check the password (capitals count); the network must offer a **2.4 GHz** band; move nearer the router. |
| Host won't open / no files | Check the host name for typos; the server may be down; confirm the white WiFi lamp is lit. |
| Can't save to a FujiNet drive | The disk is read-only — switch it to read/write with **[W]** in CONFIG or `FMOUNT -w`. Public-library disks can't be made writable; copy one to your own card first. |
| Printout never appears | Confirm `FUJIPRN.SYS` is loaded and your program prints to `LPT1:`; refresh the FujiNet's web page. |
| Drive letter clashes | Load `FUJINET.SYS` earlier in `CONFIG.SYS`, or adjust the other driver; use `FMOUNT` to see the letters. |

---

## Reference Charts

**Driver settings** (on the `DEVICE=FUJINET.SYS` line):

| Setting | Default | Meaning |
|---------|---------|---------|
| `FUJI_PORT` | `1` | Serial port 1–4, or address + IRQ (`0x2F8,3`) |
| `FUJI_BPS` | `115200` | Speed in bits per second; must match the FujiNet |
| `NOTIME` | — | If present, don't set the DOS clock from the FujiNet |

**CONFIG keys:** `↑ ↓` move · `1`–`8` jump · `ENTER` choose/load read-only ·
`W` load read/write · `E` edit host / eject drive · `TAB` switch lists ·
`C` configuration screen · `N` new disk · `F` filter · `BKSP` up a folder ·
`ESC` leave CONFIG.

**Commands:** `CONFIG`, `FMOUNT [-a -w -e -t]`, `NGET src dest`,
`NPUT src dest`, `NCOPY host`, `FNSHARE map L: url`.

**New-disk sizes:** `[1]` 360 KB · `[2]` 720 KB · `[3]` 1.2 MB · `[4]` 1.44 MB
· `[C]` custom.

---

## Getting Help

The FujiNet is the work of a friendly worldwide community:

- **Web site** — [fujinet.online](https://fujinet.online): downloads,
  documentation, the firmware updater, and a current list of public
  libraries.
- **Chat server** — linked from the web site; a real person usually answers
  within the hour.
- **Users' group** — for show-and-tell and tips.
- **Source code** — [github.com/FujiNetWIFI](https://github.com/FujiNetWIFI):
  everything is open.

When you ask for help, mention your PC and DOS version, the serial port and
speed, the firmware version from the Configuration screen, and the exact
wording of any message you saw.

*Welcome to the network. We're glad you're here.*
