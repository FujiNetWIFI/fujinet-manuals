#import "../lib.typ": *
= netcat <ch-netcat>

`netcat` holds a conversation with a TCP server: what the server sends scrolls up the top of the screen, and what you type goes back a line at a time. It is the network device used both ways at once, and it needs something no other program in this handbook does: text typed on a console with no keyboard.

#sect[Typing without a keyboard]

The keypad types digits by itself. Everything else comes from an on-screen keyboard of three rows, letters, then punctuation, with the stick moving a reverse-video cursor round it and the bottom button typing the key under the cursor. `_` types a space.

#tbl((auto, 1fr),
  th[Control], th[Does],
  [The stick], [Moves the cursor one key per push. It must come back to the middle before it moves again, so a held stick does not race across the keyboard.],
  [The bottom button], [Types the key under the cursor, once per press.],
  [#key("0")–#key("9")], [Type themselves.],
  [#key("*")], [Rubs out the last character.],
  [#key("#")], [Sends the line, with CR LF on the end.],
  [#key("START")], [Closes the connection.],
)

#shots("asm-netcat", "c-netcat", caption: [netcat in assembly and in C, after the server’s greeting and one line typed: A and B from the keyboard, 1 and 2 from the keypad, then #key("#").])

On the bench the far end is `listings/fixtures/ncserver.py`, which greets each connection with `NETCAT SAYS HI` and answers every line with `ECHO` and the line in capitals.

#sect[The loop]

`netcat` opens its devicespec, `N:TCP://127.0.0.1:8769/`, read and write (mode 12), and then never waits for anything. Every frame it looks at the stick, the button and the keypad; every eighth frame it asks STATUS whether anything has arrived, and READs it if so.

#ex((path: "listings/asm/netcat.s", from: "loop:   WAITFRAME", to: ".endproc"), t-asm)

#ex((path: "listings/c/netcat.c", from: "    for (;;) {", to: "        if ((mt_frames & 7) == 0)"), t-c)

A STATUS takes the cartridge about as long as any small transaction, a few milliseconds on the bench; once every eight frames leaves the stick and keypad smooth. What the server sends while nobody asks waits in the FujiNet.

#sect[Receiving]

STATUS, then a READ of what is waiting, at most 128 bytes, then each byte onto the screen: CR is dropped, LF starts a new row, and a row that reaches the edge wraps. When the text reaches the bottom of its area, the rows move up one.

#ex((path: "listings/asm/netcat.s", from: ".proc receive", to: "next:   lda     nleft"), t-asm)

The C version lets the library count:

#ex((path: "listings/c/netcat.c", from: "static void receive(void)", to: "void main(void)"), t-c)

#sect[Sending]

A WRITE has one two-byte parameter, the count, and the bytes as its payload. `netcat` puts CR and LF on the end of the typed line, sends it, and clears the line.

#ex((path: "listings/asm/netcat.s", from: ".proc send", to: "        jsr     go_ack"), t-asm)

#ex((path: "listings/c/netcat.c", from: "static void send(void)", to: "/* One step per push"), t-c)

#note[The keyboard’s cursor is the cell’s own character in reverse video: bit 7 set in screen memory, which `CHACTL` = 2 tells ANTIC to show inverted. In assembly that is an `EOR #$80` on the cell; in C, `mt_setpal(1, 1)` at the cell.]
