// ============================================================
// THE FUJINET BASIC EXTENSION
// A Command Reference for Applesoft BASIC · ProDOS 8
//
// The BASIC-side companion to "Programming the FujiNet".  That
// book teaches your assembler; this one teaches your BASIC: the
// seventeen N-commands the extension adds to BASIC.SYSTEM, plus
// the printer redirect, each with syntax, examples, and the
// screen transcripts to prove them.
//
// Typeset in tribute to Apple's own technical reference manuals
// of the mid-1980s: cream stock, warm red rules, Helvetica heads,
// the wide scholar's margin.  Body text is Apple Garamond (ITC
// Garamond Condensed).  Program listings and screen transcripts
// are set in the genuine Apple II character set (Print Char 21).
//
// Every command, argument, message, and address in this book is
// taken from the extension's source (fujinet-nhandler/apple2-new)
// and was exercised on running hardware against fujinet-pc — see
// the colophon.  Appendix E reprints the complete source listing,
// copied from the tree at build time so it can never go stale.
//
// Build: make          (copies listing/, runs typst)
// ============================================================

// ---------- fonts -------------------------------------------
#let f-body = "Apple Garamond"   // Apple's corporate serif — body, heads, folios
#let f-head = "Helvetica"        // section heads, tags, chips
#let f-mono = "Print Char 21"    // genuine Apple II charset — listings, hex

// ---------- palette -----------------------------------------
#let paper  = rgb("#f6f0dd")   // cream stock
#let ink    = rgb("#2b2620")   // letterpress near-black
#let red    = rgb("#f43b50")   // the Apple manual warm red (coral)
#let code-bg= rgb("#ece4cc")   // listing panel fill
#let chip-bg= rgb("#e7ddc2")   // reference-chip fill
#let rule-c = rgb("#cdbf9a")   // hairline on cream
#let scr-bg = rgb("#0d120e")   // monitor glass
#let scr-fg = rgb("#5fec87")   // green phosphor

// ---------- geometry ----------------------------------------
#let col-w   = 4.65in          // main text column
#let mhang   = 1.75in          // reach back into the margin
#let mnote-w = 1.5in           // margin note width
#let bleed-l = 2.3in           // left margin (to page edge)

// ============================================================
// RUNNING HEAD / FOLIO
// ============================================================
#let fst = state("folio-style", "none")  // "none" | "roman" | "arabic"

#let chmark(label, title) = metadata((kind: "chapter", label: label, title: title))
#let smark(title) = metadata((kind: "section", title: title))

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

// ============================================================
// OPENERS & HEADS
// ============================================================
#let chapter(label, title, banner: none) = {
  pagebreak(weak: true, to: "odd")
  chmark(label, title)
  place(dx: -mhang, dy: 6pt, box(width: mnote-w, {
    rect(width: 0.62in, height: 1.3pt, fill: red)
    v(2pt)
    text(font: f-body, size: 13.5pt, fill: ink, label)
  }))
  block(width: 100%, {
    rect(width: 2.9in, height: 1.3pt, fill: red)
    v(1pt)
    text(font: f-body, size: 22pt, fill: ink, title)
  })
  if banner != none {
    v(0.28in)
    line(length: 100%, stroke: 0.8pt + red)
    v(9pt)
    banner
    v(9pt)
    line(length: 100%, stroke: 0.8pt + red)
  }
  v(0.3in)
}

#let sect(title) = block(above: 1.7em, below: 1em, breakable: false, sticky: true, {
  smark(title)
  text(font: f-head, weight: 700, size: 10.5pt, fill: ink, title)
  v(1.5pt)
  move(dx: -bleed-l, rect(width: bleed-l + col-w, height: 3.2pt, fill: red))
})

#let subsect(title) = block(above: 1.4em, below: 0.75em, breakable: false, sticky: true, context {
  let t = text(font: f-head, weight: 700, size: 9.5pt, fill: ink, title)
  let w = measure(t).width
  t
  v(1pt)
  rect(width: w + 2pt, height: 2.5pt, fill: red)
})

// ============================================================
// MARGIN NOTES & SET-OFF TAGS
// ============================================================
#let mnote(body, dy: 1pt) = place(dx: -mhang, dy: dy, box(width: mnote-w,
  par(leading: 0.45em, spacing: 0.5em, first-line-indent: 0pt, justify: false,
    text(font: f-body, size: 8.5pt, fill: ink, body))))

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

// square black bullets, IIc style
#let sq(body) = block(above: 0.5em, below: 0.5em,
  grid(columns: (0.18in, 1fr),
    move(dy: 2.6pt, square(size: 4.2pt, fill: ink)),
    par(leading: 0.5em, first-line-indent: 0pt, body)))

// ============================================================
// CODE & INLINE MONOSPACE  (Print Char 21)
// ============================================================
// inline code word
#show raw.where(block: false): it => box(
  fill: chip-bg, outset: (y: 1.2pt), inset: (x: 1.6pt),
  text(font: f-mono, size: 7pt, fill: ink, it))

// block listing: full-width tinted panel, Apple II charset, with a
// thin red rule across the top like a punch-card header.  Breakable,
// so long listings (Appendix E!) flow across pages.
#show raw.where(block: true): it => block(above: 1.1em, below: 1.1em,
  pad(left: -mhang, block(breakable: true, width: mhang + col-w,
    fill: code-bg, inset: (x: 11pt, top: 8pt, bottom: 9pt), radius: 1.5pt,
    stroke: (top: 1.6pt + red), {
      set text(font: f-mono, size: 7pt, fill: ink)
      set par(leading: 0.42em, justify: false, first-line-indent: 0pt)
      it
    })))

// a captioned listing: "Listing n. Title" over a red rule, then code
#let listing(num, title, body) = block(breakable: true, above: 1.3em, below: 1.3em, {
  block(below: 0.5em, sticky: true, {
    text(font: f-body, size: 9.4pt, fill: ink)[Listing #num.  #title]
    v(3pt)
    line(length: 100%, stroke: 0.9pt + red)
  })
  body
})

// short label for code-word in body, lighter than raw chip (for prose)
#let cw(s) = text(font: f-mono, size: 7pt, fill: ink, s)

// ============================================================
// REFERENCE COMPONENTS
// ============================================================
// command reference header: name at left, a red chip at right naming
// the SmartPort operation the command rides on (tying this book to
// its assembly-language companion).
#let chip(s) = box(fill: red, inset: (x: 5pt, y: 2.2pt), radius: 2pt,
  text(font: f-head, weight: 700, size: 7.5pt, fill: paper, tracking: 0.3pt, s))

