# Screens for Chapters 16-19

All were captured on the book's rig with `tools/runprog.sh`. The rig boots the
HDOS 2.0 disk `build/disks/hdos-fn.h8d`, puts the game on the SY1: data disk,
and runs fujinet-pc on the same PC. The games played against the **live**
servers (th./battleship./fujitzee.carr-designs.com) on 12-13 October 2026.
Every screen was kept with
`python3 tools/keepscreen.py RUN NAME 'Dummy Cafe=Workshop' 'TMA-3=FujiNet'`.
That made no replacements, because none of these screens shows the network.

The player is THOM, who typed the name on the first screen. Every table seats
the server's bots ("clyd bot", "meg bot", "1AI CLYD" ...), so each game is
THOM against the house. Each run is in `build/runs/<RUN>/`, which holds
screen.ppm, screen.txt, tap.jsonl, fujinet.log and emu.log.

Some screens come from a picture taken partway through a run (`--ppm` as an
extra step) rather than from its last screen. Each of those has its own small
directory, `build/runs/<RUN>-<what>/`, holding the picture as screen.ppm, its
`ppm2cells` screen.json, and a SOURCE.txt that says where it came from.

## Texas Hold'em (Chapter 17)

| Screen | Run | What it shows | What to say |
|---|---|---|---|
| `texas-1` | game-texas-hdos-1 | **Title and name entry.** The bordered screen: a frame with diagonal-cut corners and an ace of each suit in the corners (spades and hearts at the top, diamonds and clubs at the bottom). Below that, the TEXAS / HOLD'EM logo in quadrant blocks, the "F U J I N E T" rule, and ENTER YOUR NAME with THOM typed and a bullet as the cursor. | On the first run app key 1/1/0 is empty, so the game asks for a name (2-8 characters) and saves it there for every lobby game. The ROM has no suit characters, so each suit is a 2x2 picture made of triangles and quadrants. |
| `texas-2` | game-texas-hdos-2 | **CHOOSE A TABLE TO JOIN.** The five tables from `GET tables?bin=1`: ai room - 6 bots (0 / 2), ai room - 4 bots (0 / 4), ai room - 2 bots (0 / 6), the den (0 / 8), the basement (0 / 8). A bullet marks the first table and the header is in reverse video. The 25th line holds the menu: R-EFRESH H-ELP C-OLOR N-AME Q-UIT. | Table names arrive in lower case because the server lower-cases every fixed-length string. Players are shown as humans / human seats, and human seats = 8 - bots. Up and down move the bullet, RETURN joins. |
| `texas-3` | game-texas-hdos-3 | **A hand at the 6-bot table, on the flop, with THOM to act.** Six bots sit around the oval rail. Their cards are face-down checkerboard, and a folded seat is down to one card. Each seat shows its purse beside a bullet chip, and its last move on the felt (fold, check, bet 10). In the middle are the flop (3, 9 and 5 of hearts), FLOP, and the pot box (55). At the bottom are THOM's 5 of spades and 7 of clubs, with YOU and 990. The status line reads `fold  call/raise  10  all-in`, with **call** in reverse video and the countdown `32` and hourglass at the right. | On the H89 the status line folds CALL and RAISE into one stop, so five moves fit beside the clock. Left and right pick a move, up and down choose the raise size, and RETURN sent `move/ca`. The whole table is redrawn on every poll, but only the cells that changed go down the 9600-baud line. |
| `texas-4` | game-texas-hdos-5-s22 (the 22nd of 42 pictures taken every 3 s in run game-texas-hdos-5) | **Showdown.** Jim bot's 7 and 8 of diamonds are turned up. The board is J clubs, J hearts, 8 hearts, 6 hearts, K clubs, with SHOWDOWN beside the pot (65). THOM has the Q of diamonds and 2 of clubs. The 25th line gives the server's `lastResult`: "jim bot won with two pair, jacks over eights, kicker king". | At round 5 the server shows every hand still in, and `checkFinalFlip()` turns the cards over one seat at a time. In this run THOM only ever pressed RETURN, which calls or checks. |

## Battleship (Chapter 18)

| Screen | Run | What it shows | What to say |
|---|---|---|---|
| `battleship-1` | game-bs-hdos-2-tables (from run game-bs-hdos-2) | **"choose a game to join".** The FUJI battleship logo box, with FUJI reversed. The tables are high seas, cape fuji, ai - 3 bots, ai - 2 bots and ai - 1 on 1, all "0 / 4", and the arrow cursor is on ai - 3 bots. Below them are "HELLO thom" and the menu Refresh Help Name Quit, with the initials reversed. | Battleship lower-cases the name it saves. Reverse video stands in for the other platforms' second colour (`drawTextAlt` reverses the capitals). The cursor arrow blinks, which is why game-bs-hdos-1, taken at the wrong moment, has no arrow. |
| `battleship-2` | game-bs-hdos-2-lobby (from run game-bs-hdos-2) | **The lobby of "ai - 3 bots".** thom, clyd bot, meg bot and kirk bot are all "ready", with "starting in 2" below them. At the bottom are "press ESC for menu" and "press SPACE when ready". | SPACE toggles ready (`GET ready`). One human plus bots starts on a 3-second countdown, and the prompt comes from the server. The screen polls about every 2 s here. |
| `battleship-3` | game-bs-hdos-3-placed (from run game-bs-hdos-3) | **All five ships placed, with "waiting on others to place".** One field is shown, moved to the middle, with the empty fleet drawer at its left. The five hulls are half a cell thick: four upright and one lying flat. | Each ship appears at a random legal square. Arrows move it, R rotates it, and RETURN places it. After the fifth the client sends `place/102,72,147,114,179`, where each number is dir*100 + y*10 + x. Every field cell is two characters wide, because H19 cells are tall. |
| `battleship-4` | game-bs-hdos-3 | **The game in progress.** At the top left is clyd bot's field, whose badge is in reverse video with a bullet because it is clyd bot's turn. At the top right is meg bot's field, and THOM's ("you") is at the bottom left. Misses are `()` and hits are reversed X pairs. Each fleet drawer shows the ships left, and a sunk ship in THOM's drawer is checkerboard. THOM's own hulls show on his field, with hits on them. | One attack fires at the same square on every opponent's field. The H89 cursor pulses `[ ]` on open water. **Only three boards:** this table had lost its third bot on the server (see notes.md 1.6), so the bottom-right quadrant, where a fourth player would sit, is empty. A second run (game-bs-hdos-4) came out the same way. |

