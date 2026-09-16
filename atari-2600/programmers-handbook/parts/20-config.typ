#import "../lib.typ": *
= CONFIG

CONFIG is the cartridge's own program: baked into the RP2040 firmware, served the instant the console starts fetching, because at power-up there is no network and nothing to load one from. It is the other real client, and it lives in `fujinet-config/atari-2600`, standalone: the shared CONFIG core assumes a keyboard, four device slots and kilobytes of buffers, and this console has a joystick, one device slot and 128 bytes. Feature parity with the Intellivision's --- WiFi setup, host slots, browsing, copy, the game lobby and boot --- on a twelve-column display with no text mode at all.

#sect[Seven screens, seven banks]

#tbl((auto, auto, 1fr),
  th[Bank], th[Screen], th[Keys],
  [0], [host slots], [up and down move, FIRE mounts and browses, SELECT the menu],
  [1], [browser], [up and down move, left and right page, left at page 0 goes up a directory, FIRE descends or boots, SELECT the menu],
  [2], [adapter info], [FIRE or SELECT back],
  [3], [keyboard], [the stick moves the grid, FIRE types, SELECT the menu],
  [4], [WiFi], [up and down move, FIRE picks a network, SELECT skips],
  [5], [boot], [a progress bar; FIRE dismisses a failure],
  [6], [copy], [FIRE returns early])

Seven 2K banks pad to eight, a 16K image; each bank carries its own copy of the library, and the fixed tail holds the trampoline and the cold stub, as Section 13 describes.

#shot("config-hosts", caption: [CONFIG's host-slot screen, from the cartridge's own build. Selection is a `>` in column 0.])

#sect[Almost nothing lives in console RAM]

The working directory, the filter, a pending copy's source path and the text being typed are all 256-byte strings, and all four of the cartridge's path buffers are in use:

#tbl((auto, 1fr),
  th[Buffer], th[Holds],
  [0], [the working directory --- and the SSID, during WiFi setup],
  [1], [the directory filter --- and the passphrase, during WiFi setup],
  [2], [a pending copy's source path, which has to survive browsing to a destination],
  [3], [the edit scratch: what the keyboard is typing into, so that cancelling an edit is possible at all])

Buffers 0 and 1 double up because WiFi setup happens before anything is mounted. `SEED` copies the selected buffer into the scratch to begin an edit, `COMMIT` copies it back on accept, and cancel is neither. The console holds a cursor and a handful of flags.

The cartridge's path buffer 0 already holds the full path of the thing to boot: the browser appends the filename before it leaves, so the boot screen needs no argument, and on failure `POP` drops the filename and puts the browser back where it was.

#sect[Two blits it could not do without]

There is no inverse video: the row renderer takes no attribute, so a selected row cannot be highlighted. Every list marks its selection with a `>` in column 0, which is why content gets eleven columns, and moving the cursor changes exactly two characters --- two TCELL blits, not two recomposed rows, because a scan list's text arrives one `GET_SCAN_RESULT` at a time and recomposing would cost two round trips per cursor step.

The keyboard is twelve by eight cells mapped directly onto ASCII 32 to 127, so the cursor position *is* the character: `ch = 32 + row × 12 + col`. What has been typed is shown through a PATH blit, the only way to see a buffer the console cannot read back.

#sect[Building it]

```
cd ~/Workspace/fujinet-config/atari-2600
make            # build/config.bin, 16384 bytes
make rom.h      # bake it into the cartridge firmware
```

Its build adds one check the bring-up's lacked: `p2bin` silently truncates a bank that grows past `$17FF`, so the script re-runs it over `$1800`--`$1FFF` and requires zero bytes there.
