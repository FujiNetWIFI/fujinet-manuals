#import "../lib.typ": *

#booklet.update(true)
#bandfile.update(("apps.irata.online", "ARCADIA/!FUJINET/Texas Hold 'em.bin"))
= Texas Hold’em
#show enum: set par(leading: 1.05em)

== General

The other great poker game: two cards of your own, five shared by the whole
table, and the best five-card hand wins. It plays like 5 Card Stud, on the same
kind of table, with robots to fill the seats.

#steps(
  [In the browser, open *APPS.IRATA.ONLINE*, then *ARCADIA*, then *!FUJINET*,
   and choose *TEXAS HOLD 'EM.BIN* (the apostrophe shows as a box).],
  [Give your name and choose a table as in 5 Card Stud (Section 12). The
   tables are *The Basement*, *The Den* and the three *AI Rooms*.],
)

== Object of the Game

Everyone starts with *1,000* chips.

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

== To Play the Game

#fig(tvlab("th-table", w: 3.0in, (
  (..cell(0, 1, rows: 26), -0.03, 0.02, [The pot], left),
  (..cell(1, 6, rows: 26), -0.03, 0.1, [The shared cards], left),
  (..cell(0, 14, rows: 26), 1.03, 0.02, [The round: PRE, \ FLOP, TURN, \ RIVER, SHOW], right),
  (..cell(17, 2, rows: 26), -0.03, 0.66, [Your two cards], left),
  (..cell(22, 9, rows: 26), 1.03, 0.88, [Your moves], right),
)), caption: [After the flop])

The shared cards lie in a row under the pot, with the round named at the
right. Your two cards are at the bottom, under your name. Your moves --
here #scr("1 FOLD"), #scr("2 CHECK"), #scr("3 BET 10"), #scr("4 BET 20") and
5, #scr("ALL-IN") -- are on the white line, with the seconds you have left. The
buttons are 5 Card Stud’s: #kp(1) to #kp(5) make a move (the Action button
is move 2), #kp(0) asks the server now, and #CLEAR leaves the table.
