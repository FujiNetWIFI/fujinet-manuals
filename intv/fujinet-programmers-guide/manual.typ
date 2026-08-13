// FujiNet Programmer's Guide for Intellivision — IntyBASIC edition
// Styled after the 1983 Mattel Intellivision Computer Module Owner's Guide
// (learn/Intellivision_Computer_Module_Owners_Guide_1983_Mattel_US.pdf).
//
// Build: typst compile --font-path fonts manual.typ

// ============================================================ palette/fonts
#let magenta   = rgb(210, 38, 84)     // interior frame, heads, code lines
#let magenta-d = rgb(166, 22, 60)
#let pink-pale = rgb(248, 224, 231)   // table shading
#let pink-scr  = rgb(243, 202, 212)   // TV screen mockups
#let cover-red = rgb(203, 21, 44)     // cover stripe red
#let silver    = rgb(219, 216, 211)   // cover ground
#let ink       = rgb(28, 26, 26)

#let f-body  = "ITC Benguiat Gothic Std"
#let f-serif = "C059"
#let f-grom  = "Intellivision GROM"
#let f-mono  = "DejaVu Sans Mono"

#let page-w = 8.67in
#let page-h = 5.71in

// ============================================================ states
#let ch-state  = state("chapter", none)   // (label:, no:, title:) once ch 1 starts

// ============================================================ helpers
#let co(n) = box(baseline: 28%, circle(
  radius: 4pt, fill: magenta,
  align(center + horizon, text(font: f-body, weight: 700, fill: white,
    size: 5.4pt, str(n)))))

#let kcap(l) = box(stroke: 1.1pt + magenta, fill: white,
  inset: (x: 3.6pt, y: 2.2pt), radius: 2.4pt, baseline: 22%,
  text(font: f-body, weight: 700, size: 7.4pt, fill: ink, l))

#let arrow-r = box(baseline: 22%, inset: (x: 2pt), stack(dir: ltr, spacing: 0pt,
  box(height: 7pt, align(horizon, line(length: 14pt, stroke: 1.6pt + ink))),
  polygon(fill: ink, (0pt, 0pt), (0pt, 7pt), (5.5pt, 3.5pt))))

#let arrow-lr = box(baseline: 22%, inset: (x: 2pt), stack(dir: ltr, spacing: 0pt,
  polygon(fill: ink, (5.5pt, 0pt), (5.5pt, 7pt), (0pt, 3.5pt)),
  box(height: 7pt, align(horizon, line(length: 12pt, stroke: 1.6pt + ink))),
  polygon(fill: ink, (0pt, 0pt), (0pt, 7pt), (5.5pt, 3.5pt))))

// hexadecimal in prose
#let hx(s) = text(font: f-mono, size: 0.92em, s)

// inline code
#let cd(s) = text(font: f-mono, size: 0.9em, s)

// period-style program statement + serif-italic explanation
#let stmt(code, expl) = block(breakable: false, above: 9pt, below: 9pt, {
  set par(justify: false)
  show raw: set text(font: f-body, weight: 700, fill: magenta, size: 9.2pt)
  raw(code, block: true)
  v(2.5pt)
  pad(left: 15pt, text(font: f-serif, style: "italic", size: 8.7pt, fill: ink, expl))
})

// TV screen mockup in the GROM font
#let tv(txt, size: 7.4pt, title: none) = align(center, block(
  fill: pink-scr, radius: 6pt, inset: (x: 13pt, y: 10pt),
  stroke: 1.2pt + magenta, breakable: false, {
    set align(left)
    show raw: set text(font: f-grom, size: size, fill: rgb(46, 22, 30))
    set par(leading: 0.32em, justify: false)
    raw(txt, block: true)
  }))

// inline code panel with LISTING-style caption
#let lst-counter = counter("inline-listing")
#let codepanel(title, body-txt, size: 6.6pt) = block(breakable: true,
  above: 11pt, below: 11pt, {
  block(breakable: false, below: 5pt, {
    line(length: 100%, stroke: 2.4pt + magenta)
    v(2.5pt)
    text(font: f-body, weight: 700, fill: magenta, size: 8pt,
      tracking: 0.06em, upper(title))
  })
  show raw: set text(font: f-mono, size: size, fill: ink)
  set par(justify: false, leading: 0.44em, hanging-indent: 12pt)
  raw(body-txt, block: true)
  v(2pt)
  line(length: 100%, stroke: 0.9pt + magenta)
})

// reference entry for one bus command
#let cmd(name, dev: "", code: "", params: (), payload: none, reply: none, body) = {
  block(breakable: true, above: 13pt, below: 9pt, {
    block(breakable: false, {
      box(fill: magenta, radius: (top-left: 3.5pt, bottom-right: 3.5pt),
        inset: (x: 8pt, y: 4pt),
        text(font: f-body, weight: 700, fill: white, size: 9.6pt,
          tracking: 0.05em, upper(name)))
      h(1fr)
      box(fill: ink, radius: 2.6pt, inset: (x: 6pt, y: 3.6pt),
        text(font: f-mono, fill: white, size: 7pt, "DEV " + dev))
      h(3pt)
      box(fill: ink, radius: 2.6pt, inset: (x: 6pt, y: 3.6pt),
        text(font: f-mono, fill: white, size: 7pt, "CMD " + code))
    })
    v(4pt)
    let rows = ()
    for p in params {
      rows.push(text(font: f-mono, size: 7.4pt, p.at(0)))
      rows.push(text(font: f-mono, size: 7.4pt, p.at(1)))
      rows.push(text(size: 8.2pt, p.at(2)))
    }
    if params.len() > 0 {
      table(
        columns: (34pt, 30pt, 1fr),
        stroke: 0.5pt + magenta.lighten(35%),
        inset: (x: 5pt, y: 3.2pt),
        fill: (x, y) => if y == 0 { pink-pale } else { white },
        table.header(
          text(font: f-body, weight: 700, size: 7pt, fill: magenta-d, "PARAM"),
          text(font: f-body, weight: 700, size: 7pt, fill: magenta-d, "SIZE"),
          text(font: f-body, weight: 700, size: 7pt, fill: magenta-d, "VALUE"),
        ),
        ..rows)
      v(2pt)
    }
    if payload != none {
      block(text(size: 8.2pt, [#text(font: f-body, weight: 700, fill: magenta-d,
        size: 7.4pt, "PAYLOAD  ") #payload]))
    }
    if reply != none {
      block(text(size: 8.2pt, [#text(font: f-body, weight: 700, fill: magenta-d,
        size: 7.4pt, "REPLY  ") #reply]))
    }
    if payload != none or reply != none { v(2pt) }
    text(size: 8.6pt, body)
  })
}

// generic wire-format table
#let wire(headers, widths: none, ..rows) = {
  let n = headers.len()
  let cells = ()
  for h in headers {
    cells.push(text(font: f-body, weight: 700, size: 7pt, fill: magenta-d, upper(h)))
  }
  table(
    columns: if widths != none { widths }
             else if n == 4 { (50pt, 62pt, 52pt, 1fr) }
             else if n == 3 { (66pt, 108pt, 1fr) }
             else { (60pt, 1fr) },
    stroke: 0.5pt + magenta.lighten(35%),
    inset: (x: 5pt, y: 3.2pt),
    fill: (x, y) => if y == 0 { pink-pale } else { white },
    table.header(..cells),
    ..rows.pos().flatten().map(c => if type(c) == str {
      text(size: 8pt, c) } else { c }))
}
#let mono7(s) = text(font: f-mono, size: 7.4pt, s)

// note in the period voice
#let note(body) = block(breakable: false, above: 9pt, below: 9pt,
  inset: (left: 10pt), stroke: (left: 2.6pt + magenta),
  text(size: 8.6pt, [#text(font: f-body, weight: 700, fill: magenta-d, "NOTE:  ")#body]))

#let warn(body) = block(breakable: false, above: 9pt, below: 9pt,
  inset: 8pt, fill: pink-pale, radius: 4pt,
  text(size: 8.6pt, [#text(font: f-body, weight: 700, fill: magenta-d, "WATCH OUT:  ")#body]))

// listing appendix renderer with callouts
#let listing-counter = counter("listing")
#let code-listing(title, path, callouts: (:), size: 5.15pt) = {
  listing-counter.step()
  block(breakable: false, above: 14pt, below: 6pt, {
    context {
      box(fill: ink, radius: 3pt, inset: (x: 7pt, y: 4pt),
        text(font: f-body, weight: 700, fill: white, size: 8.6pt,
          "LISTING " + str(listing-counter.get().first())))
    }
    h(7pt)
    text(font: f-body, weight: 700, fill: magenta, size: 9.4pt, title)
  })
  {
    show raw: set text(font: f-mono, size: size, fill: ink)
    set par(justify: false, leading: 0.4em, hanging-indent: 15pt)
    show raw.line: it => {
      box(width: 11pt, align(right,
        text(size: 3.9pt, fill: luma(145), str(it.number))))
      h(3.5pt)
      it.body
      if str(it.number) in callouts {
        h(2.5pt); co(callouts.at(str(it.number)))
      }
    }
    // A comma gains a zero-width break opportunity so the games' long
    // space-free DATA lines can wrap inside a column instead of escaping it.
    columns(2, gutter: 13pt,
      raw(read(path).replace(",", ",\u{200b}"), block: true))
  }
}

// ============================================================ page frame
#let frame-bg = context {
  let phys = here().page()
  // which chapter owns this page: the last level-1 heading at or before it
  let label = none
  for h in query(heading.where(level: 1)) {
    if h.location().page() <= phys { label = h.supplement }
  }
  // ground
  place(rect(width: 100%, height: 100%, fill: white))
  // pinstripes, top and bottom
  for (dy, th) in ((5.2pt, 2.8pt), (10.4pt, 1.7pt), (14.4pt, 1pt)) {
    place(top, dy: dy, line(length: 100%, stroke: th + magenta))
    place(bottom, dy: -dy, line(length: 100%, stroke: th + magenta))
  }
  // magenta frame
  place(top + left, dx: 13pt, dy: 20pt,
    rect(width: page-w - 26pt, height: page-h - 40pt, radius: 12pt, fill: magenta))
  // white content panel
  place(top + left, dx: 21pt, dy: 28pt,
    rect(width: page-w - 42pt, height: page-h - 56pt, radius: 8pt, fill: white))
  if label != none {
    let pg = counter(page).at(here()).first()
    let pill = box(fill: ink, radius: 3.4pt, inset: (x: 8pt, y: 3.8pt),
      text(font: f-body, weight: 700, fill: white, size: 6.8pt,
        tracking: 0.09em, label))
    if calc.odd(pg) {
      place(top + right, dx: -30pt, dy: 24.2pt, pill)
    } else {
      place(top + left, dx: 30pt, dy: 24.2pt, pill)
    }
    // folio, bottom outer corner
    let folio = text(font: f-body, weight: 700, size: 12.5pt, fill: ink, str(pg))
    if calc.odd(pg) {
      place(bottom + right, dx: -32pt, dy: -30pt, folio)
    } else {
      place(bottom + left, dx: 32pt, dy: -30pt, folio)
    }
  }
}

// ============================================================ chapter/section
#let chapter(label, title, blurb) = {
  pagebreak(weak: true)
  ch-state.update((label: upper(label), title: title))
  heading(level: 1, supplement: [#upper(label)], title)
  if blurb != none {
    v(2pt)
    text(font: f-serif, style: "italic", size: 9.2pt, blurb)
    v(6pt)
  }
}

#show heading.where(level: 1): it => {
  block(above: 4pt, below: 10pt, {
    context {
      let ch = ch-state.get()
      if ch != none {
        text(font: f-body, weight: 700, size: 8.4pt, fill: magenta-d,
          tracking: 0.14em, ch.label)
        v(-2pt)
      }
    }
    block(fill: magenta, radius: (top-left: 5pt, bottom-right: 5pt),
      inset: (x: 12pt, y: 6.5pt), width: 100%,
      text(font: f-body, weight: 700, fill: white, size: 15pt,
        tracking: 0.04em, upper(it.body)))
  })
}

#let sect(t) = heading(level: 2, t)
#show heading.where(level: 2): it => block(above: 12pt, below: 7pt,
  box(fill: magenta, radius: (top-left: 3.5pt, bottom-right: 3.5pt),
    inset: (x: 9pt, y: 4.4pt),
    text(font: f-body, weight: 700, fill: white, size: 10pt,
      tracking: 0.05em, upper(it.body))))

#let ssect(t) = heading(level: 3, t)
#show heading.where(level: 3): it => block(above: 10pt, below: 5pt,
  text(font: f-body, weight: 700, fill: magenta-d, size: 9.6pt,
    tracking: 0.05em, upper(it.body)))

// ============================================================ document setup
#set text(font: f-body, weight: 400, size: 9.2pt, fill: ink)
#set par(justify: false, leading: 0.52em, spacing: 0.9em)
#set page(width: page-w, height: page-h, margin: (x: 40pt, top: 46pt, bottom: 48pt),
  background: frame-bg)
#set list(marker: box(baseline: -1.5pt, rect(width: 4.6pt, height: 4.6pt, fill: magenta)),
  indent: 6pt, body-indent: 6pt)
