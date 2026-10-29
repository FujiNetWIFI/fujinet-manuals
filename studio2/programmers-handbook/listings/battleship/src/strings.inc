; strings.inc -- every screen's text. 16 cells a row; the panel's are four.

s_title:    DB  " ", SYM_RIGHT, " BATTLESHIP ", SYM_LEFT, 0
s_nocart:   DB  "NO FUJINET CART", 0
s_chkname:  DB  "CHECKING NAME", 0
s_yourname: DB  "YOUR NAME:", 0
s_saving:   DB  "SAVING NAME", 0
s_edleg1:   DB  "2468 MOVE 5 TYPE", 0
s_edleg2:   DB  "1 DEL     3 DONE", 0
s_choose:   DB  "CHOOSE A TABLE", 0
s_finding:  DB  "FINDING TABLES", 0
s_lbleg:    DB  "1-8 JOIN  0 MENU", 0
s_notables: DB  "NO TABLES", 0
s_neterr:   DB  "NET ERROR ", 0
s_retry:    DB  "0 MENU  5 RETRY", 0
s_menu:     DB  "MENU", 0
s_m1:       DB  "1 BACK", 0
s_m2leave:  DB  "2 LEAVE TABLE", 0
s_m2ref:    DB  "2 REFRESH", 0
s_m3:       DB  "3 CHANGE NAME", 0
s_m4:       DB  "4 QUIT TO CONFIG", 0
s_leaving:  DB  "LEAVING TABLE", 0
s_toconfig: DB  "TO CONFIG...", 0
s_cfgfail:  DB  "CONFIG FAILED", 0
s_joining:  DB  "JOINING TABLE", 0
s_sending:  DB  "SENDING FLEET", 0

; the waiting room
s_ready:    DB  "READY", 0
s_lobrdy:   DB  "5 READY   0 MENU", 0
s_lobunr:   DB  "5 UNREADY 0 MENU", 0

; placement
s_place:    DB  "PLACE YOUR FLEET", 0
s_plc1:     DB  "2468 MOVE 1 TURN", 0
s_plc2:     DB  "5 KEEP   3 ROLL", 0
s_plc3:     DB  "0 MENU", 0
s_of5:      DB  "/5 ", 0
s_ships:    DB  "CARRIER", 0, "BATTLESHIP", 0, "CRUISER", 0
            DB  "SUBMARINE", 0, "DESTROYER", 0
s_placed:   DB  "FLEET PLACED", 0
s_watching: DB  "WATCHING", 0
s_waitp1:   DB  "WAITING FOR THE", 0
s_waitp2:   DB  "OTHERS TO PLACE", 0
s_ok4:      DB  " OK ", 0
s_dots4:    DB  " ...", 0

; the boards: names, and the panel's four-cell words
s_you5:     DB  "YOU  ", 0
s_net:      DB  "NET ", 0
s_blank4:   DB  "    ", 0
s_your:     DB  "YOUR", 0
s_turn:     DB  "TURN", 0
s_you4:     DB  "YOU ", 0
s_win:      DB  "WIN!", 0
s_wins:     DB  "WINS", 0
s_game:     DB  "GAME", 0
s_over:     DB  "OVER", 0
s_sunk:     DB  "SUNK", 0
s_view:     DB  "VIEW", 0
s_only:     DB  "ONLY", 0
s_wait:     DB  "WAIT", 0
s_hit:      DB  "HIT ", 0
s_miss:     DB  "MISS", 0
s_k2468:    DB  "2468", 0
s_aim:      DB  " AIM", 0
s_k5:       DB  "   5", 0
s_fire:     DB  "FIRE", 0
s_k0:       DB  "   0", 0
s_mnu:      DB  "MENU", 0
