// lib.typ -- helpers for the FujiNet RCA Studio II Programmer's Handbook.
//
// House style: the 1977 RCA Studio II Owner's Manual -- a landscape booklet
// on off-white paper with one spot colour (RCA gold), Helvetica throughout,
// big gold Helvetica Bold heads hung at the left of the page, the console's
// name always in Bodoni italic, gold-filled figure panels with black callouts
// on leader lines, black rounded TV screens, gold round bullets, numbered
// steps, NOTE: and IMPORTANT: in gold capitals. Ragged right throughout.

// ---------- fonts ---------------------------------------------------
#let f-body = "Helvetica"
#let f-word = "Bodoni Std"            // Book Italic (400): the wordmark
#let f-mono = "Source Code Pro"

// ---------- palette -------------------------------------------------
#let ink      = rgb("#1c1b19")
#let paper    = rgb("#f7f5f0")
#let gold     = rgb("#e4a408")        // sampled from the scan's panels
#let gold-ink = rgb("#b98200")        // gold small enough to need weight
#let gold-lt  = rgb("#f4dc9a")        // a pale gold for tints
#let gray     = rgb("#6d6a64")
#let panel    = rgb("#efebe1")        // code panels
#let panel-b  = rgb("#d8d2c3")
#let screen   = rgb("#0c0c11")        // the TV glass
#let rim      = rgb("#a9a6a2")        // the TV's outline

#let front = state("front", true)     // no folio on the front matter
#let refpage = state("refpage", false) // a one-column chapter: a short drop
#let appendix = state("apx", false)
#let opener-art = state("opener", none)

// ---------- the page grid -------------------------------------------
#let page-w  = 10in
#let page-h  = 7.56in
#let m-top   = 0.5in
#let m-bot   = 0.62in
#let m-in    = 0.55in
#let m-out   = 0.55in
#let gut     = 0.3in
#let colw    = (page-w - m-in - m-out - 2 * gut) / 3
#let floor-y = page-h - m-bot

#let folio = context {
  let pg = counter(page).get().first()
  if front.get() { none } else {
    set text(font: f-body, size: 8pt, fill: ink)
    if calc.odd(pg) { align(right, str(pg)) } else { align(left, str(pg)) }
  }
}

// ---------- the wordmark --------------------------------------------
// Every "Studio II" is set as RCA set it: Bodoni italic, a little larger
// than the Helvetica around it, never broken across a line.
#let wordmark(size: 1.1em) = box(text(font: f-word, style: "italic",
  weight: 400, size: size, [Studio#sym.space.nobreak;II]))
// inside code the words are plain text again
#let unmark(body) = {
  show "Studio II": "Studio\u{A0}II"
  body
}

// ---------- full-width matter on a three-column page ----------------
// A float scoped to the page, so a table, a diagram or a wide panel can
// span all three columns. Call it at the top level of a part only.
#let wide(body, at: auto, gap: 12pt) = place(at, float: true,
  scope: "parent", clearance: gap, body)

// ---------- callouts ------------------------------------------------
// The booklet sets NOTE: and IMPORTANT: in gold capitals on a line of their
// own, the text under them.
#let callout(label, body) = block(width: 100%, above: 0.95em, below: 0.95em,
  breakable: false, {
  set par(justify: false, first-line-indent: 0pt)
  block(below: 0.4em, sticky: true,
    text(weight: 700, size: 8.6pt, fill: gold-ink, tracking: 0.3pt, upper(label) + ":"))
  body
})
#let note(body) = callout("Note", body)
#let important(body) = callout("Important", body)
#let caution(body) = callout("Caution", body)

// ---------- lists ---------------------------------------------------
#let dot = box(baseline: -1.6pt, circle(radius: 2.3pt, fill: gold, stroke: none))
#let nsteps(..items) = enum(numbering: n => text(weight: 400, numbering("1.", n)),
  spacing: 0.55em, tight: false, body-indent: 5pt, ..items.pos())

