// ============================================================
// GETTING STARTED WITH FUJINET
// for the Apple II family
//
// Designed after the 1984 "Apple IIc Owner's Manual"
// (Apple Computer, Inc. — the Snow White era): cream stock,
// warm red rules, Helvetica heads, the wide scholar's margin
// with notes and Important! tags. All serif text is set in
// Apple Garamond (ITC Garamond Condensed), Apple's corporate
// face, per Thom — in place of the original's Century.
//
// CONFIG screens are typeset in the genuine Apple II charset
// (Print Char 21) with strings taken verbatim from
// fujinet-config src/apple2/screen.c.
//
// Build: typst compile --font-path fonts manual.typ
// ============================================================

// ---------- photographs -------------------------------------
// Thom's photos. Flip an entry to true once the file exists in
// images/ — placeholders render automatically until then.
// (See FIGURES.md for the shot list.)
#let photos = (
  "cover-photo.jpg": true,
  "parts-spread.jpg": true,
  "fujiapple-front.jpg": true,
  "fujiapple-rear.jpg": true,
  "db19-adapter.jpg": true,
  "hookup-iic.jpg": true,
  "hookup-iigs.jpg": true,
  "liron-card.jpg": true,
  "softsp-diskii.jpg": true,
  "microsd.jpg": false,
)

// ---------- fonts -------------------------------------------
#let f-body = "Apple Garamond"         // Apple's corporate serif (ITC
                                       // Garamond Condensed) — all body,
                                       // titles, contents, folios
#let f-head = "Helvetica"              // section heads, tags, keycaps
#let f-scrn = "Print Char 21"          // genuine Apple II 40-col charset

// ---------- palette -----------------------------------------
#let paper  = rgb("#f6f0dd")   // cream stock
#let ink    = rgb("#2b2620")   // letterpress near-black
#let red    = rgb("#f43b50")   // the Apple manual warm red (coral)
#let ph-bg  = rgb("#ebe3c9")   // photo placeholder fill
#let scr-bg = rgb("#0d120e")   // monitor glass
#let scr-fg = rgb("#5fec87")   // green phosphor (Monitor IIc)

// ---------- geometry ----------------------------------------
#let col-w   = 4.65in          // main text column
#let mhang   = 1.75in          // reach back into the margin
#let mnote-w = 1.5in           // margin note width
#let bleed-l = 2.3in           // left margin (to page edge)

// ============================================================
// COMPONENTS
// ============================================================

#let fst = state("folio-style", "none")  // "none" | "roman" | "arabic"

// repeat string s, n times
#let rp(s, n) = range(n).map(_ => s).join("")

// "Apple IIc" — Apple's own manuals write "IIc", not "//c". Boxed so
// the name never wraps across a line.
#let iic = box("IIc")

// running-head / TOC marks
#let chmark(label, title) = metadata((kind: "chapter", label: label, title: title))
#let smark(title) = metadata((kind: "section", title: title))

// --- the page foot: red running head, serif folio at outer edge ---
#let foot = context {
  let st = fst.get()
  if st == "none" { return }
  let p = counter(page).get().first()
  let num = if st == "roman" { numbering("i", p) } else { numbering("1", p) }
  let marks = query(metadata).filter(m =>
    type(m.value) == dictionary and m.value.at("kind", default: "") in ("chapter", "section"))
  let pg = here().page()
  let prior = marks.filter(m => m.location().page() <= pg)
  let rh = if prior.len() > 0 {
    let v = prior.last().value
    if v.kind == "chapter" { v.label + ": " + v.title } else { v.title }
  } else { none }
  if rh != none {
    place(center + horizon, text(font: f-body, size: 8.2pt, fill: red, rh))
  }
  let folio = text(font: f-body, size: 9.6pt, fill: ink, num)
  if calc.even(p) {
    place(left + horizon, dx: -bleed-l + 0.55in, folio)
  } else {
    place(right + horizon, folio)
  }
}

// --- chapter / preface / appendix opener ---
#let chapter(label, title, banner: none, bdesc: none) = {
  pagebreak(weak: true, to: "odd")
  chmark(label, title)
  // margin label with its short red rule
  place(dx: -mhang, dy: 6pt, box(width: mnote-w, {
    rect(width: 0.62in, height: 1.3pt, fill: red)
    v(2pt)
    text(font: f-body, size: 13.5pt, fill: ink, label)
  }))
  // title with red rule above
  block(width: 100%, {
    rect(width: 2.9in, height: 1.3pt, fill: red)
    v(1pt)
    text(font: f-body, size: 22pt, fill: ink, title)
  })
  if banner != none {
    v(0.3in)
    line(length: 100%, stroke: 0.8pt + red)
    v(9pt)
    banner
    v(9pt)
    line(length: 100%, stroke: 0.8pt + red)
  }
  v(0.3in)
}

// --- section head: Helvetica Bold over a thick red rule that
//     runs from the page edge to the end of the column ---
#let sect(title) = block(above: 1.7em, below: 1em, breakable: false, sticky: true, {
  smark(title)
  text(font: f-head, weight: 700, size: 10.5pt, fill: ink, title)
  v(1.5pt)
  move(dx: -bleed-l, rect(width: bleed-l + col-w, height: 3.2pt, fill: red))
})

// --- sub-head: Helvetica Bold with a short red underline ---
#let subsect(title) = block(above: 1.4em, below: 0.75em, breakable: false, sticky: true, context {
  let t = text(font: f-head, weight: 700, size: 9.5pt, fill: ink, title)
  let w = measure(t).width
  t
  v(1pt)
  rect(width: w + 2pt, height: 2.5pt, fill: red)
})

// --- margin note (the scholar's margin) ---
#let mnote(body, dy: 1pt) = place(dx: -mhang, dy: dy, box(width: mnote-w,
  par(leading: 0.45em, spacing: 0.5em, first-line-indent: 0pt, justify: false,
    text(font: f-body, size: 8.5pt, fill: ink, body))))

// --- set-off text with a hairline at its left, tag in the margin ---
#let setoff(tag, body) = block(above: 1em, below: 1em, {
  if tag != none {
    place(dx: -mhang, dy: 1pt, box(width: mnote-w, align(left, tag)))
  }
  block(width: 100%, stroke: (left: 1pt + ink), inset: (left: 10pt, y: 2pt),
    par(text(size: 10pt, body)))
})
#let important(body) = setoff(
  text(font: f-head, weight: 700, size: 9pt, fill: red, "Important!"), body)
#let warning(body) = setoff({
  box(baseline: 0.5pt, polygon(fill: red, (0pt, 7pt), (4pt, 0pt), (8pt, 7pt)))
  h(4pt)
  text(font: f-head, weight: 700, size: 9pt, fill: red, "Warning")
}, body)
#let byway(body) = setoff(none, [*By the Way:* #body])

// --- square black bullets, IIc style ---
#let sq(body) = block(above: 0.5em, below: 0.5em,
  grid(columns: (0.18in, 1fr),
    move(dy: 2.6pt, square(size: 4.2pt, fill: ink)),
    par(leading: 0.5em, first-line-indent: 0pt, body)))

