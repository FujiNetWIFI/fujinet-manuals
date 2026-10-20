#import "../lib.typ": *
#set heading(numbering: "A.1")
= Program Listings

Every program in this handbook, as built and run. The assembly library and its programs from `listings/common/` are the cartridge bring-up’s, unchanged.

#sect[The assembly library]

#listing2("fujinet.inc", "listings/common/fujinet.inc")
#listing2("fujilib.s", "listings/common/fujilib.s")
#listing2("fujidisp.s", "listings/common/fujidisp.s")
#listing2("a78init.s", "listings/common/a78init.s")
#listing2("a78.cfg", "listings/common/a78.cfg")
#listing2("a78bank.cfg", "listings/common/a78bank.cfg")
#listing2("devdefs.inc", "listings/asm/devdefs.inc")
#listing2("netdefs.inc", "listings/asm/netdefs.inc")

#sect[The assembly programs]

#listing2("hello.s", "listings/common/hello.s")
#listing2("fujitest.s", "listings/common/fujitest.s")
#listing2("netget.s", "listings/asm/netget.s")
#listing2("fujidir.s", "listings/asm/fujidir.s")
#listing2("fujiboot.s", "listings/common/fujiboot.s")
#listing2("appkey.s", "listings/asm/appkey.s")
#listing2("clock.s", "listings/asm/clock.s")
#listing2("fujibank.s", "listings/common/fujibank.s")
#listing2("build.sh", "listings/asm/build.sh")

#sect[The C programs]

#listing2("hello.c", "listings/c/hello.c")
#listing2("acfg.c", "listings/c/acfg.c")
#listing2("netget.c", "listings/c/netget.c")
#listing2("dir.c", "listings/c/dir.c")
#listing2("boot.c", "listings/c/boot.c")
#listing2("appkey.c", "listings/c/appkey.c")
#listing2("clock.c", "listings/c/clock.c")
#listing2("bank.c", "listings/c/bank.c")
#listing2("bank.cfg", "listings/c/bank.cfg")
#listing2("crt0bank.s", "listings/c/crt0bank.s")
#listing2("build.sh", "listings/c/build.sh")

#sect[The 7800basic library and programs]

#listing2("fujinet.bas", "listings/bas/fujinet.bas")
#listing2("fujilib.bas", "listings/bas/fujilib.bas")
#listing2("hello.bas", "listings/bas/hello.bas")
#listing2("acfg.bas", "listings/bas/acfg.bas")
#listing2("netget.bas", "listings/bas/netget.bas")
#listing2("dir.bas", "listings/bas/dir.bas")
#listing2("boot.bas", "listings/bas/boot.bas")
#listing2("appkey.bas", "listings/bas/appkey.bas")
#listing2("clock.bas", "listings/bas/clock.bas")
#listing2("bank.bas", "listings/bas/bank.bas")
#listing2("build.sh", "listings/bas/build.sh")

#sect[The tools]

#listing2("basfix.py", "tools/basfix.py")
#listing2("mkbasfont.py", "tools/mkbasfont.py")
#listing2("checkbanks.py", "tools/checkbanks.py")
#listing2("emu/run.sh", "emu/run.sh")
#listing2("emu/screen.lua", "emu/screen.lua")
#listing2("emu/verify.sh", "emu/verify.sh")