// ---------- code ----------------------------------------------------
#let mono(s, size: 0.92em) = unmark(text(font: f-mono, size: size, s))
#let hx(s) = mono(s)
// A code line never wraps: the panel picks the largest size at which its
// longest line still fits.
#let codesize(txt, size, room) = {
  let longest = calc.max(1, ..txt.split("\n").map(l => l.len()))
  calc.min(size, room / (longest * 0.6))
}
// A comment that would shrink a column's code below legibility moves in to
// two spaces after its operand: the comment column goes, the words stay.
#let tighten(txt) = txt.split("\n").map(l => {
  let i = l.position(";")
  if i == none or i == 0 { l } else {
    let head = l.slice(0, i).trim(at: end)
    if head == "" { l } else { head + "  " + l.slice(i) }
  }
}).join("\n")
#let min-code = 6.2pt
#let codeblock(txt, size: 6.8pt, room: none) = layout(sz => {
  let r = if room == none { sz.width - 14pt } else { room }
  let txt = if codesize(txt, size, r) < min-code { tighten(txt) } else { txt }
  block(width: 100%,
    breakable: txt.split("\n").len() > 24,
    above: 0.7em, below: 0.9em, fill: panel, inset: (x: 7pt, y: 5.5pt),
    stroke: (left: 2pt + gold, rest: 0.5pt + panel-b), unmark({
      set par(justify: false, leading: 0.38em, first-line-indent: 0pt)
      set text(font: f-mono, size: codesize(txt, size, r), fill: ink)
      txt.split("\n").map(l => if l == "" { " " } else { l }).join(linebreak())
    }))
})
#let codetitle(title) = block(breakable: false, below: 3pt, sticky: true,
  text(weight: 700, size: 6.4pt, fill: gold-ink, tracking: 0.5pt, upper(title)))
#let codepanel(title, txt, size: 6.8pt) = block(above: 0.9em, below: 0.9em,
  breakable: true, {
  if title != none { codetitle(title) }
  codeblock(txt, size: size)
})
#let t-asm = "CDP1802 Assembly (AS)"
#let asmp(txt, size: 6.8pt) = codepanel(t-asm, txt, size: size)

// ---------- figures -------------------------------------------------
#let fig-n = counter("figure")
#let caption-text(c) = {
  fig-n.step()
  set par(justify: false)
  text(size: 7.6pt, style: "italic")[Figure #context fig-n.display(). #c]
}
#let fig(body, caption: none) = block(width: 100%, above: 0.9em, below: 1.0em,
  breakable: false, {
  align(center, body)
  if caption != none { v(4pt); align(center, caption-text(caption)) }
})

// The gold panel the booklet puts its photographs on, with rounded corners.
#let goldpanel(body, inset: 10pt, radius: 9pt, w: 100%) = block(width: w,
  fill: gold, radius: radius, inset: inset, body)

// A callout on a panel: a black capital label with a leader line from the
// label to the point it names. Coordinates are within the panel.
#let callout-at(label, lx, ly, px, py, al: left) = {
  place(top + left, line(start: (lx, ly), end: (px, py), stroke: 0.6pt + ink))
  let lab = text(weight: 700, size: 6.3pt, fill: ink, label)
  place(top + left, dx: lx, dy: ly, context {
    let m = measure(lab)
    let dx = if al == left { 2pt } else if al == right { -m.width - 2pt } else { -m.width / 2 }
    let dy = if al == center { -m.height - 2pt } else { -m.height / 2 }
    place(top + left, dx: dx, dy: dy, box(fill: gold, inset: 1pt, lab))
  })
}

// ---------- the TV screen -------------------------------------------
// A black rounded screen with a pale rim, as the booklet draws them. The
// picture is a MAME snapshot of the whole 1861 field, stretched to the
// 4:3 a television shows, with its pixels kept hard.
// tools/shots.sh lists the screens it made; one not made yet is drawn as a
// marked blank, which make check refuses.
#let screens = json("images/screens/index.json")
#let crt(name, w: 1.6in, label: none) = {
  let h = w * 3 / 4
  box(width: w + 6pt, height: h + 6pt, radius: (w + 6pt) * 0.13,
    stroke: 1.1pt + rim, inset: 3pt, fill: paper,
    box(width: w, height: h, radius: w * 0.12, fill: screen, clip: true,
      if name == none { none } else if name in screens {
        image("images/screens/" + name + ".png", width: w, height: h,
          fit: "stretch", scaling: "pixelated")
      } else {
        align(center + horizon, text(size: 7pt, fill: white, "NO SCREEN " + name))
      }))
}
// the booklet's small icon screens, with a caption under each
#let tvrow(..names, w: 1.05in, gap: 0.18in) = stack(dir: ltr, spacing: gap,
  ..names.pos().map(n => crt(n, w: w)))
#let shot(name, w: 2.4in, caption: none) = fig(crt(name, w: w), caption: caption)
// two screens side by side, as wide as the column allows
#let crt2(a, b, caption: none, gap: 0.14in) = layout(sz => {
  let w = (sz.width - gap - 14pt) / 2
  fig(stack(dir: ltr, spacing: gap, crt(a, w: w), crt(b, w: w)), caption: caption)
})

