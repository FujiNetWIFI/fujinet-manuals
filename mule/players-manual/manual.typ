// =============================================================================
// M.U.L.E. -- The FujiNet Multiplayer Edition: Player's Guide
//
// One source, ten editions:
//   typst compile --font-path fonts --input platform=atari manual.typ out.pdf
// The text, tables and pictures for the edition come from build/<platform>.json
// (tools/expand.py, from content/*.yaml), so this file is only the house
// style: the 1983 Electronic Arts M.U.L.E. booklet (learn/MULE.pdf) -- a
// square page between red bands, Souvenir headings with red step numbers,
// a light sans body, screens in a black TV bezel, red Q: and A:.
// =============================================================================

#let plat = sys.inputs.at("platform", default: "atari")
#let ed = json("build/" + plat + ".json")

// ---- fonts and palette -------------------------------------------------------
#let f-head = "Souvenir"
#let f-body = "ITC Benguiat Gothic Std"
#let red    = rgb("#d4252c")
#let ink    = rgb("#1b1d1c")
#let deep   = rgb("#14261d")      // the booklet's near-black green titles
#let tint   = rgb("#fbeeee")
#let rule-g = rgb("#bdbdbd")
#let yellow = rgb("#f2cf1d")
#let mars   = rgb("#8f2a1c")

// ---- inline markup: **bold**, *italic* ----------------------------------------
#let md(s) = {
  if s == none or s == "" { return [] }
  let re = regex("\*\*(.+?)\*\*|\*(.+?)\*")
  let out = ()
  let pos = 0
  for m in s.matches(re) {
    out.push(s.slice(pos, m.start))
    if m.captures.at(0) != none { out.push(strong(m.captures.at(0))) }
    else { out.push(emph(m.captures.at(1))) }
    pos = m.end
  }
  out.push(s.slice(pos))
  out.join()
}

// ---- the red band (top and bottom of every page) ------------------------------
#let band = block(width: 100%, spacing: 0pt, {
  rect(width: 100%, height: 6pt, fill: red, stroke: none)
  v(1.4pt, weak: false)
  line(length: 100%, stroke: 0.5pt + ink)
})

// ---- a screen in a TV bezel -----------------------------------------------------
#let screen(path, width: 100%) = align(center, box(
  width: width, fill: black, radius: 9pt, inset: (x: 7pt, y: 7pt),
  box(radius: 3pt, clip: true, image(path, width: 100%))))

#let alt-screen(alt) = if alt != none {
  v(3pt)
  align(center, box(width: 62%, {
    screen(alt.img)
    v(1pt)
    align(center, text(font: f-head, size: 7.5pt, fill: red, weight: "bold", upper(alt.label) + " SCREEN"))
  }))
}

// ---- blocks ----------------------------------------------------------------------
#let subhead(t) = block(above: 12pt, below: 5pt, breakable: false, sticky: true,
  text(font: f-head, weight: "bold", size: 11.5pt, fill: deep, md(t)))

#let step(b) = block(breakable: false, above: 14pt, below: 8pt, {
  align(center, text(font: f-head, weight: "bold", size: 14pt, fill: deep,
    [#text(fill: red)[#b.n.] #b.title]))
  v(4pt)
  if b.img != none { screen(b.img, width: 92%) ; alt-screen(b.alt) ; v(5pt) }
  if b.lead != "" {
    block(below: 4pt, text(font: f-head, weight: "bold", size: 10pt, fill: deep, md(b.lead)))
  }
  md(b.text)
})

#let shot(b) = block(breakable: false, above: 10pt, below: 10pt, {
  screen(b.img, width: 92%)
  alt-screen(b.alt)
  if b.caption != "" {
    v(3pt)
    align(center, text(size: 8pt, style: "italic", md(b.caption)))
  }
})

#let shots(b) = block(above: 10pt, below: 10pt, {
  for i in b.imgs {
    block(breakable: false, below: 6pt, {
      screen(i.img, width: 92%)
    })
  }
  align(center, text(size: 8pt, style: "italic", md(b.caption)))
})

#let red-square = box(baseline: -1pt, rect(width: 4.5pt, height: 4.5pt, fill: red, stroke: none))

#let tips(b) = block(above: 6pt, {
  block(below: 8pt, text(font: f-head, weight: "bold", size: 15pt, fill: deep, [Tips on the Tournament Game]))
  for it in b.items {
    grid(columns: (10pt, 1fr), gutter: 0pt, red-square, md(it))
    v(4pt)
  }
})

