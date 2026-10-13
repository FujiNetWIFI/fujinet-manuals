;	HI.COM - a CP/M program for the book's demonstration disk
;	(run from a FujiNet drive: D:HI)
	ORG	0100H
	MVI	C,9		;BDOS PRINT STRING
	LXI	D,MSG
	CALL	5
	RET
MSG:	DB	"Hello from a FujiNet drive on the H89!",13,10,"$"
