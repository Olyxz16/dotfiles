#!/usr/bin/env bash
# restore.sh — smoothly restore brightness on activity/resume.
# Point noctalia's "on resume / on activity" command at this script.
set -euo pipefail
source "$(dirname "$(readlink -f "$0")")/brightness-lib.sh"

# If a dim fade is still running, stop it first so it can't race with
# (and overwrite) the instant restore below.
if [ -f "$PID_FILE" ]; then
    dim_pid=$(cat "$PID_FILE")
    if kill -0 "$dim_pid" 2>/dev/null; then
        kill -TERM "$dim_pid" 2>/dev/null || true
        for _ in 1 2 3 4 5 6 7 8 9 10; do
            kill -0 "$dim_pid" 2>/dev/null || break
            sleep 0.02
        done
    fi
    rm -f "$PID_FILE"
fi

if [ ! -f "$STATE_FILE" ]; then
    # We were never dimmed (or already restored) — nothing to do.
    exit 0
fi

target=$(cat "$STATE_FILE")
rm -f "$STATE_FILE"

set_brightness "$target"
