// ============================================================
// PROGRAMMING THE FUJINET
// for the Coleco ADAM
//
// A programmer's guide and command reference for talking to a
// FujiNet from Z80 assembly language over AdamNet — through the
// Elementary Operating System (EOS), and by driving the Device
// Control Blocks directly, as one must under CP/M.
//
// Typeset in tribute to Coleco's own ADAM manuals of 1983: the
// silver cover with its rising pinstripes and rainbow masthead,
// ITC Avant Garde Gothic body, Serpentine bold-oblique heads,
// Handel Gothic display — the visual language established by the
// companion "Getting Started with FujiNet CONFIG for the ADAM."
//
// Every command code, DCB layout, EOS entry point and error
// number in this book is taken verbatim from the fujinet-firmware,
// fujinet-lib, the ADAM EOS binding, and the FujiNet ADAM CP/M
// library — see the colophon for the exact files.
//
// Build: typst compile --font-path fonts manual.typ
// ============================================================

// ---------- fonts (as used in the 1983 Coleco originals) ----------
#let f-body = "ITC Avant Garde Gothic"   // Medium = body, Bold = run-ins
#let f-serp = "Serpentine"               // Bold / Bold Oblique = heads
#let f-disp = "Handel Gothic D"          // Light = display / numerals
#let f-mono = "DejaVu Sans Mono"         // listings, hex, DCB dumps

#let bb(body) = text(font: f-body, weight: 700, body)
#let serp(body) = text(font: f-serp, weight: 700, body)
#let serpo(body) = text(font: f-serp, weight: 700, style: "oblique", body)
#let hv(body) = text(font: f-disp, body)

// ---------- palette ----------
#let silver-hi = rgb("#d8d7d3")
#let silver-lo = rgb("#b4b3af")
#let cream     = rgb("#fdfbf4")
#let ink       = rgb("#232323")
#let rule-gray = rgb("#9a9890")
#let band-d    = rgb("#4d4d4f")
#let band-l    = rgb("#c9cacc")
#let orange    = rgb("#e87511")   // the Coleco accent — this book's "red"
#let code-bg   = rgb("#efe9d6")   // listing panel fill
#let chip-bg   = rgb("#e6e1cf")   // reference-chip / table fill
#let scr-bg    = rgb("#0d120e")   // monitor glass
#let scr-fg    = rgb("#63d089")   // green phosphor
#let rainbow   = (rgb("#e6007e"), rgb("#f7941d"), rgb("#ffd400"),
                  rgb("#00a651"), rgb("#00aeef"), rgb("#92278f"))

// ---------- page geometry ----------
#let pg-w   = 6.0in
#let pg-h   = 9.0in
#let m-x    = 0.62in
#let col-w  = pg-w - 2 * m-x

// ============================================================
// RUNNING FOLIO — black corner wedge + white oblique numeral
// ============================================================
#let fst = state("folio-style", "none")   // "none" | "arabic"

#let chmark(label, title) = metadata((kind: "chapter", label: label, title: title))
#let smark(title) = metadata((kind: "section", title: title))

#let folio = context {
  if fst.get() == "none" { return }
  let p = counter(page).get().first()
  let num = text(font: f-serp, weight: 700, style: "oblique",
                 size: 13pt, fill: white, str(p))
  if calc.even(p) {
    place(bottom + left,
      polygon(fill: black, (0pt, 0pt), (44pt, 0pt), (58pt, 14pt), (0pt, 14pt)))
    place(bottom + left, dx: 10pt, dy: -1pt, num)
  } else {
    place(bottom + right,
      polygon(fill: black, (14pt, 0pt), (58pt, 0pt), (58pt, 14pt), (0pt, 14pt)))
    place(bottom + right, dx: -10pt, dy: -1pt, num)
  }
}

// ============================================================
// SECTION FURNITURE
// ============================================================
// gray gradient banner, bleeding past the margins — the major
// section head, and what the table of contents is built from
#let sect(title) = {
  smark(title)
  block(breakable: false, sticky: true, above: 1.15em, below: 0.9em,
    pad(x: -m-x,
      rect(width: 100%, height: 0.34in,
        fill: gradient.linear(band-d, band-l, band-d, angle: 0deg),
        stroke: (top: 1.2pt + black, bottom: 1.2pt + black),
        align(center + horizon,
          text(font: f-serp, weight: 700, style: "oblique", size: 13pt,
            fill: black, title)))))
}

// a lighter sub-head: Serpentine bold with a short orange underline
#let subsect(title) = block(above: 1.25em, below: 0.7em, breakable: false,
  sticky: true, context {
  let t = serp(text(size: 10.5pt, fill: ink, title))
  let w = measure(t).width
  t
  v(1.5pt)
  rect(width: w, height: 2.2pt, fill: orange)
})

// big oblique initial opening a section, Coleco style
#let lead(letter, rest) = par(
  text(font: f-serp, weight: 700, style: "oblique", size: 15pt, letter) + rest)

// ============================================================
// STEPS, CALLOUTS, LISTS
// ============================================================
#let step(n, body) = grid(
  columns: (0.42in, 1fr), column-gutter: 0.08in, row-gutter: 0pt,
  hv(text(size: 11pt, n)), body)

#let callout(label, body) = block(above: 0.9em, below: 0.9em,
  par(bb(label + ": ") + body))

// square orange bullet, ADAM style
#let sq(body) = block(above: 0.4em, below: 0.4em,
  grid(columns: (0.2in, 1fr),
    move(dy: 2.4pt, square(size: 4pt, fill: orange)),
    par(leading: 0.5em, first-line-indent: 0pt, body)))

// glossary entry
#let gl(term, def) = par(hanging-indent: 0.25in, bb(term) + " — " + def)

// ============================================================
// CODE & INLINE MONOSPACE
// ============================================================
// inline code word
#show raw.where(block: false): it => box(
  fill: chip-bg, outset: (y: 1.4pt), inset: (x: 1.8pt),
  text(font: f-mono, size: 7.4pt, fill: ink, it))

// block listing: tinted panel, orange top rule (a punch-card header),
// breakable so long listings flow across pages
#show raw.where(block: true): it => block(above: 1.0em, below: 1.0em,
  block(breakable: true, width: 100%, fill: code-bg,
    inset: (x: 10pt, top: 8pt, bottom: 9pt), radius: 1.5pt,
    stroke: (top: 1.8pt + orange), {
      set text(font: f-mono, size: 7.4pt, fill: ink)
      set par(leading: 0.5em, justify: false, first-line-indent: 0pt)
      it
    }))

// short mono word for prose (no chip)
#let cw(s) = text(font: f-mono, size: 7.4pt, fill: ink, s)

// a captioned listing: "Listing n. Title" over an orange rule
#let listing(num, title, body) = block(breakable: true, above: 1.2em,
  below: 1.2em, {
  block(below: 0.5em, sticky: true, {
    text(font: f-body, weight: 700, size: 9pt, fill: ink)[Listing #num.  #title]
    v(3pt)
    line(length: 100%, stroke: 0.9pt + orange)
  })
  body
})

// ============================================================
// REFERENCE COMPONENTS
// ============================================================
// an orange chip naming the AdamNet call and code byte
#let chip(s) = box(fill: orange, inset: (x: 5pt, y: 2.4pt), radius: 2.5pt,
  text(font: f-body, weight: 700, size: 7pt, fill: white, tracking: 0.3pt, s))

// command-reference header: name at left, chip(s) at right, ink rule under
#let cmd(name, ..tags) = block(above: 1.5em, below: 0.5em, breakable: false,
  sticky: true, {
  grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
    serp(text(size: 10.5pt, fill: ink, name)),
    box(tags.pos().map(t => chip(t)).join(h(3pt))))
  v(2.5pt)
  line(length: 100%, stroke: 0.8pt + ink)
})

// a fielded table for payloads / DCB layouts. Column count is inferred
// from the header row's arity; every column auto except the last, which
// wraps. Header is Avant Garde on orange; body is monospaced.
#let mk-table(rows) = {
  set text(hyphenate: false)
  let ncol = rows.first().len()
  let cols = range(ncol - 1).map(_ => auto) + (1fr,)
  table(
    columns: cols, inset: (x: 6pt, y: 3.2pt), align: left + horizon,
    stroke: none,
    fill: (_, row) => if row == 0 { orange }
                      else if calc.odd(row) { chip-bg } else { none },
    ..rows.enumerate().map(((i, r)) => {
      let st = if i == 0 { (font: f-body, weight: 700, size: 7pt, fill: white) }
               else { (font: f-mono, size: 7pt, fill: ink) }
      r.map(cell => text(..st, cell))
    }).flatten())
}
#let ptable(..rows) = block(above: 0.7em, below: 0.9em, mk-table(rows.pos()))
#let ptbl(..rows) = block(above: 0.5em, below: 0.6em, mk-table(rows.pos()))

// a "Returns" run-in line
#let returns(body) = block(above: 0.4em, below: 0.6em, {
  text(font: f-body, weight: 700, size: 7pt, fill: orange, "RETURNS  ")
  text(size: 9pt, body)
})

// ============================================================
// GREEN-PHOSPHOR SCREEN (terminal transcript, in a TV bezel)
// ============================================================
#let scr(..ls) = align(center, block(breakable: false, above: 1.1em, below: 1.1em,
  box(fill: rgb("#1a1a1a"), radius: 6pt, inset: 8pt, width: 100%,
    box(fill: scr-bg, radius: 3pt, inset: (x: 12pt, y: 11pt), width: 100%, {
      set text(font: f-mono, size: 7pt, fill: scr-fg)
      set par(leading: 0.5em, spacing: 0.5em, first-line-indent: 0pt, justify: false)
      set align(left)
      ls.pos().map(l => if l == "" { par(text(" ")) } else { par(l) }).join()
    }))))

// ============================================================
// DOCUMENT SETUP
// ============================================================
#set text(font: f-body, weight: 500, size: 9.3pt, fill: ink)
#set par(leading: 0.55em, spacing: 0.8em, justify: true, first-line-indent: 0pt)
#set page(width: pg-w, height: pg-h, fill: cream,
  margin: (x: m-x, top: 0.7in, bottom: 0.62in), background: folio)
#set enum(numbering: "1.", indent: 0pt, body-indent: 8pt, spacing: 0.85em)
#set table(stroke: none)

