/*******************************************************************
 * 
 * Do NOT include standard library headers (e.g. conio, std*). 
 * Instead, add to standard_lib.h, which gets included in misc.h
 * 
 ******************************************************************/

#include "misc.h"
#include "gamelogic.h"
#include "stateclient.h"
#include "screens.h"

#ifndef TIMER_WIDTH
#define TIMER_WIDTH 1
#endif

// Platforms whose input maps the rotate shortcut onto another physical key
// (e.g. the ColecoVision keypad) override this in their vars.h
#ifndef ROTATE_PROMPT_TEXT
#define ROTATE_PROMPT_TEXT "press R to rotate"
#endif

uint8_t posX = 0, posY = 0, inputField_done, validX;
uint8_t shipPlacements[5] = {0, 0, 0, 0, 0};
uint8_t shipPlaceIndex = 0;
char moveBuffer[32];

void progressAnim(uint8_t y)
{
    static uint8_t i;

    for (i = 0; i < 3; ++i)
    {
        pause(10);
        drawIcon(WIDTH / 2 - 2 + i * 2, y, ICON_MARK);
    }
}

// Capture a player's server gamefield into the local shadow (see the
// GAMEFIELD_BYTES note in misc.h for why this is packed on the ColecoVision)
static void packGamefield(uint8_t p)
{
#ifdef BUILD_COLECO
    uint8_t *src = clientState.game.players[p].gamefield;
    uint8_t i;

    memset(&state.gamefield[p], 0, GAMEFIELD_BYTES);
    for (i = 0; i < 100; i++)
        if (src[i])
            state.gamefield[p][i >> 3] |= 1 << (i & 7);
#else
    memcpy(&state.gamefield[p], &clientState.game.players[p].gamefield, 100);
#endif
}

void processStateChange()
{
    static uint8_t i;

    switch (clientState.game.status)
    {
    case STATUS_LOBBY:
        renderLobby();
        break;
    default:
        renderGameboard();
        break;
    }

    state.prevStatus = clientState.game.status;
    state.prevPlayerStatus = clientState.game.playerStatus;
    state.prevPlayerCount = clientState.game.playerCount;
    state.prevActivePlayer = clientState.game.activePlayer;
    state.prevAttackPos = clientState.game.lastAttackPos;

    if (clientState.game.status >= STATUS_GAMESTART)
    {
        for(i=0;i<clientState.game.playerCount;i++)
        {
            packGamefield(i);
        }
    }
}

#define READY_LEFT WIDTH / 2 - 8

void renderLobby()
{
    static uint8_t c = 0;
    uint8_t i, len;

    if (clientState.game.status != state.prevStatus || state.drawBoard)
    {
        state.drawBoard = false;
        
        // Clear gamefield
        memset(state.gamefield, 0, sizeof(state.gamefield));

        resetScreen();

        // Round 0 - Ready Up screen
        drawLogo();
        centerText(6, clientState.lobby.serverName);

        drawLine(READY_LEFT, 7, 16);
        centerTextAlt(HEIGHT - 4, "press " ESCAPE " for menu");
        centerTextAlt(HEIGHT - 1, "press TRIGGER/SPACE when ready");

        // Reset ship placement ahead of next screen
        memset(shipPlacements, 0, sizeof(shipPlacements));
        shipPlaceIndex = 0;
    }

    centerTextWide(HEIGHT - 8, clientState.lobby.prompt);

    if (clientState.lobby.prompt[0] == 's')
    {
        if (state.countdownStarted)
        {
            soundTick();
        }
        else
        {
            soundJoinGame();
            state.countdownStarted = true;
        }
    }
    else
    {
        state.countdownStarted = false;
    }

    // Show players that are ready to start
    c++;
    for (i = 0; i < 9; i++)
    {
        if (i < clientState.lobby.playerCount)
        {
            drawText(READY_LEFT, 8 + i, clientState.lobby.players[i].name);
            len = (uint8_t)strlen(clientState.lobby.players[i].name);
            if (len < 8)
            {
                drawSpace(READY_LEFT + len, 8 + i, 8 - len);
            }
            drawText(READY_LEFT, 8 + i, clientState.lobby.players[i].name);
            if (clientState.lobby.players[i].ready)
            {
                drawTextAlt(READY_LEFT + 11, 8 + i, "ready");
            }
            else
            {
                drawSpace(READY_LEFT + 11, 8 + i, 5);
                drawIcon(READY_LEFT + 11 + ((c + i * 2) % 5), 8 + i, ICON_MARK);
            }
        }
        else if (i < state.prevPlayerCount)
        {
            drawSpace(READY_LEFT, 8 + i, 16);
        }
    }

    // pause(10);
}

