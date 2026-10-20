 rem fujinet.bas -- the FujiNet cartridge's mailbox, named for 7800basic.
 rem incbasic it first; incbasic fujilib.bas after the main loop.
 rem
 rem In BASIC a register's name is its address: FN_CMD = $C4 is one store,
 rem STA $0D01. Use these names only on the left of a plain assignment
 rem or the right of a comparison, never in arithmetic: FN_TX = FN_TX + 1
 rem would read the page back and write twice.

 rem cells the cartridge paints: read them
 dim FN_REPLY = $0800
 dim FN_ACKSEQ = $0C00
 dim FN_STATUS = $0C01
 dim FN_ERR = $0C02
 dim FN_REPLYCMD = $0C03
 dim FN_RXLEN = $0C04
 dim FN_RXLENHI = $0C05
 dim FN_BOOTSTATE = $0C06
 dim FN_BOOTPCT = $0C07
 dim FN_BOOTERR = $0C08
 dim FN_MAGIC0 = $0C09
 dim FN_MAGIC1 = $0C0A
 dim FN_MODE = $0C12
 dim FN_INPTLOCK = $0C1D

 rem registers it watches: write them, one store each
 dim FN_DEVICE = $0D00
 dim FN_CMD = $0D01
 dim FN_NPARAM = $0D02
 dim FN_DATA_RST = $0D05
 dim FN_SEQ = $0D10
 dim FN_BOOTLOCK = $0D11
 dim FN_TX = $0F00

 rem the library's own variables
 dim fn_dev = var90
 dim fn_cmd = var91
 dim fn_npr = var92
 dim fn_val = var93
 dim fn_valhi = var94
 dim fn_res = var95
 dim fn_seq = var96
 dim fn_tick = var97
 dim fn_tmo = var98
 dim fn_i = var99
 dim fn_hexbuf = $27FE

 rem devices, and the commands these programs use
 const FN_FUJI = $70
 const FN_NET = $71
 const FN_CLOCK = $45
 const FN_OK = 0
 const FN_ENOCART = $FD
 const FN_ENAK = $EE
 const FN_EWAIT = $FF
 const FN_BOOT_READY = 2
 const FN_BOOT_FAILED = $80
