#import "../lib.typ": *

= Fujitzee

The dice game. Roll five dice up to three times a turn, keep the ones you
like, and score the result in one of thirteen boxes on your card. After
thirteen rounds the highest total wins. Up to six players, with robots on
hand.

== Loading the Game

Load it from the browser: host *apps.irata.online*, folder *ATARI-5200* #into
*FUJINET*, game *Fujitzee.a52*. The very first time, it shows how to play;
press any key to read on. Give your name if it asks. On #scr("choose a game to
join"), pick a table and press the bottom button. *The Bar* and *Kitchen Table*
are for people; the *AI Rooms* add two or four robots.

#shots(("fz-tables", [The tables]), ("fz-ready", [The waiting room]), w: 1.72in)

In the waiting room, press the bottom button to say you are *ready*
(#scr("press fire to toggle")). The game starts when everyone is ready.

== Your Turn

#shot("fz-play", [Your turn, after the first roll])

Your card fills the left of the screen, a column for each player, with the
round and the players beside it. The five dice sit at the bottom, after
*ROLL*.

#steps(
  [The pointer starts on *ROLL*. Press the bottom button to roll.],
  [Move left and right along the dice. The bottom button *keeps* a die;
   press again to let it go.],
  [Roll again -- up to three rolls in all.],
  [Move up onto the card. Each box shows what this roll would score there.
   Move to the box you want and press the bottom button.],
)

#controls(title: [Fujitzee], w: 1.05in,
  [#stick("udlr") \ or #kp(2, 4, 6, 8)], [Along the dice; up onto the card;
    up and down the boxes.],
  [#BOTTOM or #HASH], [Roll, keep a die, or score a box. In the waiting room,
    *ready*.],
  [#PAUSE or #STAR], [The menu: #RESET quit the table, #kp(1) how to play,
    #kp(0) sound; #PAUSE keeps playing.],
  [#TOP or #kp(1)], [How to play.],
  [#START], [At the table list: fetch it again.],
  [#RESET], [At the table list: leave Fujitzee, for the Lobby (Section 11).],
)

== The Card

#tbl((1fr, 1.6fr),
  th[Box], th[Scores],
  [*one* through *six*], [The total of the dice showing that number],
  [*total*, *bonus*], [Your top-half total, and a *bonus of 35* once it
    reaches 63],
  [*set 3*, *set 4*], [Three or four of a kind: the total of all five dice],
  [*house*], [Three of one number and two of another: *25*],
  [*s run*], [Four in a row: *30*],
  [*l run*], [Five in a row: *40*],
  [*count*], [Anything: the total of all five dice],
  [*fujitzee*], [All five the same: *50*],
)

You have about *45 seconds* a turn; if time runs out, the game scores for you
(#scr("you timed out. auto scoring.")). After thirteen rounds the standings
show who won.