#show "→": set text(font: f-mono)  // Benguiat has no arrow; keep Libertinus out
// NB: avoid writing digit-then-apostrophe ("the RP2040's") in prose --
// smartquote renders it as a prime, which Benguiat lacks (Libertinus fallback).
#set enum(indent: 6pt, body-indent: 6pt)
#set table(align: left + top)
#show emph: set text(font: f-serif, style: "italic")

#set document(title: "FujiNet Programmer's Guide for Intellivision (IntyBASIC)",
  author: "Thomas Cherryhomes")

// ============================================================ COVER
#page(margin: 0pt, background: none, {
  place(rect(width: 100%, height: 100%, fill: silver))
  // stripe bands, top and bottom, like the 1983 cover
  let stripes(at-top) = {
    let ys = ((6pt, 5pt), (15pt, 3.2pt), (22pt, 2pt), (27.5pt, 1.2pt))
    for (dy, th) in ys {
      if at-top {
        place(top, dy: dy, line(length: 100%, stroke: th + cover-red))
      } else {
        place(bottom, dy: -dy, line(length: 100%, stroke: th + cover-red))
      }
    }
  }
  stripes(true)
  stripes(false)
  // wordmark bar
  place(top + right, dx: -46pt, dy: 64pt,
    box(fill: ink, inset: (x: 16pt, y: 7pt), radius: 2pt, {
      text(font: f-body, weight: 700, fill: white, size: 16pt,
        tracking: 0.06em, "FUJINET")
      h(8pt)
      text(font: f-body, weight: 400, fill: white, size: 7pt,
        tracking: 0.14em, "FOR THE INTELLIVISION")
    }))
  // big skewed banner
  place(top + left, dy: 118pt, {
    let banner = box(fill: ink, inset: (x: 54pt, y: 13pt),
      text(font: f-body, weight: 700, fill: white, size: 25pt,
        tracking: 0.03em, [#box(fill: cover-red, inset: (x: 10pt, y: 4pt),
          radius: 2pt, "PROGRAMMER'S GUIDE")]))
    rotate(-2.2deg, banner)
  })
  place(top + left, dx: 58pt, dy: 196pt,
    text(font: f-body, weight: 500, size: 12pt, fill: ink,
      "IntyBASIC Edition"))
  // credits
  place(bottom + center, dy: -44pt, align(center,
    text(font: f-body, size: 6.6pt, fill: ink, [
      Covers the cartridge mailbox, the Network and Fuji devices, AppKeys,
      and three complete networked games with their servers.\
      FujiNet is a community project.  Intellivision is a registered trademark
      of its respective owner; this guide is not affiliated with or endorsed
      by Mattel.  Illustration style after the 1983 Computer Module Owner's Guide.
    ])))
})

// ============================================================ TITLE PAGE
#page(background: frame-bg, {
  v(20pt)
  align(center, {
    text(font: f-body, weight: 700, size: 19pt, fill: magenta,
      "FUJINET PROGRAMMER'S GUIDE")
    v(-4pt)
    text(font: f-body, weight: 500, size: 11pt, "for the Mattel Intellivision — IntyBASIC Edition")
    v(10pt)
    line(length: 55%, stroke: 1.2pt + magenta)
    v(10pt)
    text(size: 8.6pt, [
      Every command, register cell, byte offset and wire format in this guide
      was verified against the sources it documents: the cartridge firmware in
      #cd("fujinet-firmware/pico/intellivision/"), the ESP32-S3 command handlers in
      #cd("lib/device/rs232/") and #cd("lib/bus/rs232/"), the CONFIG client in
      #cd("fujinet-config/intv/"), the three game clients, and the game servers in
      #cd("fujinet-game-system/").
    ])
    v(8pt)
    text(size: 8.6pt, [
      The example programs #cd("hello.bas") and #cd("netcat.bas") compile with
      IntyBASIC v1.4.2 and assemble with as1600 without errors.
    ])
    v(14pt)
    text(font: f-serif, style: "italic", size: 9pt,
      "The network is as easy as PEEK and POKE.")
  })
})

// ============================================================ TABLE OF CONTENTS
#page(background: frame-bg, {
  align(center, box(fill: ink, radius: (top-left: 4pt, bottom-right: 4pt),
    inset: (x: 22pt, y: 6pt),
    text(font: f-body, weight: 700, fill: white, size: 12pt,
      tracking: 0.08em, "TABLE OF CONTENTS")))
  v(10pt)
  context {
    let hs = query(heading.where(level: 1))
    let entries = ()
    for h in hs {
      let pg = counter(page).at(h.location()).first()
      entries.push((h.supplement, h.body, pg))
    }
    let render(e) = block(above: 5.5pt, below: 0pt, {
      box(width: 74pt, box(fill: ink, radius: 2.6pt, inset: (x: 5pt, y: 2.6pt),
        text(font: f-body, weight: 700, fill: white, size: 6.4pt, e.at(0))))
      text(font: f-body, weight: 500, size: 8.6pt, e.at(1))
      box(width: 1fr, repeat(text(fill: magenta, size: 7pt, " .")))
      text(font: f-body, weight: 700, size: 8.6pt, fill: magenta-d, str(e.at(2)))
    })
    columns(2, gutter: 22pt, {
      for e in entries { render(e) }
    })
  }
  counter(page).update(0)
})

// ############################################################################
// CHAPTER 1 — INTRODUCTION
// ############################################################################
#chapter("Chapter 1", "Introduction", [
  What a FujiNet is, what is inside the cartridge, and what your IntyBASIC
  program can do with it.
])

FujiNet brings the Internet to the Intellivision the same way it came to the
Atari, the ADAM, the Apple II and a dozen other classic machines: as a
peripheral that does the hard part — WiFi, TCP/IP, TLS, HTTP, JSON — on a
modern processor, and hands your 8-bit (well, 16-bit!) program a simple,
byte-oriented command interface.

On most FujiNet platforms that interface is the machine's own peripheral
bus. The Intellivision has no such bus for cartridges to speak on, so the
Intellivision FujiNet takes a different road: *the cartridge itself is the
peripheral.* Inside the cartridge are two computers:

