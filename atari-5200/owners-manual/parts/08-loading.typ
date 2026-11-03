#import "../lib.typ": *

= Loading Games

To load a game, find it in the browser and press the bottom button (or
#HASH). FujiNet sends the whole game into the cartridge and starts it --
there is nothing else to do.

#shots(("browse-fujinet", [The network games, on _apps.irata.online_]),
  ("loading", [Loading]), w: 1.72in)

*LOADING* shows the game’s name, which host it comes from, and a bar that
fills as it loads, with the bytes counted under it. Then it says
#scr("BOOTING"), the screen changes, and the game starts just as if its own
cartridge were in the slot.

#important[To leave a game and go back to the FujiNet menu, turn the console
OFF and ON again (Section 5). The #RESET key on the controller only starts the
game over.]

== From the Internet

The FujiNet project keeps the 5200’s network games on the Internet, ready to
load. Nothing needs to be copied:

#tbl((1.1in, 1.1in, 1fr),
  th[Host], th[Folder], th[What is there],
  [*apps.irata.online*], [*ATARI-5200* #into *FUJINET*], [The FujiNet network
    games: Battleship, Five Card Stud, Fujitzee and Texas Hold’em
    (Sections 12--15)],
  [*apps.irata.online*], [*mule* #into *atari5200*], [M.U.L.E. (Section 17)],
  [*tnfs.fujinet.online*], [], [The FujiNet project’s library for every
    computer and console],
)

Open the host, open the folder, and choose the game.

== From the Memory Card

#steps(
  [On your computer, copy your games onto a microSD card formatted FAT32.
   You may put them in folders.],
  [With the console OFF, push the card into the top of the cartridge until
   it clicks (Section 2).],
  [Turn on. Open the *SD* host, and choose a game.],
)

== From Your Own File Server

A computer in your home can serve games to FujiNet with a small free program
called a *TNFS server*. There are versions for Windows, Mac, Linux and the
Raspberry Pi; see *fujinet.online* for the current one.

#steps(
  [Install the TNFS server, and point it at a folder of games.],
  [Find your computer’s network address -- something like `192.168.1.20`.],
  [On HOST SLOTS, rename an #scr("(EMPTY)") host to that address
   (Section 7).],
  [Open it. Your folder appears in the browser.],
)

A Windows share (`smb://`), an NFS share, or an FTP or web server works the
same way.

#pagebreak(weak: true)
== Which Games Will Load

FujiNet loads a game into the cartridge and then plays the part of that
game’s own cartridge, whatever kind it was. It knows the whole 5200 library by
heart, so nearly every game loads just by choosing it:

#tbl((1.25in, 1fr),
  th[Kind of cartridge], th[For example],
  [4K to 32K], [Kaboom!, Missile Command, Galaxian, River Raid, H.E.R.O.],
  [16K, made of two chips], [Pac-Man, Ms. Pac-Man, Joust, Defender, Qix,
    Pole Position],
  [Bounty Bob Strikes Back (40K)], [the one game of its kind],
  [Super Cart, 64K or 128K], [modern homebrews, and M.U.L.E.],
)

*File names.* FujiNet loads files whose names end in *.A52*, *.BIN* or
*.ROM*. A game file ending in `.CAR` loads once it is renamed to end in
`.A52`. Games may be up to 128K.

*Games FujiNet does not recognise* -- a new homebrew, say -- are judged by
their size. If one will not start, a small text file beside it, with the
*same name* ending in `.CFG`, can say what kind it is, in one line:

#tbl((1.25in, 1fr),
  th[Line], th[Kind],
  [`mapper=rom`], [a plain cartridge, up to 32K],
  [`mapper=2chips`], [16K made of two chips],
  [`mapper=bbsb`], [Bounty Bob Strikes Back’s kind],
  [`mapper=supercart`], [a 64K or 128K Super Cart],
)

For example, `NEWGAME.A52` and a file `NEWGAME.CFG` containing just
`mapper=2chips`.

*Not yet supported:* games larger than 128K, and 48K images, which match no
kind of cartridge.

#note[FujiNet is made for NTSC consoles and television sets. A game made for a
PAL machine may roll, or run too fast.]

== When a Game Will Not Load

#tbl((1.45in, 1fr),
  th[Screen says], th[What it means],
  [#scr("?NOT A CARTRIDGE IMAGE")], [The file is not a 5200 game -- or its
    name does not end in .A52, .BIN or .ROM.],
  [#scr("?LOAD ERROR 01")], [Larger than 128K.],
  [#scr("?LOAD ERROR 02")], [The file is cut short. Copy it again.],
  [#scr("?LOAD ERROR 03")], [A size that matches no kind of cartridge. Try a
    `.CFG` file beside it.],
  [#scr("?MOUNT ERROR"), #scr("?PATH ERROR")], [FujiNet could not open the
    host or the file. Check the host is running, and try again.],
)

After a few seconds you are back in the browser.
