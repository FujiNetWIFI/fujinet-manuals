#import "../lib.typ": *

= Parts List

The FujiNet cartridge is open hardware: the board and every program in it may
be built, changed and shared. Its design files are in *fujinet-hardware* on
GitHub, under *ATARI-5200 / FujiNet-5200-Rev0*. When asking about parts, give
the board’s name and revision, printed on the board.

#dotdef(
  [Board], [FujiNet-5200 Rev0],
  [Game chip], [RP2354B (RP2350 with 2 MB flash)],
  [Network chip], [ESP32-S3-WROOM-1, 16 MB flash, 8 MB PSRAM],
  [Bus buffer], [74HCT541],
  [WiFi], [802.11 b/g/n, 2.4 GHz],
  [Memory card], [microSD, push-push, FAT32],
  [USB], [USB-C: power, and firmware loading],
  [Lights], [status (white / orange); game (red)],
  [Buttons], [RESET; three service buttons (BOOTSEL, S3 EN, S3 BOOT)],
  [Power], [from the cartridge slot, or USB-C],
  [Consoles], [CX5200, four-port and two-port; NTSC],
  [Games], [up to 128K; .A52, .BIN or .ROM],
  [Cartridge shell], [to come; the drawings in this manual are its own],
)

== Related Publications

- _FujiNet 5200 Programmer’s Handbook_ -- writing programs for the
  cartridge.
- _M.U.L.E. Player’s Guide_ -- the whole of M.U.L.E.
- _The FujiNet Network Protocol Handbook_ -- everything FujiNet can talk to.

#pagebreak(weak: true)
== A Few Words

#tbl((0.95in, 1fr),
  th[Word], th[Meaning],
  [*AI Room*], [A game table where robot players fill the empty seats.],
  [*Firmware*], [The programs built into the cartridge itself.],
  [*FAT32*], [The way most memory cards are formatted; the one FujiNet
    reads.],
  [*Host*], [A place games are kept: the memory card, or a server on the
    Internet or in your home.],
  [*Lobby*], [FujiNet’s list of open game tables, on every kind of machine.],
  [*NTSC*, *PAL*], [The North American and the European ways of making a TV
    picture. FujiNet and its games are NTSC.],
  [*SSID*], [Your WiFi network’s name.],
  [*Super Cart*], [A cartridge bigger than the console’s 32K window, showing
    it one part at a time. FujiNet plays the part for the games it loads.],
  [*TNFS*], [The simple file-sharing language FujiNet servers speak.],
  [*Two-chip*], [A 16K cartridge built from two 8K chips. FujiNet knows which
    games were made this way.],
  [*USB-C*], [The small, either-way-up plug of modern phone chargers.],
)
