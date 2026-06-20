// ============================================================
// FUJINET COLOR COMPUTER — GETTING STARTED MANUAL
//
// Designed after the 1980 Radio Shack "TRS-80 Color Computer
// Operation Manual" (26-3001/3002): landscape booklet, Century
// Schoolbook text, double-rule chapter heads with the green
// center ornament, pale-yellow caution boxes, green gradient
// end bars, black-pill keycaps, Symptom/Cure tables, and the
// starfield cover set in Souvenir.
//
// Hardware facts verified against fujinet-hardware
// Coco/CoCo-FujiNet-Rev000 (schematic, STLs, README); CONFIG
// screens are typeset in the genuine MC6847 character set
// (Hot CoCo, Kreative Korp) with text taken verbatim from
// fujinet-config src/coco/screen.c.  Incorporates material from
// Rich Stephens' "FujiNet For CoCo: The Basics."
//
// Build: typst compile --font-path fonts manual.typ
// ============================================================

// ---------- photographs -------------------------------------
// Thom's photos. Flip an entry to true once the file exists in
// images/ — placeholders render until then. See FIGURES.md.
#let photos = (
  "insert-cartridge.jpg": true,
  "serial-plug.jpg": true,
  "full-setup.jpg": false,
  "microsd-insert.jpg": false,
)

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

#let phimg(file, desc, height: 2.2in) = {
  if photos.at(file, default: false) {
    align(center, image("images/" + file, height: height))
  } else {
    rect(width: 100%, height: height, fill: rgb("#f1efe6"),
      stroke: (paint: rule-c, thickness: 0.7pt, dash: "dashed"),
      align(center + horizon, par(justify: false, leading: 0.6em,
        text(font: f-body, size: 8pt, fill: rule-c,
          "[ PHOTO: " + file + " ]\n") +
        text(font: f-body, size: 8pt, style: "italic", fill: rule-c, desc))))
  }
}

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
// DOCUMENT SETUP
// ============================================================
#set document(title: "FujiNet Color Computer Getting Started Manual",
  author: "The FujiNet Community")
#set text(font: f-body, size: 9.3pt, fill: ink, hyphenate: true)
#set par(leading: 0.5em, spacing: 0.65em, justify: true, first-line-indent: 0pt)
#set strong(delta: 300)
#set page(width: 10in, height: 8in, fill: paper,
  margin: (x: 0.72in, top: 0.55in, bottom: 0.62in),
  footer: foot, footer-descent: 38%)
#set enum(numbering: "1.", indent: 0pt, body-indent: 7pt, spacing: 0.7em)
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
    text(font: f-sans, size: 9pt, fill: cvr-blu)[Catalog No. FN-COCO-REV000])

  #place(top + left, dx: 0.85in, dy: 0.95in, {
    set par(leading: 0.35em, spacing: 0.5em)
    text(font: f-cover, weight: 700, size: 38pt, fill: cvr-blu)[FUJINET#h(2pt)#text(size: 14pt, baseline: -14pt)[®]]
    v(0.22in)
    text(font: f-cover, weight: 700, size: 46pt, fill: cvr-mag)[COLOR]
    v(0.1in)
    text(font: f-cover, weight: 700, size: 46pt, fill: cvr-mag)[COMPUTER]
    v(0.24in)
    text(font: f-cover, weight: 700, size: 31pt, fill: cvr-blu)[GETTING]
    v(0.08in)
    text(font: f-cover, weight: 700, size: 31pt, fill: cvr-blu)[STARTED]
    v(0.08in)
    text(font: f-cover, weight: 700, size: 31pt, fill: cvr-blu)[MANUAL]
  })

  #place(top + right, dx: -0.5in, dy: 2.3in,
    image("images/cocofuji-hero.png", width: 4.15in))

  #place(bottom + center, dy: -0.55in,
    text(font: f-sans, size: 8pt, fill: cvr-blu, tracking: 0.6pt)[
      CUSTOM CRAFTED BY THE FUJINET COMMUNITY
      #h(4pt)#box(image("images/fujinet-logo.png", height: 11pt), baseline: 2.5pt)#h(4pt)
      A WORLDWIDE FREE-SOFTWARE PROJECT])
]

// ============================================================
// TITLE PAGE  (the outline-letter page)
// ============================================================
#counter(page).update(1)
#page(footer: none)[
  #v(1.1in)
  #align(center, {
    set par(leading: 0.4em)
    text(font: f-cover, weight: 700, size: 30pt,
      fill: paper, stroke: 0.6pt + rgb("#8a8578"))[FUJINET#h(2pt)#text(size: 12pt, baseline: -10pt)[®]]
    v(0.32in)
    text(font: f-cover, weight: 700, size: 36pt,
      fill: rgb("#f3eecb"), stroke: 0.7pt + rgb("#8a8578"))[COLOR COMPUTER]
    v(0.32in)
    text(font: f-cover, weight: 700, size: 30pt,
      fill: paper, stroke: 0.6pt + rgb("#8a8578"))[GETTING STARTED]
    v(0.32in)
    text(font: f-cover, weight: 700, size: 30pt,
      fill: paper, stroke: 0.6pt + rgb("#8a8578"))[MANUAL]
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
  ybox(title: [THE COMMUNITY WANTS YOU TO KNOW...])[This equipment has been
  certified to comply with the limits of pure fun, pursuant to a worldwide
  community of Color Computer owners who wanted their machines on the
  network. Everything in this manual — the device, its firmware, the CONFIG
  program, and the manual itself — is free software. Sources for all of it
  live at github.com/FujiNetWIFI.]))

#v(0.45in)
#grid(columns: (1fr, 1fr), column-gutter: 0.4in,
  {
    set text(size: 8.4pt)
    par[#emph[FujiNet Color Computer Getting Started Manual:] Copyright 2026
    the FujiNet contributors, released under the GNU General Public License
    v3 as part of the #text(font: f-sans, size: 7.6pt)[fujinet-manuals]
    repository. Reproduction and use of this manual is encouraged — copy it
    for a friend.]
    v(4pt)
    par[This manual is typeset in loving tribute to the 1980 #emph[TRS-80
    Color Computer Operation Manual] (Catalog No. 26-3001/3002). TRS-80,
    Color Computer, and Program Pak are trademarks of their respective
    owners. FujiNet is a community project and is not affiliated with,
    endorsed by, or sponsored by Tandy Corporation or its successors.]
  },
  {
    set text(size: 8.4pt)
    par[#strong[FujiNet firmware and CONFIG:] Copyright the FujiNet
    contributors, released under the GNU General Public License v3. The
    television screens pictured in this manual are typeset in the genuine
    MC6847 character set, with text taken verbatim from the CONFIG source
    code.]
    v(4pt)
    par[Incorporating material from #emph[FujiNet For CoCo: The Basics] by
    Rich Stephens, with thanks. Hardware by the FujiNet hardware
    contributors; the CoCoFuji cartridge design is open hardware.]
  })
#v(0.25in)
#align(center, text(size: 8.4pt)[10 9 8 7 6 5 4 3 2 1])

// ============================================================
// TO OUR CUSTOMERS
// ============================================================
#chapter("To Our Customers", toc: true, subs: ())

#cols2[
Your FujiNet is an exciting tool for an infinite variety of uses with your
TRS-80#h(1pt)#super[®] Color Computer — loading software in an instant,
storing a whole library on a fingernail-sized card, reading the news,
checking the weather, calling bulletin boards, and playing games against
real people on the other side of the world. Twenty years ago — make that
forty — this capability would have required a room full of equipment and a
telephone bill you don't want to think about.

In spite of its power, the FujiNet is quite simple to operate. In fact,
#emph[you] can determine exactly how "technical" a device you want it to
be.

#strong[At the simplest level of operation,] you plug the FujiNet into
your Color Computer, turn the Computer on, and pick programs off a menu
with the arrow keys. The built-in CONFIG program takes care of everything
else. For this kind of use, this book has all the information you need to
get started.

#colbreak()

#strong[At a slightly more involved level,] you may want to keep your own
disk library on a microSD card, make new blank disks out of thin air, and
copy software from the network into your own collection. Chapters 5 and 6
show you how.

#strong[If, however, you already know] your way around a disk-equipped
CoCo, you will feel right at home: the FujiNet speaks ordinary HDB-DOS,
and #tt("DIR"), #tt("LOAD"), and #tt("RUN") work exactly the way you
remember. Browse the quick reference in the back and get right down to
business.