void handleShipPlacement()
{
    uint8_t i, x, y, dir, pos, size, change, blink, maxW, maxH, canPlace;

    // Use tempBuffer to track occupied cells while placing ships
    memset(tempBuffer, 0, sizeof(tempBuffer));

    for (i = 0; i < shipPlaceIndex; i++)
    {
        pos = shipPlacements[i];
        placeShip(shipSize[i], pos);
    }

    clearCommonInput();
    while (shipPlaceIndex < 5)
    {
        size = shipSize[shipPlaceIndex];
        // Randomly select new location

        while (1)
        {
            pos = getRandomNumber(200);
            if (testShip(size, pos))
                break;
        }

        dir = pos / 100;
        x = pos % 10;
        y = (pos % 100) / 10;
        blink = 0;
        clearCommonInput();

        while (true)
        {
            // Draw ship at current position

            maxW = (11 - (dir == 0 ? size : 1));
            maxH = (11 - (dir == 1 ? size : 1));
            x = (x % maxW);
            y = (y % maxH);

            waitvsync();
            if (blink == 0 || blink == 16)
            {
                if (!blink)
                {
                    // Clear existing ship
                    drawShip(0, size, pos, DRAWSHIP_HIDE);
                }

                // New ship position
                pos = y * 10 + x + dir * 100;
                drawShip(0, size, pos, blink);

                // Redraw other ships in case they were overwritten
                for (i = 0; i < shipPlaceIndex; i++)
                {
                    drawShip(0, shipSize[i], shipPlacements[i], DRAWSHIP_SHOW);
                }
                if (change)
                {
                    soundCursor();
                }
                change = 0;
            }

            blink = (blink + 1) & 31;

            readCommonInput();
            // Move cursor
            if (input.dirX)
            {
                x += maxW + input.dirX;
                change = 1;
                blink = 0;
            }
            else if (input.dirY)
            {
                y += maxH + input.dirY;
                change = 1;
                blink = 0;
            }

            // Rotate ship
            if (input.key == 'r' || input.key == 'R')
            {
                dir = (dir + 1) % 2;
                change = 1;
                blink = 0;
            }

            // Confirm placement
            if (input.trigger)
            {
                if (testShip(size, pos))
                {
                    placeShip(size, pos);
                    shipPlacements[shipPlaceIndex] = pos;
                    shipPlaceIndex++;
                    if (shipPlaceIndex < 5)
                    {
                        soundPlaceShip();
                    }
                    else
                    {
                        // Clear input for next ship
                        soundSelect();
                    }

                    break;
                }
                else
                {
                    soundInvalid();
                }
            }

            switch (input.key)
            {
                case KEY_ESCAPE:     // Esc
                case KEY_ESCAPE_ALT: // Esc Alt
                    showInGameMenuScreen();
                    return;
                    break;
            }
        }
    }

    // Now send to server
    strcpy(moveBuffer, "place/");
    for (i = 0; i < 5; i++)
    {
        itoa(shipPlacements[i], &moveBuffer[strlen(moveBuffer)], 10);
        if (i < 4)
            strcat(moveBuffer, ",");
    }

    sendMove(moveBuffer);
}

