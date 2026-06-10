// ============================================================
// FujiNet CONFIG Set-Up Manual for the Coleco ADAM
// Designed after the 1983 Coleco "ADAM Set-Up Manual"
// Build: typst compile --font-path fonts manual.typ
// ============================================================

// ---------- fonts (as used in the 1983 Coleco originals) ----------
#let f-body = "ITC Avant Garde Gothic"   // Medium = body text, Bold = run-ins
#let f-serp = "Serpentine"               // Bold Oblique = headings & folios
#let f-disp = "Handel Gothic D"          // Light = display/title/step numerals

#let bb(body) = text(font: f-body, weight: 700, body)
#let serp(body) = text(font: f-serp, weight: 700, body)
#let serpo(body) = text(font: f-serp, weight: 700, style: "oblique", body)
#let hv(body) = text(font: f-disp, body)

// ---------- palette ----------
#let silver-hi = rgb("#d8d7d3")
#let silver-lo = rgb("#b4b3af")
#let cream = rgb("#fdfbf4")
#let rule-gray = rgb("#9a9890")
#let band-d = rgb("#4d4d4f")
#let band-l = rgb("#c9cacc")
#let coleco-orange = rgb("#e87511")
#let rainbow = (rgb("#e6007e"), rgb("#f7941d"), rgb("#ffd400"),
                rgb("#00a651"), rgb("#00aeef"), rgb("#92278f"))

// ---------- page geometry ----------
#let pg-w = 5.5in
#let pg-h = 8.5in

// horizontal hairlines that run across every interior page
#let page-rules = {
  for i in range(6) {
    place(top + left, dy: 1.55in + i * 1.12in,
      line(length: 100%, stroke: 0.45pt + rule-gray))
  }
}

// black corner wedge + white italic folio, Coleco style
#let folio = context {
  let p = counter(page).get().first()
  if p > 0 {
    let num = text(font: f-serp, weight: 700, style: "oblique",
                   size: 13pt, fill: white, str(p))
    if calc.even(p) {
      place(bottom + left,
        polygon(fill: black, (0pt, 0pt), (44pt, 0pt), (58pt, 14pt), (0pt, 14pt)))
      place(bottom + left, dx: 10pt, dy: -1pt, num)
    } else {
      place(bottom + right,
        polygon(fill: black, (14pt, 0pt), (58pt, 0pt), (58pt, 14pt), (0pt, 14pt)))
      place(bottom + right, dx: -10pt, dy: -1pt, num)
    }
  }
}

#let interior-bg = page-rules + folio

// ---------- components ----------

// gray gradient section banner with bold-italic title, bleeding past margins
#let banner(title) = {
  v(0.15in)
  pad(x: -0.55in,
    rect(width: 100%, height: 0.34in,
      fill: gradient.linear(band-d, band-l, band-d, angle: 0deg),
      stroke: (top: 1.2pt + black, bottom: 1.2pt + black),
      align(center + horizon,
        text(font: f-serp, weight: 700, style: "oblique", size: 13pt,
          fill: black, title))))
  v(0.22in)
}

// numbered instruction step, heavy numeral hanging left
#let step(n, body) = grid(
  columns: (0.42in, 1fr),
  column-gutter: 0.08in,
  row-gutter: 0pt,
  hv(text(size: 11pt, n)),
  body,
)

// big oblique initial letter opening a section, Coleco style
#let lead(letter, rest) = par(
  text(font: f-serp, weight: 700, style: "oblique", size: 15pt, letter) + rest)

// IMPORTANT / CAUTION / NOTE run-in
#let callout(label, body) = par(bb(label + ": ") + body)

// ---- figures ---------------------------------------------------------------
// CONFIG screenshot in a TV-style black bezel; placeholder until img exists
#let figshot(n, desc, height: 1.85in, img: none) = align(center, block(breakable: false)[
  #if img != none {
    box(fill: rgb("#1a1a1a"), radius: 5pt, inset: 7pt,
      image(img, height: height))
  } else {
    box(width: 3.4in, height: height, fill: rgb("#1a1a1a"), radius: 5pt, inset: 7pt,
      box(width: 100%, height: 100%, fill: rgb("#3a5a9a"),
          stroke: (paint: white, thickness: 0.6pt, dash: "dashed"),
          align(center + horizon,
            par(text(font: f-body, size: 7.5pt, fill: white,
              "[ SCREENSHOT " + n + " ]\n" + desc)))))
  }
  #v(2pt)
  #hv(text(size: 11pt, n))
])

// numbered photograph (tilted, black shadow slab); placeholder until img exists
#let figphoto(n, desc, height: 1.9in, angle: -4deg, img: none) = align(center,
  block(breakable: false, inset: (y: 0.12in))[
    #if img != none {
      context {
        let im = image(img, height: height)
        let size = measure(im)
        rotate(angle, reflow: true, {
          place(dx: 5pt, dy: 7pt,
            rect(width: size.width, height: size.height, fill: black))
          im
        })
      }
    } else {
      rotate(angle, reflow: true, {
        place(dx: 5pt, dy: 7pt, rect(width: 3.2in, height: height, fill: black))
        rect(width: 3.2in, height: height, fill: rgb("#cfcdc6"),
          stroke: (paint: rgb("#444444"), thickness: 0.6pt, dash: "dashed"),
          align(center + horizon,
            par(text(font: f-body, size: 7.5pt, fill: rgb("#333333"),
              "[ PHOTO " + n + " ]\n" + desc))))
      })
    }
    #v(4pt)
    #hv(text(size: 11pt, n))
  ])

// two-column key chart
#let keychart(title, ..rows) = block(breakable: false)[
  #bb(title)
  #v(3pt)
  #table(
    columns: (1.45in, 1fr),
    stroke: 0.5pt + rgb("#555555"),
    inset: 4.5pt,
    table.header(bb("PRESS"), bb("TO")),
    ..rows.pos().map(r => (text(size: 8.5pt, r.at(0)), text(size: 8.5pt, r.at(1)))).flatten()
  )
]

