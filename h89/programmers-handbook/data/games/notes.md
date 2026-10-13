# The network games: notes for Chapters 16-19

Sources, as built for the book (`tools/games.sh`), all paths below relative to
`build/games/` unless they start with `servers/` (=
`~/Workspace/servers/fujinet-game-system/`, HEAD 19770c3) or `lobby/`
(= `~/Workspace/fujinet-lobby/`, server v5.5.7):

| Game | Tree | Commit | Programs |
|---|---|---|---|
| Texas Hold'em | `texasHoldEm/` | 6bad3aa (`add-h89`), clean | `TEXAS.ABS` / `TEXAS.COM` |
| Battleship | `battleship/` | 0c86ed6 (`add-h89`), clean | `FBS.ABS` / `FBS.COM` |
| Fujitzee | `fujitzee/` | 3fe25a6 (`add-h89`) **plus the uncommitted working tree**: 8 modified files (Makefile, README.md, mekkogx/platforms/h89-cpm.mk, src/gamelogic.c, src/misc.c, src/misc.h, src/platform-specific/vars.h, src/screens.c) and the untracked `src/h89/`, `support/h89/`, `mekkogx/platforms/h89-hdos.mk` (listing JSON says `dirty: true, files_changed: 11`) | `FUJITZEE.ABS` / `FUJITZEE.COM` |

The book's listings (`data/listings/*.json`) print exactly the files the
compiler read (from the `.d` files). Battleship's vendored copies of the
library headers, `src/fujinet-fuji.h` and `src/fujinet-network.h`, are
compiled but deliberately left out (`tools/mklistings.py:31`).

---------------------------------------------------------------------------

## 1. The game system

### 1.1 The pieces

* **Game servers** -- one Go/Gin program per game, in
  `servers/texasholdem/server/`, `servers/battleship/`,
  `servers/fujitzee/server/`. Each runs on Google Cloud Run (us-central1,
  min 0 / max 1 instance, `gcloud run deploy --source .`; no Dockerfile);
  listens on `$PORT` (default 8080: TH main.go:58-61, BS 54-57, FJ 55-58).
  Custom domains are CNAMEs to ghs.googlehosted.com
  (`servers/texasholdem/server/deploy.sh:2`). **All state is in memory**
  (a `sync.Map`): every table resets when the instance restarts or scales to
  zero.
* **Public URLs** -- the clients' built-in defaults, which match each
  server's `lobbyClient.go` `Serverurl`:
  * `https://th.carr-designs.com/` (`texasHoldEm/src/main.c:30`)
  * `https://battleship.carr-designs.com/` (`battleship/src/main.c:22`)
  * `https://fujitzee.carr-designs.com/` (`fujitzee/src/main.c:27`)
  Battleship and Fujitzee also carry `http://127.0.0.1:8080/`
  (`battleship/src/main.c:27`, `fujitzee/src/main.c:31`), used when the
  first byte of the game's prefs app key is 0xFF (`battleship/src/misc.c:161`,
  `fujitzee/src/misc.c:131`) -- a developer switch.
* **The Lobby** -- `lobby.fujinet.online`, source `lobby/` (FujiNetWIFI/
  fujinet-lobby; `servers/lobby` is only an old binary, the old source is in
  `servers/00_moved-to-new-repo/lobby`). Routes `/`, `/docs`, `/viewFull`,
  `/view`, `/version`, `POST /server`, `DELETE /server`
  (`lobby/server/main.go:93-99`).
  * Each game server posts **one entry per table** to `/server`:
    `{game, appkey, server:<table name>, region:"us",
    serverurl:<base>+"?table=<id>", status:"online", maxplayers, curplayers,
    clients:[{platform,url}]}` at start-up, join, drop and leave -- only when
    `GO_PROD=1` (TH `lobbyClient.go:15,22-33`; BS `lobbyClient.go:14-36`;
    FJ `lobbyClient.go:14-35`).
  * A *lobby client* program (Atari, Apple II, CoCo, C64, MS-DOS, VIC-20 --
    `lobby/clients/`) lists servers with `GET /view?platform=X[&appkey=N]
    [&bin=1]` (binary: `{count,0,0}` then 189-byte records; `lobby/server/
    model.go:60-72,143-180`), lets the player pick, **writes the player's name
    to app key creator 0x0001 / app 0x01 / key 0** and **the chosen server URL
    (`https://th.carr-designs.com/?table=ai2`) to key = the game's lobby app
    key number** (`lobby/clients/src/main.c:23-25,405,511`), then boots the
    game.
  * The games never talk to the lobby. They only read those two keys.
  * **On the H89 there is no lobby client, and no server registers an `h89`
    client entry**, so the H89 games start from their built-in endpoint and ask
    the game server for its own table list (`/tables`). The name and server
    keys are still read and written, so the H89 games interoperate with the
    convention.

### 1.2 How a game finds and joins a table

1. Read app key 1/1/0 (player name). If empty, show the name screen; save it
   back to 1/1/0 (`texasHoldEm/src/screens.c:256,262`;
   `battleship/src/screens.c:168,176`; `fujitzee/src/screens.c:405,419`).
   Names are 2-8 characters (RETURN refused until `curx>1`:
   `texasHoldEm/src/screens.c:203`, `battleship/src/gamelogic.c:829`,
   `fujitzee/src/gamelogic.c:966`; `PLAYER_NAME_MAX 8`). Battleship and
   Fujitzee lower-case the name (`battleship/src/screens.c:187-193`,
   `fujitzee/src/screens.c:429-434`).
2. Read the lobby server key (TH 8, BS 5, FJ 3:
   `texasHoldEm/src/misc.h:50`, `battleship/src/misc.h:29`,
   `fujitzee/src/misc.h:28`) and split `server?query`.
   * **Texas** keeps the server part but always clears the query, so the table
     picker is always shown (`texasHoldEm/src/screens.c:144-168`, esp. 167).
   * **Battleship and Fujitzee** keep the query too (`battleship/src/
     screens.c:115-136`, `fujitzee/src/screens.c:199-216`) -- if the key names
     a table they go straight back to it, skipping the picker.
3. Table picker: `GET <server>tables?bin=1` (TH `screens.c:344`, BS
   `screens.c:259`, FJ `screens.c:560`), list `name` and `players`
   (the server's "cur / max": humans / human seats in Texas, e.g. "0 / 2" at
   the 6-bot table), a mark beside tables with players. Keys: arrows (or `-` `=`)
   move, RETURN/SPACE joins; R refresh, H help, N name (TH/BS), C colour
   (TH), S sound (BS/FJ), P local players (FJ), Q quit to the OS.
4. On join: `query = "?table=<id>"`, the full URL is written back to the
   lobby server key "in case of reboot" (TH `screens.c:437-443`, BS
   `screens.c:404-412`, FJ `screens.c:652-658`), then `&player=<name>`
   appended with spaces turned to `+` (TH `screens.c:299-313`, BS
   `screens.c:420-427`, FJ `screens.c:676-692`).
5. There is no join call: **any request carrying `table=` and `player=` seats
   that player** (server getState: TH main.go:247-278, BS 291-317, FJ
   262-288). Table names are lower-cased; an unknown table gives JSON `null`
   (with `bin=1` an HTTP 500 -- inferred from the code, not run).
6. Leaving (in-game menu, Q): `GET leave?...` and the server key is cleared
   to "" (TH `screens.c:605,609`; BS `screens.c:513,516`; FJ
   `screens.c:778,781`). With `bin=1` `/leave` returns a 0-byte body.