// --- drawn keycap ---
#let key(l) = box(baseline: 24%, rect(
  fill: rgb("#fbf6e8"), stroke: 0.75pt + ink.lighten(15%), radius: 2.8pt,
  inset: (x: 3.4pt, y: 2.4pt),
  text(font: f-head, weight: 400, size: 6.2pt, tracking: 0.3pt, fill: ink, upper(l))))
// the open-apple key, drawn with the genuine MouseText glyph (nudged
// up so it centres in the cap like the lettered keys)
#let key-oa = box(baseline: 24%, rect(
  fill: rgb("#fbf6e8"), stroke: 0.75pt + ink.lighten(15%), radius: 2.8pt,
  inset: (x: 3.4pt, y: 2.4pt),
  move(dy: -1.1pt, text(font: f-scrn, size: 6.6pt, fill: ink, "\u{F813}"))))

// --- "you type it" text, in the Apple II charset ---
#let tt(s) = text(font: f-scrn, size: 7pt, fill: ink, s)
// inverse-video run of the Apple II charset, on paper (ink box, paper
// glyphs) — for naming an inverse key inline, e.g. the "E" in "Edit"
#let ttinv(s) = box(fill: ink, outset: (y: 0.6pt), inset: (x: 0.3pt),
  text(font: f-scrn, size: 7pt, fill: paper, s))

// --- photographs & placeholders ---
#let phimg(file, desc, height: 2.2in) = {
  if photos.at(file, default: false) {
    align(center, image("images/" + file, height: height))
  } else {
    rect(width: 100%, height: height, fill: ph-bg,
      stroke: (paint: ink.lighten(35%), thickness: 0.7pt, dash: "dashed"),
      align(center + horizon, par(justify: false, leading: 0.6em,
        text(font: f-body, size: 8pt, fill: ink.lighten(15%),
          "[ PHOTO: " + file + " ]\n") +
        text(font: f-body, size: 8pt, style: "italic", fill: ink.lighten(15%), desc))))
  }
}

// --- numbered figure: serif caption over a thin red rule ---
// notes: ((dy, content), ...) margin callouts that travel with the
// figure (placed inside its unbreakable block, dy from caption top)
#let fig(num, title, file, desc, height: 2.2in, notes: ()) = block(
  breakable: false, above: 1.3em, below: 1.3em, {
  for n in notes {
    place(dx: -mhang, dy: n.at(0), box(width: mnote-w,
      par(leading: 0.45em, spacing: 0.5em, first-line-indent: 0pt, justify: false,
        text(font: f-body, size: 8.5pt, fill: ink, n.at(1)))))
  }
  text(font: f-body, size: 9.4pt, fill: ink)[Figure #num. #title]
  v(3pt)
  line(length: 100%, stroke: 0.9pt + red)
  v(7pt)
  phimg(file, desc, height: height)
})

// ============================================================
// CONFIG SCREENS (Print Char 21, green phosphor)
// ============================================================

#let scr-size = 6.5pt

// inverse video
#let iv(s) = box(fill: scr-fg, outset: (y: 0.55pt), text(fill: scr-bg, s))
// a whole 40-column line, padded then inverted (the selection bar)
#let bar40(s) = iv(s + rp(" ", calc.max(0, 40 - s.len())))
// menu item: inverse key, normal rest
#let mi(k, rest) = iv(k) + rest

// the monitor: black glass, rounded corners, 40 columns
#let scr(..ls) = align(center, block(breakable: false, above: 1.15em, below: 1.15em,
  box(fill: scr-bg, radius: 8pt, inset: (x: 14pt, top: 12pt, bottom: 12pt), {
    set text(font: f-scrn, size: scr-size, fill: scr-fg)
    set par(leading: 0.42em, spacing: 0.42em, first-line-indent: 0pt, justify: false)
    set align(left)
    ls.pos().map(l => if l == "" { par(text(" ")) } else { par(l) }).join()
  })))

// screen caption (numbered like figures, but for typeset screens);
// sticky so the caption never widows at the foot of a page — it
// travels to the next page with its screen
#let scrcap(num, title) = block(above: 1.3em, below: 0.4em, sticky: true, {
  text(font: f-body, size: 9.4pt, fill: ink)[Figure #num. #title]
  v(3pt)
  line(length: 100%, stroke: 0.9pt + red)
})

// ============================================================
// DOCUMENT SETUP
// ============================================================
#set text(font: f-body, size: 10.4pt, fill: ink)
#set par(leading: 0.55em, spacing: 0.7em, justify: true, first-line-indent: 0pt)
#set strong(delta: 300)
#set page(width: 7.5in, height: 9in, fill: paper,
  margin: (left: bleed-l, right: 0.55in, top: 0.7in, bottom: 0.85in),
  footer: foot, footer-descent: 42%)
#set enum(numbering: "1.", indent: 0pt, body-indent: 8pt, spacing: 0.85em)

// ============================================================
// FRONT COVER
// ============================================================
#page(margin: 0pt, footer: none)[
  #place(top + left, dx: 0.6in, dy: 0.55in,
    image("images/fujinet-logo.png", width: 1.15in))
  #place(top + left, dx: 2.0in, dy: 0.52in,
    text(font: f-body, size: 30pt, fill: ink)[Getting Started with FujiNet])
  #place(top + left, dx: 2.0in, dy: 0.98in,
    text(font: f-body, size: 14.5pt, style: "italic", fill: ink)[for the Apple II])

  #place(top + left, dx: 1.1in, dy: 1.7in, box(width: 5.3in,
    phimg("cover-photo.jpg",
      "FujiNet plugged into an Apple IIc, CONFIG on the monitor",
      height: 5.4in)))

  #place(bottom + left, dx: 2.0in, dy: -0.62in, box(width: 4.6in,
    par(leading: 0.5em, justify: false,
      text(font: f-body, size: 12.5pt, fill: ink)[
        Including #text(style: "italic")[CONFIG: An Interactive Guide
        to Disk Drives Without Disks].])))
]

// ============================================================
// INSIDE FRONT COVER — Free Software / Copyright
// ============================================================
#page(margin: (x: 0.6in, y: 0.65in), footer: none)[
  #set text(size: 9.2pt)
  #set par(leading: 0.5em, spacing: 0.62em, justify: true)
  #grid(columns: (1fr, 1fr), column-gutter: 0.45in, row-gutter: 0pt,
    {
      subsect("Free Software")
      par[FujiNet's firmware, the CONFIG program, and this manual are
      free software, built and given away by a worldwide community of
      Apple II owners. You may copy this manual for a friend — in fact,
      we'd be delighted. Source for everything, this booklet included,
      lives at #text(font: f-head, size: 8pt)[github.com/FujiNetWIFI].]

      subsect("Limitation on Warranties and Liability")
      par[Even though the FujiNet community has tested the software and
      reviewed its contents, neither the community nor its contributors
      make any warranty or representation with respect to this manual
      or to FujiNet, their quality, performance, merchantability, or
      fitness for any particular purpose. Everything is provided "as
      is." But unlike 1984, when something bothers you, you can read
      the source, fix it yourself, and send a pull request.]
    },
    {
      subsect("Copyright")
      par[This manual is typeset in loving tribute to the 1984 #text(
      style: "italic")[Apple IIc Owner's Manual]. Apple, the Apple
      logo, Apple IIc, Apple IIGS, ProDOS, and SmartPort are trademarks
      of Apple Inc. Liron and UniDisk are trademarks of Apple Inc.
      FujiNet is a community project and is not affiliated with,
      endorsed by, or sponsored by Apple Inc.]

      par[Copyright 2026 the FujiNet contributors. Released under the GNU
      General Public License v3 as part of the
      #text(font: f-head, size: 8pt)[fujinet-manuals] repository.]

      par[CONFIG screens in this manual are typeset in the genuine
      Apple II character set, with text taken verbatim from the CONFIG
      source code.]

      v(6pt)
      par[This manual is dedicated to everyone who kept an Apple II
      running into its fifth decade — and to those who sent in their
      ideas, bug reports, and pull requests.]

      par[In the Apple tradition, we listened to you, and learned from
      you. Keep those cards coming!]
    })
]

