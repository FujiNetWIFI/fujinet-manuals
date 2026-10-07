#import "../lib.typ": *

= Parts List

The FujiNet cartridge is open hardware: the board, the shell and every
program in it may be built, changed and shared. Its design files are kept in
the *fujinet-hardware* collection on GitHub, under
*ATARI-2600 / Fujiversal-Atari2600-Rev1*. When asking about parts, always
give the board's name and revision, which are printed on the board.

#dotdef(
  [Board], [Fujiversal-Atari2600 Rev1],
  [Game chip], [RP2354A (RP2350 with 2 MB flash)],
  [Network chip], [ESP32-S3-WROOM-1, 16 MB flash, 8 MB PSRAM],
  [WiFi], [802.11 b/g/n, 2.4 GHz],
  [Memory card], [microSD, push-push, FAT32],
  [USB], [USB-C: power, and firmware loading],
  [Lights], [status (white / orange); power (red)],
  [Buttons], [RESET; three service buttons (BOOTSEL, S3 EN, S3 BOOT)],
  [Power], [from the console's cartridge port, or USB-C],
  [Games], [up to 32K; .BIN or .ROM; NTSC],
  [Cartridge shell], [3D-printed, after norm8332's "Easy Print" shell],
  [Shell screws], [4 × countersunk wood screw, \#4 × 1/2"],
)

== Related Publications

- _FujiNet Video Computer System Programmer's Handbook_ -- writing programs
  for the cartridge.
- _FujiNet for the Atari 2600: Theory of Operation_ -- how the cartridge
  works.
- _M.U.L.E. Player's Guide_, Atari 2600 edition -- the whole of M.U.L.E.
- _The FujiNet Network Protocol Handbook_ -- everything FujiNet can talk to.

== A Few Words

#tbl((auto, 1fr), size: 8pt,
  th[WORD], th[MEANING],
  [*Host*], [A place games are kept: the memory card, or a server on the Internet or in your home.],
  [*TNFS*], [The simple file-sharing language FujiNet servers speak.],
  [*Lobby*], [FujiNet's list of open game tables, on every kind of machine.],
  [*Relay*], [A server that passes two players' moves to each other.],
  [*SSID*], [Your WiFi network's name.],
  [*Firmware*], [The programs built into the cartridge itself.],
  [*Page-switching*], [How a game bigger than 4K shows the console one part of itself at a time. FujiNet does it for the games it loads.],
)

#v(1fr)
#align(center, text(font: f-head, size: 7pt, fill: gray, tracking: 1pt)[LITHO IN THE FUJINET PROJECT])
