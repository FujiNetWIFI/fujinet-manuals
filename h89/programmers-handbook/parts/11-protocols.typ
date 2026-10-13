#import "../lib.typ": *
#import "../prog.typ": *

#chapter(11, "Network Protocols")

#section("General")[
A network channel (Chapter 10) opens whatever its *devicespec* names. The devicespec is a text
string in the payload of the OPEN request, and its *scheme* --- the word before the first colon
after the `N:` --- chooses one of the FujiNet's 28 protocols. Behind each is a piece of the firmware
that knows how to talk to one kind of server, or to make something from nothing (an SSH key, a
calendar). To the H89 they all look the same: OPEN, STATUS, READ, WRITE, CLOSE.

This chapter lists them, with the form of devicespec each takes, a word on what it does, and
anything special on the H89. The FujiNet project's *Network Protocol Handbook* gives each a full
chapter.
]

#section("The Devicespec")[
#code("N[n]:SCHEME://[user:password@]host[:port]/path[?query]")

- *N:* or *Nn:* names the channel. Under the FujiBus the channel is really chosen by the device
  number the request goes to (71H to 78H), so `N:` will do; fujinet-lib reads the digit to pick the
  device, and `N3:` sends the request to 73H.
- The *scheme* is matched in capitals, so `n:http://` works as well as `N:HTTP://`.
- Host names and paths are passed on as they are. Paths on a server whose names have case need the
  case right.
- The devicespec may be up to 256 bytes long.

The firmware changes a few characters on the way in, for the Atari's sake: an asterisk becomes the
end of the string (so `*` works as "everything" in directory listings), and a full stop at the very
end is dropped.

#warning[An OPEN of a scheme the FujiNet does not know is refused with NAK, and STATUS then reports
error 144. (The *Network Protocol Handbook* gives 165, which is what other buses report.) An OPEN
always closes whatever the channel had open first, even when it then fails.]
]

#section("The Families")[
The protocols fall into four families, and the family tells you most of what a protocol can do:

- *File systems* know files from directories. They can list a directory (OPEN mode 6), read and
  write files (modes 4 and 8), and most can rename, delete, make and remove directories (Chapter
  10's file system commands) and seek.
- *Streams* are a connection: bytes in, bytes out, until one end hangs up. Mode and translation
  hardly matter to them.
- *Utilities* do one job when opened, and READ tells you how it went.
- *Mail and calendars* turn a mailbox or a calendar into numbered items and text you can read
  line by line.

#stable((0.82in, 0.5in, 1fr),
  th[Scheme], th[Family], th[Reaches],
  [TNFS], [file], [TNFS servers, the FujiNet's own file protocol],
  [SD], [file], [the FujiNet's microSD card],
  [SMB], [file], [Windows and Samba shares],
  [NFS], [file], [UNIX NFS exports],
  [FTP], [file], [FTP servers],
  [SFTP], [file], [files over SSH],
  [HTTP, HTTPS], [file], [web servers, web services, WebDAV],
  [S3], [file], [Amazon S3 and compatible stores],
  [GDRIVE], [file], [Google Drive],
  [ONEDRIVE], [file], [Microsoft OneDrive],
  [TCP], [stream], [any TCP service; or listen for one],
  [UDP], [stream], [UDP datagrams],
  [TELNET], [stream], [Telnet: bulletin boards, servers],
  [SSH], [stream], [a shell on another computer],
  [WS, WSS], [stream], [WebSocket services],
  [SSH.KEYGEN], [utility], [makes the FujiNet's SSH key],
  [SSH.COPYID], [utility], [installs that key on a server],
  [CLIPBOARD], [utility], [the FujiNet's clipboard],
  [CPM], [utility], [a CP/M computer inside the FujiNet],
  [TEST], [utility], [a fixed test message],
  [GMAIL], [mail], [a Gmail mailbox],
  [IMAPS], [mail], [any IMAP mailbox],
  [GCAL], [calendar], [Google Calendar],
  [ICAL, WEBCAL, ICALH], [calendar], [published calendar feeds],
)
]

#let scheme(name, form, body) = {
  block(sticky: true, above: 1.1em, below: 0.35em,
    text(font: f-head, weight: "bold", size: 9.2pt, upper(name)))
  block(above: 0.3em, below: 0.45em, text(font: f-scrn, size: 7.6pt, { set smartquote(enabled: false); form }))
  body
}

#section("File Systems", balance: false)[
#scheme("TNFS", "N:TNFS://host[:port]/path")[
The Tiny Network File System, made for 8-bit computers: small requests, small replies, and servers
that run on anything. The FujiNet's public disk image servers are TNFS servers, and the tnfsd
server runs on Linux, Windows and macOS. Reading, writing, appending, directories, every file system
command and SEEK all work. `N:TNFS://tnfs.fujinet.online/` lists the public server.
]
#scheme("SD", "N:SD:/path")[
The microSD card on the FujiNet card, with the same commands as TNFS except LOCK and UNLOCK. Note
the single slash. On fujinet-pc it is the directory given with `-s`. The book's examples use it,
because it needs no network at all: `N:SD:/test/` lists the examples' test directory.
]
#scheme("SMB", "N:SMB://[user:password@]server/share/path")[
Windows file sharing (SMB 2 and 3), and Samba on other systems.
]
#scheme("NFS", "N:NFS://host[:port]/export/path")[
UNIX file servers. LOCK and UNLOCK do nothing.
]
#scheme("FTP", "N:FTP://host[:port]/path")[
Files from FTP servers, anonymously unless a user name and password are set (Chapter 10). Reading
files and directories works; the file system commands answer ACK and do nothing.
]
#scheme("SFTP", "N:SFTP://user[:password]@host[:port]/path")[
Files over SSH, from any computer that runs an SSH server, with every file system command. The
password can be left out if the FujiNet's key is installed on the server (SSH.COPYID, below).
]
#scheme("HTTP, HTTPS", "N:HTTPS://[user:password@]host[:port]/path[?query]")[
The World Wide Web, and the web services that answer in JSON or XML. OPEN's mode chooses GET (4),
PUT (8), POST (13), DELETE (5) and their variants with headers; Chapter 10 has them all, with the
JSON parser, which most programs pair with HTTP. HTTPS uses TLS, done entirely by the FujiNet, so
an H89 can talk to modern secure servers. WebDAV servers can be listed (mode 6) and have files
renamed (MOVE) and directories made (MKCOL).
]
#scheme("S3", "N:S3://[key:secret@]endpoint[:port]/bucket/key?region=..&tls=0|1")[
Amazon S3 and the many stores that speak its language, such as MinIO.
]
#scheme("GDRIVE, ONEDRIVE", "N:GDRIVE:///path     N:ONEDRIVE:///path")[
Google Drive and Microsoft OneDrive. Both need the FujiNet signed in to the account first, from its
web page; after that a path is all an H89 program needs. Files written are sent when the channel is
closed.
]
]

