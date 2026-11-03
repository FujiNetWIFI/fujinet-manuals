#import "../lib.typ": *

= Hosts and the Browser

A *host* is a place where games are kept: the memory card in the cartridge,
a server on the Internet, or a computer in your home. FujiNet remembers eight
of them, and lists them on the *FUJINET HOSTS* screen every time you turn on.

#fig(tvlab("hosts", w: 3.0in, (
  (..cell(1, 2), -0.03, 0.1, [The bar], left),
  (..cell(4, 4), -0.03, 0.32, [An empty host], left),
  (..cell(2, 13), 1.03, 0.14, [Names longer \ than 14 letters \ are cut short], right),
  (..cell(11, 6), 1.03, 0.73, [What the \ buttons do here], right),
)), caption: [FujiNet hosts, as it comes])

A new FujiNet comes with three hosts already filled in:

- *SD* -- the microSD card in the side of the cartridge.
- *TNFS.FUJINET.ONLINE* -- the FujiNet project’s own library.
- *APPS.IRATA.ONLINE* -- the library that keeps the ARCADIA-2001’s games.

The other five show a row of dashes. Move the bar to a host and press the
Action button (or #ENTER) to look inside it.

#controls(title: [On FujiNet hosts],
  [#FIRE or #ENTER], [Open the host the bar is on.],
  [#kp(1)], [Rename: fill in, or change, the host the bar is on.],
  [#kp(3)], [FujiNet’s INFO (Section 10).],
  [#kp(7)], [Choose a WiFi network again (Section 6).],
  [#kp(9)], [The Game Lobby (Section 11).],
)

== Adding a Host

#grid(columns: (2.3in, 1fr), column-gutter: 0.3in, align: (center + top, left + top),
  fig(tv("rename", w: 2.2in), caption: [Naming a host]),
  [
    #steps(
      [Move the bar to an empty host -- a row of dashes.],
      [Press #kp(1). The character grid appears, titled #scr("HOST NAME").],
      [Spell the server’s name or address, for example `192.168.1.20`.],
      [Press #ENTER.],
    )
    To change a host, rename it the same way.
  ])

Most hosts are *TNFS* servers, and a plain name means TNFS. FujiNet can also
reach other kinds of server if you spell the kind in front:

#tbl((2.1in, 1fr),
  th[Type this], th[For],
  [`SD`], [the memory card in the cartridge],
  [`games.local` or `192.168.1.20`], [a TNFS server -- the usual kind],
  [`smb://server/share`], [a Windows or Samba file share],
  [`nfs://server/export`], [an NFS share],
  [`ftp://server`], [an FTP server],
  [`http://server/path`], [a web server (`https://` too)],
)

== The Browser

When you open a host, the browser shows what is in it, eight names to a page.
The top line is the end of the folder you are in. Folders are in yellow and
end in #scr("/"); they come first. The column of blocks at the right shows how
far down the folder you are.

#shots(("browse-irata", [The top of apps.irata.online]),
  ("browse-arcadia", [Its Arcadia folder]), w: 2.45in,
  caption: [The browser])

#controls(title: [In the browser],
  [#disc("ud") or #kp(8)], [Move down and up the page. Past the bottom, go on
    to the next page.],
  [#disc("lr") or \ #kp(4) #kp(6)], [Turn the page back or on.],
  [#FIRE or #ENTER], [On a folder, open it. On a game, *load it*
    (Section 8).],
  [#kp(1)], [Back up one folder.],
  [#kp(5)], [Copy the game the bar is on to another host (Section 9).],
  [#kp(7)], [Filter: show only the names that match a pattern.],
  [#CLEAR], [Back to FujiNet hosts.],
)

Names are cut to 14 characters; the full name is still what FujiNet loads. A
character the ARCADIA-2001 cannot draw shows as a box: the *!* in front of
#scr("FUJINET/"), for one. An empty folder says #scr("EMPTY FOLDER").

*Filters.* Press #kp(7) and spell a pattern on the character grid: `*`
stands for any letters and `?` for any one letter, and the pattern must match
the whole name. So `*JU*` shows only the names with JU in them, and `B*` those
beginning with B. Capitals and small letters match each other, and folders
are always shown. The pattern stays on the screen, after #scr("FLT:"), until
you leave the folder; an empty pattern shows everything again.

#shot("filter", [The Arcadia folder, filtered by *JU*])
