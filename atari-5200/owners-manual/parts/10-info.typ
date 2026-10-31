#import "../lib.typ": *

= Info and the Web Control Panel

Press #START on HOST SLOTS to see how FujiNet is connected:

#shot("info", [ADAPTER INFO])

#tbl((0.85in, 1fr),
  th[Line], th[What it is],
  [*SSID*], [the WiFi network FujiNet joined],
  [*HOST*], [FujiNet’s own name on your network],
  [*IP*], [FujiNet’s address on your network],
  [*GATEWAY*], [your router’s address],
  [*NETMASK*, *DNS*], [the rest of your network’s settings],
  [*MAC*], [FujiNet’s own hardware number],
  [*BSSID*], [the hardware number of the router FujiNet joined],
  [*VERSION*], [the FujiNet firmware version],
)

Press the bottom button, #HASH or #STAR to go back.

== The Web Control Panel

Everything FujiNet knows can also be seen and changed from a computer, tablet
or phone on the same network. Type FujiNet’s *IP* address from the INFO
screen into a web browser -- for example `http://192.168.1.73/`. On many
networks `http://fujinet.local/` works too.

The control panel lets you change the WiFi network, fill in or change the
eight hosts with a real keyboard, put games on the memory card, and see the
adapter’s settings and version. It is the easiest way to type a long host
name, or a password the FujiNet keyboard cannot spell.

== Setting WiFi from the Memory Card

If you would rather not spell a password with the controller at all, FujiNet
can read its settings from the memory card. Make a plain text file called
`fnconfig.ini` in the top folder of the card, holding:

```
[WiFi]
enabled=1
SSID=YourNetworkName
passphrase=YourPassword
```

Put the card in the cartridge and turn on. FujiNet reads the file each time it
starts. (Everything you change in the menu or the control panel is written
back to the same file, so the card keeps your hosts as well.)
