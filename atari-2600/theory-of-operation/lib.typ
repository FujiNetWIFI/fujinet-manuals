// lib.typ -- FujiNet Engineering Series preamble and diagram helpers for
// "FujiNet for the Atari 2600: Theory of Operation".
//
// The page style follows firmware-platform-bringup-guide/manual.typ; the
// memory-map, sequence and TV-mockup helpers are ported from the Atari 2600
// Programmer's Handbook (atari-2600/programmers-handbook/lib.typ), restyled.

#let f-head = "Nimbus Sans"
#let f-body = "Nimbus Roman"
#let f-mono = "Source Code Pro"
#let f-screen = "VCS Screen"

// ---------- palette ---------------------------------------------------
#let ink     = rgb("#1c1c1e")
#let paper   = rgb("#ffffff")
#let fuji    = rgb("#b62a1c")
#let fuji-d  = rgb("#7f1d12")
#let slate   = rgb("#2f4858")
#let steel   = rgb("#41607a")
#let rule-c  = rgb("#c9ccd1")
#let code-bg = rgb("#f5f6f8")
#let code-bd = rgb("#dfe2e7")
#let note-bg = rgb("#eef3f6")
#let tip-bg  = rgb("#eef5ee")
#let warn-bg = rgb("#fbeeec")
#let amber   = rgb("#a6701a")
#let amber-bg= rgb("#fbf3e3")
#let gray    = rgb("#6b6b6b")
#let panel   = rgb("#f1f1ee")
#let panel-b = rgb("#d9d9d4")
// region colours for the memory map and block diagrams
#let c-code  = rgb("#d6e4c2")
#let c-text  = rgb("#cfe5ef")
#let c-reply = rgb("#f6dcb8")
#let c-ctl   = rgb("#f1c2bb")
#let c-tx    = rgb("#dccbe6")
#let c-stat  = rgb("#e9c8dc")
#let c-rp    = rgb("#e4e9ee")
#let c-esp   = rgb("#e6eee4")
#let c-con   = rgb("#f3ead6")
#let scr-bg  = rgb("#000000")
#let scr-fg  = rgb("#f0f0f0")

#let chapstate = state("chap", "")
#let frontmatter = state("fm", true)

// ---------- headings --------------------------------------------------
#let heading-rules(body) = {
  set heading(numbering: "1.1.1")
  set heading(supplement: [Chapter])
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    chapstate.update(upper(it.body))
    v(0.35in)
    block(width: 100%, {
      text(font: f-head, weight: 700, size: 11pt, fill: fuji,
        tracking: 2pt)[CHAPTER #context counter(heading).display("1")]
      v(6pt, weak: true)
      text(font: f-head, weight: 700, size: 23pt, fill: ink, it.body)
      v(7pt, weak: true)
      line(length: 100%, stroke: 2pt + fuji)
    })
    v(0.28in)
  }
  show heading.where(level: 2): it => {
    v(1.1em, weak: true)
    block(below: 0.6em, {
      text(font: f-head, weight: 700, size: 13.5pt, fill: slate,
        [#context counter(heading).display("1.1")#h(10pt)#it.body])
    })
  }
  show heading.where(level: 3): it => {
    v(0.8em, weak: true)
    block(below: 0.45em,
      text(font: f-head, weight: 700, size: 11pt, fill: steel,
        [#context counter(heading).display("1.1.1")#h(8pt)#it.body]))
  }
  show heading.where(level: 4): it => {
    v(0.6em, weak: true)
    block(below: 0.35em,
      text(font: f-head, weight: 700, size: 10pt, fill: ink, it.body))
  }
  body
}

// appendix restyle: level-1 headings become "APPENDIX A"
#let appendix-rules(body) = {
  counter(heading).update(0)
  set heading(numbering: "A.1")
  set heading(supplement: [Appendix])
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    chapstate.update(upper(it.body))
    v(0.35in)
    block(width: 100%, {
      text(font: f-head, weight: 700, size: 11pt, fill: fuji,
        tracking: 2pt)[APPENDIX #context counter(heading).display("A")]
      v(6pt, weak: true)
      text(font: f-head, weight: 700, size: 23pt, fill: ink, it.body)
      v(7pt, weak: true)
      line(length: 100%, stroke: 2pt + fuji)
    })
    v(0.28in)
  }
  body
}

// ---------- callouts --------------------------------------------------
#let callout(label, body, bg, bar, lc: ink) = block(
  width: 100%, above: 0.95em, below: 0.95em, breakable: true,
  fill: bg, inset: (x: 10pt, y: 8pt),
  stroke: (left: 3pt + bar, rest: none),
  {
    text(font: f-head, weight: 700, size: 8.5pt, fill: lc, tracking: 0.6pt,
      upper(label))
    v(3pt, weak: true)
    set par(leading: 0.6em, justify: true)
    body
  })
#let note(body)      = callout("Note", body, note-bg, steel, lc: slate)
#let tip(body)       = callout("Tip", body, tip-bg, rgb("#3f7d3f"), lc: rgb("#2f5d2f"))
#let important(body) = callout("Important", body, amber-bg, amber, lc: amber)
#let caution(body)   = callout("Caution", body, amber-bg, amber, lc: amber)
#let finding(n, body) = callout("Finding " + str(n) + " · unverified on hardware", body, warn-bg, fuji, lc: fuji-d)

// ---------- status tags -----------------------------------------------
// Every quantitative claim in this document carries one of these.
#let tag(txt, col) = box(fill: col.lighten(78%), stroke: 0.5pt + col,
  inset: (x: 4pt, y: 1.5pt), radius: 2pt, baseline: 18%,
  text(font: f-head, weight: 700, size: 6.6pt, fill: col.darken(20%), tracking: 0.4pt, upper(txt)))
#let v-emu   = tag("verified in emulation", rgb("#3f7d3f"))
#let v-host  = tag("host test", rgb("#3f7d3f"))
#let v-cad   = tag("verified in CAD", rgb("#3f7d3f"))
#let v-design= tag("design value, unmeasured", amber)
#let v-none  = tag("not yet implemented", fuji)
#let v-code  = tag("as written in source", steel)

// ---------- figures / tables / listings -------------------------------
#let fig(body, caption) = figure(
  block(width: 100%, inset: 7pt, stroke: 0.6pt + rule-c, radius: 2pt, body),
  caption: caption, kind: "fig", supplement: [Figure])
