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
line on the accessory bus. The PORT SEL jumper (J1) connects one of four of these, for the groups at
320, 330, 340 and 170, to the card. The 74LS02 (U1) combines the chosen select line with address
line A2, which JP1 passes straight through (on 0) or inverted (on 4), so the 82C55A’s chip select
is active for the first four ports of the group or the last four. Address lines A0 and A1 choose
among the 82C55A’s port A, port B, port C and control register. The Computer's RD and WR strobes go
straight to the 82C55A.

U1 also inverts the bus's RESET line for the 82C55A, which resets whenever the Computer does.
]

#section("The 82C55A")[
The 82C55A is U2, a PLCC part, or U6, a 40-pin DIP in the same place; only one is fitted. The
programs put it in Mode 2 by writing 300 octal to its control register. In Mode 2, port A is a
bidirectional, strobed port: a byte the Computer writes is held in port A’s output latch until the
other side takes it, and a byte from the other side is held in the input latch until the Computer
reads it. Port C carries the handshake:

#stable((0.45in, 0.6in, 1fr),
  th[Bit], th[Name], th[Use],
  [PC7], [/OBF], [Low while a byte the Computer wrote is waiting for the ESP32 (IO35).],
  [PC6], [/ACK], [From the ESP32 (IO15): it has taken the byte.],
  [PC5], [IBF], [High while a byte from the ESP32 (IO34) is waiting for the Computer.],
  [PC4], [/STB], [From the ESP32 (IO4): here is a byte.],
  [PC3], [INTR], [Interrupt request, through Q1 to J3. Not used (J3 open).],
  [PC2], [--], [Not connected (see "The Rework").],
  [PC1], [--], [Output, no longer used. It turned on U3, the data transceiver the card no longer has.],
  [PC0], [--], [Output, no longer used. It set U3’s direction.],
)

To send a byte, a program writes it to port A and waits for /OBF to go high again, which shows the
ESP32 took it. To receive, it waits for IBF, then reads port A. The Communication Test (in the
Appendix) is a complete example.

Port B drives the eight lamps, D3 through D10, through the resistor network RN1: a 0 bit lights its
lamp. It is also brought out on J12. The FujiNet does not use it.
]

#section("Level Shifting")[
Port A’s eight data lines run straight to the ESP32. U3, the 74LVC245 bus transceiver that stood
between them on the V1.1 board, is gone, and so is R1, which held it off after a reset. In Mode 2 the
82C55A drives port A only while the ESP32 holds /ACK low to take a byte, and the ESP32 drives it
only to strobe a byte in, so the two never drive the lines at the same time, and the Computer never
has to choose a direction.

U5, a 74LVC245 wired to pass one way only, brings IBF and /OBF down to 3.3 volts for the ESP32. /STB
and /ACK go from the ESP32 to the 82C55A directly. J2 brings the handshake lines
out for a logic analyzer.
]

#section("The Rework")[
The card is a V1.1 board reworked for the present firmware. The ESP32’s EN, IO0 and IO2 are no
longer connected to the card, and LED D1 and its resistor R7, on IO22, are removed. Two wires take
/OE from U5 to IO21, and DIR to IO22; the firmware for the card without U3 no longer reads them. So
nothing the Computer does can start, stop or restart the ESP32, or put it in its loading mode, and
IO0 and IO2, which the ESP32 reads as it starts, are left to the module.
]

#section("When the FujiNet Starts")[
The ESP32 starts when the Computer is turned on, or when a USB cable brings it power, and runs the
firmware in its flash. When the Computer resets, the 82C55A’s ports all become inputs and port A
leaves Mode 2, but the ESP32 is not touched.

A program sets the card up with one mode word, 300, which puts port A in Mode 2 and makes port B and
PC0 through PC2 outputs, all low, and every lamp lit. Then it reads
port A once, to drop any byte left from before. A mode word touches only the 82C55A, so a program may
send one whenever it starts.
]

#section("The ESP32 and the microSD Card")[
The ESP32 module, U4, is an ESP32-DevKitC-VE. It carries the processor, its flash memory and PSRAM,
the WiFi radio and antenna, and a USB-to-serial interface for firmware loading and diagnostic
output, with the EN and BOOT buttons that go with it. The microSD breakout board plugs into J6. Its
socket is wired to the ESP32’s SPI port (IO5, IO18, IO19 and IO23), with 10K pull-up resistors (R3
through R6).
]

#section("Power")[
The card takes its power from the accessory bus. The 82C55A and the 74LS02 run from the bus's five
volts, which also reach the ESP32 module through the diode D2. The module's own regulator makes 3.3
volts for the ESP32, U5 and the microSD card. D2 keeps a USB cable's power off the bus.
]