void renderGameboard()
{
#define LEGEND_X WIDTH / 2 + 8
    static bool redraw, fullWidth;
    uint8_t i, j, jj, x, y, dir, pos, size, playedSound, skipAnim = false;

    // Redraw the entire board when placing ships back to round 0 (ready up)
    redraw = clientState.game.status != state.prevStatus && (clientState.game.status == STATE_INVALID || clientState.game.status == STATUS_PLACE_SHIPS || state.prevStatus == STATUS_PLACE_SHIPS);

    // Clear screen and draw initial backdrop
    if (redraw || state.drawBoard)
    {
        state.drawBoard = false;
        redraw = true;
        skipAnim = true;
        resetScreen();
        drawBoard(clientState.game.status == STATUS_PLACE_SHIPS ? 1 : clientState.game.playerCount);

        if (clientState.game.status == STATUS_PLACE_SHIPS)
        {
            centerText(5, "place your five ships");
            centerTextAlt(7, ROTATE_PROMPT_TEXT);
        }
        if (clientState.game.status >= STATUS_GAMESTART)
        {
            // Draw this player's ships
            if (clientState.game.playerStatus != PLAYER_STATUS_VIEWING)
            {
                for (i = 0; i < 5; i++)
                {
                    drawShip(0, shipSize[i], clientState.game.myShips[i], DRAWSHIP_SHOW);
                }
            }

            // Draw gamefield
            for (i = 0; i < clientState.game.playerCount; i++)
            {
                drawGamefield(i, clientState.game.players[i].gamefield);
            }
        }
    }

    if (clientState.game.status >= STATUS_GAMESTART)
    {
        if (clientState.game.activePlayer == state.prevActivePlayer || clientState.game.status == STATUS_GAMESTART)
        {
            skipAnim = true;
        }

        playedSound = skipAnim;

        // Render gamefield updates
        if (clientState.game.status > STATUS_GAMESTART)
        {

            // Animate other player's attack
            if (!skipAnim && state.prevActivePlayer != 0)
            {
                for (j = 10; j < 16; j++)
                {
                    for (i = 0; i < clientState.game.playerCount; i++)
                    {
                        if (i != state.prevActivePlayer && clientState.game.players[i].playerStatus == PLAYER_STATUS_DEFAULT && GAMEFIELD_IS_EMPTY(i, clientState.game.lastAttackPos))
                            drawGamefieldUpdate(i, clientState.game.players[i].gamefield, clientState.game.lastAttackPos, j);
                    }
                    pause(5);
                }
            }

            // Animate/render hit/miss
            for (j = (!skipAnim && clientState.game.status == STATUS_HIT) * 6; j < 255; --j)
            {
                for (i = 0; i < clientState.game.playerCount; i++)
                {
                    if (i != state.prevActivePlayer && GAMEFIELD_IS_EMPTY(i, clientState.game.lastAttackPos))
                        drawGamefieldUpdate(i, clientState.game.players[i].gamefield, clientState.game.lastAttackPos, j & 1);
                }
                if (!playedSound)
                {
                    if (clientState.game.status > STATUS_MISS)
                    {
                        soundHit();
                    }
                    else
                    {
                        soundMiss();
                    }
                    playedSound = 1;
                }

                pause(4);
            }
        }

        for (i = 0; i < clientState.game.playerCount; i++)
        {
            // Draw ships left indicators on legend
            for (j = 0; j < 5; j++)
            {
                // Animate a ship being sunk
                if (!skipAnim && state.shipsLeft[i][j] != clientState.game.players[i].shipsLeft[j])
                {
                    for (jj = 0; jj < 5; jj++)
                    {
                        pause(4);
                        drawLegendShip(i, j, shipSize[j], jj & 1);
                    }

                    soundSink();
                }
                else
                {
                    drawLegendShip(i, j, shipSize[j], clientState.game.players[i].shipsLeft[j]);
                }
            }

            // Track current ships left so we can animate when a ship gets sunk
            memcpy(state.shipsLeft[i], clientState.game.players[i].shipsLeft, 5);
        }

        if (clientState.game.status != STATUS_GAMEOVER || redraw || clientState.game.status != state.prevStatus)
        {
            // Clear active player
            for (i = 0; i < clientState.game.playerCount; i++)
            {
                // Draw player name
                if (i != clientState.game.activePlayer)
                    drawPlayerName(i, i == 0 && clientState.game.playerStatus != PLAYER_STATUS_VIEWING ? "you" : (const char *)clientState.game.players[i].name, false);
            }

            // Indicate active player if not game over
            if (clientState.game.status != STATUS_GAMEOVER)
            {
                // Show active player
                if (clientState.game.activePlayer >= 0)
                {
                    drawPlayerName(clientState.game.activePlayer, clientState.game.activePlayer == 0 && clientState.game.playerStatus != PLAYER_STATUS_VIEWING ? "you" : (const char *)clientState.game.players[clientState.game.activePlayer].name, true);
                }

                // Blink active player
                if (clientState.game.activePlayer > 0)
                {

                    pause(15);
                    drawPlayerName(clientState.game.activePlayer, clientState.game.players[clientState.game.activePlayer].name, false);

                    pause(15);
                    drawPlayerName(clientState.game.activePlayer, clientState.game.players[clientState.game.activePlayer].name, true);
                    pause(15);
                }
            }
        }
    }

    // Display the gameover message and play a sound if the state just changed
    if (clientState.game.status == STATUS_GAMEOVER && (redraw || clientState.game.status != state.prevStatus))
    {
        // Reveal winning player's ships (if not this player)
        waitvsync();
        if (clientState.game.activePlayer > 0)
        {
            for (i = 0; i < 5; i++)
            {
                drawShip(clientState.game.activePlayer, shipSize[i], clientState.game.myShips[5 + i], DRAWSHIP_SHOW);
            }

            drawGamefield(clientState.game.activePlayer, clientState.game.players[clientState.game.activePlayer].gamefield);
        }

        drawEndgameMessage(clientState.game.prompt);

        if (clientState.game.status != state.prevStatus)
        {
            soundGameDone();

            // Wait for user to press button to close game result
            clearCommonInput();
            while (!input.trigger)
            {
                waitvsync();
                readCommonInput();
            }
        }
    }

    // Draw ships that have been placed already
    if (clientState.game.status == STATUS_PLACE_SHIPS)
    {
        if (clientState.game.playerStatus != PLAYER_STATUS_VIEWING)
        {
            if (clientState.game.playerStatus == PLAYER_STATUS_PLACE_SHIPS)
            {
                handleShipPlacement();
            }
            else
            {
                // Draw already placed ships from game state
                for (i = 0; i < 5; i++)
                {
                    drawShip(0, shipSize[i], clientState.game.myShips[i], DRAWSHIP_SHOW);
                }
            }
        }
        if (clientState.game.status == STATUS_PLACE_SHIPS)
        {
            centerTextWide(5, clientState.game.prompt);
            centerTextAlt(7, "                   ");
        }
    }
    pause(30);
    // cgetc();
    // pause(60);
}

