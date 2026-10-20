// lib.typ -- helpers for the FujiNet Atari 7800 Programmer's Handbook.
//
// House style: the 1986 ATARI 7800 ProSystem Owner's Manual -- a small
// booklet printed on graph paper, ITC Eras throughout, one spot colour
// (magenta) for the title tabs and the band across the foot of every page,
// square bullets, lettered steps, bold "Note:" lead-ins, and a
// Troubleshooting Checklist of Symptom / Probable Cause and Remedy.
// Ragged right throughout.

// ---------- fonts ---------------------------------------------------
#let f-body  = "ITC Eras Std Book"     // 400
#let f-bold  = "ITC Eras Std"          // Medium 500, Demi 600, Bold 700
#let f-ultra = "ITC Eras Std Ultra"    // 800, the cover
#let f-mono  = "Source Code Pro"

// ---------- palette (the 1986 booklet) ------------------------------
#let ink     = rgb("#141414")
#let paper   = rgb("#fcfbf8")
#let magenta = rgb("#b70e78")          // sampled from the scan's band
#let grid-c  = rgb("#cdc8c2")          // the graph paper
#let gray    = rgb("#6b6866")
#let panel   = rgb("#f2f0ec")
#let panel-b = rgb("#d9d5cf")
#let cover-g = rgb("#c9c4c0")          // the cover's grey half
// lane colours for diagrams, kept quiet next to the magenta
#let tint-a  = rgb("#f4d9ea")
#let tint-b  = rgb("#dfe7ef")
#let tint-c  = rgb("#efe6d6")
#let tint-d  = rgb("#e2eedd")

#let appendix = state("apx", false)
#let frontmatter = state("fm", true)

// ---------- the page: graph paper and the magenta band --------------
#let grid-pitch = 0.24in
#let band-h = 0.19in
#let graph(c: grid-c, w: 0.4pt) = tiling(size: (grid-pitch, grid-pitch), {
  place(top + left, line(start: (0pt, 0pt), end: (grid-pitch, 0pt), stroke: w + c))
  place(top + left, line(start: (0pt, 0pt), end: (0pt, grid-pitch), stroke: w + c))
})
#let page-bg = {
  place(top + left, rect(width: 100%, height: 100%, fill: graph()))
  place(bottom + left, rect(width: 100%, height: band-h, fill: magenta))
}
#let folio = context {
  let pg = counter(page).get().first()
  if frontmatter.get() { none } else {
    set text(font: f-body, size: 7.5pt, fill: ink)
    if calc.odd(pg) { align(right, str(pg)) } else { align(left, str(pg)) }
  }
}

// ---------- title tabs (level-1 headings) ---------------------------
// White Eras Demi in a magenta tab at the top left, as the booklet does.
// The chapter's number leads the tab, lighter, so cross-references work.
#let tab(n, title) = block(above: 0pt, below: 15pt, breakable: false,
  box(fill: magenta, inset: (x: 7pt, top: 5pt, bottom: 5.5pt),
    block(width: auto, {
      set par(leading: 0.32em, justify: false)
      set text(font: f-bold, weight: 600, size: 12.5pt, fill: white)
      if n != none {
        text(font: f-body, weight: 400, size: 11pt, fill: white.transparentize(15%), n)
        h(6pt)
      }
      title
    })))

// ---------- the opening letter --------------------------------------
// Each section's first paragraph opens with its first letter in bold.
#let ini(c) = text(font: f-bold, weight: 700, size: 1.12em, c)

// ---------- callouts: bold lead-ins, as the booklet sets them -------
#let callout(label, body) = block(width: 100%, above: 0.85em, below: 0.85em,
  breakable: false, {
  set par(justify: false, first-line-indent: 0pt)
  text(font: f-bold, weight: 600, label + ":")
  [ ]
  body
})
#let note(body) = callout("Note", body)
#let important(body) = callout("Important", body)
#let caution(body) = callout("Warning", body)

