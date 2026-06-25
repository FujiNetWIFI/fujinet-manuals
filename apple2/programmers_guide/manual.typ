// ============================================================
// PROGRAMMING THE FUJINET
// for the Apple II family
//
// A programmer's guide and command reference for talking to a
// FujiNet from 6502 assembly language over SmartPort.
//
// Typeset in tribute to Apple's own technical reference manuals
// of the mid-1980s: cream stock, warm red rules, Helvetica heads,
// the wide scholar's margin — the visual language established by
// the companion "Getting Started with FujiNet" (after the 1984
// Apple IIc Owner's Manual). Body text is Apple Garamond (ITC
// Garamond Condensed), Apple's corporate face. Program listings
// and register dumps are set in the genuine Apple II character
// set (Print Char 21).
//
// Every command code, parameter, and payload layout in this book
// is taken verbatim from the fujinet-firmware and fujinet-lib
// sources — see the colophon for the exact files.
//
// Build: typst compile --font-path fonts manual.typ
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
// thin red rule across the top like a punch-card header. Breakable, so
// long listings (the netcat) flow across pages instead of overflowing.
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
// command reference header: name at left, a red chip at right giving
// the SmartPort call and code byte.  e.g.  cmd("MOUNT HOST", "CONTROL $F9")
#let chip(s) = box(fill: red, inset: (x: 5pt, y: 2.2pt), radius: 2pt,
  text(font: f-head, weight: 700, size: 7.5pt, fill: paper, tracking: 0.3pt, s))

#let cmd(name, tag) = block(above: 1.5em, below: 0.55em, breakable: false, sticky: true, {
  grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
    text(font: f-head, weight: 700, size: 10pt, fill: ink, name),
    chip(tag))
  v(2pt)
  line(length: 100%, stroke: 0.8pt + ink)
})

// a small fielded table for payload / parameter layouts.
// rows: ( ("Offset","Bytes","Meaning"), ... ) — first row is the header
#let ptable(..rows) = block(above: 0.7em, below: 0.9em,
  move(dx: -mhang, box(width: mhang + col-w,
  table(
    columns: (auto, auto, 1fr),
    inset: (x: 7pt, y: 3.4pt),
    align: (left + horizon, left + horizon, left + horizon),
    stroke: none,
    fill: (_, row) => if row == 0 { red } else if calc.odd(row) { chip-bg } else { none },
    table.hline(y: 0, stroke: 0pt),
    ..rows.pos().enumerate().map(((i, r)) => {
      let st = if i == 0 { (font: f-head, weight: 700, size: 7.5pt, fill: paper) }
               else { (font: f-mono, size: 7pt, fill: ink) }
      r.map(cell => text(..st, cell))
    }).flatten()
  ))))

// a two-column "Returns / On error" style note line
#let returns(body) = block(above: 0.4em, below: 0.6em, {
  text(font: f-head, weight: 700, size: 7.5pt, fill: red, "Returns  ")
  text(size: 9.5pt, body)
})

// ============================================================
// GREEN-PHOSPHOR SCREEN (for the occasional terminal transcript)
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
    text(font: f-body, size: 30pt, fill: ink)[Programming the FujiNet])
  #place(top + left, dx: 2.0in, dy: 1.02in,
    text(font: f-body, size: 14.5pt, style: "italic", fill: ink)[for the Apple II])

  // a typographic "listing card" motif in place of a photo
  #place(top + left, dx: 1.1in, dy: 2.0in, box(width: 5.3in, height: 4.4in,
    fill: code-bg, radius: 2pt, stroke: (top: 3pt + red), inset: 20pt, {
      set text(font: f-mono, size: 8pt, fill: ink)
      set par(leading: 0.7em, justify: false)
      let lines = (
        "FINDFN   JSR   SPINIT      ; locate SmartPort",
        "         BCS   NODEV       ; carry = no FujiNet",
        "",
        "OPEN     LDA   #<URL       ; N:HTTPS://...",
        "         LDX   #>URL",
        "         JSR   NETOPEN",
        "",
        "LOOP     JSR   NETSTAT     ; bytes waiting?",
        "         LDA   BW",
        "         BEQ   LOOP",
        "         JSR   NETREAD     ; pull them in",
        "         JSR   COUT        ; and print them",
        "         JMP   LOOP",
        "",
        "; the world, one SmartPort call at a time.",
      )
      lines.map(l => if l == "" { v(0.62em) } else { l }).join(linebreak())
    }))

  #place(bottom + left, dx: 2.0in, dy: -0.62in, box(width: 4.6in,
    par(leading: 0.5em, justify: false,
      text(font: f-body, size: 12.5pt, fill: ink)[
        A programmer's guide and command reference for the FujiNet
        WiFi peripheral, from 6502 assembly language.])))
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
      par[FujiNet's firmware, its client library, and this manual are
      free software, built and given away by a worldwide community of
      Apple II owners. You may copy this book for a friend — in fact,
      we'd be delighted. Source for everything, this booklet included,
      lives at #cw("github.com/FujiNetWIFI").]

      subsect("How This Book Was Verified")
      par[Every command code, parameter, payload layout, and error
      number in this reference was read out of the FujiNet sources, not
      remembered. The firmware side comes from #cw("fujinet-firmware"):
      the SmartPort bus in #cw("lib/bus/iwm/"), the device handlers in
      #cw("lib/device/iwm/") (#cw("iwmFuji.cpp"), #cw("network.cpp"),
      #cw("clock.cpp")), and the master command list in
      #cw("include/fujiCommandID.h"). The host side comes from
      #cw("fujinet-lib"), whose Apple II SmartPort glue lives in
      #cw("apple2/apple2-6502/bus/").]

      subsect("Limitation of Warranties")
      par[Neither the FujiNet community nor its contributors make any
      warranty with respect to this manual or to FujiNet. Everything is
      provided "as is." But unlike 1984, when something bothers you, you
      can read the source, fix it yourself, and send a pull request.]
    },
    {
      subsect("Trademarks")
      par[Apple, the Apple logo, Apple IIc, Apple IIGS, ProDOS, and
      SmartPort are trademarks of Apple Inc. Liron and UniDisk are
      trademarks of Apple Inc. FujiNet is a community project and is not
      affiliated with, endorsed by, or sponsored by Apple Inc.]

      subsect("Conventions")
      par[Program listings and register dumps are set in the genuine
      Apple II character set. Hexadecimal numbers are written with a
      leading dollar sign, as the Apple II has always written them:
      #cw("$F9"), #cw("$C700"). All assembly is in the syntax of the
      #cw("ca65") assembler from the #cw("cc65") suite — the same
      toolchain that builds #cw("fujinet-lib") — so the examples can be
      assembled and linked against the library as-is.]

      par[Copyright 2026 the FujiNet contributors. Released under the GNU
      General Public License v3 as part of the #cw("fujinet-manuals")
      repository.]

      v(4pt)
      par[Dedicated to everyone still writing 6502 by hand — and to the
      memory of the disk drive, which taught the Apple II to remember,
      and which FujiNet now teaches to dream.]
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
  #text(font: f-body, size: 24pt)[Programming the FujiNet]
  #v(2pt)
  #par(leading: 0.5em, text(font: f-body, size: 12.5pt, style: "italic")[
    A guide to driving the FujiNet WiFi peripheral from 6502 assembly
    language over SmartPort, with a complete reference to the firmware's
    command set — for the Apple #box("IIc"), Apple IIc Plus, Apple IIGS,
    and every Apple II with a SmartPort.])

  #v(0.55in)
  #line(length: 100%, stroke: 0.8pt + red)
  #v(10pt)
  #set text(size: 9.6pt)
  #par[This book picks up where #text(style: "italic")[Getting Started
  with FujiNet] leaves off. That book taught your fingers; this one
  teaches your assembler. By the last chapter you will have written a
  working #text(style: "italic")[netcat] — open a socket, read it,
  write it — in a couple of pages of 6502, talking to hardware that
  did not exist when the 6502 did.]
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

A FujiNet is, electrically, a small computer of its own — an ESP32 with
WiFi, a memory-card slot, and a wire that pretends to be a disk drive.
The pretending is the clever part. To your Apple II, the FujiNet is not
a network card and not a co-processor. It is a *SmartPort*: the same
intelligent peripheral bus that an Apple #box("IIc"), a IIGS, or a Liron
card uses to talk to UniDisk 3.5" drives and hard disks. Everything in
this book is, underneath, a SmartPort call.

That single fact is what makes the FujiNet so easy to program. You do
not install a driver. You do not patch the firmware. You find the
SmartPort, you ask it which devices are attached, and you discover —
alongside whatever disk drives are present — a handful of devices that
were never made of metal:

#sq[*THE\_FUJI* (device type #cw("$10")) — the control device. It mounts
disk images, browses hosts, scans WiFi, reads the clock, hashes data,
and keeps the slots that CONFIG shows you.]
#sq[*NETWORK* (device type #cw("$11")) — the #cw("N:") device. It opens
TCP, UDP, HTTP, TNFS, FTP, SMB, SSH and TELNET connections and moves
bytes across them, eight channels at a time.]
#sq[*FN\_CLOCK* (device type #cw("$13")) — a real-time clock with
time-zone awareness.]
#sq[*CPM* (type #cw("$12")), a #cw("Z80") co-processor channel, and the
*printer* and *modem* devices round out the family.]

#sect("Two Ways In")

#mnote[#cw("fujinet-lib") is the library this book quotes from. It ships
prebuilt for #cw("apple2") and #cw("apple2enh") targets and links with
#cw("cc65"). If you are writing in C, call its functions directly and
skip to the reference tables.]
There are two heights at which you can program the FujiNet, and this
book teaches the lower one.

The high road is #cw("fujinet-lib"), the community client library. It
gives you C functions like #cw("network_open()") and
#cw("fuji_mount_host_slot()") and hides the bus entirely. It is the
right tool for an application, and the reference chapters name the
library function beside every raw command so you can find it.

The low road — the subject of this book — is to issue the SmartPort
calls yourself. It costs you a page of set-up code, and buys you three
things: you understand exactly what crosses the wire; you depend on
nothing but the Apple's own ROM; and you can fit FujiNet support into a
boot sector, a demo, or a language that has no C compiler. Every
example here is raw 6502, and the last chapter — a working
#text(style: "italic")[netcat] — uses nothing but the routines this
book builds up.

