// lib.typ -- helpers for the FujiNet Atari 2600 Programmer's Handbook.
//
// House style: the 1977 Atari "Video Computer System Owner's Manual" --
// a half-letter booklet, Helvetica, numbered colour section bands with the
// numeral in a black block at the outer edge of the page, bold NOTE and
// IMPORTANT paragraphs between thin blue rules, round bullets, lettered
// steps, a SYMPTOM / PROBABLE CAUSE AND REMEDY table with a blue divider,
// and a PARTS LIST at the end. Ragged right throughout: no rivers.

// ---------- fonts ---------------------------------------------------
#let f-body   = "Helvetica"
#let f-head   = "Helvetica"
#let f-ital   = "Nimbus Sans"          // Helvetica has no oblique here
#let f-mono   = "Source Code Pro"
#let f-wordmk = "Harry"                // Harry Fat: the cover and the numerals
#let f-screen = "VCS Screen"           // the cartridge's own 3x5 font

// ---------- palette (the 1977 booklet) ------------------------------
#let ink     = rgb("#111111")
#let paper   = rgb("#fdfcf8")
#let blue    = rgb("#2ea3d9")          // the thin rules
#let gray    = rgb("#6b6b6b")
#let panel   = rgb("#f1f1ee")
#let panel-b = rgb("#d9d9d4")
#let lime    = rgb("#b5cd3a")
#let cyan    = rgb("#2aa8de")
#let orange  = rgb("#f5901f")
#let red     = rgb("#e6402a")
#let green   = rgb("#4aa64a")
#let purple  = rgb("#7b3f98")
#let magenta = rgb("#c22a7f")
#let bands   = (lime, cyan, orange, red, green, purple, magenta)
#let scr-bg  = rgb("#000000")
#let scr-fg  = rgb("#f0f0f0")

// the colour of the section we are in, for panels and figures
#let band-col = state("band-col", cyan)
#let appendix = state("apx", false)
#let frontmatter = state("fm", true)

// ---------- section bands (level-1 headings) ------------------------
// The numeral sits in a black block at the OUTER edge: left on even pages,
// right on odd ones, as the booklet does. Colours cycle through the seven
// the booklet used.
#let band(n, title, col, letter: false) = context {
  let pg = counter(page).get().first()
  let odd = calc.odd(pg)
  let numeral = box(fill: ink, width: 30pt, height: 24pt,
    align(center + horizon, text(font: f-wordmk, weight: 900, size: 17pt,
      fill: white, if letter { n } else { str(n) })))
  let ttl = text(font: f-head, weight: 700, size: 12.5pt, fill: ink,
    tracking: 0.3pt, upper(title))
  block(width: 100%, above: 0pt, below: 14pt, breakable: false,
    if odd {
      grid(columns: (1fr, auto), align: (right + horizon, right + horizon),
        box(fill: col, height: 24pt, width: 100%,
          align(right + horizon, pad(right: 8pt, ttl))),
        numeral)
    } else {
      grid(columns: (auto, 1fr), align: (left + horizon, left + horizon),
        numeral,
        box(fill: col, height: 24pt, width: 100%,
          align(left + horizon, pad(left: 8pt, ttl))))
    })
}

// ---------- callouts ------------------------------------------------
// NOTE: and IMPORTANT: are set entirely in bold between two thin blue
// rules -- the booklet's signature.
#let callout(label, body) = block(width: 100%, above: 0.9em, below: 0.9em,
  breakable: false, {
  line(length: 100%, stroke: 0.7pt + blue)
  v(4pt)
  block(inset: (x: 2pt), {
    set par(justify: false, leading: 0.42em, first-line-indent: 0pt)
    set text(weight: 700)
    [#label: #body]
  })
  v(4pt)
  line(length: 100%, stroke: 0.7pt + blue)
})
#let note(body) = callout("NOTE", body)
#let important(body) = callout("IMPORTANT", body)
#let caution(body) = callout("CAUTION", body)

// ---------- lists ---------------------------------------------------
#let steps(..items) = enum(numbering: "A.", spacing: 0.45em, tight: false,
  ..items.pos())

