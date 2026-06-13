// ============================================================
// THE FUJINET WIFI PERIPHERAL — OWNER'S GUIDE
// for Atari Home Computers
//
// Designed after the early Atari home computer manuals,
// 1980–1982: "The ATARI 800 Home Computer Owner's Guide"
// (CO60057) and "ATARI 1050 Disk Drive: An Introduction to
// the Disk Operating System" (C061529).
//
// Build: typst compile --font-path fonts manual.typ
// ============================================================

// ---------- fonts ----------
// "Futura" carries two vendored cuts: Futura Extra Bold (weight 700,
// display) and Futura LT Book (weight 400, labels & section heads).
#let f-head = "Futura"            // use with weight: 700 (Extra Bold)
#let f-sans = "Futura"            // default weight 400 (Futura LT)
#let f-body = "Rockwell Std"      // Light cut (weight 300) for body
#let f-mark = "Harry"             // Harry Fatt — the ATARI-logo face
#let f-scrn = "EightBit Atari"    // the genuine Atari ROM character set

// ---------- palette ----------
#let ink = rgb("#221f1c")
#let cream = rgb("#f2eee3")        // warm interior stock
#let silver = rgb("#b9bcbe")       // silver foil pages
#let silver-line = rgb("#cdd0d2")  // pinstripe on silver
#let cover-gray = rgb("#c6c8c5")   // 800 guide cover gray
#let navy = rgb("#1d3060")         // inside-cover blue
#let toc-blue = rgb("#2b4fa3")     // contents entries
#let scr-bg = rgb("#1c2f96")       // CONFIG's GR.0 dark blue
#let scr-fg = rgb("#dfe4f5")       // GR.0 text luminance
#let scr-red = rgb("#b03a36")      // CONFIG's red bar (radio off)
#let cap-fill = rgb("#c9c6bd")     // keycap gray
#let cap-line = rgb("#6b665e")

// cube palette, straight off the 1050 booklet
#let cubes-c = (rgb("#d23b2e"), rgb("#e0457f"), rgb("#eda4c0"),
                rgb("#e8871f"), rgb("#edc522"), rgb("#3f9e58"),
                rgb("#7ec98c"), rgb("#3b76c0"), rgb("#27897a"),
                rgb("#7b52a8"))

// ============================================================
// COMPONENTS
// ============================================================

#let tm = super(text(size: 0.45em, tracking: 0pt)[TM])
#let rg = super(text(size: 0.45em, tracking: 0pt)[®])

// screen-font run from a string (strings are safe for "//" in URLs)
#let sf(s, size: 6.6pt) = text(font: f-scrn, size: size, s)

// --- chapter heads: stacked Futura Extra Bold caps + black band ---
#let secmark(title) = metadata((title: title))
#let headband(..lines, right: false, fg: ink, band: black) = {
  let ls = lines.pos()
  block(above: 0pt, below: 1.5em, width: 100%, {
    set par(leading: 0.22em, spacing: 0.22em, first-line-indent: 0pt)
    set text(font: f-head, weight: 700, size: 23pt, fill: fg,
             tracking: 0.4pt)
    set align(if right { right } else { left })
    for l in ls { par(upper(l)) }
    v(8pt)
    move(dx: -0.6in, rect(width: 8.5in, height: 11pt, fill: band))
  })
}

// --- section heads: Futura LT, like the originals' light subheads ---
#let lsub(t) = block(above: 1.15em, below: 0.5em,
  text(font: f-sans, weight: 400, size: 9.5pt,
       tracking: 0.45pt, fill: ink, upper(t)))

// --- big numbered step, 800-guide style ---
#let bstep(n, body) = block(above: 0.85em, below: 0.85em,
  grid(columns: (0.3in, 1fr), column-gutter: 4pt,
    text(font: f-head, weight: 700, size: 16pt, fill: ink,
         baseline: 2pt, str(n)),
    body))

// --- itemized list entry: square bullet, Futura Extra Bold ---
#let item(body) = block(above: 0.55em, below: 0.55em,
  grid(columns: (0.16in, 1fr), column-gutter: 3pt,
    move(dy: 1.6pt, square(size: 4.6pt, fill: ink)),
    par(leading: 0.45em, first-line-indent: 0pt,
      text(font: f-head, weight: 700, size: 8pt, tracking: 0.15pt,
           body))))

// --- drawn keycap (the 1050's gray RETURN cap) ---
#let key(label) = box(baseline: 22%,
  rect(fill: cap-fill, stroke: 0.6pt + cap-line, radius: 1.6pt,
       inset: (x: 3.2pt, y: 2.2pt),
       text(font: f-sans, weight: 400, size: 5.8pt,
            fill: ink, tracking: 0.3pt, upper(label))))

// --- COMPUTER: / YOU TYPE: dialogue rows ---
#let dsay(who, what) = grid(columns: (0.92in, 1fr), column-gutter: 7pt,
  align: (right + top, left + top),
  text(font: f-body, size: 7.6pt, fill: ink, upper(who) + ":"),
  {
    set text(font: f-scrn, size: 6.6pt, fill: ink)
    set par(leading: 3.6pt, first-line-indent: 0pt)
    what
  })
#let dialogue(..rows) = block(breakable: false, above: 0.9em, below: 0.9em,
  stack(spacing: 4.6pt, ..rows.pos().map(r => dsay(r.at(0), r.at(1)))))

// --- CONFIG screens, drawn in the genuine Atari ROM font ---
#let iv(s) = box(fill: scr-fg, outset: (y: 0.6pt, x: 0.2pt),
  text(fill: scr-bg, s))                       // inverse video
#let ivs(s) = iv(text(s))                      // ...from a string, so
                                               // padding spaces survive
#let rv(s) = box(fill: scr-red, outset: (y: 0.6pt, x: 0.2pt),
  text(fill: scr-fg, s))                       // red bar
#let pv(s) = box(fill: ink, outset: (y: 0.6pt, x: 0.2pt),
  text(fill: cream, s))                        // inverse on paper
#let wide(s) = box(scale(x: 192%, reflow: true, s))  // 20-col double width
#let bars(n) = box(baseline: 0.4pt, {           // wifi signal strength
  let h = (2.0pt, 3.4pt, 4.8pt)
  stack(dir: ltr, spacing: 0.9pt,
    ..range(3).map(i =>
      move(dy: -h.at(i) + 4.8pt,
        rect(width: 1.7pt, height: h.at(i),
             fill: if i < n { scr-fg } else { scr-bg.lighten(18%) }))))
})
#let folder-ic = box(baseline: 0.5pt, {          // the folder glyph
  place(rect(width: 3.4pt, height: 1.4pt, fill: scr-fg))
  rect(width: 5.4pt, height: 3.8pt, fill: scr-fg,
       outset: (top: -1.2pt))
})
// true 40-column panel: 40 chars at 5.6pt = 224pt inner width
#let screen(body, w: 3.5in) = block(breakable: false,
  above: 1.0em, below: 1.0em,
  box(width: w, fill: scr-bg, radius: 9pt, inset: (x: 14pt, y: 12pt), {
    set text(font: f-scrn, size: 5.6pt, fill: scr-fg)
    set par(leading: 3.0pt, spacing: 3.0pt, first-line-indent: 0pt)
    body
  }))

// --- silver page pinstripes ---
#let silver-bg = {
  rect(width: 100%, height: 100%, fill: silver)
  for i in range(52) {
    place(top + left, dy: 0.16in + i * 0.21in,
      line(length: 100%, stroke: 0.5pt + silver-line))
  }
}

// --- folio, serif, bottom outer corner ---
#let folio = context {
  let p = counter(page).get().first()
  if p > 1 {
    let num = text(font: f-sans, size: 9.5pt, fill: ink, str(p))
    if calc.even(p) {
      place(bottom + left, dx: 10pt, dy: -14pt, num)
    } else {
      place(bottom + right, dx: -10pt, dy: -14pt, num)
    }
  }
}

