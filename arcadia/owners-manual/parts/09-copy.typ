#import "../lib.typ": *

= Copying Games

FujiNet can copy a game from one host to another -- from the Internet to your
memory card, say, so that you can play it without a network.

#steps(
  [In the browser, move the bar to the game you want to copy and press
   #kp(5).],
  [The list of hosts comes back, titled #scr("COPY TO HOST"), with the game’s
   name under it. Move to the host to copy to -- *SD* for the memory card --
   and press the Action button.],
  [Open the folder the game should go in, as in the browser.],
  [Press #kp(5) to copy it there.],
)

#shots(("copy-to", [Step 2]), ("copy-here", [Step 3]), w: 2.45in,
  caption: [Copying a game to the memory card])

The message line says #scr("COPYING") while it works, and #scr("COPIED")
when it is done. Then you are back where you started, in the folder the game
came from. To change your mind, press #CLEAR: it cancels the copy.

If it says #scr("COPY FAILED"), the memory card may be full or missing, or
the host may not let you write to it -- the Internet libraries, for one, are
read-only. Folders cannot be copied (#scr("FILES ONLY")), only games, one at a
time. A small settings file kept beside a game, with the same name ending in
`.CFG`, is copied with it; CONFIG does not list those files.
