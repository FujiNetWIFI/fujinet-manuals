 rem fujilib.bas -- the mailbox subroutines for 7800basic, fujilib.s's
 rem one for one. incbasic it after the main loop, where it is never
 rem fallen into; call each with gosub.

 rem fn_chk -- fn_res = 0 if a FujiNet cartridge answers, else FN_ENOCART.
fn_chk
 fn_res = FN_ENOCART
 if FN_MAGIC0 <> $46 then return
 if FN_MAGIC1 <> $4E then return
 fn_res = FN_OK
 return

 rem fn_beg -- begin the transaction in fn_dev, fn_cmd, fn_npr. The TX
 rem stream is rewound last, so parameters can follow at once. Sets the
 rem timeout to 3 (about 13 seconds); raise fn_tmo after this for a
 rem slow command.
fn_beg
 FN_DEVICE = fn_dev
 FN_CMD = fn_cmd
 FN_NPARAM = fn_npr
 FN_DATA_RST = 0
 fn_tmo = 3
 return

 rem fn_pb -- append a one-byte parameter, fn_val.
fn_pb
 FN_TX = 1
 FN_TX = fn_val
 return

 rem fn_pw -- append a two-byte parameter, fn_val low and fn_valhi high.
fn_pw
 FN_TX = 2
 FN_TX = fn_val
 FN_TX = fn_valhi
 return

 rem fn_pad -- append NULs from byte fn_i until fn_i wraps: after a path
 rem of fn_i bytes, this makes it exactly 256.
fn_pad
 FN_TX = 0
 fn_i = fn_i + 1
 if fn_i <> 0 then goto fn_pad
 return

 rem fn_go -- launch it and wait, drawing the screen meanwhile. fn_res is
 rem 0 (FN_OK), the cartridge's error, FN_ENAK if the server said no, or
 rem FN_EWAIT if nothing came back in fn_tmo x 256 frames. The next
 rem sequence number is always the cartridge's ACKSEQ + 1, never a
 rem counter of ours: 0 is reserved, so 255 wraps to 1.
fn_go
 fn_seq = FN_ACKSEQ + 1
 if fn_seq = 0 then fn_seq = 1
 FN_SEQ = fn_seq
 fn_tick = 0
fn_go_wait
 if FN_ACKSEQ = fn_seq then goto fn_go_done
 drawscreen
 fn_tick = fn_tick + 1
 if fn_tick <> 0 then goto fn_go_wait
 fn_tmo = fn_tmo - 1
 if fn_tmo <> 0 then goto fn_go_wait
 fn_res = FN_EWAIT
 return
fn_go_done
 fn_res = FN_ERR
 if fn_res <> FN_OK then return
 if FN_REPLYCMD <> $06 then fn_res = FN_ENAK
 return

 rem fn_hex -- fn_val as two hex digits in fn_hexbuf, for plotchars.
fn_hex
 fn_i = fn_val / 16
 fn_hexbuf[0] = fn_hexdigits[fn_i]
 fn_i = fn_val & 15
 fn_hexbuf[1] = fn_hexdigits[fn_i]
 return

 alphadata fn_hexdigits fujifont
 '0123456789ABCDEF'
end
