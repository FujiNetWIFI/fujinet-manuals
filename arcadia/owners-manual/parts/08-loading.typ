#import "../lib.typ": *

= Loading Games

To load a game, find it in the browser and press the Action button (or
#ENTER). FujiNet sends the whole game into the cartridge and starts it --
there is nothing else to do.

#shot("booting", [Booting])

*BOOTING* shows the game’s name and a bar that fills as it loads. The game
chip plays a short fanfare, the screen changes, and the game starts just as
if its own cartridge were in the slot. #scr("DO NOT POWER OFF") means just
that, for the second or two it takes.

#important[To leave a game and go back to CONFIG, press RESET on the back of
the cartridge and then the console’s RESET (Section 5). The console’s RESET
alone only starts the game over.]

== From the Internet

The FujiNet project keeps the ARCADIA-2001’s games on the Internet, ready to
load. Nothing needs to be copied:

#tbl((1.45in, 1.75in, 1fr),
  th[Host], th[Folder], th[What is there],
  [*APPS.IRATA.ONLINE*], [*ARCADIA*], [The ARCADIA-2001’s own games: all 48
    of them (Section 17)],
  [*APPS.IRATA.ONLINE*], [*ARCADIA* #into *!FUJINET*], [The FujiNet network
    games: 5 Card Stud, Battleship, Fujitzee and Texas Hold’em
    (Sections 12--15)],
  [*APPS.IRATA.ONLINE*], [*MULE* #into *ARCADIA*], [M.U.L.E. (Section 16)],
  [*TNFS.FUJINET.ONLINE*], [], [The FujiNet project’s library for every
    computer and console],
)

Open the host, open the folder, and choose the game.

#shot("browse-fujinet", [Arcadia #into !FUJINET: the network games])

== From the Memory Card

#steps(
  [On your computer, copy your games onto a microSD card formatted FAT32.
   You may put them in folders.],
  [With the console OFF, push the card into the side of the cartridge until
   it clicks (Section 2).],
  [Turn on. Open the *SD* host, and choose a game.],
)

#shots(("browse-sd", [The memory card]), ("browse-games", [A folder on it]),
  w: 2.1in, caption: [Games on the memory card])

== From Your Own File Server

A computer in your home can serve games to FujiNet with a small free program
called a *TNFS server*. There are versions for Windows, Mac, Linux and the
Raspberry Pi; see *fujinet.online* for the current one.

#steps(
  [Install the TNFS server, and point it at a folder of games.],
  [Find your computer’s network address -- something like `192.168.1.20`.],
  [On FujiNet hosts, rename an empty host to that address (Section 7).],
  [Open it. Your folder appears in the browser.],
)

A Windows share (`smb://`), an NFS share, or an FTP or web server works the
same way.

== Which Games Will Load

FujiNet loads every game made for the ARCADIA-2001, up to 8,192 bytes -- the
size of the largest cartridge -- and the larger programs made for FujiNet
itself, up to 71,680 bytes. Of the 48 games in the library, 47 play; the
one that does not is *Golf*, whose cartridge was wired differently from all
the others. FujiNet does not imitate that cartridge yet.

*File names.* FujiNet loads files whose names end in *.BIN* or *.ROM*. A
game file ending in `.ARC` loads once it is renamed to end in `.BIN`.

#note[FujiNet is made for the NTSC console. The games marked _Europe_ in
the library were sold for look-alike consoles in Europe, and play on the
ARCADIA-2001 as well.]

== When a Game Will Not Load

#tbl((1.6in, 1fr),
  th[Screen says], th[What it means],
  [#scr("NOT A CART")], [The file is not a game -- or its name does not end
    in .BIN or .ROM.],
  [#scr("ROM TOO BIG")], [Larger than 71,680 bytes.],
  [#scr("STAGE ERROR")], [Larger than 8,192 bytes, but not a program made
    for FujiNet: the cartridge cannot place it.],
  [#scr("TRUNCATED")], [The file was cut short on its way. Try again, or
    copy it again.],
  [#scr("PATH ERROR"), #scr("MOUNT ERROR")], [FujiNet could not open the
    host or the file. Check the host is running, and try again.],
)

The message stays a moment, with a number at the right of the line for the
FujiNet project should you ask them about it, and then you are back in the
browser.