// ============================================================
// TITLE PAGE
// ============================================================
#counter(page).update(3)
#page[
  #v(0.1in)
  #place(dx: -mhang, dy: 4pt,
    image("images/fujinet-logo.png", width: 1.05in))
  #rect(width: 2.9in, height: 1.3pt, fill: red)
  #v(1pt)
  #text(font: f-body, size: 24pt)[Getting Started with FujiNet]
  #v(2pt)
  #par(leading: 0.5em, text(font: f-body, size: 12.5pt, style: "italic")[
    An owner's guide to the WiFi peripheral and its CONFIG program,
    for the Apple #iic, Apple IIc Plus, Apple IIGS, and every Apple II
    with a SmartPort.])

  #v(0.55in)
  #line(length: 100%, stroke: 0.8pt + red)
  #v(9pt)
  #phimg("parts-spread.jpg",
    "flat-lay: FujiApple, DB-19 adapter, IDC20 cable, microSD card",
    height: 2.9in)
  #v(9pt)
  #line(length: 100%, stroke: 0.8pt + red)
]

// ============================================================
// CONTENTS
// ============================================================
#pagebreak(weak: true)
#fst.update("roman")
#block(width: 100%, {
  rect(width: 2.9in, height: 1.3pt, fill: red)
  v(1pt)
  text(font: f-body, size: 22pt)[Contents]
})
#v(0.4in)
#context {
  let marks = query(metadata).filter(m =>
    type(m.value) == dictionary and m.value.at("kind", default: "") in ("chapter", "section"))
  for m in marks {
    let loc = m.location()
    let p = counter(page).at(loc).first()
    let style = fst.at(loc)
    let num = if style == "roman" { numbering("i", p) } else { numbering("1", p) }
    if m.value.kind == "chapter" {
      block(above: 1.35em, below: 0.55em, {
        place(dx: -mhang, box(width: mnote-w,
          text(font: f-body, size: 9.2pt, fill: red, tracking: 0.6pt,
            upper(m.value.label))))
        text(font: f-body, weight: 700, size: 10.6pt, m.value.title)
        h(1fr)
        text(font: f-body, size: 10.6pt, num)
      })
    } else {
      block(above: 0pt, below: 0.5em,
        text(font: f-body, size: 10pt, m.value.title + "  " + num))
    }
  }
}

// ============================================================
// PREFACE — Welcome to the Network
// ============================================================
#chapter("Preface", "Welcome to the Network")

When you plugged a disk drive into your Apple II, you gave it a
memory. When you plug in a FujiNet, you give it the world — and you
don't have to give up anything to get it. No slots are used up
(unless you want them to be), no software has to be rewritten, and
nothing about your Apple changes. As far as your computer knows, a
FujiNet is simply a chain of fast, well-behaved disk drives. The
difference is where those disks live: on a memory card the size of
your thumbnail, on a server in your closet, or on a library on the
other side of the world.

Learning to use it should be part of the fun — and it is fun, with
*CONFIG*, the built-in program your Apple loads from the FujiNet the
moment you switch it on.

#sect("What You'll Learn")

This guide will help you get comfortable with your FujiNet. The
guide will

#sq[show you how to hook the FujiNet up to your particular Apple II —
whether it has a built-in SmartPort or needs a card's worth of help]
#sq[walk you through joining your wireless network the first time]
#sq[teach you CONFIG: browsing disk collections, mounting and booting
disks, making new blank disks, and copying files from host to host]
#sq[introduce the rest of the FujiNet's bag of tricks — the printer,
the clock, the modem, the Lobby, and the web control panel.]

#sect("What You'll Need")

#sq[A FujiNet for the Apple II (the *FujiApple*), with the cable or
adapter that fits your machine — Chapter 2 sorts this out.]
#sq[An Apple II with SmartPort: an Apple #iic (most ROMs), IIc Plus,
or IIGS right out of the box; an Apple II Plus or IIe with a
SmartPort-capable controller card.]
#sq[A 2.4 GHz WiFi network and its password.]
#sq[Optionally, a microSD card (FAT32) if you'd like your disk
library to live right inside the FujiNet.]

#sect("How It Works")

#mnote[Computer jargon is *boldfaced* when it is introduced, and
explained right here in the margin.]
This book borrows its manners from the manual that came with the
Apple IIc in 1984. Explanations of new terms — and asides that
didn't fit in the main story — appear in this wide margin.

Look for these other visual cues throughout the manual:

#important[Text set off in this manner — with a tag in the margin —
presents important information.]

#warning[Text set off like this indicates potential problems or
disasters.]

#byway[Text set off in this manner presents sidelights or
interesting pieces of information.]

Keys look like this: #key("ESC"), #key-oa, #key("RETURN"). When you
see a hyphen joining two keys, it means to press them
simultaneously: #key("CONTROL")\-#key("RESET") means hold down
#key("CONTROL") while you press #key("RESET").

You will also see a special typeface used for what you type and for
what appears on the screen: #tt("PR#5") looks like that. Whole
screens appear the way they look on a green monochrome monitor, set
in the genuine Apple II character set.

// ============================================================
// CHAPTER 1 — Meet Your FujiNet
// ============================================================
// the body of the book counts in arabic, starting at 1
#pagebreak(weak: true, to: "odd")
#counter(page).update(1)
#fst.update("arabic")
#chapter("Chapter 1", "Meet Your FujiNet",
  banner: phimg("parts-spread.jpg",
    "the FujiApple with DB-19 adapter, IDC20 cable, and microSD card",
    height: 2.5in))

Take a minute to get acquainted before you plug anything in. The
FujiNet for the Apple II is a small device — about the size of a
deck of cards — that connects to your Apple's disk port and to your
home network at the same time, and spends its life translating
between the two.

#fig("1-1", "The FujiNet", "fujiapple-front.jpg",
  "FujiApple front: LEDs, buttons, microSD slot visible",
  height: 2.4in,
  notes: (
    (0.45in, [*Lights:* the white lamp glows when the FujiNet
is connected to your WiFi network. The amber lamp flickers with
disk-port activity, just like the in-use lamp on a disk drive.]),
    (1.55in, [*Buttons:* one is the reset button, which
restarts the FujiNet (not the Apple). The other, button A, is
reserved for future tricks.]),
  ))

