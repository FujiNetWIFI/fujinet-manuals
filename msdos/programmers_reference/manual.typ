// ============================================================
// FUJINET INT F5 — TECHNICAL REFERENCE  (MS-DOS)
//
// Designed after the 1984 IBM Personal Computer "Technical
// Reference" (P/N 6361453): the deep-indigo cover with the
// striped masthead and "Hardware Reference Library" slug,
// Press Roman (Times) body, bold serif heads, register
// diagrams, dense monospace listings, section-relative folios.
//
// All facts verified against the canonical sources:
//   fujinet-msdos/sys      (intf5.c, fujicom.c, fuji_f5.h)
//   fujinet-firmware       (lib/device/rs232/*, FUJICMD_*/NETCMD_*)
//   fujinet-lib/msdos      (the C bindings that call INT F5)
//
// Build: typst compile --font-path fonts manual.typ
// ============================================================

// ---------- fonts -------------------------------------------
#let f-body = "Nimbus Roman"            // Press Roman / Times equivalent
#let f-mono = "Px437 IBM VGA 8x16"      // genuine PC ROM font (listings)

// ---------- palette -----------------------------------------
#let ink    = rgb("#1b1a18")
#let paper  = rgb("#ffffff")
#let navy   = rgb("#2b2c64")            // the cover stock (indigo)
#let navy-d = rgb("#1e1f49")
#let rule-c = rgb("#222025")
#let tab-bg = rgb("#181614")
#let reg-bg = rgb("#eceaf3")            // register-diagram tint
#let lst-bg = rgb("#f4f2ec")

// ---------- helpers -----------------------------------------
#let rp(s, n) = range(n).map(_ => s).join("")
#let sp(n) = rp(" ", n)
#let kw(s) = text(font: f-mono, size: 0.92em, fill: ink, s)
#let hx(s) = text(font: f-mono, size: 0.92em, fill: ink, s)

#let chmark(title, num, subs) = metadata((
  kind: "chapter", title: title, num: num, subs: subs))
#let ix(..terms) = terms.pos().map(t => metadata((kind: "ix", term: t))).join()

// ---------- section-relative folio --------------------------
#let sec-state = state("sec", (name: "", num: 0))
#let sec-page = counter("secpage")
#let show-folio = state("folio", false)

#let foot = context {
  if not show-folio.get() { return }
  let s = sec-state.get()
  if s.name == "" { return }
  let cur = counter(page).get().first()
  let p = cur - s.at("start", default: cur) + 1
  set text(font: f-body, size: 9pt, fill: ink)
  align(right)[#strong(s.name)#h(6pt)#s.num\-#p]
}

#let regmarks = context {
  if not show-folio.get() { return }
  let arc = curve(stroke: 0.5pt + rgb("#b6b3c4"), fill: none,
    curve.move((0pt, 0pt)),
    curve.cubic((3pt, 3pt), (3pt, 11pt), (0pt, 14pt)))
  place(top + right, dx: 0.16in, dy: 1.1in, arc)
  place(bottom + right, dx: 0.16in, dy: -1.1in, arc)
}

// ---------- striped masthead (IBM 8-bar homage) -------------
#let striped(body, stripe: navy, n: 7) = box(clip: true, {
  body
  context {
    let m = measure(body)
    let gap = m.height / n
    for i in range(1, n) {
      place(top + left, dy: gap * i - 0.6pt,
        line(length: m.width, stroke: 1.1pt + stripe))
    }
  }
})

// ---------- bleeder tab -------------------------------------
#let bleeder(label, slot: 0) = place(top + right, dx: 0.62in,
  dy: 0.9in + slot * 0.92in,
  rotate(90deg, origin: center, reflow: false,
    box(fill: tab-bg, inset: (x: 9pt, y: 4pt),
      text(font: f-body, weight: 700, size: 8.5pt, fill: white,
        tracking: 0.4pt, upper(label)))))

// ---------- chapter opener ----------------------------------
#let chapter(title, num: 0, subs: (), tab: none) = {
  pagebreak(weak: true)
  context {
    sec-state.update((name: title, num: num, start: counter(page).get().first()))
  }
  chmark(title, num, subs)
  if tab != none { bleeder(tab) }
  v(0.15in)
  text(font: f-body, weight: 700, size: 16pt, fill: ink,
    [SECTION #num.#h(6pt)#upper(title)])
  v(2pt)
  line(length: 100%, stroke: 1.6pt + rule-c)
  v(0.3in)
}

#let sect(title) = block(above: 1.4em, below: 0.7em, breakable: false,
  sticky: true,
  text(font: f-body, weight: 700, size: 13pt, fill: ink, title))
#let subsect(title) = block(above: 1.1em, below: 0.5em, breakable: false,
  sticky: true,
  text(font: f-body, weight: 700, size: 11pt, fill: ink, title))

#let bl(body) = block(above: 0.4em, below: 0.4em,
  grid(columns: (0.26in, 1fr),
    align(left + top, move(dy: 3.2pt, box(width: 4.5pt, height: 4.5pt, fill: ink))),
    par(leading: 0.56em, justify: true, body)))

#let note(body) = block(above: 0.9em, below: 0.9em, breakable: false,
  grid(columns: (auto, 1fr), column-gutter: 5pt,
    text(weight: 700)[Note:],
    par(leading: 0.56em, justify: true, body)))
#let caution(body, word: "Warning") = block(above: 0.9em, below: 0.9em,
  breakable: false, par(leading: 0.56em, justify: true,
    text(weight: 700, [#underline(word):]) + " " + body))

#let figcap(body) = block(above: 0.5em, below: 1.0em,
  align(center, text(font: f-body, style: "italic", size: 9.5pt, body)))

// ---------- listings ----------------------------------------
// markup listing (no //, no -- inside)
#let listing(body) = block(above: 0.9em, below: 0.9em, breakable: false,
  width: 100%, fill: lst-bg, inset: 9pt, stroke: 0.5pt + rgb("#cfcabf"),
  text(font: f-mono, size: 8.3pt, fill: ink, body))
// string listing (safe for // and -- and ; comments)
#let lst(..lines) = block(above: 0.9em, below: 0.9em, breakable: false,
  width: 100%, fill: lst-bg, inset: 9pt, stroke: 0.5pt + rgb("#cfcabf"),
  text(font: f-mono, size: 8.3pt, fill: ink,
    lines.pos().map(l => l).join(linebreak())))
// breakable variant for long program listings (may span a page break)
#let lstb(..lines) = block(above: 0.9em, below: 0.9em, breakable: true,
  width: 100%, fill: lst-bg, inset: 9pt, stroke: 0.5pt + rgb("#cfcabf"),
  text(font: f-mono, size: 8.3pt, fill: ink,
    lines.pos().map(l => l).join(linebreak())))

// ---------- register diagram --------------------------------
// a row of 16 bit-cells split into two bytes (hi/lo) with a label
#let regbox(name, hi, lo) = grid(columns: (0.5in, 1fr, 1fr),
  column-gutter: 0pt, row-gutter: 0pt,
  align(right + horizon, box(inset: (right: 6pt),
    text(font: f-mono, size: 9pt, weight: 700, name))),
  box(fill: reg-bg, stroke: 0.6pt + rule-c, inset: 4pt,
    align(center, text(font: f-body, size: 8.5pt, hi))),
  box(fill: reg-bg, stroke: 0.6pt + rule-c, inset: 4pt,
    align(center, text(font: f-body, size: 8.5pt, lo))))
#let regsingle(name, body) = grid(columns: (0.5in, 1fr),
  column-gutter: 0pt,
  align(right + horizon, box(inset: (right: 6pt),
    text(font: f-mono, size: 9pt, weight: 700, name))),
  box(fill: reg-bg, stroke: 0.6pt + rule-c, inset: 4pt,
    align(center, text(font: f-body, size: 8.5pt, body))))

// ---------- a command-reference entry -----------------------
// header block: NAME, summary, device, command byte; then a
// parameter table; then description + example (passed as body).
#let cmd(name, summary, dev: "", code: "", dir: "", field: "—",
         aux: "—", payload: "—", returns: "", body) = block(
  breakable: true, above: 1.6em, below: 0.8em, {
  // header (rule + title + parameter box) stays together and sticks
  // to the body that follows, so it can never orphan at a page foot.
  block(breakable: false, sticky: true, {
    line(length: 100%, stroke: 0.8pt + rule-c)
    v(3pt)
    grid(columns: (1fr, auto), column-gutter: 8pt,
      text(font: f-body, weight: 700, size: 12pt,
        [#kw(name) — #summary]),
      text(font: f-mono, size: 9pt)[Dev #dev#h(8pt)Cmd #code])
    v(4pt)
    block(width: 100%, fill: reg-bg, inset: 6pt, {
      set text(size: 8.8pt)
      grid(columns: (auto, 1fr), row-gutter: 2.5pt, column-gutter: 8pt,
        text(weight: 700)[Direction], dir,
        text(weight: 700)[Field (DH)], field,
        text(weight: 700)[AUX], aux,
        text(weight: 700)[Payload], payload,
        text(weight: 700)[Returns], returns,
      )
    })
  })
  v(5pt)
  body
})

// ============================================================
// DOCUMENT SETUP
// ============================================================
#set document(title: "FujiNet INT F5 — Technical Reference",
  author: "The FujiNet Community")
#set text(font: f-body, size: 10.5pt, fill: ink, hyphenate: true)
#set par(leading: 0.62em, spacing: 0.7em, justify: true, first-line-indent: 0pt)
#set strong(delta: 300)
// straight quotes throughout: the ROM font has no curly quotes, and a
// code-heavy reference reads better with plain ' and " anyway.
#set smartquote(enabled: false)
#set page(width: 7.0in, height: 9.0in, fill: paper,
  margin: (left: 0.95in, right: 1.05in, top: 0.7in, bottom: 0.8in),
  footer: foot, background: regmarks)
#set enum(numbering: "1.", indent: 0pt, body-indent: 8pt, spacing: 0.7em)

// ============================================================
// FRONT COVER
// ============================================================
#page(margin: 0pt, footer: none, background: none)[
  #rect(width: 100%, height: 100%, fill: navy)
  #for dy in (1.6in, 4.5in, 7.4in) {
    place(left + top, dx: 0.42in, dy: dy, circle(radius: 0.12in, fill: paper))
  }
  #place(top + left, dx: 1.15in, dy: 0.7in,
    striped(text(font: f-body, weight: 700, size: 30pt, fill: paper)[FujiNet],
      stripe: navy, n: 7))
  #place(top + right, dx: -0.7in, dy: 0.78in,
    text(font: f-body, style: "italic", size: 12pt, fill: paper)[
      Personal Computer\
      Hardware Reference\
      Library])

  #place(top + left, dx: 1.15in, dy: 3.9in,
    line(length: 4.6in, stroke: 0.8pt + paper))
  #place(top + left, dx: 1.15in, dy: 4.15in,
    text(font: f-body, weight: 700, size: 40pt, fill: paper)[Technical\ Reference])

  #place(top + left, dx: 1.15in, dy: 5.95in,
    text(font: f-body, style: "italic", size: 13pt, fill: paper)[
      The INT F5 Programming Interface])

  #place(bottom + right, dx: -0.7in, dy: -1.15in,
    image("images/fujinet-rs232-hero.png", width: 2.9in))

  #place(bottom + left, dx: 1.15in, dy: -0.7in,
    text(font: f-mono, size: 10pt, fill: paper)[FN-RS232-TR-001])
]

// ============================================================
// EDITION / ABOUT
// ============================================================
#page(footer: none)[
  #v(1fr)
  #set text(size: 9.5pt)
  #set par(justify: true, leading: 0.6em)
  #strong[First Edition (2026)]
  #v(6pt)
  This publication describes the #strong[INT F5] programming interface of
  the RS-232 FujiNet under MS-DOS: the software interrupt installed by the
  FujiNet device driver through which any program may command any FujiNet
  device, with or without a data payload, in either direction.
  #v(6pt)
  It is written for assembly-language and C programmers, and for anyone who
  wishes to understand what the FujiNet C library
  (#kw("fujinet-lib")) ultimately calls. Every register, command, and
  return code is reproduced from the canonical sources — the FujiNet device
  driver, the FujiNet firmware, and the C bindings — so that what is printed
  here matches the machine exactly.
  #v(6pt)
  FujiNet is free and open. The driver, the firmware, the C library, and
  this manual are released under free-software and open-hardware licenses.
  Sources for everything live at #kw("github.com/FujiNetWIFI") .
  #v(10pt)
  #align(center, text(size: 9pt)[© 2026 The FujiNet Community · Copy freely])
  #v(4pt)
  #set par(justify: true, leading: 0.55em)
  #text(size: 8.5pt)[The FujiNet project is a community of enthusiasts and is
  not affiliated with, endorsed by, or sponsored by International Business
  Machines Corporation. The visual styling of this manual is an affectionate
  tribute to the IBM Personal Computer #emph[Technical Reference.]]
  #v(0.4in)
]

// ============================================================
// PREFACE
// ============================================================
#show-folio.update(true)
#context { sec-state.update((name: "Preface", num: 0, start: counter(page).get().first())) }

#v(0.1in)
#text(font: f-body, weight: 700, size: 16pt)[Preface]
#v(2pt)
#line(length: 100%, stroke: 1.6pt + rule-c)
#v(0.25in)

