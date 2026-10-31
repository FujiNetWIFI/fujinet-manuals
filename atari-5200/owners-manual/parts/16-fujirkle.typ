#import "../lib.typ": *

= Fujirkle

A dice game of nerve. Roll six dice, set aside the ones that score, and either
roll on for more or bank what you have -- but roll nothing that scores and you
lose the whole turn. The first to 10,000 points starts the final round. Up to
six players, with robots on hand.

#note[Fujirkle for the 5200 is being finished now, and is not yet in the
library on _apps.irata.online_. When it is, it will sit beside the other games
in *ATARI-5200* #into *FUJINET*. What follows is how it plays.]

== Loading the Game

The table list (#scr("choose a game to join")), the name and the waiting room
work as in Fujitzee (Section 15): *The Bar* and *Kitchen Table* are for
people, the *AI Rooms* add two or four robots, and the bottom button says you
are ready.

#shots(("fk-tables", [The tables]), ("fk-play", [Your turn]), w: 1.72in)

== Your Turn

The players and their scores are at the top left; the dice you have *kept*
this turn, and the turn’s score so far, at the top right. Your six dice are at
the bottom, after *ROLL* and *BANK*.

#steps(
  [Press the bottom button on *ROLL* to throw the dice.],
  [Move along the dice and press the bottom button on each one that scores
   to set it aside. You must keep at least one.],
  [Then either *ROLL* the rest again for more, or *BANK* to add the turn’s
   score to your total and end your turn.],
  [Roll nothing that scores, and the turn is over with nothing banked. Set
   aside all six, and you have *hot dice*: roll all six again.],
)

#controls(title: [Fujirkle], w: 1.05in,
  [#stick("udlr") \ or #kp(2, 4, 6, 8)], [Along the dice. Up jumps to ROLL,
    down to BANK.],
  [#BOTTOM, #HASH \ or #kp(5)], [Roll, keep a die, or bank. In the waiting
    room, *ready*.],
  [#START, #PAUSE \ or #STAR], [The menu: #RESET quit the table, #kp(1) how to
    play, #kp(3) sound; #START goes back to the game.],
  [#TOP or #kp(1)], [How to play.],
  [#kp(3)], [Sound on or off.],
  [#kp(0)], [At the table list: fetch it again.],
  [#RESET], [At the table list: leave Fujirkle, for the Lobby (Section 11).],
)

== What Scores

#tbl((1.3fr, 1fr),
  th[Dice], th[Points],
  [A single 1], [100],
  [A single 5], [50],
  [Three of a kind], [100 × the number (three 1s: 1,000)],
  [Four, five or six of a kind], [twice, four times or eight times that],
  [1-2-3-4-5-6, a straight], [1,500],
  [Three pairs], [1,500],
)

When someone reaches *10,000*, everyone else has one last turn, and the highest
score wins. If time runs out on your turn, the game banks for you.
