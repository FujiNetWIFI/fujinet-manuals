#import "../lib.typ": *
= Battleship

#ini[F]uji Battleship is a networked game for up to four players, with bots to fill the empty seats, and it runs on every computer FujiNet serves. Its 7800 port is merged into the game’s repository, and it is the best example there is of a C program on the FujiNet cartridge: one shared game, written once, and a thin 7800 layer underneath that draws, reads the stick, makes the noises, and talks to the cartridge through fujinet-lib.

This section walks through the port at the game’s commit `87b8cc7`. Appendix D prints its 7800 files.

#fig(grid(columns: 3, column-gutter: 6pt,
  tvframe("images/screens/bs-ready.png", 1.2in),
  tvframe("images/screens/bs-place.png", 1.2in),
  tvframe("images/screens/bs-game.png", 1.2in)),
  caption: [At a table with three bots, all ready; placing the five ships; a game under way, four boards, attacks marked in red.])

#sect[Controls]

#tbl((auto, 1fr),
  th[Input], th[Does],
  [Joystick], [Moves the cursor.],
  [Button 1], [Ready, place, attack: the RETURN of the other ports.],
  [Button 2 or RESET], [Rotates a ship while placing.],
  [PAUSE], [The in-game menu.],
  [SELECT with button 1, button 2, PAUSE], [Help, sound on or off, quit to the lobby.],
)

A 2600 joystick works too: its one button is button 1, and RESET stands in for button 2. The buttons reach the shared code as key codes behind `kbhit()` and `cgetc()`, exactly as a keyboard’s would.

#sect[What is shared and what is the 7800’s]

#tbl((1.45in, auto, 1fr),
  th[File], th[Lines], th[What it does],
  [`src/main.c`, `gamelogic.c`, `screens.c`, `misc.c`, `stateclient.c`], [1846], [The game: every port’s. Screens, rules, the polling loop, the server calls.],
  [`src/atari7800/graphics.c`], [675], [The screen, on the tile engine.],
  [`src/atari7800/osk.c`], [226], [The on-screen keyboard for the player’s name.],
  [`src/atari7800/sound.c`], [243], [The sound effects, on the POKEY.],
  [`src/atari7800/fujinet.c`], [170], [Every call to the cartridge.],
  [`src/atari7800/input.c`, `util.c`], [193], [The stick, the switches, timing.],
  [`src/atari7800/maria.s`, `maria.h`], [607], [The tile engine (Section 15), verbatim.],
  [`src/atari7800/mkchr.py`], [—], [The tiles, from the MS-DOS client’s art.],
)

#sect[Talking to the cartridge]

Everything that reaches the cartridge is in `fujinet.c`. On the 7800, most `fuji_*` calls are macros over the library’s bus call, so the shared code’s own declarations of them would link against nothing; the game is built with `CUSTOM_FUJINET_CALLS`, and the shared code calls three hooks this file supplies. The network hook is one HTTP request, start to finish:

#ex((path: "listings/battleship/src/atari7800/fujinet.c", from: "int16_t custom_network_call", to: "uint16_t custom_read_appkey"), t-c)

`mt_sync()` first shows whatever was just drawn, because the transaction holds the 6502 for as long as the server takes, and a palette change waits for a frame.

#sect[The URL and the state]

The game never parses anything. The shared `apiCall()` builds the request — `n:`, the server, a path such as `state`, the player and table, and `bin=1` — and the server answers with the whole game as a C structure in binary:

#ex((path: "listings/battleship/src/stateclient.c", from: "    strcpy(url, \"n:\");", to: "    // Allow platform"), t-c)

The `Game` structure is 509 bytes: the prompt, whose turn it is, and each of four players’ name, status, 100-square field and ships left. One READ brings all of it into the reply window and fujinet-lib copies it into `clientState`; a 1K window holds it with room to spare. The game polls this way every second or so and redraws what changed.

#sect[Which server]

The FujiNet Lobby leaves the game a server and a table in appkey 1:1:5 (`http://server/?table=t`), and the player’s name in 1:1:0. Without the Lobby, the game uses the public server. The game’s own preferences live in appkey `$E41C`:5:0, and a first byte of `$FF` there points it at `http://127.0.0.1:8080/`, a server on the same computer. The screens above came from the server in `fujinet-game-system/battleship`, run locally with `go run .`, with the Lobby key set to its `ai3` table.

#sect[The board]

Four players’ boards fill the 32 × 24 tiles, a quadrant each, with a legend of ships at the sides. The art is the MS-DOS client’s, converted by `mkchr.py`, which fits it into 128 tiles by letting the tile engine’s two palettes do what the NES port did with extra sets of glyphs:

#ex((path: "listings/battleship/src/atari7800/mkchr.py", from: "  palette 0  1 white", to: "The font sits"), "PYTHON")

The cost of a palette change is a run in the row’s display list, and a row holds at most twelve (Section 15). So `graphics.c` keeps runs long: text sets its whole string to one palette, white-only art leaves a cell’s palette alone, and `drawBoard()` turns the fields to the art palette before anything is drawn in them. The busiest rows in a four-player game have seven runs.

#sect[Sound]

`sound.c` plays the same cues as the other ports through the cartridge’s POKEY, never the TIA. Tones join channels 1 and 2 into one 16-bit channel clocked at 1.79 MHz, which reaches every note of the table exactly; explosions sweep channels 3 and 4 joined the same way, with a noise burst on channel 1.

#sect[Back to the Lobby]

Quitting a game boots the FujiNet Lobby, the way CONFIG would: find the lobby’s host among the host slots, mount `/atari7800/lobby.a78`, watch the push, and hand the console to the loader:

#ex((path: "listings/battleship/src/atari7800/fujinet.c", from: "    if (!fuji_mount_host_slot(slot)", to: "#endif"), t-c)

#note[At the time of writing the Lobby has no 7800 client on its host, so “LOBBY NOT AVAILABLE” is what a player sees. The code is ready for the day it does.]

#sect[Building and testing it]

```
make PLATFORMS=atari7800 atari7800 FUJINET_LIB=~/fujinet-lib-experimental
```

writes `r2r/atari7800/fbs.a78`, running `mkchr.py` first. The game’s `support/atari7800/smoke.lua` reads the screen out of the tile engine’s map and drives the game with a script of button presses; `emu/bssmoke.lua` is a copy. A game server counts real seconds, so a run against one must not be sped up: the handbook’s `emu/run.sh` takes `THROTTLE=1` for that.

```
THROTTLE=1 FBS_TILEMAP=support/atari7800/tilemap.lua \
  FBS_MAPFILE=r2r/atari7800/fbs.map \
  FBS_SCRIPT=wait2,fire,wait12,show,fire,fire,fire,fire,fire,wait6,show \
  emu/run.sh r2r/atari7800/fbs.a78 bssmoke
```
