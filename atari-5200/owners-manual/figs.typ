// figs.typ -- the labelled pictures, shared by the book and tools/wikifig.typ.
// Each label's point comes from images/render/<view>.json, which
// tools/views.py writes from the model's own coordinates, so a leader always
// lands on the part it names.
#import "lib.typ": *

#let at(view, name) = json("images/render/" + view + ".json").at(name)
// a label: the point from the view; the label hangs just outside the
// picture's left or right edge (or above/below it with side: center), `dy`
// (a fraction of the picture's height) from the point
#let lab(view, name, side, dy, body, dx: 0) = {
  let p = at(view, name)
  let lx = if side == left { -0.03 + dx } else if side == right { 1.03 + dx }
           else { p.at(0) + dx }
  (p.at(0), p.at(1), lx, p.at(1) + dy, body, side)
}
// a second leader from a label to another point
#let also(view, name, from) = {
  let p = at(view, name)
  (p.at(0), p.at(1), from.at(2), from.at(3), none)
}
#let side-pad = (left: 0.78in, right: 0.78in, top: 6pt, bottom: 6pt)

// ---------- the cartridge -------------------------------------------
#let fig-face(w: 2.2in) = {
  let v = "cart-face"
  let pin = lab(v, "bootsel", left, 0.12, [Service holes])
  labelled("images/render/" + v + ".png", w: w, pad: side-pad, (
    lab(v, "reset", left, -0.08, [RESET button]),
    pin, also(v, "s3en", pin), also(v, "s3boot", pin),
    lab(v, "label_top", right, -0.1, [Label]),
    lab(v, "led_ws", right, -0.03, [Status light]),
    lab(v, "led_rp", right, 0.06, [Game light]),
    lab(v, "fingers", right, -0.02, [Connector]),
  ))
}
#let fig-top(w: 2.0in) = {
  let v = "cart-top"
  labelled("images/render/" + v + ".png", w: w, pad: side-pad, (
    lab(v, "card", left, -0.06, [microSD card]),
    lab(v, "plug", right, 0.08, [USB-C plug]),
    lab(v, "label", left, 0.2, [Label side]),
  ))
}
// the board: points measured on the KiCad render
#let fig-inside(w: 2.0in) = labelled("images/render/board-inside.png", w: w,
  pad: (left: 0.95in, right: 0.95in, top: 4pt, bottom: 4pt), (
  (0.148, 0.12, -0.03, 0.06, [Network chip \ (ESP32-S3, WiFi)], left),
  (0.10, 0.33, -0.03, 0.27, [Buttons], left),
  (0.38, 0.44, -0.03, 0.45, [Game chip \ (RP2354B)], left),
  (0.35, 0.71, -0.03, 0.7, [Bus buffer], left),
  (0.55, 0.09, 1.03, 0.04, [microSD socket], right),
  (0.84, 0.04, 1.03, 0.13, [USB-C socket], right),
  (0.70, 0.44, 1.03, 0.4, [Lights], right),
  (0.50, 0.96, 1.03, 0.9, [Connector], right),
))

// ---------- the console ---------------------------------------------
#let fig-insert(w: 2.7in) = {
  let v = "a52-insert"
  labelled("images/render/" + v + ".png", w: w,
    pad: (left: 0.7in, right: 0.7in, top: 6pt, bottom: 4pt), (
    lab(v, "v_label_top", left, -0.12, [FujiNet \ cartridge]),
    lab(v, "power", right, -0.12, [POWER \ switch]),
    lab(v, "lid", right, -0.12, [Storage lid]),
  ))
}
#let fig-jacks(w: 2.7in) = {
  let v = "a52-front"
  let j = lab(v, "jack1", left, 0.32, [Controller \ jacks 1--4])
  labelled("images/render/" + v + ".png", w: w,
    pad: (left: 0.7in, right: 0.7in, top: 6pt, bottom: 4pt), (
    lab(v, "power", right, -0.1, [POWER]),
    lab(v, "jack4", right, 0.14, [Jack 4]),
    lab(v, "jack1", left, 0.18, [Jack 1]),
  ))
}

