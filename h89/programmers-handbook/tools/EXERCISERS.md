# The exercisers: how the book's command examples are made

Every command card in Chapters 8–12 prints three things for its command:

- a **Z80 snippet**,
- a **C snippet**, and
- the **bytes that went over the bus** when it ran.

All three come from one place, the *exerciser* programs. These run under HDOS and
CP/M on FujiNet Go H89 against the rig: a fujinet-pc built from fn-h89 7ab84ae64,
behind `tools/tap.py`, which logs every frame.

Nothing printed is typed in by hand. If a snippet is in the book, it ran.

## Files

| What | Where |
|---|---|
| Z80 exercisers | `src/asm/ex/exfuji.asm`, `exnet.asm`, `exdisk.asm`, `exclock.asm`, `exprint.asm`, `exmodem.asm` |
| C exercisers | `src/c/ex/exfuji.c`, `exnet.c`, … (same names) |
| Expected results | `expect/<prog>.json` |
| Firmware facts, with file:line | `data/fwspec/{fuji,net,misc}.json` (read these first) |
| Library | `src/asm/inc/` (Z80: os, fujinet, fncmd, fujibus, card, con, mark, tail); `src/c/common/` (h89con, exlog, hdosargs) |

## Keys

A key names an example: `<device>.<command>` in lower case, from the firmware's name
less its prefix.

- `fuji.get_adapterconfig`, `fuji.read_dir_entry`, `net.open`, `clock.get_time`,
  `disk.read`.
- A second example of the same command takes a suffix: `fuji.read_dir_entry.ext`,
  `net.open.http_post`, `net.read.json`.
- A sequence that only makes sense together (open the appkey, write it, close it)
  gets one key per command, in order.

The same key is used in the Z80 file, the C file and the bus log, which is how a card
finds all three. **Never reuse a key for a different example.**

## A Z80 example

```
        call    ex_m                    ; (marker: not printed)
        defm    "fuji.get_host_prefix", 0
;@ex fuji.get_host_prefix
        ld      hl,rq_getpfx            ; host slot 0's directory prefix
        call    fn_call
        ld      hl,pfx                  ; it is a NUL-terminated string
        call    print
;@end
        call    ex_show                 ; (report: not printed)
...
;@ex fuji.get_host_prefix
rq_getpfx:
        FNREQ   DEV_FUJINET, FUJI_GET_HOST_PREFIX, F_A1, 0,0,0,0
        FNBUF   0, 0, pfx, 256
;@end
```

What happens to it:

- Code between `;@ex KEY` and `;@end` is cut out and printed. If a key has more than
  one region in a file (here, the code and the request block), they print joined, in
  source order.
- `;@hide` … `;@show` inside a region leaves lines out.
- The marker (`call ex_m` / `defm "KEY",0`) sends a frame to device 0FH, which does not
  exist. The firmware NAKs it, but the frame stands in the bus log, so everything after
  it belongs to that key. `mkexamples.py` drops the marker and its NAK.
- `ex_show` prints `ACK|NAK|TMO|BAD length first-bytes`. It reads `fn_res`/`fn_len`,
  so the snippet may use A, BC and the flags after `fn_call`.

The request block is two lines:

```
FNREQ   device, command, descriptor, aux1, aux2, aux3, aux4
FNBUF   payload, payload length, reply buffer, reply buffer size
```

- Descriptors are `F_NONE`, `F_A1`, `F_A1_A2`, `F_A1_A2_A3`, `F_A1_A2_A3_A4`, `F_B12`
  (one word), `F_B12_B34` and `F_C1234` (one long).
- A word field goes in aux1/aux2, low byte first. A long goes in aux1–aux4.
- To change a field or a length at run time, store into the block:
  `ld (rq_x+RQ_AUX1),hl`, `ld (rq_x+RQ_PLEN),bc`. The offsets are in `fujinet.inc`.
- `fn_call` returns:
  - A = `FN_OK` / `FN_NAK` / `FN_TIMEOUT` / `FN_BAD`, with Z set on ACK;
  - BC = the reply's payload length, even if that is more than the buffer;
  - carry = the reply was truncated.

