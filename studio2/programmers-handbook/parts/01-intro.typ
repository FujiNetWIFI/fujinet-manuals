#import "../lib.typ": *

// The cartridge on a gold panel, with its parts called out, as the booklet
// shows the console and its cords.
#let board-fig = {
  let pw = 2 * colw + gut
  let ph = 3.55in
  let bh = 3.3in
  let s = bh / 1453
  let bw = 1180 * s
  let x0 = (pw - bw) / 2
  let y0 = 0.13in
  let at(x, y) = (x0 + x * s, y0 + y * s)
  let L = x0 - 0.12in        // left labels end here
  let R = x0 + bw + 0.12in   // right labels start here
  goldpanel(inset: 0pt, box(width: pw, height: ph, {
    place(top + left, dx: x0, dy: y0, image("../images/art/board-top-cut.png", height: bh))
    let (px, py) = at(136, 45)
    callout-at([USB-C: POWER, \ AND THE S3’S CONSOLE], L, 0.3in, px, py, al: right)
    let (px, py) = at(586, 215)
    callout-at([ESP32-S3: \ THE FUJINET], L, 0.9in, px, py, al: right)
    let (px, py) = at(511, 445)
    callout-at([S3 RESET], L, 1.45in, px, py, al: right)
    let (px, py) = at(641, 805)
    callout-at([RP2354B: SERVES \ THE 1802’S BUS], L, 2.2in, px, py, al: right)
    let (px, py) = at(766, 1010)
    callout-at([BUS BUFFER], L, 2.75in, px, py, al: right)
    let (px, py) = at(1036, 115)
    callout-at([MICROSD SLOT], R, 0.3in, px, py)
    let (px, py) = at(901, 445)
    callout-at([S3 BOOT], R, 0.75in, px, py)
    let (px, py) = at(771, 445)
    callout-at([RP RESET], R, 1.02in, px, py)
    let (px, py) = at(641, 445)
    callout-at([RP BOOTSEL], R, 1.29in, px, py)
    let (px, py) = at(666, 378)
    callout-at([STATUS LIGHT], R, 1.6in, px, py)
    let (px, py) = at(1006, 945)
    callout-at([GLUE LOGIC], R, 2.3in, px, py)
    let (px, py) = at(586, 1385)
    callout-at([TO THE CARTRIDGE \ SOCKET], R, 3.05in, px, py)
  }))
}

#opener-art.update((split: 1, art: board-fig))
= Introduction to FujiNet for Studio II <intro>

The FujiNet cartridge brings the network to the RCA Studio II. Plug it into the cartridge socket and the console that shipped in 1977 with five built-in games can browse a file server, load programs from an SD card or the internet, keep the time, and play against other machines across the world.

The heart of the cartridge is two small computers. An RP2354B microcontroller answers every read the CDP1802 makes, faster than the console can ask: it serves your program, the screen the 1861 draws, and a _mailbox_ through which your program talks to the second computer. That one, an ESP32-S3, is the FujiNet itself, the same adapter that serves the Atari, the Apple II, the Coleco ADAM and a dozen other machines, with its WiFi, its SD card and its network devices.

This handbook is for the programmer. It shows how a Studio II program written in CDP1802 assembly language reaches the network through that mailbox, one read at a time, and it carries every command the FujiNet answers.

== What you should have

- A FujiNet Studio II cartridge, or the FujiNet model of it in MAME (Install the Tools, page 2).
- A computer with Python 3 and the Macroassembler AS.
- A FujiNet adapter to talk to: the cartridge’s own ESP32-S3, or fujinet-pc running on your computer.
- The listings of this handbook, which build every program it shows.

#note[No FujiNet Studio II cartridge has been built yet. Everything in this handbook was run in the cartridge’s model in MAME, which runs the cartridge’s own firmware sources. Where a real console may differ, the text says so.]

== How this handbook is organised

The first chapters explain the machine: the tools, the memory map, the mailbox, the text display, the console’s 512 bytes of RAM, the 1802 runtime every program is built on, far calls across the cartridge’s pages, and the keypads and the beeper.

The middle chapters are programs, each built and run: first contact with the adapter, the network device, a netcat, directories and booting, app keys and the clock, and glyphs, tiles and mosaics.

Four reference chapters list every command the FujiNet answers, with the parameters it wants, the reply it sends and an 1802 example. Three games follow, Battleship, 5 Card Stud and CONFIG, and the back of the book has the troubleshooting checklist, the parts list and the full listings.