// glossary entry
#let gl(term, def) = par(hanging-indent: 0.25in, bb(term) + " — " + def)

// ============================================================
// DOCUMENT SETUP
// ============================================================
#set text(font: f-body, weight: 500, size: 9.3pt, fill: black)
#set par(leading: 0.52em, spacing: 0.85em, justify: false)
#set page(width: pg-w, height: pg-h, margin: (x: 0.55in, top: 0.65in, bottom: 0.55in),
  fill: cream)

// ============================================================
// COVER
// ============================================================
#page(margin: 0pt, fill: none, background: {
  // silver field
  place(rect(width: 100%, height: 100%,
    fill: gradient.linear(silver-hi, silver-lo, silver-hi, angle: 65deg)))
  // sweeping diagonal pinstripes, rising to the right, starting just
  // above the cover photo (they pass behind it); clipped so none cross
  // the heavy rule below
  place(top + left, box(width: 100%, height: 8.1in, clip: true, {
    for i in range(5) {
      place(top + left, dx: -1.2in, dy: 4.7in + i * 0.95in,
        rotate(-12deg, origin: left, line(length: 9.5in, stroke: 1.1pt + rgb("#1c1c1c"))))
    }
  }))
  // heavy black rule near the bottom edge
  place(top + left, dy: 8.1in, rect(width: 100%, height: 5pt, fill: black))
})[
  // ---- masthead: rainbow stripes behind the FujiNet logo ----
  #place(top + right, dx: -0.0in, dy: 0.35in,
    box(width: 5.5in, height: 1.05in, {
      for (i, c) in rainbow.enumerate() {
        place(top + left, dy: 0.08in + i * 0.085in,
          line(length: 100%, stroke: 1.6pt + c))
      }
      // grey transparent drop shadow lifts the wordmark off the stripes
      place(top + right, dx: -0.4in + 3.5pt, dy: -0.12in + 3.5pt,
        box(image("images/fujinet-logo-shadow.png", width: 2.9in)))
      place(top + right, dx: -0.4in, dy: -0.12in,
        box(image("images/fujinet-logo-trans.png", width: 2.9in)))
    }))
  #place(top + right, dx: -0.42in, dy: 1.42in,
    text(font: f-disp, size: 17pt, tracking: 1.5pt, "SET-UP MANUAL"))

  // ---- left text block ----
  #place(top + left, dx: 0.45in, dy: 2.1in, box(width: 4.2in)[
    #text(font: f-disp, size: 19pt, tracking: 0.6pt, "GETTING STARTED")
    #v(0.08in)
    #text(font: f-disp, size: 10.5pt)[
      Easy-to-Follow Instructions on Setting Up \
      And Using FujiNet CONFIG With Your \
      ADAM#super(text(size: 5.5pt)[TM]) Family Computer System]
    #v(0.32in)
    #text(font: f-disp, size: 13pt, "READ ME FIRST!")
  ])

  // ---- angled cover photograph ----
  #place(top + left, dx: 1.05in, dy: 4.05in, {
    rotate(-6deg, origin: center, {
      place(dx: 0.32in, dy: 0.30in, rect(width: 3.4in, height: 3.5in, fill: black))
      rect(width: 3.4in, height: 3.5in, fill: coleco-orange, inset: 0.13in,
        image("images/cover-photo.jpg", width: 100%, height: 100%, fit: "cover"))
    })
  })
]

// blank verso, like the original inside cover
#page(fill: cream)[#counter(page).update(0)]

// ============================================================
// interior pages: rules + folios begin here
// ============================================================
#set page(background: interior-bg)

// ---------- p1 : title / colophon ----------
#v(2.45in)
#align(center)[
  #text(font: f-serp, weight: 700, style: "oblique", size: 13pt)[
    FujiNet#super(text(size: 6pt)[TM]) CONFIG for the ADAM#super(text(size: 6pt)[TM]) \
    Family Computer System \
    Set-Up Manual]
  #v(0.12in)
  by The FujiNet Project Contributors
]
#v(0.25in)
Logos, illustrations and drawings Copyright #sym.copyright 2026 by the FujiNet
Project. FujiNet is free, open-source hardware and software, built by
enthusiasts, for enthusiasts.

This manual describes the CONFIG program supplied in FujiNet firmware for the
Coleco ADAM. The authors have used their best efforts in preparing this book
and the program described in it. The software is provided "as is," without
warranty of any kind, in the spirit of every home computer manual you have
ever loved.

ADAM, ColecoVision, SmartWRITER, SmartBASIC and UNIX are trademarks of
their respective owners, used here in tribute. This document is distributed under
the GNU General Public License v3, as part of the
#text(font: "DejaVu Sans Mono", size: 7.5pt, "fujinet-manuals") repository.
#align(right, text(size: 8pt, "REV 1"))

#pagebreak()

// ---------- p2 : operating hints ----------
#v(1.7in)
#align(center, serpo(text(size: 14pt, "Operating Hints")))
#v(0.18in)

#step("1.", [#bb("Power:") FujiNet draws very little power, but it is a
  computer. Switch it OFF before connecting or disconnecting the ADAMnet
  cable, and use the supplied cable or equivalent.])
#step("2.", [#bb("microSD Cards:") cards must be formatted FAT32. Insert and
  remove cards only while the FujiNet is switched OFF. Unlike digital data
  packs, an SD card is perfectly happy near your TV set.])
#step("3.", [#bb("Wireless:") FujiNet speaks 802.11 b/g/n on the 2.4 GHz band
  only. If your network is 5 GHz-only, ask your router for a 2.4 GHz
  network (most provide both).])
#step("4.", [#bb("If your FujiNet fails to operate correctly,") the worldwide
  FujiNet community answers questions on Discord at all hours. No toll-free
  number required: #text(font: "DejaVu Sans Mono", size: 8pt,
  "https://discord.gg/7MfFTvD")])