// ---------- the cartridge's own characters ---------------------------
// Drawn from its 3 x 5 font (tools/mkfontjson.py): a dot is a little wider
// than tall, as on the television. s2ch(0x01) is the spade.
#let s2font = json("images/art/s2font.json")
#let s2ch(code, h: 0.72em, fill: ink) = {
  let key = upper(str(code, base: 16))
  let key = if key.len() < 2 { "0" + key } else { key }
  let rows = s2font.at(key)
  let dh = h / 5
  let dw = dh * 1.25
  box(width: dw * 3.6, height: h, {
    for (y, r) in rows.enumerate() {
      for x in range(3) {
        if calc.rem(calc.quo(r, calc.pow(2, 2 - x)), 2) == 1 {
          place(top + left, dx: x * dw, dy: y * dh,
            rect(width: dw, height: dh, fill: fill, stroke: none))
        }
      }
    }
  })
}

// ---------- the keypads ---------------------------------------------
// The console's two 10-key pads: 1-9 in a square, 0 under the middle.
// `marks` names keys to fill in gold and label; labels sit beside the pad.
#let keycap(k, hot: false, s: 13pt, sub: none) = box(width: s, height: s, radius: 2pt,
  fill: if hot { gold } else { white }, stroke: 0.7pt + ink, {
    align(center + horizon, text(weight: 700, size: s * 0.55, fill: ink, str(k)))
    if sub != none {
      place(bottom + right, dx: -1.5pt, dy: -1pt,
        text(size: s * 0.3, fill: gray, sub))
    }
  })
// `subs` labels keys with something small, such as MAME's keys for them.
#let keypad(name: none, hot: (), s: 13pt, gap: 3pt, subs: (:)) = {
  let cell(k) = keycap(k, hot: k in hot, s: s, sub: subs.at(str(k), default: none))
  box(fill: rgb("#d9d5cc"), radius: 4pt, inset: 5pt, stroke: 0.7pt + ink, {
    grid(columns: 3, gutter: gap, ..range(1, 10).map(cell),
      [], cell(0), [])
    if name != none {
      v(3pt, weak: true)
      align(center, text(weight: 700, size: 6pt, name))
    }
  })
}

// ---------- tables --------------------------------------------------
// A short table never breaks across a column or a page; a long one may.
#let tbl(cols, ..rows, align: left, size: 7.9pt) = block(above: 0.7em, below: 0.9em,
  breakable: rows.pos().flatten().len() / (if type(cols) == array { cols.len() } else { cols }) > 12, {
  set par(justify: false, first-line-indent: 0pt)
  set text(size: size)
  let n = if type(cols) == array { cols.len() } else { cols }
  let cells = rows.pos().flatten()
  table(columns: cols, align: align + top, inset: (x: 4.5pt, y: 3.4pt),
    fill: (x, y) => if y == 0 { gold-lt } else { none },
    stroke: (x, y) => (
      top: if y == 0 { 0.9pt + gold } else { 0.4pt + panel-b },
      bottom: 0.9pt + gold),
    table.header(..cells.slice(0, n)),
    ..cells.slice(n))
})
#let th(s) = text(weight: 700, s)

// ---------- dot-leader rows (contents, parts list) -------------------
#let leaders(left-part, right-part, size: 8.4pt) = box(width: 100%, {
  text(size: size, left-part)
  box(width: 1fr, repeat(text(size: size)[.], gap: 1.6pt))
  text(size: size, right-part)
})
#let dotdef(..rows, size: 8.2pt) = {
  set par(first-line-indent: 0pt, justify: false)
  grid(columns: (1.15fr, 1fr), row-gutter: 5pt, column-gutter: 8pt,
    align: (left + top, left + top),
    ..rows.pos().map(r => (
      box(width: 100%, {
        text(size: size, r.at(0))
        box(width: 1fr, repeat(text(size: size)[.], gap: 2pt))
      }),
      mono(r.at(1), size: size * 0.86))).flatten())
}

// ---------- byte-field strip ----------------------------------------
#let bytefield(..cells) = {
  let cs = cells.pos()
  align(center, block(above: 0.6em, below: 0.5em, breakable: false,
    grid(columns: cs.map(c => c.at(1)), stroke: 0.6pt + ink, fill: white,
      ..cs.map(c => grid.cell(inset: 4pt, align: center,
        mono(c.at(0), size: 7pt))))))
}

