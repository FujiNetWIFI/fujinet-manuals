// lib.typ -- the house style: the 1979 Heathkit "Manual for the Digital
// Computer Model H88, Operation" (595-2268-02), done over for the FujiNet.
//
// Letter pages in two columns; a running head of the badge on the gutter side
// and a long rule out to "Page N-M" on the outer side; chapter titles in big
// Century Schoolbook Bold capitals at the top left, a good deal of white
// space, then centred section heads over balanced columns; "( )" check-off
// steps; NOTE:/CAUTION:/WARNING: run-ins; parts lists and tables in
// Helvetica; "PICTORIAL n-m" captions.

#let f-body = "C059"                       // URW Century Schoolbook
#let f-head = "Century Schoolbook"         // Monotype CS Bold (heads)
#let f-sans = "Helvetica"
#let f-scrn = "H19 Screen"                 // the H19's character ROM, 444-29

// the cover inks, eyedropped from the H88 Operation Manual
#let gold   = rgb("#d0a846")
#let brown  = rgb("#6c3500")
#let yellow = rgb("#fef069")
#let ink    = rgb("#1a1714")
#let phosphor = rgb("#dde6ee")             // P4 white, as FujiNet Go H89 draws it
#let tube   = rgb("#0b0c0b")

// ---------------------------------------------------------------- chapters
#let chap = state("chap", (num: none, title: "", start: 1))
#let pics = counter("pictorial")

// the badge: a lozenge with a double outline, a little antenna-and-waves
// device where the Heathkit badge has its atom, and FUJINET in open capitals
#let badge(w: 1.42in) = {
  let h = w * 0.19
  box(width: w, height: h, {
    place(rect(width: w, height: h, radius: h / 2, stroke: 0.9pt + ink, fill: white))
    place(dx: 0.045 * w, dy: 0.18 * h,
      rect(width: w - 0.09 * w, height: h * 0.64, radius: h * 0.32, stroke: 0.5pt + ink, fill: ink))
    // the device: a mast and three arcs
    place(dx: 0.11 * w, dy: 0.5 * h - 0.5pt, {
      let r = h * 0.2
      place(line(start: (0pt, -r * 0.9), end: (0pt, r * 0.9), stroke: 0.7pt + white))
      for (i, k) in ((1, 0.55), (2, 1.0), (3, 1.45)) {
        place(dx: -r * k, dy: -r * k, circle(radius: r * k, stroke: (paint: white, thickness: 0.45pt)))
      }
    })
    place(dx: 0.22 * w, dy: 0pt, box(width: 0.74 * w, height: h, align(center + horizon,
      text(font: f-head, weight: "bold", size: h * 0.56, tracking: 0.12em, fill: white,
        stroke: 0.25pt + ink)[FUJINET])))
  })
}

#let running-head() = context {
  // the chapter in force on this page: a chapter marker on the page itself
  // (the header is laid out before the page's body updates the state)
  let pg = here().page()
  let mk = query(<chapter>).filter(m => m.location().page() == pg)
  if mk.len() > 0 and mk.first().value.nohead { return }
  // a page left blank so the next chapter starts on the right: the chapter in
  // force has already ended (its end marker is on an earlier page)
  if mk.len() == 0 {
    let starts = query(<chapter>).filter(m => m.location().page() < pg)
    let ends = query(<chapter-end>).filter(m => m.location().page() < pg)
    if starts.len() > 0 and ends.len() > 0 and ends.last().location().page() >= starts.last().location().page() {
      return
    }
  }
  let c = if mk.len() > 0 { (num: mk.first().value.num, start: pg) } else { chap.get() }
  if c.num == none { return }
  let n = counter(page).get().first()
  let f = text(font: f-sans, size: 7.5pt, "Page " + str(c.num) + "-" + str(n - c.start + 1))
  let b = badge()
  let bw = measure(b).width
  let bh = measure(b).height
  // the H88: odd pages carry the badge at the left (the gutter) and the folio
  // at the right; the rule runs out of the badge's middle to the far edge
  box(width: 100%, height: bh + 9pt, {
    let ry = 9pt + bh / 2
    if calc.odd(n) {
      place(dx: bw - 1pt, dy: ry - 0.6pt, line(length: 100% - bw + 1pt, stroke: 1.2pt + ink))
      place(dy: 9pt, b)
      place(right + top, dy: ry - 11pt, f)
    } else {
      place(dy: ry - 0.6pt, line(length: 100% - bw + 1pt, stroke: 1.2pt + ink))
      place(right + top, dy: 9pt, b)
      place(left + top, dy: ry - 11pt, f)
    }
  })
}

