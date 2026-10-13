#import "../lib.typ": *
#import "../prog.typ": *

#chapter(16, "The Network Games")

#section("General")[
Three games close this Manual: *Texas Hold'em*, *Battleship* and *Fujitzee*, a dice game. Each is
played at a table on a server on the Internet, against other people --- on H89s, Ataris, Apples,
Commodores, IBM PCs, anything with a FujiNet --- and against the server's own robot players when
there are not enough people. They are Eric Carr's games, written once in C for every computer the
FujiNet serves, with a small part written again for each; this Manual's author wrote the H89's
part.

They are the largest C programs in this Manual, about 4,000 lines each, and the following three
chapters list them in full. This chapter explains what they have in common: how a game finds a
table and talks to its server, how the shared code meets the H89, and how to build them.
]

#section("The Game System")[
#sub("The servers")
Each game has its own server, a small Go program that keeps every table in memory: Texas Hold'em at
`th.carr-designs.com`, Battleship at `battleship.carr-designs.com`, Fujitzee at
`fujitzee.carr-designs.com`. A server runs the game. It deals, rolls, keeps score, moves its robot
players, and advances the game every couple of seconds by the clock; the clients only show what the
server says and send what the player chooses. So a game cannot be cheated from the client, and an
H89 at 2 MHz keeps up with a modern PC.

#sub("The calls")
Everything is an HTTP GET to the server, built the same way by all three games:

#code("N: + server + path + ?table=ai2&player=thom + &bin=1")

#stable((0.9in, 1fr), size: 7.6pt,
  th[Path], th[Does],
  [`tables`], [lists the server's tables, with how many players each has],
  [`state`], [seats the player at the table if need be, and returns the game as it stands],
  [`move/ca`], [Texas Hold'em: a move (fold, check, call, bet, raise, all-in)],
  [`ready`], [Battleship, Fujitzee: ready to start],
  [`place/...`], [Battleship: where the five ships are],
  [`attack/n`], [Battleship: fire at square n],
  [`roll/01101`], [Fujitzee: roll again the dice marked 1],
  [`score/n`], [Fujitzee: score the dice in category n],
  [`leave`], [leave the table],
)

There is no "join" call: any request that names a table and a player seats that player. A move's
reply is the new state, so it takes the place of the next poll.

#sub("Binary replies")
With `bin=1`, the servers answer not in JSON but in a fixed layout of bytes, the same as the game's
C structure on a little-endian computer like the Z80. The client reads the reply straight into its
structure with `network_read()`, and has no parsing to do at all --- which saves an 8-bit computer a
great deal of time and memory. Strings come in fixed lengths, padded with zeros, and in lower case.
Fujitzee checks at compile time that its structure is the size the server sends:

#code("typedef char game_wire_size_check[(sizeof(Game) == 599) ? 1 : -1];")

#sub("Polling")
No server can call the H89, so every client polls: it asks for `state` every second or two, and
draws what changed. Texas Hold'em polls back to back and repaints only if a checksum of the reply
has changed; Battleship and Fujitzee poll about once a second.

#sub("Names, and finding a table")
On other computers a *lobby* program lists the game servers and starts the game; the H89 has no
lobby program yet, so each game asks its own server for its tables. All three keep the player's name
in the app key the lobby uses (creator 0001H, application 01H, key 00H, Chapter 8), and the last table
in another, so a game can go back to it.
]

#section("How the Code Is Arranged")[
Each game's source is a shared part, used on every computer, and a part for each computer:

