# FUJINET C DEMO -- Z88DK on the Bally Astrocade

The working companion to the handbook's "C on the Professional Arcade"
chapter: a complete FujiNet client in C, built with z88dk's `+astrocde`
target. It checks the cartridge magic, runs one
`GET_ADAPTERCONFIG_EXTENDED` transaction through the mailbox, and shows
the adapter's SSID, firmware version and IP address on screen.

| File | Role |
|---|---|
| `fujinet.h` / `fujinet.c` | the mailbox transport, a C rendering of `fujilib.inc` |
| `text.h` / `text.c` | byte-aligned 5x7 text (BIOS glyphs + lowercase), CONFIG's approach |
| `main.c` | screen setup, the demo itself |
| `support.asm` | console-driver stub + `port_out` (sccz80 has no port intrinsics here) |
| `build.sh` / `Makefile` | build, pad to 8K, stamp the `FUJI` claim, layout checks |
| `run.sh` | boot it in MAME against a live fujinet-pc (BoIP) |
| `emu/smoke.lua` | headless end-to-end test with a snapshot |

## Build

Needs a z88dk checkout with built binaries (`$Z88DK`, default
`~/Workspace/z88dk`). The `+astrocde` target is marked incomplete
upstream -- it ships a crt0 and HVGLIB.H but no target clib -- so the
build links the generic z80 clib, `support.asm` supplies the console
stub the runtime insists on, and pragmas place BSS at `0x4D00`, the
stack at `0x4FC0`, and run `DI` first (the mailbox contract).

```
make            # -> build/cdemo.bin, exactly 8192 bytes
make run        # boot in MAME against fujinet-pc BoIP on 127.0.0.1:9995
make smoke      # headless: presses keypad 1, snapshots the result
```

Known sccz80 hazard, worked around in `fujinet.h`: a **constant**
subscript on a cast-constant pointer (`FN_RDATA[2]`) is silently
miscompiled to the constant itself; use `FN_RDATA_B(i)` for constant
offsets. Variable subscripts are fine. Verified against z88dk
`3bd06cad` (2026-07).

Verified end to end 2026-09-04: MAME `astrocde` with the fujinet
cartslot device, fujinet-pc-rs232 BoIP listener, transaction log
`dev=70 cmd=C4 ... err=0 reply=06 rxlen=240`.