// ============================================================
// FRONT COVER
// ============================================================
#page(margin: 0pt, fill: none, background: {
  place(rect(width: 100%, height: 100%,
    fill: gradient.linear(silver-hi, silver-lo, silver-hi, angle: 65deg)))
  place(top + left, box(width: 100%, height: 8.6in, clip: true, {
    for i in range(6) {
      place(top + left, dx: -1.2in, dy: 4.9in + i * 0.9in,
        rotate(-12deg, origin: left,
          line(length: 10in, stroke: 1.1pt + rgb("#1c1c1c"))))
    }
  }))
  place(top + left, dy: 8.55in, rect(width: 100%, height: 5pt, fill: black))
})[
  // ---- masthead: rainbow stripes behind the FujiNet logo ----
  #place(top + right, dy: 0.35in,
    box(width: 6in, height: 1.05in, {
      for (i, c) in rainbow.enumerate() {
        place(top + left, dy: 0.08in + i * 0.085in,
          line(length: 100%, stroke: 1.6pt + c))
      }
      place(top + right, dx: -0.42in + 3.5pt, dy: -0.12in + 3.5pt,
        box(image("images/fujinet-logo-shadow.png", width: 2.9in)))
      place(top + right, dx: -0.42in, dy: -0.12in,
        box(image("images/fujinet-logo-trans.png", width: 2.9in)))
    }))
  #place(top + right, dx: -0.45in, dy: 1.42in,
    text(font: f-disp, size: 16pt, tracking: 1.4pt, "PROGRAMMING GUIDE"))

  // ---- left title block ----
  #place(top + left, dx: 0.5in, dy: 2.05in, box(width: 5in)[
    #text(font: f-disp, size: 21pt, tracking: 0.4pt, "PROGRAMMING")
    #v(-2pt)
    #text(font: f-disp, size: 21pt, tracking: 0.4pt, "THE FUJINET")
    #v(0.06in)
    #text(font: f-disp, size: 10.5pt)[
      Talking to Your FujiNet from Z80 Assembly \
      Language Over AdamNet — Through EOS, \
      and Directly by DCB Under CP/M]
    #v(0.24in)
    #text(font: f-disp, size: 12pt, "FOR THE ADAM" + super(text(size: 5.5pt)[TM]))
  ])

  // ---- listing card, on a Coleco-orange slab ----
  #place(top + left, dx: 0.85in, dy: 3.95in, {
    rotate(-5deg, origin: center, {
      place(dx: 0.3in, dy: 0.28in, rect(width: 4.2in, height: 3.5in, fill: black))
      rect(width: 4.2in, height: 3.5in, fill: orange, inset: 0.16in,
        box(width: 100%, height: 100%, fill: rgb("#141414"), radius: 2pt,
          inset: 12pt, {
          set text(font: f-mono, size: 7pt, fill: scr-fg)
          set par(leading: 0.62em, justify: false)
          let lines = (
            "FINDDCB LD   HL,$FEC4   ; walk the DCBs",
            "        LD   A,($FEC3)  ; how many?",
            "        ...             ; match dev = $0F",
            "",
            "OPEN    LD   HL,SPEC    ; N:TCP://host...",
            "        CALL FNWR       ; hand to the 6801",
            "",
            "LOOP    CALL FNRD       ; bytes waiting?",
            "        CALL COUT       ; and print them",
            "        JR   LOOP",
            "",
            "; the world, one AdamNet packet at a time.",
          )
          lines.map(l => if l == "" { v(0.5em) } else { l }).join(linebreak())
        }))
    })
  })

  #place(bottom + left, dx: 0.5in, dy: -0.5in, box(width: 5in,
    par(leading: 0.5em, justify: false,
      text(font: f-disp, size: 10pt, fill: black)[
        A programmer's guide and command reference for the FujiNet
        WiFi peripheral, from Z80 assembly language.])))
]

// blank verso
#page(fill: cream)[#counter(page).update(0)]

// ============================================================
// INSIDE FRONT COVER — Colophon / Free Software
// ============================================================
#page(margin: (x: 0.6in, y: 0.6in))[
  #set text(size: 8.6pt)
  #set par(leading: 0.5em, spacing: 0.6em, justify: true)
  #grid(columns: (1fr, 1fr), column-gutter: 0.4in, row-gutter: 0pt,
    {
      subsect("Free Software")
      par[FujiNet's firmware, its client libraries, and this manual are
      free software, built and given away by a worldwide community of
      ADAM owners. You may copy this book for a friend — in fact, we would
      be delighted. Source for everything, this booklet included, lives at
      #cw("github.com/FujiNetWIFI").]

      subsect("How This Book Was Verified")
      par[Every command code, DCB layout, EOS entry point and error number
      in this reference was read out of the FujiNet sources, not
      remembered. The firmware side comes from #cw("fujinet-firmware"): the
      AdamNet bus in #cw("lib/bus/adamnet/"), the device handlers in
      #cw("lib/device/adamnet/") (#cw("adamFuji.cpp"), #cw("network.cpp")),
      and the master command list in #cw("include/fujiCommandID.h"). The
      ADAM side comes from the EOS C binding (#cw("eos.h")), the
      #cw("fujinet-lib") ADAM target, and the FujiNet ADAM CP/M library
      (#cw("fujinet-adam-cpm-lib")), which drives the DCB directly.]

      subsect("Limitation of Warranties")
      par[Neither the FujiNet community nor its contributors make any
      warranty with respect to this manual or to FujiNet. Everything is
      provided "as is." But unlike 1983, when something bothers you, you can
      read the source, fix it yourself, and send a pull request.]
    },
    {
      subsect("Trademarks")
      par[ADAM, ColecoVision, SmartWRITER, SmartBASIC and EOS are trademarks
      of their respective owners, used here in tribute. CP/M is a trademark
      of its owner. Z80 is a trademark of Zilog. FujiNet is a community
      project, affiliated with none of them.]

      subsect("Conventions")
      par[Program listings and DCB dumps are set in a monospaced face.
      Hexadecimal numbers are written with a leading dollar sign, as the
      ADAM's own listings write them: #cw("$0F"), #cw("$FEC0"). All assembly
      is Zilog Z80 mnemonics in the syntax common to #cw("z88dk")'s
      assembler and #cw("zmac") — labels in column one, a leading
      #cw("$") on hex — so the examples assemble as-is.]

      par[Copyright 2026 the FujiNet contributors. Released under the GNU
      General Public License v3 as part of the #cw("fujinet-manuals")
      repository.]

      v(3pt)
      par[Dedicated to everyone still writing Z80 by hand — and to the
      memory of the digital data pack, which taught the ADAM to remember,
      and which FujiNet now teaches to dream.]
    })
]

// ============================================================
// TITLE PAGE
// ============================================================
#page[
  #v(0.4in)
  #image("images/fujinet-logo.png", width: 1.15in)
  #v(0.15in)
  #rect(width: 2.9in, height: 1.3pt, fill: orange)
  #v(2pt)
  #text(font: f-disp, size: 22pt)[Programming the FujiNet]
  #v(4pt)
  #par(leading: 0.5em, text(font: f-body, style: "oblique", size: 11pt)[
    A guide to driving the FujiNet WiFi peripheral from Z80 assembly
    language over AdamNet — through the Elementary Operating System, and
    by reaching into the Device Control Blocks directly, as a CP/M program
    must — with a complete reference to the firmware's command set.])

  #v(0.5in)
  #line(length: 100%, stroke: 0.8pt + orange)
  #v(9pt)
  #set text(size: 9pt)
  #par[This book picks up where #text(style: "oblique")[Getting Started with
  FujiNet CONFIG for the ADAM] leaves off. That book taught your fingers;
  this one teaches your assembler. By the last chapter you will have written
  a working #text(style: "oblique")[netcat] — open a socket, read it, write
  it — in a couple of pages of Z80, talking to hardware that did not exist
  when the Z80 did.]
  #v(9pt)
  #line(length: 100%, stroke: 0.8pt + orange)
]

// ============================================================
// CONTENTS
// ============================================================
#page[
  #v(0.15in)
  #rect(width: 2.9in, height: 1.3pt, fill: orange)
  #v(2pt)
  #text(font: f-disp, size: 20pt)[Contents]
  #v(0.3in)
  #context {
    let marks = query(metadata).filter(m =>
      type(m.value) == dictionary and m.value.at("kind", default: "") in
        ("chapter", "section"))
    for m in marks {
      let loc = m.location()
      let p = counter(page).at(loc).first()
      if m.value.kind == "chapter" {
        block(above: 1.0em, below: 0.35em, {
          text(font: f-body, weight: 700, size: 7.6pt, fill: orange,
            tracking: 0.5pt, upper(m.value.label))
          linebreak()
          text(font: f-body, weight: 700, size: 10pt, m.value.title)
          box(width: 1fr, repeat(gap: 3pt)[.])
          text(font: f-body, size: 10pt, str(p))
        })
      } else {
        block(above: 0pt, below: 0.3em, {
          h(0.2in)
          text(font: f-body, size: 8.6pt, m.value.title)
          box(width: 1fr, repeat(gap: 3pt)[.])
          text(font: f-body, size: 8.6pt, str(p))
        })
      }
    }
  }
]

// ============================================================
// OPENERS
// ============================================================
#let chapter(label, title, first: false) = {
  pagebreak(weak: true)
  if first {
    counter(page).update(1)
    fst.update("arabic")
  }
  chmark(label, title)
  block(width: 100%, {
    text(font: f-body, weight: 700, size: 9pt, fill: orange, tracking: 0.6pt,
      upper(label))
    v(3pt)
    rect(width: 100%, height: 1.3pt, fill: orange)
    v(5pt)
    text(font: f-serp, weight: 700, style: "oblique", size: 21pt, fill: ink,
      title)
  })
  v(0.28in)
}

// ============================================================
// PREFACE
// ============================================================
#chapter("Preface", "The Shape of the Thing", first: true)

A FujiNet is, electrically, a small computer of its own — an ESP32 with
WiFi, a memory-card slot, and a wire that pretends to be a peripheral. The
pretending is the clever part. To your ADAM, the FujiNet is not a network
card and not a co-processor. It is a cluster of *AdamNet devices*: the same
intelligent peripheral bus that your keyboard, your disk drives, and your
printer already hang from. Everything in this book is, underneath, an
AdamNet transaction.

That single fact is what makes the FujiNet so easy to program. You do not
install a driver. You do not patch EOS. You ask AdamNet which devices are
attached, and you find — alongside the keyboard, the tape drives, and the
printer — a handful of devices that were never made of metal:

#sq[*The FujiNet control device* (AdamNet id #cw("$0F")). It mounts disk
images, browses hosts, scans WiFi, reads the clock, hashes data, and keeps
the slots that CONFIG shows you.]
#sq[*The Network devices* (ids #cw("$09") and #cw("$0A")) — the #cw("N:")
device. They open TCP, UDP, HTTP, TNFS, FTP, SMB, SSH and TELNET
connections and move bytes across them.]
#sq[The FujiNet's *disk drives* (ids #cw("$04")–#cw("$07")) and its
*printer* (id #cw("$02")) round out the family — ordinary AdamNet block and
character devices, mounted from images.]

#sect("How AdamNet Really Works")

AdamNet is a single half-duplex wire running at 62,500 baud. Your Z80 does
not drive it directly. A dedicated *master 6801* microcontroller owns the
wire; the Z80 and the 6801 meet in shared memory, through a *Peripheral
Control Block* (PCB) and, hanging off it, one *Device Control Block* (DCB)
per device. You fill in a DCB — here is my buffer, here is its length, now
please read (or write) — and poke a byte. The 6801 does the rest: it wraps
your bytes into AdamNet packets, clocks them down the wire, collects the
reply, and drops a completion code back into the DCB. Chapter 1 derives all
of this from the silicon up.

#sect("Two Ways In")

There are two heights at which you can reach a DCB, and this book teaches
both, side by side.

The *EOS road* is the one Coleco intended. The Elementary Operating System —
resident in ROM, always at the top of memory — publishes a jump table of
device routines. You load a register or two and #cw("CALL") a fixed address;
EOS finds the DCB, fills it, pokes it, and waits. It is the right tool for a
SmartBASIC extension, an EOS program, or a cartridge.

The *CP/M road* is the one you must take when EOS is not there. A CP/M
program has no jump table to call — but the PCB and its DCBs still sit at
#cw("$FEC0"), and the master 6801 is still listening. So you find the DCB
yourself, poke it yourself, and spin on the status byte yourself. It costs
you a dozen instructions and buys you the FujiNet from inside CP/M,
SmartBASIC, or anything else that can address memory.

Every command in this book is shown both ways: the EOS #cw("CALL"), and the
direct DCB poke. Learn the two primitives in Chapter 2 and the rest of the
book is just payloads.

#sect("What You Should Already Know")

#sq[Z80 assembly language, and an assembler. The listings use #cw("z88dk") /
#cw("zmac") syntax, but they translate to any Z80 assembler without
surprises.]
#sq[A little of the ADAM's memory map — or a willingness to read Chapter 1,
which derives what it needs from scratch.]
#sq[Enough of CONFIG (from #text(style: "oblique")[Getting Started with
FujiNet]) to know what a "host slot" and a "disk slot" are.]

#sect("How the Reference Is Laid Out")

Chapters 1 and 2 build the foundation: how AdamNet is wired, and how a
single transaction is shaped — in EOS and in CP/M. Chapters 3 through 5 walk
the devices you will actually program — Network, the Fuji control device,
and the clock — and every command in them is written up the same way:

#cmd("EXAMPLE COMMAND", "SEND $F9")
A one-line synopsis, then the payload your program hands the device (the
first byte is the command; the rest are its arguments), or the layout of
what comes back:
#ptable(
  ("Offset", "Bytes", "Meaning"),
  ("0", "1", "command byte"),
  ("1", "1", "an argument byte"),
)
#returns[#cw("$80") from the AdamNet master on success; a device reply you
collect with a read. The EOS call and the DCB status code are named here
too.]
Read the next two chapters in order; after that, dip in wherever you like.

// ============================================================
// CHAPTER 1 — THE ADAMNET CONNECTION
// ============================================================
#chapter("Chapter 1", "The AdamNet Connection")

Before you can send the FujiNet a single command you must understand the
three things that stand between your Z80 and the wire: the *master 6801*
that owns the bus, the *PCB* that anchors the device list in memory, and the
*DCB* through which every transaction passes. This chapter builds them from
the bottom. It owes everything to the ADAM's EOS listing and to the FujiNet
firmware's #cw("lib/bus/adamnet/").

#sect("What AdamNet Is")

AdamNet is a daisy chain of intelligent devices on one three-wire cable:
ground, and a single bidirectional data line at 62,500 baud (plus a reset
line). Unlike a dumb serial port, every device on it has an *address*, a
number from #cw("0") to #cw("15"), and answers only when spoken to. The
standard ADAM assigns them like this:

#ptable(
  ("Id", "Device"),
  ("$01", "keyboard"),
  ("$02", "printer"),
  ("$04–$07", "disk drives 1–4"),
  ("$08", "tape (data pack) drive"),
  ("$09–$0A", "FujiNet Network devices (N:)"),
  ("$0F", "FujiNet control device"),
)

The FujiNet plugs into that chain and adds its own devices to it — the four
disk drives it can present, two network devices, a printer, and the control
device at #cw("$0F"). To the ADAM they are indistinguishable from real
peripherals, which is why no driver is needed.

#sect("The Master, the Z80, and Shared Memory")

Here is the arrangement that governs everything else. Your Z80 is the ADAM's
main processor, but it does *not* bit-bang AdamNet. A second processor — a
Motorola 6801, the "master" — sits between the Z80 and the wire and does all
the clocking, timing, and error recovery. The two processors rendezvous in
the Z80's own RAM:

#sq[A *Peripheral Control Block* (PCB) — a short header the master polls,
holding a status byte, a base address, and a count of active devices.]
#sq[A *Device Control Block* (DCB) for each device — 21 bytes describing one
pending transaction: a status/command byte, a buffer pointer, a length, a
block number, the device id, and a few fields the master keeps for itself.]

You never touch the wire. You write into a DCB — buffer, length, and a
command — and the master, which is forever polling the PCB, notices, carries
out the AdamNet transaction, and writes a completion code back into that
same status byte. Programming AdamNet is programming the DCB.

#sect("The PCB and DCB, Field by Field")

Both structures are fixed. This is the EOS binding's view of them, and the
CP/M library's, byte for byte:

#ptable(
  ("Off", "Bytes", "PCB field"),
  ("0", "1", "status / command"),
  ("1", "2", "base address"),
  ("3", "1", "number of active devices (DCBs)"),
)

#ptable(
  ("Off", "Bytes", "DCB field"),
  ("0", "1", "status — you poke a request; master writes result"),
  ("1", "2", "buffer pointer (your data, low/high)"),
  ("3", "2", "length, low/high"),
  ("5", "4", "block number (block devices only)"),
  ("9", "1", "device number"),
  ("10", "6", "reserved for the master"),
  ("16", "1", "device id — low nibble is the AdamNet address"),
  ("18", "2", "maximum length"),
  ("20", "1", "device type / status"),
)

#callout("IMPORTANT", [The byte you care about most is the DCB *status* at
offset 0. You write a small number into it to request work (Chapter 2 lists
them); the master writes back a code with its high bit set — #cw("$80") and
up — when the work is done. That single byte is the whole handshake.])

#sect("Finding the PCB — and the FujiNet's DCB")

Under EOS you rarely hunt for a DCB by hand; the jump table's
#cw("FIND_DCB") does it for you (next chapter). But under CP/M there is no
EOS, so you find it the hard way — and it is not hard. The PCB lives at a
known address, #cw("$FEC0"), and the DCBs follow it immediately, 21 bytes
apiece, beginning at #cw("$FEC4"):

#ptable(
  ("Address", "Holds"),
  ("$FEC0", "PCB status byte"),
  ("$FEC3", "count of DCBs"),
  ("$FEC4", "first DCB (then every 21 bytes)"),
)

To find the FujiNet control device, walk the DCBs and match the low nibble
of the device-id byte (offset 16) against #cw("$0F"). This is the CP/M
library's #cw("find_dcb"), transliterated to Z80:

#listing("1-1", "Find the FujiNet DCB the CP/M way (FINDDCB)")[
```
DCBBAS  equ  $FEC4         ; first DCB (PCB is $FEC0..$FEC3)
NDCBS   equ  $FEC3         ; count of DCBs, from the PCB
DCBSZ   equ  21            ; bytes per DCB
DEVFUJI equ  $0F           ; FujiNet control device address
;
; FINDDCB - locate the FujiNet control DCB.
;   exit: HL -> DCB, carry CLEAR if found
;         carry SET if no FujiNet on the bus
;
FINDDCB ld   hl,DCBBAS
        ld   a,(NDCBS)
        or   a
        jr   z,FD_NONE     ; no devices at all
        ld   b,a           ; B = how many DCBs to scan
FD_LP   ld   de,16
        add  hl,de         ; HL -> device-id byte (offset 16)
        ld   a,(hl)
        and  $0F           ; low nibble = AdamNet address
        push af
        ld   de,-16
        add  hl,de         ; HL -> back to top of this DCB
        pop  af
        cp   DEVFUJI
        jr   z,FD_OK       ; matched: HL points at its DCB
        ld   de,DCBSZ
        add  hl,de         ; step to the next DCB
        djnz FD_LP
FD_NONE scf                ; not found
        ret
FD_OK   or   a             ; carry CLEAR = found
        ret
```
]

#callout("NOTE", [The network devices are found exactly the same way — match
#cw("$09") for #cw("N1:"), #cw("$0A") for #cw("N2:"). The netcat in Appendix
C reuses #cw("FINDDCB") with a different address in one register.])

With the DCB located, the next chapter shapes an actual transaction — first
with EOS, then by poking that DCB directly.

// ============================================================
// CHAPTER 2 — SHAPING A TRANSACTION
// ============================================================
#chapter("Chapter 2", "Shaping a Transaction")

Every FujiNet command is the same two-beat rhythm: *write* a request to the
device (a command byte and its arguments), then *read* the device's reply.
Both beats are single AdamNet transactions, and there are two ways to
perform each — through EOS, or by poking the DCB. This chapter builds four
small routines — #cw("FNWR"), #cw("FNRD") and their CP/M twins — and every
later example calls them.

#sect("The Write-Then-Read Pattern")

A FujiNet command is a character-device *write*: the bytes you send are the
command. The first byte is the command code; anything after it is arguments.
You do not prefix a length — the length lives in the DCB (or in the register
you hand EOS), and the master 6801 adds the AdamNet length header on the
wire for you.

To get the answer back, you then *read* the device: the reply lands in your
buffer, and the DCB's length field tells you how many bytes arrived. Some
commands only write (a mount, a reset); some write then read (a scan, a
directory entry, a status). When a reference entry shows a payload *and* a
`RETURNS` line, it takes both beats.

