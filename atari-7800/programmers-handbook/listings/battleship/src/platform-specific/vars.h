/*
  Platform specific vars.
*/
#ifndef VARS_H
#define VARS_H

// Include platform specific vars - this is defined in the Makefile as "../$(PLATFORM)/vars.h"
// Watcom / wine has issues with \" in the define, so hacking this for now
// zcc (Adam/ColecoVision/Master System) gets the same treatment to avoid the \" quoting through defoogi.
// Note z88dk defines __COLECO__ for the Adam subtype too, so the ColecoVision
// build is keyed on BUILD_COLECO instead.
#if __MSDOS__
#include "../msdos/vars.h"
#elif defined(__ADAM__)
#include "../adam/vars.h"
#elif defined(BUILD_COLECO)
#include "../coleco/vars.h"
#elif defined(BUILD_SMS)
#include "../sms/vars.h"
#else
#include PLATFORM_VARS
#endif

// Default vars (covers most platforms) - after the platform include so a
// platform's vars.h can override them
#ifndef ESCAPE
#define ESCAPE "ESCAPE"
#define ESC "ESC"
#endif

#endif /* VARS_H */
