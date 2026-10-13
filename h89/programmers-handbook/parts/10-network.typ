#import "../lib.typ": *
#import "../prog.typ": *

#chapter(10, "The Network Device")

#section("General")[
The FujiNet keeps eight *network channels*, devices 71H to 78H. Each can be open on one thing at a
time: a file on a web server, a TCP connection, a directory on the microSD card, a JSON document.
Chapter 11 lists the kinds of thing; this chapter gives the commands.

Every channel lives the same way:

+ *OPEN* it on a devicespec, such as `N:HTTP://192.168.1.10/hello.txt`, with a mode (read, write,
  and others) and a line-ending translation.
+ Ask its *STATUS*: how many bytes are waiting, whether it is still connected, and what went wrong
  if anything did.
+ *READ* what is waiting --- never more --- or *WRITE* to it.
+ *CLOSE* it.

A channel never tells the H89 that data has arrived: there is no interrupt (Chapter 2). A program
asks STATUS, and asks again. NETCAT's loop (Chapter 13) is the pattern.

#warning[Every network command that takes fields must have all of them. A command that finds a field
missing stops the firmware (Chapter 3): OPEN needs two, and so do SET_PARSER, TRANSLATION,
SET_PARAMETER, SET_HTTP_MODE and the six file system commands, even where a field is not used.]
]

#section("The Examples in This Chapter")[
The examples come from EXNET.ASM and EXNET.C, which use the channels like this, all at once:

#stable((0.5in, 1fr), size: 7.6pt,
  th[Unit], th[Open on],
  [71H], [a web page (`hello.txt`), then the channel settings and errors],
  [72H], [a JSON document],
  [73H], [web requests: POST, PUT, DELETE],
  [74H], [HTTP headers],
  [75H], [a TCP connection to the test board],
  [76H], [a TCP server, which the test client connects to],
  [77H], [UDP],
  [78H], [files on the microSD card],
)

The servers were the book's test servers (`tools/helpers.py`) on the same computer as fujinet-pc,
so the devicespecs in the bytes say 127.0.0.1. On a real card use the server's address on your
network.
]

#section("Opening and Closing", balance: false)[
#cmdcard("Open", dev: "71H--78H", cmd: 0x4F, equ: "NET_OPEN",
  lines: (("Fields", [2 bytes: the mode; the translation]),
    ("Payload", [the devicespec (up to 256 bytes)]), ("Reply", [ACK, or NAK])))
Opens the channel on a devicespec (Chapter 11). Any channel already open on the unit is closed first
--- even if this OPEN then fails. The payload is the devicespec; a zero or a CR LF ends it, and an
`N:` or `Nn:` in front is optional (the device number chooses the unit).

#values-table([Mode], [Means],
  [04H], [Read. For HTTP, a GET.],
  [05H], [HTTP DELETE.],
  [06H, 07H], [A directory listing. The translation field then chooses the listing's form.],
  [08H], [Write: create or replace a file. For HTTP, a PUT.],
  [09H], [Append to a file. For HTTP, a DELETE that may send headers.],
  [0CH], [Read and write a file. For HTTP, a GET that can send and collect headers.],
  [0DH], [HTTP POST.],
  [0EH], [Meant as HTTP PUT with headers --- but a POST is sent (see below).],
)

#values-table([Translation], [Means], first: 0.8in,
  [0], [None: bytes pass as they are.],
  [1], [The far end uses CR: each CR read becomes CR LF; CR LF written becomes CR.],
  [2], [The far end uses LF: likewise with LF.],
  [3], [The far end uses CR LF: nothing changes, since the H89's line ending is CR LF.],
)

Streams (TCP, UDP, Telnet) take any mode; mode 12 is the usual. For a file system, a mode not in the
table is worse than refused: TNFS and SD stop the firmware.

#warning[Mode 0EH sends a POST, not a PUT. Use mode 08H for a PUT. And an HTTP DELETE (05H or 09H)
is sent only when the program next asks STATUS or READs; a CLOSE straight after the OPEN sends
nothing at all.]
#examples("net.open")

