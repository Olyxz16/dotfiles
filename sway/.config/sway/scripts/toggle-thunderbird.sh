#!/usr/bin/env bash
set -euo pipefail

APP_ID="org.mozilla.thunderbird"
MARK="thunderbird_main"

TREE=$(swaymsg -t get_tree)

# Find any thunderbird window in the tree
WINDOW_IDS=$(echo "$TREE" | jq --arg app_id "$APP_ID" '.. | objects | select(.app_id? == $app_id) | .id')

# If no thunderbird window exists, launch it
if [ -z "$WINDOW_IDS" ]; then
    flatpak run org.mozilla.thunderbird &
    exit 0
fi

# Check if we already have a marked main window
MARKED_ID=$(echo "$TREE" | jq --arg mark "$MARK" '.. | objects | select(.marks? | index($mark)) | .id')

if [ -z "$MARKED_ID" ]; then
    # No marked window yet — grab the oldest Thunderbird window and mark it
    OLDEST_ID=$(echo "$WINDOW_IDS" | head -n1)
    swaymsg "[con_id=$OLDEST_ID] mark --add $MARK"
    MARKED_ID="$OLDEST_ID"
fi

# Check if the marked window is currently stashed in the scratchpad
SCRATCHPAD_ID=$(echo "$TREE" | jq --arg mark "$MARK" '.. | objects | select(.name? == "__i3_scratch") | .. | objects | select(.marks? | index($mark)) | .id')

if [ -n "$SCRATCHPAD_ID" ]; then
    swaymsg "[con_id=$MARKED_ID] scratchpad show"
else
    swaymsg "[con_id=$MARKED_ID] move to scratchpad"
fi
