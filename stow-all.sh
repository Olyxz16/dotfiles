#!/usr/bin/env bash
# ============================================================================
# Stow all dotfiles into their expected locations.
#
# Usage:
#   ./stow-all.sh         # stow all packages
#   ./stow-all.sh -R      # restow all packages
#   ./stow-all.sh -D      # unstow all packages
# ============================================================================

set -euo pipefail

MODE=""
VERBOSE="-v"

while [ $# -gt 0 ]; do
    case "$1" in
        -R|--restow)
            MODE="-R"
            shift
            ;;
        -D|--unstow|-d)
            MODE="-D"
            shift
            ;;
        -q|--quiet)
            VERBOSE=""
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-R|--restow] [-D|--unstow] [-q|--quiet]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if ! command -v stow >/dev/null 2>&1; then
    echo "Error: stow is not installed. Install it with: sudo apt install stow" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Packages that live under ~/.config/<name>
CONFIG_PKGS=(hypr lf nvim sway waybar wayle yazi)

stow_pkg() {
    local target="$1"
    local pkg="$2"
    mkdir -p "$target"
    stow $VERBOSE $MODE -t "$target" "$pkg"
}

for pkg in "${CONFIG_PKGS[@]}"; do
    stow_pkg "$HOME/.config/$pkg" "$pkg"
done

# bashrc lives directly in ~
stow_pkg "$HOME" bash

echo "Dotfiles stowed."
