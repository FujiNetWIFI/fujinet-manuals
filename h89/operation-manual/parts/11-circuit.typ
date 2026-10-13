#import "../lib.typ": *
#import "../figs.typ": blocks

#chapter(11, "Circuit Description")

#section("General")[
Refer to Pictorial 11-1 while you read this description.

The card joins two different worlds. On one side is the H89’s accessory bus: five-volt logic, an
8-bit data bus, and a set of decoded port-select lines from the CPU logic circuit board. On the
other is the ESP32, a 3.3-volt microcontroller that runs the FujiNet firmware and has the WiFi
radio built in. An 82C55A programmable peripheral interface stands between them. The Computer reads
and writes it as four I/O ports; the ESP32 works its handshake lines directly.
]

#pictorial(caption: [How the card connects the H89 to the FujiNet.], blocks())

#section("Address Decoding")[
The CPU logic circuit board decodes the I/O address and gives each group of eight ports a select
line on the accessory bus. The PORT SEL jumper connects one of four of these, for the groups at 320,
330, 340 and 170, to the card. The 74LS02 (U3) combines the chosen select line with address line A2,
so the 82C55A’s chip select is active for the first four ports of the group only. Address lines A0
and A1 choose among the 82C55A’s port A, port B, port C and control register. The Computer's RD and
WR strobes go straight to the 82C55A.

U3 also inverts the bus's RESET line for the 82C55A, which resets whenever the Computer does.
]

#section("The 82C55A")[
The programs put the 82C55A in Mode 2 by writing 300 octal to its control register. In Mode 2, port A
is a bidirectional, strobed port: a byte the Computer writes is held in port A’s output latch until
the other side takes it, and a byte from the other side is held in the input latch until the
Computer reads it. Port C carries the handshake:

#stable((0.45in, 0.6in, 1fr),
  th[Bit], th[Name], th[Use],
  [PC7], [/OBF], [Low while a byte the Computer wrote is waiting for the ESP32.],
  [PC6], [/ACK], [From the ESP32: it has taken the byte.],
  [PC5], [IBF], [High while a byte from the ESP32 is waiting for the Computer.],
  [PC4], [/STB], [From the ESP32: here is a byte.],
  [PC3], [INTR], [Interrupt request. Not used (J3 open).],
  [PC2], [EN], [Output: the ESP32’s enable. Low holds it in reset.],
  [PC1], [/OE], [Output: turns on the 74LVC245. Also the ESP32’s IO0 start-up strap.],
  [PC0], [DIR], [Output: the 74LVC245’s direction. 1 is toward the ESP32.],
)

To send a byte, a program sets DIR to 1, writes the byte to port A, and waits for /OBF to go high
again, which shows the ESP32 took it. To receive, it sets DIR to 0 and waits for IBF, then reads
port A. The Communication Test (in the Appendix) is a complete example.
]

#section("Level Shifting")[
Port A’s eight data lines reach the ESP32 through a 74LVC245 bus transceiver (U2), powered from 3.3
volts. Its inputs tolerate five volts, so it passes the 82C55A’s five-volt outputs safely to the
ESP32, and the ESP32’s 3.3-volt outputs are high enough for the 82C55A’s inputs. PC0 sets its
direction and PC1 turns it on.

The five port C lines the ESP32 reads (DIR, /OE, EN, IBF and /OBF) come down to 3.3 volts through
dividers of 2.2K and 3.3K resistors, plugged into the socket strip J2. /STB and /ACK go from the
ESP32 to the 82C55A directly.
]

#section("Starting the FujiNet")[
When the Computer resets, the 82C55A’s ports all become inputs and port A leaves Mode 2. The
82C55A holds its inputs high with weak pull-ups, against the dividers, so PC2 may read 1 although
nothing has set the card up. A program sets it up by setting Mode 2 (which makes PC0 through PC2
outputs, all low), then at once writing 006 to port C: EN high, and PC1, and so IO0, high too. An
ESP32 that was held in reset starts, and reads IO0 as it comes out of reset: high means "run the
firmware in flash." The program waits a moment for that, writes 245 (A5H) to port B, which is wired
to nothing, then turns PC1 low to enable the 74LVC245, and the two sides can talk.

A program that finds 245 in port B, and EN high, knows the card is already set up and leaves it
alone. A reset makes port B an input, which reads 377, and any other mode word clears it.

If EN rises with PC1 low instead, the ESP32 starts in its loading mode, waiting for new firmware over
USB. That is how the firmware is updated (Chapter 9).
]

#section("The ESP32 and the microSD Card")[
The ESP32 module carries the processor, its flash memory and PSRAM, the WiFi radio and antenna, and a
USB-to-serial interface for firmware loading and diagnostic output. The microSD socket is wired to
the ESP32’s SPI port, with 10K pull-up resistors (R13 through R16). LED D1 is driven from the ESP32
through R12; the present firmware does not light it.
]

#section("Power")[
The card takes its power from the accessory bus. The 82C55A and the 74LS02 run from the bus's five
volts; the ESP32 module, the 74LVC245 and the microSD card run from 3.3 volts made on the card.
]
