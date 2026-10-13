# Errata: the H89 FujiNet's software, as this manual found it

Everything below behaves differently from what a programmer would
reasonably expect. The manual documents today's behaviour, with a WARNING
and a workaround where it matters, so its examples work as printed. This
list is the place to check when a newer firmware, fujinet-lib or z88dk
comes out: each entry cites the line of source it comes from.

Versions: fn-h89 `h89-disk-fixes` 7ab84ae64; fujinet-lib
`h89-keep-esp32-running` 9e6d4dd; z88dk v2.4-1231 (3bd06cad56);
fujinet-pc built from the same firmware.


## FujiNet device (70H)

- **F1 FUJI_RESET**: No reply at all: the base handler table runs first (fn-h89/lib/device/rs232/rs232Fuji.cpp:215) and never ACKs; rs232Fuji's case FUJI_RESET -> fujicmd_reset(), which would ACK first (fn-h89/lib/device/fujiDevice/fujiDevice.cpp:405-411), is unreachable (`fn-h89/lib/device/rs232/rs232Fuji.cpp:228-230`)
- **F2 FUJI_DEVICE_READY**: Debug/test command left in the RS232 switch; one of only two commands reached through rs232Fuji's own switch.
- **F3 FUJI_STATUS**: Always 4 zero bytes. rs232_status() (reqtype 1 = per-drive mount times, 8 x time_t) is dead code: base table handles FUJI_STATUS before the rs232 switch . The switch's paramCount<1 NAK is also unreachable. (`fn-h89/lib/device/rs232/rs232Fuji.cpp:66-90, 220-227`)
- **F4 FUJI_GET_ADAPTERCONFIG**: fn_version is truncated to 14 characters (`fn-h89/lib/device/fujiDevice/fujiDevice.cpp:1232`)
- **F5 FUJI_GET_ADAPTERCONFIG_EXTENDED**: String fields are filled even when not connected (`fn-h89/lib/device/fujiDevice/fujiDevice.cpp:1250-1259`)
- **F6 FUJI_SCAN_NETWORKS**: ESP32 scan is blocking and temporarily disconnects an associated station (`fn-h89/lib/hardware/fnWiFi.cpp:370-405`)
- **F7 FUJI_SET_SSID**: Failure sends two NAK frames: fujicore_net_set_ssid_success() NAKs  and fujicmd_net_set_ssid_success() NAKs again (fn-h89/lib/device/fujiDevice/fujiDevice.cpp:569). fujinet-lib resyncs on the next SLIP_END (fujinet-lib/bus/h89/port_slip.c:56-68) and so reads the stray NAK as the reply to the NEXT command: replies run one behind. (`fn-h89/lib/device/fujiDevice/fujiDevice.cpp:540`)
- **F8 FUJI_SET_SSID**: ACK does not mean associated: ESP32 connect() returns esp_wifi_connect()'s immediate status ; a wrong password is ACKed and saved. (`fn-h89/lib/hardware/fnWiFi.cpp:149-204`)
- **F9 FUJI_GET_SSID**: Returns the saved WiFi passphrase in plain text (`fn-h89/lib/device/fujiDevice/fujiDevice.cpp:431-433, 444`)
- **F10 FUJI_WRITE_HOST_SLOTS**: Buffer is not zeroed : a payload shorter than 256 bytes fills the remaining slots with stack garbage. (`fn-h89/lib/device/fujiDevice/fujiDevice.cpp:1444`)
- **F11 FUJI_MOUNT_HOST**: Once hostMounted is set the mount is not retried  even if the server went away. (`fn-h89/lib/device/fujiDevice/fujiDevice.cpp:459`)
- **F12 FUJI_UNMOUNT_HOST**: On the SD host the disks are unmounted and their slots cleared BEFORE the NAK (`fn-h89/lib/device/fujiDevice/fujiDevice.cpp:1553-1568`)
- **F13 FUJI_UNMOUNT_HOST**: MOUNT_ALL and COPY_FILE mount hosts without setting hostMounted, so UNMOUNT_HOST after them NAKs.
- **F14 FUJI_SET_HOST_PREFIX**: COPY_FILE breaks once a prefix longer than "/" is set (see FUJI_COPY_FILE).
- **F15 FUJI_GET_HOST_PREFIX**: prefix[] is never zeroed ; strlcpy writes only up to the NUL (fn-h89/lib/fuji/fujiHost.cpp:300-306): the tail of the reply is garbage. (`fn-h89/lib/device/fujiDevice/fujiDevice.cpp:1396`)
- **F16 FUJI_OPEN_DIRECTORY**: MOUNT_HOST first: dir_open fails on an unmounted host.
- **F17 FUJI_OPEN_DIRECTORY**: With a path < 253 chars the pattern pointer is never null; an empty pattern is passed as "" (`fnFsTNFS.cpp:296 then indexes realpat[-1]`)
- **F18 FUJI_READ_DIR_ENTRY**: addtl 0xC0 (block mode, group size 0) divides by zero at fn-h89/lib/device/fujiDevice/fujiDevice.cpp:887 -> SIGFPE on fujinet-pc, panic/reboot on ESP32.
- **F19 FUJI_READ_DIR_ENTRY**: With 0x80 keep maxlen >= 14: set_additional_direntry_details does uint8_t maxlen -= 12 , smaller values wrap and the reply is cut mid-header. (`fn-h89/lib/device/rs232/rs232Fuji.cpp:199`)
- **F20 FUJI_READ_DIR_ENTRY**: TRUNC flag and slash rules disagree by one for directories: a dir name of maxlen-13 chars gets TRUNC although only the '/' was dropped; one of maxlen-14 chars gets neither '/' nor TRUNC (`fn-h89/lib/device/rs232/rs232Fuji.cpp:199-205 vs fn-h89/lib/device/fujiDevice/fujiDevice.cpp:1004-1020`)
- **F21 FUJI_READ_DIR_ENTRY**: Plain .img files report mediatype 0 (unknown), not 1 (`fn-h89/lib/media/rs232/diskType.cpp:64-95`)
- **F22 FUJI_READ_DEVICE_SLOTS**: Empty slots report mode 0x01 . (`fujiDisk default, fn-h89/lib/fuji/fujiDisk.cpp:9`)
- **F23 FUJI_READ_DEVICE_SLOTS**: mode reflects SET_DEVICE_FULLPATH / WRITE_DEVICE_SLOTS, not the mode passed to MOUNT_IMAGE . (`MOUNT_IMAGE never stores it, fn-h89/lib/device/fujiDevice/fujiDevice.cpp:592-635`)
- **F24 FUJI_WRITE_DEVICE_SLOTS**: Filenames in the payload are ignored: fujiDisk::reset(fname, ...) never copies fname . Paths can only be set with SET_DEVICE_FULLPATH. (`fn-h89/lib/fuji/fujiDisk.cpp:15-25`)
- **F25 FUJI_WRITE_DEVICE_SLOTS**: hostSlot 0xFF drops the slot from fnconfig.ini (path gone after restart) while the RAM filename stays and READ_DEVICE_SLOTS still shows it (`fn-h89/lib/device/fujiDevice/fujiDevice.cpp:221-222`)
- **F26 FUJI_WRITE_DEVICE_SLOTS**: No host-slot validation: a value 8..254 with an existing filename makes MOUNT_ALL use _fnHosts[] out of bounds (`fn-h89/lib/device/fujiDevice/fujiDevice.cpp:239,248`)
- **F27 FUJI_WRITE_DEVICE_SLOTS**: Buffer not zeroed : a short payload gives the remaining slots garbage host/mode. (`fn-h89/lib/device/fujiDevice/fujiDevice.cpp:1619`)
- **F28 FUJI_SET_DEVICE_FULLPATH**: Missing field aborts the firmware: the rs232 switch's paramCount<3 guard  is unreachable. (`fn-h89/lib/device/rs232/rs232Fuji.cpp:334-342`)
- **F29 FUJI_MOUNT_IMAGE**: ROM-type extensions  push the whole file before replying: FujiNet sends its own command frames to device 0xFF (NET_OPEN 0x4F with 5-byte payload id+u32 size, NET_WRITE 0x57 chunks, NET_CLOSE 0x43 [+0x01 abort]) and waits for ACKs (fn-h89/lib/device/rs232/disk.cpp:28-110, 305-315; fn-h89/lib/bus/rs232/rs232.h:178-186). On the H89 a .BIN file is therefore not a disk image. (`.ROM .BIN .INT .ITV .CHF .NES .SMS .A78 .A52 .ST2, fn-h89/lib/media/rs232/diskType.cpp:86-93`)
- **F30 FUJI_MOUNT_IMAGE**: Needs filename+host from SET_DEVICE_FULLPATH (or saved config) and a mounted host; it does not mount the host itself.
- **F31 FUJI_MOUNT_IMAGE**: Repeated MOUNT_IMAGE with a prefix set re-applies the prefix to the already-prefixed filename.
- **F32 FUJI_MOUNT_ALL**: Out-of-range host_slot 8..254 (possible via WRITE_DEVICE_SLOTS) indexes _fnHosts out of bounds (`fn-h89/lib/device/fujiDevice/fujiDevice.cpp:239,248`)
- **F33 FUJI_NEW_DISK**: Leaves a 0-byte file behind and a dangling _fnDisks[slot].fileh (closed handle never set to nullptr, fn-h89/lib/device/rs232/rs232Fuji.cpp:150,159); fileh != nullptr is what image rotation tests (`fn-h89/lib/device/fujiDevice/fujiDevice.cpp:324,349`)
- **F34 FUJI_NEW_DISK**: Reached only through rs232Fuji's switch (not in the base table).
- **F35 FUJI_SET_BOOT_MODE**: Mode 0 puts the RS232 MS-DOS boot disk (360 KB FAT12, fn-h89/data/webui/device_specific/BUILD_RS232/autorun.img) on drive 0x31 even though setup() deliberately skips it on PINMAP_H89 (`fn-h89/lib/device/rs232/rs232Fuji.cpp:38-43`)
- **F36 FUJI_SET_BOOT_MODE**: Always ACKs: invalid mode, missing image (only autorun.img ships for BUILD_RS232) or TNFS failure mount nothing silently (`fn-h89/lib/device/fujiDevice/fujiDevice.cpp:678-702`)
- **F37 FUJI_CONFIG_BOOT**: Despite the name it never changes boot_config or the saved config; boot_config is only written, never read, on BUILD_RS232.
- **F38 FUJI_COPY_FILE**: Fails whenever a host prefix longer than "/" is set: each path is opened with fullpathlen = path length + 1 (fn-h89/lib/device/fujiDevice/fujiDevice.cpp:1126-1132), so prefix+path never fits and fnfile_open returns null (`fn-h89/lib/fuji/fujiHost.cpp:245-254`)
- **F39 FUJI_COPY_FILE**: The trailing-'/' rule only works if the LAST payload byte is '/': a NUL-terminated or padded spec disables it.
- **F40 FUJI_COPY_FILE**: fread/fwrite results are not checked: a short copy still ACKs (`fn-h89/lib/device/fujiDevice/fujiDevice.cpp:1148-1152`)
- **F41 FUJI_COPY_FILE**: Missing field aborts: the rs232 switch's guard  is unreachable. (`fn-h89/lib/device/rs232/rs232Fuji.cpp:375-383`)
- **F42 FUJI_OPEN_APPKEY**: Any mode other than 0xFF is accepted; mode 2 still reads only 64 bytes . (`MAX_APPKEY_LEN, fn-h89/lib/device/fujiDevice/AppKeyMixin.h:6`)
- **F43 FUJI_READ_APPKEY**: Never NAKs: no SD, no OPEN, OPEN in write mode, or missing file all return ACK with length 0 (`fn-h89/lib/device/fujiDevice/AppKeyMixin.cpp:84 empty buffer; failure paths fn-h89/lib/device/fujiDevice/AppKeyMixin.cpp:87-108`)
- **F44 FUJI_WRITE_APPKEY**: An empty/missing payload writes a 0-byte key (truncating an existing one) and ACKs (`fn-h89/lib/device/fujiDevice/AppKeyMixin.cpp:189, 139, 172-175`)
- **F45 FUJI_BASE64_ENCODE_INPUT**: transaction_get's result is ignored : no payload appends len zero bytes and ACKs. (`fn-h89/lib/device/fujiDevice/Base64Mixin.cpp:21`)
- **F46 FUJI_BASE64_ENCODE_INPUT**: Encode and decode share ONE buffer  and there is no clear command: unread output from a previous operation is prepended to the next input. (`global base64.base64_buffer, fn-h89/lib/encoding/base64.h:62`)
- **F47 FUJI_BASE64_ENCODE_COMPUTE**: Output uses the standard alphabet with '=' padding AND inserts '\n' after every 72 characters plus a final '\n' ; ENCODE_LENGTH counts them. (`fn-h89/lib/encoding/base64.cpp:39-42, 61-62`)
- **F48 FUJI_BASE64_DECODE_INPUT**: Payload result ignored : missing payload appends zeros and ACKs. (`fn-h89/lib/device/fujiDevice/Base64Mixin.cpp:109`)
- **F49 FUJI_BASE64_DECODE_INPUT**: Encode and decode share ONE buffer  and there is no clear command: unread output from a previous operation is prepended to the next input. (`global base64.base64_buffer, fn-h89/lib/encoding/base64.h:62`)
- **F50 FUJI_BASE64_DECODE_COMPUTE**: Encode and decode share ONE buffer  and there is no clear command: unread output from a previous operation is prepended to the next input. (`global base64.base64_buffer, fn-h89/lib/encoding/base64.h:62`)
- **F51 FUJI_HASH_INPUT**: Payload result ignored : missing payload hashes len zero bytes. (`fn-h89/lib/device/fujiDevice/HashMixin.cpp:23`)
- **F52 FUJI_HASH_COMPUTE**: Unknown algorithm still ACKs, leaves an empty digest (LENGTH 0, OUTPUT 0 bytes) and still clears the data.
- **F53 FUJI_HASH_LENGTH**: Reply is ONE byte, unlike the u32 Base64/QR lengths.
- **F54 FUJI_QRCODE_INPUT**: Payload result ignored (`fn-h89/lib/device/fujiDevice/QRMixin.cpp:22`)
- **F55 FUJI_QRCODE_ENCODE**: All three fields are required: a two-field packet aborts the firmware.
- **F56 FUJI_QRCODE_LENGTH**: After OUTPUT has consumed the whole code, LENGTH returns 0 and cannot re-render.
- **F90 FUJI_SET_DEVICE_FULLPATH (emptying a slot)**: An empty path sets the slot's host slot to FFH but leaves the old path, which FUJI_GET_DEVICE_FULLPATH still returns: the slot is not emptied. And a request that itself gives host slot FFH (what FUJI_READ_DEVICE_SLOTS reports for an empty slot) is refused with NAK, even with an empty path. Only FUJI_UNMOUNT_IMAGE empties a slot. (`fn-h89/lib/device/fujiDevice/fujiDevice.cpp:1311-1324, fn-h89/lib/fuji/fujiDisk.cpp:3-12; observed: build/runs/libtest-fujidev-cpm, libtestfix-fujidev-hdos`)
- **F91 FUJI_COPY_FILE (time)**: The ACK comes only when the copy is finished. A 161,280-byte image from tnfs.fujinet.online took from 14.4 to 18.2 s in six runs, four of them more than the 15 s that fujinet-lib and the book's library wait for a reply (see L21). (`observed: build/runs/libtest{,fix,slow}-disk-{hdos,cpm}/tap.jsonl`)

