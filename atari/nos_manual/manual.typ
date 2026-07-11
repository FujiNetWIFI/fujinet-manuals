// ============================================================
// FUJINET NOS — AN INTRODUCTION TO THE
// NETWORK OPERATING SYSTEM
//
// Styled after "ATARI 1050 Disk Drive: An Introduction to the
// Disk Operating System" (C061529, 1982) — silver foil pages,
// Futura Extra Bold headbands, tumbling data cubes, and flat
// cel illustrations with black outlines.  Where the 1050
// booklet draws diskettes, this booklet draws the network.
//
// Content is source-verified against fujinet-nhandler nos/src/
// nos.s (v1.0.0) and fujinet-firmware lib/network-protocol.
//
// Build: typst compile --font-path fonts manual.typ
// ============================================================

// ---------- fonts ----------
#let f-head = "Futura"            // weight 700 = Futura Extra Bold
#let f-sans = "Futura"            // weight 400 = Futura LT
#let f-body = "Rockwell Std"      // Light cut (weight 300) for body
#let f-mark = "Harry"             // Harry Fat — the ATARI-logo face
#let f-scrn = "EightBit Atari"    // the genuine Atari ROM charset
#let f-mono = "DejaVu Sans Mono"  // appendix listing only

// ---------- palette ----------
#let ink = rgb("#221f1c")
#let cream = rgb("#f2eee3")        // warm interior stock
#let silver = rgb("#b9bcbe")       // silver foil pages
#let silver-line = rgb("#cdd0d2")  // pinstripe on silver
#let navy = rgb("#1d3060")         // inside-cover blue
#let toc-blue = rgb("#2b4fa3")     // contents entries / cover subtitle
#let scr-bg = rgb("#1c2f96")       // GR.0 dark blue
#let scr-fg = rgb("#dfe4f5")       // GR.0 text luminance
#let cap-fill = rgb("#c9c6bd")     // keycap gray
#let cap-line = rgb("#6b665e")
#let net-dark = rgb("#46403c")     // network-volume body (diskette dark)
#let net-line = rgb("#847a72")     // graticule / sector lines
#let hub-gray = rgb("#b9b5ae")     // diskette hub silver
#let tan = rgb("#d9c7a6")          // computer-case tan
#let tan-dk = rgb("#c4b08c")       // its shaded side
#let kbd-dark = rgb("#3a332e")     // keyboard well

// cube palette, straight off the 1050 booklet
#let cubes-c = (rgb("#d23b2e"), rgb("#e0457f"), rgb("#eda4c0"),
                rgb("#e8871f"), rgb("#edc522"), rgb("#3f9e58"),
                rgb("#7ec98c"), rgb("#3b76c0"), rgb("#27897a"),
                rgb("#7b52a8"))

// ============================================================
// TEXT COMPONENTS
// ============================================================

#let tm = super(text(size: 0.45em, tracking: 0pt)[TM])
#let rg = super(text(size: 0.45em, tracking: 0pt)[®])

// screen-font run from a string (strings are safe for "//" in URLs)
#let sf(s, size: 6.6pt) = {
  set smartquote(enabled: false)
  text(font: f-scrn, size: size, s)
}

// --- chapter heads: stacked Futura Extra Bold caps + black band ---
#let secmark(title) = metadata((title: title))
#let headband(..lines, flush: left, fg: ink, band: black) = {
  let ls = lines.pos()
  block(above: 0pt, below: 1.5em, width: 100%, {
    set par(leading: 0.22em, spacing: 0.22em, first-line-indent: 0pt)
    set text(font: f-head, weight: 700, size: 23pt, fill: fg,
             tracking: 0.4pt)
    set align(flush)
    for l in ls { par(upper(l)) }
    v(8pt)
    align(left, move(dx: -0.6in,
      rect(width: 8.5in, height: 11pt, fill: band)))
  })
}

// --- section heads: Futura LT, like the originals' light subheads ---
#let lsub(t) = block(above: 1.15em, below: 0.5em,
  text(font: f-sans, weight: 400, size: 9.5pt,
       tracking: 0.45pt, fill: ink, upper(t)))

// --- tiny drawn glyphs (avoid font fallback) ---
#let sqdot = box(baseline: -1pt, square(size: 3.6pt, fill: ink))
#let dblarrow = box(baseline: 0.5pt, width: 13pt, height: 5pt, {
  place(dy: 2.1pt, line(start: (2.4pt, 0pt), end: (10.6pt, 0pt),
    stroke: 0.9pt + ink))
  place(polygon(fill: ink, (2.8pt, 0pt), (2.8pt, 4.6pt), (0pt, 2.3pt)))
  place(polygon(fill: ink, (10.2pt, 0pt), (10.2pt, 4.6pt),
    (13pt, 2.3pt)))
})

// --- thin black band for continuation pages ---
#let contband = block(above: 0pt, below: 1.5em, {
  v(55.4pt)
  align(left, move(dx: -0.6in,
    rect(width: 8.5in, height: 11pt, fill: black)))
})

// --- big numbered step ---
#let bstep(n, body) = block(above: 0.85em, below: 0.85em,
  grid(columns: (0.3in, 1fr), column-gutter: 4pt,
    text(font: f-head, weight: 700, size: 16pt, fill: ink,
         baseline: 2pt, str(n)),
    body))

// --- itemized list entry: square bullet ---
#let item(body) = block(above: 0.55em, below: 0.55em,
  grid(columns: (0.16in, 1fr), column-gutter: 3pt,
    move(dy: 1.6pt, square(size: 4.6pt, fill: ink)),
    par(leading: 0.45em, first-line-indent: 0pt, body)))

// --- drawn keycap (the 1050's gray RETURN cap) ---
#let key(label) = box(baseline: 22%,
  rect(fill: cap-fill, stroke: 0.6pt + cap-line, radius: 1.6pt,
       inset: (x: 3.2pt, y: 2.2pt),
       text(font: f-sans, weight: 400, size: 5.8pt,
            fill: ink, tracking: 0.3pt, upper(label))))

// --- COMPUTER: / YOU TYPE: dialogue rows ---
#let dsay(who, what, size: 6.2pt, label-w: 0.68in) = grid(
  columns: (label-w, 1fr), column-gutter: 6pt,
  align: (right + top, left + top),
  text(font: f-body, size: 7.4pt, fill: ink, upper(who) + ":"),
  {
    set smartquote(enabled: false)
    set text(font: f-scrn, size: size, fill: ink)
    set par(leading: 3.6pt, first-line-indent: 0pt)
    what
  })
#let dialogue(..rows) = block(breakable: false, above: 0.9em, below: 0.9em,
  stack(spacing: 4.6pt, ..rows.pos().map(r => dsay(r.at(0), r.at(1)))))

// --- blue CRT panel, drawn in the genuine Atari ROM font ---
#let iv(s) = box(fill: scr-fg, outset: (y: 0.6pt, x: 0.2pt),
  text(fill: scr-bg, s))                       // inverse video
#let screen(body, w: 3.5in) = block(breakable: false,
  above: 1.0em, below: 1.0em,
  box(width: w, fill: scr-bg, radius: 9pt, inset: (x: 14pt, y: 12pt), {
    set smartquote(enabled: false)
    set text(font: f-scrn, size: 5.6pt, fill: scr-fg)
    set par(leading: 3.0pt, spacing: 3.0pt, first-line-indent: 0pt)
    body
  }))

// --- silver page pinstripes ---
#let silver-bg = {
  rect(width: 100%, height: 100%, fill: silver)
  for i in range(52) {
    place(top + left, dy: 0.16in + i * 0.21in,
      line(length: 100%, stroke: 0.5pt + silver-line))
  }
}

// --- folio ---
#let folio = context {
  let p = counter(page).get().first()
  if p > 1 {
    let num = text(font: f-sans, size: 9.5pt, fill: ink, str(p))
    if calc.even(p) {
      place(bottom + left, dx: 10pt, dy: -14pt, num)
    } else {
      place(bottom + right, dx: -10pt, dy: -14pt, num)
    }
  }
}

// ============================================================
// ILLUSTRATION MACHINERY (1050 flat-cel style)
// ============================================================

// --- isometric data cube ---
#let cube(s, c, rot: 0deg) = rotate(rot, reflow: false, {
  let w = s; let h = s * 2.1; let dx = s * 0.62; let dy = s * 0.40
  let st = 0.85pt + black
  box(width: w + dx, height: h + dy, {
    place(polygon(fill: c.lighten(34%), stroke: st,
      (0pt + dx, 0pt), (w + dx, 0pt), (w, dy), (0pt, dy)))
    place(dy: dy, polygon(fill: c, stroke: st,
      (0pt, 0pt), (w, 0pt), (w, h), (0pt, h)))
    place(dx: w, polygon(fill: c.darken(26%), stroke: st,
      (dx, 0pt), (dx, h), (0pt, h + dy), (0pt, dy)))
  })
})

// --- extruded arrow brick (the 1050 stream has these mixed in) ---
#let arrowcube(s, c, rot: 0deg) = rotate(rot, reflow: false, {
  let st = 0.85pt + black
  let d = s * 0.34                       // extrusion offset
  let pts = ((0.0, 0.30), (0.55, 0.30), (0.55, 0.0), (1.0, 0.5),
             (0.55, 1.0), (0.55, 0.70), (0.0, 0.70))
  let face = pts.map(p => (p.at(0) * s * 1.7, p.at(1) * s * 1.15))
  box(width: s * 1.7 + d, height: s * 1.15 + d, {
    place(dx: d, dy: d, polygon(fill: c.darken(30%), stroke: st,
      ..face))
    place(polygon(fill: c, stroke: st, ..face))
  })
})

// a loose arc of tumbling cubes; pts: (x, y, size, color-idx, rot)
// mark a point with "A" appended sizewise?  keep simple: cubes only
#let cubestream(pts, unit: 1pt, arrows: ()) = {
  let w = calc.max(..pts.map(p => p.at(0) + p.at(2) * 2.2)) * unit
  let h = calc.max(..pts.map(p => p.at(1) + p.at(2) * 2.7)) * unit
  box(width: w, height: h, {
    for (i, p) in pts.enumerate() {
      place(dx: p.at(0) * unit, dy: p.at(1) * unit,
        if arrows.contains(i) {
          arrowcube(p.at(2) * unit,
            cubes-c.at(calc.rem(p.at(3), cubes-c.len())),
            rot: p.at(4) * 1deg)
        } else {
          cube(p.at(2) * unit,
            cubes-c.at(calc.rem(p.at(3), cubes-c.len())),
            rot: p.at(4) * 1deg)
        })
    }
  })
}

// ------------------------------------------------------------
// THE NETWORK VOLUME — the diskette of this booklet.
// An orthographic globe drawn exactly the way the 1050 booklet
// draws a diskette: near-black body, lighter sector grid, and
// flat colored slabs (your files) resting on the grid.
// patches: (lat1, lat2, lon1, lon2, color-idx) in degrees,
// lat -90..90 (up positive), lon -90..90 (right positive).
// ------------------------------------------------------------
#let globe(r, patches: (), meridians: (-60, -30, 30, 60),
           parallels: (-60, -30, 0, 30, 60),
           body-c: net-dark, line-c: net-line, depth: 0.09,
           raise-c: none) = {
  let d = r * depth
  let px(lat, lon) = r + r * calc.cos(lat * 1deg) * calc.sin(lon * 1deg)
  let py(lat) = r - r * calc.sin(lat * 1deg)
  box(width: 2 * r + d, height: 2 * r + d, {
    // extruded rim behind (down-right), like the diskette's edge
    place(dx: d, dy: d, circle(radius: r, fill: black,
      stroke: 0.9pt + black))
    // face
    place(circle(radius: r, fill: body-c, stroke: 1.1pt + black))
    // parallels (straight chords in orthographic view)
    for phi in parallels {
      let y = py(phi)
      let half = r * calc.cos(phi * 1deg)
      place(dx: r - half, dy: y,
        line(length: 2 * half, stroke: 0.75pt + line-c))
    }
    // central meridian + elliptical meridians
    place(dx: r, line(angle: 90deg, length: 2 * r,
      stroke: 0.75pt + line-c))
    for lam in meridians {
      let w = calc.abs(2 * r * calc.sin(lam * 1deg))
      place(dx: r - w / 2,
        ellipse(width: w, height: 2 * r, stroke: 0.75pt + line-c,
                fill: none))
    }
    // colored file slabs, extruded like the 1050's file bricks
    for p in patches {
      let (a1, a2, l1, l2, ci) = p
      let c = cubes-c.at(calc.rem(ci, cubes-c.len()))
      let quad = ((px(a1, l1), py(a1)), (px(a1, l2), py(a1)),
                  (px(a2, l2), py(a2)), (px(a2, l1), py(a2)))
      let sd = r * 0.045                 // slab extrusion
      place(dx: sd, dy: sd, polygon(fill: c.darken(32%),
        stroke: 0.85pt + black, ..quad))
      place(polygon(fill: c, stroke: 0.85pt + black, ..quad))
    }
    // optional lifted slab (a file being taken off the volume)
    if raise-c != none {
      let c = raise-c
      let quad = ((px(38, -62), py(38)), (px(38, -22), py(38)),
                  (px(12, -22), py(12)), (px(12, -62), py(12)))
      let sd = r * 0.10
      place(dx: -sd, dy: -sd, {
        place(dx: sd * 0.55, dy: sd * 0.55,
          polygon(fill: c.darken(32%), stroke: 0.85pt + black, ..quad))
        polygon(fill: c.lighten(12%), stroke: 0.85pt + black, ..quad)
      })
    }
  })
}

// ------------------------------------------------------------
// FLAT-CEL ATARI 800XL (3/4 view, after the period press photo:
// silver rear deck w/ ribbed edge, cartridge slot, nameplate,
// charcoal keyboard section, console-key column, space bar)
// ------------------------------------------------------------
#let atari800(w) = {
  let u = w / 100
  let st = 1.0pt + black
  let D = 46                              // machine depth units
  let px(x, d) = (x + d * 0.30) * u       // shear right with depth
  let py(d) = (D - d) * 0.55 * u          // rear high, front low
  let quad(x1, d1, x2, d2, x3, d3, x4, d4, f, s) = place(
    polygon(fill: f, stroke: s,
      (px(x1, d1), py(d1)), (px(x2, d2), py(d2)),
      (px(x3, d3), py(d3)), (px(x4, d4), py(d4))))
  // palette from the photo
  let silver  = rgb("#c6c7c1")            // rear deck
  let silv-dk = rgb("#a9aaa4")            // deck shading / recess
  let char    = rgb("#3b3630")            // keyboard section
  let char-dk = rgb("#28241f")            // front face / well
  let keycap  = rgb("#5a5147")            // key brown
  let console = rgb("#ccd3d5")            // silver function keys

  box(width: 114 * u, height: 34.5 * u, {
    // right side wall (dark at front, silver at rear)
    place(polygon(fill: char-dk, stroke: st,
      (px(100, 0), py(0)), (px(100, 24), py(24)),
      (px(100, 24), py(24) + 5.4 * u), (px(100, 0), py(0) + 6.2 * u)))
    place(polygon(fill: silv-dk, stroke: st,
      (px(100, 24), py(24)), (px(100, 46), py(46)),
      (px(100, 46), py(46) + 4.6 * u), (px(100, 24), py(24) + 5.4 * u)))
    // front face
    place(polygon(fill: char-dk, stroke: st,
      (px(0, 0), py(0)), (px(100, 0), py(0)),
      (px(100, 0), py(0) + 6.2 * u), (px(0, 0), py(0) + 6.2 * u)))
    // ridge line on the front face
    place(line(start: (px(0, 0), py(0) + 2.0 * u),
      end: (px(100, 0), py(0) + 2.0 * u), stroke: 0.7pt + black))
    // top: charcoal keyboard section (front) + silver deck (rear)
    quad(0, 0, 100, 0, 100, 24, 0, 24, char, st)
    quad(0, 24, 100, 24, 100, 46, 0, 46, silver, st)
    // ribs along the rear edge of the deck
    for i in range(17) {
      let x = 3 + i * 5.8
      place(polygon(fill: silv-dk, stroke: 0.55pt + black,
        (px(x, 46), py(46)), (px(x + 3, 46), py(46)),
        (px(x + 3 - 1.1, 42.5), py(42.5)), (px(x - 1.1, 42.5), py(42.5))))
    }
    // cartridge slot (recess + dark slot)
    quad(41, 31, 63, 31, 63, 40, 41, 40, silv-dk, st)
    quad(44, 33.5, 60, 33.5, 60, 37.5, 44, 37.5, rgb("#171512"), st)
    // nameplate: fuji bar + ATARI 800XL
    place(dx: px(7, 30.5), dy: py(31.8),
      rect(width: 0.8 * u, height: 2.8 * u, fill: ink))
    place(dx: px(9.3, 30.5), dy: py(30.7),
      text(font: f-sans, weight: 400, size: 3.0 * u, fill: ink,
        tracking: 0.2 * u)[ATARI 800XL])
    // keyboard well
    quad(3, 2, 76, 2, 76, 23, 3, 23, char-dk, st)
    // four key rows (rear = number row)
    for (ri, d) in (18.6, 14.6, 10.6, 6.6).enumerate() {
      let n = 12
      for k in range(n) {
        let x0 = 5 + ri * 0.9 + k * 5.1
        place(polygon(fill: keycap, stroke: 0.55pt + black,
          (px(x0, d + 3.1), py(d + 3.1)),
          (px(x0 + 4.3, d + 3.1), py(d + 3.1)),
          (px(x0 + 4.3, d), py(d)), (px(x0, d), py(d))))
      }
      // wider key closing each row (BACK S / RETURN / CAPS / SHIFT)
      let xe = 5 + ri * 0.9 + 12 * 5.1
      place(polygon(fill: keycap, stroke: 0.55pt + black,
        (px(xe, d + 3.1), py(d + 3.1)),
        (px(xe + 6.6, d + 3.1), py(d + 3.1)),
        (px(xe + 6.6, d), py(d)), (px(xe, d), py(d))))
    }
    // space bar
    quad(20, 3.0, 58, 3.0, 58, 5.4, 20, 5.4, keycap, 0.55pt + black)
    // console key column (POWER..RESET, front to rear)
    for (i, d) in (2.8, 6.9, 11.0, 15.1, 19.2).enumerate() {
      quad(80, d, 92, d, 92, d + 3.2, 80, d + 3.2, console,
        0.6pt + black)
    }
  })
}

