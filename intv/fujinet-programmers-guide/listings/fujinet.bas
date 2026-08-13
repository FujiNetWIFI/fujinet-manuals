' fujinet.bas -- FujiNet mailbox transport + network/appkey primitives.
'
' Mailbox layout is the hand-synchronized copy of
' fujinet-firmware/pico/intellivision/firmware/fuji_mailbox.h, exactly as
' proven working by intv/fujitest.bas in that repo. Do not change these
' addresses without re-checking that file.
'
' MEMATTR intentionally stops at $9BFF, short of the $9C00-$9FFF mailbox
' itself: on real PiRTO II hardware the RP2040 maps that whole window as
' RAM unconditionally (inty_cart.c hardcodes it, independent of what this
' .cfg says), so declaring less here doesn't affect real hardware or what
' POKE can reach at runtime. But jzIntv's --fujinet peripheral emulation
' registers its own handler for $9C00-$9FFF *after* the cart's generic
' MEMATTR RAM, and its layered bus dispatch lets whichever peripheral
' registered first answer a given address -- so declaring the full
' $8000-$9FFF range here (as fujitest.bas does) silently shadows the
' emulator's FujiNet peripheral with inert RAM, and the mailbox never
' comes up under --fujinet even though it works on real hardware.
    ASM MEMATTR $8000, $9BFF, "+RWN"

    CONST FN_MAGIC0     = $9C00
    CONST FN_MAGIC1     = $9C01
    CONST FN_SEQ        = $9C03
    CONST FN_ACKSEQ     = $9C04
    CONST FN_DEVICE     = $9C05
    CONST FN_CMD        = $9C06
    CONST FN_NPARAM     = $9C07
    CONST FN_TXLEN_LO   = $9C08
    CONST FN_TXLEN_HI   = $9C09
    CONST FN_ERR        = $9C0B
    CONST FN_RXLEN_LO   = $9C0C
    CONST FN_RXLEN_HI   = $9C0D
    CONST FN_REPLY_CMD  = $9C0E
    CONST FN_PARAM_SIZE = $9C10
    CONST FN_PARAM_VAL  = $9C20
    CONST FN_TX         = $9C40
    CONST FN_RX         = $9D40

    CONST FUJICMD_ACK = $06
    CONST FUJICMD_NAK = $15

    ' Fuji device (config/appkey) commands.
    CONST FUJI_DEVICEID       = $70
    CONST FUJICMD_OPEN_APPKEY  = $DC
    CONST FUJICMD_CLOSE_APPKEY = $DB
    CONST FUJICMD_WRITE_APPKEY = $DE
    CONST FUJICMD_READ_APPKEY  = $DD

    ' Network device (N1:) commands.
    CONST NET_DEVICEID = $71
    CONST NETCMD_OPEN   = $4F
    CONST NETCMD_CLOSE  = $43
    CONST NETCMD_READ   = $52
    CONST NETCMD_WRITE  = $57
    CONST NETCMD_STATUS = $53

    ' $0C is HTTP "GET with header access" and, on file/socket protocols,
    ' plain READ-WRITE -- the same value serves both names.
    CONST OPEN_MODE_HTTP_GET_H = $0C
    CONST OPEN_MODE_RW = $0C
    CONST OPEN_TRANS_NONE = $00

    ' Scratch RAM ($9000-$97FF) -- ours, outside the mailbox proper. Holds
    ' state that must survive across multiple mailbox transactions (the
    ' mailbox's own TX/RX buffers get overwritten by every call).
    CONST SC_NAME    = $9100 ' playerName, 9 bytes (8 + NUL)
    CONST SC_ENDPT   = $9110 ' serverEndpoint, 64 bytes
    CONST SC_QUERY   = $9150 ' query (?table=...&player=...), 48 bytes

    ' fn_ok: 1 = last transaction produced ACK, 0 = timeout or NAK.
    ' mb_err: FN_ERR value on failure (0 on timeout, since the RP2040 never answered).
    DIM fn_ok, #mb_err
    DIM mb_dev, mb_cmd, mb_nparam, mb_seq
    DIM #fn_txlen
    DIM #fn_t          ' generic frame-count timeout counter
    DIM #fn_src         ' VARPTR source for putstr/getstr
    DIM fn_len, fn_i    ' generic length/index for putstr/getstr

