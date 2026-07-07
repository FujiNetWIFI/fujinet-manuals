// ============================================================
// PROGRAMMING THE FUJINET
// for the Atari 8-bit computers
//
// A programmer's guide and command reference for driving the
// FujiNet WiFi peripheral two ways: through the N: handler
// (NDEV) from Atari BASIC, and by talking to the SIO bus
// directly from 6502 assembly.
//
// Typeset in tribute to the Atari home-computer and technical
// manuals of 1980–1982 — Futura Extra Bold heads over black
// bands, Rockwell body, the genuine Atari ROM character set for
// screens, tumbling data cubes off the 1050 booklet. The visual
// language is the one established by the companion "Getting
// Started with FujiNet — Owner's Guide for the Atari 400/800."
//
// Every command byte, parameter and payload in this book is
// taken verbatim from the FujiNet sources — see the colophon.
//
// Build: typst compile --font-path fonts manual.typ
// ============================================================

// ---------- fonts ----------
#let f-head = "Futura"            // weight 700 = Futura Extra Bold (display)
#let f-sans = "Futura"            // weight 400 = Futura LT (labels, section heads)
#let f-body = "Rockwell Std"      // Light cut (weight 300) for body
#let f-mark = "Harry"             // Harry Fat — the ATARI-logo face
#let f-scrn = "EightBit Atari"    // the genuine Atari ROM character set (screens)
#let f-code = "DejaVu Sans Mono"  // program listings & register dumps

// ---------- palette ----------
#let ink = rgb("#221f1c")
#let cream = rgb("#f2eee3")        // warm interior stock
#let cover-gray = rgb("#c6c8c5")   // 800-guide cover gray
#let navy = rgb("#1d3060")         // inside-cover blue
#let toc-blue = rgb("#2b4fa3")     // contents entries
#let red = rgb("#003779")          // accent blue
#let code-bg = rgb("#e7e2d5")      // listing panel fill
#let chip-bg = rgb("#e7ddc2")      // inline-code fill
#let scr-bg = rgb("#1c2f96")       // GR.0 dark blue
#let scr-fg = rgb("#dfe4f5")       // GR.0 text luminance
#let cap-fill = rgb("#c9c6bd")
#let cap-line = rgb("#6b665e")
#let mx = 0.8in                    // page side margin (drives full-bleed bands)

// cube palette, straight off the 1050 booklet
#let cubes-c = (rgb("#d23b2e"), rgb("#e0457f"), rgb("#eda4c0"),
                rgb("#e8871f"), rgb("#edc522"), rgb("#3f9e58"),
                rgb("#7ec98c"), rgb("#3b76c0"), rgb("#27897a"),
                rgb("#7b52a8"))

// ============================================================
// SMALL HELPERS
// ============================================================
#let tm = super(text(size: 0.45em, tracking: 0pt)[TM])
#let rg = super(text(size: 0.45em, tracking: 0pt)[®])

// screen-font run from a string (strings survive "//" in URLs)
#let sf(s, size: 6.6pt) = text(font: f-scrn, size: size, s)

// inline code, from a string — safe for $ and // in prose
#let cw(s) = box(fill: chip-bg, outset: (y: 1.4pt), inset: (x: 1.7pt),
  text(font: f-code, size: 7.6pt, fill: ink, s))

// ============================================================
// HEADS
// ============================================================
#let secmark(title) = metadata((title: title))

// chapter heads: stacked Futura Extra Bold caps + full-bleed black band
#let headband(..lines, fg: ink, band: black) = {
  let ls = lines.pos()
  block(above: 0pt, below: 1.4em, width: 100%, {
    set par(leading: 0.22em, spacing: 0.22em, first-line-indent: 0pt)
    set text(font: f-head, weight: 700, size: 22pt, fill: fg, tracking: 0.4pt)
    for l in ls { par(upper(l)) }
    v(8pt)
    move(dx: -mx, rect(width: 8.5in, height: 11pt, fill: band))
  })
}

// section head: Futura LT caps over a red full-measure rule
#let sect(title) = block(above: 1.5em, below: 0.85em, breakable: false, sticky: true, {
  text(font: f-sans, weight: 400, size: 10pt, tracking: 0.5pt, fill: ink, upper(title))
  v(2pt)
  line(length: 100%, stroke: 2.4pt + red)
})

// light subhead
#let lsub(t) = block(above: 1.05em, below: 0.4em,
  text(font: f-sans, weight: 400, size: 9pt, tracking: 0.45pt, fill: ink, upper(t)))

// ============================================================
// LISTS, KEYS, STEPS
// ============================================================
#let bstep(n, body) = block(above: 0.7em, below: 0.7em,
  grid(columns: (0.3in, 1fr), column-gutter: 4pt,
    text(font: f-head, weight: 700, size: 15pt, fill: ink, baseline: 2pt, str(n)),
    body))

#let item(body) = block(above: 0.4em, below: 0.4em,
  grid(columns: (0.16in, 1fr), column-gutter: 3pt,
    move(dy: 2.2pt, square(size: 4.2pt, fill: ink)),
    par(leading: 0.5em, first-line-indent: 0pt, body)))

#let key(label) = box(baseline: 22%,
  rect(fill: cap-fill, stroke: 0.6pt + cap-line, radius: 1.6pt,
       inset: (x: 3.2pt, y: 2.2pt),
       text(font: f-sans, weight: 400, size: 5.8pt, fill: ink,
            tracking: 0.3pt, upper(label))))

// ============================================================
// SCREEN TRANSCRIPTS (genuine Atari ROM font, GR.0 blue box)
// ============================================================
#let iv(s) = box(fill: scr-fg, outset: (y: 0.6pt, x: 0.2pt), text(fill: scr-bg, s))
#let ivs(s) = iv(text(s))
#let screen(body, w: 3.6in) = block(breakable: false, above: 1.0em, below: 1.0em,
  box(width: w, fill: scr-bg, radius: 9pt, inset: (x: 14pt, y: 12pt), {
    set text(font: f-scrn, size: 5.9pt, fill: scr-fg)
    set par(leading: 3.0pt, spacing: 3.0pt, first-line-indent: 0pt)
    body
  }))

// COMPUTER: / YOU TYPE: dialogue rows
#let dsay(who, what) = grid(columns: (0.95in, 1fr), column-gutter: 7pt,
  align: (right + top, left + top),
  text(font: f-body, size: 7.8pt, fill: ink, upper(who) + ":"),
  { set text(font: f-scrn, size: 6.4pt, fill: ink)
    set par(leading: 3.6pt, first-line-indent: 0pt); what })
#let dialogue(..rows) = block(breakable: false, above: 0.85em, below: 0.85em,
  stack(spacing: 4.6pt, ..rows.pos().map(r => dsay(r.at(0), r.at(1)))))

// ============================================================
// CODE LISTINGS
// ============================================================
// full-width tinted panel with a red punch-card rule; breakable so
// long listings (the netcat, the handler) flow across pages.
#show raw.where(block: true): it => block(above: 1.0em, below: 1.1em, width: 100%,
  block(breakable: true, width: 100%, fill: code-bg, radius: 1.5pt,
    inset: (x: 10pt, top: 8pt, bottom: 9pt), stroke: (top: 1.6pt + red), {
      set text(font: f-code, size: 7.3pt, fill: ink)
      set par(leading: 0.42em, justify: false, first-line-indent: 0pt)
      it
    }))
#show raw.where(block: false): it => box(fill: chip-bg, outset: (y: 1.4pt),
  inset: (x: 1.7pt), text(font: f-code, size: 7.6pt, fill: ink, it))

#let lctr = counter("listing")
#let listing(title, body) = {
  lctr.step()
  block(breakable: true, above: 1.3em, below: 1.3em, {
    block(below: 0.4em, sticky: true, context {
      text(font: f-head, weight: 700, size: 8.5pt, fill: red,
           "LISTING " + lctr.display() + ".")
      h(5pt)
      text(font: f-sans, weight: 400, size: 8.5pt, tracking: 0.4pt, fill: ink, upper(title))
    })
    body
  })
}

// ============================================================
// COMMAND-REFERENCE COMPONENTS
// ============================================================
#let chip(s) = box(fill: red, inset: (x: 5pt, y: 2.2pt), radius: 2pt,
  text(font: f-head, weight: 700, size: 7.2pt, fill: cream, tracking: 0.3pt, s))

#let cmd(name, tag) = block(above: 1.5em, below: 0.55em, breakable: false, sticky: true, {
  grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
    text(font: f-head, weight: 700, size: 11pt, fill: ink, upper(name)),
    chip(tag))
  v(2.5pt)
  line(length: 100%, stroke: 0.9pt + ink)
})

// fielded table; column count inferred from the header row's arity.
// last column is body font (prose), the rest monospace.
#let mk-table(rows) = {
  set text(hyphenate: false)
  let ncol = rows.first().len()
  let cols = range(ncol - 1).map(_ => auto) + (1fr,)
  table(columns: cols, inset: (x: 6pt, y: 3.0pt), align: left + horizon, stroke: none,
    fill: (_, row) => if row == 0 { red } else if calc.odd(row) { code-bg } else { none },
    ..rows.enumerate().map(((i, r)) => {
      r.enumerate().map(((j, cell)) => {
        let st = if i == 0 { (font: f-head, weight: 700, size: 6.8pt, fill: cream) }
                 else if j == r.len() - 1 { (font: f-body, weight: 300, size: 8.2pt, fill: ink) }
                 else { (font: f-code, size: 7pt, fill: ink) }
        text(..st, cell)
      })
    }).flatten())
}
#let ptable(..rows) = block(above: 0.6em, below: 0.85em, mk-table(rows.pos()))

#let returns(body) = block(above: 0.35em, below: 0.7em, {
  text(font: f-head, weight: 700, size: 7.2pt, fill: red, "RETURNS  ")
  text(font: f-body, weight: 300, size: 9pt, body)
})

// ============================================================
// DATA CUBES (chapter dividers, off the 1050 booklet)
// ============================================================
#let cube(s, c, rot: 0deg) = rotate(rot, reflow: false, {
  let w = s; let h = s * 2.1; let dx = s * 0.62; let dy = s * 0.40
  let st = 0.85pt + black
  box(width: w + dx, height: h + dy, {
    place(polygon(fill: c.lighten(34%), stroke: st,
      (0pt + dx, 0pt), (w + dx, 0pt), (w, dy), (0pt, dy)))
    place(dy: dy, polygon(fill: c, stroke: st,
      (0pt, 0pt), (w, 0pt), (w, h), (0pt, h)))
    place(dx: w, polygon(fill: c.darken(26%), stroke: st,
      (dx, 0pt), (dx, h), (0pt, h + dy), (0pt, dy)))
  })
})
#let cubestream(pts, unit: 1pt) = {
  let w = calc.max(..pts.map(p => p.at(0) + p.at(2) * 2.2)) * unit
  let h = calc.max(..pts.map(p => p.at(1) + p.at(2) * 2.7)) * unit
  box(width: w, height: h, {
    for p in pts {
      place(dx: p.at(0) * unit, dy: p.at(1) * unit,
        cube(p.at(2) * unit, cubes-c.at(calc.rem(p.at(3), cubes-c.len())),
             rot: p.at(4) * 1deg))
    }
  })
}
#let divider = align(center, cubestream((
  (0, 10, 8, 7, -10), (30, 22, 7, 1, 14), (58, 6, 9, 4, -22),
  (90, 18, 7, 0, 8), (118, 2, 8, 5, -14), (148, 16, 7, 8, 18),
  (176, 4, 8, 2, -6), (206, 14, 9, 6, 12), (238, 2, 7, 3, -18),
  (266, 12, 8, 9, 6),
), unit: 1pt))

