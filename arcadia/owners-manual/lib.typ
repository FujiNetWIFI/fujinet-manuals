// lib.typ -- helpers for the FujiNet Arcadia 2001 Owner's Manual.
//
// House style: the 1982 Emerson ARCADIA-2001 Owner's Manual (model ADV-1)
// and the Emerson game booklets of the same year (Baseball, Space Mission),
// arcadia/learn/. Letter-size pages printed in black ink on white:
// Helvetica throughout, heads in bold capitals with no rules, generous
// leading, numbered line drawings with leader lines and the "1) NAME / what
// it does" lists under them, CAUTION and NOTE lines, a ruled Trouble
// Shooting Check List of Symptom / Cause And Remedy, folios centred between
// dashes ("-- 3 --"). The game sections are set as the booklets are: a
// "VIDEO GAME INSTRUCTIONS" line over a black title band, roman-numbered
// heads (I. GENERAL), double-spaced numbered steps, and an OVERLAY figure.
// The screens are the only colour: a television's, framed in a TV outline.

// ---------- fonts ---------------------------------------------------
#let f-body = "Helvetica"
#let f-wm   = "Harry"                      // Harry Obese: the ARCADIA-2001 lettering
#let f-narrow = "Nimbus Sans"              // Narrow Bold (stretch 87.5%): the cover's condensed capitals

// ---------- ink -------------------------------------------------------
#let ink   = rgb("#141414")
#let paper = rgb("#ffffff")
#let gray  = rgb("#5a5a5a")
#let rule-c = ink
#let tint  = rgb("#ececec")               // a table's head row, a panel

#let frontmatter = state("fm", true)
#let booklet = state("booklet", false)    // inside a game section
#let bandfile = state("bandfile", none)   // its (host, file), for the band

// ---------- the page --------------------------------------------------
#let m-left = 0.95in
#let m-right = 0.85in
#let folio = context {
  if frontmatter.get() { none } else {
    set text(font: f-body, size: 10pt, fill: ink)
    align(center, [--#h(0.4em)#counter(page).display()#h(0.4em)--])
  }
}

// ---------- heads -----------------------------------------------------
// The Owner's Manual's: bold capitals, the size of a line and a half of
// text, no rule; a section starts a new page. The number goes before it
// so the contents can name it.
#let chap(n, title) = block(above: 0pt, below: 16pt, breakable: false,
  sticky: true, {
    set par(leading: 0.45em, justify: false)
    set text(font: f-body, weight: 700, size: 17pt, fill: ink, tracking: 0.3pt)
    if n != none {
      box(width: 0.42in, n + ".")
    }
    upper(title)
  })

// ---------- callouts --------------------------------------------------
// "CAUTION:" and "NOTE:" as the Owner's Manual sets them: the word in
// capitals, the rest following in the same type.
#let callout(label, body, bold: false) = block(width: 100%, above: 1em,
  below: 1em, breakable: false, {
  set par(justify: false, first-line-indent: 0pt)
  text(weight: 700, label + ":")
  [ ]
  if bold { strong(body) } else { body }
})
#let note(body) = callout("NOTE", body)
#let caution(body) = callout("CAUTION", body, bold: true)
#let important(body) = callout("IMPORTANT", body)
// a pointer to the other books, in grey
#let rules(body) = block(width: 100%, above: 1.1em, below: 0.8em,
  breakable: false, text(size: 9.5pt, fill: gray, body))

// ---------- lists -----------------------------------------------------
// The booklets' steps: "1." hanging, the lines double-spaced (set by the
// caller in a game section).
#let steps(..items, start: 1) = enum(numbering: n => text(weight: 700,
  numbering("1.", n)), start: start, spacing: 0.9em, tight: false,
  body-indent: 8pt, indent: 0pt, ..items.pos())