// Chapter numbering: a <chapter> marker starts the "Page N-M" count on its
// page. (The H88's title page is page 1-1 and carries no head.)
#let chap-start(num, nohead: false) = {
  pics.update(0)
  context chap.update((num: num, title: "", start: here().page()))
  [#metadata((num: num, nohead: nohead)) <chapter>]
}
#let title-block(title, gap) = {
  block(sticky: true, below: gap,
    text(font: f-head, weight: "bold", size: 25pt, fill: ink.lighten(10%), tracking: 0.01em, upper(title)))
  [#metadata(title) <toc1>]
}
// A chapter starts on a right-hand page: the title in big capitals at the top
// left, then white space before the first section.
#let chapter-end() = [#metadata("end") <chapter-end>]
#let chapter(num, title, gap: 0.85in) = {
  chapter-end()
  pagebreak(to: "odd", weak: true)
  chap-start(num)
  v(0.5in)
  title-block(title, gap)
}
// a titled part of chapter 1 that doesn't restart the count (Introduction)
#let part-title(title, gap: 0.85in) = { v(0.5in); title-block(title, gap) }

// "N-M" for a location: the chapter in force there, and the page within it
#let page-ref(loc) = {
  let pg = loc.page()
  let ms = query(<chapter>).filter(m => m.location().page() <= pg)
  if ms.len() == 0 { return "" }
  let m = ms.last()
  str(m.value.num) + "-" + str(pg - m.location().page() + 1)
}

// The contents, as on H88 page 1-2: chapters in capitals with leaders and
// section-relative page numbers; their sections indented under them.
#let contents() = context {
  let items = (query(<toc1>).map(m => (1, m)) + query(<toc2>).map(m => (2, m)))
    .sorted(key: it => (it.at(1).location().page(), it.at(1).location().position().y))
  set text(size: 8.8pt)
  columns(2, gutter: 0.4in, for (lvl, m) in items {
    let t = if lvl == 1 { text(font: f-head, weight: "bold", upper(m.value)) } else { m.value }
    block(above: if lvl == 1 { 0.95em } else { 0.38em }, below: 0.38em, sticky: lvl == 1,
      grid(columns: (if lvl == 1 { 0pt } else { 0.9em }, 1fr, auto), column-gutter: 0.3em, [],
        box(width: 100%, t + box(width: 1fr, repeat(gap: 0.15em)[.])),
        link(m.location(), page-ref(m.location()))))
  })
}

// ---------------------------------------------------------------- columns
// Typst has no balanced columns: lay the body out in one column to learn its
// height, then give the two-column block half of it (plus a little, for the
// lines that will not split).
#let gutter = 0.28in
// the height two balanced columns of the body need, at column width colw:
// the split at a paragraph boundary that makes the taller column shortest.
// (Typst's own fill packs the first column at least that full, so the rest
// always fits in the second.)
#let bal-height(body, colw, slack: 1.8em) = {
  let kids = if body.has("children") { body.children } else { (body,) }
  let groups = ()
  let cur = ()
  for k in kids {
    if k.func() == parbreak {
      if cur.len() > 0 { groups.push(cur.join()); cur = () }
    } else { cur.push(k) }
  }
  if cur.len() > 0 { groups.push(cur.join()) }
  let hs = groups.map(g => measure(block(width: colw, g)).height).filter(h => h > 0pt)
  let one = measure(block(width: colw)[x]).height
  let sp = measure(block(width: colw)[x #parbreak() x]).height - 2 * one
  let total = hs.sum(default: 0pt) + sp * calc.max(0, hs.len() - 1)
  let best = total
  let acc = 0pt
  for (i, h) in hs.enumerate() {
    acc += h + if i > 0 { sp } else { 0pt }
    let m = calc.max(acc, total - acc - sp)
    if m < best { best = m }
  }
  best + slack
}
// Balance only what can finish where it starts: a long section crosses a
// page break, and a picture floated onto the next page would take height
// the fixed block counted on. Long sections flow in plain columns.
#let balanced(body, limit: 3.6in) = layout(size => {
  let colw = (size.width - gutter) / 2
  let h = bal-height(body, colw).to-absolute()
  if h > limit { columns(2, gutter: gutter, body) }
  else { block(width: 100%, height: h, breakable: true, columns(2, gutter: gutter, body)) }
})
#let flow(body) = columns(2, gutter: gutter, body)

