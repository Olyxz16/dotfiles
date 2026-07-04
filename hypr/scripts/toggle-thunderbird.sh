#!/usr/bin/env bash
set -euo pipefail

APP_CLASS="org.mozilla.thunderbird"
SPECIAL_WS="special:thunderbird"

CLIENTS=$(hyprctl clients -j)
WIN=$(echo "$CLIENTS" | jq -r --arg class "$APP_CLASS" '[.[] | select(.class == $class)] | sort_by(.focusHistoryID) | first // empty')

# No Thunderbird window yet -> launch it
if [ -z "$WIN" ]; then
    flatpak run org.mozilla.thunderbird &
    exit 0
fi

ADDRESS=$(echo "$WIN" | jq -r '.address')
WS_NAME=$(echo "$WIN" | jq -r '.workspace.name')

if [ "$WS_NAME" = "$SPECIAL_WS" ]; then
    # Already in the scratchpad-like special workspace -> show/hide it
    hyprctl dispatch togglespecialworkspace thunderbird >/dev/null
else
    # Visible on a regular workspace -> stash it in the special workspace
    hyprctl dispatch focuswindow "address:$ADDRESS" >/dev/null
    hyprctl dispatch movetoworkspace "$SPECIAL_WS" >/dev/null
fi
