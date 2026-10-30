// figs.typ -- the line drawings. Measured from the KiCad render of the V1.1
// card (images/photo/board.jpg, at half scale: the board is 666 x 342 there,
// its connector tab 315 x 42), drawn the way Heath drew its pictorials: plain
// outlines, part numbers in Helvetica, leader lines out to the labels.

#import "lib.typ": *

#let lw = 0.6pt + ink
#let thin = 0.4pt + ink

// ------------------------------------------------------------- primitives
// a DIP, pin 1 end at the top (vertical) or left (horizontal)
#let dip(x, y, w, h, pins, label, sub: none, s: 1pt, vertical: true) = {
  let per = calc.quo(pins, 2)
  place(dx: x * s, dy: y * s, {
    place(rect(width: w * s, height: h * s, fill: rgb("#3b3a38"), stroke: lw, radius: 0.6pt))
    // the notch
    if vertical { place(dx: w * s / 2 - 3 * s, dy: -0.2pt, circle(radius: 3 * s, fill: white, stroke: thin)) }
    else { place(dx: -3 * s, dy: h * s / 2 - 3 * s, circle(radius: 3 * s, fill: white, stroke: thin)) }
    // the pins
    for i in range(per) {
      if vertical {
        let py = (i + 0.5) * h / per
        place(dx: -2.2 * s, dy: (py - 1.2) * s, rect(width: 2.2 * s, height: 2.4 * s, fill: white, stroke: thin))
        place(dx: w * s, dy: (py - 1.2) * s, rect(width: 2.2 * s, height: 2.4 * s, fill: white, stroke: thin))
      } else {
        let px = (i + 0.5) * w / per
        place(dx: (px - 1.2) * s, dy: -2.2 * s, rect(width: 2.4 * s, height: 2.2 * s, fill: white, stroke: thin))
        place(dx: (px - 1.2) * s, dy: h * s, rect(width: 2.4 * s, height: 2.2 * s, fill: white, stroke: thin))
      }
    }
  })
}
#let resistor(x, y, len, s: 1pt, vertical: false) = place(dx: x * s, dy: y * s, {
  if vertical {
    place(dx: 2 * s, line(start: (0pt, 0pt), end: (0pt, len * s), stroke: thin))
    place(dx: 0pt, dy: len * s * 0.25, rect(width: 4 * s, height: len * s * 0.5, radius: 1.5pt, fill: rgb("#d9c7a0"), stroke: thin))
  } else {
    place(dy: 2 * s, line(start: (0pt, 0pt), end: (len * s, 0pt), stroke: thin))
    place(dx: len * s * 0.25, rect(width: len * s * 0.5, height: 4 * s, radius: 1.5pt, fill: rgb("#d9c7a0"), stroke: thin))
  }
})
#let header(x, y, cols, rows, s: 1pt, pitch: 7.2) = place(dx: x * s, dy: y * s, {
  place(rect(width: cols * pitch * s, height: rows * pitch * s, fill: rgb("#2c2b29"), stroke: thin))
  for c in range(cols) { for r in range(rows) {
    place(dx: (c + 0.5) * pitch * s - 1.1 * s, dy: (r + 0.5) * pitch * s - 1.1 * s,
      rect(width: 2.2 * s, height: 2.2 * s, fill: rgb("#e6d9a8"), stroke: none))
  } }
})
// a label with a leader line from (x0,y0) on the drawing to (x1,y1); the
// label sits right of x1 (anchor left) or ends at x1 (anchor right)
#let callout(x0, y0, x1, y1, body, s: 1pt, anchor: left) = {
  place(line(start: (x0 * s, y0 * s), end: (x1 * s, y1 * s), stroke: 0.45pt + ink))
  place(dx: x0 * s - 1.4pt, dy: y0 * s - 1.4pt, circle(radius: 1.4pt, fill: ink, stroke: none))
  let t = box(fill: white, inset: (x: 1.5pt, y: 1pt), text(font: f-sans, size: 6.8pt, body))
  if anchor == left { place(dx: x1 * s + 1pt, dy: y1 * s - 5pt, t) }
  else { place(dx: x1 * s - 1.2in - 1pt, dy: y1 * s - 5pt, box(width: 1.2in, align(right, t))) }
}

