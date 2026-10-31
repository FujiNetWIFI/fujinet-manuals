#import "../lib.typ": *

= Join Your Network

Each time you turn the console on, FujiNet types its name across the screen
and says #scr("OK"). Press any key to hurry it along.

#shot("splash", [The FujiNet menu, starting], w: 2.0in)

The first time, FujiNet has no network to join yet, so it shows *SELECT
NETWORK* and listens for WiFi networks nearby. #scr("SCANNING...") stays on
the screen for a few seconds; then it lists what it heard. After that it
remembers your network, joins it by itself, and goes straight to the list of
hosts (Section 7).

#shot("wifi-pick", [SELECT NETWORK])

#steps(
  [Move the bar to your network’s name.],
  [Press the bottom button (or #HASH). The keyboard appears, asking
   #scr("PASSWORD?").],
  [Spell your network’s password (see _The Keyboard_, next).],
  [Press #START. FujiNet tries to join.],
)

The number at the right of each name is how strongly FujiNet hears that
network: the nearer to 0, the stronger. #scr("-42") is strong; #scr("-85") is
very faint. Up to fifteen networks are listed, and #START looks again. If your
network is not in the list -- some routers keep their names hidden -- choose
*OTHER (TYPE AN SSID)* at the bottom. FujiNet asks for the network’s name
(#scr("SSID?")) first, and then for the password.

#shots(("wifi-join", [Joining]), ("wifi-ok", [Joined]), w: 1.72in)

*JOINING NETWORK* shows the network’s name and #scr("PLEASE WAIT"). It can
take up to about forty seconds. When it says #scr("CONNECTED"), the status light
on the cartridge turns white and the list of hosts appears. If the password
was not right, or the router is too far away, it says why -- for example
#scr("?CONNECT FAILED") -- and goes back to SELECT NETWORK to try again.
#STAR while it is joining goes back at once.

#note[You can skip WiFi altogether: press #STAR at SELECT NETWORK. FujiNet
goes to the list of hosts and still plays games from its memory card.]

== The Keyboard

FujiNet draws a keyboard whenever it needs words: a password, a network’s
name, a host’s name, or a filter. The top line asks the question; the line
under it is what you have typed so far.

#shot("kbd-pass", [The keyboard, with a password typed])

#controls(title: [On the keyboard], w: 1.0in,
  [#stick("udlr") \ or #kp(2, 4, 6, 8)], [Move the block from character to
    character.],
  [#BOTTOM button \ or #HASH], [Type the character the block is on, or do
    what its word says.],
  [#TOP button, #STAR \ or #RESET], [Erase the last character.],
  [#PAUSE], [Capital letters or small ones. *CASE* on the bottom row does the
    same.],
  [#START], [Accept what you typed. *OK* does the same.],
)

*SPC* types a space and *DEL* erases. *ESC* is the only way to leave without
changing anything. A password can be up to 63 characters, a network’s name up
to 32.

#important[Passwords care about capitals and small letters. Watch the
keyboard: after #PAUSE its letters are small, and so is everything you type
until you press it again.]

The keyboard has no #scr("`"), #scr("{"), #scr("|"), #scr("}") or
#scr("~"). If your password uses one of them, set your WiFi from a computer
instead (Section 10).
