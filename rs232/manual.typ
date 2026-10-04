// ============================================================
// THE RS-232 FUJINET -- USER'S MANUAL
// Driving every FujiNet device over a plain serial port: setting up
// fnconfig.ini, the FujiBus packet format, a command reference for every
// device with real byte streams, and three complete Z80 programs (CONFIG,
// NETCAT, 5 CARD STUD) for an Altair 8800 with an 88-2SIO.
//
// House style: the FujiNet engineering series (The FujiNet Network
// Protocol Handbook, the Platform Bring-Up Guide, the ColecoVision
// Programmers Handbook) -- single-column US-Letter, Nimbus Roman body,
// Nimbus Sans heads, Source Code Pro listings, FujiNet red accents,
// sticky headings, strict widow/orphan control.
//
// Every command, structure offset and byte stream is transcribed from the
// firmware sources and checked against a running adapter: the example
// streams are read from examples.json, captured by tools/examples.py.
// See README.md for the sources-of-truth table.
//
// Build: typst compile --font-path fonts manual.typ
// ============================================================

#let f-head   = "Nimbus Sans"
#let f-body   = "Nimbus Roman"
#let f-mono   = "Source Code Pro"

// ---------- palette (FujiNet engineering) ----------------------------
#let ink    = rgb("#1c1c1e")
#let paper  = rgb("#ffffff")
#let fuji   = rgb("#b62a1c")            // FujiNet red (the mountain)
#let fuji-d = rgb("#7f1d12")
#let slate  = rgb("#2f4858")            // secondary heads / notes
#let steel  = rgb("#41607a")
#let rule-c = rgb("#c9ccd1")            // hairline rules, borders
#let code-bg= rgb("#f5f6f8")
#let code-bd= rgb("#dfe2e7")
#let note-bg= rgb("#eef3f6")
#let tip-bg = rgb("#eef5ee")
#let warn-bg= rgb("#fbeeec")
#let amber  = rgb("#a6701a")
#let amber-bg=rgb("#fbf3e3")
#let mast   = rgb("#3a5a6e")            // diagram "computer" lane
#let perif  = rgb("#7a3b2e")            // diagram "FujiNet" lane
#let gray   = rgb("#6d6a63")

// byte-stream roles (wire diagrams)
#let r-end  = rgb("#2f4858")            // SLIP END
#let r-hdr  = rgb("#c9dcec")            // device, command
#let r-len  = rgb("#dde8c0")            // length
#let r-chk  = rgb("#f2d48f")            // checksum
#let r-dsc  = rgb("#d9c9ee")            // descriptor
#let r-par  = rgb("#b9e0c4")            // parameters
#let r-pay  = rgb("#ffffff")            // payload
#let r-esc  = rgb("#f1aea3")            // SLIP escape pair

// ---------- document & page geometry --------------------------------
#set document(title: "The RS-232 FujiNet User's Manual",
              author: "FujiNet Project")
#set page(
  paper: "us-letter",
  margin: (top: 1.0in, bottom: 1.0in, inside: 1.05in, outside: 0.9in),
)
#set text(font: f-body, size: 10.5pt, fill: ink, lang: "en")
// Widow/orphan/runt discipline: high costs push a stranded line's whole
// paragraph rather than leave one line alone at a page edge.
#set par(justify: true, leading: 0.62em, spacing: 0.95em, first-line-indent: 0pt)
#set text(costs: (hyphenation: 220%, runt: 500%, widow: 900%, orphan: 900%))
#set smartquote(enabled: true)

#let frontmatter = state("fm", true)
#let appendix = state("apx", false)

// ---------- heading system ------------------------------------------
#set heading(numbering: "1.1")

// level 1 (chapter): new page, red kicker, big title, red rule.
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  v(0.30in)
  block(width: 100%, {
    context if appendix.get() {
      text(font: f-head, weight: 800, size: 10.5pt, fill: fuji,
        tracking: 2pt)[APPENDIX #counter(heading).display("A")]
    } else {
      text(font: f-head, weight: 800, size: 10.5pt, fill: fuji,
        tracking: 2pt)[CHAPTER #counter(heading).display("1")]
    }
    v(6pt, weak: true)
    text(font: f-head, weight: 800, size: 22pt, fill: ink, it.body)
    v(7pt, weak: true)
    line(length: 100%, stroke: 2pt + fuji)
  })
  v(0.24in)
}

// sticky: a section heading may never be the last block on a page.
#show heading.where(level: 2): it => block(above: 1.15em, below: 0.55em,
  sticky: true,
  text(font: f-head, weight: 800, size: 13pt, fill: slate, context {
    if appendix.get() { it.body }
    else if it.numbering != none { counter(heading).display("1.1") + h(9pt) + it.body }
    else { it.body }
  }))

#show heading.where(level: 3): it => block(above: 0.85em, below: 0.4em,
  sticky: true,
  text(font: f-head, weight: 700, size: 10.5pt, fill: steel, it.body))
#show heading.where(level: 4): it => block(above: 0.6em, below: 0.35em,
  sticky: true,
  text(font: f-head, weight: 700, size: 10pt, fill: ink, it.body))

#let chapter(t) = heading(level: 1, t)
#let sect(t) = heading(level: 2, t)
#let sub(t) = heading(level: 3, t)

// ---------- inline code & raw blocks --------------------------------
#show raw.where(block: false): it => box(
  fill: code-bg, inset: (x: 3pt, y: 0pt), outset: (y: 3pt), radius: 2pt,
  text(font: f-mono, size: 0.88em, fill: fuji-d.mix((ink, 30%)), it))

#show raw.where(block: true): it => block(
  width: 100%, breakable: true, fill: code-bg, inset: 9pt,
  stroke: (left: 2.5pt + fuji.mix((paper, 35%)), rest: 0.6pt + code-bd),
  radius: 1pt,
  text(font: f-mono, size: 8.2pt, fill: ink, it))

// ---------- callouts ------------------------------------------------
#let callout(label, body, bg, bar, lc: ink, breakable: false) = block(
  width: 100%, above: 0.95em, below: 0.95em, breakable: breakable,
  fill: bg, inset: (x: 10pt, y: 8pt), stroke: (left: 3pt + bar, rest: none),
  {
    text(font: f-head, weight: 800, size: 8.5pt, fill: lc, tracking: 0.6pt,
      upper(label))
    v(3pt, weak: true)
    set par(leading: 0.6em, justify: true, first-line-indent: 0pt)
    body
  })
#let note(body)      = callout("Note", body, note-bg, steel, lc: slate)
#let tip(body)       = callout("Tip", body, tip-bg, rgb("#3f7d3f"), lc: rgb("#2f5d2f"))
#let important(body) = callout("Important", body, amber-bg, amber, lc: amber)
#let caution(body)   = callout("Caution", body, warn-bg, fuji, lc: fuji-d)
#let pitfall(body)   = callout("Pitfall", body, warn-bg, fuji, lc: fuji-d)
#let sidebar(label, body) = callout(label, body, amber-bg, amber, lc: amber,
  breakable: true)

// ---------- code panel with a LISTING-style rubric ------------------
#let codepanel(title, body-txt, size: 8.0pt, breakable: false) = block(
  breakable: breakable, above: 0.95em, below: 0.95em, {
  block(breakable: false, below: 4pt, sticky: true, {
    text(font: f-head, weight: 800, fill: fuji, size: 8pt,
      tracking: 0.5pt, upper(title))
    v(2pt)
    line(length: 100%, stroke: 0.8pt + rule-c)
  })
  block(width: 100%, breakable: breakable, fill: code-bg, inset: 9pt,
    stroke: (left: 2.5pt + fuji.mix((paper, 35%)), rest: 0.6pt + code-bd),
    radius: 1pt, {
      set par(justify: false, leading: 0.5em, first-line-indent: 0pt)
      text(font: f-mono, size: size, fill: ink,
        body-txt.split("\n").map(l => if l == "" { " " } else { l })
          .join(linebreak()))
    })
})

// ---------- figures with captions -----------------------------------
#let fig-n = counter("figure-c")
#let fig(body, caption: none) = block(
  width: 100%, above: 1.0em, below: 1.0em, breakable: false, {
  fig-n.step()
  align(center, body)
  v(4pt)
  align(center, text(font: f-head, size: 8.4pt, fill: slate,
    if caption != none [#strong[Figure #context fig-n.display().] #caption]
    else [#strong[Figure #context fig-n.display().]]))
})

// ---------- numbered step (procedures) ------------------------------
#let step(n, body) = block(above: 0.5em, below: 0.5em, breakable: false, grid(
  columns: (0.3in, 1fr), column-gutter: 0.1in, row-gutter: 0pt,
  text(font: f-head, weight: 800, size: 11pt, fill: fuji,
    [#str(n).]),
  par(leading: 0.58em, first-line-indent: 0pt, body)))

// keycap glyph
#let key(s) = box(baseline: 18%, fill: rgb("#ececec"), inset: (x: 4pt, y: 1pt),
  radius: 2pt, stroke: 0.5pt + rgb("#bdbdbd"),
  text(font: f-head, size: 8pt, s))

// a displayed devicespec / command line
#let spec(s) = align(center, block(above: 0.6em, below: 0.6em,
  box(fill: code-bg, stroke: 0.6pt + code-bd, inset: (x: 10pt, y: 6pt),
    radius: 2pt,
    text(font: f-mono, size: 9pt, weight: 600, fill: ink, s))))

// ---------- tables --------------------------------------------------
#set table(stroke: (x, y) => (
  top: if y == 0 { 1pt + ink } else { 0.5pt + rule-c },
  bottom: 0.5pt + rule-c))
#show table.cell.where(y: 0): set text(font: f-head, weight: 800,
  size: 8.2pt, fill: white)
#set table(fill: (x, y) => if y == 0 { slate })
#set table(inset: (x: 6pt, y: 4pt))
#show table: set text(size: 8.6pt)
#show table: set par(justify: false)

// a table that is never split (short tables)
#let ktable(..args) = block(breakable: false, above: 0.8em, below: 0.9em,
  table(..args))
// a table that may split; its header row repeats on the next page
#let btable(..args) = block(breakable: true, above: 0.8em, below: 0.9em,
  table(..args))

// ---------- byte-field strip ----------------------------------------
#let bytefield(..cells) = {
  let cs = cells.pos()
  align(center, block(above: 0.6em, below: 0.4em, breakable: false,
    grid(columns: cs.map(c => c.at(1)), rows: auto, stroke: 0.7pt + slate,
      ..cs.map(c => grid.cell(inset: 5pt, align: center,
        text(font: f-mono, size: 7.6pt, fill: ink, c.at(0)))))))
}

// ---------- block-diagram nodes -------------------------------------
#let nodebox(title, sub: none, fill: note-bg, bd: steel, w: auto, tc: ink) = box(
  width: w, fill: fill, inset: (x: 8pt, y: 6pt), radius: 3pt,
  stroke: 0.8pt + bd,
  align(center, {
    text(font: f-head, weight: 800, size: 8.6pt, fill: tc, title)
    if sub != none { v(2pt, weak: true)
      text(font: f-mono, size: 7pt, fill: slate, sub) }
  }))
#let biarrow(w: 24pt, c: slate, label: none) = box(width: w, height: 12pt, baseline: 4pt, {
  place(left + horizon, dx: 4pt, line(length: w - 8pt, stroke: 0.9pt + c))
  place(left + horizon, dx: 0pt, polygon(fill: c, (5pt,-3pt),(0pt,0pt),(5pt,3pt)))
  place(left + horizon, dx: w - 7pt, polygon(fill: c, (0pt,-3pt),(5pt,0pt),(0pt,3pt)))
  if label != none { place(center + bottom, dy: -8pt,
    text(font: f-head, size: 6pt, fill: c, label)) }
})
#let flow(..items) = align(center, block(above: 0.7em, below: 0.5em,
  breakable: false, stack(dir: ltr, spacing: 0pt, ..items.pos())))

// ---------- sequence diagram ----------------------------------------
#let msg(from, to, body, dashed: false, c: ink) = (
  kind: "msg", from: from, to: to, body: body, dashed: dashed, c: c)
#let snote(lane, body, span: 1, fill: amber-bg, bd: amber) = (
  kind: "note", lane: lane, span: span, body: body, fill: fill, bd: bd)
#let sgap(h: 10pt) = (kind: "gap", h: h)
#let seq(actors, ..steps, w: 430pt, lanecols: none) = {
  let cols = if lanecols == none { actors.map(a => a.at(2)) } else { lanecols }
  let n = actors.len()
  let steps = steps.pos()
  let lane = w / n
  let xs = range(n).map(i => lane * (i + 0.5))
  let headh = 22pt
  let bodyh = 0pt
  for s in steps {
    if s.kind == "gap" { bodyh += s.h }
    else if s.kind == "note" { bodyh += 26pt }
    else { bodyh += 22pt }
  }
  let toth = headh + bodyh + 12pt
  align(center, block(breakable: false, box(width: w, height: toth, {
    for i in range(n) {
      place(top + left, dx: xs.at(i) - 0.4pt, dy: headh - 2pt,
        line(start: (0pt, 0pt), end: (0pt, bodyh + 6pt),
          stroke: (paint: rule-c, thickness: 0.8pt, dash: "dotted")))
    }
    for i in range(n) {
      place(top + left, dx: xs.at(i) - lane/2 + 4pt, dy: 0pt,
        box(width: lane - 8pt, height: 18pt,
          fill: color.mix((cols.at(i), 16%), (paper, 84%)),
          stroke: 0.9pt + cols.at(i), radius: 2pt,
          align(center + horizon,
            text(font: f-head, weight: 800, size: 7pt, fill: cols.at(i),
              actors.at(i).at(0)))))
    }
    let y = headh + 6pt
    for s in steps {
      if s.kind == "gap" { y += s.h }
      else if s.kind == "note" {
        let x0 = xs.at(s.lane) - lane/2 + 6pt
        let wn = lane * s.span - 12pt
        place(top + left, dx: x0, dy: y - 4pt,
          box(width: wn, fill: s.fill, stroke: 0.7pt + s.bd, radius: 2pt,
            inset: (x: 5pt, y: 3pt), align(center,
              text(font: f-head, size: 6.6pt, fill: ink, s.body))))
        y += 26pt
      } else {
        let a = xs.at(s.from)
        let b = xs.at(s.to)
        let lab = text(font: f-mono, size: 6.6pt, fill: s.c, s.body)
        let lo = calc.min(a, b)
        let hi = calc.max(a, b)
        place(top + left, dx: lo, dy: y + 8pt,
          line(start: (0pt,0pt), end: (hi - lo, 0pt),
            stroke: (paint: s.c, thickness: 0.9pt,
              dash: if s.dashed {"dashed"} else {none})))
        if b > a {
          place(top + left, dx: b - 6pt, dy: y + 8pt,
            polygon(fill: s.c, (0pt,-3pt),(6pt,0pt),(0pt,3pt)))
        } else {
          place(top + left, dx: b, dy: y + 8pt,
            polygon(fill: s.c, (6pt,-3pt),(0pt,0pt),(6pt,3pt)))
        }
        place(top + left, dx: lo + 4pt, dy: y - 2pt, lab)
        y += 22pt
      }
    }
  })))
}

// ---------- wire diagrams: real byte streams from examples.json -----
#let EX = json("examples.json")
#let role-fill(r) = {
  if r == "end" { r-end } else if r == "dev" or r == "cmd" { r-hdr }
  else if r == "len" { r-len } else if r == "chk" { r-chk }
  else if r == "dsc" { r-dsc } else if r == "par" { r-par }
  else if r == "esc" { r-esc } else { r-pay }
}
#let hexval(h) = {
  let d = "0123456789ABCDEF"
  d.position(h.at(0)) * 16 + d.position(h.at(1))
}
#let bcell(h, r, ascii: true) = {
  let val = hexval(h)
  let ch = if r == "pay" and ascii and val >= 33 and val < 127 { str.from-unicode(val) } else { "" }
  box(width: 16.2pt, height: if ascii { 17pt } else { 11.5pt },
    fill: role-fill(r), stroke: 0.4pt + rgb("#9aa5ae"), inset: 0pt,
    align(center + top, {
      v(1.6pt)
      text(font: f-mono, size: 6.6pt, weight: if r == "end" { 700 } else { 400 },
        fill: if r == "end" { white } else { ink }, h)
      if ascii {
        linebreak()
        text(font: f-mono, size: 5.6pt, fill: slate, ch)
      }
    }))
}
#let gapcell(n, ascii: true) = box(height: if ascii { 17pt } else { 11.5pt },
  inset: (x: 4pt), stroke: (paint: rgb("#9aa5ae"), thickness: 0.4pt, dash: "dotted"),
  align(center + horizon, text(font: f-head, size: 6.4pt, fill: slate,
    [#sym.dots.h #n more bytes #sym.dots.h])))
// Render one direction of an example.  Long payloads are shown as their
// first `head` bytes and a gap marker; the END that closes the frame is
// always drawn.
#let stream(key, which: "req", head: 24) = {
  let e = EX.at(key)
  let fr = e.at(which)
  let hasascii = fr.any(b => b.at(1) == "pay")
  let firstpay = fr.position(b => b.at(1) == "pay" or b.at(1) == "esc")
  let cells = ()
  let paycount = fr.filter(b => b.at(1) == "pay" or b.at(1) == "esc").len()
  // A row holds 27 cells.  Streams of up to two full rows are drawn whole;
  // longer ones keep one row: the header, as much payload as fits, the gap
  // marker (about four cells wide) and the closing END.
  let fits = calc.max(6, 21 - (if firstpay == none { 0 } else { firstpay }))
  let hh = calc.min(head, fits)
  if firstpay == none or fr.len() <= 54 {
    cells = fr.map(b => bcell(b.at(0), b.at(1), ascii: hasascii))
  } else {
    let shown = fr.slice(0, firstpay + hh)
    cells = shown.map(b => bcell(b.at(0), b.at(1), ascii: hasascii))
    cells.push(gapcell(paycount - hh, ascii: hasascii))
    cells.push(bcell(fr.last().at(0), fr.last().at(1), ascii: hasascii))
  }
  block(breakable: false, above: 0.25em, below: 0.25em, {
    set par(justify: false, leading: 0.25em, spacing: 0.25em)
    cells.join(h(0.8pt))
  })
}
#let wirelab(s) = text(font: f-head, weight: 800, size: 6.6pt, fill: slate,
  tracking: 0.5pt, upper(s))
// Request + reply for one example, labelled.
#let exchange(key, head: 24, label: none) = {
  let e = EX.at(key)
  let replab = if "rep" in e {
    if e.ack { [reply · ACK · #e.replen payload byte#if e.replen != 1 [s]] }
    else { [reply · NAK] }
  } else { [no reply] }
  block(breakable: false, above: 0.7em, below: 0.8em, {
    if label != none { text(font: f-head, size: 7.6pt, fill: ink, label); v(2pt, weak: true) }
    wirelab[request #sym.arrow.r FujiNet#if not e.sent [ · not sent, computed]]
    stream(key, which: "req", head: head)
    if "rep" in e {
      v(2pt)
      wirelab[#replab]
      stream(key, which: "rep", head: head)
    } else {
      v(2pt)
      wirelab[#replab]
    }
  })
}
// Legend of the byte roles, once, in chapter 4.
#let legend() = {
  let item(r, t) = box({ box(width: 9pt, height: 8pt, fill: role-fill(r),
      stroke: 0.4pt + rgb("#9aa5ae")); h(3pt);
    text(font: f-head, size: 7.4pt, t) })
  align(center, block(above: 0.6em, below: 0.8em,
    (item("end", [SLIP END]), item("dev", [device / command]),
     item("len", [length]), item("chk", [checksum]),
     item("dsc", [descriptor]), item("par", [parameters]),
     item("pay", [payload, ASCII below]), item("esc", [escape pair]))
    .join(h(7pt))))
}

// ---------- command reference card ----------------------------------
#let cmdlab(s) = text(font: f-head, weight: 800, size: 6.8pt, fill: slate,
  tracking: 0.5pt, upper(s))
#let hex2(n) = {
  let d = "0123456789ABCDEF"
  d.at(calc.quo(n, 16)) + d.at(calc.rem(n, 16)) + "h"
}
// devcmd: one command.  `params` and `payload` and `reply` are content;
// `ex` names one or more examples.json keys to draw underneath.
#let devcmd(name, code: "", params: [none], payload: [none],
            reply: [empty ACK], ex: (), head: 24, body) = block(
  width: 100%, above: 1.1em, below: 1.1em, breakable: true, {
  block(breakable: false, sticky: true, fill: code-bg,
    stroke: (left: 3pt + fuji, rest: 0.6pt + code-bd),
    inset: (x: 11pt, y: 8pt), {
    grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
      text(font: f-head, weight: 800, size: 11pt, fill: fuji-d, name),
      text(font: f-mono, weight: 700, size: 9.5pt, fill: ink, code))
    v(4pt)
    grid(columns: (50pt, 1fr), row-gutter: 4.5pt, column-gutter: 8pt,
      cmdlab("params"),  text(size: 8.6pt, params),
      cmdlab("payload"), text(size: 8.6pt, payload),
      cmdlab("reply"),   text(size: 8.6pt, reply),
    )
  })
  v(3pt)
  set par(first-line-indent: 0pt)
  body
  let exs = if type(ex) == str { (ex,) } else { ex }
  for k in exs { exchange(k, head: head) }
})

// ---------- appendix listing renderer -------------------------------
// One column at a readable size; lines inside a PLATFORM BEGIN ...
// PLATFORM END block are shaded, so the code to change when porting to
// other hardware stands out on the page.
#let code-listing(title, path, size: 6.9pt) = {
  let src = read(path)
  let lines = src.split("\n")
  let inplat = ()
  let on = false
  for (i, l) in lines.enumerate() {
    if l.contains("PLATFORM BEGIN") { on = true }
    inplat.push(on)
    if l.contains("PLATFORM END") { on = false }
  }
  block(breakable: false, above: 1.0em, below: 3pt, sticky: true, {
    text(font: f-head, weight: 800, fill: fuji, size: 8.5pt,
      tracking: 0.4pt, upper(title))
    v(2pt)
    line(length: 100%, stroke: 0.8pt + rule-c)
  })
  {
    show raw.where(block: true): it => block(width: 100%, breakable: true,
      fill: none, inset: 0pt, stroke: none,
      text(font: f-mono, size: size, fill: ink, it.lines.join(linebreak())))
    show raw.line: it => {
      let shade = inplat.at(it.number - 1, default: false)
      box(width: 100%, fill: if shade { amber-bg } else { none },
        outset: (y: 1.1pt), {
        box(width: 15pt, align(right,
          text(size: size * 0.74, fill: gray, str(it.number))))
        h(5pt)
        it.body
      })
    }
    set par(justify: false, leading: 0.42em, first-line-indent: 0pt)
    raw(src, block: true)
  }
  v(2pt)
  line(length: 100%, stroke: 0.7pt + rule-c)
}