// ------------------------------------------------------------
// LITTLE SERVER CABINET (for fan-out diagrams): an extruded
// box with two "drive" slots and a light, in the cube style.
// ------------------------------------------------------------
#let servbox(s, c: tan) = {
  let st = 0.9pt + black
  let w = s * 1.35; let h = s * 1.8
  let dx = s * 0.42; let dy = s * 0.30
  box(width: w + dx, height: h + dy, {
    place(polygon(fill: c.lighten(22%), stroke: st,
      (dx, 0pt), (w + dx, 0pt), (w, dy), (0pt, dy)))
    place(dx: w, polygon(fill: c.darken(24%), stroke: st,
      (dx, 0pt), (dx, h), (0pt, h + dy), (0pt, dy)))
    place(dy: dy, rect(width: w, height: h, fill: c, stroke: st))
    // dark face panel with two drive slots and a lamp
    place(dx: w * 0.10, dy: dy + h * 0.10,
      rect(width: w * 0.80, height: h * 0.80, fill: kbd-dark,
           stroke: st))
    place(dx: w * 0.18, dy: dy + h * 0.20,
      rect(width: w * 0.64, height: h * 0.09, fill: black,
           stroke: 0.7pt + net-line))
    place(dx: w * 0.18, dy: dy + h * 0.38,
      rect(width: w * 0.64, height: h * 0.09, fill: black,
           stroke: 0.7pt + net-line))
    place(dx: w * 0.18, dy: dy + h * 0.62,
      circle(radius: s * 0.06, fill: cubes-c.at(0), stroke: 0.6pt + black))
    place(dx: w * 0.34, dy: dy + h * 0.60,
      rect(width: w * 0.44, height: h * 0.10, fill: kbd-dark.lighten(14%),
           stroke: 0.7pt + black))
  })
}

// ------------------------------------------------------------
// PIPE — a fat outlined connector line (bezier), 1050-cel style
// ------------------------------------------------------------
#let pipe(from, ctrl1, ctrl2, to, c, w: 3.2pt) = {
  place(curve(stroke: (paint: black, thickness: w + 1.8pt, cap: "round"),
    curve.move(from), curve.cubic(ctrl1, ctrl2, to)))
  place(curve(stroke: (paint: c, thickness: w, cap: "round"),
    curve.move(from), curve.cubic(ctrl1, ctrl2, to)))
}

// ------------------------------------------------------------
// EXTRUDED DISPLAY GLYPH (for the big * and ? and letters)
// ------------------------------------------------------------
#let glyph3d(ch, size, c, depth: 0.06, font: f-head, rot: 0deg) = {
  rotate(rot, reflow: false,
    box({
      let d = size * depth
      place(dx: d, dy: d, text(font: font, weight: 700, size: size,
        fill: c.darken(38%), stroke: 0.8pt + black, ch))
      text(font: font, weight: 700, size: size, fill: c,
        stroke: 0.8pt + black, ch)
    }))
}

// the 1050's six-petal asterisk flower
#let asterisk-flower(r) = box(width: 2.4 * r, height: 2.4 * r, {
  let petals = (rgb("#3f9e58"), rgb("#3b76c0"), rgb("#7b52a8"),
                rgb("#3f9e58"), rgb("#3b76c0"), rgb("#7b52a8"))
  for i in range(6) {
    place(dx: 1.2 * r, dy: 1.2 * r,
      rotate(i * 60deg, origin: top + left, reflow: false,
        place(dx: -r * 0.28, dy: -r * 1.15,
          ellipse(width: r * 0.56, height: r * 1.2,
                  fill: petals.at(i), stroke: 0.9pt + black))))
  }
})

// ============================================================
// DOCUMENT SETUP
// ============================================================
#set text(font: f-body, weight: 300, size: 9.2pt, fill: ink)
#set par(leading: 0.5em, spacing: 0.62em, justify: false,
         first-line-indent: 0pt)
#show emph: set text(weight: 400, style: "normal")
#set page(width: 8.5in, height: 11in,
  margin: (x: 0.6in, top: 0.55in, bottom: 0.7in),
  fill: cream, background: folio)

// ============================================================
// FRONT COVER — after the 1050 booklet cover: silver foil,
// black masthead, blue subtitle, hero art, rainbow wordmark.
// ============================================================
#page(margin: 0pt, fill: none, background: {
  rect(width: 100%, height: 100%, fill: silver)
  for i in range(64) {
    place(top + left, dy: 0.1in + i * 0.17in,
      line(length: 100%, stroke: 0.55pt + silver-line))
  }
})[
  // masthead
  #place(top + left, dx: 0.55in, dy: 0.5in, {
    set par(leading: 0.16em, spacing: 0.16em, first-line-indent: 0pt)
    par(text(font: f-head, weight: 700, size: 40pt, fill: black,
             tracking: 0.4pt)[FUJINET#h(2pt)#text(size: 0.4em, baseline: -1.05em)[TM] NOS])
    v(2pt)
    set text(font: f-sans, weight: 400, size: 19.5pt, fill: toc-blue,
             tracking: 0.6pt)
    par[AN INTRODUCTION TO THE]
    par[NETWORK OPERATING SYSTEM]
  })

  // hero: the FujiNet, with a stream of data cubes pouring out of
  // it and landing on the network volume — disk drive & diskette,
  // reimagined.
  #place(top + left, dx: 1.7in, dy: 2.5in,
    image("images/fujinet-hero.png", width: 4.4in))
  #place(top + left, dx: 0.95in, dy: 5.4in,
    cubestream(unit: 1.35pt, arrows: (2, 9),
      ((118, 4, 7, 0, -18), (132, 22, 8, 7, 30), (108, 30, 8, 3, 10),
       (88, 44, 7, 4, -25), (120, 48, 7, 5, 40), (70, 62, 8, 1, 15),
       (95, 70, 7, 8, -35), (52, 82, 7, 9, 5), (74, 92, 8, 2, 28),
       (40, 104, 8, 6, -12), (58, 116, 7, 0, 45), (30, 128, 7, 3, -30))))
  #place(top + left, dx: 0.7in, dy: 7.55in,
    globe(1.05in,
      patches: ((52, 28, -58, -20, 0), (52, 28, 12, 48, 4),
                (18, -8, -88, -62, 5), (18, -8, -28, 8, 1),
                (18, -8, 40, 78, 8), (-18, -42, -50, -14, 3),
                (-18, -42, 20, 55, 9), (-52, -74, -30, 10, 6))))

  // rainbow wordmark, bottom right, like the cover's ATARI logo
  #place(bottom + right, dx: -0.55in, dy: -0.62in, {
    set align(right)
    box(text(font: f-mark, weight: 900, size: 64pt, tracking: 2pt,
      fill: gradient.linear(dir: ttb,
        rgb("#7b3fa0"), rgb("#3b55b5"), rgb("#2e8eb0"),
        rgb("#36a37e"), rgb("#58b758")).repeat(1),
      top-edge: "bounds", bottom-edge: "bounds")[FUJINET])
    v(-20pt)
    text(font: f-sans, weight: 400, size: 13.5pt, tracking: 6.5pt,
      fill: ink)[NETWORK  OPERATING  SYSTEM]
  })
]

// inside front cover: solid navy, like the booklet
#page(margin: 0pt, fill: navy, background: none)[
  #counter(page).update(0)
]

// ============================================================
// CONTENTS
// ============================================================
#{
  set par(first-line-indent: 0pt)
  block(above: 0pt, {
    set text(font: f-head, weight: 700, size: 26pt, fill: ink)
    [CONTENTS]
    v(8pt)
    move(dx: -0.6in, rect(width: 8.5in, height: 11pt, fill: black))
  })
  v(0.22in)
  align(center, box(width: 5.4in, {
    set align(left)
    context {
      let entries = query(metadata).filter(m =>
        type(m.value) == dictionary and "title" in m.value)
      for e in entries {
        let pg = counter(page).at(e.location()).first()
        block(above: 0pt, below: 5.0pt, {
          line(length: 100%, stroke: 0.9pt + ink)
          v(2.4pt)
          text(font: f-head, weight: 700, size: 10.8pt, fill: toc-blue,
               tracking: 0.3pt, upper(e.value.title))
          h(8pt)
          text(font: f-sans, size: 9.5pt, fill: ink, str(pg))
        })
      }
    }
  }))

  place(bottom + left, dy: -0.05in, box(width: 6.4in, {
    set text(size: 7.4pt)
    set par(leading: 0.46em)
    [FujiNet#tm is free, open-source hardware and software, built by
     enthusiasts for enthusiasts. This booklet covers NOS, the FujiNet
     Network Operating System for the Atari 8-bit computers, version
     1.0, by Thomas Cherryhomes and Michael Sternberg. Its design
     pays tribute to the Atari peripheral manuals of 1980--1982.
     ATARI#rg and the names of ATARI peripherals are trademarks of
     their respective owners, used here in loving tribute. FujiNet is
     not affiliated with Atari.]
  }))
  pagebreak()
}

// --- labeled slab (a brick with a name on its face) ---
#let slab(label, c, w: 52pt, h: 16pt) = {
  let st = 0.9pt + black
  let dx = 7pt; let dy = 5pt
  box(width: w + dx, height: h + dy, {
    place(polygon(fill: c.lighten(34%), stroke: st,
      (dx, 0pt), (w + dx, 0pt), (w, dy), (0pt, dy)))
    place(dx: w, polygon(fill: c.darken(28%), stroke: st,
      (dx, 0pt), (dx, h), (0pt, h + dy), (0pt, dy)))
    place(dy: dy, rect(width: w, height: h, fill: c, stroke: st))
    place(dy: dy, box(width: w, height: h, align(center + horizon,
      text(font: f-scrn, size: 6.4pt, fill: white,
           stroke: none, label))))
  })
}

// --- flat-cel diskette, straight off the booklet ---
#let diskette(w, files: ((1, 1, 0), (3, 0, 7), (2, 3, 5))) = {
  let u = w / 100
  let st = 1.1pt + black
  box(width: w + 6 * u, height: w + 6 * u, {
    // jacket with extruded edge
    place(dx: 6 * u, dy: 6 * u,
      rect(width: w, height: w, fill: black, stroke: st))
    place(rect(width: w, height: w, fill: net-dark, stroke: st))
    // sector grid: 4 columns, 8 rows
    for i in range(1, 4) {
      place(dx: i * 25 * u, line(angle: 90deg, length: w,
        stroke: 0.75pt + net-line))
    }
    for j in range(1, 8) {
      place(dy: j * 12.5 * u, line(length: w, stroke: 0.75pt + net-line))
    }
    // hub ring
    place(dx: 36 * u, dy: 36 * u,
      circle(radius: 14 * u, fill: hub-gray, stroke: st))
    place(dx: 42 * u, dy: 42 * u,
      circle(radius: 8 * u, fill: cream, stroke: st))
    // colored file blocks: (col, row, color-idx)
    for f in files {
      place(dx: f.at(0) * 25 * u + 1.4 * u, dy: f.at(1) * 12.5 * u + 1.2 * u,
        rect(width: 22 * u, height: 10 * u,
          fill: cubes-c.at(calc.rem(f.at(2), cubes-c.len())),
          stroke: 0.9pt + black))
    }
  })
}

// --- drawn 3D key, for the AUTORUN appkey ---
#let key3d(w, c: rgb("#edc522")) = {
  let u = w / 100
  let st = 1.1pt + black
  let face = {
    // bow (ring) + blade with two teeth
    place(circle(radius: 16 * u, fill: c, stroke: st))
    place(dx: 8 * u, dy: 8 * u, circle(radius: 7 * u, fill: net-dark,
      stroke: st))
    place(dx: 28 * u, dy: 11 * u, rect(width: 66 * u, height: 10 * u,
      fill: c, stroke: st))
    place(dx: 74 * u, dy: 21 * u, rect(width: 8 * u, height: 10 * u,
      fill: c, stroke: st))
    place(dx: 88 * u, dy: 21 * u, rect(width: 7 * u, height: 14 * u,
      fill: c, stroke: st))
  }
  box(width: 100 * u, height: 40 * u, {
    place(dx: 3.4 * u, dy: 3.4 * u, {
      // extrusion shadow pass
      place(circle(radius: 16 * u, fill: c.darken(38%), stroke: st))
      place(dx: 28 * u, dy: 11 * u, rect(width: 66 * u, height: 10 * u,
        fill: c.darken(38%), stroke: st))
      place(dx: 74 * u, dy: 21 * u, rect(width: 8 * u, height: 10 * u,
        fill: c.darken(38%), stroke: st))
      place(dx: 88 * u, dy: 21 * u, rect(width: 7 * u, height: 14 * u,
        fill: c.darken(38%), stroke: st))
    })
    place(face)
  })
}

// ============================================================
// INTRODUCING NOS  (silver, after "INTRODUCING DOS")
// ============================================================
#page(fill: none, background: { silver-bg; folio })[
  #secmark("Introducing NOS")
  #headband("Introducing", "NOS")

  #grid(columns: (1fr, 1fr, 1fr), column-gutter: 14pt, [
    #lsub[Why You Need NOS]

    The Network Operating System (NOS) is a program that allows your
    ATARI computer to work with your FujiNet#tm and enables you to
    store and retrieve information on #emph[servers] --- other
    computers on your network and across the Internet. The
    information you save is still called a "file," and NOS
    (pronounced "noss") still lets you give a name to each file so
    you can call it up whenever you want it.

    If you have used ATARI DOS with a disk drive, you already know
    most of what NOS does. NOS lists your files, deletes them,
    renames them, copies them, and loads and saves programs. The
    difference is where the files live. DOS keeps them on a diskette
    spinning a few inches away. NOS keeps them anywhere at all --- on
    the computer in your den, or on a hobbyist server on the other
    side of the world.
  ], [
    #lsub[What You'll Learn From This Booklet]

    This is an introduction to NOS. After you read this booklet and
    follow the examples, you'll know your way around the NOS menu
    and the command line behind it: you'll connect a network drive
    to a server, look at its directory, and copy, delete, rename,
    load, save, and run the files you find there. You'll also learn
    how to make NOS set up all your favorite connections
    automatically, every time you turn the computer on.

    A complete reference for every NOS command begins on the
    reference pages near the back of this booklet; a tour of NOS's
    insides --- its memory map and its overlay machinery --- sits
    just ahead of the full source listing, printed in the back for
    advanced users. NOS also carries its own online HELP library,
    described in the section "Getting Help."

    One thing you #emph[won't] find here is anything about floppy
    diskettes. NOS doesn't use them. There is nothing to format,
    nothing to insert, and nothing to fill up.
  ], [
    #lsub[Got Everything?]

    Before you begin, check that you have:

    #bstep(1)[An ATARI home computer, set up and working.]
    #bstep(2)[A FujiNet, connected to your wireless network. (The
      FujiNet owner's guide covers this.)]
    #bstep(3)[The NOS disk image, #sf("NOS.ATR", size: 6.2pt). It is
      always available at #sf("apps.irata.online", size: 6.2pt) in
      the #sf("Atari_8-bit/DOS/", size: 6.2pt) folder.]

    NOS is young software, still growing. It is best suited to
    workflows where your ATARI and a modern computer work together
    --- and it is developed in the open. The source code lives in
    the #sf("fujinet-nhandler", size: 6.2pt) repository on GitHub,
    under #sf("nos/", size: 6.2pt).
  ])

  #place(bottom + right, dx: 0.5in, dy: 0.55in,
    rotate(-18deg, image("images/fujinet-rear34.png", width: 2.1in)))
]

// ============================================================
// BEGINNING WITH NOS  (silver)
// ============================================================
#page(fill: none, background: { silver-bg; folio })[
  #secmark("Beginning with NOS")
  #headband("Beginning", "with NOS", flush: right)

  #grid(columns: (1fr, 1fr), column-gutter: 16pt, [
    #lsub[How Programs Are Stored On the Network]

    Programs are stored in an area of the computer called #emph[the
    memory,] and the memory forgets everything when you turn the
    power off. A disk drive fixes that by recording your work on a
    diskette. Your FujiNet fixes it by sending your work through
    the air to a server --- any computer, anywhere, that agrees to
    hold files for you.

    When you save a file under NOS, a stream of information flows
    out of the computer's memory, through the FujiNet, across your
    wireless network, and comes to rest on the server you chose.
    Loading is the reverse: the server streams the file back, and
    it settles into the computer's memory. If there was a program
    in memory already, the new one is written over it.

    The server holding your files is called a #emph[mount,] and the
    connection NOS makes to it is called a #emph[network drive.]
    You have eight of them, named #sf("N1:") through #sf("N8:") ---
    more about them in a few pages.
  ], [
    #lsub[Loading NOS]

    NOS boots from a disk image, the same way DOS boots from a
    diskette --- your FujiNet simply pretends to be the drive.

    #bstep(1)[Boot your FujiNet CONFIG program, and navigate to the
      host #sf("apps.irata.online", size: 6.2pt).]
    #bstep(2)[Find #sf("NOS.ATR", size: 6.2pt) in the folder
      #sf("Atari_8-bit/DOS/", size: 6.2pt) and mount it in disk
      slot 1, read-only is fine.]
    #bstep(3)[Boot the disk. In a moment you'll see the NOS
      menu --- sixteen choices, waiting on one keystroke.]
  ])

  #v(4pt)
  #grid(columns: (3.2in, 1fr), column-gutter: 18pt,
    screen(w: 3.2in)[
      #sf("FUJINET NETWORK OPERATING SYSTEM 1.0", size: 5.0pt)\
      #sf("COPYLEFT 2026 FUJINET", size: 5.0pt)\
      #v(3pt)
      #sf(" A. DIRECTORY         I. CHANGE DIR", size: 5.0pt)\
      #sf(" B. RUN CARTRIDGE     J. SHOW DIR", size: 5.0pt)\
      #sf(" C. COPY FILE         K. BINARY SAVE", size: 5.0pt)\
      #sf(" D. DELETE FILE(S)    L. BINARY LOAD", size: 5.0pt)\
      #sf(" E. RENAME FILE       M. RUN AT ADDR", size: 5.0pt)\
      #sf(" F. MAKE DIRECTORY    N. CHANGE DRIVE", size: 5.0pt)\
      #sf(" G. REMOVE DIRECTORY  O. TYPE FILE", size: 5.0pt)\
      #sf(" H. BASIC ON/OFF      P. COMMAND LINE", size: 5.0pt)\
      #v(3pt)
      #sf("SELECT ITEM OR ", size: 5.0pt)#iv(sf("RETURN", size: 5.0pt))#sf(" FOR MENU", size: 5.0pt)\
      #iv(sf(" ", size: 5.0pt))
    ], [
    #lsub[The Menu]

    What greets you is the NOS menu, drawn from the school of DOS
    2.0: sixteen choices, one letter each. Press a letter, answer
    the question it asks, and NOS does the rest --- nothing to
    remember, nothing to spell. The next section walks through
    every letter.

    The last item is a door. #strong[P. COMMAND LINE] opens the NOS
    prompt, where every menu item is a command you can type with
    more say in the matter --- and where a dozen commands live that
    never made the menu. This booklet teaches both, letter and
    command together; type #sf("MENU") at the prompt whenever you
    want the menu back.
  ])

  #v(4pt)
  #lsub[Leave the NOS Disk In the Drive]

  Like DOS, NOS keeps only part of itself in memory. The everyday
  machinery stays resident; the less-used commands --- and the menu
  itself --- wait out on the NOS disk image, loaded in the moment
  you call them. So leave #sf("NOS.ATR", size: 6.2pt) mounted in
  disk slot 1 while you work. Where DOS swapped a whole menu
  program over your work (and invented MEM.SAV to apologize for
  it), the NOS menu is ten small sectors borrowing one small patch
  of free memory --- and the command line borrows nothing at all.
  The chapter "Inside NOS," near the back, maps every byte.

  #place(bottom + left, dx: -0.1in, dy: 0.42in,
    cubestream(unit: 1.15pt, arrows: (3, 8),
      ((4, 74, 8, 0, -20), (26, 60, 8, 7, 25), (48, 48, 8, 3, -5),
       (72, 40, 8, 4, 40), (98, 30, 8, 5, 12), (126, 24, 8, 1, -30),
       (155, 20, 8, 8, 8), (185, 22, 8, 9, -18), (214, 28, 8, 2, 30),
       (242, 38, 8, 6, -8), (268, 50, 8, 0, 22), (292, 64, 8, 3, -25))))
]

