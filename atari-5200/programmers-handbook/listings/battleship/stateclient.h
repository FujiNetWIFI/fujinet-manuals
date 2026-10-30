/*******************************************************************
 * 
 * Do NOT include standard library headers (e.g. conio, std*). 
 * Instead, add to standard_lib.h, which gets included in misc.h
 * 
 ******************************************************************/

#ifndef STATECLIENT_H
#define STATECLIENT_H

#define API_CALL_ERROR (0)
#define API_CALL_SUCCESS (1)
#define API_CALL_PENDING (2)

#define STATE_UPDATE_ERROR (0)
#define STATE_UPDATE_CHANGE (1)
#define STATE_UPDATE_NOCHANGE (2)

void updateState(bool isTables);
uint8_t getStateFromServer();
uint8_t apiCall(const char *path );
void sendMove(char* move);

#endif /* STATECLIENT_H */
