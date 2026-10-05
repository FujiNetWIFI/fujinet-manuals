#include "fujinet-bus-nes.h"
#include "fujinet-commands.h"


uint16_t fuji_bus_call_rlen;

void __fastcall__ fn_tx(uint8_t b)
{
  FN_TXPAGE = b;
}

/* A register write is one store: the address picks the register, the data
   is the value. The cartridge decodes it on the falling edge of M2. */
void fn_regwr(uint8_t reg, uint8_t val)
{
  FN_REGSEL[reg] = val;
}

/*
  Launch the transaction and wait for the cartridge to publish a reply.

  The sequence number comes from the cartridge's own ACKSEQ + 1, never from a
  variable of ours. A console RESET restarts the program and re-zeroes
  everything it owns but does NOT reset the cartridge, so a locally derived
  sequence replays a number the cart has already acknowledged: no request is
  sent, and the stale reply still sitting in the window looks like success.

  The wait loop is deliberately dumb. The cart's own transaction budget is 5s,
  and 60s for MOUNT_IMAGE, so we have to outlast that for a real timeout to
  surface as the cart's error code rather than ours. ~12 s at 1.79 MHz.
*/
uint8_t fn_commit(void)
{
  uint8_t want = (uint8_t) (FN_ACKSEQ + 1);
  uint16_t outer, inner;


  if (want == 0)
    want = 1;                   /* 0 means "never used" */
  fn_regwr(FNR_SEQ, want);

  for (outer = 0; outer < 4000u; outer++) {
    for (inner = 0; inner < 250u; inner++) {
      if (FN_ACKSEQ == want)
        return FN_ERRCODE;
    }
  }

  return FN_EWAIT;
}

/*
  The FUJI_FIELD_* descriptor maps straight onto the mailbox's parameter
  stream. fuji_field_numbytes() gives the total aux bytes and
  fuji_field_numfields() how many parameters they make up, so their quotient is
  each parameter's size -- always 1, 2 or 4, which is exactly what the stream
  accepts. The DEVCALL_* macros already split wider values low byte first on
  this target (see NATIVE_SPLIT_U16 in fujinet-endian.h), so the aux bytes
  stream through in argument order with no reordering.

  Fixed arguments rather than varargs, the same shape as the ColecoVision
  target, so the two cartridge ports' C code is interchangeable.

  `buf` is the outgoing payload when FUJI_FIELD_DATA is set and the reply
  destination when FUJI_FIELD_REPLY is; no call sets both.
*/
bool fuji_bus_call(uint8_t device, uint8_t fuji_cmd, uint8_t fields,
                   uint8_t aux1, uint8_t aux2, uint8_t aux3, uint8_t aux4,
                   const void *buf, size_t buf_length)
{
  uint8_t aux[4];
  uint8_t numbytes, numfields, size;
  uint8_t idx, field, i;
  uint16_t rlen;


  fuji_bus_call_rlen = 0;

  aux[0] = aux1;
  aux[1] = aux2;
  aux[2] = aux3;
  aux[3] = aux4;

  numbytes = fuji_field_numbytes(fields);
  numfields = fuji_field_numfields(fields);
  size = numfields ? (uint8_t) (numbytes / numfields) : 0;

  /* Each parameter costs its size byte plus its value bytes. Refuse rather
     than truncate: a short SET_DEVICE_FULLPATH is rejected on the ESP32 side
     anyway, and silently dropping the tail would be far harder to see. */
  if ((fields & FUJI_FIELD_DATA)
      && (uint16_t) (numfields + numbytes) + buf_length > FN_TX_MAX)
    return false;

  fn_regwr(FNR_DATA_RST, 0);    /* rewind the TX write pointer */
  fn_regwr(FNR_DEVICE, device);
  fn_regwr(FNR_CMD, fuji_cmd);
  fn_regwr(FNR_NPARAM, 0);

  idx = 0;
  for (field = 0; field < numfields; field++) {
    fn_tx(size);
    for (i = 0; i < size; i++)
      fn_tx(aux[idx++]);
  }
  if (numfields)
    fn_regwr(FNR_NPARAM, numfields);

  if (fields & FUJI_FIELD_DATA) {
    const uint8_t *data = (const uint8_t *) buf;
    size_t n = buf_length;

    while (n--)
      fn_tx(*data++);
  }

  if (fn_commit() != FN_OK)
    return false;

  if (FN_REPLYCMD != FUJICMD_ACK)
    return false;

  rlen = (uint16_t) FN_RXLEN_LO | ((uint16_t) FN_RXLEN_HI << 8);
  if (rlen > FN_REPLY_MAX)
    rlen = FN_REPLY_MAX;

  if (fields & FUJI_FIELD_REPLY) {
    uint8_t *reply = (uint8_t *) buf;
    volatile uint8_t *src = FN_REPLY;
    uint16_t n;

    if (rlen > buf_length)
      rlen = buf_length;
    for (n = rlen; n; n--)
      *reply++ = *src++;
  }

  fuji_bus_call_rlen = rlen;

  return true;
}