#sect("The Cast of Characters")

Out of the box, a FujiNet setup has only a few pieces:

#sq[*The FujiNet itself*, with one 20-pin disk connector (an *IDC20*,
two rows of ten pins — the same connector found on the original
Disk II controller card).]
#sq[*A DB-19 adapter*, which converts that connector to the 19-pin
D-shaped disk port found on the back of the Apple #iic, IIc Plus,
IIGS, and Laser 128.]
#sq[*A microSD card slot* (push to insert, push to eject). A card is
optional — it must be formatted FAT32 — and gives your FujiNet a
built-in disk library.]
#sq[*A USB-C connector*, used for firmware updates. The FujiNet is
powered by the Apple through the disk cable, so USB power is
optional — plug it in only if you want the FujiNet awake (for its
web control panel) while the Apple is switched off.]

#fig("1-2", "The business end", "fujiapple-rear.jpg",
  "FujiApple rear/side: IDC20 disk connector and USB-C",
  height: 2.1in)

There is no power switch. Switch on the Apple and the FujiNet wakes
up; switch it off and the FujiNet goes to sleep. It draws its power
from the disk port, the same way a real drive does.

#sect("What Your Apple Thinks It Is")

#mnote[*SmartPort* is Apple's protocol for intelligent disk devices,
introduced with the UniDisk 3.5. A SmartPort host can address many
drives — and other devices besides — through one connector.]
The FujiNet introduces itself to your Apple as a daisy chain of
SmartPort devices:

#sq[*Eight disk drives.* Each can hold a disk image up to 32
megabytes — a whole hard disk's worth — served from your network or
the microSD card.]
#sq[*A network adapter*, for programs written to use it (there is a
growing library of them).]
#sq[*A clock*, so ProDOS can finally date your files correctly.]
#sq[*A printer and a modem*, for software that knows how to talk to
them (more in Chapter 6).]
#sq[*A CP/M computer* — an entire emulated Z80 environment, no
SoftCard required.]

It can also pretend to be something much older: a *Disk II*. On
systems wired for it, the FujiNet spins imaginary 5.25-inch disks —
including copy-protected originals in *WOZ* format — convincingly
enough to fool DOS 3.3 itself. Chapter 4 tells that story.

#sect("Handle With Care")

The FujiNet isn't made of porcelain — handle it with care, but not
with kid gloves. Two rules will keep it (and your Apple) healthy:

#warning[Never plug anything into an Apple's disk port while the
power is on. That was true in 1978 and it is true now. Switch off
the Apple first, every time.]

#warning[If you connect with a ribbon cable to a Disk II-style
controller, check the plug's alignment twice before powering up. A
cable offset by one row or column of pins can damage the FujiNet,
the card, or both. No pins should be visible outside the plug.]

#sect("Chapter 1 Summary")

#sq[FujiNet connects your Apple's disk port to your WiFi network.]
#sq[To the Apple it looks like eight SmartPort drives, plus a
clock, printer, modem, network adapter, and CP/M machine.]
#sq[White lamp: WiFi. Amber lamp: disk activity.]
#sq[It is powered by the Apple; there is no power switch.]
#sq[microSD cards are optional and must be FAT32.]
#sq[Power off before connecting anything to the disk port.]

// ============================================================
// CHAPTER 2 — Hooking Up
// ============================================================
#chapter("Chapter 2", "Hooking Up")

Every Apple II since 1977 can join the party, but they don't all
join the same way. Find your machine below, then follow its recipe.

#sect("Which Apple Do You Have?")

#subsect("Born with a SmartPort")

The Apple #iic (most of them), the Apple IIc Plus, the Apple IIGS,
and the Laser 128 all have a SmartPort built into the 19-pin disk
connector on the back panel. For these machines the FujiNet plugs
straight in with the DB-19 adapter — no cards, no fuss.

#mnote[Location 64447 (\$FBBF) holds the ROM version byte. The very first IIc ROM
(version 255) predates the SmartPort protocol and can't boot a
FujiNet — though it can still use one as an emulated Disk II
external drive. Apple offered a free ROM upgrade in 1985; many
machines got it.]
The one exception is the very first Apple #iic ROM. To find out which
ROM your #iic has, switch it on, press #key("CONTROL")\-#key("RESET")
to get a BASIC prompt, and type:

#block(inset: (left: 0.25in), tt("PRINT PEEK(64447)") + h(6pt) + key("RETURN"))

If the answer is *255*, you have the original ROM — SmartPort is not
included. If it's *0*, *3*, or *4*, you're in business; *5* means
you have a IIc Plus, and you're also in business.

#subsect("SmartPort by expansion card")

The Apple II Plus and IIe need a SmartPort added through a slot.
Working options, roughly in order of popularity:

#sq[*A softSP card paired with a 5.25-inch drive controller.* softSP
is a small firmware that teaches an ordinary card to speak
SmartPort — available ready-made (the KBOOHK softSP card, or an
A2Pico running softSP), or as a DIY EPROM for a Grappler+ or Super
Serial Card. The FujiNet then connects to the drive controller
card's disk connector. Use softSP v6 or newer.]
#sq[*A genuine SmartPort card.* The original Apple Liron (the UniDisk
3.5 controller) is the classic, and modern equivalents are easier to
find: A2Heaven's *Liron Reborn*, or the open-source *SmartDiskII*
(a Liron with the IWM swapped for Disk II circuitry). These give
SmartPort drives only — no Disk II emulation — and connect through
the DB-19 adapter or an IDC20 cable.]
#sq[*A Yellowstone card* (Big Mess o' Wires). A modern universal disk
controller. It will serve FujiNet *disk drives* — over an IDC20 cable
only, not the DB-19 adapter, in either SmartPort or Disk II mode but
not both at once. Because it handles the disks itself rather than
passing the bus through, it cannot reach FujiNet's network, printer,
modem, or CP/M devices.]

#byway[An Apple III or III Plus can also play, using a Liron or
softSP card and a driver from the FujiNet apps repository — a story
for a different manual.]

#sect("Connecting to a IIc, IIc Plus, or IIGS")

#fig("2-1", "The DB-19 adapter", "db19-adapter.jpg",
  "DB-19 adapter mated to the FujiApple",
  height: 1.9in)

+ Switch off the Apple and anything attached to it.
+ Fit the DB-19 adapter to the FujiNet's 20-pin connector (directly,
  or through a short ribbon cable).
+ Plug the adapter into the disk port on the back panel — the
  D-shaped, 19-pin connector marked with a disk icon.
+ Remove any floppy from the internal drive, so the Apple doesn't
  boot that instead.
+ Switch on your monitor, then the Apple.

#fig("2-2", "Plugging into the IIc", "hookup-iic.jpg",
  "hand plugging the FujiNet into the IIc external disk port",
  height: 2.3in)

On a #iic or IIc Plus, that's the whole recipe: the machine checks
its disk port at startup, finds the FujiNet, and boots CONFIG all by
itself.

