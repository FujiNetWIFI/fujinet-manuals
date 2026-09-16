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
char serverEndpoint[50] = "https://5card.carr-designs.com/";
//char serverEndpoint[50] = "http://127.0.0.1:8080/"; // "N: for apple, but not C64"

char query[QUERY_LEN] = "";//&player=ERICAPL2";
char playerName[12] = ""; // "eric";
//char playerName[12] = "ericmsx";

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
unsigned char playerCount, prevPlayerCount, validMoveCount, prevRound, tableCount, currentCard, cardIndex, xOffset, fullFirst, cursorX, cursorY, waitCount, wasViewing;
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
      showGameScreen();
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
