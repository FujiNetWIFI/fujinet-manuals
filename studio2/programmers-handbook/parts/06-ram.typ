#import "../lib.typ": *

= Living in 512 Bytes <ram>

The Studio II has 512 bytes of RAM, `$0800` to `$09FF`, and a FujiNet program has all of them. The console’s own games lose the top 256 to their picture; a FujiNet program’s picture lives in the cartridge, so the whole of it is yours.

Everything else a program can reach is read-only: its code, its strings and tables on the cartridge’s pages, and the reply window. A variable, the stack and anything the program builds must live in those 512 bytes.

== The ledger

#tbl((0.95in, 1fr),
  [*Bytes*], [*Belong to*],
  [`$0800-$080F`], [the runtime’s variables, `V_TMO` to `V_T`],
  [`$0810` up], [the program’s variables, from `V_APP`],
  [... down to R2], [the stack, from `$09FF` down],
)

#tbl((0.7in, 1fr),
  [*Variable*], [*Holds*],
  [`V_TMO`], [`fn_go`’s timeout, in seconds],
  [`V_SEQ`], [the sequence number it launched],
  [`V_CNT`], [`fn_frames`’s countdown, two bytes],
  [`V_LAST`], [the frame `fn_tick` last saw],
  [`V_KTMP`], [the key number `OUT 2` sends to the keypads],
  [`V_KLAST`], [the key held at the last scan],
  [`V_KTIME`], [when a held key repeats next],
  [`V_T`], [scratch for one routine at a time],
)

Write the program’s own ledger at the top of its source, as a comment and as equates, and let the assembler check that the pieces do not overlap. The netcat’s is typical: its variables, the line being typed, a copy of the screen, and the stack.

#excerpt-at(auto, "listings/asm/netcat.asm", "; ---- RAM ledger", to: "NROWS   EQU")

== The stack

R2 is the stack pointer, from `$09FF` downwards, and X is 2 between calls. Each `FCALL` pushes the caller’s link, two bytes, and `FRET` takes them back. The byte R2 points at is free: a routine may use it as scratch with `STR R2` and arithmetic on M(R(X)), until its next call.

#important[The display interrupt saves two bytes *below* R2, sixty times a second, at any moment. Never keep anything below the stack pointer.]

== The reply window is memory too

The reply to the last transaction stays at `$E400` until the next one is launched: a kilobyte of read-only memory a program did not have to find room for. `netget` reads its text straight out of it with LDA, and the text engine prints from it without the bytes crossing into the console at all. Copy out only what must outlive the next transaction.

== What survives what

#tbl((0.95in, 1fr, 1fr),
  [*Event*], [*The program*], [*The cartridge*],
  [CLEAR], [starts over from the BIOS; RAM is the BIOS’s to clear], [keeps the program and ACKSEQ: the next sequence number goes on],
  [a hand-over], [the new program starts; `$08A0-$08FF` are zeroed], [ACKSEQ starts again at 0],
  [power off], [gone], [back to CONFIG],
)

Turning the console off is the only way back from a game, the image that does not claim the mailbox; a FujiNet program can go back to CONFIG by itself, with `fn_config`.
