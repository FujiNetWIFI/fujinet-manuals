#import "../lib.typ": *

= Trouble Shooting Check List

The following list of symptoms, causes and remedies is supplied to help you
find the trouble when your FujiNet does not do what you expect. As a rule of
thumb, if something does not work, turn the console OFF, wait a few seconds,
and turn it ON again.

#symrem(
  ([No playfield image on TV, or a whitish grey screen.],
   ([Switch box set at “TV”. Change to “GAME”.],
    [TV not on channel 3 or 4, or not the channel the console’s switch is
     set to.],
    [Cartridge not firmly seated. Turn the console OFF, push the cartridge in
     firmly, and turn it ON.],
    [Cartridge put in while the console was ON. Turn the POWER OFF and back
     ON.])),
  ([#scr("NO FUJINET CART") on the screen.],
   ([The cartridge is not answering. Turn the console OFF, seat the
     cartridge firmly, and turn it ON. If it persists, press RESET on the back
     of the cartridge, then the console’s RESET.],)),
  ([The picture jumps when WiFi connects, or CONFIG starts over by itself.],
   ([The console cannot give the cartridge enough power. Plug a USB-C phone
     charger into the top of the cartridge, before turning the console on
     (Section 4).],)),
  ([The hand controller does nothing.],
   ([CONFIG listens to the left hand controller. Use that one.],)),
  ([My network is not in the SELECT NETWORK list.],
   ([Router too far away. Move the console nearer, or the router.],
    [The network uses only 5 GHz. FujiNet needs 2.4 GHz.],
    [A hidden network. Choose OTHER NETWORK and spell its name.],
    [Press #CLEAR to listen again.])),
  ([#scr("CONNECT FAILED").],
   ([Wrong password. Small letters show in yellow; check each one
     (Section 6).],
    [Or set your WiFi from a computer, or from the memory card (Section 10).])),
  ([The status light is not white.],
   ([FujiNet is not on your WiFi. See the two above.],)),
  ([A host shows nothing, or #scr("HOST ERROR") or #scr("FOLDER ERROR").],
   ([Host name misspelled. Rename it (Section 7).],
    [The server is not running, or your Internet connection is down.],
    [SD: no memory card, or it is not formatted FAT32.])),
  ([#scr("NOT A CART").],
   ([The file’s name does not end in .BIN or .ROM. Rename an .ARC file to
     .BIN (Section 8).],
    [The file is not an ARCADIA-2001 game.])),
  ([#scr("ROM TOO BIG"), #scr("STAGE ERROR") or #scr("TRUNCATED").],
   ([A file too large, of a size the cartridge cannot place, or cut short.
     See Section 8.],)),
  ([I cannot get back to CONFIG.],
   ([Press RESET on the back of the cartridge, then the console’s RESET
     (Section 5). The console’s RESET alone only starts the game over.],)),
  ([Golf stops at its first screen.],
   ([Golf’s cartridge was wired unlike any other; FujiNet cannot play it
     yet (Section 17).],)),
)

#note[Due to differences in color circuitry on various makes of TV
receivers, not all colors will appear the same on every TV set.]

== Getting Help

FujiNet is made by a worldwide community of volunteers, and they are glad to
help:

- *fujinet.online* -- news, downloads and the FujiNet wiki
- *github.com/FujiNetWIFI* -- the source for everything, and the place to
  report a problem
- *discord.gg/7MfFTvD* -- the FujiNet Discord, where you can ask anything
