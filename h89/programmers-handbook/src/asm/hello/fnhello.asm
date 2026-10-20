;-----------------------------------------------------------------------------
; FNHELLO -- first contact. Sets the FujiNet card up, asks it for its adapter
; configuration, and prints the network it has joined, its name, its address
; and its firmware version. One source, two systems:
;   z88dk-z80asm -b -DHDOS -I=../inc fnhello.asm   ->  FNHELLO.ABS (HDOS)
;   z88dk-z80asm -b -DCPM  -I=../inc fnhello.asm   ->  FNHELLO.COM (CP/M)
;
; Copyright (C) 2026 Thomas Cherryhomes
; SPDX-License-Identifier: GPL-3.0-or-later
;-----------------------------------------------------------------------------
INCLUDE "os.inc"
INCLUDE "fujinet.inc"

main:
        ld      hl,t_banner
        call    print
        call    card_on                 ; set the card up
        call    card_present
        jr      nz,no_card
;@ex hello.config
        ld      hl,rq_config            ; ask for the adapter configuration
        call    fn_call
        jr      nz,failed
;@end
        ld      hl,t_ssid
        call    print
        ld      hl,cfg_ssid
        call    print
        ld      hl,t_host
        call    print
        ld      hl,cfg_host
        call    print
        ld      hl,t_ip
        call    print
        ld      hl,cfg_ip
        call    pip
        ld      hl,t_ver
        call    print
        ld      hl,cfg_ver
        call    print
        jp      crlf

no_card:
        ld      hl,t_nocard
        jp      print
failed:
        ld      hl,t_failed
        jp      print

;@ex hello.config
rq_config:
        FNREQ   DEV_FUJINET, FUJI_GET_ADAPTERCONFIG, F_NONE, 0,0,0,0
        FNBUF   0, 0, cfg, 140          ; no payload; 140 bytes back to cfg
;@end

; the reply: 140 bytes
cfg:
cfg_ssid:       defs    33              ; the WiFi network's name
cfg_host:       defs    64              ; the FujiNet's own name
cfg_ip:         defs    4               ; its address,
cfg_gw:         defs    4               ;   the router's,
cfg_mask:       defs    4               ;   the netmask
cfg_dns:        defs    4               ;   and the name server
cfg_mac:        defs    6
cfg_bssid:      defs    6
cfg_ver:        defs    15              ; the firmware version

t_banner:       defm    "FNHELLO - first contact with the FujiNet"
                defb    13, 10, 0
t_ssid:         defm    "Network:  "
                defb    0
t_host:         defb    13, 10
                defm    "Name:     "
                defb    0
t_ip:           defb    13, 10
                defm    "Address:  "
                defb    0
t_ver:          defb    13, 10
                defm    "Firmware: "
                defb    0
t_nocard:       defm    "No FujiNet card at 0D0H."
                defb    13, 10, 0
t_failed:       defm    "The FujiNet did not answer."
                defb    13, 10, 0

INCLUDE "card.inc"
INCLUDE "fujibus.inc"
INCLUDE "con.inc"
INCLUDE "tail.inc"
