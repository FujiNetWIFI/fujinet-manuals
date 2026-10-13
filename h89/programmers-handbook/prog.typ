// prog.typ -- what a programmer's manual needs on top of the house style
// (lib.typ, the Operation Manual's, kept identical): program text in the
// H19's own characters, the snippets cut from the book's programs, the
// bytes that went over the bus, the command and library cards, and the
// long listings.
//
// Everything printed here comes from data/, made by the tools from programs
// that were built and run: snips.json (tools/mksnips.py), examples.json
// (tools/mkexamples.py, from the bus log), cmdref.json, libref.json and
// listings/*.json.

#import "lib.typ": *

#let EX = json("data/examples.json")
#let SN = json("data/snips.json")

// ---------------------------------------------------------------- numbers
// Heath wrote octal: a byte as three digits and Q (350Q), an address in
// split octal (042.200). The book leads with hexadecimal and gives the
// octal beside it where an H89 owner would look for it.
#let hexd = "0123456789ABCDEF"
#let hx2(n) = hexd.at(calc.quo(n, 16)) + hexd.at(calc.rem(n, 16))
#let hx4(n) = hx2(calc.quo(n, 256)) + hx2(calc.rem(n, 256))
#let oct3(n) = str(calc.quo(n, 64)) + str(calc.rem(calc.quo(n, 8), 8)) + str(calc.rem(n, 8))
#let hq(n) = [#hx2(n)H (#oct3(n)Q)]
#let splitoct(n) = oct3(calc.quo(n, 256)) + "." + oct3(calc.rem(n, 256))
#let hexval(h) = hexd.position(h.at(0)) * 16 + hexd.position(h.at(1))