#byway[Have real drives too? While you're learning, the simplest
arrangement is the FujiNet alone on the port. Daisy chains do work —
the time-honored rule still applies: 5.25-inch drives always go last
in the chain.]

#subsect("One extra step on the IIGS")

The IIGS likes to be told where to boot from:

+ Hold down #key("CONTROL") and #key-oa and press #key("ESC") to
  open the Control Panel (at startup or any time).
+ Choose *Slots*.
+ Set *Slot 5* to *Smart Port*, and *Startup Slot* to *5* (or
  *Scan*).
+ Choose *Quit*, and reboot
  (#key("CONTROL")\-#key-oa\-#key("RESET")).

#fig("2-3", "FujiNet on the IIGS", "hookup-iigs.jpg",
  "FujiNet connected to the IIGS rear disk port",
  height: 2.3in)

#sect("Connecting to a II Plus or IIe")

+ Switch off the Apple. (Always.)
+ Seat your SmartPort card combination: for softSP, the softSP (or
  Super Serial/Grappler+ with softSP EPROM) in one slot — slot 5 is
  traditional — and the 5.25-inch drive controller it partners with in
  another, traditionally slot 6.
+ Connect the FujiNet to the drive controller's disk connector: by
  IDC20 ribbon cable to a Disk II-style card, or by the DB-19
  adapter to a card with the D-shaped connector.
+ Triple-check ribbon cable alignment (see the Warning in
  Chapter 1).
+ Switch on the Apple, press #key("CONTROL")\-#key("RESET"), then
  type #tt("PR#5") (or your softSP card's slot number) and press
  #key("RETURN"). CONFIG boots.

#fig("2-5", "A softSP card", "softsp-diskii.jpg",
  "the KBOOHK softSP card, which teaches an ordinary controller to speak SmartPort",
  height: 2.3in)

#important[The FujiNet draws its power from the disk connector, so
there is nothing else to plug in. If you ever want the FujiNet's web
control panel available while the Apple is off, power it separately
through the USB-C connector — otherwise leave USB for firmware
updates.]

#sect("Chapter 2 Summary")

#sq[#iic, IIc Plus, IIGS, Laser 128: attach the DB-19 adapter, plug
into the disk port, power on. (#iic ROM 255 is the exception.)]
#sq[IIGS: Control Panel, Slots: set Slot 5 to Smart Port and the
Startup Slot to 5.]
#sq[II Plus and IIe: add SmartPort with softSP + a drive controller
(or a Liron card), then boot with #tt("PR#5").]
#sq[Always power off before connecting; always check ribbon-cable
alignment.]

// ============================================================
// CHAPTER 3 — Joining Your Network
// ============================================================
#chapter("Chapter 3", "Joining Your Network")

The first time your Apple boots CONFIG, the screen fills with the
FujiNet logo while the device looks around, then gets right down to
introductions: it scans the airwaves and shows you every wireless
network it can hear.

#scrcap("3-1", "Choosing a network")
#scr(
  "         Welcome to FujiNet!",
  "",
  "MAC Address:  4C:11:AE:0D:FA:9C",
  "",
  bar40("  HOMEBASE"),
  "  BRAEBURN" + rp(" ", 26) + "**",
  "  CORTLAND-GUEST" + rp(" ", 20) + "*",
  "", "", "", "", "", "", "", "", "", "", "", "", "", "",
  "          Found 3 networks.",
  "    " + mi("H", "idden SSID  ") + mi("R", "escan  ") + mi("S", "kip"),
  "          " + mi("RETURN", " to select"))

#mnote[The stars at the right are signal strength: three stars is
excellent, one star is "move the antenna."]
Move the highlight bar with the arrow keys and press #key("RETURN")
on your network. Three more keys are on duty here: #key("H") names a
hidden network by hand, #key("R") rescans, and #key("S") skips WiFi
setup entirely.

#mnote[On an Apple II or II Plus there are no up/down arrow keys —
CONFIG accepts #key("I") (up), #key("J") (left), #key("K") (right),
and #key("M") (down) everywhere, plus #key("T") for #key("TAB").]

Next, the password:

#scrcap("3-2", "Entering the password")
#scr(
  "Enter net password and press [RETURN]",
  "] ************_")

Type carefully — passwords are case-sensitive — and press
#key("RETURN"). Characters echo as asterisks, up to 64 of them.

#mnote[On an Apple II or II Plus, which can't type lowercase, CONFIG
shows one more line: "Use [ESC] to switch to upper/lower case."
#key("ESC") toggles the case of the letters you type next.]

CONFIG announces #tt("Connecting to network: ") with your network's
name, the white lamp comes on, and that's that. The FujiNet
remembers the network in its own flash memory (and, if a microSD
card is present, in a file called #tt("fnconfig.ini")), so from now
on it reconnects by itself, every time, before your coffee is
poured.

#important[The FujiNet's radio speaks 2.4 GHz WiFi only. If your
router runs a "mixed" 2.4/5 GHz network under one name, the FujiNet
may have trouble joining — if it does, give the 2.4 GHz band its own
network name.]

#sect("Chapter 3 Summary")

#sq[First boot: CONFIG scans and lists networks; #key("RETURN")
selects, #key("H") enters a hidden name, #key("R") rescans,
#key("S") skips.]
#sq[Passwords: up to 64 characters, case-sensitive, echoed as
asterisks.]
#sq[The network is remembered; reconnection is automatic.]
#sq[2.4 GHz networks only.]

// ============================================================
// CHAPTER 4 — Disks From Thin Air
// ============================================================
#chapter("Chapter 4", "Disks From Thin Air")

Here is the heart of the matter. CONFIG's main screen manages two
lists, and once you can read them, you can do everything.

#mnote[*Host:* any place disk images live. A host can be a *TNFS*
server — a simple file server protocol beloved of 8-bit machines —
named by hostname or IP address; an #tt("SMB://") or #tt("FTP://")
server on your LAN; or the FujiNet's own microSD card, which goes by
the special name #tt("SD").]
The top half is the *host list*: eight slots naming the places your
disk images come from. The bottom half is the *drive list*: the
eight SmartPort drives the Apple sees, and which image (if any) is
loaded in each.

#scrcap("4-1", "The main screen")
#scr(
  rp("─", 30) + " Host List",
  bar40("1 SD"),
  "2 TNFS.FUJINET.ONLINE",
  "3 APPS.IRATA.ONLINE",
  "4 FUJINET.DILLER.ORG",
  "5 Empty",
  "6 Empty",
  "7 Empty",
  "8 Empty",
  "",
  "D─R─H" + rp("─", 18) + " SmartPort Drives",
  "1 R 2:ProDOS.2.4.3.po",
  "2" + rp(" ", 5) + "Empty",
  "3" + rp(" ", 5) + "Empty",
  "4" + rp(" ", 5) + "Empty",
  "5" + rp(" ", 5) + "Empty",
  "6" + rp(" ", 5) + "Empty",
  "7" + rp(" ", 5) + "Empty",
  "8" + rp(" ", 5) + "Empty",
  "", "",
  mi("1-8", ":Host  ") + mi("E", "dit  ") + mi("RETURN", ":Select files"),
  mi("C", "onfig ") + mi("TAB", ":Drives ") + mi("S", "pDevs ") + mi("L", "obby ") + mi("ESC", ":Boot"))