#cmdcard("Open: Other Kinds of Channel", dev: "71H--78H", cmd: 0x4F)
The same command for the other examples' channels. A TCP connection, mode 12, no translation:
#examples("net.open.tcp")
A web page with translation 2, so its LF line endings arrive as CR LF:
#examples("net.open.translated", only: 0)
A file on the microSD card, opened for reading, to seek in later:
#examples("net.open.file")
And an OPEN that fails: nothing is listening on port 1, so the FujiNet answers NAK, and STATUS (later
in the chapter) says why:
#examples("net.open.refused")

#cmdcard("Close", dev: "71H--78H", cmd: 0x43, equ: "NET_CLOSE",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [ACK])))
Closes the channel. For a file being written, this is when the last of it is written; for an HTTP
PUT, this is when the request is sent, with everything written as its body. Closing a closed channel
does no harm.
#examples("net.close")
]

#section("Status", balance: false)[
#cmdcard("Status", dev: "71H--78H", cmd: 0x53, equ: "NET_STATUS",
  lines: (("Fields", [none]), ("Payload", [none]),
    ("Reply", [4 bytes: bytes waiting (word, low first), connected, error])))
How the channel stands:

#fields-table(
  [0], [2], [How many bytes the next READ can return.],
  [2], [1], [1 while the connection is up, or the file or listing has more to give; 0 when it is
    done.],
  [3], [1], [The last error: 1 means all is well; 136 the end of the data; others are in the
    Appendix.],
)

For an HTTP channel the first STATUS is when the request is sent: it waits for the server's answer
to begin. For TCP and UDP, STATUS collects what has arrived. A program that only reads after STATUS
never asks for more than is there.

The example comes just after the OPEN of `hello.txt`: 55 bytes waiting (37H), connected 0 because
the test server had already sent the whole page, error 1.
#examples("net.status")

#cmdcard("Status of a Closed Channel", dev: "71H--78H", cmd: 0x53)
With nothing open, STATUS answers 00 00 00 CFH: error 207, *not connected*. The file system
commands later in this chapter leave their unit like this.
#examples("net.status.closed")

#cmdcard("Status at the End", dev: "71H--78H", cmd: 0x53)
After the whole page has been read: nothing waiting, error 136, the end.
#examples("net.status.eof")

#cmdcard("Status after a Failed Open", dev: "71H--78H", cmd: 0x53)
After the refused OPEN above: error 200, *connection refused*.
#examples("net.status.refused")
]

#section("Reading and Writing", balance: false)[
#cmdcard("Read", dev: "71H--78H", cmd: 0x52, equ: "NET_READ",
  lines: (("Fields", [a word: the most bytes to return]), ("Payload", [none]),
    ("Reply", [up to that many bytes])))
Takes bytes the channel has waiting. Ask for what STATUS said, or less: the reply may be shorter than
asked, and the reply's length says how much came.

#warning[A READ for more than is waiting can fail, and lose what *was* waiting. On a TCP channel, if
nothing was waiting, the FujiNet asks the network for the whole amount at once, and when fewer arrive
it answers NAK and throws away the bytes that did come. Always ask STATUS first, and read no more
than it says.]
#examples("net.read")

#cmdcard("Read Past the End", dev: "71H--78H", cmd: 0x52)
With nothing left, READ answers NAK.
#examples("net.read.eof")

#cmdcard("Reading Something Big", dev: "71H--78H", cmd: 0x52)
A file longer than one reply, read in pieces of 2048 bytes: STATUS, READ, and again until STATUS
says the end. Here `data.bin`, 3000 bytes, comes as 2048 and 952:
#examples("net.read.loop", only: (2, 4))

#note[Over HTTP, a READ larger than what is buffered (with no STATUS first) does work: the FujiNet
returns what it has. But fujinet-lib's `network_bus_read()` then reports the length you asked for, not
the length that came; use `network_read()`, which asks STATUS first.]