Players who have not pinged for 5 minutes (`PLAYER_PING_TIMEOUT`, TH
gameLogic.go:58, BS 34, FJ 32) are removed at game end or when someone joins.
In Texas only joining and your own `/move` refresh the ping (gameLogic.go:571,
1198) -- polling `/state` does not; in Battleship and Fujitzee every `/state`
does (BS gameLogic.go:431, FJ 478).

### 1.3 The URL every call uses

All three build the URL the same way:

    N: + server + path + query + (&|?)bin=1 [+ suffix]

* Texas: `"N:"` unless the endpoint already starts with N
  (`texasHoldEm/src/stateclient.c:23-47`), `&bin=1` + `QUERY_SUFFIX` (empty on
  the H89, `texasHoldEm/src/h89/vars.h:30`).
* Battleship: `"n:"` and `&bin=1&v=2` (`battleship/src/stateclient.c:36-44`,
  `API_CLIENT_VERSION "2"` at `misc.h:23`) -- v=2 gets ten ship positions
  (yours + the winner's at game over) and the winner index.
* Fujitzee: `"n:"` and `&bin=1` (`fujitzee/src/stateclient.c:27-36`); the
  query is per *local player* (hot-seat play, below).
* `be=1` (big-endian words) is never needed: the Z80 is little-endian (TH and
  FJ `QUERY_SUFFIX ""`).

Every request is an HTTP GET; the servers accept GET and POST on everything
except `/view` and `/tables`.

### 1.4 Server routes used by the H89 clients

| Game | Path | What it does |
|---|---|---|
| all | `tables` | table list (binary below) |
| all | `state` | advance the game if seated, return the state |
| all | `leave` | leave the table |
| Texas | `move/<code>` | FO fold, CH check, CA call, BL/BH bet 1x/2x big blind, RL/RH raise min/2x, AI all-in -- amounts computed by the server (servers/texasholdem/server/gameLogic.go:1290-1369) |
| Battleship | `ready` | toggle ready in the lobby (the deprecated toggle; `/ready/1`/`/ready/0` also exist) (`battleship/src/gamelogic.c:570`) |
| Battleship | `place/a,b,c,d,e` | five ship positions in order 5,4,3,3,2, each `dir*100 + y*10 + x` (dir 0 across, 1 down; anchor top-left) (`battleship/src/gamelogic.c:297-305`) |
| Battleship | `attack/N` | N = 0-99; fires at **every** live opponent at once (`battleship/src/gamelogic.c:694-696`) |
| Fujitzee | `ready` | toggle only (`fujitzee/src/gamelogic.c:108,607`) |
| Fujitzee | `roll/xxxxx` | five chars, `1` = re-roll that die, `0` = keep (`fujitzee/src/gamelogic.c:740-742`) |
| Fujitzee | `score/N` | N = 0-14, accepted only if `validScores[N] > -1` (`fujitzee/src/gamelogic.c:714-716`) |

Other routes exist but are not used by the H89 clients: `/view` (state without
advancing), `/version`, `/updateLobby`, TH `/ws` (WebSocket),
BS `/debugEndGame`. Other query parameters: `hash` (TH: a matching hash gives
just `"1"`, but only JSON carries the hash, so binary clients cannot use it),
`raw=1`/`lf=1`/`uc=1`/`lc=1` (old delimited-text format), `dev=1` on `/tables`
(hidden developer tables), FJ `pov=<name>`.

### 1.5 The binary replies (`bin=1`)

The server writes fixed-layout little-endian records; the client reads the
reply **straight into a union** (`ClientState`) with
`network_read(url, &clientState.firstByte, sizeof(Game))` -- one read of up to
`sizeof(Game)`, which returns early at end of data (shorter replies are
normal). No parsing at all. z88dk (sccz80) never pads structs, so the C
layout is the wire layout; Texas marks the structs `_Packed` (defined empty
for z88dk, `texasHoldEm/src/misc.h:81-83`), Fujitzee checks at compile time:

    typedef char game_wire_size_check[(sizeof(Game) == 599) ? 1 : -1];

(`fujitzee/src/h89/util.c:26`; `FUJITZEE_PACK_STRUCTS`/`#pragma pack` in
`fujitzee/src/misc.h:39-54` for compilers that pad).

Strings: `appendFixedLengthString` truncates to N, **lower-cases**, and pads
with NULs to N+1 bytes, so a terminator is always there (TH util.go:179-196,
BS util.go:118-135, FJ util.go:119-136). That is why table names, player names
and Texas move names arrive in lower case (and why Fujitzee's H89 graphics
code shows all text in capitals).

**Table list (all three, identical)** -- `Tables`
(`texasHoldEm/src/misc.h:85-89,119-122`; `battleship/src/misc.h:67-92`;
`fujitzee/src/misc.h:56-71`):

| Offset | Size | Field |
|---|---|---|
| 0 | 1 | `uint8_t count` |
| 1+36i | 9 | `char table[9]` (id, e.g. "ai2") |
| 10+36i | 21 | `char name[21]` ("ai room - 2 bots") |
| 31+36i | 6 | `char players[6]` ("0 / 6" = humans / human seats) |

Client struct holds 10 tables (361 bytes). Tables come out in reverse
creation order.

**Texas Hold'em `Game`** (`texasHoldEm/src/misc.h:91-117`; server serializer
servers/texasholdem/server/util.go:78-160, locked by bin_protocol_test.go:13-28):

| Offset | Size | Field |
|---|---|---|
| 0 | 81 | `char lastResult[81]` |
| 81 | 1 | `uint8_t round` (0 waiting, 1 pre-flop, 2 flop, 3 turn, 4 river, 5 showdown) |
| 82 | 2 | `uint16_t pot` |
| 84 | 1 | `int8_t activePlayer` (-1 none; players rotated so **you are 0**) |
| 85 | 1 | `uint8_t moveTime` (seconds left, minus a 4 s grace; non-zero only on your turn) |
| 86 | 1 | `uint8_t viewing` (1 = spectator, table full) |
| 87 | 11 | `char community[11]` ("askh2d": rank+suit pairs, `t` = ten) |
| 98 | 1 | `uint8_t validMoveCount` |
| 99 | 5x13 | `ValidMove validMoves[5]` = `{char move[3]; char name[10];}` (always 5 slots) |
| 164 | 1 | `uint8_t playerCount` |
| 165 | 8x33 | `Player players[8]` = `{char name[9]; uint8_t status; uint16_t bet; char move[8]; uint16_t purse; char hand[11];}` |

`sizeof(Game)` = 429; a reply is `165 + 33*N` bytes. Other hands arrive as
`????` (folded `??`), all revealed at showdown. Status 0 waiting, 1 playing,
2 folded, 3 left (all-in sent as 1).

**Battleship `Game`** (`battleship/src/misc.h:74-106`; serializer
servers/battleship/util.go:19-110):