void placeShip(uint8_t shipSize, uint8_t pos)
{
    uint8_t i;
    drawShip(0, shipSize, pos, DRAWSHIP_SHOW);
    for (i = 0; i < shipSize; i++)
    {
        tempBuffer[pos % 100] = 1;
        pos += (pos >= 100) ? 10 : 1;
    }
}

/// @brief Returns true if free to place ship at position
bool testShip(uint8_t shipSize, uint8_t pos)
{
    uint8_t i;
    for (i = 0; i < shipSize; i++)
    {
        // if existing ship || outside V bounds || crossed H bounds, return false
        if (tempBuffer[pos % 100] || pos > 199 || (i > 0 && pos <= 100 && pos % 10 == 0))
            return false;

        pos += (pos >= 100) ? 10 : 1;
    }
    return true;
}

void processInput()
{
    waitvsync();
    readCommonInput();

    if (state.waitingOnEndGameContinue)
    {
        if (input.trigger)
        {
            state.waitingOnEndGameContinue = false;
            //  clearRenderState();
        }
    }
    else if (clientState.game.playerStatus != PLAYER_STATUS_VIEWING)
    {
        // Toggle readiness if waiting to start game. The server echoes the
        // updated lobby state back from "ready", so render from that truth
        // rather than writing the toggle into clientState first - clientState
        // is not writable on every platform (the ColecoVision reads it out of
        // the cartridge's reply window).
        if (clientState.game.status == STATUS_LOBBY && input.trigger)
        {
            if (apiCall("ready") == API_CALL_SUCCESS && clientState.game.status == STATUS_LOBBY)
            {
                if (clientState.lobby.players[0].ready)
                    soundSelect();
                else
                    soundInvalid();

                renderLobby();
            }

            // Poll again right away in case the reply was not the lobby state
            state.apiCallWait = 0;
            clearCommonInput();
            return;
        }

        // Wait on this player to attack
        if (clientState.game.activePlayer == 0 && clientState.game.status >= STATUS_GAMESTART)
        {
            waitOnPlayerMove();
        }
    }

    switch (input.key)
    {
    case KEY_ESCAPE:     // Esc
    case KEY_ESCAPE_ALT: // Esc Alt
        showInGameMenuScreen();
        break;
    }
}

