#import "../lib.typ": *

= Battleship

Two to four fleets on one ocean. Hide your five ships, then take turns firing
-- and every shot you fire lands on *every* enemy board at once. The last
fleet afloat wins.

== Loading the Game

Load it from the browser: host *apps.irata.online*, folder *ATARI-5200* #into
*FUJINET*, game *Battleship.a52*. Give your name if it asks. The list of games
shows each table and how many of its four seats are taken; the bottom line
greets you by name. The *AI* tables give you one, two or three robot
admirals; *Cape Fuji* and *High Seas* are for people. Move to a table and press
the bottom button to join.

#shots(("bs-tables", [The tables]), ("bs-place", [Hiding your ships]), w: 1.72in)

In the waiting room, press the bottom button when you are ready
(#scr("PRESS FIRE WHEN READY")). The game starts when everyone is ready.

== Hiding Your Ships

You have five ships, five, four, three, three and two squares long. The game
starts you with a fleet already laid out, so you can simply press the bottom
button five times to keep it. To move a ship instead:

#controls(title: [Placing ships], w: 1.05in,
  [#stick("udlr")], [Move the ship that is being placed.],
  [#TOP or #kp(1)], [Turn it. (The screen calls the top button
    #scr("LOWER FIRE").)],
  [#BOTTOM, #HASH \ or #START], [Leave it there and go on to the next ship.],
)

== Battle

#shot("bs-battle", [Battle: two fleets, your board at the bottom])

Every board is on the screen: yours at the bottom, marked #scr("YOU"), and
each enemy’s with its admiral’s name. Hits and misses are marked on the
boards, and each fleet’s ships stand beside its board, afloat or sunk. When it
is your turn, aim at any square and fire.

#controls(title: [In battle], w: 1.05in,
  [#stick("udlr")], [Aim.],
  [#BOTTOM, #HASH \ or #START], [Fire at that square, on every enemy board at
    once.],
  [#TOP or #kp(1)], [Ask the server now, instead of waiting.],
  [#PAUSE or #STAR], [The game menu: #kp(5) quit the game, #kp(2) how to
    play, #kp(3) sound on or off; the bottom button closes it.],
  [#kp(2), #kp(3), #kp(4)], [How to play, sound, your name.],
)

You have about *45 seconds* a turn. A square you have already fired at on
every board is refused, so you cannot waste a shot. The last fleet with a ship
afloat wins.

To leave, open the game menu and press #kp(5). At the list of games, #kp(5)
leaves Battleship for the Lobby (Section 11).
