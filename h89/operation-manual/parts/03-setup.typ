#import "../lib.typ": *
#import "../figs.typ": card, jumpers, sockets

#chapter(3, "Set-Up and Testing")

#section("What You Need")[
Before you begin, make sure you have:

- Your Heathkit H89 (or H88, or Zenith Z-89), working, with its monitor ROM: MTR-88, MTR-89 or
  MTR-90. The Computer needs at least 48K of memory for HDOS (64K is better; see Page 4-1), and 64K for CP/M.
- A system diskette that starts HDOS 2.0 or Heath/Zenith CP/M 2.2.04, and a blank diskette for the
  FujiNet programs (see "FujiNet Software," Page 5-1).
- The name and password of your WiFi network. The FujiNet uses the 2.4 GHz band only.
- A microSD card, if you want a library of disk images on the board itself. It is not needed to
  begin with.
- A small flat-blade screwdriver, for the cabinet latches.

#sub("Parts List")
Check the contents of your package against this list.

#stable((0.45in, 1fr),
  th[Qty.], th[Description],
  [1], [H89 FujiNet circuit board (V1.1, reworked; see "The Rework" in Chapter 11), assembled and tested, with the FujiNet firmware loaded],
  [2], [Jumpers (shunts), installed on the PORT SEL header at 320Q and on JP1 at 0],
)

If anything is missing, see "Getting Help" in the Appendix.
]

#section("Handling the Card")[
CAUTION: The integrated circuits on the FujiNet card are MOS devices, and can be damaged by
static electricity. Before you pick up the card, touch the metal chassis of the Computer (with the
line cord unplugged) to equalize the static charge between you and it. Then hold the card by its
edges. Do not touch the pins of the edge connectors, the pins of the ESP32 module, or the module's
antenna.

Keep the card in its protective bag until you install it. If you must set it down, lay it on the
bag, component side up.
]

#section("Setting the Jumpers")[
Refer to Pictorial 3-1 for the location of the jumpers, and to Pictorial 3-2 for the following
steps.

The PORT SEL jumper chooses the group of eight I/O ports the card answers, and JP1 chooses the
first four ports of the group or the last four. The FujiNet programs expect the card at port 320,
so the PORT SEL jumper goes on the 320Q position and JP1 on 0. The other positions are for future
software.

J3 connects the card to one of the Computer's interrupt lines. The FujiNet programs do not use
interrupts, so J3 has no jumper on it.

#step[Find the PORT SEL header, J1 (marked IO_PORT_SEL), near the bottom edge of the card, below
the ESP32 module. Make sure the jumper is on the pair of pins marked 320Q, and on no other.]

#step[Find JP1, marked BA2, to the left of J1. Make sure its jumper joins the middle pin to the pin
marked 0.]

#step[Find J3, marked /INTE_ENA, to the right of J1. Make sure there are no jumpers on it. If there
is one, remove it and store it on a single pin of J3 so it is not lost.]

#stable((auto, 1fr),
  th[Jumper], th[To],
  [PORT SEL (J1)], [320Q],
  [JP1 (BA2)], [0],
  [J3 (/INTE_ENA)], [No jumper],
)

NOTE: Port 320 is also the second port of the HA-88-3 three-port serial interface accessory, which
HDOS uses as its alternate terminal port. If your Computer has an HA-88-3 board with an 8250 IC
installed for that port, it and the FujiNet would both answer at 320. See "Installing the Card."
]

#wide(pictorial(caption: [The H89 FujiNet card, component side.], card(s: 0.0083in)))

#section("The microSD Card")[
You can put a microSD card in the FujiNet's socket to keep your own library of disk images on the
board. The card must be formatted FAT32. Cards of 32 gigabytes or smaller are formatted that way
when new.

#step[On your personal computer, copy your .H8D disk images onto the microSD card. You may put them
in folders.]

#step[Slide the microSD card into the socket on the breakout board near the top edge of the
FujiNet card, contacts first and label up, until it stops.]

The FujiNet looks at the microSD card only when it starts, when the Computer is turned on. Insert or
remove the card only while the Computer is turned off, and with no USB cable plugged into the ESP32
module: a USB cable keeps the FujiNet running.
]

#pictorial(caption: [PORT SEL at 320Q; no jumper on J3.], jumpers())

#section("Cabinet Removal")[
Whenever you need to remove the cabinet shell:

- Turn off the Computer and unplug the line cord.
- Insert the blade of a small screwdriver into the notch in the latch plate on one side of the
  cabinet, and slide the latch plate toward the back of the Computer about 1/2".
- Likewise, open the latch plate on the other side of the cabinet shell.
- Carefully tilt the cabinet shell back. Never allow the cabinet shell to hang unsupported.

