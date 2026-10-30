// lib.typ -- helpers for the FujiNet Atari 5200 Programmer's Handbook.
//
// House style: the 1982 ATARI 5200 Owner's Manual -- a small booklet on
// warm paper ruled with a faint graph grid, Helvetica throughout, numbered
// heads in blue-violet hung to the left of the text, pictures in white
// panels on a lilac band, black key labels lettered in the colour of the
// controller's keys, and a Troubleshooting Checklist of Symptom / Probable
// Cause and Remedy between rules. Ragged right throughout.

// ---------- fonts ---------------------------------------------------
#let f-body = "Helvetica"
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
#let panel   = rgb("#fcfaf9")          // code and pictures sit on white
#let panel-b = rgb("#d9ccd2")
#let cover-k = rgb("#0f0f14")          // the cover's black
// the controller's key colours, as the booklet letters them
#let k-green  = rgb("#43c063")
#let k-yellow = rgb("#f2c522")
#let k-red    = rgb("#ee5040")
// lane colours for diagrams, kept quiet next to the violet
#let tint-a  = rgb("#e6def0")
#let tint-b  = rgb("#dde8ee")
#let tint-c  = rgb("#f1e6d4")
#let tint-d  = rgb("#e1ecdc")

#let appendix = state("apx", false)
#let frontmatter = state("fm", true)

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
  pad(left: -hang, {
    set par(leading: 0.4em, justify: false, hanging-indent: if n != none { 1.35em } else { 0pt })
    set text(font: f-body, weight: 700, size: 13.5pt, fill: violet)
    if n != none { n + "." + h(0.45em) }
    title
  }))

// ---------- the opening letter --------------------------------------
// The booklet has none; kept as a no-op so the parts read the same as the
// other handbooks'.
#let ini(c) = c

// ---------- callouts ------------------------------------------------
// "NOTE:" in plain caps, the stronger ones in bold, as the booklet sets them.
#let callout(label, body, bold: true) = block(width: 100%, above: 0.85em,
  below: 0.85em, breakable: false, {
  set par(justify: false, first-line-indent: 0pt)
  if bold { text(weight: 700, label + ":") } else { label + ":" }
  [ ]
  body
})
#let note(body) = callout("NOTE", body, bold: false)
#let important(body) = callout("IMPORTANT", body)
#let caution(body) = callout("CAUTION", body)
#let warning(body) = callout("WARNING", body)

// ---------- lists ---------------------------------------------------
#let dot = box(baseline: 3.7pt, circle(radius: 1.55pt, fill: ink))
#let nsteps(..items) = enum(numbering: n => text(weight: 700,
  numbering("1.", n)), spacing: 0.6em, tight: false, body-indent: 5pt,
  ..items.pos())
#let steps(..items) = enum(numbering: n => text(weight: 700,
  numbering("A.", n)), spacing: 0.6em, tight: false, body-indent: 5pt,
  ..items.pos())

// ---------- key labels ----------------------------------------------
// Black boxes lettered in the key's own colour: START green, PAUSE yellow,
// RESET red, the keypad and the fire buttons white.
#let key-colour(s) = (START: k-green, PAUSE: k-yellow, RESET: k-red).at(s, default: white)
#let key(s) = box(fill: ink, inset: (x: 2.6pt), outset: (y: 1.7pt),
  text(font: f-body, weight: 400, size: 7.4pt, fill: key-colour(s), s))

// ---------- code ----------------------------------------------------
#let mono(s, size: 0.94em) = text(font: f-mono, size: size, s)
#let hx(s) = text(font: f-mono, size: 0.94em, s)
// A code line never wraps: the panel picks the largest size at which its
// longest line still fits the measure (the text width less the insets).
#let measure = 278pt
#let codesize(txt, size) = {
  let longest = calc.max(1, ..txt.split("\n").map(l => l.len()))
  calc.min(size, measure / (longest * 0.61))
}
// A short panel never breaks across pages; a long one may.
#let codeblock(txt, size: 7pt) = block(width: 100%,
  breakable: txt.split("\n").len() > 28,
  above: 0.8em, below: 0.9em, fill: panel, inset: (x: 7pt, y: 5.5pt),
  stroke: (left: 2pt + violet, rest: 0.5pt + panel-b), {
    set par(justify: false, leading: 0.36em, first-line-indent: 0pt)
    set text(font: f-mono, size: codesize(txt, size), fill: ink)
    txt.split("\n").map(l => if l == "" { " " } else { l }).join(linebreak())
  })
