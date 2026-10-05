#import "../lib.typ": *

// ================= THE COVER =================
// The black-box starfield, the tilted cyan wordmark, the white oblique
// "INSTRUCTION BOOKLET" line and the series badge -- here NETWORK SERIES,
// with a FujiNet cartridge where R.O.B. stood.
#let badge(size: 0.78in) = box(width: size, height: size * 1.18, {
  let s = size / 0.78in
  place(dx: 0pt, dy: 0pt, rect(width: size, height: size,
    stroke: 0.5pt + white, fill: none))
  // the Game Pak: a purple slab with the ridged top and a white label
  let bx = 0.17in * s
  let by = 0.16in * s
  let bw = 0.44in * s
  let bh = 0.5in * s
  place(dx: bx, dy: by + 0.06in * s, rect(width: bw, height: bh - 0.06in * s,
    fill: purple, radius: (bottom: 1.5pt)))
  for i in range(5) {
    place(dx: bx + 0.03in * s + i * 0.08in * s, dy: by,
      rect(width: 0.055in * s, height: 0.07in * s, fill: purple))
  }
  place(dx: bx + 0.07in * s, dy: by + 0.15in * s, rect(width: bw - 0.14in * s,
    height: 0.2in * s, fill: white))
  // signal bars on the label, the way R.O.B. had eyes
  for i in range(3) {
    let h = (0.05in + i * 0.04in) * s
    place(dx: bx + 0.14in * s + i * 0.06in * s, dy: by + 0.32in * s - h,
      rect(width: 0.035in * s, height: h, fill: purple))
  }
  place(dx: 0pt, dy: size + 1.5pt, box(width: size, align(center,
    text(font: f-body, stretch: 75%, weight: 400, size: 5.6pt * s,
      tracking: 0.12em, fill: purple, "NETWORK SERIES"))))
})

#page(margin: 0pt, fill: black, footer: none, {
  place(top + left, image("../images/starfield.png", width: 7.5in, height: 5.75in))
  // the wordmark, rising to the right as GYROMITE does
  place(top + left, dx: 1.35in, dy: 1.25in, rotate(-8deg, reflow: false,
    text(font: f-black, weight: 900, size: 84pt, tracking: -0.01em,
      fill: cyan, "FUJINET")))
  place(top + left, dx: 2.05in, dy: 2.55in, rotate(-8deg, reflow: false,
    text(font: f-head, weight: 700, style: "italic", size: 13pt,
      tracking: 0.02em, fill: white, "FOR THE NINTENDO ENTERTAINMENT SYSTEM")))
  place(top + left, dx: 0.85in, dy: 4.55in, rotate(-8deg, reflow: false,
    text(font: f-head, weight: 700, style: "italic", size: 19pt,
      tracking: 0.01em, fill: white, "PROGRAMMER'S MANUAL")))
  place(top + left, dx: 4.6in, dy: 3.82in, rotate(-8deg, reflow: false, badge()))
})

// ================= THE SEAL PAGE =================
#let seal(r: 0.62in) = box(width: 2 * r, height: 2 * r, {
  let n = 32
  let pts = range(2 * n).map(i => {
    let a = i * 180deg / n
    let rr = if calc.even(i) { r } else { r * 0.86 }
    (r + rr * calc.cos(a), r + rr * calc.sin(a))
  })
  place(polygon(fill: spot, stroke: none, ..pts))
  place(dx: r * 0.2, dy: r * 0.2, box(width: r * 1.6, height: r * 1.6,
    align(center + horizon, {
      set par(leading: 0.28em)
      text(font: f-body, weight: 700, stretch: 75%, size: 6.8pt, fill: white,
        tracking: 0.03em)[THIS SEAL IS\ YOUR ASSURANCE THAT]
      v(2pt, weak: true)
      box(stroke: 0.8pt + white, radius: 50%, inset: (x: 5pt, y: 2.5pt),
        text(font: f-head, weight: 700, style: "italic", size: 9pt,
          fill: white, text(size: 12pt, "FujiNet")))
      v(2pt, weak: true)
      text(font: f-body, weight: 700, stretch: 75%, size: 6.8pt, fill: white,
        tracking: 0.03em)[EVERY PROGRAM IN\ THIS BOOK WAS BUILT\ AND RUN]
    })))
})

#page(footer: none, margin: (x: 0.55in, y: 0.5in), {
  block(width: 100%, height: 100%, stroke: 0.5pt + ink, inset: 6pt,
    block(width: 100%, height: 100%, stroke: 0.9pt + ink,
      inset: (x: 0.45in, y: 0.32in), {
      set par(leading: 0.52em)
      set text(font: f-seal, style: "italic", size: 17.5pt, tracking: 0pt)
      grid(columns: (1fr, 1.75in), column-gutter: 2pt,
        [#text(size: 40pt, baseline: 0.14em)[L]ook for this seal on every program
        in this manual. It is the FujiNet project's assurance that what you are
        about to read was built and run, not merely written: every listing
        assembled or compiled, every transaction made against a live FujiNet,
        every screen in these pages taken from an emulated NES that was talking
        to it at the time.],
        align(bottom + right, move(dx: 0.3in, dy: 0.22in, seal(r: 0.82in))))
    }))
})