## Network channels (71H-78H)

- **N1 NET_OPEN**: Two fields are mandatory even when aux2 is 0; one field (or a single u16) crashes the firmware (`NDevice.cpp:136-137, FujiBusPacket.h:75-77`)
- **N2 NET_OPEN**: On TNFS:// and SD:// an aux1 other than 4/6/7/8/9/12 reaches abort() - firmware reboot (`fn-h89/lib/network-protocol/TNFS.cpp:54-56, SD.cpp:56-58`)
- **N3 NET_OPEN**: A '*' in a non-directory URL (e.g. in an HTTP query string) is turned into NUL and truncates the URL (`utils.cpp:953`)
- **N4 NET_OPEN**: A URL ending in '.' loses the dot (`utils.cpp:957-960`)
- **N5 NET_OPEN**: Terminate the spec with NUL or CR LF; a lone CR stays inside the URL (`NDevice.cpp:27-29`)
- **N6 NET_OPEN**: HTTP aux1 4 and 8 URL-encode the path (so do not pre-encode); 5/9/12/13/14 send it verbatim (`HTTP.cpp:310-316`)
- **N7 NET_OPEN**: UDP OPEN without a port NAKs but leaves STATUS err = 1 (error never set) (`UDP.cpp:50-54, NDevice.cpp:182`)
- **N8 NET_CLOSE**: HTTP POST (aux1 13/14) and DELETE (5/9) are never sent if no STATUS/READ happened before CLOSE: resultCode 0 means 'no transaction' and close just succeeds (`HTTP.cpp:553-564`)
- **N9 NET_READ**: TCP: READ with nothing pre-buffered asks the socket for exactly 'length'; a short read NAKs with err 202 and the bytes that did arrive are thrown away . Always STATUS first (it pre-reads into the buffer, Protocol.cpp:169-175) and ask for no more than bytes-waiting (`TCP.cpp:123-139`)
- **N10 NET_READ**: HTTP body with nothing buffered: client read short -> NAK and the partial bytes are lost (`HTTP.cpp:508-514, FS.cpp:303-312`)
- **N11 NET_READ**: UDP with empty buffer pads the reply with zero bytes up to 'length' (`UDP.cpp:102,115-118`)
- **N12 NET_READ**: HTTP GET_HEADERS mode: each READ consumes one header and copies exactly 'length' bytes from it (over-read when length > header); a READ after the last header indexes past the vector - undefined, may crash (`HTTP.cpp:490-495`)
- **N13 NET_READ**: If NET_SET_PARSER was sent while no channel was open, READ dereferences a null protocol - crash (`NDevice.cpp:543-561, NParser.cpp:5`)
- **N14 NET_WRITE**: Payload shorter than the length field: zero bytes are appended up to 'length' and written ; longer: the excess is ignored (`NDevice.cpp:276-281, rs232.cpp:77-81`)
- **N15 NET_WRITE**: A failed write leaves its bytes in the transmit buffer; they are prepended to the next WRITE and retried at CLOSE (FS.cpp:351-356, TCP.cpp:166-196, Protocol.cpp:127-128). NET_SET_HTTP_MODE clears the buffer (`HTTP.cpp:69-70`)
- **N16 NET_WRITE**: Write translation looks for the full native EOL (CR LF unless NET_SET_EOL changed it); a lone CR is not translated (`Protocol.cpp:231, rs232.h:165`)
- **N17 NET_WRITE**: A STATUS on an HTTP PUT channel before CLOSE fires the PUT early with the data so far (empty body -> client returns -1 -> err 144); CLOSE then PUTs again (`HTTP.cpp:430-436, 553-554, fn-h89/lib/http/mgHttpClient.cpp:982-983`)
- **N18 NET_STATUS**: No channel: 00 00 00 CF (207 NOT_CONNECTED) (NDevice.cpp:309-314); after a failed OPEN or CLOSE: 00 00 00 <reason> (`NParser.h:31-51`)
- **N19 NET_STATUS**: UDP under-reports: STATUS pre-reads the waiting datagram into the receive buffer, then computes avail from udp.available() - the NEXT datagram - so a single pending datagram shows avail 0 . The datagram is still returned by a READ (`Protocol.cpp:169-175, NDevice.cpp:317-319, UDP.h:72, fn-h89/lib/tcpip/fnUDP.cpp:286-314`)
- **N20 NET_STATUS**: err 136 appears as soon as an FS file or HTTP body is fully consumed, including right after a JSON PARSE (body consumed) and before QUERY fills the buffer (`FS.cpp:398, HTTP.cpp:443-444`)
- **N21 NET_STATUS**: After a failed PARSE err stays 213 (JSON) or 144 (HTML/XML) on every STATUS (`NParser.cpp:58-59`)
- **N22 NET_STATUS**: HTTP GET_HEADERS mode: STATUS (and the background interrupt poll via available()) fires the request if not done yet (`HTTP.cpp:456-458, 959-961`)
- **N23 NET_PARSE**: On a stream that stays connected (e.g. TCP) PARSE does not return until the peer disconnects (fnjson.cpp:364); the H89 library times out after 15 s of silence (`fujinet-lib/bus/h89/fuji_bus_call.c:14`)
- **N24 NET_QUERY**: Querying a value that is, or contains, an empty array [] crashes the firmware: the array loop dereferences a null child . Any query whose result includes [] - including the empty query on a document containing [] - triggers it (`fnjson.cpp:301-307`)
- **N25 NET_QUERY**: Flag 0x04 with a string holding '<' but no later '>' loops forever (`fnjson.cpp:135-144`)
- **N26 NET_QUERY**: HTML/XML: the RS232 handler keeps a trailing NUL and any bytes after it in the selector string  - send exactly the selector bytes (`rs232Network.cpp:9; fnhtml.cpp:80-112 compares/parses the whole std::string`)
- **N27 NET_QUERY**: NET_SET_PARSER while no channel was open, then QUERY -> null protocol dereference crash (`JSONParser.cpp:23`)
- **N28 NET_SET_PARAMETER**: NET_SET_PARSER builds a fresh parser and resets flags and line ending: send SET_PARAMETER after SET_PARSER (`NDevice.cpp:543-569, JSONParser.h:14-17`)
- **N29 NET_SET_PARAMETER**: param 1 with parser NONE after SET_PARSER-before-OPEN dereferences a null protocol (`NParser.cpp:68-72`)
- **N30 NET_SET_PARSER**: Does not check for an open channel: with none it creates a parser bound to a null protocol, and a later READ, QUERY, SEEK/TELL (mode 0) or SET_PARAMETER 1 (mode 0) crashes the firmware (`NDevice.cpp:548-561, NParser.cpp:5,33,70, JSONParser.cpp:23`)
- **N31 NET_SET_PARSER**: OPEN resets the parser to NONE : send SET_PARSER after OPEN (`NDevice.cpp:154,188`)
- **N32 NET_SET_PARSER**: Write HTTP POST data before switching to JSON - writes NAK afterwards (`JSONParser.cpp:3-6`)
- **N33 NET_TRANSLATION**: OR semantics: override 1 with aux2 2 gives mode 3 (CR LF) (`NDevice.cpp:174`)
- **N34 NET_SET_EOL**: A NUL terminator in the payload becomes part of the line ending
- **N35 NET_SET_INT_RATE**: rate 0: poll_interrupt divides by timerRate*2 - integer division by zero, firmware crash once a channel is open on that unit (NDevice.cpp:861,867); poll_interrupt runs on the H89 card too (`rs232.cpp:173-183`)
- **N36 NET_SET_INT_RATE**: On the H89 card the data-ready signal goes nowhere: ESP32 calls setRI(), a no-op on PPIChannel (rs232.cpp:186-187, PPIChannel.h:48); fujinet-pc drives DTR/RTS only on a real serial port with serial_proceed configured, never under BoIP (`rs232.cpp:184-199`)
- **N37 NET_SEEK**: The seek is performed twice  - on HTTP that is two Range requests (`NDevice.cpp:672-676`)
- **N38 NET_TELL**: No channel: the 4 bytes are uninitialised stack contents - u32le_t has no constructor (`NDevice.cpp:697-704, fn-h89/include/global_types.h:69-71`)
- **N39 NET_TELL**: TNFS/SD: the seek(0,SEEK_CUR) clears the receive buffer, so bytes STATUS pre-read (translation read-ahead) are discarded and the position reported is past them (`TNFS.cpp:333-341, SD.cpp:338-346`)
- **N40 NET_TELL**: HTTP reports bytes fetched from the server so far (`HTTP.cpp:510-512, 811-812`)
- **N41 NET_TELL**: Parser NONE bound to a null protocol (SET_PARSER before OPEN) -> crash (`NParser.cpp:33`)
- **N42 NET_CHDIR**: CR/LF are NOT stripped (unlike OPEN): a CR LF-terminated payload puts CR LF into the prefix and into every later relative OPEN (`NDevice.cpp:420`)
- **N43 NET_CHDIR**: A packet with no payload clears the prefix (`transaction_get failure ignored, NDevice.cpp:419`)
- **N44 NET_USERNAME**: If the user name is empty the password is not passed either (`NetworkProtocolFactory.cpp:125-129`)
- **N45 NET_PASSWORD**: Ignored unless a user name is also set (`NetworkProtocolFactory.cpp:125`)
- **N46 NET_RENAME**: Kills whatever channel was open on the unit - buffered writes/HTTP PUT lost, no close (`NDevice.cpp:498,738-739`)
- **N47 NET_RENAME**: Failure reason is lost: STATUS afterwards says 207 (`NDevice.cpp:309-314`)
- **N48 NET_RENAME**: TNFS without a comma ACKs and does nothing (`TNFS.cpp:231-232`)
- **N49 NET_RENAME**: FTP: ACK, nothing done (FTP.h:37); GDRIVE has no override - only parses, ACKs (`FS.cpp:463-486, GDRIVE.h:41-43`)
- **N50 NET_RENAME**: HTTP: WebDAV MOVE with Destination set to a server path, not a full URL (`HTTP.cpp:885-900`)
- **N51 NET_DELETE**: FTP: ACK, nothing deleted (`FTP.h:44`)
- **N52 NET_DELETE**: channel on the unit destroyed; error reason lost
- **N53 NET_LOCK**: Silent no-op ACK on FTP (FTP.h:65), NFS (NFS.cpp:360-363) and every protocol without an override - HTTP, SMB, S3, GDRIVE, ONEDRIVE (`FS.h:124`)
- **N54 NET_UNLOCK**: Silent no-op ACK where not implemented (`FS.h:131; NFS.cpp:365-368; FTP has no unlock override so the FS default applies`)
- **N55 NET_MKDIR**: FTP: ACK, nothing created (`FTP.h:51`)
- **N56 NET_MKDIR**: TNFS MKDIR/RMDIR never unmount their session (`TNFS.cpp:260-284`)
- **N57 NET_RMDIR**: FTP: ACK, nothing removed (`FTP.h:58`)
- **N58 NET_ACCEPT**: Poll STATUS first: on a listener with no client 'connected' = 1 means a client is waiting (`TCP.cpp:225-229`)
- **N59 NET_CLOSE_CLIENT**: Return value inverted: NAK = client closed, ACK = nothing was closed (`TCP.cpp:347,354,370`)
- **N60 NET_SET_HTTP_MODE**: Any response bytes still buffered are discarded by the mode switch (`HTTP.cpp:69`)
- **N61 NET_GET_REMOTE**: Overwrites the first ~22 bytes of an unread datagram, and writes past the string's allocation when the receive buffer is empty/small; then sends 256 bytes read from that storage (`NDevice.cpp:834-835`)
- **N62 NET_GET_REMOTE**: Before any datagram arrived the address is fnUDP's initial remote_ip/remote_port (`fn-h89/lib/tcpip/fnUDP.cpp:349-357`)
- **N63 NET_SET_DESTINATION**: ESP32 extracts the host with substr(first_colon+1, last_colon-2), correct only when the first colon is at index 1: 'N:host:port' works, 'N1:host:port' yields 'host:' and sends fail (`UDP.cpp:211-212`)
- **N64 NET_SET_DESTINATION**: fujinet-pc builds the string with strlen on a payload that is not NUL-terminated - send a trailing NUL (`UDP.cpp:197-200, NDevice.cpp:847`)
- **N65 NET_SET_DESTINATION**: Any STATUS after a datagram arrives replaces the destination with that datagram's sender (`UDP.cpp:169-183`)
- **N90 NET_QUERY (ASCII flag)**: With query flag 10H (ASCII output) a JSON string's LF line ending is turned into a space, which network_json_query() does not strip: "FujiNet " comes back for "FujiNet". Numbers are not affected. (`fn-h89/lib/fnjson/fnjson.cpp:228, fn-h89/lib/fntext/fn_sanitize.cpp:658-660`)
- **N91 NET_READ on HTTP (correction)**: A READ larger than what is buffered returns what is there (FS.cpp caps the request to available()); it NAKs only when nothing is available. (`fn-h89/lib/network-protocol/FS.cpp:294-297`)
- **N92 NET_GET_REMOTE**: Overwrites a buffered datagram (the next READ returned '127.'); before any datagram it answers 255.255.255.255:0. (`observed on fujinet-pc; fn-h89/lib/device/NDevice/NDevice.cpp:834-835`)

