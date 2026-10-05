#import "../lib.typ": *

= Netcat

#lead[A terminal for the NES: type a URL, connect, and talk to whatever is at
the other end -- a bulletin board, a chat server, a program of your own.]

#shots("netcat-url", "netcat-session", "netcat-compose", w: 1.95in,
  caption: [Entering a URL; connected to a test server that answers each line;
and typing the next line over the bottom of the pane.])

== Using it

#runin(
  ("Connect", [The first screen asks for a URL, with the last one already
   filled in -- `N:TCP://BBS.FOZZTEXX.COM:23/` to begin with. Edit it on the
   on-screen keyboard and press Start.]),
  ("Read", [Whatever the other end sends scrolls up the screen. Telnet's
   option bytes and ANSI colour codes are thrown away.]),
  ("Write", [Press Start to type a line. The keyboard covers the bottom of
   the screen; Start again sends the line with CR LF, and the pane comes back.
   With a Family BASIC or Subor keyboard plugged in, just type: every key goes
   straight to the other end, and Return sends CR LF.]),
  ("Hang up", [Select. Then A takes you back to the URL.]),
)

On the on-screen keyboard the pad moves, A presses, B deletes, Select is
SHIFT -- lower case -- and Start is DONE.

== How it works

Four small files:

#tbl((auto, auto, 1fr),
  th[File], th[Lines], th[Does],
  [`netcat.c`], [224], [The two screens and the session loop.],
  [`term.c`], [83], [The pane: a shadow copy in RAM, scrolled with `memmove`, drawn a row at a time when it changes.],
  [`osk.c`], [111], [The on-screen keyboard.],
  [`pad.c`], [49], [The controller, with auto-repeat, and `frame()`.],
)

The session loop, once a frame:

#steps(
  [STATUS: how many bytes are waiting? If some, READ up to 128 of them and
   feed them through the Telnet and ANSI filter into the pane, then send the
   rows that changed to the screen. If none, and the connection is gone, hang
   up.],
  [Read the pad. Select hangs up; Start opens the keyboard.],
  [If a keyboard is plugged in, send what was typed.],
)

#excerpt-at("netcat.c: the session loop", "listings/netcat/netcat.c",
  "    /* What has the other end sent?", to: "    if (pad & PAD_START)", size: 6.6pt)

cc65's NMI resets the scroll every frame, so the pane cannot be scrolled by
the PPU. Every character goes into a 24×30 shadow copy instead; a new line at
the bottom moves the copy up with `memmove` and marks every row as changed.
`term_flush()` then sends only the marked rows, through cc65's queue. A burst
of text that scrolls the pane ten times costs one redraw, not ten.

The keyboard, when it is open, draws over the bottom of the pane. The shadow
still holds what was there, so `term_repaint()` puts it back afterwards.

== Building it

#codepanel("Build and run",
"make -C listings netcat               # listings/build/netcat.nes
emu/run.sh listings/build/netcat.nes  # or open it in FujiNet Go NES Desktop")

For testing, `emu/echo.py` is a server that answers every line; build netcat
pointed at it with `-DDEFAULT_URL='\"N:TCP://127.0.0.1:7777/\"'`, as was done
for the pictures here.

== Listings

#code-listing("netcat.c", "listings/netcat/netcat.c",
  callouts: (("network_open(url, OPEN_MODE_RW", 1), ("network_status(url, &avail", 2),
             ("network_read_nb(url, buf", 3), ("if (c == 0xFF)", 4),
             ("term_repaint();", 5)))
#code-listing("term.c", "listings/netcat/term.c",
  callouts: (("memmove(shadow[0]", 6), ("cputc(shadow[r][c]);", 7)))
#code-listing("osk.c", "listings/netcat/osk.c")
#code-listing("pad.c", "listings/netcat/pad.c",
  callouts: (("JOY1 = 1;", 8), ("while (clock() == t)", 9)))