WARNING: When the line cord is connected to an AC outlet, hazardous voltages can be present inside
your Computer, even with the power switch off. Always unplug the line cord before you open the
cabinet.

Simply reverse this procedure to close and lock the cabinet shell.
]

#pictorial(caption: [The cabinet shell tilted back.], photo-slot(1.7in, [The H89 with its cabinet shell tilted back, showing the CPU logic circuit board.]))

#section("Installing the Card")[
Refer to Pictorial 3-4 for the following steps.

The CPU logic circuit board has three pairs of accessory sockets. Each pair is a 10-pin socket and
a 25-pin socket: P504 with P510, P505 with P511, and P506 with P512. The floppy disk interface
board uses P506 and P512, and must stay there. The FujiNet card goes in either of the other pairs.

#step[Open the cabinet. See "Cabinet Removal."]

#step[Find the three pairs of accessory sockets on the CPU logic circuit board, and note which
boards are already installed.]

#step[Choose a free pair: P504 with P510, or P505 with P511.]

#step[If an HA-88-3 serial interface board is installed, look at it. If the 8250 IC for its 320
port is in its socket, the serial port and the FujiNet cannot share the Computer. Remove that one
8250 (handle it as a protected IC), or do not install the FujiNet card.]

#step[Hold the FujiNet card by its edges, component side facing the same way as the other
accessory boards. Line up its 10-pin connector with the 10-pin socket (P504 or P505) and its
25-pin connector with the 25-pin socket (P510 or P511).]

#step[Press the card straight down onto the sockets, evenly, until it is fully seated. Make sure
every pin went into its socket, and that no row is offset by one.]

#step[Make sure no wires or cables lie across the ESP32 module's antenna.]

#step[Close and lock the cabinet shell, and plug in the line cord.]

NOTE: The FujiNet's firmware is updated through the USB connector on the ESP32 module. If you
expect to update it, you may want to plug a USB cable into the module now and lead it out of the
cabinet, so you need not open the Computer later. See "Firmware Updates" on Page 9-1.

The FujiNet's antenna is inside the cabinet. The plastic shell lets the signal through, but the
picture tube and chassis do not. If your WiFi router is far away, you may need to move it closer.
]

#wide(pictorial(caption: [The accessory sockets on the CPU logic circuit board (not to scale).], sockets()))

#pictorial(caption: [The FujiNet card installed.], photo-slot(1.7in, [The FujiNet card seated on P504 and P510, beside the floppy disk interface board.]))

#pagebreak(weak: true)
#section("Testing", balance: false, above: 0pt)[
The purpose of the "Testing" is to verify that your FujiNet card is installed and working properly.
It is not necessary, at this time, to have a working knowledge of the FujiNet, nor to have set up
your WiFi network: the tests use nothing but the Computer's monitor. If, at any time during the
"Testing," you fail to obtain the proper results, refer to the "Troubleshooting" section on Page
10-1.

There are three tests. The Initial Tests make sure the Computer still starts with the card in it.
The Port Test (for MTR-90 only) checks the card's 82C55A with the monitor's own commands. The
Communication Test is a short program you key into memory; it sets up the card, sends the FujiNet
a request, and prints the answer.

#sub("Initial Tests")
#step[Push the rear panel POWER switch to ON. The speaker should produce a "beep," and after the
picture tube warms up the monitor's prompt, #scr("H:"), appears at the left of the screen.]

NOTE: If your Computer starts HDOS or CP/M by itself at power-up, or runs a memory test first,
switch SW501 on the CPU logic circuit board is set for it. Push #key[SHIFT] and #key[RESET] to
stop it and get the #scr("H:") prompt, or see Page 10-1.

#step[Push the right-hand #key[SHIFT] key and the #key[RESET] key together. The Computer
should beep and give you the #scr("H:") prompt again.]

If the prompt does not appear, turn the Computer off at once and see "Troubleshooting."

#sub("Port Test (MTR-90)")
The MTR-90 monitor has an Out command, which writes a number to an I/O port, and an In command,
which reads one. If your monitor shows "Out" when you type O, you can use them to check the card's
82C55A with no program at all. If your monitor is MTR-88 or MTR-89, skip to the Communication
Test.

#step[Type #typed("O"); the monitor finishes the word "Out." Type #typed("323,300")#ret. This sets up the
82C55A.]

#step[Type #typed("I"); the monitor finishes the word "In." Type #typed("322")#ret. The monitor shows
what it read from port 322 on the next line. It should be #scr("200").]

#step[Type #typed("O") again, and then #typed("321,252")#ret. This writes a pattern to port B, which
lights every other one of the card's eight lamps.]

#step[Type #typed("I321")#ret. The monitor should show #scr("252"), the pattern you wrote.]

