#import "../lib.typ": *

= Hosts and the Browser

A *host* is a place where games are kept: the memory card in the cartridge,
a server on the Internet, or a computer in your home. FujiNet remembers eight
of them, and lists them on the *HOST SLOTS* screen every time you turn on.

#shot("hosts", [HOST SLOTS, as it comes])

A new FujiNet comes with three hosts already filled in:

- *SD* -- the microSD card in the top of the cartridge.
- *tnfs.fujinet.online* -- the FujiNet project’s own library.
- *apps.irata.online* -- the library that keeps the 5200’s network games.

The other five say #scr("(EMPTY)"). Under them, *PLAY GAME LOBBY* opens the
FujiNet Game Lobby (Section 11). Move the bar to a host and press the bottom
button (or #HASH) to look inside it.

#controls(title: [On HOST SLOTS], w: 1.0in,
  [#BOTTOM or #HASH], [Open the host the bar is on (or the Lobby).],
  [#PAUSE], [Fill in, or change, the host the bar is on.],
  [#START], [The adapter’s INFO (Section 10).],
  [#TOP or #STAR], [Choose a WiFi network again (Section 6).],
)

== Adding a Host

#steps(
  [Move the bar to an #scr("(EMPTY)") line.],
  [Press #PAUSE. The keyboard appears, asking #scr("HOST NAME?").],
  [Spell the server’s name or address, for example `192.168.1.20` or
   `games.local`.],
  [Press #START.],
)

To change a host, rename it the same way. A host name can be up to 31
characters. Most hosts are *TNFS* servers, and a plain name means TNFS.
FujiNet can also reach other kinds of server if you spell the kind in front:

#tbl((1.45in, 1fr),
  th[Type this], th[For],
  [`SD`], [the memory card in the cartridge],
  [`games.local` or `192.168.1.20`], [a TNFS server -- the usual kind],
  [`smb://server/share`], [a Windows or Samba file share],
  [`nfs://server/export`], [an NFS share],
  [`ftp://server`], [an FTP server],
  [`http://server/path`], [a web server (`https://` too)],
)

#pagebreak(weak: true)
== The Browser

When you open a host, the browser shows what is in it, sixteen names to a
page. The top line says which host you are in (#scr("HOST 3") is the third
on HOST SLOTS); the next line is the folder you are in. Folders end in
#scr("/") and come first.

#shots(("browse-irata", [The top of _apps.irata.online_]),
  ("browse-games", [A folder on the memory card]), w: 1.72in)

#controls(title: [In the browser], w: 1.0in,
  [#stick("ud") or #kp(2, 8)], [Move up and down. At the top or bottom of a
    page, go on to the next one.],
  [#stick("lr") or #kp(4, 6)], [Turn the page back or on.],
  [#BOTTOM or #HASH], [On a folder, open it. On a game, *load it*
    (Section 8).],
  [#TOP or #STAR], [Back up one folder. At the top of the host, back to
    HOST SLOTS.],
  [#PAUSE], [Filter: show only the names that match a pattern.],
  [#START], [Copy the game the bar is on to another host (Section 9).],
)

*Filters.* Spell a pattern on the keyboard: `*` stands for any letters and
`?` for any one letter, so `B*` shows only the names beginning with B, and
`*CARD*` only those with CARD in them. Capitals and small letters match
each other, and folders are always shown. An empty filter shows everything
again. If nothing matches, the browser says #scr("(NO MATCHES)").

Long names are cut short, with #scr("...") in the middle; the full name is
still what FujiNet loads.
