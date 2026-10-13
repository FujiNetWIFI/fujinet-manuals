#import "../lib.typ": *
#import "../prog.typ": *

#chapter(17, "Texas Hold'em")

#section("General")[
Texas Hold'em is the poker game of the card rooms: up to eight players at a table, each starting
with 1000 chips, blinds of 5 and 10. Each player is dealt two cards face down; five more are dealt
face up in the middle, three (the *flop*), then one (the *turn*), then one more (the *river*), with
a round of betting before each and after the last. The best five-card hand from your two and the
five in the middle wins the pot.

The server's tables include "AI rooms" with two, four or six robot players, so there is always a
game. The program is TEXAS.ABS for HDOS and TEXAS.COM for CP/M.
]

#section("Playing", balance: false)[
#steps(
  [Run TEXAS. The first time, it asks for your name (2 to 8 letters), and keeps it in the lobby's app
   key, where every FujiNet game will find it.],
  [Choose a table with the arrow keys (or `-` and `=`) and RETURN. The list shows how many of each
   table's human seats are taken; tables with robots have fewer human seats.],
  [When it is your turn, the bottom line offers your moves and a countdown. Left and right choose a
   move; up and down choose between the two sizes of bet or raise; RETURN sends it.],
  [ESC (or any of the H19's function keys) opens the menu: Q leaves the table, H shows the help, C
   changes how red cards are drawn.],
)

#pictorial(caption: [The first screen: your name, kept in the lobby's app key for every game. The
suits are pictures two characters square.], crt("texas-1"))
#pictorial(caption: [Choosing a table. The names come from the server, in lower case; a table with
six robots has two human seats.], crt("texas-2"))
#pictorial(caption: [A hand at the six-robot table, on the flop, your turn: CALL is chosen, 32 seconds
left on the clock at the right of the bottom line.], crt("texas-3"))
#pictorial(caption: [The showdown: every hand is turned up, and the bottom line gives the server's
verdict.], crt("texas-4"))
]

#section("How It Works")[
#sub("The state")
Every poll is `state?table=ai6&player=thom&bin=1` (or a move, `move/ca`, in its place). The reply
is the `Game` structure, read straight into memory:

#fields-table(
  [0], [81], [The last hand's result, as text.],
  [81], [1], [The round: 0 waiting, 1 before the flop, 2 flop, 3 turn, 4 river, 5 showdown.],
  [82], [2], [The pot.],
  [84], [1], [Whose turn it is; players are numbered from you, so 0 is you.],
  [85], [1], [Seconds left to move (only on your turn).],
  [86], [1], [1 if you are only watching (the table is full).],
  [87], [11], [The cards in the middle, as `askh2d` (ace of spades, king of hearts, two of diamonds).],
  [98], [66], [How many moves you may make, and up to five: a code and a name each.],
  [164], [1], [How many players.],
  [165], [33 each], [Each player: name, status, bet, last move, purse, and hand (`????` until the
    showdown).],
)

Texas Hold'em polls as fast as the server answers, and adds up the reply's bytes, each weighted by
its place; it repaints only when the sum changes. The H19 would be sent nothing anyway for an
unchanged table (the console layer sends only changed cells), but repainting also redraws the
highlight that sweeps to the active player, which would flicker.

#sub("Drawing the cards")
The H19 has no card suits in its character set, so each card's suit is a picture two characters
square, made of the graphics set's triangles and quarter blocks, under the rank. A card is six
characters by five, with corners and edges from the graphics set; a face-down card is checkerboard.
The H19 is monochrome, so the "colour" setting draws hearts and diamonds in reverse video instead of
red. The table is an oval of diagonals; you are always at the bottom, in the middle.

The title is TEXAS HOLD'EM in letters made of quarter blocks, two dots by two per character, drawn
from a table (`logo.h`) that a small Python program made from a picture.

#sub("Moves")
The server says which moves are allowed and computes every amount. The H89's bottom line has room
for five stops beside the clock, so CALL and RAISE share one, with the amount beside it. When your
clock runs out, the program sends the chosen CHECK or CALL itself, so the server never folds you, and
it does not poll the server while it waits for you.
]

#section("The Files")[
#stable((1.35in, 1fr), size: 7.6pt,
  th[File], th[Holds],
  [`src/main.c`], [The globals and the main loop; the repaint check.],
  [`src/stateclient.c`], [Builds each request and reads the reply into the state.],
  [`src/screens.c`], [Help, name, welcome, table list, the game screen, the menu.],
  [`src/gamelogic.c`], [Seats, pot, betting, dealing, the move menu and its countdown.],
  [`src/misc.c`, `misc.h`], [Pauses, keys, preferences (app key BEBEH/1/0); the structures.],
  [`src/platform-specific/*.h`], [What the H89's part must supply.],
  [`src/h89/console.c`], [The H19: the screen in memory, changed cells only; the OS console.],
  [`src/h89/graphics.c`], [The table, cards, chips, logo and status line.],
  [`src/h89/input.c`], [The H19's keys, escape sequences decoded.],
  [`src/h89/network.c`], [A request through fujinet-lib.],
  [`src/h89/appkey.c`], [App keys through fujinet-lib.],
  [`src/h89/sound.c`, `util.c`], [The bell; frames, the move timer, leaving.],
  [`src/h89/vars.c`, `vars.h`, `logo.h`], [The layout, keys, and the title.],
)
]

#section("Listing", balance: false)[
#plisting("texasHoldEm")
]
