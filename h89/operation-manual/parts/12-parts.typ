#import "../lib.typ": *

#chapter(12, "Parts List", gap: 0.55in)

#grid(columns: (1fr, 1fr), column-gutter: gutter, [
The circuit component numbers are those printed on the card. Parts marked with an asterisk (\*) are
described from the card itself and should be confirmed against your card's own markings.

#wide-head("Integrated Circuits", above: 0.6em)
#stable((0.55in, 1fr),
  th[Comp. No.], th[Description],
  [U1], [82C55A programmable peripheral interface (OKI MSM82C55A), 40 pins],
  [U2], [74LVC245 octal bus transceiver, 20 pins],
  [U3], [74LS02 quad 2-input NOR gate, 14 pins],
  [U4\*], [IC on the prototype area, 20 pins (a second 74LVC245)],
)

#wide-head("Modules")
#stable((0.55in, 1fr),
  th[Comp. No.], th[Description],
  [--], [ESP32-DevKitC-VE module (ESP32-WROVER-E, 8 MB flash)],
  [--], [microSD card breakout board],
)

#wide-head("Resistors")
#stable((0.55in, 1fr),
  th[Comp. No.], th[Description],
  [R11], [10K],
  [R12], [560 Ω (LED D1)],
  [R13--R16], [10K (microSD pull-ups)],
  [J2], [Divider resistors, in the socket strip: 2.2K (5) and 3.3K (5)],
)
], [
#wide-head("Capacitors", above: 0pt)
#stable((0.55in, 1fr),
  th[Comp. No.], th[Description],
  [C3, C4], [0.1 µF],
  [--\*], [47 µF electrolytic],
)

#wide-head("Semiconductors and Indicators")
#stable((0.55in, 1fr),
  th[Comp. No.], th[Description],
  [D1], [LED, green ("FujiNet_IO")],
  [Q1\*], [TO-92 device],
)

#wide-head("Connectors and Jumpers")
#stable((0.55in, 1fr),
  th[Comp. No.], th[Description],
  [--], [10-pin bus connector (data D0--D7)],
  [--], [25-pin bus connector (power, address, control, port selects)],
  [PORT SEL], [2 × 4 pin header, with one jumper (shunt)],
  [J3], [2 × 3 pin header (INT LVL)],
  [--\*], [3-pin header],
  [J2], [Socket strip for the divider resistors],
)
])
