#import "../lib.typ": *

#pagebreak(weak: true)
= Trouble Shooting Checklist

#symrem(
  ([No picture, or a grey or snowy screen.],
   [- Console POWER switch not ON.
    - TV not on channel 3, or the TV/Game switch set to TV.
    - Cartridge not firmly seated. Turn the console OFF, push the cartridge
      in firmly, and turn it ON.
    - Cartridge put in while the console was ON. Slide POWER OFF and back ON.]),
  ([The picture rolls, or jumps when WiFi connects; the FujiNet menu keeps
    starting over.],
   [- The console cannot give the cartridge enough power. Plug a USB-C phone
      charger into the top of the cartridge (Section 4).
    - A PAL console or TV. FujiNet is made for NTSC.]),
  ([The joystick does nothing.],
   [- Joystick plugged into RIGHT CONTROLLER. Move it to LEFT CONTROLLER.
    - Plug not pushed fully home.]),
  ([My network is not in the PICK NET list.],
   [- Router too far away. Move the console nearer, or the router.
    - Network uses only 5 GHz. FujiNet needs 2.4 GHz.
    - Hidden network. Choose OTHER... and spell its name.]),
  ([WIFI FAILED.],
   [- Wrong password. Remember the bottom three rows of the keyboard are
      small letters (Section 6). Press GAME SELECT, then choose WIFI on the
      hosts screen and try again.
    - Or set WiFi from the memory card (Section 10).]),
  ([Status light not white.],
   [- FujiNet is not on your WiFi. See WIFI FAILED, above.]),
  ([A host shows nothing, or an error such as E03 FF.],
   [- Host name misspelled. RENAME it (Section 7).
    - The server is not running, or your Internet connection is down.
    - SD: no memory card, or it is not formatted FAT32.]),
  ([BOOT FAILED.],
   [- A game FujiNet cannot play yet (Section 8).
    - An 8K game that needs a `.CFG` file beside it (Section 8).
    - A damaged file. Copy it again.]),
  ([The game starts, but is garbled or rolls.],
   [- A PAL game. Use the NTSC version.
    - The wrong `.CFG` word for the game.]),
  ([A game file is not in the browser.],
   [- Its name does not end in .BIN or .ROM. Rename `.A26` files to `.BIN`.
    - A FILTER is set. Choose FILTER and ACCEPT an empty one.]),
  ([I cannot get back to the FujiNet menu.],
   [- Press the RESET button on the back of the cartridge, not GAME RESET.
    - Or turn the console OFF and ON again.]),
  ([The Lobby says NO SERVERS.],
   [- No tables are open just now. Load the game from the browser instead;
      it has its own table list.]),
  ([A network classic stays at WAITING FOR AN OPPONENT.],
   [- Nobody else has joined yet. Leave it waiting, or arrange a time with a
      friend.]),
)

As a rule of thumb, if something does not work, turn the console OFF, wait
ten seconds, and turn it ON again.

== Getting Help

FujiNet is made by a worldwide community of volunteers, and they are glad to
help:

- *fujinet.online* -- news, downloads and the FujiNet wiki
- *github.com/FujiNetWIFI* -- the source for everything, and the place to
  report a problem
- *discord.gg/7MfFTvD* -- the FujiNet Discord, where you can ask anything
