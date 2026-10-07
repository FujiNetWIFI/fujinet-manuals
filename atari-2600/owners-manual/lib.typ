// lib.typ -- helpers for the FujiNet Atari 2600 Owner's Manual.
//
// House style: the 1977 Atari "Video Computer System Owner's Manual" -- a
// half-letter booklet, Helvetica, numbered colour section bands with a big
// Harry Fat numeral IN THE BAND'S COLOUR on the paper at the outer edge of
// the page, black caps in the band, bold NOTE and IMPORTANT paragraphs
// between thin blue rules, round bullets, lettered steps, line art with
// leader-line labels, a SYMPTOM / PROBABLE CAUSE AND REMEDY checklist and a
// PARTS LIST.  Ragged right throughout.  Short sections run on, one under
// the other, as the booklet's 6, 7 and 8 do.
//
// Adapted from ../programmers-handbook/lib.typ (palette, callouts, tables);
// the band, the TV screens and the figure labels are this book's own.

// ---------- fonts ---------------------------------------------------
#let f-body   = "Helvetica"
#let f-head   = "Helvetica"
#let f-ital   = "Nimbus Sans"          // Helvetica has no oblique here
#let f-mono   = "Source Code Pro"
#let f-wordmk = "Harry"                // Harry Fat: the cover and the numerals
#let f-screen = "VCS Screen"           // the cartridge's own 3x5 font

// ---------- palette (eyedropped from the 1977 booklet) --------------
#let ink     = rgb("#111111")
#let paper   = rgb("#fdfcf8")
#let blue    = rgb("#1e8fd0")          // the thin rules
#let gray    = rgb("#6b6b6b")
#let panel   = rgb("#f1f1ee")
#let panel-b = rgb("#d9d9d4")
#let lime    = rgb("#a9c43a")
#let bblue   = rgb("#1180c6")
#let orange  = rgb("#f39200")
#let red     = rgb("#ee3a12")
#let green   = rgb("#86b11d")
#let plum    = rgb("#8e2478")
#let magenta = rgb("#c4108e")
// the booklet's order: 1 lime, 2 blue, 3 orange, 4 lime, 5 red, 6 orange,
// 7 green; its 8 and 9 (the checklist and the parts list) are plum and
// magenta, and so are ours.
#let bands   = (lime, bblue, orange, lime, red, orange, green)
#let band-ink(c) = if c == plum { rgb("#f6dcef") } else { ink }
#let scr-bg  = rgb("#000000")
#let scr-fg  = rgb("#f0f0f0")

#let band-col = state("band-col", lime)
#let frontmatter = state("fm", true)

// ---------- section bands (level-1 headings) ------------------------
// The numeral sits on the paper at the OUTER edge -- left on a left-hand
// page, right on a right-hand one -- set in the band's own colour.  Left or
// right is decided by the PHYSICAL page, which is what the binding sees.
#let band(n, title, col) = context {
  let odd = calc.odd(here().page())
  let num = text(font: f-wordmk, weight: 900, size: 40pt, fill: col,
    top-edge: "cap-height", bottom-edge: "baseline", str(n))
  let bar = box(width: 100%, fill: col, inset: (x: 8pt, y: 5.5pt),
    align((if odd { right } else { left }) + horizon,
      par(leading: 0.22em, justify: false,
        text(font: f-head, weight: 700, size: 17pt, fill: band-ink(col),
          tracking: -0.2pt, upper(title)))))
  block(width: 100%, above: 1.5em, below: 13pt, breakable: false,
    sticky: true,
    grid(columns: if odd { (1fr, auto) } else { (auto, 1fr) },
      column-gutter: 7pt, align: horizon,
      ..if odd { (bar, num) } else { (num, bar) }))
}