#align(center, block(above: 8pt, below: 8pt, {
  set text(size: 7.2pt)
  let bx(t, sub) = box(stroke: 1.4pt + ink, radius: 5pt, inset: (x: 8pt, y: 5.5pt),
    align(center, [#text(font: f-body, weight: 700, size: 8pt, t)\ #text(size: 6.4pt, sub)]))
  stack(dir: ltr, spacing: 4pt,
    bx("INTELLIVISION", "CP-1610, IntyBASIC"),
    align(horizon, stack(spacing: 2pt, arrow-lr, text(size: 5.6pt, "PEEK/POKE"))),
    bx("RP2040 / RP2350", [cartridge, mailbox at #hx("$9C00")]),
    align(horizon, stack(spacing: 2pt, arrow-lr, text(size: 5.6pt, "USB CDC"))),
    bx("ESP32-S3", "fujinet-firmware, WiFi"),
    align(horizon, arrow-lr),
    bx("INTERNET", "your game server"))
}))

The RP2040 (or RP2350) runs the cartridge: it serves the ROM your program
executes from, and it maps a small window of cartridge RAM at addresses
#hx("$9C00")–#hx("$9F3F") that both sides can read and write. That window is
the *mailbox*. Your program fills in a request — a device number, a command
number, parameters, maybe a payload — and rings a bell. The RP2040 notices,
re-encodes the request as a FujiBus packet, and sends it over an internal
USB serial link to the ESP32-S3, which is running the same fujinet-firmware
that powers every other FujiNet. The reply comes back the same way and
lands in the mailbox, where your program PEEKs it out.

The beautiful consequence: *everything is PEEK and POKE.* No handlers, no
interrupts, no bus timing. If you can poke a byte and wait for another byte
to change, you can talk to the Internet.

#sect("What you can do")

- Open network connections by name — #cd("N:HTTPS://server/path"),
  #cd("N:TCP://host:port/"), TELNET, UDP, TNFS and more — then read, write
  and poll them (Chapter 4).
- Ask the Fuji control device to scan WiFi, manage host and device slots,
  browse server directories, mount disk images — and on the Intellivision,
  *boot another ROM over the network* (Chapter 5).
- Store small records — a player name, a saved game, a server URL — on the
  FujiNet itself with AppKeys, so they survive power-off (Chapter 5).
- Read the real-world clock in seven formats (Chapter 6).
- Encode and decode Base64, compute MD5/SHA hashes, even build QR codes,
  using the FujiNet as a coprocessor (Chapter 5).

#sect("How this guide is arranged")

Chapters 2 and 3 teach the mailbox itself — the memory map, the handshake,
and a first working program. Chapters 4 through 6 are the command
reference, one device at a time. Chapter 7 documents #cd("fujinet.bas"),
the drop-in IntyBASIC library used by every program in this guide.
Chapters 8 through 10 dissect three complete, playable network games — *5
Card Stud*, *Battleship* and *Fujitzee* — client and server both, down to
the byte. Chapter 11 covers the Lobby that ties them together. The
appendices hold the error tables, a quick reference, the full program
listings (with numbered call-outs #co(1) referenced from the chapters), and
a network terminal you can type in.

#note[Numbers written like #hx("$9C00") are hexadecimal; plain numbers are
decimal. Mailbox cells are named #cd("FN_") the way #cd("fujinet.bas")
names them. Controller keys look like #kcap("ENTER").]

// ############################################################################
// CHAPTER 2 — THE CARTRIDGE MAILBOX
// ############################################################################
#chapter("Chapter 2", "The Cartridge Mailbox", [
  One page of shared RAM is the whole hardware interface. Learn it and you
  know everything the cartridge can do.
])

The mailbox is a window of cartridge RAM the RP2040 maps into the
Intellivision's address space at #hx("$9C00")–#hx("$9F3F") — 832 locations.
Each location holds one byte in the low 8 bits of a 16-bit word (writes
from the Intellivision side are hardware-truncated to 8 bits), so always
mask what you read: #cd("PEEK(addr) AND 255").

It sits at the *top* of the #hx("$8000")–#hx("$9FFF") region deliberately:
on a JLP-enabled cartridge that whole region is JLP RAM, and parking the
mailbox at the top leaves #hx("$8000")–#hx("$9BFF") — 7168 words, 87% of
the window — free for JLP while the mailbox keeps its 832.

#sect("The memory map")

#wire(("address", "name", "who writes", "meaning"),
  (mono7("$9C00"), mono7("MAGIC0"),   "RP2040", [ASCII #cd("F") (70) — mailbox present]),
  (mono7("$9C01"), mono7("MAGIC1"),   "RP2040", [ASCII #cd("N") (78)]),
  (mono7("$9C02"), mono7("PROTO_VER"),"RP2040", "protocol version, currently 1"),
  (mono7("$9C03"), mono7("SEQ"),      "Inty",   "bump to start a transaction (wraps, skip 0)"),
  (mono7("$9C04"), mono7("ACKSEQ"),   "RP2040", "set equal to SEQ when the reply is ready"),
  (mono7("$9C05"), mono7("DEVICE"),   "Inty",   [device id (#hx("$70") Fuji, #hx("$71") N1: …)]),
  (mono7("$9C06"), mono7("CMD"),      "Inty",   "command id"),
  (mono7("$9C07"), mono7("NPARAM"),   "Inty",   "parameter count, 0–8"),
  (mono7("$9C08/09"), mono7("TXLEN"), "Inty",   "payload length, little-endian"),
  (mono7("$9C0A"), mono7("STATUS"),   "RP2040", "diagnostic only: 0 idle, 1 busy, 2 ok, 3 err"),
  (mono7("$9C0B"), mono7("ERR"),      "RP2040", "link result of last transaction (Appendix A)"),
  (mono7("$9C0C/0D"), mono7("RXLEN"), "RP2040", "reply payload length, little-endian"),
  (mono7("$9C0E"), mono7("REPLY_CMD"),"RP2040", [#hx("$06") ACK or #hx("$15") NAK]),
  (mono7("$9C0F"), mono7("LINK"),     "RP2040", "1 if the ESP32-S3 is up on the USB link"),
  (mono7("$9C10-17"), mono7("PARAM_SIZE"), "Inty", "size of each parameter: 1, 2 or 4 bytes"),
  (mono7("$9C18"), mono7("BOOT_STATE"), "RP2040", "network-boot progress (see below)"),
  (mono7("$9C19"), mono7("BOOT_PCT"),   "RP2040", "network-boot progress, 0–100"),
  (mono7("$9C1A"), mono7("BOOT_ERR"),   "RP2040", "reason, when BOOT_STATE = failed"),
  (mono7("$9C1B"), mono7("DOORBELL"),   "Inty",   [write #hx("$B5") → RP2040 reboots to BOOTSEL]),
  (mono7("$9C20-3F"), mono7("PARAM_VAL"), "Inty", "8 slots × 4 bytes, little-endian"),
  (mono7("$9C40-"), mono7("TX"),      "Inty",   "request payload, up to 256 bytes"),
  (mono7("$9D40-"), mono7("RX"),      "RP2040", "reply payload, up to 512 bytes"),
)

#sect("The handshake")

A transaction is four steps, and the order of the last one is the whole
protocol:

+ Fill in #cd("DEVICE"), #cd("CMD"), #cd("NPARAM"), the parameter table,
  #cd("TXLEN") and the TX payload — everything *except* #cd("SEQ").
+ Read #cd("ACKSEQ"), add 1 (wrap past 255, and skip 0), and write that to
  #cd("SEQ"). #emph[Last.] The RP2040 polls for
  #cd("SEQ") ≠ #cd("ACKSEQ"); writing SEQ is what submits the request.
+ Wait for #cd("ACKSEQ") to become equal to the SEQ you wrote. Give up
  after a generous timeout — the library allows 900 frames (15 seconds).
+ Check #cd("REPLY_CMD"): #hx("$06") is ACK — the reply payload, if any, is
  at #cd("RX") with its length in #cd("RXLEN"). Anything else, look at
  #cd("ERR") for the link-level reason (Appendix A).

#warn[Always derive the new SEQ from the #cd("ACKSEQ") the RP2040 itself publishes, never
from a variable of your own. Pressing Reset restarts your program and
zeroes your variables — but not the RP2040. A locally-counted SEQ would
recompute the same value it already used, the RP2040 would see nothing
new, and your first transaction after every reset would hang. This is
call-out #co(2) in Listing 1.]

The interlock is a *sequence number*, not a busy flag: re-poking the same
SEQ while a transaction is in flight is a no-op, so a nervous retry can
never make the RP2040 run a command twice. #cd("STATUS") at #hx("$9C0A")
is a debugging aid only — poll #cd("ACKSEQ"), not STATUS.

#sect("Parameters and payloads")

Commands take up to eight small numeric parameters — the things other
FujiNet platforms pass in "aux" bytes. Parameter #emph[i] occupies one word
at #cd("PARAM_SIZE + i") giving its size (1, 2 or 4 bytes) and up to four
words at #cd("PARAM_VAL + i×4") holding its value, little-endian, one byte
per word. Bulk data — a URL, a filename, a WiFi password — goes in the TX
window instead, as consecutive bytes, with the count in #cd("TXLEN").

Replies land in the RX window, length in #cd("RXLEN"), and *stay there
until the next transaction overwrites them*. The IntyBASIC discipline that
follows from this is the most important habit in this guide: #emph[read
replies in place.] IntyBASIC gives you 228 eight-bit variables; a /state
reply from a game server is 400+ bytes. Never copy a reply into variables
— PEEK what you need straight out of #cd("FN_RX"), and copy only the few
bytes that must survive the next transaction into cartridge scratch RAM
(#hx("$9000")–#hx("$9BFF") is free on a FujiNet cartridge when JLP is off).

#sect("Timeouts and the link byte")

The RP2040 gives an ordinary command 5 seconds on the USB link, and
#cd("MOUNT_IMAGE") 60 (a ROM can take a while to fetch). It also waits up
to 3 seconds for the ESP32 to enumerate before the very first command —
the Intellivision boots much faster than the ESP32 does. #cd("LINK") at
#hx("$9C0F") shows the live state of the USB link; a program can show
"waiting for FujiNet" instead of a mysterious timeout.

#sect("Booting a ROM through the mailbox")

#cd("MOUNT_IMAGE") on the Fuji device does something on this platform it
does nowhere else: the ESP32 pushes the selected ROM — plus its
#cd(".cfg") sibling, if one exists — back over the same USB link, the
RP2040 decodes it straight into cartridge ROM space, remaps, and resets
your console into the new program. While that happens the ordinary
handshake is still outstanding, so progress is published out-of-band in
three cells your wait loop can PEEK: #cd("BOOT_STATE") (0 idle, 1 opening,
2 transferring, 3 mapping, #hx("$80") failed), #cd("BOOT_PCT") (0–100),
and #cd("BOOT_ERR") (Appendix A). Flat #cd(".bin"), self-describing
Intellicart #cd(".rom"), and #cd(".bin")+#cd(".cfg") (with JLP variables)
all load; a mapping that would collide with the mailbox itself is refused.

#sect("Declaring the window in IntyBASIC")

#stmt("    ASM MEMATTR $8000, $9BFF, \"+RWN\"",
  [Tells the assembler that the cartridge RAM below the mailbox is
  readable and writable, so POKE reaches your scratch buffers.])

Declare #hx("$8000")–#hx("$9BFF") — and stop there. On real hardware the
RP2040 maps the whole window regardless of what your #cd(".cfg") says, but
jzIntv's #cd("--fujinet") emulation registers its own handler for
#hx("$9C00")–#hx("$9FFF"), and a cartridge that claims those addresses as
plain RAM *shadows the emulated FujiNet* — the mailbox never comes up
under emulation even though the same ROM works on the real cartridge.
Call-out #co(8) in Listing 1.

// ############################################################################
// CHAPTER 3 — YOUR FIRST TRANSACTION
// ############################################################################
#chapter("Chapter 3", "Your First Transaction", [
  A complete program in under fifty lines, and the IntyBASIC survival rules
  that keep the rest of them working.
])

Here is the whole idea of the library in three procedures. First, wait for
the mailbox to introduce itself:

#stmt("GOSUB fn_wait_mailbox",
  [Polls for the two magic bytes — "F", "N" — at #raw("$9C00") for up to
  three seconds. Sets fn_ok to 1 when the cartridge answers, 0 when it
  does not (this is not a FujiNet cartridge, or the mailbox is shadowed —
  see Chapter 2).])

Then describe a transaction and run it. Ask the Fuji device
(#hx("$70")) for its WiFi status (command #hx("$FA")):

#stmt("mb_dev = $70 : mb_cmd = $FA : mb_nparam = 0\n#fn_txlen = 0\nGOSUB fn_transact",
  [Stages the request, bumps SEQ, blocks until ACKSEQ answers or 900
  frames pass. On return fn_ok is 1 and the one-byte reply is waiting at
  FN_RX; a 3 means the WiFi is up.])

#stmt("IF (PEEK(FN_RX) AND 255) = 3 THEN PRINT AT 40, \"CONNECTED\"",
  [Reads the reply in place. The AND 255 mask matters — mailbox words
  carry a byte in their low half and whatever in their high half.])

That is genuinely all there is. #cd("hello.bas") below is the complete
program; type it in, or find it with the listings.

#codepanel("hello.bas — one complete transaction", read("listings/hello.bas"))

#sect("Survival rules for IntyBASIC network code")

Every rule below was paid for in debugging time on the three games. They
are worth a page of anyone's attention.

#ssect("Jump over your includes")

An INCLUDE pastes its text where it stands, and falling into a
#cd("PROCEDURE") or #cd("DATA") block by straight-line execution corrupts
the return stack. Make line one of your program #cd("GOTO main") (or
#cd("boot_start")), and put every INCLUDE between it and the label.

#ssect("Respect the memory map")

IntyBASIC compiles into #hx("$5000")–#hx("$6FFF") and keeps going if you
outgrow it — straight into #hx("$7000"), which is *not* in the manual's
list of ranges usable on modern cartridge PCBs. Both Battleship and
Fujitzee overflowed; the fix is an explicit #cd("ASM ORG $D000") placed
so the overflow lands in documented-safe #hx("$C100")–#hx("$FFFF")
territory. Fujitzee's boot loader genuinely hung on real hardware from a
20-word spill that jzIntv forgave. Safe ranges: #hx("$2000")–#hx("$2FFF"),
#hx("$5000")–#hx("$6FFF"), #hx("$A000")–#hx("$BFFF"),
#hx("$C100")–#hx("$FFFF").

#ssect("Parenthesize (PEEK(x) AND 255)")

IntyBASIC's #cd("=") binds *tighter* than #cd("AND") — the same trap as C's
#cd("a & b == c"). An unparenthesized #cd("DEF FN v = PEEK(x) AND 255")
substituted into #cd("IF v = 0") compiles as #cd("PEEK(x) AND (255 = 0)"),
which is always zero. Fujitzee's turn logic silently never ran until the
generated assembly was read. Write #cd("(PEEK(x) AND 255)"), always.

#ssect("Mask into 16-bit variables")

IntyBASIC v1.4.2 silently drops the #cd("AND 255") when the destination of
#cd("var = PEEK(...) AND 255") is an 8-bit variable — no ANDI is emitted at
all, and high-byte garbage survives. #hx("#")-prefixed 16-bit destinations
compile correctly. The library's #cd("#mb_err") and #cd("#net_err") are
16-bit for exactly this reason.

#ssect("Nest IFs instead of chaining AND")

Two equality comparisons joined by #cd("AND"), where a side comes from a
#cd("DEF FN") containing its own #cd("AND 255"), can fuse into code that is
always false. Write nested single-condition IFs. (Fujitzee again;
confirmed in the compiled listing.)

#ssect("Number fields: <.n>, not <n>")

#cd("PRINT <3>") (zero-padded) can print garbage in its leading digit —
its runtime entry point never initializes the pad register.
#cd("PRINT <.3>") (space-padded) initializes it. Use #cd("<.n>") for any
value that can need fewer digits than the field.

#ssect("Wait for key release")

#cd("CONT1.KEY") reads 12 when nothing is pressed. When a key opens a menu,
wait for 12 before accepting input, or the same press instantly triggers
the menu's own handler. And check #cd("CONT1.B1")/#cd("B2") *before*
#cd("CONT1.BUTTON") — BUTTON is a mask that is non-zero for all three
action buttons.

// ############################################################################
// CHAPTER 4 — THE NETWORK DEVICE
// ############################################################################
#chapter("Chapter 4", "The Network Device", [
  Eight channels to anywhere: URLs in, bytes out. Devices #raw("$71")
  through #raw("$78").
])

The Network device turns a URL into a byte channel. Eight independent
units — N1: through N8:, device ids #hx("$71") through #hx("$78") — can
each hold one open connection. Everything in this guide uses N1:.

A connection is named by a *devicespec* — an ASCII string staged in the TX
window when you OPEN:

#align(center, text(font: f-mono, size: 8.6pt, "N:PROTOCOL://HOST[:PORT]/PATH[?QUERY]"))

The protocols in current firmware: HTTP, HTTPS, TCP, UDP, TELNET, TNFS,
FTP, SMB, NFS, SSH, plus a few specials. HTTPS certificates, redirects,
name resolution — the ESP32 handles all of it, so you never see it.

#sect("The life of a connection")

+ #cd("OPEN") with an access mode and translation mode.
+ #cd("STATUS") until data is waiting (or the connection reports an error).
+ #cd("READ") the bytes; #cd("WRITE") your own.
+ #cd("CLOSE").

Two subtleties both games hit, worth learning before writing code. First:
for an HTTP devicespec, *the actual request happens at the first STATUS*,
not at OPEN. OPEN parses and stores; the first STATUS performs the
transaction and its result code lands in the status reply's error byte.
Second: STATUS reports bytes *available so far* — a response still
arriving over WiFi grows between polls. The library's #cd("api_call")
polls until two consecutive STATUS reads agree (call-out #co(6), Listing 1)
before trusting the count. An HTTP error page is still a readable body, so
the byte count alone cannot tell success from a 400 — check the error
byte, which reads 1 (SUCCESS) on a good channel (call-out #co(5)).

#sect("Command reference")

#cmd("OPEN", dev: "$71-78", code: "$4F 'O'",
  params: (("0", "1", [access mode — table below]),
           ("1", "1", [translation — 0 none, 1 CR, 2 LF, 3 CR LF, 4 PETSCII])),
  payload: [devicespec, ASCII, no terminator needed — TXLEN is the length],
  reply: [ACK on success; NAK if the protocol could not connect],
)[Opens the channel. Re-opening an open unit closes it first. Translation
rewrites line endings between the wire and your program; the games use 0
and handle bytes raw.]

#wire(("mode", "meaning", "protocols"),
  (mono7("4"),  "READ / HTTP GET", "all"),
  (mono7("5"),  "HTTP DELETE", "HTTP(S)"),
  (mono7("6"),  "DIRECTORY", "filesystem protocols"),
  (mono7("8"),  "WRITE / HTTP PUT", "all"),
  (mono7("9"),  "APPEND / HTTP DELETE with headers", "file / HTTP(S)"),
  (mono7("12"), "READ-WRITE / HTTP GET with header access", "sockets, HTTP(S)"),
  (mono7("13"), "HTTP POST", "HTTP(S)"),
  (mono7("14"), "HTTP PUT with header access", "HTTP(S)"))

#note[The games open with mode 12 — on HTTP it is a GET that also permits
header interaction through the M command, and on TCP it is plain
read-write. Mode 4 works for fire-and-forget GETs.]

#cmd("CLOSE", dev: "$71-78", code: "$43 'C'", params: (),
)[Tears the connection down. Always close — even after an error — so the
unit is free for the next OPEN. Closing writes a fresh (empty) reply
length, so capture #cd("RXLEN") from a READ before you CLOSE (the library
does: call-out #co(4) territory in Listing 1).]

#cmd("READ", dev: "$71-78", code: "$52 'R'",
  params: (("0", "2", "byte count to read"),),
  reply: [the bytes, in RX; RXLEN says how many arrived],
)[Never ask for more than STATUS said was available — a short channel pads
with NULs and flags an error. Ask STATUS first, clamp, then READ.]

#cmd("WRITE", dev: "$71-78", code: "$57 'W'",
  params: (("0", "2", "byte count to send"),),
  payload: [the bytes],
)[Sends payload bytes out the channel. The count rides twice — as
parameter 0 and as TXLEN — and both must agree.]

#cmd("STATUS", dev: "$71-78", code: "$53 'S'",
  params: (("0", "1", "0"),
           ("1", "1", [request type — 0 for channel status])),
  reply: [4 bytes: available-low, available-high, connected, error],
)[The heartbeat of every network program. #emph[available] is a 16-bit
little-endian count of bytes ready to READ; #emph[connected] is 1 while
the far end holds the connection; #emph[error] is 1 for success or a code
from Appendix A. With no channel open, request types 1–4 return instead
the adapter's IP address, netmask, gateway and DNS, 4 bytes each.]

#cmd("CHANNEL MODE", dev: "$71-78", code: "$FC",
  params: (("0", "1", "0"),
           ("1", "1", "0 protocol (raw), 1 JSON, 2 SGML")),
)[Switches the open channel between raw bytes and a parsed view. In JSON
mode, PARSE ingests the body and QUERY extracts values by path — see the
worked sequence below.]