The FujiNet has many features not found in any disk drive. A few minutes
spent with this manual before pressing #key("ENTER") could save you hours
later.

#v(6pt)
#gbar
]

// ============================================================
// IMPORTANT INFORMATION
// ============================================================
#pagebreak(weak: true)
#v(0.5in)
#align(center, box(width: 6.4in, {
  set par(justify: true)
  set align(left)
  align(center, text(font: f-head, weight: 700, size: 14pt)[Important Information])
  v(10pt)
  par[This manual describes the #strong[CoCoFuji Rev000] cartridge — the
  FujiNet model currently in production for the Color Computer family —
  running FujiNet firmware 1.5 with its matching CONFIG program. FujiNet
  is a living project: firmware updates arrive regularly, and a screen or
  menu may differ in detail from what is pictured here. When in doubt, the
  device in front of you is right and the book is behind the times.]
  v(6pt)
  par[If something in this manual does not match your device, or you get
  stuck in a way the #emph[Troubleshooting and Maintenance] chapter does
  not cure, help is close at hand:]
  v(6pt)
  bl[The FujiNet web site: #strong[fujinet.online] — downloads,
  documentation, and the firmware flasher]
  bl[The FujiNet Discord chat server — the link is at fujinet.online; the
  community is friendly and quick]
  bl[The FujiNet Users Group on Facebook]
  bl[Source code and issue trackers: #strong[github.com/FujiNetWIFI]]
  v(6pt)
  par[You may find the following booklet, prepared by your fellow
  enthusiasts, helpful: #emph[How to Identify and Resolve WiFi Problems on
  Computers Built Before WiFi.] (We're kidding. That's this booklet.)]
}))

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

#align(center, box(width: 6.3in, context {
  let marks = query(metadata).filter(m =>
    type(m.value) == dictionary and m.value.at("kind", default: "") == "chapter")
  for m in marks {
    let p = counter(page).at(m.location()).first()
    block(above: 0.85em, below: 0.2em, {
      text(font: f-head, weight: 700, size: 10.5pt, m.value.title)
      dots
      text(font: f-head, weight: 700, size: 10.5pt, str(p))
    })
    if m.value.subs.len() > 0 {
      block(above: 0pt, below: 0.3em, inset: (left: 0.25in, right: 0.3in),
        par(leading: 0.55em, justify: false,
          text(size: 9pt, m.value.subs.join(h(5pt) + sq + h(5pt)))))
    }
  }
}))

// ============================================================
// WELCOME TO FUJINET!
// ============================================================
#chapter("Welcome to FujiNet!", subs: ("What It Does", "The CONFIG Program",
  "HDB-DOS", "A Tour of the Cartridge"))
#ix("FujiNet, described", "CoCoFuji")

#cols2[
The FujiNet for the Color Computer — the #strong[CoCoFuji] — is a Program
Pak#h(1pt)#super[TM]-style cartridge that connects your Computer to your
household WiFi network, and spends its life pretending to be something
much humbler: a stack of disk drives.

The FujiNet system consists of:

#bl[A #strong[cartridge] that plugs into your Computer's cartridge slot,
containing the FujiNet itself — a complete computer of its own — plus the
HDB-DOS disk ROM your CoCo boots from]
#bl[A built-in #strong[serial cable] that carries disk and network data to
the Serial I/O jack on the back of your Computer]
#bl[#strong[Four virtual disk drives] (drives 0 through 3), each holding a
disk image loaded from the network or from a microSD card]
#bl[A #strong[WiFi radio] for your household network — no telephone
dialer, no monthly fee]
#bl[A #strong[microSD card slot], so your whole disk library can live
inside the cartridge]
#bl[A #strong[real-time clock], a #strong[printer port] of sorts, and a
direct network channel for programs written to use them]

#fig("1", [The CoCoFuji and its serial cable.],
  align(center, image("images/cocofuji-hero.png", width: 87%)))

#sect[What It Does]
#ix("Disk images")

Instead of physical floppy disks, the FujiNet uses #strong[disk images] —
exact, byte-for-byte copies of disks, stored as files. Disk images can sit
on the microSD card in the cartridge, on a file server on your own
network, or on a public library across the internet. Your Color Computer
can't tell the difference, and doesn't need to: as far as it knows, a real
drive answered the call.

#sect[The CONFIG Program]
#ix("CONFIG program")

When you power up, the FujiNet hands your Computer a friendly menu
program called #strong[CONFIG]. CONFIG is your control panel: it joins
your WiFi network, browses disk libraries, loads disk images into drives,
and gets out of the way. Chapters 4 and 5 give you the tour.

#sect[HDB-DOS]
#ix("HDB-DOS")

The cartridge carries #strong[HDB-DOS], a faithful extension of Tandy's
Disk Extended Color BASIC. Everything you (or your books and magazines)
know about disk BASIC still works: #tt("DIR"), #tt("LOAD"), #tt("RUN"),
#tt("SAVE"), and friends. Chapter 6 covers the few pleasant differences.

#v(4pt)
#gbar
]

// --------------------------------------------------------------
#pagebreak(weak: true)
#sect[A Tour of the Cartridge]
#ix("Lamps (LED indicators)", "Buttons", "Switches, model select")

#grid(columns: (1.45fr, 1fr), column-gutter: 0.35in,
  {
    fig("2", [Cartridge top: lamps, model switches, and markings.],
      align(center, image("images/cocofuji-top.png", height: 4.05in)))
  },
  {
    par[Take a minute to get acquainted before you plug anything in. With
    the cartridge held label-up, connector to the left:]
    v(2pt)
    bl[#strong[WiFi lamp (white)] — next to the #strong[A] marking. It
    glows steadily once the FujiNet has joined your network.]
    bl[#strong[Activity lamp (orange)] — next to the #strong[#rsym] marking.
    It flickers when your Computer talks to the FujiNet, just like the
    busy lamp on a disk drive.]
    bl[#strong[Model switches] — the small red switch block, visible
    through its window. These tell the FujiNet which Color Computer model
    it lives in (next chapter).]
    bl[#strong[Button A] — the button on the outer edge nearest the
    #strong[A] marking (closest to the front when installed). It is used
    when updating firmware.]
    bl[#strong[Reset button (#rsym)] — the button at the other end of the
    outer edge. Pressing it restarts the FujiNet itself — not your
    Computer.]
    bl[#strong[Micro-USB jack and microSD slot] — center of the outer
    edge. USB is for firmware updates and (optionally) power; the slot
    takes a microSD card, label up — push to seat it, push again to
    release it.]
  })

// ============================================================
// INSTALLATION
// ============================================================
#chapter("Installation", subs: ("What You'll Need", "Setting the Model Switches",
  "Connecting the FujiNet", "First Power-Up"))
#ix("Installation")

#cols2[
Carefully unpack your FujiNet. Save the packing material in case you ever
need to transport it. This chapter takes you from the box to the first
glowing screen. Take your time and follow each step — it's easier than it
looks.

#sect[What You'll Need]

#bl[Your FujiNet cartridge, with its attached serial cable]
#bl[A TRS-80 Color Computer — model 1, 2, or 3 — or a Dragon 32/64, with
its television or monitor]
#bl[A 2.4 GHz WiFi network, and its password]
#bl[Optionally, a #strong[microSD card] for your own disk library]

#ybox(title: [NOTE])[A microSD card of 64 GB or less, formatted FAT32,
from a reliable brand, is recommended. In reality 8 to 32 GB is more disk
space than every CoCo program ever written. On most computers: insert the
card, choose Format, choose FAT32, proceed.]
#ix("microSD card")

#sect[Setting the Model Switches]
#ix("Model switches (DIP)", "Baud rate")

The cartridge top has a small window with two numbered slide switches.
They select the HDB-DOS ROM — and the serial speed — that matches your
machine. Set them #emph[before] you plug in, using a toothpick or a bent
paper clip:

#block(breakable: false, align(center, table(columns: (auto, auto, auto), align: (left, center, center),
  stroke: 0.6pt + ink, inset: 5.5pt,
  table.header(
    text(font: f-head, weight: 700, size: 9.5pt)[Your Computer],
    text(font: f-head, weight: 700, size: 9.5pt)[Switch 1],
    text(font: f-head, weight: 700, size: 9.5pt)[Switch 2]),
  [Color Computer 1], [ON], [ON],
  [Color Computer 2], [OFF], [ON],
  [Color Computer 3], [ON], [OFF],
  [Dragon 32/64], [OFF], [OFF])))

