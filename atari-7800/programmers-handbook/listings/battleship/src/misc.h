/*
 * Common include file for project.
*/ 

/*******************************************************************
 * 
 * Do NOT include standard library headers (e.g. conio, std*). 
 * Instead, add to standard_lib.h, which gets included in this file
 * 
 ******************************************************************/

#ifndef MISC_H
#define MISC_H

#include "standard_lib.h"
#include "platform-specific/graphics.h"
#include "platform-specific/util.h"
#include "platform-specific/input.h"
#include "platform-specific/sound.h"
#include "platform-specific/vars.h"

// Client version string to send to server
#define API_CLIENT_VERSION "2"

// FujiNet AppKey settings. These should not be changed
#define AK_LOBBY_CREATOR_ID 1   // FUJINET Lobby
#define AK_LOBBY_APP_ID 1       // Lobby Enabled Game
#define AK_LOBBY_KEY_USERNAME 0 // Lobby Username key
#define AK_LOBBY_KEY_SERVER 5   // Battleship registered as Lobby appkey 5 at https://github.com/FujiNetWIFI/fujinet-firmware/wiki/SIO-Command-$DC-Open-App-Key

// Battleship
#define AK_CREATOR_ID 0xE41C // Eric Carr's creator id
#define AK_APP_ID 5          // Battleship App ID
#define AK_KEY_PREFS 0       // Preferences

#define PLAYER_MAX 4

#define FUJITZEE_SCORE 14

#define STATUS_LOBBY 0
#define STATUS_PLACE_SHIPS 1
#define STATUS_GAMESTART 10
#define STATUS_MISS 11     // Attack did not hit any ships
#define STATUS_HIT 12      // A ship was hit
#define STATUS_SUNK 13     // Also implies a ship was hit
#define STATUS_GAMEOVER 99 // Also implies a ship was hit

// Set at start to force full redraw
#define STATE_INVALID 200

// Player status
#define PLAYER_STATUS_DEFAULT 0
#define PLAYER_STATUS_DEFEATED 1
#define PLAYER_STATUS_VIEWING 2
#define PLAYER_STATUS_READY 3
#define PLAYER_STATUS_PLACE_SHIPS 10

#define FIELD_ATTACK 1
#define FIELD_MISS 2

#define LEGEND_SHIP_DESTROYED 0
#define LEGEND_SHIP_INTACT 1

#define DRAWSHIP_SHOW 0
#define DRAWSHIP_HIDE 1

typedef struct
{
    char table[9];
    char name[21];
    char players[6];
} Table;

typedef struct
{
    char name[9];
    uint8_t playerStatus;
    uint8_t gamefield[100];
    uint8_t shipsLeft[5];
} Player;

typedef struct
{
    char name[9];
    uint8_t ready;
} LobbyPlayer;

typedef struct
{
    uint8_t count;
    Table table[10];
} Tables;

typedef struct
{
    uint8_t playerCount;
    char prompt[33];
    uint8_t status;
    uint8_t playerStatus;
    int8_t activePlayer;
    uint8_t moveTime;
    uint8_t lastAttackPos;
    // First 5 are my ships, last 5 are winner, sent at game over
    uint8_t myShips[10];
    Player players[PLAYER_MAX];
} Game;

typedef struct
{
    uint8_t playerCount;
    char prompt[33];
    uint8_t status;
    uint8_t playerStatus;
    int8_t activePlayer;
    uint8_t moveTime;
    char serverName[21];
    LobbyPlayer players[PLAYER_MAX];
} Lobby;

typedef union
{
    uint8_t firstByte;
    Game game;
    Lobby lobby;
    Tables tables;
} ClientState;

#ifdef BUILD_COLECO
/*
  The ColecoVision has 1K of RAM and this union is 509 bytes of it, so the
  state is never copied down: it is read in place out of the FujiNet
  cartridge's reply window, which is what that window is 1K and addressable
  for. See src/coleco/vars.h and src/coleco/fujinet.c.

  It is therefore READ-ONLY -- a store here goes nowhere, the cartridge cannot
  even see a write cycle -- and it is valid only until the next fuji_* call of
  any kind, because every transaction repaints the window.
*/
#define clientState (*(ClientState *) COLECO_REPLY_WINDOW)
#else
extern ClientState clientState;
#endif

