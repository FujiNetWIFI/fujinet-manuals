// ============================================================
// FUJINET COLECOVISION -- PROGRAMMERS HANDBOOK
// The FujiNet programming manual for the ColecoVision: the cartridge
// mailbox tutorial, the Z80 assembler and Z88DK C client libraries, the
// complete command reference for every device the FujiNet answers, and
// four worked programs (NETCAT, 5 CARD STUD, BATTLESHIP, CONFIG) with
// full listings.
//
// House style: the FujiNet engineering series (matching The FujiNet Network
// Protocol Handbook and the Platform Bring-Up Guide) -- single-column
// US-Letter, Nimbus Roman body, Nimbus Sans heads, Source Code Pro listings,
// FujiNet red accents, sticky headings, and strict widow/orphan control.
//
// Every address, opcode, struct offset and code fragment is transcribed from
// the live project sources; see README.md for the sources-of-truth table
// with commit hashes.
//
// Build: typst compile --font-path fonts manual.typ
// ============================================================

#let f-head   = "Nimbus Sans"
#let f-body   = "Nimbus Roman"
#let f-mono   = "Source Code Pro"
#let f-screen = "Coleco Screen"
#let f-serif  = f-body           // compatibility alias

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
#let perif  = rgb("#7a3b2e")            // diagram "FujiNet/server" lane
#let gray   = rgb("#6d6a63")

// compatibility aliases so body diagram calls resolve on the new palette
#let blue   = slate
#let blue-d = steel
#let blue-l = rule-c
#let gray-l = rule-c
#let panel  = note-bg
#let cream  = paper
#let cream2 = code-bg
#let warn   = fuji
// TV-mockup screen colours
#let scr-bg = rgb("#12161c")
#let scr-fg = rgb("#eef1f5")
#let scr-gn = rgb("#6fca7a")
#let scr-bl = rgb("#5ab0e6")

// ---------- document & page geometry --------------------------------
#set document(title: "FujiNet ColecoVision Programmers Handbook",
              author: "FujiNet Project")
#set page(
  paper: "us-letter",
  margin: (top: 1.0in, bottom: 1.0in, inside: 1.05in, outside: 0.9in),
)
#set text(font: f-body, size: 10.5pt, fill: ink, lang: "en")
// Widow/orphan/runt discipline -- the piece the NPH itself lacks. High
// widow/orphan costs push a stranded line's whole paragraph rather than
// leaving one line alone at a column edge; block paragraphs (space, no
// indent) let that happen without ugly gaps.
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
    // appendix sections carry their own "C.1" labels in the title text, so
    // they are not auto-numbered; body sections get "5.1"-style numbers.
    if appendix.get() { it.body }
    else if it.numbering != none { counter(heading).display("1.1") + h(9pt) + it.body }
    else { it.body }
  }))

// level 3 and 4 styled but unnumbered, to keep the run-in heads clean.
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
  text(font: f-mono, size: 8.4pt, fill: ink, it))

// ---------- callouts ------------------------------------------------
#let callout(label, body, bg, bar, lc: ink) = block(
  width: 100%, above: 0.95em, below: 0.95em, breakable: true,
  fill: bg, inset: (x: 10pt, y: 8pt), stroke: (left: 3pt + bar, rest: none),
  {
    text(font: f-head, weight: 800, size: 8.5pt, fill: lc, tracking: 0.6pt,
      upper(label))
    v(3pt, weak: true)
    set par(leading: 0.6em, justify: true, first-line-indent: 0pt)
    body
  })
#let note(body)      = callout("Note", body, note-bg, steel, lc: slate)
#let important(body)  = callout("Important", body, amber-bg, amber, lc: amber)
#let caution(body)   = callout("Caution", body, warn-bg, fuji, lc: fuji-d)
#let warning(body)   = callout("Warning", body, warn-bg, fuji, lc: fuji-d)

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

// ---------- paired ASM / C example, side by side --------------------
#let pair(asm-txt, c-txt, size: 7.6pt) = block(above: 0.7em, below: 0.85em,
  breakable: false, {
  set par(justify: false, leading: 0.5em, first-line-indent: 0pt)
  grid(columns: (1fr, 1fr), column-gutter: 9pt,
    block(fill: code-bg, inset: (x: 8pt, y: 6pt), radius: 1pt, width: 100%,
      stroke: (left: 2.5pt + fuji.mix((paper, 35%)), rest: 0.6pt + code-bd), {
      text(font: f-head, weight: 800, size: 6.4pt, fill: fuji, tracking: 0.5pt)[Z80 ASSEMBLER]
      v(3pt)
      text(font: f-mono, size: size, fill: ink,
        asm-txt.split("\n").map(l => if l == "" { " " } else { l }).join(linebreak()))
    }),
    block(fill: code-bg, inset: (x: 8pt, y: 6pt), radius: 1pt, width: 100%,
      stroke: (left: 2.5pt + slate.mix((paper, 40%)), rest: 0.6pt + code-bd), {
      text(font: f-head, weight: 800, size: 6.4pt, fill: slate, tracking: 0.5pt)[Z88DK C]
      v(3pt)
      text(font: f-mono, size: size, fill: ink,
        c-txt.split("\n").map(l => if l == "" { " " } else { l }).join(linebreak()))
    }))
})

// ---------- figures with italic captions ----------------------------
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

// blue/red run-in numeral for inline enumerated points
#let rnum(n) = text(font: f-head, weight: 800, fill: fuji, [#n.])

// ---------- numbered step (procedures) ------------------------------
#let step(n, body) = block(above: 0.5em, below: 0.5em, breakable: false, grid(
  columns: (0.3in, 1fr), column-gutter: 0.1in, row-gutter: 0pt,
  text(font: f-head, weight: 800, size: 11pt, fill: fuji,
    [#str(n).]),
  par(leading: 0.58em, first-line-indent: 0pt, body)))

// ---------- TV / screen mockup --------------------------------------
#let tv(txt, size: 8pt, fg: scr-fg, w: 3.0in) = box(
  fill: rgb("#d7dbe0"), radius: 6pt, inset: 7pt, stroke: 1pt + slate,
  box(fill: scr-bg, radius: 3pt, inset: (x: 10pt, y: 9pt), width: w - 14pt,
    align(left, {
      set par(leading: 0.5em, first-line-indent: 0pt)
      text(font: f-screen, size: size, fill: fg,
        txt.split("\n").map(l => if l == "" { " " } else { l })
          .join(linebreak()))
    })))

// keycap glyph
#let key(s) = box(baseline: 18%, fill: rgb("#ececec"), inset: (x: 4pt, y: 1pt),
  radius: 2pt, stroke: 0.5pt + rgb("#bdbdbd"),
  text(font: f-head, size: 8pt, s))

// dot-leader definition row
#let dotdef(..rows) = {
  set par(first-line-indent: 0pt)
  grid(columns: (108pt, 1fr), row-gutter: 4pt, column-gutter: 0pt,
    ..rows.pos().map(r => (
      box(width: 100%, {
        text(font: f-head, size: 9pt, weight: 600, r.at(0))
        box(width: 1fr, repeat(text(size: 9pt, fill: rule-c)[.], gap: 1.5pt))
      }),
      text(size: 9pt, r.at(1)))).flatten())
}

// two-column body is now single-column: identity passthrough
#let twocol(body) = body

// a displayed devicespec / command line
#let spec(s) = align(center, block(above: 0.6em, below: 0.6em,
  box(fill: code-bg, stroke: 0.6pt + code-bd, inset: (x: 10pt, y: 6pt),
    radius: 2pt,
    text(font: f-mono, size: 9pt, weight: 600, fill: ink, s))))

// ---------- command reference card ----------------------------------
#let cmdlab(s) = text(font: f-head, weight: 800, size: 6.8pt, fill: slate,
  tracking: 0.5pt, upper(s))
#let cmd(name, code: "", dev: "", nparam: "", params: "none",
         payload: "none", reply: "none", asm: none, c: none, body) = block(
  width: 100%, above: 1.1em, below: 1.1em, breakable: true, {
  block(breakable: false, sticky: true, fill: code-bg,
    stroke: (left: 3pt + fuji, rest: 0.6pt + code-bd),
    inset: (x: 11pt, y: 9pt), {
    grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
      text(font: f-head, weight: 800, size: 11.5pt, fill: fuji-d, name),
      text(font: f-mono, weight: 700, size: 9.5pt, fill: ink, code))
    v(5pt)
    grid(columns: (46pt, 1fr, 46pt, 1fr), row-gutter: 5pt, column-gutter: 8pt,
      cmdlab("device"),  text(font: f-mono, size: 8pt, dev),
      cmdlab("nparam"),  text(font: f-mono, size: 8pt, nparam),
      cmdlab("params"),  grid.cell(colspan: 3, text(size: 8.6pt, params)),
      cmdlab("payload"), grid.cell(colspan: 3, text(size: 8.6pt, payload)),
      cmdlab("reply"),   grid.cell(colspan: 3, text(size: 8.6pt, reply)),
    )
  })
  v(4pt)
  set par(first-line-indent: 0pt)
  body
  if asm != none and c != none { pair(asm, c) }
})

// ---------- tables --------------------------------------------------
#set table(stroke: (x, y) => (
  top: if y == 0 { 1pt + ink } else { 0.5pt + rule-c },
  bottom: 0.5pt + rule-c))
#show table.cell.where(y: 0): set text(font: f-head, weight: 800,
  size: 8.2pt, fill: white)
#set table(fill: (x, y) => if y == 0 { slate })
#set table(inset: (x: 6pt, y: 4pt))
#show table: set text(size: 8.6pt)

// ---------- SYMPTOM / REMEDY troubleshooting table ------------------
#let symrem(..rows) = {
  set par(first-line-indent: 0pt)
  table(columns: (0.95fr, 1.3fr), align: (left + top, left + top),
    table.header([SYMPTOM], [REMEDY]),
    ..rows.pos().map(r => (r.at(0), r.at(1))).flatten())
}

// ---------- byte-field strip ----------------------------------------
#let bytefield(..cells) = {
  let cs = cells.pos()
  align(center, block(above: 0.6em, below: 0.4em, breakable: false,
    grid(columns: cs.map(c => c.at(1)), rows: auto, stroke: 0.7pt + slate,
      ..cs.map(c => grid.cell(inset: 5pt, align: center,
        text(font: f-mono, size: 8pt, fill: ink, c.at(0)))))))
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

// ---------- appendix listing renderer -------------------------------
#let code-listing(title, path, size: 6.2pt, cols: 2) = {
  let src = read(path)
  // short files set one column at a readable size (no empty second column);
  // long files go two-up to keep the source archive compact.
  let n = src.split("\n").len()
  let c = if n < 58 { 1 } else { cols }
  let sz = if c == 1 { 7.0pt } else { size }
  block(breakable: false, above: 1.0em, below: 3pt, sticky: true, {
    text(font: f-head, weight: 800, fill: fuji, size: 8.5pt,
      tracking: 0.4pt, upper(title))
    v(2pt)
    line(length: 100%, stroke: 0.8pt + rule-c)
  })
  {
    show raw.where(block: true): it => block(width: 100%, breakable: true,
      fill: none, inset: 0pt, stroke: none,
      text(font: f-mono, size: sz, fill: ink,
        it.lines.join(linebreak())))
    show raw.line: it => {
      box(width: 12pt, align(right,
        text(size: sz * 0.72, fill: gray, str(it.number))))
      h(3pt)
      it.body
    }
    set par(justify: false, leading: 0.4em, hanging-indent: 14pt,
      first-line-indent: 0pt)
    columns(c, gutter: 16pt, raw(src, block: true))
  }
  v(2pt)
  line(length: 100%, stroke: 0.7pt + rule-c)
}

// ---------- running header & centered footer ------------------------
#set page(
  header: context {
    if frontmatter.get() { return }
    let pg = here().page()
    let openers = query(heading.where(level: 1)).filter(h => h.location().page() == pg)
    if openers.len() > 0 { return }
    let hs = query(heading.where(level: 1)).filter(h => h.location().page() <= pg)
    let c = if hs.len() > 0 { upper(hs.last().body) } else { [] }
    set text(font: f-head, size: 8pt, fill: slate)
    grid(columns: (1fr, auto),
      align(left)[FujiNet ColecoVision Programmers Handbook],
      align(right)[#c])
    v(-6pt)
    line(length: 100%, stroke: 0.5pt + rule-c)
  },
  footer: context {
    if frontmatter.get() { return }
    set text(font: f-head, size: 8.5pt, fill: slate)
    line(length: 100%, stroke: 0.5pt + rule-c)
    v(2pt)
    grid(columns: (1fr, auto, 1fr),
      align(left)[fujinet-firmware · pico/coleco],
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
    The ColecoVision\ Programmers Handbook]
  v(14pt, weak: true)
  text(font: f-body, style: "italic", size: 13pt, fill: slate)[
    Programming the FujiNet cartridge in Z80 assembly language and C]
  v(6pt, weak: true)
  text(font: f-head, size: 10pt, fill: steel)[
    The mailbox · a complete command reference · four worked programs]
  v(1fr)
  line(length: 100%, stroke: 0.5pt + rule-c)
  v(8pt)
  grid(columns: (1fr, 1fr), column-gutter: 18pt, row-gutter: 5pt,
    text(font: f-head, size: 9pt, fill: slate)[Z80 assembler & Z88DK C],
    align(right, text(font: f-head, size: 9pt, fill: slate)[First edition]),
    text(font: f-head, size: 9pt, fill: gray)[Every opcode source-verified],
    align(right, text(font: f-head, size: 9pt, fill: gray)[The FujiNet Project]),
  )
})

// ============================================================
// COLOPHON / CREDITS
// ============================================================
#page(header: none, footer: none, {
  v(0.2in)
  text(font: f-head, weight: 800, size: 15pt, fill: ink)[About this handbook]
  v(4pt)
  line(length: 100%, stroke: 1.5pt + fuji)
  v(10pt)
  set par(leading: 0.6em, justify: true)
  set text(size: 9.5pt, fill: slate)
  [This handbook teaches you to program the FujiNet cartridge for the
  ColecoVision, in both Z80 assembly language and C. It covers the cartridge
  #emph[mailbox] --- the in-memory protocol the console uses to talk to the
  adapter --- from first principles; a complete reference for every command the
  FujiNet answers, each with a worked example in both languages; and four real
  programs, explained end to end, with their full listings.

  It is typeset in the FujiNet engineering series style, alongside
  #emph[The FujiNet Network Protocol Handbook] and the #emph[Platform Bring-Up
  Guide]. Every address, opcode, structure offset and code fragment is
  transcribed from the live project sources and verified against the firmware
  and a running adapter.]
  v(14pt)
  text(font: f-head, weight: 800, size: 12pt, fill: ink)[Canonical sources]
  v(6pt)
  set text(size: 9pt, fill: ink)
  grid(columns: (auto, 1fr), row-gutter: 5pt, column-gutter: 12pt,
    text(font: f-mono, fill: fuji-d)[fujinet-firmware],
    [`pico/coleco` --- the mailbox spec, RP2040 firmware, MAME device, and CONFIG (`d1e89c21e`)],
    text(font: f-mono, fill: fuji-d)[fujinet-lib],
    [the ColecoVision mailbox bus, in the portable C library (`dc399ec`)],
    text(font: f-mono, fill: fuji-d)[fujinet-5cardstud],
    [the 5 Card Stud ColecoVision port (`f2b5298`)],
    text(font: f-mono, fill: fuji-d)[fujinet-battleship],
    [the Battleship ColecoVision port (`c413cba`)],
    text(font: f-mono, fill: fuji-d)[fujinet-go-coleco-desktop],
    [the desktop emulator + FujiNet (`e6db9ec`, v0.2.0)],
    text(font: f-mono, fill: fuji-d)[os7lib],
    [the OS-7 BIOS binding for Z88DK (`a6254e8`)],
    text(font: f-mono, fill: fuji-d)[z88dk],
    [`zcc` and `z88dk-z80asm` (`3bd06cad56`)],
  )
  v(1fr)
  line(length: 100%, stroke: 0.5pt + rule-c)
  v(6pt)
  set text(size: 7.5pt, fill: gray)
  set par(leading: 0.5em, justify: true)
  [ColecoVision and Coleco are trademarks of their respective holders; no
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
// CHAPTER: WELCOME TO FUJINET
// ============================================================
#chapter[Welcome to FujiNet]

#twocol[
Your ColecoVision was sold in 1982 as "the Arcade Quality Video Game
System." Four decades on, the FujiNet cartridge gives it something the
arcade never had: a network. Plug FujiNet into the cartridge slot and your
ColecoVision is online. WiFi. Web servers. Disk hosts over TNFS. Telnet
bulletin boards. Multiplayer game lobbies. All of it reachable from
3.58 megahertz of Z80.

FujiNet is a family of network adapters for classic computers and consoles.
On every platform it presents the same two personalities: the #emph[Fuji
device], which manages the adapter itself --- WiFi, host slots, directories,
mounting --- and the #emph[network device], the famous `N:`, which opens
connections to the outside world by URL. What differs per platform is only
the plumbing between the machine and the adapter. On the ColecoVision that
plumbing is a small, strict, rather beautiful protocol called the
#emph[mailbox], and it is the subject of this book.

