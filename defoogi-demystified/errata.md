# Errata / open items

Source-derived findings and things to confirm with the defoogi maintainer:

* **`VASM` / `VBCC` are declared but not built.** `versions.env` pins
  `VASM=2_0c` with no `vasm.docker`; `tail.docker` exports `VBCC=/opt/vbcc`
  (and adds `$VBCC/bin` to `PATH`) with no `vbcc.docker` and no `VBCC` pin.
  Documented in §4 as scaffolding for a planned vasm/vbcc toolchain — worth
  confirming whether they're intended for a future release or should be
  removed.
* **PlatformIO / abimap versions float.** They're installed at latest via
  `pipx` in `final.docker` rather than pinned in `versions.env`, so they're
  the one part of the toolchain not covered by the reproducibility guarantee.
  Confirm whether this is intentional.
* **Photos/screenshots:** none required for this manual (the cover terminal
  and code listings are typeset, not captured). Add real `docker build` /
  CI-run screenshots later if desired.
* **Verify pins on next defoogi tag** — re-check Appendix A against
  `versions.env` whenever defoogi bumps past 1.4.6.
