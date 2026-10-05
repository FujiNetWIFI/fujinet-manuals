#import "../lib.typ": *

= Program Listings

The programs of Chapters 5 to 9 in assembly -- their C versions are printed
whole in those chapters -- and then the NES layers of the four games, with the
callouts their chapters refer to. Every listing here is the file that was
built and run.

== This manual's programs

#code-listing("hello.s -- the first transaction", "listings/asm/hello.s",
  callouts: (("jsr     fn_chk", 1), ("have:   CALL", 2), ("jsr     fn_go", 3),
             ("ldx     #AC_SSID", 4), ("lda     FN_ACKS", 5)))
#code-listing("netget.s -- a file over HTTP", "listings/asm/netget.s",
  callouts: (("CALL    FNDEVN, NCOPEN, 2", 1), ("next:   CALL", 2),
             ("cmp     #2", 3), ("CALL    FNDEVN, NCREAD, 1", 4)))
#code-listing("json.s -- a JSON round trip", "listings/asm/json.s",
  callouts: (("CALL    FNDEVN, NCPARSER, 2", 1), ("CALL    FNDEVN, NCPARSE, 0", 2),
             ("CALL    FNDEVN, NCQUERY, 0", 3), ("lda     FN_RPLY                 ; still", 4)))
#code-listing("dir.s -- a directory on a TNFS host", "listings/asm/dir.s",
  callouts: (("ldx     #HOST*32", 1), ("jsr     fn_path", 2), ("cmp     #$7F", 3)))
#code-listing("boot.s -- loading an image, with progress", "listings/asm/boot.s",
  callouts: (("jsr     fn_launch", 1), ("lda     FN_BPC", 2), ("jsr     fn_done", 3),
             ("jsr     fn_blk", 4)))
#code-listing("appkey.s -- a run counter", "listings/asm/appkey.s",
  callouts: (("lda     FN_RPLY+1", 1), ("count:  inc", 2), (".proc open_key", 3)))
#code-listing("clock.s -- the time, once a second", "listings/asm/clock.s",
  callouts: (("jsr     wait_vbl", 1), ("ldx     #11", 2)))
#code-listing("booklib.s -- what this manual adds to fujilib.s", "listings/common/booklib.s",
  callouts: ((".proc nmi", 1), (".proc fn_launch", 2), (".proc fn_done", 3)))

== 5 Card Stud

#code-listing("src/nes/network.c", "listings/games/5cardstud/network.c",
  callouts: (("network_open(url", 1), ("count = network_read", 2)))
#code-listing("src/nes/ppu.s", "listings/games/5cardstud/ppu.s",
  callouts: (("jsr     popax", 3), ("jmp     ppubuf_put", 4)))
#code-listing("src/nes/input.c", "listings/games/5cardstud/input.c",
  callouts: (("modsSeen |= buttons & MODS", 5),))
#code-listing("src/nes/util.c", "listings/games/5cardstud/util.c",
  callouts: (("fuji_nes_boot();", 6), ("Only starts the transfer", 7)))
#code-listing("src/nes/sound.c", "listings/games/5cardstud/sound.c",
  callouts: (("111861UL", 8), ("PULSE1_SWEEP = PULSE2_SWEEP = 0x08", 9)))
#code-listing("src/nes/osk.c", "listings/games/5cardstud/osk.c",
  callouts: (("hold = REPEAT_FIRST;", 10),))

== Battleship

#code-listing("src/nes/fujinet.c", "listings/games/battleship/fujinet.c",
  callouts: (("static const char lobbyPath", 1), ("fuji_get_host_slots(slots", 2),
             ("return fuji_mount_disk_image", 3), ("bootState = fuji_nes_boot_state", 4),
             ("fuji_nes_boot();", 5)))
#code-listing("src/nes/util.c", "listings/games/battleship/util.c",
  callouts: (("while ((uint8_t)clock() == t)", 6),))
#code-listing("src/nes/input.c", "listings/games/battleship/input.c",
  callouts: (("return sel ? 'h' : KEY_RETURN;", 7),))

== Fujitzee

#code-listing("src/nes/osk.c", "listings/games/fujitzee/osk.c",
  callouts: (("unsigned char oskPoll(void)", 1),))
#code-listing("src/nes/input.c", "listings/games/fujitzee/input.c",
  callouts: (("pendingKey = oskPoll();", 2),))
#code-listing("src/nes/util.c", "listings/games/fujitzee/util.c",
  callouts: (("game_wire_size_check", 3),))

== Texas Hold'em

#code-listing("src/main.c", "listings/games/texasholdem/main.c",
  callouts: (("sum += sp[n] ^ (unsigned char)n;", 1),))