#let cmd(name, tag) = block(above: 1.5em, below: 0.55em, breakable: false, sticky: true, {
  grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
    text(font: f-head, weight: 700, size: 10pt, fill: ink, name),
    chip(tag))
  v(2pt)
  line(length: 100%, stroke: 0.8pt + ink)
})

// the syntax line for a BASIC command: a set-off panel with a red
// left bar, Apple II charset.  italic-looking placeholders are
// rendered lowercase to read as metavariables against the uppercase
// keywords, the way Apple's BASIC manuals did it.
#let syntax(s) = block(above: 0.6em, below: 0.8em,
  pad(left: -mhang, box(width: mhang + col-w, fill: chip-bg,
    inset: (x: 11pt, y: 7pt), stroke: (left: 3pt + red),
    text(font: f-mono, size: 8pt, fill: ink, s))))

// a small fielded table for parameters.  Column count inferred from
// the header row; last column is fractional and wraps.
#let mk-table(rows) = {
  set text(hyphenate: false)
  let ncol = rows.first().len()
  let cols = range(ncol - 1).map(_ => auto) + (1fr,)
  table(
    columns: cols,
    inset: (x: 7pt, y: 3.4pt),
    align: left + horizon,
    stroke: none,
    fill: (_, row) => if row == 0 { red } else if calc.odd(row) { chip-bg } else { none },
    ..rows.enumerate().map(((i, r)) => {
      let st = if i == 0 { (font: f-head, weight: 700, size: 7.5pt, fill: paper) }
               else { (font: f-mono, size: 7pt, fill: ink) }
      r.map(cell => text(..st, cell))
    }).flatten()
  )
}
// full-bleed parameter table: reaches into the left margin.
#let ptable(..rows) = block(above: 0.7em, below: 0.9em,
  pad(left: -mhang, box(width: mhang + col-w, mk-table(rows.pos()))))
// plain table that fills its container (for side-by-side grids).
#let ptbl(..rows) = block(above: 0.5em, below: 0.6em, mk-table(rows.pos()))

// a "Returns / Errors" note line
#let returns(body) = block(above: 0.4em, below: 0.6em, {
  text(font: f-head, weight: 700, size: 7.5pt, fill: red, "Errors  ")
  text(size: 9.5pt, body)
})

// ============================================================
// GREEN-PHOSPHOR SCREEN (for transcripts at the ] prompt)
// ============================================================
#let scr-size = 6.5pt
#let scr(..ls) = align(center, block(breakable: false, above: 1.15em, below: 1.15em,
  box(fill: scr-bg, radius: 8pt, inset: (x: 14pt, top: 12pt, bottom: 12pt), width: mhang + col-w, {
    set text(font: f-mono, size: scr-size, fill: scr-fg)
    set par(leading: 0.42em, spacing: 0.42em, first-line-indent: 0pt, justify: false)
    set align(left)
    ls.pos().map(l => if l == "" { par(text(" ")) } else { par(l) }).join()
  })))

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
#set table(stroke: none)

// ============================================================
// FRONT COVER
// ============================================================
#page(margin: 0pt, footer: none)[
  #place(top + left, dx: 0.6in, dy: 0.55in,
    image("images/fujinet-logo.png", width: 1.15in))
  #place(top + left, dx: 2.0in, dy: 0.55in,
    text(font: f-body, size: 27pt, fill: ink)[The FujiNet BASIC Extension])
  #place(top + left, dx: 2.0in, dy: 1.02in,
    text(font: f-body, size: 14.5pt, style: "italic", fill: ink)[for Applesoft BASIC and ProDOS 8])

  // a typographic "listing card" motif in place of a photo
  #place(top + left, dx: 1.1in, dy: 2.0in, box(width: 5.3in, height: 4.4in,
    fill: code-bg, radius: 2pt, stroke: (top: 3pt + red), inset: 20pt, {
      set text(font: f-mono, size: 8pt, fill: ink)
      set par(leading: 0.7em, justify: false)
      let lines = (
        " 10 D$ = CHR$(4): Q$ = CHR$(34)",
        " 20 U$ = \"N:HTTPS://ICANHAZIP.COM/\"",
        " 30 PRINT D$;\"NOPEN 1,\";Q$;U$;Q$;\",4,0\"",
        " 40 PRINT D$;\"NSTATUS 1,BW,CN,ER\"",
        " 50 IF BW = 0 AND CN THEN 40",
        " 60 PRINT D$;\"NREAD 1,A$,BW\"",
        " 70 PRINT \"MY IP IS \";A$",
        " 80 PRINT D$;\"NCLOSE 1\"",
        "",
        "]RUN",
        "MY IP IS 47.190.140.76",
        "",
        "; the world, one PRINT CHR$(4); at a time.",
      )
      lines.map(l => if l == "" { v(0.62em) } else { l }).join(linebreak())
    }))

  #place(bottom + left, dx: 2.0in, dy: -0.62in, box(width: 4.6in,
    par(leading: 0.5em, justify: false,
      text(font: f-body, size: 12.5pt, fill: ink)[
        A command reference for the seventeen network commands the
        FujiNet adds to Applesoft BASIC.])))
]

