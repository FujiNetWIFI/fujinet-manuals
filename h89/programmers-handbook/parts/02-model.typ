#import "../lib.typ": *
#import "../figs.typ": blocks, portmap
#import "../pfigs.typ": *
#import "../prog.typ": *

#chapter(2, "Programming Model")

#section("General")[
To a program, the FujiNet card is four I/O ports and a clock. There is no memory on the card for
the H89 to see, no interrupt, and no ROM. A program writes bytes to one port and reads bytes from
it, watches a second port to know when it may, and uses the H89's 2-millisecond clock to give up
if the FujiNet does not answer.

Those bytes make *requests* and *replies*, in the FujiBus protocol (Chapter 3). Everything the
FujiNet can do --- join a network, mount a disk image, fetch a web page --- is a request from the
H89 and a reply from the FujiNet, one at a time. The FujiNet never speaks first.

This chapter covers the ports and the handshake. Most programs never deal with them directly:
they call `fn_call` in the book's assembly library (Chapter 4), or a function in fujinet-lib
(Chapter 6). But it is worth knowing what those do, and you will need it if you write for the
card in another language.
]

#pictorial(caption: [The path from the H89 to the FujiNet.], blocks())

#section("The Ports")[
The card answers at four consecutive ports, set by its PORT SEL jumper. This Manual, the
book's library and fujinet-lib all assume the setting the Operation Manual recommends, 320Q:

#stable((0.55in, 0.55in, 1fr),
  th[Port], th[Octal], th[Use],
  [D0H], [320Q], [PORTA. The data: every byte to and from the FujiNet goes through it.],
  [D1H], [321Q], [PORTB. Not used.],
  [D2H], [322Q], [PORTC. Status (read) and control (written).],
  [D3H], [323Q], [PCTRL. The 82C55A's control register.],
)

If your card is set to another group (330Q, 340Q or 170Q), change the four equates at the top of
`fujinet.inc` in the book's library. For C, change `IOPORT` in fujinet-lib's
`bus/h89/portio.c` and rebuild the library (Chapter 6).

Port D0H is the 82C55A's port A in Mode 2: one byte in each direction can wait there. A byte the
H89 writes stays in port A's output latch until the ESP32 takes it, and a byte the ESP32 sends
stays in its input latch until the H89 reads it. Port C tells the H89 which latch is full.
]

#section("Port C")[
Reading port D2H gives the 82C55A's port C. The top five bits are the handshake; the bottom three
are the outputs that start the ESP32 and steer the bus transceiver, read back:

#stable((0.42in, 0.55in, 0.5in, 1fr),
  th[Bit], th[Name], th[Mask], th[Meaning],
  [PC7], [/OBF], [80H], [0 while a byte the H89 wrote waits for the ESP32. `PC_OBF`.],
  [PC6], [/ACK], [40H], [From the ESP32: 0 while it takes the byte. `PC_ACK`.],
  [PC5], [IBF], [20H], [1 while a byte from the ESP32 waits for the H89. `PC_IBF`.],
  [PC4], [/STB], [10H], [From the ESP32: 0 while it puts a byte in. `PC_STB`.],
  [PC3], [INTR], [08H], [Interrupt request. Not connected (J3 open).],
  [PC2], [EN], [04H], [1 = the ESP32 is running. `PC_EN`.],
  [PC1], [/OE], [02H], [0 = the bus transceiver is on. `PC_OE`.],
  [PC0], [DIR], [01H], [1 = toward the ESP32, 0 = toward the H89. `PC_DIR`.],
)

A program changes PC0, PC1 and PC2 one at a time with the 82C55A's bit set/reset command:
writing 00000bbs (binary) to PCTRL sets bit *bbb* of port C to *s*. So `DIR_TO_ESP` (01H) sets
DIR, `DIR_TO_H89` (00H) clears it, and `OE_ON` (02H) clears /OE.

#note[Writing a mode word to PCTRL clears all of port C's outputs, and EN with them. That resets
the ESP32. Write the mode word only when the FujiNet is not already running.]
]

