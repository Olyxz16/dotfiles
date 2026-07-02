#!/usr/bin/env bash
# Note: we intentionally omit -u because several third-party init scripts
# (nvm, SDKMAN, etc.) reference variables that may be unset.
set -eo pipefail

mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

log() { echo "[toolchains] $*"; }

# -----------------------------------------------------------------------------
# Node Version Manager (nvm)
# -----------------------------------------------------------------------------
if [ ! -d "$HOME/.nvm" ]; then
    log "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi

export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

log "Installing Node versions..."
nvm install v22.22.0
nvm install v24.13.0
nvm alias default v22.22.0

# -----------------------------------------------------------------------------
# Bob (Neovim version manager)
# -----------------------------------------------------------------------------
if [ ! -f "$HOME/.local/bin/bob" ]; then
    log "Installing Bob..."
    tmpdir=$(mktemp -d)
    curl -fsSL https://github.com/MordechaiHadad/bob/releases/latest/download/bob-linux-x86_64.zip -o "$tmpdir/bob.zip"
    unzip -o "$tmpdir/bob.zip" -d "$tmpdir/bob"
    cp "$tmpdir/bob/bob" "$HOME/.local/bin/bob"
    chmod +x "$HOME/.local/bin/bob"
    rm -rf "$tmpdir"
fi

log "Installing Neovim via Bob..."
bob install latest || true
bob use latest || true

# -----------------------------------------------------------------------------
# Rust
# -----------------------------------------------------------------------------
if [ ! -f "$HOME/.cargo/bin/rustc" ]; then
    log "Installing Rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# -----------------------------------------------------------------------------
# Opencode
# -----------------------------------------------------------------------------
if [ ! -d "$HOME/.opencode/bin" ]; then
    log "Installing Opencode..."
    curl -fsSL https://opencode.ai/install | bash
fi

# -----------------------------------------------------------------------------
# Zed
# -----------------------------------------------------------------------------
if [ ! -f "$HOME/.local/bin/zed" ]; then
    log "Installing Zed..."
    curl -f https://zed.dev/install.sh | sh
fi

# -----------------------------------------------------------------------------
# Devbox
# -----------------------------------------------------------------------------
if [ ! -f "$HOME/.local/bin/devbox" ]; then
    log "Installing Devbox..."
    tmpdir=$(mktemp -d)
    latest_url=$(curl -fsSL https://api.github.com/repos/jetify-com/devbox/releases/latest | grep -oE 'https://[^"]+devbox_[0-9]+\.[0-9]+\.[0-9]+_linux_amd64\.tar\.gz' | head -n 1)
    curl -fsSL "$latest_url" -o "$tmpdir/devbox.tar.gz"
    tar -xzf "$tmpdir/devbox.tar.gz" -C "$HOME/.local/bin" devbox
    chmod +x "$HOME/.local/bin/devbox"
    rm -rf "$tmpdir"
fi

# -----------------------------------------------------------------------------
# SDKMAN + Java
# -----------------------------------------------------------------------------
if [ ! -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    log "Installing SDKMAN..."
    curl -s "https://get.sdkman.io" | bash
fi

export SDKMAN_DIR="$HOME/.sdkman"
# shellcheck disable=SC1091
source "$SDKMAN_DIR/bin/sdkman-init.sh"

log "Installing Java versions..."
sdk install java 8.0.482-tem || true
sdk install java 21.0.6-tem || true

# -----------------------------------------------------------------------------
# lf (file manager)
# -----------------------------------------------------------------------------
if command -v go >/dev/null 2>&1; then
    log "Installing lf..."
    env CGO_ENABLED=0 go install -trimpath -ldflags="-s -w" github.com/gokcehan/lf@latest
else
    log "Go not found; skipping lf install (install Go via Ansible first)"
fi

log "User-level toolchains configured."
