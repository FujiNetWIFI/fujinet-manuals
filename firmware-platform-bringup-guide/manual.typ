// ============================================================
// FUJINET PLATFORM BRING-UP GUIDE
// A developer's manual for adding new platform support to FujiNet,
// using the 8-bit PC ISA bus as the worked example.
//
// Clean modern engineering style (not a period tribute): Nimbus Sans
// heads, Nimbus Roman body, Source Code Pro listings.
//
// Every technical claim is cross-referenced against the canonical
// sources, all present in the workspace:
//   fujiversal              RP2350 bus-interface firmware (PIO, USB bridge)
//   fujiversal-pcb-prototype  Universal proto board + ISA/CoCo/MSX adapters
//   fujinet-lib-experimental  host-side client (FujiBus framing, byte pipe)
//   fujinet-firmware        ESP32 device firmware (lib/bus, lib/device, lib/media)
//   FEP-004 (wiki)          the serial-encapsulation proposal
//
// Build: typst compile --font-path fonts manual.typ
// ============================================================

#let f-head = "Nimbus Sans"
#let f-body = "Nimbus Roman"
#let f-mono = "Source Code Pro"

// ---------- palette -----------------------------------------
#let ink    = rgb("#1c1c1e")
#let paper  = rgb("#ffffff")
#let fuji   = rgb("#b62a1c")            // FujiNet red (the mountain)
#let fuji-d = rgb("#7f1d12")
#let slate  = rgb("#2f4858")            // secondary heads / notes
#let steel  = rgb("#41607a")
#let rule-c = rgb("#c9ccd1")
#let code-bg= rgb("#f5f6f8")
#let code-bd= rgb("#dfe2e7")
#let note-bg= rgb("#eef3f6")
#let tip-bg = rgb("#eef5ee")
#let warn-bg= rgb("#fbeeec")
#let amber  = rgb("#a6701a")
#let amber-bg=rgb("#fbf3e3")

// ---------- page geometry -----------------------------------
#set document(title: "FujiNet Platform Bring-Up Guide",
              author: "FujiNet Project")
#set page(
  paper: "us-letter",
  margin: (top: 1.0in, bottom: 1.0in, inside: 1.05in, outside: 0.9in),
)
#set text(font: f-body, size: 10.5pt, fill: ink, lang: "en")
#set par(justify: true, leading: 0.62em, spacing: 0.95em, first-line-indent: 0pt)
#set smartquote(enabled: true)

// running chapter title (for the page header)
#let chapstate = state("chap", "")
// true while typesetting front matter (title / colophon / contents)
#let frontmatter = state("fm", true)

// ---------- heading system ----------------------------------
#set heading(numbering: "1.1.1")

#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  chapstate.update(upper(it.body))
  v(0.35in)
  block(width: 100%, {
    text(font: f-head, weight: 700, size: 11pt, fill: fuji,
      tracking: 2pt)[CHAPTER #context counter(heading).display("1")]
    v(6pt, weak: true)
    text(font: f-head, weight: 700, size: 23pt, fill: ink, it.body)
    v(7pt, weak: true)
    line(length: 100%, stroke: 2pt + fuji)
  })
  v(0.28in)
}

#show heading.where(level: 2): it => {
  v(1.1em, weak: true)
  block(below: 0.6em, {
    text(font: f-head, weight: 700, size: 13.5pt, fill: slate,
      [#context counter(heading).display("1.1")#h(10pt)#it.body])
  })
}

#show heading.where(level: 3): it => {
  v(0.8em, weak: true)
  block(below: 0.45em,
    text(font: f-head, weight: 700, size: 11pt, fill: steel,
      [#context counter(heading).display("1.1.1")#h(8pt)#it.body]))
}

#show heading.where(level: 4): it => {
  v(0.6em, weak: true)
  block(below: 0.35em,
    text(font: f-head, weight: 700, size: 10pt, fill: ink, it.body))
}

// ---------- inline code & raw blocks ------------------------
#show raw.where(block: false): it => box(
  fill: code-bg, inset: (x: 3pt, y: 0pt), outset: (y: 3pt), radius: 2pt,
  text(font: f-mono, size: 0.88em, fill: rgb("#9a2a1c").mix((ink, 30%)), it))

#show raw.where(block: true): it => block(
  width: 100%, breakable: true, fill: code-bg, inset: 9pt,
  stroke: (left: 2.5pt + fuji.mix((paper, 35%)), rest: 0.6pt + code-bd),
  radius: 1pt,
  text(font: f-mono, size: 8.6pt, fill: ink, it))

// ---------- callouts ----------------------------------------
#let callout(label, body, bg, bar, lc: ink) = block(
  width: 100%, above: 0.95em, below: 0.95em, breakable: true,
  fill: bg, inset: (x: 10pt, y: 8pt),
  stroke: (left: 3pt + bar, rest: none),
  {
    text(font: f-head, weight: 700, size: 8.5pt, fill: lc, tracking: 0.6pt,
      upper(label))
    v(3pt, weak: true)
    set par(leading: 0.6em, justify: true)
    body
  })

#let note(body)      = callout("Note", body, note-bg, steel, lc: slate)
#let tip(body)       = callout("Tip", body, tip-bg, rgb("#3f7d3f"), lc: rgb("#2f5d2f"))
#let important(body) = callout("Important", body, amber-bg, amber, lc: amber)
#let caution(body)   = callout("Caution", body, amber-bg, amber, lc: amber)

// drawn warning triangle (no emoji -> no NotoColorEmoji fallback)
#let warntri = box(width: 12pt, height: 11pt, baseline: 1.5pt, {
  place(polygon(fill: fuji, (6pt, 0pt), (12pt, 11pt), (0pt, 11pt)))
  place(center + horizon, dy: 2.2pt, text(fill: white, weight: 700, size: 7pt)[!])
})
#let warning(body) = block(
  width: 100%, above: 0.95em, below: 0.95em, breakable: true,
  fill: warn-bg, inset: (x: 10pt, y: 8pt), stroke: (left: 3pt + fuji, rest: none),
  {
    grid(columns: (auto, 1fr), column-gutter: 6pt, align: (horizon, horizon),
      warntri,
      text(font: f-head, weight: 700, size: 8.5pt, fill: fuji-d, tracking: 0.6pt)[
        MAGIC SMOKE — HARDWARE HAZARD])
    v(3pt, weak: true)
    set par(leading: 0.6em, justify: true)
    body
  })

// ---------- numbered figures / listings / tables ------------
#show figure.caption: it => {
  set text(font: f-head, size: 8.6pt, fill: slate)
  [#strong[#it.supplement #context it.counter.display(it.numbering).] #it.body]
}
#set figure(numbering: "1")

#let fig(body, caption) = figure(
  block(width: 100%, inset: 7pt, stroke: 0.6pt + rule-c, radius: 2pt, body),
  caption: caption, kind: "fig", supplement: [Figure])

#let listed(body, caption) = figure(body, caption: caption,
  kind: "lst", supplement: [Listing])

#let tbl(body, caption) = figure(body, caption: caption,
  kind: table, supplement: [Table])

#show figure.where(kind: "lst"): set figure(numbering: "1")
#show figure.where(kind: "fig"): set figure(numbering: "1")

// table base style
#set table(stroke: (x, y) => (
  top: if y == 0 { 1pt + ink } else { 0.5pt + rule-c },
  bottom: 0.5pt + rule-c))
#show table.cell.where(y: 0): set text(font: f-head, weight: 700, size: 8.6pt, fill: white)
#show table.cell.where(y: 0): set table.cell(fill: slate)
#set table(inset: (x: 6pt, y: 4pt))

// ---------- small helpers -----------------------------------
#let kbd(s) = box(fill: rgb("#ececec"), inset: (x: 4pt, y: 1pt), radius: 2pt,
  stroke: 0.5pt + rgb("#bdbdbd"), text(font: f-head, size: 8pt, s))

// a labeled byte-field strip (for packet diagrams)
#let bytefield(..cells) = {
  let cs = cells.pos()
  align(center, block(above: 0.6em, below: 0.4em,
    grid(columns: cs.map(c => c.at(1)), rows: auto, stroke: 0.7pt + slate,
      ..cs.map(c => grid.cell(inset: 5pt, align: center,
        text(font: f-mono, size: 8pt, fill: ink, c.at(0)))))))
}

// part divider
#let part(num, title, blurb) = {
  pagebreak(weak: true)
  [#metadata("pd") <partdiv>]
  v(1fr)
  block(width: 100%, {
    text(font: f-head, weight: 700, size: 12pt, fill: fuji, tracking: 3pt)[PART #num]
    v(10pt, weak: true)
    text(font: f-head, weight: 700, size: 30pt, fill: ink, title)
    v(14pt, weak: true)
    line(length: 40%, stroke: 2.5pt + fuji)
    v(12pt, weak: true)
    set par(leading: 0.65em)
    text(size: 11pt, fill: slate, blurb)
  })
  v(2fr)
  pagebreak(weak: true)
}

// ---------- page chrome -------------------------------------
#set page(
  header: context {
    if frontmatter.get() { return }    // no chrome on title / front
    let pg = here().page()
    // plain header (LaTeX-style) on chapter/appendix openers & part dividers
    let openers = query(heading.where(level: 1)).filter(h => h.location().page() == pg)
    let divs = query(<partdiv>).filter(m => m.location().page() == pg)
    if openers.len() > 0 or divs.len() > 0 { return }
    // running title = most recent level-1 heading at or before this page
    let hs = query(heading.where(level: 1)).filter(h => h.location().page() <= pg)
    let c = if hs.len() > 0 { upper(hs.last().body) } else { [] }
    set text(font: f-head, size: 8pt, fill: slate)
    grid(columns: (1fr, auto),
      align(left)[FujiNet Platform Bring-Up Guide],
      align(right)[#c])
    v(-6pt)
    line(length: 100%, stroke: 0.5pt + rule-c)
  },
  footer: context {
    if frontmatter.get() { return }
    set text(font: f-head, size: 8.5pt, fill: slate)
    line(length: 100%, stroke: 0.5pt + rule-c)
    v(2pt)
    grid(columns: (1fr, auto, 1fr),
      align(left)[FEP-004 · fujiversal · fujinet-firmware],
      align(center)[#counter(page).display("1")],
      align(right)[Rev. 3 · 2026])
  },
)

// ============================================================
// TITLE PAGE  (natural first page — flow, not page(), to avoid a
// spurious leading blank; chrome suppressed via frontmatter state)
// ============================================================
#{
  v(0.2in)
  text(font: f-head, weight: 700, size: 10pt, fill: fuji, tracking: 4pt)[
    FUJINET ENGINEERING SERIES]
  v(10pt)
  line(length: 100%, stroke: 2.5pt + fuji)
  v(20pt)
  text(font: f-head, weight: 700, size: 40pt, fill: ink)[
    Platform\ Bring-Up Guide]
  v(14pt)
  text(font: f-body, style: "italic", size: 15pt, fill: slate)[
    Bringing new platforms to FujiNet on the prototype board — the
    design, the decisions, and two real examples.]
  v(10pt)
  text(font: f-head, weight: 600, size: 12pt, fill: steel)[
    Worked examples: MSX and the Tandy Color Computer]
  v(1fr)
  block(width: 100%, inset: 0pt, {
    set text(font: f-head, size: 9.5pt, fill: slate)
    line(length: 100%, stroke: 0.7pt + rule-c)
    v(8pt)
    grid(columns: (1fr, 1fr), row-gutter: 5pt,
      [The ESP32 + RP2350 tandem design],
      align(right)[Revision 3 · June 2026],
      [Hardware · PIO · Firmware · Client library],
      align(right)[The FujiNet Project],
    )
  })
}
#pagebreak()

// ============================================================
// COLOPHON / FRONT
// ============================================================
#{
  set text(size: 9.5pt, fill: slate)
  v(1fr)
  set par(leading: 0.6em, justify: true)
  text(font: f-head, weight: 700, size: 10pt, fill: ink)[About this guide]
  v(4pt)
  [This manual helps a small team of hardware and firmware engineers bring
  a new computer onto FujiNet using the *bus-interface tandem* design — a
  Raspberry Pi RP2350 that speaks the machine's native bus, paired with an
  ESP32 that runs the FujiNet device firmware — built on the project's
  *prototype board* (`fujiversal-pcb-prototype`). It is deliberately not a
  recipe. It explains *why the board is designed the way it is*, then
  works two real bring-ups — MSX and the Tandy Color Computer — so you can
  see the decisions and adapt them. The aim is to teach reasoning, not
  steps, because reasoning is the only thing that transfers to the machine
  on your bench.]
  v(8pt)
  [Every register value, pin assignment, packet field, and source
  excerpt in this guide was transcribed from the live project sources
  listed on the copyright page of each repository, not from secondary
  documentation. Where the prototype is deliberately incomplete or
  risky, the text says so plainly.]
  v(10pt)
  text(font: f-head, weight: 700, size: 10pt, fill: ink)[Canonical sources]
  v(4pt)
  set text(font: f-mono, size: 8.5pt, fill: ink)
  grid(columns: (auto, 1fr), row-gutter: 3pt, column-gutter: 10pt,
    [fujinet-bringup], [*START HERE* — minimal byte relay + `iotest` host test; the bring-up MVP],
    [fujiversal], [RP2350 bus-interface firmware — PIO, USB-CDC bridge, ROM emulation],
    [fujiversal-pcb-prototype], [Universal proto board, ISA / CoCo / MSX adapters, footprints],
    [fujinet-lib-experimental], [Host client — FujiBus framing over the I/O byte pipe],
    [fujinet-firmware], [ESP32 device firmware — lib/bus, lib/device, lib/media],
    [fujinet-config], [Host-side ROM / CONFIG image served by the RP2350],
    [FEP-004 (wiki)], [FujiNet serial-encapsulation protocol proposal],
  )
  v(1fr)
  set text(font: f-head, size: 8pt, fill: slate)
  line(length: 100%, stroke: 0.5pt + rule-c)
  v(4pt)
  [FujiNet is an open-source project. This is a community engineering
  document; trademarks belong to their respective owners. The IBM PC,
  ISA, and the names of other systems are used for identification only.]
}
#pagebreak()

// ============================================================
// TABLE OF CONTENTS
// ============================================================
#{
  show outline.entry.where(level: 1): it => {
    v(8pt, weak: true)
    set text(font: f-head, weight: 700, size: 10pt, fill: ink)
    it
  }
  set text(size: 9.5pt)
  v(0.2in)
  text(font: f-head, weight: 700, size: 24pt, fill: ink)[Contents]
  v(4pt)
  line(length: 100%, stroke: 2pt + fuji)
  v(14pt)
  outline(title: none, indent: auto, depth: 2)
}

