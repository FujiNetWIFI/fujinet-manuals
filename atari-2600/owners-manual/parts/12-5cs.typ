#import "../lib.typ": *

= 5 Card Stud

Up to eight players around one table, on any computer or console FujiNet
plays on -- and if there are not enough people, the house's robots fill the
seats. Each hand you get one card face down and four face up, and the best
poker hand takes the pot.

== Loading the Game

Choose a 5 Card Stud table in the Lobby (Section 11), or load it from the
browser: host *apps.irata.online*, folder *Atari_2600*, game *5CARD.BIN*.

The first time, the game asks *YOUR NAME*. Move around the letters with the
joystick and press the red button to type; *OK* finishes, *DEL* erases, *SPC*
is a space. (If you have already given FujiNet a name, it just uses that.)

Then comes the list of tables. *The Basement* and *The Den* are for people;
the *AI Rooms* seat you with two, four or six robot players, which is the
best way to learn. Move to a table and press the red button -- *FIRE TO SIT*.

#shots(("5cs-tables", [The tables]), ("5cs-banner", [The hand is over]),
       ("5cs-purses", [GAME SELECT held]), ("5cs-menu", [TABLE MENU]),
       h: 1.2in, gutter: 6pt)

#grid(columns: (auto, 1fr), column-gutter: 12pt, align: (left + top, left + top),
  shot("5cs-table", h: 2.1in),
  [
    == The Table

    - *Top line:* *P* and the pot, then *\$* and your purse.
    - *Eight seats*, two lines each: each card's rank over its suit, then
      the player's name and what they have bet. A face-down card is drawn
      as a hatched back until the showdown.
    - A seat's *colour* tells you its state: whose turn it is, who has
      folded, who has left, and which seat is yours.
    - *Bottom lines:* your moves when it is your turn. The bar marks the
      move you are on, and the number on it is the seconds you have left.
      Otherwise *WAITING ON* and whose turn it is.
  ],
)

#controls(title: [5 Card Stud],
  [#stick("ud")], [Choose a move (or a table, or a letter).],
  [#FIRE], [Make that move. In the table list, sit down.],
  [#key("GAME SELECT") held], [Every seat shows its *purse* instead of its bet.],
  [#stick("r")], [Ask the server now, instead of waiting.],
  [#stick("l") or #RESET], [The *TABLE MENU*: *RESUME*, *HOW TO PLAY*, or *LEAVE TABLE*.],
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
   hand wins the pot, and the end-of-hand message runs along the bottom.],
  [About twelve seconds later the next hand is dealt.],
)

Everyone starts with *\$200*. You have about *forty seconds* for each move.
If the clock runs out, the move under the bar is sent for you -- and the bar
never starts on FOLD, so you will not drop out by accident.

#note[To leave, use LEAVE TABLE from the TABLE MENU. It gives your seat back
properly, so the others are not left waiting for you.]
