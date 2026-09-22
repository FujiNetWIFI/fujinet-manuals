// ============================================================
// FUJINET PROGRAMMER'S HANDBOOK
// FOR THE TRS-80 COLOR COMPUTER
//
// The companion volume to the Getting Started manual, and cut
// from the same cloth: the 1980 Radio Shack "TRS-80 Color
// Computer Operation Manual" landscape booklet, Century
// Schoolbook text, double-rule chapter heads with the green
// centre ornament, pale-yellow caution panels, green gradient
// end bars, black-pill keycaps and the genuine MC6847
// character set for anything the screen would show.
//
// Where that book stops this one starts, so the preamble
// carries a programmer's furniture as well: command reference
// cards, side-by-side 6809/C example panels, byte-field
// diagrams, and listings read straight off disk from
// listings/ so that nothing printed here can drift from
// something that builds.
//
// Every opcode, command byte, parameter and reply length is
// transcribed from the FujiNet sources:
//   lib/bus/drivewire/{drivewire.cpp,opcode.h,FujiDWPacket.cpp}
//   lib/device/fujiDevice/{fujiDevice.cpp,*Mixin.h}
//   lib/device/drivewire/{drivewireFuji,disk,cpm,printer}.cpp
//   lib/device/NDevice/NDevice.cpp
//   lib/device/fujiClock/fujiClock.cpp
//   include/{fujiCommandID.h,fujiDeviceID.h}
//   lib/network-protocol/status_error_codes.h
// and cross-checked against the fujinet-lib Color Computer
// port, whose structs fix the byte layout of every frame it
// sends.  See README.md for the commits.
//
// Build: typst compile --font-path fonts manual.typ
// ============================================================

// ---------- fonts -------------------------------------------
#let f-body  = "C059"                  // URW Century Schoolbook — body
#let f-head  = "Century Schoolbook"    // Monotype bold — display heads
#let f-sans  = "Helvetica"             // keycaps, index headers, labels
#let f-cover = "Souvenir"              // the soft-serif cover lettering
#let f-scrn  = "Hot CoCo"              // genuine MC6847 VDG charset

// ---------- palette -----------------------------------------
#let ink     = rgb("#231f1c")          // letterpress near-black
#let paper   = rgb("#fbfaf6")          // warm white stock
#let note-bg = rgb("#f5f2bf")          // the pale yellow caution panel
#let grn-d   = rgb("#4e8c2f")          // ornament green, dark
#let grn-m   = rgb("#79b347")          // gradient bar middle
#let grn-l   = rgb("#cfe3a8")          // gradient bar light
#let rule-c  = rgb("#5a5a52")          // hairline rules
#let cvr-blu = rgb("#7aaedd")          // cover blue
#let cvr-mag = rgb("#d5418e")          // cover magenta

// VDG screen colors (tuned to a well-adjusted color TV)
#let vg = (
  g: rgb("#36a93b"),   // green
  y: rgb("#c9c93e"),   // yellow
  b: rgb("#23239b"),   // blue
  r: rgb("#9b2832"),   // red
  w: rgb("#e9e7df"),   // buff
  c: rgb("#3aa89c"),   // cyan
  m: rgb("#c4499f"),   // magenta
  o: rgb("#d06a26"),   // orange
  k: rgb("#0d0d0d"),   // black
)

// ---------- helpers ------------------------------------------
#let rp(s, n) = range(n).map(_ => s).join("")

// index + toc marks
#let chmark(title, subs) = metadata((kind: "chapter", title: title, subs: subs))
#let ix(..terms) = terms.pos().map(t => metadata((kind: "ix", term: t))).join()

// ---------- page foot: folio at the outer corner -------------
#let fst = state("folio", false)
#let foot = context {
  if not fst.get() { return }
  let p = counter(page).get().first()
  let folio = text(font: f-body, size: 9pt, fill: ink, str(p))
  if calc.even(p) {
    align(left + horizon, folio)
  } else {
    align(right + horizon, folio)
  }
}

// ---------- the Tandy double rule with center ornament -------
#let orn-rule = block(width: 100%, height: 9pt, {
  place(horizon, dy: -1.6pt, line(length: 100%, stroke: 0.7pt + rule-c))
  place(horizon, dy: 1.6pt, line(length: 100%, stroke: 0.7pt + rule-c))
  // the green pod with its darts
  place(center + horizon, box(width: 64pt, height: 9pt, fill: paper, {
    place(center + horizon, ellipse(width: 22pt, height: 7pt,
      fill: gradient.linear(grn-m, grn-d), stroke: 0.5pt + grn-d))
    place(horizon + left, dx: 6pt,
      polygon(fill: grn-d, (0pt, 2.6pt), (9pt, 0pt), (9pt, 5.2pt)))
    place(horizon + right, dx: -6pt,
      polygon(fill: grn-d, (0pt, 0pt), (0pt, 5.2pt), (9pt, 2.6pt)))
  }))
})

// ---------- chapter opener ------------------------------------
#let chapter(title, subs: (), toc: true) = {
  pagebreak(weak: true)
  if toc { chmark(title, subs) }
  v(0.25in)
  orn-rule
  v(10pt)
  align(center, text(font: f-head, weight: 700, size: 23pt,
    tracking: 0.8pt, fill: ink, upper(title)))
  v(8pt)
  orn-rule
  v(0.28in)
}

// ---------- section + sub-section heads -----------------------
#let sect(title) = block(above: 1.5em, below: 0.8em, breakable: false,
  text(font: f-head, weight: 700, size: 13pt, fill: ink, title))
#let subsect(title) = block(above: 1.3em, below: 0.6em, breakable: false,
  text(font: f-head, weight: 700, size: 10pt, fill: ink, title))

// ---------- the pale-yellow caution panel ---------------------
#let ybox(body, title: none) = block(above: 1.1em, below: 1.1em,
  breakable: false, width: 100%, fill: note-bg, inset: (x: 12pt, y: 9pt), {
    set par(justify: true, first-line-indent: 0pt)
    if title != none {
      align(center, text(font: f-head, weight: 700, size: 9.6pt, title))
      v(5pt)
    }
    text(weight: 700, size: 9.4pt, body)
  })

// ---------- green gradient end bar ----------------------------
#let gbar = block(width: 100%, above: 1.4em, below: 0.6em, align(right,
  box(width: 58%, stack(dir: ttb,
    rect(width: 100%, height: 3.4pt,
      fill: gradient.linear(paper, grn-l, angle: 0deg)),
    rect(width: 100%, height: 3.4pt,
      fill: gradient.linear(grn-l, grn-m, angle: 0deg)),
    rect(width: 100%, height: 3.4pt,
      fill: gradient.linear(grn-m, grn-d, angle: 0deg))))))

// ---------- keycaps: the black pill ---------------------------
#let key(l) = box(baseline: 22%, rect(fill: ink, radius: 4.5pt,
  inset: (x: 4pt, y: 2.2pt),
  text(font: f-sans, weight: 700, size: 6.4pt, fill: white, upper(l))))
// arrow keycaps use the genuine VDG arrow glyphs, like the CoCo keyboard
#let karr(s) = box(baseline: 22%, rect(fill: ink, radius: 4.5pt,
  inset: (x: 3.4pt, y: 1.8pt),
  text(font: f-scrn, size: 6.8pt, fill: white, s)))
#let key-up    = karr("\u{2191}")
#let key-down  = karr("\u{2193}")
#let key-left  = karr("\u{2190}")
#let key-right = karr("\u{2192}")
// the case's counterclockwise reset-arrow marking, drawn inline
#let rsym = box(width: 9pt, height: 8pt, baseline: 15%, {
  place(center + horizon, dy: 0.6pt, circle(radius: 3pt, stroke: 1.15pt + ink))
  place(top + left, rect(width: 4.4pt, height: 2.4pt, fill: paper))
  place(top + left, dx: 3.2pt, dy: -0.4pt,
    polygon(fill: ink, (3.4pt, 1.5pt), (0pt, 0pt), (0pt, 3pt)))
})

// ---------- "what you type" — the VDG face in print ink -------
#let tt(s) = text(font: f-scrn, size: 7.6pt, fill: ink, s)

// ---------- bullets -------------------------------------------
#let bl(body) = block(above: 0.45em, below: 0.45em,
  grid(columns: (0.16in, 1fr),
    align(left, move(dy: 2.2pt, circle(radius: 1.9pt, fill: ink))),
    par(leading: 0.5em, first-line-indent: 0pt, justify: true, body)))

// ---------- figures & photographs -----------------------------
#let figcap(num, title) = block(above: 0.55em, below: 1.1em,
  par(leading: 0.45em, first-line-indent: 0pt, justify: false,
    text(font: f-head, weight: 700, size: 9.2pt)[Figure #num. #title]))

#let fig(num, title, body) = block(breakable: false, above: 1.2em, below: 0.6em, {
  body
  figcap(num, title)
})

// ============================================================
// THE TELEVISION — 32x16 VDG screens, drawn cell-exact
// ============================================================
#let scrsz = 8.1pt
#let CW = scrsz * 2 / 3       // the MC6847 cell is 8x12 dots
#let CH = scrsz

// segments: N normal (black on green), I inverse (green on black),
// FB filler block of n cells in color c
#let N(s) = (txt: s, bg: vg.g, fg: vg.k)
#let I(s) = (txt: s, bg: vg.k, fg: vg.g)
#let FB(n, c) = (txt: none, n: n, bg: c)

#let vrow(..segs) = stack(dir: ltr, ..segs.pos().map(s => {
  let w = if s.txt == none { s.n * CW } else { s.txt.clusters().len() * CW }
  box(width: w, height: CH, fill: s.bg, clip: false,
    if s.txt != none {
      align(left + horizon, text(font: f-scrn, size: scrsz, fill: s.fg, s.txt))
    })
}))

// a full row of one color (unprinted CLS fill)
#let FR(c) = box(width: 32 * CW, height: CH, fill: c)

// the semigraphic "shadow" row: SG4 byte c|0x03 across, c|0x0B first
#let SH(c) = box(width: 32 * CW, height: CH, fill: vg.k, {
  place(bottom + left, rect(width: 32 * CW, height: CH / 2, fill: c))
  place(top + left, rect(width: CW / 2, height: CH / 2, fill: c))
})

// the set: black bezel (the VDG alphanumeric border) around 32x16
#let tv(..rows) = align(center, block(breakable: false, above: 1.1em, below: 0.7em,
  box(fill: vg.k, inset: (x: 0.3in, y: 0.22in), radius: 3pt,
    stack(dir: ttb, ..rows.pos()))))

// VDG arrows (Hot CoCo PUA: 6847 codes 0x1E up, 0x1F left)
#let vup = "\u{E05E}"
#let vleft = "\u{E05F}"

// ============================================================
// THE PROGRAMMER'S FURNITURE
//
// Everything above this line is the Getting Started manual's
// preamble, carried over unchanged so the two books match.
// Everything below it is what a reference needs and a
// getting-started guide does not.
// ============================================================

// ---------- the monospace face --------------------------------
// Hot CoCo is the MC6847 character set and has no lowercase, so
// it stays where the other book put it: what you type, and what
// the screen shows.  Program listings need a real monospace.
#let f-mono  = "Source Code Pro"

#let code-bg = rgb("#f2efe4")          // listing panel, warm
#let code-bd = rgb("#cfc9b6")          // its hairline
#let slate   = rgb("#46586a")          // the second language
#let dim     = rgb("#7a7568")          // line numbers, labels

// ---------- a code word in running prose ----------------------
#let cw(s) = text(font: f-mono, size: 8.1pt, fill: ink, s)

// ---------- a hexadecimal byte --------------------------------
// Typst reads a bare dollar sign as the start of a formula, and
// this book is made of dollar signs.  #hx("E2") writes $E2.
#let hx(v) = text(font: f-mono, size: 8.1pt, fill: ink, "$" + v)

// ---------- a centred devicespec ------------------------------
#let spec(s) = align(center, block(above: 0.7em, below: 0.7em,
  text(font: f-mono, size: 8.4pt, fill: ink, s)))

// ---------- numbered steps ------------------------------------
#let step(n, body) = block(above: 0.5em, below: 0.5em,
  grid(columns: (0.24in, 1fr), column-gutter: 4pt,
    align(right, text(font: f-head, weight: 700, size: 9.3pt, fill: grn-d,
      str(n) + ".")),
    par(leading: 0.5em, first-line-indent: 0pt, justify: true, body)))

// ---------- one code panel ------------------------------------
// Blank lines survive as spaces so that a listing's shape does.
#let cpanel(title, body, size: 7.4pt, accent: grn-d) = block(
  fill: code-bg, inset: (x: 8pt, y: 6pt), width: 100%,
  stroke: (left: 2.5pt + accent, rest: 0.6pt + code-bd), {
    set par(justify: false, leading: 0.48em, first-line-indent: 0pt)
    text(font: f-sans, weight: 700, size: 6.4pt, fill: accent,
      tracking: 0.5pt, upper(title))
    v(3pt)
    text(font: f-mono, size: size, fill: ink,
      body.split("\n").map(l => if l == "" { " " } else { l })
        .join(linebreak()))
  })

// ---------- the two languages, side by side -------------------
#let pair(asm-txt, c-txt, size: 7.4pt) = block(above: 0.8em, below: 0.9em,
  breakable: false, width: 100%,
  grid(columns: (1fr, 1fr), column-gutter: 9pt,
    cpanel("6809 assembler", asm-txt, size: size, accent: grn-d),
    cpanel("cmoc c", c-txt, size: size, accent: slate)))

// ---------- the two languages, one above the other ------------
// Inside the two-column narrative chapters a side-by-side pair
// would be 1.9in wide and wrap every line.  Stacked, each panel
// gets the full column: about 65 characters at 7.4pt.
#let vpair(asm-txt, c-txt, size: 7.4pt) = block(above: 0.8em, below: 0.9em,
  breakable: false, width: 100%, {
    cpanel("6809 assembler", asm-txt, size: size, accent: grn-d)
    v(4pt)
    cpanel("cmoc c", c-txt, size: size, accent: slate)
  })

// ---------- one language on its own ---------------------------
#let asmbox(t, size: 7.4pt) = block(above: 0.8em, below: 0.9em,
  breakable: false, cpanel("6809 assembler", t, size: size, accent: grn-d))
#let cbox(t, size: 7.4pt) = block(above: 0.8em, below: 0.9em,
  breakable: false, cpanel("cmoc c", t, size: size, accent: slate))
#let basbox(t, size: 7.4pt) = block(above: 0.8em, below: 0.9em,
  breakable: false, cpanel("extended color basic", t, size: size,
    accent: rgb("#8a6d2f")))
#let shbox(t, size: 7.4pt) = block(above: 0.8em, below: 0.9em,
  breakable: false, cpanel("at the prompt", t, size: size, accent: dim))

// ---------- the command reference card ------------------------
#let cmdlab(s) = text(font: f-sans, weight: 700, size: 6.6pt, fill: dim,
  tracking: 0.5pt, upper(s))

#let cmd(name, code: "", dev: "", aux: "none", payload: "none",
         reply: "none", lib: none, asm: none, c: none, body) = block(
  width: 100%, above: 1.2em, below: 1.2em, breakable: true, {
  block(breakable: false, sticky: true, fill: code-bg,
    stroke: (left: 3pt + grn-d, rest: 0.6pt + code-bd),
    inset: (x: 11pt, y: 9pt), width: 100%, {
    grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
      text(font: f-head, weight: 700, size: 12pt, fill: grn-d, name),
      text(font: f-mono, weight: 700, size: 9.5pt, fill: ink, code))
    v(5pt)
    set par(leading: 0.5em, first-line-indent: 0pt, justify: false)
    grid(columns: (58pt, 1fr), row-gutter: 5pt, column-gutter: 8pt,
      cmdlab("frame"),   text(font: f-mono, size: 8pt, dev),
      cmdlab("aux"),     text(size: 8.6pt, aux),
      cmdlab("payload"), text(size: 8.6pt, payload),
      cmdlab("reply"),   text(size: 8.6pt, reply),
      ..if lib != none {
        (cmdlab("fujinet-lib"), text(size: 8.6pt, lib))
      } else { () },
    )
  })
  v(4pt)
  set par(first-line-indent: 0pt, justify: false)
  body
  if asm != none and c != none { pair(asm, c) }
  else if asm != none { asmbox(asm) }
  else if c != none { cbox(c) }
})

// ---------- a byte-by-byte frame diagram ----------------------
// Each field is (label, width-in-units). One unit is one byte
// unless the label says otherwise.
#let bytefield(..fields) = {
  let fs = fields.pos()
  let total = fs.fold(0, (a, f) => a + f.at(1))
  block(above: 1.0em, below: 1.0em, breakable: false, width: 100%,
    grid(columns: fs.map(f => f.at(1) * 1fr), column-gutter: 0pt,
      ..fs.map(f => block(width: 100%, height: 22pt, fill: code-bg,
        stroke: 0.6pt + code-bd,
        align(center + horizon,
          text(font: f-mono, size: 7.4pt, fill: ink, f.at(0)))))))
}

// ---------- SYMPTOM / REMEDY ----------------------------------
#let symrem(..rows) = {
  let cell(b) = {
    set par(leading: 0.5em, justify: false, first-line-indent: 0pt)
    set text(size: 8.8pt)
    b
  }
  table(columns: (1.9in, 1fr), stroke: 0.6pt + ink, inset: 6pt,
    table.header(
      text(font: f-head, weight: 700, size: 10pt)[Symptom],
      text(font: f-head, weight: 700, size: 10pt)[Remedy]),
    ..rows.pos().map(r => (cell(r.at(0)), cell(r.at(1)))).flatten())
}

// ---------- dot-leader definitions ----------------------------
#let dotdef(..rows) = block(above: 0.8em, below: 0.8em, {
  let lead = box(width: 1fr, inset: (bottom: 1.5pt),
    align(bottom, repeat(text(size: 7.5pt)[.#h(2.2pt)])))
  for r in rows.pos() {
    block(above: 0.4em, below: 0pt, {
      text(font: f-mono, size: 8.2pt, r.at(0))
      lead
      text(size: 9pt, r.at(1))
    })
  }
})

// ---------- a whole source file, read off the disk ------------
// Appendix C prints these.  Because the file is read at build
// time, a listing in this book cannot drift from one that
// builds.
#let code-listing(title, path, cols: auto, size: 6.4pt) = {
  let lines = read(path).split("\n")
  while lines.len() > 0 and lines.last().trim() == "" { lines.pop() }
  let w = str(lines.len()).len()
  let numbered = lines.enumerate().map(((i, l)) => {
    let n = str(i + 1)
    let gutter = rp(" ", w - n.len()) + n + "  "
    text(fill: dim, gutter) + text(fill: ink, if l == "" { " " } else { l })
  })
  block(breakable: true, above: 1.1em, below: 1.1em, {
    block(below: 0.5em, sticky: true, {
      text(font: f-head, weight: 700, size: 9.6pt, fill: ink, title)
      v(3pt)
      line(length: 100%, stroke: 0.9pt + grn-d)
    })
    set par(justify: false, leading: 0.42em, first-line-indent: 0pt)
    set text(font: f-mono, size: size)
    // A short file in two columns reads as a mistake; a long one in
    // one column wastes half the page.
    let c = if cols == auto { if lines.len() < 20 { 1 } else { 2 } } else { cols }
    if c == 1 {
      numbered.join(linebreak())
    } else {
      columns(c, gutter: 0.3in, numbered.join(linebreak()))
    }
  })
}

// ---------- appendix opener -----------------------------------
#let appendix(letter, title, subs: ()) = {
  pagebreak(weak: true)
  chmark("Appendix " + letter + ". " + title, subs)
  v(0.25in)
  orn-rule
  v(10pt)
  align(center, text(font: f-head, weight: 700, size: 15pt,
    tracking: 0.8pt, fill: grn-d, upper("Appendix " + letter)))
  v(4pt)
  align(center, text(font: f-head, weight: 700, size: 23pt,
    tracking: 0.8pt, fill: ink, upper(title)))
  v(8pt)
  orn-rule
  v(0.28in)
}

// ============================================================
// DOCUMENT SETUP
// ============================================================
#set document(title: "FujiNet Programmer's Handbook for the TRS-80 Color Computer",
  author: "The FujiNet Community")
#set text(font: f-body, size: 9.3pt, fill: ink, hyphenate: true)
#set par(leading: 0.5em, spacing: 0.65em, justify: true, first-line-indent: 0pt)
#set strong(delta: 300)
#set page(width: 10in, height: 8in, fill: paper,
  margin: (x: 0.72in, top: 0.55in, bottom: 0.62in),
  footer: foot, footer-descent: 38%)
#set enum(numbering: "1.", indent: 0pt, body-indent: 7pt, spacing: 0.7em)

// Widow, orphan and runt discipline.  A high cost pushes a
// stranded line's whole paragraph to the next column rather
// than leaving it alone at the foot of this one.
#set text(costs: (hyphenation: 220%, runt: 500%, widow: 900%, orphan: 900%))

#let cols2(body) = columns(2, gutter: 0.32in, body)

// ============================================================
// FRONT COVER
// ============================================================
#page(margin: 0pt, footer: none)[
  #place(image("images/starfield.png", width: 100%, height: 100%))
  #place(top + left, dx: 0.32in, dy: 0.32in,
    rect(width: 10in - 0.64in, height: 8in - 0.64in,
      stroke: 2.6pt + cvr-blu))
  #place(top + left, dx: 0.38in, dy: 0.38in,
    rect(width: 10in - 0.76in, height: 8in - 0.76in,
      stroke: 0.8pt + cvr-blu))

  #place(top + right, dx: -0.62in, dy: 0.52in,
    text(font: f-sans, size: 9pt, fill: cvr-blu)[Catalog No. FN-COCO-PROG-01])

  #place(top + left, dx: 0.85in, dy: 0.9in, {
    set par(leading: 0.35em, spacing: 0.5em)
    text(font: f-cover, weight: 700, size: 38pt, fill: cvr-blu)[FUJINET#h(2pt)#text(size: 14pt, baseline: -14pt)[®]]
    v(0.22in)
    text(font: f-cover, weight: 700, size: 46pt, fill: cvr-mag)[COLOR]
    v(0.1in)
    text(font: f-cover, weight: 700, size: 46pt, fill: cvr-mag)[COMPUTER]
    v(0.24in)
    text(font: f-cover, weight: 700, size: 31pt, fill: cvr-blu)[PROGRAMMER'S]
    v(0.08in)
    text(font: f-cover, weight: 700, size: 31pt, fill: cvr-blu)[HANDBOOK]
  })

  #place(top + left, dx: 0.9in, dy: 5.55in,
    text(font: f-sans, size: 9.5pt, fill: cvr-mag, tracking: 0.4pt)[
      EVERY COMMAND, IN C AND IN 6809])

  #place(top + right, dx: -0.5in, dy: 2.3in,
    image("images/cocofuji-hero.png", width: 4.15in))

  #place(bottom + center, dy: -0.55in,
    text(font: f-sans, size: 8pt, fill: cvr-blu, tracking: 0.6pt)[
      CUSTOM CRAFTED BY THE FUJINET COMMUNITY
      #h(4pt)#box(image("images/fujinet-logo.png", height: 11pt), baseline: 2.5pt)#h(4pt)
      A WORLDWIDE FREE-SOFTWARE PROJECT])
]

// ============================================================
// TITLE PAGE
// ============================================================
#counter(page).update(1)
#page(footer: none)[
  #v(1.0in)
  #align(center, {
    set par(leading: 0.4em)
    text(font: f-cover, weight: 700, size: 30pt,
      fill: paper, stroke: 0.6pt + rgb("#8a8578"))[FUJINET#h(2pt)#text(size: 12pt, baseline: -10pt)[®]]
    v(0.32in)
    text(font: f-cover, weight: 700, size: 36pt,
      fill: rgb("#f3eecb"), stroke: 0.7pt + rgb("#8a8578"))[COLOR COMPUTER]
    v(0.32in)
    text(font: f-cover, weight: 700, size: 30pt,
      fill: paper, stroke: 0.6pt + rgb("#8a8578"))[PROGRAMMER'S]
    v(0.32in)
    text(font: f-cover, weight: 700, size: 30pt,
      fill: paper, stroke: 0.6pt + rgb("#8a8578"))[HANDBOOK]
  })
  #v(1fr)
  #align(center, {
    image("images/fujinet-logo.png", width: 0.85in)
    v(4pt)
    text(font: f-sans, weight: 700, size: 8.5pt)[THE FUJINET COMMUNITY]
    linebreak()
    text(font: f-sans, size: 7.5pt)[A WORLDWIDE FREE-SOFTWARE PROJECT — FUJINET.ONLINE]
  })
  #v(0.4in)
]

// ============================================================
// WARNINGS + COPYRIGHT  (page 2)
// ============================================================
#counter(page).update(2)
#fst.update(true)

#v(0.35in)
#align(center, box(width: 5.4in,
  ybox(title: [WARNING])[Before inserting or removing the FujiNet — or any
  Program Pak#h(1pt)#super[TM] — be sure the Computer is OFF. Otherwise,
  the FujiNet or the Computer could be damaged.]))

#v(0.12in)
#align(center, box(width: 5.4in,
  ybox(title: [A WORD ABOUT THESE NUMBERS])[Every address, command byte,
  parameter and reply length in this book was read out of the FujiNet
  sources and checked against a client that speaks to them. Firmware
  moves. When this book and the sources disagree, the sources are right
  and this book has a bug; the back cover says where to report it.]))

#v(0.18in)
#align(center, box(width: 7.4in, {
  set text(size: 8.4pt)
  set par(leading: 0.5em, justify: true)
  grid(columns: (1fr, 1fr), column-gutter: 0.4in,
    [
      FujiNet Programmer's Handbook for the TRS-80#h(1pt)#super[®] Color
      Computer.\
      First edition.

      The FujiNet firmware, the fujinet-lib client library, and the example
      programs printed in this book are free software, published under the
      GNU General Public License. Copy them, change them, put them on a
      disk and give the disk away.

      TRS-80, Color Computer, Program Pak and Radio Shack are trademarks of
      Tandy Corporation, used here the way one speaks of an old friend.
      OS-9 is a trademark of Microware. Neither company had anything to do
      with this book and neither should be blamed for it.
    ],
    [
      The DriveWire protocol is Boisy Pitre's, and the Color Computer owes
      him a drink. The bit-banger routines this book leans on all evening
      are Darren Atkinson's. CMOC is Pierre Sarrazin's. LWTOOLS is William
      Astle's. None of this would run without them.

      Written by the FujiNet community for anyone who wants to put a
      Color Computer on the network and then write something that uses it.

      #v(4pt)
      #text(font: f-mono, size: 7.6pt)[10 9 8 7 6 5 4 3 2 1]
    ])
}))

// ============================================================
// TO OUR PROGRAMMERS
// ============================================================
#chapter("To Our Programmers")

#cols2[
At the simplest level of operation, you do not need this book at all. The
CONFIG program that comes up when you switch the Computer on will put a
disk in a drive for you, and every program you already own will load from
it and never know the difference. The Getting Started manual covers that,
and covers it well.

At a slightly more involved level, you have written something in Extended
Color BASIC and you would like it to fetch a score table, or the weather,
or a line of text from a friend's machine three time zones away. You will
want Chapters 1 through 5, and then Chapter 12 as a menu.

If, however, you already know what a devicespec is, and you have opened
this book to find out whether #cw("SET_DIRECTORY_POSITION") takes its
argument high byte first — it does — then start at Chapter 12 and use the
index. Everything in the reference chapters was transcribed from the
firmware and checked against a client that talks to it, and every card
carries the same command written twice: once in 6809 assembly and once in
C.

#sect[What is in here]

Chapters 1 through 5 are the short road to a working program. They cover
the tools, the two ROM vectors that carry everything, the shape of a
FujiNet command, and a first program that asks the adapter who it is.

Chapters 6 through 11 are the libraries and the environments: a 6809
assembler library you can lift wholesale, the C side using fujinet-lib,
the two devices you will spend all your time with, and what changes when
you leave Disk BASIC for OS-9.

Chapters 12 through 15 are the reference. Every command the Color
Computer can send is in there, one card each, with its frame laid out
byte by byte and an example in both languages. The commands that are
*not* answered are named too, at the end of each chapter, so that you
can tell a command that does nothing from one you spelled wrong.

Chapters 16 through 19 are four complete programs, and Appendix C prints
them in full. They are not sketches. They compile with the tools in
Chapter 2 and the listings in this book are read off the same files at
the moment the book is typeset, so a listing here cannot drift from one
that builds.

#sect[What is not]

This book documents the *bus*: how to get a command to the adapter and an
answer back. It does not document what lives at the far end of a URL. The
schemes the #cw("N:") device speaks — #cw("TCP:"), #cw("HTTP:"),
#cw("TNFS:"), #cw("JSON:"), #cw("SSH:"), #cw("SMB:") and the rest — have a
book of their own, the *FujiNet Network Protocol Handbook*, and Chapter 20
says where to find it.

It also assumes you can already write 6809 assembly or C for the Color
Computer. There are good books on both and this is not trying to be one
of them.

#v(4pt)
#gbar
]

// ============================================================
// CONTENTS
// ============================================================
#pagebreak(weak: true)
#v(0.2in)
#align(center, text(font: f-head, weight: 700, size: 24pt)[CONTENTS])
#v(0.25in)

