#import "../lib.typ": *
= The Network Device <ch-net>

The FujiNet’s network device is how a 5200 reaches the rest of the world: HTTP and HTTPS, TCP and UDP, FTP, TNFS, and more, all behind one small set of commands. There are eight of them, N1: to N8:, devices `$71` to `$78`, each a connection of its own. A program names the far end with a *devicespec* such as `N:http://example.com/file.txt` and then opens, reads, writes and closes it like a file.

#sect[The lifecycle]

#tbl((auto, auto, auto, 1fr),
  th[Command], th[Code], th[Parameters], th[Payload and reply],
  [OPEN], [`$4F` `'O'`], [mode, translation (one byte each)], [Payload: the devicespec. Reply: none.],
  [STATUS], [`$53` `'S'`], [two one-byte zeros], [Reply: bytes waiting (two bytes, low first), connected (1 byte), status (1 byte; 1 is good).],
  [READ], [`$52` `'R'`], [the count (two bytes)], [Reply: the bytes.],
  [WRITE], [`$57` `'W'`], [the count (two bytes)], [Payload: the bytes.],
  [CLOSE], [`$43` `'C'`], [none], [—],
)

The modes are the protocol’s: 4 to read (an HTTP GET), 8 to write (PUT), 12 to read and write (a GET that may also set headers), 13 for an HTTP POST. Translation 0 leaves the bytes alone; 1, 2 and 3 turn the far end’s line endings into CR, LF or CR LF.

Five rules make the lifecycle behave:

#nsteps(
  [*STATUS until it settles.* The adapter answers STATUS as soon as some of the response has arrived, so one reading can be a fraction of it. Read STATUS until two readings agree and are not zero.],
  [*READ at most what fits.* The reply window holds 1024 bytes, and a READ’s answer must fit in it. Ask for no more than STATUS says is waiting, and no more than 1024.],
  [*Wait long enough.* The cartridge gives OPEN, STATUS, READ and CLOSE 90 seconds each. An HTTP request is not even sent until the first STATUS or READ, so that is where a slow server shows.],
  [*Close what you open*, every time, including on the way out of a failure. The adapter keeps a connection open until it is told otherwise, even across a power cycle of the console.],
  [*Use the devicespec on every call* in C: fujinet-lib takes the unit number from it.],
)

#sect[netget]

`netget` fetches `http://127.0.0.1:8768/hello.txt`, on the bench a two-line file served by `python3 -m http.server` from `listings/fixtures`, and shows it a line at a time: LF ends a row, CR is skipped, a row stops at the edge.

#shots("asm-netget", "c-netget", caption: [netget in assembly and in C.])

#sect[In assembly]

OPEN takes its two parameters, then the devicespec, a byte at a time. The loop counts in X, because `fn_txb` sends its byte in Y:

#ex((path: "listings/asm/netget.s", from: "open:   lda     #NETDEV", to: "        ; STATUS until"), t-asm)

STATUS until two readings agree, three frames apart:

#ex((path: "listings/asm/netget.s", from: "stat:   lda     #NETDEV", to: "        ; READ:"), t-asm)

READ takes one two-byte parameter. The text is then walked straight out of the reply window with a pointer, since it can be longer than 256 bytes:

#ex((path: "listings/asm/netget.s", from: "@len:   lda     #NETDEV", to: "        ; show it"), t-asm)

#note[The library waits 12 seconds unless told otherwise. A real server can take longer than that to answer the first STATUS; set `FN_TMO` to 96 after `fn_beg` for each network command, and the cartridge’s 90 seconds will run out first.]

#sect[In C]

fujinet-lib does the STATUS loop inside `network_read()`, which returns how many bytes it read, or a negative number on failure:

#ex((path: "listings/c/netget.c", from: "    network_init();", to: "    mt_at(2, row);"), t-c)

`network_init()` does nothing on the 5200, but some platforms need it, so a portable program calls it before the first `network_open()`. The library waits at least 91 seconds for each of the long network calls. The line endings are spelled out as `0x0D` and `0x0A`, because cc65’s Atari targets read `'\n'` as the Atari’s own end-of-line, `$9B`.

#sect[JSON]

An open connection can parse what it fetched as JSON, so a program never has to. Switch the channel to JSON mode (`$FC`, mode 1 as the second of two parameters), send PARSE (`$50` `'P'`), then for each value send QUERY (`$51` `'Q'`) with the path, `/0/name` say, as the payload, and STATUS and READ the value’s text. In C that is `network_json_parse()` and `network_json_query()`. The command cards in @ch-ref-net have the details. FujiNet’s game servers also answer in plain binary when asked (`?bin=1`), which is what the games do.