// ============================================================
// THE MENU  (cream) — the DOS 2.0 menu, reborn for 1.0
// ============================================================
#secmark("The Menu")
#headband("The", "Menu", flush: right)

#grid(columns: (1fr, 1fr), column-gutter: 20pt, [
  Sixteen letters, and every one of them is a NOS command wearing
  a nametag. Choose a letter and the menu asks one plain question
  --- some of them word for word the questions DOS 2.0 asked.
  Answer it, and the menu quietly assembles the real command, runs
  it, and waits beneath the result:

  #dialogue(
    ("computer", sf("SELECT ITEM OR ") + iv(sf("RETURN")) + sf(" FOR MENU")),
    ("you type", sf("A") + h(3pt) + key("return")),
    ("computer", sf("DIRECTORY-SEARCH SPEC?")),
    ("you type", sf("*.XEX") + h(3pt) + key("return")),
    ("computer", sf("GAME.XEX         25K", size: 5.8pt)),
    ("", sf("DEMO.XEX         12K", size: 5.8pt)))

  Answer a question with a bare #key("return") and the item runs
  plain --- item A with no search spec lists everything. When the
  result ends, the SELECT ITEM prompt returns beneath it, your
  listing still on the screen; press #key("return") alone and the
  whole menu redraws.

  #lsub[What Each Letter Asks]

  #{
    set text(size: 7.2pt)
    table(columns: (1.32in, 1.42in, 1fr), stroke: 0.6pt + ink,
      inset: (x: 4.5pt, y: 3.1pt),
      table.header(
        text(font: f-sans, size: 6.8pt, tracking: 0.4pt)[ITEM],
        text(font: f-sans, size: 6.8pt, tracking: 0.4pt)[IT ASKS],
        text(font: f-sans, size: 6.8pt, tracking: 0.4pt)[RUNS]),
      [A. Directory], sf("DIRECTORY-SEARCH SPEC?", size: 4.6pt), [#strong[DIR]],
      [B. Run Cartridge], [--- runs at once ---], [#strong[CAR]],
      [C. Copy File], sf("COPY-FROM,TO?", size: 4.6pt), [#strong[NCOPY]],
      [D. Delete File(s)], sf("DELETE FILE SPEC?", size: 4.6pt), [#strong[DEL]],
      [E. Rename File], sf("RENAME-OLD,NEW?", size: 4.6pt), [#strong[RENAME]],
      [F. Make Directory], sf("MAKE DIRECTORY?", size: 4.6pt), [#strong[MKDIR]],
      [G. Remove Directory], sf("REMOVE DIRECTORY?", size: 4.6pt), [#strong[RMDIR]],
      [H. BASIC On/Off], sf("BASIC ON OR OFF?", size: 4.6pt), [#strong[BASIC]],
      [I. Change Dir], sf("CHANGE TO DIRECTORY?", size: 4.6pt), [#strong[NCD]],
      [J. Show Dir], [--- runs at once ---], [#strong[NPWD]],
      [K. Binary Save], sf("SAVE-NAME,START,END?", size: 4.6pt), [#strong[SAVE]],
      [L. Binary Load], sf("BINARY LOAD FILE?", size: 4.6pt), [#strong[LOAD]],
      [M. Run At Addr], sf("RUN AT ADDRESS (HEX)?", size: 4.6pt), [#strong[RUN]],
      [N. Change Drive], sf("CHANGE TO DRIVE (1-8)?", size: 4.6pt), [#strong[Nn:]],
      [O. Type File], sf("TYPE FILE?", size: 4.6pt), [#strong[TYPE]],
      [P. Command Line], [--- opens the prompt ---], [])
  }
], [
  #lsub[The DOS Menu, Reborn]

  If you grew up on ATARI DOS, look closely: the letters you wore
  into muscle memory still do what they always did. A lists the
  directory, C copies a file, D deletes, E renames, K and L save
  and load binaries, M runs at an address, B runs the cartridge.

  #screen(w: 2.95in)[
    #sf("DISK OPERATING SYSTEM II VERSION 2.0S", size: 4.6pt)\
    #sf("COPYRIGHT 1980 ATARI", size: 4.6pt)\
    #sf("A. DISK DIRECTORY   I. FORMAT DISK", size: 4.6pt)\
    #sf("B. RUN CARTRIDGE    J. DUPLICATE DISK", size: 4.6pt)\
    #sf("C. COPY FILE        K. BINARY SAVE", size: 4.6pt)\
    #sf("D. DELETE FILE(S)   L. BINARY LOAD", size: 4.6pt)\
    #sf("E. RENAME FILE      M. RUN AT ADDRESS", size: 4.6pt)\
    #sf("F. LOCK FILE        N. CREATE MEM.SAV", size: 4.6pt)\
    #sf("G. UNLOCK FILE      O. DUPLICATE FILE", size: 4.6pt)\
    #sf("H. WRITE DOS FILES", size: 4.6pt)\
    #sf("SELECT ITEM OR RETURN FOR MENU", size: 4.6pt)
  ]

  Only the chores that came with diskettes gave up their letters.
  FORMAT DISK and DUPLICATE DISK are gone --- nothing to format,
  nothing to copy sector by sector --- and LOCK, UNLOCK, WRITE
  DOS FILES, and CREATE MEM.SAV went with them. Their letters were
  handed to network work: directories to make and remove, a drive
  to change, a file viewer, and the door to the command line.

  And one old letter grew truer. #strong[D. DELETE FILE(S)]
  finally earns its plural: give it a wild card like
  #sf("*.BAK") and it works through the whole crowd, asking about
  each file by name. (The chapter "Wild Cards" tells that story.)

  #lsub[Where the Menu Lives]

  The menu is not part of resident NOS. Each time it draws, NOS
  reads it fresh from the disk image --- ten small sectors ---
  into a patch of free memory at \$2600, and your chosen command
  runs from #emph[resident] code, so even a command that
  overwrites the menu can't get lost on the way home. The price
  is honest and small: a program tall enough to reach \$2600 ---
  about 2.8K past NOS's floor --- gets a corner stepped on when
  the menu draws. The command line loads nothing up there at all,
  which is one more reason #strong[P] is the power user's first
  keystroke. "Inside NOS," near the back, has the whole map.
])

#pagebreak()

// ============================================================
// NETWORK, NOT DISK  (cream — the big idea)
// ============================================================
#secmark("Network, Not Disk")
#headband("Network,", "Not Disk")

#grid(columns: (1fr, 1fr, 1fr), column-gutter: 14pt, [
  #lsub[A Diskette That Can Be Anywhere]

  Every disk operating system before this one was built around a
  piece of spinning plastic. NOS is built around a connection. Where
  DOS thinks "drive 1, sector 42," NOS thinks "that folder on that
  server." Once a network drive is connected --- #emph[mounted,] as
  NOS says --- everything you know from DOS carries over: the
  directory, the filenames, copying, deleting, renaming, loading,
  saving.

  A mounted server behaves like a diskette with a few upgrades. It
  can be as big as the server's owner allows. Several people can
  reach it at once. And it never goes soft in a hot car.
], [
  #lsub[Where Did D: Go?]

  ATARI software talks to diskettes through a device named
  #sf("D:"). NOS contains no disk software at all --- no File
  Management System, no sectors, no formatting --- but it still
  answers calls to #sf("D:"). When a program asks #sf("D:") for a
  file, NOS quietly hands the request to the network device,
  #sf("N:"). The program never knows the difference.

  This is how a BASIC program written in 1982 can
  #sf("SAVE \"D:MYFILE\"") and have MYFILE come to rest on a server
  in another hemisphere. The program thinks it's talking to a
  1050. It's talking to the world.
], [
  #lsub[What That Means Day To Day]

  #item[Drive numbers name #emph[connections,] not hardware.
    #sf("N1:") through #sf("N8:") can each point somewhere
    different.]
  #item[There are no BASIC pokes, no handlers to load, no
    cartridges. NOS installs its #sf("N:") handler at boot, and
    maps #sf("D:") to it.]
  #item[Physical and emulated diskettes are #emph[not] reachable
    from NOS. If you need real disk images, boot a disk-based DOS
    instead --- see "What NOS Doesn't Do."]

  The next few pages teach the one genuinely new skill NOS asks of
  you: connecting a network drive to a server.
])

#v(0.35in)
// diskette --> globe: the whole booklet in one picture
#align(center, box({
  let g = 1.02in
  stack(dir: ltr, spacing: 0.55in,
    align(horizon, diskette(1.7in,
      files: ((1, 1, 0), (3, 0, 7), (0, 4, 5), (2, 6, 3)))),
    align(horizon, arrowcube(30pt, cubes-c.at(0))),
    align(horizon, globe(g,
      patches: ((52, 28, -58, -20, 0), (52, 28, 12, 48, 7),
                (18, -8, -88, -62, 5), (18, -8, -28, 8, 3),
                (18, -8, 40, 78, 8), (-18, -42, -50, -14, 1),
                (-18, -42, 20, 55, 9), (-52, -74, -30, 10, 6)))))
}))
#align(center, box(width: 4.6in,
  text(size: 7.6pt)[The diskette you know, and the diskette you're
    getting: a mounted server holds files the same way, listed the
    same way, named the same way --- it just isn't in the room.]))

#pagebreak()

// ============================================================
// CONNECTING TO A SERVER  (cream)
// ============================================================
#secmark("Connecting to a Server")
#headband("Connecting", "to a Server", flush: right)

#grid(columns: (1fr, 1fr), column-gutter: 20pt, [
  Before a network drive can do anything, it must be connected to a
  server. The command that does it is #strong[NCD] --- #emph[network
  change directory] --- item #strong[I. CHANGE DIR] on the menu,
  and if the two-letter version suits you better at the prompt,
  #strong[CD] does the same thing.

  You hand NCD a #emph[URL:] the name of a protocol, the name of a
  host, and a path. (Protocols get their own section, a few pages
  on. For now, TNFS is the protocol FujiNet folks use most.)

  #dialogue(
    ("you type", sf("NCD N1:TNFS://192.168.1.20/") + h(3pt) + key("return")),
    ("computer", sf("N1:")))

  No news is good news: the prompt returns, and drive 1 is mounted.
  If NOS can't reach the server, you'll get an error number instead.
  To see where a drive points, ask #strong[NPWD] (or #strong[PWD]
  --- item #strong[J] on the menu):

  #dialogue(
    ("you type", sf("NPWD") + h(3pt) + key("return")),
    ("computer", sf("N1:TNFS://192.168.1.20/")))

  #lsub[Moving Around]

  Once a drive is mounted, NCD moves through the server's folders
  the way you'd move through directories on any big computer.
  Relative paths work, and so does #sf("..") for the parent
  directory:

  #dialogue(
    ("you type", sf("NCD GAMES/ACTION") + h(3pt) + key("return")),
    ("you type", sf("NPWD") + h(3pt) + key("return")),
    ("computer", sf("N1:TNFS://192.168.1.20/GAMES/ACTION/", size: 5.6pt)),
    ("you type", sf("NCD ../PUZZLE") + h(3pt) + key("return")),
    ("you type", sf("NPWD") + h(3pt) + key("return")),
    ("computer", sf("N1:TNFS://192.168.1.20/GAMES/PUZZLE/", size: 5.6pt)))

  A trailing #sf("/") is added for you if you leave it off.
], [
  #lsub[Names With Spaces]

  If a path has spaces in it, wrap the whole thing --- device, URL,
  and all --- in double quotes:

  #dialogue(
    ("you type", sf("NCD \"N2:FTP://ftp.pigwa.net/stuff/holmes cd/\"", size: 5.4pt)))

  #lsub[Letting Go]

  To disconnect a drive, give NCD a bare drive name and nothing
  else:

  #dialogue(
    ("you type", sf("NCD N2:") + h(3pt) + key("return")))

  #lsub[Which Drive Gets Mounted?]

  If the URL starts with a drive name like #sf("N2:"), that drive is
  mounted. If it starts with the bare protocol, the #emph[current]
  drive --- the one in your prompt --- is mounted. Both of these
  connect drive 2:

  #dialogue(
    ("you type", sf("NCD N2:TNFS://192.168.1.20/")),
    ("you type", sf("N2:") + h(8pt) + sf("then") + h(8pt) + sf("NCD TNFS://192.168.1.20/", size: 5.6pt)))

  One caution before you wander: NCD does #emph[not] check that a
  new path really exists on the server. If you mistype a folder
  name, the mistake shows up later, when DIR or LOAD comes back
  empty-handed. When in doubt, DIR right after you arrive.
])

#v(0.3in)
// Atari -> pipe -> server: the mount, drawn
#align(center, box(width: 6.9in, height: 2.0in, {
  place(dx: 0in, dy: 0.55in, atari800(2.5in))
  pipe((2.62in, 1.0in), (3.7in, 0.6in), (4.4in, 1.5in),
    (5.3in, 1.12in), cubes-c.at(7), w: 4.4pt)
  place(dx: 5.28in, dy: 0.42in, servbox(0.85in))
  place(dx: 2.75in, dy: 1.62in,
    text(font: f-scrn, size: 7.5pt, fill: ink,
      "N1:TNFS://192.168.1.20/"))
}))
#align(center, box(width: 5in,
  text(size: 7.6pt)[A mount is a conversation: your computer on one
    end, a server on the other, and the FujiNet translating in
    between.]))

#pagebreak()
// ============================================================
// THE EIGHT NETWORK DRIVES  (cream)
// ============================================================
#secmark("The Eight Network Drives")
#headband("The Eight", "Network Drives")

#grid(columns: (1fr, 1fr, 1fr), column-gutter: 14pt, [
  Your FujiNet carries #emph[eight] network devices, #sf("N1:")
  through #sf("N8:"), and every one of them can be mounted somewhere
  different at the same time. One drive on your workroom TNFS
  server, one on an FTP archive in Poland, one on the FujiNet's own
  SD card, one reading a page from the web --- all at once, all
  switchable with two keystrokes.

  To make another drive the current one, press #strong[N] at the
  menu and answer with a digit --- or, at the prompt, type the
  drive's name, alone:

  #dialogue(
    ("you type", sf("N3:") + h(3pt) + key("return")),
    ("computer", sf("N3:")))

  The prompt follows you. Commands typed without a drive name ---
  #sf("DIR"), #sf("NCD PATH"), #sf("LOAD GAME.XEX") --- now mean
  drive 3. Switching is allowed even if the drive has no mount yet;
  NOS doesn't check until you try to use it.
], [
  #lsub[The Mounts Live In the FujiNet]

  Here is the single most important idea in this booklet. The mount
  table --- which drive points where --- is kept #emph[inside the
  FujiNet,] not inside your computer. NOS is only one voice giving
  it instructions.

  That has a happy consequence: mounts survive. Load a program,
  quit back to NOS, and your drives are still connected right where
  you left them.

  And it has a consequence to respect: the drives are
  #emph[shared.] A BASIC program that opens #sf("N1:") sees exactly
  the same #sf("N1:") the NOS prompt sees. If you --- or a batch
  file, or the program itself --- #sf("NCD") drive 1 somewhere
  else, it moves for #emph[everyone,] including any program that
  was counting on it.
], [
  #lsub[Advice For Programmers]

  #item[Pick your drives deliberately. If your program keeps its
    data on #sf("N1:"), do your NOS housekeeping on another
    drive.]
  #item[Be careful with #sf("NCD") (or #sf("CD")) inside programs
    and batch files --- you are moving a shared drive, not a
    private one.]
  #item[Leave #sf("N4:") to NOS when you can. NOS itself borrows
    drive 4 as its service line: HELP fetches its articles over
    it, and NCOPY builds its network destinations there. A mount
    you park on #sf("N4:") can confuse both.]
  #item[Keep everyday file traffic on drives 1 through 4. All
    eight drives answer the drive commands (NCD, NPWD, DIR, DEL,
    RENAME, MKDIR, RMDIR, NTRANS, LOAD), but the resident
    #sf("N:") handler provides stream buffers for units 1--4, and
    that is where TYPE, NCOPY, SAVE, SUBMIT, and your own OPEN
    statements should live.]
])

#v(0.25in)
// the fan-out: one FujiNet, eight mounts
#align(center, box(width: 7.0in, height: 3.35in, {
  let fuji = (0.32in, 1.35in)
  // eight pipes to eight little servers
  let dests = ((2.15in, 0.22in), (3.45in, 0.14in), (4.75in, 0.18in),
               (6.05in, 0.30in), (2.15in, 2.28in), (3.45in, 2.40in),
               (4.75in, 2.36in), (6.05in, 2.22in))
  let cix = (7, 0, 5, 3, 9, 4, 8, 1)
  for (i, d) in dests.enumerate() {
    let mid1 = (fuji.at(0) + 0.95in, fuji.at(1) + 0.25in)
    let mid2 = (d.at(0) - 0.5in, d.at(1) + 0.35in)
    pipe((fuji.at(0) + 0.62in, fuji.at(1) + 0.42in), mid1, mid2,
      (d.at(0) + 0.18in, d.at(1) + 0.38in), cubes-c.at(cix.at(i)),
      w: 3.4pt)
  }
  for (i, d) in dests.enumerate() {
    place(dx: d.at(0), dy: d.at(1), servbox(0.42in))
    place(dx: d.at(0) + 0.14in,
      dy: d.at(1) + if i < 4 { -0.2in } else { 0.98in },
      text(font: f-scrn, size: 8pt, fill: ink,
        "N" + str(i + 1) + ":"))
  }
  place(dx: 0.02in, dy: 0.97in,
    image("images/fujinet-top.png", width: 1.15in))
}))
#align(center, box(width: 5.4in,
  text(size: 7.6pt)[Eight drives, eight destinations. The FujiNet
    holds all eight conversations at once --- and everything running
    on your ATARI shares them.]))

#pagebreak()

// ============================================================
// THE PROTOCOLS  (cream spread)
// ============================================================
#secmark("The Protocols")
#headband("The", "Protocols", flush: right)