#sub[What this handbook teaches]

You will learn, in order: how the FujiNet cartridge works and why the
ColecoVision edition is the way it is (a cartridge port that cannot write!);
how to install the tools; the mailbox, the in-memory protocol every program
uses to talk to the cartridge; how to drive it from Z80 assembly language
and from C with the Z88DK compiler; a complete reference for every command
the FujiNet answers, each with a worked example in both languages; and then
four real programs, explained end to end, with their listings in the
appendix: #strong[NETCAT], #strong[5 CARD STUD], #strong[BATTLESHIP], and
#strong[CONFIG].

#sub[What you will need]
]

#step(1)[A ColecoVision --- or MAME's `coleco` driver with the FujiNet
cartridge device grafted in (the firmware tree's
`pico/coleco/emu/apply.sh` does the grafting).]

#step(2)[A FujiNet cartridge --- or, under MAME, a running #emph[fujinet-pc]
with its bus-over-IP listener on `127.0.0.1:9995`.]

#step(3)[The Z88DK compiler (for `zcc` and `z88dk-z80asm`) and the `os7lib`
BIOS binding library. The next chapter installs both.]

#step(4)[This handbook, a cup of coffee, and a colour television. The
automatic colour circuitry will forgive long debugging sessions.]

#note[Everything network-side --- the URL schemes the `N:` device speaks,
from `TCP:` and `TELNET:` to `HTTPS:`, `JSON:`, `SSH:` and `GMAIL:` --- is a
book of its own: #emph[The FujiNet Network Protocol Handbook], from this
same series. This handbook teaches you to reach the `N:` device; that one
teaches you everything it can say once reached.]

// ============================================================
// CHAPTER: YOUR FUJINET CARTRIDGE
// ============================================================
#chapter[Your FujiNet Cartridge]

#twocol[
The ColecoVision cartridge port is the most asymmetric in the FujiNet
family. Its thirty pins carry fifteen address lines (A0--A14), eight data
lines (D0--D7), four pre-decoded #emph[chip selects] (one for each 8K block
of the cartridge window), power and ground. That is the whole interface.

Count what is missing: no #emph[/RD]. No #emph[/WR]. No #emph[/MREQ], no
clock, no reset line. The four chip selects come out of the console's
address decoder --- a 74LS138 with A13/A14/A15 on its select inputs and
`/MREQ` and `/RFSH` as its enables --- and they assert for #strong[reads
and writes alike]. The cartridge cannot tell the two apart. This is not a
FujiNet limitation; it is why every real ColecoVision mapper --- MegaCart,
Activision, X-in-1 --- takes its bank number from the #emph[address]. The
hardware left them no choice, and it leaves us none either.

So how can a read-only cartridge be a #emph[network adapter]? With the same
trick the mappers use, in both directions:

#rnum(1) #strong[The console talks by reading.] Certain pages of the
cartridge window are #emph[hotspots]. When the console reads an address
inside one, the cartridge does not care what byte it returns --- it cares
#strong[which address was read]. The low eight address bits are the
payload. Reading `$FF41` "sends" the byte `$41`.

#rnum(2) #strong[The cartridge talks by repainting.] The cartridge serves
its 32K window out of RAM on its own processor. To answer, it simply changes
the bytes it serves; by the time the console reads them, they are just ROM.

A happy consequence of that decoder: the chip selects are inhibited during
Z80 refresh, so the R register's traffic on the low address lines never
reaches the cartridge. The Astrocade port had to defend against exactly that
hazard; here the console filters it out for us.

#sub[The tandem inside the cartridge]

Two processors share the cartridge shell. An #strong[RP2040] sits on the
cartridge edge, serves the 32K window at Z80 bus speed, decodes the hotspot
reads, and repaints the reply bytes. It speaks to an #strong[ESP32-S3] --- a
stock FujiNet --- over a USB cable, using the same SLIP-framed FujiBus
packets FujiNet speaks over a serial port elsewhere. The ESP32-S3 is the
actual network adapter: WiFi, TNFS, HTTP, TLS, the lot. The RP2040 is its
translator into read-only cartridge language.

Under MAME there is no silicon, but the shape survives: the MAME cartridge
device compiles the very same mailbox sources and forwards the FujiBus
packets over TCP --- #emph[bus-over-IP] --- to a #emph[fujinet-pc] process
on your desk.
]

#fig(caption: [The three-tier stack. The mailbox is the only part your
program ever sees.],
  flow(
    nodebox("YOUR PROGRAM", sub: "Z80 · $8000", w: 1.35in),
    biarrow(w: 0.6in, label: "mailbox"),
    nodebox("RP2040", sub: "window server", w: 1.15in, bd: fuji, tc: fuji),
    biarrow(w: 0.6in, label: "USB"),
    nodebox("ESP32-S3", sub: "FujiNet", w: 1.0in),
    biarrow(w: 0.6in, label: "WiFi"),
    nodebox("THE WORLD", sub: "tnfs·http", w: 1.05in),
  ))

#twocol[
#sub[The 32K window]

The cartridge window is 32,768 bytes at console addresses `$8000`--`$FFFF`.
Your program gets nearly all of it. The mailbox owns only the top 2K; the
contract, from `fuji_mailbox.h` (the single source of truth, compiled into
the RP2040 firmware and the MAME model alike):

#rnum(1) Program code and data stay #strong[below `$F800`] --- 30K, cart
offsets `$0000`--`$77FF`.

#rnum(2) `$F800`--`$FBFF` is the #strong[reply window], one kilobyte the
cartridge repaints.

#rnum(3) `$FC00`--`$FC0C` are the #strong[status bytes], and `$FCFC` carries
the #emph[claim signature].

#rnum(4) `$FD00`, `$FE00` and `$FF00` are the three #strong[hotspot pages]
the console reads to talk.

#sub[Why the ColecoVision is scarce, not the window]

Every other cartridge port in the FujiNet family pages its reply through a
256-byte slice, because its window was too small to do otherwise. Here the
window is 32K and the #emph[console] is what is scarce: the ColecoVision has
one kilobyte of RAM, of which the BIOS keeps `$73B9`--`$73FF` and a C
program's variables and stack take most of the rest --- call it 700 usable
bytes. So this port spends its big window on the console's behalf: the whole
one-kilobyte reply is handed over as directly addressable ROM, and a program
reads a directory entry or a game state #emph[in place], out of the
cartridge, without a copy in RAM. Keep that in mind; it shapes every program
in this book.
]

#caution[
Programs that use the mailbox run with maskable interrupts #strong[disabled]
--- `DI` at entry. But the ColecoVision's vblank interrupt is wired to the
Z80's #strong[/NMI], which `DI` cannot stop, and it #emph[will] land in the
middle of a mailbox transaction. That is harmless, provided your NMI handler
never reads `$F800` or above. This is the single most important rule on the
platform, and the next chapters earn it.
]

// ============================================================
// CHAPTER: INSTALLING THE TOOLS
// ============================================================
#chapter[Installing the Tools]

#twocol[
Everything in this book is built with #strong[Z88DK], a mature cross-compiler
and assembler for the Z80. From it you get `zcc` (the C compiler front end and
the C clients' toolchain) and `z88dk-z80asm` (the assembler used for the
pure-assembly examples). The ColecoVision C clients also link against
#strong[os7lib], a small library that binds the ColecoVision's own BIOS
(OS-7) routines --- `mode_1`, `load_ascii`, `put_vram`, the controller poller
--- so a C program gets a 32$times$24 text screen and debounced input for
nothing.

#sub[Installing Z88DK]

The quickest route is a nightly build; the surest, for a machine that must
match this book, is a source build. Both give you the same `zcc` and
`z88dk-z80asm`.
]

#sub[A. The nightly build (fastest)]

#step(1)[Download the current nightly for your platform from
`nightly.z88dk.org` (Windows and macOS get complete binary packages; Linux
gets a source package). Unpack it somewhere permanent, say `~/z88dk`.]

#step(2)[Point two environment variables at it, and put its `bin` on your
path, in your shell profile (below).]

#step(3)[Check it: `zcc +coleco` should report the ColecoVision target, and
`z88dk-z80asm` should print its version.]

#codepanel("shell profile", "export Z88DK=$HOME/z88dk
export PATH=\"$Z88DK/bin:$PATH\"
export ZCCCFG=\"$Z88DK/lib/config\"", size: 7.4pt)

#sub[B. From source (surest)]

#twocol[
Z88DK uses git submodules, so clone recursively and run its build script.
This is the path that matches the sources in this book.
]

#codepanel("building z88dk from source", "git clone --recursive https://github.com/z88dk/z88dk.git
cd z88dk
export PATH=\"$PWD/bin:$PATH\"
export ZCCCFG=\"$PWD/lib/config\"
./build.sh            # Linux/Unix; see the wiki for Windows
# then, from anywhere:
zcc +coleco -v", size: 7.4pt)

#twocol[
#sub[Installing os7lib]

The C clients build against os7lib, a thin C binding of the ColecoVision
BIOS. Clone and build it, then remember where it landed --- the C programs'
`build.sh` reads its path from the `OS7LIB` variable (default
`~/Workspace/os7lib`).
]

#codepanel("os7lib", "git clone https://github.com/tschak909/os7lib.git
cd os7lib
make                  # produces os7.lib
export OS7LIB=$PWD", size: 7.4pt)

#twocol[
#sub[The test bench: MAME and fujinet-pc]

You do not need cartridge hardware to develop for FujiNet --- in fact, at the
time of writing, ColecoVision FujiNet hardware does not yet exist. The whole
stack runs on your desk:

#rnum(1) #strong[fujinet-pc] is the ESP32 firmware built to run as a desktop
process. Start it; its bus-over-IP listener waits on `127.0.0.1:9995`.

#rnum(2) #strong[MAME] emulates the ColecoVision. The firmware tree carries a
MAME cartridge device that compiles the cartridge's own mailbox sources and
forwards FujiBus packets to fujinet-pc over TCP. Graft it in once:
]

#codepanel("grafting the FujiNet cartridge into MAME", "cd ~/Workspace/fujinet-firmware/pico/coleco
./emu/apply.sh ~/Workspace/mame
make -C ~/Workspace/mame -j$(nproc) NOWERROR=1 REGENIE=1
# REGENIE=1 is needed the FIRST time (the build files changed);
# re-run apply.sh after every edit to the cartridge sources.", size: 7.2pt)

#twocol[
With both in place, `pico/coleco/run.sh` boots a built client in MAME against
the live fujinet-pc --- windowed, or headless with a one-line PASS/FAIL
verdict. Every program in this book was built and verified exactly this way.

#sub[Building a client]

Each C client in this book carries a `build.sh` that is the firmware
testrom's recipe narrowed to one program. It compiles with `zcc +coleco`,
forces the image to exactly 32,768 bytes, warns if any byte reaches the
mailbox pages, and stamps the claim signature. The next chapters explain
every part of that recipe; for now, the shape:
]

#codepanel("the shape of a build", "zcc +coleco -O2 -I$OS7LIB/src -I../common \\
    program.c $SHARED -o build/program -create-app \\
    -Cz--romsize=32768 -Cz--rombase=32768 \\
    -Cz--code-fence=0xF800 -Cz--data-fence=0xF800 \\
    -pragma-define:CRT_ORG_BSS=0x702C \\
    -pragma-define:REGISTER_SP=0x73B8 \\
    -L$OS7LIB -los7
python3 checkrom.py --stamp build/program.bin", size: 7.0pt)

#important[
The C clients build against #strong[fujinet-lib-experimental], the branch of
the portable FujiNet C library that carries the ColecoVision mailbox bus. The
two games in this book fetch it automatically through their `make-exp` script;
the standalone examples call the mailbox directly through the small library
this book develops. Both talk to the identical mailbox.
]

// ============================================================
// CHAPTER: THE MAILBOX
// ============================================================
#chapter[The Mailbox]

#twocol[
This chapter is the heart of the handbook. The mailbox is a small, strict
protocol; learn its five moves and every FujiNet feature on this console is
yours. All addresses below are #strong[console addresses] --- cart offset
plus `$8000` --- exactly as your program uses them.

#sub[The two directions]

#strong[Console to cartridge: hotspot reads.] Three pages carry everything
you will ever say. A read of `$FD00+r` #emph[arms] mailbox register `r`. A
read of `$FE00+v` delivers the value `v` to the armed register --- one
register write is therefore a #emph[pair] of reads, back to back. A read of
`$FF00+v` appends the byte `v` to the #emph[TX stream], the outgoing
parameter-and-payload buffer.

#strong[Cartridge to console: repainted ROM.] The reply window at
`$F800`--`$FBFF` is plain memory you read whenever you like --- the whole
one-kilobyte reply, in one piece. Above it, `$FC00`--`$FC0C` are thirteen
status bytes the cartridge paints.

Instruction fetches are harmless: your code executes from `$8000` upward, far
below the hotspot pages, so the thousands of reads the Z80 performs just
running your program never trip anything.
]

#fig(caption: [The cartridge window, as the console sees it.],
  table(columns: (auto, auto, 1fr), align: (left, left, left),
    table.header[Console][Name][What lives there],
    [`$8000-$F7FF`], [---], [your program: 30K of code and data],
    [`$F800-$FBFF`], [`FN_REPLY`], [the whole 1K reply, in one piece],
    [`$FC00-$FC0C`], [status], [thirteen painted status bytes],
    [`$FCFC-$FCFF`], [claim], [`FUJI` signature (cart offset `$7CFC`)],
    [`$FD00-$FD7F`], [`FN_REGSEL`], [hotspot: read `+r` arms register r],
    [`$FDFE`], [`FN_SWAP`], [hotspot: serve the staged boot image (armed only)],
    [`$FE00-$FEFF`], [`FN_REGDAT`], [hotspot: read `+v` delivers v to the armed register],
    [`$FF00-$FFFF`], [`FN_TXPAGE`], [hotspot: read `+v` appends v to the TX stream],
  ))

#fig(caption: [The thirteen painted status bytes at `$FC00`.],
  table(columns: (auto, auto, 1fr),
    table.header[Address][Name][Meaning],
    [`$FC00`], [`FN_ACKSEQ`], [echoes your SEQ when the reply is ready],
    [`$FC01`], [`FN_STATUS`], [bit 0 link up (bit 1 defined but never set)],
    [`$FC02`], [`FN_ERR`], [transport verdict of the last transaction],
    [`$FC03`], [`FN_REPLYCMD`], [`$06` ACK or `$15` NAK],
    [`$FC04`], [`FN_RXLEN_LO`], [reply length, low byte],
    [`$FC05`], [`FN_RXLEN_HI`], [reply length, high byte],
    [`$FC06`], [`FN_BOOTSTAT`], [boot state: idle 0, xfer 1, ready 2, failed `$80`],
    [`$FC07`], [`FN_BOOTPCT`], [boot progress, 0--100],
    [`$FC08`], [`FN_BOOTERR`], [boot error code],
    [`$FC09`], [`FN_MAGIC0`], [the letter `F` --- cartridge presence],
    [`$FC0A`], [`FN_MAGIC1`], [the letter `N`],
    [`$FC0B`], [`FN_PROTOVER`], [mailbox protocol version (1)],
    [`$FC0C`], [`FN_SLICE_ECHO`], [slice echo --- vestigial here, always 0],
  ))

#twocol[
#sub[The registers]