Your FujiNet most likely arrived already set. If the seller knew your
model, leave the switches alone.

#colbreak()

#sect[Connecting the FujiNet]
#ix("Connecting the FujiNet", "Serial I/O jack", "Cartridge slot")

#ybox[The Computer must always be turned OFF whenever the FujiNet is
plugged in or removed. WARNING! Do not insert fingers or other objects
into the cartridge slot. Doing so could damage your Computer.]

+ Turn off your Color Computer.
+ If you have a microSD card, insert it into the FujiNet's card slot now —
  label up, push gently until it clicks.
+ Locate the cartridge slot on the right side of the Computer. Carefully
  insert the FujiNet with the label side up and the connector facing into
  the slot. It should slide smoothly into the recessed receptacle. If it
  resists, it may be upside down — it only goes in one way.
+ Plug the round 4-pin DIN plug on the FujiNet's cable into the jack
  marked #strong[SERIAL I/O] on the back of the Computer. The plug only
  fits one way: rotate it gently until the pins line up, then press it
  home.
+ That's the whole installation. There is no power supply to connect —
  the FujiNet draws its power from the cartridge slot.

#fig("3", [The FujiNet seated in the cartridge slot — label up.],
  phimg("insert-cartridge.jpg",
    "the CocoFuji halfway into the CoCo's cartridge slot, label up",
    height: 1.85in))

#fig("4", [The serial plug in the SERIAL I/O jack — mind the
look-alike CASS jack next door.],
  phimg("serial-plug.jpg",
    "hand seating the DIN-4 plug into the SERIAL I/O jack on the rear panel",
    height: 1.85in))
#sect[First Power-Up]
#ix("Power-on", "LOADING screen")

Turn on your television (or monitor), then turn on the Computer. Three
things happen, in quick succession:

+ The familiar green BASIC screen appears for a moment, announcing
  Extended Color BASIC and #strong[HDB-DOS]:

#tv(
  vrow(N("DISK EXTENDED COLOR BASIC 1.1" + rp(" ", 3))),
  vrow(N("COPYRIGHT (C) 1982 BY TANDY" + rp(" ", 5))),
  vrow(N("UNDER LICENSE FROM MICROSOFT" + rp(" ", 4))),
  vrow(N("HDB-DOS 1.5 DW3 COCO 2" + rp(" ", 10))),
  vrow(N("OK" + rp(" ", 30))),
  vrow(FB(1, vg.k), N(rp(" ", 31))),
  ..range(10).map(_ => vrow(N(rp(" ", 32))))
)
#figcap("5", [The power-up message. Wording varies with your model and
switch setting.])

2. The FujiNet splash screen appears while CONFIG comes over the serial
  cable:

// the genuine splash bitmap, extracted from cfgload's fujinet_bitmap[]
// (PMODE 4, 256x192 — regenerate with tools/make_loading.py)
#align(center, block(breakable: false, above: 1.1em, below: 0.7em,
  box(fill: vg.k, inset: (x: 0.3in, y: 0.22in), radius: 3pt,
    image("images/loading-splash.png", width: 32 * CW))))
#figcap("6", [CONFIG on its way over the serial cable. On a television
set, the sharp edges bloom with color fringes — that's normal.])

3. A few seconds later the CONFIG program appears — on the very first
  power-up, it begins by scanning for WiFi networks (next chapter).

#sect[If the Message Does Not Appear]

A. Make sure the television is turned on and tuned to the Computer
(channel 3 or 4, antenna switch to COMPUTER — see your Operation Manual).

B. Check that the FujiNet is firmly seated in the cartridge slot, and the
serial plug is firmly seated in the #strong[SERIAL I/O] jack.

C. Make sure your microSD card, if any, is properly inserted.

D. If the BASIC screen appears but CONFIG never loads, check the model
switches against the table on the previous page — a wrong setting makes
the FujiNet talk at the wrong speed.

E. Turn off the entire system, recheck all connections, and try again.
For further assistance, see #strong[Troubleshooting and Maintenance].

#ybox[Do not insert or remove the FujiNet, its serial plug, or the
microSD card while the Computer is in use — to do so could cause abnormal
operation, or damage.]

#block(breakable: false, {
  sect[Where Things Stand]
  par[From now on, every time you switch on your Computer, the FujiNet
  boots CONFIG. When you leave CONFIG (Chapter 5), your Computer restarts
  into plain HDB-DOS BASIC with your chosen disks loaded — exactly like a
  CoCo with a well-stocked multi-drive system. Pressing the Computer's
  RESET button brings back BASIC; typing #tt("DOS") #key("ENTER") at the
  #tt("OK") prompt brings back CONFIG.]
  ix("DOS command", "RESET button (Computer)")
})

#v(4pt)
#gbar
]

// ============================================================
// JOINING YOUR NETWORK
// ============================================================
#chapter("Joining Your Network", subs: ("Choosing a Network",
  "Entering the Password", "The Configuration Screen"))
#ix("WiFi setup", "Networks, scanning for")

#cols2[
The first time your FujiNet wakes up, its first order of business is
introductions: it scans the airwaves and lists every WiFi network it can
hear, strongest first.

#sect[Choosing a Network]

#tv(
  vrow(N(rp(" ", 14) + "WELCOME TO FUJINET")),
  vrow(N(rp(" ", 11) + "MAC:D0:1C:ED:C0:FF:EE")),
  vrow(I("HOMEBASE" + rp(" ", 20) + "*** ")),
  vrow(N("COCO-NUT" + rp(" ", 20) + "**  ")),
  vrow(N("RAINBOW-GUEST" + rp(" ", 15) + "*   ")),
  SH(vg.c),
  ..range(8).map(_ => FR(vg.c)),
  vrow(N(rp(" ", 5)), I("UP"), N("/"), I("DOWN"), N(" SELECT "), I("S"), N(" SKIP" + rp(" ", 6))),
  vrow(I("H"), N("IDDEN SSID "), I("R"), N("ESCAN "), I("ENTER"), N(" SELECT ")))
#figcap("7", [The network list. Stars show signal strength — three is
excellent, one means "move closer."])

The bright bar marks your place. In CONFIG, menu keys are shown in
#emph[reverse video] — where the screen shows a bright letter, that's the
key to press.

#bl[#key-up #key-down — move the bar through the list]
#bl[#key("ENTER") — join the highlighted network]
#bl[#key("H") — type the name of a hidden network]
#bl[#key("R") — rescan the airwaves]
#bl[#key("S") — skip WiFi setup entirely (you can return later)]

#colbreak()

#sect[Entering the Password]
#ix("Password, network")

Pick your network and CONFIG asks for the password. Type it carefully —
capitals count. Like on a big computer, what you type starts out
lowercase; hold #key("SHIFT") for capitals. The screen echoes a #tt("*")
for each character (up to 64), and the left arrow key #key-left erases a
mistake:

#tv(
  vrow(N(rp(" ", 14) + "WELCOME TO FUJINET")),
  vrow(N(rp(" ", 11) + "MAC:D0:1C:ED:C0:FF:EE")),
  vrow(I("HOMEBASE" + rp(" ", 20) + "*** ")),
  vrow(N("COCO-NUT" + rp(" ", 20) + "**  ")),
  vrow(N("RAINBOW-GUEST" + rp(" ", 15) + "*   ")),
  SH(vg.c),
  ..range(8).map(_ => FR(vg.c)),
  vrow(N("ENTER NET PASSWORD, PRESS "), I("ENTER"), N(".")),
  vrow(N("************"), FB(1, vg.b), N(rp(" ", 19))))
#figcap("8", [Passwords echo as asterisks. The blue block is the
cursor.])

Press #key("ENTER") and the FujiNet joins up. The white WiFi lamp comes
on, and you land on the Host Slots screen — Chapter 5.

The network and password are remembered inside the FujiNet (and, if a
microSD card is present, in a file called #tt("FNCONFIG.INI") on the
card). From now on it reconnects all by itself, every time, before the
television warms up.
#ix("FNCONFIG.INI file")

