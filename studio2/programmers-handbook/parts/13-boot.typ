#import "../lib.typ": *

#opener-art.update((sub: [hosts · directories · mount · hand over],
  art: tvrow("fujidir", "fujiboot", w: 1.3in)))
= Directories, Mount and Boot <boot>

The FujiNet keeps eight _host slots_, places files come from: its SD card, TNFS servers, web servers. It keeps eight _device slots_ too, the drives a computer would boot from. A Studio II has no drives, but it boots the same way: a file is named in a device slot, mounted, and the FujiNet sends it to the cartridge, which hands the console over to it.

== Listing a directory

`fujidir.asm` lists `/s2book/` on host slot 0, the SD card. Four commands of the FUJI device: MOUNT_HOST connects the host, OPEN_DIRECTORY opens the folder, READ_DIR_ENTRY reads one name a call, CLOSE_DIRECTORY closes it.

#excerpt-at(auto, "listings/asm/fujidir.asm", "mount:  FNBEGIN FNDEVF, FNCMHST, 1", to: "        FJMP    list")

OPEN_DIRECTORY’s path goes out as exactly 256 bytes, padded with NULs, and so does every path the FUJI device takes; `fn_path` pads it. After the path’s NUL, a filter such as `*.ST2` may follow.

#excerpt-at(auto, "listings/asm/fujidir.asm", "entry:  FNBEGIN FNDEVF, FNCRDIR, 2", to: "close:  FJMP")

READ_DIR_ENTRY takes the longest name wanted and a flags byte. Each name is printed straight from the reply window. Two bytes of `$7F` say the folder is done.

#important[Never ask for names exactly 31 characters long: at that length the firmware puts icon bytes in front of each name.]

== Booting

`fujiboot.asm`, the bring-up’s, boots `/s2book/hello.st2` from the SD card. The handbook’s `build.sh` sets the path; the program is unchanged. Three commands, then the hand-over:

#tbl((1.45in, 1fr),
  [*Command*], [*Does*],
  [MOUNT_HOST `$F9`], [connects host slot 0],
  [SET_DEVICE_FULLPATH `$E2`], [device slot, host slot, mode, then the path in 256 bytes],
  [MOUNT_IMAGE `$F8`], [device slot, mode: the FujiNet sends the file],
)

#wex("listings/runtime/fujiboot.asm", "        ; ---- MOUNT_IMAGE", to: "; go_ack --", at: bottom)

MOUNT_IMAGE does two things at once. Before it answers, the FujiNet sends the whole file to the cartridge, over the same USB link, addressed to a device of the cartridge’s own. The cartridge stores it beside the program that is running, and paints its progress on the status page: BOOT_STATE goes from 1, coming, to 2, ready, or `$80`, failed, with BOOT_PCT counting to 100 and a bar in the status strip below the text. The cartridge allows a mount 60 seconds; `fujiboot` waits 66.

== The hand-over

#wex("listings/runtime/fujiboot.asm", "stage:  LDI     4", to: "; ---- the failure screen", at: top)

When BOOT_STATE says ready, `fn_boot` writes `$B5` to BOOTLOCK, which _arms_ the new image, and waits for the cartridge to say so on the status page. Then `fn_handover` starts the console over:

#nsteps(
  [It waits for the bottom of a frame, when the 1861 is quiet for about 1,850 cycles.],
  [It turns the interrupt off and clears `$08A0-$08FF`, the RAM the BIOS does not clear itself.],
  [It sets the registers as the console has them after a power-on, and jumps to a stub at `$E9F0` that returns to `$0000`.],
  [The BIOS’s first fetch from `$0000` is the cartridge’s signal: it swaps the new image in, and the BIOS starts it as if it had been in the socket all along.],
)

If the new image claims the mailbox, it finds ACKSEQ at 0 and the screen blank; the status page’s MODE reads 3 and SWAPS has gone up by one. If it is an old game, the cartridge serves its pages and nothing else.

#note[CLEAR does not undo a hand-over: it restarts the image that is running. Turning the console off brings CONFIG back.]

== When it fails

`fujiboot` shows which step failed and with what: `FAILED 03E02`, say, is the third command with ERR 2, a timeout. Step 5 is a failed transfer, with BOOT_ERR: 1 too big, 2 cut short, 3 a page the program may not use. Step 6 is a swap the cartridge never armed.