// ============================================================
// INSIDE FRONT COVER — Colophon / Free Software
// ============================================================
#page(margin: (x: 0.6in, y: 0.65in), footer: none)[
  #set text(size: 9.2pt)
  #set par(leading: 0.5em, spacing: 0.62em, justify: true)
  #grid(columns: (1fr, 1fr), column-gutter: 0.45in, row-gutter: 0pt,
    {
      subsect("Free Software")
      par[FujiNet's firmware, this BASIC extension, and this manual are
      free software, built and given away by a worldwide community of
      Apple II owners. You may copy this book for a friend — in fact,
      we'd be delighted. Source for everything, this booklet included,
      lives at #cw("github.com/FujiNetWIFI").]

      subsect("How This Book Was Verified")
      par[Every command, argument, error message, and address in this
      reference was taken from the extension's own source — reprinted
      in full in Appendix E, copied from the tree each time this book
      is typeset — and every command was exercised on running hardware
      against the FujiNet firmware. The extension lives in
      #cw("fujinet-nhandler/apple2-new"); the firmware side of each
      operation is in #cw("fujinet-firmware")
      (#cw("lib/device/iwm/network.cpp") and friends). The assembly-level
      story of the same machinery is told in the companion volume,
      #text(style: "italic")[Programming the FujiNet].]

      subsect("Limitation of Warranties")
      par[Neither the FujiNet community nor its contributors make any
      warranty with respect to this manual or to FujiNet. Everything is
      provided "as is." But unlike 1984, when something bothers you, you
      can read the source — it's in the back of this very book — fix it,
      and send a pull request.]
    },
    {
      subsect("Trademarks")
      par[Apple, the Apple logo, Applesoft, ProDOS, and SmartPort are
      trademarks of Apple Inc. FujiNet is a community project and is not
      affiliated with, endorsed by, or sponsored by Apple Inc.]

      subsect("Conventions")
      par[Program listings and screen transcripts are set in the genuine
      Apple II character set. Hexadecimal numbers are written with a
      leading dollar sign, as the Apple II has always written them:
      #cw("$7C00"), #cw("$BE06") — though as befits a BASIC manual,
      you will mostly meet honest decimal here. In syntax lines,
      UPPERCASE is typed as shown and lowercase names stand for the
      parts you supply.]

      par[Copyright 2026 the FujiNet contributors. Released under the GNU
      General Public License v3 as part of the #cw("fujinet-manuals")
      repository.]

      v(4pt)
      par[Dedicated to everyone who ever typed #cw("PRINT CHR$(4)") and
      trusted that somebody, somewhere, was listening.]
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
  #text(font: f-body, size: 24pt)[The FujiNet BASIC Extension]
  #v(2pt)
  #par(leading: 0.5em, text(font: f-body, size: 12.5pt, style: "italic")[
    A command reference for Applesoft BASIC under ProDOS 8: seventeen
    network commands and a printer, for every Apple II with a FujiNet
    on its SmartPort.])

  #v(0.55in)
  #line(length: 100%, stroke: 0.8pt + red)
  #v(10pt)
  #set text(size: 9.6pt)
  #par[This book is the BASIC-speaking member of a family.
  #text(style: "italic")[Getting Started with FujiNet] taught your
  fingers; #text(style: "italic")[Programming the FujiNet] taught your
  assembler; this one teaches the language the Apple II booted into
  every morning. By the last chapter you will have fetched a web page,
  parsed JSON, served TCP, and printed over WiFi — without leaving the
  #cw("]") prompt.]
  #v(10pt)
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
#v(0.35in)
#context {
  let marks = query(metadata).filter(m =>
    type(m.value) == dictionary and m.value.at("kind", default: "") in ("chapter", "section"))
  for m in marks {
    let loc = m.location()
    let p = counter(page).at(loc).first()
    let style = fst.at(loc)
    let num = if style == "roman" { numbering("i", p) } else { numbering("1", p) }
    if m.value.kind == "chapter" {
      block(above: 1.3em, below: 0.5em, {
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
// PREFACE
// ============================================================
#chapter("Preface", "The Shape of the Thing")
#fst.update("arabic")
#counter(page).update(1)

#mnote[Seventeen commands, one printer, no new dialect: it is still
Applesoft, still ProDOS, still the machine you know.]

Somewhere between 1977 and now, the Apple II learned to talk to the
whole world. The FujiNet did that: a WiFi peripheral that hangs off the
SmartPort and speaks TCP, HTTP, JSON, and half a dozen other protocols
on the machine's behalf. What this book documents is the thinnest
possible bridge between that power and the language most Apple II
programs were ever written in.

The FujiNet BASIC extension adds *seventeen network commands* to
Applesoft BASIC. They are not new keywords baked into a new
interpreter — Applesoft lives in ROM, and its keyword table is carved
in silicon. Instead they are *BASIC.SYSTEM external commands*, exactly
the mechanism ProDOS provides for the purpose, and they behave like
the disk commands you already know: type them at the #cw("]") prompt,
or issue them from a program with #cw("PRINT CHR$(4)").

#sect("Where the Commands Came From")

The command set is a port. The Coleco Adam's SmartBASIC got these same
seventeen commands first, and this extension deliberately matches that
set, name for name — #cw("NOPEN") to #cw("NHTTPMODE") — so programs and
habits move between the machines. If you have used FujiNet from BASIC
anywhere, you already know most of this book.

#sect("What You Should Already Know")

Applesoft, at the level of #text(style: "italic")[Basic Programming
With ProDOS]: variables, strings, #cw("PRINT"), #cw("ONERR"). Nothing
here requires assembly language, PEEKs, or POKEs — the two #cw("CALL")s
in Chapter 8 are the entire machine-language surface of this book. When
you get curious about what is underneath, Appendix C sketches the
machinery and Appendix E reprints every line of it.

#sect("How the Reference Is Laid Out")

Each command gets an entry like this: the name, with a red chip naming
the FujiNet operation it rides on (the same operation names used in
#text(style: "italic")[Programming the FujiNet], so the two books
cross-reference); a syntax line, where #cw("UPPERCASE") is typed as
shown and lowercase stands for what you supply; a parameter table;
the errors it can raise; and a worked example — usually a transcript
from a real session, green phosphor and all.

// ============================================================
// CHAPTER 1
// ============================================================
#chapter("Chapter 1", "Getting Started",
  banner: scr(
    "]PR#6",
    "",
    "FUJINET BASIC EXTENSION INSTALLED",
    "17 COMMANDS - NOPEN..NHTTPMODE",
    "FUJINET NETWORK DEVICE AT SP UNIT $0B",
    "FUJINET PRINTER AT SP UNIT $0D",
    "",
    "]",
  ))

#sect("What You Need")

#sq[An Apple II that boots ProDOS — any model with 64K.]
#sq[A FujiNet on the SmartPort: the real device on a IIc, IIGS or
SmartPort card, or #cw("fujinet-pc") behind an emulator.]
#sq[The extension disk, #cw("FUJIAPPLE.PO"). It boots ProDOS 8 and
BASIC.SYSTEM, then installs the commands automatically.]

#sect("Booting It")

Boot the disk. ProDOS starts BASIC.SYSTEM, BASIC.SYSTEM runs
#cw("STARTUP"), and #cw("STARTUP") does one interesting thing:

#syntax("PRINT CHR$(4);\"BRUN FUJIAPPLE\"")

That single line is the whole installation. The extension announces
itself with the banner shown above: seventeen commands are live, and
the FujiNet's network device (and printer, if the firmware exposes
one) have been found on the SmartPort and remembered.

#mnote[No FujiNet? The banner says #cw("FUJINET NETWORK DEVICE NOT
FOUND") and every N-command answers #cw("NO DEVICE CONNECTED"). The
rest of the machine is unaffected.]