Style. The snippets are printed, so they must read well:

- Lower-case mnemonics.
- Tabs as spaces: label at column 1, mnemonic at column 9, operands at column 17,
  comment at column 41.
- **No line longer than 72 characters.**
- Comments are short, plain English, and say *why*, the way Heath's listings do.
- Always use the equates: `DEV_FUJINET`, `DEV_NETWORK`, `DEV_DISK`, `DEV_CLOCK`,
  `DEV_PRINTER`, `DEV_SERIAL` (the modem, 50H), `FUJI_…`, `NET_…`, `DISK_…`, `F_…`,
  `RQ_…`, `NS_…`. Never a raw number for a device, command or descriptor.
- Labels: `rq_<short>` for request blocks, `p_<short>` for payload data.
- Show what the reply means where that is short: print a string with `print`, a number
  with `pdec8`/`pdec16`, bytes with `phex8`/`phexs`, an IP address with `pip`. Make use
  of the reply in the snippet when the reader would.
- Keep each snippet small, about 3–12 lines of code plus its request block.
- Shared buffers (`buf: defs 512`) live outside any region. An example's own payload
  data (a path, a string) lives inside its region.
- The exerciser must carry on after every example, including ones that NAK. So don't
  `jp` out of a snippet to a failure exit. If you show a check, make it `jr nz,` to a
  label at the end of the same snippet.

## A C example

```
    ex_mark("fuji.get_host_prefix");
//@ex fuji.get_host_prefix
    ok = fuji_get_host_prefix(0, prefix);   /* host slot 0's prefix */
    if (ok)
        printf("prefix: %s\n", prefix);
//@end
    ex_showb(ok, prefix, 16);
```

- Use the fujinet-lib function that sends the command. The `fujinet_lib` field in
  `data/fwspec/*.json` names it.
- Where fujinet-lib has none, or is broken on the H89, call `fuji_bus_call()` directly,
  and say why in a comment in the snippet.