// ---------- callouts ------------------------------------------------
// NOTE: and IMPORTANT: are set entirely in bold between two thin blue
// rules -- the booklet's signature.
#let callout(label, body) = block(width: 100%, above: 0.9em, below: 0.9em,
  breakable: false, {
  line(length: 100%, stroke: 0.7pt + blue)
  v(3pt)
  block(inset: (x: 2pt), {
    set par(justify: false, leading: 0.42em, first-line-indent: 0pt)
    set text(weight: 700)
    if label == none { body } else [#label: #body]
  })
  v(3pt)
  line(length: 100%, stroke: 0.7pt + blue)
})
#let note(body) = callout("NOTE", body)
#let important(body) = callout("IMPORTANT", body)
#let caution(body) = callout("CAUTION", body)
#let rules(body) = callout(none, body)

// ---------- lists ---------------------------------------------------
#let steps(..items) = enum(numbering: "A.", spacing: 0.5em, tight: false,
  ..items.pos())

// ---------- figures (the booklet never numbers them) ----------------
#let fig(body, caption: none) = block(width: 100%, above: 0.9em, below: 1.0em,
  breakable: false, {
  align(center, body)
  if caption != none {
    v(4pt)
    set par(justify: false)
    align(center, text(size: 7.8pt, fill: gray, caption))
  }
})

// a render (images/render/*.png) at a width
#let art(name, w: 100%) = image("images/render/" + name + ".png", width: w)

// a MAME capture, already scaled to TV aspect by tools/scale.py
#let shot(name, w: 1.5in, h: none) = box(stroke: 0.6pt + ink,
  if h != none { image("images/screens/" + name + ".png", height: h) }
  else { image("images/screens/" + name + ".png", width: w) })
// a row of captures, all the same HEIGHT (close-ups are taller than wide)
#let shots(..items, h: 1.05in, gutter: 8pt) = {
  let it = items.pos()
  align(center, grid(columns: it.len(), column-gutter: gutter, row-gutter: 3pt,
    align: center,
    ..it.map(x => shot(x.at(0), h: h)),
    ..it.map(x => text(size: 7pt, fill: gray, x.at(1)))))
}

// ---------- labelled line art ---------------------------------------
// `labels`: (px, py, lx, ly, body[, side]) -- px/py is the point on the
// picture the leader touches, lx/ly where the label sits; all fractions of
// the picture's width/height (labels may sit outside 0..1, in the margin
// the `pad` reserves).  `side` (left/right/center) is which edge of the
// label the leader leaves from; by default the edge facing the point.
#let labelled(img, w: 100%, pad: (top: 0pt, bottom: 0pt, left: 0pt, right: 0pt),
              size: 7.6pt, labels) = layout(sz => {
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
        // a second leader for the label before it: line only
        place(top + left, line(start: (pl + W * lx, pt + h * ly),
          end: (pl + W * px, pt + h * py), stroke: 0.7pt + ink))
        continue
      }
      let lab = text(font: f-head, weight: 700, size: size, body)
      let m = measure(box(width: 1.6in, par(justify: false, leading: 0.3em,
                                         lab)))
      let lw = calc.min(m.width, 1.6in)
      let tx = pl + W * lx
      let ty = pt + h * ly
      // where the label box goes, and where its leader starts
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

// ---------- the cartridge's screen ----------------------------------
// The cartridge draws a 12 x 21 grid of 3x5 letters in 4x6 cells, one
// colour clock wide and one scanline tall a pixel -- so on a TV a cell is
// about 1.7 times wider than the square font draws it.  `tvtext` sets the
// grid at TV shape; `tvfile` reads it from screens/<name>.txt.  Rows may
// carry a colour: a line "@#rrggbb text" is drawn in that colour.
#let tv-aspect = 1.7
#let tvtext(src, size: 5.8pt, frame: true, cols: 12, rows: 21,
            margin: 2.2) = {
  let lines = src.split("\n")
  if lines.len() > 0 and lines.last() == "" { lines = lines.slice(0, -1) }
  while lines.len() < rows { lines.push("") }
  let cw = size * 4 / 6                       // the font's square cell
  let cell(c, fill) = box(width: cw, height: size,
    if c == " " { none } else {
      text(font: f-screen, size: size, fill: fill,
        top-edge: "ascender", bottom-edge: "descender", c) })
  let body = stack(dir: ttb, spacing: 0pt, ..lines.slice(0, rows).map(l => {
    let fill = scr-fg
    let s = l
    if l.starts-with("@#") {
      fill = rgb(l.slice(1, 8))
      s = l.slice(9)
    }
    box(width: cw * cols, height: size, align(left + top,
      stack(dir: ltr, spacing: 0pt, ..s.clusters().map(c => cell(c, fill)))))
  }))
  // a 2600 pixel is about 1.7 times wider on a TV than tall
  let screen = box(fill: scr-bg, inset: (x: cw * tv-aspect * margin, y: size * 1.2),
    radius: 3pt, scale(x: tv-aspect * 100%, reflow: true, body))
  if frame {
    box(fill: rgb("#d8d8d2"), radius: 6pt, inset: 5pt, stroke: 0.8pt + ink,
      screen)
  } else { screen }
}
#let tvfile(name, ..args) = tvtext(read("screens/" + name + ".txt"), ..args)
// a screen with a caption under it, for rows of screens
#let tvcap(name, cap, ..args) = box(align(center, {
  tvfile(name, ..args)
  v(2pt)
  text(size: 7pt, fill: gray, cap)
}))
// inline: the screen's own lettering, at text size
#let scr(s) = box(fill: scr-bg, inset: (x: 2pt, y: 1.2pt), outset: (y: 1pt),
  radius: 1pt, scale(x: tv-aspect * 100%, reflow: true,
    stack(dir: ltr, spacing: 0pt, ..s.clusters().map(c => box(width: 0.92em * 4 / 6,
      if c == " " { none } else { text(font: f-screen, size: 0.92em, fill: scr-fg,
        top-edge: "ascender", bottom-edge: "descender", c) })))))

