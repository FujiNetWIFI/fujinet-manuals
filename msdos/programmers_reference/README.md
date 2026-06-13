# FujiNet INT F5 — Technical Reference (MS-DOS)

A programmer's reference for the **INT F5 interface** of the RS-232 FujiNet
under MS-DOS — the software interrupt installed by the FujiNet device driver
through which any program can command any FujiNet device. It documents the
floor that the FujiNet C library (`fujinet-lib`) ultimately calls, so you can
call it directly from assembler or C.

It is typeset as an affectionate tribute to the 1984 IBM Personal Computer
**Technical Reference** (P/N 6361453): the deep-indigo cover with the striped
masthead and "Hardware Reference Library" slug, Press Roman (Times) body,
bold serif heads, register-model diagrams, dense ROM-font listings, and the
black bleeder tabs down the fore-edge. (Its companion, the wine-covered
*Guide to Operations*, is in `../getting_started/`.)

The scan used as the styling reference is in `../learn/`.

## Output

`make` builds **`fujinet-int-f5-technical-reference.pdf`** (portrait 7 × 9 in):

1. **Introduction** — the device model and the software layers
2. **The Calling Convention** — registers (with a register-model diagram),
   payload direction, the field descriptor, return codes, the C wrappers, and
   the wire protocol
3. **The Devices** — the device-ID map
4. **Command Reference** — every command of the control device (70h), the
   network adapters (71h–78h), the disk drives (31h–38h), and the clock (45h),
   detailed and tabulated, with examples
5. **A Worked Example** — `NETCAT`, a complete network terminal in assembly
6. **Appendices** — error codes, status request types, field descriptors, and
   the FujiBus frame layout

## Sources of truth

Every register, command, and code is verified against source:

- **`fujinet-msdos/sys`** — `intf5.c` (the INT F5 handler), `fujicom.c` (the
  FujiBus framing and SLIP), `include/fuji_f5.h` (the register convention and
  command constants).
- **`fujinet-firmware/lib/device/rs232`** — the device command handlers
  (`rs232Fuji.cpp`, `network.cpp`, `disk.cpp`, `apetime.cpp`) and the
  `FUJICMD_*` / `NETCMD_*` constant set.
- **`fujinet-lib/msdos/src/bus`** — `int_f5.c`, `int_f5_read.c`,
  `int_f5_write.c`: the three wrappers the C library is built on, which fix
  the canonical register convention.

### The register convention

The current, canonical convention (driver + library) is:

| Reg | Holds |
|-----|-------|
| `DL` | direction: `00h` none / `40h` read / `80h` write |
| `DH` | field descriptor (how many AUX bytes to frame) |
| `AL` | device ID |
| `AH` | command code |
| `CL` / `CH` | AUX1 / AUX2 |
| `SI` | AUX3 (low) : AUX4 (high) |
| `ES:BX` | far pointer to payload buffer |
| `DI` | payload length |

`AL` returns `'C'` (complete), `'E'` (error), or `'N'` (NAK).

> **Note:** the older `fujinet-msdos/fujinet-bios.md` describes an earlier
> register layout (direction in `AH`, command in `CL`). This reference follows
> the **current** driver and `fujinet-lib`, which is what the firmware speaks.

## Fonts (vendored in `fonts/`)

| Family | Use | Source |
|--------|-----|--------|
| Nimbus Roman | body & heads (Press Roman / Times equivalent) | URW (GPL + font exception) |
| Px437 IBM VGA 8x16 | all listings and register/command codes | int10h.org *Oldschool PC Font Pack* (CC BY-SA 4.0) |

## Build

```sh
make            # build the PDF
make watch      # rebuild on save
make preview    # per-page PNGs in preview/
make clean
```

Requires [Typst](https://typst.app) 0.13+. Fonts load via `--font-path fonts`.

## Licence & trademarks

Manual text, tables, and the NETCAT example: © 2026 the FujiNet community;
copy freely. FujiNet is a community project and is **not** affiliated with,
endorsed by, or sponsored by IBM. The styling is a tribute to the IBM Personal
Computer *Technical Reference.*
