#import "../lib.typ": *
#set page(columns: 3)
#refpage.update(true)
#set heading(numbering: "A")

= Game and CONFIG Listings <apx-d>

The files the game and CONFIG chapters discuss, at the commits in the Parts List. The rest of each program is in its repository, and in `listings/`.

#sect[Battleship]

#listing3("tiles.inc", "listings/battleship/src/tiles.inc")
#listing3("board.inc", "listings/battleship/src/board.inc")
#listing3("net.inc", "listings/battleship/src/net.inc")
#listing3("url.inc", "listings/battleship/src/url.inc")

#sect[5 Card Stud]

#listing3("cards.inc", "listings/5cardstud/src/cards.inc")

#sect[CONFIG]

#listing3("fujicmd.inc", "listings/config/src/fujicmd.inc")
#listing3("boot.inc", "listings/config/src/boot.inc")
#listing3("edit.inc", "listings/config/src/edit.inc")

#refpage.update(false)
