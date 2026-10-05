// lib.typ -- helpers for the FujiNet NES Programmer's Manual.
//
// House style: the 1985 Nintendo "Gyromite" instruction booklet, the black-box
// launch-title look. White pages, black ink and ONE spot colour (a yellow-
// orange), section heads in Helvetica Bold Oblique capitals flush left with
// no rules, a loosely tracked Univers body set ragged right, bold intro
// paragraphs, thin black rule boxes, the CAUTION highlight, technical line
// art with hairline leaders, small black-ground screen shots, and a plain
// numeral folio at the bottom corner -- even pages right, odd pages left,
// as the booklet does it.

// ---------- fonts ---------------------------------------------------
#let f-body  = "Univers LT Std"         // 55 Roman / 65 Bold
#let f-head  = "Helvetica"              // Bold Oblique for the heads
#let f-black = "Helvetica Neue"         // the cover wordmark (Black)
#let f-seal  = "Apple Garamond"         // the seal page italic
#let f-mono  = "Source Code Pro"

// ---------- palette -------------------------------------------------
#let ink    = rgb("#111111")
#let paper  = rgb("#ffffff")
#let spot   = rgb("#fbb408")            // the booklet's only colour inside
#let gray   = rgb("#6f6f6f")
#let hair   = rgb("#b9b9b9")
#let cyan   = rgb("#1ca8f7")            // the cover title
#let purple = rgb("#762571")            // the series badge
#let screen-bg = rgb("#000000")

#let appendix = state("apx", false)
#let frontmatter = state("fm", true)

// ---------- type helpers --------------------------------------------
#let track = 0.025em                    // the phototype letterspacing
#let caps(s, size: 9pt, weight: 700) = text(font: f-body, weight: weight,
  size: size, tracking: 0.04em, upper(s))
#let mono(s, size: 0.88em) = text(font: f-mono, size: size, tracking: 0pt, s)
#let hx(s) = text(font: f-mono, size: 0.88em, tracking: 0pt, s)

// The booklet's intro paragraph: bold and a size up.
#let lead(body) = block(above: 0.2em, below: 0.9em, {
  set text(weight: 700, size: 10.2pt)
  set par(leading: 0.5em)
  body
})

// ---------- callouts ------------------------------------------------
// CAUTION: the word in bold capitals on a solid spot-colour box, then a
// colon and the text in the body face. The booklet's signature.
#let hilite(s) = box(fill: spot, inset: (x: 1.5pt, y: 1.6pt), outset: (y: 0.6pt),
  text(weight: 700, tracking: 0.03em, upper(s)))
#let caution(body) = block(above: 0.8em, below: 0.8em, breakable: false,
  [#hilite("Caution"): #body])
#let warning(body) = block(above: 0.8em, below: 0.8em, breakable: false,
  [#hilite("Warning"): #body])
// NOTE: bold capitals, the text hanging past it.
#let note(body) = block(above: 0.8em, below: 0.8em, breakable: false,
  grid(columns: (auto, 1fr), column-gutter: 5pt,
    text(weight: 700, tracking: 0.03em)[NOTE:], body))
// The thin black rule box ("OBJECT OF THE GAME / GAME DESCRIPTION").
#let objbox(title, body) = block(width: 100%, above: 0.9em, below: 1em,
  breakable: false, stroke: 0.6pt + ink, inset: (x: 10pt, top: 7pt, bottom: 8pt), {
  text(font: f-body, weight: 400, size: 10.5pt, tracking: 0.05em, spacing: 150%, upper(title))
  v(3pt)
  set text(weight: 700)
  body
})

