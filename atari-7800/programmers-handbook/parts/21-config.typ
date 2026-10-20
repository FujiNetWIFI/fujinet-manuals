#import "../lib.typ": *
= CONFIG

#ini[C]ONFIG is the program every FujiNet cartridge runs at power-on: the host list, the file browser, WiFi setup, and the boot. The 7800’s is in fujinet-config’s `atari7800/` directory, a 32K C program built exactly as Section 8 describes, and baked into the cartridge’s firmware so it is there before any network is. It is the largest FujiNet program on the 7800, and every technique in this handbook is in it.

#fig(grid(columns: 3, column-gutter: 6pt,
  tvframe("images/screens/config-hosts.png", 1.2in),
  tvframe("images/screens/config-files.png", 1.2in),
  tvframe("images/screens/config-info.png", 1.2in)),
  caption: [CONFIG: the host slots, the SD card’s root, and the adapter information with the TV standard, INPTCTRL and the High Score Cart.])

#sect[The screens]

#tbl((auto, auto, 1fr),
  th[File], th[Lines], th[Screen],
  [`st_hosts.c`], [158], [The eight host slots, renaming one, PLAY GAME LOBBY; also where a copy’s destination is picked.],
  [`st_files.c`], [304], [The file browser: pages, into and out of directories, the filter.],
  [`st_copy.c`], [124], [Host-to-host copy: mark a file, pick a host and directory, copy.],
  [`st_wifi.c`], [206], [Checking, scanning, choosing a network, a password, a hidden SSID.],
  [`st_info.c`], [106], [The adapter, the TV standard, INPTCTRL’s lock, the High Score Cart switch.],
  [`st_boot.c`], [212], [Mounting into device slot 0, the progress bar, the hand-over; installing an HSC ROM.],
  [`st_lobby.c`], [80], [Finding or adding the Lobby’s host, mounting it, booting it.],
  [`config.c`], [152], [The state machine that moves between them.],
)

The support files are the same pieces this handbook has used: the tile engine (`maria.s`), a layer of frames and bars over it (`fujidisp.c`), the joystick and switches with auto-repeat (`fujiin.c`), an on-screen keyboard (`fujiedit.c`), and POKEY sounds (`sfx.c`).

#tbl((auto, 1fr, 1fr, 1fr),
  th[Screen], th[Button 1], th[Button 2 / RESET], th[SELECT / PAUSE],
  [Hosts], [open the host, or boot the Lobby], [WiFi setup], [rename / information],
  [Files], [open the directory, or boot the file], [up a directory], [filter / copy this file],
  [WiFi], [choose the network], [back], [— / scan again],
  [Information], [back], [back], [High Score Cart on or off],
)

#sect[Drawn straight out of the reply]

CONFIG keeps no copy of a host list or a directory page. It asks, and draws what comes back straight from the reply window into the tile map, `mt_text` taking each name from `$0800`. A screen of 20 names is 20 READ_DIR_ENTRY transactions; on the cartridge that is a fraction of a second. The habit comes from the CONFIGs for consoles with no RAM to spare, and it is why CONFIG fits.

#sect[fujiraw: when the library will not do]

`fuji_bus_call()` takes its payload as one buffer. A few of CONFIG’s commands want one assembled from pieces, and `fujiraw.c` sends those with the bus layer — `fn_regwr`, `fn_tx`, `fn_commit` — streaming each piece into the TX page and padding as it goes, so nothing is assembled in RAM first:

- OPEN_DIRECTORY with a filter: the path, a NUL, the pattern, padded to 256;
- WRITE_HOST_SLOTS: all eight slots, streamed back out of the reply window of a READ_HOST_SLOTS with the renamed one replaced;
- SET_DEVICE_FULLPATH: the directory from RAM, then the file name straight out of the reply window;
- SET_SSID’s 33 and 64 bytes, and COPY_FILE’s `source|destination`;
- MOUNT_IMAGE without waiting for its answer, so the progress bar can be drawn while the push arrives and the answer is checked when `ACKSEQ` comes round.

Everything else goes through fujinet-lib.

#sect[Building it into the cartridge]

```
cd fujinet-config/atari7800
make FNLIB=~/fujinet-lib-experimental     # build/config.bin, build/config.a78
make install PICO_7800=~/fujinet-firmware/pico/atari-7800
cd ~/fujinet-firmware/pico/atari-7800
./build-cart.sh --bake                    # into the firmware, and into firmware/baked/
```

`build-cart.sh` turns `config.bin`, the loader and the signed boot block into headers the firmware compiles in, and builds the RP2354B firmware. `firmware/baked/` keeps the last baked copies, so a build with no cc65 at hand (the ESP32’s, or CI’s) still has a CONFIG.

The cartridge’s own `emu/cfgtest.lua` drives this CONFIG in MAME through the hosts, a directory and a boot, and checks each screen. The screens above came from the same build, driven by the handbook’s copy of Battleship’s smoke script with an ASCII tile map.