#mnote[Reading a drive line: drive number, then *R* (read-only) or
*W* (read/write), then the host slot the image came from, then the
image's name. The header row — D, R, H — labels those columns.]
The inverse bar is your place marker. #key("TAB") jumps it between
the host list and the drive list; the arrow keys (or #key("I"),
#key("J"), #key("K"), #key("M")) move it; the number keys jump
straight to a slot.

In the menu lines at the bottom, the inverse capital letter is the
key to press: where the screen shows #ttinv("E")#tt("dit"), pressing
#key("E") does the editing.

#sect("Setting Up Hosts")

Press #key("E") on any host slot to edit it, type a name up to 32
characters, and press #key("RETURN"). Out of the box you'll want a
couple of public TNFS libraries and the SD card:

#sq[#tt("SD") — the microSD card inside your FujiNet]
#sq[#tt("TNFS.FUJINET.ONLINE") — the community's main library]
#sq[#tt("APPS.IRATA.ONLINE") — applications and online services]
#sq[#tt("FUJINET.DILLER.ORG") — more disk images]

#byway[Type hostnames in lowercase if you like; they may be shown
in capitals the next time CONFIG loads. The two are the same to a
server. You can also run your own TNFS server on a modern computer —
search for "TNFS daemon" — and serve your whole collection across
the room.]

#sect("Browsing and Mounting")

Highlight a host and press #key("RETURN"). CONFIG opens the host's
catalog:

#scrcap("4-2", "Selecting a disk image")
#scr(
  "TNFS.FUJINET.ONLINE",
  "/Apple II/Games/",
  "",
  "Action/",
  "Arcade/",
  "Utilities/",
  "AppleWorks.2mg",
  "Airheart.po",
  "Choplifter.dsk",
  bar40("Karateka.po"),
  "Lode.Runner.po",
  "Marble.Madness.2mg",
  "Oregon.Trail.po",
  "Prince.of.Persia.po",
  "ProDOS.2.4.3.po",
  "", "", "",
  "[...]",
  "", "",
  mi("RETURN", ":Select file to mount"),
  mi("<-", "Updir  ") + mi("ESC", ":Abort  ") + mi("F", "ilter  ") + mi("N", "ew  ") + mi("C", "opy"))

#mnote[Fifteen entries show per page; #tt("[...]") at top or bottom
means there's more. The #key("<") and #key(">") keys also flip
pages.]
Names ending in #tt("/") are folders — press #key("RETURN") to step
in, and the left arrow (or #key("DELETE")) to step back out. Press
#key("F") to filter a big catalog by wildcard (#tt("*karate*") finds
our hero), and #key("ESC") to go back to the main screen.

Press #key("RETURN") on a disk image and CONFIG asks where to put
it:

#scrcap("4-3", "Choosing a drive")
#scr(
  "",
  rp("─", 23) + " SmartPort Drives",
  "1 R 2:ProDOS.2.4.3.po",
  bar40("2" + rp(" ", 5) + "Empty"),
  "3" + rp(" ", 5) + "Empty",
  "4" + rp(" ", 5) + "Empty",
  "5" + rp(" ", 5) + "Empty",
  "6" + rp(" ", 5) + "Empty",
  "7" + rp(" ", 5) + "Empty",
  "8" + rp(" ", 5) + "Empty",
  "", "", "",
  "File details",
  "  MTime: 2026-06-11 19:02:44",
  "   Size: 140 K",
  "",
  "Karateka.po",
  "", "",
  " " + mi("1-8", " Select drive or use arrow keys"),
  " " + mi("RETURN/R", ":Insert read only"),
  " " + mi("W", ":Insert read/write  ") + mi("ESC", ":Abort"))

Pick a drive and press #key("RETURN") (or #key("R")) to insert the
disk *read-only*, or #key("W") to insert it *read/write*. Read-only
is exactly like sliding the write-protect tab open on a real
floppy: nothing can scribble on the image.

#important[Public TNFS libraries don't allow writing, so mount
their disks read-only. Save the #key("W") key for images on your SD
card or your own server.]

#sect("Booting")

Back on the main screen, with a bootable image in drive 1, press
#key("ESC"). CONFIG announces #tt("RESTARTING...") and restarts the
Apple itself — booting straight into the disk you mounted, just as a
fresh power-on would. To return to CONFIG later, power the Apple off
and on again (a plain #key("CONTROL")\-#key("RESET") won't do it — on
an Apple II that drops you into BASIC or the monitor, it doesn't
reboot the machine).

#byway[How many of the eight drives software sees depends on the
operating system. ProDOS 2.x — including the recommended 2.4.3 —
handles up to fourteen SmartPort drives, so all eight FujiNet slots
are fair game. Only the older ProDOS 1.x was limited to four. Mount
your boot disk in drive 1 and you're safe either way.]

#sect("Managing Drives")

Press #key("TAB") to drop the bar into the drive list. There,
#key("E") ejects the highlighted image, and #key("R") or #key("W")
changes its read-only/read-write mode in place. If a mounted image
has a name too long for the line, the full name appears above the
menu while it's highlighted.

#sect("The Disk II Side")

#mnote[*WOZ* images are bit-perfect recordings of original floppies,
copy protection and all. They only make sense on an emulated
Disk II — a SmartPort drive is far too modern for them.]
Some software refuses to believe in hard disks: DOS 3.3 disks,
copy-protected games, anything that talks to the drive hardware
directly. For those, FujiNet emulates the genuine article. If your
setup includes a Disk II-style controller wired to the FujiNet (the
softSP combination from Chapter 2, for instance), a #key("D") option
appears on the main screen: press it to flip the drive list between
SmartPort view and Disk II view.

#scrcap("4-4", "The drive list, Disk II view")
#scr(
  "D───R─H" + rp("─", 18) + " Disk II Drives",
  bar40("S6D1R 2:Choplifter.woz"),
  "S6D2" + rp(" ", 4) + "Empty",
  "",
  mi("E", "ject  ") + mi("R", "ead only  ") + mi("W", "rite"),
  mi("TAB", ":Host slots  ") + mi("ESC", ":Boot"),
  mi("D", "rives toggle (SP or DiskII)"))

The label tells you which real-world position each emulated disk
occupies — #tt("S6D1") is slot 6, drive 1. Mount 5.25-inch images
(#tt(".dsk"), #tt(".do"), #tt(".po"), #tt(".woz") — 140K only) here,
then boot with #tt("PR#6") just like 1983.

#byway[WOZ images are read-only by nature. Plain 16-sector images
(DSK, DO, PO) can be written to in Disk II mode with current
firmware.]

#sect("Chapter 4 Summary")

#sq[Hosts (top) are where images live; drives (bottom) are what the
Apple sees. #key("TAB") switches lists.]
#sq[#key("E") edits a host; #key("RETURN") browses it.]
#sq[In the browser: #key("RETURN") selects, left arrow goes up,
#key("F") filters, #key("ESC") backs out.]
#sq[Insert read-only with #key("RETURN")/#key("R"), read/write
with #key("W"); eject with #key("E").]
#sq[#key("ESC") on the main screen reboots the Apple into drive 1.]
#sq[#key("D") (when present) switches to Disk II view for DOS 3.3
and WOZ software.]

