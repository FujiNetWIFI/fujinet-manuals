// ============================================================
// FUJINET RS-232 for MS-DOS — GUIDE TO OPERATIONS
//
// Designed after the 1981 IBM Personal Computer "Guide to
// Operations" (P/N 6025000): portrait binder trim, deep wine
// cover with the striped masthead and "Hardware Reference
// Library" slug, Press Roman (Times) body, bold serif heads,
// big step numerals, Note:/CAUTION: callouts, black bleeder
// tabs down the fore-edge, curved corner registration marks,
// and section-relative folios ("Setup 2-7").
//
// Hardware facts verified against fujinet-hardware RS232-Rev1b
// (schematic, BOM, STLs) and fujinet-msdos (sys, printer,
// fmount, fnshare, ncopy, nget, nput).  CONFIG screens are
// typeset in the genuine IBM PC ROM character set (Px437 IBM)
// with text taken verbatim from fujinet-config src/msdos.
//
// Build: typst compile --font-path fonts manual.typ
// ============================================================

#let photos = (
  "fujinet-in-hand.jpg": false,
  "plugged-in.jpg": false,
  "full-setup.jpg": false,
)

// ---------- fonts -------------------------------------------
#let f-body = "Nimbus Roman"            // Press Roman / Times equivalent
#let f-mono = "Px437 IBM VGA 8x16"      // genuine PC ROM font (listings)
#let f-scrn = "Px437 IBM CGA"           // genuine CGA ROM font (screens)

// ---------- palette -----------------------------------------
#let ink    = rgb("#1b1a18")
#let paper  = rgb("#ffffff")
#let wine   = rgb("#6c3a48")            // the cover stock
#let wine-d = rgb("#52303b")
#let rule-c = rgb("#262320")
#let tab-bg = rgb("#181614")

// CGA text-mode colors (EDIT.EXE scheme used by CONFIG)
#let cga = (
  blue:  rgb("#0000aa"),   // desktop / box interior  (bg 1)
  gray:  rgb("#aaaaaa"),   // light gray  (header/status bars, normal text)
  white: rgb("#ffffff"),   // bright white (borders, emphasis)
  black: rgb("#000000"),
  dgray: rgb("#555555"),   // drop shadow
  cyan:  rgb("#00aaaa"),
)

// ---------- helpers -----------------------------------------
#let rp(s, n) = range(n).map(_ => s).join("")
#let sp(n) = rp(" ", n)

// inline literal (filenames, commands) — the ROM mono face
#let kw(s) = text(font: f-mono, size: 0.92em, fill: ink, s)
// a path/URL that contains // — pass as a plain string, never markup
#let url(s) = text(font: f-mono, size: 0.92em, fill: ink, s)

// index + toc metadata
#let chmark(title, num, subs) = metadata((
  kind: "chapter", title: title, num: num, subs: subs))
#let ix(..terms) = terms.pos().map(t => metadata((kind: "ix", term: t))).join()

// ---------- section-relative folio + running section --------
#let sec-state = state("sec", (name: "", num: 0))
#let sec-page = counter("secpage")
#let show-folio = state("folio", false)

#let foot = context {
  if not show-folio.get() { return }
  let s = sec-state.get()
  if s.name == "" { return }
  let p = sec-page.get().first()
  set text(font: f-body, size: 9pt, fill: ink)
  align(right)[#strong(s.name)#h(6pt)#s.num\-#p]
}

// curved corner registration marks in the fore-edge margin
#let regmarks = context {
  if not show-folio.get() { return }
  let arc = curve(
    stroke: 0.5pt + rgb("#b9b3a8"), fill: none,
    curve.move((0pt, 0pt)),
    curve.cubic((3pt, 3pt), (3pt, 11pt), (0pt, 14pt)),
  )
  place(top + right, dx: 0.16in, dy: 1.1in, arc)
  place(bottom + right, dx: 0.16in, dy: -1.1in, arc)
}

// ---------- the striped masthead (IBM 8-bar homage) ---------
#let striped(body, stripe: wine, n: 7) = box(clip: true, {
  body
  context {
    let m = measure(body)
    let h = m.height
    let gap = h / n
    for i in range(1, n) {
      place(top + left, dy: gap * i - 0.6pt,
        line(length: m.width, stroke: 1.1pt + stripe))
    }
  }
})

// ---------- bleeder tab on the fore-edge --------------------
#let bleeder(label, slot: 0) = place(top + right, dx: 0.62in,
  dy: 0.9in + slot * 0.92in,
  rotate(90deg, origin: center, reflow: false,
    box(fill: tab-bg, inset: (x: 9pt, y: 4pt),
      text(font: f-body, weight: 700, size: 8.5pt, fill: white,
        tracking: 0.4pt, upper(label)))))

// ---------- chapter opener ----------------------------------
#let chapter(title, num: 0, subs: (), tab: none) = {
  pagebreak(weak: true)
  sec-state.update((name: title, num: num))
  sec-page.update(1)
  chmark(title, num, subs)
  if tab != none { bleeder(tab) }
  v(0.15in)
  text(font: f-body, weight: 700, size: 16pt, fill: ink,
    [SECTION #num.#h(6pt)#upper(title)])
  v(2pt)
  line(length: 100%, stroke: 1.6pt + rule-c)
  v(0.3in)
}

// a major head (bold serif, flush left, like the IBM subsection heads)
#let sect(title) = block(above: 1.4em, below: 0.7em, breakable: false,
  text(font: f-body, weight: 700, size: 13pt, fill: ink, title))
#let subsect(title) = block(above: 1.1em, below: 0.5em, breakable: false,
  text(font: f-body, weight: 700, size: 11pt, fill: ink, title))

// ---------- big step numerals -------------------------------
#let step(n, body) = block(above: 0.8em, below: 0.8em, breakable: false,
  grid(columns: (0.42in, 1fr), column-gutter: 6pt,
    text(font: f-body, weight: 700, size: 17pt, fill: ink, [#n.]),
    par(leading: 0.6em, justify: true, body)))

// ---------- bullets -----------------------------------------
#let bl(body) = block(above: 0.4em, below: 0.4em,
  grid(columns: (0.26in, 1fr),
    align(left + top, move(dy: 3.2pt, box(width: 4.5pt, height: 4.5pt,
      fill: ink))),
    par(leading: 0.56em, justify: true, body)))

// ---------- Note / CAUTION / WARNING ------------------------
#let note(body) = block(above: 0.9em, below: 0.9em, breakable: false,
  grid(columns: (auto, 1fr), column-gutter: 5pt,
    text(weight: 700)[Note:],
    par(leading: 0.56em, justify: true, body)))
#let caution(body, word: "CAUTION") = block(above: 0.9em, below: 0.9em,
  breakable: false, par(leading: 0.56em, justify: true,
    text(weight: 700, [#underline(word):]) + " " + body))

// ---------- figure caption ----------------------------------
#let figcap(body) = block(above: 0.5em, below: 1.0em,
  align(center, text(font: f-body, style: "italic", size: 9.5pt, body)))

#let phimg(file, desc, height: 2.0in) = {
  if photos.at(file, default: false) {
    align(center, image("images/" + file, height: height))
  } else {
    align(center, rect(width: 80%, height: height, fill: rgb("#f3f1ec"),
      stroke: (paint: rgb("#a8a298"), thickness: 0.7pt, dash: "dashed"),
      align(center + horizon, par(justify: false, leading: 0.6em,
        text(font: f-body, size: 9pt, fill: rgb("#8a8478"),
          "[ PHOTOGRAPH: " + file + " ]\n") +
        text(font: f-body, size: 9pt, style: "italic",
          fill: rgb("#8a8478"), desc)))))
  }
}

// ============================================================
// CRT SCREEN RENDERER — 80x25 text mode in the IBM ROM font
// ============================================================
// A screen is a list of rows; each row is a list of runs
// (text, fg, bg) laid into fixed cells so columns always align.
// 80 cols x ~4.1pt fit the page; the IBM manual's inset screens
// were small too.
#let SCRSZ = 4.15pt         // glyph size (== cell advance)
#let CELLW = 4.15pt         // cell width
#let ROWH  = 4.9pt          // cell height (a little leading)

#let run(s, fg: cga.gray, bg: cga.blue) = (s: s, fg: fg, bg: bg)
#let n_(s) = run(s, fg: cga.gray, bg: cga.blue)          // normal
#let b_(s) = run(s, fg: cga.white, bg: cga.blue)         // bright white
#let bar(s) = run(s, fg: cga.black, bg: cga.gray)        // header/status
#let sel(s) = run(s, fg: cga.black, bg: cga.gray)        // selection bar

#let srow(..runs) = stack(dir: ltr, ..runs.pos().map(r => {
  box(width: r.s.clusters().len() * CELLW, height: ROWH, fill: r.bg,
    clip: true, inset: 0pt, outset: 0pt,
    place(left + horizon,
      text(font: f-scrn, size: SCRSZ, fill: r.fg, bottom-edge: "baseline", r.s)))
}))

