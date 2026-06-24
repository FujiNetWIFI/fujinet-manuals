# Writing Cross-Platform FujiNet Apps

A developer's guide to writing **one C program** that runs on Atari,
Coleco ADAM, Apple II, Tandy CoCo, and IBM PC / MS-DOS — over
[FujiNet](https://fujinet.online) — using the **fujinet-lib** client
library, the **defoogi** build container, the **github.dev** browser
editor, and **GitHub Actions CI/CD** to compile and package every
platform automatically. The resulting disks are tested either on an
emulator driven by **FujiNet-PC**, or on real hardware.

It is the hands-on companion to *defoogi Demystified*: that book
explains the container; this one shows you how to ship apps with it.
Styled to match — JetBrains Mono display type, dark terminal code
blocks, Docker-blue rules, terminal-green accents.

## Contents

1. The Workflow at a Glance — edit in the browser, build in the cloud, run on iron
2. What You Build Against — `fujinet-lib`, the `N:` device, and the five targets
3. The App Skeleton — one source tree, many machines
4. Writing the Code — a worked cross-platform HTTP + JSON app
5. Building with defoogi — the prefix, the toolchains, the disk images
6. Editing in github.dev — zero local install
7. CI/CD — build in the cloud, produce downloadable packages
8. Testing on an Emulator with FujiNet-PC
9. Testing on Real Hardware — SD, TNFS, and mounting the CI build by URL
10. Appendix A — `fujinet-lib` API quick reference
11. Appendix B — Per-platform cheat sheet
12. Appendix C — Sources & further reading

## Sources

Every technical claim is cross-referenced against the repositories in
the workspace, as of June 2026:

- **`fujinet-lib`** (v4.10.0) — the client library: `Makefile`,
  `makefiles/*.mk`, and the public API (`fujinet-network.h`,
  `fujinet-fuji.h`, `fujinet-clock.h`).
- **`fujinet-lib-examples`** — the canonical consumer-app pattern:
  `makefiles/build.mk`, `makefiles/fujinet-lib.mk`,
  `makefiles/custom-*.mk`, and the worked apps (`network/echo-test`,
  `network/mastodon`, `clock/get_time`).
- **`defoogi`** (v1.4.6) — the build container (`README.md`, `start`,
  `versions.env`), and `fujinet-lib`'s own `.github/workflows/ci.yml`
  for the real CI/CD pattern.
- **`fujinet-emulator-bridge`** / the `fujinet-pc-*` projects — the
  emulator + NetSIO + FujiNet-PC test path.

## Building

```
make            # writing-cross-platform-fujinet-apps.pdf
make watch      # rebuild on save
make preview    # preview/page-NN.png at 110 ppi
make clean
```

Requires Typst 0.13+. Fonts are vendored in `fonts/` (JetBrains Mono —
display type and code; DejaVu Sans — body text).

## Wiki

A GitHub-flavored Markdown edition lives in
[`wiki/Writing-Cross-Platform-FujiNet-Apps.md`](wiki/Writing-Cross-Platform-FujiNet-Apps.md).