#ybox(title: [NOTE])[The FujiNet's radio speaks 2.4 GHz WiFi only. If
your router runs one network name across both 2.4 and 5 GHz bands and the
FujiNet has trouble joining, give the 2.4 GHz band its own name in your
router's settings.]
#sect[The Configuration Screen]
#ix("Configuration screen", "IP address")

Any time you want the FujiNet's vital signs, press #key("C") from the
Host Slots or Drive Slots screen (Chapter 5):

#tv(
  vrow(N("     FUJINET CONFIGURATION      ")),
  vrow(I(rp(" ", 27) + "SSID:")),
  vrow(N(rp(" ", 24) + "HOMEBASE")),
  vrow(I(rp(" ", 23) + "HOSTNAME:")),
  vrow(N(rp(" ", 25) + "FUJINET")),
  vrow(N("      IP: 192.168.1.73" + rp(" ", 10))),
  vrow(N(" NETMASK: 255.255.255.0" + rp(" ", 9))),
  vrow(N("     DNS: 192.168.1.1" + rp(" ", 11))),
  vrow(N("     MAC: D0:1C:ED:C0:FF:EE" + rp(" ", 5))),
  vrow(N("   BSSID: A4:2B:8C:11:0D:E5" + rp(" ", 5))),
  vrow(N("   FNVER: V1.5.2" + rp(" ", 16))),
  FR(vg.m),
  SH(vg.m),
  vrow(N(" "), I("C"), N("HANGE SSID" + rp(" ", 10)), I("R"), N("ECONNECT ")),
  vrow(N("OR  ANY KEY  TO RETURN TO HOSTS ")),
  SH(vg.m))
#figcap("9", [The Configuration screen: your network name, the FujiNet's
address on your network, and the firmware version.])

#bl[#key("C") — change to a different WiFi network (back to the scan
screen)]
#bl[#key("R") — reconnect to the current network]
#bl[Any other key — return to the Host Slots screen]

#colbreak()

#sect[The Web Control Panel]
#ix("Web control panel")

Note the #strong[IP] line — that is your FujiNet's address on your own
network. While the Computer is on, the FujiNet serves a full settings
page to any web browser in the house. From a modern computer or phone,
visit:

#align(center, tt("HTTP://192.168.1.73"))

(your address will differ — read it off the Configuration screen). From
that comfortable chair you can rename the device, manage WiFi, choose
printer emulations, adjust options, and update firmware.

#sect[A Word About the Clock]
#ix("Clock, real-time")

Once it is on the network, the FujiNet quietly keeps the real date and
time, fetched from the internet. Software written for the FujiNet — and
OS-9 users with the right driver — can read it any time. Your CoCo
finally knows what day it is.

#v(4pt)
#gbar
]

// ============================================================
// THE CONFIG PROGRAM
// ============================================================
#chapter("The CONFIG Program", subs: ("Host Slots and Drive Slots",
  "Browsing a Host", "Loading a Disk", "The Drive Slots Screen",
  "Leaving CONFIG", "New Disks and Copies", "The Game Lobby"))
#ix("Host slots", "CONFIG program")

#cols2[
Here is the heart of the matter. CONFIG manages two short lists, and once
you can read them, you can do everything.

A #strong[host] is any place disk images live: a public library on the
internet, a file server on your own network, or the microSD card in the
cartridge (which always goes by the name #tt("SD")). The FujiNet
remembers eight of them — the #strong[host slots].

A #strong[drive slot] is one of the four disk drives your Computer sees —
drives 0 through 3, just as in Disk BASIC. Loading a disk image into a
drive slot is the FujiNet's version of sliding a floppy into a drive.

#sect[The Host Slots Screen]

#tv(
  vrow(FB(22, vg.b), I("HOST"), N(" "), I("SLOTS")),
  vrow(I("1SD" + rp(" ", 29))),
  vrow(I("2"), N("APPS.IRATA.ONLINE" + rp(" ", 14))),
  vrow(I("3"), N("TNFS.FUJINET.ONLINE" + rp(" ", 12))),
  vrow(I("4"), N("FUJINET.PL" + rp(" ", 21))),
  vrow(I("5"), N(rp(" ", 31))),
  vrow(I("6"), N(rp(" ", 31))),
  vrow(I("7"), N(rp(" ", 31))),
  vrow(I("8"), N(rp(" ", 31))),
  SH(vg.b),
  ..range(3).map(_ => FR(vg.b)),
  vrow(N("1-8 "), I("SLOT"), N(" E"), I("DIT"), N(" ENTER "), I("BROWSE"), N(" L"), I("OBBY")),
  vrow(N("  C"), I("ONFIG"), N("  -> "), I("DRIVES"), N("  BREAK "), I("QUIT"), N(" ")),
  SH(vg.b))
#figcap("10", [The Host Slots screen. Slot 1 is the microSD card; the
others hold network libraries.])

Out of the box, slot 1 is #tt("SD") and slot 2 is a public library. The
keys:

#bl[#key-up #key-down — move the bar; #key("1")–#key("8") jumps straight
to a slot]
#bl[#key("E") — edit the highlighted slot: type a host name (up to 32
characters) and press #key("ENTER")]
#bl[#key("ENTER") — open the highlighted host and browse it]
#bl[#key-right — switch to the Drive Slots screen]
#bl[#key("C") — the Configuration screen (Chapter 4)]
#bl[#key("L") — the Game Lobby (end of this chapter)]
#bl[#key("BREAK") — leave CONFIG and start computing]

#colbreak()

Fill your empty slots with libraries worth visiting. Type names in upper
or lower case — they're the same to a server:

#bl[#tt("TNFS.FUJINET.ONLINE") — the community's main library; CoCo
software lives in the #tt("COCO") folder]
#bl[#tt("APPS.IRATA.ONLINE") — applications and on-line services]
#bl[#tt("FUJINET.PL") — a well-stocked European mirror]

#ybox(title: [NOTE])[These libraries are #strong[TNFS] file servers — a
simple file-sharing protocol beloved of 8-bit machines. A current list of
public servers is kept at fujinet.online/tnfs-server-status. You can also
run a free TNFS server on a modern computer in your own home and serve
your collection across the room — see the FujiNet wiki.]
#ix("TNFS servers")

#sect[Browsing a Host]
#ix("Browsing disk images", "Filter, directory")

Highlight a host, press #key("ENTER"), and CONFIG opens its catalog.
Entries ending in #tt("/") are folders:

#tv(
  vrow(N("TNFS.FUJINET.ONLINE" + rp(" ", 13))),
  vrow(N("/" + rp(" ", 31))),
  SH(vg.o),
  vrow(I("ADAM/" + rp(" ", 27))),
  vrow(N("APPLE2/" + rp(" ", 25))),
  vrow(N("ATARI/" + rp(" ", 26))),
  vrow(N("CBM/" + rp(" ", 28))),
  vrow(N("COCO/" + rp(" ", 27))),
  vrow(N("LINKS/" + rp(" ", 26))),
  SH(vg.o),
  ..range(4).map(_ => FR(vg.o)),
  vrow(I(vleft), N(" ../ "), I("UP"), N("/"), I("DN"), N(" MOVE "), I(vup + "UP"), N("/"), I(vup + "DN"), N(" PAGE" + rp(" ", 3))),
  vrow(I("ENTER"), N(" OR "), I("BREAK"), N(" "), I("F"), N("ILTER "), I("N"), N("EW "), I("C"), N("OPY  ")))
#figcap("11", [Browsing a library. The host's name and your place in its
folders are shown at the top.])

#bl[#key-up #key-down — move the bar. At the top or bottom of a full
screen, keep going — the next ten entries page in. Hold #key("SHIFT")
with #key-up or #key-down to leap a whole page.]
#bl[#key("ENTER") — open the highlighted folder, or choose the
highlighted disk image]
#bl[#key-left — back out to the enclosing folder]
#bl[#key("F") — type a filter, like #tt("W*.*"), to show only matching
entries; #tt("!") followed by text hunts through every folder beneath
you. Enter an empty filter to clear it.]
#bl[#key("BREAK") — back to the Host Slots screen]
A long file name scrolls back and forth by itself if you let the bar rest
on it for a few seconds. Folders with more than one screenful show
#tt("[...]") at the edge of the list.

#sect[Loading a Disk]
#ix("Mounting a disk image", "Read-only and read/write")