#section("Starting the FujiNet")[
When the H89 is reset, the 82C55A's ports become inputs, a resistor pulls the ESP32's enable low,
and the FujiNet stops. Something must start it again before any program can talk to it. FN.DVD,
FNDISK, FNON and CONFIG all do it, and so does every program in this Manual, with `card_on`:

#snip("model.card_on", "asm", caption: [CARD.INC --- start the FujiNet if nothing has])

`card_on` looks at EN first. If the FujiNet is running, it leaves it alone; a reset would throw away
the drives FNDISK has mounted and the network connections other programs have open. Otherwise it
sets Mode 2 and brings EN up with PC1 (and so the ESP32's IO0 strap) high, which tells the ESP32 to
run the firmware in its flash. It pulses EN once more to be sure of a clean start, waits 200 ms,
throws away any byte latched while the ESP32 woke up, and turns the bus transceiver on facing
the H89.

fujinet-lib does the same the first time a program calls it.

#note[The firmware needs a little while after EN rises before it answers. A request sent sooner
waits in port A until it does; `fn_call` allows 15 seconds for a reply to begin.]

#pictorial(caption: [Starting the ESP32. PC1 is low after the transceiver is turned on.], start-timing())

#sub("Is it there?")
With no card at the selected ports, every port reads FFH. A program that waits for IBF would see a
byte at once, and another, forever. `card_present` checks the three output bits instead, which
`card_on` has left at EN = 1, /OE = 0, DIR = 0:

#snip("model.card_present", "asm", caption: [CARD.INC --- Z if the card is there and running])
]

#section("Sending a Byte")[
To send, the program sets DIR to 1, so the transceiver drives toward the ESP32. Then, for each
byte, it waits until /OBF is high, which means port A's output latch is empty, and writes the
byte to port A:

#pictorial(caption: [Sending a byte. (1) The H89 writes port A. (2) /OBF falls. (3) The ESP32 takes
the byte. (4) /OBF rises: the next byte may be written.], send-timing())

#snip("model.putc", "asm", caption: [FUJIBUS.INC --- send the byte in A])

After the last byte of a request, the program waits once more for /OBF to rise, so it knows the
ESP32 has the whole request, and sets DIR back to 0.

#warning[The firmware waits at most 100 ms for each byte of a request after the first. A program
that pauses longer in the middle of a request --- to compute a checksum the slow way, say, or
because it is interpreted --- loses the whole request: the FujiNet sends no reply, and treats the
rest of the bytes as data for its modem (Chapter 12). Build the request in memory first, then send
it in one go.]
]

#section("Receiving a Byte")[
To receive, DIR must be 0. The ESP32 puts a byte in port A's input latch and IBF goes high; the
program reads port A, which clears IBF and lets the ESP32 send the next:

#pictorial(caption: [Receiving a byte. (1) The ESP32 strobes the byte in. (2) IBF rises. (3) The H89
reads port A. (4) IBF falls.], recv-timing())

#snip("model.getc", "asm", caption: [FUJIBUS.INC --- the next byte into A, or give up])

The ESP32 waits up to a second for each byte to be taken. A program that reads its reply slowly
loses the rest of it.

#sub("Turning the bus around")
Both sides share port A's eight lines, so only one may drive them. The rules are simple:

- DIR is 0 except while the H89 is sending a request.
- The H89 never sends while a reply is coming. If it does, the ESP32 stops sending at once: the
  firmware sees /OBF fall and cuts its reply short.
- A reply always comes after a request, never before. The FujiNet does not speak unless spoken to.
]

#section("Time")[
The H89's clock interrupt counts 2-millisecond ticks into a 16-bit word in memory. HDOS keeps it at
201BH (040.033); Heath's CP/M BIOS at 000BH. The book's library calls it `TICKS`, and fujinet-lib
reads the same word:

#snip("model.tick", "asm", caption: [CARD.INC --- wait for the next tick])

To time something, a program saves `TICKS` at the start and subtracts. The subtraction works across
the moment the count wraps from FFFFH to 0:

#snip("model.expired", "asm", caption: [FUJIBUS.INC --- has `fn_tlim` ticks passed since `fn_t0`?])

