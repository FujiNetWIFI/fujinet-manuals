#import "../lib.typ": *

#opener-art.update((sub: [1 player · Keypad A · any TCP server],
  art: tvrow("netcat-url", "netcat-typed", "netcat-echo", w: 1.15in)))
= netcat <netcat>

_netcat_ is the oldest tool on the network: connect to a server and pass lines back and forth. Every FujiNet book has one, and so does this handbook. It is the largest program in it, 2,281 bytes on 11 pages, and it puts together everything so far: a network channel kept open, a screen that scrolls, the keypads, and an on-screen keyboard.

== Playing it

#nsteps(
  [The URL comes up in the keyboard, ready to change: `N:TCP://` and a host and port. Press *9* to connect.],
  [What the server sends appears in rows 0 to 8, and scrolls up when they are full. Row 9 shows the keys.],
  [Press *5* to type a line. Keys 2, 4, 6 and 8 move around the keyboard, *5* types the character under the cursor, *0* deletes the last, *9* sends the line with CR LF, and *1* goes back without sending.],
  [Press *0* to close the connection and go back to CONFIG.],
)

#note[Bytes that arrive while you type wait in the FujiNet: netcat reads them when you come back.]

The bench’s line server, `listings/fixtures/ncserver.py`, greets a connection with `NETCAT SAYS HI` and answers each line with `ECHO` and the line in capitals.

== Connecting

The URL opens a TCP connection with mode 12, read and write. Then netcat blanks its copy of the screen and starts the receive view:

#excerpt-at(auto, "listings/asm/netcat.asm", "connect:", to: "LDR     R8, SHADOW")

== Keys every frame, STATUS every eighth

The receive view polls two things: the keypads, every time round, and the connection, every eighth frame. RE, the frame counter, decides which: a press of the keypad takes a few frames, and a loop that slept between polls would miss it.

#excerpt-at(auto, "listings/asm/netcat.asm", "poll:   FCALL   in_get", to: "; ---- STATUS")

STATUS answers how many bytes are waiting, and whether the connection is still up. When nothing is waiting and the server has gone, row 9 says so.

== A screen that scrolls

The text engine’s SCROLL moves rows 1 to 9 up one, which carries the key row up with them. netcat blanks row 8 again and puts the keys back on row 9:

#excerpt-at(auto, "listings/asm/netcat.asm", "nl1:    LDI     TOP_SCROLL", n: 7)

== A copy of the screen

A program cannot read the text engine’s screen back, and the keyboard needs the whole screen. So netcat keeps a copy of rows 0 to 8, 144 bytes at `$0900`, and every character it shows goes there too. After the keyboard, the view is drawn again from the copy: 144 PUTCs, which wrap from row to row by themselves.

#excerpt-at(auto, "listings/asm/netcat.asm", "view:   FCALL   d_cls", to: "        FCALL   legend")

== CONFIG’s keyboard

The keyboard is CONFIG’s own: rows 3 to 8 hold every character from `$20` to `$7F`, sixteen to a row, so a character’s cell is its code less `$20`. `osk.inc` carries CONFIG’s routines unchanged, between marker lines that `tools/vendorcheck.py` checks against CONFIG’s source. netcat supplies what CONFIG’s screens did: the screen around the keyboard, and what 9 and 1 do.

#excerpt-at(auto, "listings/asm/netcat.asm", "; ed_ok: 9. ed_esc: 1.", to: "; ---- OPEN")

== Sending

A WRITE takes one two-byte parameter, the count, then that many bytes: the line, then CR and LF.

#excerpt-at(auto, "listings/asm/netcat.asm", "send:   FNBEGIN NETDEV, NCWRITE, 1", to: "LDR     R8, V_EDIT      ; empty again")

== Back to CONFIG

The program closes the connection and asks the cartridge for CONFIG. `fn_config` writes `$C5` to the CONFIG register, waits for the cartridge to say it is ready, and hands the console over: CONFIG comes up as if the console had just been turned on.

#excerpt-at(auto, "listings/asm/netcat.asm", "quit:   LDV     V_CONN", n: 7)
