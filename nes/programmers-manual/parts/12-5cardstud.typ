#import "../lib.typ": *

= Game One: 5 Card Stud

#lead[Five-card stud poker against bots, or against anybody else on the
Internet who sits down at the same table. The NES version is the same game
that runs on the Atari, the Apple II, the CoCo and a dozen more, with a
thousand lines of NES underneath.]

#shots("fcs-1", "fcs-2", "fcs-3", w: 1.95in, caption: [Choosing a table; the
deal; a few seconds later, waiting on Fry Bot. Taken against the live
server.])

#objbox("Object of the game / Game description")[Every client polls one web
server for the state of its table, draws it, and sends the player's move. The
server deals the cards, runs the bots, keeps the time and decides who won.
All the client has to do is ask, draw and answer -- which on the NES means
ask through the mailbox, draw through the PPU queue, and answer with the
pad.]

== The shape of the client

The game lives in `fujinet-5cardstud` (cc65 C). The shared code in `src/` --
`main.c`, `screens.c`, `gamelogic.c`, `stateclient.c` -- is the same on
every computer. Each platform supplies a directory of its own that implements
a fixed set of functions; for the NES that is `src/nes/`:

#tbl((auto, auto, 1fr),
  th[File], th[Lines], th[What it provides],
  [`graphics.c`], [575], [`initGraphics`, `drawCard`, `drawText`, `drawChip`, `resetScreen` and the rest: the table, in tiles],
  [`ppu.s`], [23], [`ppu_put`: one queued PPU write (Listing 10)],
  [`network.c`], [36], [`getResponse`: one HTTP GET (Listing 9)],
  [`appkey.c`], [35], [`read_appkey`, `write_appkey`],
  [`input.c`], [79], [`readJoystick`, `getPlatformKey`: the pad (Listing 11)],
  [`osk.c`], [227], [`platformNameEntry`: the on-screen keyboard (Listing 14)],
  [`sound.c`], [143], [the beeps (Listing 13)],
  [`util.c`], [141], [the timer, and `quit` to the Lobby (Listing 12)],
  [`mkchr.py`], [152], [generates `chr.s` and `tiles.h`, the tile set],
  [`nes.cfg`], [66], [the linker configuration],
)

`main()` loads the player's preferences from an app key, sets up the screen
and the sound, shows the welcome and table screens, and then goes round one
loop for the rest of the game: get the state from the server, draw it, and if
it is the player's turn, ask for a move.

== Memory

The build is plain NROM -- 32K of PRG, 8K of CHR ROM -- linked with a copy of
fujinet-lib's `nes-fujinet.cfg` that splits the CHR in two:

#excerpt-at("src/nes/nes.cfg", "listings/games/5cardstud/nes.cfg",
  "    # 8k CHR Bank", to: "SEGMENTS", size: 6.6pt)

cc65's console font has to be linked whether the game uses it or not, so it
gets `$0000`; the game's 233 tiles get `$1000`, and `initGraphics()` points
the background there. All the game's data -- its state, a 768-byte copy of
the screen, its buffers -- lives in the cartridge's 8K at `$6000`.

== One request, one GET

The NES half of the network code is one function:

#wholefile("src/nes/network.c", "listings/games/5cardstud/network.c")

Every poll is an OPEN, a READ and a CLOSE. Mode 12, `OPEN_MODE_HTTP_GET_H`, is
a GET; `network_read()` loops until it has the whole reply or the server is
done. The reply lands in `clientState` in the cartridge's work RAM.

The URL is put together by the shared `apiCall()` from the server's address,
the path -- `tables`, `state`, `move/CA`, `leave` -- the table and the
player's name, and `bin=1`:

#codepanel("A poll, and a call",
"N:https://5card.carr-designs.com/state?table=ai2&player=THOM&bin=1
N:https://5card.carr-designs.com/move/CA?table=ai2&player=THOM&bin=1")