The FujiNet PC interface reserves software interrupt #kw("F5h") to provide a
single, uniform way to talk to the FujiNet — no matter how it is physically
attached. Through one interrupt you can send #emph[any] command the FujiNet
understands, to #emph[any] of its virtual devices, carrying a payload to the
FujiNet, from the FujiNet, or neither.

#v(0.1in)
This reference has six sections:

#bl[#strong[Section 1. Introduction] describes the FujiNet device model and
how INT F5 fits between your program, the device driver, and the FujiNet
hardware.]
#bl[#strong[Section 2. The Calling Convention] documents the registers, the
field descriptor, the return codes, and the wire protocol the driver speaks
on your behalf.]
#bl[#strong[Section 3. The Devices] lists the device IDs and what each one
is for.]
#bl[#strong[Section 4. Command Reference] documents every command — its
direction, parameters, payload, and return — device by device, with an
example for each group.]
#bl[#strong[Section 5. A Worked Example] builds a complete network utility,
#kw("NETCAT"), in assembly language and again in C.]
#bl[#strong[Section 6. A Second Example] reads a Mastodon timeline through
the FujiNet's JSON engine, in assembly, C, and Pascal side by side.]
#bl[#strong[Section 7. Inside FUJINET.SYS] is a guided tour of the block
device driver — the program that installs INT F5 and presents the FujiNet's
disks as DOS drive letters — with source listings.]
#bl[#strong[Section 8. Inside FUJIPRN.SYS] does the same for the printer
driver, including its INT 17h hook and idle-time auto-flush.]
#bl[#strong[Section 9. Appendices] gather the error codes, the status
request types, the field-descriptor table, the wire-frame layout, and a
one-line summary of every command.]

#v(0.1in)
#note[Throughout this reference, register and command values are given in
hexadecimal with a trailing #kw("h") (for example #kw("70h")) or with a
leading #kw("0x") in C and assembler listings, as the source uses both.]

// ============================================================
// CONTENTS
// ============================================================
#pagebreak(weak: true)
#show-folio.update(false)
#v(0.15in)
#align(center, text(font: f-body, weight: 700, size: 20pt)[Contents])
#v(0.3in)
#context {
  let marks = query(metadata).filter(m =>
    type(m.value) == dictionary and m.value.at("kind", default: "") == "chapter")
  for m in marks {
    block(above: 0.9em, below: 0.2em, {
      text(font: f-body, weight: 700, size: 11pt,
        [Section #m.value.num.#h(5pt)#m.value.title])
      box(width: 1fr, inset: (bottom: 1.5pt),
        align(bottom, repeat(text(size: 9pt)[.#h(3pt)])))
      text(font: f-body, weight: 700, size: 11pt, [#m.value.num\-1])
    })
    if m.value.subs.len() > 0 {
      block(above: 0pt, below: 0.3em, inset: (left: 0.3in, right: 0.4in),
        par(leading: 0.6em, justify: false,
          text(size: 9.5pt, m.value.subs.join(text(fill: rule-c)[ · ]))))
    }
  }
}
#show-folio.update(true)

// ============================================================
// SECTION 1 — INTRODUCTION
// ============================================================
#chapter("Introduction", num: 1, tab: "Intro",
  subs: ("The Device Model", "The Software Layers", "Relation to fujinet-lib"))
#ix("INT F5", "Device model")

The FujiNet presents itself to the Personal Computer not as one device but as
a small bus of #emph[virtual devices]: eight disk drives, eight network
adapters, a real-time clock, a printer, and a control device that manages
them all. The FujiNet device driver — #kw("FUJINET.SYS"), loaded from
#kw("CONFIG.SYS") — installs a single software interrupt, #kw("INT F5h"),
that reaches every one of them.

A program issues a command by loading a handful of registers and executing
#kw("INT F5h"). The driver packages the command, sends it to the FujiNet
across the serial cable, waits for the reply, copies any returned data into
your buffer, and hands control back with a one-character result in
#kw("AL"). The program need not know anything about serial ports, baud
rates, framing, or checksums; the driver does all of it.

#sect[The Device Model]
#ix("Virtual devices")

Every FujiNet command is addressed to a #strong[device] (a one-byte ID in
#kw("AL")) and names a #strong[command] (a one-byte code in #kw("AH")).
The same command byte may mean different things to different devices —
#kw("'R'") is "read a sector" to a disk and "read bytes" to a network
adapter — so the device ID always travels with it. Section 3 lists the
devices; Section 4 documents their commands.

#sect[The Software Layers]
#ix("FUJICOM", "SLIP")

Four layers sit between your program and the network:

#bl[#strong[Your program] loads registers and calls #kw("INT F5h").]
#bl[#strong[The INT F5 handler] in #kw("FUJINET.SYS") translates the
registers into a FujiNet bus command.]
#bl[#strong[The FUJICOM layer] frames that command as a packet, wraps it in
SLIP, and exchanges it with the FujiNet over the serial port (Section 2,
#emph[The Wire Protocol]).]
#bl[#strong[The FujiNet] carries out the command — touching a disk image, a
network socket, the clock — and replies.]

You work entirely at the top layer. Everything below #kw("INT F5h") is the
driver's concern, and is described here only so you understand what your
calls set in motion.

#sect[Relation to fujinet-lib]
#ix("fujinet-lib")

The FujiNet C library, #kw("fujinet-lib"), provides comfortable C functions
— #kw("network_open"), #kw("fuji_mount_image"), and the rest. On MS-DOS,
every one of those functions ultimately reduces to an #kw("INT F5h") call
through one of three thin wrappers: #kw("int_f5"), #kw("int_f5_read"), and
#kw("int_f5_write") (Section 2). This reference documents that floor — the
exact interface the library stands on — so you may call it directly from
assembler or C, or understand precisely what the library does on your
behalf.

// ============================================================
// SECTION 2 — THE CALLING CONVENTION
// ============================================================
#chapter("The Calling Convention", num: 2, tab: "Calling",
  subs: ("Registers", "Payload Direction", "The Field Descriptor",
         "Return Codes", "The C Wrappers", "The Wire Protocol"))
#ix("Registers", "Calling convention")

To issue a command, load the registers below and execute #kw("INT F5h"). On
return, #kw("AL") holds the result.

#sect[Registers]

#block(breakable: false, {
  set text(size: 9pt)
  v(2pt)
  regbox("DX", [DH — field descriptor], [DL — payload direction])
  v(3pt)
  regbox("AX", [AH — command], [AL — device ID])
  v(3pt)
  regbox("CX", [CH — AUX2], [CL — AUX1])
  v(3pt)
  regsingle("SI", [AUX3 (low byte) : AUX4 (high byte)])
  v(3pt)
  regsingle("ES:BX", [segment : offset of the payload buffer])
  v(3pt)
  regsingle("DI", [length of the payload buffer, in bytes])
})

#v(6pt)
#block(breakable: false, table(columns: (auto, 1fr),
  align: (left, left), stroke: 0.6pt + rule-c, inset: 6pt,
  table.header(text(weight: 700)[Register], text(weight: 700)[Holds]),
  kw("DL"), [Payload direction: #kw("00h") none, #kw("40h") read, #kw("80h") write],
  kw("DH"), [Field descriptor: how many AUX bytes to send (see below)],
  kw("AL"), [Device ID (Section 3)],
  kw("AH"), [Command code (Section 4)],
  kw("CL"), [AUX1 — first command parameter],
  kw("CH"), [AUX2 — second command parameter],
  kw("SI"), [AUX3 and AUX4 — third and fourth parameters (low : high)],
  kw("ES:BX"), [Far pointer to the payload buffer (read or write)],
  kw("DI"), [Length of the payload buffer, in bytes],
))

#note[#kw("ES:BX") and #kw("DI") are used only when #kw("DL") is #kw("40h")
or #kw("80h"). For a no-payload command (#kw("DL")=#kw("00h")) they are
ignored.]

#sect[Payload Direction]
#ix("Payload direction")

Register #kw("DL") selects one of three forms:

#block(breakable: false, table(columns: (auto, auto, 1fr),
  align: (left, left, left), stroke: 0.6pt + rule-c, inset: 6pt,
  table.header(text(weight: 700)[DL], text(weight: 700)[Form],
    text(weight: 700)[Meaning]),
  kw("00h"), [None], [Send the command alone; no data moves.],
  kw("40h"), [Read], [The FujiNet returns data into #kw("ES:BX"), #kw("DI") bytes.],
  kw("80h"), [Write], [Your data at #kw("ES:BX"), #kw("DI") bytes, goes to the FujiNet.],
))

#sect[The Field Descriptor]
#ix("Field descriptor", "AUX bytes")

A command's AUX bytes only travel to the FujiNet if the #strong[field
descriptor] in #kw("DH") says how many to send. Set #kw("DH") to match the
parameters the command expects:

#block(breakable: false, table(columns: (auto, auto, auto, 1fr),
  align: (left, center, center, left), stroke: 0.6pt + rule-c, inset: 5.5pt,
  table.header(text(weight: 700)[Name], text(weight: 700)[DH],
    text(weight: 700)[Bytes], text(weight: 700)[Sends]),
  kw("FUJI_FIELD_NONE"), kw("00h"), [0], [no AUX],
  kw("FUJI_FIELD_A1"), kw("01h"), [1], [AUX1],
  kw("FUJI_FIELD_A1_A2"), kw("02h"), [2], [AUX1, AUX2],
  kw("FUJI_FIELD_A1_A2_A3"), kw("03h"), [3], [AUX1, AUX2, AUX3],
  kw("FUJI_FIELD_A1_A2_A3_A4"), kw("04h"), [4], [AUX1–AUX4],
  kw("FUJI_FIELD_B12"), kw("05h"), [2], [AUX1, AUX2 (16-bit field)],
  kw("FUJI_FIELD_B12_B34"), kw("06h"), [4], [two 16-bit fields],
  kw("FUJI_FIELD_C1234"), kw("07h"), [4], [AUX1–AUX4 as one 32-bit field],
))

The AUX bytes are placed into the command frame in order — AUX1, then AUX2,
and so on — up to the count the descriptor names. A command that takes a
16-bit length passes it as AUX1 (low) and AUX2 (high) with
#kw("FUJI_FIELD_A1_A2"); a disk sector number is a 32-bit value passed in
AUX1–AUX4 with #kw("FUJI_FIELD_C1234").

#caution[A command whose AUX bytes you set in #kw("CL")/#kw("CH") but whose
field descriptor in #kw("DH") is left at #kw("00h") will reach the FujiNet
with #emph[no] parameters, and will usually be rejected. Always set
#kw("DH") to match the command.]

#sect[Return Codes]
#ix("Return codes")

On return, #kw("AL") holds a single character:

#block(breakable: false, table(columns: (auto, auto, 1fr),
  align: (center, left, left), stroke: 0.6pt + rule-c, inset: 6pt,
  table.header(text(weight: 700)[AL], text(weight: 700)[Name],
    text(weight: 700)[Meaning]),
  kw("'C'"), [Complete], [The command finished without error.],
  kw("'E'"), [Error], [The command finished, but a problem occurred.],
  kw("'N'"), [NAK], [The device did not recognize the command.],
))

For read commands, a result of #kw("'C'") means your buffer now holds the
returned data. For many network commands the #emph[meaning] of an error is
found by a following STATUS call, whose fourth byte is a detailed error code
(Appendix A).

#sect[The C Wrappers]
#ix("int_f5", "C wrappers")

The FujiNet C library exposes the interface as three functions — one per
direction. They are the whole of the library's floor; everything else is
built on them.

#listing[unsigned char int_f5      (unsigned char dev, unsigned char cmd,
                          unsigned char aux1, unsigned char aux2);
unsigned char int_f5_read (unsigned char dev, unsigned char cmd,
                          unsigned char aux1, unsigned char aux2,
                          void *buf, unsigned short len);
unsigned char int_f5_write(unsigned char dev, unsigned char cmd,
                          unsigned char aux1, unsigned char aux2,
                          void *buf, unsigned short len);]

Each loads #kw("DL") with the direction, #kw("AL") with #kw("dev"),
#kw("AH") with #kw("cmd"), #kw("CL")/#kw("CH") with the AUX bytes, and (for
read and write) #kw("ES:BX")/#kw("DI") with the buffer, then executes
#kw("INT F5h") and returns #kw("AL"). They set #kw("DH") and #kw("SI") to
zero; when a command needs AUX bytes or AUX3/AUX4, set #kw("DH") (and
#kw("SI")) yourself, as the assembler examples in Section 4 show.

The simplest possible call — reset the FujiNet — needs no payload and no
parameters:

#lst(
  "        MOV  DL,00h        ; direction: none",
  "        MOV  DH,00h        ; field descriptor: none",
  "        MOV  AL,70h        ; device: FujiNet control",
  "        MOV  AH,0FFh       ; command: RESET",
  "        INT  0F5h          ; AL = 'C' on success",
)

#sect[The Wire Protocol]
#ix("FujiBus frame", "Checksum", "SLIP")

You do not need this section to use INT F5, but it explains what the driver
builds. Each command becomes a #strong[FujiBus packet]: a five-byte header
(device, command, 16-bit length, 8-bit checksum, field descriptor),
followed by the AUX bytes the descriptor names, followed by any payload. The
packet is wrapped in #strong[SLIP] framing — bracketed by #kw("C0h") end
markers, with #kw("C0h") and #kw("DB h") escaped — and sent over the serial
line. The FujiNet replies with a header whose command byte is #kw("ACK")
(#kw("06h")) on success, followed by any requested data. The driver verifies
the checksum and the device, then reports #kw("'C'") or #kw("'E'").

// ============================================================
// SECTION 3 — THE DEVICES
// ============================================================
#chapter("The Devices", num: 3, tab: "Devices",
  subs: ("Device ID Map", "Device Classes"))
