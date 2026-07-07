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
"What NOS Doesn't Do" spread maps every DOS 2.0S menu letter to its
NOS equivalent, and lists what's missing with workarounds).

## Contents

- Introducing / Beginning with NOS (booting `NOS.atr` from
  `apps.irata.online:/Atari_8-bit/DOS/`, the prompt, overlays)
- Network, Not Disk (no FMS; `D:` mapped to the `N:` handler)
- Connecting to a Server (NCD/NPWD), The Eight Network Drives
  (shared mounts, the NCD-while-programming caution, N4: as NOS's
  service line)
- The Protocols (from `fujinet-firmware/lib/network-protocol`:
  TNFS, SD, FTP, HTTP(S)/WebDAV, SMB, NFS, GDRIVE + stream protocols)
- Directory, Wild Cards, Filespecs & URLs, Saving/Loading BASIC,
  Loading Programs, Copying, Deleting/Renaming, Text Files & NTRANS,
  Batch Files, AUTORUN (AppKey `db790000.key` on the FujiNet's SD)
- What NOS Doesn't Do, Troubleshooting, Getting Help (HELP over N4:)
- Command Reference (all 32 commands + aliases, source-derived)
- Appendix: the complete `nos.s` source listing

## Building

Requires Typst 0.13+.

    make            # -> fujinet-nos-introduction.pdf
    make watch      # live rebuild
    make preview    # page PNGs into preview/
    make listing    # re-stage listings/nos.s from ~/Workspace/fujinet-nhandler

## Sources of truth

Content is verified against source, not docs:

- `fujinet-nhandler/nos/src/nos.s` (v0.8.0) — commands, aliases,
  overlay architecture, AppKey creator `$DB79`, HELP URL (N4:),
  error strings, SUBMIT echo default (quiet), NCOPY `,A` append.
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
