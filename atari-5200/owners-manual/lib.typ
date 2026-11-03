// lib.typ -- helpers for the FujiNet Atari 5200 Owner's Manual.
//
// House style: the 1982 ATARI 5200 Owner's Manual, as the Programmer's
// Handbook already sets it -- a small booklet on warm paper ruled with a
// faint graph grid, Helvetica throughout, numbered heads in blue-violet hung
// to the left of the text, pictures in white panels on a lilac band (line
// art straight on the lilac), bold step numerals, black key labels lettered
// in the colour of the controller's keys, and a Troubleshooting Checklist of
// Symptom / Probable Cause and Remedy between rules. Ragged right
// throughout. The owner's pieces (controls charts, leader-line labels, the
// stick arrows) come from the 2600 Owner's Manual.

// ---------- fonts ---------------------------------------------------
#let f-body = "Helvetica"
#let f-head = "Helvetica"
#let f-mono = "Source Code Pro"
#let f-wm   = "ITC Avant Garde Gothic"   // the round-zero 5200

// ---------- palette (sampled from the 1982 booklet) -----------------
#let ink     = rgb("#1b1a1f")
#let paper   = rgb("#f5eeec")
#let grid-c  = rgb("#e3d6d5")          // the graph paper
#let violet  = rgb("#5a5694")          // the heads
#let lilac   = rgb("#d6c4d5")          // the band behind pictures
#let lilac-d = rgb("#c6b3cb")
#let gray    = rgb("#6c6772")
#let panel   = rgb("#fcfaf9")          // pictures sit on white
#let panel-b = rgb("#d9ccd2")
#let cover-k = rgb("#0f0f14")          // the cover's black
// the controller's key colours, as the booklet letters them
#let k-green  = rgb("#43c063")
#let k-yellow = rgb("#f2c522")
#let k-red    = rgb("#ee5040")
#let k-fire   = rgb("#e8663f")          // the red-orange side buttons
#let k-gold   = rgb("#e9c46a")          // the keypad's numerals

#let frontmatter = state("fm", true)
#let run-on = state("runon", false)

// ---------- the page ------------------------------------------------
#let grid-pitch = 0.26in                  // 155 px at 600 dpi in the scan
#let hang = 0.2in                         // heads hang left of the text
#let m-left = 0.52in
#let m-right = 0.38in
#let graph(c: grid-c, w: 0.55pt, p: grid-pitch) = tiling(size: (p, p), {
  place(top + left, line(start: (0pt, 0pt), end: (p, 0pt), stroke: w + c))
  place(top + left, line(start: (0pt, 0pt), end: (0pt, p), stroke: w + c))
})
#let page-bg = place(top + left, rect(width: 100%, height: 100%, fill: graph()))
// The booklet sets odd folios at the left and even ones at the right.
#let folio = context {
  let pg = counter(page).get().first()
  if frontmatter.get() { none } else {
    set text(font: f-body, size: 8pt, fill: ink)
    if calc.odd(pg) { pad(left: -hang, str(pg)) } else { align(right, str(pg)) }
  }
}

// A band across the whole page, from edge to edge, at the current place.
#let lilac-fill = gradient.linear(lilac-d, lilac, lilac-d.lighten(6%), angle: 0deg)
#let bleed(body, fill: lilac-fill, inset: (y: 9pt)) = pad(left: -m-left,
  right: -m-right, block(width: 100%, fill: fill, inset: inset, breakable: false,
  pad(left: m-left, right: m-right, body)))

// ---------- heads ---------------------------------------------------
// "1. Unpacking Your ATARI 5200": Helvetica Bold in blue-violet, hung into
// the left margin so the text column starts a step in.
#let chap(n, title) = block(above: 0pt, below: 14pt, breakable: false,
  sticky: true, pad(left: -hang, {
    set par(leading: 0.4em, justify: false, hanging-indent: if n != none { 1.35em } else { 0pt })
    set text(font: f-body, weight: 700, size: 13.5pt, fill: violet)
    if n != none { n + "." + h(0.45em) }
    title
  }))

// ---------- callouts ------------------------------------------------
// "NOTE:" in plain caps, the stronger ones in bold, as the booklet sets them.
#let callout(label, body, bold: true) = block(width: 100%, above: 0.85em,
  below: 0.85em, breakable: false, {
  set par(justify: false, first-line-indent: 0pt)
  if label != none {
    if bold { text(weight: 700, label + ":") } else { label + ":" }
    [ ]
  }
  body
})
#let note(body) = callout("NOTE", body, bold: false)
#let important(body) = callout("IMPORTANT", body)
#let caution(body) = callout("CAUTION", body)
#let warning(body) = callout("WARNING", body)
// a pointer to the other books, in grey
#let rules(body) = block(width: 100%, above: 0.9em, below: 0.6em,
  breakable: false, text(size: 7.8pt, fill: gray, body))