// --- isometric data cubes, 1050-booklet style ---
#let cube(s, c, rot: 0deg) = rotate(rot, reflow: false, {
  let w = s; let h = s * 2.1; let dx = s * 0.62; let dy = s * 0.40
  let st = 0.85pt + black
  box(width: w + dx, height: h + dy, {
    // top face
    place(polygon(fill: c.lighten(34%), stroke: st,
      (0pt + dx, 0pt), (w + dx, 0pt), (w, dy), (0pt, dy)))
    // front face
    place(dy: dy, polygon(fill: c, stroke: st,
      (0pt, 0pt), (w, 0pt), (w, h), (0pt, h)))
    // side face
    place(dx: w, polygon(fill: c.darken(26%), stroke: st,
      (dx, 0pt), (dx, h), (0pt, h + dy), (0pt, dy)))
  })
})
// a loose arc of tumbling cubes; pts: (x, y, size, color-idx, rot)
#let cubestream(pts, unit: 1pt) = {
  let w = calc.max(..pts.map(p => p.at(0) + p.at(2) * 2.2)) * unit
  let h = calc.max(..pts.map(p => p.at(1) + p.at(2) * 2.7)) * unit
  box(width: w, height: h, {
    for p in pts {
      place(dx: p.at(0) * unit, dy: p.at(1) * unit,
        cube(p.at(2) * unit, cubes-c.at(calc.rem(p.at(3), cubes-c.len())),
             rot: p.at(4) * 1deg))
    }
  })
}

// --- callout label for hardware diagrams ---
#let callout(label-text, w: 1.1in) = box(width: w,
  par(leading: 0.32em, first-line-indent: 0pt,
    text(font: f-sans, weight: 400, size: 7.6pt,
         tracking: 0.3pt, fill: ink, upper(label-text))))

// ============================================================
// DOCUMENT SETUP
// ============================================================
#set text(font: f-body, weight: 300, size: 9pt, fill: ink)
#set par(leading: 0.5em, spacing: 0.62em, justify: false,
         first-line-indent: 0pt)
// no italic Rockwell cut is vendored; emphasize with the Regular weight
#show emph: set text(weight: 400, style: "normal")
#set page(width: 8.5in, height: 11in,
  margin: (x: 0.6in, top: 0.55in, bottom: 0.7in),
  fill: cream, background: folio)

// ============================================================
// FRONT COVER  (after the 800 Owner's Guide, CO60057)
// ============================================================
#page(margin: 0pt, fill: cover-gray, background: none)[
  // vertical rainbow wordmark down the right side, like the giant
  // ATARI — Harry Fatt, one hue per letter, purple fading to green
  #place(top + left, dx: 8.4in, dy: 0.3in,
    rotate(90deg, origin: top + left, reflow: false,
      text(font: f-mark, weight: 900, size: 116pt, tracking: 14pt, {
        let cols = (rgb("#7b3fa0"), rgb("#5b49ae"), rgb("#3b55b5"),
                    rgb("#2e6fbb"), rgb("#2e8eb0"), rgb("#36a37e"),
                    rgb("#58b758"))
        for (i, ch) in "FUJINET".clusters().enumerate() {
          text(fill: cols.at(i), ch)
        }
      })))

  // masthead
  #place(top + left, dx: 0.55in, dy: 0.5in, {
    set par(leading: 0.14em, spacing: 0.14em, first-line-indent: 0pt)
    set text(font: f-head, weight: 700, size: 34pt, fill: black,
             tracking: 0.3pt)
    par[THE FUJINET#tm]
    par[WIFI NETWORK]
    par[PERIPHERAL]
  })

  // hero illustration, rendered from the fujinet-hardware 3D model
  #place(top + left, dx: 0.85in, dy: 2.65in,
    image("images/fujinet-hero.png", width: 3.7in))

  // the thin "OWNER'S GUIDE" line
  #place(top + left, dx: 0.55in, dy: 8.6in,
    text(font: f-sans, weight: 400, size: 40pt,
         tracking: 1.2pt, fill: ink)[OWNER'S GUIDE])

  // mark at the foot, like the Fuji + Warner line
  #place(bottom + left, dx: 0.55in, dy: -0.42in,
    stack(dir: ltr, spacing: 10pt,
      image("images/fujinet-logo.png", width: 1.5in),
      align(horizon, text(font: f-sans, size: 8pt,
        fill: ink)[A Worldwide Community Project])))
]

// inside front cover: solid navy, like the 1050 booklet
#page(margin: 0pt, fill: navy, background: none)[
  #counter(page).update(0)
]

// ============================================================
// CONTENTS  (1050-booklet style: blue condensed entries, rules)
// ============================================================
#{
  set par(first-line-indent: 0pt)
  block(above: 0pt, {
    set text(font: f-head, weight: 700, size: 26pt, fill: ink)
    [CONTENTS]
    v(8pt)
    move(dx: -0.6in, rect(width: 8.5in, height: 11pt, fill: black))
  })
  v(0.45in)
  align(center, box(width: 5.2in, {
    set align(left)
    context {
      let entries = query(metadata).filter(m =>
        type(m.value) == dictionary and "title" in m.value)
      for e in entries {
        let pg = counter(page).at(e.location()).first()
        block(above: 0pt, below: 7.5pt, {
          line(length: 100%, stroke: 0.9pt + ink)
          v(3.5pt)
          text(font: f-head, weight: 700, size: 12.5pt, fill: toc-blue,
               tracking: 0.3pt, upper(e.value.title))
          h(8pt)
          text(font: f-sans, size: 11pt, fill: ink, str(pg))
        })
      }
    }
  }))

  place(bottom + left, dy: -0.1in, box(width: 5.9in, {
    set text(size: 7.4pt)
    set par(leading: 0.46em)
    [FujiNet#tm is free, open-source hardware and software, built by
     enthusiasts for enthusiasts. This guide covers the CONFIG program
     supplied in FujiNet firmware for the Atari 8-bit computers. Its
     design pays tribute to the Atari home computer manuals of
     1980--1982. ATARI#rg and the names of ATARI peripherals are
     trademarks of their respective owners, used here in loving tribute.
     FujiNet is not affiliated with Atari.]
  }))
  pagebreak()
}

// ============================================================
// INTRODUCING FUJINET  (silver page, like "INTRODUCING DOS")
// ============================================================
#page(fill: none, background: { silver-bg; folio })[
  #secmark("Introducing FujiNet")
  #headband("Introducing", "FujiNet")

  #grid(columns: (1fr, 1fr, 1fr), column-gutter: 14pt, [
    #lsub[Why You Need FujiNet]

    The FujiNet#tm is a WiFi network peripheral for your ATARI home
    computer --- the 400, 800, 1200XL, 600XL, 800XL, 65XE, 130XE, and
    XEGS. It plugs into the serial port like a disk drive, and connects
    your computer to your home wireless network, and through it, the
    world.

    Inside this one little box are eight disk drives, a place to keep
    your own software library, a clock, a printer, a modem, and a
    network connection for programs that know how to use one.

    Most important of all: a FujiNet full of software from across the
    Internet is #emph[exactly as easy to use] as a disk drive full of
    diskettes. If you have ever booted a diskette, you already know
    nearly everything this booklet has to teach.
  ], [
    #lsub[What You'll Learn From This Booklet]

    The program that runs the show is called #strong[CONFIG]. It lives
    inside the FujiNet itself, and your computer loads it automatically
    at power-on --- no cartridge, no diskette, no program recorder
    required. CONFIG is what this booklet teaches: every screen, every
    key, every function.

    You don't need any computer or networking experience. After you
    read this booklet and follow the examples, you'll connect FujiNet
    to your wireless network, browse libraries of thousands of
    programs, mount disk images, boot them, copy them, and even
    manufacture blank diskettes out of thin air.
  ], [
    #lsub[Got Everything?]

    Before you begin, check that you have everything you need:

    #bstep(1)[An ATARI home computer, set up and working with your TV
      set or monitor.]
    #bstep(2)[A FujiNet for the Atari 8-bit computers.]
    #bstep(3)[An SIO peripheral cable, if your FujiNet did not come
      with its own plug molded on.]
    #bstep(4)[The name of your 2.4 GHz wireless network and its
      password, written down #emph[exactly] --- capitalization
      counts.]
    #bstep(5)[#emph[(Optional)] A microSD card formatted FAT32, for a
      library of your own.]

    FujiNet speaks 802.11 b/g/n on the 2.4 GHz band only. If your
    network is 5 GHz-only, ask your router for a 2.4 GHz network ---
    nearly all routers provide both.
  ])

  // FujiNet leaning out of the corner, like the 1050's drive
  #place(bottom + right, dx: 0.5in, dy: 0.55in,
    rotate(-18deg, image("images/fujinet-rear34.png", width: 2.2in)))
]

// ============================================================
// MEET YOUR FUJINET (labeled diagrams from the 3D models)
// ============================================================
#secmark("Meet Your FujiNet")
#headband("Meet Your", "FujiNet")