// ============================================================
// CHAPTER 5 — Making and Copying Disks
// ============================================================
#chapter("Chapter 5", "Making and Copying Disks")

A disk drive that can't make new disks would be a sad thing. Yours
makes them out of nothing at all.

#sect("A Fresh Box of Disks")

While browsing any host you can write to (your SD card, say), press
#key("N"). CONFIG asks three questions in the menu area:

#scrcap("5-1", "The three questions")
#scr(
  iv(" New media: Select type "),
  mi("P", "O  ") + mi("2", "MG  ") + mi("D", "OS 3.3"),
  "",
  iv(" New media: Select size "),
  mi("1", "40K  ") + mi("8", "00K  ") + mi("3", "2MB"),
  "",
  iv(" New media: Enter filename "),
  "] saves.po_")

#sq[*Type.* #key("P") makes a ProDOS-order image (#tt(".po")),
#key("2") a 2MG image, #key("D") a DOS 3.3 image (#tt(".do") —
always 140K, so the size question is skipped).]
#sq[*Size.* #key("1") for a 5.25-inch floppy's 140K, #key("8") for a
3.5-inch floppy's 800K, #key("3") for a 32 MB volume — the largest
ProDOS allows.]
#sq[*Name.* Type it and press #key("RETURN"), including the
extension.]

Then pick which drive to put the new disk in, and it's mounted
read/write, blank as the day it was born.

#byway[There's a secret fourth size: press #key("C") at the size
question and type any number of 512-byte blocks for a custom-sized
volume.]

#important[A new image is like a disk fresh from the shrink-wrap:
it needs formatting before use. Boot your favorite OS and format
it there — ProDOS's filer, or #tt("INIT") under DOS 3.3 — exactly
as you would a real blank disk.]

#sect("Copying From Host to Host")

Found something on a network library you'd like to keep locally?
Highlight the disk image in the browser and press #key("C"). CONFIG asks
which host to copy *to* — pick your SD card — then lets you walk
the destination's folders. When you're standing in the right
folder, press #key("C") again and the FujiNet does the rest,
all by itself, no Apple memory required:

#scrcap("5-2", "A copy in progress")
#scr(
  rp(" ", 14) + "Copying file from:",
  "",
  rp(" ", 13) + "TNFS.FUJINET.ONLINE",
  "/Apple II/Games/Karateka.po",
  "", "", "",
  rp(" ", 16) + "Copying file to:",
  "",
  rp(" ", 38) + "SD",
  "/games/Karateka.po")

#sect("Chapter 5 Summary")

#sq[#key("N") in the browser creates a blank image: type, size,
name, drive.]
#sq[New images need formatting by your OS, like any blank disk.]
#sq[#key("C") copies a disk image between hosts — TNFS library to SD card
is the classic move.]

// ============================================================
// CHAPTER 6 — Beyond the Disk Drive
// ============================================================
#chapter("Chapter 6", "Beyond the Disk Drive")

The disk drives are the headline act, but the FujiNet brought its
whole troupe.

#sect("The Config Screen")

Press #key("C") on the main screen for the FujiNet's vital signs:

#scrcap("6-1", "Show Config")
#scr(
  "", "", "", "", "",
  "   " + iv(" F U J I N E T      C O N F I G "),
  "", "",
  "    SSID: HOMEBASE",
  "Hostname: fujinet",
  "      IP: 192.168.1.99",
  " Netmask: 255.255.255.0",
  "     DNS: 192.168.1.1",
  "     MAC: 4C:11:AE:0D:FA:9C",
  "   BSSID: A4:2B:8C:11:0D:E5",
  "   FNVer: 1.5.1 2026-04-18",
  "  CONFIG: v1.5",
  "", "", "", "",
  "      " + mi("C", "hange SSID  ") + mi("R", "econnect"),
  "   Press any key to return to hosts",
  "      FujiNet printer enabled")

From here #key("C") switches to a different WiFi network and
#key("R") reconnects to the current one. Note the IP address — you
need it for the next trick.

#sect("The Web Control Panel")

#mnote[If your computer can't find #tt("fujinet.local"), the IP
address from the Config screen always works.]
While the FujiNet is powered, it serves a full settings page to any
browser in the house. Visit your FujiNet's IP address — or just
#tt("http://fujinet.local") — from a modern computer, and you can
rename the device, pick printer emulations, adjust the boot
options, manage WiFi, and update firmware, all from a comfortable
chair.

#sect("Roll Call: The SmartPort Device List")

Press #key("S") on the main screen and every SmartPort device the
FujiNet is impersonating answers roll:

#scrcap("6-2", "The whole troupe")
#scr(
  iv(" SMARTPORT DEVICE LIST "),
  "",
  "Unit #1  Name: FUJINET_DISK_0",
  "Unit #2  Name: FUJINET_DISK_1",
  "Unit #3  Name: FUJINET_DISK_2",
  "Unit #4  Name: FUJINET_DISK_3",
  "Unit #5  Name: FUJINET_DISK_4",
  "Unit #6  Name: FUJINET_DISK_5",
  "Unit #7  Name: FUJINET_DISK_6",
  "Unit #8  Name: FUJINET_DISK_7",
  "Unit #9  Name: CPM",
  "Unit #10 Name: FN_CLOCK",
  "Unit #11 Name: NETWORK",
  "Unit #12 Name: THE_FUJI",
  "",
  iv(" Press any key to continue "))

#sect("The Lobby")

Press #key("L") and CONFIG asks #tt("Boot to Lobby? Y/N"). Say yes
and your Apple boots into the *Lobby* — a live directory of online,
multiplayer games being played right now on FujiNet-equipped
8-bit machines everywhere. Pick a game and you're seated at the
table. Yes, against real people. Yes, on your Apple II.

#sect("The Supporting Cast")

#sq[*Printer.* The FujiNet captures printing from SmartPort-aware
software and renders it as a PDF — emulating an Epson-compatible
dot-matrix printer — which you collect from the web control panel.
(On a #iic, printing through the FujiNet takes a custom ROM; ask the
community.)]
#sq[*Clock.* SmartPort-aware software can read the real date and
time, fetched from the network.]
#sq[*Modem.* The emulated modem answers Hayes commands and "dials"
telnet BBSes — yes, they're still out there, and they're lively.]
#sq[*CP/M.* A complete emulated CP/M machine with storage on the
microSD card, for when you want WordStar without a SoftCard.]
#sq[*Network adapter.* A growing catalog of native applications —
weather, news, ISS trackers, multiplayer games — speaks to the
network device directly. Browse the libraries from Chapter 4 and
try things.]

#sect("Keeping Fresh")

New firmware arrives regularly with new tricks. Grab
*FujiNet-Flasher* from #text(font: f-head, size: 8.6pt)[fujinet.online] on a modern
computer, connect the USB-C cable, and you're current in two
minutes. News, documentation, and the community Discord all live at
the same address — when you're stuck, hundreds of fellow travelers
are a message away.