// ============================================================
// FOLIO
// ============================================================
#let folio = context {
  let p = counter(page).get().first()
  if p > 1 {
    let num = text(font: f-sans, size: 9.5pt, fill: ink, str(p))
    if calc.even(p) { place(bottom + left, dx: 10pt, dy: -14pt, num) }
    else { place(bottom + right, dx: -10pt, dy: -14pt, num) }
  }
}

// ============================================================
// DOCUMENT SETUP
// ============================================================
#set text(font: f-body, weight: 300, size: 9.5pt, fill: ink)
#set par(leading: 0.6em, spacing: 0.7em, justify: false, first-line-indent: 0pt)
#show emph: set text(weight: 400, style: "normal")   // no italic Rockwell cut
#show strong: set text(font: f-body, weight: 700)    // Rockwell Bold for *emphasis*
#set page(width: 8.5in, height: 11in,
  margin: (x: mx, top: 0.7in, bottom: 0.8in), fill: cream, background: folio)

// ============================================================
// FRONT COVER
// ============================================================
#page(margin: 0pt, fill: cover-gray, background: none)[
  #place(top + left, dx: 8.4in, dy: 0.3in,
    rotate(90deg, origin: top + left, reflow: false,
      text(font: f-mark, weight: 900, size: 116pt, tracking: 14pt, {
        let cols = (rgb("#7b3fa0"), rgb("#5b49ae"), rgb("#3b55b5"),
                    rgb("#2e6fbb"), rgb("#2e8eb0"), rgb("#36a37e"), rgb("#58b758"))
        for (i, ch) in "FUJINET".clusters().enumerate() { text(fill: cols.at(i), ch) }
      })))

  #place(top + left, dx: 0.55in, dy: 0.5in, {
    set par(leading: 0.14em, spacing: 0.14em, first-line-indent: 0pt)
    set text(font: f-head, weight: 700, size: 34pt, fill: black, tracking: 0.3pt)
    par[THE FUJINET#tm]
    par[WIFI NETWORK]
    par[PERIPHERAL]
  })

  // a listing card in place of a photo — a short high-road program in
  // the genuine Atari ROM font on the GR.0 blue screen, matching the
  // Apple II and ADAM programmer's guides.
  #place(top + left, dx: 1.05in, dy: 3.05in, context {
    let card = box(width: 5.55in, fill: scr-bg, radius: 12pt, inset: (x: 24pt, y: 22pt), {
      set text(font: f-scrn, size: 8.6pt, fill: scr-fg)
      set par(leading: 8pt, first-line-indent: 0pt)
      let lines = (
        "10 OPEN #1,4,0,",
        "   \"N:HTTP://FUJINET.ONLINE/\"",
        "20 STATUS #1,S",
        "30 BW=PEEK(746)+PEEK(747)*256",
        "40 IF BW=0 THEN 20",
        "50 INPUT #1,A$:PRINT A$",
        "60 GOTO 20",
        "",
        "70 REM THE WORLD, ONE OPEN",
        "   AT A TIME.",
      )
      lines.map(l => if l == "" { v(0.4em) } else { text(l) }).join(linebreak())
    })
    // drop shadow, sized to the card's actual height
    place(dx: 0.15in, dy: 0.17in, rect(width: 5.55in, height: measure(card).height,
      radius: 12pt, fill: rgb("#0000001f")))
    card
  })

  #place(top + left, dx: 0.55in, dy: 8.35in,
    text(font: f-sans, weight: 400, size: 40pt, tracking: 1.0pt, fill: ink)[PROGRAMMER'S GUIDE])
  #place(top + left, dx: 0.57in, dy: 9.35in,
    text(font: f-sans, weight: 400, size: 12.5pt, tracking: 1.6pt, fill: ink)[
      A TECHNICAL REFERENCE FOR THE ATARI#rg 8-BIT COMPUTERS])

  #place(bottom + left, dx: 0.55in, dy: -0.42in,
    stack(dir: ltr, spacing: 10pt,
      image("images/fujinet-logo.png", width: 1.5in),
      align(horizon, text(font: f-sans, size: 8pt, fill: ink)[A Worldwide Community Project])))
]

// inside front cover: navy
#page(margin: 0pt, fill: navy, background: none)[ #counter(page).update(0) ]

// ============================================================
// CONTENTS
// ============================================================
#{
  set par(first-line-indent: 0pt)
  block(above: 0pt, {
    set text(font: f-head, weight: 700, size: 26pt, fill: ink)
    [CONTENTS]
    v(8pt)
    move(dx: -mx, rect(width: 8.5in, height: 11pt, fill: black))
  })
  v(0.4in)
  align(center, box(width: 5.6in, {
    set align(left)
    context {
      let entries = query(metadata).filter(m =>
        type(m.value) == dictionary and "title" in m.value)
      for e in entries {
        let pg = counter(page).at(e.location()).first()
        block(above: 0pt, below: 7pt, {
          line(length: 100%, stroke: 0.8pt + ink)
          v(3pt)
          text(font: f-head, weight: 700, size: 11.5pt, fill: toc-blue,
               tracking: 0.3pt, upper(e.value.title))
          h(8pt)
          text(font: f-sans, size: 10.5pt, fill: ink, str(pg))
        })
      }
    }
  }))
  place(bottom + left, dy: -0.1in, box(width: 6.4in, {
    set text(size: 7.6pt)
    set par(leading: 0.46em)
    [FujiNet#tm is free, open-source hardware and software, built by enthusiasts for
     enthusiasts. This guide is the developer companion to #emph[Getting Started with
     FujiNet] and pays tribute to the Atari home-computer and technical manuals of
     1980--1982. ATARI#rg and the names of ATARI products are trademarks of their
     respective owners, used here in loving tribute. FujiNet is not affiliated with Atari.]
  }))
  pagebreak()
}

// ============================================================
// 1. TWO ROADS TO THE FUJINET
// ============================================================
#secmark("Two Roads to the FujiNet")
#headband("Two Roads to", "the FujiNet")

The FujiNet is, electrically, a little computer of its own — an ESP32 with WiFi, a
memory-card slot, and a cable that pretends to be an Atari peripheral. It plugs into
the SIO (serial) port like a disk drive, and inside it lives a cluster of *SIO devices*:
eight disk drives, a printer, a modem, a clock — and the two devices this book is about,
the *Network device* and the *Fuji control device*.

There are two heights at which an Atari program can reach them, and this guide teaches
both, side by side.

#lsub[The high road — the N: handler (NDEV)]
NDEV is a CIO device handler, letter *N*, that you load into memory once. From then on
the network is just another Atari device: you `OPEN #1,4,0,"N:HTTP://..."`, `INPUT` and
`PRINT` and `GET` and `PUT`, and `CLOSE`, exactly as you would to `D:` or `E:` or the
printer. Any language that speaks CIO speaks to the FujiNet — Atari BASIC, the
Assembler/Editor cartridge, Atari Logo. *All of the BASIC examples in this book take the
high road.*

#lsub[The low road — the SIO bus itself]
Underneath NDEV, and underneath CIO, is the Serial Input/Output bus. You fill a
*Device Control Block* at #cw("$0300"), call the OS `SIOV` vector at #cw("$E459"), and
the command travels the wire to the FujiNet. This is how you reach the *whole* FujiNet
— including the Fuji control device, which NDEV does not expose at all. *All of the
assembly examples in this book take the low road.*

#lsub[When to use which]
Take the high road for ordinary network I/O from a high-level language: fetching a URL,
reading a socket, writing a file. Take the low road when you need speed, when NDEV is
not present (or cannot be — see the next chapter), or when you must reach a command NDEV
cannot: mounting disks, scanning WiFi, reading the clock, the app-key store. A real
program often takes both — NDEV for the socket, direct SIO for the mount.

#sect("The devices on the bus")
Each FujiNet function answers to its own *device id* on the SIO bus. You will meet three:

#ptable(
  ("Device", "Bus id", "Reached by", "What it is"),
  ("Network", "$71–$78", "NDEV or SIO", "N1: through N8: — TCP, UDP, HTTP, TNFS, FTP, SMB, SSH, TELNET"),
  ("Fuji control", "$70", "SIO only", "the device CONFIG talks to: mounts, hosts, slots, WiFi, clock, app keys"),
  ("Clock (APETime)", "$45", "SIO only", "time of day in several formats"),
)

The Network device is really *eight* devices, one per channel: `N1:` is bus id
#cw("$71"), `N2:` is #cw("$72"), and so on up to `N8:` at #cw("$78"). The Atari OS builds
the on-wire id for you from the two DCB bytes `DDEVIC` and `DUNIT` — it sends
#cw("DDEVIC + DUNIT - 1") — so you set `DDEVIC` to #cw("$71") and `DUNIT` to the channel
number, and the OS does the arithmetic. NDEV does exactly this.

#divider
#pagebreak()

// ============================================================
// 2. GETTING THE N: HANDLER
// ============================================================
#secmark("Getting the N: Handler")
#headband("Getting the", "N: Handler")

The N: handler is not built into the FujiNet firmware or the Atari ROM — it is a small
relocatable driver, *NDEV*, that you load into your Atari's memory. It ships as an
executable named `AUTORUN.SYS` (or `NDEV.COM`), about a kilobyte long, that installs the
`N:` device into the handler table (HATABS) and steps out of the way. Once loaded it
serves `N1:` through `N8:` until the next cold start.

#sect("Three places to get it")

