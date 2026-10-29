// =============================================================================
// M.U.L.E. -- The FujiNet Multiplayer Edition: Cheat Sheet
//
// One US Letter page per edition:
//   typst compile --font-path fonts --input platform=atari cheatsheet.typ out.pdf
// The text and tables come from the "sheet" key of build/<platform>.json
// (tools/expand.py, from content/cheatsheet.yaml, rules.yaml and
// platforms.yaml). The house style is manual.typ's: Souvenir headings with
// red step numbers, the Benguiat body, red bands, screens in a TV bezel.
// =============================================================================

#let plat = sys.inputs.at("platform", default: "atari")
#let ed = json("build/" + plat + ".json")
#let sh = ed.sheet

// ---- fonts and palette (as manual.typ) ------------------------------------------
#let f-head = "Souvenir"
#let f-body = "ITC Benguiat Gothic Std"
#let red    = rgb("#d4252c")
#let ink    = rgb("#1b1d1c")
#let deep   = rgb("#14261d")
#let rule-g = rgb("#bdbdbd")

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

#let band = block(width: 100%, spacing: 0pt, {
  rect(width: 100%, height: 6pt, fill: red, stroke: none)
  v(1.4pt, weak: false)
  line(length: 100%, stroke: 0.5pt + ink)
})

#let screen(path, width: 100%) = align(center, box(
  width: width, fill: black, radius: 7pt, inset: (x: 5pt, y: 5pt),
  box(radius: 2pt, clip: true, image(path, width: 100%))))

// a strip screen: every edition's screens get the same 3:2 window, so the
// strip is the same height on every sheet; other shapes are letterboxed in
// the bezel's black
#let strip-screen(path) = box(width: 100%, fill: black, radius: 7pt, inset: 5pt, layout(size =>
  box(radius: 2pt, clip: true, image(path, width: size.width, height: size.width / 1.5, fit: "contain"))))

#let red-square = box(baseline: -1pt, rect(width: 4pt, height: 4pt, fill: red, stroke: none))

// ---- blocks ----------------------------------------------------------------------
#let subhead(t) = block(above: 9pt, below: 4pt, breakable: false, sticky: true,
  text(font: f-head, weight: "bold", size: 10.5pt, fill: deep, md(t)))

#let bullets(items) = list(spacing: 3.2pt, tight: false, marker: red-square, ..items.map(md))

// icons by height: some editions' plots are taller than they are wide
#let cell(c) = if type(c) == dictionary { image(c.img, height: 12pt) } else { md(c) }

// a header cell: text, or an icon over its name
#let head-cell(h) = {
  let t(s) = text(font: f-head, weight: "bold", fill: deep, s)
  if type(h) == dictionary { stack(spacing: 2pt, align(center, image(h.img, height: 12pt)), align(center, t(h.text))) }
  else { t(h) }
}

#let tbl(b) = {
  let n = b.head.len()
  let kv = b.at("kv", default: false)
  let icon = b.at("icon", default: false)
  let w = b.at("widths", default: none)
  let cols = if w != none { w.map(x => if x == 0 { auto } else { x * 1fr }) }
    else if kv { (auto, 1fr) }
    else if icon { (17pt,) + (auto,) + range(n - 2).map(_ => 1fr) }
    else { range(n).map(i => if i == 0 { 1.6fr } else { 1fr }) }
  block(above: 4pt, below: 6pt, text(size: 7.1pt, table(
    columns: cols,
    stroke: (x, y) => if y == 0 and not kv { (bottom: 1pt + red) } else { (bottom: 0.4pt + rule-g) },
    inset: (x: 3pt, y: if icon { 1.5pt } else { 2.6pt }),
    align: (x, y) => if icon and x > 1 { center + horizon } else { left + horizon },
    ..if not kv { b.head.map(head-cell) },
    ..b.rows.flatten().map(cell),
  )))
}

// a numbered step of the month: red number, Souvenir title, then the text
#let step(s) = block(breakable: false, above: 0pt, below: 4.5pt, grid(
  columns: (13pt, 1fr), column-gutter: 2pt,
  text(font: f-head, weight: "bold", size: 10.5pt, fill: red, str(s.n) + "."),
  pad(top: 1.2pt, [#text(font: f-head, weight: "bold", size: 8.6pt, fill: deep, s.title) #h(2pt) #md(s.text)])))

// ---- page setup ---------------------------------------------------------------------
#set document(title: ed.title + " " + sh.kind + " — " + ed.name,
  author: "FujiNet", keywords: ("M.U.L.E.", "FujiNet", ed.name))
#set text(font: f-body, size: 7.5pt, fill: ink, lang: "en", hyphenate: true)
#set par(leading: 0.48em, spacing: 0.6em, justify: false)
#set strong(delta: 300)
#set page(width: 8.5in, height: 11in,
  margin: (top: 36pt, bottom: 46pt, x: 36pt),
  header: band, header-ascent: 40%,
  footer: {
    band
    v(4pt)
    grid(columns: (1fr, auto),
      text(font: f-head, size: 7.5pt, fill: deep, [*M.U.L.E.* · #ed.subtitle · #ed.name]),
      text(font: f-head, size: 7.5pt, fill: deep, [#link("https://fujinet.online")[fujinet.online] · irata.online]))
    v(1pt)
    text(size: 5.8pt, fill: rgb("#555555"),
      [M.U.L.E. was designed by Ozark Softscape and published by Electronic Arts in 1983. Its pictures are converted from the 1983 Atari disk and remain the property of their owners.])
  },
  footer-descent: 20%,
)

// ---- the title ------------------------------------------------------------------------
#grid(columns: (auto, 1fr, auto), column-gutter: 12pt, align: bottom,
  text(font: f-head, weight: "bold", size: 40pt, fill: ink, tracking: 2pt, "M.U.L.E."),
  pad(bottom: 5pt, {
    text(font: f-head, weight: "bold", size: 18pt, fill: red, sh.kind)
    linebreak()
    text(font: f-head, size: 9pt, fill: deep, ed.subtitle)
  }),
  pad(bottom: 5pt, align(right, {
    text(font: f-head, weight: "bold", size: 13pt, fill: deep, ed.name)
    linebreak()
    text(size: 7.5pt, ed.long)
  })))
#v(3pt)
#band
#v(8pt)

// ---- the screen strip -------------------------------------------------------------------
#grid(columns: (1fr,) * sh.strip.len(), column-gutter: 10pt, ..sh.strip.map(s => {
  strip-screen(s.img)
  v(1pt)
  align(center, text(font: f-head, weight: "bold", size: 8.5pt, fill: deep,
    [#text(fill: red)[#s.n.] #s.label]))
}))
#v(4pt)

// ---- the two columns ---------------------------------------------------------------------
#columns(2, gutter: 18pt, {
  subhead("Controls")
  md(sh.controls_note)
  tbl(sh.controls)

  subhead("Getting In")
  bullets(sh.getting_in)

  subhead("A Month on Irata")
  for s in sh.month { step(s) }

  subhead("On Your Turn")
  tbl(sh.town)

  subhead("Watch Out")
  bullets(sh.watch)

  subhead("The Land")
  tbl(sh.land)

  subhead("The Store")
  tbl(sh.store)

  subhead("Bonuses")
  bullets(sh.bonuses)

  subhead("Month by Month")
  tbl(sh.months)

  subhead("The Colonists")
  md(sh.colonists)

  subhead("Winning")
  md(sh.scoring)
  parbreak()
  md(sh.rating)

  subhead("Tips from the Old Hands")
  bullets(sh.tips)
})
