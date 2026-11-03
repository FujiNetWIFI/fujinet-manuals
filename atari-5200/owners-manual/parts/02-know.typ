#import "../lib.typ": *
#import "../figs.typ": *

= Know Your Cartridge

The cartridge has two faces. The *label* faces you, toward the front of the
console, and carries everything you can press or see light up. The other face
is plain. The top edge, which stands up out of the console, has the
sockets for power and the memory card.

#plate(fig-face())

== The Lights

#tbl((0.95in, 1fr),
  th[Light], th[What it means],
  [*Status*, white], [FujiNet is connected to your WiFi network.],
  [*Status*, orange, flickering], [FujiNet is busy: reading the network or
    the memory card, or sending a game to the console. It goes back to white
    when it is done.],
  [*Status*, off], [FujiNet is not connected to WiFi (yet).],
  [*Game*, red], [A game has been sent to the console since you turned it
    on. It is dark while the FujiNet menu is on the screen.],
)

== The RESET Button and the Service Holes

The *RESET* button restarts the cartridge itself: both of its small
computers. The 5200 cannot be told, so after pressing it, turn the console
OFF and ON again. You will rarely need it. Turning the console OFF and ON is
the everyday way back to the FujiNet menu.

#important[The three small *service holes* beside RESET are for loading new
firmware into the cartridge. Do not push anything into them in everyday use.]

== The Top Edge

#plate(fig-top())

*USB-C socket.* The cartridge can run on power from the console, and a USB-C
phone charger plugged in here powers it too (Section 4). Power from the
charger never flows back into the console, so it is safe to leave it plugged
in. The same socket is used to load new firmware.

*Memory card slot.* A microSD card pushes into the slot beside the USB-C
socket, contacts first and its printed side toward the label. Push it in
until it clicks; push again to let it out.

== A Look Inside

You never need to open the cartridge, but if you are curious, this is the
board inside it, seen from the label side.

#plate(fig-inside(), caption: [The FujiNet 5200 board, Rev0. The network chip
does the WiFi, the memory card and the talking to servers; the game chip
answers the console and plays the part of each game’s cartridge.])
