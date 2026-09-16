# Battleship for the Atari 2600

A 6502 client for the [Battleship server](https://battleship.carr-designs.com/),
running over the FujiNet cartridge mailbox from the 2600 bring-up at
`fujinet-firmware/pico/atari-2600`, in the `?bin=1&v=2` wire format the
Intellivision, Astrocade, Arcadia and Channel F ports share.

**Every board on screen at once, in colour.** Up to four 10x10 boards as
coloured cells -- blue water, red hits, white misses, gold brackets for your
own hulls and for the cursor, and a gold strip of pips under each pair saying
which of that seat's five ships are still afloat -- on a console with 128
bytes of RAM, no framebuffer, and a playfield that has exactly one colour per
scanline.

```sh
make                       # build/battleship.bin, 16384 bytes
make layout                # the screen with no network at all
make shot                  # ...snapshotted and read back, cell by cell
make run                   # in a window
make drive                 # headless: a game against the live server (AI1)
make drive4                # ...at the four-seat table (AI3)
make frames                # every frame across a whole game must be 262 lines
make frames4               # ...at four seats, where the kernel has no slack
make resetleave            # the RESET switch: menu, LEAVE, back to the list
make resettest             # a 6507 restart mid-game
make sounds                # the cues, logged as they fire
make hosttest              # the cartridge's playfield composer, byte for byte
```

`build.sh` needs Macroassembler AS and the firmware tree; `run.sh` needs a
MAME with `pico/atari-2600/emu/apply.sh` applied and a fujinet-pc listening.

## The screen

```
 YOUR TURN 45         the status row, synthesised (see below)
 BOB   >      ALICE   names over the pair: left owner, a marker each, right
 ###==    #####       each seat's fleet: '#' afloat, '=' sunk. Gold, and
 +-----------+-----------+    three scanlines tall, not five
 |           |           |   board pair A, 80 lines: two 10x10 boards of
 |    Q1     |    Q2     |   8x8-pixel cells, abutting at pixel 80 with a
 |           |           |   two-clock black missile down the seam
 +-----------+-----------+
 YOU          CAROL
 #####    ##===
 +-----------+-----------+
 |    Q0     |    Q3     |   pair B
 +-----------+-----------+
```

Three or four seats use the family's quadrant convention: you bottom-left,
the others clockwise from top-left. **Two seats -- the AI1 table, the common
case -- get one pair of 8x12 cells, which is square on a 4:3 set, and the
lower half becomes text**: the server's prompt in full, each fleet as pips
(`#` afloat, `=` sunk), and a hint.

### The fleet strips

`shipsLeft[5]` is one byte a ship in every player's record, and until these
strips existed the quadrant layout threw all of it away: the pips were in the
two-seat layout's lower rows and nowhere else, so at a three- or four-seat
table nothing on screen said which ships had gone down, or how many.

The strips are text rows 3 and 4 -- free all along, blanked on a screen change
and never rendered -- under the name row of each pair, six columns a seat: a
space and five pips, so the right-hand seat's land in columns 7-11 and column
7 starts at clock 80, the board seam. Each seat's fleet sits over its own
half.

**They are three ink lines, not five, because that is what the frame could
pay for** (see below), and the font survives the clip: it is a 3x5 glyph, so
`'#'` keeps `{5,7,5}` and `'='` keeps `{0,7,0}` -- a hash and a bar. Digits
would not: clipped to three rows `'8'` and `'9'` are both `{7,5,7}`, which is
why a ships-left count was the wrong answer here and pips were the right one.

### How a playfield with one colour per line shows three colours per board

A cell is two playfield bits -- eight pixels -- so two boards side by side
are the whole 40-bit asymmetric playfield, rewritten twice a scanline. The
colour is decided **by line within the cell**: each line of the cell draws
a different table in a different colour.

```
 line 0    AUX  gold     your hulls; the cursor on the enemy boards
 line 1-2  HIT  red      a hit: the top of the block
 line 3-4  MID  white    hit OR miss: a hit's white core, a miss's dash
 line 5-6  HIT  red      the bottom of the block
 line 7    AUX  gold
```

So a hit is a red block with a white core, a miss is a white dash, and a
hull or the cursor is a pair of gold bars above and below the cell -- a
bracket that never hides what is under it, which is why the cursor does not
blink. A shot lands on every live enemy at once (the rule this game does not
share with the board game), so the same bracket is on every live enemy
board.

The tables are **composed by the cartridge**. Six 20-byte tables per kind
-- one per playfield register, one entry per cell row -- live in the text
plane region the cartridge already publishes, between text rows 4 and 15,
and four transforms the cartridge grew for this client fill them straight
out of the reply window: `FN_BLIT_PFIELD` (a gamefield's 100 cells to HIT
and MID), `FN_BLIT_PFHULL` (five placements to AUX), `FN_BLIT_PFCELL` (one
cell: the cursor, a pending hull) and `FN_BLIT_PFCLR`. Doing that on the
console would be four hundred reads through a 16-bit reply cursor in a bank
that has not got the bytes, into RAM it has not got at all. The console's
part is `lda table,y / sta PFn` eighteen times a line on a cycle-exact
schedule -- `dispgame.inc` has the windows.

### Every frame is 262 lines

The blanked bands are timed with the RIOT timer, as in the 5 Card Stud
port, and so is the **visible** band: the kernel's own lines add up to less
than 192 and a timed pad at the bottom absorbs the difference, so an
overrun moves nothing.

The quadrant layout's 192 now go like this, and there is no slack left in
them:

```
  1  the unblank line
  6  status row        (text row 0: five ink lines and a seam)
  6  names over pair A (text row 1)
  3  fleet strip       (text row 3)
  1  the strip's seam, WHICH IS ALSO the board's lead-in
 80  board pair A
  1  lead-out
  2  gap
  6  names over pair B (text row 2)
  3  fleet strip       (text row 4)
  1  seam and lead-in
 80  board pair B
  1  lead-out
  1  timed pad
```

The strips cost six lines and the gap and the pad paid for them: the gap was
seven and the pad four before. Three of those six came from **merging the
strip's seam line into the board's lead-in**, which is free because the two
lines want the same thing at different deadlines. A text row's seam blanks
the sprites; a lead-in blanks them too, and turns the water on and the
divider on. One line does all of it -- but the ORDER is not taste: `COLUBK`
must be written before pixel 0 at cycle 22.67, and the sprites only have to
be gone before the text block at clock 52, which is cycle 39. Blanking first,
as `LEADIN` does where it is free, puts the water in four clocks late and
leaves a black sliver down the left of that line.

That merge is why `TINK5` is now a wrapper: `TINKN` draws A ink lines and
hands the seam line to its caller **without** blanking, `TINK5` is `TINKN`
plus the blanking every other row wants, and `PIPROW` is `TINKN` plus the
lead-in. The twelve cycles the extra `jsr`/`rts` costs come out of a line
that has fifty-seven spare.

A network poll does not blank the screen and does not shudder. Four
things make that true:

- The network bank carries the board kernel and spends every wait for the
  cartridge drawing a frame out of the tables it is still holding
  (`NFRAME`, `NPGO`).
- **The overscan is waited out at the START of the next frame, not the end
  of the one before.** `DFRAME2` arms the timer and returns; `DFRAME` waits
  on it. So whatever a bank does between two frames -- stream a URL into
  the TX page, recompose the boards, switch banks -- is spent inside the
  overscan and moves nothing, as long as it fits in thirty lines. With the
  wait at the end, all of that landed between the overscan and the next
  VSYNC: a played game measured 96 frames in 2,400 that were 273 to 310
  lines, and every one was a transaction's setup or a recompose.
- **A switch INTO a frame is taken inside the vblank hook, and the bank
  entered finishes the frame** (`DFRAME2`, the kernel's second half). The
  RIOT timer does not care which bank is mapped. A switch that started a
  fresh frame from the hook would throw a 40-line frame at the set.
- **The transport draws one frame after every launch before its first look
  at the acknowledgement.** In emulation the cartridge answers inside the
  commit, so without that a whole transaction and the next one's setup --
  a URL streamed a character at a time -- piled into one overscan.
- **A poll's recompose is two passes**, in a bank of its own: the cue
  edges and the four boards between frames, in the overscan; the text a
  frame later, in the vblank the game bank's hook hands over from, and only
  the rows a poll can change -- the status row, the fleets, and the two
  turn-marker cells of each name row through `FN_BLIT_TCELL`. A screen
  change (a phase change, the menu closing) is three passes more: the rows
  blanked, the status and the names, the lower rows.

`make frames` histograms VSYNC-to-VSYNC across a played game and prints any
frame that is not 262 lines; `emu/banktime.lua` says where a long one went,
in scanlines, by bank switch.

### The status row

The server's prompt is empty for the whole of play, deliberately, so the
row is synthesised: `MISS YOU  45` / `HIT  ENEMY` / `SUNK YOU  12` -- the
last result, whose turn, and your clock, which counts down locally and polls
when it runs out (the server has moved on by then). The lobby shows the
server's own countdown; game over says `YOU WIN!` or `ALICE WINS`.

## Controls

| | lobby | placement | in play |
|---|---|---|---|
| stick | -- | move the ship | move the cursor |
| FIRE | ready up (a toggle) | keep the ship where it is, or where you moved it | attack that cell |
| SELECT | poll now | rotate | poll now |
| RESET | | the menu | **the menu: resume, how to play, leave** |

**The placement screen opens on a fleet, not on an empty board.** Five random
legal placements are rolled, the whole fleet is drawn, and the stick moves
whichever ship's turn it is FROM WHERE THE ROLL PUT IT; five presses of FIRE
accept the roll as it stands. That is the family's model -- Channel F,
Arcadia, Astrocade and the shared C clients all do it -- and it is the right
way round: nobody should be made to solve the packing problem from nothing.

Overlaps are checked here now, not left to the server. They have to be, for
the roll to be legal, and the same test refuses a move that would sit on
another hull -- with a tone and `SHIPS TOUCH`, the way `WON'T FIT` already
refuses one that runs off the edge. What it buys is the round trip it used to
cost: a `/place` the server refused came back as `ENPLFAIL` and all five
ships done again.

RESET is a switch on this console, a bit in a RIOT register the program
reads; it restarts nothing, and what it means is the client's to choose.
LEAVE sends `/leave` and then a fresh `/tables`, so the seat is given up
rather than abandoned.

The placement screen is not reached by pressing anything: the client hands
over when a poll says the phase is placement **and your own status is still
PLACE**. The phase stays at placement until everyone has placed, so testing
the phase alone would drop you back into it the moment you had finished.

A shot at a cell already resolved on every live enemy is refused with a
tone: the server refuses it silently and the turn never passes.

## Sounds

One TIA channel, a script engine that steps once a frame, and the family's
vocabulary: a click for every cursor step (one frame, so auto-repeat does
not drag), rising notes for a choice, a falling swoosh when a shot goes
out, a short low splash for a miss, a longer brighter explosion for a hit,
the explosion and three falling tones for a sinking, three rising tones on
your turn (before the draw: an alert after the fact is not one), a click on
the clock's last seconds, a low buzz for a refused move, and three long
falling tones at game over. The result cue rides the **status edge paired
with `lastAttackPos`**, so an opponent's shot is heard too and a result that
repeats across polls is heard once.

The cue numbers are in bank order, not in the order they were written: each
bank's cues are a prefix of the list and `SNDLAST` truncates its copy of the
scripts there. It is the same trick as `BSHASINP` and it is worth 148 bytes
in the bank that had none.

## Banks

Seven 2K banks and the fixed half, 16384 bytes. A bank switch replaces every
byte of `$1000-$17FF`, so each carries its own copy of every module it
calls; only zero page crosses, and the text planes, the playfield tables
and the reply window are cartridge state that survives.

| | | bytes |
|---|---|---|
| 0 `bslobby` | the cold start and the table list | 1016 |
| 1 `bsgame` | the board kernel, the cursor, the cues, a shot | 1668 |
| 2 `bsnet` | one request, with the picture up, and back | 1993 |
| 3 `bsmenu` | the RESET menu, the help, leaving | 1092 |
| 4 `bsname` | the keyboard and the shared username | 1201 |
| 5 `bsplace` | the roll, the five ships | 2013 |
| 6 `bscomp` | compose the game screen, in passes | 2025 |

Neither the strips nor the roll would have fitted where they had to go --
`bscomp` had six bytes free and `bsplace` seventy-seven -- so three things
each bank used to carry whether it wanted them or not were split apart
first. A byte in a shared include costs one bank of every bank that includes
it:

- **`BSHASUI` became `BSHASINP` and `BSHASUI`.** Reading the stick
  (`INSCAN`/`INREPT`, 104 bytes) and reading a player record out of the reply
  window (`PLRECP`/`GCURS`/`SLOTBIT`/`FNRPLP`, 118) were one flag. No bank
  but the game one wants both, and the composer -- whose `APPVBL` is an `rts`
  -- was carrying every byte of the input scanner.
- **`BSHASRPL` came out of `BSHASSTR`.** Only the composer streams the reply
  window into a text row.
- **The cues are numbered so each bank's are a prefix**, and `SNDLAST` says
  where that bank's copy of `sound.inc` stops. The place bank fires four of
  the twelve and used to carry all of them, which is 148 bytes it did not
  have. `tools/checkbanks.py` says whether the arithmetic worked.

The composer is a bank because the game bank came in 961 bytes over with it
in. The shared transport and the text primitives are in the fixed tail
(`bscore.inc`), the only region every bank sees at the same address;
`tools/mktail.py` reads their addresses out of the tail's own listing into
`build/tail.inc`, so there is no hand-kept list to go stale. The trampoline
resets the stack on every switch.

## The name

The shared FujiNet username -- appkey creator 1, app 1, key 0, the slot
every game in the family reads -- goes straight from the appkey reply into
a cartridge path buffer and from there into every URL; it never touches
console RAM. If the slot is empty, or the adapter has no SD card, a
three-row keyboard types one and writes it back. The joined table's id
lives in another path buffer for the same reason: every `/state` poll
repaints the window the listing came from.

## Traps paid for here

- **The cartridge blit is a single-slot request on the RP2040.** The bus
  core hands it to the other core and there is no queue, so a burst of
  thirteen would lose most of them on hardware -- and lose none in MAME,
  where a blit runs inside the store. The firmware now publishes
  `FN_B_BLITGEN` ($1F19), bumped when a blit has landed, and `FNBLIT` waits
  (bounded) for it before the next; `FNENDW` does the same for a text row
  through `FN_B_TEXTGEN`.
- **Missiles replicate with their player's copy count.** The divider is
  missile 1; with NUSIZ1's three close copies for the text there were three
  dividers. It is switched to one copy in the lead-in line before a board
  and back after.
- **A text row leaks.** The six-copy kernel goes on displaying its last two
  bytes down the screen until something blanks them, and the row routine's
  exit is too long to do it on the last ink line: a `jsr` right after its
  `rts` lands at cycle 79 and costs a scanline without anything looking
  wrong. Every text row here has a seam line that blanks, and the routine
  returns early in it.
- **The seam line's two deadlines are not the same deadline.** `PIPROW`'s
  line is a seam and a lead-in at once: `COLUBK` before pixel 0 at cycle
  22.67, the sprite blanking any time before the text block at clock 52,
  which is cycle 39. `LEADIN` blanks first because it can afford to; doing
  the same here costs four clocks of water at the left edge.
- **A whole fleet does not fit in one overscan.** The roll is one candidate
  a frame in the vblank hook, not a loop in `PENTRY`. A candidate costs up to
  about 1,650 cycles -- the hunt walks every hull already down -- and five
  ships at two candidates each is thousands more than the 2,200 an entry
  between frames has. The first version looped in `PENTRY`, took several
  frames to return, and dropped every button pressed at it in the meantime:
  the driver's five presses went into a bank that was not reading input yet,
  and the client sat in placement until the run timed out. Spread, the worst
  frame is one candidate, the fleet lands in about ten frames, and nothing
  reads the stick until it is down.
- **`SHIPS[4]` is the roll's flag.** The slots fill in order, so `$FF` in the
  last one means the roll is still running -- no cell was free for a state
  byte, and none was needed.
- **The place bank's scratch still must not alias `$AE-$B0`.** The roll needed
  four more cells and took `BSSEL`, `BSERR2`, `BSBLINK` and `BSTMP2`, each
  dead in this bank for the reason written next to it. The game bank's edge
  memory is the one region that has to survive placement.
- **NTSC hue 4 is pink** in MAME's palette; red is hue 3.
- **The text block is at clocks 52-99**, not 46-93: a player positioned by
  `RESPn` completing at cycle N lands at clock 3N-63, a missile one clock
  earlier. Both measured from the raster with `tools/pfcheck.py`.
- **A "done" flag in the network bank must not alias a settle-loop cell.**
  Its hook runs inside every frame the settle loop draws; an alias of the
  delay counter switched to a garbage bank mid-poll, and the symptom was a
  cold start after the first `/state`.
- **The poll's recompose was three lines too long at four seats, and had
  been all along.** `make frames` was AI1, which is two seats; nothing ran
  the quadrant layout past a VSYNC tap until `make frames4`, and it found
  sixty long frames in six thousand -- one per poll, every one of them
  `bank 2 -> 1`. `emu/banktime.lua` put the switch into the composer at
  +235.9 lines and the switch out at +263.5, so the pass wanted 27.6 lines of
  the 26.1 the network bank had left it. Four seats mean two more records to
  walk and two more blits than two. The AUX plane -- the hulls and the
  cursor -- is now a pass of its own in the next frame's vblank, and the
  count is 0 of 6178.
- **Placement scratch must not alias the game bank's edge memory**, or the
  first poll after placing hears a phantom shot.
- **The lobby's row count comes from the listing's count byte**, set in the
  validator; a `/tables` that is only length-checked lists nothing.
- **A cold start's RAM clear writes every zero-page cell**, so a Lua write
  tap on the request cell sees a spurious "request 0 in bank 0" -- that is
  the clear, not a fetch.
- Everything the 5 Card Stud port learned still applies: RAM is not cleared
  by a reset and the cold stub forces a cold entry; the RESET switch is a
  switch; MAME must run from its own tree; throttled is not a performance
  choice, because the server's countdown and move clock are wall clock.

## How it is checked

| | |
|---|---|
| `make hosttest` | the four playfield transforms against a picture of the tables built from the bit map in prose, every slot, poisoned outside |
| `make layout && make shot` | the kernel with no network: tables baked into the image, snapshotted, and every cell line of every board read back and required to be the colour the picture says (`tools/pfcheck.py`), plus the divider at 79-80; both layouts |
| `make drive` | types a name if asked, picks the table off the screen, readies -- and readies AGAIN if the status has not become PSREADY, because `/ready` toggles and the server resets a finished table under you, and one press left a run sitting in the lobby looking exactly like a hang -- **waits for the roll and checks the fleet it rolled does not overlap itself**, accepts it, fires until a result shows; after every poll reads the reply window's gamefields and the tables back and requires them to agree byte for byte |
| `make drive4` | the same at four seats, where it also reads text rows 3 and 4 back through the font and requires the pips to be `shipsLeft[5]` of that seat's record, seat by seat |
| `make frames` | the same game with a VSYNC tap: nothing but 262 |
| `make frames4` | and at four seats, where the kernel is 191 lines of a band of 192 and the poll's recompose has the least overscan to fit in |
| `make resetleave` / `make resettest` | the switch and the restart, which are two different things |
| build gates | `checkdefs.py` (the equates against the firmware header), `checkrom.py` (size, the `FUJI` claim, no RMW or indirect store on the control pages), `checkbanks.py` per bank, `mktail.py` on the tail. All fail the build. |

## Not here

- **Real hardware.** The firmware builds and its host tests pass; bus timing
  is the one thing emulation cannot settle.
- **PAL.** The line counts are NTSC.
- **The leftmost and rightmost cells sit at the very edge of the active
  area.** Two 80-pixel boards are the whole line; a CRT that overscans may
  clip a column. There is no playfield-granularity fix, and MAME shows all
  160.
- **Vertical ships read as a ladder of rungs** (a bracket per cell); a
  shape at eight pixels has no better answer.
- **A re-roll.** The Channel F port reshuffles the whole fleet on TIME. Every
  button this console has is spoken for during placement -- stick, FIRE,
  SELECT, RESET -- so a re-roll would have to become an item on the RESET
  menu.
- **Which ship each pip is.** The pips are in the server's order (5, 4, 3, 3,
  2) and the strip has five columns, not five names.
