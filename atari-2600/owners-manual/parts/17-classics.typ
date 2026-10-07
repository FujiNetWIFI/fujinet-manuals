#import "../lib.typ": *

#pagebreak(weak: true)
= Classics, Networked

Some of the best games ever made for the 2600 were for two players sitting
side by side. The FujiNet project is teaching five of them to reach across
the Internet instead -- the same games, unchanged in how they look and play,
with your opponent at their own console, in their own home.

#grid(columns: (1fr,) * 5, column-gutter: 5pt,
  ..("combat", "dodgem", "dragster", "tennis", "vo").map(n =>
    shot(n + "-play", w: 100%)))
#align(center, text(size: 7pt, fill: gray)[Combat · Dodge 'Em · Dragster · Tennis · Video Olympics])

#note[These five are being finished now. As each one is ready it will appear
in the FujiNet Game Lobby (Section 11). What follows is how they will play.]

== How a Match Works

#flow(
  nodebox([YOUR 2600], sub: [with FujiNet], w: 0.85in),
  biarrow(w: 0.5in),
  nodebox([THE RELAY], sub: [on the Internet], w: 0.85in),
  biarrow(w: 0.5in),
  nodebox([THEIR 2600], sub: [with FujiNet], w: 0.85in),
)

Both consoles run the whole game. All that travels between them is what each
player does with the controller -- fifteen times a second, through a *relay*
on the Internet that pairs the first two players who arrive. Each console
waits the same short moment (about an eighth of a second) before acting on
*both* players' moves, so neither of you is ever ahead. If the other player's
moves are late, the picture holds still for a moment rather than going wrong.

- Each player uses *their own* joystick in *their own* console's *LEFT
  CONTROLLER* jack.
- *GAME SELECT* and *GAME RESET* work from either console, and both games
  obey them at the same instant.
- The *TV TYPE* switch stays your own: you can play in colour while your
  opponent plays in black and white.
- If the two games ever disagree, they press GAME RESET together, by
  themselves, and start the round again.

== What You Will See

#grid(columns: (1fr,) * 4, column-gutter: 3pt,
  align(center, tvcap("cb-conn", rows: 12, margin: 0.8, [Finding the relay], size: 4.4pt)),
  align(center, tvcap("cb-wait", rows: 12, margin: 0.8, [Waiting for a player], size: 4.4pt)),
  align(center, tvcap("cb-play", rows: 12, margin: 0.8, [Paired: your opponent's name], size: 4.4pt)),
  align(center, tvcap("cb-nonet", rows: 12, margin: 0.8, [No network], size: 4.4pt)),
)

*CONNECTING*, then *WAITING FOR AN OPPONENT* until someone joins, then
*PLAYING* and your opponent's name -- and the game begins. With no network, or
no relay, the screen says *NO NETWORK / LOCAL PLAY* for a moment, and then the
old game starts just as it always did, for two players on one console: press
GAME RESET to play. If your opponent leaves, the screen says *OPPONENT HAS
LEFT* -- press GAME RESET to look for another.

#pagebreak(weak: true)
== The Games

#let classic(name, body) = block(breakable: false, above: 0.9em, below: 0.6em, {
  context block(below: 4pt, width: 100%, fill: band-col.get(),
    inset: (x: 6pt, y: 3.5pt),
    text(font: f-head, weight: 700, size: 8pt, upper(name)))
  set text(size: 8.6pt)
  body
})

#classic([Combat (Atari, 1977)])[The first player to arrive drives the
*left* tank (or plane), the second the right. All 27 games are there: tanks,
Tank-Pong, invisible tanks, biplanes and jets, guided or straight shots, open
field, mazes and clouds. *Choose the game with GAME SELECT first, then press
GAME RESET* -- GAME SELECT is ignored once a battle has started. Each player's
*own left difficulty switch* sets their own tank's handicap. A game lasts
about two minutes and sixteen seconds.]

#classic([Dodge 'Em (Atari, 1980)])[Over the network it is *game 3*, the
two-player game: one of you drives the car collecting the dots while the other
drives the crash car after them, and you swap every round, so both of you are
busy all the time. The difficulty switches cross the wire too.]

#classic([Dragster (Activision, 1980)])[The first player races in the *top*
lane, the second in the *low* lane; the screen tells you which, and *JOY
RIGHT TO STAGE*. Push the joystick right to stage. Pull it *left* to arm a
gear change and let go to take the gear -- letting go is also your launch, the
instant the tree turns green. The red button is the throttle; hold it past the
red line and the engine blows. GAME SELECT chooses the straight race or the
race with a drift to steer against. The starting lights are shown a moment
early so your launch is not late; gear changes still arrive a little after you
make them, so network times run a touch slower than on one console.]

#classic([Tennis (Activision, 1981)])[The screen tells you whether you are
*PLAYER ONE* or *PLAYER TWO*. You swap ends every game, just as in real tennis.
The red button serves; swings are automatic. GAME SELECT offers the two
two-player games (the second is the slower one). Your own difficulty switch
limits your racket's angles, and it crosses the wire.]

#classic([Video Olympics (Atari, 1977)])[A *paddle* game: each player plugs
paddles into their own console's *LEFT CONTROLLER* jack and uses the first
paddle. The first player to arrive is the left side, the second the right.
GAME SELECT steps through the 22 of its 50 versions that two players can
play; your own difficulty switch crosses the wire.]

#rules[How a 1977 game learns to play over the Internet without changing how
it plays is a story in itself, told in the _PORTING_ notes that come with
each game's source code.]
