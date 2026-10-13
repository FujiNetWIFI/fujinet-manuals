#import "../lib.typ": *
#import "../prog.typ": *

#chapter(6, "C with z88dk")

#section("General")[
C is the easiest way to write a large FujiNet program for the H89. z88dk's C compiler knows both
HDOS and CP/M, and the FujiNet project's library, fujinet-lib, wraps every FujiNet command in a C
function: `fuji_get_adapter_config()` makes the request FNHELLO built by hand in Chapter 4, and
`network_open()` opens a network channel. The three games in this Manual, and the C versions of
its other programs, are written this way.

This chapter shows how to build fujinet-lib, how to compile a program for each system, and what
to watch for. Two things need care on the H89: z88dk's start-up code for HDOS has two faults the
book works around, and HDOS turns a C program's output into capital letters unless the program
says otherwise.
]

#section("What You Need")[
z88dk, set up as in Chapter 4, and fujinet-lib. No release of fujinet-lib includes the H89 yet,
so it is built from its source:

#steps(
  [Get fujinet-lib from #text(font: f-sans, size: 0.9em)[github.com/FujiNetWIFI/fujinet-lib], on the
   branch this Manual describes (Chapter 1).],
  [In its directory, type: \ `make h89-hdos/r2r h89-cpm/r2r`],
  [The libraries are `r2r/h89-hdos/fujinet.h89-hdos.lib` and `r2r/h89-cpm/fujinet.h89-cpm.lib`; the
   header files are in `include/`.],
)

#note[Use the `/r2r` targets. They build the library and copy it to `r2r/`; the plain `h89-hdos`
target leaves a library a program can link with an older copy of, and the program then never
reaches the FujiNet.]

The library's test programs are built the same way, in its `testing` directory:
`make -C testing h89-hdos/r2r h89-cpm/r2r`. They are described at the end of this chapter.
]

#section("A First Program")[
HELLO is FNHELLO again, in C:

#plisting("hello", size: code-size)

`fuji_get_adapter_config()` fills in an `AdapterConfig` structure, which has the same layout as
the reply (Chapter 8), and returns `true` for an ACK. That is all there is to it. fujinet-lib
starts the card the first time it is called, the way `card_on` does, and makes the whole exchange
itself.
]

#section("Compiling for CP/M")[
#code("zcc +cpm -create-app -D__H89__ -I$FNLIB/include \\
    -L$FNLIB/r2r/h89-cpm -lfujinet.h89-cpm.lib \\
    -o HELLO hello.c")

- `+cpm` chooses CP/M.
- `-create-app` makes `HELLO.COM`, ready to run.
- `-D__H89__` tells fujinet-lib's headers it is the H89. Without it they do not know which computer
  this CP/M runs on, and the program will not compile.
- `-I` and `-L` say where fujinet-lib's headers and library are (`FNLIB` is its directory).
- `-l` names the library. Give it in full, `.lib` and all: the dot in the name stops z88dk adding
  `.lib` for you, and without it z88dk reports that it cannot find the file.

The program is loaded at 0100H, and z88dk sets the stack at the top of the TPA, under the BDOS.
]

#section("Compiling for HDOS")[
#code("zcc +hdos -startup=3 -Cz--abs -create-app -D__H89__ \\
    -pragma-define:CRT_ORG_CODE=0x2A80 \\
    -pragma-define:REGISTER_SP=0x2A80 \\
    -pragma-define:CRT_ENABLE_COMMANDLINE=0 \\
    -pragma-define:CLIB_DISABLE_FGETS_CURSOR=1 \\
    -I$FNLIB/include -L$FNLIB/r2r/h89-hdos -lfujinet.h89-hdos.lib \\
    -o HELLO hello.c")

- `+hdos -startup=3` chooses HDOS, and the start-up that takes its arguments from the command line
  rather than prompting for them.
- `-Cz--abs -create-app` makes an .ABS file.
- The three `-pragma-define` lines set where the program loads, where its stack is, and turn off
  z88dk's own command-line handling. They are explained below; use them as they stand.