// a short source excerpt (by line range) for the walkthroughs
#let excerpt(path, from, to, title: none, size: 7.6pt) = {
  let lines = read(path).split("\n").slice(from - 1, to)
  while lines.len() > 1 and lines.last().trim() == "" { lines = lines.slice(0, -1) }
  // short excerpts stay whole; long ones may continue on the next page
  // (the title stays with the first part)
  let long = lines.len() > 16
  block(breakable: long, above: 0.8em, below: 0.8em, {
    if title != none {
      block(sticky: true, below: 3pt, text(font: f-head, weight: 800, fill: fuji,
        size: 7.6pt, tracking: 0.4pt, upper(title)))
    }
    block(width: 100%, breakable: long, fill: code-bg, inset: (x: 8pt, y: 6pt),
      stroke: (left: 2.5pt + fuji.mix((paper, 35%)), rest: 0.6pt + code-bd), {
      set par(justify: false, leading: 0.45em, first-line-indent: 0pt)
      for (i, l) in lines.enumerate() {
        box(width: 15pt, align(right, text(font: f-mono, size: size * 0.74,
          fill: gray, str(from + i))))
        h(5pt)
        text(font: f-mono, size: size, if l == "" { " " } else { l })
        linebreak()
      }
    })
  })
}

// snip: an excerpt located by text, not by line number, so it follows the
// listing when the source changes.  It starts at the first line that begins
// with `start` and stops before the next line (after it) that begins with
// `stop`; the real line numbers are shown.
#let snip(path, start, stop, title: none, size: 7.6pt) = {
  let lines = read(path).split("\n")
  let i = lines.position(l => l.starts-with(start))
  assert(i != none, message: "snip: no line starts with " + start)
  let rest = lines.slice(i + 1)
  let j = rest.position(l => l.starts-with(stop))
  assert(j != none, message: "snip: no line starts with " + stop)
  excerpt(path, i + 1, i + 1 + j, title: title, size: size)
}

// a captured terminal session, in a pale panel
#let session(path, title: none, from: 0, to: none) = {
  let lines = read(path).split("\n")
  let lines = if to == none { lines.slice(from) } else { lines.slice(from, to) }
  // trim the trailing blanks a Teletype layout leaves on each line
  let lines = lines.map(l => l.trim(at: end))
  block(breakable: true, above: 0.8em, below: 0.8em, {
    if title != none {
      block(sticky: true, below: 3pt, text(font: f-head, weight: 800, fill: fuji,
        size: 7.6pt, tracking: 0.4pt, upper(title)))
    }
    block(width: 100%, breakable: true, fill: rgb("#f3f1ea"), inset: (x: 9pt, y: 7pt),
      stroke: 0.6pt + rgb("#d8d3c4"), radius: 1pt, {
      set par(justify: false, leading: 0.42em, first-line-indent: 0pt)
      text(font: f-mono, size: 7.4pt, fill: ink,
        lines.map(l => if l == "" { " " } else { l }).join(linebreak()))
    })
  })
}

// ---------- part divider --------------------------------------------
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

// ---------- running header & centered footer ------------------------
#set page(
  header: context {
    if frontmatter.get() { return }
    let pg = here().page()
    let openers = query(heading.where(level: 1)).filter(h => h.location().page() == pg)
    let divs = query(<partdiv>).filter(m => m.location().page() == pg)
    if openers.len() > 0 or divs.len() > 0 { return }
    let hs = query(heading.where(level: 1)).filter(h => h.location().page() <= pg)
    let c = if hs.len() > 0 { upper(hs.last().body) } else { [] }
    set text(font: f-head, size: 8pt, fill: slate)
    grid(columns: (1fr, auto),
      align(left)[The RS-232 FujiNet User's Manual],
      align(right)[#c])
    v(-6pt)
    line(length: 100%, stroke: 0.5pt + rule-c)
  },
  footer: context {
    if frontmatter.get() { return }
    let pg = here().page()
    let divs = query(<partdiv>).filter(m => m.location().page() == pg)
    if divs.len() > 0 { return }
    set text(font: f-head, size: 8.5pt, fill: slate)
    line(length: 100%, stroke: 0.5pt + rule-c)
    v(2pt)
    grid(columns: (1fr, auto, 1fr),
      align(left)[fujinet-firmware · lib/bus/rs232],
      align(center)[#counter(page).display("1")],
      align(right)[First edition · 2026])
  },
)

// ============================================================
// COVER
// ============================================================
#page(header: none, footer: none, {
  v(1.5in)
  text(font: f-head, weight: 800, size: 12pt, fill: fuji,
    tracking: 3pt)[FUJINET ENGINEERING SERIES]
  v(10pt, weak: true)
  line(length: 100%, stroke: 2.5pt + fuji)
  v(16pt, weak: true)
  text(font: f-head, weight: 800, size: 34pt, fill: ink)[
    The RS-232 FujiNet\ User's Manual]
  v(14pt, weak: true)
  text(font: f-body, style: "italic", size: 13pt, fill: slate)[
    Every FujiNet device, driven through a plain serial port]
  v(6pt, weak: true)
  text(font: f-head, size: 10pt, fill: steel)[
    fnconfig.ini · the FujiBus packet · a command reference with real byte
    streams · CONFIG, NETCAT and 5 CARD STUD in Z80 for the Altair 8800]
  v(1fr)
  line(length: 100%, stroke: 0.5pt + rule-c)
  v(8pt)
  grid(columns: (1fr, 1fr), column-gutter: 18pt, row-gutter: 5pt,
    text(font: f-head, size: 9pt, fill: slate)[Any computer with a serial port],
    align(right, text(font: f-head, size: 9pt, fill: slate)[First edition]),
    text(font: f-head, size: 9pt, fill: gray)[Every byte checked on a running adapter],
    align(right, text(font: f-head, size: 9pt, fill: gray)[The FujiNet Project]),
  )
})

// ============================================================
// COLOPHON
// ============================================================
#page(header: none, footer: none, {
  v(0.2in)
  text(font: f-head, weight: 800, size: 15pt, fill: ink)[About this manual]
  v(4pt)
  line(length: 100%, stroke: 1.5pt + fuji)
  v(10pt)
  set par(leading: 0.6em, justify: true)
  set text(size: 9.5pt, fill: slate)
  [This manual is for anyone who wants to drive a FujiNet from a computer
  through an RS-232 serial port, whatever that computer is. It is not tied
  to one platform: it describes the wire itself. It shows how to set the
  adapter up with its `fnconfig.ini` file, how the FujiBus packet is built
  byte by byte, and what every device on the bus accepts and answers, each
  command with the exact byte streams that go out and come back. Three
  appendices then build complete programs in Z80 assembly language for an
  Altair 8800 with a MITS 88-2SIO serial board: a CONFIG that manages host
  and disk slots, a NETCAT terminal, and a client for FujiNet 5 Card Stud.
  Their hardware-dependent code is marked off so that it can be moved to
  any other serial card.

  It is typeset in the FujiNet engineering series style, alongside
  #emph[The FujiNet Network Protocol Handbook], which covers the network
  protocols themselves in depth. Every byte stream printed here was
  captured from a running adapter, and every program was assembled and run
  on a simulated Altair against it.]
  v(14pt)
  text(font: f-head, weight: 800, size: 12pt, fill: ink)[Canonical sources]
  v(6pt)
  set text(size: 9pt, fill: ink)
  grid(columns: (auto, 1fr), row-gutter: 5pt, column-gutter: 12pt,
    text(font: f-mono, fill: fuji-d)[fujinet-firmware],
    [`lib/bus/rs232`, `lib/device/rs232`, `lib/device/fujiDevice`,
     `lib/device/NDevice`, `lib/config` (`670b2ed55`)],
    text(font: f-mono, fill: fuji-d)[fujinet-pc-rs232],
    [the RESEND extension, branch `rs232-resend` (`1c5dcb807`)],
    text(font: f-mono, fill: fuji-d)[fujinet-5cardstud],
    [the 5 Card Stud clients (`7333b1b`)],
    text(font: f-mono, fill: fuji-d)[fujinet-game-system],
    [the 5 Card Stud server and its binary state format (`19770c3`)],
    text(font: f-mono, fill: fuji-d)[simh],
    [the AltairZ80 simulator and its 88-2SIO model (`5cfa8662`)],
    text(font: f-mono, fill: fuji-d)[z88dk],
    [`z88dk-z80asm`, which assembles every listing (`3bd06cad56`)],
  )
  v(1fr)
  line(length: 100%, stroke: 0.5pt + rule-c)
  v(6pt)
  set text(size: 7.5pt, fill: gray)
  set par(leading: 0.5em, justify: true)
  [Altair and MITS are trademarks of their respective holders; no
  affiliation or endorsement is implied. A community work of the FujiNet
  Project --- fujinet.online, 2026.]
})

// ============================================================
// TABLE OF CONTENTS
// ============================================================
#page(header: none, footer: none, {
  show outline.entry.where(level: 1): it => {
    v(7pt, weak: true)
    set text(font: f-head, weight: 800, size: 10pt, fill: ink)
    it
  }
  show outline.entry.where(level: 2): it => {
    set text(font: f-head, size: 8.8pt, fill: slate)
    it
  }
  text(font: f-head, weight: 800, size: 22pt, fill: ink)[Contents]
  v(4pt)
  line(length: 100%, stroke: 2pt + fuji)
  v(12pt)
  outline(title: none, indent: auto, depth: 2)
})

#counter(page).update(1)
#frontmatter.update(false)

// ============================================================
// CHAPTER 1: INTRODUCTION
// ============================================================
#chapter[Introduction]

FujiNet began as a peripheral for the Atari 8-bit computers and grew into
a family: one ESP32 board and one firmware, wearing a different bus
interface on each machine. The RS-232 FujiNet is the plainest member of
that family. It has no cartridge edge and no proprietary connector, just
a nine-pin serial port. Anything that can send and receive bytes on a
serial line can use it: an IBM PC, a CP/M machine, an S-100 system, a
terminal server, a microcontroller, or a Python script on a laptop.

That plainness is what this manual is about. Every FujiNet feature ---
WiFi, the eight host slots and eight disk slots, the `N:` network device
with its two dozen protocols, the real-time clock, the printer and the
modem --- is reached the same way: by sending a small, self-describing
packet down the serial line and reading the one packet that comes back.
Learn that packet and you can drive all of FujiNet from any machine.

== What this manual covers

#step(1)[#strong[Getting connected.] Chapter 2 describes the hardware,
the serial line and its control signals, and #emph[fujinet-pc], the
desktop build of the firmware that speaks the same protocol over a serial
port or a TCP socket. Chapter 3 is a complete guide to `fnconfig.ini`, the
file that holds every setting the adapter keeps.]

#step(2)[#strong[The protocol.] Chapter 4 takes the FujiBus packet apart
byte by byte: SLIP framing, the six-byte header, the checksum, the
parameter descriptors and the payload. Chapter 5 covers the rules of a
transaction, including timeouts, retries and the mistakes the firmware
does not forgive. Chapter 6 lists the devices on the bus.]

#step(3)[#strong[The devices.] Chapters 7 to 13 are the command reference,
one chapter per device: the Fuji device that manages the adapter itself,
the eight disk drives, the eight network units, the clock, the printer,
the modem and the CP/M device. Every command is shown with the byte stream
a program sends and the byte stream FujiNet sends back.]

#step(4)[#strong[Working programs.] The appendices hold a quick reference,
a small FujiBus library in Z80 assembly language, and three programs built
on it for an Altair 8800 with an 88-2SIO serial board: CONFIG, NETCAT and a
client for FujiNet 5 Card Stud. A final appendix runs them all on a
simulated Altair, and another lists the firmware behaviour that may
surprise you.]

== Conventions

Numbers written with an `h` suffix are hexadecimal, as Z80 assemblers write
them: `70h` is 112. Multi-byte values on the wire are always
#strong[little-endian], low byte first; a 16-bit length of 262 travels as
`06 01`. Device and command names follow the firmware source
(`FUJI_GET_WIFISTATUS` is written GET_WIFISTATUS). Parameters are numbered
from zero, so #strong[p0] is the first parameter of a command and #strong[p1]
the second. Slot numbers on the wire count from zero even though people
count host and disk slots from one: disk slot 1 is `p0 = 0`.

The byte streams in this book are drawn as rows of cells, coloured by what
each byte is (the legend is in Chapter 4). They are not illustrations: each
one is a real exchange, captured from a FujiNet running the firmware this
manual describes, and every checksum in them is right.

#note[This manual describes `fujinet-firmware` at commit `670b2ed55`. Where
the firmware does something it plainly was not meant to do, the text says
so where it matters, and Appendix G collects every such case with its
source reference.]

// ============================================================
// PART I
// ============================================================
#part("I", [Getting Connected], [The RS-232 FujiNet hardware, the serial
line and its control signals, fujinet-pc, and the `fnconfig.ini` file that
holds every setting the adapter keeps.])

// ============================================================
// CHAPTER 2: THE RS-232 FUJINET
// ============================================================
#chapter[The RS-232 FujiNet]

The RS-232 FujiNet is an ESP32 with a serial line driver and a DB-9
connector. It is powered from its own USB-C socket, not from the serial
port, so plug it into power first and then into the computer. Inside it
runs the same firmware as every other FujiNet, built for the RS-232 bus.

== Hardware variants

Three firmware targets drive the RS-232 bus. They differ only in how the
bytes reach the ESP32; the packets are identical.

#ktable(columns: (auto, auto, 1fr),
  table.header[Target][Processor][Host link],
  [`fujinet-rs232-rev0`], [ESP32, 8 MB],
  [UART 1 through a TRS3238E line driver: RX on GPIO 13, TX on GPIO 21.],
  [`fujinet-rs232-s3`], [ESP32-S3, 16 MB],
  [UART 1 through a TRS3238E: RX on GPIO 41, TX on GPIO 42. UART 0
   (GPIO 43/44) is the debug console on the USB port.],
  [`fujiversal-rs232`], [ESP32-S3],
  [USB CDC-ACM host: the FujiBus packets travel over USB to a Fujiversal
   cartridge. There is no UART and the baud rate is ignored.],
)

The two serial boards present the port as #strong[data communications
equipment] (DCE), the way a modem does: they carry a female DB-9 that plugs
straight onto a PC's male COM port, with no null-modem cable. On a machine
whose serial port is itself wired as DCE (many S-100 serial boards can be
strapped either way), a null-modem adapter is needed.

#ktable(columns: (auto, auto, auto, 1fr),
  table.header[DB-9 pin][Signal][Direction][Use on the RS-232 FujiNet],
  [2], [RXD], [FujiNet #sym.arrow.r computer], [replies],
  [3], [TXD], [computer #sym.arrow.r FujiNet], [commands],
  [5], [GND], [---], [signal ground],
  [9], [RI],  [FujiNet #sym.arrow.r computer], [network attention (Section 2.2)],
  [1], [DCD], [FujiNet #sym.arrow.r computer], [driven only by the modem device],
  [6], [DSR], [FujiNet #sym.arrow.r computer], [driven only by the modem device],
  [8], [CTS], [FujiNet #sym.arrow.r computer], [held on (see the note below)],
  [4], [DTR], [computer #sym.arrow.r FujiNet], [read only by the modem device],
  [7], [RTS], [computer #sym.arrow.r FujiNet], [read only by the modem device],
)

Three wires are all the bus needs: TXD, RXD and ground. Commands travel
#strong[entirely in-band]\; there is no command line or attention line that
must be asserted before a packet, as there was on the original Atari SIO
bus.

#note[The firmware asks the ESP32 for RTS/CTS flow control, but it never
routes those pins to the UART: CTS is set to #strong[on] at start-up and
stays there, and RTS is never looked at. In practice there is no hardware
flow control, so do not wait for anything before sending. The line is 8 data
bits, no parity, one stop bit.]

== The serial line

The default speed is #strong[115,200 baud], set by `[Serial] baud` in
`fnconfig.ini` (Chapter 3). Any standard rate works; a computer whose UART
cannot reach 115,200 simply needs the adapter set to match it. The Altair
programs in this book run at 9600 baud, the top of the 88-2SIO's usual
jumper settings.

The adapter answers only when spoken to. It never sends a packet on its own,
with one exception: the modem device (Chapter 12) sends text whenever it
has some. A program that never uses the modem can treat every byte that
arrives as part of the reply to the command it just sent.

=== The RI "attention" line

FujiNet can tell a computer that a network unit wants attention without
being asked. While any open network unit has data waiting, has lost its
connection, or has an error to report, the firmware toggles the #strong[RI]
(ring indicator) line. Normally RI is held #strong[on]. When a unit needs
attention RI goes #strong[off] for one interrupt period and on for the
next, every `2 x rate` milliseconds, until the condition is cleared. The
rate is 100 ms by default and can be changed per unit with SET_INT_RATE
(Chapter 9). For 5 ms after each READ the line is left alone.

RI is a convenience. A program can always ask instead, by sending a network
STATUS command, and the programs in this book do exactly that: an 88-2SIO
has no RI input. On fujinet-pc the same signal is driven on the PC's own DTR
or RTS line, chosen by `[Serial] proceed` (Chapter 3).

== Powering up

At power-up the firmware reads `fnconfig.ini`, joins the WiFi network it
names, and loads the host slots and disk slots it lists. Two settings
decide what disk device 31h (disk slot 1) holds when the computer first
asks:

- The #strong[boot image]. `[General] boot_mode` names an image kept in the
  adapter's flash (mode 0 is `/autorun.img`) and the firmware places it in
  disk slot 1 at power-up. It is meant for computers that boot from the
  FujiNet, such as an IBM PC with the FujiNet BIOS driver.
- The #strong[CONFIG switch]. When `[General] configenabled` is `0`, the
  firmware mounts every disk slot listed in `fnconfig.ini` as soon as WiFi
  is up, replacing the boot image with the slot 1 entry if there is one.
  When it is `1` (the default), the slots are loaded but not mounted until a
  program sends MOUNT_ALL or MOUNT_IMAGE.

A computer that does not boot from the FujiNet should normally set
`configenabled=0`, so its disks are ready the moment it starts.

== fujinet-pc

#emph[fujinet-pc] is the FujiNet firmware built as an ordinary program for
#block(sticky: true)[
Linux, macOS or Windows. Built for the RS-232 target it speaks exactly the
same packets as the hardware, and it is the easiest way to develop for the
FujiNet: everything in this manual was captured from it. It reaches the
computer in one of two ways:
]

#ktable(columns: (auto, 1fr),
  table.header[Link][How it is set up],
  [Serial port],
  [`[Serial] port` names the port (`/dev/ttyUSB0`, `COM3`, a pseudo-terminal)
   and `[Serial] baud` its speed. If `port` is empty, `/dev/ttyUSB0` and
   then `/dev/ttyS0` are tried.],
  [TCP (Bus over IP)],
  [With `[BOIP] enabled=1`, fujinet-pc listens on a TCP port (1985 by
   default for the RS-232 build) and the same SLIP frames travel over the
   socket. An emulator, a terminal server or a test script connects to it.],
)

It is started from its `dist` directory:

```
./fujinet -c fnconfig.ini -s SD -u http://0.0.0.0:8000
```

`-c` names the configuration file, `-s` the directory that stands in for the
SD card, and `-u` the address of the built-in web interface. On fujinet-pc
the serial and Bus-over-IP settings are read only at start-up; restart the
program after changing them. Appendix F uses fujinet-pc over TCP to run the
Altair programs on a simulator.

== The web interface

The adapter also serves a configuration page on port 80 (fujinet-pc: the
`-u` address). It shows the network, the host and disk slots and the
printer, and offers a firmware update. On the RS-232 build it can set the
baud rate; the other serial settings are made in `fnconfig.ini`. Anything
the web page can change, a program on the computer can change too, with the
commands in Chapter 7.

// ============================================================
// CHAPTER 3: FNCONFIG.INI
// ============================================================
#chapter[Configuring fnconfig.ini]

Everything the FujiNet remembers between power cycles lives in one text
file, `fnconfig.ini`. The adapter rewrites it whenever a setting changes ---
when a program saves host slots, mounts a disk, or joins a network --- and
reads it at every start. Editing it by hand is the quickest way to set an
adapter up before it is ever connected to a computer.

== Where the file lives

On the hardware the file is kept in two places. At start-up the firmware
looks for `/fnconfig.ini` on the SD card first and uses it if present;
otherwise it reads the copy in its internal flash. When it saves, the
`[General] fnconfig_on_spifs` setting decides where it writes: with `1`
(the default) it writes the flash copy and then copies it to the SD card;
with `0` it writes the SD card only.

So the simplest way to configure an adapter is to put a prepared
`fnconfig.ini` in the root of an SD card, insert it, and power up.

On fujinet-pc the file is whatever `-c` names, `fnconfig.ini` in the
current directory by default.

== The format

The file is a series of sections. Each starts with a name in square brackets
and holds `name=value` lines until the next section:

```
[General]
devicename=ALTAIR-FN
configenabled=0

[WiFi]
SSID=My Network
passphrase=correct horse battery staple
```

#step(1)[Section names are matched without regard to case, by their
#strong[beginning]: `[Host3]` is the third host section, `[Mount1]` the
first disk slot. Numbered sections count from 1.]

#step(2)[Key names are also case-blind. Spaces around the name and the
value are trimmed; spaces inside a value are kept (an SSID may contain
them).]

#step(3)[A yes/no value is true when it begins with `1`, `T`, `t`, `Y` or
`y`. Three keys are stricter and are true only for exactly `1`:
`[WiFi] enabled`, `[WiFi] multi_ap` and `[Bluetooth] enabled`.]

#step(4)[The firmware writes the file with CR LF line endings. It reads
either.]

#step(5)[Sections the firmware does not use on the RS-232 build are still
read and written back, so one file can move between platforms.]

The rest of this chapter lists every section and key. The #strong[RS-232]
column says whether the RS-232 firmware acts on the setting.

== [General]

