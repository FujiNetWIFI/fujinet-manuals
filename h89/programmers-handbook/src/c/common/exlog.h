/*
 * exlog.h -- the C exercisers' markers and reports (mark.inc, in C).
 *
 *   ex_mark(key)   prints "@ex key" and sends the key to device 0FH, which
 *                  does not exist: the firmware answers NAK, but the frame
 *                  stands in the bus log, so the exchanges after it belong
 *                  to that example.
 *   ex_show(ok)    prints ACK or NAK after a fujinet-lib call.
 *   ex_done()      prints "@done".
 *
 * Copyright (C) 2026 Thomas Cherryhomes
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#ifndef EXLOG_H
#define EXLOG_H

#include <stdbool.h>
#include <stdint.h>

void ex_mark(const char *key);
void ex_show(bool ok);
void ex_showb(bool ok, const void *buf, uint16_t len);   /* and some bytes */
void ex_done(void);

#endif
