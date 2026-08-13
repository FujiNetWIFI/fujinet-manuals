' sound.bas -- sound effects, adapted from fujinet-5cardstud/intv/sound.bas.
' The transport primitive (play_tone) and several UI-generic effects are
' kept verbatim; the game-specific effects are replaced with Battleship's
' own set, matching the C clients' platform-specific/sound.h event names
' (soundCursor/Select/MyTurn/JoinGame/... plus Attack/Hit/Sink/Miss/Invalid
' which 5 Card Stud has no equivalent of).
'
' All effects play on PSG channel 0 -- turn-based game, non-overlapping UI
' events, no need for polyphony (and SOUND's channel argument must be a
' compile-time constant anyway, which rules out a generic multi-channel
' helper).
'
' SOUND's frequency argument is a 12-bit PSG divisor, computed as
' round(3579545/32/hz) for NTSC. These are precomputed rather than divided
' at runtime: 3579545/32 alone is ~111861, which overflows IntyBASIC's
' 16-bit variables (max 65535), so it only works as a compile-time-folded
' literal division -- not as CONST-divided-by-a-runtime-variable. Every
' effect here uses a fixed, known-in-advance frequency, so precomputing
' sidesteps the overflow entirely.
'   50Hz->2237  60Hz->1864  70Hz->1598  80Hz->1398  100Hz->1119
'  150Hz->746  200Hz->559   300Hz->373  311Hz->360   330Hz->339
'  340Hz->329  350Hz->320   392Hz->285  415Hz->270    430Hz->260
'  500Hz->224  800Hz->140
    CONST SND_VOL = 12

    DIM #snd_val, snd_gate, snd_post, snd_i

' ---------------------------------------------------------------------------
' play_tone: one square-wave note on channel 0. #snd_val = precomputed PSG
' divisor (see table above), snd_gate = frames the tone sounds, snd_post =
' frames of silence after.
' ---------------------------------------------------------------------------
play_tone: PROCEDURE
    SOUND 0, #snd_val, SND_VOL
    FOR snd_i = 1 TO snd_gate
        WAIT
    NEXT snd_i
    SOUND 0, 0, 0
    FOR snd_i = 1 TO snd_post
        WAIT
    NEXT snd_i
END

' sound_join: sit down at a table (3-tone rising figure: 430,340,500 Hz).
sound_join: PROCEDURE
    #snd_val = 260 : snd_gate = 5 : snd_post = 8 : GOSUB play_tone
    #snd_val = 329 : snd_gate = 5 : snd_post = 0 : GOSUB play_tone
    #snd_val = 224 : snd_gate = 5 : snd_post = 0 : GOSUB play_tone
END

' sound_myturn: it's your turn to fire (double beep, 430,430 Hz).
sound_myturn: PROCEDURE
    #snd_val = 260 : snd_gate = 4 : snd_post = 2 : GOSUB play_tone
    #snd_val = 260 : snd_gate = 4 : snd_post = 2 : GOSUB play_tone
END

' sound_gamedone: game over, win fanfare (4-tone rising: 311,330,392,415 Hz).
sound_gamedone: PROCEDURE
    #snd_val = 360 : snd_gate = 10 : snd_post = 0 : GOSUB play_tone
    #snd_val = 339 : snd_gate = 20 : snd_post = 0 : GOSUB play_tone
    #snd_val = 285 : snd_gate = 10 : snd_post = 0 : GOSUB play_tone
    #snd_val = 270 : snd_gate = 20 : snd_post = 0 : GOSUB play_tone
END

' sound_player_join: another player sits down mid-lobby (5-tone rising
' sweep: 50,60,70,80 Hz).
sound_player_join: PROCEDURE
    #snd_val = 2237 : snd_gate = 2 : snd_post = 15 : GOSUB play_tone
    #snd_val = 1864 : snd_gate = 2 : snd_post = 15 : GOSUB play_tone
    #snd_val = 1598 : snd_gate = 2 : snd_post = 15 : GOSUB play_tone
    #snd_val = 1398 : snd_gate = 2 : snd_post = 15 : GOSUB play_tone
END

' sound_player_left: a player leaves mid-game (falling sweep, mirror of join).
sound_player_left: PROCEDURE
    #snd_val = 1398 : snd_gate = 2 : snd_post = 15 : GOSUB play_tone
    #snd_val = 1598 : snd_gate = 2 : snd_post = 15 : GOSUB play_tone
    #snd_val = 1864 : snd_gate = 2 : snd_post = 15 : GOSUB play_tone
    #snd_val = 2237 : snd_gate = 2 : snd_post = 15 : GOSUB play_tone
END

' sound_select: a menu/table/ready choice was confirmed (2-tone rising
' chirp: 300,350 Hz).
sound_select: PROCEDURE
    #snd_val = 373 : snd_gate = 3 : snd_post = 1 : GOSUB play_tone
    #snd_val = 320 : snd_gate = 3 : snd_post = 0 : GOSUB play_tone
END

' sound_cursor: cursor/ship moved one position (300 Hz).
sound_cursor: PROCEDURE
    #snd_val = 373 : snd_gate = 2 : snd_post = 0 : GOSUB play_tone
END

' sound_tick: countdown clock tick during targeting (short 300 Hz click).
sound_tick: PROCEDURE
    #snd_val = 373 : snd_gate = 1 : snd_post = 0 : GOSUB play_tone
END

' sound_place_ship: a ship was confirmed placed (short rising chirp,
' 300,500 Hz).
sound_place_ship: PROCEDURE
    #snd_val = 373 : snd_gate = 2 : snd_post = 0 : GOSUB play_tone
    #snd_val = 224 : snd_gate = 3 : snd_post = 2 : GOSUB play_tone
END

' sound_attack: a shot was fired (falling swoosh, 500,300 Hz).
sound_attack: PROCEDURE
    #snd_val = 224 : snd_gate = 3 : snd_post = 0 : GOSUB play_tone
    #snd_val = 373 : snd_gate = 3 : snd_post = 0 : GOSUB play_tone
END

' sound_miss: shot landed in water (single splash-like click, 800 Hz).
sound_miss: PROCEDURE
    #snd_val = 140 : snd_gate = 4 : snd_post = 4 : GOSUB play_tone
END

' sound_hit: shot struck a ship (low descending buzz, 200,100 Hz).
sound_hit: PROCEDURE
    #snd_val = 559 : snd_gate = 4 : snd_post = 0 : GOSUB play_tone
    #snd_val = 1119 : snd_gate = 6 : snd_post = 4 : GOSUB play_tone
END

' sound_sink: a ship was sunk (4-tone falling fanfare, mirror of
' sound_gamedone: 415,392,330,311 Hz).
sound_sink: PROCEDURE
    #snd_val = 270 : snd_gate = 10 : snd_post = 0 : GOSUB play_tone
    #snd_val = 285 : snd_gate = 10 : snd_post = 0 : GOSUB play_tone
    #snd_val = 339 : snd_gate = 10 : snd_post = 0 : GOSUB play_tone
    #snd_val = 360 : snd_gate = 15 : snd_post = 0 : GOSUB play_tone
END

' sound_invalid: rejected input -- ship placement collision, spent attack
' cell, out-of-turn action (single low buzz, 100 Hz, held).
sound_invalid: PROCEDURE
    #snd_val = 1119 : snd_gate = 10 : snd_post = 5 : GOSUB play_tone
END
