#import "../lib.typ": *

#part("VI", "Verification, and what is not verified",
  [What the emulator model proves, what the host tests prove, and the
   precise list of what nothing proves yet: the bus loop on real silicon,
   and five defects in the source found while this document was written.])

= The emulator model <ch-mame>
Every milestone of the bring-up was passed in MAME, against a live
`fujinet-pc`, before any hardware existed, and the design of the
verification is as deliberate as the design of the cartridge.

== The device

`emu/fujinet.cpp` is a MAME cartridge device for the `a2600` driver,
selected with `-cartslot fujinet`. It is only the port: bytes go into a
4K window and frames go over a TCP socket. Everything that decides what
a byte means is the cartridge firmware's own source, copied into the MAME
tree by `emu/apply.sh`: `fujimail.c`, `fujibus.c`, `vcs_render.c`,
`vcs_cart.h` and `vcsmap.h`. The device's `read()` and `write()` call the
same `vcs_read` and `vcs_write` core1 compiles, so the device and the
cartridge cannot disagree about which store is a register write or which
access is a hotspot. The TCP transport, `emu/fujitcp.c`, carries the same
FujiBus frames to `fujinet-pc`'s bus-over-IP listener at `127.0.0.1:9995`
by default. #src[emu/fujinet.h:14-24; emu/fujitcp.c:28-36]

#important[
  What the device does not model is the important thing. MAME hands a
  cartridge device a clean data byte on a write. The real cartridge has
  no R/W line and recovers the byte from the second-to-last sample of a
  bus it is watching; that sampling, the single riskiest thing in the
  port, never runs in the emulator. `host_test/test_busio.c` is the
  substitute for the *model* of it (#ref(<ch-hosttests>)). The loop that performs it
  on silicon is exercised by nothing. #src[emu/fujinet.h:28-35]
]

Two facts about MAME's memory system shaped the firmware. Its read taps
run *after* the read, so a bank-switch hotspot returns the old bank's
byte; the mappers were inverted until the MAME source settled it. And
Lua's `read_u8` is not side-effect free in this build, so a harness that
sweeps a banked window trips the game's own hotspots and has to poll only
handler-free offsets. #src[README-fujinet.md:213-220]

== The harnesses

Each milestone has a Lua script that drives the emulated console and
checks the result by decoding memory or the raster, never by eye.
#src[emu/\*.lua; README-fujinet.md:121-154]

