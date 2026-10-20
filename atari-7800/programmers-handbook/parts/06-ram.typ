#import "../lib.typ": *
= Living in 4K

#ini[T]he 7800 has 4K of RAM, at `$1800`–`$27FF`. Two pieces of it are also seen low in memory: `$2040`–`$20FF` is the zero page at `$0040`–`$00FF`, and `$2140`–`$21FF` is the stack page at `$0140`–`$01FF`. The bottom of both pages belongs to TIA and MARIA. So the zero page, the stack and everything else share the same 4K, and MARIA’s display lists usually want a good part of it.

The FujiNet cartridge helps in two ways. A program that sets the claim’s RAM flag gets 16K more at `$4000`–`$7FFF`, in the cartridge, which MARIA can read like any other memory. And the reply window is 1K of memory the program never has to give up RAM for: a reply is read where it lies.

#sect[Who uses what]

#tbl((auto, 1fr, 1fr, 1fr),
  th[], th[Assembly], th[C], th[7800basic],
  [Zero page], [`$40`–`$DF` the program’s; `$E0`–`$EB` the library’s], [`$40`–`$FF`: cc65’s registers and the program’s `ZEROPAGE`], [`$40`–`$4A` its temporaries; `a`–`z` at `$E6`–`$FF`],
  [Stack page], [the 6502 stack], [the 6502 stack], [`var0`–`var99` at `$140`–`$1A3`, its own variables above, then the stack from `$1C2`],
  [`$1800`–`$27FF`], [free], [`CONSOLE` segment (optional)], [`$1800` the DLL, `$1880`–`$1FFF` display lists, its variables; `$2200`–`$27FF` free],
  [`$4000`–`$7FFF`], [screen, lists, DLL; variables (`BSS`)], [data, `BSS`, heap; the tile map and lists; the C stack (2K) at the top], [not used unless `set romsize 32kRAM`],
)

The handbook’s 7800basic library keeps its ten variables in `var90`–`var99`, so a program has `var0`–`var89`, `a`–`z` and the free RAM from `$2200`. A string that MARIA must show, and anything else bigger than a byte, goes in that free RAM with `dim name = $2200`.

#note[The loader runs from the cartridge and borrows `$80`–`$89` while it copies an image in. A program finds them dirty, along with S at `$16` and MARIA’s DMA off. Clear what you use, and set the stack before anything else.]

#sect[The reply is free memory]

The reply window at `$0800` is the biggest buffer a FujiNet program has, and it costs no RAM. Read a reply where it lies: walk it with an index, compare against it, take bytes from it into the screen. Copy only what must outlive the next transaction, or what MARIA must draw.

#tbl((auto, 1fr),
  th[Language], th[Reading the reply in place],
  [Assembly], [`LDA FN_REPLY,X` — or `(ptr),Y` for more than 256 bytes.],
  [C], [`FN_REPLY[i]` from the bus header; fujinet-lib’s calls copy into your buffer for you.],
  [7800basic], [`FN_REPLY[ix]`; for a field past the first 256 bytes, or for clarity, `dim` a name at its address: `dim FN_R_IP = $088C`.],
)

#sect[What survives what]

#tbl((auto, 1fr, 1fr),
  th[], th[RESET switch], th[Power off and on],
  [Your program], [keeps running: RESET is a bit in `SWCHB` you read], [gone: the cartridge boots CONFIG],
  [Console RAM], [kept], [lost],
  [Cartridge RAM (`$4000`)], [kept], [cleared by the loader when CONFIG loads],
  [The cartridge’s `ACKSEQ`], [kept], [kept: the cartridge was never reset],
  [The FujiNet adapter], [untouched], [untouched],
)

The last two rows are why a program must take its sequence number from `ACKSEQ` and never count for itself (Section 4). A FujiNet program also cannot leave anything in the adapter that it expects to be gone: a network connection opened before the power went off is still open, and a program that may have been interrupted should close what it opens before it opens it again.