// end of front matter: enable page chrome and restart numbering
#frontmatter.update(false)
#counter(page).update(1)

// ============================================================
#part("I", "Orientation",
  [What it means to bring up a platform, how the tandem design divides
   the work between two chips, and the FujiBus protocol that ties them
   together. Read this part before touching hardware.])
// ============================================================

= Introduction

FujiNet is a network and storage peripheral for retro computers. To a
1980s machine it looks like a fast disk drive, a printer, an RS-232
modem, a real-time clock, and a handful of other devices; behind that
façade it is an ESP32 microcontroller with WiFi, an SD card, and a
small army of internet protocol adapters. "Bringing up a platform"
means making FujiNet appear as those familiar peripherals on a machine
it has never run on before.

== Start at fujinet-bringup

#important[
  Before anything in this guide, clone and read the *`fujinet-bringup`*
  repository. It is the project's canonical, deliberately-minimal first
  step, and it exists so you can prove two-way communication with your
  machine *before* committing to PCBs, PIO programs, or ROM emulation.
  This guide is what comes after — the production tandem design — but
  `fujinet-bringup` is where the work actually begins.
]

`fujinet-bringup` contains three small pieces and one method:

/ `iotest`: a tiny host-side program (it runs on your retro machine) that
  echoes bytes between the keyboard/screen and the bus. You port it by
  writing a `portio` for your platform.

/ `esp32` / `rp2350`: minimal *byte-relay* firmware for the
  microcontroller — it does nothing but shuttle bytes between the host
  bus (on GPIO) and a USB serial port. No FujiNet logic at all.

/ The method: get those two talking, then point the relay's USB port at
  the FujiNet firmware running as a *PC build* and run a "Hello World"
  that asks FujiNet for its version. Only once that works do you graduate
  to the on-board, ROM-emulating design this guide details.

This matters because it inverts the risk. The hard, scary part of a
bring-up is the electrical and timing layer; `fujinet-bringup` lets you
nail that with a breadboard, a relay, and a terminal loop before a single
custom board is fabricated.

=== The host-side contract: `portio`

Whichever path you take, the host always talks to FujiNet through five
routines. This is the same contract `iotest`, this guide's client
library (Chapter 16), and the production firmware all share:

```c
// the portio contract (fujinet-bringup iotest/src/<platform>/portio.*)
void     port_init(void);
bool     port_available(void);                 // is a byte waiting?
int      port_getc(void);                      // read one byte, or -1
int      port_getc_timeout(uint16_t ticks);
uint16_t port_getbuf(void *buf, uint16_t len, uint16_t timeout);
void     port_putc(uint8_t c);                 // write one byte
uint16_t port_putbuf(void *buf, uint16_t len);
```

`iotest` already ships working `portio` examples and build makefiles for
roughly a dozen platforms — `adam`, `apple2`, `atari`, `c64`, `coco`,
`dragon`, `h89-cpm`, `msdos`, `msx`, `vic20`, and more — so for many
machines you are adapting an example, not starting blank. The host loop
itself is just:

```c
// iotest/src/main.c  (the entire two-way test)
port_init();
while (1) {
    if (kbhit())         port_putc(cgetc());   // key  -> bus -> relay -> USB
    if (port_available()) putchar(port_getc()); // USB -> relay -> bus -> screen
}
```

== Choosing the interface: ESP32 or RP2350

The first design decision `fujinet-bringup` asks you to make is *which
microcontroller sits on the bus*, and it turns on one number: how many
bus signal lines you must manage.

#tbl(
  table(columns: (auto, auto, 1fr),
    table.header([Bus width], [Interface], [Why]),
    [*≤ 8 signal lines*], [ESP32 can do it],
    [Few enough lines to bit-bang from the ESP32's GPIO. The ESP32 is
     *not* 5 V tolerant, so it needs a level translator (the
     `fujinet-bringup` H89 example drives a `74LVC245` via `OE`/`DIR`).
     The H89 reaches FujiNet through an i8255 PPI in this way.],
    [*> 8 signal lines*], [use an RP2350],
    [Enough GPIO for a wide address/data/control bus, *and* — per
     `fujinet-bringup` — the RP2350 can interface to 5 V signal lines
     *directly, without a level shifter*. That capability is the main
     reason to reach for it.],
  ),
  [The interface decision. ISA, with 20 address + 8 data + several
   control lines, is firmly in RP2350 territory — which is why this
   guide's worked example uses one.],
) <tbl-mcu-choice>

#important[
  Note the 5 V point, because it corrects a natural assumption (and an
  error in this guide's first edition): the RP2350's direct connection to
  a 5 V bus is *intentional and supported*, not a hazard to be buffered
  away. Level shifting in this design is an *ESP32* concern, not an
  RP2350 one. See Chapter 7.
]

== The two decisions

Resist the urge to frame a bring-up as "which existing bus do I copy?"
That is the wrong question and it leads to brittle designs. There are
really only *two* decisions about how FujiNet talks to a machine, sitting
underneath one overriding goal.

*The goal: look like a boot device.* The best user experience asks the
least of the user — power on, and FujiNet is simply *there*. No second
peripheral to own, no driver to side-load first, no disk to boot from
something else. So wherever the machine allows it, FujiNet should *look
like a normal boot device* and come up from bare metal. Hold this goal in
mind; it decides close calls.

*Decision 1 — do you connect through an existing disk interface, or not?*

/ No (the common case): FujiNet speaks *FEP-004* (Chapter 3) directly,
  over whatever transport the machine offers — a serial port, or a
  microcontroller you place on the parallel expansion bus. Cartridge ports
  and card slots fall here, and this is the path the rest of the guide
  builds.

/ Yes: Some machines already have a peripheral *disk* interface with a
  documented protocol — Atari's SIO, the Tandy CoCo's DriveWire. FujiNet
  can ride it by presenting as a drive, and the wire protocol could even
  be *FEP-004 carried inside* the disk protocol. But "could" is not
  "should": whether it makes sense depends entirely on the disk protocol,
  and you cannot judge that without understanding it first. Studying that
  protocol *is* the job in this case.

*Decision 2 — which microcontroller sits on the bus* — is the electrical
question from the previous section: count your signal lines (ESP32 for
few, RP2350 for many), and remember the RP2350 takes 5 V directly.

#note[
  The two decisions are independent, and the UX goal often breaks the tie.
  Riding a disk interface can be less work, but it frequently costs the
  bare-metal-boot experience: the user may have to own a disk controller
  or load its software before FujiNet appears. A cartridge or card slot,
  by contrast, lets FujiNet present a boot ROM and come up on its own.
  When in doubt, favour the path that boots from bare metal.
]

When the answer to Decision 1 is "no disk interface" and the transport is
a parallel expansion bus, you cannot simply hang the ESP32 on that bus:
parallel CPU buses are *fast and unforgiving*. A Z80 or an 8088 expects
valid data within tens of nanoseconds of asserting a read strobe; an
ESP32 running FreeRTOS and a WiFi stack cannot meet that deadline. An
RP2350 can — its Programmable I/O (PIO) blocks are deterministic state
machines that react in single clock cycles, and a whole core can be
dedicated to the bus. That is why a wide parallel-bus platform uses the
two-chip design described next, and why this guide — and the prototype
board it is built around — exists.

== The division of labour

The single most important idea in this guide is how responsibility is
split across the two chips. Internalise this and the rest of the manual
is detail.

