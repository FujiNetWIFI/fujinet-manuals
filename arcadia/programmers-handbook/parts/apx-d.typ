#import "../lib.typ": *
#set heading(numbering: "A")

= Game and CONFIG Listings <apx-d>

The files Sections 21 to 23 quote, at the revisions in the Parts List.

#{
  for f in ("battleship/input.inc", "battleship/net.inc", "battleship/place.inc",
            "5cardstud/state.inc", "5cardstud/net.inc",
            "config/mailbox.inc", "config/boot.inc") {
    listing2(f, "listings/" + f, size: 6.9pt)
  }
})
