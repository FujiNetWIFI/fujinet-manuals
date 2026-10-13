#import "../lib.typ": *
#import "../pfigs.typ": *
#import "../prog.typ": *

#chapter(3, "The FujiBus Protocol")

#section("General")[
Every exchange between the H89 and the FujiNet is a *request* and a *reply*. The H89 sends a
request naming a device and a command, with any numbers and data the command needs. The device
answers ACK, with whatever data it has to give, or NAK, which means no. Then the next request may
go.

The format is FujiBus, the FujiNet project's protocol for computers that reach it over a plain
byte stream, as the H89 does through port A. It is the same on every such computer; only the wires
differ. This chapter describes it a byte at a time, so you can read the byte strips under every
command in this Manual, and write a FujiBus program in any language.
]

#section("Devices")[
A request goes to one *device*, by number. The FujiNet on the H89 has these:

#stable((0.75in, 0.95in, 1fr),
  th[Device], th[Name], th[What it is],
  [70H], [DEV_FUJINET], [The FujiNet itself: WiFi, hosts, drives, app keys, utilities (Chapter 8)],
  [31H--38H], [DEV_DISK + n], [Disk drive slots 1 to 8 (Chapter 9)],
  [71H--78H], [DEV_NETWORK + n], [Network channels 1 to 8 (Chapter 10)],
  [45H], [DEV_CLOCK], [The clock (Chapter 12)],
  [40H], [DEV_PRINTER], [The printer (Chapter 12)],
  [50H], [DEV_SERIAL], [The modem (Chapter 12)],
)

Other device numbers appear in the firmware's list, for other computers. On the H89 a request to
any of them is answered with a NAK, as for a device that does not exist.
]

#section("Frames")[
A request or a reply travels as one *frame*: a byte C0H, the packet, and another C0H. The C0H
bytes are called END. They mark where a frame starts and stops, so the receiver needs no count to
find them.

The packet itself may contain any byte, including C0H. So before it is sent, two bytes are
replaced by pairs:

#stable((0.75in, 1fr),
  th[In the packet], th[Is sent as],
  [C0H (END)], [DBH DCH],
  [DBH (ESC)], [DBH DDH],
)

The receiver turns each pair back into one byte. This is SLIP framing, from the early days of the
Internet; the names END and ESC are SLIP's. Escapes are commoner than you might think: the command
FUJI_CLOSE_APPKEY *is* DBH, so it always goes as DB DD (page #card-page("FUJI_CLOSE_APPKEY")), and
any checksum can come out as C0H (the reply on page #card-page("FUJI_QRCODE_LENGTH") does). Here is how the book's library sends a packet:

#snip("bus.slip", "asm", caption: [FUJIBUS.INC --- send BC bytes, escaped])

#warning[Send exactly one END before the packet. Some SLIP programs send END twice, to flush the
line; the FujiNet takes the second END as the end of an empty frame, throws it away, and reads the
packet that follows as data for its modem. The request is lost, with no reply.]
]

#pictorial(caption: [A FujiBus packet, before it is framed.], fieldrow((
  (0.55in, [device], [1 byte]), (0.55in, [command], [1 byte]), (0.75in, [length], [2 bytes, low first]),
  (0.6in, [checksum], [1 byte]), (0.65in, [descriptor], [1 byte]), (0.75in, [fields], [0--4 bytes each]),
  (1.15in, [payload], [the rest]),
)))

#section("The Header")[
Every packet starts with a six-byte header:

#stable((0.4in, 0.8in, 1fr),
  th[Byte], th[Name], th[Holds],
  [0], [device], [The device the request is for; in a reply, the device answering.],
  [1], [command], [The command. In a reply, ACK (06H) or NAK (15H).],
  [2, 3], [length], [The length of the whole packet, header included, before escaping. Low
    byte first.],
  [4], [checksum], [See below.],
  [5], [descriptor], [What fields follow. See "Fields."],
)

The length counts bytes as they are in the packet, not as they go down the wire: an escaped C0H
counts as one byte. The smallest packet is six bytes, a header alone.
]

#section("The Checksum")[
The checksum is an eight-bit sum of every byte of the packet, with the carry out of each addition
added back in at the bottom (an *end-around carry*). The checksum byte itself counts as 0 while
the sum is made.

For example, the request for the WiFi status is device 70H, command FAH, length 6, and no fields.
With the checksum byte as 0, its bytes are 70 FA 06 00 00 00:

#stable((0.9in, 0.9in, 1fr),
  th[Add], th[Sum], th[Carry back],
  [70H], [70H], [],
  [FAH], [16AH], [6AH + 1 = 6BH],
  [06H], [71H], [],
  [00H, 00H, 00H], [71H], [],
)

