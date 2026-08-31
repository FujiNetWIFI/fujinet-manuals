# The FujiNet Network Protocol Handbook

A complete reference for every network protocol adapter in the FujiNet
firmware — 28 scheme strings across 25 adapters in
`fujinet-firmware/lib/network-protocol` — plus one chapter per host
environment showing how the same protocols are driven from Atari BASIC,
Applesoft BASIC (BASIC.SYSTEM extension), Coleco ADAM SmartBASIC 1.x,
C with fujinet-lib, IntyBASIC on the Intellivision, and FujiNet NOS.

Each protocol chapter carries a synopsis card (scheme, class, family,
default port, credentials, capabilities), a full description with
sequence diagrams where a handshake matters, the devicespec grammar with
every query parameter, reference tables for every accepted value and
every error mapping, and worked examples: a bus-neutral transaction
trace plus a complete C program against fujinet-lib.

Styled as a FujiNet Engineering Series volume (matches the Platform
Bring-Up Guide and *Connecting an Emulator to FujiNet-PC*): Nimbus Sans
heads, Nimbus Roman body, Source Code Pro listings.

## Building

Requires [typst](https://typst.app) 0.13+ (built with 0.15.1). Fonts are
vendored in `fonts/`, so the build is self-contained:

```
make            # -> fujinet-network-protocol-handbook.pdf
make watch      # rebuild on save
make preview    # per-page PNGs into preview/ (gitignored)
make clean
```

Verify no system fonts leaked in with
`pdffonts fujinet-network-protocol-handbook.pdf` — every font should be
Nimbus or Source Code Pro, all embedded.

## Sources of truth

Every scheme string, aux value, command byte, constant, buffer size, and
error code was transcribed from the live project sources in the
workspace, not from secondary documentation:

| Repo | What was used |
|------|---------------|
| `fujinet-firmware` | `lib/network-protocol/` (all 25 adapters), `include/fujiCommandID.h`, `lib/device/sio/network.cpp` as the reference dispatcher — commit `8b61bde69` (Aug 2026) |
| `fujinet-lib` | v4.11.2 — `fujinet-network.h` for the C examples |
| `fujinet-nhandler` | the Atari NDEV handler and NOS; the Apple II BASIC.SYSTEM extension |
| `smartbasic-1.x` | the ADAM SmartBASIC FujiNet statements |
| `fujinet-manuals` | the per-platform programmer's guides digested in Part VI |

Where the implementation has a rough edge (stubbed operations that
report success, the Win32 would-block misreport, the shared Telnet state
machine…), the text says so plainly; Appendix E collects the list.

## Structure

- **Part I — The Network Device Model**: devicespec grammar, open/
  translation modes, channel modes (JSON/SGML), status and the full
  error table, the special-command set.
- **Part II — Filesystem Protocols**: the FS model, then TNFS, SD, SMB,
  NFS, FTP, SFTP, HTTP/HTTPS (with WebDAV, header channels, Range seek),
  S3, GDRIVE, ONEDRIVE.
- **Part III — Stream Protocols**: TCP (client and listening server),
  UDP, TELNET, SSH, WS/WSS.
- **Part IV — Session Utilities**: SSH.KEYGEN, SSH.COPYID, CLIPBOARD,
  CPM, TEST.
- **Part V — Mail and Calendar**: the Mailbox model, GMAIL, IMAPS; the
  Calendar model (including the compose/edit draft format), GCAL,
  ICAL/WEBCAL/ICALH.
- **Part VI — From Your Machine**: Atari BASIC, Applesoft BASIC, ADAM
  SmartBASIC 1.x, C with fujinet-lib, IntyBASIC, FujiNet NOS — each a
  digest pointing at its full programmer's guide.
- **Appendices**: error codes at a glance; the protocol capability
  matrix; scheme quick reference; specials by protocol; implementation
  notes; the programmer's guides.

The GitHub-wiki markdown edition lives in
`wiki/FujiNet-Network-Protocol-Handbook.md` and is maintained by hand
alongside `manual.typ`.