Both sides of the card give up when the other stops. These are the limits:

#stable((1.55in, 1fr),
  th[Who waits], th[How long],
  [Firmware, between request bytes], [100 ms; then the request is lost (see above)],
  [Firmware, for the H89 to take a reply byte], [1 second; then the rest of the reply is lost],
  [Book library, for a reply to begin], [15 seconds (`RX_FIRST`)],
  [Book library, between reply bytes], [1 second (`RX_TIMEOUT`)],
  [Book library, for a request byte to be taken], [1 second (`TX_TIMEOUT`)],
  [fujinet-lib, for any reply byte], [15 seconds],
  [fujinet-lib, for a request byte to be taken], [forever],
)

#warning[fujinet-lib never gives up while sending. If the FujiNet is not running --- the card was
never started, or the ESP32 has crashed --- a C program hangs in its first call, and only the
H89's RESET will free it. Check with `card_present` first if that matters to you.]
]

#section("No Interrupts")[
The card's interrupt line is not connected (jumper J3 is open), and nothing in the firmware would
use it. A program learns that something has happened only by asking. That matters most for the
network device: data arriving from the far end of a connection waits in the FujiNet until the
program asks how much there is, with the network STATUS command (Chapter 10), and then reads it.
A program that talks to the network therefore loops: check the keyboard, ask for STATUS, read what
has come, and around again. NETCAT (Chapter 13) is the pattern.
]

#section("Sharing the Card")[
Several programs may use the card in one session: FN.DVD or FNDISK, for the FujiNet drives; CONFIG;
and yours. This works because every transaction is complete before the code that made it returns.
A disk read by HDOS's FN.DVD in the middle of your program's work starts and finishes between two
of your requests, and leaves the card as it found it: running, transceiver on, DIR = 0.

Keep to that, and your programs will get on with the drivers too:

- Start the card with `card_on`, which leaves a running FujiNet alone.
- Leave DIR at 0 and /OE at 0 between requests.
- Never leave a request half sent, or a reply half read. If your program gives up on a reply, take
  and discard whatever is still coming before the next request. `fn_call` does this for you
  (it waits until 100 ms pass with nothing arriving).
- Don't write the 82C55A's mode word while the FujiNet is running.

The FujiNet's state is shared, too. If your program mounts a different image in drive slot 2, the
drive FNDISK calls FN2: (HDOS) or F: (CP/M) changes under it. Programs that change the drives should
say so.
]

#section("Memory")[
#grid(columns: (1fr, 1fr), column-gutter: 0.2in,
  [#align(center, lab[HDOS 2.0, 56K])
   #memmap((
     ("FFFF", none, [HDOS resident, device drivers \ (FN.DVD when loaded)]),
     ("S.SYSM", none, [free: the stack and heap of a \ C program grow here], false, 0.45in),
     ("S.USRM", none, [your program], true, 0.45in),
     ("2280", none, [command line, HDOS stack]),
     ("2000", none, [HDOS system values \ TICKS at 201BH]),
     ("1FFF", none, [monitor and H17 ROMs]),
   ), w: 1.25in)],
  [#align(center, lab[CP/M 2.2.04, 62K])
   #memmap((
     ("FFFF", none, [BIOS (FNDISK hooks in here)]),
     ("(0006)", none, [BDOS, then the CCP]),
     ("", none, [free], false, 0.45in),
     ("0100", none, [your program (the TPA)], true, 0.45in),
     ("0080", none, [command tail, default DMA]),
     ("0000", none, [page zero: BDOS jump, \ TICKS at 000BH]),
   ), w: 1.25in)])

HDOS loads a program at 2280H (042.200) and starts it with SP pointing at the command line's
arguments, just below. S.USRM and S.SYSM, at 20D2H and 20D0H, give the end of the loaded program
and the start of the memory HDOS keeps for itself. CP/M loads a program at 0100H; the word at
0006H gives the start of the BDOS, and the space between is the program's to use.

Chapter 4 shows how the book's library deals with both, and Chapter 6 how z88dk's C does.
]
