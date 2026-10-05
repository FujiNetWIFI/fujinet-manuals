/* netcat.c -- a network terminal for the NES.
 *
 * Asks for a URL (N:TCP://host:port/ or N:TELNET://...), connects, and then
 * shows whatever the other end sends. Press Start to type a line on the
 * on-screen keyboard -- Start again sends it -- or just type, if a Family
 * BASIC or Subor keyboard is plugged in. Select hangs up. */

#include <conio.h>
#include <string.h>
#include <fujinet-network.h>
#include <fujinet-nes.h>
#include "pad.h"
#include "osk.h"
#include "term.h"

#ifndef DEFAULT_URL
#define DEFAULT_URL "N:TCP://BBS.FOZZTEXX.COM:23/"
#endif

#define URL_MAX   120
#define LINE_MAX   60
#define OSK_TOP    17                   /* conio row of the keyboard */
#define EDIT_ROW   15                   /* conio row of the line being typed */

static char url[URL_MAX + 1] = DEFAULT_URL;
static char line[LINE_MAX + 3];
static uint8_t buf[128];
static uint8_t kbd;                     /* FUJI_NES_KBD_* */

/* ---- small screen helpers ---- */

static void blank(uint8_t y, uint8_t n)
{
  while (n--)
    cclearxy(0, y++, 32);
}

static void title(const char *s)
{
  revers(1);
  cclearxy(0, 0, 32);
  cputsxy(1, 0, s);
  revers(0);
}

static void help(const char *s)
{
  blank(27, 1);
  cputsxy(1, 27, s);
}

/* Show the last `rows` x 30 characters of s, so the end of a long string --
   where the typing happens -- is always in view. */
static void show_field(uint8_t y, uint8_t rows, const char *s)
{
  uint8_t len = strlen(s), skip = 0, i;

  if (len >= rows * 30)
    skip = len - rows * 30 + 1;
  blank(y, rows);
  gotoxy(1, y);
  for (i = skip; i < len; i++) {
    if ((i - skip) % 30 == 0)
      gotoxy(1, y + (i - skip) / 30);
    cputc(s[i]);
  }
  revers(1);
  cputc(' ');                           /* the cursor */
  revers(0);
}

/* Edit s in place with the joypad keyboard (or a real one). Returns when
   DONE is pressed. */
static void edit(char *s, uint8_t max, uint8_t y, uint8_t rows)
{
  char c;
  uint8_t len;

  show_field(y, rows, s);
  for (;;) {
    frame();
    c = osk_input(pad_poll());
    if (!c && kbd)
      c = fuji_nes_kbd_getc();
    if (!c)
      continue;
    len = strlen(s);
    if (c == OSK_DONE || c == FUJI_NES_KEY_ENTER)
      return;
    if (c == OSK_DEL) {
      if (len)
        s[len - 1] = '\0';
    } else if (c >= ' ' && c <= '~' && len < max) {
      s[len] = c;
      s[len + 1] = '\0';
    } else
      continue;
    show_field(y, rows, s);
  }
}

/* ---- the two screens ---- */

static void ask_url(void)
{
  clrscr();
  title("NETCAT");
  cputsxy(1, 3, "CONNECT TO:");
  osk_draw(OSK_TOP);
  help("A KEY  B DEL  SEL SHIFT  ST GO");
  edit(url, URL_MAX, 5, 4);
}

/* Telnet servers open with IAC option negotiation, and BBSes send ANSI
   colour codes. Neither means anything here: swallow them. */
static uint8_t skip_iac, in_esc;

static void receive(uint8_t c)
{
  if (skip_iac) {                       /* IAC cmd opt: drop cmd and opt */
    --skip_iac;
    return;
  }
  if (c == 0xFF) {
    skip_iac = 2;
    return;
  }
  if (in_esc) {                         /* ESC [ params letter */
    if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z'))
      in_esc = 0;
    return;
  }
  if (c == 0x1B) {
    in_esc = 1;
    return;
  }
  term_putc(c);
}

static void send(const char *s, uint16_t n)
{
  network_write(url, (uint8_t *) s, n);
}

static void session(void)
{
  uint16_t avail;
  uint8_t connected, err, pad, i;
  int16_t n;
  char c;

  clrscr();
  title(url);
  term_clear();
  term_flush();
  help("CONNECTING...");

  if (network_open(url, OPEN_MODE_RW, OPEN_TRANS_NONE) != FN_ERR_OK) {
    help("CANNOT CONNECT. PRESS A.");
    while (!(pad_poll() & PAD_A))
      frame();
    return;
  }
  help("ST TYPE A LINE   SEL HANG UP");
  skip_iac = in_esc = 0;

  for (;;) {
    frame();

    /* What has the other end sent? STATUS says how much is waiting. */
    if (network_status(url, &avail, &connected, &err) != FN_ERR_OK)
      break;
    if (avail) {
      n = network_read_nb(url, buf, avail < sizeof buf ? avail : sizeof buf);
      for (i = 0; n > 0 && i < (uint8_t) n; i++)
        receive(buf[i]);
      term_flush();
    } else if (!connected)
      break;

    pad = pad_poll();
    if (pad & PAD_SELECT)
      break;

    c = kbd ? fuji_nes_kbd_getc() : 0;
    if (c == FUJI_NES_KEY_ENTER)
      send("\r\n", 2);
    else if (c >= ' ' && c <= '~')
      send(&c, 1);

    if (pad & PAD_START) {              /* compose a line */
      line[0] = '\0';
      blank(EDIT_ROW, 27 - EDIT_ROW);   /* the keyboard covers the pane */
      osk_draw(OSK_TOP);
      help("ST SEND");
      edit(line, LINE_MAX, EDIT_ROW, 1);
      strcat(line, "\r\n");
      send(line, strlen(line));
      term_repaint();                   /* back from the shadow copy */
      help("ST TYPE A LINE   SEL HANG UP");
    }
  }

  network_close(url);
  help("DISCONNECTED. PRESS A.");
  while (!(pad_poll() & PAD_A))
    frame();
}

void main(void)
{
  if (!fuji_nes_present()) {
    clrscr();
    cputs("NO FUJINET CARTRIDGE");
    for (;;) ;
  }
  network_init();
  kbd = fuji_nes_kbd_detect();

  for (;;) {
    ask_url();
    session();
  }
}
