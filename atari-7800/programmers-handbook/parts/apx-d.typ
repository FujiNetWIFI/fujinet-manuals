#import "../lib.typ": *
#set heading(numbering: "A.1")
= Battleship Listing

The 7800 layer of Fuji Battleship, `src/atari7800/` at the game’s commit `87b8cc7`, in the order Section 20 discusses it. The shared game (`src/main.c`, `gamelogic.c`, `screens.c`, `misc.c`, `stateclient.c`) is every port’s and is not printed; the tile engine is in Section 15.

#listing2("fujinet.c", "listings/battleship/src/atari7800/fujinet.c")
#listing2("vars.h", "listings/battleship/src/atari7800/vars.h")
#listing2("graphics.c", "listings/battleship/src/atari7800/graphics.c")
#listing2("input.c", "listings/battleship/src/atari7800/input.c")
#listing2("pad.h", "listings/battleship/src/atari7800/pad.h")
#listing2("osk.c", "listings/battleship/src/atari7800/osk.c")
#listing2("sound.c", "listings/battleship/src/atari7800/sound.c")
#listing2("util.c", "listings/battleship/src/atari7800/util.c")
#listing2("tiles.h", "listings/battleship/src/atari7800/tiles.h")
#listing2("mkchr.py", "listings/battleship/src/atari7800/mkchr.py")
#listing2("maria.h", "listings/battleship/src/atari7800/maria.h")
#listing2("maria.s", "listings/battleship/src/atari7800/maria.s")