#ix("Device IDs")

Register #kw("AL") names the destination device. The FujiNet recognizes the
following IDs:

#block(breakable: false, table(columns: (auto, 1fr),
  align: (left, left), stroke: 0.6pt + rule-c, inset: 6pt,
  table.header(text(weight: 700)[AL], text(weight: 700)[Device]),
  kw("31h - 38h"), [Disk drives 1 through 8 (block devices)],
  kw("40h - 43h"), [Printer (driven by #kw("FUJIPRN.SYS"); see note)],
  kw("45h"), [Real-time clock (NTP)],
  kw("70h"), [FujiNet control device],
  kw("71h - 78h"), [Network adapters 1 through 8 (character devices)],
))

#note[The printer device (#kw("40h")) is served by the printer driver,
#kw("FUJIPRN.SYS"), which hooks #kw("INT 17h"); printing is done with
ordinary DOS printer output rather than through INT F5, and is not covered
here. Devices for serial, CP/M, MIDI, and voice exist in the firmware but
are not used by the MS-DOS driver.]

#sect[Device Classes]

#bl[#strong[Disk drives (31h-38h)] are block devices. They read and write
512-byte sectors of the disk image mounted in their slot. The MS-DOS driver
exposes these to DOS as drive letters; you may also reach them directly
(Section 4.3).]
#bl[#strong[The clock (45h)] returns the current date and time, kept by the
FujiNet from the internet (Section 4.4).]
#bl[#strong[The control device (70h)] manages the FujiNet itself: WiFi,
hosts, disk slots, directories, the adapter configuration, and more. It is
the largest command set (Section 4.1).]
#bl[#strong[Network adapters (71h-78h)] are character devices. Each is an
independent connection — to a web server, a TCP socket, a file — opened with
a URL and read or written as a stream (Section 4.2).]

// ============================================================
// SECTION 4 — COMMAND REFERENCE
// ============================================================
#chapter("Command Reference", num: 4, tab: "Commands",
  subs: ("The Control Device", "Network Adapters", "Disk Drives", "The Clock"))

This section documents the commands of each device. Every entry names the
command's direction, its field descriptor, the meaning of its AUX bytes and
payload, and what it returns, followed by a short description. An example
accompanies each group.

#sect[4.1  The Control Device (70h)]
#ix("Control device", "FujiNet device")

The control device manages the FujiNet. Its commands fall into groups:
wireless networking, host and disk-slot management, directory browsing,
adapter information, and housekeeping. The most-used commands are detailed
below; every command is summarized in the table at the end of this section.

#cmd("RESET", "Restart the FujiNet", dev: "70h", code: "FFh",
  dir: "None", field: kw("NONE"), aux: "—", payload: "—",
  returns: kw("'C'"))[
Restarts the FujiNet's firmware. The serial link is re-established
automatically. Equivalent to pressing the Reset button on the adapter.
#lst(
  "        MOV  DL,00h        ; none",
  "        MOV  AX,0FF70h     ; AH=FFh RESET, AL=70h FujiNet",
  "        INT  0F5h",
)]

#cmd("GET ADAPTER CONFIG", "Read network configuration", dev: "70h",
  code: "E8h", dir: "Read", field: kw("NONE"), aux: "—",
  payload: [139-byte #kw("AdapterConfig") in], returns: kw("'C'"))[
Returns the FujiNet's current network details — SSID, host name, IP address,
gateway, netmask, DNS, MAC, BSSID, and firmware version — as one packed
structure.
#listing[typedef struct {
    char  ssid[33];       unsigned char gateway[4];
    char  hostname[64];   unsigned char netmask[4];
    unsigned char localIP[4];  unsigned char dnsIP[4];
    unsigned char macAddress[6];
    unsigned char bssid[6];    char fn_version[15];
} AdapterConfig;

AdapterConfig ac;
int_f5_read(0x70, 0xE8, 0, 0, &ac, sizeof(ac));]]

#cmd("SCAN NETWORKS", "Begin a WiFi scan", dev: "70h", code: "FDh",
  dir: "Read", field: kw("NONE"), aux: "—",
  payload: [1 byte: network count, in], returns: kw("'C'"))[
Scans for wireless networks and returns the number found. Follow with GET
SCAN RESULT once per network to read each name and signal strength.
#lst("unsigned char count;",
     "int_f5_read(0x70, 0xFD, 0, 0, &count, 1);")]

#cmd("GET SCAN RESULT", "Read one scanned network", dev: "70h", code: "FCh",
  dir: "Read", field: kw("A1"), aux: [AUX1 = network index],
  payload: [#kw("SSIDInfo") in], returns: kw("'C'"))[
Returns the name and signal strength of the network at the given index
(0-based, up to the count from SCAN NETWORKS). Because this command takes a
parameter, set the field descriptor in #kw("DH").
#lst(
  "        MOV  DL,40h        ; read",
  "        MOV  DH,01h        ; FUJI_FIELD_A1",
  "        MOV  AX,0FC70h     ; AH=FCh, AL=70h",
  "        MOV  CL,[index]    ; AUX1 = which network",
  "        LES  BX,[ssidinfo] ; ES:BX -> buffer",
  "        MOV  DI,34         ; sizeof SSIDInfo",
  "        INT  0F5h",
)]

#cmd("SET SSID", "Join a wireless network", dev: "70h", code: "FBh",
  dir: "Write", field: kw("NONE"),
  aux: "—", payload: [#kw("ssid[32]")+#kw("password[64]") out],
  returns: kw("'C'"))[
Sends a network name and password; the FujiNet joins that network and
remembers it. The payload is two fixed fields.
#listing[struct { char ssid[33]; char password[64]; } s;
strcpy(s.ssid, "HOMEBASE");
strcpy(s.password, "secret");
int_f5_write(0x70, 0xFB, 0, 0, &s, sizeof(s));]]

#cmd("GET WIFI STATUS", "Read the WiFi link state", dev: "70h", code: "FAh",
  dir: "Read", field: kw("NONE"), aux: "—",
  payload: [1 byte: status, in], returns: kw("'C'"))[
Returns a single byte: #kw("3") means connected; other values mean the link
is down or connecting.
#lst("unsigned char wifi;",
     "int_f5_read(0x70, 0xFA, 0, 0, &wifi, 1);")]

#cmd("MOUNT HOST", "Open a host slot", dev: "70h", code: "F9h",
  dir: "None", field: kw("A1"), aux: [AUX1 = host slot (0–7)],
  payload: "—", returns: kw("'C'"))[
Connects the FujiNet to the file server named in the given host slot, so its
disk images can be mounted. Set #kw("DH")=#kw("01h").
#lst(
  "        MOV  DX,0100h      ; DH=01 (A1), DL=00 (none)",
  "        MOV  AX,0F970h     ; AH=F9h, AL=70h",
  "        MOV  CL,01h        ; AUX1 = host slot 1",
  "        INT  0F5h",
)]

#cmd("MOUNT IMAGE", "Mount a disk image into a drive", dev: "70h",
  code: "F8h", dir: "None", field: kw("A1_A2"),
  aux: [AUX1 = device slot (0–7), AUX2 = mode (1=R/O, 2=R/W)],
  payload: "—", returns: kw("'C'"))[
Mounts the disk image previously selected for the given device slot,
read-only or read/write. The image and host are chosen with SET DEVICE
FULL PATH or by the slot table. Set #kw("DH")=#kw("02h").
#lst(
  "        MOV  DX,0200h      ; DH=02 (A1_A2), DL=00",
  "        MOV  AX,0F870h     ; AH=F8h, AL=70h",
  "        MOV  CL,00h        ; AUX1 = device slot 0",
  "        MOV  CH,01h        ; AUX2 = read-only",
  "        INT  0F5h",
)]

#cmd("UNMOUNT IMAGE", "Eject a disk image", dev: "70h", code: "E9h",
  dir: "None", field: kw("A1"), aux: [AUX1 = device slot (0–7)],
  payload: "—", returns: kw("'C'"))[
Ejects whatever image is mounted in the given device slot.]

#cmd("READ DEVICE SLOTS", "Read the disk-slot table", dev: "70h",
  code: "F2h", dir: "Read", field: kw("NONE"), aux: "—",
  payload: [8 × #kw("DeviceSlot") in], returns: kw("'C'"))[
Returns the table of eight device (drive) slots: for each, the host it came
from, its mode, and the image's file name.
#listing[typedef struct {
    unsigned char hostSlot;
    unsigned char mode;          /* 1 = R/O, 2 = R/W */
    char          file[36];
} DeviceSlot;

DeviceSlot slots[8];
int_f5_read(0x70, 0xF2, 0, 0, slots, sizeof(slots));]]

#cmd("READ HOST SLOTS", "Read the host-slot table", dev: "70h", code: "F4h",
  dir: "Read", field: kw("NONE"), aux: "—",
  payload: [8 × 32-byte names in], returns: kw("'C'"))[
Returns the eight host-slot names (32 bytes each), the file servers and the
#kw("SD") card the FujiNet knows about.
#lst("char hosts[8][32];",
     "int_f5_read(0x70, 0xF4, 0, 0, hosts, sizeof(hosts));")]

#cmd("WRITE HOST SLOTS", "Write the host-slot table", dev: "70h", code: "F3h",
  dir: "Write", field: kw("NONE"), aux: "—",
  payload: [8 × 32-byte names out], returns: kw("'C'"))[
Replaces all eight host-slot names. Read them first, change what you need,
and write them back.]

#cmd("WRITE DEVICE SLOTS", "Write the disk-slot table", dev: "70h",
  code: "F1h", dir: "Write", field: kw("NONE"), aux: "—",
  payload: [8 × #kw("DeviceSlot") out], returns: kw("'C'"))[
Replaces the device-slot table. Used to assign images to slots before
mounting.]

#cmd("MOUNT ALL", "Mount every selected slot", dev: "70h", code: "D7h",
  dir: "None", field: kw("NONE"), aux: "—", payload: "—",
  returns: kw("'C'"))[
Mounts every device slot that has an image selected — the operation CONFIG
performs as it exits. After this, the disks are live at their drive letters.]

#cmd("OPEN DIRECTORY", "Begin reading a host's directory", dev: "70h",
  code: "F7h", dir: "Write", field: kw("A1"),
  aux: [AUX1 = host slot (0–7)], payload: [path string out],
  returns: kw("'C'"))[
Opens a directory on a mounted host for reading. The payload is the path to
open (for example #kw("/MSDOS/")). Follow with READ DIR ENTRY.]

#cmd("READ DIR ENTRY", "Read one directory entry", dev: "70h", code: "F6h",
  dir: "Read", field: kw("A1_A2"),
  aux: [AUX1 = max length, AUX2 = options], payload: [entry string in],
  returns: kw("'C'"))[
Returns the next directory entry as a string of at most AUX1 bytes. A name
ending in #kw("/") is a folder. An entry of #kw("7Fh") at the first byte
marks the end of the directory.]

#cmd("CLOSE DIRECTORY", "Finish reading a directory", dev: "70h",
  code: "F5h", dir: "None", field: kw("NONE"), aux: "—", payload: "—",
  returns: kw("'C'"))[
Closes the directory opened by OPEN DIRECTORY.]

#cmd("NEW DISK", "Create a blank disk image", dev: "70h", code: "E7h",
  dir: "Write", field: kw("NONE"), aux: "—",
  payload: [#kw("NewDisk") structure out], returns: kw("'C'"))[
Creates a new, empty disk image on a host. The structure gives the host and
device slots, the geometry (sector count and size), and the file name.
#listing[typedef struct {
    unsigned short numSectors;
    unsigned short sectorSize;
    unsigned char  hostSlot;
    unsigned char  deviceSlot;
    char           filename[256];
} NewDisk;

NewDisk nd = { 720, 512, 0, 0, "" };  /* 360K */
strcpy(nd.filename, "BLANK.IMG");
int_f5_write(0x70, 0xE7, 0, 0, &nd, sizeof(nd));]]

#subsect[All Control-Device Commands]
#ix("Command matrix, control device")

The complete command set of device #kw("70h"). Commands shown earlier in
full are marked #kw("•").

