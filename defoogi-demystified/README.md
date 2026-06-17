# defoogi Demystified — A Developer's Guide to the FujiNet Build Container

A comprehensive developer manual for **defoogi**, Chris Osborn's
(*@fozztexx*) Docker container that bundles every compiler, assembler,
library, and disk-image tool needed to build [FujiNet](https://fujinet.online)
firmware, libraries, and applications — across every platform FujiNet
supports — plus the embedded toolchains (PlatformIO/ESP32, Pico SDK)
the hardware itself is built with.

The manual takes defoogi apart into its constituent components, shows
what it would take to install each tool on its own on Linux, Windows,
and macOS, and explains why the container is the more complete option.
It is styled as a modern technical reference with a "terminal /
container" identity: JetBrains Mono display type, dark terminal code
blocks, Docker-blue chapter rules, and terminal-green accents.

## Contents

1. What defoogi Is, and the Problem It Solves
2. How defoogi Is Built (Architecture — multi-stage build, `.deb` packaging, `versions.env`)
3. How defoogi Runs (Runtime Model — `start`/`defoogi`, `cntnr-init`, ownership preservation)
4. The Complete Toolchain Inventory (every component, version, target, role)
5. Installing Each Tool Yourself (The Hard Way — per-OS install matrix)
6. Why defoogi Is the More Complete Option
7. Using defoogi Day-to-Day (install, usage, CI/CD, troubleshooting)
8. Appendices — version pin reference, the generated Dockerfile, sources

## Sources

Verified against the **defoogi** repository (tag **1.4.6**) at
`~/Workspace/defoogi`:

- **Build** — `Makefile`, `versions.env`, and every `Dockerfiles/*.docker`
  stage (`head`, `final`, `tail`, and one per component tool).
- **Runtime** — the `start`, `cntnr-init`, and `defoogi-make` scripts.
- **Cross-platform packaging** — each tool's upstream (cc65, CMOC/lwtools,
  z88dk, Open Watcom v2, MADS/Mad-Pascal, AppleCommander, cpmtools, mtools,
  nasm, the Atari disk tools, cc1541, Pico SDK, PlatformIO), as of June 2026.

## Building

```
make            # defoogi-demystified.pdf
make watch      # rebuild on save
make preview    # preview/page-NN.png at 110 ppi
make clean
```

Requires Typst 0.13+. Fonts are vendored in `fonts/` (JetBrains Mono —
display type and code; DejaVu Sans — body text).

## Wiki

A GitHub-flavored Markdown edition lives in
[`wiki/defoogi-Demystified.md`](wiki/defoogi-Demystified.md).