Register numbers `$00`--`$0F` mirror the FujiNet mailbox on its sibling
cartridge ports where the meanings match; `$10` and up are shared with the
Astrocade numbering.

#dotdef(
  ([`$00` DEVICE], [FujiBus device id: `$70` Fuji, `$71`--`$78` network]),
  ([`$01` COMMAND], [FujiBus command id]),
  ([`$02` NPARAM], [how many parameters lead the TX stream]),
  ([`$05` DATA RST], [any value: rewind the TX write pointer]),
  ([`$06` RXSLICE], [reply slice --- vestigial here, one slice only]),
  ([`$10` SEQ], [nonzero and $eq.not$ last ACK: launch the transaction]),
  ([`$11` BOOTLOCK], [magic `$B5` arms the ROM swap]),
  ([`$12`/`$13` BOOTSEL], [`$B5` then `$4A`: reboot cart to firmware update mode]),
)

Registers `$03`, `$04`, `$07`--`$0F` and `$14`--`$7F` are undefined and do
nothing --- reading their REGDATA is a silent no-op.

#sub[The TX stream]

Every transaction's outgoing bytes form one stream, at most #strong[320
bytes], with a fixed grammar: first the parameters --- NPARAM of them, each a
#emph[size byte] (1, 2 or 4) followed by that many value bytes,
little-endian --- then the raw payload, whose length is simply whatever
remains. At most eight parameters are unpacked.
]

#fig(caption: [The TX stream for `NET_OPEN` with two one-byte parameters and
a devicespec payload.],
  bytefield(
    ([`01`], 24pt), ([`0C`], 24pt),
    ([`01`], 24pt), ([`00`], 24pt),
    ([`N : T C P : / / ...`], 140pt),
  ))

#twocol[
#sub[One whole transaction]

Every exchange with the FujiNet --- from a WiFi scan to an HTTP GET --- is
the same five moves:

#rnum(1) #strong[Begin.] Rewind the TX stream (register `$05`), then set
DEVICE, COMMAND, and NPARAM.

#rnum(2) #strong[Stream.] Append the parameters and payload with `$FF00+v`
reads.

#rnum(3) #strong[Commit.] Read `FN_ACKSEQ`, add one (wrapping 255 to 1 ---
zero is reserved), and write the result to the SEQ register. The cartridge
sees a fresh sequence number and fires the whole stream at the ESP32-S3 as
one FujiBus packet.

#rnum(4) #strong[Wait.] Poll `FN_ACKSEQ` until it equals the number you
wrote. When it does, the reply is painted: check `FN_ERR` (the transport
verdict), `FN_REPLYCMD` (ACK or NAK), and capture the reply length from
`FN_RXLEN_LO`/`HI` #emph[immediately].

#rnum(5) #strong[Read.] The whole reply, up to 1,024 bytes, is already in the
window at `$F800`. Read it in place.
]

#fig(caption: [A `GET_ADAPTERCONFIG_EXTENDED` transaction, end to end.],
  seq((("YOUR PROGRAM", 0, ink), ("RP2040 CART", 0, fuji), ("ESP32-S3", 0, slate)),
    msg(0, 1, "read $FD05,$FE00  (rewind TX)"),
    msg(0, 1, "read $FD00,$FE70  (DEVICE=$70)"),
    msg(0, 1, "read $FD01,$FEC4  (COMMAND=$C4)"),
    msg(0, 1, "read $FD10,$FE01  (SEQ=ACKSEQ+1)"),
    msg(1, 2, "FujiBus packet over USB (SLIP)"),
    msg(2, 1, "ACK + 240-byte reply", dashed: true),
    snote(1, [paints the reply, then FN_ACKSEQ last]),
    msg(0, 1, "poll FN_ACKSEQ until it echoes"),
    msg(1, 0, "FN_ERR=0, ACK, RXLEN=240", dashed: true),
    msg(0, 1, "read the reply at $F800"),
  ))

#twocol[
#sub[The sequence rule]

Why derive SEQ from the cartridge's own `FN_ACKSEQ` instead of counting
locally? Because the RESET button restarts #emph[your program] --- but not
the cartridge. The cart edge carries no reset line. A program that kept its
own counter would, after a RESET, re-send sequence number 1; the cartridge,
having already acknowledged a 1 this session, would ignore it forever, while
the stale reply sat there looking like success. Read the cart's persisted
`FN_ACKSEQ`, add one, wrap 255 to 1, and RESET cannot desynchronise you. This
rule is inherited from hard experience on the Intellivision and Astrocade
bring-ups; honour it.

#sub[The interlock]

The cartridge paints `FN_ACKSEQ` #emph[last], after every other byte of the
reply is already in place. That single ordered store is the whole handshake:
the instant your poll sees the sequence match, everything else you are about
to read is guaranteed to be there. There is nothing else to wait on --- the
slice-echo byte that the sibling ports poll is vestigial here, always zero,
because the reply is one piece.

#sub[Stray reads, and the defences]

On a port where reading is writing, the hazard is the read you did not mean
to make --- above all the vblank NMI, which cannot be masked and lands
mid-transaction. The defences, in depth:

#rnum(1) A REGDATA read with no immediately-preceding REGSEL read is a
#strong[no-op] --- arming disarms after one use, so an isolated stray mutates
nothing.

#rnum(2) A transaction launches only on a SEQ value that is nonzero
#emph[and] differs from the last acknowledged one.

#rnum(3) The ROM-swap trigger at `$FDFE` fires only after BOOTLOCK armed it;
rebooting the cart to update mode takes two full register writes with two
different magics.

#rnum(4) Refresh cycles never assert a chip select, so the R register's
traffic never reaches the cartridge.

The one rule these leave to you: #strong[your NMI handler must never read
`$F800` or above.] A handler that bumps a frame counter and reads the VDP
status port is safe; one that peeks at the reply window can corrupt the
transaction it interrupted. The firmware's `checkrom.py` enforces the image
half of this --- no code or data may live in the mailbox pages --- so a
program that drifts up there fails its build, not a debugging session.

#sub[Timeouts]

The cartridge's own transaction budget is #strong[five seconds], except
`MOUNT_IMAGE` (command `$F8`), which gets #strong[sixty] because a network
ROM push rides inside it. Your client should wait a little longer than that,
so a real timeout is reported as the cart's error code rather than as your
own. A commit that never sees the sequence echo returns the client-timeout
sentinel.
]

#caution[
The reply window is #strong[never cleared] between transactions. A short
reply leaves the stale tail of a longer, older one behind it, and bytes past
the reported length read as zero. Capture `FN_RXLEN` the moment a transaction
acknowledges, believe only that many bytes, and validate what they claim to
be before acting on them.
]

// ============================================================
// CHAPTER: FIRST CONTACT
// ============================================================
#chapter[First Contact]

#twocol[
Enough theory --- let us shake hands with the cartridge. The smallest useful
FujiNet program does three things: proves the cartridge is there, runs one
transaction, and shows what came back. This chapter builds it twice --- once
in Z80 assembly, once in C --- and every program in this book, games
included, is this program with a bigger middle. The assembly version is
`acfg.asm`, driving the mailbox directly; the C version uses the portable
#strong[fujinet-lib] the games link. (The appendix's `fujitest.c` is the same
round trip written against the low-level library, for comparison.)

#sub[Is anybody home?]

The cartridge paints the letters `F` and `N` at `$FC09` and `$FC0A`. If they
are not both there, you are running on a bare console --- or a different
cartridge --- and must not touch the hotspot pages. Every client checks this
first, and so should you.

#sub[One transaction, no parameters]

`GET_ADAPTERCONFIG_EXTENDED` (command `$C4` to device `$70`) is the perfect
first transaction: it takes no parameters and no payload, works even before
WiFi is configured, and returns a 240-byte structure whose best fields sit at
convenient offsets --- the SSID at 0, the firmware version at 125, and the IP
address, already in dotted-decimal text, at 140.
]

#pair(
"        call    FNPRES        ; Z if 'F','N'
        jr      nz,NOCART
        ld      d,$70         ; device
        ld      e,$C4         ; ACFG_EXT
        call    FNSTART
        call    FNCOMMIT
        jr      c,TIMEOUT     ; never answered
        or      a
        jr      nz,LERR       ; FN_ERR != 0
        call    FNACKED
        jr      nz,GOTNAK
; reply is at $F800: ssid +0,
; fw +125, ip +140.",
"    AdapterConfigExtended ac;

    if (!fuji_coleco_present()) {
        show(\"NO FUJINET CART\");
        for (;;) ;
    }
    if (!fuji_get_adapter_config_extended(&ac))
        fail();

    show(ac.ssid);
    show(ac.sLocalIP);   /* dotted text */
    show(ac.fn_version);")

#twocol[
#sub[What success looks like]

Build either version and run it. Against a live FujiNet --- or fujinet-pc
under MAME --- the screen answers in about a second:
]

#fig(caption: [The assembly demo's first contact, captured from MAME against
a live fujinet-pc.],
  tv("FUJINET  ACFG DEMO

SSID
  Dummy Cafe

IP ADDRESS
  127.0.0.1

FIRMWARE
  v1.6-2a9e2c23f

OK", w: 3.0in, size: 7.6pt))

#twocol[
Read the error paths as carefully as the happy one. At the mailbox there are
three layers. #strong[Carry set] from `FNCOMMIT` in assembly (the low-level C
library returns the sentinel `FN_EWAIT`) means the cartridge never acknowledged
--- almost always "no cartridge" or "the RP2040 never enumerated its ESP32." A
#strong[nonzero `FN_ERR`] means the cartridge answered but the transport
beneath it failed: `1` no link, `2` timeout, `3` bad frame, `4` too big. A
#strong[NAK in `FN_REPLYCMD`] means everything carried perfectly and the
FujiNet itself refused the command --- wrong parameters, an unmounted host, a
file that is not there.

Three different layers, three different bytes, three different remedies.
fujinet-lib folds them together for you: a `fuji_*` call returns `false` on
any failure, and a `network_*` call returns a non-`FN_ERR_OK` code --- but the
three bytes are still there underneath when you need to tell the cases apart.
]

// ============================================================
// CHAPTER: THE Z80 ASSEMBLER LIBRARY
// ============================================================
#chapter[The Z80 Assembler Library]

#twocol[
The mailbox is nothing but memory reads, and reading memory is what a Z80
does best. This chapter walks the assembly library `fujimail.inc` --- printed
in full in the appendix and used by the assembly examples throughout ---
routine by routine. Know these nine and you know the mailbox by heart.

Calling conventions are register-based and stated at each routine; two scratch
bytes, `NPARAM` and `WANT`, live in low RAM. In assembly there is no volatile
hazard: `ld a,(hl)` always performs the read, so the "read whose value we
discard" needs no ceremony --- it is simply a load.

#sub[FNREGWR --- one register write]

The atom everything is built from. `C` names the register, `A` the value; the
routine issues the REGSEL/REGDATA read pair, back to back. The read whose
result is thrown away #emph[is] the message.
]

#codepanel("FNREGWR, fujimail.inc",
"; C = register number, A = value.
FNREGWR:
        push    af          ; hold the value
        ld      h,$FD       ; REGSEL page
        ld      l,c
        ld      a,(hl)      ; arm the register
        pop     af
        ld      h,$FE       ; REGDATA page
        ld      l,a
        ld      a,(hl)      ; deliver the value
        ret")

#twocol[
Nothing requires the two reads to be adjacent --- ordinary instruction
fetches between them are invisible to the hotspot decode, and the vblank NMI
can land there harmlessly because the armed register simply waits. The
library keeps them adjacent as hygiene.

#sub[FNTXB, FNP8, FNP16 --- feeding the stream]

`FNTXB` appends the byte in `A` with a single `$FF00+v` read. `FNP8` wraps it
for the parameter grammar --- size byte 1, then the value, then bump NPARAM.
`FNP16` sends a two-byte parameter: size byte 2, low, high. The raw payload
after the parameters is just `FNTXB` in a loop, or `FNTXPAD`, which streams a
string and pads it with NULs to a fixed width --- the shape
`SET_DEVICE_FULLPATH` and `OPEN_DIRECTORY` demand.

#sub[FNSTART --- opening the envelope]

`D` = device, `E` = command. Rewinds the TX pointer (register `$05`) and
writes DEVICE, COMMAND and NPARAM = 0. Because `FNREGWR` touches only `A`,
`H` and `L`, the `D` and `E` you loaded survive the call. Afterwards the
stream is empty and waiting.

#sub[FNCOMMIT --- the moment of truth]

Computes the sequence rule from the last chapter --- `FN_ACKSEQ` + 1, wrap
255 to 1 --- writes SEQ, and polls. On success it returns with `A` = `FN_ERR`
and the flags set from `or a`, so `jr nz,error` reads naturally; on a
client-side timeout it returns with carry set.
]

#codepanel("FNCOMMIT, fujimail.inc -- the sequence rule in the flesh",
"FNCOMMIT:
        ld      a,(FN_ACKSEQ)
        inc     a
        jr      nz,FNCM1
        inc     a           ; 255 wrapped; step past reserved 0
FNCM1:  ld      (WANT),a
        ld      c,FNR_SEQ
        call    FNREGWR     ; A = want
        ld      b,40        ; outer quanta; inner is a full spin
FNCMO:  ld      de,0
FNCMI:  ld      a,(FN_ACKSEQ)
        ld      hl,WANT
        cp      (hl)
        jr      z,FNCMOK
        dec     de
        ld      a,d
        or      e
        jr      nz,FNCMI
        djnz    FNCMO
        scf                 ; timed out
        ret
FNCMOK: ld      a,(FN_ERR)
        or      a           ; clears carry
        ret")

#twocol[
#sub[FNACKED, FNRLEN, FNPRES --- reading the answer]

`FNACKED` returns Z set when `FN_REPLYCMD` is `$06` (ACK). `FNRLEN` loads
`HL` from `FN_RXLEN` in one `ld hl,(nn)` --- the length is little-endian, so
the low byte at `$FC04` becomes `L` and the high at `$FC05` becomes `H`, for
free. `FNPRES` compares `$FC09`/`$FC0A` against `F`,`N` and returns Z set when
the cartridge is present; call it once at boot, before any hotspot is touched.

That is the whole library. Everything else in this book --- the C client, the
games, CONFIG --- is these routines, or their C twins, with a purpose.
]

// ============================================================
// CHAPTER: C ON THE COLECOVISION
// ============================================================
#chapter[C on the ColecoVision]

#twocol[
The mailbox is memory reads, and C reads memory too. This book's C clients
build with Z88DK's `+coleco` target against `os7lib`, and that is not a
shortcut --- it is the design. The ColecoVision window is 32K, so C's overhead
is affordable, and "use OS7 for everything" gives every client a 32$times$24
text screen, a debounced controller, and a font, all from the console's own
BIOS. The C mailbox library is `fujilib.c`; it mirrors `fujimail.inc` function
for function.

#sub[The build, part by part]

The link line looks alarming but each pragma earns its place. The
ColecoVision's whole RAM is one kilobyte; after OS7's tables and the C stack,
a client has about 700 usable bytes. The layout is pinned by hand:
]

#dotdef(
  ([`+coleco`], [the ColecoVision target: crt0, header, VDP glue]),
  ([`romsize/rombase 32768`], [force a full 32K image based at `$8000`]),
  ([`code-fence/data-fence $F800`], [warn if anything reaches the mailbox pages]),
  ([`CRT_ORG_BSS=0x702C`], [variables start just above the header's tables]),
  ([`REGISTER_SP=0x73B8`], [stack below the BIOS scratch at `$73B9`]),
  ([`CLIB_DEFAULT_SCREEN_MODE=-1`], [keep the crt0 out of the VDP; os7lib owns it]),
)

#twocol[
The guard macro for ColecoVision-only code is #strong[`BUILD_COLECO`], not
`__COLECO__`: Z88DK defines the latter for the ADAM sub-target too
(`+coleco -subtype=adam`), so the games use their own define to tell the two
apart.

#sub[Reading as writing, in C]

Here C needs one idiom, and one warning. The hotspot "write" is a read whose
#emph[address] matters and whose value does not. Written the obvious way ---
`(void)FN_REGSEL[reg];` --- sccz80 computes the address and then throws the
load away, so the register write never happens and no transaction ever
launches. Storing the read into a `volatile` sink is what forces the compiler
to keep it.
]