// ---------- lists ---------------------------------------------------
// "1. Select Button: ..." -- bold numeral, bold run-in label, hanging indent.
#let runin(..items) = {
  let xs = items.pos()
  block(above: 0.6em, below: 0.8em, grid(columns: (auto, 1fr),
    column-gutter: 4pt, row-gutter: 0.5em,
    ..xs.enumerate().map(((i, it)) => (
      text(weight: 700)[#(i + 1).],
      [#text(weight: 700)[#it.at(0):] #it.at(1)])).flatten()))
}
// "* A spinning gyro ..." -- the raised asterisk list.
#let stars(..items) = block(above: 0.5em, below: 0.7em, grid(
  columns: (auto, 1fr), column-gutter: 4pt, row-gutter: 0.45em,
  ..items.pos().map(it => (text(baseline: -0.15em)[\*], it)).flatten()))
// "a) b) c)" steps.
#let steps(..items) = enum(numbering: "a)", spacing: 0.5em, tight: false,
  indent: 0pt, body-indent: 5pt, ..items.pos())
// "Up : Raises the arms." -- the D-pad legend, colon-aligned.
#let legend(..rows) = block(above: 0.5em, below: 0.7em, grid(
  columns: (auto, auto, 1fr), column-gutter: 4pt, row-gutter: 0.4em,
  ..rows.pos().map(r => (text(weight: 700, r.at(0)), [:], r.at(1))).flatten()))

// ---------- code ----------------------------------------------------
// A panel never wraps a line: it picks the largest size at which its longest
// line still fits the width it is given.
#let fitsize(txt, size, width) = {
  let longest = calc.max(1, ..txt.split("\n").map(l => l.len()))
  calc.min(size, width / (longest * 0.6))
}
#let codebody(txt, size) = {
  set par(justify: false, leading: 0.38em, first-line-indent: 0pt)
  set text(font: f-mono, size: size, tracking: 0pt, fill: ink)
  txt.split("\n").map(l => if l == "" { " " } else { l }).join(linebreak())
}
#let code-head(title) = block(breakable: false, below: 3pt, sticky: true,
  text(font: f-body, weight: 700, size: 7pt, tracking: 0.08em, upper(title)))
// One program fragment in a thin rule box, its caption above in small caps.
#let codepanel(title, txt, size: 7.2pt, width: 100%) = layout(sz => {
  let w = if type(width) == ratio { sz.width * width } else { width }
  // a short panel stays in one piece; a long one may break across pages
  let long = txt.split("\n").len() > 40
  block(width: w, above: 0.8em, below: 0.9em, breakable: long, {
    if title != none { code-head(title) }
    block(width: 100%, breakable: long, stroke: 0.5pt + ink,
      inset: (x: 7pt, y: 5pt), codebody(txt, fitsize(txt, size, w - 16pt)))
  })
})
// The two roads, side by side: 6502 assembly on the left, C on the right.
#let pair(asm, c, size: 6.6pt, asm-title: "6502 Assembly (ca65)",
          c-title: "C (cc65 + fujinet-lib)") = block(width: 100%,
  above: 0.8em, below: 0.9em, breakable: false, {
  grid(columns: (1fr, 1fr), column-gutter: 10pt,
    if asm != none { codepanel(asm-title, asm, size: size) } else { [] },
    if c != none { codepanel(c-title, c, size: size) } else { [] })
})

// ---------- figures -------------------------------------------------
#let fig-n = counter("figure")
#let fig(body, caption: none) = block(width: 100%, above: 0.9em, below: 1em,
  breakable: false, {
  fig-n.step()
  align(center, body)
  if caption != none {
    v(3pt)
    set par(justify: false)
    align(center, text(size: 7.6pt, fill: ink, {
      text(weight: 700)[Fig. #context fig-n.display()]
      [ #sym.dash.en #caption]
    }))
  }
})
// A real screen from the grafted MAME: the black image is its own frame.
#let shot(name, w: 2.3in) = image("images/screens/" + name + ".png", width: w,
  scaling: "pixelated")
#let shotfig(name, caption: none, w: 2.3in) = fig(shot(name, w: w), caption: caption)
// Two or three shots in a row.
#let shots(..names, w: 1.95in, caption: none) = fig(
  stack(dir: ltr, spacing: 8pt, ..names.pos().map(n => shot(n, w: w))),
  caption: caption)