#let dots = box(width: 1fr, inset: (bottom: 1.5pt),
  align(bottom, repeat(text(size: 8pt)[.#h(2.6pt)])))
#let sq = box(baseline: -0.5pt, square(size: 5pt, stroke: 0.7pt + ink))

#context {
  let marks = query(metadata).filter(m =>
    type(m.value) == dictionary and m.value.at("kind", default: "") == "chapter")
  let entry(m) = {
    let p = counter(page).at(m.location()).first()
    block(above: 0.62em, below: 0.16em, breakable: false, {
      text(font: f-head, weight: 700, size: 9.6pt, m.value.title)
      dots
      text(font: f-head, weight: 700, size: 9.6pt, str(p))
    })
    if m.value.subs.len() > 0 {
      block(above: 0pt, below: 0.28em, inset: (left: 0.16in, right: 0.16in),
        par(leading: 0.5em, justify: false,
          text(size: 8pt, m.value.subs.join(h(4pt) + sq + h(4pt)))))
    }
  }
  // split so the two columns hold about the same number of lines
  let weight(m) = 1 + m.value.subs.len() / 3
  let total = marks.fold(0.0, (a, m) => a + weight(m))
  let run = 0.0
  let cut = marks.len()
  for (i, m) in marks.enumerate() {
    run = run + weight(m)
    if run >= total / 2 and cut == marks.len() { cut = i + 1 }
  }
  align(center, block(width: 7.9in,
    grid(columns: (1fr, 1fr), column-gutter: 0.42in,
      { for m in marks.slice(0, cut) { entry(m) } },
      { for m in marks.slice(cut) { entry(m) } })))
}

// ============================================================
// 1. WELCOME TO FUJINET
// ============================================================
#chapter("1. Welcome to FujiNet",
  subs: ("What is on the other end", "The devices", "What it is not"))
#ix("FujiNet cartridge", "Devices, the list of", "DriveWire protocol")

#cols2[
The FujiNet is an ESP32 with a WiFi radio, a microSD slot and a serial
cable, in a case that sits beside your Color Computer. The cable goes to
the four-pin DIN on the back of the Computer — the one Radio Shack meant
for a printer — and from the Computer's point of view what is on the
other end is a DriveWire server.

That is the whole trick, and it is worth sitting with for a moment. Disk
BASIC already knows how to talk to a DriveWire server: HDB-DOS is in the
cartridge, the ROM routines are in memory, and #tt("DIR") works. You did
not have to teach the Computer anything. The FujiNet simply answers, and
because it is answering over a protocol that already had room in it, the
FujiNet's own commands ride along in the same conversation.

#sect[What is on the other end]

A DriveWire server answers an opcode byte and then reads or writes
however many bytes that opcode implies. The published opcodes cover
disks, printing, the clock and a set of virtual serial channels. FujiNet
answers all of those, and then answers four more of its own:

#dotdef(
  (hx("E2"), [the FujiNet control device — slots, hosts, WiFi, app keys]),
  (hx("E3"), [the #cw("N:") network devices — one channel each]),
  (hx("E4"), [the CP/M console]),
  (hx("E5"), [the clock]),
)

Everything in Chapters 12 and 13 — every host slot, every mounted image,
every socket you open — goes out as one of those two bytes followed by a
command byte. There is no handshake to negotiate, no device to enumerate,
and nothing to install. You write #hx("E2") and the adapter is listening.

#sect[The devices]

#subsect[Disk]

Four drive slots, numbered 0 to 3. The Color Computer gets four where the
Atari gets eight, because #cw("MAX_DWDISK_DEVICES") is four. Mount an
image into a slot and it answers #cw("OP_READEX") and #cw("OP_WRITE") as
a 256-byte-block device — which is exactly what HDB-DOS expects, so
#tt("DRIVE #0") through #tt("DRIVE #3") work with no further ceremony.
Chapter 14 documents the block protocol, checksum and all.

#subsect[The FujiNet control device]

Device #hx("E2"). Sixty-odd commands: join a network, read and write the
eight host slots and the four drive slots, walk a host's directory, mount
and unmount, copy a file between hosts, keep a small blob of application
state in an app key, and — because the adapter has a processor and you do
not — compute a SHA-256, encode base64, or render a QR code.

#subsect[The network device]

Device #hx("E3"), and the one you will spend your time with. Open a
devicespec like

#spec("N:TCP://fujinet.online:6502/")

and you have a socket. Twenty-nine commands hang off it: the five that
matter (open, close, read, write, status) and twenty-four more for
seeking, locking, making directories, accepting inbound connections and
running a JSON, HTML or XML parser over whatever came back so that the
Computer never has to hold the whole document.

#subsect[The clock, the printer, CP/M]

The clock will give you the time in seven formats, one of which is a
six-byte reply to a single opcode with no command byte at all. The
printer takes one byte per call and emulates a shelf full of hardware
that has not been made in forty years. CP/M is a Z80 emulator with a
console on the wire, and it is the only device in this book that is not
available on every build.

#sect[What it is not]

The FujiNet is not a modem, not a terminal program, and not a filesystem.
It is a way to move bytes, and every interesting thing on the other side
of those bytes is somebody else's protocol. This book stops at the point
where your bytes leave the Computer.

One more honest note before we start. The adapter's own AT-command modem
is implemented in the firmware and is *not* reachable on this bus: nothing
constructs it for the Color Computer build. Chapter 14 says so again, in
its place, because a command reference that quietly omits the dead ends is
not a reference.

#v(4pt)
#gbar
]

// ============================================================
// 2. INSTALLING THE TOOLS
// ============================================================
#chapter("2. Installing the Tools",
  subs: ("CMOC", "LWTOOLS", "Toolshed", "fujinet-lib", "A place to put it"))
#ix("CMOC", "LWTOOLS", "lwasm", "Toolshed", "fujinet-lib", "Tools, installing")

#cols2[
Everything in this book is built with two compilers and one disk tool,
all three of them free, all three of them running on the machine you are
reading this on rather than on the Color Computer. Cross-development is
not cheating. The CoCo has 32K and no editor worth the name; your other
computer has a screen you can see.

#sect[CMOC]

CMOC is Pierre Sarrazin's C compiler for the 6809. It targets Disk
Extended Color BASIC by default, which is what we want: it emits a
#tt(".BIN") file you load with #tt("LOADM") and start with #tt("EXEC").
It also targets OS-9, which Chapter 11 needs.

#shbox("$ cmoc --version
cmoc (cmoc 0.1.100)")

Debian and Ubuntu have it as #cw("cmoc")\; Arch has it in the AUR;
otherwise build it from source. It wants a C preprocessor (it uses the
system #cw("cpp")) and it wants LWTOOLS, below, because it assembles and
links with them.

#sect[LWTOOLS]

William Astle's LWTOOLS is the 6809 assembler, linker and librarian:
#cw("lwasm"), #cw("lwlink"), #cw("lwar"). Every assembly listing in this
book assembles with #cw("lwasm"), and CMOC calls it for you on the C
side.

#shbox("$ lwasm --version
lwasm from lwtools 4.24")

The two flags that matter here are #cw("--6809"), because the Color
Computer is a 6809 and not a 6309, and #cw("--format=decb"), which writes
the loader blocks #tt("LOADM") expects.

#shbox("$ lwasm --6809 --format=decb \\
      -o NETCAT.BIN netcat.asm")

#sect[Toolshed]

Toolshed gives you #cw("decb"), which makes and fills Disk BASIC disk
images, and #cw("os9"), which does the same for OS-9. You need it to get
a #tt(".BIN") onto something the Computer can read.

#shbox("$ decb dskini NETCAT.DSK
$ decb copy -2b NETCAT.BIN NETCAT.DSK,NETCAT.BIN")

Put the resulting image somewhere your FujiNet can reach — the microSD
card, or a TNFS share — mount it into a drive slot, and #tt("LOADM") it.
Chapter 17 writes a program that does the mounting for you.

#ybox(title: [A SHORTER LOOP])[If you are running FujiNet-PC rather than
hardware, or if you keep a TNFS server on the same machine you compile on,
you can copy the built #tt(".DSK") straight into the served directory and
re-mount it from CONFIG. Edit, make, re-mount, #tt("LOADM"). It is about
fifteen seconds.]

#colbreak()

#sect[fujinet-lib]

fujinet-lib is the C client library, and it has a Color Computer port
built with CMOC. A release unpacks flat: the three headers, three
assembler include files, and one library.

#shbox("fujinet-fuji.h     fujinet-fuji.inc
fujinet-network.h  fujinet-network.inc
fujinet-clock.h    fujinet-clock.inc
fujinet-coco-4.7.9.lib")

Point CMOC at the directory with #cw("-I") and hand it the library on the
link line. Some installations symlink the library to
#cw("libfujinet.a") in CMOC's own library directory, in which case
#cw("-lfujinet") finds it:

#shbox("$ cmoc -Ifujinet -o WEATHER.BIN \\
      weather.c fujinet/fujinet-coco-4.7.9.lib

$ cmoc -Ifujinet -o WEATHER.BIN \\
      weather.c -lfujinet")

The library covers most of the FujiNet control device and the five moves
of the network device. It does not cover everything, and Chapters 12 and
13 say so command by command: each card names the fujinet-lib call when
there is one, and shows the raw frame when there is not. Chapter 7 shows
how to drop below the library without leaving it.

#sect[The assembler side]

There is no equivalent library shipped for assembly, so this book brings
one. Chapter 6 develops it and Appendix C prints it:

#dotdef(
  ("fn.inc", [every opcode, command byte, mode and error code as an #cw("EQU")]),
  ("fnlow.asm", [nine subroutines: the handshake, the verdict, the response]),
  ("fnnet.asm", [the five moves of the #cw("N:") device]),
  ("cocoio.asm", [screen and keyboard, so the examples can say something]),
)

Put them in a directory and point #cw("lwasm") at it with #cw("-I"). They
assume nothing about where your program lives and allocate nothing but
their own frames.

#sect[A place to put it]

The layout the listings in this book use:

#shbox("listings/
  common.mk        the shared flags
  fnlib/           fn.inc, fnlow.asm, ...
  netcat/          netcat.asm, netcat.c
  mounter/  weather/  os9/")

and #cw("common.mk") holds the one thing that varies between machines:

#shbox("FNDIR ?= /usr/share/cmoc/include
CFLAGS := -I$(FNDIR)
ASFLAGS := --6809 --format=decb \\
           -I../fnlib")

#ybox(title: [NOTE])[The listings in this book are read off disk when the
book is typeset. If you are reading the PDF, the code you see in
Appendix C is the same text that produced the #tt(".BIN") files, character
for character. It cannot have drifted, because there is nowhere for it to
drift to.]

#v(4pt)
#gbar
]

// ============================================================
// 3. THE DRIVEWIRE CONNECTION
// ============================================================
#chapter("3. The DriveWire Connection",
  subs: ("Two vectors", "The calling convention", "Baud and the model switches",
         "Is anybody there?", "Why the vectors"))
#ix("DWRead", "DWWrite", "Vectors, DriveWire", "Baud rate", "Model switches (DIP)",
    "Bit-banger port")

#cols2[
Everything the Color Computer says to a FujiNet, and everything it hears
back, goes through two subroutines. They are already in memory. Disk
BASIC put them there.

#sect[Two vectors]

Disk BASIC keeps the DriveWire entry points in a pair of indirect
vectors near the top of the ROM:

#dotdef(
  (hx("D93F"), [#cw("DWRead") — the vector, not the routine]),
  (hx("D941"), [#cw("DWWrite")]),
)

They are vectors, so you call through them and not to them:

#asmbox("DWREADV EQU     $D93F
DWWRITV EQU     $D941

        ldx     #BUFFER
        ldy     #LENGTH
        jsr     [DWWRITV]")

On a Dragon the same two routines live at #hx("F9FE") and #hx("FA00").
fujinet-lib carries both and picks with a #cw("-DDRAGON") at build time;
so does this book's #cw("fn.inc").

#sect[The calling convention]

Both routines take the buffer in #cw("X") and the count in #cw("Y").
What they give back is where people trip.

#subsect[DWWrite]

Sends #cw("Y") bytes from #cw("X"). On return #cw("X") points one past
the last byte sent and #cw("Y") is zero. Everything else is preserved.
There is no error return: the bit-banger writes into the dark.

#subsect[DWRead]

Reads #cw("Y") bytes into #cw("X") and gives up if the line goes quiet
for about a second and a half. On return:

#bl[#strong[Z is set] if every byte arrived. This is the test you want —
#cw("BNE") branches on failure.]

#bl[#strong[The carry is set] on a framing error, which is a different
and rarer complaint.]

#bl[#cw("X") still points at the start of the buffer.]

#bl[#cw("Y") holds a 16-bit sum of the bytes received. It is the disk
checksum, and it means your count register does not survive the call.]

#bl[All three accumulators are clobbered. #cw("U") is preserved.]

So the shortest correct read is:

#asmbox("        ldx     #BUF
        ldy     #7
        jsr     [DWREADV]
        bne     NOANSWER        ; Z clear")

#ybox(title: [WATCH THE FLAG])[It is the #strong[zero] flag, not the
carry, that says the read worked. fujinet-lib's C binding extracts it
with #cw("tfr cc,b") and two #cw("lsrb")s, which is bit 2 of the
condition codes — the Z flag. Testing the carry instead gives you a
program that works perfectly until the network is slow.]

#colbreak()

#sect[Baud and the model switches]

The bit-banger's speed is set by how many cycles the CPU spends between
bits, so it depends on the machine. The FujiNet reads a pair of DIP
switches at power-up and picks to match:

#align(center, table(columns: (auto, auto), align: (left, right),
  stroke: 0.6pt + ink, inset: 5pt,
  table.header(
    text(font: f-head, weight: 700, size: 9.5pt)[Model setting],
    text(font: f-head, weight: 700, size: 9.5pt)[Speed]),
  [Color Computer 1], [38,400 baud],
  [Color Computer 2], [57,600 baud],
  [Color Computer 3], [115,200 baud],
  [Dragon], [57,600 baud],
))

Cartridges built around the high-speed UART run at 921,600 baud to their
own coprocessor instead, and FujiNet-PC over DriveWire-over-IP takes the
rate from its configuration file and listens on TCP port 65504.

You do not set any of this from a program, and you cannot ask what it is.
If the adapter is silent, the switches are the first thing to check.

#sect[Why the vectors]

You could bit-bang the port yourself. People have. The reason not to is
that the routines behind those vectors are cycle-counted, tuned by people
with oscilloscopes, and are the same ones HDB-DOS is using to serve the
disk you booted from.

The deeper reason is that everything above them stops caring how the
bytes move. Chapter 11 takes the vectors away --- OS-9 does not map that
ROM --- and nothing above them changes.

#sect[Is anybody there?]

There is a one-byte opcode whose only job is to prove something is
listening. Send #hx("A5") and the adapter replies with the seven
characters #cw("FUJINET") — no length, no terminator, no command byte.

#vpair(
"PROBE   ldx     #JFRM
        ldy     #1
        jsr     [DWWRITV]
        ldx     #JBUF
        ldy     #7
        jsr     [DWREADV]
        bne     NOFUJI      ; nothing there
        ldx     #JBUF
        ldy     #JSIG
        ldb     #7
CMP1    lda     ,x+
        cmpa    ,y+
        bne     NOFUJI
        decb
        bne     CMP1
        rts                 ; Z set: a FujiNet

JFRM    fcb     $A5
JSIG    fcc     \"FUJINET\"
JBUF    rmb     7",
"/* fujinet-lib keeps these to itself,
   but they are in the library. */
extern byte dwread(byte *s, int l);
extern byte dwwrite(byte *s, int l);

byte fujinet_present(void)
{
    byte op = 0xA5;
    byte buf[8];

    dwwrite(&op, 1);
    if (!dwread(buf, 7))
        return 0;          /* silence */
    buf[7] = '\\0';
    return !strcmp((char *) buf,
                   \"FUJINET\");
}")

It costs eight bytes on the wire and it is the difference between a
program that says #tt("NO FUJINET FOUND") and one that hangs.

#v(4pt)
#gbar
]

// ============================================================
// 4. THE SHAPE OF A COMMAND
// ============================================================
#chapter("4. The Shape of a Command",
  subs: ("Two frames", "Big-endian, for once", "The three meta-commands",
         "The three-step dance", "Getting the length wrong",
         "One error byte for the whole bus"))
#ix("Frames, command", "Aux bytes", "DEVICE_READY", "SEND_ERROR",
    "SEND_RESPONSE", "Big-endian", "Desynchronisation")

#cols2[
A FujiNet command is a few bytes written to the wire. There is no header,
no length field, no checksum and no acknowledgement. The adapter reads an
opcode, and from that opcode it knows exactly how many more bytes to
take. If you and it disagree about that number, nothing complains: the
conversation simply becomes nonsense from that point on, forever.

Which is why this chapter is short, and why it is the most important one.

#sect[Two frames]

The FujiNet control device takes an opcode and a command byte, then
whatever that command wants:

#bytefield((hx("E2"), 2), ([command], 2), ([aux bytes, 0 to 3], 3),
  ([payload, if any], 4))

The network device puts a unit number between them, and then *always*
takes exactly two more bytes before any payload — whether the command
wants them or not:

#bytefield((hx("E3"), 2), ([unit], 2), ([command], 2), ([aux1], 2),
  ([aux2], 2), ([payload, if any], 4))

That "always two" is not a convention, it is the parser: the frame
decoder for #hx("E3") consumes a two-byte parameter word before it will
hand you a payload, and its destructor consumes it on the way out if
nothing else did. A network command with no parameters still needs two
zero bytes. Leave them off and the next command's first two bytes become
this command's parameters.

The control device has no such rule. Its aux byte count is per command,
and the reference cards in Chapter 12 give it for each one.

#sect[Big-endian, for once]

Any parameter wider than a byte goes high byte first. So does the length
in a #cw("SEND_RESPONSE") on the network device, and so do the byte
counts in #cw("READ") and #cw("WRITE").

This is the one place where the Color Computer has it easier than the
Atari or the Apple II. The 6809 stores the high byte first, so a CMOC
structure can go straight out of the door:

#cbox("struct
{
    uint8_t  opcode;
    uint8_t  unit;
    uint8_t  cmd;
    uint16_t len;      /* already big-endian */
} r;

r.opcode = 0xE3;
r.unit   = unit;
r.cmd    = 'R';
r.len    = 512;

dwwrite((uint8_t *) &r, sizeof(r));")

No swapping, no packing directives, no helper macros. On every other
FujiNet platform that structure needs work before it is legal on the
wire. Here it is legal as written.

#ybox(title: [THREE EXCEPTIONS])[Three replies come back
#strong[little]-endian, because the firmware sends a raw host integer
rather than a declared big-endian one: #cw("GET_DIRECTORY_POSITION"),
#cw("RANDOM_NUMBER"), and the network device's #cw("TELL"). Their cards
say so. Everything else is high byte first.]

#colbreak()

#sect[The three meta-commands]

Three command bytes never reach a device. The bus answers them itself,
and they are the same three on #hx("E2") and on #hx("E3"):

#dotdef(
  (hx("00") + "  READY", [Writes back a single #hx("01"). It means "I am
   here and I am listening."]),
  (hx("02") + "  SEND_ERROR", [Writes back one byte: how the last command
   went. #hx("01") is success; everything else is in Appendix B.]),
  (hx("01") + "  SEND_RESPONSE", [Writes back whatever the last command
   parked. You must know how many bytes to expect.]),
)

On the network device all three take the unit byte and the two aux bytes
like any other command, and #cw("SEND_RESPONSE") reads its length out of
that aux word and zero-pads the reply up to it.

#sect[The three-step dance]

So a command that returns data is three exchanges, not one:

#step(1)[#strong[Ask if it is ready.] Write #hx("E2") #hx("00") and read
one byte. If nothing comes back, the adapter is busy; write it again.
Loop until it answers. This is not politeness — a command sent into a
busy adapter is a command that vanishes.]

#step(2)[#strong[Send the command.] Opcode, command byte, aux bytes,
payload. Nothing comes back.]

#step(3)[#strong[Collect.] Write #hx("E2") #hx("02") and read the error
byte. If the command had something to say, write #hx("E2") #hx("01") and
read exactly as many bytes as it owes you.]

Here is the whole of #cw("GET_WIFISTATUS") as bytes on the wire. Three
bytes out, one in; two out, one in; two out, one in.

#shbox("CoCo -> E2 00              ready?
FN   -> 01                 yes
CoCo -> E2 FA              GET_WIFISTATUS
CoCo -> E2 00              ready?
FN   -> 01                 yes
CoCo -> E2 02              how did it go?
FN   -> 01                 fine
CoCo -> E2 00              ready?
FN   -> 01                 yes
CoCo -> E2 01              give it here
FN   -> 03                 connected")

Eleven bytes to learn one. It is not efficient and it does not need to
be: at 115,200 baud that is under a millisecond, and the alternative —
inline replies — is what makes the SIO bus on the Atari need a checksum
on every frame.

#sect[Getting the length wrong]

Say a command wants a 256-byte payload and you send 200. The adapter
takes your 200, then keeps reading. The next 56 bytes it gets are the
front of your next command. It uses them as payload, answers something
meaningless, and now every byte for the rest of the session is one
command out of step.

There is no recovery from this short of resetting the Computer. So:

#bl[Pad fixed-size fields to their full size. A devicespec field is 256
bytes even when the spec is 20.]

#bl[Read exactly as many bytes as the card says a reply is. Not fewer.]

#bl[Send the aux bytes even when they are ignored.]

#sect[One error byte for the whole bus]

A caution that costs nothing to obey and an evening to discover. The
error byte and the parked response are kept in one place for the whole
bus, not one place per device. The network device's dispatcher hands the
control device's error state to the meta-command handler.

In practice: finish one command before you start another. Do not send a
control-device command between a network command and its
#cw("SEND_RESPONSE"), and do not interleave two #cw("N:") units. The
library does not protect you from this and neither does the adapter.

#v(4pt)
#gbar
]

// ============================================================
// 5. FIRST CONTACT
// ============================================================
#chapter("5. First Contact",
  subs: ("The command", "In assembly", "In C", "What comes back",
         "Building and running it"))
#ix("GET_ADAPTERCONFIG_EXTENDED", "AdapterConfigExtended", "First Contact",
    "FCDEMO")

#cols2[
Here is a program that asks the adapter who it is and prints the answer.
It is thirty lines of assembly or twenty of C, it uses one command, and
when it works you know the cable, the switches, the ROM vectors, the
handshake and your build are all correct. Nothing else you write will
have as good a ratio of certainty to effort.

#sect[The command]

#cw("GET_ADAPTERCONFIG_EXTENDED"), command byte #hx("C4"), no parameters,
240 bytes back. It is the right first command for three reasons: it takes
nothing to get wrong, it answers before the WiFi is up, and its reply
carries the IP address as text so you do not have to write a
print-a-number routine before you can see anything.

The 240 bytes are one structure. The fields you want first are:

#dotdef(
  ("0", [#cw("ssid[33]") — the network it joined]),
  ("125", [#cw("fn_version[15]") — the firmware]),
  ("140", [#cw("sLocalIP[16]") — the address, already dotted]),
)

and the rest — hostname, the binary forms of the four addresses, the MAC,
the BSSID, and text forms of all of them — are laid out in full on the
card in Chapter 12.

#sect[In assembly]

Three calls. #cw("FNCMD0") sends a control-device command that takes no
parameters and brings back the verdict; #cw("FNGRSP") fetches what it
parked. Both are from #cw("fnlow.asm"), which Chapter 6 builds.

#asmbox("        lda     #FCADCFX        ; $C4
        jsr     FNCMD0
        bne     FAILED          ; A was not $01

        ldx     #CFG
        ldy     #SZADCFX        ; 240
        jsr     FNGRSP
        bne     FAILED")

and then it is just printing:

#asmbox("        ldx     #MSSID
        jsr     PUTS
        ldx     #CFG+0          ; ssid[33]
        jsr     PUTS
        jsr     CRLF

        ldx     #MADDR
        jsr     PUTS
        ldx     #CFG+140        ; sLocalIP[16]
        jsr     PUTS
        jsr     CRLF")

Every field is NUL-terminated inside its own fixed-width slot, so the
same #cw("PUTS") that prints a message prints a field. Appendix C.2 has
the whole file.

#colbreak()

#sect[In C]

fujinet-lib wraps this one, and the structure it fills is declared in
#cw("fujinet-fuji.h"), so the offsets above become field names:

#cbox("#include <cmoc.h>
#include <coco.h>
#include <fujinet-fuji.h>

int main(void)
{
    AdapterConfigExtended ac;

    putchar(12);                /* clear */
    printf(\"FUJINET FIRST CONTACT\\n\");

    if (!fuji_get_adapter_config_extended(&ac))
    {
        printf(\"NO ANSWER\\n\");
        return 1;
    }

    printf(\"NETWORK.. %s\\n\", ac.ssid);
    printf(\"ADDRESS.. %s\\n\", ac.sLocalIP);
    printf(\"FIRMWARE. %s\\n\", ac.fn_version);

    return 0;
}")

#cw("putchar(12)") clears the screen: Color BASIC's console-out routine
treats a form feed that way, and it saves calling #cw("cls()") for one
character. Either is fine.

#sect[What comes back]

#tv(
  vrow(N("FUJINET FIRST CONTACT" + rp(" ", 11))),
  vrow(N(rp(" ", 32))),
  vrow(N("NETWORK.. " + "HOME-2G" + rp(" ", 15))),
  vrow(N("ADDRESS.. " + "192.168.1.44" + rp(" ", 10))),
  vrow(N("FIRMWARE. " + "1.8.1" + rp(" ", 17))),
  vrow(N(rp(" ", 32))),
  vrow(N("OK" + rp(" ", 30))),
  vrow(N(rp(" ", 32))),
  ..range(8).map(_ => FR(vg.g)))

#sect[Building and running it]

#shbox("$ lwasm --6809 --format=decb \\
      -I../fnlib -o FCDEMO.BIN fcdemo.asm

$ cmoc -Ifujinet -o FCDEMO.BIN \\
      fcdemo.c -lfujinet")

Get the #tt(".BIN") onto a disk image, mount the image, and:

#shbox("LOADM\"FCDEMO\"
EXEC")

#ybox(title: [IF IT SAYS NOTHING AT ALL])[A program that hangs here has
not reached the adapter. #cw("FNCMD0") begins with #cw("FNWAIT"), which
asks "are you there" forever and never gives up, because that is exactly
what you want once you *know* something is out there. Before you know it,
use the seven-byte probe from Chapter 3 — it fails in a second and a half
and tells you so.]

#ybox(title: [IF THE SSID IS EMPTY])[Then you reached the adapter and it
is not on a network. That is a CONFIG problem, not a program problem;
the Getting Started manual has the screens. #cw("GET_WIFISTATUS") will
tell you the same thing in one byte: #hx("03") is connected and
#hx("06") is not.]

#v(4pt)
#gbar
]

// ============================================================
// 6. THE 6809 ASSEMBLER LIBRARY
// ============================================================
#chapter("6. The 6809 Assembler Library",
  subs: ("fn.inc", "FNWAIT", "FNXACT and FNGERR", "FNGRSP",
         "FNCMD0 and FNCMD1", "The network four", "Register discipline"))
#ix("fnlow.asm", "fn.inc", "FNWAIT", "FNXACT", "FNGERR", "FNGRSP",
    "Assembler library")

#cols2[
There is no shipped assembler library for FujiNet on the Color Computer,
so this book brings one. It is nine subroutines in about two hundred
lines, it allocates nothing but its own frames, and every assembly
example in the reference chapters calls into it. Appendix C.3 prints it
whole.

#sect[fn.inc]

Before the code, the names. #cw("fn.inc") is two hundred #cw("EQU")s:
every DriveWire opcode, every command byte on both devices, the open and
translation modes, the parser modes, the hash algorithms, every error
code, and the sizes of the fixed-length replies.

#asmbox("DWREADV EQU     $D93F
DWWRITV EQU     $D941
OPFUJI  EQU     $E2
OPNET   EQU     $E3
FNREADY EQU     $00
FNRESP  EQU     $01
FNERROR EQU     $02
FCADCFX EQU     $C4
SZADCFX EQU     240
ESUCC   EQU     1")

Nothing in it generates a byte. Include it and use the names; the
reference chapters use the same ones.

#sect[FNWAIT]

The first routine and the one everything else starts with. Write
#hx("E2") #hx("00"), read one byte, and if nothing comes back, ask
again.

#asmbox("FNWAIT  pshs    d,x,y
FNWAIT1 ldx     #FNRDYF
        ldy     #2
        jsr     [DWWRITV]
        ldx     #FNSCRP
        ldy     #1
        jsr     [DWREADV]
        bne     FNWAIT1     ; nothing yet
        puls    d,x,y,pc

FNRDYF  fcb     OPFUJI,FNREADY
FNSCRP  rmb     1")

It loops forever by design. #cw("DWRead") times out after a second and a
half, so each pass is bounded; what is unbounded is how many passes it
takes, and the adapter is allowed to be busy for as long as a directory
listing needs. If you want a program that gives up, count the passes
yourself — but do the seven-byte probe from Chapter 3 first and you
will not need to.

#sect[FNXACT and FNGERR]

#cw("FNXACT") sends a whole frame and brings back the verdict. It does
that by falling straight into #cw("FNGERR"), which is the tidiest thing
in the file:

#asmbox("FNXACT  jsr     FNWAIT
        jsr     [DWWRITV]   ; X, Y consumed
*       fall into FNGERR

FNGERR  pshs    x,y
        jsr     FNWAIT
        ldx     #FNERRF
        ldy     #2
        jsr     [DWWRITV]
        ldx     #FNSCRP
        ldy     #1
        jsr     [DWREADV]
        bne     FNGE1       ; no answer at all
        lda     FNSCRP
        bra     FNGE2
FNGE1   lda     #EGENERL    ; call silence fatal
FNGE2   puls    x,y
        cmpa    #ESUCC
        rts")

Two things worth pointing at. The #cw("CMPA #ESUCC") at the end sets the
zero flag when the byte was #hx("01"), so every caller in this book ends
#cw("jsr FNXACT / bne FAILED") and reads naturally. And silence is
folded into #hx("90") — a general error — rather than being reported as
success, because a command whose verdict never arrived did not succeed.

#colbreak()

#sect[FNGRSP]

Fetch whatever the last command parked. You supply the buffer and the
count; the count is not negotiable, it is on the command's card.

#asmbox("FNGRSP  pshs    x,y
        jsr     FNWAIT
        ldx     #FNRSPF
        ldy     #2
        jsr     [DWWRITV]
        puls    x,y
        jmp     [DWREADV]")

The #cw("JMP") at the end is not a shortcut, it is the return: whatever
#cw("DWRead") sets the zero flag to is what the caller tests.

#sect[FNCMD0 and FNCMD1]

Most control-device commands take no parameters or one byte, so two
shorthands cover a great deal of Chapter 12:

#asmbox("FNCMD0  sta     FNC0F+1
        ldx     #FNC0F
        ldy     #2
        bra     FNXACT

FNCMD1  sta     FNC1F+1
        stb     FNC1F+2
        ldx     #FNC1F
        ldy     #3
        bra     FNXACT

FNC0F   fcb     OPFUJI,0
FNC1F   fcb     OPFUJI,0,0")

So mounting host slot 2 is:

#asmbox("        lda     #FCMNTHS    ; $F9
        ldb     #2
        jsr     FNCMD1
        bne     FAILED")

#ybox(title: [COUNT THE PARAMETERS])[#cw("FNCMD1") sends exactly one
parameter byte. A command that takes two — #cw("READ_DIR_ENTRY") and
#cw("MOUNT_IMAGE") among them — needs its own frame, because the adapter
will read the second byte whether you sent it or not. Chapter 17's
mounter builds a four-byte frame for exactly this reason.]

#sect[The network four]

#cw("fnnet.asm") adds the five moves. They share one unit byte,
#cw("NTUNI"), which #cw("NTOPEN") sets from the devicespec:

#dotdef(
  ("NTOPEN", [X = devicespec, A = mode, B = translation]),
  ("NTCLOS", [no arguments]),
  ("NTSTAT", [X = a four-byte buffer]),
  ("NTREAD", [X = buffer, Y = count]),
  ("NTWRIT", [X = buffer, Y = count]),
)

plus #cw("NTXACT"), #cw("NTGERR") and #cw("NTGRSP") for the other
twenty-four network commands, which take the unit in #cw("B"). To drive
two channels at once, keep your own unit bytes and call those three
directly; the five convenience routines are single-channel on purpose.

#sect[Register discipline]

The ROM routines are not gentle. #cw("DWRead") returns a checksum in
#cw("Y") and clobbers all three accumulators; #cw("DWWrite") consumes
both index registers. Every routine in #cw("fnlow.asm") therefore states
in its header exactly what it keeps, and keeps it.

The one to remember: after any call that ends in #cw("DWRead"), your
count register is gone. Push it if you need it.

#v(4pt)
#gbar
]

// ============================================================
// 7. C ON THE COLOR COMPUTER
// ============================================================
#chapter("7. C on the Color Computer",
  subs: ("What CMOC gives you", "The library's shape", "Reading the return",
         "Dropping below the library", "Inline assembly", "Memory"))
#ix("CMOC", "fujinet-lib", "fn_device_error", "FN_ERR codes",
    "Inline assembly (CMOC)")

