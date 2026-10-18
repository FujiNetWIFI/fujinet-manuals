# Figures and screens

Every H19 screen in the book was read cell by cell from FujiNet Go H89's
picture of the terminal (`tools/ppm2cells.py`), in a run of the program
on the book's rig (see README.md).

The rig's FujiNet is fujinet-pc on the same computer, so its screens show
a stand-in network:

- the WiFi network "Dummy Cafe";
- the FujiNet at 127.0.0.1, named after the computer;
- the test servers at 127.0.0.1.

`tools/keepscreen.py` puts the Operation Manual's example network in their
place:

- the FujiNet at 192.168.1.89 on "Workshop", named FujiNet;
- the servers at 192.168.1.10.

Every replacement is listed below. Nothing else on any screen was changed.
The byte strips under the command cards are never edited, so they show
the stand-in values.

| Screen | Run | Replaced |
|---|---|---|
| battleship-1 | game-bs-hdos-2-tables | nothing |
| battleship-2 | game-bs-hdos-2-lobby | nothing |
| battleship-3 | game-bs-hdos-3-placed | nothing |
| battleship-4 | game-bs-hdos-3 | nothing |
| fnhello-cpm | fnhello-asm-cpm | 127.0.0.1 -> 192.168.1.89, Dummy Cafe -> Workshop, TMA-3 -> FujiNet |
| fnhello-hdos | fnhello-asm-hdos | 127.0.0.1 -> 192.168.1.89, Dummy Cafe -> Workshop, TMA-3 -> FujiNet |
| fujitzee-1 | game-fj-hdos-1 | nothing |
| fujitzee-2 | game-fj-hdos-2-lobby | nothing |
| fujitzee-3 | game-fj-hdos-4-h2 | nothing |
| fujitzee-4 | game-fj-hdos-3 | nothing |
| hello-cpm | hello-c-cpm | 127.0.0.1 -> 192.168.1.89, Dummy Cafe -> Workshop, TMA-3 -> FujiNet |
| hello-hdos | hello-c-hdos | 127.0.0.1 -> 192.168.1.89, DUMMY CAFE -> WORKSHOP, TMA-3 -> FUJINET |
| iss-asm-hdos | issmap-asm-hdos | nothing |
| isspeople-asm-hdos | isspeople-asm-hdos | nothing |
| memprobe-cpm | memprobe-c-cpm | nothing |
| memprobe-hdos | memprobe-c-hdos | nothing |
| native-fnver-asm | native-fnver-asm | nothing |
| native-fnver-run | native-fnver-run | Dummy Cafe -> Workshop |
| native-fnverh-asm | native-fnverh-asm | nothing |
| native-fnverh-run | native-fnverh-run | DUMMY CAFE -> WORKSHOP |
| netcat-cpm | netcat-c-cpm | 127.0.0.1 -> 192.168.1.10 |
| netcat-hdos | netcat-asm-hdos | 127.0.0.1 -> 192.168.1.10 |
| nget-hdos | nget-asm-hdos | 127.0.0.1 -> 192.168.1.10 |
| nput-cpm | nput-asm-cpm | 127.0.0.1 -> 192.168.1.10 |
| texas-1 | game-texas-hdos-1 | nothing |
| texas-2 | game-texas-hdos-2 | nothing |
| texas-3 | game-texas-hdos-3 | nothing |
| texas-4 | game-texas-hdos-5-s22 | nothing |
