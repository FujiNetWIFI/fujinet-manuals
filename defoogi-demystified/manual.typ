// ============================================================
// DEFOOGI DEMYSTIFIED — A Developer's Guide to the FujiNet
// Build Container.
//
// Styled as a modern technical reference with a "terminal /
// container" identity: JetBrains Mono display type, dark
// terminal code blocks, Docker-blue chapter rules, and
// terminal-green accents.
//
// Source-verified against the defoogi repository (tag 1.4.6)
// at ~/Workspace/defoogi: Dockerfiles/*.docker, Makefile,
// versions.env, start, cntnr-init, defoogi-make. Cross-platform
// packaging facts checked against tool upstreams (June 2026).
//
// Build: typst compile --font-path fonts manual.typ
// ============================================================

// ---------- fonts -------------------------------------------
#let f-mono = "JetBrains Mono"     // display heads, code, terminal
#let f-body = "DejaVu Sans"        // body text and labels

// ---------- palette -----------------------------------------
#let ink      = rgb("#1b2128")     // body ink
#let paper    = rgb("#fcfcfa")     // page stock
#let blue-d   = rgb("#0b3d91")     // deep header blue
#let blue     = rgb("#1d63ed")     // Docker blue accent
#let grn      = rgb("#2ea043")     // terminal green
#let amber-bg = rgb("#fff4d6")     // caution panel fill
#let amber-br = rgb("#d99e00")     // caution panel border
#let amber-ik = rgb("#6b5200")     // caution panel ink
#let info-bg  = rgb("#e7f0fb")     // info panel fill
#let info-br  = rgb("#1d63ed")     // info panel border
#let red      = rgb("#c4352b")     // "no" badge
#let rule-c   = rgb("#d7d8d0")     // hairlines
#let code-bg  = rgb("#eef0ea")     // inline code background
#let faint    = rgb("#6b7178")     // captions / dim labels

// terminal block colors
#let term-bg   = rgb("#0d1117")
#let term-fg   = rgb("#d7dce2")
#let term-grn  = rgb("#56d364")
#let term-blu  = rgb("#79c0ff")
#let term-com  = rgb("#768390")
#let term-bar  = rgb("#161b22")

// ---------- helpers ------------------------------------------
#let ic(s) = box(fill: code-bg, outset: (y: 2pt), inset: (x: 3pt),
  radius: 2pt, text(font: f-mono, size: 8.4pt, fill: rgb("#7a2520"), s))

// status badges for the install matrix
#let badge(c, l) = box(fill: c, radius: 2.5pt, inset: (x: 3.5pt, y: 1pt),
  baseline: 1.5pt, text(font: f-mono, size: 6.6pt, weight: 700, fill: white, l))
#let b-ok  = badge(grn, "OK")
#let b-src = badge(amber-br, "SRC")
#let b-no  = badge(red, "NO")

// ---------- terminal "window" code block ---------------------
// Three traffic-light dots, then the body in mono on dark stock.
#let dot(c) = box(circle(radius: 2.6pt, fill: c))
#let term(body, title: "bash") = block(width: 100%, above: 1.0em,
  below: 1.0em, breakable: false, radius: 6pt, clip: true,
  fill: term-bg, stroke: 0.8pt + rgb("#30363d"), {
    block(width: 100%, fill: term-bar, inset: (x: 9pt, y: 6pt),
      grid(columns: (auto, 1fr), align: (left + horizon, right + horizon),
        stack(dir: ltr, spacing: 5pt,
          dot(rgb("#ff5f56")), dot(rgb("#ffbd2e")), dot(rgb("#27c93f"))),
        text(font: f-mono, size: 7pt, fill: term-com, title)))
    block(width: 100%, inset: (x: 11pt, y: 9pt), body)
  })

// ---------- callout panels -----------------------------------
#let panel(body, title, fill: info-bg, bar: info-br, tk: ink) = block(
  width: 100%, above: 1.1em, below: 1.1em, breakable: false, radius: 4pt,
  fill: fill, stroke: (left: 3pt + bar), inset: (x: 12pt, y: 9pt), {
    set par(justify: false, first-line-indent: 0pt, leading: 0.55em)
    text(font: f-mono, weight: 700, size: 8.4pt, fill: bar, upper(title))
    v(4pt)
    set text(size: 9pt, fill: tk)
    body
  })
#let note(body, title: "NOTE") = panel(body, title,
  fill: amber-bg, bar: amber-br, tk: amber-ik)
#let info(body, title: "INFO") = panel(body, title)

// ---------- page footer: rule + folio ------------------------
#let fst = state("folio", false)
#let foot = context {
  if not fst.get() { return }
  let p = counter(page).get().first()
  set text(font: f-mono, size: 7.5pt, fill: faint)
  grid(columns: (1fr, auto, 1fr), align: (left, center, right),
    [defoogi demystified],
    line(length: 0pt),
    [#p])
}

// ============================================================
// DOCUMENT SETUP
// ============================================================
#set document(title: "defoogi Demystified — A Developer's Guide to the FujiNet Build Container",
  author: "FujiNet Manuals Project")
#set text(font: f-body, size: 9.4pt, fill: ink, hyphenate: true)
#set par(leading: 0.62em, spacing: 0.85em, justify: true)
#set page(width: 8.5in, height: 11in, fill: paper,
  margin: (top: 0.85in, bottom: 0.85in, inside: 0.95in, outside: 0.85in),
  footer: foot)

// heading styles ---------------------------------------------
#show heading: set text(font: f-mono)
#set heading(numbering: none)

#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  fst.update(true)
  v(0.15in)
  block(width: 100%, {
    text(font: f-mono, size: 9pt, weight: 700, fill: blue, tracking: 1.5pt,
      "# " + upper(it.body))
    v(5pt)
    line(length: 100%, stroke: 2pt + blue-d)
    v(2pt)
    line(length: 100%, stroke: 0.7pt + rule-c)
  })
  v(0.18in)
}
#show heading.where(level: 2): it => block(above: 1.5em, below: 0.7em,
  breakable: false,
  text(font: f-mono, weight: 700, size: 12.5pt, fill: blue-d, it.body))
