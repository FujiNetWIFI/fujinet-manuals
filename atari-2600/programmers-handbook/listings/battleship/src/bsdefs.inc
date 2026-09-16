; bsdefs.inc -- what every bank of the Battleship client agrees on.
;
; EQUATES ONLY, included before the ORG next to fujinet.inc.
;
; This console has 128 bytes of RAM and the stack mirrors into the top of
; them. What that buys, once you accept it, is a design where the CARTRIDGE
; holds the state: the server's reply sits in the cartridge's 512-byte window
; and is read from there in place; the four boards are composed by the
; cartridge into playfield tables the kernel streams straight into the TIA;
; the player name and the table id live in the cartridge's path buffers; the
; URL is streamed a character at a time into the cartridge's TX page. What
; the console holds is a cursor, a phase, and a handful of counters.

; ---------------- the banks ----------------
; An image is (N+1) x 2048 bytes -- N banks then the fixed half -- and MAME's
; cart slot accepts only N in {1,3,7,15}. Seven banks, and all seven used.
BANKLOB EQU     0               ; the cold start and the table list
BANKGAM EQU     1               ; the game: the kernel, the cursor, a shot
BANKNET EQU     2               ; one request, with the picture up, and back
BANKMNU EQU     3               ; the RESET menu: resume, help, leave
BANKNAM EQU     4               ; the keyboard and the shared username
BANKPLC EQU     5               ; placing the five ships
BANKCMP EQU     6               ; compose the game screen, in one vblank
NBANKS  EQU     7

; The trampoline, at a fixed address in the fixed tail because the banks are
; assembled separately. bscore.inc ORGs it there.
BSGOTO  EQU     FNTAIL

; A bank switch is a JUMP, never a call: the store that switches is the last
; instruction fetched from the old bank, so there is no return address to
; come back to. "Where to carry on" is therefore DATA, in BSENT.
ENCOLD  EQU     0               ; bank 0: power-on
ENLOBBY EQU     1               ; bank 0: the table list is in the window
ENGCOLD EQU     2               ; bank 1, then 6: a table was just joined
ENGAME  EQU     3               ; bank 6: back from a poll: recompose
ENFETCH EQU     4               ; bank 2: /state, or the staged request
ENTABLE EQU     5               ; bank 2: /tables, then the lobby
ENMENU  EQU     6               ; bank 3: the RESET menu
ENLEAVE EQU     7               ; bank 2: /leave, /tables, then the lobby
ENNAME  EQU     8               ; bank 4: the keyboard
ENGRUN  EQU     9               ; bank 1: composed: finish the frame, run
ENPLACE EQU     10              ; bank 5: the server wants our ships
ENPLFAIL EQU    11              ; bank 5: the /place was refused: again
ENGNEXT EQU     12              ; bank 1: composed, between frames: run
ENRESUME EQU    13              ; bank 6: the menu closed, mid-frame
ENTEXT  EQU     14              ; bank 6: the text pass, mid-frame
ENGRUND EQU     15              ; bank 1: as ENGRUN, after a text bank: DINIT

; ---------------- requests ----------------
; Every one of them returns the same state blob, so a staged move REPLACES
; the /state poll: its reply is the next state. Request 0 is /tables, so a
; cleared "pending request" cell can never mean /state.
RQTABLE EQU     0
RQSTATE EQU     1
RQREADY EQU     2               ; a bare /ready TOGGLES
RQPLACE EQU     3               ; /place/P,P,P,P,P
RQATTCK EQU     4               ; /attack/P
RQLEAVE EQU     5

; The cartridge's path buffers: where the two strings this client needs live.
PBTABLE EQU     FP_SEL0         ; the joined table's id
PBNAME  EQU     FP_SEL1         ; the player name
PBEDIT  EQU     FP_SEL3         ; what the keyboard is typing into

; ---------------- zero page ----------------
; $80-$BF, and the stack must stay above $C0. $80-$8C is the transport's, as
; is $A8/$A9 (fujinet.inc); the rest is ours. $8D-$A7 is the ROM swap stub's
; landing ground in the firmware's own clients -- this program never swaps,
; so it is ours.
PAD3    EQU     $81             ; the display kernels' 3-cycle pad target
SAVSP   EQU     $82             ; the stack pointer, parked across a text row
BSIDX   EQU     $84             ; a render loop's index. Its own cell: BSTMP
                                ;   is not safe across a call
BSTMP   EQU     $85             ; scratch; any routine you call may clobber it
INRPT   EQU     $8D             ; INREPT's auto-repeat countdown
BSDGT   EQU     $8E             ; BSDEC's digit and leading-zero latch
BSREQ   EQU     $8F             ; the request in flight (RQ*)
BSTRIES EQU     $90             ; the settle loop's bound
BSDLY   EQU     $91             ; its inter-poll delay, in memory because
                                ;   NFRAME clobbers X and Y
