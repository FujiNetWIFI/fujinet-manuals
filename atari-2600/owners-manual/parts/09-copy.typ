#import "../lib.typ": *

= Copying Games

FujiNet can copy a game from one host to another -- from the Internet to your
memory card, say, so that you can play it without a network.

#steps(
  [In the browser, move the *>* to the game you want to copy. Press *GAME
   SELECT* and choose *COPY*.],
  [The hosts screen comes back, titled *COPY TO*. Choose the host to copy to
   -- *SD* for the memory card -- and press the red button.],
  [Find the folder the game should go in. Press *GAME SELECT* and choose
   *COPY HERE*.],
)

#grid(columns: (1fr, 1fr, 1fr), column-gutter: 6pt,
  align(center, tvcap("copy-to", [Step B], size: 5.2pt)),
  align(center, tvcap("copying", [Copying], size: 5.2pt)),
  align(center, tvcap("copied", [Done], size: 5.2pt)),
)

*COPYING* shows where the game is coming from and where it is going. When it
says *COPIED*, press the red button (or wait a moment) to go back to the
browser. If it says *COPY FAILED*, the memory card may be full, or missing, or
the host may not let you write to it -- the Internet libraries, for one, are
read-only. A game's `.CFG` file, if it has one, is copied along with it.
