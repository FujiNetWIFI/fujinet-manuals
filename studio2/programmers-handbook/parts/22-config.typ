#import "../lib.typ": *

#opener-art.update((sub: [hosts · networks · files · boot],
  art: tvrow("cfg-status", "cfg-hosts", "cfg-browse", w: 1.15in)))
= CONFIG <config>

CONFIG is the program a FujiNet computer meets first: the WiFi, the host slots, the files on them, and the one to boot. On the Studio II it lives in the cartridge itself. The firmware carries it, built, as `baked/fujiconfigrom.h`, and the cartridge serves it from the moment the console is turned on. Its source is `fujinet-config/studio2/`, carried by the handbook in `listings/config/`.

It does not share the other consoles’ CONFIG code: that code assumes a keyboard, four device slots and kilobytes of buffers, and the Studio II has twenty keys and 512 bytes. It does what the Channel F’s does, in 4,152 bytes of 1802 on top of the runtime: 25 pages.

== The screens

#crt2("cfg-info", "cfg-wifi", caption: [Adapter info, and the networks the adapter can see.])

#tbl((0.85in, 1fr),
  [*Screen*], [*Shows*],
  [Status], [the network and the address; with a network already joined, it moves on to the host slots after three seconds],
  [Host slots], [the eight hosts; 5 opens one, 7 renames it, 1 the networks, 3 adapter info],
  [Files], [a folder, eight names to a page; 5 opens a folder or boots a file, 7 copies it to another host],
  [Networks], [what the adapter found; 5 picks one, then the keyboard for its password],
  [Info], [the adapter’s addresses, version and MAC],
)

Both keypads work alike: 2 and 8 move, 4 and 6 page, 5 selects, 0 goes back.

== A page in one round trip

The file browser shows a page of eight names with one READ_DIR_ENTRY. In _block mode_, flag bits `$C0` plus the group’s size, the FujiNet answers with a whole group of entries, full-length names and a folder flag for each, in one reply. CONFIG notes where each name starts, prints the rows from the reply window, and moves the bar without asking again:

#wex("listings/config/src/fujicmd.inc", "; c_rdblk --", to: "; c_cdir --", at: bottom)

The folder stays open until the next OPEN_DIRECTORY, or a boot, closes it.

== The keyboard

Names and passwords are typed on a keyboard of six rows, all of `$20` to `$7F`, sixteen to a row. A character’s cell is its code less `$20`, so there is no table and no shift key: the font’s lower case is a letter of its own. The netcat uses the same keyboard, carried over unchanged (netcat, page #pg(<netcat>)).

== Booting

`boot.inc` boots a file as `fujiboot` does: MOUNT_HOST, SET_DEVICE_FULLPATH, MOUNT_IMAGE, then `fn_boot` once BOOT_STATE says ready. The file’s name goes on the screen under a marquee, straight from the reply window, while the cartridge draws the progress bar in its status strip.

#wex("listings/config/src/boot.inc", "st_boot:", n: 22, at: top)

== Building it into the cartridge

#nsteps(
  [`make` in `fujinet-config/studio2/` builds `build/config.st2`; `make install` copies it into the firmware’s `pico/studio2/build/`.],
  [`build-cart.sh --bake` in the firmware turns it into `baked/fujiconfigrom.h`, which the cartridge’s firmware and the MAME model both compile in.],
  [In MAME, `FUJINET=1` serves the baked CONFIG from power-on, as the cartridge will.],
)

#note[CONFIG is the one image the cartridge lets claim the mailbox without the `"FUJI"` check: it is staged with the claim forced on, so the console always has a way back to the network.]