#lsub[1 · The ready-made handler disk]
The simplest source is the handler disk image, kept on the public server
#sf("apps.irata.online"):
#block(inset: (left: 0.3in), cw("https://apps.irata.online/Atari_8-bit/n-handler.atr"))
#sf("apps.irata.online") is directly reachable from a FujiNet *both* over HTTPS and over
TNFS — add it as a host slot in CONFIG (just the bare name #sf("apps.irata.online")) and
you can mount #sf("n-handler.atr") straight off it, no download to a PC required.

#lsub[2 · Any of the DOS disks]
Every DOS image in the collection at
#block(inset: (left: 0.3in), cw("https://apps.irata.online/Atari_8-bit/DOS/"))
already carries the handler as its `AUTORUN.SYS`, so booting any one of them installs
`N:` automatically. This is the usual way: boot a FujiNet-aware DOS, and the network is
simply there.

#lsub[3 · Build it from source]
The handler is open source. Its repository is
#block(inset: (left: 0.3in), cw("https://github.com/FujiNetWIFI/fujinet-nhandler"))
with the Atari handler under the `handler/` directory. It is written for the MADS
assembler and post-processed into a *relocatable* executable (see the repository's
`README` for the RELGEN dance, and Appendix C for the complete listing). Building it
yourself is the way to change how it behaves — a longer receive buffer, a different
interrupt policy, or one of the missing commands catalogued in Chapter 9.

#sect("Loading it")
NDEV loads like any DOS executable. Booted as `AUTORUN.SYS` it installs at power-on and
prints a one-line FujiNet banner. Loaded by hand from DOS (the `L` "binary load" menu
item, or from BASIC-adjacent loaders) it installs the moment it finishes loading. Because
it relocates itself to the top of free memory and lifts `MEMLO` above itself, it coexists
with whatever you load next.

#block(breakable: false, {
  box(width: 100%, fill: rgb("#efe7cf"), stroke: (left: 3pt + red),
    inset: (x: 12pt, y: 9pt), radius: 1pt, {
    text(font: f-head, weight: 700, size: 9pt, fill: red)[IMPORTANT — DUP AND ATARI DOS 2]
    v(4pt)
    set text(size: 9pt)
    [NDEV *cannot be used from the DUP menu of Atari DOS 2.0S, 2.0D, or 2.5.* When you
     return to DOS and its menu processor (DUP.SYS) loads, DUP inevitably overwrites the
     very region of memory NDEV relocated itself into — because NDEV lives just above
     `MEMLO`, and DUP claims that same space for its buffers. The handler is clobbered,
     and `N:` stops answering.

     This is a limitation of where DOS 2's DUP lives, not of the handler. Use `N:` from a
     running program (BASIC, an assembled binary, a language cartridge) rather than from
     the DOS menu; or use a DOS whose command processor leaves the handler alone (SpartaDOS,
     MyDOS, and others reload cleanly). From #emph[within] a program the handler is solid —
     it is only the DUP menu itself that steps on it.]
  })
})

#divider
#pagebreak()

// ============================================================
// 3. THE N: DEVICE FROM BASIC
// ============================================================
#secmark("The N: Device from BASIC")
#headband("The N: Device", "from BASIC")

With NDEV loaded, the network is an Atari device. Everything you already know about
`OPEN`, `CLOSE`, `INPUT`, `PRINT`, `GET`, `PUT` and `STATUS` applies unchanged. This
chapter is the whole of ordinary network I/O from Atari BASIC.

#sect("The device spec")
What you open is a *device spec*: the device name, then a scheme, then the resource.
#block(inset: (left: 0.3in), cw("Nx:SCHEME://host[:port]/path"))
`x` is the channel, `1` through `8` (a bare `N:` means `N1:`). The scheme is one of
#cw("TCP"), #cw("UDP"), #cw("HTTP"), #cw("HTTPS"), #cw("TNFS"), #cw("FTP"), #cw("SMB"),
#cw("SSH"), #cw("TELNET"), in upper case. The rest names the host and resource, e.g.
#cw("N:HTTP://fujinet.online/") or #cw("N1:TCP://192.168.1.5:9000/").

#sect("OPEN — mode and translation")
`OPEN #ch,aux1,aux2,"Nx:..."` hands NDEV two bytes. *aux1* is the access mode; *aux2* is
the end-of-line translation.

#grid(columns: (1fr, 1fr), column-gutter: 0.3in,
  ptable(
    ("aux1", "Mode"),
    ("4", "read (GET)"),
    ("6", "directory read"),
    ("8", "write (PUT)"),
    ("9", "append"),
    ("12", "read / write"),
    ("13", "HTTP POST"),
    ("5", "HTTP DELETE"),
  ),
  ptable(
    ("aux2", "Line endings"),
    ("0", "none — binary"),
    ("1", "CR"),
    ("2", "LF"),
    ("3", "CR / LF"),
  ),
)

Translation converts between the Atari's end-of-line (`$9B`, EOL) and the wider world's
CR/LF as bytes cross the wire — indispensable for text protocols, switched off (`0`) for
binary. For most reading and writing of Internet text, open with translation `2` (LF).

#listing("Fetch a URL and print it")[
```basic
10 REM --- FETCH A WEB PAGE OVER N: ---
20 DIM L$(255)
30 OPEN #1,4,2,"N:HTTP://fujinet.online/"
40 REM  AUX1=4 READ, AUX2=2 LF TRANSLATION
50 STATUS #1,S
60 IF S<>1 THEN GOTO 200
70 BW=PEEK(746)+PEEK(747)*256:REM BYTES WAITING
80 IF BW=0 THEN GOTO 50
90 INPUT #1,L$
100 PRINT L$
110 GOTO 50
200 REM  S=136 IS END OF FILE, THE NORMAL FINISH
210 CLOSE #1
220 END
```
]

#sect("Reading — INPUT, GET, and STATUS")
`INPUT #ch,A$` reads one *record* — bytes up to and including an EOL. `GET #ch,B` reads
a single byte into a numeric variable. NDEV keeps a receive buffer that fills as data
arrives from the network; a read drains it.

Before you read, ask how much is waiting. `STATUS #ch,S` runs the handler's status entry,
which asks the FujiNet and fills the four-byte OS status buffer *DVSTAT* at #cw("$02EA")
(decimal 746):

#ptable(
  ("PEEK", "Address", "Meaning"),
  ("PEEK(746)+PEEK(747)*256", "$02EA/EB", "bytes waiting to be read"),
  ("PEEK(748)", "$02EC", "connection: 1 = up, 0 = closed by far end"),
  ("PEEK(749)", "$02ED", "device error (1 = OK, 136 = end of file)"),
)

The value `S` that `STATUS` returns is the handler status; when it is `136` the resource
is fully read (end of file) and it is time to `CLOSE`. Watch bytes-waiting to know when a
socket has data, and the connection byte to know when the far end has hung up.

#lsub[The PROCEED interrupt]
NDEV does not busy-wait for the network. It arms the SIO *PROCEED* interrupt (vector
`VPRCED` at #cw("$0202")); the FujiNet pulses the line when data arrives or the connection
changes, and the handler notes it. From BASIC you need not touch any of this — `GET` and
`STATUS` ride on it — but it is why a `GET` on an idle socket blocks politely instead of
spinning.

#sect("Writing — PRINT and PUT")
`PRINT #ch;A$` writes a string and appends an EOL; `PRINT #ch;A$;` (trailing semicolon)
writes without one; `PUT #ch,B` writes one byte. NDEV *buffers* what you write into a
128-byte transmit buffer and sends it in bunches — you will meet that buffer, and the
command that flushes it early, in the next chapter.

#listing("Post to a TCP service")[
```basic
10 REM --- OPEN A TCP SOCKET, TALK, LISTEN ---
20 DIM M$(100),R$(255)
30 OPEN #1,12,0,"N1:TCP://192.168.1.5:9000/"
40 M$="HELLO FROM THE ATARI"
50 PRINT #1;M$:REM  SENDS M$ + EOL
60 REM  --- NOW READ THE REPLY ---
70 STATUS #1,S:BW=PEEK(746)+PEEK(747)*256
80 IF BW=0 AND PEEK(748)=1 THEN GOTO 70
90 IF BW=0 THEN GOTO 200
100 INPUT #1,R$:PRINT R$:GOTO 70
200 CLOSE #1
```
]

#sect("Closing")
`CLOSE #ch` tears down the connection. NDEV first *flushes* anything still in the transmit
buffer, then tells the FujiNet to close the protocol. Always close a channel you opened —
the handler keeps only eight, one per unit, and a stranded socket ties one up until the
next cold start (or a `CLR`/`END`, which BASIC turns into closes).

#divider
#pagebreak()

// ============================================================
// 4. THE XIO COMMANDS
// ============================================================
#secmark("The XIO Commands (NDEV)")
#headband("The XIO", "Commands")

`OPEN`, `INPUT`, `PRINT`, `GET`, `PUT`, `STATUS` and `CLOSE` cover reading and writing.
Everything *else* the Network device can do — make a directory, delete a file, parse
JSON, set a password, flush the buffer — is a CIO *special* command, issued from BASIC
with `XIO`.

#sect("How XIO reaches NDEV")
`XIO cmd,#ch,aux1,aux2,"Nx:..."` sends command number *cmd* to the handler. CIO routes any
command of 14 or more to the handler's *special* entry, and NDEV does something clever
with it:

#bstep(1)[If *cmd* is *15*, NDEV handles it itself — the put-buffer flush, below. It never
  reaches the wire.]
#bstep(2)[Otherwise NDEV *asks the FujiNet* what that command expects: does it send data,
  receive data, or neither? (It does this with a one-byte inquiry.) If the FujiNet answers
  "I don't know that command," NDEV returns *error 146*, unimplemented.]
#bstep(3)[If the command is known, NDEV issues it — using the *command number itself as the
  SIO command byte* — passing your `aux1`/`aux2` through, and the device-spec string as a
  256-byte payload when the command sends data.]

The consequence worth remembering: *the XIO command number equals the SIO command byte.*
`XIO 42` sends SIO command #cw("$2A") — which is #cw("*"), make-directory. You can read
the whole table below as ATASCII if you like.

#sect("XIO 15 — flush the put buffer")
#cmd("Flush transmit buffer", "N: — XIO 15")
NDEV collects your `PUT`s and `PRINT`s in a 128-byte transmit buffer and sends them only
when the buffer fills, when an EOL (`$9B`) goes by, or when the channel closes. *XIO 15
sends whatever is buffered right now* — before the buffer is full and before any EOL.
This is implemented *inside NDEV itself;* no other special command is.

Reach for it whenever you must get bytes out immediately: a protocol that has no line
endings, a prompt you must send without a newline, an interactive exchange where the far
end is waiting on your half of a line.

#returns[`1` always — the flush cannot fail. On the open write channel only.]
#listing("Send a partial line, then flush")[
```basic
10 OPEN #1,12,0,"N1:TCP://10.0.0.9:23/"
20 REM  SEND A PROMPT WITH NO NEWLINE...
30 PRINT #1;"LOGIN: ";
40 REM  ...AND PUSH IT OUT NOW:
50 XIO 15,#1,0,0,"N:"
60 REM  THE FAR END SEES "LOGIN: " IMMEDIATELY
```
]

