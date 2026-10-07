#import "../lib.typ": *

= Loading Games

To load a game, find it in the browser and press the red button. FujiNet
sends the whole game into the cartridge and starts it -- there is nothing
else to do.

#grid(columns: (auto, auto, 1fr), column-gutter: 10pt, align: (left + top, left + top, left + top),
  tvcap("boot", [Loading], size: 4.6pt),
  tvcap("boot-fail", [It would not load], size: 4.6pt),
  [
    *BOOTING* shows the end of the game's name and a bar that fills as it
    loads. *DO NOT POWER* off while it does. Then the screen changes, and the
    game starts just as if its own cartridge were in the slot.

    If it says *BOOT FAILED*, the game is one FujiNet cannot play (see the
    table on the next page), or the file is damaged. After a few seconds you
    are back in the browser.
  ],
)

#important[To leave a game and go back to the FujiNet menu, press the *RESET
button on the cartridge*. Turning the console off and on again does the same.
The console's GAME RESET switch only restarts the game.]

== From the Internet

The FujiNet project keeps 2600 games on the Internet, ready to load. Nothing
needs to be copied:

#tbl((auto, auto, 1fr),
  th[HOST], th[FOLDER], th[WHAT IS THERE],
  [*apps.irata.online*], [*Atari_2600*], [The FujiNet network games: 5 Card Stud, Texas Hold'em, Battleship and Fujitzee (Sections 12--15)],
  [*apps.irata.online*], [*mule / atari-2600*], [M.U.L.E. (Section 16)],
  [*tnfs.fujinet.online*], [], [The FujiNet project's library for every computer and console],
)

Open the host, open the folder, and choose the game.

== From the Memory Card

#steps(
  [On your computer, copy your games onto a microSD card formatted FAT32.
   You may put them in folders.],
  [With the console OFF, push the card into the side of the cartridge until
   it clicks (Section 2).],
  [Turn on. Open the *SD* host, and choose a game.],
)

== From Your Own File Server

A computer in your home can serve games to FujiNet with a small free program
called a *TNFS server*. There are versions for Windows, Mac, Linux and the
Raspberry Pi; see *fujinet.online* for the current one.

#steps(
  [Install the TNFS server, and point it at a folder of games.],
  [Find your computer's network address -- something like `192.168.1.20`.],
  [On FN HOSTS, RENAME an (EMPTY) host to that address (Section 7).],
  [Open it. Your folder appears in the browser.],
)

A Windows share (`smb://`) or an FTP or web server works the same way.

== Which Games Will Load

FujiNet loads a game into its own memory and then plays the part of that
game's cartridge, page-switching included. Most of the 2600 library loads
just by choosing it:

#tbl((1.1fr, 1fr),
  th[GAME SIZE AND KIND], th[FOR EXAMPLE],
  [2K and 4K games], [Combat, Adventure, Pitfall!, Space Invaders],
  [8K (F8)], [Asteroids, Ms. Pac-Man, Raiders of the Lost Ark],
  [12K (FA, CBS RAM Plus)], [Omega Race, Mountain King, Tunnel Runner],
  [16K (F6)], [Solaris, Midnight Magic],
  [32K (F4)], [Fatal Run],
  [Games with an extra Super Chip (F8SC, F6SC, F4SC)], [Dig Dug, Crystal Castles, Off the Wall -- found by themselves],
)

A few kinds of game cannot be told apart by their size. They load when a small
text file sits beside them, with the *same name* ending in `.CFG`, holding
one word: the kind.

#tbl((auto, 1fr, 1fr),
  th[WORD], th[KIND], th[FOR EXAMPLE],
  [`E0`], [Parker Brothers 8K], [Frogger II, Montezuma's Revenge, Popeye, Gyruss],
  [`FE`], [Activision 8K], [Decathlon, Robot Tank],
  [`UA`], [UA Limited 8K], [Pleiades, Funky Fish],
  [`CV`], [CommaVid], [Magicard, Video Life],
)

For example, `MONTEZUMA.BIN` and a file `MONTEZUMA.CFG` containing just
`E0`. FujiNet hides `.CFG` files in the browser and copies them along with
their games.

*File names.* FujiNet loads files whose names end in *.BIN* or *.ROM*. Many
2600 game files end in `.A26`; rename them to `.BIN`. Games may be up to
32K.

*Not yet supported:* Pitfall II and other games with an extra chip of their
own (DPC), Starpath Supercharger tapes, Tigervision and other games larger
than 32K or with their own page-switching (3E, 3F, F0, EF, DF, BF, SB), and
the modern ARM-powered homebrews.

#note[FujiNet is made for NTSC consoles and TVs. PAL games may roll or lose
their colour.]
