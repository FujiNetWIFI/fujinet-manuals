' gfx.bas -- card GRAM bitmaps and draw routines.
'
' Card faces and the print_card/foreground_color rendering logic are ported
' verbatim from carlsson's intv/5card-test-display.bas mock. cardtop holds
' 14 GRAM images (index 0 = card back/blank, 1-13 = ranks 2..A), cardbot
' holds 7 (index 0 = blank, 1-4 = suit bottoms for DIAMONDS/HEARTS/CLUBS/
' SPADES, plus 2 more finishing the set) -- see print_card for the exact
' index math. DEFINE loads these into GRAM slots 0-13 (screen codes 256-269)
' and 14-20 (screen codes 270-276) respectively.

    CONST DIAMONDS = 1
    CONST HEARTS = 2
    CONST CLUBS = 3
    CONST SPADES = 4

' ---------------------------------------------------------------------------
' gfx_init: load both GRAM sets. Must run once at startup, each DEFINE
' followed by a WAIT (GRAM loads take effect on the next video frame; a
' second DEFINE in the same frame would silently overwrite the first).
' ---------------------------------------------------------------------------
gfx_init: PROCEDURE
    DEFINE 0, 14, cardtop : WAIT
    DEFINE 14, 7, cardbot : WAIT
END

' ---------------------------------------------------------------------------
' print_card: draw one card at screen cell p (top half) / p+20 (bottom
' half). Inputs: p (top-left cell), card (1-13, 0 = hidden/back), suit
' (1-4, DIAMONDS/HEARTS/CLUBS/SPADES).
' ---------------------------------------------------------------------------
print_card: PROCEDURE
    #col = BG_WHITE
    GOSUB foreground_color
    #BACKTAB(p) = #col + (card + 256) * 8
    #BACKTAB(p + 20) = #col + (suit + 270) * 8
END

' ---------------------------------------------------------------------------
' foreground_color: pick #col's foreground bits for the card being drawn
' (red for D/H, black for C/S, blue for a hidden card), and adjusts `card`
' from its wire value (2-14) down to the 1-13 GRAM index.
' ---------------------------------------------------------------------------
foreground_color: PROCEDURE
    IF card > 0 THEN
        card = card - 1 ' compensate for suit runs 23456789TJQKA
        IF suit = DIAMONDS OR suit = HEARTS THEN
            #col = #col + FG_RED
        ELSE
            #col = #col + FG_BLACK
        END IF
    ELSE
        #col = #col + FG_BLUE
    END IF
END