== What comes back

`bin=1` asks for the state as packed binary, laid out exactly as the C
structures the client reads it into -- fixed-length strings padded with NULs,
numbers low byte first, which suits a 6502:

#tbl((auto, auto, 1fr),
  th[Offset], th[Bytes], th[Field],
  [0], [81], [`lastResult`: what just happened],
  [81], [1], [`round`: 0 no game, 1-4 betting, 5 showdown],
  [82], [2], [`pot`],
  [84], [1], [`activePlayer`: 0 is you, -1 nobody],
  [85], [1], [`moveTime`: seconds left, on your turn],
  [86], [1], [`viewing`: 1 if you are only watching],
  [87], [1], [`validMoveCount`],
  [88], [65], [`validMoves[5]`: a move code (3) and its name (10)],
  [153], [1], [`playerCount`],
  [154], [33 each], [`players`: name (9), status, bet (2), move (8), purse (2), hand (11)],
)

Only the seated players are sent, so a reply is 154 + 33 bytes per player.
The server turns the table around so that you are always player 0. A hand is
two characters a card -- rank then suit, `kd` for the king of diamonds, `??`
for a card face down. The strings arrive in lower case; the NES font has only
capitals, so `textGlyph()` folds them.

== Drawing without a frame buffer

The shared code was written for computers that can read their screens back.
The NES cannot read the nametable while it is drawing, so the NES layer keeps
its own copy -- `shadow`, one glyph per cell -- and draws through it:

#excerpt-at("src/nes/graphics.c: put", "listings/games/5cardstud/graphics.c",
  "static void put(unsigned char x", to: "/* Fold to the font", size: 6.8pt)

The glyph goes in the shadow, where the card-drawing code can ask what is
already there; the tile, which carries its colour, goes to the PPU queue.
`ppu_put()` (Listing 10) is nine instructions of assembly that hand the
address and value to cc65's `ppubuf_put` in the registers it wants.

Colour is the harder part. Each 16×16-pixel block of the screen has one
palette, chosen by two bits of an attribute byte, so greying the player's own
hole card means rewriting attribute bits:

#excerpt-at("src/nes/graphics.c: setBlockPalette", "listings/games/5cardstud/graphics.c",
  "static void setBlockPalette", to: "/* Grey (or not)", size: 6.8pt)

Only an even column lines up with the attribute grid, so seat 0 sits on one.

== Your turn

The pad goes through cc65's joystick driver. Every *button* is reported as a
key -- A is Return, B is Escape -- so that all of them pass through one edge
detector (Listing 11 #co(5)). Start and Select report on *release*, so the
code can tell either one alone from both together: Select plus Start leaves
the table for the Lobby.

When it is your turn, the status line shows the moves the server allows; the
pad moves an underline between them and A sends `move/` and the move's code.

== The server

The server is Go, in `servers/fujinet-game-system/5cardstud/server`. It keeps
every table in memory, each behind its own lock. A request copies the table,
works on the copy, and saves it only if nothing went wrong.

The game moves forward only when somebody asks: each `/state` request runs the
game logic -- deal, time out a slow player, let a bot move -- before it answers.
A human has 39 seconds to move; a bot takes 3. Tables `ai2`, `ai4` and `ai6`
seat two, four and six bots; `den` and `basement` start empty.

== Leaving for the Lobby

`quit()` (Listing 12) is how every FujiNet game on the NES goes back to the
FujiNet Lobby: find the host slot named `ec.tnfs.io`, mount `nes/lobby.nes`
from it, and boot it (Listing 12 #co(6)).

#note[The comment in `quit()` says the image is pushed after MOUNT_IMAGE has
been answered. It is not: MOUNT_IMAGE answers only once the image has arrived
(Chapter 8), so the percentage loop that follows sees READY at once. And at
the time of writing there is no NES Lobby image on `ec.tnfs.io` yet.]
