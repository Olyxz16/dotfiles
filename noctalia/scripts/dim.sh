#!/usr/bin/env bash
# dim.sh — smoothly dim brightness on idle, relative to current value.
# Point noctalia's "on idle timeout" command at this script.
set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/brightness-lib.sh"

# If already dimmed (state file exists), don't overwrite the saved
# "before" value — this makes the script idempotent/safe to call twice.
if [ -f "$STATE_FILE" ]; then
    exit 0
fi

current=$(get_brightness)
max=$(get_max_brightness)

echo "$current" > "$STATE_FILE"

# Track this process so restore.sh can cancel us if activity resumes
# mid-fade — otherwise our remaining steps would overwrite the restore.
echo $$ > "$PID_FILE"
trap 'rm -f "$PID_FILE"' EXIT
trap 'rm -f "$PID_FILE"; exit 0' TERM

floor=$(( max * MIN_FLOOR_PERCENT / 100 ))
target=$(awk -v b="$current" -v f="$DIM_FACTOR" 'BEGIN{printf "%d", b*f}')

# Never brighten the screen, and never go below the floor.
[ "$target" -gt "$current" ] && target=$current
[ "$target" -lt "$floor" ] && target=$floor

fade_to "$target"