To install onto your own work disk, copy the #cw("FUJIAPPLE") file
across and add the #cw("BRUN") line to your own #cw("STARTUP"). The
extension is a single ProDOS #cw("BIN") file; there is nothing else
to carry.

#sect("What Gets Installed, and Where")

The extension is *resident*: it loads once at #cw("$8000") and stays
until you reboot. To protect itself it moves BASIC's ceiling,
#cw("HIMEM"), down to 31744 (#cw("$7C00")). Your program, variables,
and strings live below that line exactly as before; you simply have
about six fewer K to spend. A 48K machine still leaves you roughly
29K of program space — the same arithmetic as any resident DOS-era
utility, and Appendix C has the full memory map.

Everything else you know keeps working. #cw("CATALOG"), #cw("SAVE"),
#cw("LOAD"), #cw("OPEN"), #cw("EXEC") — the ProDOS commands and the
N-commands share the same command line, the same error style, and the
same disk, without stepping on each other.

#sect("Your First Command")

Type this at the #cw("]") prompt (substitute any TNFS host you like —
#cw("FUJINET.ONLINE") is always awake):

#scr(
  "]NDIR \"N:TNFS://FUJINET.ONLINE/\"",
  "/ APOD        DIR 001",
  "/ CATALOGS    DIR 001",
  "/ GAMES       DIR 286",
  "  README      TXT 004",
  "",
  "]",
)

That listing came over WiFi, from a filesystem on the other side of
the internet, into a machine whose designers were worried about the
price of 16K RAM chips. It took one line of BASIC.

#byway[Every command in this book works the same typed at the prompt
or issued from a program. The transcripts show the prompt because it
is the fastest way to explore; your programs will use
#cw("PRINT CHR$(4)"), described next.]

// ============================================================
// CHAPTER 2
// ============================================================
#chapter("Chapter 2", "Command Conventions")

#sect("Typing Commands, Running Commands")

At the #cw("]") prompt, an N-command is typed bare, like #cw("CATALOG"):

#syntax("NOPEN 1,\"N:HTTPS://ICANHAZIP.COM/\",4,0")

Inside a program, an N-command is *printed* — the standard ProDOS
idiom, a #cw("PRINT") whose first character is #cw("CTRL-D"),
#cw("CHR$(4)"):

#listing("2-1", "The CHR\\$(4) idiom")[
```
 10 D$ = CHR$(4)
 20 PRINT D$;"NOPEN 1,";CHR$(34);
    "N:HTTPS://ICANHAZIP.COM/";CHR$(34);",4,0"
```
]

#mnote[#cw("CHR$(34)") is the quotation mark. Building specs into a
string variable first (#cw("U$")) usually reads better — every command
that takes a quoted string also accepts a string variable in its
place.]

Two habits from the disk commands carry over exactly: the
#cw("CTRL-D") must be the first character printed on its line, and the
command text is ordinary uppercase.

#sect("Channels")

The FujiNet holds up to *fifteen simultaneous connections*, numbered
1 through 15. Every connection-oriented command names its channel
first: #cw("NOPEN 1,…") opens channel 1; #cw("NREAD 1,…") reads it;
channels 2 through 15 are yours for more connections at the same
time — a web fetch on one, a TCP chat on another. A channel number
outside 1–15 raises #cw("RANGE ERROR").

#byway[The extension reserves channel 0 for its own housekeeping —
the filesystem commands of Chapter 4 ride on it — which is why you
cannot open it yourself.]

#sect("The Device Spec")

Every place this book says #text(style: "italic")[spec], it means a
FujiNet device specification: the string that names what to connect
to, always beginning #cw("N:").

#syntax("N:protocol://host[:port]/path")

#ptable(
  ("Protocol", "Talks to", "Example"),
  ("TNFS", "TNFS file servers", "N:TNFS://FUJINET.ONLINE/GAMES/"),
  ("HTTP", "web servers", "N:HTTP://IP-API.COM/JSON/"),
  ("HTTPS", "web servers, TLS", "N:HTTPS://ICANHAZIP.COM/"),
  ("TCP", "raw sockets, or listen", "N:TCP://BBS.EXAMPLE.ORG:6502/"),
  ("UDP", "datagrams", "N:UDP://192.168.1.7:5000/"),
  ("TELNET", "telnet hosts", "N:TELNET://RETRO.SDF.ORG:23/"),
)

A spec appears in a command either as a quoted literal or as a *simple
string variable* — an expression such as #cw("A$+B$") will not do:

#syntax("NOPEN 2,U$,4,0")

#sect("Modes and Translation")

#cw("NOPEN") takes two small numbers after the spec. The *mode* says
which way data flows; *translation* rewrites line endings between the
Apple's carriage returns and the network's conventions.

#grid(columns: (1fr, 1fr), column-gutter: 14pt,
  ptbl(
    ("Mode", "Meaning"),
    ("4", "read"),
    ("8", "write"),
    ("12", "read/write"),
    ("13", "HTTP POST"),
  ),
  ptbl(
    ("Trans", "Line endings"),
    ("0", "none (binary)"),
    ("1", "CR (Apple)"),
    ("2", "LF (Unix)"),
    ("3", "CR/LF (internet)"),
  ),
)

For text from the modern world, mode 4 with translation 2 or 3 is the
usual choice; for binary data, always translation 0.

#sect("When Something Goes Wrong")

The N-commands report trouble the ProDOS way — a message at the
prompt, or a catchable error under #cw("ONERR GOTO"):

#ptable(
  ("Message", "PEEK(222)", "Meaning"),
  ("NO DEVICE CONNECTED", "3", "no FujiNet found at boot"),
  ("RANGE ERROR", "2", "channel number not 1-15"),
  ("I/O ERROR", "8", "the FujiNet refused the operation"),
  ("PROGRAM TOO LARGE", "14", "NLOAD: file exceeds program space"),
)

A mistyped argument — a missing comma, a word where a number should
be, an argument too many — is reported as a plain
#cw("?SYNTAX ERROR") (code 16 under #cw("ONERR")); the command does
not run, and nothing else is disturbed.

#important[Network trouble on an open channel — a dropped connection,
a server error — does #text(style: "italic")[not] interrupt your
program. It shows up in the error variable of #cw("NSTATUS"), which
well-behaved programs check as they go. Chapter 3 shows the pattern.]