## The bus

- **B1 framing**: On 0xC0 the bus collects bytes until a second 0xC0 has been read; that span is the frame . A frame must therefore be exactly C0 <body> C0: a doubled leading C0 (C0 C0 <body> C0) produces an empty 2-byte frame that is rejected silently, the body bytes are then read as raw modem data, and the trailing C0 opens a bogus frame (derived from rs232.cpp:99-116 + 337-359 and FujiBusPacket.cpp:150-151) (`fn-h89/lib/bus/rs232/rs232.cpp:337-366`)
- **B2 framing**: Frame rejected if: encoded span < 8 bytes or does not start and end with 0xC0 ; decoded < 6 bytes (157-158); header length != decoded length (164-165); checksum mismatch (170-176); descriptor chain or fields run past the end (193-194, 212-213) (`FujiBusPacket.cpp:150-153`)
- **B3 params**: param(n) returns _params.at(n).value as uint32 regardless of the field's wire size ; devices never check the field width, so a u8, u16 or u32 field all work where a number is expected (`fn-h89/lib/bus/rs232/FujiBusPacket.h:75-77`)
- **B4 params**: A missing field makes .at() throw std::out_of_range. ESP32 H89 build has C++ exceptions off (fn-h89/sdkconfig.fujinet-heathkit-h89:422) so it aborts (reboot); fujinet-pc terminates on the uncaught exception. Guarded: disk R/P/W (disk.cpp:385-388), disk STATUS (395-396), clock alt flag (rs232Clock.h:14-17), printer STATUS (printer.cpp:241). Unguarded: modem SET_DUMP, LISTEN, BAUDRATELOCK (2 fields), AUTOANSWER, STATUS (`modem.cpp:1632, 1635, 1641, 1644, 1648`)
- **B5 replies**: Data is attached only when ack is true; a NAK never carries data, even when the handler supplied some (`rs232.cpp:390-394`)
- **B6 replies**: Exactly one reply per accepted frame except: bad frame (silence), printer disabled , modem disabled (silence, modem.cpp:1612-1615), modem ACK/NAK (no bytes), and ROM mount pushes (extra unsolicited frames to device 0xFF before the Fuji reply, disk.cpp:28-110) (`silence, printer.cpp:226-229`)
- **B7 replies**: transaction_success asserts the state is NO_GET/DID_GET ; assertions are enabled on the ESP32 H89 build (sdkconfig.fujinet-heathkit-h89:414), so a success after an error aborts (see modem LISTEN 0) (`rs232.cpp:55`)
- **B8 errors**: Read timeout inside a frame (gap longer than the channel read timeout): frame is incomplete, parse fails, silence (rs232.cpp:355-359, 365). The bytes that arrive after the gap are then read as raw modem data until the next C0 (`rs232.cpp:99-107`)
- **B9 errors**: The bus does not consult device_active / enable state before dispatch ; each device decides (`rs232.cpp:126-128`)