#cmd("PARSE", dev: "$71-78", code: "$50 'P'", params: (),
)[JSON/SGML mode: reads the entire response body off the protocol and
parses it. Do this once, after STATUS says the body has arrived.]

#cmd("QUERY", dev: "$71-78", code: "$51 'Q'",
  params: (),
  payload: [a query path, e.g. #cd("/0/name") — 256 bytes, NUL-padded],
)[Selects a value out of the parsed document. After QUERY, STATUS reports
the extracted value's length and READ returns it as text.]

#cmd("SET CHANNEL MODE (HTTP)", dev: "$71-78", code: "$4D 'M'",
  params: (("0", "1", "0"),
           ("1", "1", "0 body, 1 collect headers, 2 get headers, 3 set headers, 4 set POST data")),
)[HTTP only: redirects READ/WRITE at the header machinery instead of the
body — set request headers before the transaction, read response headers
after.]

#cmd("TRANSLATION", dev: "$71-78", code: "$54 'T'",
  params: (("0", "1", "0"), ("1", "1", "as OPEN parameter 1")),
)[Changes line-ending translation on an open channel.]

#cmd("SET EOL", dev: "$71-78", code: "$4C 'L'",
  params: (("0", "1", "first EOL byte, or 0 to restore the default"),
           ("1", "1", "optional second EOL byte")),
)[Overrides what the translation layer treats as your machine's native
line ending.]

#cmd("SEEK / TELL", dev: "$71-78", code: "$25 / $26",
  params: (("0", "4", "SEEK only: absolute byte offset"),),
  reply: [TELL: 4 bytes, little-endian, current offset],
)[Repositions within a seekable resource. On HTTP this issues a Range
request — valid for GET reads in body mode.]

#cmd("GETCWD / CHDIR", dev: "$71-78", code: "$30 / $2C",
  params: (),
  payload: [CHDIR: the new prefix/path],
  reply: [GETCWD: 256 bytes, the prefix],
)[Maintains a working-directory prefix for filesystem protocols, so later
devicespecs can be relative.]

#cmd("USERNAME / PASSWORD", dev: "$71-78", code: "$FD / $FE",
  params: (),
  payload: [the credential, up to 256 bytes],
)[Stages login credentials before OPEN, for protocols that need them
(SMB, FTP, SSH…).]

#cmd("TCP: ACCEPT / CLOSE CLIENT", dev: "$71-78", code: "$41 / $63",
  params: (),
)[A TCP devicespec with no host — #cd("N:TCP://:6502/") — listens.
#hx("$41") accepts a waiting caller onto the channel; #hx("$63") hangs up
on the caller and resumes listening. Your Intellivision can be the
server.]

#cmd("UDP: SET DESTINATION", dev: "$71-78", code: "$44 'D'",
  params: (),
  payload: [#cd("host:port") for subsequent datagrams],
)[UDP is connectionless; this sets where WRITEs go. (The companion
#hx("$72") GET-REMOTE query exists only in the PC build of the firmware,
not on the ESP32.)]

#cmd("FILE OPS", dev: "$71-78", code: "$20/$21/$23/$24/$2A/$2B",
  params: (),
  payload: [a devicespec (RENAME: #cd("old,new"))],
)[RENAME #hx("$20"), DELETE #hx("$21"), LOCK #hx("$23"), UNLOCK
#hx("$24"), MKDIR #hx("$2A"), RMDIR #hx("$2B") — for protocols with a
filesystem behind them (TNFS, SMB, FTP…).]

#sect("A JSON round trip")

The game servers in this guide sidestep JSON with #cd("?bin=1") binary
replies (Chapter 8), but the parser is there when you want it:

#stmt("' open, then: switch the channel to JSON\nmb_cmd = $FC : mb_nparam = 2\npm_i = 0 : pm_size = 1 : #pm_val = 0 : GOSUB fn_param\npm_i = 1 : pm_size = 1 : #pm_val = 1 : GOSUB fn_param\nGOSUB fn_transact",
  [Channel mode 1 = JSON.])
#stmt("mb_cmd = $50 : mb_nparam = 0 : #fn_txlen = 0 : GOSUB fn_transact",
  [PARSE — the FujiNet reads and digests the whole body.])
#stmt("' stage \"/0/title\" in FN_TX, NUL-padded, then:\nmb_cmd = $51 : GOSUB fn_transact",
  [QUERY selects one value by path.])
#stmt("GOSUB net_status : #net_readlen = #net_avail : GOSUB net_read",
  [STATUS now reports the extracted value's length; READ fetches it as
  ASCII, ready to draw with draw_field.])

// ############################################################################
// CHAPTER 5 — THE FUJI DEVICE
// ############################################################################
#chapter("Chapter 5", "The Fuji Device", [
  Device #raw("$70"): the FujiNet's own control panel — WiFi, hosts,
  directories, disk images, AppKeys, and a bag of coprocessor tricks.
])

Everything that is *about the FujiNet itself* — rather than about one
network connection — lives on device #hx("$70"). CONFIG is nothing but a
client of this device, and everything CONFIG does, your program can do.

#sect("WiFi")

#cmd("GET WIFI STATUS", dev: "$70", code: "$FA", params: (),
  reply: [1 byte: 3 = connected; other values are the ESP32 WL codes
  (0 idle, 1 no SSID, 4 connect failed, 5 connection lost, 6 disconnected)],
)[The first thing #cd("hello.bas") asks. Poll it after SET SSID — the
join takes a few seconds.]

#cmd("SCAN NETWORKS", dev: "$70", code: "$FD", params: (),
  reply: [1 byte: number of networks found],
)[Blocks while the ESP32 scans. Follow with GET SCAN RESULT for each
index.]

#cmd("GET SCAN RESULT", dev: "$70", code: "$FC",
  params: (("0", "1", "network index, 0-based"),),
  reply: [34 bytes: SSID (33, NUL-terminated) + RSSI (1, signed)],
)[]

#cmd("SET SSID", dev: "$70", code: "$FB",
  params: (("0", "1", "any value — at least one parameter must be present"),),
  payload: [97 bytes exactly: SSID (33) + password (64), NUL-padded],
)[Joins and *saves* the network. The parameter is ignored but required.
The 97-byte shape is not negotiable — see the payload rule below.]

#cmd("GET SSID", dev: "$70", code: "$FE", params: (),
  reply: [97 bytes: the stored SSID + password in the same shape],
)[]

#cmd("GET WIFI ENABLED", dev: "$70", code: "$EA", params: (),
  reply: [1 byte, 0/1],
)[]

#warn[#emph[The exact-length payload rule.] The ESP32 handler for a
fixed-size payload fails the transaction if *fewer* bytes arrive than the
structure it expects — SET SSID wants exactly 97, OPEN DIRECTORY and SET
DEVICE FULLPATH want exactly 256. Sending a short, "obviously enough"
payload reads back as a NAK. Pad with NULs to the documented size, every
time.]

#sect("Hosts and mounts")

Eight *host slots* name the file servers CONFIG browses — TNFS hosts, SMB
shares. Eight *device slots* bind a file on some host to an emulated disk.
On the Intellivision the disk story is what powers network booting.

#cmd("READ HOST SLOTS", dev: "$70", code: "$F4", params: (),
  reply: [256 bytes: 8 hostnames × 32, NUL-padded],
)[]

#cmd("WRITE HOST SLOTS", dev: "$70", code: "$F3", params: (),
  payload: [the same 256-byte block, all 8 slots at once],
)[There is no single-slot write — read, modify one, write all.]

#cmd("MOUNT HOST", dev: "$70", code: "$F9",
  params: (("0", "1", "host slot, 0–7"),),
)[Connects to the named server. Required before directory or file
operations on that slot.]

