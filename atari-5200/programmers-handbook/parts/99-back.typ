#import "../lib.typ": *
// ---------- the back cover ------------------------------------------
// The booklet's back: black, the stripe, the maker's mark low and centred
// over its address, a double rule, and the part number, copyright and
// printing line along the foot.
#frontmatter.update(true)
#pagebreak(to: "even", weak: true)
#page(margin: 0pt, footer: none, background: none, fill: cover-k, {
  set par(justify: false)
  place(top + left, rect(width: 100%, height: 100%,
    fill: graph(c: rgb("#24232e"), w: 0.5pt, p: 0.135in)))
  place(top + left, dy: 0.84in, rect(width: 100%, height: 0.1in, fill: rainbow))
  place(top + center, dy: 4.55in, align(center, {
    image("../images/fujinet-logo-white.png", width: 0.72in)
    v(3pt)
    text(size: 6.4pt, fill: white)[A FujiNet Project Publication]
    v(9pt)
    text(size: 7.6pt, fill: white)[The FujiNet Project \ fujinet.online · github.com/FujiNetWIFI]
  }))
  place(bottom + left, dx: 0.24in, dy: -0.52in, {
    line(length: 4.52in, stroke: 0.6pt + white)
    v(-8.4pt)
    line(length: 4.52in, stroke: 0.6pt + white)
  })
  place(bottom + left, dx: 0.24in, dy: -0.24in,
    text(size: 6.6pt, fill: white)[FN5200-PH REV. A])
  place(bottom + center, dy: -0.18in, align(center,
    text(weight: 700, size: 7pt, fill: white)[© 2026 the FujiNet Project \ CC BY-SA 4.0]))
  place(bottom + right, dx: -0.24in, dy: -0.24in,
    text(size: 6.6pt, fill: white)[Printed in the FujiNet Project])
})
