/* book.h -- what the handbook's C programs share beyond antic.h. */
#ifndef BOOK_H
#define BOOK_H

/* A NUL-terminated string at the write position, up to the row's end. */
#define mt_puts(s) mt_text((s), MT_COLS)

#endif /* BOOK_H */