#cmdcard("Write", dev: "71H--78H", cmd: 0x57, equ: "NET_WRITE",
  lines: (("Fields", [a word: how many bytes]), ("Payload", [those bytes]), ("Reply", [ACK])))
Sends bytes. The field and the payload's length must agree: a payload shorter than the field is made
up with zeros. Here a line goes to the test board over TCP:
#examples("net.write")

#cmdcard("Reading a TCP Reply", dev: "71H--78H", cmd: 0x52)
The test board echoes each key as it comes, so its answer arrives in pieces. A program reads until
nothing more comes for a while --- here, half a second:
#examples("net.read.tcp_reply", only: (0, 1, 2, 3))

#cmdcard("When the Far End Hangs Up", dev: "71H--78H", cmd: 0x53)
After `BYE`, the board says goodbye and hangs up. STATUS then says not connected, error 136 --- with
the goodbye's 15 bytes still waiting to be read. The far end has gone only when *nothing* is waiting
and it is not connected.
#examples("net.status.hangup")
]

#section("JSON and Other Parsers", balance: false)[
A channel can parse what it reads. With the parser set to JSON, the FujiNet reads the whole document
into its own memory, and from then on READ returns only the values a program asks for, one at a time,
by *JSON Pointer* (Chapter 15 explains them, and uses them). The parser can also be HTML, with CSS
selectors, or XML.

#cmdcard("Set Parser", dev: "71H--78H", cmd: 0xFC, equ: "NET_SET_PARSER",
  lines: (("Fields", [2 bytes: 0 (not used, but send it); the parser]),
    ("Payload", [none]), ("Reply", [ACK])))
Chooses the channel's parser: 0 none, 1 JSON, 2 HTML, 3 XML. Send it after OPEN: an OPEN sets the
parser back to none. With a parser set, WRITE always fails, so finish writing (an HTTP POST's body)
first.

#warning[Never send SET_PARSER to a unit with no channel open. It is accepted, but a later READ,
QUERY, SEEK or TELL on that unit stops the firmware.]
#examples("net.set_parser")

#cmdcard("Parse", dev: "71H--78H", cmd: 0x50, equ: "NET_PARSE",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [ACK, or NAK if it will not parse])))
Reads the whole document and parses it. For HTTP, this is when the request goes. NAK, and error 213
in STATUS, if the document is not good JSON. Afterwards STATUS shows nothing waiting and error 136:
the document has been read.

#warning[On a connection that stays open (TCP), PARSE does not finish until the far end hangs up.]
#examples("net.parse")

#cmdcard("Query", dev: "71H--78H", cmd: 0x51, equ: "NET_QUERY",
  lines: (("Fields", [none]), ("Payload", [a JSON Pointer, such as `/name`]),
    ("Reply", [ACK; then STATUS and READ for the value])))
Asks for one value. The answer is put in the channel's buffer as text, followed by a line feed (0AH):
a string without its quotes, a number as digits, `TRUE`, `FALSE` or `NULL`. STATUS gives its length,
and READ takes it. The payload is the pointer itself; a zero ends it.
#examples("net.query")

#cmdcard("Query an Array", dev: "71H--78H", cmd: 0x51)
Array elements count from 0: `/ports/2` is the third.
#examples("net.query.array")

#cmdcard("Query Something Missing", dev: "71H--78H", cmd: 0x51)
A pointer that names nothing still gets ACK, but STATUS then shows nothing waiting.
#examples("net.query.missing")

#warning[A query whose answer contains an empty array, `[]`, stops the firmware.]

#cmdcard("Set Parameter", dev: "71H--78H", cmd: 0xFB, equ: "NET_SET_PARAMETER",
  lines: (("Fields", [2 bytes: which; the value]), ("Payload", [none]), ("Reply", [ACK])))
