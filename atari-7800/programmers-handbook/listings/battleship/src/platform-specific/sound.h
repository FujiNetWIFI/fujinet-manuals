/*
  Platform specific sound functions
*/
#ifndef SOUND_H
#define SOUND_H

void initSound();

void disableKeySounds();
void enableKeySounds();
void soundCursor();
void soundSelect();
void soundStop();
void soundJoinGame();
void soundMyTurn();
void soundGameDone();
void soundTick();
void soundPlaceShip();
void soundAttack();
void soundInvalid();
void soundHit();
void soundSink();
void soundMiss();

void pause(uint8_t frames);

#endif /* SOUND_H */
