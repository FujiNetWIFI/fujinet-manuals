#import "../lib.typ": *

#opener-art.update((sub: [app keys · the clock · hashes and ids],
  art: tvrow("appkey", "clock", w: 1.3in)))
= App Keys, Clock and Utilities <keys>

A Studio II forgets everything when it is turned off. The FujiNet does not: it keeps small _app keys_ on its SD card for any program that asks, and it knows the time.

== App keys

An app key is up to 64 bytes, named by three numbers: a _creator_, two bytes, an _app_ and a _key_ number. On the SD card it is the file `/FujiNet/CCCCAAKK.key`. Creator 1, app 1, key 0 is special: every FujiNet game reads the player’s name from it, so a name typed once is known everywhere.

`appkey.asm` reads the player’s name, then writes a key of the handbook’s own, creator `$1802`, app `$FF`, key 0, and reads it back.

#excerpt-at(auto, "listings/asm/appkey.asm", "go:     PUTS    20H, t_name", to: "; akopen --")

== Opening a key

OPEN_APPKEY chooses the key the next read or write uses. It has no parameters: the key goes as a six-byte payload, the creator low byte first, then the app, the key, the mode (0 read, 1 write) and a reserved 0.

#excerpt-at(auto, "listings/asm/appkey.asm", "akopen: FNBEGIN FNDEVF, FNCAKOP, 0", to: "; akread --")

#important[Send the reserved byte. Without it the adapter waits for the sixth byte until the transaction times out.]

== Reading and writing

READ_APPKEY answers with a two-byte length and then the value; the program prints the value from offset 2 of the reply window. WRITE_APPKEY takes the length as one parameter and the bytes as the payload. A write ends the selection: open the key again before the next read.

#excerpt-at(auto, "listings/asm/appkey.asm", "akwrite:", to: "; akshow --")

== The clock

The FujiNet’s clock is a device of its own, `$45`. GET_ISO_LOCAL (`$49`, an `I`) answers with the local time as text, `2026-10-20T09:57:25` and the zone’s offset; GET_ISO_UTC (`$5A`, a `Z`) the same in UTC. `clock.asm` prints the date and the time on two rows, straight out of the reply window:

#excerpt-at(auto, "listings/asm/clock.asm", "ASK     MACRO   cmd, rc", to: "        FIT     187")

A `fujinet-pc` knows no zone of its own until it is given one, and its local time is UTC. So `clock.asm` first sets one, with command `$74` (a `t`) and a POSIX zone as the payload:

#excerpt-at(auto, "listings/asm/clock.asm", "go:     FNBEGIN CLKDEV, CKSETZA, 0", n: 4)

#note[`$99`, which `fujiCommandID.h` calls SETTZ, sets the _alternate_ zone: the one a clock read uses when it is given a parameter of 1. `$74` sets the adapter’s own, and the adapter saves it.]

GETTIME (`$93`) answers in binary instead: six bytes, day, month, year (two digits), hour, minute, second.

== Utilities

The FUJI device has a few services no Studio II could afford to do itself:

#tbl((1.25in, 1fr),
  [*Command*], [*Gives*],
  [GENERATE_GUID `$BB`], [a fresh unique id, 36 characters],
  [HASH `$C8`--`$C5`], [MD5, SHA-1, SHA-256 or SHA-512 of the bytes you feed it],
  [BASE64 `$D0`--`$C9`], [base64, either way],
)

A hash is four transactions: feed the bytes with HASH_INPUT, as often as needed, choose the algorithm with HASH_COMPUTE, and read the result with HASH_OUTPUT, as text or binary.

#asmp("        FNBEGIN FNDEVF, FNCHSHI, 1  ; feed it
        LDR     R8, 5
        FCALL   fn_pw
        LDR     R8, data        ; \"HELLO\"
        FCALL   fn_str
        GOACK
        FNBEGIN FNDEVF, FNCHSHC, 1  ; SHA-256
        LDI     HASHA256
        FCALL   fn_pb
        GOACK
        FNBEGIN FNDEVF, FNCHSHO, 1  ; as hex text
        LDI     1
        FCALL   fn_pb
        GOACK                       ; 64 characters")

The Command Reference has all of them (The Fuji Device, page #pg(<ref-fuji>)).
