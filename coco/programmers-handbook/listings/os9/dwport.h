#ifndef DWPORT_H
#define DWPORT_H

#include <cmoc.h>

/*
 * coco.h is a Disk BASIC header and we are not using it here,
 * so the one typedef we want from it comes along by hand.
 */
typedef unsigned char byte;

/* Read l bytes into s.  Returns 1 when every byte arrived. */
byte dwread(byte *s, int l);

/* Write l bytes from s.  Returns 0 on success. */
byte dwwrite(byte *s, int l);

#endif /* DWPORT_H */
