#import "../lib.typ": *
= CONFIG <ch-config>

CONFIG is the program the cartridge serves at power-on: the FujiNet’s own menu, where you join a WiFi network, pick a host, browse it, and boot what you find. It is a 32K FujiNet APP in C, like this handbook’s programs, baked into the cartridge’s flash. Its source is `atari5200/` in the fujinet-config repository.

#shots("config-hosts", "config-files", caption: [The host slots, and the files on host 1, the SD card, with `battleship.a52` picked.])
#shots("config-info", "config-boot", caption: [The adapter’s information (#key("START") on the host slots), and a game being pushed and booted.])

#sect[The controls]

#tbl((auto, 1fr),
  th[Control], th[Does],
  [The stick], [Moves the bar up and down a list; left and right page through a long directory.],
  [#key("#") or the fire button], [Opens: a host, a directory, a file to boot.],
  [#key("*") or the other button], [Goes back; on the host slots, #key("*") opens the WiFi screen.],
  [#key("PAUSE")], [Renames a host slot; on a directory, sets a filter.],
  [#key("START")], [The adapter’s information; on a file, copies it to another host.],
)

#sect[How it is built]

#tbl((1fr, 1.3fr),
  th[File], th[What it does],
  [`config.c`], [The entry point and the state dispatcher: one state byte, one module per screen.],
  [`st_wifi.c`, `st_hosts.c`, `st_files.c`, `st_copy.c`, `st_info.c`, `st_lobby.c`, `st_boot.c`], [The screens.],
  [`antic.c`, `antic_dl.s`], [The text screen this handbook’s C programs use (@ch-display).],
  [`fujidisp.c`], [Frames, the bar, the progress bar, the cursor, on top of it.],
  [`fujiin.c`], [The stick, the buttons and the keypad, with repeat.],
  [`fujiedit.c`], [The on-screen keyboard for passwords and names.],
  [`fujiraw.c`], [The transactions fujinet-lib’s calls do not fit (below).],
  [`sfx.c`], [POKEY’s beeps.],
)

Lists are drawn straight out of the cartridge’s reply window, never copied: a directory page is one READ_DIR_ENTRY after another, each name drawn the moment it arrives.

#sect[Streaming a payload]

fujinet-lib’s calls take a payload as one buffer. A few of CONFIG’s commands want a payload made of pieces, such as a directory path in RAM followed by a file name that exists only in the reply window. For those, `fujiraw.c` uses the library’s own bus layer and streams the bytes with `fn_tx()`, padding as it goes:

#ex((path: "listings/config/fujiraw.c", from: "static void raw_begin", to: "}"), t-c)

#sect[Booting with a progress bar]

MOUNT_IMAGE is answered only after the whole image has been pushed, on some FujiNets, so a program that waits for the answer shows nothing moving. CONFIG launches the transaction and does not wait: it writes the sequence number, then watches `ACKSEQ` and the boot registers together, drawing the bar from BOOTPCT as it goes.

#ex((path: "listings/config/st_boot.c", from: "    want = fnraw_mount_start(DEVICE_SLOT, MODE_READ);", to: "        now = fuji_a5200_boot_percent();"), t-c)

An answer of yes with nothing arriving means the FujiNet did not take the file for a cartridge image, and CONFIG says so after three seconds.

#sect[Building and baking]

```
cd fujinet-config/atari5200
make FNLIB=<fujinet-lib-experimental> PICO_5200=<fujinet-firmware>/pico/atari-5200
make cart          # copy build/config.bin into the bring-up and build the firmware
```

`make` builds `build/config.bin` and runs both checkers on it. The firmware build turns it into a header, `fujiconfigrom.h`, compiled into the cartridge’s flash; the firmware keeps a copy in `firmware/baked/` for builds that have no fresh one. The CONFIG built from fujinet-config’s `main` for this handbook is byte for byte the one baked into the firmware it describes.

#note[CONFIG builds against fujinet-lib-experimental’s `atari5200` target, which still carries its own start-up code and linker configuration. The calls are the same as the ones this handbook’s programs make through fujinet-lib and MekkoGX.]