Step into the #tt("COCO") folder, put the bar on something promising, and
press #key("ENTER"):

#tv(
  vrow(N("TNFS.FUJINET.ONLINE" + rp(" ", 13))),
  vrow(N("/COCO/" + rp(" ", 26))),
  SH(vg.o),
  vrow(N("LOBBY.DSK" + rp(" ", 23))),
  vrow(N("NETCAT.DSK" + rp(" ", 22))),
  vrow(I("NEWS.DSK" + rp(" ", 24))),
  vrow(N("WEATHER.DSK" + rp(" ", 21))),
  vrow(N("WIKI.DSK" + rp(" ", 24))),
  SH(vg.o),
  ..range(5).map(_ => FR(vg.o)),
  vrow(I(vleft), N(" ../ "), I("UP"), N("/"), I("DN"), N(" MOVE "), I(vup + "UP"), N("/"), I(vup + "DN"), N(" PAGE" + rp(" ", 3))),
  vrow(I("ENTER"), N(" OR "), I("BREAK"), N(" "), I("F"), N("ILTER "), I("N"), N("EW "), I("C"), N("OPY  ")))
#figcap("12", [The community's CoCo shelf — programs written for the
FujiNet (Chapter 7).])

CONFIG asks which drive slot the disk should go in, and shows the file's
details while you decide:

#tv(
  vrow(I(rp(" ", 11) + "PLACE IN DEVICE SLOT:")),
  vrow(I("0"), FB(31, vg.k)),
  vrow(I("1"), FB(2, vg.k), N(rp(" ", 29))),
  vrow(I("2"), FB(2, vg.k), N(rp(" ", 29))),
  vrow(I("3"), FB(2, vg.k), N(rp(" ", 29))),
  SH(vg.r),
  vrow(I(rp(" ", 20) + "FILE DETAILS")),
  vrow(N("  MTIME: 2026-05-30 16:20:08" + rp(" ", 4))),
  vrow(N("   SIZE: 157 K" + rp(" ", 18))),
  vrow(N(rp(" ", 32))),
  vrow(N(rp(" ", 32))),
  vrow(N(rp(" ", 24) + "NEWS.DSK")),
  SH(vg.r),
  vrow(N("   "), I("ARROW"), N(" "), I("KEYS"), N("  TO SELECT SLOT   ")),
  vrow(N(" "), I("ENTER"), N(" R/O "), I("W"), N(" R/W OR "), I("BREAK"), N(" ABORT ")),
  SH(vg.r))
#figcap("13", [Choosing a drive slot. Drive 0 is the one your Computer
boots from.])

#bl[#key-up #key-down — choose a drive slot (0 through 3)]
#bl[#key("ENTER") — load it #strong[read-only] (R/O): nothing can write
on it. Like a floppy with the notch covered.]
#bl[#key("W") — load it #strong[read/write] (R/W): programs can save onto
the image]
#bl[#key("BREAK") — never mind]

#colbreak()

#ybox(title: [NOTE])[Public libraries don't allow writing, so load their
disks read-only — that's the #key("ENTER") key. Save #key("W") for images
on your own SD card or your own server.]

When the disk is in, you return to the catalog right where you were —
load another disk into another drive, or press #key("BREAK") to back out
to the Host Slots screen.

#sect[The Drive Slots Screen]
#ix("Drive slots")

From the Host Slots screen, #key-right brings up the other list — what's
in the drives right now:

#tv(
  vrow(FB(21, vg.r), I("DRIVE"), N(" "), I("SLOTS")),
  vrow(I("03"), FB(1, vg.b), I("NEWS.DSK" + rp(" ", 21))),
  vrow(I("1"), FB(2, vg.k), N(rp(" ", 29))),
  vrow(I("2"), FB(2, vg.k), N(rp(" ", 29))),
  vrow(I("3"), FB(2, vg.k), N(rp(" ", 29))),
  SH(vg.r),
  ..range(7).map(_ => FR(vg.r)),
  vrow(N("0-3 "), I("SLOT"), N(" E"), I("JECT"), N("  CLEAR  "), I("ALL"), N(" "), I("SLOTS")),
  vrow(N("<- "), I("HOSTS"), N(" R"), I("EAD"), N(" W"), I("RITE"), N(" C"), I("ONFIG"), N(" L"), I("OBBY")),
  SH(vg.r))
#figcap("14", [Drive Slots. Reading a line: drive number, the host it
came from, a colored mode block, and the image's name.])

The small colored block on each line is the mode indicator:
#strong[blue] means read-only, #strong[yellow] means read/write, and
#strong[black] means the drive is empty.

#bl[#key("0")–#key("3") or #key-up #key-down — choose a drive]
#bl[#key("R") / #key("W") — flip the highlighted drive between read-only
and read/write]
#bl[#key("E") — eject the highlighted image]
#bl[#key("CLEAR") — eject everything]
#bl[#key-left — back to the Host Slots screen]

#sect[Leaving CONFIG]
#ix("Booting", "AUTOEXEC.BAS")

When your disks are loaded, press #key("BREAK") (from either the Host
Slots or Drive Slots screen). CONFIG announces #tt("MOUNTING ALL
SLOTS..."), your Computer restarts into HDB-DOS BASIC — and if the disk
in drive 0 has a BASIC program named #tt("AUTOEXEC.BAS") on it (or is an
OS-9 disk with a boot track), it runs automatically. Otherwise you land
at the friendly #tt("OK") prompt with your disks ready: type
#tt("DIR") #key("ENTER") and see.
#sect[Making New Disks]
#ix("New disk images, creating")

A disk system that can't make new disks would be a sad thing. Yours makes
them out of nothing at all. While browsing a host you can write to (your
SD card, say), press #key("N"). CONFIG asks two questions in the menu
area:

#bl[#tt("ENTER # OF DRIVES TO CREATE") — how many 157K virtual diskettes
to put in the image. Answer #tt("1") (multi-disk images are an HDB-DOS
power feature).]
#bl[#tt("ENTER FILENAME:") — name it. #tt(".DSK") is added for you if you
forget.]

The new image appears in the current folder, blank as the day it was
born, ready to load read/write — HDB-DOS images need no formatting.
Switch to it (Chapter 6) and #tt("SAVE") away.

#ybox(title: [NOTE])[Only create new disk images on your own SD card or
your own local server — public libraries politely refuse.]

#sect[Copying a Disk]
#ix("Copying disk images")

Found something on a network library you'd like to keep on your own card?
Highlight the file in the catalog and press #key("C"). CONFIG asks which
host to copy #emph[to] — pick #tt("SD") — then lets you walk the
destination's folders. When you're standing in the right folder, press
#key("C") again and the FujiNet does the rest, no Computer memory
required:

#tv(
  vrow(N(rp(" ", 14) + "COPYING FILE FROM:")),
  FR(vg.b),
  vrow(N(rp(" ", 13) + "TNFS.FUJINET.ONLINE")),
  vrow(N("/COCO/NEWS.DSK" + rp(" ", 18))),
  ..range(3).map(_ => FR(vg.b)),
  vrow(N(rp(" ", 16) + "COPYING FILE TO:")),
  FR(vg.b),
  vrow(N(rp(" ", 30) + "SD")),
  vrow(N("/NEWS.DSK" + rp(" ", 23))),
  ..range(5).map(_ => FR(vg.b)))
#figcap("15", [A copy in progress — straight from the library to your
card.])

#colbreak()

#sect[The Game Lobby]
#ix("Game Lobby", "Games, on-line")

Press #key("L") from the Host Slots or Drive Slots screen and CONFIG asks
#tt("BOOT TO LOBBY? Y/N"). Answer #key("Y") and your Computer boots into
the #strong[Lobby] — a live directory of on-line, multi-player games
being played right now on FujiNet-equipped computers everywhere: Five
Card Stud, Battleship, Fujitzee, and more. Pick a table and you're seated
— against an Atari in Poland, an Apple II in California, and a CoCo down
the street. Yes, real people. Yes, on your Color Computer.