#btable(columns: (auto, auto, auto, 1fr),
  table.header[Key][Default][RS-232][Meaning],
  [`devicename`], [`FujiNet`], [yes], [The adapter's name, used as its
   network host name.],
  [`timezone`], [empty], [yes], [A POSIX time-zone string such as
   `CST6CDT,M3.2.0,M11.1.0`, used by the clock device. Empty means UTC.],
  [`configenabled`], [`1`], [yes], [`0`: mount every listed disk slot at
   start-up. `1`: leave them for a program to mount (Chapter 2).],
  [`altconfigfile`], [empty], [partly], [An alternate CONFIG image. When it
   is set, slots are not mounted at start-up even if `configenabled=0`.],
  [`boot_mode`], [`0`], [yes], [The image placed in disk slot 1 at
   power-up: `0` `/autorun.img`, `1` `/mount-and-boot.img`, `2` the lobby
   image on `tnfs.fujinet.online`, `3` `/hisioboot-fujinet.img`.],
  [`fnconfig_on_spifs`], [`1`], [hardware], [Where saves go (see above).],
  [`printer_enabled`], [`1`], [yes], [`0` makes the printer device ignore
   every command, without even a reply.],
  [`encrypt_passphrase`], [`0`], [yes], [`1` stores the WiFi passphrase
   obfuscated rather than in clear text.],
  [`hsioindex`], [`-1`], [no], [Atari high-speed SIO index.],
  [`rotationsounds`], [`1`], [no], [Atari disk-rotation sounds.],
  [`config_ng`], [`0`], [no], [Atari CONFIG selection.],
  [`status_wait_enabled`], [`1`], [no], [Atari and Commander X16 only.],
)

== [WiFi] and [WiFiStored1] to [WiFiStored8]

#btable(columns: (auto, auto, 1fr),
  table.header[Key][Default][Meaning],
  [`enabled`], [`1`], [`1` to use WiFi at all.],
  [`SSID`], [empty], [The network to join.],
  [`passphrase`], [empty], [Its password (obfuscated if
   `encrypt_passphrase=1`).],
  [`multi_ap`], [`0`], [`1` to try the stored networks below as well.],
)

Each `[WiFiStoredN]` section holds another `SSID` and `passphrase` for the
adapter to try; a section that exists is in use. A program sets the primary
network with SET_SSID (Chapter 7), which also saves it here.

== [HostN]: the eight host slots

#block(sticky: true)[
A host slot names a place disk images are kept. Sections `[Host1]` to
`[Host8]` each hold:
]

#ktable(columns: (auto, 1fr),
  table.header[Key][Meaning],
  [`type`], [`SD` for the adapter's own SD card, `TNFS` for a TNFS server.],
  [`name`], [`SD` for the SD card; otherwise the server's host name, such
   as `apps.irata.online`.],
)

```
[Host1]
type=SD
name=SD

[Host2]
type=TNFS
name=tnfs.fujinet.online
```

== [MountN]: the eight disk slots

Sections `[Mount1]` to `[Mount8]` say what image each disk slot holds.
Disk slot N is disk device `30h + N`.

#ktable(columns: (auto, 1fr),
  table.header[Key][Meaning],
  [`hostslot`], [The host slot the image lives on, counted #strong[from 1].],
  [`path`], [The image's path on that host.],
  [`mode`], [`r` for read-only, `w` for read/write.],
)

```
[Mount1]
hostslot=2
path=/cpm/altair/cpm22.dsk
mode=r
```

== [PrinterN]

#ktable(columns: (auto, 1fr),
  table.header[Key][Meaning],
  [`type`], [The printer emulation, a number from the table in Chapter 11.
   An unknown number falls back to `1`, a text file with trailing blanks
   trimmed.],
  [`port`], [The printer port, 1 to 4.],
)

#caution[Only the first printer is ever used on the RS-232 build, and a bug
in the section-name parser makes every `[PrinterN]` section load into that
first slot. If you have more than one, the last in the file wins. Keep just
`[Printer1]`.]

== [Serial] and [BOIP]

These two sections choose the link to the computer.

#btable(columns: (auto, auto, auto, 1fr),
  table.header[Key][Default][Applies to][Meaning],
  [`[Serial] baud`], [`115200`], [hardware, fujinet-pc],
   [Line speed. Ignored on the USB `fujiversal-rs232` target.],
  [`[Serial] port`], [empty], [fujinet-pc],
   [The serial device to open.],
  [`[Serial] proceed`], [`DTR`], [fujinet-pc],
   [Which of the PC's output lines carries the RI attention signal:
    `DTR`, `RTS` or `none`.],
  [`[Serial] command`], [`DSR`], [---],
   [An Atari setting, read but not used by the RS-232 bus.],
  [`[BOIP] enabled`], [`0`], [hardware, fujinet-pc],
   [`1` to carry the bus over TCP instead of the serial port.],
  [`[BOIP] host`], [hardware: empty; fujinet-pc: `localhost`],
   [hardware, fujinet-pc], [The address to listen on; empty or `*` means
    every address.],
  [`[BOIP] port`], [`1985`], [hardware, fujinet-pc],
   [The TCP port. An empty or out-of-range value means 1985.],
)

#caution[fujinet-pc writes the `[Serial]` section twice when it saves
(once with `port`, once with `baud`). Both are read correctly, so the
duplicate is harmless. But it writes `proceed` back only on the Atari build:
on the RS-232 build a hand-edited `proceed=RTS` is lost the next time the
adapter saves its settings, and RI returns to DTR.]

== [Modem] and [Phonebook1] to [Phonebook16]

#btable(columns: (auto, auto, 1fr),
  table.header[Key][Default][Meaning],
  [`modem_enabled`], [`1`], [`0` silences the modem device entirely.],
  [`sniffer_enabled`], [`0`], [`1` records modem traffic to a file.],
  [`connect_delay_ms`], [`2000`], [Atari only.],
)

Each `[PhonebookN]` section maps a number the modem can dial to a host:
`number`, `host` and `port`. Chapter 12 shows them in use.

== [Network]

#btable(columns: (auto, auto, 1fr),
  table.header[Key][Default][Meaning],
  [`sntpserver`], [`pool.ntp.org`], [The time server the clock uses.],
  [`log_network_json`], [`0`], [`1` logs every JSON document the parser
   reads (debug builds).],
  [`netstream_*`], [---], [Five keys for the Atari NetStream feature
   (`host`, `port`, `mode`, `register`, `rx_depth`); not used on RS-232.],
)

== Cloud credentials: [S3], [GoogleDrive], [OneDrive]

These hold the credentials for the `S3:`, `GDRIVE:`, `GCAL:`, `GMAIL:` and
`ONEDRIVE:` protocols of the network device. `[S3]` has `endpoint`,
`region`, `access_key`, `secret_key` and `use_ssl` (default `1`);
`[GoogleDrive]` and `[OneDrive]` have `refresh_token`, `access_token` and
`token_expiry`. #emph[The FujiNet Network Protocol Handbook] explains how
to obtain them.

== Sections the RS-232 build ignores

`[Bluetooth]`, `[Cassette]`, `[CPM]` and `[ENABLE]` are read and written
back, but nothing on the RS-232 bus uses them. `[Tape1]` is read too, and
because of a bug it overwrites the first disk slot when present; leave it
out.

== Three working files

=== An Altair at 9600 baud

The configuration the Altair programs in this book were written for: the
88-2SIO's port B strapped for 9600 baud, two TNFS hosts and the SD card,
CP/M in disk slot 1, mounted at power-up.

```
[General]
devicename=ALTAIR-FN
configenabled=0
timezone=CST6CDT,M3.2.0,M11.1.0

[WiFi]
enabled=1
SSID=My Network
passphrase=my password

[Serial]
baud=9600

[Host1]
type=SD
name=SD

[Host2]
type=TNFS
name=tnfs.fujinet.online

[Host3]
type=TNFS
name=apps.irata.online

[Mount1]
hostslot=2
path=/cpm/altair/cpm22.dsk
mode=r

[Printer1]
type=1
port=1
```

=== fujinet-pc on a serial port

```
[Serial]
port=/dev/ttyUSB0
baud=115200
proceed=DTR

[BOIP]
enabled=0
```

=== fujinet-pc for a simulator

The configuration Appendix F uses: the bus is carried over TCP port 1985 on
the local machine, where the simulated Altair's serial port connects.

```
[BOIP]
enabled=1
host=localhost
port=1985
```

#tip[Settings that a program can change, the adapter saves for you. A
program that writes host slots, mounts disks or joins a network does not
need to touch `fnconfig.ini` at all: the firmware rewrites it with the new
values.]

// ============================================================
// PART II
// ============================================================
#part("II", [The FujiBus Protocol], [How a command is framed, checked and
answered: the SLIP envelope, the six-byte header, the checksum, the
parameter descriptors and the payload; the rules of a transaction; and the
devices that answer on the bus.])

// ============================================================
// CHAPTER 4: THE PACKET
// ============================================================
#chapter[The FujiBus Packet]

Every exchange on the RS-232 bus is one packet from the computer and one
packet back. The firmware calls the format #emph[FEP-004]\; this manual
calls it the #strong[FujiBus packet]. It is self-describing: the packet
says how long it is, checks itself, and says how many parameters it carries
and how wide each one is. This chapter builds one from nothing.

== A first look

Here is the smallest useful exchange: GET_WIFISTATUS, which asks the
adapter whether it is on the network. The computer sends eight bytes and
the adapter answers with nine.

#legend()
#exchange("first")

#block(sticky: true)[
Read the request from the left:
]

#ktable(columns: (auto, auto, 1fr),
  table.header[Byte][Value][Meaning],
  [`C0`], [END], [SLIP: a frame starts.],
  [`70`], [device], [The Fuji device, which manages the adapter.],
  [`FA`], [command], [GET_WIFISTATUS.],
  [`06 00`], [length], [The packet is 6 bytes long, low byte first.],
  [`71`], [checksum], [Of all six bytes, computed with this byte as zero.],
  [`00`], [descriptor], [No parameters follow.],
  [`C0`], [END], [SLIP: the frame ends.],
)

The reply has the same shape. Its device byte is again `70`, the device
that answered; its command byte is `06`, #strong[ACK], meaning success; its
length is 7 and its descriptor 0. The one byte after the header, `03`, is the
answer: connected. The rest of this chapter takes each part in turn.

== SLIP framing

#block(sticky: true)[
A packet travels inside a #strong[SLIP] frame (RFC 1055). The frame begins
and ends with the byte `C0`, called END. Because `C0` marks the edges, a
`C0` inside the packet must be disguised, and so must the escape byte
itself:
]

#ktable(columns: (auto, auto),
  table.header[Packet byte][Sent on the wire as],
  [`C0`], [`DB DC`],
  [`DB`], [`DB DD`],
  [anything else], [itself],
)

#block(sticky: true)[
The receiver reverses this: `DB DC` becomes `C0`, `DB DD` becomes `DB`.
Escaping happens #strong[after] the packet is built and checksummed, and is
undone #strong[before] it is checked; the length and the checksum always
describe the packet itself, never its escaped form. This WRITE carries the
two awkward bytes as its payload; on the wire each becomes a pair, and the
frame grows from 12 bytes to 14 while its length field still says `0A`, ten:
]

#exchange("esc")

#block(sticky: true)[
Four rules govern the frame:
]

#step(1)[#strong[Send exactly one END before a packet and one after it.]
RFC 1055 suggests opening a frame with an extra END to flush line noise.
Do not: the firmware takes two ENDs in a row as an empty frame, discards it,
and then reads the real packet as stray bytes (Chapter 5).]

#step(2)[#strong[Bytes before the first END are not part of the packet.]
The firmware hands them to the modem device as if typed at a modem.]

#step(3)[#strong[A frame ends at the next END.] There is no other length
limit on the wire; the length field inside is what is checked.]

#step(4)[#strong[An escape followed by anything but `DC` or `DD` is
dropped.] The packet then fails its length or checksum test.]

== The header

#block(sticky: true)[
After SLIP decoding, every packet starts with the same six bytes:
]

#bytefield(("device", 52pt), ("command", 52pt), ("length (lo)", 58pt),
  ("length (hi)", 58pt), ("checksum", 52pt), ("descriptor", 58pt),
  ("params ...", 60pt), ("payload ...", 66pt))

#ktable(columns: (auto, auto, 1fr),
  table.header[Offset][Field][Meaning],
  [0], [device], [The device the packet is for; in a reply, the device that
   answers. Chapter 6 lists them.],
  [1], [command], [What to do. In a reply: `06` ACK or `15` NAK.],
  [2--3], [length], [The total length of the packet in bytes, #strong[header
   included], low byte first. It counts the packet before SLIP escaping and
   without the END bytes. A packet whose length field disagrees with what
   arrived is thrown away.],
  [4], [checksum], [See the next section.],
  [5], [descriptor], [The first parameter descriptor (Section 4.5). `00`
   means no parameters.],
)

== The checksum

The checksum is an 8-bit sum of every byte of the packet --- header,
parameters and payload --- with an #strong[end-around carry]: each time the
running sum overflows 255, the carry is added back into the low byte. It is
computed with the checksum byte itself set to zero, and it is stored as it
comes out, not inverted. In C:

```c
uint8_t fb_checksum(const uint8_t *buf, size_t len)
{
    uint16_t chk = 0;
    for (size_t i = 0; i < len; i++) {
        chk += buf[i];
        chk = (chk >> 8) + (chk & 0xFF);    /* fold the carry back in */
    }
    return (uint8_t) chk;
}
```

In Z80 the fold is a single instruction: `ADD` sets the carry flag on
overflow, and `ADC A,0` adds it back. This is the routine the programs in
this book use:

```
CKSUM:  XOR     A               ; checksum of BC bytes at HL
CKS1:   ADD     A,(HL)
        ADC     A,0             ; end-around carry
        INC     HL
        DEC     BC
        LD      D,A
        LD      A,B
        OR      C
        LD      A,D
        JR      NZ,CKS1
        RET
```

#block(sticky: true)[
The GET_WIFISTATUS request works out like this, with the checksum byte
taken as zero:
]

#ktable(columns: (auto, auto, auto, auto),
  table.header[Byte][Running sum][Carry out][After the fold],
  [`70`], [`070`], [0], [`70`],
  [`FA`], [`16A`], [1], [`6B`],
  [`06`], [`071`], [0], [`71`],
  [`00`], [`071`], [0], [`71`],
  [`00`], [`071`], [0], [`71`],
  [`00`], [`071`], [0], [`71`],
)

The result, `71`, is what goes in byte 4. To check a packet that arrives,
save its checksum byte, set it to zero, compute, and compare.

== Parameters and descriptors

#block(sticky: true)[
Most commands take a few small numbers: a slot, a sector, a length, a mode.
These travel as #strong[parameters], straight after the header. Each
parameter is 1, 2 or 4 bytes wide, little-endian, and the descriptor byte
says how many there are and how wide:
]

#ktable(columns: (auto, auto, auto, auto),
  table.header[Descriptor (low 3 bits)][Parameters][Each][Bytes],
  [`0`], [none], [---], [0],
  [`1`], [1], [8-bit], [1],
  [`2`], [2], [8-bit], [2],
  [`3`], [3], [8-bit], [3],
  [`4`], [4], [8-bit], [4],
  [`5`], [1], [16-bit], [2],
  [`6`], [2], [16-bit], [4],
  [`7`], [1], [32-bit], [4],
)

#block(sticky: true)[
SET_DEVICE_FULLPATH, for instance, takes three 8-bit parameters (disk slot,
host slot, mode), so its descriptor is `03` and the three bytes follow the
header; after them comes the path as payload:
]

#exchange("multi", head: 16)

#block(sticky: true)[
A disk READ takes one 32-bit sector number, descriptor `07`:
]

#block(breakable: false, {
  wirelab[request #sym.arrow.r FujiNet · read sector 0 from disk slot 1]
  stream("descr")
})

One descriptor describes at most four bytes of parameters, all the same
width. When a command needs more, or mixed widths, bit 7 of the descriptor
is set to say #emph[another descriptor follows]\; the extra descriptor bytes
come right after the header, #strong[before] any parameter values. One
8-bit parameter followed by one 16-bit parameter would be descriptors `81 05`
and then the three value bytes. Bits 3 to 6 are not used. No command on the
RS-232 bus needs more than one descriptor, but the firmware decodes chains
correctly.

#note[The firmware reads a parameter's #strong[value], not its width: a
slot number sent as a 16-bit parameter works as well as one sent as 8 bits.
This manual uses the natural widths --- 8 bits for slots, modes and flags,
16 bits for byte counts, 32 bits for sector numbers and offsets --- and so
do the example programs.]

#caution[Send #strong[every] parameter a command uses, even the ones it
ignores. A handler that reads a parameter the packet does not carry throws
an exception the firmware does not catch: fujinet-pc aborts, and the
hardware restarts. A disk STATUS sent with no parameter crashes the adapter
this way.]

== The payload

Everything after the parameters, up to the end of the packet, is the
#strong[payload]. Its length is not sent separately: it is the packet
length minus the header, the extra descriptors and the parameters. Commands
use the payload two ways:

- #strong[Fixed-size structures.] A host-slot table is always 256 bytes, an
  SSID-and-password block 97, a path 256. Send them #strong[at full size],
  padding unused bytes with zeroes. The firmware copies whatever arrives into
  a buffer of the right size: a short payload leaves the rest of the buffer
  holding old or uninitialised memory (and some builds reject it outright).
- #strong[Variable data.] A network devicespec, bytes written to a network
  connection, a time-zone string: these are sent at their natural length.
  Strings the firmware treats as C strings should end with a NUL byte; the
  reference says which.

== The reply

The adapter answers every packet it can read with exactly one packet. Its
#strong[device] byte is the device that answered and its #strong[command]
#block(sticky: true)[
byte is the result:
]

#ktable(columns: (auto, auto, 1fr),
  table.header[Command byte][Name][Meaning],
  [`06`], [ACK], [Success. Any data the command returns is the payload of
   this same packet.],
  [`15`], [NAK], [Failure. A NAK #strong[never] carries data.],
)

#block(sticky: true)[
A reply has no parameters, so its descriptor is always `00` and its payload
starts at offset 6. Its length is 6 plus the number of data bytes. A command
that returns nothing is answered with an empty ACK:
]

#exchange("fuji.mount_host")

#block(sticky: true)[
And a command the device does not know, or cannot carry out, with a bare
NAK:
]

#exchange("fuji.bad_command")

== Building a packet, step by step

#step(1)[Write the device, the command, two zero bytes for the length, a
zero for the checksum, and the descriptor.]
#step(2)[Append any extra descriptors, then the parameter values, each
little-endian.]
#step(3)[Append the payload, padding fixed-size structures with zeroes.]
#step(4)[Store the total length at offsets 2 and 3, low byte first.]
#step(5)[Compute the checksum over the whole packet, with offset 4 still
zero, and store it at offset 4.]
#step(6)[Send `C0`, then each byte with `C0` and `DB` escaped, then `C0`.]

Receiving is the same in reverse: collect bytes from one END to the next,
undo the escapes, check that the length field matches the number of bytes,
check the checksum, then read the command byte.

// ============================================================
// CHAPTER 5: TRANSACTIONS
// ============================================================
#chapter[Transactions]

A transaction is one command and its reply. The adapter handles one at a
time, completely, before it reads the next packet, so the computer is always
the one in charge of the pace. This chapter covers timing, what happens when
something goes wrong, and how to recover.

== One command, one reply

#fig(seq((("COMPUTER", 0, mast), ("FUJINET", 1, perif)),
  msg(0, 1, "C0 70 F4 06 00 6B 00 C0   READ_HOST_SLOTS"),
  snote(1, [the Fuji device builds 256 bytes of host names]),
  msg(1, 0, "C0 70 06 06 01 ... C0   ACK + 256 bytes", c: perif),
  sgap(h: 4pt),
  msg(0, 1, "C0 70 F9 07 00 72 01 00 C0   MOUNT_HOST p0=0"),
  snote(1, [connects to the host; a TNFS server may take a while]),
  msg(1, 0, "C0 70 06 06 00 7C 00 C0   empty ACK", c: perif),
  w: 440pt), caption: [Two transactions. Nothing overlaps: the next command
  is sent only after the reply to the last one is in.])

Write data travels in the command itself: a program that writes a sector
puts the 512 bytes in the payload of the WRITE packet, and the reply is an
empty ACK. Read data travels in the reply. No command needs a second packet
in either direction.

== Timing

#strong[Within a packet], the firmware waits at most 200 ms for each next
byte on a serial port (500 ms over TCP). If the line goes quiet for longer
than that in the middle of a frame, it gives up on the frame and discards
what it had. A computer must therefore send each packet in one go, without
pausing in the middle --- an easy rule for any program that builds the
packet first and sends it from memory.

#strong[Before the reply]: most commands are answered within a few
#block(sticky: true)[
milliseconds. Some take much longer, because the adapter has to do
something slow on the network before it can answer:
]

#ktable(columns: (auto, 1fr),
  table.header[Command][What it waits for],
  [network OPEN], [a DNS lookup, a TCP connection, a TLS handshake for
   `HTTPS:`; seconds],
  [SET_SSID], [joining a WiFi network; up to tens of seconds],
  [MOUNT_HOST, OPEN_DIRECTORY], [a TNFS server],
  [MOUNT_IMAGE], [opening an image on a remote host],
  [COPY_FILE], [the whole copy],
)

So a program needs two timeouts: a long one (ten seconds or more) for the
first byte of a reply, and a short one between the bytes of a reply once it
has begun. The Z80 library in Appendix B waits ten seconds for the first byte
by default, and a quarter of a second between bytes; CONFIG and NETCAT raise
the first to 20 or 30 seconds around the slow commands.

#strong[After a reset or power-up], the firmware throws away anything that
arrives until the line has been quiet for 100 ms.

== When no reply comes

#block(sticky: true)[
The adapter stays silent, rather than sending a NAK, in these cases:
]

#btable(columns: (auto, 1fr),
  table.header[Cause][What the firmware does],
  [Bad checksum, wrong length, or a malformed frame],
  [Logs "packet fail" and discards it. #strong[No reply at all.]],
  [A frame that stalled more than 200 ms],
  [Discarded as above.],
  [RESET (`FF`) to the Fuji device], [Restarts immediately, without an ACK.],
  [Any command to the printer when `printer_enabled=0`], [Ignored.],
  [A missing parameter], [The firmware crashes (Chapter 4).],
  [Any command to the modem device], [The modem's replies are never
   framed; see Chapter 12.],
)

#block(sticky: true)[
A packet for a device that does not exist is answered with a NAK whose
device byte is `00`:
]

#exchange("unknown_dev")