// ---------- tables --------------------------------------------------
// The parts-list table: fully ruled, bold heads.
#let ruled(cols, ..cells, size: 8pt, align: left) = block(above: 0.7em,
  below: 0.9em, {
  set par(justify: false)
  set text(size: size)
  table(columns: cols, align: align + horizon, inset: (x: 5pt, y: 3.5pt),
    stroke: 0.5pt + ink, ..cells.pos())
})
// The quieter table: rules top and bottom, hairlines between.
#let tbl(cols, ..cells, size: 8pt, align: left) = block(above: 0.7em,
  below: 0.9em, {
  set par(justify: false)
  set text(size: size)
  table(columns: cols, align: align + top, inset: (x: 4pt, y: 3.2pt),
    stroke: (x, y) => (
      top: if y == 0 { 0.8pt + ink } else if y == 1 { 0.5pt + ink } else { 0.3pt + hair },
      bottom: 0.8pt + ink),
    ..cells.pos())
})
#let th(s) = text(weight: 700, s)

// ---------- byte-field strip ----------------------------------------
#let bytefield(..cells) = align(center, block(above: 0.6em, below: 0.6em,
  breakable: false, grid(columns: cells.pos().map(c => c.at(1)),
    stroke: 0.6pt + ink,
    ..cells.pos().map(c => grid.cell(inset: 4pt, align: center,
      text(font: f-mono, size: 7pt, c.at(0)))))))

// ---------- memory map ----------------------------------------------
// rows: (from, to, label, filled?, note). A column of boxes, addresses at the
// left, notes at the right; a box's height grows with its size, with a floor.
#let memmap(rows, w: 1.45in, scale: 0.012pt, minh: 13pt, maxh: 60pt) = {
  let boxes = rows.map(r => {
    let h = calc.min(maxh, calc.max(minh, (r.at(1) - r.at(0) + 1) * scale))
    grid(columns: (0.52in, w, 1fr), column-gutter: 6pt,
      align: (right + top, left + top, left + horizon),
      text(font: f-mono, size: 6.8pt, "$" + upper(str(r.at(0), base: 16))),
      box(width: w, height: h, fill: if r.at(3) { spot } else { paper },
        stroke: 0.6pt + ink, align(center + horizon,
          text(font: f-body, weight: 700, size: 6.8pt, tracking: 0.03em, r.at(2)))),
      text(size: 7pt, r.at(4)))
  })
  align(center, block(above: 0.7em, below: 0.6em, breakable: false,
    stack(dir: ttb, spacing: 0pt, ..boxes, v(2pt),
      grid(columns: (0.52in, w, 1fr), column-gutter: 6pt, align: right,
        text(font: f-mono, size: 6.8pt,
          "$" + upper(str(rows.last().at(1) + 1, base: 16))), [], []))))
}

// ---------- sequence diagram ----------------------------------------
#let msg(from, to, body, dashed: false) = (kind: "msg", from: from, to: to,
  body: body, dashed: dashed)