## Disk drives (31H-38H)

- **D1 DISK_READ**: Sector numbers are 0-based although diskTypeImg.cpp:16 says '1-based' (`diskTypeImg.cpp:17-20`)
- **D2 DISK_READ**: A trailing partial 512-byte block of an IMG is unreachable: sector count = size/512 truncated (`diskTypeImg.cpp:162`)
- **D3 DISK_READ**: An IMD sector with a data error or deleted mark is still returned with ACK; only DISK_STATUS shows it (`diskTypeIMD.cpp:173-183`)
- **D4 DISK_WRITE**: verify flag (WRITE vs PUT) is ignored by every media type (`diskTypeImg.cpp:63-105; diskTypeIMD.cpp:193`)
- **D5 DISK_WRITE**: IMD out-of-range sector: sector_size()=0 -> zero-length get succeeds -> write() NAKs (`diskTypeIMD.cpp:245-250; rs232.cpp:71-72`)
- **D6 DISK_PUT**: Identical to DISK_WRITE; the only difference  is ignored downstream (`verify=false, disk.cpp:392`)
- **D7 DISK_STATUS**: Answers even with nothing mounted: 00 FF E0 00 (`disk.cpp:206-217`)
- **D8 DISK_STATUS**: IMG never reports double density: _disk_sector_size stays at its 128 default  because MediaTypeImg::mount never sets it (diskTypeImg.cpp:157-166, 111-112). Normal IMG reply: 00 FF E0 00 (`diskType.h:57`)
- **D9 DISK_STATUS**: ROM media: 00 00 00 00 (`diskTypeROM.cpp:48-51`)
- **D10 DISK_STATUS**: After unmount the stale media object still answers (`disk.cpp:212-213`)
- **D11 DISK_STATUS**: Was mapped onto WRITE before 7ab84ae64 (commit message); fixed at HEAD (`disk.cpp:394-397`)
- **D12 DISK_FORMAT**: FORMAT does not format: IMG just ACKs (`diskTypeImg.cpp:130-142`)
- **D13 DISK_FORMAT**: Reply length is _disk_sector_size = 128, not 512 (`diskTypeImg.cpp:139; diskType.h:57`)
- **D14 DISK_FORMAT**: No device_active check: after unmount an IMG drive still ACKs (`disk.cpp:226`)
- **D15 DISK_FORMAT_MEDIUM**: Alias of DISK_FORMAT
- **D16 DISK_PERCOM_READ**: IMG: all zeros, derive_percom_block is empty  - unless a DISK_PERCOM_WRITE stored something (`fn-h89/lib/media/rs232/diskType.cpp:39-42`)
- **D17 DISK_PERCOM_READ**: IMD: filled at mount: tracks=max cyl+1, step 1, spt=max, sides=heads-1, density, sector_size=largest sector, drive_present 0xFF (`diskTypeIMD.cpp:66-77`)
- **D18 DISK_PERCOM_READ**: Layout from fn-h89/lib/media/rs232/diskType.h:62-75
- **D19 DISK_PERCOM_WRITE**: ACKs even with no payload: transaction_get result is ignored (`disk.cpp:269-273`)