// ---------- lists ---------------------------------------------------
#let dot = box(baseline: 3.7pt, circle(radius: 1.55pt, fill: ink))
// The booklet's own steps: "1." in bold, hanging.
#let steps(..items, start: 1) = enum(numbering: n => text(weight: 700,
  numbering("1.", n)), start: start, spacing: 0.75em, tight: false,
  body-indent: 5pt, ..items.pos())

// ---------- key labels ----------------------------------------------
// Black boxes lettered in the key's own colour: START green, PAUSE yellow,
// RESET red, the keypad gold, the side buttons red-orange.
#let key-colour(s) = (START: k-green, PAUSE: k-yellow, RESET: k-red).at(s,
  default: if s.len() == 1 { k-gold } else { white })
#let key(s, fill: auto) = box(fill: ink, inset: (x: 2.6pt), outset: (y: 1.7pt),
  text(font: f-body, weight: 400, size: 7.4pt,
    fill: if fill == auto { key-colour(s) } else { fill }, s))
#let START = key("START")
#let PAUSE = key("PAUSE")
#let RESET = key("RESET")
#let HASH = key("#")
#let STAR = key("*")
#let BOTTOM = key("BOTTOM", fill: k-fire)
#let TOP = key("TOP", fill: k-fire)
#let kp(..ds) = ds.pos().map(d => key(str(d))).join(h(1.5pt))

// a stick direction, drawn (Helvetica has no arrows): "u" "d" "l" "r",
// "ud" (up or down), "lr" (left or right), "udlr" (any way)
#let stick(dir) = {
  let tri(rot) = box(baseline: 0.5pt, width: 6pt, height: 6pt,
    rotate(rot, reflow: false, polygon(fill: white,
      (3pt, 0.5pt), (5.6pt, 5.4pt), (0.4pt, 5.4pt))))
  let one(d) = if d == "u" { tri(0deg) } else if d == "d" { tri(180deg) }
    else if d == "l" { tri(-90deg) } else { tri(90deg) }
  box(fill: ink, inset: (x: 2.2pt), outset: (y: 1.7pt), {
    for (i, c) in dir.clusters().enumerate() {
      if i > 0 { h(1pt) }
      one(c)
    }
  })
}

// A controls chart, as the booklet lays out START / PAUSE / RESET: the
// key at the left, what it does at the right, a hairline between rows.
#let controls(title: none, ..rows, w: 0.95in) = block(above: 0.8em,
  below: 0.95em, breakable: false, width: 100%, {
  set par(justify: false, first-line-indent: 0pt, leading: 0.5em)
  set text(size: 8.2pt)
  if title != none {
    block(below: 4pt, sticky: true,
      text(weight: 700, size: 8.6pt, fill: violet, title))
  }
  table(columns: (w, 1fr), align: (left + top, left + top),
    inset: (x: 4pt, y: 3.6pt), fill: panel,
    stroke: (x, y) => (top: if y == 0 { 0.9pt + ink } else { 0.4pt + panel-b },
      bottom: 0.9pt + ink),
    ..rows.pos().flatten())
})

// ---------- figures (the booklet never numbers them) ----------------
#let fig(body, caption: none) = block(width: 100%, above: 0.9em, below: 1.0em,
  breakable: false, {
  align(center, body)
  if caption != none {
    v(4pt)
    set par(justify: false)
    align(center, text(size: 7.6pt, fill: gray, caption))
  }
})
// a render, at a width
#let art(name, w: 100%) = image("images/render/" + name + ".png", width: w)
// line art straight on the lilac band, edge to edge, as the booklet sets its
// drawings; a caption (or numbered step) may follow under the band
#let plate(body, caption: none, inset: (y: 10pt)) = block(above: 1em,
  below: 0.9em, breakable: false, {
  bleed(inset: inset, align(center, body))
  if caption != none {
    v(4pt)
    set par(justify: false)
    align(center, text(size: 7.6pt, fill: gray, caption))
  }
})
// a real screen from the FujiNet MAME, kept at hard pixels, in a white
// panel on the lilac band, as the booklet mounts its photographs
#let tvframe(img, w) = box(fill: rgb("#24222a"), inset: 3.5pt, radius: 2.5pt,
  box(clip: true, radius: 1pt, image(img, width: w)))