#block(breakable: true, table(columns: (auto, auto, 1fr),
  align: (center, left, left), stroke: 0.5pt + rule-c, inset: 4.5pt,
  table.header(text(weight: 700)[Cmd], text(weight: 700)[Name],
    text(weight: 700)[Purpose]),
  kw("00h"), [DEVICE READY], [Test that the device responds],
  kw("BBh"), [GENERATE GUID], [Return a fresh globally-unique identifier],
  kw("BCh"), [QRCODE INPUT], [Feed text to the QR-code encoder],
  kw("BDh"), [QRCODE ENCODE], [Encode the input as a QR code],
  kw("BEh"), [QRCODE LENGTH], [Length of the encoded QR code],
  kw("BFh"), [QRCODE OUTPUT], [Read the encoded QR code],
  kw("C1h"), [GET HEAP], [Free memory in the FujiNet],
  kw("C2h"), [HASH CLEAR], [Reset the hash engine],
  kw("C3h"), [HASH COMPUTE], [Compute hash, keep input],
  kw("C4h"), [GET ADAPTER CFG EXT], [Extended adapter configuration],
  kw("C5h"), [HASH OUTPUT], [Read the computed hash],
  kw("C6h"), [HASH LENGTH], [Length of the hash output],
  kw("C7h"), [HASH COMPUTE], [Compute hash and clear],
  kw("C8h"), [HASH INPUT], [Feed bytes to the hash engine],
  kw("D2h"), [GET TIME], [Time as a packed value],
  kw("D3h"), [RANDOM NUMBER], [A hardware random number],
  kw("D6h"), [SET BOOT MODE], [Choose the boot configuration],
  kw("D7h"), [MOUNT ALL #box(width: 3.5pt, height: 3.5pt, fill: ink)], [Mount every selected slot],
  kw("D8h"), [COPY FILE], [Copy a file between hosts],
  kw("D9h"), [CONFIG BOOT], [Enable or disable the CONFIG boot disk],
  kw("DAh"), [GET DEVICE FULLPATH], [Read a slot's full image path],
  kw("DBh"), [CLOSE APPKEY], [Close the open app-key],
  kw("DCh"), [OPEN APPKEY], [Open an app-key for read or write],
  kw("DDh"), [READ APPKEY], [Read application-private data],
  kw("DEh"), [WRITE APPKEY], [Write application-private data],
  kw("E0h"), [GET HOST PREFIX], [Read a host's path prefix],
  kw("E1h"), [SET HOST PREFIX], [Set a host's path prefix],
  kw("E2h"), [SET DEVICE FULLPATH], [Select a slot's image by path],
  kw("E5h"), [GET DIR POSITION], [Current directory read position],
  kw("E4h"), [SET DIR POSITION], [Seek within a directory],
  kw("E6h"), [UNMOUNT HOST], [Disconnect a host slot],
  kw("E7h"), [NEW DISK #box(width: 3.5pt, height: 3.5pt, fill: ink)], [Create a blank disk image],
  kw("E8h"), [GET ADAPTER CONFIG #box(width: 3.5pt, height: 3.5pt, fill: ink)], [Network configuration],
  kw("E9h"), [UNMOUNT IMAGE #box(width: 3.5pt, height: 3.5pt, fill: ink)], [Eject a disk image],
  kw("EAh"), [GET WIFI ENABLED], [Is the radio switched on],
  kw("EBh"), [SET BAUDRATE], [Change the serial speed],
  kw("F1h"), [WRITE DEVICE SLOTS #box(width: 3.5pt, height: 3.5pt, fill: ink)], [Write the disk-slot table],
  kw("F2h"), [READ DEVICE SLOTS #box(width: 3.5pt, height: 3.5pt, fill: ink)], [Read the disk-slot table],
  kw("F3h"), [WRITE HOST SLOTS #box(width: 3.5pt, height: 3.5pt, fill: ink)], [Write the host-slot table],
  kw("F4h"), [READ HOST SLOTS #box(width: 3.5pt, height: 3.5pt, fill: ink)], [Read the host-slot table],
  kw("F5h"), [CLOSE DIRECTORY #box(width: 3.5pt, height: 3.5pt, fill: ink)], [Finish reading a directory],
  kw("F6h"), [READ DIR ENTRY #box(width: 3.5pt, height: 3.5pt, fill: ink)], [Read one directory entry],
  kw("F7h"), [OPEN DIRECTORY #box(width: 3.5pt, height: 3.5pt, fill: ink)], [Begin reading a directory],
  kw("F8h"), [MOUNT IMAGE #box(width: 3.5pt, height: 3.5pt, fill: ink)], [Mount a disk image],
  kw("F9h"), [MOUNT HOST #box(width: 3.5pt, height: 3.5pt, fill: ink)], [Open a host slot],
  kw("FAh"), [GET WIFI STATUS #box(width: 3.5pt, height: 3.5pt, fill: ink)], [Read the WiFi link state],
  kw("FBh"), [SET SSID #box(width: 3.5pt, height: 3.5pt, fill: ink)], [Join a wireless network],
  kw("FCh"), [GET SCAN RESULT #box(width: 3.5pt, height: 3.5pt, fill: ink)], [Read one scanned network],
  kw("FDh"), [SCAN NETWORKS #box(width: 3.5pt, height: 3.5pt, fill: ink)], [Begin a WiFi scan],
  kw("FEh"), [GET SSID], [Read the joined network's name],
  kw("FFh"), [RESET #box(width: 3.5pt, height: 3.5pt, fill: ink)], [Restart the FujiNet],
))

// --------------------------------------------------------------
#pagebreak(weak: true)
#sect[4.2  Network Adapters (71h-78h)]
#ix("Network adapters", "Channel I/O")

A network adapter is a single connection — to a web server, a TCP socket, a
remote file. You OPEN it with a URL, then READ and WRITE it as a stream, and
CLOSE it when done. Eight adapters (#kw("71h")–#kw("78h")) run
independently. The URL — the FujiNet calls it a #emph[devicespec] — names
the protocol, as in #kw("N:TCP://host:1234/") or
#kw("N:HTTP://example.com/page") .

#cmd("OPEN", "Open a network connection", dev: "71h-78h", code: "4Fh \"O\"",
  dir: "Write", field: kw("A1_A2"),
  aux: [AUX1 = mode, AUX2 = translation],
  payload: [devicespec URL out], returns: kw("'C'/'E'"))[
Opens the connection named by the devicespec. AUX1 is the access mode:
#kw("04h") read, #kw("08h") write, #kw("0Ch") read/write. AUX2 selects
end-of-line translation: #kw("00h") none, #kw("01h") CR, #kw("02h") LF,
#kw("03h") CR/LF. The payload is the URL (pad or terminate to a known
length).
#lst(
  "char url[256] = \"N:TCP://192.168.1.10:9000/\";",
  "/* mode 0x0C = read/write, trans 0 = none */",
  "/* set DH = FUJI_FIELD_A1_A2 (02h), CL=0x0C, CH=00 */",
  "        MOV  DX,0280h      ; DH=02 (A1_A2), DL=80 (write)",
  "        MOV  AX,4F71h      ; AH=4Fh 'O', AL=71h adapter 1",
  "        MOV  CL,0Ch        ; AUX1 = read/write",
  "        MOV  CH,00h        ; AUX2 = no translation",
  "        LES  BX,[url]      ; ES:BX -> devicespec",
  "        MOV  DI,256        ; length",
  "        INT  0F5h",
)]

#cmd("STATUS", "Bytes waiting and link state", dev: "71h-78h",
  code: "53h \"S\"", dir: "Read", field: kw("NONE"), aux: "—",
  payload: [4 bytes in], returns: kw("'C'"))[
Returns four bytes: the number of bytes waiting to be read (low, then high),
a #strong[connected] flag, and an #strong[error] code (Appendix A). Always
STATUS before READ, so you ask for no more than is waiting.
#listing[unsigned char st[4];
int_f5_read(0x71, 'S', 0, 0, st, 4);
unsigned short waiting = st[0] | (st[1] << 8);
unsigned char connected = st[2], error = st[3];]]

#cmd("READ", "Read bytes from the connection", dev: "71h-78h",
  code: "52h \"R\"", dir: "Read", field: kw("A1_A2"),
  aux: [AUX1/AUX2 = byte count (low/high)], payload: [data in],
  returns: kw("'C'/'E'"))[
Reads up to a 16-bit count of bytes into your buffer. Use the count from
STATUS. Set #kw("DH")=#kw("A1_A2") and #kw("DI") to the same count.
#lst(
  "        MOV  DX,0240h      ; DH=02 (A1_A2), DL=40 (read)",
  "        MOV  AX,5271h      ; AH=52h 'R', AL=71h",
  "        MOV  CX,[waiting]  ; CL/CH = byte count",
  "        LES  BX,[buf]",
  "        MOV  DI,[waiting]",
  "        INT  0F5h",
)]

#cmd("WRITE", "Write bytes to the connection", dev: "71h-78h",
  code: "57h \"W\"", dir: "Write", field: kw("A1_A2"),
  aux: [AUX1/AUX2 = byte count (low/high)], payload: [data out],
  returns: kw("'C'/'E'"))[
Writes a 16-bit count of bytes from your buffer to the connection.
#listing[network_write equivalent:
  CL/CH = len (low/high), DH = A1_A2, DL = 80h,
  AH = 'W' (57h), AL = device, ES:BX = buf, DI = len.]]

#cmd("CLOSE", "Close the connection", dev: "71h-78h", code: "43h \"C\"",
  dir: "None", field: kw("NONE"), aux: "—", payload: "—",
  returns: kw("'C'"))[
Closes the adapter and frees it for reuse. Always close what you open.]

#cmd("PARSE", "Parse received data as JSON", dev: "71h-78h",
  code: "50h \"P\"", dir: "None", field: kw("NONE"), aux: "—",
  payload: "—", returns: kw("'C'/'E'"))[
Parses the data most recently read on this adapter as JSON, readying it for
QUERY. Used with web services that answer in JSON.]

#cmd("QUERY", "Select a value from parsed JSON", dev: "71h-78h",
  code: "51h \"Q\"", dir: "Write", field: kw("NONE"), aux: "—",
  payload: [query string out], returns: kw("'C'/'E'"))[
Sets a query (a JSONPath-like path) against the parsed JSON. A following
STATUS reports the size of the result, which a READ then returns. Lets a
program pull one field out of a web reply without a JSON parser of its own.]

#subsect[Other Network Commands]
#block(breakable: true, table(columns: (auto, auto, 1fr),
  align: (center, left, left), stroke: 0.5pt + rule-c, inset: 4.5pt,
  table.header(text(weight: 700)[Cmd], text(weight: 700)[Name],
    text(weight: 700)[Purpose]),
  kw("FCh"), [CHANNEL MODE], [Switch between stream (0) and JSON (1) modes; mode in AUX1],
  kw("25h"), [SEEK], [Move the read/write position (AUX = 32-bit offset)],
  kw("26h"), [TELL], [Report the current position],
  kw("30h"), [GET PREFIX], [Read the adapter's path prefix],
  kw("2Ch"), [SET PREFIX], [Set the adapter's path prefix],
  kw("20h"), [RENAME], [Rename a file (file protocols)],
  kw("21h"), [DELETE], [Delete a file],
  kw("2Ah"), [MKDIR], [Make a directory],
  kw("2Bh"), [RMDIR], [Remove a directory],
  kw("FDh"), [USERNAME], [Supply a login name for the next OPEN],
  kw("FEh"), [PASSWORD], [Supply a password for the next OPEN],
  kw("5Ah"), [SET INT RATE], [Set the byte-waiting interrupt rate],
  kw("41h"), [CONTROL], [Protocol control (TCP accept, etc.)],
  kw("44h"), [SET DESTINATION], [Set the UDP destination],
  kw("72h"), [GET REMOTE], [Read the UDP sender's address],
))

// --------------------------------------------------------------
#pagebreak(weak: true)
#sect[4.3  Disk Drives (31h-38h)]
#ix("Disk drives", "Sectors")

A disk drive reads and writes 512-byte sectors of the disk image in its
slot. The MS-DOS driver uses these commands to present each drive as a DOS
drive letter; you may also call them directly to read or write raw sectors.
The sector number is a 32-bit value passed in AUX1–AUX4 with the
#kw("C1234") field descriptor.

#cmd("READ", "Read a 512-byte sector", dev: "31h-38h", code: "52h \"R\"",
  dir: "Read", field: kw("C1234"), aux: [AUX1–AUX4 = 32-bit sector],
  payload: [512 bytes in], returns: kw("'C'/'E'"))[
Reads one sector of the mounted image into your buffer.
#lst(
  "        MOV  DX,0740h      ; DH=07 (C1234), DL=40 (read)",
  "        MOV  AX,5231h      ; AH=52h 'R', AL=31h drive 1",
  "        MOV  CL,[sec+0]    ; AUX1 sector byte 0",
  "        MOV  CH,[sec+1]    ; AUX2 sector byte 1",
  "        MOV  SI,[sec+2]    ; AUX3:AUX4 sector bytes 2,3",
  "        LES  BX,[buf]",
  "        MOV  DI,512",
  "        INT  0F5h",
)]

#cmd("WRITE", "Write a 512-byte sector", dev: "31h-38h", code: "57h \"W\"",
  dir: "Write", field: kw("C1234"), aux: [AUX1–AUX4 = 32-bit sector],
  payload: [512 bytes out], returns: kw("'C'/'E'"))[
Writes one sector to the mounted image. The image must be mounted
read/write, or the command returns #kw("'E'").]

#cmd("STATUS", "Read drive status", dev: "31h-38h", code: "53h \"S\"",
  dir: "Read", field: kw("NONE"), aux: "—",
  payload: [status bytes in], returns: kw("'C'"))[
Returns the drive's status — whether an image is mounted, and its
read/write state.]

#subsect[Other Disk Commands]
#block(breakable: false, table(columns: (auto, auto, 1fr),
  align: (center, left, left), stroke: 0.5pt + rule-c, inset: 4.5pt,
  table.header(text(weight: 700)[Cmd], text(weight: 700)[Name],
    text(weight: 700)[Purpose]),
  kw("50h"), [PUT], [Write a sector without read-back verify],
  kw("21h"), [FORMAT], [Format the mounted image],
))

// --------------------------------------------------------------
#sect[4.4  The Clock (45h)]
#ix("Clock", "Time")

The clock device returns the date and time the FujiNet keeps from the
internet. Several commands return the same moment in different formats; the
most useful are below.

#cmd("GET TIME", "Read the time as bytes", dev: "45h", code: "93h",
  dir: "Read", field: kw("NONE"), aux: "—",
  payload: [6 bytes in], returns: kw("'C'"))[
Returns the local date and time as six bytes: year (since 1900), month, day,
hour, minute, second.
#lst("unsigned char t[6];",
     "int_f5_read(0x45, 0x93, 0, 0, t, 6);",
     "/* t[0]=year-1900 t[1]=mon t[2]=day t[3]=hr t[4]=min t[5]=sec */")]

#cmd("GET TIME (ISO)", "Read the time as text", dev: "45h", code: "5Ah",
  dir: "Read", field: kw("NONE"), aux: "—",
  payload: [ISO-8601 string in], returns: kw("'C'"))[
Returns the time as a printable ISO-8601 string in UTC (for example
#kw("2026-06-13T18:20:08Z")). Command #kw("49h") returns local time the
same way.]

#cmd("SET TIMEZONE", "Set the local time zone", dev: "45h", code: "99h",
  dir: "Write", field: kw("NONE"), aux: "—",
  payload: [TZ string out], returns: kw("'C'"))[
Sets the POSIX time-zone string (for example #kw("CST6CDT")) used by the
local-time commands.]

// ============================================================
// SECTION 5 — A WORKED EXAMPLE: NETCAT
// ============================================================
#chapter("A Worked Example: NETCAT", num: 5, tab: "NetCat",
  subs: ("What It Does", "Opening the Connection", "The Polling Loop",
         "Reading and Writing", "The Whole Program", "The Same Program in C"))
#ix("NETCAT", "Example program")

Nothing shows an interface better than a small, complete program. This
section builds #strong[NETCAT] — a bare-bones version of the classic network
utility — entirely in 8088 assembly language, using nothing but #kw("INT
F5h") for the network and #kw("INT 21h") for the console. It opens a TCP
connection, copies everything the connection sends to the screen, and sends
everything you type back. In about forty instructions you have a working
network terminal.

#sect[What It Does]

NETCAT uses a single network adapter (device #kw("71h")). After opening it
on a TCP devicespec, the program loops:

#bl[Ask the adapter how many bytes are waiting (STATUS).]
#bl[If the remote has closed, stop. If bytes are waiting, READ them and
write them to standard output.]
#bl[If a key has been pressed, send it to the connection (WRITE). #kw("ESC")
ends the program.]

#sect[Opening the Connection]

A #kw(".COM") program runs with all segment registers equal, so #kw("ES")
already points at our data once we copy #kw("CS") into it. The devicespec is
a plain string at the end of the program. We open for read/write (mode
#kw("0Ch")) with no translation, setting the field descriptor in #kw("DH")
to #kw("A1_A2") so both AUX bytes are sent:

#lst(
  "        MOV  AX,CS",
  "        MOV  ES,AX             ; ES -> our data (for ES:BX)",
  "        MOV  DX,0280h          ; DH=02 (A1_A2), DL=80 (write)",
  "        MOV  AX,4F71h          ; AH=4Fh 'O' open, AL=71h adapter 1",
  "        MOV  CL,0Ch            ; AUX1 = read/write",
  "        MOV  CH,00h            ; AUX2 = no translation",
  "        MOV  BX,OFFSET SPEC    ; ES:BX -> devicespec string",
  "        MOV  DI,SPECLEN        ; DI = its length",
  "        INT  0F5h",
  "        CMP  AL,'C'",
  "        JNE  QUIT              ; 'E' -> could not connect",
)

#sect[The Polling Loop]

The heart of the program asks for status, then acts. STATUS returns four
bytes: the count of bytes waiting (low, high), a connected flag, and an
error code. We read it into a 4-byte buffer:

#lst(
  "POLL:   MOV  DX,0040h          ; DH=00, DL=40 (read)",
  "        MOV  AX,5371h          ; AH=53h 'S' status, AL=71h",
  "        MOV  BX,OFFSET STAT",
  "        MOV  DI,4",
  "        INT  0F5h",
  "        CMP  BYTE PTR [STAT+2],0   ; connected?",
  "        JE   DONE              ; remote closed -> finish",
  "        MOV  AX,WORD PTR [STAT]    ; AX = bytes waiting",
  "        OR   AX,AX",
  "        JZ   KBD               ; none waiting -> check keyboard",
)

#sect[Reading and Writing]

When bytes are waiting we READ them (capped to our buffer) and hand them to
DOS for display. Note the field descriptor #kw("A1_A2") and the count in
both #kw("CX") and #kw("DI"):

#lst(
  "        CMP  AX,128",
  "        JBE  RLEN",
  "        MOV  AX,128            ; cap to buffer size",
  "RLEN:   MOV  CX,AX             ; CL/CH = count",
  "        MOV  DI,AX             ; DI    = count",
  "        MOV  DX,0240h          ; DH=02 (A1_A2), DL=40 (read)",
  "        PUSH AX",
  "        MOV  AX,5271h          ; AH=52h 'R' read, AL=71h",
  "        MOV  BX,OFFSET BUF",
  "        INT  0F5h",
  "        POP  CX                ; CX = bytes read",
  "        MOV  BX,1              ; stdout handle",
  "        MOV  DX,OFFSET BUF",
  "        MOV  AH,40h            ; DOS 'write file'",
  "        INT  21h",
)