// ------------------------------------------------------------- the card
// card(s) -- the board, in half-scale render pixels times s. The V1.1 card
// as reworked: D1 and R7 gone (dashed), EN, IO0 and IO2 cut from the module
// (x), and wires bringing /OE and DIR to IO21 and IO22 (red rings).
#let card(s: 1pt, labels: true) = {
  let W = 666
  let H = 342
  let wire = rgb("#b3261e")
  let pad(x, y, r: 1.6) = place(dx: (x - r) * s, dy: (y - r) * s, circle(radius: r * s, fill: rgb("#e6d9a8"), stroke: 0.25pt + ink))
  // room around the board for the labels: 150 to the left, 70 above, 75 below, 20 right
  box(width: (W + 170) * s, height: (H + 42 + 145) * s, place(dx: 150 * s, dy: 70 * s, {
    // the connector tab, with its three rows of pads for each bus connector
    place(dx: 48 * s, dy: (H - 1) * s, rect(width: 315 * s, height: 43 * s, stroke: lw, fill: rgb("#f4f1e8")))
    for v in (351, 365, 375.5) {
      for i in range(10) { pad(57.5 + i * 8.7, v) }
      for i in range(25) { pad(155.5 + i * 8.6, v) }
    }
    // the board
    place(rect(width: W * s, height: H * s, stroke: 0.9pt + ink, fill: rgb("#f4f1e8")))
    // prototype area: an L of pads
    let field = tiling(size: (5.4 * s, 5.4 * s), place(dx: 1.6 * s, dy: 1.6 * s, circle(radius: 1.1 * s, stroke: 0.25pt + ink.lighten(30%))))
    place(dx: 422 * s, dy: 4 * s, rect(width: 240 * s, height: 334 * s, stroke: thin, fill: field))
    place(dx: 321 * s, dy: 192 * s, rect(width: 101 * s, height: 146 * s, stroke: thin, fill: field))
    place(dx: 321.4 * s, dy: 192.4 * s, rect(width: 101 * s, height: 145 * s, stroke: none, fill: rgb("#f4f1e8").transparentize(100%)))
    // silkscreen
    place(dx: 7 * s, dy: 7 * s, text(font: f-sans, size: 9 * s, weight: "bold")[H89 FujiNet \ V1.1 \ 10/31/2026])
    place(dx: 236 * s, dy: 124 * s, box(width: 84 * s, text(font: f-sans, size: 5.2 * s)[Note: Please install board onto H89 "RIGHT" sided connectors.]))
    // D1 and R7, removed in the rework
    place(dx: (121.5 - 7) * s, dy: (17 - 7) * s, circle(radius: 7 * s, stroke: (paint: ink, thickness: 0.4pt, dash: "dashed")))
    place(dx: 33 * s, dy: 64 * s, rect(width: 4 * s, height: 28 * s, radius: 1.5pt, stroke: (paint: ink, thickness: 0.4pt, dash: "dashed")))
    // R6-R3, the microSD pull-ups
    for x in (52.5, 69, 86, 103) { resistor(x - 2, 64, 28, s: s, vertical: true) }
    // J6, for the microSD breakout; J2, the logic analyzer header; J12, port B
    header(150, 80, 6, 1, s: s, pitch: 9.2)
    header(228, 18, 10, 1, s: s, pitch: 8.6)
    header(321, 69, 1, 10, s: s, pitch: 8.6)
    // D2
    resistor(234.5, 64, 38, s: s, vertical: true)
    // the lamps D3-D10, RN1, the +5 V and GND pins
    for i in range(8) { place(dx: (365.5 - 7) * s, dy: (19.5 + i * 22.6 - 7) * s, circle(radius: 7 * s, fill: rgb("#55534f"), stroke: lw)) }
    place(dx: 397 * s, dy: 55 * s, rect(width: 8 * s, height: 73 * s, radius: 2pt, fill: rgb("#d9c7a0"), stroke: thin))
    header(409, 6, 1, 4, s: s, pitch: 9)
    // the chips
    dip(50, 110, 47, 168, 40, [U6 82C55A], s: s)
    dip(246, 187, 35, 82, 20, [U5], s: s)
    dip(94, 300, 61, 25, 14, [U1], s: s, vertical: false)
    // C1 (47 uF), C2-C4, R1, R2
    place(dx: (6.5 - 14) * s, dy: (329.5 - 14) * s, circle(radius: 14 * s, fill: rgb("#9aa7bd"), stroke: lw))
    for (x, y) in ((74, 283), (85, 308), (264, 278)) {
      place(dx: (x - 4.5) * s, dy: (y - 2.5) * s, rect(width: 9 * s, height: 5 * s, radius: 2pt, fill: rgb("#e2b84a"), stroke: thin))
    }
    resistor(224, 288, 28, s: s)
    resistor(274, 288, 24, s: s)
    // JP1 (shunt on 0), J1 PORT SEL (shunt on 320Q), J3 (empty), Q1
    header(185, 308, 1, 3, s: s, pitch: 8.5)
    place(dx: 184 * s, dy: 307 * s, rect(width: 10.5 * s, height: 18 * s, radius: 1pt, fill: rgb("#1c1b1a"), stroke: thin))
    header(219, 313, 4, 2, s: s, pitch: 8.5)
    place(dx: 218 * s, dy: 312 * s, rect(width: 10.5 * s, height: 19 * s, radius: 1pt, fill: rgb("#1c1b1a"), stroke: thin))
    header(262, 313, 3, 2, s: s, pitch: 8.5)
    place(dx: 299 * s, dy: 318 * s, rect(width: 14 * s, height: 12 * s, radius: (top-left: 6 * s, top-right: 6 * s), fill: rgb("#2c2b29"), stroke: thin))
    // the ESP32 module (U3 is under it), USB connector at the top, antenna at the bottom
    place(dx: 135 * s, dy: 114 * s, rect(width: 92 * s, height: 175 * s, fill: rgb("#2d2c2b"), stroke: lw, radius: 1pt))
    place(dx: 169 * s, dy: 109 * s, rect(width: 24 * s, height: 14 * s, fill: rgb("#b8bcc2"), stroke: thin))
    place(dx: 148 * s, dy: 205 * s, rect(width: 66 * s, height: 56 * s, fill: rgb("#c2c5c9"), stroke: thin))
    place(dx: 148 * s, dy: 261 * s, rect(width: 66 * s, height: 26 * s, fill: rgb("#1e1d1c"), stroke: thin))
    place(dx: 160 * s, dy: 228 * s, text(font: f-sans, size: 5.5pt, fill: ink)[ESP32])
    for i in range(19) {
      place(dx: (139 - 1.2) * s, dy: (118 + i * 8.25 - 1.2) * s, circle(radius: 1.2 * s, fill: rgb("#e6d9a8"), stroke: none))
      place(dx: (224 - 1.2) * s, dy: (118 + i * 8.25 - 1.2) * s, circle(radius: 1.2 * s, fill: rgb("#e6d9a8"), stroke: none))
    }
    // the rework: IO0, IO2 (left, pins 5 and 6) and EN (right, pin 18) cut; IO21, IO22 wired
    let cut(x, y) = {
      place(line(start: ((x - 3) * s, (y - 3) * s), end: ((x + 3) * s, (y + 3) * s), stroke: 0.7pt + wire))
      place(line(start: ((x - 3) * s, (y + 3) * s), end: ((x + 3) * s, (y - 3) * s), stroke: 0.7pt + wire))
    }
    cut(139, 118 + 4 * 8.25)
    cut(139, 118 + 5 * 8.25)
    cut(224, 118 + 17 * 8.25)
    for i in (13, 16) { place(dx: (139 - 3.2) * s, dy: (118 + i * 8.25 - 3.2) * s, circle(radius: 3.2 * s, stroke: 0.8pt + wire)) }
    if labels {
      callout(121.5, 17, 60, -46, [D1, R7 (removed)], s: s)
      callout(178, 80, 165, -46, [J6: microSD breakout], s: s)
      callout(365.5, 19.5, 330, -46, [Lamps D3--D10 (port B)], s: s)
      callout(413, 12, 470, -46, [+5 V and GND], s: s)
      callout(236.5, 84, 195, -22, [D2], s: s)
      callout(270, 18, 250, -22, [J2: logic analyzer], s: s)
      callout(401, 58, 400, -22, [RN1], s: s)
      callout(560, 60, 560, -22, [prototype area], s: s)
      callout(325.5, 143, 470, 143, [J12: port B], s: s)
      callout(266, 228, 470, 228, [U5 74LVC245], s: s)
      callout(306, 324, 470, 300, [Q1], s: s)
      callout(52.5, 78, -10, 66, [R3--R6], s: s, anchor: right)
      callout(180, 116, -10, 92, [U4 ESP32 module, \ its USB connector \ (U3 74LVC245 under it)], s: s, anchor: right)
      callout(60, 180, -10, 160, [U6 82C55A \ (or U2, a PLCC)], s: s, anchor: right)
      callout(120, 312, -10, 296, [U1 74LS02], s: s, anchor: right)
      callout(2, 336, -10, 345, [C1 47 µF], s: s, anchor: right)
      callout(95, 375.5, 40, 412, [10-pin bus connector], s: s, anchor: right)
      callout(189, 316, 150, 412, [JP1 (BA2) on 0], s: s)
      callout(270, 318, 290, 412, [J3 (/INTE_ENA)], s: s)
      callout(224, 318, 205, 432, [PORT SEL (J1) on 320Q], s: s)
      callout(300, 375.5, 380, 432, [25-pin bus connector], s: s)
      // the rework, as a key
      place(dx: 500 * s, dy: 392 * s, box(width: 186 * s, stroke: 0.45pt + ink, inset: 3pt, {
        set text(font: f-sans, size: 6.4pt)
        let xmark = box(width: 6pt, height: 6pt, {
          place(line(start: (0.5pt, 0.5pt), end: (5.5pt, 5.5pt), stroke: 0.7pt + wire))
          place(line(start: (0.5pt, 5.5pt), end: (5.5pt, 0.5pt), stroke: 0.7pt + wire))
        })
        let ring = box(width: 6pt, height: 6pt, circle(radius: 2.6pt, stroke: 0.8pt + wire))
        grid(columns: (auto, 1fr), column-gutter: 4pt, row-gutter: 3pt, align: horizon,
          xmark, [IO0, IO2, EN: cut from the card],
          ring, [/OE to IO21, DIR to IO22: rework wires])
      }))
    }
  }))
}

