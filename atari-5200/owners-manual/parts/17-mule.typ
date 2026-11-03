#import "../lib.typ": *

= M.U.L.E.

The classic game of settling the planet Irata, for four colonists on any
FujiNet machine at all -- the other three may be on an Atari computer, a 7800,
an Apple, a PC or a 2600, and the computer takes any empty seat. Twelve months
to claim land, outfit your M.U.L.E.s, and trade your way to the richest
colony.

#shots(("mule-title", [The title]), ("mule-develop-map", [The map]), w: 1.72in)

== Loading the Game

Load it from the browser: host *apps.irata.online*, folder *mule* #into
*atari5200*, game *mule.a52* -- a 128K Super Cart. On the title screen press
the bottom button, give your name if it asks, and pick a table
(#scr("UP/DOWN, FIRE")); *Planet IRATA* is the public colony. In the colony
room, choose your species with the joystick and press the bottom button when
you are ready.

#shots(("mule-lobby", [The colony room]), ("mule-develop-town", [The town]), w: 1.72in)

#controls(title: [M.U.L.E.], w: 1.05in,
  [#stick("udlr")], [Walk; choose; move your auction line; declare.],
  [#BOTTOM], [Start, join and ready; claim a plot; begin your turn; install a
    M.U.L.E.; and every other “press the button” of the game.],
  [#START], [End your turn. On the name screen, done.],
  [#TOP], [On the name screen, rub out a letter.],
  [#kp(0)], [Sit out a declaration.],
  [#HASH], [Sound off and on.],
  [#STAR], [Leave the table: press it twice (#scr("LEAVE GAME? * AGAIN:
    YES")). The computer takes over your colonist. At the table list,
    #STAR goes back to the FujiNet menu.],
)

#rules[The whole game -- the colonists, the land, every phase of a month, the
auctions, every fortune and catastrophe -- is in the _M.U.L.E. Player’s
Guide_ from the FujiNet project. The 5200 plays like its Atari computer
edition.]