== Retrying

#block(sticky: true)[
When the reply does not come, or comes damaged, the computer cannot know
whether the adapter ever saw the command. That matters for commands that
change something:
]

#btable(columns: (auto, 1fr),
  table.header[Kind of command][Safe to send again?],
  [Reads of state: GET_WIFISTATUS, READ_HOST_SLOTS, STATUS, disk READ],
  [Yes. Running them twice changes nothing.],
  [Settings: WRITE_HOST_SLOTS, SET_DEVICE_FULLPATH, MOUNT_IMAGE],
  [Yes. The second run sets the same values again.],
  [Network READ], [#strong[No.] The first READ took the bytes out of the
   adapter's buffer; reading again returns the #emph[next] bytes, and the
   lost ones are gone.],
  [Network WRITE, printer WRITE], [#strong[No.] The data would be written
   twice.],
  [Hash, Base64 and QR #emph[input] commands], [#strong[No.] They append to
   a buffer.],
)

For the first two kinds, the cure for a lost or damaged reply is to send the
command again. For the others there are two choices: accept the rare loss,
or use RESEND where the firmware has it.

#sidebar("RESEND: where supported")[A FujiNet build that implements RESEND
(fujinet-pc, branch `rs232-resend`) keeps a copy of the last reply it sent.
Command #strong[`05`] (ASCII ENQ), sent to any device with no parameters and
no payload, makes it send that reply again, byte for byte, #emph[without]
running the command a second time. If it has sent nothing yet it answers
NAK.

#exchange("resend")

Use RESEND only when part of a reply arrived and it was damaged --- a
wrong length or checksum, or a frame that stopped part-way. If #emph[nothing]
arrived, the command itself may never have reached the adapter, and RESEND
would fetch the reply to the command before it. Firmware without RESEND
(including the `670b2ed55` firmware this manual describes) treats `05` as
an unknown command and answers NAK:

#exchange("resend.nak")

The Z80 library in Appendix B asks for RESEND when it is assembled with
`USE_RESEND` set, and sends the whole command again otherwise.]

== Stale bytes

A reply should only ever answer the command just sent. Two things can leave
extra bytes waiting on the line and confuse the next exchange:

- A reply that arrived after the computer had given up on it.
- A command that answers twice: SET_SSID sends #strong[two] NAKs when the
  adapter cannot join the network.

The defence is simple: before sending a command, read and discard anything
already waiting. The Z80 library's FBCALL does this on every call.

== Sharing the line with the modem

The modem device (Chapter 12) shares the serial line with the FujiBus
packets, which leads to two traps:

- Any bytes that arrive #strong[outside] a frame are given to the modem as
  if typed into it. A packet that loses its opening END is therefore not an
  error the adapter reports: its bytes go to the modem and the command is
  silently lost.
- While the modem has a connection open, it sends the remote end's data down
  the line #strong[unframed], interleaved with any FujiBus replies. A
  program that uses the modem must be ready to separate the two; a program
  that does not use the modem should leave it alone (or set
  `modem_enabled=0`).

== The rules, in short

#step(1)[One END, the packet with `C0` and `DB` escaped, one END.]
#step(2)[Length and checksum describe the unescaped packet, header
included, with the checksum byte taken as zero.]
#step(3)[Send every parameter the command reads; pad fixed-size payloads to
full size.]
#step(4)[Send a packet without pausing in the middle.]
#step(5)[Drain stale input, send, then wait long for the first reply byte
and briefly for the rest.]
#step(6)[ACK carries the data; NAK carries nothing; silence means the
packet was not read.]
#step(7)[Retry reads freely; think before retrying anything that consumes
or appends.]

// ============================================================
// CHAPTER 6: THE DEVICES ON THE BUS
// ============================================================
#chapter[The Devices on the Bus]

#block(sticky: true)[
Each packet names a device. The RS-232 firmware answers to these numbers:
]

#ktable(columns: (auto, auto, 1fr, auto),
  table.header[Device][Name][What it is][Chapter],
  [`70`], [Fuji], [The adapter itself: WiFi, host slots, disk slots,
   directories, application keys, and helpers for hashing, Base64 and QR
   codes.], [7],
  [`31`--`38`], [Disk], [The eight disk drives, one per disk slot: `31` is
   disk slot 1.], [8],
  [`71`--`78`], [Network], [The eight `N:` units: each opens one URL ---
   HTTP, TCP, TNFS, SSH and two dozen more.], [9],
  [`45`], [Clock], [The real-time clock, in a dozen formats.], [10],
  [`40`], [Printer], [A printer that renders to a file on the adapter.], [11],
  [`50`], [Modem], [A Hayes-style modem that dials TCP hosts.], [12],
  [`5A`], [CP/M], [Defined, but not present on the RS-232 bus.], [13],
)

The disk drives and network units are numbered from one in conversation
(disk slot 1, unit `N1:`) and from zero in parameters: the Fuji command that
mounts an image into disk slot 3 takes `p0 = 2`, and that drive then answers
as device `33`.

== A first session

The commands below, sent in order, take a freshly powered adapter from
nothing to reading a disk sector. Every one is described in Part III; the
streams here are the real ones.

#step(1)[Is the adapter on the network? GET_WIFISTATUS answers `03` for
connected.]
#exchange("fuji.wifi_status")

#step(2)[Which hosts does it know? READ_HOST_SLOTS returns 8 names of 32
bytes each.]
#exchange("fuji.read_hosts", head: 16)

#step(3)[Connect to host slot 1 (the SD card) with MOUNT_HOST, `p0 = 0`.]
#exchange("fuji.mount_host")

#step(4)[Put `/test/disk.img` from host slot 1 into disk slot 2, read-only:
SET_DEVICE_FULLPATH with `p0 = 1` (disk slot 2), `p1 = 0` (host slot 1),
`p2 = 1` (read), then MOUNT_IMAGE with `p0 = 1`, `p1 = 1`.]
#exchange("fuji.set_fullpath", head: 16)
#exchange("fuji.mount_image")

#step(5)[Read sector 0 from disk slot 2, which is device `32`.]
#exchange("disk.read", head: 16)

That is the whole pattern. Everything else in this manual is the same
exchange with a different device, command, parameters and payload.

// ============================================================
// PART III
// ============================================================
#part("III", [The Devices], [A command reference for every device on the
RS-232 bus: the Fuji device, the disk drives, the network units, the clock,
the printer, the modem and the CP/M device. Every command is shown with the
bytes a program sends and the bytes FujiNet sends back.])

// ============================================================
// CHAPTER 7: THE FUJI DEVICE
// ============================================================
#chapter[The Fuji Device (70h)]

Device `70` is the adapter itself. It joins WiFi networks, keeps the eight
host slots and eight disk slots, browses the hosts, mounts disk images,
stores small files for programs, and offers a few helpers --- hashing,
Base64, QR codes, random numbers --- that are hard to do on a small
computer. Its commands fall into groups, and this chapter takes them group
by group.

Each command below is shown as a card: its name and command byte, the
parameters it reads, the payload it expects, and what it answers, followed
by a real exchange.

== WiFi

The adapter joins the network named in `fnconfig.ini` at power-up. These
commands report on that connection and choose another network.

#devcmd([GET_WIFISTATUS], code: "FA",
  reply: [1 byte: `03` connected, `06` not connected],
  ex: "fuji.wifi_status")[
The quick question every program should ask first. The two values are
borrowed from the ESP32's own status codes.]

#devcmd([GET_WIFI_ENABLED], code: "EA",
  reply: [1 byte: `01` if WiFi is enabled in `fnconfig.ini`, `00` if not],
  ex: "fuji.wifi_enabled")[]

#devcmd([SCAN_NETWORKS], code: "FD",
  reply: [1 byte: the number of networks found],
  ex: "fuji.scan")[
Scans for networks and keeps the list for GET_SCAN_RESULT. A scan takes a
second or two; the reply waits for it. (fujinet-pc, which has no radio,
always reports sixteen networks named after its configured one.)]

#devcmd([GET_SCAN_RESULT], code: "FC",
  params: [p0: index, from 0 to count #sym.minus 1],
  reply: [34 bytes: SSID (33, NUL-padded), then the signal strength as a
    signed byte in dBm],
  ex: "fuji.scan_result")[
An index beyond the scan list is answered with NAK. The signal strength is
negative: `FF` is #sym.minus;1 dBm (the fujinet-pc stand-in), a real
network nearby reads something like `C4`, #sym.minus;60 dBm.]

#devcmd([SET_SSID], code: "FB",
  payload: [97 bytes: SSID (33, NUL-padded) then password (64, NUL-padded)],
  reply: [empty ACK once connected],
  ex: "fuji.set_ssid")[
Joins the network, and when that succeeds saves it to `fnconfig.ini` as the
`[WiFi]` network. The reply waits until the adapter has joined, which can
take many seconds: allow at least thirty.]

#caution[When the adapter cannot join the network, SET_SSID answers with
#strong[two] NAK packets, not one. Read and discard the second before the
next command (the Z80 library drains stale input before every command, for
this reason).]

#devcmd([GET_SSID], code: "FE",
  reply: [97 bytes: SSID (33) then password (64)],
  ex: "fuji.get_ssid")[
Returns the configured network.]

#caution[GET_SSID returns the #strong[stored WiFi password] in clear text in
its last 64 bytes. Use GET_ADAPTERCONFIG to show the current network instead.]

== Adapter information

#devcmd([GET_ADAPTERCONFIG], code: "E8",
  reply: [140 bytes: the structure below],
  ex: "fuji.adapter", head: 20)[
Everything about the adapter's network connection, in one reply. The
addresses are binary, most significant byte first, the way they are written:
`127.0.0.1` is `7F 00 00 01`.]

#ktable(columns: (auto, auto, 1fr),
  table.header[Offset][Size][Field],
  [0], [33], [SSID of the current network, NUL-terminated; `NOT CONNECTED`
   when there is none],
  [33], [64], [host name],
  [97], [4], [IP address],
  [101], [4], [gateway],
  [105], [4], [netmask],
  [109], [4], [DNS server],
  [113], [6], [MAC address],
  [119], [6], [BSSID (the access point's MAC address)],
  [125], [15], [firmware version, NUL-terminated (e.g. `v1.6-670b2ed55`)],
)

The IP and DNS addresses are filled in only while the adapter is connected.

#devcmd([GET_ADAPTERCONFIG_EXTENDED], code: "C4",
  reply: [240 bytes: the 140 above, then the addresses as text],
  ex: "fuji.adapter_ext", head: 20)[
The same 140 bytes, followed by the addresses already formatted as
NUL-terminated strings, so a small program can print them without
converting:]

#ktable(columns: (auto, auto, 1fr),
  table.header[Offset][Size][Field],
  [140], [16], [IP address as text, `"192.168.1.42"`],
  [156], [16], [gateway as text],
  [172], [16], [netmask as text],
  [188], [16], [DNS server as text],
  [204], [18], [MAC address as text, `"A0:B7:65:12:34:56"`],
  [222], [18], [BSSID as text],
)

#devcmd([STATUS], code: "53",
  reply: [4 bytes, all zero],
  ex: "fuji.status")[
Present for compatibility. On the RS-232 bus it always answers four zero
bytes.]

#devcmd([DEVICE_READY], code: "00",
  reply: [512 bytes, every one `41` (ASCII `A`)],
  ex: "fuji.device_ready", head: 12)[
A test of the link: a known 512-byte pattern that exercises a long reply.
A program can use it at start-up to check that its receive code keeps up.]

== Host slots

#block(sticky: true)[
A #strong[host slot] names a place that disk images live: the adapter's SD
card, or a TNFS server on the network. There are eight. The table is held
as eight fixed 32-byte fields:
]

#bytefield(("host 1: 32 bytes", 96pt), ("host 2: 32 bytes", 96pt),
  ("...", 50pt), ("host 8: 32 bytes", 96pt))

Each field holds a NUL-terminated name: `SD` for the SD card, otherwise a
server's host name. An empty field (first byte zero) is an unused slot.

#devcmd([READ_HOST_SLOTS], code: "F4",
  reply: [256 bytes: 8 host names of 32 bytes],
  ex: "fuji.read_hosts", head: 20)[]

#devcmd([WRITE_HOST_SLOTS], code: "F3",
  payload: [256 bytes: 8 host names of 32 bytes],
  ex: "fuji.write_hosts", head: 20)[
Replaces the whole table and saves it to `fnconfig.ini`. All eight hosts are
marked as not connected; mount a host again before browsing it. To change one
slot, read the table, change that field, and write all 256 bytes back.]

#devcmd([MOUNT_HOST], code: "F9",
  params: [p0: host slot, 0 to 7],
  ex: "fuji.mount_host")[
Connects to the host: for a TNFS server this opens a session, which may take
a moment. Mount a host before opening a directory on it or mounting an image
from it.]

#devcmd([UNMOUNT_HOST], code: "E6",
  params: [p0: host slot],
  ex: "fuji.unmount_host")[
Closes the host's session and unmounts every disk slot that uses it. It is
answered with NAK if the host was never mounted --- and, on fujinet-pc, for the
SD card, which cannot be unmounted:]
#exchange("fuji.unmount_host_sd")

#devcmd([SET_HOST_PREFIX], code: "E1",
  params: [p0: host slot],
  payload: [256 bytes: a directory path, NUL-terminated],
  ex: "fuji.set_prefix", head: 16)[
Sets a working directory on the host. Later paths on that host that do not
begin with `/` are taken relative to it.]

#devcmd([GET_HOST_PREFIX], code: "E0",
  params: [p0: host slot],
  reply: [256 bytes: the prefix, NUL-terminated],
  ex: "fuji.get_prefix", head: 16)[
Read only up to the first NUL. The rest of the 256 bytes is whatever was in
the firmware's buffer, and if no prefix was ever set the reply is
#strong[entirely] leftover memory: set a prefix (even an empty one) before
relying on this.]

== Browsing a host

Directories are read one entry at a time, like a file. The adapter keeps one
directory open at a time, across all hosts.

#devcmd([OPEN_DIRECTORY], code: "F7",
  params: [p0: host slot],
  payload: [256 bytes: path, NUL, then an optional pattern and NUL],
  ex: "fuji.open_dir", head: 16)[
Opens a directory on a mounted host. A trailing `/` on the path is removed.
To list only some files, put a wildcard pattern after the path's NUL:
`/games` NUL `*.img` NUL. Opening a directory closes any that was open.]

#devcmd([READ_DIR_ENTRY], code: "F6",
  params: [p0: length wanted (1 to 255) · p1: flags],
  reply: [exactly p0 bytes],
  ex: "fuji.read_dir")[
Reads the next entry. The reply is always exactly `p0` bytes: the file name,
a NUL, and NUL padding. A directory's name ends with `/`. A name too long
for the space is shortened with an ellipsis in the middle; ask for more
bytes to avoid it. When the directory is used up, the reply begins with
#strong[`7F 7F`]:]
#exchange("fuji.read_dir_end")

#block(sticky: true)[
Setting bit 7 of `p1` (`80`) puts 12 bytes of details in front of the name:
]

#ktable(columns: (auto, auto, 1fr),
  table.header[Offset][Size][Field],
  [0], [1], [year #sym.minus 1970 of the last modification],
  [1], [1], [month, 1 to 12],
  [2], [1], [day],
  [3], [1], [hour],
  [4], [1], [minute],
  [5], [1], [second],
  [6], [4], [size in bytes, little-endian],
  [10], [1], [flags: `01` directory, `02` name was shortened],
  [11], [1], [media type: `00` unknown, `01` disk image, `02` ROM, `03` IMD],
)

#exchange("fuji.read_dir_ext")

A host that keeps no modification times (fujinet-pc's SD directory is one)
reports 31 December 1969, 18:00 --- the year byte `FF` is #sym.minus;1 --- and
a size of zero. The 12 bytes count against `p0`, so ask for 12 more.

#sub[Block mode]

#block(sticky: true)[
With the top two bits of `p1` both set (`C0` to `FF`), READ_DIR_ENTRY
returns many entries at once, packed into pages. `p0` is the number of
256-byte pages wanted and the low six bits of `p1` the number of entries per
group. The reply is exactly `p0 x 256` bytes:
]

#ktable(columns: (auto, 1fr),
  table.header[Part][Layout],
  [Page header], [`4D 46` (`MF`), `04`, number of groups],
  [Group header], [5 bytes: flags (`80` = last group), entry count, data
   size (16 bits), group index],
  [Each entry], [8 bytes: year #sym.minus 1970; directory flag in bit 7 with the
   month in the low nibble; day in bits 7--3 with hour bits 4--2 in bits 2--0;
   hour bits 1--0 in bits 7--6 with the minute in bits 5--0; size (24 bits);
   media type --- then the name and a NUL],
)

#block(sticky: true)[
Directory names carry no trailing `/` in block mode; the flag bit says what
they are. One request for page 1 of `/test` with up to 8 entries per group
returned:
]

#codepanel("Block-mode reply (first 80 of 256 bytes)",
"4D 46 04 01                    'MF', version 4, 1 group
80 04 47 00 00                 last group, 4 entries, 71 bytes, group 0
FF 0C FC 80 00 00 00 00        1969-12-31 18:00, size 0, type 0
62 6C 61 6E 6B 2E 69 6D 67 00  blank.img
FF 0C FC 80 00 00 00 00 ...    copy.txt
...")

#devcmd([GET_DIRECTORY_POSITION], code: "E5",
  reply: [2 bytes: the index of the next entry],
  ex: "fuji.dir_pos")[]

#devcmd([SET_DIRECTORY_POSITION], code: "E4",
  params: [p0: entry index (16 bits)],
  ex: "fuji.set_dir_pos")[
Moves to an entry; the next READ_DIR_ENTRY returns it. Together with
GET_DIRECTORY_POSITION this lets a program page backwards through a long
directory without reading it from the start.]

#devcmd([CLOSE_DIRECTORY], code: "F5",
  ex: "fuji.close_dir")[
Always answered with ACK.]

== Disk slots

#block(sticky: true)[
A #strong[disk slot] connects a disk image on a host to one of the eight
disk devices: disk slot N is device `30h + N`. The slot table holds eight
38-byte records:
]

#ktable(columns: (auto, auto, 1fr),
  table.header[Offset][Size][Field],
  [0], [1], [host slot, 0 to 7, or `FF` for an empty slot],
  [1], [1], [mode: bit 0 read, bit 1 write, bit 6 (`40`) the image is
   mounted],
  [2], [36], [the image's file name, NUL-terminated],
)

The full path of an image can be up to 256 bytes, but the slot table holds
only the #strong[file name], without its directory; GET_DEVICE_FULLPATH
returns the whole path.

#devcmd([READ_DEVICE_SLOTS], code: "F2",
  reply: [304 bytes: 8 records of 38],
  ex: "fuji.read_slots", head: 20)[
In this reply, slot 1 is `07 01 lobby.img`: host slot 8, read-only, not
mounted. Slot 2 is `00 41 disk.img`: host slot 1, read-only (`01`) and
mounted (`40`). The bytes after a name's NUL are left over from longer names
and mean nothing.]

#devcmd([WRITE_DEVICE_SLOTS], code: "F1",
  payload: [304 bytes: 8 records of 38],
  ex: "fuji.write_slots", head: 20)[
Replaces the whole slot table and saves it. It does not mount anything.]

#caution[Because READ_DEVICE_SLOTS returns only file names, writing its
reply straight back with WRITE_DEVICE_SLOTS replaces every image's full path
with its bare file name, and the images can no longer be found. To change
one slot, use SET_DEVICE_FULLPATH instead.]

#devcmd([SET_DEVICE_FULLPATH], code: "E2",
  params: [p0: disk slot · p1: host slot · p2: mode (`01` read, `02` read/write)],
  payload: [256 bytes: the image's path, NUL-terminated],
  ex: "fuji.set_fullpath", head: 16)[
Puts an image in a disk slot, without mounting it, and saves the slot to
`fnconfig.ini`. An empty path empties the slot.]

#devcmd([GET_DEVICE_FULLPATH], code: "DA",
  params: [p0: disk slot],
  reply: [256 bytes: the full path, NUL-padded],
  ex: "fuji.get_fullpath", head: 16)[]

#devcmd([MOUNT_IMAGE], code: "F8",
  params: [p0: disk slot · p1: mode (`01` read, `02` read/write)],
  ex: "fuji.mount_image")[
Opens the image named in the slot so the disk device can read and write it.
The host must be mounted first. The adapter decides how to treat the file
from its extension (Chapter 8); a file it cannot classify is refused with NAK.]

#devcmd([UNMOUNT_IMAGE], code: "E9",
  params: [p0: disk slot],
  ex: "fuji.unmount_image")[
Closes the image and empties the slot.]

#devcmd([MOUNT_ALL], code: "D7",
  ex: "fuji.mount_all")[
Mounts every host that a slot uses, then every slot that holds an image ---
what the firmware does by itself at power-up when `configenabled=0`. It
stops at the first failure and answers NAK.]

#devcmd([NEW_DISK], code: "E7",
  payload: [262 bytes: sectors (16 bits), sector size (16 bits), host slot,
    disk slot, path (256)],
  reply: [NAK],
  ex: "fuji.new_disk", head: 16)[
Meant to create a blank image of the given geometry and put it in the disk
slot.]

#caution[On the RS-232 build NEW_DISK #strong[always] answers NAK: the
image-creation routine it calls is not implemented for this platform. It
does create (or truncate!) the named file, empty, and it does change the disk
slot's host and file name. Create blank images some other way.]

== Booting

#devcmd([CONFIG_BOOT], code: "D9",
  params: [p0: `01` keep the boot image, `00` drop it],
  ex: "fuji.config_boot")[
With `p0 = 0`, removes the boot image from disk slot 1 if no real image has
been put there. Always answered with ACK.]

#devcmd([SET_BOOT_MODE], code: "D6",
  params: [p0: boot mode, as `[General] boot_mode`],
  ex: "fuji.boot_mode")[
Places the boot image for the given mode in disk slot 1 at once: `0`
`/autorun.img`, `1` `/mount-and-boot.img`, `2` the lobby image on
`tnfs.fujinet.online`, `3` `/hisioboot-fujinet.img`. Always answered with ACK,
even if the image does not exist.]

#devcmd([RESET], code: "FF",
  reply: [none],
  ex: "fuji.reset")[
Restarts the adapter at once, #strong[without] replying. Wait a few seconds,
and expect the firmware to discard input until the line has been quiet for
100 ms after it comes back.]

== Copying files