If you do encounter a problem, it is usually one of the above.

#pagebreak()

// ---------- p3 : table of contents ----------
#let toc-line(num, title, page) = grid(
  columns: (0.28in, 1fr, 0.3in),
  hv(num), [#title #box(width: 1fr, repeat(gap: 3pt)[.])], align(right)[#page])
#let toc-sub(title, page) = grid(
  columns: (0.28in, 0.18in, 1fr, 0.3in),
  [], [], [#title #box(width: 1fr, repeat(gap: 3pt)[.])], align(right)[#page])

#v(1.15in)
#align(center, hv(text(size: 12.5pt, "TABLE OF CONTENTS")))
#v(0.14in)
#text(size: 8.4pt)[
#set par(leading: 0.42em, spacing: 0.5em)
#toc-line("1", "SETTING UP", "4")
#toc-sub("Welcome!", "5")
#toc-sub("Got Everything for Your FujiNet?", "5")
#toc-sub("Know Your FujiNet", "6")
#toc-sub("Hooking Up Your FujiNet", "8")
#toc-line("2", "GETTING STARTED", "9")
#toc-sub("Turning On Your Computer", "10")
#toc-sub("Connecting to Your Wireless Network", "11")
#toc-sub("Troubleshooting", "13")
#toc-line("3", "USING HOSTS AND DISK SLOTS", "14")
#toc-sub("The Main Screen", "15")
#toc-sub("Setting Up a Host Slot", "16")
#toc-sub("Working With Disk Slots", "17")
#toc-line("4", "BROWSING AND MOUNTING DISK IMAGES", "18")
#toc-sub("Browsing a Host", "19")
#toc-sub("Filtering and Searching", "21")
#toc-sub("Mounting a Disk Image", "22")
#toc-sub("Booting Your Software", "23")
#toc-line("5", "CREATING NEW DISK IMAGES", "24")
#toc-line("6", "COPYING FILES BETWEEN HOSTS", "27")
#toc-line("7", "THE CONFIGURATION SCREEN", "29")
#toc-line("8", "USING YOUR GAME CONTROLLERS", "32")
#toc-line("9", "ROUTINE PROCEDURES", "34")
#toc-sub("Returning to CONFIG", "35")
#toc-sub("Swapping Disks With Button A", "35")
#toc-sub("Hints on Taking Care of Your FujiNet", "35")
#toc-line("10", "GLOSSARY OF COMPUTER WORDS", "36")
#toc-sub("Learning More", "39")
#toc-sub("Doing More", "39")
]

#pagebreak()

// ============================================================
// CHAPTER 1 — SETTING UP
// ============================================================
#let chapter(n, title) = {
  v(1.95in)
  align(right)[
    #serpo(text(size: 16pt, "Chapter " + n)) \
    #v(0.05in)
    #serpo(text(size: 18.5pt, title))
  ]
  pagebreak()
}

#chapter("1", "Setting Up")

#banner("Welcome!")

#lead("Y", [our FujiNet#super(text(size: 5.5pt)[TM]) is a remarkable product.
Whole libraries of ADAM#super(text(size: 5.5pt)[TM]) software served over the
air, four virtual disk drives, a wireless printer, networking for your own
programs --- FujiNet has something for every member of the family. And it's
all in one little package!])

You can use FujiNet to browse software collections on the Internet, boot any
program in seconds without swapping digital data packs, keep your own library on a tiny
memory card, and much more.

FujiNet is easy to use. The program that runs the show is called #bb("CONFIG"),
it lives inside the FujiNet itself, and your ADAM loads it automatically. This
booklet contains all the information you'll need to hook up your FujiNet and
use every function CONFIG has. And you don't need any computer-networking
experience or training to use it.

#bb("Got Everything for Your FujiNet?")

As you unpack, check that you have everything you need:

#step("1", "Your ADAM Family Computer System (or Expansion Module #3), set up and working.")
#step("2", "A FujiNet for the Coleco ADAM.")
#step("3", "An ADAMnet cable (the small square RJ12 telephone-style plug).")
#step("4", [The name of your 2.4 GHz wireless network and its password.
  Capitalization counts, so jot it down exactly.])
#step("5", [#emph[(Optional)] A microSD card formatted FAT32, for a library of
  your own.])

#pagebreak()

#banner("Know Your FujiNet")

#lead("T", [ake a moment to get acquainted. You'll find these parts on your
FujiNet --- their positions vary slightly between cases, but every ADAM
FujiNet has them:])

#figphoto("1", "", height: 2.0in, angle: -3deg, img: "images/adam-fujinet-parts.jpg")

#step("A", [#bb("ADAMNET IN jack.") Connects to your ADAM. This is FujiNet's
  lifeline --- data and power arrive through it.])
#step("B", [#bb("ADAMNET OUT jack.") A pass-through, so any device that used
  to occupy your ADAMnet port can plug in behind the FujiNet and keep
  working.])
#step("C", [#bb("microSD slot.") Push a card in until it clicks; push again
  to release.])
#step("D", [#bb("Power switch.") FujiNet ON and OFF.])
#step("E", [#bb("Indicator lights.") #bb("WiFi") (white) glows when connected
  to your network. #bb("BT") (blue) signals Bluetooth mode. #bb("Bus")
  (orange) flickers along with ADAMnet activity.])
#step("F", [#bb("Button A.") A short press rotates your mounted disk images
  one slot forward --- the famous "disk swap" button. (See Chapter 9.)])
#step("G", [#bb("Button B.") Hold a few seconds to restart the FujiNet.])
#step("H", [#bb("Safe Reset button.") A short press restarts the FujiNet
  safely.])
#step("I", [#bb("micro-USB port.") Used to flash new firmware from a PC, and
  as an alternate power source.])

#pagebreak()

#banner("Hooking Up Your FujiNet")

Complete the steps below to connect FujiNet to your ADAM.