#sect("What You Should Already Know")

#sq[6502 assembly language, and an assembler. The listings use
#cw("ca65") syntax, but they translate to Merlin or the mini-assembler
without surprises.]
#sq[How a SmartPort or ProDOS block device is found in the slots — or a
willingness to read Chapter 1, which derives it from scratch.]
#sq[Enough of CONFIG (from #text(style: "italic")[Getting Started with
FujiNet]) to know what a "host slot" and a "device slot" are.]

#sect("How the Reference Is Laid Out")

Chapters 1 and 2 build the foundation: how to find the FujiNet and how a
single call is shaped. Chapters 3 through 5 walk the three devices you
will actually program — Network, the Fuji control device, and the
Clock — and every command in them is written up the same way:

#cmd("EXAMPLE COMMAND", "CONTROL $F9")
A one-line synopsis of what the command does, then the payload your
program must build (for #cw("CONTROL") and #cw("WRITE")) or the layout
of what comes back (for #cw("STATUS") and #cw("READ")):
#ptable(
  ("Offset", "Bytes", "Meaning"),
  ("0–1", "2", "payload length, little-endian (set by you)"),
  ("2", "1", "an argument byte"),
)
#returns[#cw("$00") and carry clear on success; a SmartPort error in
#cw("A") with carry set otherwise. The fujinet-lib equivalent is named
here too.]
A short listing follows each, showing the call in context. Read the
next two chapters in order; after that, dip in wherever you like.

// ============================================================
// CHAPTER 1 — THE SMARTPORT CONNECTION
// ============================================================
#chapter("Chapter 1", "The SmartPort Connection")

Before you can send the FujiNet a single command you must do two things
the ROM will not do for you: find the *SmartPort dispatcher* — the entry
point in some peripheral card's firmware that accepts SmartPort calls —
and learn the *unit number* the FujiNet's devices answer to. This
chapter does the first. It owes everything to the Apple SmartPort
firmware specification, and the code is a direct transliteration of
#cw("fujinet-lib")'s #cw("sp_init.s") and #cw("sp_status_control_dispatch.s").

#sect("What a SmartPort Is")

A SmartPort is a chain of intelligent block devices hanging off one
slot. Unlike the Disk II — where the Apple shovels raw bits — a
SmartPort device is told what to do in *packets*: a command number and a
small *parameter list* in memory. The card's firmware does the rest. The
Apple #box("IIc") and IIc Plus have a SmartPort built in; a IIGS has one
per smart slot; an Apple II Plus or IIe gets one from a Liron card or
any SmartPort-capable controller.

#mnote[The signature is the Pascal 1.1 firmware protocol with the
SmartPort byte (#cw("$00")) at offset 7. It is exactly the test the
FujiNet firmware itself uses to recognise a host.]
The FujiNet plugs into that chain and adds its own devices to it. To the
ROM they are indistinguishable from disk drives, which is why no driver
is needed. Your job is only to locate the chain and address the right
link.

#sect("Finding the Dispatcher")

A SmartPort card identifies itself by four bytes near the top of its
#cw("$Cn00") ROM page, where #cw("n") is the slot number. Read low to
high, slot 7 down to slot 1, and test each candidate:

#ptable(
  ("Address", "Value", "Meaning"),
  ("$Cn01", "$20", "Pascal 1.1 firmware protocol"),
  ("$Cn03", "$00", "  \" "),
  ("$Cn05", "$03", "block device"),
  ("$Cn07", "$00", "SmartPort capable"),
)

When all four match, the byte at #cw("$CnFF") is the offset to the
card's ProDOS entry point; the SmartPort entry sits *three bytes past
it*. Add, and you have the address to which every call in this book is a
#cw("JSR"). Listing 1-1 finds it and patches that address straight into
the dispatch routine of Listing 1-3.

#listing("1-1", "Locate the SmartPort dispatcher (SPINIT)")[
```
; --- zero page & scratch -------------------------------
PTR     =   $06          ; a 16-bit scratch pointer
;
; SPINIT: scan slots 7..1 for a SmartPort signature.
;   exit: carry CLEAR and SPVEC patched if found
;         carry SET if no SmartPort in any slot
;
SPINIT  LDX  #$C7         ; high byte of $C700 (slot 7)
SI_LOOP STX  PTR+1
        LDA  #$00
        STA  PTR          ; PTR -> $Cn00
        LDY  #$01         ; test offsets 1,3,5,7
SI_SIG  LDA  (PTR),Y
        CMP  SIGTAB,Y
        BNE  SI_NEXT
        INY
        INY
        CPY  #$09
        BNE  SI_SIG
; --- signature matched: compute dispatch address -------
        LDY  #$FF
        LDA  (PTR),Y      ; ProDOS entry offset at $CnFF
        CLC
        ADC  #$03         ; +3 -> SmartPort entry
        STA  SPVEC        ; low byte of dispatch
        LDA  PTR+1
        ADC  #$00         ; carry into high byte
        STA  SPVEC+1      ; high byte = $Cn (+carry)
        CLC               ; success
        RTS
SI_NEXT DEX
        CPX  #$C0
        BNE  SI_LOOP
        SEC               ; no SmartPort found
        RTS
; offsets 0,2,4,6 are never read, any filler will do
SIGTAB  .BYTE $FF,$20,$FF,$00,$FF,$03,$FF,$00
```
]

#important[#cw("SPINIT") only finds the bus. It does not tell you which
unit is the FujiNet — a slot may carry real disks too. Unit discovery is
Chapter 2's job, and it depends on the call machinery built next.]

#sect("The Shape of a Call")

Every SmartPort call is the same three-step ritual: build a parameter
list in memory, #cw("JSR") to the dispatcher, and follow the #cw("JSR")
with the command number and the address of your list — *inline, in the
code stream*:

#listing("1-2", "The SmartPort calling sequence")[
```
        JSR   dispatch      ; the address SPINIT found
        .BYTE command       ; 0=STATUS 4=CONTROL 8=READ 9=WRITE
        .WORD paramlist     ; pointer to the list below
        ; <-- control returns HERE; A = error code, C = error
```
]

#mnote[This is why the dispatcher is reached by #cw("JSR") and not
#cw("JMP"): it pops the return address, reads the three bytes that
follow it, then pushes a corrected address so the #cw("RTS") lands past
them.]
The dispatcher reads those three bytes, then bumps its own return
address past them so your program resumes on the instruction after the
#cw("$.WORD"). On return, #cw("A") holds the result code (#cw("$00") =
success) and the carry flag mirrors it; #cw("X") and #cw("Y") hold the
count of bytes transferred, low then high.

The parameter list itself is a flat block of bytes. Its first byte is
the *parameter count*, which depends on the call; the rest carry the
unit, a pointer to your data buffer, and either a one-byte command code
(for #cw("STATUS") and #cw("CONTROL")) or a two-byte length (for
#cw("READ") and #cw("WRITE")):

#ptable(
  ("Offset", "Bytes", "Field"),
  ("0", "1", "parameter count (3, 3, 4, 4)"),
  ("1", "1", "unit number (the device id)"),
  ("2–3", "2", "buffer pointer, low/high"),
  ("4", "1", "STATUS / CONTROL code   ---or---"),
  ("4–5", "2", "READ / WRITE byte count, low/high"),
)

The four calls this book uses, with their command numbers and parameter
counts, are taken verbatim from #cw("sp.inc"):

#ptable(
  ("Call", "Cmd #", "Pcount", "Purpose"),
  ("STATUS", "$00", "3", "ask a device for data"),
  ("CONTROL", "$04", "3", "send a device a command + data"),
  ("READ", "$08", "4", "read a stream of bytes"),
  ("WRITE", "$09", "4", "write a stream of bytes"),
)

#byway[SmartPort also defines #cw("OPEN") (#cw("$06")) and #cw("CLOSE")
(#cw("$07")). The FujiNet's character devices accept them but do nothing
useful with them — connections are opened and closed with #cw("CONTROL")
codes instead, as Chapter 3 shows — so this book never issues them.]

#sect("Four Routines You'll Use Everywhere")

Rather than hand-assemble a parameter list at every call site, build it
once. The routines in Listing 1-3 keep a single list (#cw("CMDLIST")), a
single 512-byte buffer (#cw("PAYLOAD")), and a one-byte destination
(#cw("SPUNIT")) that you set before calling. They are the assembly twins
of #cw("fujinet-lib")'s #cw("sp_status"), #cw("sp_control"),
#cw("sp_read"), and #cw("sp_write"); every later example calls them.

#listing("1-3", "The call primitives (SPSTAT, SPCTRL, SPREAD, SPWRITE)")[
```
PAYLOAD =   $1000        ; 512-byte data buffer (page-aligned)
;
SPUNIT  .BYTE 0          ; destination device id, set before a call
SPERR   .BYTE 0          ; result code from the last call
SPCNT   .WORD 0          ; bytes transferred (from X/Y)
CMDLIST .RES  10         ; the parameter list
;
; SPSTAT - STATUS call.  A = status code.
SPSTAT  STA  CMDLIST+4
        LDA  #3
        STA  CMDLIST
        LDA  #$00         ; SP_CMD_STATUS
        STA  SPCMD
        JMP  SPSETUP
; SPCTRL - CONTROL call.  A = control code.
SPCTRL  STA  CMDLIST+4
        LDA  #3
        STA  CMDLIST
        LDA  #$04         ; SP_CMD_CONTROL
        STA  SPCMD
        JMP  SPSETUP
; SPREAD - READ call.   A/X = byte count (lo/hi).
SPREAD  STA  CMDLIST+4
        STX  CMDLIST+5
        LDA  #4
        STA  CMDLIST
        LDA  #$08         ; SP_CMD_READ
        STA  SPCMD
        JMP  SPSETUP
; SPWRITE - WRITE call.  A/X = byte count (lo/hi).
SPWRITE STA  CMDLIST+4
        STX  CMDLIST+5
        LDA  #4
        STA  CMDLIST
        LDA  #$09         ; SP_CMD_WRITE
        STA  SPCMD
; --- shared: fill unit + buffer pointer, then dispatch --
SPSETUP LDA  SPUNIT
        STA  CMDLIST+1
        LDA  #<PAYLOAD
        STA  CMDLIST+2
        LDA  #>PAYLOAD
        STA  CMDLIST+3
        JSR  $FFFF        ; <-- operand patched by SPINIT
SPVEC   =    *-2
SPCMD   .BYTE $00         ; command number (patched above)
        .WORD CMDLIST     ; pointer to the parameter list
        STA  SPERR        ; A = result; C already reflects it
        STX  SPCNT
        STY  SPCNT+1
        LDA  SPERR
        RTS
```
]

#warning[#cw("SPCMD") and the #cw("JSR") operand at #cw("SPVEC") live in
the code stream and are modified as the program runs. Keep these
routines in RAM, never in ROM, and do not let an interrupt re-enter them
mid-call.]

#sect("Reading the Result")

A call comes back with its error code in #cw("A") and the carry flag set
on any error, so the idiom is simply #cw("BCC ok") / handle the error.
The codes are SmartPort's own (from #cw("iwm.h")); the ones you will
actually meet are below, and Appendix A lists them all.

#ptable(
  ("Code", "Name", "Means"),
  ("$00", "NOERROR", "success"),
  ("$01", "BADCMD", "device doesn't know that command"),
  ("$21", "BADCTL", "bad STATUS / CONTROL code"),
  ("$22", "BADCTLPARM", "bad parameter in the payload"),
  ("$27", "IOERROR", "the device tried and failed"),
  ("$28", "NODRIVE", "no such unit on the bus"),
  ("$2F", "OFFLINE", "device offline / no media"),
)