#grid(columns: (1fr, 1fr), column-gutter: 20pt, [
  A #emph[protocol] is the language a server speaks. You choose one
  in the first word of every URL, before the #sf("://") --- and
  that's the only place you ever deal with it. Once a drive is
  mounted, every protocol looks like the same thing: files.

  The FujiNet firmware speaks all of the protocols on this page.
  They differ in what they allow. Some let you do everything DOS
  ever did --- list, read, write, delete, rename, make and remove
  directories. Others are read-mostly, and a couple are special
  guests. The table below is the map.

  #lsub[TNFS --- the home team]

  TNFS was invented for machines like yours. Servers are free and
  tiny --- run #sf("tnfsd") on any PC, Mac, or Linux box --- and
  most public FujiNet software libraries speak it, including
  #sf("apps.irata.online") and #sf("tnfs.fujinet.online").
  Everything works: reading, writing, the whole DOS toolbox.

  #dialogue(
    ("you type", sf("NCD N1:TNFS://192.168.1.20/")))

  If a URL gives no protocol port, the standard one is used
  (16384 for TNFS), which is nearly always right.
], [
  #lsub[SD --- the server in your hand]

  The protocol named #sf("SD") is a server that never leaves home:
  the microSD card plugged into your FujiNet. No host name needed
  --- and no network, either. Everything works, just like TNFS.

  #dialogue(
    ("you type", sf("NCD N1:SD://fujinet/")))

  #lsub[FTP --- the deep archives]

  Decades of ATARI software sit on FTP sites. NOS signs you in as
  an #emph[anonymous] guest --- fine for public archives, which are
  usually read-only to guests. Directory listings, downloads, and
  (where the server permits) uploads all work.

  #dialogue(
    ("you type", sf("NCD N2:FTP://ftp.pigwa.net/atari/", size: 5.8pt)))

  #lsub[HTTP and HTTPS --- the web itself]

  Any web URL can be opened and read --- TYPE a page straight off
  the Internet. The full DOS toolbox (directories, writing,
  renaming, deleting) works when the far end is a #emph[WebDAV]
  server; an ordinary web server is read-only.

  #dialogue(
    ("you type", sf("TYPE N3:HTTPS://fujinet.online/", size: 5.8pt)))
])

#v(0.2in)
#align(center, {
  stack(dir: ltr, spacing: 14pt,
    slab("TNFS", cubes-c.at(0), w: 46pt),
    slab("SD", cubes-c.at(3), w: 34pt),
    slab("FTP", cubes-c.at(5), w: 40pt),
    slab("HTTP", cubes-c.at(7), w: 46pt),
    slab("SMB", cubes-c.at(9), w: 40pt),
    slab("NFS", cubes-c.at(8), w: 40pt),
    slab("GDRIVE", cubes-c.at(1), w: 56pt))
})

#pagebreak()
#contband

#grid(columns: (1fr, 1fr), column-gutter: 20pt, [
  #lsub[SMB --- the house network]

  SMB is the file sharing built into Windows (and served by Samba
  and most NAS boxes). Everything works. If the share wants a name
  and password, supply them with the USER and PASS commands
  #emph[before] mounting:

  #dialogue(
    ("you type", sf("USER MOLLY") + h(3pt) + key("return")),
    ("you type", sf("PASS SECRET") + h(3pt) + key("return")),
    ("you type", sf("NCD N1:SMB://DEN-PC/ATARI/", size: 5.8pt)))

  #lsub[NFS --- the Unix cousin]

  The traditional file sharing of Unix machines. Everything works.

  #dialogue(
    ("you type", sf("NCD N1:NFS://192.168.1.9/export/atari/", size: 5.4pt)))

  #lsub[GDRIVE --- a cloud guest]

  Google Drive, by way of a relay at fujinet.online. Authorize your
  Google account once in the FujiNet's web configuration page, and
  your Drive becomes a mountable volume --- list, read, write,
  delete, make directories. (Renaming isn't provided.)

  #dialogue(
    ("you type", sf("NCD N1:GDRIVE://drive/atari/", size: 5.8pt)))
], [
  #lsub[What Works Where]

  #{
    set text(size: 7.4pt)
    table(
      columns: (auto, 1fr, 1fr, 1fr, 1.15fr, 1.1fr),
      align: (left, center, center, center, center, center),
      stroke: 0.6pt + ink,
      inset: (x: 4pt, y: 4pt),
      table.header(
        text(font: f-sans, size: 7pt, tracking: 0.4pt)[PROTOCOL],
        text(font: f-sans, size: 7pt, tracking: 0.4pt)[DIR],
        text(font: f-sans, size: 7pt, tracking: 0.4pt)[READ],
        text(font: f-sans, size: 7pt, tracking: 0.4pt)[WRITE],
        text(font: f-sans, size: 7pt, tracking: 0.4pt)[DEL / REN /\ MKDIR],
        text(font: f-sans, size: 7pt, tracking: 0.4pt)[NOTE /\ POINT]),
      [TNFS],   sqdot, sqdot, sqdot, sqdot, sqdot,
      [SD],     sqdot, sqdot, sqdot, sqdot, sqdot,
      [FTP],    sqdot, sqdot, [(1)], [(1)], [---],
      [HTTP(S)],[(2)], sqdot, [(2)], [(2)], [(4)],
      [SMB],    sqdot, sqdot, sqdot, sqdot, sqdot,
      [NFS],    sqdot, sqdot, sqdot, sqdot, sqdot,
      [GDRIVE], sqdot, sqdot, sqdot, [(3)], [---])
  }
  #v(2pt)
  #text(size: 7pt)[(1) where the server permits its guests. (2)
  needs a WebDAV server; plain web sites are read-only. (3)
  everything except RENAME. (4) reading only --- see "Moving
  Around In a File."]

  #lsub[Beyond Files: The Stream Protocols]

  The #sf("N:") device speaks a few more languages --- #sf("TCP:"),
  #sf("UDP:"), #sf("TELNET:"), #sf("SSH:") --- that carry live
  #emph[streams] instead of files. There is no directory to list,
  so DIR and friends shrug; but a program (or a bold TYPE command)
  can hold a conversation through them. They belong to the
  FujiNet programmer's guide rather than to this booklet.

  #lsub[Mind Your Case]

  One habit to unlearn from DOS: most servers care about
  capitalization. On a TNFS or SMB server, #sf("Jumpman.xex") and
  #sf("JUMPMAN.XEX") are different files. When a command comes back
  empty-handed, check the case of what you typed against DIR.
])

#pagebreak()
// ============================================================
// LOOKING AT THE DIRECTORY  (silver)
// ============================================================
#page(fill: none, background: { silver-bg; folio })[
  #secmark("Looking at the Directory")
  #headband("Looking at", "the Directory")

  #grid(columns: (2.9in, 1fr), column-gutter: 18pt, [
    The Directory contains a list of all the files at the current
    spot on a mounted network drive. To see it, press #strong[A]
    at the menu and answer the search-spec question with a bare
    #key("return") --- or, at the prompt, type #strong[DIR]:

    #dialogue(
      ("you type", sf("DIR") + h(3pt) + key("return")))

    Each line shows a name and, at the right, a size --- plain
    bytes for small files, #sf("K") for kilobytes, #sf("M") for
    megabytes. Folders you can NCD into are marked with a trailing
    #sf("/"). Servers can hold #emph[far] more than a diskette's
    707 sectors, so long listings scroll: hold #key("space") to
    pause the parade, and press #key("esc") to stop it.

    A directory somewhere else is no harder. Name the drive, or
    the path, or both:

    #dialogue(
      ("you type", sf("DIR N2:") + h(3pt) + key("return")),
      ("you type", sf("DIR GAMES/") + h(3pt) + key("return")),
      ("you type", sf("DIR N2:GAMES/*.XEX") + h(3pt) + key("return")))

    That last one uses a #emph[wild card] --- the subject of the
    next section.
  ], [
    #screen(w: 3.4in)[
      #sf("N1:")#sf("DIR")\
      #sf("JUMPMAN.XEX                  25K")\
      #sf("STAR.RAIDERS.XEX             33K")\
      #sf("HELLO.BAS                    512")\
      #sf("NOTES.TXT                   1201")\
      #sf("LETTER.TXT                  4400")\
      #sf("GAMES/")\
      #sf("UTILS/")\
      #sf("N1:")#iv(sf(" "))
    ]
    #v(6pt)
    #align(center, globe(0.98in,
      patches: ((52, 28, -58, -20, 5), (52, 28, 12, 48, 0),
                (18, -8, -88, -62, 4), (18, -8, -28, 8, 8),
                (18, -8, 40, 78, 1), (-18, -42, -50, -14, 7),
                (-18, -42, 20, 55, 3), (-52, -74, -30, 10, 9)),
      raise-c: cubes-c.at(0)))
    #v(4pt)
    #align(center, box(width: 2.9in,
      text(size: 7.6pt)[The directory is the map of the volume:
        every file, its size, and the folders inside.]))
  ])
]

// ============================================================
// WILD CARDS  (full-page black art, like the booklet's p13)
// ============================================================
#page(margin: 0pt, fill: black, background: none)[
  #place(dx: 0.55in, dy: 0.55in, asterisk-flower(0.62in))
  #place(dx: 6.7in, dy: 0.5in,
    glyph3d("?", 120pt, rgb("#d23b2e"), depth: 0.08))
  // two ragged columns of bricks tumbling toward the grid
  #place(dx: 1.15in, dy: 1.35in,
    cubestream(unit: 1.5pt, arrows: (4,),
      ((30, 0, 10, 0, -35), (78, 14, 11, 3, 20), (18, 40, 10, 1, 10),
       (64, 52, 10, 7, -18), (30, 84, 11, 4, 30), (86, 92, 10, 5, -8),
       (48, 122, 10, 9, 42), (10, 138, 10, 2, -25))))
  #place(dx: 4.6in, dy: 1.5in,
    cubestream(unit: 1.5pt,
      ((60, 0, 10, 7, 25), (16, 22, 10, 5, -15), (70, 46, 11, 8, 8),
       (34, 70, 10, 6, -32), (72, 96, 10, 3, 18), (24, 120, 10, 0, -5))))
  // the network volume, big, breaching the bottom edge
  #place(dx: 1.7in, dy: 6.4in,
    globe(2.6in, depth: 0.05,
      body-c: rgb("#2c2826"), line-c: rgb("#6a625c"),
      patches: ((52, 28, -58, -20, 0), (52, 28, 12, 48, 4),
                (18, -8, -88, -62, 5), (18, -8, -28, 8, 1),
                (18, -8, 40, 78, 8), (-18, -42, -50, -14, 3))))
]

// ============================================================
// WILD CARDS, the text page  (cream)
// ============================================================
#secmark("Wild Cards")
#headband("Wild", "Cards", flush: right)

#grid(columns: (1fr, 1fr, 1fr), column-gutter: 14pt, [
  A wild card in a filename works just like a joker in a pack of
  cards --- it stands in for characters you don't feel like
  spelling out. Two are allowed: an asterisk (#sf("*")) stands for
  any run of characters, and a question mark (#sf("?")) stands for
  exactly one.

  Suppose your work directory holds a season's worth of BASIC
  programs mixed in with text files. To see just the BASIC:

  #dialogue(
    ("you type", sf("DIR *.BAS") + h(3pt) + key("return")),
    ("computer", sf("FILE1.BAS      884", size: 5.8pt)),
    ("", sf("FILE2.BAS      901", size: 5.8pt)),
    ("", sf("GAME.BAS       15K", size: 5.8pt)))
], [
  And to pick out numbered files one digit apart:

  #dialogue(
    ("you type", sf("DIR NAME?.DAT") + h(3pt) + key("return")),
    ("computer", sf("NAME1.DAT      128", size: 5.8pt)),
    ("", sf("NAME2.DAT      128", size: 5.8pt)),
    ("", sf("NAME3.DAT      128", size: 5.8pt)))

  Two small prints. First, folders are always listed, whatever
  pattern you give --- the pattern sifts files only. Second,
  remember that servers usually mind capitalization:
  #sf("*.xex") and #sf("*.XEX") can be different crowds.
], [
  #lsub[Where Wild Cards Work]

  Wild cards work in #strong[DIR] --- and, new in NOS 1.0, in
  #strong[DELETE] and #strong[COPY] too. Deleting stays careful:
  every matched file is offered back by name, and only a Y sends
  it away. Copying announces each file as it goes. The chapters
  "Copying Files" and "Deleting and Renaming" show both at work.
  #strong[RENAME] is the lone holdout: one plain filename at a
  time.

  One grain of fine print: NOS gathers the matched names into a
  512-byte basket --- room for a few dozen names per command. If
  a pattern catches more files than the basket holds, simply run
  the command again; it refills with the files that remain.
])

#pagebreak()

// ============================================================
// FILESPECS AND URLS  (cream)
// ============================================================
#secmark("Filespecs and URLs")
#headband("Filespecs", "and URLs")

#grid(columns: (1fr, 1fr), column-gutter: 20pt, [
  Just as you call a person by name, so must you call a file by its
  right name. A complete NOS filespec has more parts than a DOS
  one, because it can name any file on Earth --- but you'll almost
  never spell out the whole thing. Once a drive is mounted, the
  drive remembers the protocol, the host, and the path, and a
  filespec shrinks back to the friendly old shape:

  #dialogue(
    ("you type", sf("LOAD JUMPMAN.XEX")),
    ("you type", sf("LOAD N2:GAMES/JUMPMAN.XEX", size: 5.8pt)))

  #lsub[The Rules]

  #item[Names may be long, and may use upper case, lower case,
    digits, and punctuation the server allows.]
  #item[Most servers treat capital and small letters as
    #emph[different.] #sf("Letter.txt") is not #sf("LETTER.TXT").]
  #item[A name with spaces must ride inside double quotes,
    device and all: #sf("DEL \"N2:My File.TXT\"", size: 5.8pt)]
  #item[Extenders still mean what they meant: #sf(".BAS") for
    BASIC, #sf(".XEX") and #sf(".COM") for machine programs,
    #sf(".TXT") for text.]
  #item[Paths use #sf("/"), and #sf("..") walks up one folder.]
], [
  #lsub[Anatomy of the Full Spec]

  When you do need the whole thing --- in NCD, or in a filespec
  aimed at an unmounted spot --- the parts snap together like
  this:

  #v(6pt)
  #{
    set par(first-line-indent: 0pt, leading: 0.3em)
    let lab(t) = text(font: f-sans, size: 6.6pt, tracking: 0.4pt,
      fill: toc-blue, upper(t))
    box({
      sf("N2:TNFS://192.168.1.20/GAMES/JUMPMAN.XEX", size: 6.2pt)
      v(3pt)
      // one measured underbracket per part; DRIVE/HOST/FILE label
      // the top row, PROTOCOL/PATH drop a row on leader stems
      context {
        let adv = measure(sf("N2:TNFS://192.168.1.20/GAMES/JUMPMAN.XEX",
          size: 6.2pt)).width / 40
        box(width: 100%, height: 30pt, {
          let bracket(c0, c1) = {
            place(dx: c0 * adv, dy: 3.4pt, line(length: (c1 - c0) * adv,
              stroke: 0.7pt + toc-blue))
            place(dx: c0 * adv, dy: 1.0pt, line(angle: 90deg,
              length: 2.4pt, stroke: 0.7pt + toc-blue))
            place(dx: c1 * adv, dy: 1.0pt, line(angle: 90deg,
              length: 2.4pt, stroke: 0.7pt + toc-blue))
          }
          let clabel(c0, c1, t, y) = place(
            dx: (c0 + c1) / 2 * adv - 0.6in, dy: y,
            box(width: 1.2in, align(center, lab(t))))
          bracket(0, 3)      // N2:
          bracket(3, 10)     // TNFS://
          bracket(10, 22)    // 192.168.1.20
          bracket(22, 29)    // /GAMES/
          bracket(29, 40)    // JUMPMAN.XEX
          clabel(0, 3, "drive", 7.5pt)
          clabel(10, 22, "host", 7.5pt)
          clabel(29, 40, "file", 7.5pt)
          place(dx: 6.5 * adv, dy: 5pt, line(angle: 90deg,
            length: 12.5pt, stroke: 0.7pt + toc-blue))
          place(dx: 25.5 * adv, dy: 5pt, line(angle: 90deg,
            length: 12.5pt, stroke: 0.7pt + toc-blue))
          clabel(3, 10, "protocol", 19pt)
          clabel(22, 29, "path", 19pt)
        })
      }
    })
  }
  #v(4pt)

  The drive says #emph[which of the eight connections.] The
  protocol says #emph[what language.] The host says #emph[which
  server] --- a name or an address, with an optional
  #sf(":port") after it if the server listens somewhere unusual.
  The path and file say the rest.

  #lsub[When D: Appears]

  Programs may still say #sf("D:") or #sf("D1:") in their
  filespecs. NOS forwards the call to the matching network drive
  --- #sf("D1:") means #sf("N1:"), #sf("D2:") means #sf("N2:"),
  and so on. Nothing to set up; it simply works.
])

#v(0.3in)
#align(center, rotate(45deg, reflow: false,
  globe(1.5in,
    patches: ((52, 28, -58, -20, 8), (18, -8, -88, -62, 5),
              (18, -8, 40, 78, 0), (-18, -42, -50, -14, 6),
              (-52, -74, -30, 10, 4)))))
#v(0.85in)

#pagebreak()

// ============================================================
// SAVING AND LOADING A BASIC PROGRAM  (silver spread, p8 tribute)
// ============================================================
#page(fill: none, background: { silver-bg; folio })[
  #secmark("Saving and Loading a BASIC Program")
  #headband("Saving and Loading", "a BASIC Program")

  #grid(columns: (1fr, 1fr, 1fr), column-gutter: 14pt, [
    It's quite easy to save a program you have written onto a
    server, and then load it back --- even for a program that has
    never heard of a network. Let's prove it with the oldest
    two-liner in the book. You'll need a mounted drive you're
    allowed to write to (your own TNFS server, an SMB share, or
    the FujiNet's SD card are all good).

    Go to BASIC --- press #strong[B] at the menu, or type
    #sf("CAR") at the prompt, if a BASIC cartridge or built-in
    BASIC is waiting --- and type:

    #dialogue(
      ("computer", sf("READY")),
      ("you type", sf("10 PRINT \"HELLO NETWORK\"") + h(3pt) + key("return")),
      ("you type", sf("20 GOTO 10") + h(3pt) + key("return")))
  ], [
    Now save it, exactly the way the 1050 manual taught:

    #dialogue(
      ("you type", sf("SAVE \"D:MYFILE\"") + h(3pt) + key("return")))

    The FujiNet's bus light flickers, and the program streams out
    of memory, through the FujiNet, and onto the server ---
    because on this machine, #sf("D:") #emph[is] #sf("N1:").
    You could just as well have typed #sf("SAVE \"N1:MYFILE\"");
    they land in the same place.

    To prove the save worked, switch the computer off and on
    (boot NOS again), go to BASIC, and:

    #dialogue(
      ("you type", sf("LOAD \"D:MYFILE\"") + h(3pt) + key("return")),
      ("computer", sf("READY")),
      ("you type", sf("LIST") + h(3pt) + key("return")))
  ], [
    There is your program, back from across the network. #sf("RUN")
    it and enjoy the applause. (Press #key("break") to stop it.)

    Everything else you know works the same way:
    #sf("RUN \"D:MYFILE\"") loads and runs in one step;
    #sf("LIST \"D:PROG.LST\"") and #sf("ENTER \"D:PROG.LST\"")
    move listings; #sf("PRINT#") and #sf("INPUT#") tend data
    files.

    #lsub[NOTE and POINT, Too]

    Even BASIC's NOTE and POINT --- the commands that jump around
    inside a file --- work over the network now, wherever the
    protocol plays along. That story is new in NOS 1.0, and it
    gets its own chapter, "Moving Around In a File." Everything
    that reads or writes start-to-finish --- which is nearly
    everything --- is right at home already.
  ])

  // the money shot: cubes out of the keyboard, into the globe
  #place(bottom + left, dx: -0.05in, dy: 0.5in,
    box(width: 7.3in, height: 3.1in, {
      place(dx: 0in, dy: 0.8in, atari800(3.3in))
      place(dx: 2.6in, dy: -0.15in,
        cubestream(unit: 1.35pt, arrows: (2, 8),
          ((6, 96, 8, 0, -20), (24, 76, 8, 7, 25), (44, 58, 9, 3, -5),
           (66, 44, 8, 4, 40), (90, 33, 9, 5, 12), (116, 26, 8, 1, -30),
           (143, 24, 9, 8, 8), (169, 28, 8, 9, -18), (194, 38, 9, 2, 30),
           (216, 52, 8, 6, -8), (236, 70, 8, 0, 22))))
      place(dx: 5.35in, dy: 1.1in,
        globe(0.95in,
          patches: ((52, 28, -58, -20, 0), (52, 28, 12, 48, 4),
                    (18, -8, -88, -62, 5), (18, -8, -28, 8, 1),
                    (-18, -42, -50, -14, 3), (-52, -74, -30, 10, 6))))
    }))
]

