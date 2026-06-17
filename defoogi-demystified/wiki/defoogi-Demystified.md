# defoogi Demystified

### A Developer's Guide to the FujiNet Build Container

*Source-verified against `defoogi` v1.4.6 (`Makefile` `TAG = 1.4.6`) and `versions.env` as of June 2026.*

---

## Table of Contents

1. [What defoogi Is, and the Problem It Solves](#1-what-defoogi-is-and-the-problem-it-solves)
2. [How defoogi Is Built (Architecture)](#2-how-defoogi-is-built-architecture)
3. [How defoogi Runs (The Runtime Model)](#3-how-defoogi-runs-the-runtime-model)
4. [The Complete Toolchain Inventory](#4-the-complete-toolchain-inventory)
5. [Installing Each Tool Yourself (The Hard Way)](#5-installing-each-tool-yourself-the-hard-way)
6. [Why defoogi Is the More Complete Option](#6-why-defoogi-is-the-more-complete-option)
7. [Using defoogi Day-to-Day](#7-using-defoogi-day-to-day)
8. [Appendix A — Version Pin Reference](#appendix-a--version-pin-reference)
9. [Appendix B — The Generated Dockerfile](#appendix-b--the-generated-dockerfile)
10. [Appendix C — Sources & References](#appendix-c--sources--references)

---

## 1. What defoogi Is, and the Problem It Solves

**defoogi** (created by Chris Osborn, *@fozztexx*) is a single Docker container that bundles *every* compiler, assembler, library, and disk-image utility needed to build [FujiNet](https://fujinet.online) firmware, libraries, and applications — across every retro platform FujiNet supports — plus the modern embedded toolchains (PlatformIO/ESP32, Pico SDK) the FujiNet hardware itself is built with.

You use it as a **command prefix**. Instead of installing a dozen cross-compilers on your machine, you run:

```bash
defoogi make
defoogi cc65 hello.c
defoogi cmoc program.c
```

…and the build happens inside the container, but the artifacts land in your working directory **owned by you**, not by `root`.

### The problem it solves

Building software for 8-bit and 16-bit machines means assembling a zoo of toolchains that were each written by a different person, in a different decade, with a different build system, and with wildly different packaging stories:

- Some are in `apt`/Homebrew (cc65, nasm, cpmtools, mtools).
- Some are Java jars that need a JDK (AppleCommander).
- Some only build from source under autotools and *won't compile natively on Windows* (CMOC needs Cygwin).
- Some are Free Pascal programs that need `fpc` just to bootstrap (MADS, Mad Pascal).
- Some are two-phase self-hosting builds that "take forever" (Open Watcom v2 — the Dockerfile comment literally says so).
- Some need a specific pre-release commit with non-default build flags (z88dk, built `-z` for special MSX options).

Getting all of these onto one machine — at *mutually compatible, reproducible versions* — and then getting the **same** set onto a teammate's macOS laptop and a Windows box and a CI runner, is the actual problem. defoogi turns that problem into `docker pull`.

### The headline feature: ownership preservation

> Unlike many Docker build environments, **defoogi preserves file ownership and permissions**, so your build artifacts stay usable on the host without extra `chown`. — `README.md`

This is not cosmetic. The usual Docker-build complaint is that everything the container writes to a bind-mounted directory comes out `root:root`, and you spend your life running `sudo chown -R`. defoogi solves this at the entrypoint (see [§3](#3-how-defoogi-runs-the-runtime-model)).

---

## 2. How defoogi Is Built (Architecture)

defoogi is **not** one monolithic Dockerfile. It is a set of independent build stages that are assembled at build time by the `Makefile`. Understanding this explains both its reproducibility and why each tool is cleanly separable.

### 2.1 The three "core" stages and the components

```
Dockerfiles/
├── head.docker      ← CORE: defines the `tooling` base image
├── final.docker     ← CORE: the final image preamble (PlatformIO, etc.)
├── tail.docker      ← CORE: installs all .debs, runtime tools, entrypoint
│
├── cc65.docker          ┐
├── cmoc.docker          │
├── z88dk.docker         │
├── open-watcom-v2.docker│
├── mads.docker          │
├── nasm.docker          ├─ COMPONENT stages: each builds ONE tool
├── applecommander.docker│   and packages it as a .deb
├── atari-tools.docker   │
├── dir2atr.docker       │
├── cc1541.docker        │
├── cpmtools.docker      │
└── pico-sdk.docker      ┘
```

The `Makefile` classifies them:

```make
CORE = head final tail
COMPONENTS = $(filter-out $(CORE),$(notdir $(DOCKERFILES:.docker=)))
```

### 2.2 The base image — `head.docker`

Everything starts from **Debian 13.0 (`ARG BASE=debian:13.0`)**, plus a minimal toolchain that every component shares:

```dockerfile
FROM ${BASE} AS tooling
RUN apt-get install -y --no-install-recommends build-essential ca-certificates git
```

Every component stage begins `FROM tooling AS <name>`, so they all inherit the same compiler base.

### 2.3 The clever part — build once, package as `.deb`

Each component **builds its tool from source (or downloads it), installs it into a clean prefix, then wraps that prefix in a Debian package** inside the build stage. The pattern, taken verbatim from `cc65.docker`:

```dockerfile
FROM tooling AS cc65
RUN git clone .../cc65.git && cd cc65 && git checkout ${CC65_VERSION} \
    && PREFIX=/usr/local make && PREFIX=/opt/cc65 make install
# …then turn /opt/cc65 into /tmp/cc65.deb via dpkg-deb --build
```

So each stage's *output artifact* is a single file: `/tmp/<name>.deb`.

### 2.4 Assembly — the `Makefile` concatenates everything into one Dockerfile

This is the trick that ties it together. The `docker-build` target literally **streams** the core + component Dockerfiles into `docker build -f -` (read from stdin), injecting generated `COPY --from=` lines that pull each component's `.deb` out of its build stage:

```make
docker-build:
	printf "%s\n" $(COMPONENTS) | \
	sed 's,.*,COPY --from=& /tmp/&.deb /tmp/packages/,' | \
	cat head.docker <component stages> final.docker - tail.docker | \
	docker build -f - $(shell sed 's/^\([^=]*\)=/--build-arg \1_VERSION=/' versions.env) ...
```

The result, written to `/tmp/defoogi.dockerfile`, is one big multi-stage Dockerfile where:

1. `head` builds `tooling`.
2. Every component stage builds its tool as a `.deb` — **these run in parallel** under BuildKit, each isolated.
3. `final` (a fresh `FROM tooling`) installs the no-compile-needed pieces — **PlatformIO** and `abimap` via `pipx`, plus `cmake`/`libmbedtls`/`libexpat`.
4. The generated `COPY --from=<component> /tmp/<component>.deb /tmp/packages/` lines copy every built `.deb` into the final image.
5. `tail` installs them all in one shot (`apt-get install -y ./tmp/packages/*.deb`), adds runtime utilities, sets environment variables, creates the unprivileged `wario` user, and installs the entrypoint.

### 2.5 Reproducibility — `versions.env`

Every tool version is **pinned** in `versions.env`, and the `Makefile` turns each line into a `--build-arg <NAME>_VERSION=…`. The intent is stated in the `Makefile`:

> Package versions are pinned intentionally. This ensures a stable, reproducible toolchain that can be matched to specific FujiNet firmware/software releases. In the future, older defoogi versions can still be rebuilt against the exact tool versions they were originally developed with.

This is the single most important architectural property: **defoogi version 1.4.6 is a fixed point** — a known-good constellation of ~19 tool versions that are known to build FujiNet together. (See [Appendix A](#appendix-a--version-pin-reference).)

### 2.6 Multi-arch

`make multi-arch NAMESPACE=fozztexx/` builds and pushes per-architecture tags (`-amd64`, `-arm64`), and `make manifest` stitches them into a single multi-arch manifest with `docker buildx imagetools create`. That's why the published image runs natively on both Intel and Apple-Silicon/ARM hosts.

---

## 3. How defoogi Runs (The Runtime Model)

Three scripts implement the "just prefix your command" experience: `start` (installed as `defoogi`), `cntnr-init` (the in-container entrypoint), and `defoogi-make` (a `make` convenience wrapper).

### 3.1 `start` → installed as `defoogi`

You copy `start` into your `PATH` renamed to `defoogi` (`make install` does `cp start /usr/local/bin/defoogi`). Because the script keys off its own name (`IMAGE=$(basename $0):latest`), the executable name *is* the image name.

When you run `defoogi make`, `start` issues roughly:

```bash
docker run --privileged -v /dev:/dev --cap-add=SYS_ADMIN --cap-add SYS_PTRACE \
  -e DISPLAY -v ${HOME}/.Xauthority:/home/wario/.Xauthority --net=host \
  --rm -e HOSTDIR="${PWD}" -v "${PWD}":/workspace \
  fozztexx/defoogi:latest make
```

Notable bits:

- **`-v "${PWD}":/workspace`** — your current directory becomes `/workspace` in the container.
- **`-e HOSTDIR="${PWD}"`** — tells the container the *real* host path, so it can recreate it (see §3.2).
- **X11 passthrough** (`DISPLAY`, `.Xauthority`, `--net=host`) — so GUI tools (e.g. AppleCommander's GUI) can display.
- **`--privileged` + `SYS_ADMIN`** — needed because the entrypoint performs a `mount --bind`.
- **`--rm`** for one-shot runs; `--daemon` keeps it running; `--shell`/`--super-shell` give you an interactive shell as the workspace user / root.

### 3.2 `cntnr-init` — the ownership-preservation magic

This is the entrypoint, and it's where the "no root-owned artifacts" promise is kept. On startup it:

1. Reads the **owner uid:gid of `/workspace`** (your mounted directory).
2. If that owner is a normal user (uid ≥ 1000), it **`usermod`/`groupmod`s the in-container `wario` user to match your uid:gid**. So when `wario` writes files, they're written as *you*.
3. **Bind-mounts `/workspace` back onto the original host path** (`HOSTDIR`) inside the container, then `cd`s there — so relative paths, `realpath`, and anything that records absolute paths match the host. (This is why `--privileged`/`SYS_ADMIN` are required.)
4. Drops privileges and runs your command as `wario` via `sudo -u wario -E --preserve-env=PATH -H env "$@"`.

That uid/gid remapping is the whole trick: artifacts come out owned by you, on Linux, with zero `chown`. (On Docker Desktop for macOS/Windows the file-sharing layer already remaps ownership, so the benefit is most visible on native Linux Docker.)

### 3.3 `defoogi-make` — directory-aware `make`

A thin wrapper so `make -C some/subdir` works through the container: it extracts the `-C`/`--directory` argument, mounts the *parent* directory, and re-invokes `defoogi --directory <parent> make -C <target>`. Useful when your build references files one level up from the makefile.

---

## 4. The Complete Toolchain Inventory

Everything defoogi contains, grouped by job. Versions are the pinned values from `versions.env`.

### 4.1 Cross-compilers (high-level languages → retro CPUs)

| Tool | Pinned version | CPU / target | What it is |
|------|----------------|--------------|------------|
| **cc65** | `6efe447` | 6502/65C02/65816 | C compiler **+ ca65 assembler + ld65 linker + ar65 + da65**. Targets C64, Apple II, Atari 8-bit, NES, VIC-20, Oric, and more. The backbone of FujiNet's 6502-family apps. |
| **CMOC** | `0.1.97` | 6809/6309 | C-like compiler for Motorola 6809. Targets Tandy CoCo, Dragon 32/64, OS-9. **Requires lwtools** (below). |
| **lwtools** | `4.24` | 6809/6309 | `lwasm` assembler + `lwlink` linker + `lwar`. CMOC emits assembly that lwasm/lwlink turn into binaries. |
| **z88dk** | `4c74585` (pre-release) | Z80/Z180/8080/8085 | C compiler (`zcc` driving **sccz80** *and* a bundled **SDCC**), assembler, linker, and a huge library covering 100+ Z80 machines: MSX, ZX Spectrum, CP/M, Amstrad CPC, Coleco/ADAM, etc. Built with `./build.sh -z` for **special MSX options** (per git log). |
| **Open Watcom v2** | `2025-08-02-Build` | 8086/80286/80386 (x86) | Full C/C++ compiler + linker (`wcc`, `wcl`, `wlink`) for DOS, 16-bit Windows, OS/2, CP/M-86. This is the FujiNet **MS-DOS / PC** toolchain. Self-hosting two-phase build. |
| **Mad Pascal** | `23e4c5f` | 6502 (Atari 8-bit) | Turbo-Pascal-compatible compiler for Atari 8-bit, paired with MADS as its backend. Ships with FujiNet Pascal libraries (`fn_cookies`, `fn_tcp`) — defoogi even patches them at build time. |

**FujiNet-specific Z80 libraries** added into z88dk:

| Library | Pinned version | Purpose |
|---------|----------------|---------|
| **eoslib** | `70d476b` | Coleco ADAM **EOS** (operating system) C library — `eos.lib` + `eos.h`. (tschak909) |
| **smartkeyslib** | `1.1` | ADAM **SmartKeys** function-key library. (tschak909) |

### 4.2 Assemblers

| Tool | Pinned version | CPU / target | Notes |
|------|----------------|--------------|-------|
| **ca65** | (part of cc65 `6efe447`) | 6502 family | cc65's macro assembler. |
| **lwasm** | (part of lwtools `4.24`) | 6809 | lwtools' assembler. |
| **MADS** (Mad-Assembler) | `2370bf0` | 6502 / Atari | Powerful Atari-centric 6502 macro assembler; the Atari-8-bit community standard. Built from Pascal via `fpc`. |
| **atasm** | `V1.30` | 6502 / Atari | MAC/65-compatible Atari assembler (built inside `dir2atr.docker`). |
| **nasm** | `e9fac2f` | x86 | The Netwide Assembler — modern x86/x86-64 assembly. |

### 4.3 Disk-image & file tools — *making the target media*

This is the part most "just install a compiler" guides forget: a compiled binary is useless until it's inside a disk image the target machine (or FujiNet) can mount. defoogi bundles a tool for **every** disk format FujiNet platforms use:

| Tool | Pinned version | Disk/file format | Platform |
|------|----------------|------------------|----------|
| **atari-tools** (`atr`) | `835d5a6` | `.ATR` (read/write/extract) | Atari 8-bit |
| **dir2atr** (from AtariSIO) | `bbccb15` | builds `.ATR` from a directory tree | Atari 8-bit |
| **cc1541** | `4.2` | `.D64` (1541 floppy image) | Commodore 64 / VIC-20 |
| **AppleCommander** (`ac`, `acx`) | `12.0` | `.dsk`, `.do`, `.po`, `.2mg`, ShrinkIt | Apple II |
| **cpmtools** (`cpmcp`, `cpmls`, `mkfs.cpm`) | `2.23` | CP/M filesystems | CP/M machines **+ Coleco ADAM** (custom `diskdefs`) |
| **mtools** (`mcopy`, `mformat`, …) | (Debian apt) | FAT12/16 floppy & disk images | MS-DOS / PC |
| **decb** (from Toolshed) | `v2_4_2` | Disk Extended Color BASIC `.dsk` | Tandy CoCo |

> **ADAM detail worth knowing:** `cpmtools.docker` writes a custom `/usr/local/share/diskdefs` defining `coleco-adam` (5.25″, 40 tracks) and `coleco-adam-3.5` (3.5″, 160 tracks) geometries — so you can build ADAM media that stock cpmtools doesn't know about out of the box.

### 4.4 Embedded / FujiNet-hardware toolchains

| Tool | Pinned version | Target | Role |
|------|----------------|--------|------|
| **PlatformIO** | latest (via `pipx`) | ESP32 (ESP-IDF / Arduino) | **The FujiNet firmware build system itself.** This is how the FujiNet device firmware is compiled and flashed. |
| **abimap** | latest (via `pipx`) | — | ABI/symbol-version map helper used in some build flows. |
| **Pico SDK** | `2.2.0` | RP2040 (Raspberry Pi Pico) | SDK at `/usr/local/share/pico-sdk` (`PICO_SDK_PATH` is preset) for RP2040-based FujiNet peripherals/variants. |
| **picotool** | (built w/ pico-sdk) | RP2040 | Inspect/flash RP2040 binaries. |

### 4.5 Base system, libraries & build dependencies (the invisible glue)

These come from `head`, `final`, and `tail`, and from being pulled in as dependencies. They're "free" inside defoogi but each is a thing you'd otherwise have to provide:

- **Debian 13.0** userland + **build-essential** (gcc/g++/make), **git**, **ca-certificates**, **cmake**.
- **Free Pascal Compiler (`fpc`)** — required to build MADS / Mad Pascal.
- **default-jdk (Java)** — pulled in as a dependency of AppleCommander; required to run `ac`/`acx`.
- **SDCC** — built *as part of* z88dk (`BUILD_SDCC=1`).
- A large pile of **Perl modules** (Capture::Tiny, Clone, Path::Tiny, YAML, Modern::Perl, …) plus `bison`, `flex`, `ragel`, `re2c`, `m4`, `ccache`, `texinfo` — all required just to build z88dk.
- Runtime utilities in `tail`: `mtools`, `curl`, `wget`, `file`, `jq`, `xxd`, `zip`/`unzip`, `less`, `bsdmainutils`, `libz-dev`, `sudo`.
- Preset environment: `WATCOM=/opt/watcom`, `PATH+=${WATCOM}/binl`, `PLATFORMIO_CORE_DIR=/workspace/.platformio`, `PICO_SDK_PATH=/usr/local/share/pico-sdk`.

### 4.6 Declared-but-not-built (housekeeping note)

Two entries are referenced but **not currently produced** by any Dockerfile in this revision:

- `versions.env` pins **`VASM=2_0c`**, but there is no `vasm.docker`.
- `tail.docker` exports **`VBCC=/opt/vbcc`** and adds `${VBCC}/bin` to `PATH`, but no `vbcc.docker` builds it and there's no `VBCC` version pin.

These look like scaffolding for a planned **vasm/vbcc (Amiga/68k-style)** toolchain. They're harmless today (the `PATH` entry just points at a non-existent dir) but worth flagging so you don't go looking for `vasmm68k` and wonder why it's missing.

---

## 5. Installing Each Tool Yourself (The Hard Way)

This section answers "what if I *didn't* use defoogi?" — what it actually takes to stand up each tool on **Linux**, **Windows**, and **macOS**. The pattern that emerges: a few tools are well-packaged everywhere, but the *majority are source-only*, several **do not build natively on Windows** (Cygwin/MSYS required), and **none of the platform combinations gets you a pinned, mutually-compatible set** without manual version juggling.

Legend: ✅ packaged/easy · ⚠️ build-from-source or caveats · ❌ no native path (needs Cygwin/MSYS/VM)

### 5.1 cc65 (6502)

| | Method |
|---|---|
| **Linux** | ✅ `apt install cc65` (Debian/Ubuntu); also openSUSE Build Service RPM/DEB. |
| **macOS** | ✅ `brew install cc65`. |
| **Windows** | ✅ Official `.exe` snapshot installer (sets env vars) **or** unzip the Windows binary snapshot. |

cc65 is the *easy* one. Caveat: distro packages can lag the upstream git `HEAD` that FujiNet may rely on, so you may still end up doing `git clone && make` to match `versions.env`'s `6efe447`.
Sources: [Homebrew](https://formulae.brew.sh/formula/cc65), [cc65 getting-started](https://cc65.github.io/getting-started.html), [NESdev: Installing CC65](https://www.nesdev.org/wiki/Installing_CC65).

### 5.2 CMOC + lwtools (6809)

| | Method |
|---|---|
| **Linux** | ⚠️ Build both from source. `lwtools`: download tarball, `make && make install`. `CMOC`: `./configure && make && make install` (needs `flex`/`yacc`). lwasm/lwlink must be on `PATH`. |
| **macOS** | ⚠️ Same source build — CMOC explicitly supports Darwin, but no Homebrew formula; you compile it. |
| **Windows** | ❌ Per the CMOC author, it **cannot be compiled as a native Windows app** — you must use **Cygwin** (lwtools likewise). A third-party **WinCMOC** bundle exists on SourceForge but lags far behind (≈v0.5) and isn't the pinned `0.1.97`. |

defoogi additionally builds **`decb`** from Toolshed here (CoCo `.dsk` handling) — another from-source step you'd have to replicate.
Sources: [CMOC homepage](https://perso.b2b2c.ca/~sarrazip/dev/cmoc.html), [CMOC manual](https://perso.b2b2c.ca/~sarrazip/dev/cmoc-manual.html), [LWTOOLS on Windows via Cygwin](https://subethasoftware.com/2022/06/16/installing-lwtools-on-windows-using-cygwin/).

### 5.3 z88dk + SDCC (Z80)

| | Method |
|---|---|
| **Linux** | ⚠️ Nightly source tarball or `git clone --recursive` + `./build.sh`; a **snap** exists for some distros but won't be the pinned commit or carry the `-z` MSX flags. |
| **macOS** | ⚠️ Nightly `z88dk-osx-latest.zip` exists, but to match defoogi's pinned pre-release commit with MSX options you build from source. |
| **Windows** | ❌/✅ Nightly `z88dk-win32-latest.zip` is available, **but building the classic libs from source requires MSYS or Cygwin**. |

Then you'd *still* have to clone & build **eoslib** and **smartkeyslib** and drop them into z88dk's lib tree — exactly what `z88dk.docker` does. And z88dk's build pulls in a long list of Perl modules + bison/flex/ragel/re2c.
Sources: [z88dk installation wiki](https://github.com/z88dk/z88dk/wiki/installation), [nightly builds](http://nightly.z88dk.org/).

### 5.4 Open Watcom v2 (x86 / DOS)

| | Method |
|---|---|
| **Linux** | ✅/⚠️ Download the portable snapshot zip (`ow_portable_v2_stable.zip`) and set `WATCOM`/`PATH`/`INCLUDE`; or build from source (two-phase, slow). |
| **macOS** | ⚠️ Portable snapshot / build from source; set env vars manually. |
| **Windows** | ✅ Official installer from the snapshot builds. |

Workable, but you must pick a build and wire up three environment variables (`WATCOM`, `INCLUDE`, `PATH`) yourself — defoogi presets them. The source build "takes *forever*" (Dockerfile's own words).
Sources: [Open Watcom v2 install.txt](https://github.com/open-watcom/open-watcom-v2/blob/master/build/server/install.txt), [openwatcom.org](https://www.openwatcom.org/).

### 5.5 MADS + Mad Pascal (Atari 6502)

| | Method |
|---|---|
| **Linux** | ⚠️ Install `fpc`, then `fpc -Mdelphi mads.pas` and `fpc src/mp.pas` from the Mad-Assembler / Mad-Pascal git repos. |
| **macOS** | ⚠️ Same — install Free Pascal, build from source. |
| **Windows** | ✅/⚠️ Prebuilt Windows binaries are published by the author (tebe6502); otherwise install FPC and build. |

You'd also need to replicate defoogi's library staging (copying `base/lib/blibs/dlibs`, creating upper-case symlinks) **and** the FujiNet `fn_cookies`/`fn_tcp` source patch to build current FujiNet Pascal code.

### 5.6 atasm / dir2atr (AtariSIO) — Atari disk tooling

| | Method |
|---|---|
| **Linux** | ⚠️ `atasm`: clone & `make`. `dir2atr`: clone **AtariSIO** (`make tools && make tools-install`); needs `libncurses-dev`. |
| **macOS** | ⚠️ Build from source; AtariSIO is Linux-centric (it's primarily a kernel SIO driver project) so expect minor portability fixes. |
| **Windows** | ⚠️ Hias publishes Windows builds of the AtariSIO tools; atasm builds under MSYS/MinGW. |

### 5.7 atari-tools (`atr`) — Atari ATR

| | Method |
|---|---|
| **Linux / macOS** | ⚠️ `git clone jhallen/atari-tools && make`. No package. |
| **Windows** | ⚠️ Build under MSYS/Cygwin. |

### 5.8 cc1541 — Commodore D64

| | Method |
|---|---|
| **Linux** | ⚠️ Clone from Bitbucket, `make && make install`. (Some community AUR/Homebrew packages exist but versions vary.) |
| **macOS** | ⚠️ Source build. |
| **Windows** | ⚠️ Source build under MSYS/MinGW. |

### 5.9 AppleCommander (`ac`/`acx`) — Apple II disks

| | Method |
|---|---|
| **All three** | ✅/⚠️ Download the cross-platform **jars** from GitHub releases — but you must have **Java 11+** installed, and you'll want to write `ac`/`acx` shell-script wrappers (`java -jar …`) yourself. defoogi does both (and pulls `default-jdk` automatically). |

Source: [AppleCommander releases](https://github.com/AppleCommander/AppleCommander/releases), [install guide](https://applecommander.github.io/install/) (Java 11 required).

### 5.10 cpmtools / mtools — CP/M & FAT images

| | Method |
|---|---|
| **Linux** | ✅ `apt install cpmtools mtools`. |
| **macOS** | ✅ `brew install cpmtools mtools`. |
| **Windows** | ⚠️ Cygwin build for cpmtools; mtools via Cygwin/MSYS. |

Even here, you'd have to add defoogi's custom **Coleco ADAM `diskdefs`** by hand to make ADAM media.
Sources: [cpmtools Homebrew](https://formulae.brew.sh/formula/cpmtools), [GNU mtools](https://www.gnu.org/software/mtools/).

### 5.11 nasm — x86 assembler

| | Method |
|---|---|
| **Linux** | ✅ `apt install nasm`. |
| **macOS** | ✅ `brew install nasm`. |
| **Windows** | ✅ Official installer/binaries. |

Source: [nasm Homebrew](https://formulae.brew.sh/formula/nasm).

### 5.12 PlatformIO + Pico SDK — embedded

| | Method |
|---|---|
| **All three** | ✅ PlatformIO: `pipx install platformio` (cross-platform). |
| **Pico SDK** | ⚠️ Clone `pico-sdk` + submodules, set `PICO_SDK_PATH`, and install the **`gcc-arm-none-eabi`** cross toolchain + newlib; build **picotool** from source (needs `libusb`, `cmake`, `pkg-config`). |

PlatformIO is genuinely easy everywhere; the Pico SDK is the usual "clone + submodules + ARM toolchain + env var" dance, which defoogi has already done and wired up.

### 5.13 The DIY pain summary

| Tool | Linux | Windows | macOS | Packaged anywhere? |
|------|:----:|:------:|:----:|---|
| cc65 | ✅ | ✅ | ✅ | apt, brew, .exe |
| nasm | ✅ | ✅ | ✅ | apt, brew, .exe |
| cpmtools / mtools | ✅ | ⚠️ | ✅ | apt, brew |
| Open Watcom v2 | ⚠️ | ✅ | ⚠️ | snapshot/installer |
| AppleCommander | ⚠️ | ⚠️ | ⚠️ | jar (needs JDK 11) |
| PlatformIO | ✅ | ✅ | ✅ | pipx |
| z88dk (+eoslib/smartkeys) | ⚠️ | ❌ | ⚠️ | nightly/snap (not pinned) |
| CMOC + lwtools | ⚠️ | ❌ | ⚠️ | source only |
| MADS / Mad Pascal | ⚠️ | ✅* | ⚠️ | source (Win binaries) |
| atasm / dir2atr / atari-tools | ⚠️ | ⚠️ | ⚠️ | source only |
| cc1541 | ⚠️ | ⚠️ | ⚠️ | source (mostly) |
| Pico SDK + picotool | ⚠️ | ⚠️ | ⚠️ | source + ARM toolchain |

\* Windows binaries published by upstream author, version may differ from the pin.

Tally: of ~13 tool groups, only **3** (cc65, nasm, PlatformIO) are genuinely one-command everywhere. **Two won't build natively on Windows at all.** And **none** of this gives you version pins matched to a FujiNet release.

---

## 6. Why defoogi Is the More Complete Option

The DIY matrix above shows the *breadth* problem. Here's why the container wins on the dimensions that actually matter for FujiNet development:

1. **One install, not thirteen.** `docker pull fozztexx/defoogi` (or build once) replaces a multi-day setup involving apt, Homebrew, pipx, Java, Free Pascal, Cygwin/MSYS, and a half-dozen `git clone && make` builds — *per developer, per machine*.

2. **Reproducibility pinned to FujiNet releases.** `versions.env` freezes ~19 components at exact commits/tags. A given defoogi tag (1.4.6) is a *known-good constellation* that builds the matching FujiNet sources. With DIY installs, every machine drifts to slightly different upstream versions and "works on my machine" bugs follow. defoogi can be **rebuilt from an old tag** to reproduce a historical build exactly.

3. **True cross-platform parity.** The container is byte-for-byte identical on Linux, Windows (Docker Desktop/WSL2), and macOS (incl. Apple Silicon via the multi-arch manifest). The DIY path is *different on every OS* — and on Windows, several tools require Cygwin/MSYS that subtly change behavior.

4. **The disk-image tools are included and pre-configured.** Compilers are only half the job; you need `atr`, `dir2atr`, `cc1541`, `ac`/`acx`, `cpmtools` (with **ADAM diskdefs**), `mtools`, and `decb` to produce mountable media. defoogi ships all of them, wired up — including custom config a fresh install wouldn't have.

5. **All the build glue is solved.** Java for AppleCommander, FPC for MADS, SDCC inside z88dk, the Perl-module wall z88dk needs, the FujiNet `fn_cookies`/`fn_tcp` patches, the eoslib/smartkeyslib staging, `WATCOM`/`PICO_SDK_PATH` env vars — all pre-resolved.

6. **Ownership preservation.** Build artifacts come out owned by you (uid/gid remap + bind-mount), so there's no `sudo chown` ritual and no root-owned junk in your repo.

7. **Local and CI are the same environment.** The exact image used on your laptop runs in GitHub Actions, enabling the **edit → push → CI build → mount over HTTP via FujiNet → boot** workflow the README describes. DIY means maintaining two parallel setups (your machine *and* the CI image) and keeping them in sync.

8. **FujiNet firmware *and* apps in one place.** It's the only environment that covers both the **device firmware** (PlatformIO/ESP32, Pico SDK) and **every client-platform app toolchain** — so firmware devs and app devs share one tool.

The honest counterpoint: defoogi requires Docker, the first build/pull is large, `--privileged` is needed for the bind-mount trick, and GUI/serial-flashing workflows need the X11/`/dev` passthrough the `start` script sets up. For the FujiNet use case, those costs are small next to maintaining a dozen hand-built cross toolchains across three operating systems.

---

## 7. Using defoogi Day-to-Day

### 7.1 Install

```bash
# 1. Get Docker (the repo even ships get-docker.py for Debian-family Linux)
./get-docker.py            # adds Docker's apt repo + installs docker-ce; adds you to the docker group

# 2. Put the launcher on your PATH, named `defoogi`
sudo make install          # cp start /usr/local/bin/defoogi
#   or manually:  cp start ~/bin/defoogi && chmod +x ~/bin/defoogi

# 3. (first run pulls fozztexx/defoogi:latest automatically)
```

To **build the image yourself** (reproducible from pins):

```bash
make            # assembles + builds defoogi:1.4.6 and defoogi:latest
make rebuild    # --no-cache --pull, full clean build
```

### 7.2 Everyday usage

```bash
cd ~/my-fujinet-app

defoogi make                 # run the project's Makefile in-container
defoogi cc65 hello.c         # invoke a single tool
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

### 7.3 CI/CD (GitHub Actions)

Use the same image as a container step so CI builds bit-identically to local, then publish the artifact as a downloadable asset that FujiNet can mount over HTTP. The README's promised loop: **edit → push → CI builds with defoogi → boot retro machine → mount the build directly via FujiNet → run.** No floppies, no SD-card sneakernet.

### 7.4 Troubleshooting quick hits

- **`No /workspace directory found` warning** → you ran the raw container without the `start`/`defoogi` wrapper; use `defoogi …` (it sets `-v $PWD:/workspace` and `HOSTDIR`).
- **Artifacts owned by a system user** → if `/workspace` is owned by a uid < 1000, `cntnr-init` deliberately skips the remap and warns; run from a normally-owned directory.
- **GUI tool won't display** → ensure `$DISPLAY` is set and `~/.Xauthority` exists; `start` forwards both with `--net=host`.
- **`vasm`/`vbcc` not found** → expected; they're declared in `versions.env`/`tail` but not built in this revision (see [§4.6](#46-declared-but-not-built-housekeeping-note)).

---

## Appendix A — Version Pin Reference

Every pin in `versions.env`, with what it controls. `defoogi` tag at time of writing: **1.4.6**.

| `versions.env` key | Value | Controls | Built by |
|---|---|---|---|
| `AC` | `12.0` | AppleCommander jars | `applecommander.docker` |
| `ATARISIO` | `bbccb15` | dir2atr (AtariSIO tools) | `dir2atr.docker` |
| `ATARITOOLS` | `835d5a6` | `atr` (atari-tools) | `atari-tools.docker` |
| `ATASM` | `V1.30` | atasm assembler | `dir2atr.docker` |
| `CC1541` | `4.2` | cc1541 (D64) | `cc1541.docker` |
| `CC65` | `6efe447` | cc65 suite | `cc65.docker` |
| `CMOC` | `0.1.97` | CMOC 6809 compiler | `cmoc.docker` |
| `CPMTOOLS` | `2.23` | cpmtools (+ADAM diskdefs) | `cpmtools.docker` |
| `EOSLIB` | `70d476b` | ADAM EOS lib (in z88dk) | `z88dk.docker` |
| `LWTOOLS` | `4.24` | lwasm/lwlink (for CMOC) | `cmoc.docker` |
| `MADSASM` | `2370bf0` | Mad-Assembler | `mads.docker` |
| `MADSPAS` | `23e4c5f` | Mad-Pascal | `mads.docker` |
| `OW2` | `2025-08-02-Build` | Open Watcom v2 | `open-watcom-v2.docker` |
| `PICOSDK` | `2.2.0` | Pico SDK + picotool | `pico-sdk.docker` |
| `SMARTKEYS` | `1.1` | ADAM SmartKeys lib (in z88dk) | `z88dk.docker` |
| `TOOLSHED` | `v2_4_2` | `decb` (CoCo .dsk) | `cmoc.docker` |
| `VASM` | `2_0c` | *(declared, not built)* | — |
| `Z88DK` | `4c74585` | z88dk + SDCC | `z88dk.docker` |
| `NASM` | `e9fac2f` | nasm | `nasm.docker` |

Not in `versions.env` (installed at latest): **PlatformIO**, **abimap**, **mtools**, **default-jdk (Java)**, **fpc**, **SDCC** (built within z88dk), **cmake**.

---

## Appendix B — The Generated Dockerfile

What the `Makefile` actually feeds to `docker build` (written to `/tmp/defoogi.dockerfile`), conceptually:

```
[ head.docker ]                         # FROM debian:13.0 AS tooling
[ cc65.docker ]                         # FROM tooling AS cc65        → /tmp/cc65.deb
[ cmoc.docker ]                         # FROM tooling AS cmoc        → /tmp/cmoc.deb
[ z88dk.docker ]                        #   …one stage per component, built in parallel
[ … every other component … ]
[ final.docker ]                        # FROM tooling   (the final image; installs PlatformIO)
COPY --from=cc65 /tmp/cc65.deb /tmp/packages/      ← generated by sed
COPY --from=cmoc /tmp/cmoc.deb /tmp/packages/
COPY --from=…   …                                   (one COPY per component)
[ tail.docker ]                         # apt-get install /tmp/packages/*.deb; runtime tools;
                                        # env vars; create `wario`; ENTRYPOINT cntnr-init
```

Build-args are injected from `versions.env` (`AC=12.0` → `--build-arg AC_VERSION=12.0`), plus `MAINTAINER` and `WSUSER`.

---

## Appendix C — Sources & References

**defoogi itself**
- defoogi repository: `github.com/tschak909/defoogi` (analyzed locally at `~/Workspace/defoogi`, tag 1.4.6)
- Docker Hub: https://hub.docker.com/repository/docker/fozztexx/defoogi
- FujiNet: https://fujinet.online

**Toolchains**
- cc65: https://cc65.github.io/ · [Homebrew formula](https://formulae.brew.sh/formula/cc65) · [NESdev install guide](https://www.nesdev.org/wiki/Installing_CC65)
- CMOC: https://perso.b2b2c.ca/~sarrazip/dev/cmoc.html · [manual](https://perso.b2b2c.ca/~sarrazip/dev/cmoc-manual.html) · [lwtools on Windows/Cygwin](https://subethasoftware.com/2022/06/16/installing-lwtools-on-windows-using-cygwin/)
- lwtools: http://www.lwtools.ca/
- z88dk: https://www.z88dk.org/ · [installation wiki](https://github.com/z88dk/z88dk/wiki/installation) · [nightly builds](http://nightly.z88dk.org/)
- Open Watcom v2: https://www.openwatcom.org/ · [install.txt](https://github.com/open-watcom/open-watcom-v2/blob/master/build/server/install.txt) · https://open-watcom.github.io/
- MADS / Mad-Pascal: https://github.com/tebe6502/Mad-Assembler · https://github.com/tebe6502/Mad-Pascal
- atasm: https://github.com/CycoPH/atasm
- AtariSIO (dir2atr): https://github.com/HiassofT/AtariSIO
- atari-tools: https://github.com/jhallen/atari-tools
- cc1541: https://bitbucket.org/ptv_claus/cc1541
- AppleCommander: https://applecommander.github.io/ · [releases](https://github.com/AppleCommander/AppleCommander/releases) · [install (Java 11)](https://applecommander.github.io/install/)
- cpmtools: https://www.moria.de/~michael/cpmtools/ · [Homebrew](https://formulae.brew.sh/formula/cpmtools)
- mtools: https://www.gnu.org/software/mtools/
- nasm: https://www.nasm.us/ · [Homebrew](https://formulae.brew.sh/formula/nasm)
- Toolshed (decb): https://github.com/nitros9project/toolshed
- eoslib / smartkeyslib: https://github.com/tschak909/eoslib · https://github.com/tschak909/smartkeyslib
- PlatformIO: https://platformio.org/
- Pico SDK / picotool: https://github.com/raspberrypi/pico-sdk · https://github.com/raspberrypi/picotool

---

*Document generated for the FujiNet manuals project. Verified against defoogi v1.4.6 source. Where this manual lists upstream packaging behavior it reflects the state at June 2026; individual upstreams may change.*
