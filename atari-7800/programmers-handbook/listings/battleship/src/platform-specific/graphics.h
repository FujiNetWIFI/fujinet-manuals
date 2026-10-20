/*
 Platform specific graphics commands
*/

#ifndef GRAPHICS_H
#define GRAPHICS_H
#include "../standard_lib.h"

// Call to clear the screen, passing true to preserve borders
void resetScreen();

uint8_t cycleNextColor();

/// @brief Draw a string of text, default color
void drawText(uint8_t x, uint8_t y, const char *s);

/// @brief Draw a string of text. Draw alternate color for CAPITALIZED lettes.
void drawTextAlt(uint8_t x, uint8_t y, const char *s);

/// @brief Draw a single character - used for icons
void drawIcon(uint8_t x, uint8_t y, uint8_t icon);

/// @brief Draw (or erase) a ship at given size and position.
/// @param quadrant player index (0-3) for positioning purpose
/// @param size ship size (2-5)
/// @param pos ship position 0-99, add 100 for vertical
/// @param hide 0=show, 1=hide
void drawShip(uint8_t quadrant, uint8_t size, uint8_t pos, bool hide);

/// @brief Draw a ship either in whole or destroyed, in the legend (side trays)
/// @param player player index (0-3) for positioning purpose
/// @param index ship index (0-4)
/// @param size ship size (2-5)
/// @param status ship status: 0=destroyed, 1=intact
void drawLegendShip(uint8_t player, uint8_t index, uint8_t size, uint8_t status);

/// @brief Draw the player's name by their gamefield
/// @param player player index (0-3) for positioning purpose
/// @param name player name
/// @param active whether this is the currently active player
void drawPlayerName(uint8_t player, const char *name, bool active);

/// @brief Draw end game message
/// @param message
void drawEndgameMessage(const char *message);

/// @brief Draw the gamefield for a given player/quadrant
/// @param quadrant player index (0-3). Starting bottom left and moving clockwise
/// @param field pointer to 100 byte gamefield array from server
void drawGamefield(uint8_t quadrant, uint8_t *field);

/// @brief Draw/update a single cell (attackPos) for the the specified gamefield
/// @param quadrant [0-3] player index
/// @param gamefield pointer to 100 byte gamefield array from server
/// @param attackPos [0-99] position of cell to update
/// @param anim [0/1,10-15] : [0/1] toggle between two "hit" sprites for animation, [10-15] attack animation
void drawGamefieldUpdate(uint8_t quadrant, uint8_t *gamefield, uint8_t attackPos, uint8_t anim);

/// @brief  Draw the cursor at the specified position on the specified gamefield
/// @param quadrant     [0-3] player index
/// @param x    [0-9] cursor x position
/// @param y    [0-9] cursor y position
/// @param gamefield pointer to 100 byte gamefield array from server
/// @param blink [0-2] used to cycle between different cursor sprites
void drawGamefieldCursor(uint8_t quadrant, uint8_t x, uint8_t y, uint8_t *gamefield, uint8_t blink);

/// @brief Draw the clock icon at the bottom right of the screen
void drawClock();

/// @brief Draw or erase the connection status icon at the bottom left of the screen
void drawConnectionIcon(bool show);

/// @brief Draw a single blank space character at given position
void drawBlank(uint8_t x, uint8_t y);

/// @brief Draw W blank space characters at given position
void drawSpace(uint8_t x, uint8_t y, uint8_t w);

/// @brief Draw a horizontal line of width W characters at location
void drawLine(uint8_t x, uint8_t y, uint8_t w);

/// @brief Draw a box at given location
void drawBox(uint8_t x, uint8_t y, uint8_t w, uint8_t h);

/// @brief Draw the main game board layout for the specified number of players
/// The player count dictates the general layout
void drawBoard(uint8_t playerCount);

/// @brief Call to save screen buffer for later restore. Returns false if screen buffer not supported
bool saveScreenBuffer();

/// @brief Call to restore screen buffer
void restoreScreenBuffer();

/// @brief Initialize graphics mode
void initGraphics();

/// @brief Reset graphics mode to default state
void resetGraphics();

/// @brief Wait for vertical sync
void waitvsync();
#endif /* GRAPHICS_H */
