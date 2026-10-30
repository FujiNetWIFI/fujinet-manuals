#import "../lib.typ": *

#chapter(12, "Parts List", gap: 0.55in)

#grid(columns: (1fr, 1fr), column-gutter: gutter, [
The circuit component numbers are those printed on the card (V1.1). Parts marked with an asterisk
(\*) should be confirmed against your card's own markings. The rework (Chapter 11) removes D1 and
R7 and adds two wires.

#wide-head("Integrated Circuits", above: 0.6em)
#stable((0.55in, 1fr),
  th[Comp. No.], th[Description],
  [U1], [74LS02 quad 2-input NOR gate, 14 pins],
  [U2\*], [82C55A programmable peripheral interface, 44-pin PLCC; or U6],
  [U6\*], [82C55A, 40-pin DIP, in U2’s place],
  [U5], [74LVC245 octal bus transceiver, 20 pins (control lines)],
)

#wide-head("Modules")
#stable((0.55in, 1fr),
  th[Comp. No.], th[Description],
  [U4], [ESP32-DevKitC-VE module (ESP32-WROVER-E, 8 MB flash)],
  [--], [microSD card breakout board, on J6],
)

#wide-head("Resistors")
#stable((0.55in, 1fr),
  th[Comp. No.], th[Description],
  [R2], [10K (Q1’s base)],
  [R3--R6], [10K (microSD pull-ups)],
  [R7], [560 Ω (LED D1). Removed in the rework.],
  [RN1], [1.2K network, 8 resistors (the lamps)],
)

#wide-head("Capacitors")
#stable((0.55in, 1fr),
  th[Comp. No.], th[Description],
  [C1], [47 µF electrolytic],
  [C2--C4], [0.1 µF],
)
], [
#wide-head("Semiconductors and Indicators", above: 0pt)
#stable((0.55in, 1fr),
  th[Comp. No.], th[Description],
  [D1], [LED, red ("FujiNet_IO"). Removed in the rework.],
  [D2], [1N5819 Schottky diode],
  [D3--D10], [LEDs, the lamps for port B (PB0--PB7)],
  [Q1], [2N3904 transistor],
)

#wide-head("Connectors and Jumpers")
#stable((0.78in, 1fr),
  th[Comp. No.], th[Description],
  [J1], [PORT SEL: 2 × 4 pin header, with one jumper],
  [JP1], [BA2: 3-pin header, with one jumper],
  [J2], [Logic analyzer header, 10 pins],
  [J3], [/INTE_ENA: 2 × 3 pin header],
  [J4, J7, J8\*], [Rows of pads for the 10-pin bus connector (data D0--D7)],
  [J5, J9, J11\*], [Rows of pads for the 25-pin bus connector (power, address, control, port selects)],
  [J6], [microSD breakout header, 6 pins],
  [J12], [Port B header, 10 pins],
  [--], [Rework wires: /OE to IO21, DIR to IO22],
)
])
