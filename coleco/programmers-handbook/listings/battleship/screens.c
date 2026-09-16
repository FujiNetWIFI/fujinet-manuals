/*******************************************************************
 * 
 * Do NOT include standard library headers (e.g. conio, std*). 
 * Instead, add to standard_lib.h, which gets included in misc.h
 * 
 ******************************************************************/

#include "misc.h"
#include "stateclient.h"
#include "screens.h"
#include "gamelogic.h"

#define PLAYER_NAME_MAX 8
#define PLAYER_BOX_TOP 13
#define REMOVE_PLAYER_KEY '/'
#define INGAME_MENU_X WIDTH / 2 - 8

// Key labels shown to the player. Platforms whose input maps these shortcuts
// onto other physical keys (e.g. the ColecoVision keypad) override them in
// their vars.h so the labels match what the player actually presses.
#ifndef TABLE_STATUS_TEXT
#define TABLE_STATUS_TEXT "Refresh    Help     Name    Quit"
#endif
#ifndef MENU_QUIT_TEXT
#define MENU_QUIT_TEXT "  Q: quit game"
#endif
#ifndef MENU_HELP_TEXT
#define MENU_HELP_TEXT "  H: how to play"
#endif
// The ON variant carries a trailing space so toggling from OFF erases the F
#ifndef MENU_SOUND_ON_TEXT
#define MENU_SOUND_ON_TEXT "  S: sound ON "
#endif
#ifndef MENU_SOUND_OFF_TEXT
#define MENU_SOUND_OFF_TEXT "  S: sound OFF"
#endif

// Logo vertical position - set in [platform]/vars.h to override if needed
#ifndef LOGO_Y
#define LOGO_Y 1
#endif

bool inBorderedScreen = false, prevBorderedScreen = false, savedScreen = false;

bool saveScreen()
{
    prevBorderedScreen = inBorderedScreen;
    return savedScreen = saveScreenBuffer();
}

bool restoreScreen()
{
    if (savedScreen)
    {
        savedScreen = false;
        inBorderedScreen = prevBorderedScreen;
        restoreScreenBuffer();
        return true;
    }
    return false;
}

/// @brief Shows information about the game
void showHelpScreen()
{
    uint8_t y;
#define X WIDTH / 2 - 16

    resetScreen();

    drawTextAlt(WIDTH / 2 - 14, 1, "how to play FUJI BATTLESHIP");
    drawLine(WIDTH / 2 - 16, 2, 31);
    y = 3;

    //                 12345678901234567890123456789012
    y++;
    drawTextAlt(X, y, "BATTLESHIP is a classic game of");
    y++;
    drawTextAlt(X, y, "sea battle for up to 4 players!");

    y += 3;
    centerTextAlt(y, "GAME PLAY");

    y++;
    y++;
    drawTextAlt(X, y, "player starts with FIVE ships,");
    y++;
    drawTextAlt(X, y, "taking turns attacking until");
    y++;
    drawTextAlt(X, y, "only ONE player remains.");
    y++;
    y++;
    drawTextAlt(X, y, "when you attack a location, ALL");
    y++;
    drawTextAlt(X, y, "ENEMY players are attacked.");

    y++;
    y++;
    y++;
    drawTextAlt(X, y, "use your strategy and luck to");
    y++;
    drawTextAlt(X, y, "be the last player standing!");

    centerStatusText("press any key to close");

    clearCommonInput();
    cgetc();
}

/// @brief Action called in Welcome Screen to check if a server name is stored in an app key
void welcomeActionVerifyServerDetails()
{
    uint8_t i;
    // Read server endpoint into server and query
    read_appkey(AK_LOBBY_CREATOR_ID, AK_LOBBY_APP_ID, AK_LOBBY_KEY_SERVER, tempBuffer);

    i = (uint8_t)strlen(tempBuffer);
    if (i)
    {
        // Split "server?query" into separate variables
        while (--i)
        {
            if (tempBuffer[i] == '?')
            {
                strcpy(query, tempBuffer + i);
                tempBuffer[i] = 0;
                strcpy(serverEndpoint, tempBuffer);
                break;
            }
        }
    }
}

