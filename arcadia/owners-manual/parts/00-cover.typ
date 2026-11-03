#import "../lib.typ": *
// ---------- the cover -----------------------------------------------
// After the 1982 Owner's Manual's: the ARCADIA-2001 lettering across the
// top, the three bars under it with the maker's line beside them, a
// television's outline holding the product's name in condensed capitals,
// the console drawn over its lower corner, and OWNER'S MANUAL with the
// model number along the foot. FujiNet's mark stands where the maker's was.
#page(margin: 0pt, footer: none, {
  set par(justify: false)
  // the lettering
  place(top + left, dx: 0.95in, dy: 0.62in,
    text(font: f-wm, size: 64pt, tracking: -0.5pt)[ARCADIA-2001])
  place(top + left, dx: 0.95in, dy: 1.62in, bars(h: 0.62in))
  place(top + left, dx: 3.3in, dy: 1.78in, {
    box(baseline: -0.3in, text(weight: 700, size: 14pt)[WITH])
    h(10pt)
    box(image("../images/fujinet-logo-trans.png", width: 2.9in))
  })
  // the television
  place(top + left, dx: 0.95in, dy: 2.75in, rect(width: 6.0in, height: 4.55in,
    radius: 0.55in, stroke: 3pt + ink))
  place(top + left, dx: 1.45in, dy: 3.1in, stack(spacing: 0.16in,
    bars(h: 0.42in),
    block({
      set par(leading: 0.24em)
      text(font: f-narrow, weight: 700, stretch: 87.5%, size: 42pt, tracking: 0.5pt)[
        NETWORK \ ADAPTER \ CARTRIDGE]
    })))
  // the console, over the television's lower corner
  place(top + left, dx: 2.45in, dy: 5.3in, image("../images/render/adv1-cover.png",
    width: 5.6in))
  // the foot
  place(bottom + left, dx: 0.95in, dy: -0.62in,
    text(weight: 700, size: 26pt, tracking: 0.5pt)[OWNER’S MANUAL])
  place(bottom + right, dx: -0.85in, dy: -0.66in,
    text(weight: 700, size: 10pt)[MODEL NO. FN2001-OM])
})

// ---------- inside cover --------------------------------------------
#page(footer: none, {
  set par(justify: false)
  text(weight: 700, size: 15pt, tracking: 0.3pt)[IN A HURRY?]
  v(4pt)
  steps(
    [With the console’s POWER OFF, push the FujiNet cartridge into the slot,
     label toward you. Plug a USB-C phone charger into its top.],
    [Turn the television to channel 3 or 4 and the switch box to GAME. Press
     POWER ON.],
    [SELECT NETWORK: move to your WiFi network with the left hand
     controller’s disc and press the Action button.],
    [Spell the password on the character grid -- disc to move, Action button
     to type, ENTER when done.],
    [On FujiNet hosts, open APPS.IRATA.ONLINE, then ARCADIA, and choose a
     game.],
    [To come back: RESET on the back of the cartridge, then the console’s
     RESET.],
  )
  v(1fr)
  set text(size: 8.5pt, fill: gray)
  [*FujiNet Owner’s Manual for the EMERSON ARCADIA-2001.* First edition,
  2026.]
  v(0.45em)
  [Typeset after the 1982 Emerson _ARCADIA-2001 Owner’s Manual_ and the
  Emerson game instruction booklets of the same year, as a tribute. FujiNet is
  an independent project and is not affiliated with, endorsed by, or sponsored
  by Emerson Radio Corp. “Emerson” and “Arcadia 2001” are trademarks of their
  owners and are used here to identify the console this manual is about. The
  games named in it are the FujiNet project’s own, except M.U.L.E., a
  trademark of its owner, and the games of Section 17, which belong to their
  makers.]
  v(0.45em)
  [This manual describes the FujiNet cartridge for the ARCADIA-2001 as it is
  meant to work. The cartridge is new, and the drawings of it and of the
  console are the manual’s own; the screens are the cartridge’s own programs,
  captured running in the FujiNet MAME. Where today’s firmware and games still
  differ, the differences are listed in the manual’s errata, kept with its
  sources.]
  v(0.45em)
  [Text and pictures © 2026 the FujiNet Project, CC BY-SA 4.0.]
})

// ---------- contents ------------------------------------------------
#page(footer: none, {
  chap(none, [Contents])
  set par(justify: false)
  show outline.entry.where(level: 1): it => {
    v(9pt, weak: true)
    link(it.element.location(), text(size: 11pt, {
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