Tunes the parser: with 1, the value is the line ending put after each answer (normally 0AH); with 0,
flags for HTML and XML text. Send it after SET_PARSER, which starts a fresh parser. The example makes
the line ending CR, then asks for `/machine`.
#examples("net.set_parameter")
]

#section("HTTP", balance: false)[
An HTTP channel is opened with the method as its mode (OPEN's table, above). Reading the reply is
ordinary: STATUS, then READ. Three things need more: sending a body (POST, PUT), sending request
headers, and reading response headers. All three use SET_HTTP_MODE to say what the next WRITEs and
READs mean.

#values-table([Mode], [WRITE and READ then mean],
  [0], [Body: READ returns the reply's body. For PUT, WRITE adds to the body.],
  [1], [Collect: each WRITE names a response header to keep. Mode 0CH GETs only.],
  [2], [Get headers: each READ returns one kept header's value.],
  [3], [Set headers: each WRITE is a request header, `Name: value`.],
  [4], [Post data: WRITE adds to a POST's (or PUT's) body.],
)

#cmdcard("Set HTTP Mode", dev: "71H--78H", cmd: 0x4D, equ: "NET_SET_HTTP_MODE",
  lines: (("Fields", [2 bytes: 0 (not used, but send it); the mode]),
    ("Payload", [none]), ("Reply", [ACK])))
Changes what WRITE and READ mean on an HTTP channel. NAK on any other kind of channel. Changing mode
throws away anything buffered.

A POST, step by step: open with mode 0DH, set mode 4, WRITE the body, set mode 0, then STATUS (which
sends the request) and READ the answer.
#examples("net.set_http_mode")

#cmdcard("POST: the Body", dev: "71H--78H", cmd: 0x57)
The body, `name=H89&cpu=Z80`:
#examples("net.write.http_post")

#cmdcard("POST: Back to the Body Mode", dev: "71H--78H", cmd: 0x4D)
#examples("net.set_http_mode.body")

#cmdcard("POST: Sending It", dev: "71H--78H", cmd: 0x53)
This STATUS sends the request. The test server answered "GOT 16 BYTES", 14 bytes with its CR LF:
#examples("net.status.http_post")
#examples("net.read.http_post")

#cmdcard("PUT", dev: "71H--78H", cmd: 0x57)
A PUT (mode 08H) is simpler: WRITE the body in mode 0, then CLOSE, which sends it.

#warning[Don't ask a PUT channel for STATUS. The first STATUS sends the PUT; CLOSE then sends it
again.]
#examples("net.open.http_put")
#examples("net.write.http_put")
#examples("net.close.http_put")

#cmdcard("DELETE", dev: "71H--78H", cmd: 0x4F)
A DELETE (mode 05H) goes when the program asks STATUS:
#examples("net.open.http_delete")
#examples("net.status.http_delete")

#cmdcard("DELETE That Is Never Sent", dev: "71H--78H", cmd: 0x4F)
OPEN, then CLOSE: the test server never heard of `/never.txt`.
#examples("net.close.unsent")

#cmdcard("Mode 0EH Sends POST", dev: "71H--78H", cmd: 0x4F)
"PUT with headers" (0EH) goes out as a POST: the test server's log shows the method.
#examples("net.open.http_put_h", only: (0, -1))

#cmdcard("Request Headers", dev: "71H--78H", cmd: 0x57)
On a channel opened with mode 0CH (or 09H, 0DH), set mode 3 and WRITE each header as
`Name: value`, with exactly one space after the colon. Here `X-Machine: H89`:
#examples("net.open.http_get_h")
#examples("net.set_http_mode.set_headers")
#examples("net.write.header")

#cmdcard("Response Headers", dev: "71H--78H", cmd: 0x52)
To read headers from the reply: set mode 1, WRITE the name of each header to keep (mode 0CH GETs
only), then set mode 2. The request goes at the next STATUS. Each READ then gives one value, ending
in 9BH (the Atari's end of line, which the FujiNet uses here on every computer), in alphabetical order
of the headers' names --- not the order they were asked for.
#examples("net.set_http_mode.collect")
#examples("net.write.collect")
#examples("net.set_http_mode.get_headers")
#examples("net.read.header")
]