- `CLIB_DISABLE_FGETS_CURSOR` stops `fgets()` drawing a cursor of its own, which the H19 does not
  need.

The book's `tools/cc.sh hdos NAME file.c ...` and `tools/cc.sh cpm NAME file.c ...` give exactly
these commands.

#sub("Where the program loads")
HDOS loads programs at 2280H, which Heath's documents write in split octal as 042.200. Left to
itself, z88dk puts an HDOS program at 4480H: someone read 042200 as one octal number, which it
is not. The program still runs --- HDOS will load a program anywhere above 2280H --- but the 8.6K
below it is wasted, and z88dk's stack sits there, just under the program.

The book does what FujiNet CONFIG does: it loads the program at 2A80H and puts the stack just under
it, at 2A80H, so that the stack has the 2K between 2280H and 2A80H to itself and can never run into
the program, its data, or HDOS's device drivers above. A program that wants every byte can load at
2280H instead, and set `REGISTER_SP` to the top of the memory it knows it has.

#warning[z88dk's `hdos.def` gives HDOS's system values (S_SYSM, S_USRM and the rest) 2000H too high,
for the same reason. S.SYSM is at 20D0H, not 40D0H. The Appendix lists the right addresses.]

#sub("The command line")
z88dk's HDOS start-up code saves the stack pointer HDOS gave it, moves the stack, and then takes
the old value back off the *new* stack. So it splits up the command line with the wrong length,
and `argv[]` comes out wrong: given `HELLO WORLD`, MEMPROBE's first argument printed as junk.

The cure is to turn z88dk's handling off (`CRT_ENABLE_COMMANDLINE=0`, above) and split the command
line yourself, from where HDOS left it. `hdos_args()`, in the book's `src/c/common`, does that.
Call it first thing:

#code("int main(int argc, char *argv[])
{
    ARGS(argc, argv);       /* HDOS: argc and argv from the command line */
    ...")

`ARGS` does nothing under CP/M, where z88dk's own handling is correct.

#plisting("hdosargs", size: 6.4pt)
]

#section("Where Everything Ends Up")[
MEMPROBE (in `src/c/probe`) prints where its code, its data and its stack are, and what it was given
on the command line. Here it is under each system, built as above:

#grid(columns: (1fr, 1fr), column-gutter: 0.2in,
  session("memprobe-hdos", rows: (17, 24), size: 7.6pt),
  session("memprobe-cpm", rows: (7, 15), size: 7.6pt))

Under HDOS, the program starts at 2A80H (`main` is a little after it), its data ends near 3B09H,
and the stack is just under 2A80H. S.SYSM shows that HDOS's resident part starts at EDB1H in this
56K machine, so everything from 3B40H up to there is free. Under CP/M the program starts at 0100H,
the BDOS at D806H, and the stack is just under it.
]

#section("The Console")[
z88dk's `printf()` and `puts()` go through the system's ordinary console calls, which is fine for
text. But HDOS normally maps lower case to upper case on the way out, so a C program that prints
"Hello" shows HELLO, as the first run of HELLO above does.

For anything more than plain text --- escape sequences for the H19, graphics characters, a key the
moment it is struck --- use the book's `h89con.c`. `con_init(0)` stops HDOS's case mapping;
`con_init(1)` also turns off echo and CTRL-C handling and gives the program each key as it is
struck. `con_getc()` returns a key or -1 at once, and `con_putc()` sends a byte exactly as it is.
Under CP/M these go to the BIOS's console routines directly, which do the same. Call `con_exit()`
before the program ends, to put the console back.

#plisting("h89con", size: 6.4pt)
]

