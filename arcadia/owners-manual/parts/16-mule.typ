#import "../lib.typ": *

#booklet.update(true)
#bandfile.update(("apps.irata.online", "MULE/ARCADIA/mule.bin"))
= M.U.L.E.
#show enum: set par(leading: 1.05em)

== General

The classic game of settling the planet Irata, for four colonists on any
FujiNet machine at all -- the other three may be on an Atari, an Apple, a PC
or another ARCADIA-2001, and the computer takes any empty seat. Twelve months
to claim land, outfit your M.U.L.E.s, and trade your way to the richest
colony.

#shots(("mule-title", [The title]), ("mule-develop-map", [The map]), w: 2.45in)

#steps(
  [In the browser, open *APPS.IRATA.ONLINE*, then *MULE*, then *ARCADIA*,
   and choose *MULE.BIN*. At 51,200 bytes it is the largest program the
   cartridge plays (Section 3).],
  [Give your name: the disc up and down picks a letter, right takes it, left
   rubs it out; #ENTER or the console’s START when you are done.],
  [Choose a table (#scr("DISC, THEN FIRE")). In the colony room, choose your
   species with the disc and press the Action button when you are ready.],
)

#note[If M.U.L.E. says it #scr("NEEDS A FUJINET") #scr("CART, PROTO 2."), the
cartridge’s firmware is older than the game. Bring it up to date (Section 19).]

== To Play the Game

M.U.L.E. is the one FujiNet game that uses the console’s own buttons, too.

#shots(("mule-land-grant", [The land grant]), ("mule-develop-town", [The town]),
  w: 2.45in)

#controls(title: [M.U.L.E.], w: 1.35in,
  [#disc("udlr")], [Walk; choose; move your line in an auction; up to sell,
    down to buy.],
  [#FIRE or #kp(2)], [Join and ready; claim a plot; begin your turn; install
    a M.U.L.E.; and every other “press the button” of the game.],
  [#START], [End your turn. On the name screen, done.],
  [#OPTION], [Leave the table (in a game it asks first: press OPTION again).
    The computer takes over your colonist.],
  [#SELECT], [Sound off and on.],
  [#kp(0)], [Sit out a declaration.],
  [#CLEAR], [On the name screen, rub out a letter.],
)

#rules[The whole game -- the colonists, the land, every phase of a month, the
auctions, every fortune and catastrophe -- is in the _M.U.L.E. Player’s
Guide_ from the FujiNet project.]