#code("src/*.c, *.h                the game: main loop, logic, screens, server
src/platform-specific/*.h   what each computer must supply
src/h89/                    the H89's part
mekkogx/                    the shared build system")

The interface the H89's part supplies is small: graphics (the screen, text, cards, boards, dice),
input (keys), sound, a timer, and in Texas Hold'em the network and app key calls. Everything in
`src/h89/` is wrapped in `#ifdef __H89__`, which both H89 builds define.

#sub("The H19 console")
The shared code thinks in characters on a grid, which suits the H19. Each game keeps a picture in
memory of what the terminal shows, one byte per cell --- the H19's own character number, with the
top bit for reverse video --- and sends only the cells that change, since the H19 is a terminal on a
9600-baud line and can take fewer than a thousand characters a second. Texas Hold'em and Fujitzee
draw into a second picture and compare whole rows before sending, which lets them clear the screen
with `ESC E` when that is cheaper; Battleship compares cell by cell.

The renderer tracks what the terminal is doing --- cursor position, reverse video, graphics mode ---
and sends `ESC Y`, `ESC p`/`q` and `ESC F`/`G` only when they must change. Graphics mode remaps only
the characters 5EH to 7EH, so text below 5EH never forces a change. The cards, ships, dice and frames
are drawn entirely in the H19's graphics characters (the Appendix shows them).

Under HDOS the console is put in raw character mode, with no echo and no case mapping (the graphics
characters are sent as lower-case letters); under CP/M the games call the BIOS's console routines
directly. The book's `h89con.c` (Chapter 6) is the same code, made smaller.

#sub("The keyboard")
The H19 sends its arrow and function keys as escape sequences, back to back at 9600 baud. The
games put the keypad in shifted mode (`ESC t`), so its arrows send `ESC A` to `ESC D`, and take an
ESC with nothing behind it within 20 ms as the ESC key itself.

#sub("Time and sound")
The shared code counts sixtieths of a second; the H89's clock counts 2 ms ticks (Chapter 2), so a
"frame" is 8, 8 and 9 ticks in turn. The only sound an H89 makes is the H19's bell, rung when you sit
down, when it is your turn and when a game ends.
]

#section("fujinet-lib in the Games")[
The games use only a handful of fujinet-lib's functions:

- `network_open()` (mode 4 or 12), `network_read()` and `network_close()`, for every request;
- `fuji_set_appkey_details()`, `fuji_read_appkey()` and `fuji_write_appkey()`, for the name and
  preferences.

Battleship and Fujitzee are built with `CUSTOM_FUJINET_CALLS`, which routes these through three
functions in `src/h89/fujinet.c`. Battleship needs it because its shared code includes its own copy
of fujinet-lib's headers, which declare the app key calls as functions where the H89's library has
macros; Fujitzee uses it to draw the screen before each call, so "refreshing" shows while the request
is out.
]

#section("Building the Games")[
Each game builds with its own Makefile, given the H89 platform and fujinet-lib (Chapter 6):

#code("make FUJINET_LIB=$HOME/fujinet-lib PLATFORMS=h89-hdos h89-hdos
make FUJINET_LIB=$HOME/fujinet-lib PLATFORMS=h89-cpm  h89-cpm")

The programs (`texas.abs`, `fbs.abs`, `fujitzee.abs`, and `.com` for CP/M) and 100K H17 disk images
holding them are left in `r2r/h89-hdos/` and `r2r/h89-cpm/`.

The games link with no standard I/O and no file handles (they talk to the console themselves), and
with `CRT_ENABLE_COMMANDLINE=0`, which also keeps clear of z88dk's HDOS command-line fault. They take
z88dk's default HDOS load address, 4480H, with the stack below it: wasteful, as Chapter 6 says, but
harmless.

#stable((0.9in, 0.5in, 0.85in, 1fr), size: 7.6pt,
  th[Program], th[Size], th[Ends at], th[Needs],
  [TEXAS.ABS], [25K], [AA3DH], [HDOS, 48K or more (not tried in 48K)],
  [FBS.ABS], [26K], [AA9BH], [HDOS, 48K or more (not tried in 48K)],
  [FUJITZEE.ABS], [34K], [CE46H], [HDOS on a full-memory H89],
  [TEXAS.COM], [25K], [669EH], [CP/M],
  [FBS.COM], [26K], [66FCH], [CP/M],
  [FUJITZEE.COM], [34K], [8AA7H], [CP/M],
)

Fujitzee is the largest because it keeps three pictures of the screen, 2,000 bytes each. Its Makefile
checks that it ends below EDB0H, where HDOS's resident part begins on a full machine.

#note[Texas Hold'em and Fujitzee each have a smoke test, `make h89-smoke`, which boots the game in
FujiNet Go H89 and checks its first screen.]

#note[Fujitzee's H89 port was not yet committed to its repository when this Manual was made: its
listing is of the working tree, as it then stood.]
]

#section("Licences")[
The games are free software, under the GNU General Public License, version 3: Texas Hold'em's
repository carries the licence; Battleship's and Fujitzee's say so in every source file's heading.
]