#grid(columns: (2.45in, 1fr), column-gutter: 0.3in, [
  Take a moment to get acquainted with your FujiNet before you hook it
  up. The pieces shown here appear on every Atari FujiNet, though their
  exact positions vary a little from one case style to another.

  #lsub[SIO Plug]
  Plugs into the peripheral (serial) jack on your computer, or into the
  pass-through jack of any ATARI peripheral, just like a disk drive's
  cable. Data #emph[and power] arrive through it --- FujiNet has no
  power cord and no batteries. When your computer is on, your FujiNet
  is on.

  #lsub[SIO Jack]
  A pass-through. Any peripheral that used to occupy your computer's
  serial jack --- an 810 or 1050 disk drive, a printer, an 850
  interface --- can plug in behind the FujiNet and keep working.

  #lsub[microSD Card Slot]
  On the side of the case: holds an optional memory card with your own
  software library. Push the card in until it clicks; push again to
  release it. Insert or remove it only with the power off.

  #lsub[USB Port]
  Next to the power switch: loads new FujiNet firmware from a PC, and
  serves as an alternate source of power. Current FujiNets wear a USB-C
  connector; earlier ones, micro-USB.

  #lsub[Power Switch]
  Slide it OFF and the FujiNet goes quiet without unplugging anything
  --- handy when you want to boot a real diskette instead.
], [
  #let pointer = box(baseline: -2.5pt, line(length: 0.28in,
    stroke: 0.7pt + ink))
  #let co(label-text) = block(below: 0.85em,
    par(leading: 0.35em, hanging-indent: 0.36in, first-line-indent: 0pt,
      pointer + h(4pt) +
      text(font: f-sans, weight: 400, size: 7.8pt,
           tracking: 0.3pt, fill: ink, upper(label-text))))

  // the front of the case, labels at right
  #grid(columns: (2.1in, 1fr), column-gutter: 0.2in,
    align: (center + horizon, left + horizon),
    image("images/fujinet-front-flat.png", height: 2.35in),
    {
      co[Buttons A, B and C — pressed from the top, among the ridges]
      co[Indicator lights — near the top]
      co[Power switch and USB port — on this edge]
      co[SIO plug — to the computer (or to another peripheral's
         pass-through jack)]
    })

  #v(0.6em)
  // the back of the case, labels at left
  #grid(columns: (1fr, 2.1in), column-gutter: 0.2in,
    align: (left + horizon, center + horizon),
    {
      co[Vents — the lights glow through them at power-on]
      co[microSD card slot — on this edge]
      co[SIO jack — your old drive or printer plugs in here and keeps
         working]
    },
    image("images/fujinet-rear34.png", height: 2.35in))

  #v(0.5em)
  Your FujiNet's case is 3-D printed by whoever built it, and comes in
  styles to match every ATARI --- the warm tan of a 400 or 800,
  the cream of an XL, the gray of an XE. Same FujiNet inside.

  #v(0.4em)
  #align(center, grid(columns: 3, column-gutter: 0.5in, align: bottom,
    stack(spacing: 5pt,
      image("images/fujinet-hero.png", height: 1.35in),
      text(font: f-sans, size: 7.5pt)[400/800 STYLE]),
    stack(spacing: 5pt,
      image("images/fujinet-xl.png", height: 1.35in),
      text(font: f-sans, size: 7.5pt)[XL STYLE]),
    stack(spacing: 5pt,
      image("images/fujinet-xe.png", height: 1.35in),
      text(font: f-sans, size: 7.5pt)[XE STYLE])))
])
#pagebreak()

// ============================================================
// LIGHTS AND BUTTONS
// ============================================================
#secmark("Lights and Buttons")
#headband("Lights and", "Buttons")

#grid(columns: (1fr, 1fr, 1fr), column-gutter: 14pt, [
  #lsub[The Indicator Lights]

  Small lights report what your FujiNet is up to:

  #item[WIFI (white) glows steadily when FujiNet is connected to your
    wireless network]
  #item[SIO (orange) flickers in time with data moving between FujiNet
    and your computer --- the electronic equivalent of the whirring of
    a disk drive --- and blinks twice to confirm a button press]
], [
  #lsub[Button A — Disk Swap]

  A short press rotates the disk images in your drive slots: the image
  in slot 2 slides into slot 1, slot 3 into slot 2, and so on, around
  the horn. When a program says "insert disk 2 and press RETURN,"
  press Button A instead of getting up. The orange light blinks twice
  to confirm.

  #lsub[Button B — Restart]

  Hold Button B for a few seconds to restart the FujiNet itself.
], [
  #lsub[Button C — Safe Reset]

  A short press restarts the FujiNet safely. You'll use it whenever you
  want to come back to CONFIG after booting a program. On some FujiNet
  models this button is small and recessed; on others it is labeled
  RESET.

  #lsub[About the microSD Card]

  The card must be formatted FAT32. Insert or remove it only while the
  computer --- and so the FujiNet --- is switched off. Unlike
  diskettes, a memory card is perfectly happy near your TV set. But it
  is small, so mind the carpet.
])

#v(0.35in)
#align(center, grid(columns: 2, column-gutter: 0.85in, align: bottom,
  stack(spacing: 7pt,
    image("images/fujinet-front-flat.png", height: 2.3in),
    text(font: f-sans, size: 7.5pt, tracking: 0.3pt)[THE LIGHTS SHINE
      THROUGH THE FRONT OF THE CASE]),
  stack(spacing: 7pt,
    // top view with the three buttons marked among the ridges
    box({
      let mark(x, label) = {
        place(top + left, dx: x, dy: -0.17in,
          text(font: f-head, weight: 700, size: 9pt, label))
        place(top + left, dx: x + 0.025in, dy: -0.045in,
          line(angle: 90deg, length: 0.2in, stroke: 0.8pt + ink))
      }
      mark(0.30in, "A")
      mark(0.61in, "B")
      mark(1.64in, "C")
      pad(top: 0.18in, image("images/fujinet-top.png", height: 2.3in))
    }),
    text(font: f-sans, size: 7.5pt, tracking: 0.3pt)[THE BUTTONS, IN
      THE TOP: A CLOSEST TO THE EDGE, \ B RIGHT NEXT TO IT, C ON ITS
      OWN])))
#v(1fr)
#align(center, cubestream((
  (0, 26, 7, 0, -14), (26, 12, 8, 4, 8), (54, 22, 7, 7, -30),
  (84, 6, 9, 1, 14), (114, 18, 7, 5, -8), (140, 4, 8, 3, 24),
  (170, 16, 7, 8, -18), (196, 2, 8, 2, 6), (224, 14, 7, 6, -24),
  (252, 4, 9, 9, 16), (282, 16, 7, 0, -6), (310, 2, 8, 4, 20),
  (338, 14, 7, 1, -16), (366, 6, 8, 7, 10),
), unit: 1pt))
#v(0.35in)
#pagebreak()

// ============================================================
// HOOKING IT UP  (800-guide big-numeral steps)
// ============================================================
#secmark("Hooking It Up")
#headband("Hooking", "It Up")

#grid(columns: (2.9in, 1fr), column-gutter: 0.35in, [
  All you need to set up your FujiNet is your ATARI computer and a
  free serial jack. Set-up takes only a few minutes.

  #bstep(1)[Turn your computer #strong[OFF]. As a rule, never plug or
    unplug peripherals while the power is on.]

  #bstep(2)[If you have a microSD card, insert it into FujiNet's card
    slot until it clicks.]

  #bstep(3)[Plug the FujiNet's #strong[SIO plug] into the jack marked
    #strong[PERIPHERAL] (or #strong[SERIAL I/O]) on your computer.]

  #bstep(4)[If another peripheral was using that jack, plug its cable
    into the FujiNet's #strong[SIO jack]. Devices behind FujiNet keep
    working normally.]

  #bstep(5)[Slide the FujiNet's power switch #strong[ON].]

  That's the whole job. FujiNet draws its power from the computer, so
  there is no power supply to find an outlet for. If you own real
  ATARI disk drives, they can stay in the chain --- see "Working With
  Drive Slots" for the one switch you may need to flip.

  #lsub[Important]

  #strong[Remove all cartridges, diskettes and cassettes] before the
  first power-up, so the computer's attention belongs to the FujiNet.
  (On the XL and XE computers, ATARI BASIC is built in --- CONFIG gets
  along fine with it.)
], [
  #align(center, image("images/sio-plug.png", width: 2.1in))
  #align(center, text(font: f-sans, size: 7.5pt)[THE
    SIO PLUG — IT ONLY FITS THE RIGHT WAY UP])
  #v(0.3in)
  #align(center, image("images/fujinet-rear34.png", width: 2.0in))
  #align(center, text(font: f-sans, size: 7.5pt)[YOUR
    OLD DRIVE PLUGS INTO THE SIO JACK ON THE BACK])
])
#pagebreak()

// ============================================================
// CHECKING IT OUT — first power-on, network scan
// ============================================================
#secmark("Checking It Out")
#headband("Checking", "It Out")

