// ============================================================
// FUJINET PROFESSIONAL ARCADE -- PROGRAMMERS HANDBOOK
// The FujiNet programming manual for the Bally Astrocade (Bally
// Professional Arcade / Home Library Computer): the cartridge mailbox
// tutorial, the Z80 and Z88DK C client libraries, the complete Fuji- and
// network-device command reference, and five worked programs (NETCAT,
// TEXAS HOLD'EM, BATTLESHIP, FUJITZEE, CONFIG) with full listings.
//
// House style: the 1977 Bally Home Library Computer Owners Manual
// (astrocade/learn/), extrapolated to a technical manual -- landscape
// half-letter booklet, cream stock, black + Bally red, Helvetica-era
// heads, red CAUTION boxes, circled figure callouts, dot-leader lists.
//
// Every address, opcode, struct offset and code fragment is transcribed
// from the live project sources; see README.md for the sources-of-truth
// table with commit hashes.
//
// Build: typst compile --font-path fonts manual.typ
// ============================================================

#let f-head   = "Nimbus Sans"
#let f-body   = "Nimbus Sans"
#let f-mono   = "Source Code Pro"
#let f-screen = "Astrocade Screen"

// ---------- palette (two-color press: black + Bally red on cream) ----
#let ink    = rgb("#231f1c")            // warm black
#let red    = rgb("#c22128")            // Bally red
#let red-d  = rgb("#8f181e")
#let cream  = rgb("#f6f0e0")            // the paper
#let cream2 = rgb("#efe7d2")            // panels a shade deeper
#let gray   = rgb("#6f6a62")            // halftone gray (photos were B/W)
#let gray-l = rgb("#c9c2b4")
#let scr-bg = rgb("#181512")            // TV screen ground
#let scr-fg = rgb("#f2ede0")            // TV screen "white"
#let scr-gn = rgb("#79c060")            // TV screen green accent
#let scr-rd = rgb("#e0574f")            // TV screen red accent

// ---------- document ------------------------------------------------
#set document(title: "FujiNet Professional Arcade Programmers Handbook",
              author: "FujiNet Project")
#set page(width: 8.4in, height: 5.45in, fill: cream,
  margin: (x: 0.44in, top: 0.42in, bottom: 0.44in))
#set text(font: f-body, size: 8.8pt, fill: ink, lang: "en")
#set par(justify: true, leading: 0.5em, spacing: 0.62em,
  first-line-indent: (amount: 1.1em, all: false))
#set smartquote(enabled: true)

#let frontmatter = state("fm", true)

// ---------- headings (1977 system) ----------------------------------
// level 1: chapter opener -- centered red bold, like CONGRATULATIONS
// level 2: red bold flush left, like "Automatic TV Protection"
// level 3: bold black, like "How to get Gunfight on your screen:"
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  block(width: 100%, below: 0.7em, align(center, {
    text(font: f-head, weight: 700, size: 15.5pt, fill: red,
      tracking: 0.4pt, upper(it.body))
  }))
}
#show heading.where(level: 2): it => block(
  above: 1.05em, below: 0.5em, sticky: true,
  text(font: f-head, weight: 700, size: 11pt, fill: red, it.body))
#show heading.where(level: 3): it => block(
  above: 0.85em, below: 0.4em, sticky: true,
  text(font: f-head, weight: 700, size: 9.2pt, fill: ink, it.body))

#let chapter(t) = heading(level: 1, t)
#let sect(t) = heading(level: 2, t)
#let sub(t) = heading(level: 3, t)

// ---------- page chrome: folio at the outer bottom corner -----------
#set page(footer: context {
  if frontmatter.get() { return }
  let pg = counter(page).get().first()
  set text(font: f-head, size: 8.5pt, fill: ink)
  if calc.odd(pg) { align(right, str(pg)) } else { align(left, str(pg)) }
})

// ---------- inline code & raw blocks --------------------------------
#show raw.where(block: false): it => text(
  font: f-mono, size: 0.94em, fill: red-d.mix((ink, 55%)), weight: 500, it)

#show raw.where(block: true): it => block(
  width: 100%, breakable: true, fill: cream2, inset: (x: 8pt, y: 6pt),
  stroke: (left: 2pt + red, rest: 0.5pt + gray-l),
  text(font: f-mono, size: 6.9pt, fill: ink, it))

// ---------- code panel with a LISTING-style rubric ------------------
#let codepanel(title, body-txt, size: 6.9pt, breakable: false) = block(
  breakable: breakable, above: 0.85em, below: 0.85em, {
  block(breakable: false, below: 4pt, {
    line(length: 100%, stroke: 1.8pt + red)
    v(2pt)
    text(font: f-head, weight: 700, fill: red, size: 7.6pt,
      tracking: 0.5pt, upper(title))
  })
  {
    show raw.where(block: true): it => block(width: 100%,
      breakable: breakable,
      text(font: f-mono, size: size, fill: ink,
        it.lines.join(linebreak())))
    set par(justify: false, leading: 0.42em, first-line-indent: 0pt)
    raw(body-txt, block: true)
  }
  v(1pt)
  line(length: 100%, stroke: 0.7pt + red)
})

// ---------- CAUTION / NOTE boxes (the 1977 signature) ----------------
#let caution(body, title: "CAUTION") = block(
  width: 100%, above: 1em, below: 1em, breakable: false,
  stroke: 1.4pt + red, inset: (x: 10pt, y: 8pt), fill: cream,
  {
    align(center, text(font: f-head, weight: 700, size: 10pt, fill: red,
      tracking: 1pt, title))
    v(4pt)
    set par(justify: true, leading: 0.5em, first-line-indent: 0pt)
    body
  })

#let note(body) = block(
  width: 100%, above: 0.85em, below: 0.85em, breakable: false,
  fill: cream2, inset: (x: 9pt, y: 7pt), stroke: (left: 2.5pt + ink),
  {
    text(font: f-head, weight: 700, size: 8pt, fill: ink)[NOTE:#h(4pt)]
    body
  })

// ---------- figures with italic "Figure N" captions ------------------
#let fig-n = counter("figure1977")
#let fig(body, caption: none) = block(
  width: 100%, above: 0.9em, below: 0.9em, breakable: false, {
  fig-n.step()
  align(center, body)
  if caption != none {
    v(3pt)
    align(center, text(font: f-body, style: "italic", size: 7.8pt,
      fill: ink, [Figure #context fig-n.display() #h(6pt) #caption]))
  } else {
    v(3pt)
    align(center, text(font: f-body, style: "italic", size: 7.8pt,
      fill: ink, [Figure #context fig-n.display()]))
  }
})

// circled red number callout, keyed to red-numbered lists
#let co(n) = box(baseline: 22%, circle(radius: 4.6pt, stroke: 1pt + red,
  align(center + horizon, text(font: f-head, weight: 700, size: 6.8pt,
    fill: red, str(n)))))
#let rnum(n) = text(font: f-head, weight: 700, fill: red, [#n.])

// ---------- TV screen mockup -----------------------------------------
// body is a string; rendered in the Astrocade screen font (the actual
// 4x6 glyphs the clients draw with).
#let tv(txt, size: 7.6pt, fg: scr-fg, w: 2.9in) = box(
  fill: rgb("#e9e2cf"), radius: 10pt, inset: 8pt, stroke: 1.4pt + ink,
  box(fill: scr-bg, radius: 6pt, inset: (x: 10pt, y: 8pt), width: w - 16pt,
    align(left, {
      set par(leading: 0.5em, first-line-indent: 0pt)
      text(font: f-screen, size: size, fill: fg,
        txt.split("\n").map(l => if l == "" { " " } else { l })
          .join(linebreak()))
    })))

// keypad key as a boxed glyph
#let key(s) = box(baseline: 18%, stroke: 0.9pt + ink, inset: (x: 3.2pt, y: 1.6pt),
  text(font: f-head, weight: 700, size: 7.6pt, s))

// dot-leader definition row ("Joy Stick.... Walks your gun fighter")
#let dotdef(..rows) = {
  set par(first-line-indent: 0pt)
  grid(columns: (86pt, 1fr), row-gutter: 3.4pt, column-gutter: 0pt,
    ..rows.pos().map(r => (
      box(width: 100%, {
        text(font: f-head, size: 8.2pt, weight: 500, r.at(0))
        box(width: 1fr, repeat(text(size: 8.2pt)[.], gap: 1.5pt))
      }),
      text(size: 8.2pt, r.at(1)))).flatten())
}

// two-column body block, the 1977 default for prose
#let twocol(body) = columns(2, gutter: 18pt, body)

// a displayed devicespec / command line
#let spec(s) = align(center, block(above: 0.55em, below: 0.55em,
  box(fill: cream2, stroke: 0.6pt + gray-l, inset: (x: 9pt, y: 5pt),
    text(font: f-mono, size: 8.4pt, weight: 600, fill: ink, s))))

// ---------- command reference card -----------------------------------
#let cmdlab(s) = text(font: f-head, weight: 700, size: 6.6pt, fill: gray,
  tracking: 0.5pt, upper(s))
#let cmd(name, code: "", dev: "", nparam: "", params: "none",
         payload: "none", reply: "none", body) = block(
  width: 100%, above: 1em, below: 1em, breakable: true, {
  block(breakable: false, {
    line(length: 100%, stroke: 1.8pt + red)
    v(3pt)
    grid(columns: (1fr, auto), align: (left, right),
      text(font: f-head, weight: 700, size: 10pt, fill: red, name),
      text(font: f-mono, weight: 700, size: 9pt, fill: ink, code))
    v(3pt)
    grid(columns: (44pt, 1fr, 44pt, 1fr), row-gutter: 3.6pt, column-gutter: 6pt,
      cmdlab("device"),  text(font: f-mono, size: 7.4pt, dev),
      cmdlab("nparam"),  text(font: f-mono, size: 7.4pt, nparam),
      cmdlab("params"),  grid.cell(colspan: 3, text(size: 7.8pt, params)),
      cmdlab("payload"), grid.cell(colspan: 3, text(size: 7.8pt, payload)),
      cmdlab("reply"),   grid.cell(colspan: 3, text(size: 7.8pt, reply)),
    )
    v(2pt)
    line(length: 100%, stroke: 0.6pt + gray-l)
  })
  v(2pt)
  set par(first-line-indent: 0pt)
  body
})

// ---------- tables ----------------------------------------------------
#set table(stroke: (x, y) => (
  top: if y == 0 { 1pt + ink } else { 0.4pt + gray-l },
  bottom: 0.4pt + gray-l))
#show table.cell.where(y: 0): set text(font: f-head, weight: 700,
  size: 7.4pt, fill: cream)
#set table(fill: (x, y) => if y == 0 { red })
#set table(inset: (x: 5pt, y: 3.4pt))
#show table: set text(size: 7.8pt)

// ---------- byte-field strip ------------------------------------------
#let bytefield(..cells) = {
  let cs = cells.pos()
  align(center, block(above: 0.6em, below: 0.4em,
    grid(columns: cs.map(c => c.at(1)), rows: auto, stroke: 0.7pt + ink,
      ..cs.map(c => grid.cell(inset: 4.6pt, align: center,
        text(font: f-mono, size: 7.4pt, fill: ink, c.at(0)))))))
}

// ---------- block-diagram nodes ---------------------------------------
#let nodebox(title, sub: none, fill: cream2, bd: ink, w: auto, tc: ink) = box(
  width: w, fill: fill, inset: (x: 7pt, y: 5pt), radius: 2.5pt,
  stroke: 0.9pt + bd,
  align(center, {
    text(font: f-head, weight: 700, size: 8.2pt, fill: tc, title)
    if sub != none { v(2pt, weak: true)
      text(font: f-mono, size: 6.8pt, fill: gray, sub) }
  }))

#let rarrow(w: 24pt, c: ink, label: none) = box(width: w, height: 12pt, baseline: 4pt, {
  place(left + horizon, line(length: w - 5pt, stroke: 0.9pt + c))
  place(left + horizon, dx: w - 7pt, polygon(fill: c, (0pt,-3pt),(5pt,0pt),(0pt,3pt)))
  if label != none { place(center + bottom, dy: -8pt,
    text(font: f-head, size: 6.3pt, fill: c, label)) }
})
#let biarrow(w: 24pt, c: ink, label: none) = box(width: w, height: 12pt, baseline: 4pt, {
  place(left + horizon, dx: 4pt, line(length: w - 8pt, stroke: 0.9pt + c))
  place(left + horizon, dx: 0pt, polygon(fill: c, (5pt,-3pt),(0pt,0pt),(5pt,3pt)))
  place(left + horizon, dx: w - 7pt, polygon(fill: c, (0pt,-3pt),(5pt,0pt),(0pt,3pt)))
  if label != none { place(center + bottom, dy: -8pt,
    text(font: f-head, size: 6.3pt, fill: c, label)) }
})
#let flow(..items) = align(center, block(above: 0.7em, below: 0.5em,
  stack(dir: ltr, spacing: 0pt, ..items.pos())))

// ---------- sequence diagram (recolored from the Protocol Handbook) ---
#let msg(from, to, body, dashed: false, c: ink) = (
  kind: "msg", from: from, to: to, body: body, dashed: dashed, c: c)
#let snote(lane, body, span: 1, fill: cream2, bd: gray) = (
  kind: "note", lane: lane, span: span, body: body, fill: fill, bd: bd)
#let sgap(h: 10pt) = (kind: "gap", h: h)

#let seq(actors, ..steps, w: 420pt, lanecols: none) = {
  let cols = if lanecols == none { actors.map(a => a.at(2)) } else { lanecols }
  let n = actors.len()
  let steps = steps.pos()
  let lane = w / n
  let xs = range(n).map(i => lane * (i + 0.5))
  let headh = 24pt
  let bodyh = 0pt
  for s in steps {
    if s.kind == "gap" { bodyh += s.h }
    else if s.kind == "note" { bodyh += 26pt }
    else { bodyh += 22pt }
  }
  let toth = headh + bodyh + 12pt
  align(center, box(width: w, height: toth, {
    for i in range(n) {
      place(top + left, dx: xs.at(i) - 0.4pt, dy: headh - 2pt,
        line(start: (0pt, 0pt), end: (0pt, bodyh + 6pt),
          stroke: (paint: gray-l, thickness: 0.8pt, dash: "dotted")))
    }
    for i in range(n) {
      place(top + left, dx: xs.at(i) - lane/2 + 4pt, dy: 0pt,
        box(width: lane - 8pt, height: 20pt,
          fill: color.mix((cols.at(i), 14%), (cream, 86%)),
          stroke: 0.9pt + cols.at(i), radius: 2pt,
          align(center + horizon,
            text(font: f-head, weight: 700, size: 7.6pt, fill: cols.at(i),
              actors.at(i).at(0)))))
    }
    let y = headh + 6pt
    for s in steps {
      if s.kind == "gap" { y += s.h }
      else if s.kind == "note" {
        let x0 = xs.at(s.lane) - lane/2 + 6pt
        let wn = lane * s.span - 12pt
        place(top + left, dx: x0, dy: y - 4pt,
          box(width: wn, fill: s.fill, stroke: 0.7pt + s.bd, radius: 2pt,
            inset: (x: 5pt, y: 3pt), align(center,
              text(font: f-head, size: 6.8pt, fill: ink, s.body))))
        y += 26pt
      } else {
        let a = xs.at(s.from)
        let b = xs.at(s.to)
        let lab = text(font: f-mono, size: 6.8pt, fill: s.c, s.body)
        let lo = calc.min(a, b)
        let hi = calc.max(a, b)
        place(top + left, dx: lo, dy: y + 8pt,
          line(start: (0pt,0pt), end: (hi - lo, 0pt),
            stroke: (paint: s.c, thickness: 0.9pt,
              dash: if s.dashed {"dashed"} else {none})))
        if b > a {
          place(top + left, dx: b - 6pt, dy: y + 8pt,
            polygon(fill: s.c, (0pt,-3pt),(6pt,0pt),(0pt,3pt)))
        } else {
          place(top + left, dx: b, dy: y + 8pt,
            polygon(fill: s.c, (6pt,-3pt),(0pt,0pt),(6pt,3pt)))
        }
        place(top + left, dx: lo + 4pt, dy: y - 2pt, lab)
        y += 22pt
      }
    }
  }))
}

