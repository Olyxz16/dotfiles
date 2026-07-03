#!/usr/bin/env bash
# Start Wayle fresh with the current Hyprland instance.
# Killing any existing daemon avoids stale HYPRLAND_INSTANCE_SIGNATURE, and
# we also force the live socket because Hyprland can leave stale socket dirs.
pkill -x wayle || true
sleep 0.5

for dir in /run/user/1000/hypr/*; do
  if [[ -S "$dir/.socket.sock" ]]; then
    HYPRLAND_INSTANCE_SIGNATURE=$(basename "$dir")
    break
  fi
done

export HYPRLAND_INSTANCE_SIGNATURE
exec wayle panel start