#grid(columns: (1fr, 1fr), column-gutter: 0.3in, [
  When you turn on your computer with a FujiNet attached, the FujiNet
  introduces itself by lending the computer its own boot program ---
  CONFIG.

  #bstep(1)[Turn on your TV set and select the proper channel.]
  #bstep(2)[Turn the computer #strong[ON].]
  #bstep(3)[Watch the screen. In a moment you'll see #strong[WELCOME
    TO FUJINET!] at the top of your screen.]

  The very first time, CONFIG goes straight into network setup: it
  announces #strong[SCANNING NETWORKS...] and lists the wireless
  networks it finds in the air around your house --- up to 16 of them,
  each with a one-, two- or three-bar signal-strength meter. More
  bars, better signal.

  Your FujiNet's #strong[MAC address] --- its hardware serial number
  --- is printed at the top of the screen. You'll only ever need it if
  your router restricts which devices may join.

  #lsub[Keys On This Screen]

  Press #key[ctrl] #key[−] and #key[ctrl] #key[=] to move the
  highlight bar up and down the list. (The arrow keys work with or
  without #key[ctrl] everywhere in CONFIG.) Press #key[return] to
  choose the highlighted network, #key[S] to skip network setup, or
  #key[esc] to scan the air again.

  If your network hides its name, move the highlight to the last entry
  on the list --- #strong[\<Enter a specific SSID\>] --- press
  #key[return], and type the name yourself, up to 32 characters.
], [
  #screen([
    #wide[WELCOME TO FUJINET!]

    MAC Address: A0:B7:65:29:33:F0

    #h(5.6pt)#ivs(" HomeNet                         ")#h(5.6pt)#bars(3) \
    #h(11.2pt)Wireless-2.4#h(117.6pt)#bars(2) \
    #h(11.2pt)Maple-Street-WiFi#h(89.6pt)#bars(2) \
    #h(11.2pt)CoffeeHouse Guest#h(89.6pt)#bars(1) \
    #h(11.2pt)\<Enter a specific SSID\>

    #v(40pt)
    #h(4pt)SELECT NET, S SKIP#h(12pt)ESC TO RE-SCAN
  ])
  #align(center, text(font: f-sans, size: 7.5pt)[THE
    NETWORK SCAN — YOUR NEIGHBORHOOD WILL VARY])

  #v(0.5em)
  #lsub[Entering Your Password]

  Highlight your network, press #key[return], and CONFIG asks for the
  password. Type it --- up to 64 characters, capitals and all. Each
  character appears as a #strong[\*] so onlookers can't read it.
  #key[delete] fixes mistakes; #key[return] finishes the job.

  #dialogue(
    ("Computer", [#pv(text(" ENTER PASSWORD "))]),
    ("You type", [\*\*\*\*\*\*\*\*\*\*\*\* #key[return]]),
    ("Computer", [CONNECTING TO NET]),
    ("Computer", [CONNECTION SUCCESS!]),
  )

  FujiNet remembers this network inside itself and will rejoin it
  automatically every time it powers up, skipping ahead to the main
  screen.

  If you see #strong[CONNECT FAILED] or #strong[UNABLE TO CONNECT],
  the connection didn't take, and CONFIG returns to the network list.
  Nine times out of ten the password was mistyped --- choose your
  network and try again carefully. While CONFIG shows #strong[PLEASE
  WAIT...(ESC TO ABORT)], pressing #key[esc] gives up and returns to
  the list.
])
#pagebreak()

// ============================================================
// THE MAIN SCREEN — hosts and drive slots
// ============================================================
#secmark("The Main Screen")
#headband("The Main Screen:", "Hosts and Drive Slots")

#grid(columns: (1fr, 1fr), column-gutter: 0.3in, [
  Everything in CONFIG begins at the main screen. The top half is the
  #strong[HOST LIST] --- eight remembered places that software comes
  from. The bottom half is your eight #strong[DRIVE SLOTS] --- the
  virtual disk drives your computer sees as D1: through D8:. Press
  #key[tab] to jump between the halves.

  A #strong[host] is most often a #strong[TNFS server] on the Internet
  --- a computer that shares a library of ATARI software, such as
  #text(font: f-scrn, size: 6.6pt)[fujinet.online] --- or the microSD
  card in your FujiNet, which goes by the special name
  #text(font: f-scrn, size: 6.6pt)[SD]. Empty slots read
  #strong[Empty].

  Each drive slot line shows, from left to right: which host its disk
  came from (1--8), the drive number, #strong[R] or #strong[W] ---
  whether programs may write on the disk --- and the name of the disk
  image mounted there.

  #lsub[Keys On the Host List]

  #grid(columns: (1.05in, 1fr), row-gutter: 5.5pt, column-gutter: 6pt,
    [#key[1]–#key[8]], [Jump straight to a numbered slot.],
    [#key[return]], [Open the highlighted host and browse its files.],
    [#key[E]], [Edit the host name in the highlighted slot.],
    [#key[C]], [Show the information screen.],
    [#key[L]], [Boot the multi-player Game Lobby (CONFIG asks
      #strong[Boot Lobby Y/N?]).],
    [#key[tab]], [Jump down to the drive slots.],
    [#key[option]], [Mount everything and boot.],
  )
], [
  #screen([
    #wide[#h(28pt)HOST LIST]

    #h(11.2pt)1 #ivs(" fujinet.online              ") \
    #h(11.2pt)2 SD \
    #h(11.2pt)3 Empty \
    #h(11.2pt)4 Empty \
    #h(11.2pt)5 Empty \
    #h(11.2pt)6 Empty \
    #h(11.2pt)7 Empty \
    #h(11.2pt)8 Empty

    #wide[#h(22pt)DRIVE SLOTS]

    1 1R Jumpman.atr \
    #h(11.2pt)2#h(11.2pt)Empty \
    #h(11.2pt)3#h(11.2pt)Empty \
    #h(11.2pt)4#h(11.2pt)Empty \
    #h(11.2pt)5#h(11.2pt)Empty \
    #h(11.2pt)6#h(11.2pt)Empty \
    #h(11.2pt)7#h(11.2pt)Empty \
    #h(11.2pt)8#h(11.2pt)Empty

    #iv[1-8]Slot#iv[E]dit#iv[RETURN]Browse#iv[L]obby \
    #h(11.2pt)#iv[C]onfig#iv[TAB]Drive Slots#iv[OPTION]Boot
  ])
  #align(center, text(font: f-sans, size: 7.5pt)[THE
    MAIN SCREEN — HOSTS ABOVE, DRIVE SLOTS BELOW])

  #v(0.4em)
  The bottom two lines of every CONFIG screen list the keys that are
  active right there, so you never have to memorize a thing.

  #lsub[Your Joystick Works Too]

  Plug a joystick into #strong[controller jack 1] and you can run
  CONFIG from the comfort of your couch. Stick up and down move the
  highlight bar; the #strong[fire button] is RETURN; stick right turns
  to the next page of a long file list; stick left goes back ---
  previous page, then up one folder, then back to the main screen.
  Hold the stick left and press fire to boot, same as #key[option].
  CONFIG also understands the cursor keys of a TransKey-II keyboard
  adapter, if your computer wears one.
])
#pagebreak()

// ============================================================
// TELLING FUJINET WHERE SOFTWARE LIVES — host slots
// ============================================================
#secmark("Setting Up Host Slots")
#headband("Telling FujiNet Where", "Software Lives")

