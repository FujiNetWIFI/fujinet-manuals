#import "../lib.typ": *

= The Libraries

#lead[Two libraries stand between a program and the mailbox. One is a page
of assembly you have already read. The other is fujinet-lib, and its NES
half is a little over two hundred lines of C.]

== fujinet-lib on the NES

fujinet-lib is the same library on every FujiNet computer. Its common code
-- `network_open()`, `fuji_read_appkey()`, `clock_get_time()` and the rest --
turns every call into one or more *bus calls*:

#codepanel("The one function every platform implements",
"bool fuji_bus_call(uint8_t device, uint8_t fuji_cmd, uint8_t fields,
                   uint8_t aux1, uint8_t aux2, uint8_t aux3, uint8_t aux4,
                   const void *buf, size_t buf_length);")

`fields` says how the four `aux` bytes are to be sent -- none, one to four
single bytes, one or two 16-bit values, or one 32-bit value -- and whether
`buf` is a payload going out (`FUJI_FIELD_DATA`) or a place for the reply
(`FUJI_FIELD_REPLY`). The NES implementation maps that straight onto the
mailbox:

#excerpt-at("fujinet-lib bus/nes/fujinet-bus-nes.c", "listings/lib/fujinet-bus-nes.c",
  "  numbytes = fuji_field_numbytes(fields);", to: "  return true;", size: 6.4pt)

Three things to notice. It refuses, rather than truncates, a request that
would not fit the 320-byte TX stream. It sets NPARAM only after the
parameters are in. And a call with `FUJI_FIELD_REPLY` copies the reply out of
the window; a call without it leaves the reply in the window, where
`fuji_bus_call_rlen` says how long it is -- which is how CONFIG reads
directory entries without copying them.

#excerpt-at("fn_commit()", "listings/lib/fujinet-bus-nes.c",
  "uint8_t fn_commit(void)", to: "/*\n", n: 20, size: 6.8pt)

== The capped calls

#runin(
  ([`network_bus_read()`], [asks for at most 1024 bytes: the reply window.
   `network_read()` loops over it until it has what you asked for.]),
  ([`network_bus_write()`], [sends at most 317: the TX stream, less the
   three bytes of the count parameter. `network_write()` loops.]),
  ([`fuji_bus_appkey_read()`], [reads into a 66-byte buffer of its own,
   because on this bus the reply starts with two bytes of length, and gives
   you only the key.]),
)

== The NES's own calls

`fujinet-nes.h` adds what no other platform has:

#tbl((auto, 1fr),
  th[Call], th[Does],
  [`fuji_nes_present()`], [True if `'F'`, `'N'` and protocol version 1 are in the status page.],
  [`fuji_nes_boot_state()`], [BOOT_STATE: `FUJI_NES_BOOT_IDLE`, `_XFER`, `_READY` or `_FAILED`.],
  [`fuji_nes_boot_percent()`], [BOOT_PCT, 0-100.],
  [`fuji_nes_boot_error()`], [BOOT_ERR (Chapter 8).],
  [`fuji_nes_boot_got()`, `_total()`], [The image's byte counts. They are 24 bits painted a byte at a time, so the library reads them twice until two reads agree.],
  [`fuji_nes_boot()`], [BOOTLOCK, interrupts and PPU and APU off, jump to the loader. Never returns.],
  [`fuji_nes_kbd_detect()`], [Look for a keyboard on the expansion port: `FUJI_NES_KBD_NONE`, `_FAMILY_BASIC` or `_SUBOR`. Call once.],
  [`fuji_nes_kbd_getc()`], [Once a frame: the character of a key that has just gone down, or 0.],
  [`fuji_nes_kbd_scan()`], [The raw key matrix, for a program that wants it.],
  [`fn_regwr()`, `fn_tx()`, `fn_commit()`], [The mailbox itself, for a transaction built by hand.],
)

== Keyboards

The Famicom's two keyboards -- Nintendo's Family BASIC keyboard and the
Subor -- sit on the expansion port and are scanned through `$4016` and
`$4017`. `fuji_nes_kbd_detect()` tells them apart by what an idle port reads:
a disabled Subor still drives `$1E`, a Family BASIC keyboard reads 0. Letters
come in lower case, and upper case with Shift; the arrow keys, Enter, Escape,
Backspace and Home come as the `FUJI_NES_KEY_` codes.

#pair("; there is no assembly keyboard
; driver: link the C library's, or
; scan $4016/$4017 as kbd_nes.c does",
"uint8_t kbd = fuji_nes_kbd_detect();

for (;;) {
  char c;
  waitvsync();
  c = kbd ? fuji_nes_kbd_getc() : 0;
  if (c == FUJI_NES_KEY_ENTER)
    break;
}")

The netcat in Appendix D takes typing from a keyboard if one is there and from
an on-screen keyboard if not, the same as CONFIG.

== Building a transaction by hand

When a payload is built from pieces -- part from RAM, part out of the last
reply -- there is no single buffer to give `fuji_bus_call()`. CONFIG has five
such transactions in `fujiraw.c`. This one rewrites one host slot by streaming
the other seven straight out of the reply window:

#excerpt-at("CONFIG fujiraw.c: one host slot", "listings/config/fujiraw.c",
  "bool fnraw_write_host_slot", to: "bool fnraw_set_device_path_from_reply",
  size: 6.8pt)

It works because the reply window holds still until the next commit. Nothing
else may run between the READ and the commit that ends the WRITE -- not even
another of the program's own transactions.

== Building with the library's makefiles

A project that builds with fujinet-lib's own makefiles, as the games do, gets
the NES configuration, the map file and the claim for free from
`makefiles/platforms/nes.mk`:

#codepanel("makefiles/platforms/nes.mk, the part that matters",
"NES_CFG ?= $(MWD)/nes-fujinet.cfg
NES_MAP ?= $(EXECUTABLE:.nes=.map)
LDFLAGS += -C $(NES_CFG) -m $(NES_MAP)

$(PLATFORM)/executable-post::
	$(MWD)/nes-romstamp.py --stamp --map $(NES_MAP) $(EXECUTABLE)")

A game that wants a different layout -- its own CHR bank, a sprite page --
copies `nes-fujinet.cfg`, keeps the `CLAIM` memory area, and sets `NES_CFG`.