With Listing 1-3 assembled, a complete (if pointless) first call — ask
unit 1 for its general status — is four instructions:

#listing("1-4", "Your first SmartPort call")[
```
        JSR   SPINIT       ; find the bus
        BCS   NODEV
        LDA   #1
        STA   SPUNIT       ; talk to unit 1
        LDA   #$00         ; status code 0 = device status
        JSR   SPSTAT
        BCS   OOPS         ; A holds the SmartPort error
        ; PAYLOAD now holds a 4-byte status; SPCNT = 4
```
]

The next chapter turns that "unit 1" guess into a real search for the
FujiNet, and explains the one convention — the payload's length header —
that every Fuji and Network command obeys.

// ============================================================
// CHAPTER 2 — FINDING THE FUJINET, SHAPING A COMMAND
// ============================================================
#chapter("Chapter 2", "Finding the FujiNet, Shaping a Command")

The bus may carry real disks as well as the FujiNet's invented devices,
so you cannot assume a unit number — you must ask. SmartPort lets you
enumerate the chain and interrogate each link, and every FujiNet device
announces itself with a *type byte* you can recognise.

#sect("The Device Roll Call")

A #cw("STATUS") call to *unit 0* with status code #cw("$00") returns the
number of devices on the bus in the first payload byte. Walk the units
from #cw("1") upward and ask each for its *Device Information Block*
(DIB) with status code #cw("$03"). The DIB is a fixed 25-byte record;
the byte you want is at offset 21 — the device *type*:

#ptable(
  ("Offset", "Bytes", "DIB field"),
  ("0", "1", "status byte"),
  ("1–3", "3", "block size (0 for FujiNet devices)"),
  ("4", "1", "name length"),
  ("5–20", "16", "device name, space-padded (\"NETWORK\", ...)"),
  ("21", "1", "device TYPE  <-- match on this"),
  ("22", "1", "device subtype"),
  ("23–24", "2", "firmware version"),
)

The FujiNet type bytes are defined in #cw("iwm.h"). These are the
constants you search for:

#ptable(
  ("Type", "Device", "What it is"),
  ("$10", "THE_FUJI", "control: slots, mounts, WiFi, hashing"),
  ("$11", "NETWORK", "the N: device — sockets and protocols"),
  ("$12", "CPM", "Z80 / CP/M co-processor channel"),
  ("$13", "FN_CLOCK", "real-time clock"),
  ("$14", "(printer)", "the FujiNet printer"),
  ("$15", "(modem)", "the FujiNet modem"),
)

Listing 2-1 is a generic search. Hand it a type byte; it returns the
unit number in #cw("A"), or zero with carry set if no such device is on
the bus. It is the spine of #cw("fujinet-lib")'s #cw("sp_find_device").

#listing("2-1", "Find a device by type (FINDDEV)")[
```
WANT    .BYTE 0          ; the type we're hunting for
COUNT   .BYTE 0          ; devices reported on the bus
IDX     .BYTE 0          ; current unit under test
;
; FINDDEV: A = wanted type byte ($10, $11, ...).
;   exit: A = unit (1..n), carry CLEAR if found
;         A = 0, carry SET if not found
;
FINDDEV STA  WANT
        LDA  #0
        STA  SPUNIT       ; unit 0...
        LDA  #$00         ; ...status 0 = device count
        JSR  SPSTAT
        BCS  FD_NONE
        LDA  PAYLOAD      ; count in first byte
        BEQ  FD_NONE
        STA  COUNT
        LDA  #1
        STA  IDX
FD_LOOP LDA  IDX
        STA  SPUNIT
        LDA  #$03         ; DIB request
        JSR  SPSTAT
        BCS  FD_SKIP      ; no DIB for this unit
        LDA  PAYLOAD+21   ; the type byte
        CMP  WANT
        BEQ  FD_FOUND
FD_SKIP INC  IDX
        LDA  IDX
        CMP  COUNT
        BCC  FD_LOOP
        BEQ  FD_LOOP
FD_NONE LDA  #0
        SEC
        RTS
FD_FOUND LDA IDX
        CLC               ; A = unit number
        RTS
```
]

Two thin wrappers name the devices you reach for most. Keep the results;
you will pass them as #cw("SPUNIT") before every command:

#listing("2-2", "Name the two devices you'll use (FINDFUJI, FINDNET)")[
```
FUJIID  .BYTE 0
NETID   .BYTE 0
;
FINDFUJI LDA #$10
        JSR  FINDDEV
        STA  FUJIID
        RTS
FINDNET LDA  #$11
        JSR  FINDDEV
        STA  NETID
        RTS
```
]

#byway[Historically the Fuji control device was bolted onto disk unit 0,
and very old firmware may still answer there. #cw("fujinet-lib") keeps a
fallback that looks for a block device named #cw("DISK_0") if no
#cw("$10") type is found. Current firmware exposes #cw("THE_FUJI")
properly, so a plain type search is enough.]

#sect("The Length Header")

Here is the one rule that governs every Fuji and Network command. When
you send a device data — any #cw("CONTROL") call, and the data half of a
#cw("WRITE") — the firmware first reads a *length*: the first two bytes
of your payload, low byte then high, give the number of bytes that
follow. The firmware (#cw("iwm_decode_data_packet")) uses it to know how
much to pull off the wire. So a #cw("CONTROL") payload always looks like
this:

#ptable(
  ("Offset", "Bytes", "Meaning"),
  ("0", "1", "length low byte"),
  ("1", "1", "length high byte"),
  ("2…", "N", "the command's own arguments"),
)

#important[The length counts the bytes *after* the two-byte header — the
arguments only. Forget it, or count it wrong, and the device reads
garbage and returns #cw("$22") (BADCTLPARM). Every #cw("CONTROL")
example in this book sets bytes 0 and 1 first.]

A #cw("STATUS") call is the mirror image: you do not send a length, you
*receive* data. The device fills #cw("PAYLOAD") with its reply and tells
you the size in #cw("X")/#cw("Y") (which Listing 1-3 saved in
#cw("SPCNT")). Read it straight out of the buffer.

#sect("Commands That Come in Pairs")

Because #cw("CONTROL") sends and #cw("STATUS") receives, several
operations take *both*: a #cw("CONTROL") to pose the question or stage
the work, then a #cw("STATUS") with the *same* code to collect the
answer. Reading a directory entry, running a JSON query, and computing a
hash all follow this two-step. When a reference entry shows two chips —
#chip("CONTROL $F6") #chip("STATUS $F6") — that is what it means: send,
then fetch.

With discovery and the length rule in hand, every command in the rest of
the book reduces to: point #cw("SPUNIT") at the right device, lay out the
payload, and call one of the four primitives. The next three chapters are
just that, command by command.

// ============================================================
// CHAPTER 3 — THE NETWORK DEVICE (N:)
// ============================================================
#chapter("Chapter 3", "The Network Device")

The Network device — type #cw("$11"), the one you reach as #cw("N:") from
BASIC — is where the FujiNet earns its name. Through it you open TCP and
UDP sockets, fetch URLs over HTTP and HTTPS, mount remote filesystems
over TNFS, FTP, and SMB, and even tunnel TELNET and SSH. All of it
arrives through the same four SmartPort primitives from Chapter 1; the
protocol is chosen by a *device spec* string, and the verbs are
#cw("CONTROL") codes that happen to be ASCII letters.

#sect("The Device Spec")

Every network command is addressed to a string of the form

#align(center, cw("N[x]:PROTO://host[:port]/path"))

#mnote[The protocol is matched in the firmware's #cw("ProtocolParser").
Names are upper-case. Omit the unit digit and #cw("1") is assumed.]
where #cw("x") is the channel number 1–8, #cw("PROTO") is one of the
schemes below, and the rest is the resource. The firmware recognises:

#ptable(
  ("Scheme", "Use", "Scheme", "Use"),
  ("TCP", "raw TCP socket", "TNFS", "remote disk filesystem"),
  ("UDP", "datagram socket", "FTP", "file transfer"),
  ("HTTP", "web (cleartext)", "SMB", "Windows shares"),
  ("HTTPS", "web (TLS)", "SSH", "secure shell"),
  ("TELNET", "telnet", "", ""),
)

#sect("Channels and the Device Unit")

Mind the difference between two "unit" numbers. The SmartPort *device*
unit — what you put in #cw("SPUNIT") — is the Network device's id from
#cw("FINDNET"); it never changes. The *channel* (the #cw("x") in
#cw("Nx:"), 1–8) is a logical sub-unit selected by a #cw("CONTROL")
code, #cw("$FA"), before you operate on it. Send it once when you switch
channels; every later call acts on the selected one.

#cmd("SET CHANNEL", "CONTROL $FA")
Selects which #cw("Nx:") channel subsequent network commands act on.
#ptable(
  ("Offset", "Bytes", "Value"),
  ("0–1", "2", "length = $0001"),
  ("2", "1", "channel number, 1–8"),
)
#returns[#cw("$00") on success. fujinet-lib: #cw("network_set_unit()"),
called automatically inside every other network call.]
#listing("3-1", "Select a channel (NETCHAN)")[
```
; NETCHAN: A = channel number (1..8)
NETCHAN STA  PAYLOAD+2
        LDA  #1
        STA  PAYLOAD       ; length low  = 1
        LDA  #0
        STA  PAYLOAD+1     ; length high = 0
        LDA  NETID
        STA  SPUNIT
        LDA  #$FA          ; NETCMD_SET_CHANNEL
        JMP  SPCTRL
```
]

