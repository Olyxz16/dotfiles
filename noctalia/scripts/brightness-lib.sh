#!/usr/bin/env bash
# brightness-lib.sh — shared helpers, sourced by dim.sh and restore.sh
# Not meant to be run directly.

# ---------- Config (tune to taste) ----------
DIM_FACTOR=0.35          # dim target = current_brightness * DIM_FACTOR
MIN_FLOOR_PERCENT=2      # never go below this % of max — avoids a black screen
STEPS=30                 # fade smoothness (more = smoother)
STEP_TIME=0.02           # seconds between steps
DEVICE=""                # e.g. "intel_backlight"; empty = brightnessctl default
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/hypr-idle-dim-brightness"
PID_FILE="${STATE_FILE}.pid"
# ---------------------------------------------

dev_arg=()
[ -n "$DEVICE" ] && dev_arg=(-d "$DEVICE")

get_brightness() { brightnessctl "${dev_arg[@]}" g; }
get_max_brightness() { brightnessctl "${dev_arg[@]}" m; }
set_brightness() { brightnessctl "${dev_arg[@]}" s "$1" >/dev/null; }

# Smoothly step current brightness towards $1
fade_to() {
    local target=$1
    local current
    current=$(get_brightness)

    [ "$current" -eq "$target" ] && return 0

    local diff=$(( target - current ))
    local step_size=$(( diff / STEPS ))
    [ "$step_size" -eq 0 ] && step_size=$(( diff > 0 ? 1 : -1 ))

    local i=0
    while [ "$i" -lt "$STEPS" ]; do
        current=$(( current + step_size ))
        if { [ "$step_size" -gt 0 ] && [ "$current" -gt "$target" ]; } || \
           { [ "$step_size" -lt 0 ] && [ "$current" -lt "$target" ]; }; then
            current=$target
        fi
        set_brightness "$current"
        sleep "$STEP_TIME"
        [ "$current" -eq "$target" ] && break
        i=$(( i + 1 ))
    done
    set_brightness "$target"   # guarantee we land exactly on target
}
