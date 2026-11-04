#import "../lib.typ": *
#set heading(numbering: "A")

= Program Listings <apx-c>

The handbook’s programs and libraries, then the runtime they are built on,
exactly as `listings/` holds them.

#{
  for f in ("asm/bookdefs.inc", "asm/booklib.inc", "asm/netlib.inc",
            "asm/pads.asm", "asm/netget.asm", "asm/netcat.asm", "asm/fujidir.asm",
            "asm/appkey.asm", "asm/clock.asm", "asm/sprites.asm",
            "runtime/fujilib.inc", "runtime/fujidisp.inc", "runtime/hello.asm",
            "runtime/fujitest.asm", "runtime/fujiboot.asm", "runtime/fujibank.asm") {
    listing2(f.split("/").last(), "listings/" + f, size: 6.9pt)
  }
})