// ---------- appendix listing renderer ---------------------------------
// Reads a real source file from listings/ and prints it two-up with
// line numbers, the way the sources actually assemble.
#let code-listing(title, path, size: 4.9pt, cols: 2) = {
  block(breakable: false, above: 0.8em, below: 3pt, {
    line(length: 100%, stroke: 1.8pt + red)
    v(2pt)
    text(font: f-head, weight: 700, fill: red, size: 8pt,
      tracking: 0.5pt, upper(title))
  })
  {
    show raw.where(block: true): it => block(width: 100%, breakable: true,
      text(font: f-mono, size: size, fill: ink,
        it.lines.join(linebreak())))
    show raw.line: it => {
      box(width: 9pt, align(right,
        text(size: 3.7pt, fill: gray, str(it.number))))
      h(3pt)
      it.body
    }
    set par(justify: false, leading: 0.34em, hanging-indent: 12pt,
      first-line-indent: 0pt)
    columns(cols, gutter: 14pt, raw(read(path), block: true))
  }
  v(2pt)
  line(length: 100%, stroke: 0.7pt + red)
}

// ============================================================
// COVER
// ============================================================
#page(margin: 0pt, footer: none, {
  // masthead: red script-era wordmark + massive black title
  place(top + left, dx: 0.5in, dy: 0.42in, {
    text(font: f-head, weight: 700, style: "italic", size: 40pt,
      fill: red)[FujiNet]
    text(font: f-head, weight: 400, size: 10pt, fill: red,
      baseline: -22pt)[ ®]
  })
  place(top + left, dx: 2.62in, dy: 0.40in, {
    set par(leading: 0.16em)
    text(font: f-head, weight: 700, size: 33.5pt, fill: ink,
      tracking: 0.5pt)[PROFESSIONAL\ ARCADE]
  })
  // the console: a 1977 halftone-style line drawing, built from shapes
  place(top + left, dx: 2.05in, dy: 2.02in, {
    box(width: 4.3in, height: 2.05in, {
      // body wedge
      place(top + left, dx: 0.25in, dy: 0.42in,
        polygon(fill: gray-l.mix((cream, 25%)), stroke: 1.2pt + ink,
          (0.55in, 0in), (3.5in, 0in), (3.82in, 1.05in), (0in, 1.05in)))
      // top face
      place(top + left, dx: 0.25in, dy: 0.42in,
        polygon(fill: cream2, stroke: 1.2pt + ink,
          (0.55in, 0in), (3.5in, 0in), (3.62in, 0.42in), (0.36in, 0.42in)))
      // cartridge slot door
      place(top + left, dx: 1.95in, dy: 0.62in,
        rect(width: 1.15in, height: 0.34in, fill: scr-bg, stroke: 1pt + ink))
      // the FujiNet cartridge, in red, half-inserted
      place(top + left, dx: 2.08in, dy: 0.50in,
        rect(width: 0.9in, height: 0.2in, fill: red, stroke: 1pt + red-d))
      place(top + left, dx: 2.16in, dy: 0.53in,
        text(font: f-head, weight: 700, size: 7pt, fill: cream)[FUJINET])
      // keypad
      place(top + left, dx: 0.78in, dy: 0.56in, {
        grid(columns: 4, column-gutter: 2.6pt, row-gutter: 2.6pt,
          ..range(24).map(i =>
            rect(width: 0.135in, height: 0.075in, fill: cream,
              stroke: 0.7pt + ink)))
      })
      // badge
      place(top + left, dx: 0.62in, dy: 0.14in,
        rect(fill: cream, stroke: 0.8pt + ink, inset: (x: 5pt, y: 2.6pt), {
          text(font: f-head, weight: 700, style: "italic", size: 6.6pt,
            fill: red)[FujiNet ]
          text(font: f-head, weight: 600, size: 6.6pt,
            fill: ink)[| PROFESSIONAL ARCADE]
        }))
    })
  })
  // rubric
  place(bottom + center, dy: -0.5in,
    text(font: f-head, weight: 700, size: 24pt, fill: red,
      tracking: 1pt)[PROGRAMMERS HANDBOOK])
})

// ============================================================
// INSIDE COVER / CREDITS
// ============================================================
#page(footer: none, {
  v(1fr)
  align(center, {
    text(font: f-head, weight: 700, size: 12pt, fill: red)[CONGRATULATIONS]
    v(6pt)
    box(width: 5.6in, {
      set par(justify: true, leading: 0.55em, first-line-indent: 1.1em)
      set text(size: 9pt)
      [The FujiNet cartridge is the first module of one of the most exciting
      new concepts in Arcade technology. Your Professional Arcade now
      reaches WiFi networks, disk hosts, web servers, and game lobbies the
      world over --- and this handbook will teach you to program all of it,
      in Z80 assembly language and in C.

      Congratulations, you have purchased the finest system available.]
    })
  })
  v(1fr)
  align(center, box(width: 6.4in, {
    set text(size: 6.4pt, fill: gray)
    set par(justify: true, leading: 0.5em, first-line-indent: 0pt)
    [This handbook is a community work of the FujiNet Project, typeset in the
    style of the 1977 _Bally Home Library Computer Owners Manual_ as a loving
    tribute. Bally, Astrocade, and Bally Professional Arcade are trademarks of
    their respective holders; no affiliation with or endorsement by any of
    them is implied. The Astrocade name is used throughout in its
    community-adopted sense for the Bally Arcade/Astrocade console family.
    Every address, opcode and listing is transcribed from the live FujiNet
    project sources and verified against the firmware; the sources-of-truth
    table with commit hashes is in the repository README.]
  }))
  v(0.2in)
  align(center, text(font: f-head, size: 7pt, fill: gray)[
    MANUFACTURED BY THE FUJINET PROJECT · fujinet.online · September 2026])
})

// ============================================================
// TABLE OF CONTENTS
// ============================================================
#page({
  align(center, text(font: f-head, weight: 700, size: 13pt, fill: red,
    tracking: 0.6pt)[TABLE OF CONTENTS])
  v(2pt)
  align(center, text(font: f-head, weight: 700, size: 8.6pt, fill: ink)[Page])
  v(6pt)
  context {
    let hs = query(heading.where(level: 1))
    let rows = hs.map(h => (
      upper(h.body),
      str(counter(page).at(h.location()).first())))
    let half = calc.ceil(rows.len() / 2)
    let render(rs) = grid(columns: (1fr, auto), row-gutter: 5.6pt,
      column-gutter: 4pt,
      ..rs.map(r => (
        box(width: 100%, {
          text(font: f-head, size: 8.2pt, weight: 500, r.at(0))
          box(width: 1fr, repeat(text(size: 8.2pt)[ .], gap: 1pt))
        }),
        text(font: f-head, size: 8.2pt, r.at(1)))).flatten())
    grid(columns: (1fr, 1fr), column-gutter: 26pt,
      render(rows.slice(0, half)),
      render(rows.slice(half)))
  }
})

#counter(page).update(1)
#frontmatter.update(false)

// ============================================================
// CHAPTER: WELCOME TO FUJINET
// ============================================================
#chapter[Welcome to FujiNet]

#twocol[
Your Bally Professional Arcade --- the Astrocade, as its friends call it
--- was sold in 1977 as "the exclusive computer video system that grows as
you grow." It has taken the world a few decades to deliver on that
promise, but here we are: plug the FujiNet cartridge into the slot under
the storage-compartment door, and your Arcade is on the network. WiFi.
Web servers. Disk hosts. Telnet bulletin boards. Multiplayer game
lobbies. All of it reachable from 1.789 megahertz of Z80.

FujiNet is a family of network adapters for classic computers and
consoles. On every platform it presents the same two personalities: the
#emph[Fuji device], which manages the adapter itself (WiFi, host slots,
directories, mounting), and the #emph[network device] --- the famous
`N:` --- which opens connections to the outside world by URL. What
differs per platform is only the plumbing between the machine and the
adapter. On the Astrocade, that plumbing is the most delightfully
strange in the whole family, and it is the subject of this book.

#sub[What this handbook teaches]

You will learn, in order: how the FujiNet cartridge works and why the
Astrocade edition is special (a cartridge port that cannot write!); the
#emph[mailbox] --- the in-memory protocol every program uses to talk to
the cartridge; how to drive it from Z80 assembly language with
`fujilib.inc`, and from C with the Z88DK compiler; the network device
and the Fuji device in working detail; a complete reference for every
command the FujiNet answers on this platform; and then five real,
shipping programs, explained end to end, with their complete listings
in the appendix: #strong[NETCAT], #strong[TEXAS HOLD'EM],
#strong[BATTLESHIP], #strong[FUJITZEE], and #strong[CONFIG].

#sub[What you will need]

#rnum(1) A Bally Arcade/Astrocade --- or MAME's `astrocde` driver with
the FujiNet cartridge device grafted in (the firmware tree's
`pico/astrocade/emu/apply.sh` does the grafting).

#rnum(2) A FujiNet cartridge --- or, under MAME, a running
#emph[fujinet-pc] with its bus-over-IP listener on `127.0.0.1:9995`.

#rnum(3) An assembler (the clients use #emph[zmac 1.3]) and, for the C
chapters, a #emph[z88dk] checkout.

#rnum(4) This handbook, a cup of coffee, and a television set. The
automatic TV protection circuit will forgive long debugging sessions.

#note[Everything network-side --- the 28 URL schemes the `N:` device
speaks, from `TCP:` and `TELNET:` to `HTTPS:`, `JSON:`, `SSH:` and
`GMAIL:` --- is a book of its own: #emph[The FujiNet Network Protocol
Handbook], from this same series. This handbook teaches you to reach
the `N:` device; that one teaches you everything it can say once
reached.]
]

// ============================================================
// CHAPTER: YOUR FUJINET CARTRIDGE
// ============================================================
#chapter[Your FujiNet Cartridge]

#twocol[
The Astrocade cartridge port is the most asymmetric in the FujiNet
family. It carries thirteen address lines (A0--A12), eight data lines
(D0--D7), one pre-decoded #emph[Enable] that asserts for #strong[reads]
in the 2000H--3FFFH window, and power. That is the whole interface.

Count what is missing: no #emph[/RD]. No #emph[/WR]. No #emph[/IORQ].
No clock, no reset line. When your program stores a byte anywhere in
0000H--3FFFH, the console's magic function generator eats the write ---
the cartridge never sees it. A cartridge on this port is, electrically,
a read-only answering machine.

So how can a cartridge possibly be a #emph[network adapter]? The
FujiNet cartridge answers with a trick the Astrocade community has used
for decades --- the 512K homebrew mapper selects banks with reads at
3F80H--3FFFH, and AstroBASIC toggled its tape relay the same way:

#rnum(1) #strong[The console talks by reading.] Certain pages of the
cartridge window are #emph[hotspots]. When the console reads an address
inside one, the cartridge does not care what byte it returns --- it
cares which address was read. #strong[The low eight address bits are
the payload.] Reading 3F41H "sends" the byte 41H.

#rnum(2) #strong[The cartridge talks by repainting.] The cartridge
serves its window from RAM on its own processor. To answer, it simply
changes the bytes it serves; by the time the console reads them, they
are just ROM.

#sub[The tandem inside the cartridge]

Two processors share the cartridge shell. An #strong[RP2040] sits on
the cartridge edge, serves the 8K window at Z80 bus speed, decodes the
hotspot reads, and repaints the reply bytes. It speaks to an
#strong[ESP32-S3] --- a stock FujiNet running the RS232 firmware build
--- over a USB cable, using the same SLIP-framed FujiBus packets that
FujiNet speaks over a serial port elsewhere. The ESP32-S3 is the actual
network adapter: WiFi, TNFS, HTTP, TLS, the lot. The RP2040 is its
translator into read-only cartridge language.

Under MAME there is no silicon, but the shape survives: the MAME
cartridge device compiles the very same mailbox sources, and forwards
the FujiBus packets over TCP (#emph[bus-over-IP]) to a #emph[fujinet-pc]
process on your desk.
]

#fig(caption: [The three-tier stack. The mailbox is the only part your
program ever sees.],
  flow(
    nodebox("YOUR PROGRAM", sub: "Z80 · 2000H-3AFFH", w: 1.28in),
    biarrow(w: 0.58in, label: "mailbox"),
    nodebox("RP2040", sub: "window server", w: 1.12in, bd: red, tc: red),
    biarrow(w: 0.58in, label: "USB CDC"),
    nodebox("ESP32-S3", sub: "BUILD_RS232", w: 1.02in),
    biarrow(w: 0.52in, label: "WiFi"),
    nodebox("THE WORLD", sub: "tnfs · http · tcp", w: 1.05in),
  ))

#twocol[
#sub[The 8K window]

The cartridge window is 8,192 bytes at console addresses
2000H--3FFFH. Your program does not get all of it. The mailbox owns the
top 1,280 bytes; the contract, from `fuji_mailbox.h` (the single source
of truth, compiled into the RP2040 firmware and the MAME model alike):

#rnum(1) Program code and data stay #strong[below 3B00H] --- that is
6,912 bytes for your program, cart offsets 0000H--1AFFH.

#rnum(2) 3B00H--3CFFH is the #strong[reply window] the cartridge
repaints.

#rnum(3) 3D00H--3FFFH are the #strong[hotspot pages] the console reads
to talk.

#rnum(4) At cart offset 1CFCH the image carries the four bytes
`FUJI` --- the #emph[claim signature], a promise that the image keeps
1B00H--1FFFH free so the mailbox may stay alive after the image boots.
An ordinary game (no claim) uses that space for its own bytes, and
booting one shuts the mailbox down for the session.

#sub[A cartridge program, in brief]

An Astrocade cartridge begins with the seven-byte on-board-menu header:
the 55H sentinel, a chain word to `MENUST`, a pointer to the program's
name, and a pointer to its entry. Power the console on and your program
is one keypress away, listed on the SELECT GAME screen like it was 1978.
]

#codepanel("The cartridge header, as every client in this book writes it",
"        ORG     FIRSTC          ; 2000H
        DB      55H             ; menued-cartridge sentinel
        DW      MENUST          ; chain to the on-board SELECT GAME list
        DW      PRGNAM
        DW      PRGSTR
PRGNAM: DB      \"NETCAT\"
        DB      0
PRGSTR: DI                      ; interrupts off, for the program's life
        LD      SP,STACK        ; stack in high screen RAM")

#caution[
Programs that use the mailbox run with interrupts #strong[disabled] ---
`DI` at entry, and no `EI`, ever. With interrupts off the Z80's I
register keeps its reset value of zero, refresh cycles land harmlessly
in on-board ROM space, and the refresh-stray hazard described in the
next chapter never arises. Poll the keypad and handles directly from
ports 10H--17H; the on-board SENTRY system needs interrupts you cannot
give it.
]

// ============================================================
// CHAPTER: THE MAILBOX
// ============================================================
#chapter[The Mailbox]

#twocol[
This chapter is the heart of the handbook. The mailbox is a small,
strict, and rather beautiful protocol; learn its five moves and every
FujiNet feature on this console is yours. All addresses below are
#strong[console addresses] --- cart offset plus 2000H --- exactly as
your program uses them.

#sub[The two directions]

#strong[Console to cartridge: hotspot reads.] Three pages carry
everything you will ever say. A read of `3D00H+r` #emph[arms] mailbox
register `r`. A read of `3E00H+v` delivers the value `v` to the armed
register --- one register write is therefore a #emph[pair] of reads,
back to back. A read of `3F00H+v` appends the byte `v` to the
#emph[TX stream], the outgoing parameter-and-payload buffer.

#strong[Cartridge to console: repainted ROM.] The reply window at
3B00H--3C0CH is plain memory you read whenever you like. 3B00H--3BFFH
is a 256-byte #emph[reply slice]; 3C00H--3C0CH are thirteen status
bytes, listed in Figure 3.

Instruction fetches are harmless. Your code executes from
2000H--3AFFH, far from the hotspot pages, so the thousands of reads the
Z80 performs just running your program never trip anything.
]

#fig(caption: [The cartridge window, as the console sees it.],
  table(columns: (auto, auto, 1fr), align: (left, left, left),
    table.header[Console address][Name][What lives there],
    [`2000H-3AFFH`], [---], [your program: 6,912 bytes of code and data],
    [`3B00H-3BFFH`], [`FNRDATA`], [reply slice: 256 bytes of the current reply],
    [`3C00H-3C0CH`], [`FNACKSQ..FNSECHO`], [thirteen painted status bytes],
    [`3CFCH-3CFFH`], [claim], [`FUJI` signature (cart offset 1CFCH)],
    [`3D00H-3D7FH`], [`FNREGSEL`], [hotspot: read `+r` arms register r],
    [`3D80H-3DEFH`], [`FNBKSEL`], [hotspot: read `+page` selects a bank (v2)],
    [`3DFEH`], [`FNSWAP`], [hotspot: serve the staged boot image (armed only)],
    [`3E00H-3EFFH`], [`FNREGDAT`], [hotspot: read `+v` delivers v to the armed register],
    [`3F00H-3FFFH`], [`FNDATA`], [hotspot: read `+v` appends v to the TX stream],
  ))

