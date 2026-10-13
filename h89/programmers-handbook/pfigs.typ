// pfigs.typ -- the programmer's drawings: timing diagrams, frames, memory
// maps. (figs.typ is the Operation Manual's, kept as it is.)

#import "lib.typ": *

#let lw = 0.6pt + ink
#let thin = 0.4pt + ink

// ---------------------------------------------------------------- waveforms
// A timing diagram, as in Heath's circuit descriptions: one row per signal,
// time running left to right in arbitrary units.
//   rows: ((name, kind, events), ...)
//     kind "bit":  events = ((t, level), ...), level 0 or 1, starting at t=0
//     kind "bus":  events = ((t0, t1, label), ...): a value held from t0 to t1
//   marks: ((t, label), ...) dashed verticals with a label at the foot
#let wave(rows, tmax: 20, width: 3.2in, rowh: 0.26in, namew: 0.62in, marks: ()) = {
  let plotw = width - namew
  let x(t) = namew + plotw * t / tmax
  let h = rowh * 0.62
  box(width: width, height: rowh * rows.len() + 0.22in, {
    for (i, (name, kind, ev)) in rows.enumerate() {
      let y0 = i * rowh + (rowh - h) / 2          // top of the high level
      let y1 = y0 + h                              // the low level
      place(dx: 0pt, dy: y0 + h / 2 - 3.5pt, text(font: f-sans, size: 6.5pt, name))
      if kind == "bit" {
        let pts = ()
        let lvl = ev.at(0).at(1)
        let t0 = 0
        for (j, (t, l)) in ev.enumerate() {
          if j == 0 { lvl = l; t0 = t; continue }
          let y = if lvl == 1 { y0 } else { y1 }
          place(line(start: (x(t0), y), end: (x(t), y), stroke: lw))
          place(line(start: (x(t), y0), end: (x(t), y1), stroke: lw))
          lvl = l
          t0 = t
        }
        let y = if lvl == 1 { y0 } else { y1 }
        place(line(start: (x(t0), y), end: (x(tmax), y), stroke: lw))
      } else {
        // a bus: a pair of lines, crossing where it changes
        let cuts = (0,) + ev.map(e => e.at(0)) + ev.map(e => e.at(1)) + (tmax,)
        let d = plotw / tmax * 0.35
        for (t0, t1, lab) in ev {
          place(polygon(stroke: lw, fill: white,
            (x(t0), y0 + h / 2), (x(t0) + d, y0), (x(t1) - d, y0), (x(t1), y0 + h / 2),
            (x(t1) - d, y1), (x(t0) + d, y1)))
          place(dx: x(t0), dy: y0 + h / 2 - 3.6pt, box(width: x(t1) - x(t0),
            align(center, text(font: f-sans, size: 6pt, lab))))
        }
        // the idle stretches: a single mid line
        let busy = ev.map(e => (e.at(0), e.at(1)))
        let t = 0
        for (a, b) in busy.sorted() {
          if a > t { place(line(start: (x(t), y0 + h / 2), end: (x(a), y0 + h / 2), stroke: (paint: ink, thickness: 0.4pt, dash: "dotted"))) }
          t = b
        }
        if t < tmax { place(line(start: (x(t), y0 + h / 2), end: (x(tmax), y0 + h / 2), stroke: (paint: ink, thickness: 0.4pt, dash: "dotted"))) }
      }
    }
    for (t, lab) in marks {
      place(line(start: (x(t), 0pt), end: (x(t), rowh * rows.len() + 0.04in),
        stroke: (paint: ink.lighten(30%), thickness: 0.4pt, dash: "dashed")))
      place(dx: x(t) - 0.3in, dy: rowh * rows.len() + 0.05in, box(width: 0.6in,
        align(center, text(font: f-sans, size: 6pt, lab))))
    }
  })
}

// sending a byte: the H89 writes port A; /OBF falls; the ESP32 takes it
// with /ACK; /OBF rises again
#let send-timing() = wave(tmax: 20, (
  ("DIR (PC0)", "bit", ((0, 1), (20, 1))),
  ("WR", "bit", ((0, 1), (2, 0), (4, 1))),
  ("PA0-PA7", "bus", ((2, 13, [the byte]),)),
  ("/OBF (PC7)", "bit", ((0, 1), (4, 0), (12, 1))),
  ("/ACK (PC6)", "bit", ((0, 1), (9, 0), (12, 1))),
), marks: ((2, [1]), (4, [2]), (9, [3]), (12, [4])))

// receiving a byte: the ESP32 strobes it in; IBF rises; the H89 reads it
#let recv-timing() = wave(tmax: 20, (
  ("DIR (PC0)", "bit", ((0, 0), (20, 0))),
  ("/STB (PC4)", "bit", ((0, 1), (3, 0), (6, 1))),
  ("PA0-PA7", "bus", ((2, 7, [the byte]),)),
  ("IBF (PC5)", "bit", ((0, 0), (5, 1), (14, 0))),
  ("RD", "bit", ((0, 1), (12, 0), (14, 1))),
), marks: ((3, [1]), (5, [2]), (12, [3]), (14, [4])))

// starting the ESP32 (card_on)
#let start-timing() = wave(tmax: 24, width: 3.2in, (
  ("EN (PC2)", "bit", ((0, 0), (2, 1), (4, 0), (7, 1))),
  ("IO0 = PC1", "bit", ((0, 0), (2, 1), (16, 0))),
  ("DIR (PC0)", "bit", ((0, 0), (24, 0))),
), marks: ((2, [mode 2]), (4, [reset]), (7, [run]), (16, [245 on])))

// ---------------------------------------------------------------- frames
// a row of labelled boxes, for a frame's layout
#let fieldrow(cells, h: 0.3in) = {
  // cells: ((width, label, sub), ...)
  set text(font: f-sans, size: 6.6pt)
  grid(columns: cells.map(c => c.at(0)), column-gutter: 0pt,
    ..cells.map(c => rect(width: 100%, height: h, stroke: lw, inset: 2pt,
      fill: c.at(3, default: white),
      align(center + horizon, [#c.at(1) #if c.at(2) != none [\ #text(size: 5.6pt, c.at(2))]]))))
}

// ---------------------------------------------------------------- memory maps
// a column of regions, top of memory first: ((top, bottom, label, mark), ...)
#let memmap(rows, w: 1.9in, unit: 0.1in) = {
  set text(font: f-sans, size: 6.6pt)
  grid(columns: (0.5in, w), row-gutter: 0pt,
    ..rows.map(r => (
      align(right + top, pad(right: 4pt, text(font: f-scrn, size: 7pt, r.at(0)))),
      rect(width: 100%, height: r.at(4, default: 0.3in), stroke: lw,
        fill: if r.at(3, default: false) { yellow } else { white },
        align(center + horizon, r.at(2))),
    )).flatten())
}
