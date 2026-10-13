/*
 * words.h -- the command line, or questions if there is none.
 *
 *   two_words(argc, argv, q1, a1, size1, q2, a2, size2)
 *       Takes the first two arguments, or, if there are none, asks for
 *       them (CP/M turns a command line into capitals, which a web path
 *       may not survive). Returns 0 if it got two, -1 if not.
 *   net_spec(s)
 *       Puts "N:" in front of s unless it starts N: or Nn: already. s needs
 *       two bytes of room.
 *
 * Copyright (C) 2026 Thomas Cherryhomes
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#ifndef WORDS_H
#define WORDS_H

int two_words(int argc, char **argv, const char *q1, char *a1, int size1,
              const char *q2, char *a2, int size2);
void net_spec(char *s);

#endif