## Clock (45H)

- **C1 APETIME_GETTIME**: Year byte is tm_year-100, i.e. two-digit year from 2000 (`fujiClock.cpp:124`)
- **C2 APETIME_GETTZTIME**: With no alternate TZ set it falls back to the system TZ (`fujiClock.h:30-33`)
- **C3 APETIME_SETTZ_ALT2**: Despite the name this is the SIMPLE time GETTER on RS232: the read table claims 0x54 before the write table (`fujiClock.cpp:350-352, 385-390, 406-409`)
- **C4 APETIME_GET_SOS**: NUL included because rs232Clock does not override string_needs_null() (`fujiClock.h:76; fujiClock.cpp:264-268`)
- **C5 APETIME_SETTZ**: ACK is sent BEFORE validation ; an invalid TZ (e.g. payload starting with NUL, or a control char) is silently ignored but still ACKed (`fujiClock.cpp:212`)
- **C6 APETIME_SETTZ**: Any printable string is stored; POSIX validity is not checked
- **C7 APETIME_SETTZ_ALT**: ACK before validation, invalid TZ silently dropped (`fujiClock.cpp:212, 317-321`)
- **C8 APETIME_SETTZ_ALT**: Persists across reboots (writes config)

## Printer (40H)

- **R1 PRINTER_WRITE**: Buffer overrun: memcpy(provideBuffer(), data, len) with no bound into uint8_t buffer[320] - payloads > 320 bytes overwrite the emulator object (`printer.cpp:46; fn-h89/lib/printer-emulator/printer_emulator.h:41, 72`)
- **R2 PRINTER_WRITE**: Length truncated to 8 bits: process(uint8_t linelen, ...) gets len mod 256, so 256 bytes print nothing (still ACK) and 300 bytes print the first 44 (`printer.cpp:48; printer_emulator.h:68`)
- **R3 PRINTER_WRITE**: Default type FILE_TRIM writes up to and including the first 0x9B (ATASCII EOL) and drops the rest of the record . setEOL('\r') does not affect the file printer (`fn-h89/lib/printer-emulator/file_printer.cpp:20-27; fn-h89/include/atascii.h:12`)
- **R4 PRINTER_WRITE**: FILE_ASCII drops CR and LF (keeps only 32..122 except 96, after &0x7F) so lines run together on the H89 (`file_printer.cpp:28-58`)
- **R5 PRINTER_WRITE**: Printer disabled in config -> no reply at all (silence), not a NAK (printer.cpp:226-229); default enabled (`fn-h89/lib/config/fnConfig.h:487`)
- **R6 PRINTER_PUT**: Alias of PRINTER_WRITE
- **R7 PRINTER_STATUS**: Byte 1 is an uninitialized member (`printer.h:27; printer.cpp:96; object created with new at main.cpp:360`)
- **R90 output**: fujinet-pc writes the printer's output to the file paper in its SD directory. (`fn-h89/lib/printer-emulator/printer_emulator.cpp:7, 83-89`)