#ptable(
  ("Beat", "AdamNet", "EOS call", "DCB status you poke"),
  ("write", "SEND", "WR_CH_DEV", "3"),
  ("read", "RECEIVE", "RD_CH_DEV", "4"),
)

#sect("The EOS Road")

EOS keeps a jump table at the very top of memory — a column of fixed
addresses you #cw("CALL"). These are the entries this book uses, taken from
the EOS binding (#cw("eos.h")) and the EOS listing line numbers beside them:

#ptable(
  ("Addr", "EOS routine", "In / Out"),
  ("$FC54", "FIND_DCB", "A=dev  ->  IY=DCB, Z=ok"),
  ("$FC5A", "FIND_PCB", "->  IY=PCB"),
  ("$FC7E", "REQUEST_DEV_STATUS", "A=dev  ->  IY=DCB"),
  ("$FCA5", "START_RD_CH_DEV", "A=dev, DE=buf, BC=len"),
  ("$FC48", "END_RD_CH_DEV", "A=dev  ->  A=status"),
  ("$FCAE", "START_WR_CH_DEV", "A=dev, HL=buf, BC=len"),
  ("$FC51", "END_WR_CH_DEV", "A=dev  ->  A=status"),
)

A character-device write is a *start* followed by polling *end* until the
master reports done. EOS returns the result in #cw("A"); a value below
#cw("$80") means "still working," and #cw("$9B") means the transaction timed
out and should be retried. Listing 2-1 wraps that into #cw("FNWR"): point
#cw("FNBUF")/#cw("FNLEN")/#cw("FNDEV") and call.

#listing("2-1", "Write a command through EOS (FNWR)")[
```
STWRCH  equ  $FCAE         ; START_WR_CH_DEV : A=dev, HL=buf, BC=len
ENWRCH  equ  $FC51         ; END_WR_CH_DEV   : A=dev -> A=status
STRDCH  equ  $FCA5         ; START_RD_CH_DEV : A=dev, DE=buf, BC=len
ENRDCH  equ  $FC48         ; END_RD_CH_DEV   : A=dev -> A=status
;
FNDEV   db   DEVFUJI       ; the device we're talking to
FNBUF   dw   0             ; buffer pointer
FNLEN   dw   0             ; length
;
; FNWR - send (FNLEN) bytes at (FNBUF) to device (FNDEV).
;        exit: A = AdamNet result ($80 = ok).
FNWR    ld   a,(FNDEV)
        ld   hl,(FNBUF)
        ld   bc,(FNLEN)
        call STWRCH        ; start the write (SEND)
FNWRP   ld   a,(FNDEV)
        call ENWRCH        ; poll for completion
        cp   $80
        jr   c,FNWRP       ; < $80 : master still busy
        cp   $9B           ; $9B : general timeout
        jr   z,FNWR        ; re-issue the whole write
        ret                ; A = $80 (ok) or an error code
```
]

Reading the reply is the mirror image — #cw("START_RD_CH_DEV") then poll
#cw("END_RD_CH_DEV"). After it returns, the DCB's length field holds the
count of bytes actually delivered into your buffer.

#listing("2-2", "Read the reply through EOS (FNRD)")[
```
; FNRD - read up to (FNLEN) bytes into (FNBUF) from (FNDEV).
;        exit: A = AdamNet result; DCB length = bytes delivered.
FNRD    ld   a,(FNDEV)
        ld   de,(FNBUF)
        ld   bc,(FNLEN)
        call STRDCH        ; start the read (RECEIVE)
FNRDP   ld   a,(FNDEV)
        call ENRDCH        ; poll for completion
        cp   $80
        jr   c,FNRDP       ; still busy
        cp   $9B
        jr   z,FNRD        ; timed out, retry
        ret
```
]

#sect("The CP/M Road")

With no EOS jump table, you do exactly what EOS would have done: find the
DCB (Listing 1-1), write the buffer pointer and length into it, poke the
status byte with #cw("3") to write or #cw("4") to read, and spin until the
master raises the status to #cw("$80") or above. This is the FujiNet CP/M
library's #cw("fuji_write") / #cw("fuji_read"), in Z80.

#listing("2-3", "Write and read by poking the DCB (DCBWR, DCBRD)")[
```
; DCBWR - HL -> DCB, DE -> buffer, BC = length. Poke a write.
;         exit: A = result.
DCBWR   push hl
        inc  hl
        ld   (hl),e        ; DCB+1 : buffer low
        inc  hl
        ld   (hl),d        ; DCB+2 : buffer high
        inc  hl
        ld   (hl),c        ; DCB+3 : length low
        inc  hl
        ld   (hl),b        ; DCB+4 : length high
        pop  hl
        ld   (hl),3        ; DCB+0 : status = 3 (write)
DCBWRP  ld   a,(hl)        ; poll the status byte
        cp   $80
        jr   c,DCBWRP      ; < $80 : master still working
        cp   $9B
        jr   z,DCBWR       ; $9B timeout : re-poke (buf/len intact)
        ret
;
; DCBRD - HL -> DCB, DE -> buffer, BC = max length. Poke a read.
DCBRD   push hl
        inc  hl
        ld   (hl),e        ; buffer low
        inc  hl
        ld   (hl),d        ; buffer high
        inc  hl
        ld   (hl),c        ; length low
        inc  hl
        ld   (hl),b        ; length high
        pop  hl
        ld   (hl),4        ; status = 4 (read)
DCBRDP  ld   a,(hl)
        cp   $80
        jr   c,DCBRDP
        cp   $9B
        jr   z,DCBRD
        ret
```
]

#callout("NOTE", [The two roads are interchangeable. Every command in the
rest of this book is issued with #cw("FNWR")/#cw("FNRD"); to run the same
example under CP/M, find the DCB once with #cw("FINDDCB") and swap in
#cw("DCBWR")/#cw("DCBRD"). The payloads are identical — only the plumbing
differs.])

#sect("Reading the Result")

Both roads leave an AdamNet result code in #cw("A"). The master's codes come
from the 6801 listing; the ones you will actually meet are below, and
Appendix A lists them all. Anything #cw("$80") or higher means the
transaction completed; #cw("$80") itself is plain success.

#ptable(
  ("Code", "Name", "Means"),
  ("$80", "ADAMNET_OK", "success"),
  ("$88", "SEND_DATA_NACK", "device refused the data"),
  ("$9B", "TIMEOUT", "no response — retry the transaction"),
)

The *device's own* answer is separate: it comes back in the bytes you read.
A Network status read, for instance, carries a device error in its fourth
byte; a Fuji scan returns a count. Those live with their commands, in the
chapters ahead.

#sect("Talking to the Right Device")

One routine keeps everything pointed at the correct AdamNet address. Set
#cw("FNDEV") before a transaction and both roads obey it. The two you reach
for most:

#listing("2-4", "Name the devices you'll use")[
```
DEVFUJI equ  $0F           ; FujiNet control device
DEVNET1 equ  $09           ; N1: network device
DEVNET2 equ  $0A           ; N2: network device
;
USEFUJI ld   a,DEVFUJI
        ld   (FNDEV),a
        ret
USENET1 ld   a,DEVNET1
        ld   (FNDEV),a
        ret
```
]

With the two primitives in hand, every command in the book reduces to: point
#cw("FNDEV") at the device, lay out the payload, #cw("FNWR"), and — if there
is a reply — #cw("FNRD"). The next three chapters are just that, command by
command.

// ============================================================
// CHAPTER 3 — THE NETWORK DEVICE (N:)
// ============================================================
#chapter("Chapter 3", "The Network Device")

The Network device — AdamNet id #cw("$09") for #cw("N1:"), #cw("$0A") for
#cw("N2:") — is where the FujiNet earns its name. Through it you open TCP and
UDP sockets, fetch URLs over HTTP and HTTPS, mount remote filesystems over
TNFS, FTP and SMB, and tunnel TELNET and SSH. All of it rides the two
primitives from Chapter 2; the protocol is chosen by a *device spec* string,
and the verbs are command bytes that happen to be ASCII letters.

#sect("The Device Spec")

Every network command is addressed to a string of the form

#align(center, cw("N[x]:PROTO://host[:port]/path"))

where #cw("x") is the channel 1–2 on the ADAM, #cw("PROTO") is one of the
schemes below, and the rest is the resource. The scheme is matched in the
firmware's protocol parser; names are upper-case.

#grid(columns: (1fr, 1fr), column-gutter: 14pt,
  ptbl(
    ("Scheme", "Use"),
    ("TCP", "raw TCP socket"),
    ("UDP", "datagram socket"),
    ("HTTP", "web server, cleartext"),
    ("HTTPS", "web server, TLS"),
    ("TNFS", "remote disk filesystem"),
  ),
  ptbl(
    ("Scheme", "Use"),
    ("FTP", "file transfer"),
    ("SMB", "Windows shares"),
    ("SSH", "secure shell"),
    ("TELNET", "telnet"),
    ("", ""),
  ),
)

#callout("NOTE", [On the ADAM the channel digit chooses the *device*:
#cw("N1:") is AdamNet id #cw("$09"), #cw("N2:") is #cw("$0A"). Point
#cw("FNDEV") at the matching id before you operate on a channel. There are
two network devices, so two connections may be open at once.])

#sect("Opening and Closing")