#let codetitle(title) = block(breakable: false, below: 3pt, sticky: true,
  text(weight: 700, size: 6.8pt, fill: violet, tracking: 0.3pt, title))
#let codepanel(title, txt, size: 7pt) = block(above: 0.9em, below: 0.9em,
  breakable: true, {
  codetitle(title)
  codeblock(txt, size: size)
})
// Both roads, one under the other: the page is too narrow for two columns.
#let t-asm = "6502 ASSEMBLY (ca65)"
#let t-c   = "C (cc65 + fujinet-lib)"
#let pair(asm, c, size: 6.9pt) = block(above: 0.8em, below: 0.9em,
  breakable: true, {
  if asm != none { codepanel(t-asm, asm, size: size) }
  if c != none { codepanel(t-c, c, size: size) }
})

// ---------- figures -------------------------------------------------
#let fig-n = counter("figure")
#let caption-of(caption) = {
  fig-n.step()
  set par(justify: false)
  align(center, text(size: 7.6pt, {
    text(weight: 700)[Figure #context fig-n.display().]
    if caption != none { [ #caption] }
  }))
}
#let fig(body, caption: none) = block(width: 100%, above: 0.9em, below: 1.0em,
  breakable: false, {
  align(center, body)
  v(4pt)
  caption-of(caption)
})
// a real screen from the FujiNet MAME, kept at hard pixels, in a white
// panel on the lilac band, as the booklet mounts its photographs
#let tvframe(img, w) = box(fill: rgb("#24222a"), inset: 3.5pt, radius: 2.5pt,
  box(clip: true, radius: 1pt, image(img, width: w)))
#let shotpanel(names, w) = box(fill: panel, inset: 7pt,
  stack(dir: ltr, spacing: 8pt, ..names.map(n =>
    tvframe("images/screens/" + n + ".png", w))))
#let shot(name, w: 2.3in, caption: none) = block(above: 1em, below: 1em,
  breakable: false, {
  bleed(align(center, shotpanel((name,), w)))
  v(4pt)
  caption-of(caption)
})
// two screens side by side: the same program in both languages
#let shots(..names, w: 1.72in, caption: none) = block(above: 1em, below: 1em,
  breakable: false, {
  bleed(align(center, shotpanel(names.pos(), w)))
  v(4pt)
  caption-of(caption)
})

// ---------- the Troubleshooting Checklist ---------------------------
// Rules across the page; "Symptom" and "Probable Cause and Remedy" in bold
// blue-violet at the left, the bullets at the right.
#let symrem(..rows) = block(above: 0.6em, below: 0.8em, {
  set par(justify: false, first-line-indent: 0pt)
  let head(s) = text(weight: 700, size: 9.6pt, fill: violet, s)
  let rule = line(length: 100%, stroke: 0.9pt + ink)
  for r in rows.pos() {
    let causes = if type(r.at(1)) == array { r.at(1) } else { (r.at(1),) }
    block(breakable: false, above: 0.9em, below: 0.4em, {
      rule
      v(2pt)
      grid(columns: (1.15in, 1fr), column-gutter: 8pt,
        head[Symptom], list(r.at(0)))
      v(8pt)
      rule
      v(2pt)
      grid(columns: (1.15in, 1fr), column-gutter: 8pt,
        head[Probable Cause \ and Remedy], list(..causes))
    })
  }
})

// ---------- plain tables --------------------------------------------
// Tables sit on paper so the graph grid does not run through their rules.
#let tbl(cols, ..rows, align: left) = block(above: 0.7em, below: 0.9em, {
  set par(justify: false, first-line-indent: 0pt)
  set text(size: 7.8pt)
  let n = if type(cols) == array { cols.len() } else { cols }
  let cells = rows.pos().flatten()
  // the first row is the header: it repeats on a new page, and Typst will
  // not leave it alone at the foot of one
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
  grid(columns: (1.15fr, 1fr), row-gutter: 5pt, column-gutter: 8pt,
    align: (left + top, left + top),
    ..rows.pos().map(r => (
      box(width: 100%, {
        text(size: 8.2pt, r.at(0))
        box(width: 1fr, repeat(text(size: 8.2pt)[.], gap: 2pt))
      }),
      text(font: f-mono, size: 7pt, r.at(1)))).flatten())
}

