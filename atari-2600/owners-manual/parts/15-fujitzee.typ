#import "../lib.typ": *

= Fujitzee

The dice game. Roll five dice up to three times a turn, keep the ones you
like, and score the result in one of thirteen boxes on your card. After
thirteen rounds the highest total wins. Up to six players, with robots on
hand.

== Loading the Game

Choose a Fujitzee table in the Lobby, or load it from the browser: host
*apps.irata.online*, folder *Atari_2600*, game *FUJITZEE.BIN*. Give your name
if it asks (*YOUR NAME*; *RST=DONE* -- here GAME RESET finishes). On *PICK A
TABLE*, choose a table and press the red button (*FIRE=JOIN*). *The Bar* and
*Kitchen Table* are for people; the *AI Rooms* add two or four robots. In the
waiting room, press the red button when you are ready.

#grid(columns: (auto, 1fr), column-gutter: 12pt, align: (left + top, left + top),
  shot("fz-card", h: 2.0in),
  [
    == Your Turn

    The card fills the screen, one box to a line. The five dice sit near the
    bottom, with *ROLL* and the rolls you have left beneath them.

    #steps(
      [The pointer starts on *ROLL*. Press the red button to roll.],
      [Move left and right along the dice. The red button *holds* a die
       (drawn as brackets, with a mark beneath); press again to let it go.],
      [Roll again -- up to three rolls in all.],
      [Push up onto the card. *Green* lines show what this roll would score
       in each box. Move to the box you want and press the red button.],
    )
  ],
)

Pressing the red button over and over plays a legal, if unwise, game: the
pointer starts on ROLL, and after the last roll it waits on the box that pays
best.

#controls(title: [Fujitzee],
  [Joystick], [Left and right along the dice; up onto the card; up and down the boxes.],
  [#FIRE], [Roll, hold a die, or score a box. In the waiting room, *ready*.],
  [#SELECT], [The *MENU*: *RESUME*, *HOW TO PLAY*, *LEAVE TABLE*.],
  [#RESET], [Ask the server now.],
  [#key("LEFT DIFFICULTY") at A], [Show everyone's standings, for as long as it stays at A.],
)

== The Card

#tbl((1fr, 1.6fr),
  th[BOX], th[SCORES],
  [*ONE* through *SIX*], [The total of the dice showing that number],
  [*UP*], [Your top-half total, and a *bonus of 35* once it reaches 63],
  [*SET 3*, *SET 4*], [Three or four of a kind: the total of all five dice],
  [*FULL HSE*], [Three of one number and two of another: *25*],
  [*SM STRT*], [Four in a row: *30*],
  [*LG STRT*], [Five in a row: *40*],
  [*FUJITZEE*], [All five the same: *50*],
  [*CHANCE*], [Anything: the total of all five dice],
)

Lines in *blue* are boxes already filled; *yellow* is your pointer (or the box
a robot has just taken). You have *45 seconds* a turn. At *GAME OVER* the
standings show who won.

#shots(("fz-wait", [Waiting for everyone]), ("fz-over", [Game over]), h: 1.05in)
