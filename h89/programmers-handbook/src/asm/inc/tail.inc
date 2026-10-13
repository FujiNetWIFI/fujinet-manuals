;-----------------------------------------------------------------------------
; tail.inc -- the library's data, the CP/M stack, and prog_end. Include it
; LAST, after your own code and data.
;
; Copyright (C) 2026 Thomas Cherryhomes
; SPDX-License-Identifier: GPL-3.0-or-later
;-----------------------------------------------------------------------------
os_fcnt:        defw    0               ; bytes in os_fbuf
os_fptr:        defw    0               ; next byte to read from os_fbuf
os_feof:        defb    0               ; 1 = the file has ended
os_rcount:      defw    0
IFDEF HDOS
os_argp:        defw    0               ; SP at entry: the command line
os_nul:         defb    0               ; "no arguments"
os_consave:     defs    5               ; the console mode bytes at entry
os_hdefault:    defm    "SY0"           ; the default device, no extension
                defb    0, 0, 0, 0
os_fbuf:        defs    256             ; one HDOS sector
ELSE
os_fcb:         defs    36
os_fbuf:        defs    128             ; one CP/M record
                defs    256             ; our stack
os_stack:
ENDIF
prog_end:
