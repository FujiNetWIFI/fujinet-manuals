#!/usr/bin/env bash
# tour.sh -- every CONFIG screen the book shows, captured from CONFIG running
# on the FujiNet cartridge in MAME against the owner's bench (emu/bench.sh up).
# Each screen is one run of emu/walk.lua: a walk through the menus that waits
# for each screen's own words before the next key, a check that the screen
# says what the book quotes (WANT), and a snapshot, scaled 3x with hard
# pixels into images/screens/<name>.png.
#
#   emu/tour.sh            all of them
#   emu/tour.sh hosts info ...
set -uo pipefail
cd "$(dirname "$0")/.."
HB=../programmers-handbook
mkdir -p images/screens build/tour

# shot NAME STEPS WANT [SWAP]   (THR=1 runs MAME at real speed)
shot() {
    local name=$1
    echo "== $name"
    env SNAP="$name" SCRIPT=walk STEPS="$2" WANT="$3" SWAP="${4:-}" ${THR:+THROTTLE=1} \
        emu/run.sh > "build/tour/$name.log" 2>&1
    grep -v '^$' "build/tour/$name.log" | grep -v '^fujinet:\|^Average' || true
    if ! grep -q 'VERDICT PASS' "build/tour/$name.log"; then
        echo "tour: $name FAILED" >&2
        return 1
    fi
    local png
    png=$(ls build/snap/"$name"/a5200/*.png | sort | tail -1)
    python3 $HB/tools/pngscale.py "$png" "images/screens/$name.png" 3 >/dev/null
}
want() { [ ${#ONLY[@]} -eq 0 ] || [[ " ${ONLY[*]} " == *" $1 "* ]]; }

# the invented neighbourhood: fujinet-pc's dummy WiFi lists "Dummy Cafe 0-14"
# at -1 dBm; the book shows ordinary names and strengths
NETS=(HOMENET Upstairs SmithFamily Garage-2.4G "Apt 3B" OurWiFi "Library Guest"
      "Corner Cafe" Neighbor Printer-Setup Guest Wanderers BlueHouse Cottage
      "Bob Phone")
DBM=(-42 -55 -61 -64 -67 -70 -73 -75 -77 -79 -81 -83 -84 -86 -88)
WIFI_SWAP=""
for i in $(seq 0 14); do
    WIFI_SWAP+="$(printf '%-30s%s' "Dummy Cafe $i" "-1")=>$(printf '%-30s%s' "${NETS[$i]}" "${DBM[$i]}")|"
done
WIFI_SWAP+="Dummy Cafe 0=>HOMENET|Dummy Cafe=>HOMENET"
# this computer's own name and addresses, on INFO, become a home network's
INFO_SWAP="Dummy Cafe=>HOMENET|HOST     TMA-3=>HOST     FujiNet|IP       127.0.0.1=>IP       192.168.1.73"
INFO_SWAP+="|GATEWAY  0.0.0.0=>GATEWAY  192.168.1.1|NETMASK  255.0.0.0=>NETMASK  255.255.255.0"
INFO_SWAP+="|DNS      1.1.1.1=>DNS      192.168.1.1"
INFO_SWAP+="|MAC      D0:1C:ED:C0:FF:EE=>MAC      A0:B7:65:3C:1F:04"
INFO_SWAP+="|BSSID    D0:1C:ED:C0:FF:EE=>BSSID    60:38:E0:1A:22:9C"

H="wait=PLAY GAME LOBBY"                  # the hosts screen, drawn
NET="$H;star;wait=OTHER (TYPE AN SSID)"   # the network list
# the password keyboard, "Fuji5200" typed: F, then small u j i, then 5 2 0 0
PASS="$NET;hash;wait=PASSWORD?;k6;k6;k6;k6;k6;k6;hash;pause;k8;k4;hash;k2;k6;k6;k6;k6;k6;hash;k4;hash;k2;k4;k4;k4;k4;hash;k4;k4;k4;hash;k4;k4;hash;hash"
# apps.irata.online, over the Internet (read-only TNFS): the top, then
# ATARI-5200 / FUJINET, where the network games are
IRATA="$H;k8;k8;hash;wait=ATARI-5200/"
FN="$IRATA;k8;k8;k8;k8;k8;hash;wait=FUJINET/;k8;k8;k8;k8;k8;k8;k8;hash;wait=Battleship.a52"

ONLY=("$@")
FAIL=0
run() { want "$1" || return 0; shot "$@" || FAIL=1; }
run splash "wait=FOR THE ATARI 5200;pause=0.05;shot" "FUJINET CONFIG|FOR THE ATARI 5200"
run hosts "$H;pause=0.3;shot" "HOST SLOTS|PLAY GAME LOBBY|*--WIFI  START--INFO"
run wifi-pick "$NET;pause=0.3;shot" "SELECT NETWORK|OTHER (TYPE AN SSID)" "$WIFI_SWAP"
run kbd-pass "$PASS;pause=0.3;shot" "PASSWORD?|Fuji5200|CASE SPC DEL OK ESC" "$WIFI_SWAP"
run wifi-join "$NET;hash;wait=PASSWORD?;start;wait=JOINING NETWORK;wait=PLEASE WAIT;shot" \
    "JOINING NETWORK|PLEASE WAIT  *--CANCEL" "$WIFI_SWAP"
run wifi-ok "$NET;hash;wait=PASSWORD?;start;wait=CONNECTED;pause=0.2;shot" \
    "JOINING NETWORK|CONNECTED" "$WIFI_SWAP"
run info "$H;start;wait=VERSION;pause=0.3;shot" "ADAPTER INFO|VERSION|#,*--BACK" "$INFO_SWAP"
run rename "$H;k8;k8;k8;pause;wait=HOST NAME?;pause=0.3;shot" "HOST NAME?|KEYBOARD"
run browse-sd "$H;hash;wait=GAMES/;pause=0.3;shot" "HOST 1|GAMES/|<>--PAGE  START--COPY"
run browse-games "$H;hash;wait=GAMES/;k8;hash;wait=MULE.a52;pause=0.3;shot" "/GAMES/|MULE.a52"
THR=1 run browse-irata "$IRATA;pause=0.3;shot" "HOST 3|ATARI-5200/"
THR=1 run browse-fujinet "$FN;pause=0.3;shot" "/ATARI-5200/FUJINET/|Battleship.a52"
# loading Battleship from the Internet, caught part-way (a few tries)
if want loading; then
    for _ in 1 2 3 4 5 6; do
        THR=1 shot loading "$FN;hash;wait=LOADING;pct=25-85;shot" "LOADING|BYTES|FROM HOST 3" && break
    done || FAIL=1
fi
# copying it to the memory card
COPY="$FN;start;wait=COPY TO WHICH HOST?"
THR=1 run copy-to "$COPY;pause=0.3;shot" "COPY TO WHICH HOST?|#--PICK DESTINATION"
THR=1 run copy-here "$COPY;k2;k2;hash;wait=START--COPY HERE;wait=GAMES/;pause=0.3;shot" "START--COPY HERE|HOST 1"
THR=1 run copied "$COPY;k2;k2;hash;wait=START--COPY HERE;wait=GAMES/;start;wait=COPIED;shot" "COPIED"
exit $FAIL
