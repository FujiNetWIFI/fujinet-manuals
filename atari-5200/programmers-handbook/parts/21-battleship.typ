#import "../lib.typ": *
= Battleship <ch-bs>

FujiNet Battleship is a sea battle for up to four players, on any mix of computers and consoles a FujiNet serves. The game itself lives on a server. Each client sends the player’s moves as HTTP requests and draws the state the server sends back, so a 5200 can sink an Apple II’s fleet. The 5200 client is the same program as every other client with a thin layer for the console under it.

#shots("bs-place", "bs-game", caption: [Placing the fleet, and the battle against a bot on the bench’s own server. The board at the top is the bot’s, the one below is yours.])

#sect[How the code is laid out]

#tbl((auto, 1fr),
  th[Where], th[What],
  [`src/*.c`], [The game, shared by every client: `main.c` (the loop), `stateclient.c` (the server), `gamelogic.c` and `screens.c` (what to draw and when).],
  [`src/platform-specific/`], [The interface each client implements: graphics, input, sound, appkeys.],
  [`src/atari5200/`], [The 5200’s implementation, guarded by `BUILD_ATARI5200`.],
  [`mekkogx/`], [The build: `make PLATFORMS=atari5200 atari5200` makes `r2r/atari5200/fbs.bin`.],
)

The 5200 layer is about 1,400 lines:

#tbl((auto, 1fr),
  th[File], th[What it does],
  [`graphics.c`, `charset.s`], [The Atari 8-bit client’s screen: ANTIC mode 4, 40 × 26, in the 8-bit client’s character set, with players for the target cursors (@ch-antic).],
  [`input.c`], [The stick, the buttons and the keypad, turned into the key codes the shared code expects.],
  [`osk.c`], [An on-screen keyboard for the player’s name.],
  [`sound.c`], [POKEY effects for shots, hits and turns.],
  [`fujinet.c`], [Every call into fujinet-lib: the network, the appkeys, and the lobby.],
)

#sect[Talking to the server]

The shared code builds a URL from the server’s address and a query, and the 5200 layer fetches it: one OPEN, one READ of everything that arrives, one CLOSE. The server answers in a packed binary form when asked (`bin=1`), which the shared code reads straight into a struct.

#ex((path: "listings/battleship/atari5200/fujinet.c", from: "int16_t custom_network_call", to: "uint16_t custom_read_appkey"), t-c)

`fujinet.c` is the only file that includes fujinet-lib’s headers, because on the 5200 most of the library’s FUJI calls are macros over its bus call; the shared code reaches it through hooks (`CUSTOM_FUJINET_CALLS`).

#sect[Which server]

The address comes from an appkey: creator 1, app 1, key 5, which the FujiNet Lobby writes before it boots the game, holding `server?query`. With no key, the game uses `https://battleship.carr-designs.com/`. The bench in this handbook writes the key itself, pointing at a copy of the server running locally:

```
printf 'http://127.0.0.1:8781/?table=ai1' > SD/FujiNet/00010105.key
```

`ai1` is the server’s table with one bot, so the game starts at once.

#sect[The screen in RAM]

The 8-bit client draws in ANTIC mode 4 with a character set it rewrites as the boards change. On the 5200 nothing in the cartridge window can be rewritten, so all of it lives in the top 4K of RAM, which the build reserves with `__RESERVED_MEMORY__=0x1000`:

#tbl((auto, 1fr),
  th[Address], th[What],
  [`$3000`], [The character set, copied from ROM at start-up (1K-aligned for `CHBASE`).],
  [`$3400`], [The screen, 40 × 26 = 1040 bytes.],
  [`$3800`], [Player/missile memory, single-line (2K-aligned for `PMBASE`).],
)

#sect[The controls]

The stick moves the cursor; one button fires or places a ship, the other rotates a ship or goes back; the keypad answers the screens’ questions. `input.c` folds them all into key codes behind the `kbhit()` and `cgetc()` the shared code calls.

#ex((path: "listings/battleship/atari5200/input.c", from: "#include \"../platform-specific/graphics.h\"", skip: 2, to: "#define REG(a)"), t-c)

#note[The game calls the button it reads through `SKSTAT` the “lower fire” and `TRIG0` the top one. MAME, the Atari800 emulator and the 1982 Owner’s Manual put `TRIG0`, the fire button for every game, at the bottom (@ch-pads). On a real controller, believe the controller.]

#sect[Building it]

The game’s Makefile builds the 5200 client against fujinet-lib-experimental’s `atari5200` target, which still carries its own start-up code:

```
git clone https://github.com/FujiNetWIFI/fujinet-battleship.git
cd fujinet-battleship
make PLATFORMS=atari5200 atari5200 FUJINET_LIB=<fujinet-lib-experimental>
```

`make atari5200-smoke` and `make atari5200-play` run it in MAME, headless or in a window, through the game’s own `support/atari5200/smoke.lua`, which this handbook used for the pictures.