// Section heads: centred serif capitals across the page.
// the type area, for sections that check the room left on the page
#let text-w = 8.5in - 2 * 0.72in
#let floor-y = 11in - 0.72in
#let section(title, body, balance: true, above: 0.32in, newpage: false) = {
  // newpage: start on a fresh page (set where a section would otherwise
  // begin with a line or two at the foot of one)
  if newpage { pagebreak(weak: true) }
  block(sticky: true, above: above, below: 0.2in, width: 100%,
    align(center, text(font: f-head, weight: "bold", size: 13pt, hyphenate: false, upper(title))))
  [#metadata(title) <toc2>]
  if balance { balanced(body) } else { flow(body) }
}
// a whole-width section head with no columns under it (for tables, pictorials)
#let wide-head(title, above: 0.3in) = block(sticky: true, above: above, below: 0.18in, width: 100%,
  align(center, text(font: f-head, weight: "bold", size: 13pt, hyphenate: false, upper(title))))

// Sub-heads in a column: small bold capitals.
#let sub(title) = block(sticky: true, above: 1.1em, below: 0.55em,
  text(font: f-head, weight: "bold", size: 9.2pt, hyphenate: false, upper(title)))

// ---------------------------------------------------------------- steps
// The Heathkit check-off step: "( )" in the margin of the paragraph, so the
// builder can tick each one off.
#let chk = box(width: 2.1em, text(tracking: 0.35em, "(  )"))
#let step(body, n: none) = block(above: 0.75em, below: 0.75em,
  grid(columns: if n == none { (2.1em, 1fr) } else { (1.3em, 2.1em, 1fr) },
    column-gutter: 0.25em,
    ..if n != none { (str(n) + ".",) }, chk, body))
#let steps(..items) = for (i, it) in items.pos().enumerate() { step(it) }

// an indented dash note under a step, as on H88 page 4-3
#let dash(body) = block(above: 0.6em, below: 0.6em, inset: (left: 2.35em),
  grid(columns: (1.4em, 1fr), [---], body))

#let note(body, word: "NOTE") = block(above: 0.8em, below: 0.8em)[#word: #body]
#let caution(body) = note(word: "CAUTION", body)
#let warning(body) = note(word: "WARNING", body)

// the boxed notice (H88 page 8-1)
#let notice(title, body) = block(width: 100%, breakable: false, stroke: 0.6pt + ink,
  inset: (x: 0.22in, y: 0.16in), above: 1em, below: 1em, {
    align(center, text(font: f-head, weight: "bold", size: 9.5pt, upper(title)))
    v(0.4em)
    set text(size: 8.8pt)
    body
  })

// ---------------------------------------------------------------- typing
// What you type is underlined; RETURN is a little circled arrow (the H88
// uses its own symbol and explains it once).
#let ret = box(baseline: 0.14em, height: 0.86em, width: 0.92em, {
  place(dx: 0.03em, dy: 0.02em, circle(radius: 0.42em, stroke: 0.5pt + ink))
  // a bent arrow: down, then left, ending in a point
  place(curve(stroke: (paint: ink, thickness: 0.6pt, cap: "round", join: "round"),
    curve.move((0.64em, 0.2em)), curve.line((0.64em, 0.52em)), curve.line((0.34em, 0.52em))))
  place(curve(fill: ink, stroke: none,
    curve.move((0.2em, 0.52em)), curve.line((0.38em, 0.4em)), curve.line((0.38em, 0.64em)), curve.close()))
})
// (no smart quotes in the H19's characters: its ROM has only straight ones)
#let typed(s) = { set smartquote(enabled: false); underline(offset: 2pt, stroke: 0.5pt, text(font: f-scrn, size: 1.12em, s)) }
#let scr(s) = { set smartquote(enabled: false); text(font: f-scrn, size: 1.12em, s) }   // as the H19 shows it
#let key(s) = text(font: f-sans, size: 0.86em, weight: "bold", s)   // a key's legend

