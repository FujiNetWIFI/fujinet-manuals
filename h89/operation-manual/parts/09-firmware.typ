#import "../lib.typ": *

#chapter(9, "Firmware Updates")

#section("About the Firmware", balance: false)[
The program that runs on the FujiNet itself, on its ESP32, is its firmware. It is improved often,
and you can put a new version on your card with the FujiNet-Flasher, a free program for Windows,
macOS and Linux, and a USB cable from your personal computer to the ESP32 module on the card. Your
settings, host slots and drive slots are kept through an update.

To take a new firmware, the ESP32 must be started in its loading mode. On the H89 card, the
Computer does that: a monitor command (MTR-90) or a short program you key in (MTR-88 and MTR-89)
sets the FujiNet's start-up lines for loading, and the Flasher does the rest over USB.

#sub("You Will Need")
- A personal computer with the FujiNet-Flasher, from fujinet.online/download. On Windows you may
  also need the driver for the ESP32 module's USB interface (the Silicon Labs CP210x).
- A USB cable that carries data, not just power, from your computer to the ESP32 module's USB
  connector.

WARNING: The Computer must be on while you update the firmware, and hazardous voltages are present
inside it. Never reach into a running Computer. Plug the USB cable into the ESP32 module and lead it
out of the cabinet before you turn the Computer on; better still, leave a cable there when you
install the card (see Page 3-4).

#sub("Updating the Firmware")
#step[With the Computer off, connect the USB cable to the ESP32 module and lead it out of the
cabinet. Close the cabinet. Leave the other end unplugged for now.]

#step[Turn on the Computer and get the #scr("H:") prompt.]

#step[Put the FujiNet in its loading mode. With MTR-90, type #typed("O")#typed("323,300")#ret and
then #typed("O")#typed("322,004")#ret. With MTR-88 or MTR-89, key in the program below at 040100 the
way you keyed in the Communication Test (Page 3-6), and run it with #typed("G040100")#ret; the
monitor beeps and prints #scr("H") when it is done.]

#octal-table("flashmode")

#step[Plug the USB cable into your personal computer and start the FujiNet-Flasher.]

#step[In the Flasher, choose the serial port of the ESP32 module, choose the platform "Heathkit
H89," and choose the firmware version you want. Then click Flash. The Flasher shows its progress,
and says when it is finished.]

#step[Unplug the USB cable from your personal computer.]

#step[Push #key[SHIFT] and #key[RESET] on the Computer. This takes the FujiNet out of loading mode;
until you do, the FujiNet programs will report that the FujiNet is not answering.]

#step[Run CONFIG and push #typed("C"). The Info screen shows the new firmware's version.]

#sub("If the Flasher Cannot Connect")
The FujiNet is not in loading mode, or the computer cannot see the module. Push #key[SHIFT] and
#key[RESET], put the FujiNet in loading mode again, and try once more. Make sure the cable carries
data (try another), and on Windows, that the CP210x driver is installed.

#sub("The FujiNet's Diagnostic Output")
While it runs, the FujiNet writes a running account of what it is doing to the ESP32 module's USB
connector, at 460,800 baud. If you ask other owners for help with a problem, they may ask you for
it. The FujiNet-Flasher can show it (its "Serial Debug Output"), as can any terminal program. You
need not put the FujiNet in loading mode to see it.
]