#devcmd([COPY_FILE], code: "D8",
  params: [p0: source host slot · p1: destination host slot --- both counted
    #strong[from 1]],
  payload: [`source|destination`, NUL-terminated],
  ex: "fuji.copy_file", head: 16)[
Copies a file between hosts (or within one) on the adapter, without the
bytes crossing the serial line. A destination ending in `/` gets the source
file's name. Unlike every other command, the host slots here count from 1:
`p0 = 1` is host slot 1. The reply waits until the copy is done.]

== Application keys

#strong[Application keys] are small files the adapter keeps on its SD card
for programs: a high-score table, a player name, a server address. A key is
named by a creator number, an application number and a key number, and holds
up to 64 bytes. It is stored on the SD card as `/FujiNet/ccccaakk.key`,
the three numbers in hexadecimal, so keys need an SD card.

#block(sticky: true)[
Every key operation starts with OPEN_APPKEY and a 6-byte description:
]

#ktable(columns: (auto, auto, 1fr),
  table.header[Offset][Size][Field],
  [0], [2], [creator, little-endian (assign your own; 0 is not allowed)],
  [2], [1], [application],
  [3], [1], [key],
  [4], [1], [mode: `00` read, `01` write],
  [5], [1], [reserved, 0],
)

#devcmd([OPEN_APPKEY], code: "DC",
  payload: [6 bytes, above],
  ex: "fuji.appkey_open_w")[
Answered with NAK if there is no SD card or the creator is 0.]

#devcmd([WRITE_APPKEY], code: "DE",
  payload: [the key's contents, up to 64 bytes],
  ex: "fuji.appkey_write")[
Needs an OPEN_APPKEY in mode `01` first, and closes the key afterwards.]

#devcmd([READ_APPKEY], code: "DD",
  reply: [2-byte length, little-endian, then that many bytes],
  ex: "fuji.appkey_read")[
Needs an OPEN_APPKEY in mode `00` first. The RS-232 build puts a 2-byte
length in front of the data, here `10 00`, sixteen bytes.]

#caution[READ_APPKEY answers ACK even when it fails --- no key, no SD card,
not opened for reading --- and then returns a length of 64 and 64 zero bytes.
A key of 64 zeroes is therefore indistinguishable from no key; store
something recognisable in your keys.]

#devcmd([CLOSE_APPKEY], code: "DB",
  ex: "fuji.appkey_close")[]

== Base64

The adapter can encode to and decode from Base64, a job too heavy for many
small machines. Each direction is four steps: feed the input in pieces,
compute, ask the length, and read the result in pieces. Encoding and
decoding share #strong[one] buffer, so finish one job before starting the
next.

#devcmd([BASE64_ENCODE_INPUT], code: "D0",
  params: [p0: byte count (16 bits)],
  payload: [that many bytes],
  ex: "fuji.b64e_in")[
Appends to the buffer. Send it as many times as needed.]

#devcmd([BASE64_ENCODE_COMPUTE], code: "CF",
  ex: "fuji.b64e_compute")[
Replaces the buffer's contents with their Base64 encoding.]

#devcmd([BASE64_ENCODE_LENGTH], code: "CE",
  reply: [4 bytes: the length of the result, little-endian],
  ex: "fuji.b64e_len")[
The encoder leaves a NUL at the end of its result and this length counts it:
`FujiNet` encodes to the 12 characters `RnVqaU5ldA==`, and the length is
`0D`, 13.]

#devcmd([BASE64_ENCODE_OUTPUT], code: "CD",
  params: [p0: byte count (16 bits)],
  reply: [that many bytes, taken from the front of the buffer],
  ex: "fuji.b64e_out")[
Answered with NAK if `p0` is 0 or more than the buffer holds.]

#block(sticky: true)[
The decoding commands mirror them exactly:
]

#ktable(columns: (auto, auto, 1fr),
  table.header[Command][Code][Same as],
  [BASE64_DECODE_INPUT], [`CC`], [ENCODE_INPUT, with Base64 text as input],
  [BASE64_DECODE_COMPUTE], [`CB`], [ENCODE_COMPUTE],
  [BASE64_DECODE_LENGTH], [`CA`], [ENCODE_LENGTH (no NUL is counted)],
  [BASE64_DECODE_OUTPUT], [`C9`], [ENCODE_OUTPUT],
)

#exchange("fuji.b64d_in")
#exchange("fuji.b64d_out")

== Hashing

The adapter computes MD5, SHA-1, SHA-256 and SHA-512 digests.

#devcmd([HASH_INPUT], code: "C8",
  params: [p0: byte count (16 bits)],
  payload: [that many bytes],
  ex: "fuji.hash_in")[
Appends to the data to be hashed.]

#devcmd([HASH_COMPUTE], code: "C7",
  params: [p0: algorithm: `00` MD5, `01` SHA-1, `02` SHA-256, `03` SHA-512],
  ex: "fuji.hash_compute")[
Computes the digest and clears the input. HASH_COMPUTE_NO_CLEAR (`C3`) does
the same but keeps the input, to compute a second digest of the same data.]

#devcmd([HASH_LENGTH], code: "C6",
  params: [p0: `01` for hexadecimal text, `00` for binary],
  reply: [1 byte: the digest's length in that form],
  ex: "fuji.hash_len")[]

#devcmd([HASH_OUTPUT], code: "C5",
  params: [p0: `01` for hexadecimal text, `00` for binary],
  reply: [the digest],
  ex: "fuji.hash_out")[
SHA-1 of `abc`, as hexadecimal text. In binary the same digest is 20 bytes;
here is the MD5 of `abc`, binary:]
#exchange("fuji.hash_out_bin")

#devcmd([HASH_CLEAR], code: "C2",
  ex: "fuji.hash_clear")[
Clears the input without computing.]

== QR codes

The adapter turns text into a QR code and renders it in one of several forms,
one of which is ready to print on an ANSI terminal.

#devcmd([QRCODE_INPUT], code: "BC",
  params: [p0: byte count (16 bits)],
  payload: [that many bytes of text],
  ex: "fuji.qr_in")[]

#devcmd([QRCODE_ENCODE], code: "BD",
  params: [p0: QR version (1 to 40) · p1: error correction: `00` L, `01` M,
    `02` Q, `03` H · p2: `01` to shorten a URL first],
  ex: "fuji.qr_encode")[
Encodes the input and clears it. The version sets the size, and so the
capacity: a 23-character URL needs version 3 at level L, and is refused with
NAK at version 1.]

#devcmd([QRCODE_LENGTH], code: "BE",
  params: [p0: output form, below],
  reply: [4 bytes: the length of the rendered code],
  ex: "fuji.qr_len")[
Renders the code in the chosen form and returns its length:]

#ktable(columns: (auto, auto, 1fr),
  table.header[p0][Form][Layout],
  [`00`], [binary], [the code's size in modules, then every module
   row by row, packed 8 to a byte, least significant bit first],
  [`01`], [ANSI], [text with ANSI colour codes, two spaces per module, a
   newline per row: print it on an ANSI terminal],
  [`02`], [bitmap], [the size, then each row packed into whole bytes, most
   significant bit leftmost],
  [`03`], [SVG], [an SVG image as text],
  [`04`], [ATASCII], [Atari text-mode graphics],
  [`05`], [PETSCII], [Commodore text-mode graphics],
)

#devcmd([QRCODE_OUTPUT], code: "BF",
  params: [p0: byte count (16 bits)],
  reply: [that many bytes, taken from the front of the rendered code],
  ex: "fuji.qr_out", head: 16)[
A version 3 code is 29 modules square; in binary form that is one size byte
(`1D`) and 106 bytes of modules.]

== Random numbers and GUIDs

#devcmd([RANDOM_NUMBER], code: "D3",
  reply: [4 bytes: a random 32-bit number, little-endian],
  ex: "fuji.random")[]

#devcmd([GENERATE_GUID], code: "BB",
  reply: [37 bytes: a version 4 UUID as text, and a NUL],
  ex: "fuji.guid")[]

== Commands not available on RS-232

These Fuji commands exist on other FujiNet platforms but are answered with
NAK on the RS-232 bus: ENABLE_UDPSTREAM (`F0`), SET_BAUDRATE (`EB`),
SET_HSIO_INDEX (`E3`), SET_SIO_EXTERNAL_CLOCK (`DF`), ENABLE_DEVICE (`D5`),
DISABLE_DEVICE (`D4`), DEVICE_ENABLE_STATUS (`D1`), GET_TIME (`D2`; use the
clock device), GET_HEAP (`C1`), GET_DEVICE1_FULLPATH to GET_DEVICE10_FULLPATH
(`A0`--`A9`; use GET_DEVICE_FULLPATH), UPDATE_FIRMWARE (`90`) and
HSIO_INDEX (`3F`).

// ============================================================
// CHAPTER 8: DISK DRIVES
// ============================================================
#chapter[The Disk Drives (31h--38h)]

Each of the eight disk slots appears on the bus as a disk drive: disk slot 1
is device `31`, disk slot 8 is device `38`. Once the Fuji device has mounted
an image into a slot (Chapter 7), the drive reads and writes it sector by
sector. A drive whose slot is empty answers every command with NAK.

== What an image is

#block(sticky: true)[
The firmware decides how to treat an image by the end of its file name:
]

#ktable(columns: (auto, auto, 1fr),
  table.header[Extension][Treated as][Sectors],
  [`.IMD`], [ImageDisk], [The image's own sector sizes, in logical order,
   sector 0 first. Sectors the image records as bad or deleted are reported
   as such.],
  [`.ROM`, `.BIN`, `.INT`, `.ITV`, `.CHF`], [cartridge ROM], [Not readable
   as a disk: see below.],
  [anything else], [flat image], [A plain sequence of #strong[512-byte]
   sectors, sector 0 at the start of the file.],
)

Most S-100 and CP/M disk images are flat images of 128-byte sectors.
The drive still serves them in 512-byte pieces: sector `n` is bytes `512n` to
`512n + 511` of the file, whatever the image's own geometry. A program that
wants 128-byte CP/M records reads the 512-byte sector that holds them and
picks out the quarter it needs.

#caution[A ROM image is not a disk. Mounting one tells the adapter to send
the whole ROM to a Fujiversal cartridge, so the firmware starts sending
packets of its own --- to device `FF`, the cartridge --- and waits for each to
be acknowledged. On an ordinary serial computer those packets arrive where
the MOUNT_IMAGE reply was expected, nothing acknowledges them, and the mount
fails. Do not mount `.ROM`, `.BIN`, `.INT`, `.ITV` or `.CHF` files on a
computer that is not a Fujiversal cartridge.]

== Commands

#devcmd([READ], code: "52",
  params: [p0: sector number (32 bits), from 0],
  reply: [the sector: 512 bytes for a flat image],
  ex: "disk.read", head: 16)[
Answered with NAK if the sector is past the end of the image or the slot is
empty:]
#exchange("disk.read_far")

#devcmd([WRITE], code: "57",
  params: [p0: sector number (32 bits)],
  payload: [the sector: 512 bytes for a flat image],
  ex: "disk.write", head: 16)[
Writes the sector. The image must be mounted read/write (MOUNT_IMAGE mode
`02`); a read-only mount answers NAK.]

#devcmd([PUT], code: "50",
  params: [p0: sector number (32 bits)],
  payload: [the sector],
  ex: "disk.put", head: 16)[
The same as WRITE. (On the Atari bus PUT skips the verify; on RS-232 the two
are one routine.)]

#devcmd([STATUS], code: "53",
  params: [p0: sector number (32 bits)],
  payload: [see below],
  reply: [NAK],
  ex: "disk.status")[
On other FujiNet buses this returns the drive's four status bytes. On the
RS-232 bus it is wired, by mistake, to #strong[WRITE]: it takes a sector number
and a payload and writes them. Sent without a payload it simply fails, as
here; sent without a parameter it crashes the adapter (Chapter 4).]

#caution[Do not use disk STATUS on the RS-232 bus. There is nothing it can
tell you that MOUNT_IMAGE and READ_DEVICE_SLOTS do not, and a stray payload
would overwrite a sector.]

#devcmd([FORMAT], code: "21",
  reply: [128 bytes: `FF FF`, then zeroes],
  ex: "disk.format", head: 16)[
Returns an empty bad-sector list in the Atari style --- the bytes `FF FF`
padded to 128 --- and #strong[does not touch the image]. FORMAT_MEDIUM
(`22`) is the same. An ImageDisk or ROM image answers NAK.]

#devcmd([PERCOM_READ], code: "4E",
  reply: [12 bytes: a PERCOM drive-geometry block],
  ex: "disk.percom_r")[
The Atari PERCOM block: tracks, step rate, sectors per track (16 bits,
#strong[big-endian]), sides, density, sector size (16 bits, big-endian), a
"drive present" flag and three reserved bytes. A flat image reports all
zeroes; an ImageDisk image reports its geometry.]

#devcmd([PERCOM_WRITE], code: "4F",
  payload: [12 bytes],
  ex: "disk.percom_w")[
Accepted and stored, with no effect on a flat image.]

The Atari high-speed variants of these commands (`D0`--`D7`, `A1`, `A2`,
`3F`) are not recognised on RS-232 and are answered with NAK.

// ============================================================
// CHAPTER 9: THE NETWORK UNITS
// ============================================================
#chapter[The Network Units (71h--78h)]

The eight network units are FujiNet's `N:` device: each opens one URL, and
then reads and writes it like a file. Unit 1 is device `71`, unit 8 device
`78`. One unit might hold a TCP connection to a bulletin board, another an
HTTP request to a weather service, a third a file on a TNFS server --- all at
once, each independent.

The protocols themselves --- HTTP and HTTPS, TCP and UDP, TNFS, FTP, SMB,
NFS, SSH and SFTP, TELNET, WebSockets, S3, the Google and Microsoft cloud
services, the SD card, and more --- are described in depth in #emph[The FujiNet
Network Protocol Handbook]. This chapter covers the commands that drive them
over the RS-232 bus.

== The life of a connection

#fig(seq((("COMPUTER", 0, mast), ("FUJINET N1:", 1, perif), ("SERVER", 2, steel)),
  msg(0, 1, "OPEN p0=12 \"N:TCP://bbs.example:23/\""),
  msg(1, 2, "connect", c: steel),
  msg(1, 0, "ACK", c: perif),
  sgap(h: 2pt),
  msg(2, 1, "\"Welcome!\" (arrives any time)", c: steel),
  msg(0, 1, "STATUS"),
  msg(1, 0, "ACK  0A 00 01 01  (10 waiting)", c: perif),
  msg(0, 1, "READ p0=10"),
  msg(1, 0, "ACK  \"Welcome!\\r\\n\"", c: perif),
  msg(0, 1, "WRITE p0=3 \"hi\\r\""),
  msg(1, 2, "hi", c: steel),
  msg(1, 0, "ACK", c: perif),
  msg(0, 1, "CLOSE"),
  msg(1, 0, "ACK", c: perif),
  w: 440pt), caption: [A unit's life: OPEN, then STATUS and READ to collect
  what has arrived, WRITE to send, CLOSE at the end.])

Data from the far end collects in the unit's buffer as it arrives. The
computer finds out how much is waiting with STATUS and collects it with READ,
at whatever pace suits it; nothing is lost while it is busy.

== The devicespec

#block(sticky: true)[
A unit is opened on a #strong[devicespec], a URL with an optional `N:`
prefix:
]

#spec("N:HTTPS://5card.carr-designs.com/tables?bin=1")

The prefix may name a unit (`N2:`), but the unit that opens the URL is the
device the packet is sent to, whatever the prefix says. The devicespec ends
at its first NUL, or at a CR LF, and may be up to 255 characters.

== Opening and closing

#devcmd([OPEN], code: "4F",
  params: [p0: mode · p1: translation],
  payload: [the devicespec, NUL-terminated],
  ex: "net.open_get")[
Opens the URL. For most protocols the reply waits until the connection is
made, so allow for DNS, TCP and TLS: several seconds. Opening a unit that is
already open closes the old connection first. When OPEN fails it answers
NAK, and STATUS then gives the reason in its error byte.]

#block(sticky: true)[
The mode says what the program means to do:
]

#ktable(columns: (auto, auto, 1fr),
  table.header[p0][General meaning][For HTTP and HTTPS],
  [`04`], [read], [GET],
  [`05`], [---], [DELETE],
  [`06`], [read a directory listing], [---],
  [`07`], [read a directory, alternate format], [---],
  [`08`], [write], [PUT],
  [`09`], [append], [DELETE, headers allowed],
  [`0C`], [read and write], [GET, headers allowed],
  [`0D`], [---], [POST],
  [`0E`], [---], [PUT, headers allowed],
)

"Headers allowed" modes let a program use SET_HTTP_MODE (below) to send and
collect HTTP headers; mode `0C` is the usual choice for a GET.

The #strong[translation] in `p1` converts line endings as data passes through
the unit: `00` none, `01` CR, `02` LF, `03` CR LF, `04` PETSCII. The RS-232
bus's own line ending is CR LF. Programs that handle bytes themselves, like
the ones in this book, use `00`.

#devcmd([CLOSE], code: "43",
  ex: "net.close")[
Closes the connection and frees the unit.]

== Reading and writing

#devcmd([STATUS], code: "53",
  reply: [4 bytes: bytes waiting (16 bits), connected, error],
  ex: "net.status_tcp")[
The heartbeat of every network program. The first two bytes are the number
of bytes waiting to be read, up to 65,535. The third is `01` while the
connection is up. The fourth is a status code from the table at the end of
this chapter: `01` all is well, `88` (136) end of file.]

#important[How a program knows it has everything depends on the protocol.
For TCP and TELNET, the connection is over when nothing is waiting and the
#strong[connected] byte is `00`. For HTTP, the connected byte is `00` from
the start; the reply is complete when nothing is waiting and the
#strong[error] byte is `88`, end of file. A program that serves both, like
NETCAT, should stop on either.]

#block(sticky: true)[
Here is the end of an HTTP reply --- nothing waiting, not connected, end of
file:
]

#exchange("net.status_eof")

#devcmd([READ], code: "52",
  params: [p0: most bytes wanted (16 bits)],
  reply: [up to p0 bytes],
  ex: "net.read_tcp")[
Returns what is waiting, up to `p0` bytes; ask for the number STATUS reported,
or less. A READ when nothing is waiting is answered with NAK, and `p0 = 0`
is refused the same way. A READ cannot be repeated: the bytes it returned
have left the unit's buffer.]

#devcmd([WRITE], code: "57",
  params: [p0: byte count (16 bits)],
  payload: [that many bytes],
  ex: "net.write_tcp")[
Sends the bytes to the far end.]

== A web request, start to finish

#block(sticky: true)[
An HTTP GET of a small JSON document, as every byte goes:
]

#exchange("net.open_get", label: [OPEN mode `0C` (GET), translation `00`:])
#exchange("net.status_get", label: [STATUS: 53 bytes waiting (`35 00`); not connected, status OK:])
#exchange("net.read", head: 20, label: [READ all 53:])
#exchange("net.status_eof", label: [STATUS: nothing left, end of file (`88`):])
#exchange("net.close", label: [CLOSE:])

== Posting data

#block(sticky: true)[
A POST sends a body to the server before reading its reply. Open in mode
`0D`, switch the unit to "post data" with SET_HTTP_MODE, WRITE the body,
switch back to "body", and read the reply as usual:
]

#exchange("net.open_post", label: [OPEN mode `0D` (POST):])
#exchange("net.http_mode_post", label: [SET_HTTP_MODE `p1 = 4`, post data:])
#exchange("net.write_post", label: [WRITE the body:])
#exchange("net.http_mode_body", label: [SET_HTTP_MODE `p1 = 0`, body --- this sends the request:])
#exchange("net.read_post", label: [READ the server's answer:])

#devcmd([SET_HTTP_MODE], code: "4D",
  params: [p0: unused, but must be sent · p1: channel mode],
  ex: "net.http_mode_body")[
Chooses what READ and WRITE mean on an HTTP unit: `00` the body (the
default), `01` collect response headers, `02` read the collected headers,
`03` write request headers, `04` write POST data. NAK on a unit that is not
HTTP.]

== Parsing JSON

#block(sticky: true)[
A unit can parse what it has read as JSON (or HTML, or XML) and hand back
single values by path, so a small computer never has to hold the whole
document. After OPEN:
]

#exchange("net.set_parser", label: [SET_PARSER `p1 = 1`, JSON:])
#exchange("net.parse", label: [PARSE --- reads the whole reply and parses it:])
#exchange("net.query", label: [QUERY `/name`:])
#exchange("net.status_q", label: [STATUS: the value is 8 bytes long:])
#exchange("net.read_q", label: [READ it:])

The value comes back with the parser's line ending appended, a line feed by
default. Array elements are addressed by index: `/ports/0` returned
`1985` and a line feed.

#devcmd([SET_PARSER], code: "FC",
  params: [p0: unused, but must be sent · p1: `00` none, `01` JSON, `02` HTML,
    `03` XML],
  ex: "net.set_parser")[]

#devcmd([PARSE], code: "50",
  ex: "net.parse")[
Reads the rest of the unit's data and parses it. NAK if nothing is open or
the document will not parse.]

#devcmd([QUERY], code: "51",
  payload: [the path, such as `/0/account/display_name`],
  ex: "net.query")[
Selects a value. STATUS then reports its length, and READ returns it.]

#devcmd([SET_PARAMETER], code: "FB",
  params: [p0: `00` query flags, or `01` line ending · p1: the value],
  ex: "net.set_param_eol")[
With `p0 = 1`, `p1` becomes the line ending appended to query results. With
`p0 = 0`, `p1` holds query flags: bits 0--2 remap characters, and bits 4--5
choose the output, `00` verbatim or `10` plain ASCII with entities decoded
and everything else stripped. NAK if no parser is set.]

== Line endings and translation

#devcmd([TRANSLATION], code: "54",
  params: [p0: unused, but must be sent · p1: translation, as for OPEN],
  ex: "net.translation")[
Sets a translation that is combined with OPEN's `p1` from the next OPEN on;
`FF` turns translation off whatever OPEN asks.]

#devcmd([SET_EOL], code: "4C",
  payload: [the line ending to use; empty for the default],
  ex: "net.set_eol")[
Overrides the line ending translation converts to.]

== Files and directories

Units opened on file protocols (TNFS, FTP, SMB, NFS, SFTP, the SD card)
support moving around and changing files. These commands take the full
devicespec in the payload; the unit need not be open.

#devcmd([RENAME], code: "20",
  params: [p0: mode · p1: unused --- both must be sent],
  payload: [`N:proto://host/path/old,new`, NUL-terminated],
  ex: "net.rename")[]