#let qa(b) = for it in b.items {
  block(breakable: false, above: 9pt, below: 2pt, grid(columns: (19pt, 1fr), column-gutter: 3pt,
    text(font: f-head, weight: "bold", size: 15pt, fill: red, "Q:"),
    pad(top: 2pt, text(font: f-head, weight: "bold", size: 9.5pt, fill: deep, md(it.q)))))
  block(above: 0pt, below: 6pt, grid(columns: (19pt, 1fr), column-gutter: 3pt,
    text(font: f-head, weight: "bold", size: 15pt, fill: red, "A:"),
    pad(top: 3pt, md(it.a))))
}

#let note(b) = block(width: 100%, above: 8pt, below: 10pt, fill: tint, inset: 8pt,
  stroke: (left: 3pt + red), md(b.text))

#let blist(b) = {
  if b.ordered {
    enum(spacing: 5pt, tight: false, numbering: n => text(font: f-head, weight: "bold", fill: red, str(n) + "."),
      ..b.items.map(md))
  } else {
    list(spacing: 5pt, tight: false, marker: red-square, ..b.items.map(md))
  }
}

#let cell(c) = if type(c) == dictionary { image(c.img, width: 26pt) } else { md(c) }

#let tbl(b) = {
  let n = b.head.len()
  let kv = b.at("kv", default: false)
  let icon = b.at("icon", default: false)
  let w = b.at("widths", default: none)
  let cols = if w != none { w.map(x => if x == 0 { auto } else { x * 1fr }) }
    else if kv { (auto, 1fr) }
    else if icon { (30pt,) + (auto,) + range(n - 2).map(_ => 1fr) }
    else if b.at("events", default: false) { (1.6fr, 1fr) }
    else if n == 2 { (auto, 1fr) }
    else { range(n).map(i => if i == 0 { 1.4fr } else { 1fr }) }
  block(above: 6pt, below: 10pt, text(size: 8.3pt, table(
    columns: cols,
    stroke: (x, y) => if y == 0 and not kv { (bottom: 1pt + red) } else { (bottom: 0.4pt + rule-g) },
    inset: (x: 3.5pt, y: 4pt),
    align: (x, y) => if icon and x > 1 { center + horizon } else { left + horizon },
    ..if not kv { b.head.map(h => text(font: f-head, weight: "bold", fill: deep, h)) },
    ..b.rows.flatten().map(cell),
  )))
}

#let event(b) = block(breakable: false, above: 8pt, below: 6pt, {
  grid(columns: (1fr, auto),
    text(font: f-head, weight: "bold", size: 10.5pt, fill: deep, b.name),
    text(size: 7.5pt, fill: red, weight: "bold", upper("up to " + str(b.times) + " a game")))
  v(2pt)
  block(below: 3pt, text(style: "italic", "“" + b.text + "”"))
  md(b.effect)
})

#let render(b) = {
  let t = b.t
  if t == "p" { par(md(b.text)) }
  else if t == "h" { subhead(b.text) }
  else if t == "list" { blist(b) }
  else if t == "step" { step(b) }
  else if t == "shot" { shot(b) }
  else if t == "shots" { shots(b) }
  else if t == "tips" { tips(b) }
  else if t == "qa" { qa(b) }
  else if t == "note" { note(b) }
  else if t == "table" { tbl(b) }
  else if t == "event" { event(b) }
}

// ---- split the blocks into chapters ---------------------------------------------
#let chapters = {
  let out = ()
  for b in ed.blocks {
    if b.t == "chapter" { out.push((title: b.title, id: b.id, blocks: ())) }
    else { out.last().blocks.push(b) }
  }
  out
}

// ---- page setup ---------------------------------------------------------------------
#set document(title: ed.title + " " + ed.kind + " — " + ed.name,
  author: "FujiNet", keywords: ("M.U.L.E.", "FujiNet", ed.name))
#set text(font: f-body, size: 9.3pt, fill: ink, lang: "en", hyphenate: true)
#set par(leading: 0.52em, spacing: 0.75em, justify: false)
#set strong(delta: 300)
#show heading: none

#let page-w = 556pt
#let page-h = 560pt

