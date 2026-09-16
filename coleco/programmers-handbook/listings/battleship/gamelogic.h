#ifndef GAMELOGIC_H
#define GAMELOGIC_H

void processStateChange();
void renderLobby();
void renderGameboard();
void handleAnimation();

void processInput();

void clearRenderState();

void centerText(uint8_t y, const char *text);
void centerTextAlt(uint8_t y, const char *text);
void centerTextWide(uint8_t y, const char *text);
void centerStatusText(const char *text);

void resetInputField();
bool inputFieldCycle(uint8_t x, uint8_t y, uint8_t max, char *buffer);

void waitOnPlayerMove();

void progressAnim(uint8_t y);

void placeShip(uint8_t shipSize, uint8_t pos);
bool testShip(uint8_t shipSize, uint8_t pos);

#endif /*GAMELOGIC_H*/
