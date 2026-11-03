#import "../lib.typ": *
#import "../figs.typ": *

= Using the Hand Controller

This micro-computer has two hand controllers, fixed to it by coil cords. The
FujiNet CONFIG listens to the *left* one. Lift it out of its place, the
keyboard toward the top.

#fig-controller

Every hand controller has a *keyboard* with 12 buttons, an *Action button* on
each side (they do the same thing, for the convenience of either a right- or
a left-handed player), and a *control disc*. Press the edge of the disc
toward where you want to go -- or, with a joy stick screwed into it, push the
stick that way. To stop, just let go.

#important[On the ARCADIA-2001 the Action buttons and the #kp(2) button are
one and the same: the console cannot tell them apart. So in CONFIG and in
every FujiNet game, #kp(2) does what the Action button does.]

== In the FujiNet CONFIG

A bar across the screen marks the line you are on. The bottom two lines of
every CONFIG screen say which buttons do what there, as #scr("7 WIFI") or
#scr("FIRE PICK") -- *FIRE* is the Action button.

#controls(title: [Everywhere in CONFIG],
  [#disc("ud") or #kp(8)], [Move down and up the list. #kp(8) goes down only,
    and from the bottom round to the top. Hold to repeat.],
  [#FIRE, #kp(2) \ or #ENTER], [Choose the line the bar is on: open it, boot
    it, pick it.],
  [#CLEAR], [Go back.],
)

The other buttons do the jobs each screen’s bottom lines name: on the list of
hosts, #kp(1) renames a host, #kp(3) shows FujiNet’s INFO, #kp(7) chooses a
WiFi network and #kp(9) opens the Game Lobby; in the browser, #disc("lr") or
#kp(4) and #kp(6) turn the page, #kp(1) goes up a folder, #kp(5) copies and
#kp(7) sets a filter. Sections 6 to 11 show each screen. CONFIG does not use
the console’s START, SELECT and OPTION buttons; the games you load decide
what every button does.

== Keyboard Overlay

#grid(columns: (2.6in, 1fr), column-gutter: 0.35in, align: (center + top, left + top),
  fig(overlay("FujiNet Config", (
    "Rename · Up a folder", "Select", "Info",
    "Page back", "Copy", "Page on",
    "WiFi · Filter", "Down", "Lobby",
    "Back · Delete", "Skip · Esc", "OK"),
    head: [Action: select]), caption: [Overlay], above: 0.4em),
  [
    ARCADIA-2001 games come with mylar overlays, slipped over the keyboard to
    show what each button does. This is the FujiNet CONFIG’s. Copy it onto a
    blank overlay, or keep this page beside you while you learn.

    Each dot is a button, with its job lettered over it; the button’s own name
    is under it in grey. Where a button has two jobs, the first is on FujiNet
    hosts and the second in the browser or on the character grid.
  ])

== Getting Back to CONFIG

#fig-panel

The ARCADIA-2001 has no wire to tell a cartridge to start over. The console’s
*RESET* button restarts the game you are playing, not CONFIG. To leave a
game and go back to CONFIG:

#steps(
  [Press the *RESET* button on the back of the FujiNet cartridge (Section 2).],
  [Press the console’s *RESET* button.],
)

CONFIG comes back, with your hosts and WiFi just as you left them.

Turning the console’s POWER OFF and ON again does the same, when the
cartridge runs on the console’s power. With a USB-C charger plugged into the
cartridge, the cartridge stays awake while the console is off and keeps the
game it last loaded; use the RESET button on the cartridge.
