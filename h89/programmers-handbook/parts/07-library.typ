#import "../lib.typ": *
#import "../prog.typ": *

#chapter(7, "fujinet-lib Reference")

#let LR = json("../data/libref.json")

#section("General")[
fujinet-lib is the FujiNet project's C library. It runs on a dozen kinds of computer; on the H89 it
is built with z88dk, for HDOS and for CP/M, as Chapter 6 describes. Nearly every function sends one
FujiNet command and returns what the reply said, so this chapter is short on explanation: each
entry names the command, and the command's card in Chapters 8 to 12 tells the rest.

The entries are in five groups, by header file. Each gives the function's declaration as the
H89's build sees it, what it returns, the commands it sends with the page of their cards, and any
WARNING for the H89. Many of the names are macros over the bus call rather than functions; that
makes no difference to a program, except that a macro's arguments may be used more than once, so
don't pass one an expression with side effects.
]

#section("The Header Files")[
#stable((1.25in, 1fr),
  th[Include], th[For],
  [`fujinet-fuji.h`], [The FujiNet device: WiFi, hosts, directories, drives, app keys, base64,
    hashes. Includes the others it needs.],
  [`fujinet-network.h`], [Network channels: open, read, write, status, JSON, HTTP, file systems.],
  [`fujinet-clock.h`], [The clock.],
  [`fujinet-qrcode.h`], [QR codes.],
  [`fujinet-bus.h`], [The bus call itself, and the device numbers.],
  [`fujinet-err.h`], [`FN_ERR` codes and the network error numbers.],
  [`fujinet-commands.h`], [The command numbers, under fujinet-lib's names (`FUJICMD_...`).],
)

fujinet-lib's command names differ a little from the firmware's, which this Manual uses: the
library's `FUJICMD_GET_SSID` is the firmware's `FUJI_GET_SSID`, and `NETCMD_OPEN` is `NET_OPEN`.
]

#section("What Functions Return")[
There are three kinds of answer:

- `bool`: `true` if the FujiNet answered ACK, `false` for a NAK, a garbled reply or no reply at all.
  Most `fuji_` functions and macros return this.
- `FN_ERR`: 0 (`FN_ERR_OK`) for success, otherwise a reason. Most `network_` and `clock_`
  functions return this. The reasons are few, because the H89's bus says little: `FN_ERR_IO_ERROR`
  (1) covers every failed exchange, `FN_ERR_BAD_CMD` (2) bad arguments.
- `int16_t`: a length, or a negative `FN_ERR`. The functions that read data return this:
  `network_read()`, `network_json_query()`.

For why a network request failed, ask for the channel's STATUS (`network_status()`): its error byte
is one of the network error numbers in the Appendix, which `fujinet-err.h` names
`NETWORK_ERROR_...`.

#warning[A `bool` function cannot tell you how much data came back. If the FujiNet sends a shorter
reply than the buffer you gave, the function still returns `true`, and the end of your buffer is
whatever was there before. Clear buffers first when it matters.]
]

#section("Structures")[
The structures have the same layout as the replies, byte for byte, so a reply is read straight
into one. On the H89 they are:

#code("typedef struct {                /* FUJI_GET_ADAPTERCONFIG: 140 bytes */
    char ssid[33];              /* the network's name */
    char hostname[64];          /* the FujiNet's name */
    uint8_t localIP[4], gateway[4], netmask[4], dnsIP[4];
    uint8_t macAddress[6], bssid[6];
    char fn_version[15];        /* the firmware's version */
} AdapterConfig;

typedef struct {                /* ..._EXTENDED: 240 bytes */
    /* AdapterConfig's fields, then the addresses as text: */
    char sLocalIP[16], sGateway[16], sNetmask[16], sDnsIP[16];
    char sMacAddress[18], sBssid[18];
} AdapterConfigExtended;

typedef uint8_t HostSlot[32];   /* a host's name; 8 of them */

typedef struct {                /* 38 bytes; 8 of them */
    uint8_t hostSlot;           /* which host; FFH: empty */
    uint8_t mode;               /* 01H read, 02H write */
    uint8_t file[36];           /* the image's name */
} DeviceSlot;

typedef struct {                /* 34 bytes */
    char ssid[33];
    signed char rssi;           /* signal strength, dBm */
} SSIDInfo;

typedef struct {                /* 97 bytes */
    char ssid[33];
    char password[64];
} NetConfig;

typedef struct {                /* FUJI_NEW_DISK's payload */
    uint16_t numSectors, sectorSize;
    uint8_t hostSlot, deviceSlot;
    char filename[256];
} NewDisk;

typedef struct {                /* a directory entry with its details */
    FujiDirEntryTimestamp modified;   /* years since 1970, month,
                                         day, hour, minute, second */
    uint32_t size;
    uint8_t flags;              /* 01H a directory, 02H name cut short */
    uint8_t mediatype;
    char filename[256];
} FujiDirEntry;")

#warning[On the H89, `FujiDirEntry` has a `flags` byte where other computers have `is_dir` and
`is_trunc`, but the macros `FUJI_DIR_ENTRY_IS_DIR()` and `FUJI_DIR_ENTRY_IS_TRUNC()` still use the
other names, so a program that uses them will not compile. Test `flags & 1` and `flags & 2` instead.
The header the firmware actually sends before the name is 12 bytes long (Chapter 8).]
]

#section("The Bus Call")[
Under all of it is one function:

#code("bool fuji_bus_call(uint8_t device, uint8_t fuji_cmd, uint8_t fields,
                   uint8_t aux1, uint8_t aux2, uint8_t aux3, uint8_t aux4,
                   const void *buf, size_t buf_length);")