#codepanel("fujilib.c -- the transport atom, and the trap it dodges",
"/* sccz80 discards (void)FN_REGSEL[reg]; the store into a
   volatile sink is what makes the read a real side effect.
   Check: zcc +coleco -O2 -a fujilib.c -- look for TWO loads. */
volatile unsigned char fn_sink;
#define FN_TOUCH(a) (fn_sink = *(volatile unsigned char *)(a))

static void fn_regwr(unsigned char reg, unsigned char val)
{
    FN_TOUCH(FN_REGSEL + reg);   /* arm the register  */
    FN_TOUCH(FN_REGDAT + val);   /* deliver the value */
}")

#caution[
A second helping of the same compiler, and the subtler of the two: never
index the reply window as `FN_REPLY[i]`. sccz80 indexes the macro's
cast-constant differently from a `volatile unsigned char *` local and gets it
wrong --- the identical expression that draws a filename correctly through a
local reads back zero through the macro, which shows up as a directory listing
that looks perfect but whose end-of-directory test never fires. Always read
the window through a pointer variable.
]

#twocol[
#sub[The rest of the library]

`fujilib.c` continues exactly along `fujimail.inc`'s lines: `fn_start`,
`fn_param8`/`fn_param16`, `fn_tx`/`fn_tx_padded`, `fn_commit`, `fn_acked`,
`fn_reply_len`, plus two streaming helpers the games and CONFIG lean on ---
`fn_tx_path`, which streams a filename #emph[out of the reply window] and into
the next transaction's payload without a RAM copy, and `fn_tx_from_reply`,
which does the same for a run of bytes. On a machine with 700 bytes of RAM
those are not optimisations; they are what makes a directory browser possible.

#sub[fujinet-lib, the portable road]

The game clients --- and every C example in this handbook's command reference
--- use #strong[fujinet-lib-experimental], the portable FujiNet C library,
rather than calling `fujilib.c` directly. Its ColecoVision bus is the same
mailbox by another name: `network_open`, `network_read_nb`, `network_close`,
`network_status`, and the `fuji_*` calls for the adapter --- WiFi, host and
device slots, directories, mounting, app keys, hashing, and the
`fuji_coleco_*` boot helpers. The same source compiles for the Apple II, the
C64 and the CoCo; only the bus underneath changes. `fujilib.c` is shown in this
book because it #emph[is] that bus, laid bare, so the portable library holds no
mysteries --- and the two sccz80 traps above apply to it just the same: its
coleco bus stores every hotspot read through a volatile sink, and reads the
reply window through a pointer, for exactly the reasons given here. A handful of
commands have no wrapper (disk and printer I/O, `RANDOM_NUMBER`); for those the
reference drops to the low-level calls, and says so.
]

// ============================================================
// CHAPTER: THE NETWORK DEVICE
// ============================================================
#chapter[The Network Device]

#twocol[
Device `$71` is the first of eight network units --- N1: through N8:,
`$71`--`$78` --- each an independent connection to somewhere in the world. You
give one a #emph[devicespec], a URL with an `N:` prefix, and from then on it
is a byte pipe with a status word.

#spec("N:TELNET://bbs.fozztexx.com/")
#spec("N:TCP://192.168.1.10:6502/")

The scheme decides everything: `TCP:`, `TELNET:`, `HTTP:`, `HTTPS:`, `TNFS:`,
`JSON:`, `SSH:`, `UDP:` and more, each with its own grammar and behaviour.
This handbook does not repeat that material --- it fills a book of its own,
#emph[The FujiNet Network Protocol Handbook] --- but everything there applies
to the ColecoVision verbatim once you can drive the five commands below.

#sub[The lifecycle five]

#dotdef(
  ([OPEN `$4F`], [mode and translation params, devicespec payload]),
  ([STATUS `$53`], [four reply bytes: bytes waiting, connected, device status]),
  ([READ `$52`], [up to 1,024 bytes into the reply window]),
  ([WRITE `$57`], [bytes out --- NETCAT is this book's user]),
  ([CLOSE `$43`], [hang up]),
)

#sub[OPEN]

Two one-byte parameters, then the devicespec as payload, padded to a fixed
256 bytes. The #emph[mode] is a `fileAccessMode_t`: 4 read, 8 write, 12
read/write --- and 12 also performs a GET on an HTTP adapter. The
#emph[translation] is 0 (none) for a binary stream. NETCAT opens a socket
read/write.

#sub[STATUS]

The heartbeat. On an open channel the reply is four bytes:
]

#fig(caption: [The `NET_STATUS` reply on an open channel.],
  bytefield(
    ([`avail lo`], 54pt), ([`avail hi`], 54pt),
    ([`connected`], 58pt), ([`devstatus`], 58pt)))

#twocol[
`avail` is how many bytes wait to be read, little-endian. `connected` is the
socket truth. `devstatus` is the protocol adapter's verdict: `1` SUCCESS,
`136` end-of-file, and a table of per-protocol error codes the Protocol
Handbook documents. A terminal like NETCAT watches `connected` --- on a live
socket, end-of-file is a hangup, not an error --- while a game that fetches an
HTTP body watches `devstatus`, because a GET is performed at #emph[read] time
and an error page still has a readable body that `connected` alone would
happily render as garbage.

#sub[READ, WRITE, CLOSE]

`READ` takes a one word count, clamped to what STATUS reported and to the
1,024-byte window; the reply lands at `$F800` and you capture its length that
instant. `WRITE` carries the count as a parameter #emph[and] the bytes as
payload --- so keep a write inside the 320-byte TX stream; NETCAT caps at 120.
`CLOSE` takes nothing.

The one rule of discipline: nothing may run between a `READ` and the code that
renders its bytes, because every transaction --- `STATUS`, `CLOSE`, anything
--- repaints the reply window. NETCAT's loop is written around that: status,
read, draw, in that order.
]

// ============================================================
// CHAPTER: THE FUJI DEVICE
// ============================================================
#chapter[The Fuji Device]

#twocol[
Device `$70` is the adapter itself: WiFi, host slots, directories, disk
images, and a drawer of utilities. CONFIG is its natural habitat --- the one
client in this book that lives on device `$70` --- and this chapter follows
CONFIG's road through it. The complete command cards are in the reference
chapter; here is how the pieces fit.

#sub[Getting on the air]

CONFIG's WiFi checkout: `SCAN_NETWORKS` (`$FD`) starts a scan and returns a
count; `GET_SCAN_RESULT` (`$FC`) takes an index and returns 34 bytes ---
`ssid[33]` and an RSSI byte, a #emph[negative dBm] you must read as signed or
every network looks impossibly strong. Joining is `SET_SSID` (`$FB`), and it
has two famous edges: it demands #strong[at least one parameter whose value it
ignores], and the payload must be #strong[exactly 97 bytes] --- `ssid[33]` +
`password[64]`, NUL-padded to their full widths.

#sub[The payload-shape rule]

Behind that edge is one firmware fact worth internalising: the transaction
layer #strong[fails a short read]. A command that expects a struct wants
#emph[all] of it. `OPEN_DIRECTORY` and `SET_DEVICE_FULLPATH` always send a
full #strong[256-byte, NUL-padded] payload; `SET_SSID` sends exactly 97.

#sub[Hosts and directories]

Eight host slots of 32 bytes each. `READ_HOST_SLOTS` (`$F4`) returns all 256
bytes in one reply, which CONFIG renders straight from the window.
`WRITE_HOST_SLOTS` (`$F3`) is #strong[all-or-nothing] --- there is no
write-one-slot form --- so CONFIG re-reads the slots and streams them back out
of the reply window with the edited one substituted, never mirroring 256 bytes
in a machine that has under a kilobyte.
]

#codepanel("fujicfg.c -- the reply window IS the buffer (rename a host slot)",
"/* WRITE_HOST_SLOTS takes all eight 32-byte slots, every time.
   Re-read, then stream them straight back with the edited one
   swapped in -- no 256-byte RAM mirror, because there is nowhere
   to put one. The editor runs no transactions, so nothing
   repaints the window between the read and the streamed write. */
    fn_start(FN_DEV_FUJINET, CMD_READ_HOST_SLOTS);
    ...
    fn_start(FN_DEV_FUJINET, CMD_WRITE_HOST_SLOTS);
    for (i = 0; i < HOST_SLOTS; i++)
        if (i == cur) fn_tx_padded(fn_entry, HOST_STRIDE);
        else          fn_tx_from_reply(i * HOST_STRIDE, HOST_STRIDE);")

#twocol[
Then `MOUNT_HOST` (`$F9`) takes the slot number; `OPEN_DIRECTORY` (`$F7`, host
parameter, 256-byte path payload), `SET_DIRECTORY_POSITION` (`$E4`, a word),
`READ_DIR_ENTRY` (`$F6`, maxlen and flags), and `CLOSE_DIRECTORY` (`$F5`).
Entries arrive as names with a trailing `/` on subdirectories; end of
directory is #strong[exactly two `$7F` bytes].
]

#caution[
Do not read past the end of a directory. `fujiDevice` returns two `$7F` bytes
when the listing runs out, but a fujinet-pc SD host hands back `..` over and
over instead --- and once you have done that, every later
`SET_DIRECTORY_POSITION` NAKs for the rest of the session. CONFIG stops on
`$7F $7F`, `.` and `..` alike.
]

#twocol[
#sub[The utility drawer]

The Fuji device also answers `GET_ADAPTERCONFIG_EXTENDED` (`$C4`, the
first-contact command), `RANDOM_NUMBER` (`$D3`, four bytes of entropy),
`GENERATE_GUID` (`$BB`), app keys (`$DC`--`$DB`, per-app key/value storage on
the adapter's SD card), base64 and hash engines (`$D0`--`$C2` --- an SHA-256
on call from a Z80), and QR code rendering (`$BC`--`$BF`). Command cards for
all of them, with paired assembly and C examples, follow in the reference.
]

// ============================================================
// CHAPTER: BOOT, SWAP, AND THE MAPPERS
// ============================================================
#chapter[Boot, Swap, and the Mappers]

#twocol[
The finale of CONFIG's road: pick a program from a network host and
#emph[become] it. On other FujiNets that is "mount the disk and reboot." On a
console whose cartridge port cannot write, it is a small magic trick in three
acts.

#sub[Act one: the push]

`SET_DEVICE_FULLPATH` (`$E2`: device slot 0, host, mode 1-read, path padded to
256) names the file. Then `MOUNT_IMAGE` (`$F8`) --- and here the ColecoVision
departs from every sibling. While your `MOUNT_IMAGE` transaction is #emph[still
outstanding], the ESP32-S3 fetches the file and streams it to the RP2040 over
a side channel: FujiBus frames addressed to device `$FF` (DBC) --- an OPEN
carrying a stream id and a 32-bit size, WRITE after WRITE of 512-byte chunks,
then a CLOSE that commits. Stream 0 is the ROM; stream 1, pushed first when it
exists, is the image's `.cfg` sidecar.

Your program sees all this as theatre on the status bytes: `FN_BOOTSTAT` walks
idle $arrow$ transfer $arrow$ ready (or `$80`, failed, with the reason in
`FN_BOOTERR`), and `FN_BOOTPCT` climbs 0 to 100. Watch the counter, paint a
progress bar, and touch no hotspot while the push is in flight.

#sub[Act two: the swap]

When `FN_BOOTSTAT` reads ready: write BOOTLOCK (`$11`) = `$B5` to arm the
trigger, copy a small stub into console RAM, and jump to it. The stub must run
from RAM for the best reason imaginable --- the swap replaces #strong[every
byte of the cartridge window, including the code that triggers it].
]

#codepanel("fujilib.c -- the swap stub, hand-assembled",
"static const unsigned char stub_src[] = {
    0x3E,0x00, 0xD3,0xBF, 0x3E,0x81, 0xD3,0xBF,  /* VDP reg1 = 0: */
                                                 /*  screen+INT off */
    0xDB,0xBF,                                   /* clear latched INT */
    0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00,    /* let an NMI drain */
    0x3E,0x9F,0xD3,0xFF, 0x3E,0xBF,0xD3,0xFF,    /* silence the PSG */
    0x3E,0xDF,0xD3,0xFF, 0x3E,0xFF,0xD3,0xFF,
    0x3A,0xFE,0xFD,                              /* THE SWAP: read $FDFE */
    0x21,0x00,0x80, 0x06,0x08,                   /* VDP regs 0..7 -> 0 */
    0x7D, 0xD3,0xBF, 0x7C, 0xD3,0xBF, 0x24, 0x10,0xF8,
    0xC3,0x00,0x00                               /* jp $0000: cold start */
};")

#twocol[
The stub blanks the screen and clears VDP register 1 #emph[before] the swap,
because the BIOS vectors the vblank NMI to `$8021` --- a byte that belongs to
the #emph[next] image the instant the swap happens. Then one read of `$FDFE`
flips the cartridge, the VDP registers are reset to a power-on-like state so a
`$55AA` game that skips the BIOS title does not inherit CONFIG's video mode,
the sound chip is silenced, and `JP $0000` cold-starts the BIOS, which reads
the new image's own `$8000` header exactly as it would a real cartridge.

#sub[Act three: after the swap]

What the mailbox does next depends on what was pushed. An image carrying the
`FUJI` claim at cart offset `$7CFC` --- every client in this book --- keeps
the mailbox alive: the program can go on talking to the network, and CONFIG
can be re-entered. An ordinary game makes no such promise, so booting one
shuts the mailbox down for the session; RESET all you like, the game works
exactly as a real cartridge would.

#sub[The mappers]

A pushed image up to 128K is served through whichever real ColecoVision mapper
its size selects: flat (up to 32K), MegaCart, Activision, X-in-1, or the
Opcode Super Game Module. Every one of those puts its bank hotspots inside the
`$FF00` page --- the same page as the TX stream --- which is not a collision
but the same mutual exclusion: a game image carries no claim, so the mailbox
is already dead before any mapper decode goes live, and a claimed client image
is flat 32K by construction. The size ceiling is 128K because a banked image
must live in the RP2040's SRAM; there is no execute-in-place flash tier, since
this port has only about 373 nanoseconds from address-valid to data-required.
]

// ============================================================
// CHAPTER: COMMAND REFERENCE -- THE FUJI DEVICE
// ============================================================
#chapter[Command Reference: The Fuji Device]

#block({
  set par(first-line-indent: 0pt)
  [Every command device `$70` answers on this platform, verified against the
  firmware dispatch tables (`fujiDevice.cpp`, its five mixins, and the RS232
  fall-through switch in `rs232Fuji.cpp`). Conventions: #emph[nparam] is the
  value written to the NPARAM register; a #emph[byte] parameter is size 1, a
  #emph[word] is size 2, little-endian. Replies land in the reply window at
  `$F800`. Each card carries a compact example in Z80 assembly (using
  `fujimail.inc`) and C (using the portable #strong[fujinet-lib], dropping to
  the low-level library only for the few commands it does not wrap). Any command
  not listed here is answered with a NAK on this platform --- the closing
  section names them.]
})

#sect[WiFi and the adapter]

#cmd("GET_ADAPTERCONFIG_EXTENDED", code: "$C4", dev: "$70", nparam: "0",
  reply: [240 bytes: `ssid[33]` `hostname[64]` binary `localIP/gateway/`
    `netmask/dnsIP[4]` `mac[6]` `bssid[6]` `fn_version[15]`, then the text
    fields `sLocalIP[16]` (offset 140), `sGateway`, `sNetmask`, `sDnsIP`,
    `sMacAddress[18]` (204), `sBssid` --- all NUL-terminated],
  asm: "        ld  d,$70
        ld  e,$C4
        call FNSTART
        call FNCOMMIT
; ssid  $F800+0
; fw    $F800+125
; ip    $F800+140",
  c: "AdapterConfigExtended ac;
if (fuji_get_adapter_config_extended(&ac)) {
  show(ac.ssid);
  show(ac.sLocalIP);     /* dotted text */
  show(ac.fn_version);
}",
  [The first-contact command, and the one every status screen wants: no
  parameters, works before WiFi is up, and its text fields save you a
  print-an-IP routine. The compact form `GET_ADAPTERCONFIG` (`$E8`) returns
  the first 140 bytes only, addresses in binary.])

