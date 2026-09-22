#ifndef FNBUS_H
#define FNBUS_H

#include <cmoc.h>
#include "dwport.h"

#define FN_OK 1

void fn_wait(void);
byte fn_error(void);
byte fn_send(byte *frame, int len);
byte fn_response(byte *buf, int len);

#endif /* FNBUS_H */