#fig(
  align(center, {
    set text(font: f-head, size: 8.5pt)
    grid(columns: (1fr, auto, 1.05fr, auto, 1fr), align: center + horizon,
      column-gutter: 0pt,
      block(width: 100%, fill: note-bg, inset: 8pt, stroke: 1pt + slate, radius: 3pt)[
        *Host computer*\ \
        #text(size: 7.5pt)[CPU + parallel\ expansion bus\ (cartridge, card, slot)]],
      box(inset: 5pt)[#text(size: 14pt, fill: slate)[◄──►]\ #text(size: 6.5pt, fill: slate)[parallel\ bus]],
      block(width: 100%, fill: tip-bg, inset: 8pt, stroke: 1pt + rgb("#3f7d3f"), radius: 3pt)[
        *RP2350*\ #text(size: 7.5pt)[(fujiversal)]\ \
        #text(size: 7.5pt)[PIO bus interface\ ROM + I/O window\ USB-CDC device]],
      box(inset: 5pt)[#text(size: 14pt, fill: slate)[◄──►]\ #text(size: 6.5pt, fill: slate)[USB\ CDC-ACM]],
      block(width: 100%, fill: warn-bg, inset: 8pt, stroke: 1pt + fuji, radius: 3pt)[
        *ESP32-S3*\ #text(size: 7.5pt)[(fujinet-firmware)]\ \
        #text(size: 7.5pt)[devices, media,\ N: protocols\ WiFi + SD]],
    )
    v(6pt)
    text(size: 7.5pt, fill: slate)[
      nanoseconds  ·  hard real time #h(40pt) milliseconds  ·  soft real time #h(30pt) internet time]
  }),
  [The tandem architecture. The RP2350 owns the time-critical parallel
   bus; the ESP32 owns devices and the network. They meet over a USB
   serial link carrying FujiBus packets.],
)

- *The host* runs unmodified software. To it, FujiNet is a ROM in its
  address space plus a few I/O registers — nothing more exotic than a
  period-correct expansion card.

- *The RP2350* (the `fujiversal` firmware) emulates a ROM chip and a
  small bank of I/O registers on the host's bus. The ROM holds the
  host-side loader and CONFIG program. The I/O registers are a *byte
  pipe*: the host pushes and pulls bytes through them, and the RP2350
  shuttles those bytes over USB to the ESP32. The RP2350 understands
  almost nothing about FujiNet devices — it is a transparent pipe with
  one exception (ROM bank-switching, covered in Chapter 8).

- *The ESP32* (the `fujinet-firmware`) runs the entire FujiNet device
  stack: the Fuji control device, virtual disk drives, the `N:` network
  device, printers, clock, CP/M, and the internet protocol adapters
  behind them. It receives FujiBus packets over the USB serial link
  exactly as if they had arrived on any other FujiNet transport.

#important[
  Because the ESP32 sees a *serial stream of FujiBus packets*, a
  bus-based platform reuses the firmware's existing serial transport —
  the `rs232` bus class — almost unchanged. The genuinely
  platform-specific engineering concentrates in two places: the *RP2350
  PIO program* (Part III) and the *host ROM + client library* (Part IV).
  The ESP32 side is mostly a build-system and pin-map exercise. This is
  the payoff of the tandem design, and a recurring theme of this guide.
]

== What you will build, and how this guide teaches it

By the end of a bring-up you will have produced, for your target machine:

+ A configured *prototype board* — the right signals routed to the right
  GPIO for your bus, the two dev boards seated and powered (Part II).
+ A *bus adapter* — a small PCB (or, early on, a patched header) that
  mates the board to the machine's physical connector (Part II).
+ An *RP2350 PIO program* — a `boards/<platform>.pio` file that decodes
  your bus and implements the ROM + byte-pipe (Part III).
+ *ESP32 firmware support* — a build target, a pin map, and (only if
  needed) new device or media classes (Part IV).
+ A *host ROM and client library* — the loader/CONFIG image the RP2350
  serves, and the `fujinet-lib` bus backend that drives the byte pipe
  (Part IV).

This guide does *not* hand you a recipe for one bus. Instead it explains
the prototype board's design and walks two real bring-ups — *MSX* and
*CoCo* — showing the decisions that were made and why. MSX is the case
where the board fits the machine cleanly; CoCo is the case where it does
not, and has to be coaxed. Study both and you will be equipped to reason
about *your* machine, which is the only skill that actually ports. A short
design exercise near the end (Chapter 19) applies that reasoning to a bus
nobody has built yet.

== Conventions

Inline code, signal names, register names, and file paths are set in
`monospace`. Active-low signals are written `/IOR` or with an overline in
schematics (KiCad renders these as `~{IOR}`). Hexadecimal is written
`0x1234`; an I/O *port* address is also written `0x300`. GPIO numbers on
the RP2350 are written `GP17`. Callout boxes carry four levels of
emphasis:

#note[Background, rationale, or a pointer to a deeper source file.]
#tip[A shortcut, a known-good value, or a debugging trick.]
#important[Something you must get right or the design will not work.]
#warning[A way to destroy hardware. Read these twice.]

= System architecture

This chapter is the map. It names every board, chip, firmware image, and
wire, and shows where each one lives in the repositories. Later chapters
zoom into the boxes drawn here.

== The physical stack

A bring-up rig is three boards (#ref(<fig-boards>) shows how they relate):

/ Waveshare Core2350B: the RP2350 board (component `U1` on the prototype
  schematic, footprint `FujiNet:WaveShare-Core-RP2350B`). The RP2350B
  variant brings out up to 48 GPIO, which is what makes a 20-bit address
  bus plus 8-bit data plus control signals fit on one chip. It connects
  to the host bus through the prototype board, and to the ESP32 over USB.

/ Freenove ESP32-S3-CAM: the ESP32 board (component `U2`, footprint
  `FujiNet:ESP32-S3-CAM`). It runs the FujiNet firmware, holds the WiFi
  radio, and carries the microSD slot.

/ Universal prototype board: `fujiversal-pcb-prototype/Bus-proto`
  (`Universal-proto-v1`). It seats both dev boards, distributes power,
  and routes every RP2350 GPIO to a generic *bus header* through a farm
  of solder jumpers. That header is an 8-bit ISA card-edge — see the next
  section for why.

/ Bus adapter: a small per-machine board that converts the universal
  board's bus header into the target machine's physical connector. The
  repository already contains `CoCo-adapter` and `MSX-adapter`; building
  the *ISA adapter* is Chapter 6.

#note[
  The Freenove board may need a hardware tweak before its microSD works:
  one SD pin must be grounded by a solder bridge. The prototype README
  flags this (`<insert details about soldering microSD pin to ground
  here>`); confirm against your board revision before assembly.
]

== Why the inter-board bus is shaped like an ISA slot

The prototype board's generic bus header uses the footprint of an 8-bit
ISA edge connector (`Connector:Bus_ISA_8bit`). This is a *practical choice
of a cheap, available 62-pin connector* whose signal set is a superset of
most 8-bit buses — not a sign that ISA is the reference platform. Each
per-machine adapter (`MSX-adapter`, `CoCo-adapter`) carries a matching
`Bus_ISA_8bit` on the board side and the real machine connector
(`MSX-Edge`, `CoCo-edge`) on the other. The board's *default* GPIO routing
(#ref(<tbl-gpmap>)) follows the ISA pin roles, but that is a starting
assignment you customise per bus, not a fixed pinout — Chapter 4 is the
full design rationale, and Chapters 5–6 show it bent to fit MSX and CoCo.

== The two firmware images and one ROM image

Three pieces of code run in a working system:

#tbl(
  table(columns: (auto, auto, 1fr),
    table.header([Image], [Runs on], [Built from]),
    [`fujiversal` UF2], [RP2350], [`fujiversal/` — `make ROM_FILE=… BOARD=…`],
    [FujiNet firmware], [ESP32-S3], [`fujinet-firmware/` — PlatformIO env],
    [Host ROM], [host CPU\ (served by RP2350)], [`fujinet-config/` — per-platform loader + CONFIG],
  ),
  [The three build products. The host ROM is *data* compiled into the
   RP2350 image (`build/<board>/rom.h`), not a separate flash.],
)

The host ROM deserves emphasis because it is easy to forget. The RP2350
does not invent the bytes the host CPU fetches from the emulated ROM;
those bytes come from `fujinet-config`, which builds a small loader and
the CONFIG user interface for each platform. You build that ROM image
*first*, then build `fujiversal` with `ROM_FILE` pointing at it
(Chapter 15).

== The communication layers

From the host CPU down to the internet, a single disk read passes
through five distinct layers. Knowing which layer owns a problem is the
difference between an hour and a week of debugging.

#fig(
  {
    set text(font: f-head, size: 8.3pt)
    set par(justify: false)
    let row(n, name, who, what) = (
      grid.cell(fill: slate, inset: 6pt, text(fill: white, weight: 700, n)),
      grid.cell(inset: 6pt, strong(name)),
      grid.cell(inset: 6pt, text(fill: steel, who)),
      grid.cell(inset: 6pt, text(size: 7.8pt, what)),
    )
    grid(columns: (auto, auto, auto, 1fr), stroke: 0.5pt + rule-c,
      grid.cell(fill: ink, inset: 6pt, text(fill: white, weight: 700)[#h(2pt)]),
      grid.cell(fill: ink, inset: 6pt, text(fill: white, weight: 700)[Layer]),
      grid.cell(fill: ink, inset: 6pt, text(fill: white, weight: 700)[Owner]),
      grid.cell(fill: ink, inset: 6pt, text(fill: white, weight: 700)[Responsibility]),
      ..row("5", "Device / media", "ESP32", "Fuji, disk, N:, printer, clock; image formats; N: protocol adapters"),
      ..row("4", "FujiBus (FEP-004)", "ESP32 ⇄ host lib", "device + command + AUX fields + payload, SLIP-framed, checksummed"),
      ..row("3", "Byte pipe", "RP2350 ⇄ host", "the 4 I/O registers: GETC / STATUS / PUTC / CONTROL"),
      ..row("2", "Bus interface (PIO)", "RP2350", "ROM emulation, address decode, drive/sample the data bus"),
      ..row("1", "Physical bus", "adapter + board", "voltage levels, connector, timing, AEN / strobes"),
    )
  },
  [The five layers of a FujiNet transaction on a tandem platform. The
   chapters of this guide are organised bottom-up: Part II builds
   layer 1, Part III builds layers 2–3, Part IV builds layers 4–5.],
) <fig-boards>

= The FujiBus protocol (FEP-004)

FujiBus is the packet protocol the ESP32 and the host exchange. It is the
working implementation of the FEP-004 proposal, and it is identical
whether the bytes travel over a true RS-232 line, an MSX serial port, or
— in our case — the USB-CDC link between the RP2350 and the ESP32. This
chapter is a precise reference; you will implement an encoder for it in
the client library (Chapter 16) and decode it in the PIO bridge's
control path (Chapter 8).

The authoritative implementations are `FujiBusPacket.cpp` (present in
both `fujiversal/` and `fujinet-firmware/lib/bus/rs232/`) and the C
encoder in `fujinet-lib-experimental`. Where the FEP-004 wiki draft left
questions open, the live code answers them; this chapter documents the
code.

== Framing: SLIP

Every packet is wrapped in SLIP (RFC 1055) so the receiver can find frame
boundaries in a raw byte stream. A frame *both starts and ends* with the
`END` byte.

#tbl(
  table(columns: (auto, auto, 1fr),
    table.header([Symbol], [Byte], [Meaning]),
    [`END`], [`0xC0`], [Frame delimiter (sent before and after every frame)],
    [`ESC`], [`0xDB`], [Escape prefix],
    [`ESC_END`], [`0xDC`], [Follows `ESC` to mean a literal `0xC0`],
    [`ESC_ESC`], [`0xDD`], [Follows `ESC` to mean a literal `0xDB`],
  ),
  [SLIP framing bytes (`FujiBusPacket.h`). Any `0xC0` in the payload is
   sent as `0xDB 0xDC`; any `0xDB` as `0xDB 0xDD`.],
)

== The packet header

Inside the SLIP frame is a fixed six-byte header followed by optional
field descriptors, optional AUX fields, and an optional payload. All
multi-byte values are *little-endian*.

#bytefield(
  ([device\ 1], 1fr),
  ([command\ 1], 1fr),
  ([length\ 2 (LE)], 1.6fr),
  ([checksum\ 1], 1fr),
  ([descr\ 1], 1fr),
  ([fields…\ AUX], 1.6fr),
  ([payload…], 2fr),
)

#tbl(
  table(columns: (auto, auto, 1fr),
    table.header([Offset], [Field], [Meaning]),
    [0], [`device`], [Destination device ID (see device table below)],
    [1], [`command`], [Command ID; in a reply, `ACK` (`0x06`) or `NAK` (`0x15`)],
    [2–3], [`length`], [Total decoded packet length *including* the header, little-endian],
    [4], [`checksum`], [8-bit add-with-carry-fold over the whole packet with this byte zeroed],
    [5], [`descr`], [First field descriptor (see below); `0x00` if there are no AUX fields],
  ),
  [The six-byte FujiBus header (`struct fujibus_header`, `FujiBusPacket.cpp`).],
)

#note[
  The header struct is declared `static_assert(sizeof(fujibus_header)
  == 6)` and the checksum byte is asserted to be at offset 4. If you
  re-implement the header in another language, preserve this layout
  exactly — the firmware reads it as a packed C struct.
]

== The checksum

The checksum is *not* a plain XOR. It is an 8-bit running sum that folds
the carry back in after every byte, computed over the entire packet
(header + descriptors + AUX + payload) with the checksum byte set to
zero:

```c
uint8_t calcChecksum(const ByteBuffer &buf) {
    uint16_t chk = 0;
    for (size_t i = 0; i < buf.size(); ++i) {
        chk += buf[i];
        chk = (chk >> 8) + (chk & 0xFF);   // fold carry
    }
    return (uint8_t) chk;
}
```

== Field descriptors and AUX

Most FujiNet commands carry a few small "AUX" arguments — a disk sector
number, a network open mode, a string length. FEP-004 packs these
compactly. The `descr` byte (and any additional descriptor bytes)
encodes how many AUX values follow and how wide each is.

#tbl(
  table(columns: (auto, auto, auto, 1fr),
    table.header([`descr` & 0x07], [Fields], [Each], [`FUJI_FIELD_*` name]),
    [0], [0], [—], [`NONE`],
    [1], [1], [1 byte], [`A1`],
    [2], [2], [1 byte], [`A1_A2`],
    [3], [3], [1 byte], [`A1_A2_A3`],
    [4], [4], [1 byte], [`A1_A2_A3_A4`],
    [5], [1], [2 bytes], [`B12` (a `uint16`)],
    [6], [2], [2 bytes], [`B12_B34` (two `uint16`)],
    [7], [1], [4 bytes], [`C1234` (a `uint32`)],
  ),
  [Field-descriptor encoding. The two lookup tables in the code are
   `numFieldsTable = {0,1,2,3,4,1,2,1}` and
   `fieldSizeTable = {0,1,1,1,1,2,2,4}`.],
) <tbl-fields>

Bit 7 of a descriptor (`FUJI_DESCR_ADDTL_MASK`, `0x80`) means "another
descriptor byte follows", letting a packet mix field widths (for example
a 32-bit sector number *and* a one-byte unit). AUX values are written
little-endian immediately after all descriptor bytes; anything left over
is the payload.

#note[
  You rarely hand-assemble descriptors. The client library exposes
  `fuji_bus_call(device, cmd, fields, a1, a2, a3, a4, data, len, reply,
  reply_len)` plus a family of `FUJICALL_*` macros (`FUJICALL_A1`,
  `FUJICALL_B12_D`, `FUJICALL_C1234`, …) named for exactly these field
  codes. Chapter 16 shows the byte pipe underneath them.
]

== Devices and commands

A packet's first byte selects a device. The RP2350 also watches this
byte: a packet addressed to device `0xFF` (`FUJI_DEVICEID_DBC`, the bus
controller itself) is consumed by the RP2350 and never reaches the
ESP32 (Chapter 8).

#tbl(
  table(columns: (auto, auto, 1fr),
    table.header([ID], [Symbol], [Device]),
    [`0x31`–`0x3F`], [`DISK` … `DISK_LAST`], [Virtual disk drives (block devices)],
    [`0x40`–`0x43`], [`PRINTER` … `PRINTER_LAST`], [Printers / voice],
    [`0x45`], [`CLOCK`], [Real-time clock (APETime)],
    [`0x50`–`0x53`], [`SERIAL`], [Serial / modem passthrough],
    [`0x5A`], [`CPM`], [CP/M console],
    [`0x70`], [`FUJINET`], [The Fuji control device (mounts, hosts, config)],
    [`0x71`–`0x78`], [`NETWORK` … `NETWORK_LAST`], [`N:` network units (8 of them)],
    [`0x99`], [`MIDI`], [MIDI],
    [`0xFF`], [`DBC`], [Bus controller (RP2350) — intercepted locally],
  ),
  [FujiNet device IDs (`fujiDeviceID.h`). The same header is shared,
   byte-for-byte, by the RP2350 firmware and the client library.],
) <tbl-devices>

Commands are a single byte. Many are printable ASCII, a convention
inherited from the Atari SIO and `N:` heritage: `'O'` (`0x4F`) opens,
`'R'` (`0x52`) reads, `'W'` (`0x57`) writes, `'S'` (`0x53`) gets status,
`'C'` (`0x43`) closes. The Fuji control device uses a dense high range
(`0xD0`–`0xFF`) for mounts, host slots, app-keys, hashing, and the rest.
The complete list is `fujiCommandID.h`, reproduced in Appendix A.

== Request and response

The exchange is strictly command/response over the byte pipe:

+ The host (via the client library) builds a packet, SLIP-encodes it, and
  streams it out through the `PUTC` register.
+ The ESP32 decodes it, dispatches to the addressed device, and acts.
+ The ESP32 replies with a packet whose `command` is `ACK` (`0x06`) on
  success — carrying any requested data as payload — or `NAK` (`0x15`)
  on failure.
+ The host polls `STATUS` for the `available` bit, then reads the reply
  bytes back through `GETC`.

#note[
  The FEP-004 wiki draft explicitly left "reply packet structure" and
  "how to signal data availability" as open questions. The shipping code
  resolves them: replies are *full FujiBus packets* (same header,
  checksum, optional payload), and availability is signalled by the
  `STATUS` register's `available` bit in the byte pipe — no
  platform-specific interrupt line required. Document your platform's
  behaviour the same way.
]

// ============================================================
// ============================================================
#part("II", "The Prototype Board, by Example",
  [What the prototype board is, why it is built the way it is, and how to
   bend it to a new bus — taught through two real bring-ups: MSX, where the
   board fits cleanly, and the Color Computer, where it does not and has to
   be coaxed into shape.])
// ============================================================

= The prototype board, and how to think about it

Before any single platform, understand the board every platform is brought
up on: `fujiversal-pcb-prototype/Bus-proto` (`Universal-proto-v1`). It is
not an ISA card, not a CoCo cartridge, not an MSX cartridge — it is a
*development fixture* designed so you can try any of those buses without
spinning a new PCB each time. This chapter is about its design intent,
because every later decision is a negotiation with that intent.

== Why the board exists

Bringing a microcontroller up on an unfamiliar parallel bus is fiddly and
iterative: you probe, you guess, you move a wire, you try again. Respinning
a custom PCB for each guess would be absurd. The prototype board removes
that cost. It does four things and nothing more:

+ It *seats the two dev boards* — the Waveshare Core2350B (`U1`, the
  RP2350) and the Freenove ESP32-S3-CAM (`U2`) — and wires the USB link
  between them.
+ It *distributes power* with a selectable source (`J9`) and reverse
  protection (`D1`).
+ It *routes every RP2350 GPIO* to a generic, bus-shaped header (`J1`)
  through a field of solder jumpers, so you choose what reaches the bus.
+ It *brings every signal out to 0.1″ breakout headers* (`J2` on the bus
  side, `J3`/`J4` on the GPIO side) so you can probe — or patch — anything.

That is the whole board. There are *no buffers, no glue logic, no
decode* — those are decisions left to you, because they depend on the bus.