So the checksum is 71H, and the packet is 70 FA 06 00 71 00. The library's routine is short:

#snip("bus.cksum", "asm", caption: [FUJIBUS.INC --- add BC bytes into the sum in D])

The receiver adds up the packet the same way, skipping byte 4, and compares. A packet whose sum is
wrong is thrown away.
]

#section("Fields")[
Most commands need a few small numbers: a slot number, a length, a mode. These go in *fields*,
just after the header, and byte 5, the *descriptor*, says how many there are and how big:

#stable((0.8in, 1.0in, 1fr),
  th[Descriptor], th[Library], th[Fields],
  [0], [F_NONE], [none],
  [1], [F_A1], [one byte],
  [2], [F_A1_A2], [two bytes],
  [3], [F_A1_A2_A3], [three bytes],
  [4], [F_A1_A2_A3_A4], [four bytes],
  [5], [F_B12], [one 16-bit word],
  [6], [F_B12_B34], [two 16-bit words],
  [7], [F_C1234], [one 32-bit number],
)

Words and longer numbers are sent low byte first, like the length. (The names come from the AUX1
to AUX4 bytes of the Atari's SIO protocol, which FujiBus grew from: B12 is AUX1 and AUX2 taken as a
word.)

If a command needs more fields than one descriptor can describe, bit 7 of the descriptor is set
and another descriptor byte follows it, before any field. No command on the H89 needs this.

The FujiNet does not care how wide a field is sent: a command that takes a number takes it from a
one-byte field, a word or a long alike. Each card in Chapters 8 to 12 shows the size the command
uses, which is what this Manual's examples send.

#note[The FujiNet looks only at the descriptor's low three bits (and bit 7). fujinet-lib puts two
flags of its own in bits 3 and 4 (08H, "payload follows," and 10H, "reply expected"), so its
requests carry descriptors like 10H and 12H where the book's library sends 00H and 02H. The
FujiNet treats them the same.]

#warning[Always send every field a command takes. A command that finds a field missing does not NAK:
the firmware stops. On the card the ESP32 restarts, and every drive and network connection is lost;
fujinet-pc exits.]
]

#section("The Payload")[
Whatever follows the fields is the *payload*: a file name, a block of data to write, a structure
of settings. Its length is not stated separately; it is what the header's length leaves after the
header, the extra descriptors and the fields.

Commands are not strict about payloads. A payload shorter than the command expects is accepted
(the rest of the command's buffer is whatever was there before), and a longer one is cut off.
Each card says what the command expects.
]

#section("The Reply")[
For every request it accepts, the device sends one reply:

#stable((0.4in, 1fr),
  th[Byte], th[Holds],
  [0], [The device answering. For a request to a device that does not exist, 00H.],
  [1], [ACK (06H): done. NAK (15H): refused, or failed.],
  [2, 3], [The length, as in a request.],
  [4], [The checksum, as in a request.],
  [5], [00H: a reply has no fields.],
  [6 ...], [The reply's data, if any. Only an ACK carries data.],
)

The reply carries no count of its own other than the length. A program learns how much data came
by subtracting six from the length: `fn_call` returns it in BC.

#sub("When there is no reply")
Some requests are never answered:

- A frame with a wrong checksum or length, or a gap of more than 100 ms in the middle (Chapter 2).
  The FujiNet cannot tell what it was, so it says nothing.
- FUJI_RESET, which restarts the FujiNet instead (Chapter 8).
- Any request to the printer while it is turned off in the FujiNet's settings.
- The modem's commands. The modem answers with bare bytes, not a frame (Chapter 12).

A program must therefore give up on a reply after a while. The book's library waits 15 seconds for
the first byte, and 1 second for each after.
]

#section("A Complete Exchange")[
Here is the WiFi status request, as it went over the bus, and the FujiNet's reply. The bytes are
shaded by their part of the frame:

#legend()
#exchange("fuji.get_wifistatus")

The request is the packet worked out above, framed in ENDs. In the reply, the FujiNet has answered
as device 70H, with ACK, in a packet seven bytes long: the header and one byte of data, 03H, which
means the FujiNet is connected to its network.
]

#section("The Rules")[
These hold for every exchange in this Manual:

+ The H89 speaks first. The FujiNet only answers.
+ One request, one reply, and then the next request. Requests do not overlap, even to different
  devices.
+ Send a request in one go: no pause of 100 ms or more between its bytes.
+ Send exactly one END before the packet and one after.
+ Send every field the command takes.
+ Take the whole reply, to its last END, before the next request, even if you do not want it all.
+ If no reply comes, wait until the line is quiet, then go on. Expect that the request did nothing,
  or that it did everything; you cannot tell which.
]
