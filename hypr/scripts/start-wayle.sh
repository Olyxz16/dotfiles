#!/usr/bin/env bash
# Start Wayle fresh with the current Hyprland instance.
# Killing any existing daemon avoids stale HYPRLAND_INSTANCE_SIGNATURE, and
# we also force the live socket because Hyprland can leave stale socket dirs.
pkill -x wayle || true
sleep 0.5

# Wait for the Hyprland socket to appear (up to 3 seconds)
HYPRLAND_INSTANCE_SIGNATURE=""
for i in $(seq 1 30); do
  for dir in /run/user/1000/hypr/*; do
    if [[ -S "$dir/.socket.sock" ]]; then
      HYPRLAND_INSTANCE_SIGNATURE=$(basename "$dir")
      break 2
    fi
  done
  sleep 0.1
done

if [[ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
  echo "start-wayle.sh: failed to find Hyprland socket" >&2
  exit 1
fi

export HYPRLAND_INSTANCE_SIGNATURE
exec ~/.cargo/bin/wayle panel start