== Why the header is shaped like an ISA slot

The generic bus header `J1` has the footprint of an 8-bit ISA edge
connector (`Connector:Bus_ISA_8bit`). This is a *practical convenience,
not a statement that the board is an ISA card*. An 8-bit ISA edge is a
cheap, widely-available 62-pin connector with a sane 0.1″ pitch, and its
signal set — twenty address lines, eight data lines, a handful of control
strobes, and the common supply rails — is a comfortable *superset* of what
most 8-bit buses need. So the board borrows that connector as its
backplane, and the per-machine adapters (`MSX-adapter`, `CoCo-adapter`)
carry a matching `Bus_ISA_8bit` on one side and the real machine connector
on the other.

#important[
  Do not read the ISA-shaped header as "ISA is the reference platform".
  It is a generic interconnect that happens to use an ISA footprint. The
  worked examples in this guide are MSX and CoCo precisely to keep that
  distinction honest.
]

== The default GPIO routing

Because the header is ISA-shaped, the board's *default* jumper routing maps
each GPIO to the ISA pin of the same role. Treat this as a starting
assignment, not a fixed pinout: it is what the jumpers connect *until you
decide otherwise*.

#tbl(
  table(columns: (auto, auto, auto, auto, auto, auto),
    table.header([GP], [default], [GP], [default], [GP], [default]),
    [`GP0`–`GP7`],[`A0`–`A7`], [`GP8`–`GP15`],[`A8`–`A15`], [`GP16`–`GP19`],[`A16`–`A19`],
    [`GP20`–`GP27`],[`D0`–`D7`], [`GP28`],[strobe 1], [`GP29`],[strobe 2],
    [`GP30`],[strobe 3], [`GP31`],[strobe 4], [`GP32`],[select / `AEN`],
    [`GP33`],[clock], [`GP34`],[latch / `ALE`], [`GP35`],[reset],
  ),
  [The board's *default* GPIO routing (net labels `GP0_ISA_A0` …
   `GP35_ISA_RESET`). `GP36`–`GP47` are unassigned spares on the breakout
   headers. The four "strobe" pins are wired to ISA's
   `/MEMR`/`/MEMW`/`/IOR`/`/IOW` by default; a different bus repurposes
   them (the MSX example does exactly that).],
) <tbl-gpmap>

== The jumper farm is a routing decision, not a checklist

Thirty-nine solder jumpers sit between the GPIO map and the header.
*This is the board's customisation mechanism, and it is the part people
misuse.* The jumpers are not a ritual to perform — you do not "cut them all
and bridge them back". You make a *per-signal routing decision*:

#tbl(
  table(columns: (auto, auto, 1fr),
    table.header([Jumpers], [Default], [What deciding means]),
    [`JP1`–`JP36`], [bridged], [Each connects one GPIO to its default header pin. *Leave bridged* the signals your bus uses in their default role; *cut* the ones it does not, to free that GPIO or that header pin for another use.],
    [`JP37`–`JP39`], [open], [Optional straps for alternate routing. *Bridge* one only when a specific need calls for it.],
  ),
  [How to think about the jumpers. For a bus that matches the default map
   you change almost nothing; for one that does not, you cut what you are
   repurposing and patch in what you need.],
)

The practical consequence is the design question you should be asking from
the start: *which of my bus's signals fall on the default GPIO, which do
not, and how will I bring the strays in?* The MSX and CoCo examples are the
two answers to that question — "almost all of them do" and "several of them
don't".

== The breakout headers are also patch points

`J2` (every bus-side signal) and `J3`/`J4` (every GPIO) are the obvious
logic-analyzer taps, and you will live on them during bring-up. But they
have a second, less obvious job: they are how you *add* a connection the
board does not route by default. If your bus needs a signal on a GPIO the
default map never wired to the header, you do not respin the board — you run
a jumper wire from the GPIO breakout to wherever it needs to go. The CoCo
example turns on exactly this.

== Customising the board for your bus

Putting the chapter together, customising the board for a new machine is a
sequence of decisions, not a procedure:

+ *Enumerate the bus signals* the interface must see (address, data,
  selects, strobes, clocks, reset — and any oddities).
+ *Match them to the default GPIO routing.* Which land where they already
  are? Which need a jumper cut and re-bridged elsewhere? Which are not on
  the header at all and must be patched from a breakout?
+ *Decide the byte-pipe and ROM addresses* — where can the host reach four
  registers, and is there an address window you can present a boot ROM in?
+ *Decide voltage and power* — almost always "nothing to do" on an RP2350
  (Chapter 7).

Hold those four decisions in mind through the next two chapters; they are
the spine of both worked examples.

= MSX: when the board fits

The MSX bring-up is the easy case, and the right one to study first,
because the prototype board's default routing nearly matches the machine.
Watch how few decisions are actually forced.

== The decisions

- *Disk interface? No.* The MSX has cartridge and expansion slots but no
  standard peripheral *disk* protocol to ride, so FujiNet speaks *FEP-004*
  directly (Decision 1 from Chapter 1).

- *Look like a boot device? Yes, and MSX makes it easy.* An MSX cartridge
  whose ROM begins with the signature bytes `0x41 0x42` ("AB") at address
  `0x4000` is found by the BIOS at power-on, which calls the cartridge's
  `INIT` entry. So FujiNet presents a ROM with that header and *is* a
  normal, auto-starting cartridge — bare-metal boot, nothing pre-installed.
  This is the UX goal met for free by the platform's own conventions.

- *Which microcontroller?* The cartridge bus is wide (16 address + 8 data +
  several control), so RP2350 (Decision 2), which also takes the 5 V
  cartridge bus directly.

== Mapping MSX onto the board

The MSX cartridge is a Z80 bus: `A0`–`A15`, `D0`–`D7`, `/SLTSL` (slot
select), `/RD`, `/WR`, `/IORQ`, `/MERQ`, `CLOCK`, `RESET`. The board's
default routing absorbs it almost untouched — and where it does not match
exactly, the four "strobe" jumpers are simply *repurposed* rather than
rerouted:

#tbl(
  table(columns: (auto, auto, 1fr),
    table.header([MSX signal], [GPIO], [Note]),
    [`A0`–`A15`], [`GP0`–`GP15`], [Default address routing, unchanged.],
    [`D0`–`D7`], [`GP20`–`GP27`], [Default data routing, unchanged.],
    [`/RD`, `/WR`, `/IORQ`, `/MERQ`], [`GP28`–`GP31`], [The four default "strobe" pins, *repurposed* from ISA's `/MEMR`/`/MEMW`/`/IOR`/`/IOW` to the Z80's four control lines. No rewiring — just a different meaning in the PIO.],
    [`/SLTSL`], [`GP32`], [The default select pin (ISA's `AEN`), now the cartridge slot-select.],
    [`CLOCK`], [`GP33`], [The default clock pin.],
    [`RESET`], [`GP35`], [The default reset pin.],
  ),
  [MSX on the prototype board (from `boards/msx_proto_260402.pio`). Nothing
   is cut or patched; the default routing carries the whole bus, and the
   PIO simply reads the four strobe pins as Z80 control lines.],
) <tbl-msx-map>

That is what "the board fits" means: the only adaptation is in firmware
(what the PIO calls each pin), not in copper.

== The byte pipe and the boot ROM

MSX memory-maps the byte pipe rather than using an I/O port. The four
registers live at `0xBFFC`–`0xBFFF` — a free spot high in the cartridge's
page-2 window — and the boot ROM occupies `0x4000`–`0xBFFF`:

```text
IO_BASE     0xBFFC      ; GETC=+0  STATUS=+1  PUTC=+2  CONTROL=+3
IO_FLAG_AVAIL 0x80      ; STATUS bit 7 set when a byte is waiting
BUS_ROM_BASE 0x4000     ; the cartridge ROM window (AB header lives here)
```

#note[
  `0xBFFC` is not arbitrary, and it is worth seeing the consistency: the
  `fujinet-bringup` `iotest` MSX `portio` reads and writes the *same*
  `0xBFFC` byte pipe (`IO_OFFSET = 0x8000 + 0x3FFC`). The relay MVP and the
  production board expose the identical four registers at the identical
  address — proof that the byte pipe is one contract, not two.
]

== The adapter

Because the mapping is clean, the `MSX-adapter` is mostly straight wiring:
an MSX cartridge edge on one side, a `Bus_ISA_8bit` on the other, signal
for signal. The RP2350 meets the 5 V bus directly. There is little to
*decide* here — which is exactly why MSX is the example to cut your teeth
on.

= The Color Computer: when the board is not enough

The CoCo bring-up is the instructive case, because the prototype board, as
designed, *does not have enough of the right signals connected* for it.
Everything interesting about a real bring-up — a UX judgement call, a
hardware shortfall, and four different ways to fix it — shows up here.

== The decision that sets the tone: cartridge, not DriveWire

The CoCo is unusual in that it *does* have a disk interface FujiNet could
ride: *DriveWire*, a serial disk protocol, which is how FujiNet's existing
CoCo support works. So Decision 1 has a real "yes" answer available. Why
does the prototype-board bring-up choose the cartridge port instead?

*Because of the boot-device goal.* Riding DriveWire means the user must
have Disk BASIC and a DriveWire setup in place before FujiNet appears — a
peripheral and pre-installed software, exactly what the UX goal says to
avoid. The cartridge port, by contrast, *autostarts a Program Pak*: on
power-up the Color BASIC ROM hands control to a cartridge at `0xC000`, so a
FujiNet cartridge comes up from bare metal with nothing installed. The
worse-effort path wins because it is the better experience. This is the
Chapter 1 trade-off made concrete.

== Where the board comes up short

The 6809 cartridge edge brings signals the ISA-shaped default routing never
anticipated: *two* phase clocks (`E` and `Q`, where ISA has one), plus
cartridge control lines — `/CART`, `/SLENB`, `/HALT`, `/NMI`, `SND` — that
have no analogue in the default map at all. The board simply does not route
all of them to where the `CoCo-adapter` can reach them. Put plainly: *as
built, the proto board does not have enough signals connected for CoCo.*

This is not a defect; it is the expected outcome of a generic fixture
meeting a specific machine. The skill is recognising the gap and closing it
deliberately.

== Four ways to add the missing connections

When a signal the bus needs is not routed to where it must go, you have a
genuine design choice. None of these is "correct"; they trade reworkability
against permanence against effort:

#tbl(
  table(columns: (auto, 1fr, auto),
    table.header([Approach], [What it is], [Best when]),
    [Breakout jumpers], [Run a jumper wire from a `J3`/`J4` GPIO breakout pin to where the signal must go. *This is how the team manages CoCo today.*], [You are still iterating; you want to move it tomorrow],
    [Solder front], [Omit those breakout headers and solder a wire directly between the two pads.], [The routing is settled and you want it low-profile],
    [Solder back], [Run the wire on the back of the board.], [The front is crowded; mechanical clearance matters],
    [Wire-wrap], [Fit long wire-wrap posts and wire-wrap the connections.], [Many signals to patch; you value reworkable-but-robust],
  ),
  [Four ways to patch a connection the board does not route. The CoCo
   bring-up uses breakout jumpers; the others are equally valid depending
   on how permanent and how dense the rework is.],
) <tbl-rework>

The point of listing them is not to pick a winner — it is to show that
"the board doesn't have the signal" is a solvable problem with a spectrum
of answers, and which you choose is a judgement about your build, not a
rule.

== The fingerprints of a tight fit

When the board does not match the machine, the firmware shows it. Two
artefacts in `boards/coco_proto_260402.pio` are worth recognising, because
you will produce your own versions of them:

+ *Relocated pins.* The file still carries the original pin assignment as a
  comment — `CTS=16`, `SCS=17`, `CLOCK=18` — above the assignment actually
  used — `CTS=32`, `SCS=30`, `CLOCK=33`. The signals were moved to whatever
  GPIO could actually be reached after patching, not to where they were
  first drawn.
+ *A defensive pull-up.* One unused middle pin (`GP31`) is pulled up in
  firmware "to avoid a false zero" on the bus. A stray, floating, or
  repurposed line often needs a small defensive measure like this; budget
  for one or two.

== The byte pipe and the boot ROM

The CoCo places its byte pipe in I/O-ish space and its ROM in the cartridge
window:

```text
IO_BASE      0xFF41     ; STATUS=+0  GETC=+1  CONTROL=+2  PUTC=+3  (note order)
IO_FLAG_AVAIL 0x02      ; STATUS bit set when a byte is waiting
BUS_ROM_BASE 0xC000     ; the /CTS cartridge ROM window (autostart vector here)
```

The register *order and the available-bit position differ from MSX* — they
are chosen to fall on convenient bits and addresses for the 6809 code, and
that is fine: the byte pipe is a contract about four registers, not about
their exact offsets. Timing references the `E` clock and `R/W` (a 6809 has
no separate read and write strobes), which is the other reason the CoCo PIO
looks different from the MSX one.

= Hardware decisions you will face

The two examples cover the routing decisions. This chapter collects the
remaining hardware choices — voltage, the adapter, power, and how to bring a
board up without flailing — and frames each as a decision rather than a
step.

== Voltage: usually nothing to do

On an RP2350 board this is the shortest decision in the guide: the RP2350
interfaces to a 5 V bus *directly* (Chapter 1), so there is no level
shifter and no "5 V problem". Both worked examples connect straight to the
5 V cartridge bus.

A translator becomes *mandatory* only on the narrow-bus *ESP32* path, which
is not 5 V tolerant — the `fujinet-bringup` H89 example drives a `74LVC245`
from the ESP32 via its `OE`/`DIR` pins for exactly this reason. On an
RP2350 you would add buffering only for *signal integrity* on a long or
heavily-loaded bus, never for protection.

== The adapter, from patched header to PCB

"Adapter" is a spectrum, not a deliverable you need up front:

#tbl(
  table(columns: (auto, 1fr),
    table.header([Stage], [What the adapter is]),
    [Bench bring-up], [Jumper wires from the breakout headers to the machine's connector. No PCB at all.],
    [Settling], [A scrap of perfboard, or wire-wrap, fixing the routing you proved on the bench.],
    [Reproducible], [A small PCB — machine edge on one side, `Bus_ISA_8bit` on the other — like the `MSX-adapter` and `CoCo-adapter`.],
  ),
  [You do not need the PCB to start. The examples' adapters are the
   end state, not the entry point.],
)

