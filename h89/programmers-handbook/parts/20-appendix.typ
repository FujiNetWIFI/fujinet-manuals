#import "../lib.typ": *
#import "../prog.typ": *

#chapter(20, "Appendix")

#let NET = json("../data/fwspec/net.json")

#section("Network Error Codes")[
The fourth byte of a network STATUS reply (Chapter 10) is one of these. 1 means all is well; 136
means the data has all been read. fujinet-lib returns the same numbers.

#set text(size: 8.2pt)
#stable((0.4in, 1.45in, 1fr), size: 7.2pt,
  th[Code], th[Name], th[Given when],
  ..NET.error_codes.map(e => (str(e.code), raw(e.name),
    e.meaning.replace(regex("\s*\([^)]*\.(cpp|h)[^)]*\)"), "").replace(regex(" - .*$"), ""))).flatten())
]

#section("Command Quick Reference", balance: false)[
Every command the H89's FujiNet answers, by device. FIELDS gives the size of each field in order
(1, a byte; 2, a word; 4, a long); PAYLOAD and REPLY give their length in bytes, or ACK for a reply
with no data. The page is the command's card.

#let QR = json("../data/quickref.json")
// the section already sets two columns
#{
  for d in QR.devices {
    block(sticky: true, above: 1em, below: 0.4em,
      text(font: f-head, weight: "bold", size: 8.6pt, upper(d.name) + "  " + d.ids))
    set text(font: f-sans, size: 6.4pt)
    table(columns: (1fr, 0.32in, 0.42in, 0.5in, 0.45in, 0.32in), stroke: none,
      inset: (x: 0.2em, y: 0.18em),
      table.header(th[Command], th[No.], th[Fields], th[Payload], th[Reply], th[Page]),
      ..d.rows.map(r => (text(font: f-scrn, size: 6.6pt, r.equ), r.hex, r.fields, r.payload,
        r.reply, card-page(r.equ))).flatten())
  }
}
]