#block(sticky: true)[
The others have the same shape:
]

#ktable(columns: (auto, auto, 1fr),
  table.header[Command][Code][Payload],
  [DELETE], [`21`], [the file's devicespec],
  [LOCK], [`23`], [the file's devicespec (where the protocol supports it)],
  [UNLOCK], [`24`], [the file's devicespec],
  [MKDIR], [`2A`], [the new directory's devicespec],
  [RMDIR], [`2B`], [the directory's devicespec],
)

#exchange("net.mkdir")

A directory is read by opening it in mode `06`: READ then returns a text
listing, one entry per line.

#exchange("net.read_dir", head: 24, label: [READ on `N:SD:/test/`, opened in mode `06`:])

#devcmd([CHDIR], code: "2C",
  payload: [a path, `..`, `/`, or a whole devicespec],
  ex: "net.chdir")[
Sets the unit's working directory, against which relative devicespecs are
taken.]

#devcmd([GETCWD], code: "30",
  reply: [the working directory, with no NUL],
  ex: "net.getcwd")[]

#devcmd([USERNAME], code: "FD",
  payload: [the user name, NUL-terminated],
  ex: "net.username")[
Sets the login for the next OPEN. PASSWORD (`FE`) sets the password the same
way.]

#devcmd([SEEK], code: "25",
  params: [p0: offset from the start (32 bits)],
  ex: "net.seek")[]

#devcmd([TELL], code: "26",
  reply: [4 bytes: the current offset],
  ex: "net.tell")[
After reading all 53 bytes of a document, the offset is 53. On a unit that
is not open, TELL returns four bytes of leftover memory.]

== Serving: TCP servers and UDP

#sub[A TCP server]

#block(sticky: true)[
A unit opened on `N:TCP://:port/` --- no host --- listens. STATUS reports a
client waiting as #emph[connected], ACCEPT takes it, and from then on READ
and WRITE talk to that client:
]

#exchange("net.open_listen", label: [OPEN `N:TCP://:7803/`:])
#exchange("net.accept", label: [ACCEPT, once STATUS shows a caller:])
#exchange("net.read_acc", label: [READ what the client sent:])

#devcmd([CLOSE_CLIENT], code: "63",
  ex: "net.close_client")[
Hangs up on the current client and keeps listening for the next.]

#caution[CLOSE_CLIENT's answer is inverted. It disconnects the client and
then answers #strong[NAK] (as above); it answers #strong[ACK] when there was
no client to disconnect. Treat either reply as done, and check STATUS.]

#sub[UDP]

A unit opened on `N:UDP://host:port/` sends datagrams to that host; opened on
`N:UDP://:port/` it listens on the port. Each READ returns one datagram.

#exchange("net.open_udp", label: [OPEN `N:UDP://:7804/`, listening:])
#exchange("net.read_udp", label: [READ one datagram (STATUS shows 0 waiting, see below):])
#exchange("net.get_remote", head: 24, label: [GET_REMOTE --- who sent it:])
#exchange("net.set_dest", label: [SET_DESTINATION `N:127.0.0.1:7805` --- answer them:])
#exchange("net.write_udp", label: [WRITE the answer:])

#important[STATUS does not count waiting datagrams on fujinet-pc: it reports
0 bytes even when a datagram has arrived. READ anyway, with a buffer big
enough for the largest datagram expected; it returns the datagram if there is
one. STATUS also points the unit's destination at whoever sent the last
datagram, so a server can simply WRITE its reply.]

#devcmd([GET_REMOTE], code: "72",
  reply: [256 bytes: `address:port`, ended by `9B`],
  ex: "net.get_remote", head: 24)[
The sender of the last datagram, as text. The text ends with the byte `9B`
(the Atari end-of-line), not a NUL; the rest of the 256 bytes is leftover
memory. NAK on the ESP32 hardware, where it is not implemented.]

#devcmd([SET_DESTINATION], code: "44",
  payload: [`prefix:host:port` and a NUL],
  ex: "net.set_dest")[
Where the next WRITE goes. The text must have a prefix before the host
(`N:` will do), because the host is taken from between the first and last
colons, and it must end with a NUL: without one, fujinet-pc reads past the
end of the payload.]

== Interrupt rate

#devcmd([SET_INT_RATE], code: "5A",
  params: [p0: milliseconds (8 bits)],
  ex: "net.int_rate")[
How often the unit toggles the RI attention line while it needs attention
(Chapter 2). The default is 100 ms on the hardware and 20 ms on fujinet-pc.]

== Status codes

#block(sticky: true)[
The fourth byte of STATUS:
]

#btable(columns: (auto, auto, 1fr),
  table.header[Code][Hex][Meaning],
  [1], [`01`], [success],
  [131], [`83`], [opened write-only],
  [132], [`84`], [invalid command],
  [135], [`87`], [opened read-only],
  [136], [`88`], [end of file],
  [138], [`8A`], [general timeout],
  [144], [`90`], [general error],
  [146], [`92`], [not implemented],
  [151], [`97`], [file exists],
  [162], [`A2`], [no space on device],
  [165], [`A5`], [invalid devicespec],
  [166], [`A6`], [invalid position],
  [167], [`A7`], [access denied],
  [170], [`AA`], [file not found],
  [200], [`C8`], [connection refused],
  [201], [`C9`], [network unreachable],
  [202], [`CA`], [socket timeout],
  [203], [`CB`], [network down],
  [204], [`CC`], [connection reset],
  [205], [`CD`], [connection already in progress],
  [206], [`CE`], [address in use],
  [207], [`CF`], [not connected],
  [208], [`D0`], [server not running],
  [209], [`D1`], [no connection waiting],
  [210], [`D2`], [service not available],
  [211], [`D3`], [connection aborted],
  [212], [`D4`], [invalid user name or password],
  [213], [`D5`], [could not parse JSON],
  [214], [`D6`], [general client error],
  [215], [`D7`], [general server error],
  [255], [`FF`], [could not allocate buffers],
)

#block(sticky: true)[
An HTTP OPEN to a port where nothing listens is accepted --- HTTP connects
lazily --- and the failure shows up in the first STATUS, as `CF`:
]

#exchange("net.status_bad")

== Commands not available on RS-232

GET_DSTATS_VALUE (`FF`), SET_UNIT (`FA`), SET_HSIO_INDEX (`E3`), PARSE_ALT
(`80`), QUERY_ALT (`81`), GET_ERROR (`45`) and HSIO_INDEX (`3F`) are answered
with NAK. Use STATUS for the error code.

// ============================================================
// CHAPTER 10: THE CLOCK
// ============================================================
#chapter[The Clock (45h)]

The adapter sets its clock from the network at start-up (from the
`[Network] sntpserver`, `pool.ntp.org` by default) and offers the time in a
dozen formats, so that each computer can have it in the shape its own system
software expects.

Every clock command takes one parameter. With `p0 = 1`, the commands that
honour it give the time in the #strong[alternate] time zone (set with SETTZ,
below) instead of the adapter's own (`[General] timezone`). Send `p0 = 0`
otherwise --- but always send it (Chapter 4).

== Reading the time

#devcmd([GETTIME], code: "93",
  params: [p0: `00` system zone, `01` alternate zone],
  reply: [6 bytes: day, month, year #sym.minus 2000, hour, minute, second],
  ex: "clock.gettime")[
The APETime format, binary. #{
  let p = EX.at("clock.gettime").rep.filter(b => b.at(1) == "pay").map(b => hexval(b.at(0)))
  let two(n) = if n < 10 { "0" + str(n) } else { str(n) }
  [Here: day #p.at(0), month #p.at(1), 20#two(p.at(2)), at #two(p.at(3)):#two(p.at(4)):#two(p.at(5)) UTC.]
}]

#devcmd([GETTZTIME], code: "9A",
  params: [p0: unused],
  reply: [6 bytes, as GETTIME, always in the alternate zone],
  ex: "clock.gettztime")[]

#devcmd([GET_SIMPLE], code: "54",
  params: [p0: zone],
  reply: [7 bytes: century, year, month, day, hour, minute, second],
  ex: "clock.simple")[
The firmware calls this command SETTZ_ALT2: on buses where reading and writing
use separate commands it sets the time zone. On RS-232 the read table claims
it first, so it is a #strong[read]: the time as plain binary, with a full
century byte (`14` is 20).]

#devcmd([GET_SIMPLE_HUNDREDTHS], code: "4D",
  params: [p0: zone],
  reply: [8 bytes: as GET_SIMPLE, then hundredths of a second, 0 to 99],
  ex: "clock.hundredths")[]

#devcmd([GET_PRODOS], code: "50",
  params: [p0: zone],
  reply: [4 bytes: the ProDOS date and time],
  ex: "clock.prodos")[
Byte 0 is the day plus the month times 32; byte 1 is the year (two digits)
times 2 plus the month's top bit; byte 2 the minute; byte 3 the hour.]

#devcmd([GET_SOS], code: "53",
  params: [p0: zone],
  reply: [19 bytes: `YYYYMMDD0HHMMSS000` and a NUL],
  ex: "clock.sos")[
The Apple III SOS format, as text. The `0` after the date is fixed.]

#devcmd([GET_ISO_LOCAL], code: "49",
  params: [p0: zone],
  reply: [25 bytes: `YYYY-MM-DDTHH:MM:SS+HHMM` and a NUL],
  ex: "clock.iso_local")[
ISO 8601 with the zone's offset. In the alternate zone, after SETTZ set it
to US Central time:]
#exchange("clock.iso_alt")

#devcmd([GET_ISO_UTC], code: "5A",
  params: [p0: unused],
  reply: [25 bytes: ISO 8601 in UTC, offset `+0000`],
  ex: "clock.iso_utc")[]

== Time zones

A time zone is a POSIX `TZ` string: `UTC0`, `CST6CDT,M3.2.0,M11.1.0`,
`CET-1CEST,M3.5.0,M10.5.0/3`.

#devcmd([GET_GENERAL], code: "47",
  params: [p0: unused],
  reply: [the system time zone and a NUL],
  ex: "clock.general")[
An empty or malformed zone reads as `UTC`.]

#devcmd([GETTZ_LEN], code: "4C",
  params: [p0: unused],
  reply: [1 byte: the length of the system zone, plus 1 for the NUL],
  ex: "clock.tzlen")[]

#devcmd([SETTZ], code: "99",
  params: [p0: unused],
  payload: [a time-zone string, NUL-terminated],
  ex: "clock.settz")[
Sets the #strong[alternate] zone, used by commands sent with `p0 = 1` and by
GETTZTIME. It is not saved: it lasts until the adapter restarts.]

#devcmd([SETTZ_ALT], code: "74",
  params: [p0: unused],
  payload: [a time-zone string, NUL-terminated],
  ex: "clock.settz_alt")[
Sets the #strong[system] zone and saves it to `fnconfig.ini` as
`[General] timezone`.]

#note[Both SETTZ commands answer ACK before they look at the string. A zone
containing control characters or bytes above `7E` is then quietly ignored.]

The Atari-format and "alternate spelling" reads --- `41`, `61`, `69`, `70`,
`73`, `7A` --- are not available on RS-232 and answer NAK.

// ============================================================
// CHAPTER 11: THE PRINTER
// ============================================================
#chapter[The Printer (40h)]

The printer device accepts text and printer control codes and renders them
on the adapter, as a printer of the type chosen in `fnconfig.ini` would. The
result is a file kept on the adapter's SD card (or in its flash when there is
no card), which the web interface offers for download --- as a PDF for the
emulated graphics printers, as text for the plain types.

#devcmd([WRITE], code: "57",
  payload: [up to 255 bytes to print],
  ex: "printer.write")[
Prints the bytes. PUT (`50`) is the same command. An empty payload is
refused with NAK.]

#caution[Keep each WRITE to #strong[255 bytes or fewer]. The renderer takes
the length as a single byte, so a longer write is cut short, and its buffer
holds 320 bytes with no check: more than that overwrites the firmware's
memory. One line per WRITE is the natural size.]

#devcmd([STATUS], code: "53",
  params: [p0: unused, but must be sent],
  reply: [4 bytes: `00`, a byte with no meaning, `05`, `00`],
  ex: "printer.status")[
The Atari 820 status frame, kept for compatibility: the timeout byte `05` is
the only constant. The second byte is meant to repeat the last write's
parameter; on RS-232 it is never set, and holds leftover memory.]

#note[When `[General] printer_enabled=0`, the printer ignores every command
without replying.]

== Printer types

#block(sticky: true)[
`[Printer1] type` chooses the emulation:
]

#ktable(columns: (auto, 1fr, auto, 1fr),
  table.header[Type][Printer][Type][Printer],
  [0], [file, raw bytes], [9], [Atari 1029],
  [1], [file, text, trailing blanks trimmed (default)], [10], [Atari XMM801],
  [2], [file, ASCII], [11], [Atari XDM121],
  [3], [Atari 820], [12], [Epson 80],
  [4], [Atari 822], [13], [Epson for The Print Shop],
  [5], [Atari 825], [14], [Okimate 10],
  [6], [Atari 1020], [15], [GRANTIC (PNG image)],
  [7], [Atari 1025], [16], [HTML],
  [8], [Atari 1027], [17], [HTML with ATASCII],
)

For a CP/M or S-100 machine, type 1 (a text file) or type 12 (an Epson
80, which understands the usual ESC codes and renders a PDF) are the useful
choices. The firmware treats CR as the end of a line.

// ============================================================
// CHAPTER 12: THE MODEM
// ============================================================
#chapter[The Modem (50h)]

The modem device is a Hayes-style modem that dials TCP hosts instead of
telephone numbers: `ATDT bbs.example.com:23` connects, and from then on the
bytes typed go to the host and the host's bytes come back. It is the oldest
part of the RS-232 firmware, and it does not follow the packet rules of the
rest of the bus.

== Talking to the modem

There are two ways in:

- #strong[Raw bytes.] Anything that arrives on the serial line outside a
  FujiBus frame --- before an opening END --- is given to the modem, as if
  typed at it. A terminal program can therefore talk to the modem directly,
  sending `ATDT...` and a carriage return as plain text.
- #strong[WRITE packets.] A FujiBus WRITE (`57`) to device `50` hands its
  payload to the modem the same way.

And one way out: everything the modem says --- its result messages, and in
data mode the remote host's bytes --- is written to the serial line #strong[as
raw bytes, never inside a frame]. That includes its answers to the FujiBus
commands below: a modem STATUS comes back as two bare bytes, and an
acknowledgement as nothing at all.

#caution[The modem's immediate answers to AT commands are suppressed on the
RS-232 bus: `AT` does not answer `OK`, `ATIP` does not print the address.
The commands still take effect, and messages the modem sends later ---
`CONNECT`, `NO CARRIER` --- do appear. Write modem programs to watch for
`CONNECT` and the remote host's data, not for `OK`.]

== A call

#block(sticky: true)[
Captured on fujinet-pc, sending plain text on the serial line to a test
server on port 7777:
]

#codepanel("Computer sends (raw)", "ATDT127.0.0.1:7777<CR>")
#codepanel("FujiNet sends back (raw)",
"WELCOME TO THE ECHO SERVER<CR><LF>
TYPE A LINE, OR BYE.<CR><LF>
CONNECT 115200<CR><LF>")
#codepanel("Computer sends, then FujiNet answers",
"hello<CR>                        ->  YOU SAID: HELLO<CR><LF>
bye<CR>                          ->  SO LONG.<CR><LF> NO CARRIER<CR><LF>")

While the call was up, a FujiBus GET_WIFISTATUS packet sent on the same line
was answered normally, framed, in between the host's text. A program can use
the modem and the rest of the bus together, provided it can tell raw modem
bytes from framed replies: a FujiBus reply always begins with `C0`.

== AT commands

#btable(columns: (auto, 1fr),
  table.header[Command][Effect],
  [`ATDT`#emph[host]`:`#emph[port], `ATDP`, `ATDI`],
   [Dial. The port defaults to 23. A host of digits only is looked up in the
    phonebook.],
  [`ATA`], [Answer an incoming call (see `ATPORT`).],
  [`ATH`, `+++ATH`], [Hang up. `+++` returns to command mode during a call.],
  [`ATO`], [Return to a call from command mode.],
  [`ATPORT`#emph[n]], [Listen for incoming connections on TCP port #emph[n].],
  [`ATS0=1`, `ATS0=0`], [Auto-answer on or off.],
  [`ATE0`, `ATE1`], [Echo off or on.],
  [`ATV0`, `ATV1`], [Numeric or word result codes.],
  [`ATNET0`, `ATNET1`], [TELNET negotiation off or on.],
  [`AT+TERM=`#emph[type]], [Terminal type reported to TELNET hosts:
   `VT52`, `VT100`, `ANSI`, `DUMB`. (`ANSI` and `DUMB` are swapped in the
   firmware.)],
  [`ATWIFILIST`, `ATWIFICONNECT`#emph[ssid]`,`#emph[key]],
   [List networks; join one.],
  [`ATGET`#emph[url]], [Fetch a web page and print it.],
  [`ATPB`#emph[number]`=`#emph[host]`:`#emph[port]], [Add a phonebook entry.],
  [`ATPBLIST`, `ATPBCLEAR`], [List or empty the phonebook.],
  [`AT+SNIFF`, `AT-SNIFF`], [Record the traffic to a file, or stop.],
  [`AT?`, `ATIP`], [Help; the adapter's address. Their output is suppressed
   on RS-232.],
)

`AT&F`, `AT&W`, `ATM0`, `ATX1`, `AT&C1`, `AT&D2` and `ATS` registers other
than `S0` are accepted and ignored, so old dialling strings work. The
phonebook is kept in `fnconfig.ini` (Chapter 3); dialling `5551234`
pretends to connect, for old terminal programs that insist on dialling a
number first.

#caution[`ATCPM` is listed by the modem's help text but the CP/M device
it hands over to does not exist on the RS-232 bus (Chapter 13): the firmware
dereferences a null pointer and crashes. Do not send it.]

== Modem commands

#btable(columns: (auto, auto, auto, 1fr),
  table.header[Command][Code][Params][Effect and reply],
  [WRITE], [`57`], [---], [Payload to the AT parser, or to the host during a
   call. No reply.],
  [STATUS], [`53`], [p0 (unused)], [2 raw bytes: `00`, then the modem lines
   --- DSR in bits 7--6, CTS in bits 3--2, `11` each while connected --- and
   bit 0 set when data is waiting.],
  [LISTEN], [`4C`], [p0: port], [Listen for calls on a TCP port.],
  [UNLISTEN], [`4D`], [---], [Stop listening.],
  [AUTOANSWER], [`4F`], [p0: `01` on], [Answer calls by itself.],
  [BAUDRATELOCK], [`4E`], [p0: on/off, p1: baud], [Fix the reported speed.],
  [SET_DUMP], [`44`], [p0: on/off], [The traffic sniffer.],
  [CONFIGURE], [`42`], [---], [Accepted; sets 9600 unless the rate is locked.],
  [CONTROL], [`41`], [---], [Accepted; does nothing on RS-232.],
  [STREAM], [`58`], [---], [Atari concurrent mode: 9 raw bytes of POKEY
   divisors, then the bus changes speed. Not useful on RS-232.],
)

#codepanel("Modem STATUS, captured",
"sent:      C0 50 53 07 00 AB 01 00 C0      (a normal FujiBus packet)
received:  00 00                           (two raw bytes, no frame)")

// ============================================================
// CHAPTER 13: CP/M
// ============================================================
#chapter[The CP/M Device (5Ah)]

The FujiNet firmware contains a CP/M 2.2 emulator, RunCPM, and a device to
start it: command `47` to device `5A` would switch the serial line over to a
CP/M console running #emph[on the adapter]. On the Atari and Coleco ADAM
FujiNets this lets a terminal run CP/M programs from the SD card.

On the RS-232 build the CP/M device is compiled in but #strong[never placed
on the bus], so device `5A` does not exist. A packet sent to it is answered
like any packet to a missing device, with a NAK whose device byte is `00`.
The `[CPM]` section of `fnconfig.ini` has no effect, and the modem's `ATCPM`
command, which would hand the line to the same device, crashes the adapter
(Chapter 12).

A computer that wants CP/M should run its own, from a disk image mounted in
a disk slot (Chapter 8). That is what the 88-2SIO Altair in the appendices
would do: boot CP/M from disk slot 1 and run CONFIG, NETCAT and 5 Card Stud
as `.COM` files.

// ============================================================
// APPENDICES
// ============================================================
#counter(heading).update(0)
#appendix.update(true)
// Letters at level 1 (so the counter advances and the kicker/TOC show A, B,
// C...); nothing at deeper levels (appendix sections carry their own labels).
#set heading(numbering: (..n) => {
  let nums = n.pos()
  if nums.len() == 1 { numbering("A", ..nums) } else { none }
})

// ============================================================
// APPENDIX A: QUICK REFERENCE
// ============================================================
#chapter[Quick Reference]

// the reference tables are set a little tighter than the body's
#show table: set text(size: 7.9pt)
#set table(inset: (x: 5pt, y: 3pt))

== A.1 The packet

#ktable(columns: (auto, 1fr),
  table.header[Item][Rule],
  [Frame], [`C0`, the packet with `C0` sent as `DB DC` and `DB` as `DB DD`,
   `C0`. One END each side.],
  [Header], [device · command · length (16 bits, LE, whole packet) ·
   checksum · descriptor],
  [Checksum], [8-bit sum of the whole packet with end-around carry,
   computed with the checksum byte zero.],
  [Descriptor], [low 3 bits: `0` none, `1`--`4` that many u8, `5` one u16,
   `6` two u16, `7` one u32. Bit 7: another descriptor follows.],
  [Reply], [device = who answered; command `06` ACK (data in the payload) or
   `15` NAK (never data); descriptor `00`.],
  [Silence], [bad checksum, bad length, stalled frame, RESET, printer
   disabled, missing parameter (crash).],
)

== A.2 Devices

#ktable(columns: (auto, auto, auto, auto, auto, auto, auto),
  table.header[Fuji][Disk][Printer][Clock][Modem][CP/M][Network],
  [`70`], [`31`--`38`], [`40`], [`45`], [`50`], [`5A` (absent)], [`71`--`78`],
)

== A.3 Fuji device (70h)