#pagebreak(weak: true)
// ============================================================
// LOADING PROGRAMS  (cream)
// ============================================================
#secmark("Loading Programs")
#headband("Loading", "Programs")

#grid(columns: (1fr, 1fr, 1fr), column-gutter: 14pt, [
  Most of the software you'll meet on the network is #emph[binary]
  --- machine-language programs with extenders like #sf(".XEX") or
  #sf(".COM"). The #strong[LOAD] command brings one in and runs it
  --- item #strong[L. BINARY LOAD] on the menu, with #strong[X] as
  a one-letter alias for the impatient at the prompt:

  #dialogue(
    ("you type", sf("LOAD JUMPMAN.XEX") + h(3pt) + key("return")),
    ("you type", sf("X N2:GAMES/JUMPMAN.XEX", size: 5.8pt)))

  LOAD understands the standard ATARI binary format --- it
  follows the file's own instructions about where to sit in
  memory, runs any initialization on the way, and jumps to the
  program at the end. If a file isn't binary at all, NOS says so:

  #dialogue(
    ("computer", sf("NOT A BINARY FILE")))

  Line-ending translation (see "Text Files") is switched off
  automatically on the drive doing the loading, so a binary never
  arrives scrambled. And loading is quick: whenever at least 128
  bytes are on the way, NOS moves them in single bursts of up to
  8K, streamed straight into their place in memory --- no bucket
  brigade, byte by byte. "Inside NOS" tells how.

  #lsub[The Shortcut]

  Type a bare word NOS doesn't recognize, and NOS assumes you
  mean a program: it adds #sf(".COM") and tries to LOAD it from
  the current drive. If your server has an
  #sf("ATARIWRITER.COM"), then this is all it takes:

  #dialogue(
    ("you type", sf("ATARIWRITER") + h(3pt) + key("return")))

  In effect, every #sf(".COM") on the current drive is a NOS
  command.
], [
  #lsub[Coming Back]

  Some programs offer an "exit to DOS." With NOS underneath, that
  lands you back at the menu --- and because NOS runs its commands
  from a buffer well below your program's quarters, you can often
  hop back in:

  #dialogue(
    ("you type", sf("REENTER") + h(3pt) + key("return")))

  #strong[REENTER] (or #strong[REE]) jumps to the program's own
  restart address. Two honest cautions. The menu you land on
  borrows the memory at \$2600--\$2AFF while it draws, so a
  program occupying that particular patch won't survive the
  round trip. And whether #emph[any] program survives is the
  program's business --- some re-initialize and wipe their slate
  --- so save your work first.

  You can also run machine code anywhere in memory by address ---
  item #strong[M] on the menu, #strong[RUN] at the prompt (four
  hex digits, no #sf("\$"), lead small addresses with a zero):

  #dialogue(
    ("you type", sf("RUN A000") + h(3pt) + key("return")),
    ("you type", sf("RUN 0600") + h(3pt) + key("return")))
], [
  #lsub[Cartridges and BASIC]

  #strong[CAR] --- item #strong[B] on the menu --- hands control
  to the cartridge (or built-in BASIC) without a cold start ---
  your BASIC listing is still there when you arrive. Type
  #sf("DOS") in BASIC to come back to NOS, work a while, then
  #sf("CAR") again. One caution for long programs: coming back
  draws the menu, which borrows the memory from \$2600 up ---
  room for about 2.8K of BASIC program above NOS's floor. Longer
  than that, SAVE before you visit.

  On XL and XE machines, #strong[BASIC ON] and #strong[BASIC OFF]
  (item #strong[H]) swap the built-in BASIC in and out of the
  memory map without
  the ritual of rebooting while holding #key("option"). (The
  command answers to #strong[ROM ON] / #strong[ROM OFF] too, for
  machines whose banked ROM holds something other than BASIC.)
  While ROM occupies \$A000--\$BFFF, NOS keeps the screen border
  gray as a reminder; #sf("BASIC ON") when it's already on simply
  behaves like CAR.

  #lsub[Saving Binaries]

  #strong[SAVE] --- item #strong[K] --- writes a memory range out
  in the same binary format, with optional init and run
  addresses:

  #dialogue(
    ("you type", sf("SAVE MYPROG,2000,2FFF", size: 5.8pt)),
    ("you type", sf("SAVE MYPROG,2000,2FFF,,2000", size: 5.4pt)))

  The double comma skips the init address while supplying the
  run address --- the reference pages have the full recipe.
])

#pagebreak()

// ============================================================
// COPYING FILES  (cream)
// ============================================================
#secmark("Copying Files")
#headband("Copying", "Files", flush: right)

#grid(columns: (1fr, 1fr, 1fr), column-gutter: 14pt, [
  The #strong[NCOPY] command (alias #strong[COPY]) makes a copy of
  a file --- on the same drive, or clear across the world from one
  server to another. It's item #strong[C] on the menu, asking
  #sf("COPY-FROM,TO?", size: 5.8pt); at the prompt, name the
  source, a comma, and the destination:

  #dialogue(
    ("you type", sf("NCOPY MYFILE,MYFILE2", size: 5.8pt)),
    ("you type", sf("NCOPY N1:GAME.XEX,N2:GAME.XEX", size: 5.2pt)))

  That second command is quietly astonishing: the file streams
  down from one server and up to another, with your ATARI
  conducting. When the destination keeps the same name, you may
  shorten it to a bare drive --- or any folder ending in
  #sf("/") --- or, new in 1.0, leave it off altogether: one lone
  argument means "copy it #emph[here,] onto the current drive."

  #dialogue(
    ("you type", sf("NCOPY N1:GAME.XEX,N2:", size: 5.8pt)),
    ("you type", sf("NCOPY GAME.XEX,N2:GAMES/", size: 5.8pt)),
    ("you type", sf("COPY N2:GAMES/GAME.XEX", size: 5.8pt)))

  NOS refuses to copy a file exactly onto itself ---
  #sf("SAME FILE?") is its whole objection.
], [
  #lsub[A Handful At Once]

  New in 1.0: give the source a wild card and NCOPY copies
  everything that matches, announcing each file as it goes ---
  no questions asked:

  #dialogue(
    ("you type", sf("COPY *.BAS,N2:BACKUP/", size: 5.6pt)),
    ("computer", sf("FILE1.BAS", size: 5.8pt)),
    ("", sf("FILE2.BAS", size: 5.8pt)),
    ("", sf("GAME.BAS", size: 5.8pt)))

  #lsub[Adding On]

  A third argument, #sf("A"), appends the source to the end of
  the destination instead of replacing it --- handy for building
  one big log out of many small pieces:

  #dialogue(
    ("you type", sf("NCOPY DAY2.TXT,LOG.TXT,A", size: 5.6pt)))

  #lsub[Two Cautions]

  #item[If line-ending translation is switched on (NTRANS --- see
    "Text Files and Line Endings"), it alters what NCOPY carries
    --- fine for text, ruinous for binaries. Leave translation at
    0 when copying programs.]
  #item[NCOPY builds its network destination over drive
    #sf("N4:") --- another reason to keep your own mounts off
    drive 4.]
], [
  #lsub[Copying To Devices]

  The destination doesn't have to be a file. Send text to the
  printer, or straight to the screen:

  #dialogue(
    ("you type", sf("NCOPY NOTES.TXT,P:", size: 5.8pt)),
    ("you type", sf("NCOPY NOTES.TXT,E:", size: 5.8pt)))

  #v(0.1in)
  #align(center, box(width: 2.1in, height: 3.6in, {
    place(dx: 0.1in, dy: 0in,
      globe(0.78in,
        patches: ((52, 28, -58, -20, 0), (18, -8, -28, 8, 4),
                  (-18, -42, -50, -14, 3), (-52, -74, -30, 10, 6)),
        raise-c: cubes-c.at(1)))
    place(dx: 1.0in, dy: 1.55in,
      cubestream(unit: 1.2pt, arrows: (1,),
        ((10, 4, 8, 1, 30), (34, 22, 8, 1, 0), (58, 44, 8, 1, -25))))
    place(dx: 0.35in, dy: 2.05in,
      globe(0.78in,
        patches: ((52, 28, 12, 48, 8), (18, -8, 40, 78, 5),
                  (-18, -42, 20, 55, 9))))
  }))
  #align(center, box(width: 2.0in,
    text(size: 7.6pt)[One file, two servers: NCOPY lifts it from
      the first volume and lays it onto the second.]))
])

#pagebreak()

// ============================================================
// DELETING AND RENAMING  (cream)
// ============================================================
#secmark("Deleting and Renaming")
#headband("Deleting and", "Renaming")

#grid(columns: (1fr, 1fr, 1fr), column-gutter: 14pt, [
  The #strong[DEL] command removes files from a mounted drive.
  (It answers to #strong[ERASE] and #strong[ERA] as well, and to
  item #strong[D. DELETE FILE(S)] on the menu.)

  #dialogue(
    ("you type", sf("DEL MYFILE.AWP") + h(3pt) + key("return")),
    ("you type", sf("DEL N2:DOCS/OLD.TXT", size: 5.8pt)),
    ("you type", sf("DEL \"N2:My File.AWP\"", size: 5.8pt)))

  Mind three things. A plain name deletes #emph[immediately] ---
  no are-you-sure. It is #emph[case-sensitive] --- ask DIR for
  the exact name first. And there is no undelete anywhere on the
  network.

  #v(0.15in)
  #align(center, box(width: 2.2in, height: 3.65in, {
    place(dx: 0.15in, dy: 0in, rotate(18deg, reflow: false,
      globe(0.85in,
        patches: ((52, 28, -58, -20, 5), (18, -8, -28, 8, 8),
                  (18, -8, 40, 78, 3)))))
    place(dx: 0.35in, dy: 2.0in,
      cubestream(unit: 1.25pt,
        ((10, 0, 8, 0, 160), (48, 10, 8, 4, 200), (86, 6, 8, 9, 140),
         (28, 40, 7, 7, 190), (66, 46, 7, 1, 150), (12, 78, 7, 6, 170))))
  }))
  #align(center, box(width: 2.0in,
    text(size: 7.6pt)[DEL tips the volume: the file's blocks
      tumble away for good. There is no getting them back.]))
], [
  #lsub[Deleting a Crowd]

  New in 1.0: give DEL a wild card, and it turns careful. Every
  file that matches is offered back by name, and nothing goes
  until you say Y:

  #dialogue(
    ("you type", sf("DEL *.BAK") + h(3pt) + key("return")),
    ("computer", sf("DRAFT1.BAK (Y/N)?")),
    ("you type", sf("Y") + h(3pt) + key("return")),
    ("computer", sf("DRAFT2.BAK (Y/N)?")),
    ("you type", sf("N") + h(3pt) + key("return")),
    ("computer", sf("NOTES.BAK (Y/N)?")))

  Any answer but Y --- an N, a bare #key("return") --- spares
  that file and moves along to the next. So #sf("DEL *.*") is
  not the catastrophe it was on DOS 2.0: it's an interview.

  The safety net has this shape on purpose: the #emph[pattern]
  casts wide, and the #emph[questions] keep you honest. If
  you've already made your peace, answering a column of Y's
  still beats typing a column of DELs.
], [
  #lsub[Renaming]

  #strong[RENAME] (alias #strong[REN], item #strong[E]) gives
  one file a new name: old name, comma, new name.

  #dialogue(
    ("you type", sf("RENAME Draft.txt,FINAL.TXT", size: 5.2pt)),
    ("you type", sf("REN N2:A.TXT,B.TXT", size: 5.8pt)))

  Give the new name bare --- no drive, no path. (Renaming through
  a relative path is a known rough edge in this version; NCD to
  the file's folder first.) Wild cards don't reach RENAME ---
  one file at a time here.

  #lsub[Making Room]

  Directories are yours to create and remove --- items
  #strong[F] and #strong[G], where the protocol allows:

  #dialogue(
    ("you type", sf("MKDIR PROJECTS") + h(3pt) + key("return")),
    ("you type", sf("RMDIR PROJECTS") + h(3pt) + key("return")))

  RMDIR only removes an #emph[empty] directory --- clean it out
  first.
])

#pagebreak()

// ============================================================
// TEXT FILES AND LINE ENDINGS  (cream)
// ============================================================
#secmark("Text Files and Line Endings")
#headband("Text Files and", "Line Endings", flush: right)

#grid(columns: (1fr, 1fr, 1fr), column-gutter: 14pt, [
  To read a text file without leaving NOS, use #strong[TYPE] ---
  item #strong[O] on the menu:

  #dialogue(
    ("you type", sf("TYPE README.TXT") + h(3pt) + key("return")),
    ("you type", sf("TYPE N3:HTTPS://fujinet.online/", size: 5.4pt)))

  TYPE clears the screen and shows the file a screenful at a
  time. Press any key for the next page; press #key("esc") to
  stop. It quietly copes with text from other computers ---
  carriage returns and linefeeds both --- so most files read
  clean with no ceremony. Point it only at #emph[text:] TYPE
  trusts what it reads, and a big binary can overrun its buffer
  and scramble memory.
], [
  #lsub[Why Line Endings Matter]

  Your ATARI ends a line of text with its own EOL character
  (155). Nearly every other computer ends lines with CR, LF, or
  both. A file is just bytes; if it moves between worlds
  untranslated, it reads as one endless line on one side or
  staircases on the other.

  The #strong[NTRANS] command tells a network drive how to
  translate #emph[as bytes flow through it,] each direction:

  #dialogue(
    ("you type", sf("NTRANS N1: 2") + h(3pt) + key("return")))

  #{
    set text(size: 7.6pt)
    table(columns: (0.5in, 1fr), stroke: 0.6pt + ink,
      inset: (x: 5pt, y: 3.5pt),
      align: (center, left),
      table.header(
        text(font: f-sans, size: 7pt, tracking: 0.4pt)[MODE],
        text(font: f-sans, size: 7pt, tracking: 0.4pt)[TRANSLATION]),
      sf("0", size: 6pt), [none --- bytes pass untouched],
      sf("1", size: 6pt), [CR #dblarrow ATARI EOL],
      sf("2", size: 6pt), [LF #dblarrow ATARI EOL (Unix, Mac)],
      sf("3", size: 6pt), [CR/LF #dblarrow ATARI EOL (Windows)])
  }
], [
  #lsub[The One Rule of NTRANS]

  Translation is for text and #emph[only] text. A binary program
  hauled through mode 2 arrives subtly broken --- every byte that
  happened to equal 10 turned into 155. LOAD protects itself by
  switching translation off on its drive; NCOPY does not, so
  check before you copy programs.

  Set it per drive and forget it: a drive mounted on a Unix or
  Windows server for text work wants mode 2 or 3; a drive full
  of ATARI software wants 0.

  #v(0.35in)
  #align(center, box(width: 2.1in, height: 1.15in, {
    place(dx: 0in, dy: 0.28in, slab("155", cubes-c.at(4), w: 34pt))
    place(dx: 0.72in, dy: 0.32in,
      arrowcube(13pt, cubes-c.at(0)))
    place(dx: 0.72in, dy: 0.62in,
      rotate(180deg, reflow: false, arrowcube(13pt, cubes-c.at(7))))
    place(dx: 1.28in, dy: 0.12in, slab("CR", cubes-c.at(9), w: 30pt))
    place(dx: 1.42in, dy: 0.55in, slab("LF", cubes-c.at(5), w: 30pt))
  }))
  #align(center, box(width: 2.0in,
    text(size: 7.6pt)[NTRANS swaps line endings in flight ---
      ATARI's 155 on this side, CR and/or LF on that side.]))
])

#pagebreak()

// ============================================================
// MOVING AROUND IN A FILE  (cream) — NOTE/POINT, new in 1.0
// ============================================================
#secmark("Moving Around In a File")
#headband("Moving Around", "In a File", flush: right)

