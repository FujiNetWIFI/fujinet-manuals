#import "../lib.typ": *
#import "../figs.typ": *

= Inserting the Cartridge

#plate(fig-insert())

#steps(
  [Check to see that the console’s *POWER* is *OFF*.],
  [Hold the FujiNet cartridge so the label faces you and reads right side up.],
  [Carefully insert the cartridge into the cartridge slot in the 5200
   console. Be sure the cartridge fits firmly into the slot but DO NOT FORCE
   IT IN. The top edge, with its USB-C socket, stays standing out of the
   slot.],
  [Plug your controller into *jack 1* (below).],
  [Turn your television set on and set the volume control to a comfortable
   level.],
  [Press the console’s *POWER ON/OFF* switch. The red light beside it glows,
   and the FujiNet menu appears.],
)

#important[To protect your console and the cartridge, the console’s POWER
should be OFF whenever you put a cartridge in or take one out.]

When you take the cartridge out, pull it straight up, and check first that
the POWER is OFF.

== Plugging In the Controller

#plate(fig-jacks())

Plug a 5200 controller into *jack 1* on the front of the console. The
FujiNet menu and every FujiNet game listen to the controller in jack 1. The
jack is designed to fit only one way. Be sure the connection is firm, but do
not try to force it.

#note[Some games want a second controller, in jack 2. The game will tell you;
FujiNet does not mind what is plugged in.]

#pagebreak(weak: true)
== Extra Power

#grid(columns: (1.15in, 1fr), column-gutter: 12pt, align: (center + top, left + top),
  art("cart-power", w: 1.05in),
  [
    The cartridge can run on power from the console, but its WiFi radio
    needs more, in short bursts, than some consoles have to spare. A *USB-C
    phone charger* plugged into the top of the cartridge supplies it. The
    cartridge takes what it needs from the charger and never sends any of it
    back to the console.

    - *Four-port consoles.* Use a charger. The original four-port console
      feeds the cartridge from the same small supply that runs its own
      memory and controllers, and WiFi can overload it.
    - *Two-port consoles* power the cartridge well on their own. Use a
      charger if the picture jumps or the FujiNet menu starts over by itself
      when the WiFi connects.
  ],
)

#important[Plug the charger into the cartridge *before* you turn the console
on. The cartridge is then already awake when the console first looks at it.]

With a charger plugged in, FujiNet stays awake and connected while the
console is off, so it is ready again the moment you turn the console back
on.
