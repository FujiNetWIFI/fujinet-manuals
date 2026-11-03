#import "../lib.typ": *

= Parts List

The FujiNet cartridge is open hardware: the board and every program in it may
be built, changed and shared. Its design files are in *fujinet-hardware* on
GitHub, under *Emerson-Arcadia / FujiNet-Arcadia-Rev0*. When asking about
parts, give the board’s name and revision, printed on the board.

#dotdef(
  [Board], [FujiNet-Arcadia Rev0],
  [Game chip], [RP2354A (RP2350 with 2 MB flash)],
  [Network chip], [ESP32-S3-WROOM-1, 16 MB flash, 8 MB PSRAM],
  [WiFi], [802.11 b/g/n, 2.4 GHz],
  [Memory card], [microSD, push-push, FAT32],
  [USB], [USB-C: power, and firmware loading],
  [Lights], [status (white / orange); game chip (red)],
  [Buttons], [RESET; three service buttons (BOOTSEL, S3 RST, S3 BOOT)],
  [Power], [from the cartridge slot, or USB-C (USB-C first)],
  [Console], [EMERSON ARCADIA-2001 (ADV-1), NTSC],
  [Contacts], [2 × 15, 2.54 mm],
  [Games], [up to 8,192 bytes; FujiNet programs up to 71,680; .BIN or .ROM],
  [Cartridge shell], [to come; the drawings in this manual are its own],
)

== Related Publications

- _ARCADIA-2001 Owner’s Manual_ (Emerson, 1982) -- the console itself.
- _M.U.L.E. Player’s Guide_ -- the whole of M.U.L.E.
- _The FujiNet Network Protocol Handbook_ -- everything FujiNet can talk to.

== A Few Words

#tbl((1.35in, 1fr),
  th[Word], th[Meaning],
  [*AI Room*], [A game table where robot players fill the empty seats.],
  [*CONFIG*], [The FujiNet program built into the cartridge: the hosts, the
    browser, WiFi and INFO.],
  [*Firmware*], [The programs built into the cartridge itself.],
  [*FAT32*], [The way most memory cards are formatted; the one FujiNet
    reads.],
  [*Host*], [A place games are kept: the memory card, or a server on the
    Internet or in your home.],
  [*Lobby*], [FujiNet’s list of open game tables, on every kind of machine.],
  [*NTSC*, *PAL*], [The North American and the European ways of making a TV
    picture. The ARCADIA-2001 and FujiNet are NTSC.],
  [*Page*], [A 2K part of a large FujiNet program, shown to the console one
    at a time.],
  [*SSID*], [Your WiFi network’s name.],
  [*TNFS*], [The simple file-sharing language FujiNet servers speak.],
  [*USB-C*], [The small, either-way-up plug of modern phone chargers.],
)
