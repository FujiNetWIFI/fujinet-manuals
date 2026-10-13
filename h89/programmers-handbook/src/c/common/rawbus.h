/*
 * rawbus.h -- FujiBus frames out, bare bytes in: for the modem (50H).
 *
 * The modem does not answer in frames. STATUS's two bytes, STREAM's
 * nine and all it hears from the far end come as bare bytes, and an
 * ACK or a NAK comes as nothing at all. fujinet-lib's fuji_bus_call()
 * would wait 15 seconds for a frame that never comes, so a program
 * that talks to the modem sends with raw_frame() and reads with
 * raw_get().
 *
 *   raw_frame(dev, cmd, fields, a1, a2, a3, a4, data, len)
 *              sends one request, as fuji_bus_call() would (the same
 *              arguments, FUJI_FIELD_* in fields), and does not wait
 *   raw_put(data, len)
 *              sends bytes outside any frame: the modem takes them as
 *              if typed (an AT command, or data when online). They
 *              must not hold a C0H, which would start a frame.
 *   raw_get(buf, size)
 *              takes the bytes that come back: waits up to 2 s for the
 *              first, then stops after 200 ms with none, or when buf
 *              is full. Returns how many it took (0: none came).
 *
 * Both senders first drop any byte still waiting from an earlier
 * reply (fujinet-lib leaves a frame's closing C0H behind). The card
 * must be running: call fujinet-lib first, or run FNON.
 *
 * Copyright (C) 2026 Thomas Cherryhomes
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#ifndef RAWBUS_H
#define RAWBUS_H

#include <stdint.h>

void raw_frame(uint8_t dev, uint8_t cmd, uint8_t fields,
               uint8_t a1, uint8_t a2, uint8_t a3, uint8_t a4,
               const void *data, uint16_t len);
void raw_put(const void *data, uint16_t len);
uint16_t raw_get(void *buf, uint16_t size);

#endif
