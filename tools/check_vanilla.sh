#!/bin/bash
# Says whether the game's trough tooltip file still matches the one our copy was made from.
# Usage: tools/check_vanilla.sh [game folder, default ~/pzserver]
GAME="${1:-$HOME/pzserver}"
KNOWN=68fe216946671a00dd481de99a117b74b3fbca2b56c2e40784595f6053fe127c
NOW=$(sha256sum "$GAME/media/lua/client/FeedingTrough/CFeedingTroughSystem.lua" | cut -d' ' -f1)
if [ "$NOW" = "$KNOWN" ]; then echo "OK: the game's CFeedingTroughSystem.lua is unchanged."
else echo "CHANGED: the game's CFeedingTroughSystem.lua is different. Re-copy it and redo the gallon change."; exit 1; fi