#sect("The complete XIO command set")
Every special command NDEV can reach is listed here. *cmd* is the number you give `XIO`
(and the SIO command byte, in hex). Where a command sends a string, put it in the `XIO`
filespec; where it takes numbers, pass them in `aux1`/`aux2`. Filesystem commands may be
issued on any free IOCB (the device spec carries the target); connection commands
(*parse, query, translation, channel mode, close-client, accept, flush*) act on an
already-`OPEN` channel.

#ptable(
  ("XIO", "SIO", "Char", "Command — what it does"),
  ("15", "—", "—", "flush the transmit buffer now (handled inside NDEV)"),
  ("32", "$20", " ", "rename a file; filespec is \"Nx:from,to\""),
  ("33", "$21", "!", "delete a file"),
  ("35", "$23", "#", "lock a file (make it read-only)"),
  ("36", "$24", "$", "unlock a file"),
  ("42", "$2A", "*", "make a directory"),
  ("43", "$2B", "+", "remove a directory"),
  ("44", "$2C", ",", "change directory (set the channel's path prefix)"),
  ("48", "$30", "0", "get current directory (reads the prefix back)"),
  ("65", "$41", "A", "TCP: accept a waiting client on a listening channel"),
  ("68", "$44", "D", "UDP: set the destination \"host:port\" for writes"),
  ("80", "$50", "P", "JSON: parse the document just read"),
  ("81", "$51", "Q", "JSON: set a query path; the value becomes readable"),
  ("84", "$54", "T", "set the translation mode (aux2 = 0/1/2/3)"),
  ("90", "$5A", "Z", "set the interrupt/status poll rate (aux1/aux2)"),
  ("99", "$63", "c", "TCP: close the current client, keep listening"),
  ("251", "$FB", "—", "set a JSON parameter (aux1 selects which)"),
  ("252", "$FC", "—", "set channel mode (aux2: 0 = protocol, 1 = JSON)"),
  ("253", "$FD", "—", "set the username (for FTP, SMB) — filespec is the name"),
  ("254", "$FE", "—", "set the password — filespec is the password"),
)

#sect("Working with files")
The filesystem commands each take a device spec naming the target, on any free IOCB.

#listing("Directory housekeeping over TNFS")[
```basic
10 REM  MAKE, RENAME, DELETE ON A TNFS HOST
20 XIO 42,#6,0,0,"N:TNFS://192.168.1.10/SAVES"
30 REM  ^ MAKE DIRECTORY /SAVES
40 XIO 32,#6,0,0,"N:TNFS://192.168.1.10/A.DAT,B.DAT"
50 REM  ^ RENAME A.DAT TO B.DAT (COMMA SEPARATES)
60 XIO 33,#6,0,0,"N:TNFS://192.168.1.10/B.DAT"
70 REM  ^ DELETE B.DAT
80 XIO 43,#6,0,0,"N:TNFS://192.168.1.10/SAVES"
90 REM  ^ REMOVE DIRECTORY /SAVES
```
]

#sect("Setting credentials")
For FTP and SMB, set the username and password *before* you `OPEN` the resource.

#listing("Log in to an FTP host")[
```basic
10 XIO 253,#1,0,0,"N1:anonymous"
20 XIO 254,#1,0,0,"N1:guest@example.com"
30 OPEN #1,4,2,"N1:FTP://ftp.example.com/readme.txt"
```
]

#sect("Reading JSON")
FujiNet can pick a single value out of a JSON document for you, so a BASIC program need
never parse braces. Suppose the resource at #cw("status.json") returns this document:

#listing("The JSON document returned by status.json")[
```json
{
  "status": {
    "code": 200,
    "message": "All systems go"
  },
  "hosts": ["fujinet.online", "irata.online"]
}
```
]

Open the resource, switch the channel into JSON mode, parse it, set a JSONPath, and read
the value with an ordinary `INPUT`:

#listing("Pull one field out of a JSON reply")[
```basic
10 DIM V$(255)
20 OPEN #1,4,0,"N:HTTPS://api.example.com/status.json"
30 XIO 252,#1,0,1,"N:":REM  CHANNEL MODE = JSON
40 XIO 80,#1,0,0,"N:":REM   PARSE THE DOCUMENT
50 XIO 81,#1,0,0,"N:/status/message":REM  QUERY PATH
60 INPUT #1,V$:REM  THE VALUE OF /status/message
70 PRINT V$:REM   PRINTS: ALL SYSTEMS GO
80 CLOSE #1
```
]
The path after the colon is a JSONPath-style selector: object members are names, array
indices are numbers. Against the document above, `/status/message` selects the string
`All systems go`; `/hosts/0` would select `fujinet.online`, and `/status/code` the number
`200`. After `XIO 81` the value is waiting in the channel — read it as text with `INPUT`,
or byte-by-byte with `GET`.

#sect("TCP servers and UDP")
A listening TCP channel accepts clients with `XIO 65` and drops the current one with
`XIO 99`. A UDP channel aims its writes with `XIO 68`.

#listing("Answer a TCP client; aim a UDP datagram")[
```basic
10 REM  --- LISTEN AND ACCEPT (TCP SERVER) ---
20 OPEN #1,12,0,"N1:TCP://:9000/":REM  NO HOST = LISTEN
30 XIO 65,#1,0,0,"N:":REM  ACCEPT A WAITING CLIENT
40 REM  ...CONVERSE ON #1...  XIO 99 DROPS THE CLIENT
50 REM
60 REM  --- AIM A UDP DATAGRAM ---
70 OPEN #2,12,0,"N2:UDP://:5000/"
80 XIO 68,#2,0,0,"N2:192.168.1.50:5001"
90 PRINT #2;"PING":REM  GOES TO 192.168.1.50:5001
```
]

#divider
#pagebreak()

// ============================================================
// 5. TALKING TO SIO DIRECTLY
// ============================================================
#secmark("Talking to SIO Directly")
#headband("Talking to", "SIO Directly")

Below NDEV, below CIO, is the bus itself. Every FujiNet command in the two chapters that
follow is, underneath, a *SIO transaction:* you fill a Device Control Block and call the
OS. This chapter is the one primitive the rest of the low road is built on.

#sect("The Device Control Block")
The DCB is twelve bytes of page three, from #cw("$0300"). You fill it in, call `SIOV`, and
read the result back out of `DSTATS`.

#ptable(
  ("Addr", "Name", "Holds"),
  ("$0300", "DDEVIC", "device id — $71 network, $70 Fuji, $45 clock"),
  ("$0301", "DUNIT", "unit — the channel; the OS sends DDEVIC+DUNIT-1 on the wire"),
  ("$0302", "DCOMND", "command byte"),
  ("$0303", "DSTATS", "before: data direction; after: the result code"),
  ("$0304", "DBUFLO/HI", "buffer address (payload in or out)"),
  ("$0306", "DTIMLO", "timeout, in seconds — $1F (31) is ample"),
  ("$0308", "DBYTLO/HI", "byte count of the payload"),
  ("$030A", "DAUX1/2", "the two auxiliary bytes"),
)

*DSTATS*, going in, tells SIO which way the data flows:

#ptable(
  ("Value", "Direction"),
  ("$80", "Atari → FujiNet — the payload at DBUF is sent"),
  ("$40", "FujiNet → Atari — the reply is read into DBUF"),
  ("$00", "no payload — command and aux bytes only"),
)

Coming back out, `DSTATS` is the result. `1` is success; the OS reports timeouts and bus
trouble with the codes below. *The FujiNet's own errors do not appear here* — a value of
`144` means "the device signalled an error," and you must then issue a `STATUS` command
and read the extended error out of the status reply (Chapter 6).

#ptable(
  ("DSTATS", "Meaning"),
  ("1", "success"),
  ("138", "device timed out — no answer on the bus"),
  ("139", "device NAK — the FujiNet refused the frame"),
  ("143", "bad frame — checksum mismatch"),
  ("144", "device error — issue STATUS for the real cause"),
)

#sect("The command frame, and what SIO does with it")
When you call `SIOV`, the OS builds a five-byte *command frame* — device id, command,
`aux1`, `aux2`, checksum — and clocks it out. The FujiNet answers each stage with a single
byte: *ACK* (`$41`, #cw("'A'")) or *NAK* (`$4E`, #cw("'N'")) for the frame, then, after the
work is done, *COMPLETE* (`$43`, #cw("'C'")) or *ERROR* (`$45`, #cw("'E'")). Payload bytes
flow in whichever direction `DSTATS` asked, guarded by their own checksum. You never see
these bytes yourself — the OS folds them into the `DSTATS` result — but knowing the shape
of the handshake explains every value the bus can return.

#sect("A reusable SIO call")
Rather than poke twelve addresses at every command, keep the DCB body as a template and
copy it in. This is exactly what NDEV does internally; here it is in the small, in 6502
that assembles under `ca65` or MADS.

#listing("SIOCALL — copy a template to the DCB and go")[
```asm
DDEVIC  = $0300         ; the Device Control Block
SIOV    = $E459         ; OS serial-I/O entry
DVSTAT  = $02EA         ; 4-byte status buffer

; ----------------------------------------------------------
; SIOCALL: A/Y point at a 12-byte DCB template.
;   copies it into the real DCB at $0300, calls SIOV,
;   returns the result code in A (and in DSTATS/$0303).
; ----------------------------------------------------------
SIOCALL stx  tmpx+1        ; (save nothing; X is free here)
        sta  src+1
        sty  src+2
        ldy  #11           ; 12 bytes: $0300..$030B
copy    lda  $FFFF,y       ; src, patched just above
src     = copy+1
        sta  DDEVIC,y
        dey
        bpl  copy
        jsr  SIOV          ; do it
        lda  $0303         ; DSTATS -> A
tmpx    ldx  #0
        rts
```
]

The template is the twelve DCB bytes laid out in order. Here is the one that reads the
network device's status — you will reuse the shape for every command that follows.

#listing("A DCB template: Network STATUS on N1:")[
```asm
; DDEVIC DUNIT DCOMND DSTATS  DBUF     DTIM RES  DBYT   DAUX
STATCB  .byte $71          ; DDEVIC : network device
        .byte $01          ; DUNIT  : channel 1  (wire id $71)
        .byte $53          ; DCOMND : 'S' status
        .byte $40          ; DSTATS : FujiNet -> Atari
        .word DVSTAT       ; DBUF   : into the status buffer
        .byte $1F          ; DTIMLO : 31 seconds
        .byte $00          ; (reserved)
        .word 4            ; DBYT   : four bytes come back
        .byte $00,$00      ; DAUX1, DAUX2

;  lda #<STATCB : ldy #>STATCB : jsr SIOCALL
;  DVSTAT+0/+1 = bytes waiting, +2 = connected, +3 = error
```
]

Everything the low road does is that pattern: name a device in `DDEVIC`/`DUNIT`, a command
in `DCOMND`, a direction and a buffer, and go. The two chapters that follow give the
command byte, the parameters, and a worked example for every command the FujiNet knows.

