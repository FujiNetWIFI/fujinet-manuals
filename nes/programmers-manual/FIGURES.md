# Figures

No photographs are needed. Everything is generated or captured:

| Figure | Source |
|---|---|
| cover / back starfields | `tools/make_starfield.py images/starfield.png 1985` (and `starfield-back.png 2026`) |
| block diagram, memory map, sequence diagrams, controller | drawn in Typst (`lib.typ`) |
| program screens (`hello-*`, `netget-*`, `json-*`, `dir-*`, `appkey-*`, `boot-*`, `clock-*`, `netcat-*`) | `emu/run.sh` against fujinet-pc, 2026-10-04 |
| game screens (`fcs-*`, `fbs-*`, `fz-*`, `tx-*`) | `emu/run.sh` + `emu/drive.lua` on the games' `r2r/nes/*.nes`, against the live carr-designs.com servers |
| CONFIG screens (`cfg-*`) | `fn-config-nes/nes/build/config.nes` (built 2026-10-04 16:12, one commit before cd33413) |

Re-take the CONFIG shots once a newer CONFIG build exists. Re-take any shot when a real cartridge does,
and replace the emulated screens with photographs of a TV if wanted.
