#import "../lib.typ": *

#opener-art.update((sub: [up to 8 players · either keypad],
  art: tvrow("5card-lobby", "5card-hand1", "5card-turn", w: 1.15in)))
= 5 Card Stud <fcs>

5 Card Stud is the FujiNet’s poker table: one card down, four up, a round of betting after each, against people on other computers or the server’s bots. It was the first game on the Studio II port, and Battleship took its network, name and lobby code. It is in `fujinet-5cardstud/studio2/`; the handbook carries it unchanged in `listings/5cardstud/`.

== Playing it

#tbl((0.95in, 1fr),
  [*Screen*], [*Keys*],
  [Name], [2 4 6 8 move on the grid, 5 types, 1 deletes, 3 done, 0 keeps the old name],
  [Lobby], [1–8 joins that table, 0 the menu],
  [Table], [1–5 sends that move, 9 shows cards or chips, 0 the menu],
  [Menu], [1 or 0 back, 2 leaves the table, 3 changes the name, 4 quits to CONFIG],
)

On your turn the bottom two rows become the moves, two to a row: an inverse key, then the move, `1FOLD  2CALL` and `3RAISE5`. A beep says it is your turn.

== The screen

#crt2("5card-showdown", "5card-chips", caption: [The showdown, and the same table with 9 pressed: each seat’s chips and last move.])

Each seat has a row: its name to the first space, then its five cards, or `FOLDED`, `LEFT` or `WAITING`. Row 8 is the pot, the street and the clock, and row 9 the result while it is news, scrolling under a marquee.

A card is two cells, its rank and its suit from the cartridge’s font, #s2ch(1) #s2ch(2) #s2ch(3) #s2ch(4), white on black. The ten is the font’s own `10` in one cell, #s2ch(10). A face-down card is a pair of glyphs the program defines, a hatched back:

#wex("listings/5cardstud/src/cards.inc", "; glyphs --", to: "; dhand --", at: bottom)

Inverse video would be the obvious card face, and it is wrong: on a 3 × 5 letter the outer strokes merge into the gap beside them, and a K loses its stem.

== The name

Every FujiNet game reads the player’s name from the shared app key, creator 1, app 1, key 0. The editor comes up only when the key is empty or cannot be read, and writes the name back when it is done; a name typed in 5 Card Stud is the name in Battleship. The name and the table go into the URL percent-encoded.

== The transport

`net.inc` is the family’s, described in Battleship. 5 Card Stud’s own numbers: STATUS settles on 154 bytes at least for `/state` and 1 for `/tables`, and the reply must be `154 + 33 × players` or `1 + 36 × tables` long. It waits 100 seconds on a network transaction, past the cartridge’s 90. The keypads are read while a transaction runs, so a press during a poll is kept. Leaving a table is `/leave?bin=1`, which has no body: an OPEN and one STATUS.

== Size

5,188 bytes on 25 pages: the runtime, then blocks at `$0C00`, `$1400`, `$2400` and `$3400`. The client’s variables are all on page `$08`, so RA.1 stays fixed for the whole run, and the stack uses under 40 bytes.

== Played through, in MAME

The firmware’s `emu/5carddrive.lua` plays it against the bench’s server: it types a name when the app key is empty, joins `AI ROOM - 2`, plays legal moves through two hands, then 0 and 4 back to CONFIG, and waits for the cartridge’s hand-over. `emu/games.sh 5card` runs it. The server is `fujinet-game-system/5cardstud/server`; `PORT=8772 go run .` starts it.
