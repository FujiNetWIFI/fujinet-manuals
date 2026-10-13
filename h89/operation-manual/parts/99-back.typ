#import "../lib.typ": *

// The back cover, as the H88’s: gold, with a yellow band along the foot
// carrying the maker's name and its motto in spaced capitals.
#chapter-end()
#pagebreak(to: "even", weak: true)
#page(margin: 0pt, header: none, fill: gold)[
  #place(center + horizon, dy: -0.3in, block(width: 1.75in, {
    block(width: 100%, fill: yellow, stroke: 0.6pt + brown, inset: (y: 0.05in),
      align(center, text(font: f-sans, size: 9pt, weight: "bold", fill: brown)[FUJINET]))
    v(-0.12in)
    block(width: 100%, fill: brown, inset: (y: 0.07in),
      align(center, text(font: f-sans, size: 13pt, fill: yellow)[for the H89]))
  }))
  #place(bottom, block(width: 100%, height: 1.55in, fill: yellow, inset: (x: 0.5in, top: 0.3in), {
    set text(font: f-sans, fill: brown)
    align(center, text(size: 10pt, weight: "bold", tracking: 0.35em)[FUJINET PROJECT #h(0.5em) • #h(0.5em) FUJINET.ONLINE])
    v(0.08in)
    align(center, text(size: 10pt, weight: "bold", style: "oblique", tracking: 0.08em)[THE WORLD'S FRIENDLIEST NETWORK ADAPTERS FOR VINTAGE COMPUTERS])
    v(0.3in)
    align(center, text(size: 6pt, weight: "bold")[PRINTED WHEREVER YOU ARE])
  }))
]