#show heading.where(level: 3): it => block(above: 1.2em, below: 0.5em,
  breakable: false,
  text(font: f-mono, weight: 700, size: 10pt, fill: ink, it.body))

// list styling ------------------------------------------------
#set list(indent: 6pt, body-indent: 7pt, spacing: 0.7em,
  marker: text(fill: grn, font: f-mono, "▸"))
#set enum(indent: 6pt, body-indent: 8pt, spacing: 0.7em)

// raw / code styling ------------------------------------------
#show raw: set text(font: f-mono, size: 8.4pt)
#show raw.where(block: false): it => box(fill: code-bg, outset: (y: 2pt),
  inset: (x: 3pt), radius: 2pt, it)
// light code box with Typst's default (light-theme) syntax highlighting;
// the dark "terminal" look is reserved for the term() helper.
#show raw.where(block: true): it => block(width: 100%, above: 1.0em,
  below: 1.0em, breakable: false, radius: 6pt, fill: rgb("#f5f7f0"),
  stroke: (left: 3pt + grn, rest: 0.5pt + rule-c), inset: (x: 12pt, y: 10pt),
  it)

// tables ------------------------------------------------------
#set table(stroke: (x, y) => (
  top: if y == 0 { 0pt } else { 0.5pt + rule-c },
  bottom: 0.5pt + rule-c,
))
#show table.cell.where(y: 0): set text(font: f-mono, fill: white,
  weight: 700, size: 8pt)
#let thead-fill = blue-d
#let tbl(cols, ..cells) = table(columns: cols, inset: (x: 7pt, y: 6pt),
  align: left + horizon,
  fill: (x, y) => if y == 0 { thead-fill } else if calc.odd(y) { rgb("#f4f5f1") } else { paper },
  ..cells)

// ============================================================
// COVER
// ============================================================
#set page(footer: none)
#counter(page).update(1)

#v(0.55in)
#align(center, text(font: f-mono, size: 8.5pt, weight: 700, fill: faint,
  tracking: 4pt, "THE FUJINET BUILD CONTAINER"))

#v(0.30in)
#align(center, text(font: f-mono, size: 46pt, weight: 800, fill: ink,
  tracking: -1pt, "defoogi"))
#align(center, text(font: f-mono, size: 21pt, weight: 700, fill: blue,
  tracking: 8pt, "DEMYSTIFIED"))

#v(0.18in)
#align(center, block(width: 70%, text(font: f-body, size: 11pt, fill: faint,
  "One container, every FujiNet toolchain — and what it would take to build them all yourself.")))

#v(0.40in)

// the terminal window illustration
#align(center, block(width: 78%, radius: 8pt, clip: true, fill: term-bg,
  stroke: 1pt + rgb("#30363d"), {
    block(width: 100%, fill: term-bar, inset: (x: 12pt, y: 8pt),
      stack(dir: ltr, spacing: 6pt,
        dot(rgb("#ff5f56")), dot(rgb("#ffbd2e")), dot(rgb("#27c93f"))))
    block(width: 100%, inset: (x: 16pt, y: 14pt), {
      set text(font: f-mono, size: 9.5pt, fill: term-fg)
      set align(left)
      let prompt = (text(fill: term-grn, "wario@defoogi")
        + text(fill: term-com, ":") + text(fill: term-blu, "~/my-app")
        + text(fill: term-fg, "$ "))
      let dim(s) = text(fill: term-com, s)
      stack(dir: ttb, spacing: 8pt,
        prompt + text(fill: term-fg, "defoogi make"),
        dim("  cc65   →  apple2 · c64 · atari · nes"),
        dim("  cmoc   →  tandy coco (6809)"),
        dim("  zcc    →  msx · coleco adam (z80)"),
        dim("  wcl    →  ibm pc / dos (x86)"),
        dim("  atr/ac →  disk image, mounted by fujinet"),
        text(fill: term-grn, "  ✓ ")
          + text(fill: term-fg, "build complete — artifacts owned by ")
          + text(fill: term-blu, "you"),
        prompt + box(fill: term-fg, width: 7pt, height: 11pt),
      )
    })
  }))

#v(1fr)
#align(center, text(font: f-mono, size: 8pt, fill: faint,
  "FujiNet Manuals Project  ·  verified against defoogi v1.4.6  ·  June 2026"))
#v(0.3in)

// ============================================================
// CONTENTS
// ============================================================
#set page(footer: foot)
#pagebreak()
#fst.update(true)

#block(above: 0.2in, below: 0.3in,
  text(font: f-mono, size: 18pt, weight: 800, fill: blue-d, "Contents"))
#line(length: 100%, stroke: 2pt + blue-d)
#v(0.1in)

#show outline.entry.where(level: 1): it => {
  v(7pt, weak: true)
  set text(font: f-mono, weight: 700, size: 9.5pt, fill: ink)
  it
}
#outline(title: none, depth: 2, indent: auto)

// ============================================================
// CHAPTER 1
// ============================================================
= 1 · What defoogi Is, and the Problem It Solves

*defoogi* — created by Chris Osborn (#text(font: f-mono, size: 8.6pt)[\@fozztexx]) — is a
single Docker container that bundles #emph[every] compiler, assembler, library,
and disk-image utility needed to build #link("https://fujinet.online")[FujiNet]
firmware, libraries, and applications across every retro platform FujiNet
supports — plus the modern embedded toolchains (PlatformIO / ESP32, Pico SDK)
that the FujiNet hardware itself is built with.

You use it as a *command prefix*. Instead of installing a dozen cross-compilers
on your machine, you run:

#term[
  #set text(fill: term-fg, size: 8.6pt)
  #set par(leading: 0.8em, justify: false)
  #text(fill: term-grn)[\$] defoogi make            #text(fill: term-com)[\# run the project Makefile in-container] \
  #text(fill: term-grn)[\$] defoogi cc65 hello.c     #text(fill: term-com)[\# or invoke one tool directly] \
  #text(fill: term-grn)[\$] defoogi cmoc program.c
]