#sect("Chapter 6 Summary")

#sq[#key("C"): vital signs, change network. #key("S"): SmartPort
roll call. #key("L"): the Lobby.]
#sq[The web control panel lives at the FujiNet's IP address or
#tt("fujinet.local").]
#sq[Printer, clock, modem, CP/M, and native network apps round out
the troupe.]
#sq[Firmware updates: FujiNet-Flasher, over USB.]

// ============================================================
// APPENDIX A — Troubleshooting
// ============================================================
#chapter("Appendix A", "Troubleshooting")

The Apple II tradition says: when something goes wrong, stay calm,
check the cable, and read the friendly list.

#subsect("The Apple powers on but CONFIG never appears")

#sq[Is there a floppy in the internal drive? Remove it and reset.]
#sq[On a IIGS — is Slot 5 set to Smart Port and the Startup Slot
to 5 (or Scan)? See Chapter 2.]
#sq[On a II Plus/IIe — CONFIG doesn't auto-boot; press
#key("CONTROL")\-#key("RESET") and type #tt("PR#5") (your softSP
slot).]
#sq[On a #iic — check the ROM: #tt("PRINT PEEK(64447)"). An answer
of 255 means no SmartPort in ROM (Chapter 2).]
#sq[Ribbon cable connections: aligned, fully seated, no stray
pins?]

#subsect("The scan finds no networks, or won't connect")

#sq[The FujiNet hears 2.4 GHz networks only — and mixed 2.4/5 GHz
networks with one name can confuse the radio. Give the 2.4 GHz
band its own name in your router.]
#sq[Hidden network? Press #key("H") and type its name exactly.]
#sq[Passwords are case-sensitive — on a II/II+, remember the
#key("ESC") case toggle while typing.]

#subsect("A host slot won't open")

#sq[Check the spelling (press #key("E") to look).]
#sq[Try a known-good host: #tt("TNFS.FUJINET.ONLINE").]
#sq[For #tt("SD"): is a card inserted, and is it FAT32? exFAT
cards are not recognized.]

#subsect("A mounted disk won't boot")

#sq[The Apple boots SmartPort drive 1 — is your disk there?]
#sq[Is it bootable at all? Many images are data disks.]
#sq[DOS 3.3 and copy-protected (WOZ) software needs the Disk II
side, not a SmartPort drive — see Chapter 4, and boot it with
#tt("PR#6") (or the slot your Disk II controller card is in).]

#subsect("I can't save onto a disk")

#sq[Mounted read-only? Press #key("TAB"), highlight it, press
#key("W").]
#sq[Public TNFS libraries refuse writes no matter what — copy the
image to your SD card first (Chapter 5).]
#sq[WOZ images are always read-only.]

#subsect("Small oddities that are not problems")

#sq[Hostnames typed in lowercase reappear in capitals. Harmless.]
#sq[Booting under ProDOS 1.x and only four of the eight SmartPort
drives appear? That's ProDOS 1.x's four-drive limit, not the
FujiNet — ProDOS 2.x (2.4.3 recommended) sees all eight.]
#sq[The #key("D") drives-toggle only appears when a Disk II-style
controller is detected at boot.]

#subsect("When all else fails")

Visit #text(font: f-head, size: 8.6pt)[fujinet.online] and join the
Discord — the community has seen it all, and loves a good puzzle.

// ============================================================
// APPENDIX B — CONFIG Quick Reference
// ============================================================
#chapter("Appendix B", "CONFIG Quick Reference")

#let qr(..rows) = block(above: 0.6em, below: 1.2em,
  grid(columns: (1.35in, 1fr), column-gutter: 10pt, row-gutter: 7pt,
    ..rows.pos().map(r => (
      align(left, r.at(0)),
      par(leading: 0.45em, first-line-indent: 0pt, justify: false,
        text(size: 9.8pt, r.at(1)))
    )).flatten()))

Anywhere: arrows move the highlight bar; on machines without all
four arrows, #key("I") #key("J") #key("K") #key("M") are up, left,
right, down, and #key("T") stands in for #key("TAB").

#subsect("Main screen — host list")
#qr(
  ([#key("1") – #key("8")], [jump to host slot]),
  ([#key("E")], [edit the highlighted host (32 characters max)]),
  ([#key("RETURN")], [browse the highlighted host]),
  ([#key("TAB")], [switch to the drive list]),
  ([#key("C")], [show config (network details; change SSID)]),
  ([#key("S")], [list all SmartPort devices]),
  ([#key("L")], [boot to the Lobby]),
  ([#key("D")], [toggle SmartPort/Disk II drive view (when shown)]),
  ([#key("ESC")], [reboot the Apple into the mounted disk]))

#subsect("Main screen — drive list")
#qr(
  ([#key("E")], [eject the highlighted image]),
  ([#key("R") \/ #key("W")], [set read-only / read-write]),
  ([#key("TAB")], [back to the host list]),
  ([#key("ESC")], [reboot the Apple into the mounted disk]))

#subsect("File browser")
#qr(
  ([#key("RETURN")], [open folder / select disk image]),
  ([left arrow], [up one folder (also #key("DELETE"))]),
  ([#key("<") #key(">")], [previous / next page]),
  ([#key("F")], [wildcard filter (e.g. #tt("*karate*"))]),
  ([#key("N")], [new blank disk image]),
  ([#key("C")], [copy the highlighted file to another host]),
  ([#key("ESC")], [back to the main screen]))

#subsect("Drive picker (after selecting an image)")
#qr(
  ([#key("1") – #key("8")], [choose a drive]),
  ([#key("RETURN") \/ #key("R")], [insert read-only]),
  ([#key("W")], [insert read/write]),
  ([#key("E")], [eject from the highlighted drive]),
  ([#key("ESC")], [back to the browser]))

#subsect("WiFi setup")
#qr(
  ([#key("RETURN")], [join the highlighted network]),
  ([#key("H")], [enter a hidden network name]),
  ([#key("R")], [rescan]),
  ([#key("S")], [skip WiFi setup]),
  ([#key("ESC")], [(II/II+ only) toggle upper/lower case while
  typing]))

// ============================================================
// TELL FUJINET
// ============================================================
#chapter("Tell FujiNet", "We're Listening")

The back of the 1984 manual carried a postage-paid card: #emph[Tell
Apple. We want to be sure we're giving you the information you need
to get up and running quickly.] We feel exactly the same way — we
just answer faster.

#sq[Found a mistake in this manual? File an issue at
#text(font: f-head, size: 8.6pt)[github.com/FujiNetWIFI/fujinet-manuals].]
#sq[Have an idea for CONFIG or the firmware? The same door is open
at #text(font: f-head, size: 8.6pt)[github.com/FujiNetWIFI].]
#sq[Want to chat with the people who built it? The Discord link
waits at #text(font: f-head, size: 8.6pt)[fujinet.online].]

Let us know what you liked about the manual, and what you'd like us
to do differently. Thanks.

#v(1fr)
#align(center, {
  image("images/fujinet-logo.png", width: 1.6in)
  v(8pt)
  text(font: f-body, size: 9.8pt, style: "italic")[A Worldwide Community Project]
})
#v(0.4in)