// ---------- lists ---------------------------------------------------
// The booklet's square bullet; Eras has no U+25A0, so it is drawn.
#let sq = box(baseline: -0.5pt, rect(width: 4.2pt, height: 4.2pt, fill: ink, stroke: none))
#let steps(..items) = enum(numbering: n => text(font: f-bold, weight: 600,
  numbering("A.", n)), spacing: 0.5em, tight: false, ..items.pos())
#let nsteps(..items) = enum(numbering: n => text(font: f-bold, weight: 600,
  numbering("1.", n)), spacing: 0.5em, tight: false, ..items.pos())

// ---------- code ----------------------------------------------------
#let mono(s, size: 0.9em) = text(font: f-mono, size: size, s)
#let hx(s) = text(font: f-mono, size: 0.9em, s)
// A code line never wraps: the panel picks the largest size at which its
// longest line still fits the measure (about 272pt inside the insets).
#let measure = 272pt
#let codesize(txt, size) = {
  let longest = calc.max(1, ..txt.split("\n").map(l => l.len()))
  calc.min(size, measure / (longest * 0.61))
}
// A short panel never breaks across pages; a long one may.
#let codeblock(txt, size: 7pt) = block(width: 100%,
  breakable: txt.split("\n").len() > 28,
  above: 0.8em, below: 0.9em, fill: panel, inset: (x: 7pt, y: 5.5pt),
  stroke: (left: 2pt + magenta, rest: 0.5pt + panel-b), {
    set par(justify: false, leading: 0.36em, first-line-indent: 0pt)
    set text(font: f-mono, size: codesize(txt, size), fill: ink)
    txt.split("\n").map(l => if l == "" { " " } else { l }).join(linebreak())
  })
#let codetitle(title) = block(breakable: false, below: 3pt, sticky: true,
  text(font: f-bold, weight: 600, size: 7pt, fill: gray, tracking: 0.4pt, title))
#let codepanel(title, txt, size: 7pt) = block(above: 0.9em, below: 0.9em,
  breakable: true, {
  codetitle(title)
  codeblock(txt, size: size)
})
// The three roads, one under the other: the page is too narrow for two
// columns of code, let alone three.
#let t-asm = "6502 ASSEMBLY (ca65)"
#let t-c   = "C (cc65 + fujinet-lib)"
#let t-bas = "7800basic"
#let trio(asm, c, bas, size: 6.9pt) = block(above: 0.8em, below: 0.9em,
  breakable: true, {
  if asm != none { codepanel(t-asm, asm, size: size) }
  if c != none { codepanel(t-c, c, size: size) }
  if bas != none { codepanel(t-bas, bas, size: size) }
})

// ---------- figures -------------------------------------------------
#let fig-n = counter("figure")
#let fig(body, caption: none) = block(width: 100%, above: 0.9em, below: 1.0em,
  breakable: false, {
  fig-n.step()
  align(center, body)
  v(4pt)
  set par(justify: false)
  align(center, text(size: 7.6pt, {
    text(font: f-bold, weight: 600)[Figure #context fig-n.display().]
    if caption != none { [ #caption] }
  }))
})
// a real screen from the FujiNet MAME, kept at hard pixels, in a bezel
#let tvframe(img, w) = box(fill: rgb("#2a2624"), inset: 4pt, radius: 3pt,
  box(clip: true, radius: 1pt, image(img, width: w)))
#let shot(name, w: 2.3in, caption: none) = fig(
  tvframe("images/screens/" + name + ".png", w), caption: caption)

// ---------- keycaps and switches ------------------------------------
#let key(s) = box(baseline: 20%, stroke: 0.6pt + ink, inset: (x: 3pt, y: 1pt),
  radius: 1.5pt, fill: paper, text(font: f-bold, weight: 600, size: 7pt, s))