#cmd("SCAN_NETWORKS", code: "$FD", dev: "$70", nparam: "0",
  reply: [1 byte: number of networks found],
  [Starts a fresh scan and blocks until it finishes. Follow with
  `GET_SCAN_RESULT` once per index. Reachable but slow; CONFIG shows a
  "scanning" line first.])

#cmd("GET_SCAN_RESULT", code: "$FC", dev: "$70", nparam: "1",
  params: [byte: result index, 0-based],
  reply: [34 bytes: `ssid[33]` + `rssi` (signed dBm)],
  asm: "        ld  d,$70
        ld  e,$FC
        call FNSTART
        ld  a,(IDX)     ; index
        call FNP8
        call FNCOMMIT
; rssi at $F800+33, signed",
  c: "uint8_t count;
SSIDInfo net;
fuji_scan_for_networks(&count);
fuji_get_scan_result(idx, &net);
/* net.rssi is already signed dBm */
bar_graph(net.ssid, net.rssi);",
  [One scanned network. The RSSI byte at offset 33 is a negative dBm ---
  closer to zero is stronger --- so bar-graph its magnitude.])

#cmd("SET_SSID", code: "$FB", dev: "$70", nparam: "1",
  params: [byte: any value --- #strong[required but ignored]],
  payload: [#strong[exactly 97 bytes]: `ssid[33]` + `password[64]`, NUL-padded],
  asm: "        ld  d,$70
        ld  e,$FB
        call FNSTART
        xor a
        call FNP8       ; dummy param
        ld  hl,SSID
        ld  de,33
        call FNTXPAD
        ld  hl,PASS
        ld  de,64
        call FNTXPAD
        call FNCOMMIT",
  c: "NetConfig nc;
memset(&nc, 0, sizeof nc);   /* NUL-pad */
strcpy(nc.ssid, ssid);
strcpy(nc.password, pass);
if (fuji_set_ssid(&nc))
    /* joined and saved as default */;",
  [Joins a network and saves it as the default. The two sharp edges are in
  bold: a short payload fails the transaction outright.])

#cmd("GET_SSID", code: "$FE", dev: "$70", nparam: "0",
  reply: [97 bytes: `ssid[33]` + `password[64]`, NUL-padded],
  [The current network configuration --- password in clear text; your adapter
  is a trusted friend.])

#cmd("GET_WIFISTATUS", code: "$FA", dev: "$70", nparam: "0",
  reply: [1 byte: `3` = connected; other values not (yet)],
  [The poll target while a join is in flight. `GET_WIFI_ENABLED` (`$EA`)
  answers 1 byte: is the radio administratively on at all.])

#cmd("RESET / GET_WIFI_ENABLED", code: "$FF / $EA", dev: "$70",
  nparam: "0", reply: [`$FF`: ACK, adapter reboots · `$EA`: 1 byte],
  [`RESET` reboots the ESP32-S3; the RP2040 and mailbox stay up while the link
  bit in `FN_STATUS` drops and returns. `GET_WIFI_ENABLED` reports whether the
  radio is enabled.])

#cmd("STATUS", code: "$53", dev: "$70", nparam: "1",
  params: [byte: request type --- 1 mount times, else diagnostic],
  reply: [type 1: a `time_t` per device slot (0 = unmounted); else 4 bytes],
  [Requires the parameter on this build; mostly a diagnostic.])

#cmd("DEVICE_READY", code: "$00", dev: "$70", nparam: "0",
  reply: [the bus self-test response],
  [The "FUJICMD DEVICE TEST" round trip --- proof the mailbox, the RP2040, the
  USB link and the ESP32-S3 are all telling the truth.])

#sect[Hosts, slots, and mounting]

#cmd("READ_HOST_SLOTS", code: "$F4", dev: "$70", nparam: "0",
  reply: [256 bytes: 8 slots $times$ `hostname[32]`],
  asm: "        ld  d,$70
        ld  e,$F4
        call FNSTART
        call FNCOMMIT
; slot i name at $F800 + i*32",
  c: "/* read in place -- 256 bytes is a
   quarter of RAM, so point at the
   reply window as the games do */
HostSlot *hosts = (HostSlot *) 0xF800;
fuji_get_host_slots(hosts, 8);",
  [The host list, one transaction. CONFIG renders its HOSTS screen straight
  from the reply window --- no copy in RAM.])

#cmd("WRITE_HOST_SLOTS", code: "$F3", dev: "$70", nparam: "0",
  payload: [256 bytes: all 8 slots, full width],
  reply: [ACK],
  [All-or-nothing --- there is no write-one-slot command. See the "reply
  window IS the buffer" idiom in the Fuji Device chapter: stream the payload
  straight back out of a fresh `READ_HOST_SLOTS`, substituting the edited
  slot with `fn_tx_from_reply`.])

#cmd("MOUNT_HOST / UNMOUNT_HOST", code: "$F9 / $E6", dev: "$70", nparam: "1",
  params: [byte: host slot, 0-based], reply: [ACK, or NAK if unreachable],
  asm: "        ld  d,$70
        ld  e,$F9
        call FNSTART
        ld  a,(HOST)
        call FNP8
        call FNCOMMIT",
  c: "if (fuji_mount_host_slot(host))
    /* host mounted */;
/* fuji_unmount_host_slot(host)
   releases it */",
  [Connects (or releases) the named host --- TNFS, SMB and the rest. Required
  before `OPEN_DIRECTORY` or a boot.])

#cmd("READ_DEVICE_SLOTS / WRITE_DEVICE_SLOTS", code: "$F2 / $F1", dev: "$70",
  nparam: "0",
  reply: [`$F2`: the device-slot table (`hostSlot`, `mode`, `filename[]` per
    slot); `$F1` takes it back as payload],
  [What is configured in each virtual drive. The ColecoVision boots images
  rather than serving drives, so CONFIG leaves these screenless --- but they
  answer.])

#cmd("SET_DEVICE_FULLPATH", code: "$E2", dev: "$70", nparam: "3",
  params: [bytes: device slot, host slot, mode (1 = read)],
  payload: [#strong[256 bytes]: the path, NUL-padded],
  reply: [ACK],
  asm: "        ld  d,$70
        ld  e,$E2
        call FNSTART
        xor a
        call FNP8       ; devslot 0
        ld  a,(HOST)
        call FNP8
        ld  a,1
        call FNP8       ; mode read
        ld  hl,PATH
        ld  de,256
        call FNTXPAD
        call FNCOMMIT",
  c: "fuji_set_device_filename(
    1 /*read*/, host,
    0 /*dev slot*/, path);",
  [Names the file for a device slot --- the first half of booting. The argument
  order is `(mode, host, device slot, path)`; the library pads the path to the
  256-byte buffer the adapter expects.])

#cmd("MOUNT_IMAGE / UNMOUNT_IMAGE", code: "$F8 / $E9", dev: "$70",
  nparam: "2 / 1",
  params: [`$F8`: device slot, access mode (1 read) · `$E9`: device slot],
  reply: [ACK when the mount --- and, on this platform, the push --- completes],
  asm: "        ld  d,$70
        ld  e,$F8
        call FNSTART
        xor a
        call FNP8       ; devslot 0
        ld  a,1
        call FNP8       ; mode read
        call FNCOMMIT
; then watch FN_BOOTSTAT / FN_BOOTPCT",
  c: "fuji_mount_disk_image(0 /*slot*/, 1);
while (fuji_coleco_boot_state()
       != FUJI_COLECO_BOOT_READY) {
  if (fuji_coleco_boot_state()
      == FUJI_COLECO_BOOT_FAILED) break;
  show_pct(fuji_coleco_boot_percent());
}",
  [The second half of booting, and the platform's most theatrical command:
  while it is outstanding the adapter streams the image to the cartridge over
  the DBC side channel, and `FN_BOOTSTAT`/`FN_BOOTPCT` narrate the progress.
  Allow the 60-second budget and paint a progress bar. See the Boot chapter.])

#cmd("MOUNT_ALL / SET_BOOT_MODE / CONFIG_BOOT", code: "$D7 / $D6 / $D9",
  dev: "$70", nparam: "0 / 1 / 1",
  reply: [ACK],
  [`MOUNT_ALL` mounts every configured slot; `SET_BOOT_MODE` and `CONFIG_BOOT`
  select what the adapter offers at power-on on disk-serving platforms. On this
  console the mailbox claim, not a config flag, decides who boots --- CONFIG
  deliberately never sends `CONFIG_BOOT`.])

#cmd("NEW_DISK", code: "$E7", dev: "$70", nparam: "0",
  payload: [`numSectors` (word) `sectorSize` (word) `hostSlot` `deviceSlot`
    `filename[256]`],
  reply: [ACK on creation],
  [Creates a blank image on a host --- full-struct payload, NUL-padded
  filename, the 256-pad rule again.])

#sect[Directories]

#cmd("OPEN_DIRECTORY", code: "$F7", dev: "$70", nparam: "1",
  params: [byte: host slot],
  payload: [#strong[256 bytes]: path, NUL, then an optional `*.COL`-style
    filter, the rest NUL padding],
  reply: [ACK],
  asm: "        ld  d,$70
        ld  e,$F7
        call FNSTART
        ld  a,(HOST)
        call FNP8
        ld  hl,ROOTP    ; \"/\",0
        ld  de,256
        call FNTXPAD
        call FNCOMMIT",
  c: "fuji_open_directory(host, \"/\");
/* with a filter:
   fuji_open_directory_filter(
     host, \"/\", \"*.COL\"); */",
  [Opens a directory on a mounted host; the filter is applied server-side.])

#cmd("READ_DIR_ENTRY", code: "$F6", dev: "$70", nparam: "2",
  params: [bytes: maxlen (crunch width), flags (0)],
  reply: [one entry name, NUL-terminated; a trailing `/` marks a subdirectory;
    #strong[end of directory is two `$7F` bytes]],
  asm: "        ld  d,$70
        ld  e,$F6
        call FNSTART
        ld  a,29        ; maxlen
        call FNP8
        xor a
        call FNP8       ; flags
        call FNCOMMIT
; $F800: $7F,$7F => end",
  c: "uint8_t entry[32];
fuji_read_directory(maxlen, 0, entry);
if (entry[0]==0x7F &&
    entry[1]==0x7F) /* end */ ;",
  [One entry per transaction; the entry advances the cursor itself. `maxlen`
  truncates the name --- ask for the display width when drawing, the full
  width when building a boot path. See the caution in the Fuji Device chapter
  about reading past the end.])

#cmd("SET_DIRECTORY_POSITION / GET_DIRECTORY_POSITION", code: "$E4 / $E5",
  dev: "$70", nparam: "1 / 0",
  params: [`$E4`: word, absolute entry index],
  reply: [`$E5`: word, the current index; `$E4`: ACK],
  [Seek and tell for the open directory --- CONFIG's paging in one command.
  Note the two-byte parameter for the seek.])

#cmd("CLOSE_DIRECTORY", code: "$F5", dev: "$70", nparam: "0",
  reply: [ACK], [Closes the walk. Directories are a scarce resource on the
  adapter; close what you open.])

#sect[Files, prefixes, and paths]

#cmd("COPY_FILE", code: "$D8", dev: "$70", nparam: "2",
  params: [bytes: source host, destination host --- #strong[both 1-based]],
  payload: [#strong[exact length], no padding: `sourcepath|destdir/destname`],
  reply: [ACK when the copy completes],
  [Server-to-server copy without a byte passing through the console. The
  payload is read as a string, so it goes at exact length --- one padding NUL
  would land inside the destination name --- and its host parameters are
  1-based, alone among slot parameters.])

#cmd("SET_HOST_PREFIX / GET_HOST_PREFIX", code: "$E1 / $E0", dev: "$70",
  nparam: "1", params: [byte: host slot; SET carries the prefix as payload],
  reply: [GET: the prefix string],
  [A per-host working directory prepended to relative paths.])

#cmd("GET_DEVICE_FULLPATH", code: "$DA", dev: "$70", nparam: "1",
  params: [byte: device slot], reply: [the stored path],
  [Reads back what `SET_DEVICE_FULLPATH` stored.])

#sect[App keys]

#block({
  set par(first-line-indent: 0pt)
  [Small key/value files on the adapter's SD card, namespaced by a 16-bit
  creator id, an app id and a key id --- how a FujiNet program remembers a
  player name between sessions. `OPEN_APPKEY` selects the key and the
  direction; then read or write; then close. The 5 Card Stud and Battleship
  clients use these for the Lobby username.]
})

#cmd("OPEN_APPKEY", code: "$DC", dev: "$70", nparam: "0",
  payload: [6 bytes: `creator` (word) `app` `key` `mode` (0 read, 1 write)
    `reserved`],
  reply: [ACK --- NAK if no SD card, `creator`=0, or a bad mode],
  asm: "        ld  d,$70
        ld  e,$DC
        call FNSTART
        ld  hl,AKREC    ; 6-byte struct
        ld  de,6
        call FNTXPAD
        call FNCOMMIT",
  c: "/* the portable library folds OPEN
   into the read/write: set the ids... */
fuji_set_appkey_details(0xE41C, 1, DEFAULT);
uint8_t val[MAX_APPKEY_LEN + 2];
uint16_t len;
fuji_read_appkey(0 /*key*/, &len, val);",
  [Selects which key the next read or write touches. The portable library has no
  standalone OPEN_APPKEY: `fuji_set_appkey_details(creator, app, size)` records
  the ids, and `fuji_read_appkey` / `fuji_write_appkey` issue the OPEN implicitly.
  The file is `/FujiNet/CCCCAAKK.key` on the SD card; the value cap is 64 bytes.])

#cmd("READ_APPKEY / WRITE_APPKEY / CLOSE_APPKEY", code: "$DD / $DE / $DB",
  dev: "$70", nparam: "0",
  payload: [WRITE: the value, up to 64 bytes],
  reply: [READ: a `u16` length then up to 64 data bytes; others ACK],
  [`READ_APPKEY`'s reply is length-prefixed on this bus. A successful WRITE
  resets the selection, so each write needs a fresh OPEN in write mode.])

#sect[Utilities: entropy, encoding, hashing, QR]

#cmd("RANDOM_NUMBER / GENERATE_GUID", code: "$D3 / $BB", dev: "$70",
  nparam: "0",
  reply: [`$D3`: 4 random bytes · `$BB`: a 37-byte UUID text],
  asm: "        ld  d,$70
        ld  e,$D3
        call FNSTART
        call FNCOMMIT
; 4 bytes at $F800",
  c: "char guid[MAX_GUID_LEN];
fuji_generate_guid(guid);
/* RANDOM_NUMBER ($D3) has no
   fujinet-lib wrapper -- use the
   low-level fuji_bus_call for it */",
  [Hardware entropy from the ESP32, and a fresh printable unique id.
  `GENERATE_GUID` has a wrapper; `RANDOM_NUMBER` does not.])

#cmd("BASE64 / HASH: INPUT, COMPUTE, LENGTH, OUTPUT",
  code: "$D0-$C9 / $C8-$C2", dev: "$70", nparam: "varies",
  params: [INPUT: word byte count; HASH COMPUTE: byte algorithm (0 MD5, 1
    SHA1, 2 SHA256, 3 SHA512); LENGTH/OUTPUT: byte (1 = hex)],
  payload: [INPUT: the bytes to feed], reply: [LENGTH: the size; OUTPUT: the
    result],
  asm: "; SHA-256 of the INPUT buffer:
        ; $C8 INPUT (append), then:
        ld  d,$70
        ld  e,$C7       ; COMPUTE
        call FNSTART
        ld  a,2         ; SHA256
        call FNP8
        call FNCOMMIT",
  c: "/* one-shot SHA-256, hex output */
uint8_t digest[64];
fuji_hash_data(SHA256, data, n,
               true /*hex*/, digest);",
  [Four-step pipelines on the adapter: feed bytes in with INPUT (call it
  repeatedly for long data), COMPUTE, ask LENGTH, then drain with OUTPUT. An
  SHA-256 on call from a Z80. fujinet-lib wraps the whole hash pipeline in one
  `fuji_hash_data(...)` call (`hash_alg_t` = `MD5`/`SHA1`/`SHA256`/`SHA512`);
  the base64 pair (`$D0`--`$C9`) is driven with the four step macros.])