#let listed(body, caption) = figure(body, caption: caption,
  kind: "lst", supplement: [Listing])
#let tbl(body, caption) = figure(body, caption: caption,
  kind: table, supplement: [Table])

// plain table builder: tab((cols), th[..], ..., [cell], ...)
#let th(s) = text(font: f-head, weight: 700, size: 8.6pt, fill: white, s)
#let tab(cols, ..rows, align: left, size: 8.6pt) = {
  set text(size: size)
  set par(justify: false)
  table(columns: cols, align: align + top, ..rows.pos().flatten())
}

// a source citation, set small and grey
#let src(s) = text(font: f-mono, size: 7.4pt, fill: gray, s)
#let kbd(s) = box(fill: rgb("#ececec"), inset: (x: 4pt, y: 1pt), radius: 2pt,
  stroke: 0.5pt + rgb("#bdbdbd"), text(font: f-head, size: 8pt, s))

// ---------- byte-field strip ------------------------------------------
#let bytefield(..cells) = {
  let cs = cells.pos()
  align(center, block(above: 0.6em, below: 0.4em,
    grid(columns: cs.map(c => c.at(1)), rows: auto, stroke: 0.7pt + slate,
      ..cs.map(c => grid.cell(inset: 5pt, align: center,
        text(font: f-mono, size: 8pt, fill: ink, c.at(0)))))))
}

// ---------- memory map --------------------------------------------------
// rows: (from, to, label, colour, note)
#let memmap(rows, w: 1.6in, scale: 0.028pt, minh: 16pt) = {
  let boxes = rows.map(r => {
    let h = calc.max(minh, (r.at(1) - r.at(0) + 1) * scale)
    grid(columns: (0.62in, w, 1fr), column-gutter: 8pt,
      align: (right + top, left + top, left + top),
      text(font: f-mono, size: 7.6pt, "$" + upper(str(r.at(0), base: 16))),
      box(width: w, height: h, fill: r.at(3), stroke: 0.7pt + ink,
        align(center + horizon, text(font: f-head, weight: 700, size: 7.4pt,
          fill: ink, r.at(2)))),
      text(size: 8pt, r.at(4)))
  })
  align(center, block(above: 0.4em, below: 0.4em, breakable: false,
    stack(dir: ttb, spacing: 0pt, ..boxes,
      v(5pt),
      grid(columns: (0.62in, w, 1fr), column-gutter: 8pt,
        align: (right + top, left + top, left + top),
        text(font: f-mono, size: 7.6pt,
          "$" + upper(str(rows.last().at(1) + 1, base: 16))), [], []))))
}