#let snote(lane, body, span: 1) = (kind: "note", lane: lane, span: span, body: body)
#let seq(actors, ..steps, w: 420pt) = {
  let n = actors.len()
  let steps = steps.pos()
  let lane = w / n
  let xs = range(n).map(i => lane * (i + 0.5))
  let headh = 20pt
  let bodyh = steps.map(s => if s.kind == "note" { 22pt } else { 17pt }).sum()
  align(center, block(breakable: false, above: 0.7em, below: 0.7em,
    box(width: w, height: headh + bodyh + 10pt, {
      for i in range(n) {
        place(top + left, dx: xs.at(i), dy: headh - 2pt, line(start: (0pt, 0pt),
          end: (0pt, bodyh + 8pt), stroke: (paint: gray, thickness: 0.5pt,
            dash: "dotted")))
        place(top + left, dx: xs.at(i) - lane / 2 + 6pt, dy: 0pt,
          box(width: lane - 12pt, height: 16pt, stroke: 0.6pt + ink,
            align(center + horizon, caps(actors.at(i), size: 6.8pt))))
      }
      let y = headh + 5pt
      for s in steps {
        if s.kind == "note" {
          place(top + left, dx: xs.at(s.lane) - lane / 2 + 8pt, dy: y - 2pt,
            box(width: lane * s.span - 16pt, fill: spot, inset: (x: 4pt, y: 3pt),
              align(center, text(size: 6.4pt, s.body))))
          y += 22pt
        } else {
          let a = xs.at(s.from)
          let b = xs.at(s.to)
          let lo = calc.min(a, b)
          let hi = calc.max(a, b)
          place(top + left, dx: lo, dy: y + 8pt, line(start: (0pt, 0pt),
            end: (hi - lo, 0pt), stroke: (paint: ink, thickness: 0.7pt,
              dash: if s.dashed { "dashed" } else { none })))
          if b > a {
            place(top + left, dx: b - 5pt, dy: y + 8pt,
              polygon(fill: ink, (0pt, -2.3pt), (5pt, 0pt), (0pt, 2.3pt)))
          } else {
            place(top + left, dx: b, dy: y + 8pt,
              polygon(fill: ink, (5pt, -2.3pt), (0pt, 0pt), (5pt, 2.3pt)))
          }
          place(top + left, dx: lo + 5pt, dy: y - 1pt,
            text(font: f-mono, size: 6.2pt, s.body))
          y += 17pt
        }
      }
    })))
}

// ---------- block diagram -------------------------------------------
#let nodebox(title, sub: none, w: auto, fill: paper) = box(width: w,
  fill: fill, inset: (x: 7pt, y: 5pt), stroke: 0.6pt + ink, align(center, {
    caps(title, size: 7.2pt)
    if sub != none { v(2pt, weak: true); text(size: 6.4pt, sub) }
  }))
#let biarrow(w: 26pt, label: none) = box(width: w, height: 14pt, baseline: 4pt, {
  place(left + horizon, dx: 4pt, line(length: w - 8pt, stroke: 0.7pt + ink))
  place(left + horizon, polygon(fill: ink, (4pt, -2.3pt), (0pt, 0pt), (4pt, 2.3pt)))
  place(left + horizon, dx: w - 4pt, polygon(fill: ink, (0pt, -2.3pt), (4pt, 0pt), (0pt, 2.3pt)))
  if label != none { place(center + top, dy: -6pt, text(size: 5.6pt, label)) }
})
#let flow(..items) = align(center, block(above: 0.8em, below: 0.7em,
  breakable: false, stack(dir: ltr, spacing: 0pt, ..items.pos())))

// ---------- the command card ----------------------------------------
// The command's name on the spot colour like a CAUTION, its numbers at the
// right, then a thin rule box of what goes in and what comes back.
#let cmdlab(s) = text(weight: 700, size: 6.6pt, tracking: 0.06em, upper(s))
#let cmd(name, code: "", dev: "", params: "none", payload: "none",
         reply: "none", asm: none, c: none, body) = block(width: 100%,
  above: 1.1em, below: 0.9em, breakable: false, {
  block(breakable: false, sticky: true, width: 100%, {
    grid(columns: (1fr, auto), align: (left + bottom, right + bottom),
      hilite(name),
      text(font: f-mono, weight: 700, size: 8pt, tracking: 0pt,
        [DEV #dev #h(6pt) CMD #code]))
    v(3pt)
    block(width: 100%, stroke: 0.5pt + ink, inset: (x: 7pt, y: 5pt), {
      set par(justify: false)
      set text(size: 7.8pt)
      grid(columns: (46pt, 1fr), row-gutter: 4pt, column-gutter: 4pt,
        cmdlab("params"), params, cmdlab("payload"), payload,
        cmdlab("reply"), reply)
    })
  })
  v(2pt)
  body
  if asm != none or c != none { pair(asm, c) }
})

// ---------- listings ------------------------------------------------
// Zero-width spaces after separators inside very long tokens, so a 2-up
// listing line that cannot otherwise wrap still has somewhere to break.
#let softbreak(src) = src.split("\n").map(l =>
  l.split(" ").map(t =>
    if t.len() > 40 {
      t.replace(",", ",\u{200b}").replace("=", "=\u{200b}").replace("/", "/\u{200b}")
    } else { t }).join(" ")).join("\n")
// A numbered callout: black numeral on a spot-colour disc.
#let co(n) = box(baseline: 20%, circle(radius: 4.2pt, fill: spot, stroke: none,
  align(center + horizon, text(font: f-body, weight: 700, size: 6.2pt,
    tracking: 0pt, fill: ink, str(n)))))