A keypress is sent to the connection one byte at a time. DOS function
#kw("0Bh") tells us whether a key is ready; #kw("08h") reads it without echo:

#lst(
  "KBD:    MOV  AH,0Bh            ; key ready?",
  "        INT  21h",
  "        OR   AL,AL",
  "        JZ   POLL              ; no -> keep polling",
  "        MOV  AH,08h            ; read key, no echo",
  "        INT  21h",
  "        CMP  AL,27             ; ESC ends the program",
  "        JE   DONE",
  "        MOV  [BUF],AL",
  "        MOV  DX,0280h          ; DH=02 (A1_A2), DL=80 (write)",
  "        MOV  AX,5771h          ; AH=57h 'W' write, AL=71h",
  "        MOV  CX,1              ; one byte",
  "        MOV  BX,OFFSET BUF",
  "        MOV  DI,1",
  "        INT  0F5h",
  "        JMP  POLL",
)

#sect[The Whole Program]

Closing the adapter and exiting completes it. Assemble with TASM
(#kw("TASM NETCAT")  then  #kw("TLINK /t NETCAT")) or MASM
(#kw("ML /AT NETCAT.ASM")) to produce #kw("NETCAT.COM").

#lst(
  "; NETCAT.ASM -- a tiny netcat for FujiNet, via INT F5h.",
  "        .MODEL TINY",
  "        .CODE",
  "        ORG  100h",
  "START:  MOV  AX,CS",
  "        MOV  ES,AX",
  "        MOV  DX,0280h          ; open: A1_A2 / write",
  "        MOV  AX,4F71h          ; 'O', adapter 1",
  "        MOV  CL,0Ch            ; read/write",
  "        MOV  CH,00h            ; no translation",
  "        MOV  BX,OFFSET SPEC",
  "        MOV  DI,SPECLEN",
  "        INT  0F5h",
  "        CMP  AL,'C'",
  "        JNE  QUIT",
  "POLL:   MOV  DX,0040h          ; status",
  "        MOV  AX,5371h",
  "        MOV  BX,OFFSET STAT",
  "        MOV  DI,4",
  "        INT  0F5h",
  "        CMP  BYTE PTR [STAT+2],0",
  "        JE   DONE",
  "        MOV  AX,WORD PTR [STAT]",
  "        OR   AX,AX",
  "        JZ   KBD",
  "        CMP  AX,128",
  "        JBE  RLEN",
  "        MOV  AX,128",
  "RLEN:   MOV  CX,AX",
  "        MOV  DI,AX",
  "        MOV  DX,0240h          ; read: A1_A2 / read",
  "        PUSH AX",
  "        MOV  AX,5271h",
  "        MOV  BX,OFFSET BUF",
  "        INT  0F5h",
  "        POP  CX",
  "        MOV  BX,1",
  "        MOV  DX,OFFSET BUF",
  "        MOV  AH,40h",
  "        INT  21h",
  "KBD:    MOV  AH,0Bh",
  "        INT  21h",
  "        OR   AL,AL",
  "        JZ   POLL",
  "        MOV  AH,08h",
  "        INT  21h",
  "        CMP  AL,27",
  "        JE   DONE",
  "        MOV  [BUF],AL",
  "        MOV  DX,0280h          ; write: A1_A2 / write",
  "        MOV  AX,5771h",
  "        MOV  CX,1",
  "        MOV  BX,OFFSET BUF",
  "        MOV  DI,1",
  "        INT  0F5h",
  "        JMP  POLL",
  "DONE:   MOV  DX,0000h          ; close: none",
  "        MOV  AX,4371h",
  "        INT  0F5h",
  "QUIT:   MOV  AX,4C00h",
  "        INT  21h",
  "SPEC    DB   'N:TCP://192.168.1.10:9000/',0",
  "SPECLEN EQU  $-SPEC",
  "STAT    DB   4 DUP(0)",
  "BUF     DB   128 DUP(0)",
  "        END  START",
)

#note[NETCAT polls as fast as it can, which is fine for a demonstration. A
real program would yield to DOS between polls, or raise the byte-waiting
interrupt rate (network command #kw("5Ah")) and wait on it, to be gentler on
the machine.]

#sect[The Same Program in C]
#ix("NETCAT, in C", "fujinet-lib")

For comparison, here is NETCAT again — the same program, the same steps — in
C, using the FujiNet library #kw("fujinet-lib") instead of raw #kw("INT
F5h"). Read the two side by side as a Rosetta stone: each library call below
reduces to one of the interrupt calls on the facing pages. #kw("network_open")
is the OPEN of Section 4.2; #kw("network_status") returns the same four bytes
this program reads by hand; #kw("network_read") and #kw("network_write") are
the READ and WRITE; #kw("network_close") is the CLOSE. The library simply
loads the registers and issues #kw("INT F5h") for you (Section 2, #emph[The C
Wrappers]).

#lst(
  "/* NETCAT.C -- the program above, in C, via fujinet-lib.",
  "   Open Watcom:  wcl -bcl=dos netcat.c fujinet.lib            */",
  "",
  "#include <conio.h>             /* kbhit, getch            */",
  "#include <stdio.h>             /* fwrite, printf          */",
  "#include <fujinet-network.h>",
  "",
  "#define SPEC \"N:TCP://192.168.1.10:9000/\"",
  "",
  "int main(void)",
  "{",
  "    unsigned char  buf[128];",
  "    unsigned short waiting;    /* bytes ready to read     */",
  "    unsigned char  connected;  /* is the link still up?   */",
  "    unsigned char  err;        /* detailed error code     */",
  "    int            n, key;",
  "",
  "    network_init();",
  "    if (network_open(SPEC, OPEN_MODE_RW, OPEN_TRANS_NONE) != FN_ERR_OK) {",
  "        printf(\"could not connect\\n\");",
  "        return 1;",
  "    }",
  "",
  "    for (;;) {",
  "        /* STATUS: bytes waiting, and are we still connected? */",
  "        network_status(SPEC, &waiting, &connected, &err);",
  "        if (!connected)",
  "            break;                          /* remote closed  */",
  "",
  "        if (waiting) {                      /* READ and print */",
  "            if (waiting > sizeof(buf))",
  "                waiting = sizeof(buf);",
  "            n = network_read(SPEC, buf, waiting);",
  "            if (n > 0)",
  "                fwrite(buf, 1, n, stdout);",
  "        }",
  "",
  "        if (kbhit()) {                      /* a key? WRITE it */",
  "            key = getch();",
  "            if (key == 27)                  /* ESC quits      */",
  "                break;",
  "            buf[0] = (unsigned char) key;",
  "            network_write(SPEC, buf, 1);",
  "        }",
  "    }",
  "",
  "    network_close(SPEC);                    /* CLOSE          */",
  "    return 0;",
  "}",
)

The C is shorter and clearer, and it is what most programs should use. The
assembler version exists to show what #kw("fujinet-lib") does underneath —
and to prove that the whole interface fits in a handful of register loads and
one interrupt.

// ============================================================
// SECTION 6 — A SECOND EXAMPLE: READING MASTODON
// ============================================================
#chapter("A Second Example: Reading Mastodon", num: 6, tab: "Mastodon",
  subs: ("The JSON Engine", "The Flow", "In C", "In Assembler", "In Pascal"))
#ix("Mastodon", "JSON", "Web services")

Most of the modern web answers in #strong[JSON], and JSON is a poor fit for a
machine with 64 kilobytes and no string library. The FujiNet solves this on
your behalf: it can fetch a web page, parse the JSON #emph[on the adapter],
and hand back only the field you ask for. Your program never sees a brace.

This example fetches the newest post from a public Mastodon timeline and
pulls out three fields — the author's display name, the date, and the body of
the post. It is the heart of the FujiNet Mastodon client, reduced to its
network calls and shown three ways.

#sect[The JSON Engine]
#ix("PARSE command", "QUERY command")

Three network commands do the work, after an ordinary OPEN:

#bl[#strong[CHANNEL MODE] (#kw("FCh")) with AUX1 = #kw("01h") switches the
adapter into #strong[JSON mode].]
#bl[#strong[PARSE] (#kw("50h"), #kw("'P'")) tells the adapter to read the
whole HTTP response and parse it as JSON, holding the result in the FujiNet.]
#bl[#strong[QUERY] (#kw("51h"), #kw("'Q'")) sends a path such as
#kw("/0/content"); a following STATUS gives the length of the matching value,
and a READ returns it.]

A path is a slash-separated walk into the JSON: #kw("/0") is the first element
of the top-level array (the newest post), #kw("/0/account/display_name") the
author's name within it. Query as many paths as you like before closing.

#sect[The Flow]

#bl[#kw("network_open") the timeline URL for an HTTP GET.]
#bl[#kw("network_json_parse") — set JSON mode, then PARSE.]
#bl[#kw("network_json_query") once per field — QUERY, STATUS, READ.]
#bl[#kw("network_close").]

The URL asks the server for just the newest post:

#lst("N:HTTPS://oldbytes.space/api/v1/timelines/public?limit=1")

#sect[In C]
#ix("Mastodon, in C")

With #kw("fujinet-lib") the whole job is a dozen lines. This is essentially
the client's own #kw("fetch_post") routine:

#lstb(
  "/* MASTO.C -- newest Mastodon post, three fields, via fujinet-lib. */",
  "#include <string.h>",
  "#include <fujinet-network.h>",
  "",
  "static const char *url =",
  "    \"N:HTTPS://oldbytes.space/api/v1/timelines/public?limit=1\";",
  "",
  "void fetch_post(char *name, char *date, char *toot)",
  "{",
  "    char tmp[256];",
  "",
  "    memset(name, 0, 32);",
  "    memset(date, 0, 32);",
  "    memset(toot, 0, 5120);",
  "",
  "    network_init();",
  "    network_open(url, OPEN_MODE_HTTP_GET, 0x00);",
  "    network_json_parse(url);                       /* JSON mode + PARSE */",
  "",
  "    network_json_query(url, \"/0/account/display_name\", tmp);",
  "    strncpy(name, tmp, 31);",
  "    network_json_query(url, \"/0/created_at\", tmp);",
  "    strncpy(date, tmp, 31);",
  "    network_json_query(url, \"/0/content\", toot);  /* QUERY+STATUS+READ */",
  "",
  "    network_close(url);",
  "}",
)

#sect[In Assembler]
#ix("Mastodon, in assembler")

The same sequence in 8088, calling #kw("INT F5h") directly. A subroutine
#kw("QUERY") sends one path and reads its value, so the three fields are three
calls. Note the JSON-mode and PARSE calls between OPEN and the first query.

#lstb(
  "; MASTO.ASM -- newest Mastodon post fields via INT F5h.",
  "        .MODEL SMALL",
  "        .STACK 100h",
  "        .DATA",
  "URL     DB 'N:HTTPS://oldbytes.space/api/v1/timelines/public?limit=1',0",
  "URLLEN  EQU $-URL",
  "QNAME   DB '/0/account/display_name',0",
  "QDATE   DB '/0/created_at',0",
  "QBODY   DB '/0/content',0",
  "STAT    DB 4 DUP(0)",
  "NAME    DB 32 DUP(0)",
  "DATE_   DB 32 DUP(0)",
  "BODY    DB 5120 DUP(0)        ; a toot can be long",
  "        .CODE",
  "START:  MOV  AX,@DATA",
  "        MOV  DS,AX",
  "        MOV  ES,AX             ; ES=DS for ES:BX payloads",
  "        MOV  DX,0080h          ; open: DH=00, DL=80 (write)",
  "        MOV  AX,4F71h          ; 'O', adapter 1",
  "        MOV  CL,04h            ; AUX1 = HTTP GET",
  "        MOV  CH,00h            ; AUX2 = no translation",
  "        MOV  BX,OFFSET URL",
  "        MOV  DI,URLLEN",
  "        INT  0F5h",
  "        MOV  DX,0000h          ; channel mode: none",
  "        MOV  AX,0FC71h         ; AH=FCh",
  "        MOV  CL,01h            ; AUX1 = JSON mode",
  "        INT  0F5h",
  "        MOV  DX,0000h          ; parse: none",
  "        MOV  AX,5071h          ; AH=50h 'P'",
  "        INT  0F5h",
  "        MOV  SI,OFFSET QNAME   ; query each field",
  "        MOV  BP,OFFSET NAME",
  "        CALL QUERY",
  "        MOV  SI,OFFSET QDATE",
  "        MOV  BP,OFFSET DATE_",
  "        CALL QUERY",
  "        MOV  SI,OFFSET QBODY",
  "        MOV  BP,OFFSET BODY",
  "        CALL QUERY",
  "        MOV  DX,0000h          ; close: none",
  "        MOV  AX,4371h          ; 'C'",
  "        INT  0F5h",
  "        MOV  AX,4C00h",
  "        INT  21h",
  "; QUERY: path at DS:SI, destination at DS:BP",
  "QUERY:  MOV  DX,0080h          ; write the path",
  "        MOV  AX,5171h          ; AH=51h 'Q'",
  "        MOV  BX,SI",
  "        MOV  DI,256            ; the library sends 256",
  "        INT  0F5h",
  "        MOV  DX,0040h          ; status -> bytes waiting",
  "        MOV  AX,5371h          ; AH=53h 'S'",
  "        MOV  BX,OFFSET STAT",
  "        MOV  DI,4",
  "        INT  0F5h",
  "        MOV  CX,WORD PTR [STAT]    ; CL/CH = byte count",
  "        JCXZ Q9",
  "        MOV  DX,0240h          ; read: DH=02 (A1_A2), DL=40",
  "        MOV  AX,5271h          ; AH=52h 'R'",
  "        MOV  BX,BP             ; ES:BX -> destination",
  "        MOV  DI,CX             ; DI = count",
  "        INT  0F5h",
  "Q9:     RET",
  "        END START",
)

#sect[In Pascal]
#ix("Mastodon, in Pascal")

And once more in Turbo Pascal, reaching #kw("INT F5h") through the #kw("Dos")
unit's #kw("Intr"). A small #kw("FujiF5") helper plays the part the library's
wrappers play in C; #kw("JsonQuery") mirrors #kw("network_json_query").

#lstb(
  "{ MASTO.PAS -- newest Mastodon post via INT F5h (Turbo Pascal). }",
  "uses Dos, Strings;",
  "",
  "const",
  "  DEV = $71;",
  "  url   : PChar = 'N:HTTPS://oldbytes.space/api/v1/timelines/public'",
  "                + '?limit=1';",
  "  qName : PChar = '/0/account/display_name';",
  "  qDate : PChar = '/0/created_at';",
  "  qBody : PChar = '/0/content';",
  "var",
  "  stat : array[0..3] of Byte;",
  "",
  "function FujiF5(dir, fld, cmd, aux1, aux2: Byte;",
  "                buf: Pointer; len: Word): Char;",
  "var r: Registers;",
  "begin",
  "  FillChar(r, SizeOf(r), 0);",
  "  r.DL := dir;  r.DH := fld;",
  "  r.AL := DEV;  r.AH := cmd;",
  "  r.CL := aux1; r.CH := aux2;",
  "  if buf <> nil then begin",
  "    r.ES := Seg(buf^);  r.BX := Ofs(buf^);  r.DI := len;",
  "  end;",
  "  Intr($F5, r);",
  "  FujiF5 := Chr(r.AL);",
  "end;",
  "",
  "procedure JsonQuery(query, dest: PChar);",
  "var bw: Word;",
  "begin",
  "  FujiF5($80, $00, $51, 0, 0, query, 256);          { 'Q' write path }",
  "  FujiF5($40, $00, $53, 0, 0, @stat, 4);            { 'S' status     }",
  "  bw := stat[0] or (Word(stat[1]) shl 8);",
  "  if bw > 0 then",
  "    FujiF5($40, $02, $52, Lo(bw), Hi(bw), dest, bw);  { 'R' read     }",
  "  dest[bw] := #0;",
  "end;",
  "",
  "procedure FetchPost(name, date, toot: PChar);",
  "begin",
  "  FillChar(name^, 32, 0);  FillChar(date^, 32, 0);",
  "  FillChar(toot^, 5120, 0);",
  "  FujiF5($80, $00, $4F, $04, 0, url, StrLen(url)+1);  { open HTTP GET }",
  "  FujiF5($00, $00, $FC, $01, 0, nil, 0);             { JSON mode     }",
  "  FujiF5($00, $00, $50, 0, 0, nil, 0);               { parse         }",
  "  JsonQuery(qName, name);",
  "  JsonQuery(qDate, date);",
  "  JsonQuery(qBody, toot);",
  "  FujiF5($00, $00, $43, 0, 0, nil, 0);               { close         }",
  "end;",
)

#note[All three speak to the same engine in the same order — open, JSON mode,
parse, query each field, close. C names the steps, Pascal wraps them, and the
assembler shows the registers underneath. The FujiNet does the parsing; the
program just asks for #kw("/0/content") and is handed the text.]

// ============================================================
// SECTION 7 — INSIDE FUJINET.SYS
// ============================================================
#chapter("Inside FUJINET.SYS", num: 7, tab: "FUJINET.SYS",
  subs: ("The Device Header", "Strategy and Interrupt", "The Request Packet",
         "The Dispatch Table", "Initialization", "Reading and Writing Sectors",
         "Media Check and BPB", "The IOCTL Signature"))
#ix("FUJINET.SYS", "Device driver, block")

#kw("FUJINET.SYS") is the program behind everything in this book. It is an
installable MS-DOS #strong[block device driver], loaded from
#kw("CONFIG.SYS"), that does two jobs at once: it presents the FujiNet's eight
virtual disks to DOS as ordinary drive letters, and — on the way — it installs
the #kw("INT F5h") handler documented in Sections 2 through 4. This section
walks its source.

The DOS side of the story (how DOS finds, calls, and talks to a device driver)
is covered in the IBM #emph[DOS Technical Reference]; here we follow what
#kw("FUJINET.SYS") does in answer.

#sect[The Device Header]
#ix("Device header")

Every driver begins with a #strong[device header]: a fixed structure DOS reads
to learn the driver's kind, its entry points, and its name. For
#kw("FUJINET.SYS") it is written in assembly, at offset 0 of the load image:

#lstb(
  "_SYS_HEADER segment word public 'SYS_HEADER'",
  "        org     0",
  "_sys_hdr_ label near",
  "        extrn   Strategy_:near",
  "        extrn   Interrupt_:near",
  "ATTRIB_OVER_32M equ     0020h",
  "ATTRIB_FAT_BPB  equ     2000h",
  "ATTRIB_RW_IOCTL equ     4000h",
  "        dd      -1                  ; link to next driver (set by DOS)",
  "        dw      ATTRIB_OVER_32M OR ATTRIB_FAT_BPB OR ATTRIB_RW_IOCTL",
  "        dw      Strategy_           ; offset of STRATEGY entry",
  "        dw      Interrupt_          ; offset of INTERRUPT entry",
  "        db      8, 0, 0, 0, 0, 0, 0, 0   ; 8 units; rest unused",
)

The fields, in order:

#bl[#strong[Link field] (#kw("dd -1")) — a far pointer to the next driver in
the chain. DOS fills this in when it links the driver; the initial #kw("-1")
marks the end.]
#bl[#strong[Attribute word] — bit flags describing the driver. A #strong[zero]
top bit marks it a #strong[block] device (a character device sets bit 15).
The three flags raised here say the driver understands volumes over 32 MB
(#kw("0020h")), supplies its own BPB so DOS accepts a non-IBM disk layout
(#kw("2000h")), and accepts IOCTL read/write control calls (#kw("4000h")).]
#bl[#strong[Strategy and Interrupt offsets] — the two entry points DOS calls
(next).]
#bl[#strong[Name/unit field] — eight bytes. For a block driver the first byte
is the #strong[unit count]: #kw("8"), the FujiNet's eight disks. (A character
driver puts an eight-character device name here instead — see
#kw("FUJIPRN.SYS").)]

#sect[Strategy and Interrupt]
#ix("Strategy routine", "Interrupt routine")

DOS calls a driver in #strong[two steps]. First it calls the #strong[strategy]
routine with a far pointer (in #kw("ES:BX")) to a #strong[request packet];
the strategy routine only stows that pointer away. Then it calls the
#strong[interrupt] routine, which does the actual work on the saved packet.
The split is a relic of multitasking ambitions that DOS never used, but every
driver must honor it.

In #kw("FUJINET.SYS") the two are C functions with custom calling conventions.
Strategy is a single line:

#lstb(
  "static SYSREQ __far *fpRequest = (SYSREQ __far *) 0;",
  "",
  "void far Strategy(SYSREQ far *req)",
  "#pragma aux Strategy __parm [__es __bx]      // packet arrives in ES:BX",
  "{",
  "  fpRequest = req;                           // just remember it",
  "  return;",
  "}",
)

The interrupt routine saves every register, switches to the driver's own
stack, dispatches the command, marks the packet done, restores the stack and
registers, and returns:

#lstb(
  "void far Interrupt(void)",
  "{",
  "  push_regs();",
  "",
  "  // Save DOS's SS:SP and switch to our own 1 KB stack",
  "  // (DOS calls drivers on a tiny stack).",
  "  _asm {",
  "    mov dos_ss, ss",
  "    mov dos_sp, sp",
  "    mov ss, ax            // ax = our_ss, cx = our_sp",
  "    mov sp, cx",
  "  }",
  "",
  "  if (fpRequest->command > MAXCOMMAND",
  "      || !(currentFunction = dispatchTable[fpRequest->command]))",
  "    fpRequest->status = ERROR_BIT | UNKNOWN_CMD;",
  "  else",
  "    fpRequest->status = currentFunction(fpRequest);",
  "",
  "  fpRequest->status |= DONE_BIT;             // tell DOS we finished",
  "",
  "  _asm {                  // restore DOS's stack",
  "    mov ss, dos_ss",
  "    mov sp, dos_sp",
  "  }",
  "  pop_regs();",
  "}",
)