#cols2[
CMOC compiles C for the 6809 and, by default, for the Disk BASIC
environment: the output is a #tt(".BIN") that #tt("LOADM") loads and
#tt("EXEC") starts. It has the standard library you would expect of a C
for an eight-bit machine — #cw("printf"), #cw("strcpy"), #cw("malloc") —
and a header of Color Computer particulars in #cw("<coco.h>"):
#cw("cls()"), #cw("inkey()"), #cw("waitkey()"), #cw("width()"),
#cw("locate()").

#sect[What CMOC gives you]

Two things matter for this book.

The first is that the 6809 is big-endian, so a #cw("struct") of
#cw("uint8_t") and #cw("uint16_t") fields is already in wire order.
Chapter 4 made this point and it is worth making twice: nowhere in a
Color Computer FujiNet program do you byte-swap anything.

The second is that CMOC does not pad structures. A
#cw("struct { uint8_t a, b, c; uint16_t d; }") is five bytes, in that
order, always. Every frame in this book is built that way.

#sect[The library's shape]

fujinet-lib is one call per command, named after the command, taking the
parameters in the order the frame wants them:

#cbox("bool fuji_mount_host_slot(uint8_t hs);
bool fuji_mount_disk_image(uint8_t ds,
                           uint8_t mode);
bool fuji_read_directory(uint8_t maxlen,
                         uint8_t aux2,
                         char *buffer);

uint8_t network_open(const char *spec,
                     uint8_t mode,
                     uint8_t trans);
int16_t network_read(const char *spec,
                     uint8_t *buf,
                     uint16_t len);")

Note that the network calls take the *devicespec*, not a unit number.
The library digs the unit out of the string each time — #cw("N:") is
unit 1, #cw("N2:") is unit 2 — so you pass the same string you opened
with and the library keeps the bookkeeping.

#sect[Reading the return]

This is where people get caught, because the two halves of the library
answer differently.

The #cw("fuji_") calls return a #cw("bool"): true if it worked. The raw
byte from the adapter is left in the global #cw("fn_device_error"), so
that is what you print when something fails.

#cbox("if (!fuji_mount_host_slot(0))
    printf(\"NO: %u\\n\", fn_device_error);")

The #cw("network_") calls return a #cw("uint8_t") error code — and it is
*not* the adapter's byte, it is a small device-agnostic code:

#dotdef(
  ("FN_ERR_OK", "0 — it worked"),
  ("FN_ERR_IO_ERROR", "1 — the device complained"),
  ("FN_ERR_BAD_CMD", "2 — bad arguments"),
  ("FN_ERR_OFFLINE", "3 — no device"),
  ("FN_ERR_WARNING", "4 — non-fatal"),
  ("FN_ERR_NO_DEVICE", "5 — nothing there"),
  ("FN_ERR_UNKNOWN", "$FF"),
)

so a success test is #cw("== FN_ERR_OK") and not #cw("!= 0")-as-truth,
and the adapter's real byte is again in #cw("fn_device_error"). On this
platform the mapping is blunt: exactly #hx("01") becomes
#cw("FN_ERR_OK") and everything else becomes #cw("FN_ERR_IO_ERROR"). If
you want to know that it was #hx("88") — end of file — rather than
#hx("CA") — connection refused — read #cw("fn_device_error") yourself.

#cw("network_read()") is the exception to the exception: it returns the
number of bytes it got, or the *negative* of an error code.

#cbox("n = network_read(spec, buf, want);
if (n < 0)
    fail(fn_device_error);")

#colbreak()

#sect[Dropping below the library]

fujinet-lib does not wrap every command, and one or two of the calls it
does provide disagree with the current firmware about which aux byte
carries the parameter. When that happens you do not have to leave C: the
bus primitives are in the library even though the headers keep them
private.

#cbox("extern void    bus_ready(void);
extern byte    dwwrite(byte *s, int l);
extern byte    dwread(byte *s, int l);
extern uint8_t network_get_error(uint8_t unit);
extern uint8_t network_get_response(uint8_t unit,
                                    uint8_t *buf,
                                    int len);")

Declare the ones you need, build the frame as a structure, and send it.
Here is the one from Chapter 18, which selects the JSON parser — a
command whose mode the firmware reads out of aux2:

#cbox("struct
{
    uint8_t op, unit, cmd, aux1, aux2;
} f;

f.op   = 0xE3;
f.unit = unit;
f.cmd  = 0xFC;              /* SET_PARSER */
f.aux1 = 0;
f.aux2 = 1;                 /* JSON */

bus_ready();
dwwrite((byte *) &f, sizeof(f));
e = network_get_error(unit);")

Five bytes, and it is the same five the card in Chapter 13 shows. There
is no layer to fight: the library and your own frames are the same
conversation.

#sect[Inline assembly]

CMOC will take a block of 6809 wherever a statement can go, and inside
it a parameter or local is named with a leading colon. This is how the
library reaches the ROM vectors, and it is how you would reach your own:

#cbox("byte dwwrite(byte *s, int l)
{
    asm
    {
        pshs x,y
        ldx  :s
        ldy  :l
        jsr  [0xD941]
        tfr  cc,d
        puls y,x
    }
}")

The value left in #cw("B") when the block ends is the function's return
value. Labels inside a block want an #cw("@") prefix so that repeated
inlining does not collide.

#sect[Memory]

CMOC's default origin for a Disk BASIC program is set by
#cw("--org="), and the default leaves room under it for BASIC. A
FujiNet program's appetite is mostly buffers, and the two that matter
are the 256-byte devicespec field in every network frame and whatever
you read into. Neither is large, but both are easy to put on the stack
by accident:

#ybox(title: [KEEP THE FRAMES STATIC])[A network frame is 261 bytes. A
local one eats a quarter of a small stack and CMOC will not warn you.
Declare frame structures and read buffers #cw("static") — every
listing in this book does.]

#v(4pt)
#gbar
]

// ============================================================
// 8. THE NETWORK DEVICE
// ============================================================
#chapter("8. The Network Device",
  subs: ("Devicespecs and units", "Open modes", "Translation",
         "The five moves", "Reading what is there", "Prefixes",
         "Parsers", "Interrupts"))
#ix("N: devicespec", "Network device", "Open modes", "Translation modes",
    "Status, network", "End of file", "Prefix (network)", "Parsers")

#cols2[
Device #hx("E3") is a bank of channels. Each one is identified by a unit
number, each unit is created the moment you first address it, and what a
channel *is* depends entirely on the URL you opened it with. A TCP
socket, a file on a TNFS share, an HTTP response, a directory listing —
all of them are the same five commands over the same five bytes of frame.

#sect[Devicespecs and units]

A devicespec is the #cw("N") prefix, an optional unit digit, a colon, and
a URL:

#spec("N:TCP://fujinet.online:6502/")
#spec("N2:HTTPS://api.example.com/v1/now")
#spec("N3:TNFS://tnfs.fujinet.online/COCO/")

#cw("N:") with no digit is unit 1. #cw("N2:") through #cw("N8:") are
units 2 to 8 by convention — the firmware will create any unit from 0 to
255, but eight is what every client library parses and eight is what you
should stay inside.

The unit is what goes in the frame's second byte. fujinet-lib works it
out from the string every time you call; the assembly library works it
out once, in #cw("NTOPEN"), and remembers it.

#sect[Open modes]

The first aux byte of #cw("OPEN") says what you want to do:

#align(center, table(columns: (auto, auto), align: (right, left),
  stroke: 0.6pt + ink, inset: 5pt,
  table.header(
    text(font: f-head, weight: 700, size: 9.5pt)[Mode],
    text(font: f-head, weight: 700, size: 9.5pt)[Access]),
  cw("$04"), [read],
  cw("$06"), [directory],
  cw("$07"), [directory, alternate form],
  cw("$08"), [write],
  cw("$09"), [append],
  cw("$0C"), [read and write],
))

For #cw("HTTP:") and #cw("HTTPS:") the same byte chooses the method,
which is why the numbers are not contiguous:

#align(center, table(columns: (auto, auto), align: (right, left),
  stroke: 0.6pt + ink, inset: 5pt,
  table.header(
    text(font: f-head, weight: 700, size: 9.5pt)[Mode],
    text(font: f-head, weight: 700, size: 9.5pt)[Method]),
  cw("$04"), [GET],
  cw("$05"), [DELETE],
  cw("$08"), [PUT],
  cw("$09"), [DELETE, collecting headers],
  cw("$0C"), [GET, collecting headers],
  cw("$0D"), [POST],
  cw("$0E"), [PUT, collecting headers],
))

#sect[Translation]

The second aux byte rewrites line endings on the way through:

#dotdef(
  (hx("00"), [none — the bytes are the bytes]),
  (hx("01"), [CR — the Color Computer's own]),
  (hx("02"), [LF]),
  (hx("03"), [CR LF]),
  (hx("04"), [PETSCII]),
)

The Color Computer's native line ending is a carriage return,
#hx("0D"), and the firmware knows it: when a protocol needs to emit a
line ending and you have not said otherwise, that is what it emits. So
#hx("00") is usually right for the CoCo and the translation modes are
there for when you are reading something that insists on LF.

#colbreak()

#sect[The five moves]

#dotdef(
  (hx("4F") + "  OPEN", [mode and translation in the aux bytes, then a
   256-byte devicespec field]),
  (hx("43") + "  CLOSE", [nothing]),
  (hx("53") + "  STATUS", [nothing; four bytes come back]),
  (hx("52") + "  READ", [the count in the aux word; the bytes come back
   through #cw("SEND_RESPONSE")]),
  (hx("57") + "  WRITE", [the count in the aux word, then the bytes]),
)

and the shape of a session is always the same:

#asmbox("        ldx     #SPEC
        lda     #OMRW
        ldb     #TRNONE
        jsr     NTOPEN
        bne     BADOPEN
*       ... status, read, write ...
        jsr     NTCLOS")

#sect[Reading what is there]

#cw("STATUS") returns four bytes and they are the whole state of the
channel:

#bytefield(([bytes waiting, high], 2), ([bytes waiting, low], 2),
  ([connected], 2), ([error], 2))

The rule is: ask #cw("STATUS"), then read *no more than* it said. Ask for
more and the adapter pads the reply with zeros to the length you named,
and you will spend an afternoon wondering where the zeros came from.

#asmbox("        ldx     #STBUF
        jsr     NTSTAT
        ldd     STBUF       ; big-endian, so LDD
        beq     NOTHING
        cmpd    #RXMAX
        bls     TAKEIT
        ldd     #RXMAX      ; only what we can hold
TAKEIT  ldx     #RXBUF
        tfr     d,y
        jsr     NTREAD")

The third byte is the connection: while it is non-zero the far end is
still there. The fourth is the channel's own error, and the one you will
meet most is #hx("88") — 136, end of file. It is not a failure. It means
this resource is finished; close the channel.

#ybox(title: [ZERO WAITING IS NOT AN ERROR])[A TCP socket with nothing
to say returns zero bytes waiting and a connected byte of one. That is
the normal state of a network connection most of the time. The test for
"we are done" is zero waiting #strong[and] not connected, or an error
byte of 136 — never zero waiting on its own.]

#sect[Prefixes]

Each unit keeps a current directory, and #cw("CHDIR") sets it with the
shell conventions you would hope for: #cw("..") goes up, a leading
slash replaces the path but keeps the host, a bare #cw("scheme:")
resets everything, and anything else appends. An empty #cw("Nn:")
clears it. #cw("GETCWD") reads it back.

#sect[Parsers]

A channel can have a parser sitting on it — JSON, HTML with CSS
selectors, or XML with a subset of XPath. You set the mode, tell it to
parse, and then query it. The document stays on the adapter; only the
answer to each query crosses the wire, which is the only reason a
64-kilobyte machine can read a modern API at all. Chapter 18 does this
end to end.

#sect[Interrupts]

The adapter will tell you when a channel has something, rather than
making you poll: it drives the serial line's DCD on hardware, or DTR or
RTS on FujiNet-PC, whenever bytes are waiting, the connection dropped,
or an error other than success or end-of-file is pending.
#cw("SET_INT_RATE") sets how often it looks. It is not driven at all
over DriveWire-over-IP, where there is no line to drive.

#v(4pt)
#gbar
]

// ============================================================
// 9. THE FUJI DEVICE
// ============================================================
#chapter("9. The Fuji Device",
  subs: ("Host slots", "Device slots", "Prefixes", "Walking a directory",
         "App keys", "The adapter's spare cycles"))
#ix("Host slots", "Device slots", "Directory, reading a", "App keys",
    "Detail block", "Hashing", "Base64", "QR code")

#cols2[
Device #hx("E2") is the adapter's own housekeeping: where your files
live, which of them are in drives, what network you are on, and a
handful of things the ESP32 can do that a 6809 would rather not.

#sect[Host slots]

Eight of them, numbered 0 to 7. A host slot is a name — a TNFS server, or
the literal #cw("SD") for the card in the side of the cartridge — stored
as 32 bytes.

#cw("READ_HOST_SLOTS") returns all eight at once, 256 bytes, and
#cw("WRITE_HOST_SLOTS") takes all eight back. There is no read-one or
write-one; you fetch the block, change a name, and put the block back.

#cbox("HostSlot hosts[8];

fuji_get_host_slots((uint8_t *) hosts, 8);
strcpy((char *) hosts[2],
       \"tnfs.example.com\");
fuji_put_host_slots((HostSlot *) hosts, 8);")

Naming a slot does not open it. #cw("MOUNT_HOST") does that, and it is
what turns a name into something you can list.

#sect[Device slots]

Four of them on the Color Computer, numbered 0 to 3, and this is the one
number where the CoCo differs from its cousins: the Atari has eight and
the Apple II has ten. A device slot is 38 bytes:

#bytefield(([host slot], 3), ([mode], 3), ([file name, 36 bytes], 10))

#cw("READ_DEVICE_SLOTS") returns all four, 152 bytes. The mode byte you
get back is not the mode you set: the adapter ORs in #hx("40") when the
drive is actually live, so

#cbox("if (drives[i].mode & 0x40)
    /* something is mounted here */;")

is the test for "is there a disk in it", and the low bits — #hx("01")
read, #hx("02") write — are how it was mounted.

#sect[Prefixes]

Each host slot also carries a prefix, up to 256 bytes: the directory you
are working in on that host. #cw("SET_HOST_PREFIX") and
#cw("GET_HOST_PREFIX") take the slot number in the aux byte.

The prefix is what #cw("OPEN_DIRECTORY") is relative to, so setting it
once and then listing #cw("/") repeatedly is how a file browser walks a
tree without building paths.

#colbreak()

#sect[Walking a directory]

Three commands, and one of them has a parameter worth understanding.

#step(1)[#cw("OPEN_DIRECTORY") takes the host slot in its aux byte and a
256-byte field holding the path. If there is room, a filename pattern can
follow the path's terminating NUL: #cw("\"/\" 00 \"*.dsk\" 00") lists only
the disk images.]

#step(2)[#cw("READ_DIR_ENTRY") takes *two* aux bytes — the maximum length
you will accept and a flags byte — and returns that many bytes. A
directory's entries come back one per call, NUL-terminated inside the
fixed width, with a trailing slash on the names that are directories.
Two bytes of #hx("7F") mean the directory is finished.]

#step(3)[#cw("CLOSE_DIRECTORY") takes nothing.]

The flags byte is where the detail lives. Set bit 7 and each entry is
prefixed with a 13-byte block describing the file, in a layout that is
the Color Computer's own:

#bytefield(([yr], 1), ([mo], 1), ([dy], 1), ([hr], 1), ([mi], 1),
  ([sec], 1), ([size, 4 bytes, big-endian], 4), ([dir], 1),
  ([trunc], 1), ([media], 1))

The year is #cw("tm_year - 100"), so 26 is 2026. The size is four bytes
high byte first — the one place in the firmware where a 32-bit value is
deliberately put in the Color Computer's order. The flags byte is
#hx("01") for a directory and #hx("02") for a name that had to be
truncated to fit.

Set both bits 7 and 6 and you get block mode instead: the maximum-length
byte becomes a count of 256-byte pages and the low six bits of the flags
become a group size, and the adapter packs as many entries as will fit
into one transfer. It is much faster for a long directory and the card in
Chapter 12 gives the header layout.

#sect[App keys]

An app key is 64 bytes of state the adapter will keep for you, filed
under your creator ID, application ID and key number. It is how a game
remembers a high score across a power cycle without owning a disk.

#step(1)[#cw("OPEN_APPKEY") with a six-byte payload: creator (two bytes,
high first), application, key, mode — 0 to read, 1 to write — and a
reserved byte.]

#step(2)[#cw("READ_APPKEY") returns 66 bytes: a two-byte length, high
byte first, and then the 64. #cw("WRITE_APPKEY") takes the length in its
aux word and then always the full 64 bytes, whatever the length says.]

#step(3)[#cw("CLOSE_APPKEY") when you are done.]

#ybox(title: [WRITE ALL SIXTY-FOUR])[The write path drains a full
64-byte block regardless of the length you declared. Send fewer and the
adapter keeps reading into your next command. The firmware says so in a
comment, which is how you know somebody found out the hard way.]

#sect[The adapter's spare cycles]

The ESP32 is a great deal faster than the 6809 and is sitting there
anyway. Four families of command lend it out:

#bl[#strong[Base64], in and out, encode and decode, four commands each
way: feed input, compute, ask the length, take the output.]

#bl[#strong[Hashing] — MD5, SHA-1, SHA-256, SHA-512 — with the same
shape, plus a variant that keeps the input so you can hash a stream in
pieces.]

#bl[#strong[QR codes], which will render to an ANSI or bitmap form you
can put on a screen that has no business displaying a QR code.]

#bl[#strong[A UUID] and #strong[four random bytes], for when you need
either and would rather not write the code.]

All four are in Chapter 12 with their exact frames.

#v(4pt)
#gbar
]

// ============================================================
// 10. DEVICES, SLOTS AND BOOTING
// ============================================================
#chapter("10. Devices, Slots and Booting",
  subs: ("Getting a file into a drive", "Access modes", "Making a blank disk",
         "What an image can be", "Boot modes", "Living with HDB-DOS"))
#ix("Mounting", "MOUNT_IMAGE", "SET_DEVICE_FULLPATH", "Boot modes",
    "NEW_DISK", "Media types", "HDB-DOS", "CONFIG disk")

#cols2[
A drive slot has a file name in it and, separately, a state: mounted or
not. Those are two commands, and running them in the wrong order is the
most common way to get a drive that looks right and does nothing.

#sect[Getting a file into a drive]

#step(1)[#cw("MOUNT_HOST") the host slot the file lives on. Naming a
host is not opening it.]

#step(2)[#cw("SET_DEVICE_FULLPATH") writes the file name into the drive
slot. Its aux bytes are the drive slot, the host slot, and a mode; a mode
of #hx("00") stores the name without touching the file.]

#step(3)[#cw("MOUNT_IMAGE") opens it. Its two aux bytes are the drive
slot and the access mode.]

#cbox("fuji_mount_host_slot(hs);
fuji_set_device_filename(0, hs, ds, name);
fuji_mount_disk_image(ds, 2);   /* r/w */")

Chapter 17's mounter does exactly this with a menu on the front, and its
assembly half builds the two payload frames by hand because neither
command fits #cw("FNCMD1").

#cw("MOUNT_ALL") does the lot in one call, from whatever the four slots
already hold — which is how a saved configuration comes back after a
power cycle.

#sect[Access modes]

#dotdef(
  (hx("01"), [read only]),
  (hx("02"), [read and write]),
  (hx("40"), [set by the adapter in a slot you read back: this drive is
   live. Never send it.]),
)

Mount an image #hx("01") and a write to it fails at the disk layer, which
is what you want for something you are only booting.

#sect[Making a blank disk]

#cw("NEW_DISK") is one of the two commands on this bus with a
Color-Computer-only payload. It takes no aux bytes and a 259-byte block:

#bytefield(([disks], 2), ([host], 2), ([drive], 2),
  ([file name, 256 bytes], 10))

The first byte is a multiplier, not a size. Each unit is 315 blocks of
512 bytes — 161,280 bytes, which is exactly a 35-track, 18-sector,
single-sided Disk BASIC diskette — and the whole thing is filled with
#hx("FF"). One gives you one diskette; four gives you a four-disk image
for a drive that knows how to step through them.

The file must not already exist. If it does, the command fails rather
than truncating something you wanted.

#colbreak()

#sect[What an image can be]

The extension decides what the adapter thinks it is serving:

#dotdef(
  (".DSK", [a Disk BASIC diskette, 256-byte sectors]),
  (".VDK", [the Dragon format]),
  (".MRM, .RMM", [raw block images]),
  (".CAS", [a cassette image, served as blocks]),
  (".ROM, .CCC", [a cartridge image — see below]),
)

A #tt(".ROM") is not served over DriveWire at all. On cartridges that
have a coprocessor, mounting one pushes the whole image across to it at
mount time, and it appears as a cartridge. On hardware that has no
coprocessor, and over DriveWire-over-IP, it is not supported.

#sect[Boot modes]

#cw("SET_BOOT_MODE") takes one byte and chooses what the adapter serves
as drive 0 when nothing else is mounted:

#dotdef(
  ("0", [#tt("/autorun.dsk")]),
  ("1", [#tt("/mount-and-boot.dsk")]),
  ("2", [the Game Lobby, over TNFS]),
  ("3", [#tt("/hisioboot-fujinet.dsk")]),
)

and #cw("CONFIG_BOOT") turns the CONFIG disk on and off with a single
byte. Turn it off and the adapter stops inserting CONFIG ahead of your
disk, which is what you want when your own program is the thing that
should come up.

#ybox(title: [RESET PUTS CONFIG BACK])[Any of the three reset opcodes —
#hx("F8"), #hx("FE"), #hx("FF") — re-arms the CONFIG disk and re-inserts
the boot device. That is deliberate: it means there is always a way back
to a working machine. It also means a program that turns CONFIG off and
then resets has not achieved anything.]

#sect[Living with HDB-DOS]

The thing to keep in mind while writing any of this is that HDB-DOS is
using the same wire. It thinks it has a disk; it does not know the disk
is being swapped underneath it.

#bl[Do not unmount or re-mount a drive image while a file is open on it
from BASIC. Close the file first. The adapter will do exactly as it is
told and DOS will be looking at a different disk than it remembers.]

#bl[A program that mounts its own next disk should do the mounting and
then hand control over — not mount and keep running out of the disk it
just replaced.]

#bl[Drive numbers in BASIC and drive slots in FujiNet are the same
numbers: slot 0 is #tt("DRIVE #0"). There is no offset to remember, which
is a small mercy.]

#ybox(title: [THE DISK IS NOT A DEVICE])[There is no command language
for the disk. It answers exactly two opcodes — #cw("OP_READEX") and
#cw("OP_WRITE") — and everything about *which* disk it is answering as
comes from the slot commands in this chapter. Chapter 14 documents the
block protocol for the benefit of anyone writing their own DOS.]

#v(4pt)
#gbar
]

// ============================================================
// 11. FUJINET UNDER OS-9
// ============================================================
#chapter("11. FujiNet under OS-9 and NitrOS-9",
  subs: ("What still works", "What stops working", "Supplying the two",
         "The stack above", "The bit-banger", "What this book has verified"))
#ix("OS-9", "NitrOS-9", "Becker port", "DWPORT.C", "Transports")

#cols2[
OS-9 boots over DriveWire perfectly well, and a FujiNet is a DriveWire
server, so a NitrOS-9 system running off a FujiNet is an ordinary thing
that many people have. What is not ordinary is issuing #hx("E2") and
#hx("E3") commands from inside it, and this chapter is about why and what
to do.

#sect[What still works]

The disk service. #cw("OP_READEX") and #cw("OP_WRITE") are the
protocol the OS-9 DriveWire driver already speaks, and an image mounted
in a FujiNet drive slot is a device descriptor away from being
#tt("/dd"). Nothing in this chapter is needed for that.

The adapter also answers #cw("OP_DWINIT") — the feature enquiry OS-9's
driver makes at startup — with #hx("04") every time, whatever its
configured feature set says.

#sect[What stops working]

Everything else in this book, and for one reason: under OS-9 the Disk
BASIC ROM is not in the memory map. #hx("D93F") and #hx("D941") are not
vectors any more; they are whatever the MMU has put there. Every routine
in Chapter 6, and the whole of fujinet-lib's Color Computer build, calls
through them.

So fujinet-lib cannot be linked into an OS-9 module. It is not a
packaging problem — the library is Disk BASIC code by construction.

#sect[Supplying the two]

The fix is the shape of the design. Only two routines touch the hardware.
Replace them and everything above is unchanged.

For the memory-mapped ports — the Becker port, the CoCo 3 FPGA's
DriveWire window, the high-speed UART cartridge — that replacement is
about a dozen instructions. Status at #hx("FF41"), data at #hx("FF42"),
bit 1 of the status byte meaning a byte is waiting:

#asmbox("@byte   ldu     #$2000      ; a timeout
@wait   lda     $FF41
        bita    #$02
        bne     @got
        leau    -1,u
        bne     @wait
        bra     @timeout
@got    lda     $FF42
        sta     ,x+
        leay    -1,y
        bne     @byte")

Two details that are easy to miss, and both of them cost real time to
find:

#bl[#strong[Mask interrupts.] These ports hold one byte. An OS-9 clock
tick between the poll and the read loses it. Frames are short and the
mask is shorter than the transfer.]

#bl[#strong[Keep the timeout.] The ROM's #cw("DWRead") gives up after
about a second and a half, and #cw("FNWAIT") depends on that: it asks
again when the adapter is busy. A poll loop with no timeout hangs there
instead of retrying, and it will look exactly like a dead adapter.]

#colbreak()

#sect[The stack above]

Chapter 6's library is assembly for Disk BASIC, so the OS-9 listing in
this book rebuilds the same four routines in C, above the transport:

#cbox("void fn_wait(void);
byte fn_error(void);
byte fn_send(byte *frame, int len);
byte fn_response(byte *buf, int len);")

Put them beside #cw("FNWAIT"), #cw("FNGERR"), #cw("FNXACT") and
#cw("FNGRSP") and they are the same routines in a different language.
The handshake did not change, the frames did not change, and the
commands in Chapters 12 to 15 are all still true. Only the bottom two
calls moved.

#cbox("byte fn_send(byte *frame, int len)
{
    fn_wait();
    dwwrite(frame, len);
    return fn_error();
}")

Chapter 19's #cw("fnstat") is thirty lines on top of that, and prints the
same three fields Chapter 5 printed.

#shbox("$ cmoc --os9 -o fnstat \\
      fnstat.c fnbus.c dwport.c
$ os9 copy fnstat /dd/CMDS/fnstat")

#sect[The bit-banger]

Which leaves the case that matters most, and the one this book will not
print: a FujiNet cartridge on a stock Color Computer hangs off the
bit-banger port, and a correct bit-banger #cw("DWRead") is a
cycle-counted routine with the loop timing chosen per CPU speed.

It exists, it is good, and it is not ours. It lives in the DriveWire and
NitrOS-9 sources as #cw("DWRead") and #cw("DWWrite"), maintained by
people with oscilloscopes, and it has been retuned more than once.
Reprinting it here would be copying somebody else's careful work into a
book that cannot be updated when they improve it.

Take it from your NitrOS-9 or DriveWire source tree, put it behind the
two names in #cw("dwport.h"), and nothing else in Chapter 19 changes.
That is the whole point of having built on the vectors.

#ybox(title: [OR ASK NITROS-9 FOR ITS COPY])[NitrOS-9 already has those
routines resident — they are how your boot disk arrived. They live in a
subroutine module which a program can #cw("F\$Link") and call at fixed
offsets from its execution entry. That is the tidiest route on a running
system, and the offsets must come from your own NitrOS-9 build rather
than from this book.]

#sect[What this book has verified]

Being plain about it, because the rest of this book is:

#bl[The C stack in Chapter 19 compiles with #cw("cmoc --os9") and is
printed in Appendix C from the file that compiled.]

#bl[The memory-mapped transport is correct by inspection of the register
map and has not been run against hardware for this book.]

#bl[The bit-banger route is described, not supplied.]

#bl[Everything from #cw("fn_wait()") upward is the same protocol as the
rest of the book, and that part is verified everywhere else in it.]

#v(4pt)
#gbar
]

// ============================================================
// 12. COMMAND REFERENCE: THE FUJI DEVICE
// ============================================================
#chapter("12. Command Reference: The Fuji Device",
  subs: ("The bus answers three", "WiFi and the adapter", "Hosts and prefixes",
         "Directories", "Device slots and mounting", "Booting and resetting",
         "App keys", "Base64", "Hashing", "QR codes", "Odds and ends",
         "Answered with silence"))
#ix("Fuji device commands", "Command reference, Fuji")