// the Lobby's own screen theme: bright green on field green
#let LG = rgb("#177117")
#let LB = rgb("#4adb4a")
#let LN(s) = (txt: s, bg: LG, fg: LB)
#let LI(s) = (txt: s, bg: LB, fg: rgb("#0c4f0c"))
#tv(
  vrow(LN("#FUJINET GAME LOBBY     THOMCOCO")),
  vrow(LN(rp("-", 32))),
  vrow(LN("5 CARD STUD" + rp(" ", 14) + "PLAYERS")),
  vrow(LI(" AI ROOM - 2 BOTS" + rp(" ", 12) + "0/6")),
  vrow(LN(" AI ROOM - 4 BOTS" + rp(" ", 12) + "0/4")),
  vrow(LN(" AI ROOM - 6 BOTS" + rp(" ", 12) + "0/2")),
  vrow(LN(" THE BASEMENT" + rp(" ", 16) + "0/8")),
  vrow(LN(" THE DEN" + rp(" ", 21) + "0/8")),
  vrow(LN(rp(" ", 32))),
  vrow(LN("BATTLESHIP" + rp(" ", 22))),
  vrow(LN(" AI - 1 ON 1" + rp(" ", 17) + "0/4")),
  vrow(LN(" AI - 2 BOTS" + rp(" ", 17) + "0/4")),
  vrow(LN(" AI - 3 BOTS" + rp(" ", 17) + "0/4")),
  vrow(LN(rp("-", 32))),
  vrow(LN("SELECT GAME, PRESS "), LI("ENTER"), LN(" TO PLAY")),
  vrow(LI("R"), LN("EFRESH LIST" + rp(" ", 4)), LI("Q"), LN("A" + rp(" ", 3)), LI("C"), LN("HANGE NAME")))
#figcap("16", [The Lobby. Pick a table — bots are always seated, people
drop in all evening.])

#ybox(title: [NOTE])[If your firmware doesn't offer the #key("L") key
yet, no matter: load #tt("LOBBY.DSK") from the #tt("COCO") folder of
#tt("TNFS.FUJINET.ONLINE") into drive 0 and leave CONFIG with
#key("BREAK").]

#block(breakable: false, {
sect[CONFIG at a Glance]

align(center, table(columns: (auto, 1fr), align: (left, left),
  stroke: 0.6pt + ink, inset: 5pt,
  table.header(
    text(font: f-head, weight: 700, size: 9.5pt)[Key],
    text(font: f-head, weight: 700, size: 9.5pt)[Does]),
  [#key("ENTER")], [open / choose / load read-only],
  [#key("W")], [load read/write — careful],
  [#key("E")], [edit a host slot; eject a drive],
  [#key-left #key-right], [hosts screen and drives screen; in
    the catalog, #key-left backs out of a folder],
  [#key("F") #key("N") #key("C")], [filter, new image, copy (in the
    catalog)],
  [#key("C") #key("L")], [configuration screen, Lobby],
  [#key("CLEAR")], [eject all drives],
  [#key("BREAK")], [back out; from the main screens, leave CONFIG and
    boot]))
})

#v(4pt)
#gbar
]

// ============================================================
// USING HDB-DOS
// ============================================================
#chapter("Using HDB-DOS", subs: ("Old Friends", "RUNM", "DRIVE #",
  "FLEXIKEY", "Saving Your Work"))
#ix("HDB-DOS", "Disk BASIC commands")

#cols2[
This is where the fun really begins. When you leave CONFIG, your Computer
is an ordinary disk-equipped CoCo — as far as it knows. The disk system
it boots is #strong[HDB-DOS], a widely used extension of Tandy's Disk
Extended Color BASIC, and everything from your books, magazines, and
memory works unchanged. The FujiNet team did not write HDB-DOS and treats
it as the well-finished classic it is.

#sect[Old Friends]

All the Disk BASIC commands behave exactly as documented in 1981:

#block(inset: (left: 0.2in), {
  par(tt("DIR") + h(10pt) + text(size: 8.6pt)[— list the disk in drive 0])
  par(tt("DIR 1") + h(10pt) + text(size: 8.6pt)[— list the disk in drive 1])
  par(tt("RUN\"GAME\"") + h(10pt) + text(size: 8.6pt)[— load and run a BASIC
  program])
  par(tt("LOADM\"PROG.BIN\"") + text(size: 8.6pt)[ then ] + tt("EXEC") +
    h(8pt) + text(size: 8.6pt)[— machine language, the long way])
  par(tt("SAVE\"MINE\"") + h(10pt) + text(size: 8.6pt)[— save your BASIC
  program])
  par(tt("BACKUP") + text(size: 8.6pt)[, ] + tt("COPY") +
    text(size: 8.6pt)[, ] + tt("KILL") + text(size: 8.6pt)[, ] +
    tt("RENAME") + text(size: 8.6pt)[... — all present])
})

#sect[RUNM]
#ix("RUNM command")

HDB-DOS adds a one-step launcher for machine-language programs. Instead
of #tt("LOADM") followed by #tt("EXEC"):

#block(inset: (left: 0.2in), tt("RUNM\"PROG.BIN\"") + h(6pt) + key("ENTER"))

#sect[DRIVE \#]
#ix("DRIVE # command")

To make a different drive the default, HDB-DOS uses a #tt("#") where
Disk BASIC's plain #tt("DRIVE") command would go. To switch to the disk
image in drive slot 1:

#block(inset: (left: 0.2in), tt("DRIVE #1") + h(6pt) + key("ENTER"))

#colbreak()

#sect[FLEXIKEY]
#ix("FLEXIKEY")

HDB-DOS can replay the last line you typed, one character at a time —
wonderful after a typo:

#bl[#key-right — recall the last line you typed, one character per press]
#bl[#key("SHIFT") #key-right — recall the whole rest of the line at once]
#bl[#key-left — erase one character, as always]
#bl[#key("SHIFT") #key-left — throw away the whole line you're typing]

#sect[Saving Your Work]
#ix("Saving programs")

Remember the mode blocks from Chapter 5: a disk loaded #strong[read-only]
(blue) refuses #tt("SAVE") and #tt("KILL") just as a write-protected
floppy would. To save, use an image on your own card loaded with
#key("W") (yellow). The recipe for a fresh workspace:

+ In CONFIG, browse to your SD card, press #key("N"), and make
  #tt("MYDISK.DSK").
+ Load it into drive 1 read/write.
+ Leave CONFIG with #key("BREAK").
+ #tt("SAVE\"WORK:1\"") — or #tt("DRIVE #1") first, and just
  #tt("SAVE\"WORK\"").

#ybox(title: [NOTE])[HDB-DOS has more features than this chapter — many
of them, like multi-disk #tt("DRIVE") banks, are power tools. The
complete HDB-DOS manual is free at cloud9tech.com. For questions about
HDB-DOS itself, that manual is the authority.]

#block(breakable: false, {
  sect[Getting Back to CONFIG]
  par[Press the Computer's RESET button (right rear corner of the case),
  then type #tt("DOS") #key("ENTER"). The FujiNet serves CONFIG again,
  with your drives just as you left them. (Powering off and on works
  too.)]
})

#v(4pt)
#gbar
]

// ============================================================
// THE PROGRAM LIBRARY
// ============================================================
#chapter("The Program Library", subs: ("News", "Weather", "Wiki",
  "Netcat", "And More"))
#ix("Programs, FujiNet-aware", "News program", "Weather program",
   "Wiki program", "Netcat program")

// a program screenshot in the manual's black TV bezel
#let scrshot(file, w: 2.35in) = align(center, block(breakable: false,
  box(fill: vg.k, inset: 8pt, radius: 3pt,
    image("images/" + file, width: w))))
// one program: heading, description, and its screen — kept together
#let prog(head, num, cap, shot, body) = block(breakable: false,
  above: 1.1em, below: 0.3em, {
  sect(head)
  body
  v(3pt)
  scrshot(shot)
  figcap(num, cap)
})

#cols2[
Disk images were only the beginning. A growing shelf of programs is
written #emph[for] the FujiNet — they talk through its network channel
directly, no modem heard from. You met the Lobby in Chapter 5; here are
the daily drivers, all free in the #tt("COCO") folder at
#tt("TNFS.FUJINET.ONLINE"). Load one into drive 0, leave CONFIG, and it
runs by itself.

#prog([News — #tt("NEWS.DSK")], "17",
  [The News topic menu.], "prog-news.png")[
A wire-service reader. Pick a topic — world news, business, science,
technology, sports — scroll the headlines, and read whole stories on your
CoCo. On a CoCo 1 or 2 it offers 32- and 42-column displays (the latter
with real lowercase); a CoCo 3 can use its native 40- and 80-column
screens.]

