#import "../lib.typ": *
= The Network Device

The N: device is the FujiNet's reason to exist. It opens a URL --- HTTP and HTTPS, TCP and UDP, TNFS, FTP, SMB, NFS, SSH, TELNET --- and hands the bytes back through the reply window, 512 at a time. Devices `$71` to `$78` are eight independent connections; every program in this handbook uses the first. The protocols, the devicespec grammar and each scheme's behaviour are the subject of _The FujiNet Network Protocol Handbook_; this section is the five commands that carry all of them, and a program that fetches a page.

#sect[The lifecycle]

#tbl((auto, auto, 1fr),
  th[Command], th[Params], th[What it does],
  [OPEN `'O'`], [mode, translation; payload: the devicespec], [connects. Mode 4 is read, which on HTTP is GET; 8 write (PUT); 12 read/write, which on HTTP is GET with headers allowed; 13 POST. Translation 0 sends bytes as they are.],
  [STATUS `'S'`], [two zero bytes], [answers four bytes: bytes waiting, low and high; connected; and the device status, 1 for success.],
  [READ `'R'`], [one two-byte count], [answers exactly that many bytes in the reply window.],
  [WRITE `'W'`], [one two-byte count; payload: the bytes], [sends them.],
  [CLOSE `'C'`], [---], [hangs up.])

Five rules, each learned by a port in this family and each written into `netget`:

- The adapter reports STATUS as soon as *some* of the response has arrived. Take readings until two agree and the count is not zero; the Channel F port once read a plausible header followed by forty bytes of nothing.
- The fourth STATUS byte is the only place an HTTP error shows. The GET is deferred until the first STATUS, so a bad URL is a status of not-1, not a failed OPEN.
- Cap the READ at what you can show, and at 512, which is one slice of the window; the largest thing any program here reads is 240 bytes, twenty rows.
- CLOSE belongs at the start of the next request, never right after a READ: every screen here renders straight out of the reply window, and closing wipes the thing being displayed. `netget` closes after it has composed its rows, which is the same thing.
- Compare byte counts through the carry, never the sign bit. 181 minus 1 comes out negative on a signed compare, and it did.

#sect[netget in assembly]

`netget.asm` opens `N:http://127.0.0.1:8765/hello.txt` --- a small text file served by `python3 -m http.server` from `listings/fixtures/`, so that the run is reproducible; change the string and it fetches anything --- and puts the page on the screen, a line per text row.

#excerpt-at("netget.asm: OPEN", "listings/asm/netget.asm", "GOTCART:", to: "; ---------------- STATUS")

The devicespec goes into the TX stream a byte at a time from ROM, and the string's NUL is not sent: the cartridge counts the payload. Then STATUS until the count settles:

#excerpt-at("netget.asm: STATUS until it settles", "listings/asm/netget.asm", "NSTAT:  lda", to: "; ---------------- READ")

The READ's count is one parameter of two bytes, through `FNPW`, capped at 228, and the rows are composed straight out of the reply: a linefeed ends a row, a carriage return is skipped, and a thirteenth character on a line is lost.

#excerpt-at("netget.asm: READ, and a row per line", "listings/asm/netget.asm", "NREAD:  lda", to: "; ---------------- CLOSE")

`NGOACK` is the transaction's tail in one place --- commit, wait, check the ACK --- and on any failure it drops its own return address and goes to the error screen, so that no call site needs a branch after it. `NENDW` renders a row and waits for TEXTGEN to change.

#shot("asm-netget", caption: [`netget.asm`, showing the fixture file.])

#sect[netget in BASIC]

The BASIC version is the same program with the helpers of Section 8. Its settle loop draws three frames between readings, and its READ caps the count in two compares because BASIC has no 16-bit compare:

#excerpt-at("netget.bas: STATUS and READ", "listings/bas/netget.bas", "status", to: "rem show it")

#excerpt-at("netget.bas: a row per line, a row per frame", "listings/bas/netget.bas", "rem show it", to: "shown")

It is the one program in this handbook that needed the trimmed module list of Section 8: with batari Basic's stock modules it was five bytes over.

#shot("bas-netget", caption: [`netget.bas`, with five rows under the playfield.])

#sect[JSON]

An open connection can be switched to the adapter's JSON parser with `CHANNEL_MODE` (`$FC`, mode 1 in the second of two parameters), the body parsed with `PARSE` (`'P'`), and a single value fetched with `QUERY` (`'Q'`, the path such as `/0/name` as the payload) followed by STATUS and READ for its text. That is the difference between parsing JSON on a 6507 and not. The games in this family skip it by asking their servers for binary with `?bin=1`, which is what Battleship does. The cards in Section 16 have the details.
