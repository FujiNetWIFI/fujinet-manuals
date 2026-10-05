/**
 * @brief   5-card-stud
 * @author  Eric Carr, Thomas Cherryhomes, (insert names here)
 * @license gpl v. 3
 * @verbose main
 */

#ifdef _CMOC_VERSION_
#include "coco/coco_bool.h"
#else
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#endif /* _CMOC_VERSION_ */

#include "platform-specific/graphics.h"
#include "platform-specific/util.h"
#include "platform-specific/input.h"
#include "misc.h"
#include "platform-specific/network.h"
#include "platform-specific/appkey.h"
#include "platform-specific/sound.h"

#include "stateclient.h"
#include "gamelogic.h"
#include "screens.h"

// Store default server endpoint in case lobby did not set app key
char serverEndpoint[50] = "https://th.carr-designs.com/";
//char serverEndpoint[50] = "http://127.0.0.1:8080/"; // local dev; "N: for apple, but not C64"

// Empty at boot so the table selection screen is always shown; the room list
// comes from the server's /tables endpoint
char query[QUERY_LEN] = "";
char playerName[12] = "";

//GameState state;
// On the ColecoVision this is a macro for the cartridge's reply window, not an
// object -- see src/misc.h.
#ifndef BUILD_COLECO
ClientState clientState;
#endif


// State helper vars
#ifdef __WATCOMC__
int inputKey;
#else
char inputKey;
#endif
unsigned char prevPlayerCount, prevRound, currentCard, cardIndex, cursorX, cursorY, waitCount, wasViewing;
signed char inputDirX, inputDirY;
uint16_t prevPot, maxJifs;
bool noAnim, doAnim, finalFlip, inputTrigger;

unsigned char playerX[8], playerY[8], moveLoc[5];
signed char playerBetX[8], playerBetY[8], playerDir[8];

// Common local scope temp variables
unsigned char h, i, j, k, x, y, xx;
char tempBuffer[TEMP_BUFFER_LEN];

char prefs[4];

char *hand, *requestedMove;


#ifdef _CMOC_VERSION_
int main(void)
#else
void main(void)
#endif /* _CMOC_VERSION_ */
{ 
    // uint8_t x, result;
    // x=0;
    // x=x+2;

  //unsigned char i;while (1) {if (kbhit()) {inputKey = cgetc(); printf("\nKEY: %u", inputKey);}for(i=0;i<10;i++){pause(2);printf(".");}}
  loadPrefs();
  initGraphics();
  initSound();

// Checking MSX C compiler bug
//    x=10;
//    result=(x>5)+10;
//    itoa(result,tempBuffer,10);

//    cputs(tempBuffer);
//    cgetc();
  
#ifdef USE_PLATFORM_SPECIFIC_INPUT
  initPlatformKeyboardInput();
#endif 

  showWelcomeScreen();
  showTableSelectionScreen();

  // Main in-game loop
  while (true) {

    // Get latest state and draw on screen, then prompt player for move if their turn
    if (getStateFromServer()) {
#if defined(BUILD_COLECO) || defined(BUILD_NES)
      /*
        The ColecoVision has no back buffer (1K of RAM), so showGameScreen()
        repaints the table straight to VRAM. Every server poll would otherwise
        redraw the whole table even when nothing changed -- invisible on a real
        display (identical bytes rewritten in place) but a waste, and it makes a
        redraw always be in flight, which tears on capture. Skip the repaint
        when the fetched state is byte-for-byte what is already on screen.

        state is the reply window here (see src/misc.h), valid until the next
        fuji_* call -- which is exactly now, right after the fetch. A one-word
        sum is enough: a rare collision just defers a repaint to the next
        differing poll. requestPlayerMove() still runs, so our own turn (where
        the countdown does change the state every second) always draws.

        The NES draws through cc65's vblank ring buffer, a few dozen tiles a
        frame, so an unchanged repaint there costs a backlog the next real
        change has to queue behind. Its state is an ordinary object in WRAM.
      */
      {
        static unsigned int lastDrawnSum = 1; // != any first real sum
        unsigned int sum = 0;
        unsigned int n;                        // Game is 429 bytes: not a char
        unsigned char *sp = &clientState.firstByte;
        for (n = 0; n < sizeof(Game); n++)
          sum += sp[n] ^ (unsigned char)n;     // position-weighted vs byte swaps
        if (sum != lastDrawnSum) {
          lastDrawnSum = sum;
          showGameScreen();
        }
      }
#else
      showGameScreen();
#endif
      requestPlayerMove();
    } else {
       // Wait a bit to avoid hammering the server if getting bad responses
       pause(30);
    }

    // Handle other key presses
    readCommonInput();

    switch(inputKey) {
      case KEY_ESCAPE: // Esc
      case KEY_ESCAPE_ALT: // Esc Alt
        showInGameMenuScreen();
        break;
    }


  }
#ifdef _CMOC_VERSION_
  return 0;
#endif
}