#sect("Opening and Closing")

#cmd("OPEN", "CONTROL $4F  'O'")
Instantiates the protocol named in the device spec and connects. The
payload carries an access *mode* and a translation *mode*, then the spec
and a terminating zero.
#ptable(
  ("Offset", "Bytes", "Value"),
  ("0–1", "2", "length = (spec length) + 3"),
  ("2", "1", "access mode (see table)"),
  ("3", "1", "translation mode (see table)"),
  ("4…", "N+1", "device spec string, NUL-terminated"),
)
#grid(columns: (1fr, 1fr), column-gutter: 14pt,
  ptable(
    ("Mode", "Access"),
    ("$04", "read"),
    ("$08", "write"),
    ("$0C", "read/write"),
    ("$0D", "HTTP POST"),
    ("$05", "HTTP DELETE"),
  ),
  ptable(
    ("Trans", "Line endings"),
    ("$00", "none (binary)"),
    ("$01", "CR"),
    ("$02", "LF"),
    ("$03", "CR/LF"),
    ("$04", "PETSCII"),
  ),
)
#returns[#cw("$00") on success; #cw("$22") if the spec is malformed.
Check the device error with a #cw("STATUS") call afterwards. fujinet-lib:
#cw("network_open()").]
#listing("3-2", "Open a connection (NETOPEN, COPYSPEC)")[
```
URLPTR  =   $08          ; zp pointer -> device spec
MODE    .BYTE 0
TRANS   .BYTE 0
;
; NETOPEN: URLPTR -> NUL-terminated spec; MODE, TRANS set.
;          select the channel first with NETCHAN.
NETOPEN JSR  COPYSPEC     ; copy spec to PAYLOAD+4, Y = length
        TYA
        CLC
        ADC  #3           ; +mode +trans +NUL
        STA  PAYLOAD      ; length low
        LDA  #0
        ADC  #0
        STA  PAYLOAD+1    ; length high (spec may exceed 252)
        LDA  MODE
        STA  PAYLOAD+2
        LDA  TRANS
        STA  PAYLOAD+3
        LDA  NETID
        STA  SPUNIT
        LDA  #'O'         ; NETCMD_OPEN
        JMP  SPCTRL
;
; COPYSPEC: copy the spec (with its NUL) to PAYLOAD+4.
;           exit Y = string length (offset of the NUL).
COPYSPEC LDY #0
CS_LOOP LDA  (URLPTR),Y
        STA  PAYLOAD+4,Y
        BEQ  CS_DONE      ; the NUL is now copied
        INY
        BNE  CS_LOOP
CS_DONE RTS
```
]

#cmd("CLOSE", "CONTROL $43  'C'")
Closes the channel, flushes and frees its buffers. The spec identifies
the channel; only its unit digit really matters.
#ptable(
  ("Offset", "Bytes", "Value"),
  ("0–1", "2", "length = (spec length) + 1"),
  ("2…", "N+1", "device spec string, NUL-terminated"),
)
#returns[#cw("$00") on success. fujinet-lib: #cw("network_close()").]
#listing("3-3", "Close a connection (NETCLOSE)")[
```
NETCLOSE LDY #0
NC_LOOP LDA  (URLPTR),Y
        STA  PAYLOAD+2,Y
        BEQ  NC_DONE
        INY
        BNE  NC_LOOP
NC_DONE INY               ; count the NUL
        STY  PAYLOAD      ; length low
        LDA  #0
        STA  PAYLOAD+1    ; length high
        LDA  NETID
        STA  SPUNIT
        LDA  #'C'         ; NETCMD_CLOSE
        JMP  SPCTRL
```
]

#sect("Status, Reading, and Writing")

These three are the working day of the Network device. #cw("STATUS")
tells you how many bytes have arrived and whether the far end is still
connected; #cw("READ") drains them; #cw("WRITE") sends.

#cmd("STATUS", "STATUS $53  'S'")
Returns the channel's pending byte count, connection flag, and the
device-specific error code.
#ptable(
  ("Offset", "Bytes", "Returned value"),
  ("0–1", "2", "bytes waiting to be read"),
  ("2", "1", "connected: 1 = open, 0 = far end closed"),
  ("3", "1", "device error (1 = OK, 136 = EOF)"),
)
#returns[Byte count also left in #cw("SPCNT"). fujinet-lib:
#cw("network_status()").]
#listing("3-4", "Poll a channel (NETSTAT)")[
```
BW      .WORD 0          ; bytes waiting
CONN    .BYTE 0          ; connected flag
NERR    .BYTE 0          ; device error
;
NETSTAT LDA  NETID
        STA  SPUNIT
        LDA  #'S'         ; NETCMD_STATUS
        JSR  SPSTAT
        BCS  NS_X
        LDA  PAYLOAD
        STA  BW
        LDA  PAYLOAD+1
        STA  BW+1
        LDA  PAYLOAD+2
        STA  CONN
        LDA  PAYLOAD+3
        STA  NERR
NS_X    RTS
```
]

#cmd("READ", "READ  (cmd $08)")
Reads up to the requested number of bytes — never more than are waiting,
and never more than 512 in one call — into #cw("PAYLOAD"). Always poll
#cw("STATUS") first so you ask only for what is there.
#returns[Data in #cw("PAYLOAD"); actual count in #cw("SPCNT").
fujinet-lib: #cw("network_read()") (which loops this for you).]
#listing("3-5", "Read what's waiting (NETREAD)")[
```
; NETREAD: read BW bytes (caller guarantees BW <= 512) into PAYLOAD
NETREAD LDA  NETID
        STA  SPUNIT
        LDA  BW
        LDX  BW+1
        JSR  SPREAD        ; A/X = byte count
        RTS                ; data in PAYLOAD, SPCNT = bytes read
```
]

#cmd("WRITE", "WRITE  (cmd $09)")
Sends bytes from #cw("PAYLOAD") to the channel. Write at most 512 per
call; loop for more.
#returns[#cw("$00") on success. fujinet-lib: #cw("network_write()").]
#listing("3-6", "Write a buffer (NETWRITE)")[
```
; NETWRITE: A/X = byte count (lo/hi); data already in PAYLOAD
NETWRITE LDY NETID
        STY  SPUNIT
        JMP  SPWRITE       ; A/X preserved; returns A = error
```
]

#sect("A Complete Exchange: HTTP GET")

The five routines above are enough to fetch a web page. Select a channel,
open the URL for reading, then poll-and-read until the far end signals
EOF (device error #cw("136")). Listing 3-7 prints a URL to the 40-column
screen through the monitor's #cw("COUT").

#listing("3-7", "Fetch a URL and print it")[
```
COUT    =   $FDED        ; monitor character out
;
GET     JSR  SPINIT
        BCS  NODEV
        JSR  FINDNET      ; -> NETID
        LDA  NETID
        BEQ  NODEV
        LDA  #1
        JSR  NETCHAN      ; use N1:
        LDA  #<URL
        STA  URLPTR
        LDA  #>URL
        STA  URLPTR+1
        LDA  #$04         ; mode = read
        STA  MODE
        LDA  #$00         ; trans = none
        STA  TRANS
        JSR  NETOPEN
        BCS  DONE
GLOOP   JSR  NETSTAT
        LDA  NERR
        CMP  #136         ; EOF?
        BEQ  DONE
        LDA  BW
        ORA  BW+1
        BEQ  GLOOP        ; nothing yet, poll again
        ; clamp BW to 512 if larger (omitted for brevity)
        JSR  NETREAD
        LDX  #0
PLOOP   LDA  PAYLOAD,X
        ORA  #$80         ; high bit set for the Apple video
        JSR  COUT
        INX
        CPX  SPCNT
        BNE  PLOOP
        JMP  GLOOP
DONE    JSR  NETCLOSE
        RTS
URL     .BYTE "N1:HTTP://FUJINET.ONLINE/", 0
```
]

#warning[#cw("READ") returns at most 512 bytes, so clamp #cw("BW") to 512
before #cw("NETREAD") when a channel has more than that waiting. The
library's #cw("network_read") does this; the netcat in Appendix C shows
the few extra instructions.]

#sect("Credentials")

For schemes that authenticate — FTP, SMB — set a username and password
*before* #cw("OPEN"). Both are #cw("CONTROL") codes carrying a fixed
256-byte string field.

#cmd("USERNAME / PASSWORD", "CONTROL $FD / $FE")
#ptable(
  ("Offset", "Bytes", "Value"),
  ("0–1", "2", "length = $0100 (256)"),
  ("2…", "256", "credential string (NUL-padded)"),
)
#returns[#cw("$00") on success. Username is #cw("$FD"), password
#cw("$FE"). No library wrapper on the Apple II — issue them raw.]

#sect("Filesystem Operations")

When a channel speaks a filesystem protocol (TNFS, FTP, SMB, even HTTP
with WebDAV), six #cw("CONTROL") codes manage files and directories.
Each takes the same payload — a device spec naming the target — so one
example covers them all.

#ptable(
  ("Code", "Char", "Operation", "fujinet-lib"),
  ("$21", "!", "delete file", "network_fs_delete"),
  ("$20", "(sp)", "rename (spec is from,to)", "network_fs_rename"),
  ("$23", "#", "lock (make read-only)", "network_fs_lock"),
  ("$24", "$", "unlock", "network_fs_unlock"),
  ("$2A", "*", "make directory", "network_fs_mkdir"),
  ("$2B", "+", "remove directory", "network_fs_rmdir"),
  ("$2C", ",", "change directory", "network_fs_cd"),
)
#listing("3-8", "Delete a remote file")[
```
; delete the file named by URLPTR's spec, e.g.
;   "N1:TNFS://TMA-2/OLD.TXT"
RM      LDY  #0
RM_LP   LDA  (URLPTR),Y
        STA  PAYLOAD+2,Y
        BEQ  RM_END
        INY
        BNE  RM_LP
RM_END  INY               ; include NUL
        STY  PAYLOAD      ; length low
        LDA  #0
        STA  PAYLOAD+1
        LDA  NETID
        STA  SPUNIT
        LDA  #'!'         ; NETCMD_DELETE
        JMP  SPCTRL
```
]
#byway[#cw("GETCWD") (#cw("STATUS $30"), the digit #cw("0")) returns the
current directory prefix in the payload — the read-side companion to
#cw("CHDIR").]