#cmd("QR CODE: INPUT, ENCODE, LENGTH, OUTPUT", code: "$BC / $BD / $BE / $BF",
  dev: "$70", nparam: "varies",
  params: [INPUT: word count · ENCODE: version (0=auto), ECC (0--3), shorten ·
    LENGTH: output mode (0 binary, 2 bitmap) · OUTPUT: word count],
  payload: [INPUT: the text to encode], reply: [LENGTH: 4-byte size; OUTPUT:
    the module data],
  [The adapter renders a QR matrix you can blit --- feed the text, ENCODE,
  ask LENGTH in the mode you want, drain OUTPUT. A version-1 code is 21$times$21
  modules. There is no `QRCODE_CLEAR` on this build.])

#sect[Answered with a NAK on this platform]

#block({
  set par(first-line-indent: 0pt)
  [These `fujiCommandID.h` opcodes fall through every dispatch table in this
  build and earn a NAK; none needs an example. `ENABLE_UDPSTREAM` (`$F0`),
  `SET_BAUDRATE` (`$EB`), `SET_HSIO_INDEX` (`$E3`),
  `SET_SIO_EXTERNAL_CLOCK` (`$DF`), `ENABLE`/`DISABLE_DEVICE` (`$D5`/`$D4`),
  `GET_TIME` (`$D2` --- use device `$45`), `DEVICE_ENABLE_STATUS` (`$D1`),
  `GET_HEAP` (`$C1`), `GET_DEVICE1..10_FULLPATH` (`$A0`--`$A9`),
  `UPDATE_FIRMWARE` (`$90`), and `HSIO_INDEX` (`$3F`). Most are other
  platforms' bus tuning.]
})

// ============================================================
// CHAPTER: COMMAND REFERENCE -- THE NETWORK DEVICE
// ============================================================
#chapter[Command Reference: The Network Device]

#block({
  set par(first-line-indent: 0pt)
  [Every command devices `$71`--`$78` answer, verified against the RS232
  network dispatcher (`network.cpp`). Most opcodes are the ASCII letter of
  their name --- `'O'`pen, `'R'`ead, `'W'`rite --- a habit from the Atari. The
  connection, the devicespec grammar, and per-protocol behaviour belong to
  #emph[The FujiNet Network Protocol Handbook]; these are the cards. Cap a
  read at 1,024 bytes (the reply window) and a write's payload at what fits the
  320-byte TX stream.]
})

#sect[The lifecycle five]

#cmd("NET_OPEN", code: "$4F 'O'", dev: "$71", nparam: "2",
  params: [bytes: access mode (4 read, 8 write, 12 read/write), translation
    (0 none, 1 CR, 2 LF, 3 CR/LF)],
  payload: [#strong[256 bytes]: the devicespec, NUL-padded],
  reply: [ACK when the connection is established],
  asm: "        ld  d,$71
        ld  e,$4F
        call FNSTART
        ld  a,12        ; read/write
        call FNP8
        xor a
        call FNP8       ; no translation
        ld  hl,SPEC
        ld  de,256
        call FNTXPAD
        call FNCOMMIT",
  c: "if (network_open(spec, OPEN_MODE_RW,
        OPEN_TRANS_NONE) == FN_ERR_OK)
    /* connected */;
/* HTTP GET: OPEN_MODE_HTTP_GET_H */",
  [Mode 12 doubles as GET on an HTTP adapter, whose fetch is deferred to the
  first READ. Modes 13 POST, 14 PUT, 5 DELETE, 6 HEAD are the HTTP family.
  NETCAT opens a socket read/write with no translation.])

#cmd("NET_STATUS", code: "$53 'S'", dev: "$71", nparam: "2",
  params: [two zero bytes (the build reads the request type from parameter 1)],
  reply: [4 bytes: `avail` (word), `connected`, `devstatus` (1 SUCCESS, 136
    end-of-file)],
  asm: "        ld  d,$71
        ld  e,$53
        call FNSTART
        xor a
        call FNP8
        xor a
        call FNP8
        call FNCOMMIT
; avail=$F800/1, conn=2, ds=3",
  c: "uint16_t avail;
uint8_t conn, ds;
network_status(spec, &avail, &conn, &ds);",
  [The heartbeat. A terminal gates on `conn` (connected); a fetch-and-render
  client gates on `ds` (device status --- 1 SUCCESS, 136 end-of-file); everyone
  reads `avail`. `network_status` fills all three.])

#cmd("NET_READ", code: "$52 'R'", dev: "$71", nparam: "1",
  params: [word: byte count --- clamp to `avail` and to 1,024],
  reply: [exactly that many bytes, in the reply window],
  asm: "        ld  d,$71
        ld  e,$52
        call FNSTART
        ld  hl,(WANT)   ; count
        call FNP16
        call FNCOMMIT
        call FNRLEN     ; HL = length",
  c: "int16_t n = network_read_nb(spec,
                            buf, want);
if (n > 0) render(buf, n);
/* render BEFORE any other
   transaction repaints the window */",
  [The firmware sends exactly `want` bytes on ACK; a short/failed read comes
  back as a NAK. On deferred HTTP the first READ performs the fetch --- give
  it the OPEN-class wait.])

#cmd("NET_WRITE", code: "$57 'W'", dev: "$71", nparam: "1",
  params: [word: byte count],
  payload: [exactly that many bytes],
  reply: [ACK],
  asm: "        ld  d,$71
        ld  e,$57
        call FNSTART
        ld  hl,(LEN)
        call FNP16
        ld  hl,BUF
        ld  b,(LEN)
WLP:    ld  a,(hl)
        call FNTXB
        inc hl
        djnz WLP
        call FNCOMMIT",
  c: "network_write(spec, buf, len);",
  [The count rides twice --- as the parameter and as the payload the cartridge
  measures. `network_write` handles both. Keep it well inside the 320-byte TX
  stream; NETCAT caps a line at 120 bytes.])

#cmd("NET_CLOSE", code: "$43 'C'", dev: "$71", nparam: "0",
  reply: [ACK --- and an empty reply window],
  [Hang up. Send it when you mean to end the connection; a game that reopens
  per request closes at the #emph[start] of the next request, never between a
  READ and the rendering that follows it.])

#sect[Structured channels, seek, and line discipline]

#cmd("NET_SET_CHANNEL_MODE / NET_PARSE / NET_QUERY", code: "$4D / $50 / $51",
  dev: "$71", nparam: "2 / 0 / 0",
  params: [SET_CHANNEL_MODE: byte (ignored), then mode (0 raw, 1 JSON)],
  payload: [QUERY: the path, e.g. `/players/0/name`],
  reply: [QUERY: the value as text, then READ it],
  [Switch an open HTTP-family connection to the on-adapter JSON parser
  (`'M'` reads the mode from the #emph[second] parameter), `PARSE` the body,
  then `QUERY` one element --- the difference between parsing JSON on a Z80 and
  not. The games skip this and ask their servers for binary with `?bin=1`.])

#cmd("NET_SEEK / NET_TELL", code: "$25 '%' / $26 '&'", dev: "$71",
  nparam: "1 / 0",
  params: [SEEK: 4-byte offset], reply: [TELL: 4-byte position],
  [Random access where the protocol supports it (TNFS, HTTP ranges).])

#cmd("NET_TRANSLATION / NET_SET_EOL / NET_SET_INT_RATE",
  code: "$54 / $4C / $5A", dev: "$71", nparam: "2",
  params: [TRANSLATION: byte (ignored) then code; SET_EOL: the EOL pair, a
    first byte of 0 clears; SET_INT_RATE: byte (ignored) then rate],
  reply: [ACK],
  [Line-ending translation and custom terminators after OPEN. `SET_INT_RATE`
  paces a bus interrupt on platforms that have one; the ColecoVision has no
  interrupt line back from the cartridge, so it is accepted and irrelevant ---
  polling `FN_ACKSEQ` is the only completion mechanism here.])

#sect[Filesystems, sockets, and credentials]

#cmd("NET_RENAME / DELETE / LOCK / UNLOCK / MKDIR / RMDIR / CHDIR / GETCWD",
  code: "$20 $21 $23 $24 $2A $2B $2C $30", dev: "$71", nparam: "0",
  payload: [the target path (RENAME: `old,new`)],
  reply: [ACK; GETCWD returns the path],
  [Filesystem verbs on protocols that have files --- TNFS, FTP, SMB. `CHDIR`
  and `GETCWD` move and report the working directory.])

#cmd("NET_CONTROL / NET_CLOSE_CLIENT", code: "$41 'A' / $63 'c'", dev: "$71",
  nparam: "0", reply: [ACK],
  [TCP server duty: a listening `N:TCP://:port/` accepts a waiting client with
  `'A'` and hangs up on that client with `'c'` while keeping the listener ---
  your ColecoVision can be the BBS.])

#cmd("NET_GET_REMOTE / NET_SET_DESTINATION / NET_USERNAME / NET_PASSWORD",
  code: "$72 / $44 / $FD / $FE", dev: "$71", nparam: "0",
  payload: [SET_DESTINATION: `host:port`; USERNAME/PASSWORD: the credential],
  reply: [GET_REMOTE: the last datagram's sender],
  [UDP's who-said-that and talk-to-them-instead, plus stored credentials for
  the next OPEN on protocols that log in (FTP, SSH, SMB) --- send them before
  OPEN.])

#sect[Answered with a NAK on this platform]

#block({
  set par(first-line-indent: 0pt)
  [Enum'd but not dispatched in this build, so a NAK, no example:
  `NET_GET_DSTATS_VALUE` (`$FF`), `NET_CHANNEL_MODE` getter (`$FC` --- the
  setter `$4D` works), `NET_SET_PARAMETERS` (`$FB`), `NET_SET_CHANNEL`
  (`$FA`), `NET_SET_HSIO_INDEX` (`$E3`), `NET_QUERY_ALT`/`NET_PARSE_ALT`
  (`$81`/`$80`), `NET_GET_ERROR` (`$45` --- read the STATUS device byte
  instead), and `NET_HSIO_INDEX` (`$3F`).]
})

// ============================================================
// CHAPTER: COMMAND REFERENCE -- THE OTHER DEVICES
// ============================================================
#chapter[Command Reference: The Other Devices]

#twocol[
The mailbox is a transport, not a translator: whatever byte you put in the
DEVICE register goes on the wire. Beyond the Fuji and network devices, the
fujinet-pc build instantiates four more --- disks, a printer, a clock, and a
Hayes-style modem. #strong[Nothing in the ColecoVision tree drives them yet];
they are reachable capability, documented here honestly as such. The examples
show the shape; the behaviour is transcribed from the RS232 handlers.
]

#sect[Disk --- devices 31H--38H]

#block({
  set par(first-line-indent: 0pt)
  [Eight disk devices, `$31`+#emph[n]. On this build every sector is 512 bytes
  and the offset is `sector` $times$ 512. Read and write name the sector in
  `param(0)`; a missing parameter throws on the adapter, so always supply it.]
})

#cmd("DISK_READ / DISK_WRITE / DISK_PUT", code: "$52 / $57 / $50", dev: "$31",
  nparam: "1",
  params: [`param(0)`: sector number],
  payload: [WRITE/PUT: 512 bytes], reply: [READ: 512 bytes; WRITE/PUT: ACK],
  asm: "        ld  d,$31       ; disk 0
        ld  e,$52       ; READ
        call FNSTART
        ld  hl,(SEC)
        call FNP16
        call FNCOMMIT
; 512 bytes at $F800",
  c: "/* no fujinet-lib wrapper for disks:
   drop to the low-level mailbox */
fn_start(0x31, 0x52);   /* READ */
fn_param16(sector);
fn_commit();            /* 512B @ $F800 */",
  [`$53` (`DISK_STATUS`) is #strong[not] a status call on this build --- it
  falls through into the write path, so never send it to a disk expecting a
  status reply. With no image mounted, READ returns NAK.])

#cmd("DISK_FORMAT / PERCOM_READ / PERCOM_WRITE", code: "$21 / $4E / $4F",
  dev: "$31", nparam: "0",
  reply: [FORMAT: a bad-sector map; PERCOM_READ: a 12-byte geometry block],
  [Vestigial on this build: FORMAT writes nothing to the image, and the PERCOM
  block is a 12-byte scratch area with no effect on geometry. Documented for
  completeness.])

#sect[Printer --- device 40H]

#cmd("PRINTER_WRITE / PRINTER_PUT / PRINTER_STATUS", code: "$57 / $50 / $53",
  dev: "$40", nparam: "0 / 0 / 1",
  params: [STATUS: byte request type, required but ignored],
  payload: [WRITE/PUT: the bytes to print (keep under 255)],
  reply: [WRITE/PUT: ACK; STATUS: 4 bytes],
  asm: "        ld  d,$40
        ld  e,$57       ; WRITE
        call FNSTART
        ld  hl,LINE
        ld  b,(LLEN)
PLP:    ld  a,(hl)
        call FNTXB      ; one byte
        inc hl
        djnz PLP
        call FNCOMMIT",
  c: "/* no fujinet-lib wrapper for the
   printer: low-level mailbox */
fn_start(0x40, 0x57);
fn_tx_bytes(line, len); /* <255 */
fn_commit();",
  [Output goes to a `/paper` file on the adapter, retrieved through its web UI
  --- not to a PDF. The default emulation is trimmed plain text. The printer
  can be disabled in config, in which case it does not reply at all and the
  host must time out.])

#sect[Clock --- device 45H (APETime)]

#block({
  set par(first-line-indent: 0pt)
  [Present only when APETime is enabled in the adapter's config (it is, by
  default). Reads come in many formats; the parameter, when 1, selects an
  alternate time zone set by `SETTZ`.]
})

#cmd("APETIME_GETTIME / GET_ISO_LOCAL / SETTZ", code: "$93 / $49 / $99",
  dev: "$45", nparam: "0 / 0 / 0",
  params: [byte 1 = alternate TZ (on the read commands)],
  payload: [SETTZ: a POSIX TZ string],
  reply: [GETTIME: 6 bytes `DD MM YY HH MM SS`; GET_ISO_LOCAL: a 25-byte ISO
    8601 string],
  asm: "        ld  d,$45
        ld  e,$93       ; GETTIME
        call FNSTART
        call FNCOMMIT
; DD MM YY HH MM SS at $F800",
  c: "uint8_t t[8];
clock_get_time(t, APETIME_BINARY);
/* t = DD MM YY HH MM SS */
/* clock_set_tz(\"EST5EDT\"); then
   clock_get_time(t, TZ_ISO_STRING); */",
  [Other formats answer too: PRODOS (`$50`, 4 bytes), SOS (`$53`, ASCII),
  simple (`$54`, 7 bytes), simple+hundredths (`$4D`, 8 bytes), ISO UTC
  (`$5A`), the raw TZ string (`$47`) and its length (`$4C`). `SETTZ_ALT`
  (`$74`) stores the system TZ persistently.])

#sect[Modem --- device 50H]

#block({
  set par(first-line-indent: 0pt)
  [A Hayes AT-command virtual modem that dials TCP instead of phone lines:
  `ATDT host:port` opens a socket, `ATNET1` runs the session through telnet
  negotiation. Ten packet commands configure and poll it; the character stream
  itself is unframed. Reachable but unexercised on the ColecoVision.]
})

#cmd("MODEM_STATUS / MODEM_WRITE / MODEM_STREAM", code: "$53 / $57 / $58",
  dev: "$50", nparam: "1 / 0 / 0",
  params: [STATUS: byte (ignored, required)],
  payload: [WRITE: an AT command line, or data when connected],
  reply: [STATUS: 2 bytes (byte 1 carries the handshake bits: `$CD` connected
    with data, `$CC` connected idle, `$00` idle); WRITE: ACK; STREAM: a 9-byte
    baud table],
  [The other seven --- `CONTROL $41`, `CONFIGURE $42`, `SET_DUMP $44`,
  `LISTEN $4C`, `UNLISTEN $4D`, `BAUDRATELOCK $4E`, `AUTOANSWER $4F` ---
  configure the virtual modem. Disabled in config, it does not reply.])

// ============================================================
// CHAPTER: COMMAND REFERENCE -- THE CARTRIDGE ITSELF
// ============================================================
#chapter[Command Reference: The Cartridge Itself]

#twocol[
Below the FujiBus devices sits the cartridge's own protocol --- the hotspot
decode and the register file the earlier chapters used. This is the whole of
it, in one place, plus the one message the cartridge #emph[receives] rather
than sends.

#sub[Layer 1: the hotspot pages]