#prog([Weather — #tt("WEATHER.DSK")], "18",
  [Weather, with a forecast a keypress away.], "prog-weather.png")[
Current conditions and forecasts, anywhere you can name. It finds your
location automatically (by your network address), shows temperature,
humidity, wind, dew point, sunrise and sunset — and switches between
Fahrenheit and metric on a keypress.]

#prog([Wiki — #tt("WIKI.DSK")], "19",
  [Wikipedia in 42 columns of real lowercase.], "prog-wiki.png")[
Wikipedia, on a Color Computer. Type a subject, pick from the matching
articles, and read — the soft 42-column font with true lowercase makes
long articles a pleasure. Forty years on, your CoCo contains the sum of
human knowledge. Approximately.]

#prog([Netcat — #tt("NETCAT.DSK")], "20",
  [Netcat dialing a telnet BBS.], "prog-netcat.png")[
#ix("Bulletin boards (BBS)")
A simple, solid terminal program for the telnet bulletin boards that are
alive and well today. Give it an address in the form
#tt("N:TELNET://BBS.EXAMPLE.COM:23") and you're calling — no telephone,
no long distance. Recent versions speak VT-52 with a 42-column display,
so full-screen boards look right.]

#sect[And More]

The shelf keeps growing — browse the #tt("COCO") folder now and then.
Programmers: the network channel that powers these programs is yours too,
from BASIC or C or assembly. Start at
#text(font: f-sans, size: 8pt)[github.com/FujiNetWIFI] and the
#strong[fujinet-lib] library; the community Discord is full of people who
will happily get you started.
#ix("Programming, FujiNet")
]

// a full-width closing plate: the whole outfit at work
#v(0.22in)
#block(breakable: false, {
  phimg("full-setup.jpg",
    "the whole setup: CoCo with CocoFuji installed, serial cable to the rear, TV showing CONFIG",
    height: 3.7in)
  figcap("21", [The complete outfit — disks and programs alike,
  conjured out of thin air.])
})

#gbar

// ============================================================
// TROUBLESHOOTING AND MAINTENANCE
// ============================================================
#chapter("Troubleshooting and Maintenance", subs: ("Symptom/Cure Table",
  "Updating the Firmware", "Maintenance"))
#ix("Troubleshooting")

If you have problems operating your FujiNet, check the following table of
symptoms. Hopefully, you'll find the cure as well. If you still can't
remedy the problem, bring it to the community (page 4) where it will be
promptly puzzled over, free of charge.

#v(6pt)
#let sympt(s, cures) = (
  {
    set par(leading: 0.5em, justify: false)
    set text(size: 9pt)
    s
  },
  {
    set par(leading: 0.5em, justify: false)
    set text(size: 9pt)
    set enum(spacing: 0.55em)
    cures
  },
)
#grid(columns: (1fr, 1fr), column-gutter: 0.35in,
  table(columns: (1.35in, 1fr), stroke: 0.6pt + ink, inset: 6pt,
    table.header(
      text(font: f-head, weight: 700, size: 11pt)[Symptom],
      text(font: f-head, weight: 700, size: 11pt)[Cure]),
    ..sympt[CONFIG doesn't appear when you turn the Computer on.][
      1. Cartridge not seated. Power off, reseat it, try again.
      2. Serial plug not in the SERIAL I/O jack (or in the cassette jack
      by mistake — they're neighbors and the cassette DIN has 5 pins).
      3. Model switches set for the wrong machine — check the table in
      Chapter 2.
      4. Television not tuned to the Computer (channel 3/4, antenna
      switch).],
    ..sympt[Garbage, or BASIC appears but #tt("DOS") hangs.][
      1. Wrong model switch setting — the FujiNet is talking at the wrong
      speed.
      2. Dirty cartridge contacts. Power off and reseat the cartridge.],
    ..sympt[The network scan finds nothing, or won't connect.][
      1. The FujiNet hears 2.4 GHz networks only. Give your router's
      2.4 GHz band its own network name.
      2. Hidden network? Press #key("H") and type its name exactly.
      3. Passwords are case-sensitive — #key("SHIFT") for capitals.]),
  table(columns: (1.35in, 1fr), stroke: 0.6pt + ink, inset: 6pt,
    table.header(
      text(font: f-head, weight: 700, size: 11pt)[Symptom],
      text(font: f-head, weight: 700, size: 11pt)[Cure]),
    ..sympt[A host slot won't open.][
      1. Check the spelling (#key("E") to look).
      2. Try a known-good host: #tt("TNFS.FUJINET.ONLINE").
      3. For #tt("SD"): is a card inserted and clicked home? Is it
      FAT32?],
    ..sympt[A disk won't boot, or a program won't load.][
      1. The Computer boots drive 0 — is your disk there?
      2. Not every image is bootable; many are data disks. #tt("DIR") it
      and #tt("RUN") what you find.],
    ..sympt[Can't #tt("SAVE") — #tt("?WP ERROR") or similar.][
      1. The image is loaded read-only. In CONFIG's Drive Slots screen,
      highlight it and press #key("W") (mode block turns yellow).
      2. Public libraries never accept writes — copy the image to your SD
      card first (Chapter 5).],
    ..sympt[The white lamp never lights.][
      The FujiNet hasn't joined a network — run through Chapter 4. The
      lamp is also off for a few seconds at every power-up while it
      reconnects: patience.]))

// --------------------------------------------------------------
#pagebreak(weak: true)
#cols2[
#sect[Updating the Firmware]
#ix("Firmware updates", "FujiNet-Flasher")

New firmware arrives regularly with new features. Updating takes a modern
computer, the free #strong[FujiNet-Flasher] program (from
fujinet.online/download), and a USB cable with a #strong[micro-USB] end.

+ Power off your Color Computer. You may leave the cartridge installed or
  bring it to your desk — USB powers it safely either way.
+ Install the flasher. On Windows you may also need the SiLabs "CP210x
  Universal" USB driver — the flasher's page links to it.
+ Connect the USB cable from your computer to the FujiNet's micro-USB
  jack.
+ Start the flasher, choose the serial port it found, leave the speed at
  460800, and choose platform #strong[Tandy CoCo] and the newest firmware
  version.
+ Click #strong[Flash FujiNet Firmware], then press and hold the
  FujiNet's #strong[A button] until the progress log shows writing has
  begun. Release, and let it finish.
+ Disconnect the cable before powering up your CoCo.

#ybox(title: [NOTE])[Nightly test builds are also published. They are
provided 100% as-is with no guarantee — use them only if you enjoy
troubleshooting (some of us do).]

The flasher also has a #strong[Serial Debug Output] button: with the USB
cable connected, it shows a running log of everything the FujiNet is
doing — the first thing the community will ask for if you report a
mystery.
#ix("Debug log")

#colbreak()

#sect[Maintenance]

Your FujiNet requires little maintenance.

#bl[Keep it free of dust, and treat the cartridge slot with the same
respect as any Program Pak: Computer OFF before inserting or removing.]
#bl[The microSD card is the only moving part, so to speak. Push to seat,
push to release — never pull.]
#bl[If the case needs cleaning, use a damp, lint-free cloth. The printed
case does not care for solvents.]
#bl[The serial cable is captive. If it ever fails, the cartridge is open
hardware — the community can show you the two solder joints.]

#sect[Pressing the Reset Button]

The small button at the #rsym marking restarts the FujiNet itself —
not your Computer. You will rarely need it: if the FujiNet ever seems
asleep (lamps frozen, CONFIG unresponsive), press it once, wait a few
seconds, and press the Computer's RESET, then type #tt("DOS")
#key("ENTER").

#v(4pt)
#gbar
]

// ============================================================
// SPECIFICATIONS
// ============================================================
#chapter("Specifications", subs: ())
#ix("Specifications", "Pin connections, serial")

#cols2[
#sect[Power]
#block(inset: (left: 0.15in), {
  grid(columns: (1.7in, 1fr), row-gutter: 5pt,
    text(size: 9pt)[Supply], text(size: 9pt)[+5 VDC from the cartridge
      slot (diode-isolated)],
    text(size: 9pt)[Alternate supply], text(size: 9pt)[micro-USB, 5 VDC —
      safe to use together],
    text(size: 9pt)[Processor], text(size: 9pt)[ESP32 (two 32-bit cores,
      240 MHz) — rather more computer than the computer])
})