#fig(caption: [The thirteen painted status bytes.],
  table(columns: (auto, auto, 1fr),
    table.header[Address][Name][Meaning],
    [`3C00H`], [`FNACKSQ`], [echoes your SEQ when the reply is ready],
    [`3C01H`], [`FNSTATS`], [bit 0 link up, bit 1 busy],
    [`3C02H`], [`FNERR`], [transport verdict of the last transaction (Appendix B)],
    [`3C03H`], [`FNREPLY`], [06H ACK or 15H NAK],
    [`3C04H`], [`FNRXLL`], [reply length, low byte],
    [`3C05H`], [`FNRXLH`], [reply length, high byte],
    [`3C06H`], [`FNBSTAT`], [boot state: idle 0, transfer 1, ready 2, failed 80H],
    [`3C07H`], [`FNBPCT`], [boot progress, 0--100],
    [`3C08H`], [`FNBERR`], [boot error (Appendix B)],
    [`3C09H`], [`FNMAGF`], [the letter `F` --- cartridge presence check],
    [`3C0AH`], [`FNMAGN`], [the letter `N`],
    [`3C0BH`], [`FNPVER`], [mailbox protocol version (2 = banking)],
    [`3C0CH`], [`FNSECHO`], [echoes the slice number, painted #emph[last]],
  ))

#twocol[
#sub[The registers]

Register numbers 00H--0FH mirror the FujiNet Odyssey#super[2] mailbox
where the meanings match; 10H and up are Astrocade-specific.

#dotdef(
  ([`00H` DEVICE], [FujiBus device id: 70H Fuji, 71H network]),
  ([`01H` COMMAND], [FujiBus command id]),
  ([`02H` NPARAM], [how many parameters lead the TX stream]),
  ([`05H` DATA RST], [any value: rewind the TX write pointer]),
  ([`06H` RXSLICE], [which 256-byte reply slice FNRDATA shows]),
  ([`10H` SEQ], [nonzero and ≠ last ACK: launch the transaction]),
  ([`11H` BOOTLOCK], [magic 0B5H arms the ROM swap]),
  ([`12H/13H` BOOTSEL], [magic 0B5H then 4AH: reboot cart to UF2 mode]),
)

#sub[The TX stream]

Every transaction's outgoing bytes form one stream, at most
#strong[320 bytes], with a fixed grammar: first the parameters ---
NPARAM of them, each a #emph[size byte] (1, 2 or 4) followed by that
many value bytes, little-endian --- then the raw payload, whose length
is simply whatever remains.
]

#fig(caption: [The TX stream for `NET_OPEN` with two one-byte parameters
and a devicespec payload.],
  bytefield(
    ([`01`], 26pt), ([`0C`], 26pt),
    ([`01`], 26pt), ([`00`], 26pt),
    ([`N : H T T P S : / / ...`], 150pt),
  ))

#twocol[
#sub[One whole transaction]

Every exchange with the FujiNet --- every one, from a WiFi scan to an
HTTP GET --- is the same five moves:

#rnum(1) #strong[Begin.] Rewind the TX stream (register 05H), then set
DEVICE, COMMAND, and NPARAM.

#rnum(2) #strong[Stream.] Append the parameters and payload with
`3F00H+v` reads.

#rnum(3) #strong[Commit.] Read `FNACKSQ`, add one (wrapping 255 to 1
--- zero is reserved), and write the result to the SEQ register. The
cartridge sees a fresh sequence number and fires the whole stream at
the ESP32-S3 as one FujiBus packet.

#rnum(4) #strong[Wait.] Poll `FNACKSQ` until it equals the number you
wrote. When it does, the reply is painted: check `FNERR` (the transport
verdict), `FNREPLY` (ACK or NAK), and capture the reply length from
`FNRXLL`/`FNRXLH` #emph[immediately] --- those bytes describe the most
recent transaction only.

#rnum(5) #strong[Read.] The first 256 reply bytes are already in
`FNRDATA` (the cartridge republishes slice 0 after every transaction).
For a longer reply, write 1--3 to the RXSLICE register and poll
`FNSECHO` until it echoes your slice number --- the cartridge paints
that echo #emph[last], so when it matches, the slice is whole. Replies
run to 1,024 bytes: four slices.
]

#fig(caption: [A GET_ADAPTERCONFIG_EXTENDED transaction, end to end.],
  seq((("YOUR PROGRAM", 0, ink), ("RP2040 CART", 0, red), ("ESP32-S3", 0, gray)),
    msg(0, 1, "read 3D05H, 3E00H  (rewind TX)"),
    msg(0, 1, "read 3D00H, 3E70H  (DEVICE = 70H)"),
    msg(0, 1, "read 3D01H, 3EC4H  (COMMAND = 0C4H)"),
    msg(0, 1, "read 3D02H, 3E00H  (NPARAM = 0)"),
    msg(0, 1, "read 3D10H, 3E01H  (SEQ = ACKSEQ+1)"),
    msg(1, 2, "FujiBus packet over USB (SLIP)"),
    msg(2, 1, "ACK + 240-byte reply", dashed: true),
    snote(1, [paints slices, status bytes; FNACKSQ last]),
    msg(0, 1, "poll FNACKSQ until it echoes"),
    msg(1, 0, "FNERR=0, FNREPLY=06H, RXLEN=240", dashed: true),
    msg(0, 1, "read FNRDATA bytes; RXSLICE for 256+"),
  ))

#twocol[
#sub[The sequence rule]

Why derive SEQ from the cartridge's own `FNACKSQ` instead of counting
locally? Because the RESET button restarts #emph[your program] --- but
not the cartridge. The cart edge carries no reset line. A program that
kept its own counter would, after a RESET, re-send sequence number 1;
the cartridge, having already acknowledged a 1 in this session, would
ignore it forever. Read the cart's persisted ACKSEQ, add one, wrap 255
to 1, and RESET simply cannot desynchronize you. This rule is inherited
from hard experience on the Intellivision and Odyssey#super[2]
bring-ups; honor it.

#sub[Stray reads, and the defenses against them]

On a port where reading is writing, the design hazard is the read you
did not mean to make. The Z80's refresh machinery performs a memory
read every instruction, with the I register on A8--A15 --- if I ever
pointed at 3DH--3FH while the console's Enable decode passed refresh
cycles, your program would spray phantom hotspot reads. The defenses,
in depth:

#rnum(1) A REGDATA read with no immediately-preceding REGSEL read is a
#strong[no-op] --- arming disarms after one use, so an isolated stray
mutates nothing.

#rnum(2) A transaction launches only on a SEQ value that is nonzero
#emph[and] differs from the last acknowledged one.

#rnum(3) The ROM-swap trigger lives at offset 0FEH of the REGSEL page
--- bit 7 set, where the R register (which only counts through bit 6)
can never wander --- and fires only after BOOTLOCK armed it. Rebooting
the cart to UF2 mode takes #emph[two] full register writes with two
different magics.

#rnum(4) Your own program runs `DI` with I = 0, so refresh lands in
on-board ROM and the whole question is moot.

#sub[Timeouts]

The library waits in quanta of 65,536 polls of `FNACKSQ` --- about two
seconds each at 1.789 MHz. How many quanta to allow is a judgment the
shipping clients have already made for you:
]

#fig(caption: [Timeout quanta used by the shipping clients.],
  table(columns: (auto, auto, 1fr),
    table.header[Operation][Quanta][Why],
    [`NET_OPEN`], [8], [16 s: TLS handshakes and telnet negotiation are slow],
    [`NET_READ`], [8], [16 s: a deferred HTTP GET performs the fetch here],
    [`NET_STATUS`], [4], [8 s],
    [`NET_CLOSE`], [3], [6 s],
    [Fuji device commands], [8], [16 s (CONFIG's `CGO` helper)],
    [`MOUNT_IMAGE`], [60], [~2 min: the ROM push rides inside it, progress on `FNBPCT`],
    [slice select], [1], [a live cart repaints in microseconds],
  ))

#caution[
The reply window is #strong[never cleared] between transactions. A
short reply leaves the stale tail of a longer, older one lying in
`FNRDATA` after it. Capture `FNRXLL`/`FNRXLH` the moment a transaction
acknowledges, believe only that many bytes, and validate what they
claim to be before acting on them. Chapter "The Network Device"
elevates this to a rule with the games' `VALID8` idiom.
]

// ============================================================
// CHAPTER: FIRST CONTACT
// ============================================================
#chapter[First Contact]

#twocol[
Enough theory --- let us shake hands with the cartridge. The smallest
useful FujiNet program does three things: proves the cartridge is
there, runs one transaction, and shows what came back. This chapter
builds it twice --- once in Z80 assembly, once in C --- and every
program in this book, games included, is this program with a bigger
middle.

#sub[Is anybody home?]

The cartridge paints the letters `F` and `N` at 3C09H and 3C0AH. If
they are not both there, you are running on a bare console --- or a
different cartridge --- and must not touch the hotspot pages. Every
client checks this first, and so should you.

#sub[One transaction, no parameters]

`GET_ADAPTERCONFIG_EXTENDED` (command 0C4H to device 70H) is the
perfect first transaction: it takes no parameters and no payload, works
even before WiFi is configured, and returns a 240-byte structure whose
best fields sit conveniently in slice 0: the SSID at offset 0, the
firmware version string at offset 125, and the IP address, already in
dotted-decimal text, at offset 140.
]

#codepanel("First contact, in Z80 (after fujilib.inc; the shape of
pico/astrocade/testrom/fujitest.asm)",
"        CALL    FNCHECK         ; Z set if 'F','N' painted
        JP      NZ,NOCARD

        LD      A,FNDFUJI       ; device 70H
        LD      E,FCACFGX       ; GET_ADAPTERCONFIG_EXTENDED, 0C4H
        LD      L,0             ; no parameters, no payload
        CALL    FNBEGIN
        LD      B,8             ; ~16 s: covers ESP32 enumeration
        CALL    FNCOMMIT
        JR      C,TMOUT         ; carry: the cart never answered
        OR      A
        JR      NZ,LERR         ; FNERR nonzero: no link, timeout...

; Slice 0 already shows the reply: ssid at +0, fn_version at +125,
; sLocalIP at +140 (AdapterConfigExtended).
        LD      HL,FNRDATA+0    ; the SSID, NUL-terminated, 32 max
        LD      B,32
        CALL    SHOWSTR         ; your favorite string printer")

#codepanel("The same contact, in C (the c-demo of Chapter 6, verbatim)",
"    if (!fn_check()) {
        txt_puts(0, 2, \"NO FUJINET CART\");
        for (;;) ;
    }

    fn_begin(FN_DEV_FUJI, FUJI_GET_ADAPTERCONFIG_EXTENDED, 0);
    r = fn_commit(8);
    rx_home();
    if (r != FN_ERR_OK)  { txt_puts(0, 3, \"ERR\");  for (;;) ; }
    if (FN_REPLY != FN_ACK) { txt_puts(0, 3, \"NAK\"); for (;;) ; }

    rx_strn(buf, 0, 20);        /* ssid[33] at offset 0        */
    txt_puts(0, 4, buf);
    rx_strn(buf, 125, 15);      /* fn_version[15] at 125       */
    txt_puts(3, 5, buf);
    rx_strn(buf, 140, 16);      /* sLocalIP[16] at 140         */
    txt_puts(3, 6, buf);")

#twocol[
#sub[What success looks like]

Build either version, boot it, and press #key[1] at the SELECT GAME
menu. Against a live FujiNet (or fujinet-pc under MAME) the screen
answers in about a second:
]

#fig(caption: [The C demo's first contact, exactly as captured from
MAME against a live fujinet-pc.],
  tv("FUJINET C DEMO
PROTO 02 LINK UP

SSID
Dummy Cafe
FW v1.6-2a9e2c23f
IP 127.0.0.1

OK", w: 3.1in))

#twocol[
Read the error paths as carefully as the happy one. #strong[Carry set]
from `FNCOMMIT` means the cartridge itself never acknowledged ---
almost always "no cartridge" or "the RP2040 never enumerated its
ESP32." A #strong[nonzero FNERR] means the cartridge answered but the
transport beneath it failed: `1` no link, `2` timeout, `3` bad frame,
`4` too big. A #strong[NAK in FNREPLY] means everything carried
perfectly and the FujiNet itself refused the command --- wrong
parameters, an unmounted host, a file that is not there.

Three different layers, three different bytes, three different
remedies. Programs that collapse them into one "error" spend their
debugging sessions guessing; the shipping clients never do, and
Chapter "The Network Device" shows the discipline they use instead.
]

// ============================================================
// CHAPTER: THE Z80 LIBRARY
// ============================================================
#chapter[The Z80 Library]

#twocol[
All five programs in this book share one transport file,
`fujilib.inc` --- 223 lines, byte-identical in every repository, and
printed in full in Appendix C. This chapter walks its eight routines;
know them and you know the mailbox by heart. The library hand-mirrors
`fuji_mailbox.h` and is vendored per-program on purpose: a client
builds with no particular firmware branch checked out.

#sub[FNREGWR --- one register write]

The atom everything else is made of: C names the register, A the
value, and the routine issues the REGSEL/REGDATA read pair back to
back. Note the idiom --- the "read" whose result is thrown away is the
message:
]

#codepanel("FNREGWR, fujilib.inc",
"; Write mailbox register: C = register number, A = value.
; Clobbers A,B,D,E.
FNREGWR:
        LD      B,A             ; hold the value
        LD      D,FNRSELP       ; 3DH: the REGSEL page
        LD      E,C
        LD      A,(DE)          ; arm the register
        LD      D,FNRDATP       ; 3EH: the REGDATA page
        LD      E,B
        LD      A,(DE)          ; deliver the value
        RET")

#twocol[
`FNRSELP`/`FNRDATP`/`FNDATAP` hold the page bytes 3DH/3EH/3FH
separately because zmac 1.3 has no `HIGH` operator. Nothing requires
the two reads to be adjacent instructions --- ordinary instruction
fetches in between are invisible to the hotspot decode --- but the
library keeps them adjacent as a matter of hygiene.

#sub[FNTXBYT, FNPARB, FNTXSTR --- feeding the stream]

`FNTXBYT` appends the byte in A with a single `3F00H+v` read.
`FNPARB` wraps it for the parameter grammar: size byte 1, then the
value. `FNTXSTR` streams a NUL-terminated string --- the NUL itself is
#emph[not] sent; string payloads carry their length by the packet's
edge, not by a terminator. A two-byte parameter is three `FNTXBYT`
calls by hand: size byte `2`, low, high. (CONFIG wraps that as
`FNPARW` in its `fujicmd.inc`.)

#sub[FNBEGIN --- opening the envelope]

A = device, E = command, L = parameter count; the routine rewinds the
TX pointer (register 05H) and writes DEVICE, COMMAND, NPARAM. After
`FNBEGIN` returns, the stream is empty and waiting.

#sub[FNCOMMIT --- the moment of truth]

B = timeout in quanta of 65,536 polls (about 2 s each). It computes
the sequence rule from Chapter "The Mailbox" --- ACKSEQ + 1, wrap 255
to 1 --- writes SEQ, and polls. On success it returns with A = `FNERR`
and flags set from `OR A` (so `JR NZ,error` reads naturally); on
timeout it returns with carry set.
]

#codepanel("FNCOMMIT, fujilib.inc -- the sequence rule in the flesh",
"FNCOMMIT:
        LD      A,(FNACKSQ)
        INC     A
        JR      NZ,FNCMS
        INC     A               ; 255 wraps past the reserved 0
FNCMS:  LD      H,A             ; expected ACKSEQ
        LD      C,FRSEQ
        CALL    FNREGWR
FNCMO:  LD      DE,0            ; inner: 65536 polls, ~2 s at 1.789 MHz
FNCMI:  LD      A,(FNACKSQ)
        CP      H
        JR      Z,FNCMOK
        DEC     DE
        LD      A,D
        OR      E
        JR      NZ,FNCMI
        DJNZ    FNCMO
        SCF                     ; timed out
        RET
