# FujiNet NOS — An Introduction to the Network Operating System

A user's booklet for **NOS**, the FujiNet Network Operating System for
the Atari 8-bit computers, styled as a faithful tribute to the 1982
*ATARI 1050 Disk Drive: An Introduction to the Disk Operating System*
(C061529) — silver foil pages, Futura Extra Bold headbands over black
bands, blue CRT transcripts in the genuine Atari ROM font, and flat-cel
illustrations with tumbling data cubes. Where the 1050 booklet draws
diskettes, this booklet draws the network: the recurring "network
volume" is an orthographic globe drawn exactly the way the original
draws a diskette, dark body, sector grid, colored file slabs.

Audience: new Atari users **and** experienced ATARI DOS users (the
"The Menu" chapter sets NOS 1.1's DOS 2.0-style menu side by side
with the original, letter by letter).

## Contents

- Introducing / Beginning with NOS (booting `NOS.atr` from
  `apps.irata.online:/Atari_8-bit/DOS/`, boot-to-menu, overlays)
- The Menu (all sixteen items A–P, their prompts, the DOS 2.0
  side-by-side, where the transient menu module lives)
- Network, Not Disk (no resident FMS; `D:` mapped to the `N:`
  handler — except the DIR/COPY `D2:`–`D8:` diskette door)
- Connecting to a Server (NCD/NPWD), The Eight Network Drives
  (shared mounts, the NCD-while-programming caution, N4: as NOS's
  service line), One File At a Time (one open file per `Nn:`; the
  two-drives-same-endpoint pattern for read+write, AMAC example)
- The Protocols (from `fujinet-firmware/lib/network-protocol`:
  TNFS, SD, FTP, HTTP(S)/WebDAV, SMB, NFS, GDRIVE + stream
  protocols, incl. the NOTE/POINT seek column)
- Directory, Wild Cards (now incl. DEL with Y/N confirm and COPY),
  Filespecs & URLs, Saving/Loading BASIC, Loading Programs (incl.
  1.1's command-line parameters for extrinsics), Copying (one-arg +
  wildcard), The Diskette Comes Back (1.1's DOS 2.0S diskette
  transfer via DIR/COPY `Dn:`), Deleting/Renaming, Text Files &
  NTRANS, Moving Around In a File (NOTE/POINT via XIO 37/38),
  Batch Files, AUTORUN (AppKey `db790000.key` on the FujiNet's SD)
- What NOS Doesn't Do, Troubleshooting, Getting Help (HELP over N4:
  + the card catalog of `nos/HELP/`)
- Inside NOS (memory map, overlay system, NOS.atr disk layout,
  writing a new overlay, the burst engine, the borrowed DOS 2.0S
  FMS module)
- Command Reference (all 33 commands + aliases + menu letters,
  source-derived)
- Appendix: the complete `nos.s` source listing

## Building

Requires Typst 0.13+.

    make            # -> fujinet-nos-introduction.pdf
    make watch      # live rebuild
    make preview    # page PNGs into preview/
    make listing    # re-stage listings/nos.s from ~/Workspace/fujinet-nhandler

## Sources of truth

Content is verified against source, not docs:

- `fujinet-nhandler/nos/src/nos.s` (v1.1.0) — commands, aliases,
  the menu module, wildcard DEL/COPY, NOTE/POINT, burst constants,
  overlay architecture and addresses (OVLBUF `$1A00`, MEMLO
  `$1C00`, menu `$2700`, wild `$4300`, DOS 2.0S FMS `$5000`), the
  cc65 COMTAB stub (command line at DOSVEC+63), AppKey creator
  `$DB79`, HELP URL (N4:), error strings, SUBMIT echo default
  (quiet).
- `fujinet-nhandler/nos/HELP/*` — the online help library cataloged
  in "Getting Help" (NOS/ASM/MAP/REF/DEV/UTL shelves).
- `fujinet-firmware/lib/network-protocol/*` — protocol list and
  capability matrix (`*_implemented` flags), FTP anonymous login,
  GDRIVE OAuth relay, SD card protocol.
- `fujinet-firmware/lib/utils/utils.cpp` — long directory entry
  format used in the DIR screen transcripts.

## Fonts (vendored in `fonts/`)

Futura LT Extra Bold / LT / Book (heads, labels), Rockwell Std
Light/Regular/Bold (body), Harry Fat (rainbow cover wordmark),
EightBit Atari (screen transcripts), DejaVu Sans Mono (source
listing appendix only).

The wiki twin lives in `wiki/`.