== Power

Bring `+5V` and `GND` from the machine to the board's power header through
`J9`, which selects the source; `D1` blocks back-feed. The Freenove ESP32
module may need its microSD pin grounded by a solder bridge before the card
works (the prototype README flags this) — confirm against your revision.

#caution[
  Decide the power source *before* connecting to a live machine. During
  bench bring-up, power from USB and leave the machine's `+5V` disconnected
  so you are never tying two supplies together. Switch to bus power only
  once the interface is otherwise proven.
]

== First power-on, in groups

Bring a board up in layers so a fault is contained to the layer you just
added — and note what this is *not*: it is not "cut every jumper first". For
a clean-fit bus (MSX) you change no jumpers at all; for a tight-fit bus
(CoCo) you first make your deliberate routing changes — cut the defaults you
are repurposing, patch in the strays (the four ways above) — and only then
stage the bring-up. Either way the staging is about *observability*:

+ *RP2350 alone*, on USB, no bus: confirm it enumerates as a USB CDC device
  (Chapter 10). Nothing should warm up.
+ *ESP32 alone*: flash it, confirm WiFi and SD.
+ *Bus, address + select*, watched at the breakouts: confirm the PIO sees
  the machine address the interface, and only when it should.
+ *Bus, strobes + data*: run the loopback of Chapter 10.
+ *In the machine*: only now move from the bench to a real slot and switch
  `J9` to bus power.

#tip[
  Keep a powered USB hub with per-port power between your workstation and
  both dev boards. You will reflash each many times, and per-port power
  lets you cycle one without disturbing the other or the bus.
]

#part("III", "The RP2350 Bus Interface",
  [The `fujiversal` firmware: how two cores and three PIO state machines
   turn a generic dev board into a ROM-and-registers peripheral, and how
   to write the PIO program that decodes *your* bus. This is the most
   platform-specific code you will write.])
// ============================================================

= Inside the fujiversal firmware

`fujiversal` is a single Pico-SDK application that emulates a ROM chip and
a four-register I/O window on the host's bus, and bridges that window to
the ESP32 over USB. Before you write a line of ISA PIO, understand how the
existing MSX and CoCo builds are structured, because your build is the
same skeleton with a new `.pio` file.

== Two cores

The firmware pins the time-critical work to one core and the housekeeping
to the other.

/ Core 1 — `romulan()`: the bus loop. It runs `__time_critical_func`, sets
  up the PIO, and then spins forever pulling latched bus words from a PIO
  FIFO and responding to them. It is the only code allowed to touch the
  bus. It services ROM reads and the I/O registers with no operating
  system, no allocation, and no blocking.

/ Core 0 — `main()`: the USB bridge. It runs TinyUSB, moves bytes between
  the host (via core 1) and the ESP32 (via USB-CDC), maintains the SLIP
  framing, and intercepts the handful of packets addressed to the bus
  controller itself. It also feeds the watchdog.

The two cores exchange single bytes through the SDK's multicore FIFO,
buffered on each side by a 1 KB ring.

== The three PIO state machines

A bus-based board uses three PIO programs, set up in
`setup_pio_irq_logic()`. They are defined per board in `boards/<board>.pio`
and are the part you rewrite for a new bus.

#tbl(
  table(columns: (auto, 1fr),
    table.header([State machine], [Job]),
    [`wait_sel`], [Watch the select/decode signals. When the host addresses the card, raise an IRQ. This program *encodes your bus's decode rule*.],
    [`send_bus`], [On that IRQ, sample *all 32 low GPIO* in one instruction and autopush the 32-bit word to the RX FIFO. Core 1 reads it as a `BusSignals` union.],
    [`read`], [Drive `D0–D7` with a byte core 1 supplies, manage the data-pin direction (high-Z except during a read of our address), and release the bus when the cycle ends.],
  ),
  [The three PIO state machines. `wait_sel` and `read` are where bus
   timing lives; `send_bus` is essentially boilerplate.],
)

== The BusSignals union

`send_bus` hands core 1 a packed 32-bit word. A C union maps the bit
positions of the GPIO onto named fields. This is the MSX definition; note
how `addr:16`, `data:8`, and the control bits line up with the pin
`.define`s in the same file:

```c
typedef union {
  struct {
    uint32_t addr:16;     // A0..A15  on GP0..GP15
    uint32_t resv:4;
    uint32_t data:8;      // D0..D7   on GP20..GP27
    uint32_t rd:1;        // /RD
    uint32_t wr:1;        // /WR
    uint32_t iorq:1;      // /IORQ
    uint32_t memrq:1;     // /MEMRQ
  } __attribute__((packed));
  uint32_t combined;
} __attribute__((packed)) BusSignals;
```

Your ISA union (Chapter 9) is wider in the address field and carries
different control bits, but the idea is identical: the bit layout *is* the
GPIO map.

== ROM emulation and the I/O window

Core 1's loop is short enough to read in full. It decides, for every
latched bus cycle, whether the address falls in the I/O window or the ROM
window, and acts:

```c
// from romulan(), main.cpp — the per-cycle decode
if (IO_BASE <= bus.addr && bus.addr < IO_TOP) {
    unsigned io_reg = (bus.addr - IO_BASE) & 0x3;
#ifdef RW_PIN
    if (!bus.rw) io_reg |= 2;          // fold R/W into the register index
#endif
    switch (io_reg) {
    case IO_GETC:   pio_put_fifo(PSM_READ, sio_hw->fifo_rd); break;   // byte from ESP32
    case IO_STATUS: pio_put_fifo(PSM_READ,
                       sio_hw->fifo_st & SIO_FIFO_ST_VLD_BITS
                         ? IO_FLAG_AVAIL : 0x00); break;              // is a byte ready?
    case IO_PUTC:   sio_hw->fifo_wr = bus.combined; break;            // byte to ESP32
    case IO_CONTROL: break;
    }
}
else if (BUS_ROM_BASE <= bus.addr && bus.addr < BUS_ROM_TOP) {
    rom_offset = bus.addr - BUS_ROM_BASE;
    pio_put_fifo(PSM_READ, rom_ptr[rom_offset]);                      // serve a ROM byte
}
```

Two things to take from this:

+ The four registers are nothing more than the two ends of the multicore
  FIFO (`sio_hw->fifo_rd` / `fifo_wr`) dressed up as bus-visible ports.
  `GETC` pops a byte the ESP32 sent; `PUTC` pushes a byte toward the
  ESP32; `STATUS` exposes the FIFO's "valid" flag as the `available` bit.
+ `IO_BASE`, `IO_GETC`, `IO_STATUS`, `IO_PUTC`, `IO_CONTROL`,
  `IO_FLAG_AVAIL`, `BUS_ROM_BASE`, and `BUS_ROM_TOP` are all `.define`s in
  the board's `.pio` file. Re-pointing the byte pipe at ISA's address map
  is mostly a matter of changing those constants.

== ROM bank-switching: the one packet the RP2350 keeps

There is a single exception to "the RP2350 is a transparent pipe". The
host-side loader needs to swap the emulated ROM's contents at runtime (to
page in CONFIG, or a booted disk's loader). It does this with FujiBus
packets addressed to `FUJI_DEVICEID_DBC` (`0xFF`). Core 0 sniffs the
second byte of every frame and, if it is `0xFF`, consumes the packet
locally instead of forwarding it:

```c
// main loop, core 0 — divert DBC frames to process_command()
if (command_size == 2 && input != FUJI_DEVICEID_DBC) {
    // second byte isn't 0xFF -> not for us, push to ESP32
    ...
}
else if (command_size > 1 && input == SLIP_END) {
    process_command(command_buf);     // a complete DBC frame: handle locally
}
```

`process_command()` implements a tiny device: `FUJICMD_OPEN` selects a RAM
bank, `FUJICMD_WRITE` fills it, `FUJICMD_CLOSE` activates it (the next
ROM fetch sees the new image), and `FUJICMD_RESET` reverts to the
built-in ROM. You inherit this for free; an ISA build needs no change
here.

== USB transport and SLIP

Everything else core 0 does is plumbing: read a byte from USB
(`tud_cdc_read`), and if a frame is in progress (started by a `SLIP_END`)
accumulate it, otherwise pass the byte straight to core 1 for the host to
read via `GETC`. Bytes the host writes via `PUTC` travel the other way,
out through `tud_cdc_write`. A 50 ms timeout flushes a partial frame so a
glitch cannot wedge the pipe. The USB side is `stdio`-based on some builds
and raw TinyUSB CDC on others; either way the ESP32 sees a clean CDC-ACM
serial port.

= Writing the PIO for your bus

The PIO is where a bus's specifics live. Chapter 8 described the three
state machines in the abstract; this chapter shows how the *real* MSX and
CoCo `.pio` files fill them in, because the differences between those two
files *are* the design decisions you will face. Read them side by side and
the pattern generalises to any bus.

#tbl(
  table(columns: (auto, 1fr, 1fr),
    table.header([Decision], [MSX (`msx_proto_260402.pio`)], [CoCo (`coco_proto_260402.pio`)]),
    [What "selected" means], [`/SLTSL` low — a ready-made slot-select line], [`/CTS` or `/SCS` low — two separate cartridge selects you decode],
    [Timing reference], [none needed; the select line frames the cycle], [the 6809 `E` clock edges],
    [Read vs write], [`/RD` / `/WR` (separate Z80 strobes)], [a single `R/W` level],
    [Data-direction flip], [tri-state when the FIFO is empty or `/SLTSL` releases], [flip `pindirs` with side-set around the `E` clock],
    [Byte pipe], [memory-mapped, `0xBFFC`], [`0xFF41` in the `/SCS` I/O spot],
    [ROM window], [`0x4000` (AB-header cartridge)], [`0xC000` (autostart Program Pak)],
  ),
  [The PIO decisions, read straight off the two shipping board files. The
   rest of this chapter walks the three that matter most.],
) <tbl-pio-decisions>

== Pin defines and the BusSignals union

Every board file opens with pin `.define`s that must match how the board is
actually routed (Chapters 4–6) and a `BusSignals` union whose bit layout
*is* that routing. They differ per bus: MSX is a clean 16-bit-address Z80
union; CoCo relocated several pins to whatever GPIO it could reach, so its
defines do not sit on the default numbers. Get these wrong and every
later instruction reads the wrong wire — so derive them from your routing
table, not from another bus's file.

```c
// MSX BusSignals (16-bit address, separate Z80 strobes)
typedef union {
  struct {
    uint32_t addr:16;     // A0..A15  GP0..GP15
    uint32_t resv:4;
    uint32_t data:8;      // D0..D7   GP20..GP27
    uint32_t rd:1, wr:1, iorq:1, memrq:1;   // GP28..GP31
  } __attribute__((packed));
  uint32_t combined;
} __attribute__((packed)) BusSignals;
```

== Decode: the `wait_sel` decision

`wait_sel` encodes what "the host is talking to us" means, and the two
examples sit at opposite ends of the difficulty range.

*MSX — a ready-made select line.* The cartridge slot hands the card a
single `/SLTSL` that is asserted exactly when this slot is addressed. So
`wait_sel` is almost nothing: wait for it, raise the IRQ, wait for it to
release.

```text
; MSX wait_sel  (SLTSL pin configured inverted, so "wait 1" = /SLTSL low)
.program wait_sel
.wrap_target
        wait 1 gpio SLTSL_PIN [WAIT_CYCLES]   ; selected
        irq 0
        wait 0 gpio SLTSL_PIN                  ; deselected
.wrap
```

*CoCo — decode it yourself.* The cartridge port has two selects (`/CTS`
for ROM, `/SCS` for the I/O spot) and no single "card selected" line, so
the program reads the pins, masks the two select bits, and only proceeds
when one is asserted — then qualifies on `R/W` and the `E` clock for
timing.

```text
; CoCo wait_sel  (decode /CTS or /SCS, then time against E)
idle:
        mov osr, ~pins          ; all pins, inverted
        out x, NUM_PINS         ; grab the /CTS /SCS bits
        jmp !x idle             ; both high -> not us
        jmp pin send            ; R/W high (read)? no need to wait
        wait 1 gpio CLOCK_PIN    ; else wait for E
send:
        irq IRQ_SEL             ; selected
        wait 0 gpio CLOCK_PIN    ; end of this bus cycle
```

The lesson is the decision, not the code: *does your bus give you a select
line, or must you synthesise one from address-decode and strobes?* If it
hands you one (MSX), `wait_sel` is trivial. If it does not (CoCo, and most
backplane buses), you decode — either in PIO instructions, or by adding a
little external logic that produces a single select line and reduces the
problem to the MSX case.

== Driving data: the `read` decision

`read` puts a byte on `D0–D7` when core 1 supplies one and tri-states the
pins the rest of the time. The decision here is *what edge tells you the
cycle is ending* so you know when to release the bus.

*MSX* keys off the select line itself: it loops checking the FIFO, drives
the data while `/SLTSL` stays asserted (`jmp pin`), and returns the pins to
inputs when the FIFO drains or the select releases.

*CoCo* keys off the `E` clock, using a side-set bit to flip `pindirs` in
lockstep with the bus cycle:

```text
; CoCo read  (side-set flips data-pin direction around E)
.program read
.side_set 1 opt
        mov x, ~null  side 1            ; D0-7 start as inputs
.wrap_target
        pull block                      ; byte from core 1
        out pins, DATA_WIDTH
        mov osr, ~null
        out pindirs, DATA_WIDTH side 0  ; drive D0-7
        wait 1 gpio CLOCK_PIN           ; through the E cycle
        wait 0 gpio CLOCK_PIN
        mov osr, null
        out pindirs, DATA_WIDTH side 1  ; release D0-7
.wrap
```