#block({
  set par(first-line-indent: 0pt, justify: true)
  [Every command device #hx("E2") answers on the Color Computer, verified
  against the firmware's dispatch tables — the shared handler map in
  #cw("fujiDevice.cpp"), the four mixins beside it, and the two commands
  #cw("drivewireFuji.cpp") adds — and cross-checked against the
  fujinet-lib Color Computer port, whose structures fix the byte layout
  of every frame it sends.

  Conventions. #emph[Frame] gives the bytes in order. #emph[Aux] are the
  parameter bytes that follow the command byte; the FujiNet control
  device takes as many as the command wants and no more. A #emph[byte]
  parameter is one byte; a #emph[word] is two, high byte first, unless
  the card says otherwise. #emph[Payload] is the block that follows the
  aux bytes. #emph[Reply] is what #cw("SEND_RESPONSE") will give you and
  exactly how many bytes to ask for.

  Every card carries the command written twice: once in 6809 assembly
  using the library in Chapter 6, once in C using fujinet-lib where it
  wraps the command and raw frames where it does not. Any command not in
  this chapter is not answered on this bus; the closing section names
  them all.]
})

#sect[12.1 The bus answers three]

#block({
  set par(first-line-indent: 0pt, justify: true)
  [These three never reach the device. The bus intercepts them, on
  #hx("E2") and on #hx("E3") alike, and they are the handshake every
  other card assumes has already happened.]
})