// ---------- controls ------------------------------------------------
// Keycap-ish boxes for the console's switches and the joystick.
#let key(s) = box(baseline: 20%, stroke: 0.6pt + ink, inset: (x: 3pt, y: 1.2pt),
  radius: 1.5pt, text(font: f-head, weight: 700, size: 6.8pt, s))
#let FIRE = key("FIRE")
#let SELECT = key("GAME SELECT")
#let RESET = key("GAME RESET")
#let CRESET = box(baseline: 20%, fill: ink, inset: (x: 3pt, y: 1.2pt),
  radius: 1.5pt, text(font: f-head, weight: 700, size: 6.8pt, fill: white,
  "CARTRIDGE RESET"))
// a joystick direction, drawn (Helvetica has no arrows): "u" "d" "l" "r",
// "ud" (up or down), "lr" (left or right)
#let stick(dir) = {
  let tri(rot) = box(baseline: 0.5pt, width: 6pt, height: 6pt,
    rotate(rot, reflow: false, polygon(fill: ink,
      (3pt, 0.5pt), (5.6pt, 5.4pt), (0.4pt, 5.4pt))))
  let one(d) = if d == "u" { tri(0deg) } else if d == "d" { tri(180deg) }
    else if d == "l" { tri(-90deg) } else { tri(90deg) }
  box(stroke: 0.6pt + ink, radius: 1.5pt, inset: (x: 2pt, y: 1.2pt),
    baseline: 20%, {
    for (i, c) in dir.clusters().enumerate() {
      if i > 0 { h(1pt) }
      one(c)
    }
  })
}
// A controls chart: rows of (control, what it does).
#let controls(title: none, ..rows) = block(above: 0.7em, below: 0.9em,
  breakable: false, width: 100%, {
  set par(justify: false, first-line-indent: 0pt)
  set text(size: 8.2pt)
  context {
    let c = band-col.get()
    if title != none {
      block(below: 0pt, width: 100%, fill: c, inset: (x: 6pt, y: 3.5pt),
        text(font: f-head, weight: 700, size: 7.8pt, fill: band-ink(c),
          tracking: 0.3pt, upper(title)))
    }
    table(columns: (auto, 1fr), align: (left + horizon, left + top),
      inset: (x: 5pt, y: 3.6pt),
      stroke: (x, y) => (bottom: 0.4pt + panel-b,
        left: if x == 1 { 0.4pt + panel-b } else { none }),
      ..rows.pos().flatten())
  }
})

