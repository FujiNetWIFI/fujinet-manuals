#import "../lib.typ": *
= Keys, Clock and Utilities

#ini[A] FujiNet can remember things for a program, tell it the time, and do the arithmetic a 6502 should not have to. This section covers the three a program reaches for first — appkeys, the clock, and the utilities — and the one the 7800 cartridge adds: a High Score Cart whose scores live on the FujiNet.

#sect[Appkeys]

An *appkey* is a small file on the FujiNet’s SD card, named by three numbers: a *creator* (two bytes), an *application* and a *key* (one byte each). A program reads and writes its own keys to remember settings, names and scores between sessions; every FujiNet game reads the same key, creator 1, app 1, key 0, for the player’s name.

#tbl((auto, auto, 1fr),
  th[Command], th[Code], th[Parameters, payload, reply],
  [OPEN_APPKEY], [`$DC`], [No parameters. Payload: six bytes — creator (low, high), app, key, mode (0 read, 1 write), and a reserved 0 that must be sent.],
  [READ_APPKEY], [`$DD`], [None. Reply: the length (two bytes, low first), then the value.],
  [WRITE_APPKEY], [`$DE`], [The length (one byte); then the value as the payload.],
  [CLOSE_APPKEY], [`$DB`], [None.],
)

A key holds up to 64 bytes. Register a creator id of your own on the FujiNet wiki’s AppKey Registry before you ship a program that writes keys. The 7800 cartridge’s own creator is `$7800`; its app 1 is the High Score Cart (below). This handbook’s programs use app `$FF` of the same creator as scratch.

#fig(grid(columns: 3, column-gutter: 6pt,
  tvframe("images/screens/asm-appkey.png", 1.2in),
  tvframe("images/screens/c-appkey.png", 1.2in),
  tvframe("images/screens/bas-appkey.png", 1.2in)),
  caption: [The shared player name, then a key of our own written and read back.])

#sect[In assembly]

#ex((path: "listings/asm/appkey.s", from: "; akopen --", to: "; akshow --"), t-asm)

#sect[In C]

fujinet-lib keeps the creator and app in `fuji_set_appkey_details()`, and its read and write each do the OPEN themselves:

#ex((path: "listings/c/appkey.c", from: "static void show", to: "void main"), t-c)
#ex((path: "listings/c/appkey.c", from: "    fuji_set_appkey_details(0x7800", to: "    for (;;)"), t-c)

The read’s buffer must be two bytes bigger than the key: the library reads the length into it too.

#sect[In 7800basic]

#ex((path: "listings/bas/appkey.bas", from: " rem akopen --", to: " alphadata value"), t-bas)
#ex((path: "listings/bas/appkey.bas", from: "ours", to: "failed"), t-bas)

`last = value_length - 1` before the loop is Section 9’s rule about `for` bounds; without it, the key gains a stray byte.

#sect[The clock]

The clock is a device of its own, `$45`. Its commands take no parameters and answer with the time in one of several forms:

#tbl((auto, auto, 1fr),
  th[Command], th[Code], th[Reply],
  [GET_ISO_LOCAL], [`$49` `'I'`], [`2026-10-20T15:46:08+0000` and a NUL, in the adapter’s time zone.],
  [GET_ISO_UTC], [`$5A` `'Z'`], [The same in UTC.],
  [GETTIME], [`$93`], [Six bytes: day, month, year (two digits), hour, minute, second.],
  [(simple time)], [`$54` `'T'`], [Seven bytes: century, year, month, day, hour, minute, second.],
  [SETTZ_ALT], [`$74` `'t'`], [Payload: a POSIX time-zone string, such as `EST5EDT`: the zone the local reads use.],
)

#fig(grid(columns: 3, column-gutter: 6pt,
  tvframe("images/screens/asm-clock.png", 1.2in),
  tvframe("images/screens/c-clock.png", 1.2in),
  tvframe("images/screens/bas-clock.png", 1.2in)),
  caption: [The clock. fujinet-pc on the bench runs in UTC, so both lines agree.])

#ex((path: "listings/asm/clock.s", from: ".proc main", to: ".endproc"), t-asm)
#ex((path: "listings/c/clock.c", from: "static void line", to: "void main"), t-c)
#ex((path: "listings/bas/clock.bas", from: " fn_dev = FN_CLOCK : fn_cmd = $49", to: " goto main"), t-bas)

#sect[Entropy, hashing, encoding]

The FujiNet does the work a 6502 would take seconds over:

- *GENERATE_GUID* (`$BB`) answers with a fresh 36-character GUID.
- *HASH_INPUT* (`$C8`), *HASH_COMPUTE* (`$C7`), *HASH_LENGTH* (`$C6`) and *HASH_OUTPUT* (`$C5`) hash data: feed it in pieces, compute with an algorithm (0 MD5, 1 SHA-1, 3 SHA-256, 4 SHA-512), ask the length, read the result. In C, `fuji_hash_data()` does all four.
- The *Base64* commands (`$D0`–`$C9`, encode and decode) work the same way.
- The *QR code* commands (`$BC`–`$BF`) turn text into a QR code’s modules.

The cards in Section 16 show each one in all three languages.

#sect[The High Score Cart]

Atari’s High Score Cart sat between the console and a game and kept the scores of every game that knew about it, in 2K of battery-backed RAM at `$1000`–`$17FF`, with its own ROM at `$3000`–`$3FFF`. The FujiNet cartridge can be one. It serves the HSC ROM — your own copy, installed once from CONFIG and kept in the cartridge’s flash; none is supplied — and keeps the 2K of RAM as 32 appkeys of 64 bytes, creator `$7800`, app 1, keys 0–31, on the FujiNet’s SD card. While a game runs, the cartridge saves each 64-byte chunk the game changed, two seconds after the last change. The scores follow the SD card, not the cartridge.

A program sees and controls it through the status page and one register:

#tbl((auto, 1fr),
  th[Where], th[What],
  [`$0C26` HSC], [Bit 0 a ROM is installed; bit 1 games get the HSC; bit 2 the last save reached the SD card; bit 3 scores are waiting to be saved.],
  [`$0D16` HSC], [0 turn it off, 1 on, 2 forget the installed ROM, 3 install the pushed image (STAGED bit 3) as the HSC ROM.],
)

In C, `fuji_a7800_hsc()` reads the bits and `fuji_a7800_hsc_op()` writes the register. CONFIG’s information screen has the switch.

#note[The HSC is for games: the cartridge saves its RAM only while a game (GAME mode) runs. A FujiNet program keeps its own data in its own appkeys, as above.]
