# Battleship for the RCA Studio II

A CDP1802 client in Macroassembler AS, in the mould of 5 Card Stud's Studio II
port (`fujinet-5cardstud/studio2`, whose network, name and lobby code it
reuses), running over the FujiNet cartridge mailbox from
`fujinet-firmware/pico/studio2`. All four seats' boards are on the screen at
once, every hit, miss and hull of them.

The cart draws the screen. Every character is a hotspot read that the cart's
text engine renders into the 64x128 raster the 1861 fetches. The reply window
(`$E400`) is plain readable memory between transactions, so screens draw
straight out of it. Only the name, the table id and a few header bytes are
copied into RAM.

## Four boards on 160 cells

The text engine is 16x10 cells of 4 pixels by 12 scanlines, and four 10x10
boards are 400 squares. The 32 app glyphs cannot cover it: two squares by
three to a cell, each sea, hit, miss, hull or hit hull, is thousands of
combinations. So the cart gained an operation for this port:

- **`TOP_MOSAIC`** splits a cell into 2x3 squares of 2 pixels by 4 scanlines.
- **`TOP_TILE`** defines the 16 tiles a square can be.
- Both live in `pico/studio2/firmware/src/s2_text.c` on the firmware branch
  `studio2-mosaic`.

**Firmware requirement:** a cart, or the grafted MAME device, without that
branch draws every board blank.

`tiles.inc` defines the tiles; `board.inc` composes a board row, fifteen tile
pairs, into one `TOP_MOSAIC`. A square's tile is its gamefield byte ORed with
a mark from `MAP` (`$0900`): a hull, the cursor, or placement's ship. The
numbers line up so that one OR does it, and a board with no gamefield or no
marks reads a page of zeros instead. Redrawing all four boards is about 7,500
instructions, roughly 100 ms. The cursor blinks by redefining three tiles,
and the cart then redraws just those cells.

**The board look:**
- Each board is a lit panel. Black is a ship: a hit on an opponent, or our
  own hull.
- A hatched square is a hit on our hull.
- A dark dot is a miss.
- The cursor inverts its square.

With dark sea, the boards' edges vanished into the black around them. On a TV
a pixel is about three scanlines wide, so a square is a little wider than
tall. `make shot` shows it.

## The screen (16 x 10)

```
CLYDE HULK   :38     names over the boards; the player to move in inverse
#####·#####·YOUR     row 0 of each board: five fleet pips (afloat / sunk)
#####·#####·TURN     then the 10x10 field, then a blank square row
#####·#####·
#####·#####· HIT     the panel (columns 12-15): the clock, whose turn,
YOU   JIM            the last shot, the keys
#####·#####·2468
#####·#####· AIM
#####·#####·   5
#####·#####·FIRE
```

Seats sit where the C ports put them: us bottom-left, then clockwise from
top-left. An empty seat leaves its quadrant blank. At game over the panel
says `YOU WIN!` or `name WINS`, and the winner's fleet (v=2's
`myShips[5-9]`) appears on their board.

**The waiting room:** the server's name, the seats with `READY`, and the
server's prompt (`starting in 5`), which the cart scrolls when it runs long.

**Placement:** your board in its quadrant, with the keys and the other seats'
`OK` / `...` beside it.

## Keys

Either pad.

| Screen | Keys |
|---|---|
| Name | 2 4 6 8 move on the grid, 5 type, 1 delete, 3 done, 0 keep the old name |
| Tables | 1-8 join that table, 0 menu |
| Waiting room | 5 ready / unready (`/ready/1`, `/ready/0`, never the toggle), 0 menu |
| Placement | 2 4 6 8 move the blinking ship, 1 turn it, 5 keep it, 3 roll the rest again, 0 menu |
| Our turn | 1-9 move the cursor the way the keypad is laid out (diagonals too, wrapping), 5 fire, 0 menu |
| Menu | 1 or 0 back, 2 leave the table, 3 change name, 4 quit to CONFIG |

**Placement:**
- The fleet starts as a random legal roll, so five presses of 5 is a valid
  fleet.
- A move off the board is refused with a tone.
- A ship can pass over another (those squares buzz) but cannot be kept there.
  The server ignores an illegal placement without a word, so nothing illegal
  is sent.

**Firing:**
- One shot lands on every live opponent at once, so the one cursor is on all
  their boards.
- A square every live opponent has already had is refused with a tone.

## Transport

`net.inc` is 5 Card Stud's, as is. It carries the family's rules:
- CLOSE opens the next request.
- Take the reply length right after the READ.
- STATUS settles on two agreeing readings above a minimum.
- STATUS byte 3 must be 1.
- The length must match what `playerCount` and `status` imply.

**Expected lengths:**

| State | Length |
|---|---|
| Lobby | `59 + 10n` |
| Placement | `49 + 10n` (its records are name and status only) |
| Play and game over | `49 + 115n` |

**The settle minimum** is the shortest state that can follow the last good
one:
- Placement's after the lobby or placement.
- The lobby's after game over.
- Play's after play.