#cmd("SET HOST PREFIX / GET HOST PREFIX", dev: "$70", code: "$E1 / $E0",
  params: (("0", "1", "host slot"),),
  payload: [SET: the prefix string],
  reply: [GET: the prefix],
)[A per-host working directory.]

#cmd("OPEN DIRECTORY", dev: "$70", code: "$F7",
  params: (("0", "1", "host slot"),),
  payload: [256 bytes exactly: path, NUL, wildcard filter (may be empty),
  NUL, then NUL padding],
)[Opens a directory listing on a mounted host. The filter understands
#cd("*") and #cd("?") only.]

#cmd("READ DIR ENTRY", dev: "$70", code: "$F6",
  params: (("0", "1", "maximum reply length"),
           ("1", "1", [flags: 0 plain, #hx("$80") with details])),
  reply: [plain: the filename, NUL-terminated — directories carry a
  trailing #cd("/"); end of directory is two #hx("$7F") bytes.
  With #hx("$80"): a 10-byte prefix (modified date 6, size 4 LE) plus
  flags and media type precede the name],
)[CONFIG's file browser is this command in a loop.]

#cmd("CLOSE DIRECTORY", dev: "$70", code: "$F5", params: ())[]

#cmd("GET / SET DIRECTORY POSITION", dev: "$70", code: "$E5 / $E4",
  params: (("0", "2", "SET: absolute entry index"),),
  reply: [GET: 2 bytes, little-endian],
)[Random access into the listing — how CONFIG pages backward without
rereading from the top.]

#cmd("READ / WRITE DEVICE SLOTS", dev: "$70", code: "$F2 / $F1",
  params: (),
  payload: [WRITE: 8 records of {host slot, mode, filename[36]} = 304 bytes],
  reply: [READ: the same 304-byte block],
)[The table binding device slots to files.]

#cmd("SET DEVICE FULLPATH", dev: "$70", code: "$E2",
  params: (("0", "1", "device slot"), ("1", "1", "host slot"),
           ("2", "1", "mode: 1 read")),
  payload: [256 bytes exactly: full path, NUL-padded],
)[Points a device slot at a file. On the Intellivision this is also where
the cartridge learns the filename it will derive a JLP flash save-file
name from — CONFIG always sends it immediately before MOUNT IMAGE.]

#cmd("GET DEVICE FULLPATH", dev: "$70", code: "$DA",
  params: (("0", "1", "device slot"),),
  reply: [the path],
)[]

#cmd("MOUNT IMAGE", dev: "$70", code: "$F8",
  params: (("0", "1", "device slot"), ("1", "1", "access flags: 1 read")),
)[On every FujiNet: mounts the image. On the Intellivision: *boots it* —
the ESP32 pushes the ROM back through the cartridge as described in
Chapter 2, and this transaction is allowed 60 seconds. Watch
#cd("BOOT_PCT") for a progress bar while you wait.]

#cmd("UNMOUNT IMAGE", dev: "$70", code: "$E9",
  params: (("0", "1", "device slot"),))[]

#cmd("MOUNT ALL / NEW DISK / COPY FILE", dev: "$70", code: "$D7 / $E7 / $D8",
  params: (),
)[Housekeeping from the wider FujiNet family: mount every configured
slot; create a blank image ({sectors u16, sector size u16, host slot,
device slot, filename[256]} payload); copy between hosts (parameters
source and destination slot, payload the copy spec).]

#cmd("CONFIG BOOT / SET BOOT MODE", dev: "$70", code: "$D9 / $D6",
  params: (("0", "1", "flag / mode"),),
)[Controls whether the FujiNet offers CONFIG at power-up. The
Intellivision cartridge boots CONFIG from its own flash, so CONFIG BOOT
has no effect here — and CONFIG deliberately never sends it.]

#sect("AppKeys — small facts that survive power-off")

An AppKey is up to 64 bytes stored on the FujiNet, addressed by a
registered *creator id* (16-bit), an *app id* and a *key id*. The games
use them for the player name and the Lobby handoff (Chapter 11). The
protocol is open–operate–close:

#cmd("OPEN APPKEY", dev: "$70", code: "$DC",
  params: (),
  payload: [6 bytes: creator low, creator high, app, key, mode
  (0 read, 1 write, 2 read-256), reserved (0)],
)[Selects which key the next read or write touches. Mode 2 selects
256-byte keys; plain mode 0 reads 64-byte keys. #emph[All six bytes are
required] — a 5-byte payload leaves the firmware waiting for the last
byte and reads back as a timeout (call-out #co(7) neighborhood, Listing 1).]

#cmd("READ APPKEY", dev: "$70", code: "$DD", params: (),
  reply: [2-byte little-endian length, then the data],
)[The length prefix is specific to this bus (an appkey read takes no
length parameter, so the reply describes itself). RXLEN covers prefix +
data. Call-out #co(7) in Listing 1 shows the client-side handling.]

#cmd("WRITE APPKEY", dev: "$70", code: "$DE", params: (),
  payload: [the value — length is TXLEN],
)[]

#cmd("CLOSE APPKEY", dev: "$70", code: "$DB", params: ())[]

#note[Creator #cd("1") / app #cd("1") is the FujiNet game system.
Key 0 holds the shared player name every lobby game reads; keys 1, 3 and 5
are the 5 Card Stud, Fujitzee and Battleship server-handoff slots. New
creator ids are registered on the fujinet-firmware wiki's AppKey page.]

#sect("Adapter information")

#cmd("GET ADAPTERCONFIG EXTENDED", dev: "$70", code: "$C4", params: (),
  reply: [240 bytes — table below. The older #hx("$E8") form is the first
  140 bytes only, without the printable strings],
)[One call answers "what is my IP" for an About screen — CONFIG's info
page is this struct drawn on screen.]

#wire(("offset", "size", "field", "notes"), widths: (46pt, 40pt, 92pt, 1fr),
  (mono7("0"),   mono7("33"), "ssid",       "NUL-terminated"),
  (mono7("33"),  mono7("64"), "hostname",   ""),
  (mono7("97"),  mono7("4"),  "localIP",    "binary, one octet per byte"),
  (mono7("101"), mono7("4"),  "gateway",    ""),
  (mono7("105"), mono7("4"),  "netmask",    ""),
  (mono7("109"), mono7("4"),  "dnsIP",      ""),
  (mono7("113"), mono7("6"),  "macAddress", "binary"),
  (mono7("119"), mono7("6"),  "bssid",      "binary"),
  (mono7("125"), mono7("15"), "fn_version", "printable"),
  (mono7("140"), mono7("16"), "sLocalIP",   "dotted-quad string"),
  (mono7("156"), mono7("16"), "sGateway",   ""),
  (mono7("172"), mono7("16"), "sNetmask",   ""),
  (mono7("188"), mono7("16"), "sDnsIP",     ""),
  (mono7("204"), mono7("18"), "sMacAddress","colon string"),
  (mono7("222"), mono7("18"), "sBssid",     ""))

#cmd("STATUS", dev: "$70", code: "$53 'S'",
  params: (("0", "1", "1 = mount-time report"),),
  reply: [one timestamp per disk device — 0 means unmounted],
)[]

#cmd("RESET / DEVICE READY / GENERATE GUID", dev: "$70", code: "$FF / $00 / $BB",
  params: (),
)[RESET reboots the ESP32 (the mailbox link drops and comes back).
DEVICE READY answers 512 bytes of #cd("A") — a link self-test.
GENERATE GUID returns a fresh unique id, handy for session tokens.]

#sect("The coprocessor bag")

Three little engines share a buffer-in / compute / length / buffer-out
shape. Feed input in chunks, compute, ask the length, then drain.

#cmd("BASE64 ENCODE", dev: "$70", code: "$D0/$CF/$CE/$CD",
  params: (("0", "2", "INPUT and OUTPUT: byte count"),),
  payload: [INPUT: the bytes],
  reply: [LENGTH: 4 bytes; OUTPUT: the requested bytes, consumed as read],
)[INPUT #hx("$D0") accumulates, COMPUTE #hx("$CF") transforms the buffer
in place, LENGTH #hx("$CE"), OUTPUT #hx("$CD"). Decode is the mirror set
#hx("$CC")–#hx("$C9").]

#cmd("HASH", dev: "$70", code: "$C8/$C7/$C6/$C5/$C2",
  params: (("0", "2", "INPUT: byte count.  COMPUTE: algorithm — 0 MD5,
  1 SHA-1, 2 SHA-256, 3 SHA-512.  LENGTH/OUTPUT: 1 = hex text, 0 = binary"),),
  payload: [INPUT: the bytes],
  reply: [LENGTH: 1 byte; OUTPUT: the digest],
)[#hx("$C3") computes without clearing the input, for incremental use;
CLEAR #hx("$C2") abandons it. A SHA-256 of a game state in one
transaction — try that on a CP-1610.]

#cmd("QR CODE", dev: "$70", code: "$BC/$BD/$BE/$BF",
  params: (("0", "2", "INPUT: byte count.  ENCODE: version.  LENGTH/OUTPUT:
  output mode"), ("1", "1", "ENCODE: error-correction level"),
  ("2", "1", "ENCODE: shorten flag")),
  payload: [INPUT: the text],
  reply: [LENGTH: 4 bytes; OUTPUT: the module bitmap],
)[Render the output on the colored-squares screen (the kernel in
Chapter 9 draws 40×24 pixels) and you have a scannable screen.]

// ############################################################################
// CHAPTER 6 — THE CLOCK DEVICE
// ############################################################################
#chapter("Chapter 6", "The Clock Device", [
  Device #raw("$45"): real time, seven ways, time-zone aware.
])

The FujiNet keeps real time via NTP. Device #hx("$45") serves it in every
format the wider FujiNet world has ever asked for. All GET commands accept
an optional parameter 0: a value of 1 selects the *alternate* time zone
set by #hx("$74"), letting a program show a second clock without touching
the saved configuration.

#wire(("cmd", "name", "reply"),
  (mono7("$93"), "GET TIME", "6 bytes: day, month, year-2000, hour, minute, second"),
  (mono7("$9A"), "GET TZ TIME", "the same 6 bytes, always in the alternate zone"),
  (mono7("$47 'G'"), "GET SIMPLE", "7 bytes: century, year, month, day, hour, minute, second"),
  (mono7("$4D 'M'"), "GET SIMPLE + HUNDREDTHS", "8 bytes: simple + hundredths (0–99)"),
  (mono7("$50 'P'"), "GET PRODOS", "4 bytes, ProDOS packed date/time"),
  (mono7("$53 'S'"), "GET SOS", "NUL-terminated Apple SOS string"),
  (mono7("$49 'I'"), "GET ISO LOCAL", [NUL-terminated ISO-8601 string, local]),
  (mono7("$5A 'Z'"), "GET ISO UTC", "NUL-terminated ISO-8601 string, UTC"),
  (mono7("$99"), "SET TZ", "— payload: POSIX TZ string, saved to config"),
  (mono7("$74 't' / $54 'T'"), "SET ALT TZ", "— payload: POSIX TZ string, this session only"),
  (mono7("$4C 'L'"), "GET TZ LENGTH", "1 byte: length of the saved TZ string"),
  (mono7("$47"), "GET TZ", "the saved TZ string, NUL-terminated"))

#stmt("mb_dev = $45 : mb_cmd = $93 : mb_nparam = 0\n#fn_txlen = 0 : GOSUB fn_transact\nday = PEEK(FN_RX) AND 255",
  [Six PEEKs later your game has a real-world timestamp — for a
  tournament clock, a daily challenge seed, or just a clock on the title
  screen.])

// ############################################################################
// CHAPTER 7 — THE FUJINET.BAS LIBRARY
// ############################################################################
#chapter("Chapter 7", "The fujinet.bas Library", [
  Sixteen procedures, tested in three shipped games. INCLUDE it and go.
])