#sect("Reading JSON")

The Network device can parse a JSON document on the FujiNet and hand you
single fields, so a 1 MHz 6502 never has to. Open the resource, switch
the channel into *JSON mode*, parse, then query a path as many times as
you like; each query's result is fetched with #cw("STATUS") + #cw("READ")
exactly as a normal read.

#cmd("CHANNEL MODE", "CONTROL $FC")
Switches the channel between protocol mode (#cw("0"), the default) and
JSON mode (#cw("1")).
#ptable(
  ("Offset", "Bytes", "Value"),
  ("0–1", "2", "length = $0001"),
  ("2", "1", "0 = protocol, 1 = JSON"),
)

#cmd("JSON PARSE", "CONTROL $50  'P'")
Parses the document currently waiting on the channel. No arguments
(length #cw("$0000")). fujinet-lib pairs this with the mode switch above
as #cw("network_json_parse()").

#cmd("JSON QUERY", "CONTROL $51  'Q'")
Sets the JSONPath to read; the value is then retrieved with a normal
#cw("STATUS")/#cw("READ").
#ptable(
  ("Offset", "Bytes", "Value"),
  ("0–1", "2", "length = (query length) + 1"),
  ("2…", "N+1", "JSONPath string, e.g. \"/weather/temp\", NUL"),
)
#returns[After the query, #cw("STATUS") reports the value length; a
#cw("READ") of that many bytes returns the value. fujinet-lib:
#cw("network_json_query()").]
#listing("3-9", "Query one field after an open")[
```
; assumes the resource is open on the selected channel
JPARSE  LDA  #1
        STA  PAYLOAD       ; len = 1
        LDA  #0
        STA  PAYLOAD+1
        LDA  #1
        STA  PAYLOAD+2     ; mode = JSON
        LDA  NETID
        STA  SPUNIT
        LDA  #$FC          ; CHANNEL_MODE
        JSR  SPCTRL
        LDA  #0
        STA  PAYLOAD       ; len = 0
        STA  PAYLOAD+1
        LDA  #'P'          ; PARSE
        JSR  SPCTRL
        ; --- now ask for a field ---
        LDY  #0
JQ_LP   LDA  QUERY,Y
        STA  PAYLOAD+2,Y
        BEQ  JQ_END
        INY
        BNE  JQ_LP
JQ_END  INY               ; include NUL
        STY  PAYLOAD
        LDA  #0
        STA  PAYLOAD+1
        LDA  #'Q'          ; QUERY
        JSR  SPCTRL
        JSR  NETSTAT       ; BW = value length
        JSR  NETREAD       ; value now in PAYLOAD
        RTS
QUERY   .BYTE "/weather/0/main", 0
```
]

#sect("HTTP Verbs and Headers")

An #cw("HTTP")/#cw("HTTPS") channel is more than a byte pipe. The access
mode chosen at #cw("OPEN") selects the verb — read is GET, #cw("$0D") is
POST, #cw("$05") is DELETE — and one #cw("CONTROL") code,
#cw("$4D"), steers the channel between the request body and its headers.

#cmd("HTTP CHANNEL MODE", "CONTROL $4D  'M'")
Directs reads and writes on an HTTP channel to the body or the headers.
The mode travels in the *second* argument byte.
#ptable(
  ("Offset", "Bytes", "Value"),
  ("0–1", "2", "length = $0002"),
  ("2", "1", "0"),
  ("3", "1", "channel mode (see table)"),
)
#grid(columns: (1fr, 1fr), column-gutter: 14pt,
  ptable(
    ("Mode", "Meaning"),
    ("0", "body (default)"),
    ("1", "collect request headers"),
    ("2", "read response headers"),
  ),
  ptable(
    ("Mode", "Meaning"),
    ("3", "set request headers"),
    ("4", "POST: set data"),
    ("", ""),
  ),
)
#returns[#cw("$00") on success. fujinet-lib:
#cw("network_http_set_channel_mode()"); a header is then sent with an
ordinary #cw("WRITE") (#cw("network_http_add_header()")).]

#sect("TCP and UDP")

A raw #cw("TCP:") channel opened in read/write mode is a bidirectional
socket — the foundation of the netcat in Appendix C. Two extra
#cw("CONTROL") codes serve the listening and datagram cases.

#cmd("TCP ACCEPT / CLOSE CLIENT", "CONTROL $41 / $63")
On a #cw("TCP:") channel opened to listen, #cw("$41") (#cw("'A'"))
accepts a waiting client; #cw("$63") (#cw("'c'")) closes the current
client while keeping the listener alive. Both take an empty payload
(length #cw("$0000")).

#cmd("UDP SET DESTINATION", "CONTROL $44  'D'")
For a #cw("UDP:") channel, sets the host\:port that the next
#cw("WRITE") datagrams are addressed to.
#ptable(
  ("Offset", "Bytes", "Value"),
  ("0–1", "2", "length = (string length)"),
  ("2…", "N", "\"host:port\" string"),
)
#returns[Companion #cw("$72") (#cw("'r'"), #cw("GET REMOTE")) reports the
address of the last datagram's sender into the payload — handy for
replying.]

That is the whole Network device. Point #cw("SPUNIT") at #cw("NETID"),
select a channel, and these codes give you the Internet. The next chapter
turns to the other half of the FujiNet: the control device that manages
disks, hosts, and the hardware itself.

// ============================================================
// CHAPTER 4 — THE FUJI CONTROL DEVICE
// ============================================================
#chapter("Chapter 4", "The Fuji Control Device")

The device named #cw("THE_FUJI") — type #cw("$10") — is the one CONFIG
talks to. It owns the WiFi radio, the list of *hosts* (TNFS, SMB and the
like) and *disk image* mounts, the directory browser, persistent
app-key storage, and a drawer of utilities. Where the Network device
overloaded ASCII letters as verbs, the Fuji device uses the high-numbered
#cw("FUJICMD_") codes from #cw("fujiCommandID.h"). Set #cw("SPUNIT") to
#cw("FUJIID") (from #cw("FINDFUJI")); the rule from Chapter 2 holds —
#cw("STATUS") receives, #cw("CONTROL") sends, and the length header
leads every #cw("CONTROL") payload.

#mnote[Not every code in #cw("fujiCommandID.h") is serviced on the Apple
II. This chapter documents those the firmware's #cw("iwmFuji.cpp")
actually dispatches; Appendix B's table marks every code's status.]

#sect("The Slots Model")

CONFIG presents two arrays you will meet constantly. *Host slots* (8 of
them) name the places disks live — a TNFS server, an SMB share, the SD
card. *Device slots* are the drive bays: each remembers a host, an access
mode, and a filename, and maps to a SmartPort disk unit. Mounting is a
two-step you will recognise from CONFIG: mount a host, browse it, then
mount one of its images into a device slot.

#sect("WiFi and the Adapter")

#cmd("SCAN NETWORKS", "STATUS $FD")
Triggers a scan and returns the count of access points found, in the
first payload byte. fujinet-lib: #cw("fuji_scan_for_networks()").

#cmd("GET SCAN RESULT", "CONTROL $FC + STATUS $FC")
A paired command. #cw("CONTROL") with the index selects an access point;
the following #cw("STATUS") returns its name and signal.
#ptable(
  ("Phase", "Offset", "Bytes", "Meaning"),
  ("CONTROL", "0–1 / 2", "2 / 1", "length $0001; AP index n"),
  ("STATUS", "0–32 / 33", "33 / 1", "SSID (NUL-padded); RSSI (signed)"),
)
#returns[fujinet-lib: #cw("fuji_get_scan_result()").]

#cmd("GET / SET SSID", "STATUS $FE / CONTROL $FB")
#cw("STATUS $FE") returns the stored network config — a 33-byte SSID
followed by a 64-byte password. #cw("CONTROL $FB") sets the same
structure (length = its size), joining the network. fujinet-lib:
#cw("fuji_get_ssid()") / #cw("fuji_set_ssid()").

#cmd("GET WIFI STATUS", "STATUS $FA")
Returns one byte: #cw("3") = connected, #cw("6") = disconnected.
#cw("STATUS $EA") (#cw("GET WIFI ENABLED")) returns #cw("1") if the radio
is on. fujinet-lib: #cw("fuji_get_wifi_status()").

#cmd("GET ADAPTER CONFIG", "STATUS $E8")
Returns the live network configuration in one shot: the joined SSID,
hostname, and the four-byte IP, gateway, netmask, DNS, plus MAC and BSSID
and a firmware version string.
#ptable(
  ("Offset", "Bytes", "Field"),
  ("0", "33", "SSID"),
  ("33", "64", "hostname"),
  ("97", "4", "local IP"),
  ("101", "4", "gateway"),
  ("105", "4", "netmask"),
  ("109", "4", "DNS IP"),
  ("113", "6", "MAC address"),
  ("119", "6", "BSSID"),
  ("125", "15", "firmware version string"),
)
#returns[#cw("STATUS $C4") returns the same plus ready-made string forms
of every address. fujinet-lib: #cw("fuji_get_adapter_config()") /
#cw("_extended()").]
#listing("4-1", "Print the FujiNet's IP address")[
```
PRTIP   JSR  FINDFUJI      ; -> FUJIID
        LDA  FUJIID
        STA  SPUNIT
        LDA  #$E8          ; GET ADAPTERCONFIG
        JSR  SPSTAT
        BCS  IPERR
        LDX  #0            ; print local IP as N.N.N.N
DOTLP   LDA  PAYLOAD+97,X  ; localIP starts at offset 97
        JSR  PRBYTE        ; monitor: print A in decimal/hex
        CPX  #3
        BEQ  IPDONE
        LDA  #'.' + $80
        JSR  COUT
        INX
        BNE  DOTLP
IPDONE  RTS
```
]

#sect("Hosts and Device Slots")

#cmd("READ / WRITE HOST SLOTS", "STATUS $F4 / CONTROL $F3")
The eight host slots are an array of eight 32-byte names. #cw("STATUS
$F4") reads all 256 bytes; #cw("CONTROL $F3") writes them back (length =
256). fujinet-lib: #cw("fuji_get_host_slots()") /
#cw("fuji_put_host_slots()").