#btable(columns: (auto, auto, 1fr, 1fr),
  table.header[Code][Command][Params / payload][Reply],
  [`FF`], [RESET], [---], [none (restarts)],
  [`FE`], [GET_SSID], [---], [97: SSID 33, password 64],
  [`FD`], [SCAN_NETWORKS], [---], [1: count],
  [`FC`], [GET_SCAN_RESULT], [p0 index], [34: SSID 33, RSSI],
  [`FB`], [SET_SSID], [97: SSID 33, password 64], [ACK when joined],
  [`FA`], [GET_WIFISTATUS], [---], [1: `03` up, `06` down],
  [`F9`], [MOUNT_HOST], [p0 host], [ACK],
  [`F8`], [MOUNT_IMAGE], [p0 disk, p1 mode], [ACK],
  [`F7`], [OPEN_DIRECTORY], [p0 host; 256: path NUL [pattern NUL]], [ACK],
  [`F6`], [READ_DIR_ENTRY], [p0 length, p1 flags], [p0 bytes; `7F 7F` at end],
  [`F5`], [CLOSE_DIRECTORY], [---], [ACK],
  [`F4`], [READ_HOST_SLOTS], [---], [256: 8 #sym.times 32],
  [`F3`], [WRITE_HOST_SLOTS], [256: 8 #sym.times 32], [ACK],
  [`F2`], [READ_DEVICE_SLOTS], [---], [304: 8 #sym.times 38],
  [`F1`], [WRITE_DEVICE_SLOTS], [304: 8 #sym.times 38], [ACK],
  [`EA`], [GET_WIFI_ENABLED], [---], [1],
  [`E9`], [UNMOUNT_IMAGE], [p0 disk], [ACK],
  [`E8`], [GET_ADAPTERCONFIG], [---], [140],
  [`E7`], [NEW_DISK], [262], [always NAK],
  [`E6`], [UNMOUNT_HOST], [p0 host], [ACK],
  [`E5`], [GET_DIRECTORY_POSITION], [---], [2],
  [`E4`], [SET_DIRECTORY_POSITION], [p0 (u16)], [ACK],
  [`E2`], [SET_DEVICE_FULLPATH], [p0 disk, p1 host, p2 mode; 256: path], [ACK],
  [`E1`], [SET_HOST_PREFIX], [p0 host; 256: prefix], [ACK],
  [`E0`], [GET_HOST_PREFIX], [p0 host], [256],
  [`DE`], [WRITE_APPKEY], [up to 64 bytes], [ACK],
  [`DD`], [READ_APPKEY], [---], [length (u16) + data],
  [`DC`], [OPEN_APPKEY], [6: creator, app, key, mode, 0], [ACK],
  [`DB`], [CLOSE_APPKEY], [---], [ACK],
  [`DA`], [GET_DEVICE_FULLPATH], [p0 disk], [256],
  [`D9`], [CONFIG_BOOT], [p0], [ACK],
  [`D8`], [COPY_FILE], [p0, p1 hosts #strong[from 1]\; `src|dst` NUL], [ACK],
  [`D7`], [MOUNT_ALL], [---], [ACK],
  [`D6`], [SET_BOOT_MODE], [p0 mode], [ACK],
  [`D3`], [RANDOM_NUMBER], [---], [4],
  [`D0`/`CC`], [BASE64 ENC/DEC INPUT], [p0 count (u16); data], [ACK],
  [`CF`/`CB`], [BASE64 ENC/DEC COMPUTE], [---], [ACK],
  [`CE`/`CA`], [BASE64 ENC/DEC LENGTH], [---], [4],
  [`CD`/`C9`], [BASE64 ENC/DEC OUTPUT], [p0 count (u16)], [data],
  [`C8`], [HASH_INPUT], [p0 count (u16); data], [ACK],
  [`C7`/`C3`], [HASH_COMPUTE (/NO_CLEAR)], [p0 algorithm 0--3], [ACK],
  [`C6`], [HASH_LENGTH], [p0 `01` hex], [1],
  [`C5`], [HASH_OUTPUT], [p0 `01` hex], [digest],
  [`C4`], [GET_ADAPTERCONFIG_EXTENDED], [---], [240],
  [`C2`], [HASH_CLEAR], [---], [ACK],
  [`BF`], [QRCODE_OUTPUT], [p0 count (u16)], [data],
  [`BE`], [QRCODE_LENGTH], [p0 form 0--5], [4],
  [`BD`], [QRCODE_ENCODE], [p0 version, p1 ECC, p2 shorten], [ACK],
  [`BC`], [QRCODE_INPUT], [p0 count (u16); text], [ACK],
  [`BB`], [GENERATE_GUID], [---], [37],
  [`53`], [STATUS], [---], [4 zeroes],
  [`00`], [DEVICE_READY], [---], [512 #sym.times `41`],
)

== A.4 Disk drives (31h--38h)

#ktable(columns: (auto, auto, 1fr, 1fr),
  table.header[Code][Command][Params / payload][Reply],
  [`52`], [READ], [p0 sector (u32)], [512 (flat image)],
  [`57`], [WRITE], [p0 sector (u32); sector], [ACK],
  [`50`], [PUT], [p0 sector (u32); sector], [ACK],
  [`53`], [STATUS], [do not use: it writes], [---],
  [`21`/`22`], [FORMAT, FORMAT_MEDIUM], [---], [128: `FF FF` ...],
  [`4E`], [PERCOM_READ], [---], [12],
  [`4F`], [PERCOM_WRITE], [12], [ACK],
)

== A.5 Network units (71h--78h)

#btable(columns: (auto, auto, 1fr, 1fr),
  table.header[Code][Command][Params / payload][Reply],
  [`4F`], [OPEN], [p0 mode, p1 translation; devicespec NUL], [ACK],
  [`43`], [CLOSE], [---], [ACK],
  [`53`], [STATUS], [---], [4: waiting (u16), connected, status],
  [`52`], [READ], [p0 count (u16)], [up to count bytes],
  [`57`], [WRITE], [p0 count (u16); data], [ACK],
  [`FC`], [SET_PARSER], [p0 0, p1 `01` JSON / `02` HTML / `03` XML], [ACK],
  [`50`], [PARSE], [---], [ACK],
  [`51`], [QUERY], [path], [ACK],
  [`FB`], [SET_PARAMETER], [p0 `00` flags / `01` EOL, p1 value], [ACK],
  [`54`], [TRANSLATION], [p0 0, p1 translation], [ACK],
  [`4C`], [SET_EOL], [EOL bytes], [ACK],
  [`5A`], [SET_INT_RATE], [p0 ms], [ACK],
  [`25`], [SEEK], [p0 offset (u32)], [ACK],
  [`26`], [TELL], [---], [4],
  [`30`], [GETCWD], [---], [path, no NUL],
  [`2C`], [CHDIR], [path], [ACK],
  [`FD`], [USERNAME], [name NUL], [ACK],
  [`FE`], [PASSWORD], [password NUL], [ACK],
  [`20`], [RENAME], [p0 mode, p1 0; `spec,new` NUL], [ACK],
  [`21`/`23`/`24`], [DELETE / LOCK / UNLOCK], [p0 mode, p1 0; spec NUL], [ACK],
  [`2A`/`2B`], [MKDIR / RMDIR], [p0 mode, p1 0; spec NUL], [ACK],
  [`41`], [ACCEPT], [---], [ACK],
  [`63`], [CLOSE_CLIENT], [---], [inverted: NAK on success],
  [`4D`], [SET_HTTP_MODE], [p0 0, p1 mode 0--4], [ACK],
  [`72`], [GET_REMOTE], [---], [256: `addr:port` `9B`],
  [`44`], [SET_DESTINATION], [`N:host:port` NUL], [ACK],
)

OPEN modes: `04` read/GET, `05` DELETE, `06` directory, `07` directory
(alternate), `08` write/PUT, `09` append/DELETE with headers, `0C` read-write/GET
with headers, `0D` POST, `0E` PUT with headers. Translation: `00` none, `01` CR,
`02` LF, `03` CR LF, `04` PETSCII. Status: `01` OK, `88` end of file, `C8`
refused, `CF` not connected; the full list is in Chapter 9.

== A.6 Clock (45h), printer (40h), modem (50h)

#ktable(columns: (auto, auto, auto, 1fr),
  table.header[Device][Code][Command][Reply (all clock commands take p0)],
  [`45`], [`93`], [GETTIME], [6: D M Y-2000 h m s],
  [`45`], [`9A`], [GETTZTIME], [6, alternate zone],
  [`45`], [`54`], [GET_SIMPLE], [7: century Y M D h m s],
  [`45`], [`4D`], [GET_SIMPLE_HUNDREDTHS], [8],
  [`45`], [`50`], [GET_PRODOS], [4],
  [`45`], [`53`], [GET_SOS], [19: `YYYYMMDD0HHMMSS000` NUL],
  [`45`], [`49`], [GET_ISO_LOCAL], [25: ISO 8601 NUL],
  [`45`], [`5A`], [GET_ISO_UTC], [25],
  [`45`], [`47`], [GET_GENERAL], [zone NUL],
  [`45`], [`4C`], [GETTZ_LEN], [1],
  [`45`], [`99`], [SETTZ], [ACK (alternate zone, not saved)],
  [`45`], [`74`], [SETTZ_ALT], [ACK (system zone, saved)],
  [`40`], [`57`/`50`], [WRITE / PUT], [ACK; at most 255 bytes],
  [`40`], [`53`], [STATUS], [4 (p0 required)],
  [`50`], [`57`], [WRITE], [none; text to the modem],
  [`50`], [`53`], [STATUS], [2 raw bytes, unframed],
)

#show table: set text(size: 8.6pt)
#set table(inset: (x: 6pt, y: 4pt))

// ============================================================
// APPENDIX B: A FUJIBUS LIBRARY IN Z80
// ============================================================
#chapter[A FujiBus Library in Z80]

The programs in the next three appendices share three include files: a
#strong[platform layer] that touches the hardware, a #strong[console layer]
of printing and input helpers, and the #strong[FujiBus layer] that builds,
sends and receives packets. They are written for the Z80 and assembled with
`z88dk-z80asm`. An 8080 version is possible: the Z80-only instructions are
`JR`, `DJNZ`, `LDIR`, `NEG`, `SBC HL` and the `ED`-prefixed 16-bit loads such
as `LD DE,(nn)`, each of which has a short 8080 equivalent.

#fig(flow(
  nodebox("fncfg.asm  netcat.asm  stud.asm", sub: "the programs", w: 140pt),
  biarrow(w: 22pt),
  nodebox("FUJIBUS.INC", sub: "FBNEW · FBCALL · CKSUM", fill: tip-bg, bd: rgb("#3f7d3f"), w: 104pt),
  biarrow(w: 22pt),
  nodebox("ALTAIR.INC", sub: "FNIN · FNOUT · CONIN · CONOUT", fill: amber-bg, bd: amber, w: 124pt),
), caption: [The three layers. Only ALTAIR.INC knows what the hardware is;
CONIO.INC, used by the programs for the terminal, sits beside FUJIBUS.INC
on top of it.])

== B.1 The platform layer: ALTAIR.INC

The MITS 88-2SIO carries two Motorola 6850 ACIAs. Port A, at I/O addresses
`10h` (control and status) and `11h` (data), is the operator's terminal or
Teletype. Port B, at `12h` and `13h`, is wired to the FujiNet. A 6850 is
programmed by writing `03` (master reset) and then a mode byte to its
control register; `15h` selects a divide-by-16 clock, 8 data bits, no
parity, one stop bit and no interrupts. The baud rate itself is set by
jumpers on the board. Reading the status register gives `RDRF` (bit 0, a byte
has arrived) and `TDRE` (bit 1, the transmitter can take a byte).

#block(sticky: true)[
Every routine that touches a port lives in ALTAIR.INC, between lines that
read `PLATFORM BEGIN` and `PLATFORM END` (shaded in the listing at the end of
this appendix). These are the routines to rewrite for other hardware, and
their contracts are all the rest of the code relies on:
]

#ktable(columns: (auto, 1fr),
  table.header[Routine][Contract (BC, DE, HL preserved unless stated)],
  [`PINIT`], [Set up both serial ports.],
  [`CONST`], [`A = 0` if no key is waiting; non-zero if one is.],
  [`CONIN`], [Wait for a key; return it in `A` with bit 7 clear.],
  [`CONOUT`], [Send `A` to the terminal.],
  [`FNOUT`], [Send `A` to the FujiNet.],
  [`FNST`], [`A = 0` if no byte is waiting from the FujiNet.],
  [`FNIN`], [Wait for a byte from the FujiNet, but not for ever: carry
   clear and the byte in `A`, or carry set after about 250 ms of silence.],
  [`DELAY`], [Wait about `A` #sym.times 10 ms.],
  [`PEXIT`], [Leave the program: `HALT` on bare metal, `JP 0` (CP/M warm
   boot) when assembled with `-DCPM`.],
)

The two timeouts are counted in instructions, so they depend on the clock.
FNIN's loop takes 51 T-states a pass, and `FNTMO = 9600` passes is about
250 ms at 2 MHz; DELAY's inner loop is 26 T-states, and `DLY10MS = 769` is
10 ms. Double both constants for a 4 MHz Z80.

#snip("listings/common/altair.inc", "FNIN:", ";------", title: "FNIN: receive a byte, with a timeout")

== B.2 Moving to other hardware

#block(sticky: true)[
Only the routines between the PLATFORM markers change. A few common cases:
]

#sub[A different 88-2SIO strapping, or two boards]

Change the four `EQU`s at the top. A board strapped at `20h` for the
FujiNet needs only `FNSTAT EQU 20h` and `FNDATA EQU 21h`.

#sub[An Intel 8251 USART]

#block(sticky: true)[
Many S-100 and single-board machines (the Cromemco TU-ART, the SD Systems
boards, the IMSAI SIO) use an 8251. Its status bits are in different places
--- `TxRDY` is bit 0, `RxRDY` bit 1 --- and it needs a mode and a command byte
after reset:
]

#codepanel("PLATFORM: 8251 USART for the FujiNet (data 22h, control 23h)",
"FNDATA  EQU     22h
FNCTL   EQU     23h
TXRDY   EQU     01h
RXRDY   EQU     02h

FNINIT: XOR     A               ; the classic 8251 wake-up: three zeroes,
        OUT     (FNCTL),A       ;   then an internal reset
        OUT     (FNCTL),A
        OUT     (FNCTL),A
        LD      A,40h
        OUT     (FNCTL),A
        LD      A,4Eh           ; mode: async x16, 8 data, no parity, 1 stop
        OUT     (FNCTL),A
        LD      A,37h           ; command: RTS, error reset, RX on, DTR, TX on
        OUT     (FNCTL),A
        RET

FNOUT:  PUSH    AF
FOUT1:  IN      A,(FNCTL)
        AND     TXRDY
        JR      Z,FOUT1
        POP     AF
        OUT     (FNDATA),A
        RET

FNST:   IN      A,(FNCTL)
        AND     RXRDY
        RET")

FNIN keeps its shape: poll `FNCTL` for `RXRDY` instead of `FNSTAT` for
`RDRF`.

#sub[A Zilog SIO or SCC]

The Z80 SIO (Kaypro, Osborne Executive, many CP/M boards) reports
"character available" in bit 0 and "transmit buffer empty" in bit 2 of read
register 0, which is what a plain `IN` from its control port returns. Its
set-up is a short table of register writes (channel reset, then registers
4, 3 and 5 for x16 clock, 8 bits, receiver and transmitter on), and the baud
rate comes from a separate CTC or baud-rate generator.

#sub[A CP/M machine whose console is not a 6850]

Under CP/M the console routines can call the BIOS or BDOS instead of
touching hardware: CONST becomes BDOS function 11, CONIN function 1 (or the
BIOS CONIN entry, which does not echo), CONOUT function 2. Only the FujiNet
routines then need real port code, for the serial port the FujiNet is plugged
into --- the reader or punch port, or a second serial card.

#important[Whatever the hardware, the receive side must keep up. The
FujiNet sends a reply as fast as the line allows, with no flow control, and
a single-byte UART like the 6850 holds only one byte: FBRECV stores each
byte and goes straight back for the next. Do not add work to that loop, and
do not let an interrupt routine hold the processor for longer than one
character time (about 1 ms at 9600 baud). If you cannot avoid it, lower the
baud rate, or use the RESEND command where the firmware has it.]

== B.3 The packet layer: FUJIBUS.INC

#block(sticky: true)[
A program sends a command in three steps: start the packet with FBNEW, add
parameters and payload with FBBYTE, FBWORD, FBMEM and FBSTR, then call FBCALL.
GET_WIFISTATUS, for example, is:
]

#codepanel("A complete command",
"        LD      A,70h           ; device: Fuji
        LD      C,0FAh          ; command: GET_WIFISTATUS
        LD      B,00h           ; descriptor: no parameters
        CALL    FBNEW
        CALL    FBCALL          ; send it, collect the reply
        JR      C,NOREPLY       ; carry: no good reply
        JR      NZ,GOTNAK       ; NZ: NAK
        LD      A,(HL)          ; HL -> payload, BC = its length")

#block(sticky: true)[
The descriptor is given by the caller, not worked out by the library: the
programmer knows the command takes, say, two 8-bit parameters, and writes
`LD B,02h`. FBNEW stores the device, the command and the descriptor, leaves
room for the length and the checksum, and FBCALL fills both in when the
packet is complete:
]

#snip("listings/common/fujibus.inc", "FBCALL:", "FBC1:", title: "FBCALL: finishing the packet")

#block(sticky: true)[
FBSTR is the library's answer to the fixed-size payload rule of Chapter 4:
it copies a NUL-terminated string into a field of exactly the size given,
padding with zeroes. A path for OPEN_DIRECTORY is therefore one call:
]

#codepanel("A 256-byte path field",
"        LD      HL,PATH         ; the string
        LD      BC,256          ; the field size
        CALL    FBSTR")

=== Sending

FBSEND writes the frame: one END, each byte with `C0` and `DB` replaced by
their escape pairs, and one END.

#snip("listings/common/fujibus.inc", "FBSEND:", "        IF      USE_RESEND", title: "FBSEND: SLIP framing")

=== Receiving

#block(sticky: true)[
FBRECV is the delicate part. It waits up to FBWAIT timeouts (40, about ten
seconds) for the opening END, skipping anything else; then it stores bytes,
undoing escapes, until the closing END. Each byte must arrive within one
FNIN timeout or the frame is abandoned. Finally it checks the length field
and the checksum. On failure it sets `FBERR` to say why, which the programs
print:
]

#ktable(columns: (auto, 1fr),
  table.header[FBERR][Meaning],
  [1], [no reply at all],
  [2], [the reply stopped part-way],
  [3], [longer than RXMAX (600 bytes)],
  [4], [shorter than a header],
  [5], [the length field disagrees with the bytes received],
  [6], [bad checksum],
)

#snip("listings/common/fujibus.inc", "FBR3:", "FBR8:", title: "FBRECV: the receive loop")

=== Retrying

#block(sticky: true)[
FBCALL tries up to three times. Before the first try it drains the port
(FBDRAIN, Chapter 5), so that a stale byte cannot be taken for the reply.
After a failure it sends the whole command again --- or, when the library is
assembled with `-DUSE_RESEND=1` and some of the reply did arrive, it sends
the RESEND command instead:
]

#snip("listings/common/fujibus.inc", "FBC1:", "FBC3:", title: "FBCALL: the retry loop")

The retry logic was tested by passing the simulated Altair's traffic through
a proxy that damaged every second or third reply (`tools/faultproxy.py`):
CONFIG ran correctly both ways, re-sending commands in the default build and
asking for RESEND in the other.

== B.4 The console layer: CONIO.INC

#block(sticky: true)[
CONIO.INC holds the small routines every program needs: PRINT (print the
string that follows the CALL), PRSTR and PRSTRN, CRLF, PRHEX, PRDEC (and
PRDECW, right-aligned in a field), GETLN (a line editor with backspace and
Ctrl-C), GETKEY and UCASE. Its one trick is PRINT, which finds its string
through the return address and returns past it:
]

#snip("listings/common/conio.inc", "PRINT:", "PRSTR:", title: "PRINT: an inline string")

== B.5 A first program: HELLO

HELLO asks for the WiFi status and prints the host slots: the smallest
program that proves the hardware, the cable and the configuration are right.
Run it first.

#session("listings/hello/session.txt", title: "HELLO on the simulated Altair")

== B.6 Building

```
cd listings/hello
z88dk-z80asm -b hello.asm               # -> hello.bin, to load at 0100h
z88dk-z80asm -b -DCPM=1 hello.asm       # the same, exiting to CP/M
z88dk-z80asm -b -DUSE_RESEND=1 ...      # ask for RESEND on a bad reply
```

Every program is `ORG 0100h` and uses no CP/M calls, so the same binary can
be loaded at `0100h` and started from a monitor or the front panel, or
renamed `.COM` and run from CP/M (assemble with `-DCPM=1` so that it returns
to CP/M rather than halting). `make listings` at the top of the manual's
directory builds them all.

== B.7 Listings

#code-listing("ALTAIR.INC", "listings/common/altair.inc")
#code-listing("FUJIBUS.INC", "listings/common/fujibus.inc")
#code-listing("CONIO.INC", "listings/common/conio.inc")
#code-listing("HELLO.ASM", "listings/hello/hello.asm")

// ============================================================
// APPENDIX C: CONFIG
// ============================================================
#chapter[CONFIG in Z80]

Every FujiNet platform has a CONFIG program: the tool that names host slots,
browses them, and puts disk images into disk slots. This one is written for a
terminal or a Teletype on an Altair 8800 and the 88-2SIO, in plain scrolling
text with no cursor addressing, and it uses only the commands of Chapter 7.
It is about 700 lines of Z80 and assembles to under 6 KB.

== C.1 What it does

#block(sticky: true)[
CONFIG starts by showing everything at once --- the network, the eight host
slots and the eight disk slots --- and then waits for a one-letter command:
]

#ktable(columns: (auto, 1fr),
  table.header[Key][Action],
  [`H`], [Name a host slot (or clear it), then write the host table back.],
  [`B`], [Browse a host: walk its directories, choose an image, choose a disk
   slot and a mode, and mount it.],
  [`E`], [Eject the image in a disk slot.],
  [`W`], [Scan for WiFi networks and join one.],
  [`L`], [Show everything again.],
  [`Q`], [Quit.],
)

Here is a whole session on the simulated Altair: mounting a CP/M disk from
the SD card into disk slot 1, mounting the lobby disk from a TNFS server into
slot 2, renaming host slot 6, and ejecting slot 2 again.

#session("listings/config/session.txt", title: "A CONFIG session", to: 115)

== C.2 Talking to the Fuji device

