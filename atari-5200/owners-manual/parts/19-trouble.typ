#import "../lib.typ": *

= Troubleshooting Checklist

The following list of symptoms, causes, and remedies is supplied to help you
find the trouble when your FujiNet does not do what you expect. As a rule of
thumb, if something does not work, turn the console OFF, wait ten seconds,
and turn it ON again.

#symrem(
  ([No picture, or a grey or snowy screen.],
   ([Console POWER not ON, or the TV not on the console’s channel.],
    [Cartridge not firmly seated. Turn the console OFF, push the cartridge in
     firmly, and turn it ON.],
    [Cartridge put in while the console was ON. Turn the POWER OFF and back
     ON.])),
  ([The picture jumps when WiFi connects, or the FujiNet menu starts over by
    itself.],
   ([The console cannot give the cartridge enough power. Plug a USB-C phone
     charger into the top of the cartridge, before turning the console on
     (Section 4). On a four-port console, always use one.],)),
  ([The controller does nothing.],
   ([Controller plugged into a jack other than jack 1. Move it to jack 1.],
    [Plug not pushed fully home.])),
  ([The joystick does nothing, but the keypad works.],
   ([Use keypad keys 2, 4, 6 and 8 to move in the FujiNet menu, and tell the
     FujiNet project (see Getting Help).],)),
  ([My network is not in the SELECT NETWORK list.],
   ([Router too far away. Move the console nearer, or the router.],
    [The network uses only 5 GHz. FujiNet needs 2.4 GHz.],
    [A hidden network. Choose OTHER (TYPE AN SSID) and spell its name.])),
  ([?CONNECT FAILED, or ?UNABLE TO CONNECT.],
   ([Wrong password. Remember #PAUSE switches between capitals and small
     letters (Section 6).],
    [Or set your WiFi from a computer, or from the memory card (Section 10).])),
  ([The status light is not white.],
   ([FujiNet is not on your WiFi. See the two above.],)),
  ([A host shows nothing, or ?HOST ERROR or ?OPEN ERROR.],
   ([Host name misspelled. Rename it (Section 7).],
    [The server is not running, or your Internet connection is down.],
    [SD: no memory card, or it is not formatted FAT32.])),
  ([?NOT A CARTRIDGE IMAGE.],
   ([The file’s name does not end in .A52, .BIN or .ROM. Rename a .CAR file to
     .A52 (Section 8).],
    [The file is not a 5200 game.])),
  ([?LOAD ERROR 01, 02 or 03.],
   ([A game larger than 128K, a damaged file, or a size FujiNet cannot place.
     See Section 8.],)),
  ([The game starts, but is garbled or rolls.],
   ([A PAL game. Use the NTSC version.],
    [Try a .CFG file naming the kind of cartridge (Section 8).])),
  ([I cannot get back to the FujiNet menu.],
   ([Turn the console OFF and ON again. The RESET key on the controller only
     starts the game over.],)),
  ([A network game says LOBBY NOT AVAILABLE.],
   ([The 5200 Lobby is still being finished (Section 11). Load the games
     from the browser.],)),
  ([An error with a number, such as ?READ ERROR 01.],
   ([01: the cartridge’s two computers could not talk. Turn the console OFF
     and ON.],
    [02: FujiNet took too long to answer. Try again; check the host.],)),
)

== Getting Help

FujiNet is made by a worldwide community of volunteers, and they are glad to
help:

- *fujinet.online* -- news, downloads and the FujiNet wiki
- *github.com/FujiNetWIFI* -- the source for everything, and the place to
  report a problem
- *discord.gg/7MfFTvD* -- the FujiNet Discord, where you can ask anything