#cmd("READ / WRITE DEVICE SLOTS", "STATUS $F2 / CONTROL $F1")
Device slots are an array of 38-byte records:
#ptable(
  ("Offset", "Bytes", "Field"),
  ("0", "1", "host slot this disk lives on"),
  ("1", "1", "access mode (1 = read, 2 = read/write)"),
  ("2", "36", "filename"),
)
#returns[#cw("STATUS $F2") returns the whole array; #cw("CONTROL $F1")
writes it (length = 38 × count). Library calls: get and put device
slots.]

#cmd("MOUNT / UNMOUNT HOST", "CONTROL $F9 / $E6")
Brings a host slot online (connects the server) or takes it offline. The
payload is one byte: the host slot number.
#ptable(
  ("Offset", "Bytes", "Value"),
  ("0–1", "2", "length = $0001"),
  ("2", "1", "host slot number"),
)
#returns[fujinet-lib: #cw("fuji_mount_host_slot()") /
#cw("fuji_unmount_host_slot()").]

#cmd("MOUNT / UNMOUNT IMAGE", "CONTROL $F8 / $E9")
Mounts the disk image recorded in a *device* slot, making it a live
SmartPort disk. #cw("MOUNT") takes the slot and an access mode; #cw("UNMOUNT")
takes just the slot.
#ptable(
  ("Offset", "Bytes", "Value"),
  ("0–1", "2", "length ($0002 mount, $0001 unmount)"),
  ("2", "1", "device slot number"),
  ("3", "1", "access mode (mount only: 1=RO, 2=RW)"),
)
#returns[fujinet-lib: #cw("fuji_mount_disk_image()") /
#cw("fuji_unmount_disk_image()"). #cw("CONTROL $D7") (#cw("MOUNT ALL"),
empty payload) mounts every configured slot at once.]
#listing("4-2", "Mount host 0, then image in device slot 1")[
```
MOUNT   JSR  FINDFUJI
        LDA  FUJIID
        STA  SPUNIT
        LDA  #1
        STA  PAYLOAD       ; length = 1
        LDA  #0
        STA  PAYLOAD+1
        STA  PAYLOAD+2     ; host slot 0
        LDA  #$F9          ; MOUNT HOST
        JSR  SPCTRL
        BCS  MERR
        LDA  #2
        STA  PAYLOAD       ; length = 2
        LDA  #0
        STA  PAYLOAD+1
        LDA  #1
        STA  PAYLOAD+2     ; device slot 1
        LDA  #2
        STA  PAYLOAD+3     ; mode = read/write
        LDA  #$F8          ; MOUNT IMAGE
        JMP  SPCTRL
```
]

#cmd("SET / GET DEVICE FULLPATH", "CONTROL $E2 / STATUS $A0+ds")
#cw("CONTROL $E2") records a filename into a device slot without
mounting: payload is device slot, host slot, mode, then the filename and
a NUL. To read a slot's filename back, issue #cw("STATUS") with code
#cw("$A0 + ds") (so #cw("$A0")…#cw("$A9") for slots 0–9); the payload
returns the 256-byte path.
#ptable(
  ("Offset", "Bytes", "Value (SET)"),
  ("0–1", "2", "length = (name length) + 4"),
  ("2", "1", "device slot"),
  ("3", "1", "host slot"),
  ("4", "1", "access mode"),
  ("5…", "N+1", "filename, NUL-terminated"),
)
#returns[fujinet-lib: #cw("fuji_set_device_filename()") /
#cw("fuji_get_device_filename()").]

#cmd("NEW DISK", "CONTROL $E7")
Creates a fresh blank image on a host and records it in a device slot.
#ptable(
  ("Offset", "Bytes", "Value"),
  ("0–1", "2", "length = sizeof(NewDisk)"),
  ("2", "1", "host slot"),
  ("3", "1", "device slot"),
  ("4", "1", "create/media type"),
  ("5–8", "4", "block count (little-endian)"),
  ("9…", "256", "filename"),
)
#returns[fujinet-lib: #cw("fuji_create_new()").]

#sect("Browsing a Host")

To list files on a mounted host, open its directory, read entries one at
a time until the end marker, then close.

#cmd("OPEN DIRECTORY", "CONTROL $F7")
Opens a directory on a host slot. The path and an optional filename
filter are packed into one field, separated by a NUL.
#ptable(
  ("Offset", "Bytes", "Value"),
  ("0", "1", "length low = $00"),
  ("1", "1", "length high = $01  (a full 256-byte field)"),
  ("2", "1", "host slot"),
  ("3…", "255", "path, NUL, optional filter"),
)
#returns[fujinet-lib: #cw("fuji_open_directory()").]

#cmd("READ DIR ENTRY", "CONTROL $F6 + STATUS $F6")
A paired command. #cw("CONTROL") sets the maximum length to return and a
flags byte; the following #cw("STATUS") returns one entry. Set bit 7 of
the flags to append a details block after the name.
#ptable(
  ("Phase", "Offset", "Bytes", "Meaning"),
  ("CONTROL", "2 / 3", "1 / 1", "max length; flags ($80 = + details)"),
  ("STATUS", "0…", "maxlen", "filename; details if requested"),
)
The optional details block, appended after the filename, is:
#ptable(
  ("Offset", "Bytes", "Detail"),
  ("0–5", "6", "modified: year, month, day, hour, min, sec"),
  ("6–9", "4", "file size (little-endian)"),
  ("10", "1", "is-directory flag"),
  ("11", "1", "name-was-truncated flag"),
  ("12", "1", "media type"),
)
#important[A returned entry whose first byte is #cw("$7F") is the
*end-of-directory* marker — stop reading. On the Apple II the firmware
also prepends two spaces (#cw("$20")) to each real filename; skip them.]
#returns[fujinet-lib: #cw("fuji_read_directory()").]

#cmd("CLOSE DIRECTORY", "CONTROL $F5")
Closes the open directory. Empty payload (length #cw("$0000")).
#cw("STATUS $E5") / #cw("CONTROL $E4") get and set the directory read
position for paging. fujinet-lib: #cw("fuji_close_directory()").

#listing("4-3", "List a directory to the screen")[
```
; host slot 0 already mounted; FUJIID set
LISTDIR LDA  FUJIID
        STA  SPUNIT
        LDA  #0            ; length = $0100 (256-byte field)
        STA  PAYLOAD
        LDA  #1
        STA  PAYLOAD+1
        LDA  #0
        STA  PAYLOAD+2     ; host slot 0
        LDA  #'/'          ; path = "/"
        STA  PAYLOAD+3
        LDA  #0
        STA  PAYLOAD+4     ; NUL: no filter
        LDA  #$F7          ; OPEN DIRECTORY
        JSR  SPCTRL
LD_NEXT LDA  #2
        STA  PAYLOAD       ; length = 2
        LDA  #0
        STA  PAYLOAD+1
        LDA  #40
        STA  PAYLOAD+2     ; max 40 chars
        LDA  #0
        STA  PAYLOAD+3     ; name only, no details
        LDA  #$F6          ; READ DIR ENTRY (control)
        JSR  SPCTRL
        LDA  #$F6          ; READ DIR ENTRY (status)
        JSR  SPSTAT
        LDA  PAYLOAD
        CMP  #$7F          ; end-of-directory?
        BEQ  LD_END
        LDX  #2            ; skip the two pad spaces
PR_LP   LDA  PAYLOAD,X
        BEQ  PR_EOL
        ORA  #$80
        JSR  COUT
        INX
        BNE  PR_LP
PR_EOL  LDA  #$8D          ; carriage return
        JSR  COUT
        JMP  LD_NEXT
LD_END  LDA  #0
        STA  PAYLOAD
        STA  PAYLOAD+1     ; length = 0
        LDA  #$F5          ; CLOSE DIRECTORY
        JMP  SPCTRL
```
]

#sect("App Keys: Saving State")

An *app key* is a small block (up to 64 bytes) the FujiNet stores for
your program, indexed by a creator id, an app id, and a key id — handy
for high scores, settings, or a save game. You always #cw("OPEN") the key
first, declaring read or write, then #cw("READ") or #cw("WRITE") it.

#cmd("OPEN APPKEY", "CONTROL $DC")
#ptable(
  ("Offset", "Bytes", "Value"),
  ("0–1", "2", "length = $0006"),
  ("2–3", "2", "creator id (little-endian)"),
  ("4", "1", "app id"),
  ("5", "1", "key id"),
  ("6", "1", "mode: 0 = read, 1 = write"),
  ("7", "1", "reserved ($00)"),
)

#cmd("READ / WRITE APPKEY", "STATUS $DD / CONTROL $DE")
After an #cw("OPEN") in read mode, #cw("STATUS $DD") returns the key's
bytes (count in #cw("SPCNT")). After an #cw("OPEN") in write mode,
#cw("CONTROL $DE") stores them: payload is the byte count then the data.
#returns[fujinet-lib: #cw("fuji_read_appkey()") /
#cw("fuji_write_appkey()") (which wrap the open for you).]
#listing("4-4", "Save 16 bytes to app key 1")[
```
SAVEKEY LDA  FUJIID
        STA  SPUNIT
        LDA  #6
        STA  PAYLOAD       ; length = 6
        LDA  #0
        STA  PAYLOAD+1
        LDA  #<CREATOR
        STA  PAYLOAD+2
        LDA  #>CREATOR
        STA  PAYLOAD+3
        LDA  #APPID
        STA  PAYLOAD+4
        LDA  #1
        STA  PAYLOAD+5     ; key id 1
        LDA  #1
        STA  PAYLOAD+6     ; mode = write
        LDA  #0
        STA  PAYLOAD+7
        LDA  #$DC          ; OPEN APPKEY
        JSR  SPCTRL
        BCS  SK_ERR
        LDA  #16
        STA  PAYLOAD       ; length = 16
        LDA  #0
        STA  PAYLOAD+1
        LDX  #0            ; copy 16 bytes of state in
SK_CP   LDA  STATE,X
        STA  PAYLOAD+2,X
        INX
        CPX  #16
        BNE  SK_CP
        LDA  #$DE          ; WRITE APPKEY
        JMP  SPCTRL
CREATOR = $1234
APPID   = 1
```
]

#sect("Boot, Devices, and Housekeeping")

