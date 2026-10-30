#import "../lib.typ": *
= App Keys, Clock and Utilities <ch-keys>

A FujiNet can remember things for a program, tell it the time, and do the arithmetic a 6502 should not have to. This section covers the three a program reaches for first: appkeys, the clock, and the utilities.

#sect[Appkeys]

An *appkey* is a small file on the FujiNet’s SD card, named by three numbers: a *creator* (two bytes), an *application* and a *key* (one byte each). A program reads and writes its own keys to remember settings, names and scores between sessions; every FujiNet game reads the same key, creator 1, app 1, key 0, for the player’s name. On a console whose RAM forgets everything at every hand-over and every power cycle (@ch-ram), appkeys are the only memory a 5200 program has.

#tbl((auto, auto, 1fr),
  th[Command], th[Code], th[Parameters, payload, reply],
  [OPEN_APPKEY], [`$DC`], [No parameters. Payload: six bytes: creator (low, high), app, key, mode (0 read, 1 write), and a reserved 0 that must be sent.],
  [READ_APPKEY], [`$DD`], [None. Reply: the length (two bytes, low first), then the value.],
  [WRITE_APPKEY], [`$DE`], [The length (one byte); then the value as the payload.],
  [CLOSE_APPKEY], [`$DB`], [None.],
)

A key holds up to 64 bytes. Register a creator id of your own on the FujiNet wiki’s AppKey Registry before you ship a program that writes keys. This handbook’s programs use creator `$5200`, app `$FF`, as scratch.

#shots("asm-appkey", "c-appkey", caption: [The shared player name, then a key of our own written and read back.])

#sect[In assembly]

#ex((path: "listings/asm/appkey.s", from: "; akopen --", to: "; akread --"), t-asm)

The write sends its value with `fn_txb`, counted in X:

#ex((path: "listings/asm/appkey.s", from: "; akwrite --", to: "; akshow --"), t-asm)

#sect[In C]

fujinet-lib keeps the creator and app in `fuji_set_appkey_details()`, and its read and write each do the OPEN themselves:

#ex((path: "listings/c/appkey.c", from: "static void show", to: "void main"), t-c)
#ex((path: "listings/c/appkey.c", from: "    fuji_set_appkey_details(0x5200", to: "    for (;;)"), t-c)

The read’s buffer must be two bytes bigger than the key: the library reads the length into it too.

#sect[The clock]

The clock is a device of its own, `$45`. Its commands take no parameters and answer with the time in one of several forms:

#tbl((auto, auto, 1fr),
  th[Command], th[Code], th[Reply],
  [GET_ISO_LOCAL], [`$49` `'I'`], [`2026-10-30T18:42:08-0400` and a NUL, in the adapter’s time zone.],
  [GET_ISO_UTC], [`$5A` `'Z'`], [The same in UTC.],
  [GETTIME], [`$93`], [Six bytes: day, month, year (two digits), hour, minute, second.],
  [(simple time)], [`$54` `'T'`], [Seven bytes: century, year, month, day, hour, minute, second.],
  [SETTZ_ALT], [`$74` `'t'`], [Payload: a POSIX time-zone string, such as `EST5EDT`: the zone the local reads use.],
)

#shots("asm-clock", "c-clock", caption: [The clock, local and UTC. The bench’s fujinet-pc keeps `EST5EDT`.])

#ex((path: "listings/asm/clock.s", from: ".proc main", to: ".endproc"), t-asm)
#ex((path: "listings/c/clock.c", from: "static void line", to: "void main"), t-c)

#sect[Entropy, hashing, encoding]

The FujiNet does the work a 6502 would take seconds over:

- *GENERATE_GUID* (`$BB`) answers with a fresh 36-character GUID.
- *HASH_INPUT* (`$C8`), *HASH_COMPUTE* (`$C7`), *HASH_LENGTH* (`$C6`) and *HASH_OUTPUT* (`$C5`) hash data: feed it in pieces, compute with an algorithm (0 MD5, 1 SHA-1, 3 SHA-256, 4 SHA-512), ask the length, read the result. In C, `fuji_hash_data()` does all four.
- The *Base64* commands (`$D0`–`$C9`, encode and decode) work the same way.
- The *QR code* commands (`$BC`–`$BF`) turn text into a QR code’s modules.

The cards in @ch-ref-fuji show each one in both languages.

#note[The 5200 has no random-number problem to solve: POKEY’s `RANDOM` register at `$E80A` reads a fresh byte from a 17-bit noise generator at any moment.]
