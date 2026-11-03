#import "../lib.typ": *

= Join Your Network

Each time you turn the console on, CONFIG says #scr("FUJINET CONFIG") and
#scr("WAITING FOR LINK") while the cartridge’s network chip wakes up -- a few
seconds, never more than fifteen. Press any button to hurry it along.

If FujiNet already knows your network, it joins it by itself and goes
straight to the list of hosts (Section 7). The first time, it has no network
to join yet, so it shows *SELECT NETWORK*. #scr("SCANNING") stays on the
screen while it listens for WiFi networks nearby; then it lists what it
heard.

#shot("wifi-pick", [Select network])

Up to seven networks are listed, the strongest first, with a block at the
right of each: the taller the block, the stronger FujiNet hears that network.
If yours is not in the list -- some routers keep their names hidden -- choose
*OTHER NETWORK* at the bottom; FujiNet asks for the network’s name first,
and then for its password. #CLEAR listens again.

#steps(
  [Move the bar to your network’s name.],
  [Press the Action button. The character grid appears, titled
   #scr("PASSWORD").],
  [Spell your network’s password (see _The Character Grid_, next).],
  [Press #ENTER. FujiNet says #scr("SAVING"), then #scr("CONNECTING").],
)

#shot("wifi-conn", [Connecting])

*CONNECTING* shows the network’s name and a bar that fills as FujiNet tries
to join, for up to about forty seconds. When it has joined, three rising notes
sound, the status light on the cartridge turns white, and the list of hosts
appears. If the password was not right, or the router is too far away, it
says #scr("CONNECT FAILED") and goes back to SELECT NETWORK to try again.
Any button while it is trying goes back at once.

#note[You can skip WiFi altogether: press #kp(0) at SELECT NETWORK. FujiNet
goes to the list of hosts and still plays games from its memory card.]

#pagebreak(weak: true)
== The Character Grid

CONFIG shows a grid of characters whenever it needs words: a password, a
network’s name, a host’s name, or a filter. The top line says what it wants;
the line under it is what you have typed so far, and beside that, how many
characters you have typed of how many it can take.

#fig(tvlab("wifi-pass", w: 3.0in, (
  (..cell(0, 2), -0.03, 0.02, [What it wants], left),
  (..cell(1, 4), -0.03, 0.11, [What you have typed], left),
  (..cell(3, 1), -0.03, 0.26, [A box: a symbol \ the Arcadia cannot \ draw], left),
  (..cell(4, 1), -0.03, 0.4, [The cursor], left),
  (..cell(2, 12), 1.03, 0.08, [Characters typed, \ of how many], right),
  (..cell(5, 15), 1.03, 0.3, [Capitals], right),
  (..cell(7, 15), 1.03, 0.46, [Small letters \ (in yellow)], right),
)), caption: [The character grid, with a password typed])

#controls(title: [On the character grid],
  [#disc("udlr"), or \ #kp(4) #kp(6) #kp(8)], [Move the cursor from character
    to character. It goes round at the edges.],
  [#FIRE or #kp(2)], [Type the character the cursor is on.],
  [#CLEAR], [Erase the last character.],
  [#ENTER], [Accept what you typed.],
  [#kp(0)], [Leave without changing anything.],
)

The ARCADIA-2001 has no small letters and few symbols. The grid shows small
letters as capitals in *yellow*, and every symbol the Arcadia cannot draw as a
box; move the cursor onto a box and it shows which symbol it is. What you
type is still exactly what you chose.

#important[Passwords care about capitals and small letters. Watch the colour:
white capitals are capitals; yellow ones are small letters.]

A password can be up to 63 characters, a network’s name up to 32, a host’s
up to 31 and a filter up to 15. Only the last 15 show on the line; the count
beside them says how many there are.