// pad a row of runs to 80 columns with blue fill
#let full(..runs) = {
  let used = runs.pos().map(r => r.s.clusters().len()).sum(default: 0)
  let pad = if used < 80 { (n_(sp(80 - used)),) } else { () }
  srow(..runs.pos(), ..pad)
}
// a header/status bar filled to 80 cols in light gray
#let barline(..runs) = {
  let used = runs.pos().map(r => r.s.clusters().len()).sum(default: 0)
  let pad = if used < 80 { (bar(sp(80 - used)),) } else { () }
  srow(..runs.pos(), ..pad)
}

#let crt(..rows) = align(center, block(breakable: false,
  above: 1.2em, below: 0.7em,
  box(fill: rgb("#d3cec3"), radius: 10pt, inset: 9pt,
    stroke: 1.2pt + rule-c, {
    box(fill: cga.blue, inset: 4pt, radius: 2pt,
      stack(dir: ttb, ..rows.pos()))
  })))

// monospace listing (DOS prompt transcripts) on white, ROM font
#let listing(body) = block(above: 0.9em, below: 0.9em, breakable: false,
  width: 100%, fill: rgb("#f4f2ec"), inset: 9pt, stroke: 0.5pt + rgb("#cfcabf"),
  text(font: f-mono, size: 8.5pt, fill: ink, body))

// string-based listing (safe for URLs with // and literal -- dashes)
#let lst(..lines) = block(above: 0.9em, below: 0.9em, breakable: false,
  width: 100%, fill: rgb("#f4f2ec"), inset: 9pt, stroke: 0.5pt + rgb("#cfcabf"),
  text(font: f-mono, size: 8.5pt, fill: ink,
    lines.pos().map(l => l).join(linebreak())))

// ============================================================
// DOCUMENT SETUP
// ============================================================
#set document(title: "FujiNet RS-232 for MS-DOS — Guide to Operations",
  author: "The FujiNet Community")
#set text(font: f-body, size: 10.5pt, fill: ink, hyphenate: true)
#set par(leading: 0.62em, spacing: 0.7em, justify: true, first-line-indent: 0pt)
#set strong(delta: 300)
#set page(width: 7.0in, height: 9.0in, fill: paper,
  margin: (left: 0.95in, right: 1.05in, top: 0.7in, bottom: 0.8in),
  footer: foot, background: regmarks)
#set enum(numbering: "1.", indent: 0pt, body-indent: 8pt, spacing: 0.7em)

// ============================================================
// FRONT COVER
// ============================================================
#page(margin: 0pt, footer: none, background: none)[
  #rect(width: 100%, height: 100%, fill: wine)
  // three-hole binder punches
  #for dy in (1.6in, 4.5in, 7.4in) {
    place(left + top, dx: 0.42in, dy: dy, circle(radius: 0.12in, fill: paper))
  }
  // masthead: striped FujiNet + reference library slug
  #place(top + left, dx: 1.15in, dy: 0.7in,
    striped(text(font: f-body, weight: 700, size: 30pt, fill: paper)[FujiNet],
      stripe: wine, n: 7))
  #place(top + right, dx: -0.7in, dy: 0.78in,
    text(font: f-body, style: "italic", size: 12pt, fill: paper)[
      Personal Computer\
      Hardware Reference\
      Library])

  #place(top + left, dx: 1.15in, dy: 3.7in,
    line(length: 4.6in, stroke: 0.8pt + paper))
  #place(top + left, dx: 1.15in, dy: 3.95in,
    text(font: f-body, size: 44pt, fill: paper)[Guide to\ Operations])

  #place(top + left, dx: 1.15in, dy: 5.7in,
    text(font: f-body, style: "italic", size: 13pt, fill: paper)[
      The RS-232 FujiNet Network Adapter])

  #place(bottom + right, dx: -0.7in, dy: -1.2in,
    image("images/fujinet-rs232-hero.png", width: 3.3in))

  #place(bottom + left, dx: 1.15in, dy: -0.7in,
    text(font: f-mono, size: 10pt, fill: paper)[FN-RS232-GTO-001])
]

// ============================================================
// INSIDE FRONT — LIMITED WARRANTY (tribute, original text)
// ============================================================
#page(footer: none)[
  #v(0.4in)
  #align(center, text(font: f-body, weight: 700, size: 13pt)[
    A WORD ABOUT THIS GUIDE])
  #v(0.3in)
  #set par(justify: true, leading: 0.62em)
  #set text(size: 10pt)
  This Guide is a labor of love by the worldwide FujiNet community. It is
  free, as is everything it describes: the FujiNet firmware, the CONFIG
  program, the MS-DOS drivers and utilities, and this very book. You are
  warmly encouraged to copy it, print it, and pass it to a friend.

  #v(0.15in)
  The FujiNet community makes no promise that the network will be polite,
  that the weather report you fetch will be accurate, or that you will get
  any sleep once you discover how much there is to explore. The hardware is
  warranted only to the extent that the people who designed it want you to
  have a good time. If something does not work, the community will do its
  best to help — see #strong[Getting Help] at the end of this Guide.

  #v(0.3in)
  #align(center, text(font: f-body, weight: 700, size: 11pt)[
    A NOTE ON RADIO INTERFERENCE])
  #v(0.12in)
  This equipment uses a small radio to reach your wireless network. It has
  been designed to be a good neighbor on the air. In the rare event that
  it disagrees with a nearby television or radio, moving the FujiNet, the
  computer, or the offended appliance a few inches usually restores the
  peace — the same cure the original Personal Computer manual recommended
  forty-odd years ago, and just as good today.

  #v(1fr)
  #set text(size: 9pt)
  #par(justify: false)[
    #strong[First Edition (2026)]\
    The FujiNet project is a community of enthusiasts and is not affiliated
    with, endorsed by, or sponsored by International Business Machines
    Corporation. "IBM" and "Personal Computer" are used here only to
    describe the computers this adapter works with. The visual styling of
    this Guide is an affectionate tribute to a manual that taught a
    generation how to switch the thing on.]
]

// ============================================================
// TITLE PAGE
// ============================================================
#page(footer: none)[
  #v(0.7in)
  #align(center, striped(
    text(font: f-body, weight: 700, size: 26pt, fill: ink)[FujiNet],
    stripe: paper, n: 7))
  #v(4pt)
  #align(center, text(font: f-body, style: "italic", size: 11pt)[
    Personal Computer Hardware Reference Library])
  #v(1.3in)
  #align(center, line(length: 3.4in, stroke: 0.8pt + ink))
  #v(0.18in)
  #align(center, text(font: f-body, size: 34pt)[Guide to Operations])
  #v(0.18in)
  #align(center, text(font: f-body, style: "italic", size: 12pt)[
    The RS-232 FujiNet Network Adapter for MS-DOS])
  #v(1fr)
  #align(center, image("images/fujinet-rs232-hero.png", width: 2.7in))
  #v(1fr)
  #align(center, text(size: 9.5pt)[
    The FujiNet Community#h(10pt)·#h(10pt)fujinet.online])
]

// ============================================================
// EDITION / COPYRIGHT
// ============================================================
#page(footer: none)[
  #v(1fr)
  #set text(size: 9.5pt)
  #set par(justify: true, leading: 0.6em)
  #strong[First Edition (2026)]
  #v(6pt)
  The drawings of the Personal Computer and its rear panel in this Guide
  are stylized illustrations, drawn for clarity. The drawings of the
  FujiNet are rendered from the published FujiNet RS232-Rev1b hardware
  models. Your unit may differ in small details as the design improves.
  #v(6pt)
  Throughout this Guide, the names of the FujiNet drivers, utilities, and
  CONFIG screens are reproduced exactly as they appear on your computer, so
  that what you read here matches what you see there.
  #v(6pt)
  FujiNet is free and open. The firmware, the CONFIG program, the MS-DOS
  drivers and utilities, the hardware design, and this manual are all
  released under free-software and open-hardware licenses. Sources for
  everything live at #url("github.com/FujiNetWIFI") .
  #v(10pt)
  #align(center, text(size: 9pt)[© 2026 The FujiNet Community · Copy freely])
  #v(0.5in)
]

