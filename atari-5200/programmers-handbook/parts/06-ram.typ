#import "../lib.typ": *
= Living in 16K <ch-ram>

The 5200 has 16K of RAM, from `$0000` to `$3FFF`, and a FujiNet program has all of it: the BIOS steps aside before the program starts, and the cartridge never needs the console’s RAM for anything. What the BIOS would have used is still laid out the BIOS’s way, because both languages’ start-up code keeps that layout, and cc65’s library depends on it.

#sect[Zero page]

#tbl((auto, auto, 1fr),
  th[Address], th[Name], th[What it is],
  [`$00`], [POKMSK], [The POKEY interrupts the program wants on; the IRQ handler restores `IRQEN` from it.],
  [`$01`–`$02`], [RTCLOK], [The frame counter, high byte first: the VBI adds one to `$02` every frame.],
  [`$03`], [CRITIC], [Non-zero: the VBI skips the shadow copies this frame.],
  [`$04`], [ATRACT], [The attract-mode counter. A key press clears it.],
  [`$05`–`$07`], [SDLST, SDMCTL], [Display shadows (@ch-display).],
  [`$08`–`$10`], [PCOLR0–3, COLOR0–4], [Colour shadows for the players and the playfield.],
  [`$11`–`$18`], [PADDL0–7], [The eight pots, copied by the VBI: each controller’s stick X and Y (@ch-pads).],
  [`$19`], [KEY], [Assembly: the last keypad key + 1 (`a52init.s`).],
  [`$19`–`$1C`], [], [C: cc65’s console cursor and colour.],
  [`$1D`–`$FF`], [], [C: cc65’s own zero page, and yours.],
  [`$E0`–`$ED`], [`FN_*`], [Assembly: the 6502 library’s (@ch-library).],
  [`$F0`–`$F5`], [PTR1, PTR2, ZTMP], [Assembly: this handbook’s programs’ pointers (`book.inc`).],
)

#caution[The bring-up’s `a52.cfg` starts the linker’s `ZEROPAGE` segment at `$19`, which is also `KEY`, the byte the keypad interrupt writes. A program that puts a variable in `ZEROPAGE` and reads the keypad loses one or the other. This handbook’s programs keep their variables in `BSS` and put the few pointers they need at fixed addresses above the library’s.]

#sect[The vectors]

The BIOS’s interrupt handlers jump through RAM vectors at `$0200`–`$021B`, with nothing saved: a handler saves what it uses. Both start-up files fill the table with handlers that do what the BIOS’s would.

#tbl((auto, auto, 1fr),
  th[Address], th[Vector], th[Taken on],
  [`$0200`], [VIMIRQ], [Every IRQ: the handler looks at `IRQST` and goes on through one of the rest.],
  [`$0202`], [VVBLKI], [The vertical blank, first: the frame counter and the shadow copies.],
  [`$0204`], [VVBLKD], [The vertical blank, deferred: put your own per-frame work here.],
  [`$0206`], [VDSLST], [A display-list interrupt (@ch-antic).],
  [`$0208`], [VKYBDI], [A keypad key: reads `KBCODE` and translates it.],
  [`$020A`], [VKYBDF], [The keypad, continued: here the translated key is counted.],
  [`$020C`–`$021A`], [], [POKEY’s other interrupts: break, `BRK`, serial, timers 1, 2 and 4. Unused here.],
)

#sect[RAM]

#tbl((auto, auto, auto),
  th[], th[Assembly (`a52.cfg`)], th[C (MekkoGX)],
  [`$0100`–`$01FF`], [the 6502 stack], [the 6502 stack],
  [`$0200`–`$021B`], [vectors], [vectors],
  [`$021C`–`$02FF`], [free], [data, BSS, heap…],
  [`$0300`–`$0FFF`], [`BSS`], […],
  [`$1000`–`$13BF`], [the screen], […],
  [`$13C0`–`$37FF`], [free], […],
  [`$3800`–`$3BFF`], [free], [the C stack (1K)],
  [`$3C00`–`$3FFF`], [free], [reserved: `antic.c`’s screen],
)

In C, `__RESERVED_MEMORY__` takes room off the top of RAM, and the 1K C stack goes below it. This handbook’s C programs reserve 1K for the `antic.c` screen at `$3C00`; cc65’s console needs `$3E20`–`$3FFF`, so 1K covers it too.

#sect[What lasts]

Nothing in RAM outlives the program. Handing the console to another image clears all 16K as a power-on does. A power cycle restarts everything, the cartridge included: it watches the console’s power, and when the power comes back it serves CONFIG with its count started over. A program that must remember something between runs keeps it on the FujiNet, in an appkey (@ch-keys).

#sect[The reply is not yours]

The reply window at `$B000` is cartridge memory. A program may read it as often as it likes, but only until its next transaction, and ANTIC must never read it. Text from a reply goes on the screen by being copied into screen RAM, as `disp_rpl` does in assembly and `mt_text` in C; data a program wants to keep goes into its own RAM before the next transaction.