// The Owner's Manual's numbered parts: "1) LED POWER INDICATOR" in
// capitals, what it does on the line under it, indented.
#let partlist(..items) = block(above: 0.9em, below: 1em, {
  set par(justify: false, leading: 0.55em)
  for (i, it) in items.pos().enumerate() {
    block(above: 0.85em, below: 0pt, breakable: false,
      grid(columns: (0.34in, 1fr), row-gutter: 3.5pt,
        text(weight: 400, str(i + 1) + ")"), upper(it.at(0)),
        [], it.at(1)))
  }
})

// ---------- keys --------------------------------------------------------
// The Arcadia's keys and buttons, named in the text as small keycaps:
// capitals in a rounded box, as the hand controller's keys are lettered.
#let key(s) = box(stroke: 0.6pt + ink, radius: 2pt, inset: (x: 2.6pt),
  outset: (y: 1.8pt), text(font: f-body, weight: 700, size: 0.78em, s))
#let kp(..ds) = ds.pos().map(d => key(str(d))).join(h(1.6pt))
#let CLEAR = key("CLEAR")
#let ENTER = key("ENTER")
#let FIRE = key("ACTION")                  // the side buttons
#let START = key("START")
#let SELECT = key("SELECT")
#let OPTION = key("OPTION")
#let RESET = key("RESET")
#let POWER = key("POWER")
// a direction on the control disc, drawn (Helvetica has no arrows): "u"
// "d" "l" "r", "ud" (up or down), "lr", "udlr"
#let disc(dir) = {
  let tri(rot) = box(baseline: 0.5pt, width: 6pt, height: 6pt,
    rotate(rot, reflow: false, polygon(fill: white,
      (3pt, 0.5pt), (5.6pt, 5.4pt), (0.4pt, 5.4pt))))
  let one(d) = if d == "u" { tri(0deg) } else if d == "d" { tri(180deg) }
    else if d == "l" { tri(-90deg) } else { tri(90deg) }
  box(fill: ink, radius: 5pt, inset: (x: 3pt), outset: (y: 1.8pt), {
    for (i, c) in dir.clusters().enumerate() {
      if i > 0 { h(1pt) }
      one(c)
    }
  })
}

// A controls chart: the key at the left, what it does at the right,
// rules between rows, as the Owner's Manual rules its check list.
#let controls(title: none, ..rows, w: 1.35in) = block(above: 1em,
  below: 1.1em, breakable: false, width: 100%, {
  set par(justify: false, first-line-indent: 0pt, leading: 0.55em)
  set text(size: 10pt)
  if title != none {
    block(below: 5pt, sticky: true, text(weight: 700, size: 10.5pt, upper(title)))
  }
  table(columns: (w, 1fr), align: (left + top, left + top),
    inset: (x: 6pt, y: 5pt),
    stroke: (x, y) => (top: if y == 0 { 1pt + ink } else { 0.5pt + ink },
      bottom: 1pt + ink),
    ..rows.pos().flatten())
})

// ---------- figures -----------------------------------------------------
// Numbered, as the Owner's Manual numbers them: "Fig. 3" over a caption in
// capitals, centred under the picture.
#let figno = counter("fig")
#let wiki = state("wiki", false)          // tools/wikifig.typ: no numbers
#let fig(body, caption: none, above: 1.1em, below: 1.2em) = block(width: 100%,
  above: above, below: below, breakable: false, {
  align(center, body)
  figno.step()
  v(5pt)
  set par(justify: false, leading: 0.45em)
  align(center, text(size: 9pt, context {
    if not wiki.get() [FIG. #figno.display()]
    if caption != none {
      if not wiki.get() { linebreak() }
      upper(caption)
    }
  }))
})
// a render, at a width
#let art(name, w: 100%) = image("images/render/" + name + ".png", width: w)

// ---------- the television ------------------------------------------------
// Each screen sits in a TV outline, as the booklets draw theirs (Baseball,
// Fig. 3): a heavy rounded frame round the picture. The picture is the
// FujiNet MAME's, every pixel kept (tools/scrscale.py).
#let tv-ins = 0.055                         // the margin, a fraction of the width
#let tv-aspect = 1310 / 1728                // the picture's height / width
#let tv(name, w: 2.6in) = box(width: w, stroke: 2.4pt + ink, radius: 12%,
  inset: w * tv-ins, fill: paper,
  box(clip: true, radius: 3pt, image("images/screens/" + name + ".png",
    width: w * (1 - 2 * tv-ins))))
