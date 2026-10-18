#import "../lib.typ": *

#chapter(9, "Firmware Updates")

#section("About the Firmware", balance: false)[
The program that runs on the FujiNet itself, on its ESP32, is its firmware. It is improved often,
and you can put a new version on your card with the FujiNet-Flasher, a free program for Windows,
macOS and Linux, and a USB cable from your personal computer to the ESP32 module on the card. Your
settings, host slots and drive slots are kept through an update.

The Flasher does the whole job over the USB cable. The ESP32 module goes into its loading mode
when the Flasher asks, and starts the new firmware when the Flasher is done. The Computer takes no
part, and has no way to put the FujiNet in loading mode.

#sub("You Will Need")
- A personal computer with the FujiNet-Flasher, from fujinet.online/download. On Windows you may
  also need the driver for the ESP32 module's USB interface (the Silicon Labs CP210x).
- A USB cable that carries data, not just power, from your computer to the ESP32 module's USB
  connector.

WARNING: Leave the Computer on while you update the firmware: its 82C55A then holds the card's bus
transceiver off. Hazardous voltages are present inside a running Computer. Never reach into it. Plug
the USB cable into the ESP32 module and lead it out of the cabinet before you turn the Computer on;
better still, leave a cable there when you install the card (see Page 3-4).

#sub("Updating the Firmware")
#step[With the Computer off, connect the USB cable to the ESP32 module and lead it out of the
cabinet. Close the cabinet. Leave the other end unplugged for now.]

#step[Turn on the Computer and get the #scr("H:") prompt.]

#step[Plug the USB cable into your personal computer and start the FujiNet-Flasher.]

#step[In the Flasher, choose the serial port of the ESP32 module, choose the platform "Heathkit
H89," and choose the firmware version you want. Then click Flash. The Flasher shows its progress,
and says when it is finished. The FujiNet then starts the new firmware.]

#step[Unplug the USB cable from your personal computer.]

#step[Run CONFIG and push #typed("C"). The Info screen shows the new firmware's version.]

#sub("If the Flasher Cannot Connect")
The computer cannot see the module, or the module did not go into loading mode. Make sure the cable
carries data (try another), and on Windows, that the CP210x driver is installed. Then unplug the
cable from your personal computer, turn the Computer off and on, and try once more.

#sub("The FujiNet's Diagnostic Output")
While it runs, the FujiNet writes a running account of what it is doing to the ESP32 module's USB
connector, at 460,800 baud. If you ask other owners for help with a problem, they may ask you for
it. The FujiNet-Flasher can show it (its "Serial Debug Output"), as can any terminal program.
]
