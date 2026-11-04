#import "../lib.typ": *
// ---------- the back cover --------------------------------------------
#page(margin: 0pt, footer: none, {
  place(top + left, dx: 0.95in, dy: 0.62in,
    text(font: f-wm, size: 40pt, tracking: -0.5pt)[ARCADIA-2001])
  place(top + left, dx: 0.95in, dy: 1.3in, bars(h: 0.4in))
  place(center + horizon, dy: -0.3in, box(width: 4.2in, {
    set par(justify: false, leading: 0.6em)
    align(center, image("../images/fujinet-logo-trans.png", width: 2.6in))
    v(14pt)
    align(center, text(size: 11pt)[A FujiNet Project publication])
  }))
  place(bottom + left, dx: 0.95in, dy: -0.66in,
    text(weight: 700, size: 10pt)[FN2001-PH #h(0.6em) REV. A])
  place(bottom + right, dx: -0.85in, dy: -0.66in,
    text(size: 10pt)[Typeset in Helvetica])
})
