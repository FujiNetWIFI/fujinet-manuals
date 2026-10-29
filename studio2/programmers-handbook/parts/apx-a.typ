#import "../lib.typ": *
#set page(columns: 1)
#refpage.update(true)
#appendix.update(true)
#counter(heading).update(0)
#set heading(numbering: "A")

= Mailbox Quick Reference <apx-a>

#hang([The arena], tbl((0.9in, 1fr), [*Address*], [*Is*],
  [`$E400-$E7FF`], [the reply window, RXLEN bytes],
  [`$E800`], [the status page],
  [`$E9`_nn_ then `$EA`_vv_], [register nn = vv],
  [`$EB`_bb_], [one byte of the TX stream],
  [`$EC`_rc_], [the cursor to row r, column c],
  [`$ED`_cc_], [draw character cc],
  [`$EE`_op_], [run text operation op],
  [`$EF`_vv_], [push parameter vv],
  [`$F400-$FFFF`], [the picture: never read it],
))

#hang([The registers], tbl((0.9in, 0.5in, 1fr), [*Name*], [*No.*], [*Value*],
  [DEVICE], [`$00`], [`$70` FUJI, `$71` network, `$45` clock ...],
  [CMD], [`$01`], [the command],
  [NPARAM], [`$02`], [parameters: 0 to 8],
  [DATA_RST], [`$05`], [any: the TX stream starts over],
  [SEQ], [`$10`], [ACKSEQ + 1, skipping 0: launch],
  [BOOTLOCK], [`$11`], [`$B5`: arm the staged image],
  [CONFIG], [`$14`], [`$C5`: back to CONFIG],
))

#hang([The status page], tbl((0.9in, 0.9in, 1fr), [*Address*], [*Runtime name*], [*Is*],
  [`$E800`], [`FN_ACKSEQ`], [the answer’s sequence number; last painted],
  [`$E801`], [`FN_STAT`], [bit 0: the link],
  [`$E802`], [`FN_ERR`], [0, or the cartridge’s error],
  [`$E803`], [`FN_REPLYCMD`], [`$06` ACK, `$15` NAK],
  [`$E804`], [`FN_RXLEN`], [the reply’s length, low first],
  [`$E806`], [`FN_BOOTSTATE`], [0 idle, 1 coming, 2 ready, `$80` failed],
  [`$E807`], [`FN_BOOTPCT`], [0–100],
  [`$E808`], [`FN_BOOTERR`], [1 too big, 2 short, 3 bad page],
  [`$E809`], [`FN_MAGIC`], [`'F'`, `'N'`],
  [`$E812`], [`FN_MODE`], [0 CONFIG, 2 a game, 3 a FujiNet program],
  [`$E81C`], [`FN_ARMED`], [1: the swap is armed],
  [`$E823`], [`FN_SWAPS`], [hand-overs since power-on],
))

#hang([A transaction], asmp("        FNBEGIN FNDEVF, FNCADPX, 0  ; device, command, n
        SLOW    95              ; if it can take long
        FCALL   fn_go           ; launch and wait
        BNZ     failed          ; the cart's error
        FCALL   fn_ack
        BNZ     failed          ; the FujiNet's NAK
        PEEK    FN_RXLEN        ; and the reply"))

#hang([The RAM], tbl((0.9in, 1fr), [*Address*], [*Is*],
  [`$0800-$080F`], [the runtime’s `V_*`],
  [`$0810` up], [the program’s, from `V_APP`],
  [down from `$09FF`], [the stack, R2],
))

#refpage.update(false)
