# Writing Cross-Platform FujiNet Apps

### Edit in the browser · Build in the cloud · Run on iron

*A developer's guide to writing **one C program** that runs on Atari, Coleco ADAM, Apple II, Tandy CoCo, and IBM PC / MS-DOS — over [FujiNet](https://fujinet.online) — using **fujinet-lib**, the **defoogi** build container, the **github.dev** browser editor, and **GitHub Actions** CI/CD.*

*Source-verified against `fujinet-lib` v4.10.0, `fujinet-lib-examples`, `defoogi` v1.4.6, and `fujinet-emulator-bridge`, as of June 2026.*

---

## Table of Contents

1. [The Workflow at a Glance](#1-the-workflow-at-a-glance)
2. [What You Build Against: fujinet-lib](#2-what-you-build-against-fujinet-lib)
3. [The App Skeleton](#3-the-app-skeleton)
4. [Writing the Code](#4-writing-the-code)
5. [Building with defoogi](#5-building-with-defoogi)
6. [Editing in github.dev](#6-editing-in-githubdev)
7. [CI/CD — Build in the Cloud, Produce Packages](#7-cicd--build-in-the-cloud-produce-packages)
8. [Testing on an Emulator with FujiNet-PC](#8-testing-on-an-emulator-with-fujinet-pc)
9. [Testing on Real Hardware](#9-testing-on-real-hardware)
10. [Appendix A — fujinet-lib API Quick Reference](#appendix-a--fujinet-lib-api-quick-reference)
11. [Appendix B — Per-Platform Cheat Sheet](#appendix-b--per-platform-cheat-sheet)
12. [Appendix C — Sources & Further Reading](#appendix-c--sources--further-reading)

---

## 1. The Workflow at a Glance

This guide shows you how to write **one** C program and have it run on five very different computers — the Atari 8-bit, the Coleco ADAM, the Apple II, the Tandy Color Computer, and the IBM PC under MS-DOS — by talking to the network through [FujiNet](https://fujinet.online). You will never touch a 6502 datasheet, install a single cross-compiler, or own all five machines. The whole thing runs as a loop:

> **The loop:** *Edit* your code in the browser with **github.dev**. *Push.* **GitHub Actions** builds every platform for you inside the **defoogi** container and publishes a downloadable package per machine. *Test* the result on an **emulator driven by FujiNet-PC**, or on **real hardware** — and on real hardware you can have FujiNet **mount the CI build straight off the internet by URL.**

The reason this is possible at all is that FujiNet gives every one of these machines the *same* network device, and `fujinet-lib` gives you the *same* C API to drive it. Your program calls `network_open()`, `network_read()`, `network_json_query()`, `clock_get_time()` — and the library knows how to turn those calls into the right bus protocol for whichever machine it was compiled for.

### The five moving parts

| Piece | What it does for you |
|---|---|
| `fujinet-lib` | A C library with one network/`fuji`/clock API. You link your app against a prebuilt `.lib` for each target. (Ch. 2.) |
| **your app + Makefile** | One `src/` tree and a Makefile that just lists the target platforms. A shared build engine does the per-platform work. (Ch. 3–4.) |
| **defoogi** | Chris Osborn's Docker container with every cross-compiler already inside. Builds locally as a command prefix, and is the image CI runs in. (Ch. 5.) |
| **github.dev** | The browser version of VS Code. Edit and commit without installing anything. (Ch. 6.) |
| **GitHub Actions** | Compiles all platforms in `defoogi`, uploads a `.zip` per platform, and cuts a Release on a tag. (Ch. 7.) |

### Why "cross-platform" is realistic here

Targeting a 6502, a 6809, a Z80, and an x86 from one source file sounds like a fantasy. Three things make it routine for FujiNet apps:

- **The network device is identical everywhere.** FujiNet presents an `N:` device that speaks HTTP, TCP, UDP, TNFS and more. The protocol detail lives in the firmware, not your program.
- **`fujinet-lib` hides the bus.** Atari→SIO, Apple→SmartPort, ADAM→AdamNet, CoCo→serial, PC→RS-232 — every one is behind the same `network_*` functions and the same `fujinet-network.h`.
- **A small portable C subset goes a long way.** `conio.h` console I/O, plain `stdio`/`string`, and a handful of `#ifdef`s for the few genuinely machine-specific touches is enough for most utilities.

---

## 2. What You Build Against: fujinet-lib

`fujinet-lib` is the client library you link your application against. It is **not** the FujiNet firmware (that runs on the ESP32 inside the device); it is the small body of host code that runs on the *retro computer* and turns ordinary C function calls into FujiNet bus transactions.

### The `N:` device and the device spec

Everything network-shaped goes through a **device spec** string:

```text
N[unit]:PROTO://[HOSTNAME][:PORT]/PATH...
```

For example `N1:HTTPS://fujinet.online/` or `N2:TCP://192.168.1.10:6502/`. The leading `N` is the FujiNet network device; the optional unit digit (`N1`–`N8`) lets you keep up to eight connections open at once; the protocol is resolved inside the firmware. Protocols available today include `HTTP`/`HTTPS`, `TCP`, `UDP`, `TNFS`, `FTP`, `SMB`, `SSH`, and `TELNET`.

This is the key abstraction: **your code opens a URL, not a socket.** The firmware owns the TLS stack, the DNS resolver, and the protocol state machine. Your 1.79 MHz machine just reads and writes bytes.

### The three headers

The public API is three headers, shipped in every release zip alongside the compiled `.lib`:

| Header | Surface |
|---|---|
| `fujinet-network.h` | The `N:` device — open/read/write/close, HTTP verbs and headers, JSON parse/query, filesystem ops, plus error globals. |
| `fujinet-fuji.h` | The `THE FUJI` control device — adapter/Wi-Fi config, host & device (disk) slots, mounting, directory reads, AppKeys, base64, hashing. |
| `fujinet-clock.h` | The network clock — `clock_get_time()` in several binary and ISO string formats, with timezone support. |

### The network lifecycle

Almost every networking task is the same four-beat pattern: **init once**, then **open → transfer → close** per request.

```c
#include "fujinet-network.h"

uint8_t err;

err = network_init();                 /* once, at program start */

network_open(url, OPEN_MODE_HTTP_GET, OPEN_TRANS_NONE);
n = network_read(url, buffer, sizeof(buffer));
network_close(url);
```

`network_read()` returns the number of bytes read, or a **negative** value whose magnitude is the error code — so the idiom is "if it came back negative, `-n` is your error." `network_open()`'s `mode` is one of the `OPEN_MODE_*` constants and `trans` is an end-of-line translation (`OPEN_TRANS_NONE`, `…_CR`, `…_LF`, `…_CRLF`, `…_PET`):

| Constant | Value | Meaning |
|---|---|---|
| `OPEN_MODE_READ` / `…_HTTP_GET` | `0x04` | Read / HTTP GET |
| `OPEN_MODE_WRITE` / `…_HTTP_PUT` | `0x08` | Write / HTTP PUT |
| `OPEN_MODE_HTTP_POST` | `0x0D` | HTTP POST |
| `OPEN_MODE_HTTP_DELETE` | `0x05` | HTTP DELETE |
| `OPEN_MODE_RW` | `0x0C` | Read/write (e.g. TCP) |

### Error handling

Every fallible call returns a status byte. `FN_ERR_OK` is `0`; anything else is a problem:

| Code | Value | Meaning |
|---|---|---|
| `FN_ERR_OK` | `0x00` | Success |
| `FN_ERR_IO_ERROR` | `0x01` | I/O problem with the device |
| `FN_ERR_BAD_CMD` | `0x02` | Called with bad arguments |
| `FN_ERR_OFFLINE` | `0x03` | Device / network offline |
| `FN_ERR_WARNING` | `0x04` | Non-fatal, device-specific |
| `FN_ERR_NO_DEVICE` | `0x05` | No network device found |
| `FN_ERR_UNKNOWN` | `0xFF` | Device-specific, unmapped |

When you need more detail, the library exposes globals: `fn_device_error` holds the underlying device error after a failed call, and `fn_bytes_read` holds the count from the last read.

```c
void handle_err(uint8_t err, char *reason) {
    printf("Error: %d (dev: %d) %s\n", err, fn_device_error, reason);
    cgetc();        /* wait for a key */
    exit(1);
}
```

### JSON without a JSON parser

Parsing JSON on a 64 KB machine would be miserable, so FujiNet does it in the firmware. You hand it a URL, ask it to parse the response, then *query* individual fields with a JSONPath-like string:

```c
network_open(url, OPEN_MODE_READ, OPEN_TRANS_NONE);
network_json_parse(url);
network_json_query(url, "/0/account/display_name", buffer);
network_json_query(url, "/0/content", buffer);
network_close(url);
```

`network_json_query()` returns the length written to `buffer` (negative on error). This is the backbone of nearly every practical FujiNet app — weather, Mastodon, high-score tables, game lobbies — and we build one in Chapter 4.

### The targets this library supports

`fujinet-lib`'s own top-level `Makefile` builds: `adam apple2 apple2enh atari c64 plus4 vic20 coco msdos pmd85`. This guide concentrates on the five the question asks for — each built by a *different* compiler, which is exactly the plumbing defoogi exists to hide (Ch. 5):

| Target | CPU | Compiler | Bus to FujiNet |
|---|---|---|---|
| `atari` | 6502 | cc65 (`cl65`) | SIO |
| `apple2` / `apple2enh` | 6502 | cc65 (`cl65`) | SmartPort / IWM |
| `adam` | Z80 | z88dk (`zcc`, `+coleco -subtype=adam`) | AdamNet |
| `coco` | 6809 | CMOC (`cmoc`) | serial (DriveWire-style) |
| `msdos` | x86 | Open Watcom (`wcc`) | RS-232 |

> **apple2 vs apple2enh:** `apple2` targets the original II/II+; `apple2enh` targets the enhanced //e, //c and IIgs and unlocks 80-column mode and the full character set. Most network apps want `apple2enh`.

---

## 3. The App Skeleton

The fastest way to start is to copy the layout used by the official [`fujinet-lib-examples`](https://github.com/FujiNetWIFI/fujinet-lib-examples) repository, because its build engine already knows how to download the right library, invoke the right compiler, and build a disk image — for every target — from a single Makefile that does almost nothing.

### One repository, many machines

```text
myapp/
├── Makefile              # names the targets; delegates to the engine
├── application.mk        # optional: extra CFLAGS, unit-test hooks
└── src/
    ├── main.c            # shared code — compiled for every target
    ├── main.h
    ├── common/           # more shared code (recursed)
    ├── atari/            # files compiled ONLY for the atari platform
    ├── apple2/           # ONLY for apple2 / apple2enh
    └── current-target/
        └── coco/         # ONLY for the exact target "coco"
```

The build engine compiles, in order: every `src/*.c` and `src/*.s`; all of `src/common/`; everything under `src/<platform>/` for the current *platform*; and everything under `src/current-target/<target>/` for the exact *target*. That three-level split is your escape hatch — but most apps need only `main.c`.

> **Platform vs target:** a *target* is a precise build (`apple2enh`, `atarixl`); a *platform* is the family (`apple2`, `atari`). The engine maps targets to platforms (`apple2enh → apple2`, `plus4 → c64`), so `src/apple2/` is shared by both Apple targets.

### The application Makefile

You change exactly two lines — `TARGETS` and `PROGRAM` — and delegate everything else to the shared `makefiles/build.mk` engine:

```makefile
# Set the TARGETS and PROGRAM values as required.
TARGETS = atari apple2enh coco adam msdos
PROGRAM := myapp

SUB_TASKS := clean disk test release
.PHONY: all help $(SUB_TASKS)

all:
	@for target in $(TARGETS); do \
	  echo "----- Building $$target -----"; \
	  $(MAKE) --no-print-directory -f ../../makefiles/build.mk \
	    CURRENT_TARGET=$$target PROGRAM=$(PROGRAM) $(MAKECMDGOALS); \
	done

$(SUB_TASKS): _do_all
$(SUB_TASKS):
	@:
_do_all: all
```

That loop is the whole trick: for each target it re-invokes the engine with `CURRENT_TARGET` set. To add or drop a machine, edit the `TARGETS` list — nothing else.

> **Why two directories deep:** the engine paths are written relative to `../../makefiles/`, so your app must live *two levels below* the repo root (e.g. `network/myapp/`), like the examples (`network/mastodon/`).

### The build targets you get for free

| Command | What it does |
|---|---|
| `make` | Compile every target into `build/<program>.<target>`. |
| `make release` | Copy each built binary into `dist/` with its platform suffix. |
| `make disk` | `release`, then wrap each binary in a bootable disk image where a recipe exists (`.atr`, `.po`, …). |
| `make test` | Build, then launch the platform's emulator on the result. |
| `make clean` | Remove `build/`, `obj/`, `dist/`. |

### How the library gets there

You do **not** vendor the library into your repo. The engine's `makefiles/fujinet-lib.mk` downloads the correct release zip on demand, caches it under `_cache/`, adds its directory to the include path, and links the `.lib`:

```makefile
FUJINET_LIB_VERSION := 4.10.0
FUJINET_LIB_DOWNLOAD_URL = \
  https://github.com/FujiNetWIFI/fujinet-lib/releases/download/v$(FUJINET_LIB_VERSION)/fujinet-lib-$(CURRENT_TARGET)-$(FUJINET_LIB_VERSION).zip
```

The practical consequences: you **pin a version** (bump `FUJINET_LIB_VERSION` to move); each target pulls its own zip (`fujinet-lib-atari-4.10.0.zip`, …) containing that target's `.lib` plus the three headers; and **CI works the same way**, so a fresh runner downloads the same pinned library you built against locally.

---

## 4. Writing the Code

Let us build a real, useful, genuinely cross-platform app: a **feed reader** that fetches a public Mastodon timeline over HTTPS, parses the JSON in the firmware, and prints the latest post. It is modelled directly on the `network/mastodon` example, generalised to all five machines. The entire program is one `src/main.c`.

### The shared core

```c
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <ctype.h>

#include "fujinet-network.h"

uint8_t  screen_width;
uint8_t  buffer[1024];
char     url[]  = "n1:https://oldbytes.space/api/v1/timelines/public?limit=1";
char     q_name[]    = "/0/account/display_name";
char     q_created[] = "/0/created_at";
char     q_content[] = "/0/content";

void handle_err(uint8_t err, char *reason) {
    printf("Error: %d (dev: %d) %s\n", err, fn_device_error, reason);
    cgetc();
    exit(1);
}

/* Replace anything non-printable so a 40-column ROM font stays sane. */
void filter_buf(void) {
    char *c;
    for (c = (char *)buffer; *c != '\0'; ++c)
        if (!isascii(*c) || !isprint(*c)) *c = '?';
}

void query(char *q) {
    int16_t n = network_json_query(url, q, (char *)buffer);
    if (n < 0) handle_err(-n, "query");
    filter_buf();
}

void main(void) {
    uint8_t err;

    setup();                      /* per-machine screen setup (below) */
    clrscr();
    cputs("FujiNet feed reader\r\n");

    for (;;) {
        network_open(url, OPEN_MODE_READ, OPEN_TRANS_NONE);
        err = network_json_parse(url);
        if (err != FN_ERR_OK) handle_err(err, "parse");

        query(q_name);    printf("%*s", screen_width, buffer);
        query(q_created); printf("%*s", screen_width, buffer);
        query(q_content); printf("%s\n", buffer);

        network_close(url);
        cgetc();                  /* press a key for the next post */
    }
}
```

There is no HTTP code, no TLS, no JSON tokeniser anywhere in your program. The same source compiles for a 6502 Atari and an x86 PC.

### The few machine-specific touches

The only place you need per-machine code is screen setup. Wrap it in the compiler's predefined target macros:

```c
#ifdef __APPLE2__
#include <apple2.h>
#endif
#ifdef __ATARI__
#include <atari.h>
#endif

void setup(void) {
    uint8_t height;

#ifdef __APPLE2__
    videomode(VIDEOMODE_80COL);      /* apple2enh */
#endif
#ifdef __ATARI__
    OS.color2 = 0;                   /* black background */
#endif

    screensize(&screen_width, &height);

    if (network_init() != FN_ERR_OK)
        handle_err(FN_ERR_NO_DEVICE, "network_init");
}
```

| Macro | Defined when compiling for |
|---|---|
| `__ATARI__` | Atari 8-bit (cc65) |
| `__APPLE2__` | Apple II (cc65); `__APPLE2ENH__` also for `apple2enh` |
| `__CBM__` / `__C64__` | Commodore (cc65) |
| `__COCO__` | Tandy CoCo (CMOC) |
| `__MSDOS__` | IBM PC / DOS (Open Watcom; the lib's Makefile also defines it) |

### Portability rules of thumb

- **Assume 40 columns, light up 80 where you can.** Read the real width with `screensize()` and lay out from that.
- **The character set is ASCII-ish, not ASCII.** ROM fonts vary; the `filter_buf()` pass keeps a remote feed from spraying garbage.
- **Watch your memory.** These are 64 KB machines. Reuse one buffer; avoid `malloc` churn.
- **`int` is 16-bit.** Sizes are `uint16_t`; read counts come back `int16_t` so they can carry a negative error.
- **No threads, one request at a time** per `N:` unit — but you have eight units (`N1:`–`N8:`) if you need concurrency.

### Building it locally

With the skeleton in place and defoogi installed (Ch. 5):

```console
$ defoogi make clean
$ defoogi make release disk
----- Building atari -----
   cc65   src/main.c  ->  build/myapp.atari
   dir2atr           ->  dist/myapp.atr
----- Building apple2enh -----
   cc65   src/main.c  ->  build/myapp.apple2enh
   mk-bitsy          ->  dist/myapp-enh.po
   ...
   ✓ artifacts in dist/, owned by you
```

---

## 5. Building with defoogi

`defoogi` (by Chris Osborn, *@fozztexx*) is a single Docker container that bundles **every** compiler this guide needs — cc65 for the 6502 targets, CMOC for the CoCo's 6809, z88dk for the ADAM's Z80, Open Watcom for the PC's x86 — plus the disk-image tools (`dir2atr`, AppleCommander, …). The companion volume *defoogi Demystified* takes the container apart stage by stage; here we only need to *use* it.

### Install it as a command prefix

Grab the `start` script from the defoogi repo, rename it `defoogi`, and put it on your `PATH`:

```bash
curl -L https://raw.githubusercontent.com/FozzTexx/defoogi/main/start \
  -o ~/bin/defoogi
chmod +x ~/bin/defoogi
```

Then, from your app directory:

```bash
defoogi make release disk   # runs the Makefile in-container
defoogi cc65 hello.c        # or invoke one tool directly
defoogi cmoc program.c
```

The build happens inside the container, but **the artifacts land in your working directory owned by you**, not by `root`. No `sudo chown -R` afterwards.

> **What you get vs. installing toolchains by hand:** without defoogi you would install cc65, CMOC (needs Cygwin on Windows), z88dk (built from a specific commit with non-default flags), Open Watcom (a slow two-phase self-hosting build), *and* the disk tools — at mutually compatible versions, on every machine and every CI runner. defoogi turns all of that into `docker pull`.

### What a build produces, per platform

| Target | `release` output | `disk` output |
|---|---|---|
| `atari` | `myapp.com` | `myapp.atr` (bootable; `dir2atr` + `picoboot.bin`) |
| `apple2` / `enh` | `myapp.apple2` | `myapp.po` (bootable ProDOS; AppleCommander) |
| `c64` | `myapp.c64` (PRG) | `myapp.d64` |
| `coco` | `myapp.coco` | no disk recipe in the engine yet — ship the binary |
| `adam` | `myapp.adam` | no disk recipe in the engine yet — ship the binary |
| `msdos` | `myapp.msdos` | no disk recipe in the engine yet — ship the `.com`/`.exe` |

> **Disk recipes are per-platform and still filling in.** The shared engine ships `disk` recipes for `atari`, `apple2`, and `c64` today (`makefiles/custom-atari.mk`, `custom-apple2.mk`, `custom-c64.mk`). For CoCo, ADAM, and MS-DOS, `make disk` is effectively `make release` — you get the raw runnable, which you mount or copy directly (Ch. 9). Adding a recipe is just another `custom-<platform>.mk`; the `DISK_TASKS` hook is already there.

### The same image everywhere

defoogi is published to Docker Hub as `fozztexx/defoogi:<tag>` (e.g. `1.4.6`). When you pin that tag, your laptop build and your CI build use byte-for-byte the same compilers — which is why the cloud build can be trusted to match what you tested locally.

---

## 6. Editing in github.dev

You can write and ship a FujiNet app **without installing anything at all** — not even Docker — by editing in the browser and letting CI do the building.

### Press the dot

On any GitHub repository, press the `.` (period) key, or change the URL from `github.com/you/myapp` to `github.dev/you/myapp`. A full VS Code editor opens **in the browser**, with your repo loaded: syntax highlighting, multi-file search, the Source Control panel, extensions.

This is ideal for the inner loop of a FujiNet app, which is mostly editing C and a Makefile:

- Open `src/main.c`, make a change.
- Stage it in the Source Control panel, write a commit message, commit.
- Push (github.dev commits go straight to the repo).

That commit triggers the CI build in Chapter 7, which produces the per-platform packages. You never left the browser tab.

> **github.dev can't build.** github.dev is a lightweight *editor*. It has no terminal and cannot run `make` or `defoogi` — there is no compute behind it. *Editing* happens in github.dev; *building* happens in GitHub Actions (Ch. 7). If you want a browser environment that can actually run a build, that is **Codespaces** — a full container in the cloud where you *can* `docker run` defoogi or run the toolchains directly. Codespaces costs compute; github.dev is free. For this workflow you only need github.dev plus Actions.

### Why this matters for retro development

The traditional barrier to entry for 8-bit development is the toolchain install. The github.dev + Actions combination removes it: a collaborator with nothing but a web browser can fix a bug in your Atari *and* Apple *and* CoCo build, commit it, and have downloadable disk images a few minutes later. The skills required collapse to "edit C, press commit."

---

## 7. CI/CD — Build in the Cloud, Produce Packages

A GitHub Actions workflow runs your build **inside the defoogi container**, packages every platform, and publishes the results as downloadable artifacts — and, on a tagged commit, as a GitHub Release. It is the exact pattern `fujinet-lib` uses for its own releases, adapted to build an *application*.

### The build job

Drop this in `.github/workflows/ci.yml`. The crucial line is `container:` — every step then runs inside defoogi, so `cl65`, `cmoc`, `zcc`, `wcc`, and the disk tools are all simply *there*.

```yaml
name: CI

on:
  pull_request:
    branches: [ main ]
  push:
    tags: [ "v*" ]
  workflow_dispatch:        # run it by hand from the Actions tab

jobs:
  build:
    name: Build all platforms
    runs-on: ubuntu-latest
    container:
      image: fozztexx/defoogi:1.4.6     # the toolchains live here

    outputs:
      files: ${{ steps.list_zips.outputs.files }}

    steps:
      - uses: actions/checkout@v4

      - name: Build release disks
        run: make release disk          # already inside defoogi

      - name: Package each platform
        working-directory: dist
        run: |
          for f in *; do
            [ -f "$f" ] && zip -j "${f}.zip" "$f"
          done

      - name: List zip files
        id: list_zips
        shell: bash
        run: |
          echo 'files=["'"$(( cd dist; echo *.zip ) | sed -e 's/ /","/g')"'"]' >> $GITHUB_OUTPUT

      - name: Upload dist for later jobs
        uses: actions/upload-artifact@v4
        with:
          name: dist
          path: dist/
```

After this job runs on a pull request, the **Artifacts** section of the run holds a downloadable `dist` bundle — your Atari `.atr`, Apple `.po`, and the CoCo/ADAM/PC binaries — built from the commit you just pushed from github.dev. That is the whole "push, wait a moment, download" loop.

> **Run inside defoogi, not on the runner.** The Ubuntu runner has none of these cross-compilers; defoogi has all of them. Pin a real tag (not `latest`) so a green build today stays reproducible tomorrow — the same discipline as pinning `FUJINET_LIB_VERSION`.

### Per-platform artifacts (optional)

To download one platform at a time, fan the list out into a matrix — the trick `fujinet-lib`'s CI uses:

```yaml
  upload:
    needs: build
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    strategy:
      matrix:
        file: ${{ fromJson(needs.build.outputs.files) }}
    steps:
      - uses: actions/download-artifact@v4
        with: { name: dist, path: dist }
      - uses: actions/upload-artifact@v4
        with:
          name: ${{ matrix.file }}
          path: dist/${{ matrix.file }}
```

### Cutting a Release on a tag

When you push a version tag, CI turns the build into a public GitHub **Release** with each platform's zip attached as a downloadable asset that anyone — including a FujiNet on the other side of the world — can fetch by URL.

```yaml
  tagged-release:
    needs: build
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/tags/')
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v4
        with: { name: dist, path: dist }

      - name: Create the release
        uses: softprops/action-gh-release@v2
        with:
          files: dist/*.zip
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

Triggering a release is two commands from anywhere — including the github.dev Source Control panel:

```bash
git tag v1.0.0
git push origin v1.0.0
# -> CI builds in defoogi, attaches myapp-atari.atr.zip,
#    myapp-apple2.po.zip, myapp-coco.zip ... to Release v1.0.0
```

> **The asset URL is the point.** Each release asset has a stable `https://github.com/you/myapp/releases/download/v1.0.0/…` URL. In Chapter 9 you hand that URL straight to FujiNet and have it mount the build over the internet — no SD card, no cable. As defoogi's README puts it: *"the FujiNet can mount that HTTP asset directly as a disk image."*

---

## 8. Testing on an Emulator with FujiNet-PC

You do not need any of the five machines to test your build. **FujiNet-PC** is the FujiNet firmware compiled to run as a desktop program; pair it with a platform emulator and you have a complete virtual battlestation — the emulated computer on one side, a real FujiNet (in software) on the other, talking to the actual internet.

### The pieces

| Piece | Role |
|---|---|
| **Platform emulator** | Emulates the computer itself (Altirra for Atari; AppleWin for Apple II; an MSX/Coleco or ADAM emulator; an x86/DOS emulator for the PC). |
| **NetSIO / emulator bridge** | Relays the emulated machine's bus to FujiNet-PC over the network. For Atari this is the [`fujinet-emulator-bridge`](https://github.com/FujiNetWIFI/fujinet-emulator-bridge) (a NetSIO hub plus an Altirra custom device). |
| **FujiNet-PC** | The firmware as a desktop app — same `N:` device, web UI, and SD/host handling as real hardware. |

### The Atari path, concretely

Atari has the most mature emulator story, and the examples engine wires `make test` to it directly:

1. **Start the NetSIO hub** from the bridge repo:
   ```bash
   cd fujinet-emulator-bridge/fujinet-bridge
   python -m netsiohub
   ```
2. **Point Altirra at it** — add the `netsio.atdevice` custom device (System ▸ Configure System ▸ Peripherals ▸ Devices), detach `D1:` so FujiNet supplies the disk, and disable *Fast boot* so the handshake completes.
3. **Connect FujiNet-PC to the hub** — in its web UI, enable *SIO over Network* and give it the hub's host/IP.
4. **Boot your build.** Either let `make test` launch Altirra on your `.atr`, or mount the disk from FujiNet-PC and reboot the emulated Atari with `Shift+F5`.

The examples engine already knows how to start the emulator. With `ALTIRRA_HOME` (or `ATARI800_HOME`) set, from your app folder:

```bash
export ALTIRRA_BIN=~/altirra/Altirra64.exe
defoogi make test        # builds, then launches the emulator
# -> your app boots, talks to the real internet via FujiNet-PC
```

`make test` resolves the emulator command from `makefiles/custom-atari.mk` (`ATARI_EMULATOR=ALTIRRA` by default, or `ATARI800`). Each platform that has an emulator exposes its own knobs in the matching `custom-<platform>.mk`.

> **Coverage is uneven, and that's fine.** The turnkey `make test` path is most complete for Atari (and Commodore via VICE). For Apple, ADAM, CoCo, and DOS you may run the emulator by hand and point it at the `dist/` artifact, with FujiNet-PC providing `N:`. The build half of the loop — Chapters 3–7 — is identical for every platform; only the emulator wiring differs.

### Why bother with emulation at all

Two reasons. **Speed:** the edit → build → boot loop is seconds, no SD card shuffling. **Debugging:** emulators like Altirra and AppleWin have real debuggers, and the engine can emit symbol files for them (the Apple `custom-apple2.mk` even generates an AppleWin `debug.scr` from the build's `.lbl`). You can set a breakpoint on `_main` or on a `fujinet-lib` call and single-step your networking code.

---

## 9. Testing on Real Hardware

Three ways to get a CI build onto real iron, from most manual to most magical.

### 1 — Copy to the SD card (WebDAV)

FujiNet serves its SD card over WebDAV, so you can push a freshly built disk straight to it using a WebDAV client such as `duck` (Cyberduck CLI):

```bash
duck --upload dav://anonymous@fujinet.home/dav/myapp.atr \
  dist/myapp.atr -existing overwrite
```

Then boot the FujiNet, pick the disk in CONFIG, and run it. Good for rapid iteration when the machine is on your bench.

### 2 — Serve it from TNFS

Drop the disk on a TNFS server on your LAN (or a public one) and mount it through CONFIG like any other image. Handy when several people share one build, or the machine isn't next to your computer.

### 3 — Mount the CI build by URL (the magic one)

This is the move the whole pipeline was built for. Because Chapter 7 published your release asset at a stable HTTPS URL, you can have FujiNet **mount it directly off the internet** — no SD card, no cable, no local server:

```text
# In FujiNet CONFIG, mount a host/slot pointing at:
https://github.com/you/myapp/releases/download/v1.0.0/myapp.atr
# boot — you're running the exact artifact CI built
```

The complete loop, then, is: **edit in github.dev → push → Actions builds in defoogi and publishes a release → mount the release URL from FujiNet → boot.** You can run code on a 1983 Atari that you wrote, built, and shipped without ever leaving a browser tab. defoogi's README frames this as the headline workflow: *"Edit and commit your code from any modern machine, wait a moment for the CI build to finish, boot your retro computer, mount the build directly via FujiNet, and run it instantly."*

> **Booting from FujiNet, per platform.** How a machine boots a mounted image is platform-specific — which drive it is, how CONFIG presents slots, which button cold-starts it. Those details live in the per-platform *FujiNet CONFIG / Getting Started* manuals (Atari, ADAM, Apple II, CoCo, MS-DOS). This guide gets the *artifact* to the machine; those guides cover *running* it.

---

## Appendix A — fujinet-lib API Quick Reference

Signatures as of `fujinet-lib` v4.10.0. Full doc comments are in the shipped headers.

### fujinet-network.h

```c
uint8_t  network_init(void);
uint8_t  network_open (const char *spec, uint8_t mode, uint8_t trans);
uint8_t  network_close(const char *spec);
int16_t  network_read (const char *spec, uint8_t *buf, uint16_t len);
int16_t  network_read_nb(const char *spec, uint8_t *buf, uint16_t len);
uint8_t  network_write(const char *spec, const uint8_t *buf, uint16_t len);
uint8_t  network_status(const char *spec, uint16_t *bw, uint8_t *c, uint8_t *err);
uint8_t  network_ioctl(uint8_t cmd, uint8_t a1, uint8_t a2, const char *spec, ...);

/* HTTP */
uint8_t  network_http_set_channel_mode(const char *spec, uint8_t mode);
uint8_t  network_http_start_add_headers(const char *spec);
uint8_t  network_http_add_header(const char *spec, const char *header);
uint8_t  network_http_end_add_headers(const char *spec);
uint8_t  network_http_post(const char *spec, const char *data);
uint8_t  network_http_post_bin(const char *spec, const uint8_t *data, uint16_t len);
uint8_t  network_http_put(const char *spec, const char *data);
uint8_t  network_http_delete(const char *spec, uint8_t trans);

/* JSON (parsed in firmware) */
uint8_t  network_json_parse(const char *spec);
int16_t  network_json_query(const char *spec, const char *query, char *s);

/* Filesystem over N: */
uint8_t  network_fs_delete(const char *spec);
uint8_t  network_fs_rename(const char *spec);
uint8_t  network_fs_mkdir (const char *spec);
uint8_t  network_fs_rmdir (const char *spec);
uint8_t  network_fs_cd    (const char *spec);
uint8_t  network_fs_lock  (const char *spec);
uint8_t  network_fs_unlock(const char *spec);

/* Globals */
extern uint16_t fn_bytes_read;
extern uint8_t  fn_device_error;
extern uint16_t fn_network_bw;
extern uint8_t  fn_network_conn;
extern uint8_t  fn_network_error;
extern uint8_t  fn_default_timeout;
```

### fujinet-clock.h

```c
/* TimeFormat values: SIMPLE_BINARY, PRODOS_BINARY, APETIME_BINARY,
   TZ_ISO_STRING, UTC_ISO_STRING, APPLE3_SOS_BINARY */
uint8_t  clock_set_tz(const char *tz);
uint8_t  clock_get_tz(char *tz);
uint8_t  clock_get_time   (uint8_t *time_data, TimeFormat format);
uint8_t  clock_get_time_tz(uint8_t *time_data, const char *tz, TimeFormat format);
```

### fujinet-fuji.h (selected)

```c
bool fuji_get_adapter_config(AdapterConfig *ac);
bool fuji_get_wifi_status(uint8_t *status);
bool fuji_get_host_slots(HostSlot *h, size_t size);
bool fuji_get_device_slots(DeviceSlot *d, size_t size);
bool fuji_mount_host_slot(uint8_t hs);
bool fuji_mount_disk_image(uint8_t ds, uint8_t mode);
bool fuji_open_directory(uint8_t hs, char *path_filter);
bool fuji_read_directory(uint8_t maxlen, uint8_t aux2, char *buffer);
bool fuji_close_directory(void);
bool fuji_read_appkey (uint8_t key_id, uint16_t *count, uint8_t *data);
bool fuji_write_appkey(uint8_t key_id, uint16_t count, uint8_t *data);
/* plus base64_*, hash_*, ssid/scan, boot config ... */
```

---

## Appendix B — Per-Platform Cheat Sheet

| Target | CPU | Compiler | release file | disk recipe |
|---|---|---|---|---|
| `atari` | 6502 | cc65 `cl65` | `.com` | `.atr` ✅ |
| `apple2` | 6502 | cc65 `cl65` | `.apple2` | `.po` ✅ |
| `apple2enh` | 6502 | cc65 `cl65` | `.apple2enh` | `.po` ✅ |
| `coco` | 6809 | CMOC `cmoc` | `.coco` | binary (soon) |
| `adam` | Z80 | z88dk `zcc` | `.adam` | binary (soon) |
| `msdos` | x86 | Open Watcom `wcc` | `.msdos` | `.com`/`.exe` (soon) |

✅ = bootable disk recipe in the shared engine today · *soon* = ship the runnable; recipe is a future `custom-<platform>.mk`.

- **Target macros:** `__ATARI__`, `__APPLE2__` / `__APPLE2ENH__`, `__COCO__`, `__MSDOS__`, `__CBM__`/`__C64__`.
- **Predefined console subset:** `clrscr`, `cputs`, `cputc`, `cgetc`, `gotoxy`, `screensize`, `revers` (`conio.h`).
- **The two lines you edit in an app Makefile:** `TARGETS = …` and `PROGRAM := …`.
- **The version you pin:** `FUJINET_LIB_VERSION` in `makefiles/fujinet-lib.mk`, and the `fozztexx/defoogi:<tag>` image in `ci.yml`.

---

## Appendix C — Sources & Further Reading

All verified in the workspace, June 2026.

| Repository | What to read |
|---|---|
| [`FujiNetWIFI/fujinet-lib`](https://github.com/FujiNetWIFI/fujinet-lib) | The library, its `Makefile` / `makefiles/`, and the public headers. v4.10.0. |
| [`FujiNetWIFI/fujinet-lib-examples`](https://github.com/FujiNetWIFI/fujinet-lib-examples) | The canonical app pattern: `makefiles/build.mk`, `fujinet-lib.mk`, `custom-*.mk`, and worked apps (`network/mastodon`, `network/echo-test`, `clock/get_time`). |
| [`FozzTexx/defoogi`](https://github.com/FozzTexx/defoogi) | The build container — `README`, `start`, `versions.env`. v1.4.6. |
| [`FujiNetWIFI/fujinet-emulator-bridge`](https://github.com/FujiNetWIFI/fujinet-emulator-bridge) | NetSIO hub + Altirra custom device for the FujiNet-PC emulator path. |

**Companion manuals in `fujinet-manuals/`:**

- *defoogi Demystified* — the container taken apart stage by stage; the per-OS "install it yourself" matrix; CI/CD deep dive.
- *FujiNet Platform Bring-Up Guide* — the layer *below* this one: adding a brand-new platform to FujiNet (the ESP32 + RP2350 tandem).
- The per-platform *FujiNet CONFIG / Getting Started* guides (Atari, ADAM, Apple II, CoCo, MS-DOS) — booting and running images on each machine.