// one or more screens in a row, each with a short caption under it, and the
// figure's number and caption under them all
#let shots(..items, w: 2.45in, caption: none, gap: 0.3in) = fig(caption: caption, {
  let it = items.pos()
  grid(columns: it.len(), column-gutter: gap, row-gutter: 5pt,
    align: center + top,
    ..it.map(x => tv(x.at(0), w: w)),
    ..it.map(x => text(size: 8.5pt, upper(x.at(1)))))
})
#let shot(name, cap, w: 3.0in) = shots((name, cap), w: w)

// ---------- labelled line art (leader lines) ------------------------------
// `labels`: (px, py, lx, ly, body[, side]) -- px/py is the point on the
// picture the leader touches, lx/ly where the label sits; fractions of the
// picture's width/height (labels may sit outside 0..1, in the margin the
// `pad` reserves). `side` (left/right/center) is which edge of the label
// the leader leaves from; by default the edge facing the point.
#let labelled(img, w: 100%, pad: (top: 0pt, bottom: 0pt, left: 0pt, right: 0pt),
              size: 8.5pt, weight: 400, labels) = layout(sz => {
  let W = if type(w) == ratio { sz.width * w } else { w }
  let im = if type(img) == str { image(img, width: W) } else { box(width: W, img) }
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
      let lab = text(font: f-body, weight: weight, size: size, body)
      let m = measure(box(width: 1.5in, par(justify: false, leading: 0.3em, lab)))
      let lw = calc.min(m.width, 1.5in)
      let tx = pl + W * lx
      let ty = pt + h * ly
      let (bx, ax) = if side == left { (tx - lw, tx + 2pt) }
                     else if side == right { (tx, tx - 2pt) }
                     else { (tx - lw / 2, tx) }
      let below = ly > py
      let by = ty - m.height / 2
      let ay = if side == center { if below { ty - m.height / 2 - 1.5pt } else { ty + m.height / 2 + 1.5pt } } else { ty }
      place(top + left, dx: bx, dy: by, box(width: lw,
        align(if side == left { right } else if side == right { left } else { center },
          par(justify: false, leading: 0.3em, lab))))
      place(top + left, line(start: (ax, ay), end: (pl + W * px, pt + h * py),
        stroke: 0.7pt + ink))
    }
  }))
})
// A screen's own row and column, as a point for `labelled` (the Arcadia's
// 16 x 13 text screen in MAME's 192 x 262 frame: cells 8 pixels wide from
// pixel 32, rows 16 lines tall from line 0; 26-row screens are 8 lines tall)
#let cell(r, c, rows: 13) = ((32 + 8 * c + 4) / 192,
  (if rows == 13 { 16 * r + 8 } else { 8 * r + 4 }) / 262)
// a screen in its TV outline with leader-line callouts round it
#let tvlab(name, w: 2.6in, pad: (left: 1.3in, right: 1.3in, top: 4pt, bottom: 4pt),
           labels) = {
  // a point on the picture, as a fraction of the framed whole
  let wi = 1 - 2 * tv-ins
  let H = wi * tv-aspect + 2 * tv-ins        // the whole's height, in widths
  let mapped = labels.map(l => {
    let px = tv-ins + l.at(0) * wi
    let py = (tv-ins + l.at(1) * wi * tv-aspect) / H
    (px, py, ..l.slice(2))
  })
  labelled(tv(name, w: w), w: w, pad: pad, size: 8pt, mapped)
}

// ---------- the screen's own lettering, inline ----------------------------
// What a screen says, quoted in the text: bold capitals, as the Arcadia
// prints them (it has no small letters).
#let scr(s) = text(weight: 700, size: 0.9em, tracking: 0.3pt, s)