cardtop:
	BITMAP "oooooooo"
    BITMAP "oo..o..o"
	BITMAP "o.o..o.."
	BITMAP "o..o..o."
	BITMAP "oo..o..o"
	BITMAP "o.o..o.."
	BITMAP "o..o..o."
	BITMAP "oo..o..o"

	BITMAP "oooooooo"
    BITMAP "o......."
	BITMAP "o.oooo.."
	BITMAP "o.....o."
	BITMAP "o..ooo.."
	BITMAP "o.o....."
	BITMAP "o.ooooo."
	BITMAP "o......."
	
	BITMAP "oooooooo"
    BITMAP "o......."
	BITMAP "o.oooo.."
	BITMAP "o.....o."
	BITMAP "o..ooo.."
	BITMAP "o.....o."
	BITMAP "o.oooo.."
	BITMAP "o......."

	BITMAP "oooooooo"
    BITMAP "o......."
	BITMAP "o.o...o."
	BITMAP "o.o...o."
	BITMAP "o.ooooo."
	BITMAP "o.....o."
	BITMAP "o.....o."
	BITMAP "o......."

	BITMAP "oooooooo"
    BITMAP "o......."
	BITMAP "o.ooooo."
	BITMAP "o.o....."
	BITMAP "o.oooo.."
	BITMAP "o.....o."
	BITMAP "o.oooo.."
	BITMAP "o......."

	BITMAP "oooooooo"
    BITMAP "o......."
	BITMAP "o...oo.."
	BITMAP "o..o...."
	BITMAP "o.oooo.."
	BITMAP "o.o...o."
	BITMAP "o..ooo.."
	BITMAP "o......."

	BITMAP "oooooooo"
    BITMAP "o......."
	BITMAP "o.ooooo."
	BITMAP "o.....o."
	BITMAP "o....o.."
	BITMAP "o...o..."
	BITMAP "o...o..."
	BITMAP "o......."

	BITMAP "oooooooo"
    BITMAP "o......."
	BITMAP "o..ooo.."
	BITMAP "o.o...o."
	BITMAP "o..ooo.."
	BITMAP "o.o...o."
	BITMAP "o..ooo.."
	BITMAP "o......."

	BITMAP "oooooooo"
    BITMAP "o......."
	BITMAP "o..ooo.."
	BITMAP "o.o...o."
	BITMAP "o..oooo."
	BITMAP "o.....o."
	BITMAP "o..ooo.."
	BITMAP "o......."

	BITMAP "oooooooo"
    BITMAP "o......."
	BITMAP "o.o..o.."
	BITMAP "o.o.o.o."
	BITMAP "o.o.o.o."
	BITMAP "o.o.o.o."
	BITMAP "o.o..o.."
	BITMAP "o......."

	BITMAP "oooooooo"
    BITMAP "o......."
	BITMAP "o.....o."
	BITMAP "o.....o."
	BITMAP "o.....o."
	BITMAP "o.o...o."
	BITMAP "o..ooo.."
	BITMAP "o......."

	BITMAP "oooooooo"
    BITMAP "o......."
	BITMAP "o..ooo.."
	BITMAP "o.o...o."
	BITMAP "o.o.o.o."
	BITMAP "o.o..o.."
	BITMAP "o..oo.o."
    BITMAP "o......."

	BITMAP "oooooooo"
    BITMAP "o......."
	BITMAP "o.o...o."
	BITMAP "o.o..o.."
	BITMAP "o.ooo..."
	BITMAP "o.o..o.."
	BITMAP "o.o...o."
    BITMAP "o......."	

	BITMAP "oooooooo"
	BITMAP "o......."
	BITMAP "o..ooo.."
	BITMAP "o.o...o."
	BITMAP "o.ooooo."
	BITMAP "o.o...o."
	BITMAP "o.o...o."
	BITMAP "o......."	

cardbot:
	BITMAP "o.o..o.."
    BITMAP "o..o..o."
	BITMAP "oo..o..o"
	BITMAP "o.o..o.."
	BITMAP "o..o..o."
	BITMAP "oo..o..o"
	BITMAP "o.o..o.."
	BITMAP "oooooooo"

	BITMAP "o......."
    BITMAP "o...o..."
	BITMAP "o..ooo.."
	BITMAP "o.ooooo."
	BITMAP "o..ooo.."
	BITMAP "o...o..."
	BITMAP "o......."
	BITMAP "oooooooo"

	BITMAP "o......."
    BITMAP "o..o.o.."
	BITMAP "o.ooooo."
	BITMAP "o.ooooo."
	BITMAP "o..ooo.."
	BITMAP "o...o..."
	BITMAP "o......."
	BITMAP "oooooooo"

	BITMAP "o......."
    BITMAP "o..ooo.."
	BITMAP "o.o.o.o."
	BITMAP "o.ooooo."
	BITMAP "o.o.o.o."
	BITMAP "o...o..."
	BITMAP "o......."
	BITMAP "oooooooo"

	BITMAP "o......."
    BITMAP "o..ooo.."
	BITMAP "o.ooooo."
	BITMAP "o.ooooo."
	BITMAP "o...o..."
	BITMAP "o...o..."
	BITMAP "o......."
	BITMAP "oooooooo"

	BITMAP "o......."
	BITMAP "o......."
	BITMAP "o......."
	BITMAP "o......."
	BITMAP "o......."
	BITMAP "o......."
	BITMAP "o......."
	BITMAP "o......."

	BITMAP ".ooooo.."
	BITMAP "ooo.ooo."
	BITMAP "ooo.ooo."
	BITMAP "ooo...o."
	BITMAP "ooooooo."
	BITMAP "ooooooo."
	BITMAP ".ooooo.."
	BITMAP "........"