#grid(columns: (1fr, 1fr, 1fr), column-gutter: 14pt, [
  To put a name in a host slot:

  #bstep(1)[Highlight a host slot --- press its number, 1 through 8,
    or use the arrows.]
  #bstep(2)[Press #key[E]. The slot opens for typing.]
  #bstep(3)[Type the host's name --- up to 32 characters --- and
    press #key[return].]

  #dialogue(
    ("You press", [#pv[E]]),
    ("You type", [fujinet.online #key[return]]),
  )

  #key[delete] erases; #key[esc] cancels and keeps the old name. To
  clear a slot, edit it and backspace the name away, then press
  #key[return] --- the slot reads #strong[Empty] again.

  #strong[IMPORTANT:] Changing or clearing a host slot automatically
  ejects any disk images that were mounted from it, since they can no
  longer be reached.
], [
  #lsub[Hosts Speak Several Languages]

  What you type tells FujiNet what kind of server to reach:

  #set text(size: 8.2pt)
  #table(
    columns: (0.95in, 1fr),
    stroke: 0.5pt + ink,
    inset: 3.6pt,
    table.header(
      text(font: f-head, weight: 700, size: 7.5pt)[YOU TYPE],
      text(font: f-head, weight: 700, size: 7.5pt)[FUJINET REACHES]),
    sf("SD", size: 6.2pt),
      [The microSD card in your FujiNet],
    sf("...", size: 6.2pt),
      [A #strong[TNFS] software server --- what FujiNet assumes when a
       plain name is given],
    sf("http://...", size: 6.2pt),
      [A web server; its index page becomes a browsable folder
       (#sf("https://", size: 6.2pt) works too)],
    sf("smb://...", size: 6.2pt),
      [A Windows file share; user:pass\@ may be included],
    sf("nfs://...", size: 6.2pt),
      [An NFS server],
    sf("ftp://...", size: 6.2pt),
      [An FTP server],
  )
], [
  #lsub[Names To Try First]

  #sf("fujinet.online") is the flagship public library, and comes
  already set in host slot 1 of a new FujiNet. Should you ever lose
  your host list, these names will restock it:

  #item[#sf("SD", size: 6.2pt) --- the card in your FujiNet]
  #item[#sf("FUJINET.ONLINE", size: 6.2pt)]
  #item[#sf("APPS.IRATA.ONLINE", size: 6.2pt)]
  #item[#sf("FUJINET.ABBUC.SOCIAL", size: 6.2pt)]
  #item[#sf("FUJINET.PL", size: 6.2pt)]

  A list of TNFS servers and their on-line status is kept at
  #sf("https://fujinet.online/tnfs-server-status/", size: 6.2pt)

  #lsub[Doorways To Other Hosts]

  On some public servers you may see entries marked with a small
  #text(font: f-scrn, size: 6.6pt, baseline: -0.5pt)[♥] beside them.
  These are doorways to #emph[other] TNFS hosts: choose one, and
  CONFIG connects there and keeps browsing. The linked host's name
  lands in host slot 8, so it will be on your main screen afterward,
  too.
])
#v(1fr)
#align(center + bottom,
  cubestream((
    (0, 10, 8, 7, -10), (30, 22, 7, 1, 14), (58, 6, 9, 4, -22),
    (90, 18, 7, 0, 8), (118, 2, 8, 5, -14), (148, 16, 7, 8, 18),
    (176, 4, 8, 2, -6), (206, 14, 9, 6, 12), (238, 2, 7, 3, -18),
    (266, 12, 8, 9, 6),
  ), unit: 1pt))
#v(0.4in)
#pagebreak()

// ============================================================
// BROWSING FOR SOFTWARE
// ============================================================
#secmark("Browsing for Software")
#headband("Browsing for", "Software")

#grid(columns: (1fr, 1fr), column-gutter: 0.3in, [
  Highlight a host slot and press #key[return]. CONFIG opens the host
  and presents its files under the title #strong[DISK IMAGES] ---
  fifteen to a page, with the host's name, the current filter, and
  your current folder path across the top.

  A small icon marks each #strong[folder]. Everything else is a file:
  disk images (#text(font: f-scrn, size: 6.6pt)[.atr]), executable
  programs (#text(font: f-scrn, size: 6.6pt)[.xex]), cassettes
  (#text(font: f-scrn, size: 6.6pt)[.cas]). When the list is longer
  than one page, #strong[> Next Page] and #strong[< Previous Page]
  markers appear at the bottom and top.

  Rest the highlight on a long name for a moment, and the full name
  appears at the bottom of the screen.

  #lsub[Keys In the Browser]

  #grid(columns: (1.05in, 1fr), row-gutter: 5.5pt, column-gutter: 6pt,
    [#key[return]], [Open the highlighted folder, or choose the
      highlighted file.],
    [#key[>]], [Turn to the next page. The down-arrow rolls onto it
      too.],
    [#key[<]], [Go back: previous page; from the first page, up one
      folder; from the top of the host, back to the main screen.],
    [#key[delete]], [Jump straight up to the parent folder.],
    [#key[F]], [Filter or search --- see the next page.],
    [#key[N]], [Create a brand-new blank disk (see "Creating a New
      Disk").],
    [#key[C]], [Copy the highlighted file to another host (see
      "Copying Files").],
    [#key[option]], [Boot whatever is already mounted.],
    [#key[esc]], [Back to the main screen.],
  )
], [
  #screen([
    #wide[#h(22pt)DISK IMAGES]

    Host: fujinet.online \
    Fltr: \
    Path: /Games/

    #h(11.2pt)#folder-ic#h(5pt)Action! \
    #h(11.2pt)#folder-ic#h(5pt)Adventure \
    #h(16.8pt)#ivs(" Jumpman.atr                 ") \
    #h(16.8pt)Joust.atr \
    #h(16.8pt)MULE.atr \
    #h(16.8pt)Miner2049er.atr \
    #h(16.8pt)Pitfall.atr \
    #h(16.8pt)RiverRaid.atr \
    #h(16.8pt)StarRaiders.xex \
    #h(16.8pt)Zork1.atr

    #iv[>]Next Page

    #iv[←]#iv[DELETE]Up Dir#iv[N]ew#iv[F]ilter#iv[C]opy \
    #iv[→]#iv[RETURN]Choose#iv[OPTION]Boot#iv[ESC]Abort
  ])
  #align(center, text(font: f-sans, size: 7.5pt)[THE
    FILE BROWSER, FIFTEEN ENTRIES TO A PAGE])
])
#pagebreak()

// ============================================================
// WILD CARDS — filter and search (black art panel)
// ============================================================
#secmark("Wild Cards")
#headband("Wild Cards:", "Finding the Needle")

#grid(columns: (1fr, 1fr, 1fr), column-gutter: 14pt, [
  When a host holds hundreds of files, let CONFIG do the digging.
  Press #key[F] in the browser and type into the #strong[Fltr:] line.

  A pattern with #strong[\*] wild cards --- like
  #text(font: f-scrn, size: 6.6pt)[\*Star\*] or
  #text(font: f-scrn, size: 6.6pt)[Donkey\*] --- narrows the current
  folder to names that match. The asterisk stands for any run of
  letters and numbers, just as it did in ATARI DOS.

  A pattern starting with #strong[!] --- like
  #text(font: f-scrn, size: 6.6pt)[!zork] --- #strong[searches the
  entire host], top to bottom, and lists every file containing that
  term, wherever it hides.
], [
  A blank filter brings everything back.

  #dialogue(
    ("You press", [#pv[F]]),
    ("You type", [!donkey #key[return]]),
    ("Computer", [Fltr: !donkey \
      #h(16.5pt)DonkeyKong.atr \
      #h(16.5pt)DonkeyKongJr.atr]),
  )

  The active filter stays posted on the #strong[Fltr:] line, so you'll
  always know why a folder looks short.
], [
  #lsub[A Hint]

  Searching the whole of a big public host takes a few moments ---
  CONFIG is reading every folder for you, which beats doing it
  yourself. Searches reach at most two folders deep, which covers the
  way every public library is organized.
])

#v(0.35in)
// black wildcard art panel, after the 1050's full-page divider
#align(center, box(width: 7.3in, height: 3.5in, fill: black, clip: true, {
  place(dx: 0.3in, dy: 0.1in,
    text(font: f-mark, weight: 900, size: 175pt, fill: rgb("#3f9e58"), "*"))
  place(top + right, dx: -0.4in, dy: 0.02in,
    text(font: f-mark, weight: 900, size: 92pt, fill: rgb("#d23b2e"), "?"))
  place(dx: 0.2in, dy: 0.2in, cubestream((
    (60, 130, 9, 0, -18), (110, 95, 8, 4, 12), (160, 140, 9, 7, -8),
    (215, 80, 10, 1, 20), (270, 125, 8, 5, -26), (330, 70, 9, 3, 10),
    (385, 115, 8, 8, -14), (300, 170, 9, 2, 18), (130, 185, 8, 6, -10),
    (440, 90, 10, 9, 8), (480, 150, 8, 0, -20), (220, 190, 8, 4, 26),
    (370, 185, 9, 1, -6), (35, 185, 8, 8, 16),
  ), unit: 1pt))
}))
#pagebreak()

// ============================================================
// MOUNTING AND BOOTING
// ============================================================
#secmark("Mounting and Booting")
#headband("Mounting", "and Booting")

#grid(columns: (1fr, 1fr), column-gutter: 0.3in, [
  Mounting an image is just like putting a diskette in a drive ---
  without getting up. Highlight a disk image in the browser and press
  #key[return]. CONFIG shows #strong[MOUNT TO DRIVE SLOT]: your eight
  drive slots, with the file's name, date and size below.

  #bstep(1)[Choose a drive slot --- press its number, 1 through 8, or
    move the highlight --- and press #key[return].]

  #bstep(2)[CONFIG asks how to mount it. Press #key[return] (or
    #key[R]) for #strong[Read Only] --- the safe choice --- or
    #key[W] for #strong[Read/Write], so programs can save onto it.]

  #bstep(3)[You return to the browser in the same folder, so you can
    mount more disks into other slots. Press #key[E] on the mount
    screen first if a slot needs emptying.]

  #strong[HINT:] Mount read-only unless you know the program saves
  onto its own disk. A read-only image can be shared by everyone on a
  server at once, and no stray write can ever damage it.

  #lsub[Booting]

  Press and hold #key[option] from the main screen, the browser, or
  the mount screen. CONFIG mounts everything in your drive slots,
  steps out of the way, and restarts the computer --- which boots from
  drive slot 1 exactly as if a real diskette were spinning in a real
  drive.

  #strong[Keep holding] #key[option] #strong[until the program begins
  to load.] On XL and XE computers the OPTION key, held during a
  restart, also switches off built-in BASIC --- which most games
  require. One key, two jobs.
], [
  #screen([
    #wide[MOUNT TO DRIVE SLOT]

    #h(11.2pt)1 #ivs(" Empty                       ") \
    #h(11.2pt)2 Empty \
    #h(11.2pt)3 Empty \
    #h(11.2pt)4 Empty \
    #h(11.2pt)5 Empty \
    #h(11.2pt)6 Empty \
    #h(11.2pt)7 Empty \
    #h(11.2pt)8 Empty

    #h(16.8pt)FILE: Jumpman.atr \
    #h(5.6pt)MTIME: 2024-03-11 09:14:22 \
    #h(11.2pt)SIZE: 90 K

    #v(14pt)
    #iv[1-8]Slot#iv[RETURN]Select#iv[E]ject#iv[ESC]Abort
  ])

  #dialogue(
    ("Computer", [#pv[RETURN]Read Only#pv[W]Read/Write#pv[ESC]Abort]),
    ("You press", [#pv[RETURN]]),
  )

  #lsub[Getting Back To CONFIG]

  Your drive slots are remembered inside the FujiNet, so the same
  software boots again on every restart --- CONFIG politely stays out
  of the way. To return to CONFIG: press FujiNet's #strong[Button C]
  (safe reset), wait a few seconds, then turn the computer off and on.
  Your hosts and mounted images will be just as you left them.

  #lsub[Owners of Real Drives]

  Your computer can't have two drive number 1's. If a real ATARI drive
  answers at the same number as a FujiNet drive slot, set the real
  drive to a different number --- or simply leave that FujiNet slot
  empty. Slots holding no image stay politely silent.
])
#pagebreak()

// ============================================================
// WORKING WITH DRIVE SLOTS
// ============================================================
#secmark("Working With Drive Slots")
#headband("Working With", "Drive Slots")

#grid(columns: (1fr, 1fr), column-gutter: 0.3in, [
  Press #key[tab] on the main screen to move the highlight into the
  DRIVE SLOTS half. Here you manage the diskettes your computer
  believes it owns.

  #lsub[Keys On the Drive Slots]

  #grid(columns: (1.15in, 1fr), row-gutter: 5.5pt, column-gutter: 6pt,
    [#key[1]–#key[8]], [Jump straight to a numbered slot.],
    [#key[E]], [Eject the image in the highlighted slot. The file
      itself is never harmed --- you are only taking the diskette out
      of the drive.],
    [#key[shift] #key[<]], [Eject #strong[ALL] drive slots at once.
      CONFIG announces #strong[EJECTING ALL.. WAIT].],
    [#key[R]], [Remount the highlighted disk #strong[read-only] ---
      programs may look but not touch.],
    [#key[W]], [Remount the highlighted disk #strong[read/write] ---
      programs may save onto it.],
    [#key[L]], [Boot the Game Lobby.],
    [#key[C]], [Show the information screen.],
    [#key[tab]], [Jump back up to the host list.],
    [#key[option]], [Boot whatever is mounted.],
  )
], [
  #lsub[If W Won't Stick]

  Public servers are usually read-only. If CONFIG reports
  #strong[ERROR SETTING DISK MODE], the host refused write permission,
  and the slot quietly returns to #strong[R]. To save into a disk
  image, copy it to your SD card first (see "Copying Files").

  #lsub[The One-Button Disk Swap]

  Mount all of a program's disks into slots 1 through 4 before
  booting, and multi-disk software becomes a one-button affair: when
  the program asks for the next disk, press FujiNet's #strong[Button
  A]. Every mounted image rotates one slot forward --- 2 into 1, 3
  into 2, around the horn --- and the orange light blinks twice to
  confirm.

  #lsub[The Cassette That Isn't]

  Mount a #text(font: f-scrn, size: 6.6pt)[.cas] cassette image into
  #strong[drive slot 8] and the slot's number changes to #strong[C]:
  FujiNet now stands in for an ATARI 410 Program Recorder. Boot the
  computer while holding #key[start] (on a 400 or 800, with no
  cartridge; on an XL or XE, hold #key[option] at the same time),
  press a key when the buzzer sounds, and enjoy the one part of 1982
  nobody was nostalgic for --- now considerably faster.
])
#pagebreak()

// ============================================================
// CREATING A NEW DISK
// ============================================================
#secmark("Creating a New Disk")
#headband("Creating a", "New Disk")

#grid(columns: (1fr, 1fr), column-gutter: 0.3in, [
  CONFIG can manufacture blank diskettes out of thin air --- on your
  SD card, or on any server that allows writing. Browse to the folder
  where the new disk should live, then:

  #bstep(1)[Press #key[N]. CONFIG asks: #strong[Size?]]

  #bstep(2)[Pick a capacity by pressing its number:]

  #set text(size: 8.2pt)
  #table(
    columns: (0.35in, 0.55in, 1fr),
    stroke: 0.5pt + ink,
    inset: 3.6pt,
    align: (center, center, left),
    table.header(
      text(font: f-head, weight: 700, size: 7.5pt)[KEY],
      text(font: f-head, weight: 700, size: 7.5pt)[SIZE],
      text(font: f-head, weight: 700, size: 7.5pt)[JUST LIKE...]),
    [1], [90K], [a single-density diskette (810 drive)],
    [2], [130K], [an enhanced-density diskette (1050 drive)],
    [3], [180K], [a double-density diskette],
    [4], [360K], [a double-sided, double-density diskette],
    [5], [720K], [a hard-disk image for DOS programs],
    [6], [1440K], [a bigger one],
    [7], [Custom], [you pick the number of sectors, and 128, 256 or
      512 bytes each],
  )
  #set text(size: 9pt)

  #bstep(3)[#strong[Enter name of new disk image file] --- type a
    name, give it an #text(font: f-scrn, size: 6.6pt)[.atr] ending,
    and press #key[return]. A blank name cancels.]

  #bstep(4)[Choose a drive slot for the newborn disk, and answer the
    Read Only / Read-Write question with #key[W] --- you'll want to
    write on it, after all.]
], [
  #dialogue(
    ("You press", [#pv[N]]),
    ("Computer", [Size?#pv[1]90K #pv[2]130K #pv[3]180K #pv[4]360K \
      #h(22pt)#pv[5]720K #pv[6]1440K #pv[7]Custom ?]),
    ("You press", [#pv[1]]),
    ("Computer", [Enter name of new disk image file]),
    ("You type", [mydisk.atr #key[return]]),
    ("Computer", [Creating File]),
  )

  CONFIG returns you to the browser with a fresh, blank, writable disk
  in its slot.

  #strong[NOTE:] The new disk is unformatted, like a fresh box of
  diskettes in 1982. Boot your favorite DOS and format it from there,
  then SAVE away.

  #v(0.3in)
  #align(center, cubestream((
    (0, 40, 8, 4, -12), (34, 18, 9, 0, 10), (70, 44, 8, 7, -24),
    (104, 14, 9, 5, 16), (140, 38, 8, 1, -8), (174, 10, 9, 8, 22),
    (208, 36, 8, 3, -16), (240, 12, 8, 6, 6),
  ), unit: 1pt))
])
#pagebreak()

// ============================================================
// COPYING FILES
// ============================================================
#secmark("Copying Files")
#headband("Copying", "Files")

#grid(columns: (1fr, 1fr), column-gutter: 0.3in, [
  Grab a game from a server across the ocean and keep it on the card
  in your FujiNet --- CONFIG copies files from any host to any
  writable host. Server to SD, SD to server, even server to server.

  #bstep(1)[Browse to the file you want, and highlight it.]

  #bstep(2)[Press #key[C]. CONFIG shows #strong[COPY TO HOST SLOT]
    and lists your eight hosts. The original file is never altered.]

  #bstep(3)[Choose the destination host --- #key[1] through #key[8]
    or the arrows --- and press #key[return]. (#key[esc] aborts.)]

  #bstep(4)[The destination host opens in the browser. Walk to the
    folder where the copy should go; the #key[F] filter works here
    too.]

  #bstep(5)[Press #key[C] again --- the key label now reads
    #strong[Do It!] --- and CONFIG announces #strong[COPYING, PLEASE
    WAIT].]

  When the copy finishes, you are returned to the folder you copied
  from --- handy for collecting several files in one sitting.

  #strong[NOTE:] The destination must allow writing. Public servers
  are usually read-only; your SD card is always willing.

  This is the easy way to build a personal library: find a favorite on
  #text(font: f-scrn, size: 6.6pt)[fujinet.online], copy it to
  #text(font: f-scrn, size: 6.6pt)[SD], and from then on it loads
  instantly --- Internet or no Internet.
], [
  #screen([
    #wide[COPY TO HOST SLOT]

    #h(11.2pt)1 #ivs(" fujinet.online              ") \
    #h(11.2pt)2 SD \
    #h(11.2pt)3 Empty \
    #h(11.2pt)4 Empty \
    #h(11.2pt)5 Empty \
    #h(11.2pt)6 Empty \
    #h(11.2pt)7 Empty \
    #h(11.2pt)8 Empty

    #v(22pt)
    fujinet.online \
    /Games/Jumpman.atr

    #v(8pt)
    #iv[1-8]Slot#iv[RETURN]Select#iv[ESC]Abort
  ])
  #align(center, text(font: f-sans, size: 7.5pt)[PICK
    A DESTINATION FOR THE COPY])

  #v(0.35in)
  #align(center, cubestream((
    (0, 30, 7, 8, -10), (26, 14, 8, 2, 14), (54, 34, 7, 5, -20),
    (82, 10, 8, 0, 8), (110, 30, 7, 9, -14), (138, 8, 8, 4, 18),
    (166, 28, 7, 1, -8), (194, 10, 8, 7, 12), (222, 28, 7, 3, -18),
    (250, 8, 8, 6, 6), (278, 26, 7, 0, -12),
  ), unit: 1pt))
])
#pagebreak()