#tbl(
  tab((auto, auto, 1fr),
    th[Harness], th[Milestone], th[What it proves],
    [`dispcheck.py`], [M0], [The cart-composed display: decodes a MAME snapshot's raster back into plane bytes and byte-compares them with the renderer. 756/756. This found three real kernel bugs: a missing seventh `GRP` write, an end-of-frame drain that toggled VDELP and restored stale registers, and a `ldx`-versus-`tsx` cycle],
    [`drive.lua`], [M1], [A live GET_ADAPTERCONFIG_EXTENDED reaches the screen: SSID, IP and version],
    [`resettest.lua`], [M1], [ACKSEQ survives a console RESET (01 → 02), so the sequence rule holds],
    [`boottest.lua`], [M2], [A pushed 4K image with *no* claim is served byte-identically: 4096/4096 against the file, with the mailbox dead afterwards, as a real game requires],
    [`dirtest.lua`], [M3], [The browser navigates to a file *by name* and boots it, 4096/4096],
    [`maptest.lua`], [M5], [F8 hotspots in a booted game switch the right banks],
    [`soaktest.lua` + `tools/soak.sh`], [M6], [Thirteen synthetic images across all nine schemes, Super Chip variants included, each with a `.cfg` sibling: pushed, booted, the chosen mapper checked, every bank byte-compared. 13/13],
    [`cfgtest.lua`], [M7], [CONFIG, from power-on through WiFi, hosts and a subfolder to a booted game],
    [Battleship's `drive.lua`, `frames.lua`], [M7], [A real game against the live server; every frame of a game held to 262 lines],
  ),
  [The MAME harnesses. All #v-emu.],
) <tbl-harness>

M0 was pulled forward deliberately: every sibling console had a character
generator or a framebuffer, so the cartridge-composed display was the one
component with no template anywhere in the family. The soak found two
things no host test could reach: that an 8K F8, E0, UA and FE cannot be
told apart by size, so the `.cfg` had to be read; and that UA and FE
switch below A12, where neither core1 nor the device was looking.

== The bench

The long-running `fujinet-pc` is the RS232 build with bus-over-IP
listening on `127.0.0.1:9995`; its host slot 0 is an SD directory. The
listener accepts one client, so a stray MAME starves the next run and the
symptom is a hang rather than an error. MAME must be started from its own
tree or the autoboot script is silently ignored, and needs
`SDL_VIDEODRIVER=dummy` without a display. `emu/run.sh` handles all three.
#src[README-fujinet.md:195-209]

= Host tests and static checks <ch-hosttests>
Four C programs under `firmware/host_test/` compile the shared headers and
codec on the build machine with no SDK, and CI runs them on every push as
the job "Atari 2600 --- bus decode, mappers, glyph compositor, FujiBus
codec". #src[host\_test/Makefile; .github/workflows/pico-carts.yml:264-266]

#tbl(
  tab((auto, 1fr),
    th[Test], th[What it proves],
    [`test_busio`], [The decode and the write-sampling *model*: which pages are tri-stated; the arming gate; arm and commit; TX appends; the one-shot operations; that the painted window swallows stores; the claim and banking; that `STA abs` and `STA abs,X` recover the stored byte through `vcs_recover` and that an RMW's three cycles do not; the client-versus-game seam; the path buffers' pop and pad rules. Its expectations are written from the rules in prose in the headers, never by calling the decoder to see what it does. It tests `vcs_read` and `vcs_write`, not the core1 loop],
    [`test_vcsmap`], [Every scheme against a verbatim transcription of MAME's `rom.cpp` handlers: 200 000 fuzzed accesses per scheme must agree byte for byte, bank state included],
    [`test_render`], [The compositor against goldens generated from `tools/vcsfont.py`, the single source of the font],
    [`test_fujibus`], [The FujiBus codec: encode, decode, SLIP, checksum],
  ),
  [The host tests. All #v-host.],
) <tbl-hosttests>

Three static checks guard the client side. `tools/checkdefs.py`
cross-checks the 39 equates in `fujinet.inc` against `fuji_mailbox.h`
before anything assembles, because the two are hand-mirrored and once
drifted by a page: every register write went to a page that decodes
nothing, the client came up, drew a screen, and never armed the mailbox.
`tools/checkrom.py` scans every image (#ref(<ch-ram>)). `tools/checksram.py`
asserts core1's residency in SRAM (#ref(<ch-cores>)). #src[README-fujinet.md:227-232]

= What nothing proves yet <ch-gaps>
This chapter is the one to read before building the board.

== The bus loop on silicon

No test executes `vcs_core1_main`. The emulator never calls it; the host
tests call the functions it calls. Everything in #ref(<ch-read>) and #ref(<ch-write>) about
settling, sampling and driving is therefore a design argued from the 6500
datasheet and from the PlusCart firmware the idiom was taken from, and
Rev0's checklist item 4 --- address-to-data on a scope against the 6507's
read window --- is the first measurement the design needs.

== Five findings in the source

These were found by reading the firmware while writing this document and
confirmed against the cited lines. They are the gap between the design as
described and the code as written on `2600-experiment` at `7432186c0`, and
none can be seen from the emulator or the host tests, because each lives
in the one place those do not reach.

#tbl(
  tab((auto, 1fr, auto),
    th[], th[Finding], th[Where],
    [1], [`DATA_DRIVE` and `DATA_RELEASE` never flip DIR, so the cartridge cannot drive the console through U5 and fights its outputs when it tries. Recorded in both READMEs with the fix], [#ref(<ch-buffers>)],
    [2], [`vcs_tristate` is tested before the mapper is consulted, so a booted game's `$1D00`--`$1EFF` is never driven. The host test that checks the case goes through `vcs_read_ex`, which has the guard the loop lacks], [#ref(<ch-mappers>)],
    [3], [Super Chip, FA and CV RAM stores take the driven-read path on core1; the write never reaches `vcsmap_write`, and the cartridge drives against the 6507], [#ref(<ch-mappers>)],
    [4], [The image swap runs 7K of `memset`/`memcpy` inline on core1 while the console's stub reaches the reset vector in about 6 µs], [#ref(<ch-boot>)],
    [5], [`PATH_POP`, `PATH_COMMIT` and `PATH_SEED` run loops of up to 256 iterations inline on core1 while the next fetch, from the cartridge, is 838 ns away], [#ref(<ch-cores>)],
  ),
  [Findings. Items 2--5 have the same shape: work on core1's path that the emulator performs instantly and silicon cannot. Items 2 and 3 need a mapper test in the loop; 4 and 5 need the work moved to core0 with a pointer or a flag handed back, as banking, rendering and blits already do.],
) <tbl-findings>

== The hardware checklist

#ref(<ch-hwstatus>) reproduced the nine items the Rev0 README says only a built
board can answer: DIR in firmware, fit, the console's 5 V under WiFi load,
timing on a scope, back-power, RESET and BOOTSEL behaviour, card-detect
polarity, placement rotations, and RSSI in the shell. Items 3 and 4 are
measurements; the rest are observations. None has a stand-in.

== What would close them

A built Rev0, a debug probe on the SWD pads for the first flash, a scope
on the edge, and a console. The five findings are firmware changes that
can be made and tested in the emulator *before* that, with the knowledge
that the emulator cannot show whether they were needed --- only the board
can. That order is the one the rest of the family has followed, and it is
the reason this document exists in the form it does: as a statement of
intent precise enough to be checked against the silicon when it arrives.
