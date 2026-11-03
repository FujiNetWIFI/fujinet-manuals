#import "../lib.typ": *

#booklet.update(true)
#bandfile.update(("apps.irata.online", "ARCADIA/!FUJINET/Fujitzee.bin"))
= Fujitzee
#show enum: set par(leading: 1.05em)

== General

The dice game. Roll five dice up to three times a turn, keep the ones you
like, and score the result in one of the boxes on your card. Up to six
players, with robots on hand.

#steps(
  [In the browser, open *APPS.IRATA.ONLINE*, then *ARCADIA*, then *!FUJINET*,
   and choose *FUJITZEE.BIN*.],
  [Give your name and choose a table as in 5 Card Stud (Section 12). *The
   Bar* and *Kitchen Table* are for people; the *AI Rooms* add two or four
   robots.],
  [In the *LOBBY*, press the Action button when you are ready
   (#scr("FIRE TO READY")); each player shows #scr("READY") or #scr("WATCH").
   The game starts when everyone is ready.],
)

== Object of the Game

Fill every box on your card. After the last round the highest total wins.

#tbl((1.6in, 1fr),
  th[Box], th[Scores],
  [*ONE* through *SIX*], [The total of the dice showing that number],
  [*UP*, *BON*], [Your top-half total, and a *bonus of 35* once it reaches
    63],
  [*SET3*, *SET4*], [Three or four of a kind: the total of all five dice],
  [*HOUS*], [Three of one number and two of another: *25*],
  [*SRUN*], [Four in a row: *30*],
  [*LRUN*], [Five in a row: *40*],
  [*CNT*], [Anything: the total of all five dice],
  [*FUJI*], [All five the same: *50*],
  [*TOT*], [Your total],
)

== To Play the Game

#fig(tvlab("fz-turn", w: 2.9in, (
  (..cell(0, 2, rows: 26), -0.03, 0.02, [Your name], left),
  (..cell(6, 1, rows: 26), -0.03, 0.25, [The boxes], left),
  (..cell(4, 12, rows: 26), 1.03, 0.15, [Each player’s \ scores], right),
  (..cell(14, 6, rows: 26), -0.03, 0.55, [The dice], left),
  (..cell(17, 4, rows: 26), 1.03, 0.66, [ROLL, and how \ many rolls made], right),
)), caption: [Your turn, after the first roll])

When it is #scr("YOUR TURN"), the pointer is on *ROLL*.

#steps(
  [Press the Action button to roll.],
  [Move left and right along the dice. The Action button *keeps* a die;
   press again to let it go.],
  [Move down to *ROLL* and roll again -- up to three rolls in all.],
  [Move up onto the card. Move to the box you want and press the Action
   button to score it. After the last roll the pointer goes to the box that
   pays most, so you may simply press the button.],
)

#grid(columns: (2.55in, 1fr), column-gutter: 0.35in, align: (center + top, left + top),
  fig(overlay("Fujitzee", (none, "Select", none, none, none, none,
    none, none, none, "Leave", "Ask now", "Select"),
    head: [Action: roll · keep · score]), caption: [Overlay]),
  [
    #controls(title: [Fujitzee], w: 1.1in,
      [#disc("ud")], [Up and down the boxes; down to ROLL.],
      [#disc("lr")], [Along the dice. While others play, turn to another
        player’s card.],
      [#FIRE, #kp(2) \ or #ENTER], [Ready; roll; keep a die; score a box.],
      [#kp(0)], [Ask the server now.],
      [#CLEAR], [Leave the table.],
    )
  ])
