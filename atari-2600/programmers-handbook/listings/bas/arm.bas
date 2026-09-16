 rem arm.bas -- spike S2: open the decode gate and run one transaction,
 rem GET_ADAPTERCONFIG_EXTENDED, from BASIC alone. The mailbox's names come
 rem from the assembler headers: an assignment to one is a store, a read of
 rem one is a load. No dim is needed.
 include fujinet.h
 include fujibas.h
 include devdefs.h
 set romsize 2k
 dim fnseq = a
 dim ch = b
 COLUBK = 0
 FNH_ARM1 = FNAM1
 FNH_ARM2 = FNAM2
 rem device $70 (FUJI), command $C4, no parameters, rewind TX
 FNA_DEV = 0
 FNCMT = FNDEVF
 FNA_CMD = 0
 FNCMT = FNCADPX
 FNA_NPAR = 0
 FNCMT = 0
 FNA_DRST = 0
 FNCMT = 0
 rem launch: SEQ = the cartridge's ACKSEQ + 1, wrapping 255 to 1
 fnseq = FNACKS + 1
 if fnseq = 0 then fnseq = 1
 FNA_SEQ = 0
 FNCMT = fnseq
wait
 drawscreen
 if FNACKS <> fnseq then goto wait
 rem done: green screen if the transport reported OK, red otherwise
 COLUBK = $C4
 if FNERR <> 0 then COLUBK = $34
 ch = FNRPLY[0]
main
 drawscreen
 goto main