#grid(columns: (1fr, 1fr), column-gutter: 20pt, [
  Most programs read a file the way you read a novel: front to
  back, no skipping. But some files are built for jumping around
  in --- a database that hops straight to customer 500, a word
  processor that stitches pages out of order. On a diskette,
  BASIC's NOTE and POINT did the jumping. New in NOS 1.0, they
  jump across the network too.

  NOTE asks #emph[where am I?] POINT says #emph[go there.] And the
  dialect is byte-counting, the way SpartaDOS speaks, not DOS 2's
  sector-and-offset: a position is simply how many bytes into the
  file you are, counted from zero.

  #dialogue(
    ("you type", sf("100 OPEN #1,4,0,\"D:BIG.DAT\"", size: 5.6pt)),
    ("you type", sf("110 POINT #1,5000,0", size: 5.6pt)),
    ("you type", sf("120 GET #1,B", size: 5.6pt)))

  Line 110 jumps clean to byte 5,000 --- no reading past the
  first 4,999 to get there --- and GET picks up the byte living
  there. The two numbers make one position: #emph[position =
  first + 65,536 × second.] For files under 64K, which is most
  of them, the second number is simply 0, and the first is the
  byte position, plain as a page number.

  Reading along, NOTE remembers a place worth returning to:

  #dialogue(
    ("you type", sf("200 NOTE #1,A,B", size: 5.6pt)),
    ("you type", sf("210 REM READ ON A WHILE...", size: 5.6pt)),
    ("you type", sf("220 POINT #1,A,B", size: 5.6pt)))

  NOS keeps the books straight behind the scenes: NOTE answers
  with #emph[your program's] place --- not the FujiNet's, which
  reads a little ahead --- and POINT throws the read-ahead away
  and starts fresh at the new spot.
], [
  #lsub[From Machine Language]

  NOTE is XIO 38 and POINT is XIO 37, the same CIO commands every
  DOS answered. The position is 24 bits, riding in the IOCB's
  auxiliary bytes --- ICAX3 low, ICAX4 middle, ICAX5 high --- for
  a reach of 16 megabytes into any file. The source listing in
  the back shows both ends of the conversation
  (#sf("PNOTE", size: 5.8pt) and #sf("PPOINT", size: 5.8pt)).

  #lsub[Where Jumping Works]

  Jumping is the server's trick, so the protocol must play along:

  #{
    set text(size: 7.5pt)
    table(columns: (1.3in, 1fr), stroke: 0.6pt + ink,
      inset: (x: 5pt, y: 3.4pt),
      table.header(
        text(font: f-sans, size: 7pt, tracking: 0.4pt)[PROTOCOL],
        text(font: f-sans, size: 7pt, tracking: 0.4pt)[NOTE AND POINT]),
      [TNFS, SD, SMB, NFS], [jump anywhere, reading or writing],
      [HTTP(S)], [reading only],
      [FTP, GDRIVE, streams], [front to back only --- no jumping])
  }

  On the web the jump is a polite request to resume elsewhere ---
  a #emph[Range] request, the same trick download managers use
  --- and the FujiNet quietly reopens the connection to make it.
  Fine for reading; there is no jumping while #emph[writing] a
  web resource.

  A protocol that can't jump answers POINT with
  #sf("ERROR 166") --- the same "invalid POINT" number DOS
  always reserved for the complaint.

  #v(0.2in)
  #align(center, box(width: 2.3in, height: 1.9in, {
    place(dx: 0.15in, dy: 0.25in,
      globe(0.8in,
        patches: ((52, 28, 12, 48, 4), (18, -8, -88, -62, 5),
                  (-18, -42, 20, 55, 9)),
        raise-c: cubes-c.at(0)))
    place(dx: 1.72in, dy: 0.05in, rotate(115deg, reflow: false,
      arrowcube(15pt, cubes-c.at(7))))
  }))
  #align(center, box(width: 2.2in,
    text(size: 7.6pt)[POINT drops the needle anywhere on the
      volume; NOTE reads off exactly where it sits.]))
])

#pagebreak()

// ============================================================
// BATCH FILES  (silver)
// ============================================================
#page(fill: none, background: { silver-bg; folio })[
  #secmark("Batch Files")
  #headband("Batch", "Files")

  #grid(columns: (1fr, 1fr, 1fr), column-gutter: 14pt, [
    Any list of NOS commands can be saved as a text file and
    played back with one command. The file is called a #emph[batch
    file,] and the command is #strong[SUBMIT] --- or just
    #strong[\@].

    #dialogue(
      ("you type", sf("SUBMIT SETUP.BAT") + h(3pt) + key("return")),
      ("you type", sf("@ SETUP.BAT") + h(3pt) + key("return")))

    Each line runs exactly as if you had typed it at the prompt.
    And because a batch file is only text, you can write it
    #emph[anywhere] --- in an ATARI editor, or on your PC in the
    comfort of a big screen, saved straight onto the server NOS
    reads it from. ATARI line endings, Unix LF, Windows CR/LF:
    SUBMIT reads them all as they come, no NTRANS needed.
  ], [
    #lsub[The Batch Toolkit]

    Four commands exist mostly for batch files.

    #strong[PRINT] puts a message on the screen:

    #dialogue(
      ("", sf("PRINT \"MOUNTING DRIVES...\"", size: 5.6pt)))

    #strong[REM] marks a comment --- so does an apostrophe or
    #sf("#") --- and the line is ignored:

    #dialogue(
      ("", sf("REM SET UP MY MORNING", size: 5.8pt)),
      ("", sf("' THIS TOO IS A COMMENT", size: 5.8pt)))

    #strong[\@SCREEN] and #strong[\@NOSCREEN] control whether each
    command is echoed to the screen as it runs. A batch file runs
    #emph[quietly] unless you ask: put #sf("@SCREEN") where you
    want the play-by-play to start, #sf("@NOSCREEN") where you
    want it to stop. (Lines that begin with #sf("@") are never
    echoed.)
  ], [
    #lsub[A Morning Batch File]

    Here is a #sf("SETUP.BAT") that readies a whole desk:

    #screen(w: 2.42in)[
      #sf("REM -- MY MORNING SETUP --", size: 4.8pt)\
      #sf("PRINT \"GOOD MORNING\"", size: 4.8pt)\
      #sf("NCD N1:TNFS://192.168.1.20/WORK/", size: 4.8pt)\
      #sf("NCD N2:TNFS://APPS.IRATA.ONLINE/", size: 4.8pt)\
      #sf("NCD N3:SD://SCRATCH/", size: 4.8pt)\
      #sf("NTRANS N1: 2", size: 4.8pt)\
      #sf("PRINT \"DRIVES 1-3 READY\"", size: 4.8pt)
    ]

    Drive 1 mounts your PC's work folder (with Unix line endings
    translated), drive 2 a public library, drive 3 the FujiNet's
    own SD card. The next section makes a file like this run
    #emph[itself.]
  ])

  #place(bottom + left, dx: 0.2in, dy: 0.35in,
    cubestream(unit: 1.1pt, arrows: (5,),
      ((6, 30, 7, 5, -12), (36, 22, 7, 7, 15), (66, 16, 7, 0, -30),
       (96, 12, 7, 3, 25), (126, 10, 7, 9, 5), (156, 10, 7, 4, 0),
       (186, 12, 7, 8, -20), (216, 16, 7, 1, 30), (246, 22, 7, 6, -8))))
]

// ============================================================
// AUTORUN  (silver)
// ============================================================
#page(fill: none, background: { silver-bg; folio })[
  #secmark("AUTORUN: Starting Up Your Way")
  #headband("Starting Up", "Your Way", flush: right)

  #grid(columns: (1fr, 1fr, 1fr), column-gutter: 14pt, [
    Atari DOS had AUTORUN.SYS: put the right file on the right
    diskette, and the computer set itself up at boot. NOS has the
    same idea with a twist worth understanding: the setting lives
    #emph[in your FujiNet,] not on any disk.

    Tell NOS which batch file to run at boot by handing
    #strong[AUTORUN] a full URL --- protocol, host, path, and
    all, since at boot time nothing is mounted yet:

    #dialogue(
      ("you type", sf("AUTORUN TNFS://192.168.1.20/SETUP.BAT", size: 5pt)))

    From then on, every cold start ends with that batch file
    playing through --- drives mounted, translation set, message
    on the screen, ready to work before you've touched a key.
  ], [
    #lsub[Where the Setting Lives]

    When you set AUTORUN, NOS writes the URL into an
    #emph[AppKey] --- a small named record the FujiNet keeps for
    programs --- and AppKeys are stored on the microSD card in
    the FujiNet itself, in a file called
    #sf("/FujiNet/db790000.key", size: 5.8pt). So the FujiNet
    needs an SD card (FAT32) for AUTORUN to stick.

    Because the setting rides in the FujiNet:

    #item[It survives power-off, and doesn't care which disk
      image booted.]
    #item[Carry your FujiNet to a friend's ATARI, and your
      startup comes along.]
    #item[Swap SD cards, and it stays with the #emph[card.]]
  ], [
    #lsub[Asking and Clearing]

    Query the current setting with a question mark; clear it with
    an empty string:

    #dialogue(
      ("you type", sf("AUTORUN ?") + h(3pt) + key("return")),
      ("computer", sf("TNFS://192.168.1.20/SETUP.BAT", size: 5pt)),
      ("you type", sf("AUTORUN \"\"") + h(3pt) + key("return")))

    #lsub[Skipping It]

    Batch file gone wrong, or just want a plain prompt? Hold
    #key("option") while NOS boots, and AUTORUN is skipped for
    that start.
  ])

  // the key sliding home
  #place(bottom + left, dx: 0.35in, dy: -0.15in,
    box(width: 7.0in, height: 3.95in, {
      place(dx: 0.15in, dy: 1.9in, key3d(2.1in))
      place(dx: 2.55in, dy: 2.2in,
        text(font: f-scrn, size: 8pt, fill: ink, "db790000.key"))
      place(dx: 4.1in, dy: 0.1in,
        image("images/fujinet-rear34.png", width: 2.5in))
    }))
  #place(bottom + left, dx: 0.55in, dy: -2.62in,
    box(width: 3.2in, text(size: 7.6pt)[Your startup, kept like a
      key in the FujiNet's pocket: an AppKey on its SD card, waiting
      for every cold start.]))
]

#pagebreak(weak: true)
// ============================================================
// WHAT NOS DOESN'T DO  (cream spread, for the DOS expert)
// ============================================================
#secmark("What NOS Doesn't Do")
#headband("What NOS", "Doesn't Do")

#grid(columns: (1fr, 1fr, 1fr), column-gutter: 14pt, [
  NOS wears DOS's clothes --- the menu, the letters, the prompt
  --- so it's fair to ask what it deliberately leaves out. The
  list is short, and every entry on it has the same explanation:
  #emph[NOS contains no File Management System.] It cannot read
  or write diskettes or disk images --- not even the ones your
  FujiNet mounts in its disk slots. #sf("D:") goes to the
  network, full stop.

  #lsub[No Lock and Unlock]

  Whether a network file may be changed is the #emph[server's]
  decision, not NOS's. To protect files, set permissions on the
  server (or mount read-only media). A read-only file gives a
  write error, much like DOS's ERROR 167.

  #lsub[The Last Few Gaps]

  #item[#strong[RENAME] takes one plain name --- the only file
    command wild cards haven't reached.]
  #item[There is no #strong[MOVE] --- copy, then delete.]
  #item[DIR lists names and sizes, but no dates --- servers know
    them; NOS doesn't ask yet.]
], [
  #lsub[No Diskettes At All]

  When you really need a diskette or an ATR disk image ---
  yesterday's software library, a protected original, a disk-based
  application --- use a disk operating system for disks and NOS
  for the network:

  #item[Reboot into your FujiNet's CONFIG, mount the disk image,
    and boot it. Coming back to NOS is one more reboot.]
  #item[To move files between a diskette world and the network
    world, boot a classic DOS with the FujiNet #sf("N:") handler
    loaded (from #sf("n-handler.atr", size: 5.8pt)) --- there
    #sf("D:") and #sf("N:") exist side by side, and DOS's own
    copier moves files between them.]
  #item[Files on the FujiNet's SD card need no diskette at all:
    mount them directly with the #sf("SD://") protocol.]
], [
  #lsub[The Pleasant Surprises]

  The ledger runs the other way too. NOS never asks you to swap
  diskettes mid-copy. It never runs out of room at 707 sectors.
  Its menu is ten small sectors, not a whole DUP.SYS --- and
  MEM.SAV, that slow insurance policy, was never needed.
  Directories nest as deep as you please. Filenames breathe. And
  drive 2 can be in another country.

  #v(0.3in)
  #align(center,
    globe(0.85in, body-c: silver.darken(35%),
      line-c: silver.lighten(10%), depth: 0.07,
      patches: ()))
  #align(center, box(width: 1.9in,
    text(size: 7.6pt)[Formatting: the one chore the network never
      asks of you. A fresh mount arrives ready to use.]))
])

#pagebreak()

// ============================================================
// WHAT TO DO IF IT DOESN'T WORK  (silver, blue screens)
// ============================================================
#page(fill: none, background: { silver-bg; folio })[
  #secmark("What To Do If It Doesn't Work")
  #headband("What To Do If", "It Doesn't Work")

  #grid(columns: (1fr, 1fr, 1fr), column-gutter: 14pt, [
    In most cases, when something goes wrong, NOS prints a message
    or an error number. You haven't broken anything. The common
    ones and their cures are listed here.

    #screen(w: 2.25in)[
      #sf("BOOT ERROR", size: 5.2pt)\
      #sf("BOOT ERROR", size: 5.2pt)\
      #sf("BOOT ERROR", size: 5.2pt)
    ]

    #lsub[Boot Error]

    The computer can't find a bootable disk. Check that your
    FujiNet is on and connected, that #sf("NOS.ATR", size: 5.8pt)
    is mounted in #emph[disk slot 1,] and that the slot is set to
    boot.

    #screen(w: 2.25in)[
      #sf("N1:LOAD GAME.XEX", size: 5.2pt)\
      #sf("170", size: 5.2pt)\
      #sf("N1:", size: 5.2pt)#iv(sf(" ", size: 5.2pt))
    ]

    #lsub[Error 170: File Not Found]

    The old classic, and the case-sensitive network gives it new
    life. DIR first; match the name letter for letter. You'll
    also meet it when a bare word isn't a command: NOS tried to
    fetch #sf("WORD.COM") and found no such file.
    #sf("CMD?", size: 5.8pt) is its cousin --- NOS couldn't even
    parse the line.
  ], [
    #lsub[When NOS Asks a Question]

    A one-line answer like #sf("FILE?") or #sf("PATH?") or
    #sf("Nn?") isn't scolding --- it's the command reminding you
    what it needs: a filename, a path, a drive between 1 and 8.
    #sf("MODE? 0=NONE, 1=CR, 2=LF, 3=CR/LF", size: 4.9pt) is
    NTRANS showing its whole menu.

    #lsub[Error 138: Timeout]

    The computer called and nobody answered. The FujiNet is off,
    still starting up, or has lost the wireless network. Its
    status light tells the story.

    #lsub[Error 136: End of File]

    Usually honest --- the file simply ended --- but arriving
    unexpectedly it means #emph[the connection closed:] the
    server went away, or the mount was never made. NPWD the
    drive and look.

    #lsub[Error 146: Not Implemented]

    You asked a protocol for a trick it doesn't do --- renaming
    on GDRIVE, writing to a plain web server, MKDIR on a
    read-only guest login. The protocol table in "The Protocols"
    is the map of what works where.
  ], [
    #lsub[Error 144: The Server Said No]

    DOS veterans know 144 as "device done error"; on the network
    it means the server refused --- often a permissions problem,
    a read-only share, or a full disk on the far end. NOS asks
    the FujiNet for the specific reason and prints #emph[that]
    number when it has one, so you may see a code from the
    server's world instead.

    #lsub[Error 165: Bad Filename]

    The filespec itself is malformed --- a stray colon, a
    protocol misspelled, quotes forgotten around a name with
    spaces.

    #lsub[Still Stuck?]

    NOS's online help is one command away --- see the next page.
    The FujiNet community keeps a Discord where NOS's own authors
    answer questions, linked from #sf("fujinet.online", size: 5.8pt);
    and if you've found a genuine bug, the source listing in the
    back of this booklet is an invitation.
  ])
]

// ============================================================
// GETTING HELP  (silver)
// ============================================================
#page(fill: none, background: { silver-bg; folio })[
  #secmark("Getting Help")
  #headband("Getting", "Help", flush: right)

  #grid(columns: (1fr, 1fr, 1fr), column-gutter: 14pt, [
    NOS carries a reference library it doesn't have room to hold:
    the #strong[HELP] command fetches articles over the network,
    from the NOS project's own pages on GitHub, and shows them a
    screenful at a time like TYPE.

    #dialogue(
      ("you type", sf("HELP") + h(3pt) + key("return")))

    plain HELP lists the top-level topics. Ask for a topic to see
    what's inside it, and for #sf("TOPIC/ARTICLE") to read one:

    #dialogue(
      ("you type", sf("HELP NOS") + h(3pt) + key("return")),
      ("you type", sf("HELP NOS/MKDIR") + h(3pt) + key("return")),
      ("you type", sf("HELP REF/ATASCII") + h(3pt) + key("return")))

    Any key turns the page; #key("esc") closes the book. The
    next page of this booklet is the card catalog.
  ], [
    #lsub[What's On the Shelf]

    #{
      set text(size: 7.5pt)
      table(columns: (0.55in, 1fr), stroke: 0.6pt + ink,
        inset: (x: 5pt, y: 3.4pt),
        table.header(
          text(font: f-sans, size: 7pt, tracking: 0.4pt)[TOPIC],
          text(font: f-sans, size: 7pt, tracking: 0.4pt)[COVERS]),
        sf("NOS", size: 6pt), [every NOS command, one article
          each],
        sf("MAP", size: 6pt), [the ATARI memory map --- 1,082
          cards, label by label],
        sf("REF", size: 6pt), [reference tables: ATASCII, colors,
          key codes, error codes],
        sf("ASM", size: 6pt), [a 6502 assembly reference,
          instruction by instruction],
        sf("DEV", size: 6pt), [developer tools],
        sf("UTL", size: 6pt), [utilities])
    }

    A whole programmer's bookshelf --- more than 1,200 articles
    --- an arm's reach from the prompt, weighing nothing.
  ], [
    #lsub[The Fine Print]

    HELP needs the network, of course --- it reads its articles
    over drive #sf("N4:"), which is the main reason this booklet
    keeps advising you to leave drive 4 unmounted.

    If HELP answers with an HTTP error like 404, the topic path
    wasn't quite right: articles under a topic need the topic in
    front --- #sf("HELP NOS/MKDIR") finds what
    #sf("HELP MKDIR") cannot.

    #v(0.25in)
    #align(center, box(width: 2.1in, height: 1.5in, {
      place(dx: 0.2in, dy: 0.15in,
        glyph3d("?", 64pt, cubes-c.at(7), depth: 0.07))
      place(dx: 1.05in, dy: 0.3in,
        cubestream(unit: 1.1pt,
          ((0, 40, 7, 4, -15), (26, 26, 7, 0, 20), (52, 16, 7, 5, -5),
           (78, 10, 7, 9, 30))))
    }))
    #align(center, box(width: 1.9in,
      text(size: 7.6pt)[Ask the network; the network answers.]))
  ])
]

