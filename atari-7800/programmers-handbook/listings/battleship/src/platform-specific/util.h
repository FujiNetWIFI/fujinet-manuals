#ifndef UTIL_H
#define UTIL_H

/*
  Platform specific utilities that don't fit in any category
*/


void resetTimer();
uint16_t getTime();
void quit();
void housekeeping();
uint8_t getJiffiesPerSecond();
uint8_t getRandomNumber(uint8_t maxExclusive);

#endif /* UTIL_H */