Listing 1 is the complete library — the exact transport all three game
chapters build on, in its newest revision (the games in the field carry
two vintages; this one folds in the compiler-bug fixes from Chapter 3 and
adds #cd("net_write") and #cd("fn_putnum")). Include it after your
opening GOTO:

#stmt("    GOTO main\n    INCLUDE \"fujinet.bas\"\nmain:",
  [Remember: never fall into an include. Chapter 3's first survival
  rule.])

#sect("Transport")

#ssect("fn_wait_mailbox")
Waits up to 180 frames for the mailbox magic bytes. Sets #cd("fn_ok").
Call once at boot, before anything else. #co(1)

#ssect("fn_transact")
The engine. In: #cd("mb_dev"), #cd("mb_cmd"), #cd("mb_nparam"),
#cd("#fn_txlen") (payload already at #cd("FN_TX")), parameters staged via
#cd("fn_param"). Out: #cd("fn_ok"); on failure #cd("#mb_err") holds the
link error (0 on timeout — the RP2040 never answered). Derives SEQ from
ACKSEQ #co(2), polls up to 900 frames #co(3), and verifies the ACK #co(4).

#ssect("fn_param")
Stages parameter #cd("pm_i") (0-based) of size #cd("pm_size") (1 or 2
bytes here; the mailbox allows 4) with value #cd("#pm_val") into the
parameter table.

#ssect("fn_putstr / fn_strlen")
The string kit. #cd("fn_putstr") appends #cd("fn_len") bytes from address
#cd("#fn_src") — ROM DATA via VARPTR, or any RAM buffer — to the TX
window, advancing #cd("#fn_txlen"). #cd("fn_strlen") measures a
NUL-padded field first, so padded storage never leaks NULs into a URL
(the wire sends TXLEN bytes verbatim; an embedded NUL corrupts the HTTP
request downstream).

#sect("Network shorthand")

#ssect("net_open")
Opens the devicespec staged at #cd("FN_TX") for HTTP GET (mode 12,
translation 0).

#ssect("net_status")
STATUS with the two zero parameters; unpacks available count into
#cd("#net_avail") and the error byte into #cd("#net_err") #co(5) — and
folds "error ≠ 1" into #cd("fn_ok"), which is what catches an HTTP error
page masquerading as a good response.

#ssect("net_read")
Reads #cd("#net_readlen") bytes; the count that actually arrived lands in
#cd("#net_gotlen") — captured before CLOSE can overwrite RXLEN.

#ssect("net_write")
Sends #cd("fn_len") bytes already at #cd("FN_TX"). New in this guide's
revision; the netcat in Appendix D is its first customer.

#ssect("net_close")
Closes N1:. Unconditionally safe.

#ssect("api_call")
The one-shot HTTP GET: open → settle-poll STATUS #co(6) → clamp → read →
close. Set #cd("#net_readlen") to your reply buffer budget first. This is
the only network call the three games ever make.

#sect("AppKeys")

#ssect("appkey_open / appkey_read / appkey_write / appkey_close")
Set #cd("ak_creator_lo/hi"), #cd("ak_app"), #cd("ak_key"), #cd("ak_mode")
and open; then read into a buffer at #cd("#fn_src") (bounded by
#cd("ls_max"), always NUL-terminated, actual length in #cd("fn_len") —
the 2-byte reply prefix is consumed for you #co(7)) or write #cd("fn_len")
bytes from #cd("#fn_src"); then close.

#sect("Utility")

#ssect("fn_putnum")
Appends #cd("pn_val") (0–999) to the TX window as decimal ASCII — the
missing #cd("itoa") for building URLs like #cd("/attack/47").

#note[The library owns scratch RAM #hx("$9100")–#hx("$917F") for three
buffers: #cd("SC_NAME") (player name, 9), #cd("SC_ENDPT") (server
endpoint, 64), #cd("SC_QUERY") (48). Everything below #hx("$9C00") and
above your own use is yours to allocate; the games start theirs at
#hx("$9180").]

// ############################################################################
// CHAPTER 8 — FIVE CARD STUD
// ############################################################################
#chapter("Chapter 8", "Game One: 5 Card Stud", [
  Eight seats, a felt table, and every bet a URL. The founding game of the
  FujiNet game system, on a 159×96 screen.
])

*5 Card Stud* (Listing 2) is the pattern the other two games copy: a thin
IntyBASIC client that draws whatever a stateless-feeling HTTP server says
the table looks like. The client never knows the rules of poker. It knows
how to draw a Game structure, and how to ask again.

#sect("The shape of the client")

#align(center, block(above: 6pt, below: 6pt, {
  set text(size: 7.4pt)
  let step(t) = box(stroke: 1.2pt + magenta, radius: 4pt,
    inset: (x: 6pt, y: 4pt), text(font: f-body, weight: 500, t))
  stack(dir: ltr, spacing: 3pt,
    step("boot +\nmailbox"), align(horizon, arrow-r),
    step("name from\nAppKey 1/1/0"), align(horizon, arrow-r),
    step("room from\nAppKey 1/1/1"), align(horizon, arrow-r),
    step("table\nselect"), align(horizon, arrow-r),
    step("poll loop\n/state"), align(horizon, arrow-r),
    step("move UI\n/move/XX"))
}))