#note[The stack swap matters. DOS hands a driver only a few dozen bytes of
stack — far too little for C code that calls into the serial routines.
#kw("FUJINET.SYS") moves to its own 1 KB stack for the duration of the call,
then puts DOS's stack back exactly as it was.]

#sect[The Request Packet]
#ix("Request packet")

DOS describes each operation in a #strong[request packet]. The first five
bytes are common to every command — a length, the target unit, the command
code, and a status word DOS reads on return — followed by a union of
command-specific fields:

#lstb(
  "typedef struct {",
  "  uint8_t  length;        // size of this packet",
  "  uint8_t  unit;          // which disk (0-7)",
  "  uint8_t  command;       // what to do (0-24)",
  "  uint16_t status;        // driver writes the result here",
  "  uint8_t  reserved[8];",
  "  union {                 // one arm per command group:",
  "    SYSREQ_INIT  init;     //   command 0  (INIT)",
  "    SYSREQ_MEDIA media;    //   command 1  (MEDIA CHECK)",
  "    SYSREQ_BPB   bpb;      //   command 2  (BUILD BPB)",
  "    SYSREQ_IO    io;       //   commands 4 & 8 (READ / WRITE)",
  "    SYSREQ_INPUT input;",
  "    SYSREQ_LDMAP ldmap;",
  "  };",
  "} SYSREQ;",
)

The #kw("command") byte is the whole story: it selects both the arm of the
union that is valid and the handler that runs. The status word the driver
writes back carries an #strong[error bit] (#kw("8000h")), a #strong[done bit]
(#kw("0100h")), and, on error, a DOS error number in the low byte.

#sect[The Dispatch Table]
#ix("Dispatch table")

The command byte (0 through 24) indexes a table of handlers. Commands the
FujiNet has no use for point at #kw("Unknown_cmd"), which reports
#emph[unknown command] to DOS:

#lstb(
  "static driverFunction_t dispatchTable[] = {",
  "  Init_cmd,           //  0  INIT          (install-time)",
  "  Media_check_cmd,    //  1  MEDIA CHECK   (has the disk changed?)",
  "  Build_bpb_cmd,      //  2  BUILD BPB     (describe the disk)",
  "  Ioctl_input_cmd,    //  3  IOCTL READ    (the FUJI signature)",
  "  Input_cmd,          //  4  READ          (sectors in)",
  "  Input_no_wait_cmd,  //  5  (char only)",
  "  Input_status_cmd,   //  6  (char only)",
  "  Input_flush_cmd,    //  7  (char only)",
  "  Output_cmd,         //  8  WRITE         (sectors out)",
  "  Output_verify_cmd,  //  9  WRITE+VERIFY",
  "  Output_status_cmd,  // 10  (char only)",
  "  Output_flush_cmd,   // 11  (char only)",
  "  Ioctl_output_cmd,   // 12  IOCTL WRITE",
  "  Dev_open_cmd,       // 13  OPEN",
  "  Dev_close_cmd,      // 14  CLOSE",
  "  Remove_media_cmd,   // 15  REMOVE MEDIA",
  "  Unknown_cmd, Unknown_cmd, Unknown_cmd,   // 16-18 reserved",
  "  Ioctl_cmd,          // 19  GENERIC IOCTL",
  "  Unknown_cmd, Unknown_cmd, Unknown_cmd,   // 20-22 reserved",
  "  Get_l_d_map_cmd,    // 23  GET LOGICAL DRIVE MAP",
  "  Set_l_d_map_cmd     // 24  SET LOGICAL DRIVE MAP",
  "};",
)

Of these, only a handful do real work: #strong[INIT], #strong[MEDIA CHECK],
#strong[BUILD BPB], #strong[IOCTL READ], #strong[READ], and #strong[WRITE].
The rest are answered politely and otherwise ignored.

#sect[Initialization]
#ix("INIT command", "BPB", "List of Lists")

Command 0, #strong[INIT], runs once, when DOS loads the driver at boot. It is
the busiest handler. Abridged, it:

#lstb(
  "uint16_t Init_cmd(SYSREQ far *req)",
  "{",
  "  // 1. Announce ourselves (DOS version via INT 21h AH=30h).",
  "  consolef(\"\\nFujiNet driver \" VERSION \" ... on MS-DOS %i.%i\\n\", ...);",
  "",
  "  // 2. Turn the CONFIG.SYS line into environment variables",
  "  //    (FUJI_PORT=, FUJI_BPS=, NOTIME) for getenv().",
  "  parse_config(req->init.bpb_ptr);",
  "  environ = (char **) &config_env;",
  "",
  "  // 3. Open the serial port and identify the UART.",
  "  fujicom_init();",
  "  check_uart();",
  "",
  "  // 4. Prove the FujiNet is really there; bail out if not.",
  "  err = get_fujinet_version();",
  "  if (!err) err = get_set_time(!getenv(\"NOTIME\"));",
  "  if (err) {                       // nothing answered:",
  "    req->init.num_units = 0;        //   claim zero drives,",
  "    req->init.end_ptr   = 0;        //   keep no memory resident",
  "    return ERROR_BIT;",
  "  }",
  "",
  "  // 5. Hand DOS a BPB for each of the 8 disks (see below).",
  "  req->init.num_units = FN_MAX_DEV;",
  "  // ... fill fn_bpb_table[idx], point fn_bpb_pointers[idx] at it ...",
  "  req->bpb.table = MK_FP(getCS(), fn_bpb_pointers);",
  "",
  "  // 6. Report which drive letters we landed on, then arm INT F5.",
  "  find_drive_letter(req->init.num_units);",
  "  setf5();",
  "  return OP_COMPLETE;",
  "}",
)

A few details repay a closer look.

#subsect[The BIOS Parameter Block]
Step 5 gives DOS a #strong[BPB] — a BIOS Parameter Block — describing each
disk's geometry. Rather than ask the FujiNet, the driver simply describes a
familiar #strong[360 KB 5.25-inch floppy]: 512-byte sectors, two sectors per
cluster, two FATs, 112 root entries, #kw("0x2d0") (720) sectors, media
descriptor #kw("0xFD"). Whatever image is later mounted, DOS reads its real
boot sector through BUILD BPB and adjusts.

#subsect[Finding the Drive Letter]
Step 6's #kw("find_drive_letter") performs a small piece of DOS archaeology to
report the letters the FujiNet's disks received. It asks for the
#strong[List of Lists] (the undocumented internal table at the head of DOS) and
reads the running block-device count from it:

#lstb(
  "void find_drive_letter(uint8_t num_units)",
  "{",
  "  uint8_t far *lol;",
  "  _asm {",
  "    mov ah, 52h            // INT 21h AH=52h: get List of Lists",
  "    int 21h                //   -> ES:BX",
  "    mov word ptr lol,   bx",
  "    mov word ptr lol+2, es",
  "  }",
  "  // byte at offset 0x20 = number of block devices so far,",
  "  // which is also the index of our first drive letter.",
  "  char first = lol[0x20] + 'A';",
  "  consolef(\"FujiNet attached to drives %c:-%c:\\n\",",
  "           first, first + num_units - 1);",
  "}",
)

#sect[Reading and Writing Sectors]
#ix("READ command", "WRITE command", "Sector addressing")

The two commands DOS leans on hardest are #strong[READ] (4) and
#strong[WRITE] (8). Both carry a #kw("SYSREQ_IO") arm: a buffer, a sector
count, and a starting sector. The driver loops, turning each DOS sector into a
disk-device command on the FujiBus.

#kw("READ") translates almost directly to the disk-device READ of Section 4.3
— the 32-bit sector goes into AUX1–AUX4 with the #kw("C1234") field
descriptor, and 512 bytes come back:

#lstb(
  "uint16_t Input_cmd(SYSREQ far *req)",
  "{",
  "  uint8_t far *buf = req->io.buffer_ptr;",
  "  uint32_t sector  = (req->length > 22) ? req->io.start_sector_32",
  "                                        : req->io.start_sector;",
  "  uint32_t sector_max = fn_bpb_table[req->unit].num_sectors;",
  "",
  "  for (idx = 0; idx < req->io.count; idx++, sector++) {",
  "    if (sector >= sector_max)            // off the end of the image?",
  "      return ERROR_BIT | NOT_FOUND;",
  "    if (!fuji_bus_call(FUJI_DEVICEID_DISK + req->unit,",
  "                       FUJICMD_READ, FUJI_FIELD_C1234,",
  "                       U16_LSB(U32_LSW(sector)), U16_MSB(U32_LSW(sector)),",
  "                       U16_LSB(U32_MSW(sector)), U16_MSB(U32_MSW(sector)),",
  "                       NULL, 0, &buf[idx * SECTOR_SIZE], SECTOR_SIZE))",
  "      break;                             // serial error: stop here",
  "  }",
  "  req->io.count = idx;                   // tell DOS how many we did",
  "  return idx ? OP_COMPLETE : (ERROR_BIT | GENERAL_FAIL);",
  "}",
)

The #kw("U16_LSB(U32_LSW(...))") nest just slices the 32-bit sector into four
bytes for AUX1–AUX4. On any serial failure the loop stops and reports the
partial count, exactly as DOS expects of real hardware.

#kw("WRITE") is the mirror image, with one guard in front: it refuses a disk
that was mounted read-only, returning DOS's #emph[write protect] error so the
familiar #emph[Write protect error writing drive X] appears:

#lstb(
  "uint16_t Output_cmd(SYSREQ far *req)",
  "{",
  "  if (disk_slots[req->unit].mode != SLOT_READWRITE)",
  "    return ERROR_BIT | WRITE_PROTECT;    // read-only image",
  "  // ... identical loop, FUJICMD_WRITE, buffer -> FujiNet ...",
  "}",
)

#sect[Media Check and BPB]
#ix("MEDIA CHECK command", "BUILD BPB command")

Two smaller commands keep DOS's idea of the disk honest.

#strong[MEDIA CHECK] (1) answers a single question: has the disk changed since
DOS last looked? The driver asks the FujiNet for the slot's #strong[mount
time] and compares it with the value from before. If they differ, a new image
has been mounted, and the driver tells DOS to throw away its cached directory
and FAT:

#lstb(
  "  fuji_bus_call(FUJI_DEVICEID_FUJINET, FUJICMD_STATUS, FUJI_FIELD_A1,",
  "                STATUS_MOUNT_TIME, 0, 0, 0, NULL, 0,",
  "                mount_status, sizeof(mount_status));",
  "  new_status = mount_status[req->unit * 2];",
  "  if (!new_status)            req->media.return_info =  0; // unsure",
  "  else if (old != new_status) req->media.return_info = -1; // changed",
  "  else                        req->media.return_info =  1; // unchanged",
)

This is what lets you mount a different disk image in CONFIG and have it appear
under the same drive letter without rebooting.

#strong[BUILD BPB] (2) hands DOS the disk's real geometry. The driver reads
sector 0 — the boot sector — of the freshly mounted image and copies the BPB
out of it, from the standard offset #kw("0x0B"):

#lstb(
  "  fuji_bus_call(FUJI_DEVICEID_DISK + req->unit, FUJICMD_READ,",
  "                FUJI_FIELD_C1234, 0, 0, 0, 0, NULL, 0, buf, SECTOR_SIZE);",
  "  _fmemcpy(fn_bpb_pointers[req->unit], &buf[0x0b], sizeof(DOS_BPB));",
)

#sect[The IOCTL Signature]
#ix("IOCTL", "Device identification")

How does a utility such as #kw("FMOUNT") know which drive letters belong to the
FujiNet? Through #strong[IOCTL READ] (command 3). A program opens the drive,
issues a control read, and the driver answers with a four-byte signature and
the unit number:

#lstb(
  "uint16_t Ioctl_input_cmd(SYSREQ far *req)",
  "{",
  "  fuji_ioctl_query far *query = (fuji_ioctl_query far *) req->io.buffer_ptr;",
  "  _fmemcpy(query->signature, \"FUJI\", 4);   // the secret handshake",
  "  query->unit = req->unit;",
  "  return OP_COMPLETE;",
  "}",
)

Any program that reads #kw("FUJI") back from a drive knows it is talking to a
FujiNet, and which of the eight units it is. That is the whole mechanism by
which the command-line tools find their device.


// ============================================================
// SECTION 8 — INSIDE FUJIPRN.SYS
// ============================================================
#chapter("Inside FUJIPRN.SYS", num: 8, tab: "FUJIPRN.SYS",
  subs: ("A Character Device", "Capturing Output", "The INT 17h Hook",
         "The Buffer", "Auto-Flush: Timer and Idle"))
#ix("FUJIPRN.SYS", "Device driver, character", "Printer")

