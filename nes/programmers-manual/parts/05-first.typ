#import "../lib.typ": *

= Your First Transaction

#lead[The first program asks the FujiNet one question -- "how are you
connected?" -- and puts the answer on the screen.]

#objbox("Object of this chapter")[Build `hello`, in C and in assembly; run it;
follow its one transaction through the mailbox; and press Reset to watch the
sequence number carry on.]

== In C

#wholefile("listings/c/hello.c", "listings/c/hello.c")

#runin(
  ([`fuji_nes_present()`], [checks the magic bytes and the protocol version
   in the status page. On an ordinary cartridge they are open bus.]),
  ([`fuji_get_adapter_config_extended()`], [is one transaction: device `$70`,
   command `$C4`, no parameters, no payload. The 240-byte reply is copied out
   of the reply window into `ac`.]),
  ([`cputs`, `cprintf`], [are cc65's console routines. On the NES they queue
   their writes for the vblank NMI, so they work with the screen on.]),
)

#shots("hello-c", "hello-asm", caption: [`hello` in C (left) and in assembly
(right). The FujiNet here is fujinet-pc, whose WiFi is a fixture called
"Dummy Cafe".])

== In assembly

The assembly version does the same, with the transaction spelled out. Here is
its heart; the whole program is Listing 1 in Appendix C.

#excerpt-at("listings/asm/hello.s", "listings/asm/hello.s", "have:   CALL",
  to: "fail:   pha", size: 7pt)

#runin(
  ([`CALL FNDEVF, FNCADPX, 0`], [is a macro from `book.inc`. It stores the
   device, the command and the parameter count in the library's zero page and
   calls `fn_beg`, which writes them to registers `$00-$02` and rewinds the TX
   stream.]),
  ([`fn_go`], [commits: ACKSEQ plus one goes to SEQ, then it waits for ACKSEQ
   to match. It returns the cartridge's ERR in A, with the Z flag set for
   success, or `FNEWAIT` if the cartridge never answered.]),
  ([`fn_ack`], [looks at REPLY_CMD: zero for ACK, `FNENAK` for NAK.]),
  ([`disp_rpl`], [copies up to Y bytes from offset X of the reply window
   straight to the PPU, stopping at a NUL. The answer never touches console
   RAM.]),
)

The reply's layout is the firmware's `AdapterConfigExtended`, packed:

#tbl((auto, auto, 1fr),
  th[Offset], th[Bytes], th[Field],
  [0], [33], [`ssid` -- "NOT CONNECTED" when WiFi is down],
  [33], [64], [`hostname`],
  [97], [4 each], [`localIP`, `gateway`, `netmask`, `dnsIP`, as four binary bytes],
  [113], [6 each], [`macAddress`, `bssid`],
  [125], [15], [`fn_version` (no NUL if it fills the field)],
  [140], [16 each], [`sLocalIP`, `sGateway`, `sNetmask`, `sDnsIP`, as text],
  [204], [18 each], [`sMacAddress`, `sBssid`, as text; 240 in all],
)

== What crossed the mailbox

#tbl((auto, 1fr),
  th[Store or load], th[Meaning],
  [`$5500 ← $70`], [DEVICE: the Fuji device],
  [`$5501 ← $C4`], [CMD: GET_ADAPTERCONFIG_EXTENDED],
  [`$5502 ← $00`], [NPARAM: none],
  [`$5505 ← $00`], [DATA_RST: empty TX stream],
  [`$5510 ← $01`], [SEQ: ACKSEQ was 0, nothing answered yet, so 1],
  [`$5400 → $01`], [ACKSEQ matches: done],
  [`$5402 → $00`], [ERR: the FujiNet answered],
  [`$5403 → $06`], [REPLY_CMD: ACK],
  [`$5404 → $F0`], [RXLEN: 240 bytes, now at `$5000-$50EF`],
)

== Press Reset

#shots("hello-asm", "hello-reset", caption: [Before and after the console's
Reset. The program started again from nothing, but the cartridge did not: the
next sequence number was 2.])

`hello.s` prints ACKSEQ at the bottom of the screen. Press Reset: the 6502
starts over, `nesinit.s` clears all of RAM, and `fn_go` reads ACKSEQ -- still 1 --
and sends 2. Had it counted from a variable of its own it would have sent 1
again, the cartridge would have ignored it, and the program would have printed
the stale reply as if it were new.

== The assembly library

`fujilib.s` is the cartridge firmware's own test library, unchanged. It is
short enough to know by heart:

#tbl((auto, auto, 1fr),
  th[Routine], th[Takes], th[Does],
  [`fn_chk`], [], [Z set if the magic bytes say a FujiNet is there.],
  [`fn_rw`], [X reg, A value], [One register write.],
  [`fn_beg`], [`fn_dev`, `fn_cmd`, `fn_npr`], [Begin a transaction: the three registers, then DATA_RST. Sets the timeout to 16 quanta.],
  [`fn_txb`], [A], [Append one raw byte to the TX stream.],
  [`fn_pb`], [A], [Append a one-byte parameter (size byte 1, then A).],
  [`fn_pw`], [A low, X high], [Append a two-byte parameter.],
  [`fn_path`], [`fn_ptr`], [Append the string at `fn_ptr`, padded with NULs to exactly 256 bytes.],
  [`fn_go`], [`fn_tmo`], [Commit and wait. A = ERR (Z set if 0), or `FNEWAIT`.],
  [`fn_ack`], [], [A = 0 if the reply was ACK, else `FNENAK`.],
  [`fn_blk`], [], [Arm the loader (BOOTLOCK = `$B5`).],
  [`fn_boot`], [], [Interrupts and PPU off, jump to the loader at `$5800`. Never returns.],
)

`booklib.s` adds what this manual's programs need beyond that:

#tbl((auto, 1fr),
  th[Routine], th[Does],
  [`nmi`], [The vblank handler: counts frames in `frames`, nothing else.],
  [`wait_vbl`], [Wait for the next vblank.],
  [`scroll0`], [After drawing in vblank: scroll home, NMI on.],
  [`fn_str`], [Append the string at `fn_ptr` *without* padding -- for URLs.],
  [`fn_launch`], [Commit without waiting.],
  [`fn_done`], [C set once the launched transaction has been answered.],
  [`disp_d3`], [A as three decimal digits, right-aligned.],
)

#caution[The library keeps its state in zero page `$E0-$EF`: the sequence it
is waiting for, the timeout, the transaction setup and `fn_ptr`. Keep your own
variables out of it. `nes.cfg` stops the ZEROPAGE segment at `$E0`.]

The display routines in `fujidisp.s` write straight to the PPU and must run
with rendering off, or inside vblank; Chapter 11 explains why. `hello.s`
draws everything first and turns the screen on last.