void waitOnPlayerMove()
{
    bool foundValidLocation;
    uint8_t waitCount, frames, lastFrame, i, j, moved, attackPos;
    // The countdown tracker. Hoisted out of clientState: writing the ticking
    // value back into it never worked on platforms where the state is
    // read-only (the ColecoVision's cartridge reply window) - the write went
    // nowhere, the loop condition never expired, and the move was never
    // auto-resolved.
    uint8_t timeLeft;
    uint16_t jifsPerSecond, maxJifs;

    resetTimer();

    // Determine max jiffies for PAL and NTS
    jifsPerSecond = getJiffiesPerSecond();
    timeLeft = clientState.game.moveTime;
    maxJifs = jifsPerSecond * timeLeft;
    waitCount = 0;
    moved = frames = 9;

    // Move selection loop
    while (timeLeft > 0)
    {
        frames = (frames + 1) % 30;
        i = frames / 10;
        waitvsync();
        if (moved || i != lastFrame)
        {
            

            // Always show the cursor (do not blink) when moving it around. 
            // Otherwise, it appears to skip around
            if (moved)
                lastFrame = 1; // Show cursor frame 1
            else
                lastFrame = i; // Show 0,1,2 depending on frame

            // Draw cursor
            for (i = 1; i < clientState.game.playerCount; i++)
            {
                if (clientState.game.players[i].playerStatus == PLAYER_STATUS_DEFAULT)
                    drawGamefieldCursor(i, posX, posY, clientState.game.players[i].gamefield, lastFrame);
            }
        }

        if (moved)
        {
            // Play "my turn" sound on first move
            if (moved == 9)
                soundMyTurn();
            else
                soundCursor();

            moved = 0;
        }

        // Handle trigger press
        if (input.trigger)
        {

            attackPos = posY * 10 + posX;

            // Check if at least one enemy cell is valid to attack
            for (i = 1; i < clientState.game.playerCount; i++)
            {
                if (clientState.game.players[i].playerStatus == PLAYER_STATUS_DEFAULT && GAMEFIELD_IS_EMPTY(i, attackPos))
                    break;
            }

            if (i == clientState.game.playerCount)
            {
                // Invalid location
                soundInvalid();
            }
            else 
            {
                // Attack!
                soundAttack();
                
                // Animate attack / clear cursor
                for (j = 10; j < 16; j++)
                {
                    for (i = 1; i < clientState.game.playerCount; i++)
                    {
                        if (clientState.game.players[i].playerStatus == PLAYER_STATUS_DEFAULT)
                            drawGamefieldUpdate(i, clientState.game.players[i].gamefield, attackPos, GAMEFIELD_IS_EMPTY(i, attackPos) ?  j : 0);
                    }
                    pause(5);
                }

                // Send command to score this value
                strcpy(moveBuffer, "attack/");
                itoa(attackPos, moveBuffer + strlen(moveBuffer), 10);
                sendMove(moveBuffer);

                // Clear timer
                drawSpace(WIDTH - TIMER_WIDTH - 2, HEIGHT - 1, 2 + TIMER_WIDTH);
                return;
            }
        }

        // Update cursor
        if (input.dirX || input.dirY)
        {
            for (i = 1; i < clientState.game.playerCount; i++)
            {
                if (clientState.game.players[i].playerStatus == PLAYER_STATUS_DEFAULT)
                    drawGamefieldCursor(i, posX, posY, clientState.game.players[i].gamefield, 0);
            }
            posX = (posX + 10 + input.dirX) % 10;
            posY = (posY + 10 + input.dirY) % 10;
            moved = 1;
        }

        // Tick counter once per second
        if (++waitCount > 5)
        {
            waitCount = 0;
            i = (uint8_t)((maxJifs - getTime()) / jifsPerSecond);
            if (i <= 20 && i != timeLeft)
            {
                timeLeft = i;
                if (i < 10)
                    tempBuffer[0] = ' ';

                itoa(i, tempBuffer + (i < 10), 10);
                drawTextAlt(WIDTH - TIMER_WIDTH - 2, HEIGHT - 1, tempBuffer);
                drawClock();
                soundTick();
            }
        }

        // Pressed Esc
        switch (input.key)
        {
        case KEY_ESCAPE:
        case KEY_ESCAPE_ALT:
            for (i = 1; i < clientState.game.playerCount; i++)
            {
                if (clientState.game.players[i].playerStatus == PLAYER_STATUS_DEFAULT)
                    drawGamefieldCursor(i, posX, posY, clientState.game.players[i].gamefield, 0);
            }
            showInGameMenuScreen();
            return;
        }

        // Read input for next iteration
        readCommonInput();
    }

    // Timed out
}

