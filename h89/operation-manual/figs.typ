// figs.typ -- the line drawings. Measured from Thom's photo of the V1.0
// card (images/photo/board.jpg, at half scale: the board is 543 x 278 there),
// drawn the way Heath drew its pictorials: plain outlines, part numbers in
// Helvetica, leader lines out to the labels.

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
// card(s) -- the board, in half-scale photo pixels times s.
#let card(s: 1pt, labels: true) = {
  let W = 543
  let H = 278
  // room around the board for the labels: 120 to the left, 40 above, 80 below
  box(width: (W + 130) * s, height: (H + 150) * s, place(dx: 120 * s, dy: 40 * s, {
    // the two edge connectors along the bottom
    place(dx: 35 * s, dy: H * s, rect(width: 78 * s, height: 30 * s, fill: white, stroke: lw))
    place(dx: 118 * s, dy: H * s, rect(width: 175 * s, height: 30 * s, fill: white, stroke: lw))
    for i in range(10) { place(dx: (38 + i * 7.6) * s, dy: (H + 18) * s, rect(width: 4 * s, height: 8 * s, stroke: thin)) }
    for i in range(25) { place(dx: (121 + i * 6.85) * s, dy: (H + 18) * s, rect(width: 4 * s, height: 8 * s, stroke: thin)) }
    // the board
    place(rect(width: W * s, height: H * s, stroke: 0.9pt + ink, fill: rgb("#f4f1e8")))
    // prototype area: a field of pads
    place(dx: 258 * s, dy: 4 * s, rect(width: 282 * s, height: 270 * s, stroke: thin,
      fill: tiling(size: (5.4 * s, 5.4 * s), place(dx: 1.6 * s, dy: 1.6 * s, circle(radius: 1.1 * s, stroke: 0.25pt + ink.lighten(30%))))))
    // silkscreen title
    place(dx: 6 * s, dy: 5 * s, text(font: f-sans, size: 8 * s, weight: "bold")[H89 FujiNet \ V1.0 \ 10/31/2025])
    // D1
    place(dx: 97 * s, dy: 8 * s, circle(radius: 6 * s, fill: rgb("#cfe3c5"), stroke: lw))
    // the divider resistors in their socket strip (J2)
    place(dx: 82 * s, dy: 48 * s, rect(width: 28 * s, height: 78 * s, stroke: thin, fill: white))
    for i in range(10) { resistor(85, 50 + i * 7.6, 22, s: s) }
    // R12 and R13-R16
    resistor(10, 62, 20, s: s, vertical: true)
    for i in range(4) { resistor(124, 46 + i * 8.4, 32, s: s) }
    // the microSD breakout
    place(dx: 160 * s, dy: 16 * s, rect(width: 46 * s, height: 52 * s, stroke: lw, fill: rgb("#c9d6e8")))
    place(dx: 168 * s, dy: 16 * s, rect(width: 30 * s, height: 24 * s, stroke: thin, fill: rgb("#b8bcc2")))
    // the chips
    dip(18, 108, 50, 150, 40, [U1 #h(0.4em) 82C55A], s: s)
    dip(82, 138, 28, 76, 20, [U2 74LVC245], s: s)
    dip(74, 238, 48, 22, 14, [U3 74LS02], s: s, vertical: false)
    dip(266, 58, 22, 76, 20, [U4], s: s)
    // C4 and the 47 uF electrolytic, R11
    place(dx: 96 * s, dy: 129 * s, rect(width: 9 * s, height: 5 * s, radius: 2pt, fill: rgb("#e2b84a"), stroke: thin))
    place(dx: -12 * s, dy: 262 * s, circle(radius: 12 * s, fill: rgb("#9aa7bd"), stroke: lw))
    resistor(36, 262, 22, s: s)
    // the ESP32 module
    place(dx: 137 * s, dy: 92 * s, rect(width: 82 * s, height: 162 * s, fill: rgb("#2d2c2b"), stroke: lw, radius: 1pt))
    place(dx: 166 * s, dy: 89 * s, rect(width: 22 * s, height: 13 * s, fill: rgb("#b8bcc2"), stroke: thin))
    place(dx: 143 * s, dy: 98 * s, rect(width: 9 * s, height: 9 * s, fill: rgb("#6f6d6a"), stroke: thin))
    place(dx: 203 * s, dy: 98 * s, rect(width: 9 * s, height: 9 * s, fill: rgb("#6f6d6a"), stroke: thin))
    place(dx: 152 * s, dy: 156 * s, rect(width: 52 * s, height: 60 * s, fill: rgb("#c2c5c9"), stroke: thin))
    place(dx: 152 * s, dy: 216 * s, rect(width: 52 * s, height: 32 * s, fill: rgb("#1e1d1c"), stroke: thin))
    place(dx: 156 * s, dy: 182 * s, text(font: f-sans, size: 5.5pt, fill: ink)[ESP32])
    for i in range(19) {
      place(dx: 139 * s, dy: (112 + i * 7.2) * s, circle(radius: 1.1 * s, fill: rgb("#e6d9a8"), stroke: none))
      place(dx: 214 * s, dy: (112 + i * 7.2) * s, circle(radius: 1.1 * s, fill: rgb("#e6d9a8"), stroke: none))
    }
    // the jumpers, Q1, the power pads
    header(143, 258, 1, 3, s: s, pitch: 5.6)
    header(174, 256, 4, 2, s: s)
    header(210, 256, 3, 2, s: s)
    place(dx: 236 * s, dy: 260 * s, rect(width: 14 * s, height: 11 * s, radius: (top-left: 6 * s, top-right: 6 * s), fill: rgb("#2c2b29"), stroke: thin))
    for i in range(4) { place(dx: 244 * s, dy: (11 + i * 6) * s, rect(width: 6 * s, height: 4.5 * s, fill: rgb("#e6d9a8"), stroke: thin)) }
    if labels {
      callout(103, 8, 103, -18, [D1 (LED)], s: s)
      callout(183, 30, 230, -18, [microSD socket], s: s)
      callout(140, 60, 150, -30, [R13--R16], s: s)
      callout(96, 70, 40, -30, [J2: divider resistors], s: s, anchor: right)
      callout(16, 72, -30, 60, [R12], s: s, anchor: right)
      callout(30, 180, -30, 170, [U1 82C55A \ peripheral interface], s: s, anchor: right)
      callout(96, 190, -30, 220, [U2 74LVC245], s: s, anchor: right)
      callout(98, 249, -30, 250, [U3 74LS02], s: s, anchor: right)
      callout(0, 275, -30, 290, [47 µF], s: s, anchor: right)
      callout(176, 96, 245, 80, [USB connector], s: s)
      callout(178, 186, 245, 150, [ESP32 module], s: s)
      callout(178, 236, 245, 205, [antenna], s: s)
      callout(147, 266, 112, 378, [three-pin jumper], s: s)
      callout(188, 263, 180, 356, [PORT SEL], s: s)
      callout(221, 263, 236, 378, [J3 (INT LVL)], s: s)
      callout(243, 266, 292, 356, [Q1], s: s)
      callout(250, 22, 330, -18, [+5 V and GND pads], s: s)
      callout(277, 110, 330, 120, [U4 (see Parts List)], s: s)
      callout(420, 140, 430, -18, [prototype area], s: s)
      callout(70, 300, 26, 356, [10-pin connector], s: s, anchor: right)
      callout(270, 300, 340, 378, [25-pin connector], s: s)
    }
  }))
}

// ---------------------------------------------------------- the jumpers
#let jumpers() = {
  let p = 16pt
  let pin(x, y) = place(dx: x, dy: y, rect(width: 4pt, height: 4pt, fill: rgb("#c9a13a"), stroke: thin))
  let shunt(x, y) = place(dx: x - 3pt, dy: y - 3pt, rect(width: 10pt, height: p + 10pt, radius: 1.5pt, fill: rgb("#1c1b1a"), stroke: lw))
  box(width: 4.6in, height: 1.2in, {
    // PORT SEL: 2 rows x 4 columns, a shunt across the 320Q column
    place(dx: 0.2in, dy: 0.25in, {
      place(rect(width: 4 * p, height: 2 * p, fill: rgb("#3a3937"), stroke: lw))
      for c in range(4) { for r in range(2) { pin(c * p + p / 2 - 2pt, r * p + p / 2 - 2pt) } }
      shunt(p / 2 - 2pt, p / 2 - 2pt)
      place(dx: 0pt, dy: -14pt, text(font: f-sans, size: 7.5pt, weight: "bold")[PORT SEL])
      for (c, t) in ("320Q", "330Q", "340Q", "170Q").enumerate() {
        place(dx: c * p, dy: 2 * p + 3pt, box(width: p, align(center, text(font: f-sans, size: 5.6pt, t))))
      }
      place(dx: -0.05in, dy: 2 * p + 0.22in, text(font: f-sans, size: 7pt)[jumper on 320Q])
    })
    // J3: 2 rows x 3 columns, no shunts
    place(dx: 1.7in, dy: 0.25in, {
      place(rect(width: 3 * p, height: 2 * p, fill: rgb("#3a3937"), stroke: lw))
      for c in range(3) { for r in range(2) { pin(c * p + p / 2 - 2pt, r * p + p / 2 - 2pt) } }
      place(dx: 0pt, dy: -14pt, text(font: f-sans, size: 7.5pt, weight: "bold")[J3 #h(0.3em) INT LVL])
      for (c, t) in ("/INT3", "/INT4", "/INT5").enumerate() {
        place(dx: c * p - 2pt, dy: 2 * p + 3pt, box(width: p + 4pt, align(center, text(font: f-sans, size: 5.4pt, t))))
      }
      place(dx: -0.05in, dy: 2 * p + 0.22in, text(font: f-sans, size: 7pt)[no jumpers])
    })
    // the three-pin header, as supplied
    place(dx: 3.05in, dy: 0.25in, {
      place(rect(width: p, height: 3 * p, fill: rgb("#3a3937"), stroke: lw))
      for r in range(3) { pin(p / 2 - 2pt, r * p + p / 2 - 2pt) }
      place(dx: -4pt, dy: -14pt, text(font: f-sans, size: 7.5pt, weight: "bold")[three-pin])
      place(dx: -0.2in, dy: 3 * p + 0.12in, text(font: f-sans, size: 7pt)[leave as supplied])
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
    bx(3.1in, 0.85in, 0.85in, 0.42in, [74LVC245])
    bx(3.1in, 1.4in, 0.85in, 0.42in, [dividers \ 5 V to 3.3 V])
    bx(4.55in, 0.55in, 1.0in, 1.3in, [ESP32 \ (the FujiNet \ firmware)], fill: rgb("#efe9d6"))
    bx(5.75in, 0.3in, 0.62in, 0.4in, [WiFi])
    bx(5.75in, 1.5in, 0.62in, 0.4in, [microSD])
    arrow(1.05in, 0.4in, 1.6in, 0.4in, label: [port select, \ A0--A2, RD, WR])
    arrow(2.05in, 0.6in, 2.05in, 0.85in)
    arrow(1.05in, 1.15in, 1.6in, 1.15in, label: [D0--D7], both: true)
    arrow(1.05in, 1.6in, 1.6in, 1.6in, label: [RESET])
    arrow(2.5in, 1.06in, 3.1in, 1.06in, label: [PA0--PA7], both: true)
    arrow(3.95in, 1.06in, 4.55in, 1.06in, label: [IO data], both: true)
    arrow(2.5in, 1.6in, 3.1in, 1.6in, label: [PC0--PC2, \ IBF, /OBF])
    arrow(3.95in, 1.6in, 4.55in, 1.6in, label: [EN, IO0, \ DIR, /OE])
    arrow(5.55in, 0.65in, 5.75in, 0.5in, both: true)
    arrow(5.55in, 1.6in, 5.75in, 1.7in, both: true)
    place(dx: 2.5in, dy: 1.9in, box(width: 2.1in, align(center, text(font: f-sans, size: 6pt)[/STB and /ACK go back from the ESP32 to port C])))
  })
}