#divider
#pagebreak()

// ============================================================
// 6. THE NETWORK DEVICE — SIO REFERENCE
// ============================================================
#secmark("The Network Device — SIO Reference")
#headband("The Network Device", "SIO Reference")

The Network device answers at bus id #cw("$71") for `N1:` through #cw("$78") for `N8:` —
set `DDEVIC` to #cw("$71") and `DUNIT` to the channel. Its commands are the same bytes
NDEV sends; the difference is only that here *you* fill the DCB. Each entry gives the
command byte, its direction and parameters, and what it returns.

#cmd("Open", "N: — SIO $4F 'O'")
Instantiate the protocol and connect. Direction #cw("$80") (send). `DAUX1` is the access
mode, `DAUX2` the translation mode (the same values as BASIC `OPEN`; see Chapter 3). The
payload is the device-spec string, padded to 256 bytes; NDEV sends a full page.
#ptable(
  ("Field", "Value"),
  ("DCOMND", "$4F"),
  ("DSTATS", "$80  (Atari → FujiNet)"),
  ("DBYT", "256  (the padded device spec)"),
  ("DAUX1", "access mode — 4 read, 8 write, 12 read/write, 13 POST, 5 DELETE"),
  ("DAUX2", "translation — 0 none, 1 CR, 2 LF, 3 CR/LF"),
)
#returns[`DSTATS` = 1 on success. On `144`, the connection failed — read the extended error
with `STATUS`.]

#cmd("Close", "N: — SIO $43 'C'")
Tear the connection down. No payload. Direction #cw("$00"), `DBYT` 0.
#returns[`DSTATS` = 1. Always close what you opened.]

#cmd("Read", "N: — SIO $52 'R'")
Receive up to `DAUX1`/`DAUX2` (a 16-bit count, low in `DAUX1`) bytes into `DBUF`. Direction
#cw("$40"). *Ask `STATUS` first* and never request more than is waiting, nor more than a
single frame carries.
#ptable(
  ("Field", "Value"),
  ("DCOMND", "$52"),
  ("DSTATS", "$40  (FujiNet → Atari)"),
  ("DBYT", "the byte count you are reading"),
  ("DAUX1/2", "the same count, low byte / high byte"),
)
#returns[the bytes in `DBUF`; `DSTATS` = 1, or an error if the read fell short.]

#cmd("Write", "N: — SIO $57 'W'")
Send `DAUX1`/`DAUX2` bytes from `DBUF`. Direction #cw("$80").
#ptable(
  ("Field", "Value"),
  ("DCOMND", "$57"),
  ("DSTATS", "$80  (Atari → FujiNet)"),
  ("DBYT", "the byte count you are writing"),
  ("DAUX1/2", "the same count, low / high"),
)
#returns[`DSTATS` = 1 when the bytes were accepted.]

#cmd("Status", "N: — SIO $53 'S'")
Read the four-byte channel status into `DBUF` (point it at `DVSTAT`, #cw("$02EA")).
#ptable(
  ("Byte", "Meaning"),
  ("0–1", "bytes waiting to be read (low / high)"),
  ("2", "connection: 1 = up, 0 = closed by the far end"),
  ("3", "device error — 1 = OK, 136 = end of file, else a code from Appendix A"),
)
#returns[the four bytes; poll this between reads to pace a socket.]

#listing("HTTP GET, the low road")[
```asm
; open N1:HTTP://.../ for read, drain it to the screen.
; assumes SIOCALL from Chapter 5, and COUT at $F6A4 (E: put)

GET     lda #<OPENCB : ldy #>OPENCB : jsr SIOCALL
        bmi  GERR              ; DSTATS bit 7 set = trouble
LOOP    lda #<STATCB : ldy #>STATCB : jsr SIOCALL
        lda  DVSTAT+3          ; device error
        cmp  #136              ; end of file?
        beq  GDONE
        lda  DVSTAT            ; bytes waiting (low)
        ora  DVSTAT+1          ; (high)
        beq  LOOP              ; nothing yet — poll again
        ; set READ length = min(bytes waiting, 128) -- omitted
        lda #<READCB : ldy #>READCB : jsr SIOCALL
        ; ... emit DBUF for the byte count via COUT ...
        jmp  LOOP
GDONE   lda #<CLOSCB : ldy #>CLOSCB : jsr SIOCALL
GERR    rts

OPENCB  .byte $71,$01,$4F,$80    ; N1: OPEN, send
        .word SPEC              ; device spec buffer
        .byte $1F,$00
        .word 256               ; a full page
        .byte $04,$02           ; mode 4 (read), trans 2 (LF)
SPEC    .byte "N1:HTTP://fujinet.online/",$9B
        .res  256               ; padded out to a page
```
]

#sect("Filesystem commands")
Each names its target in the device-spec payload (direction #cw("$80")), just as the XIO
forms do. The command bytes are the ATASCII characters in the table.

#ptable(
  ("Cmd", "Char", "Operation", "Payload is"),
  ("$21", "!", "delete a file", "the device spec"),
  ("$20", " ", "rename a file", "spec \"Nx:from,to\""),
  ("$23", "#", "lock (read-only)", "the device spec"),
  ("$24", "$", "unlock", "the device spec"),
  ("$2A", "*", "make directory", "the device spec"),
  ("$2B", "+", "remove directory", "the device spec"),
  ("$2C", ",", "change directory", "the new prefix"),
  ("$30", "0", "get current dir", "read the prefix into DBUF (direction $40)"),
)

#sect("JSON, credentials, and channel mode")

#cmd("Set channel mode", "N: — SIO $FC")
`DAUX2` = 0 for the ordinary protocol channel, 1 for JSON. No payload.

#cmd("Parse JSON", "N: — SIO $50 'P'")
Parse the document just read on the channel. No payload. Follow with a query.

#cmd("Query JSON", "N: — SIO $51 'Q'")
Send a JSONPath string (direction #cw("$80")); the selected value becomes available to
`READ`. `DAUX2` sets the value's translation (0/1/2).

#cmd("Username / Password", "N: — SIO $FD / $FE")
Send the credential string (direction #cw("$80")) *before* `OPEN`. `$FD` sets the username,
`$FE` the password — for FTP and SMB.

#cmd("Translation", "N: — SIO $54 'T'")
Set the channel's end-of-line translation from `DAUX2` (0/1/2/3). No payload. Applies to
subsequent opens on the channel.

#cmd("Set interrupt rate", "N: — SIO $5A 'Z'")
Set how often the FujiNet raises the PROCEED interrupt to offer new status, as a 16-bit
millisecond count in `DAUX1` (low) / `DAUX2` (high). No payload.

#sect("TCP and UDP")

#cmd("Accept client", "N: — SIO $41 'A'")
On a listening TCP channel, accept a waiting client. No payload.

#cmd("Close client", "N: — SIO $63 'c'")
Drop the current TCP client but keep listening. No payload.

#cmd("Set UDP destination", "N: — SIO $44 'D'")
Send #cw("\"host:port\"") (direction #cw("$80")); subsequent writes go there.

#cmd("Get UDP remote", "N: — SIO $72 'r'")
Read the address of the last datagram's sender into `DBUF` (direction #cw("$40")). *This
command is reachable only on the low road — see Chapter 9.*

#cmd("Inquire direction", "N: — SIO $FF")
Ask what data direction a command uses. `DAUX1` is the command byte to ask about; the
reply is one byte: #cw("$00") none, #cw("$40") read, #cw("$80") write, #cw("$FF") unknown.
This is the very call NDEV makes before every special command; you can use it to write a
handler of your own.

#divider
#pagebreak()

// ============================================================
// 7. THE FUJI CONTROL DEVICE — SIO REFERENCE
// ============================================================
#secmark("The Fuji Control Device — SIO Reference")
#headband("The Fuji Control Device", "SIO Reference")

The device at bus id #cw("$70") is the one CONFIG talks to: the WiFi radio, the host and
disk-image mounts, the directory browser, the app-key store, the clock, and a shelf of
utilities. *NDEV does not expose any of it* — this whole chapter is the low road only. Set
`DDEVIC` to #cw("$70"), `DUNIT` to `1`.

A note on parameters: unlike the Network device, the Fuji device takes most of its small
arguments in `DAUX1`/`DAUX2` and reserves the payload for bulk data (names, slot arrays,
disk images). Each entry says which.

#sect("WiFi and the adapter")

#cmd("Scan networks", "Fuji — SIO $FD")
Kick off a scan. Read one byte back: the count of access points found. Direction #cw("$40"),
`DBYT` 1.
#listing("Scan, then list the access points")[
```asm
; DDEVIC=$70 throughout.  A count comes back in NBUF.
SCAN    lda #<SCANCB : ldy #>SCANCB : jsr SIOCALL
        lda  NBUF             ; A = number of APs
        sta  COUNT
        ; --- for each index 0..COUNT-1, GET SCAN RESULT ---
        ldx  #0
SR      stx  RESCB+10         ; DAUX1 = index
        lda #<RESCB : ldy #>RESCB : jsr SIOCALL
        ; ENTRY now holds 32-byte SSID + 1 signed RSSI byte
        ; ... print it ...
        inx : cpx COUNT : bne SR
        rts

SCANCB  .byte $70,$01,$FD,$40 : .word NBUF
        .byte $1F,$00 : .word 1 : .byte $00,$00
RESCB   .byte $70,$01,$FC,$40 : .word ENTRY
        .byte $1F,$00 : .word 33 : .byte $00,$00
NBUF    .res 1
ENTRY   .res 33
```
]

#cmd("Get scan result", "Fuji — SIO $FC")
Read one scanned access point. `DAUX1` is the index (0-based). Reads a 33-byte record:
a 32-byte SSID followed by one signed RSSI byte. Direction #cw("$40").

#cmd("Set SSID", "Fuji — SIO $FB")
Join a network. Payload (direction #cw("$80")) is a 32-byte SSID then a 64-byte password;
`DAUX1` = 1 stores it to config so the FujiNet rejoins at power-on.

#cmd("Get SSID", "Fuji — SIO $FE")
Read the stored SSID and password (same 96-byte layout). Direction #cw("$40").

#cmd("Get WiFi status", "Fuji — SIO $FA")
Read one byte: `3` = connected, `6` = not connected. Direction #cw("$40").

#cmd("Get adapter config", "Fuji — SIO $E8")
Read the live network configuration into `DBUF`. Direction #cw("$40").
#ptable(
  ("Off", "Bytes", "Field"),
  ("0", "32", "SSID"),
  ("32", "64", "hostname"),
  ("96", "4", "local IP"),
  ("100", "4", "gateway"),
  ("104", "4", "netmask"),
  ("108", "4", "DNS server"),
  ("112", "6", "MAC address"),
  ("118", "6", "BSSID"),
  ("124", "15", "firmware version string"),
)

#sect("Hosts and disk slots")
*Host slots* (8) name where disks live — a TNFS server, an SMB share, the SD card.
*Disk slots* (8) are the drive bays `D1:` through `D8:`. Mounting is two steps: mount a
host, then mount an image from it into a disk slot.

#ptable(
  ("Cmd", "Operation", "Parameters"),
  ("$F4", "read host slots", "read 8 × 32-byte names (256 bytes), direction $40"),
  ("$F3", "write host slots", "send 256 bytes, direction $80"),
  ("$F2", "read device slots", "read the 8 × 38-byte slot array, direction $40"),
  ("$F1", "write device slots", "send the slot array, direction $80"),
  ("$F9", "mount host", "DAUX1 = host slot"),
  ("$E6", "unmount host", "DAUX1 = host slot"),
  ("$F8", "mount image", "DAUX1 = disk slot, DAUX2 = mode (1 RO, 2 RW)"),
  ("$E9", "unmount image", "DAUX1 = disk slot"),
  ("$D7", "mount all", "no parameters — mount every configured slot"),
  ("$E2", "set device filename", "DAUX1 = slot, DAUX2 = host<<4 | mode; payload = name"),
  ("$A0–$A9", "get device filename", "$A0 + slot; read the path back, direction $40"),
)