#section("The H19's Escape Sequences")[
The H19 in its own Heath mode answers these. Each is the ESC character (1BH) followed by the
characters shown. In ANSI mode (after ESC <) it follows the ANSI standard instead, until ESC \[ ? 2 h.

#let esc(s) = text(font: f-scrn, size: 8pt, { set smartquote(enabled: false); "ESC " + s })
#stable((0.62in, 1fr), size: 7.4pt, breakable: true,
  th[Send], th[To],
  [#esc("H")], [Move the cursor home (top left)],
  [#esc("Y") #emph[r c]], [Move the cursor to row #emph[r], column #emph[c], each sent plus 32 (20H)],
  [#esc("A B C D")], [Move the cursor up, down, right, left],
  [#esc("I")], [Reverse line feed (up, scrolling down at the top)],
  [#esc("j k")], [Save the cursor's place; go back to it],
  [#esc("n")], [Report the cursor's place (as ESC Y r c)],
  [#esc("E")], [Clear the screen],
  [#esc("J")], [Erase to the end of the screen],
  [#esc("b")], [Erase from the start of the screen],
  [#esc("K")], [Erase to the end of the line],
  [#esc("o")], [Erase from the start of the line],
  [#esc("l")], [Erase the whole line],
  [#esc("L M")], [Insert a line; delete a line],
  [#esc("N")], [Delete a character],
  [#esc("@ O")], [Insert-character mode on; off],
  [#esc("p q")], [Reverse video on; off],
  [#esc("F G")], [Graphics characters on; off (see below)],
  [#esc("x") #emph[n]], [Set mode #emph[n]: 1 the 25th line on, 2 no key click, 3 hold screen, 4 block
    cursor, 5 cursor off, 6 keypad shifted, 7 alternate keypad, 8 auto LF after CR, 9 auto CR after LF],
  [#esc("y") #emph[n]], [Reset mode #emph[n] (the same numbers)],
  [#esc("t u")], [Keypad shifted mode on; off],
  [#esc("= >")], [Alternate keypad mode on; off],
  [#esc("v w")], [Wrap at the end of a line; discard instead],
  [#esc("{ }")], [Keyboard on; off],
  [#esc("z")], [Reset to the power-up state],
  [#esc("<")], [ANSI mode],
  [#esc("Z")], [Identify (the H19 answers ESC / K)],
)
]

#section("The H19's Graphics Characters")[
After ESC F, the H19 shows the characters from ^ (5EH) to \~ (7EH) as these 33 graphics, drawn
here from its character generator ROM (444-29), until ESC G.

#let gl(c) = {
  let code = c.to-unicode()
  let g = if code == 0x5E { 0xE07F } else if code == 0x5F { 0xE01F } else { 0xE000 + code - 0x60 }
  (text(font: f-scrn, size: 9pt, { set smartquote(enabled: false); c }),
   box(fill: tube, inset: (x: 2pt, y: 1pt), text(font: f-scrn, size: 11pt, fill: phosphor,
     top-edge: 0.8em, bottom-edge: -0.2em, str.from-unicode(g))))
}
#let names = (
  "^": "bullet", "_": "upper right triangle", "`": "vertical line", "a": "horizontal line",
  "b": "cross", "c": "upper right corner", "d": "lower right corner", "e": "lower left corner",
  "f": "upper left corner", "g": "plus or minus", "h": "right arrow", "i": "checkerboard",
  "j": "divide", "k": "down arrow", "l": "lower right quadrant", "m": "lower left quadrant",
  "n": "upper left quadrant", "o": "upper right quadrant", "p": "upper half", "q": "right half",
  "r": "upper left triangle", "s": "T, stem down", "t": "T, stem left", "u": "T, stem up",
  "v": "T, stem right", "w": "diagonal cross", "x": "slash", "y": "backslash", "z": "top line",
  "{": "bottom line", "|": "left bar", "}": "right bar", "~": "paragraph mark")
#stable((0.3in, 0.3in, 1fr, 0.3in, 0.3in, 1fr), size: 7.2pt, inset: (x: 0.3em, y: 0.2em),
  breakable: true,
  th[Key], th[Shows], th[], th[Key], th[Shows], th[],
  ..{
    let keys = names.keys()
    let half = calc.ceil(keys.len() / 2)
    let out = ()
    for i in range(half) {
      let a = keys.at(i)
      out += gl(a) + (names.at(a),)
      if i + half < keys.len() {
        let b = keys.at(i + half)
        out += gl(b) + (names.at(b),)
      } else { out += ([], [], []) }
    }
    out
  })
]

#section("CP/M 2.2: The BDOS and the BIOS")[
A CP/M program calls the BDOS with the function number in C and an argument in E or DE, then
`CALL 5`. A byte comes back in A, a word in HL.

#stable((0.3in, 1fr, 0.3in, 1fr), size: 7.2pt, inset: (x: 0.3em, y: 0.2em), breakable: true,
  th[No.], th[Function], th[No.], th[Function],
  [0], [System reset], [20], [Read sequential],
  [1], [Console input], [21], [Write sequential],
  [2], [Console output (E)], [22], [Make file],
  [3], [Reader input], [23], [Rename file],
  [4], [Punch output], [24], [Login vector],
  [5], [List output], [25], [Current disk],
  [6], [Direct console I/O (E = FFH: input)], [26], [Set DMA address],
  [7], [Get I/O byte], [27], [Allocation vector],
  [8], [Set I/O byte], [28], [Write protect disk],
  [9], [Print string to \$], [29], [Read-only vector],
  [10], [Read console buffer], [30], [Set file attributes],
  [11], [Console status], [31], [Disk parameters],
  [12], [Version number], [32], [Get/set user number],
  [13], [Reset disk system], [33], [Read random],
  [14], [Select disk], [34], [Write random],
  [15], [Open file], [35], [File size],
  [16], [Close file], [36], [Set random record],
  [17], [Search for first], [37], [Reset drive],
  [18], [Search for next], [40], [Write random, zero fill],
  [19], [Delete file], [], [],
)

The BIOS is a table of jumps; the word at 0001H holds the address of its second entry, WBOOT. The
entries, 3 bytes apart from there: WBOOT, CONST (A = FFH if a key waits), CONIN, CONOUT (C),
LIST, PUNCH, READER, HOME, SELDSK, SETTRK, SETSEC, SETDMA, READ, WRITE, LISTST, SECTRAN. The book's
`h89con.c` calls CONST, CONIN and CONOUT directly. Heath's BIOS keeps the 2 ms tick count at 000BH.
]

#section("Firmware Behaviour and Errata", balance: false)[
Everything the making of this Manual found the FujiNet's software doing that a programmer would not
expect: the firmware (by device), fujinet-lib, z88dk, and fujinet-pc where it differs from the card.
The entries that matter in practice are WARNINGs on their cards; this is the complete list, each
with the line of source it comes from, so it can be checked against later versions. `errata.md`,
beside the book's source, holds the same list.

#let ER = json("../data/errata.json")
// the section already sets two columns
#{
  let area = none
  for it in ER.items {
    if it.area != area {
      area = it.area
      block(sticky: true, above: 0.9em, below: 0.35em,
        text(font: f-head, weight: "bold", size: 8pt, upper(area)))
    }
    block(above: 0.3em, below: 0.3em, breakable: true, text(size: 6.8pt, hyphenate: true, {
      text(font: f-sans, weight: "bold", it.id + " ")
      // long names (CRT_ENABLE_COMMANDLINE) may break after an underscore
      text(font: f-scrn, size: 6.8pt, it.subject.replace("_", "_\u{200B}"))
      [. ]
      it.text.replace(regex("\s+"), " ").replace("_", "_\u{200B}")
      if it.cite != "" { text(fill: ink.lighten(30%), [ (#it.cite)]) }
    }))
  }
}
]

#section("Glossary", balance: true)[
#let g(t, d) = block(above: 0.55em, below: 0.55em)[#text(weight: "bold", t). #d]
#g[ACK][The reply that means "done": 06H in the reply's command byte.]
#g[Channel][One of the eight network connections the FujiNet keeps, devices 71H to 78H.]
#g[Checksum][An 8-bit sum with end-around carry over a packet, in byte 4 of its header.]
#g[Descriptor][Byte 5 of a packet's header: how many fields follow, and their size.]
#g[Device][Something the FujiNet makes look like a peripheral: itself (70H), a disk drive, a
  network channel, the clock, the printer, the modem.]
#g[Devicespec][The text that tells a network channel what to open: `N:HTTP://host/path`.]
#g[END][C0H: the byte that starts and ends a SLIP frame.]
#g[ESC][In SLIP, DBH, which begins an escape pair. (On the H19, 1BH, which begins an escape
  sequence.)]
#g[Field][A small number sent in a request's header: a slot, a length, a mode.]
#g[fujinet-lib][The FujiNet project's C library, one function per command.]
#g[fujinet-pc][The FujiNet firmware built to run on a personal computer.]
#g[FujiBus][The FujiNet's request-and-reply protocol over a byte stream (Chapter 3).]
#g[Host slot][One of eight places the FujiNet keeps the name of a server of disk images.]
#g[JSON Pointer][A path through a JSON document, such as `/people/0/name` (RFC 6901).]
#g[NAK][The reply that means "refused": 15H.]
#g[Payload][The data that follows a request's fields.]
#g[Request block][In the book's library, the two lines (FNREQ, FNBUF) that describe one request.]
#g[SLIP][Serial Line Internet Protocol: the framing FujiBus uses.]
#g[Split octal][Heath's way of writing a 16-bit address: each byte in octal, as 042.200.]
#g[TNFS][The Tiny Network File System, made for 8-bit computers.]
#g[Translation][Changing line endings between the network's and the computer's (Chapter 10).]
]