#session("mtr-ports", rows: (0, 6), cols: (0, 26), typed-rows: none,
  under: ((0, 5, 5), (0, 9, 15), (1, 5, 5), (1, 8, 10), (3, 5, 5), (3, 9, 15), (4, 5, 5), (4, 8, 10)))

The first number shows the 82C55A answered at port 322. (The second digit may be 4 instead of 0:
240 is a good result too.) The second shows the 82C55A keeps what is written to it. If you see
#scr("377"), nothing answered: check the PORT SEL jumper, JP1, and that the card is seated.

#step[Push #key[SHIFT] and #key[RESET]. This resets the 82C55A. The FujiNet itself keeps running.]

#sub("Communication Test")
This test is the Computer and the FujiNet talking to each other. You will first enter a short
program into memory with the monitor's Substitute command, and then run it. The program sets up the
card's 82C55A, asks the FujiNet for its adapter configuration, and prints what comes back.

The program prints a #scr("1") as soon as it finds the card's 82C55A, and a #scr("2") once the
FujiNet has taken the request. Then it prints the text in the FujiNet's answer: the name of your
WiFi network and the FujiNet's own name, if it has joined a network, and the version of its
firmware. Then the monitor beeps, prints an #scr("H"), and gives you the prompt.

The program is 106 numbers long. Take your time; if you make a mistake, you can go back and fix it.

#step[Push #key[SHIFT] and #key[RESET] to make sure you have the #scr("H:") prompt.]

#step[Type #typed("S"); the Computer will finish the word "Substitute." Type #typed("040100")#ret.
The Computer will respond with:]

#align(center, block[#scr("040100 XXX")])

Each X can be any digit, 0 through 7. It is what is in memory now.

#step[Enter #typed("076") and push the SPACE bar. The Computer moves to the next address:]

#align(center, block[#scr("040101 XXX")])

#step[Enter #typed("300") and push the SPACE bar. Then continue by making the following entries,
eight to a line in the table. Push the SPACE bar once after each entry. The address at the left of
each line of the table is the address the Computer should be showing when you begin that line;
check it as you go.]

#octal-table("acctest")

#session("mtr-keying-mtr90", rows: (0, 7), cols: (0, 26), typed-rows: none,
  under: ((0, 5, 5), (0, 16, 21), (1, 11, 13), (2, 11, 13), (3, 11, 13), (4, 11, 13), (5, 11, 13), (6, 11, 13)))

#step[After the last entry (#scr("300") at address 040251), push RETURN instead of the SPACE bar.
The Computer gives you the #scr("H:") prompt.]

If you made a mistake: while you are still entering, push the minus sign (#typed("-")) to go back
one address, and type the number again. Only the last three digits you type count. To check your
work afterward, type #typed("S040100")#ret and push the SPACE bar to step through the numbers
without changing them; push RETURN when you are done.

#step[Type #typed("G"); the Computer will finish the word "Go." Type #typed("040100")#ret.]

At once, the display should be:

#session("mtr-pass-444-142_mtr90", rows: (22, 23), cols: (0, 40), typed-rows: none,
  under: ((22, 5, 5), (22, 8, 13)))

The text after #scr("12") is the FujiNet's answer. Here, "Workshop" is the WiFi network the
FujiNet has joined, "FujiNet" is its own name, and v1.6-6b818770 is its firmware version. Until the
FujiNet has joined a network, the names are blank and only the firmware version shows. You may
also see a few stray letters and marks between the names: they are the bytes of the FujiNet's
network addresses that happen to be printable characters.

The program stays in memory until you turn off the Computer. To run it again, push #key[SHIFT] and
#key[RESET] and type #typed("G040100")#ret. (Typing G with no address would not start it over.)

#sub("What the Test Tells You")
#stable((1.15in, 1fr),
  th[You See], th[It Means],
  [#scr("12") and text, #scr("H")], [The card is working. Go on to "System Configuration."],
  [Only #scr("H") (and a beep)], [No 82C55A answered at port 320: the PORT SEL jumper, the card's seating, or another board at 320.],
  [#scr("1"), and nothing more], [The 82C55A is there, but the FujiNet is not taking the request: its firmware, its power, or U5, the 74LVC245.],
  [#scr("12"), and nothing more], [The request went out but no answer came back: the FujiNet's firmware, or the return path through the 82C55A.],
  [No beep, no #scr("H"), or a garbled screen], [The program was keyed in wrong. Push #key[SHIFT] and #key[RESET] and check your entries.],
)

For more about each of these, see "Troubleshooting" on Page 10-1. The program itself is listed in
the Appendix.

NOTES:

+ If you have not yet made your FujiNet diskette, proceed to "FujiNet Software" (Page 5-1).
+ If your FujiNet diskette is ready, proceed to "System Configuration" (Page 4-1) and then
  "FujiNet CONFIG" (Page 6-1).
]
