#import "../lib.typ": *

= The Game Lobby

The *FujiNet Game Lobby* is a list of every network game that has a table open
right now, on every kind of computer and console FujiNet works with. Pick a
table and the Lobby loads the right game for your ARCADIA-2001 and sends you
to it.

To open the Lobby, press #kp(9) on FujiNet hosts. CONFIG says
#scr("GAME LOBBY"), looks for the Lobby’s host, *ec.tnfs.io*, among your
hosts -- putting it in host 8 if it is not there -- and loads the Lobby from
it, as it loads any game.

#note[The ARCADIA-2001’s Lobby is being finished now, and is not yet on
ec.tnfs.io. Until it is, load the network games from the browser, as
Section 8 shows: each has its own list of tables, and they work just the same
without the Lobby.]

== Your Name

The first time, the Lobby asks #scr("YOUR NAME") on the character grid
(Section 6): two to eight letters and numbers (#scr("USE 2-8 A-Z 0-9")).
Press #ENTER, and the Lobby remembers it.

#shots(("lobby-name", [Your name]), ("lobby-list", [The rooms]), w: 2.45in,
  caption: [The Game Lobby])

== The Rooms

#scr("LOADING ROOMS"), then the open tables, six to a page, under each game’s
name, with how many of their seats are taken. The bottom line takes turns
telling you the buttons.

#controls(title: [In the Lobby],
  [#disc("ud") or #kp(8)], [Move from table to table. Past either end, turn
    the page.],
  [#disc("lr") or \ #kp(4) #kp(6)], [Turn the page.],
  [#FIRE or #ENTER], [Join the table the bar is on: the Lobby loads the
    game (#scr("JOINING")).],
  [#kp(0)], [Fetch the list again, from the first page.],
  [#CLEAR], [Change your name.],
)

The *AI Rooms* seat you with robot players, the best way to learn a game;
the others are for people, playing on an ARCADIA-2001, an Atari, an Apple, a
PC or anything else FujiNet plugs into. If none are open the Lobby says
#scr("NO ROOMS OPEN"); press #kp(0) to look again.