#let listing-n = counter("listing")
// A whole file, numbered lines, callouts keyed by line number. Two columns
// for a long file, one for a short one.
// Callouts are (text, n) pairs: n goes on the first line containing text,
// so they follow the source when its line numbers move.
#let code-listing(title, path, size: 5.5pt, callouts: (), cols: auto) = {
  let raw-src = read(path)
  let lines = raw-src.split("\n")
  let marks = (:)
  for (pat, n) in callouts {
    let i = lines.position(l => l.contains(pat))
    if i == none { panic("callout not found in " + path + ": " + pat) }
    marks.insert(str(i + 1), n)
  }
  let callouts = marks
  let src = softbreak(raw-src)
  let nlines = lines.len()
  let ncols = if cols == auto { if nlines > 70 { 2 } else { 1 } } else { cols }
  listing-n.step()
  block(breakable: false, above: 1.1em, below: 4pt, sticky: true, {
    grid(columns: (auto, 1fr), column-gutter: 6pt, align: horizon,
      hilite[Listing #context listing-n.display()],
      text(weight: 700, size: 8pt, tracking: 0.04em, upper(title)))
    v(2pt)
    line(length: 100%, stroke: 0.5pt + ink)
  })
  let body = {
    show raw.where(block: true): it => block(width: 100%, breakable: true,
      text(font: f-mono, size: size, tracking: 0pt, fill: ink,
        it.lines.join(parbreak())))
    show raw.line: it => {
      box(width: 12pt, align(right, text(size: size * 0.82, fill: gray,
        str(it.number))))
      h(3pt)
      it.body
      if str(it.number) in callouts { h(2pt); co(callouts.at(str(it.number))) }
    }
    set par(justify: false, leading: 0.3em, spacing: 0.3em,
      hanging-indent: 15pt, first-line-indent: 0pt)
    raw(src, block: true)
  }
  if ncols == 2 { columns(2, gutter: 10pt, body) } else { body }
}

// ---------- excerpts of the verified listings -----------------------
// From the first line containing `from` up to (not including) the first
// later line containing `to`, or `n` lines.
#let excerpt-lines(path, from, to: none, n: 30, skip: 0) = {
  let lines = read(path).split("\n")
  let a = lines.position(l => l.contains(from))
  if a == none { panic("excerpt: marker not found: " + from) }
  a += skip
  let b = a + n
  if to != none {
    let rel = lines.slice(a + 1).position(l => l.contains(to))
    if rel != none { b = a + 1 + rel }
  }
  lines.slice(a, calc.min(b, lines.len())).join("\n")
}
#let excerpt-at(title, path, from, to: none, n: 30, size: 7pt, skip: 0) = codepanel(title, excerpt-lines(path, from, to: to, n: n, skip: skip), size: size)
#let wholefile(title, path, size: 7pt) = codepanel(title, read(path).trim(at: end), size: size)

// ---------- unnumbered sub-heads ------------------------------------
#let sect(t) = heading(level: 2, numbering: none, t)
#let sub(t) = heading(level: 3, numbering: none, t)