// ============================================================
// THE INFORMATION SCREEN
// ============================================================
#secmark("The Information Screen")
#headband("The Information", "Screen")

#grid(columns: (1fr, 1fr), column-gutter: 0.3in, [
  From either half of the main screen, press #key[C] to see exactly
  how your FujiNet is faring on the network.

  #set text(size: 8.4pt)
  #table(
    columns: (0.85in, 1fr),
    stroke: 0.5pt + ink,
    inset: 3.6pt,
    [#strong[SSID]], [The wireless network FujiNet is connected to],
    [#strong[Hostname]], [FujiNet's name on your network],
    [#strong[IP Address]], [FujiNet's address on your network],
    [#strong[Gateway]], [Your router's address],
    [#strong[DNS]], [The name server FujiNet uses],
    [#strong[Netmask]], [Your network's subnet mask],
    [#strong[MAC]], [FujiNet's hardware address],
    [#strong[BSSID]], [Your WiFi access point's hardware address],
    [#strong[Version]], [FujiNet firmware version and build date],
  )
  #set text(size: 9pt)

  Press #key[C] here to drop the connection and re-join the same
  network; press #key[S] to forget this network and run network setup
  again; any other key returns to the main screen.
], [
  #screen([
    #v(10pt)
    #wide[#h(16pt)FUJINET CONFIG]

    // labels right-aligned in an 11-character field, values beside
    #let fld(l, v) = [#h(28pt)#box(width: 61.6pt,
      align(right, text(l)))#h(5.6pt)#text(v) \ ]
    #fld("SSID:", "HomeNet")
    #fld("Hostname:", "fujinet")
    #fld("IP Address:", "192.168.1.123")
    #fld("Gateway:", "192.168.1.1")
    #fld("DNS:", "192.168.1.1")
    #fld("Netmask:", "255.255.255.0")
    #fld("MAC:", "A0:B7:65:29:33:F0")
    #fld("BSSID:", "9C:05:D6:AA:01:10")
    #fld("Version:", "1.6.1")

    #v(8pt)
    #h(39.2pt)#iv[C]RECONNECT #iv[S]CHANGE SSID \
    #h(50.4pt)Any other key to return
  ])

  #lsub[The Deluxe Companion]

  Type the IP address shown on this screen into a web browser on any
  computer or phone in your house --- for example
  #sf("http://192.168.1.123/") --- and
  FujiNet's built-in web page appears. There you can manage hosts and
  slots from a big screen, configure the virtual #strong[printer]
  (FujiNet can pretend to be an ATARI 820, 822, 825, 1020, 1025, 1027
  or an Epson, and saves everything programs print for you to
  download), set the clock's time zone, adjust high-speed loading,
  enable or disable the wireless radio, and much more. It is the
  deluxe companion to the CONFIG program in this guide.
])
#pagebreak()

// ============================================================
// MORE INSIDE — black showcase page, like "PERIPHERAL EQUIPMENT"
// ============================================================
#page(fill: black, background: none)[
  #secmark("And There's More Inside")
  #headband("And There's", "More Inside", fg: white, band: white)

  #set text(fill: rgb("#f0ede4"))
  #grid(columns: (1fr, 1fr, 1fr), column-gutter: 14pt, [
    #text(font: f-sans, size: 10pt,
          tracking: 0.35pt)[THE GAME LOBBY]
    #v(0.4em)

    Press #key[L] on the main screen and answer #strong[Y] --- FujiNet
    boots the #strong[Game Lobby], an online meeting hall listing every
    FujiNet-aware multi-player game with servers waiting for players:
    5-Card Stud against Apple owners, checkers, and more. Pick a table;
    the right program loads itself. To come home, press Button C and
    restart, as usual.

    #v(0.7em)
    #text(font: f-sans, size: 10pt,
          tracking: 0.35pt)[A PRINTER WITHOUT A PRINTER]
    #v(0.4em)

    When a program prints to #strong[P:], FujiNet catches the output
    and keeps it for you. Open FujiNet's web page, look under
    #strong[Printer], and collect your listing as a modern document ---
    no ribbon, no fanfold paper, no 40-column smudge.
  ], [
    #text(font: f-sans, size: 10pt,
          tracking: 0.35pt)[A CLOCK THAT'S ALWAYS RIGHT]
    #v(0.4em)

    FujiNet knows the time --- it asks the Internet. Programs that are
    FujiNet-aware can stamp files and screens with the real date and
    time, something no stock ATARI ever managed.

    #v(0.7em)
    #text(font: f-sans, size: 10pt,
          tracking: 0.35pt)[THE N: DEVICE]
    #v(0.4em)

    Programs written for FujiNet can open #strong[N:] the way they open
    D: or P: --- and reach TCP, UDP, HTTP, TELNET and more through it.
    BBSes, weather reports, news wires, chat across the world: the
    network becomes just another ATARI device, programmable from BASIC.
  ], [
    #text(font: f-sans, size: 10pt,
          tracking: 0.35pt)[KEEPING FRESH]
    #v(0.4em)

    New FujiNet firmware arrives regularly, with features and fixes.
    Flash updates over the USB port with the FujiNet Flasher from
    #text(font: f-scrn, size: 6.4pt)[fujinet.online/download] --- or
    from FujiNet's own web page, at the press of a button.

    #v(0.9em)
    #align(center,
      image("images/fujinet-logo-white.png", width: 1.7in))
    #v(0.5em)

    #align(center, text(font: f-head, weight: 700, size: 9pt,
      tracking: 0.4pt)[EIGHT DRIVES · PRINTER · MODEM \
      CLOCK · NETWORK · LOBBY])
    #v(0.5em)
    #align(center, text(size: 8.4pt)[All in one little box, and the
      box is open hardware: the schematics, the firmware, and this
      very booklet are free for anyone to study, improve and share.])
  ])
]