#let screen(name, w: 1.9in) = tvframe("images/screens/" + name + ".png", w)
// one or more screens on the band, each with its own small caption
#let shots(..items, w: 1.85in, caption: none, gap: 8pt) = block(above: 1em,
  below: 0.9em, breakable: false, {
  let it = items.pos()
  bleed(align(center, box(fill: panel, inset: 7pt,
    grid(columns: it.len(), column-gutter: gap, row-gutter: 3.5pt,
      align: center + top,
      ..it.map(x => screen(x.at(0), w: w)),
      ..it.map(x => text(size: 6.8pt, fill: gray, x.at(1)))))))
  if caption != none {
    v(4pt)
    set par(justify: false)
    align(center, text(size: 7.6pt, fill: gray, caption))
  }
})
#let shot(name, cap, w: 2.3in, caption: none) = shots((name, cap), w: w,
  caption: caption)

// ---------- labelled line art ---------------------------------------
// `labels`: (px, py, lx, ly, body[, side]) -- px/py is the point on the
// picture the leader touches, lx/ly where the label sits; all fractions of
// the picture's width/height (labels may sit outside 0..1, in the margin
// the `pad` reserves).  `side` (left/right/center) is which edge of the
// label the leader leaves from; by default the edge facing the point.
#let labelled(img, w: 100%, pad: (top: 0pt, bottom: 0pt, left: 0pt, right: 0pt),
              size: 7pt, labels) = layout(sz => {
  let W = if type(w) == ratio { sz.width * w } else { w }
  let im = image(img, width: W)
  let h = measure(im).height
  let pt = pad.at("top", default: 0pt)
  let pb = pad.at("bottom", default: 0pt)
  let pl = pad.at("left", default: 0pt)
  let pr = pad.at("right", default: 0pt)
  align(center, box(width: W + pl + pr, height: h + pt + pb, {
    place(top + left, dx: pl, dy: pt, im)
    for l in labels {
      let (px, py, lx, ly, body) = (l.at(0), l.at(1), l.at(2), l.at(3), l.at(4))
      let side = if l.len() > 5 { l.at(5) } else if lx < px - 0.05 { left }
                 else if lx > px + 0.05 { right } else { center }
      if body == none {
        place(top + left, line(start: (pl + W * lx, pt + h * ly),
          end: (pl + W * px, pt + h * py), stroke: 0.7pt + ink))
        continue
      }
      let lab = text(font: f-head, weight: 700, size: size, body)
      let m = measure(box(width: 1.3in, par(justify: false, leading: 0.3em,
                                         lab)))
      let lw = calc.min(m.width, 1.3in)
      let tx = pl + W * lx
      let ty = pt + h * ly
      let (bx, ax) = if side == left { (tx - lw, tx + 2pt) }
                     else if side == right { (tx, tx - 2pt) }
                     else { (tx - lw / 2, tx) }
      let below = ly > py
      let by = ty - m.height / 2
      let ay = if side == center { if below { ty - m.height / 2 - 1pt } else { ty + m.height / 2 + 1pt } } else { ty }
      place(top + left, dx: bx, dy: by, box(width: lw,
        align(if side == left { right } else if side == right { left } else { center },
          par(justify: false, leading: 0.3em, lab))))
      place(top + left, line(start: (ax, ay), end: (pl + W * px, pt + h * py),
        stroke: 0.7pt + ink))
    }
  }))
})

// ---------- the screen's own lettering, inline ----------------------
// CONFIG draws white capitals on its blue; the book quotes them in small
// bold capitals so a reader can match them to the screen.
#let scr(s) = text(weight: 700, size: 0.92em, tracking: 0.2pt, s)

// ---------- the Troubleshooting Checklist ---------------------------
// Rules across the page; "Symptom" and "Probable Cause and Remedy" in bold
// blue-violet at the left, the bullets at the right.
#let symrem(..rows) = block(above: 0.6em, below: 0.8em, {
  set par(justify: false, first-line-indent: 0pt)
  let head(s) = text(weight: 700, size: 9.4pt, fill: violet, s)
  let rule = line(length: 100%, stroke: 0.9pt + ink)
  for r in rows.pos() {
    let causes = if type(r.at(1)) == array { r.at(1) } else { (r.at(1),) }
    block(breakable: false, above: 0.9em, below: 0.4em, {
      rule
      v(2pt)
      grid(columns: (1.05in, 1fr), column-gutter: 8pt,
        head[Symptom], list(r.at(0)))
      v(7pt)
      rule
      v(2pt)
      grid(columns: (1.05in, 1fr), column-gutter: 8pt,
        head[Probable Cause \ and Remedy], list(..causes))
    })
  }
})