#cmd("OPEN", "SEND 'O'  $4F")
Instantiates the protocol named in the device spec and connects. The payload
is the command byte, an access *mode*, a translation *mode*, then the spec
and a terminating zero.
#ptable(
  ("Offset", "Bytes", "Value"),
  ("0", "1", "$4F  ('O')"),
  ("1", "1", "access mode (see table)"),
  ("2", "1", "translation mode (see table)"),
  ("3…", "N+1", "device spec string, NUL-terminated"),
)
#grid(columns: (1fr, 1fr), column-gutter: 14pt,
  ptbl(
    ("Mode", "Access"),
    ("$04", "read"),
    ("$08", "write"),
    ("$0C", "read/write"),
    ("$0D", "HTTP POST"),
    ("$05", "HTTP DELETE"),
  ),
  ptbl(
    ("Trans", "Line endings"),
    ("$00", "none (binary)"),
    ("$01", "CR"),
    ("$02", "LF"),
    ("$03", "CR/LF"),
    ("", ""),
  ),
)
#returns[#cw("$80") from the master. Check the device's own error with a
#cw("STATUS") afterward. fujinet-lib: #cw("network_open()").]
#listing("3-1", "Open a connection (NETOPEN)")[
```
; NETOPEN - open the spec at (SPEC) on N1: for read/write.
;   the open buffer is [ 'O', mode, trans, spec..., 0 ]
NETOPEN call USENET1        ; FNDEV = $09
        ld   hl,OPBUF
        ld   (FNBUF),hl
        ; build the fixed header
        ld   a,'O'
        ld   (OPBUF),a       ; command
        ld   a,$0C
        ld   (OPBUF+1),a     ; mode = read/write
        xor  a
        ld   (OPBUF+2),a     ; trans = none
        ; copy the NUL-terminated spec after it, counting length
        ld   hl,SPEC
        ld   de,OPBUF+3
        ld   bc,3            ; already 3 header bytes
CPSPEC  ld   a,(hl)
        ld   (de),a
        inc  hl
        inc  de
        inc  bc
        or   a
        jr   nz,CPSPEC       ; stop after copying the NUL
        ld   (FNLEN),bc
        jp   FNWR            ; hand it to the device
;
SPEC    db   "N1:TCP://192.168.1.5:9000/",0
OPBUF   ds   300
```
]

#cmd("CLOSE", "SEND 'C'  $43")
Closes the channel, flushes and frees its buffers. A one-byte payload — just
the command — is enough; the device knows which channel it is.
#returns[#cw("$80"). fujinet-lib: #cw("network_close()").]
#listing("3-2", "Close a connection (NETCLOSE)")[
```
NETCLOSE call USENET1
        ld   a,'C'
        ld   (CBUF),a
        ld   hl,CBUF
        ld   (FNBUF),hl
        ld   hl,1
        ld   (FNLEN),hl
        jp   FNWR
CBUF    db   0
```
]

#sect("Status, Reading, and Writing")

These three are the working day of the Network device. #cw("STATUS") tells
you how many bytes have arrived and whether the far end is still connected;
a read drains them; a write sends.

#cmd("STATUS", "SEND 'S'  $53")
Write the one-byte command #cw("'S'"), then *read* four bytes back: the
pending byte count, a connection flag, and the device error code.
#ptable(
  ("Offset", "Bytes", "Returned value"),
  ("0–1", "2", "bytes waiting to be read (low/high)"),
  ("2", "1", "connected: 1 = open, 0 = far end closed"),
  ("3", "1", "device error (1 = OK, 136 = EOF)"),
)
#returns[fujinet-lib: #cw("network_status()").]
#listing("3-3", "Poll a channel (NETSTAT)")[
```
; NETSTAT - write 'S', read the 4-byte status into STATBF.
;   after: (BW) = bytes waiting, (CONN), (NERR) set.
NETSTAT call USENET1
        ld   a,'S'
        ld   (SBUF),a
        ld   hl,SBUF
        ld   (FNBUF),hl
        ld   hl,1
        ld   (FNLEN),hl
        call FNWR            ; send the status request
        ld   hl,STATBF
        ld   (FNBUF),hl
        ld   hl,4
        ld   (FNLEN),hl
        call FNRD            ; read the 4-byte reply
        ld   hl,(STATBF)     ; bytes waiting
        ld   (BW),hl
        ld   a,(STATBF+2)
        ld   (CONN),a
        ld   a,(STATBF+3)
        ld   (NERR),a
        ret
SBUF    db   0
STATBF  ds   4
BW      dw   0               ; bytes waiting
CONN    db   0               ; connection flag
NERR    db   0               ; device error (136 = EOF)
```
]

#cmd("READ", "RECEIVE")
A read takes no command byte — it *is* the RECEIVE beat. Poll #cw("STATUS")
first so you ask only for what is waiting; never request more than the
device buffer (1024 bytes) holds. The bytes land in your buffer and the DCB
length tells you how many came.
#returns[Data in your buffer; count in the DCB length. fujinet-lib:
#cw("network_read()").]
#listing("3-4", "Read what's waiting (NETREAD)")[
```
; NETREAD - read (BW) bytes into RXBUF (caller guarantees BW <= 1024).
NETREAD call USENET1
        ld   hl,RXBUF
        ld   (FNBUF),hl
        ld   hl,(BW)
        ld   (FNLEN),hl
        jp   FNRD            ; data in RXBUF afterward
RXBUF   ds   1024
```
]

#cmd("WRITE", "SEND 'W'  $57")
Sends bytes to the channel. The payload is the command #cw("'W'") followed
by the data; on the ADAM the firmware pulls the byte count from the AdamNet
length the master supplies, so you need only set #cw("FNLEN") to one plus the
data length.
#returns[#cw("$80"). fujinet-lib: #cw("network_write()").]
#listing("3-5", "Write a buffer (NETWRITE)")[
```
; NETWRITE - write B bytes at HL to N1:.  buffer becomes [ 'W', data... ]
NETWRITE call USENET1
        ld   a,'W'
        ld   (TXBUF),a       ; command byte
        ld   de,TXBUF+1
        ld   c,b             ; save count
        ld   b,0
        push bc
CPTX    ld   a,(hl)          ; copy the data in behind 'W'
        ld   (de),a
        inc  hl
        inc  de
        dec  c
        jr   nz,CPTX
        pop  bc
        inc  bc              ; +1 for the 'W'
        ld   (FNLEN),bc
        ld   hl,TXBUF
        ld   (FNBUF),hl
        jp   FNWR
TXBUF   ds   256
```
]

#sect("A Complete Exchange: HTTP GET")

The routines above are enough to fetch a web page. Open the URL for reading,
then poll-and-read until the far end signals EOF — device error #cw("136")
in the status reply. This prints the body to the screen through
#cw("COUT") (Appendix C shows a console #cw("COUT") for both EOS and CP/M).

#listing("3-6", "Fetch a URL and print it")[
```
GET     call NETOPEN         ; SPEC = "N1:HTTP://...", mode = read
        ret  c               ; open failed
GLOOP   call NETSTAT
        ld   a,(NERR)
        cp   136             ; EOF ?
        jr   z,GDONE
        ld   hl,(BW)
        ld   a,h
        or   l
        jr   z,GLOOP         ; nothing waiting yet, poll again
        ; clamp BW to 1024 if larger (omitted for brevity)
        call NETREAD
        ld   hl,RXBUF
        ld   bc,(BW)
EMIT    ld   a,(hl)
        call COUT            ; print one byte
        inc  hl
        dec  bc
        ld   a,b
        or   c
        jr   nz,EMIT
        jr   GLOOP
GDONE   jp   NETCLOSE
```
]

#callout("WARNING", [A read returns at most the device buffer's worth
(1024 bytes), so clamp #cw("BW") to 1024 before #cw("NETREAD") when more than
that is waiting. The library's #cw("network_read") does this for you; the
netcat in Appendix C shows the few extra instructions.])

#sect("Credentials")

For schemes that authenticate — FTP, SMB — set a username and password
*before* #cw("OPEN"). Each is a command byte followed by the string.

#cmd("USERNAME / PASSWORD", "SEND $FD / $FE")
Payload is the command (#cw("$FD") username, #cw("$FE") password) then the
credential string. fujinet-lib: issued as raw writes on the ADAM.
#ptable(
  ("Offset", "Bytes", "Value"),
  ("0", "1", "$FD (user) or $FE (password)"),
  ("1…", "N", "credential string"),
)

#sect("Filesystem Operations")

When a channel speaks a filesystem protocol (TNFS, FTP, SMB, even HTTP with
WebDAV), a family of command bytes manages files and directories. Each takes
the same shape — the command byte, then a device spec naming the target — so
one example covers them all.

#ptable(
  ("Code", "Char", "Operation", "fujinet-lib"),
  ("$21", "!", "delete file", "network_delete"),
  ("$20", "", "rename (spec is from,to)", "network_rename"),
  ("$23", "#", "lock (make read-only)", "network_lock"),
  ("$24", "$", "unlock", "network_unlock"),
  ("$2A", "*", "make directory", "network_mkdir"),
  ("$2B", "+", "remove directory", "network_rmdir"),
  ("$2C", ",", "change directory", "network_chdir"),
  ("$30", "0", "get current directory", "network_getcwd"),
)
#listing("3-7", "Delete a remote file")[
```
; delete the file named by (SPEC), e.g. "N1:TNFS://TMA-2/OLD.TXT"
RM      call USENET1
        ld   a,'!'           ; $21 = delete
        ld   (RMBUF),a
        ld   hl,SPEC         ; copy spec in behind the command
        ld   de,RMBUF+1
        ld   bc,1
RMCP    ld   a,(hl)
        ld   (de),a
        inc  hl
        inc  de
        inc  bc
        or   a
        jr   nz,RMCP
        ld   (FNLEN),bc
        ld   hl,RMBUF
        ld   (FNBUF),hl
        jp   FNWR
RMBUF   ds   280
```
]

#sect("Reading JSON")

The Network device can parse a JSON document on the FujiNet and hand you
single fields, so a 3.58 MHz Z80 never has to. Open the resource, switch the
channel into *JSON mode*, parse, then query a path as many times as you like;
each query's result is fetched with a #cw("STATUS")+read, exactly like a
normal read.

#cmd("CHANNEL MODE", "SEND $FC")
Switches the channel between protocol mode (#cw("0"), default) and JSON mode
(#cw("1")). Payload: the command byte, then the mode byte.

#cmd("JSON PARSE", "SEND 'P'  $50")
Parses the document currently waiting on the channel. Command byte only.

#cmd("JSON QUERY", "SEND 'Q'  $51")
Sets the JSONPath to read; the value is then retrieved with a normal
#cw("STATUS")+read.
#ptable(
  ("Offset", "Bytes", "Value"),
  ("0", "1", "$51  ('Q')"),
  ("1…", "N+1", "JSONPath, e.g. \"/weather/0/main\", NUL"),
)
#returns[After the query, #cw("STATUS") reports the value length and a read
returns it. fujinet-lib: #cw("network_json_query()").]

#sect("HTTP Verbs and Headers")

An #cw("HTTP")/#cw("HTTPS") channel is more than a byte pipe. The access mode
chosen at #cw("OPEN") selects the verb — read is GET, #cw("$0D") is POST,
#cw("$05") is DELETE — and one command byte, #cw("$4D") (#cw("'M'")), steers
the channel between the request body and its headers.

#cmd("HTTP CHANNEL MODE", "SEND 'M'  $4D")
Directs reads and writes on an HTTP channel to the body or the headers.
#ptable(
  ("Value", "Meaning"),
  ("0", "body (default)"),
  ("1", "collect request headers"),
  ("2", "read response headers"),
)
#returns[fujinet-lib: #cw("network_http_set_channel_mode()"); a header is
then sent with an ordinary write.]

