#import "../lib.typ": *
#import "../prog.typ": *

#chapter(13, "NETCAT")

#section("General")[
NETCAT turns the H89 into a terminal on the network. Give it the devicespec of a bulletin board,
a Telnet server or any TCP service, and it connects, sends what you type, and shows what comes
back, until the far end hangs up or you strike CTRL-\]. It is the shortest program in this Manual
that does something you will use, and the pattern of its main loop --- keyboard, STATUS, READ,
around again --- is the pattern of every program that talks to the network.

There are two versions, NETCAT.ASM and NETCAT.C. They behave the same, and each makes a program
called NETCAT for HDOS and for CP/M.
]

#section("Using NETCAT")[
#steps(
  [Give NETCAT the devicespec on the command line: \
   #typed("NETCAT N:TELNET://BBS.FOZZTEXX.COM/") #ret],
  [Or run it with nothing after its name, and answer its question. Just #ret connects to
   BBS.FOZZTEXX.COM, a bulletin board run by one of the FujiNet's developers.],
  [Talk to the far end. Everything you type goes to it; everything it sends is shown.],
  [To leave, log off the far end, or strike CTRL-\] (hold CTRL and press the \] key).],
)

The devicespec may be any stream the FujiNet knows (Chapter 11): `N:TELNET://host/` for bulletin
boards and Telnet servers, `N:TCP://host:port/` for anything else. NETCAT adds the `N:` if you
leave it off.

#note[HDOS and CP/M both turn a typed command line into capital letters. Host names don't care,
but if a devicespec must have small letters in it --- a path, a password --- run NETCAT with nothing
after its name and type the devicespec at its question, which keeps what you type as you type it.]

Here NETCAT is talking to the book's test board (`tools/helpers.py`, which you can run on any
computer on your network) under HDOS, and then under CP/M:

#session("netcat-hdos", rows: (10, 22))
#session("netcat-cpm", rows: (7, 20), under: ((9, 43, 70),))
]

#section("How It Works")[
NETCAT does four things:

+ It gets the devicespec, from the command line or by asking.
+ It opens network channel 1 on it, in mode 12 (read and write) with no translation, so every
  byte passes untouched in both directions.
+ It loops: if a key has been struck, it sends it; then it asks the channel's STATUS; if bytes are
  waiting, it reads them, no more than its buffer holds, and types them on the screen. If nothing
  is waiting and STATUS says the connection is gone, the far end has hung up.
+ It closes the channel.

There is no waiting anywhere in the loop. NETCAT never asks the FujiNet for bytes it does not have
(Chapter 10 explains why that matters: a READ for more than is waiting fails, and loses what was
there), and never waits for a key. So keys go out the moment they are struck, and bytes appear the
moment they arrive.

#sub("The H19 and ANSI")
Bulletin boards send the escape sequences of the ANSI standard (VT100 terminals and the IBM PC's
ANSI.SYS), not the H19's own. Fortunately the H19 understands them too, in its *ANSI mode*. NETCAT
sends `ESC <` when the connection opens, which puts the H19 in ANSI mode, and `ESC [ ? 2 h` when
it closes, which puts it back in Heath mode, so the screen is as you left it. In ANSI mode the H19's
keypad and arrow keys send ANSI sequences too, which is what the far end expects.

For a Telnet server, tell it what you are with the devicespec's query:
`N:TELNET://BBS.FOZZTEXX.COM/?term=ansi&cols=80&rows=24`.

#sub("Line endings")
NETCAT opens the channel with no translation, so the far end's line endings reach the H19 as they
are: most servers send CR LF, which the H19 shows correctly. The RETURN key sends CR, as a terminal
should.
]

#section("The Assembly Version")[
NETCAT.ASM opens the channel with a request block whose payload is the devicespec; its length is
set just before the call, since it depends on what was typed:

#snip("netcat.open", "asm", caption: [NETCAT.ASM --- open the channel])

The main loop is the heart of the program. `conin` returns with carry set when no key is waiting;
a key goes out in a one-byte WRITE. Then STATUS fills `nstat`: two bytes saying how much is waiting,
a byte that is 1 while the connection is up, and an error code (Chapter 10). The READ's length field
is stored into its request block before each call:

#snip("netcat.loop", "asm", caption: [NETCAT.ASM --- the loop])

The requests themselves are five blocks:

#snip("netcat.requests", "asm", caption: [NETCAT.ASM --- the requests])
]

#section("The C Version")[
NETCAT.C does the same with fujinet-lib, and with the book's `h89con.c` for the keyboard and
screen. `con_init(1)` gives it each key as it is struck, with no echo (the far end echoes) and no
CTRL-C handling, so every key, CTRL-C included, goes to the far end.

#snip("netcat.loop", "c", caption: [NETCAT.C --- the loop])

`network_status()` returns the same three things the assembly version takes from the reply, and
`network_read()` reads the bytes. Note `len`, which never asks for more than is waiting.
]

#section("Listings", balance: false)[
#plisting("netcat-asm")
#plisting("netcat-c")
]