A *device-slot record* is 38 bytes: host slot (1), access mode (1: 1 = read, 2 =
read/write), then a 36-byte filename.

#listing("Mount host slot 0, image into disk slot 1 (R/W)")[
```asm
MOUNT   lda #<MHOST : ldy #>MHOST : jsr SIOCALL   ; mount host
        lda #<MIMG  : ldy #>MIMG  : jsr SIOCALL   ; mount image
        rts
; mount host: DAUX1 = host slot 0
MHOST   .byte $70,$01,$F9,$00 : .word 0
        .byte $1F,$00 : .word 0 : .byte $00,$00
; mount image: DAUX1 = disk slot 1, DAUX2 = 2 (read/write)
MIMG    .byte $70,$01,$F8,$00 : .word 0
        .byte $1F,$00 : .word 0 : .byte $01,$02
```
]

#cmd("New disk", "Fuji — SIO $E7")
Manufacture a blank disk image on a writable host. Direction #cw("$80"); the payload is a
short header then the filename:
#ptable(
  ("Off", "Bytes", "Field"),
  ("0", "2", "number of sectors (low / high)"),
  ("2", "2", "sector size (128 / 256 / 512)"),
  ("4", "1", "host slot"),
  ("5", "1", "device (disk) slot"),
  ("6", "256", "filename"),
)

#sect("Browsing a host")

#cmd("Open directory", "Fuji — SIO $F7")
`DAUX1` = host slot; payload (direction #cw("$80")) is the path, NUL, then an optional
wildcard filter.

#cmd("Read directory entry", "Fuji — SIO $F6")
`DAUX1` = maximum length to return; `DAUX2` = flags (`$80` appends packed date/size/flags
after the name). Reads one entry into `DBUF`. A first byte of #cw("$7F") is the
end-of-directory marker.

#cmd("Close directory", "Fuji — SIO $F5")
No parameters.

#cmd("Get / set position", "Fuji — SIO $E5 / $E4")
Read the current directory position (2 bytes), or set it from `DAUX1`/`DAUX2`, for paging.

#sect("App keys — a place to keep state")
The FujiNet will hold a small block (up to 64 bytes) on its SD card for your program,
indexed by a *creator id*, *app id* and *key id*. Ideal for high scores, saved options,
a resume point.

#cmd("Open app key", "Fuji — SIO $DC")
Payload (direction #cw("$80")): creator id (2 bytes, low first), app id (1), key id (1),
mode (1: 0 = read, 1 = write). Opens the key for the read or write that follows.

#cmd("Write app key", "Fuji — SIO $DE")
After opening for write, send the data. `DAUX1`/`DAUX2` carry the length (16-bit, low
first). Direction #cw("$80"); up to 64 bytes are stored.

#cmd("Read app key", "Fuji — SIO $DD")
After opening for read, read the block back (a 2-byte length then the data). Direction
#cw("$40").

#cmd("Close app key", "Fuji — SIO $DB")
No parameters — closes the current key.

#sect("The clock, utilities, and housekeeping")
The Fuji device also tells time (Chapter 8) and carries a shelf of utilities. Small ones:

#ptable(
  ("Cmd", "Operation", "Notes"),
  ("$FF", "reset the FujiNet", "no parameters"),
  ("$D9", "enable/disable CONFIG boot", "DAUX1 = 0/1"),
  ("$D6", "set boot mode", "DAUX1 = mode"),
  ("$D5 / $D4", "enable / disable a device", "DAUX1 = device id"),
  ("$D1", "device-enabled status", "read one byte, direction $40"),
  ("$D8", "copy a file between hosts", "payload = source, dest slots + spec"),
  ("$D3", "random number", "read 4 bytes, direction $40"),
  ("$BB", "generate a GUID", "read the 36-char string, direction $40"),
  ("$EB", "set SIO baud rate", "DAUX1 = index (0 = 19200 … 6 = 921600)"),
  ("$E3", "set high-speed SIO index", "DAUX1 = index, DAUX2 = 1 to save"),
)

And three multi-step utility families — each is *input, compute, length, output*, sending
data in and reading the result back out in pieces:

#ptable(
  ("Family", "Commands", "Notes"),
  ("Hash", "$C8 $C7 $C6 $C5 $C2", "input, compute, length, output, clear; algorithm in the byte after $C7 (0 MD5, 1 SHA-1, 2 SHA-256, 3 SHA-512)"),
  ("Base64 encode", "$D0 $CF $CE $CD", "input, compute, length, output"),
  ("Base64 decode", "$CC $CB $CA $C9", "input, compute, length, output"),
  ("QR code", "$BC $BD $BE $BF", "input, encode, length, output — the bytes of a QR bitmap"),
)

#divider
#pagebreak()

// ============================================================
// 8. TELLING TIME
// ============================================================
#secmark("Telling Time")
#headband("Telling", "Time")

The Atari has never known what time it is. The FujiNet does — it keeps the clock from the
Internet — and there are two ways to ask.

#sect("From the Fuji device")
#cmd("Get time", "Fuji — SIO $D2")
Point `DDEVIC` at #cw("$70"), send #cw("$D2"), and read seven bytes: a binary date and
time in the FujiNet's configured zone.
#ptable(
  ("Off", "Bytes", "Field"),
  ("0", "1", "century (add to year: $13 = 19 → 1900s, $14 = 20 → 2000s)"),
  ("1", "1", "year (0–99)"),
  ("2", "1", "month (1–12)"),
  ("3", "1", "day"),
  ("4", "1", "hour (24-hour)"),
  ("5", "1", "minute"),
  ("6", "1", "second"),
)
#listing("Read the wall clock")[
```asm
GETTIME lda #<TIMECB : ldy #>TIMECB : jsr SIOCALL
        ; NOW+0..6 = century, year, month, day, hour, min, sec
        rts
TIMECB  .byte $70,$01,$D2,$40 : .word NOW
        .byte $1F,$00 : .word 7 : .byte $00,$00
NOW     .res 7
```
]

#sect("From the clock (APETime) device")
FujiNet also emulates the venerable *APETime* clock at bus id #cw("$45"), the interface a
good deal of existing Atari software already understands. It offers the time pre-formatted
several ways, chosen by the command byte:

#ptable(
  ("Cmd", "Format"),
  ("$93", "APETime binary (6 bytes: DD MM YY HH MM SS)"),
  ("$41 'A'", "Atari-native binary"),
  ("$49 'I'", "ISO-8601 local time, as a string"),
  ("$5A 'Z'", "ISO-8601 UTC, as a string"),
  ("$50 'P'", "ProDOS date/time"),
  ("$99", "set the time zone (payload = TZ string)"),
)
The clock device is the right target when adapting software that already speaks APETime;
the Fuji device's #cw("$D2") is the simplest when writing fresh.

#divider
#pagebreak()

// ============================================================
// 9. WHAT NDEV CANNOT REACH
// ============================================================
#secmark("What NDEV Cannot Reach")
#headband("What NDEV", "Cannot Reach")

The high road is broad but not complete. Some of the FujiNet is out of NDEV's sight, and
knowing exactly where the road ends saves an afternoon of wondering why an `XIO` returns
error 146. Each gap below is also a standing invitation: NDEV is open source (Chapter 2,
Appendix C), and closing these is the obvious next work.

#sect("The whole Fuji control device")
This is the big one. *NDEV speaks only to the Network device* (`$71`–`$78`). Everything in
Chapter 7 — mounting hosts and disks, scanning WiFi, reading the clock, the app-key store,
the directory browser, hashing, Base64, QR codes — lives on the Fuji device (`$70`), which
NDEV never addresses. From BASIC there is no `XIO` that will mount a disk. To reach the
Fuji device you must take the low road: poke the DCB and call `SIOV` yourself (which BASIC
can do through `USR` and a short machine-code stub, or a language cartridge can do
directly).

*A worthy improvement:* a companion handler, or an extension to NDEV, that surfaces the
common Fuji commands as `XIO`s on a pseudo-device — mount, unmount, scan, get-time — so a
BASIC program could manage its own disks.

#sect("A handful of network sub-commands")
NDEV reaches a network special command only if the FujiNet's *inquiry* (Chapter 6, `$FF`)
reports a known data direction for it. A few commands are not in that table, so NDEV
answers *error 146* when you try:

#ptable(
  ("SIO", "Char", "Command", "Why it is out of reach"),
  ("$72", "r", "UDP get remote address", "not in the inquiry table — reachable only via direct SIO"),
  ("$4D", "M", "HTTP set channel mode (headers)", "not in the inquiry table; set the verb via OPEN aux1 instead"),
  ("$FA", "—", "set channel (advanced)", "not surfaced through NDEV"),
)
None of these is fatal — the UDP sender address you can read on the low road, and HTTP
verbs you select through the `OPEN` access mode — but they are honest gaps. Adding their
rows to the firmware's inquiry table would let NDEV pass them straight through.

#sect("The 128-byte receive cap")
NDEV's receive path caps a single read at *127 bytes* (its transmit and receive buffers are
128 bytes each). A program that reads through `GET`/`INPUT` never notices — the handler
loops — but it means NDEV cannot hand back a 512-byte block in one call the way a direct
`READ` can. For bulk transfer, the low road's larger single reads are faster. *An
improvement:* a larger, page-aligned buffer, or a block-read special command.

#sect("STATUS is four bytes, no more")
The handler's `STATUS` returns exactly the four `DVSTAT` bytes — bytes-waiting, connection,
error. Richer per-protocol status (an HTTP response code, an FTP reply line) is available
on the wire but not surfaced by NDEV. Reading it is a low-road affair today.