It sends one request and takes its reply, exactly as the book's `fn_call` does (Chapter 4). `fields`
is the descriptor, `FUJI_FIELD_NONE` to `FUJI_FIELD_C1234` (0 to 7), plus one of two flags of
fujinet-lib's own:

- `FUJI_FIELD_DATA` (8): `buf` and `buf_length` are a payload to send.
- `FUJI_FIELD_REPLY` (16): `buf` and `buf_length` are where the reply's data goes.

Without either, `buf` is sent as a payload if `buf_length` is not 0. With `FUJI_FIELD_REPLY`, the
call succeeds only if the reply is ACK from the right device with a good checksum; it does not
check that the data filled the buffer.

A call can send a payload *or* take a reply's data, not both. No FujiNet command on the H89 needs
both.

When fujinet-lib has no function for something --- the disk drives, for one --- call
`fuji_bus_call()` yourself:

#snip("disk.read", "c", caption: [EXDISK.C --- a disk sector, by the bus call])

#sub("The shorthand macros")
fujinet-lib writes most of its functions as one-line macros over the bus call, named for what they
send: `FUJICALL_A1_RV(cmd, a1, reply, len)` sends `cmd` to the FujiNet device with one byte field
and takes a reply of `len` bytes. `NETCALL_...` does the same for a network channel (with the unit
as an extra first argument), and `CLKCALL_...` for the clock. The suffixes are:

#stable((0.6in, 1fr),
  th[Suffix], th[Means],
  [`A1` ... `A4`], [one to four byte fields],
  [`B12`], [a word field (aux1 and aux2)],
  [`B12_B34`], [two word fields],
  [`C1234`], [a 32-bit field],
  [`D`], [a payload follows: data and its length],
  [`RV`], [a reply comes back: a buffer and its length],
)

They are handy in your own programs too: `FUJICALL_A1_RV(FUJICMD_GET_HOST_PREFIX, 0, buf, 256)` is
the whole of `fuji_get_host_prefix(0, buf)`.
]

#let ent(f) = {
  block(sticky: true, above: 1em, below: 0.3em, text(font: f-head, weight: "bold", size: 8.8pt, f.name))
  block(above: 0.2em, below: 0.35em, text(font: f-scrn, size: 7pt, { set smartquote(enabled: false); f.proto }))
}

#section("Functions That Will Not Link")[
These are declared in fujinet-lib's headers, but not built for the H89. A program that calls one
compiles, and then fails to link with "undefined symbol":

#for f in LR.functions.filter(f => not (f.links.hdos and f.links.cpm)) { ent(f) }

Also declared and not built: `fn_error()`, and the variable `_fuji_status`.
]

#let LD = json("../data/libdesc.json")
// one entry: the name, its declaration, what it does, what it sends
#let libent(f) = {
  let d = LD.at(f.name, default: (:))
  block(sticky: true, above: 1.1em, below: 0.25em, width: 100%, {
    line(length: 100%, stroke: 0.5pt + ink)
    v(-0.3em)
    let nm = text(font: f-head, weight: "bold", size: 8.8pt, f.name)
    let tg = text(font: f-sans, size: 6.2pt, tracking: 0.04em, upper(
      (if f.kind == "macro" { "macro" } else { "function" }) + " · " + (if f.header != none { f.header } else { "" })))
    // a long name puts the kind and header on a line of their own
    std.layout(size => if measure(nm).width + measure(tg).width + 0.12in > size.width {
      stack(spacing: 0.3em, nm, tg)
    } else { grid(columns: (1fr, auto), nm, tg) })
  })
  block(above: 0.25em, below: 0.4em, breakable: true,
    text(font: f-scrn, size: 6.8pt, hyphenate: false, { set smartquote(enabled: false)
      f.proto.replace(regex("\s+"), " ") }))
  if "what" in d and d.what != none { block(above: 0.3em, below: 0.3em, d.what) }
  let lines = ()
  if "returns" in d and d.returns != none { lines.push(([Returns], [#d.returns])) }
  if f.commands.len() > 0 {
    lines.push(([Sends], f.commands.map(c => [#text(font: f-scrn, size: 7pt, c) (page #card-page(c))]).join([, ])))
  }
  if not (f.links.hdos and f.links.cpm) { lines.push(([Links], [*no*: not built for the H89])) }
  if lines.len() > 0 {
    grid(columns: (0.6in, 1fr), column-gutter: 0.4em, row-gutter: 0.35em,
      ..lines.map(((a, b)) => (text(font: f-sans, size: 6.6pt, tracking: 0.05em, upper(a)), text(size: 8.4pt, b))).flatten())
  }
  if "warning" in d and d.warning != none { warning(d.warning) }
  if "example" in d and d.example != none and has-snip(d.example, "c") {
    snip(d.example, "c")
  }
}

#let groups = (
  ("fuji", "The FujiNet Device"), ("appkey", "App Keys"), ("network", "Network Channels"),
  ("clock", "The Clock"), ("qrcode", "QR Codes"), ("bus", "The Bus"), ("helper", "Helpers"),
)
#for (g, title) in groups {
  let fs = LR.functions.filter(f => LD.at(f.name, default: (:)).at("group", default:
    if f.name.starts-with("network") { "network" } else if f.name.starts-with("clock") { "clock" }
    else if f.name.starts-with("qrcode") { "qrcode" } else { "fuji" }) == g)
  if fs.len() > 0 {
    section(title, balance: false, { for f in fs { libent(f) } })
  }
}
