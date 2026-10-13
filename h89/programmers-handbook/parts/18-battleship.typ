#import "../lib.typ": *
#import "../prog.typ": *

#chapter(18, "Battleship")

#section("General")[
Battleship is the old pencil-and-paper game for two to four players. Each hides five ships on a
ten-by-ten sea --- of five, four, three, three and two squares --- and the players take turns firing
at a square. On the FujiNet's version a shot goes at *every* other player's sea at once, and the last
fleet afloat wins. The program is FBS.ABS for HDOS and FBS.COM for CP/M.
]

#section("Playing", balance: false)[
#steps(
  [Run FBS, give your name if it asks, and choose a table. The "AI" tables have robot players.],
  [In the lobby, press SPACE when you are ready. When everyone is, a countdown starts.],
  [Place your ships: each appears at a random place; the arrow keys move it, R turns it, and RETURN
   puts it there.],
  [On your turn a cursor blinks on every opponent's sea at the same square: move it, and RETURN
   fires. Hits, misses and sunk ships show on each sea and in each player's "drawer" of ships.],
  [ESC opens the menu: Q leaves, H tells how to play, S turns the bell off.],
)

#pictorial(caption: [Choosing a game to join.], crt("battleship-1"))
#pictorial(caption: [The lobby: one player and three robots, all ready, and the countdown.],
  crt("battleship-2"))
#pictorial(caption: [Your five ships placed, half a square thick, waiting for the others.],
  crt("battleship-3"))
#pictorial(caption: [A game in progress, against two robots: misses are `()`, hits reversed crosses,
and the badge of the player whose turn it is is in reverse video.], crt("battleship-4"))
]

#section("How It Works")[
#sub("The state")
Battleship asks for `state` about once a second, with `&bin=1&v=2`. The reply is the `Game`
structure; in the lobby the same bytes are read as a `Lobby` (the table's name and who is ready):

#fields-table(
  [0], [1], [How many players (you are 0).],
  [1], [33], [The prompt to show.],
  [34], [1], [The game's status: 0 lobby, 1 place ships, 10 start, 11 miss, 12 hit, 13 sunk, 99
    over.],
  [35], [1], [Your status: playing, defeated, watching, ready, or place your ships.],
  [36], [1], [Whose turn.],
  [37], [1], [Seconds left to move.],
  [38], [1], [The square last fired at.],
  [39], [10], [Your ships (and, at the end, the winner's): square + 100 if down.],
  [49], [115 each], [Each player: name, status, the sea (100 squares: untried, hit, miss), and which
    ships are left.],
)

Ships are placed with `place/a,b,c,d,e`, each the square of its top left plus 100 if it runs down
the sea; a shot is `attack/n`, n from 0 to 99.

#sub("Drawing the seas")
H19 characters are about twice as tall as they are wide, so each square of a sea is two characters
wide, which makes it nearly square. Water is blank, a miss is `()`, and a hit two reversed diagonal
crosses. A ship's hull is half a square thick, drawn with half blocks and quarter blocks so it never
touches its neighbours; its bow and stern are quarter blocks too. A shot is a little animation:
`><`, `\/`, `XX`, reversed, checkerboard, a flash.

Battleship keeps one picture of the screen in memory and sends each changed cell at once, without
the second picture the other two games use; it was the first of the three to be ported, and its
console and keyboard code became theirs.

#sub("fujinet-lib")
Battleship's shared code includes its own copy of fujinet-lib's headers, which declare the app key
calls as functions; on the H89 they are macros, so calls through those declarations would link to
nothing. So the game is built with `CUSTOM_FUJINET_CALLS`, and three small functions in
`src/h89/fujinet.c`, which include the library's real headers, make the calls.
]

#section("The Files")[
#stable((1.35in, 1fr), size: 7.6pt,
  th[File], th[Holds],
  [`src/main.c`], [The globals, the ship sizes, the main loop and its polling.],
  [`src/stateclient.c`], [Requests, moves, the state.],
  [`src/screens.c`], [Help, name, welcome, table list, the menu.],
  [`src/gamelogic.c`], [The lobby, placing ships, the seas, shots, the end.],
  [`src/misc.c`, `misc.h`], [Keys, preferences, app keys; the structures.],
  [`src/standard_lib.h`], [The standard headers, per compiler; the H89's `kbhit()` and `cgetc()`.],
  [`src/platform-specific/*.h`], [What the H89's part must supply.],
  [`src/h89/console.c`], [The H19: one picture of the screen; the OS console.],
  [`src/h89/graphics.c`], [Seas, ships, the cursor, drawers, name badges.],
  [`src/h89/input.c`], [The H19's keys.],
  [`src/h89/fujinet.c`], [The three fujinet-lib calls.],
  [`src/h89/sound.c`, `util.c`, `vars.h`], [The bell; frames, timer, random numbers; layout and keys.],
)
]

#section("Listing", balance: false)[
#plisting("battleship")
]