#step("1", "Turn your ADAM OFF (the switch on the back of the printer).")
#step("2", [Plug one end of the ADAMnet cable into the jack marked
  #bb("ADAMNET IN") on the FujiNet.])
#step("3", "Plug the other end into the ADAMnet port on your ADAM.")
#step("4", [If another device was using that port, plug it into FujiNet's
  #bb("ADAMNET OUT") jack.])
#step("5", "If you have a microSD card, insert it until it clicks.")
#step("6", "Slide the FujiNet's power switch to ON.")

#figphoto("2", "", height: 1.8in, angle: 3deg, img: "images/adam-fujinet-hookup.jpg")

#callout("IMPORTANT", [DO NOT TURN ON THE COMPUTER SYSTEM YET. Turn to the
next chapter for those directions.])

#pagebreak()

// ============================================================
// CHAPTER 2 — GETTING STARTED
// ============================================================
#chapter("2", "Getting Started")

#banner("Turning On Your Computer")

#lead("W", [hether you have the ADAM Family Computer System or Expansion
Module #3, you follow the same steps to bring up CONFIG. Complete the steps
listed below.])

#step("1", [Make sure there is #bb("no") digital data pack in the data drive,
  no disk in the disk drive, and no game cartridge in the cartridge slot.])
#step("2", "Turn on the TV and select the proper channel (3 or 4).")
#step("3", [Turn the ADAM on --- or, if it is already on, pull the
  #bb("COMPUTER RESET") switch toward you.])
#step("4", [Watch the screen. In a moment you'll hear a cheerful chime and see
  #bb("WELCOME TO FUJINET") at the bottom of your screen. The ADAM has booted
  CONFIG directly from your FujiNet --- no digital data pack required.])

#callout("NOTE", [If software is already mounted in disk slot 1 from an
earlier session, the ADAM boots that instead. Chapter 9 shows how to return
to CONFIG.])

#bb("The SmartKeys")

CONFIG is operated mostly with the ADAM's six #bb("SmartKeys") --- the dark
keys numbered I through VI across the top of your keyboard. The bottom of
every CONFIG screen shows a row of labeled boxes; each box lines up with one
SmartKey, and a blank box means that key does nothing right now. This manual
writes them as #bb("[ I ]") through #bb("[ VI ]").

#pagebreak()

#banner("Connecting to Your Wireless Network")

#lead("T", [he first time FujiNet starts, CONFIG goes straight into network
setup --- it scans the air and announces #bb("SCANNING FOR NETWORKS...") If
your FujiNet has connected before, it reconnects by itself and you may skip
to Chapter 3.])

After the scan, the wireless networks FujiNet found (up to 16) are listed on
your screen:

#figshot("3", "", img: "images/config-wifi-scan.png")

#list(
  [Each network shows a one-to-three bar #bb("signal-strength meter.") More
   bars, better signal.],
  [Your FujiNet's #bb("MAC address") is printed at the top of the screen ---
   useful if your router restricts which devices may join.],
)

#keychart("ON THE NETWORK LIST",
  ("↑ / ↓", "Move the highlight bar"),
  ("RETURN", "Choose the highlighted network"),
  ("[ IV ] HIDDEN SSID", "Type the name of a network that hides itself"),
  ("[ V ] RESCAN", "Search the air again"),
  ("[ VI ] SKIP", "Go to the main screen without connecting"),
)

#pagebreak()

#bb("Entering Your Network Password")

#step("1", [Highlight your network with the arrow keys and press
  #bb("RETURN").])
#step("2", [CONFIG asks: #bb("ENTER NETWORK PASSWORD AND PRESS [RETURN].")
  Type the password --- up to 64 characters, capitals and all. Each character
  appears as a smudge so onlookers can't read it. #bb("BACKSPACE") fixes
  mistakes.])
#step("3", [Press #bb("RETURN"). CONFIG announces #bb("CONNECTING TO NETWORK")
  and tries for several seconds. Press #bb("ESCAPE/WP") to abort.])

#figshot("4", "", img: "images/config-wifi-password.png")

If you pressed #bb("[ IV ] HIDDEN SSID"), CONFIG first asks for the network's
name (up to 32 characters), then continues with the password as above.

#bb("What you'll see next")

#step("a.", [#bb("CONNECTION SUCCESS!") --- You're online. FujiNet remembers
  this network and will rejoin it automatically every time it powers up. The
  main screen appears.])
#step("b.", [#bb("CONNECT FAILED"), #bb("NO SSID AVAILABLE"),
  #bb("CONNECTION LOST") or #bb("UNABLE TO CONNECT") --- the connection
  didn't take, and CONFIG returns to the network list. Nine times out of ten
  the password was mistyped; choose your network and try again carefully.])

#pagebreak()

#banner("Troubleshooting")

#lead("S", [ometimes you don't get the result you expected when you turn on
your computer. Most difficulties are easy to resolve. Refer to the chart
below to remedy any problem.])

#v(0.1in)
#context {
let chart = table(
  columns: (1.25in, 1.35in, 1.6in),
  stroke: 0.6pt + black,
  fill: cream,
  inset: 4pt,
  table.header(bb("Symptom"), bb("Cause"), bb("Remedy")),
  ..(
    ("ADAM boots the electronic typewriter, not CONFIG",
     "FujiNet off, or cable loose",
     "Check FujiNet's power switch and the ADAMnet cable; pull COMPUTER RESET"),
    ("", "Boot media in a drive", "Remove data packs, disks and cartridges; reset"),
    ("ADAM boots old software instead of CONFIG",
     "An image is still mounted in disk slot 1",
     "Restart the FujiNet, then pull COMPUTER RESET (Chapter 9)"),
    ("No networks found", "Network is 5 GHz-only or out of range",
     "FujiNet sees 2.4 GHz networks only; enable 2.4 GHz on the router or move closer"),
    ("", "Network is hidden", "Use [ IV ] HIDDEN SSID and type the name"),
    ("CONNECT FAILED or UNABLE TO CONNECT", "Wrong password",
     "Re-enter carefully; capitalization counts"),
    ("", "Router restrictions",
     "Check MAC filtering against the MAC address shown on the scan screen"),
  ).map(r => r.map(c => text(size: 7.3pt, c))).flatten()
)
let size = measure(chart)
block(breakable: false, {
  place(dx: 5pt, dy: 7pt, rect(width: size.width, height: size.height, fill: black))
  chart
})
}