// ---------- plain tables --------------------------------------------
// Tables sit on paper so the graph grid does not run through their rules.
#let tbl(cols, ..rows, align: left, size: 7.8pt) = block(above: 0.7em,
  below: 0.9em, {
  set par(justify: false, first-line-indent: 0pt, leading: 0.5em)
  set text(size: size)
  let n = if type(cols) == array { cols.len() } else { cols }
  let cells = rows.pos().flatten()
  table(columns: cols, align: align + top, inset: (x: 4.5pt, y: 3.6pt),
    fill: panel,
    stroke: (x, y) => (
      top: if y == 0 { 0.9pt + ink } else { 0.4pt + panel-b },
      bottom: 0.9pt + ink),
    table.header(..cells.slice(0, n)),
    ..cells.slice(n))
})
#let th(s) = text(weight: 700, fill: violet, s)

// ---------- dot-leader definition rows (the parts list) -------------
#let dotdef(..rows) = {
  set par(first-line-indent: 0pt, justify: false)
  grid(columns: (1fr, 1.25fr), row-gutter: 3.6pt, column-gutter: 8pt,
    align: (left + top, left + top),
    ..rows.pos().chunks(2).map(r => (
      box(width: 100%, {
        text(size: 8.2pt, r.at(0))
        box(width: 1fr, repeat(text(size: 8.2pt)[.], gap: 2pt))
      }),
      text(size: 8pt, r.at(1)))).flatten())
}

// ---------- block-diagram nodes -------------------------------------
#let nodebox(title, sub: none, fill: panel, w: auto, h: auto) = box(width: w,
  height: h, fill: fill, inset: (x: 6pt, y: 4.5pt), stroke: 0.7pt + ink,
  align(center + horizon, {
    text(weight: 700, size: 7.2pt, title)
    if sub != none { v(2pt, weak: true); text(size: 6.2pt, fill: gray, sub) }
  }))
#let rarrow(w: 18pt, label: none) = box(width: w, height: 12pt, baseline: 4pt, {
  place(left + horizon, line(length: w - 5pt, stroke: 0.8pt + ink))
  place(left + horizon, dx: w - 6pt, polygon(fill: ink, (0pt, -2.5pt), (5pt, 0pt), (0pt, 2.5pt)))
  if label != none { place(center + bottom, dy: -8pt, text(size: 5.4pt, label)) }
})
#let biarrow(w: 20pt, label: none) = box(width: w, height: 12pt, baseline: 4pt, {
  place(left + horizon, dx: 4pt, line(length: w - 8pt, stroke: 0.8pt + ink))
  place(left + horizon, dx: 0pt, polygon(fill: ink, (4pt, -2.5pt), (0pt, 0pt), (4pt, 2.5pt)))
  place(left + horizon, dx: w - 6pt, polygon(fill: ink, (0pt, -2.5pt), (4pt, 0pt), (0pt, 2.5pt)))
  if label != none { place(center + bottom, dy: -8pt, text(size: 5.5pt, label)) }
})
#let flow(..items) = align(center, block(above: 0.7em, below: 0.6em,
  breakable: false, stack(dir: ltr, spacing: 0pt, ..items.pos())))

// ---------- unnumbered sub-heads ------------------------------------
#let sect(t) = heading(level: 2, numbering: none, t)
#let sub(t) = heading(level: 3, numbering: none, t)

// ---------- pointers to the other books -----------------------------
#let PH = emph[FujiNet 5200 Programmer's Handbook]
#let url(s) = text(weight: 700, s)
#let file(s) = text(font: f-mono, size: 0.92em, s)

// ---------- the rainbow ---------------------------------------------
// The stripe across both covers.
#let rainbow = gradient.linear(
  (rgb("#e8553f"), 0%), (rgb("#d9567f"), 18%), (rgb("#9a5cb8"), 34%),
  (rgb("#5a6fcf"), 50%), (rgb("#3fa3b5"), 62%), (rgb("#5cbb62"), 76%),
  (rgb("#b9cf4c"), 88%), (rgb("#ecd447"), 100%))

// "this folder, then that one": a small drawn triangle (Helvetica has none)
#let into = box(inset: (x: 2pt), baseline: -0.5pt, polygon(fill: ink,
  (0pt, 0pt), (3.6pt, 2.3pt), (0pt, 4.6pt)))