#divider
#pagebreak()

// ============================================================
// 10. OTHER LANGUAGES THROUGH CIO
// ============================================================
#secmark("Other Languages Through CIO")
#headband("Other Languages", "Through CIO")

Nothing about the N: handler is particular to Atari BASIC. NDEV installs itself into the
Atari's handler table, and *any language that can reach CIO can reach the FujiNet.* If it
can `OPEN` a device and `GET`/`PUT` bytes, it can talk to `N:`.

#sect("The Assembler / Editor cartridge")
The Atari Assembler/Editor cartridge (and the Macro Assembler, and MAC/65) assemble
programs that call `CIOV` at #cw("$E456") directly. Set up an IOCB — handler-id from the
device name, command, buffer, aux bytes — load `X` with the IOCB number times sixteen, and
`JSR CIOV`. The special commands of Chapter 4 are just command bytes 14 and up in `ICCOM`.
A program written this way needs no BASIC at all, and runs at assembly speed while still
riding NDEV's buffering and interrupt handling.

#sect("Atari Logo")
Atari Logo has no file words of its own, but it has three that let you reach anything: the
low-level primitives #cw(".DEPOSIT"), #cw(".EXAMINE"), and #cw(".CALL"). With them you poke
a tiny machine-code stub into page six (`$0600`, free on every Atari), set up an IOCB, and
`.CALL` `CIOV` through the stub. The next chapter shows exactly this.

#sect("And the rest")
The same door is open to Action!, to Forth, to C compiled with cc65, to Pascal — to any
language on the Atari that can call the OS. Most reach `N:` through CIO exactly as BASIC
does; some (Action!, in Chapter 12) skip NDEV entirely and drive SIO. The point stands:
*the N: handler is a public utility, and every language is welcome to it.*

#divider
#pagebreak()

// ============================================================
// 11. FUJINET FROM ATARI LOGO
// ============================================================
#secmark("FujiNet from Atari Logo (NDEV)")
#headband("FujiNet from", "Atari Logo")

Atari Logo is turtles and lists, not file handles — but its three low-level primitives
open a path to the N: handler. The plan: build a three-byte stub in page six that selects
an IOCB and jumps to `CIOV`, then drive an IOCB from Logo with #cw(".DEPOSIT"), calling the
stub with #cw(".CALL") for each CIO operation.

#sect("The stub")
CIO expects the IOCB number, times sixteen, in the `X` register; #cw(".CALL") enters an
address with a plain `JSR` and does not set registers. So we lay down a stub that sets `X`
itself and jumps to `CIOV` (#cw("$E456"), decimal 58454):
#block(inset: (left: 0.3in), {
  set text(size: 9pt)
  [#cw("$0600") · #cw("LDX #$10") — `162 16` — use IOCB \#1 \
   #cw("$0602") · #cw("JMP CIOV") — `76 86 228`]
})
#listing("Reach N: from Atari Logo")[
```
TO NSETUP
  ; --- lay the stub at 1536 ($0600) ---
  .DEPOSIT 1536 162   ; LDX #$10   (IOCB 1)
  .DEPOSIT 1537 16
  .DEPOSIT 1538 76    ; JMP $E456  (CIOV)
  .DEPOSIT 1539 86
  .DEPOSIT 1540 228
END

TO NPUTSPEC :SPEC :ADDR         ; the device spec, char by char
  IF EMPTYP :SPEC [.DEPOSIT :ADDR 155  STOP]   ; 155 = EOL
  .DEPOSIT :ADDR  ASCII FIRST :SPEC
  NPUTSPEC BUTFIRST :SPEC  :ADDR + 1
END

TO NOPEN :SPEC
  NPUTSPEC :SPEC 1280           ; device spec into $0500
  ; IOCB 1 is at $0350..$035F (848..)
  .DEPOSIT 850 3                ; ICCOM = 3 (OPEN)
  .DEPOSIT 852 0  .DEPOSIT 853 5 ; ICBAL/H = $0500
  .DEPOSIT 858 4                ; ICAX1 = 4 (read)
  .DEPOSIT 859 2                ; ICAX2 = 2 (LF)
  .CALL 1536
END

TO NGET                         ; read one byte (GET CHARACTERS)
  .DEPOSIT 850 7                ; ICCOM = 7
  .DEPOSIT 852 0  .DEPOSIT 853 5 ; ICBAL/H = $0500
  .DEPOSIT 856 1  .DEPOSIT 857 0 ; ICBLL/H = 1 byte
  .CALL 1536
  OUTPUT .EXAMINE 1280          ; the byte at $0500
END

TO NCLOSE
  .DEPOSIT 850 12              ; ICCOM = 12 (CLOSE)
  .CALL 1536
END
```
]
IOCB \#1's control block begins at #cw("$0350") (decimal 848): command at +2 (850), buffer
address at +4/+5 (852/853), buffer length at +8/+9 (856/857), the aux bytes at +10/+11
(858/859). #cw(".DEPOSIT address value") writes a byte; #cw(".EXAMINE address") reads one
back. Change the stub's `LDX` operand (`16` for IOCB 1, `32` for 2, `48` for 3 …) to drive
other channels.

This is deliberately close to the metal — but it works, and it is the honest way to give a
turtle a network. Anything BASIC does with `N:`, Logo can do this way; only the plumbing is
longer.

#divider
#pagebreak()

// ============================================================
// 12. FUJINET IN ACTION!
// ============================================================
#secmark("FujiNet in Action! (SIO)")
#headband("FujiNet in", "Action!")

The OSS *Action!* language compiles to fast 6502 and lets you reach memory and the OS
directly — so the natural way to use the FujiNet from Action! is the *low road:* fill the
DCB, call `SIOV`, skip NDEV entirely. This chapter walks the *NIO.ACT* library, a small
Action! module that does exactly that. (The full source is at the end of this chapter; the
companion #emph[Action! Reference Manual] is in the repository's `learn/` folder.)

#sect("The shape of it")
Action! lets you name the DCB fields as `BYTE` and `CARD` (16-bit) variables at their
page-three addresses, and declare `SIOV` as a `PROC` at #cw("$E459"). After that a command
is just: set the fields, call `siov()`, read `DSTATS`.

#listing("NIO.ACT — the DCB, and the SIO entry")[
```
; the Device Control Block, named field by field
BYTE DDEVIC = $0300   ; Device #
BYTE DUNIT  = $0301   ; Unit #
BYTE DCOMND = $0302   ; Command
BYTE DSTATS = $0303   ; direction / result
CARD DBUF   = $0304   ; buffer
BYTE DTIMLO = $0306   ; timeout secs
CARD DBYT   = $0308   ; payload length
CARD DAUX   = $030A   ; aux1 / aux2
BYTE DAUX1  = $030A
BYTE DAUX2  = $030B

PROC siov=$E459()     ; the OS SIO vector
```
]

#sect("Open, read, write")
Each library routine is the DCB pattern with the command byte and direction filled in. Note
the direction constants — #cw("$40") to receive, #cw("$80") to send — exactly as Chapter 5
described.

#listing("NIO.ACT — OPEN and READ")[
```
BYTE FUNC nopen(BYTE ARRAY ds, BYTE t)
  DDEVIC = $71
  DUNIT  = ngetunit(ds)
  DCOMND = 'O            ; OPEN
  DSTATS = $80           ; Atari -> FujiNet
  DBUF   = ds            ; the device spec
  DTIMLO = $1F
  DBYT   = 256
  DAUX1  = 12            ; read/write
  DAUX2  = t             ; translation
  siov()
RETURN (geterror(ds))

BYTE FUNC nread(BYTE ARRAY ds, BYTE ARRAY buf, CARD len)
  DDEVIC = $71
  DUNIT  = ngetunit(ds)
  DCOMND = 'R            ; READ
  DSTATS = $40           ; FujiNet -> Atari
  DBUF   = buf
  DTIMLO = $1F
  DBYT   = len
  DAUX   = len
  siov()
RETURN (geterror(ds))
```
]

#sect("The error dance, and the interrupt")
`NIO.ACT` handles errors just as NDEV does: when `DSTATS` comes back `144`, it issues a
`STATUS` (`'S'`) and reads the extended error from `DVSTAT+3`. It also carries an optional
*PROCEED* interrupt handler — a five-byte routine poked into memory — that sets a flag when
the FujiNet signals, so a program can await data without a busy loop, the same mechanism
NDEV uses.

#listing("NIO.ACT — extended error, and the PROCEED trip")[
```
BYTE FUNC geterror(BYTE ARRAY ds)
  BYTE errno
  IF DSTATS=144 THEN     ; device-signalled error
    nstatus(ds)          ; do a STATUS
    errno=EXTERR         ; DVSTAT+3 (the real cause)
  ELSE
    errno=DSTATS
  FI
RETURN (errno)

PROC ninterrupt_handler=*()   ; the 5-byte PROCEED handler
[$A9$01$8D trip $68$40]       ; LDA #1 : STA trip : PLA : RTI
```
]

#sect("Why Action! takes the low road")
Action! could call CIO and use NDEV — but it does not need to. It reaches the OS as easily
as BASIC reaches a variable, so driving SIO directly is no harder and a good deal faster:
no handler to load, no DUP to trip over, and the full Network device at hand. `NIO.ACT` is
the template — copy it, point `DDEVIC` at #cw("$70"), and the Fuji device of Chapter 7 is
yours from Action! too.

The complete, unabridged `NIO.ACT`:

#listing("NIO.ACT — the complete library")[
#raw(read("listings/NIO.ACT"), lang: "clike", block: true)
]

#divider
#pagebreak()

// ============================================================
// APPENDIX A — ERROR CODES
// ============================================================
#secmark("Appendix A — Error Codes")
#headband("Appendix A", "Error Codes")

#sect("What DSTATS returns from a SIO call")
The OS leaves one of these in `DSTATS` (#cw("$0303")) after `SIOV`. A value with the high
bit set (≥ 128) is trouble.
#ptable(
  ("Code", "Meaning"),
  ("1", "success"),
  ("138", "device timeout — nothing answered on the bus"),
  ("139", "device NAK — the frame was refused"),
  ("143", "bad frame — checksum mismatch"),
  ("144", "device error — the FujiNet signalled; read STATUS for the cause"),
)