FNCMOK: LD      A,(FNERR)
        OR      A               ; clears carry
        RET")

#twocol[
#sub[FNSLICE --- turning the reply window]

A = slice 0--3. Writes the RXSLICE register, then polls `FNSECHO`
until it echoes the slice number. The echo byte is painted #emph[last]
in every repaint, which is the whole reason it exists: on real
hardware the RP2040 repaints asynchronously while the Z80 keeps
running, and a client that read the slice without polling would race
the paint. (The Odyssey#super[2] mailbox lacks this byte; its emulator
model admits it cannot catch a client that forgets. Here, forgetting
is impossible --- there is nothing else to wait on.)

#sub[FNCHECK --- is anybody home?]

Compares 3C09H/3C0AH against `F`,`N`; returns with Z set when the
cartridge is present. Call it once at boot, before any hotspot is
touched.

#sub[RXGETB, RXGETW, RXSTRN --- the flat window]

`state.inc` (54 lines, shared by netcat and all three games) folds the
four slices into one flat 0--1023 address space: `RXGETB` takes an
offset in HL, switches slices only when the high byte changes (a
one-byte cache, `CURSLC`), and returns the byte. `RXGETW` reads a
little-endian word; `RXSTRN` copies a bounded, NUL-stopping string.
One rule rides with the cache: #strong[every transaction republishes
slice 0], so the round-trip code re-homes `CURSLC` to 0 after each
commit.

#sub[Building an 8K client]

The build is zmac plus forty lines of shell, and the layout contract
is enforced, not hoped for: assemble, fail if the image crosses 1B00H,
pad to exactly 8,192 bytes, stamp `FUJI` at 1CFCH, then run
`checkrom.py` (size, sentinel, claim, and not one stray byte in the
mailbox pages). NETCAT adds `checksize.py`, which reads the assembler
listing and prints a per-module budget table --- luxury living on a
6,912-byte budget.
]

// ============================================================
// CHAPTER: C ON THE PROFESSIONAL ARCADE
// ============================================================
#chapter[C on the Professional Arcade]

#twocol[
Every shipping Astrocade client is assembly --- the fujinet-lib C
library has no Astrocade port, and the cross-platform game clients'
shared C core does not fit this machine. But the mailbox itself is
nothing but memory reads, and memory reads are something C does
perfectly well. This chapter builds a complete, working C client with
#emph[z88dk]: the `c-demo` project, shipped whole in `listings/c-demo/`
and printed in Appendix D. It compiles, boots, and talks --- the
screen in Figure 5 is its output, captured from MAME against a live
fujinet-pc.

#sub[The target, honestly stated]

z88dk ships an `astrocde` target --- and marks it #emph[incomplete].
What exists: a correct `crt0` (ORG 2000H, the 55H menu header, entry
glue) and the HVGLIB equates. What is missing: the target C library,
including the console driver the classic runtime insists every target
provide. The gap is smaller than it sounds. Three additions make the
target usable for mailbox work:

#rnum(1) a one-line `fputc_cons_native` stub (the demo paints screen
RAM itself);

#rnum(2) a tiny `port_out` in assembly --- sccz80 has no port
intrinsics here, and the screen needs five OUTs at boot;

#rnum(3) pragmas that place things: BSS above the visible screen,
the stack below the BIOS cells, and `DI` first thing.
]

#codepanel("The whole build recipe (c-demo build.sh)",
"zcc +astrocde main.c text.c fujinet.c support.asm \\
    -o build/cdemo.raw -m \\
    -pragma-define:CRT_ENABLE_EIDI=1 \\
    -pragma-define:REGISTER_SP=0x4fc0 \\
    -pragma-define:CRT_ORG_BSS=0x4d00 \\
    -pragma-define:CRT_MODEL=1
# then: pad to 8192, stamp FUJI at 0x1CFC, checkrom.py -- same as asm")

#twocol[
`CRT_ENABLE_EIDI=1` makes the crt0 execute `DI` before `main` --- the
mailbox contract from Chapter "Your FujiNet Cartridge."
`CRT_MODEL=1` selects the ROM model, so initialized data is copied
from the cartridge image into RAM at startup. The demo compiles to
about 2.7K of the 6,912-byte budget.

#sub[Reading as writing, in C]

The C rendering of `FNREGWR` needs one idiom: the hotspot "write" is a
read whose #emph[address] matters and whose result does not. Assigning
a `volatile` read to a `volatile` sink guarantees the compiler emits
the load, never elides it, and never reorders it:
]

#codepanel("fujinet.c -- the transport atoms",
"static volatile unsigned char fn_sink;

#define FN_HOT(page, v) (fn_sink = (page)[v])

void fn_regwr(unsigned char reg, unsigned char val)
{
    FN_HOT(FN_REGSEL, reg);     /* arm the register    */
    FN_HOT(FN_REGDATA, val);    /* deliver the value   */
}

void fn_tx_byte(unsigned char v)
{
    FN_HOT(FN_DATA, v);
}")

#codepanel("fujinet.c -- fn_commit, the sequence rule again",
"unsigned char fn_commit(unsigned char quanta)
{
    unsigned char want;
    unsigned int spin;

    want = FN_ACKSEQ + 1;
    if (want == 0)
        want = 1;
    fn_regwr(FN_REG_SEQ, want);
    while (quanta--) {
        spin = 0;
        do {
            if (FN_ACKSEQ == want)
                return FN_ERRBYTE;
        } while (--spin != 0);  /* 65,536 polls per quantum */
    }
    return FN_ERR_CLIENT_TIMEOUT;   /* 0xFF */
}")

#caution[
A compiler hazard, found while verifying this very chapter: sccz80
(z88dk `3bd06cad`, July 2026) silently #strong[miscompiles a constant
subscript on a cast-constant pointer]. `FN_RDATA[2]` compiles to the
constant 2 --- not a memory read --- with only a "value out of range"
warning as the tell. A #emph[variable] subscript compiles correctly,
and so does a dereference of a constant sum. The demo's `fujinet.h`
therefore defines `FN_RDATA_B(i)` as
`(*(volatile unsigned char *)(0x3b00 + (i)))` and uses it for every
constant offset. Treat that warning as an error whenever you see it.
]

#twocol[
#sub[The rest of the demo]

`fujinet.c` continues exactly along `fujilib.inc`'s lines ---
`fn_begin`, `fn_slice`, the flat-window readers `rx_getb`/`rx_getw`/
`rx_strn` with the same slice cache and the same re-home-after-commit
rule --- and then the N: round trip in netcat's shape: `net_open`,
`net_close`, `net_status` (filling `net_avail`, `net_connected`,
`net_devstatus`), `net_read` (capturing `net_rxlen` immediately), and
`net_write` with its count-rides-twice rule. Chapter "The Network
Device" explains those; the point here is that the C and assembly
libraries are the #emph[same library] in two spellings, and this
handbook's examples come in pairs for exactly that reason.

`text.c` is CONFIG's byte-aligned 5×7 blitter in C: BIOS glyph data at
08E4H for 20H--63H, its own 26-glyph lowercase table, two bytes per
scanline at 2bpp, twenty columns. `main.c` is Chapter "First Contact."

#sub[Running it]

`make` builds `build/cdemo.bin` --- 8,192 bytes, checkrom-clean.
`make run` boots it in MAME against a fujinet-pc; `make smoke` does the
same headless, presses #key[1] on the menu itself, and snapshots the
result. The demo appears on the SELECT GAME menu under the crt0's
built-in name, `z88dk` --- renaming it means bringing your own crt0,
a fine first exercise.

One honest limitation: a C quantum is a little #emph[longer] than an
assembly quantum --- the poll loop runs through compiled code --- so
timeouts stretch by roughly half. The counts in this book are already
generous; keep them.
]

// ============================================================
// CHAPTER: THE NETWORK DEVICE
// ============================================================
#chapter[The Network Device]

#twocol[
Device `71H` is the first of eight network units --- N1: through N8:,
71H--78H --- each an independent connection to somewhere in the world.
Every Astrocade client so far uses only N1:. You give it a
#emph[devicespec] --- a URL with an `N:` prefix --- and from then on it
is a byte pipe with a status word.

#spec("N:TELNET://BBS.FOZZTEXX.COM/")
#spec("N:HTTPS://fujitzee.carr-designs.com/state?bin=1")

The scheme decides everything: `TCP:`, `TELNET:`, `HTTP:`, `HTTPS:`,
`TNFS:`, `JSON:`, `SSH:`, `UDP:` and twenty more, each with its own
grammar and behavior. This handbook deliberately does not repeat that
material: it fills a book of its own, #emph[The FujiNet Network
Protocol Handbook], and everything there applies to the Astrocade
verbatim once you can drive the five commands below.

#sub[The lifecycle]

#dotdef(
  ([OPEN `4FH`], [mode and translation params, devicespec payload]),
  ([STATUS `53H`], [four reply bytes: bytes waiting, connected, device status]),
  ([READ `52H`], [up to 1,024 bytes into the reply window]),
  ([WRITE `57H`], [bytes out --- NETCAT is the family's first user]),
  ([CLOSE `43H`], [hang up --- and #emph[when] you send it is a doctrine]),
)

#sub[OPEN]

Two one-byte parameters, then the devicespec as payload. The
#emph[mode] every client here uses is `0CH` --- read/write for a
socket, and the same 12 performs a GET on an HTTP adapter. The
#emph[translation] is `0` --- none; the Astrocade's 4×6 font speaks
ASCII natively and the games' wire format is binary anyway. NETCAT
appends `?cols=40&rows=13` to a bare TELNET spec --- the TELNET
adapter reads the terminal size off the query string and only then
offers NAWS to the far end.
]

#codepanel("NOPEN, netcat net.inc -- open the devicespec at HL",
"; NOPEN: open the N: connection. HL = devicespec (NUL-terminated).
; Carry set on failure.
NOPEN:  PUSH    HL
        LD      A,NETDEV        ; 71H
        LD      E,NCOPEN        ; 'O'
        LD      L,2             ; two parameters
        CALL    FNBEGIN
        LD      A,NMRDWR        ; mode 0CH: read/write
        CALL    FNPARB
        LD      A,NTRNONE       ; translation 0: none
        CALL    FNPARB
        POP     HL
        CALL    FNTXSTR         ; the devicespec is the payload
        LD      B,8             ; 16 s: TLS handshakes are slow
        CALL    FNCOMMIT
        RET     C
        JR      NZ,NOPBAD
        LD      A,(FNREPLY)
        CP      FCACK
        RET     Z               ; open, carry clear
NOPBAD: SCF
        RET")

#twocol[
#sub[STATUS]

Two zero parameters (a quirk the firmware expects), and the reply is
four bytes in slice 0:
]

#fig(caption: [The NET_STATUS reply.],
  bytefield(
    ([`avail lo`], 58pt), ([`avail hi`], 58pt),
    ([`connected`], 62pt), ([`devstatus`], 62pt)))

#twocol[
`avail` is how many bytes wait to be read. `connected` is the socket
truth. `devstatus` is the protocol adapter's verdict: `1` means
SUCCESS, `136` end-of-file. The two flags earn their keep in
different loops: the #strong[games] gate rendering on
`devstatus == 1` --- an HTTP GET is performed #emph[at read time], so
an error page still has a readable body and `connected` alone would
happily render garbage --- while #strong[NETCAT] watches `connected`,
because on a live socket EOF is a hangup, not an error.

#sub[READ]

One two-byte parameter: how many bytes you want, clamped to what
STATUS said was waiting and to 1,024. On ACK, capture
`FNRXLL`/`FNRXLH` #emph[that instant] --- the next transaction, any
transaction, repaints them.

#sub[WRITE]

NETCAT's contribution to the family. One two-byte parameter carries
the count, then the bytes themselves follow as payload --- the count
rides #emph[twice], once as the parameter and once implicitly as the
payload the cartridge measures. NETCAT caps a write at 128 bytes,
comfortably inside the 320-byte TX stream with three bytes spent on
the length parameter.

#sub[CLOSE]

No parameters. The doctrine is #emph[when]: see Rule 1.

#sub[The three rules]

Every game client learned these the hard way; they are the difference
between a demo and a product.

#rnum(1) #strong[CLOSE at the start of the next request, never after
the read.] Every transaction repaints the whole reply window, and a
CLOSE reply is empty. The games render their screens straight out of
the reply window between polls --- close after read, and you have just
erased the state you were about to draw. NETCAT is the deliberate
exception: it consumes each read immediately and holds one connection
open for the session.

#rnum(2) #strong[The settle loop.] The ESP32 reports STATUS the moment
#emph[some] of a response has arrived. A game polls STATUS until two
consecutive `avail` readings agree (bounded at 20 tries, ~3 frames
apart), and only then reads. NETCAT skips this on purpose --- a live
stream never produces two equal readings, and a terminal wants bytes
now, not settled.

#rnum(3) #strong[Validate before believing --- VALID8.] The reply
window is never cleared; a short reply leaves a stale tail. Check the
captured length against the format's minimum, check enums against
their ranges, check counts against their caps --- then act.
]

#codepanel("APICALL, battleship net.inc -- one whole HTTP round trip,
rules 1 and 2 in the flesh",
"APICALL: LD     (V_URL),A       ; which URL BLDURL builds
        CALL    NCLOSE          ; rule 1: the PREVIOUS connection
        CALL    NOPEN
        RET     C
        XOR     A
        LD      (PRVAVL),A
        LD      (PRVAVL+1),A
        LD      B,20            ; rule 2: settle-loop bound
APSET:  PUSH    BC
        CALL    NSTATUS
        POP     BC
        JR      C,APCFL
        LD      HL,(AVAIL)
        LD      A,H
        OR      L
        JR      Z,APAGN         ; nothing at all yet
        LD      DE,(PRVAVL)
        OR      A
        SBC     HL,DE
        JR      Z,APRD          ; two readings agree: it has landed
APAGN:  LD      HL,(AVAIL)
        LD      (PRVAVL),HL
        LD      DE,4000         ; ~3 frames between polls
APDLY:  DEC     DE
        LD      A,D
        OR      E
        JR      NZ,APDLY
        DJNZ    APSET
APCFL:  CALL    NCLOSE
        SCF
        RET
APRD:   CALL    NREAD
        JR      C,APCFL
        ; falls through into VALID8 -- rule 3")

#note[The `N:` device also speaks structured channels --- JSON mode
with PARSE and QUERY, seek and tell on file-like protocols, rename,
delete and mkdir on filesystem ones. The Astrocade games chose raw
binary (`?bin=1`) over JSON to keep parsing on the server, but the
whole command set answers on this platform and Chapter "Command
Reference: The Network Device" documents every command.]

// ============================================================
// CHAPTER: THE FUJI DEVICE
// ============================================================
#chapter[The Fuji Device]

#twocol[
Device `70H` is the adapter itself: WiFi, host slots, directories,
disk images, and a drawer of utilities. CONFIG is its natural habitat
--- the only shipping Astrocade client that speaks to it --- and this
chapter follows CONFIG's road through it. The complete command cards
are in Chapter "Command Reference: The Fuji Device"; here is how the
roads fit together.

#sub[Getting on the air]

CONFIG's WiFi checkout is four commands long: `GET_WIFI_ENABLED`
(0EAH) --- is there a radio at all; `GET_WIFISTATUS` (0FAH) --- one
reply byte, `3` means connected; `GET_SSID` (0FEH) --- the current
network and password, a 97-byte reply; and if you need a new network,
`SCAN_NETWORKS` (0FDH) returns a count, `GET_SCAN_RESULT` (0FCH) takes
an index parameter and returns 34 bytes --- `ssid[33]` and an RSSI
byte, a negative dBm you can bar-graph.

Joining is `SET_SSID` (0FBH), and it carries two famous sharp edges:
the firmware demands #strong[at least one parameter, whose value it
ignores], and the payload must be #strong[exactly 97 bytes] ---
`ssid[33] + password[64]`, NUL-padded to their full widths.

#sub[The payload-shape rules]

Behind those edges is one firmware fact worth internalizing: the
transaction layer's `transaction_get()` #strong[fails a short read].
A command that expects a struct wants #emph[all] of it:

#rnum(1) `OPEN_DIRECTORY` and `SET_DEVICE_FULLPATH` always send a full
#strong[256-byte, NUL-padded] payload.

#rnum(2) `SET_SSID` sends #strong[exactly 97].