// ============================================================
// PREFACE
// ============================================================
#show-folio.update(true)
#sec-state.update((name: "Preface", num: 0))
#sec-page.update(1)

#v(0.1in)
#text(font: f-body, weight: 700, size: 16pt)[Preface]
#v(2pt)
#line(length: 100%, stroke: 1.6pt + rule-c)
#v(0.25in)

This Guide introduces you to the #strong[RS-232 FujiNet] — a small adapter
that plugs into the serial port of an IBM Personal Computer, or any close
compatible, and gives it three things the original machine never dreamed
of: virtual disk drives that hold their contents on the internet, a
doorway onto your wireless network, and a printer that files its pages
away as neat documents.

#v(0.1in)
This publication is intended for anyone who will be setting up and using a
FujiNet, whether or not they have ever used one before. No prior knowledge
of networks is assumed. If you can switch on your computer and put a
diskette in a drive, you already know enough to begin.

#v(0.1in)
This Guide has six sections:

#bl[#strong[Section 1. Introduction] describes what the FujiNet is, what
comes with it, and the handful of things you supply yourself.]
#bl[#strong[Section 2. Setup] takes you from the box to a working FujiNet:
connecting it, installing its two drivers, and running a short test to
confirm all is well.]
#bl[#strong[Section 3. Operations] is the heart of the Guide. It teaches
the CONFIG program, the virtual disk drives, the network utilities, and
the printer. New users should read it through; old hands may use it for
reference.]
#bl[#strong[Section 4. Problem Determination Procedures] helps you find and
cure trouble, should any arise.]
#bl[#strong[Section 5. Reference] collects the command summaries, the
driver settings, and the list of network protocols in one place.]
#bl[#strong[Section 6. Relocate] tells you how to move your system safely.]

// ============================================================
// THE EASY WAY TO START
// ============================================================
#pagebreak(weak: true)
#v(0.1in)
#text(font: f-body, weight: 700, size: 16pt)[The Easy Way to Start]
#v(2pt)
#line(length: 100%, stroke: 1.6pt + rule-c)
#v(0.25in)

The fastest way through this Guide is to follow the black tabs printed
along the edge of the right-hand pages. Each marks a major section, and
together they trace the path from an unopened box to a computer that is
on the network.

#bl[#strong[SETUP] — connect the FujiNet to your serial port, install its
two drivers, and prove it is working.]
#bl[#strong[OPERATIONS] — the learning-and-reference section. Read it once
and you will know how to join your network, load disks, copy files, and
print. Behind it sit smaller tabs for the parts you will reach for often:
CONFIG, DISKS, NETWORK, and PRINTER.]
#bl[#strong[PDPs] — the Problem Determination Procedures. If anything
misbehaves, turn here first; the steps are written to be followed in
order, top to bottom.]
#bl[#strong[REFERENCE] — every command and setting, gathered for the day
you need a quick reminder.]

#v(0.2in)
#note[If you are the sort of person who likes to switch a thing on and see
what it does, skip to #strong[Section 2] now. The FujiNet is hard to hurt
and easy to reset, and you can always come back here.]

// ============================================================
// CONTENTS
// ============================================================
#pagebreak(weak: true)
#show-folio.update(false)
#v(0.15in)
#align(center, text(font: f-body, weight: 700, size: 20pt)[Contents])
#v(0.3in)

#let dots = box(width: 1fr, inset: (bottom: 1.5pt),
  align(bottom, repeat(text(size: 9pt)[.#h(3pt)])))

#context {
  let marks = query(metadata).filter(m =>
    type(m.value) == dictionary and m.value.at("kind", default: "") == "chapter")
  for m in marks {
    block(above: 0.9em, below: 0.2em, {
      text(font: f-body, weight: 700, size: 11pt,
        [Section #m.value.num.#h(5pt)#m.value.title])
      box(width: 1fr, inset: (bottom: 1.5pt),
        align(bottom, repeat(text(size: 9pt)[.#h(3pt)])))
      text(font: f-body, weight: 700, size: 11pt,
        [#m.value.num\-1])
    })
    if m.value.subs.len() > 0 {
      block(above: 0pt, below: 0.3em, inset: (left: 0.3in, right: 0.4in),
        par(leading: 0.6em, justify: false,
          text(size: 9.5pt, m.value.subs.join(text(fill: rule-c)[ · ]))))
    }
  }
}

#show-folio.update(true)

// ============================================================
// SECTION 1 — INTRODUCTION
// ============================================================
#chapter("Introduction", num: 1, tab: "Intro",
  subs: ("What the FujiNet Does", "Configuration Examples",
         "What You Supply", "A Tour of the FujiNet"))
#ix("FujiNet, described", "RS-232 FujiNet")

Welcome to the world of the FujiNet. Your new adapter turns the serial
port on the back of your Personal Computer into a doorway — onto your
wireless network, onto a worldwide library of software, and onto a printer
that never runs out of paper. Plug it in, and a machine designed before
the network existed joins the network anyway.

In spite of its reach, the FujiNet is simple to operate, and #emph[you]
decide how technical you want it to be. At the simplest level you load its
CONFIG program, pick a disk off a menu, and start computing. Everything
else this Guide describes is there for the day you want it.

#sect[What the FujiNet Does]
#ix("Disk images", "Virtual drives")

The FujiNet wears three hats at once:

#bl[#strong[Virtual disk drives.] The FujiNet pretends to be a stack of
ordinary diskette drives. Where a real drive reads a floppy, the FujiNet
reads a #strong[disk image] — an exact copy of a diskette, kept as a file
on a memory card or out on the network. DOS cannot tell the difference,
and does not need to: as far as it knows, a drive answered the call. These
appear as new drive letters, #kw("C:"), #kw("D:"), and beyond.]

#bl[#strong[A network adapter.] A small radio inside the FujiNet joins your
household wireless network. Programs written for the FujiNet can read the
news, fetch the weather, call bulletin boards, and play games against real
people across the world. A set of plain-DOS utilities — #kw("NCOPY"),
#kw("NGET"), #kw("NPUT"), and #kw("FNSHARE") — let any computer copy files
to and from the network without special software.]

#bl[#strong[A printer.] The FujiNet can stand in for a printer on
#kw("LPT1:"). Anything your programs print is captured by the FujiNet and
filed away as a finished document you can collect later.]

#sect[Configuration Examples]

A typical setup is shown below: an IBM Personal Computer with its display
and keyboard, and the FujiNet on the serial port at the rear. No card to
install, no case to open.

#figcap[#image("images/ibm-pc-system.png", width: 78%)
#v(4pt)
The Personal Computer — System Unit, Display, and Keyboard. The FujiNet
attaches to the serial port on the back of the System Unit.]

#sect[What You Supply]
#ix("Requirements")

The FujiNet supplies the network. You supply the rest, and you very likely
have it already:

#bl[A #strong[Personal Computer] — an IBM PC, PC/XT, PC/AT, or any close
compatible — running #strong[MS-DOS] (or PC DOS) version 3.0 or later.]
#bl[A free #strong[serial port] (a COM port). Most computers have one as a
9-pin connector on the back; some older machines have a 25-pin connector,
for which an inexpensive 9-to-25-pin adapter is used.]
#bl[A source of #strong[USB power] for the FujiNet — a common USB wall
charger, or a USB port on the computer. The FujiNet does #emph[not] draw
its power from the serial port.]
#bl[A #strong[2.4-gigahertz wireless network] and its password.]
#bl[Optionally, a #strong[microSD memory card] (64 GB or smaller, formatted
FAT32) to hold a disk library of your own.]

#note[The FujiNet's radio speaks the 2.4-gigahertz band only — the band
every router still provides. If your network hides its 2.4-gigahertz band
behind the same name as a 5-gigahertz band and the FujiNet has trouble
joining, give the slower band its own name in the router's settings.]

// --------------------------------------------------------------
#pagebreak(weak: true)
#sect[A Tour of the FujiNet]
#ix("Lamps (LED indicators)", "Buttons", "Connector, DB-9",
  "microSD card", "USB-C")

Take a moment to get acquainted before you plug anything in. Hold the
FujiNet with its label up and its silver connector pointing away from you.

#figcap[#image("images/fujinet-rs232-top.png", height: 2.7in)
#v(4pt)
The FujiNet, seen from above. The serial connector is at the top; the
reset button is at the lower edge.]