#pagebreak()

// ============================================================
// CHAPTER 3 — USING HOSTS AND DISK SLOTS
// ============================================================
#chapter("3", "Using Hosts\nand Disk Slots")

#banner("The Main Screen")

#lead("E", [verything in CONFIG begins at the main screen. The top half lists
your eight #bb("HOST SLOTS") --- remembered places that software comes from.
The bottom half lists your four #bb("DISK SLOTS") --- the virtual drives your
ADAM sees. Press #bb("TAB") to jump between the halves.])

#figshot("5", "", height: 1.55in, img: "images/config-main-hosts.png")

A #bb("host") is most often a #bb("TNFS server") on the Internet --- a
computer that shares a library of ADAM software, such as
#text(font: "DejaVu Sans Mono", size: 8pt, "fujinet.online") --- or the
microSD card in your FujiNet (the special name
#text(font: "DejaVu Sans Mono", size: 8pt, "SD")). Web, SMB, NFS and FTP
servers work too (next section). Empty slots read #bb("EMPTY").

Each #bb("disk slot") shows the disk image mounted in it, or #bb("EMPTY"), or
#bb("OFF") if you have disabled that drive. The slot's number sits on a
colored tile: #bb("blue") means the image is mounted read-only, #bb("green")
means read/write.

#keychart("ON THE HOST SLOTS (TOP) HALF",
  ("↑ / ↓  or  1–8", "Move to a host slot"),
  ("RETURN", "Open the highlighted host and browse it (Chapter 4)"),
  ("TAB", "Jump to the disk slots"),
  ("[ IV ] SHOW CONFIG", "Display FujiNet's network details (Chapter 7)"),
  ("[ V ] EDIT SLOT", "Type a new host name into the slot"),
  ("[ VI ] BOOT", "Leave CONFIG and boot what's mounted (Chapter 4)"),
)

#pagebreak()

#banner("Setting Up a Host Slot")

To tell FujiNet where your software lives, put a name in a host slot:

#step("1", "Highlight a host slot with the arrow keys (or press its number, 1–8).")
#step("2", [Press #bb("[ V ] EDIT SLOT"). CONFIG prompts: #bb("EDIT THE HOST
  NAME FOR SLOT") followed by the slot number.])
#step("3", [Type the host's name and press #bb("RETURN"). #bb("BACKSPACE")
  erases.])

Host slots speak several protocols --- what you type tells FujiNet what kind
of server to reach:

#let mono(s) = text(font: "DejaVu Sans Mono", size: 7.2pt, s)
#table(
  columns: (1.55in, 1fr),
  stroke: 0.5pt + rgb("#555555"),
  inset: 4pt,
  table.header(bb(text(size: 8.5pt, "YOU TYPE")),
               bb(text(size: 8.5pt, "FUJINET CONNECTS TO"))),
  ..(
    (mono("SD"), [The microSD card in your FujiNet]),
    ([#mono("fujinet.online")\ (any plain name or IP)],
     [A #bb("TNFS") software server --- the default when no protocol is given]),
    (mono("http://server/path"), [A web server --- its index page is read and
      presented as a browsable folder]),
    (mono("smb://server/share"), [A Windows (SMB) file share;
      #mono("user:password@") may be included]),
    (mono("nfs://server/export"), [An NFS server]),
    (mono("ftp://server"), [An FTP server]),
  ).map(r => (r.at(0), text(size: 8.3pt, r.at(1)))).flatten()
)

#figshot("6", "", height: 1.3in, img: "images/config-edit-host.png")

To clear a slot, edit it and backspace the name away, then press
#bb("RETURN") --- the slot reads #bb("EMPTY") again.

#callout("IMPORTANT", [Changing or clearing a host slot automatically ejects
any disk images that were mounted from it, since they can no longer be
reached.])

#pagebreak()

#banner("Working With Disk Slots")

Press #bb("TAB") to move the highlight into the DISK SLOTS half:

#figshot("7", "", height: 1.6in, img: "images/config-main-disks.png")

#keychart("ON THE DISK SLOTS (BOTTOM) HALF",
  ("↑ / ↓  or  1–4", "Move to a disk slot"),
  ("TAB", "Jump back to the host slots"),
  ("[ IV ] EJECT", "Unmount the image in the highlighted slot"),
  ("[ V ] ON/OFF TOGGLE", "Enable or disable that virtual drive"),
  ("[ VI ] BOOT", "Leave CONFIG and boot what's mounted"),
  ("CLEAR", "Eject ALL disk slots at once"),
)

#bb("About ON/OFF.") This one is for owners of real ADAM disk drives. If a
physical drive answers at the same ADAMnet address as one of FujiNet's
virtual drives, switch that slot #bb("OFF") so the two don't quarrel. A slot
showing OFF ignores everything until you toggle it back on. Press
#bb("[ V ]") on the highlighted slot to flip it.

#bb("Long names.") If a mounted image's filename is too long for its row, the
full name appears in the open area beneath the disk slots.

When you press #bb("CLEAR"), CONFIG announces #bb("CLEARING ALL SLOTS...")
and every slot returns to EMPTY. The image files themselves are never harmed
by ejecting --- you are only taking the digital data pack out of the drive.

#pagebreak()

// ============================================================
// CHAPTER 4 — BROWSING AND MOUNTING
// ============================================================
#chapter("4", "Browsing and\nMounting Disk Images")

#banner("Browsing a Host")

#lead("H", [ighlight a host slot and press #bb("RETURN"). CONFIG says
#bb("OPENING...") and presents the host's files, fifteen to a page, with the
host's name and your current folder path across the top.])

#figshot("8", "", img: "images/config-browser.png")

Every entry carries a little icon telling you what it is: a #bb("folder"), a
#bb("DDP") (data pack image), a #bb("DSK") (disk image), or a #bb("ROM"). A
#bb("[...]") mark at the top or bottom of the list means more entries lie in
that direction. Rest the highlight on a long name for a moment and the full
name appears at the bottom of the screen.

#keychart("IN THE FILE BROWSER",
  ("↑ / ↓", "Move the highlight (rolls onto the next page)"),
  ("CONTROL + ↑ / ↓", "Jump a whole page at a time"),
  ("HOME", "Back to the top of the list"),
  ("RETURN", "Open the highlighted folder, or pick the file"),
  ("[ IV ] UP", "Up to the parent folder (hidden at the top level)"),
  ("[ V ] FILTER", "Show only matching files; search the whole host"),
  ("[ VI ] BOOT", "Mount the highlighted image in slot 1 and boot it NOW"),
  ("INSERT", "Create a brand-new blank disk image (Chapter 5)"),
  ("MOVE/COPY", "Copy the highlighted file to another host (Chapter 6)"),
  ("ESCAPE/WP", "Back to the main screen"),
)