// ---------- the controller ------------------------------------------
#let fig-controller(w: 1.4in) = {
  let v = "cx52"
  labelled("images/render/" + v + ".png", w: w,
    pad: (left: 1.0in, right: 1.0in, top: 6pt, bottom: 4pt), (
    lab(v, "start", left, -0.06, [START, PAUSE \ and RESET]),
    lab(v, "knob", right, -0.02, [Joystick]),
    lab(v, "fire_top", right, 0.1, [Two buttons \ on each side]),
    lab(v, "k1", left, 0.06, [Keypad]),
    lab(v, "star", left, 0.04, [\* key]),
    lab(v, "hash", right, 0.02, [\# key]),
  ))
}
#let fig-side(w: 2.6in) = {
  let v = "cx52-side"
  labelled("images/render/" + v + ".png", w: w,
    pad: (left: 0.75in, right: 0.75in, top: 6pt, bottom: 6pt), (
    lab(v, "fire_top", left, -0.3, [TOP BUTTON]),
    lab(v, "fire_bot", left, 0.3, [BOTTOM \ BUTTON]),
  ))
}

// ---------- How It Works --------------------------------------------
// The console only ever READS the cartridge; FujiNet hears which address it
// reads. A row of cells for the console's view of the cartridge window.
#let window-strip = {
  let cell(w, fill, body) = box(width: w, height: 30pt, fill: fill,
    stroke: 0.6pt + ink, inset: 2pt, align(center + horizon,
      text(size: 6.2pt, weight: 700, body)))
  stack(dir: ltr, spacing: 0pt,
    cell(1.25in, panel, [THE GAME \ #text(weight: 400)[\$4000--\$AFFF]]),
    cell(0.62in, lilac, [ANSWERS \ #text(weight: 400)[read to learn]]),
    cell(0.62in, rgb("#e6def0"), [QUESTIONS \ #text(weight: 400)[read to say]]),
    cell(0.75in, panel, [THE GAME \ #text(weight: 400)[\$B800--\$BFFF]]))
}

// ---------- the keypad overlay for the FujiNet menu -----------------
// Drawn, not to scale: a card with a window for each key and its job over
// it, as the booklet's overlays are lettered.
#let overlay-card = {
  let jobs = (("1", none), ("2", "UP"), ("3", none),
              ("4", "PAGE BACK"), ("5", none), ("6", "PAGE ON"),
              ("7", none), ("8", "DOWN"), ("9", none),
              ("*", "BACK"), ("0", none), ("#", "OPEN"))
  let cell(k, job) = box(width: 0.62in, height: 0.5in, {
    place(top + center, dy: 2pt, text(weight: 700, size: 5.6pt, fill: white,
      if job == none { [] } else { job }))
    place(bottom + center, dy: -3pt, box(width: 0.34in, height: 0.25in,
      radius: 3pt, fill: rgb("#2e2e32"), stroke: 0.6pt + rgb("#77727c"),
      align(center + horizon, text(weight: 700, size: 9pt, fill: k-gold, k))))
  })
  box(fill: rgb("#1c1b20"), radius: 4pt, inset: (x: 8pt, top: 7pt, bottom: 9pt),
    stroke: 0.8pt + ink, {
    align(center, {
      text(weight: 700, size: 7.6pt, fill: white, tracking: 0.6pt)[FUJINET MENU]
      v(1pt)
      text(size: 5.4pt, fill: rgb("#cfcfd2"))[PAUSE: RENAME · FILTER · CASE   START: INFO · COPY · OK]
    })
    v(3pt)
    grid(columns: 3, row-gutter: 2pt, column-gutter: 2pt,
      ..jobs.map(j => cell(j.at(0), j.at(1))))
  })
}