// ============================================================
// GETTING HELP, PAGE 2 — THE CARD CATALOG  (silver)
// ============================================================
#page(fill: none, background: { silver-bg; folio })[
  #contband

  #grid(columns: (1fr, 1fr, 1fr), column-gutter: 14pt, [
    #lsub[Where the Library Lives]

    Every article is a plain text file in the
    #sf("fujinet-nhandler", size: 5.8pt) repository on GitHub,
    under #sf("nos/HELP/", size: 5.8pt). HELP fetches them from
    GitHub's raw pages the moment you ask, so what you read at
    the prompt is exactly what the repository holds today. Fix a
    typo, write a missing article, and every NOS in the world
    gets the improvement.

    #lsub[The NOS Shelf]

    One card per command --- ask as
    #sf("HELP NOS/DIR", size: 5.8pt):

    #{
      set text(size: 7.2pt)
      table(columns: (0.62in, 1fr), stroke: 0.6pt + ink,
        inset: (x: 4.5pt, y: 3.4pt),
        [drives], sf("NCD NPWD Nn: NTRANS", size: 5.0pt),
        [files], sf("DIR MKDIR RMDIR COPY NCOPY DEL RENAME TYPE", size: 5.0pt),
        [programs], sf("CAR LOAD REENTER RUN SAVE", size: 5.0pt),
        [batch], sf("SUBMIT AUTORUN REM @SCREEN @NOSCREEN", size: 5.0pt),
        [odd jobs], sf("CLS PRINT BASIC DUMP FILL COLD WARM XEP HELP", size: 5.0pt))
    }
  ], [
    #lsub[The Programmer's Shelves]

    #strong[ASM] is a 6502 reference: summary cards for the
    instruction set, address modes, branching, loops, and
    arithmetic --- then one card per instruction, ADC through
    TYA.

    #dialogue(
      ("you type", sf("HELP ASM/INSTR", size: 5.8pt)),
      ("you type", sf("HELP ASM/LDA", size: 5.8pt)))

    #strong[MAP] is the whole ATARI memory map --- 1,082 cards
    set from the text of #emph[Mapping the ATARI] by Ian
    Chadwick. Browse it by letter, by label, or by address:

    #dialogue(
      ("you type", sf("HELP MAP/S", size: 5.8pt)),
      ("you type", sf("HELP MAP/SAVMSC", size: 5.8pt)),
      ("you type", sf("HELP MAP/0230", size: 5.8pt)))

    A letter card lists every label under that letter with its
    address; the label and address cards tell you what the
    location does --- the sort of question that once meant a
    book within arm's reach. Now the book #emph[is] the arm's
    reach.
  ], [
    #lsub[The Reference Shelf]

    #strong[REF] holds the tables taped inside every ATARI
    programmer's desk drawer: ATASCII codes, color values,
    keyboard codes, and the error numbers --- with one card per
    error:

    #dialogue(
      ("you type", sf("HELP REF/ATASCII", size: 5.8pt)),
      ("you type", sf("HELP REF/ERROR/144", size: 5.6pt)))

    #strong[DEV] covers development tools (the ATARI Assembler
    Editor, to start), and #strong[UTL] the utilities (the
    #sf("T:EDIT", size: 5.8pt) text editor).

    #lsub[One Unlisted Card]

    #sf("HELP BUGS", size: 5.8pt) is the project's standing
    confession: the known bugs, kept honestly, straight from
    the repository.

    #v(0.15in)
    #align(center, stack(spacing: 4.5pt,
      slab("NOS", cubes-c.at(0), w: 70pt),
      slab("ASM", cubes-c.at(7), w: 70pt),
      slab("MAP", cubes-c.at(4), w: 70pt),
      slab("REF", cubes-c.at(5), w: 70pt),
      slab("DEV", cubes-c.at(9), w: 70pt),
      slab("UTL", cubes-c.at(3), w: 70pt)))
    #v(4pt)
    #align(center, box(width: 2.0in,
      text(size: 7.6pt)[Six shelves, twelve hundred cards, and
        not one of them on your bookcase.]))
  ])
]

#pagebreak(weak: true)
// ============================================================
// COMMAND REFERENCE
// ============================================================
#secmark("Command Reference")
#headband("Command", "Reference")

#let refentry(name, syntax: (), aliases: (), menu: none, notes: (),
  body) = block(
  breakable: false, above: 0.9em, below: 0.4em, width: 100%, {
  line(length: 100%, stroke: 1.1pt + ink)
  v(2.5pt)
  grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
    text(font: f-head, weight: 700, size: 11.5pt, fill: toc-blue,
      tracking: 0.3pt, name),
    {
      let tags = ()
      if menu != none { tags.push("menu: " + menu) }
      if aliases.len() > 0 { tags.push("also: " + aliases.join(", ")) }
      if tags.len() > 0 {
        text(font: f-sans, size: 6.6pt, tracking: 0.4pt, fill: ink,
          upper(tags.join("    ")))
      }
    })
  v(1.5pt)
  for s in syntax {
    block(above: 2.5pt, below: 2.5pt, width: 100%,
      rect(fill: cream.darken(7%), width: 100%,
        inset: (x: 5pt, y: 3.6pt),
        sf(s, size: 5.9pt)))
  }
  v(1pt)
  {
    set text(size: 7.8pt)
    set par(leading: 0.45em, spacing: 0.5em)
    body
    for n in notes {
      block(above: 0.35em, below: 0.2em,
        grid(columns: (0.12in, 1fr), column-gutter: 2pt,
          move(dy: 1.4pt, square(size: 3.6pt, fill: ink)),
          par(leading: 0.4em, first-line-indent: 0pt,
            text(size: 7.4pt, n))))
    }
  }
})

Every command NOS understands, in alphabetical order. Square
brackets mark optional parts; #sf("Nn:", size: 5.9pt) means any
drive name #sf("N1:", size: 5.9pt) through #sf("N8:", size: 5.9pt)
(when omitted, the current drive is used). Commands may be typed in
either case. A letter at an entry's top right names its item on
the NOS menu.

#v(0.4em)
#columns(2, gutter: 20pt)[

#refentry("@NOSCREEN", syntax: ("@NOSCREEN",))[
  Stops the echo of batch-file commands to the screen (the quiet
  state a batch file starts in). Counterpart of \@SCREEN.
]

#refentry("@SCREEN", syntax: ("@SCREEN",))[
  Starts echoing each batch-file command to the screen as it runs.
  Lines beginning with #sf("@", size: 5.9pt) are never echoed.
  Example: put #sf("@SCREEN", size: 5.9pt) at the top of a batch
  file to watch it work.
]

#refentry("AUTORUN",
  syntax: ("AUTORUN PROTO://HOST[:PORT]/[PATH/]FILE",
           "AUTORUN ?", "AUTORUN \"\""),
  notes: (
    [The URL must be complete --- nothing is mounted yet at boot.],
    [Stored as FujiNet AppKey db79/00/00: file
     #sf("/FujiNet/db790000.key", size: 5.4pt) on the FujiNet's
     (FAT32) SD card; 64 characters most.],
    [Hold #key("option") during boot to skip the AUTORUN.]))[
  Names a batch file to SUBMIT automatically at every cold start.
  #sf("?", size: 5.9pt) shows the current setting;
  #sf("\"\"", size: 5.9pt) clears it. Example:
  #sf("AUTORUN TNFS://192.168.1.20/SETUP.BAT", size: 5.2pt)
]

#refentry("BASIC", aliases: ("ROM",), menu: "H",
  syntax: ("BASIC ON|OFF", "ROM ON|OFF"),
  notes: (
    [XL/XE machines with built-in BASIC only ---
     otherwise #sf("NO BUILT-IN BASIC", size: 5.4pt).],
    [Performs a warmstart to settle the change.],
    [While ROM is switched in, NOS keeps the screen border gray
     as a reminder.]))[
  Switches the ROM at \$A000--\$BFFF (usually built-in BASIC) in
  or out of the memory map, without rebooting while holding
  #key("option"). #sf("BASIC ON", size: 5.9pt) when ROM is
  already in behaves like CAR.
]

#refentry("CAR", menu: "B", syntax: ("CAR",),
  notes: ([#sf("NO CARTRIDGE", size: 5.4pt) means nothing is
    there to run --- no cartridge, and built-in BASIC switched
    out.],))[
  Leaves NOS for the cartridge (or built-in BASIC) through its
  warmstart vector --- memory is preserved in both directions, so
  a BASIC listing survives the round trip. Type
  #sf("DOS", size: 5.9pt) there to come back.
]

#refentry("CLS", syntax: ("CLS",))[
  Clears the screen.
]

#refentry("COLD", syntax: ("COLD",))[
  Reboots the computer (coldstart). On XL/XE machines, hold
  #key("option") as it restarts to keep BASIC out.
]

#refentry("DEL", aliases: ("ERASE", "ERA"), menu: "D",
  syntax: ("DEL [Nn:][PATH/]FILE", "DEL [Nn:][PATH/]PATTERN"),
  notes: (
    [A plain name deletes immediately --- no confirmation, no
     undelete.],
    [A pattern (#sf("*", size: 5.9pt), #sf("?", size: 5.9pt))
     offers each matched file with #sf("(Y/N)?", size: 5.4pt) ---
     only Y deletes; matched names fill a 512-byte list per run.],
    [Names are case-sensitive; quote names with spaces:
     #sf("DEL \"N2:My File.AWP\"", size: 5.4pt)]))[
  Removes one file, or --- with a wild card --- a confirmed crowd
  of them, from a mounted drive. Examples:
  #sf("DEL N2:DOCS/OLDFILE.TXT", size: 5.6pt)
  #sf("DEL *.BAK", size: 5.6pt)
]

#refentry("DIR", menu: "A", syntax: ("DIR [Nn:][PATH/][PATTERN]",),
  notes: (
    [#sf("*", size: 5.9pt) matches any run of characters,
     #sf("?", size: 5.9pt) exactly one.],
    [Directories are always listed, whatever the pattern.],
    [Hold #key("space") to pause; #key("esc") stops the
     listing.]))[
  Lists files at the current spot (or the given path) with sizes
  --- bytes, #sf("K", size: 5.9pt), or #sf("M", size: 5.9pt) ---
  and folders marked with a trailing #sf("/", size: 5.9pt).
  Examples: #sf("DIR", size: 5.6pt) #sf("DIR N2:*.XEX", size: 5.6pt)
  #sf("DIR GAMES/", size: 5.6pt)
]

#refentry("DUMP", syntax: ("DUMP START [END]",),
  notes: ([Addresses are four hex digits, no dollar sign; lead
    small ones with zeros.], [#key("esc") stops a long dump.]))[
  Shows memory in hex, eight bytes per line, from START to END
  (or one line's worth if END is omitted). Example:
  #sf("DUMP 0600 067F", size: 5.6pt)
]

#refentry("FILL", syntax: ("FILL START END XX",))[
  Fills memory from START through END with the byte XX (two hex
  digits). Example: #sf("FILL 5000 5FFF 00", size: 5.6pt) clears
  a 4K block.
]

#refentry("HELP", syntax: ("HELP [TOPIC[/ARTICLE]]",),
  notes: (
    [Articles arrive over drive #sf("N4:", size: 5.9pt) from the
     NOS project's GitHub pages; a mount on drive 4 can confuse
     it.],
    [Articles under a topic need the topic in the path:
     #sf("HELP NOS/MKDIR", size: 5.4pt), not
     #sf("HELP MKDIR", size: 5.4pt).]))[
  The online manual. Plain HELP lists topics (NOS, MAP, REF, ASM,
  DEV, UTL); a topic lists its articles; topic/article shows the
  text, paged like TYPE.
]

#refentry("LOAD", aliases: ("X",), menu: "L",
  syntax: ("LOAD [Nn:][PATH/]FILE", "FILENAME"),
  notes: (
    [A bare unrecognized word is treated as
     #sf("LOAD WORD.COM", size: 5.4pt) from the current drive.],
    [Line-ending translation is switched off automatically for
     the load.],
    [A non-binary file stops with
     #sf("NOT A BINARY FILE", size: 5.4pt).]))[
  Loads a standard ATARI binary file (#sf(".XEX", size: 5.9pt),
  #sf(".COM", size: 5.9pt)) and runs it, honoring the file's init
  and run addresses. Example:
  #sf("LOAD N2:GAMES/JUMPMAN.XEX", size: 5.4pt)
]

#refentry("MENU", syntax: ("MENU",),
  notes: ([The menu module is reloaded from the NOS disk image
    each time it draws --- one more reason NOS.ATR stays
    mounted.],))[
  Returns from the command line to the NOS menu --- the reverse
  of menu item P.
]

#refentry("MKDIR", menu: "F",
  syntax: ("MKDIR [Nn:][PATH/]DIRNAME",))[
  Creates a directory on a mounted drive, where the protocol
  allows it. Example: #sf("MKDIR PROJECTS", size: 5.6pt)
]

#refentry("NCD", aliases: ("CD", "CWD"), menu: "I",
  syntax: ("NCD [Nn:]PROTO://HOST[:PORT]/[PATH/]",
           "NCD PATH | NCD ..", "NCD Nn:"),
  notes: (
    [A trailing #sf("/", size: 5.9pt) is added if missing; quote
     paths containing spaces.],
    [No check is made that the new path exists --- DIR after
     moving.],
    [Mounts live in the FujiNet and are shared with running
     programs; move drives thoughtfully.]))[
  The mount command. With a full URL, connects a drive to a
  server; with a bare path (or #sf("..", size: 5.9pt)), moves
  around inside the mount; with a bare drive name, disconnects
  that drive.
]

#refentry("NCOPY", aliases: ("COPY",), menu: "C",
  syntax: ("NCOPY [Nn:][PATH/]FILE[,[Nn:][PATH/]FILE][,A]",
           "NCOPY PATTERN,DEST | NCOPY FILE,P:"),
  notes: (
    [With no destination, copies onto the #emph[current] drive,
     keeping the name. Copying a file onto itself is refused
     (#sf("SAME FILE?", size: 5.4pt)).],
    [A source pattern (#sf("*", size: 5.9pt),
     #sf("?", size: 5.9pt)) copies every match, echoing each
     name --- no confirmation; matched names fill a 512-byte
     list per run.],
    [#sf(",A", size: 5.9pt) appends to the destination instead
     of replacing it.],
    [A destination of #sf("Nn:", size: 5.9pt) alone, or ending
     in #sf("/", size: 5.9pt), keeps the source's filename.
     Destinations #sf("P:", size: 5.9pt) (printer) and
     #sf("E:", size: 5.9pt) (screen) also work.],
    [Active NTRANS translation alters what is copied --- set
     mode 0 for binaries. Network destinations are built over
     drive #sf("N4:", size: 5.9pt).]))[
  Copies a file --- or a wild-card crowd of them --- within a
  drive, between drives (even between different servers), or to
  a device.
]

#refentry("Nn:", menu: "N", syntax: ("Nn:",))[
  Typed alone, makes drive #emph[n] (1--8) the current drive; the
  prompt follows. No check is made that the drive is mounted.
  Example: #sf("N3:", size: 5.6pt)
]

#refentry("NPWD", aliases: ("PWD",), menu: "J",
  syntax: ("NPWD [Nn:]",))[
  Shows where a drive is mounted --- the full URL, protocol and
  all. A blank answer means nothing is mounted there.
]

#refentry("NTRANS", syntax: ("NTRANS [Nn:] MODE",),
  notes: (
    [Modes: 0 none, 1 CR, 2 LF, 3 CR/LF --- each swapped with
     ATARI EOL (155) as bytes flow.],
    [Text only! Translation corrupts binaries. LOAD disables it
     for itself; NCOPY does not.]))[
  Sets a drive's line-ending translation for text exchanged with
  other kinds of computer. Example:
  #sf("NTRANS N1: 2", size: 5.6pt) for a Unix-flavored server.
]

#refentry("PASS", syntax: ("PASS PASSWORD",))[
  Supplies the password half of the credentials used for
  protocols that want a login (SMB shares, for instance). Give
  USER and PASS #emph[before] the NCD that mounts.
]

#refentry("PRINT", syntax: ("PRINT \"STRING\"",))[
  Shows a message on the screen --- a batch file's voice.
  Example: #sf("PRINT \"DRIVES READY\"", size: 5.6pt)
]

#refentry("REENTER", aliases: ("REE",), syntax: ("REENTER",),
  notes: ([Whether the program survives re-entry is up to the
    program --- save work before quitting to NOS.],))[
  Jumps back into the last loaded program through its run (or
  init) address. #sf("NO ADDR IN INITAD OR RUNAD", size: 5.2pt)
  means there's nothing to return to.
]

#refentry("REM", aliases: ("'", "#"),
  syntax: ("REM COMMENT",))[
  A comment --- NOS ignores the line. For batch files.
]

#refentry("RENAME", aliases: ("REN",), menu: "E",
  syntax: ("RENAME [Nn:][PATH/]OLDNAME,NEWNAME",),
  notes: (
    [Give NEWNAME bare --- no drive or path in the second half.],
    [One file at a time --- wild cards don't reach RENAME.],
    [Known rough edge: renaming through a relative path misfires
     in this version; NCD to the file's directory first.]))[
  Gives a file (or directory) a new name on the same mount.
  Example:
  #sf("RENAME AtariWriter.xex,ATARIWRITER.COM", size: 4.7pt)
]

#refentry("RMDIR", menu: "G",
  syntax: ("RMDIR [Nn:][PATH/]DIRNAME",))[
  Removes an #emph[empty] directory, where the protocol allows.
]

#refentry("RUN", menu: "M", syntax: ("RUN ADDR",))[
  Calls machine code at a hex address (four digits, no dollar
  sign --- #sf("RUN 0600", size: 5.6pt), not
  #sf("RUN $600", size: 5.6pt)).
]

#refentry("SAVE", menu: "K",
  syntax: ("SAVE [Nn:]FILE,START,END[,INIT][,RUN]",),
  notes: (
    [All addresses four hex digits. END is inclusive.],
    [Skip INIT but give RUN with a double comma:
     #sf("SAVE PROG,2000,2FFF,,2000", size: 5.2pt)]))[
  Writes a memory range as a standard ATARI binary file, with
  optional init and run addresses for LOAD to honor later.
  Example: #sf("SAVE N1:FONT.BIN,3800,3BFF", size: 5.2pt)
]

#refentry("SUBMIT", aliases: ("@",),
  syntax: ("SUBMIT [Nn:][PATH/]FILE",),
  notes: (
    [Accepts ATARI, Unix (LF), and Windows (CR/LF) line endings
     as they come.],
    [Runs quietly unless the file says
     #sf("@SCREEN", size: 5.4pt).]))[
  Runs the NOS commands in a text file, line by line, as if
  typed. Example: #sf("@ SETUP.BAT", size: 5.6pt)
]

#refentry("TYPE", menu: "O", syntax: ("TYPE [Nn:][PATH/]FILE",),
  notes: (
    [Any key shows the next screenful; #key("esc") stops.],
    [Text only --- a large binary can overrun the buffer and
     corrupt memory.]))[
  Shows a text file on the screen, a page at a time, coping with
  CR/LF along the way. Works on anything the drive can read ---
  including a web page by URL.
]

#refentry("USER", syntax: ("USER NAME",))[
  Supplies the username half of the credentials for protocols
  that want a login. Pair with PASS, before the mount.
]

#refentry("WARM", syntax: ("WARM",))[
  Warmstarts the computer (like pressing #key("reset")).
]

#refentry("XEP", syntax: ("XEP [40]",),
  notes: ([Load the XEP80 handler first (for instance
    #sf("LOAD XEP80HAN.COM", size: 5.4pt)); use only with an
    XEP80 connected.],))[
  For the XEP80 80-column peripheral: #sf("XEP", size: 5.9pt)
  switches to the 80-column screen, #sf("XEP 40", size: 5.9pt)
  back to the normal one.
]

]

#pagebreak()

// ============================================================
// INSIDE NOS  (cream, 2 pages) — memory map, overlays, disk
// layout, writing your own overlay, the burst engine.
// Addresses verified against the MADS label table for v1.0.0.
// ============================================================
#secmark("Inside NOS")
#headband("Inside", "NOS")

#let code(..lines) = block(above: 3pt, below: 5pt, width: 100%,
  rect(fill: cream.darken(7%), width: 100%, inset: (x: 6pt, y: 4.5pt), {
    set text(font: f-mono, size: 6.0pt, fill: ink)
    set par(leading: 2.7pt, spacing: 2.7pt, first-line-indent: 0pt)
    set smartquote(enabled: false)
    for l in lines.pos() { par(l) }
  }))

#grid(columns: (1fr, 3.15in), column-gutter: 18pt, [
  This chapter is for the reader who wants to know how the watch
  ticks --- and for the one who wants to add a gear. Everything
  here can be checked against the source listing that follows.

  #lsub[The Shape of Memory]

  At boot, NOS hooks the system's DOS vectors (DOSVEC and DOSINI,
  at \$0A and \$0C), installs its #sf("N:") handler --- answering
  for #sf("D:") as well --- and raises MEMLO to \$1B00. That is
  the whole resident cost: #emph[five kilobytes even,] from
  \$0700 through \$1AFF, less than DOS 2.0 asked with its default
  buffers. Everything from \$1B00 up belongs to you.

  The top of the resident block is working space. At \$1900 sits
  #strong[OVLBUF], a 256-byte window --- two disk sectors' worth
  --- where overlay commands are brought in to run. Above it,
  two 128-byte buffers (#sf("RBUF"), #sf("TBUF")) smooth network
  reads and writes, and the command line itself lives down in
  page 5, at \$0582.

  Three tenants #emph[borrow] your memory briefly, and only while
  their features are on duty. The menu is ten sectors read into
  \$2600 each time it draws. The wild-card machinery keeps its
  scratch at \$4000 and its code at \$4300 while a pattern is
  being worked through. And NCOPY stages its 8K bursts in the
  free RAM just above MEMLO. None of them leave anything resident
  behind.

  #lsub[The Overlay Game]

  A command set this size won't fit in five kilobytes, and NOS
  solves it the way DOS always did: keep the everyday machinery
  resident and leave the rest on the disk. Two dozen commands run
  straight from the kernel. The bigger ones --- AUTORUN, BASIC,
  DIR, DUMP, FILL, HELP, NCOPY, NTRANS, REENTER, SAVE, XEP, and
  DEL's wild-card scanner --- live on #sf("NOS.ATR") as
  #emph[overlays,] one or two sectors each.

  Calling one is plain arithmetic. Because the whole OS is
  assembled as one image whose ATR begins at \$0700, a routine's
  assembled address #emph[is] its place on the disk:

  #code(
    "sector = address / 128 - 13",
    ";  $0700/$80 - $0D = sector 1  (boot)",
    ";  $2080/$80 - $0D = sector 52 (NCOPY)")

  The resident dispatcher (#sf("DO_OVERLAY", size: 5.8pt)) looks
  up that sector in a table, reads the overlay into OVLBUF, and
  jumps to it --- remembering what it loaded, so running DIR
  twice reads the disk once. An overlay executes at \$1900 though
  it was assembled at its disk address, so its branches are
  relative and any absolute self-reference is spelled with one
  idiom: #sf("OVLBUF-OVL_FOO+label", size: 5.6pt). A command too
  big for the window chains: NCOPY is three overlays that hand
  the copy from parser to opener to mover.

  The menu and the wild-card engine are the second pattern:
  #emph[transient modules,] assembled at their own run addresses
  (\$2600 and \$4300), loaded above MEMLO on demand, and expected
  to be stepped on --- which is why menu picks are dispatched
  from resident trampolines that reload the module afterward.
], [
  #box(width: 3.15in, height: 6.35in, {
    // extrusion shadow for the whole tower
    place(dx: 0.66in, dy: 0.07in,
      rect(width: 1.85in, height: 5.70in, fill: black))
    // ---- bands, high addresses at the top ----
    // cartridge / BASIC ROM
    place(dx: 0.60in, dy: 0.00in, rect(width: 1.85in, height: 0.40in,
      fill: tan, stroke: 1.0pt + black))
    place(dx: 0.60in, dy: 0.00in, box(width: 1.85in, height: 0.40in,
      align(center + horizon, text(font: f-scrn, size: 5.4pt, fill: ink,
        "CARTRIDGE / BASIC ROM"))))
    // free RAM
    place(dx: 0.60in, dy: 0.40in, rect(width: 1.85in, height: 2.60in,
      fill: cream.darken(3%), stroke: 1.0pt + black))
    place(dx: 0.60in, dy: 2.70in, box(width: 1.85in,
      align(center, text(font: f-scrn, size: 5.4pt, fill: ink,
        "FREE RAM: YOURS"))))
    // tenants (addresses written on the slabs, clear of the shadow)
    place(dx: 0.82in, dy: 0.60in, rect(width: 1.41in, height: 0.26in,
      fill: cubes-c.at(9), stroke: 0.9pt + black))
    place(dx: 0.82in, dy: 0.60in, box(width: 1.41in, height: 0.26in,
      align(center + horizon, text(font: f-scrn, size: 4.9pt, fill: white,
        "WILD MODULE 4300"))))
    place(dx: 0.82in, dy: 0.90in, rect(width: 1.41in, height: 0.26in,
      fill: cubes-c.at(4), stroke: 0.9pt + black))
    place(dx: 0.82in, dy: 0.90in, box(width: 1.41in, height: 0.26in,
      align(center + horizon, text(font: f-scrn, size: 4.9pt, fill: ink,
        "WILD SCRATCH 4000"))))
    place(dx: 0.82in, dy: 1.78in, rect(width: 1.41in, height: 0.36in,
      fill: cubes-c.at(7), stroke: 0.9pt + black))
    place(dx: 0.82in, dy: 1.78in, box(width: 1.41in, height: 0.36in,
      align(center + horizon, text(font: f-scrn, size: 4.9pt, fill: white,
        "MENU MODULE 2600"))))
    // burst-buffer extent bracket ($1B00..$3AFF), clear of the shadow
    place(dx: 2.62in, dy: 1.20in, line(angle: 90deg, length: 1.80in,
      stroke: 1.2pt + ink))
    place(dx: 2.57in, dy: 1.20in, line(length: 0.05in, stroke: 1.2pt + ink))
    place(dx: 2.57in, dy: 3.00in, line(length: 0.05in, stroke: 1.2pt + ink))
    // label rotated about its top-left, centered on the bracket
    place(dx: 2.76in, dy: 1.73in, rotate(90deg, origin: top + left,
      reflow: false,
      text(font: f-scrn, size: 4.9pt, fill: ink, "NCOPY 8K BURST")))
    // RBUF / TBUF
    place(dx: 0.60in, dy: 3.00in, rect(width: 1.85in, height: 0.26in,
      fill: silver, stroke: 1.0pt + black))
    place(dx: 0.60in, dy: 3.00in, box(width: 1.85in, height: 0.26in,
      align(center + horizon, text(font: f-scrn, size: 5.0pt, fill: ink,
        "RBUF / TBUF"))))
    // OVLBUF
    place(dx: 0.60in, dy: 3.26in, rect(width: 1.85in, height: 0.38in,
      fill: cubes-c.at(0), stroke: 1.0pt + black))
    place(dx: 0.60in, dy: 3.26in, box(width: 1.85in, height: 0.38in,
      align(center + horizon, text(font: f-scrn, size: 5.0pt, fill: white,
        "OVLBUF: OVERLAY WINDOW"))))
    // resident kernel
    place(dx: 0.60in, dy: 3.64in, rect(width: 1.85in, height: 1.60in,
      fill: navy, stroke: 1.0pt + black))
    place(dx: 0.60in, dy: 3.64in, box(width: 1.85in, height: 1.60in,
      align(center + horizon, {
        set par(leading: 4pt)
        set text(font: f-scrn, size: 5.4pt, fill: scr-fg)
        par("RESIDENT NOS")
        par("N: HANDLER - CIO - SIO")
        par("PARSER - RESIDENT CMDS")
        par("MENU TRAMPOLINES")
      })))
    // OS pages
    place(dx: 0.60in, dy: 5.24in, rect(width: 1.85in, height: 0.46in,
      fill: silver, stroke: 1.0pt + black))
    place(dx: 0.60in, dy: 5.24in, box(width: 1.85in, height: 0.46in,
      align(center + horizon, text(font: f-scrn, size: 5.0pt, fill: ink,
        "OS PAGES - LNBUF AT 0582"))))
    // ---- address gutter ----
    place(dx: 0.06in, dy: -0.02in, text(font: f-scrn, size: 5.2pt,
      fill: ink, "A000"))
    place(dx: 0.06in, dy: 2.90in, text(font: f-scrn, size: 5.2pt,
      fill: ink, "1B00"))
    place(dx: 0.02in, dy: 3.00in, text(font: f-sans, size: 4.6pt,
      fill: toc-blue, "MEMLO"))
    place(dx: 0.06in, dy: 3.24in, text(font: f-scrn, size: 5.2pt,
      fill: ink, "1900"))
    place(dx: 0.06in, dy: 3.62in, text(font: f-scrn, size: 5.2pt,
      fill: ink, "0700"))
    place(dx: 0.06in, dy: 5.64in, text(font: f-scrn, size: 5.2pt,
      fill: ink, "0000"))
  })
  #align(center, box(width: 2.9in,
    text(size: 7.6pt)[The lay of memory under NOS 1.0 --- resident
      kernel below MEMLO at \$1B00, and three well-mannered
      tenants that borrow the free RAM only while they work.
      (Heights not to scale.)]))
])

