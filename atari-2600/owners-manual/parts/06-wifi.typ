#import "../lib.typ": *

= Join Your Network

The first time you turn on the console with the FujiNet cartridge in it,
FujiNet looks for WiFi networks nearby. The screen may go dark for a few
seconds while it listens. Then it lists what it heard.

#grid(columns: (auto, 1fr), column-gutter: 12pt, align: (left + top, left + top),
  tvcap("wifi-pick", [PICK NET]),
  [
    #steps(
      [Push the joystick up or down until the *>* is beside the name of your
       network.],
      [Press the red button. The keyboard appears, titled *PASSWORD*.],
      [Spell your password (see _The Keyboard_, below).],
      [Press *GAME SELECT*, move to *ACCEPT* and press the red button.],
    )
    Names longer than eleven letters are cut short. If your network is not in
    the list -- some routers hide their names -- choose *OTHER...* at the
    bottom. FujiNet asks for the network's name (*ENTER SSID*) first, and
    then for the password.
  ],
)

#block(breakable: false, grid(columns: (auto, auto, 1fr), column-gutter: 8pt, align: (left + top, left + top, left + top),
  tvcap("wifi-conn", [Joining], size: 4.6pt),
  tvcap("wifi-fail", [It did not work], size: 4.6pt),
  [
    FujiNet now tries to join. The screen says *CONNECTING* and *PLEASE
    WAIT*; this can take up to about forty seconds. When it is done, the
    status light on the cartridge turns white and the list of hosts appears
    (Section 7). FujiNet remembers your network, so next time it joins by
    itself.

    If the screen says *WIFI FAILED*, the password was not right or the
    router is too far away. Press *GAME SELECT* to go on without WiFi, then
    choose *WIFI* from the ACTIONS menu on the hosts screen to try again.
  ],
))

#note[You can skip WiFi altogether: press GAME SELECT at *PICK NET*. FujiNet
still plays games from its memory card.]

== The Keyboard

FujiNet has no keyboard to plug in, so it draws one. Move the *^* pointer
under a character with the joystick and press the red button to type it. The
top line shows what you have typed so far; *LEN* counts the letters.

#grid(columns: (auto, 1fr), column-gutter: 12pt, align: (left + top, left + top),
  tvcap("kbd-pass", [The keyboard]),
  [
    #set text(size: 8.6pt)
    *The bottom-right key, \<,* erases the last letter.

    *GAME SELECT* opens the keyboard's ACTIONS:

    - *ACCEPT* -- done; use what is typed.
    - *CANCEL* -- leave it as it was before.
    - *CLEAR* -- start over.

    A password can be up to 63 letters, a network name up to 32.
  ],
)

#important[Passwords care about capitals and small letters. FujiNet's screen
draws them all the same way, so use this chart: the *top* letters on the
keyboard are CAPITALS and the *bottom three rows* are small letters.]

// the keyboard chart: what each cell really types
#let kb-rows = (
  " !\"#$%&'()*+", ",-./01234567", "89:;<=>?@ABC", "DEFGHIJKLMNO",
  "PQRSTUVWXYZ[", "\\]^_`abcdefg", "hijklmnopqrs", "tuvwxyz{|}~",
)
#let kb-cell(ch, row, col) = {
  let small = row >= 5
  let del = row == 7 and col == 11
  let label = if del { text(size: 6pt, weight: 700)[ERASE] }
    else if ch == " " { text(size: 6pt, weight: 700)[SPACE] }
    else { text(font: f-mono, size: 9pt, weight: 700, ch) }
  box(width: 100%, height: 17pt, fill: if small { bblue.lighten(75%) }
      else if del { panel-b } else { white },
    stroke: 0.5pt + ink, align(center + horizon, label))
}
#fig(block(width: 92%, {
  grid(columns: 12, column-gutter: 0pt, row-gutter: 0pt,
    ..range(8).map(r => range(12).map(c => {
      let row = kb-rows.at(r)
      let ch = if c < row.clusters().len() { row.clusters().at(c) } else { "" }
      kb-cell(ch, r, c)
    })).flatten())
}), caption: [What each key types. The shaded rows are small (lower-case)
letters, even though the screen shows them as capitals.])