#rnum(3) `COPY_FILE` is the exception that proves the rule: its
payload is read as a #emph[string], so it goes at #strong[exact
length] --- one padding NUL would land inside the destination
filename. And its two host-slot parameters are #strong[1-based],
unlike everywhere else.

#sub[Hosts and directories]

Eight host slots of 32 bytes each --- `READ_HOST_SLOTS` (0F4H) returns
all 256 in one reply, which is to say: #emph[exactly slice 0].
`MOUNT_HOST` (0F9H) takes the slot number; then `OPEN_DIRECTORY`
(0F7H, host parameter, path + NUL + filter payload),
`SET_DIRECTORY_POSITION` (0E4H, a two-byte position),
`READ_DIR_ENTRY` (0F6H, maxlen and a flags parameter), and
`CLOSE_DIRECTORY` (0F5H). Directory entries arrive as names with a
trailing `/` on subdirectories; end of directory is #strong[exactly
two 7FH bytes]. Keep `maxlen` away from 31 --- that magic value asks
the firmware to append packed detail bytes meant for other platforms'
file pickers.
]

#codepanel("HWRITE, config hosts.inc -- the reply window IS the buffer",
"; Rename host slot A to the string at HL: a fresh READ_HOST_SLOTS for
; freshness, then WRITE_HOST_SLOTS streamed byte-for-byte out of the
; reply window itself, substituting only the edited slot. No 256-byte
; RAM mirror ever exists -- there is nowhere to put one. The one rule:
; no transaction may run between the read and the streamed write.
        CALL    CRHSL           ; READ_HOST_SLOTS -> slice 0
        RET     C
        LD      A,FNDFUJI
        LD      E,FCWHSL        ; WRITE_HOST_SLOTS
        LD      L,0
        CALL    FNBEGIN
        LD      DE,FNRDATA      ; stream 8 x 32 bytes back out of
        ...                     ; the painted reply, swapping in the
        ...                     ; edited slot as it passes")

#twocol[
That fragment deserves its caution: CONFIG's on-screen editor is
#strong[transaction-free by contract] so that nothing can repaint the
reply window between the freshness read and the streamed write. On a
machine with 4K of RAM, total, the reply window is not a copy of the
state --- it #emph[is] the state.

#sub[The utility drawer]

The Fuji device also answers `GET_ADAPTERCONFIG_EXTENDED` (0C4H ---
Chapter "First Contact"), `RANDOM_NUMBER` (0D3H, four bytes of
entropy), `GENERATE_GUID` (0BBH), app keys (0DCH--0DBH: per-app
key/value storage on the adapter's SD card --- TEXAS HOLD'EM already
declares its lobby-key constants for the day it enrolls), base64 and
hash engines (0D0H--0C2H: feed data in, compute, read the digest out
--- an SHA256 on call from a Z80!), and QR code rendering
(0BCH--0BFH). Command cards for all of them follow in the reference.
]

// ============================================================
// CHAPTER: BOOT, SWAP, AND BANKING
// ============================================================
#chapter[Boot, Swap, and Banking]

#twocol[
The finale of CONFIG's road: pick a program from a network host and
#emph[become] it. On other FujiNets that is "mount the disk and
reboot." On a console whose cartridge port cannot write, it is a small
magic trick in three acts.

#sub[Act one: the push]

`SET_DEVICE_FULLPATH` (0E2H: device slot 0, host, mode 1-read, path
padded to 256) names the file. Then `MOUNT_IMAGE` (0F8H) --- and here
the Astrocade departs from every sibling. While your MOUNT_IMAGE
transaction is #emph[still outstanding], the ESP32-S3 fetches the file
and streams it to the RP2040 over a side channel: FujiBus frames
addressed to device 0FFH (DBC) --- an OPEN carrying a stream id and a
32-bit size, WRITE after WRITE of sector-sized chunks, then a CLOSE
that commits (a CLOSE with a 1-byte payload aborts). Stream id 0 is
the ROM; stream id 1, pushed first when one exists, is the image's
`.cfg` sidecar.

Your program sees all this as theater on the status bytes: `FNBSTAT`
walks idle → transfer → ready (or 80H, failed, with the reason in
`FNBERR`), and `FNBPCT` climbs 0 to 100. CONFIG's `BCOMMIT` is
`FNCOMMIT`'s shape with a 60-quantum patience and a progress bar
painted from `FNBPCT` between polls --- passive reads only; never
touch a hotspot while the push is in flight.

#sub[Act two: the swap]

When `FNBSTAT` says ready: write BOOTLOCK (register 11H) = 0B5H to arm
the trigger, copy a stub into screen RAM, and jump to it. The stub
must run from RAM for the best reason imaginable --- the swap replaces
#strong[every byte of the cartridge window, including the code that
triggers it.]
]

#codepanel("The swap stub, config boot.inc -- ten bytes that change the game",
"BREADY: LD      A,100
        CALL    BARUPD          ; progress bar: done
        LD      C,FRBOOTL
        LD      A,FNBLMAG       ; 0B5H
        CALL    FNREGWR         ; arm the trigger
        LD      HL,BSTUB
        LD      DE,STUB         ; STUB EQU 4FE0H: top of screen RAM
        LD      BC,BSTUBL
        LDIR
        JP      STUB
BSTUB:  LD      A,(FNSWAP)      ; 3DFEH: the cart flips between this
        JP      0               ; read and the next fetch
BSTUBL  EQU     $-BSTUB")

#twocol[
`JP 0` cold-starts the on-board OS, which walks the freshly served
image's 55H menu header, and the pushed program is one keypress away
--- delivered over WiFi to a 1978 console, wearing the OS's own menu
like it came in a Videocade box.

#sub[Act three: after the swap]

What the mailbox does next depends on what was pushed. An image
carrying the `FUJI` claim at 1CFCH --- every client in this book ---
keeps the mailbox alive: the OS menu itself is now served through it,
and CONFIG can be re-entered by the BOOTLOCK road again. An ordinary
game image makes no such promise, so the mailbox goes dark for the
session; RESET all you like, the game keeps working exactly as a real
cartridge would.

#sub[Banking: past 8K]

Mailbox protocol version 2 (check `FNPVER`) adds two banking schemes,
mutually exclusive by construction:

#strong[GAME banking] --- for pushed images of exactly 256K or 512K
with no claim: the established homebrew mapper, byte-compatible with
MAME's `rom_256k`/`rom_512k`. 2000H--2FFFH is fixed to the image's
last 4K bank; a read in 3FC0H--3FFFH (256K; 3F80H up for 512K)
selects the bank #emph[and returns the bank number as the data byte].
Those hotspots live inside the FNDATA page --- which is exactly why
game banking exists only with the mailbox dead.

#strong[APPBANK] --- for claimed images of 8K + k×4K, up to 112 extra
pages: the mailbox stays fully alive. One read at `FNBKSEL+page`
(3D80H+page) maps image page 0--111 into 2000H--2FFFH; the high half
never moves, because your code, the reply window and the hotspots
live there. The select completes before the next read; the byte it
returns is undefined. Two etiquette rules: never execute from
2000H--2FFFH while switching away from the page the PC stands in, and
stamp every selectable page with the 7-byte sentinel header whose
start vector re-selects page 0 --- console RESET does not, because the
cartridge never hears it. The firmware's `tools/mkbanked.py` stamps
exactly that.
]

#caution[
On a cartridge serving a plain 8K image, `FNBKSEL` reads are no-ops
--- probing is safe. But `FNSWAP` is #strong[armed-only] everywhere:
without the BOOTLOCK magic, reading 3DFEH does nothing, and with it,
it does everything. Arm it as the last act before the stub, never
earlier.
]

// ============================================================
// CHAPTER: COMMAND REFERENCE -- THE FUJI DEVICE
// ============================================================
#chapter[Command Reference: The Fuji Device]

#block({
  set par(first-line-indent: 0pt)
  [Every command device `70H` answers on the Astrocade, verified against
  the firmware dispatch tables (`fujiDevice.cpp`, its four mixins, and the
  RS232 fall-through switch). Conventions: #emph[nparam] is the value for
  the NPARAM register; a #emph[byte] parameter is `FNPARB` (size 1), a
  #emph[word] is size 2, little-endian; replies land in the reply window
  and "slice 0" means the first 256 bytes. Any command not listed here is
  answered with a NAK on this platform --- the closing table names them.]
})

#sect[WiFi and the adapter]

#cmd("RESET", code: "0FFH", dev: "70H", nparam: "0",
  reply: [ACK, then the adapter reboots],
  [Reboots the ESP32-S3. The RP2040 and the mailbox stay up; the link
  bit in `FNSTATS` drops until the adapter re-enumerates (allow ~16 s,
  the same 8 quanta as an OPEN).])

#cmd("GET_WIFI_ENABLED", code: "0EAH", dev: "70H", nparam: "0",
  reply: [1 byte: 1 = radio enabled],
  [CONFIG's first WiFi question (`wifi.inc`). A 0 here means the radio
  is administratively off --- scanning and joining will refuse.])

#cmd("GET_WIFISTATUS", code: "0FAH", dev: "70H", nparam: "0",
  reply: [1 byte: 3 = connected; anything else = not (yet)],
  [The poll target while a join is in flight. CONFIG polls it after
  SET_SSID until it turns 3 or patience runs out.])

#cmd("GET_SSID", code: "0FEH", dev: "70H", nparam: "0",
  reply: [97 bytes: `ssid[33]` + `password[64]`, NUL-padded],
  [The current network configuration. Yes, the password comes back in
  clear text --- your Arcade is a trusted friend.])

#cmd("SCAN_NETWORKS", code: "0FDH", dev: "70H", nparam: "0",
  reply: [1 byte: number of networks found],
  [Starts a fresh scan and blocks until it finishes. Follow with
  GET_SCAN_RESULT once per index.])

#cmd("GET_SCAN_RESULT", code: "0FCH", dev: "70H", nparam: "1",
  params: [byte: result index, 0-based],
  reply: [34 bytes: `ssid[33]` + `rssi` (signed dBm)],
  [One scanned network. CONFIG bar-graphs the RSSI byte at offset 33 ---
  remember it is negative dBm, so closer to zero is stronger.])

#cmd("SET_SSID", code: "0FBH", dev: "70H", nparam: "1",
  params: [byte: any value --- #strong[required but ignored]],
  payload: [#strong[exactly 97 bytes]: `ssid[33]` + `password[64]`,
    NUL-padded to their full widths],
  reply: [ACK on join, NAK on refusal],
  [Joins a network and saves it as the default. The two sharp edges are
  in bold; a short payload fails the transaction outright
  (`transaction_get` refuses short reads).])

#cmd("GET_ADAPTERCONFIG", code: "0E8H", dev: "70H", nparam: "0",
  reply: [140 bytes: `ssid[33]` `hostname[64]` `localIP[4]` `gateway[4]`
    `netmask[4]` `dnsIP[4]` `mac[6]` `bssid[6]` `fn_version[15]`],
  [The compact adapter picture, addresses in binary. Prefer the extended
  form below --- its text fields save you a print-an-IP routine.])

#cmd("GET_ADAPTERCONFIG_EXTENDED", code: "0C4H", dev: "70H", nparam: "0",
  reply: [240 bytes: the 140 above, then `sLocalIP[16]` at offset 140,
    `sGateway[16]` at 156, `sNetmask[16]` at 172, `sDnsIP[16]` at 188,
    `sMacAddress[18]` at 204, `sBssid[18]` at 222 --- all dotted/colon
    text, NUL-terminated],
  [The first-contact command of Chapter 4. The three fields every
  status screen wants sit in slice 0: SSID at +0, `fn_version` at +125,
  IP text at +140.])

#cmd("STATUS", code: "53H", dev: "70H", nparam: "1",
  params: [byte: request type --- 0 connection error, 1 mount times,
    2 netmask, 3 gateway, 4 DNS],
  reply: [type 1: one mount timestamp per device slot (zero =
    unmounted); other types currently 4 zero bytes],
  [The RS232 build requires the parameter; omitting it is an error.
  Mostly a diagnostic.])

#cmd("DEVICE_READY", code: "00H", dev: "70H", nparam: "0",
  reply: [512 bytes, every one the letter `A`],
  [The bus test card. Two slices of solid 41H --- if they arrive
  intact, your mailbox, the RP2040, the USB link and the ESP32-S3 are
  all telling the truth.])

#sect[Hosts, slots, and mounting]

#cmd("READ_HOST_SLOTS", code: "0F4H", dev: "70H", nparam: "0",
  reply: [256 bytes: 8 slots × `hostname[32]` --- exactly slice 0],
  [The host list, one transaction, no slicing needed. CONFIG renders
  its HOSTS screen straight from the reply window.])

#cmd("WRITE_HOST_SLOTS", code: "0F3H", dev: "70H", nparam: "0",
  payload: [256 bytes: all 8 slots, full width],
  reply: [ACK],
  [All-or-nothing: there is no write-one-slot command. CONFIG's
  `HWRITE` streams the payload straight back out of a fresh
  READ_HOST_SLOTS reply, substituting the edited slot in flight ---
  the "reply window IS the buffer" idiom of Chapter 8.])

#cmd("MOUNT_HOST", code: "0F9H", dev: "70H", nparam: "1",
  params: [byte: host slot, #strong[0-based]],
  reply: [ACK, or NAK if the host is unreachable],
  [Connects to the named host (TNFS, SMB, ...). Required before
  OPEN_DIRECTORY or a boot.])

#cmd("UNMOUNT_HOST", code: "0E6H", dev: "70H", nparam: "1",
  params: [byte: host slot], reply: [ACK],
  [Releases the connection. CONFIG never bothers; sessions are short.])

#cmd("SET_HOST_PREFIX / GET_HOST_PREFIX", code: "0E1H / 0E0H", dev: "70H",
  nparam: "1", params: [byte: host slot; SET also carries the prefix
  string as payload], reply: [GET: the prefix string],
  [A per-host working directory prepended to relative paths. The
  Astrocade clients keep absolute paths instead.])

#cmd("READ_DEVICE_SLOTS", code: "0F2H", dev: "70H", nparam: "0",
  reply: [38 bytes per device slot: `hostSlot` `mode`
    `filename[36]`],
  [What is (configured to be) in each virtual drive. The Astrocade
  boots images rather than serving drives, so CONFIG leaves this
  screenless --- but the command answers.])

#cmd("WRITE_DEVICE_SLOTS", code: "0F1H", dev: "70H", nparam: "0",
  payload: [the full device-slot table, as read], reply: [ACK],
  [The paired writer, same all-or-nothing contract as host slots.])

#cmd("SET_DEVICE_FULLPATH", code: "0E2H", dev: "70H", nparam: "3",
  params: [bytes: device slot, host slot, mode (1 = read)],
  payload: [#strong[256 bytes]: the path, NUL-padded],
  reply: [ACK],
  [Names the file for a device slot. On the Astrocade this is the first
  half of booting: CONFIG points slot 0 at the chosen ROM
  (`boot.inc`).])

#cmd("GET_DEVICE_FULLPATH", code: "0DAH", dev: "70H", nparam: "1",
  params: [byte: device slot], reply: [the stored path],
  [Reads back what SET stored.])

#cmd("MOUNT_IMAGE", code: "0F8H", dev: "70H", nparam: "2",
  params: [bytes: device slot, access mode (1 read, 2 write)],
  reply: [ACK when the mount --- and on this platform, the push ---
    completes],
  [The second half of booting, and the Astrocade's most theatrical
  command: while it is outstanding, the adapter streams the image to
  the cartridge over the DBC side channel and `FNBSTAT`/`FNBPCT`
  narrate the progress. Allow 60 quanta and paint a progress bar
  (Chapter 9). Plain disk-style mounts also work --- but nothing on
  this console reads sectors yet.])

#cmd("UNMOUNT_IMAGE", code: "0E9H", dev: "70H", nparam: "1",
  params: [byte: device slot], reply: [ACK], [Releases the image.])

#cmd("MOUNT_ALL", code: "0D7H", dev: "70H", nparam: "0", reply: [ACK],
  [Mounts every configured slot in one go --- the other platforms'
  "boot my usual setup" button.])

#cmd("NEW_DISK", code: "0E7H", dev: "70H", nparam: "0",
  payload: [262 bytes: `numSectors` (word) `sectorSize` (word)
    `hostSlot` `deviceSlot` `filename[256]`],
  reply: [ACK on creation],
  [Creates a blank image on a host. Full-struct payload, NUL-padded
  filename --- the 256-pad rule again.])