// ---------- code ----------------------------------------------------
#let mono(s, size: 0.9em) = text(font: f-mono, size: size, s)
#let hx(s) = text(font: f-mono, size: 0.9em, s)
// A code line never wraps: the panel picks the largest size at which its
// longest line still fits the measure (about 300pt inside the insets).
#let codesize(txt, size) = {
  let longest = calc.max(1, ..txt.split("\n").map(l => l.len()))
  calc.min(size, 300pt / (longest * 0.62))
}
#let codeblock(txt, size: 7pt) = context block(width: 100%, breakable: true,
  above: 0.8em, below: 0.9em, fill: panel, inset: (x: 8pt, y: 6pt),
  stroke: (left: 2pt + band-col.get(), rest: 0.5pt + panel-b), {
    set par(justify: false, leading: 0.36em, first-line-indent: 0pt)
    set text(font: f-mono, size: codesize(txt, size), fill: ink)
    txt.split("\n").map(l => if l == "" { " " } else { l }).join(linebreak())
  })
#let codepanel(title, txt, size: 7pt) = block(above: 0.9em, below: 0.9em,
  breakable: true, {
  block(breakable: false, below: 3pt, sticky: true,
    text(font: f-head, weight: 700, size: 7.5pt, fill: gray, tracking: 0.5pt,
      upper(title)))
  codeblock(txt, size: size)
})
// The two roads, one under the other: the page is too narrow for two
// columns of assembler.
#let pair(asm, bas, size: 6.9pt, asm-title: "6502 ASSEMBLY",
          bas-title: "batari BASIC") = block(above: 0.8em, below: 0.9em,
  breakable: true, {
  if asm != none { codepanel(asm-title, asm, size: size) }
  if bas != none { codepanel(bas-title, bas, size: size) }
})

// ---------- figures -------------------------------------------------
#let fig-n = counter("figure")
#let fig(body, caption: none) = block(width: 100%, above: 0.9em, below: 1.0em,
  breakable: false, {
  fig-n.step()
  align(center, body)
  v(4pt)
  set par(justify: false)
  align(center, text(size: 8pt, {
    text(weight: 700)[Figure #context fig-n.display().]
    if caption != none { [ #caption] }
  }))
})
// a real screen from the FujiNet MAME, kept at hard pixels
#let shot(name, w: 2.2in, caption: none) = fig(
  box(stroke: 0.6pt + ink, image("images/screens/" + name + ".png", width: w)),
  caption: caption)

// ---------- TV mockup in the cartridge's font -----------------------
#let tv(txt, size: 7.2pt, fg: scr-fg, w: 2.4in) = box(
  fill: rgb("#d8d8d2"), radius: 5pt, inset: 6pt, stroke: 0.8pt + ink,
  box(fill: scr-bg, radius: 2pt, inset: (x: 9pt, y: 8pt), width: w - 12pt,
    align(left, {
      set par(leading: 0.42em, first-line-indent: 0pt, justify: false)
      text(font: f-screen, size: size, fill: fg,
        txt.split("\n").map(l => if l == "" { " " } else { l }).join(linebreak()))
    })))

// ---------- keycaps and switches ------------------------------------
#let key(s) = box(baseline: 20%, stroke: 0.6pt + ink, inset: (x: 3pt, y: 1pt),
  radius: 1.5pt, text(font: f-head, weight: 700, size: 7pt, s))

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
      text(weight: 700)[SYMPTOM], text(weight: 700)[PROBABLE CAUSE AND REMEDY]),
    ..rows.pos().map(r => (r.at(0), r.at(1))).flatten())
})

// ---------- plain tables --------------------------------------------
#let tbl(cols, ..rows, align: left) = block(above: 0.7em, below: 0.9em, {
  set par(justify: false, first-line-indent: 0pt)
  set text(size: 8.2pt)
  table(columns: cols, align: align + top, inset: (x: 5pt, y: 4pt),
    stroke: (x, y) => (
      top: if y == 0 { 0.8pt + ink } else { 0.4pt + panel-b },
      bottom: 0.8pt + ink),
    ..rows.pos().flatten())
})
#let th(s) = text(weight: 700, s)

// ---------- dot-leader definition rows (the parts list) -------------
#let dotdef(..rows) = {
  set par(first-line-indent: 0pt, justify: false)
  grid(columns: (1.15fr, 1fr), row-gutter: 5pt, column-gutter: 8pt,
    align: (left + top, left + top),
    ..rows.pos().map(r => (
      box(width: 100%, {
        text(size: 8.6pt, r.at(0))
        box(width: 1fr, repeat(text(size: 8.6pt)[.], gap: 2pt))
      }),
      text(font: f-mono, size: 7.4pt, r.at(1)))).flatten())
}