/*
  The gamefield shadow only ever answers "was this cell empty before" (the
  shoot animation trigger), so on the RAM-starved ColecoVision it is packed to
  one bit per cell - 13 bytes per player instead of 100. Everywhere else it
  stays byte-per-cell. gamelogic.c's packGamefield() fills it and
  GAMEFIELD_IS_EMPTY() is the only reader.
*/
#ifdef BUILD_COLECO
#define GAMEFIELD_BYTES 13
#define GAMEFIELD_IS_EMPTY(p, pos) (!(state.gamefield[p][(pos) >> 3] & (1 << ((pos)&7))))
#else
#define GAMEFIELD_BYTES 100
#define GAMEFIELD_IS_EMPTY(p, pos) (state.gamefield[p][pos] == 0)
#endif

typedef struct
{

    // Internal game state
    uint8_t prevPlayerCount;
    uint8_t prevStatus;
    uint8_t prevPlayerStatus;
    uint8_t apiCallWait;

    int8_t prevActivePlayer;
    int8_t prevAttackPos;

    bool countdownStarted;
    bool waitingOnEndGameContinue;
    bool drawBoard;
    bool inGame;

    // Track gamefield state - used to know when to fire shoot animation
    uint8_t gamefield[PLAYER_MAX][GAMEFIELD_BYTES];

    // Track ships left - used to know when to fire sink animation
    uint8_t shipsLeft[PLAYER_MAX][5];
} GameState;

typedef struct
{
    uint16_t key;
    bool trigger;
    int8_t dirX;
    int8_t dirY;
} InputStruct;

typedef struct
{
    uint8_t debugFlag; // 0xFF to use localhost instead of server
    bool seenHelp;
    uint8_t disableSound;
    uint8_t colorMode;
    uint8_t reserved[20]; // Reserve blank space for future
} PrefsStruct;

/*
  Scratch buffer sizes. The ColecoVision has 1K of RAM in total, so these are
  cut to what each one actually has to hold rather than to a round number.
  On the ColecoVision tempBuffer also doubles as stateclient.c's url build
  buffer, so its floor is the full url: "n:" + endpoint(49) + the longest path
  ("place/199,..." = 25) + query(35) + "&bin=1&v=2" = 122 (which also covers
  its other floors, the 100-cell ship-placement occupancy map and
  MAX_APPKEY_LEN+1). query is "?table=" + 8 + "&player=" + 11.
*/
#ifdef BUILD_COLECO
#define TEMP_BUFFER_LEN 124
#define QUERY_LEN 36
#define URL_BUFFER_LEN 124
#else
#define TEMP_BUFFER_LEN 128
#define QUERY_LEN 50
#define URL_BUFFER_LEN 160
#endif

extern char tempBuffer[TEMP_BUFFER_LEN];
extern char serverEndpoint[50];
extern const char localServer[];
extern char query[QUERY_LEN];
extern char playerName[12];
extern const uint8_t shipSize[5];

#ifdef USE_PLATFORM_NAME_ENTRY
// Keyboard-less platforms implement name entry themselves (e.g. the
// ColecoVision on-screen keyboard in src/coleco/osk.c)
void platformNameEntry(uint8_t x, uint8_t y, uint8_t max, char *buffer);
#endif

extern GameState state;
extern InputStruct input;
extern PrefsStruct prefs;

// Common local scope temp variables

void pause(uint8_t frames);
void clearCommonInput();
void readCommonInput();
void loadPrefs();
void savePrefs();

/// @brief Helper method to write to an appkey
void write_appkey(uint16_t creator_id, uint8_t app_id, uint8_t key_id, uint16_t count, char *data);

/// @brief Helper method to read from an appkey.
/// NULL will be appended to data in case this is a string, though the length returned will not consider the NULL.
uint16_t read_appkey(uint16_t creator_id, uint8_t app_id, uint8_t key_id, char *destination);

#endif /* MISC_H */
