// ============================================================
// FUJINET FOR THE ATARI 2600 -- THEORY OF OPERATION
// FujiNet Engineering Series. Build: typst compile --font-path fonts manual.typ
//
// Every address, pin, constant and listing is transcribed from the live
// sources listed in the colophon and in Appendix E; nothing is taken from
// secondary documentation. Claims carry a status tag: verified in emulation,
// host test, verified in CAD, design value (unmeasured), not yet implemented.
// ============================================================
#import "lib.typ": *

#set document(title: "FujiNet for the Atari 2600: Theory of Operation",
              author: "FujiNet Project")
#set page(
  paper: "us-letter",
  margin: (top: 1.0in, bottom: 1.0in, inside: 1.05in, outside: 0.9in),
)
#set text(font: f-body, size: 10.5pt, fill: ink, lang: "en")
#set par(justify: true, leading: 0.62em, spacing: 0.95em, first-line-indent: 0pt)
#set smartquote(enabled: true)

#show raw.where(block: false): it => box(
  fill: code-bg, inset: (x: 3pt, y: 0pt), outset: (y: 3pt), radius: 2pt,
  text(font: f-mono, size: 0.88em, fill: rgb("#9a2a1c").mix((ink, 30%)), it))
#show raw.where(block: true): it => block(
  width: 100%, breakable: true, fill: code-bg, inset: 9pt,
  stroke: (left: 2.5pt + fuji.mix((paper, 35%)), rest: 0.6pt + code-bd),
  radius: 1pt,
  text(font: f-mono, size: 8.2pt, fill: ink, it))

#show figure.caption: it => {
  set text(font: f-head, size: 8.6pt, fill: slate)
  set par(justify: false)
  [#strong[#it.supplement #context it.counter.display(it.numbering).] #it.body]
}
#set figure(numbering: "1")
#show figure.where(kind: "lst"): set figure(numbering: "1")
#show figure.where(kind: "fig"): set figure(numbering: "1")
#show figure.where(kind: table): set block(breakable: true)
#show figure.where(kind: "lst"): set block(breakable: true)

#set table(stroke: (x, y) => (
  top: if y == 0 { 1pt + ink } else { 0.5pt + rule-c },
  bottom: 0.5pt + rule-c))
#show table.cell.where(y: 0): set text(font: f-head, weight: 700, size: 8.6pt, fill: white)
#show table.cell.where(y: 0): set table.cell(fill: slate)
#set table(inset: (x: 6pt, y: 4pt))

// ---------- page chrome ----------------------------------------------
#set page(
  header: context {
    if frontmatter.get() { return }
    let pg = here().page()
    let openers = query(heading.where(level: 1)).filter(h => h.location().page() == pg)
    let divs = query(<partdiv>).filter(m => m.location().page() == pg)
    if openers.len() > 0 or divs.len() > 0 { return }
    let hs = query(heading.where(level: 1)).filter(h => h.location().page() <= pg)
    let c = if hs.len() > 0 { upper(hs.last().body) } else { [] }
    set text(font: f-head, size: 8pt, fill: slate)
    grid(columns: (1fr, auto),
      align(left)[FujiNet for the Atari 2600 · Theory of Operation],
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
      align(left)[fujiversal-atari2600 · 2600-experiment · atari2600-rev0],
      align(center)[#counter(page).display("1")],
      align(right)[Rev. 1 · October 2026])
  },
)