At boot (Listing 2 #co(1)) the client reads the shared player name from
AppKey creator 1 / app 1 / key 0 — *with one retry*, because the very
first transaction after power-on can catch the USB link still waking —
and validates every byte to A–Z 0–9. That slot is shared by every FujiNet
game on every platform, so it can hold anything; anything outside the
name-entry alphabet goes straight into a URL query string unescaped, and
a stray #cd("&") turns into a broken request the server answers with an
HTTP error page. Fall back to the letter-picker if in doubt.

Then the Lobby handoff (Chapter 11, and #co(2) in Listing 2): AppKey
creator 1 / app 1 / key 1 may hold #cd("https://host/?table=xyz") written
by the Lobby client. If it parses (#cd("split_room_url")), the client
skips straight to that table; if not, it seeds the compiled-in default
endpoint and shows table select.

#sect("URLs, composed byte by byte")

IntyBASIC has no strings, so URLs are assembled by #cd("compose_url")
(#co(3)) from ASCII #cd("DATA") literals and scratch buffers, directly
into the TX window:

#align(center, text(font: f-mono, size: 7.8pt,
  "N:https://5card.carr-designs.com/state?table=r1&player=THOM&bin=1"))

#wire(("path", "when", "reply"),
  (mono7("tables?bin=1"), "table select", "Tables structure"),
  (mono7("state?…&bin=1"), "every poll", "Game structure"),
  (mono7("move/XX?…&bin=1"), "your move (XX = 2-char code)", "Game structure"),
  (mono7("leave?…&bin=1"), "quit table", [#cd("bye")]))

#cd("?bin=1") asks the server for its binary serialization — fixed
offsets, no JSON parser needed. Multi-byte numbers are little-endian.
(There is a #cd("&be=1") big-endian option; the Intellivision client
tried it and retired it after pot values kept landing on suspicious
multiples of 256 — the signature of a byte-order mismatch. Little-endian
is the road the whole client family exercises daily. Stay on it.)

#sect("The Tables structure")

#wire(("offset", "size", "field", "notes"), widths: (46pt, 40pt, 92pt, 1fr),
  (mono7("0"), mono7("1"), "count", "tables that follow"),
  (mono7("1+36i"), mono7("9"), "table id", "NUL-padded, lowercased"),
  (mono7("10+36i"), mono7("21"), "name", ""),
  (mono7("31+36i"), mono7("6"), "players", [literal text like #cd("2 / 8")]))

The client validates before trusting: reply length must cover
#cd("1 + count×36") bytes, or the "Tables structure" was actually an error
page and the poll is retried (#co(4)).

#sect("The Game structure")

#wire(("offset", "size", "field", "notes"), widths: (46pt, 40pt, 92pt, 1fr),
  (mono7("0"),   mono7("81"), "lastResult", "one-shot message, NUL-padded"),
  (mono7("81"),  mono7("1"),  "round", "0 wait, 1–4 streets, 5 showdown"),
  (mono7("82"),  mono7("2"),  "pot", "u16 LE"),
  (mono7("84"),  mono7("1"),  "activePlayer", [signed; #hx("$FF") = none, 0 = you]),
  (mono7("85"),  mono7("1"),  "moveTime", "seconds left, server-computed"),
  (mono7("86"),  mono7("1"),  "viewing", "1 = you are a spectator"),
  (mono7("87"),  mono7("1"),  "validMoveCount", ""),
  (mono7("88"),  mono7("65"), "validMoves[5]", "13 each: code[3] + name[10]"),
  (mono7("153"), mono7("1"),  "playerCount", ""),
  (mono7("154"), mono7("33×N"), "players[N]", "name[9] status(1) bet(2 LE) move[8] purse(2 LE) hand[11]"))

Wire index 0 is *always you* — the server rotates the array per client.
Hands are ASCII pairs (rank #cd("2")–#cd("9"), #cd("t j q k a"); suit
#cd("d h c s")); a hidden card is #cd("??"), which the renderer converts
to the card-back glyph. Status: 0 waiting, 1 playing, 2 folded, 3 left.

Validation is layered (#co(5)): length ≥ the 154-byte fixed prefix; round
≤ 5 and playerCount ≤ 8 (an HTTP error page fails this instantly); and
length ≥ #cd("154 + playerCount×33") — because a short read leaves stale
bytes from a previous, larger reply in the RX window, and fixed-offset
reads would render them as garbage.

#sect("Drawing without flicker")

The STIC has no page-flip: BACKTAB is live every frame. The client's
answer (#co(6), and the long comment in Listing 2 is worth reading whole)
is *differential rendering*: a full CLS only when the layout genuinely
changed (first render, player count changed, new hand); otherwise only
cells whose values changed are poked, and the redraw yields a #cd("WAIT")
between seats so no single burst outruns vblank — the cause of a
half-drawn frame a screenshot once caught and made look like data
corruption. Seat placement comes from the C clients' #cd("seatmap") table
(player count → seat ring); each seat draws name, bet and its dealt
cards, clicking #cd("sound_deal") only for cards not shown last poll.

#sect("Your turn")

When #cd("activePlayer") is 0 and you are not a spectator, #cd("move_ui")
(#co(7)) lists up to five server-supplied moves on the status row —
#emph[the server names the moves]; the client just draws
#cd("validMoves[i].name") and submits #cd(".move") — with the cursor
defaulting to the second entry (not Fold), a countdown seeded from
#cd("moveTime") (the server already subtracted a 4-second network grace),
and timeout submitting the highlighted move, exactly like the C clients.
Move codes you will see: #cd("FO") fold, #cd("CH") check, #cd("CA") call,
#cd("BL")/#cd("BH") bet low/high, #cd("RA") raise, #cd("BB") post
bring-in.

The one-shot #cd("lastResult") ("fry bot won with pair, sixes") is easy
to miss at bot speed, so the client hashes the field each poll; a changed,
non-empty hash blacks out the bottom rows, shows the message for four
seconds (#co(8)), and forces a redraw afterward.

#tv("CHOOSE A TABLE
>THE MAIN TABLE  2/8
 SMALL STAKES    0/8
 BOT PRACTICE   1/8
 HIGH ROLLERS    0/8")

#sect("The server")

#cd("servers/fujinet-game-system/5cardstud") is a Go/gin service. Every
route does the same four things: lock the table, apply game logic, save
state, serialize the client-centric view — JSON by default, the binary
layout above with #cd("?bin=1") (that serializer is
#cd("util.go")'s #cd("appendFixedLengthString") plus little-endian
#cd("appendUint16"); every string is lowercased and gets one NUL
terminator, which is why fields are "size + 1" on the wire).
State lives in a #cd("sync.Map") keyed by table, one mutex per table;
bots move after 3 seconds, humans get 39, minus the 4-second grace the
client shows. A hidden #cd("test") table is reserved for client
developers — polls there never register on the public Lobby.

// ############################################################################
// CHAPTER 9 — BATTLESHIP
// ############################################################################
#chapter("Chapter 9", "Game Two: Battleship", [
  Four 10×10 oceans on one screen, and one shot that hits all of them.
  A lesson in the STIC's other graphics mode.
])

Battleship (Listing 6) needed something 5 Card Stud did not: four 10×10
grids visible at once. Text cards cannot do it — but the STIC's
*colored-squares* mode can. Its distinctive rule: every shot you fire
lands on the same coordinate of #emph[every] opposing board
simultaneously. One cursor, up to three victims.

#sect("The colored-squares kernel")

A BACKTAB word with bit 12 set and bit 11 clear stops being a character
and becomes four independently colored 4×4-pixel quadrants. #cd("board.bas")
(Listing 8) wraps that in three calls: #cd("cs_fill") (whole card),
#cd("cs_plot") (read-modify-write one quadrant, #co(1)), and the
board-level #cd("board_cell") (quadrant of a 5×5-card board = one grid
cell). Two hardware quirks are baked into its tables: the bottom-right
quadrant's high color bit lives up at bit 13, not bit 11 (the pre-shifted
#cd("cs_val") table hides this); and the update mask must clear the
enable bit before adding it back — an early version preserved it, the ADD
doubled it into bit 13, and the card snapped back to text mode showing a
stray letter (the comment at #co(1) tells the story).

The screen: quadrants q1/q2 on the top row, q0 (always you) / q3 below,
black divider lines, a 9-column chrome panel on the right for names and
ships-left, and the prompt row at the bottom.

#sect("Client flow and wire format")

Boot, name, Lobby handoff and table select are 5 Card Stud verbatim
(AppKey key 5 this time). The poll loop differs in one habit: the reply's
*header* decides everything. Requests add #cd("&bin=1&v=2") — version 2
matters, because at game over v1 hides the winner's ships and the
game-over screen wants to reveal them (#co(2)).

#wire(("offset", "size", "field", "notes"), widths: (46pt, 40pt, 92pt, 1fr),
  (mono7("0"),  mono7("1"),  "playerCount", ""),
  (mono7("1"),  mono7("33"), "prompt", "server-composed status line"),
  (mono7("34"), mono7("1"),  "status", "0 lobby, 1 place, 10 start, 11 miss, 12 hit, 13 sunk, 99 over"),
  (mono7("35"), mono7("1"),  "playerStatus", "you: 0 playing, 1 defeated, 2 viewing, 3 ready, 10 placing"),
  (mono7("36"), mono7("1"),  "activePlayer", [signed, #hx("$FF") none]),
  (mono7("37"), mono7("1"),  "moveTime", "seconds"))

Then it branches. In the lobby (status 0): server name (21) plus
10-byte records {name[9], ready}. In play: lastAttackPos (1), myShips
(10 — yours in [0..4], the winner's in [5..9] at game over), then
115-byte records {name[9], status, gamefield[100], shipsLeft[5]}. A
gamefield byte is 0 unknown, 1 hit, 2 miss; a ship byte encodes
#emph[cell + 100×direction] (0 across, 1 down) — so 47 is a horizontal
ship starting at column 7 row 4, and 147 the same cell going down.
#cd("validate_state") (Listing 7 #co(3)) computes the expected length for
whichever branch applies before any offset is trusted.

#sect("Placing and shooting")

Placement (#co(4)) is fully client-side until the last moment: five ships
(5,4,3,3,2) start at random legal spots; the disc slides, #kcap("B1")
rotates, the action button confirms against a local occupancy map — no
server round-trip to discover an overlap. The result is five encoded
bytes, comma-joined into #cd("/place/25,113,4,167,89"). The server
answers with authoritative myShips, and the renderer draws *those*, which
is what makes a reconnect after a reset come back with your real fleet.

Targeting (#co(5)) draws one yellow cursor on every live enemy quadrant in
lockstep, counts down #cd("moveTime"), and on fire sends
#cd("/attack/47"). The status codes 11/12/13 then narrate the result —
paired with #cd("lastAttackPos") so each miss/hit/sunk sound plays once
per actual event, not once per poll that repeats the status (#co(6)).

Rendering diffs each visible gamefield against a 100-byte shadow copy per
quadrant in scratch RAM (#co(7)) — the same differential-drawing lesson as
5 Card Stud, with the same one-WAIT-per-board vblank discipline.

#sect("The server")

Routes: #cd("/state"), #cd("/ready"), #cd("/place/:ships"),
#cd("/attack/:pos"), #cd("/leave"), #cd("/tables"), #cd("/view") — plus a
dev-only #cd("/debugEndGame/:winner"). Same table-mutex pattern as 5 Card
Stud. Timing: bots 3 s, humans 45 s (250 s when you are alone at a table,
capped so it still fits the one-byte moveTime), 4-second network grace, a
5-second bonus after a status change. The hard-coded rooms: two open seas
and three AI tables (one, two and three bots), plus the hidden
#cd("test") room. When only bots remain, the game resets to the lobby.

// ############################################################################
// CHAPTER 10 — FUJITZEE
// ############################################################################
#chapter("Chapter 10", "Game Three: Fujitzee", [
  Five dice, thirteen rounds, sixteen scores — and a scorecard bigger than
  the screen.
])

Fujitzee (Listing 10) is the dice game you think it is, and the most
UI-dense of the three: a 15-category scorecard per player simply does not
fit on a 20×12 screen next to six seats and five dice. The client's
answer is *one card at a time* — a permanent seat strip, dice row and
prompt, with the disc paging whose scorecard fills the middle.

#sect("Wire format")

Unlike Battleship, the structure is the same shape in every round:

#wire(("offset", "size", "field", "notes"), widths: (46pt, 40pt, 92pt, 1fr),
  (mono7("0"),  mono7("1"),  "playerCount", "seats + spectators, up to 12"),
  (mono7("1"),  mono7("21"), "serverName", ""),
  (mono7("22"), mono7("41"), "prompt", ""),
  (mono7("63"), mono7("1"),  "round", "0 lobby, 1–13 play, 99 over"),
  (mono7("64"), mono7("1"),  "rollsLeft", ""),
  (mono7("65"), mono7("1"),  "activePlayer", "signed"),
  (mono7("66"), mono7("1"),  "moveTime", "seconds"),
  (mono7("67"), mono7("1"),  "viewing", ""),
  (mono7("68"), mono7("6"),  "dice", [5 ASCII digits #cd("1")–#cd("6") + NUL; empty at turn start]),
  (mono7("74"), mono7("6"),  "keepRoll", [5 ASCII #cd("0")/#cd("1") + NUL — 1 rerolls]),
  (mono7("80"), mono7("15"), "validScores", [signed bytes; #hx("$FF") = not selectable]),
  (mono7("95"), mono7("42×N"), "players[N]", "name[9] alias(1) scores[16] (u16 LE each)"))

Scores are sixteen little-endian words: six upper categories, computed
upper total and bonus (indices 6, 7 — a player never picks those
directly), seven lower categories (8–14, index 14 is Fujitzee itself),
and the running total at 15. #hx("$FFFF") is "unset"; in the lobby,
#cd("scores[0]") moonlights as the ready flag (1 ready, 0 not,
#hx("$FFFE") spectator).

#warn[Twelve 42-byte records plus the 95-byte header is 599 bytes — more
than the mailbox's 512-byte RX window. Up to nine player records fit; a
table with more spectators than that will fail the length gate and the
poll simply retries. Seats are capped at six, so play is never affected —
but know where the ceiling is.]

#sect("Turn machinery")

Your turn is a little two-mode machine (#co(1), Listing 10): *DICE* mode —
cursor over the ROLL tile and five dice, the action button toggles a die
between reroll (the default, wire #cd("1")) and keep (#cd("0")), ROLL
submits #cd("/roll/01100")-style masks; and *SCORE* mode — cursor over
the open categories, with your current roll's would-be score already
painted green in each open cell straight from #cd("validScores"). Out of
rolls, the client hops to SCORE mode by itself and parks the cursor on
the highest-scoring open category (#co(2)) — the same courtesy the C
clients extend. Submitting sends #cd("/score/11") with the *wire* index
(the display collapses the computed rows 6–7, so the cursor-to-index map
adds 2 past the upper section — #co(3)).

Two touches keep the multiplayer legible. Whenever the active player
changes, the viewed card snaps to them. And when *someone else's* turn
ends, the client diffs their scores against a shadow copy it refreshed on
every poll (#co(4)) to find which category they just filled, then holds
their card on screen for three-quarters of a second with that cell
highlighted — so a bot's instant move is still a visible event.

Rolls animate on *every* card, yours or not: a change in
#cd("rollsLeft") (or a turn change — that covers the server's automatic
opening roll) flickers the dice the wire's keepRoll says were thrown
(#co(5)).

#sect("The server")

Routes #cd("/state"), #cd("/ready"), #cd("/roll/:keep"),
#cd("/score/:index"), #cd("/leave"), #cd("/tables"), #cd("/view"),
with the familiar per-table locking. Timing: bots 3 s, humans 45 s — 15
for a player being penalized for a previous timeout, 250 when alone —
game-start countdowns of 31/6/3 seconds, and the same 4-second grace
baked into moveTime. Scoring — including the upper bonus at 63, the
Fujitzee bonus scores and the automatic totals — is entirely server-side:
the client never adds a die.

// ############################################################################
// CHAPTER 11 — THE LOBBY
// ############################################################################
#chapter("Chapter 11", "The Lobby", [
  How players find your table — and how a game remembers where it was.
])

The FujiNet Lobby (#cd("lobby.fujinet.online")) is the directory of every
live game room on every platform. The pieces:

- *Game servers upsert themselves.* Each server POSTs a JSON GameServer
  record — game name, region, server URL (with #cd("?table=") suffix per
  room), current and max players, plus a per-platform list of client
  download URLs — to the Lobby whenever a room's population changes, and
  game results when a match ends. A QA Lobby at
  #cd("qalobby.fujinet.online") receives the same traffic from
  development servers.
- *The Lobby client hands off through AppKeys.* When a player picks a
  room in the Lobby browser, the Lobby writes
  #cd("https://server/?table=id") into that game's registered AppKey slot
  (creator 1 / app 1 / key: 1 five-card-stud, 3 fujitzee, 5 battleship)
  and boots the game client.
- *The game rejoins on its own.* At boot each game reads its slot,
  splits the URL at the #cd("?") (#cd("split_room_url"), validating that
  the query really is #cd("table=") plus letters and digits — the value
  goes into rebuilt URLs unescaped), and if it parses, skips table select
  entirely. Picking a table by hand *writes* the same slot back, so a
  console reset rejoins your game; deliberately quitting *clears* it, so
  a reset lands on table select instead of dragging you back into a table
  you left.

The shared username slot (key 0) rounds out the handshake: every lobby
game on every platform reads and writes the same player name. Treat both
slots as hostile input — Chapters 8 through 10 all validate them
byte-by-byte, and so should you.

// ############################################################################
// APPENDIX A — ERROR CODES
// ############################################################################
#chapter("Appendix A", "Error Codes", none)

#sect("Mailbox link errors (FN_ERR, $9C0B)")

#wire(("value", "name", "meaning"),
  (mono7("0"), "OK", "transaction completed (or, after a timeout, never started)"),
  (mono7("1"), "ENOLINK", "no USB link to the ESP32 — check FN_LINK, wait, retry"),
  (mono7("2"), "ETIMEOUT", "the ESP32 did not answer within the deadline"),
  (mono7("3"), "EBADFRAME", "framing/checksum failure on the link"),
  (mono7("4"), "ETOOBIG", "request or reply exceeded the buffers"))

#sect("Network status errors (STATUS byte 3)")

#wire(("value", "name", "meaning"),
  (mono7("1"),   "SUCCESS", "all is well"),
  (mono7("128"), "WRITE ONLY", "channel not open for reading"),
  (mono7("131"), "READ ONLY / WRITE ONLY", "direction not open"),
  (mono7("132"), "INVALID COMMAND", ""),
  (mono7("135"), "READ ONLY", ""),
  (mono7("136"), "END OF FILE", ""),
  (mono7("138"), "GENERAL TIMEOUT", ""),
  (mono7("144"), "GENERAL ERROR", ""),
  (mono7("146"), "NOT IMPLEMENTED", ""),
  (mono7("151"), "FILE EXISTS", ""),
  (mono7("162"), "NO SPACE ON DEVICE", ""),
  (mono7("165"), "INVALID DEVICESPEC", "the URL did not parse"),
  (mono7("166"), "INVALID POINT", "bad SEEK"),
  (mono7("167"), "ACCESS DENIED", ""),
  (mono7("170"), "FILE NOT FOUND", ""),
  (mono7("200"), "CONNECTION REFUSED", ""),
  (mono7("201"), "NETWORK UNREACHABLE", ""),
  (mono7("202"), "SOCKET TIMEOUT", ""),
  (mono7("203"), "NETWORK DOWN", ""),
  (mono7("204"), "CONNECTION RESET", ""),
  (mono7("205"), "CONNECTION ALREADY IN PROGRESS", ""),
  (mono7("206"), "ADDRESS IN USE", ""),
  (mono7("207"), "NOT CONNECTED", "READ/WRITE with no OPEN"),
  (mono7("208"), "SERVER NOT RUNNING", ""),
  (mono7("209"), "NO CONNECTION WAITING", "TCP ACCEPT with no caller"),
  (mono7("210"), "SERVICE NOT AVAILABLE", ""),
  (mono7("211"), "CONNECTION ABORTED", ""),
  (mono7("212"), "INVALID USERNAME OR PASSWORD", ""),
  (mono7("213"), "COULD NOT PARSE JSON", ""),
  (mono7("214"), "CLIENT ERROR", "HTTP 4xx"),
  (mono7("215"), "SERVER ERROR", "HTTP 5xx"),
  (mono7("255"), "COULD NOT ALLOCATE BUFFERS", ""))

#sect("Network-boot errors (FN_BOOT_ERR, $9C1A)")

#wire(("value", "name", "meaning"),
  (mono7("1"), "REJECTED", "ROM header malformed (bad address range)"),
  (mono7("2"), "TRUNCATED", "Intellicart stream ended mid-segment"),
  (mono7("3"), "NOMAP", [no #cd(".cfg"), no header, and the size matches no known layout]),
  (mono7("4"), "MAILBOX", "a segment would overlap the mailbox window"),
  (mono7("5"), "CFGBAD", [a #cd(".cfg") arrived but held no mapping line]))

// ############################################################################
// APPENDIX B — QUICK REFERENCE
// ############################################################################
#chapter("Appendix B", "Quick Reference", none)

#sect("The transaction recipe")

+ Stage parameters: #cd("PARAM_SIZE[i]") = 1/2/4, value LE at #cd("PARAM_VAL + 4i")
+ Stage payload at #cd("TX"), length in #cd("TXLEN") (LE)
+ Write #cd("DEVICE"), #cd("CMD"), #cd("NPARAM")
+ #cd("SEQ") = #cd("ACKSEQ") + 1 (wrap, skip 0) — *last write*
+ Poll until #cd("ACKSEQ") = #cd("SEQ") (timeout ≈ 15 s)
+ #cd("REPLY_CMD") = #hx("$06")? Reply at #cd("RX"), length #cd("RXLEN") : else #cd("ERR")

#sect("Devices")

#wire(("id", "device", "notes"),
  (mono7("$70"), "Fuji control", "WiFi, hosts, mounts, AppKeys, encoders"),
  (mono7("$71-78"), "Network N1:–N8:", "one connection each"),
  (mono7("$45"), "Clock", "APETime command set"),
  (mono7("$31-38"), "Disk", "block devices (not used by the Inty client)"))

#sect("Network commands (dev $71–$78)")

#wire(("cmd", "name", "params / payload"),
  (mono7("$4F 'O'"), "OPEN",    "p0 mode, p1 translation; payload devicespec"),
  (mono7("$43 'C'"), "CLOSE",   "—"),
  (mono7("$52 'R'"), "READ",    "p0 length(2) → data"),
  (mono7("$57 'W'"), "WRITE",   "p0 length(2); payload data"),
  (mono7("$53 'S'"), "STATUS",  "p0 0, p1 type → 4 bytes: avail lo/hi, conn, err"),
  (mono7("$FC"),     "CHANNEL MODE", "p1: 0 raw, 1 JSON, 2 SGML"),
  (mono7("$50 'P'"), "PARSE",   "—"),
  (mono7("$51 'Q'"), "QUERY",   "payload query path"),
  (mono7("$4D 'M'"), "HTTP CHANNEL", "p1: 0 body, 1–3 headers, 4 POST data"),
  (mono7("$54 'T'"), "TRANSLATION", "p1 mode"),
  (mono7("$4C 'L'"), "SET EOL", "p0/p1 EOL bytes"),
  (mono7("$25 '%'"), "SEEK",    "p0 offset(4)"),
  (mono7("$26 '&'"), "TELL",    "→ 4-byte offset"),
  (mono7("$30 '0'"), "GETCWD",  "→ prefix"),
  (mono7("$2C ','"), "CHDIR",   "payload path"),
  (mono7("$FD"),     "USERNAME","payload"),
  (mono7("$FE"),     "PASSWORD","payload"),
  (mono7("$41 'A'"), "TCP ACCEPT", "—"),
  (mono7("$63 'c'"), "TCP CLOSE CLIENT", "—"),
  (mono7("$44 'D'"), "UDP DESTINATION", "payload host:port"),
  (mono7("$20/$21"), "RENAME / DELETE", "payload spec"),
  (mono7("$23/$24"), "LOCK / UNLOCK", "payload spec"),
  (mono7("$2A/$2B"), "MKDIR / RMDIR", "payload spec"))

#sect("Fuji commands (dev $70)")

#wire(("cmd", "name", "params / payload"),
  (mono7("$FF"), "RESET", "—"),
  (mono7("$FE"), "GET SSID", "→ 97 bytes"),
  (mono7("$FD"), "SCAN NETWORKS", "→ count"),
  (mono7("$FC"), "GET SCAN RESULT", "p0 index → 34 bytes"),
  (mono7("$FB"), "SET SSID", "p0 any; payload 97 bytes"),
  (mono7("$FA"), "GET WIFI STATUS", "→ 1 byte, 3 = connected"),
  (mono7("$F9"), "MOUNT HOST", "p0 slot"),
  (mono7("$F8"), "MOUNT IMAGE", "p0 slot, p1 flags — boots the ROM on Inty"),
  (mono7("$F7"), "OPEN DIRECTORY", "p0 slot; payload 256 bytes path+filter"),
  (mono7("$F6"), "READ DIR ENTRY", [p0 maxlen, p1 flags → name / #hx("$7F7F")]),
  (mono7("$F5"), "CLOSE DIRECTORY", "—"),
  (mono7("$F4"), "READ HOST SLOTS", "→ 256 bytes"),
  (mono7("$F3"), "WRITE HOST SLOTS", "payload 256 bytes"),
  (mono7("$F2/$F1"), "READ / WRITE DEVICE SLOTS", "304-byte table"),
  (mono7("$EA"), "GET WIFI ENABLED", "→ 1 byte"),
  (mono7("$E9"), "UNMOUNT IMAGE", "p0 slot"),
  (mono7("$E8"), "GET ADAPTERCONFIG", "→ 140 bytes"),
  (mono7("$E7"), "NEW DISK", "payload spec"),
  (mono7("$E5/$E4"), "GET / SET DIR POSITION", "p0 pos(2)"),
  (mono7("$E2"), "SET DEVICE FULLPATH", "p0 dev, p1 host, p2 mode; payload 256"),
  (mono7("$E1/$E0"), "SET / GET HOST PREFIX", "p0 slot"),
  (mono7("$DE"), "WRITE APPKEY", "payload value"),
  (mono7("$DD"), "READ APPKEY", "→ 2-byte length + value"),
  (mono7("$DC"), "OPEN APPKEY", "payload 6 bytes"),
  (mono7("$DB"), "CLOSE APPKEY", "—"),
  (mono7("$DA"), "GET DEVICE FULLPATH", "p0 slot → path"),
  (mono7("$D9"), "CONFIG BOOT", "p0 flag"),
  (mono7("$D8"), "COPY FILE", "p0 src, p1 dst; payload spec"),
  (mono7("$D7"), "MOUNT ALL", "—"),
  (mono7("$D6"), "SET BOOT MODE", "p0 mode"),
  (mono7("$D0-$C9"), "BASE64 ENC/DEC", "input / compute / length / output"),
  (mono7("$C8-$C2"), "HASH", "p0: algo 0 MD5, 1 SHA1, 2 SHA256, 3 SHA512"),
  (mono7("$C4"), "ADAPTERCONFIG EXTENDED", "→ 240 bytes"),
  (mono7("$BF-$BC"), "QR CODE", "input / encode / length / output"),
  (mono7("$BB"), "GENERATE GUID", "→ guid"),
  (mono7("$53"), "STATUS", "p0 1 = mount times"),
  (mono7("$00"), "DEVICE READY", "→ 512 test bytes"))

#sect("AppKey registry (creator 1, app 1)")

#wire(("key", "holder", "contents"),
  (mono7("0"), "all lobby games", "shared player name"),
  (mono7("1"), "5 Card Stud", "server?table= handoff"),
  (mono7("3"), "Fujitzee", "server?table= handoff"),
  (mono7("5"), "Battleship", "server?table= handoff"))

// ############################################################################
// APPENDIX C — LISTINGS
// ############################################################################
#chapter("Appendix C", "Program Listings", [
  The complete, building source of the library and all three games,
  line-numbered, with the call-outs the chapters reference. Each game also
  includes the community-standard #raw("constants.bas") (Mark Ball's, from
  the IntyBASIC distribution), not reprinted here.
])

#code-listing("fujinet.bas — the FujiNet library (Chapter 7)",
  "listings/fujinet.bas",
  callouts: ("19": 8, "91": 1, "120": 2, "125": 3, "136": 4,
             "225": 5, "296": 6, "356": 7))

#code-listing("5card.bas — 5 Card Stud client (Chapter 8)",
  "listings/5cardstud/5card.bas",
  callouts: ("320": 1, "365": 2, "158": 3, "407": 4, "549": 5,
             "638": 6, "887": 7, "590": 8))

#code-listing("state.bas — 5 Card Stud wire format",
  "listings/5cardstud/state.bas")

#code-listing("gfx.bas — 5 Card Stud card art",
  "listings/5cardstud/gfx.bas")

#code-listing("sound.bas — 5 Card Stud effects",
  "listings/5cardstud/sound.bas")

#code-listing("battleship.bas — Battleship client (Chapter 9)",
  "listings/battleship/battleship.bas",
  callouts: ("49": 2, "878": 4, "753": 5, "546": 6, "691": 7))

#code-listing("state.bas — Battleship wire format",
  "listings/battleship/state.bas",
  callouts: ("123": 3))

#code-listing("board.bas — the colored-squares kernel",
  "listings/battleship/board.bas",
  callouts: ("42": 1))

#code-listing("sound.bas — Battleship effects",
  "listings/battleship/sound.bas")

#code-listing("fujitzee.bas — Fujitzee client (Chapter 10)",
  "listings/fujitzee/fujitzee.bas",
  callouts: ("777": 1, "743": 2, "947": 3, "653": 4, "485": 5))

#code-listing("state.bas — Fujitzee wire format",
  "listings/fujitzee/state.bas")

#code-listing("dice.bas — Fujitzee dice",
  "listings/fujitzee/dice.bas")

#code-listing("card.bas — Fujitzee scorecard",
  "listings/fujitzee/card.bas")

#code-listing("sound.bas — Fujitzee effects",
  "listings/fujitzee/sound.bas")

// ############################################################################
// APPENDIX D — NETCAT
// ############################################################################
#chapter("Appendix D", "Netcat", [
  The traditional closing program of every FujiNet programmer's guide: a
  terminal. Type a line with the disc, #kcap("ENTER") sends it, and
  whatever comes back scrolls by. It compiles, assembles, and defaults to
  an echo server so it demonstrates itself.
])

#code-listing("netcat.bas — a line-mode network terminal",
  "listings/netcat.bas", size: 5.6pt)

#v(10pt)
#align(center, text(font: f-serif, style: "italic", size: 9pt,
  "Now go put an Intellivision on the Internet."))