Every console-to-cartridge byte is a read whose address is the message.
]

#fig(caption: [The hotspot decode: what each read does.],
  table(columns: (auto, 1fr),
    table.header[Console read][Effect],
    [`$FD00 + r`, r < `$80`], [arm register `r`],
    [`$FDFE`], [swap to the staged boot image (BOOTLOCK-armed only)],
    [`$FE00 + v`], [armed register $arrow.l$ `v`, then disarm],
    [`$FF00 + v`], [append `v` to the TX stream (max 320)],
    [anything below `$FD00`], [an ordinary ROM read; no side effect],
  ))

#twocol[
#sub[Layer 2: the register file]

Written through a REGSEL/REGDATA read pair. The complete set:
]

#fig(caption: [The mailbox registers.],
  table(columns: (auto, auto, 1fr),
    table.header[Reg][Name][Use],
    [`$00`], [DEVICE], [FujiBus device id],
    [`$01`], [COMMAND], [FujiBus command id],
    [`$02`], [NPARAM], [parameters leading the TX stream (max 8)],
    [`$05`], [DATA_RST], [any value rewinds the TX write pointer],
    [`$06`], [RXSLICE], [reply slice --- vestigial, one slice only],
    [`$10`], [SEQ], [nonzero, $eq.not$ ACKSEQ: launch the transaction],
    [`$11`], [BOOTLOCK], [`$B5` arms the ROM swap],
    [`$12`/`$13`], [BOOTSEL], [`$B5` then `$4A`: reboot cart to update mode],
  ))

#twocol[
#sub[Layer 3: the DBC push (device FFH)]

One device the cartridge #emph[receives] on, unsolicited, while a
`MOUNT_IMAGE` is still outstanding: the ESP32 pushes the image to the RP2040
as FujiBus frames addressed to device `$FF` (DBC) --- `NET_OPEN` with a stream
id and 32-bit size, `NET_WRITE` of 512-byte chunks, `NET_CLOSE` to commit.
Stream 0 is the ROM, stream 1 its `.cfg` sidecar. Your program never sends
these; it watches them arrive on `FN_BOOTSTAT` and `FN_BOOTPCT`. Boot errors
land in `FN_BOOTERR`: 1 too big, 2 truncated, 3 no mapping fits, 4 store busy.
]

// ============================================================
// CHAPTER: NETCAT
// ============================================================
#chapter[Netcat]

#twocol[
"Dial, you tinhorn!" NETCAT is the family's terminal: give it any `N:`
devicespec and it pumps bytes between the connection and a scrolling
32$times$20 pane, forever. Call a telnet BBS, watch a TCP echo server, talk
to anything that talks back. It is also the network device's teaching program
--- the first client in this book to hold a single connection open for its
whole life, the first to send `NET_WRITE`, and the first with a pane that
scrolls. Its full source is in Appendix C.

#sub[How to get NETCAT on your screen]

Build with `./build.sh` (the default devicespec, a telnet BBS, bakes in) and
run with `pico/coleco/run.sh netcat` under MAME, or burn `build/netcat.bin` to
a cartridge. The dial screen offers the devicespec for editing on the
on-screen keyboard; #key[\#] dials.

#sub[Hand controls]

#dotdef(
  ([Control Stick], [steer the on-screen keyboard cursor]),
  ([Fire / #key[\#]], [in the editor: type / accept · in session: compose a line]),
  ([Keypad #key[\*]], [in the editor: backspace · in session: hang up]),
)
]

#fig(caption: [NETCAT in session against a telnet BBS, captured from MAME.],
  tv("NETCAT  CONNECTED

Welcome to the Cave BBS
Enter your handle: coleco
Last on: never.

Main >

# SEND   * HANG UP", w: 3.05in, size: 7.2pt))

#twocol[
#sub[Inside the program]

The session loop is the three rules of the network device in the flesh:
#strong[status, read, draw], in that order, with nothing between the read and
the draw that could repaint the reply window. A terminal watches `connected`
rather than a device-status byte, because on a live socket end-of-file is a
hangup, not an error.
]

#codepanel("netcat.c -- the whole terminal, one loop",
"for (;;) {
    if (!net_status(&avail, &conn, &ds)) return;   /* link lost */
    if (!conn && avail == 0) return;               /* disconnected */

    if (avail != 0) {
        got = net_read(avail > NET_READ_MAX ? NET_READ_MAX : avail);
        term_puts(FN_REPLY, got);   /* draw straight out of the window,
                                       before any other transaction */
    }
    ev = in_read();
    if (ev == IN_KEYHASH || ev == IN_FIRE) compose_and_send();
    else if (ev == IN_KEYSTAR) { net_close(); return; }
}")

#twocol[
Scrolling is honest work: the TMS9918 in Graphics 1 has no scroll register, so
`netterm.c` copies every row up one through OS7's `read_vram`/`write_vram` and
clears the last. And because there is no RAM to shadow the pane in, composing a
line is the one clever move: the on-screen keyboard borrows the whole screen,
so NETCAT saves the pane to #emph[spare VRAM] first (`term_save`) and restores
it after (`term_restore`) --- the conversation survives the detour without ever
occupying console RAM. The five `N:` commands live in `netlib.c`; the shared
mailbox, display, input and editor come from `../common`. Full listings:
Appendix C.
]

// ============================================================
// CHAPTER: 5 CARD STUD
// ============================================================
#chapter[5 Card Stud]

#twocol[
Ante up --- the table is world-wide. 5 CARD STUD joins live multiplayer poker
at `5card.carr-designs.com`, against players on Ataris, Apples, ADAMs,
Intellivisions and the rest of the FujiNet family. The #strong[server owns the
rules]: every legal move arrives over the wire with its label, so the client
carries no poker logic at all --- and inherits rule changes without a re-burn.

#sub[How to play]

Build with `./make-exp coleco` and run. Enter a name on the on-screen
keyboard, pick a table, and the keypad presses whichever move the server dealt
you. The stick and both fire buttons drive the table; the keypad's
#key[1]--#key[5] map to refresh, help, colour, name and quit.

#sub[Inside the program]

5 CARD STUD is the C client this whole platform was brought up to prove, and
every one of its ColecoVision-specific decisions is forced by the same fact:
one kilobyte of RAM, and a game state that is 418 bytes of it. So the state is
#strong[never copied into RAM]. It is read in place out of the reply window ---
which is cartridge ROM --- through a single audacious macro.
]

#codepanel("src/misc.h and src/coleco/vars.h -- the state IS the window",
"#define COLECO_REPLY_WINDOW 0xF800
/* The 418-byte game state lives in the cartridge's reply window,
   not in RAM. It is READ-ONLY -- a store here goes nowhere -- and
   valid only until the next fuji_* call of any kind. */
#define clientState (*(ClientState *) COLECO_REPLY_WINDOW)
#define state clientState.game")

#twocol[
Two rules follow from that macro, and the network layer is built around them:
]

#codepanel("src/coleco/network.c -- one transaction, and nothing after it",
"uint8_t getResponse(char *url, unsigned char *buffer, uint16_t max_len)
{
    if (channelOpen) { network_close(url); channelOpen = 0; }
    if (network_open(url, OPEN_MODE_HTTP_GET_H, OPEN_TRANS_NONE)
        != FN_ERR_OK) return 0;
    channelOpen = 1;
    /* ONE transaction: network_read_nb waits for the whole body to be
       available, then issues exactly one read. network_read()'s loop
       would copy its second chunk to buffer+count -- cartridge ROM --
       and lose the tail silently. And nothing runs after: the close is
       deferred to the top of the NEXT call, because every transaction
       repaints the window we are about to render from. */
    return network_read_nb(url, buffer, max_len) > 0;
}")

#twocol[
The rest of the port is a study in living within the budget. The vblank NMI
handler (`myInt`) does nothing but bump two counters --- it must never touch
`$F800` and up, so it is kept deliberately tiny. `conbuf.asm` cuts z88dk's
256-byte console scroll buffer to sixteen, safe only because the game disables
vertical scrolling. The seat-position tables are `const`, so they live in ROM
rather than spending 96 bytes of RAM. And `coleco-romstamp.py` enforces the
cartridge contract at build time: exactly 32K, the `55 AA` header, and the
`FUJI` claim at `$FCFC` --- without which the cartridge shuts the mailbox down
for the session.

When you quit, the game hands the console back to the FujiNet Lobby: it finds
`ec.tnfs.io` among the host slots, mounts `coleco/lobby.rom`, watches
`FN_BOOTPCT` climb, and takes the swap. Full listings: Appendix C.
]

// ============================================================
// CHAPTER: BATTLESHIP
// ============================================================
#chapter[Battleship]

#twocol[
You sank my --- well, you know. BATTLESHIP is up to four players, live over
the network at `battleship.carr-designs.com`, on boards small enough that all
of them fit the screen at once: four 10$times$10 quadrants. You are always
quadrant 0 --- the server rotates its player list so every client sees itself
first --- and the game meets the Intellivision port at the same tables.

#sub[How to play]

Name, table, then place your five ships (the placement screen rejects overlaps
and offers a random legal seed), press ready, and when your turn lights up
steer the target cursor and fire. The keypad's #key[1]--#key[5] map to
refresh, help, sink-a-ship, name and quit.

#sub[Inside the program]

BATTLESHIP shares 5 CARD STUD's shape --- state in the reply window, one
transaction per read --- but reaches the mailbox through its own hook, enabled
with `-DCUSTOM_FUJINET_CALLS`, so the shared game core calls a single function
the ColecoVision port defines:
]

#codepanel("src/coleco/fujinet.c -- the custom network hook",
"int16_t custom_network_call(char *url, uint8_t *buffer, uint16_t max_len)
{
    if (channelOpen) { network_close(url); channelOpen = 0; }
    if (network_open(url, OPEN_MODE_HTTP_GET, OPEN_TRANS_NONE) != FN_ERR_OK)
        return -1;
    channelOpen = 1;
    return network_read_nb(url, buffer, max_len);   /* one transaction */
}")

#twocol[
Two economies are worth the look. The graphics run GRAPHICS II as a
#strong[cellmap]: z88dk lays down an identity name table once and never touches
it, so every 32$times$24 cell owns eight pattern bytes and eight colour bytes,
and drawing a cell is two VRAM writes --- no glyph budget, no RAM shadow. And
the 100-cell "was this square empty" shadow, needed only to trigger the shot
animation, is packed to #strong[one bit per cell] --- thirteen bytes per
player instead of a hundred. The poll loop backs off when the server errors
(waiting longer after each failure) and, on the sound side, routes explosion
sub-bass to the noise channel because it falls below the tone chip's floor.
Server and wire format are documented with the game; full listings: Appendix C.
]

// ============================================================
// CHAPTER: CONFIG
// ============================================================
#chapter[Config]

#twocol[
CONFIG is the program your FujiNet cartridge wakes up in --- the adapter's
face on the ColecoVision, and the only client in this book that speaks to
device `$70`. It lists host slots, renames them on an on-screen keyboard,
browses directories, scans WiFi and joins a network, and boots what you pick,
progress bar and all.

It is also the one program here that ships #emph[inside] the cartridge:
`build-cart.sh` packs the built client into `fujiconfigrom.h`, a C array
compiled into the RP2040 firmware, which serves it as the power-on image ---
and after CONFIG network-boots something else, the swap replaces it entirely.

#sub[A note on where CONFIG lives]

The CONFIG in this book is `fujicfg.c`, from the firmware's own `testrom/`. It
is the working browse-and-boot client the cartridge serves today, and its own
header says it is the stand-in for the full `fujinet-config` port that will one
day live in that project's `coleco/` directory. It is documented here because
it is the real thing --- the code on the cartridge --- not a sketch.

#sub[Around the screens]

Three pages: HOSTS (pick one to open, #key[9] to rename, #key[\#] for the
config screen), FILES (browse and boot), and CONFIG (adapter info, a WiFi
scan, and joining). The selection bar is not a colour change --- Graphics 1
has no per-cell colour --- but a second copy of the character set at pattern
`$80`, so highlighting a row means re-pointing its name-table bytes at the
inverse glyphs.
]

#fig(caption: [CONFIG's host page.],
  tv("FUJINET   C O N F I G

SELECT A HOST
 1 fujinet.online
 2 ec.tnfs.io
 3 my-basement-pi
 4 (empty)

FIRE OPEN  9 RENAME  # CONFIG",
  w: 3.05in, size: 7.0pt))

#twocol[
#sub[Two contracts]

CONFIG leans on two rules this book has already met. The on-screen keyboard
(`fujiedit.c`) runs #strong[no mailbox transactions] --- a hard contract, so
that a caller can hold data in the reply window across an edit; that is what
lets `rename_host` re-read eight host slots, edit one on screen, and stream all
eight back out of the window. And the file browser never keeps a filename in
RAM: it draws each entry straight from the window and, to boot one, streams it
straight back into the next transaction's payload with `fn_tx_path`.
]

#codepanel("fujicfg.c -- read a directory entry, and know when to stop",
"static bool read_entry(unsigned char maxlen)
{
    volatile unsigned char *r;
    fn_start(FN_DEV_FUJINET, CMD_READ_DIR_ENTRY);
    fn_param8(maxlen);   /* the crunch width */
    fn_param8(0);
    if (fn_commit() != FN_OK || !fn_acked()) return false;

    r = FN_REPLY;        /* through a local pointer, never FN_REPLY[i] */
    if (r[0] == 0x7F && r[1] == 0x7F) return false;   /* end of dir */
    /* an SD host hands back '.' and '..' forever instead of $7F$7F,
       and reading past the end poisons SET_DIRECTORY_POSITION for the
       session -- so stop on those too, and never read past it. */
    if (r[0] == '.' && (r[1] == 0 || (r[1] == '.' && r[2] == 0)))
        return false;
    return true;
}")

#twocol[
Deliberately not here, and left to the full CONFIG port: descending into
subdirectories, disk-slot management, app keys. This is the browse-and-boot
core, proven against a live adapter. Its helper modules --- the OS7 display
layer `fujidisp.c`, the POLLER-based input `fujiin.c`, the on-screen keyboard
`fujiedit.c`, the mandatory-first sound silencer `fujisnd.c`, and the boot
splash --- are the same ones NETCAT and the milestone clients share, and all
are printed in Appendix C.
]

// ============================================================
// CHAPTER: ALWAYS MORE TO COME
// ============================================================
#chapter[Always More To Come]

#twocol[
Your FujiNet cartridge does not only ship four programs --- it opens the
ColecoVision to virtually hundreds of program possibilities. Here is where to
go next.

#sub[The Network Protocol Handbook]

The companion volume from this series documents every URL scheme the `N:`
device speaks --- `TCP:`, `TELNET:`, `HTTP:`/`HTTPS:`, `TNFS:`, `JSON:`,
`SSH:`, `SMB:`, `FTP:`, `UDP:`, `GMAIL:`, `GCAL:` and more --- with the
complete devicespec grammar, every mode and error code, and worked examples.
Everything in it runs on the ColecoVision through the five commands of the
Network Device chapter.

#sub[FujiNet Go Coleco Desktop]

If you want to develop without touching hardware or hand-assembling a MAME
tree, the next chapter covers #emph[FujiNet Go Coleco Desktop]: a
self-contained ColecoVision with a FujiNet built in, a Z80 and VDP debugger,
and drag-and-drop mounting --- the friendliest bench there is.

#sub[The sources of truth]

#dotdef(
  ([`fuji_mailbox.h`], [the mailbox spec --- firmware `pico/coleco/`]),
  ([`fujilib.c` / `fujimail.inc`], [the C and Z80 transports (Appendix C)]),
  ([`fujiCommandID.h`], [every command opcode, canonically]),
  ([`fujitest.c`, `acfg.asm`], [the minimal round trip, both languages]),
)

#sub[The programs]

Each program's repository carries its full build system, its MAME smoke tests,
and a README with its own war stories: `netcat` (this book's, in the manuals
repo), `fujinet-5cardstud`, `fujinet-battleship`, and the firmware's
`pico/coleco/testrom` for CONFIG --- all under `github.com/FujiNetWIFI` and
friends. The game servers are `carr-designs.com` productions.

So enjoy your FujiNet: you now have a whole new dimension of home computing at
your fingertips.
]

// ============================================================
// CHAPTER: FUJINET GO COLECO DESKTOP
// ============================================================
#chapter[FujiNet Go Coleco Desktop]