#section("TCP Servers", balance: false)[
A TCP channel opened with no host, `N:TCP://:7803/`, *listens*: other computers can connect to the
FujiNet on that port, and the H89 can serve them.

#cmdcard("Listening", dev: "71H--78H", cmd: 0x4F)
Open the server, then watch STATUS: on a listening channel, "connected" is 1 when a caller is
waiting to be accepted.
#examples("net.open.tcp_server")
#examples("net.status.listen", only: -1)

#cmdcard("Accept", dev: "71H--78H", cmd: 0x41, equ: "NET_ACCEPT",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [ACK, or NAK])))
Takes the waiting caller. From then on READ, WRITE and STATUS on the channel talk to it, and the
channel goes on listening for the next. NAK if nobody is waiting (error 209) or the channel is not a
server (208).
#examples("net.accept")

#cmdcard("Talking to the Caller", dev: "71H--78H", cmd: 0x52)
The test client sends `PING`; the H89 answers `PONG`:
#examples("net.read.server", only: (-2, -1))
#examples("net.write.server")

#cmdcard("Close Client", dev: "71H--78H", cmd: 0x63, equ: "NET_CLOSE_CLIENT",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [*NAK* if it hung up on a caller])))
Hangs up on the accepted caller, and goes on listening.

#warning[The answer is backwards: NAK means the caller *was* hung up on, and ACK that there was no
caller to hang up on. fujinet-lib's `network_close_client()` passes this on, so it reports failure
when it succeeded.]
#examples("net.close_client", only: -1)
#examples("net.close_client.none")
]

#section("UDP", balance: false)[
A UDP channel sends and receives *datagrams*, single messages, rather than a stream. Open it on a
port, `N:UDP://:7804/`, to receive; SET_DESTINATION says where WRITE sends.

#cmdcard("Reading a Datagram", dev: "71H--78H", cmd: 0x52)
#warning[STATUS does not count the datagram that is waiting, only the one after it: with one
datagram in, it says 0 waiting. So a UDP program asks STATUS, then READs anyway, with room for the
largest datagram it expects: the reply is the datagram. (If nothing has come, the READ answers NAK;
if the FujiNet's buffer is empty but a datagram is in, it is padded with zeros to the length asked.)]
#examples("net.open.udp")
#examples("net.read.udp")

#cmdcard("Get Remote", dev: "71H--78H", cmd: 0x72, equ: "NET_GET_REMOTE",
  lines: (("Fields", [none]), ("Payload", [none]),
    ("Reply", [256 bytes: who sent the last datagram, as text])))
Where the last datagram came from, as `address:port`, then 9BH and a zero; the rest of the 256 bytes
is left over. Before any datagram it reads `255.255.255.255:0`.

#warning[GET_REMOTE writes its text over the channel's buffer: a datagram not yet read loses its first
bytes. Read first, then ask.]
#examples("net.get_remote")

#cmdcard("Set Destination", dev: "71H--78H", cmd: 0x44, equ: "NET_SET_DESTINATION",
  lines: (("Fields", [none]), ("Payload", [`N:address:port`, ending in a zero]), ("Reply", [ACK])))
Where the next WRITE sends its datagram. Write it exactly `N:address:port`, with a zero after: on the
card, `N7:...` gets the address wrong, and on fujinet-pc a payload without the zero is read past its
end.

#note[Any STATUS after a datagram arrives sets the destination to that datagram's sender, so a server
can simply answer whoever wrote.]
#examples("net.set_destination")
#examples("net.write.udp")
]

#section("Files and Directories", balance: false)[
On a file system channel (TNFS, SD, SMB, NFS, FTP, SFTP, and HTTP for some), OPEN reads, writes or
lists, and six commands work on files directly. The examples use the microSD card (unit 78H).

