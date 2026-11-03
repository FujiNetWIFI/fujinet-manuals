#import "../lib.typ": *

= No Console? FujiNet Go

*FujiNet Go Arcadia 2001 Desktop* is an ARCADIA-2001 for your computer --
Windows, Mac or Linux -- with a FujiNet cartridge already in its slot. It runs
the same CONFIG, the same Lobby and the same games as the cartridge, from the
same hosts, and needs no Arcadia of your own. It is free, from
*github.com/FujiNetWIFI/fujinet-go-arcadia-desktop*, under Releases.

The computer’s keyboard is the left hand controller:

#tbl((2.0in, 1fr),
  th[Arcadia], th[Computer],
  [Keyboard #kp(1) to #kp(9), #kp(0)], [`1` to `9`, `0`],
  [#CLEAR, #ENTER], [Backspace, Enter],
  [Control disc], [the arrow keys (or a game pad’s stick)],
  [Action button], [Right Ctrl],
  [#START, #OPTION, #SELECT], [F2, F3, F4],
  [The console’s #RESET], [F1],
  [Back to CONFIG (the power switch)], [Escape],
  [The Controllers window], [F9: both hand controllers, drawn; click a
    button, drag the disc],
)

Games from the library load through CONFIG as on the console. A game kept on
your computer opens with *File #into Open cartridge* and plays on its own
cartridge -- Golf’s too.

*Your own FujiNet.* In Preferences, *External FujiNet* points the program at a
FujiNet running elsewhere on your network, by its address and port, instead
of the one built in.