void drawLogo()
{
    drawBox(WIDTH / 2 - 8, 0, 15, 1);
    drawTextAlt(WIDTH / 2 - 7, LOGO_Y, "FUJI battleship");

}

void showPlayerNameScreen()
{
    uint8_t i, y;
    resetScreen();
    drawLogo();

    centerText(13, "ENTER YOUR NAME");
    drawBox(WIDTH / 2 - PLAYER_NAME_MAX / 2 - 1, 16, PLAYER_NAME_MAX + 1, 1);
    drawText(WIDTH / 2 - PLAYER_NAME_MAX / 2, 17, playerName);

    i = (uint8_t)strlen(playerName);

    clearCommonInput();
#ifdef USE_PLATFORM_NAME_ENTRY
    platformNameEntry(WIDTH / 2 - PLAYER_NAME_MAX / 2, 17, PLAYER_NAME_MAX, playerName);
#else
    while (!inputFieldCycle(WIDTH / 2 - PLAYER_NAME_MAX / 2, 17, PLAYER_NAME_MAX, playerName))
        ;
#endif

    for (y = 13; y < 19; ++y)
        centerText(y, "                 ");

    write_appkey(AK_LOBBY_CREATOR_ID, AK_LOBBY_APP_ID, AK_LOBBY_KEY_USERNAME, strlen(playerName), playerName);
}

/// @brief Action called in Welcome Screen to verify player has a name
void welcomeActionVerifyPlayerName()
{
    char *ptr;
    // Read player's name from app key
    read_appkey(AK_LOBBY_CREATOR_ID, AK_LOBBY_APP_ID, AK_LOBBY_KEY_USERNAME, tempBuffer);
    tempBuffer[8] = 0;
    strcpy(playerName, tempBuffer);

    // Capture username if player didn't come in from the lobby
    if (!playerName[0])
    {
        showPlayerNameScreen();
    }

    // Convert to lowercase
    ptr = playerName;
    while (*ptr)
    {
        if (*ptr >= 65 && *ptr <= 90)
            *ptr += 32;
        ptr++;
    }
}

/// @brief Shows the Welcome Screen with Logo. Asks player's name
void showWelcomeScreen()
{
    // Retrieve the main player's name
    welcomeActionVerifyPlayerName();

    // Parse server url from app key if present
    welcomeActionVerifyServerDetails();

    // If first run, show the help screen
    if (!prefs.seenHelp)
    {
        prefs.seenHelp = true;
        savePrefs();
        showHelpScreen();
    }

    pause(30);
}