#section("Files")[
Under CP/M, z88dk's `fopen()`, `fread()`, `fwrite()` and `fclose()` work as on any C system, through
the BDOS. Under HDOS they work through HDOS's channels, with a few limits: at most a handful of
files open at once (z88dk's default is 3, including the console), and file names in HDOS's form,
`SY1:NAME.EXT`. NGET and NPUT (Chapter 14) use them under both systems.

A text file written under CP/M ends with CTRL-Z (1AH) in the rest of its last 128-byte record;
under HDOS, the rest of its last 256-byte sector is zeros. A program that reads files written on
the other system, or fetched from the network, should stop at whichever it finds.
]

#section("Mixing C and Assembly")[
z88dk lets C call assembly in two ways. Short pieces go inside a C function between `#asm` and
`#endasm`; `h89con.c` makes its HDOS system calls that way. Longer ones go in their own `.asm` file
with a `PUBLIC` label, assembled by `zcc` along with the C files, and declared in C as an
`extern` function.

The compiler fujinet-lib is built with, sccz80, passes arguments on the stack, last argument
first, and returns a value in HL. A function marked `__z88dk_fastcall` takes its one argument in
HL instead, as `con_putc()` does. Keep IX and IY: the C code uses them. HDOS's system calls leave
them alone; a CP/M BIOS may not, which is why `h89con.c` saves them around each BIOS call.

#warning[In the version of z88dk this Manual used, the remainder of an `unsigned long` by a constant
came out wrong in ISS.C (Chapter 15): `t % 60` gave the remainder of `t`'s low 16 bits. Division was
right. If a long remainder matters, check it, or do as ISS.C does: subtract the whole parts and take
the remainder of what is left in 16 bits.]

#note[fujinet-lib is built with sccz80. Compiling your own program with z88dk's other compiler,
zsdcc (`-compiler=sdcc`), and linking it with fujinet-lib has not been tried.]
]

#section("fujinet-lib's Own Tests")[
fujinet-lib comes with test programs that exercise the library against a running FujiNet. They are
a good way to check a new build, and the source of each is a handy example. They are in fujinet-lib's
`testing` directory: with z88dk on the PATH, `make h89-hdos h89-cpm` there builds them into
`r2r/h89-hdos` and `r2r/h89-cpm`.

They need the FujiNet on the Internet, since they talk to public servers such as `httpbin.dev`,
`tcpbin.com` and `tnfs.fujinet.online`. FUJIDEV and DISK change the FujiNet's host and drive slots
as they go, and DISK copies a 160K disk image to the SD card, so run them on a FujiNet whose set-up
you can put back.

The table that follows shows how they fared on this Manual's set-up, with fujinet-lib v5.0.1 and the tests
from its commit 5fadd0d. Each program stops at its first failure, so "4 of 5" means that the fifth
test failed and the rest were never run.

Three of the failures are mistakes in the test programs, not in fujinet-lib or the FujiNet. Each
was corrected in a copy of the tests, which was then run again ("Corrected" in the table). The
numbers are those of the errata list (Appendix).

- *NETWORK* takes the H89's line ending to be LF, but the FujiNet's is CR LF (Chapter 10), so the
  echo of its line comes back a byte longer (T1).
- *DISK* looks for a file's name 13 bytes into a directory entry, but on this bus the header is 12
  bytes (Chapter 8) (T2).
- *FUJIDEV* puts back an empty drive slot with FUJI_SET_DEVICE_FULLPATH, which cannot empty a slot
  (Chapter 8), and leaves drive slot 0 named `/test_filename` (T3).

The fourth failure is real. FUJI_COPY_FILE took longer than the 15 seconds that fujinet-lib waits
for a reply (Chapter 8), and after that every reply was one behind. DISK was run again, corrected and
linked with a copy of fujinet-lib in which `TIMEOUT_SLOW` is 60 seconds.
]

// across the page, in one piece: a broken table would lose its heading
#context {
  let t = json("../data/libtests.json")
  stable((0.85in, 0.6in, 0.6in, 1fr), size: 7.4pt, breakable: false,
    th[Program], th[HDOS], th[CP/M], th[Notes],
    ..t.tests.map(x => (raw(x.name), x.hdos, x.cpm, x.note)).flatten())
}
