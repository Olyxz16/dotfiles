#!/bin/bash

INTERNAL="eDP-1"
EXTERNAL="HDMI-A-1"

# Check dependencies
if ! command -v jq &> /dev/null; then
    notify-send "Mirror Error" "jq is required but not installed"
    exit 1
fi

case "$1" in
    mirror)
        # Verify external display exists
        if ! swaymsg -t get_outputs | jq -e --arg name "$EXTERNAL" '.[] | select(.name == $name)' > /dev/null 2>&1; then
            notify-send "Mirror" "External display $EXTERNAL not connected"
            exit 1
        fi

        # Get internal logical size
        read -r int_w int_h < <(swaymsg -t get_outputs | jq -r --arg name "$INTERNAL" '.[] | select(.name == $name) | "\(.rect.width) \(.rect.height)"')

        # Get external physical resolution
        read -r ext_w ext_h < <(swaymsg -t get_outputs | jq -r --arg name "$EXTERNAL" '.[] | select(.name == $name) | "\(.current_mode.width) \(.current_mode.height)"')

        # Calculate scale to fit internal logical desktop into external physical resolution
        scale_w=$(awk "BEGIN {printf \"%.4f\", $ext_w / $int_w}")
        scale_h=$(awk "BEGIN {printf \"%.4f\", $ext_h / $int_h}")

        # Pick the smaller scale so the entire desktop fits
        # (letterbox/pillarbox with background color if aspect ratios differ)
        if awk "BEGIN {exit !($scale_w < $scale_h)}"; then
            scale=$scale_w
        else
            scale=$scale_h
        fi

        wlr-randr --output "$INTERNAL" --pos 0,0 --output "$EXTERNAL" --pos 0,0 --scale "$scale"
        notify-send "Screen Share" "Mirrored to $EXTERNAL (scale: $scale)"
        ;;
    extend)
        read -r int_w int_h < <(swaymsg -t get_outputs | jq -r --arg name "$INTERNAL" '.[] | select(.name == $name) | "\(.rect.width) \(.rect.height)"')
        wlr-randr --output "$INTERNAL" --pos 0,0 --output "$EXTERNAL" --pos "${int_w},0" --scale 1
        notify-send "Screen Share" "Extended mode restored"
        ;;
    *)
        echo "Usage: $0 {mirror|extend}"
        exit 1
        ;;
esac