// ============================================================
// CHAPTER 3
// ============================================================
#chapter("Chapter 3", "Connections")

Five commands carry every conversation: open a channel, ask it how it
is doing, read it, write it, close it. Learn these five and the rest
of the book is detail.

#cmd("NOPEN", "CONTROL 'O'")
#syntax("NOPEN channel, spec, mode, trans")
Opens #text(style: "italic")[channel] to the destination named by
#text(style: "italic")[spec]. The connection is attempted immediately.
#ptable(
  ("Argument", "Type", "Meaning"),
  ("channel", "number 1-15", "which of the fifteen channels to open"),
  ("spec", "string", "the device spec (Chapter 2)"),
  ("mode", "number", "4 read, 8 write, 12 read/write, 13 POST"),
  ("trans", "number", "0 none, 1 CR, 2 LF, 3 CR/LF"),
)
#returns[#cw("RANGE ERROR") for a bad channel. For file-flavored
protocols — TNFS and its kin — a failed open is reported at once:
#cw("PATH NOT FOUND") if the file or directory is not there,
#cw("I/O ERROR") for other refusals, and the channel is closed for
you. For #cw("HTTP") and #cw("HTTPS") the request has not actually
fired yet (see Chapter 7), so nothing can have failed: check the
error value of #cw("NSTATUS") after your first read.]

#cmd("NCLOSE", "CONTROL 'C'")
#syntax("NCLOSE channel")
Closes the channel and frees its connection on the FujiNet. Close what
you open — fifteen channels feels infinite right up until it isn't.

#cmd("NSTATUS", "STATUS 'S'")
#syntax("NSTATUS channel, bw, conn, err")
The heartbeat of every network program. Asks the FujiNet how
#text(style: "italic")[channel] is doing and stores the answer into
three #text(style: "italic")[numeric variables you name] — they are
assigned, not read:
#ptable(
  ("Variable", "Receives", "Meaning"),
  ("bw", "0-65535", "bytes waiting to be read"),
  ("conn", "0 or 1", "1 while the connection is alive"),
  ("err", "code", "1 = all is well; 136 = end of data; 128+ = trouble"),
)
The idiomatic fetch loop asks three questions in order: anything to
read? still connected? did it end well?
#listing("3-1", "The NSTATUS loop, the shape of every fetch")[
```
100 PRINT D$;"NSTATUS 1,BW,CN,ER"
110 IF BW > 0 THEN GOSUB 200: GOTO 100
120 IF CN = 1 THEN 100
130 IF ER <> 136 THEN PRINT "ERROR ";ER
140 END
```
]

#cmd("NREAD", "READ")
#syntax("NREAD channel, var$, count")
Reads up to #text(style: "italic")[count] bytes (1 to 255) from the
channel into the string variable #text(style: "italic")[var\$]. The
variable receives #text(style: "italic")[exactly what arrived] — if
fewer bytes were waiting, it is shorter; check #cw("LEN(var$)"), not
your request. Ask #cw("NSTATUS") first and read the smaller of
#text(style: "italic")[bw] and 255.

#cmd("NWRITE", "WRITE")
#syntax("NWRITE channel, data$, count")
Writes the first #text(style: "italic")[count] bytes of
#text(style: "italic")[data\$] to the channel. If
#text(style: "italic")[count] exceeds #cw("LEN(data$)"), the whole
string is written and nothing more. For strings, the natural spelling
is #cw("NWRITE 1,A$,LEN(A$)")... except that
#text(style: "italic")[count], like every numeric argument, may be any
expression — so that spelling works as written.

#sect("A Complete Exchange")

The program from the front cover, in full. It opens an HTTPS channel,
waits for the reply, reads it, and says where you are:

#listing("3-2", "WHATSMYIP — a complete HTTPS fetch")[
```
 10 D$ = CHR$(4): Q$ = CHR$(34)
 20 U$ = "N:HTTPS://ICANHAZIP.COM/"
 30 PRINT D$;"NOPEN 1,";Q$;U$;Q$;",4,0"
 40 PRINT D$;"NSTATUS 1,BW,CN,ER"
 50 IF BW = 0 AND CN = 1 THEN 40
 60 IF BW = 0 THEN PRINT "NO REPLY, ERR ";ER: GOTO 90
 70 PRINT D$;"NREAD 1,A$,BW"
 80 PRINT "MY IP IS ";A$
 90 PRINT D$;"NCLOSE 1"
```
]

#scr(
  "]RUN",
  "MY IP IS 47.190.140.76",
  "",
  "]",
)

#byway[Line 50 is the polite way to wait: while the reply is still in
flight, #text(style: "italic")[bw] is zero but
#text(style: "italic")[conn] is one. When both go to zero without
data, something failed — and line 60 reports the code instead of
looping forever.]

// ============================================================
// CHAPTER 4
// ============================================================
#chapter("Chapter 4", "The Filesystem Commands")

Five commands treat the network as a disk: list it, walk it, make and
remove directories, delete files. They take *no channel number* — just
a spec — because each is a complete errand: the extension runs it on a
reserved internal channel and is done before the prompt returns.

They work on any filesystem-shaped protocol — TNFS above all, and
anything else the firmware exposes with directories.

#cmd("NDIR", "OPEN 6 + READ")
#syntax("NDIR spec")
Prints the directory named by the spec to the screen, one entry per
line, sizes and all. This is the command from Chapter 1 — the fastest
way to see whether the network is alive.

#cmd("NCD", "CONTROL ','")
#syntax("NCD spec")
Sets the working prefix for the filesystem commands that follow, the
way #cw("PREFIX") does for ProDOS. Two forms are worth knowing:
#syntax("NCD \"N:TNFS://FUJINET.ONLINE/GAMES/\"\nNCD \"N:..\"")
The second walks up one level, wherever you are.

#cmd("NMKDIR", "CONTROL '*'")
#syntax("NMKDIR spec")
Creates the directory named by the spec.

#cmd("NRMDIR", "CONTROL '+'")
#syntax("NRMDIR spec")
Removes the (empty) directory named by the spec.

#cmd("NDEL", "CONTROL '!'")
#syntax("NDEL spec")
Deletes the file named by the spec.

#returns[All five raise catchable errors when the server refuses.
#cw("NDIR") answers #cw("PATH NOT FOUND") for a directory that isn't
there; the others answer #cw("I/O ERROR") — a missing path, a
directory that isn't empty, a share without write permission.]

#sect("A Working Session")

