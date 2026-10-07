#import "../lib.typ": *

= Hosts and the Browser

A *host* is a place where games are kept: the memory card in the cartridge,
a server on the Internet, or a computer in your home. FujiNet remembers eight
of them, and lists them on the *FN HOSTS* screen every time you turn on.

#grid(columns: (auto, 1fr), column-gutter: 12pt, align: (left + top, left + top),
  tvcap("hosts", [FN HOSTS, as it comes]),
  [
    A new FujiNet comes with three hosts already filled in:

    - *SD* -- the microSD card in the side of the cartridge.
    - *tnfs.fujinet.online* -- the FujiNet project's own library.
    - *apps.irata.online* -- the library that keeps the 2600's network
      games.

    The other five say *(EMPTY)*. Names are cut to eleven letters, so
    _apps.irata.online_ shows as *APPS.IRATA.*

    Move to a host and press the red button to look inside it.
  ],
)

#grid(columns: (auto, 1fr), column-gutter: 12pt, align: (left + top, left + top),
  shot("config-hosts", h: 1.15in),
  [
    #set text(size: 8.6pt)
    *What your TV shows.* FujiNet's twelve-letter menus sit in a narrow
    column in the middle of the screen. The screens in this booklet show
    that column close up. (This one has a few more hosts filled in.)
  ],
)

== Adding a Host

#steps(
  [Move the *>* to an *(EMPTY)* line.],
  [Press *GAME SELECT*. Choose *RENAME*.],
  [The keyboard appears, titled *HOST NAME*. Spell the server's name or
   address, for example `192.168.1.20` or `games.local`.],
  [Press *GAME SELECT* and choose *ACCEPT*.],
)

To change a host, RENAME it the same way. A host name can be up to 31
letters. Most hosts are *TNFS* servers, and a plain name means TNFS. FujiNet
can also reach other kinds of server if you spell the kind in front:

#tbl((auto, 1fr),
  th[TYPE THIS], th[FOR],
  [`SD`], [the memory card in the cartridge],
  [`games.local` or `192.168.1.20`], [a TNFS server -- the usual kind],
  [`smb://server/share`], [a Windows or Samba file share],
  [`ftp://server`], [an FTP server],
  [`http://server/path`], [a web server (`https://` too)],
)

#grid(columns: (auto, 1fr), column-gutter: 12pt, align: (left + top, left + top),
  tvcap("hosts-menu", [The ACTIONS menu]),
  [
    == The Hosts Menu

    *GAME SELECT* on the FN HOSTS screen opens its ACTIONS:

    - *INFO* -- your network and FujiNet's version (Section 10).
    - *RENAME* -- fill in or change the host you are on.
    - *WIFI* -- choose a WiFi network again (Section 6).
    - *LOBBY* -- the FujiNet Game Lobby (Section 11).

    Up and down choose; the red button does it; GAME SELECT closes the menu
    and does nothing.
  ],
)

#pagebreak(weak: true)
== The Browser

When you open a host, *FN BROWSE* shows what is in it, fourteen names to a
page. The second line shows where you are, ending in the folder's own name.
Folders end in #scr("/") and come first; games follow, A to Z.

#grid(columns: (1fr, 1fr), column-gutter: 8pt,
  align(center, tvcap("browse-root", [The top of _apps.irata.online_])),
  align(center, tvcap("browse", [Inside _Atari_2600_])),
)

#controls(title: [In the browser],
  [#stick("ud")], [Move up and down the page.],
  [#stick("r")], [Next page (when there is more).],
  [#stick("l")], [Previous page. On the first page, go back up one folder;
    at the top of the host, go back to FN HOSTS.],
  [#FIRE], [On a folder, open it. On a game, *load it* (Section 8).],
  [#SELECT], [Open the browser's ACTIONS menu.],
)

#grid(columns: (auto, 1fr), column-gutter: 12pt, align: (left + top, left + top),
  tvcap("browse-menu", [The browser's ACTIONS]),
  [
    - *UP DIR* -- back up one folder.
    - *FILTER* -- show only the names that match a pattern. Spell it on the
      keyboard: `*` stands for any letters and `?` for any one letter, so
      `B*` shows only games beginning with B, and `*.BIN` only `.BIN`
      files. Folders are always shown. An empty filter shows everything.
    - *INFO* -- your network and FujiNet's version.
    - *COPY*, *COPY HERE* -- copy a game to another host (Section 9).

    #v(4pt)
    #set text(size: 8.4pt)
    Long names are cut to eleven letters; the full name is still what
    FujiNet loads. The small `.CFG` files some games need (Section 8) are
    kept out of the list.
  ],
)