// ---------- byte-field strip ----------------------------------------
#let bytefield(..cells) = {
  let cs = cells.pos()
  align(center, block(above: 0.6em, below: 0.5em, breakable: false,
    grid(columns: cs.map(c => c.at(1)), stroke: 0.6pt + ink,
      ..cs.map(c => grid.cell(inset: 4pt, align: center,
        text(font: f-mono, size: 7.2pt, c.at(0)))))))
}

// ---------- memory map ----------------------------------------------
// rows: (from, to, label, colour, note). Drawn as a column of boxes with the
// addresses at the left and a note at the right; heights are proportional
// to size, with a floor so a one-page region still has room for its name.
#let memmap(rows, w: 1.55in, scale: 0.030pt, minh: 15pt, notes: true) = {
  let boxes = rows.map(r => {
    let h = calc.max(minh, (r.at(1) - r.at(0) + 1) * scale)
    grid(columns: (0.62in, w, if notes { 1fr } else { 0pt }),
      column-gutter: 6pt, align: (right + top, left + top, left + top),
      text(font: f-mono, size: 7pt, "$" + upper(str(r.at(0), base: 16))),
      box(width: w, height: h, fill: r.at(3), stroke: 0.7pt + ink,
        align(center + horizon, text(font: f-head, weight: 700, size: 7.2pt,
          fill: ink, r.at(2)))),
      if notes { text(size: 7.4pt, r.at(4)) } else { none })
  })
  align(center, block(above: 0.6em, below: 0.4em, breakable: false,
    stack(dir: ttb, spacing: 0pt, ..boxes,
      v(5pt),
      grid(columns: (0.62in, w, if notes { 1fr } else { 0pt }),
        column-gutter: 6pt, align: (right + top, left + top, left + top),
        text(font: f-mono, size: 7pt,
          "$" + upper(str(rows.last().at(1) + 1, base: 16))), [], []))))
}

// ---------- sequence diagrams ---------------------------------------
#let msg(from, to, body, dashed: false, c: ink) = (
  kind: "msg", from: from, to: to, body: body, dashed: dashed, c: c)
#let snote(lane, body, span: 1, fill: panel, bd: gray) = (
  kind: "note", lane: lane, span: span, body: body, fill: fill, bd: bd)
#let sgap(h: 8pt) = (kind: "gap", h: h)
#let seq(actors, ..steps, w: 300pt) = {
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
    box(width: w, height: toth, {
    for i in range(n) {
      place(top + left, dx: xs.at(i) - 0.4pt, dy: headh - 2pt,
        line(start: (0pt, 0pt), end: (0pt, bodyh + 6pt),
          stroke: (paint: gray, thickness: 0.6pt, dash: "dotted")))
    }
    for i in range(n) {
      place(top + left, dx: xs.at(i) - lane/2 + 4pt, dy: 0pt,
        box(width: lane - 8pt, height: 16pt, fill: actors.at(i).at(1),
          stroke: 0.7pt + ink,
          align(center + horizon, text(font: f-head, weight: 700, size: 6.8pt,
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
              text(font: f-head, size: 6.3pt, fill: ink, s.body))))
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
          text(font: f-mono, size: 6.3pt, fill: s.c, s.body))
        y += 19pt
      }
    }
  })))
}

// ---------- block diagram nodes -------------------------------------
#let nodebox(title, sub: none, fill: panel, w: auto) = box(width: w, fill: fill,
  inset: (x: 7pt, y: 5pt), stroke: 0.7pt + ink,
  align(center, {
    text(font: f-head, weight: 700, size: 7.6pt, title)
    if sub != none { v(2pt, weak: true); text(font: f-mono, size: 6.4pt, fill: gray, sub) }
  }))