#sect("TCP and UDP")

A raw #cw("TCP:") channel opened read/write is a bidirectional socket — the
foundation of the netcat in Appendix C. Two extra command bytes serve the
listening and datagram cases.

#cmd("TCP ACCEPT / CLOSE CLIENT", "SEND 'A' $41 / 'c' $63")
On a #cw("TCP:") channel opened to listen, #cw("$41") (#cw("'A'")) accepts a
waiting client; #cw("$63") (#cw("'c'")) closes the current client while
keeping the listener alive. Command byte only.

#cmd("UDP SET DESTINATION", "SEND 'D'  $44")
For a #cw("UDP:") channel, sets the host\:port the next writes are addressed
to. Payload: the command byte, then a #cw("\"host:port\"") string.
#returns[Companion #cw("$72") (#cw("'r'"), GET REMOTE) reads back the address
of the last datagram's sender — handy for replying.]

That is the whole Network device. Point #cw("FNDEV") at #cw("$09") or
#cw("$0A"), and these bytes give you the Internet. The next chapter turns to
the other half of the FujiNet: the control device that manages disks, hosts,
and the hardware itself.

// ============================================================
// CHAPTER 4 — THE FUJI CONTROL DEVICE
// ============================================================
#chapter("Chapter 4", "The Fuji Control Device")

The device at AdamNet id #cw("$0F") is the one CONFIG talks to. It owns the
WiFi radio, the list of *hosts* and *disk-image* mounts, the directory
browser, persistent app-key storage, the clock, and a drawer of utilities.
Where the Network device overloaded ASCII letters as verbs, the Fuji device
uses the high-numbered #cw("FUJICMD_") bytes from #cw("fujiCommandID.h"). Set
#cw("FNDEV") to #cw("$0F") (call #cw("USEFUJI")); the rhythm from Chapter 2
holds — write the command, then read the reply.

#callout("NOTE", [Not every code in #cw("fujiCommandID.h") is serviced on the
ADAM. This chapter documents those the firmware's #cw("adamFuji.cpp")
actually dispatches; Appendix B's table marks every code's status.])

#sect("The Slots Model")

CONFIG presents two arrays you will meet constantly. *Host slots* (8 of them)
name the places disks live — a TNFS server, an SMB share, the SD card.
*Disk slots* (4 of them) are the drive bays: each remembers a host, an access
mode, and a filename, and maps to an AdamNet disk drive #cw("$04")–#cw("$07").
Mounting is the two-step you know from CONFIG: mount a host, browse it, then
mount one of its images into a disk slot.

#sect("WiFi and the Adapter")

#cmd("SCAN NETWORKS", "SEND $FD")
Write the one-byte command; the following read returns the count of access
points found in the first byte. fujinet-lib: #cw("fuji_scan_for_networks()").
#listing("4-1", "Scan for networks (both roads)")[
```
; --- the EOS road ---
SCAN    call USEFUJI
        ld   a,$FD
        ld   (SCMD),a
        ld   hl,SCMD
        ld   (FNBUF),hl
        ld   hl,1
        ld   (FNLEN),hl
        call FNWR            ; send SCAN
        ld   hl,RESP
        ld   (FNBUF),hl
        ld   hl,1024
        ld   (FNLEN),hl
        call FNRD            ; read the reply
        ld   a,(RESP)        ; A = number of APs found
        ret
;
; --- the CP/M road: identical payload, DCB plumbing ---
SCANC   call FINDDCB         ; HL -> Fuji DCB, from Chapter 1
        ret  c
        push hl
        ld   de,SCMD
        ld   bc,1
        call DCBWR           ; poke a write of the 1-byte command
        pop  hl
        ld   de,RESP
        ld   bc,1024
        call DCBRD           ; poke a read of the reply
        ld   a,(RESP)
        ret
SCMD    db   $FD
RESP    ds   1024
```
]

#cmd("GET SCAN RESULT", "SEND $FC")
Write #cw("$FC") followed by the index #cw("n") of the access point you want;
the read returns that one's name and signal — a 32-byte SSID and a signed
one-byte RSSI. fujinet-lib: #cw("fuji_get_scan_result()").

#cmd("SET SSID", "SEND $FB")
Write #cw("$FB") followed by a 32-byte SSID and a 64-byte password, joining
the network. #cw("$FE") (GET SSID) reads the stored pair back. fujinet-lib:
#cw("fuji_set_ssid()") / #cw("fuji_get_ssid()").

#cmd("GET WIFI STATUS", "SEND $FA")
Write #cw("$FA"); the read returns one byte — #cw("3") = connected,
#cw("6") = disconnected. fujinet-lib: #cw("fuji_get_wifi_status()").

#cmd("GET ADAPTER CONFIG", "SEND $E8")
Write #cw("$E8"); the read returns the live network configuration in one
shot — the joined SSID, hostname, and four-byte IP, gateway, netmask and
DNS, plus MAC and BSSID and a firmware-version string.
#ptable(
  ("Offset", "Bytes", "Field"),
  ("0", "32", "SSID"),
  ("32", "64", "hostname"),
  ("96", "4", "local IP"),
  ("100", "4", "gateway"),
  ("104", "4", "netmask"),
  ("108", "4", "DNS IP"),
  ("112", "6", "MAC address"),
  ("118", "6", "BSSID"),
  ("124", "15", "firmware version string"),
)
#returns[fujinet-lib: #cw("fuji_get_adapter_config()"). The layout is the
#cw("AdapterConfig") struct from the CP/M library, byte for byte.]

#sect("Hosts and Disk Slots")

#cmd("READ / WRITE HOST SLOTS", "SEND $F4 / $F3")
The eight host slots are an array of eight 32-byte names. Write #cw("$F4")
then read all 256 bytes; write #cw("$F3") followed by 256 bytes to store
them. fujinet-lib: #cw("fuji_get_host_slots()") /
#cw("fuji_put_host_slots()").

#cmd("READ / WRITE DEVICE SLOTS", "SEND $F2 / $F1")
Disk slots are an array of 38-byte records:
#ptable(
  ("Offset", "Bytes", "Field"),
  ("0", "1", "host slot this disk lives on"),
  ("1", "1", "access mode (1 = read, 2 = read/write)"),
  ("2", "36", "filename"),
)
#returns[Write #cw("$F2") then read the whole array; write #cw("$F1")
followed by it to store. The CP/M library models each record as its
#cw("DeviceSlot") struct.]

#cmd("MOUNT / UNMOUNT HOST", "SEND $F9 / $E6")
Brings a host slot online (connects the server) or takes it offline. Payload
is the command byte then the host-slot number.
#ptable(
  ("Offset", "Bytes", "Value"),
  ("0", "1", "$F9 (mount) or $E6 (unmount)"),
  ("1", "1", "host slot number"),
)
#returns[fujinet-lib: #cw("fuji_mount_host_slot()") /
#cw("fuji_unmount_host_slot()").]

#cmd("MOUNT / UNMOUNT IMAGE", "SEND $F8 / $E9")
Mounts the disk image recorded in a *disk* slot, making it a live AdamNet
drive. Mount takes the slot and an access mode; unmount takes just the slot.
#ptable(
  ("Offset", "Bytes", "Value"),
  ("0", "1", "$F8 (mount) or $E9 (unmount)"),
  ("1", "1", "disk slot number"),
  ("2", "1", "access mode (mount only: 1=RO, 2=RW)"),
)
#returns[fujinet-lib: #cw("fuji_mount_disk_image()") /
#cw("fuji_unmount_disk_image()"). #cw("$D7") (MOUNT ALL, command byte only)
mounts every configured slot at once.]
#listing("4-2", "Mount host 0, then image in disk slot 1")[
```
MOUNT   call USEFUJI
        ; mount host slot 0
        ld   a,$F9
        ld   (MBUF),a
        xor  a
        ld   (MBUF+1),a      ; host slot 0
        ld   hl,MBUF
        ld   (FNBUF),hl
        ld   hl,2
        ld   (FNLEN),hl
        call FNWR
        ; mount image in disk slot 1, read/write
        ld   a,$F8
        ld   (MBUF),a
        ld   a,1
        ld   (MBUF+1),a      ; disk slot 1
        ld   a,2
        ld   (MBUF+2),a      ; mode = read/write
        ld   hl,3
        ld   (FNLEN),hl
        jp   FNWR
MBUF    ds   4
```
]

#cmd("SET DEVICE FILENAME", "SEND $E2")
Records a filename into a disk slot without mounting: command byte, disk
slot, then the filename. To read a slot's filename back, write #cw("$A0 + ds")
(so #cw("$A0")…#cw("$A9") for slots 0–9). fujinet-lib:
#cw("fuji_set_device_filename()").

#cmd("NEW DISK", "SEND $E7")
Creates a fresh blank image on a host and records it in a disk slot.
#ptable(
  ("Offset", "Bytes", "Value"),
  ("0", "1", "$E7"),
  ("1", "1", "host slot"),
  ("2", "1", "disk slot"),
  ("3–6", "4", "block count (little-endian)"),
  ("7…", "256", "filename"),
)
#returns[fujinet-lib: #cw("fuji_create_new()").]

#sect("Browsing a Host")

To list files on a mounted host, open its directory, read entries one at a
time until the end marker, then close.

#cmd("OPEN DIRECTORY", "SEND $F7")
Opens a directory on a host slot. Payload: command byte, host slot, then the
path and an optional filename filter, separated by a NUL. fujinet-lib:
#cw("fuji_open_directory()").

#cmd("READ DIR ENTRY", "SEND $F6")
Write #cw("$F6"), a maximum length to return, and a flags byte; the read
returns one entry. Set bit 7 of the flags to append a details block after
the name.
#ptable(
  ("Beat", "Bytes", "Field"),
  ("write", "1", "$F6"),
  ("write", "1", "max length to return"),
  ("write", "1", "flags ($80 = append details)"),
  ("read", "maxlen", "filename; details if requested"),
)
#callout("IMPORTANT", [A returned entry whose first byte is #cw("$7F") is the
*end-of-directory* marker — stop reading. On the ADAM the firmware also
prepends two type-icon bytes to each real filename (a folder, DDP, DSK or ROM
glyph); skip or render them as you like.])
#returns[fujinet-lib: #cw("fuji_read_directory()").]