// ---------------------------------------------------------------- code
// Program text is set in the H19 Screen face, as a listing came off the
// terminal; one line to a block so columns stay where the source put them.
#let code-size = 7.2pt
#let lab(s) = text(font: f-sans, size: 6.6pt, tracking: 0.06em, upper(s))
#let code-lines(src, size: code-size) = {
  for l in src.split("\n") {
    block(above: 0pt, below: 0pt, height: size * 1.22, breakable: false, width: 100%,
      text(font: f-scrn, size: size, top-edge: 0.8em, bottom-edge: -0.2em, hyphenate: false,
        { set smartquote(enabled: false); l.replace(" ", "\u{00A0}") }))
  }
}
// a block of program text with a small caption over it
#let code(src, caption: none, size: code-size, breakable: auto) = {
  let n = src.split("\n").len()
  let brk = if breakable == auto { n > 16 } else { breakable }
  block(above: 0.75em, below: 0.85em, breakable: brk, width: 100%, {
    if caption != none { block(sticky: true, above: 0pt, below: 0.35em, lab(caption)) }
    block(inset: (left: 0.5em), stroke: (left: 0.5pt + ink.lighten(55%)), breakable: brk,
      code-lines(src, size: size))
  })
}
// the language a snippet is in, as the caption says it
#let lang-name = (asm: "Z80 assembly", c: "C (z88dk, fujinet-lib)")
// A snippet: the piece of a program marked ;@ex KEY / //@ex KEY.
// The caption names the program it was cut from.
#let snip(key, lang, caption: auto, size: code-size) = {
  let s = SN.at(key, default: none)
  if s == none or lang not in s {
    block(stroke: 0.6pt + red, inset: 4pt, text(fill: red, size: 7pt)[MISSING SNIPPET #key (#lang)])
  } else {
    let e = s.at(lang)
    let file = e.where.at(0).at(0).split("/").last()
    let cap = if caption == auto { lang-name.at(lang) + " " + sym.dash.em + " from " + upper(file) } else { caption }
    code(e.text, caption: cap, size: size)
  }
}
#let has-snip(key, lang) = key in SN and lang in SN.at(key)

// ---------------------------------------------------------------- bytes
// One byte of a frame as a cell, shaded by what it is. One ink and its
// tints, as a Heath manual would print it.
#let role-fill(r) = {
  if r == "end" { brown }
  else if r == "dev" or r == "cmd" { gold.lighten(35%) }
  else if r == "len" { luma(222) }
  else if r == "chk" { yellow.lighten(10%) }
  else if r == "dsc" { gold.lighten(68%) }
  else if r == "par" { rgb("#e7d7b4") }
  else if r == "esc" { brown.lighten(62%) }
  else { white }
}
#let cell-w = 14.6pt
#let bcell(h, r, ascii: true) = {
  let val = hexval(h)
  let ch = if r == "pay" and ascii and val > 32 and val < 127 { str.from-unicode(val) } else { "" }
  box(width: cell-w, height: if ascii { 16.5pt } else { 10.5pt },
    fill: role-fill(r), stroke: 0.4pt + ink.lighten(45%), inset: 0pt,
    align(center + top, {
      v(1.7pt)
      text(font: f-scrn, size: 7.6pt, fill: if r == "end" { white } else { ink },
        top-edge: 0.8em, bottom-edge: -0.1em, h)
      if ascii {
        linebreak()
        text(font: f-scrn, size: 6.4pt, fill: ink.lighten(25%), top-edge: 0.8em, bottom-edge: -0.1em,
          { set smartquote(enabled: false); ch })
      }
    }))
}
#let gapcell(n, ascii: true) = box(height: if ascii { 16.5pt } else { 10.5pt },
  inset: (x: 3.5pt), stroke: (paint: ink.lighten(45%), thickness: 0.4pt, dash: "dotted"),
  align(center + horizon, text(font: f-sans, size: 6pt, [#n MORE])))
// One frame. A frame that fits in three rows of cells is drawn whole; a
// longer one shows its header, the first of its payload, how many bytes
// are left out, and the END that closes it.
#let per-row = 15
#let strip(fr, rows: 3) = {
  let hasascii = fr.any(b => b.at(1) == "pay")
  let firstpay = fr.position(b => b.at(1) == "pay" or b.at(1) == "esc")
  let cells = ()
  if firstpay == none or fr.len() <= per-row * rows {
    cells = fr.map(b => bcell(b.at(0), b.at(1), ascii: hasascii))
  } else {
    let room = per-row * 2 - 3                // the gap cell is about three wide
    let keep = calc.max(4, room - firstpay)
    let paycount = fr.len() - firstpay - 1
    cells = fr.slice(0, firstpay + keep).map(b => bcell(b.at(0), b.at(1), ascii: hasascii))
    cells.push(gapcell(paycount - keep, ascii: hasascii))
    cells.push(bcell(fr.last().at(0), fr.last().at(1), ascii: hasascii))
  }
  block(breakable: false, above: 0.2em, below: 0.2em, {
    set par(justify: false, leading: 0.22em, spacing: 0.2em)
    cells.join(h(0.6pt))
  })
}
// which run of a program a strip is taken from: the assembly one under
// HDOS if there is one (it is the snippet printed beside it)
#let run-order = ("asm-hdos", "asm-cpm", "c-hdos", "c-cpm")
#let pick-run(key, run: auto) = {
  let e = EX.at(key, default: none)
  if e == none { return none }
  if run != auto { return run }
  for want in run-order {
    for r in e.keys() { if r.ends-with(want) { return r } }
  }
  e.keys().first()
}
#let wirelab(s) = text(font: f-sans, size: 6.4pt, tracking: 0.05em, upper(s))
#let plural(n, one, many) = if n == 1 { one } else { many }
// Request and reply, as they went over the bus. `only` picks exchanges
// (indexes) when an example made several.
#let exchange(key, run: auto, only: auto, rows: 3) = {
  let r = pick-run(key, run: run)
  if r == none {
    block(stroke: 0.6pt + red, inset: 4pt, text(fill: red, size: 7pt)[NO CAPTURE FOR #key])
    return
  }
  let xs = EX.at(key).at(r)
  let idx = if only == auto { range(xs.len()) } else if type(only) == int { (only,) } else { only }
  // negative indexes count from the end: -1 is the last exchange
  idx = idx.map(i => if i < 0 { xs.len() + i } else { i })
  for i in idx {
    let x = xs.at(i)
    block(breakable: false, above: 0.6em, below: 0.7em, {
      if x.req != none {
        wirelab[H89 #sym.arrow.r FujiNet]
        strip(x.req, rows: rows)
      } else if x.at("rawreq", default: none) != none {
        let bytes = x.rawreq.split(" ")
        wirelab[H89 #sym.arrow.r FujiNet #sym.dot.c not framed #sym.dot.c #bytes.len() #plural(bytes.len(), "byte", "bytes")]
        strip(bytes.map(b => (b, "pay")), rows: rows)
      }
      v(1.5pt)
      if x.rep != none {
        wirelab[FujiNet #sym.arrow.r H89 #sym.dot.c #x.reply #if x.replen > 0 [#sym.dot.c #x.replen #plural(x.replen, "byte", "bytes")]]
        strip(x.rep, rows: rows)
      } else if x.raw != none {
        wirelab[FujiNet #sym.arrow.r H89 #sym.dot.c not framed #sym.dot.c #x.replen #plural(x.replen, "byte", "bytes")]
        let bytes = x.raw.split(" ")
        strip(bytes.map(b => (b, "pay")), rows: rows)
      } else {
        wirelab[no reply]
      }
    })
  }
}
// the key to the shading, once, in Chapter 3
#let legend() = {
  let item(r, t) = box(baseline: 1pt, { box(width: 8pt, height: 7pt, fill: role-fill(r),
      stroke: 0.4pt + ink.lighten(45%)); h(2.5pt); text(font: f-sans, size: 6.8pt, t) })
  block(above: 0.6em, below: 0.8em, {
    set par(justify: false, leading: 0.5em)
    (item("end", [END]), item("dev", [device, command]), item("len", [length]),
     item("chk", [checksum]), item("dsc", [descriptor]), item("par", [fields]),
     item("pay", [payload (characters under)]), item("esc", [escape pair])).join(h(6pt))
  })
}

// ---------------------------------------------------------------- cards
// A card heads each command's entry: its name, its numbers in hex and
// octal, and the spec lines; the entry's text, warnings, the two snippets
// and the bytes follow under it.
#let spec-line(a, b) = grid(columns: (0.72in, 1fr), column-gutter: 0.5em,
  text(font: f-sans, size: 6.8pt, tracking: 0.05em, upper(a)), text(size: 8.6pt, b))
#let tag-box(t) = box(stroke: 0.5pt + ink, inset: (x: 3pt, y: 1.5pt), baseline: 1.5pt,
  text(font: f-sans, size: 6pt, weight: "bold", tracking: 0.06em, upper(t)))
#let cmdcard(title, dev: none, cmd: none, equ: none, tags: (), lines: ()) = {
  // a label for the quick reference's page numbers: <cmd-FUJI_GET_SSID>
  if equ != none { [#metadata(equ) #label("cmd-" + equ)] }
  block(sticky: true, breakable: false, above: 1.4em, below: 0.6em, width: 100%, {
    line(length: 100%, stroke: 0.8pt + ink)
    v(-0.2em)
    grid(columns: (1fr, auto), align: (left + bottom, right + bottom), column-gutter: 0.4em,
      text(font: f-head, weight: "bold", size: 9.4pt, hyphenate: false, upper(title)),
      if cmd != none { text(font: f-scrn, size: 9pt, hx2(cmd) + "H") })
    v(-0.35em)
    if dev != none or equ != none {
      text(font: f-sans, size: 6.6pt, tracking: 0.04em, {
        if dev != none [DEVICE #(if type(dev) == str { dev } else { hq(dev) })]
        if cmd != none [#h(0.6em) COMMAND #hq(cmd)]
        if equ != none [#h(0.6em) #text(font: f-scrn, size: 7.2pt, equ)]
      })
      v(-0.2em)
    }
    if tags.len() > 0 { tags.map(tag-box).join(h(3pt)); v(-0.1em) }
    if lines.len() > 0 {
      grid(columns: (0.72in, 1fr), column-gutter: 0.5em, row-gutter: 0.42em,
        ..lines.map(((a, b)) => (text(font: f-sans, size: 6.8pt, tracking: 0.05em, baseline: -0.5pt, upper(a)),
                                 text(size: 8.6pt, b))).flatten())
    }
  })
}
// The examples under a card: the Z80 snippet, the C snippet, the bytes.
#let examples(key, asm: auto, c: auto, wire: auto, run: auto, only: auto) = {
  let ak = if asm == auto { key } else { asm }
  let ck = if c == auto { key } else { c }
  let wk = if wire == auto { key } else { wire }
  if ak != none { snip(ak, "asm") }
  if ck != none { snip(ck, "c") }
  if wk != none { exchange(wk, run: run, only: only) }
}

// ---------------------------------------------------------------- listings
// A whole program in two columns at listing size: pre-wrapped by
// tools/mklistings.py, every printed line with its source line number (a
// continuation line carries none), one text() to a line so 300 pages of it
// set quickly.
#let listing-size = 6.0pt
#let plisting(name, size: listing-size) = {
  let d = json("data/listings/" + name + ".json")
  for f in d.files {
    block(sticky: true, above: 1.1em, below: 0.4em, width: 100%, {
      line(length: 100%, stroke: 0.5pt + ink)
      v(-0.25em)
      grid(columns: (1fr, auto), lab(f.path), lab(str(f.lines) + " lines"))
    })
    for l in f.printed {
      block(above: 0pt, below: 0pt, height: size * 1.2, breakable: false, width: 100%,
        text(font: f-scrn, size: size, top-edge: 0.8em, bottom-edge: -0.2em, hyphenate: false,
          { set smartquote(enabled: false)
            text(fill: ink.lighten(45%), l.at(0))
            l.at(1).replace(" ", "\u{00A0}") }))
    }
  }
}

// the page a command's card is on ("8-4"), for the quick reference
#let card-page(equ) = context {
  let found = query(label("cmd-" + equ))
  if found.len() == 0 { "--" } else { page-ref(found.first().location()) }
}

// a reply's (or payload's) layout: offset, bytes, what they hold
// table.header keeps the heading with the first row, and repeats it when the table breaks
#let htable(cols, heads, rows, size: 7.6pt) = {
  set text(font: f-sans, size: size, hyphenate: false)
  block(breakable: true, above: 0.8em, below: 0.8em,
    table(columns: cols, stroke: none, inset: (x: 0.3em, y: 0.22em),
      table.header(..heads.map(th)), ..rows))
}
#let fields-table(..rows) = htable((0.46in, 0.42in, 1fr), ([Offset], [Bytes], [Holds]), rows.pos())
// a list of values (modes, codes) and what each means
#let values-table(what, means, ..rows, first: 0.5in) = htable((first, 1fr), (what, means), rows.pos())

// ---------------------------------------------------------------- sections
// lib.typ's section() balances a short section in a block of fixed height
// that may split across a page: with a table at the foot of a page the two
// halves overprint. Here a balanced section is kept whole (it is at most
// 3.6 in tall, so it always fits on the next page); longer ones flow.
#let pbalanced(body, limit: 3.6in) = std.layout(size => {
  let colw = (size.width - gutter) / 2
  let h = bal-height(body, colw).to-absolute()
  // a table's height is not always measured right here: let it flow
  if h > limit or repr(body).contains("table(") { columns(2, gutter: gutter, body) }
  else { block(width: 100%, height: h, breakable: false, columns(2, gutter: gutter, body)) }
})
#let section(title, body, balance: true, above: 0.32in, newpage: false) = {
  if newpage { pagebreak(weak: true) }
  block(sticky: true, above: above, below: 0.2in, width: 100%,
    align(center, text(font: f-head, weight: "bold", size: 13pt, hyphenate: false, upper(title))))
  [#metadata(title) <toc2>]
  if balance { pbalanced(body) } else { flow(body) }
}

// lib.typ's stable() keeps a table in one piece; in this book's long
// reference tables that can push a table past the foot of a column, so
// here they may break (between rows)
#let stable(cols, ..cells, size: 7.8pt, inset: (x: 0.35em, y: 0.28em), breakable: true) = {
  set text(font: f-sans, size: size, hyphenate: false)
  block(breakable: breakable, above: 0.8em, below: 0.8em,
    table(columns: cols, stroke: none, inset: inset, ..cells))
}
