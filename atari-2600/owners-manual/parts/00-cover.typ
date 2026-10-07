#import "../lib.typ": *
// ---------- the cover -----------------------------------------------
// After the 1977 cover: black, the white wordmark in three lines, a
// white-framed picture of the console among its screens, OWNER'S MANUAL and
// the model line, the logo, the address.
#page(fill: rgb("#0b0b0b"), margin: (x: 0.42in, top: 0.32in, bottom: 0.3in),
      footer: none, {
  set text(fill: white)
  set par(justify: false)
  place(top + left, text(font: f-head, size: 6.5pt, fill: rgb("#cfcfcf"))[© 2026 FUJINET PROJECT])
  place(top + right, text(font: f-head, size: 6.5pt, fill: rgb("#cfcfcf"))[FN2600-OM])
  v(0.22in)
  let wm(s) = text(font: f-wordmk, weight: 900, size: 40pt, fill: white,
    top-edge: "cap-height", bottom-edge: "baseline", s)
  align(center, stack(dir: ttb, spacing: 6pt,
    wm[VIDEO], wm[COMPUTER],
    box({ wm[SYSTEM]; h(1pt); box(baseline: -22pt, text(font: f-head, size: 7pt)[TM]) })))
  v(0.12in)
  // the picture: a row of screens over the console, in a white frame
  align(center, box(fill: white, inset: 3.5pt, box(width: 100%,
    fill: rgb("#3b3f46"), clip: true, inset: (x: 6pt, top: 6pt, bottom: 0pt), {
      let scrn(f) = image("../images/screens/" + f + ".png", height: 0.6in)
      align(center, stack(dir: ltr, spacing: 4pt,
        scrn("bs-play2"), scrn("th-0007"), scrn("fz-card"),
        scrn("mule-08-develop-town"), scrn("bs-play4")))
      v(-0.02in)
      align(center, image("../images/render/vcs-cover.png", width: 98%))
    })))
  v(0.16in)
  align(center, {
    set par(leading: 0.2em)
    text(font: f-head, weight: 700, size: 25pt, fill: white, tracking: 0.3pt)[OWNER'S MANUAL]
    v(1pt)
    text(font: f-head, size: 9.5pt, fill: white)[MODEL CX2600 · FUJINET NETWORK CARTRIDGE]
  })
  v(1fr)
  align(center, image("../images/fujinet-logo-white.png", width: 1.25in))
  v(0.08in)
  align(center, text(font: f-head, size: 7.5pt, fill: rgb("#cfcfcf"))[A FujiNet Project Publication])
  v(0.1in)
  align(center, text(font: f-head, size: 6.8pt, fill: rgb("#cfcfcf"))[FUJINET PROJECT · fujinet.online · github.com/FujiNetWIFI])
})

// ---------- inside cover: quick start --------------------------------
#page(footer: none, {
  block(width: 100%, fill: ink, inset: (x: 8pt, y: 5pt),
    text(font: f-head, weight: 700, size: 12.5pt, fill: white)[IN A HURRY?])
  v(6pt)
  set par(justify: false)
  [Everything in this booklet is in the numbered sections that follow. If
  you have played with a FujiNet before, this is all there is to it:]
  v(2pt)
  steps(
    [With the console *OFF*, push the FujiNet cartridge into the slot,
     label toward you. Plug a joystick into *LEFT CONTROLLER*.],
    [Slide the *POWER* switch *ON*. The FujiNet menu appears.],
    [Pick your WiFi network with the joystick and press the *red button*
     ("fire"). Spell the password on the on-screen keyboard. (Section 6.)],
    [On the *FN HOSTS* screen, move to *apps.irata.online* and press fire.
     Open *Atari_2600*.],
    [Move to a game and press fire. It loads and starts by itself.],
    [To come back to the FujiNet menu, press the *RESET button on the
     cartridge* (not the console's GAME RESET switch).],
  )
  v(1fr)
  set text(size: 7.4pt, fill: gray)
  [*FujiNet Video Computer System Owner's Manual.* First edition, 2026.]
  v(0.4em)
  [Typeset after the 1977 _Video Computer System Owner's Manual_ as a tribute. FujiNet is an independent, open-source project and is not affiliated with, endorsed by, or sponsored by Atari. "Atari", "Video Computer System", "Combat", "Video Olympics" and "Dodge 'Em" are trademarks of their owners; "Dragster" and "Tennis" are Activision titles; "M.U.L.E." is a trademark of its owner. They are used here only to identify the console and the games this booklet is about.]
  v(0.4em)
  [The cartridge shell is a re-model of "Atari 2600 Cartridge Shell -- Easy Print" by norm8332 (Thingiverse 1790785, CC BY). The pictures of the cartridge and the console are drawn from the FujiNet hardware design files; the screens are taken from the FujiNet cartridge running in MAME against a FujiNet adapter.]
  v(0.4em)
  [Text and pictures © 2026 the FujiNet Project, CC BY-SA 4.0.]
})

// ---------- contents ------------------------------------------------
#page(footer: none, {
  block(width: 100%, fill: ink, inset: (x: 8pt, y: 5pt),
    text(font: f-head, weight: 700, size: 12.5pt, fill: white)[CONTENTS])
  v(10pt)
  set par(justify: false)
  show outline.entry.where(level: 1): it => {
    v(6.5pt, weak: true)
    text(font: f-head, weight: 700, size: 9.4pt, it)
  }
  outline(title: none, depth: 1, indent: 0pt)
  v(1fr)
  rules[The technical side of the cartridge -- how it answers a console that
  has no network port, and how to write programs for it -- is told in the
  #PH and in #TO. This booklet tells you how to use it.]
})
#frontmatter.update(false)
#counter(page).update(1)