// ---------- byte-field strip ----------------------------------------
#let bytefield(..cells) = {
  let cs = cells.pos()
  align(center, block(above: 0.6em, below: 0.5em, breakable: false,
    grid(columns: cs.map(c => c.at(1)), stroke: 0.6pt + ink, fill: panel,
      ..cs.map(c => grid.cell(inset: 4pt, align: center,
        text(font: f-mono, size: 7pt, c.at(0)))))))
}

// ---------- memory map ----------------------------------------------
// rows: (from, to, label, colour, note). A column of boxes with the
// addresses at the left and a note at the right; heights follow the size,
// with a floor so a one-page region still has room for its name.
#let memmap(rows, w: 1.3in, scale: 0.030pt, minh: 14pt, notes: true) = {
  let boxes = rows.map(r => {
    let h = calc.max(minh, (r.at(1) - r.at(0) + 1) * scale)
    grid(columns: (0.5in, w, if notes { 1fr } else { 0pt }),
      column-gutter: 6pt, align: (right + top, left + top, left + top),
      text(font: f-mono, size: 6.8pt, "$" + upper(str(r.at(0), base: 16))),
      box(width: w, height: h, fill: r.at(3), stroke: 0.7pt + ink,
        align(center + horizon, text(weight: 700, size: 6.8pt,
          fill: ink, r.at(2)))),
      if notes { text(size: 7pt, r.at(4)) } else { none })
  })
  align(center, block(above: 0.6em, below: 0.4em, breakable: false,
    stack(dir: ttb, spacing: 0pt, ..boxes,
      v(5pt),
      grid(columns: (0.5in, w, if notes { 1fr } else { 0pt }),
        column-gutter: 6pt, align: (right + top, left + top, left + top),
        text(font: f-mono, size: 6.8pt,
          "$" + upper(str(rows.last().at(1) + 1, base: 16))), [], []))))
}

// ---------- sequence diagrams ---------------------------------------
#let msg(from, to, body, dashed: false, c: ink) = (
  kind: "msg", from: from, to: to, body: body, dashed: dashed, c: c)
#let snote(lane, body, span: 1, fill: panel, bd: gray) = (
  kind: "note", lane: lane, span: span, body: body, fill: fill, bd: bd)
#let sgap(h: 8pt) = (kind: "gap", h: h)
#let seq(actors, ..steps, w: 286pt) = {
  let n = actors.len()
  let steps = steps.pos()
  let lane = w / n
  let xs = range(n).map(i => lane * (i + 0.5))
  let headh = 20pt
  let bodyh = 0pt
  for s in steps {
    if s.kind == "gap" { bodyh += s.h }
    else if s.kind == "note" { bodyh += 24pt }
    else { bodyh += 19pt }
  }
  let toth = headh + bodyh + 10pt
  align(center, block(breakable: false, above: 0.6em, below: 0.6em,
    box(width: w + 8pt, height: toth + 8pt, fill: panel, stroke: 0.5pt + panel-b,
      inset: 4pt, {
    for i in range(n) {
      place(top + left, dx: xs.at(i) - 0.4pt, dy: headh - 2pt,
        line(start: (0pt, 0pt), end: (0pt, bodyh + 6pt),
          stroke: (paint: gray, thickness: 0.6pt, dash: "dotted")))
    }
    for i in range(n) {
      place(top + left, dx: xs.at(i) - lane/2 + 4pt, dy: 0pt,
        box(width: lane - 8pt, height: 16pt, fill: actors.at(i).at(1),
          stroke: 0.7pt + ink,
          align(center + horizon, text(weight: 700, size: 6.6pt,
            fill: ink, actors.at(i).at(0)))))
    }
    let y = headh + 5pt
    for s in steps {
      if s.kind == "gap" { y += s.h }
      else if s.kind == "note" {
        let x0 = xs.at(s.lane) - lane/2 + 6pt
        let wn = lane * s.span - 12pt
        place(top + left, dx: x0, dy: y - 3pt,
          box(width: wn, fill: s.fill, stroke: 0.6pt + s.bd, radius: 2pt,
            inset: (x: 4pt, y: 3pt), align(center,
              text(size: 6.2pt, fill: ink, s.body))))
        y += 24pt
      } else {
        let a = xs.at(s.from)
        let b = xs.at(s.to)
        let lo = calc.min(a, b)
        let hi = calc.max(a, b)
        place(top + left, dx: lo, dy: y + 8pt,
          line(start: (0pt, 0pt), end: (hi - lo, 0pt),
            stroke: (paint: s.c, thickness: 0.8pt,
              dash: if s.dashed { "dashed" } else { none })))
        if b > a {
          place(top + left, dx: b - 5pt, dy: y + 8pt,
            polygon(fill: s.c, (0pt, -2.5pt), (5pt, 0pt), (0pt, 2.5pt)))
        } else {
          place(top + left, dx: b, dy: y + 8pt,
            polygon(fill: s.c, (5pt, -2.5pt), (0pt, 0pt), (5pt, 2.5pt)))
        }
        place(top + left, dx: lo + 4pt, dy: y - 1pt,
          text(font: f-mono, size: 6.2pt, fill: s.c, s.body))
        y += 19pt
      }
    }
  })))
}