#let biarrow(w: 22pt, label: none) = box(width: w, height: 12pt, baseline: 4pt, {
  place(left + horizon, dx: 4pt, line(length: w - 8pt, stroke: 0.8pt + ink))
  place(left + horizon, dx: 0pt, polygon(fill: ink, (4pt, -2.5pt), (0pt, 0pt), (4pt, 2.5pt)))
  place(left + horizon, dx: w - 6pt, polygon(fill: ink, (0pt, -2.5pt), (4pt, 0pt), (0pt, 2.5pt)))
  if label != none { place(center + bottom, dy: -8pt, text(font: f-head, size: 5.5pt, label)) }
})
#let flow(..items) = align(center, block(above: 0.7em, below: 0.6em,
  breakable: false, stack(dir: ltr, spacing: 0pt, ..items.pos())))

// ---------- command reference card ----------------------------------
#let cmdlab(s) = text(font: f-head, weight: 700, size: 6.4pt, fill: gray,
  tracking: 0.4pt, upper(s))
#let cmd(name, code: "", dev: "", nparam: "", params: "none",
         payload: "none", reply: "none", asm: none, bas: none, body) = block(
  width: 100%, above: 1.0em, below: 1.0em, breakable: true, {
  context block(breakable: false, sticky: true, width: 100%, fill: panel,
    stroke: (left: 2.5pt + band-col.get(), rest: 0.5pt + panel-b),
    inset: (x: 8pt, y: 6pt), {
    grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
      text(font: f-head, weight: 700, size: 10pt, fill: ink, name),
      text(font: f-mono, weight: 700, size: 8.5pt, fill: ink, code))
    v(4pt)
    set par(justify: false, first-line-indent: 0pt)
    grid(columns: (44pt, 1fr, 44pt, 1fr), row-gutter: 4pt, column-gutter: 5pt,
      cmdlab("device"),  text(font: f-mono, size: 7.4pt, dev),
      cmdlab("nparam"),  text(font: f-mono, size: 7.4pt, nparam),
      cmdlab("params"),  grid.cell(colspan: 3, text(size: 7.8pt, params)),
      cmdlab("payload"), grid.cell(colspan: 3, text(size: 7.8pt, payload)),
      cmdlab("reply"),   grid.cell(colspan: 3, text(size: 7.8pt, reply)))
  })
  v(3pt)
  set par(first-line-indent: 0pt)
  body
  if asm != none or bas != none { pair(asm, bas) }
})


// A listing line with a very long space-free token -- a 400-character
// command-line argument, say -- cannot wrap and would run off the page.
// Zero-width spaces after the separators inside such tokens give the line
// somewhere to break; nothing visible changes.
#let softbreak(src) = src.split("\n").map(l =>
  l.split(" ").map(t =>
    if t.len() > 48 {
      t.replace(",", ",\u{200b}").replace("=", "=\u{200b}").replace("/", "/\u{200b}")
    } else { t }).join(" ")).join("\n")

// ---------- listing appendix renderer -------------------------------
#let co(n) = box(baseline: 22%, circle(radius: 4pt, stroke: 0.8pt + red,
  align(center + horizon, text(font: f-head, weight: 700, size: 6pt,
    fill: red, str(n)))))
#let code-listing(title, path, size: 5.6pt, callouts: (:)) = {
  let src = softbreak(read(path))
  block(breakable: false, above: 1.0em, below: 3pt, sticky: true, {
    text(font: f-head, weight: 700, size: 8pt, tracking: 0.4pt, upper(title))
    v(2pt)
    line(length: 100%, stroke: 0.7pt + blue)
  })
  {
    show raw.where(block: true): it => block(width: 100%, breakable: true,
      fill: none, inset: 0pt, stroke: none,
      text(font: f-mono, size: size, fill: ink, it.lines.join(linebreak())))
    show raw.line: it => {
      box(width: 14pt, align(right,
        text(size: size * 0.8, fill: gray, str(it.number))))
      h(3pt)
      it.body
      if str(it.number) in callouts { h(2pt); co(callouts.at(str(it.number))) }
    }
    set par(justify: false, leading: 0.34em, hanging-indent: 14pt,
      first-line-indent: 0pt)
    raw(src, block: true)
  }
}

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
#let listing2(title, path, size: 4.9pt) = block(width: 100%, breakable: true, {
  block(breakable: false, above: 0.9em, below: 3pt, sticky: true, {
    text(font: f-head, weight: 700, size: 8pt, tracking: 0.4pt, upper(title))
    v(2pt)
    line(length: 100%, stroke: 0.7pt + blue)
  })
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
  })
})