#bb("Link entries.") On some public servers you may see entries marked with a
#bb("+"). These are doorways to #emph[other] TNFS hosts: choose one and CONFIG
connects there and keeps browsing. (The linked host's name lands in host slot
8, so it will be on your main screen afterward, too.)

#pagebreak()

#banner("Filtering and Searching")

When a host holds hundreds of files, let CONFIG do the digging. Press
#bb("[ V ] FILTER") in the browser. CONFIG prompts:

#align(center, bb("ENTER A WILDCARD FILTER.\nE.G. *Coleco*, or !TERM FOR SEARCH."))

#step("1", [A pattern with #bb("*") wildcards --- like
  #text(font: "DejaVu Sans Mono", size: 8.5pt)[\*Coleco\*] or
  #text(font: "DejaVu Sans Mono", size: 8.5pt)[Donkey\*] --- narrows the
  current folder to names that match.])
#step("2", [A pattern starting with #bb("!") --- like
  #text(font: "DejaVu Sans Mono", size: 8.5pt)[!zork] --- #bb("searches the
  entire host"), top to bottom, and lists every file containing that term,
  wherever it hides.])
#step("3", "Enter a blank filter to see everything again.")

#figshot("9", "", height: 1.45in, img: "images/config-filter.png")

While a filter is active it is shown in the top-right corner of the browser,
so you'll always know why a folder looks short.

#pagebreak()

#banner("Mounting a Disk Image")

Mounting an image is just like putting a data pack in the drive --- without
getting up. Highlight a disk image in the browser and press #bb("RETURN").
CONFIG presents #bb("FILE DETAILS") --- the file's name, date, and size ---
with your four disk slots below:

#figshot("10", "", img: "images/config-select-slot.png")

#keychart("ON THE FILE DETAILS SCREEN",
  ("↑ / ↓  or  1–4", "Choose a disk slot"),
  ("RETURN  or  [ V ]", "Mount the image READ ONLY (safe)"),
  ("[ VI ]", "Mount the image READ/WRITE (programs can save to it)"),
  ("[ IV ] EJECT", "Empty the highlighted slot first, if you need room"),
  ("ESCAPE/WP", "Abort, back to the main screen"),
)

After mounting, CONFIG returns you to the browser in the same folder, so you
can mount more disks into other slots. Press #bb("ESCAPE/WP") when you're
done.

#callout("HINT", [Mount read-only unless you know the software saves onto its
own disk. A read-only image can be shared by everyone on a server at once,
and no stray write can ever damage it.])

#pagebreak()

#banner("Booting Your Software")

There are two ways to start what you've mounted:

#step("1", [#bb("BOOT.") From either half of the main screen, press
  #bb("[ VI ] BOOT"). CONFIG mounts everything in your disk slots, steps out
  of the way, and restarts the ADAM. The ADAM boots from disk slot 1 exactly
  as if a real data pack were in the drive.])
#step("2", [#bb("QUICK BOOT.") In the browser, highlight a disk image and
  press #bb("[ VI ]"). The image is mounted into slot 1, read-only, and
  booted immediately. Browse, pick, play.])

Your disk slots are remembered inside the FujiNet, so the same software
boots again next time --- until you eject it or mount something else.

#callout("NOTE", [When some slots are already occupied the browser's smartkey
reads #bb("BOOT"); when all are empty it reads #bb("QUICK BOOT"). Both do the
same convenient thing to the file you have highlighted.])

#pagebreak()

// ============================================================
// CHAPTER 5 — CREATING NEW DISK IMAGES
// ============================================================
#chapter("5", "Creating New\nDisk Images")

#banner("Creating New Disk Images")

#lead("C", [ONFIG can manufacture blank media out of thin air --- on your SD
card, or on any TNFS server that allows writing. Browse to the folder where
the new image should live, then:])

#step("1", [Press #bb("INSERT"). CONFIG asks: #bb("NEW MEDIA: SELECT MEDIA
  TYPE.") Press #bb("[ V ] DDP") for a digital data pack image or
  #bb("[ VI ] DISK") for a disk image. (Any other key cancels.)])
#step("2", [#bb("SIZE?") Pick a capacity with the SmartKeys:
  #list(
    [#bb("DDP:")  128K, 256K or 320K --- or CUSTOM. 256K is the most
     common choice: the size of a standard digital data pack.],
    [#bb("DISK:") 160K, 320K, 720K or 1440K --- or CUSTOM. 160K is the
     most common: the size of a standard Coleco Disk Drive disk.],
  )
  #bb("CUSTOM") asks you to type the size as a number of 1K blocks.])