The companion driver, #kw("FUJIPRN.SYS"), makes the FujiNet's printer device
(ID #kw("40h")) appear to DOS as the printer #kw("LPT1"). Everything a program
prints — through DOS or through the BIOS — is captured, buffered, and
forwarded to the FujiNet, which renders it (to a PDF, for instance). It is a
smaller driver than #kw("FUJINET.SYS"), but it shows two techniques worth
study: hooking the BIOS printer interrupt, and flushing safely from idle time.

#sect[A Character Device]
#ix("Character device header")

Where #kw("FUJINET.SYS") is a block driver, #kw("FUJIPRN.SYS") is a
#strong[character] driver — a single stream, not a set of disks. Its header
differs in just two places: the attribute word sets bit 15 (#kw("8000h")) to
mark a character device, and the name/unit field carries an eight-character
#strong[device name] rather than a unit count:

#lstb(
  "_SYS_HEADER segment word public 'SYS_HEADER'",
  "        org     0",
  "_sys_hdr_ label near",
  "        extrn   Strategy_:near",
  "        extrn   Interrupt_:near",
  "        dd      -1                       ; link to next driver",
  "        dw      8000h                    ; bit 15 = character device",
  "        dw      Strategy_",
  "        dw      Interrupt_",
  "        db      'L','P','T','1',' ',' ',' ',' '   ; device name",
)

Because it names itself #kw("LPT1"), DOS routes the printer stream to it. The
strategy and interrupt routines, the request packet, and the dispatch table
are the same machinery as in #kw("FUJINET.SYS") (Section 7); only the handlers
differ. Most are no-ops — a character printer has nothing to say about media or
sectors — so this section follows only the few that matter.

#sect[Capturing Output]
#ix("OUTPUT command")

When DOS writes to the printer it calls #strong[OUTPUT] (command 8), one byte
at a time. The handler simply feeds the byte to the buffer:

#lstb(
  "uint16_t Output_cmd(SYSREQ far *req)",
  "{",
  "  if (!prn_buf_add(req->io.buffer_ptr[0]))",
  "    return ERROR_BIT | NOT_READY;",
  "  return OP_COMPLETE;",
  "}",
)

#strong[CLOSE] (14) and #strong[OUTPUT FLUSH] (11) push whatever is buffered to
the FujiNet at once; #strong[OUTPUT STATUS] (10) always answers #emph[ready].
Everything else returns #emph[unknown command].

#sect[The INT 17h Hook]
#ix("INT 17h", "BIOS printer")

DOS is not the only way to print. Many programs call the BIOS printer service,
#kw("INT 17h"), directly — bypassing the driver entirely. To catch them too,
#kw("FUJIPRN.SYS") installs its own #kw("INT 17h") handler at INIT time and
answers the three BIOS printer functions itself:

#lstb(
  "int int17(uint16_t direction, uint16_t cmdchar, ...)",
  "{",
  "  unsigned char ah = cmdchar >> 8;     // BIOS function in AH",
  "  unsigned char al = cmdchar & 0xFF;   // character in AL",
  "  switch (ah) {",
  "  case 0:  prn_buf_add(al);  return 0x9000;  // print AL; status = ready",
  "  case 1:                    return 0x9000;  // init printer",
  "  case 2:                    return 0x9000;  // read status",
  "  }",
  "  return 0;",
  "}",
)

Each returns #kw("90h") in #kw("AH") — the BIOS status bits for
#emph[selected, acknowledged, not busy] — so callers believe a real, ready
printer answered. Function 0 also buffers the character, exactly as the DOS
path does, so the two routes converge on the same buffer.

The handler is reached through a small assembly wrapper that preserves
registers, sets #kw("DS") to the driver's segment, calls the C function, and
returns with #kw("IRET"):

#lstb(
  "INTERRUPT MACRO func              ; build an interrupt wrapper",
  "        push    bx",
  "        ... push cx dx si di bp ds es ...",
  "        push    cs",
  "        pop     ds                ; DS = CS (our data segment)",
  "        call    func",
  "        ... pop es ds bp di si dx cx bx ...",
  "        iret",
  "ENDM",
  "        INTERRUPT  int17_",
)

#sect[The Buffer]
#ix("Print buffer", "Flushing")

Sending one byte per network packet would be painfully slow, so the driver
gathers bytes in a 255-byte buffer and forwards them in bursts. A burst is a
single FujiBus WRITE to the printer device:

#lstb(
  "int flush_prn_buf(void)",
  "{",
  "  int ok = 1;",
  "  if (prn_buf_len > 0) {",
  "    ok = fujiF5_write(FUJI_DEVICEID_PRINTER, FUJICMD_WRITE,",
  "                      FUJI_FIELD_NONE, 0, 0, prn_buf, prn_buf_len);",
  "    if (ok) { prn_buf_len = 0; memset(prn_buf, 0, PRN_BUF_SIZE); }",
  "  }",
  "  return ok;",
  "}",
)

A byte is added, and the buffer flushed when it nears full:

#lstb(
  "int prn_buf_add(unsigned char c)",
  "{",
  "  if (prn_buf_len >= PRN_BUF_SIZE)       // full: flush first",
  "    if (!flush_prn_buf()) return 0;",
  "  prn_buf[prn_buf_len++] = c;",
  "  if (!buffering_enabled)                // DOS < 3.0: flush every byte",
  "    return flush_prn_buf();",
  "  last_activity = timer_counter;         // note the time, for auto-flush",
  "  if (prn_buf_len >= PRN_BUF_FLUSH)       // 250 of 255: flush",
  "    flush_prn_buf();",
  "  return 1;",
  "}",
)

But a document rarely ends on a buffer boundary. The last few bytes of a print
job would sit in the buffer forever unless something flushed them — which is
what the timer is for.

#sect[Auto-Flush: Timer and Idle]
#ix("INT 08h", "INT 28h", "InDOS flag", "Re-entrancy")

The driver flushes the tail of a job automatically, a few seconds after the
printing stops. Doing so safely is the subtle part, because a flush calls into
DOS to talk to the serial port, and #strong[DOS is not re-entrant] — calling
it from a hardware interrupt while it is already busy will corrupt it.

The solution uses two interrupts and one flag. At INIT the driver hooks the
#strong[timer tick] (#kw("INT 08h"), 18.2 times a second) and the #strong[DOS
idle] interrupt (#kw("INT 28h")), and records the address of DOS's
#strong[InDOS flag] — a byte DOS keeps non-zero while it is inside itself:

#lstb(
  "void install_timer_handler(void)",
  "{",
  "  _asm { mov ah, 34h    int 21h     // INT 21h AH=34h: address of",
  "         mov indos_off, bx  mov indos_seg, es }  //   the InDOS flag",
  "  indos_flag = MK_FP(indos_seg, indos_off);",
  "",
  "  // chain onto INT 08h (timer) and INT 28h (DOS idle)",
  "  old = _dos_getvect(0x08); ...; _dos_setvect(0x08, timer_vect);",
  "  old = _dos_getvect(0x28); ...; _dos_setvect(0x28, idle_vect);",
  "",
  "  _asm { mov ah, 30h  int 21h  mov buffering_enabled, al } // DOS ver",
  "  buffering_enabled = (buffering_enabled >= 3) ? 1 : 0;    // need 3.0+",
  "}",
)

Every timer tick, the driver checks whether the buffer has been idle for five
seconds. If so — and only if DOS is #emph[not] currently busy — it flushes. If
DOS #emph[is] busy, it cannot flush now, so it sets a flag and waits for the
idle interrupt:

#lstb(
  "void timer_tick(void)        // INT 08h, 18.2 Hz",
  "{",
  "  timer_counter++;",
  "  if (prn_buf_len > 0 && (timer_counter - last_activity) >= AUTO_FLUSH_TICKS) {",
  "    if (indos_flag && *indos_flag == 0) {   // safe: DOS is idle",
  "      flush_prn_buf();",
  "      last_activity = timer_counter;",
  "    } else {",
  "      flush_pending = 1;       // DOS busy -- let INT 28h do it",
  "    }",
  "  }",
  "}",
"",
  "void idle_flush(void)         // INT 28h, raised by DOS when idle",
  "{",
  "  flush_pending = 0;",
  "  flush_prn_buf();            // here it is always safe to call DOS",
  "}",
)

DOS raises #kw("INT 28h") precisely when it is sitting idle and willing to be
re-entered — the one safe moment for a background task to call it. By deferring
to that moment whenever it finds DOS busy, the driver flushes the tail of every
print job without ever risking the system. The timer wrappers are ordinary
interrupt stubs that set #kw("DS"), call the C routine, and #strong[chain] to
the previous handler rather than returning:

#lstb(
  "timer_vect_ PROC NEAR",
  "        ... push registers; push cs; pop ds ...",
  "        call    timer_tick_",
  "        ... pop registers ...",
  "        jmp     dword ptr cs:[_old_timer_off]   ; chain to old INT 08h",
  "timer_vect_ ENDP",
)

Chaining matters: the system clock and every other timer client must still see
the tick. The driver does its small work and passes the interrupt along.


// ============================================================
// SECTION 9 — APPENDICES
// ============================================================
#chapter("Appendices", num: 9, tab: "Appendix",
  subs: ("Network Error Codes", "Status Request Types",
         "Field Descriptors", "The FujiBus Frame"))

#sect[Appendix A.  Network Error Codes]
#ix("Error codes")

When a network command returns #kw("'E'"), the detailed reason is the fourth
byte of the next STATUS reply (Section 4.2). The values:

#block(breakable: true, table(columns: (auto, 1fr, auto, 1fr),
  align: (center, left, center, left), stroke: 0.5pt + rule-c, inset: 4pt,
  table.header(
    text(weight: 700)[Code], text(weight: 700)[Meaning],
    text(weight: 700)[Code], text(weight: 700)[Meaning]),
  kw("1"), [Success], kw("167"), [Access denied],
  kw("131"), [Write-only], kw("170"), [File not found],
  kw("132"), [Invalid command], kw("200"), [Connection refused],
  kw("135"), [Read-only], kw("201"), [Network unreachable],
  kw("136"), [End of file], kw("202"), [Socket timeout],
  kw("138"), [General timeout], kw("203"), [Network down],
  kw("144"), [General error], kw("204"), [Connection reset],
  kw("146"), [Not implemented], kw("207"), [Not connected],
  kw("151"), [File exists], kw("208"), [Server not running],
  kw("162"), [No space on device], kw("210"), [Service unavailable],
  kw("165"), [Invalid devicespec], kw("212"), [Bad username/password],
))

#sect[Appendix B.  Status Request Types]
#ix("Status request types")

The control device's STATUS command (#kw("70h"), #kw("53h")) and the network
adapters' local STATUS take a request type in AUX1, selecting which value to
return:

#block(breakable: false, table(columns: (auto, 1fr),
  align: (center, left), stroke: 0.5pt + rule-c, inset: 5pt,
  table.header(text(weight: 700)[AUX1], text(weight: 700)[Returns]),
  kw("0"), [Connection / error status],
  kw("1"), [IP address — or, for the control device, mount time],
  kw("2"), [Netmask],
  kw("3"), [Gateway],
  kw("4"), [DNS server],
))

#sect[Appendix C.  Field Descriptors]
#ix("Field descriptors")

The value placed in #kw("DH"), and the number of AUX bytes it sends into the
command frame (repeated from Section 2 for reference):

#block(breakable: false, table(columns: (auto, auto, auto, 1fr),
  align: (left, center, center, left), stroke: 0.5pt + rule-c, inset: 5pt,
  table.header(text(weight: 700)[Name], text(weight: 700)[DH],
    text(weight: 700)[Bytes], text(weight: 700)[Typical use]),
  kw("FUJI_FIELD_NONE"), kw("00h"), [0], [no parameters],
  kw("FUJI_FIELD_A1"), kw("01h"), [1], [one slot or index],
  kw("FUJI_FIELD_A1_A2"), kw("02h"), [2], [two bytes, or a 16-bit length],
  kw("FUJI_FIELD_A1_A2_A3"), kw("03h"), [3], [three parameters],
  kw("FUJI_FIELD_A1_A2_A3_A4"), kw("04h"), [4], [four parameters],
  kw("FUJI_FIELD_C1234"), kw("07h"), [4], [a 32-bit value (disk sector)],
))

#sect[Appendix D.  The FujiBus Frame]
#ix("FujiBus frame")

For reference, the packet the driver builds and sends. All multi-byte fields
are little-endian. The frame is SLIP-encoded on the wire.

#block(breakable: false, table(columns: (auto, auto, 1fr),
  align: (left, center, left), stroke: 0.5pt + rule-c, inset: 5pt,
  table.header(text(weight: 700)[Field], text(weight: 700)[Bytes],
    text(weight: 700)[Meaning]),
  [device], [1], [Destination device ID],
  [command], [1], [Command code],
  [length], [2], [Total packet length, including this header],
  [checksum], [1], [Fold-add checksum of the whole packet],
  [fields], [1], [Field descriptor (how many AUX bytes follow)],
  [AUX], [0–4], [The AUX parameter bytes],
  [payload], [n], [Command data, if any],
))

The reply carries the same header with the command byte set to #kw("ACK")
(#kw("06h")) on success, followed by any data the command returns. The
driver checks the length, checksum, and device before reporting #kw("'C'").

#v(0.3in)
#align(center, line(length: 40%, stroke: 0.6pt + rule-c))
#v(0.15in)
#align(center, striped(
  text(font: f-body, weight: 700, size: 16pt, fill: ink)[FujiNet],
  stripe: paper, n: 7))
#v(3pt)
#align(center, text(size: 9pt)[github.com/FujiNetWIFI · fujinet.online])