// ---------- command reference card ----------------------------------
#let cmdlab(s) = text(weight: 700, size: 6.2pt, fill: gray,
  tracking: 0.4pt, upper(s))
#let cmd(name, code: "", dev: "", nparam: "", params: "none",
         payload: "none", reply: "none", asm: none, c: none,
         body) = block(width: 100%, above: 1.0em, below: 1.0em,
  breakable: true, {
  block(breakable: false, sticky: true, width: 100%, fill: panel,
    stroke: (left: 2.5pt + violet, rest: 0.5pt + panel-b),
    inset: (x: 7pt, y: 5.5pt), {
    grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
      text(weight: 700, size: 9.4pt, fill: ink, name),
      text(font: f-mono, weight: 700, size: 8.2pt, fill: violet, code))
    v(4pt)
    set par(justify: false, first-line-indent: 0pt)
    grid(columns: (40pt, 1fr, 40pt, 1fr), row-gutter: 4pt, column-gutter: 5pt,
      cmdlab("device"),  text(font: f-mono, size: 7.2pt, dev),
      cmdlab("nparam"),  text(font: f-mono, size: 7.2pt, nparam),
      cmdlab("params"),  grid.cell(colspan: 3, text(size: 7.5pt, params)),
      cmdlab("payload"), grid.cell(colspan: 3, text(size: 7.5pt, payload)),
      cmdlab("reply"),   grid.cell(colspan: 3, text(size: 7.5pt, reply)))
  })
  v(3pt)
  set par(first-line-indent: 0pt)
  body
  if asm != none or c != none { pair(asm, c) }
})

// A listing line with a very long space-free token cannot wrap and would
// run off the page. Zero-width spaces after the separators inside such
// tokens give it somewhere to break; nothing visible changes.
#let softbreak(src) = src.split("\n").map(l =>
  l.split(" ").map(t =>
    if t.len() > 44 {
      t.replace(",", ",\u{200b}").replace("=", "=\u{200b}").replace("/", "/\u{200b}")
    } else { t }).join(" ")).join("\n")

// ---------- unnumbered sub-heads ------------------------------------
#let sect(t) = heading(level: 2, numbering: none, t)
#let sub(t) = heading(level: 3, numbering: none, t)

