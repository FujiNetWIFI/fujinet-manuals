# Figures

Every figure is a screenshot, or a piece of one, from the edition it appears in. They are made in the game repo by `screenshots/make-shots.sh`, which runs each client's offline test mode in an emulator (MAME, openMSX, jzIntv, asim), and copied here by `make assets` (`tools/pull_assets.py`).

| Scene | Where in the guide |
|---|---|
| 01-title | cover |
| 02-lobby | The Colony Room; Meet the Colonists (first four species) |
| 17-species-b | Meet the Colonists (the other four species) |
| 03-summary | step 1, The Summary Report (Intellivision: also the first four species) |
| 04-transport-ship | step 2 |
| 05-land-grant | step 3 |
| 06-land-auction-show | step 4; the source of the land icons |
| 07-land-auction-bidding | step 5 |
| 08-develop-town | step 6, Development |
| 09-develop-map | The Land; step 8, Installing Your M.U.L.E. |
| 10-player-event | Random Events |
| 11-production | Production |
| 12-colony-event | The Colony Event |
| 13-goods-status | Player Status |
| 14-declare | Declaring |
| 15-trading | Trading |
| 16-game-over | Winning |

**Land icons** (`assets/<target>/icons/`) are single plots cut from 06-land-auction-show by plot number. Each target's plot grid is listed in `tools/pull_assets.py`. On the test board (`clients/mekkogx/src/teststart.c`) the plots are:

| Icon | Plot |
|---|---|
| plains | 2 |
| river | 31 |
| mountains ×1 / ×2 / ×3 | 25 / 5 / 15 |
| town | 22 |
| Food | 10 |
| Energy | 12 |
| Smithore | 20 |
| Crystite | 34 |

The Atari 2600 has no offline mode, so its icons are rendered from `clients/atari-2600/tools/mulemap.py`, the model of the cartridge's map composer.

**Missing screens** are left out, never replaced by another machine's:

| Target | Missing | Why |
|---|---|---|
| CoCo, Adam | 04 (transport ship) | the ship has gone by the time the screen is drawn |
| Intellivision | 02 (lobby) | its test mode has no lobby, so the summary screen stands in |
| Atari 2600 | 01, 04, 14, 17 | its screens come from a live game |

**MS-DOS** shows the PCjr's 16-colour screens. The CGA versions of the lobby, the town and the map appear beside them.
