#import "../lib.typ": *

#booklet.update(true)
#bandfile.update(("apps.irata.online", "ARCADIA/!FUJINET/5 Card Stud.bin"))
= 5 Card Stud
#show enum: set par(leading: 1.05em)

== General

Up to eight players around one table, on any computer or console FujiNet
plays on -- and if there are not enough people, the house’s robots fill the
seats.

#steps(
  [Be sure the FujiNet cartridge is in the slot and FujiNet has joined your
   network (Section 6).],
  [In the browser, open *APPS.IRATA.ONLINE*, then *ARCADIA*, then *!FUJINET*,
   and choose *5 CARD STUD.BIN*.],
  [Play with the *left* hand controller.],
)

== Object of the Game

Each hand you get one card face down and four face up, and the best poker
hand takes the pot. Everyone starts with *200* chips.

#steps(
  [Everyone puts *1* in the pot to start (the ante). Each player is dealt one
   card face down and one face up.],
  [The player showing the lowest card must *POST* to begin the betting.
   Going round the table, each player may *CALL* (match the bet), *BET* or
   *RAISE* (make it bigger), *CHECK* (bet nothing, when there is nothing to
   call), or *FOLD* (drop out of this hand).],
  [A third, fourth and fifth card are dealt face up, each followed by another
   round of betting. Bets are *5* in the early rounds and *10* later; a round
   allows no more than three raises.],
  [When the betting is done, the hidden cards are turned over. The best poker
   hand wins the pot, and a few seconds later the next hand is dealt.],
)

== To Start the Game

#steps(
  [The game asks #scr("YOUR NAME"), with #scr("ARCADIA") already spelled.
   Press the disc up or down to spin the letter at the cursor through A--Z,
   0--9 and a blank; #kp(4) and #kp(6) move the cursor. Press #ENTER.],
  [#scr("CHOOSE A TABLE"): each table with the players seated and the seats
   in all. *The Basement* and *The Den* are for people; the *AI Rooms* seat
   you with two, four or six robot players, which is the best way to learn.],
  [Move to a table with the disc and press #ENTER (#scr("ENTER JOINS")).
   #CLEAR goes back to your name (#scr("CLEAR RENAMES")); #kp(0) fetches the
   list again.],
)

#shots(("fcs-name", [Your name]), ("fcs-tables", [The tables]), w: 2.1in)

== To Play the Game

#fig(tvlab("fcs-table", w: 2.7in, (
  (..cell(0, 1, rows: 26), -0.03, 0.02, [The pot], left),
  (..cell(0, 14, rows: 26), 1.03, 0.02, [The round], right),
  (..cell(4, 3, rows: 26), -0.03, 0.17, [A robot’s cards: \ one face down], left),
  (..cell(8, 12, rows: 26), 1.03, 0.3, [What each player \ last did], right),
  (..cell(17, 3, rows: 26), -0.03, 0.62, [Your name, \ and your cards], left),
  (..cell(20, 3, rows: 26), -0.03, 0.8, [Your chips], left),
  (..cell(20, 14, rows: 26), 1.03, 0.77, [Seconds left \ for your move], right),
  (..cell(22, 4, rows: 26), 1.03, 0.9, [Your moves], right),
)), caption: [Your turn])

Each seat shows the player’s name over their cards. When it is your turn,
your moves are numbered on the white line at the bottom -- here
#scr("1 FOLD"), #scr("2 CALL") and #scr("3 RAISE") -- with the seconds you
have left at the right. Press the number of the move you want. Otherwise the
line says #scr("WAITING ON") and whose turn it is.

#grid(columns: (2.55in, 1fr), column-gutter: 0.35in, align: (center + top, left + top),
  fig(overlay("5 Card Stud", ("Move 1", "Move 2", "Move 3", "Move 4 · Name left",
    "Move 5", "Name right", none, none, none, "Leave", "Ask now", "Join · OK"),
    head: [Action: move 2 · join]), caption: [Overlay]),
  [
    #steps(
      [Watch the white line. When your moves appear, press #kp(1) to #kp(5)
       to make one. The Action button is move 2.],
      [You have about *forty seconds* for each move. If the clock runs out,
       the server moves for you.],
      [#kp(0) asks the server for the table now, instead of waiting.],
      [To leave the table, press #CLEAR. Your seat is given back properly, so
       the others are not left waiting for you.],
    )
  ])