#scr(
  "]NMKDIR \"N:TNFS://TMA-3/SCRATCH\"",
  "",
  "]NDIR \"N:TNFS://TMA-3/\"",
  "/ BIN         DIR 001",
  "/ SCRATCH     DIR 001",
  "/ SRC         DIR 001",
  "  HELLO           001",
  "",
  "]NRMDIR \"N:TNFS://TMA-3/SCRATCH\"",
  "",
  "]",
)

// ============================================================
// CHAPTER 5
// ============================================================
#chapter("Chapter 5", "Programs over the Network")

Two commands make the network a place to keep BASIC programs. Your
program library can live on a TNFS server — one copy, reachable from
every Apple II in the house, or the hemisphere.

#cmd("NSAVE", "OPEN 8 + WRITE")
#syntax("NSAVE spec")
Writes the program in memory to the network file named by the spec,
in Applesoft's own tokenized form — the same bytes #cw("SAVE") puts on
disk. The file it makes is what #cw("NLOAD") takes back.
#syntax("NSAVE \"N:TNFS://TMA-3/LIB/STARBASE.BAS\"")

#cmd("NLOAD", "OPEN 4 + READ")
#syntax("NLOAD spec")
Replaces the program in memory with the network file named by the
spec, relinks it, and clears variables — afterwards, #cw("LIST") and
#cw("RUN") behave exactly as after a disk #cw("LOAD").

#important[#cw("NLOAD") is for the #cw("]") prompt only. Like ProDOS's
own rule for a program that replaces itself, issuing it from a running
program would pull the program out from under its own feet.]

#returns[#cw("PATH NOT FOUND") if the file is not there — and the
program in memory is left untouched. #cw("I/O ERROR") for other
refusals. #cw("PROGRAM TOO LARGE") if the file will not fit below
#cw("HIMEM") — the partial load is discarded and memory is left
clean, as after #cw("NEW").]

#sect("A Library Session")

#scr(
  "]10 PRINT \"HELLO FROM THE NET\"",
  "]NSAVE \"N:TNFS://TMA-3/HELLO.BAS\"",
  "",
  "]NEW",
  "",
  "]NLOAD \"N:TNFS://TMA-3/HELLO.BAS\"",
  "",
  "]RUN",
  "HELLO FROM THE NET",
  "",
  "]",
)

#byway[The saved image is a tokenized Applesoft program, not text —
compact, exact, and instantly loadable, but meant for Apple IIs. To
publish source for other machines to read, print the listing through
the FujiNet printer (Chapter 8) instead.]

// ============================================================
// CHAPTER 6
// ============================================================
#chapter("Chapter 6", "Reading JSON")

The modern web answers in JSON — nested braces and quoted keys, easy
for a server, miserable for a 6502. So the 6502 doesn't do it. The
FujiNet parses the document *on the device*, and BASIC asks for values
by name, one at a time, each arriving as a tidy string.

The dance is always: #cw("NOPEN") the document, #cw("NJSONPARSE") it,
then #cw("NJSONQUERY") for each value you want.

#cmd("NJSONPARSE", "CONTROL $FC + 'P'")
#syntax("NJSONPARSE channel")
Switches an open channel into JSON mode and parses the document it is
reading. The channel must already be #cw("NOPEN")ed (mode 4) on
something that serves JSON. Parse once; query as often as you like.

#cmd("NJSONQUERY", "CONTROL 'Q' + READ")
#syntax("NJSONQUERY channel, result$, query")
Looks up one value in the parsed document and assigns it, as text, to
the string variable #text(style: "italic")[result\$]. The
#text(style: "italic")[query] is a slash path from the top of the
document — a quoted literal or a string variable:
#ptable(
  ("Query", "Finds"),
  ("/city", "the value of key \"city\" at the top level"),
  ("/results/0/name", "key \"name\" of the first element of array \"results\""),
  ("/main/temp", "key \"temp\" inside object \"main\""),
)
Numbers index into arrays, counting from zero. A value that does not
exist comes back as the empty string — test with #cw("LEN(R$)").
Values longer than 255 characters are truncated to fit a BASIC string.

#sect("A Worked Example: Where Am I?")

#cw("IP-API.COM") answers with your address and whereabouts, in JSON,
for free:

#listing("6-1", "WHEREAMI — parse and query a live JSON service")[
```
 10 D$ = CHR$(4): Q$ = CHR$(34)
 20 U$ = "N:HTTP://IP-API.COM/JSON/"
 30 PRINT D$;"NOPEN 1,";Q$;U$;Q$;",4,0"
 40 PRINT D$;"NJSONPARSE 1"
 50 PRINT D$;"NJSONQUERY 1,IP$,";Q$;"/query";Q$
 60 PRINT D$;"NJSONQUERY 1,CI$,";Q$;"/city";Q$
 70 PRINT D$;"NJSONQUERY 1,CO$,";Q$;"/country";Q$
 80 PRINT D$;"NCLOSE 1"
 90 PRINT "YOU ARE ";IP$
100 PRINT "IN ";CI$;", ";CO$
```
]

#scr(
  "]RUN",
  "YOU ARE 47.190.140.76",
  "IN DALLAS, UNITED STATES",
  "",
  "]",
)

#byway[Ten lines, no string chopping, no bracket counting. Any JSON
service on the internet — weather, time, news, your own — is now a
BASIC subroutine away.]

// ============================================================
// CHAPTER 7
// ============================================================
#chapter("Chapter 7", "Servers, Credentials, and HTTP")

Three commands round out the set: one turns your Apple II into a
server, one presents credentials, and one gets at the parts of HTTP
that live outside the page body.

#cmd("NACCEPT", "CONTROL 'A'")
#syntax("NACCEPT channel")
Accepts an incoming caller on a *listening* TCP channel. To listen,
open a TCP spec with no host — just a port — and wait for
#cw("NSTATUS") to report a connection:
#syntax("NOPEN 1,\"N:TCP://:6502/\",12,0")
When #text(style: "italic")[conn] goes to 1, someone is on the line;
#cw("NACCEPT") takes the call, and from then on #cw("NREAD") and
#cw("NWRITE") on that channel talk to your caller.
#listing("7-1", "ECHO — a TCP server in a dozen lines")[
```
 10 D$ = CHR$(4)
 20 PRINT D$;"NOPEN 1,";CHR$(34);
    "N:TCP://:6502/";CHR$(34);",12,0"
 30 PRINT "LISTENING ON 6502..."
 40 PRINT D$;"NSTATUS 1,BW,CN,ER"
 50 IF CN = 0 THEN 40
 60 PRINT D$;"NACCEPT 1"
 70 PRINT "CALLER!"
 80 PRINT D$;"NSTATUS 1,BW,CN,ER"
 90 IF BW = 0 AND CN = 1 THEN 80
100 IF BW = 0 THEN PRINT D$;"NCLOSE 1": END
110 PRINT D$;"NREAD 1,A$,BW"
120 PRINT D$;"NWRITE 1,A$,LEN(A$)"
130 PRINT A$;: GOTO 80
```
]
Aim a telnet or #cw("nc") session at your Apple's address, port 6502,
and watch a 1977 machine serve the modern internet, politely repeating
everything you say.

