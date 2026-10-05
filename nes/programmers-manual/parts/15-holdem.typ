#import "../lib.typ": *

= Game Four: Texas Hold'em

#lead[Hold'em is 5 Card Stud's younger brother: the same client, the same
NES layer almost line for line, and a server that knows how to deal a flop.]

#shots("tx-1", "tx-3", w: 2.4in, caption: [The table list, and a hand in
progress against five bots: two hole cards each, the pot in the middle, the
moves on the status line.])

#objbox("Object of the game / Game description")[Two cards each, face down;
five shared cards dealt three, one and one; four rounds of betting with
blinds of 5 and 10 and a purse of 1000. The best five cards of the seven win.]

== A chapter of differences

`fujinet-texasHoldEm`'s `src/nes/` is 5 Card Stud's with four changes. The
tiles that `mkchr.py` generates are byte for byte the same. The differences:

#runin(
  ("The seats", [move to keep the middle of the table clear for the
   community cards. Hold'em never greys a hidden hole card, so seat 0 no
   longer has to sit on an even column.]),
  ("The pot", [moves down three rows, below the board.]),
  ("A face-down card", [already on the felt is left alone.]),
  ("The title", [says Texas Hold'em.]),
)

#excerpt-at("src/nes/vars.c: the seats", "listings/games/texasholdem/vars.c",
  "const unsigned char playerXMaster", n: 5, size: 6.6pt)

== Not redrawing what has not changed

The third difference, and a change to the shared `main.c`, come from the same
lesson. Every tile goes through cc65's queue at about 68 a frame. A poll that
redraws the whole table -- every opponent's two card backs, every purse --
keeps the queue full, and the next real change waits behind it. So the
card-drawing code ships nothing when a card back is already there:

#excerpt-at("src/nes/graphics.c", "listings/games/texasholdem/graphics.c",
  "            if (peek((x>WIDTH-3)?x-1:x, y+1) == UDG_BACK_L_TOP)", n: 2, size: 7pt)

and the main loop skips the redraw entirely when the reply is the same as the
last one, by keeping a checksum of it:

#excerpt-at("src/main.c", "listings/games/texasholdem/main.c",
  "        static unsigned int lastDrawnSum", to: "#else", size: 6.6pt)

Each byte is mixed with its position, so two bytes trading places still
changes the sum. A rare collision only means one poll goes undrawn.

== The wire

Hold'em's reply is 5 Card Stud's with one field added after `viewing`: the
community cards, eleven bytes, `askh2d` for the ace of spades, king of hearts
and two of diamonds. Everything after it moves down eleven, so a reply is 165
bytes and 33 for each player; the whole structure is 429. The moves gain
`RL` and `RH`, the smallest and a bigger raise, and `AI`, all in. A player
who is all in is reported to the 8-bit clients as merely playing.

The server -- `servers/fujinet-game-system/texasholdem` -- also offers a
WebSocket, and a `hash` parameter that answers just `1` when nothing has
changed. The NES client uses neither; its checksum does the same job without
a second request.

== The server's bots

Each bot has a personality: how often it plays a hand, how often it raises
before the flop, how often it bluffs. And the bots only play while a human is
seated -- an empty table waits.

#note[The table in the second picture shows a few cells of an earlier status
line left over beside the seats -- "FPOST", "OOOMEG". It is as the emulator
drew it, against the live server, and is not a fault of the camera.]