A handful of one-byte and empty-payload commands round out the device.

#ptable(
  ("Code", "Call", "Action", "Payload"),
  ("$D9", "CONTROL", "enable/disable CONFIG boot", "1 byte: toggle"),
  ("$D6", "CONTROL", "set boot mode (e.g. Lobby)", "1 byte: mode"),
  ("$D5", "CONTROL", "enable a device", "1 byte: device id"),
  ("$D4", "CONTROL", "disable a device", "1 byte: device id"),
  ("$D1", "STATUS", "device-enabled status", "returns 1 byte"),
  ("$D7", "CONTROL", "mount all slots", "empty"),
  ("$D8", "CONTROL", "copy file between hosts", "src,dst,spec"),
  ("$BB", "STATUS", "generate a GUID string", "returns 37 bytes"),
  ("$C1", "STATUS", "free heap (debug)", "returns 4 bytes"),
  ("$53", "STATUS", "Fuji status block", "returns 4 bytes"),
  ("$FF", "CONTROL", "reset the FujiNet", "empty"),
)
#returns[fujinet-lib names follow the obvious pattern —
#cw("fuji_set_boot_mode()"), #cw("fuji_enable_device()"),
#cw("fuji_generate_guid()"), #cw("fuji_reset()"), and so on.]

#sect("Hashing and QR Codes")

The firmware can compute MD5, SHA-1, SHA-256 and SHA-512 digests and
render QR codes — useful for content addressing or showing a link on
screen. These live in #cw("iwmFuji.cpp") and are driven raw; the Apple II
library wrappers are presently stubs, so issue the codes yourself.

#ptable(
  ("Code", "Call", "Step"),
  ("$C8", "CONTROL", "add input data to the hash buffer"),
  ("$C7", "CONTROL", "compute (algorithm in byte 0); clears buffer"),
  ("$C3", "CONTROL", "compute without clearing the buffer"),
  ("$C6", "STATUS", "length of the resulting digest"),
  ("$C5", "STATUS", "read the digest (set hex/binary via CONTROL $C5)"),
  ("$C2", "CONTROL", "clear the hash buffer"),
  ("$BC", "CONTROL", "add input to the QR encoder"),
  ("$BD", "CONTROL", "encode (version, ECC, shorten in bytes 0–2)"),
  ("$BE", "STATUS", "length of the encoded QR data"),
  ("$BF", "STATUS", "read the encoded QR modules"),
)
#listing("4-5", "MD5 of a buffer (raw)")[
```
; algorithm: 0=MD5 1=SHA1 2=SHA256 3=SHA512
HASHBUF LDA  FUJIID
        STA  SPUNIT
        ; --- feed the data ---
        LDA  #<DLEN
        STA  PAYLOAD       ; length = data length
        LDA  #>DLEN
        STA  PAYLOAD+1
        ; ...copy DLEN bytes of data to PAYLOAD+2...
        LDA  #$C8          ; HASH INPUT
        JSR  SPCTRL
        ; --- compute MD5 ---
        LDA  #1
        STA  PAYLOAD       ; length = 1
        LDA  #0
        STA  PAYLOAD+1
        STA  PAYLOAD+2     ; 0 = MD5
        LDA  #$C7          ; HASH COMPUTE
        JSR  SPCTRL
        ; --- read the 16-byte digest ---
        LDA  #$C5          ; HASH OUTPUT
        JSR  SPSTAT        ; digest now in PAYLOAD, SPCNT = 16
        RTS
```
]

That is the Fuji control device. Between it and the Network device you
can do anything CONFIG can, and a good deal it cannot. One small device
remains — the clock — and then we build the netcat.

// ============================================================
// CHAPTER 5 — THE CLOCK DEVICE
// ============================================================
#chapter("Chapter 5", "The Clock Device")

An Apple II has never known what time it is. The FujiNet does — it keeps
network time and a configured time zone — and exposes it as device type
#cw("$13"), #cw("FN_CLOCK"). Find it with #cw("FINDDEV") and the type
byte #cw("$13"); then a single #cw("STATUS") call returns the time in
whichever of six formats you ask for. The status *code* you send is an
ASCII letter naming the format.

#sect("Getting the Time")

#cmd("GET TIME", "STATUS  (format letter)")
The reply lands in #cw("PAYLOAD"); its length is in #cw("SPCNT"). Binary
formats are raw numbers; string formats are NUL-terminated ISO text. Send
the upper-case letter to use the FujiNet's own time zone.
#ptable(
  ("Code", "Char", "Format returned"),
  ("$54", "T", "simple binary: cent, yr, mon, day, hr, min, sec"),
  ("$50", "P", "ProDOS date/time (4 bytes)"),
  ("$41", "A", "APETIME binary (6 bytes)"),
  ("$49", "I", "ISO 8601 string, local zone"),
  ("$5A", "Z", "ISO 8601 string, UTC"),
  ("$53", "S", "Apple /// SOS format"),
)
#returns[fujinet-lib: #cw("clock_get_time()"), with format constants
#cw("SIMPLE_BINARY"), #cw("PRODOS_BINARY"), #cw("TZ_ISO_STRING"),
#cw("UTC_ISO_STRING"), and so on.]

The seven bytes of the simple binary format are the easiest to act on —
no parsing, just numbers. The century byte is #cw("20") for the
twenty-first; add the year byte for the full year.

#listing("5-1", "Read the time into seven bytes")[
```
NOW     .RES 7           ; cent, year, month, day, hour, min, sec
;
GETTIME LDA  #$13
        JSR  FINDDEV      ; locate FN_CLOCK
        BCS  NOCLOCK
        STA  SPUNIT
        LDA  #'T'         ; simple binary, FujiNet time zone
        JSR  SPSTAT
        BCS  NOCLOCK
        LDX  #0           ; copy the seven bytes out
GT_CP   LDA  PAYLOAD,X
        STA  NOW,X
        INX
        CPX  #7
        BNE  GT_CP
        RTS
```
]

#byway[Send the *lower-case* letter (#cw("'t'"), #cw("'i'"), …) and the
clock answers using an *alternate* time zone instead of the FujiNet's —
the one you last set with #cw("CONTROL $74"). This is how
#cw("clock_get_time_tz()") fetches another city's time without disturbing
the system zone.]

#sect("The Time Zone")

#cmd("GET TIME ZONE", "STATUS $47  'G'")
Returns the configured POSIX time-zone string (for example
#cw("CST6CDT,M3.2.0,M11.1.0")) into #cw("PAYLOAD"), NUL-terminated.
fujinet-lib: #cw("clock_get_tz()").

#cmd("SET TIME ZONE", "CONTROL $54 / $74")
Sets the time zone from a string. #cw("CONTROL $54") (#cw("'T'")) sets
the FujiNet's own zone and saves it; #cw("CONTROL $74") (#cw("'t'")) sets
the temporary alternate zone used by the lower-case time formats.
#ptable(
  ("Offset", "Bytes", "Value"),
  ("0–1", "2", "length = (string length) + 1"),
  ("2…", "N+1", "POSIX TZ string, NUL-terminated"),
)
#returns[fujinet-lib: #cw("clock_set_tz()").]

With the clock read, every device the Apple II programmer can reach
through the FujiNet has been covered. What remains is to put the Network
device through its paces — a real program, start to finish.

// ============================================================
// APPENDIX A — ERROR CODES
// ============================================================
#chapter("Appendix A", "Error Codes")

Two layers of error codes meet in FujiNet programming. The SmartPort
layer returns the code in #cw("A") (and the carry flag) from every call;
these are Apple's own, defined in #cw("iwm.h"). The network *device*
reports a second, finer code in the fourth byte of its #cw("STATUS")
reply — most importantly #cw("136"), end-of-file.

#sect("SmartPort Result Codes")

#ptable(
  ("Code", "Name", "Meaning"),
  ("$00", "NOERROR", "success"),
  ("$01", "BADCMD", "device does not support the command"),
  ("$06", "BUSERR", "communications error on the bus"),
  ("$21", "BADCTL", "invalid STATUS or CONTROL code"),
  ("$22", "BADCTLPARM", "invalid parameter in the payload"),
  ("$27", "IOERROR", "the device tried the operation and failed"),
  ("$28", "NODRIVE", "no device at that unit number"),
  ("$2B", "NOWRITE", "media is write-protected"),
  ("$2D", "BADBLOCK", "invalid block number"),
  ("$2E", "DISKSW", "media was swapped (extended calls)"),
  ("$2F", "OFFLINE", "device offline or no media present"),
  ("$30", "BADWIFI", "error joining the requested SSID"),
)

#sect("Network Device Status Codes")

Read from byte 3 of a Network #cw("STATUS") reply (Listing 3-4's
#cw("NERR")):

#ptable(
  ("Code", "Meaning"),
  ("1", "normal — connected, no error"),
  ("136", "end of file — the resource is fully read"),
)

#sect("Library Error Codes")

When you call #cw("fujinet-lib") instead of issuing raw calls, it folds
the SmartPort codes into a small device-agnostic set (#cw("fn_error()")):

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

Everything in this book, condensed. Codes are the bytes you place in the
parameter list — as a #cw("STATUS")/#cw("CONTROL") code, or as the
command number for #cw("READ")/#cw("WRITE").

#sect("Device Types and Calls")

#grid(columns: (1fr, 1fr), column-gutter: 14pt,
  ptable(
    ("Type", "Device"),
    ("$10", "THE_FUJI (control)"),
    ("$11", "NETWORK (N:)"),
    ("$12", "CPM"),
    ("$13", "FN_CLOCK"),
    ("$14", "printer"),
    ("$15", "modem"),
  ),
  ptable(
    ("Cmd", "SmartPort call"),
    ("$00", "STATUS"),
    ("$04", "CONTROL"),
    ("$06", "OPEN"),
    ("$07", "CLOSE"),
    ("$08", "READ"),
    ("$09", "WRITE"),
  ),
)

#sect("Network Device (type $11)")