#sect[Serial Interface]
The captive cable carries DriveWire protocol over the Color Computer's
built-in serial port ("the bit-banger"), at a speed set by the model
switches:

#align(center, table(columns: (auto, auto), align: (left, right),
  stroke: 0.6pt + ink, inset: 5pt,
  table.header(
    text(font: f-head, weight: 700, size: 9.5pt)[Model setting],
    text(font: f-head, weight: 700, size: 9.5pt)[Speed]),
  [Color Computer 1], [38,400 baud],
  [Color Computer 2 / Dragon], [57,600 baud],
  [Color Computer 3], [115,200 baud]))

#sect[Storage]
#block(inset: (left: 0.15in), {
  grid(columns: (1.7in, 1fr), row-gutter: 5pt,
    text(size: 9pt)[Drive slots], text(size: 9pt)[4 (drives 0–3)],
    text(size: 9pt)[Host slots], text(size: 9pt)[8],
    text(size: 9pt)[Virtual diskette], text(size: 9pt)[161,280 bytes
      (35 tracks × 18 sectors × 256 bytes) — "157K"],
    text(size: 9pt)[microSD], text(size: 9pt)[FAT32, 64 GB or less
      recommended],
    text(size: 9pt)[Network], text(size: 9pt)[WiFi 802.11 b/g/n,
      2.4 GHz; TNFS, HTTP and friends over WiFi])
})

#colbreak()

#sect[Serial Plug Pin Location]

Looking at the 4-pin DIN plug on the FujiNet's cable (solder side — the
view you'd see looking #emph[into] the SERIAL I/O jack on the Computer):

#align(center, box(width: 1.7in, height: 1.7in, {
  place(center + horizon, circle(radius: 0.72in, stroke: 1.1pt + ink))
  place(center + top, dy: 0.13in, rect(width: 0.2in, height: 0.12in,
    fill: paper, stroke: 1.1pt + ink))
  // pins: 1 right, 4 left, 2 lower-right, 3 lower-left
  place(center + horizon, dx: 0.42in, dy: -0.05in, circle(radius: 3.2pt, fill: ink))
  place(center + horizon, dx: -0.42in, dy: -0.05in, circle(radius: 3.2pt, fill: ink))
  place(center + horizon, dx: 0.2in, dy: 0.33in, circle(radius: 3.2pt, fill: ink))
  place(center + horizon, dx: -0.2in, dy: 0.33in, circle(radius: 3.2pt, fill: ink))
  place(center + horizon, dx: 0.62in, dy: -0.05in, text(font: f-head, weight: 700, size: 9pt)[1])
  place(center + horizon, dx: -0.62in, dy: -0.05in, text(font: f-head, weight: 700, size: 9pt)[4])
  place(center + horizon, dx: 0.34in, dy: 0.5in, text(font: f-head, weight: 700, size: 9pt)[2])
  place(center + horizon, dx: -0.34in, dy: 0.5in, text(font: f-head, weight: 700, size: 9pt)[3])
}))

#align(center, table(columns: (auto, auto, auto), align: (center, left, left),
  stroke: 0.6pt + ink, inset: 5pt,
  table.header(
    text(font: f-head, weight: 700, size: 9.5pt)[Pin],
    text(font: f-head, weight: 700, size: 9.5pt)[Signal],
    text(font: f-head, weight: 700, size: 9.5pt)[Direction]),
  [1], [CD — Carrier Detect], [FujiNet to Computer],
  [2], [RD — Receive Data], [FujiNet to Computer],
  [3], [GND — Signal Ground], [—],
  [4], [TD — Transmit Data], [Computer to FujiNet]))

The pinout is the Color Computer's own — see the #emph[Serial Interface]
page of your Operation Manual, where the same drawing appears facing the
other way.

#v(4pt)
#gbar
]

// ============================================================
// CUSTOMER INFORMATION
// ============================================================
#chapter("Customer Information", subs: ())
#ix("License, software", "Warranty")

#cols2[
#sect[Service Policy]

The FujiNet community's worldwide network of enthusiasts provides quick,
convenient, and friendly help for this device, in most instances within
hours, on the Discord server and the user groups listed on page 4.
Because there is no warranty department, there is also no warranty-void
sticker: opening the case is not a violation, it's encouraged. The
following limitations also apply:

+ If any of the screws on your FujiNet are broken, the community will
  cheerfully tell you where to buy more (they are ordinary M3s).
+ If your FujiNet has been modified, the community will want to hear all
  about it.

#sect[Software License]

The FujiNet firmware, the CONFIG program, this manual, and the hardware
design are free software and open hardware, licensed under the GNU
General Public License v3 (and compatible licenses). You may use, copy,
study, modify, and share them. Source for everything is at
#text(font: f-sans, size: 8.2pt)[github.com/FujiNetWIFI] — and your
improvements are welcome back.

#colbreak()

#align(center + horizon, box(width: 95%, {
  rect(width: 100%, stroke: 2.6pt + ink, inset: 3.5pt,
    rect(width: 100%, stroke: 0.8pt + ink, inset: (x: 14pt, y: 12pt), {
      align(center, text(font: f-head, weight: 700, size: 13.5pt)[LIMITED
      WARRANTY])
      v(7pt)
      set par(justify: true)
      set text(size: 8.7pt)
      par[For a period of FOREVER from the date of delivery, the FujiNet
      community warrants to the original purchaser — and to everyone the
      purchaser shares it with — that the software shall remain free, the
      source shall remain open, and the schematics shall remain
      published.]
      v(4pt)
      par[EXCEPT AS SPECIFICALLY PROVIDED ABOVE, EVERYTHING IS PROVIDED
      "AS IS" WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
      ANY IMPLIED WARRANTIES OF MERCHANTABILITY OR FITNESS FOR A
      PARTICULAR PURPOSE. IN NO EVENT SHALL THE COMMUNITY BE LIABLE FOR
      LOSS OF PROFITS OR BENEFITS — ONLY OF EVENINGS, WHICH YOU WILL
      SPEND PLAYING WITH YOUR COLOR COMPUTER.]
      v(4pt)
      par[Unlike 1980: when something bothers you, you can read the
      source, fix it yourself, and send a pull request. Statements made
      by community members regarding the FujiNet's capacity or
      suitability are usually enthusiasm, which is warranted in full.]
      v(4pt)
      align(right, text(size: 8.7pt)[6-26])
    }))
}))
]

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

// ============================================================
// BACK COVER
// ============================================================
#pagebreak(weak: true)
#fst.update(false)
#page(margin: 0pt, footer: none)[
  #place(image("images/starfield.png", width: 100%, height: 100%))
  #place(top + left, dx: 0.32in, dy: 0.32in,
    rect(width: 10in - 0.64in, height: 8in - 0.64in,
      stroke: 2.6pt + cvr-blu))

  #place(bottom + center, dy: -1.05in, {
    set align(center)
    set par(leading: 0.7em)
    text(font: f-sans, weight: 700, size: 9.5pt, fill: cvr-mag,
      tracking: 0.5pt)[FUJINET #h(4pt) A WORLDWIDE COMMUNITY PROJECT]
    v(2pt)
    line(length: 3.4in, stroke: 0.7pt + cvr-mag)
    v(4pt)
    text(font: f-sans, size: 8.5pt, fill: cvr-mag)[WEB: FUJINET.ONLINE]
    linebreak()
    text(font: f-sans, size: 8.5pt, fill: cvr-mag)[SOURCE: GITHUB.COM/FUJINETWIFI]
    v(4pt)
    line(length: 3.4in, stroke: 0.7pt + cvr-mag)
    v(4pt)
    grid(columns: (1fr, 1fr, 1fr), column-gutter: 0.3in,
      align(center, text(font: f-sans, size: 7pt, fill: cvr-mag)[CHAT\ DISCORD — LINK AT\ FUJINET.ONLINE]),
      align(center, text(font: f-sans, size: 7pt, fill: cvr-mag)[GROUPS\ FUJINET USERS\ ON FACEBOOK]),
      align(center, text(font: f-sans, size: 7pt, fill: cvr-mag)[LIBRARY\ TNFS.FUJINET.ONLINE\ /COCO]))
  })
]