#cmd("SET_BOOT_MODE / CONFIG_BOOT", code: "0D6H / 0D9H", dev: "70H",
  nparam: "1", params: [byte: mode], reply: [ACK],
  [Selects what the adapter offers at power-on on disk-serving
  platforms. CONFIG #strong[deliberately never sends] CONFIG_BOOT ---
  on this console the mailbox claim, not a config flag, decides who
  boots.])

#sect[Directories]

#cmd("OPEN_DIRECTORY", code: "0F7H", dev: "70H", nparam: "1",
  params: [byte: host slot],
  payload: [#strong[256 bytes]: path, NUL, then an optional filename
    filter (e.g. `*.BIN`), the rest NUL padding],
  reply: [ACK],
  [Opens a directory on a mounted host. The filter is applied
  server-side; CONFIG uses it for its file-type toggle.])

#cmd("READ_DIR_ENTRY", code: "0F6H", dev: "70H", nparam: "2",
  params: [bytes: maxlen, flags (0)],
  reply: [one entry name, NUL-terminated; directories arrive with a
    trailing `/`; #strong[end of directory is exactly two 7FH bytes]],
  [One entry per transaction. Keep `maxlen` away from 31 --- that magic
  value appends packed detail bytes (timestamp, size, media type)
  meant for other platforms' pickers, and with flags `0C0H` the whole
  reply switches to that block format.])

#cmd("SET_DIRECTORY_POSITION", code: "0E4H", dev: "70H", nparam: "1",
  params: [#strong[word]: absolute entry index],
  reply: [ACK],
  [Seeks the open directory --- CONFIG's paging in one command. Note
  the two-byte parameter: size byte 2, low, high.])

#cmd("GET_DIRECTORY_POSITION", code: "0E5H", dev: "70H", nparam: "0",
  reply: [word: the current index], [The matching tell.])

#cmd("CLOSE_DIRECTORY", code: "0F5H", dev: "70H", nparam: "0",
  reply: [ACK], [Closes the walk. Directories are a scarce resource on
  the adapter; close what you open.])

#sect[Files]

#cmd("COPY_FILE", code: "0D8H", dev: "70H", nparam: "2",
  params: [bytes: source host, destination host --- #strong[both
    1-based], alone among slot parameters],
  payload: [#strong[exact length], no padding:
    `sourcepath|destdir/destname`, `|`-separated],
  reply: [ACK when the copy completes],
  [Server-to-server copy without a byte passing through the console.
  The string payload is the one place padding would corrupt (a NUL
  lands inside the destination name), hence the exact-length rule.
  CONFIG's copy screen (`copy.inc`) is this command plus a retry that
  brings the `.cfg` sidecar along.])

#sect[App keys]

#block({
  set par(first-line-indent: 0pt)
  [Small key/value files on the adapter's SD card, namespaced by a
  16-bit creator id, an app id and a key id --- how FujiNet programs
  remember a player name between sessions. TEXAS HOLD'EM already
  declares the lobby's ids (creator 1, app 1, key 0 --- the username
  shared by every lobby client) for the day it enrolls.]
})

#cmd("OPEN_APPKEY", code: "0DCH", dev: "70H", nparam: "0",
  payload: [6 bytes: `creator` (word) `app` `key` `mode`
    (0 read, 1 write) `reserved`],
  reply: [ACK --- NAK if no SD card is present],
  [Selects which key the next read or write touches.])

#cmd("READ_APPKEY", code: "0DDH", dev: "70H", nparam: "0",
  reply: [64 bytes: the value, NUL-padded],
  [Reads the selected key (open mode 0 first).])

#cmd("WRITE_APPKEY", code: "0DEH", dev: "70H", nparam: "0",
  payload: [the value, up to 64 bytes],
  reply: [ACK],
  [Writes the selected key (open mode 1 first).])

#cmd("CLOSE_APPKEY", code: "0DBH", dev: "70H", nparam: "0",
  reply: [ACK], [Invalidates the selection.])

#sect[Utilities]

#cmd("RANDOM_NUMBER", code: "0D3H", dev: "70H", nparam: "0",
  reply: [4 bytes: a random 32-bit value, little-endian],
  [Hardware entropy from the ESP32. The games keep their 16-bit LFSR
  for speed --- but its seed could come from here.])

#cmd("GENERATE_GUID", code: "0BBH", dev: "70H", nparam: "0",
  reply: [37 bytes: a UUID in text, NUL-terminated],
  [A fresh unique id, ready to print.])

#cmd("BASE64 ENCODE: INPUT / COMPUTE / LENGTH / OUTPUT",
  code: "0D0H / 0CFH / 0CEH / 0CDH", dev: "70H",
  nparam: "INPUT and OUTPUT: 1; others: 0",
  params: [word: byte count (INPUT: how many follow; OUTPUT: how many
    to return)],
  payload: [INPUT: the bytes themselves],
  reply: [LENGTH: 4-byte little-endian size; OUTPUT: the encoded
    text],
  [A four-step pipeline on the adapter: feed raw bytes in (INPUT
  appends --- call it repeatedly for long data), COMPUTE, ask LENGTH,
  then drain with OUTPUT. The buffer survives between transactions.])

#cmd("BASE64 DECODE: INPUT / COMPUTE / LENGTH / OUTPUT",
  code: "0CCH / 0CBH / 0CAH / 0C9H", dev: "70H",
  nparam: "as above", params: [as above], payload: [as above],
  reply: [as above, decoded bytes out],
  [The mirror pipeline, text in, bytes out.])

#cmd("HASH: INPUT / COMPUTE / COMPUTE_NO_CLEAR / LENGTH / OUTPUT / CLEAR",
  code: "0C8H / 0C7H / 0C3H / 0C6H / 0C5H / 0C2H", dev: "70H",
  nparam: "1 (CLEAR: 0)",
  params: [INPUT: word, byte count. COMPUTE: byte, algorithm --- 0 MD5,
    1 SHA1, 2 SHA256, 3 SHA512, 4 SHA224, 5 SHA384. LENGTH and OUTPUT:
    byte, 1 = hex text, else raw],
  payload: [INPUT: the bytes],
  reply: [LENGTH: 1 byte; OUTPUT: the digest],
  [SHA256 on call from a Z80. INPUT appends (COMPUTE clears the buffer
  afterward; COMPUTE_NO_CLEAR keeps it for incremental use); OUTPUT
  as hex costs twice the bytes but prints itself.])

#cmd("QR CODE: INPUT / ENCODE / LENGTH / OUTPUT",
  code: "0BCH / 0BDH / 0BEH / 0BFH", dev: "70H",
  nparam: "INPUT 1 · ENCODE 3 · LENGTH 1 · OUTPUT 1",
  params: [INPUT: word, byte count. ENCODE: bytes --- version (1--40),
    ECC level (0--3), shorten-URL flag. LENGTH: byte, output mode
    (0 binary). OUTPUT: word, byte count],
  payload: [INPUT: the text to encode],
  reply: [LENGTH: 4-byte size; OUTPUT: the module bitmap],
  [The adapter renders a QR matrix you can blit --- at 160×102 with
  4×4-pixel cells, a version-1 code (21×21 modules) fits the Astrocade
  screen with room to spare. A weekend project waiting for its
  author.])

#sect[Answered with a NAK on this platform]

#block({
  set par(first-line-indent: 0pt)
  [The remaining `fujiCommandID.h` opcodes fall through every dispatch
  table in this build and earn a NAK: `ENABLE_UDPSTREAM` (0F0H),
  `SET_BAUDRATE` (0EBH), `SET_HSIO_INDEX` (0E3H),
  `SET_SIO_EXTERNAL_CLOCK` (0DFH), `ENABLE/DISABLE_DEVICE`
  (0D5H/0D4H), `GET_TIME` (0D2H), `DEVICE_ENABLE_STATUS` (0D1H),
  `GET_HEAP` (0C1H), `GET_DEVICE1--10_FULLPATH` (0A0H--0A9H),
  `UPDATE_FIRMWARE` (90H), `HSIO_INDEX` (3FH), and the reply-plumbing
  codes `SEND_ERROR`/`SEND_RESPONSE` (02H/01H). Most are other
  platforms' bus tuning; none are needed here.]
})

// ============================================================
// CHAPTER: COMMAND REFERENCE -- THE NETWORK DEVICE
// ============================================================
#chapter[Command Reference: The Network Device]

#block({
  set par(first-line-indent: 0pt)
  [Every command devices `71H`--`78H` answer, verified against the RS232
  network dispatcher (`lib/device/rs232/network.cpp`). Most opcodes are
  the ASCII letter of their name --- `'O'`pen, `'R'`ead, `'W'`rite ---
  a habit inherited from the Atari. The connection itself, the
  devicespec grammar, and per-protocol behavior are Chapter "The
  Network Device" and the #emph[Network Protocol Handbook];
  these are the cards.]
})

#sect[The lifecycle five]

#cmd("NET_OPEN", code: "4FH  'O'", dev: "71H", nparam: "2",
  params: [bytes: access mode, translation],
  payload: [the devicespec, e.g. `N:HTTPS://host/path`],
  reply: [ACK when the connection (or deferred fetch) is established],
  [Modes: 4 read, 8 write, 12 read/write --- and 12 doubles as GET on
  HTTP, whose fetch is deferred to the first READ. 13 POST, 14 PUT, 5
  DELETE, 6 HEAD on the HTTP family. Translation: 0 none, 1 CR, 2 LF,
  3 CR/LF --- the Astrocade clients always send 0.])

#cmd("NET_STATUS", code: "53H  'S'", dev: "71H", nparam: "2",
  params: [two zero bytes (the RS232 build expects both)],
  reply: [4 bytes: avail low, avail high, connected, device status
    (1 SUCCESS, 136 END_OF_FILE)],
  [The heartbeat. Games gate on device status; NETCAT gates on
  connected; everyone reads avail. See the three rules, Chapter 7.])

#cmd("NET_READ", code: "52H  'R'", dev: "71H", nparam: "1",
  params: [word: byte count --- clamp to avail, and to the 1,024-byte
    reply window],
  reply: [the bytes; capture `FNRXLL/FNRXLH` immediately],
  [On deferred HTTP, the first READ performs the fetch --- give it
  OPEN-class patience (8 quanta).])

#cmd("NET_WRITE", code: "57H  'W'", dev: "71H", nparam: "1",
  params: [word: byte count],
  payload: [exactly that many bytes],
  reply: [ACK],
  [The count rides twice --- as the parameter and as the payload
  length. NETCAT caps writes at 128 bytes to stay clear of the
  320-byte TX stream.])

#cmd("NET_CLOSE", code: "43H  'C'", dev: "71H", nparam: "0",
  reply: [ACK --- and an empty reply window],
  [Rule 1 of Chapter 7: send it at the #emph[start] of the next
  request, never between a READ and the rendering.])

#sect[Structured channels: JSON]

#cmd("NET_SET_CHANNEL_MODE", code: "4DH  'M'", dev: "71H", nparam: "2",
  params: [bytes: 0 (ignored), then mode --- 0 protocol (raw),
    1 JSON],
  reply: [ACK],
  [Switches an open HTTP-family connection between raw bytes and the
  JSON parser. (The dispatcher reads the mode from the #emph[second]
  parameter; send a placeholder first.)])

#cmd("NET_PARSE", code: "50H  'P'", dev: "71H", nparam: "0",
  reply: [ACK when the document parsed],
  [In JSON mode: fetch and parse the reply body into a query-able
  tree. On the SGML channel mode it parses markup instead.])

#cmd("NET_QUERY", code: "51H  'Q'", dev: "71H", nparam: "0",
  payload: [the query, e.g. `N:/players/0/name`],
  reply: [the value as text; then READ it],
  [Extracts one element from the parsed tree. The games skip this
  whole channel --- their servers pre-chew binary with `?bin=1` ---
  but it answers on this platform, and for a lightweight client it is
  the difference between parsing JSON on a Z80 and not.])

#sect[File-shaped connections]

#cmd("NET_SEEK / NET_TELL", code: "25H '%'  /  26H '&'", dev: "71H",
  nparam: "SEEK: 1 · TELL: 0",
  params: [SEEK: 4-byte offset],
  reply: [TELL: 4-byte position],
  [Random access where the protocol supports it (TNFS, HTTP with
  ranges).])

#cmd("NET_RENAME / NET_DELETE / NET_LOCK / NET_UNLOCK",
  code: "20H / 21H '!' / 23H '#' / 24H '$'", dev: "71H", nparam: "0",
  payload: [the target devicespec (RENAME: `old,new`)],
  reply: [ACK],
  [Filesystem verbs on protocols that have files.])

#cmd("NET_MKDIR / NET_RMDIR / NET_CHDIR / NET_GETCWD",
  code: "2AH '*' / 2BH '+' / 2CH ',' / 30H '0'", dev: "71H",
  nparam: "0",
  payload: [MKDIR/RMDIR/CHDIR: the path],
  reply: [GETCWD: the current path],
  [Directory verbs, same family.])

#sect[Sockets and servers]

#cmd("NET_CONTROL / NET_CLOSE_CLIENT", code: "41H 'A'  /  63H 'c'",
  dev: "71H", nparam: "0",
  reply: [ACK],
  [TCP server duty: a listening `N:TCP://:port/` accepts a waiting
  client with `'A'`, and hangs up on that client with `'c'` while
  keeping the listener. Your Astrocade can be the BBS.])

#cmd("NET_GET_REMOTE / NET_SET_DESTINATION",
  code: "72H 'r'  /  44H 'D'", dev: "71H", nparam: "0",
  payload: [SET_DESTINATION: `host:port` for subsequent writes],
  reply: [GET_REMOTE: the sender of the last datagram],
  [UDP's who-said-that and talk-to-them-instead.])

#cmd("NET_USERNAME / NET_PASSWORD", code: "0FDH / 0FEH", dev: "71H",
  nparam: "0",
  payload: [the credential string],
  reply: [ACK],
  [Stored credentials for the next OPEN on protocols that log in
  (FTP, SSH, SMB). Send before OPEN.])

#sect[Line discipline]

#cmd("NET_TRANSLATION", code: "54H  'T'", dev: "71H", nparam: "2",
  params: [bytes: 0 (ignored), then the translation code],
  reply: [ACK],
  [Changes end-of-line translation after OPEN. Same second-parameter
  quirk as SET_CHANNEL_MODE.])

#cmd("NET_SET_EOL", code: "4CH  'L'", dev: "71H", nparam: "2",
  params: [bytes: the custom EOL pair; a first byte of 0 clears],
  reply: [ACK],
  [Custom line terminators for odd servers.])

#cmd("NET_SET_INT_RATE", code: "5AH  'Z'", dev: "71H", nparam: "2",
  params: [bytes: 0 (ignored), then the rate],
  reply: [ACK],
  [Interrupt pacing for platforms with a bus interrupt line. The
  Astrocade polls; accepted and irrelevant here.])

#sect[Answered with a NAK on this platform]

#block({
  set par(first-line-indent: 0pt)
  [Enum'd but not dispatched in this build: `NET_GET_DSTATS_VALUE`
  (0FFH), `NET_CHANNEL_MODE` (0FCH --- the getter; the setter 4DH
  works), `NET_SET_PARAMETERS` (0FBH), `NET_SET_CHANNEL` (0FAH),
  `NET_SET_HSIO_INDEX` (0E3H), `NET_QUERY_ALT`/`NET_PARSE_ALT`
  (81H/80H), `NET_GET_ERROR` (45H --- read the STATUS device-status
  byte instead), and `NET_HSIO_INDEX` (3FH).]
})

// ============================================================
// CHAPTER: NETCAT
// ============================================================
#chapter[Netcat]

#twocol[
"Dial, you tinhorn!" NETCAT is the family's terminal: give it any `N:`
devicespec and it pumps bytes between the connection and a scrolling
40×13 pane, forever. Call a telnet BBS, watch a TCP echo server, talk
to anything that talks back. It is also the family's teaching
milestone three times over: the first Astrocade client to #strong[hold
a connection open] (everything before it was one-shot HTTP GET), the
first to send #strong[N: WRITE], and the first with a pane that
#strong[scrolls].

#sub[How to get NETCAT on your screen]

