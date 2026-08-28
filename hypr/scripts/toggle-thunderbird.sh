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
    # In scratchpad -> move to current workspace without stealing focus
    CURRENT_WS=$(hyprctl activeworkspace -j | jq -r '.name')
    hyprctl dispatch movetoworkspacesilent "$CURRENT_WS",address:"$ADDRESS" >/dev/null
else
    # Visible on a regular workspace -> stash it in the special workspace
    hyprctl dispatch movetoworkspacesilent "$SPECIAL_WS",address:"$ADDRESS" >/dev/null
fi