Using the exact last length, the first try, wedged every lobby-to-placement
change, because that reply is ten bytes shorter.

**Requests:**
- They are `state`, `ready/1`, `ready/0`, `place/a,b,c,d,e` and `attack/p`,
  each with `?table=&player=&bin=1&v=2`.
- A move's reply is the next state.
- `/leave` has no body, so leaving is OPEN plus one STATUS.

**Cues:**
- A 40-frame beep marks our turn, on the edge where `activePlayer` becomes 0.
- A shorter beep marks a hit or a sink, on a new `(status, lastAttackPos)`,
  anyone's shot.

**Polling:**

| When | Every |
|---|---|
| In play | 90 frames |
| Our turn | 240 frames, and when our clock runs out |
| Waiting room | 120 frames |
| Placing | 240 frames |
| Game over | 180 frames |
| After an error | 150 frames |

## Building

```sh
make                                     # == ./build.sh -> build/battleship.st2
ENDPOINT=http://127.0.0.1:8080/ make     # another server
make demo                                # DEMO=1: a canned four-seat game, no network
```

The build needs:
- `~/asl/asl`, or `asl` on PATH, or `ASL=`.
- The firmware tree (`FUJI_FIRMWARE`, default `~/Workspace/fujinet-firmware`)
  for `checkrom.py` and `mkst2.py`.

`build/endpoint.inc` and `build/flags.inc` are regenerated on every run, and
`tools/mkdemo.py` writes the demo state, as `util.go` would serialize it, to
`build/demo.inc`.

`src/fujinet.inc`, `s2macro.inc`, `s2call.inc`, `fujilib.inc`,
`fujidisp.inc` and `input.inc` are verbatim copies of the firmware tree's
`testrom/`. Copy them after `studio2-mosaic`: `fujinet.inc` has `TOP_TILE`
and `TOP_MOSAIC`.

## Size and RAM

**ROM:** about 8.5K in 42 of the 64 pages an ST2 may have:

| Range | Contents |
|---|---|
| `$0400-$077D` | The runtime |
| `$0C00` | Start-up, tiles, ui |
| `$1400` | Net, url, name |
| `$2400` | Lobby, menu, waiting room |
| `$3400` | The game |
| `$4400` | The boards, behind a page of tables |
| `$5400` | Placement, aiming |
| `$6400` | Text |
| `$7400` | The demo state, `DEMO=1` only |

There are no 3-cycle opcodes (`checkrom.py`).

**RAM:**

| Range | Contents |
|---|---|
| `$0800-$080F` | The runtime's |
| `$0810-$088F` | The client's variables (the ledger in `battleship.asm`), all on page `$08` |
| `$0900-$0963` | `MAP` |
| Down from `$09FF` | The stack, well clear of `MAP` |

`main` clears both pages.

## Test

```sh
make shot     # the demo: MAME headless, snapshots in build/snap, cell map on stdout
```

`emu/shot.lua` checks the names, the panel, that every board cell is a mosaic,
and that the cursor moves on 6 and 3.

```sh
cd ~/Workspace/servers/fujinet-game-system/battleship && go run . &     # :8080
cd ~/Workspace/fnpc-studio2 && ./run-fujinet -u 127.0.0.1:8037 -c fnconfig.ini -s SD &
ENDPOINT=http://127.0.0.1:8080/ make && make drive
```

`emu/bsdrive.lua` plays a whole game against the local server:
1. Types `S2TEST` on the grid when the appkey is empty.
2. Joins `AI - 3 BOTS`, a table with four seats.
3. Readies up.
4. Moves and turns the carrier, checking that our board's cells changed, then
   keeps the fleet.
5. Fires at the first open square in reading order on every turn, visiting
   the menu and coming back on the third.
6. After game over, leaves the table through the menu.

It passed at all three AI tables, with no net errors in any run:

| Table | Seats | Result |
|---|---|---|
| `AI - 1 ON 1` | 2 | 55 turns |
| `AI - 2 BOTS` | 3 | 32 turns |
| `AI - 3 BOTS` | 4 | 15 turns, from the waiting room through leaving |

One more run rejoined an `AI - 3 BOTS` game left mid-play.

It runs MAME throttled, since the server's clocks are real time.
`BS_TABLE`, `S2_NAME` and `BS_LIMIT` override the defaults.

MAME must have the cart from `studio2-mosaic`. Graft it with the firmware's
`pico/studio2/emu/apply.sh ~/Workspace/mame-studio2`, then
`make SUBTARGET=studio2 SOURCES=src/mame/rca/studio2.cpp REGENIE=1 NOWERROR=1`.

## Untested

- Spectating a full table.
- A seat leaving mid-game: the settle floor fails one poll, then recovers.
- The live server, `battleship.carr-designs.com`: every run above was against
  a local copy of it.
- A server-refused placement: it is never sent, but the client re-opens
  placement if it happens.
- No hardware exists yet.
