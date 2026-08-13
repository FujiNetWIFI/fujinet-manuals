' sound.bas -- sound effects, adapted from fujinet-battleship/intv/sound.bas.
' The transport primitive (play_tone) and the UI-generic effects are kept
' verbatim; the game-specific effects are replaced with Fujitzee's own set
' (roll/hold/score/fujitzee in place of Battleship's place/attack/hit/sink).
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
'  500Hz->224  600Hz->187   700Hz->160  800Hz->140
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

' sound_myturn: it's your turn to roll (double beep, 430,430 Hz).
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

' sound_cursor: cursor moved one position (300 Hz).
sound_cursor: PROCEDURE
    #snd_val = 373 : snd_gate = 2 : snd_post = 0 : GOSUB play_tone
END

' sound_tick: countdown clock tick during your turn (short 300 Hz click).
sound_tick: PROCEDURE
    #snd_val = 373 : snd_gate = 1 : snd_post = 0 : GOSUB play_tone
END

' sound_hold: a die's re-roll flag was toggled (short click, 600 Hz).
sound_hold: PROCEDURE
    #snd_val = 187 : snd_gate = 2 : snd_post = 0 : GOSUB play_tone
END

' sound_roll: the dice were rolled (rattling triplet: 700,600,700 Hz).
sound_roll: PROCEDURE
    #snd_val = 160 : snd_gate = 2 : snd_post = 1 : GOSUB play_tone
    #snd_val = 187 : snd_gate = 2 : snd_post = 1 : GOSUB play_tone
    #snd_val = 160 : snd_gate = 2 : snd_post = 4 : GOSUB play_tone
END

' sound_score: a category was scored (rising chirp, 350,500 Hz).
sound_score: PROCEDURE
    #snd_val = 320 : snd_gate = 3 : snd_post = 0 : GOSUB play_tone
    #snd_val = 224 : snd_gate = 4 : snd_post = 2 : GOSUB play_tone
END

' sound_fujitzee: five of a kind scored (5-tone rising fanfare, brighter and
' longer than sound_gamedone -- the rare, celebrated roll).
sound_fujitzee: PROCEDURE
    #snd_val = 373 : snd_gate = 6 : snd_post = 0 : GOSUB play_tone
    #snd_val = 320 : snd_gate = 6 : snd_post = 0 : GOSUB play_tone
    #snd_val = 285 : snd_gate = 6 : snd_post = 0 : GOSUB play_tone
    #snd_val = 260 : snd_gate = 6 : snd_post = 0 : GOSUB play_tone
    #snd_val = 224 : snd_gate = 16 : snd_post = 0 : GOSUB play_tone
END

' sound_invalid: rejected input -- all-zero re-roll mask, out-of-turn action,
' unselectable category (single low buzz, 100 Hz, held).
sound_invalid: PROCEDURE
    #snd_val = 1119 : snd_gate = 10 : snd_post = 5 : GOSUB play_tone
END