#cmd("CLOSE DIRECTORY", "SEND $F5")
Closes the open directory. Command byte only. #cw("$E5") / #cw("$E4") get and
set the directory read position for paging. fujinet-lib:
#cw("fuji_close_directory()").

#listing("4-3", "List a directory to the screen")[
```
; host slot 0 already mounted; FNDEV = $0F
LISTDIR call USEFUJI
        ; OPEN DIRECTORY on host 0, path "/"
        ld   a,$F7
        ld   (DBUF),a
        xor  a
        ld   (DBUF+1),a      ; host slot 0
        ld   a,'/'
        ld   (DBUF+2),a      ; path = "/"
        xor  a
        ld   (DBUF+3),a      ; NUL: no filter
        ld   hl,DBUF
        ld   (FNBUF),hl
        ld   hl,4
        ld   (FNLEN),hl
        call FNWR
LD_NEXT ; READ DIR ENTRY, max 40 chars, name only
        ld   a,$F6
        ld   (DBUF),a
        ld   a,40
        ld   (DBUF+1),a      ; max length
        xor  a
        ld   (DBUF+2),a      ; flags = 0 (no details)
        ld   hl,DBUF
        ld   (FNBUF),hl
        ld   hl,3
        ld   (FNLEN),hl
        call FNWR
        ld   hl,ENTRY        ; read one entry
        ld   (FNBUF),hl
        ld   hl,40
        ld   (FNLEN),hl
        call FNRD
        ld   a,(ENTRY)
        cp   $7F             ; end-of-directory?
        jr   z,LD_END
        ld   hl,ENTRY+2      ; skip the two icon bytes
PR_LP   ld   a,(hl)
        or   a
        jr   z,PR_EOL
        call COUT
        inc  hl
        jr   PR_LP
PR_EOL  ld   a,13
        call COUT            ; carriage return
        jr   LD_NEXT
LD_END  ld   a,$F5           ; CLOSE DIRECTORY
        ld   (DBUF),a
        ld   hl,DBUF
        ld   (FNBUF),hl
        ld   hl,1
        ld   (FNLEN),hl
        jp   FNWR
DBUF    ds   8
ENTRY   ds   64
```
]

#sect("App Keys: Saving State")

An *app key* is a small block (up to 64 bytes) the FujiNet stores for your
program, indexed by a creator id, an app id and a key id — handy for high
scores, settings, or a save game. #cw("OPEN") the key first, declaring read
or write, then read or write it.

#cmd("OPEN APPKEY", "SEND $DC")
#ptable(
  ("Offset", "Bytes", "Value"),
  ("0", "1", "$DC"),
  ("1–2", "2", "creator id (little-endian)"),
  ("3", "1", "app id"),
  ("4", "1", "key id"),
  ("5", "1", "mode: 0 = read, 1 = write"),
)

#cmd("READ / WRITE APPKEY", "SEND $DD / $DE")
After an #cw("OPEN") in read mode, write #cw("$DD") and read the key's bytes.
After an #cw("OPEN") in write mode, write #cw("$DE") followed by the data.
#returns[fujinet-lib: #cw("fuji_read_appkey()") / #cw("fuji_write_appkey()").]

#sect("Boot, Devices, and Housekeeping")

A handful of short commands round out the device.

#ptable(
  ("Code", "Action", "Payload after command byte"),
  ("$D9", "enable/disable CONFIG boot", "1 byte: toggle"),
  ("$D6", "set boot mode", "1 byte: mode"),
  ("$D5", "enable a device", "1 byte: device id"),
  ("$D4", "disable a device", "1 byte: device id"),
  ("$D1", "device-enabled status", "read returns 1 byte"),
  ("$D7", "mount all slots", "none"),
  ("$D8", "copy file between hosts", "src, dst, spec"),
  ("$BB", "generate a GUID string", "read returns text"),
  ("$D3", "random number", "read returns 2 bytes"),
  ("$FF", "reset the FujiNet", "none"),
)
#returns[fujinet-lib names follow the obvious pattern —
#cw("fuji_set_boot_mode()"), #cw("fuji_enable_device()"),
#cw("fuji_generate_guid()"), #cw("fuji_reset()"), and so on.]

#sect("Hashing, Base64, and QR Codes")

The firmware can compute MD5, SHA-1, SHA-256 and SHA-512 digests, encode and
decode Base64, and render QR codes — useful for content addressing or showing
a link on screen. Each is a small state machine: feed input, compute, ask the
length, read the result.

#ptable(
  ("Code", "Step"),
  ("$C8", "hash: add input data to the buffer"),
  ("$C7", "hash: compute (algorithm in byte 1); clears buffer"),
  ("$C6", "hash: read length of the digest"),
  ("$C5", "hash: read the digest"),
  ("$C2", "hash: clear the buffer"),
  ("$D0 $CF $CE $CD", "base64 encode: input, compute, length, output"),
  ("$CC $CB $CA $C9", "base64 decode: input, compute, length, output"),
  ("$BC $BD $BE $BF", "QR: input, encode, length, output"),
)

That is the Fuji control device. Between it and the Network device you can do
anything CONFIG can, and a good deal it cannot. One small thing remains — the
clock — and then we build the netcat.

// ============================================================
// CHAPTER 5 — TELLING TIME
// ============================================================
#chapter("Chapter 5", "Telling Time")

An ADAM has never known what time it is. The FujiNet does — it keeps network
time and a configured time zone — and unlike the Atari and Apple, which
expose a separate clock device, the ADAM reads the clock straight from the
Fuji control device with a single command.

#sect("Getting the Time")

#cmd("GET TIME", "SEND $D2")
Point #cw("FNDEV") at #cw("$0F"), write #cw("$D2"), then read seven bytes:
century, year, month, day, hour, minute, second — all binary, no parsing.
The century byte is #cw("$13") (19 decimal, added to the two-digit year) so
that century plus year gives the full four-digit year.
#ptable(
  ("Offset", "Bytes", "Field"),
  ("0", "1", "century (add to year)"),
  ("1", "1", "year (0–99)"),
  ("2", "1", "month (1–12)"),
  ("3", "1", "day"),
  ("4", "1", "hour (24h)"),
  ("5", "1", "minute"),
  ("6", "1", "second"),
)
#returns[The time is in the FujiNet's configured zone. fujinet-lib:
#cw("fuji_get_time()"); the layout matches the firmware's
#cw("adamnet_get_time()").]

#listing("5-1", "Read the time into seven bytes")[
```
GETTIME call USEFUJI
        ld   a,$D2
        ld   (TCMD),a
        ld   hl,TCMD
        ld   (FNBUF),hl
        ld   hl,1
        ld   (FNLEN),hl
        call FNWR            ; send GET TIME
        ld   hl,NOW
        ld   (FNBUF),hl
        ld   hl,7
        ld   (FNLEN),hl
        call FNRD            ; seven bytes into NOW
        ret
TCMD    db   $D2
NOW     ds   7               ; cent, year, month, day, hour, min, sec
```
]

#callout("NOTE", [The time zone itself is a general FujiNet setting, managed
from CONFIG and stored in the adapter configuration. Programs that only need
to stamp a file or show a clock read the seven bytes above and are done.])

With the clock read, every device the ADAM programmer can reach through the
FujiNet has been covered. What remains is to put the Network device through
its paces — a real program, start to finish.

// ============================================================
// APPENDIX A — ERROR CODES
// ============================================================
#chapter("Appendix A", "Error Codes")

Three layers of status meet in FujiNet programming on the ADAM. The *AdamNet
master* returns a result code in #cw("A") (or in the DCB status byte) from
every transaction. *EOS* returns its own file/device errors from the jump
table. And the network *device* reports a finer code inside the bytes you
read — most importantly #cw("136"), end-of-file.

#sect("AdamNet Master Result Codes")

From the 6801 master listing; these are what land in the DCB status byte
(high bit set) and in #cw("A") from #cw("FNWR")/#cw("FNRD"):

#ptable(
  ("Code", "Name", "Meaning"),
  ("$80", "ADAMNET_OK", "success"),
  ("$81", "READY_TIMEOUT", "READY packet not answered in time"),
  ("$83", "SEND_TIMEOUT", "SEND packet not answered in time"),
  ("$85", "SEND_DATA_BREAK", "device broke off during a send"),
  ("$88", "SEND_DATA_NACK", "device NACKed the sent data"),
  ("$89", "RECEIVE_TIMEOUT", "RECEIVE packet not answered in time"),
  ("$8C", "RECEIVE_NACK", "device NACKed a receive"),
  ("$8D", "CLR_TIMEOUT", "device did not send its data in time"),
  ("$93", "STAT_TIMEOUT", "STATUS packet not answered in time"),
  ("$9B", "TIMEOUT", "general timeout — retry the transaction"),
)

#sect("EOS Error Codes")

Returned by the file and device calls; strip the high bit (#cw("AND $7F"))
before comparing:

#ptable(
  ("Code", "Meaning"),
  ("0", "no error"),
  ("1", "DCB not found"),
  ("2", "DCB busy"),
  ("3", "DCB idle"),
  ("5", "no file"),
  ("9", "bad file number"),
  ("10", "end of file"),
  ("13", "storage medium full"),
  ("$9B", "device timeout"),
)

#sect("Network Device Status Codes")

Read from byte 3 of a Network #cw("STATUS") reply (Listing 3-3's
#cw("NERR")):

#ptable(
  ("Code", "Meaning"),
  ("1", "normal — connected, no error"),
  ("136", "end of file — the resource is fully read"),
)

#sect("Library Error Codes")

When you call #cw("fujinet-lib") instead of issuing raw transactions, it
folds these into a small device-agnostic set:

#ptable(
  ("Code", "Name", "Meaning"),
  ("$00", "FN_ERR_OK", "no error"),
  ("$01", "FN_ERR_IO_ERROR", "an I/O problem with the device"),
  ("$02", "FN_ERR_BAD_CMD", "called with bad arguments"),
  ("$03", "FN_ERR_OFFLINE", "the device is offline"),
  ("$04", "FN_ERR_WARNING", "non-fatal device warning"),
  ("$05", "FN_ERR_NO_DEVICE", "no network device present"),
  ("$FF", "FN_ERR_UNKNOWN", "an unmapped device error"),
)

// ============================================================
// APPENDIX B — COMMAND QUICK REFERENCE
// ============================================================
#chapter("Appendix B", "Command Quick Reference")

Everything in this book, condensed. Codes are the *first byte* of the payload
you write to the device.

#sect("Devices and the EOS Jump Table")

#grid(columns: (1fr, 1fr), column-gutter: 12pt,
  ptbl(
    ("Id", "AdamNet device"),
    ("$01", "keyboard"),
    ("$02", "printer"),
    ("$04–$07", "disk drives 1–4"),
    ("$08", "tape drive"),
    ("$09–$0A", "Network (N1:, N2:)"),
    ("$0F", "Fuji control"),
  ),
  ptbl(
    ("Addr", "EOS routine"),
    ("$FC54", "FIND_DCB"),
    ("$FC5A", "FIND_PCB"),
    ("$FCA5", "START_RD_CH_DEV"),
    ("$FC48", "END_RD_CH_DEV"),
    ("$FCAE", "START_WR_CH_DEV"),
    ("$FC51", "END_WR_CH_DEV"),
  ),
)

#sect("DCB Status Requests")

#ptable(
  ("Poke", "Requests"),
  ("3", "write (character device)"),
  ("4", "read (character device)"),
  (">= $80", "master's completion code (result)"),
)

#sect("Network Device (id $09 / $0A)")

#ptable(
  ("Code", "Char", "Operation"),
  ("$4F", "O", "open connection (mode, trans, spec)"),
  ("$43", "C", "close connection"),
  ("$53", "S", "channel status (bw, conn, err)"),
  ("$57", "W", "write bytes"),
  ("—", "", "read waiting bytes (RECEIVE beat)"),
  ("$FD/$FE", "", "set username / password"),
  ("$FC", "", "channel mode (0 protocol, 1 JSON)"),
  ("$50", "P", "JSON parse"),
  ("$51", "Q", "JSON query (then status + read)"),
  ("$2C", ",", "change directory"),
  ("$30", "0", "get current directory"),
  ("$20", "", "rename (spec is from,to)"),
  ("$21", "!", "delete file"),
  ("$23", "#", "lock file"),
  ("$24", "$", "unlock file"),
  ("$2A", "*", "make directory"),
  ("$2B", "+", "remove directory"),
  ("$4D", "M", "HTTP channel mode (body/headers)"),
  ("$41", "A", "TCP accept connection"),
  ("$63", "c", "TCP close client"),
  ("$44", "D", "UDP set destination"),
  ("$72", "r", "UDP get remote address"),
)

#sect("Fuji Control Device (id $0F)")

The commands the ADAM firmware services. Codes not listed here exist in
#cw("fujiCommandID.h") but are not dispatched on the ADAM.

#ptable(
  ("Code", "Operation"),
  ("$FF", "reset FujiNet"),
  ("$FE / $FB", "get / set SSID"),
  ("$FD", "scan networks (read returns count)"),
  ("$FC", "get scan result n"),
  ("$FA", "get WiFi status"),
  ("$F9 / $E6", "mount / unmount host slot"),
  ("$F8 / $E9", "mount / unmount disk image"),
  ("$D7", "mount all"),
  ("$F4 / $F3", "read / write host slots"),
  ("$F2 / $F1", "read / write device slots"),
  ("$E2", "set device filename"),
  ("$A0–$A9", "get device filename (slot 0–9)"),
  ("$E7", "new (blank) disk"),
  ("$F7", "open directory"),
  ("$F6", "read directory entry"),
  ("$F5", "close directory"),
  ("$E5 / $E4", "get / set directory position"),
  ("$E8", "get adapter config"),
  ("$DC", "open app key"),
  ("$DD / $DE", "read / write app key"),
  ("$D9", "enable CONFIG boot"),
  ("$D6", "set boot mode"),
  ("$D5 / $D4", "enable / disable device"),
  ("$D1", "device enable status"),
  ("$D8", "copy file"),
  ("$D3", "random number"),
  ("$D2", "get time (7 bytes)"),
  ("$BB", "generate GUID"),
  ("$C8 $C7 $C6 $C5 $C2", "hash: input, compute, len, out, clear"),
  ("$BC $BD $BE $BF", "QR: input, encode, length, output"),
)

// ============================================================
// APPENDIX C — NETCAT
// ============================================================
#chapter("Appendix C", "netcat in Z80")

Here is the program promised on the title page: a #text(style:
"oblique")[netcat], written for *CP/M* on the ADAM. It opens a raw TCP
connection through the Network device, then pumps bytes both ways — whatever
the far end sends is printed to the screen, and whatever you type is sent to
the far end — until the connection drops or you press #box(text(font: f-body,
weight: 700, size: 8pt)[ESC]).

It is the whole book in one listing, and it takes the *CP/M road*
deliberately: no EOS, just the PCB at #cw("$FEC0"), the network DCB found by
hand, and CP/M's own BDOS for the console. #cw("FINDDCB") from Chapter 1 and
#cw("DCBWR")/#cw("DCBRD") from Chapter 2 do all the FujiNet work; BDOS
function 6 does the keyboard and screen.

#sect("What It Needs")

Assemble the listing below together with #cw("FINDDCB") (Listing 1-1, with
its #cw("match") value changed to #cw("$09") for #cw("N1:")) and
#cw("DCBWR") / #cw("DCBRD") (Listing 2-3). Change the address in #cw("HOST")
to the server you want to reach, assemble to a #cw(".COM"), and run it from
the CP/M prompt.

#sect("The Program")

#listing("C-1", "FujiNet netcat — CP/M, direct DCB")[
```
; ============================================================
;  FUJINET NETCAT for the Coleco ADAM, under CP/M
;  socket <-> screen + keyboard, ESC to quit
;  assemble with FINDDCB (match $09), DCBWR, DCBRD
; ============================================================
BDOS    equ  $0005          ; CP/M entry
CONIO   equ  6              ; BDOS direct console I/O
;
        org  $0100          ; CP/M .COM load address
;
NETCAT  call FINDDCB        ; HL -> N1: DCB (match $09)
        jp   c,NODEV        ; no FujiNet on the bus
        ld   (NETDCB),hl    ; remember it
;
; ---- open TCP, read/write, no translation ----
        ld   hl,(NETDCB)
        ld   de,OPENB       ; [ 'O', $0C, $00, "N1:TCP://...",0 ]
        ld   bc,OPENL
        call DCBWR
;
; ---- the pump: drain the socket, then check the keyboard ----
PUMP    call STATUS         ; how much is waiting? still up?
        ld   a,(CONNF)
        or   a
        jr   z,CLOSED       ; far end hung up
        ld   a,(NERRF)
        cp   136            ; EOF from the resource
        jr   z,CLOSED
        ld   hl,(BWCNT)
        ld   a,h
        or   l
        jr   z,KEYS         ; nothing waiting -> service keyboard
;
        ld   a,h            ; clamp request to 1024 bytes
        cp   4
        jr   c,RDOK
        ld   hl,1024
RDOK    ld   (RDLEN),hl
        ld   hl,(NETDCB)
        ld   de,RXBUF
        ld   bc,(RDLEN)
        call DCBRD          ; pull the bytes in
        ld   hl,(NETDCB)    ; DCB length = bytes delivered
        ld   de,3
        add  hl,de
        ld   c,(hl)
        inc  hl
        ld   b,(hl)         ; BC = count
        ld   hl,RXBUF
EMIT    ld   a,b
        or   c
        jr   z,KEYS
        ld   e,(hl)         ; print one byte via BDOS
        push hl
        push bc
        ld   c,CONIO
        call BDOS
        pop  bc
        pop  hl
        inc  hl
        dec  bc
        jr   EMIT
;
; ---- one key per pass, so the screen stays responsive -------
KEYS    ld   c,CONIO
        ld   e,$FF          ; $FF = input request
        call BDOS
        or   a
        jr   z,PUMP         ; no key -> keep pumping
        cp   $1B            ; ESC ?
        jr   z,QUIT
        ld   (ONEB),a       ; send this one byte, behind a 'W'
        ld   a,'W'
        ld   (WBUF),a
        ld   hl,(NETDCB)
        ld   de,WBUF
        ld   bc,2           ; 'W' + the key
        call DCBWR
        jr   PUMP
;
; ---- STATUS: write 'S', read 4 bytes, unpack ----
STATUS  ld   hl,(NETDCB)
        ld   de,SCMD        ; "S"
        ld   bc,1
        call DCBWR
        ld   hl,(NETDCB)
        ld   de,STATB
        ld   bc,4
        call DCBRD
        ld   hl,(STATB)
        ld   (BWCNT),hl     ; bytes waiting
        ld   a,(STATB+2)
        ld   (CONNF),a
        ld   a,(STATB+3)
        ld   (NERRF),a
        ret
;
CLOSED  ld   de,BYEMSG
        call PRSTR
QUIT    ld   hl,(NETDCB)    ; close the channel
        ld   de,CLB         ; "C"
        ld   bc,1
        call DCBWR
        rst  0              ; warm boot back to CP/M
NODEV   ld   de,NOMSG
        call PRSTR
        rst  0
;
; ---- PRSTR: print the $-terminated string at DE ----
PRSTR   ld   c,9            ; BDOS print string
        jp   BDOS
;
; ---- data ---------------------------------------------------
OPENB   db   'O',$0C,$00,"N1:TCP://192.168.1.5:9000/",0
OPENL   equ  $-OPENB
SCMD    db   "S"
CLB     db   "C"
WBUF    db   0              ; 'W'
ONEB    db   0              ; the keystroke
STATB   ds   4
BWCNT   dw   0
CONNF   db   0
NERRF   db   0
RDLEN   dw   0
NETDCB  dw   0
RXBUF   ds   1024
BYEMSG  db   13,10,"** CONNECTION CLOSED",13,10,"$"
NOMSG   db   13,10,"** NO FUJINET FOUND",13,10,"$"
```
]

#sect("Trying It")

On the other end, anything that speaks TCP will do. The classic test is the
Unix #cw("netcat") itself, listening on the port you named:

#scr(
  "A>NETCAT",
  "",
  "HELLO FROM THE ADAM",
  "and hello back from your laptop",
  "the quick brown fox jumped over",
  "",
  "** CONNECTION CLOSED",
  "A>",
)

Type, and your keystrokes cross the room — or the world — and the reply
paints onto a 3.58 MHz machine that predates the network it just joined. That
is the whole trick of the FujiNet, and now it is yours to program: find the
DCB, write the command, read the reply, and the rest is just Z80.

#v(0.3in)
#align(center, serpo(text(size: 12pt, "A FujiNet in every home!")))
