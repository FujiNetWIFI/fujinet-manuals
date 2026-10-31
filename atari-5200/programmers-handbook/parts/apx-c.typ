#import "../lib.typ": *
#set heading(numbering: "A.1")
= Program Listings

Every program in this handbook, as built and run. The assembly library and its programs from `listings/common/` are the cartridge bring-up’s, unchanged; `antic.c` and its display list are CONFIG’s.

#sect[The assembly library]

#listing2("fujinet.inc", "listings/common/fujinet.inc")
#listing2("header.inc", "listings/common/header.inc")
#listing2("fujilib.s", "listings/common/fujilib.s")
#listing2("fujidisp.s", "listings/common/fujidisp.s")
#listing2("a52init.s", "listings/common/a52init.s")
#listing2("a52.cfg", "listings/common/a52.cfg")
#listing2("a52bank.cfg", "listings/common/a52bank.cfg")
#listing2("bank0.cfg", "listings/common/bank0.cfg")
#listing2("devdefs.inc", "listings/asm/devdefs.inc")
#listing2("netdefs.inc", "listings/asm/netdefs.inc")
#listing2("book.inc", "listings/asm/book.inc")

#sect[The assembly programs]

#listing2("hello.s", "listings/common/hello.s")
#listing2("fujitest.s", "listings/common/fujitest.s")
#listing2("pads.s", "listings/asm/pads.s")
#listing2("netget.s", "listings/asm/netget.s")
#listing2("netcat.s", "listings/asm/netcat.s")
#listing2("fujidir.s", "listings/asm/fujidir.s")
#listing2("fujiboot.s", "listings/common/fujiboot.s")
#listing2("appkey.s", "listings/asm/appkey.s")
#listing2("clock.s", "listings/asm/clock.s")
#listing2("bank.s", "listings/asm/bank.s")
#listing2("bank0.s", "listings/common/bank0.s")
#listing2("build.sh", "listings/asm/build.sh")

#sect[The C programs]

#listing2("antic.h", "listings/c/antic.h")
#listing2("antic.c", "listings/c/antic.c")
#listing2("antic_dl.s", "listings/c/antic_dl.s")
#listing2("book.h", "listings/c/book.h")
#listing2("hello.c", "listings/c/hello.c")
#listing2("conio.c", "listings/c/conio.c")
#listing2("acfg.c", "listings/c/acfg.c")
#listing2("pads.c", "listings/c/pads.c")
#listing2("netget.c", "listings/c/netget.c")
#listing2("netcat.c", "listings/c/netcat.c")
#listing2("dir.c", "listings/c/dir.c")
#listing2("boot.c", "listings/c/boot.c")
#listing2("appkey.c", "listings/c/appkey.c")
#listing2("clock.c", "listings/c/clock.c")
#listing2("bank.c", "listings/c/bank.c")
#listing2("bank0.c", "listings/c/bank0.c")
#listing2("supercart.s", "listings/c/supercart.s")
#listing2("bank.cfg", "listings/c/bank.cfg")
#listing2("build.sh", "listings/c/build.sh")