// ---------- memory map ----------------------------------------------
// rows: (from, to, label, colour, note). Heights follow the size, with a
// floor so a one-page region still has room for its name.
#let memmap(rows, w: 1.4in, scale: 0.0045pt, minh: 13pt, notes: true,
            addrw: 0.45in, notew: 3.4in) = {
  let boxes = rows.map(r => {
    // a sixth element, when present, is the box's height
    let h = if r.len() > 5 { r.at(5) } else { calc.max(minh, (r.at(1) - r.at(0) + 1) * scale) }
    grid(columns: (addrw, w, if notes { notew } else { 0pt }),
      column-gutter: 6pt, align: (right + top, left + top, left + horizon),
      mono("$" + upper(str(r.at(0), base: 16)), size: 6.8pt),
      box(width: w, height: h, fill: r.at(3), stroke: 0.7pt + ink,
        align(center + horizon, text(weight: 700, size: 6.8pt, fill: ink, r.at(2)))),
      if notes { box(height: h, align(horizon, text(size: 7.2pt, r.at(4)))) } else { none })
  })
  block(above: 0.6em, below: 0.4em, breakable: false,
    stack(dir: ttb, spacing: 0pt, ..boxes,
      v(4pt),
      grid(columns: (addrw, w), column-gutter: 6pt, align: (right + top, left),
        mono("$" + upper(str(rows.last().at(1) + 1, base: 16)), size: 6.8pt), [])))
}

// ---------- sequence diagrams ---------------------------------------
#let msg(from, to, body, dashed: false, c: ink) = (
  kind: "msg", from: from, to: to, body: body, dashed: dashed, c: c)
#let snote(lane, body, span: 1, fill: panel, bd: gray) = (
  kind: "note", lane: lane, span: span, body: body, fill: fill, bd: bd)
#let sgap(h: 8pt) = (kind: "gap", h: h)
#let seq(actors, ..steps, w: 6in) = {
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
    box(width: w + 8pt, height: toth + 8pt, fill: white, stroke: 0.5pt + panel-b,
      inset: 4pt, {
    for i in range(n) {
      place(top + left, dx: xs.at(i) - 0.4pt, dy: headh - 2pt,
        line(start: (0pt, 0pt), end: (0pt, bodyh + 6pt),
          stroke: (paint: gray, thickness: 0.6pt, dash: "dotted")))
    }
    for i in range(n) {
      place(top + left, dx: xs.at(i) - lane/2 + 4pt, dy: 0pt,
        box(width: lane - 8pt, height: 16pt, fill: actors.at(i).at(1),
          stroke: 0.7pt + ink, radius: 2pt,
          align(center + horizon, text(weight: 700, size: 6.8pt,
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
              text(size: 6.6pt, fill: ink, s.body))))
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
          mono(s.body, size: 6.4pt))
        y += 19pt
      }
    }
  })))
}

// ---------- the RCA grid on a single-column page --------------------
// The reference chapters, the checklist and the appendices are set on a
// one-column page, and draw the grid inside it: a hung left column and a
// right column two wide.
#let hang(l, r, gap: gut) = grid(columns: (colw, 1fr), column-gutter: gap,
  align: (left + top, left + top), l, r)

// ---------- command reference card ----------------------------------
#let cmdlab(s) = text(weight: 700, size: 6.2pt, fill: gray, tracking: 0.4pt, upper(s))
#let cmd(name, code: "", dev: "", nparam: "", params: "none",
         payload: "none", reply: "none", asm: none, body) = block(width: 100%,
  above: 1.1em, below: 1.1em, breakable: false, {
  set par(justify: false, first-line-indent: 0pt)
  hang({
    block(below: 2pt, sticky: true, text(weight: 700, size: 11.5pt, fill: gold, name))
    block(below: 6pt, mono(text(weight: 700, fill: gold-ink, code), size: 9pt))
    grid(columns: (38pt, 1fr), row-gutter: 4.5pt, column-gutter: 5pt,
      cmdlab("device"),  mono(dev, size: 7.4pt),
      cmdlab("nparam"),  mono(nparam, size: 7.4pt),
      cmdlab("params"),  text(size: 7.6pt, params),
      cmdlab("payload"), text(size: 7.6pt, payload),
      cmdlab("reply"),   text(size: 7.6pt, reply))
  }, {
    body
    if asm != none { asmp(asm, size: 7pt) }
  })
  v(2pt)
  line(length: 100%, stroke: 0.4pt + panel-b)
})

// ---------- the Troubleshooting Checklist ---------------------------
#let symrem(..rows) = block(above: 0.6em, below: 0.8em, {
  set par(justify: false, first-line-indent: 0pt)
  hang(text(weight: 700, size: 8pt, fill: gold-ink, tracking: 0.4pt)[SYMPTOM],
       text(weight: 700, size: 8pt, fill: gold-ink, tracking: 0.4pt)[PROBABLE CAUSE AND REMEDY])
  for r in rows.pos() {
    let causes = if type(r.at(1)) == array { r.at(1) } else { (r.at(1),) }
    block(breakable: false, above: 0.7em, below: 0.4em, {
      line(length: 100%, stroke: 0.4pt + panel-b)
      v(3pt)
      hang(text(weight: 700, r.at(0)), list(marker: dot, ..causes))
    })
  }
})