…and the build happens inside the container, but the artifacts land in your
working directory *owned by you*, not by `root`.

== The problem it solves

Building software for 8-bit and 16-bit machines means assembling a zoo of
toolchains that were each written by a different person, in a different decade,
with a different build system, and with wildly different packaging stories:

- Some are in `apt` / Homebrew (cc65, nasm, cpmtools, mtools).
- Some are Java jars that need a JDK (AppleCommander).
- Some only build from source under autotools and #emph[won't compile natively on Windows] (CMOC needs Cygwin).
- Some are Free Pascal programs that need `fpc` just to bootstrap (MADS, Mad Pascal).
- Some are two-phase self-hosting builds that "take forever" — Open Watcom v2's Dockerfile comment literally says so.
- Some need a specific pre-release commit with non-default build flags (z88dk, built `-z` for special MSX options).

Getting all of these onto one machine — at #emph[mutually compatible,
reproducible versions] — and then getting the #emph[same] set onto a teammate's
macOS laptop, a Windows box, and a CI runner, is the actual problem. defoogi
turns that problem into `docker pull`.

== The headline feature: ownership preservation

#info(title: "From the README")[
  Unlike many Docker build environments, *defoogi preserves file ownership and
  permissions*, so your build artifacts stay usable on the host without extra
  `chown`.
]

This is not cosmetic. The usual Docker-build complaint is that everything the
container writes to a bind-mounted directory comes out `root:root`, and you
spend your life running `sudo chown -R`. defoogi solves this at the entrypoint
(see Chapter 3).

// ============================================================
// CHAPTER 2
// ============================================================
= 2 · How defoogi Is Built (Architecture)

defoogi is #emph[not] one monolithic Dockerfile. It is a set of independent
build stages that are assembled at build time by the `Makefile`. Understanding
this explains both its reproducibility and why each tool is cleanly separable.

== The three core stages and the components

The `Dockerfiles/` directory holds three *core* stages and one stage per
*component* tool:

#term(title: "Dockerfiles/")[
  #set text(fill: term-fg, size: 8.2pt)
  #set par(leading: 0.7em, justify: false)
  #text(fill: term-blu)[head.docker]   #text(fill: term-com)[ ← CORE  · defines the tooling base image] \
  #text(fill: term-blu)[final.docker]  #text(fill: term-com)[ ← CORE  · final image preamble (PlatformIO …)] \
  #text(fill: term-blu)[tail.docker]   #text(fill: term-com)[ ← CORE  · installs all .debs, env, entrypoint] \
  #text(fill: term-com)[──────────────────────────────────────────────] \
  cc65 · cmoc · z88dk · open-watcom-v2 · mads · nasm \
  applecommander · atari-tools · dir2atr · cc1541 \
  cpmtools · pico-sdk     #text(fill: term-com)[← COMPONENTS, one tool each → a .deb]
]

The `Makefile` classifies them programmatically:

```make
CORE = head final tail
COMPONENTS = $(filter-out $(CORE),$(notdir $(DOCKERFILES:.docker=)))
```

== The base image — `head.docker`

Everything starts from *Debian 13.0* (`ARG BASE=debian:13.0`) plus a minimal
toolchain every component shares. Each component stage begins
`FROM tooling AS <name>`, inheriting the same compiler base:

```dockerfile
FROM ${BASE} AS tooling
RUN apt-get install -y --no-install-recommends \
      build-essential ca-certificates git
```

== The clever part — build once, package as a `.deb`

Each component *builds its tool from source (or downloads it), installs it into
a clean prefix, then wraps that prefix in a Debian package* inside the build
stage. The pattern, from `cc65.docker`:

```dockerfile
FROM tooling AS cc65
RUN git clone .../cc65.git && cd cc65 \
    && git checkout ${CC65_VERSION} \
    && PREFIX=/usr/local make \
    && PREFIX=/opt/cc65 make install
# …then turn /opt/cc65 into /tmp/cc65.deb via dpkg-deb --build
```

So each stage's #emph[output artifact] is a single file: `/tmp/<name>.deb`.

== Assembly — the `Makefile` streams everything into one Dockerfile

This is the trick that ties it together. The `docker-build` target *streams*
the core + component Dockerfiles into `docker build -f -` (read from stdin),
injecting generated `COPY --from=` lines that pull each component's `.deb`
out of its build stage:

```make
docker-build:
	printf "%s\n" $(COMPONENTS) | \
	sed 's,.*,COPY --from=& /tmp/&.deb /tmp/packages/,' | \
	cat head.docker <components> final.docker - tail.docker | \
	docker build -f - \
	  $(shell sed 's/^\([^=]*\)=/--build-arg \1_VERSION=/' versions.env) ...
```

The result (written to `/tmp/defoogi.dockerfile`) is one big multi-stage
Dockerfile where:

+ `head` builds `tooling`.
+ Every component stage builds its tool as a `.deb` — *these run in parallel* under BuildKit, each isolated.
+ `final` (a fresh `FROM tooling`) installs the no-compile-needed pieces: *PlatformIO* and `abimap` via `pipx`, plus `cmake` / `libmbedtls` / `libexpat`.
+ The generated `COPY --from=<component>` lines copy every built `.deb` into the final image.
+ `tail` installs them all at once (`apt-get install ./tmp/packages/*.deb`), adds runtime utilities, sets environment variables, creates the unprivileged `wario` user, and installs the entrypoint.

== Reproducibility — `versions.env`

Every tool version is *pinned* in `versions.env`, and the `Makefile` turns each
line into a `--build-arg <NAME>_VERSION=…`. The intent is stated in the
`Makefile` itself:

#info(title: "Why versions are pinned")[
  "…a stable, reproducible toolchain that can be matched to specific FujiNet
  firmware/software releases. In the future, older defoogi versions can still be
  rebuilt against the exact tool versions they were originally developed with."
]

This is the single most important architectural property: *defoogi v1.4.6 is a
fixed point* — a known-good constellation of ~19 tool versions known to build
FujiNet together. (See Appendix A.)