BSINP   EQU     $92             ; THIS FRAME'S input mask, in a cell of its own
BSAVL0  EQU     $92             ; NET_STATUS bytes waiting -- only ever live
BSAVL1  EQU     $93             ;   inside a transaction, when no input runs
BSPRV0  EQU     $94             ; the previous reading, for the settle loop
BSPRV1  EQU     $95
BSNUM0  EQU     $94             ; BSDEC's 16-bit number: never live with the
BSNUM1  EQU     $95             ;   settle loop, which composes nothing
BSRXL0  EQU     $96             ; the READ's reply length, captured at once
BSRXL1  EQU     $97
BSMIN0  EQU     $98             ; the length this request will settle for
BSMIN1  EQU     $99
BSERR   EQU     $9A             ; the last failure
BSSTEP  EQU     $9B             ; where it happened: 1 open 2 status 3 read
                                ;   4 validate
BSROW   EQU     $9C             ; text kernel: the row being drawn
ROWEND  EQU     $9C             ; board kernel: one past the last cell row
BSLINE  EQU     $9D             ; text kernel: ink lines left in the row
BSBAR   EQU     $9E             ; text kernel: the red bar's row, or $FF
BSTMP2  EQU     $9E             ; board banks: a second scratch cell
SNDPTR  EQU     $9F             ; the sound script step, 0 = silent
SNDCNT  EQU     $A0             ; frames left on that step
BSPOLL  EQU     $A1             ; frames until the next /state
BSFRAME EQU     $A2             ; free-running frame counter
BSENT   EQU     $A3             ; EN*: what the bank being entered should do
BSPCNT  EQU     $A4             ; playerCount from the last reply
BSSTAT  EQU     $A5             ; game status from the last reply
BSMYST  EQU     $A6             ; YOUR player status
BSACT   EQU     $A7             ; the active player, $FF for nobody; at game
                                ;   over the winner
BSSEL   EQU     $AA             ; list cursor / menu item / keyboard cell
BSCNT   EQU     $AB             ; rows on the table list -- LOBBY BANK ONLY
BSSHIP  EQU     $AB             ; the ship being placed -- PLACE BANK ONLY
BSCURX  EQU     $AC             ; the board cursor, 0-9
BSCURY  EQU     $AD
BSPRVAC EQU     $AE             ; previous activePlayer, for the turn edge
BSPRVST EQU     $AF             ; previous status, for the result edge...
BSPRVLP EQU     $B0             ; ...paired with the previous lastAttackPos
BSCLK   EQU     $B1             ; the local move clock, seconds
BSTICK  EQU     $B2             ; frames until it ticks
BSLIVE  EQU     $B3             ; the live enemy SLOTS, as a bit mask
BSMODE  EQU     $B4             ; 0: two boards, square cells; 1: quadrants
BSDIR   EQU     $B5             ; 0 across, 1 down -- PLACE BANK ONLY
BSMHELP EQU     $B5             ; the help page is up -- MENU BANK ONLY
BSNLEN  EQU     $B6             ; characters typed -- NAME BANK ONLY
BSCLASS EQU     $B6             ; the screen class (CL*) -- GAME BANK ONLY
SHIPS   EQU     $B7             ; the five staged placements, $B7-$BB, each
                                ;   pos + 100*dir: PLACE and NET banks only
BSREDRW EQU     $BC             ; the composer's flags, one pass a frame:
                                ;   bit 0 everything, bit 1 the names, bit 2
                                ;   the whole name rows, bit 3 the lower rows,
                                ;   bit 4 the fleet strips, bit 5 the AUX
                                ;   plane, bit 7 a pass is due at all
BSREQ2  EQU     $BD             ; the request staged for the next fetch, or
                                ;   RQSTATE
BSERR2  EQU     $BE             ; APICALL's result, parked across a switch
BSBLINK EQU     $BF             ; the placement blink

; ---------------- the wire format ----------------
; ?bin=1&v=2, little-endian. Header, 38 bytes, always present.
GOPLCNT EQU     0               ; playerCount, max 4
GOPRMPT EQU     1               ; prompt[33]
GOSTAT  EQU     34              ; ST*
GOPLST  EQU     35              ; YOUR player status
GOACTPL EQU     36              ; int8: $FF nobody, 0 = your turn; at game
                                ;   over (v=2) the WINNER's index
GOMVTIM EQU     37              ; seconds left, 0-250
GHDRLEN EQU     38