## Fujitzee (Chapter 19)

| Screen | Run | What it shows | What to say |
|---|---|---|---|
| `fujitzee-1` | game-fj-hdos-1 | **CHOOSE A GAME TO JOIN.** The bordered screen has a 7x3 die in each corner and a frame between them, which joins the FUJITZEE logo box by itself. The tables are AI ROOM - 4 BOTS (selected, so the whole row is reversed), AI ROOM - 2 BOTS, KITCHEN TABLE and THE BAR, all "0 / 6". Below them are HELLO THOM and PRESS P TO ADD LOCAL PLAYERS, and the menu REFRESH HELP PLAYERS QUIT. | All text is in capitals. "Alternate" text reverses the letters the other platforms draw in lower case, so FUJI is reversed and TZEE is not. Lines are drawn by direction, so wherever two meet the cell becomes the right corner, T or cross by itself. P adds up to four local players for hot-seat play. |
| `fujitzee-2` | game-fj-hdos-2-lobby (from run game-fj-hdos-2) | **The lobby of AI ROOM - 4 BOTS.** THOM, who is not ready yet, has the marching arrow. 1AI CLYD, 2AI MEG, 3AI KIRK and 4AI JIM are READY, in reverse video. Below are WAITING FOR EVERYONE TO READY UP and PRESS SPACE TO TOGGLE. | The digit in front of each bot's name is its one-letter alias, which heads its column on the board. |
| `fujitzee-3` | game-fj-hdos-4-h2 (from run game-fj-hdos-4, 9.5 s after YOUR TURN first showed) | **THOM's first turn (round 1), with the in-game help box laid over the bots' columns.** The box reads "IT'S YOUR TURN / MOVE UP/DOWN TO CHOOSE A SCORE ... MOVE LEFT/RIGHT, AND PICK DICE TO KEEP, THEN ROLL." THOM's column, under its reversed T tab, shows the possible scores in reverse: ONES 2, TWOS 2, FOURS 8, COUNT 12. At the bottom are the ROLL! button with two dots for two rolls left, and five solid dice (2 4 4 1 1) with the bracket cursor round the first. YOUR TURN THOM is at the left. | The help box appears only on the very first turn (`prefs.hasPlayed`). It is saved and put back with `conSave()`/`conRestore()`, the third 80x25 buffer. An earlier attempt (game-fj-hdos-3 turn1.ppm) caught the box half-drawn, which shows how long a 17-row overlay takes at 9600 baud. |
| `fujitzee-4` | game-fj-hdos-3 | **Round 5, THOM's turn, with two dice kept.** The board shows every player's scores. THOM has SHORT RUN 0, LONG RUN 0, COUNT 16 and FUJITZEE 0, from scoring the lowest open box each turn (`score/14`, `/13`, `/12`, `/11`). His possible scores are reversed: ONES 1, THREES 3, FIVES 15, SET OF 3 19. Bot 4's new SHORT RUN 30 is reversed as the latest score. In the dice row, ROLL! comes first, then two **kept (hollow)** dice (3 and 1) with the bracket cursor on the second, then three free (solid) fives. | A kept die is hollow, showing bright pips between edge bars, and a free die is a solid reversed block with dark pips. RETURN on a die toggles keep, and RETURN on ROLL! sends `roll/00111` (1 = re-roll). Up moves into the score column, and RETURN sends `score/N`. |

## Also run, not kept

- **game-fj-cpm-1.** Fujitzee under 62K CP/M (`FUJITZEE.COM` from B:), as far as the table list. It works the same as under HDOS. Its list showed "● 1 / 1" on AI ROOM - 4 BOTS: THOM from an earlier run was still seated.
- **game-texas-hdos-4.** Waited for SHOWDOWN after its keys ran out and timed out. It did show that the client sends CALL/CHECK by itself when its countdown ends.
- **game-bs-hdos-1.** The table list without the cursor arrow, taken during the blink. game-bs-hdos-4 was a second three-board game.
- Between runs, the THOM left over on a table was sent `GET leave?table=..&player=thom` with curl, so that the next run started in the lobby (see notes.md 1.6).
