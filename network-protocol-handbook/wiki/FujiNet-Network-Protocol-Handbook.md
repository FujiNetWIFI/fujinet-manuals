# The FujiNet Network Protocol Handbook

*Every protocol the FujiNet `N:` device speaks — file servers, web
services, sockets, shells, mail, and calendars — with the complete
devicespec grammar, every value and error code, and worked examples for
each. With chapters for Atari BASIC, Applesoft BASIC, ADAM SmartBASIC,
C with fujinet-lib, IntyBASIC, and FujiNet NOS.*

> This is the GitHub-wiki edition of the print handbook
> (`fujinet-network-protocol-handbook.pdf`). The two are kept in sync by
> hand. Every scheme string, aux value, command byte, constant, and error
> code is transcribed from the live sources: `fujinet-firmware`
> `lib/network-protocol` (commits `c026d9a12` + `07e53c764`, Sep 2026), `fujinet-lib`
> v4.11.2, `fujinet-nhandler`, `smartbasic-1.x`, and the programmer's
> guides in `fujinet-manuals`.

## Contents

- **Part I — The Network Device Model:**
  [Introduction](#introduction) · [The devicespec](#the-devicespec) ·
  [Open modes and translation](#open-modes-and-translation) ·
  [Channel modes](#channel-modes-protocol-json-and-sgml) ·
  [Status and errors](#status-errors-and-interrupts) ·
  [Special commands](#special-commands)
- **Part II — Filesystem Protocols:**
  [The filesystem model](#the-filesystem-model) · [TNFS](#tnfs) ·
  [SD](#sd) · [SMB](#smb) · [NFS](#nfs) · [FTP](#ftp) · [SFTP](#sftp) ·
  [HTTP and HTTPS](#http-and-https) · [S3](#s3) · [GDRIVE](#gdrive) ·
  [ONEDRIVE](#onedrive)
- **Part III — Stream Protocols:**
  [TCP](#tcp) · [UDP](#udp) · [TELNET](#telnet) · [SSH](#ssh) ·
  [WS and WSS](#ws-and-wss)
- **Part IV — Session Utilities:**
  [SSH.KEYGEN](#sshkeygen) · [SSH.COPYID](#sshcopyid) ·
  [CLIPBOARD](#clipboard) · [CPM](#cpm) · [TEST](#test)
- **Part V — Mail and Calendar:**
  [The mailbox model](#the-mailbox-model) · [GMAIL](#gmail) ·
  [IMAPS](#imaps) · [The calendar model](#the-calendar-model) ·
  [GCAL](#gcal) · [ICAL / WEBCAL / ICALH](#ical-webcal-and-icalh)
- **Part VI — From Your Machine:**
  [Atari BASIC](#atari-basic) · [Applesoft BASIC](#applesoft-basic) ·
  [ADAM SmartBASIC 1.x](#coleco-adam-smartbasic-1x) ·
  [C with fujinet-lib](#c-with-fujinet-lib) ·
  [IntyBASIC](#intybasic-on-the-intellivision) · [NOS](#fujinet-nos)
- **Appendices:**
  [Capability matrix](#appendix-protocol-capability-matrix) ·
  [Scheme quick reference](#appendix-scheme-quick-reference) ·
  [Implementation notes](#appendix-implementation-notes) ·
  [The programmer's guides](#appendix-the-programmers-guides)

---

# Part I — The Network Device Model

## Introduction

To your computer, the FujiNet's network device is one more peripheral:
open it with a name, read and write like a file, close it. The name is a
**devicespec**:

```
N:HTTPS://fujinet.online/hello.txt
```

Everything before the first colon addresses a device on your machine's
bus; everything after is a URL whose scheme selects a **protocol
adapter** in the firmware — 25 adapters answering to 28 scheme strings.

Every protocol is driven by the same four beats:

1. **Open** — devicespec + access mode (aux1) + translation mode (aux2).
2. **Status** — bytes waiting, connection state, error code.
3. **Read / write** — move bytes.
4. **Close** — flush, tear down, free.

The adapter lives **in the FujiNet, not your computer**: the ESP32 (or
fujinet-pc) holds the buffers, speaks TLS, parses JSON, walks OAuth. An
8 KB machine reads Gmail because the hard part happens across the bus.

### The scheme table

| Scheme | Class | Reaches |
|---|---|---|
| `TNFS` | NetworkProtocolTNFS | TNFS file servers |
| `SD` | NetworkProtocolSD | the FujiNet's own SD card |
| `SMB` | NetworkProtocolSMB | Windows / Samba shares |
| `NFS` | NetworkProtocolNFS | UNIX NFSv3 exports |
| `FTP` | NetworkProtocolFTP | FTP servers (anonymous) |
| `SFTP` | NetworkProtocolSFTP | files over SSH |
| `HTTP` `HTTPS` | NetworkProtocolHTTP | web servers, REST APIs, WebDAV |
| `S3` | NetworkProtocolS3 | Amazon S3 and compatibles |
| `GDRIVE` | NetworkProtocolGDRIVE | Google Drive |
| `ONEDRIVE` | NetworkProtocolONEDRIVE | Microsoft OneDrive |
| `TCP` | NetworkProtocolTCP | raw sockets, client or server |
| `UDP` | NetworkProtocolUDP | datagrams |
| `TELNET` | NetworkProtocolTELNET | negotiated Telnet |
| `SSH` | NetworkProtocolSSH | an interactive SSH shell |
| `WS` `WSS` | NetworkProtocolWS/WSS | WebSockets, plain or TLS |
| `SSH.KEYGEN` | NetworkProtocolSSHKeygen | generate the SSH key pair |
| `SSH.COPYID` | NetworkProtocolSSHCopyId | install it on a server |
| `CLIPBOARD` | NetworkProtocolClipboard | the FujiNet clipboard + history |
| `CPM` | NetworkProtocolCPM | a CP/M 2.2 machine inside the FujiNet |
| `GMAIL` | NetworkProtocolGMAIL | a Gmail mailbox — read, compose, reply |
| `IMAPS` | NetworkProtocolIMAPS | any IMAP mailbox over TLS |
| `GCAL` | NetworkProtocolGCAL | Google Calendar — read, compose, edit |
| `ICAL` `WEBCAL` `ICALH` | NetworkProtocolICAL | published iCalendar feeds |
| `TEST` | NetworkProtocolTest | a fixed test pattern / adapter skeleton |

Schemes are uppercased before matching. An unknown scheme fails the open
with error 144; an unparseable URL with 165.

## The Devicespec

```
N[unit]:SCHEME://user:password@host:port/path?query
```

- `N1:`–`N8:` select independent **channels** (bare `N:` = `N1:`); how
  many you get is a bus property (Atari 8, Apple/ADAM extensions expose
  1–15, Intellivision devices `$71`–`$78`).
- Credentials reach a protocol three ways: in the URL; via the username
  (`$FD`) / password (`$FE`) specials before the open; or from stored
  config (OAuth tokens, S3 keys) so nothing secret crosses the vintage
  bus.
- **Pitfall:** the firmware only hands stashed credentials over when the
  *username* is non-empty. A password alone never arrives.

## Open Modes and Translation

**aux1 (access mode):** 4 read · 6 directory (7 alt) · 8 write · 9
append · 12 read/write · 5/13/14 HTTP-specific (DELETE / POST /
PUT-with-headers).

**aux2 (translation):** what a line ending looks like on the network
side; the FujiNet folds it to/from your machine's native EOL.

| aux2 | Network EOL |
|---|---|
| 0 | none — binary, untouched |
| 1 | CR (`$0D`) |
| 2 | LF (`$0A`) |
| 3 | CR/LF |
| 4 | PETSCII character translation (on top of the stream) |

Use **mode 0 for anything binary**. The Atari also maps BEL/BS/TAB to
ATASCII equivalents. A sticky translation (`$54` special) is OR-ed into
later opens — except directory opens, where aux2 means a format or
width. Generated text (directories, indexes, status reports) arrives
with the platform line ending already applied and translation off.

## Channel Modes: Protocol, JSON, and SGML

The `$FC` special sets the channel mode: 0 protocol (default), 1 JSON,
2 SGML. The JSON three-beat, identical on every platform:

1. Open the URL, set channel mode JSON (`$FC` aux2=1).
2. **Parse** (`$50` 'P') — the FujiNet builds the document tree.
3. **Query** (`$51` 'Q') — send a path like `/results/0/name`; read the
   value back.

`$FB` tunes result translation (aux1=0) and the result line-ending byte
(aux1=1). JSON/SGML live in `lib/fnjson` / `lib/fnsgml`, driven by the
bus device — which is why any protocol can carry them. Do not confuse
`$FC` (channel mode) with `$4D` (HTTP body/header channel, HTTP only).

## Status, Errors, and Interrupts

Status returns 4 bytes on every bus: **avail** (u16 LE, capped 65534),
**connected**, **error**. The idiomatic loop: status until avail > 0 (or
connected drops), read, repeat until error 136. Some adapters do their
first real work at the first status (HTTP fires its request there). A
failed open destroys the adapter, but the error is latched for the next
status. On buses with an interrupt line, a timer polls channels and
asserts it when data waits or the connection drops (`$5A` sets the
rate).

### The error table

| Code | Meaning | | Code | Meaning |
|---|---|---|---|---|
| 1 | success | | 202 | socket timeout |
| 131 | write only | | 203 | network down |
| 132 | invalid command | | 204 | connection reset |
| 135 | read only | | 205 | connect in progress |
| 136 | end of file | | 206 | address in use |
| 138 | timeout | | 207 | not connected |
| 144 | general fatal | | 208 | server not running |
| 146 | not implemented | | 209 | no connection waiting |
| 151 | file exists | | 210 | service unavailable |
| 162 | no space | | 211 | connection aborted (never raised) |
| 165 | invalid devicespec | | 212 | bad username/password |
| 166 | invalid point | | 213 | could not parse JSON |
| 167 | access denied | | 214 | HTTP 4xx client error |
| 170 | file not found | | 215 | HTTP 5xx server error |
| 200 | connection refused | | 255 | out of buffers |
| 201 | network unreachable | | | |

## Special Commands

Printable command bytes match their mnemonic; on the Atari the XIO
number *is* the command byte.

| Hex | Dec | Char | Command |
|---|---|---|---|
| `$20` | 32 | | rename (`old,new` in one devicespec) |
| `$21` | 33 | `!` | delete |
| `$23`/`$24` | 35/36 | `#` `$` | lock / unlock |
| `$25`/`$26` | 37/38 | `%` `&` | seek (POINT) / tell (NOTE) |
| `$2A`/`$2B` | 42/43 | `*` `+` | mkdir / rmdir |
| `$2C`/`$30` | 44/48 | `,` `0` | chdir / getcwd |
| `$41`/`$63` | 65/99 | `A` `c` | TCP accept / close client |
| `$44`/`$72` | 68/114 | `D` `r` | UDP set destination / get remote |
| `$4C` | 76 | `L` | set native EOL |
| `$4D` | 77 | `M` | HTTP channel mode |
| `$50`/`$51` | 80/81 | `P` `Q` | JSON/SGML parse / query |
| `$54` | 84 | `T` | sticky translation |
| `$5A` | 90 | `Z` | interrupt rate |
| `$FB` | 251 | | JSON parameters |
| `$FC` | 252 | | channel mode (protocol/JSON/SGML) |
| `$FD`/`$FE` | 253/254 | | username / password |
| `$FF` | 255 | | data-direction inquiry (how NDEV relays unknowns) |

The filesystem specials are **one-shot**: a fresh adapter is built from
the devicespec in the payload, does the op, and is destroyed — they work
with no open channel, and need a complete devicespec every time.

---

# Part II — Filesystem Protocols

## The Filesystem Model

All ten adapters derive from `NetworkProtocolFS`. File opens resolve the
path (with crunched-8.3 recovery for long filenames), reads count
`fileSize` down to error 136, seek/tell work where the backend allows.
Directory opens (aux1=6) use **aux2 as a format selector**:

| aux2 | Format |
|---|---|
| < 128 | classic 8.3 short entries (sizes in `FSSectorSize` sectors) |
| 128 | long filename, platform width (37 / ADAM 30 / CoCo 31) |
| 129 | Apple II 80-column |
| 130 | long + provider file ID (GDRIVE) |
| 131 | RAW — filename only, `/` marks directories; for programs |
| 132 | ProDOS 40-col CAT (real dates only from TNFS) |
| 133 | ProDOS 80-col CATALOG |

Wildcards `*` `?` filter listings (`*.*`, `**`, `-` normalize to `*`);
Atari builds append `999+FREE SECTORS` except in RAW. Rename carries
both names comma-separated: `N:TNFS://host/path/OLD,NEW` (no comma →
165). Some adapters **advertise but stub** operations — accepted,
"success," nothing happens; see the capability matrix.

## TNFS

`N:TNFS://host[:port]/path` — port 16384, anonymous, plain UDP. The most
complete citizen: all modes, all specials, real seek, and the only
adapter returning real modified *and* created timestamps. Errors: not
found → 170, read-only/denied → 167, no space → 162, EOF → 136, exists →
151, mount timeout → 138, else 144. Treat as LAN/public-archive
transport — nothing is encrypted.

## SD

`N:SD:/path` — the FujiNet's own card; no host, no network. All modes;
rename/delete/mkdir/rmdir real; lock/unlock honestly report 146; seek
real. No card mounted → **200** on everything. Errno map: ENOENT → 170,
EEXIST → 151, EACCES → 167, ENOSPC → 162, ENOMEM → 255.

## SMB

`N:SMB://[user:pass@]server/share/path` — SMB2 via libsmb2, signing
enabled. First path component is the share. Credentials from URL, else
the `$FD`/`$FE` specials. A username/password with *no lowercase at all*
is lowercased (friendly to all-caps machines; hostile to all-caps
passwords). mkdir/rmdir/seek real; **rename/delete/lock/unlock are
silent stubs**. Every library failure reports 144 — check server, share,
credentials in that order.

## NFS

`N:NFS://host[:port]/export/path` — NFSv3 via libnfs; a URL port sets
both mount and NFS ports. Credentials are numeric: username special =
UID, password = GID. Auto-negotiates the export boundary (tries the
path's dir, falls back to the root export). mkdir/rmdir/seek real;
**rename/delete/lock/unlock stubs**; errors collapse to 144.

## FTP

`N:FTP://host[:port]/path` — always **anonymous**
(`anonymous`/`fujinet@fujinet.online`); URL credentials ignored; no TLS.
Read = RETR, write = STOR; append/read-write → 146. **All six
filesystem specials are silent stubs.** Reply map: 226 → 136 (EOF),
421 → 210, 430 → 212, 45x → 167, 550 → 170, other 4xx/5xx → 144.

## SFTP

`N:SFTP://user[:pass]@host[:port]/path` — port 22. Password in URL =
password auth; none = **key auth** with `/.ssh/id_ed25519` from the SD
card (see SSH.KEYGEN / SSH.COPYID). Full operation set, all real: seek,
rename, delete, mkdir 755, rmdir, lock chmod 444 / unlock 644. EOF
zero-pads reads. Errors: EOF → 136, no file/path → 170,
permission/write-protect → 167, exists → 151, missing user/empty pass →
212, else 144. Host keys are **not verified** — safe from eavesdroppers,
not from an active MITM.

## HTTP and HTTPS

`N:HTTPS://[user:pass@]host[:port]/path?query` — the biggest adapter:
REST client, form poster, WebDAV filesystem.

**The lazy transaction:** open does *not* send the request — the first
**status** does. Between them you may stage request headers and POST
data. HTTP errors surface in that first status.

**aux1 = method:** 4 GET (path encoded) · 12 GET verbatim+headers ·
8 PUT · 13 POST · 14 PUT-with-headers (sent as POST) · 5 DELETE ·
9 DELETE+headers · 6 WebDAV PROPFIND directory.

**`$4D` HTTP channel modes:** 0 body · 1 collect headers (write names
before the transaction; GET modes only) · 2 get headers (read values
back) · 3 set headers (write `Name: value`) · 4 set POST data.

**WebDAV:** directory listings via depth-1 PROPFIND (falling back to
plain GET on 405/408); rename = MOVE, delete = DELETE, mkdir = MKCOL,
rmdir = delete.

**Seek:** on a GET body channel, `$25` re-issues with `Range: bytes=n-`;
a 200 (Range ignored) is handled by skipping. 

**Status map:** 2xx → 1 · 401/402/403/407 → 212 · 404/410 → 170 · 405 →
146 · 408 → 138 · 423/451 → 167 · other 4xx → 214 · 5xx → 215 · connect
failure → 207.

## S3

`S3://[KEY:SECRET@]endpoint[:port]/bucket/key?region=..&tls=0|1` —
AWS Signature V4 signed inside the FujiNet; works with MinIO, Wasabi,
Ceph. Credentials/region/TLS fall back to web-UI config. Reads stream
GET; **writes buffer and go out as one PUT at close** (512 KB cap →
162); append downloads first; directories via ListObjectsV2 (paginated);
mkdir = zero-byte folder marker; rename = copy+delete. No seek. Map:
2xx → 1, 403 → 167, 404 → 170, 409 → 151, no response → 207, else 144.

## GDRIVE

`GDRIVE:///path/to/file` — OAuth once in the web UI (shared grant with
GMAIL/GCAL; token refresh via the FujiNet relay, client secret never on
device). Paths resolve component-by-component to file IDs; shortcuts
followed; trash invisible. Writes buffer (64 KB) and upload multipart at
close; append pre-downloads. Directory format 130 appends Drive file
IDs. Delete/mkdir real; rmdir = delete (removes non-empty folders!);
**no rename**. Mount failure (207) means re-authorize.

## ONEDRIVE

`ONEDRIVE:///path/to/file` — Microsoft Graph, by path (no ID walk).
Same buffered-upload model (64 KB PUT at close). Delete, mkdir
(conflict → 151), rmdir = delete, and — unlike GDRIVE — **real rename**
via PATCH. OAuth via the same relay pattern, `[OneDrive]` config.

---

# Part III — Stream Protocols

## TCP

| Devicespec | Meaning |
|---|---|
| `N:TCP://host:port/` | connect |
| `N:TCP://host/` | connect, port 23 |
| `N:TCP://:port/` | **listen** |
| `N:TCP://` | empty channel |

Server mode: status `connected=1` means a client is waiting; accept with
`$41`; drop with `$63` and it listens again (one client at a time).
Errors: refused → 200, short read/write → 202, reset → 204, write with
no client → 207, accept with no server → 208, nobody waiting → 209.
Quirk: `$63` reports an error even on success — trust the next status.

## UDP

`N:UDP://host:port/` (talk) or `N:UDP://:port/` (listen) — the **port is
mandatory**. `connected` is always 1. `$44` retargets writes
(`N:host:port` payload); `$72` reports the last sender (fujinet-pc
only); and the destination **auto-learns the last sender**, so
read-then-write answers whoever spoke. Write with no destination → 207.
Multicast join is not implemented.

## TELNET

`N:TELNET://host[:port]/?term=ansi&cols=40&rows=24` — TCP plus a real
Telnet state machine; negotiations answered invisibly (refuses ECHO,
offers TTYPE, declines COMPRESS2/MSSP). `term` defaults `dumb`; NAWS is
mentioned only if *both* cols and rows are given. Client only.

## SSH

`N:SSH://user[:pass]@host[:port]/?term=vanilla&cols=80&rows=24` — an
interactive shell with a real PTY. Password in URL = password auth; none
= key auth (`/.ssh/id_ed25519`). Missing username → 212 immediately.
Status 136 when the remote shell exits. Auth rejected → 167. Host key
logged, not verified. Password rides in the devicespec — prefer key
auth.

## WS and WSS

`N:WSS://host[:port]/path?frame=text` — WebSocket client; WSS is WS over
TLS. `?frame=text` sends TEXT frames (default binary). Handshake gets
10 s → 200 on failure. **One write = one frame.** Peer close → 136;
stalled transfer → 202; write after drop → 207.

---

# Part IV — Session Utilities

## SSH.KEYGEN

`N:SSH.KEYGEN://ed25519/` (add `?overwrite=1` — exact literal — to
replace). Generates `/.ssh/id_ed25519` + `.pub` on the SD card; refuses
to touch an existing key otherwise; overwrite writes tmp files and
renames. Read the report:

```
OK SSH.KEYGEN / TYPE ed25519 / OVERWRITE 0 / PRIVATE ... / PUBLIC ...
```

Failures are one-line `SSH.KEYGEN error: ...` reports with status 144.

## SSH.COPYID

`N:SSH.COPYID://user:pass@host[:port]/` — password required (that's the
point). Appends the public key to the server's `authorized_keys`
(creating dir/file with right permissions, skipping if present). Report:
`OK SSH.COPYID / HOST / USER / KEY / STATUS installed|already-present`.
After keygen + copyid, password-less `SSH://user@host` and
`SFTP://user@host` just work.

## CLIPBOARD

`N:CLIPBOARD:///[0-9]` — index 0 is the clipboard (shared with the web
UI), 1–9 the history, newest first. Only 0 writable (else 167); unfilled
slot → 170; 64 KB cap → 162; `?binary=1` stores verbatim forever. Text
is stored LF-terminated; translation applies at **close** (commit).
Pitfall: a write-mode open commits at close *even if nothing was
written* — mode 8 + close empties the clipboard. Short reads NUL-pad and
report 136.

## CPM

`N:CPM://` — boots RunCPM (CP/M 2.2 + CCP) inside the FujiNet; the
channel is its console. Drives live on the SD card. Warm boots handled
invisibly; session end → 136; empty console poll → 202; close halts the
machine.

## TEST

`N:TEST://anything/` — returns one fixed line (`This is test data…`)
terminated per your aux2; writes are hex-dumped to the debug log before
and after translation. The loopback for plumbing tests, the microscope
for translation bugs, and the official skeleton (`Test.h/.cpp`) for
writing a new adapter.

---

# Part V — Mail and Calendar

## The Mailbox Model

Shared by GMAIL and IMAPS. Append/read-write → 135; write (mode 8)
works only on providers that can send — GMAIL yes, IMAPS no (135).

| Path | aux1 | Returns |
|---|---|---|
| `/FOLDER` | 4 | message count |
| `/FOLDER` | 6 | message index |
| `/FOLDER/N` | 4 | message N's body |
| `/FOLDER/N` | 6 | attachment index |
| `/FOLDER/N/A` | 4 | attachment data (0 = body) |
| `/` | 8 | **compose** a new message (write, then close) |
| `/FOLDER/N` | 8 | **reply** to message N |

`?range=START-END` (0-based, default first 20, max 200) and
`?newest=0|1` page the index. For index opens **aux2 = 255** yields
packed records; any other value is a human listing at width = aux2 & 127
(0 → platform default: Atari 38, Apple 40, ADAM/CoCo 32, RS-232 80).
Human index: two lines per message, sized to wrap perfectly at 40
columns. Packed records (little-endian, NUL-padded):
`MailIndexItem` = msgNum u32, displayName[32], emailAddress[48],
subject[128], timestamp u64 (220 bytes);
`MailAttachmentItem` = attachmentNum u8, displayName[128], fileName[128],
mimeType[48], length u64 (313 bytes). Everything is staged at open;
reads drain to 136.

**Writing a message:** open mode 8 starts a draft; write RFC822-style
header lines — `KEY: value`, colon required, keys case-insensitive —
then a blank line, then the body verbatim; close **sends**:

```
TO: alice@example.com
SUBJECT: Hello from an Atari

Sent from my 130XE over FujiNet.
```

Only `TO`, `CC`, `BCC`, `SUBJECT` (no `FROM` — the sender is the
authenticated account). TO/CC/BCC accumulate on repeat; SUBJECT is
last-wins. Any EOL works (0x9B/CR/LF/CRLF, mixed); aux2 translation is
never applied to a write channel. Replies (mode 8 on `/FOLDER/N`)
default an omitted TO to the original's Reply-To/From and an omitted
SUBJECT to `Re:` (never doubled); the shortest legal reply is a blank
line and a sentence; the target is pinned at open (bad N → 170).
Verdict in the post-close status: 1 sent, 132 rejected draft (reason in
debug log only), 162 oversized (16 KB, nothing sent); writing nothing =
clean abort. Sent mail is text/plain UTF-8, no attachments; reading a
write channel → 131. Sending is the only write — nothing is marked
read, moved, or deleted. (The post-close verdict is latched on
SIO/AdamNet/DriveWire/RS-232; other buses don't latch it yet.)

## GMAIL

`GMAIL:///Inbox[/N[/A]]` — folders are Gmail *labels*
(case-insensitive). Message 1 = oldest; newest = the count — so "latest"
is read `/Inbox`, then open `/Inbox/<count>`. Bodies prefer text/plain.
Uses the shared Google grant (scopes `gmail.readonly` + `gmail.send`).
Map: 401 → 212 (re-authorize), 403 → 167 (scope missing), 404 → 170,
silent/5xx → 210.

**Sending** (newest firmware): mode 8 on `/` composes, on `/Inbox/N`
replies — the mailbox draft grammar above. Gmail stamps From/date from
the account and files a copy under Sent; replies thread via the
original's threadId + Message-ID/References (override the `Re:` subject
and Gmail may display the reply outside the conversation). Needs the
`gmail.send` scope — an older grant keeps reading but fails its first
send with 167; re-authorize in the web UI. Reading still marks, moves,
and deletes nothing.

## IMAPS

`IMAPS://user:pass@host[:993]/FOLDER[/N[/A]]` — any IMAP server,
implicit TLS (no STARTTLS). N = IMAP sequence number (1 = oldest). The
most fine-grained login diagnostics in the book: no host → 165, no user
→ 212, TLS fail → 200, silent server → 202, odd greeting → 210, LOGIN
rejected → 212, missing folder/message → 170, parse/fetch → 144. No
sending: a mode-8 open is refused with 135 (compose is GMAIL-only).

## The Calendar Model

Shared by GCAL and ICAL:

```
SCHEME://selector/VIEW[/DATE[/N]]
```

VIEW = `DAY | WEEK | MONTH | AGENDA` (scanned from the path's end);
DATE = `YYYY-MM-DD` (or `YYYY-MM` for MONTH), default today; N = 1-based
event in the view. aux1: 6 index · 4 count (or detail with N) · 8
**compose** (on `/sel`) or **edit** (on `/sel/VIEW/DATE/N`), providers
permitting. Params: `?category=` filter, `?count=` (AGENDA cap, 20),
`?days=` (horizon, 365), `?wkst=MO`, `?tz=`, plus `?view=/date=/n=`
escape hatches. Windows are DST-correct; recurring events expand into
occurrences; numbering is deterministic (sorted by start) and a 2-minute
cache makes index-then-detail one fetch. aux2 = width/255-raw for
indexes (as Mailbox), ignored for details. Packed record `CalEventItem`
= eventNum u32, start u64, end u64 (exclusive, UTC), flags u8 (1
all-day, 2 recurring), summary[96], location[64], category[32], uid[64]
— 277 bytes; `CalListItem` = name[64], category[32], id[128].

**Writing:** open mode 8, write field lines (`KEY: value` — the colon is
required), close commits:

```
SUMMARY: Dentist
START: 2026-09-03 14:30
END: 2026-09-03 15:15
LOCATION: 12 Main St.
DESCRIPTION: bring the x-rays
CATEGORY: health
```

Six keys only: SUMMARY, START, END, LOCATION, DESCRIPTION (repeats to
build paragraphs), CATEGORY. Blank lines are skipped (no header/body
divide, unlike mail); any EOL works; aux2 translation never applies to
a write channel. Times: `YYYY-MM-DD` (date-only = all-day) or
`YYYY-MM-DD HH:MM[:SS]` — a `T` may replace the space, compact
`YYYYMMDD[THHMMSS]` works, and a trailing `Z`/`±HH:MM` makes it
absolute; otherwise it resolves in `?tz=` (default the FujiNet's zone).
Compose needs SUMMARY + START (missing END = +1 hour, or +1 day
all-day; all-day END is inclusive). Edits change only sent fields:
neither START nor END = times untouched; lone START keeps duration
(unless it switches all-day↔timed, then compose defaults apply); lone
END must match the event's form. Rejections all report 132 (unknown
key, missing colon, bad time, missing required field, END ≤ START,
mixed date forms — reason in debug log only). Verdict in the post-close
status: 1 ok, 132 rejected, 162 oversized (16 KB), 170 target gone
(resolved at open); writing nothing = clean abort. **No delete.** A
successful commit drops the 2-minute listing cache, so re-list before
editing again. (Verdict latched on SIO/AdamNet/DriveWire/RS-232 only.)

## GCAL

`GCAL:///[sel]/VIEW[/DATE[/N]]` — selector = calendar name → id →
verbatim; empty = your "shown" calendars merged; `*` = everything (max
8). Categories: explicit (extended property) → Google color name →
calendar name. Same Google grant; needs `calendar.readonly`
(+`calendar.events` to write) — a grant never gains scopes
retroactively; re-authorize in the web UI (scope problems → 167).
Compose to `/` = primary; `*` refused (165). A calendar literally
*named* `Day`/`Week`/`Month`/`Agenda` can't be compose-targeted by name
(the view scan claims that segment) — use its id. Written CATEGORY
round-trips via private extended properties. Edits go up as a `PATCH`
and translate between Google's two date forms, so sending START in the
other form switches all-day↔timed. Indexes expand recurrences, so
editing N touches **that occurrence only, never the series**.
Unparseable JSON → 213.

## ICAL, WEBCAL, and ICALH

`ICAL://feed-host/feed-path.ics/VIEW[/DATE[/N]]` — any published .ics
feed; `WEBCAL` = same over https (paste subscription links unchanged);
`ICALH` = plain http. The feed URL is resent **verbatim** (secret URLs
survive). Streaming parse: window-sized memory, recurrence expansion
in-window, RECURRENCE-ID overrides patched at end of feed. No calendar
list (`/` → 165); read-only (135); detail is a second pass with the
window widened a day each side. Compressed responses are refused (146).
TZID-named times resolve in your configured zone — `?tz=` overrides.

---

# Part VI — From Your Machine

## Atari BASIC

Load the NDEV handler (`AUTORUN.SYS`/`NDEV.COM`). Then:

```basic
10 OPEN #1,4,0,"N:HTTPS://FUJINET.ONLINE/HELLO.TXT"
20 STATUS #1,A:BW=PEEK(746)+PEEK(747)*256
30 IF BW=0 AND PEEK(748)=1 THEN 20
40 TRAP 80:FOR I=1 TO BW:GET #1,C:? CHR$(C);:NEXT I:GOTO 20
80 CLOSE #1
```

DVSTAT: bytes waiting `PEEK(746)+PEEK(747)*256`, connection `PEEK(748)`,
error `PEEK(749)`. **The XIO number is the command byte** — the specials
table above doubles as the XIO reference. `XIO 15` flushes locally. JSON:

```basic
30 XIO 252,#1,0,1,"N:" : XIO 80,#1,0,0,"N:"
50 XIO 81,#1,0,0,"N:/status/message" : INPUT #1,V$
```

Edges: reads cap at 127 bytes/call; the DOS 2 menu unloads the handler;
NDEV cannot reach the Fuji device; `$4D` reports 146.
→ **FujiNet Programming Guide for the Atari** (`atari/programmers_guide/`).

## Applesoft BASIC

`BRUN FUJINET` hooks BASIC.SYSTEM's external commands (deliberately not
`&` — the tokenizer mangles N-words). Eighteen commands, typed at `]` or
via `PRINT CHR$(4);"…"`: NOPEN/NCLOSE/NSTATUS/NREAD/NWRITE, NJSONPARSE/
NJSONQUERY, NCD/NCAT/NCATALOG/NMKDIR/NRMDIR/NDEL/NTYPE, NLOAD/NSAVE,
NTRANS/NACCEPT/NLOGIN/NHTTPMODE. Channels 1–15; translation 4 =
PETSCII; errors via `ONERR` + `PEEK(222)`.

```basic
 10 D$ = CHR$(4): Q$ = CHR$(34)
 30 PRINT D$;"NOPEN 1,";Q$;"N:HTTPS://ICANHAZIP.COM/";Q$;",4,0"
 40 PRINT D$;"NSTATUS 1,BW,CN,ER"
 50 IF BW = 0 AND CN = 1 THEN 40
 70 PRINT D$;"NREAD 1,A$,BW": PRINT "MY IP IS ";A$
 90 PRINT D$;"NCLOSE 1"
```

→ **FujiNet BASIC Extension for the Apple II**
(`apple2/basic_extension/`) and the Apple II programmer's guide.

## Coleco ADAM SmartBASIC 1.x

Seventeen **native statements** patched into the interpreter itself:
same vocabulary as the Apple II (with `NDIR`), channels 1–15 → EOS
devices 9+. Network failures raise BASIC error 37 (`?Network Error n`),
ONERR-catchable; codes 1/136 never raise; no FujiNet → `?ILLEGAL
QUANTITY ERROR` fast.

```basic
220 ONERR GOTO 900
300 NOPEN 1,"N:HTTP://api.open-notify.org/iss-now.json",4,0
310 NJSONPARSE 1
320 NJSONQUERY 1,"/iss_position/latitude",lat$
340 NCLOSE 1
900 NSTATUS 1,bw,conn,err : PRINT "Network Error: ";err
```

AdamNet moves ≤ 1024 bytes per bus transaction. → the `smartbasic-1.x`
repository's appendix, and `adam/programmers_guide/` for EOS/Z80.

## C with fujinet-lib

One portable API (cc65/z88dk/CMOC…): `network_init/open/close`,
`network_read`/`_read_nb` (→ bytes or **−error**; EOF = −136),
`network_write`, `network_status`, `network_json_parse/query`, the
`network_http_*` family, `network_fs_*` one-shots, `network_ioctl` for
everything else. Constants exist for modes 4/8/12, HTTP modes, and
translations; pass 6 (directory) and 9 (append) as literals.

```c
network_open(url, OPEN_MODE_HTTP_GET, OPEN_TRANS_NONE);
network_json_parse(url);
network_json_query(url, "/number", buffer);
network_close(url);
```

→ **Writing Cross-Platform Client Apps Using fujinet-lib** and
`fujinet-lib-examples/network/`.

## IntyBASIC on the Intellivision

A shared-RAM mailbox at `$9C00`: stage device/command/params/payload,
submit by writing `SEQ = ACKSEQ + 1` **last**, poll ACKSEQ, verify the
reply. The `fujinet.bas` library wraps it (`fn_transact`, `fn_param`,
`fn_putstr`, `net_open/status/read/write/close`, `api_call`). Edges:
derive SEQ from the *published* ACKSEQ; HTTP fires at the first STATUS
and the library polls until two STATUS reads agree; declare
`ASM MEMATTR $8000, $9BFF, "+RWN"`; parenthesize `(PEEK(x) AND 255)`.
→ **FujiNet Programming Guide for the Intellivision**
(`intv/fujinet-programmers-guide/`).

## FujiNet NOS

The network as a DOS — no program required:

```
NCD N1:TNFS://fujinet.online/     DIR         LOAD GAMES/JUMPMAN.XEX
USER MOLLY                        PASS SECRET
NCD N2:SMB://DEN-PC/ATARI/        NCOPY N1:DOCS/README,N2:BACKUP/README
TYPE N3:HTTPS://fujinet.online/   NTRANS N1: 0
```

Mounts live in the FujiNet and are shared with whatever you run next;
`D1:`–`D8:` filespecs forward to `N1:`–`N8:` so 1982 programs save to
servers unknowingly. Keep mounts off **N4:** (NOS uses it for NCOPY and
HELP). Streams (TCP/SSH/Telnet) are the programmer's guide's department.
→ **NOS: An Introduction** (`atari/nos_manual/`).

---

# Appendix — Protocol Capability Matrix

**Y** implemented · **S** accepted but does nothing (reports success) ·
**–** refused/absent · blank = treated as nearest neighbor.

| Protocol | R | W | A | RW | DIR | SEEK | REN | DEL | MKD | RMD | LCK | UNL | Port / notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| TNFS | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | 16384 · anonymous |
| SD | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | – | – | local card |
| SMB | Y | Y | Y | Y | Y | Y | S | S | Y | Y | S | S | 445 · URL or specials |
| NFS | Y | Y | Y | Y | Y | Y | S | S | Y | Y | S | S | 2049 · UID/GID |
| FTP | Y | Y | – | – | Y | – | S | S | S | S | S | S | 21 · anonymous only |
| SFTP | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y | 22 · pass or key |
| HTTP/S | Y | Y | – | Y | Y | Y | Y | Y | Y | Y | S | S | 80/443 · WebDAV ops |
| S3 | Y | Y | Y | Y | Y | – | Y | Y | Y | Y | S | S | 443 · keys or config |
| GDRIVE | Y | Y | Y | Y | Y | – | S | Y | Y | Y | S | S | OAuth (web UI) |
| ONEDRIVE | Y | Y | Y | Y | Y | – | Y | Y | Y | Y | S | S | OAuth (web UI) |
| TCP | Y | Y |  | Y | – | – | – | – | – | – | – | – | 23 dflt · listen + accept |
| UDP | Y | Y |  | Y | – | – | – | – | – | – | – | – | port required |
| TELNET | Y | Y |  | Y | – | – | – | – | – | – | – | – | 23 · negotiated |
| SSH | Y | Y |  | Y | – | – | – | – | – | – | – | – | 22 · pass or key |
| WS/WSS | Y | Y |  | Y | – | – | – | – | – | – | – | – | 80/443 · frames |
| SSH.KEYGEN | Y | – |  |  | – | – | – | – | – | – | – | – | report only |
| SSH.COPYID | Y | – |  |  | – | – | – | – | – | – | – | – | pass required |
| CLIPBOARD | Y | Y | Y | Y | – | – | – | – | – | – | – | – | index 0 writable |
| CPM | Y | Y |  | Y | – | – | – | – | – | – | – | – | console channel |
| GMAIL | Y | Y | – | – | Y | – | – | – | – | – | – | – | OAuth · W = compose/reply |
| IMAPS | Y | – | – | – | Y | – | – | – | – | – | – | – | 993 · read-only |
| GCAL | Y | Y | – | Y | Y | – | – | – | – | – | – | – | OAuth · W = compose/edit |
| ICAL | Y | – | – | Y | Y | – | – | – | – | – | – | – | feeds · read-only |
| TEST | Y | Y | Y | Y | – | – | – | – | – | – | – | – | loopback |

# Appendix — Scheme Quick Reference

| Scheme | Canonical form · query parameters |
|---|---|
| `TNFS` | `N:TNFS://host[:port]/path` |
| `SD` | `N:SD:/path` |
| `SMB` | `N:SMB://[user:pass@]server/share/path` |
| `NFS` | `N:NFS://host[:port]/export/path` |
| `FTP` | `N:FTP://host[:port]/path` |
| `SFTP` | `N:SFTP://user[:pass]@host[:port]/path` |
| `HTTP` `HTTPS` | `N:HTTPS://[user:pass@]host[:port]/path[?query]` |
| `S3` | `S3://[key:secret@]endpoint[:port]/bucket/key` · `?region=` `?tls=0\|1` |
| `GDRIVE` | `GDRIVE:///path` |
| `ONEDRIVE` | `ONEDRIVE:///path` |
| `TCP` | `N:TCP://host[:port]/` · `N:TCP://:port/` (listen) |
| `UDP` | `N:UDP://[host]:port/` |
| `TELNET` | `N:TELNET://host[:port]/` · `?term=` `?cols=` `?rows=` |
| `SSH` | `N:SSH://user[:pass]@host[:port]/` · `?term=` `?cols=` `?rows=` |
| `WS` `WSS` | `N:WSS://host[:port]/path` · `?frame=text` |
| `SSH.KEYGEN` | `N:SSH.KEYGEN://ed25519/` · `?overwrite=1` |
| `SSH.COPYID` | `N:SSH.COPYID://user:pass@host[:port]/` |
| `CLIPBOARD` | `N:CLIPBOARD:///[0-9]` · `?binary=1` |
| `CPM` | `N:CPM://` |
| `TEST` | `N:TEST://anything/` |
| `GMAIL` | `GMAIL:///Folder[/N[/A]]` · `?range=a-b` `?newest=0\|1` · mode 8: `/` compose, `/Folder/N` reply |
| `IMAPS` | `IMAPS://user:pass@host[:port]/FOLDER[/N[/A]]` · `?range=` `?newest=` (read-only) |
| `GCAL` | `GCAL:///[sel]/VIEW[/DATE[/N]]` · `?category=` `?count=` `?days=` `?wkst=` `?tz=` · mode 8: `/[sel]` compose, `/…/N` edit |
| `ICAL` `WEBCAL` `ICALH` | `ICAL://feed-host/feed-path/VIEW[/DATE[/N]]` · same as GCAL |

# Appendix — Implementation Notes

Rough edges as of the colophon's commit, stated plainly:

1. **Windows would-block misreport** — fujinet-pc Win32 builds report
   206 for a would-block socket (fall-through in `Protocol.cpp`).
2. **TCP close-client reports failure on success** — ignore `$63`'s
   transaction status; trust the next status call.
3. **Silent stubs** — FTP's six filesystem specials; SMB/NFS
   rename/delete/lock/unlock; base-class lock/unlock inherited by HTTP,
   S3, GDRIVE, ONEDRIVE. All marked `S` in the matrix.
4. **HTTP `stat()` short-circuits** before its HEAD logic.
5. **HTTP header reads lack a length clamp** — give them 256-byte
   buffers.
6. **One Telnet state machine** (file-scope static) — one TELNET channel
   at a time.
7. **SSH status logic** uses an inverted variable name and an unchecked
   channel pointer; correct for successfully opened channels.
8. **`is_locked` conventions differ** — TNFS sets it for writable files,
   SFTP for read-only ones.
9. **Shadowed capability flags** in TNFS/FTP/SMB/NFS — harmless (nothing
   consults them), but a trap for future code.
10. **Error 211** (`CONNECTION_ABORTED`) is defined but never raised.
11. **UDP multicast detection** exists but is unwired; no group joins.
12. **The commit verdict is bus-dependent** — the mail/calendar
    commit-on-close verdict is latched into the next status by the SIO,
    AdamNet, DriveWire, and RS-232 layers; IEC, IWM, ComLynx, S100, and
    RC2014 do not yet latch it, so a failed send or commit may not
    surface there.
13. **Draft rejections are one number** — every mail or calendar draft
    error (bad key, missing colon, bad time, missing required field, end
    before start, mixed date forms) reports 132; the cause is named only
    in the debug log.
14. **No delete, no attachments out** — the mail adapters never delete,
    move, or mark messages and send `text/plain` only; the calendar
    adapters compose and edit but cannot remove an event.

# Appendix — The Programmer's Guides

| Guide | Where |
|---|---|
| FujiNet Programming Guide for the Atari | `fujinet-manuals/atari/programmers_guide/` |
| FujiNet BASIC Extension for the Apple II | `fujinet-manuals/apple2/basic_extension/` |
| FujiNet Programming Guide for the Apple II | `fujinet-manuals/apple2/programmers_guide/` |
| FujiNet Programming Guide for the Coleco ADAM | `fujinet-manuals/adam/programmers_guide/` |
| SmartBASIC 1.x FujiNet appendix | the `smartbasic-1.x` repository |
| FujiNet Programming Guide for the Intellivision | `fujinet-manuals/intv/fujinet-programmers-guide/` |
| Writing Cross-Platform Client Apps Using fujinet-lib | `fujinet-manuals/writing-cross-platform-client-apps-using-fujinet-lib/` |
| NOS: An Introduction | `fujinet-manuals/atari/nos_manual/` |
| FujiNet Programmer's Reference (MS-DOS) | `fujinet-manuals/msdos/programmers_reference/` |

The guides differ in *spelling*; the protocols never do.