So the `read` decision follows directly from the bus's timing model: a bus
with a clean clock (CoCo's `E`, or any synchronous backplane) hangs the
direction flip on that clock; a bus framed by a chip-select (MSX) hangs it
on the select. Identify your timing reference first and the `read` program
writes itself.

`send_bus` carries no per-bus decision — it samples the GPIO and autopushes
the 32-bit word — so it is copied unchanged between board files. Keep it
verbatim.

== Building the board into fujiversal

`fujiversal` selects a board file through CMake. Add yours to the RP2350
board set alongside the existing two:

```cmake
# CMakeLists.txt — RP2350 board set
if(BOARD STREQUAL "msx_proto_260402"
   OR BOARD STREQUAL "coco_proto_260402"
   OR BOARD STREQUAL "<your_board>")              # <-- new
    set(PICO_BOARD  "pimoroni_pga2350" CACHE STRING "" FORCE)
    set(PICO_PLATFORM "rp2350-arm-s"   CACHE STRING "" FORCE)
    set(PICO_CHIP   "rp2350"           CACHE STRING "" FORCE)
endif()
```

#important[
  If your routing uses any GPIO above 31 (as both examples do — selects and
  reset live up there), the build *must* define `PICO_PIO_USE_GPIO_BASE=1`
  so the PIO can reach the upper bank. `setup_state_machine()` in
  `setup_sm.cpp` computes the GPIO base/range and rejects an illegal span
  (one straddling the 16↔32 boundary) — heed its return codes when a state
  machine silently fails to start.
]

== Generating the host ROM

The bytes the host fetches from the emulated ROM come from `fujinet-config`,
not `fujiversal`. Build the host image first, then bake it in:

```bash
# 1. build the host loader + CONFIG for your platform (fujinet-config)
make PLATFORM=<platform>          # -> config-<platform>.rom   (Chapter 15)

# 2. build the RP2350 firmware with that ROM
cd ../fujiversal
make ROM_FILE=../fujinet-config/config-<platform>.rom BOARD=<your_board>
# -> build/<your_board>/fujiversal_<your_board>.uf2
```

#note[
  Applying all of this to a bus that has *no* board file yet — decoding
  it from scratch, choosing the byte-pipe address, writing the union — is
  the design exercise in Chapter 19, worked through for the 8-bit ISA bus.
  It is the place to go once the MSX and CoCo files make sense.
]

= Bringing the RP2350 up

With a `.uf2` in hand, prove the bus interface in isolation before you ask
the ESP32 to do anything.

== Flash and enumerate

Hold the BOOTSEL button while plugging the Core2350B into USB; it mounts
as a mass-storage drive. Copy the `.uf2` (or use `picotool load`). On
reset the board should enumerate as a USB CDC-ACM serial device — that
port is the link the ESP32 will later own. Open it from your workstation
first; you have a debug console before the ESP32 is in the loop.

== The loopback test

The cleanest first proof needs no host bus at all. With the RP2350 on USB
and a terminal open on its CDC port, anything the firmware's core 0 places
in the RX ring appears on `GETC`, and anything written to `PUTC` is sent
out the CDC port. So:

+ From the workstation terminal, send a byte. Confirm (with a logic
  analyzer on `J3`/`J4`, or a tiny host test program) that a host read of
  `GETC` returns it and that `STATUS` showed `available` first.
+ Have the host write a byte to `PUTC`; confirm it arrives on the
  workstation terminal.

That round trip exercises both PIO directions, the multicore FIFO, and the
USB bridge — layers 2 and 3 of `fig-boards` — without any FujiNet
firmware running.

== Debugging with the registers

The four registers are also your instrument. A short host program that
spins reading `STATUS` and dumping `GETC` is the equivalent of a serial
monitor for the byte pipe. When something later goes wrong end-to-end, the
question "is the byte pipe healthy?" is answered here, below FujiBus and
below the ESP32.

#tip[
  Build `fujiversal` with `USE_STDIO` / `VERBOSE_DEBUG` during bring-up to
  get `printf` over the CDC port, then turn it off: the debug build steals
  the same CDC channel the ESP32 needs, so a verbose RP2350 and a
  connected ESP32 cannot coexist. Bring the byte pipe up verbose, then go
  quiet and hand the port to the ESP32.
]

// ============================================================
#part("IV", "The ESP32 Device Firmware",
  [Where the work gets easy. On the ESP32 a tandem platform is a FujiBus
   serial transport, so it reuses the existing `rs232` bus, device, and
   media classes. This part shows the build target, the pin map, the
   device and media seams, the host ROM, and the client library.])
// ============================================================

= Where a bus platform fits in fujinet-firmware

The ESP32 never sees your bus — not MSX, not CoCo, not anything. It sees a
CDC-ACM serial port carrying FujiBus packets. That is *exactly* what the
firmware's `rs232` bus already consumes — the same class used by the real
RS-232 FujiNet. The two `fujiversal` build targets that already exist,
`fujiversal-rs232` and `fujiversal-drivewire`, are proof of the pattern:
they pair the RP2350 with the ESP32 over USB and select an existing bus
on the ESP32 side.

== The rs232 bus is the FujiBus transport

`lib/bus/rs232/` is misleadingly named: it is the FujiBus/FEP-004 engine,
not an RS-232 UART driver. It contains its own copy of `FujiBusPacket.cpp`
(the same encoder you met in Chapter 3) and a `systemBus` that reads and
writes whole packets:

```cpp
// lib/bus/rs232/rs232.h  (abridged)
class systemBus {
    std::forward_list<virtualDevice *> _daisyChain;
    IOChannel *_port;
#if FUJINET_OVER_USB
    ACMChannel _serial;        // USB-CDC host channel  <-- the fujiversal path
#else
    UARTChannel _serial;       // a real UART
#endif
    std::unique_ptr<FujiBusPacket> readBusPacket(int first = -1);
    void writeBusPacket(FujiBusPacket &packet);
    void sendReplyPacket(fujiDeviceID_t source, bool ack,
                         const void *data, size_t length);
    void addDevice(virtualDevice *pDevice, fujiDeviceID_t device_id);
    // ...
};
extern systemBus SYSTEM_BUS;
```

The `FUJINET_OVER_USB` switch is the whole story: when the firmware is
built to talk to the RP2350 over USB, `_serial` is an `ACMChannel` (a
USB-CDC *host* channel); when it drives a physical serial port, it is a
`UARTChannel`. A tandem bus platform uses the USB path, identical to
`fujiversal-rs232`.

== What this means for your effort

#important[
  For a tandem bus-based platform, you usually write *no new bus class and
  no new device classes on the ESP32*. You add a build target and a pin
  map, and reuse `rs232`. New code on the ESP32 is needed only when your
  platform exposes a device the existing set does not, or needs a disk
  image format not already handled. Budget your engineering accordingly:
  the deep work is the PIO (Part III) and the host side (Chapters 15–16),
  not here.
]

= Adding the platform to the build system

PlatformIO drives the firmware build. Every platform is one `.ini` in
`build-platforms/` plus a pin map. Model your target on
`platformio-fujiversal-rs232.ini` — substitute your platform's name for
`<platform>` below.

== The build platform file

```ini
; build-platforms/platformio-fujiversal-<platform>.ini
[fujinet]
build_bus      = RS232          ; reuse the FujiBus serial bus
build_platform = BUILD_RS232    ; ... and its device/media set

[env:fujiversal-<platform>]
build_type = debug
build_flags =
    ${env.build_flags}
    -D PINMAP_FUJIVERSAL_<PLATFORM>     ; <-- new pin map (below)
    -D CONFIG_USB_HOST_ENABLED=1        ; ESP32-S3 is the USB *host*
    -D CONFIG_USB_CDC_ACM_HOST_ENABLED=1
platform         = espressif32@${fujinet.esp32s3_platform_version}
platform_packages = ${fujinet.esp32s3_platform_packages}
board            = esp32-s3-wroom-1-n16r8
```

Three lines carry the design: `build_bus = RS232` chooses the FujiBus
transport; `CONFIG_USB_HOST_ENABLED` / `CONFIG_USB_CDC_ACM_HOST_ENABLED`
make the ESP32-S3 a USB host so it can open the RP2350's CDC port; and
`PINMAP_FUJIVERSAL_<PLATFORM>` selects your board's pin assignments.

== The pin map

Add a pin-map header guarded by `PINMAP_FUJIVERSAL_<PLATFORM>` and include
it in the firmware's pin-map dispatch. On a `fujiversal` board the pin map
is small — the heavy bus I/O lives on the RP2350, so the ESP32 pin map
mostly declares the USB-host data pins, the status LEDs, the button, and
the SD pins of the Freenove module.

```c
// include/pinmap/fujiversal_<platform>.h   (mirror fujiversal_rs232.h)
#ifdef PINMAP_FUJIVERSAL_<PLATFORM>
#define PIN_LED_WIFI     GPIO_NUM_..   // white WiFi LED
#define PIN_LED_BUS      GPIO_NUM_..   // bus activity LED
#define PIN_BUTTON_A     GPIO_NUM_..
// USB host D+/D- and SD pins per the Freenove ESP32-S3-CAM board
// (no parallel-bus pins here: the RP2350 owns the host bus)
#endif
```

#note[
  The status-LED and button conventions are shared across FujiNet
  hardware (white = WiFi, an amber/orange = bus, Button A + a safe-reset).
  Match them so the existing firmware LED/boot logic "just works" — the
  `fujinet-firmware` `lib/hardware` LED code keys off these names.
]

== Partitions and flashing

Reuse the existing 16 MB partition layout
(`fujinet_partitions_16MB.csv`); the firmware image, the SPIFFS/FAT data
partition (web UI, CONFIG assets), and OTA slots are platform-independent.
Build and flash with the new env:

```bash
pio run -e fujiversal-<platform>
pio run -e fujiversal-<platform> -t upload    # over the ESP32-S3 USB/JTAG port
```

= Device classes

A FujiNet "device" is a class derived from `virtualDevice` that handles
FujiBus packets for one device ID. The `rs232` device set you inherit
covers the whole standard FujiNet feature list.

== What you inherit

#tbl(
  table(columns: (auto, auto, 1fr),
    table.header([Device ID], [Class (`lib/device/rs232/`)], [Function]),
    [`0x70`], [`rs232Fuji`], [Mounts, host slots, app-keys, hashing, adapter config — the CONFIG back end],
    [`0x31`–`0x3F`], [`rs232Disk` + media], [Virtual disk drives],
    [`0x71`–`0x78`], [`rs232Network`], [The `N:` device — one per unit, 8 units],
    [`0x40`–`0x43`], [`rs232Printer`], [Printer emulation to PDF],
    [`0x50`–`0x53`], [`rs232Modem`], [Modem / serial passthrough],
    [`0x45`], [clock], [APETime real-time clock],
    [`0x5A`], [`rs232CPM`], [CP/M console],
  ),
  [The device classes a `BUILD_RS232` platform gets for free. Each is a
   `virtualDevice` registered with `SYSTEM_BUS.addDevice()`.],
)

== The virtualDevice contract

If you ever do need a new device, the interface is small. Every device
implements two pure-virtual methods that the bus calls:

```cpp
// lib/bus/rs232/rs232.h
class virtualDevice {
protected:
    fujiDeviceID_t _devnum;
    // Per-command dispatch: usually a switch() on packet.command()
    virtual void rs232_process(FujiBusPacket &packet) = 0;
    // Return 4 status bytes (the historical DVSTAT semantics)
    virtual void rs232_status(FujiStatusReq reqType) = 0;
    virtual void shutdown() {}
public:
    fujiDeviceID_t id() { return _devnum; }
    bool is_config_device = false;   // true for the disk that boots CONFIG
    bool device_active = true;
};
```

The bus reads a packet, finds the device whose `id()` matches
`packet.device()`, and calls its `rs232_process()`. To add a device you
subclass `virtualDevice`, implement those two methods, and register an
instance:

```cpp
SYSTEM_BUS.addDevice(new myDevice(), FUJI_DEVICEID_SOMETHING);
```

#note[
  Devices are registered during `SYSTEM_BUS.setup()`, which the
  platform's `BUILD_*` selection wires up. For a stock build you
  change nothing here — the `rs232` set registers itself.
]

= Media classes

A media class turns a host disk-image file on the SD card into the
sectors a virtual disk device serves. They live in `lib/media/`, one
directory per platform (`atari`, `apple`, `adam`, `cbm`, `mac`,
`drivewire`, `rs232`, …), behind the `MediaType` interface in
`lib/media/media.h`.

== Reuse first

The disk device (`rs232Disk`) presents *block* storage: the host reads
and writes 512-byte sectors by number (the FujiBus disk command carries
the sector as a 32-bit `C1234` field). If your platform's software is
happy with raw block images, the existing `rs232` media path already
serves them and you add nothing.

== When you need a new media class

Add a `lib/media/<platform>/` only when the host expects an *image format*
with structure the firmware must understand — a header, an interleave, a
copy-protection scheme, a non-512 sector size. The class implements:

```cpp
// the shape of a MediaType (lib/media/media.h)
class MediaType {
public:
    virtual bool read(uint32_t blockNum, uint16_t *readcount) = 0;
    virtual bool write(uint32_t blockNum, bool verify)        = 0;
    virtual bool format(uint16_t *responsesize)               = 0;
    virtual mediatype_t mount(fnFile *f, uint32_t disksize)   = 0;
    virtual void unmount()                                    = 0;
    static  mediatype_t discover_disktype(const char *filename); // by extension
};
```

Decide what your host's software expects: a flat sector image (a `.dsk` or
`.img` of a floppy or hard disk) maps directly onto block reads and needs
no new class. A structured format — an interleave, an on-disk header, a
copy-protected original — would. Start flat; add a `MediaType` only when a
real image format forces you to.

#tip[
  `discover_disktype()` dispatches on file extension. When you do add a
  format, register its extension there so a user mounting `disk.img` from
  CONFIG gets the right `MediaType` automatically.
]

= The host ROM and CONFIG

The emulated ROM the RP2350 serves is built by `fujinet-config`. This is
the code that runs *on the host CPU*, and it is as platform-specific as
the PIO — it is written in the host's assembly/C and it drives the byte
pipe directly.

== What fujinet-config produces

`fujinet-config` builds, per platform, two things baked into one ROM
image:

+ A *loader*: the few hundred bytes the host runs at boot, in whatever form
  the machine autostarts (the boot-device goal from Chapter 1). MSX wants a
  cartridge ROM carrying the `AB` header at `0x4000`; CoCo wants an
  autostart Program Pak at `0xC000`; a PC ISA card wants an option ROM
  (`0x55 0xAA`, length, entry point) the BIOS calls during its
  expansion-ROM scan. Whatever the form, the loader brings up the byte
  pipe, asks FujiNet to mount the configured boot disk, and either boots it
  or launches CONFIG.

+ The *CONFIG application*: the full-screen UI for choosing WiFi hosts,
  browsing TNFS, and mounting images into the eight disk slots. Its screen
  text for each platform lives in `fujinet-config/src/<platform>/screen.c`
  and is rendered in that machine's native character set.

== How the loader talks to FujiNet

The loader uses the same four registers as everything else. In pseudocode,
sending one FujiBus byte and reading the reply is:

```text
put_byte(b):   while (inb(IO_BASE+IO_STATUS) & BUSY) ;   ; optional flow ctl
               outb(IO_BASE+IO_PUTC, b)
get_byte():    while (!(inb(IO_BASE+IO_STATUS) & IO_FLAG_AVAIL)) ;
               return inb(IO_BASE+IO_GETC)
```

On ISA those `inb`/`outb` are 8088 `IN`/`OUT` instructions to ports
`0x300`–`0x303`. On MSX they are memory reads/writes at `0xBFFC`; on CoCo,
at `0xFF41`. *Only the access method and the addresses change* — the
protocol above is identical, which is exactly why the client library
(next chapter) is mostly shared C with a thin per-platform shim.

== Building and chaining the ROM

```bash
# in fujinet-config
make PLATFORM=<platform>   # builds loader + CONFIG -> config-<platform>.rom
```

The output is consumed by `fujiversal` (Chapter 9, `ROM_FILE=…`), which
converts it to a C array (`build/<board>/rom.h`) and serves it from
`BUS_ROM_BASE`. Change the host UI, rebuild `fujinet-config`, rebuild
`fujiversal`, reflash the RP2350.

= The client library

`fujinet-lib` is the C library application programmers link against to use
FujiNet — the same one CONFIG and every networked program use. The
experimental tree, `fujinet-lib-experimental`, is the FujiBus-native
version, and its structure is the template for your platform's port.

== The backend pattern

```text
fujinet-lib-experimental/
  include/        fujinet-bus.h, fujinet-bus-ezcall.h, FUJI_FIELD_*, FujiDCB
  common/         network.c, network_json.c, fuji_*.c   (platform-independent)
  bus/
    apple2/  atari/  c64/  coco/  msx/  msdos/  adam/    (one dir per platform)
    <platform>/   <-- you add this
  Makefile        PLATFORMS = coco apple2 atari c64 msx msdos adam  (+ yours)
```

`common/` is the bulk of the library and is shared verbatim. Each
`bus/<platform>/` provides the same small surface: the three transport
primitives and the platform's port I/O.

== What bus/<platform>/ contains

#tbl(
  table(columns: (auto, 1fr),
    table.header([File], [Responsibility]),
    [`portio.s` / `portio.h`], [The platform's access to the four byte-pipe registers — `IN`/`OUT` to an I/O port (the `0xBFFC`-style memory window on MSX, an I/O port on a PC), or loads/stores to a memory address.],
    [`fujinet-bus-<platform>.c`], [Implements `fuji_bus_call`, `fuji_bus_read`, `fuji_bus_write`: build the FujiBus packet (header, descriptors, AUX, payload, checksum), SLIP-encode it, stream it out `PUTC`, then read the SLIP reply back through `GETC`.],
  ),
  [The two pieces of a `fujinet-lib` bus backend. The existing
   `bus/msdos/portio.s` (real PC `IN`/`OUT`) and `bus/msx/portio.s`
   (memory-mapped at `0xBFFC`) are the two shapes to crib from.],
)

The public surface the rest of the library calls is just:

```c
// include/fujinet-bus.h
bool   fuji_bus_call(uint8_t device, uint8_t fuji_cmd, uint8_t fields,
                     uint8_t aux1, uint8_t aux2, uint8_t aux3, uint8_t aux4,
                     const void *data, size_t data_length,
                     void *reply, size_t reply_length);
size_t fuji_bus_read (uint8_t device, void *buffer, size_t length);
size_t fuji_bus_write(uint8_t device, const void *buffer, size_t length);
```

and the `FUJICALL_*` convenience macros wrap it with the right
`FUJI_FIELD_*` descriptor. A program that opens an `N:` URL never sees a
byte of FujiBus framing; it calls `network_open()` in `common/`, which
calls `fuji_bus_call()`, which calls your `bus/<platform>` primitives,
which hit the byte pipe.

== Building it

Add your platform to `PLATFORMS` in the Makefile and build:

```bash
make <platform>     # builds fujinet.lib for your backend
```

`SRC_DIRS = common bus/%PLATFORM%` already composes the shared core with
your new backend; no other Makefile change is needed.

#tip[
  Bring the library up against the *loopback* of Chapter 10 before the
  full firmware is ready: a host program that calls `fuji_bus_write()` and
  watches the bytes appear on the RP2350's USB console proves your SLIP
  encoder and port I/O independent of the ESP32. Then connect the ESP32
  and the same call returns a real `ACK`.
]

// ============================================================
#part("V", "Integration & Validation",
  [Putting the layers together: the milestone ladder from first power-on
   to a booting machine, a troubleshooting matrix indexed by symptom, and
   a worked design exercise that applies the whole method to a bus nobody
   has built yet.])
// ============================================================

= The bring-up milestone ladder

Bring a platform up in the order the layers stack, lowest first. Each rung
is independently testable, and a failure is contained to the rung you are
on. Do not move up until the current rung is solid.

#tbl(
  table(columns: (auto, auto, 1fr),
    table.header([#h(2pt)M], [Milestone], [Proven when…]),
    [0], [Boards seated, power correct], [Continuity passes; nothing warms up on USB power; `J9` set for bench.],
    [1], [RP2350 enumerates], [The Core2350B appears as a USB CDC device on your workstation.],
    [2], [ESP32 alive], [Firmware flashed (`pio run -e fujiversal-<platform> -t upload`); WiFi joins; SD mounts.],
    [3], [Byte pipe loopback], [A host `GETC` returns a byte you injected; a host `PUTC` reaches the USB console (Chapter 10).],
    [4], [Address decode], [The logic analyzer shows the PIO IRQ firing only when the host actually addresses the interface — and on no other bus cycle.],
    [5], [FujiBus ACK], [A `fuji_bus_call()` from the host library returns `ACK` from the ESP32 (the Fuji device answers an adapter-config query).],
    [6], [CONFIG boots], [The host runs the boot ROM (cartridge / Program Pak / option ROM), the loader runs, and CONFIG draws on screen.],
    [7], [Mount + boot a disk], [CONFIG mounts a `.img`; the machine boots it through the disk device.],
    [8], [`N:` works], [A program opens `N:HTTP://…` and reads data over WiFi.],
  ),
  [The milestone ladder for a tandem bring-up. Milestones 0–4 are
   hardware/PIO (Parts II–III); 5–8 are firmware/host (Part IV).],
) <tbl-milestones>

#note[
  Milestones 1–3 are exactly the `fujinet-bringup` MVP (Chapter 1): a
  minimal byte relay plus `iotest` proving two-way communication. They
  need *no host bus board at all* — they run on the bench over USB with the
  micro wired to your machine's bus, and you can reach milestone 3 before
  the bus adapter PCB even arrives. Start there, with the FujiNet firmware
  as a PC build, and order your work so the slow-to-fabricate adapter is
  never on the critical path. Milestone 5 is the `fujinet-bringup` "Hello
  World" (fetch the adapter config) succeeding for the first time.
]

= Troubleshooting

Indexed by symptom. The "layer" column points you at the part of this
guide — and the part of `fig-boards` — that owns the fault.

#tbl(
  table(columns: (auto, auto, 1fr),
    table.header([Symptom], [Layer], [Likely cause and cure]),
    [Machine hangs or crashes the moment the interface is connected],
      [1], [The decode is too loose — it responds to cycles that are not ours. (On ISA, forgetting to gate I/O decode on `AEN` low is the classic case; the card then answers DMA addresses.) Tighten the `wait_sel` condition (Ch. 9). Or a signal is mis-routed and two drivers are fighting — check your jumper/patch routing.],
    [Interface does nothing; no PIO IRQ on the analyzer],
      [2], [`wait_sel` decode never matches. Wrong `IO_BASE`, wrong strobe polarity (strobes are usually active-*low*), or a needed signal not routed to its GPIO. Probe `J2` vs `J3`/`J4`.],
    [PIO IRQs fire on every bus cycle],
      [2], [`wait_sel` is not pre-qualifying the address window — it selects on the strobe alone. Add the window decode, or feed a decoded select line from adapter logic (Ch. 9).],
    [Host reads our register but gets `0xFF` / garbage],
      [2–3], [Data not driven in time, or direction backwards. Check the `read` program's `pindirs` flip timing against your timing reference — the clock (CoCo) or the select line (MSX) (Ch. 9).],
    [Bytes go out but no reply ever comes back],
      [3–4], [Loopback (M3) first. If loopback is fine, the ESP32 isn't opening the CDC port (`CONFIG_USB_CDC_ACM_HOST_ENABLED`?) or the RP2350 is still in verbose `printf` mode stealing the channel (Ch. 10).],
    [`fuji_bus_call` returns failure though bytes flow],
      [4], [Framing bug: checksum (the add-with-fold, not XOR), little-endian `length`, or a descriptor/AUX mismatch. Diff your encoder against `FujiBusPacket.cpp` (Ch. 3, 16).],
    [Host never runs the boot ROM],
      [5], [The ROM is not where/what the machine autostarts from — wrong `BUS_ROM_BASE`, or a bad header (the MSX `AB` signature, the CoCo autostart bytes, the PC option-ROM `0x55 0xAA`/length/checksum). Verify the served bytes at the ROM window with the analyzer on the memory-read strobe (Ch. 9, 15).],
    [CONFIG draws garbage characters],
      [5], [Host-side screen rendering — `fujinet-config/src/<platform>/screen.c` uses the wrong character set or addresses. A firmware/byte-pipe problem would corrupt *data*, not just glyphs.],
    [Intermittent corruption at speed],
      [1], [Unbuffered 5 V bus ringing, or missing decoupling at the adapter. This is the design moving off "bench only" — add the `74LVC` buffers (Ch. 6).],
  ),
  [Troubleshooting matrix. The layer numbers match `fig-boards`; fix the
   lowest failing layer first.],
)

= Design exercise: a bus nobody has built yet

The two worked examples were real — code you can open in the repository.
This closing chapter is deliberately different: it applies the same method
to a bus that has *no* board file, no adapter, and no firmware yet — the
8-bit IBM PC/XT ISA bus — purely as a reasoning exercise.

#important[
  Everything here is *illustrative and unbuilt*. The addresses, the PIO
  sketch, and the build names are a worked design, not a proven port. Its
  value is the reasoning, not the numbers. Read it as "how you would think
  this through," and verify every choice on a logic analyzer if you ever
  build it.
]

== The method: what changes from one bus to the next

Everything platform-specific is captured by a short diff. Walk it for any
new bus — ISA below, or the 6502 cartridge port, S-100 backplane, or Apple
slot on your bench — and you have your design. Everything *not* in this
table is shared and unchanged.

#tbl(
  table(columns: (auto, 1fr),
    table.header([What changes per bus], [Where you change it]),
    [Disk interface, or not], [Decision 1 (Ch. 1): a disk interface to ride, or FEP-004 direct. Favour whatever boots from bare metal.],
    [Connector and voltage], [The adapter (Ch. 6–7); on an RP2350, voltage is usually nothing to do.],
    [Signal-to-GPIO routing], [The jumpers and patches (Ch. 4–6): which signals land on the default map, which you reroute, which you wire in from the breakouts.],
    [The decode rule], [`wait_sel` (Ch. 9): what "selected" means, and the timing reference (clock edge, chip-select, or strobe).],
    [Data-direction timing], [The `read` program (Ch. 9): which edge flips `pindirs`.],
    [Byte-pipe + ROM address], [`IO_BASE` / `BUS_ROM_BASE` and the register offsets — wherever the host can reach four registers and present a boot ROM.],
    [Host loader + screens], [`fujinet-config/src/<platform>/` — the access method and the CONFIG character set.],
    [Client port I/O], [`fujinet-lib` `bus/<platform>/portio.*` — memory- or port-mapped.],
  ),
  [The per-bus diff. FujiBus framing, the ESP32 device and media classes,
   the `N:` stack, and the byte-pipe model never appear here — they do not
   change.],
)

== Working the diff for ISA

*Disk interface?* No. A PC/XT has no peripheral disk-serial bus to ride, so
FujiNet speaks FEP-004 directly. *Boot device?* Yes, and the PC offers a
clean way: the BIOS scans the expansion-ROM region `0xC0000`–`0xDFFFF` at
power-on for option ROMs marked `0x55 0xAA`, a length byte, and an entry
point. Present one at, say, `0xC8000` and FujiNet boots from bare metal —
the goal met.

*The decode rule — and the trap.* ISA gives you no ready-made select line,
so this is the CoCo-style "decode it yourself" case with one extra hazard:
`AEN`. The condition for an I/O cycle being *ours* is "address in our port
window AND a command strobe (`/IOR`/`/IOW`) asserted AND `AEN` low". `AEN`
is high during DMA; an I/O interface that ignores it answers DMA addresses
and crashes the machine. The ROM window is simpler — address in
`0xC8000…` AND `/MEMR` — and ignores `AEN`.

*Signal routing — the one place ISA is easy.* ISA is the bus the board's
default routing was drawn from, so it lands almost untouched: `A0`–`A19` on
`GP0`–`GP19`, `D0`–`D7` on `GP20`–`GP27`, the four strobes on `GP28`–`GP31`,
`AEN` on `GP32`. One caveat to reason about: `send_bus` samples only
`GP0`–`GP31`, so `AEN` at `GP32` sits just past the latched word — gate it
inside `wait_sel` (which can `wait` on any GPIO) rather than reading its
level in core 1.

