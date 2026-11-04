#import "../lib.typ": *
// ---------- the cover -----------------------------------------------
// The Owner's Manual's, after the 1982 ADV-1's: the ARCADIA-2001 lettering,
// the three bars with FujiNet's mark where the maker's line was, a
// television's outline with the product's name in condensed capitals, the
// console over its corner, and the book's name and model number along the
// foot.
#page(margin: 0pt, footer: none, {
  set par(justify: false)
  place(top + left, dx: 0.95in, dy: 0.62in,
    text(font: f-wm, size: 64pt, tracking: -0.5pt)[ARCADIA-2001])
  place(top + left, dx: 0.95in, dy: 1.62in, bars(h: 0.62in))
  place(top + left, dx: 3.3in, dy: 1.78in, {
    box(baseline: -0.3in, text(weight: 700, size: 14pt)[WITH])
    h(10pt)
    box(image("../images/fujinet-logo-trans.png", width: 2.9in))
  })
  place(top + left, dx: 0.95in, dy: 2.75in, rect(width: 6.0in, height: 4.55in,
    radius: 0.55in, stroke: 3pt + ink))
  place(top + left, dx: 1.45in, dy: 3.1in, stack(spacing: 0.16in,
    bars(h: 0.42in),
    block({
      set par(leading: 0.24em)
      text(font: f-narrow, weight: 700, stretch: 87.5%, size: 42pt, tracking: 0.5pt)[
        PROGRAMMING \ THE NETWORK \ CARTRIDGE]
    })))
  place(top + left, dx: 2.45in, dy: 5.3in, image("../images/render/adv1-cover.png",
    width: 5.6in))
  place(bottom + left, dx: 0.95in, dy: -0.62in,
    text(weight: 700, size: 22pt, tracking: 0.5pt)[PROGRAMMER’S HANDBOOK])
  place(bottom + right, dx: -0.85in, dy: -0.66in,
    text(weight: 700, size: 10pt)[MODEL NO. FN2001-PH])
})

// ---------- inside cover --------------------------------------------
#page(footer: none, {
  set par(justify: false)
  text(weight: 700, size: 15pt, tracking: 0.3pt)[IN A HURRY?]
  v(4pt)
  steps(
    [Build the Macroassembler AS, and MAME with the FujiNet cartridge
     grafted in (Section 2).],
    [Start the bench: `bench/up.sh` runs a fujinet-pc of the book’s own and
     the two little servers the network programs talk to.],
    [Build every program: `make listings`.],
    [Run one: `emu/run.sh listings/asm/build/fujitest.bin`. Its screen
     shows the adapter’s network name, firmware version and address.],
    [Read Section 4, How the Mailbox Works, before you write a line: a
     console that can only read its cartridge talks to the network by
     reading, and everything else follows from that.],
  )
  v(1fr)
  set text(size: 8.5pt, fill: gray)
  [*FujiNet Programmer’s Handbook for the EMERSON ARCADIA-2001.* First
  edition, 2026.]
  v(0.45em)
  [Typeset after the 1982 Emerson _ARCADIA-2001 Owner’s Manual_ and the
  Emerson game instruction booklets of the same year, as the FujiNet
  _Owner’s Manual_ for the Arcadia is. FujiNet is an independent project and
  is not affiliated with, endorsed by, or sponsored by Emerson Radio Corp.
  “Emerson” and “Arcadia 2001” are trademarks of their owners and are used
  here to identify the console this book is about. “M.U.L.E.” is a trademark
  of its owner.]
  v(0.45em)
  [No FujiNet Arcadia cartridge has been built yet. Every program in this
  book was assembled from its listing and run on the FujiNet model of the
  cartridge in MAME, which compiles the cartridge’s own firmware sources,
  against a fujinet-pc built from the same firmware; each one’s screen was
  checked by a script. Where a real console may differ, the text says so.]
  v(0.45em)
  [Text, pictures and programs © 2026 the FujiNet Project. Text and pictures
  CC BY-SA 4.0; the programs GPL-3.0, as the firmware they come from.]
})

// ---------- contents ------------------------------------------------
#page(footer: none, {
  chap(none, [Contents])
  set par(justify: false)
  show outline.entry.where(level: 1): it => {
    v(7.5pt, weak: true)
    link(it.element.location(), text(size: 10.5pt, {
      let pre = it.prefix()
      box(width: 0.42in, if pre != none { text(weight: 700, pre) })
      upper(it.body())
      box(width: 1fr, repeat([.], gap: 3pt))
      h(4pt)
      it.page()
    }))
  }
  outline(title: none, depth: 1, indent: 0pt)
})
#frontmatter.update(false)
#counter(page).update(1)