#section("Streams", balance: false)[
#scheme("TCP", "N:TCP://host:port/       N:TCP://:port/   (listen)")[
A plain TCP connection to any port: the H89 sends bytes, the far end's bytes wait in the FujiNet
until READ takes them. With no host, the FujiNet *listens* on the port instead, and ACCEPT takes
each computer that connects (Chapter 10). NETCAT (Chapter 13) is a TCP and Telnet client.
]
#scheme("UDP", "N:UDP://host:port/       N:UDP://:port/")[
Datagrams, one at a time, to and from a port. A port is required. SET_DESTINATION and GET_REMOTE
(Chapter 10) say where datagrams go and where the last one came from.
]
#scheme("TELNET", "N:TELNET://host[:port]/?term=ansi&cols=80&rows=24")[
TCP with the Telnet protocol's negotiation handled by the FujiNet, so bulletin boards and Telnet
servers see a proper terminal. `term`, `cols` and `rows` say what terminal to claim. The H19 in
ANSI mode is a good match for `term=ansi` (NETCAT switches it); in its own Heath mode it is close
to a VT52.
]
#scheme("SSH", "N:SSH://user[:password]@host[:port]/?term=vt100&cols=80&rows=24")[
A shell on another computer over SSH, with all the encryption done by the FujiNet.
]
#scheme("WS, WSS", "N:WSS://host[:port]/path?frame=text")[
WebSocket connections, plain or over TLS: a message-based stream that many web services use for
live data. `frame=text` sends text frames rather than binary ones.
]
]

#section("Utilities", balance: false)[
#scheme("SSH.KEYGEN", "N:SSH.KEYGEN://ed25519/?overwrite=1")[
Makes an SSH key pair for the FujiNet and keeps it on the microSD card. READ gives a line saying
what happened.
]
#scheme("SSH.COPYID", "N:SSH.COPYID://user:password@host[:port]/")[
Logs in to a server once with a password and adds the FujiNet's key to the user's
`authorized_keys`, so SSH and SFTP need no password after.
]
#scheme("CLIPBOARD", "N:CLIPBOARD:///[0-9]")[
The FujiNet's clipboard, shared by every computer that uses the FujiNet and by its web page: read
the current text (0) or one of the nine before it, write to replace it (when the channel closes), or
append with mode 9. A handy way to move text from a modern computer to the H89 and back.
]
#scheme("CPM", "N:CPM://")[
A whole CP/M 2.2 computer, emulated inside the FujiNet: READ takes its console output, and WRITE
types at its keyboard. There is one, shared by every channel. (It is not the H89's CP/M, and has
nothing to do with device 5AH, which the H89 does not have.)
]
#scheme("TEST", "N:TEST://anything/")[
READ gives a fixed sentence and WRITE is thrown away: a way to check a program's network code with
no server at all.
]
]

#section("Mail and Calendars", balance: false)[
#scheme("GMAIL", "N:GMAIL:///Folder[/n[/a]]")[
A Gmail mailbox, signed in from the FujiNet's web page. Reading a folder gives how many messages it
holds; a directory listing (mode 6) gives one line per message; `/Inbox/3` reads message 3, and a
third number an attachment. In mode 8, `N:GMAIL:///` sends a new message and `N:GMAIL:///Inbox/3`
a reply.
]
#scheme("IMAPS", "N:IMAPS://user:password@host[:port]/FOLDER[/n[/a]]")[
The same, read-only, for any mailbox that offers IMAP over TLS.
]
#scheme("GCAL", "N:GCAL:///[calendar]/VIEW[/DATE[/n]]")[
Google Calendar as text: VIEW is DAY, WEEK or MONTH. On this bus lines are formatted 80 columns
wide, just right for the H19. Mode 8 adds an event, or edits one.
]
#scheme("ICAL, WEBCAL, ICALH", "N:ICAL://feed-host/feed-path/VIEW[/DATE[/n]]")[
Published calendar feeds (iCalendar files), read-only, with the same views. ICAL and WEBCAL fetch
over HTTPS, ICALH over plain HTTP.
]
]

#section("Which Were Tried")[
The examples in this Manual open SD, HTTP, TCP and UDP channels, against servers on the same
computer as fujinet-pc, and NETCAT opens TCP and Telnet ones. The others are as the firmware has
them; the *Network Protocol Handbook* describes each in full. All 28 are in the H89's firmware and
in fujinet-pc alike.
]
