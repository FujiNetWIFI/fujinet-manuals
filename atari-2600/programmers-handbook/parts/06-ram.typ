#import "../lib.typ": *
= Living in 128 Bytes

The console has 128 bytes of RAM, at `$80` to `$FF`. The stack is not separate: `$0100`--`$01FF` mirrors into the same 128 bytes, so the stack pointer starting at `$FF` means the stack grows down from the top of the only RAM there is. A path is 256 bytes. A directory entry is 30. A player's record in a game is 115. None of it fits, and none of it has to, because the cartridge is on the other side of the bus with all the memory in the world.

This section is the discipline that follows from that, and it is the discipline every program in this handbook is written under.

#sect[Nothing is copied]

The reply window is stable between transactions. So a program does not copy a reply into RAM to use it; it uses it where it lies:

- *Reply to row.* `FNRRPL` streams up to twelve bytes of the reply, at any offset, into a text row. The name of a file, the SSID, a line of a page: cartridge to cartridge, through one byte of the console at a time in the accumulator.
- *Reply to request.* `FNPRPL` appends bytes of the reply straight into the TX stream of the next request. A directory browser that reads an entry's name and then mounts it never holds the name.
- *Reply to path buffer.* `FNWRPL` appends bytes of the reply to one of the cartridge's path buffers, where they wait for the transaction that needs them. Battleship's table id and player name go this way, from the server's reply into every later URL, without ever landing in RAM.

The rule that makes these possible: the window is repainted only by a `SEQ` commit or a slice select. Read what you need before you launch the next transaction, or read it while you build the next transaction, but never after.

#sect[The cartridge holds the strings]

Four 256-byte path buffers live in the cartridge, selected by one-shot operations and edited a character at a time. A program appends characters, pops the last component, pops one character, resets, and asks the cartridge to emit the buffer into the TX stream --- NUL-padded to exactly 256 bytes, which is what `OPEN_DIRECTORY` and `SET_DEVICE_FULLPATH` read, or raw, which is what a URL wants. The buffers survive a console reset, because nothing on the cartridge sees the reset; a program that assumes an empty buffer at startup is wrong, and resets it.

The console cannot read a buffer back: the pages it is written through are write-only. A blit renders the buffer into a text row, which is how the on-screen keyboard in CONFIG shows what has been typed.

CONFIG needs all four at once --- the working directory, the filter, a pending copy's source path and the keyboard's edit scratch --- and the cartridge is the only place they could be.

#sect[The cartridge does the loops]

A Battleship game field is 100 cells in the reply, and turning it into ten rows of text is a hundred reads, a hundred compares and a 16-bit cursor, in a bank that has under a thousand bytes to spare, into RAM that does not exist. The blit port does it in six stores. Whenever the work is "take these bytes from the reply and put them on the screen", look for the transform first; Section 18 lists them.

#sect[The zero page, three ways]

Every program divides the 128 bytes differently, and the three divisions below are the ones this handbook uses.

#tbl((auto, 1fr, 1fr, 1fr),
  th[Cells], th[The library clients], th[Battleship], th[batari Basic],
  [`$80`--`$8B`], [the transport: FNSEQ `$80`, the kernel's PAD3 `$81` and SAVSP `$82`, FNCNT `$83`, FNDEV/FNCMD/FNNPR `$86`--`$88`, FNTMO `$89`, FNPTRL/H `$8A`--`$8B`], [the same cells, plus BSIDX and BSTMP in the holes], [the kernel: sprite positions and pointers, heights, score, `temp1`--`temp6`],
  [`$8C`--`$A7`], [FNPCNT `$8E`; the rest free --- but this is where the swap stub lands, so a client that boots keeps nothing here it needs afterwards], [the client's own cells: request, error, steps, the settle loop, cursor], [the kernel, then `rand` and `scorecolor`],
  [`$A8`--`$BF`], [INCUR/INPREV `$A8`--`$A9`; free], [cursor, edge memory, clock, ships, composer flags], [the RAM playfield, `var0`--`var47` (to `$D3`)],
  [`$C0`--`$FF`], [the stack], [the stack, which must stay above `$C0`], [`a`--`z` at `$D4`--`$ED`, `temp7`, `playfieldpos`, `aux1`--`aux6` at `$F0`--`$F5`, the stack from `$F6`])

The library's cells were chosen so that a client can put everything of its own above `$8C`. Battleship's map is in Section 19, with every alias and the reason for it. batari Basic's leaves a program 26 named variables and, if it draws no playfield, 48 more; its stack is ten bytes, which is five nested `gosub`s.

#sect[The stack pointer is a register]

The text kernel parks a graphics byte in the stack pointer for two cycles because the schedule does not close otherwise, and restores it before anything can push. The rule that makes that safe is that nothing between the `TXS` and the restore touches the stack, and on this console nothing can: there are no interrupts. A `JSR` into a routine that does this is fine, because its return address is pushed before the trick begins and nothing pushes again until it ends.

#sect[The swap stub]

The one thing that must run from RAM is the boot. The swap replaces every byte of the window, including the code that triggered it, so the thirty-byte stub that strobes the swap and jumps through the new vector is copied to `$80` and run there. The stack and the stub share the same 128 bytes; a program that boots keeps its stack pointer above the stub, and the library's copier checks that rather than corrupting itself.

#sect[A byte costs a bank]

In a banked program each bank carries its own copy of the routines it calls, because the high 2K is the mailbox and the fixed tail is 220 bytes. A byte added to a shared include is therefore a byte in every bank that includes it. Battleship splits its shared code behind feature flags for exactly that reason, and numbers its sound cues so that each bank's are a prefix of the list. Section 19 has the arithmetic.

#sect[What survives what]

#tbl((1fr, auto, auto),
  th[State], th[Console RESET], th[Power off],
  [console RAM], [survives (nothing clears it)], [lost],
  [the selected bank], [survives --- the cold stub reselects bank 0], [bank 0],
  [ACKSEQ and the mailbox's sequence], [survives --- derive SEQ from it], [restarts at 0],
  [the reply window, the text planes], [survive], [lost],
  [the four path buffers], [survive --- reset them], [empty],
  [the arming gate], [stays open], [closed until the pair arrives])

#note[The RESET switch restarts the 6507. It does not tell the cartridge anything, and a client decides what it means: Battleship uses it for a menu, and only a real 6507 restart, which no switch on the console produces during play, reaches the cold stub.]