| Offset | Size | Field |
|---|---|---|
| 0 | 1 | `uint8_t playerCount` (you = 0) |
| 1 | 33 | `char prompt[33]` |
| 34 | 1 | `uint8_t status` (0 lobby, 1 place ships, 10 start, 11 miss, 12 hit, 13 sunk, 99 game over) |
| 35 | 1 | `uint8_t playerStatus` (0 playing/not ready, 1 defeated, 2 viewing, 3 ready, 10 must place ships) |
| 36 | 1 | `int8_t activePlayer` |
| 37 | 1 | `uint8_t moveTime` |
| 38 | 1 | `uint8_t lastAttackPos` |
| 39 | 10 | `uint8_t myShips[10]` (pos + 100*dir; 5-9 = the winner's, at game over, v=2) |
| 49 | 4x115 | `Player players[4]` = `{char name[9]; uint8_t playerStatus; uint8_t gamefield[100]; uint8_t shipsLeft[5];}` |

`sizeof(Game)` = 509. In the lobby (status 0) the same bytes are read as
`Lobby` (`misc.h:108-118`): after the 38-byte header comes
`char serverName[21]` and `LobbyPlayer {char name[9]; uint8_t ready;}` x4.
Gamefield cells: 0 untried, 1 hit, 2 miss; shipsLeft 1 afloat / 0 sunk; ships
5,4,3,3,2. (The server omits a player's 105-byte field until the game has
started.)

**Fujitzee `Game`** (`fujitzee/src/misc.h:62-86`; serializer
servers/fujitzee/server/util.go:56-111):

| Offset | Size | Field |
|---|---|---|
| 0 | 1 | `uint8_t playerCount` (players, then spectators) |
| 1 | 21 | `char serverName[21]` |
| 22 | 41 | `char prompt[41]` |
| 63 | 1 | `uint8_t round` (0 lobby, 1-13, 99 game over) |
| 64 | 1 | `uint8_t rollsLeft` |
| 65 | 1 | `int8_t activePlayer` |
| 66 | 1 | `uint8_t moveTime` |
| 67 | 1 | `uint8_t viewing` |
| 68 | 6 | `char dice[6]` ("35126") |
| 74 | 6 | `char keepRoll[6]` ("01101") |
| 80 | 15 | `int8_t validScores[15]` (-1 = not allowed) |
| 95 | 12x42 | `Player players[12]` = `{char name[9]; uint8_t alias; int16_t scores[16];}` (-1 = unscored) |

`sizeof(Game)` = 599; reply `95 + 42*N`. Score index: 0-5 ones..sixes, 6
upper total, 7 bonus (35 at >=63), 8 set of 3, 9 set of 4, 10 full house (25),
11 short run (30), 12 long run (40), 13 count/chance, 14 Fujitzee (50), 15
total. In the lobby `scores[0]` is 1 ready / 0 not / -2 viewing. Each human
gets a one-letter **alias** from their name (the column initial on the board).

### 1.6 Polling and change detection

* **Texas** polls back to back, with no timer of its own: `getStateFromServer()` -> if the reply is
  good, a position-weighted byte sum of the whole 429-byte `Game`
  (`sum += byte ^ index`) is compared with the last one drawn and the table
  repainted only if it changed; then `requestPlayerMove()`, then a key read,
  then the next request (`texasHoldEm/src/main.c:100-161`, sum at 129-140,
  comment at 104-128 explaining the H89 case: the renderer would send no bytes
  anyway, but it would re-sweep the active player's highlight). It waits only
  after a failed fetch (`pause(30)`, half a second, main.c:147). The server
  itself advances the game every 2 s from a per-table goroutine (main.go:271,
  websocket_handler.go:29-68).
* **Battleship and Fujitzee** count frames: after a good reply,
  `apiCallWait = 59` frames (`battleship/src/main.c:140`,
  `fujitzee/src/main.c:105`), on failure `60 * failures` up to 4 (4 s), with a
  flashing connection icon after the second failure (BS main.c:109-127, FJ
  77-93). A Battleship frame is 10 ticks = 20 ms (`battleship/src/h89/
  util.c:22`), so it polls about every 1.2 s plus the request; Fujitzee's frame
  is 1/60 s, about 1 s. No change detection in the client: every reply is
  "rendered", and the console layer sends only cells that differ.
* **What the tap saw** (run game-texas-hdos-3, `build/runs/game-texas-hdos-3/
  tap.jsonl`): each poll is five transactions on network unit 71H --
  `O` open (mode 0CH, the URL `N:https://th.carr-designs.com/state?table=ai6&
  player=THOM&bin=1`), `S` status, `R` read of exactly the bytes waiting
  (181 = 1 + 5x36 for the table list, 396 = 165 + 7x33 for a seven-player
  table), `S`, `C` close. A request took 0.5-0.9 s of real time, and polls
  came every 2.2-2.4 s while nothing needed the player (the rest is the
  9600-baud redraw and the highlight sweep), longer around animations. The
  app key traffic at start-up is on unit 70H: DCH open (creator BEBEH, app 1,
  key 0, read), DDH read, DEH write ("THOM" to 1/1/0). THOM is sent as typed
  (Texas does not lower-case the name; the server matches names
  case-insensitively). The move went out as **`move/ca`**: the move codes
  come back lower-cased like every string, and the server upper-cases the
  move it is given.
* Measured on the rig for the other two: Battleship polled about every 2 s
  in the lobby and every 4-5 s during play; Fujitzee about every 1.2-2 s in
  the lobby and every 3-6 s during play (the board redraws, the dice
  animation and `pause(30)` while others play eat the rest). Reply sizes seen:
  Battleship lobby 99 = 59 + 4x10, placement 89/79 (fields not yet sent:
  49 + n x 10), game 394 = 49 + 3x115; Fujitzee table list 145 = 1 + 4x36,
  state 305 = 95 + 5x42. Moves seen: `place/102,72,147,114,179`,
  `attack/11`, `ready`, `score/14`.
* **Texas never lets the server fold you on time.** `requestPlayerMove()`
  counts down `moveTime` (the server's clock less a 4 s grace) and when it
  reaches 0 it sends the move under the cursor anyway -- CALL/CHECK by
  default, because the cursor starts on stop 1
  (`texasHoldEm/src/gamelogic.c:743,783-866`). Seen in run game-texas-hdos-4:
  with no key pressed, `move/ca` and `move/ch` went out about 36 s into each
  turn. While it is your turn the client does not poll at all.
* **A session outlives the program.** Quitting with Q sends `/leave`; turning
  the H89 off (or the emulator ending) does not, so the player stays seated
  until the 5-minute ping time-out is acted on (game end or a *different*
  player joining). Rejoining with the same name takes the same seat -- in
  Battleship/Fujitzee straight into the running game, not the lobby; a
  Battleship table can sit in ship placement indefinitely (no placement
  timer). For the screenshots the leftover THOM was sent `/leave` with curl
  between runs. (An accidental `/view?player=...` also seats a player and,
  in Battleship, pushed a bot into the "bot box" until the next game reset --
  which is why run game-bs-hdos-3 has only three boards.)
* A move request replaces the next poll (`sendMove()` sets
  `apiCallWait = 0` and the next fetch is `move/...` instead of `state`, whose
  reply is the new state: TH `stateclient.c:50-61`, BS `stateclient.c:73-94`,
  FJ `stateclient.c:58-110`).

### 1.7 Tables, bots and timers on the live servers

| Game | Tables (id: name) | Bots | Seats | Turn timer |
|---|---|---|---|---|
| Texas | basement, den (no bots); ai2/ai4/ai6 "AI Room - n bots"; hidden dev1-dev7 (main.go:284-300) | Clyd, Jim, Kirk, Hulk, Fry, Meg, Grif, GPT "BOT", each with a VPIP/PFR/bluff profile; a bot below 25 chips is renamed and rebought to 1000 (gameLogic.go:78-89,191-198,341-357) | 8; bots hold seats, so human seats = 8 - bots; 9th caller watches | 39 s (+1 s first player), bots 3 s, 12 s between hands; a timed-out human is folded (52-55, 921-925); blinds 5/10; stake 1000 |
| Battleship | r1 "Cape Fuji", r2 "High Seas", ai1 "AI - 1 on 1", ai2/ai3 "AI - n Bots", hidden test (main.go:323-336) | Clyd, Meg, Kirk Bot, always ready, random ships | 4 | 45 s (15 s after a time-out penalty; 250 s if you are the only human), bots 3 s; game starts when >=2 humans or 1 human + a bot are ready, countdown 31 s (3 s for one human, 6 s once all ready) |
| Fujitzee | bar "The Bar", kit "Kitchen Table", ai2/ai4 "AI Room - n bots", hidden dev1-3 (main.go:294-309) | "1AI Clyd", "2AI Meg", "3AI Kirk", "4AI Jim" (digit = alias); every other bot "smart" | 6 | 45 s (255 s if the only human), bots 3 s; server auto-rolls the first roll of each turn; on time-out scores the first open category |

When no human is seated a Texas table stops (bots fold, gameLogic.go:831-852).
Unknown-player requests to BS/FJ `/view` panic (HTTP 500) -- not used here.

---------------------------------------------------------------------------

## 2. Shared architecture of the three clients

All three come from Eric Carr's multi-platform game clients (5 Card Stud is
the ancestor; "Eric Carr, Thomas Cherryhomes" in each `main.c` header). The
H89 ports are Thomas Cherryhomes's. Their comments give the lineage:
Battleship's `src/h89/console.c` OS layer and `input.c` decoder were reused by
the later ports (`texasHoldEm/src/h89/console.c:10-17`,
`texasHoldEm/src/h89/input.c:15`), and Fujitzee's console and decoder are
"fujinet-5cardstud's ... whose OS layer is fujinet-battleship's"
(`fujitzee/src/h89/console.c:10-18`, `fujitzee/src/h89/input.c:13-18`). Texas
and Fujitzee share the back-buffer renderer; Battleship has the older,
simpler shadow-only one.

### 2.1 Layout of a tree

    src/*.c, *.h               shared game code (all platforms)
    src/platform-specific/*.h  the interface each platform implements
    src/<platform>/            one directory per platform: h89, adam, coco, ...
    mekkogx/                   the shared build system (do not customise)
    mekkogx/platforms/h89-hdos.mk, h89-cpm.mk
    support/h89/               cpm-dir-fixup.py (+ smoke.sh: TH, FJ)

`PLATFORM_COMBOS += h89-cpm+=h89 h89-hdos+=h89` makes both builds compile
`src/h89` (TH Makefile:101, BS 135, FJ 92); everything in it is wrapped in
`#ifdef __H89__`, which both `.mk` files define (`-D__H89__`; fujinet-lib keys
on it too). `src/platform-specific/vars.h` (BS, FJ) or `input.h` (TH) pulls in
`../h89/vars.h` (BS `src/platform-specific/vars.h:20-21`) -- screen size,
key codes, icons, layout macros.

The interface headers: `graphics.h` (screen, text, cards/boards/dice, buffers),
`input.h` (keys, joystick), `sound.h` (one function per event), `util.h`
(waitvsync, timer, quit, random), and in Texas also `network.h`
(`getResponse(url, buffer, max)`) and `appkey.h` (`read_appkey`,
`write_appkey`). Battleship and Fujitzee call fujinet-lib from the shared code
(`stateclient.c`, `misc.c`) unless `CUSTOM_FUJINET_CALLS` routes it to the
platform (below).

### 2.2 The main loop

* **Texas** (`texasHoldEm/src/main.c:74-165`): `loadPrefs`, `initGraphics`,
  `initSound`, `initPlatformKeyboardInput`, `showWelcomeScreen` (name),
  `showTableSelectionScreen`, then forever: fetch state; if new,
  `showGameScreen()`; `requestPlayerMove()` (blocks with a countdown while it
  is your turn); read a key; ESC (or f1-f5/colour keys, CTRL-C) opens the
  in-game menu.
* **Battleship** (`battleship/src/main.c:48-147`) and **Fujitzee**
  (`fujitzee/src/main.c:46-117`): same start, then every pass: count down
  `apiCallWait`; when it hits zero fetch and `processStateChange()`;
  Fujitzee `handleAnimation()` (dice rolling); `processInput()` -- which, on
  your turn, enters `waitOnPlayerMove()` and stays there until you move or
  time runs out.

### 2.3 The H19 console layer (`src/h89/console.c`)

Common ideas:

* A **cell code** per screen position: bit 7 reverse video, low 7 bits the
  H19's own character-ROM index (444-29): 0x00-0x1F the graphics characters,
  0x7F the graphics bullet, 0x20-0x7E ASCII (`texasHoldEm/src/h89/console.h:4-64`,
  names `G_VLINE` ... `G_BULLET`).
* Sending a cell (`sendCell`, TH console.c:248-282; BS `emit` 242-292): switch
  reverse video with ESC p / ESC q only when it changes; switch graphics mode
  with ESC F / ESC G only when the cell needs it -- graphics mode only remaps
  0x5E-0x7E, so ASCII below 0x5E prints the same either way and never forces
  a mode change (`gfxNeed`, TH 237-246); graphics ROM index n is sent as
  `n + 0x60` (` through ~), 0x1F as `_`, the bullet 0x7F as `^`.
* Cursor addressing ESC Y row+32 col+32, sent only when the cursor is not
  already there; the cursor position, reverse and graphics state are tracked
  (`curX, curY, curRev, curGfx`; `CUR_UNKNOWN` = 0xFF forces a re-send). In
  discard-at-end-of-line mode (ESC w) the cursor sticks on column 79, so after
  writing there the position is forgotten (TH 280-281).
* **Texas/Fujitzee (back buffer)**: `buf` (being drawn) and `scr` (what the
  terminal shows), 80x25 each, a `dirty` flag per row; `flush()`
  (TH 383-410) finds rows that really differ (memcmp), and if at least half
  the 24 rows changed and at least 600 cells must be blanked it clears with
  ESC E and redraws (`CLEAR_MIN 600`); per row it skips to the last non-blank
  cell and erases the rest with ESC K when 4+ stale cells would otherwise be
  sent as spaces (`EOL_MIN 4`); it re-sends up to 3 unchanged cells rather
  than a 4-byte ESC Y when no mode change is needed (`GAP_MAX 3`,
  `cheapGap`). A row-offset table avoids sccz80's multiply call
  (TH 44-50). Texas flushes when the shared code calls `drawBuffer()` or
  draws unbuffered; Fujitzee flushes in `waitvsync()`
  (`fujitzee/src/h89/util.c:38`), in `kbhit()`/`cgetc()`
  (`fujitzee/src/h89/input.c`) and before every FujiNet call
  (`fujitzee/src/h89/fujinet.c:25,38,48`) so "refreshing game list.." is on
  the screen while the request blocks. Fujitzee adds a third 2000-byte buffer
  `saved` for `conSave()`/`conRestore()` (console.c:40,494-504) -- the
  in-game menu and help overlays. **Three 80x25 buffers is why Fujitzee is the
  big one** (see 4.3).
* **Battleship (shadow only)**: one `scr` shadow (80x24) plus `scrBak`; `put()`
  compares with the shadow and sends the cell at once if it differs
  (`battleship/src/h89/console.c:294-307`); `termSave`/`termRestore` copy the
  shadow aside and put it back cell by cell (315-329). It does not use the
  25th line.
* `termInit()` (TH 416-438): ESC G, ESC q, **ESC x 5** (cursor off),
  **ESC w** (discard at end of line, no wrap), **ESC t** (keypad shifted:
  the unshifted keypad sends ESC A-D), **ESC x 1** (25th line on; TH and FJ
  only), ESC E. `termExit()`: **ESC z** (reset to the power-up configuration
  the DIP switches set), wait 100 ticks (200 ms), restore the OS console
  (TH 440-452).
* OS layer: **HDOS** -- `RST 38H` + function byte: `.SCOUT` (2), `.SCIN` (1,
  carry = nothing waiting), `.CONSL` (6) (TH 64-111); `osInit()` saves the
  five console bytes S.CSLMD..S.CONFL at 20D6H and sets raw character mode,
  no echo, no wrap, width 255, no upper-case mapping (graphics characters are
  sent as lower-case letters!), clears CTL-O/CTL-S flags (TH 115-145);
  `osExit()` puts them back. **CP/M** -- the BIOS jump table directly: (0001)
  -> WBOOT, +3 CONST, +6 CONIN, +9 CONOUT, saving IX/IY (TH 160-201); the BDOS
  console calls would expand tabs, filter and hold back characters.
* `TICKS`: the H89's 2 ms clock counter, HDOS `.TICCNT` at 201BH, the CP/M
  BIOS's at 000BH (`texasHoldEm/src/h89/console.h:94-98`).

### 2.4 Keyboard (`src/h89/input.c`)

* Raw bytes from `conIn()`; DELETE (7FH) becomes BACKSPACE, LINE FEED (0AH)
  becomes RETURN (TH input.c:36-43).
* ESC: wait up to **10 ticks = 20 ms** for a follower (`ESC_WAIT_TICKS`,
  TH input.c:23, 46-60): at 9600 baud a keypad sequence arrives back to back,
  so an ESC alone is the ESC key. ESC A/B/C/D = up/down/right/left; ESC P/Q/R
  (BLUE/RED/GRAY) and ESC S-W (f1-f5) all mean ESC (open the menu); HOME,
  ERASE, IL, DL, IC, DC are ignored; ESC + an ordinary key = ESC then the key
  (TH 62-116). Decoded keys queue in a 4-byte `pending[]`.
* Both OSes buffer the keyboard on interrupt (HDOS's console driver, the CP/M
  BIOS's 40-byte RST 3 buffer), so no key is lost between polls.
* Arrow codes: Texas/Fujitzee use the MSX cursor codes 1CH-1FH (Texas's
  `inputKey` is a plain signed `char`), Battleship A0H-A3H; spares without
  the keypad: `,` left, `.` right, `-` up, `=` down; CTRL-C = ESC alt
  (`texasHoldEm/src/h89/vars.h:45-65`, `battleship/src/h89/vars.h:32-52`,
  `fujitzee/src/h89/vars.h:84-104`). `readJoystick()` returns 0.
* Interfaces: Texas uses `USE_PLATFORM_SPECIFIC_INPUT` and a non-blocking
  `getPlatformKey()`; Battleship and Fujitzee supply `kbhit()`/`cgetc()`
  themselves instead of z88dk's conio (whose CP/M `getk()` drains the
  type-ahead and keeps only the last byte: `battleship/src/standard_lib.h:60-74`).

### 2.5 Timing

* Texas and Fujitzee: the shared code thinks in 60ths of a second; a frame is
  25/3 ticks, so `waitvsync()` waits 8, 8, then 9 ticks
  (`texasHoldEm/src/h89/util.c:23-35`, `fujitzee/src/h89/util.c:31-44`).
  Texas `getTime()` = ticks*3/25 in 60ths (long arithmetic,
  TH util.c:42-47); Fujitzee's move clock counts 50ths (ticks/10) to avoid
  it (FJ util.c:51-60).
* Battleship: frame = 10 ticks = 50 per second (`battleship/src/h89/
  util.c:22-49`); `getRandomNumber()` seeds `srand(TICKS)` at first use
  (after human-paced input) -- used for the random first position of each
  ship.
* "Drawing over the 9600 baud console can take longer than a frame; the game
  just runs at the pace of the terminal then." The tick word wraps after
  131 s, longer than any move clock.

### 2.6 Sound

"The only sound an H89 makes is the H19's bell" -- BEL (07H) via `termBell()`.
Rung for: sitting down/join, your turn, game/hand over (all three); Battleship
also invalid move and a sunk ship; Fujitzee two bells for a Fujitzee. All other
sound hooks are empty (`texasHoldEm/src/h89/sound.c`,
`battleship/src/h89/sound.c`, `fujitzee/src/h89/sound.c`). Battleship and
Fujitzee honour `prefs.disableSound` (S key).

### 2.7 App keys

| Creator/app/key | Contents | Who |
|---|---|---|
| 0x0001 / 0x01 / 0 | player name (lobby convention) | all three read and write |
| 0x0001 / 0x01 / 8 | `https://th.carr-designs.com/?table=<id>` | Texas |
| 0x0001 / 0x01 / 5 | Battleship server URL + table | Battleship |
| 0x0001 / 0x01 / 3 | Fujitzee server URL + table | Fujitzee |
| 0xBEBE / 0x01 / 0 | Texas prefs: 3 chars + NUL -- [0] help seen (1/2), [1] colour mode+1 (`texasHoldEm/src/misc.h:53-58`, `misc.c:152-175`) | Texas (its own creator id, "do not reuse 5 Card Stud's 0xE41C") |
| 0xE41C / 5 / 0 | `PrefsStruct` (24 bytes: debugFlag, seenHelp, disableSound, colorMode, reserved[20]) (`battleship/src/misc.h:191-198`) | Battleship (Eric Carr's creator id) |
| 0xE41C / 3 / 0 | `PrefsStruct`: seenHelp, color, debugFlag, localPlayerCount, 4 local player names[9], disableSound, hasPlayed (`fujitzee/src/misc.h:143-155`) | Fujitzee |

All use 64-byte keys (`DEFAULT`). Texas reads keys through
`src/h89/appkey.c` and always NUL-terminates even on failure, because callers
pass the shared `tempBuffer` and `strlen()` it (appkey.c:15-27).

### 2.8 fujinet-lib calls

fujinet-lib as built for the book (`build/fnlib`, fujinet-lib 9e6d4dd,
h89-support). Note that in this library **`fuji_set_appkey_details()` is a
macro** setting three globals and **`fuji_read_appkey()` a macro** for
`fuji_read_appkey_common()` (`build/fnlib/include/fujinet-fuji.h:530-557`).

* **Texas** -- all in platform code:
  * `network_init()` once, on the first request (`texasHoldEm/src/h89/network.c:13-23`)
  * `network_open(url, OPEN_MODE_HTTP_GET_H, OPEN_TRANS_NONE)` (mode 0x0C,
    "GET with headers") (network.c:27)
  * `network_read(url, buffer, max_len)`, `network_close(url)` (network.c:30-31)
  * `fuji_set_appkey_details(creator, app, DEFAULT)`, `fuji_read_appkey()`,
    `fuji_write_appkey()` (`texasHoldEm/src/h89/appkey.c:15-33`)
* **Battleship** -- `-DCUSTOM_FUJINET_CALLS` (Makefile:140-141); the shared
  `stateclient.c`/`misc.c` call `custom_network_call()`,
  `custom_read_appkey()`, `custom_write_appkey()` in
  `battleship/src/h89/fujinet.c`, which calls `network_open(url,
  OPEN_MODE_HTTP_GET, OPEN_TRANS_NONE)`, `network_read`, `network_close`
  (fujinet.c:23-33), `fuji_set_appkey_details`, `fuji_read_appkey`,
  `fuji_write_appkey` (35-49). **Why**: the shared code includes the game's
  own vendored `src/fujinet-fuji.h` (via `standard_lib.h:15`), which declares
  the app key calls as real functions; the H89 library implements them as
  macros, so those prototypes would link against nothing. `src/h89/fujinet.c`
  includes none of the game's headers, only the library's
  `<fujinet-fuji.h>`/`<fujinet-network.h>` (fujinet.c:9-16, from the SMS
  port). No `network_init()` call.
* **Fujitzee** -- also `-DCUSTOM_FUJINET_CALLS` (Makefile:102-103), same three
  hooks in `fujitzee/src/h89/fujinet.c`, here "only so the screen can be sent
  first": each calls `flush()` before the blocking FujiNet call
  (fujinet.c:9-14,21-51). Uses the library's own headers (no vendored copy).
  No `network_init()` call.
* Battleship/Fujitzee `network_open` mode is 0x04 (`OPEN_MODE_HTTP_GET`);
  Texas 0x0C (`OPEN_MODE_HTTP_GET_H`). Both work for a plain GET.
* `network_read()` blocks until `len` bytes or end of data; all three ask for
  `sizeof(Game)` and accept any positive count (TH network.c:30-33, BS
  stateclient.c:65-70, FJ 50-55). Texas's comment: don't read from a channel
  that never opened, `network_read()` would poll status on a dead unit.

---------------------------------------------------------------------------

## 3. Building

### 3.1 Commands

The book builds all three with `tools/games.sh` (copies the trees into
`build/games/<g>`, then for each of `h89-hdos h89-cpm`):

    make -C build/games/<g> FUJINET_LIB=$BOOK/build/fnlib PLATFORMS=<p> <p>

with `PATH=$HOME/Workspace/z88dk/bin:$PATH ZCCCFG=$HOME/Workspace/z88dk/lib/config`
(`tools/games.sh:15,29`). The repos document
`make FUJINET_LIB=$HOME/Workspace/fujinet-lib PLATFORMS=h89-hdos h89-hdos`
(TH Makefile:97-100; BS Makefile:128-129 sets `FUJINET_LIB` itself; FJ
`make h89-hdos` / `make h89-cpm`, Makefile:90-91, 202-206 -- H89 is not in
`PLATFORMS`, so the target must be named).

### 3.2 Compiler and linker flags (from the build logs)

Compile, HDOS (`build-h89-hdos.log`):

    zcc -c -O3 [-DCUSTOM_FUJINET_CALLS] -DUSING_FUJINET_LIB [-Isrc/platform-specific]
        -I$FNLIB/include +hdos -create-app -startup=3 -Cz--abs
        -pragma-define:CLIB_DISABLE_FGETS_CURSOR=1 -D__H89__ -o ... file.c -MMD

Compile, CP/M: `... +cpm -create-app -D__H89__` (the CP/M .mk calls its flag
variable `MSX_FLAGS`, a leftover from the MSX file it was copied from:
`mekkogx/platforms/h89-cpm.mk:8`, the same in all three trees; the CP/M link
also passes `-create-app` twice).
`+hdos -create-app -startup=3 -Cz--abs -pragma-define:CLIB_DISABLE_FGETS_CURSOR=1`
come from `mekkogx/platforms/h89-hdos.mk:8` (identical in all three trees).

Link (all three, both OSes; `H89_LDFLAGS`, TH Makefile:107-112, BS 145-150,
FJ 107-112):

    zcc -m -pragma-define:CRT_ENABLE_STDIO=0 -pragma-define:CLIB_FOPEN_MAX=0
        -pragma-define:CLIB_OPEN_MAX=0 -pragma-define:CLIB_EXIT_STACK_SIZE=0
        -pragma-define:CRT_ENABLE_COMMANDLINE=0  +hdos ... *.o
        -L$FNLIB/r2r/h89-hdos -lfujinet.h89-hdos.lib -o r2r/h89-hdos/<prog>.abs

* No stdio or file handles: "the game talks to the console itself".
* `CRT_ENABLE_COMMANDLINE=0`: no argv (and avoids z88dk's HDOS argv bug,
  Chapter 6).
* `-m` writes the map, so the end of BSS can be checked.
* **No `CRT_ORG_CODE` or `REGISTER_SP`**: the games take z88dk's default HDOS
  load address **4480H** with the stack just under it (`__register_sp =
  $447F`), not the book's 2A80H. The 8.6K between 2280H and 4480H is the
  stack's (Chapter 6 explains the 042200-read-as-octal origin).
* `-O3` everywhere.

### 3.3 Sizes and memory

From the `.map` files (`r2r/h89-*/<prog>.map`):

| Program | File | Code head-end | BSS end (`__BSS_END_tail`) |
|---|---|---|---|
| TEXAS.ABS | 25 K | 44ADH-9111H | **AA3DH** |
| TEXAS.COM | 25 K | 017AH-4D79H | 669EH |
| FBS.ABS | 26 K | 44ADH-91A9H | **AA9BH** |
| FBS.COM | 26 K | 017AH-4E11H | 66FCH |
| FUJITZEE.ABS | 34 K | 44ADH-A726H | **CE46H** |
| FUJITZEE.COM | 34 K | 017AH-638EH | 8AA7H |

* HDOS 2.0's resident part starts at S.SYSM = **EDB1H** on a full-memory H89
  (HDOS says "SYSTEM HAS 56K OF RAM"; the book's MEMPROBE shows it,
  Chapter 6). All three fit there. **All three ran on the book's default HDOS
  boot disk (`build/disks/hdos-fn.h8d`)**; no 64K-CP/M fallback was needed,
  and Fujitzee also ran under the book's 62K CP/M (run game-fj-cpm-1). The
  stack is the 8.6K from 2280H to 447FH, under the program.
* **Fujitzee needs that full-memory H89 under HDOS**: its Makefile checks the
  end of BSS against `H89_HDOS_TOP ?= 0xEDB0` and says "with 48K it is
  $ADB1, too low" (`fujitzee/Makefile:115-119,174-178`; README: "needs a
  64K H89", `fujitzee/README.md:164-167`). Texas (AA3DH) and
  Battleship (AA9BH) end just under ADB1H, so they would fit the smaller
  machine too (by 1.9K and 790 bytes -- not tested).
* Under CP/M all are well inside the 62K TPA (BDOS at D806H on the book's
  62K CP/M) -- Fujitzee ends at 8AA7H.
* Biggest RAM users: the console buffers (Texas 2x2000 + Fujitzee 3x2000 +
  row flags; Battleship 2x1920), `ClientState` (TH 429, BS 509, FJ 599),
  Battleship's `GameState` shadow fields (4x100 + 4x5).

### 3.4 Disks and smoke tests

* HDOS: `r2r-post` strips the 8-byte .ABS header (FF 00, load, length,
  entry), and `z88dk-appmake +hdos -b <prog>.bin --org <load> -o <PROG>`
  makes a 100K H17 data disk `<prog>.h8d` (TH Makefile:164-174, BS 288-297,
  FJ 169-184; FJ first checks the BSS end). Use: `MOUNT SY1:` then
  `RUN SY1:TEXAS.ABS`.
* CP/M: `z88dk-appmake +cpmdisk -f hz89 --container raw --no-com-file
  -b <prog>.com -o <prog>.h8d` (H17, 40 tracks, 3 boot tracks), then
  `python3 -I support/h89/cpm-dir-fixup.py <prog>.h8d` marks the empty
  directory entries appmake leaves zeroed as erased (E5H) (TH Makefile:176-181,
  BS 299-305, FJ 186-191). Use: `B:TEXAS`.
* Smoke tests: `make h89-smoke [H89_OS=hdos] [EXPECT=...] [STEPS=...]
  [SHOT=x.ppm]` -> `support/h89/smoke.sh` in Texas and Fujitzee (not
  Battleship): boots 64K CP/M 2.2.04 or HDOS 2.0 in FujiNet Go H89's
  `h89_session_run` with the in-process FujiNet, the game disk in drive 2,
  waits for EXPECT ("F U J I N E T" / "FUJITZEE") and prints the screen with
  the H19 graphics as Unicode (`texasHoldEm/support/h89/smoke.sh`,
  `texasHoldEm/Makefile:268-290`, `fujitzee/Makefile:208-221`). It notes that
  the runner's `--type` drops control characters, so ESC is sent as
  `--key f1`, which the games take as ESC.

---------------------------------------------------------------------------

## 4. The games

### 4.1 Texas Hold'em (Chapter 17)

**Play.** Up to eight at a table, each starting with 1000 chips; blinds 5/10.
Two hole cards each, five community cards dealt flop (3), turn, river; best
five-card hand wins the pot. On your turn the status line offers the server's
valid moves -- FOLD, CHECK or CALL n, BET/RAISE (two sizes), ALL-IN -- left and
right pick a move, up and down choose between the two raise sizes, RETURN or
SPACE sends it. A countdown and hourglass sit at the right of the status line.
The AI rooms seat 2, 4 or 6 bots (named "... bot") who always play.

**Modules.**

* `src/main.c` -- globals (server, query, name, `ClientState`), the main loop,
  the byte-sum repaint check for the H89 (and Coleco/NES/SMS).
* `src/stateclient.c` -- `apiCall()` builds `N:` + server + path + query +
  `?bin=1` and reads the reply into `clientState`; `getStateFromServer()`
  sends `move/<code>` if a move is pending, else `state`.
* `src/screens.c` -- help, name entry (`inputFieldCycle`), welcome, table
  picker, `showGameScreen()` (draw order: spectator/players changed, chips to
  pot, final flip, pot, street, names/purses, bets, cards, status, highlight),
  in-game menu (Q quit table, H help, C colour, ESC back).
* `src/gamelogic.c` -- seat layout by player count, pot box, street label
  (PRE-FLOP/FLOP/TURN/RIVER/SHOWDOWN), names and purses, bets and last moves,
  card dealing animation and the final flip at showdown, "YOU SIT DOWN AT THE
  TABLE", "A NEW PLAYER JOINS", the move menu (`layoutMoveMenu` folds call and
  raise into one "call/raise n" stop with the amount beside it, so five moves
  fit beside the clock), `requestPlayerMove()` with its countdown.
* `src/misc.c` -- `pause()`, common input decoding (arrows, RETURN/SPACE),
  prefs in app key 0xBEBE/1/0.
* `src/h89/console.c`, `console.h` -- the H19 back-buffer renderer and OS
  console I/O (2.3).
* `src/h89/graphics.c` -- table, cards, chips, logo, status line (below).
* `src/h89/input.c` -- H19 key decoder (2.4).
* `src/h89/network.c` -- `getResponse()` over fujinet-lib.
* `src/h89/appkey.c` -- `read_appkey()`/`write_appkey()` over fujinet-lib.
* `src/h89/sound.c` -- the bell for sit-down, your turn, hand over.
* `src/h89/util.c` -- frame pacing, move timer, `quit()` back to the OS.
* `src/h89/vars.c`, `vars.h` -- 80x25 geometry, card pitch, seat tables
  (`playerXMaster` etc. for 2-8 players), key codes.
* `src/h89/logo.h` -- the title logo as runs of cell codes (row, column,
  length, codes; FFH ends), generated by `src/h89/mklogo.py`. The generator is
  not compiled, so it is not in the listing; logo.h is.

**H89 drawing** (`texasHoldEm/src/h89/graphics.c:1-29`):

* Cards are **6x5**: corners and lines from the graphics set, rank top left
  (`t` -> "10", face letters upper-cased), and a **2x2 suit picture** made of
  triangles and quadrant blocks, since the ROM has no suits
  (graphics.c:53-57):

      spades  ◢◣   hearts ▙▟   diamonds ◢◣   clubs ▗▖
              ▝▘          ◥◤            ◥◤         ●●

  Face-down cards are checkerboard (graphics.c:219-225).
* The H19 is monochrome, so the colour toggle (C) draws hearts and diamonds
  in reverse video instead of red (`cardRev`, graphics.c:181-201).
* The table is an oval rail of diagonals (`x`, `y`) and edge bars, rows 7-17,
  columns 16-63 (graphics.c:41-117); seats outside it, YOU at the bottom
  centre. Other screens get a frame with an ace in each corner
  (`drawBorder`, 325-358).
* Chips are bullets; the pot is a small box below the community cards.
* The status bar is the 25th line; the selected move is shown in reverse
  video. Where other platforms underline (`drawLine`/`hideLine`) the H89
  reverses the text above (the active player's name, the table list header)
  (graphics.c:274-304). The move timer's hourglass is a reversed diagonal
  cross (`drawStatusTimer`, 147-152).
* The title logo: TEXAS / HOLD'EM in quadrant-block letters, two pixels by
  two per cell; pixels are tall because H19 dots are ~2.4x as tall as wide;
  the ROM lacks the "diagonal pair" quadrant so the art must avoid it
  (`mklogo.py:1-40`).
* `disableDoubleBuffer()` makes each draw call flush, so dealing shows card
  by card.

### 4.2 Battleship (Chapter 18)

**Play.** Two to four players (with bots on the AI tables). In the lobby each
player presses SPACE when ready; a countdown starts. Everyone places five ships
(5,4,3,3,2) on a 10x10 field: each ship appears at a random legal spot, arrows
move it, R rotates, RETURN/SPACE places it; when all five are placed the client
sends `place/...`. Then players take turns; on your turn a blinking cursor
appears on every opponent's field at the same square; RETURN fires at that
square on **all** opponents at once. Hits, misses and sunk ships show on each
field and in each player's "fleet drawer". Last fleet afloat wins.

**Modules.**

* `src/main.c` -- globals, ship sizes, main loop with frame-counted polling and
  failure back-off.
* `src/stateclient.c` -- `apiCall()` (`n:` ... `&bin=1&v=2`), `sendMove()`,
  `getStateFromServer()`.
* `src/screens.c` -- help, name entry, welcome, table picker ("choose a game
  to join"), in-game menu (Q quit game, H how to play, S sound), screen
  save/restore around overlays.
* `src/gamelogic.c` -- `processStateChange()` dispatches lobby or board;
  `renderLobby()` (server name, players and "ready" marks, countdown prompt);
  `handleShipPlacement()`; `renderGameboard()` (fields, ships, attack/hit/miss
  animations, sinking in the drawer, active player badge, game over message);
  `processInput()` (ready toggle, your turn); `waitOnPlayerMove()` (cursor,
  timer, attack); `inputFieldCycle()`.
* `src/misc.c` -- input decoding, prefs, app key helpers (calling the custom
  hooks on the H89).
* `src/standard_lib.h` -- the one place standard headers are included per
  compiler; on the H89 declares the game's own `kbhit()`/`cgetc()`.
* `src/h89/console.c` -- the H19 shadow renderer and OS console I/O.
* `src/h89/graphics.c` -- boards, ships, cursor, drawers, badges (below).
* `src/h89/input.c` -- key decoder behind `kbhit()`/`cgetc()`.
* `src/h89/fujinet.c` -- the `CUSTOM_FUJINET_CALLS` hooks.
* `src/h89/sound.c` -- the bell (join, your turn, game over, invalid, sunk).
* `src/h89/util.c` -- 50 Hz frames, timer, random numbers, `quit()`.
* `src/h89/vars.h` -- 80x24, icons, key codes, H89 wording ("press SPACE when
  ready", "ESC").

**H89 drawing** (`battleship/src/h89/graphics.c:1-96`):

* The layout is the Adam's 32x24 one with **every board cell two characters
  wide** -- H19 dots are about twice as tall as wide, so two characters make a
  near-square cell. Row 0 name badges of the top boards, rows 1-10 top fields,
  row 11 shared divider, rows 12-21 bottom fields, row 22 bottom badges, row 23
  status (connection, timer, clock). Fields are 20 columns at column 18 and 42,
  or 30 when there are only one or two players (`SHIFT_1V1`).
* Water is blank; a miss is `()` "a centred circle"; a hit is a pair of
  reversed diagonal crosses; sunk/second hit frame checkerboard.
* Hulls are half a cell thick: horizontal ones use the lower half-row on the
  top boards and the upper half on the bottom ones (so they never touch a
  badge or the divider), vertical ones the middle half of the two columns; bow
  and stern from quadrant blocks (graphics.c:68-85).
* The attack animation: `><`, `\/`, `XX`, reversed `XX`, checkerboard, a
  reversed flash (graphics.c:87-95).
* The fleet drawer beside each field shows the ships left (sunk ones as
  checkerboard).
* Name badges "-- name ----", the active player's in reverse video with a
  bullet; the cursor on open water pulses `[ ]`.
* Players run clockwise from the bottom left; you are always bottom left.

### 4.3 Fujitzee (Chapter 19)

**Play.** A Yahtzee-style dice game, up to six at a table, 13 rounds. Each turn
the server rolls five dice; you may re-roll any of them twice (left/right moves
the dice cursor, RETURN/SPACE toggles keep on a die, RETURN on ROLL! rolls),
then pick a score category (up moves into the score column, up/down chooses
among the valid ones, RETURN scores). Upper bonus 35 at 63; full house 25,
short run 30, long run 40, Fujitzee (five of a kind) 50. Highest total wins.
"P" on the table screen adds up to four **local players** sharing one H89
(hot seat) -- each gets its own query, with `pov=` the first player
(`fujitzee/src/screens.c:226-289,670-692`; `apiCallForAll`,
`stateclient.c:67-72`).

**Modules.**

* `src/main.c` -- globals, main loop (poll, animate, input).
* `src/stateclient.c` -- `apiCall()`, `sendMove()`, `apiCallForAll()` (one
  call per local player), `getStateFromServer()` which also works out which
  local player is active.
* `src/screens.c` -- two-page help, local player setup, name entry ("your name
  must be at least 2 letters", duplicate check), welcome, table picker, in-game
  menu.
* `src/gamelogic.c` -- `renderBoardNamesMessages()` (lobby "ready" list or
  the board: names with aliases, scores, valid-score hints, prompt),
  `handleAnimation()` (dice roll animation, Fujitzee bells), `processInput()`
  (ready toggle, your turn), in-game help box ("it's your turn ...", shown on
  the first turn ever: `prefs.hasPlayed`), `waitOnPlayerMove()` (dice cursor,
  keep/roll, score cursor, timer, auto-score on time-out), `inputFieldCycle()`.
* `src/misc.c` -- input decoding, prefs (0xE41C/3/0), app key helpers.
* `src/h89/console.c` -- the back-buffer renderer with `conSave/conRestore`.
* `src/h89/graphics.c` -- board, dice, cursor, tab, frame (below).
* `src/h89/input.c` -- key decoder; `kbhit()`/`cgetc()` also flush the screen.
* `src/h89/fujinet.c` -- custom hooks that flush first.
* `src/h89/sound.c` -- the bell (join, your turn, Fujitzee x2, game over).
* `src/h89/util.c` -- 60 Hz frames (flushing), move clock in 50ths,
  `sizeof(Game)==599` check, `quit()`.
* `src/h89/vars.h` -- 80x25 layout macros for the board (score column
  positions, die positions, help box), icons, key codes.

**H89 drawing** (`fujitzee/src/h89/graphics.c:1-31`, `vars.h:6-22`):

* The 40-column board widened to 80: score names in full in a box at columns
  11-23 ("ONES" ... "COUNT", "FUJITZEE" in reverse lower/upper style), then six
  player columns eight wide between dividers at 23, 32, ... 77; rules at rows
  0, 2, 9, 12, 20.
* Lines are drawn by direction (`line()`, `glyphBits[]`, `lineGlyph[]`): where
  two meet, the cell becomes the right corner, T or cross by itself
  (graphics.c:83-240).
* **Dice are 7x3** -- square on the H19's tall cells: a free die is a solid
  reverse-video block with dark bullet pips; a kept die is hollow -- bright
  pips between edge bars (graphics.c:383-433). The ROLL! button is the same
  size with a dot per roll left, checkerboard when nothing is left to roll.
  The dice cursor is a bracket in the gap columns either side.
* The active player's column header is a reverse-video tab, kept through
  every redraw by `cell()` (graphics.c:113-125).
* Text is all capitals; "alternate" text puts lower-case letters in reverse
  video (so the shared code's "fujiTZEE" style shows FUJI reversed + TZEE).
* Bordered screens have a die in each corner and a frame between them.
* The hourglass (timer) is a reversed diagonal cross; the connection icon a
  reversed X and "?".

---------------------------------------------------------------------------

## 5. Licences

* **Texas Hold'em**: `LICENSE` = GNU GPL v3 (29 June 2007)
  (`texasHoldEm/LICENSE`); `main.c` header "@license gpl v. 3".
* **Battleship** and **Fujitzee**: **no LICENSE file** in the repository (none
  in any commit). The sources say "@license gpl v. 3" (`battleship/src/main.c:4`,
  `fujitzee/src/main.c:4`) and the H89 files "gpl v. 3, see LICENSE for
  details" -- which points at a file that is not there. The book should state
  GPL v3 from the headers and perhaps note the missing file (or Thom adds one
  upstream).
* Battleship's vendored `src/fujinet-network.h`: "FujiNet Network Device
  Library, @license gpl v. 3".

---------------------------------------------------------------------------

## 6. Screens

Twelve screens were captured against the live servers, all under HDOS. Each one
is described in `data/games/screens.md`, which also says which run made it.

* **Texas.** `texas-1` title and name entry, `texas-2` table list,
  `texas-3` the flop with THOM to act (the move menu and countdown on the
  25th line), `texas-4` showdown with the winner's cards turned up and
  `lastResult` on the status line.
* **Battleship.** `battleship-1` table list, `battleship-2` lobby (everyone
  ready, "starting in 2"), `battleship-3` five ships placed ("waiting on
  others to place"), `battleship-4` game in progress. Only three boards show,
  because the server's ai3 table had lost a bot.
* **Fujitzee.** `fujitzee-1` table list on the bordered screen, `fujitzee-2`
  lobby, `fujitzee-3` first turn with the in-game help overlay and score
  hints, `fujitzee-4` round 5 with two kept (hollow) dice and the dice cursor.

Screens each game has that were not captured:

* **Texas.** The help screen, the in-game menu, and "TABLE FULL: WATCHING AS
  A SPECTATOR".
* **Battleship.** The help screen, the in-game menu, and game over (the
  winner's ships shown, the message on the bottom line).
* **Fujitzee.** The two help pages, local player setup, the in-game menu,
  and game over.

### Things the screens show that the text should explain

* Reverse video stands in for colour. In Texas the colour toggle C reverses
  hearts and diamonds. In Battleship and Fujitzee `drawTextAlt` reverses
  letters, so "FUJI battleship" and "FUJITZEE" both have FUJI in reverse.
* Lower-case server strings. Texas and Battleship print them as they come,
  e.g. "ai room - 6 bots" and "jim bot won with two pair". Fujitzee
  upper-cases every character it draws.
* Texas's status bar is on the 25th line (ESC x 1). Battleship leaves the
  25th line off and uses row 23. Fujitzee uses the 25th line for the menu.
