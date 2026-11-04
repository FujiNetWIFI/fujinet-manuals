#import "../lib.typ": *

= App Keys, the Clock and Utilities <keys>

An ARCADIA-2001 forgets everything when it is switched off. The FujiNet does
not: it keeps small _app keys_ on its memory card for any program that asks,
and it knows the time.

#shots(("appkey", [appkey]), ("clock", [clock]),
  caption: [The player’s name, a key of our own, and the time twice over])

== App keys

An app key is up to 64 bytes, named by three numbers: a _creator_, two
bytes, an _app_ and a _key_ number. On the memory card it is the file
`/FujiNet/CCCCAAKK.key`. Creator 1, app 1, key 0 is special: it holds the
player’s name, which the FujiNet games on most machines read, so a name typed
once is known everywhere. (The Arcadia’s Battleship and 5 Card Stud do not
yet: they ask for a name each time, and offer ARCADIA.) `appkey` reads that
name, then writes a key of the handbook’s own -- creator `$2650`, app `$FF`,
key 0 -- and reads it back:

#excerpt-at(auto, "listings/asm/appkey.asm", "GO:     PUTS    $20, TNAME", to: "; AKOPEN --")

== Opening a key

OPEN_APPKEY chooses the key the next read or write uses. It has no
parameters: the key goes as a six-byte payload, the creator’s low byte
first, then its high byte, the app, the key, the mode (0 read, 1 write) and a
reserved 0. `FNTXN` streams the six bytes as they are, zeros included:

#excerpt-at(auto, "listings/asm/appkey.asm", "AKOPEN: FNBEGIN FNDFUJI, FCAKOP, 0", to: "; AKREAD --")
#excerpt-at(auto, "listings/asm/appkey.asm", "KNAME:  DB", n: 3)

#important[Send the reserved byte. Without it the adapter waits for a
sixth byte that never comes, until the transaction times out.]

== Reading and writing

READ_APPKEY answers with a two-byte length and then the value; `AKSHOW`
prints the value from byte 2 of the reply window. WRITE_APPKEY takes the
length as one parameter and the bytes as the payload. A write ends the
selection: open the key again before the next read.

#excerpt-at(auto, "listings/asm/appkey.asm", "AKWRIT: FNBEGIN FNDFUJI, FCAKWR, 1", to: "; AKSHOW --")

== The clock

The FujiNet’s clock is a device of its own, `$45`. GET_ISO_LOCAL (`$49`, an
`I`) answers with the local time as text, `2026-11-03T10:45:31` and the
zone’s offset; GET_ISO_UTC (`$5A`, a `Z`) the same in UTC. `clock` prints the
date and the time on two rows, straight out of the reply window, with
`DREPLY`:

#excerpt-at(auto, "listings/asm/clock.asm", "ASK:    STRA,R1 BKVAR", to: "TZONE:")

The clock command is in R1 at run time, so `ASK` cannot use the `FNBEGIN`
macro, whose arguments are fixed when the program is assembled; it makes
the four register writes itself. A fujinet-pc knows no zone until it is
given one, and its local time is UTC, so `clock` sets one first, with command
`$74` (a `t`) and a POSIX zone as the payload:

#excerpt-at(auto, "listings/asm/clock.asm", "GO:     FNBEGIN DVCLOCK, CKSETTA, 0", n: 5)

#note[`$99`, which the firmware calls SETTZ, sets the _alternate_ zone: the
one a clock read uses when it is given a parameter of 1. `$74` sets the
adapter’s own, and the adapter saves it.]

GETTIME (`$93`) answers in binary instead: six bytes -- day, month, year (two
digits), hour, minute, second.

== Utilities

The Fuji device has a few services no ARCADIA-2001 could afford to do
itself:

#tbl((1.6in, 1fr),
  [*Command*], [*Gives*],
  [GENERATE_GUID `$BB`], [a fresh unique id, 36 characters],
  [HASH `$C8-$C2`], [MD5, SHA-1, SHA-256 or SHA-512 of the bytes you feed it],
  [BASE64 `$D0-$C9`], [base64, either way],
)

RANDOM_NUMBER (`$D3`) is in the firmware’s list but not answered on this
build; a program’s randomness comes from a GUID or a hash. A hash is three
transactions: feed the bytes with HASH_INPUT, as often as
needed; choose the algorithm with HASH_COMPUTE; read the result with
HASH_OUTPUT, as text or in binary.

#asmp("        FNBEGIN FNDFUJI, FCHSHI, 1 ; HASH_INPUT: feed it
        LODI,R2 5
        LODI,R3 0
        BSTA,UN FNPARW          ; five bytes
        SETFSTR HDATA           ; \"HELLO\"
        BSTA,UN FNTXSTR
        BSTA,UN FNGO
        BCFA,EQ FAIL
        FNBEGIN FNDFUJI, FCHSHC, 1 ; HASH_COMPUTE: SHA-256
        LODI,R2 HASH256
        BSTA,UN FNPARB
        BSTA,UN FNGO
        BCFA,EQ FAIL
        FNBEGIN FNDFUJI, FCHSHO, 1 ; HASH_OUTPUT: as hex text
        LODI,R2 1
        BSTA,UN FNPARB
        BSTA,UN FNGO            ; 64 characters at $2B00
        BCFA,EQ FAIL")

Section 17 has all of them.
