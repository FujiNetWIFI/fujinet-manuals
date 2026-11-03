#!/usr/bin/env bash
# rooms.sh -- the book's Lobby rooms, POSTed to the bench's Lobby server
# (emu/bench.sh up games). Names, keys and seats as the real Lobby lists
# them (lobby.fujinet.online, 2026-11-03); the Arcadia clients point at the
# bench copies on the memory card, which talk to the bench's game servers.
set -euo pipefail
cd "$(dirname "$0")/.."
. emu/ports.env
room() {    # game appkey server maxplayers curplayers port file
    curl -sf -X POST "http://127.0.0.1:$LOBBY_PORT/server" -H 'Content-Type: application/json' -d "{
      \"game\": \"$1\", \"appkey\": $2, \"server\": \"$3\", \"region\": \"us\",
      \"serverurl\": \"http://127.0.0.1:$6/?table=$(echo "$3" | tr A-Z a-z | tr -dc 'a-z0-9' | head -c 12)\",
      \"status\": \"online\", \"maxplayers\": $4, \"curplayers\": $5,
      \"clients\": [{\"platform\": \"arcadia\", \"url\": \"tnfs://SD/arcadia/$7\"},
                    {\"platform\": \"atari\", \"url\": \"tnfs://example/atari\"}]}" > /dev/null
}
room "5 Card Stud" 1 "AI Room - 2 bots" 6 2 "$FCS_PORT" 5card.bin
room "5 Card Stud" 1 "The Basement" 8 3 "$FCS_PORT" 5card.bin
room "5 Card Stud" 1 "The Den" 8 0 "$FCS_PORT" 5card.bin
room "Battleship" 5 "AI - 1 on 1" 4 1 "$BS_PORT" battleship.bin
room "Battleship" 5 "Cape Fuji" 4 2 "$BS_PORT" battleship.bin
room "Fujitzee" 3 "AI Room - 2 bots" 6 2 "$FZ_PORT" fujitzee.bin
room "Fujitzee" 3 "Kitchen Table" 6 1 "$FZ_PORT" fujitzee.bin
room "Texas Hold'em" 8 "AI Room - 4 bots" 4 4 "$TH_PORT" texas.bin
room "Texas Hold'em" 8 "The Den" 8 2 "$TH_PORT" texas.bin
curl -sf "http://127.0.0.1:$LOBBY_PORT/view?platform=arcadia" | head -c 600; echo
