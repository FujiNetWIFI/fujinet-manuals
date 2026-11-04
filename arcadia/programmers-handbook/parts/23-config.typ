#import "../lib.typ": *

#booklet.update(true)
#bandfile.update(("the cartridge", "firmware/baked/fujiconfigrom.h"))
= CONFIG <config>

== General

CONFIG is the program the cartridge serves when it is switched on: WiFi,
the eight hosts and their names, the Game Lobby, a browser with paging,
folders, a filter and a scrollbar, copying a file between hosts, the
adapter’s details, and the boot of what you choose, with a progress bar.
The Arcadia’s is `fujinet-config/arcadia/`, 2650 assembly, and the firmware
bakes its 8,192 bytes into the game chip’s flash (`pico/arcadia/firmware/
baked/fujiconfigrom.h`). `listings/games.sh` builds it from its pin and
checks it against the baked header byte for byte.

#shots(("cfg-hosts", [the hosts]), ("cfg-browse", [the memory card]), ("booting", [booting]),
  w: 1.75in, gap: 0.2in, caption: [CONFIG, from fujinet-config at its pin])

== The Budget

A client has 6,912 bytes. The first complete CONFIG came to 7,115, and two
features went (the long-name marquee and a byte counter during the boot);
what is left is 3,955 bytes in block 1 and 2,546 in block 2, with 411 to
spare. Three things made it fit, all of them Section 8’s.

*Zero-page vectors.* The 30 routines CONFIG calls or jumps to most often,
counted from the source, have pointer words at `$0004-$003F`, where every
other program leaves the bytes between the header and the code empty. A
`ZBSR *ZPRS` is a two-byte `BSTA,UN PRS` from either block:

#excerpt-at(auto, "listings/config/config.asm", "; ---- zero-page vectors", n: 10)

That saved about 180 bytes.

*The split.* Block 1 holds the screen, the RAM and the controller; block 2,
in the mailbox’s page, the transport, the Fuji command wrappers, the screens
that mostly talk to the cartridge, and every table and string. Code in block
2 reads the hotspots directly -- `LODA,R0 FNRSEL+FRDEVIC` -- and so is
smaller than the runtime’s pointer-word version of the same routine:

#excerpt-at(auto, "listings/config/mailbox.inc", "MSTART: LODA,R0 FNRSEL+FRDATRS", n: 9)

*Data as data.* The boot stub, which must run from RAM, is kept in block 2
as raw `DB` bytes, because AS will not assemble its page-0 operand there.

== The RAM

CONFIG uses all 292 bytes, and its ledger at the head of `config.asm` names
every one (Section 6). The lower screen holds, laid over one another, the
path being browsed, the WiFi name and password and the host name being
edited, the filter, the copy’s source, a stack of parent folders and the
editor’s state.

== Abandoning frames

Every one of CONFIG’s screens is entered with a branch, from wherever the
program happens to be:

#excerpt-at(auto, "listings/config/config.asm", "; Every state is entered with BCTA", n: 3)

A failure deep in the boot jumps straight back to the browser’s redraw,
leaving the calls that led to it on the return stack. On the 2650 that is
safe: the eight-entry stack is a ring, and the frames left behind are simply
overwritten, as long as the screen they jump to never returns. The
handbook’s `depthcheck.py` sees those jumps, says so, and counts the deepest
live chain at six routines -- five return addresses, from the boot through
re-reading the chosen entry to a commit.

== The Boot

CONFIG boots as `fujiboot` does (Section 13), with one difference that
matters on real hardware: it does not give up after a fixed time while the
image is coming. `BCOMMIT` waits for the MOUNT_IMAGE reply and repaints the
progress bar from BOOT_PCT while it waits, and only times out after a spell
with no progress at all:

#excerpt-at(auto, "listings/config/boot.inc", "BCOMMIT: LODI,R0 $FF", to: "BCACK:")

The stub is the runtime’s eleven bytes, and the verdict is read only after
the reply is in, so a FAILED left over from an earlier mount is never
mistaken for this one’s. An image the cartridge will not take shows ROM TOO
BIG.

== The Controls

#grid(columns: (2.6in, 1fr), column-gutter: 0.35in, align: (center + top, left + top),
  overlay("CONFIG", ([up], none, none, [page], [copy], [page], [filter], none, none,
    [back], none, [select]), head: [Action buttons: select]),
  [
    The disc moves the bar and the Action buttons choose, everywhere; the
    keys on each screen are named on its bottom two rows. The overlay is the
    browser’s: 1 up a folder, 4 and 6 a page, 5 copy, 7 the filter. On the
    host list 1 renames, 3 is INFO, 7 the WiFi and 9 the Lobby. The WiFi and
    the names
    are typed on a character grid, `edit.inc`: the disc moves over 96
    characters, the Action buttons type, CLEAR deletes, ENTER accepts, 0
    escapes.
  ])

#shots(("wifi-pass", [the character grid]), ("info", [INFO]), w: 2.2in,
  caption: [Two more of CONFIG’s screens, from the Owner’s Manual])

== Baking It In

When CONFIG changes, the firmware takes the new image in two steps:
fujinet-config’s `arcadia/build.sh` writes `build/config.bin`; then, in the
firmware, `pico/arcadia/build-cart.sh --bake` turns it into
`firmware/baked/fujiconfigrom.h`, which the game chip’s build compiles in.
Until it is baked, a CONFIG under development runs like any other program:
`emu/run.sh bench/run/src/config/arcadia/build/config.bin`.