#bl[#strong[The serial connector] — the silver 9-pin D-connector at the
front. This is the plug that mates with your computer's serial port. A
#strong[knurled thumbscrew] stands at each side of it; finger-tight, they
hold the FujiNet firmly to the computer.]

#bl[#strong[The WiFi lamp (white)] — on the top face near the connector. It
glows steadily once the FujiNet has joined your wireless network.]

#bl[#strong[The bus lamp (orange)] — beside the WiFi lamp. It flickers when
the computer and the FujiNet are talking — the FujiNet's version of the
"in use" light on a diskette drive.]

#bl[#strong[Button A] — a small button on the top face. You will use it only
when updating the FujiNet's firmware; in everyday use it is left alone.]

#bl[#strong[The Reset button] — at the rear edge, opposite the connector.
Pressing it restarts the FujiNet itself. It does #emph[not] restart your
computer, and it is perfectly safe to press.]

#bl[#strong[The USB-C jack] — on the rear edge. This is where the FujiNet
takes its power, and how new firmware is loaded.]

#bl[#strong[The microSD card slot] — on the rear edge. A memory card slides
in here, contacts up; push to seat it, push again to release. The card is
optional, but it gives you a disk library that needs no network at all.]

// ============================================================
// SECTION 2 — SETUP
// ============================================================
#chapter("Setup", num: 2, tab: "Setup",
  subs: ("Connecting the FujiNet", "The FujiNet Tools Diskette",
         "Installing the Drivers", "First Power-On", "The Mini-Test",
         "Summary"))
#ix("Setup", "Installation")

This section takes you from an unopened box to a working FujiNet. There
are four short jobs: connect the adapter, copy its drivers onto a DOS
diskette, tell DOS to load them, and switch on. Take them in order and you
will be on the network in a few minutes.

#caution[Switch the computer OFF before connecting or disconnecting the
FujiNet from the serial port. The serial port is not designed to be
plugged and unplugged with the power on.]

#sect[Connecting the FujiNet]
#ix("Serial port", "COM port", "Power, USB-C", "Thumbscrews")

#step(1)[#strong[Find the serial port.] Look at the back of the System Unit
for a #strong[9-pin D-shaped connector] with the pins showing — this is
the serial port, also called the COM port. On a computer with more than
one, the first is #strong[COM1].]

#figcap[#image("images/ibm-pc-rear.png", width: 86%)
#v(4pt)
The back panel. The serial (COM) port is one of the D-shaped connectors
among the option-card openings.]

#step(2)[#strong[Mate the connectors.] With the computer #strong[off], push
the FujiNet's connector squarely onto the serial port. It fits only one
way. Turn the two knurled thumbscrews finger-tight to hold it — snug is
plenty; they are not meant to be forced.]

#note[If your computer's serial port has #strong[25 pins] instead of 9, fit
an inexpensive 9-pin-to-25-pin serial adapter between the FujiNet and the
port. Any electronics counter has them. Wire the FujiNet to a 9-pin end.]

#step(3)[#strong[Supply power.] Connect a USB-C cable from the FujiNet to a
USB wall charger or a USB port. The lamps on top flicker as it starts up,
then the white WiFi lamp waits, unlit, until the FujiNet has a network to
join.]

#step(4)[That is the whole hardware installation. There is no card to seat
and no case to open. Leave the FujiNet powered; the rest of the work is
done in software.]

// --------------------------------------------------------------
#pagebreak(weak: true)
#sect[The FujiNet Tools Diskette]
#ix("FujiNet Tools diskette", "FUJINET.SYS", "FUJIPRN.SYS")

The FujiNet's drivers and utilities arrive as a small collection of files
— the #strong[FujiNet Tools]. You will find them on the diskette image
supplied with your FujiNet, or as a download from #url("fujinet.online") .
The collection holds:

#block(breakable: false, table(columns: (auto, 1fr), align: (left, left),
  stroke: 0.6pt + rule-c, inset: 6pt,
  table.header(
    text(weight: 700)[File], text(weight: 700)[What it is]),
  kw("FUJINET.SYS"), [The disk-drive driver — loads in CONFIG.SYS],
  kw("FUJIPRN.SYS"), [The printer driver — loads in CONFIG.SYS],
  kw("CONFIG.EXE"),  [The CONFIG program — the menu you live in],
  kw("FMOUNT.EXE"),  [Mounts and ejects disk images from DOS],
  kw("NCOPY.EXE"),   [Copies files to and from the network],
  kw("NGET.EXE"), [Downloads one file from a network address],
  kw("NPUT.EXE"), [Uploads one file to a network address],
  kw("FNSHARE.EXE"), [Maps a network share to a drive letter],
))

#step(1)[Copy these files onto your everyday #strong[DOS system diskette]
(or your hard disk), the same disk you start the computer from. They take
very little room. If the FujiNet came with a ready-made bootable diskette
image, you may simply start the computer from it instead.]

#note[The FujiNet provides its drives over the serial cable, but DOS itself
must come from somewhere the computer can already start from — a diskette
or a hard disk. The FujiNet's drives appear #emph[after] DOS is running
and the drivers are loaded.]

#sect[Installing the Drivers]
#ix("CONFIG.SYS", "AUTOEXEC.BAT", "DEVICE=")

Two files on your start-up disk tell DOS what to do at switch-on:
#kw("CONFIG.SYS") and #kw("AUTOEXEC.BAT"). Add the FujiNet to each with any
text editor.

#step(1)[Add these two lines to #kw("CONFIG.SYS"). The first loads the disk
driver; the second loads the printer driver:]

#listing[DEVICE=FUJINET.SYS FUJI_PORT=1 FUJI_BPS=115200\
DEVICE=FUJIPRN.SYS]

#step(2)[Add this line to the end of #kw("AUTOEXEC.BAT") so the CONFIG
program greets you at every start-up:]

#listing[CONFIG.EXE]

The two settings on the #kw("FUJINET.SYS") line are worth knowing:

#bl[#kw("FUJI_PORT") names the serial port: #kw("1") for COM1, #kw("2") for
COM2, and so on. Set it to the port you used. (For an unusual port you may
give an address and interrupt directly, as in
#kw("FUJI_PORT=0x2F8,3") .)]
#bl[#kw("FUJI_BPS") sets the speed, in bits per second. #kw("115200") is
the standard, and matches a FujiNet as it ships. Both ends must agree; if
you ever change the FujiNet's speed, change it here to match.]

#note[Leave the two driver lines near the top of #kw("CONFIG.SYS"). If you
prefer the computer not to set its clock from the FujiNet, add the word
#kw("NOTIME") to the #kw("FUJINET.SYS") line.]

// --------------------------------------------------------------
#pagebreak(weak: true)
#sect[First Power-On]
#ix("Power-on", "Driver banner", "Drive letters")

With the FujiNet connected and powered, and the drivers installed, restart
the computer. Watch the screen as DOS starts:

#step(1)[As #kw("CONFIG.SYS") is read, the FujiNet driver announces itself.
The exact numbers will differ, but the shape of the message is always the
same:]

#listing[FujiNet driver 0.8 Open Watcom 2.0 on MS-DOS 6.2]

#step(2)[Seeing that line means #kw("FUJINET.SYS") loaded, found the FujiNet
across the serial cable, and added a set of new disk-drive letters —
beginning at #kw("C:") (or the next free letter after your real drives).
If you asked it to, the FujiNet also quietly set the computer's clock to
the correct date and time, fetched from the internet.]

#step(3)[When #kw("AUTOEXEC.BAT") reaches #kw("CONFIG.EXE"), the CONFIG
program fills the screen. The very first time, it begins by scanning for
wireless networks (Section 3). After that, it opens straight to its main
menu.]

#note[If the driver prints a message that it could #emph[not] find the
FujiNet, the computer started up normally but no FujiNet drives were
added. Turn to #strong[Section 4, Problem Determination Procedures]; the
usual causes are the wrong COM port or a loose connector.]

