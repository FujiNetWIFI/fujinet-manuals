' sound.bas -- sound effects, modeled on the C clients' platform-specific
' sound.c implementations (src/msx/sound.c and src/plus4/sound.c gave the
' clearest Hz-based reference; other platforms use raw PSG period/noise
' values that amount to the same tones). Every effect there is built from
' plain square-wave tones (SOUND channel 0-2, no envelope/noise), which is
' exactly IntyBASIC's SOUND statement, so this is a direct transcription
' rather than a reinterpretation.
'
' All effects play on PSG channel 0 -- the game is turn-based and effects
' are triggered at distinct, non-overlapping UI events, so there's no need
' for polyphony (and SOUND's channel argument must be a compile-time
' constant anyway, which would rule out a single generic multi-channel
' helper).
'
' SOUND's frequency argument is a 12-bit PSG divisor, computed as
' round(3579545/32/hz) for NTSC (the manual's documented formula;
' IntyBASIC exposes no runtime PAL/NTSC query outside the MUSIC/PLAY
' engine, and this project has only ever been built/tested NTSC). These
' are precomputed here rather than divided at runtime: 3579545/32 alone
' is ~111861, which doesn't fit IntyBASIC's 16-bit variables (max 65535),
' so it only works as a compile-time-folded literal division (a fixed Hz
' baked into the expression) -- not as CONST-divided-by-a-runtime-variable,
' which is what a single reusable "play Hz X" helper would need. Since
' every effect here uses fixed, known-in-advance frequencies anyway,
' precomputing sidesteps the overflow entirely and is cheaper besides.
'   50Hz->2237  60Hz->1864  70Hz->1598  80Hz->1398  100Hz->1119
'  150Hz->746  300Hz->373  311Hz->360  330Hz->339  340Hz->329
'  350Hz->320  392Hz->285  415Hz->270  430Hz->260  500Hz->224
    CONST SND_VOL = 12

    DIM #snd_val, snd_gate, snd_post, snd_i

' ---------------------------------------------------------------------------
' play_tone: one square-wave note on channel 0. #snd_val = precomputed PSG
' divisor (see table above), snd_gate = frames the tone sounds, snd_post =
' frames of silence after (both "vblank" counts, taken directly from the
' reference implementations since they're already frame units at ~60Hz).
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

' sound_myturn: it's your turn to move (double beep, 430,430 Hz).
sound_myturn: PROCEDURE
    #snd_val = 260 : snd_gate = 4 : snd_post = 2 : GOSUB play_tone
    #snd_val = 260 : snd_gate = 4 : snd_post = 2 : GOSUB play_tone
END

' sound_gamedone: round/showdown result just landed (4-tone rising
' fanfare: 311,330,392,415 Hz).
sound_gamedone: PROCEDURE
    #snd_val = 360 : snd_gate = 10 : snd_post = 0 : GOSUB play_tone
    #snd_val = 339 : snd_gate = 20 : snd_post = 0 : GOSUB play_tone
    #snd_val = 285 : snd_gate = 10 : snd_post = 0 : GOSUB play_tone
    #snd_val = 270 : snd_gate = 20 : snd_post = 0 : GOSUB play_tone
END

' sound_deal: a new hand's cards have arrived (150 Hz click). The C clients
' click once per card as each is dealt; we don't track per-card deal
' state (cards just render as soon as they're in the fetched hand), so
' this plays once per new deal instead of per card.
sound_deal: PROCEDURE
    #snd_val = 746 : snd_gate = 1 : snd_post = 5 : GOSUB play_tone
END

' sound_player_join: another player sits down mid-game (5-tone rising
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

' sound_select: a move or table selection was confirmed (2-tone rising
' chirp: 300,350 Hz).
sound_select: PROCEDURE
    #snd_val = 373 : snd_gate = 3 : snd_post = 1 : GOSUB play_tone
    #snd_val = 320 : snd_gate = 3 : snd_post = 0 : GOSUB play_tone
END

' sound_cursor: menu/move cursor moved one position (300 Hz).
sound_cursor: PROCEDURE
    #snd_val = 373 : snd_gate = 2 : snd_post = 0 : GOSUB play_tone
END

' sound_chip: pot value increased (a bet/call/raise landed, 50 Hz). The C
' clients play one ascending tone per player as chips sweep into the pot
' during a dedicated collection animation; we don't animate that (pot just
' updates), so this plays their first-player tone once per pot increase
' as a stand-in "chip clink."
sound_chip: PROCEDURE
    #snd_val = 2237 : snd_gate = 2 : snd_post = 2 : GOSUB play_tone
END
