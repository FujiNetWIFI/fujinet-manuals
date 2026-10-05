#import "../lib.typ": *

= CONFIG and the Lobby

#lead[CONFIG is the program the cartridge runs when you turn the console on:
WiFi, host slots, a file browser and a loader, in 32K, dressed as the
Famicom's Family BASIC.]

#shots("cfg-hosts", "cfg-nesbook", "cfg-mount", w: 1.95in, caption: [The host
slots; a directory on the SD card; and loading `hello.bin` from it, with the
bar filled by BOOT_PCT and the count by BOOT_GOT and BOOT_TOT.])

== Where it lives

CONFIG is in fujinet-config, in its `nes/` directory, written in cc65 C
against fujinet-lib. It is built like any other program in this manual -- the
library's linker configuration, the claim, `checkrom.py` -- and then *baked*:
the cartridge firmware's `build-cart.sh` turns `build/config.nes` into a
C array inside the RP2354B's firmware. At power-on the loader copies it from
there into the SRAMs, which takes about a sixth of a second.

#codepanel("Building CONFIG and baking it into the cartridge",
"cd fujinet-config/nes
make                              # build/config.nes
make PICO_NES=~/fujinet-firmware/pico/nes cart
                                  # copy it in, build fujines.uf2")

== The screens

CONFIG is a state machine with one source file per state:

#tbl((auto, auto, 1fr),
  th[State], th[File], th[What it does],
  [CHECK_WIFI], [`st_wifi.c`], [WiFi on? Connected (status 3)? A network saved? Then CONNECT, or SET.],
  [CONNECT_WIFI], [`st_wifi.c`], [Asks for the WiFi status every two seconds, twenty times; B gives up.],
  [SET_WIFI], [`st_wifi.c`], [SCAN_NETWORKS, then one GET_SCAN_RESULT per row; pick one, type its password.],
  [HOSTS], [`st_hosts.c`], [The eight host slots, drawn straight from the reply window.],
  [FILES], [`st_files.c`], [Sixteen entries a page; open a directory, or boot a file.],
  [INFO], [`st_info.c`], [GET_ADAPTERCONFIG_EXTENDED.],
)

#shots("cfg-wifi", "cfg-info", w: 2.3in, caption: [Choosing a network, and
the adapter. fujinet-pc pretends to see fifteen networks, all called "Dummy
Cafe".])

#tbl((auto, auto, auto, auto, auto, auto),
  th[Screen], th[Pad], th[A], th[B], th[SELECT], th[START],
  [HOSTS], [move], [open host], [WiFi], [rename], [info],
  [FILES], [move; left/right page], [open / boot], [up a level], [filter], [hosts],
  [WIFI], [move], [pick], [hosts], [], [rescan],
  [keyboard], [grid], [pick], [delete], [case], [OK],
)

== Paging a directory

A page is one SET_DIRECTORY_POSITION -- to the page's first entry -- and then
up to sixteen READ_DIR_ENTRY calls of 27 bytes, each drawn from the reply
window. When you choose a file, CONFIG seeks back to it and reads it again
at 120 bytes, to have the whole name. Then it builds SET_DEVICE_FULLPATH from
the directory's path in RAM and the file's name *out of the reply window*,
without copying it (Chapter 10).

#note[CONFIG treats `..` and `.` as the end of a directory, as well as
`$7F`. An SD card's root on fujinet-pc answers `..` for ever, and an entry
that was not there spoils the next seek.]

== Booting, with a bar

#excerpt-at("CONFIG st_boot.c: boot_mount_swap", "listings/config/st_boot.c",
  "    status_line(\"LOADING...\");", to: "    boot_pct(100);", size: 6.4pt)

It starts the mount without waiting (`fnraw_mount_start()` returns the
sequence number it sent), then once a frame looks at three things: whether
the boot has FAILED, whether the reply has come and was an ACK, and whether
the image is READY. It needs both of the last two. It gives up after 3900
frames -- 65 seconds -- so that the cartridge's own 60-second timeout is the
one you see. Errors appear the way Family BASIC prints them: `?MOUNT ERROR
02`, `?LOAD ERROR 03`.

== Typing

CONFIG's text editor takes characters from its on-screen keyboard and, if
`fuji_nes_kbd_detect()` found one, from a Family BASIC or Subor keyboard at
the same time. On the keyboard the arrows move, Return is A, Escape and
Backspace are B, and in a text field every printable key types.

== The Lobby

On other FujiNet computers there is one more program, the *Lobby*, which
lists the game servers that are running and who is playing, and boots the
right client for the game you pick. The NES clients are ready for it: each
one's `quit()` mounts `nes/lobby.nes` from `ec.tnfs.io` and boots it, and
each one keeps the player's name and the server it was sent to in the Lobby's
app keys -- creator 1, app 1, key 0 for the name, and one key per game for the
server.

#tbl((auto, auto, 1fr),
  th[Key], th[Game], th[Holds],
  [0], [all], [the player's name],
  [1], [5 Card Stud], [server address and query],
  [3], [Fujitzee], [server address and query],
  [5], [Battleship], [server address and query],
  [8], [Texas Hold'em], [server address and query],
)

What is missing, at the time of writing, is the other end: there is no NES
Lobby yet, `ec.tnfs.io` has no `nes/` directory, and the game servers do not
yet list an NES client to the Lobby. CONFIG does not offer the Lobby either.
When they arrive, the clients will need no change.