#sect[The Mini-Test]
#ix("Mini-test", "FMOUNT")

Here is a thirty-second check that everything is talking. Leave CONFIG (or,
if it has not started, work at the DOS prompt) and type:

#listing[FMOUNT]

The FujiNet answers with a list of the drive letters it has provided, and
what is in each — the disk equivalent of a roll-call:

#lst(
  "\u{25AC}\u{25AC}\u{25AC} C: R 2:DISK1.IMG",
  "    D: -- no disk selected --",
  "    E: -- no disk selected --",
)

If you see your FujiNet drive letters listed, the adapter, the cable, the
serial port, and the drivers are all working together. Your FujiNet has
passed its self-test, and you are ready for Section 3.

#sect[Summary]

This completes Setup. You have connected the FujiNet to the serial port,
given it power, copied its drivers onto your start-up disk, told DOS to
load them, and confirmed that the computer and the FujiNet are talking.

From now on, every time you switch on, the FujiNet's drives appear by
themselves and the CONFIG program greets you. You are ready to join your
network and load your first disk.

// ============================================================
// SCREEN BUILDING HELPERS (CP437 boxes, bars, rows)
// ============================================================
#let _clip(s, w) = {
  let c = s.clusters()
  if c.len() >= w { c.slice(0, w).join() } else { s + sp(w - c.len()) }
}
#let hdrbar(title) = {
  let pad = 80 - title.clusters().len()
  let l = calc.floor(pad / 2)
  srow(bar(sp(l) + title + sp(pad - l)))
}
#let ctrline(title) = {                      // centered bright-white line
  let pad = 80 - title.clusters().len()
  let l = calc.floor(pad / 2)
  full(b_(sp(l) + title))
}
#let boxtop(title) = {
  if title == "" {
    full(b_("\u{250C}" + rp("\u{2500}", 78) + "\u{2510}"))
  } else {
    let t = " " + title + " "
    let len = t.clusters().len()
    let l = calc.floor((78 - len) / 2)
    full(b_("\u{250C}" + rp("\u{2500}", l) + t + rp("\u{2500}", 78 - l - len) + "\u{2510}"))
  }
}
#let boxbot() = full(b_("\u{2514}" + rp("\u{2500}", 78) + "\u{2518}"))
#let brow(inner) = srow(b_("\u{2502}"), n_(_clip(inner, 78)), b_("\u{2502}"))
#let browb(inner) = srow(b_("\u{2502}"), b_(_clip(inner, 78)), b_("\u{2502}"))
#let brsel(inner) = srow(b_("\u{2502}"), sel(_clip(inner, 78)), b_("\u{2502}"))
#let blankrow() = full(n_(""))

// ============================================================
// SECTION 3 — OPERATIONS
// ============================================================
#chapter("Operations", num: 3, tab: "Operations",
  subs: ("Getting CONFIG Ready", "Joining Your Network", "Host & Drive Slots",
         "Loading Disks", "Leaving CONFIG", "The Drive Letters",
         "Mounting from DOS", "The Network Utilities", "Mapping a Share",
         "The Printer", "Using DOS"))

This section is the heart of the Guide. It teaches the CONFIG program — the
menu you will use to join your network and load disks — and then the
plain-DOS utilities that copy files, map network shares, and print. New
users should read it through once; afterward it serves as a handy
reference.

#sect[Getting CONFIG Ready]
#ix("CONFIG program", "Screen layout")

CONFIG runs whenever #kw("CONFIG.EXE") is started — automatically at every
switch-on, or by typing #kw("CONFIG") at the DOS prompt. It fills the
screen with a tidy display in the familiar style of the DOS Editor: a
title bar across the top, your working area in the middle, and a
#strong[status bar] across the very bottom that always lists the keys you
can press right now.

#note[Throughout CONFIG, the keys you can press are shown in the bottom
status bar inside square brackets, like #kw("[ENTER]") and #kw("[ESC]").
When in doubt, read that bottom line: it always tells you what to do
next.]

#sect[Joining Your Network]
#ix("WiFi setup", "Networks, scanning for", "Password, network")

The first time CONFIG runs, it scans the airwaves and lists every wireless
network it can hear. The signal-strength bars at the right show which are
near (#kw("\u{2593}\u{2593}\u{2593}")) and which are far
(#kw("\u{2591}")).

#crt(
  hdrbar("Welcome to FujiNet!"),
  ctrline("MAC: D0:1C:ED:C0:FF:EE"),
  boxtop("Available Networks"),
  brsel("HOMEBASE" + sp(63) + "\u{2593}\u{2593}\u{2593}"),
  brow("COCO-NUT" + sp(64) + "\u{2592}\u{2592}"),
  brow("RAINBOW-GUEST" + sp(60) + "\u{2591}"),
  brow("CAFE-DEL-MAR" + sp(61) + "\u{2591}"),
  brow("<Enter a specific SSID>"),
  brow(""), brow(""), brow(""),
  boxbot(),
  hdrbar("[ENTER] Select   [ESC] Re-scan   [S] Skip"),
)
#figcap[The network scan. The bright bar marks your place; the arrow keys
move it.]

To join a network:

#bl[Press #kw("\u{2191}") and #kw("\u{2193}") to move the bright bar to your
network, then #kw("[ENTER]").]
#bl[If your network does not broadcast its name, move to
#kw("<Enter a specific SSID>"), press #kw("[ENTER]"), and type the name.]
#bl[Press #kw("[ESC]") to scan again, or #kw("[S]") to skip the network for
now and set it up later.]

When you choose a network, CONFIG asks for the password. Type it carefully
— capitals count — and press #kw("[ENTER]"). Each character shows as an
asterisk:

#crt(
  hdrbar("Welcome to FujiNet!"),
  ctrline("MAC: D0:1C:ED:C0:FF:EE"),
  boxtop("Available Networks"),
  brow("HOMEBASE" + sp(63) + "\u{2593}\u{2593}\u{2593}"),
  brow(""), brow(""), brow(""), brow(""),
  boxbot(),
  blankrow(),
  ctrline("[ ****************                                ]"),
  hdrbar("Enter password and press [ENTER]"),
)
#figcap[Entering the network password.]

Press #kw("[ENTER]") and the FujiNet joins up. The white WiFi lamp comes on
and stays on. Your network name and password are remembered inside the
FujiNet, so from now on it reconnects by itself, before the screen has
even warmed up.

#sect[The Configuration Screen]
#ix("Configuration screen", "IP address", "Network Info")

To see the FujiNet's vital signs at any time, press #kw("[C]") from the main
screen. CONFIG shows the network it has joined, the address it was given,
and its firmware version:

#crt(
  hdrbar("FujiNet Config"),
  blankrow(), blankrow(),
  boxtop("Network Info"),
  brow("        SSID: HOMEBASE"),
  brow("    Hostname: FUJINET"),
  brow("  IP Address: 192.168.001.073"),
  brow("     Gateway: 192.168.001.001"),
  brow("         DNS: 192.168.001.001"),
  brow("     Netmask: 255.255.255.000"),
  brow("         MAC: D0:1C:ED:C0:FF:EE"),
  brow("       BSSID: A4:2B:8C:11:0D:E5"),
  brow("     Version: V1.5.2"),
  boxbot(),
  hdrbar("[R]econnect   Change [S]SID   [Any key] Return"),
)
#figcap[The Configuration screen. Note the IP Address line.]

#note[Note the #strong[IP Address] line. While the computer is on, the
FujiNet serves a full settings page to any web browser in the house. From a
modern computer or telephone, visit that address (for example
#url("http://192.168.1.73") ) to rename the device, manage WiFi, choose
printer styles, and update firmware from a comfortable chair.]

// --------------------------------------------------------------
#pagebreak(weak: true)
#sect[Host Slots and Drive Slots]
#ix("Host slots", "Drive slots")

Once you are on the network, CONFIG shows its main screen. It is two short
lists, one above the other, and once you can read them you can do
everything.

