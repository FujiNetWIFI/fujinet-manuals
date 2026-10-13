#import "../lib.typ": *
#import "../prog.typ": *

#chapter(15, "ISS Tracker")

#section("General")[
The International Space Station goes round the Earth every hour and a half, and a free web
service, api.open-notify.org, will tell anyone where it is. It answers in JSON, the text format
nearly every web service uses today:

#code("{\"message\": \"success\", \"timestamp\": 1760270400,
 \"iss_position\": {\"latitude\": \"29.7604\", \"longitude\": \"-95.3698\"}}")

An H89 has no business taking that apart itself, and with the FujiNet it doesn't have to: the
FujiNet's JSON parser does it, and hands the H89 just the values it asks for. ISS shows how. It
lists the people in space, then plots the station on a map of the world, drawn on the H19, and
moves it every 30 seconds.

ISS comes in assembly and in C, each for HDOS and for CP/M. It began as Justin Skists's ISS
tracker for the RC2014, itself after Bill Kendrick's for the Atari; the map is theirs.
]

#section("Running ISS")[
#steps(
  [Type #typed("ISS") #ret. ISS asks open-notify who is in space, and lists them.],
  [Press #ret for the map. The station is the blinking star. Every 30 seconds ISS asks again and
   moves it; #ret asks at once.],
  [Press ESC to leave.],
)

To use a server of your own (one with files named `iss-now.json` and `astros.json`, such as the
book's test server), give its address: `ISS N:HTTP://192.168.1.10/`. These screens were taken that
way, with a fixed position, so the station is over Houston:

#crt("isspeople-asm-hdos")
#crt("iss-asm-hdos")
]

#section("The FujiNet's JSON Parser")[
Every network channel has a *parser*. It is normally off, and READ returns the bytes the server
sent. Set to JSON, it reads the whole document into the FujiNet's memory, checks it, and from then
on READ returns only what you ask for, a value at a time. Asking takes four requests:

+ OPEN the document on a channel, as usual.
+ SET_PARSER with its second field 1, for JSON (2 is HTML, 3 XML).
+ PARSE, which fetches and parses the whole document. For HTTP, this is when the request is
  sent.
+ Then, for each value: QUERY with a *JSON Pointer* as the payload, STATUS to learn how long the
  answer is, and READ to take it.

A JSON Pointer (the Internet standard RFC 6901) is a path through the document: `/timestamp` is
the member *timestamp* of the top object; `/iss_position/latitude` the member *latitude* of the
object *iss_position*; `/people/2/name` the *name* of the third element (counting from 0) of the
array *people*. The FujiNet answers with the value as text --- a string without its quotes, a
number as digits --- followed by a line feed.

If the path names nothing, QUERY still answers ACK, but STATUS then shows nothing waiting. That is
how ISS knows a value is missing.

#warning[The firmware is fragile here. A query whose answer contains an empty array (`[]`) crashes
it; so does SET_PARSER on a channel that is not open, followed by a QUERY or READ. ISS opens the
channel first, and asks only for single values.]
]

#section("The Assembly Version")[
Two routines do all the JSON work. `open_json` opens a URL and parses it:

#snip("iss.open_json", "asm", caption: [ISS.ASM --- open and parse a JSON document])

`jget` asks for one value and reads it into `val`, dropping the line feed:

#snip("iss.jget", "asm", caption: [ISS.ASM --- one value, by JSON Pointer])

With those, the list of people is a loop that builds `/people/0/name`, `/people/0/craft`,
`/people/1/name` and so on, up to the count `/number` gave:

#snip("iss.astros", "asm", caption: [ISS.ASM --- the people in space])

#sub("From degrees to the map")
The map is 72 characters wide for 360 degrees of longitude, and 18 rows high for 180 degrees of
latitude: 5 degrees a column and 10 a row. ISS works in tenths of a degree, so the arithmetic is
all whole numbers: column = (longitude + 180.0) / 5, row = (90.0 - latitude) / 10.

#snip("iss.place", "asm", caption: [ISS.ASM --- where on the map])

#sub("From seconds to a date")
`/timestamp` is the time of the position, in seconds since the start of 1970 (UNIX time), about
1.76 billion: too big for 16 bits. ISS reads it as a 32-bit number, and divides by 60, 60 and 24 a
byte at a time, the way long division is done on paper; what is left is days. Then it takes away
whole years, then whole months, to find the date.

#snip("iss.time", "asm", caption: [ISS.ASM --- seconds to a date])

#sub("The screen")
ISS draws with the H19's escape sequences: `ESC E` clears the screen, `ESC Y` row column moves the
cursor (each plus 32), `ESC p` and `ESC q` turn reverse video on and off, and `ESC x 5` and
`ESC y 5` hide and show the cursor. The frame round the map is in the H19's graphics characters:
after `ESC F`, the letters `a`, `f`, `c`, `e`, `d` and the grave accent are a horizontal line, the
four corners and a vertical line, until `ESC G` turns them back into letters. The Appendix shows
them all.
]

#section("The C Version")[
In C, fujinet-lib does the JSON requests. `network_json_parse()` sends SET_PARSER and PARSE, and
`network_json_query()` sends the QUERY, then reads the answer, and strips the line feed:

#snip("iss.jget", "c", caption: [ISS.C --- one value, by JSON Pointer])

#warning[`network_json_query()` always sends 256 bytes of query, whatever the length of the string
you give it, and reads the answer into your buffer with no limit on its length. Keep the query in
a 256-byte buffer that is otherwise zero, as ISS.C does, and give it a buffer of 256 bytes for the
answer.]

The rest is the assembly version again, more briefly; the date, for one:

#snip("iss.time", "c", caption: [ISS.C --- seconds to a date])
]

#section("Listings", balance: false)[
#plisting("iss-asm")
#plisting("iss-c")
]