== Multi-arch

`make multi-arch NAMESPACE=fozztexx/` builds and pushes per-architecture tags
(`-amd64`, `-arm64`); `make manifest` stitches them into one multi-arch manifest
with `docker buildx imagetools create`. That is why the published image runs
natively on both Intel and Apple-Silicon / ARM hosts.

// ============================================================
// CHAPTER 3
// ============================================================
= 3 · How defoogi Runs (The Runtime Model)

Three scripts implement the "just prefix your command" experience: `start`
(installed as `defoogi`), `cntnr-init` (the in-container entrypoint), and
`defoogi-make` (a `make` convenience wrapper).

== `start` → installed as `defoogi`

You copy `start` into your `PATH` renamed to `defoogi` (`make install` does
`cp start /usr/local/bin/defoogi`). Because the script keys off its own name
(`IMAGE=$(basename $0):latest`), the executable name #emph[is] the image name.

When you run `defoogi make`, `start` issues roughly:

```bash
docker run --privileged -v /dev:/dev \
  --cap-add=SYS_ADMIN --cap-add SYS_PTRACE \
  -e DISPLAY -v ${HOME}/.Xauthority:/home/wario/.Xauthority --net=host \
  --rm -e HOSTDIR="${PWD}" -v "${PWD}":/workspace \
  fozztexx/defoogi:latest make
```

Notable bits:

- `-v "${PWD}":/workspace` — your current directory becomes `/workspace` inside.
- `-e HOSTDIR="${PWD}"` — tells the container the #emph[real] host path, so it can recreate it (see below).
- X11 passthrough (`DISPLAY`, `.Xauthority`, `--net=host`) — so GUI tools (e.g. AppleCommander's GUI) can display.
- `--privileged` + `SYS_ADMIN` — needed because the entrypoint performs a `mount --bind`.
- `--rm` for one-shot runs; `--daemon` keeps it running; `--shell` / `--super-shell` give an interactive shell as the workspace user / root.

== `cntnr-init` — the ownership-preservation magic

This is the entrypoint, and where the "no root-owned artifacts" promise is kept.
On startup it:

+ Reads the *owner uid:gid of `/workspace`* (your mounted directory).
+ If that owner is a normal user (uid ≥ 1000), it *`usermod` / `groupmod`s the in-container `wario` user to match your uid:gid* — so files `wario` writes are written as #emph[you].
+ *Bind-mounts `/workspace` back onto the original host path* (`HOSTDIR`) inside the container, then `cd`s there — so relative paths, `realpath`, and recorded absolute paths match the host. (This is why `--privileged` / `SYS_ADMIN` are required.)
+ Drops privileges and runs your command as `wario` via `sudo -u wario -E --preserve-env=PATH -H env "$@"`.

That uid/gid remap is the whole trick: artifacts come out owned by you, on Linux,
with zero `chown`.

#note[
  On Docker Desktop for macOS / Windows the file-sharing layer already remaps
  ownership, so the benefit is most visible on native Linux Docker.
]

== `defoogi-make` — directory-aware `make`

A thin wrapper so `make -C some/subdir` works through the container: it extracts
the `-C` / `--directory` argument, mounts the #emph[parent] directory, and
re-invokes `defoogi --directory <parent> make -C <target>`. Useful when your
build references files one level up from the makefile.

// ============================================================
// CHAPTER 4
// ============================================================
= 4 · The Complete Toolchain Inventory

Everything defoogi contains, grouped by job. Versions are the pinned values from
`versions.env`.

== Cross-compilers (high-level languages → retro CPUs)

#tbl((auto, auto, auto, 1fr),
  table.header[Tool][Pin][CPU / target][What it is],
  [*cc65*], [`6efe447`], [6502 / 65C02 / 65816],
    [C compiler #emph[plus] `ca65` assembler, `ld65` linker, `ar65`, `da65`. C64, Apple II, Atari 8-bit, NES, VIC-20, Oric… The backbone of FujiNet's 6502-family apps.],
  [*CMOC*], [`0.1.97`], [6809 / 6309],
    [C-like compiler for the Motorola 6809. Tandy CoCo, Dragon 32/64, OS-9. *Requires lwtools.*],
  [*lwtools*], [`4.24`], [6809 / 6309],
    [`lwasm` assembler + `lwlink` linker + `lwar`. CMOC emits assembly these turn into binaries.],
  [*z88dk*], [`4c74585`], [Z80 / Z180 / 8080 / 8085],
    [C compiler (`zcc` driving *sccz80* #emph[and] a bundled *SDCC*), assembler, linker, and a library covering 100+ Z80 machines: MSX, ZX Spectrum, CP/M, Amstrad, Coleco / ADAM. Built `./build.sh -z` for special MSX options.],
  [*Open Watcom v2*], [`2025-08-02`], [8086 / 286 / 386 (x86)],
    [Full C/C++ compiler + linker (`wcc`, `wcl`, `wlink`) for DOS, 16-bit Windows, OS/2, CP/M-86. The FujiNet *MS-DOS / PC* toolchain. Self-hosting two-phase build.],
  [*Mad Pascal*], [`23e4c5f`], [6502 (Atari 8-bit)],
    [Turbo-Pascal-compatible compiler, paired with MADS as its backend. Ships FujiNet Pascal libs (`fn_cookies`, `fn_tcp`) — defoogi patches them at build time.],
)

*FujiNet-specific Z80 libraries* layered into z88dk:

#tbl((auto, auto, 1fr),
  table.header[Library][Pin][Purpose],
  [*eoslib*], [`70d476b`], [Coleco ADAM *EOS* C library — `eos.lib` + `eos.h`. (tschak909)],
  [*smartkeyslib*], [`1.1`], [ADAM *SmartKeys* function-key library. (tschak909)],
)

== Assemblers

#tbl((auto, auto, auto, 1fr),
  table.header[Tool][Pin][CPU][Notes],
  [*ca65*], [in cc65], [6502 family], [cc65's macro assembler.],
  [*lwasm*], [in lwtools], [6809], [lwtools' assembler.],
  [*MADS*], [`2370bf0`], [6502 / Atari], [Powerful Atari-centric 6502 macro assembler — the Atari-8-bit standard. Built from Pascal via `fpc`.],
  [*atasm*], [`V1.30`], [6502 / Atari], [MAC/65-compatible Atari assembler (built inside `dir2atr.docker`).],
  [*nasm*], [`e9fac2f`], [x86], [The Netwide Assembler — modern x86 / x86-64 assembly.],
)

== Disk-image & file tools — #emph[making the target media]

The part most "just install a compiler" guides forget: a compiled binary is
useless until it is inside a disk image the target machine (or FujiNet) can
mount. defoogi bundles a tool for *every* disk format FujiNet platforms use.

#tbl((auto, auto, auto, 1fr),
  table.header[Tool][Pin][Format][Platform],
  [*atari-tools* (`atr`)], [`835d5a6`], [`.ATR` read/write/extract], [Atari 8-bit],
  [*dir2atr* (AtariSIO)], [`bbccb15`], [build `.ATR` from a directory], [Atari 8-bit],
  [*cc1541*], [`4.2`], [`.D64` (1541 floppy image)], [Commodore 64 / VIC-20],
  [*AppleCommander* (`ac`,`acx`)], [`12.0`], [`.dsk` `.do` `.po` `.2mg`, ShrinkIt], [Apple II],
  [*cpmtools*], [`2.23`], [CP/M filesystems], [CP/M + Coleco ADAM],
  [*mtools*], [apt], [FAT12/16 floppy & disk images], [MS-DOS / PC],
  [*decb* (Toolshed)], [`v2_4_2`], [Disk Extended Color BASIC `.dsk`], [Tandy CoCo],
)

#note(title: "ADAM detail worth knowing")[
  `cpmtools.docker` writes a custom `/usr/local/share/diskdefs` defining
  `coleco-adam` (5.25″, 40 tracks) and `coleco-adam-3.5` (3.5″, 160 tracks)
  geometries — so you can build ADAM media that stock cpmtools doesn't know
  about out of the box.
]

