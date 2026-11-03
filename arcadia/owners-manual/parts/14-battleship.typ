#import "../lib.typ": *

#booklet.update(true)
#bandfile.update(("apps.irata.online", "ARCADIA/!FUJINET/Battleship.bin"))
= Battleship
#show enum: set par(leading: 1.05em)

== General

Two to four fleets on one ocean. Hide your five ships, then take turns firing
-- and every shot you fire lands on *every* enemy board at once.

#steps(
  [In the browser, open *APPS.IRATA.ONLINE*, then *ARCADIA*, then *!FUJINET*,
   and choose *BATTLESHIP.BIN*.],
  [Give your name and choose a table as in 5 Card Stud (Section 12). The *AI*
   tables give you one, two or three robot admirals; *Cape Fuji* and *High
   Seas* are for people.],
  [The *LOBBY* lists the admirals at the table. Press the Action button when
   you are ready (#scr("FIRE = READY")); press it again if you are not. The
   game starts when everyone is ready.],
)

== Object of the Game

Each fleet has five ships, five, four, three, three and two squares long,
hidden on its own board. Sink every ship of every other fleet; the last fleet
with a ship afloat wins.

== To Start the Game

#grid(columns: (2.55in, 1fr), column-gutter: 0.35in, align: (center + top, left + top),
  fig(tv("bs-place", w: 2.45in), caption: [Place your ships]),
  [
    #steps(
      [#scr("PLACE YOUR SHIPS"): the first ship appears on your board, at the
       bottom of the screen.],
      [Move it with the disc. #kp(5) turns it (#scr("5 TURNS")).],
      [Press the Action button to leave it there (#scr("FIRE OK")). The next
       ship appears.],
      [When all five are placed, the game says #scr("WAITING ON SHIPS") until
       every admiral has placed theirs.],
    )
  ])

== To Play the Game

#fig(tvlab("bs-battle", w: 2.9in, (
  (..cell(0, 2, rows: 26), -0.03, 0.02, [Whose turn], left),
  (..cell(6, 6, rows: 26), -0.03, 0.25, [An enemy’s board, \ and your aim], left),
  (..cell(18, 6, rows: 26), -0.03, 0.7, [Your board \ and your fleet], left),
  (..cell(6, 15, rows: 26), 1.03, 0.25, [Ships afloat], right),
  (..cell(25, 2, rows: 26), 1.03, 0.93, [The enemy shown, \ and your aim], right),
)), caption: [Your turn])

The enemy’s board is at the top, your own at the bottom, with each fleet’s
ships beside its board. When it is #scr("YOUR TURN"), aim at any square and
fire. The game tells you #scr("MISS"), #scr("HIT") or #scr("SUNK").

#grid(columns: (2.55in, 1fr), column-gutter: 0.35in, align: (center + top, left + top),
  fig(overlay("Battleship", (none, "Fire", none, "Enemy back", "Turn ship",
    "Enemy on", none, none, none, "Leave", "Ask now", "Fire · Place"),
    head: [Action: fire · place · ready]), caption: [Overlay]),
  [
    #controls(title: [In battle], w: 1.1in,
      [#disc("udlr")], [Aim; while placing, move the ship.],
      [#FIRE or #ENTER], [Fire at that square, on every enemy board at
        once; place a ship.],
      [#kp(4) #kp(6)], [Show the next or the last enemy’s board, with three
        or four fleets.],
      [#kp(5)], [Turn a ship, while placing.],
      [#kp(0)], [Ask the server now, instead of waiting.],
      [#CLEAR], [Leave the game.],
    )
  ])