// ---------- excerpts of the verified listings -----------------------
// Lines a..b (1-based, inclusive) of a file under listings/, as a panel, so
// a chapter quotes the program that was actually built and run.
#let excerpt(title, path, a, b, size: 6.8pt) = {
  let lines = read(path).split("\n")
  let slice = lines.slice(a - 1, calc.min(b, lines.len()))
  codepanel(title, slice.join("\n"), size: size)
}
// Lines from the first line containing `from` up to (not including) the first
// later line containing `to` (or `n` lines when `to` is none).
#let excerpt-at(title, path, from, to: none, n: 30, size: 6.8pt, skip: 0) = {
  let lines = read(path).split("\n")
  let a = -1
  let i = 0
  for l in lines {
    if a < 0 and l.contains(from) { a = i }
    i += 1
  }
  if a < 0 { panic("excerpt-at: marker not found: " + from) }
  a += skip
  let b = a + n
  if to != none {
    let j = a + 1
    let found = -1
    for l in lines.slice(a + 1) {
      if found < 0 and l.contains(to) { found = j }
      j += 1
    }
    if found >= 0 { b = found }
  }
  codepanel(title, lines.slice(a, calc.min(b, lines.len())).join("\n"), size: size)
}

// ---------- two-up listing for the appendices -----------------------
#let listing2(title, path, size: 4.6pt) = block(width: 100%, breakable: true, {
  block(breakable: false, above: 0.9em, below: 3pt, sticky: true, {
    text(weight: 700, size: 7.6pt, fill: violet, title)
    v(2pt)
    line(length: 100%, stroke: 0.8pt + ink)
  })
  block(width: 100%, fill: panel, inset: (x: 3pt, y: 3pt),
    columns(2, gutter: 8pt, {
    let src = softbreak(read(path))
    show raw.where(block: true): it => block(width: 100%, breakable: true,
      fill: none, inset: 0pt, stroke: none,
      text(font: f-mono, size: size, fill: ink, it.lines.join(parbreak())))
    show raw.line: it => {
      box(width: 10pt, align(right, text(size: size * 0.8, fill: gray, str(it.number))))
      h(2pt)
      it.body
    }
    // one paragraph per line: a wrapped line continues past the gutter
    set par(justify: false, leading: 0.32em, spacing: 0.32em,
      hanging-indent: 12pt, first-line-indent: 0pt)
    raw(src, block: true)
  }))
})

// ---------- both roads, quoted from the verified programs -----------
// Each argument is a dictionary for excerpt-at: (path:, from:, to:, n:,
// skip:). The panel is titled with the language and the file it quotes.
#let ex(spec, lang, size: 6.6pt) = excerpt-at(
  lang + "  ·  " + spec.path.split("/").last(), spec.path, spec.from,
  to: spec.at("to", default: none), n: spec.at("n", default: 30),
  size: spec.at("size", default: size), skip: spec.at("skip", default: 0))
#let pair-at(asm: none, c: none) = block(above: 0.8em,
  below: 0.9em, breakable: true, {
  if asm != none { ex(asm, t-asm) }
  if c != none { ex(c, t-c) }
})

// ---------- block diagram nodes -------------------------------------
#let nodebox(title, sub: none, fill: panel, w: auto) = box(width: w, fill: fill,
  inset: (x: 6pt, y: 4.5pt), stroke: 0.7pt + ink,
  align(center, {
    text(weight: 700, size: 7.2pt, title)
    if sub != none { v(2pt, weak: true); text(font: f-mono, size: 6.2pt, fill: gray, sub) }
  }))
#let rarrow(w: 18pt, label: none) = box(width: w, height: 12pt, baseline: 4pt, {
  place(left + horizon, line(length: w - 5pt, stroke: 0.8pt + ink))
  place(left + horizon, dx: w - 6pt, polygon(fill: ink, (0pt, -2.5pt), (5pt, 0pt), (0pt, 2.5pt)))
  if label != none { place(center + bottom, dy: -8pt, text(size: 5.4pt, label)) }
})
#let flow(..items) = align(center, block(above: 0.7em, below: 0.6em,
  breakable: false, stack(dir: ltr, spacing: 0pt, ..items.pos())))

// ---------- the rainbow ---------------------------------------------
// The stripe across both covers.
#let rainbow = gradient.linear(
  (rgb("#e8553f"), 0%), (rgb("#d9567f"), 18%), (rgb("#9a5cb8"), 34%),
  (rgb("#5a6fcf"), 50%), (rgb("#3fa3b5"), 62%), (rgb("#5cbb62"), 76%),
  (rgb("#b9cf4c"), 88%), (rgb("#ecd447"), 100%))