// ---------- sequence diagrams -----------------------------------------
#let msg(from, to, body, dashed: false, c: ink) = (
  kind: "msg", from: from, to: to, body: body, dashed: dashed, c: c)
#let snote(lane, body, span: 1, fill: panel, bd: gray) = (
  kind: "note", lane: lane, span: span, body: body, fill: fill, bd: bd)
#let sgap(h: 8pt) = (kind: "gap", h: h)
#let seq(actors, ..steps, w: 330pt) = {
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

// ---------- block diagram nodes ---------------------------------------
#let nodebox(title, sub: none, fill: panel, w: auto, h: auto) = box(width: w, height: h, fill: fill,
  inset: (x: 7pt, y: 5pt), stroke: 0.7pt + ink, radius: 2pt,
  align(center + horizon, {
    set par(justify: false)
    text(font: f-head, weight: 700, size: 7.8pt, title)
    if sub != none { v(2pt, weak: true); text(font: f-mono, size: 6.4pt, fill: gray, sub) }
  }))
#let biarrow(w: 26pt, label: none, one: false) = box(width: w, height: 14pt, baseline: 5pt, {
  place(left + horizon, dx: 4pt, line(length: w - 8pt, stroke: 0.8pt + ink))
  if not one { place(left + horizon, dx: 0pt, polygon(fill: ink, (4pt, -2.5pt), (0pt, 0pt), (4pt, 2.5pt))) }
  place(left + horizon, dx: w - 6pt, polygon(fill: ink, (0pt, -2.5pt), (4pt, 0pt), (0pt, 2.5pt)))
  if label != none { place(center + bottom, dy: -9pt, text(font: f-head, size: 5.6pt, fill: gray, label)) }
})
#let flow(..items) = align(center, block(above: 0.5em, below: 0.5em,
  breakable: false, stack(dir: ltr, spacing: 0pt, ..items.pos())))

// ---------- TV mockup in the cartridge's font -------------------------
#let tv(txt, size: 7.2pt, fg: scr-fg, w: 2.4in) = box(
  fill: rgb("#d8d8d2"), radius: 5pt, inset: 6pt, stroke: 0.8pt + ink,
  box(fill: scr-bg, radius: 2pt, inset: (x: 9pt, y: 8pt), width: w - 12pt,
    align(left, {
      set par(leading: 0.42em, first-line-indent: 0pt, justify: false)
      text(font: f-screen, size: size, fill: fg,
        txt.split("\n").map(l => if l == "" { " " } else { l }).join(linebreak()))
    })))

