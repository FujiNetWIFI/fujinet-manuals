 rem acfg.bas -- First Contact in 7800basic: one GET_ADAPTERCONFIG_EXTENDED,
 rem and the SSID, IP address and firmware version on the screen.
 incbasic fujinet.bas

 displaymode 320A
 set zoneheight 8
 incgraphic fujifont.png 320A
 characterset fujifont
 alphachars ASCII
 BACKGRND = $00
 P0C2 = $0F

 rem two of the reply's fields, by offset: firmware 125, IP text 140
 dim FN_R_FW = $087D
 dim FN_R_IP = $088C
 rem console RAM for the strings, where MARIA can read them
 dim ssid = $2200
 dim ipaddr = $2220
 dim fwver = $2230
 dim ix = var0

 clearscreen
 plotchars 'FUJINET 7800BASIC FIRST CONTACT' 0 8 1
 gosub fn_chk
 if fn_res <> FN_OK then goto failed

 fn_dev = FN_FUJI : fn_cmd = $C4 : fn_npr = 0
 gosub fn_beg
 gosub fn_go
 if fn_res <> FN_OK then goto failed

 for ix = 0 to 31 : ssid[ix] = FN_REPLY[ix] : next
 for ix = 0 to 15 : ipaddr[ix] = FN_R_IP[ix] : next
 for ix = 0 to 14 : fwver[ix] = FN_R_FW[ix] : next
 plotchars 'SSID' 0 8 4
 plotchars ssid 0 40 4 24
 plotchars 'IP' 0 8 6
 plotchars ipaddr 0 40 6 16
 plotchars 'FW' 0 8 8
 plotchars fwver 0 40 8 15
 goto main

failed
 fn_val = fn_res
 gosub fn_hex
 plotchars 'FAILED: E' 0 8 22
 plotchars fn_hexbuf 0 44 22 2

main
 drawscreen
 goto main

 incbasic fujilib.bas