== Embedded / FujiNet-hardware toolchains

#tbl((auto, auto, auto, 1fr),
  table.header[Tool][Pin][Target][Role],
  [*PlatformIO*], [latest], [ESP32 (ESP-IDF / Arduino)], [*The FujiNet firmware build system itself* — how the device firmware is compiled and flashed.],
  [*abimap*], [latest], [—], [ABI / symbol-version map helper used in some build flows.],
  [*Pico SDK*], [`2.2.0`], [RP2040 (Raspberry Pi Pico)], [SDK at `/usr/local/share/pico-sdk` (`PICO_SDK_PATH` preset) for RP2040-based FujiNet peripherals / variants.],
  [*picotool*], [w/ pico-sdk], [RP2040], [Inspect / flash RP2040 binaries.],
)

== Base system, libraries & build dependencies (the invisible glue)

These come from `head`, `final`, `tail`, and from being pulled in as
dependencies. They're "free" inside defoogi but each is something you'd
otherwise have to provide yourself:

- *Debian 13.0* userland + *build-essential* (gcc/g++/make), *git*, *ca-certificates*, *cmake*.
- *Free Pascal Compiler (`fpc`)* — required to build MADS / Mad Pascal.
- *default-jdk (Java)* — pulled in as an AppleCommander dependency; required to run `ac` / `acx`.
- *SDCC* — built #emph[as part of] z88dk (`BUILD_SDCC=1`).
- A pile of *Perl modules* (Capture::Tiny, Clone, Path::Tiny, YAML, Modern::Perl…) plus `bison`, `flex`, `ragel`, `re2c`, `m4`, `ccache`, `texinfo` — all required just to build z88dk.
- Runtime utilities in `tail`: `mtools`, `curl`, `wget`, `file`, `jq`, `xxd`, `zip`/`unzip`, `less`, `bsdmainutils`, `libz-dev`, `sudo`.
- Preset environment: `WATCOM=/opt/watcom`, `PATH+=$WATCOM/binl`, `PLATFORMIO_CORE_DIR=/workspace/.platformio`, `PICO_SDK_PATH=/usr/local/share/pico-sdk`.

== Declared-but-not-built (housekeeping note)

#note[
  Two entries are referenced but *not currently produced* by any Dockerfile in
  this revision. `versions.env` pins `VASM=2_0c`, but there is no `vasm.docker`;
  and `tail.docker` exports `VBCC=/opt/vbcc` (adding `$VBCC/bin` to `PATH`) with
  no `vbcc.docker` to build it and no `VBCC` pin. These look like scaffolding for
  a planned *vasm / vbcc* (Amiga / 68k-style) toolchain. They're harmless today
  but worth flagging so you don't go hunting for `vasmm68k`.
]

// ============================================================
// CHAPTER 5
// ============================================================
= 5 · Installing Each Tool Yourself (The Hard Way)

What if you #emph[didn't] use defoogi? Here is what it actually takes to stand
up each tool on *Linux*, *Windows*, and *macOS*. The pattern that emerges: a few
tools are well-packaged everywhere, but the majority are source-only, several
*do not build natively on Windows* (Cygwin / MSYS required), and *none* of the
platform combinations gets you a pinned, mutually-compatible set without manual
version juggling.

#block(above: 0.6em, below: 1.0em, text(size: 8.6pt, fill: faint,
  [Legend:  #b-ok #h(3pt) packaged / one command   #h(8pt) #b-src #h(3pt) build from source / caveats   #h(8pt) #b-no #h(3pt) no native path (needs Cygwin / MSYS / VM)]))

== cc65 (6502)

#tbl((auto, 1fr),
  table.header[OS][Method],
  [Linux #b-ok], [`apt install cc65` (Debian / Ubuntu); openSUSE Build Service RPM/DEB.],
  [macOS #b-ok], [`brew install cc65`.],
  [Windows #b-ok], [Official `.exe` snapshot installer (sets env vars) or unzip the binary snapshot.],
)
cc65 is the easy one. Caveat: distro packages can lag the upstream git `HEAD`
FujiNet relies on, so you may still `git clone && make` to match `versions.env`'s
`6efe447`.

== CMOC + lwtools (6809)

#tbl((auto, 1fr),
  table.header[OS][Method],
  [Linux #b-src], [Build both from source. lwtools: tarball, `make && make install`. CMOC: `./configure && make && make install` (needs `flex`/`yacc`). `lwasm`/`lwlink` must be on `PATH`.],
  [macOS #b-src], [Same source build — CMOC supports Darwin, but no Homebrew formula.],
  [Windows #b-no], [Per the author, CMOC *cannot be compiled as a native Windows app* — you must use *Cygwin* (lwtools likewise). A third-party WinCMOC bundle exists but lags far behind and isn't the pinned `0.1.97`.],
)
defoogi additionally builds *`decb`* from Toolshed here (CoCo `.dsk` handling) —
another from-source step you'd have to replicate.

== z88dk + SDCC (Z80)

#tbl((auto, 1fr),
  table.header[OS][Method],
  [Linux #b-src], [Nightly source tarball or `git clone --recursive` + `./build.sh`; a *snap* exists but won't be the pinned commit or carry the `-z` MSX flags.],
  [macOS #b-src], [Nightly `z88dk-osx-latest.zip` exists, but to match the pinned pre-release commit you build from source.],
  [Windows #b-no], [Nightly `z88dk-win32-latest.zip` exists, *but building the classic libs from source requires MSYS or Cygwin.*],
)
Then you'd #emph[still] clone & build *eoslib* and *smartkeyslib* into z88dk's lib
tree — exactly what `z88dk.docker` does — and satisfy its long Perl-module +
bison/flex/ragel/re2c build wall.

== Open Watcom v2 (x86 / DOS)

#tbl((auto, 1fr),
  table.header[OS][Method],
  [Linux #b-ok], [Download the portable snapshot zip (`ow_portable_v2_stable.zip`); set `WATCOM`/`PATH`/`INCLUDE`. Or build from source (two-phase, slow).],
  [macOS #b-src], [Portable snapshot / build from source; set env vars manually.],
  [Windows #b-ok], [Official installer from the snapshot builds.],
)
Workable, but you wire up three environment variables yourself — defoogi presets
them. The source build "takes #emph[forever]" (the Dockerfile's own words).

== MADS + Mad Pascal (Atari 6502)

#tbl((auto, 1fr),
  table.header[OS][Method],
  [Linux #b-src], [Install `fpc`, then `fpc -Mdelphi mads.pas` and `fpc src/mp.pas` from the Mad-Assembler / Mad-Pascal repos.],
  [macOS #b-src], [Same — install Free Pascal, build from source.],
  [Windows #b-ok], [Prebuilt Windows binaries published by the author (tebe6502); otherwise install FPC and build.],
)
You'd also replicate defoogi's library staging (copying `base/lib/blibs/dlibs`,
upper-case symlinks) #emph[and] the FujiNet `fn_cookies` / `fn_tcp` source patch.

== Atari disk tooling, atari-tools, cc1541

#tbl((auto, auto, 1fr),
  table.header[Tool][OS][Method],
  [atasm / dir2atr], [Lin/mac #b-src], [atasm: clone & `make`. dir2atr: clone *AtariSIO* (`make tools && make tools-install`); needs `libncurses-dev`. AtariSIO is Linux-centric.],
  [atasm / dir2atr], [Win #b-src], [Hias publishes Windows AtariSIO builds; atasm under MSYS/MinGW.],
  [atari-tools (`atr`)], [all #b-src], [`git clone jhallen/atari-tools && make`. No package.],
  [cc1541], [all #b-src], [Clone from Bitbucket, `make && make install`. Community packages exist but versions vary.],
)

== AppleCommander (Apple II disks)

#tbl((auto, 1fr),
  table.header[OS][Method],
  [All three #b-src], [Download cross-platform *jars* from GitHub releases — but you must have *Java 11+* installed, and you'll want to write `ac`/`acx` shell-script wrappers (`java -jar …`) yourself. defoogi does both, and pulls `default-jdk` automatically.],
)

== cpmtools / mtools / nasm

#tbl((auto, auto, 1fr),
  table.header[Tool][OS][Method],
  [cpmtools/mtools], [Linux #b-ok], [`apt install cpmtools mtools`.],
  [cpmtools/mtools], [macOS #b-ok], [`brew install cpmtools mtools`.],
  [cpmtools/mtools], [Windows #b-src], [Cygwin build (cpmtools); mtools via Cygwin/MSYS.],
  [nasm], [all #b-ok], [`apt install nasm` · `brew install nasm` · official Windows installer.],
)
Even here, you'd add defoogi's custom Coleco ADAM `diskdefs` by hand to make
ADAM media.

== PlatformIO + Pico SDK (embedded)

#tbl((auto, 1fr),
  table.header[Component][Method],
  [PlatformIO #b-ok], [`pipx install platformio` — cross-platform, genuinely easy everywhere.],
  [Pico SDK #b-src], [Clone `pico-sdk` + submodules, set `PICO_SDK_PATH`, install the *`gcc-arm-none-eabi`* cross toolchain + newlib; build *picotool* from source (needs `libusb`, `cmake`, `pkg-config`).],
)

== The DIY pain summary

#tbl((1fr, auto, auto, auto, auto),
  table.header[Tool][Linux][Windows][macOS][Packaged?],
  [cc65], [#b-ok], [#b-ok], [#b-ok], [apt · brew · exe],
  [nasm], [#b-ok], [#b-ok], [#b-ok], [apt · brew · exe],
  [cpmtools / mtools], [#b-ok], [#b-src], [#b-ok], [apt · brew],
  [Open Watcom v2], [#b-ok], [#b-ok], [#b-src], [snapshot / installer],
  [AppleCommander], [#b-src], [#b-src], [#b-src], [jar (needs JDK 11)],
  [PlatformIO], [#b-ok], [#b-ok], [#b-ok], [pipx],
  [z88dk (+eoslib/keys)], [#b-src], [#b-no], [#b-src], [nightly / snap (unpinned)],
  [CMOC + lwtools], [#b-src], [#b-no], [#b-src], [source only],
  [MADS / Mad Pascal], [#b-src], [#b-ok], [#b-src], [source (Win binaries)],
  [atasm / dir2atr / atr], [#b-src], [#b-src], [#b-src], [source only],
  [cc1541], [#b-src], [#b-src], [#b-src], [source (mostly)],
  [Pico SDK + picotool], [#b-src], [#b-src], [#b-src], [source + ARM toolchain],
)

Tally: of ~13 tool groups, only *three* (cc65, nasm, PlatformIO) are genuinely
one-command everywhere. *Two won't build natively on Windows at all.* And *none*
of this gives you version pins matched to a FujiNet release.

// ============================================================
// CHAPTER 6
// ============================================================
= 6 · Why defoogi Is the More Complete Option

The matrix above shows the #emph[breadth] problem. Here is why the container wins
on the dimensions that matter for FujiNet development:

+ *One install, not thirteen.* `docker pull fozztexx/defoogi` (or one local build) replaces a multi-day setup spanning apt, Homebrew, pipx, Java, Free Pascal, Cygwin / MSYS, and a half-dozen `git clone && make` builds — #emph[per developer, per machine].

+ *Reproducibility pinned to FujiNet releases.* `versions.env` freezes ~19 components at exact commits/tags. A given defoogi tag is a #emph[known-good constellation]. DIY installs drift to slightly different upstream versions and "works on my machine" bugs follow. defoogi can be *rebuilt from an old tag* to reproduce a historical build exactly.

+ *True cross-platform parity.* The container is byte-for-byte identical on Linux, Windows (Docker Desktop / WSL2), and macOS (incl. Apple Silicon via the multi-arch manifest). The DIY path differs on every OS — and on Windows several tools require Cygwin / MSYS that subtly change behavior.

+ *The disk-image tools are included and pre-configured.* Compilers are only half the job; you need `atr`, `dir2atr`, `cc1541`, `ac`/`acx`, `cpmtools` (with *ADAM diskdefs*), `mtools`, and `decb` to produce mountable media. defoogi ships all of them, wired up — including config a fresh install wouldn't have.

+ *All the build glue is solved.* Java for AppleCommander, FPC for MADS, SDCC inside z88dk, the Perl-module wall z88dk needs, the FujiNet `fn_cookies` / `fn_tcp` patches, the eoslib / smartkeyslib staging, `WATCOM` / `PICO_SDK_PATH` env vars — all pre-resolved.

+ *Ownership preservation.* Artifacts come out owned by you (uid/gid remap + bind-mount) — no `sudo chown` ritual, no root-owned junk in your repo.

+ *Local and CI are the same environment.* The exact image used on your laptop runs in GitHub Actions, enabling the *edit → push → CI build → mount over HTTP via FujiNet → boot* workflow. DIY means maintaining two parallel setups and keeping them in sync.

+ *Firmware #emph[and] apps in one place.* It is the only environment covering both the *device firmware* (PlatformIO / ESP32, Pico SDK) and *every client-platform app toolchain* — so firmware devs and app devs share one tool.

#note(title: "The honest counterpoint")[
  defoogi requires Docker; the first build / pull is large; `--privileged` is
  needed for the bind-mount trick; and GUI / serial-flashing workflows rely on
  the X11 + `/dev` passthrough the `start` script sets up. For the FujiNet use
  case, those costs are small next to maintaining a dozen hand-built cross
  toolchains across three operating systems.
]

// ============================================================
// CHAPTER 7
// ============================================================
= 7 · Using defoogi Day-to-Day

== Install

```bash
# 1. Get Docker (the repo even ships get-docker.py for Debian-family Linux)
./get-docker.py          # adds Docker's apt repo, installs docker-ce,
                         # and adds you to the docker group

# 2. Put the launcher on your PATH, named `defoogi`
sudo make install        # cp start /usr/local/bin/defoogi
#   or:  cp start ~/bin/defoogi && chmod +x ~/bin/defoogi

# 3. first run pulls fozztexx/defoogi:latest automatically
```

To *build the image yourself* (reproducible from the pins):

```bash
make            # assembles + builds defoogi:1.4.6 and defoogi:latest
make rebuild    # --no-cache --pull, full clean build
```

== Everyday usage

```bash
cd ~/my-fujinet-app

defoogi make                 # run the project Makefile in-container
defoogi cc65 hello.c         # 6502
defoogi cmoc program.c       # 6809
defoogi zcc +cpm program.c   # z88dk for CP/M
defoogi wcl -bcl=dos prog.c  # Open Watcom for DOS

# Disk images:
defoogi atr disk.atr format ; defoogi atr disk.atr write prog.xex
defoogi cc1541 -f prog -w prog.prg disk.d64
defoogi ac -as disk.dsk PROG < prog.bin

# Interactive shells:
defoogi --shell              # shell as `wario` (you), in your workspace
defoogi --super-shell        # root shell (for poking at the image)
```

== CI/CD (GitHub Actions)

Use the same image as a container step so CI builds bit-identically to local,
then publish the artifact as a downloadable asset that FujiNet can mount over
HTTP. The promised loop: *edit → push → CI builds with defoogi → boot retro
machine → mount the build directly via FujiNet → run.* No floppies, no SD-card
sneakernet.

== Troubleshooting quick hits

#tbl((auto, 1fr),
  table.header[Symptom][Cause / fix],
  [`No /workspace directory found`], [You ran the raw container without the `start`/`defoogi` wrapper. Use `defoogi …` (it sets `-v $PWD:/workspace` and `HOSTDIR`).],
  [Artifacts owned by a system user], [`/workspace` is owned by a uid < 1000, so `cntnr-init` deliberately skips the remap and warns. Run from a normally-owned directory.],
  [GUI tool won't display], [Ensure `$DISPLAY` is set and `~/.Xauthority` exists; `start` forwards both with `--net=host`.],
  [`vasm` / `vbcc` not found], [Expected — declared in `versions.env` / `tail` but not built in this revision (§4).],
)

// ============================================================
// APPENDIX A
// ============================================================
= Appendix A · Version Pin Reference

Every pin in `versions.env`, with what it controls. defoogi tag at time of
writing: *1.4.6*.

#tbl((auto, auto, 1fr, auto),
  table.header[Key][Value][Controls][Built by],
  [`AC`], [`12.0`], [AppleCommander jars], [`applecommander`],
  [`ATARISIO`], [`bbccb15`], [dir2atr (AtariSIO tools)], [`dir2atr`],
  [`ATARITOOLS`], [`835d5a6`], [`atr` (atari-tools)], [`atari-tools`],
  [`ATASM`], [`V1.30`], [atasm assembler], [`dir2atr`],
  [`CC1541`], [`4.2`], [cc1541 (D64)], [`cc1541`],
  [`CC65`], [`6efe447`], [cc65 suite], [`cc65`],
  [`CMOC`], [`0.1.97`], [CMOC 6809 compiler], [`cmoc`],
  [`CPMTOOLS`], [`2.23`], [cpmtools (+ ADAM diskdefs)], [`cpmtools`],
  [`EOSLIB`], [`70d476b`], [ADAM EOS lib (in z88dk)], [`z88dk`],
  [`LWTOOLS`], [`4.24`], [lwasm / lwlink (for CMOC)], [`cmoc`],
  [`MADSASM`], [`2370bf0`], [Mad-Assembler], [`mads`],
  [`MADSPAS`], [`23e4c5f`], [Mad-Pascal], [`mads`],
  [`OW2`], [`2025-08-02-Build`], [Open Watcom v2], [`open-watcom-v2`],
  [`PICOSDK`], [`2.2.0`], [Pico SDK + picotool], [`pico-sdk`],
  [`SMARTKEYS`], [`1.1`], [ADAM SmartKeys lib (in z88dk)], [`z88dk`],
  [`TOOLSHED`], [`v2_4_2`], [`decb` (CoCo .dsk)], [`cmoc`],
  [`VASM`], [`2_0c`], [#emph[declared, not built]], [—],
  [`Z88DK`], [`4c74585`], [z88dk + SDCC], [`z88dk`],
  [`NASM`], [`e9fac2f`], [nasm], [`nasm`],
)

Not in `versions.env` (installed at latest): *PlatformIO*, *abimap*, *mtools*,
*default-jdk (Java)*, *fpc*, *SDCC* (built within z88dk), *cmake*.

// ============================================================
// APPENDIX B
// ============================================================
= Appendix B · The Generated Dockerfile

What the `Makefile` feeds to `docker build` (written to
`/tmp/defoogi.dockerfile`), conceptually:

```dockerfile
[ head.docker ]                     # FROM debian:13.0 AS tooling
[ cc65.docker ]                     # FROM tooling AS cc65   → /tmp/cc65.deb
[ cmoc.docker ]                     # FROM tooling AS cmoc   → /tmp/cmoc.deb
[ z88dk.docker ]                    #   …one stage per component, in parallel
[ … every other component … ]
[ final.docker ]                    # FROM tooling  (final image; PlatformIO)
COPY --from=cc65 /tmp/cc65.deb /tmp/packages/    # ← generated by sed
COPY --from=cmoc /tmp/cmoc.deb /tmp/packages/
COPY --from=…    …                               #   one COPY per component
[ tail.docker ]                     # apt-get install /tmp/packages/*.deb;
                                    # runtime tools; env; create `wario`;
                                    # ENTRYPOINT cntnr-init
```

Build-args are injected from `versions.env` (`AC=12.0` →
`--build-arg AC_VERSION=12.0`), plus `MAINTAINER` and `WSUSER`.

// ============================================================
// APPENDIX C
// ============================================================
= Appendix C · Sources & References

*defoogi itself*
- defoogi repository — `github.com/tschak909/defoogi` (analyzed locally at `~/Workspace/defoogi`, tag 1.4.6)
- Docker Hub — `hub.docker.com/repository/docker/fozztexx/defoogi`
- FujiNet — `fujinet.online`

*Toolchains*
- cc65 — `cc65.github.io` · Homebrew formula · NESdev "Installing CC65"
- CMOC — `perso.b2b2c.ca/~sarrazip/dev/cmoc.html` (+ manual) · lwtools-on-Cygwin (Sub-Etha Software)
- lwtools — `lwtools.ca`
- z88dk — `z88dk.org` · installation wiki · `nightly.z88dk.org`
- Open Watcom v2 — `openwatcom.org` · `github.com/open-watcom/open-watcom-v2` (build/server/install.txt)
- MADS / Mad-Pascal — `github.com/tebe6502/Mad-Assembler` · `…/Mad-Pascal`
- atasm — `github.com/CycoPH/atasm`
- AtariSIO (dir2atr) — `github.com/HiassofT/AtariSIO`
- atari-tools — `github.com/jhallen/atari-tools`
- cc1541 — `bitbucket.org/ptv_claus/cc1541`
- AppleCommander — `applecommander.github.io` · releases · install (Java 11)
- cpmtools — `moria.de/~michael/cpmtools` · Homebrew
- mtools — `gnu.org/software/mtools`
- nasm — `nasm.us` · Homebrew
- Toolshed (decb) — `github.com/nitros9project/toolshed`
- eoslib / smartkeyslib — `github.com/tschak909/eoslib` · `…/smartkeyslib`
- PlatformIO — `platformio.org`
- Pico SDK / picotool — `github.com/raspberrypi/pico-sdk` · `…/picotool`

#v(1.2em)
#line(length: 100%, stroke: 0.7pt + rule-c)
#v(0.5em)
#text(size: 8pt, fill: faint)[
  Generated for the FujiNet Manuals Project. Verified against defoogi v1.4.6
  source. Upstream packaging behavior reflects the state at June 2026 and may
  change.
]
