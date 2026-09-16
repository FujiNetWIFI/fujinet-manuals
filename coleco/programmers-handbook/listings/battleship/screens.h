/*******************************************************************
 * 
 * Do NOT include standard library headers (e.g. conio, std*). 
 * Instead, add to standard_lib.h, which gets included in misc.h
 * 
 ******************************************************************/

#ifndef SCREENS_H
#define SCREENS_H

extern uint8_t inputField[20];

/// @brief Save screen to memory for quick recall - returns true if successful
bool saveScreen();

/// @brief Restore screen - returns true if successful
bool restoreScreen();

/// @brief Clear screen
void resetScreen();

/// @brief Shows information about the game
void showHelpScreen();

/// @brief Action called in Welcome Screen to check if a server name is stored in an app key
void welcomeActionVerifyServerDetails();

/// @brief Action called in Welcome Screen to verify player has a name
void welcomeActionVerifyPlayerName();

/// @brief Shows the Welcome Screen with Logo. Asks player's name
void showWelcomeScreen();

/// @brief Shows a screen to select a table to join
void showTableSelectionScreen();

/// @brief Shows main game play screen (table and cards)
void showGameScreen();

/// @brief shows in-game menu
void showInGameMenuScreen();

/// @brief Allow the player to modify their name
void showPlayerNameScreen();

/// @brief Draw the title
void drawLogo();

#endif /*SCREENS_H*/

