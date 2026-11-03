#import "../lib.typ": *
#import "../figs.typ": *

= Know Your Cartridge

The cartridge has two faces. The *label* faces you, toward the front of the
console, just as a game’s label does. Everything you can press or see light
up is on the *back*, the face toward your television. The top edge, which
stands up out of the console, has the socket for power, and the right-hand
edge the slot for a memory card.

#fig-back

#partlist(
  ([Status light], [White when FujiNet is connected to your WiFi network;
    flickers orange while it is busy reading the network or the memory card,
    or sending a game to the console; dark until it has joined a network.]),
  ([Game light], [Red whenever the cartridge has power and its game chip is
    running.]),
  ([RESET button], [Restarts the cartridge itself: both of its small
    computers. It is the way back to the FujiNet CONFIG from a game
    (Section 5).]),
  ([Service holes], [Three small holes, for loading new firmware into the
    cartridge. Do not push anything into them in everyday use.]),
  ([Contacts], [The cartridge’s connector. Keep it clean, and do not touch
    the gold contacts.]),
)

== The Top and the Side

#fig-top

#partlist(
  ([USB-C socket], [The cartridge can run on power from the console, and a
    USB-C phone charger plugged in here powers it too (Section 4). Power
    from the charger never flows back into the console, so it is safe to
    leave it plugged in. The same socket is used to load new firmware.]),
  ([Memory card slot], [A microSD card pushes into the slot in the
    right-hand edge, contacts first, its printed side toward the label.
    Push it in until it clicks; push again to let it out.]),
)

#pagebreak(weak: true)
== A Look Inside

You never need to open the cartridge, but if you are curious, this is the
board inside it, seen from the back.

#fig-inside
