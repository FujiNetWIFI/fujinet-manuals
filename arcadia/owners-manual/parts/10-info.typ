#import "../lib.typ": *

= Info and the Web Control Panel

Press #kp(3) on FujiNet hosts to see how FujiNet is connected:

#grid(columns: (2.6in, 1fr), column-gutter: 0.3in, align: (center + top, left + top),
  fig(tv("info", w: 2.5in), caption: [FujiNet info]),
  tbl((1.05in, 1fr),
    th[Line], th[What it is],
    [*SSID*], [the WiFi network FujiNet joined],
    [*HOSTNAME*], [FujiNet’s own name on your network],
    [*IP ADDRESS*], [FujiNet’s address on your network],
    [*GATEWAY*], [your router’s address],
    [*VERSION*], [the FujiNet firmware version],
  ))

Press any button to go back.

== The Web Control Panel

Everything FujiNet knows can also be seen and changed from a computer, tablet
or phone on the same network. Type FujiNet’s *IP ADDRESS* from the INFO
screen into a web browser -- for example `http://192.168.1.73/`. On many
networks `http://fujinet.local/` works too.

The control panel lets you change the WiFi network, fill in or change the
eight hosts with a real keyboard, put games on the memory card, and see the
cartridge’s settings and version. It is the easiest way to type a long host
name, or a password with symbols in it.

== Setting WiFi from the Memory Card

If you would rather not spell a password with the hand controller at all,
FujiNet can read its settings from the memory card. Make a plain text file
called `fnconfig.ini` in the top folder of the card, holding:

#block(inset: (left: 0.3in), text(font: f-body, size: 10pt)[
  `[WiFi]` \
  `enabled=1` \
  `SSID=YourNetworkName` \
  `passphrase=YourPassword`
])

Put the card in the cartridge and turn on. FujiNet reads the file each time it
starts. (Everything you change in CONFIG or the control panel is written back
to the same file, so the card keeps your hosts as well.)
