#import "../lib.typ": *
#set heading(numbering: "A.1")
= Game and CONFIG Listings

The 5200 layers of Battleship (`src/atari5200/` at `3f2a548`) and 5 Card Stud (`src/atari5200/` at `d5db857`), and CONFIG’s screens and calls (`atari5200/` at fujinet-config `1bd6ec8`). The shared game code is every port’s and is not printed; CONFIG’s text engine is in Appendix C.

#sect[Battleship]

#listing2("fujinet.c", "listings/battleship/atari5200/fujinet.c")
#listing2("vars.h", "listings/battleship/atari5200/vars.h")
#listing2("graphics.c", "listings/battleship/atari5200/graphics.c")
#listing2("charset.s", "listings/battleship/atari5200/charset.s")
#listing2("input.c", "listings/battleship/atari5200/input.c")
#listing2("pad.h", "listings/battleship/atari5200/pad.h")
#listing2("osk.c", "listings/battleship/atari5200/osk.c")
#listing2("sound.c", "listings/battleship/atari5200/sound.c")
#listing2("util.c", "listings/battleship/atari5200/util.c")

#sect[5 Card Stud]

#listing2("network.c", "listings/5cardstud/atari5200/network.c")
#listing2("appkey.c", "listings/5cardstud/atari5200/appkey.c")
#listing2("vars.h", "listings/5cardstud/atari5200/vars.h")
#listing2("antic.s", "listings/5cardstud/atari5200/antic.s")
#listing2("graphics.c", "listings/5cardstud/atari5200/graphics.c")
#listing2("input.c", "listings/5cardstud/atari5200/input.c")
#listing2("osk.c", "listings/5cardstud/atari5200/osk.c")
#listing2("sound.c", "listings/5cardstud/atari5200/sound.c")
#listing2("util.c", "listings/5cardstud/atari5200/util.c")

#sect[CONFIG]

#listing2("config.c", "listings/config/config.c")
#listing2("state.h", "listings/config/state.h")
#listing2("st_hosts.c", "listings/config/st_hosts.c")
#listing2("st_files.c", "listings/config/st_files.c")
#listing2("st_boot.c", "listings/config/st_boot.c")
#listing2("st_wifi.c", "listings/config/st_wifi.c")
#listing2("st_copy.c", "listings/config/st_copy.c")
#listing2("st_info.c", "listings/config/st_info.c")
#listing2("st_lobby.c", "listings/config/st_lobby.c")
#listing2("fujiraw.h", "listings/config/fujiraw.h")
#listing2("fujiraw.c", "listings/config/fujiraw.c")
#listing2("fujidisp.c", "listings/config/fujidisp.c")
#listing2("fujiin.c", "listings/config/fujiin.c")
#listing2("fujiedit.c", "listings/config/fujiedit.c")
#listing2("sfx.c", "listings/config/sfx.c")
