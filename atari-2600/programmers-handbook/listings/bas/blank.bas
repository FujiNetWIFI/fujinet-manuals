 rem blank.bas -- spike S1: the smallest batari Basic FujiNet client.
 rem A 2K program with nothing in it but a frame loop. What it proves is the
 rem layout: bB's 2K image is bank 0, the appended fixed half carries the
 rem claim and the vectors, and the cartridge honours the claim.
 set romsize 2k
 COLUBK = $84
main
 drawscreen
 goto main