#cmd("NLOGIN", "CONTROL $FD $FE")
#syntax("NLOGIN channel, user$, pass$")
Presents a username and password for #text(style: "italic")[channel]'s
#text(style: "italic")[next] #cw("NOPEN") — so log in first, then
open. Protected TNFS shares and HTTP Basic Authentication both take
their credentials this way.
#listing("7-2", "Opening a protected resource")[
```
 10 D$ = CHR$(4): Q$ = CHR$(34)
 20 PRINT D$;"NLOGIN 1,";Q$;"OPERATOR";Q$;
    ",";Q$;"SECRET";Q$
 30 PRINT D$;"NOPEN 1,";Q$;
    "N:HTTP://MY.SERVER/PRIVATE/";Q$;",4,0"
```
]

#cmd("NHTTPMODE", "CONTROL 'M'")
#syntax("NHTTPMODE channel, mode")
Shifts what an open HTTP channel reads and writes — the page body is
mode 0, the machinery around it is the rest:
#ptable(
  ("Mode", "The channel now"),
  ("0", "reads the response body (the normal state)"),
  ("1", "collects header names you NWRITE, for the next request"),
  ("2", "reads response headers, one per NREAD"),
  ("3", "sets headers: each NWRITE adds one \"Name: value\" line"),
  ("4", "takes POST data: NWRITE the form body, then read the reply"),
)
The common recipe — custom headers on a request — is: open, mode 3,
#cw("NWRITE") each header line, mode 0, then read the body as usual.

#byway[This recipe works because an HTTP open doesn't fire the
request; the FujiNet waits until the first status or read, giving you
this window to set headers or POST data. It is also why #cw("NOPEN")
cannot report an HTTP failure immediately (Chapter 3) — at open time,
nothing has happened yet.]

// ============================================================
// CHAPTER 8
// ============================================================
#chapter("Chapter 8", "The Printer")

The FujiNet is also a printer — a SmartPort printer device that
renders whatever you send into a PDF (or a period-correct emulation
of a classic printer) waiting on the FujiNet's web page. The extension
connects Applesoft to it with two #cw("CALL")s:

#syntax("CALL 32771     printer ON  - output goes to the FujiNet\nCALL 32774     printer OFF - output returns to the screen")

Between the two calls, everything Applesoft prints — #cw("PRINT")
statements, #cw("LIST"), #cw("CATALOG") — goes to the printer instead
of the screen, exactly as if you had issued #cw("PR#1") to a printer
card in slot 1.

#listing("8-1", "A report, on paper(ish)")[
```
 10 CALL 32771
 20 PRINT "STARBASE INVENTORY, STARDATE 2026.7"
 30 FOR I = 1 TO 5
 40 PRINT I;TAB(8);N$(I);TAB(24);Q(I)
 50 NEXT I
 60 CALL 32774
```
]

#sect("How the Paper Works")

Output is gathered a line at a time and sent to the FujiNet at each
carriage return (or when a line passes 80 columns). Turning the
printer *off* delivers any unfinished line, so a #cw("PRINT") ending
in a semicolon is never lost — but the tidiest habit is to let your
last #cw("PRINT") end normally before #cw("CALL 32774").

To print a program listing, use the pair straight from the prompt:

#scr(
  "]CALL 32771",
  "]LIST",
  "]CALL 32774",
  "]",
)

#byway[While the printer is on, the screen is silent — including the
#cw("]") prompts and your own keystrokes, which land on the paper
instead. That's normal #cw("PR#")-style behavior, and it's why the
transcript above shows only what you type.]

#important[If no printer device was present at boot (the banner had no
#cw("FUJINET PRINTER") line), #cw("CALL 32771") does nothing at all —
safe, but silent. Check the FujiNet's printer settings and reboot.]

// ============================================================
// APPENDIX A
// ============================================================
#chapter("Appendix A", "Command Quick Reference")

Arguments: #text(style: "italic")[ch] a channel number 1–15;
#text(style: "italic")[spec] a device spec, quoted or a string
variable; #text(style: "italic")[v] a numeric variable that receives a
value; #text(style: "italic")[v\$] a string variable that receives a
value; #text(style: "italic")[n] a number.

#ptable(
  ("Command", "Arguments", "Does"),
  ("NOPEN", "ch, spec, mode, trans", "open a channel to spec"),
  ("NCLOSE", "ch", "close the channel"),
  ("NSTATUS", "ch, v, v, v", "bytes waiting, connected, error"),
  ("NREAD", "ch, v$, n", "read up to n bytes (max 255)"),
  ("NWRITE", "ch, data$, n", "write first n bytes of data$"),
  ("NJSONPARSE", "ch", "parse the channel's JSON document"),
  ("NJSONQUERY", "ch, v$, query", "fetch one JSON value by /path"),
  ("NCD", "spec", "set the filesystem working prefix"),
  ("NDIR", "spec", "print a directory listing"),
  ("NMKDIR", "spec", "create a directory"),
  ("NRMDIR", "spec", "remove an empty directory"),
  ("NDEL", "spec", "delete a file"),
  ("NLOAD", "spec", "load a program (prompt only)"),
  ("NSAVE", "spec", "save the program in memory"),
  ("NACCEPT", "ch", "accept a caller on a listening channel"),
  ("NLOGIN", "ch, user$, pass$", "credentials for the next NOPEN"),
  ("NHTTPMODE", "ch, n", "HTTP body/header/POST sub-mode"),
)

#v(0.5em)
#ptable(
  ("Statement", "Does"),
  ("CALL 32771", "printer ON: output to the FujiNet printer"),
  ("CALL 32774", "printer OFF: output back to the screen"),
)

#sect("NOPEN Modes and Translation")