// ---------- layer-stack table ---------------------------------------
#let layers(..rows) = {
  set text(font: f-head, size: 8.3pt)
  set par(justify: false)
  let row(n, name, who, what) = (
    grid.cell(fill: slate, inset: 6pt, text(fill: white, weight: 700, n)),
    grid.cell(inset: 6pt, strong(name)),
    grid.cell(inset: 6pt, text(fill: steel, who)),
    grid.cell(inset: 6pt, text(size: 7.8pt, what)),
  )
  grid(columns: (auto, auto, auto, 1fr), stroke: 0.5pt + rule-c,
    grid.cell(fill: ink, inset: 6pt, text(fill: white, weight: 700)[#h(2pt)]),
    grid.cell(fill: ink, inset: 6pt, text(fill: white, weight: 700)[Layer]),
    grid.cell(fill: ink, inset: 6pt, text(fill: white, weight: 700)[Owner]),
    grid.cell(fill: ink, inset: 6pt, text(fill: white, weight: 700)[Responsibility]),
    ..rows.pos().map(r => row(..r)).flatten())
}

// ---------- timing diagram --------------------------------------------
// signals: list of (name, segments) where a segment is (t0, t1, kind, label)
// kind: "hi" | "lo" | "valid" | "x" (transition) | "z" (undriven) | "act" (activity bar)
#let timing(signals, t-end, w: 420pt, ticks: (), caption-ticks: "ns") = {
  let lab-w = 78pt
  let rowh = 22pt
  let sig-h = 12pt
  let px(t) = lab-w + (w - lab-w) * (t / t-end)
  let n = signals.len()
  let tot-h = rowh * n + 24pt
  align(center, block(breakable: false, above: 0.6em, below: 0.4em,
    box(width: w, height: tot-h, {
      // tick grid
      for tk in ticks {
        place(top + left, dx: px(tk.at(0)), dy: 0pt,
          line(start: (0pt, 0pt), end: (0pt, rowh * n + 2pt),
            stroke: (paint: rule-c, thickness: 0.5pt, dash: "dotted")))
        place(top + left, dx: px(tk.at(0)) - 20pt, dy: rowh * n + 4pt,
          box(width: 40pt, align(center, text(font: f-mono, size: 6.4pt, fill: gray, tk.at(1)))))
      }
      let i = 0
      for s in signals {
        let y0 = rowh * i + 4pt
        place(top + left, dx: 0pt, dy: y0 + 1pt,
          box(width: lab-w - 6pt, align(right, text(font: f-head, size: 7.2pt, s.at(0)))))
        for g in s.at(1) {
          let x0 = px(g.at(0)); let x1 = px(g.at(1)); let k = g.at(2)
          let lbl = if g.len() > 3 { g.at(3) } else { none }
          if k == "hi" {
            place(top + left, dx: x0, dy: y0, line(start: (0pt, 0pt), end: (x1 - x0, 0pt), stroke: 0.9pt + ink))
          } else if k == "lo" {
            place(top + left, dx: x0, dy: y0 + sig-h, line(start: (0pt, 0pt), end: (x1 - x0, 0pt), stroke: 0.9pt + ink))
          } else if k == "valid" {
            place(top + left, dx: x0, dy: y0, rect(width: x1 - x0, height: sig-h, stroke: 0.9pt + ink, fill: white))
            if lbl != none { place(top + left, dx: x0, dy: y0, box(width: x1 - x0, height: sig-h, align(center + horizon, text(font: f-mono, size: 6.2pt, lbl)))) }
          } else if k == "x" {
            place(top + left, dx: x0, dy: y0, rect(width: x1 - x0, height: sig-h, stroke: 0.6pt + gray, fill: tiling(size: (4pt, 4pt), line(start: (0pt, 4pt), end: (4pt, 0pt), stroke: 0.5pt + gray))))
          } else if k == "z" {
            place(top + left, dx: x0, dy: y0 + sig-h / 2, line(start: (0pt, 0pt), end: (x1 - x0, 0pt), stroke: (paint: gray, thickness: 0.7pt, dash: "dashed")))
            if lbl != none { place(top + left, dx: x0, dy: y0 - 1pt, box(width: x1 - x0, align(center, text(font: f-head, size: 5.8pt, fill: gray, lbl)))) }
          } else if k == "act" {
            place(top + left, dx: x0, dy: y0 + 1pt, rect(width: x1 - x0, height: sig-h - 2pt, stroke: 0.6pt + steel, fill: note-bg, radius: 1.5pt))
            if lbl != none { place(top + left, dx: x0, dy: y0 + 1pt, box(width: x1 - x0, height: sig-h - 2pt, align(center + horizon, text(font: f-head, size: 5.8pt, fill: slate, lbl)))) }
          } else if k == "edge" {
            place(top + left, dx: x0, dy: y0, line(start: (0pt, 0pt), end: (0pt, sig-h), stroke: 0.9pt + ink))
          }
        }
        i += 1
      }
    })))
}

// ---------- part divider ------------------------------------------------
#let part(num, title, blurb) = {
  pagebreak(weak: true)
  [#metadata("pd") <partdiv>]
  v(1fr)
  block(width: 100%, {
    text(font: f-head, weight: 700, size: 12pt, fill: fuji, tracking: 3pt)[PART #num]
    v(10pt, weak: true)
    text(font: f-head, weight: 700, size: 30pt, fill: ink, title)
    v(14pt, weak: true)
    line(length: 40%, stroke: 2.5pt + fuji)
    v(12pt, weak: true)
    set par(leading: 0.65em)
    text(size: 11pt, fill: slate, blurb)
  })
  v(2fr)
  pagebreak(weak: true)
}

// ---------- code panel with a title ----------------------------------
#let codepanel(title, body) = block(width: 100%, breakable: true, above: 0.8em, below: 0.9em, {
  block(breakable: false, below: 3pt, sticky: true,
    text(font: f-head, weight: 700, size: 7.5pt, fill: gray, tracking: 0.5pt, upper(title)))
  body
})