#crt(
  hdrbar("FujiNet Config"),
  blankrow(),
  boxtop("HOST SLOTS"),
  brsel(" 1  SD"),
  brow(" 2  apps.irata.online"),
  brow(" 3  tnfs.fujinet.online"),
  brow(" 4  Empty"),
  brow(" 5  Empty"),
  brow(" 6  Empty"),
  brow(" 7  Empty"),
  brow(" 8  Empty"),
  boxbot(),
  boxtop("DRIVE SLOTS"),
  brow("2 1R C: GAMES.IMG"),
  brow("3 2R D: NEWS.IMG"),
  brow("  3  E: Empty"),
  brow("  4  F: Empty"),
  brow("  5  G: Empty"),
  brow("  6  H: Empty"),
  brow("  7  I: Empty"),
  brow("  8  J: Empty"),
  boxbot(),
  hdrbar("[1-8] [E]dit  [RET] Browse  [C]onfig  [TAB] Drives  [ESC] Exit"),
)
#figcap[The main screen: Host Slots above, Drive Slots below.]

A #strong[host] is any place disk images live: a library on the internet, a
file server on your own network, or a microSD card (always called
#kw("SD")). The FujiNet remembers eight of them — the #strong[host slots].

A #strong[drive slot] is one of the disk drives your computer sees. Loading
a disk image into a drive slot is the FujiNet's way of sliding a diskette
into a drive — and each drive slot shows the DOS drive letter it answers
to (#kw("C:"), #kw("D:"), and so on).

#subsect[On the Host Slots]
#bl[#kw("\u{2191}") #kw("\u{2193}") move the bright bar; #kw("[1]")–#kw("[8]")
jump straight to a slot.]
#bl[#kw("[E]") edits the highlighted slot — type a host name (up to 32
characters) and press #kw("[ENTER]").]
#bl[#kw("[ENTER]") opens the highlighted host so you can browse it.]
#bl[#kw("[TAB]") switches down to the Drive Slots list.]
#bl[#kw("[ESC]") leaves CONFIG and starts computing.]

Out of the box, slot 1 is #kw("SD") and another slot points at a public
library. Worthwhile libraries to type into an empty slot include:

#bl[#kw("tnfs.fujinet.online") — the community's main library]
#bl[#kw("apps.irata.online") — applications and on-line services]

#sect[Loading a Disk]
#ix("Browsing disk images", "Mounting a disk image", "Read-only and read/write")

Move the bar to a host, press #kw("[ENTER]"), and CONFIG opens its catalog.
Names ending in #kw("/") are folders; step into the one for your machine.

#crt(
  hdrbar("Disk Images"),
  boxtop(""),
  brow("Host: tnfs.fujinet.online"),
  brow("Fltr: "),
  brow("Path: /MSDOS/"),
  boxbot(),
  boxtop(""),
  brsel("   GAMES.IMG"),
  brow("   LANDER.IMG"),
  brow("   NEWS.IMG"),
  brow("   TOOLS.IMG"),
  brow("   WEATHER.IMG"),
  brow(""), brow(""),
  boxbot(),
  hdrbar("[BKSP] Up Dir  [N]ew  [F]ilter  [C]opy  [ENTER] Choose  [ESC] Abort"),
)
#figcap[Browsing a library. Folders end in a slash; disk images do not.]

#bl[#kw("\u{2191}") #kw("\u{2193}") move the bar. Keep going past the bottom
and the next page of names slides in.]
#bl[#kw("[ENTER]") opens a folder, or chooses a disk image.]
#bl[#kw("[BKSP]") backs out to the folder above.]
#bl[#kw("[F]") types a filter, like #kw("W*.IMG"), to show only matching
names. An empty filter clears it.]

Put the bar on a disk image, press #kw("[ENTER]"), and CONFIG asks which
drive slot it should go in, showing the file's details while you decide:

#crt(
  hdrbar("Mount to Drive Slot"),
  boxtop("Drive Slots"),
  brsel("  1  C: Empty"),
  brow("  2  D: Empty"),
  brow("  3  E: Empty"),
  brow("  4  F: Empty"),
  boxbot(),
  boxtop("File Details"),
  brow("/MSDOS/GAMES.IMG"),
  brow("Date: 2026-05-30  16:20:08"),
  brow("Size: 360 K"),
  boxbot(),
  hdrbar("[ENTER] Read Only  [W] Read/Write  [E]ject  [ESC] Abort"),
)
#figcap[Choosing a drive slot for the disk.]

#bl[#kw("\u{2191}") #kw("\u{2193}") choose a drive slot.]
#bl[#kw("[ENTER]") loads it #strong[read-only] — nothing can change it, like
a diskette with the write-notch covered.]
#bl[#kw("[W]") loads it #strong[read/write] — programs may save onto the
image.]
#bl[#kw("[E]") ejects whatever is in the slot.]

#note[Public libraries do not allow writing, so load their disks read-only
— the #kw("[ENTER]") key. Save #kw("[W]") for disks on your own SD card or
your own server.]

#sect[Leaving CONFIG]
#ix("Booting", "Mounting all slots")

When your disks are loaded, press #kw("[ESC]"). CONFIG announces
#kw("Mounting all slots...") and hands control back to DOS. Your loaded
disks are waiting at their drive letters — type #kw("DIR C:") and see.

#sect[New Disks and Copies]
#ix("New disk images, creating", "Copying disk images")

While browsing a host you can write to (your SD card, say), press
#kw("[N]") to make a brand-new, blank disk image. CONFIG offers the
familiar PC diskette sizes — #kw("[1] 360K"), #kw("[2] 720K"),
#kw("[3] 1.2MB"), #kw("[4] 1.44MB") — then asks for a name. The new image
appears in the folder, blank and ready to format with the DOS #kw("FORMAT")
command.

To keep a copy of something from a network library, highlight it and press
#kw("[C]"). CONFIG asks which host to copy #emph[to] — choose #kw("SD") —
lets you pick the folder, and copies the file across with no help from the
computer's memory at all.

// --------------------------------------------------------------
#pagebreak(weak: true)
#sect[The Drive Letters]
#ix("Drive letters", "C: drive")

Each FujiNet drive slot answers to an ordinary DOS drive letter. The driver
hands out the next free letters after your real drives — usually
#kw("C:"), #kw("D:"), and onward — and they behave exactly like diskette
drives. Once a disk image is loaded into a slot, you can:

#lst(
  "DIR C:",
  "COPY C:*.* D:",
  "A:\\> C:",
  "C:\\> _",
)

There is nothing new to learn. #kw("DIR"), #kw("COPY"), #kw("TYPE"),
#kw("FORMAT"), and the rest work on FujiNet drives just as they do on real
ones. A disk loaded #emph[read/write] can be written to; a #emph[read-only]
disk politely refuses, the same as a diskette with its notch covered.

#sect[Mounting Disks from DOS]
#ix("FMOUNT", "Mounting from DOS")

You need not return to CONFIG to manage disks. The #kw("FMOUNT") command
does the same jobs from the DOS prompt. Typed alone, it lists your FujiNet
drives and what is in each:

#lst(
  "C:\\> FMOUNT",
  "\u{25AC}\u{25AC}\u{25AC} C: R 2:GAMES.IMG",
  "\u{2500}\u{25A0}\u{2500} D: R 3:NEWS.IMG",
  "    E: -- no disk selected --",
)

The little mark at the left tells the state of each drive: three bars for a
disk that is loaded and ready, a barred dash for one chosen but not yet
mounted, and blank for an empty slot. With options, #kw("FMOUNT") loads and
ejects:

#block(breakable: false, table(columns: (auto, 1fr), align: (left, left),
  stroke: 0.6pt + rule-c, inset: 6pt,
  table.header(text(weight: 700)[Command], text(weight: 700)[What it does]),
  kw("FMOUNT -a"),    [Mount every slot that has a disk chosen],
  kw("FMOUNT C:"),    [Mount the disk chosen for drive C:],
  kw("FMOUNT -w C:"), [Mount drive C: read/write],
  kw("FMOUNT -e C:"), [Eject the disk in drive C:],
  kw("FMOUNT -t 2"),  [Show which drive letter slot 2 became],
))

#sect[The Network Utilities]
#ix("NCOPY", "NGET", "NPUT", "Network protocols")

Three small programs let any DOS program — or you, by hand — reach across
the network without knowing a thing about it. They address the network
through #strong[N: names]: a protocol, a colon, and an address, such as
#kw("N:HTTP://") or #kw("N:TNFS://") . The protocols the FujiNet
understands are listed in Section 5.

#subsect[NGET — fetch one file]
Give it a network address and a name to save under:

