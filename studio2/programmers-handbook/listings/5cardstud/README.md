# 5 Card Stud for the RCA Studio II

A CDP1802 client in Macroassembler AS, in the Arcadia and Channel F mould,
running over the FujiNet cartridge mailbox from `fujinet-firmware/pico/studio2`.
The cart draws the screen: every character is a hotspot read its text engine
renders into the raster the 1861 fetches, and the reply window (`$E400`) is
plain readable memory between transactions, so screens draw straight out of it.
Only the name, the table id and a move code are copied into RAM.

## Building

```sh
make                                     # == ./build.sh -> build/5card.st2
ENDPOINT=http://192.168.1.10:8080/ ./build.sh
```

Needs `~/asl/asl` (or `asl` on PATH, or `ASL=`) and the firmware tree for
`tools/checkrom.py` and `tools/mkst2.py` (`FUJI_FIRMWARE`, default
`~/Workspace/fujinet-firmware`). `build/endpoint.inc` is regenerated every run;
the default server is `https://5card.carr-designs.com/`. Everything lands in
`build/`.

`src/fujinet.inc`, `s2macro.inc`, `s2call.inc`, `fujilib.inc`, `fujidisp.inc`
and `input.inc` are verbatim copies of the firmware tree's `testrom/`.

## The screen (16 x 10)

```
row 0-7   YOU   9HKS            a seat each, server order; seat 0 is you
          CLYD  ##5D            name (to its first space), then five cards
          JIM   FOLDED          ...or FOLDED / LEFT / WAITING
row 8     POT 13    R2 :39      pot, street (END at the showdown), the clock
row 9     CLYD BOT WON WITH...  the result, scrolling, while it is news;
                                otherwise 0 MENU  9 CHIPS
```

The player to act has their name in inverse. A card is `[rank][suit]` in the
cart's font, white on black (inverse faces lose a 3x5 rank's outer strokes);
`t` is drawn `T`, and a hole card is a hatched app-glyph pair. Key 9 swaps the
cards for each seat's purse and last move.

On your turn rows 8-9 become the moves, two by two, an inverse key digit then
the name with spaces dropped (`1FOLD  2CALL / 3RAISE5  POT 3`); the fourth
slot shows the pot when it is free. A 40-frame Q beep marks the turn.

The lobby lists up to eight tables as `[n]NAME c/m` (name in 11 cells, the
server's `cur / max` without its spaces).

## Keys

Either pad.

| Screen | Keys |
|---|---|
| Name | 2 4 6 8 move on the A-Z 0-9 `- _ .` grid, 5 type, 1 delete, 3 done, 0 keep the old name |
| Lobby | 1-8 join that table, 0 menu |
| Table | 1-5 send that offered move, 9 cards/chips, 0 menu |
| Menu | 1 or 0 back, 2 leave the table (lobby: refresh), 3 change name, 4 quit to CONFIG |
| `NET ERROR Ex` | lobby: 0 menu, any other key retries; table: retries every 3 s |

The keypads are also scanned while a transaction runs, so a press during a
poll is kept. Changing the name or quitting leaves the table first; quitting
is fujilib's `fn_config`.

## Name

The username every client shares, the appkey at creator 1, app 1, key 0. OPEN
takes the 6-byte `struct appkey` as payload with no parameters; READ answers a
u16 length then the value. The editor opens only when the key is empty or
unreadable, and writes it back. The name and the table id are percent-encoded
in the URL.

## Transport

`net.inc` carries the family's five rules (CLOSE opens the next request; take
the reply length right after the READ; STATUS settles on two agreeing readings
and Channel F's minimum, 154 for `/state` and 1 for `/tables`; STATUS byte 3
must be 1; the length must equal `154 + 33*playerCount`, or `1 + 36*count` for
`/tables`). The client waits 100 s on N: transactions, past the cart's own
90 s. `/leave?bin=1` has no body, so leaving is OPEN plus one STATUS.

## Size and RAM

5188 bytes in 25 pages (the `.st2` is 6656): the runtime at `$0400-$077D`, then
`$0C00`, `$1400`, `$2400` and `$3400` blocks with room to spare. No 3-cycle
opcode (`checkrom.py`), and AS rejects any short branch off its page.

RAM: `$0800-$080F` the runtime's, the client's variables `$0810-$0856` (all on
page `$08`, so RA.1 stays fixed), cleared at start; the stack uses under 40
bytes down from `$09FF`. The ledger is in `5card.asm`.

## Test

`pico/studio2/emu/5carddrive.lua` in the firmware tree drives the whole flow
against the live server: types `S2TEST` on the grid when the appkey is empty,
joins `AI ROOM - 2`, plays legal moves through two hands, then 0 > 4 and waits
for the cart's hand-over (`fujinet_swaps`). It runs MAME throttled, since the
server's clocks are real time.

```sh
cd ~/Workspace/fnpc-studio2-fcs && ./run-fujinet -u 127.0.0.1:8034 -c fnconfig.ini -s SD &
cp build/5card.st2 ~/Workspace/fujinet-firmware/pico/studio2/build/
cd ~/Workspace/fujinet-firmware/pico/studio2
SECS=900 MAMEBIN=./studio2-agents FUJINET_TCP=127.0.0.1:9972 ./run.sh 5card 5carddrive
```

`S2_NAME`, `S2_TABLE`, `S2_HANDS` and `S2_LIMIT` override the defaults.

## Untested

The spectator path (`WATCHING (FULL)`, needs a full table); a fifth offered
move, which is not drawn (key 5 still sends it; the server offers at most
four); the lobby never refreshes on its own; no hardware exists yet.