// ---------------------------------------------------------------- tables
// a dot-leader line, as in the H88's Specifications
#let dots(a, b, indent: 0.25in) = block(above: 0.42em, below: 0.42em,
  grid(columns: (indent, 1.35in, 1fr), column-gutter: 0.4em, [],
    box(width: 100%, a + box(width: 1fr, repeat(gap: 0.1em)[.])), b))
#let spec-head(t) = block(sticky: true, above: 1.1em, below: 0.5em,
  text(font: f-head, weight: "bold", size: 9.2pt, upper(t)))

// Heath's ruled column heads: the head text over a short rule
#let th(s) = box(stroke: (bottom: 0.5pt + ink), inset: (bottom: 2pt), text(font: f-sans, size: 7.5pt, upper(s)))
#let stable(cols, ..cells, size: 7.8pt, inset: (x: 0.35em, y: 0.28em), breakable: false) = {
  set text(font: f-sans, size: size, hyphenate: false)
  block(breakable: breakable, above: 0.8em, below: 0.8em,
    table(columns: cols, stroke: none, inset: inset, ..cells))
}

// the troubleshooting chart: CONDITION | POSSIBLE CAUSE, ruled
#let chart(..rows) = {
  set text(size: 8.6pt)
  table(columns: (1fr, 1.25fr), stroke: (x, y) => (top: 0.5pt + ink, bottom: 0.5pt + ink,
      left: if x == 1 { 0.5pt + ink } else { none }),
    inset: (x: 0.5em, y: 0.45em),
    table.header(text(font: f-head, weight: "bold", size: 8.6pt)[CONDITION],
                 text(font: f-head, weight: "bold", size: 8.6pt)[POSSIBLE CAUSE]),
    ..rows.pos().flatten())
}

