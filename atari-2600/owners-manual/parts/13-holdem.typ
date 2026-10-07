#import "../lib.typ": *

= Texas Hold'em

The poker game everyone knows, for up to eight players with robots to fill
empty seats. Each player gets two cards of their own, five cards in the
middle are shared by all, and the best five-card hand wins.

== Loading the Game

Choose a Texas Hold'em table in the Lobby, or load it from the browser: host
*apps.irata.online*, folder *Atari_2600*, game *TEXAS.BIN*. The name screen
and the table list work just as in 5 Card Stud. Pick an *AI ROOM* to learn
against robots, or *THE DEN* or *THE BASEMENT* to play people.

#shots(("th-0001", [The tables]), ("th-0007", [Your turn]),
       ("th-0003", [The hand is over]), ("th-0016", [TABLE MENU]), h: 1.0in,
       gutter: 6pt)

== The Table

Your seat is at the top. Under each player's name are their two cards (yours
face up, the others' face down until the showdown) and their chips. Below the
eight seats are the *shared cards* -- three, then four, then five as the hand
goes on -- with the pot and your purse beside them. At the bottom are your
moves, with the bar on the one you are about to make and the seconds you have
left.

The controls are the same as 5 Card Stud's: up and down choose a move, the red
button makes it, holding GAME SELECT shows everyone's purse, right asks the
server now, and left or GAME RESET opens the *TABLE MENU*.

== Your First Hand

#steps(
  [Two players put in the *blinds*, *5* and *10*, to start the pot. Everyone
   is dealt two cards face down.],
  [Going round the table, each player may *CALL*, *RAISE* or *FOLD* -- or
   *CHECK*, if there is nothing to call.],
  [Three shared cards are dealt (the *flop*), then another betting round;
   then a fourth (the *turn*) and a fifth (the *river*), each with its own
   betting round.],
  [At the showdown, each player makes the best five-card hand from their two
   cards and the five shared ones. The best hand takes the pot.],
)

Everyone starts with *\$1,000*. As in 5 Card Stud you have about forty
seconds a move, and the next hand follows by itself.
