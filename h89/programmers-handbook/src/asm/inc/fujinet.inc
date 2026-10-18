;-----------------------------------------------------------------------------
; fujinet.inc -- the H89 FujiNet card and the FujiBus protocol, as names.
;
; The card is an 82C55A at 0D0H (320Q): port A carries the bytes, port C
; the handshake and the 245's direction and enable, port B the eight lamps,
; and 0D3H is the control register. fncmd.inc (made from the firmware) names every device
; and command.
;
; Copyright (C) 2026 Thomas Cherryhomes
; SPDX-License-Identifier: GPL-3.0-or-later
;-----------------------------------------------------------------------------

PORTA           equ     0xD0    ; 82C55A port A: the byte pipe (mode 2)
PORTB           equ     0xD1    ; port B: lamps D3-D10, each lit by a 0
PORTC           equ     0xD2    ; port C: status in, control out
PCTRL           equ     0xD3    ; control word / port C bit set-reset

; port C, read
PC_OBF          equ     0x80    ; PC7 /OBF: 1 = the byte we wrote was taken
PC_ACK          equ     0x40    ; PC6 /ACK (driven by the ESP32)
PC_IBF          equ     0x20    ; PC5 IBF: 1 = a byte from the ESP32 waits
PC_STB          equ     0x10    ; PC4 /STB (driven by the ESP32)
PC_EN           equ     0x04    ; PC2: not connected (the ESP32's EN, once)
PC_OE           equ     0x02    ; PC1: 74LVC245 /OE (0 = on); ESP32 IO21
PC_DIR          equ     0x01    ; PC0: 74LVC245 direction (1 = toward ESP32); IO22

; control register values
MODE2           equ     0xC0    ; port A mode 2; PC0-PC2 outputs, all 0
DIR_TO_H89      equ     0x00    ; bit set/reset: PC0 = 0
DIR_TO_ESP      equ     0x01    ; PC0 = 1
OE_ON           equ     0x02    ; PC1 = 0: the 245 enabled

; Left in port B by fujinet-lib, FN.DVD and FNDISK when they set up the
; card, which they skip while it is there and PC2 reads 1. card_on doesn't
; use it. A reset makes port B an input that reads FF, and any mode word
; clears it or makes it an input.
SETUP_MARK      equ     0xA5

; SLIP framing
SLIP_END        equ     0xC0
SLIP_ESC        equ     0xDB
SLIP_ESC_END    equ     0xDC
SLIP_ESC_ESC    equ     0xDD

; FujiBus field descriptors: what follows the 6-byte header
F_NONE          equ     0       ; no fields
F_A1            equ     1       ; one byte
F_A1_A2         equ     2       ; two bytes
F_A1_A2_A3      equ     3       ; three bytes
F_A1_A2_A3_A4   equ     4       ; four bytes
F_B12           equ     5       ; one 16-bit word
F_B12_B34       equ     6       ; two 16-bit words
F_C1234         equ     7       ; one 32-bit long

; replies
ACK             equ     0x06
NAK             equ     0x15

; fn_call results (in A)
FN_OK           equ     0       ; ACK
FN_NAK          equ     1       ; NAK
FN_TIMEOUT      equ     2       ; no answer in time
FN_BAD          equ     3       ; bad length, checksum or device

; the network units' STATUS reply
NS_AVAIL        equ     0       ; word: bytes waiting
NS_CONN         equ     2       ; byte: 1 = connected
NS_ERR          equ     3       ; byte: last error (1 = OK, 136 = EOF)

INCLUDE "fncmd.inc"

; A request block, read by fn_call, is two lines: what to send, then where
; the payload is and where the reply goes.
;   FNREQ  device, command, descriptor, aux1, aux2, aux3, aux4
;   FNBUF  payload, payload length, reply buffer, reply buffer size
;
; A program changes a block in place before a call (a length, a buffer):
RQ_DEV          equ     0       ; device
RQ_CMD          equ     1       ; command
RQ_DESC         equ     2       ; field descriptor
RQ_AUX1         equ     3       ; aux1-aux4: the fields (a word at aux1-aux2,
RQ_AUX2         equ     4       ;   a long at aux1-aux4, low byte first)
RQ_AUX3         equ     5
RQ_AUX4         equ     6
RQ_PAY          equ     7       ; payload address
RQ_PLEN         equ     9       ; payload length
RQ_REP          equ     11      ; reply buffer
RQ_RMAX         equ     13      ; reply buffer size
macro FNREQ dev, cmd, desc, a1, a2, a3, a4
        defb    dev, cmd, desc, a1, a2, a3, a4
endm
macro FNBUF pay, plen, rep, rmax
        defw    pay, plen, rep, rmax
endm
