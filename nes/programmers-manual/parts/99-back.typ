#import "../lib.typ": *

#appendix.update(false)

// ================= PARTS LIST =================
#page(footer: none, {
  text(font: f-head, weight: 700, style: "italic", size: 14pt,
    "FUJINET NES CARTRIDGE PARTS LIST")
  v(2pt)
  text(size: 8pt)[The parts of the Rev0 design, from its schematic. No board
  has yet been made from it; the list is here so that you know what your
  program is talking to.]
  ruled((auto, auto, 1fr, auto), size: 7.8pt,
    th[Part No.], th[Part Name], th[What it does], th[Qty.],
    [RP2354B], [Microcontroller, 2 MB flash], [The mailbox, the loader ROM, the work RAM, the bank tables, the USB link], [1],
    [AS6C4008-55], [512K × 8 static RAM, 55 ns], [PRG and CHR, in place of ROM], [2],
    [74HCT595], [Shift register], [SRAM enable, write gates, mirroring, LED], [1],
    [74HCT253], [Dual 4-to-1 selector], [CIRAM A10: the nametable mirroring], [1],
    [74HCT14], [Schmitt inverter], [PWR_OK: drive nothing into a console that is off], [1],
    [74HCT00 / 08 / 32], [Gates], [The `$5000` decode and the SRAM strobes], [2-3],
    [ESP32-S3], [WiFi microcontroller], [The FujiNet itself, at the other end of the USB link], [1],
  )
  v(6pt)
  text(size: 7.6pt)[The cartridge's firmware, its schematic, the FujiNet
  firmware, fujinet-lib, CONFIG, the four games and the programs in this manual
  are all open source. Their sources are at github.com/FujiNetWIFI.]
})

// ================= THE WARRANTY =================
#page(footer: none, {
  align(center, text(weight: 700, size: 9.5pt, tracking: 0.04em)[
    LIMITED WARRANTY\ FUJINET SOFTWARE AND THIS MANUAL])
  v(4pt)
  set text(size: 6.6pt)
  set par(justify: true, leading: 0.45em)
  columns(2, gutter: 14pt)[
    *FREE SOFTWARE:* The FujiNet firmware, its libraries and the programs
    printed in this manual are free software. You can redistribute them and/or
    modify them under the terms of the GNU General Public License as published
    by the Free Software Foundation, either version 3 of the License, or (at
    your option) any later version. The MAME device that models the cartridge
    is distributed under the BSD 3-Clause license, as MAME requires.

    *WHAT IS COVERED:* Everything in this manual was built and run before it was
    printed. That is the whole of the promise. The cartridge has been run only
    in emulation; the authors will be as interested as you are in what a real
    one does.

    *HOW TO GET SERVICE:* Ask the FujiNet community. Reports of a fault, and
    better still a fix, are welcome at github.com/FujiNetWIFI, where the
    sources live.

    *LIMITATIONS:* THIS PROGRAM IS DISTRIBUTED IN THE HOPE THAT IT WILL BE
    USEFUL, BUT WITHOUT ANY WARRANTY; WITHOUT EVEN THE IMPLIED WARRANTY OF
    MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. SEE THE GNU GENERAL
    PUBLIC LICENSE FOR MORE DETAILS. IN NO EVENT UNLESS REQUIRED BY APPLICABLE
    LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY
    WHO MODIFIES AND/OR CONVEYS THE PROGRAM, BE LIABLE TO YOU FOR DAMAGES,
    INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING
    OUT OF THE USE OR INABILITY TO USE THE PROGRAM, INCLUDING BUT NOT LIMITED TO
    LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU
    OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER
    PROGRAMS, EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGES.

    *TRADEMARKS:* Nintendo and Nintendo Entertainment System are trademarks of
    Nintendo. FujiNet is not affiliated with Nintendo, and this manual is not
    a Nintendo publication.
  ]
  v(1fr)
  align(center, text(size: 7.4pt)[FujiNet Project\ fujinet.online])
})

// ================= THE BACK COVER =================
#page(margin: 0pt, fill: black, footer: none, {
  place(top + left, image("../images/starfield-back.png", width: 7.5in, height: 5.75in))
  place(center + horizon, dy: -0.15in, box(fill: purple, radius: 50%,
    stroke: 2.4pt + white, inset: (x: 26pt, y: 10pt),
    text(font: f-head, weight: 700, style: "italic", size: 30pt, fill: white,
      "FujiNet")))
  place(center + horizon, dy: 0.55in, text(font: f-body, size: 8.5pt,
    fill: white, tracking: 0.03em)[FujiNet Project #h(8pt) fujinet.online])
  place(bottom + right, dx: -0.35in, dy: -0.3in, text(font: f-body, size: 5.5pt,
    fill: white, tracking: 0.2em, "SET IN UNIVERS AND HELVETICA"))
})