#define TWID 26
#define RMAR (WIDTH / 2 + TWID / 2)
#define LMAR (WIDTH / 2 - TWID / 2)
/// @brief Shows a screen to select a table to join
void showTableSelectionScreen()
{
    // tableCount is the local truth for the table list: clientState is not
    // writable on every platform (the ColecoVision reads it out of cartridge
    // ROM), so the "no tables yet" state lives here, not in clientState.
    uint8_t shownCursor, tableIndex, blinkCursor, i, j, tableCount = 0;
    Table *table;
    state.inGame = tableIndex = blinkCursor = 0;

    resetScreen();

    // An empty query means a table needs to be selected
    while (strlen(query) == 0)
    {
        // Show names of local player(s)

        strcpy(tempBuffer, "HELLO ");
        strcat(tempBuffer, playerName);
        centerTextAlt(20, tempBuffer);

        if (tableCount > 0)
        {
            for (i = 0; i < tableCount; ++i)
            {
                drawSpace(LMAR, 9 + i * 2, TWID);
            }
        }
        waitvsync();
        centerText(12, "      refreshing game list..      ");

        drawLogo();

        centerText(4, "choose a game to join");
        drawText(LMAR, 7, "game");
        drawText(RMAR - 7, 7, "players");
        drawLine(LMAR, 8, TWID);

        // waitvsync();

        tableCount = apiCall("tables") == API_CALL_SUCCESS ? clientState.tables.count : 0;
        if (tableIndex >= tableCount)
            tableIndex = 0;

        if (tableCount > 0)
        {
            drawSpace(LMAR, 12, TWID);
            for (i = 0; i < tableCount; ++i)
            {
                table = &clientState.tables.table[i];
                j = 9 + i * 2;
                drawTextAlt(LMAR, j, table->name);
                drawTextAlt(RMAR - 5, j, table->players);

                if (table->players[0] > '0')
                {
                    drawIcon(RMAR - 7, j, ICON_PLAYER);
                }
                // cgetc();
            }
        }
        else
        {
            centerText(12, "no servers are available");
        }

        centerStatusText(TABLE_STATUS_TEXT);

#ifdef COLOR_TOGGLE
        if (prefs.color)
        {
            drawLine(6, HEIGHT, 1);  // R
            drawLine(15, HEIGHT, 1); // H
            drawLine(21, HEIGHT, 1); // P
            drawLine(30, HEIGHT, 1); // Q
        }
#endif

        shownCursor = !tableCount;

        clearCommonInput();
        while (!input.trigger || !tableCount)
        {

            if (tableCount)
            {
                drawIcon(LMAR - 2, 9 + tableIndex * 2, blinkCursor < 50 ? ICON_MARK : ICON_MARK_ALT);
            }

            waitvsync();
            blinkCursor = (blinkCursor + 1) % 60;
            readCommonInput();

            if (input.key == 'h' || input.key == 'H')
            {
                saveScreen();
                showHelpScreen();
                if (!restoreScreen())
                {
                    resetScreen();
                    break;
                }
            }
            else if (input.key == 'r' || input.key == 'R')
            {
                drawBlank(LMAR - 2, 9 + tableIndex * 2);
                break;
            }
            else if (input.key == 'c' || input.key == 'C')
            {
                cycleNextColor();
                savePrefs();
#ifdef COLOR_CYCLE_REQUIRES_REDRAW
                break;
#endif
            }
            else if (input.key == 's' || input.key == 'S')
            {
                prefs.disableSound = !prefs.disableSound;
                soundCursor();
                savePrefs();
                // savePrefs() ran a FujiNet transaction; on platforms where
                // the table list lives in the cartridge's reply window it is
                // stale now, so refresh rather than keep navigating it
                break;
            }
            else if (input.key == 'n' || input.key == 'N')
            {
                showPlayerNameScreen();
                resetScreen();
                break;
            }
            else if (input.key == 'q' || input.key == 'Q')
            {
                quit();
                // quit() only returns on failure, after FujiNet transactions
                // of its own - same stale-window refresh as above
                break;
            } /*else if (input.key != 0) {
                itoa(input.key, tempBuffer, 10);
                drawStatusText(tempBuffer);
            }*/

            if (!shownCursor || (tableCount > 0 && input.dirY))
            {

                // Visually unselect old table
                table = &clientState.tables.table[tableIndex];
                j = table->name[0]; // Reference table so cmoc 0.1.96 optimizer does not corrupt memory
                j = 9 + tableIndex * 2;

                drawBlank(LMAR - 2, j);
                drawTextAlt(LMAR, j, table->name);
                drawTextAlt(RMAR - 5, j, table->players);

                // Move table index to new table
                tableIndex = (input.dirY + tableIndex + tableCount) % tableCount;

                // Visually select new table

                table = &clientState.tables.table[tableIndex];
                j = table->name[0]; // Reference table so cmoc 0.1.96 optimizer does not corrupt memory
                j = 9 + tableIndex * 2;

                drawIcon(LMAR - 2, j, ICON_MARK);
                drawText(LMAR, j, table->name);
                drawText(RMAR - 5, j, table->players);

                soundCursor();

                // Housekeeping - allows platform specific housekeeping, like stopping Attract/screensaver mode in Atari
                housekeeping();

                shownCursor = 1;
            }
        }

        if (input.trigger)
        {
            soundSelect();

            // Clear screen and write server name
            resetScreen();
            centerText(15, clientState.tables.table[tableIndex].name);

            strcpy(query, "?table=");
            strcat(query, clientState.tables.table[tableIndex].table);

            // Combine server endpoint and query for final base url
            strcpy(tempBuffer, serverEndpoint);
            strcat(tempBuffer, query);

            //  Update server app key in case of reboot
            write_appkey(AK_LOBBY_CREATOR_ID, AK_LOBBY_APP_ID, AK_LOBBY_KEY_SERVER, strlen(tempBuffer), tempBuffer);
        }
    }

    centerTextAlt(17, "connecting to server");
    progressAnim(19);

    // Append player name to query
    strcat(query, "&player=");
    strcat(query, playerName);

    // Replace space with + for pshowWelcomScreenlayer name
    i = (uint8_t)strlen(query);
    while (--i)
        if (query[i] == ' ')
            query[i] = '+';

    // Reset the game state
    clearRenderState();
    state.waitingOnEndGameContinue = false;

    // Clear gamefield
    memset(state.gamefield, 0, sizeof(state.gamefield));

    // Join table
    apiCall("state");

    // Reduce wait count for an immediate call
    state.apiCallWait = 0;

    state.inGame = true;
}