; Lobby body (status == STLOBBY).
GLSRVNM EQU     38              ; serverName[21]
GLPLYRS EQU     59              ; playerCount x LBSTRID
LBSTRID EQU     10
LBNAME  EQU     0               ; name[9]
LBSTAT  EQU     9               ; 3 = ready

; In-play body (status != STLOBBY).
GILASTP EQU     38              ; lastAttackPos, 0-99
GIMYSHP EQU     39              ; myShips[10]: [0-4] yours, [5-9] the winner's
GIPLYRS EQU     49              ; playerCount x PLSTRID, ONLY once the
                                ;   gamefields exist (status >= STSTART)
PLSTRID EQU     115
PLNAME  EQU     0               ; name[9]
PLSTAT  EQU     9
PLFIELD EQU     10              ; gamefield[100]: y*10+x, 0 sea 1 hit 2 miss
PLSHIPS EQU     110             ; shipsLeft[5]: 1 afloat, 0 sunk

; During STPLACE the player records are name+status ONLY -- 10 bytes, not
; 115. Never index a gamefield in the place phase.
PPSTRID EQU     10

; /tables: a count byte, then 36-byte records starting at offset 1.
TBSTRID EQU     36
TBID    EQU     0               ; table id[9]
TBNAME  EQU     9               ; name[21]
TBPLYRS EQU     30              ; players[6], the literal "cur / max"

GMAXLEN EQU     509             ; GIPLYRS + 4*PLSTRID -- fits slice 0 whole,
                                ;   which is why the reply window is 512
GMINLEN EQU     GHDRLEN
TMAXLEN EQU     361
MAXTBL  EQU     8               ; rows the list can show

; Game status.
STLOBBY EQU     0
STPLACE EQU     1
STSTART EQU     10
STMISS  EQU     11
STHIT   EQU     12
STSUNK  EQU     13
STOVER  EQU     99

; Player status.
PSPLAY  EQU     0
PSDEFT  EQU     1               ; defeated
PSVIEW  EQU     2               ; spectator
PSREADY EQU     3
PSPLACE EQU     10

; The screen class every sibling collapses the status to. A change of class
; -- or of seat count -- forces a full clear, because opaque overdraw cannot
; repair content that shrank.
CLLOBBY EQU     0
CLPLACE EQU     1
CLPLAY  EQU     2
CLOVER  EQU     3

BRDDIM  EQU     10
BRDCELL EQU     100
NSHIPS  EQU     5
MAXPLYR EQU     4
NAMEMAX EQU     8               ; the wire field is nine with the NUL

; ---------------- colours (NTSC) ----------------
CBLACK  EQU     $00
CWHITE  EQU     $0E
CGREY   EQU     $06
CDIM    EQU     $04
CRED    EQU     $34             ; the text kernel's bar
CGREEN  EQU     $C4
CWATER  EQU     $84             ; the sea
CHIT    EQU     $36             ; a hit: red (hue 4 is pink on an NTSC set)
CMISS   EQU     $0E             ; a miss: white
CAUX    EQU     $1A             ; hulls and the cursor: gold
CLABEL  EQU     $0E             ; text over the boards
CSTATUS EQU     $1C             ; the status row

; ---------------- the game screen ----------------
; Text rows the board banks own. Rows 5-14 are the playfield tables and are
; NEVER rendered in board mode; rows 15-20 are the lower text area of the
; two-player layout.
RSTAT   EQU     0               ; the status line
RLABA   EQU     1               ; names over board pair A
RLABB   EQU     2               ; names over board pair B
RFLTA   EQU     3               ; the fleet strip under each name row, three
RFLTB   EQU     4               ;   ink lines, quadrant layout only
RLOW0   EQU     15              ; the two-player layout's lower rows: 15-20
NLOWROW EQU     6

; Slots: pairrow*2 + half. Player i's slot is a mode-dependent table in the
; game bank; these are the two layouts it holds.
SLTL    EQU     0
SLTR    EQU     1
SLBL    EQU     2
SLBR    EQU     3

; Timing, in frames.
POLLFRM EQU     90              ; between /state polls in play, ~1.5s
LOBFRM  EQU     120             ; in the lobby, ~2s
OVERFRM EQU     180             ; at game over, ~3s: the server resets
FAILFRM EQU     150             ; after a failed poll
TURNFRM EQU     4               ; right after our own shot: the reply is it
BLINKFR EQU     16              ; the pending ship's blink

; ---------------- the text screens ----------------
; The 21-row text kernel (disptext.inc) is the 5 Card Stud one: a per-row
; background table BSBGT of 22 entries and a red bar on row BSBAR. Every text
; screen here is white ink, so the seat-colour pick is gone from its seam
; line.
RSEAT0  EQU     1
RBAR0   EQU     17
PFEDGE  EQU     $F0             ; the playfield border on the text screens
