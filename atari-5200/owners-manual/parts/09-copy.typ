#import "../lib.typ": *

= Copying Games

FujiNet can copy a game from one host to another -- from the Internet to your
memory card, say, so that you can play it without a network.

#steps(
  [In the browser, move the bar to the game you want to copy and press
   #START.],
  [The host list comes back, asking #scr("COPY TO WHICH HOST?"). Move to the
   host to copy to -- *SD* for the memory card -- and press the bottom button
   (or #HASH).],
  [Open the folder the game should go in, as in the browser.],
  [Press #START to copy it there.],
)

#shots(("copy-to", [Step 2]), ("copy-here", [Step 3]), w: 1.72in)

The bottom line says #scr("COPYING...") while it works, and #scr("COPIED")
when it is done. Then you are back where you started, in the folder the game
came from. To change your mind, press #STAR: on the host list it cancels the
copy, and in the folders it backs up one, cancelling at the top.

If it says #scr("?COPY ERROR"), the memory card may be full or missing, or the
host may not let you write to it -- the Internet libraries, for one, are
read-only. Folders cannot be copied, only games, one at a time; a game’s
`.CFG` file (Section 8), if it has one, is copied the same way, on its own.
