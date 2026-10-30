#import "../lib.typ": *
= 5 Card Stud <ch-fcs>

5 Card Stud is FujiNet’s poker table: up to eight players, people and bots, on any computer or console a FujiNet serves, dealt and refereed by a server. Like Battleship, it is one program for every client, and the 5200’s part is the screen, the controls, the sound and the network calls.

#fig(tvframe("images/screens/fcs-table.png", 3.0in), caption: [A hand against two bots on the bench’s server: the stakes over each player, the pot in the middle, your three cards showing and one face down, and your moves along the bottom.])

#sect[The 5200 layer]

#tbl((auto, 1fr),
  th[File], th[What it does],
  [`antic.s`, `graphics.c`], [The Atari 8-bit client’s table: ANTIC mode 4, 40 × 26, two screens in RAM for double buffering, a display-list interrupt that colours the felt and the status rows, players for the black sidebars, the hole-card mask and the moving underline.],
  [`input.c`], [The stick picks a move, the fire button makes it, the keypad answers.],
  [`osk.c`], [An on-screen keyboard for the player’s name.],
  [`sound.c`], [POKEY for the deal, the chips and the turn.],
  [`network.c`], [The server: OPEN, READ, CLOSE.],
  [`appkey.c`], [The player’s name and the server’s address.],
)

The server’s address comes from appkey creator 1, app 1, key 1, the same way as Battleship’s; the bench points it at a local server’s `ai2` table, two bots.

#sect[Talking to the server]

One request per poll, and the whole answer in one READ:

#ex((path: "listings/5cardstud/atari5200/network.c", from: "uint8_t getResponse", to: "#endif"), t-c)

`network_read()` keeps reading until it has `max_len` bytes or the server has sent everything, so the buffer is the size of the largest state the server sends.

#sect[Two screens and an interrupt]

The table is redrawn whenever the server’s state changes, and a half-drawn table would flicker. So the client keeps two screens in the reserved top 4K of RAM: it draws into the work screen while ANTIC shows a copy of the last finished frame, and switches display lists when the new frame is complete:

#ex((path: "listings/5cardstud/atari5200/antic.s", from: "_scrWork  = $3000", to: "WSYNC"), t-asm)

The felt and the status bar are different colours on the same mode-4 screen. A display-list interrupt at the top of the table and two more at the status rows change them: each loads its background colour from a table first, stores to `WSYNC`, and only then writes `COLBK` and `COLPF1`, so the change lands between lines (@ch-antic). The font stays in ROM, at `$B800`, clear of the mailbox.

#sect[Building it]

```
git clone https://github.com/FujiNetWIFI/fujinet-5cardstud.git
cd fujinet-5cardstud
make PLATFORMS=atari5200 atari5200 FUJINET_LIB=<fujinet-lib-experimental>
```

The image is `r2r/atari5200/fcs.bin`; the game’s `support/atari5200/smoke.lua` drives it in MAME, and took the picture above.