// ---------- the NES controller, Gyromite style ----------------------
// The pad drawn in outline with right-angle leader lines to its labels.
#let controller(w: 3.6in) = {
  let s = w / 3.6in
  box(width: w, height: 1.35in * s, {
    let ox = 0.75in * s
    let oy = 0.18in * s
    let pw = 1.9in * s
    let ph = 0.82in * s
    let st = 0.7pt + ink
    // body and face
    place(dx: ox, dy: oy, rect(width: pw, height: ph, radius: 3pt, stroke: st))
    place(dx: ox + 0.06in * s, dy: oy + 0.12in * s,
      rect(width: pw - 0.12in * s, height: ph - 0.24in * s, radius: 2pt,
        stroke: 0.4pt + ink))
    // D-pad
    let cx = ox + 0.36in * s
    let cy = oy + ph / 2
    let a = 0.09in * s
    place(dx: cx - a, dy: cy - 3 * a, rect(width: 2 * a, height: 6 * a, stroke: st))
    place(dx: cx - 3 * a, dy: cy - a, rect(width: 6 * a, height: 2 * a, stroke: st))
    place(dx: cx - a + 0.4pt, dy: cy - a + 0.4pt,
      rect(width: 2 * a - 0.8pt, height: 2 * a - 0.8pt, fill: paper, stroke: none))
    // SELECT / START
    let sx = ox + 0.74in * s
    let sy = oy + 0.47in * s
    for i in (0, 1) {
      place(dx: sx + i * 0.25in * s, dy: sy, rect(width: 0.19in * s,
        height: 0.07in * s, radius: 1.5pt, fill: ink))
    }
    place(dx: sx - 0.03in * s, dy: oy + 0.24in * s, rect(width: 0.5in * s,
      height: 0.14in * s, stroke: 0.4pt + ink,
      align(center + horizon, text(size: 3.2pt * s, tracking: 0.05em)[SELECT START])))
    // B and A
    let bx = ox + 1.36in * s
    let r = 0.085in * s
    for (i, l) in ((0, "B"), (1, "A")) {
      place(dx: bx + i * 0.26in * s, dy: cy - r + 0.05in * s,
        circle(radius: r, fill: ink))
      place(dx: bx + i * 0.26in * s + r - 2pt, dy: cy - r - 0.1in * s,
        text(weight: 700, size: 5pt * s, l))
    }
    // leaders and labels
    let lab(x, y, body, al: left) = place(dx: x, dy: y - 4pt,
      text(size: 7.5pt * s, body))
    let hl(x1, y, x2) = place(dx: calc.min(x1, x2), dy: y,
      line(length: calc.abs(x2 - x1), stroke: 0.5pt + ink))
    let vl(x, y1, y2) = place(dx: x, dy: calc.min(y1, y2),
      line(angle: 90deg, length: calc.abs(y2 - y1), stroke: 0.5pt + ink))
    // control pad: leader left from the D-pad
    hl(0.62in * s, cy, cx - 3 * a)
    lab(0pt, cy - 5pt, align(right, box(width: 0.6in * s)[CONTROL\ PAD]))
    // select / start: down and left
    vl(sx + 0.09in * s, sy + 0.07in * s, oy + ph + 0.14in * s)
    hl(0.62in * s, oy + ph + 0.14in * s, sx + 0.09in * s)
    lab(0pt, oy + ph + 0.14in * s, align(right, box(width: 0.6in * s)[SELECT]))
    vl(sx + 0.34in * s, sy + 0.07in * s, oy + ph + 0.3in * s)
    hl(0.62in * s, oy + ph + 0.3in * s, sx + 0.34in * s)
    lab(0pt, oy + ph + 0.3in * s, align(right, box(width: 0.6in * s)[START]))
    // B and A: up and right
    let ty = oy - 0.06in * s
    vl(bx + r, cy - r + 0.05in * s, ty)
    hl(bx + r, ty, ox + pw + 0.12in * s)
    lab(ox + pw + 0.16in * s, ty, [B button])
    vl(bx + 0.26in * s + r, cy - r + 0.05in * s, ty + 0.16in * s)
    hl(bx + 0.26in * s + r, ty + 0.16in * s, ox + pw + 0.12in * s)
    lab(ox + pw + 0.16in * s, ty + 0.16in * s, [A button])
  })
}
