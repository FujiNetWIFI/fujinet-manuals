#import "../lib.typ": *
= Keys, Clock and Utilities

Three more things the adapter does that a game wants, each a transaction or two.

#sect[Appkeys]

An appkey is a small file on the adapter's SD card --- `/FujiNet/CCCCAAKK.key`, named by a 16-bit creator id, an app id and a key number --- and it is how a FujiNet program remembers something between sessions. Creator 1, app 1, key 0 is the slot every game in the family reads the player's name from.

`OPEN_APPKEY` selects the key and the direction, and its payload is one six-byte struct, not four parameters: the creator as two bytes low first, the app, the key, the mode (0 read, 1 write), and a reserved byte that is not optional --- leave it off and the adapter waits for a byte that never comes, which reads back as a timeout. `READ_APPKEY` answers a two-byte length and then the value; `WRITE_APPKEY` takes one parameter, the length, and the value as its payload. A write resets the selection, so each write needs a fresh open.

#excerpt-at("appkey.asm: OPEN, READ, WRITE", "listings/asm/appkey.asm", "; AKOPEN -- OPEN_APPKEY", to: "; AKSHOW")

#excerpt-at("appkey.bas: the same", "listings/bas/appkey.bas", " rem akopen:", to: " rem akshow")

Both programs show the shared username, then write `HELLO 2600` into creator `$2600`, app 1, key 0 and read it back.

#shot("bas-appkey", w: 1.6in, caption: [`appkey.bas`. The name is whatever the last FujiNet game stored.])

#note[The open fails outright when no SD card is mounted on the adapter. That is not a client bug: Battleship treats it as "no name yet" and puts up its keyboard.]

#sect[The clock]

The clock is device `$45`, and `GET_ISO_LOCAL` (`$49`, `I`) answers the local time as text in the adapter's configured zone: `2026-09-15T20:45:31` followed by the offset and a NUL. `GET_ISO_UTC` (`$5A`, `Z`) is the same in UTC. Twelve columns is not nineteen, so the date goes on one row and the time on the next, straight out of the reply window.

#excerpt-at("clock.asm: GET_ISO_LOCAL", "listings/asm/clock.asm", "GOTCART:", to: "; ---------------- GET_ISO_UTC")

#excerpt-at("clock.bas: the same", "listings/bas/clock.bas", " rem showtime:", to: "fnbeg")

#shot("asm-clock", w: 1.6in, caption: [`clock.asm`. Local and UTC agree on this adapter because no zone is set.])

The other formats answer too: `GETTIME` (`$93`) is seven binary bytes, `GET_PRODOS` (`$50`) four, `GET_SIMPLE_HUNDREDTHS` (`$4D`) adds hundredths, `GET_GENERAL` (`$47`) is the zone string and `GETTZ_LEN` (`$4C`) its length. `SETTZ` (`$99`) takes a POSIX zone string as its payload and sets the zone for the session. Section 17 has the cards.

#sect[Entropy, hashing, encoding, QR codes]

`GENERATE_GUID` (`$BB`) answers a fresh 36-character UUID and a NUL. The hash and base64 pipelines take four transactions each: `INPUT` with a two-byte count and the bytes as payload (repeatable, for long data), `COMPUTE` --- for a hash, with the algorithm as a parameter: 0 MD5, 1 SHA-1, 3 SHA-256, 4 SHA-512 --- then `LENGTH` and `OUTPUT`, each with a byte parameter that is 1 for hex text. A QR code is the same shape: `INPUT`, `ENCODE` with version, error-correction level and a shorten flag, `LENGTH` in the mode you want, `OUTPUT`. The adapter returns the module data ready to blit; a version-1 code is 21 by 21 modules, which the playfield can show.

#pair("; SHA-256 of a string, as hex text
        lda     #FNDEVF
        sta     FNDEV
        lda     #FNCHSHI        ; HASH_INPUT
        sta     FNCMD
        lda     #1
        sta     FNNPR
        jsr     FNBEG
        lda     #TXTE-TXT       ; the count, two bytes
        ldx     #0
        jsr     FNPW
        ldy     #0
HI1:    lda     TXT,y           ; the bytes
        sta     FNTX
        iny
        cpy     #TXTE-TXT
        bne     HI1
        jsr     FNGO
        lda     #FNCHSHC        ; HASH_COMPUTE, algorithm 3
        sta     FNCMD
        lda     #1
        sta     FNNPR
        jsr     FNBEG
        lda     #HASHA256
        jsr     FNPB
        jsr     FNGO
        lda     #FNCHSHO        ; HASH_OUTPUT, 1 = hex text
        sta     FNCMD
        jsr     FNBEG
        lda     #1
        jsr     FNPB
        jsr     FNGO            ; 64 hex digits in the reply window",
" dev = FNDEVF
 cmd = FNCHSHI
 npar = 1
 gosub fnbeg
 FNTX = 2
 FNTX = txt_length
 FNTX = 0
 for l = 0 to txt_length - 1
 FNTX = txt[l]
 next
 gosub fngo
 cmd = FNCHSHC
 gosub fnbeg
 FNTX = 1
 FNTX = HASHA256
 gosub fngo
 cmd = FNCHSHO
 gosub fnbeg
 FNTX = 1
 FNTX = 1
 gosub fngo
 rem 64 hex digits in the reply window")