// ============================================================
// WHAT TO DO IF IT DOESN'T WORK  (silver Q&A, 1050 style)
// ============================================================
#page(fill: none, background: { silver-bg; folio })[
  #secmark("What To Do If It Doesn't Work")
  #headband("What To Do If", "It Doesn't Work")

  #let qa(q, a) = block(above: 0.85em, below: 0.4em, {
    par(text(font: f-head, weight: 700, size: 8.6pt,
        tracking: 0.3pt, upper(q)))
    v(2.5pt)
    a
  })

  #grid(columns: (1fr, 1fr, 1fr), column-gutter: 14pt, [
    In most cases, when something is amiss, a message appears on your
    television screen. If you get one, don't worry --- you haven't
    broken anything. The most common situations and their solutions
    are listed here.

    #qa[The computer shows BASIC's READY prompt (or the Self Test),
        not CONFIG][
      The computer didn't hear from the FujiNet. Check that the SIO
      plug is seated firmly, and that the power switch is ON --- no
      lights at power-on means no power, so try the other peripheral
      jack or a USB power source. If the lights are on, a program from
      an earlier session may still be in charge: press FujiNet's
      #strong[Button C], wait a few seconds, and turn the computer off
      and on.]

    #qa[The computer boots an old program instead of CONFIG][
      That's a feature --- whatever is mounted in drive slot 1 boots
      on every restart. To get back to CONFIG, press #strong[Button
      C], then restart the computer.]

    #qa[NO NETWORKS FOUND after scanning][
      FujiNet hears 2.4 GHz networks only. Make sure your router
      broadcasts on 2.4 GHz (nearly all do), or move the computer
      closer to it. If your network hides its name, choose
      #strong[\<Enter a specific SSID\>] and type the name yourself.]
  ], [
    #qa[CONNECT FAILED, or UNABLE TO CONNECT, every time][
      Re-enter the password slowly --- capitalization counts, and the
      characters print as #strong[\*] so mistakes hide well. If the
      password is certainly right, check whether your router restricts
      devices by MAC address; FujiNet's MAC is printed at the top of
      the scan screen.]

    #qa[COULD NOT MOUNT HOST SLOT][
      The host's name is mistyped, the server is down, or --- if the
      host is #text(font: f-scrn, size: 6.4pt)[SD] --- no card is in
      the slot. Press #key[E] and check the spelling; make sure the
      card is FAT32 and clicked all the way in.]

    #qa[COULD NOT OPEN DIRECTORY][
      The folder went missing, or a filter is asking for something
      that isn't there. Press #key[F] and enter a blank filter, then
      try again.]

    #qa[I pressed W but the slot says R: ERROR SETTING DISK MODE][
      The host is read-only --- public servers usually are. Copy the
      image to your SD card with #key[C], mount the copy, and write on
      that.]
  ], [
    #qa[I booted a game and got a blue screen, garbage, or BASIC][
      Hold #key[option] down and #emph[keep holding it] until the
      program starts loading. On XL and XE computers, OPTION during a
      restart disables built-in BASIC, which most games insist on.]

    #qa[My real disk drive and the FujiNet fight over drive 1][
      Two drives are answering the same number. Renumber the real
      drive (the switches on its back), or keep FujiNet's slot 1 empty
      and boot from the real drive.]

    #qa[The highlight bar is red, and CONFIG never offers a network][
      The wireless radio has been switched off on FujiNet's web page.
      Only the SD card works this way. Visit the web page from another
      computer to switch the radio back on.]

    #qa[Where did my printout go?][
      If a program "printed" and nothing happened, FujiNet's virtual
      printer caught it. Open FujiNet's web page and look under
      #strong[Printer] to view and save the output.]

    If you encounter further difficulty, the worldwide FujiNet
    community answers questions at all hours --- see the back of this
    booklet. No toll-free number required.
  ])
]

