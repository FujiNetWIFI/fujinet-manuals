// figs.typ -- the labelled pictures, shared by the book and tools/wikifig.typ.
// Each label's point comes from images/render/<view>.json, which
// tools/views.py writes from the model's own coordinates, so a leader always
// lands on the part it names. Labels are words, or the numbers of the list
// under the picture, as the Owner's Manual's page 3 numbers its parts.
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
#let side-pad = (left: 1.3in, right: 1.3in, top: 6pt, bottom: 6pt)
#let num(n) = text(weight: 700, size: 10pt, str(n))

// ---------- the cartridge -------------------------------------------
#let fig-hero = fig(art("cart-hero", w: 1.45in), above: 0.8em, below: 0.8em,
  caption: [The FujiNet cartridge])

// the back, toward the television: numbered as the list under it
#let fig-back = {
  let v = "cart-back"
  let pin = lab(v, "s3rst", left, 0.0, num(4))
  fig(labelled("images/render/" + v + ".png", w: 2.4in, pad: side-pad, (
    lab(v, "led_ws", right, -0.12, num(1)),
    lab(v, "led_rp", right, -0.04, num(2)),
    lab(v, "reset", left, -0.04, num(3)),
    pin, also(v, "bootsel", pin), also(v, "s3boot", pin),
    lab(v, "fingers_back", right, -0.02, num(5)),
  )), caption: [The back of the cartridge, toward the television])
}
#let fig-top = {
  let v = "cart-top"
  fig(labelled("images/render/" + v + ".png", w: 2.6in, pad: side-pad, (
    lab(v, "plug", right, -0.08, num(1)),
    lab(v, "card", right, 0.06, num(2)),
    lab(v, "label", left, 0.05, [Label]),
  )), caption: [The top edge and the right-hand side, with a charger and a
    memory card plugged in])
}
#let fig-power = fig(art("cart-power", w: 1.8in), caption: [A USB-C charger
  plugged in])
// the board, from its back (parts) side: points measured on the KiCad render
#let fig-inside = fig(labelled("images/render/board-inside.png", w: 2.6in,
  pad: (left: 1.45in, right: 1.45in, top: 4pt, bottom: 4pt), (
  (0.10, 0.045, -0.03, 0.03, [USB-C socket], left),
  (0.11, 0.24, -0.03, 0.2, [microSD socket], left),
  (0.05, 0.49, -0.03, 0.47, [Buttons: RESET \ and the service \ buttons], left),
  (0.48, 0.93, -0.03, 0.85, [Contacts], left),
  (0.81, 0.16, 1.03, 0.1, [Network chip \ (ESP32-S3, WiFi)], right),
  (0.45, 0.26, 1.03, 0.27, [Lights], right),
  (0.57, 0.475, 1.03, 0.47, [Game chip \ (RP2354A)], right),
)), caption: [The FujiNet Arcadia board, Rev0, from the back. The network chip
  does the WiFi, the memory card and the talking to servers; the game chip
  answers the console and plays the part of each game’s cartridge.])

// ---------- the console ---------------------------------------------
#let fig-insert = {
  let v = "adv1-insert"
  fig(labelled("images/render/" + v + ".png", w: 4.2in,
    pad: (left: 1.05in, right: 1.05in, top: 6pt, bottom: 4pt), (
    lab(v, "cart_label_top", right, -0.06, [FujiNet \ cartridge]),
    lab(v, "led", right, 0.02, [POWER light]),
    lab(v, "power", right, 0.12, [POWER switch]),
    lab(v, "reset", left, -0.12, [RESET]),
    lab(v, "well_l", left, 0.12, [Hand controller \ (in its place)]),
  )), caption: [The cartridge in the ARCADIA-2001])
}
#let fig-rear = {
  let v = "adv1-rear"
  fig(labelled("images/render/" + v + ".png", w: 3.8in,
    pad: (left: 1.15in, right: 1.15in, top: 6pt, bottom: 4pt), (
    lab(v, "out_cable", right, -0.12, [Output cable, \ to the antenna \ switch box]),
    lab(v, "chan_sw", left, 0.22, [Channel 3-4 switch]),
    lab(v, "dc_jack", left, 0.3, [AC adaptor jack]),
    lab(v, "cart_label_top", left, -0.06, [The cartridge’s \ lights and RESET \ face this way]),
  )), caption: [The ARCADIA-2001 from behind])
}
#let fig-panel = {
  let v = "adv1-panel"
  fig(labelled("images/render/" + v + ".png", w: 3.2in,
    pad: (left: 0.9in, right: 0.9in, top: 6pt, bottom: 4pt), (
    lab(v, "reset", left, 0.12, [RESET]),
    lab(v, "start", left, 0.24, [SELECT, OPTION, \ START]),
    also(v, "select", (0, 0, -0.03, 0.87)),
    also(v, "option", (0, 0, -0.03, 0.87)),
    lab(v, "led", right, -0.1, [POWER light]),
    lab(v, "power", right, 0.06, [POWER switch]),
    lab(v, "slot", left, -0.08, [Cartridge slot]),
  )), caption: [The console’s buttons])
}

// ---------- the hand controller -------------------------------------
#let fig-controller = {
  let v = "ctl"
  fig(labelled("images/render/" + v + ".png", w: 2.0in,
    pad: (left: 1.35in, right: 1.35in, top: 4pt, bottom: 4pt), (
    lab(v, "keypad", left, 0.02, [Keyboard]),
    lab(v, "action_l", left, 0.08, [Action button \ (one each side)]),
    also(v, "action_r", (0, 0, -0.03, 0.62)),
    lab(v, "disc", right, 0.08, [Control disc]),
    lab(v, "cord", right, 0.04, [Coil cord, \ to the console]),
  )), caption: [The hand controller])
}

// ---------- How It Works --------------------------------------------
// The console only ever READS the cartridge; FujiNet hears which address it
// reads. A row of cells for the console's view of the cartridge window.
#let window-strip = {
  let cell(w, fill, body) = box(width: w, height: 0.62in, fill: fill,
    stroke: 0.8pt + ink, inset: 3pt, align(center + horizon,
      text(size: 8.5pt, weight: 700, body)))
  stack(dir: ltr, spacing: 0pt,
    cell(1.55in, paper, [THE PROGRAM \ #text(weight: 400)[\$0000--\$0FFF]]),
    h(0.12in),
    cell(1.35in, paper, [THE PROGRAM \ #text(weight: 400)[\$2000--\$2AFF]]),
    cell(0.95in, tint, [ANSWERS \ #text(weight: 400)[read to learn]]),
    cell(1.1in, rgb("#d4d4d4"), [QUESTIONS \ #text(weight: 400)[read to say]]))
}