#step("3", [#bb("PLEASE ENTER A FILENAME FOR THIS DISK/DDP:") Type a name ---
  give it a #text(font: "DejaVu Sans Mono", size: 8.5pt)[.ddp] or
  #text(font: "DejaVu Sans Mono", size: 8.5pt)[.dsk] ending to match its
  type --- and press #bb("RETURN"). A blank name cancels.])
#step("4", [Choose a disk slot and press #bb("RETURN"). CONFIG announces
  #bb("CREATING FILE... PLEASE WAIT.") The image is mounted read/write.])
#step("5", [#bb("DO YOU WISH TO WRITE AN EOS DIRECTORY TO THIS IMAGE?")
  Press #bb("[ V ] YES") to format it for EOS --- SmartBASIC, SmartWriter and
  friends --- or #bb("[ VI ] NO") to leave it blank (for CP/M and other
  uses).])
#step("6", [If you chose YES: #bb("ENTER A VOLUME LABEL (12 CHARACTERS MAX)"),
  then #bb("RETURN"). CONFIG writes the directory: #bb("CREATING THE
  DIRECTORY. PLEASE WAIT.")])

#figshot("11", "", height: 1.3in, img: "images/config-new-image.png")

You return to the main screen with a fresh, formatted, writable disk in its
slot --- ready for SmartBASIC's SAVE command.

#pagebreak()

// ============================================================
// CHAPTER 6 — COPYING FILES
// ============================================================
#chapter("6", "Copying Files\nBetween Hosts")

#banner("Copying Files Between Hosts")

#lead("G", [rab a game from a server in Poland and keep it on the card in
your FujiNet --- CONFIG copies files from any host to any writable host.
Server to SD, SD to server, even server to server:])

#step("1", "Browse to the file you want, and highlight it.")
#step("2", [Press the #bb("MOVE/COPY") key. (The original file is never
  altered.)])
#step("3", [#bb("COPY TO HOST SLOT") --- your eight host slots are listed.
  Choose the destination host with #bb("1–8") or the arrows and press
  #bb("RETURN"). (#bb("ESCAPE/WP") aborts.)])
#step("4", [The destination host opens in the browser, and the status line
  reads #bb("SELECT DESTINATION.") Walk to the folder where the copy should
  go --- #bb("[ V ] FILTER") works here too.])
#step("5", [Press #bb("[ VI ] PERFORM COPY"). CONFIG shows #bb("COPYING
  FILE...PLEASE WAIT.") with the source above and the destination below.])

#figshot("12", "", img: "images/config-copy.png")

When the copy finishes, you are returned to the folder you copied from ---
handy for collecting several files in one sitting.

#callout("NOTE", [The destination must allow writing. Public servers are
usually read-only; your SD card is always willing.])

#pagebreak()

// ============================================================
// CHAPTER 7 — CONFIGURATION SCREEN
// ============================================================
#chapter("7", "The Configuration\nScreen")

#banner("The Configuration Screen")

#lead("F", [rom the main screen's host half, press #bb("[ IV ] SHOW CONFIG")
to see exactly how your FujiNet is faring on the network:])

#figshot("13", "", height: 2.0in, img: "images/config-info.png")

#table(
  columns: (0.95in, 1fr),
  stroke: 0.5pt + rgb("#555555"),
  inset: 4pt,
  ..(
    ("SSID", "The wireless network FujiNet is connected to"),
    ("HOSTNAME", "FujiNet's name on your network"),
    ("IP", "FujiNet's address on your network"),
    ("NETMASK", "Your network's subnet mask"),
    ("DNS", "The name server FujiNet uses"),
    ("MAC", "FujiNet's hardware address"),
    ("BSSID", "Your Wi-Fi access point's hardware address"),
    ("FNVER", "FujiNet firmware version and build date"),
  ).map(r => (bb(text(size: 8.5pt, r.at(0))), text(size: 8.5pt, r.at(1)))).flatten()
)

#keychart("ON THE CONFIGURATION SCREEN",
  ("[ IV ] PRINTER? YES/NO", "Toggle FujiNet's virtual printer"),
  ("[ V ] CHANGE SSID", "Forget this network; run network setup again"),
  ("[ VI ] RECONNECT", "Drop and re-join the current network"),
  ("RETURN / ESC / SPACE", "Back to the main screen"),
)

#pagebreak()

#bb("About the printer toggle.") Set to #bb("YES"), FujiNet answers as the
ADAM's printer and quietly captures everything your programs print; view and
save the output from FujiNet's web page. Set it to #bb("NO") to let your
SmartWRITER#super(text(size: 5.5pt)[TM]) printer receive output as usual.

#bb("The web page.") Type the IP address shown on this screen into a web
browser on any computer or phone in your house --- for example
#text(font: "DejaVu Sans Mono", size: 8.5pt)[http://192.168.1.123/] --- and
FujiNet's full configuration site appears: captured printer output, host and
slot management, firmware settings, and much more. It is the deluxe
companion to the CONFIG program you are reading about.

#v(0.2in)
#align(center, serpo(text(size: 11pt, "A FujiNet in every home!")))

#pagebreak()

// ============================================================
// CHAPTER 8 — GAME CONTROLLERS
// ============================================================
#chapter("8", "Using Your\nGame Controllers")

#banner("Using Your Game Controllers for CONFIG")

#lead("Y", [our ADAM's game controllers may also be used to drive CONFIG ---
from the comfort of your couch. Just be sure they are attached to their
controller ports. Their uses are as follows:])

#figphoto("14", "", height: 2.1in, angle: 4deg, img: "images/adam-controller.jpg")