// ---- the cover -----------------------------------------------------------------------
#page(width: page-w, height: page-h, margin: 0pt, fill: yellow, {
  place(top + left, dx: 22pt, dy: 22pt, rect(width: page-w - 44pt, height: page-h - 44pt, fill: mars, stroke: none))
  place(top + left, dx: 22pt, dy: 22pt, rect(width: page-w - 44pt, height: 205pt,
    fill: gradient.linear(black, mars, angle: 90deg), stroke: none))
  place(top + left, dx: 44pt, dy: 40pt, text(font: f-head, weight: "bold", size: 46pt, fill: white,
    tracking: 14pt, "M.U.L.E."))
  place(top + left, dx: 46pt, dy: 102pt, block(width: 250pt, text(font: f-head, size: 11.5pt, fill: white,
    [Four colonists. One planet. Twelve months. And a machine you will all learn to hate.])))
  place(top + right, dx: -40pt, dy: 44pt, align(right, text(font: f-head, weight: "bold", size: 12pt, fill: yellow,
    [The FujiNet\ Multiplayer Edition])))
  if ed.cover != none {
    place(top + center, dy: 168pt, box(width: 300pt, screen(ed.cover)))
  }
  place(bottom + left, dx: 44pt, dy: -40pt, text(font: f-head, weight: "bold", size: 20pt, fill: white, ed.kind))
  place(bottom + right, dx: -44pt, dy: -42pt, align(right, text(font: f-head, size: 11pt, fill: yellow,
    [for the #ed.long])))
})

// ---- the body pages ---------------------------------------------------------------------
#set page(width: page-w, height: page-h,
  margin: (top: 50pt, bottom: 52pt, x: 40pt),
  header: context {
    let pg = here().page()
    let starts = query(<chapter>).filter(m => m.location().page() == pg)
    if starts.len() == 0 { band }
  },
  header-ascent: 30%,
  footer: context {
    band
    v(5pt)
    align(center, text(size: 7.5pt, counter(page).display()))
  },
  footer-descent: 25%,
)
#counter(page).update(1)

// title page (the booklet's own "M.U.L.E. Player's Guide" page, with the notice)
#page(header: none, {
  v(24pt)
  align(center, text(font: f-head, weight: "bold", size: 60pt, fill: ink, tracking: 2pt, "M.U.L.E."))
  v(-26pt)
  align(center, text(font: f-head, weight: "bold", size: 20pt, fill: red, ed.kind))
  v(2pt)
  align(center, text(font: f-head, size: 11pt, fill: deep, ed.subtitle + " · " + ed.name))
  v(16pt)
  columns(2, gutter: 22pt, {
    text(font: f-head, weight: "bold", size: 11pt, fill: deep, [Contents])
    v(4pt)
    context {
      for c in query(<chapter>) {
        let pg = counter(page).at(c.location()).first()
        grid(columns: (1fr, auto), md(c.value), str(pg))
        v(2pt)
      }
    }
    colbreak()
    set text(size: 7.6pt)
    [*M.U.L.E.* was designed by Ozark Softscape (Dan Bunten, Bill Bunten, Jim Rushing and Alan Watson) and published by Electronic Arts in 1983 for the Atari 400 and 800.]
    parbreak()
    [*The FujiNet Multiplayer Edition* is a network version made by the FujiNet community. A server plays the original's Tournament Game by its original rules, and clients on ten machines show it the 1983 way. Its pictures are converted from the 1983 Atari disk and remain the property of their owners.]
    parbreak()
    [The pictures in this guide were taken from the #ed.name edition of the game. Everything in it applies to every edition: only the pictures, the controls and the way the game is loaded differ.]
    parbreak()
    [The layout of this guide is a tribute to the 1983 Electronic Arts M.U.L.E. booklet.]
    parbreak()
    [FujiNet: #link("https://fujinet.online")[fujinet.online] · Game server: irata.online]
  })
})

#for ch in chapters {
  pagebreak(weak: true)
  [#metadata(ch.title) <chapter>]
  heading(level: 1, ch.title)
  block(above: 0pt, below: 4pt, text(font: f-head, weight: "bold", size: 22pt, fill: deep, ch.title))
  band
  v(8pt)
  columns(2, gutter: 22pt, {
    for b in ch.blocks { render(b) }
  })
}

// ---- the back cover --------------------------------------------------------------------
#page(margin: 0pt, header: none, footer: none, fill: black, {
  place(center + horizon, align(center, {
    text(font: f-head, weight: "bold", size: 34pt, fill: white, tracking: 10pt, "M.U.L.E.")
    v(6pt)
    text(font: f-head, size: 12pt, fill: yellow, ed.subtitle)
    v(30pt)
    text(font: f-head, size: 10pt, fill: white, [Play it on FujiNet: #link("https://fujinet.online")[fujinet.online]])
    v(4pt)
    text(font: f-head, size: 9pt, fill: rgb("#aaaaaa"), [#ed.long edition])
  }))
})