Build with `./build.sh` (the default devicespec bakes in from
`$ENDPOINT`; `N:TELNET://BBS.FOZZTEXX.COM/` out of the box) and run
with `./run.sh` under MAME, or burn `build/nc.bin` to a cartridge.
Press #key[1] at the SELECT GAME menu. The dial screen offers the
devicespec for editing on a 32×3 grid keyboard --- all 96 printable
characters at once, steered with the hand control --- and #key[=]
dials.

#sub[Hand controls]

#dotdef(
  ([Joy Stick], [steer the grid-keyboard cursor]),
  ([Trigger], [type the highlighted character]),
  ([Keypad #key[=]], [dial · in session: compose-and-send line]),
  ([Keypad #key[C]], [backspace · in session: hang up]),
)

#fig(caption: [NETCAT in session.],
  tv("fozztexx.com telnet bbs

WELCOME TO THE CAVE BBS
Enter your handle: astro
Last on: never. 14 new msgs

Main > read new
14 new. [Enter] pages...

telnet://bbs.fozztexx.com [=]", w: 3.05in, size: 6.6pt))

#sub[Inside the program]

2,144 lines, 3,181 bytes of ROM. The RAM budget is the design driver:
LINES=84 shows 14 rows of 4×6 text and leaves 736 bytes above the
visible screen --- the card games' 90-line screen would have left 496,
and the terminal's shadow does not fit in that. The shadow (`TSHAD`,
160 bytes) is a character-level copy of rows 9--12, so the grid
keyboard overlay can drop over a live session and the covered rows
come back intact.

The session loop is Chapter 7's rules minus the settle loop, which a
live stream must not have:
]

#codepanel("SESSN, netcat screens.inc -- the whole terminal, one loop",
"SESSN:  CALL    TINIT
        CALL    SSTAT
        CALL    TCURON
SESS1:  CALL    NSTATUS
        JR      C,SLOST
        LD      A,(NCONN)       ; a terminal watches CONNECTED --
        OR      A               ; EOF on a socket is a hangup,
        JR      Z,SEOF          ; not an error
        LD      HL,(AVAIL)
        LD      A,H
        OR      L
        JR      Z,SESSI         ; nothing waiting: check the keys
        CALL    TCUROF
        CALL    NREAD
        JR      C,SLOST
        CALL    SREND           ; render RXLEN bytes through TPUTC
        CALL    TCURON
        JR      SESS2
SESSI:  CALL    DELAY10         ; ~11 ms idle pause
SESS2:  CALL    SPOLL           ; keys: compose, send, hang up
        JR      NC,SESS1")

#twocol[
Scrolling is honest work on this hardware --- there is no scroll
register, so `TSCROL` moves the pane up one row with an `LDIR`, about
34 ms, and the escape-swallower in `term.inc` keeps ANSI-decorated
BBSes from wrecking the pane. The 96-glyph font earns its keep the
moment a BBS greets you in lowercase.

Files: `term.inc` (the pane, 274 lines), `edit.inc` (grid keyboard,
222), `screens.inc` (dial and session, 233), `net.inc` (the five N:
commands including the family's only NWRITE, 267), plus the shared
transport. Full listings: Appendix C. Palette: white text, green
accent, gray, black.
]

// ============================================================
// CHAPTER: TEXAS HOLD'EM
// ============================================================
#chapter[Texas Hold'em]

#twocol[
Pull up a chair --- the table is world-wide. TEXAS HOLD'EM joins live
multiplayer poker at `th.carr-designs.com`, against players on Ataris,
Apples, ADAMs, Intellivisions, and the rest of the FujiNet family. The
#strong[server owns the rules]: every legal move arrives over the wire
with its label, so the client contains no poker logic at all --- and
inherits rule changes without a re-burn.

#sub[How to play]

Build, run, press #key[1]. Enter a name on the letter wheel, pick a
table from the lobby, and the keypad's #key[1]--#key[5] press whichever
move buttons the server dealt you --- FOLD, CHECK, CALL, BET, RAISE,
ALL IN as the moment demands. #key[.] shows help, #key[E] leaves.

#sub[The wire format]

Every poll is one HTTP GET --- `state`, `move/XX`, or `leave`, with
`?table=...&player=...&bin=1` --- and `bin=1` is the whole trick: the
server serializes its JSON into a fixed binary layout, so the Z80
reads fields at offsets instead of parsing text. Words are
little-endian; strings are NUL-padded records.
]

#fig(caption: [The Game object, `?bin=1` (fujinet.inc offsets).],
  table(columns: (auto, auto, 1fr),
    table.header[Offset][Field][Notes],
    [0], [`lastResult[81]`], [the round's story, ready to print],
    [81], [`round`], [0 waiting · 1 pre-flop · 2 flop · 3 turn · 4 river · 5 showdown],
    [82], [`pot` (word)], [],
    [84], [`activePlayer`], [signed; 0FFH = nobody],
    [85], [`moveTimer`], [seconds on the shot clock],
    [86], [`viewing`], [1 = you are a spectator],
    [87], [`community[11]`], [the board cards, text],
    [98], [`validMoveCount`], [],
    [99], [`validMoves[5×13]`], [2-char code + 10-char label each],
    [164], [`playerCount`], [],
    [165], [`players[n×33]`], [name 0 · status 9 · bet 10 · move 12 · purse 20 · hand 22],
  ))

#twocol[
Replies are validated (rule 3) against `GMINLEN` 165 and `GMAXLEN`
429; the table list is its own format (36-byte records: id 0, name 9,
players 30).

#sub[The simplest poll loop in the family]

No screen classes, no staged-action enum --- just one elegant trick:
#strong[a staged move rides the next request.] Press a move key and
the client stores the 2-character code; the next poll requests
`move/XX` instead of `state`, and #emph[that reply is the new state].
One round trip, not two.
]

#codepanel("GAMELP, texas screens.inc",
"GAMELP: LD      A,(MOVBUF)      ; a staged move rides the next
        OR      A               ; request -- its reply IS the
        LD      A,1             ; next state
        JR      Z,GLREQ
        LD      A,2             ; V_URL 2: move/XX
GLREQ:  CALL    APICALL
        JR      C,GLFAIL
        XOR     A
        LD      (MOVBUF),A      ; consumed
        CALL    CHKNEW          ; what changed since last poll?
        CALL    RENDER
        LD      B,90            ; ~2 s of input scanning
GLWAIT: ...                     ; KEYSCN every 20 ms, DJNZ")

#twocol[
The screen is 40×15 text over 160×90 pixels in four colors --- felt
green, black, red, white --- with 12×17-pixel cards drawn on an 8-pixel
pitch (`cards.inc`). The Lynx port supplied the screen plan; the Lynx
is 160×102, an exact resolution cousin. A `DEMO=1` build assembles a
static mock table for screenshots and box art.

2,977 lines, 4,607 bytes of ROM. Files of note: `screens.inc` (931
lines --- table list, poll loop, renderer), `cards.inc`, `nament.inc`
(the name wheel), `url.inc` (builds request URLs straight into the TX
stream). Full listings: Appendix C.
]

// ============================================================
// CHAPTER: BATTLESHIP
// ============================================================
#chapter[Battleship]

#twocol[
You sank my --- well, you know the game. Up to four players, live over
the network at `battleship.carr-designs.com`, on boards small enough
that all of them fit your screen at once: four 10×10 quadrants, each
cell 4×4 pixels --- one byte per screen row, so #strong[nothing ever
shifts] when the renderer blits a cell. The right nineteen byte-columns
are the status panel.

You are always quadrant 0: the server rotates its player list so every
client sees itself first. Gameplay was transcribed from the
Intellivision port, and the two clients meet happily at the same
tables.

#sub[How to play]

Name, table, then: place your five ships (sizes 5-4-3-3-2 --- the
placement screen rejects overlaps locally and offers a random legal
seed), press ready, and when your turn lights up, steer the target
cursor --- painted simultaneously on #emph[every] live enemy quadrant
--- and fire. Status 99 is the gun smoke clearing.

#sub[The staged-action machine]

Where TEXAS stages a move code, BATTLESHIP stages an #emph[action]:
`PENDACT` holds 0--3 for none / ready / place / attack, and the poll
loop maps it onto the request --- 0 polls `state`, the rest ride
`ready`, `place/P,P,P,P,P`, `attack/P` and are consumed on success.
Every good poll also computes the turn edge (did `activePlayer` just
become me?) from the previous poll's value, and `CHKNEW` dispatches
one of four screen classes: lobby, placement, game, game-over.

#sub[The wire format, v2]

`?bin=1&v=2` --- and the `v=2` is #strong[mandatory]: v1 hides the
winner index and sends only half the `myShips` array. Ships travel as
one byte each, `position + 100×direction`; the game field is 100
cells of hit/miss/ship state, `y×10+x`.
]

#fig(caption: [The Game object, `?bin=1&v=2` (fujinet.inc offsets).],
  table(columns: (auto, auto, 1fr),
    table.header[Offset][Field][Notes],
    [0], [`playerCount`], [],
    [1], [`prompt[33]`], [the server's banner line],
    [34], [`status`], [0 lobby · 1 place · 10 start · 11 miss · 12 hit · 13 sunk · 99 over],
    [35], [`yourStatus`], [0 play · 1 dead · 2 view · 3 ready · 10 placing],
    [36], [`activePlayer`], [0FFH nobody; at game-over: the winner],
    [37], [`moveTimer`], [],
    [38], [lobby: `serverName[21]` · else `lastAttackPos`], [0--99],
    [39], [`myShips[10]`], [pos + 100×dir],
    [49], [`players[n×115]`], [name 0 · status 9 · field[100] 10 · shipsLeft 110],
  ))

#twocol[
The 115-byte player records appear only from status 10 up; during
placement they are 10 bytes --- `VALID8` (rule 3) knows the difference
and checks `GMINLEN` 38 against the status before trusting a byte.

The random seed is a 16-bit Galois LFSR (`rnd.inc`, polynomial 2DH)
folded with the R register #emph[at the output only] --- fold R into
the state and you would shorten the period.

3,354 lines, 5,598 bytes. Files of note: `place.inc` (335 lines),
`target.inc` (time-sliced targeting, ~5 s per input scan slice),
`board.inc` (quadrant geometry and the wire-driven redraw),
`screens.inc` (799). Palette: white, red, black, sea blue (hue 30 ---
the value that #emph[reads] blue in old notes, 7AH, renders olive;
`battle.asm` documents the MAME palette math that settles it). Full
listings: Appendix C.
]

// ============================================================
// CHAPTER: FUJITZEE
// ============================================================
#chapter[Fujitzee]

#twocol[
Five dice, thirteen rounds, and everybody you know online at
`fujitzee.carr-designs.com`. FUJITZEE is the family's dice game, and
on the Astrocade its 40 columns pay for themselves: the Intellivision
port's two-column scorecard #emph[plus] an always-visible standings
panel, no screen-swapping.

#sub[How to play]

Name, table, ready. On your turn: #key[R] rolls, the keypad's
#key[1]--#key[5] toggle which dice to keep, and when the third roll is
spent (or sooner, if you like what you see) pick a row on the card and
bank it. The server scores; the client's only arithmetic is a running
total.

#sub[Server-computed everything]

The state object's masterstroke is `validScores[15]`: for every open
row, #strong[the exact points the current dice would earn there] ---
computed by the server, updated every roll. The client renders
choices, never rules. A closed row is 0FFH; scores travel as 16-bit
words with 0FFFFH for unset and 0FFFEH marking a spectator.

#sub[Edges, not levels]

Three sharp edge-detections make the UI honest, all computed per poll
against the previous poll's values: the #strong[turn edge] (active
seat just became mine --- ding!), the #strong[view flag] (spectators
never get a turn UI), and the subtle one, the #strong[roll edge]: only
a #emph[decrease] in `rollsLeft` means dice actually landed ---
a same-value poll is just time passing, and the cross-screen sentinel
`PRVRLS = 0FFH` keeps a stale comparison from firing the rattle. And
rattle it does: FUJITZEE is the family's first client to use the
noise generator, for a proper dice-cup shake.

#sub[Dice from thin air]

No dice bitmaps exist. Each die face is three 3-bit pip masks --- 18
bytes of data for all six faces --- expanded procedurally into 12×12
dice (`dice.inc`). The ROM thanks you: 3,746 lines assemble to 6,070
bytes, the tightest fit in the family, 842 bytes under the ceiling.
]

#fig(caption: [The Game object, `?bin=1` (fujinet.inc offsets).],
  table(columns: (auto, auto, 1fr),
    table.header[Offset][Field][Notes],
    [0], [`playerCount`], [spectators appended after players],
    [1], [`serverName[21]`], [],
    [22], [`prompt[41]`], [],
    [63], [`round`], [0 lobby · 1--13 play · 99 over],
    [64], [`rollsLeft`], [3..0 --- the roll edge watches for decrease],
    [65], [`activePlayer`], [0FFH nobody; 0 = your turn],
    [66], [`moveTimer`], [],
    [67], [`viewing`], [1 = spectator],
    [68], [`dice[5]` + NUL], [ASCII `1`--`6`],
    [74], [`keep[5]` + NUL], [ASCII flags: `1` = re-roll this die],
    [80], [`validScores[15]`], [signed; 0FFH = row closed; all zero in lobby],
    [95], [`players[n×42]`], [name 0 · alias 9 · scores[16] words 10],
  ))

#twocol[
Requests: `state`, `ready`, `roll/MMMMM` (the keep mask, streamed
verbatim from the wire's own ASCII flags), `score/N`, `leave` ---
the same staged-action machine as BATTLESHIP with the same `VALID8`
discipline (`GMINLEN` 95, `GMAXLEN` 599, `PCMAX` 12).

Files of note: `turn.inc` (338 lines --- the dice/score modes of your
~5 s input slice), `card.inc` (scorecard + standings, 325),
`dice.inc` (291), `sound.inc` (114 --- tone A plus that noise
rattle). `DEMO=1` builds a static mock play screen. Full listings:
Appendix C.
]

// ============================================================
// CHAPTER: CONFIG
// ============================================================
#chapter[Config]

#twocol[
CONFIG is the program your FujiNet cartridge wakes up in --- the
adapter's face on the Astrocade, and the only client in this book that
speaks to device 70H. WiFi setup with an on-screen password keyboard,
eight host slots to list, mount and rename, a directory browser with
paging and filters, host-to-host file copy, an info screen, the Game
Lobby shortcut --- and the boot road of Chapter 9, progress bar and
all.

It is also the one program here that ships #emph[inside] the
cartridge: `make rom.h` packs `build/config.bin` into
`fujiconfigrom.h`, a C array compiled into the RP2040 firmware, which
serves it as the power-on image. The program you are reading about is
the cartridge's own boot ROM --- and after it network-boots something
else, the swap replaces it entirely.

#sub[Around the screens]

Power on, press #key[1]. HOSTS lists the eight slots; pick one to
mount and browse, #key[E] edits a slot's name on the 16×4 character
grid (with CASE toggle --- SSIDs and passwords are case-sensitive,
and CONFIG carries its own lowercase glyphs beside the BIOS font's
capitals). WIFI scans, bar-graphs RSSI, and joins. BROWSE pages
through directories --- subfolders, a text filter, `.cfg` files
suppressed --- and picking a ROM starts the boot. COPY walks source
and destination and issues COPY_FILE. INFO is
GET_ADAPTERCONFIG_EXTENDED, printed.

#sub[Program shape]

2,859 lines, 5,501 bytes. Where the games are a poll loop, CONFIG is
a classic screen-state machine --- each screen owns its keys and its
redraws, `browse.inc` (442 lines) is deliberately #strong[stateless]
(it re-reads every page from the adapter rather than caching), and
`edit.inc` (397 lines) is #strong[transaction-free by contract] so
the reply window survives an edit --- the HWRITE idiom of Chapter 8
depends on it.

Deliberate scope, matching the Intellivision port: no device-slot
screens, no eject, no read/write toggles, no new-disk, no appkeys ---
a boot console, not a disk manager. And `CONFIG_BOOT` is
#strong[never sent]: on this console the claim signature, not a
config flag, decides who owns power-on.