// ---------- the Trouble Shooting Check List -------------------------------
// The Owner's Manual's: a ruled table, "Symptom" and "Cause And Remedy"
// over its two columns, each remedy a dash line.
#let symrem(..rows) = block(above: 0.8em, below: 1em, {
  set par(justify: false, first-line-indent: 0pt, leading: 0.5em)
  set text(size: 10pt)
  table(columns: (2.1in, 1fr), inset: (x: 7pt, y: 6pt),
    stroke: 0.8pt + ink, align: left + top,
    table.header(table.cell(align: center, text(weight: 700)[Symptom]),
      table.cell(align: center, text(weight: 700)[Cause And Remedy])),
    ..rows.pos().map(r => {
      let causes = if type(r.at(1)) == array { r.at(1) } else { (r.at(1),) }
      (r.at(0), causes.map(c => grid(columns: (0.8em, 1fr), [--], c))
        .join(v(3pt)))
    }).flatten())
})

// ---------- plain tables ----------------------------------------------------
#let tbl(cols, ..rows, align: left, size: 10pt) = block(above: 0.8em,
  below: 1em, {
  set par(justify: false, first-line-indent: 0pt, leading: 0.5em)
  set text(size: size)
  let n = if type(cols) == array { cols.len() } else { cols }
  let cells = rows.pos().flatten()
  table(columns: cols, align: align + top, inset: (x: 6pt, y: 4.5pt),
    stroke: (x, y) => (
      top: if y == 0 { 1pt + ink } else if y == 1 { 0.8pt + ink } else { 0.4pt + ink },
      bottom: 1pt + ink),
    table.header(..cells.slice(0, n)),
    ..cells.slice(n))
})
#let th(s) = text(weight: 700, upper(s))

// ---------- dot-leader definition rows (the parts list) ---------------------
#let dotdef(..rows) = {
  set par(first-line-indent: 0pt, justify: false)
  grid(columns: (1fr, 1.3fr), row-gutter: 5pt, column-gutter: 10pt,
    align: (left + top, left + top),
    ..rows.pos().chunks(2).map(r => (
      box(width: 100%, {
        r.at(0)
        box(width: 1fr, repeat([.], gap: 2.5pt))
      }),
      r.at(1))).flatten())
}

// ---------- block-diagram nodes ---------------------------------------------
#let nodebox(title, sub: none, fill: paper, w: auto, h: auto) = box(width: w,
  height: h, fill: fill, inset: (x: 7pt, y: 6pt), stroke: 0.9pt + ink,
  align(center + horizon, {
    text(weight: 700, size: 9pt, title)
    if sub != none { v(2.5pt, weak: true); text(size: 8pt, fill: gray, sub) }
  }))
#let biarrow(w: 24pt) = box(width: w, height: 12pt, baseline: 4pt, {
  place(left + horizon, dx: 4pt, line(length: w - 8pt, stroke: 0.9pt + ink))
  place(left + horizon, dx: 0pt, polygon(fill: ink, (4.5pt, -2.8pt), (0pt, 0pt), (4.5pt, 2.8pt)))
  place(left + horizon, dx: w - 5pt, polygon(fill: ink, (0pt, -2.8pt), (4.5pt, 0pt), (0pt, 2.8pt)))
})
#let flow(..items) = align(center, block(above: 0.9em, below: 0.8em,
  breakable: false, stack(dir: ltr, spacing: 0pt, ..items.pos())))

// ---------- sub-heads -------------------------------------------------------
// In the Owner's Manual's part: bold capitals at text size and a half step.
// In a game section: the booklet's roman numerals, "II. OBJECT OF THE GAME".
#let roman = counter("roman")
#let sect(t) = heading(level: 2, numbering: none, t)
#let sub(t) = heading(level: 3, numbering: none, t)