- Where the library is unusable for a device (the modem's replies are not framed), use
  a small helper in `src/c/common/` and document it there.
- 4-space indent, `/* */` comments, lines no longer than 72 characters.
- `ex_show(ok)` / `ex_showb(ok, buf, len)` report; they are outside the region.
- Start with `con_init(0)`, which stops HDOS upper-casing everything, and end with
  `ex_done(); con_exit();`.

## Building and running

The emulator runs are serialised by a lock, so it is safe to start them from several
shells at once.

```
tools/asm.sh hdos EXFUJI src/asm/ex/exfuji.asm      # -> build/bin/hdos/asm/EXFUJI.ABS
tools/asm.sh cpm  EXFUJI src/asm/ex/exfuji.asm      # -> build/bin/cpm/asm/EXFUJI.COM
tools/cc.sh  hdos EXFUJI src/c/ex/exfuji.c src/c/common/h89con.c src/c/common/exlog.c
tools/cc.sh  cpm  EXFUJI src/c/ex/exfuji.c src/c/common/h89con.c src/c/common/exlog.c

tools/runprog.sh exfuji-asm-hdos hdos "@done" "RUN SY1:EXFUJI.ABS" build/bin/hdos/asm/EXFUJI.ABS
tools/runprog.sh exfuji-asm-cpm  cpm  "@done" "B:EXFUJI"           build/bin/cpm/asm/EXFUJI.COM
tools/runprog.sh exfuji-c-hdos   hdos "@done" "RUN SY1:EXFUJI.ABS" build/bin/hdos/c/EXFUJI.ABS
tools/runprog.sh exfuji-c-cpm    cpm  "@done" "B:EXFUJI"           build/bin/cpm/c/EXFUJI.COM

python3 tools/mkexamples.py exfuji-asm-hdos exfuji-asm-cpm exfuji-c-hdos exfuji-c-cpm
python3 tools/mksnips.py
```

- **Run names must end in `-asm-hdos`, `-asm-cpm`, `-c-hdos` or `-c-cpm`.** The book
  prints the `-asm-hdos` capture.
- Each run leaves `build/runs/<run>/` with:
  - `screen.txt` (the last screen),
  - `tap.jsonl` (every frame),
  - `fujinet.log`,
  - `helpers.jsonl` (what the helper servers saw).
- The screen only holds the last 24 lines. For the whole story, decode `tap.jsonl` with
  `tools/fujibus.py`'s `decode()`.
- Extra data files go on the data disk (SY1: / B:). List them after the program:
  `tools/runprog.sh NAME OS UNTIL CMD PROGRAM FILE...`. Under CP/M, the first file must
  be the .COM.
- `RUN_TIMEOUT=300` (seconds) for long runs.
- Under HDOS the console is case-mapped unless the program turns that off (`os.inc`
  does for Z80; `con_init` for C). Match UNTIL to what is really on the screen.

## The rig's state at the start of every run

Every run starts from scratch, so any command may change the configuration.

- **Config:** `tools/fnconfig-rig.ini`.
  - WiFi "Dummy Cafe" / swordfish. This is fujinet-pc, so WiFi is a stand-in.
  - Host slots: 1 SD, 2 tnfs.fujinet.online, 3 apps.irata.online. These are slots 0–2
    on the wire.
  - Printer type 1. Modem enabled. Time zone UTC.
- **SD:** a fresh copy of `tools/sd/` with:
  - `test/blank.h8d`;
  - `test/disk.img`, where sector n is filled with byte n, 512-byte sectors;
  - `test/readme.txt`.
  - Add files to `tools/sd/` if an example needs them, and say so in your report.
- **Helper servers** (`tools/helpers.py`), on 127.0.0.1:
  - **7801 TCP test board:** echoes keys; a line comes back in capitals; `BYE` hangs up.
  - **7802 HTTP:**
    - GET `/hello.txt`, `/data.bin` (3000 bytes), `/fuji.json`, `/iss-now.json`,
      `/astros.json`;
    - POST and PUT are logged and answered with "GOT n BYTES";
    - DELETE is logged.
  - **7803:** the helper connects to FujiNet's TCP server here every few seconds and
    sends `PING\r\n`.
  - **7804/7805 UDP:** the helper sends "PING" to 7804 every second from 7805, and logs
    what comes back to 7805.
- **Use only SD and the local helpers in exercisers.** The internet is not reliable
  enough for a build.

## Commands that cannot run normally

Still write both snippets, so the reader can see the code. Then:

- **Run it if the run survives it.** Each run's config is thrown away, so SET_SSID,
  WRITE_HOST_SLOTS, SET_BOOT_MODE and the like are fine to send.
- **Run it last** if it ends the run. RESET has no reply and restarts fujinet-pc.
  Expect TMO.
- **If it would wedge the rig** (a ROM-type mount pushes frames to device FFH; ATCPM
  crashes fujinet-pc), do not send it. Give it an entry in `expect/` with
  `"sent": false` and the reason.

## expect/<prog>.json

One entry per key:

```json
{ "fuji.get_host_prefix": {"reply": "ACK", "len": 256},
  "fuji.new_disk": {"reply": "NAK", "trap": "always NAKs on this build (fn-h89/lib/device/rs232/rs232Fuji.cpp:NNN)"},
  "fuji.reset": {"reply": "none", "note": "no ACK; fujinet-pc restarts", "last": true},
  "fuji.scan_networks": {"reply": "ACK", "tag": "STAND-IN WIFI"} }
```

- `reply` is ACK, NAK, none or raw. `len` is optional.
- `tag` is one of:
  - `STAND-IN WIFI`;
  - `NOT SENT, COMPUTED`;
  - `UNFRAMED`;
  - `OUTPUT CHECKED ON HOST`;
  - `NAK`.
- `trap` cites fwspec when the result is a firmware bug.
- If the firmware's behaviour differs from what `data/fwspec` says, **say so**: in a
  `"surprise"` field, and in your report.
