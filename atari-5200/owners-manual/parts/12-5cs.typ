#import "../lib.typ": *

= 5 Card Stud

Up to eight players around one table, on any computer or console FujiNet
plays on -- and if there are not enough people, the house’s robots fill the
seats. Each hand you get one card face down and four face up, and the best
poker hand takes the pot.

== Loading the Game

Load it from the browser: host *apps.irata.online*, folder *ATARI-5200* #into
*FUJINET*, game *Five Card Stud.a52*. The first time, the game asks
#scr("ENTER YOUR NAME"): move around the letters with the joystick, press the
bottom button to type, and choose *OK* when you are done. If you have already
given FujiNet a name, it uses that one.

#shots(("fcs-name", [Your name]), ("fcs-tables", [The tables]), w: 1.72in)

Then comes the list of tables. *The Basement* and *The Den* are for people;
the *AI Rooms* seat you with two, four or six robot players, which is the best
way to learn. Move to a table and press the bottom button to sit down.

#shot("fcs-table", [Your turn: the bar is on CALL, and 33 seconds are left])

== The Table

Each seat shows the player’s chips over their name, and their cards; your own
seat is at the bottom, marked #scr("YOU"). The pot is in the middle, with what
each player last did beside their seat -- #scr("POST"), #scr("CALL"),
#scr("FOLD"). When it is your turn, your moves are on the bottom line, with a
bar under the one you are on and the seconds you have left at the right.
Otherwise it says whose turn it is.

#controls(title: [5 Card Stud], w: 1.05in,
  [#stick("udlr")], [Choose a table; at your turn, move the bar along your
    moves.],
  [#BOTTOM, #HASH \ or #START], [Sit down; make the move the bar is on.],
  [#TOP, #STAR \ or #RESET], [The table menu (below).],
  [#kp(1)], [Fetch the table list again.],
  [#kp(2) or #PAUSE], [How to play.],
  [#kp(3)], [Change the colour of the table.],
  [#kp(4)], [Change your name.],
  [#kp(5)], [At the table list: leave the game, for the Lobby (Section 11).],
)

== Your First Hand

#steps(
  [Everyone puts *1* in the pot to start (the ante). Each player is dealt one
   card face down and one face up.],
  [The player showing the lowest card must *POST 2* to begin the betting.
   Going round the table, each player may *CALL* (match the bet), *BET* or
   *RAISE* (make it bigger), or *FOLD* (drop out of this hand).],
  [A third, fourth and fifth card are dealt face up, each followed by another
   round of betting. Bets are *5* in the early rounds and *10* later; a round
   allows no more than three raises.],
  [When the betting is done, the hidden cards are turned over. The best poker
   hand wins the pot.],
  [A few seconds later the next hand is dealt.],
)

Everyone starts with *200* chips. You have about *forty seconds* for each
move; if the clock runs out, the move under the bar is made for you.

#shot("fcs-menu", [The table menu], w: 1.9in)

To leave, open the table menu and press #kp(5): *QUIT TABLE* gives your seat
back properly, so the others are not left waiting for you, and takes you to the
table list. #kp(2) explains the game, #kp(3) changes the table’s colour, and
#RESET goes back to the game.
