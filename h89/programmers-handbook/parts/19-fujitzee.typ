#import "../lib.typ": *
#import "../prog.typ": *

#chapter(19, "Fujitzee")

#section("General")[
Fujitzee is a dice game for up to six, in thirteen rounds. In each turn you roll five dice, may roll
any of them again twice more, and then must score the result in one of thirteen boxes: the ones to
the sixes, a set of three or four, a full house, short and long runs, a "count" of everything, and a
Fujitzee --- five of a kind, 50 points. Each box takes one score in a game; the highest total wins.
The program is FUJITZEE.ABS for HDOS and FUJITZEE.COM for CP/M.
]

#section("Playing", balance: false)[
#steps(
  [Run FUJITZEE, give your name if it asks, and choose a table. P on the table list adds up to four
   players who share the H89, taking turns at the keyboard.],
  [Press SPACE when you are ready.],
  [On your turn the server rolls for you. Left and right move along the dice; RETURN keeps a die (or
   lets it go); RETURN on ROLL! rolls the rest. You have two more rolls.],
  [Then move up into the score column, choose a box with up and down (only those you may use are
   offered), and press RETURN.],
)

#pictorial(caption: [Choosing a game to join: a die in each corner, and the frame joins itself to the
title's box.], crt("fujitzee-1"))
#pictorial(caption: [The lobby: the robots are ready (in reverse video); you are not, yet.],
  crt("fujitzee-2"))
#pictorial(caption: [Your first turn, with the help box over the robots' columns.],
  crt("fujitzee-3"))
#pictorial(caption: [Round 5, your turn, two dice kept (the hollow ones); the scores you could take
are in reverse video.], crt("fujitzee-4"))
]

#section("How It Works")[
#sub("The state")
Fujitzee polls about once a second. Its `Game` structure is 599 bytes, which the program checks at
compile time:

#fields-table(
  [0], [1], [How many players (players first, then those watching).],
  [1], [21], [The table's name.],
  [22], [41], [The prompt to show.],
  [63], [1], [The round, 1 to 13; 0 in the lobby, 99 when it is over.],
  [64], [1], [Rolls left.],
  [65], [1], [Whose turn.],
  [66], [1], [Seconds left to move.],
  [67], [1], [1 if you are only watching.],
  [68], [6], [The dice, as digits: `35126`.],
  [74], [6], [Which were kept: `01101`.],
  [80], [15], [For each box, the score it would give, or -1 if it may not be used.],
  [95], [42 each], [Each player: name, a one-letter alias, and sixteen scores (-1 for empty).],
)

A roll is `roll/01101` (1 to roll that die again), and a score `score/n`. With players sharing the
H89, each has a request of its own.

#sub("Drawing the board")
The board is the 40-column one made 80 wide: the boxes' names in full, then a column eight wide for
each player. The lines are drawn by direction, so where two meet the right corner, T or cross appears
by itself. The dice are seven characters by three, which looks square on the H19: a die still to roll
is a solid block in reverse video with dark pips; a kept one is hollow, with bright pips between two
bars.

Fujitzee keeps three pictures of the screen in memory --- the one being drawn, the one on the
terminal, and one saved under the menu and help --- 6,000 bytes in all, which is why it needs a
full-memory H89 under HDOS. It sends the screen before each FujiNet request, so that "refreshing"
shows while the request is out.
]

#section("The Files")[
#stable((1.35in, 1fr), size: 7.6pt,
  th[File], th[Holds],
  [`src/main.c`], [The globals, the main loop: poll, animate, keys.],
  [`src/stateclient.c`], [Requests (one per player sharing the H89), moves, the state.],
  [`src/screens.c`], [Help, players, name, welcome, table list, the menu.],
  [`src/gamelogic.c`], [The board, the dice and their animation, turns, scoring.],
  [`src/misc.c`, `misc.h`], [Keys, preferences (app key E41CH/3/0); the structures.],
  [`src/platform-specific/*.h`], [What the H89's part must supply.],
  [`src/h89/console.c`], [The H19: three pictures of the screen; the OS console.],
  [`src/h89/graphics.c`], [The board, dice, cursor, tab and frames.],
  [`src/h89/input.c`], [The H19's keys; sends the screen first.],
  [`src/h89/fujinet.c`], [The fujinet-lib calls, sending the screen first.],
  [`src/h89/sound.c`, `util.c`, `vars.h`], [The bell; frames, the move clock, the size check; layout.],
)

#note[Fujitzee's H89 port was not yet committed to its repository when this Manual was made. This
listing is of its working tree, as it then stood (branch `add-h89`, on 3fe25a6, with 11 files
changed).]
]

#section("Listing", balance: false)[
#plisting("fujitzee")
]