*Data direction.* There is no single convenient clock to key on, so flip
`pindirs` on the active strobe edge (`/IOR` for the port read, `/MEMR` for
the ROM) — the strobe is the timing reference.

*Byte pipe + ROM.* Four I/O ports at `0x300`–`0x303` (the conventional
home-brew card range) for `GETC`/`STATUS`/`PUTC`/`CONTROL`, and the option
ROM at `0xC8000`. The pinout that supports all of this is Appendix B.

== What you would build next

If the design survives the bench — milestones 0–5 of Chapter 17, reached
with `fujinet-bringup` and a logic analyzer — the artifacts are the
familiar five, and *only* these five:

#tbl(
  table(columns: (auto, 1fr),
    table.header([Artifact], [What it is]),
    [`boards/isa_proto.pio`], [The decode + byte pipe (the `wait_sel`/`read` reasoning above).],
    [`fujiversal` board entry], [A CMake board + `PICO_PIO_USE_GPIO_BASE=1`.],
    [`platformio-fujiversal-isa.ini`], [An ESP32 build target — `build_bus = RS232`, USB host.],
    [`fujinet-config/src/isa/`], [The option-ROM loader + CONFIG screens.],
    [`fujinet-lib/bus/isa/`], [`IN`/`OUT` `portio` + the FujiBus encoder.],
  ),
  [Everything a new ISA platform would add. Nothing in the FujiBus,
   device, media, or `N:` layers changes — which is the entire payoff of
   the tandem design, and the note to end on.],
)

#tip[
  The fastest possible bring-up of any brand-new bus: feed the PIO a single
  decoded "selected" line from a small GAL on the adapter (so `wait_sel`
  reduces to the MSX form), put the byte pipe wherever the host can do four
  `peek`/`poke`s, and reuse `BUILD_RS232` whole. You can have a machine
  exchanging FujiBus packets before you have written one line of decode
  logic in PIO — which is exactly the `fujinet-bringup` philosophy, all the
  way down.
]


// ============================================================
// APPENDICES
// ============================================================
#pagebreak(weak: true)
#counter(heading).update(0)
#set heading(numbering: "A.1")
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  chapstate.update(upper(it.body))
  v(0.35in)
  block(width: 100%, {
    text(font: f-head, weight: 700, size: 11pt, fill: fuji, tracking: 2pt)[
      APPENDIX #context counter(heading).display("A")]
    v(6pt, weak: true)
    text(font: f-head, weight: 700, size: 22pt, fill: ink, it.body)
    v(7pt, weak: true)
    line(length: 100%, stroke: 2pt + fuji)
  })
  v(0.25in)
}

= FujiBus quick reference

*Frame:* `END` (`0xC0`) · header · descriptors · AUX (little-endian) ·
payload · `END`. SLIP escapes: `0xC0`→`0xDB 0xDC`, `0xDB`→`0xDB 0xDD`.

*Header (6 bytes):* `device`, `command`, `length` (u16 LE, total incl.
header), `checksum` (add-with-carry-fold, this byte zeroed during calc),
`descr` (first field descriptor).

*Field descriptors* (`descr & 0x07`; bit 7 = more follow):

#bytefield(
  ([0\ none], 1fr), ([1\ 1×u8], 1fr), ([2\ 2×u8], 1fr), ([3\ 3×u8], 1fr),
  ([4\ 4×u8], 1fr), ([5\ 1×u16], 1fr), ([6\ 2×u16], 1fr), ([7\ 1×u32], 1fr),
)

*Replies:* `command` = `ACK` `0x06` (success, optional payload) or `NAK`
`0x15` (failure).

*Device IDs:* `0x31`–`0x3F` disk · `0x40`–`0x43` printer · `0x45` clock ·
`0x50`–`0x53` serial · `0x5A` CP/M · `0x70` Fuji control · `0x71`–`0x78`
network · `0x99` MIDI · `0xFF` bus controller (DBC, intercepted by the
RP2350).

*Common commands* (`fujiCommandID.h` is authoritative; high range is the
Fuji control device):

#tbl(
  table(columns: (auto, auto, auto, auto),
    table.header([Cmd], [Name], [Cmd], [Name]),
    [`0x4F` `'O'`],[`OPEN`],      [`0xF8`],[`MOUNT_IMAGE`],
    [`0x52` `'R'`],[`READ`],      [`0xF9`],[`MOUNT_HOST`],
    [`0x57` `'W'`],[`WRITE`],     [`0xF7`],[`OPEN_DIRECTORY`],
    [`0x53` `'S'`],[`STATUS`],    [`0xF6`],[`READ_DIR_ENTRY`],
    [`0x43` `'C'`],[`CLOSE`],     [`0xE8`],[`GET_ADAPTERCONFIG`],
    [`0x50` `'P'`],[`PARSE`/`PUT`],[`0xD9`],[`CONFIG_BOOT`],
    [`0x51` `'Q'`],[`QUERY`],     [`0x80`],[`JSON_PARSE`],
    [`0x06`],[`ACK`],             [`0x81`],[`JSON_QUERY`],
    [`0x15`],[`NAK`],             [`0xFF`],[`RESET`],
  ),
  [A working subset of FujiBus commands. The full enum (≈150 names, with
   per-device aliases) is `fujiCommandID.h`, shared by firmware and lib.],
)

= ISA 8-bit (PC/XT) 62-pin pinout

Reference for the Chapter 19 design exercise: the standard 8-bit ISA
edge, with the board's default GPIO routing for the signals FujiNet uses (from `tbl-gpmap`). Pin rows: A = component
side, B = solder side.

#grid(columns: (1fr, 1fr), column-gutter: 12pt,
  tbl(
    table(columns: (auto, auto, auto),
      table.header([A], [Signal], [GP]),
      [A1],[`/I/O CH CK`],[—],
      [A2–A9],[`D7`…`D0`],[`27`…`20`],
      [A10],[`I/O CH RDY`],[—],
      [A11],[`AEN`],[`32`],
      [A12–A31],[`A19`…`A0`],[`19`…`0`],
    ),
    [A side (data, address, `AEN`, ready).],
  ),
  tbl(
    table(columns: (auto, auto, auto),
      table.header([B], [Signal], [GP]),
      [B1],[`GND`],[—], [B2],[`RESET DRV`],[`35`],
      [B3],[`+5V`],[—],  [B11],[`/SMEMW`],[`29`],
      [B12],[`/SMEMR`],[`28`], [B13],[`/IOW`],[`31`],
      [B14],[`/IOR`],[`30`],   [B20],[`CLK`],[`33`],
      [B28],[`ALE`],[`34`],    [B30],[`OSC`],[—],
      [B4..B26],[`IRQ2–7`,`DRQ/DACK`],[—],
      [B5/B7/B9],[`-5V`/`-12V`/`+12V`],[—],
    ),
    [B side (power, strobes, clocks, IRQ/DMA).],
  ),
)

#note[
  The schematic's net names confirm this mapping: `~{SMEMR}`/`~{SMEMW}`,
  `~{IOR}`/`~{IOW}`, `AEN`, `ALE`, `CLK`, `OSC`, `IO_READY`, `IRQ2`–`IRQ7`,
  `DRQ1`–`DRQ3`, `~{DACK0}`–`~{DACK3}`, `TC`, and `BA00`–`BA19` (buffered
  address). FujiNet uses only the boxed subset above.
]

= Universal board jumper & test-point reference

#tbl(
  table(columns: (auto, auto, 1fr),
    table.header([Ref], [Type / default], [Function]),
    [`JP1`–`JP36`],[solder, bridged],[One per bus signal; cut to isolate or to insert a buffer.],
    [`JP37`–`JP39`],[solder, open],[Optional configuration straps.],
    [`J1`],[`Bus_ISA_8bit`],[Universal bus header — adapter mates here.],
    [`J2`],[2×13 header],[ISA-side breakout (logic-analyzer tap).],
    [`J3`,`J4`],[2×13 / headers],[RP2350 GPIO breakouts.],
    [`J5`–`J8`],[1×20],[Core2350B and ESP32-S3 module seats.],
    [`J9`],[2×2],[Power-source selection.],
    [`U1`],[module],[WaveShare Core2350B (RP2350B).],
    [`U2`],[module],[Freenove ESP32-S3-CAM.],
    [`D1`],[diode],[Power-rail protection.],
  ),
  [Reference designators on `Universal-proto-v1`. There are no buffer ICs;
   add level-shifting on the adapter (Ch. 6).],
)

= Repository map

Where every artifact in this guide lives.

#tbl(
  table(columns: (auto, 1fr),
    table.header([Path], [Contents]),
    [`fujinet-bringup/README.md`],[*Start here.* The bring-up-first method (relay + `iotest` + PC firmware).],
    [`fujinet-bringup/iotest/`],[Host two-way-comms test + per-platform `portio` examples (~14 platforms).],
    [`fujinet-bringup/esp32/`, `…/rp2350/`],[Minimal byte-relay firmware (GPIO bus to USB serial).],
    [`fujiversal/main.cpp`],[Core 0 USB bridge + core 1 `romulan()` bus loop + DBC handler.],
    [`fujiversal/boards/*.pio`],[Per-board PIO + pin defines + `BusSignals` union (`msx_proto`, `coco_proto`; add yours).],
    [`fujiversal/setup_sm.cpp`],[Generic PIO state-machine setup helper.],
    [`fujiversal/FujiBusPacket.*`],[FujiBus encoder/decoder (RP2350 copy).],
    [`fujiversal/CMakeLists.txt`],[Board selection, `PICO_PIO_USE_GPIO_BASE`.],
    [`fujiversal-pcb-prototype/Bus-proto/`],[`Universal-proto-v1` board (jumpers, breakouts).],
    [`fujiversal-pcb-prototype/*-adapter/`],[The `MSX-adapter` and `CoCo-adapter` (templates for yours).],
    [`fujiversal-pcb-prototype/parts.pretty/ISA_8bit*`],[ISA edge footprints.],
    [`fujinet-firmware/build-platforms/platformio-fujiversal-*.ini`],[Build targets (`rs232`, `drivewire`; add yours).],
    [`fujinet-firmware/lib/bus/rs232/`],[FujiBus transport + `systemBus` (reused as-is).],
    [`fujinet-firmware/lib/device/rs232/`],[Device classes (Fuji, disk, network, printer, …).],
    [`fujinet-firmware/lib/media/`],[Image formats (`MediaType`).],
    [`fujinet-firmware/include/pinmap/`],[Pin maps (add `fujiversal_<platform>.h`).],
    [`fujinet-lib-experimental/bus/<plat>/`],[Per-platform transport + port I/O (add `bus/<platform>/`).],
    [`fujinet-lib-experimental/common/`],[Shared `network`, `json`, `fuji` code.],
    [`fujinet-config/src/<plat>/`],[Host loader + CONFIG screens (add `src/<platform>/`).],
  ),
  [The file map. "Add …" marks the artifacts a new platform creates;
   everything else is reused.],
)

= Glossary

/ AEN: Address Enable. High during ISA DMA; an I/O card must decode only
  when it is low.
/ Byte pipe: the four I/O registers (`GETC`, `STATUS`, `PUTC`, `CONTROL`)
  through which the host streams bytes to and from the RP2350.
/ DBC: device ID `0xFF`, the bus controller (RP2350) itself; DBC-addressed
  packets are consumed locally for ROM bank-switching.
/ FEP-004: the FujiNet protocol proposal that FujiBus implements.
/ FujiBus: the SLIP-framed packet protocol the host and ESP32 exchange.
/ fujiversal: the RP2350 firmware that emulates the bus interface.
/ Option ROM: a BIOS-scanned expansion ROM (`0x55 0xAA` header) in
  `0xC0000`–`0xDFFFF`; FujiNet's boot loader on ISA.
/ PIO: the RP2350's Programmable I/O — deterministic state machines that
  implement the bus timing.
/ RAMROM: the RP2350's swappable emulated-ROM image, bank-switched via DBC
  commands.
/ Tandem design: the ESP32 + RP2350 pairing for bus-based platforms.

= Bill of materials (one bring-up rig)

#tbl(
  table(columns: (auto, 1fr, auto),
    table.header([Qty], [Item], [Note]),
    [1],[Waveshare Core2350B (RP2350B)],[`U1`; ≥40 usable GPIO],
    [1],[Freenove ESP32-S3-CAM (dual-USB, microSD)],[`U2`; may need SD-pin ground mod],
    [1],[Universal-proto-v1 PCB + headers],[`fujiversal-pcb-prototype`],
    [1],[Bus adapter PCB / patched header],[you make (Ch. 6)],
    [1–2],[`74LVC245` (data) + `74LVC` buffers (addr/strobe)],[for the buffered adapter],
    [1],[GAL/ATF16V8 (optional)],[card-select decode for `wait_sel`],
    [—],[0.1 µF + 10 µF decoupling, headers, jumper wire],[],
    [1],[USB hub with per-port power],[reflash without disturbing the bus],
    [1],[Logic analyzer (≥8 ch, ≥24 MS/s)],[`J2`/`J3`/`J4` probing],
    [1],[Bus extender or socketed breakout],[spares a fragile machine connector during bring-up],
  ),
  [What it takes to bring up one tandem board. The two dev boards and
   the proto board reach milestone 3 on their own.],
)

#v(1fr)
#align(center, block(width: 80%, {
  line(length: 100%, stroke: 0.5pt + rule-c)
  v(8pt)
  set text(font: f-head, size: 8.5pt, fill: slate)
  [*FujiNet Platform Bring-Up Guide* — Revision 3, June 2026.\
   Built with Typst from sources in `fujinet-bringup`, `fujiversal`,
   `fujiversal-pcb-prototype`, `fujinet-firmware`, `fujinet-lib-experimental`,
   and `fujinet-config`.\
   The network is as easy as the disk drive — once the bus says so.]
  v(8pt)
  line(length: 100%, stroke: 0.5pt + rule-c)
}))