## Modem (50H)

- **M1 MODEM_CONTROL**: No reply bytes at all
- **M2 MODEM_CONFIGURE**: Always 9600 regardless of the request
- **M3 MODEM_SET_DUMP**: Missing field aborts the firmware
- **M4 MODEM_LISTEN**: port 0: transaction_error() then transaction_success() -> assert(state) fails -> abort on the ESP32 (assertions on) (`modem.cpp:372-380; rs232.cpp:55; sdkconfig.fujinet-heathkit-h89:414`)
- **M5 MODEM_BAUDRATELOCK**: Two fields required
- **M6 MODEM_STATUS**: Reply is 2 raw bytes, NOT a SLIP frame (`rs232.cpp:381-386`)
- **M7 MODEM_WRITE**: cmdOutput is forced false for the whole command  and every at_cmd_println() returns early when it is false (modem.cpp:468, 484, 504, 525): OK/ERROR/help/IP/echo text is never sent for commands given this way (`modem.cpp:105, 113`)
- **M8 MODEM_WRITE**: Numeric results (ATV0) still emit CR LF but the digits go to an unsent _packetData buffer (`modem.cpp:456-461, 1665-1683`)
- **M9 MODEM_WRITE**: No payload -> returns without action (`modem.cpp:100-101`)
- **M10 MODEM_STREAM**: fujinet-pc on a TTY: the HOST LINK baud changes to modemBaud (e.g. 9600 after MODEM_CONFIGURE) (rs232.cpp:323-335); PPI: setBaudrate is a no-op (PPIChannel.h:39); BoIP: skipped (`rs232.cpp:333`)
- **M11 MODEM_STREAM**: Raw 9-byte reply, not a frame
- **M90 ATDT / ATA**: After ATDT the far end's first data reaches the H89 before CONNECT (about a second ahead); after ATA a bare CR LF comes first, then the caller's data, then CONNECT. (`observed on fujinet-pc; fn-h89/lib/device/rs232/modem.cpp:1039-1040`)
- **M91 bare AT commands**: AT commands sent as bytes outside a frame are acted on about 500 ms after the last byte (the BoIP channel's read timeout on fujinet-pc). (`observed on fujinet-pc`)

## CP/M device (5AH)

- **X1 CPM_INIT**: Not registered, and ATCPM dereferences the null CPM pointer (`modem.cpp:1256-1257`)

## fujinet-lib

- **L1 descriptor flags on the wire**: fuji_bus_call puts its FUJI_FIELD_DATA (08H) and FUJI_FIELD_REPLY (10H) flags in the packet's descriptor byte. The firmware ignores bits 3-6, so no harm, but the bytes differ from other FujiBus clients'. (`fujinet-lib/bus/h89/fuji_bus_call.c:201`)
- **L2 port_putc**: No timeout: with the FujiNet not running, a C program hangs in its first call. (`fujinet-lib/bus/h89/portio.c:140-153`)
- **L3 FUJI_DIR_ENTRY_IS_DIR / _IS_TRUNC**: Use is_dir/is_trunc, which the H89's FujiDirEntry does not have (it has flags): code using them does not compile. Test flags & 1 and flags & 2. (`fujinet-lib/include/fujinet-fuji.h (FUJI_DIR_ENTRY_IS_*; FujiDirEntry for FUJI_PLATFORM_H89)`)
- **L4 fixed 256-byte payloads**: fuji_open_directory, fuji_set_host_prefix, fuji_set_device_filename and fuji_copy_file always send 256 bytes from the caller's string, so whatever follows its NUL is sent too (and the firmware may read it as a pattern or part of a path). Clear a 256-byte buffer first. (`fujinet-lib/include/fujinet-fuji.h (MAX_FILENAME_LEN in the FUJICALL_..._D macros)`)
- **L5 network_json_query**: Always sends 256 bytes of query and reads the answer into the caller's buffer with no limit. (`fujinet-lib/common/network_json_query.c:12-30`)
- **L6 network_bus_read**: Returns the length asked for on any ACK, even when fewer bytes came. (`fujinet-lib/bus/h89/network.c:6-9`)
- **L7 fuji_get_wifi_enabled**: Ignores whether the call succeeded and returns the last value it got. (`fujinet-lib/common/fuji_get_wifi_enabled.c`)
- **L8 clock_get_time**: Writes a NUL one byte past the reply: the buffer must be one byte longer than the format's reply. (`fujinet-lib/common/fuji_clock.c:51`)
- **L9 network_udp_set_destination**: Sends the devicespec without a NUL and with the unit prefix (N7:), which the firmware reads wrongly; the datagram does not arrive. Use fuji_bus_call with 'N:host:port' and a NUL. (`fujinet-lib/common/network_udp_set_destination.c`)
- **L10 network_read_nb**: Busy-loops forever while STATUS says nothing waiting and no error, e.g. on UDP (whose STATUS under-reports) or an idle server. (`fujinet-lib/common/network_read_nb.c`)
- **L11 fuji_get_time, fuji_enable_device, fuji_disable_device**: Send commands the H89's FujiNet does not have: always false. (`fujinet-lib/include/fujinet-fuji.h:268-269, 649`)
- **L12 unlinkable**: fn_error, network_proceed, network_has_proceed, network_get_dstats, fuji_enable_udpstream, fuji_get_device_enabled_status and _fuji_status are declared but not built for the H89. (`fujinet-lib/include/fujinet-network.h:49, 341-343; fujinet-fuji.h:239, 272, 300`)
- **L13 fuji_get_host_slots / fuji_get_device_slots**: The count must be 8: the reply is always all eight slots, and a smaller buffer makes the call fail. (`fujinet-lib/bus/h89/port_slip.c:87-90`)
- **L14 network_unit**: No range check: "N0:" addresses the FujiNet device (70H), so a network command arrives there as some other command (NET_SET_PARAMETER, FBH, as SET_SSID); "N9:" goes to 79H, "N10:" to unit 1. (`fujinet-lib/common/network_unit.c:3-12`)
- **L15 network_unit_status**: Returns 0 on success (the macro is !fuji_bus_call). (`fujinet-lib/include/fujinet-network.h:492`)
- **L16 fuji_open_directory_filter**: With a NULL pattern (which the header allows) it reads address 0 and sends what it finds as the pattern; with an empty one it sends the caller's memory after the path. (`fujinet-lib/common/fuji_open_directory_filter.c:16-19`)
- **L17 fuji_hash_data / fuji_hash_calculate**: Hex output has no NUL: the buffer needs fuji_hash_size() + 1. (`fujinet-lib/common/fuji_hash.c:28`)
- **L18 network_json_strip_newlines**: Writes buffer[buflen], one past the data. (`fujinet-lib/common/network_json.c:17`)
- **L19 qrcode_create**: Returns negative NETWORK_ERROR codes (-162, -215), not FN_ERR values. (`fujinet-lib/common/qrcode_create.c:12-27`)
- **L20 port_getbuf_slip_dual**: Does not read the closing END of a reply that fills its buffer exactly, which includes every bare ACK and NAK; the next read starts with a stray C0H. Harmless for fujinet-lib's own calls (they resynchronise on END), but a program mixing in raw reads (the modem) must drop it first. (`fujinet-lib/bus/h89/port_slip.c`)
- **L21 reply timeout**: fuji_bus_call() waits a fixed 15 s (TIMEOUT_SLOW) for a reply and has no way to drop a reply that arrives later. When FUJI_COPY_FILE took longer, fuji_copy_file() returned false and the late ACK was taken as the reply to the next request (a STATUS), after which every reply was one behind and the test program reported the FujiNet BROKEN. With TIMEOUT_SLOW at 60 s the copy test passed. Proposed: a longer timeout for slow commands, and a drain before each request. (`fujinet-lib/bus/h89/fuji_bus_call.c:14; observed: build/runs/libtest-disk-hdos/tap.jsonl`)

## fujinet-lib's test programs

- **T1 network: line ending**: BASIC_LINE_ENDING is "\n" for the H89, but the FujiNet's line ending on this bus is CR LF. The echo test opens with OPEN_TRANS_LF, so its LF comes back as CR LF, and the test, reading only as many bytes as it sent, compares CR with LF and stops: only 5 of the network program's 82 tests run. Fix: give the H89 "\r\n", as __WATCOMC__ has; then all 82 pass under both systems. (`fujinet-lib/testing/tests/network.c:16-25, 485`)
- **T2 disk: directory entry offset**: DIRENTRY_FILENAME_OFFSET is 13 for the H89, but on this bus a FUJI_READ_DIR_ENTRY header is 12 bytes (as for MS-DOS), so the name is compared from its second letter and the copied lobby.dsk is never found. Fixed (the H89 given 12, as MS-DOS has) and with TIMEOUT_SLOW raised (L21), the disk test passes under both systems. (`fujinet-lib/testing/tests/constants.h:60-66; fdsk.c:197`)
- **T3 fujidev: restoring a slot**: The test puts back an empty drive slot with FUJI_SET_DEVICE_FULLPATH, an empty path and the host slot FFH it read. The firmware refuses FFH, and even with 0 it leaves the test's name in the slot (F90), so the read-back fails and drive slot 0 is left named /test_filename. Fix: put back an empty slot with fuji_unmount_disk_image(). Fixed so, all 88 of the fujidev program's tests pass under both systems. (`fujinet-lib/testing/tests/fuji.c:250`)

## z88dk (HDOS)

- **Z1 load address**: The HDOS target's default CRT_ORG_CODE is 4480H: the split-octal address 042.200 (2280H) read as the plain octal number 042200. Programs work but waste 8.6K. Proposed fix: CRT_ORG_CODE = $2280 with a REGISTER_SP that is not inside the program. (`z88dk/lib/target/hdos/classic/hdos_crt0.asm (TAR__register_sp $447F, CRT_ORG_CODE $4480)`)
- **Z2 command line**: With startup=3 the start-up code pushes the entry SP, moves the stack (crt_init_sp, crt_init_atexit), then pops from the NEW stack, so the command line is split with a wrong length and argv[] is damaged. Proposed fix: replace the push/pop with ld hl,(__restore_sp_onexit+1). The book builds with CRT_ENABLE_COMMANDLINE=0 and hdos_args(). (`z88dk/lib/target/hdos/classic/hdos_crt0.asm (start: push hl ... pop hl)`)
- **Z3 hdos.def**: The HDOS system values (S_SYSM, S_USRM, S_DATE ...) are given 2000H too high, e.g. S_SYSM $40D0 for 20D0H: the same split-octal misreading. (`z88dk/lib/target/hdos/def/hdos.def:47-52`)
- **Z5 unsigned long %**: In ISS.C, t % 60UL (and % 60, (t / 60UL) % 60UL, (t / 3600UL) % 24UL) gave wrong results for t = 1760270400: the seconds came out 36, which is the remainder of t's low 16 bits. Division of the same long was right. The book subtracts whole days and works in 16 bits instead. Seen under HDOS with sccz80's default options; not narrowed down further. (`observed: build/runs/iss-c-hdos (before the fix); src/c/iss/iss.c print_stamp()`)

## z88dk

- **Z4 -l with a dotted library name**: zcc -lfujinet.h89-hdos does not find fujinet.h89-hdos.lib (the dot stops .lib being added); give the name in full: -lfujinet.h89-hdos.lib. (`observed with z88dk v2.4-1231`)

## fujinet-pc (the book's stand-in for the card)

- **P1 directory details**: READ_DIR_ENTRY with 80H returns blank details (size 0, 1969-12-31, in the host's time zone) for files below the top of the SD directory, and network directory listings show size 0: dir_open looks files up in the wrong place. The card is not affected. (`fn-h89/lib/filesystem/fnFsSD.cpp:306 (PC build)`)
- **P2 WiFi**: A stand-in: always connected to 'Dummy Cafe'; a scan finds 'Dummy Cafe 0'-'15'; SET_SSID always succeeds. (`fn-h89/lib/hardware/fnWiFi (PC)`)
- **P3 shutdown with a TCP channel open**: fujinet-pc crashed (segmentation fault) while shutting down, in NetworkProtocolTCP's destructor, each time it was stopped with a TCP channel still open: a connection, after fujinet-lib's network test had stopped early, and a listening channel, after the corrected test had finished. Only at shutdown; the card never shuts down this way. (`observed: build/runs/libtest-network-{hdos,cpm}/fujinet.log, libtestfix-network-hdos/fujinet.log`)