#block(sticky: true)[
Most of CONFIG's commands take no parameters or one 8-bit parameter, so two
small routines build and send them: FCMD0 for a Fuji command with no
parameters, FCMD1 for one with a single byte in `E`. Both fall into CHECK,
which turns a failed FBCALL into a message and returns with carry set, so
callers can simply `RET C`:
]

#snip("listings/config/fncfg.asm", "FCMD0:", ";=====", title: "FCMD0, FCMD1 and CHECK")

== C.3 The display

#block(sticky: true)[
SHOWALL makes three requests. GET_ADAPTERCONFIG supplies the network name,
the IP address (four bytes at offset 97, printed by PRIP) and the firmware
version (offset 125). READ_HOST_SLOTS fills the 256-byte HOSTS table, which
CONFIG keeps: the `H` command changes one name in it and writes the whole
table back. READ_DEVICE_SLOTS fills SLOTS; for each 38-byte record CONFIG
prints the mode (bit 1 of byte 1 is "write"), the host slot, and the file
name:
]

#snip("listings/config/fncfg.asm", "; READ_DEVICE_SLOTS (F2h)", "SLOTNUM:", title: "Printing the disk slots")

Note that CONFIG #strong[never] writes SLOTS back: the slot table holds only
file names, not paths (Chapter 7), and writing it back would lose every
directory. Disk slots are changed one at a time, with SET_DEVICE_FULLPATH.

== C.4 Naming a host

#block(sticky: true)[
DOHOST asks for a slot number and a name, copies the name into the HOSTS
table zero-filled to 32 bytes, and sends all 256 bytes with WRITE_HOST_SLOTS:
]

#snip("listings/config/fncfg.asm", "DOHOST:", ";=====", title: "DOHOST")

== C.5 Browsing

#block(sticky: true)[
Browsing is the heart of CONFIG. DOBROWSE mounts the chosen host and opens
its root directory; BROPEN opens whatever directory `PATH` holds. The path is
sent with FBSTR, which pads it to the 256 bytes OPEN_DIRECTORY requires:
]

#snip("listings/config/fncfg.asm", "; OPEN_DIRECTORY (F7h)", "BRPAGE:", title: "BROPEN")

#block(sticky: true)[
BRNEXT reads entries one at a time with READ_DIR_ENTRY, asking for 64 bytes
each (long enough that the firmware rarely has to shorten a name), and stops
at the `7F 7F` end marker or after a page of sixteen. Each name is kept in a
page table so that the operator can pick one by number:
]

#snip("listings/config/fncfg.asm", "; READ_DIR_ENTRY (F6h)", "BRN1:", title: "BRNEXT: reading one entry")

#block(sticky: true)[
A name that ends in `/` is a directory: CONFIG appends it to `PATH` and opens
that. `U` climbs back up by cutting `PATH` after its second-to-last `/`.
Anything else is a file, and BRFILE mounts it: it closes the directory, asks
for a disk slot and a mode, joins `PATH` and the name into `FULL`, and sends
SET_DEVICE_FULLPATH followed by MOUNT_IMAGE:
]

#snip("listings/config/fncfg.asm", "; SET_DEVICE_FULLPATH (E2h)", ";=====", title: "BRFILE: mounting the chosen image")

== C.6 Joining a network

#block(sticky: true)[
DOWIFI scans, lists up to sixteen networks with their signal strength (a
signed byte, printed with NEG), asks for one and a password, and sends the
97-byte SET_SSID. Joining takes a while, so it raises FBWAIT to 120 timeouts,
about thirty seconds, for that one command:
]

#snip("listings/config/fncfg.asm", "; SET_SSID (FBh)", ";=====", title: "Joining a network")

== C.7 Listing

#code-listing("FNCFG.ASM", "listings/config/fncfg.asm")

// ============================================================
// APPENDIX D: NETCAT
// ============================================================
#chapter[NETCAT in Z80]

NETCAT turns the Altair into a terminal for any TCP or TELNET host: a
bulletin board, a MUD, a shell on another machine. It asks for a devicespec,
opens it on network unit 1, and then does two things in a loop: keys typed on
the terminal are sent with WRITE, and whatever the far end has sent is
collected with STATUS and READ and printed. Ctrl-\] hangs up.

#session("listings/netcat/session.txt", title: "NETCAT talking to a test server")

The typed lines do not appear: NETCAT does not echo, because the far end
usually does (a TELNET host always will). The two failed connections show
STATUS's error byte after a refused OPEN: `C8` (200) connection refused, and
`C9` (201) network unreachable for a host name that does not resolve.

== D.1 Opening

The devicespec is sent at its natural length with its NUL: unlike the Fuji
device's paths, OPEN's devicespec is a variable-length payload. OPEN can wait
for DNS and a TCP or TLS handshake, so NETCAT allows twenty seconds:

#snip("listings/netcat/netcat.asm", "; OPEN ('O')", "OPENED:", title: "Opening the connection")

When OPEN answers NAK, NETCAT sends STATUS to learn why.

== D.2 The loop

#snip("listings/netcat/netcat.asm", "TLOOP:", "BYE:", title: "The terminal loop")

Each pass sends at most one key and collects at most 256 bytes. When nothing
is waiting and the connected byte has gone to zero, the far end has hung up.
At 9600 baud a STATUS exchange takes about 20 ms, so NETCAT polls some fifty
times a second; a key typed while a READ is being printed waits in the
6850's receive register and is sent on the next pass.

#note[Printing on a slow terminal holds up the loop, but loses nothing: the
remote host's data waits in the FujiNet's buffer until NETCAT asks for it.
The same program works on a Teletype at 110 baud --- slowly.]

#sub[What could be added]

The RI line (Chapter 2) could replace the polling, if the serial board
offers an input to wire it to: STATUS would then be sent only when RI goes
off. A line-at-a-time mode would send fewer, larger WRITEs; a local-echo
switch would help with raw TCP hosts that do not echo.

== D.3 Listing

#code-listing("NETCAT.ASM", "listings/netcat/netcat.asm")

// ============================================================
// APPENDIX E: 5 CARD STUD
// ============================================================
#chapter[5 Card Stud in Z80]

FujiNet 5 Card Stud is a multiplayer poker game served by the FujiNet Game
System: players on any FujiNet machine --- an Atari, an Apple II, a CoCo, an
IBM PC --- sit at the same tables, with bots filling the empty seats. This
client puts an Altair at the table. It plays the game in plain text, one line
per move, so it works on a Teletype.

#session("listings/5cs/session.txt", title: "A hand at a developer table", to: 70)

== E.1 The server

The server is at `https://5card.carr-designs.com/`. It keeps no connection
open: every action is a single HTTP GET, and the game advances only when some
client asks for the state. A client needs four requests:

#ktable(columns: (auto, 1fr),
  table.header[Request][Purpose],
  [`tables?bin=1`], [The list of tables. (`&dev=1` lists the developer tables
   instead, for testing without disturbing real games.)],
  [`state?table=T&player=NAME&bin=1`], [The game as player NAME sees it. The
   first request joins the table.],
  [`move/CC?table=T&player=NAME&bin=1`], [Make the move whose two-letter code
   is CC (from the valid-move list), and return the new state.],
  [`leave?table=T&player=NAME`], [Leave the table.],
)

With `bin=1` the server answers in a fixed binary layout instead of JSON, so
the client reads fields at known offsets and never parses text. Strings are
fixed-width, NUL-padded and lower case; numbers are 16 bits, little-endian.

#ktable(columns: (auto, auto, 1fr),
  table.header[Offset][Size][Game state field],
  [0], [81], [last result text, such as `jim bot won with pair, twos`],
  [81], [1], [round: 0 waiting for players, 1--4 betting, 5 showdown],
  [82], [2], [pot],
  [84], [1], [whose turn (signed): 0 is you, #sym.minus;1 between rounds],
  [85], [1], [seconds left to move],
  [86], [1], [1 if the table is full and you are only watching],
  [87], [1], [number of valid moves],
  [88], [65], [5 valid moves of 13 bytes: code (2 + NUL), name (9 + NUL)],
  [153], [1], [number of players],
  [154], [33 each], [the players, you first],
)

#ktable(columns: (auto, auto, 1fr),
  table.header[Offset][Size][Player field],
  [0], [9], [name],
  [9], [1], [status: 0 waiting for the next game, 1 playing, 2 folded, 3 left],
  [10], [2], [bet this round],
  [12], [8], [last move, as text],
  [20], [2], [purse],
  [22], [11], [cards, two characters each: value (`2`--`9`, `t`, `j`, `q`,
   `k`, `a`) and suit (`c`, `d`, `h`, `s`); `??` for a face-down card],
)

The table list is one count byte, then up to ten 36-byte records: table id
(9), name (21) and a player count such as `3 / 8` (6).

== E.2 Fetching

Every request is the same five FujiBus commands --- OPEN in mode `0C`, then
STATUS and READ until the end-of-file status `88`, then CLOSE --- wrapped in
HTTPGET. Note the end test: for HTTP the connected byte is no help (Chapter
9), so HTTPGET stops on status `88` with nothing waiting:

#snip("listings/5cs/stud.asm", "HG1:", "HG3:", title: "HTTPGET: waiting for the end of the reply")

The request strings are built by concatenation into URLBUF: the base address,
the request name, and QUERY, which appends the table, the player name (spaces
turned into `+`) and `&bin=1`.

== E.3 The game loop

#snip("listings/5cs/stud.asm", "GLOOP:", "LEAVE:", title: "GLOOP")

Each pass fetches the state --- or, if a move is waiting, sends it, which
returns the new state just the same --- and reports what has changed. If the
active player is 0 (you), you are seated, and there are moves to make, it
asks for one; otherwise it waits about a second, watching for `Q`, and asks
again.

== E.4 Reporting for a Teletype

A screen client redraws the table on every change. On a Teletype at ten
characters a second that would take most of a minute each time a bot bets,
so REPORT prints the whole table only when a new round starts (or someone
joins or leaves), and otherwise one line for each player whose bet or move
has changed:

#snip("listings/5cs/stud.asm", "REPORT:", "RP3:", title: "REPORT: what changed?")

The comparison is against LAST, a copy of the previous state. LAST has a
second use: when the player picks a move, the move's two-letter code is taken
from LAST, because RESP will be overwritten by the very request that sends the
move.

== E.5 Asking for a move

ASKMOVE prints the player's cards and the pot, then the valid moves numbered
from 1, and waits for a key --- but no longer than the server's move timer,
since the server moves for a player who runs out of time. The wait is the
timer's seconds, each a hundred 10 ms DELAYs, with the keyboard checked every
time round:

#snip("listings/5cs/stud.asm", "AM3:", "AM6:", title: "Waiting for a move, against the clock")

== E.6 Listing

#code-listing("STUD.ASM", "listings/5cs/stud.asm")

// ============================================================
// APPENDIX F: RUNNING THE EXAMPLES IN SIMH
// ============================================================
#chapter[Running the Examples in SIMH]

Every program in this book was assembled and run on the AltairZ80 simulator
from SIMH, with its 88-2SIO model connected to fujinet-pc. That arrangement
needs no hardware at all, and it is a good place to develop: when something
goes wrong, the fujinet-pc log shows every packet it received.

#fig(flow(
  nodebox("terminal", sub: "term.py / nc", w: 66pt),
  biarrow(w: 40pt, label: "TCP"),
  nodebox("AltairZ80", sub: "88-2SIO A: 10h  B: 12h", fill: amber-bg, bd: amber, w: 110pt),
  biarrow(w: 40pt, label: "TCP"),
  nodebox("socat", sub: "bridge", w: 56pt),
  biarrow(w: 46pt, label: "TCP 1985"),
  nodebox("fujinet-pc", sub: "RS-232 build, BoIP", fill: tip-bg, bd: rgb("#3f7d3f"), w: 90pt),
), caption: [The test rig. Both 88-2SIO ports listen on TCP; a bridge
connects port B to fujinet-pc's Bus-over-IP port.])

== F.1 fujinet-pc

Build fujinet-pc for the RS-232 target from the firmware tree, and give it a
configuration with Bus over IP turned on:

```
cd fujinet-firmware
./build.sh -p RS232            # or: cmake -DFUJINET_TARGET=RS232 ...
cd build/dist
cat >> fnconfig.ini <<EOF
[BOIP]
enabled=1
host=localhost
port=1985
EOF
./fujinet -c fnconfig.ini -s SD -u http://127.0.0.1:8000
```

== F.2 The simulator

AltairZ80 is part of SIMH (`BIN/altairz80` after building). Its 88-2SIO is
two devices, `M2SIO0` (port A, `10h`) and `M2SIO1` (port B, `12h`), disabled
until asked for. The script used for this book:

#codepanel("sim/altair.ini", read("sim/altair.ini"), size: 7.4pt)

Four details matter, each learned the hard way:

#step(1)[#strong[`deposit clock 2000`.] Left alone, AltairZ80 runs as fast
as the host computer can, and the program's timeouts --- counted in
instructions --- become microseconds. CLOCK sets the simulated speed in
kilohertz. (`SET THROTTLE` does not affect the Z80 timing here.)]

#step(2)[#strong[`set m2sio0 dtr`.] The 88-2SIO model passes modem signals
through, and a listening port does not accept a connection until the
simulated computer raises DTR. With `DTR`, DTR follows the 6850's RTS output,
which PINIT turns on.]

#step(3)[#strong[`notelnet`.] Without it, SIMH speaks TELNET on the port and
doubles every `FF` byte --- fatal to binary packets.]

#step(4)[#strong[Listen on both ports.] Making port B connect out to
fujinet-pc (`attach m2sio1 connect=...`) crashed the simulator build used
here, so both ports listen and `socat` makes the connection to fujinet-pc.]

== F.3 Running a program

`sim/run.sh` puts it all together: it starts the simulator on two fresh TCP
ports (SIMH cannot reuse a port still in TIME_WAIT from the last run),
bridges port B to fujinet-pc, and drives port A with `term.py`, which can
type a script of keys:

```
cd sim
./run.sh ../listings/hello/hello.bin
./run.sh ../listings/config/fncfg.bin --keys "{3}B1\r{2}1\r" --wait 5
FAULT=3 ./run.sh ../listings/config/fncfg.bin     # damage every 3rd reply
```

In `--keys`, `{n}` waits `n` seconds and `\r` is Return. For an interactive
session, run the simulator by hand and connect to port A with
`nc localhost <port>`.

== F.4 On real hardware

On a real Altair the same binaries run unchanged at `0100h`. Strap 88-2SIO
port B for the baud rate in `fnconfig.ini` (9600 in the example of Chapter
3), connect it to the FujiNet with a straight-through cable --- or a
null-modem adapter if the board is wired as DCE --- and load the program
with your usual monitor or from CP/M. If the CPU runs at 4 MHz, double
`FNTMO` and `DLY10MS` in ALTAIR.INC first.

// ============================================================
// APPENDIX G: FIRMWARE BEHAVIOUR AND ERRATA
// ============================================================
#chapter[Firmware Behaviour and Errata]

These are the places where the RS-232 firmware, at commit `670b2ed55`, does
something a programmer would not expect from the command's name or from the
rest of the protocol. Each was confirmed on a running adapter. The source
references are to `fujinet-firmware`.

#btable(columns: (auto, 1fr),
  table.header[Command][Behaviour and source],
  [any], [A command missing a parameter its handler reads throws an uncaught
   exception: fujinet-pc aborts, the hardware restarts. \
   #text(size: 7.4pt, fill: slate)[`lib/bus/rs232/FujiBusPacket.h:76`]],
  [any], [A bad checksum, a wrong length or a stalled frame gets no reply at
   all, not a NAK. \
   #text(size: 7.4pt, fill: slate)[`lib/bus/rs232/rs232.cpp:114`]],
  [any], [A frame opened with two ENDs is lost: the empty frame is
   discarded and the real one handed to the modem as stray bytes. \
   #text(size: 7.4pt, fill: slate)[`lib/bus/rs232/rs232.cpp:107`]],
  [any], [A short fixed-size payload is accepted, leaving the rest of the
   buffer uninitialised (some builds reject it instead). \
   #text(size: 7.4pt, fill: slate)[`lib/bus/rs232/rs232.cpp:78`]],
  [unknown device], [Answered with a NAK whose device byte is `00`.],
  [Fuji `FF` RESET], [Restarts without an ACK; the ACK-then-restart routine
   is unreachable. \
   #text(size: 7.4pt, fill: slate)[`lib/device/fujiDevice/fujiDevice.cpp:55`]],
  [Fuji `FE` GET_SSID], [Returns the stored WiFi password. \
   #text(size: 7.4pt, fill: slate)[`lib/device/fujiDevice/fujiDevice.cpp:438`]],
  [Fuji `FB` SET_SSID], [A failed join sends two NAKs. \
   #text(size: 7.4pt, fill: slate)[`lib/device/fujiDevice/fujiDevice.cpp:555`]],
  [Fuji `F2` / `F1`], [READ_DEVICE_SLOTS returns file names without their
   directories; writing them back with WRITE_DEVICE_SLOTS loses the paths. \
   #text(size: 7.4pt, fill: slate)[`lib/device/fujiDevice/fujiDevice.cpp:1575`, `:1613`]],
  [Fuji `E7` NEW_DISK], [Always NAKs (image creation not implemented), after
   creating or truncating the file and changing the slot. \
   #text(size: 7.4pt, fill: slate)[`lib/media/rs232/diskTypeImg.cpp:167`]],
  [Fuji `E0` GET_HOST_PREFIX], [Returns leftover memory after the prefix,
   and entirely when no prefix was ever set. \
   #text(size: 7.4pt, fill: slate)[`lib/device/fujiDevice/fujiDevice.cpp:1393`]],
  [Fuji `E6` UNMOUNT_HOST], [NAK for the SD card host on fujinet-pc. \
   #text(size: 7.4pt, fill: slate)[`lib/device/fujiDevice/fujiDevice.cpp:1563`]],
  [Fuji `53` STATUS], [Always four zero bytes; the RS-232 mount-time status
   routine is shadowed by the shared handler. \
   #text(size: 7.4pt, fill: slate)[`lib/device/rs232/rs232Fuji.cpp:61`]],
  [Fuji `DD` READ_APPKEY], [Answers ACK with 64 zero bytes on any failure. \
   #text(size: 7.4pt, fill: slate)[`lib/device/fujiDevice/AppKeyMixin.cpp:83`]],
  [Fuji `CE` B64 ENCODE_LENGTH], [Counts a trailing NUL. \
   #text(size: 7.4pt, fill: slate)[`lib/device/fujiDevice/Base64Mixin.cpp:45`]],
  [Disk `53` STATUS], [Wired to WRITE. \
   #text(size: 7.4pt, fill: slate)[`lib/device/rs232/disk.cpp:386`]],
  [Disk `21` FORMAT], [Returns a 128-byte Atari bad-sector list and leaves
   the image alone. \
   #text(size: 7.4pt, fill: slate)[`lib/media/rs232/diskTypeImg.cpp`]],
  [Disk mount of a ROM], [Pushes the ROM to device `FF` and waits for
   replies that an ordinary computer never sends. \
   #text(size: 7.4pt, fill: slate)[`lib/device/rs232/disk.cpp:313`]],
  [Network `53` STATUS], [For HTTP the connected byte is 0 throughout; for
   UDP on fujinet-pc the waiting count stays 0. \
   #text(size: 7.4pt, fill: slate)[`lib/network-protocol/UDP.cpp:166`]],
  [Network `63` CLOSE_CLIENT], [Answer inverted: NAK after a disconnect,
   ACK when there was no client. \
   #text(size: 7.4pt, fill: slate)[`lib/network-protocol/TCP.cpp:337`]],
  [Network `72` GET_REMOTE], [Text ends with `9B`, not NUL; the rest of the
   256 bytes is leftover memory. \
   #text(size: 7.4pt, fill: slate)[`lib/network-protocol/UDP.cpp:230`]],
  [Network `44` SET_DESTINATION], [Needs a prefix before the host and a
   terminating NUL. \
   #text(size: 7.4pt, fill: slate)[`lib/network-protocol/UDP.cpp:199`]],
  [Network `26` TELL], [Leftover memory on a unit that is not open. \
   #text(size: 7.4pt, fill: slate)[`lib/device/NDevice/NDevice.cpp:697`]],
  [Clock `54`], [Named SETTZ_ALT2, but a read on RS-232. \
   #text(size: 7.4pt, fill: slate)[`lib/device/fujiClock/fujiClock.cpp:385`]],
  [Clock `99` / `74`], [ACK before validation; a bad zone is ignored
   silently. \
   #text(size: 7.4pt, fill: slate)[`lib/device/fujiClock/fujiClock.cpp:319`]],
  [Printer `57` WRITE], [More than 255 bytes is cut short; more than 320
   overruns the buffer. \
   #text(size: 7.4pt, fill: slate)[`lib/device/rs232/printer.cpp:46`]],
  [Printer `53` STATUS], [Byte 1 is never set. \
   #text(size: 7.4pt, fill: slate)[`lib/device/rs232/printer.cpp:96`]],
  [Modem], [Replies are never framed; immediate AT responses are
   suppressed. \
   #text(size: 7.4pt, fill: slate)[`lib/bus/rs232/rs232.cpp:376`, `lib/device/rs232/modem.cpp:105`]],
  [Modem `ATCPM`], [Dereferences the absent CP/M device and crashes. \
   #text(size: 7.4pt, fill: slate)[`lib/device/rs232/modem.cpp:1254`]],
  [Modem `AT+TERM`], [`ANSI` and `DUMB` are swapped. \
   #text(size: 7.4pt, fill: slate)[`lib/device/rs232/modem.cpp:1023`]],
  [CP/M `5A`], [Never added to the bus. \
   #text(size: 7.4pt, fill: slate)[`src/main.cpp:364`]],
  [`[PrinterN]`], [Every printer section loads into slot 0. \
   #text(size: 7.4pt, fill: slate)[`lib/config/fnc_util.cpp:47`]],
  [`[Tape1]`], [Loads into the disk-slot table. \
   #text(size: 7.4pt, fill: slate)[`lib/config/fnc_mounts.cpp:156`]],
  [`[Serial] proceed`], [Not written back on the RS-232 build of
   fujinet-pc. \
   #text(size: 7.4pt, fill: slate)[`lib/config/fnc_save.cpp:218`]],
  [RTS/CTS], [Flow control requested but the pins are not routed to the
   UART. \
   #text(size: 7.4pt, fill: slate)[`lib/hardware/ESP32UARTChannel.cpp:57`]],
)
