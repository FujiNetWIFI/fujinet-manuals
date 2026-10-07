#import "../lib.typ": *

= The Game Lobby

The *FujiNet Game Lobby* is a list of every network game that has a table
open right now, on every kind of computer and console FujiNet works with. Pick
a table and the Lobby loads the right game and sends you straight to it.

To open the Lobby, press *GAME SELECT* on the FN HOSTS screen and choose
*LOBBY*. FujiNet loads it from the Internet.

#grid(columns: (auto, 1fr), column-gutter: 12pt, align: (left + top, left + top),
  shot("lobby", w: 1.55in),
  [
    The top line says *LOBBY* and which page you are on. Each game has a
    coloured band; under it are its tables, with how many players are sitting
    and how many seats there are -- *2/8* is two players at a table for
    eight.

    #controls(title: [In the Lobby],
      [#stick("ud")], [Choose a table.],
      [#stick("lr")], [Previous or next page.],
      [#FIRE], [Join that table: load its game and sit down.],
      [#SELECT], [Change your name.],
      [#RESET], [Fetch the list again.],
    )
  ],
)

The bottom of the screen shows *SEL=* and your name -- GAME SELECT is the
switch that changes it. *RST=REFRESH* reminds you that GAME RESET asks for a
fresh list.

== Your Name

FujiNet keeps one player name for all of its games, so you type it once. The
Lobby asks for it the first time (*ENTER NAME*), and every FujiNet game uses
the same one. On the name keyboard the joystick moves, the red button types
the letter you are on, *GAME SELECT* erases, and *GAME RESET* is done. Names
are up to eight letters and numbers.

== What You May See

#tbl((auto, 1fr),
  th[SCREEN SAYS], th[WHAT IS HAPPENING],
  [*LOADING*], [Fetching the list of tables.],
  [*NO SERVERS*], [No game has a table open just now. Try again later, or load a game yourself from the browser -- its own table list works without the Lobby.],
  [*JOINING*, *MOUNTING*], [Getting your game ready.],
  [*DO NOT STOP*], [Loading the game. Leave the console on.],
  [*ERR* and a number], [Something on the network did not answer. Press GAME RESET to try again.],
)

#note[Every FujiNet game in this booklet can also be loaded straight from the
browser (Section 8). Each shows its own list of tables, so you can play with
or without the Lobby.]