#cmd("DEVICE_READY", code: "$00", dev: "E2 00",
  aux: [none], payload: [none],
  reply: [one byte, always #hx("01")],
  lib: [#cw("bus_ready()")],
  asm: "FNWAIT  pshs    d,x,y
FNWAIT1 ldx     #FNRDYF
        ldy     #2
        jsr     [DWWRITV]
        ldx     #FNSCRP
        ldy     #1
        jsr     [DWREADV]
        bne     FNWAIT1
        puls    d,x,y,pc
FNRDYF  fcb     OPFUJI,FNREADY",
  c: "void bus_ready(void)
{
    struct { uint8_t op, cmd; } rc;
    uint8_t r;

    rc.op = 0xE2;
    rc.cmd = 0x00;

    do
        dwwrite((uint8_t *) &rc, sizeof(rc));
    while (!dwread(&r, 1));
}",
  [Are you listening? The adapter answers when it is free and says nothing
  when it is not, so the only correct use is a loop. Send every command
  behind one of these; a command sent into a busy adapter is simply lost.])

#cmd("SEND_ERROR", code: "$02", dev: "E2 02",
  aux: [none], payload: [none],
  reply: [one byte: #hx("01") for success, otherwise a code from Appendix B],
  lib: [#cw("fuji_get_error()"), leaving the byte in #cw("fn_device_error")],
  asm: "        jsr     FNWAIT
        ldx     #FNERRF
        ldy     #2
        jsr     [DWWRITV]
        ldx     #FNSCRP
        ldy     #1
        jsr     [DWREADV]
        bne     NOANSWER
        lda     FNSCRP
        cmpa    #ESUCC
FNERRF  fcb     OPFUJI,FNERROR",
  c: "bool fuji_get_error(void)
{
    struct { uint8_t op, cmd; } sec;
    uint8_t err;

    sec.op = 0xE2;
    sec.cmd = 0x02;

    bus_ready();
    dwwrite((uint8_t *) &sec, sizeof(sec));

    return dwread(&err, 1) ? err != 1 : 1;
}",
  [How did the last command go? Treat silence as a failure and not as a
  success: a verdict that never arrived is not a good verdict. Note that
  the error state belongs to the whole bus and not to one device, so
  fetch it before you start anything else.])

#cmd("SEND_RESPONSE", code: "$01", dev: "E2 01",
  aux: [none], payload: [none],
  reply: [as many bytes as the last command parked --- you must know the count],
  lib: [#cw("fuji_get_response(buf, len)")],
  asm: "FNGRSP  pshs    x,y
        jsr     FNWAIT
        ldx     #FNRSPF
        ldy     #2
        jsr     [DWWRITV]
        puls    x,y
        jmp     [DWREADV]
FNRSPF  fcb     OPFUJI,FNRESP",
  c: "bool fuji_get_response(uint8_t *buf, int len)
{
    struct { uint8_t op, cmd; } grc;

    grc.op = 0xE2;
    grc.cmd = 0x01;

    bus_ready();
    dwwrite((uint8_t *) &grc, sizeof(grc));
    return dwread(buf, len) != 0;
}",
  [Hand over what the last command left waiting. There is no length on the
  wire: the count on each card is the count, and reading fewer bytes than
  the adapter has queued leaves the rest in the pipe for the next command
  to trip over.])

#sect[12.2 WiFi and the adapter]

#cmd("GET_ADAPTERCONFIG_EXTENDED", code: "$C4", dev: "E2 C4",
  aux: [none], payload: [none],
  reply: [240 bytes --- #cw("ssid[33]") #cw("hostname[64]") then the binary
    #cw("localIP") #cw("gateway") #cw("netmask") #cw("dnsIP") four bytes
    each, #cw("mac[6]") #cw("bssid[6]") #cw("fn_version[15]") at offset 125,
    then the text forms: #cw("sLocalIP[16]") at 140, #cw("sGateway[16]"),
    #cw("sNetmask[16]"), #cw("sDnsIP[16]"), #cw("sMacAddress[18]") at 204,
    #cw("sBssid[18]")],
  lib: [#cw("fuji_get_adapter_config_extended(&ac)")],
  asm: "        lda     #FCADCFX
        jsr     FNCMD0
        bne     FAILED
        ldx     #CFG
        ldy     #SZADCFX        ; 240
        jsr     FNGRSP
        bne     FAILED
; ssid  CFG+0
; fw    CFG+125
; ip    CFG+140",
  c: "AdapterConfigExtended ac;

if (fuji_get_adapter_config_extended(&ac)) {
    printf(\"%s\\n\", ac.ssid);
    printf(\"%s\\n\", ac.sLocalIP);
    printf(\"%s\\n\", ac.fn_version);
}",
  [The first command to send and the one every status screen wants. It
  takes nothing, it answers before the WiFi is up, and its text fields
  spare you writing a print-an-address routine before you can see
  anything. The shorter #cw("GET_ADAPTERCONFIG") returns the first 140
  bytes only, with the addresses in binary.])

#cmd("GET_ADAPTERCONFIG", code: "$E8", dev: "E2 E8",
  aux: [none], payload: [none],
  reply: [140 bytes --- the first 140 of the extended form: #cw("ssid[33]")
    #cw("hostname[64]") #cw("localIP[4]") #cw("gateway[4]") #cw("netmask[4]")
    #cw("dnsIP[4]") #cw("mac[6]") #cw("bssid[6]") #cw("fn_version[15]")],
  lib: [#cw("fuji_get_adapter_config(&ac)")],
  asm: "        lda     #FCADCFG
        jsr     FNCMD0
        bne     FAILED
        ldx     #CFG
        ldy     #SZADCFG        ; 140
        jsr     FNGRSP",
  c: "AdapterConfig ac;

if (fuji_get_adapter_config(&ac))
    printf(\"%u.%u.%u.%u\\n\",
           ac.localIP[0], ac.localIP[1],
           ac.localIP[2], ac.localIP[3]);",
  [The compact form, for when you want the addresses as numbers rather
  than as text --- to compare two of them, say. A hundred bytes cheaper
  than #hx("C4") and a print routine more expensive.])

#cmd("GET_WIFISTATUS", code: "$FA", dev: "E2 FA",
  aux: [none], payload: [none],
  reply: [one byte: #hx("03") connected, #hx("06") disconnected],
  lib: [#cw("fuji_get_wifi_status(&s)")],
  asm: "        lda     #FCWIFST
        jsr     FNCMD0
        bne     FAILED
        ldx     #WST
        ldy     #1
        jsr     FNGRSP
        lda     WST
        cmpa    #WFCONN         ; $03
        bne     OFFLINE",
  c: "uint8_t s;

if (fuji_get_wifi_status(&s) && s == 3)
    /* on the network */;",
  [One byte, and the fastest way to tell "the cable is fine but you are
  not on a network" from "there is no adapter". The other values in the
  firmware's status enumeration --- #hx("01") no SSID available,
  #hx("04") connect failed, #hx("05") connection lost --- belong to the
  radio and you will normally see only the two above.])

#cmd("GET_WIFI_ENABLED", code: "$EA", dev: "E2 EA",
  aux: [none], payload: [none],
  reply: [one byte: non-zero if the radio is switched on],
  lib: [#cw("fuji_get_wifi_enabled()")],
  asm: "        lda     #FCWIFEN
        jsr     FNCMD0
        bne     FAILED
        ldx     #WEN
        ldy     #1
        jsr     FNGRSP",
  c: "if (!fuji_get_wifi_enabled())
    printf(\"RADIO IS OFF\\n\");",
  [Whether the radio is enabled at all, which is a different question from
  whether it has joined anything. A FujiNet with WiFi switched off is
  still a perfectly good disk server.])

#cmd("SCAN_NETWORKS", code: "$FD", dev: "E2 FD",
  aux: [none], payload: [none],
  reply: [one byte: how many networks were found],
  lib: [#cw("fuji_scan_for_networks(&n)")],
  asm: "        lda     #FCSCAN
        jsr     FNCMD0
        bne     FAILED
        ldx     #NCOUNT
        ldy     #1
        jsr     FNGRSP",
  c: "uint8_t n;

if (fuji_scan_for_networks(&n))
    printf(\"%u NETWORKS\\n\", n);",
  [Sweeps the band and returns the count. This one takes real time --- the
  radio has to listen on every channel --- so #cw("FNWAIT") will spin for
  a while before the verdict comes back. That is the loop working, not
  the loop failing.])

#cmd("GET_SCAN_RESULT", code: "$FC", dev: "E2 FC n",
  aux: [#emph[byte]: which result, 0 to count−1],
  payload: [none],
  reply: [34 bytes: #cw("ssid[33]") then a signed #cw("rssi") byte],
  lib: [#cw("fuji_get_scan_result(n, &info)")],
  asm: "        lda     #FCSCANR
        ldb     #0              ; first result
        jsr     FNCMD1
        bne     FAILED
        ldx     #SSINFO
        ldy     #SZSCANR        ; 34
        jsr     FNGRSP
        ldx     #SSINFO
        jsr     PUTS            ; the name
        lda     SSINFO+33       ; the strength",
  c: "SSIDInfo info;
uint8_t i, n;

fuji_scan_for_networks(&n);
for (i = 0; i < n; i++)
    if (fuji_get_scan_result(i, &info))
        printf(\"%s %d\\n\", info.ssid,
               (signed char) info.rssi);",
  [One result at a time. The signal strength is a signed byte in dBm, so
  it is negative and bigger is worse: −45 is across the room and −85 is
  through two walls. The results live until the next scan.])

#cmd("SET_SSID", code: "$FB", dev: "E2 FB + 97",
  aux: [none],
  payload: [#strong[exactly 97 bytes]: #cw("ssid[33]") then
    #cw("password[64]"), both NUL-padded],
  reply: [none],
  lib: [#cw("fuji_set_ssid(&nc)")],
  asm: "        ldx     #SSFRM
        ldy     #99             ; 2 + 97
        jsr     FNXACT
        bne     FAILED

SSFRM   fcb     OPFUJI,FCSSSID
SSSSID  rmb     33
SSPASS  rmb     64",
  c: "NetConfig nc;

memset(&nc, 0, sizeof(nc));   /* NUL-pad */
strcpy(nc.ssid, \"HOME-2G\");
strcpy(nc.password, \"correcthorse\");

if (fuji_set_ssid(&nc))
    /* joined, and saved as the default */;",
  [Joins a network and stores it as the default. The payload is a fixed 97
  bytes whatever the two strings are; clear the buffer first. A short
  payload leaves the adapter reading into your next command and the bus
  never recovers. Unlike some platforms, this one takes no dummy
  parameter byte.])

#cmd("GET_SSID", code: "$FE", dev: "E2 FE",
  aux: [none], payload: [none],
  reply: [97 bytes: #cw("ssid[33]") then #cw("password[64]")],
  lib: [#cw("fuji_get_ssid(&nc)")],
  asm: "        lda     #FCGSSID
        jsr     FNCMD0
        bne     FAILED
        ldx     #NETCFG
        ldy     #SZSSID         ; 97
        jsr     FNGRSP",
  c: "NetConfig nc;

if (fuji_get_ssid(&nc))
    printf(\"DEFAULT: %s\\n\", nc.ssid);",
  [Reads back the stored network --- the one the adapter joins at
  power-up. Yes, it hands you the password as well. It is your adapter and
  your wire; treat the buffer accordingly.])

#sect[12.3 Hosts and prefixes]

#cmd("READ_HOST_SLOTS", code: "$F4", dev: "E2 F4",
  aux: [none], payload: [none],
  reply: [256 bytes: eight slots of 32, each a NUL-terminated name],
  lib: [#cw("fuji_get_host_slots(h, 8)")],
  asm: "        lda     #FCRDHS
        jsr     FNCMD0
        bne     FAILED
        ldx     #HOSTS
        ldy     #SZHOSTS        ; 256
        jsr     FNGRSP
; slot n is at HOSTS + 32*n",
  c: "HostSlot hosts[8];

if (fuji_get_host_slots((uint8_t *) hosts, 8))
    for (i = 0; i < 8; i++)
        printf(\"%u %s\\n\", i,
               hosts[i][0] ? (char *) hosts[i]
                           : \"(EMPTY)\");",
  [All eight at once. There is no read-one. A slot holding a TNFS server
  has its hostname; a slot pointing at the card in the side of the
  cartridge holds the literal #cw("SD")\; an unused slot's first byte is
  zero.])

#cmd("WRITE_HOST_SLOTS", code: "$F3", dev: "E2 F3 + 256",
  aux: [none],
  payload: [256 bytes: all eight slots, 32 each],
  reply: [none],
  lib: [#cw("fuji_put_host_slots(h, 8)")],
  asm: "        ldx     #WHFRM
        ldy     #258            ; 2 + 256
        jsr     FNXACT
        bne     FAILED

WHFRM   fcb     OPFUJI,FCWRHS
WHSLOT  rmb     256",
  c: "HostSlot hosts[8];

fuji_get_host_slots((uint8_t *) hosts, 8);
memset(hosts[2], 0, 32);
strcpy((char *) hosts[2], \"tnfs.example.com\");
fuji_put_host_slots(hosts, 8);",
  [And all eight go back. Read, change one, write: there is no other way
  to edit a single slot, and skipping the read means writing seven empty
  slots over somebody's configuration. Naming a slot does not open it ---
  that is #cw("MOUNT_HOST").])

#cmd("MOUNT_HOST", code: "$F9", dev: "E2 F9 n",
  aux: [#emph[byte]: the host slot, 0 to 7],
  payload: [none], reply: [none],
  lib: [#cw("fuji_mount_host_slot(hs)")],
  asm: "        lda     #FCMNTHS
        ldb     #0              ; host slot 0
        jsr     FNCMD1
        bne     FAILED",
  c: "if (!fuji_mount_host_slot(0))
    printf(\"NO: %u\\n\", fn_device_error);",
  [Opens the host named in the slot: connects to the TNFS server, or mounts
  the card. Everything that reads a directory or mounts an image from that
  host needs this first, and it is the step people forget.])

#cmd("UNMOUNT_HOST", code: "$E6", dev: "E2 E6 n",
  aux: [#emph[byte]: the host slot, 0 to 7],
  payload: [none], reply: [none],
  lib: [#strong[none that is correct] --- see below],
  asm: "        lda     #FCUNMHS        ; $E6
        ldb     #0
        jsr     FNCMD1
        bne     FAILED",
  c: "/* fujinet-lib's fuji_unmount_host_slot()
   sends $F9 --- MOUNT --- not $E6.  Until
   that is fixed, send the frame. */
struct { uint8_t op, cmd, hs; } u;

u.op = 0xE2; u.cmd = 0xE6; u.hs = 0;
bus_ready();
dwwrite((uint8_t *) &u, sizeof(u));
ok = !fuji_get_error();",
  [Closes the host and any files open on it. Worth doing before you pull a
  card out or change a server's name.

  The Color Computer build of fujinet-lib has a copy-and-paste error here:
  #cw("fuji_unmount_host_slot()") sends #cw("FUJICMD_MOUNT_HOST") rather
  than #cw("FUJICMD_UNMOUNT_HOST"), so it re-mounts the slot instead. The
  frame above is three bytes and is right.])

#cmd("SET_HOST_PREFIX", code: "$E1", dev: "E2 E1 n + 256",
  aux: [#emph[byte]: the host slot, 0 to 7],
  payload: [256 bytes: the prefix, NUL-padded],
  reply: [none],
  lib: [#cw("fuji_set_host_prefix(hs, prefix)")],
  asm: "        ldx     #SPFRM
        ldy     #259            ; 3 + 256
        jsr     FNXACT
        bne     FAILED

SPFRM   fcb     OPFUJI,FCSHPFX,0
SPPATH  rmb     256",
  c: "fuji_set_host_prefix(0, \"/COCO/GAMES\");",
  [Sets the working directory on that host. Everything
  #cw("OPEN_DIRECTORY") does afterwards is relative to it, which is how a
  file browser walks a tree without ever building a full path.])

#cmd("GET_HOST_PREFIX", code: "$E0", dev: "E2 E0 n",
  aux: [#emph[byte]: the host slot, 0 to 7],
  payload: [none],
  reply: [256 bytes: the prefix, NUL-terminated inside],
  lib: [#cw("fuji_get_host_prefix(hs, buf)")],
  asm: "        lda     #FCGHPFX
        ldb     #0
        jsr     FNCMD1
        bne     FAILED
        ldx     #PFX
        ldy     #SZSPEC         ; 256
        jsr     FNGRSP",
  c: "char prefix[256];

if (fuji_get_host_prefix(0, prefix))
    printf(\"%s\\n\", prefix);",
  [Reads it back. Always 256 bytes on the wire whatever the string's
  length --- ask for fewer and the rest stays in the pipe.])

#sect[12.4 Directories]

#cmd("OPEN_DIRECTORY", code: "$F7", dev: "E2 F7 n + 256",
  aux: [#emph[byte]: the host slot, 0 to 7],
  payload: [256 bytes: the path, and optionally a NUL then a filename
    pattern then another NUL],
  reply: [none],
  lib: [#cw("fuji_open_directory(hs, path)") or
    #cw("fuji_open_directory2(hs, path, filter)")],
  asm: "*       \"/\" 00 \"*.dsk\" 00, padded to 256
        ldy     #ODPATH
        ldx     #MROOT
        jsr     SCOPY
        leay    1,y             ; over the NUL
        ldx     #MFILT
        jsr     SCOPY
        lda     HS
        sta     ODFRM+2
        ldx     #ODFRM
        ldy     #259
        jsr     FNXACT

ODFRM   fcb     OPFUJI,FCOPNDR,0
ODPATH  rmb     256",
  c: "/* path and pattern, in one field */
fuji_open_directory2(hs, \"/\", \"*.dsk\");

/* or the whole field verbatim */
fuji_open_directory(hs, path_and_pattern);",
  [Opens a directory for reading. The pattern is optional and goes after
  the path's terminating NUL inside the same 256-byte field, with its own
  NUL after it; the adapter only looks for one if there is room. Clear the
  field before you build it.])

#cmd("READ_DIR_ENTRY", code: "$F6", dev: "E2 F6 len flags",
  aux: [#emph[byte]: the most bytes you will accept, usually 36. \
    #emph[byte]: flags --- see below],
  payload: [none],
  reply: [as many bytes as the first aux byte said],
  lib: [#cw("fuji_read_directory(maxlen, flags, buf)")],
  asm: "*       two parameters, so FNCMD1 will not do
DIR1    ldx     #RDFRM
        ldy     #4
        jsr     FNXACT
        bne     DONE
        ldx     #ENTRY
        ldy     #36
        jsr     FNGRSP
        bne     DONE
        lda     ENTRY
        cmpa    #$7F            ; end of directory
        beq     DONE

RDFRM   fcb     OPFUJI,FCRDDIR,36,0",
  c: "char entry[37];

while (fuji_read_directory(36, 0, entry))
{
    if ((uint8_t) entry[0] == 0x7F)
        break;                  /* finished */
    printf(\"%s\\n\", entry);
}",
  [One entry per call, NUL-terminated inside the width you asked for.
  Directory names come back with a trailing slash. Two bytes of #hx("7F")
  mean there is nothing left.

  The flags byte: set bit 7 and the entry is prefixed with a 13-byte
  detail block --- year (#cw("tm_year")−100), month, day, hour, minute,
  second, then a four-byte size #strong[high byte first], then a
  directory flag (#hx("01")), a truncated flag (#hx("02")) and a media
  type. Set bits 7 and 6 together and the command switches to block mode:
  the length byte becomes a count of 256-byte pages, the low six bits of
  the flags become a group size, and the adapter packs as many entries as
  will fit into one transfer, behind a small header beginning #cw("'M'")
  #cw("'F'").])

#cmd("CLOSE_DIRECTORY", code: "$F5", dev: "E2 F5",
  aux: [none], payload: [none], reply: [none],
  lib: [#cw("fuji_close_directory()")],
  asm: "        lda     #FCCLSDR
        jsr     FNCMD0",
  c: "fuji_close_directory();",
  [Finishes with the directory. There is one directory handle for the
  whole adapter, so closing is not optional housekeeping --- the next
  #cw("OPEN_DIRECTORY") from anywhere depends on it.])

#cmd("GET_DIRECTORY_POSITION", code: "$E5", dev: "E2 E5",
  aux: [none], payload: [none],
  reply: [two bytes --- #strong[low byte first]],
  lib: [#cw("fuji_get_directory_position(&pos)")],
  asm: "        lda     #FCGDIRP
        jsr     FNCMD0
        bne     FAILED
        ldx     #POS
        ldy     #2
        jsr     FNGRSP
*       little-endian: POS is the low byte
        ldb     POS
        lda     POS+1",
  c: "uint16_t pos;

fuji_get_directory_position(&pos);
/* CMOC reads this big-endian: swap it */
pos = (pos >> 8) | (pos << 8);",
  [Where you are in the open directory, so that you can come back to it.

  #strong[This reply is little-endian], alone among the control device's
  two-byte values, because the firmware sends a raw host integer rather
  than a declared big-endian one. Its partner
  #cw("SET_DIRECTORY_POSITION") reads big-endian. Swap it on the way in or
  on the way out, but do not do both.])

#cmd("SET_DIRECTORY_POSITION", code: "$E4", dev: "E2 E4 hi lo",
  aux: [#emph[word]: the position, #strong[high byte first]],
  payload: [none], reply: [none],
  lib: [#cw("fuji_set_directory_position(pos)")],
  asm: "        ldd     #17
        std     SDPFRM+2
        ldx     #SDPFRM
        ldy     #4
        jsr     FNXACT

SDPFRM  fcb     OPFUJI,FCSDIRP
        fdb     0",
  c: "fuji_set_directory_position(17);",
  [Puts the read position back where #cw("GET_DIRECTORY_POSITION") found
  it. Big-endian here, little-endian there; the firmware is inconsistent
  and this card is the only warning you get.])

#sect[12.5 Device slots and mounting]

#cmd("READ_DEVICE_SLOTS", code: "$F2", dev: "E2 F2",
  aux: [none], payload: [none],
  reply: [152 bytes: four slots of 38 --- host slot, mode, #cw("file[36]")],
  lib: [#cw("fuji_get_device_slots(d, 4)")],
  asm: "        lda     #FCRDDS
        jsr     FNCMD0
        bne     FAILED
        ldx     #DRIVES
        ldy     #SZDEVS         ; 152
        jsr     FNGRSP
; slot n is at DRIVES + 38*n",
  c: "DeviceSlot drives[4];

if (fuji_get_device_slots(drives, 4))
    for (i = 0; i < 4; i++)
        printf(\"%u%c %s\\n\", i,
               (drives[i].mode & 0x40) ? '*' : ' ',
               drives[i].file);",
  [All four drives at once. Four, not eight --- the Color Computer build
  declares four disk devices where the Atari declares eight.

  The mode byte you read back is not the mode you set: the adapter ORs in
  #hx("40") when the drive is actually live and is not the CONFIG disk.
  That bit is the test for "is there a disk in it"; the low bits say how
  it was mounted.])

#cmd("WRITE_DEVICE_SLOTS", code: "$F1", dev: "E2 F1 + 152",
  aux: [none],
  payload: [152 bytes: all four slots, 38 each],
  reply: [none],
  lib: [#cw("fuji_put_device_slots(d, 4)")],
  asm: "        ldx     #WDFRM
        ldy     #154            ; 2 + 152
        jsr     FNXACT

WDFRM   fcb     OPFUJI,FCWRDS
WDSLOT  rmb     152",
  c: "DeviceSlot drives[4];

fuji_get_device_slots(drives, 4);
drives[1].hostSlot = 0;
drives[1].mode = 2;
strcpy((char *) drives[1].file, \"GAME.DSK\");
fuji_put_device_slots(drives, 4);",
  [Writes the configuration of all four back. This records what *should*
  be mounted; it does not mount anything. #cw("MOUNT_ALL") acts on what
  this left behind, which is how a configuration survives a power cycle.
  Clear the #hx("40") bit before writing a slot back --- it is the
  adapter's to set.])

#cmd("SET_DEVICE_FULLPATH", code: "$E2", dev: "E2 E2 ds hs mode + 256",
  aux: [#emph[byte]: the drive slot, 0 to 3. \
    #emph[byte]: the host slot, 0 to 7. \
    #emph[byte]: mode --- #hx("00") stores the name without opening it],
  payload: [256 bytes: the file name, NUL-padded],
  reply: [none],
  lib: [#cw("fuji_set_device_filename(mode, hs, ds, name)")],
  asm: "        lda     DS
        sta     SDFRM+2
        lda     HS
        sta     SDFRM+3
        clr     SDFRM+4         ; mode 0
        ldx     #SDFRM
        ldy     #261            ; 5 + 256
        jsr     FNXACT

SDFRM   fcb     OPFUJI,FCSDVFP,0,0,0
SDNAME  rmb     256",
  c: "/* note the argument order: mode first */
fuji_set_device_filename(0, hs, ds,
                         \"GAMES/ZAXXON.DSK\");",
  [Puts a file name into a drive slot. Note the three aux bytes are drive,
  host, mode --- in that order on the wire, which is not the order
  fujinet-lib's function takes them. The library reorders them for you;
  if you build the frame yourself, this card is the order that matters.])

#cmd("GET_DEVICE_FULLPATH", code: "$DA", dev: "E2 DA n",
  aux: [#emph[byte]: the drive slot, 0 to 3],
  payload: [none],
  reply: [256 bytes: the full path, NUL-terminated inside],
  lib: [#cw("fuji_get_device_filename(ds, buf)")],
  asm: "        lda     #FCGDVFP
        ldb     #0
        jsr     FNCMD1
        bne     FAILED
        ldx     #PATH
        ldy     #SZSPEC         ; 256
        jsr     FNGRSP",
  c: "char path[256];

if (fuji_get_device_filename(0, path))
    printf(\"%s\\n\", path);",
  [The whole path of what is in a drive, host prefix and all --- where the
  36-byte field in #cw("READ_DEVICE_SLOTS") gives you only the name, and
  truncated at that.])

#cmd("MOUNT_IMAGE", code: "$F8", dev: "E2 F8 ds mode",
  aux: [#emph[byte]: the drive slot, 0 to 3. \
    #emph[byte]: access --- #hx("01") read, #hx("02") read and write],
  payload: [none], reply: [none],
  lib: [#cw("fuji_mount_disk_image(ds, mode)")],
  asm: "        lda     DS
        sta     MIFRM+2
        lda     #2              ; read and write
        sta     MIFRM+3
        ldx     #MIFRM
        ldy     #4
        jsr     FNXACT
        bne     FAILED

MIFRM   fcb     OPFUJI,FCMNTIM,0,0",
  c: "if (!fuji_mount_disk_image(ds, 2))
    printf(\"NO: %u\\n\", fn_device_error);",
  [Opens the file named in the slot and starts serving it as a disk. Two
  parameters, so it needs its own frame in assembly. Mount read-only and a
  write fails at the disk layer, which is what you want for anything you
  are only booting from.])

#cmd("UNMOUNT_IMAGE", code: "$E9", dev: "E2 E9 n",
  aux: [#emph[byte]: the drive slot, 0 to 3],
  payload: [none], reply: [none],
  lib: [#cw("fuji_unmount_disk_image(ds)")],
  asm: "        lda     #FCUNMIM
        ldb     DS
        jsr     FNCMD1",
  c: "fuji_unmount_disk_image(ds);",
  [Closes the image and empties the drive. Close any BASIC file open on
  that drive first: the adapter will do as it is told, and DOS will go on
  believing there is a disk there.])

#cmd("MOUNT_ALL", code: "$D7", dev: "E2 D7",
  aux: [none], payload: [none], reply: [none],
  lib: [#cw("fuji_mount_all()")],
  asm: "        lda     #FCMNTAL
        jsr     FNCMD0
        bne     FAILED",
  c: "if (!fuji_mount_all())
    printf(\"SOMETHING DID NOT MOUNT\\n\");",
  [Mounts everything the four device slots already name, using each slot's
  own access mode. One call to put a saved configuration back, and the
  usual last step of a program that has just written the slots.])

#cmd("NEW_DISK", code: "$E7", dev: "E2 E7 + 259",
  aux: [none],
  payload: [259 bytes: disks, host slot, drive slot, then
    #cw("filename[256]")],
  reply: [none],
  lib: [#cw("fuji_create_new(&nd)")],
  asm: "        ldx     #NDFRM
        ldy     #261            ; 2 + 259
        jsr     FNXACT
        bne     FAILED

NDFRM   fcb     OPFUJI,FCNEWDK
NDNUM   fcb     1               ; one diskette
NDHOST  fcb     0
NDDRIVE fcb     1
NDNAME  rmb     256",
  c: "NewDisk nd;

memset(&nd, 0, sizeof(nd));
nd.numDisks = 1;
nd.hostSlot = 0;
nd.deviceSlot = 1;
strcpy(nd.filename, \"NEW.DSK\");

if (!fuji_create_new(&nd))
    printf(\"IT ALREADY EXISTS\\n\");",
  [Creates a blank image and mounts it read-write. This is one of the two
  commands on this bus with a Color-Computer-only payload: the Atari's
  version sends a sector count and a sector size.

  The first byte is a multiplier, not a size. Each unit is 315 blocks of
  512 bytes --- 161,280 bytes, exactly a 35-track, 18-sector,
  single-sided Disk BASIC diskette --- filled with #hx("FF"). The command
  fails rather than truncating if the file already exists.])

#cmd("COPY_FILE", code: "$D8", dev: "E2 D8 src dst + 256",
  aux: [#emph[byte]: the source host slot. \
    #emph[byte]: the destination host slot],
  payload: [256 bytes: #cw("sourcepath") NUL #cw("destpath") NUL],
  reply: [none],
  lib: [#cw("fuji_copy_file(src, dst, spec)")],
  asm: "*       see the caution --- do not send this
*       to a current adapter
        ldx     #CFFRM
        ldy     #260
        jsr     FNXACT

CFFRM   fcb     OPFUJI,FCCOPYF,0,0
CFSPEC  rmb     256",
  c: "/* fuji_copy_file(0, 1, \"A.DSK\\0B.DSK\"); */",
  [Copies a file from one host to another without it passing through the
  Computer.

  #strong[This command is broken on the DriveWire bus and will wedge it.]
  The handler asks for the payload as a string but nothing ever tells the
  frame decoder how long that payload is, so the adapter sees an empty
  copy-spec, gives up --- and leaves your 256 bytes sitting in its
  receive buffer, where they become the next command. There is no recovery
  short of a reset. fujinet-lib sends the payload faithfully, which is
  precisely the problem. Leave this one alone until the firmware calls
  #cw("setDataLength()") for it.])

#sect[12.6 Booting and resetting]

#cmd("SET_BOOT_MODE", code: "$D6", dev: "E2 D6 n",
  aux: [#emph[byte]: 0 #tt("/autorun.dsk") · 1 #tt("/mount-and-boot.dsk") ·
    2 the Game Lobby over TNFS · 3 #tt("/hisioboot-fujinet.dsk")],
  payload: [none], reply: [none],
  lib: [#cw("fuji_set_boot_mode(mode)")],
  asm: "        lda     #FCSBOOT
        ldb     #2              ; the lobby
        jsr     FNCMD1",
  c: "fuji_set_boot_mode(2);",
  [Chooses what the adapter serves as drive 0 when nothing else is
  mounted. Mode 2 fetches the Game Lobby from
  #cw("tnfs://tnfs.fujinet.online/COCO/lobby.dsk"), so it needs a
  network. On a Dragon it additionally arms the named-object path to
  #tt("/DGNLOBBY.DWL").])

#cmd("CONFIG_BOOT", code: "$D9", dev: "E2 D9 n",
  aux: [#emph[byte]: non-zero to keep the CONFIG disk, zero to stop
    inserting it],
  payload: [none], reply: [none],
  lib: [#cw("fuji_set_boot_config(toggle)")],
  asm: "        lda     #FCCFGBT
        clrb                    ; stop inserting CONFIG
        jsr     FNCMD1",
  c: "fuji_set_boot_config(0);",
  [Turns the CONFIG disk on and off. Turn it off when your own program
  should come up instead. Note that any of the three reset opcodes turns
  it straight back on --- deliberately, so that there is always a way
  back to a working machine.])

#cmd("RESET", code: "$FF", dev: "E2 FF",
  aux: [none], payload: [none],
  reply: [#strong[none, and no acknowledgement] --- the adapter reboots],
  lib: [#cw("fuji_reset()")],
  asm: "        lda     #FCRESET
        jsr     FNCMD0
*       do not expect the verdict to arrive",
  c: "fuji_reset();
/* everything after this is on a new adapter */",
  [Reboots the adapter. The handler calls the reboot directly without
  bracketing the transaction, so the verdict you politely ask for
  afterwards will never come. Send it and move on; give the adapter a
  few seconds and probe with #hx("A5") before you assume anything.

  Note that this is not the same as the bus-level reset opcodes
  #hx("F8"), #hx("FE") and #hx("FF") from Chapter 15 --- those re-arm the
  CONFIG disk without rebooting.])

#sect[12.7 App keys]

#block({
  set par(first-line-indent: 0pt, justify: true)
  [An app key is 64 bytes the adapter keeps for you between power cycles,
  filed under a creator ID, an application ID and a key number. The files
  land on the microSD card as #cw("/FujiNet/ccccaakk.key"), so a
  cartridge with no card in it cannot do this at all.]
})

#cmd("OPEN_APPKEY", code: "$DC", dev: "E2 DC + 6",
  aux: [none],
  payload: [6 bytes: #cw("creator") (word, high byte first), #cw("app"),
    #cw("key"), #cw("mode") --- 0 read, 1 write, 2 read 256 --- and a
    reserved byte],
  reply: [none],
  lib: [folded into #cw("fuji_read_appkey()") and
    #cw("fuji_write_appkey()")],
  asm: "        ldd     #$4321          ; creator
        std     AKFRM+2
        lda     #1              ; app
        sta     AKFRM+4
        lda     #7              ; key
        sta     AKFRM+5
        clr     AKFRM+6         ; mode 0: read
        clr     AKFRM+7
        ldx     #AKFRM
        ldy     #8              ; 2 + 6
        jsr     FNXACT

AKFRM   fcb     OPFUJI,FCOPAPK
        fdb     0               ; creator
        fcb     0,0,0,0         ; app,key,mode,rsvd",
  c: "fuji_set_appkey_details(0x4321, 1, DEFAULT);
/* the library opens and closes around
   each read or write */",
  [Names the key and says which way you are going. The creator word is
  big-endian on the wire, which on a 6809 means you simply store it.])

#cmd("READ_APPKEY", code: "$DD", dev: "E2 DD",
  aux: [none], payload: [none],
  reply: [66 bytes: a length (word, high byte first) then 64 bytes of data],
  lib: [#cw("fuji_read_appkey(key, &count, data)")],
  asm: "        lda     #FCRDAPK
        jsr     FNCMD0
        bne     FAILED
        ldx     #AKBUF
        ldy     #66
        jsr     FNGRSP
        ldd     AKBUF           ; the length
        leax    2,x             ; the data",
  c: "uint16_t count;
uint8_t data[66];

fuji_set_appkey_details(0x4321, 1, DEFAULT);
if (fuji_read_appkey(7, &count, data))
    /* count bytes are meaningful */;",
  [Reads the open key. Always 66 bytes on the wire; the length tells you
  how many of the 64 mean anything. The two-byte header is the Color
  Computer build's own addition --- other buses return the data alone.])

#cmd("WRITE_APPKEY", code: "$DE", dev: "E2 DE hi lo + 64",
  aux: [#emph[word]: how many bytes are meaningful, high byte first],
  payload: [#strong[always 64 bytes], whatever the length says],
  reply: [none],
  lib: [#cw("fuji_write_appkey(key, count, data)")],
  asm: "        ldd     #12             ; meaningful bytes
        std     WKFRM+2
        ldx     #WKFRM
        ldy     #68             ; 4 + 64
        jsr     FNXACT

WKFRM   fcb     OPFUJI,FCWRAPK
        fdb     0               ; length
WKDATA  rmb     64",
  c: "uint8_t data[64];

memset(data, 0, sizeof(data));
memcpy(data, \"HIGH SCORE 4820\", 15);
fuji_write_appkey(7, 15, data);",
  [Writes the open key.

  #strong[Send all sixty-four bytes.] The handler drains a full block
  regardless of the length you declared, and the firmware carries a
  comment saying so, which is how you know somebody found out the hard
  way. Send fewer and the adapter reads on into your next command.])

#cmd("CLOSE_APPKEY", code: "$DB", dev: "E2 DB",
  aux: [none], payload: [none], reply: [none],
  lib: [folded into the read and write calls],
  asm: "        lda     #FCCLAPK
        jsr     FNCMD0",
  c: "/* the library closes for you */",
  [Finishes with the key. One key is open at a time for the whole
  adapter.])

#sect[12.8 Base64]

#block({
  set par(first-line-indent: 0pt, justify: true)
  [Four commands each way, and the same shape both ways: feed the input,
  tell it to compute, ask how long the answer is, take the answer. The
  buffer lives on the adapter, so a 6809 never has to hold both forms of
  a string at once.]
})

#cmd("BASE64_ENCODE_INPUT / DECODE_INPUT", code: "$D0 / $CC",
  dev: "E2 D0 hi lo + len",
  aux: [#emph[word]: how many bytes follow, high byte first. Zero is
    refused],
  payload: [that many bytes],
  reply: [none],
  lib: [#cw("fuji_base64_encode_input(s, len)") ·
    #cw("fuji_base64_decode_input(s, len)")],
  asm: "        ldd     #TEXTLEN
        std     B64FRM+2
        ldx     #B64FRM
        ldy     #4
        jsr     FNWAIT
        jsr     [DWWRITV]       ; the header
        ldx     #TEXT
        ldy     #TEXTLEN
        jsr     [DWWRITV]       ; the payload
        jsr     FNGERR

B64FRM  fcb     OPFUJI,FCB64EI
        fdb     0",
  c: "fuji_base64_encode_input(text, strlen(text));",
  [Appends to the adapter's buffer, so call it as many times as you like
  to build a long input a piece at a time.])

#cmd("BASE64_ENCODE_COMPUTE / DECODE_COMPUTE", code: "$CF / $CB",
  dev: "E2 CF",
  aux: [none], payload: [none], reply: [none],
  lib: [#cw("fuji_base64_encode_compute()") ·
    #cw("fuji_base64_decode_compute()")],
  asm: "        lda     #FCB64EC
        jsr     FNCMD0
        bne     FAILED",
  c: "if (!fuji_base64_encode_compute())
    fail();",
  [Transforms the buffer in place. Input becomes output; there is one
  buffer and this is the moment it changes meaning.])

#cmd("BASE64_ENCODE_LENGTH / DECODE_LENGTH", code: "$CE / $CA",
  dev: "E2 CE",
  aux: [none], payload: [none],
  reply: [4 bytes, #strong[high byte first]],
  lib: [#cw("fuji_base64_encode_length(&len)") ·
    #cw("fuji_base64_decode_length(&len)")],
  asm: "        lda     #FCB64EL
        jsr     FNCMD0
        bne     FAILED
        ldx     #B64LEN
        ldy     #4
        jsr     FNGRSP
*       B64LEN+2,+3 is the useful half",
  c: "unsigned long len;

fuji_base64_encode_length(&len);",
  [How long the result is. Four bytes because the adapter's buffer can be
  bigger than a Color Computer's memory; the top two will be zero for
  anything you can hold.])

#cmd("BASE64_ENCODE_OUTPUT / DECODE_OUTPUT", code: "$CD / $C9",
  dev: "E2 CD hi lo",
  aux: [#emph[word]: how many bytes to take, high byte first. Zero, or
    more than the buffer holds, is refused],
  payload: [none],
  reply: [that many bytes],
  lib: [#cw("fuji_base64_encode_output(s, len)") --- #strong[but see below]],
  asm: "        ldd     #64             ; the aux word
        std     B64OUT+2
        ldx     #B64OUT
        ldy     #4              ; 2 + 2 --- not 2
        jsr     FNXACT
        bne     FAILED
        ldx     #BUF
        ldy     #64
        jsr     FNGRSP

B64OUT  fcb     OPFUJI,FCB64EO
        fdb     0",
  c: "/* fujinet-lib's output calls send no aux
   word; the firmware reads two bytes
   regardless and eats the front of your
   next command.  Send the frame. */
struct { uint8_t op, cmd; uint16_t len; } f;

f.op = 0xE2; f.cmd = 0xCD; f.len = 64;
bus_ready();
dwwrite((uint8_t *) &f, sizeof(f));
if (!fuji_get_error())
    fuji_get_response(buf, 64);",
  [Takes bytes off the front of the buffer and removes them, so repeated
  calls walk a long result through a small Computer.

  #strong[The Color Computer build of fujinet-lib does not send the aux
  word] on either output call. The firmware reads it anyway, so two bytes
  of whatever you send next are consumed as the length and the bus goes
  out of step. Build the four-byte frame yourself until that is fixed;
  the same applies to #cw("QRCODE_OUTPUT").])

#sect[12.9 Hashing]

#cmd("HASH_INPUT", code: "$C8", dev: "E2 C8 hi lo + len",
  aux: [#emph[word]: how many bytes follow, high byte first. Zero is
    refused],
  payload: [that many bytes],
  reply: [none],
  lib: [#cw("fuji_hash_input(s, len)")],
  asm: "        ldd     #LEN
        std     HIFRM+2
        ldx     #HIFRM
        ldy     #4
        jsr     FNWAIT
        jsr     [DWWRITV]
        ldx     #DATA
        ldy     #LEN
        jsr     [DWWRITV]
        jsr     FNGERR

HIFRM   fcb     OPFUJI,FCHASHI
        fdb     0",
  c: "fuji_hash_input(buf, len);   /* repeatable */",
  [Adds to the data to be hashed. Call it as often as you like to hash
  something larger than your buffers --- a whole disk, if you have the
  patience.])

#cmd("HASH_COMPUTE", code: "$C7", dev: "E2 C7 algo",
  aux: [#emph[byte]: 0 MD5 · 1 SHA-1 · 2 SHA-256 · 3 SHA-512],
  payload: [none], reply: [none],
  lib: [#cw("fuji_hash_compute(type)")],
  asm: "        lda     #FCHASHC
        ldb     #2              ; SHA-256
        jsr     FNCMD1
        bne     FAILED",
  c: "fuji_hash_compute(2);        /* SHA-256 */",
  [Hashes what you fed it and clears the input. The algorithm you name
  here is remembered, and #cw("HASH_LENGTH") and #cw("HASH_OUTPUT") use
  it.])

#cmd("HASH_COMPUTE_NO_CLEAR", code: "$C3", dev: "E2 C3 algo",
  aux: [#emph[byte]: the algorithm, as above],
  payload: [none], reply: [none],
  lib: [#cw("fuji_hash_compute_no_clear(type)")],
  asm: "        lda     #FCHASHN
        ldb     #2
        jsr     FNCMD1",
  c: "fuji_hash_compute_no_clear(2);",
  [The same, but keeps the input. Hash a growing message at several points
  without feeding it again --- and the reason it is a separate opcode
  rather than a flag is that the handler decides by looking at which
  command byte arrived.])

#cmd("HASH_LENGTH", code: "$C6", dev: "E2 C6 mode",
  aux: [#emph[byte]: 1 for hexadecimal text, anything else for raw bytes],
  payload: [none],
  reply: [one byte: how long the output will be],
  lib: [#strong[none] --- #cw("fuji_hash_length()") returns false without
    sending anything],
  asm: "        lda     #FCHASHL
        ldb     #1              ; hex text
        jsr     FNCMD1
        bne     FAILED
        ldx     #HLEN
        ldy     #1
        jsr     FNGRSP",
  c: "struct { uint8_t op, cmd, mode; } f;
uint8_t len;

f.op = 0xE2; f.cmd = 0xC6; f.mode = 1;
bus_ready();
dwwrite((uint8_t *) &f, sizeof(f));
if (!fuji_get_error())
    fuji_get_response(&len, 1);",
  [How many bytes #cw("HASH_OUTPUT") will give you: 16 for MD5 raw and 32
  as hex, 20 and 40 for SHA-1, 32 and 64 for SHA-256, 64 and 128 for
  SHA-512. You can compute these yourself, which is presumably why the
  library's version is a stub that returns false without sending
  anything. The three-byte frame above works.])

#cmd("HASH_OUTPUT", code: "$C5", dev: "E2 C5 mode",
  aux: [#emph[byte]: 1 for hexadecimal text, anything else for raw bytes],
  payload: [none],
  reply: [the hash, as many bytes as #cw("HASH_LENGTH") said],
  lib: [#cw("fuji_hash_output(mode, s, len)")],
  asm: "        lda     #FCHASHO
        ldb     #1              ; hex text
        jsr     FNCMD1
        bne     FAILED
        ldx     #HASH
        ldy     #64             ; SHA-256 as hex
        jsr     FNGRSP",
  c: "char hash[65];

fuji_hash_output(1, hash, 64);
hash[64] = '\\0';
printf(\"%s\\n\", hash);",
  [The result. Ask for hexadecimal unless you are going to compare it
  rather than print it: the Color Computer's screen has no way to show a
  raw #hx("00").])

#cmd("HASH_CLEAR", code: "$C2", dev: "E2 C2",
  aux: [none], payload: [none], reply: [none],
  lib: [#cw("fuji_hash_clear()")],
  asm: "        lda     #FCHASHZ
        jsr     FNCMD0",
  c: "fuji_hash_clear();",
  [Throws away the accumulated input. Start again.])

#sect[12.10 QR codes]

#cmd("QRCODE_INPUT", code: "$BC", dev: "E2 BC hi lo + len",
  aux: [#emph[word]: how many bytes follow, high byte first],
  payload: [that many bytes --- the text to encode],
  reply: [none],
  lib: [#cw("fuji_qrcode_input(s, len)")],
  asm: "        ldd     #URLLEN
        std     QIFRM+2
        ldx     #QIFRM
        ldy     #4
        jsr     FNWAIT
        jsr     [DWWRITV]
        ldx     #URL
        ldy     #URLLEN
        jsr     [DWWRITV]
        jsr     FNGERR

QIFRM   fcb     OPFUJI,FCQRINP
        fdb     0",
  c: "fuji_qrcode_input(url, strlen(url));",
  [The text the code will carry. Appends, like the other input commands.])

#cmd("QRCODE_ENCODE", code: "$BD", dev: "E2 BD ver ecc short",
  aux: [#emph[byte]: version, masked to 0--127; 0 chooses one. \
    #emph[byte]: error correction, masked to 0--3 --- low, medium,
    quartile, high. \
    #emph[byte]: non-zero to shorten the text through the adapter's own
    URL shortener first],
  payload: [none], reply: [none],
  lib: [#cw("fuji_qrcode_encode(version, ecc, shorten)")],
  asm: "        clr     QEFRM+2         ; pick a version
        lda     #1              ; medium ecc
        sta     QEFRM+3
        clr     QEFRM+4         ; do not shorten
        ldx     #QEFRM
        ldy     #5
        jsr     FNXACT

QEFRM   fcb     OPFUJI,FCQRENC,0,0,0",
  c: "fuji_qrcode_encode(0, 1, false);",
  [Renders the matrix. The output mode starts as binary; asking
  #cw("QRCODE_LENGTH") for a different one re-renders from the same
  matrix, so you do not have to encode twice to get two formats.])

#cmd("QRCODE_LENGTH", code: "$BE", dev: "E2 BE mode",
  aux: [#emph[byte]: output mode --- 0 binary · 1 ANSI · 2 bitmap ·
    3 SVG · 4 ATASCII · 5 PETSCII],
  payload: [none],
  reply: [4 bytes, high byte first],
  lib: [#cw("fuji_qrcode_length(mode, &len)")],
  asm: "        lda     #FCQRLEN
        ldb     #2              ; bitmap
        jsr     FNCMD1
        bne     FAILED
        ldx     #QLEN
        ldy     #4
        jsr     FNGRSP",
  c: "unsigned long len;

fuji_qrcode_length(2, &len);   /* bitmap */",
  [How big the rendered code is in the mode you asked for --- and asking
  changes the mode. Binary gives you one byte per module, which is what
  you want if you are going to paint it into a PMODE screen yourself.])

#cmd("QRCODE_OUTPUT", code: "$BF", dev: "E2 BF hi lo",
  aux: [#emph[word]: how many bytes to take, high byte first],
  payload: [none],
  reply: [that many bytes],
  lib: [#cw("fuji_qrcode_output(s, len)") --- #strong[sends no aux word]],
  asm: "        ldd     QLEN+2
        std     QOFRM+2
        ldx     #QOFRM
        ldy     #4
        jsr     FNXACT
        bne     FAILED
        ldx     #QRBUF
        ldy     QLEN+2
        jsr     FNGRSP

QOFRM   fcb     OPFUJI,FCQROUT
        fdb     0",
  c: "struct { uint8_t op, cmd; uint16_t len; } f;

f.op = 0xE2; f.cmd = 0xBF; f.len = qlen;
bus_ready();
dwwrite((uint8_t *) &f, sizeof(f));
if (!fuji_get_error())
    fuji_get_response(qrbuf, qlen);",
  [Takes the rendered code. The same aux-word problem as the base64
  output commands: the library sends no length, the firmware reads two
  bytes anyway, and your next command loses its front. Build the frame.])

#sect[12.11 Odds and ends]

#cmd("RANDOM_NUMBER", code: "$D3", dev: "E2 D3",
  aux: [none], payload: [none],
  reply: [4 bytes --- #strong[low byte first]],
  lib: [none],
  asm: "        lda     #FCRANDM
        jsr     FNCMD0
        bne     FAILED
        ldx     #RND
        ldy     #4
        jsr     FNGRSP
*       little-endian: RND+0 is the low byte",
  c: "struct { uint8_t op, cmd; } f;
uint8_t r[4];

f.op = 0xE2; f.cmd = 0xD3;
bus_ready();
dwwrite((uint8_t *) &f, sizeof(f));
if (!fuji_get_error())
    fuji_get_response(r, 4);
/* r[0] is the low byte */",
  [Four bytes of entropy from the ESP32's hardware generator, which is a
  better source than anything you can synthesise on a machine with no
  clock. #strong[This reply is little-endian] --- the firmware sends a raw
  host integer. If you only want a die roll, take one byte and the
  question does not arise.])

#cmd("GENERATE_GUID", code: "$BB", dev: "E2 BB",
  aux: [none], payload: [none],
  reply: [37 bytes: a UUIDv4 as text, with its terminator],
  lib: [#cw("fuji_generate_guid(buf)")],
  asm: "        lda     #FCGUID
        jsr     FNCMD0
        bne     FAILED
        ldx     #GUID
        ldy     #SZGUID         ; 37
        jsr     FNGRSP
        ldx     #GUID
        jsr     PUTS",
  c: "char guid[37];

if (fuji_generate_guid(guid))
    printf(\"%s\\n\", guid);",
  [A fresh UUID, in the usual dashed text form. Thirty-six characters and
  a NUL, and it takes four lines of 6809 instead of four hundred.])

#cmd("STATUS", code: "$53  'S'", dev: "E2 53",
  aux: [none], payload: [none],
  reply: [4 bytes, all zero],
  lib: [#cw("fuji_status(&s)"), which sends nothing and returns true],
  asm: "        lda     #FCSTAT
        jsr     FNCMD0
        bne     FAILED
        ldx     #ST
        ldy     #4
        jsr     FNGRSP",
  c: "/* it answers, but it has nothing to say */",
  [Reserved. It is dispatched, it answers, and the four bytes it sends are
  always zero --- the handler is a stub on every bus. It is documented
  here because it is dispatched, and a reference that lists only the
  commands that do something is a reference you cannot trust.])

#sect[12.12 Answered with silence on this platform]

#block({
  set par(first-line-indent: 0pt, justify: true)
  [These command bytes exist in the firmware's command table and are
  #strong[not] dispatched on the DriveWire bus. None of them needs an
  example, and every one of them is a trap, for a reason worth setting
  out plainly.

  A command that reaches no handler does nothing at all: the adapter
  sends no reply, raises no error, and --- because the Color Computer's
  dispatcher clears the error code to #emph[success] before it looks for
  a handler --- a #cw("SEND_ERROR") afterwards answers #hx("01"). The
  command that did nothing reports that it worked.

  Worse, if the command had aux bytes or a payload, the adapter never
  read them. They are still in its receive buffer, and they will be read
  as the front of whatever you send next. So an unrecognised command with
  a payload does not merely fail quietly; it desynchronises the bus for
  the rest of the session.

  The list, so that you can tell a command that is not implemented from
  one you spelled wrong:]
})

#dotdef(
  (hx("F0") + "  ENABLE_UDPSTREAM", [the Atari's MIDI-over-UDP mode]),
  (hx("EB") + "  SET_BAUDRATE", [SIO bus tuning]),
  (hx("E3") + "  SET_HSIO_INDEX", [high-speed SIO tuning]),
  (hx("DF") + "  SET_SIO_EXTERNAL_CLOCK", [SIO clocking]),
  (hx("D5") + "  ENABLE_DEVICE", [device rotation, a no-op stub on this bus]),
  (hx("D4") + "  DISABLE_DEVICE", [the same]),
  (hx("D2") + "  GET_TIME", [use device #hx("E5") or the #hx("23") opcode --- Chapter 14]),
  (hx("D1") + "  DEVICE_ENABLE_STATUS", [device rotation again]),
  (hx("C1") + "  GET_HEAP", [a diagnostic, on other buses]),
  (hx("A0") + [--] + hx("A9") + [  GET_DEVICE1..10_FULLPATH],
   [use #hx("DA") with the slot in its aux byte]),
  (hx("90") + "  UPDATE_FIRMWARE", [over the web interface, not the wire]),
  (hx("3F") + "  HSIO_INDEX", [SIO again]),
  (hx("06") + " / " + hx("15") + "  ACK / NAK", [SIO frame markers; this bus
   has no frame markers]),
)

#block({
  set par(first-line-indent: 0pt, justify: true)
  [fujinet-lib ships Color Computer stubs for several of these ---
  #cw("fuji_enable_device()"), #cw("fuji_disable_device()"),
  #cw("fuji_get_device_enabled_status()"), #cw("fuji_get_hsio_index()"),
  #cw("fuji_set_hsio_index()"), #cw("fuji_enable_udpstream()"),
  #cw("fuji_status()") --- which return true without sending anything.
  That is the right behaviour for a portable library and a confusing one
  if you have not read this page: your program will believe it enabled a
  device. It did not; there was nothing to enable.]
})

#gbar

// ============================================================
// 13. COMMAND REFERENCE: THE NETWORK DEVICE
// ============================================================
#chapter("13. Command Reference: The Network Device",
  subs: ("The lifecycle five", "Line discipline and position",
         "Parsers and queries", "Filesystem operations",
         "Sockets and credentials", "Answered with an error"))
#ix("Network device commands", "Command reference, network")

#block({
  set par(first-line-indent: 0pt, justify: true)
  [Every command device #hx("E3") answers, verified against the unified
  network device in #cw("NDevice.cpp") and cross-checked against the
  fujinet-lib Color Computer port.

  Conventions as in Chapter 12, with one addition that applies to every
  card here: #strong[the frame always carries a unit byte and exactly two
  aux bytes], whether the command uses them or not. A command with no
  parameters is still five bytes. The frame decoder consumes that pair
  before it will hand a handler any payload, and consumes it on the way
  out if nothing else did.

  Unlike the control device, an unrecognised command here is a clean
  failure: the dispatcher calls the error path, so #cw("SEND_ERROR")
  answers #hx("90") and the bus stays in step.]
})

#sect[13.1 The lifecycle five]

#cmd("OPEN", code: "$4F  'O'", dev: "E3 unit 4F mode trans + 256",
  aux: [#emph[byte]: the open mode --- #hx("04") read, #hx("06")
    directory, #hx("07") directory alternate, #hx("08") write, #hx("09")
    append, #hx("0C") read and write; for HTTP the same byte is the
    method. \
    #emph[byte]: translation --- #hx("00") none, #hx("01") CR, #hx("02")
    LF, #hx("03") CR LF, #hx("04") PETSCII],
  payload: [256 bytes: the devicespec, NUL-padded],
  reply: [none],
  lib: [#cw("network_open(spec, mode, trans)")],
  asm: "        ldx     #SPEC
        lda     #OMRW
        ldb     #TRNONE
        jsr     NTOPEN
        bne     BADOPEN
*       NTOPEN parses the unit out of SPEC,
*       clears the 256-byte field and pads",
  c: "if (network_open(\"N:TCP://host:6502/\",
                 OPEN_MODE_RW,
                 OPEN_TRANS_NONE) != FN_ERR_OK)
    fail(fn_device_error);",
  [Instantiates the protocol named by the scheme and connects it. If a
  channel is already open on this unit it is closed first, so a second
  #cw("OPEN") is a reconnect rather than an error.

  The devicespec field is a fixed 256 bytes whatever the string's length.
  Pad it. A short field leaves the adapter reading on into your next
  command and there is no recovery.])

#cmd("CLOSE", code: "$43  'C'", dev: "E3 unit 43 00 00",
  aux: [two bytes, ignored --- send zeros],
  payload: [none], reply: [none],
  lib: [#cw("network_close(spec)")],
  asm: "        jsr     NTCLOS
*       or, for a unit you are tracking:
        ldb     UNIT
        stb     CFRM+1
        ldx     #CFRM
        ldy     #5
        jsr     NTXACT
CFRM    fcb     OPNET,0,NCCLOSE,0,0",
  c: "network_close(spec);",
  [Closes the channel and destroys the protocol. Always close: a channel
  left open holds a socket on the adapter, and the adapter has a finite
  number of them.])

#cmd("STATUS", code: "$53  'S'", dev: "E3 unit 53 00 00",
  aux: [two bytes, ignored],
  payload: [none],
  reply: [4 bytes: bytes waiting (word, #strong[high byte first]),
    connected, the channel's error byte],
  lib: [#cw("network_status(spec, &bw, &conn, &err)")],
  asm: "        ldx     #STBUF
        jsr     NTSTAT
        bne     BADIO
        ldd     STBUF           ; big-endian: LDD
        lda     STBUF+2         ; connected
        lda     STBUF+3         ; error",
  c: "uint16_t bw;
uint8_t conn, err;

network_status(spec, &bw, &conn, &err);
if (err == 136)                /* end of file */
    done();",
  [The whole state of a channel in four bytes, and the command you call
  most. Ask it before every read and read no more than it said.

  Zero waiting is not an error --- it is the usual state of a quiet
  socket. The end of a resource is an error byte of 136, or zero waiting
  with the connected byte clear.

  With no protocol open at all this answers 207, not connected.])

#cmd("READ", code: "$52  'R'", dev: "E3 unit 52 hi lo",
  aux: [#emph[word]: how many bytes to read, high byte first],
  payload: [none],
  reply: [that many bytes, through #cw("SEND_RESPONSE")],
  lib: [#cw("network_read(spec, buf, len)") --- blocking, or
    #cw("network_read_nb()")],
  asm: "        ldx     #RXBUF
        ldy     #64
        jsr     NTREAD
        bne     BADIO",
  c: "int16_t n = network_read(spec, buf, want);

if (n < 0)
    fail(fn_device_error);      /* negative */",
  [Takes bytes out of the channel. Ask for no more than #cw("STATUS")
  said was waiting: the adapter pads the reply with zeros up to the
  length you named, and the zeros are indistinguishable from data.

  The length goes out twice --- once in this command's aux word and again
  in the #cw("SEND_RESPONSE") that collects the bytes. The library's
  blocking #cw("network_read()") loops on #cw("STATUS") until it has
  everything you asked for or hits end of file, so it is the wrong call
  for an interactive program; ask #cw("STATUS") yourself and read what is
  there.])

#cmd("WRITE", code: "$57  'W'", dev: "E3 unit 57 hi lo + len",
  aux: [#emph[word]: how many bytes follow, high byte first],
  payload: [that many bytes],
  reply: [none],
  lib: [#cw("network_write(spec, buf, len)")],
  asm: "        ldx     #TXBUF
        ldy     #TXLEN
        jsr     NTWRIT
        bne     BADIO
*       NTWRIT sends the header, then the
*       payload as a second DriveWire write",
  c: "network_write(spec, (uint8_t *) line,
              strlen(line));",
  [Puts bytes into the channel. The header goes out first and the payload
  follows as a separate write --- the adapter is already counting, so
  there is no need to build one buffer out of two.])

#sect[13.2 Line discipline and position]

#cmd("TRANSLATION", code: "$54  'T'", dev: "E3 unit 54 00 mode",
  aux: [#emph[byte], ignored. \
    #emph[byte]: the translation mode --- #strong[aux2, not aux1]],
  payload: [none], reply: [none],
  lib: [none],
  asm: "        ldb     NTUNI
        stb     TRFRM+1
        ldx     #TRFRM
        ldy     #5
        jsr     NTXACT

TRFRM   fcb     OPNET,0,NCTRANS,0,TRCR",
  c: "struct { uint8_t op,unit,cmd,a1,a2; } f;

f.op = 0xE3; f.unit = unit;
f.cmd = 'T'; f.a1 = 0;
f.a2 = 1;                       /* CR */
bus_ready();
dwwrite((uint8_t *) &f, sizeof(f));
e = network_get_error(unit);",
  [Overrides the translation mode set at #cw("OPEN"), for the life of the
  channel. #strong[The mode is read from aux2.] A value of #hx("FF") is
  the escape hatch that suppresses the override entirely.])

#cmd("SET_EOL", code: "$4C  'L'", dev: "E3 unit 4C hi lo + len",
  aux: [#emph[word]: how many bytes of line ending follow, high byte first],
  payload: [that many bytes],
  reply: [none],
  lib: [none],
  asm: "        ldd     #1
        std     ELFRM+3
        ldb     NTUNI
        stb     ELFRM+1
        ldx     #ELFRM
        ldy     #5
        jsr     FNWAIT
        jsr     [DWWRITV]
        ldx     #ELBYTE
        ldy     #1
        jsr     [DWWRITV]
        ldb     NTUNI
        jsr     NTGERR

ELFRM   fcb     OPNET,0,NCSETEL,0,0
ELBYTE  fcb     13",
  c: "struct { uint8_t op,unit,cmd;
         uint16_t len; } f;
uint8_t eol = 13;

f.op = 0xE3; f.unit = unit;
f.cmd = 'L'; f.len = 1;
bus_ready();
dwwrite((uint8_t *) &f, sizeof(f));
dwwrite(&eol, 1);
e = network_get_error(unit);",
  [Sets the byte or bytes the protocol should treat as a line ending on
  this channel. A zero length clears the override and puts the
  platform's own ending back --- on the Color Computer that is a single
  carriage return, #hx("0D"), which is usually what you wanted anyway.])

#cmd("SET_INT_RATE", code: "$5A  'Z'", dev: "E3 unit 5A rate 00",
  aux: [#emph[byte]: milliseconds between checks],
  payload: [none], reply: [none],
  lib: [none],
  asm: "        ldb     NTUNI
        stb     IRFRM+1
        ldx     #IRFRM
        ldy     #5
        jsr     NTXACT

IRFRM   fcb     OPNET,0,NCINTRT,50,0",
  c: "f.op = 0xE3; f.unit = unit;
f.cmd = 'Z'; f.a1 = 50; f.a2 = 0;
bus_ready();
dwwrite((uint8_t *) &f, sizeof(f));",
  [How often the adapter looks to see whether this channel has anything,
  for the purpose of raising the serial line. The default is 100
  milliseconds on hardware and 20 on FujiNet-PC. It has no effect at all
  over DriveWire-over-IP, where there is no line to raise.])

#cmd("SEEK", code: "$25  '%'", dev: "E3 unit 25 + 4",
  aux: [#emph[a four-byte offset], high byte first --- #strong[not the
    usual two]],
  payload: [none], reply: [none],
  lib: [none],
  asm: "*       the one command on this device whose
*       parameter is four bytes, not two
        ldb     NTUNI
        stb     SKFRM+1
        ldd     #0
        std     SKFRM+3
        ldd     #1024
        std     SKFRM+5
        ldx     #SKFRM
        ldy     #7
        jsr     NTXACT

SKFRM   fcb     OPNET,0,NCSEEK
        fqb     0",
  c: "struct { uint8_t op,unit,cmd;
         uint32_t off; } f;

f.op = 0xE3; f.unit = unit;
f.cmd = '%'; f.off = 1024;      /* big-endian */
bus_ready();
dwwrite((uint8_t *) &f, sizeof(f));
e = network_get_error(unit);",
  [Moves the read position within whatever the channel's parser is
  holding.

  #strong[This is the exception to the two-aux-byte rule.] The handler
  asks for a 32-bit parameter, so the decoder reads four bytes here and
  not two, and the frame is seven bytes rather than five. Send five and
  the adapter takes the front of your next command as the rest of the
  offset.])

#cmd("TELL", code: "$26  '&'", dev: "E3 unit 26 00 00",
  aux: [two bytes, ignored],
  payload: [none],
  reply: [4 bytes --- #strong[low byte first]],
  lib: [none],
  asm: "        ldb     NTUNI
        stb     TLFRM+1
        ldx     #TLFRM
        ldy     #5
        jsr     NTXACT
        bne     BADIO
        ldb     NTUNI
        ldx     #POS
        ldy     #4
        jsr     NTGRSP
*       POS+0 is the low byte

TLFRM   fcb     OPNET,0,NCTELL,0,0",
  c: "uint8_t pos[4];
/* ... send the frame ... */
network_get_response(unit, pos, 4);
/* pos[0] is the low byte */",
  [Where the read position is. #strong[The reply is little-endian] --- the
  firmware declares it that way explicitly --- while #cw("SEEK") takes
  its offset big-endian. The two do not match and this card is the only
  warning.

  With no parser on the channel the offset is zero.])

#sect[13.3 Parsers and queries]

#cmd("SET_PARSER", code: "$FC", dev: "E3 unit FC 00 mode",
  aux: [#emph[byte], ignored. \
    #emph[byte]: 0 none · 1 JSON · 2 HTML · 3 XML --- #strong[aux2, not
    aux1]],
  payload: [none], reply: [none],
  lib: [#cw("network_json_parse()") sends this --- #strong[in the wrong
    aux byte]],
  asm: "        lda     NTUNI
        sta     SPFRM+1
        ldx     #SPFRM
        ldy     #5
        ldb     NTUNI
        jsr     NTXACT

SPFRM   fcb     OPNET,0,NCSPARS,0,PMJSON",
  c: "struct { uint8_t op,unit,cmd,a1,a2; } f;

f.op = 0xE3; f.unit = unit;
f.cmd = 0xFC;
f.a1 = 0;
f.a2 = 1;                       /* JSON */
bus_ready();
dwwrite((uint8_t *) &f, sizeof(f));
e = network_get_error(unit);",
  [Puts a parser on the channel. HTML is queried with a CSS selector and
  XML with a subset of XPath; JSON is the one you will use.

  #strong[The mode is read from aux2.] fujinet-lib's
  #cw("network_json_parse()") puts it in aux1 and leaves aux2 zero, which
  selects the null parser --- so on a current adapter that call appears
  to succeed and then every query comes back empty. Send the five bytes
  above instead. Chapter 18 does.])

#cmd("PARSE", code: "$50  'P'", dev: "E3 unit 50 00 00",
  aux: [two bytes, ignored],
  payload: [none], reply: [none],
  lib: [the second half of #cw("network_json_parse()")],
  asm: "        lda     NTUNI
        sta     PAFRM+1
        ldx     #PAFRM
        ldy     #5
        ldb     NTUNI
        jsr     NTXACT

PAFRM   fcb     OPNET,0,NCPARSE,0,0",
  c: "f.cmd = 'P'; f.a1 = f.a2 = 0;
bus_ready();
dwwrite((uint8_t *) &f, sizeof(f));
e = network_get_error(unit);",
  [Reads the channel to the end and hands the lot to the parser. After
  this the document lives on the adapter and the channel's contents are
  whatever the last query selected. It is the moment a 64-kilobyte
  machine stops caring how big the response was.

  Errors here are real: 213 means the document would not parse.])

#cmd("QUERY", code: "$51  'Q'", dev: "E3 unit 51 00 00 + 256",
  aux: [two bytes, ignored],
  payload: [256 bytes: the query, NUL-padded],
  reply: [none directly --- the result becomes the channel's contents,
    so ask #cw("STATUS") and then #cw("READ")],
  lib: [#cw("network_json_query(spec, query, buf)")],
  asm: "        ldx     #QYSTR          ; cleared, then
        ...                     ; the query copied in
        lda     NTUNI
        sta     QYFRM+1
        ldx     #QYFRM
        ldy     #QYLEN          ; 5 + 256
        ldb     NTUNI
        jsr     NTXACT
*       then NTSTAT and NTREAD

QYFRM   fcb     OPNET,0,NCQUERY,0,0
QYSTR   rmb     256",
  c: "char answer[64];
int16_t n = network_json_query(spec,
                 \"/current/temperature_2m\",
                 answer);
if (n > 0)
    printf(\"%s\\n\", answer);",
  [Selects part of the parsed document. A JSON query is a path like
  #cw("/current/temperature_2m")\; the result replaces the channel's
  contents, so the sequence is query, status, read.

  Note the order of checks in the firmware: the 256-byte payload is
  drained #emph[before] it complains that there is no parser, precisely so
  that a query sent too early fails cleanly instead of wedging the bus.])

#cmd("SET_PARAMETER", code: "$FB", dev: "E3 unit FB type value",
  aux: [#emph[byte]: 0 sets the query flags, 1 sets the parser's line
    ending. \
    #emph[byte]: the value],
  payload: [none], reply: [none],
  lib: [none],
  asm: "        lda     NTUNI
        sta     SQFRM+1
        ldx     #SQFRM
        ldy     #5
        ldb     NTUNI
        jsr     NTXACT

SQFRM   fcb     OPNET,0,NCSPARM,0,$10",
  c: "f.cmd = 0xFB;
f.a1 = 0;                       /* query flags */
f.a2 = 0x10;                    /* ASCII output */
bus_ready();
dwwrite((uint8_t *) &f, sizeof(f));",
  [Tunes the parser. With a type of 0 the value is a flags byte: the low
  three bits ask for character remapping (#hx("01")), international
  ATASCII remapping (#hx("02")) and the stripping of SGML tags (#hx("04"),
  JSON only), and bits 4 and 5 choose the output form --- #hx("00")
  verbatim or #hx("10") ASCII. #hx("20") and #hx("30") are reserved and
  are rejected.

  With a type of 1 the value is a single byte to use as the parser's line
  ending. Any other type is an error. This command needs a parser already
  set; without one it fails.])

#cmd("SET_HTTP_MODE", code: "$4D  'M'", dev: "E3 unit 4D 00 mode",
  aux: [#emph[byte], ignored. \
    #emph[byte]: 0 body · 1 collect response headers · 2 read the
    collected headers · 3 set a request header · 4 set the POST data
    --- #strong[aux2]],
  payload: [none], reply: [none],
  lib: [#cw("network_http_set_channel_mode(spec, mode)")],
  asm: "        lda     NTUNI
        sta     HMFRM+1
        ldx     #HMFRM
        ldy     #5
        ldb     NTUNI
        jsr     NTXACT

HMFRM   fcb     OPNET,0,NCHTTPM,0,HMSETH",
  c: "network_http_set_channel_mode(spec, 3);
network_write(spec,
    (uint8_t *) \"Accept: application/json\", 24);
network_http_set_channel_mode(spec, 0);",
  [Changes what reads and writes on an HTTP channel mean. In mode 3 a
  write sets a request header; in mode 1 the adapter collects the
  response headers and in mode 2 you read them back; in mode 4 a write
  becomes the POST body. Mode 0 puts you back on the body.

  This one is only valid on an #cw("HTTP:") or #cw("HTTPS:") channel and
  errors on anything else. The library gets the aux byte right here.])

#sect[13.4 Filesystem operations]

#block({
  set par(first-line-indent: 0pt, justify: true)
  [These six work on a #emph[one-shot] channel: the adapter parses the
  devicespec you hand it, does the operation, and throws the protocol
  away. You do not open first and you do not close afterwards. They need
  a filesystem behind them --- #cw("TNFS:"), #cw("SMB:"), #cw("FTP:") ---
  and error on a socket.

  All six share a frame: the operation's own command byte, a mode byte in
  aux1 that the filesystem layer interprets, an ignored aux2, and a
  256-byte devicespec. fujinet-lib reaches them through
  #cw("network_ioctl()"), which is why that function takes a devicespec
  as its last argument.]
})

#cmd("DELETE", code: "$21  '!'", dev: "E3 unit 21 mode 00 + 256",
  aux: [#emph[byte]: mode, passed to the filesystem. \
    #emph[byte], ignored],
  payload: [256 bytes: the devicespec, NUL-padded],
  reply: [none],
  lib: [#cw("network_fs_delete(spec)")],
  asm: "        ldx     #SPEC
        lda     #NCDELET
        jsr     FSOP            ; see Appendix C",
  c: "network_fs_delete(\"N:TNFS://server/OLD.DSK\");",
  [Removes a file.])

#cmd("RENAME", code: "$20", dev: "E3 unit 20 mode 00 + 256",
  aux: [#emph[byte]: mode. #emph[byte], ignored],
  payload: [256 bytes: #cw("path,newname"), NUL-padded],
  reply: [none],
  lib: [#cw("network_fs_rename(spec)")],
  asm: "        ldx     #SPEC
        lda     #NCRENAM
        jsr     FSOP",
  c: "network_fs_rename(\"N:TNFS://s/A.DSK,B.DSK\");",
  [Renames a file. The old and new names go in one devicespec separated
  by a comma --- the whole thing is still one 256-byte field.])

#cmd("LOCK / UNLOCK", code: "$23  '#'  /  $24  '\\$'",
  dev: "E3 unit 23 mode 00 + 256",
  aux: [#emph[byte]: mode. #emph[byte], ignored],
  payload: [256 bytes: the devicespec],
  reply: [none],
  lib: [#cw("network_fs_lock(spec)") · #cw("network_fs_unlock(spec)")],
  asm: "        ldx     #SPEC
        lda     #NCLOCK
        jsr     FSOP",
  c: "network_fs_lock(spec);
/* ... */
network_fs_unlock(spec);",
  [Sets and clears a file's read-only attribute, where the filesystem has
  one. On TNFS this is the write permission bit.])

#cmd("MKDIR / RMDIR", code: "$2A  '*'  /  $2B  '+'",
  dev: "E3 unit 2A mode 00 + 256",
  aux: [#emph[byte]: mode. #emph[byte], ignored],
  payload: [256 bytes: the devicespec],
  reply: [none],
  lib: [#cw("network_fs_mkdir(spec)") · #cw("network_fs_rmdir(spec)")],
  asm: "        ldx     #SPEC
        lda     #NCMKDIR
        jsr     FSOP",
  c: "network_fs_mkdir(\"N:TNFS://server/SAVES/\");",
  [Makes and removes a directory. #cw("RMDIR") wants the directory to be
  empty; the filesystem decides, not the adapter.])

#cmd("CHDIR", code: "$2C  ','", dev: "E3 unit 2C 00 00 + 256",
  aux: [two bytes, ignored],
  payload: [256 bytes: the new prefix, NUL-padded],
  reply: [none],
  lib: [#cw("network_fs_cd(spec)")],
  asm: "        ldx     #SPEC
        lda     #NCCHDIR
        jsr     FSOP",
  c: "network_fs_cd(\"N:TNFS://server/COCO/\");",
  [Sets this unit's prefix --- the directory every later devicespec is
  relative to. The conventions are the shell's: #cw("..") or #cw("<")
  goes up one, #cw("/") or #cw(">") truncates back to the host, a leading
  slash replaces the path but keeps the host, a bare #cw("scheme:")
  resets everything, and anything else is appended. An empty #cw("Nn:")
  clears it.])

#cmd("GETCWD", code: "$30  '0'", dev: "E3 unit 30 00 00",
  aux: [two bytes, ignored],
  payload: [none],
  reply: [the prefix --- ask for 256 bytes and it is zero-padded to fit],
  lib: [none],
  asm: "        lda     NTUNI
        sta     CWFRM+1
        ldx     #CWFRM
        ldy     #5
        ldb     NTUNI
        jsr     NTXACT
        bne     BADIO
        ldb     NTUNI
        ldx     #PFX
        ldy     #256
        jsr     NTGRSP

CWFRM   fcb     OPNET,0,NCGETCW,0,0",
  c: "char prefix[257];
/* ... send the five-byte frame ... */
network_get_response(unit,
                     (uint8_t *) prefix, 256);
prefix[256] = '\\0';",
  [Reads the prefix back. The adapter sends the string's own length, but
  #cw("SEND_RESPONSE") on this device pads the reply out to whatever you
  asked for --- so ask for 256, and the tail is zeros.])

#sect[13.5 Sockets and credentials]

#cmd("ACCEPT", code: "$41  'A'", dev: "E3 unit 41 00 00",
  aux: [two bytes, ignored],
  payload: [none], reply: [none],
  lib: [none],
  asm: "        lda     NTUNI
        sta     ACFRM+1
        ldx     #ACFRM
        ldy     #5
        ldb     NTUNI
        jsr     NTXACT

ACFRM   fcb     OPNET,0,NCACCPT,0,0",
  c: "f.cmd = 'A'; f.a1 = f.a2 = 0;
bus_ready();
dwwrite((uint8_t *) &f, sizeof(f));
e = network_get_error(unit);",
  [Accepts a waiting inbound connection on a listening #cw("TCP:")
  channel --- one opened with a port and no host, as in
  #cw("N:TCP://:6502/"). Errors on any other kind of channel.

  There is no way to ask whether a connection is waiting other than to
  try: #cw("STATUS") reports 209, no connection waiting, when there is
  none.])

#cmd("CLOSE_CLIENT", code: "$63  'c'", dev: "E3 unit 63 00 00",
  aux: [two bytes, ignored],
  payload: [none], reply: [none],
  lib: [none],
  asm: "        lda     NTUNI
        sta     CCFRM+1
        ldx     #CCFRM
        ldy     #5
        ldb     NTUNI
        jsr     NTXACT

CCFRM   fcb     OPNET,0,NCCLCLI,0,0",
  c: "f.cmd = 'c'; f.a1 = f.a2 = 0;
bus_ready();
dwwrite((uint8_t *) &f, sizeof(f));",
  [Hangs up on the accepted client without closing the listening socket,
  so the next #cw("ACCEPT") can take another. #cw("CLOSE") would throw
  away the listener as well. TCP only.])

#cmd("GET_REMOTE", code: "$72  'r'", dev: "E3 unit 72 00 00",
  aux: [two bytes, ignored],
  payload: [none],
  reply: [256 bytes: the remote address as text],
  lib: [none],
  asm: "        lda     NTUNI
        sta     GRFRM+1
        ldx     #GRFRM
        ldy     #5
        ldb     NTUNI
        jsr     NTXACT
        bne     BADIO
        ldb     NTUNI
        ldx     #REMOTE
        ldy     #256
        jsr     NTGRSP

GRFRM   fcb     OPNET,0,NCGTREM,0,0",
  c: "char remote[257];
/* ... send the frame ... */
network_get_response(unit,
                     (uint8_t *) remote, 256);",
  [Who the last UDP datagram came from.

  #strong[This one is compiled out of the ESP32 firmware.] It is guarded
  #cw("#ifndef ESP_PLATFORM"), so it works on FujiNet-PC and always
  errors on a hardware adapter. UDP only in either case.])

#cmd("SET_DESTINATION", code: "$44  'D'", dev: "E3 unit 44 hi lo + len",
  aux: [#emph[word]: how many bytes follow, high byte first],
  payload: [that many bytes: the destination, as text],
  reply: [none],
  lib: [none],
  asm: "        ldd     #DESTLEN
        std     SDFRM+3
        lda     NTUNI
        sta     SDFRM+1
        ldx     #SDFRM
        ldy     #5
        jsr     FNWAIT
        jsr     [DWWRITV]
        ldx     #DEST
        ldy     #DESTLEN
        jsr     [DWWRITV]
        ldb     NTUNI
        jsr     NTGERR

SDFRM   fcb     OPNET,0,NCSETDE,0,0",
  c: "struct { uint8_t op,unit,cmd;
         uint16_t len; } f;
char dest[] = \"192.168.1.9:5000\";

f.op = 0xE3; f.unit = unit;
f.cmd = 'D'; f.len = strlen(dest);
bus_ready();
dwwrite((uint8_t *) &f, sizeof(f));
dwwrite((uint8_t *) dest, f.len);",
  [Points a UDP channel at somewhere to send. UDP only.])

#cmd("USERNAME / PASSWORD", code: "$FD / $FE",
  dev: "E3 unit FD 00 00 + 256",
  aux: [two bytes, ignored],
  payload: [256 bytes, NUL-padded],
  reply: [none],
  lib: [none],
  asm: "        lda     NTUNI
        sta     UNFRM+1
        ldx     #UNFRM
        ldy     #261
        ldb     NTUNI
        jsr     NTXACT

UNFRM   fcb     OPNET,0,NCUSER,0,0
UNSTR   rmb     256",
  c: "/* the same frame with cmd 0xFE for the
   password.  Both are 261 bytes. */",
  [Credentials for the next protocol that wants them --- #cw("FTP:"),
  #cw("SMB:"), an authenticated #cw("HTTP:"). Set them before
  #cw("OPEN")\; they live on the unit, not on the channel, so they
  survive a close.

  They can also go inline in the devicespec as
  #cw("scheme://user:pass@host/"), which is shorter and puts your
  password in a string constant. These two exist so that it does not have
  to be.])

#sect[13.6 Answered with an error]

#block({
  set par(first-line-indent: 0pt, justify: true)
  [These bytes are in the command table and are not in the network
  device's dispatch table. Unlike the control device, this one fails
  properly: the dispatcher takes the error path, #cw("SEND_ERROR")
  answers #hx("90"), and the bus stays in step. The two aux bytes are
  still consumed, so a five-byte frame leaves nothing behind.]
})

#dotdef(
  (hx("FF") + "  GET_DSTATS_VALUE", [never implemented on any bus]),
  (hx("FA") + "  SET_UNIT", [the unit is in every frame here]),
  (hx("E3") + "  SET_HSIO_INDEX", [SIO bus tuning]),
  (hx("81") + "  QUERY_ALT", [the Atari's alternate query entry]),
  (hx("80") + "  PARSE_ALT", [likewise]),
  (hx("45") + "  GET_ERROR  'E'", [use the bus's own #hx("02")]),
  (hx("3F") + "  HSIO_INDEX  '?'", [SIO again]),
)

#block({
  set par(first-line-indent: 0pt, justify: true)
  [The third of those is worth a second look. Other FujiNet platforms
  fetch a channel's error with #cw("NET_GET_ERROR"), command #hx("45").
  On this bus that command does not exist: the error comes from the bus
  meta-command #hx("02"), addressed to the unit, exactly as Chapter 4
  described. If you are porting code from an Atari or an Apple II, that
  is the substitution to make.]
})

#gbar

// ============================================================
// 14. COMMAND REFERENCE: THE OTHER DEVICES
// ============================================================
#chapter("14. Command Reference: The Other Devices",
  subs: ("The clock", "Setting the timezone", "CP/M", "The printer",
         "The modem, and why it is not here"))
#ix("Clock device", "Timezone", "CP/M device", "Printer device",
    "Modem (not reachable)")

#sect[14.1 The clock]

#block({
  set par(first-line-indent: 0pt, justify: true)
  [Device #hx("E5"), and it breaks the rule that every other device
  follows. The bus runs the clock's handler #emph[first] and then rewrites
  the command to #cw("SEND_RESPONSE"), so the answer comes straight back:
  no #cw("DEVICE_READY"), no #cw("SEND_ERROR"), no second exchange. Write
  the frame, read the reply.

  Most of the read commands take an optional third byte. Send #hx("01")
  and the reply uses the alternate timezone set with #hx("99")\; send
  #hx("00"), or nothing at all, and it uses the adapter's own. Strings
  come back with a terminating NUL.

  There is a simpler road still, and it is the one fujinet-lib takes: the
  bus-level opcode #hx("23") in Chapter 15 is a single byte out and six
  bytes back, with no device and no command at all.]
})

#cmd("GET_TIME (simple)", code: "$54  'T'", dev: "E5 54 [alt]",
  aux: [#emph[byte], optional: #hx("01") to use the alternate timezone],
  payload: [none],
  reply: [7 bytes: century, year, month (1--12), day, hour, minute, second],
  lib: [#cw("clock_get_time(buf, SIMPLE_BINARY)") --- which actually uses
    the #hx("23") opcode],
  asm: "        ldx     #CKFRM
        ldy     #3
        jsr     [DWWRITV]
        ldx     #TIMBUF
        ldy     #7
        jsr     [DWREADV]
        bne     NOCLOCK

CKFRM   fcb     OPCLOCK,$54,0",
  c: "uint8_t frame[3] = { 0xE5, 0x54, 0 };
uint8_t t[7];

dwwrite(frame, 3);
if (dwread(t, 7))
    printf(\"%u%02u-%02u-%02u %02u:%02u:%02u\\n\",
           t[0], t[1], t[2], t[3],
           t[4], t[5], t[6]);",
  [The most convenient form: a full four-digit year split across two
  bytes, then the fields in the order you would write them.

  This opcode is in both the clock's read table and its write table --- it
  is #cw("SETTZ") on buses where reads and writes have separate
  namespaces --- and the read table is consulted first. On this bus
  #hx("54") gets you the time. To set a timezone, use #hx("99") or
  #hx("74").])

#cmd("GET_TIME (APETIME)", code: "$93", dev: "E5 93 [alt]",
  aux: [#emph[byte], optional: the alternate-timezone flag],
  payload: [none],
  reply: [6 bytes: day, month (1--12), year (two digits), hour, minute,
    second],
  lib: [none],
  asm: "        ldx     #APFRM
        ldy     #3
        jsr     [DWWRITV]
        ldx     #TIMBUF
        ldy     #6
        jsr     [DWREADV]

APFRM   fcb     OPCLOCK,$93,0",
  c: "uint8_t frame[3] = { 0xE5, 0x93, 0 };
uint8_t t[6];

dwwrite(frame, 3);
dwread(t, 6);       /* dd mm yy hh mm ss */",
  [The Atari's APETIME order, day first, and a two-digit year. It is here
  because it is dispatched and because porting code from an Atari is a
  thing people do. #hx("9A") is the same reply with the alternate
  timezone forced on regardless of the flag byte.])

#cmd("GET_TIME (hundredths)", code: "$4D  'M'", dev: "E5 4D [alt]",
  aux: [#emph[byte], optional: the alternate-timezone flag],
  payload: [none],
  reply: [8 bytes: the seven of the simple form, then hundredths (0--99)],
  lib: [none],
  asm: "        ldx     #HUFRM
        ldy     #3
        jsr     [DWWRITV]
        ldx     #TIMBUF
        ldy     #8
        jsr     [DWREADV]

HUFRM   fcb     OPCLOCK,$4D,0",
  c: "uint8_t frame[3] = { 0xE5, 0x4D, 0 };
uint8_t t[8];

dwwrite(frame, 3);
dwread(t, 8);",
  [The simple form with a hundredths byte on the end. Useful for timing
  something across a network round trip, where the Color Computer's own
  sixty-times-a-second interrupt is the least of your errors.])

#cmd("GET_TIME (ProDOS)", code: "$50  'P'", dev: "E5 50 [alt]",
  aux: [#emph[byte], optional],
  payload: [none],
  reply: [4 bytes in the ProDOS date and time format],
  lib: [#cw("clock_get_time(buf, PRODOS_BINARY)") --- not implemented on
    this platform],
  asm: "        ldx     #PDFRM
        ldy     #3
        jsr     [DWWRITV]
        ldx     #TIMBUF
        ldy     #4
        jsr     [DWREADV]

PDFRM   fcb     OPCLOCK,$50,0",
  c: "uint8_t frame[3] = { 0xE5, 0x50, 0 };
uint8_t t[4];

dwwrite(frame, 3);
dwread(t, 4);",
  [The Apple II's packed four-byte date. Dispatched here as well, because
  the clock is shared code across every bus. You will not want it on a
  Color Computer unless you are writing something that stores dates in
  that format on purpose.])

#cmd("GET_TIME (SOS)", code: "$53  'S'", dev: "E5 53 [alt]",
  aux: [#emph[byte], optional],
  payload: [none],
  reply: [the string #cw("YYYYMMDD0HHMMSS000") and a NUL --- 19 bytes],
  lib: [none],
  asm: "        ldx     #SOFRM
        ldy     #3
        jsr     [DWWRITV]
        ldx     #TIMBUF
        ldy     #19
        jsr     [DWREADV]

SOFRM   fcb     OPCLOCK,$53,0",
  c: "uint8_t frame[3] = { 0xE5, 0x53, 0 };
char t[20];

dwwrite(frame, 3);
dwread((uint8_t *) t, 19);",
  [The Apple III's SOS format, as text. Eighteen digits and a terminator.])

#cmd("GET_TIME (ISO)", code: "$49  'I'  /  $5A  'Z'",
  dev: "E5 49 [alt]",
  aux: [#emph[byte], optional --- ignored by #hx("5A")],
  payload: [none],
  reply: [#cw("YYYY-MM-DDTHH:MM:SS+HHMM") and a NUL --- 25 bytes],
  lib: [none],
  asm: "        ldx     #ISFRM
        ldy     #3
        jsr     [DWWRITV]
        ldx     #TIMBUF
        ldy     #25
        jsr     [DWREADV]
        ldx     #TIMBUF
        jsr     PUTS

ISFRM   fcb     OPCLOCK,$49,0",
  c: "uint8_t frame[3] = { 0xE5, 0x49, 0 };
char t[26];

dwwrite(frame, 3);
if (dwread((uint8_t *) t, 25))
    printf(\"%s\\n\", t);",
  [ISO 8601, which is the one to use if you are going to put a timestamp
  in something that leaves the machine. #hx("49") is local time with the
  offset filled in; #hx("5A") is the same thing at UTC, with an offset of
  #cw("+0000"), and ignores the alternate-timezone flag.])

#cmd("GET_TZ", code: "$47  'G'", dev: "E5 47",
  aux: [none --- this one takes no flag byte],
  payload: [none],
  reply: [the adapter's timezone string and a NUL],
  lib: [#cw("clock_get_tz(buf)")],
  asm: "        lda     #$4C            ; ask the length first
        sta     TZFRM+1
        ldx     #TZFRM
        ldy     #2
        jsr     [DWWRITV]
        ldx     #TZLEN
        ldy     #1
        jsr     [DWREADV]
        lda     #$47
        sta     TZFRM+1
        ldx     #TZFRM
        ldy     #2
        jsr     [DWWRITV]
        ldx     #TZBUF
        ldb     TZLEN
        clra
        tfr     d,y
        jsr     [DWREADV]

TZFRM   fcb     OPCLOCK,0",
  c: "uint8_t f[2] = { 0xE5, 0x4C };
uint8_t len;
char tz[64];

dwwrite(f, 2);  dwread(&len, 1);
f[1] = 0x47;
dwwrite(f, 2);  dwread((uint8_t *) tz, len);",
  [Which timezone the adapter is keeping. Ask #hx("4C") first: it answers
  with one byte, the string's length including its terminator, and then
  #hx("47") sends exactly that many. Reading a variable-length reply on
  a bus with no length field is the one thing that needs two commands,
  and this is the pair that does it.])

#cmd("SET_TZ", code: "$74  't'  /  $99", dev: "E5 74 hi lo + len",
  aux: [#emph[word]: how many bytes of timezone follow, high byte first],
  payload: [that many bytes],
  reply: [none],
  lib: [#cw("clock_set_tz(tz)") --- not implemented on this platform],
  asm: "*       see the caution below before using
        ldx     #STFRM
        ldy     #4
        jsr     [DWWRITV]
        ldx     #TZSTR
        ldy     #TZLEN
        jsr     [DWWRITV]

STFRM   fcb     OPCLOCK,$74
        fdb     0",
  c: "/* $74 sets the adapter's own timezone;
   $99 sets the alternate one that the
   [alt] flag selects. */",
  [#hx("74") sets the system timezone and #hx("99") sets the alternate
  one --- the one the optional flag byte on every read command selects.
  The string is a POSIX timezone name such as #cw("America/Chicago").

  #ybox(title: [KNOWN BUG])[The Color Computer's implementation of this
  reads the length with an extra byte-swap: the frame decoder has already
  converted it from big-endian, and the clock handler swaps it again. On
  the adapter's little-endian processor a length of 3 therefore arrives as
  768, and the adapter sits waiting for 768 bytes that will never come.
  Until that is fixed, set the timezone from the web interface.]])

#sect[14.2 CP/M]

#block({
  set par(first-line-indent: 0pt, justify: true)
  [Device #hx("E4") is a Z80 emulator running RunCPM on the adapter, with
  its console on the wire. It exists only in the ESP32 firmware ---
  FujiNet-PC compiles it out --- and it is the one device in this book
  that is not on every build. The three bus meta-commands work here as
  they do everywhere else.]
})

#cmd("CPM_BOOT", code: "$42  'B'", dev: "E4 42",
  aux: [none], payload: [none], reply: [none],
  lib: [none],
  asm: "        ldx     #CBFRM
        ldy     #2
        jsr     [DWWRITV]

CBFRM   fcb     OPCPM,'B",
  c: "uint8_t f[2] = { 0xE4, 'B' };
dwwrite(f, 2);",
  [Starts the emulator on its own task with 64K of RAM. Give it a moment
  before you expect a prompt.])

#cmd("CPM_READ", code: "$52  'R'", dev: "E4 52 hi lo",
  aux: [#emph[word]: how many bytes to take, high byte first],
  payload: [none],
  reply: [that many bytes from the console],
  lib: [none],
  asm: "        ldd     #64
        std     CRFRM+2
        ldx     #CRFRM
        ldy     #4
        jsr     [DWWRITV]
*       then the three-step fetch as usual

CRFRM   fcb     OPCPM,'R
        fdb     0",
  c: "struct { uint8_t op, cmd; uint16_t len; } f;

f.op = 0xE4; f.cmd = 'R'; f.len = 64;
bus_ready();
dwwrite((uint8_t *) &f, sizeof(f));",
  [Takes bytes from the console output queue. Ask #cw("CPM_STATUS") first:
  when the queue is empty this command sends nothing at all and the Color
  Computer waits for a reply that is not coming.])

#cmd("CPM_WRITE", code: "$57  'W'", dev: "E4 57 hi lo + len",
  aux: [#emph[word]: how many bytes follow],
  payload: [that many bytes],
  reply: [none],
  lib: [none],
  asm: "        ldd     #LEN
        std     CWFRM+2
        ldx     #CWFRM
        ldy     #4
        jsr     [DWWRITV]
        ldx     #KEYS
        ldy     #LEN
        jsr     [DWWRITV]

CWFRM   fcb     OPCPM,'W
        fdb     0",
  c: "f.op = 0xE4; f.cmd = 'W'; f.len = n;
bus_ready();
dwwrite((uint8_t *) &f, sizeof(f));
dwwrite(keys, n);",
  [Puts keystrokes into the console input queue. Both queues hold 2048
  bytes.])

#cmd("CPM_STATUS", code: "$53  'S'", dev: "E4 53",
  aux: [none], payload: [none],
  reply: [2 bytes: how many are waiting, high byte first],
  lib: [none],
  asm: "        ldx     #CSFRM
        ldy     #2
        jsr     [DWWRITV]
*       then the three-step fetch

CSFRM   fcb     OPCPM,'S",
  c: "uint16_t waiting;
/* ... frame, then ... */
fuji_get_response((uint8_t *) &waiting, 2);
/* already big-endian on a 6809 */",
  [How much the console has to say. Poll this and read what it reports,
  exactly as with the network device.])

#sect[14.3 The printer]

#cmd("PRINT", code: "$50  'P'", dev: "50 byte",
  aux: [#emph[byte]: the character to print],
  payload: [none], reply: [none],
  lib: [none],
  asm: "PRCHR   sta     PRFRM+1
        ldx     #PRFRM
        ldy     #2
        jmp     [DWWRITV]

PRFRM   fcb     OPPRINT,0",
  c: "void print_char(uint8_t c)
{
    uint8_t f[2] = { 0x50, 0 };

    f[1] = c;
    dwwrite(f, 2);
}",
  [One byte per call, straight into the printer emulation --- and note
  that this is a #emph[bus] opcode, not a device: there is no command
  byte, no handshake and no reply. The adapter can pretend to be anything
  from a Radio Shack line printer to a PNG file, and which one is a
  setting in the web interface rather than something you choose from
  here.

  #hx("46") #cw("'F'"), print-flush, is accepted and ignored.])

#sect[14.4 The modem, and why it is not here]

#block({
  set par(first-line-indent: 0pt, justify: true)
  [FujiNet has a full Hayes-style modem with an AT command set, and it is
  #strong[not reachable from the Color Computer]. The code is in the
  firmware and compiles; nothing in the Color Computer build ever
  constructs it, so there is no device on the bus to address. The Atari
  build constructs one; this one does not.

  What does exist is the raw virtual-serial channel machinery from
  Chapter 15 --- sixteen queues each way, addressed by
  #cw("OP_SERREAD"), #cw("OP_SERWRITE") and their relatives. On this
  adapter nothing consumes the inbound queues, so they are plumbing
  without anything plumbed to them.

  For a terminal program, open a #cw("N:TELNET://") or #cw("N:TCP:")
  channel and use the five moves. That is what Chapter 16 does, and it is
  the answer the platform actually has.]
})

#gbar

// ============================================================
// 15. COMMAND REFERENCE: DRIVEWIRE ITSELF
// ============================================================
#chapter("15. Command Reference: DriveWire Itself",
  subs: ("Reading a sector", "Writing a sector", "The clock, the short way",
         "Identification and reset", "Virtual serial channels",
         "Accepted and ignored"))
#ix("OP_READEX", "OP_WRITE", "Sector protocol", "Checksum",
    "OP_DWINIT", "OP_JEFF", "Virtual serial channels", "Named object mount")

#block({
  set par(first-line-indent: 0pt, justify: true)
  [Below the four FujiNet devices is the DriveWire protocol proper. These
  opcodes are answered by the bus itself: no device, no command byte, no
  three-step handshake. They are how HDB-DOS gets its sectors, and they
  are the only part of this book that a program written in 1985 would
  recognise.

  You will not usually send any of them --- DOS is doing it for you ---
  but two of them are the disk, so anyone writing their own DOS needs
  this chapter, and #hx("23") is by a wide margin the easiest way to ask
  the time.]
})

#sect[15.1 Reading a sector]

#cmd("OP_READEX", code: "$D2", dev: "D2 drive lsn2 lsn1 lsn0",
  aux: [#emph[byte]: the drive, 0 to 3. \
    #emph[three bytes]: the logical sector number, #strong[high byte
    first]],
  payload: [none],
  reply: [256 bytes, then you send a 16-bit checksum #strong[high byte
    first], then one status byte comes back],
  lib: [none --- this is DOS's business],
  asm: "*       read drive 0, sector 18
        clr     RXFRM+1
        clr     RXFRM+2
        clr     RXFRM+3
        lda     #18
        sta     RXFRM+4
        ldx     #RXFRM
        ldy     #5
        jsr     [DWWRITV]
        ldx     #SECTOR
        ldy     #256
        jsr     [DWREADV]
        bne     NOANSWER
        sty     CHKSUM          ; DWRead left it in Y
        ldx     #CHKSUM
        ldy     #2
        jsr     [DWWRITV]
        ldx     #STATUS
        ldy     #1
        jsr     [DWREADV]

RXFRM   fcb     OPREADX,0,0,0,0",
  c: "struct { uint8_t op, drive, l2, l1, l0; } f;
uint8_t sector[256], st;
uint16_t sum;

f.op = 0xD2; f.drive = 0;
f.l2 = 0; f.l1 = 0; f.l0 = 18;
dwwrite((uint8_t *) &f, sizeof(f));
if (!dwread(sector, 256)) fail();
sum = checksum(sector, 256);
dwwrite((uint8_t *) &sum, 2);   /* big-endian */
dwread(&st, 1);",
  [The disk read, and the only checksummed exchange on this bus. The
  adapter always sends the block --- on an error it sends 256 zeros ---
  and then you prove you received it by sending back the 16-bit sum of
  the bytes. #cw("DWRead") computes that sum for you and leaves it in
  #cw("Y"), which is why it clobbers your count register.

  Status bytes: #hx("00") success · #hx("F4") read error · #hx("F6")
  invalid or inactive drive · 211 past the end of the image · 243 your
  checksum did not match.

  A drive number of 5 or more is reduced by 5 on a Dragon.])

#sect[15.2 Writing a sector]

#cmd("OP_WRITE", code: "$57  'W'", dev: "57 drive lsn2 lsn1 lsn0 + 256",
  aux: [#emph[byte]: the drive. \
    #emph[three bytes]: the sector, high byte first],
  payload: [256 bytes of data, then a 16-bit checksum #strong[low byte
    first]],
  reply: [one status byte],
  lib: [none],
  asm: "        ldx     #WXFRM
        ldy     #5
        jsr     [DWWRITV]
        ldx     #SECTOR
        ldy     #256
        jsr     [DWWRITV]
        ldx     #CHKSUM         ; low byte first
        ldy     #2
        jsr     [DWWRITV]
        ldx     #STATUS
        ldy     #1
        jsr     [DWREADV]

WXFRM   fcb     OPWRITE,0,0,0,0",
  c: "dwwrite((uint8_t *) &f, 5);
dwwrite(sector, 256);
dwwrite(sum_lo_first, 2);
dwread(&st, 1);",
  [The disk write, and two things about it will surprise you.

  #strong[The checksum goes low byte first here] and high byte first on
  the read. The firmware reads it in the opposite order from the way it
  reads the other one, and there is no reason for it beyond history.

  #strong[The checksum is not checked.] It is read, the block's sum is
  computed, and the comparison is commented out. A corrupted write is
  written.

  Status bytes: #hx("00") success · #hx("F5") write error · #hx("F6")
  invalid or inactive drive. If you send fewer than 256 bytes of data the
  adapter discards its input and sends #strong[no status byte at all],
  which leaves you waiting on a read that will time out and a bus that is
  out of step.

  #hx("77") #cw("'w'"), re-write, is the same command under another
  name.])

#sect[15.3 The clock, the short way]

#cmd("OP_TIME", code: "$23  '#'", dev: "23",
  aux: [none], payload: [none],
  reply: [6 bytes: year minus 1900, month (1--12), day, hour, minute,
    second],
  lib: [#cw("clock_get_time(buf, SIMPLE_BINARY)")],
  asm: "DWTIME  pshs    x
        jsr     FNWAIT
        ldx     #DWTF
        ldy     #1
        jsr     [DWWRITV]
        puls    x
        ldy     #6
        jmp     [DWREADV]

DWTF    fcb     OPTIME",
  c: "uint8_t op = 0x23, t[6];

dwwrite(&op, 1);
if (dwread(t, 6))
    printf(\"%u-%02u-%02u %02u:%02u:%02u\\n\",
           t[0] + 1900, t[1], t[2],
           t[3], t[4], t[5]);",
  [One byte out, six bytes back, no device and no handshake. It is the
  cheapest command in this book and it is what fujinet-lib's
  #cw("clock_get_time()") actually uses.

  The year is a #cw("tm_year") --- years since 1900 --- so add 1900 and
  not 2000. The month has already been incremented to the 1-to-12 range
  you expect. The adapter's own timezone applies; there is no flag byte
  here.])

#sect[15.4 Identification and reset]

#cmd("OP_JEFF", code: "$A5", dev: "A5",
  aux: [none], payload: [none],
  reply: [the seven characters #cw("FUJINET"), with no terminator],
  lib: [none],
  asm: "        ldx     #JFRM
        ldy     #1
        jsr     [DWWRITV]
        ldx     #JBUF
        ldy     #7
        jsr     [DWREADV]
        bne     NOFUJI
*       compare JBUF with \"FUJINET\"

JFRM    fcb     OPJEFF
JSIG    fcc     \"FUJINET\"",
  c: "uint8_t op = 0xA5, buf[8];

dwwrite(&op, 1);
if (!dwread(buf, 7)) return 0;
buf[7] = '\\0';
return !strcmp((char *) buf, \"FUJINET\");",
  [Is there a FujiNet on this wire? A plain DriveWire server does not
  answer this, so it distinguishes a FujiNet from any other thing that
  serves disks. Eight bytes, and it fails in the time #cw("DWRead") takes
  to give up rather than hanging. Put it at the top of every program.])

#cmd("OP_DWINIT", code: "$5A  'Z'", dev: "5A",
  aux: [none], payload: [none],
  reply: [one byte, always #hx("04")],
  lib: [none],
  asm: "        ldx     #DIFRM
        ldy     #1
        jsr     [DWWRITV]
        ldx     #FEAT
        ldy     #1
        jsr     [DWREADV]

DIFRM   fcb     OPDWINI",
  c: "uint8_t op = 0x5A, feat;

dwwrite(&op, 1);
dwread(&feat, 1);   /* always 0x04 */",
  [The feature enquiry that OS-9's DriveWire driver makes at startup. The
  firmware defines a whole set of feature bits --- EMCEE, DLOAD, HDB-DOS,
  DOS-PLUS, printer, SSH, sound --- and then returns #hx("04"), HDB-DOS,
  unconditionally, because the branch that would return the real set is
  compiled out. Do not read anything into the answer.])

#cmd("OP_RESET", code: "$F8 / $FE / $FF", dev: "FF",
  aux: [none], payload: [none], reply: [none],
  lib: [none],
  asm: "        ldx     #RSFRM
        ldy     #1
        jsr     [DWWRITV]

RSFRM   fcb     OPRST1",
  c: "uint8_t op = 0xFF;
dwwrite(&op, 1);",
  [Three opcodes, one behaviour: re-arm the CONFIG disk and re-insert the
  boot device. This is a bus reset, not a reboot --- the adapter stays up
  and the network stays connected. It is what the Computer's own reset
  line triggers, and it is why there is always a way back to CONFIG.

  It also closes any named object the Dragon path had open.])

#cmd("OP_NOP", code: "$00", dev: "00",
  aux: [none], payload: [none], reply: [none],
  lib: [none],
  asm: "        ldx     #NPFRM
        ldy     #1
        jmp     [DWWRITV]

NPFRM   fcb     OPNOP",
  c: "uint8_t op = 0x00;
dwwrite(&op, 1);",
  [Does nothing and says nothing. It is here because #hx("00") on the
  wire is not an error, which is worth knowing when you are debugging a
  desynchronised bus: a stream of zeros produces no complaint at all.])

#cmd("OP_NAMEOBJ_MNT", code: "$01", dev: "01 len + name",
  aux: [#emph[byte]: the length of the name],
  payload: [that many bytes],
  reply: [one byte, #hx("01")],
  lib: [none],
  asm: "*       Dragon only
        lda     #NAMELEN
        sta     NOFRM+1
        ldx     #NOFRM
        ldy     #2
        jsr     [DWWRITV]
        ldx     #NAME
        ldy     #NAMELEN
        jsr     [DWWRITV]
        ldx     #ACKBYTE
        ldy     #1
        jsr     [DWREADV]

NOFRM   fcb     OPNAMOB,0",
  c: "/* Dragon only; ignored on a CoCo. */",
  [Names a file to be streamed sequentially in place of sector-addressed
  disk reads, and then resets. It is the Dragon's cassette-style load
  path: once a named object is set, #cw("OP_READEX") hands out the next
  256 bytes of that file rather than the sector you asked for, falling
  back to #tt("/AUTOLOAD.DWL") and, in lobby boot mode, to
  #tt("/DGNLOBBY.DWL").

  The Color Computer build does not dispatch this opcode at all.])

#sect[15.5 Virtual serial channels]

#block({
  set par(first-line-indent: 0pt, justify: true)
  [DriveWire carries sixteen virtual serial channels in each direction,
  and the adapter implements the plumbing for all of them. Nothing on
  the FujiNet side currently fills the inbound queues, so these read as
  empty and write into a queue nobody drains. They are documented because
  they are dispatched, and because OS-9's #cw("scdwv") driver speaks
  them; if a future firmware attaches the modem or a telnet service to a
  channel, this is the door it will come through.]
})

#dotdef(
  (hx("43") + "  SERREAD  'C'", [returns two bytes: the first non-empty
   channel, and one byte from it]),
  (hx("63") + "  SERREADM  'c'", [reads a channel number and a count]),
  (hx("C3") + "  SERWRITE", [reads a channel number and one byte ---
   #strong[with no bounds check on the channel]]),
  (hx("64") + "  SERWRITEM", [channel, one discarded byte, a count, then
   that many bytes]),
  (hx("80") + "--" + hx("8F") + "  FASTWRITE", [the channel is the low
   nybble of the opcode; one data byte follows]),
  (hx("45") + "  SERINIT  'E'", [reads one byte]),
  (hx("C5") + "  SERTERM", [reads one byte]),
  (hx("44") + "  SERGETSTAT  'D'", [reads two bytes]),
  (hx("C4") + "  SERSETSTAT", [reads a channel and a code; a code of
   #hx("28") drains a further 26 bytes]),
)

#ybox(title: [ONE TO AVOID])[#cw("OP_SERWRITE") does not range-check the
channel number where its multi-byte cousin does. A channel number of 16
or more writes past the end of the queue array. There is no reason to
send it at all today; there is a good reason not to send it with a bad
channel.]

#sect[15.6 Accepted and ignored]

#block({
  set par(first-line-indent: 0pt, justify: true)
  [These are dispatched, consume the bytes the protocol says they should,
  and do nothing else. They exist so that a DriveWire client that sends
  them does not desynchronise the bus.]
})

#dotdef(
  (hx("46") + "  PRINTFLUSH  'F'", [taken and discarded]),
  (hx("47") + "  GETSTAT  'G'", [reads two bytes]),
  (hx("53") + "  SETSTAT  'S'", [reads two bytes]),
  (hx("49") + "  INIT  'I'", [nothing]),
  (hx("54") + "  TERM  'T'", [nothing]),
)

#block({
  set par(first-line-indent: 0pt, justify: true)
  [And two opcodes in the table are #emph[not] dispatched: #hx("52")
  #cw("'R'"), the non-extended read, and #hx("72") #cw("'r'"), re-read.
  Only the extended forms #hx("D2") and #hx("F2") are answered. Anything
  else at all falls to the unhandled path, which drains and discards the
  whole receive buffer --- which is, at least, a way back from a
  desynchronised bus, if a lossy one.]
})

#gbar

// ============================================================
// 16. NETCAT
// ============================================================
#chapter("16. Netcat",
  subs: ("What it does", "The loop", "The two halves", "Somewhere to point it"))
#ix("NETCAT", "Programs, NETCAT")

#cols2[
Every one of these handbooks ends with a netcat, and for a good reason:
it is the smallest program that uses all five moves of the network
device, and if it works then the cable, the switches, the vectors, the
handshake, the frames and your build are all correct at once.

#sect[What it does]

Asks for a host and a port, opens a TCP channel, and then sits in a loop:
anything you type goes up the wire, anything that arrives goes on the
screen. BREAK hangs up.

#tv(
  vrow(N("FUJINET NETCAT" + rp(" ", 18))),
  vrow(N("HOST? fujinet.online" + rp(" ", 12))),
  vrow(N("PORT? 6502" + rp(" ", 22))),
  vrow(N("OPENING..." + rp(" ", 21))),
  vrow(N("CONNECTED. BREAK HANGS UP." + rp(" ", 6))),
  vrow(N(rp(" ", 32))),
  vrow(N("HELLO FROM A COLOR COMPUTER" + rp(" ", 5))),
  vrow(N(rp(" ", 32))),
  ..range(8).map(_ => FR(vg.g)))

#sect[The loop]

Four things happen on every pass, and the order of them is the whole
program:

#step(1)[Poll the keyboard. If there is a key and it is not BREAK, write
that one byte to the channel.]

#step(2)[Ask #cw("STATUS").]

#step(3)[If bytes are waiting, read #emph[no more than] that many --- and
no more than the buffer holds --- and print them.]

#step(4)[If nothing is waiting and the connected byte is clear, the far
end has gone. Say so and close.]

#asmbox("LOOP    jsr     [POLCAT]
        tsta
        beq     LRECV
        cmpa    #BREAK
        beq     BYE
        sta     KEYB
        ldx     #KEYB
        ldy     #1
        jsr     NTWRIT

LRECV   ldx     #STBUF
        jsr     NTSTAT
        ldd     STBUF
        beq     LCONN
        cmpd    #RXMAX
        bls     LREAD
        ldd     #RXMAX
LREAD   pshs    d
        ldx     #RXBUF
        tfr     d,y
        jsr     NTREAD
        puls    d
        ldx     #RXBUF
        jsr     PUTBUF
        bra     LOOP

LCONN   lda     STBUF+2
        bne     LOOP
        ldx     #MDROP
        jsr     PUTS")

#colbreak()

#sect[The two halves]

The C half is the same program with the frames hidden:

#cbox("for (;;)
{
    k = inkey();
    if (k == KBREAK)
        break;
    if (k)
        if (network_write(spec, &k, 1)
                != FN_ERR_OK)
            goto ioerr;

    if (network_status(spec, &bw, &conn, &err)
            != FN_ERR_OK)
        goto ioerr;

    if (bw)
    {
        if (bw > RXMAX)
            bw = RXMAX;
        n = network_read(spec, rx, bw);
        if (n < 0)
            goto ioerr;
        for (i = 0; i < (uint16_t) n; i++)
            putchar(rx[i]);
    }
    else if (!conn)
    {
        printf(\"\\nTHE OTHER END CLOSED.\\n\");
        break;
    }
}")

Note that it calls #cw("network_read()") with exactly the count
#cw("STATUS") gave it. The library's blocking read will wait until it
has everything you asked for, so asking for more than is there turns an
interactive program into a hung one. Ask for what is waiting.

#ybox(title: [ONE BYTE AT A TIME])[Writing each keystroke as its own
#cw("WRITE") is five bytes of frame for one byte of payload, which is
wasteful and exactly right: a terminal that buffers a line cannot be used
to talk to anything that echoes. If you are sending a file rather than a
conversation, buffer.]

#sect[Somewhere to point it]

#dotdef(
  ("fujinet.online:6502", [the project's own echo and chat service]),
  ("localhost:6502", [with FujiNet-PC, a #cw("nc -l 6502") on the same machine]),
  ("towel.blinkenlights.nl:23", [it still works]),
)

Both halves are in Appendix C.4 in full. They are 180 lines of assembly
and 110 of C, and between them they are the shortest complete statement
of what this book is about.

#v(4pt)
#gbar
]

// ============================================================
// 17. MOUNTER
// ============================================================
#chapter("17. Mounter",
  subs: ("The sequence", "Two frames by hand", "Reading the directory",
         "What CONFIG adds"))
#ix("MOUNTER", "Programs, MOUNTER")

#cols2[
Netcat exercises the network device. This one exercises the other one:
host slots, a directory, a device slot, a mount. It is CONFIG with the
menus taken off, and it is about a hundred and fifty lines either way.

#sect[The sequence]

#step(1)[#cw("READ_HOST_SLOTS") and show the eight.]

#step(2)[#cw("MOUNT_HOST") the one the user picked.]

#step(3)[#cw("OPEN_DIRECTORY") on it, with #cw("*.dsk") as the pattern,
then #cw("READ_DIR_ENTRY") until two #hx("7F") bytes arrive, then
#cw("CLOSE_DIRECTORY").]

#step(4)[#cw("SET_DEVICE_FULLPATH") to put the chosen name into a drive
slot, then #cw("MOUNT_IMAGE") to open it.]

#step(5)[#cw("READ_DEVICE_SLOTS") and show what the four drives now hold.]

#tv(
  vrow(N("FUJINET MOUNTER" + rp(" ", 17))),
  vrow(N(rp(" ", 32))),
  vrow(N("1 SD" + rp(" ", 28))),
  vrow(N("2 tnfs.fujinet.online" + rp(" ", 11))),
  vrow(N("3 (EMPTY)" + rp(" ", 23))),
  vrow(N(rp(" ", 32))),
  vrow(N("HOST? 2" + rp(" ", 25))),
  vrow(N("1 COCOLOBBY.DSK" + rp(" ", 17))),
  vrow(N("2 NETCAT.DSK" + rp(" ", 20))),
  vrow(N(rp(" ", 32))),
  vrow(N("FILE? 2" + rp(" ", 25))),
  vrow(N("DRIVE (1-4)? 1" + rp(" ", 18))),
  vrow(N(rp(" ", 32))),
  vrow(N("READY ON DRIVE 0" + rp(" ", 16))),
  ..range(2).map(_ => FR(vg.g)))

#sect[Two frames by hand]

Two of those commands do not fit #cw("FNCMD1"), and the reason is the
same both times: they take more than one parameter byte, and the adapter
will read every byte the command declares whether you sent it or not.

#cw("READ_DIR_ENTRY") takes a length and a flags byte:

#asmbox("RDFRM   fcb     OPFUJI,FCRDDIR,36,0

DIR1    ldx     #RDFRM
        ldy     #4
        jsr     FNXACT")

and #cw("SET_DEVICE_FULLPATH") takes three, plus a 256-byte name:

#asmbox("SDFRM   fcb     OPFUJI,FCSDVFP,0,0,0
SDNAME  rmb     256

        lda     DS
        sta     SDFRM+2
        lda     HS
        sta     SDFRM+3
        clr     SDFRM+4         ; mode 0
        ldx     #SDFRM
        ldy     #261
        jsr     FNXACT")

This is the pattern for every payload command in Chapter 12: declare the
frame with its fixed head and its buffer, patch the parameters in, and
send the whole thing as one write.

#colbreak()

#sect[Reading the directory]

The pattern goes in the same 256-byte field as the path, after the
path's own terminator:

#asmbox("        ldy     #ODPATH
        ldx     #MROOT          ; \"/\"
        jsr     SCOPY
        leay    1,y             ; over the NUL
        ldx     #MFILT          ; \"*.dsk\"
        jsr     SCOPY

MROOT   fcc     \"/\"
        fcb     0
MFILT   fcc     \"*.dsk\"
        fcb     0")

and the read loop watches for the two #hx("7F") bytes:

#cbox("while (n < MAXENT)
{
    if (!fuji_read_directory(36, 0, entry))
        break;
    if ((uint8_t) entry[0] == 0x7F)
        break;
    strcpy(names[n], entry);
    printf(\"%u %s\\n\", n + 1, names[n]);
    n++;
}
fuji_close_directory();")

Note the pattern is lowercase. Host filesystems are frequently
case-sensitive and the Color Computer's keyboard is not much help, so
the program carries its pattern as a constant rather than asking for one.

#ybox(title: [CLOSE THE DIRECTORY])[There is one directory handle for
the whole adapter. A program that exits without closing leaves the next
program --- CONFIG, very possibly --- unable to open one. The listing
closes even on the paths where it found nothing.]

#sect[What CONFIG adds]

Not very much, and it is worth saying what: prefixes, so you can walk
into a subdirectory; the #hx("40") bit on the mode byte, so a mounted
drive shows a marker; #cw("WRITE_DEVICE_SLOTS") and #cw("MOUNT_ALL"), so
the configuration survives a power cycle; and a screen you can navigate
with the arrow keys.

All four are commands in Chapter 12 and none of them changes the shape
of this program. The full listings are in Appendix C.5.

#v(4pt)
#gbar
]

// ============================================================
// 18. WEATHER
// ============================================================
#chapter("18. Weather",
  subs: ("Why a parser", "The sequence", "The frame the library gets wrong",
         "Asking a question"))
#ix("WEATHER", "Programs, WEATHER", "JSON")

#cols2[
The response from a modern web API is forty kilobytes of JSON and the
Color Computer has thirty-two. This program reads three numbers out of
one without ever holding more than sixty-four bytes of it.

#sect[Why a parser]

Because the parsing happens on the adapter. You open the channel, tell
the adapter to read the whole response and parse it, and from then on the
document is the adapter's problem. Each query you send selects a value,
and only that value crosses the wire.

It is the single most useful thing the network device does, and it is the
reason a 1980 machine can talk to a 2026 service at all.

#sect[The sequence]

#step(1)[#cw("OPEN") the URL with mode #hx("04") --- an HTTP GET.]

#step(2)[#cw("SET_PARSER") with the mode in #strong[aux2].]

#step(3)[#cw("PARSE"). The adapter reads the response to the end and
builds the document.]

#step(4)[For each question: #cw("QUERY") with a path, then
#cw("STATUS") to find out how long the answer is, then #cw("READ").]

#step(5)[#cw("CLOSE").]

#cbox("static char spec[] =
    \"N:HTTPS://api.open-meteo.com/v1/forecast\"
    \"?latitude=39.10&longitude=-94.58\"
    \"&current=temperature_2m,wind_speed_10m\";

network_open(spec, OPEN_MODE_HTTP_GET,
             OPEN_TRANS_NONE);
json_mode(network_unit(spec));
show(\"TIME.. \", \"/current/time\");
show(\"TEMP.. \", \"/current/temperature_2m\");
show(\"WIND.. \", \"/current/wind_speed_10m\");
network_close(spec);")

#tv(
  vrow(N("FUJINET WEATHER" + rp(" ", 17))),
  vrow(N(rp(" ", 32))),
  vrow(N("TIME.. 2026-09-22T14:00" + rp(" ", 9))),
  vrow(N("TEMP.. 27.4" + rp(" ", 21))),
  vrow(N("WIND.. 11.9" + rp(" ", 21))),
  vrow(N(rp(" ", 32))),
  vrow(N("OK" + rp(" ", 30))),
  ..range(9).map(_ => FR(vg.g)))

#colbreak()

#sect[The frame the library gets wrong]

This is the program in this book that has to go below fujinet-lib, and
it is worth understanding why rather than just copying the workaround.

#cw("network_json_parse()") sends #cw("SET_PARSER") with the mode in
aux1 and zero in aux2. The firmware reads the mode out of aux2. So the
call succeeds, selects the null parser, and every query afterwards comes
back empty --- which looks exactly like an API that has stopped
answering.

Five bytes fix it:

#cbox("static uint8_t json_mode(uint8_t unit)
{
    struct { uint8_t op, unit, cmd,
                     aux1, aux2; } f;
    uint8_t e;

    f.op   = 0xE3;
    f.unit = unit;
    f.cmd  = 0xFC;          /* SET_PARSER */
    f.aux1 = 0;
    f.aux2 = 1;             /* JSON --- aux2 */

    bus_ready();
    dwwrite((byte *) &f, sizeof(f));
    e = network_get_error(unit);
    if (e != FN_ERR_OK)
        return e;

    f.cmd  = 'P';           /* PARSE */
    f.aux1 = f.aux2 = 0;

    bus_ready();
    dwwrite((byte *) &f, sizeof(f));
    return network_get_error(unit);
}")

and the assembly half never had the problem, because it was building the
frame by hand all along:

#asmbox("SPFRM   fcb     OPNET,0,NCSPARS,0,PMJSON
PAFRM   fcb     OPNET,0,NCPARSE,0,0")

#sect[Asking a question]

A query sets the channel's contents to whatever it selected, so the read
after it is an ordinary read:

#asmbox("ASK     pshs    x,y
        jsr     PUTS            ; the label
        ...                     ; clear QYSTR,
        ...                     ; copy the query in
        lda     NTUNI
        sta     QYFRM+1
        ldx     #QYFRM
        ldy     #QYLEN          ; 5 + 256
        ldb     NTUNI
        jsr     NTXACT
        bne     ASKBAD
        ldx     #STBUF
        jsr     NTSTAT
        ldd     STBUF
        beq     ASKBAD
        ...                     ; clamp, read, print")

An empty answer is not an error --- it means the path selected nothing,
which usually means a typo in the path or an API that changed its
shape. Print a question mark and carry on; the listing does.

Both halves are in Appendix C.6.

#v(4pt)
#gbar
]

// ============================================================
// 19. FNSTAT UNDER OS-9
// ============================================================
#chapter("19. fnstat under OS-9",
  subs: ("Three files", "The transport", "The bus", "Building it",
         "What is verified"))
#ix("fnstat", "Programs, fnstat", "OS-9")

#cols2[
The last program asks the same question as the first --- who is on the
other end of the wire --- and answers it from inside OS-9, where none of
the machinery the rest of this book uses is available.

It is thirty lines on top of two files that are the real content of this
chapter.

#sect[Three files]

#dotdef(
  ("dwport.c", [#cw("dwread") and #cw("dwwrite"). Twenty lines of inline
    6809 and the only part that touches hardware.]),
  ("fnbus.c", [#cw("fn_wait"), #cw("fn_error"), #cw("fn_send"),
    #cw("fn_response"). Chapter 6's library, in C.]),
  ("fnstat.c", [the program.]),
)

Nothing above #cw("dwport.c") knows what kind of wire it is on. That is
the whole argument of Chapter 3, cashed in.

#sect[The transport]

Memory-mapped: status at #hx("FF41"), data at #hx("FF42"). Interrupts
masked, because the port holds one byte and an OS-9 clock tick will take
it. A timeout, because #cw("fn_wait") retries and a poll loop with no
timeout would never give it the chance.

#cbox("byte dwread(byte *s, int l)
{
    asm
    {
        pshs    cc,x,y,u
        orcc    #$50
        ldx     :s
        ldy     :l
        beq     @ok
@byte   ldu     #$2000
@wait   lda     $FF41
        bita    #$02
        bne     @got
        leau    -1,u
        bne     @wait
        bra     @timeout
@got    lda     $FF42
        sta     ,x+
        leay    -1,y
        bne     @byte
@ok     puls    cc,x,y,u
        ldb     #1
        bra     @exit
@timeout
        puls    cc,x,y,u
        clrb
@exit
    }
}")

This is the Becker port, the CoCo 3 FPGA's DriveWire window and the
high-speed UART cartridge. For the bit-banger --- which is what a
FujiNet cartridge actually plugs into --- take #cw("DWRead") and
#cw("DWWrite") from your NitrOS-9 or DriveWire sources and put them
behind these two names. Chapter 11 says why this book does not reprint
them.

#colbreak()

#sect[The bus]

Four functions, and they are recognisably the same four:

#cbox("void fn_wait(void)
{
    byte frame[2];
    byte r;

    frame[0] = 0xE2;
    frame[1] = 0x00;

    do
        dwwrite(frame, sizeof(frame));
    while (!dwread(&r, 1));
}

byte fn_send(byte *frame, int len)
{
    fn_wait();
    dwwrite(frame, len);
    return fn_error();
}")

And then the program is Chapter 5 again:

#cbox("frame[0] = 0xE2;
frame[1] = 0xC4;            /* ADAPTERCONFIG_EXT */

e = fn_send(frame, sizeof(frame));
if (e != FN_OK) { ... }

e = fn_response(cfg, 240);
if (e != FN_OK) { ... }

printf(\"network  %s\\n\", &cfg[0]);
printf(\"address  %s\\n\", &cfg[140]);
printf(\"firmware %s\\n\", &cfg[125]);")

with the offsets spelled out instead of a structure, because we are not
linking fujinet-lib and so we do not have its headers.

#sect[Building it]

#shbox("$ cmoc --os9 -o fnstat \\
      fnstat.c fnbus.c dwport.c
$ os9 copy fnstat /dd/CMDS/fnstat
$ chmod e+ /dd/CMDS/fnstat")

and then it is an ordinary command:

#shbox("$ fnstat
network  HOME-2G
address  192.168.1.44
firmware 1.8.1")

Lowercase, because OS-9 has a screen that can show it.

#sect[What is verified]

Plainly, because the rest of this book is:

#bl[The three files compile with #cw("cmoc --os9"), and Appendix C.7
prints them from the files that compiled.]

#bl[The transport is correct by inspection of the register map. It has
not been run against hardware for this book.]

#bl[The bit-banger route is described, not supplied.]

#bl[Everything from #cw("fn_wait()") upward is the same protocol as the
rest of the book, and that part is verified throughout it.]

#v(4pt)
#gbar
]

// ============================================================
// 20. ALWAYS MORE TO COME
// ============================================================
#chapter("20. Always More To Come",
  subs: ("The other book", "Where the sources are", "Where the people are"))
#ix("Network Protocol Handbook", "Further reading")

#cols2[
This book documents the bus: how to get a command to the adapter and an
answer back. It has said almost nothing about what is at the far end of a
URL, and that is deliberate, because the far end has a book of its own.

#sect[The other book]

The #emph[FujiNet Network Protocol Handbook] is the companion volume, and
it documents every scheme the #cw("N:") device speaks: #cw("TCP:"),
#cw("TELNET:"), #cw("UDP:"), #cw("HTTP:") and #cw("HTTPS:"),
#cw("TNFS:"), #cw("SMB:"), #cw("FTP:"), #cw("SSH:"), #cw("JSON:"),
#cw("GMAIL:"), #cw("GCAL:") and more --- what each one does with the
open modes, what a directory looks like on it, which of them support
seeking, and what their error codes mean.

Everything in it applies to the Color Computer without change. A
devicespec is a devicespec.

#sect[Where the sources are]

Nothing in this book is a secret and all of it moves. The places to look
when this book and the adapter disagree:

#dotdef(
  ("fujinet-firmware", [the adapter. #cw("lib/bus/drivewire/") is this
    bus; #cw("lib/device/fujiDevice/") and #cw("lib/device/NDevice/")
    are the two devices in Chapters 12 and 13.]),
  ("fujinet-lib", [the C client library. #cw("coco/src/") is this
    platform's half.]),
  ("fujinet-apps", [real programs, several of them with a
    #cw("coco/") directory.]),
  ("fujinet-hardware", [the cartridge: schematics, board files and the
    case.]),
)

All of them are on GitHub under #cw("FujiNetWIFI"), and all of them take
patches. The firmware bugs this book names in Chapters 12, 13 and 14 are
named precisely so that somebody can fix them; if you are that somebody,
the fix is welcome and this book will be wrong in the next edition,
happily.

#colbreak()

#sect[Where the people are]

#dotdef(
  ("fujinet.online", [the project, the documentation and the disk
    images]),
  ("The Discord", [where the firmware is argued about and where somebody
    will answer a question about a desynchronised bus at two in the
    morning]),
  ("github.com/FujiNetWIFI", [the sources, the issues and the wiki
    edition of this book]),
)

#v(0.2in)

#align(center, box(width: 4.6in, {
  set par(justify: false, leading: 0.55em)
  set text(size: 9.6pt, style: "italic")
  align(center)[
    Every address, frame and listing in this book was transcribed from
    the live FujiNet sources and checked against a client that speaks to
    them. When in doubt, the sources win.
  ]
  v(8pt)
  line(length: 40%, stroke: 0.7pt + grn-d)
  v(8pt)
  set text(size: 9pt, style: "normal")
  align(center)[The FujiNet Project · fujinet.online]
}))

#v(0.25in)

#ybox(title: [A LAST WORD])[The Color Computer was sold as a machine you
could program, in a store, with a manual in the box. That the same
machine can now hold a JSON conversation with a weather service is not
nostalgia; it is the machine doing exactly what it was sold to do, forty
years later, because somebody wrote down how.

Write something. Put it on a disk image. Tell somebody where to find it.]

#v(4pt)
#gbar
]

// ============================================================
// APPENDIX A — DRIVEWIRE QUICK REFERENCE
// ============================================================
#appendix("A", "DriveWire Quick Reference",
  subs: ("Vectors", "Opcodes", "Frames", "The dance", "Modes"))
#ix("Quick reference")

#cols2[
#sect[The two vectors]

#dotdef(
  (hx("D93F"), [#cw("DWRead") --- X = buffer, Y = count. #strong[Z set]
    when every byte arrived; carry set on a framing error. Clobbers Y (a
    checksum) and all accumulators; keeps X and U. Times out in about
    1.5 seconds.]),
  (hx("D941"), [#cw("DWWrite") --- X = buffer, Y = count. X ends one past
    the last byte, Y ends zero. No error return.]),
)

On a Dragon: #hx("F9FE") and #hx("FA00").

#sect[Baud by model]

#dotdef(
  ("Color Computer 1", "38,400"),
  ("Color Computer 2", "57,600"),
  ("Color Computer 3", "115,200"),
  ("Dragon", "57,600"),
  ("High-speed UART", "921,600"),
  ("DriveWire over IP", "TCP port 65504"),
)

#sect[The four FujiNet devices]

#dotdef(
  (hx("E2"), [the FujiNet control device --- Chapter 12]),
  (hx("E3"), [the #cw("N:") network devices --- Chapter 13]),
  (hx("E4"), [CP/M --- Chapter 14, ESP32 firmware only]),
  (hx("E5"), [the clock --- Chapter 14]),
)

#sect[Bus opcodes]

#dotdef(
  (hx("00"), "NOP"),
  (hx("01"), "named object mount (Dragon)"),
  (hx("23"), "clock --- six bytes back"),
  (hx("43"), "serial read"),
  (hx("44"), "serial get status"),
  (hx("45"), "serial init"),
  (hx("46"), "print flush (ignored)"),
  (hx("47"), "get status"),
  (hx("49"), "init"),
  (hx("50"), "print one byte"),
  (hx("53"), "set status"),
  (hx("54"), "terminate"),
  (hx("57"), "write a sector"),
  (hx("5A"), "DWINIT --- replies $04"),
  (hx("63"), "serial read multiple"),
  (hx("64"), "serial write multiple"),
  (hx("77"), "re-write a sector"),
  (hx("80") + "--" + hx("8F"), "fast write, channel in the low nybble"),
  (hx("A5"), "replies \"FUJINET\""),
  (hx("C3"), "serial write one byte"),
  (hx("C4"), "serial set status"),
  (hx("C5"), "serial terminate"),
  (hx("D2"), "read a sector"),
  (hx("F2"), "re-read a sector"),
  (hx("F8") + " " + hx("FE") + " " + hx("FF"), "reset"),
)

#colbreak()

#sect[Frames]

The FujiNet control device, #hx("E2"):

#bytefield((hx("E2"), 2), ([command], 2), ([0 to 3 aux bytes], 3),
  ([payload, if any], 4))

The network device, #hx("E3") --- always two aux bytes:

#bytefield((hx("E3"), 2), ([unit], 2), ([command], 2), ([aux1], 2),
  ([aux2], 2), ([payload], 3))

Multi-byte parameters and replies are #strong[high byte first], which is
the 6809's own order. The four exceptions, all replies:
#cw("GET_DIRECTORY_POSITION"), #cw("RANDOM_NUMBER"), the network
device's #cw("TELL"), and the write-sector checksum.

#sect[The three meta-commands]

#dotdef(
  (hx("00"), [#cw("DEVICE_READY") --- replies #hx("01")\; loop until it
    does]),
  (hx("02"), [#cw("SEND_ERROR") --- one byte, #hx("01") is success]),
  (hx("01"), [#cw("SEND_RESPONSE") --- the parked reply; you supply the
    count]),
)

#sect[The dance]

#step(1)[#hx("E2") #hx("00"), read one byte, loop until it comes.]
#step(2)[The command frame. Nothing comes back.]
#step(3)[#hx("E2") #hx("02"), read the verdict.]
#step(4)[If it owes you data, #hx("E2") #hx("01") and read exactly the
count on the card.]

On the network device every one of those carries the unit and two aux
bytes, and #cw("SEND_RESPONSE") takes the length in its aux word.

The clock, #hx("E5"), skips the whole thing: write the frame, read the
reply.

#sect[Open modes and translation]

#dotdef(
  (hx("04") + " / " + hx("06") + " / " + hx("07"), "read · directory · directory alt"),
  (hx("08") + " / " + hx("09") + " / " + hx("0C"), "write · append · read and write"),
  (hx("05") + " / " + hx("0D") + " / " + hx("0E"), "HTTP DELETE · POST · PUT with headers"),
)

#dotdef(
  (hx("00"), "no translation"),
  (hx("01"), "CR --- the Color Computer's own"),
  (hx("02") + " / " + hx("03"), "LF · CR LF"),
  (hx("04"), "PETSCII"),
)

#sect[Sector protocol]

#dotdef(
  ("read", [#hx("D2") drive lsn(3) → 256 bytes → checksum #strong[hi lo]] ),
  ("", [→ status: #hx("00") ok · #hx("F4") read · #hx("F6") drive ·
    211 EOF · 243 checksum]),
  ("write", [#hx("57") drive lsn(3) 256 bytes checksum #strong[lo hi]]),
  ("", [→ status: #hx("00") ok · #hx("F5") write · #hx("F6") drive]),
)

#v(4pt)
#gbar
]

// ============================================================
// APPENDIX B — ERROR AND STATUS CODES
// ============================================================
#appendix("B", "Error and Status Codes",
  subs: ("The device error byte", "Sector status", "Network status",
         "WiFi status", "The library's codes"))
#ix("Error codes", "Status codes")

#cols2[
#sect[The device error byte]

What #cw("SEND_ERROR") --- command #hx("02") on #hx("E2") or #hx("E3")
--- gives you. One is success; everything else is a complaint.

#dotdef(
  ("1", "success"),
  ("131", "the channel is write-only"),
  ("132", "invalid command"),
  ("135", "the channel is read-only"),
  ("136", "end of file --- not a failure"),
  ("138", "general timeout"),
  ("144", "a fatal error; also what the bus sets on any refused command"),
  ("146", "not implemented"),
  ("151", "the file exists"),
  ("162", "no space left on the device"),
  ("165", "the devicespec was not understood"),
  ("166", "invalid seek position"),
  ("167", "access denied"),
  ("170", "file not found"),
  ("200", "connection refused"),
  ("201", "network unreachable"),
  ("202", "socket timeout"),
  ("203", "network down"),
  ("204", "connection reset"),
  ("205", "connection already in progress"),
  ("206", "address in use"),
  ("207", "not connected"),
  ("208", "the server is not running"),
  ("209", "no connection waiting"),
  ("210", "service not available"),
  ("211", "connection aborted"),
  ("212", "invalid username or password"),
  ("213", "could not parse the document"),
  ("214", "general client error"),
  ("215", "general server error"),
  ("255", "could not allocate buffers"),
)

#ybox(title: [136 IS NOT A FAILURE])[End of file is how a resource says
it is finished. A program that treats it as an error will report a
failure every time it successfully reads a whole file. Check for it
before you check for anything else.]

#ybox(title: [144 MEANS TWO THINGS])[It is the firmware's general fatal
error, and it is also what the bus writes when a command it does not
recognise takes the error path. On the network device a 144 from a
command you are sure exists usually means you misspelled it.]

#colbreak()

#sect[Sector status]

The byte that ends an #hx("D2") or #hx("57") exchange:

#dotdef(
  (hx("00"), "success"),
  (hx("F4"), "read error"),
  (hx("F5"), "write error"),
  (hx("F6"), "invalid or inactive drive"),
  ("211", "past the end of the image"),
  ("243", "your checksum did not match --- read only"),
)

#sect[Network status]

The four bytes #cw("STATUS") returns on #hx("E3"):

#bytefield(([waiting, high], 3), ([waiting, low], 3), ([connected], 3),
  ([error], 3))

#dotdef(
  ("bytes waiting", [how much you may read. Zero is normal.]),
  ("connected", [non-zero while the far end is there.]),
  ("error", [the channel's own code, from the table opposite. 1 is
    fine; 136 is the end; 207 means nothing is open.]),
)

The end of a resource is #strong[136], or zero waiting with the
connected byte clear. Never zero waiting on its own.

#sect[WiFi status]

The byte #cw("GET_WIFISTATUS") returns:

#dotdef(
  ("1", "no SSID available"),
  ("3", "connected"),
  ("4", "connection failed"),
  ("5", "connection lost"),
  ("6", "disconnected"),
)

In practice you will see 3 and 6.

#sect[The library's codes]

fujinet-lib's #cw("network_") calls return these instead of the
adapter's byte. The raw byte is left in #cw("fn_device_error").

#dotdef(
  ("FN_ERR_OK", hx("00")),
  ("FN_ERR_IO_ERROR", hx("01")),
  ("FN_ERR_BAD_CMD", hx("02")),
  ("FN_ERR_OFFLINE", hx("03")),
  ("FN_ERR_WARNING", hx("04")),
  ("FN_ERR_NO_DEVICE", hx("05")),
  ("FN_ERR_UNKNOWN", hx("FF")),
)

The Color Computer's mapping is blunt: exactly #hx("01") becomes
#cw("FN_ERR_OK") and everything else becomes #cw("FN_ERR_IO_ERROR"). To
tell end-of-file from connection-refused, read #cw("fn_device_error").

The #cw("fuji_") calls return a #cw("bool") instead, and leave the byte
in the same place.

#v(4pt)
#gbar
]

// ============================================================
// APPENDIX C — PROGRAM LISTINGS
// ============================================================
#appendix("C", "Program Listings",
  subs: ("The equates", "The library", "The console", "Netcat", "Mounter",
         "Weather", "OS-9"))
#ix("Listings", "Program listings")

#block({
  set par(first-line-indent: 0pt, justify: true)
  [Every file here is read off the disk when this book is typeset, so
  what is printed is the text that produced the binaries --- character
  for character, with nothing retyped and nothing abridged. The
  Makefiles that build them are in the same directories.

  The assembly files assemble with #cw("lwasm 4.24") and the C files
  compile with #cw("cmoc 0.1.100"). Neither has been run against
  hardware for this book; every byte layout in them was read out of the
  firmware and every one of them builds from clean.]
})

#sect[C.1 The equates]
#code-listing("fn.inc", "listings/fnlib/fn.inc")

#sect[C.2 The library]
#code-listing("fnlow.asm --- the handshake, the verdict, the response",
  "listings/fnlib/fnlow.asm")
#code-listing("fnnet.asm --- the five moves of the N: device",
  "listings/fnlib/fnnet.asm")

#sect[C.3 The console]
#code-listing("cocoio.asm --- screen and keyboard",
  "listings/fnlib/cocoio.asm")

#sect[C.4 First contact]
#code-listing("fcdemo.asm", "listings/fnlib/fcdemo.asm")
#code-listing("fcdemo.c", "listings/fnlib/fcdemo.c")

#sect[C.5 Netcat]
#code-listing("netcat.asm", "listings/netcat/netcat.asm")
#code-listing("netcat.c", "listings/netcat/netcat.c")

#sect[C.6 Mounter]
#code-listing("mounter.asm", "listings/mounter/mounter.asm")
#code-listing("mounter.c", "listings/mounter/mounter.c")

#sect[C.7 Weather]
#code-listing("weather.asm", "listings/weather/weather.asm")
#code-listing("weather.c", "listings/weather/weather.c")

#sect[C.8 OS-9]
#code-listing("dwport.h", "listings/os9/dwport.h")
#code-listing("dwport.c --- DWRead and DWWrite for a memory-mapped port",
  "listings/os9/dwport.c")
#code-listing("fnbus.h", "listings/os9/fnbus.h")
#code-listing("fnbus.c --- the four moves, above your own transport",
  "listings/os9/fnbus.c")
#code-listing("fnstat.c", "listings/os9/fnstat.c")

#sect[C.9 The Makefiles]
#code-listing("listings/common.mk", "listings/common.mk")
#code-listing("listings/netcat/Makefile", "listings/netcat/Makefile")
#code-listing("listings/os9/Makefile", "listings/os9/Makefile")

#gbar

// ============================================================
// APPENDIX D — TROUBLESHOOTING
// ============================================================
#appendix("D", "Troubleshooting")
#ix("Troubleshooting")

#block({
  set par(first-line-indent: 0pt, justify: true)
  [Every row here is something that has actually happened to somebody,
  and most of them cost an evening.]
})

#symrem(
  ([The program hangs before printing anything.],
   [#cw("FNWAIT") loops forever by design --- it is waiting for an
    adapter that may simply be busy. Before you know one is there, send
    the seven-byte probe from Chapter 3: #hx("A5") and seven bytes back.
    It gives up in a second and a half.]),

  ([Nothing works after the first command, and the first command worked.],
   [The bus is out of step. Something sent fewer bytes than a command
    declared --- an unpadded devicespec, an app key write shorter than
    64 bytes, a base64 output with no length word --- or you sent a
    command the control device does not dispatch and it left your
    payload in the buffer. Only a reset recovers it.]),

  ([A command reports success and does nothing.],
   [It is probably not dispatched. The control device clears its error
    to #emph[success] before looking for a handler, so an unrecognised
    command answers #hx("01"). Check it against Chapter 12.12.]),

  ([#cw("network_json_parse()") succeeds and every query is empty.],
   [The library sends the parser mode in aux1; the firmware reads aux2.
    Send the five-byte frame yourself --- Chapter 18 does.]),

  ([Reads come back padded with zeros.],
   [You asked for more bytes than #cw("STATUS") said were waiting. The
    adapter pads the reply to the length you named. Ask for what is
    there.]),

  ([The read loop never ends.],
   [You are testing for zero bytes waiting instead of for error 136 or a
    clear connected byte. A quiet socket has nothing waiting and is
    perfectly healthy.]),

  ([The count register is wrong after a read.],
   [#cw("DWRead") returns the block's checksum in #cw("Y"). Push it.]),

  ([The program branches on the carry after a read and behaves oddly.],
   [It is the #strong[zero] flag that says the read worked. The carry is
    a framing error, which is a rarer and different complaint.]),

  ([A two-byte value comes out byte-swapped.],
   [Almost everything on this bus is big-endian, which is the 6809's own
    order --- so you should not be swapping at all. The four exceptions
    are #cw("GET_DIRECTORY_POSITION"), #cw("RANDOM_NUMBER"), the network
    #cw("TELL"), and the write-sector checksum.]),

  ([#cw("MOUNT_IMAGE") succeeds but the drive is empty.],
   [The name was never written into the slot. #cw("SET_DEVICE_FULLPATH")
    comes first, and #cw("MOUNT_HOST") before that.]),

  ([The directory opens once and never again.],
   [There is one directory handle for the whole adapter and a previous
    program exited without calling #cw("CLOSE_DIRECTORY"). Send one.]),

  ([#cw("COPY_FILE") wedges the bus.],
   [It is broken in the firmware: the handler never reads its payload.
    Do not send it. Chapter 12.5 has the detail.]),

  ([Setting the timezone hangs the adapter.],
   [Also a firmware bug --- the length is byte-swapped twice, so a
    three-byte name arrives as 768. Use the web interface.]),

  ([Everything worked yesterday and the adapter is silent today.],
   [Check the model switches. They set the baud rate, and a CoCo 1 at
    38,400 and a CoCo 3 at 115,200 do not talk to each other.]),

  ([Lowercase comes out as inverse video.],
   [That is the MC6847 doing exactly what it has always done. It is not
    a FujiNet problem and there is no fixing it from this side; either
    uppercase your output or use a hi-res text screen.]),
)

#gbar

// ============================================================
// INDEX
// ============================================================
#chapter("Index", subs: (), toc: true)

#context {
  let marks = query(metadata).filter(m =>
    type(m.value) == dictionary and m.value.at("kind", default: "") == "ix")
  let entries = (:)
  for m in marks {
    let p = counter(page).at(m.location()).first()
    let t = m.value.term
    if t in entries {
      if p not in entries.at(t) { entries.at(t).push(p) }
    } else {
      entries.insert(t, (p,))
    }
  }
  let keys = entries.keys().sorted()
  let half = calc.ceil(keys.len() / 2)
  let lead = box(width: 1fr, inset: (bottom: 1.5pt),
    align(bottom, repeat(text(size: 7.5pt)[.#h(2.2pt)])))
  let colhead = {
    block(below: 0.7em, {
      text(font: f-sans, weight: 700, size: 9pt)[Subject]
      h(1fr)
      text(font: f-sans, weight: 700, size: 9pt)[Page]
    })
  }
  let entryline(k) = block(above: 0.45em, below: 0pt, {
    text(size: 9pt, k)
    lead
    text(size: 9pt, entries.at(k).map(str).join(", "))
  })
  grid(columns: (1fr, 1fr), column-gutter: 0.45in,
    { colhead; for k in keys.slice(0, half) { entryline(k) } },
    { colhead; for k in keys.slice(half) { entryline(k) } })
}

#gbar

// ============================================================
// BACK COVER
// ============================================================
#fst.update(false)
#page(margin: 0pt, footer: none)[
  #place(image("images/starfield.png", width: 100%, height: 100%))
  #place(top + left, dx: 0.32in, dy: 0.32in,
    rect(width: 10in - 0.64in, height: 8in - 0.64in,
      stroke: 2.6pt + cvr-mag))
  #place(top + left, dx: 0.38in, dy: 0.38in,
    rect(width: 10in - 0.76in, height: 8in - 0.76in,
      stroke: 0.8pt + cvr-mag))

  #place(top + center, dy: 1.15in, {
    set par(leading: 0.4em)
    align(center)[
      #text(font: f-cover, weight: 700, size: 30pt, fill: cvr-blu)[FUJINET]
      #linebreak()
      #v(0.16in)
      #text(font: f-sans, size: 11pt, fill: cvr-mag, tracking: 1.2pt)[
        THE SOURCES WIN]
    ]
  })

  #place(top + center, dy: 2.5in,
    box(width: 6.4in, {
      line(length: 100%, stroke: 0.8pt + cvr-blu)
      v(10pt)
      set par(justify: false, leading: 0.6em)
      align(center, text(font: f-body, size: 10pt, fill: rgb("#cfe0f2"))[
        Every opcode, command byte, parameter and reply length in this
        book was transcribed from the FujiNet firmware and checked against
        a client that speaks to it. Firmware moves. When this book and the
        sources disagree, the sources are right and this book has a bug.
        Report it and the next edition will be better.
      ])
      v(10pt)
      line(length: 100%, stroke: 0.8pt + cvr-blu)
    }))

  #place(bottom + center, dy: -1.35in,
    box(width: 7.6in, grid(columns: (1fr, 1fr, 1fr), column-gutter: 0.3in,
      align: top,
      ..(
        ([CHAT], [The Discord. Somebody will answer a question about a
          desynchronised bus at two in the morning.]),
        ([SOURCES], [github.com/FujiNetWIFI --- the firmware, the client
          library, the applications and the hardware.]),
        ([LIBRARY], [fujinet.online --- the project, the documentation and
          a great many disk images.]),
      ).map(c => {
        set par(justify: false, leading: 0.55em)
        align(center, {
          text(font: f-sans, weight: 700, size: 9pt, fill: cvr-mag,
            tracking: 1pt, c.at(0))
          v(5pt)
          text(font: f-body, size: 8.4pt, fill: rgb("#bcd3ea"), c.at(1))
        })
      }))))

  #place(bottom + center, dy: -0.55in,
    text(font: f-sans, size: 8pt, fill: cvr-blu, tracking: 0.6pt)[
      CUSTOM CRAFTED BY THE FUJINET COMMUNITY
      #h(4pt)#box(image("images/fujinet-logo.png", height: 11pt), baseline: 2.5pt)#h(4pt)
      A WORLDWIDE FREE-SOFTWARE PROJECT])
]