// ---------- listings --------------------------------------------------
// A long space-free token cannot wrap; zero-width spaces after its
// separators give it somewhere to break.
#let softbreak(src) = src.split("\n").map(l =>
  l.split(" ").map(t =>
    if t.len() > 40 {
      t.replace(",", ",\u{200b}").replace("=", "=\u{200b}").replace("/", "/\u{200b}")
    } else { t }).join(" ")).join("\n")

// Lines from the first line containing `from` up to (not including) the
// first later line containing `to` (or `n` lines when `to` is none).
#let excerpt-lines(path, from, to: none, n: 30, skip: 0) = {
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
  lines.slice(a, calc.min(b, lines.len())).join("\n")
}
#let excerpt-at(title, path, from, to: none, n: 30, size: 6.8pt, skip: 0) = {
  let t = if title == auto { t-asm + "  ·  " + path.split("/").last() } else { title }
  codepanel(t, excerpt-lines(path, from, to: to, n: n, skip: skip), size: size)
}

// An excerpt too wide for a column, across the page: the vendored games'
// sources keep their comments at column 40 and run to 78 characters.
#let wex(path, from, to: none, n: 30, at: auto, size: 6.8pt) = wide(at: at,
  excerpt-at(auto, path, from, to: to, n: n, size: size))

// A listing for the appendices, numbered, wrapped lines hung past the
// number gutter. The appendix page has three columns and the listings run
// on through them one after another.
#let listing3(title, path, size: 4.9pt) = {
  block(breakable: false, above: 1.1em, below: 4pt, sticky: true, {
    text(weight: 700, size: 8.5pt, fill: gold, title)
    h(5pt)
    mono(text(fill: gray, path.split("/").slice(1).join("/")), size: 5.8pt)
    v(1pt)
    line(length: 100%, stroke: 0.8pt + gold)
  })
  unmark({
    let src = softbreak(read(path))
    show raw.where(block: true): it => block(width: 100%, breakable: true,
      fill: none, inset: 0pt, stroke: none,
      text(font: f-mono, size: size, fill: ink, it.lines.join(parbreak())))
    show raw.line: it => {
      box(width: 11pt, align(right, text(size: size * 0.8, fill: gray, str(it.number))))
      h(2.5pt)
      it.body
    }
    set par(justify: false, leading: 0.32em, spacing: 0.32em,
      hanging-indent: 13.5pt, first-line-indent: 0pt)
    raw(src, block: true)
  })
}

// ---------- unnumbered sub-heads ------------------------------------
#let sect(t) = heading(level: 2, numbering: none, t)
#let sub(t) = heading(level: 3, numbering: none, t)

// ---------- block diagram nodes -------------------------------------
#let nodebox(title, sub: none, fill: white, w: auto) = box(width: w, fill: fill,
  inset: (x: 6pt, y: 4.5pt), stroke: 0.7pt + ink, radius: 2pt,
  align(center, {
    text(weight: 700, size: 7.2pt, title)
    if sub != none { v(2pt, weak: true); mono(text(fill: gray, sub), size: 6.2pt) }
  }))
#let rarrow(w: 18pt, label: none) = box(width: w, height: 12pt, baseline: 4pt, {
  place(left + horizon, line(length: w - 5pt, stroke: 0.8pt + ink))
  place(left + horizon, dx: w - 6pt, polygon(fill: ink, (0pt, -2.5pt), (5pt, 0pt), (0pt, 2.5pt)))
  if label != none { place(center + bottom, dy: -8pt, text(size: 5.6pt, label)) }
})
#let flow(..items) = align(center, block(above: 0.7em, below: 0.6em,
  breakable: false, stack(dir: ltr, spacing: 0pt, ..items.pos())))

// ---------- cross references ----------------------------------------
// the page a label is on
// (a chapter not yet written shows ??; make check refuses a ?? in the PDF)
#let pg(lbl) = context {
  let q = query(lbl)
  if q.len() == 0 { "??" } else { str(counter(page).at(q.first().location()).first()) }
}
// The booklet has no chapter numbers: a reference names the chapter and
// its page.
#let xref(lbl) = context {
  let el = query(lbl).first()
  let pg = counter(page).at(el.location()).first()
  [_#el.body;_, page #pg]
}