// ---------- the Troubleshooting Checklist ---------------------------
// The booklet stacks them: a bold "Symptom", a bullet, then a bold
// "Probable Cause and Remedy" over square-bulleted causes.
#let symrem(..rows) = block(above: 0.6em, below: 0.8em, {
  set par(justify: false, first-line-indent: 0pt)
  for r in rows.pos() {
    let causes = if type(r.at(1)) == array { r.at(1) } else { (r.at(1),) }
    block(breakable: false, above: 1.0em, below: 0.4em, {
      block(below: 0.35em, text(font: f-bold, weight: 600)[Symptom])
      list(marker: sq, r.at(0))
      block(above: 0.55em, below: 0.35em,
        text(font: f-bold, weight: 600)[Probable Cause and Remedy])
      list(marker: sq, ..causes)
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
    fill: paper,
    stroke: (x, y) => (
      top: if y == 0 { 0.8pt + ink } else { 0.4pt + panel-b },
      bottom: 0.8pt + ink),
    table.header(..cells.slice(0, n)),
    ..cells.slice(n))
})
#let th(s) = text(font: f-bold, weight: 600, s)

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
    grid(columns: cs.map(c => c.at(1)), stroke: 0.6pt + ink, fill: paper,
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
        align(center + horizon, text(font: f-bold, weight: 600, size: 6.8pt,
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
#let seq(actors, ..steps, w: 280pt) = {
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
    box(width: w + 8pt, height: toth + 8pt, fill: paper, stroke: 0.5pt + panel-b,
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
          align(center + horizon, text(font: f-bold, weight: 600, size: 6.6pt,
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
              text(font: f-body, size: 6.2pt, fill: ink, s.body))))
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
#let cmdlab(s) = text(font: f-bold, weight: 600, size: 6.2pt, fill: gray,
  tracking: 0.4pt, upper(s))
#let cmd(name, code: "", dev: "", nparam: "", params: "none",
         payload: "none", reply: "none", asm: none, c: none, bas: none,
         body) = block(width: 100%, above: 1.0em, below: 1.0em,
  breakable: true, {
  block(breakable: false, sticky: true, width: 100%, fill: panel,
    stroke: (left: 2.5pt + magenta, rest: 0.5pt + panel-b),
    inset: (x: 7pt, y: 5.5pt), {
    grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
      text(font: f-bold, weight: 600, size: 9.6pt, fill: ink, name),
      text(font: f-mono, weight: 700, size: 8.2pt, fill: magenta, code))
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
  if asm != none or c != none or bas != none { trio(asm, c, bas) }
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
    text(font: f-bold, weight: 600, size: 7.6pt, title)
    v(2pt)
    line(length: 100%, stroke: 0.8pt + magenta)
  })
  block(width: 100%, fill: paper, inset: (x: 3pt, y: 3pt),
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

// ---------- the three roads, quoted from the verified programs ------
// Each argument is a dictionary for excerpt-at: (path:, from:, to:, n:,
// skip:). The panel is titled with the language and the file it quotes.
#let ex(spec, lang, size: 6.6pt) = excerpt-at(
  lang + "  ·  " + spec.path.split("/").last(), spec.path, spec.from,
  to: spec.at("to", default: none), n: spec.at("n", default: 30),
  size: spec.at("size", default: size), skip: spec.at("skip", default: 0))
#let trio-at(asm: none, c: none, bas: none) = block(above: 0.8em,
  below: 0.9em, breakable: true, {
  if asm != none { ex(asm, t-asm) }
  if c != none { ex(c, t-c) }
  if bas != none { ex(bas, t-bas) }
})

// ---------- block diagram nodes -------------------------------------
#let nodebox(title, sub: none, fill: panel, w: auto) = box(width: w, fill: fill,
  inset: (x: 6pt, y: 4.5pt), stroke: 0.7pt + ink,
  align(center, {
    text(font: f-bold, weight: 600, size: 7.2pt, title)
    if sub != none { v(2pt, weak: true); text(font: f-mono, size: 6.2pt, fill: gray, sub) }
  }))
#let rarrow(w: 18pt, label: none) = box(width: w, height: 12pt, baseline: 4pt, {
  place(left + horizon, line(length: w - 5pt, stroke: 0.8pt + ink))
  place(left + horizon, dx: w - 6pt, polygon(fill: ink, (0pt, -2.5pt), (5pt, 0pt), (0pt, 2.5pt)))
  if label != none { place(center + bottom, dy: -8pt, text(size: 5.4pt, label)) }
})
#let flow(..items) = align(center, block(above: 0.7em, below: 0.6em,
  breakable: false, stack(dir: ltr, spacing: 0pt, ..items.pos())))
