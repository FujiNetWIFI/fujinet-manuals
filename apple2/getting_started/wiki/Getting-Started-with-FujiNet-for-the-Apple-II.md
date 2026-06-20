# Getting Started with FujiNet for the Apple II

*Easy-to-follow instructions on setting up and using FujiNet and its CONFIG program with the Apple II family — the Apple IIc, IIc Plus, IIGS, and any Apple II with a SmartPort. Written for first-time FujiNet users; no networking experience required.*

![FujiNet on an Apple IIc](images/cover-photo.jpg)

---

## Contents

1. [What Is FujiNet?](#what-is-fujinet)
2. [What You Need](#what-you-need)
3. [Know Your FujiNet](#know-your-fujinet)
4. [Which Apple Do You Have?](#which-apple-do-you-have)
5. [Hooking Up Your FujiNet](#hooking-up-your-fujinet)
6. [Booting CONFIG on Your Machine](#booting-config-on-your-machine)
7. [Connecting to Your Wireless Network](#connecting-to-your-wireless-network)
8. [The Main Screen: Hosts and Drives](#the-main-screen-hosts-and-drives)
9. [Browsing a Host](#browsing-a-host)
10. [Mounting a Disk Image](#mounting-a-disk-image)
11. [Booting Your Software](#booting-your-software)
12. [The Disk II Side](#the-disk-ii-side)
13. [Creating a New Disk Image](#creating-a-new-disk-image)
14. [Copying Files Between Hosts](#copying-files-between-hosts)
15. [The Config Screen](#the-config-screen)
16. [The Web Control Panel](#the-web-control-panel)
17. [The SmartPort Device List](#the-smartport-device-list)
18. [The Lobby](#the-lobby)
19. [More Things FujiNet Can Be](#more-things-fujinet-can-be)
20. [Troubleshooting](#troubleshooting)
21. [Key Reference Charts](#key-reference-charts)
22. [Glossary](#glossary)
23. [Learning More](#learning-more)

---

## What Is FujiNet?

FujiNet is a wireless network adapter and multi-peripheral for your Apple II. It
plugs into the disk port and speaks **SmartPort** — Apple's own protocol for
intelligent disk devices — so to your Apple it simply looks like a chain of
well-behaved drives. It gives your Apple:

* **Eight virtual SmartPort disk drives.** Disk images (software stored as files)
  can be loaded — "mounted" — into any of eight *drive slots* and used as if they
  were real drives, up to 32 MB each.
* **Disk II emulation.** On systems wired for it, FujiNet can also pretend to be
  a genuine Disk II — including bit-perfect, copy-protected **WOZ** images that
  only make sense on real (or convincingly faked) 5¼-inch hardware.
* **Access to file servers on the Internet.** Public servers (called **TNFS
  hosts**) offer entire libraries of Apple II software you can browse and boot in
  seconds.
* **A microSD card slot.** Your own library, on a card in the FujiNet itself.
* **A virtual printer, modem, clock, network adapter, and CP/M machine.** More on
  these in [More Things FujiNet Can Be](#more-things-fujinet-can-be).

**CONFIG** is the program you use to manage all of this. It is stored inside the
FujiNet itself and served to the Apple as a boot disk. CONFIG is what this guide
teaches: every screen, every key, every function.

## What You Need

* An Apple II with a SmartPort — see [Which Apple Do You Have?](#which-apple-do-you-have)
* A FujiNet for the Apple II (the **FujiApple**, Rev1 or later recommended)
* The connector that fits your machine: the **DB-19 adapter** for machines with
  the 19-pin disk port, or an **IDC20 ribbon cable** for controller-card headers
* A 2.4 GHz Wi-Fi network and its password. *FujiNet's radio supports 2.4 GHz
  only; a 5 GHz-only network will not be seen.*
* *(Optional)* A microSD card, formatted FAT32 (exFAT is not supported)

## Know Your FujiNet

![Parts of the Apple II FujiNet](images/fujiapple-front.jpg)

| Part | What it does |
|---|---|
| **IDC20 disk connector** | Connects to the Apple — directly to a controller card header by ribbon cable, or to a DB-19 disk port through the adapter |
| **microSD slot** | Push-push socket for an optional FAT32 card holding your disk images |
| **WiFi LED** (white) | Lit when FujiNet is connected to your wireless network |
| **Bus LED** (amber) | Flickers with SmartPort/Disk II activity, like a drive's in-use lamp |
| **Button A** | Reserved for future functions |
| **Reset button** | Restarts the FujiNet (not the Apple) |
| **USB-C connector** | Firmware updates; optional power so the web control panel stays up while the Apple is off |

There is **no power switch**: the FujiNet is powered by the Apple through the
disk connector and wakes and sleeps with the machine.

## Which Apple Do You Have?

### Native SmartPort (just plug in)

* **Apple IIGS**
* **Apple IIc** — *except* the very first ROM (version 255)
* **Apple IIc Plus**
* **Laser 128**

To check a IIc's ROM: power on, press `CTRL-RESET` for a BASIC prompt, and type
`PRINT PEEK(64447)`. An answer of **255** is the original ROM — no SmartPort
(Apple offered a free upgrade in 1985, so many machines have a newer ROM). **0**,
**3**, or **4** all include SmartPort; **5** means a IIc Plus.

### SmartPort by expansion card (Apple II+, IIe)

* **softSP + a 5¼-inch drive controller** — softSP is firmware that teaches an
  ordinary card to speak SmartPort. Available as the ready-made
  [KBOOHK softSP card](https://ct6502.org/product/softsp), an
  [A2Pico](https://jcm-1.com/product/a2pico/) running
  [softSP](https://github.com/oliverschmidt/softsp), or a DIY (E)EPROM for a
  Grappler+ or Super Serial Card. Use **v6 or newer**. The FujiNet connects to
  the partnered drive controller's disk header/port.
* **A genuine SmartPort card** — the original **Apple Liron** (UniDisk 3.5
  controller), or a modern equivalent like A2Heaven's
  [Liron Reborn](https://www.a2heaven.com/webshop/index.php?rt=product/product&product_id=186)
  or the open-source [SmartDiskII](https://github.com/btb/SmartDiskII) (a Liron
  with the IWM replaced by Disk II circuitry). SmartPort drives only; no Disk II
  emulation. Connect via the DB-19 adapter or an IDC20 cable.
* **[Yellowstone](https://www.bigmessowires.com/yellowstone)** — modern universal
  disk controller. IDC20 cable **only** (no DB-19 adapter), and it runs in either
  SmartPort *or* Disk II mode, not both at once. Because it handles the disks
  itself rather than passing the bus through, it serves FujiNet **disk drives
  only** — not the network, printer, modem, or CP/M devices.

> ⚠️ **Ribbon cable warning.** When connecting to a Disk II-style controller
> header, an IDC20 plug offset by one row or column of pins **will damage
> hardware**. Check the alignment at least twice before powering up — no pins
> should be visible outside the plug.

## Hooking Up Your FujiNet

> ⚠️ **Never plug anything into an Apple's disk port while the power is on.**

**IIc, IIc Plus, IIGS, Laser 128:**

1. Switch off the Apple and everything attached to it.
2. Fit the DB-19 adapter to the FujiNet's IDC20 connector (directly or through a
   short ribbon cable).
3. Plug the adapter into the 19-pin disk port on the back panel.
4. Remove any floppy from the internal drive.
5. Switch on the monitor, then the Apple.

**II Plus / IIe:**

1. Switch off the Apple.
2. Seat the softSP card (slot 5 is traditional) and its partner 5¼-inch drive
   controller (slot 6 is traditional) — or a Liron/Yellowstone.
3. Connect the FujiNet to the drive controller's disk connector (ribbon cable or
   DB-19 adapter as appropriate). Check ribbon alignment twice.
4. Switch on.

Adapters are available from [mozzwald.com](https://mozzwald.com/product-category/appleii/),
[BMOW](https://shop.bigmessowires.com/products/db-19-adapter-and-extension-cable),
[A2Heaven](http://www.a2heaven.com/webshop/index.php?rt=product/product&product_id=125),
or [build your own](https://github.com/FujiNetWIFI/fujinet-hardware/tree/master/AppleII).

If you also have real drives: the simplest arrangement while learning is the
FujiNet alone on the port. Daisy chains work — the time-honored rule applies:
5¼-inch drives always go **last** in the chain.

## Booting CONFIG on Your Machine

| Machine | How CONFIG boots |
|---|---|
| **IIc, IIc Plus** | Automatically at power-on (internal drive empty) |
| **IIGS** | Open the Control Panel (`CTRL`-`Open Apple`-`ESC`) → **Slots** → set **Slot 5** to *Smart Port* and **Startup Slot** to *5* (or *Scan*), then reboot |
| **II Plus / IIe** | Press `CTRL-RESET`, type `PR#5` (your softSP slot) and press `RETURN` |

## Connecting to Your Wireless Network

The first time CONFIG boots, the FujiNet scans for networks and lists what it
hears (the stars at right are signal strength):

```
         Welcome to FujiNet!

MAC Address:  4C:11:AE:0D:FA:9C

  HOMEBASE                          ***
  BRAEBURN                          **
  CORTLAND-GUEST                    *



          Found 3 networks.
    Hidden SSID  Rescan  Skip
          RETURN to select
```

* Move the highlight bar with the arrows and press `RETURN` on your network.
* `H` lets you type a hidden network's name; `R` rescans; `S` skips Wi-Fi setup.
* Type the password (case-sensitive, up to 64 characters, echoed as `*`) and
  press `RETURN`.

> 💡 On an Apple II or II Plus there are no up/down arrow keys: use `I` (up),
> `J` (left), `K` (right), `M` (down) anywhere in CONFIG, and `T` for `TAB`.
> While typing a password on these machines, `ESC` toggles upper/lower case.

The network is saved in the FujiNet's flash (and to `fnconfig.ini` on the SD
card, if present); from now on it reconnects automatically. The white LED means
you're on the air.

> ⚠️ FujiNet works on **2.4 GHz networks only**. If your router runs a mixed
> 2.4/5 GHz network under one name and the FujiNet won't join, give the 2.4 GHz
> band its own network name.

## The Main Screen: Hosts and Drives

```
────────────────────────────── Host List
1 SD
2 TNFS.FUJINET.ONLINE
3 APPS.IRATA.ONLINE
4 FUJINET.DILLER.ORG
5 Empty
6 Empty
7 Empty
8 Empty

D─R─H────────────────── SmartPort Drives
1 R 2:ProDOS.2.4.3.po
2     Empty
3     Empty
4     Empty
5     Empty
6     Empty
7     Empty
8     Empty

1-8:Host  Edit  RETURN:Select files
Config TAB:Drives SpDevs Lobby ESC:Boot
```

* **Top half — the host list:** eight slots naming the places disk images come
  from. A host can be a TNFS server (hostname or IP), an `SMB://` or `FTP://`
  URL (anonymous access), or the special name `SD` for the FujiNet's own card.
* **Bottom half — the drive list:** the eight SmartPort drives the Apple sees.
  Reading a line: drive number, **R**(ead-only) or **W**(rite), the host slot
  the image came from, and the image name. The `D─R─H` header labels those
  columns.
* `TAB` jumps between the lists; arrows (or `IJKM`) move the bar; `1`–`8` jumps
  to a slot. In the menus, the highlighted capital is the key to press.

Press `E` on a host slot to edit it (up to 32 characters). Hostnames typed in
lowercase may reappear in capitals — harmless. Good starter hosts:

* `SD` — the microSD card inside your FujiNet
* `tnfs.fujinet.online` — the community's main library
* `apps.irata.online` — applications and online services
* `fujinet.diller.org` — more disk images

## Browsing a Host

Highlight a host and press `RETURN`:

```
TNFS.FUJINET.ONLINE
/Apple II/Games/

Action/
Arcade/
Utilities/
AppleWorks.2mg
Airheart.po
Choplifter.dsk
Karateka.po          ← highlight bar
Lode.Runner.po
Marble.Madness.2mg
Oregon.Trail.po
Prince.of.Persia.po
ProDOS.2.4.3.po

[...]

RETURN:Select file to mount
<-Updir  ESC:Abort  Filter  New  Copy
```

* Names ending in `/` are folders — `RETURN` steps in, **left arrow** (or
  `DELETE`) steps back out.
* Fifteen entries show per page; `[...]` at top or bottom means more. `<` and
  `>` flip pages.
* `F` filters by wildcard (e.g. `*karate*`); `ESC` returns to the main screen.

## Mounting a Disk Image

Press `RETURN` on a disk image and CONFIG asks where to put it, showing the
file's date and size:

```
─────────────────────── SmartPort Drives
1 R 2:ProDOS.2.4.3.po
2     Empty              ← highlight bar
3     Empty
...

File details
  MTime: 2026-06-11 19:02:44
   Size: 140 K

Karateka.po

 1-8 Select drive or use arrow keys
 RETURN/R:Insert read only
 W:Insert read/write  ESC:Abort
```

* `RETURN` or `R` inserts **read-only** — like opening the write-protect tab.
* `W` inserts **read/write**.
* `E` ejects from the highlighted drive; `ESC` goes back to the browser.

> ⚠️ Public TNFS libraries don't allow writing — mount their disks read-only.
> Save `W` for images on your SD card or your own server.

Back on the main screen, `TAB` into the drive list to manage what's mounted:
`E` ejects, `R`/`W` switches a drive's mode in place.

## Booting Your Software

With a bootable image in **drive 1**, press `ESC` on the main screen. CONFIG
prints `RESTARTING...` and restarts the Apple itself, booting straight into
your disk just as a fresh power-on would. To return to CONFIG later, power the
Apple off and on again — a plain `CTRL-RESET` won't do it, since on an Apple II
that drops you into BASIC or the monitor rather than rebooting the machine.

> 💡 How many of the eight drives software sees depends on the operating system.
> ProDOS 2.x — including the recommended 2.4.3 — handles up to fourteen SmartPort
> drives, so all eight FujiNet slots are usable. Only the older ProDOS 1.x was
> limited to four. Keep your boot disk in drive 1 and you're safe either way.

## The Disk II Side

DOS 3.3 disks, copy-protected games, and anything that talks to drive hardware
directly won't run from a SmartPort drive. For those, FujiNet emulates a real
Disk II. If a Disk II-style controller is wired to your FujiNet (the
softSP + controller combination), a `D` option appears on the main screen —
press it to flip the drive list between SmartPort view and Disk II view:

```
D───R─H────────────────── Disk II Drives
S6D1R 2:Choplifter.woz   ← highlight bar
S6D2    Empty

Eject  Read only  Write
TAB:Host slots  ESC:Boot
Drives toggle (SP or DiskII)
```

The label shows which real-world position each emulated disk occupies — `S6D1`
is slot 6, drive 1. Mount 140K 5¼-inch images here (`.dsk`, `.do`, `.po`,
`.woz`) and boot them with `PR#6`, just like 1983.

* **WOZ images are read-only by nature.** Plain 16-sector images (DSK/DO/PO)
  can be written in Disk II mode with current firmware.
* Supported image types by drive type:

| Drive type | DSK/DO | WOZ | PO | HDV | 2MG |
|---|:-:|:-:|:-:|:-:|:-:|
| SmartPort | ProDOS images only | — | ✅ | ✅ | ✅ |
| Disk II (140K) | ✅ | ✅ | ✅ | — | — |

## Creating a New Disk Image

While browsing any host you can write to (your SD card, say), press `N`.
CONFIG asks three questions in the menu area:

```
 New media: Select type
PO  2MG  DOS 3.3

 New media: Select size
140K  800K  32MB

 New media: Enter filename
] saves.po_
```

1. **Type:** `P` = ProDOS-order (`.po`), `2` = 2MG, `D` = DOS 3.3 (`.do`,
   always 140K — the size question is skipped).
2. **Size:** `1` = 140K, `8` = 800K, `3` = 32MB. *Secret option:* press `C`
   and type any number of 512-byte blocks for a custom size.
3. **Name:** type it (with extension) and press `RETURN`.

Then choose a drive, and the new image is mounted read/write. Like any disk
fresh from the shrink-wrap, **it needs formatting** — boot your OS and format
it there (ProDOS's filer, or `INIT` under DOS 3.3).

## Copying Files Between Hosts

Found something on a network library you'd like to keep locally?

1. Highlight the disk image in the browser and press `C`.
2. Choose the destination host (your SD card, say) and press `RETURN`.
3. Walk to the destination folder, then press `C` again to start the copy.

```
              Copying file from:

             TNFS.FUJINET.ONLINE
/Apple II/Games/Karateka.po

                Copying file to:

                                      SD
/games/Karateka.po
```

The FujiNet does the transfer itself — no Apple memory involved.

## The Config Screen

Press `C` on the main screen:

```
   F U J I N E T      C O N F I G

    SSID: HOMEBASE
Hostname: fujinet
      IP: 192.168.1.99
 Netmask: 255.255.255.0
     DNS: 192.168.1.1
     MAC: 4C:11:AE:0D:FA:9C
   BSSID: A4:2B:8C:11:0D:E5
   FNVer: 1.5.1 2026-04-18
  CONFIG: v1.5

      Change SSID  Reconnect
   Press any key to return to hosts
      FujiNet printer enabled
```

`C` here switches to a different wireless network; `R` reconnects. Note the IP
address — you'll want it for the web control panel.

## The Web Control Panel

While the FujiNet is powered, browse to its IP address — or just
`http://fujinet.local` — from any modern computer on the same network. From
there you can rename the device, choose printer emulations, adjust boot
options, manage Wi-Fi, collect printer output, and update firmware.

## The SmartPort Device List

Press `S` on the main screen and everything the FujiNet is impersonating
answers roll call:

```
 SMARTPORT DEVICE LIST

Unit #1  Name: FUJINET_DISK_0
Unit #2  Name: FUJINET_DISK_1
Unit #3  Name: FUJINET_DISK_2
Unit #4  Name: FUJINET_DISK_3
Unit #5  Name: FUJINET_DISK_4
Unit #6  Name: FUJINET_DISK_5
Unit #7  Name: FUJINET_DISK_6
Unit #8  Name: FUJINET_DISK_7
Unit #9  Name: CPM
Unit #10 Name: FN_CLOCK
Unit #11 Name: NETWORK
Unit #12 Name: THE_FUJI

 Press any key to continue
```

## The Lobby

Press `L` on the main screen and CONFIG asks `Boot to Lobby? Y/N`. Say yes and
your Apple boots the **Lobby** — a live directory of online, multiplayer games
being played right now on FujiNet-equipped 8-bit machines everywhere. Pick a
game and you're seated at the table.

## More Things FujiNet Can Be

* **Printer.** Captures printing from SmartPort-aware software and renders it
  as a PDF, emulating an Epson-compatible dot-matrix printer — collected from
  the web control panel. On a IIc, printing through FujiNet takes a custom ROM;
  ask the community.
* **Clock.** SmartPort-aware software can read real network time.
* **Modem.** Answers Hayes commands and "dials" telnet BBSes.
* **CP/M.** A complete emulated CP/M machine (RunCPM) with storage on the
  microSD card. (Rev0/Rev00 prototypes need a hardware mod for CP/M.)
* **Network adapter.** A growing catalog of native apps — weather, news,
  trackers, multiplayer games — talks to the network device directly.

## Troubleshooting

**The Apple powers on but CONFIG never appears**
* A floppy is in the internal drive — remove it and reset.
* IIGS: Slot 5 must be *Smart Port* and Startup Slot *5* (or *Scan*).
* II+/IIe: CONFIG doesn't auto-boot — `CTRL-RESET`, then `PR#5`.
* IIc: check the ROM (`PRINT PEEK(64447)`; 255 = no SmartPort in ROM).
* Ribbon cables: aligned, fully seated, no stray pins.

**The scan finds no networks, or won't connect**
* 2.4 GHz only; split a mixed 2.4/5 GHz network into separate names.
* Hidden network: press `H` and type the name exactly.
* Passwords are case-sensitive (on a II/II+, mind the `ESC` case toggle).

**A host slot won't open**
* Check the spelling (`E` to look); try `tnfs.fujinet.online`.
* For `SD`: card inserted and FAT32? exFAT is not recognized.

**A mounted disk won't boot**
* The Apple boots SmartPort drive 1 — is your disk there?
* Is the image bootable at all? Many are data disks.
* DOS 3.3 / WOZ software needs the Disk II side and `PR#6` (or the slot your Disk II controller card is in), not SmartPort.

**I can't save onto a disk**
* Mounted read-only? `TAB` to drives, highlight, press `W`.
* Public TNFS hosts refuse writes — copy the image to SD first.
* WOZ images are always read-only.

**Small oddities that are not problems**
* Lowercase hostnames reappear in capitals.
* Only four of the eight SmartPort drives appear? You're on ProDOS 1.x, which
  caps out at four. ProDOS 2.x (2.4.3 recommended) sees all eight.
* The `D` drives-toggle only appears when a Disk II controller is detected.

## Key Reference Charts

*Anywhere:* arrows move the bar; on machines without all four arrows,
`I`/`J`/`K`/`M` = up/left/right/down and `T` = `TAB`.

**Main screen — host list**

| Key | Function |
|---|---|
| `1`–`8` | jump to host slot |
| `E` | edit the highlighted host (32 chars max) |
| `RETURN` | browse the highlighted host |
| `TAB` | switch to the drive list |
| `C` | show config (network details; change SSID) |
| `S` | list all SmartPort devices |
| `L` | boot to the Lobby |
| `D` | toggle SmartPort/Disk II view (when shown) |
| `ESC` | reboot the Apple into the mounted disk |

**Main screen — drive list**

| Key | Function |
|---|---|
| `E` | eject the highlighted image |
| `R` / `W` | set read-only / read-write |
| `TAB` | back to the host list |
| `ESC` | reboot the Apple into the mounted disk |

**File browser**

| Key | Function |
|---|---|
| `RETURN` | open folder / select disk image |
| left arrow / `DELETE` | up one folder |
| `<` / `>` | previous / next page |
| `F` | wildcard filter (e.g. `*karate*`) |
| `N` | new blank disk image |
| `C` | copy the highlighted file to another host |
| `ESC` | back to the main screen |

**Drive picker (after selecting an image)**

| Key | Function |
|---|---|
| `1`–`8` | choose a drive |
| `RETURN` / `R` | insert read-only |
| `W` | insert read/write |
| `E` | eject from the highlighted drive |
| `ESC` | back to the browser |

**Wi-Fi setup**

| Key | Function |
|---|---|
| `RETURN` | join the highlighted network |
| `H` | enter a hidden network name |
| `R` | rescan |
| `S` | skip Wi-Fi setup |
| `ESC` | (II/II+ only) toggle case while typing |

## Glossary

* **SmartPort** — Apple's protocol for intelligent disk devices, introduced
  with the UniDisk 3.5. One connector, many devices.
* **Host** — any place disk images live: a TNFS/SMB/FTP server, or the
  FujiNet's SD card.
* **TNFS** — a simple file-server protocol beloved of 8-bit machines.
* **Drive slot** — one of the eight emulated SmartPort drives (or two Disk II
  drives) the Apple sees.
* **Mounting** — loading a disk image into a drive slot.
* **Disk image** — a file containing the complete contents of a disk
  (`.po`, `.hdv`, `.2mg`, `.dsk`, `.do`, `.woz`).
* **WOZ** — a bit-perfect recording of an original floppy, copy protection
  included; playable only on (emulated) Disk II hardware.
* **softSP** — firmware that teaches an ordinary controller card to speak
  SmartPort.
* **Lobby** — FujiNet's live directory of online multiplayer games.

## Learning More

* [fujinet.online](https://fujinet.online) — news, downloads, documentation,
  and the community Discord
* [Apple II & III FujiNet Quickstart Guide](https://github.com/FujiNetWIFI/fujinet-firmware/wiki/Apple-II-&-III-FujiNet-Quickstart-Guide)
  — the firmware wiki's deeper reference
* [github.com/FujiNetWIFI](https://github.com/FujiNetWIFI) — firmware, CONFIG,
  hardware designs, applications, and this manual's source
* [FujiNet-Flasher](https://fujinet.online/download/) — firmware updates over
  USB

---

*This guide is the wiki edition of* Getting Started with FujiNet for the Apple
II, *a print manual styled after the 1984 Apple IIc Owner's Manual. Content
verified against the `fujinet-config` and `fujinet-firmware` sources, June
2026. Apple, Apple IIc, Apple IIGS, ProDOS, and SmartPort are trademarks of
Apple Inc., used in tribute. FujiNet is a community project not affiliated
with Apple.*
