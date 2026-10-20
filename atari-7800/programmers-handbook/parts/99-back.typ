#import "../lib.typ": *
// ---------- the back cover ------------------------------------------
// The booklet's back: grey graph paper, the maker's mark low and centred,
// the part number, address and printing line along the foot.
#frontmatter.update(true)
#pagebreak(to: "even", weak: true)
#page(margin: 0pt, footer: none, background: none, fill: cover-g, {
  set par(justify: false)
  place(top + left, rect(width: 100%, height: 100%, fill: graph(c: white, w: 0.7pt)))
  place(top + center, dy: 4.75in, align(center, {
    image("../images/fujinet-logo.png", width: 0.75in)
    v(2pt)
    text(font: f-bold, weight: 500, size: 6.6pt, fill: ink)[A FujiNet Project Publication]
  }))
  place(bottom + left, dx: 0.3in, dy: -band-h - 0.14in,
    text(size: 5.6pt, fill: ink)[FN7800-PH REV. A])
  place(bottom + center, dy: -band-h - 0.12in, align(center,
    text(size: 5.6pt, fill: ink)[fujinet.online · github.com/FujiNetWIFI \
      © 2026 the FujiNet Project. CC BY-SA 4.0]))
  place(bottom + right, dx: -0.3in, dy: -band-h - 0.14in,
    text(size: 5.6pt, fill: ink)[Printed in the FujiNet Project])
  place(bottom + left, rect(width: 100%, height: band-h, fill: magenta))
})