#grid(columns: (1fr, 1fr), column-gutter: 14pt,
  ptbl(
    ("Mode", "Meaning"),
    ("4", "read"),
    ("8", "write"),
    ("12", "read/write"),
    ("13", "HTTP POST"),
  ),
  ptbl(
    ("Trans", "Line endings"),
    ("0", "none (binary)"),
    ("1", "CR (Apple)"),
    ("2", "LF (Unix)"),
    ("3", "CR/LF (internet)"),
  ),
)

// ============================================================
// APPENDIX B
// ============================================================
#chapter("Appendix B", "Errors")

#sect("Command Errors")

These stop the command and print a message — or land in your
#cw("ONERR GOTO") handler, where #cw("PEEK(222)") tells them apart:

#ptable(
  ("Message", "PEEK(222)", "Raised when"),
  ("NO DEVICE CONNECTED", "3", "no FujiNet network device was found at boot"),
  ("RANGE ERROR", "2", "a channel number is not 1-15"),
  ("PATH NOT FOUND", "6", "an open names a file or directory that isn't there"),
  ("I/O ERROR", "8", "the FujiNet refused the operation"),
  ("PROGRAM TOO LARGE", "14", "an NLOAD file will not fit below HIMEM"),
  ("?SYNTAX ERROR", "16", "a command's arguments are malformed"),
)

#sect("Channel Status Codes")

The third variable of #cw("NSTATUS") reports the health of an open
channel without interrupting the program:

#ptable(
  ("err", "Meaning"),
  ("1", "all is well"),
  ("136", "end of data - the far side finished cleanly"),
  ("144", "a general, fatal error"),
  ("170", "file not found"),
  ("128-255", "other trouble: connection refused, reset..."),
)

A robust fetch loop treats 136 as success-and-stop, anything else at
or above 128 as failure, and keeps its own counsel about the rest.

// ============================================================
// APPENDIX C
// ============================================================
#chapter("Appendix C", "The Memory Map, and How It Hooks In")

#sect("Where Everything Lives")

#ptable(
  ("Range", "Contents"),
  ("$0801 up", "your Applesoft program, then its variables"),
  ("down to $7C00", "your strings, growing downward"),
  ("$7C00", "HIMEM - BASIC's ceiling while the extension is resident"),
  ("$7C00-$7FFF", "BASIC.SYSTEM's first file buffer lands here"),
  ("$8000-$95FF", "the extension: code, tables, and buffers"),
  ("$9A00-$BEFF", "BASIC.SYSTEM itself"),
  ("$BF00-$BFFF", "ProDOS global page"),
)

The cost of the network, then, is about six K of program space next
to a bare ProDOS boot — a 48K machine keeps roughly 29K for BASIC.

#sect("External Commands, Not Ampersands")

Applesoft cannot take new keywords — its tokenizer and keyword table
are in ROM. The classic workaround, the ampersand hook, sees the line
#text(style: "italic")[after] tokenizing, by which time #cw("NREAD")
has a #cw("READ") token buried in it and #cw("NSTATUS") hides an
#cw("AT"). Matching mangled bytes is a bug farm, and the first
generation of this extension farmed a few.

BASIC.SYSTEM offers the honest path: an *external command* hook
(#cw("EXTRNCMD"), #cw("\$BE06")) that hands over every command line
#text(style: "italic")[before] Applesoft touches it, raw and
untokenized, exactly as it does for #cw("CATALOG"). The N-commands are
therefore first-class ProDOS commands: same prompt, same
#cw("CHR\$(4)") idiom, same error discipline.

#sect("Three Rules of Residency")

For the assembly-minded, the extension survives alongside
BASIC.SYSTEM by honoring three contracts, each learned the hard way
and documented in the source in the back of this book:

#sq[*Decline with carry set.* BASIC.SYSTEM pre-sets carry and jumps
into the external-command hook; carry clear on return means
#text(style: "italic")[claimed]. A recognizer that falls off its
keyword table with carry accidentally clear silently claims every
line typed at the prompt.]

#sq[*Keep BASIC.SYSTEM's memory bookkeeping in sync.* Lowering
#cw("MEMSIZ") is not enough: BI caches its own HIMEM page
(#cw("RSHIMEM"), #cw("\$BEFB")) and restores it when the last file
closes. Set both, or the first #cw("CATALOG") un-protects you.]

#sq[*Leave the first kilobyte above HIMEM empty.* BI places the first
open file's 1K buffer #text(style: "italic")[above] HIMEM — that is
what the stock #cw("\$9600-\$99FF") gap is for. A resident parked
directly at HIMEM gets a directory block written over its code.]

#sq[*Never let a ROM error escape your handler.* The Applesoft
evaluators bail out through #cw("ERROR") on bad input, which abandons
BI's dispatch mid-command and wedges its command processing until
reboot. The extension runs every handler under a private #cw("ONERR")
frame aimed at a one-line decoy program whose #cw("CALL") unwinds the
stack and fails the command properly — so a typo costs you a
#cw("?SYNTAX ERROR"), not the machine.]

The deeper story — SmartPort calls, the NETWORK device, channels and
control codes — is the subject of the companion volume,
#text(style: "italic")[Programming the FujiNet].

// ============================================================
// APPENDIX D — THE COMPLETE SOURCE LISTING
// ============================================================
#let srclisting(path) = pad(left: -mhang, block(breakable: true,
  width: mhang + col-w, fill: code-bg, inset: (x: 10pt, top: 8pt, bottom: 9pt),
  radius: 1.5pt, stroke: (top: 1.6pt + red), {
    set text(font: f-mono, size: 5.6pt, fill: ink)
    set par(leading: 0.4em, spacing: 0.4em, justify: false, first-line-indent: 0pt)
    for l in read(path).split("\n") {
      if l == "" { par(text(" ")) } else { par(text(l)) }
    }
  }))

#chapter("Appendix D", "The Complete Source Listing")

In the tradition of the #text(style: "italic")[Monitor ROM listings]
Apple shipped with the IIe, here is the extension, whole: every
routine, every hard-won comment. Three files of ca65 assembly, built
with the cc65 toolchain (#cw("make apple2") in
#cw("fujinet-nhandler/apple2-new") produces the bootable disk). These
pages are regenerated from the source tree every time the book is
typeset, so what you read here is what you booted.

#sect("equ.inc — equates and constants")
#srclisting("listing/equ.inc")

#sect("fujiapple.s — install, recognizer, and the seventeen commands")
#srclisting("listing/fujiapple.s")

#sect("smartport.inc — the SmartPort transport")
#srclisting("listing/smartport.inc")