#pagebreak()
#contband

#lsub[The Disk They Ride On]

#box(width: 7.1in, height: 1.42in, {
  // expanded strip: sectors 1..80 at 0.068in per sector
  let sx(s) = 0.15in + (s - 1) * 0.068in
  let seg(s0, s1, c) = place(dx: sx(s0), dy: 0.32in,
    rect(width: (s1 - s0 + 1) * 0.068in, height: 0.5in, fill: c,
      stroke: 0.9pt + black))
  seg(1, 36, navy)
  seg(37, 40, silver)
  seg(41, 62, cubes-c.at(0))
  seg(63, 72, cubes-c.at(7))
  seg(73, 78, cubes-c.at(9))
  seg(79, 80, cream.darken(3%))
  // break marks, then the directory tail
  place(dx: 5.72in, dy: 0.30in, text(font: f-head, size: 10pt, "/\u{200b}/"))
  place(dx: 5.95in, dy: 0.32in, rect(width: 0.22in, height: 0.5in,
    fill: cream.darken(3%), stroke: 0.9pt + black))
  place(dx: 6.17in, dy: 0.32in, rect(width: 0.10in, height: 0.5in,
    fill: cubes-c.at(4), stroke: 0.9pt + black))
  place(dx: 6.27in, dy: 0.32in, rect(width: 0.42in, height: 0.5in,
    fill: cubes-c.at(3), stroke: 0.9pt + black))
  place(dx: 6.69in, dy: 0.32in, rect(width: 0.26in, height: 0.5in,
    fill: cream.darken(3%), stroke: 0.9pt + black))
  // sector numbers above
  let num(s, label) = place(dx: sx(s) - 0.02in, dy: 0.16in,
    text(font: f-scrn, size: 4.8pt, fill: ink, label))
  num(1, "1")
  num(37, "37")
  num(41, "41")
  num(63, "63")
  num(73, "73")
  place(dx: 6.17in, dy: 0.16in, text(font: f-scrn, size: 4.8pt,
    fill: ink, "360"))
  place(dx: 6.90in, dy: 0.16in, text(font: f-scrn, size: 4.8pt,
    fill: ink, "720"))
  // labels below
  let lab(x, t) = place(dx: x, dy: 0.90in,
    text(font: f-sans, size: 5.0pt, tracking: 0.3pt, fill: ink, upper(t)))
  lab(0.65in, "boot + resident kernel")
  lab(2.60in, "buffers")
  lab(3.30in, "overlays")
  lab(4.42in, "menu")
  lab(5.05in, "wild")
  lab(6.05in, "vtoc + directory")
  // leader ticks
  place(dx: 2.72in, dy: 0.82in, line(angle: 90deg, length: 0.07in,
    stroke: 0.7pt + ink))
  place(dx: 5.15in, dy: 0.82in, line(angle: 90deg, length: 0.07in,
    stroke: 0.7pt + ink))
})

#v(2pt)
#grid(columns: (1fr, 1fr), column-gutter: 20pt, [
  #sf("NOS.ATR") is one long act of arithmetic. Sectors 1--36
  boot and hold the resident kernel; 37--40 are the images of
  its buffers; 41--62 carry the command overlays, one or two
  sectors apiece, each at the address the formula predicts;
  63--72 are the menu module and 73--78 the wild-card module.
  Way out at sector 360 sits a #emph[fake] VTOC, with a
  hand-built directory in 361--368 whose entry names spell out
  the OS's own name --- so that disk tools examining the image
  see a healthy single-density diskette instead of fainting.
  Nothing else on the disk is real: there is no File Management
  System in NOS, not even for its own disk.

  #lsub[The Burst Engine]

  Ordinarily the #sf("N:") handler hands bytes through a
  128-byte buffer, the classic way. But on a #emph[binary] read
  of 128 bytes or more, with data waiting, NOS skips the bucket
  brigade: one SIO frame carries
  #emph[min(bytes waiting, buffer, 8K)] straight into the
  caller's memory --- the exact count requested, nothing copied
  twice. Writes mirror it. The last byte of each burst rides
  through CIO so the bookkeeping stays honest, and the status
  poll keeps the true byte count on the side while the classic
  path still sees the old 127-byte ceiling. This is what makes
  NCOPY and LOAD feel like a disk that spins at wireless speed.
], [
  #lsub[Rolling Your Own Overlay]

  To add a command #sf("FOO"), you touch four tables and write
  one body --- the sectors take care of themselves.

  #code(
    "; 1. name it: CMD_IDX enum + keyword table",
    "        FOO             ; in .ENUM CMD_IDX",
    "        .CB \"FOO\"        ; keyword",
    "        .BYTE CMD_IDX.FOO",
    "; and CMD_TAB_L/H entries -> DO_FOO-1")

  #code(
    "; 2. a resident stub",
    "DO_FOO: LDX #OVL_IDX.FOO",
    "        JMP DO_OVERLAY")

  #code(
    "; 3. overlay tables: where + how many",
    " .BYTE <(OVL_FOO/SECTOR_SIZE-$0D)",
    " .BYTE [END_OVL_FOO-OVL_FOO]/SECTOR_SIZE")

  #code(
    "; 4. the body, sector-aligned",
    "OVL_FOO:",
    "        ; runs at OVLBUF ($1900)!",
    "        ; branches: relative only",
    "        ; absolute self-references:",
    "        ;   OVLBUF-OVL_FOO+label",
    "        .ALIGN SECTOR_SIZE,$00",
    "END_OVL_FOO:")

  Arguments arrive pre-chewed: #sf("CMDSEP", size: 5.8pt) holds
  offsets into the line buffer for each argument, commas already
  split. The kernel lends its tools ---
  #sf("PREPEND_DRIVE", size: 5.6pt) to default the drive,
  #sf("DOSIOV", size: 5.6pt) to talk SIO,
  #sf("CIOOPEN", size: 5.6pt)/#sf("CIOGET", size: 5.6pt)/#sf("CIOPUT", size: 5.6pt)/#sf("CIOCLOSE", size: 5.6pt)
  for files, #sf("PRINT_STRING", size: 5.6pt) and
  #sf("PRINT_ERROR", size: 5.6pt) to speak. Outgrow two sectors
  and you chain, as NCOPY does. Then:

  #code(
    "$ make",
    "; MADS reassembles NOS.ATR; every",
    "; sector number recomputes itself.")

  Patches are welcome --- the source, like the HELP library,
  lives in #sf("fujinet-nhandler", size: 5.8pt) on GitHub.
])

#pagebreak()

// ============================================================
// APPENDIX: THE NOS SOURCE LISTING
// ============================================================
#secmark("Appendix: The NOS Source Listing")
#headband("Appendix: The NOS", "Source Listing")

For the advanced user, the curious, and the future contributor:
the complete assembly source of NOS v1.0.0, #sf("nos.s", size: 6pt),
exactly as it builds into #sf("NOS.ATR", size: 6pt). It assembles
with MADS, and lives --- with its HELP articles, tools, and
history --- in the #sf("fujinet-nhandler", size: 6pt) repository
on GitHub under #sf("nos/", size: 6pt). Patches are welcome; so
are readers --- and the chapter "Inside NOS" is the map to carry
into these woods. The resident kernel (boot, the
#sf("N:", size: 6pt) handler, the command processor) comes first;
the overlay commands follow, each aligned to the sector it
occupies on the disk; the menu and wild-card modules and the fake
directory bring up the rear.

#v(0.5em)
#{
  set text(font: f-mono, size: 4.55pt, fill: ink)
  set par(leading: 1.9pt, spacing: 1.9pt, first-line-indent: 0pt)
  set smartquote(enabled: false)
  columns(2, gutter: 16pt,
    read("listings/nos.s").split("\n").map(l =>
      par(l.replace("\t", "        "))).join())
}

#pagebreak(weak: true)

// ============================================================
// BACK MATTER
// ============================================================
#page(margin: 0pt, fill: navy, background: none)[]

#page(margin: 0pt, fill: none, background: {
  rect(width: 100%, height: 100%, fill: silver)
  for i in range(64) {
    place(top + left, dy: 0.1in + i * 0.17in,
      line(length: 100%, stroke: 0.55pt + silver-line))
  }
})[
  #place(bottom + left, dx: 0.55in, dy: -1.3in, box(width: 2.6in, {
    set text(size: 6.8pt, fill: ink)
    set par(leading: 0.45em, spacing: 0.55em)
    par[Every effort has been made to ensure the accuracy of the
      product documentation in this booklet. However, because the
      FujiNet community is constantly improving and updating its
      software, we are unable to guarantee the accuracy of printed
      material after the date of publication and disclaim liability
      for changes, errors, or omissions.]
    par[NOS is free software; its source code appears in this very
      booklet. FujiNet is a worldwide community project, not
      affiliated with Atari. ATARI#rg and the names of ATARI
      peripherals are trademarks of their respective owners, used
      in loving tribute.]
    v(4pt)
    par[#text(font: f-mono, size: 6.2pt)[fujinet.online]]
  }))
  #place(bottom + center, dy: -0.45in, {
    box(text(font: f-mark, weight: 900, size: 30pt, tracking: 1pt,
      fill: gradient.linear(dir: ttb,
        rgb("#7b3fa0"), rgb("#3b55b5"), rgb("#2e8eb0"),
        rgb("#36a37e"), rgb("#58b758")).repeat(1),
      top-edge: "bounds", bottom-edge: "bounds")[FUJINET])
    v(-8pt)
    text(font: f-sans, weight: 400, size: 6.8pt, tracking: 3.4pt,
      fill: ink)[NETWORK  OPERATING  SYSTEM]
  })
]