/// @brief shows in-game menu
void showInGameMenuScreen()
{
    static uint8_t y, i, wait;

    saveScreen();
    state.inGame = false;
    i = wait = 1;
    while (i)
    {

        resetScreen();
        y = HEIGHT / 2 - 3;
        drawTextAlt(INGAME_MENU_X, y, MENU_QUIT_TEXT);
        drawTextAlt(INGAME_MENU_X, y += 2, MENU_HELP_TEXT);
        if (prefs.colorMode)
            drawTextAlt(INGAME_MENU_X, y += 2, "  C: color mode");

        drawTextAlt(INGAME_MENU_X, y += 2, prefs.disableSound ? MENU_SOUND_OFF_TEXT : MENU_SOUND_ON_TEXT);

        drawBox(INGAME_MENU_X - 2, HEIGHT / 2 - 5, 19, y - (HEIGHT / 2 - 5) + 1);

        centerTextAlt(HEIGHT - 2, "press TRIGGER/SPACE to close");

        // centerTextAlt(y + 6, tempBuffer);
        clearCommonInput();
        i = 1;
        while (i == 1)
        {
            waitvsync();
            readCommonInput();
            if (input.trigger)
            {
                i = 0;
                break;
            }
            switch (input.key)
            {
            case 's':
            case 'S':
                prefs.disableSound = !prefs.disableSound;
                drawTextAlt(INGAME_MENU_X, y, prefs.disableSound ? MENU_SOUND_OFF_TEXT : MENU_SOUND_ON_TEXT);
                soundSelect();
                savePrefs();
                break;
            case 'c':
            case 'C':
                cycleNextColor();
                savePrefs();
#ifdef COLOR_CYCLE_REQUIRES_REDRAW
                i = 2;
#endif
                break;

            case 'h':
            case 'H':
                showHelpScreen();
            case 'q':
            case 'Q':
                resetScreen();
                centerText(10, "please wait");

                //  Clear server app key in case of reboot
                write_appkey(AK_LOBBY_CREATOR_ID, AK_LOBBY_APP_ID, AK_LOBBY_KEY_SERVER, 0, (char *)"");

                // Inform server player is leaving
                apiCall("leave");

                progressAnim(12);

                // Clear query so a new table will be selected
                strcpy(query, "");
                showTableSelectionScreen();

                return;
            }
        }
    }

    // Show game screen again before returning

    clearCommonInput();

    state.inGame = true;
    if ((!state.drawBoard && !restoreScreen()) || state.drawBoard)
    {
        // Re-fetch before redrawing rather than rendering clientState here:
        // the menu's savePrefs()/appkey writes ran FujiNet transactions, and
        // on platforms where the state lives in the cartridge's reply window
        // it is stale now. The main loop redraws on the next poll.
        clearRenderState();
        state.apiCallWait = 0;
    }
}