#cmdcard("Directory Listing", dev: "71H--78H", cmd: 0x4F)
OPEN with mode 6 lists a directory, as text lines ending CR LF. The translation field chooses the
form: 00H short lines, `NAME EXT size date`; 80H long lines, the whole name, with `/` after
directories; 83H the bare names.

#note[In the short form the date is always 1-01-24 12:00p, a placeholder. On fujinet-pc every size
showed 0, as here.]
#examples("net.open.dir")
#examples("net.read.dir")

#cmdcard("Writing a File", dev: "71H--78H", cmd: 0x57)
OPEN with mode 8, WRITE, CLOSE:
#examples("net.open.write")
#examples("net.write.file")
#examples("net.close.file")

#cmdcard("Seek", dev: "71H--78H", cmd: 0x25, equ: "NET_SEEK",
  lines: (("Fields", [4 bytes: the position, from the start]), ("Payload", [none]), ("Reply", [ACK])))
Moves to a byte in the open file. TNFS, SD, SMB, NFS, SFTP and HTTP (GET only) can seek; others answer
NAK. The example opens `disk.img` and seeks to 1536, the start of sector 3, which is all 03H.
#examples("net.seek")

#cmdcard("Tell", dev: "71H--78H", cmd: 0x26, equ: "NET_TELL",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [4 bytes: the position, low first])))
Where the next READ will come from. FFFFFFFFH if the channel cannot seek.

#warning[With no channel open, the four bytes are left over from the FujiNet's memory. On TNFS and SD,
TELL throws away bytes STATUS had already read ahead.]
#examples("net.tell")

#cmdcard("Rename", dev: "71H--78H", cmd: 0x20, equ: "NET_RENAME",
  lines: (("Fields", [2 bytes: 0, 0 (send them)]), ("Payload", [`devicespec,newname`]),
    ("Reply", [ACK])))
Renames a file: the payload is its devicespec, a comma, and the new name (in the same directory).

#warning[The six file commands --- RENAME, DELETE, MKDIR, RMDIR, LOCK and UNLOCK --- each use the
unit as a scratch channel: whatever was open on it is thrown away, *without* being closed (a file
being written loses its end), and the unit is left closed. Use a spare unit for them. And if one
fails, STATUS afterwards says only 207 (not connected); the reason is lost.]
#examples("net.rename")

#cmdcard("Delete", dev: "71H--78H", cmd: 0x21, equ: "NET_DELETE",
  lines: (("Fields", [2 bytes: 0, 0]), ("Payload", [the devicespec]), ("Reply", [ACK])))
Deletes a file.
#examples("net.delete")

#cmdcard("Make Directory", dev: "71H--78H", cmd: 0x2A, equ: "NET_MKDIR",
  lines: (("Fields", [2 bytes: 0, 0]), ("Payload", [the devicespec]), ("Reply", [ACK])))
#examples("net.mkdir")

#cmdcard("Remove Directory", dev: "71H--78H", cmd: 0x2B, equ: "NET_RMDIR",
  lines: (("Fields", [2 bytes: 0, 0]), ("Payload", [the devicespec]), ("Reply", [ACK])))
#examples("net.rmdir")

#cmdcard("Lock and Unlock", dev: "71H--78H", cmd: 0x23, equ: "NET_LOCK",
  lines: (("Fields", [2 bytes: 0, 0]), ("Payload", [the devicespec]), ("Reply", [ACK, or NAK])))
#metadata("NET_UNLOCK") <cmd-NET_UNLOCK>
Make a file read-only, and writable again (UNLOCK is 24H, NET_UNLOCK). TNFS can; the SD card cannot,
and answers NAK, as here; FTP and NFS answer ACK and do nothing.
#examples("net.lock")
#examples("net.unlock")