#lst(
  "C:\\> NGET N:HTTP://example.com/files/manual.txt MANUAL.TXT",
  "      4096 bytes transferred.",
)

#subsect[NPUT — send one file]
The mirror image — a local file, then where to put it:

#lst(
  "C:\\> NPUT REPORT.TXT N:TNFS://192.168.1.10/uploads/REPORT.TXT",
)

#subsect[NCOPY — a file-copying conversation]
For more than one file, #kw("NCOPY") opens an interactive session on a host.
At its #kw("ncopy>") prompt you can list, change folders, and copy in both
directions:

#lst(
  "C:\\> NCOPY N:TNFS://tnfs.fujinet.online/",
  "ncopy> dir",
  "MSDOS/         <DIR>     2026-May-01 09:14",
  "README.TXT       812     2026-Apr-22 18:03",
  "ncopy> cd MSDOS",
  "ncopy> get TOOLS.IMG TOOLS.IMG",
  "ncopy> quit",
)

The commands are few and plain: #kw("dir") (or #kw("ls")) to list,
#kw("cd") to change folder, #kw("get") to fetch a file, #kw("put") to send
one, and #kw("quit") to finish. If the host needs a name and password,
#kw("NCOPY") asks for them.

#sect[Mapping a Network Share]
#ix("FNSHARE", "Network share", "Drive mapping")

#kw("FNSHARE") goes one step further: it makes a whole network folder
appear as a DOS drive letter, so #kw("DIR"), #kw("COPY"), and your programs
can use it as if it were a local disk. It stays resident after you run it.

#lst(
  "C:\\> FNSHARE map L: N:TNFS://192.168.1.10/shared",
  "FujiNet installed as L:",
)

From then on, #kw("L:") is the shared folder. If the server asks for a name
and password, #kw("FNSHARE") prompts for them before mapping the drive.

#note[#kw("FNSHARE") maps a #strong[folder of ordinary files] to a drive
letter, which is perfect for documents and programs. To run software from a
#strong[disk image], load it into a drive slot with CONFIG or #kw("FMOUNT")
instead.]

// --------------------------------------------------------------
#pagebreak(weak: true)
#sect[The Printer]
#ix("Printer", "FUJIPRN.SYS", "LPT1")

The second driver, #kw("FUJIPRN.SYS"), gives you a printer that never jams,
never runs dry, and files every page away for you. Once it is loaded,
anything the computer sends to #kw("LPT1:") — the first printer — goes to
the FujiNet instead of out a cable.

Use it exactly as you would a real printer:

#lst(
  "C:\\> COPY README.TXT LPT1:",
  "C:\\> PRINT REPORT.TXT",
)

You may also press #kw("Shift-PrtSc") to print the screen, or use the
#kw("Print") command in your favorite program. Whatever you send, the
FujiNet collects and turns into a tidy document — by default, a PDF you can
read or print on a modern machine.

#step(1)[Print from any program, the ordinary way.]
#step(2)[Open the FujiNet's web page (the address on the Configuration
screen) in a browser on a modern computer or telephone.]
#step(3)[Find your printout waiting there, ready to view, save, or print on
a real printer.]

#note[The FujiNet can imitate several kinds of printer — a plain-text page,
a dot-matrix style, and others — and you choose which from its web page.
For everyday DOS text, the standard setting needs no attention at all.]

#sect[Using DOS with the FujiNet]
#ix("Using DOS")

There is little to add: a FujiNet drive #emph[is] a DOS drive. You can make
one of them the current drive, run programs from it, save your work onto a
read/write disk, and switch between disks by loading different images into
the slots. A few friendly reminders:

#bl[Load a disk #strong[read/write] before expecting to save onto it.
Read-only is the safe default, and the usual choice for software you have
fetched from a public library.]
#bl[A blank image you made with #kw("[N]ew") is truly blank — give it a
file system with #kw("FORMAT") before first use, the same as a fresh
diskette.]
#bl[When you are finished, there is no need to "eject" anything. Switch off
when you like; your disk images are safe on their card or server.]

#v(0.2in)
#align(center, line(length: 40%, stroke: 0.6pt + rule-c))

// ============================================================
// SECTION 4 — PROBLEM DETERMINATION PROCEDURES
// ============================================================
#chapter("Problem Determination Procedures", num: 4, tab: "PDPs",
  subs: ("Start Here", "The Symptom Tables"))

When something does not behave, this section helps you find the cause and
cure it. Work through the steps for your symptom in order, top to bottom,
and stop as soon as the trouble clears.

#sect[Start Here]
Before consulting the tables, check the three things that cause most
trouble:

#step(1)[#strong[Power.] Is the FujiNet's USB cable connected to a live
source? The lamps on top should light when it starts.]
#step(2)[#strong[The connector.] Is the FujiNet pushed fully onto the
serial port, with both thumbscrews snug? A connector half-seated is the
commonest fault of all.]
#step(3)[#strong[The port.] Does the #kw("FUJI_PORT") setting in
#kw("CONFIG.SYS") name the port you actually used — #kw("1") for COM1,
#kw("2") for COM2?]

If all three are sound and trouble remains, find your symptom below.

#sect[The Symptom Tables]

#let pdp(symptom, cure) = block(breakable: false, above: 0.9em, below: 0.9em, {
  grid(columns: (1fr), row-gutter: 4pt,
    text(weight: 700)[Symptom: #symptom],
    par(leading: 0.56em, justify: true, cure))
  v(2pt)
  line(length: 100%, stroke: 0.4pt + rgb("#b8b2a8"))
})

#pdp[At start-up the driver says it cannot find the FujiNet.][
The driver loaded but got no answer over the cable. Switch off, and check
that the FujiNet is powered and firmly connected. Confirm
#kw("FUJI_PORT") names the right COM port. If you set an unusual speed,
make sure #kw("FUJI_BPS") matches the speed the FujiNet expects (the
standard is #kw("115200")). Then switch on again.]

#pdp[No new drive letters appear, and no message from the driver.][
The driver line is not being read. Check that #kw("DEVICE=FUJINET.SYS") is
in #kw("CONFIG.SYS"), spelled correctly, and that #kw("FUJINET.SYS") is
really on the start-up disk. Restart and watch for the driver's banner.]

#pdp[Characters on the FujiNet drives are garbled, or files copy wrong.][
The two ends are talking at different speeds, or the serial port is
unreliable. Make #kw("FUJI_BPS") match the FujiNet's speed. If trouble
persists, try a slower speed at both ends (for example #kw("19200")), or a
different serial port.]

#pdp[CONFIG will not join the wireless network.][
Check the password — capitals count. Make sure the network offers a
#strong[2.4-gigahertz] band; the FujiNet cannot use 5-gigahertz-only
networks. Move the FujiNet nearer the router, or press #kw("[ESC]") to
re-scan and pick a network with stronger signal bars.]

#pdp[A host slot will not open, or shows no files.][
Check the host name for a typo. A public server may be busy or down; the
current list of working servers is kept at the FujiNet web site. Confirm
the white WiFi lamp is lit — without a network, no host can be reached.]

#pdp[A program cannot save to a FujiNet drive.][
The disk is loaded read-only. In CONFIG, put the bar on the drive in the
Drive Slots list and press #kw("[W]") to switch it to read/write; or from
DOS, #kw("FMOUNT -w") the drive. Public-library disks cannot be made
writable — copy one to your own card or server first.]

#pdp[Printer output never appears on the FujiNet web page.][
Confirm #kw("DEVICE=FUJIPRN.SYS") is in #kw("CONFIG.SYS") and loaded. Make
sure your program prints to #kw("LPT1:"). Give the FujiNet a moment to
finish the document, then refresh its web page.]

#pdp[A FujiNet drive letter clashes with another disk or network drive.][
Another driver claimed the same letters. Load #kw("FUJINET.SYS") earlier in
#kw("CONFIG.SYS"), or adjust the other driver, so each gets its own range
of letters. Use #kw("FMOUNT") to see which letters the FujiNet received.]

#v(0.2in)
#note[If a symptom is not listed here, or a cure does not work, the
community is glad to help. See #strong[Getting Help] at the back of this
Guide — bring the exact wording of any message you saw.]

// ============================================================
// SECTION 5 — REFERENCE
// ============================================================
#chapter("Reference", num: 5, tab: "Reference",
  subs: ("Driver Settings", "The CONFIG Keys", "Command Summary",
         "Network Protocols", "Disk Image Sizes"))