// ============================================================
// A SHORT GLOSSARY + YOU ARE NOT ALONE
// ============================================================
#secmark("A Short Glossary")
#headband("A Short Glossary,", "and Where To Find Friends")

#let gl(term, def) = par(hanging-indent: 0.16in,
  strong(term) + " --- " + def)

#grid(columns: (1fr, 1fr, 1fr), column-gutter: 14pt, [
  #gl("ATR", [the standard file format for ATARI disk images --- an
    entire diskette captured in a single file.])
  #gl("Boot", [what a computer does when switched on: load and run
    the first program it finds. Your computer boots CONFIG from the
    FujiNet, and later boots your software from drive slot 1.])
  #gl("CAS", [a cassette-tape image. Mounted in drive slot 8, it
    turns FujiNet into a program recorder.])
  #gl("CONFIG", [the program this booklet is about: FujiNet's control
    panel, loaded by your computer directly from the FujiNet.])
  #gl("Disk image", [a complete diskette stored as one file (.atr),
    ready to mount in a drive slot.])
  #gl("Drive slot", [one of FujiNet's eight virtual disk drives, D1:
    through D8:. Whatever is in slot 1 is what the computer boots.])
  #gl("Host", [a place disk images live: a TNFS, web, SMB, NFS or FTP
    server --- or the microSD card in your FujiNet.])
  #gl("Host slot", [one of the eight remembered host names at the top
    of CONFIG's main screen.])
], [
  #gl("MAC address", [a hardware serial number identifying your
    FujiNet to the network.])
  #gl("Mount", [to load a disk image into a drive slot --- the
    electronic equivalent of inserting a diskette and closing the
    drive door.])
  #gl("Read-only / read-write", [whether programs may change a
    mounted image. The R or W on each drive slot line tells you
    which.])
  #gl("SIO", [the ATARI Serial Input/Output bus --- the daisy-chain
    of peripherals your computer talks to. FujiNet joins it as
    several devices at once.])
  #gl("SSID", [the broadcast name of a wireless network --- what you
    pick from CONFIG's network list.])
  #gl("TNFS", [the Trivial Network File System, the simple, friendly
    protocol FujiNet uses to browse software servers over the
    Internet.])
  #gl("XEX", [an ATARI executable program file. FujiNet can boot one
    directly, no disk required.])
], [
  #lsub[You Are Not Alone]

  FujiNet is built and supported by a worldwide community of
  enthusiasts, and plenty of help is available, day or night:

  #v(0.3em)
  #item[Web site: #text(font: f-scrn, size: 6.2pt,
    tracking: 0pt)[fujinet.online]]
  #item[Firmware, source &\u{00a0}wiki: #text(font: f-scrn,
    size: 6.2pt, tracking: 0pt)[github.com/FujiNetWIFI]]
  #item[Flashing & updating: #text(font: f-scrn, size: 6.2pt,
    tracking: 0pt)[fujinet.online/download]]
  #item[Community Discord — the fastest place to get help:
    #text(font: f-scrn, size: 6.2pt, tracking: 0pt)[discord.gg/7MfFTvD]]
  #item[AtariAge forums — active FujiNet discussion among Atari
    owners]

  #v(0.5em)
  CONFIG is only the beginning. FujiNet-aware software can read the
  clock, fetch the weather, chat across the world, and play games
  against owners of Apples and ADAMs and Commodores. Visit the web
  site and the Discord to see what the community is building --- and
  to show off what you build.

  #v(0.8em)
  #align(center, text(font: f-head, weight: 700, size: 12.5pt, tracking: 0.5pt,
    fill: toc-blue)[A FUJINET IN EVERY HOME!])
])

#v(1fr)
#{
  set text(size: 7.2pt)
  set par(leading: 0.45em)
  grid(columns: (1fr, 1fr), column-gutter: 0.4in, [
    Every effort has been made to ensure the accuracy of the product
    documentation in this booklet. However, because the FujiNet
    community is constantly improving and updating its software and
    hardware, the authors are unable to guarantee the accuracy of
    printed material after the date of publication, and disclaim
    liability for changes, errors or omissions.
  ], [
    Unlike 1982, reproduction of this document is encouraged: it is
    distributed under the GNU General Public License v3, and its
    source lives in the #text(font: f-scrn,
    size: 5.8pt)[fujinet-manuals] repository. The FujiNet contains no
    user-serviceable parts --- but the schematics are free, so service
    them anyway.
  ])
}

// inside back cover: navy
#pagebreak()
#page(margin: 0pt, fill: navy, background: none)[]

// ============================================================
// BACK COVER
// ============================================================
#page(margin: 0pt, fill: cover-gray, background: {
  for i in range(52) {
    place(top + left, dy: 0.16in + i * 0.21in,
      line(length: 100%, stroke: 0.5pt + rgb("#d4d5d1")))
  }
})[
  #place(bottom + left, dx: 0.5in, dy: -0.32in, {
    set text(font: f-body, size: 7pt, fill: ink)
    set par(leading: 0.45em, first-line-indent: 0pt)
    par[© 2026 The FujiNet Project, for graphics and layout only. \
        All rights reversed.]
    par[PRINTED ON PLANET EARTH \ FN-CO60057 REV. A]
  })
  #place(bottom + center, dy: -0.4in,
    image("images/fujinet-logo.png", width: 1.4in))
  #place(bottom + right, dx: -0.5in, dy: -0.36in,
    text(font: f-sans, size: 7.5pt, fill: ink)[A Worldwide Community
      Project])
]