// ---------------------------------------------------------- the jumpers
// JP1, PORT SEL (J1) and J3, left to right as they sit on the card
#let jumpers() = {
  let p = 16pt
  let pin(x, y) = place(dx: x, dy: y, rect(width: 4pt, height: 4pt, fill: rgb("#c9a13a"), stroke: thin))
  let shunt(x, y) = place(dx: x - 3pt, dy: y - 3pt, rect(width: 10pt, height: p + 10pt, radius: 1.5pt, fill: rgb("#1c1b1a"), stroke: lw))
  box(width: 4.6in, height: 1.2in, {
    // JP1: one column of three pins, "0" at the top, a shunt joining the top two
    place(dx: 0.3in, dy: 0.25in, {
      place(rect(width: p, height: 3 * p, fill: rgb("#3a3937"), stroke: lw))
      for r in range(3) { pin(p / 2 - 2pt, r * p + p / 2 - 2pt) }
      shunt(p / 2 - 2pt, p / 2 - 2pt)
      place(dx: -4pt, dy: -14pt, text(font: f-sans, size: 7.5pt, weight: "bold")[JP1 #h(0.3em) BA2])
      place(dx: p + 4pt, dy: p / 2 - 4pt, text(font: f-sans, size: 6pt)[0])
      place(dx: p + 4pt, dy: 2 * p + p / 2 - 4pt, text(font: f-sans, size: 6pt)[4])
      place(dx: -0.12in, dy: 3 * p + 0.12in, text(font: f-sans, size: 7pt)[jumper on 0])
    })
    // PORT SEL (J1): 2 rows x 4 columns, a shunt across the 320Q column
    place(dx: 1.15in, dy: 0.25in, {
      place(rect(width: 4 * p, height: 2 * p, fill: rgb("#3a3937"), stroke: lw))
      for c in range(4) { for r in range(2) { pin(c * p + p / 2 - 2pt, r * p + p / 2 - 2pt) } }
      shunt(p / 2 - 2pt, p / 2 - 2pt)
      place(dx: 0pt, dy: -14pt, text(font: f-sans, size: 7.5pt, weight: "bold")[J1 #h(0.3em) PORT SEL])
      for (c, t) in ("320Q", "330Q", "340Q", "170Q").enumerate() {
        place(dx: c * p, dy: 2 * p + 3pt, box(width: p, align(center, text(font: f-sans, size: 5.6pt, t))))
      }
      place(dx: -0.05in, dy: 2 * p + 0.22in, text(font: f-sans, size: 7pt)[jumper on 320Q])
    })
    // J3: 2 rows x 3 columns, no shunts
    place(dx: 2.65in, dy: 0.25in, {
      place(rect(width: 3 * p, height: 2 * p, fill: rgb("#3a3937"), stroke: lw))
      for c in range(3) { for r in range(2) { pin(c * p + p / 2 - 2pt, r * p + p / 2 - 2pt) } }
      place(dx: 0pt, dy: -14pt, text(font: f-sans, size: 7.5pt, weight: "bold")[J3 #h(0.3em) /INTE_ENA])
      for (c, t) in ("/INT3", "/INT4", "/INT5").enumerate() {
        place(dx: c * p - 2pt, dy: 2 * p + 3pt, box(width: p + 4pt, align(center, text(font: f-sans, size: 5.4pt, t))))
      }
      place(dx: -0.05in, dy: 2 * p + 0.22in, text(font: f-sans, size: 7pt)[no jumpers])
    })
  })
}

// --------------------------------------------- the CPU board's sockets
// Not to scale: the three pairs of accessory sockets, and which is which.
#let sockets() = {
  let pair(x, name10, name25, title, use, mark: false) = place(dx: x, dy: 0pt, {
    place(dx: 0pt, dy: 0.18in, rect(width: 0.42in, height: 0.13in, fill: if mark { yellow } else { white }, stroke: lw))
    place(dx: 0.55in, dy: 0.18in, rect(width: 1.05in, height: 0.13in, fill: if mark { yellow } else { white }, stroke: lw))
    place(dx: 0pt, dy: 0pt, text(font: f-sans, size: 7pt, weight: "bold", name10))
    place(dx: 0.55in, dy: 0pt, text(font: f-sans, size: 7pt, weight: "bold", name25))
    place(dx: 0pt, dy: 0.4in, box(width: 1.6in, text(font: f-sans, size: 6.8pt)[#title \ #use]))
  })
  box(width: 6.2in, height: 1.05in, {
    pair(0in, [P504], [P510], [10-pin #h(0.75in) 25-pin], [A free pair: FujiNet goes here], mark: true)
    pair(2.15in, [P505], [P511], [], [Or here (often the serial interface)], mark: true)
    pair(4.3in, [P506], [P512], [], [Floppy disk interface only])
  })
}

// ------------------------------------------------------- the port map
// as H88 page 5-6: a column of port ranges, the FujiNet's marked
#let portmap() = {
  let rows = (
    ("373", "372", "NMI", false),
    ("362", "", "General purpose port", false),
    ("361", "360", "NMI", false),
    ("357", "350", "Console (the H19)", false),
    ("347", "340", "LP serial port (HA-88-3)", false),
    ("337", "330", "DTE serial port (HA-88-3)", false),
    ("327", "324", "DCE serial port (HA-88-3)", false),
    ("323", "320", "FujiNet card (82C55A)", true),
    ("317", "200", "HDOS reserved", false),
    ("177", "174", "H-17 floppy disk", false),
    ("173", "170", "Z-89-37 floppy disk", false),
  )
  set text(font: f-sans, size: 7pt)
  grid(columns: (0.45in, 2.3in), row-gutter: 0pt,
    ..rows.map(r => (
      align(right + horizon, pad(right: 4pt)[#r.at(0) \ #r.at(1)]),
      rect(width: 100%, height: 0.27in, stroke: lw, fill: if r.at(3) { yellow } else { white },
        align(center + horizon, if r.at(3) { strong(r.at(2)) } else { r.at(2) })),
    )).flatten())
}

// --------------------------------------------------- the block diagram
#let blocks() = {
  let bx(x, y, w, h, body, fill: white) = place(dx: x, dy: y,
    rect(width: w, height: h, stroke: lw, fill: fill, align(center + horizon, text(font: f-sans, size: 7pt, body))))
  let arrow(x0, y0, x1, y1, label: none, both: false) = {
    place(line(start: (x0, y0), end: (x1, y1), stroke: 0.7pt + ink))
    let a = calc.atan2((x1 - x0) / 1pt, (y1 - y0) / 1pt)
    let head(x, y, ang) = place(dx: x, dy: y, rotate(ang, origin: center + horizon, reflow: false,
      place(dx: -4pt, dy: -2.4pt, polygon(fill: ink, stroke: none, (0pt, 0pt), (4.5pt, 2.4pt), (0pt, 4.8pt)))))
    head(x1, y1, a)
    if both { head(x0, y0, a + 180deg) }
    if label != none { place(dx: (x0 + x1) / 2 - 0.3in, dy: (y0 + y1) / 2 - 10pt, box(width: 0.6in,
      align(center, text(font: f-sans, size: 6pt, label)))) }
  }
  box(width: 6.4in, height: 2.2in, {
    bx(0in, 0.55in, 1.05in, 1.1in, [H89 \ CPU LOGIC \ BOARD \ (Z80)], fill: rgb("#efe9d6"))
    bx(1.6in, 0.15in, 0.9in, 0.45in, [74LS02 \ decoder])
    bx(1.6in, 0.85in, 0.9in, 0.95in, [82C55A \ port A: data \ port C: control])
    bx(3.1in, 1.4in, 0.85in, 0.42in, [74LVC245 \ (control)])
    bx(3.1in, 0.15in, 0.85in, 0.45in, [lamps \ D3--D10])
    bx(4.55in, 0.55in, 1.0in, 1.3in, [ESP32 \ (the FujiNet \ firmware)], fill: rgb("#efe9d6"))
    bx(5.75in, 0.3in, 0.62in, 0.4in, [WiFi])
    bx(5.75in, 1.5in, 0.62in, 0.4in, [microSD])
    arrow(1.05in, 0.4in, 1.6in, 0.4in, label: [port select, \ A0--A2, RD, WR])
    arrow(2.05in, 0.6in, 2.05in, 0.85in)
    arrow(1.05in, 1.15in, 1.6in, 1.15in, label: [D0--D7], both: true)
    arrow(1.05in, 1.6in, 1.6in, 1.6in, label: [RESET])
    arrow(2.5in, 1.06in, 4.55in, 1.06in, label: [PA0--PA7], both: true)
    arrow(2.5in, 0.95in, 3.1in, 0.45in, label: [port B])
    arrow(2.5in, 1.6in, 3.1in, 1.6in, label: [IBF, /OBF])
    arrow(3.95in, 1.6in, 4.55in, 1.6in, label: [IBF, /OBF \ (IO34, IO35)])
    arrow(5.55in, 0.65in, 5.75in, 0.5in, both: true)
    arrow(5.55in, 1.6in, 5.75in, 1.7in, both: true)
    place(dx: 2.5in, dy: 1.9in, box(width: 2.1in, align(center, text(font: f-sans, size: 6pt)[/STB and /ACK go back from the ESP32 to port C])))
  })
}
