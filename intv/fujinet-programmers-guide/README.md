# FujiNet Programmer's Guide for Intellivision (IntyBASIC)

A programmer's guide + complete command reference for driving FujiNet from
IntyBASIC on the Mattel Intellivision, through the FujiNet cartridge's
$9C00-$9F3F shared-memory mailbox. Covers the mailbox protocol, the Network
(N:) and Fuji device command sets, AppKeys, and three complete networked
games (5 Card Stud, Battleship, Fujitzee) together with their Go servers.

Styled after the 1983 Mattel *Intellivision Computer Module Owner's Guide*
(scan in `learn/`): landscape spiral-booklet layout, ITC Benguiat Gothic,
magenta page frames, GROM-font TV screens.

## Building

Requires [Typst](https://typst.app) 0.13+ and the vendored fonts in `fonts/`:

```sh
make            # -> fujinet-programmers-guide-intv.pdf
make watch      # live rebuild
make preview    # render page PNGs into preview/
```

`fonts/IntellivisionGROM.ttf` is generated from jzIntv's `rom/grom.bin` by
`tools/make_grom_font.py` (needs fontforge):

```sh
fontforge -script tools/make_grom_font.py path/to/grom.bin fonts/IntellivisionGROM.ttf
```

## Sources of truth

Everything technical is source-verified against:

- `fujinet-firmware/pico/intellivision/` — the RP2040/RP2350 cartridge
  firmware (`fuji_mailbox.h`, `fujinet.c`, `fujibus.h`)
- `fujinet-firmware/lib/device/rs232/` + `lib/bus/rs232/` — the ESP32-S3
  `fujiversal-rs232` command handlers the mailbox forwards to
- `fujinet-config/intv/` — CONFIG's own IntyBASIC mailbox client
- `fujinet-5cardstud/intv`, `fujinet-battleship/intv`,
  `fujinet-fujitzee/intv` — the three game clients (listings in back)
- `servers/fujinet-game-system/` — the Go game servers

## Wiki

`wiki/` holds the GitHub-wiki markdown edition for the fujinet-firmware wiki.