#cmdcard("Change Directory", dev: "71H--78H", cmd: 0x2C, equ: "NET_CHDIR",
  lines: (("Fields", [none]), ("Payload", [a directory]), ("Reply", [ACK])))
Sets the unit's *prefix*: a later OPEN or file command on the unit whose devicespec has no scheme
of its own is taken relative to it. A path with a scheme replaces the prefix; one beginning `/`
replaces the path; anything else is added to it; an empty one clears it. Nothing is checked.

#warning[Unlike OPEN, CHDIR keeps a CR or LF at the end of its payload, and puts it in the prefix,
where it spoils every later name. End the payload with a zero. A CHDIR with no payload at all clears
the prefix.]
#examples("net.chdir")

#cmdcard("Get Current Directory", dev: "71H--78H", cmd: 0x30, equ: "NET_GETCWD",
  lines: (("Fields", [none]), ("Payload", [none]), ("Reply", [the prefix, with no zero])))
The unit's prefix, without the `N:` and without a zero at the end: use the reply's length.
fujinet-lib's `network_fs_pwd()` does not add the zero either.
#examples("net.getcwd")

#cmdcard("Opening Relative to the Prefix", dev: "71H--78H", cmd: 0x4F)
With the prefix `SD:/test/`, `N8:readme.txt` opens `SD:/test/readme.txt`:
#examples("net.open.relative")
]

#section("Channel Settings", balance: false)[
#cmdcard("User Name", dev: "71H--78H", cmd: 0xFD, equ: "NET_USERNAME",
  lines: (("Fields", [none]), ("Payload", [the user name]), ("Reply", [ACK])))
A user name for the unit's next OPEN, for servers that ask (FTP, SMB, SSH, IMAPS and others), as
another way than putting it in the devicespec.
#examples("net.username")

#cmdcard("Password", dev: "71H--78H", cmd: 0xFE, equ: "NET_PASSWORD",
  lines: (("Fields", [none]), ("Payload", [the password]), ("Reply", [ACK])))
The password to go with it.

#note[The password is passed on only if a user name has been set.]
#examples("net.password")

#cmdcard("Set Line Ending", dev: "71H--78H", cmd: 0x4C, equ: "NET_SET_EOL",
  lines: (("Fields", [none]), ("Payload", [the H89's line ending, 1 or 2 bytes]), ("Reply", [ACK])))
What translation (OPEN's second field) turns the far end's line endings into, and back from:
normally CR LF. Every byte of the payload counts --- don't send a zero after it. An empty payload puts
back CR LF.
#examples("net.set_eol")

#cmdcard("Translation", dev: "71H--78H", cmd: 0x54, equ: "NET_TRANSLATION",
  lines: (("Fields", [2 bytes: 0 (not used); the translation, 0 to 3, or FFH]),
    ("Payload", [none]), ("Reply", [ACK])))
Sets a translation for the unit's *later* OPENs (not the open channel), added to theirs: with 1 here
and 2 in an OPEN, the OPEN gets 3. FFH turns translation off for later OPENs, whatever they ask.
#examples("net.translation")
#examples("net.open.translated")

#cmdcard("Interrupt Rate", dev: "71H--78H", cmd: 0x5A, equ: "NET_SET_INT_RATE",
  lines: (("Fields", [1 byte: milliseconds]), ("Payload", [none]), ("Reply", [ACK])))
How often the FujiNet signals "data waiting". On the H89 the signal goes nowhere, so this does
nothing.

#warning[Never send 0: the firmware divides by it, and stops.]
#examples("net.set_int_rate")
]

#section("Commands the Network Device Does Not Have")[
These answer NAK on the H89: NET_GET_ERROR (45H, shown below), NET_GET_DSTATS_VALUE (FFH),
NET_SET_UNIT (FAH), NET_SET_HSIO_INDEX (E3H), NET_QUERY_ALT (81H), NET_PARSE_ALT (80H) and
NET_HSIO_INDEX (3FH). For a channel's last error, ask STATUS.
#examples("net.get_error")
]