// ---------------------------------------------------------------- pictorials
#let pictorial(body, caption: none, width: 100%) = {
  pics.step()
  block(width: width, breakable: false, above: 1em, below: 1.2em, {
    align(center, body)
    v(0.5em)
    align(center, text(font: f-sans, size: 8pt, tracking: 0.08em,
      context [PICTORIAL #chap.get().num\-#pics.get().first()]))
    if caption != none { v(-0.2em); align(center, text(font: f-sans, size: 7.5pt, caption)) }
  })
}
// a picture across both columns at the top of a page (or of what is left)
#let wide(body) = place(top, float: true, scope: "parent", clearance: 0.25in, body)

// A photograph Thom will take: a ruled box with the shot described in it.
#let photo-slot(h, desc) = rect(width: 100%, height: h, stroke: (paint: ink, thickness: 0.6pt, dash: "dashed"),
  inset: 0.15in, align(center + horizon, text(font: f-sans, size: 7.5pt, fill: ink.lighten(30%),
    [PHOTOGRAPH TO COME\ #desc])))

// ---------------------------------------------------------------- screens
// A captured H19 screen (screens/<name>.json, from ppm2cells): every cell in
// the H19's own glyphs, reverse video as light cells, on a dark tube face.
#let crt(name, rows: none, cols: none, width: 100%, cursor: true) = layout(size => {
  let d = json("screens/" + name + ".json")
  let r0 = if rows == none { 0 } else { rows.at(0) }
  let r1 = if rows == none { 24 } else { rows.at(1) }
  let c0 = if cols == none { 0 } else { cols.at(0) }
  let c1 = if cols == none { 79 } else { cols.at(1) }
  let ncol = c1 - c0 + 1
  let nrow = r1 - r0 + 1
  let w = if type(width) == ratio { size.width * width } else { width }
  let pad = 0.16in
  let cw = (w - 2 * pad) / ncol             // a cell is 8 x 10 pixels, pixels 1:2
  let ch = cw * 2.5
  let cells = ()
  for y in range(r0, r1 + 1) {
    let row = d.rows.at(y)
    let t = row.text.clusters()
    let rv = row.rev.clusters()
    for x in range(c0, c1 + 1) {
      let c = t.at(x)
      let rev = rv.at(x) == "r"
      let cur = cursor and d.cursor != none and d.cursor.at(0) == x and d.cursor.at(1) == y
      if rev or c != " " or cur {
        cells.push(place(dx: (x - c0) * cw, dy: (y - r0) * ch, {
          if rev { place(rect(width: cw + 0.05pt, height: ch + 0.05pt, fill: phosphor, stroke: none)) }
          if c != " " {
            place(box(width: cw, height: ch, clip: false,
              text(font: f-scrn, size: ch, fill: if rev { tube } else { phosphor }, top-edge: 0.8em, bottom-edge: -0.2em, c)))
          }
          if cur { place(dy: ch * 0.9, rect(width: cw, height: ch * 0.1, fill: phosphor, stroke: none)) }
        }))
      }
    }
  }
  block(breakable: false, width: w, height: nrow * ch + 2 * pad, fill: tube, radius: 0.09in,
    inset: pad, block(width: ncol * cw, height: nrow * ch, { for c in cells { c } }))
})

// A session as printed paper: the screen's rows in the H19's glyphs, black on
// white, with what the operator typed underlined (rules: after a prompt, the
// command; on the monitor's lines, the letters and numbers keyed).
#let session(name, rows: none, cols: none, size: 8.4pt, typed-rows: auto, under: (), squeeze: true) = {
  let d = json("screens/" + name + ".json")
  let r0 = if rows == none { 0 } else { rows.at(0) }
  let r1 = if rows == none { 24 } else { rows.at(1) }
  let c0 = if cols == none { 0 } else { cols.at(0) }
  let c1 = if cols == none { 79 } else { cols.at(1) }
  let cw = size * 0.4
  let ch = size
  let lines = ()
  for y in range(r0, r1 + 1) {
    let s = d.rows.at(y).text.clusters().slice(c0, c1 + 1).join("").trim(at: end)
    // HDOS double-spaces its output; the printed session closes it up
    if not (squeeze and s == "") { lines.push((y, s)) }
  }
  // what was typed: (row, from col, to col), given or by rule
  let marks = under
  if typed-rows == auto {
    for (y, s) in lines {
      let m = s.match(regex("^(A>|>)(.+)$"))
      if m != none { marks.push((y, m.captures.at(0).len(), s.len() - 1)) }
    }
  }
  block(breakable: false, above: 0.7em, below: 0.8em, inset: (left: 0.6em), {
    for (y, s) in lines {
      let us = marks.filter(m => m.at(0) == y)
      block(width: 100%, height: ch * 1.22, above: 0pt, below: 0pt, breakable: false, {
        let chars = s.clusters()
        for (x, c) in chars.enumerate() {
          if c != " " {
            place(dx: x * cw, dy: 0pt, text(font: f-scrn, size: ch, fill: ink, top-edge: 0.8em, bottom-edge: -0.2em, c))
          }
          if us.any(m => x >= m.at(1) and x <= m.at(2)) {
            place(dx: x * cw, dy: ch * 0.92, line(length: cw + 0.02pt, stroke: 0.45pt + ink))
          }
        }
      })
    }
  })
}

// ---------------------------------------------------------------- keyed programs
// The numbers to key in, eight to a row, each row headed by the address of
// its first number (data/<name>.json, made by tools/mkacctest.py from the
// assembler's own output).
#let octal-table(name, size: 8.6pt) = {
  let d = json("data/" + name + ".json")
  let flat = d.flat
  let rows = ()
  let i = 0
  while i < flat.len() {
    let chunk = flat.slice(i, calc.min(i + 8, flat.len()))
    rows.push((flat.at(i).addr.replace(".", ""), chunk.map(e => e.byte)))
    i += 8
  }
  set text(font: f-scrn, size: size * 1.12)
  block(breakable: false, above: 0.8em, below: 0.9em, inset: (left: 0.3em),
    table(columns: (auto,) + (auto,) * 8, stroke: none, inset: (x: 0.28em, y: 0.24em),
      table.header(text(font: f-sans, size: 6.8pt)[ADDRESS], table.cell(colspan: 8, text(font: f-sans, size: 6.8pt)[ENTER])),
      ..rows.map(r => (text(fill: ink.lighten(35%), r.at(0)),) + r.at(1) + ("",) * (8 - r.at(1).len())).flatten()))
}

// A Heath-style listing: address in split octal, the bytes, the source --
// the lines as tools/mkacctest.py laid them out from the assembler's output.
#let listing(name, size: 6.3pt) = {
  let d = json("data/" + name + ".json")
  block(above: 0.8em, below: 0.8em, {
    for l in d.printed {
      block(above: 0pt, below: 0pt, height: size * 1.25, breakable: false,
        text(font: f-scrn, size: size, top-edge: 0.8em, bottom-edge: -0.2em, l.replace(" ", "\u{00A0}")))
    }
  })
}
