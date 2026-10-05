/**
 * @brief   Global variables for the NES
 * @author  Thomas Cherryhomes
 * @email   thom dot cherryhomes at gmail dot com
 * @license gpl v. 3, see LICENSE for details
 */

#ifdef BUILD_NES

// 32x24 seat layout, the ColecoVision's with the top and bottom rows of seats
// pulled in by one: top purses off row 0 and bottom cards off row 22, so the
// felt's rounded corners (resetScreen) are never drawn over. Seat 0 sits on an
// even column so its hole card fills exactly one column of 2x2 attribute
// blocks, which drawCard() greys while the card is hidden.
const unsigned char playerXMaster[] = { 10, 0, 0, 0, 11, 30, 30, 30 };
const unsigned char playerYMaster[] = { 17, 17, 10, 3, 3, 3, 10, 17 };
const char playerDirMaster[] = { 1, 1, 1, 1, 1, -1, -1, -1 };
const char playerBetXMaster[] = { 3, 10, 10, 10, 3, -8, -8, -8 };
const char playerBetYMaster[] = { -4, -4, 0, 4, 4, 4, 0, -4 };

//                                     2                3                4
const char playerCountIndex[] = {0,4,0,0,0,0,0,0, 0,2,6,0,0,0,0,0, 0,2,4,6,0,0,0,0,
// 5                6                 7                8
    0,2,3,5,6,0,0,0, 0,2,3,4,5,6,0,0,  0,2,3,4,5,6,7,0, 0,1,2,3,4,5,6,7};

#endif /* BUILD_NES */
