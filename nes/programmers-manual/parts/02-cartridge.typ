#import "../lib.typ": *

= The Cartridge

#lead[Most cartridges that load games from somewhere else put a programmable
logic chip between the NES and its memory. This one puts real memory there,
and lets a microcontroller watch.]

== The design in one picture

#fig(caption: [The FujiNet NES cartridge and the FujiNet it talks to.],
  flow(
    nodebox("NES", sub: [2A03 CPU\ 2C02 PPU], w: 0.95in),
    biarrow(w: 30pt, label: [cart edge]),
    box(stroke: 0.6pt + ink, inset: 6pt, stack(dir: ttb, spacing: 5pt,
      caps("FujiNet cartridge", size: 6.8pt),
      stack(dir: ltr, spacing: 5pt,
        nodebox("RP2354B", sub: [mailbox, loader,\ bank tables], w: 0.95in),
        stack(dir: ttb, spacing: 4pt,
          nodebox("PRG SRAM", sub: [512K], w: 0.75in),
          nodebox("CHR SRAM", sub: [512K], w: 0.75in))))),
    biarrow(w: 30pt, label: [USB]),
    nodebox("ESP32-S3", sub: [FujiNet\ firmware], w: 0.85in),
    biarrow(w: 30pt, label: [WiFi]),
    nodebox("Internet", sub: [servers,\ TNFS hosts], w: 0.8in)))

The cartridge holds three chips that matter to a programmer:

#runin(
  ("Two 512K static RAMs", [stand in for the PRG ROM and the CHR ROM of an
   ordinary cartridge. The console addresses them itself, at full speed, so
   a game running from them cannot tell they are not ROM.]),
  ("An RP2354B microcontroller", [watches every write the CPU makes, and when
   a write lands on a mapper register it changes the high address lines of the
   two RAMs, so the cartridge banks the way the game's original board did. It
   also serves 4K of its own memory at `$5000` -- the *mailbox* and a small
   loader -- and 8K of work RAM at `$6000`.]),
  ("A USB link", [to an ESP32-S3 running the FujiNet firmware. The RP2354B
   turns what your program writes into the mailbox into FujiBus packets, sends
   them over USB, and paints the answer back into the mailbox.]),
)

The design follows the memory architecture of the original EverDrive N8 --
two SRAMs behind the cartridge edge -- with the RP2354B's programmable I/O
state machines doing the banking. Each bank table is a handful of
instructions that the mapper code rewrites in one store; it takes about 45 ns
for a bank change to reach the RAMs, against 372 ns for a PPU memory access.

== The memory map

This is what your program sees between `$4020` and `$FFFF`:

#fig(caption: [The cartridge's half of the CPU address space.],
  memmap((
    (0x5000, 0x53FF, "REPLY WINDOW", true, [1K: the last reply, cart-painted]),
    (0x5400, 0x54FF, "STATUS PAGE", true, [ACKSEQ, errors, boot progress]),
    (0x5500, 0x55FF, "REGISTERS", false, [`STA $5500+n` sets register n]),
    (0x5600, 0x56FF, "(RAW REGDATA)", false, [not used by programs]),
    (0x5700, 0x57FF, "TX STREAM", false, [any store appends one byte]),
    (0x5800, 0x5FFF, "LOADER ROM", true, [2K, cart-served]),
    (0x6000, 0x7FFF, "WORK RAM", false, [8K, cart-served]),
    (0x8000, 0xFFFF, "PRG SRAM", false, [your program, through the mapper]),
  ), scale: 0.0016pt, minh: 13pt))

Below `$5000` the cartridge answers nothing: `$4020-$4FFF` is open bus. The
pages from `$5000` to `$57FF` are the mailbox, described in Chapter 4. The
cartridge also serves the reset vectors at `$FF00-$FFFF` while its SRAMs are
switched off, which is how it starts.

== Power on

When the console powers up the SRAMs are empty and switched off. The
RP2354B answers the CPU's reset-vector fetch itself, pointing it at the
*loader ROM* at `$5800`. The loader copies CONFIG -- a 32K NES program baked
into the cartridge's flash -- into the SRAMs, 1K at a time, and jumps to it.
This takes about a sixth of a second.

CONFIG is the cartridge's menu (Chapter 16). When you pick a game, CONFIG
asks the FujiNet to fetch the image; the FujiNet pushes it over USB into a
staging store on the cartridge; and the same loader copies it into the SRAMs
and starts it -- about 9.5 CPU cycles a byte, so a 512K-plus-256K game takes
four seconds. Chapter 8 shows how to do this from your own program.

== The claim

A commercial game knows nothing about the mailbox, and may well have its own
use for `$5000-$5FFF`. So after the loader starts an image, the cartridge
looks for a four-byte signature, `FUJI`, in the last 16 bytes of its PRG --
console address `$FFF0`, just below the vectors.

#caution[An image without the claim gets no mailbox. The cartridge stops
answering `$5000-$57FF` for the rest of the session (the loader at `$5800`
stays), and every transaction your program tries simply never completes.
Chapter 3 shows the linker configuration that reserves the space, and the
tool that writes it.]

The same thing happens to an image whose mapper decodes `$5000-$5FFF`
itself, since the two cannot share the bus.

== Mappers

A FujiNet program can use any mapper the cartridge implements. The simplest,
and the one every program in this manual uses, is mapper 0, NROM: 32K of
PRG at `$8000-$FFFF` and 8K of CHR, no banking at all.

#tbl((auto, auto, 1fr),
  th[No.], th[Board], th[Notes],
  [0], [NROM], [32K PRG, 8K CHR ROM or RAM],
  [1], [MMC1 (SxROM)], [with the consecutive-write rule, and SUROM's 512K],
  [2], [UxROM], [16K switchable + 16K fixed],
  [3], [CNROM], [8K CHR banks],
  [4], [MMC3 (TxROM)], [with the scanline IRQ],
  [7], [AxROM], [32K banks, one-screen mirroring],
  [11], [Color Dreams], [],
  [30], [UNROM 512], [],
  [34], [BNROM / NINA-001], [],
  [66], [GxROM], [],
  [71], [Camerica / BF9097], [],
  [206], [Namco 108], [],
)

The SRAMs set the ceiling: 512K of PRG, 512K of CHR, and up to 32K of work
RAM. What the design cannot do it says plainly: the MMC5's extended
attributes and split screen and the MMC2 and MMC4 tile latches need the PPU
address bus at full speed, which this cartridge does not carry; a 72-pin NES
has no path for expansion audio; and the lockout chip is an external clone.

== What is not finished

#stars(
  [No cartridge has been built. The schematic exists and passes its checks;
   the bus timing is still a datasheet claim until a scope says otherwise.],
  [Pressing Reset while an image is loading restarts the CPU through
   half-written vectors. Turn the power off and on; the cartridge reloads
   CONFIG.],
  [Battery-backed saves live in the cartridge's work RAM and are lost at power
   off. Use an app key (Chapter 7) for anything that must be kept.],
  [Four-screen mirroring is not yet wired.],
)
