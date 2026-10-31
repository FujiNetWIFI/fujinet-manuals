/**
 * @brief   Global variables for the Atari 5200
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 */

#ifdef BUILD_ATARI5200

// The 8-bit Atari client's seats (atari-fastbasic-version/5card.bas), with
// the right-hand bets one column in: the shared drawBets() places them one
// further left than the BASIC does.
const unsigned char playerXMaster[] = { 17, 1, 1, 1, 15, 37, 37, 37 };
const unsigned char playerYMaster[] = { 20, 19, 11, 3, 2, 3, 11, 19 };
const char playerDirMaster[] = { 1, 1, 1, 1, 1, -1, -1, -1 };
const char playerBetXMaster[] = { 1, 10, 10, 10, 3, -8, -8, -8 };
const char playerBetYMaster[] = { -3, -2, 1, 4, 5, 4, 1, -2 };

//                                     2                3                4
const char playerCountIndex[] = {0,4,0,0,0,0,0,0, 0,2,6,0,0,0,0,0, 0,2,4,6,0,0,0,0,
// 5                6                 7                8
    0,2,3,5,6,0,0,0, 0,2,3,4,5,6,0,0,  0,2,3,4,5,6,7,0, 0,1,2,3,4,5,6,7};

#endif /* BUILD_ATARI5200 */