// ================= INTRODUCTION =================
#page(footer: none, {
  text(font: f-head, weight: 700, style: "italic", size: 16pt, "INTRODUCTION")
  v(2pt)
  lead[Thank you for selecting the FujiNet cartridge for the Nintendo
  Entertainment System. This manual requires cc65, the 6502 compiler suite,
  and a little patience with a video chip that only listens during vblank.]
  objbox("Object of this manual / Manual description")[
  In this manual you will learn to drive the FujiNet from your own NES
  programs, in 6502 assembly and in C. You will open network connections,
  read web pages and JSON, list directories on the network, save data in app
  keys, read the clock, and load and run new cartridge images straight off the
  network. Then you will take apart four real network games and the CONFIG
  program, to see how the pieces fit, and finish with a terminal of your own.]
  [Please read this manual to ensure proper handling of your new cartridge,
  and then save it for future reference.\
  #hilite("Caution"): Misuse of a read-modify-write instruction on the
  mailbox can cause spurious transactions. Read Chapter 4 BEFORE writing to
  addresses \$5500-\$57FF.\
  Please follow the instructions in Chapter 3 to properly set up your tools,
  your emulator and your FujiNet.]
  v(1fr)
  align(right, text(size: 8pt)[FujiNet Project\ 2026 FujiNet contributors. GPL v3.])
  v(4pt)
  text(size: 6.4pt, fill: gray)[Nintendo and Nintendo Entertainment System
  are trademarks of Nintendo. This manual and the FujiNet project are not
  affiliated with, endorsed by or sponsored by Nintendo. The cover and page
  design are an affectionate tribute to the 1985 instruction booklets.]
})

// ================= CONTENTS =================
#page(footer: none, {
  text(font: f-head, weight: 700, style: "italic", size: 16pt, "CONTENTS")
  v(4pt)
  set text(size: 7.8pt)
  columns(2, gutter: 18pt, context {
    let hs = query(heading.where(level: 1).or(heading.where(level: 2)))
    let in-apx = false
    for h in hs {
      let loc = h.location()
      let pg = counter(page).at(loc).first()
      let n = counter(heading).at(loc)
      if h.level == 1 {
        let apx = appendix.at(loc)
        let label = if apx { numbering("A", n.first()) + "." } else { str(n.first()) + "." }
        block(above: 0.62em, below: 0.25em, sticky: true,
          link(loc, grid(columns: (16pt, 1fr, auto), align: (left, left, right),
            text(weight: 700, label),
            text(weight: 700, tracking: 0.03em, [#upper(h.body) #box(width: 1fr,
              repeat(text(weight: 400)[.], gap: 1.6pt))]),
            text(weight: 700, str(pg)))))
      } else {
        block(above: 0.15em, below: 0.15em, link(loc,
          grid(columns: (16pt, 1fr, auto), [],
            [#h.body #box(width: 1fr, repeat([.], gap: 1.6pt))], str(pg))))
      }
    }
  })
})

// ================= PRECAUTIONS =================
#page(footer: none, {
  text(font: f-head, weight: 700, style: "italic", size: 16pt, "PRECAUTIONS")
  v(2pt)
  [This is a high precision cartridge. It has a few rules of its own, and a
  program that breaks one of them fails in ways that are hard to see.
  Every rule here is explained in the chapter shown.]
  v(4pt)
  set enum(numbering: n => text(weight: 700)[#n)], spacing: 0.62em)
  enum(
    [*Never use a read-modify-write instruction on \$5500-\$57FF.* INC,
     DEC, ASL, LSR, ROL and ROR write the old value back first, and on these
     pages every write is an event. Use STA, STX and STY only. In C, never
     `++` or `|=` a mailbox address. (Chapter 4)],
    [*Take the next sequence number from the cartridge.* It is the
     cartridge's ACKSEQ plus one, skipping zero -- never a counter of your
     own. Reset restarts your program but not the cartridge. (Chapter 4)],
    [*Claim the mailbox.* Put "FUJI" at \$FFF0, the last 16 bytes of PRG,
     or the cartridge shuts the mailbox off the moment your program boots.
     (Chapter 4)],
    [*Leave zero page \$E0-\$EF to the assembly library,* and \$0200-\$04FF
     to cc65's PPU queue. (Chapters 5 and 10)],
    [*Touch the PPU only in vblank or with rendering off.* The NMI may land
     in the middle of a transaction; that is fine, as long as the NMI handler
     never writes to the mailbox. (Chapter 11)],
    [*Read the reply where it lies.* The 1K at \$5000 holds still until your
     next commit, so copy from it, draw from it, or stream it back out --
     but do it before you start the next transaction. (Chapter 4)],
    [*Give MOUNT_IMAGE a full minute.* It does not answer until the whole
     image has crossed into the cartridge. (Chapter 8)],
    [*Send the full size* of SET_SSID, OPEN_APPKEY and the slot tables, and
     every parameter a command takes: a missing parameter does not earn a NAK,
     it restarts the FujiNet. (Chapter 7)],
  )
})
#frontmatter.update(false)