This section gathers the settings and commands in one place, for the day
you need a quick reminder.

#sect[Driver Settings]
#ix("FUJI_PORT", "FUJI_BPS", "NOTIME")

These go on the #kw("DEVICE=FUJINET.SYS") line in #kw("CONFIG.SYS"):

#block(breakable: false, table(columns: (auto, auto, 1fr),
  align: (left, left, left), stroke: 0.6pt + rule-c, inset: 6pt,
  table.header(text(weight: 700)[Setting], text(weight: 700)[Default],
    text(weight: 700)[Meaning]),
  kw("FUJI_PORT"), kw("1"), [Serial port: 1–4, or an address and IRQ such as
    #kw("0x2F8,3")],
  kw("FUJI_BPS"), kw("115200"), [Speed in bits per second; must match the
    FujiNet],
  kw("NOTIME"), [—], [If present, do not set the DOS clock from the FujiNet],
))

#sect[The CONFIG Keys]

#block(breakable: false, table(columns: (auto, 1fr),
  align: (left, left), stroke: 0.6pt + rule-c, inset: 6pt,
  table.header(text(weight: 700)[Key], text(weight: 700)[Action]),
  kw("\u{2191} \u{2193}"), [Move the bright bar through a list],
  kw("1") + "–" + kw("8"), [Jump straight to a slot],
  kw("ENTER"), [Choose, open, or (on a disk) load read-only],
  kw("W"), [Load a disk read/write],
  kw("E"), [Edit a host slot, or eject a drive slot],
  kw("TAB"), [Switch between the Host and Drive lists],
  kw("C"), [Show the Configuration (Network Info) screen],
  kw("N"), [Make a new, blank disk image],
  kw("F"), [Filter the file list],
  kw("BKSP"), [Go up one folder],
  kw("ESC"), [Leave CONFIG, mounting all slots],
))

#sect[Command Summary]

#block(breakable: false, table(columns: (auto, 1fr),
  align: (left, left), stroke: 0.6pt + rule-c, inset: 6pt,
  table.header(text(weight: 700)[Command], text(weight: 700)[Purpose]),
  kw("CONFIG"), [Start the full-screen CONFIG program],
  kw("FMOUNT"), [List FujiNet drives and what is loaded],
  kw("FMOUNT -a"), [Mount every slot that has a disk chosen],
  kw("FMOUNT -w C:"), [Mount drive C: read/write],
  kw("FMOUNT -e C:"), [Eject the disk in drive C:],
  kw("FMOUNT -t 2"), [Show the drive letter for slot 2],
  kw("NGET src dest"), [Download one file from an N: address],
  kw("NPUT src dest"), [Upload one file to an N: address],
  kw("NCOPY host"), [Open an interactive copy session on a host],
  kw("FNSHARE map L: url"), [Map a network share to drive L:],
))

Inside #kw("NCOPY"): #kw("dir") or #kw("ls") to list, #kw("cd") to change
folder, #kw("get") and #kw("put") to copy, #kw("quit") to finish.

// --------------------------------------------------------------
#pagebreak(weak: true)
#sect[Network Protocols]
#ix("Network protocols", "N: names")

The network utilities reach the world through #strong[N: names] — a
protocol, a colon, and an address. The FujiNet understands these
protocols; any of them may be used wherever an N: address is asked for:

#block(breakable: false, table(columns: (auto, 1fr),
  align: (left, left), stroke: 0.6pt + rule-c, inset: 6pt,
  table.header(text(weight: 700)[Name], text(weight: 700)[Reaches]),
  kw("N:HTTP://"),  [Web servers (also #kw("HTTPS://") for secure sites)],
  kw("N:TNFS://"),  [TNFS servers — the 8-bit world's disk libraries],
  kw("N:FTP://"),   [File-transfer servers],
  kw("N:SMB://"),   [Windows and Samba shared folders],
  kw("N:NFS://"),   [Unix network-file-system shares],
  kw("N:TCP://"),   [A raw connection to any TCP service],
  kw("N:UDP://"),   [Raw datagrams to any UDP service],
  kw("N:SSH://"),   [A secure shell to another computer],
  kw("N:TELNET://"),[Terminal sessions on bulletin boards and hosts],
))

#note[#kw("FNSHARE") and #kw("NCOPY") work with the file-serving protocols —
#kw("TNFS"), #kw("FTP"), #kw("SMB"), #kw("NFS"), and #kw("HTTP"). The raw
protocols (#kw("TCP"), #kw("UDP"), #kw("TELNET"), #kw("SSH")) are there for
#kw("NGET"), #kw("NPUT"), and for programs written to use the network
directly.]

#sect[Disk Image Sizes]
#ix("Disk image sizes")

When you make a new disk image with #kw("[N]ew"), CONFIG offers the
standard PC diskette formats. After creating one, give it a file system
with the DOS #kw("FORMAT") command, the same as a new diskette.

#block(breakable: false, table(columns: (auto, 1fr),
  align: (left, left), stroke: 0.6pt + rule-c, inset: 6pt,
  table.header(text(weight: 700)[Choice], text(weight: 700)[Format]),
  kw("[1]"), [360 KB — 5.25-inch double-density],
  kw("[2]"), [720 KB — 3.5-inch double-density],
  kw("[3]"), [1.2 MB — 5.25-inch high-density],
  kw("[4]"), [1.44 MB — 3.5-inch high-density],
  kw("[C]"), [Custom — your own sector count and size],
))

// ============================================================
// SECTION 6 — RELOCATE
// ============================================================
#chapter("Relocate", num: 6, tab: "Relocate",
  subs: ("Moving the FujiNet", "Taking It With You"))

Whenever you need to move your system, a few moments' care saves trouble
later. The FujiNet asks little: it is small, light, and has nothing inside
that minds being carried.

#sect[Moving the FujiNet]

#step(1)[Switch the computer #strong[off].]
#step(2)[Loosen the two thumbscrews and lift the FujiNet straight off the
serial port. Unplug its USB power.]
#step(3)[If a microSD card is fitted, you may leave it in place; it is held
securely. Your disk images on it travel with it.]
#step(4)[Pack the FujiNet where it will not be crushed. There are no moving
parts and no diskettes to fall out.]

#sect[Taking It With You]
#ix("Travel", "Different network")

The FujiNet remembers the last network it joined. In a new place, with a
different wireless network, simply press #kw("[C]") in CONFIG, then
#kw("[S]") to change the network, and choose the new one from the scan —
exactly as you did the first time (Section 3). Everything else carries on
as before.

#note[Away from any network, the FujiNet still serves disk images from its
microSD card. A library on the card needs no internet, no router, and no
password — handy for a club meeting, a class, or a long trip.]

// ============================================================
// GETTING HELP / BACK MATTER
// ============================================================
#chapter("Getting Help", num: 7, tab: "Help",
  subs: ())
#ix("Getting help", "Community")

The FujiNet is the work of a worldwide community of enthusiasts, and that
community is friendly and quick to help. If this Guide has not answered
your question, here is where to turn:

#bl[#strong[The FujiNet web site] — #url("fujinet.online") . Downloads,
documentation, the firmware updater, and a current list of public
libraries.]
#bl[#strong[The FujiNet chat server] — a link is on the web site. Ask a
question and a real person usually answers within the hour.]
#bl[#strong[The FujiNet users' group] — for show-and-tell, tips, and
troubleshooting among fellow owners.]
#bl[#strong[The source code] — #url("github.com/FujiNetWIFI") . Everything
that makes the FujiNet work is open for you to read, learn from, and
improve.]

#v(0.2in)
When you ask for help, it speeds things along to mention: which computer
and version of DOS you use, which serial port and speed, the firmware
version from the Configuration screen, and the exact wording of any
message you saw.

#v(0.3in)
#align(center, block(width: 78%, {
  set par(justify: false)
  set align(center)
  text(font: f-body, style: "italic", size: 11pt)[
    Welcome to the network. We are glad you are here.]
}))

#v(1fr)
#align(center, striped(
  text(font: f-body, weight: 700, size: 18pt, fill: ink)[FujiNet],
  stripe: paper, n: 7))
#v(4pt)
#align(center, text(size: 9pt)[The FujiNet Community · A worldwide
free-software project · #url("fujinet.online")])