// ---------- the SYMPTOM / REMEDY table ------------------------------
#let symrem(..rows) = block(above: 0.8em, below: 1em, {
  set par(justify: false, first-line-indent: 0pt)
  set text(size: 8.2pt)
  table(columns: (0.8fr, 1.4fr), align: (left + top, left + top),
    inset: (x: 6pt, y: 5pt),
    stroke: (x, y) => (
      left: if x == 1 { 0.8pt + blue } else { none },
      top: if y == 0 { 0.8pt + blue } else { 0.4pt + blue },
      bottom: 0.8pt + blue),
    table.header(
      align(center, text(weight: 700)[SYMPTOM]),
      align(center, text(weight: 700)[PROBABLE CAUSE AND REMEDY])),
    ..rows.pos().map(r => (text(weight: 700, r.at(0)), r.at(1))).flatten())
})

// ---------- plain tables --------------------------------------------
#let tbl(cols, ..rows, align: left, size: 8.2pt) = block(above: 0.7em,
  below: 0.9em, {
  set par(justify: false, first-line-indent: 0pt)
  set text(size: size)
  table(columns: cols, align: align + top, inset: (x: 5pt, y: 3.6pt),
    stroke: (x, y) => (
      top: if y == 0 { 0.8pt + ink } else { 0.4pt + panel-b },
      bottom: 0.8pt + ink),
    ..rows.pos().flatten())
})
#let th(s) = text(weight: 700, s)

// ---------- dot-leader rows (the parts list) ------------------------
#let dotdef(..rows, cols: (1.3fr, 1fr)) = {
  set par(first-line-indent: 0pt, justify: false)
  grid(columns: cols, row-gutter: 5pt, column-gutter: 8pt,
    align: (left + top, left + top),
    ..rows.pos().chunks(2).map(r => (
      box(width: 100%, {
        text(size: 8.4pt, r.at(0))
        box(width: 1fr, repeat(text(size: 8.4pt)[.], gap: 2pt))
      }),
      text(size: 8pt, r.at(1)))).flatten())
}

// ---------- block-diagram nodes -------------------------------------
#let nodebox(title, sub: none, fill: panel, w: auto, h: auto) = box(width: w,
  height: h, fill: fill, inset: (x: 6pt, y: 5pt), stroke: 0.7pt + ink,
  radius: 2pt, align(center + horizon, {
    text(font: f-head, weight: 700, size: 7.4pt, title)
    if sub != none { v(2pt, weak: true); text(size: 6.4pt, fill: gray, sub) }
  }))
#let biarrow(w: 20pt, label: none) = box(width: w, height: 12pt, baseline: 4pt, {
  place(left + horizon, dx: 4pt, line(length: w - 8pt, stroke: 0.8pt + ink))
  place(left + horizon, dx: 0pt, polygon(fill: ink, (4pt, -2.5pt), (0pt, 0pt), (4pt, 2.5pt)))
  place(left + horizon, dx: w - 6pt, polygon(fill: ink, (0pt, -2.5pt), (4pt, 0pt), (0pt, 2.5pt)))
  if label != none { place(center + bottom, dy: -8pt, text(font: f-head, size: 5.5pt, label)) }
})
#let flow(..items) = align(center, block(above: 0.7em, below: 0.6em,
  breakable: false, stack(dir: ltr, spacing: 0pt, ..items.pos())))

// ---------- unnumbered sub-heads ------------------------------------
#let sect(t) = heading(level: 2, numbering: none, t)
#let sub(t) = heading(level: 3, numbering: none, t)

// ---------- pointers to the other books -----------------------------
#let PH = emph[FujiNet Video Computer System Programmer's Handbook]
#let TO = emph[FujiNet for the Atari 2600: Theory of Operation]
#let url(s) = text(font: f-head, weight: 700, s)