uint8_t prevCursorPos;
// Invalidate state variables that will trigger re-rendering of screen items on the next cycle
void clearRenderState()
{
    state.prevPlayerCount = 0;
    state.drawBoard = true;
}

/// @brief Convenience function to draw text centered at row Y
void centerText(uint8_t y, const char *text)
{
    drawText(WIDTH / 2 - (uint8_t)strlen(text) / 2, y, text);
}

/// @brief Convenience function to draw text centered at row Y, blanking out the rest of the row
void centerTextWide(uint8_t y, const char *text)
{
    uint8_t i, x;
    i = (uint8_t)strlen(text);
    x = WIDTH / 2 - i / 2;

    drawSpace(0, y, x);
    drawText(x, y, text);
    drawSpace(x + i, y, WIDTH - x - i);
}

/// @brief Convenience function to draw text centered at row Y in alternate color
void centerTextAlt(uint8_t y, const char *text)
{
    drawTextAlt(WIDTH / 2 - (uint8_t)strlen(text) / 2, y, text);
}

/// @brief Convenience function to draw status text centered
void centerStatusText(const char *text)
{
    drawTextAlt((WIDTH - (uint8_t)strlen(text)) >> 1, HEIGHT - 1, text);
}

/// @brief Init/reset the input field for display
void resetInputField()
{
    inputField_done = 1;
    disableKeySounds();
}

/// @brief Handles available key strokes for the defined input box (player name and chat). Returns true if user hits enter
bool inputFieldCycle(uint8_t x, uint8_t y, uint8_t max, char *buffer)
{
    // These must persist between calls (curx tracks the cursor across the
    // keystroke cycles); as stack locals they only worked by accident on cc65
    static uint8_t curx, lastY;

    // Initialize first call to input box
    if (inputField_done == 1 || lastY != y)
    {
        inputField_done = 0;
        lastY = y;
        curx = (uint8_t)strlen(buffer);
        drawTextAlt(x, y, buffer);
        drawIcon(x + curx, y, ICON_TEXT_CURSOR);
        enableKeySounds();
    }

    // Process any waiting keystrokes
    if (kbhit())
    {
        inputField_done = 0;

        input.key = cgetc();

        // Debugging - See what key was pressed
        // itoa(input.key, tempBuffer, 10);drawText(0,0, tempBuffer);

        if (input.key == KEY_RETURN && curx > 1)
        {
            inputField_done = 1;
            // remove cursor
            drawBlank(x + curx, y);
        }
        else if ((input.key == KEY_BACKSPACE || input.key == KEY_LEFT_ARROW) && curx > 0)
        {
            buffer[--curx] = 0;
            drawText(x + 1 + curx, y, " ");
        }
        else if (
            curx < max && ((curx > 0 && input.key == KEY_SPACEBAR) || (input.key >= 48 && input.key <= 57) || (input.key >= 65 && input.key <= 90) || (input.key >= 97 && input.key <= 122)) // 0-9 A-Z a-z
        )
        {

            if (input.key >= 65 && input.key <= 90)
                input.key += 32;

            buffer[curx] = input.key;
            buffer[++curx] = 0;
        }

        drawTextAlt(x, y, buffer);

        if (inputField_done)
            disableKeySounds();
        else
            drawIcon(x + curx, y, ICON_TEXT_CURSOR);

        return inputField_done;
    }

    return false;
}