#list(
  [Push the #bb("joystick up or down") (hold it a moment) to move the
   highlight bar on any CONFIG screen.],
  [Press #bb("either fire button") --- it acts just like #bb("RETURN").],
  [Press #bb("1 through 8 on the keypad") to jump straight to that host or
   disk slot.],
  [Press the #bb("✱ key") on the keypad to BOOT --- the same as
   #bb("[ VI ]").],
)

Either controller port will do. Consult Chapter 3 and Chapter 4 to see what
RETURN and BOOT accomplish on each screen.

#pagebreak()

// ============================================================
// CHAPTER 9 — ROUTINE PROCEDURES
// ============================================================
#chapter("9", "Routine Procedures")

#banner("Returning to CONFIG")

After you press BOOT, CONFIG politely steps aside until the FujiNet is
restarted. To get back:

#step("1", [Press the FujiNet's #bb("Safe Reset") button --- or switch the
  FujiNet off and on.])
#step("2", [Pull the ADAM's #bb("COMPUTER RESET") switch.])

The ADAM boots into CONFIG with your hosts and mounted images just as you
left them.

#banner("Swapping Disks With Button A")

When a program asks you to "insert disk 2 and press RETURN," don't get up:

#step("1", [Press FujiNet's #bb("Button A") briefly. Every mounted image
  rotates one slot forward --- slot 2's image slides into slot 1, slot 3's
  into slot 2, and so on, around the horn.])
#step("2", "Continue in your program as if you had swapped the media by hand.")

Mount all of a program's disks into slots 1 through 4 before booting, and
multi-disk software becomes a one-button affair.

#banner("Hints on Taking Care of Your FujiNet")

#step("1.", [Switch the FujiNet OFF before connecting or disconnecting the
  ADAMnet cable, and before inserting or removing the microSD card.])
#step("2.", [Keep firmware fresh. New features and fixes arrive regularly;
  flash updates over the micro-USB port using the FujiNet Flasher from
  #text(font: "DejaVu Sans Mono", size: 8pt, "fujinet.online/download").])
#step("3.", [The FujiNet contains no user-serviceable parts --- but unlike
  1983, the schematics are free. See the fujinet-hardware repository if you
  enjoy a soldering iron.])

#pagebreak()

// ============================================================
// CHAPTER 10 — GLOSSARY
// ============================================================
#chapter("10", "Glossary of\nComputer Words")

#banner("Glossary of Computer Words")

#gl("ADAMnet", [the ADAM's built-in network of peripherals (keyboard, drives,
  printer). FujiNet joins it as several devices at once.])
#gl("CONFIG", [the program this manual is about: FujiNet's control panel,
  booted by the ADAM directly from the FujiNet.])
#gl("DDP", [a Digital Data Pack image file --- an entire ADAM digital data
  pack, captured in a single file.])
#gl("Disk image", [a complete digital data pack or disk stored as one file
  (.ddp, .dsk, .rom).])
#gl("Disk slot", [one of FujiNet's four virtual drives. Whatever is mounted
  in disk slot 1 is what the ADAM boots.])
#gl("EOS", [the Elementary Operating System --- the ADAM's native operating
  system. "Writing an EOS directory" formats an image so EOS programs can
  store files on it.])
#gl("FTP", [the File Transfer Protocol, a longtime Internet standard for
  moving files. A host slot beginning #text(font: "DejaVu Sans Mono",
  size: 8pt, "ftp://") browses an FTP server.])
#gl("Host", [a place disk images live: a TNFS, web (HTTP), SMB, NFS or FTP
  server --- or the microSD card in your FujiNet.])
#gl("Host slot", [one of the eight remembered host names on CONFIG's main
  screen.])
#gl("HTTP", [the protocol of the World Wide Web. A host slot beginning
  #text(font: "DejaVu Sans Mono", size: 8pt, "http://") or
  #text(font: "DejaVu Sans Mono", size: 8pt, "https://") reads a web
  server's index page and presents it as a browsable folder.])
#gl("MAC address", [a hardware serial number identifying your FujiNet to the
  network.])
#gl("Mount", [to load a disk image into a disk slot --- the electronic
  equivalent of inserting a digital data pack and closing the drive door.])
#gl("NFS", [the Network File System, a file-sharing protocol commonly used
  on UNIX#super(text(size: 5pt)[TM]) systems. A host slot beginning
  #text(font: "DejaVu Sans Mono", size: 8pt, "nfs://") browses an NFS
  server's export.])
#gl("Read-only / read-write", [whether programs may change a mounted image.
  Blue slot number: read-only. Green: read-write.])
#gl("SMB", [Server Message Block, the file-sharing protocol of Microsoft
  Windows. A host slot beginning #text(font: "DejaVu Sans Mono", size: 8pt,
  "smb://") browses a Windows shared folder.])
#gl("SSID", [the broadcast name of a wireless network --- the name you pick
  from CONFIG's network list.])
#gl("TNFS", [the Trivial Network File System, the simple, friendly protocol
  FujiNet uses to browse software servers over the Internet.])
#gl("Wi-Fi", [wireless networking. FujiNet uses the 2.4 GHz flavor
  (802.11 b/g/n).])

#pagebreak()

#banner("Learning More")

#list(
  [#bb("FujiNet web site:")
   #text(font: "DejaVu Sans Mono", size: 8pt, "https://fujinet.online/")],
  [#bb("Firmware, downloads, wiki:")
   #text(font: "DejaVu Sans Mono", size: 8pt,
     "https://github.com/FujiNetWIFI/fujinet-firmware")],
  [#bb("Community Discord:")
   #text(font: "DejaVu Sans Mono", size: 8pt, "https://discord.gg/7MfFTvD")
   --- the fastest place to get help, day or night.],
  [#bb("Flashing & updating:")
   #text(font: "DejaVu Sans Mono", size: 8pt,
     "https://fujinet.online/download/")],
)

#banner("Doing More")

CONFIG is only the beginning. FujiNet-aware ADAM software can read the time
from the Internet, fetch weather reports, print to modern printers, play
multi-player games against other FujiNet owners on Ataris and Apples, and
write its own network programs through the N: device. Visit the web site and
the Discord to see what the community is building --- and to show off what
you build.

#v(0.35in)
#align(center, serpo(text(size: 12pt, "Welcome to the FujiNet family.\nHappy computing!")))