#ptable(
  ("Code", "Call", "Operation"),
  ("$FA", "CONTROL", "set channel (select Nx unit)"),
  ("$4F 'O'", "CONTROL", "open connection (mode, trans, spec)"),
  ("$43 'C'", "CONTROL", "close connection"),
  ("$53 'S'", "STATUS", "channel status (bw, conn, err)"),
  ("— ", "READ", "read waiting bytes"),
  ("— ", "WRITE", "write bytes"),
  ("$FD / $FE", "CONTROL", "set username / password"),
  ("$FC", "CONTROL", "channel mode (0 protocol, 1 JSON)"),
  ("$50 'P'", "CONTROL", "JSON parse"),
  ("$51 'Q'", "CONTROL", "JSON query (then STATUS+READ)"),
  ("$2C ','", "CONTROL", "change directory"),
  ("$30 '0'", "STATUS", "get current directory"),
  ("$20", "CONTROL", "rename (spec is from,to)"),
  ("$21 '!'", "CONTROL", "delete file"),
  ("$23 '#'", "CONTROL", "lock file"),
  ("$24 '$'", "CONTROL", "unlock file"),
  ("$2A '*'", "CONTROL", "make directory"),
  ("$2B '+'", "CONTROL", "remove directory"),
  ("$4D 'M'", "CONTROL", "HTTP channel mode (body/headers)"),
  ("$41 'A'", "CONTROL", "TCP accept connection"),
  ("$63 'c'", "CONTROL", "TCP close client"),
  ("$44 'D'", "CONTROL", "UDP set destination"),
  ("$72 'r'", "CONTROL", "UDP get remote address"),
)

#sect("Fuji Control Device (type $10)")

The commands the Apple II firmware services, by phase. Codes not listed
here exist in #cw("fujiCommandID.h") but are not dispatched on the Apple
II.

#ptable(
  ("Code", "Call", "Operation"),
  ("$FF", "CONTROL", "reset FujiNet"),
  ("$FE / $FB", "STATUS / CTRL", "get / set SSID"),
  ("$FD", "STATUS", "scan networks (returns count)"),
  ("$FC", "CTRL+STAT", "get scan result n"),
  ("$FA", "STATUS", "get WiFi status"),
  ("$EA", "STATUS", "get WiFi enabled"),
  ("$F9 / $E6", "CONTROL", "mount / unmount host slot"),
  ("$F8 / $E9", "CONTROL", "mount / unmount disk image"),
  ("$D7", "CONTROL", "mount all"),
  ("$F4 / $F3", "STATUS / CTRL", "read / write host slots"),
  ("$F2 / $F1", "STATUS / CTRL", "read / write device slots"),
  ("$E2", "CONTROL", "set device filename"),
  ("$A0–$A9", "STATUS", "get device filename (slot 0–9)"),
  ("$E7", "CONTROL", "new (blank) disk"),
  ("$F7", "CONTROL", "open directory"),
  ("$F6", "CTRL+STAT", "read directory entry"),
  ("$F5", "CONTROL", "close directory"),
  ("$E5 / $E4", "STATUS / CTRL", "get / set directory position"),
  ("$E8 / $C4", "STATUS", "adapter config / extended"),
  ("$DC", "CONTROL", "open app key"),
  ("$DD / $DE", "STATUS / CTRL", "read / write app key"),
  ("$D9", "CONTROL", "enable CONFIG boot"),
  ("$D6", "CONTROL", "set boot mode"),
  ("$D5 / $D4", "CONTROL", "enable / disable device"),
  ("$D1", "STATUS", "device enable status"),
  ("$D8", "CONTROL", "copy file"),
  ("$BB", "STATUS", "generate GUID"),
  ("$C1", "STATUS", "free heap (debug)"),
  ("$53", "STATUS", "Fuji status block"),
  ("$C8 $C7 $C6 $C5 $C2", "CTRL/STAT", "hash: input, compute, len, out, clear"),
  ("$BC $BD $BE $BF", "CTRL/STAT", "QR: input, encode, length, output"),
)

#sect("Clock Device (type $13)")

#ptable(
  ("Code", "Call", "Operation"),
  ("$54 'T'", "STATUS", "time, simple binary (7 bytes)"),
  ("$50 'P'", "STATUS", "time, ProDOS format"),
  ("$41 'A'", "STATUS", "time, APETIME binary"),
  ("$49 'I'", "STATUS", "time, ISO string (local)"),
  ("$5A 'Z'", "STATUS", "time, ISO string (UTC)"),
  ("$53 'S'", "STATUS", "time, Apple /// SOS format"),
  ("$47 'G'", "STATUS", "get time-zone string"),
  ("$54 'T'", "CONTROL", "set system time zone"),
  ("$74 't'", "CONTROL", "set alternate time zone"),
)
#mnote[Send a time-format letter in lower case to read using the
alternate zone instead of the system zone.]

// ============================================================
// APPENDIX C — NETCAT
// ============================================================
#chapter("Appendix C", "netcat in 6502")

Here is the program promised on the title page: a #text(style:
"italic")[netcat]. It opens a raw TCP connection, then pumps bytes both
ways — whatever the far end sends is printed to the screen, and whatever
you type is sent to the far end — until the connection drops or you press
#box(text(font: f-head, size: 8pt)[ESC]). It is the whole book in one
listing: #cw("SPINIT") finds the bus, #cw("FINDNET") finds the device,
and the five Network routines from Chapter 3 do the work.

#sect("What It Needs")

The listing below is the *main program and data only*. Assemble it
together with the routines already built in this book — they are listed
once here so the program is complete:

#sq[#cw("SPINIT") (Listing 1-1) and the call primitives #cw("SPSTAT"),
#cw("SPCTRL"), #cw("SPREAD"), #cw("SPWRITE") with #cw("PAYLOAD"),
#cw("SPUNIT"), #cw("SPCNT") (Listing 1-3);]
#sq[#cw("FINDDEV") and #cw("FINDNET") (Listings 2-1, 2-2);]
#sq[#cw("NETCHAN"), #cw("NETOPEN")/#cw("COPYSPEC"), #cw("NETCLOSE"),
#cw("NETSTAT"), #cw("NETREAD"), #cw("NETWRITE") and their variables
#cw("BW"), #cw("CONN"), #cw("NERR"), #cw("MODE"), #cw("TRANS"),
#cw("URLPTR") (Listings 3-1 through 3-6).]

Change the address in #cw("HOST") to the server you want to reach, set
the assembler's origin, and run.

#sect("The Program")

#listing("C-1", "FujiNet netcat — main loop and data")[
```
; ============================================================
;  FUJINET NETCAT for the Apple II            (ca65 syntax)
;  socket <-> screen + keyboard, ESC to quit
; ============================================================
KBD     =   $C000        ; keyboard data + ready (bit 7)
STROBE  =   $C010        ; clear keyboard strobe
COUT    =   $FDED        ; monitor: print A (high bit set)
CROUT   =   $FD8E        ; monitor: print a carriage return
;
        .ORG $2000
;
NETCAT  JSR  SPINIT       ; 1. find the SmartPort bus
        BCS  NODEV
        JSR  FINDNET      ; 2. find the Network device -> NETID
        LDA  NETID
        BEQ  NODEV
        LDA  #1
        JSR  NETCHAN      ; 3. operate on channel N1:
;
        LDA  #<HOST       ; 4. open TCP, read/write, no translation
        STA  URLPTR
        LDA  #>HOST
        STA  URLPTR+1
        LDA  #$0C         ; mode = read/write
        STA  MODE
        LDA  #$00         ; trans = none (binary)
        STA  TRANS
        JSR  NETOPEN
        BCS  OPENERR
;
; ---- the pump: drain the socket, then check the keyboard ----
PUMP    JSR  NETSTAT      ; how much is waiting? still connected?
        LDA  CONN
        BEQ  CLOSED       ; far end hung up
        LDA  NERR
        CMP  #136         ; EOF from the resource
        BEQ  CLOSED
        LDA  BW
        ORA  BW+1
        BEQ  KEYS         ; nothing waiting -> service keyboard
;
        LDA  BW+1         ; clamp the request to 512 bytes
        BEQ  RDOK         ; high byte 0 -> 255 or fewer, fine
        LDA  #$00
        STA  BW
        LDA  #$02
        STA  BW+1         ; force 512 (firmware returns <= waiting)
RDOK    JSR  NETREAD      ; pull the bytes into PAYLOAD
        LDX  #$00
EMIT    LDA  PAYLOAD,X
        ORA  #$80         ; set high bit for the Apple's video
        JSR  COUT
        INX
        CPX  SPCNT        ; SPCNT = bytes actually read
        BNE  EMIT
;
; ---- one key per pass, so the screen stays responsive -------
KEYS    LDA  KBD
        BPL  PUMP         ; no key down -> keep pumping
        STA  STROBE       ; acknowledge the key
        AND  #$7F         ; strip the ready bit
        CMP  #$1B         ; ESC?
        BEQ  QUIT
        STA  PAYLOAD      ; send this one byte
        LDA  #$01
        LDX  #$00
        JSR  NETWRITE
        JMP  PUMP
;
CLOSED  JSR  CROUT
        LDX  #$00
CMSG    LDA  BYEMSG,X     ; "** CONNECTION CLOSED"
        BEQ  QUIT
        JSR  COUT
        INX
        BNE  CMSG
QUIT    JSR  NETCLOSE     ; tidy up and return to the monitor
        RTS
;
OPENERR LDX  #$00
OMSG    LDA  OPMSG,X
        BEQ  ODONE
        JSR  COUT
        INX
        BNE  OMSG
ODONE   RTS
NODEV   LDX  #$00
NMSG    LDA  NOMSG,X
        BEQ  NDONE
        JSR  COUT
        INX
        BNE  NMSG
NDONE   RTS
;
; ---- data ---------------------------------------------------
HOST    .BYTE "N1:TCP://192.168.1.5:9000/", $00
BYEMSG  .BYTE $8D,"** CONNECTION CLOSED",$8D,$00
OPMSG   .BYTE $8D,"** COULD NOT OPEN",$8D,$00
NOMSG   .BYTE $8D,"** NO FUJINET FOUND",$8D,$00
```
]

#sect("Trying It")

On the other end, anything that speaks TCP will do. The classic test is
the Unix #cw("netcat") itself, listening on the port you named:

#scr(
  "] BRUN NETCAT",
  "",
  "HELLO FROM THE APPLE //",
  "and hello back from your laptop",
  "the quick brown fox jumped over",
  "",
  "** CONNECTION CLOSED",
  "]",
)

Type, and your keystrokes cross the room — or the world — and the reply
paints onto a 1 MHz machine that predates the network it just joined.
That is the whole trick of the FujiNet, and now it is yours to program:
find the SmartPort, address the device, mind the length header, and the
rest is just 6502.
