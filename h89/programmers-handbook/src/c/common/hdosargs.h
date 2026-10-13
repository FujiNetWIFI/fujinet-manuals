/*
 * hdosargs.h -- the command line under HDOS.
 *
 * z88dk's HDOS start-up code (hdos_crt0.asm, startup=3) picks the entry
 * stack pointer back up after it has moved the stack, so it parses the
 * command line with a wrong length and argv[] comes out damaged. Build with
 * -pragma-define:CRT_ENABLE_COMMANDLINE=0 and call hdos_args() first thing
 * in main(): it splits the command line HDOS left below 2280H into argv[].
 * Under CP/M it changes nothing.
 *
 * Copyright (C) 2026 Thomas Cherryhomes
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
#ifndef HDOSARGS_H
#define HDOSARGS_H

#define HDOS_MAXARGS 16

#ifdef __HDOS__
int hdos_args(char ***argvp);
#define ARGS(argc, argv)  ((argc) = hdos_args(&(argv)))
#else
#define ARGS(argc, argv)
#endif

#endif