' ---------------------------------------------------------------------------
' fn_wait_mailbox: bounded wait for the RP2040 magic bytes at boot.
' Sets fn_ok = 1 if the mailbox came up within 180 frames (3s), else 0.
' ---------------------------------------------------------------------------
fn_wait_mailbox: PROCEDURE
    #fn_t = 0
    WHILE ((PEEK(FN_MAGIC0) AND 255) <> 70) AND ((PEEK(FN_MAGIC1) AND 255) <> 78) AND (#fn_t < 180)
        #fn_t = #fn_t + 1
        WAIT
    WEND
    IF #fn_t >= 180 THEN
        fn_ok = 0
    ELSE
        fn_ok = 1
    END IF
END

' ---------------------------------------------------------------------------
' fn_transact: issue the transaction described by mb_dev/mb_cmd/mb_nparam/
' #fn_txlen (payload already staged at FN_TX) and block for the reply.
' seq is ALWAYS derived from the RP2040's own FN_ACKSEQ, never from a local
' counter -- a console reset zeroes IntyBASIC vars but not the RP2040, so a
' locally incrementing seq would recompute the same value forever and never
' trigger a second transaction after the first boot.
' Sets fn_ok = 1 on ACK, 0 on timeout/NAK (mb_err holds the reason).
'
' mb_err/net_err are deliberately 16-bit (#-prefixed), not the 8-bit plain
' variables their DIM comments once declared them as: IntyBASIC v1.4.2
' silently drops the AND 255 mask on any assignment of the literal shape
' "plain_var = PEEK(...) AND 255" (with or without wrapping parens) when
' the destination is an 8-bit variable -- confirmed by reading the
' generated .lst, no ANDI instruction is emitted at all, so whatever
' garbage sits in the peeked word's upper byte survives into the
' variable. #-prefixed (16-bit) destinations don't hit this; the ANDI
' shows up correctly. net_err in particular is compared with "<> 1"
' immediately after, so a stray upper byte there would misreport a good
' status as a failure.
' ---------------------------------------------------------------------------
fn_transact: PROCEDURE
    POKE (FN_DEVICE), mb_dev
    POKE (FN_CMD), mb_cmd
    POKE (FN_NPARAM), mb_nparam
    POKE (FN_TXLEN_LO), #fn_txlen AND 255
    POKE (FN_TXLEN_HI), #fn_txlen / 256

    mb_seq = (PEEK(FN_ACKSEQ) AND 255) + 1
    IF mb_seq = 0 THEN mb_seq = 1
    POKE (FN_SEQ), mb_seq

    #fn_t = 0
    WHILE ((PEEK(FN_ACKSEQ) AND 255) <> mb_seq) AND (#fn_t < 900)
        #fn_t = #fn_t + 1
        WAIT
    WEND

    IF #fn_t >= 900 THEN
        fn_ok = 0
        #mb_err = 0
        RETURN
    END IF

    IF (PEEK(FN_REPLY_CMD) AND 255) <> FUJICMD_ACK THEN
        fn_ok = 0
        #mb_err = (PEEK(FN_ERR) AND 255)
        RETURN
    END IF

    fn_ok = 1
END

' ---------------------------------------------------------------------------
' fn_param: stage transaction parameter #pm_i (0-based), #pm_size bytes
' (1 or 2), value #pm_val, little-endian, into the mailbox's param table.
' ---------------------------------------------------------------------------
DIM pm_i, pm_size
DIM #pm_val
fn_param: PROCEDURE
    POKE (FN_PARAM_SIZE + pm_i), pm_size
    POKE (FN_PARAM_VAL + pm_i * 4), #pm_val AND 255
    IF pm_size > 1 THEN POKE (FN_PARAM_VAL + pm_i * 4 + 1), #pm_val / 256
END

' ---------------------------------------------------------------------------
' fn_putstr: append fn_len ASCII bytes into FN_TX, starting at the current
' #fn_txlen, from the address in #fn_src -- either VARPTR of a ROM DATA
' label (a literal like lit_tables(0)) or a RAM address (a scratch buffer
' like SC_NAME, or even FN_RX). PEEK is uniform across ROM/RAM on the
' CP-1610's unified address space, so one procedure covers both. Advances
' #fn_txlen.
' ---------------------------------------------------------------------------
fn_putstr: PROCEDURE
    FOR fn_i = 0 TO fn_len - 1
        POKE (FN_TX + #fn_txlen + fn_i), PEEK(#fn_src + fn_i) AND 255
    NEXT fn_i
    #fn_txlen = #fn_txlen + fn_len
END

' ---------------------------------------------------------------------------
' fn_strlen: scan the NUL-padded field at #fn_src (max ls_max bytes) and set
' fn_len to the length up to (but not including) the first NUL. Use this
' before fn_putstr whenever the source is a fixed-width padded field (table
' id, player name) -- putstr has no idea where the real string ends, and
' blindly copying the full padded width embeds a literal $00 byte plus
' whatever garbage follows it into the URL, which is sent as-is (the URL's
' length is a byte count, not NUL-terminated, so nothing downstream stops
' at that NUL either -- it corrupts the HTTP request on the wire).
' ---------------------------------------------------------------------------
DIM ls_max
fn_strlen: PROCEDURE
    fn_len = 0
    WHILE (fn_len < ls_max) AND ((PEEK(#fn_src + fn_len) AND 255) <> 0)
        fn_len = fn_len + 1
    WEND
END

' ---------------------------------------------------------------------------
' net_open: open devicespec (ASCII bytes already staged at FN_TX, length in
' #fn_txlen) for HTTP GET. Leaves fn_ok set.
' ---------------------------------------------------------------------------
net_open: PROCEDURE
    mb_dev = NET_DEVICEID
    mb_cmd = NETCMD_OPEN
    mb_nparam = 2
    pm_i = 0 : pm_size = 1 : #pm_val = OPEN_MODE_HTTP_GET_H : GOSUB fn_param
    pm_i = 1 : pm_size = 1 : #pm_val = OPEN_TRANS_NONE : GOSUB fn_param
    GOSUB fn_transact
END

' ---------------------------------------------------------------------------
' net_status: query byte count available. Result in #net_avail; fn_ok as usual.
' ---------------------------------------------------------------------------
DIM #net_avail
' net_err: the 4th byte of the NDeviceStatus reply (nDevStatus_t). 1 =
' SUCCESS. For an HTTP-backed devicespec, the *actual* GET is deferred
' until this first STATUS call (see NetworkProtocolHTTP::status_file()/
' http_transaction() in fujinet-firmware) and its result code lands here
' -- an HTTP error response (e.g. a 400) still has a real, readable body
' (the error page), so `avail` alone can't tell it apart from a good
' response. Checking net_err is what actually can.
DIM #net_err
net_status: PROCEDURE
    mb_dev = NET_DEVICEID
    mb_cmd = NETCMD_STATUS
    mb_nparam = 2
    pm_i = 0 : pm_size = 1 : #pm_val = 0 : GOSUB fn_param
    pm_i = 1 : pm_size = 1 : #pm_val = 0 : GOSUB fn_param
    #fn_txlen = 0
    GOSUB fn_transact
    IF fn_ok THEN
        #net_avail = (PEEK(FN_RX) AND 255) + (PEEK(FN_RX + 1) AND 255) * 256
        #net_err = (PEEK(FN_RX + 3) AND 255)
        IF #net_err <> 1 THEN fn_ok = 0
    ELSE
        #net_avail = 0
    END IF
END

' ---------------------------------------------------------------------------
' net_read: read #net_readlen bytes into FN_RX (reply payload lands there
' directly -- callers PEEK it in place, per the "never buffer in IntyBASIC
' variables" rule). fn_ok as usual.
' ---------------------------------------------------------------------------
DIM #net_readlen
' #net_gotlen: the actual byte count the RP2040/FujiNet peripheral reported
' receiving (RXLEN), captured here because the CLOSE transaction that
' follows in api_call overwrites FN_RXLEN_LO/HI with its own (always 0)
' reply length -- callers need this checked before that happens.
DIM #net_gotlen
net_read: PROCEDURE
    mb_dev = NET_DEVICEID
    mb_cmd = NETCMD_READ
    mb_nparam = 1
    pm_i = 0 : pm_size = 2 : #pm_val = #net_readlen : GOSUB fn_param
    #fn_txlen = 0
    GOSUB fn_transact
    IF fn_ok THEN
        #net_gotlen = (PEEK(FN_RXLEN_LO) AND 255) + (PEEK(FN_RXLEN_HI) AND 255) * 256
    ELSE
        #net_gotlen = 0
    END IF
END

' ---------------------------------------------------------------------------
' net_write: send fn_len bytes already staged at FN_TX out the open
' channel. The byte count rides twice -- as parameter 0 (the command's
' length argument) and as the transaction payload length -- and both come
' from fn_len here. fn_ok as usual. The three games never write to the
' network (their moves are GET query strings), but a TCP/TELNET client
' needs this, so the library carries it.
' ---------------------------------------------------------------------------
net_write: PROCEDURE
    mb_dev = NET_DEVICEID
    mb_cmd = NETCMD_WRITE
    mb_nparam = 1
    pm_i = 0 : pm_size = 2 : #pm_val = fn_len : GOSUB fn_param
    #fn_txlen = fn_len
    GOSUB fn_transact
END

' ---------------------------------------------------------------------------
' net_close
' ---------------------------------------------------------------------------
net_close: PROCEDURE
    mb_dev = NET_DEVICEID
    mb_cmd = NETCMD_CLOSE
    mb_nparam = 0
    #fn_txlen = 0
    GOSUB fn_transact
END

' ---------------------------------------------------------------------------
' api_call: full round trip -- open the URL staged at FN_TX/#fn_txlen,
' check status, read up to #net_readlen bytes (caller sets this to the max
' expected reply size, e.g. 418 for /state, 361 for /tables), close.
' Leaves fn_ok = 1 and the reply in FN_RX on success.
' ---------------------------------------------------------------------------
' ac_i/#ac_prev: loop counter and previous STATUS reading for api_call's
' stabilization poll (see below).
DIM ac_i
DIM #ac_prev
api_call: PROCEDURE
    GOSUB net_open
    IF fn_ok = 0 THEN RETURN

    ' The RP2040/ESP32 can report STATUS as soon as *some* bytes of the
    ' real internet response have arrived, well before the full response
    ' does -- open+status+read all happening within the same poll can
    ' easily race ahead of that. Rather than guess a fixed delay, poll
    ' STATUS repeatedly and treat two consecutive equal (nonzero)
    ' readings as "the download has settled" before committing to a
    ' read length. Bounded to ~20 frames (~0.33s) of polling so a
    ' genuinely stuck connection still falls through to the normal
    ' fn_ok=0/timeout handling instead of hanging here.
    #ac_prev = 0
    FOR ac_i = 0 TO 19
        WAIT
        GOSUB net_status
        IF fn_ok = 0 THEN RETURN
        IF #net_avail > 0 AND #net_avail = #ac_prev THEN EXIT FOR
        #ac_prev = #net_avail
    NEXT ac_i

    IF #net_avail < #net_readlen THEN #net_readlen = #net_avail

    GOSUB net_read
    GOSUB net_close   ' close regardless of read result
END

' ---------------------------------------------------------------------------
' AppKey. The wire struct (fujiDevice.h's `struct appkey`, packed) is 6
' bytes: creator_lo, creator_hi, app, key, mode, reserved. mode: 0=read,
' 1=write. Sending only 5 bytes (omitting reserved) leaves the firmware's
' transaction_get() blocked waiting for a byte that never arrives, which
' reads back as a timeout, not a protocol error -- easy to misdiagnose.
' appkey_open must be followed by appkey_read or appkey_write, then
' appkey_close, mirroring the C client's read_appkey()/write_appkey().
' ---------------------------------------------------------------------------
DIM ak_creator_lo, ak_creator_hi, ak_app, ak_key, ak_mode

appkey_open: PROCEDURE
    mb_dev = FUJI_DEVICEID
    mb_cmd = FUJICMD_OPEN_APPKEY
    mb_nparam = 0
    POKE (FN_TX + 0), ak_creator_lo
    POKE (FN_TX + 1), ak_creator_hi
    POKE (FN_TX + 2), ak_app
    POKE (FN_TX + 3), ak_key
    POKE (FN_TX + 4), ak_mode
    POKE (FN_TX + 5), 0 ' reserved
    #fn_txlen = 6
    GOSUB fn_transact
END

' Reads into SC_ names buffer at address #fn_src (caller sets), up to
' fn_len bytes. Actual byte count returned in fn_len after the call (from
' RXLEN); callers should NUL-terminate at that offset.
' Caller sets #fn_src (destination) and ls_max (destination buffer size,
' including room for the NUL this always writes at fn_len). Clamps to
' ls_max-1 bytes copied -- appkeys can be up to 64 bytes but destinations
' like SC_NAME are much smaller, and always NUL-terminates at fn_len so a
' short stored value doesn't leave trailing bytes undefined for callers
' (like compose_url via fn_strlen) that scan for the terminator.
appkey_read: PROCEDURE
    mb_dev = FUJI_DEVICEID
    mb_cmd = FUJICMD_READ_APPKEY
    mb_nparam = 0
    #fn_txlen = 0
    GOSUB fn_transact
    IF fn_ok THEN
        ' The rs232 transport (rs232Fuji::fujicore_read_app_key, verified
        ' against fujinet-firmware source and a live byte dump) prepends
        ' a 2-byte little-endian length ahead of the actual appkey bytes
        ' -- unlike a network READ, an appkey READ takes no length
        ' parameter, so the firmware makes the reply self-describing
        ' instead. This is specific to appkey reads on this transport;
        ' network reads carry no such prefix. RXLEN (FN_RXLEN_LO/HI)
        ' covers the prefix + data together, so use the embedded prefix
        ' itself as the real data length and skip past it.
        fn_len = (PEEK(FN_RX) AND 255) + (PEEK(FN_RX + 1) AND 255) * 256
        IF fn_len > ls_max - 1 THEN fn_len = ls_max - 1
        FOR fn_i = 0 TO fn_len - 1
            POKE (#fn_src + fn_i), PEEK(FN_RX + 2 + fn_i) AND 255
        NEXT fn_i
        POKE (#fn_src + fn_len), 0
    ELSE
        fn_len = 0
    END IF
END

' Writes fn_len bytes from #fn_src (an SC_ buffer) as the appkey payload.
appkey_write: PROCEDURE
    mb_dev = FUJI_DEVICEID
    mb_cmd = FUJICMD_WRITE_APPKEY
    mb_nparam = 0
    FOR fn_i = 0 TO fn_len - 1
        POKE (FN_TX + fn_i), PEEK(#fn_src + fn_i) AND 255
    NEXT fn_i
    #fn_txlen = fn_len
    GOSUB fn_transact
END

appkey_close: PROCEDURE
    mb_dev = FUJI_DEVICEID
    mb_cmd = FUJICMD_CLOSE_APPKEY
    mb_nparam = 0
    #fn_txlen = 0
    GOSUB fn_transact
END

' ---------------------------------------------------------------------------
' fn_putnum: append the decimal (no leading zeros) representation of pn_val
' (0-999) into FN_TX at the current #fn_txlen. IntyBASIC has no built-in
' itoa; three digits covers every value the game servers take in a URL
' (board positions, score indices, ship placements).
' ---------------------------------------------------------------------------
DIM pn_val, pn_h, pn_t, pn_o, pn_started
fn_putnum: PROCEDURE
    pn_h = pn_val / 100
    pn_t = (pn_val / 10) % 10
    pn_o = pn_val % 10
    pn_started = 0
    IF pn_h > 0 THEN
        POKE (FN_TX + #fn_txlen), pn_h + 48 : #fn_txlen = #fn_txlen + 1
        pn_started = 1
    END IF
    IF pn_t > 0 OR pn_started THEN
        POKE (FN_TX + #fn_txlen), pn_t + 48 : #fn_txlen = #fn_txlen + 1
    END IF
    POKE (FN_TX + #fn_txlen), pn_o + 48 : #fn_txlen = #fn_txlen + 1
END
