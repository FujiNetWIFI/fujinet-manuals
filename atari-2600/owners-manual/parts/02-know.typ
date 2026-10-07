#import "../lib.typ": *
#import "../figs.typ": *

= Know Your Cartridge

The cartridge has two faces. The *label* faces you, toward the front of the
console. The *back* faces the back of the console, and carries everything you
can press or see light up.

#fig(fig-rear(), caption: [The back of the cartridge -- the side that faces the back of the console.])

== The Lights

#tbl((auto, 1fr),
  th[LIGHT], th[WHAT IT MEANS],
  [*White*, steady], [FujiNet is connected to your WiFi network.],
  [*Orange*, flickering], [FujiNet is busy: reading the network or the memory card, or sending a game to the console. It goes back to white when it is done.],
  [Status light *off*], [FujiNet is not connected to WiFi (yet).],
  [*Red*], [The cartridge has power and is running.],
)

The lights face the back of the console. Lean over the top of the console to
see them.

== The RESET Button

The *RESET* button on the back of the cartridge restarts the cartridge and
brings back the FujiNet menu, whatever game is running. It is the way home.
It is not the same as the console's *GAME RESET* switch, which belongs to the
game you are playing.

#important[The three small *service holes* are for loading new firmware
into the cartridge. Do not push anything into them in everyday use.]

== The Top End and the Side

#grid(columns: (1fr, 1fr), column-gutter: 10pt,
  fig(fig-top()),
  fig(fig-side()),
)

*USB-C socket (top end).* The cartridge normally runs on power from the
console. A USB-C phone charger plugged in here powers it too. Power from the
charger never flows back into the console, so it is safe to leave it plugged
in. The same socket is used to load new firmware.

*Memory card slot (side).* A microSD card pushes into the slot in the side of
the cartridge -- the left end as you sit at the console -- with its printed
side toward the back of the cartridge, contacts first. Push it in until it
clicks; push again to let it out. With the cartridge in the console you may
find a fingernail or a guitar pick helps.

#pagebreak(weak: true)
== A Look Inside

You never need to open the cartridge, but if you are curious, this is what
is inside. The board faces the back of the console, so this is the side the
console's back sees.

#fig(fig-inside(), caption: [The Fujiversal-Atari2600 board, Rev1. S3 EN, S3 BOOT and BOOTSEL are the service buttons behind the three small holes.])
