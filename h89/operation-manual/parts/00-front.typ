#import "../lib.typ": *

// ================================================================ the cover
// The H88’s: gold all over, the maker's word in heavy brown capitals, a white
// label naming the machine, a brown three-tone picture, and the address in
// spaced capitals along the foot.
#page(margin: 0pt, header: none, fill: gold)[
  #set text(font: f-sans)
  #place(top + center, dy: 0.95in, block(width: 100%, align(center, {
    set text(fill: brown, weight: "bold", size: 58pt, tracking: -0.01em)
    set par(leading: 0.08em)
    scale(x: 112%, reflow: false, [FUJINET \ MANUAL])
  })))
  #place(top + center, dy: 3.15in, block(width: 3.55in, fill: white, stroke: 0.8pt + brown,
    inset: (x: 0.18in, top: 0.12in, bottom: 0.1in), {
      set text(fill: ink)
      align(center, text(size: 8.5pt, style: "oblique", [for the]))
      v(0.02in)
      align(center, text(size: 17pt, weight: "bold", tracking: 0.02em, [NETWORK ADAPTER]))
      v(0.05in)
      align(center, text(size: 14pt, [Model H89 FujiNet]))
      v(0.06in)
      grid(columns: (1fr, 1fr), align: (left, right), text(size: 7.5pt, [OPERATION]), text(size: 7.5pt, [FN-89-01]))
    }))
  #place(bottom + center, dy: -0.75in, image("../images/cover-board.png", width: 100%))
  #place(bottom + center, dy: -0.32in, text(size: 10pt, weight: "bold", fill: brown, tracking: 0.12em,
    [FUJINET PROJECT #h(0.6em) • #h(0.6em) FUJINET.ONLINE]))
]

// ===================================================== inside front cover
// Where the H88 has Heath's telephone directory and its 90-day warranty.
#page(header: none)[
  #set text(size: 8.6pt)
  #v(0.2in)
  #align(center, text(font: f-head, weight: "bold", size: 11pt)[FUJINET PROJECT DIRECTORY])
  #v(0.08in)
  #align(center)[The following addresses go straight to the people and things listed:]
  #v(0.06in)
  #block(inset: (x: 0.5in), {
    set text(size: 8.6pt)
    let d(a, b) = grid(columns: (1fr, auto), column-gutter: 0.3em,
      box(width: 100%, a + box(width: 1fr, repeat(gap: 0.12em)[.])), b)
    d[The FujiNet project, news and downloads][fujinet.online]
    d[FujiNet-Flasher (firmware updates)][fujinet.online/download]
    d[Help from other owners, any hour (Discord)][discord.gg/7MfFTvD]
    d[Source code for everything in this manual][github.com/FujiNetWIFI]
    d[The FNDISK drivers for HDOS and CP/M][github.com/FujiNetWIFI/fujinet-h89]
    d[The FujiNet Wiki][github.com/FujiNetWIFI/fujinet-firmware/wiki]
    d[Corrections to this manual][github.com/FujiNetWIFI/fujinet-manuals]
  })
  #v(0.28in)
  #align(center, text(font: f-head, weight: "bold", size: 11pt)[YOUR FUJINET GUARANTEE])
  #v(0.06in)
  #columns(2, gutter: 0.3in)[
    If you are not satisfied with your FujiNet -- the card, its programs, or this manual -- tell us.
    There is no Director of Customer Services, but there are a great many owners who will make
    certain your problem receives immediate, personal attention, usually within the hour, and
    usually from someone who has already met it on their own bench.

    Our guarantee is a short one, and needs no attorney. Every part of the FujiNet is yours to
    see: the schematics, the firmware, CONFIG, the FNDISK drivers and every program printed in
    this manual are free software, published under the GNU General Public License, version 3.
    You may read them, build them, change them and give them away, as long as you pass the same
    freedom along.

    #colbreak()
    The FujiNet is provided as it is, without warranty of any kind. We are not responsible for
    incidental or consequential damages, for a cold solder joint you made yourself, or for the
    hours you will lose browsing disk images you had forgotten you owned. We are, however,
    always glad to hear what you did with it.

    #v(0.4em)
    #text(size: 7.6pt)[Heath, Heathkit, HDOS and the model numbers of Heath equipment are
    trademarks of their owners. Zenith and Z-89 are trademarks of their owners. CP/M is a
    trademark of its owner. FujiNet is a community project, and is not affiliated with,
    endorsed by, or sponsored by Heath Company, Zenith Data Systems, or their successors. This
    manual borrows the look of Heath's 1979 Operation Manual for the H88 out of affection for
    it.]
  ]
]

// ========================================================== the title page
// Page 1-1 (it carries no head; the contents page is 1-2)
#page[
  #chap-start(1, nohead: true)
  #set text(font: f-sans)
  #v(2.1in)
  #align(center, {
    text(size: 25pt, weight: "bold")[FujiNet Manual]
    v(0.12in)
    text(size: 9pt, style: "oblique")[for the]
    v(0.1in)
    text(size: 15pt, weight: "bold", tracking: 0.02em)[NETWORK ADAPTER]
    v(0.12in)
    text(size: 14pt)[Model H89 FujiNet]
    v(0.04in)
    box(width: 3.1in, grid(columns: (1fr, 1fr), align: (left, right),
      text(size: 7.5pt)[OPERATION], text(size: 7.5pt)[FN-89-01]))
  })
  #place(bottom + left, dy: -0.1in, {
    text(size: 13pt, tracking: 0.12em)[FUJINET PROJECT]
    linebreak()
    text(size: 9pt, tracking: 0.18em)[FUJINET.ONLINE]
  })
  #place(bottom + right, dy: -0.1in, align(right, text(size: 6.8pt)[
    #text(weight: "bold")[Copyright © 2026] \
    Thomas Cherryhomes \
    #text(style: "oblique")[Free software: GNU GPL, version 3] \
    Third edition, October 2026 \
    Printed wherever you are]))
]

// ================================================================ contents
#v(0.25in)
#align(center, text(font: f-head, weight: "bold", size: 13pt)[TABLE OF CONTENTS])
#v(0.25in)
#contents()