#sect("The FujiNet's own error codes")
When `DSTATS` is `144`, issue a Network `STATUS` and read byte 3 of the reply (or, through
NDEV, `PEEK(749)`). These are the FujiNet device-status codes:
#ptable(
  ("Code", "Name", "Meaning"),
  ("1", "SUCCESS", "no error"),
  ("136", "END OF FILE", "the resource is fully read"),
  ("144", "GENERAL", "a fatal device error"),
  ("146", "NOT IMPLEMENTED", "command unknown to NDEV or the device"),
  ("151", "FILE EXISTS", "on a make-directory or create"),
  ("162", "NO SPACE", "the device is full"),
  ("165", "INVALID DEVICESPEC", "the N: spec could not be parsed"),
  ("167", "ACCESS DENIED", "permission refused"),
  ("170", "FILE NOT FOUND", "no such file, or a network 404"),
  ("200", "CONNECTION REFUSED", "the far end refused, or is unreachable"),
  ("201", "NETWORK UNREACHABLE", "no route to the host"),
  ("202", "SOCKET TIMEOUT", "the connection timed out"),
  ("203", "NETWORK DOWN", "the WiFi link is down"),
  ("204", "CONNECTION RESET", "the far end reset the connection"),
  ("207", "NOT CONNECTED", "operated on a closed channel"),
  ("208", "SERVER NOT RUNNING", "a listening server returned nothing"),
  ("212", "BAD USER / PASSWORD", "credentials rejected"),
  ("213", "CANNOT PARSE JSON", "the document was not valid JSON"),
  ("255", "NO BUFFERS", "the FujiNet could not allocate memory"),
)

#divider
#pagebreak()

// ============================================================
// APPENDIX B — COMMAND QUICK REFERENCE
// ============================================================
#secmark("Appendix B — Command Quick Reference")
#headband("Appendix B", "Quick Reference")

#sect("Devices on the bus")
#ptable(
  ("DDEVIC", "DUNIT", "Wire id", "Device"),
  ("$71", "1–8", "$71–$78", "Network — N1: through N8:"),
  ("$70", "1", "$70", "Fuji control device"),
  ("$45", "1", "$45", "Clock (APETime)"),
)

#sect("BASIC / XIO summary (the high road)")
#ptable(
  ("From BASIC", "Does"),
  ("OPEN #ch,mode,trans,\"Nx:...\"", "connect (mode 4 read, 8 write, 12 r/w; trans 0/1/2/3)"),
  ("INPUT #ch,A$   /   GET #ch,B", "read a record / one byte"),
  ("PRINT #ch;A$   /   PUT #ch,B", "write a record / one byte"),
  ("STATUS #ch,S", "fill DVSTAT — PEEK(746/747) bytes, 748 conn, 749 error"),
  ("CLOSE #ch", "flush and disconnect"),
  ("XIO 15", "flush the transmit buffer now"),
  ("XIO 32/33/35/36", "rename / delete / lock / unlock"),
  ("XIO 42/43/44/48", "mkdir / rmdir / chdir / getcwd"),
  ("XIO 65/99", "TCP accept client / close client"),
  ("XIO 68", "UDP set destination"),
  ("XIO 80/81", "JSON parse / query"),
  ("XIO 84/90", "translation / interrupt rate"),
  ("XIO 252", "channel mode (aux2: 0 protocol, 1 JSON)"),
  ("XIO 253/254", "username / password"),
)

#sect("Network device — SIO command bytes (the low road)")
#ptable(
  ("Cmd", "Char", "Operation"),
  ("$4F", "O", "open connection (aux1 mode, aux2 trans, spec)"),
  ("$43", "C", "close connection"),
  ("$52", "R", "read waiting bytes (count in aux1/aux2)"),
  ("$57", "W", "write bytes (count in aux1/aux2)"),
  ("$53", "S", "channel status — 4 bytes"),
  ("$50", "P", "JSON parse"),
  ("$51", "Q", "JSON query (then read the value)"),
  ("$FC", "—", "channel mode (aux2: 0 protocol, 1 JSON)"),
  ("$54", "T", "set translation (aux2)"),
  ("$5A", "Z", "set interrupt rate (aux1/aux2)"),
  ("$FD / $FE", "—", "set username / password"),
  ("$2C / $30", ", 0", "change / get directory"),
  ("$20", " ", "rename (spec \"from,to\")"),
  ("$21 $23 $24", "! # $", "delete / lock / unlock"),
  ("$2A / $2B", "* +", "make / remove directory"),
  ("$41 / $63", "A c", "TCP accept / close client"),
  ("$44 / $72", "D r", "UDP set destination / get remote"),
  ("$FF", "—", "inquire a command's data direction"),
)

#sect("Fuji control device — SIO command bytes")
#ptable(
  ("Cmd", "Operation"),
  ("$FF", "reset FujiNet"),
  ("$FD / $FC", "scan networks / get scan result n"),
  ("$FB / $FE", "set / get SSID"),
  ("$FA", "get WiFi status"),
  ("$E8 / $C4", "get adapter config / extended"),
  ("$F9 / $E6", "mount / unmount host slot"),
  ("$F8 / $E9", "mount / unmount disk image"),
  ("$D7", "mount all"),
  ("$F4 / $F3", "read / write host slots"),
  ("$F2 / $F1", "read / write device slots"),
  ("$E2 / $A0–$A9", "set / get device filename"),
  ("$E7", "new (blank) disk"),
  ("$F7 $F6 $F5", "open / read / close directory"),
  ("$E5 / $E4", "get / set directory position"),
  ("$DC $DD $DE $DB", "app key: open / read / write / close"),
  ("$D9 / $D6", "CONFIG boot / boot mode"),
  ("$D5 / $D4 / $D1", "enable / disable / query device"),
  ("$D8 / $D3 / $BB", "copy file / random number / GUID"),
  ("$D2", "get time (7 bytes)"),
  ("$EB / $E3", "set baud rate / high-speed index"),
  ("$C8 $C7 $C6 $C5 $C2", "hash: input, compute, length, output, clear"),
  ("$D0 $CF $CE $CD", "Base64 encode: input, compute, length, output"),
  ("$CC $CB $CA $C9", "Base64 decode: input, compute, length, output"),
  ("$BC $BD $BE $BF", "QR: input, encode, length, output"),
)

#divider
#pagebreak()

// ============================================================
// APPENDIX C — THE NDEV HANDLER
// ============================================================
#secmark("Appendix C — The NDEV Handler")
#headband("Appendix C", "The NDEV Handler")

The complete source of the N: handler, verbatim from the `fujinet-nhandler` repository
(`handler/src/ndev.s`), assembled with MADS. It is a CIO handler installed into HATABS as
device *N*, with the six standard vectors — OPEN, CLOSE, GET, PUT, STATUS, SPECIAL — each
built on a shared #cw("DOSIOV") that copies a DCB template into page three and calls
`SIOV`. Read it against Chapters 3 and 4: the `SPECIAL` routine's local handling of command
15 (flush), the inquiry (#cw("$FF")) before every other special, the PUT buffer that flushes
on EOL or when full, and the PROCEED interrupt that drives `GET`.

#raw(read("listings/ndev.s"), lang: "asm", block: true)

#divider
#pagebreak()

// ============================================================
// APPENDIX D — A NETCAT
// ============================================================
#secmark("Appendix D — netcat")
#headband("Appendix D", "netcat")

Every guide in this series ends with a *netcat* — open a socket, pump bytes both ways —
because it exercises the whole road in a page. Here it is on the *high road*, in Atari
BASIC through `N:`: whatever you type crosses the wire, whatever arrives paints on the
screen, until the far end hangs up or you press *BREAK*.

#listing("netcat, in Atari BASIC over N:")[
```basic
10 REM ===== FUJINET NETCAT (N: HANDLER) =====
20 DIM L$(255)
30 REM  OPEN A RAW TCP SOCKET, READ/WRITE, BINARY
40 OPEN #1,12,0,"N1:TCP://192.168.1.5:9000/"
45 OPEN #2,4,0,"K:":REM  THE KEYBOARD, FOR TYPING
50 REM  --- MAIN PUMP ---
60 STATUS #1,S
70 IF PEEK(748)=0 THEN GOTO 900:REM  FAR END CLOSED
80 IF PEEK(749)=136 THEN GOTO 900:REM  EOF
90 BW=PEEK(746)+PEEK(747)*256
100 IF BW=0 THEN GOTO 200
110 REM  --- DRAIN THE SOCKET TO THE SCREEN ---
120 FOR I=1 TO BW
130 GET #1,B:PUT #16,B:REM  #16 = SCREEN (SEE BELOW)
140 NEXT I
200 REM  --- SEND A KEY IF ONE IS WAITING ---
210 IF PEEK(764)=255 THEN GOTO 60:REM  NO KEY DOWN
220 GET #2,K:REM  READ THE ATASCII KEY
230 PUT #1,K
240 XIO 15,#1,0,0,"N:":REM  FLUSH IT OUT NOW
250 GOTO 60
900 PRINT :PRINT "** CONNECTION CLOSED"
910 CLOSE #1:CLOSE #2:END
```
]

Three Atari touches earn their keep. #cw("PEEK(764)") is the OS's "last key pressed" cell —
`255` when nothing is down — so the pump never blocks waiting for the keyboard while the
socket has data. #cw("XIO 15") flushes each keystroke the instant you type it, so the far
end sees your typing live instead of a line at a time. And #cw("PUT #16") is the old Atari
BASIC trick for writing to the *screen editor:* BASIC multiplies the channel number by
sixteen to index the IOCB, so channel 16 wraps to IOCB 0 — the `E:` editor BASIC reserves
for itself and will not let you `PUT #0`. #cw("PUT #16,B") slips a byte onto the screen
through that back door, faster than #cw("PRINT CHR\$(B);").

On the other end, anything that speaks TCP will do — the classic test is the Unix `nc`
itself, listening on the port you named:
#screen(w: 4.2in)[
#h(4pt)nc -l 9000 \
HELLO FROM THE ATARI \
and hello back from the laptop \
the quick brown fox jumped over \
\
\*\* CONNECTION CLOSED
]

Type, and your keystrokes cross the room — or the world — and the reply paints onto a
1.79 MHz machine that predates the network it just joined. Fill the DCB, call the OS, read
the reply; the rest is just 6502.

#v(1fr)
#line(length: 100%, stroke: 0.8pt + ink)
#v(4pt)
#block({
  set text(size: 8pt)
  set par(leading: 0.5em)
  [*SOURCE-VERIFIED.* Every command byte, parameter and payload in this book was read out
   of the FujiNet sources, not remembered: `fujinet-firmware` — the SIO bus in
   `lib/bus/sio/`, the device handlers in `lib/device/sio/` (`network.cpp`, `sioFuji.cpp`)
   and `lib/device/fujiDevice.cpp`, the command list in `include/fujiCommandID.h` and
   device ids in `include/fujiDeviceID.h`; the N: handler `fujinet-nhandler`
   (`handler/src/ndev.s`, reproduced in Appendix C); and the Action! library `NIO.ACT`.
   CIO and SIO facts are drawn from the Atari 400/800 OS ROM source listing. \
   \
   This guide is free software, part of the #link("https://github.com/FujiNetWIFI/fujinet-manuals")[`fujinet-manuals`]
   repository, released under the GNU General Public License v3. The FujiNet community
   answers day and night on Discord.]
})