#twocol[
The whole stack in this book --- a ColecoVision, a FujiNet, and the network
between them --- fits in one desktop application. #strong[FujiNet Go Coleco
Desktop] is a self-contained ColecoVision with a FujiNet built in: browse a
network host from the console, boot images over the network, and let the booted
program keep talking to the network, all in one window. It is the newest member
of the FujiNet Go desktop family, and for a FujiNet programmer it is the
friendliest bench there is.

#sub[For users]

Download a build for your platform from the releases page:

#spec("github.com/FujiNetWIFI/fujinet-go-coleco-desktop/releases")

There are Linux packages for both GNOME and KDE (`.deb`, `.rpm`, `.tar.gz`),
Windows (a `.zip` and a per-user NSIS installer that needs no administrator),
macOS (an `.app` bundle, Apple Silicon and Intel), and two single-file
Flatpaks. Once it is running: drag a cartridge (`.rom`, `.col`, `.bin`) onto
the window to load it, or a disk or tape image to hand it to the built-in
FujiNet. Every real ColecoVision mapper works --- MegaCart, Activision,
X-in-1, and the Opcode Super Game Module, which is fitted by default. Both hand
controllers are drawn on screen and clickable, and every control is remappable.
]

#important[
You must supply your own #strong[`OS7.rom`]. The ColecoVision OS-7 BIOS is
copyrighted Coleco firmware and is #strong[not] redistributed with the app.
Put an #strong[exactly 8192-byte] `OS7.rom` in the ROM directory
(`~/.local/share/fujinet-go-coleco/roms/` on Linux,
`%LOCALAPPDATA%\\fujinet-go-coleco` on Windows) or use the #strong[Import
BIOS...] menu item. The app rejects a file of any other size and, without a
BIOS, boots to the FujiNet CONFIG client. See the project's `COMPLIANCE.md`.
]

#twocol[
#sub[The menus]

#dotdef(
  ([Machine], [open / eject a cartridge, reset, reset to CONFIG, import BIOS,
    preferences]),
  ([View], [the controllers panel, the debugger, TV aspect, smooth scaling]),
  ([FujiNet], [the adapter's configuration and a live console log]),
)

#sub[For developers]

The app is the fastest way to see a client run without a MAME graft. It builds
with CMake and provides its two dependencies --- the emulator core and the
FujiNet firmware --- automatically:

#codepanel("building the desktop app", "cmake -B build
cmake --build build
ctest --test-dir build --output-on-failure
# against working checkouts instead of the pinned commits:
cmake -B build -DADAMCORE_SRC=~/Workspace/adamcore \\
               -DFUJINET_SRC=~/Workspace/fujinet-firmware", size: 7.2pt)

The emulator is #strong[adamcore], a clean-room GPLv3 ColecoVision core (its
Z80 validated against Tom Harte's tests and ZEXALL, with a TMS9928A VDP, an
SN76489, and a working Super Game Module). The FujiNet is compiled in-process
as `libfujinet` from the firmware's `colecovision-bringup` branch --- the same
mailbox sources this whole book describes, exercised over a loopback socket
inside the one process. FujiNet's bus-over-IP listener is on port 11502 and its
web admin UI on 11503; unusually for the family, FujiNet listens and the
emulator's cartridge dials in, so the session starts FujiNet first.

Every frontend --- GNOME (GTK4), KDE (Qt6), macOS (AppKit), Windows (Win32) ---
carries the same #strong[Z80 and VDP debugger] over one shared engine: CPU,
VDP and trace tabs, breakpoints by symbol, a trace ring, a pokeable live VRAM
dump, and a full VDP decode (name table, pattern banks, sprites and their
attribute table, the palette). When a client misbehaves, this is where you
watch the mailbox transactions happen a frame at a time.
]
#counter(heading).update(0)
#appendix.update(true)
// Letters at level 1 (so the counter advances and the kicker/TOC show A, B,
// C, D); nothing at deeper levels (appendix section titles carry their own
// labels).
#set heading(numbering: (..n) => {
  let nums = n.pos()
  if nums.len() == 1 { numbering("A", ..nums) } else { none }
})

#chapter[Mailbox Quick Reference]

#columns(1, gutter: 16pt, {
  set par(first-line-indent: 0pt)
  sub[Status bytes (painted ROM)]
  table(columns: (auto, 1fr),
    table.header[Addr][Meaning],
    [`$F800`], [reply window, 1024 bytes],
    [`$FC00`], [ACKSEQ --- echoes SEQ when ready],
    [`$FC01`], [STATUS --- bit0 link up],
    [`$FC02`], [ERR --- transport verdict],
    [`$FC03`], [REPLYCMD --- `$06` ACK / `$15` NAK],
    [`$FC04`], [RXLEN low],
    [`$FC05`], [RXLEN high],
    [`$FC06`], [BOOTSTAT],
    [`$FC07`], [BOOTPCT 0--100],
    [`$FC08`], [BOOTERR],
    [`$FC09`], [`F` (presence)],
    [`$FC0A`], [`N`],
    [`$FC0B`], [PROTOVER (1)],
  )
  sub[Hotspots (reading is writing)]
  table(columns: (auto, 1fr),
    table.header[Read][Effect],
    [`$FD00+r`], [arm register r (r < `$80`)],
    [`$FDFE`], [swap to staged image (armed only)],
    [`$FE00+v`], [armed register $arrow.l$ v],
    [`$FF00+v`], [append v to TX (max 320)],
  )
  sub[Registers]
  table(columns: (auto, 1fr),
    table.header[Reg][Use],
    [`$00`], [DEVICE],
    [`$01`], [COMMAND],
    [`$02`], [NPARAM],
    [`$05`], [DATA_RST (rewind TX)],
    [`$10`], [SEQ (ACKSEQ+1, wrap 255->1)],
    [`$11`], [BOOTLOCK (`$B5`)],
  )
  sub[The five moves]
  block({
    set text(size: 7.8pt)
    [#rnum(1) BEGIN: rewind TX; DEVICE, COMMAND, NPARAM.\
     #rnum(2) STREAM: params (size 1/2/4 + LE value) then payload.\
     #rnum(3) COMMIT: SEQ = ACKSEQ+1 (wrap 255->1).\
     #rnum(4) WAIT: poll ACKSEQ; then ERR, REPLYCMD, RXLEN.\
     #rnum(5) READ: the reply is at `$F800`, in place.]
  })
  sub[Layout contract (cart offsets)]
  block({
    set text(size: 7.8pt)
    [Code below `$7800` · claim `FUJI` at `$7CFC` · image exactly 32768
    bytes · reply max 1024 · TX max 320 · NMI must never read `$F800`+.]
  })
})

// ============================================================
// APPENDIX B: ERROR AND STATUS CODES
// ============================================================
#chapter[Error and Status Codes]

#columns(1, gutter: 16pt, {
  set par(first-line-indent: 0pt)
  sub[FN_ERR --- transport verdict (FC02H)]
  table(columns: (auto, 1fr),
    table.header[Value][Meaning],
    [0], [OK --- carried perfectly],
    [1], [NOLINK --- ESP32-S3 not enumerated],
    [2], [TIMEOUT --- adapter did not answer],
    [3], [BADFRAME --- SLIP/checksum failure],
    [4], [TOOBIG --- reply exceeded 1024 bytes],
    [`$FF`], [EWAIT (client) --- the cart never answered],
  )
  sub[FN_REPLYCMD (FC03H)]
  table(columns: (auto, 1fr),
    table.header[Value][Meaning],
    [`$06`], [ACK --- accepted, reply painted],
    [`$15`], [NAK --- refused: bad params, missing
      target, unsupported opcode],
  )
  sub[FN_BOOTSTAT (FC06H)]
  table(columns: (auto, 1fr),
    table.header[Value][Meaning],
    [0], [IDLE --- no push in progress],
    [1], [XFER --- streaming; watch BOOTPCT],
    [2], [READY --- staged; arm and swap],
    [`$80`], [FAILED --- see BOOTERR],
  )
  sub[FN_BOOTERR (FC08H)]
  table(columns: (auto, 1fr),
    table.header[Value][Meaning],
    [1], [too big for the bank store],
    [2], [truncated push],
    [3], [no mapping fits the size],
    [4], [the only fitting store is busy],
  )
  sub[NET_STATUS device byte]
  table(columns: (auto, 1fr),
    table.header[Value][Meaning],
    [1], [SUCCESS],
    [136], [END_OF_FILE],
    [other], [per-protocol codes (see the
      Network Protocol Handbook)],
  )
  sub[GET_WIFISTATUS reply]
  table(columns: (auto, 1fr),
    table.header[Value][Meaning],
    [3], [connected],
    [other], [not connected --- keep polling],
  )
})

// ============================================================
// APPENDIX C: PROGRAM LISTINGS
// ============================================================
#chapter[Program Listings]

#block({
  set par(first-line-indent: 0pt)
  [The programs, complete, from the `listings/` snapshots --- byte-identical
  to the source repositories at the commits in the README's sources-of-truth
  table. The shared client library (C.1) is used by NETCAT, CONFIG and the
  milestone clients; the games (C.6, C.7) reach the mailbox through the
  portable fujinet-lib instead, so only their ColecoVision-specific ports are
  printed here --- the cross-platform game core is identical across eight
  machines and lives in each game's repository. Generated art (`charset.c`,
  `udg.h`, `font.bin`) is not printed.]
})

#sect[C.1 The shared client library]
#code-listing("fujilib.h -- the mailbox client, in C", "listings/common/fujilib.h")
#code-listing("fujilib.c", "listings/common/fujilib.c")
#code-listing("fujidisp.h -- OS7 text display", "listings/common/fujidisp.h")
#code-listing("fujidisp.c", "listings/common/fujidisp.c")
#code-listing("fujiin.h -- OS7 controller input", "listings/common/fujiin.h")
#code-listing("fujiin.c", "listings/common/fujiin.c")
#code-listing("fujiedit.h -- the on-screen keyboard", "listings/common/fujiedit.h")
#code-listing("fujiedit.c", "listings/common/fujiedit.c")
#code-listing("fujisnd.h -- the SN76489, kept quiet", "listings/common/fujisnd.h")
#code-listing("fujisnd.c", "listings/common/fujisnd.c")

#sect[C.2 The Z80 assembler library]
#code-listing("fujimail.inc -- the mailbox, in assembly", "listings/asm/fujimail.inc")
#code-listing("acfg.asm -- the assembly first-contact cartridge", "listings/asm/acfg.asm")

#sect[C.3 NETCAT]
#code-listing("netlib.h -- the five N: commands", "listings/netcat/netlib.h")
#code-listing("netlib.c", "listings/netcat/netlib.c")
#code-listing("netterm.h -- the scrolling pane", "listings/netcat/netterm.h")
#code-listing("netterm.c", "listings/netcat/netterm.c")
#code-listing("netcat.c", "listings/netcat/netcat.c")
#code-listing("build.sh", "listings/netcat/build.sh")

#sect[C.4 The milestone clients]
#code-listing("hello.c -- M0: toolchain and display", "listings/config/hello.c")
#code-listing("fujitest.c -- M1: one round trip", "listings/config/fujitest.c")
#code-listing("fujiboot.c -- M2: network boot", "listings/config/fujiboot.c")

#sect[C.5 CONFIG]
#code-listing("fujicfg.c -- the browse-and-boot client", "listings/config/fujicfg.c")
#code-listing("fujisplash.h", "listings/config/fujisplash.h")
#code-listing("fujisplash.c", "listings/config/fujisplash.c")

#sect[C.6 5 CARD STUD (ColecoVision port)]
#code-listing("main.c", "listings/5cardstud/main.c")
#code-listing("misc.h -- the state-in-window macro", "listings/5cardstud/misc.h")
#code-listing("coleco/network.c", "listings/5cardstud/coleco/network.c")
#code-listing("coleco/util.c -- the lobby handoff", "listings/5cardstud/coleco/util.c")
#code-listing("coleco/vars.h", "listings/5cardstud/coleco/vars.h")
#code-listing("coleco/input.c", "listings/5cardstud/coleco/input.c")
#code-listing("coleco/osk.c", "listings/5cardstud/coleco/osk.c")
#code-listing("coleco/sound.c", "listings/5cardstud/coleco/sound.c")
#code-listing("coleco/appkey.c", "listings/5cardstud/coleco/appkey.c")
#code-listing("coleco/conbuf.asm", "listings/5cardstud/coleco/conbuf.asm")

#sect[C.7 BATTLESHIP (ColecoVision port)]
#code-listing("main.c", "listings/battleship/main.c")
#code-listing("coleco/fujinet.c -- the custom network hook", "listings/battleship/coleco/fujinet.c")
#code-listing("coleco/vars.h", "listings/battleship/coleco/vars.h")
#code-listing("coleco/graphics.c -- GRAPHICS II as a cellmap", "listings/battleship/coleco/graphics.c")
#code-listing("coleco/input.c", "listings/battleship/coleco/input.c")
#code-listing("coleco/osk.c", "listings/battleship/coleco/osk.c")
#code-listing("coleco/sound.c", "listings/battleship/coleco/sound.c")
#code-listing("coleco/util.c", "listings/battleship/coleco/util.c")

// ============================================================
// APPENDIX D: TROUBLESHOOTING
// ============================================================
#chapter[Troubleshooting]

#block({
  set par(first-line-indent: 0pt)
  [In the spirit of the Owner's Manual's troubleshooting checklist --- the
  symptoms a FujiNet program actually shows, and what each one means.]
})

#symrem(
  ([The client polls forever; `FN_ACKSEQ` never changes.],
   [The register write did not happen. In C, a mailbox "write" done as
    `(void)FN_REGSEL[reg]` is discarded by sccz80 --- store through a
    `volatile` sink (`FN_TOUCH`). Check with `zcc +coleco -O2 -a`: two loads,
    not one.]),
  ([A directory or reply reads back all zeros through the right expression.],
   [You indexed the reply window as `FN_REPLY[i]`. sccz80 mis-indexes the
    macro's cast-constant; read through a `volatile unsigned char *` local
    instead.]),
  ([`FNCOMMIT` returns carry / C returns `FN_EWAIT` (`$FF`).],
   [The cartridge never answered: no FujiNet cart, or the RP2040 never
    enumerated its ESP32. Check presence (`F`,`N` at `$FC09`/`$FC0A`) first.]),
  ([`FN_ERR` is nonzero after a commit.],
   [The cartridge answered but the transport failed: 1 no link, 2 timeout,
    3 bad frame, 4 too big. Different from a NAK --- this is below the
    FujiNet, not the FujiNet refusing.]),
  ([`FN_REPLYCMD` is `$15` (NAK).],
   [Everything carried; the FujiNet refused the command --- wrong parameters,
    a short fixed-size payload, an unmounted host, a missing file, or an
    opcode this platform does not dispatch.]),
  ([A short reply shows stale trailing bytes.],
   [The reply window is never cleared. Capture `FN_RXLEN` the instant a
    transaction acknowledges and believe only that many bytes.]),
  ([Every `SET_DIRECTORY_POSITION` NAKs for the rest of the session.],
   [You read past the end of a directory on an SD host, which hands back `..`
    forever instead of `$7F $7F`. Stop on `$7F $7F`, `.` and `..` alike, and
    never read past the end.]),
  ([The screen looks right but the program is dead / behaves randomly.],
   [Likely the vblank NMI touched the mailbox pages. The NMI cannot be masked;
    its handler must never read `$F800` or above. Keep it to bumping a counter
    and reading the VDP status port.]),
  ([The sound chip buzzes from power-on.],
   [A `$55AA` client skips the BIOS title screen that would silence the PSG.
    Call `snd_init()` first thing.]),
  ([The build warns about the code or data fence, or `checkrom.py` fails.],
   [Something reached the mailbox pages (`$F800`+). Move it below `$F800`;
    those pages must hold nothing but the `FUJI` claim.]),
)

#v(18pt)
#line(length: 100%, stroke: 0.5pt + rule-c)
#v(6pt)
#align(center, text(font: f-head, size: 8.5pt, fill: slate)[
  Every address and listing in this book is transcribed from the live FujiNet
  sources and verified against the firmware and a running adapter. #linebreak()
  When in doubt, the sources win. --- The FujiNet Project · fujinet.online])
