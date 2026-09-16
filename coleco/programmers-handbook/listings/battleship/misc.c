/*******************************************************************
 * 
 * Do NOT include standard library headers (e.g. conio, std*). 
 * Instead, add to standard_lib.h, which gets included in misc.h
 * 
 ******************************************************************/

#include "misc.h"

InputStruct input;
uint8_t _lastJoy, _joy, _joySameCount = 10;
bool _buttonReleased = true;
#ifdef __APPLE2__
uint8_t _lastKey = 0;  // Track last key pressed to prevent repeated input (Apple II only)
#endif

#ifndef JOY_BTN_2_MASK
#define JOY_BTN_2_MASK JOY_BTN_1_MASK
#endif


#ifdef CUSTOM_FUJINET_CALLS
// Optional: This would be implemented in platform-specific code for emulators, etc
uint16_t custom_read_appkey(uint16_t creator_id, uint8_t app_id, uint8_t key_id, char *destination);
void custom_write_appkey(uint16_t creator_id, uint8_t app_id, uint8_t key_id, uint16_t count, char *data);
#endif

void pause(uint8_t frames)
{
    while (frames--)
        waitvsync();
}

void clearCommonInput()
{
    input.trigger = input.key = input.dirY = input.dirX = _lastJoy = _joy = _buttonReleased = 0;
#ifdef __APPLE2__
    _lastKey = 0;
#endif
    while (kbhit())
        cgetc();
}

void readCommonInput()
{
    input.trigger = input.key = input.dirX = input.dirY = 0;

    _joy = readJoystick();

    // Simulate the keyboard delay for joystick input, by checking previous joystick value
    // There is special logic so that "shifting into a diagnal" still results in a single X and Y move
    // e.g. RIGHT, RIGHT+UP, UP moves the cursor the same as a single RIGHT+UP, rathar than TWO to the right and ONE up
    if (_joy != _lastJoy)
    {
        if (JOY_LEFT(_joy) && (_lastJoy == 99 || !JOY_LEFT(_lastJoy)))
            input.dirX = -1;
        else if (JOY_RIGHT(_joy) && (_lastJoy == 99 || !JOY_RIGHT(_lastJoy)))
            input.dirX = 1;

        if (JOY_UP(_joy) && (_lastJoy == 99 || !JOY_UP(_lastJoy)))
            input.dirY = -1;
        else if (JOY_DOWN(_joy) && (_lastJoy == 99 || !JOY_DOWN(_lastJoy)))
            input.dirY = 1;

        // Reset the delay if no movement is detected
        if (_joy == 0)
            _joySameCount = 12;

        _lastJoy = _joy;

        // Trigger button press only if it was previously unpressed
        if (JOY_BTN_1(_joy) || JOY_BTN_2(_joy))
        {
            if (_buttonReleased)
            {
                input.trigger = true;
                _buttonReleased = false;
            }
        }
        else
        {
            _buttonReleased = true;
        }

        return;
    }
    else if (_joy != 0)
    {
        // Pressing in same direction, decrement wait counter
        if (!_joySameCount--)
        {
            _joySameCount = 0;

            // Set lastJoy to 99 to trigger immediate direction change on next read
            _lastJoy = 99;
        }
    }

    if (!kbhit())
    {
#ifdef __APPLE2__
        // No key pressed, reset last key (Apple II only)
        _lastKey = 0;
#endif
        return;
    }

    input.key = cgetc();
    
#ifdef __APPLE2__
    // Only process if this is a different key than last time (Apple II only)
    // This prevents the same key from being processed multiple times
    // But allow processing if last key was 0 (no key was pressed before)
    if (input.key == _lastKey && _lastKey != 0)
    {
        // Same key as last time, ignore it
        input.key = 0;
        return;
    }
    
    // New key pressed, save it
    _lastKey = input.key;
#endif

    switch (input.key)
    {
    case KEY_LEFT_ARROW:
    case KEY_LEFT_ARROW_2:
    case KEY_LEFT_ARROW_3:
        input.dirX = -1;
        break;
    case KEY_RIGHT_ARROW:
    case KEY_RIGHT_ARROW_2:
    case KEY_RIGHT_ARROW_3:
        input.dirX = 1;
        break;
    case KEY_UP_ARROW:
    case KEY_UP_ARROW_2:
    case KEY_UP_ARROW_3:
        input.dirY = -1;
        break;
    case KEY_DOWN_ARROW:
    case KEY_DOWN_ARROW_2:
    case KEY_DOWN_ARROW_3:
        input.dirY = 1;
        break;
    case KEY_SPACEBAR:
    case KEY_RETURN:
        input.trigger = true;
        break;
    }
}

void loadPrefs()
{
    memset(&prefs, 0, sizeof(prefs));
    if (read_appkey(AK_CREATOR_ID, AK_APP_ID, AK_KEY_PREFS, tempBuffer))
    {
        memcpy(&prefs, tempBuffer, sizeof(prefs));

        if (prefs.debugFlag == 0xff)
        {
            strcpy(serverEndpoint, localServer);
        }
    }
}

void savePrefs()
{
    write_appkey(AK_CREATOR_ID, AK_APP_ID, AK_KEY_PREFS, sizeof(prefs), (char *)&prefs);
}


uint16_t read_appkey(uint16_t creator_id, uint8_t app_id, uint8_t key_id, char *destination)
{
    uint16_t read = 0;

    #ifdef CUSTOM_FUJINET_CALLS
        read = custom_read_appkey(creator_id, app_id, key_id, destination);
    #else
        fuji_set_appkey_details(creator_id, app_id, DEFAULT);
        if (!fuji_read_appkey(key_id, &read, (uint8_t *)destination))
            read = 0;
    #endif

    // Add string terminator after the data ends in case it is being interpreted as a string
    destination[read] = 0;
    return read;
}

void write_appkey(uint16_t creator_id, uint8_t app_id, uint8_t key_id, uint16_t count, char *data)
{
    #ifdef CUSTOM_FUJINET_CALLS
        custom_write_appkey(creator_id, app_id, key_id, count, data);
    #else
        fuji_set_appkey_details(creator_id, app_id, DEFAULT);
        fuji_write_appkey(key_id, count, (uint8_t *)data);
    #endif
}
