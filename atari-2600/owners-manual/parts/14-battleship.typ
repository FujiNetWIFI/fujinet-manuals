#import "../lib.typ": *

#pagebreak(weak: true)
= Battleship

Two to four fleets on one ocean. Hide your five ships, then take turns firing
-- and every shot you fire lands on *every* enemy board at once. The last
fleet afloat wins.

== Loading the Game

Choose a Battleship table in the Lobby, or load it from the browser: host
*apps.irata.online*, folder *Atari_2600*, game *BATTLESHIP.BIN*. Give your name
if it asks (*YOUR NAME*: the red button types, *OK* finishes). The table list
shows each table and how many *SEATS* are taken; *FIRE JOINS*. The *AI* tables
give you one, two or three robot admirals; *Cape Fuji* and *High Seas* are for
people.

#shots(("bs-tables", [The tables]), ("bs-waiting", [Waiting to start]),
  ("bs-play2", [Two fleets]), h: 1.05in)

In the waiting room, press the red button when you are *ready*. The game
starts when everyone is ready, or about thirty seconds after the first player
sits down.

== Hiding Your Ships

You have five ships, five, four, three, three and two squares long. The game
starts you with a fleet already laid out, so you can simply press the red
button five times to keep it. To move a ship instead:

#grid(columns: (auto, 1fr), column-gutter: 12pt, align: (left + top, left + top),
  shot("bs-place", h: 1.25in),
  [
    #set text(size: 8.6pt)
    *PLACE SHIP* and the number of the ship you are placing are at the top;
    your ships are outlined in gold on your own board. The hints at the
    bottom say *SEL TURNS* and *FIRE PLACES*.
  ],
)

#controls(title: [Placing ships -- PLACE SHIP],
  [Joystick], [Move the ship that is being placed.],
  [#SELECT], [Turn it (*SEL TURNS*).],
  [#FIRE], [Leave it there and go on to the next ship (*FIRE PLACES*).],
)

A ship that would hang off the edge says *WON'T FIT*; one that would sit on
another says *SHIPS TOUCH*. Move it and try again.

== Battle

#grid(columns: (auto, 1fr), column-gutter: 12pt, align: (left + top, left + top),
  shot("bs-play4", w: 1.45in),
  [
    Every board is on the screen. With two players there are two big boards;
    with three or four, four boards -- yours at the bottom left, the others
    going round clockwise. *Gold* marks your ships and your aim, a *red*
    square with a white middle is a hit, and a *white* dash is a miss. Under
    the boards, each fleet's ships show as *\#* while afloat and *=* when
    sunk.

    The top line tells you what happened last, whose turn it is, and the
    seconds you have left -- *MISS YOU 45*, *HIT ENEMY*, *SUNK YOU 12* -- and
    finally *YOU WIN!* or the winner's name.
  ],
)

#controls(title: [In battle],
  [Joystick], [Aim.],
  [#FIRE], [Fire at that square, on every enemy board at once.],
  [#SELECT], [Ask the server now, instead of waiting.],
  [#RESET], [The *GAME MENU*: *RESUME*, *HOW TO PLAY*, or *LEAVE TABLE*.],
)

You have *45 seconds* a turn. A square you have already fired at on every
board is refused with a buzz, so you cannot waste a shot.