Files of note: `fujicmd.inc` (the 70H wrappers --- printed whole in
Appendix C, it is the Fuji-device tutorial in 173 lines), `wifi.inc`
(250), `hosts.inc` (321), `boot.inc` (224 --- Chapter 9's listings
came from here), `font.inc` (162 --- the byte-aligned 5×7 blitter the
C demo's `text.c` translates), `ui.inc`, `copy.inc`, `info.inc`,
`input.inc`. Build: the staging Makefile copies sources and `lib/`
flat into `build/stage/` because zmac resolves INCLUDE against the
working directory. Palette: white, amber, blue, black.

#fig(caption: [CONFIG's hosts screen.],
  tv("FUJINET CONFIG          v1.6
----------------------------
HOSTS
 > 1 fujinet.online
   2 tnfs.fujinet.online
   3 my-basement-pi
   4 ...empty...
----------------------------
 [1-8] mount [E]dit [W]ifi
 [B]rowse [C]opy [I]nfo", w: 3.05in, size: 6.6pt))
]

// ============================================================
// CHAPTER: FURTHER READING
// ============================================================
#chapter[Always More To Come]

#twocol[
Your FujiNet cartridge not only ships five programs, it has virtually
hundreds of program possibilities! Here is where to go next.

#sub[The Network Protocol Handbook]

The companion volume from this series: all 28 URL schemes the `N:`
device speaks --- `TCP:`, `TELNET:`, `HTTP:`/`HTTPS:`, `TNFS:`,
`JSON:`, `SSH:`, `SMB:`, `FTP:`, `UDP:`, `GMAIL:`, `GCAL:` and more
--- with the complete devicespec grammar, every mode and error code,
and worked examples. Everything in it runs on the Astrocade through
Chapter 7's five commands.

#sub[The sources of truth]

#dotdef(
  ([`fuji_mailbox.h`], [the mailbox spec --- firmware `pico/astrocade/`]),
  ([`fujilib.inc`], [the Z80 transport (Appendix C)]),
  ([`fujiCommandID.h`], [every command opcode, canonically]),
  ([`fujitest.asm`], [the minimal round trip, in the firmware tree]),
  ([`fuji*.asm` tests], [boot, browse, and banking self-tests, same tree]),
)

#sub[The programs]

Each program chapter's repository carries the full build system, the
MAME smoke tests, and a README with its own war stories: `netcat`,
`fujinet-texasHoldEm`, `fujinet-battleship`, `fujinet-fujitzee`,
`fujinet-config` (directory `astrocade/` in each), all under
`github.com/FujiNetWIFI` and friends. The game servers are
`carr-designs.com` productions; 5 CARD STUD, the games' common
ancestor, has an Astrocade port too.

#sub[Sibling handbooks]

The FujiNet manuals repository carries programming guides in this
same spirit for the Apple II, the Coleco ADAM, the Atari 8-bits, and
the Intellivision --- the last of which shares this console's mailbox
ancestry, one bring-up generation removed.

So do enjoy your FujiNet Professional Arcade... you now have a whole
new dimension in home TV entertainment at your fingertips.
]

// ============================================================
// APPENDIX A: MAILBOX QUICK REFERENCE
// ============================================================
#chapter[Appendix A: Mailbox Quick Reference]

#columns(2, gutter: 18pt, {
  set par(first-line-indent: 0pt)
  sub[Reply bytes (painted ROM)]
  table(columns: (auto, auto, 1fr),
    table.header[Addr][Name][Meaning],
    [`3B00H`], [`FNRDATA`], [reply slice, 256 bytes],
    [`3C00H`], [`FNACKSQ`], [echoes SEQ when ready],
    [`3C01H`], [`FNSTATS`], [bit0 link · bit1 busy],
    [`3C02H`], [`FNERR`], [transport verdict],
    [`3C03H`], [`FNREPLY`], [06H ACK · 15H NAK],
    [`3C04H`], [`FNRXLL`], [reply length lo],
    [`3C05H`], [`FNRXLH`], [reply length hi],
    [`3C06H`], [`FNBSTAT`], [boot state],
    [`3C07H`], [`FNBPCT`], [boot progress 0--100],
    [`3C08H`], [`FNBERR`], [boot error],
    [`3C09H`], [`FNMAGF`], [`F`],
    [`3C0AH`], [`FNMAGN`], [`N`],
    [`3C0BH`], [`FNPVER`], [protocol version (2)],
    [`3C0CH`], [`FNSECHO`], [slice echo, painted last],
  )
  sub[Hotspots (reading is writing)]
  table(columns: (auto, 1fr),
    table.header[Read][Effect],
    [`3D00H+r`], [arm register r (r < 80H)],
    [`3D80H+p`], [map image page p into 2000H (v2)],
    [`3DFEH`], [swap to staged image (BOOTLOCK-armed only)],
    [`3E00H+v`], [armed register ← v, disarm],
    [`3F00H+v`], [append v to the TX stream (max 320)],
  )
  sub[Registers]
  table(columns: (auto, auto, 1fr),
    table.header[Reg][Name][Use],
    [`00H`], [DEVICE], [70H Fuji · 71H--78H network],
    [`01H`], [COMMAND], [the opcode],
    [`02H`], [NPARAM], [parameters in the stream],
    [`05H`], [DATA RST], [any value rewinds TX],
    [`06H`], [RXSLICE], [reply slice 0--3],
    [`10H`], [SEQ], [ACKSEQ+1, wrap 255→1, 0 reserved],
    [`11H`], [BOOTLOCK], [0B5H arms the swap],
    [`12H/13H`], [BOOTSEL], [0B5H then 4AH: cart to UF2],
  )
  sub[The five moves]
  block({
    set text(size: 7.8pt)
    [#rnum(1) BEGIN: rewind TX; DEVICE, COMMAND, NPARAM.\
     #rnum(2) STREAM: params (size byte 1/2/4 + LE value) then payload.\
     #rnum(3) COMMIT: SEQ = ACKSEQ+1 (wrap 255→1).\
     #rnum(4) WAIT: poll FNACKSQ; then FNERR, FNREPLY, capture RXLEN.\
     #rnum(5) READ: slice 0 is fresh; RXSLICE + FNSECHO poll for 1--3.]
  })
  sub[Layout contract (cart offsets)]
  block({
    set text(size: 7.8pt)
    [Code below `1B00H` · claim `FUJI` at `1CFCH` · image exactly 8,192
    bytes · reply max 1,024 · TX max 320 · APPBANK pages 4K × up to 112.]
  })
})

// ============================================================
// APPENDIX B: ERROR AND STATUS CODES
// ============================================================
#chapter[Appendix B: Error and Status Codes]

#columns(2, gutter: 18pt, {
  set par(first-line-indent: 0pt)
  sub[FNERR --- transport verdict (3C02H)]
  table(columns: (auto, auto, 1fr),
    table.header[Value][Name][Meaning],
    [0], [`FN_ERR_OK`], [carried perfectly],
    [1], [`FN_ERR_NOLINK`], [ESP32-S3 not enumerated],
    [2], [`FN_ERR_TIMEOUT`], [adapter did not answer in time],
    [3], [`FN_ERR_BADFRAME`], [SLIP/checksum failure],
    [4], [`FN_ERR_TOOBIG`], [reply exceeded 1,024 bytes],
  )
  sub[FNREPLY --- the FujiNet's answer (3C03H)]
  table(columns: (auto, 1fr),
    table.header[Value][Meaning],
    [`06H`], [ACK: command accepted, reply painted],
    [`15H`], [NAK: command refused --- wrong parameters, missing
      target, unsupported opcode],
  )
  sub[FNBSTAT --- boot state (3C06H)]
  table(columns: (auto, auto, 1fr),
    table.header[Value][Name][Meaning],
    [0], [`FN_BOOT_IDLE`], [no push in progress],
    [1], [`FN_BOOT_XFER`], [image streaming; watch FNBPCT],
    [2], [`FN_BOOT_READY`], [staged; arm BOOTLOCK and swap],
    [`80H`], [`FN_BOOT_FAILED`], [see FNBERR],
  )
  sub[FNBERR --- boot error (3C08H)]
  table(columns: (auto, auto, 1fr),
    table.header[Value][Name][Meaning],
    [1], [`TOOBIG`], [image exceeds the bank store],
    [2], [`TRUNCATED`], [stream ended short of its declared size],
    [3], [`NOMAP`], [size fits no supported mapping],
    [4], [`STOREBUSY`], [the only fitting store is being served from],
  )
  sub[NET_STATUS byte 3 --- device status]
  table(columns: (auto, 1fr),
    table.header[Value][Meaning],
    [1], [SUCCESS --- the adapter is happy],
    [136], [END_OF_FILE],
    [others], [per-protocol error codes --- the Network Protocol
      Handbook tabulates them],
  )
  sub[GET_WIFISTATUS reply]
  table(columns: (auto, 1fr),
    table.header[Value][Meaning],
    [3], [connected],
    [6], [disconnected],
    [others], [transitional --- keep polling],
  )
})

// ============================================================
// APPENDIX C: PROGRAM LISTINGS
// ============================================================
// tighter margins for the listing pages: the appendix is a source
// archive, not reading matter, and every point of height is lines
#set page(margin: (x: 0.4in, top: 0.3in, bottom: 0.34in))
#chapter[Appendix C: Program Listings]

#block({
  set par(first-line-indent: 0pt)
  [The five programs, complete, from the `listings/` snapshots ---
  byte-identical to the source repositories at the commits in the
  README's sources-of-truth table. Shared files print once: the
  transport trio (C.1) is used by all five programs (CONFIG's `lib/`
  copies differ only in header comments), and the games' UI pair (C.2)
  by TEXAS HOLD'EM, BATTLESHIP and FUJITZEE. The games' 64-glyph fonts
  are byte-identical to the first 64 glyphs of NETCAT's 96-glyph
  `font.inc`, printed in C.3. Build scripts are described in Chapter 5;
  generated files (`build/endpoint.inc`, `build/flags.inc`) are not
  printed.]
})

#sect[C.1 The shared transport]
#code-listing("fujilib.inc -- the mailbox transport (all five programs)",
  "listings/common/fujilib.inc")
#code-listing("HVGLIB.H -- Home Video Game Library equates (all five)",
  "listings/common/HVGLIB.H")
#code-listing("state.inc -- the flat reply window (netcat and the games)",
  "listings/common/state.inc")

#sect[C.2 The games' shared UI]
#code-listing("gfx.inc -- 4x6 renderer via the MAGIC expander (the three games)",
  "listings/games-common/gfx.inc")
#code-listing("input.inc -- keypad and hand control (the three games)",
  "listings/games-common/input.inc")

#sect[C.3 NETCAT]
#code-listing("nc.asm", "listings/netcat/nc.asm")
#code-listing("fujinet.inc", "listings/netcat/fujinet.inc")
#code-listing("net.inc", "listings/netcat/net.inc")
#code-listing("screens.inc", "listings/netcat/screens.inc")
#code-listing("term.inc", "listings/netcat/term.inc")
#code-listing("edit.inc", "listings/netcat/edit.inc")
#code-listing("input.inc (netcat's own)", "listings/netcat/input.inc")
#code-listing("gfx.inc (netcat's own)", "listings/netcat/gfx.inc")
#code-listing("font.inc -- the 96-glyph 4x6 font (generated)",
  "listings/netcat/font.inc")

#sect[C.4 TEXAS HOLD'EM]
#code-listing("texas.asm", "listings/texas/texas.asm")
#code-listing("fujinet.inc -- the wire format", "listings/texas/fujinet.inc")
#code-listing("net.inc", "listings/texas/net.inc")
#code-listing("url.inc", "listings/texas/url.inc")
#code-listing("screens.inc", "listings/texas/screens.inc")
#code-listing("cards.inc", "listings/texas/cards.inc")
#code-listing("nament.inc", "listings/texas/nament.inc")
#code-listing("sound.inc", "listings/texas/sound.inc")
#code-listing("demo.inc", "listings/texas/demo.inc")
#code-listing("cardart.inc -- card pip art (generated)",
  "listings/texas/cardart.inc")

#sect[C.5 BATTLESHIP]
#code-listing("battle.asm", "listings/battleship/battle.asm")
#code-listing("fujinet.inc -- the v2 wire format",
  "listings/battleship/fujinet.inc")
#code-listing("net.inc", "listings/battleship/net.inc")
#code-listing("url.inc", "listings/battleship/url.inc")
#code-listing("screens.inc", "listings/battleship/screens.inc")
#code-listing("place.inc", "listings/battleship/place.inc")
#code-listing("target.inc", "listings/battleship/target.inc")
#code-listing("board.inc", "listings/battleship/board.inc")
#code-listing("nament.inc", "listings/battleship/nament.inc")
#code-listing("sound.inc", "listings/battleship/sound.inc")
#code-listing("rnd.inc", "listings/battleship/rnd.inc")

#sect[C.6 FUJITZEE]
#code-listing("fujitzee.asm", "listings/fujitzee/fujitzee.asm")
#code-listing("fujinet.inc -- the wire format",
  "listings/fujitzee/fujinet.inc")
#code-listing("net.inc", "listings/fujitzee/net.inc")
#code-listing("url.inc", "listings/fujitzee/url.inc")
#code-listing("screens.inc", "listings/fujitzee/screens.inc")
#code-listing("turn.inc", "listings/fujitzee/turn.inc")
#code-listing("card.inc", "listings/fujitzee/card.inc")
#code-listing("cardst.inc", "listings/fujitzee/cardst.inc")
#code-listing("dice.inc", "listings/fujitzee/dice.inc")
#code-listing("nament.inc", "listings/fujitzee/nament.inc")
#code-listing("sound.inc", "listings/fujitzee/sound.inc")
#code-listing("demo.inc", "listings/fujitzee/demo.inc")
#code-listing("rnd.inc", "listings/fujitzee/rnd.inc")

#sect[C.7 CONFIG]
#code-listing("config.asm", "listings/config/config.asm")
#code-listing("fujicmd.inc -- the Fuji-device wrappers",
  "listings/config/fujicmd.inc")
#code-listing("wifi.inc", "listings/config/wifi.inc")
#code-listing("hosts.inc", "listings/config/hosts.inc")
#code-listing("browse.inc", "listings/config/browse.inc")
#code-listing("copy.inc", "listings/config/copy.inc")
#code-listing("boot.inc", "listings/config/boot.inc")
#code-listing("info.inc", "listings/config/info.inc")
#code-listing("edit.inc", "listings/config/edit.inc")
#code-listing("ui.inc", "listings/config/ui.inc")
#code-listing("font.inc -- the 5x7 blitter", "listings/config/font.inc")
#code-listing("input.inc (config's own)", "listings/config/input.inc")
#code-listing("fujidisp.inc", "listings/config/fujidisp.inc")

// ============================================================
// APPENDIX D: THE C DEMO
// ============================================================
#chapter[Appendix D: The C Demo]

#block({
  set par(first-line-indent: 0pt)
  [The complete `c-demo` project of Chapter 6, from `listings/c-demo/`
  --- built with z88dk's `+astrocde` target and verified end to end
  under MAME against a live fujinet-pc (the transaction log read
  `dev=70 cmd=C4 ... err=0 reply=06 rxlen=240`). The build recipe is
  printed in Chapter 6; `checkrom.py` is the same layout checker the
  assembly clients vendor.]
})

#code-listing("fujinet.h", "listings/c-demo/fujinet.h", size: 5.6pt)
#code-listing("fujinet.c", "listings/c-demo/fujinet.c", size: 5.6pt)
#code-listing("text.h", "listings/c-demo/text.h", size: 5.6pt)
#code-listing("text.c", "listings/c-demo/text.c", size: 5.6pt)
#code-listing("main.c", "listings/c-demo/main.c", size: 5.6pt)
#code-listing("support.asm", "listings/c-demo/support.asm", size: 5.6pt)
#code-listing("build.sh", "listings/c-demo/build.sh", size: 5.6pt)

// ============================================================
// BACK COVER
// ============================================================
#page(footer: none, fill: cream, {
  v(0.55in)
  place(top + left, dx: 0.35in, dy: 0.5in, {
    text(font: f-head, weight: 700, style: "italic", size: 46pt,
      fill: red)[FujiNet]
    text(font: f-head, weight: 400, size: 11pt, fill: red,
      baseline: -26pt)[ ®]
  })
  place(top + left, dx: 0.4in, dy: 1.35in,
    text(font: f-head, weight: 700, size: 10pt, fill: ink,
      tracking: 0.8pt)[A COMMUNITY PRODUCT OF THE FUJINET PROJECT])
  place(bottom + left, dx: 0.4in, dy: -0.35in,
    text(font: f-head, size: 6.5pt, fill: gray)[0916-00001-0926])
  place(bottom + right, dx: -0.4in, dy: -0.35in,
    text(font: f-head, size: 6.5pt, fill: gray)[fujinet.online])
})