// ============================================================
// TITLE PAGE
// ============================================================
#{
  v(0.2in)
  text(font: f-head, weight: 700, size: 10pt, fill: fuji, tracking: 4pt)[
    FUJINET ENGINEERING SERIES]
  v(10pt)
  line(length: 100%, stroke: 2.5pt + fuji)
  v(20pt)
  text(font: f-head, weight: 700, size: 40pt, fill: ink)[
    FujiNet for the\ Atari 2600]
  v(14pt)
  text(font: f-head, weight: 600, size: 20pt, fill: fuji-d)[Theory of Operation]
  v(14pt)
  text(font: f-body, style: "italic", size: 14.5pt, fill: slate)[
    How a cartridge with thirteen address lines, eight data lines and no
    other signal becomes a network adapter, a boot loader and a text
    generator for a console with 128 bytes of RAM.]
  v(10pt)
  text(font: f-head, weight: 600, size: 11.5pt, fill: steel)[
    Hardware: Fujiversal-Atari2600 Rev0 · Cartridge firmware: fujivcs ·
    Adapter firmware: fujiversal-atari2600]
  v(1fr)
  block(width: 100%, inset: 0pt, {
    set text(font: f-head, size: 9.5pt, fill: slate)
    line(length: 100%, stroke: 0.7pt + rule-c)
    v(8pt)
    grid(columns: (1fr, 1fr), row-gutter: 5pt,
      [The RP2040 + ESP32-S3 cartridge design],
      align(right)[Revision 1 · October 2026],
      [Bus · Mailbox · Display · Boot · Verification],
      align(right)[The FujiNet Project],
    )
  })
}
#pagebreak()

// ============================================================
// COLOPHON
// ============================================================
#{
  set text(size: 9.5pt, fill: slate)
  v(1fr)
  set par(leading: 0.6em, justify: true)
  text(font: f-head, weight: 700, size: 10pt, fill: ink)[About this document]
  v(4pt)
  [This is a theory of operation for the Atari 2600 FujiNet: the Rev0
  cartridge board, the firmware on its two microcontrollers, and the console
  programs that use it. It is written for an engineer who knows the 6507 and
  the TIA and wants to know what the cartridge does with the bus it is given,
  how the two chips divide the work, and what has and has not been proven.
  It explains mechanisms and the reasons for them; it is not a programming
  manual (that is the _FujiNet Video Computer System Programmer's Handbook_)
  and not an assembly guide.]
  v(8pt)
  [Every address, pin, constant, timing figure and listing was transcribed
  from the live sources below, not from secondary documentation, and the
  text says which. Quantitative claims carry a tag: #v-emu, #v-host, #v-cad,
  #v-design or #v-none. *No part of this design has yet run on a physical
  Atari 2600.* #ref(<ch-gaps>) lists what that leaves unproven, including defects
  found in the source while this document was written.]
  v(10pt)
  text(font: f-head, weight: 700, size: 10pt, fill: ink)[Canonical sources]
  v(4pt)
  set text(font: f-mono, size: 8.2pt, fill: ink)
  grid(columns: (auto, 1fr), row-gutter: 3pt, column-gutter: 10pt,
    [fujinet-firmware], [branch `2600-experiment` (7432186c0, 2026-09-27): `pico/atari-2600/` cartridge firmware, 6507 clients, MAME model, tests; `lib/bus/rs232`, `lib/hardware`, `include/pinmap` adapter side],
    [fujinet-hardware], [branch `atari2600-rev0` (84a8c09, 2026-09-27): `ATARI-2600/Fujiversal-Atari2600/` KiCad 10 project, README, BOM],
    [fujinet-config], [branch `add-atari-2600` (b4e3805): `atari-2600/` CONFIG, 16K],
    [fujinet-battleship], [`atari2600/` (9de5ef6): Battleship client, 16K],
    [MOS 6500 family], [datasheet AC characteristics, used only to bound the bus timing],
  )
  v(1fr)
  set text(font: f-head, size: 8pt, fill: slate)
  line(length: 100%, stroke: 0.5pt + rule-c)
  v(4pt)
  [FujiNet is an open-source project. This is a community engineering
  document; text and diagrams CC BY-SA 4.0, hardware under CERN-OHL-W-2.0,
  firmware under the licences of its repositories. "Atari" and "Video Computer
  System" are trademarks of their owner and are used to identify the console.]
}
#pagebreak()

// ============================================================
// CONTENTS
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

#frontmatter.update(false)
#counter(page).update(1)

#show: heading-rules

#include "parts/part1.typ"
#include "parts/part2.typ"
#include "parts/part3.typ"
#include "parts/part4.typ"
#include "parts/part5.typ"
#include "parts/part6.typ"

#show: appendix-rules
#include "parts/appendix.typ"
