# Figures

**This manual needs no photographs.** Every figure is a native Typst diagram
generated from `manual.typ` (and re-drawn as Mermaid in the wiki edition), so
there is nothing for a photographer to supply and `images/` is empty by design.

This file exists to (a) make that explicit and (b) inventory the diagrams, so a
reviewer can find and check each one against the source it depicts.

## Diagram inventory

All diagrams are drawn by helpers defined at the top of `manual.typ`:
`nodebox`/`flow` (block diagrams), `bytefield` (packet & DCB byte strips), and
`seq` with `msg`/`snote`/`sgap` (sequence diagrams).

| Fig | Chapter | What it shows | Verify against |
| --- | --- | --- | --- |
| 1 | Introduction | The whole idea: emulator → socket → fujinet-pc | — |
| 2 | Bus-over-IP architecture | Master/peripheral role assignment | — |
| 3 | Bus-over-IP architecture | Who connects to whom (listen vs connect) | `AdamNet.c`, `NetAdamNet.cpp` |
| 4 | Bus-over-IP architecture | NetSIO ↔ AdamNet comparison (table) | `fujinet-emulator-bridge` |
| 5 | AdamNet bus | Z80 → 6801 master → devices two-tier model | ADAM architecture |
| 6 | AdamNet bus | Device-ID routing table | `an_forward_mask` in `AdamNet.c` |
| 7 | Wire protocol | Byte format (nibble strip) | `CMD`/`RESP` macros |
| 8 | Wire protocol | Command/response code tables | `adamnet.h` |
| 9 | Wire protocol | Packet & status-packet byte-fields | `adamnet.h`, `AdamNet_DiskStatus` |
| 10 | Wire protocol | Block-read handshake (sequence) | `AdamNet_ReadBlock` |
| 11 | Wire protocol | Block-write handshake (sequence) | `AdamNet_WriteBlock` |
| 12 | Wire protocol | Character-device handshake (sequence) | `AdamNet_CharRead/Write` |
| 13 | Finding the seam | `UpdateDCB` flow before FujiNet | `Coleco.c` |
| 14 | Boot handshake | Init → probe → release-Z80 (sequence) | `ADAMEm.c`, `AdamNet_WaitForConnection` |
| 15 | Half-duplex echo | One-wire echo vs TCP local echo | `NetAdamNet::dataOut` |
| 16 | Seek stall | Duplicate-ACK desync: before/after `an_drain` | commit `30248a5` |
| 17 | Non-blocking reads | Blocking vs non-blocking CPU timeline | commit `117fc14` |
| 18 | Throttled polling | gettimeofday gate in front of the syscall | commit `63a8b72` |
| 19 | The peripheral's view | 300 µs deadline waiver table | `adamnet.h` `_pc_no_response_deadline` |
| 20 | A recipe | The eight-step dependency order | — |

(Figure numbers are assigned by Typst at build time and may shift if text is
added; the chapter column is the stable reference.)

## If photos are ever wanted

The manual is complete without them, but a future edition could add screenshots
of the pair in action (the emulator booting `CONFIG` over BoIP, an `-verbose 8`
log, a network app running). None are required for the current revision.