// ---------- the booklets' title band ----------------------------------------
// "VIDEO GAME INSTRUCTIONS" over a black band with the game's name in white,
// and the file's place where a booklet has CART. NO. and PART NO.
#let band(title, num: none, host: none, file: none) = block(width: 100%, above: 0pt,
  below: 20pt, breakable: false, sticky: true, {
  align(center, text(weight: 700, size: 14pt, tracking: 0.6pt)[VIDEO GAME INSTRUCTIONS])
  v(8pt)
  block(width: 100%, fill: ink, inset: (y: 11pt), {
    if num != none {
      place(left + horizon, dx: 10pt, text(weight: 700, size: 13pt, fill: white, num))
    }
    align(center, text(weight: 700, size: 32pt, fill: white, tracking: 1pt,
      upper(title)))
  })
  if host != none {
    v(4pt)
    set text(size: 9pt, weight: 700)
    grid(columns: (1fr, 1fr), align(left, [HOST #h(0.3em) #upper(host)]),
      align(right, [FILE #h(0.3em) #file]))
  }
})

// ---------- the overlay -----------------------------------------------------
// As the booklets draw a game's keyboard overlay (Space Mission, Fig. 1): a
// card with the game's name running up its left edge, and over each key it
// uses a dot with that key's job lettered above it. The key's own name is
// added under each dot in grey, so the card can be read without the
// controller in hand. `jobs`: 12 entries, row by row (1 2 3 / 4 5 6 / 7 8 9 /
// CLEAR 0 ENTER), none where the key does nothing; `head`: a line over the
// keys (the Action buttons' job).
#let overlay(name, jobs, head: none, w: 2.5in) = {
  let names = ("1", "2", "3", "4", "5", "6", "7", "8", "9", "CLEAR", "0", "ENTER")
  let cellw = (w - 0.42in) / 3
  let cell(i, job) = box(width: cellw, height: 0.43in, {
    if job != none {
      place(top + center, dy: 2pt, box(width: cellw - 4pt,
        align(center, text(weight: 700, size: 6.4pt, upper(job)))))
      place(center + horizon, dy: 5pt, circle(radius: 3.6pt, fill: ink))
    } else {
      place(center + horizon, dy: 5pt, circle(radius: 3.6pt, stroke: 0.5pt + gray))
    }
    place(bottom + center, dy: -1pt, text(size: 5.6pt, fill: gray, names.at(i)))
  })
  box(width: w, stroke: 1pt + ink, inset: 0pt, {
    grid(columns: (0.42in, 1fr),
      box(height: 2.05in, width: 0.42in, stroke: (right: 0.6pt + ink),
        align(center + horizon, rotate(-90deg, reflow: true,
          text(weight: 700, size: 12pt, tracking: 1pt, upper(name))))),
      box(inset: (x: 0pt, top: 6pt, bottom: 4pt), {
        if head != none {
          align(center, text(weight: 700, size: 6.4pt, upper(head)))
          v(1pt)
        }
        grid(columns: 3, row-gutter: 0pt, column-gutter: 0pt,
          ..jobs.enumerate().map(((i, j)) => cell(i, j)))
      }))
  })
}

// ---------- pointers --------------------------------------------------------
#let url(s) = text(weight: 700, s)
#let file(s) = text(weight: 700, s)
// "this folder, then that one": a small drawn triangle (Helvetica has none)
#let into = box(inset: (x: 2pt), baseline: -0.5pt, polygon(fill: ink,
  (0pt, 0pt), (4pt, 2.6pt), (0pt, 5.2pt)))

// ---------- the /// mark ----------------------------------------------------
// Three slanted bars, as on the Emerson covers, drawn.
#let bars(h: 0.5in, fill: ink) = {
  let w = h * 0.62
  let gap = h * 0.22
  box(width: 3 * w + 2 * gap + h * 0.45, height: h, {
    for i in range(3) {
      let x = i * (w + gap)
      place(top + left, polygon(fill: fill,
        (x + h * 0.45, 0pt), (x + h * 0.45 + w, 0pt), (x + w, h), (x, h)))
    }
  })
}
