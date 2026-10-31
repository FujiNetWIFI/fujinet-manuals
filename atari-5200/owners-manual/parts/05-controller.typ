#import "../lib.typ": *
#import "../figs.typ": *

= Using the 5200 Controller

The FujiNet menu listens to the controller in *jack 1*. It can be worked
with the joystick or with the keypad alone, whichever you like better.

#plate(fig-controller())

Each controller has two buttons on either side. The *bottom buttons* are the
fire buttons for all games; in the FujiNet menu they open and choose. The
*top buttons* do different things in different games; in the FujiNet menu
they go back. The right or the left button can be used, whichever is more
comfortable for you.

#plate(fig-side())

== In the FujiNet Menu

A bar across the screen marks the line you are on. The bottom two lines of
every FujiNet screen say which keys do what there, as #scr("#--OPEN") or
#scr("PAUSE--RENAME").

#controls(title: [In every FujiNet menu], w: 0.98in,
  [#stick("udlr") \ or #kp(2, 4, 6, 8)], [Move. Up and down go along the
    list; left and right turn the page. Hold to repeat.],
  [#BOTTOM button \ or #HASH], [Open, or choose, the line the bar is on.],
  [#TOP button \ or #STAR], [Go back. On the keyboard, erase a letter.],
  [#PAUSE], [Rename a host; set a filter; capitals or small letters on the
    keyboard.],
  [#START], [Show the adapter’s INFO; mark a game to copy; look for networks
    again; accept what you typed.],
  [#RESET], [The same as #STAR. It does not restart anything.],
)

The other keypad keys, #kp(1, 3, 5, 7, 9, 0), are not used by the menu. The
games you load decide what every key does.

== Getting Back to the FujiNet Menu

The 5200 has no wire to tell a cartridge to start over, so the way back to the
FujiNet menu from any game is:

#steps(
  [Press the console’s *POWER* switch OFF.],
  [Wait a moment, and press it ON again.],
)

The FujiNet menu comes back, with your hosts and WiFi just as you left them.
The #RESET key on the controller belongs to the game you are playing: it
starts that game over from the beginning. The FujiNet network games also have
a way back of their own; each one’s section tells you how.

== Keypad Overlay

All 5200 games can come with keypad overlays, slipped over the keypad to show
what each key does. This is the FujiNet menu’s. Copy it onto a blank overlay,
or keep this page beside you while you learn.

#plate(overlay-card)
