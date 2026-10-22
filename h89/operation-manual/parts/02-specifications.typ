#import "../lib.typ": *

#chapter(2, "Specifications", gap: 0.55in)

#[
#set text(size: 9.2pt)
#let wt = 1.75in
#let dl(a, b) = block(above: 0.36em, below: 0.36em,
  grid(columns: (0.3in, wt, 1fr), column-gutter: 0.4em, [],
    box(width: 100%, a + box(width: 1fr, repeat(gap: 0.1em)[.])), b))
#let sh(t) = block(sticky: true, above: 1.15em, below: 0.5em, text(font: f-head, weight: "bold", size: 9.2pt, upper(t)))

#sh[The Card]
#dl[Bus][Heath H89/H88 accessory bus. Uses one pair of accessory sockets on the CPU logic circuit board: P504 with P510, or P505 with P511.]
#dl[I/O ports][320 through 323 octal (D0--D3 hexadecimal), selected with the PORT SEL jumper (J1) and JP1.]
#dl[Other PORT SEL positions][330, 340 and 170 octal. Not used by the present software.]
#dl[Interface][82C55A programmable peripheral interface. Port A in Mode 2 (bidirectional, strobed) carries the data; port C carries control and status.]
#dl[Interrupts][None. J3 is left open.]
#dl[Level shifting][Two 74LVC245 bus transceivers: one for the data, one for the control lines.]
#dl[Reset][The H89’s RESET resets the 82C55A only. The FujiNet runs from power-on and keeps running through a reset.]
#dl[Lamps][Eight LEDs (D3--D10) on the 82C55A’s port B, for programs to use.]

#sh[The FujiNet]
#dl[Processor][Espressif ESP32, two cores at 240 MHz, on an ESP32-DevKitC-VE module.]
#dl[Memory][8 megabytes of flash (firmware and settings) and 8 megabytes of PSRAM.]
#dl[Wireless][IEEE 802.11 b/g/n, 2.4 GHz band only. Open, WPA and WPA2 personal networks.]
#dl[Storage][microSD card socket. Cards formatted FAT32; 32 gigabytes or smaller recommended.]
#dl[USB][On the ESP32 module. The only way to update the firmware; also the diagnostic output.]

#sh[Devices the FujiNet Provides]
#dl[Disk drives][8 drive slots.]
#dl[Hosts][8 host slots: the microSD card, TNFS servers, and web (HTTP, HTTPS), FTP, SMB and NFS servers.]
#dl[Network channels][8 (N1 through N8): TCP, UDP, HTTP and HTTPS, TNFS, FTP, SMB, NFS, SSH, TELNET and more.]
#dl[Printer][1. Pages are collected on the FujiNet's web page.]
#dl[Modem][1, Hayes compatible.]
#dl[Clock][Network time.]

#sh[FujiNet Drives]
#dl[Disk image format][H8D: 102,400 bytes, 40 tracks of 10 sectors of 256 bytes. This is the H-17-1 single-sided diskette, sector for sector.]
#dl[Under HDOS][FN.DVD device driver. Units FN0: through FN7:. Catalog, read, write, mount and dismount.]
#dl[Under CP/M][FNDISK.COM. Drives D: through K:, or eight drives starting at a letter you choose. 92K and 64 directory entries per drive.]
#dl[Starting the system][From the H89’s own floppy drive. The FujiNet drives are added once HDOS or CP/M is running.]

#sh[Software]
#dl[Operating systems][HDOS 2.0 or 3.0. Heath/Zenith CP/M 2.2.04 (a 62K system).]
#dl[FujiNet programs][CONFIG (CONFIG.ABS for HDOS, CONFIG.COM for CP/M), FN.DVD and FNDISK.COM.]
#dl[Monitors][The acceptance test runs on MTR-88, MTR-89 and MTR-90.]

#sh[Memory Required]
#dl[HDOS][48K; 64K to run CONFIG after the FujiNet drives have been used.]
#dl[CP/M][64K, to run a 62K CP/M system.]

#sh[Power and Size]
#dl[Power][From the H89’s bus: +5 volts, and through D2 to the ESP32 module, whose regulator makes 3.3 volts. No separate power supply.]
#dl[Current][#text(fill: ink.lighten(40%))[(to be measured)]]
#dl[Dimensions][#text(fill: ink.lighten(40%))[(to be measured)]]
]
