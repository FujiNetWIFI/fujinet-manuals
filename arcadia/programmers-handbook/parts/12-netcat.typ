#import "../lib.typ": *

#booklet.update(true)
#bandfile.update(("SD", "/arcbook/netcat.bin"))
= NetCat <netcat>

== General

NetCat is a terminal for a TCP connection: what the far end sends scrolls up
the screen, and what you type goes back a line at a time. It is the
handbook’s longest program and the one that uses everything before it: the
network device, the controller, the tone of the keys, and the RAM
arithmetic of Section 6.

#grid(columns: (2.55in, 1fr), column-gutter: 0.35in, align: (center + top, left + top),
  fig(tv("netcat-typing", w: 2.45in), caption: [NetCat, a line sent and the next begun]),
  [
    #steps(
      [NetCat opens `N:TCP://` and the bench’s line server, which greets it
       with #scr("NETCAT SAYS HI").],
      [Turn the disc up or down: the character at the end of the line, in
       magenta, steps through the alphabet, the digits and `. , + $ / - _ :`.
       Hold it and it runs.],
      [Press the Action button to type that character. #CLEAR takes the last
       one back.],
      [#ENTER sends the line with CR LF. The server answers
       #scr("ECHO") and the line.],
      [#kp(0) closes the connection: #scr("CLOSED").],
    )
  ])

== The Keyboard

#grid(columns: (2.6in, 1fr), column-gutter: 0.35in, align: (center + top, left + top),
  overlay("NetCat", (none, [type], none, none, none, none, none, none, none,
    [delete], [close], [send]), head: [Action buttons: type]),
  [
    The ARCADIA-2001 has twelve keys and no keyboard, and the 2 is the Action
    buttons’ wire, so NetCat does not type from the keys at all. It takes its
    characters from a wheel, as an arcade machine takes a high-score name.

    The wheel is a string in ROM, `WHEEL`, and its position a byte, `WIDX`.
    The disc is read once a frame, in the blank; a turn moves `WIDX` at once,
    then again every eighth frame from the sixteenth while the disc is held,
    so one press is one character and a held disc runs.
  ])

#excerpt-at(auto, "listings/asm/netcat.asm", "INPUT:  LODA,R0 $19FF", to: "INKEYS:")

The keys are taken on their edges: the program keeps last frame’s keys in
`PREVK`, and a key counts only in the frame it goes down. The four bits that
matter are gathered into one byte first:

#excerpt-at(auto, "listings/asm/netcat.asm", "INKEYS: LODA,R0 $1901", to: "TYPE:   LODA,R1 LLEN")

== The Connection

The devicespec is `N:TCP://127.0.0.1:8791/`, from `build.sh`, opened in mode
12, read and write. After that NetCat never waits on the network. Every
sixth frame it asks STATUS; if bytes are waiting it READs them, up to 255,
and prints them; then it goes back to the controller:

#excerpt-at(auto, "listings/asm/netcat.asm", "RECV:   BSTA,UN NSTAT", to: "; TPUTC")

A line goes out with one WRITE: the characters, then CR and LF, from the
line buffer in RAM through `FSTRP`:

#excerpt-at(auto, "listings/asm/netcat.asm", "SEND:   LODA,R1 LLEN", to: "QUIT:")

== The Terminal

Rows 0--9 are the terminal, with a cursor of its own (`TROW`, `TCOL`).
`TPUTC` ignores CR, starts a new line at LF, and wraps at the sixteenth
column. Off the bottom, `TSCRL` copies rows 1--9 up a row and clears row 9:
the 2637 cannot scroll, but the screen is RAM, and the copy takes under a
frame.

#excerpt-at(auto, "listings/asm/netcat.asm", "TSCRL:  LODI,R3 0", to: "URL:")

== Living in RAM

#tbl((1.1in, 0.5in, 1fr),
  [*Where*], [*Bytes*], [*What*],
  [`$1A00-$1A07`], [8], [the libraries: FNGO, FAIL, the STATUS reply, DREPLY],
  [`$1A08-$1A10`], [9], [`TROW`, `TCOL`, `TCH`, `WIDX`, `LLEN`, `HELD`, `PREVK`, `POLL`, `RIDX`],
  [`$1A18-$1A28`], [17], [`LBUF`: 15 characters, CR, LF],
)

The received bytes are never copied: `RECV` prints each one straight out of
the reply window, keeping only its index, `RIDX`.

== Testing It

`emu/verify.sh` drives NetCat as a player would: it waits for the greeting,
turns the disc down seven times to H, types, turns once more to I, types,
presses ENTER and waits for #scr("ECHO HI"). The line server writes what it
heard to `bench/run/ncserver.log.txt`.

#important[NetCat must be tested in real time (`THROTTLE=1`). The server
waits half a second before its greeting, and an unthrottled MAME runs a
minute of console time in that half second; the test would give up before
the greeting came.]

NetCat has no way back to CONFIG: no ARCADIA-2001 program does. #kp(0)
closes the connection, and the cartridge’s RESET, then the console’s, bring
CONFIG back.
