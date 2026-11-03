#import "../lib.typ": *

= Texas Hold’em

The other great poker game: two cards of your own, five shared by the whole
table, and the best five-card hand wins. It plays like 5 Card Stud, on the same
kind of table, with robots to fill the seats.

== Loading the Game

Load it from the browser: host *apps.irata.online*, folder *ATARI-5200* #into
*FUJINET*, game *Texas Hold’em.a52*. The name screen, the table list and the
tables -- *The Basement*, *The Den* and the three *AI Rooms* -- work as in
5 Card Stud (Section 12).

#shots(("th-tables", [The tables]), ("th-table", [After the flop]), w: 1.72in)

The three shared cards in the middle are the *flop*, with the round named
beside them. Your two cards are at the bottom, by #scr("YOU"); your moves --
here #scr("FOLD"), #scr("CHECK/BET") and #scr("ALL-IN") -- are on the bottom
line, with the seconds you have left.

#controls(title: [Texas Hold’em], w: 1.05in,
  [#stick("udlr")], [Choose a table; at your turn, move the bar along your
    moves.],
  [#BOTTOM, #HASH \ or #START], [Sit down; make the move the bar is on.],
  [#TOP, #STAR, \ #PAUSE or #RESET], [The table menu; #PAUSE there goes back
    to the game.],
  [#kp(1) to #kp(5)], [As in 5 Card Stud: list again, how to play, colour,
    name, leave.],
)

== Your First Hand

#steps(
  [Two players put in the *blinds*, *5* and *10*, to start the pot. Everyone
   is dealt two cards face down.],
  [Going round the table, each player may *CALL*, *RAISE* or *FOLD* -- or
   *CHECK*, if there is nothing to call.],
  [Three shared cards are dealt (the *flop*), then another betting round;
   then a fourth (the *turn*) and a fifth (the *river*), each with its own
   betting round.],
  [At the *showdown*, each player makes the best five-card hand from their
   two cards and the five shared ones. The best hand takes the pot.],
)

Everyone starts with *1,000* chips. As in 5 Card Stud you have about forty
seconds a move, and the next hand follows by itself. To leave, open the table
menu and press #kp(5), *QUIT TABLE*.
