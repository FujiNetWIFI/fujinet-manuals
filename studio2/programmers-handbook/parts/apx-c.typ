#import "../lib.typ": *
#set page(columns: 3)
#refpage.update(true)
#set heading(numbering: "A")

= Program Listings <apx-c>

Every program in this handbook, as built and run. The runtime, `listings/runtime/`, is the cartridge bring-up’s, unchanged.

#sect[The runtime]

#listing3("fujinet.inc", "listings/runtime/fujinet.inc")
#listing3("s2macro.inc", "listings/runtime/s2macro.inc")
#listing3("s2call.inc", "listings/runtime/s2call.inc")
#listing3("fujilib.inc", "listings/runtime/fujilib.inc")
#listing3("fujidisp.inc", "listings/runtime/fujidisp.inc")
#listing3("input.inc", "listings/runtime/input.inc")

#sect[The handbook’s additions]

#listing3("s2defs.inc", "listings/asm/s2defs.inc")
#listing3("booklib.inc", "listings/asm/booklib.inc")
#listing3("build.sh", "listings/asm/build.sh")

#sect[The programs]

#listing3("hello.asm", "listings/runtime/hello.asm")
#listing3("fujitest.asm", "listings/runtime/fujitest.asm")
#listing3("netget.asm", "listings/asm/netget.asm")
#listing3("fujidir.asm", "listings/asm/fujidir.asm")
#listing3("fujiboot.asm", "listings/runtime/fujiboot.asm")
#listing3("appkey.asm", "listings/asm/appkey.asm")
#listing3("clock.asm", "listings/asm/clock.asm")
#listing3("keys.asm", "listings/asm/keys.asm")
#listing3("glyphs.asm", "listings/asm/glyphs.asm")
#listing3("pages.asm", "listings/asm/pages.asm")
#listing3("netcat.asm", "listings/asm/netcat.asm")
#listing3("osk.inc", "listings/asm/osk.inc")

#refpage.update(false)
