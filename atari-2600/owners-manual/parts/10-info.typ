#import "../lib.typ": *

= Info and the Web Control Panel

#grid(columns: (auto, 1fr), column-gutter: 12pt, align: (left + top, left + top),
  tvcap("info", [FN INFO]),
  [
    Choose *INFO* from the ACTIONS menu on the hosts screen or in the browser
    to see how FujiNet is connected:

    #tbl((auto, 1fr), size: 8pt,
      th[LINE], th[WHAT IT IS],
      [*SSID*], [the WiFi network FujiNet joined],
      [*IP*], [FujiNet's address on your network],
      [*GATEWAY*], [your router's address],
      [*DNS*], [the name server it uses],
      [*MAC*], [FujiNet's own hardware number (only the start fits)],
      [*VERSION*], [the FujiNet firmware version],
    )

    Press the red button to go back.
  ],
)

== The Web Control Panel

Everything FujiNet knows can also be seen and changed from a computer, tablet
or phone on the same network. Type FujiNet's *IP* address from the INFO screen
into a web browser -- for example `http://192.168.1.73/`. On many networks
`http://fujinet.local/` works too.

The control panel lets you change the WiFi network, fill in or change the
eight host slots with a real keyboard, and see the adapter's settings and
version. It is the easiest way to type a long host name.

== Setting WiFi from the Memory Card

If you would rather not spell a password with the joystick, FujiNet can read
its settings from the memory card. Make a plain text file called
`fnconfig.ini` in the top folder of the card, holding:

```
[WiFi]
enabled=1
SSID=YourNetworkName
passphrase=YourPassword
```

Put the card in the cartridge and turn on. FujiNet reads the file each time
it starts. (Everything you change in the menu or the control panel is written
back to the same file, so the card keeps your hosts as well.)
