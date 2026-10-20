/**
 * @brief   Fuji Battleship
 * @author  Eric Carr, Thomas Cherryhomes, (insert names here)
 * @license gpl v. 3
 * @verbose main
 */

/*******************************************************************
 * 
 * Do NOT include standard library headers (e.g. conio, std*). 
 * Instead, add to standard_lib.h, which gets included in misc.h
 * 
 ******************************************************************/

#include "misc.h"
#include "stateclient.h"
#include "gamelogic.h"
#include "screens.h"


// Store default public server endpoint in case lobby did not set app key
char serverEndpoint[50] = "https://battleship.carr-designs.com/";
//char serverEndpoint[50] = "http://127.0.0.1:8080/";

// For local dev testing, instead of changing the endpoint above,
// set 1st byte in the e41c0500 appkey to 0xff, which will cause the below endpoint to be used
const char localServer[] = "http://127.0.0.1:8080/";

// Zero-initialized by the C runtime (BSS) - an explicit = "" would cost the
// z88dk ROM a stored DATA image of the zeros
char query[QUERY_LEN]; //"?table=dev7";//&player=ERICAPL2";
char playerName[12];

// On the ColecoVision this is a macro for the FujiNet cartridge's reply
// window, not an object -- see src/misc.h.
#ifndef BUILD_COLECO
ClientState clientState;
#endif
GameState state;
PrefsStruct prefs;

// Common local scope temp variables
char tempBuffer[TEMP_BUFFER_LEN];
const uint8_t shipSize[5] = {5, 4, 3, 3, 2}; // Standard ship sizes

// extern void toneFinder();

void main(void)
{
    uint8_t failedApiCalls = 0;
        char ch;
    // Testing
    // toneFinder();
    // printf("Press keys\n");while(1) {while (!kbhit());failedApiCalls = cgetc();printf("%d 0x%x\n", failedApiCalls, failedApiCalls);} // Read Key
    
    loadPrefs();
    initGraphics();
    initSound();

    // soundCursor();
    // cgetc();

    // soundSelect();
    // cgetc();

    // soundJoinGame();
    // cgetc();

    // soundMyTurn();
    // cgetc();

    // soundGameDone();
    // cgetc();

    // soundTick();
    // cgetc();

    // soundPlaceShip();
    // cgetc();

    // soundAttack(); // jak stuknięcie, nie wybuch, za wysoki
    // cgetc();

    // soundInvalid();
    // cgetc();

    // soundHit(); // dwa szumy, za wysokie
    // cgetc();

    showWelcomeScreen();
    showTableSelectionScreen();

    // Main event loop - process state from server and input from keyboard/joystick
    state.apiCallWait = 0;

    while (true)
    {

        // Poll the server every so often.
        if (!state.apiCallWait--)
        {

            // Housekeeping - allows platform specific housekeeping, like stopping Attract/screensaver mode in Atari
            housekeeping();

            // Poll the server
            switch (getStateFromServer())
            {
            case STATE_UPDATE_ERROR:
                // ERROR - Wait a bit to avoid hammering the server if getting bad responses
                // Wait max 4 seconds (since 4*60=240 fits in a single byte)
                if (failedApiCalls < 4)
                {
                    failedApiCalls++;
                }
                state.apiCallWait = 60 * failedApiCalls;

                // After consequitive failures, let the player know we are experiencing technical difficulties
                if (failedApiCalls > 1)
                {
                    drawConnectionIcon(true);
                    pause(30);
                    drawConnectionIcon(false);
                    pause(30);
                    drawConnectionIcon(true);
                }
                break;

            case STATE_UPDATE_CHANGE:

                // Clear connection failure message
                if (failedApiCalls > 1)
                {
                    drawConnectionIcon(false);
                }
                failedApiCalls = 0;
                processStateChange();

                // Poll again in a bit
                state.apiCallWait = 59;
                break;
            }
        }

        processInput();
    }
}
