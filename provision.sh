#!/usr/bin/env bash
# ============================================================================
# Debian Bookworm Provisioning Script
# ============================================================================

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
fail() { echo -e "${RED}[FAIL]${NC} $*"; }
info() { echo -e "${BLUE}[INFO]${NC} $*"; }

FAILED_PACKAGES=()

# ============================================================================
# REPO DEFINITIONS
# To add a new repo, just append an entry to this array.
#
# Format (one entry = one string, fields separated by |):
#   name|gpg_url|gpg_dest|repo_line
#
# Fields:
#   name      - used for the .list filename (/etc/apt/sources.list.d/<name>.list)
#   gpg_url   - URL to fetch the GPG key from (raw .asc or .gpg)
#   gpg_dest  - where to save the key on disk
#   repo_line - the full "deb [signed-by=...] ..." line
#
# The key file is only downloaded if it doesn't already exist.
# The .list file is only written if it doesn't already exist or its content changed.
# ============================================================================
declare -a REPOS=(
    "vscode|https://packages.microsoft.com/keys/microsoft.asc|/usr/share/keyrings/microsoft-archive-keyring.gpg|deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/code stable main"
    "tailscale|https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg|/usr/share/keyrings/tailscale-archive-keyring.gpg|deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/debian bookworm main"
    "k6|https://dl.k6.io/key.gpg|/usr/share/keyrings/k6-archive-keyring.gpg|deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main"
    "github-cli|https://cli.github.com/packages/githubcli-archive-keyring.gpg|/etc/apt/keyrings/githubcli-archive-keyring.gpg|deb [arch=amd64 signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main"
    "git-lfs|https://packagecloud.io/github/git-lfs/gpgkey|/etc/apt/keyrings/github_git-lfs-archive-keyring.gpg|deb [arch=amd64 signed-by=/etc/apt/keyrings/github_git-lfs-archive-keyring.gpg] https://packagecloud.io/github/git-lfs/debian/ bookworm main"
    "kitware|https://apt.kitware.com/keys/kitware-archive-latest.asc|/usr/share/keyrings/kitware-archive-keyring.gpg|deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ noble main"
    "task|https://dl.cloudsmith.io/public/task/task/gpg.key|/usr/share/keyrings/task-task-archive-keyring.gpg|deb [signed-by=/usr/share/keyrings/task-task-archive-keyring.gpg] https://dl.cloudsmith.io/public/task/task/deb/debian bookworm main"
    "intel-oneapi|https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB|/usr/share/keyrings/oneapi-archive-keyring.gpg|deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main"
    "microsoft-prod|https://packages.microsoft.com/keys/microsoft.asc|/usr/share/keyrings/microsoft-prod.gpg|deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/debian/12/prod bookworm main"
    "beekeeper-studio|https://deb.beekeeperstudio.io/beekeeper.key|/usr/share/keyrings/beekeeper.gpg|deb [signed-by=/usr/share/keyrings/beekeeper.gpg] https://deb.beekeeperstudio.io stable main"
    "spotify|https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.asc|/etc/apt/trusted.gpg.d/spotify.gpg|deb https://repository.spotify.com stable non-free"
)

# Docker uses DEB822 format, handled separately below
# If you need more DEB822 repos, add them to REPOS_DEB822
declare -a REPOS_DEB822=(
    # Format: name|gpg_url|gpg_dest|uris|suites|components|architectures
    # Leave architectures empty if not needed
    "docker|https://download.docker.com/linux/debian/gpg|/etc/apt/keyrings/docker.asc|https://download.docker.com/linux/debian|bookworm|stable|amd64"
)

# ============================================================================
# REPO ENGINE
# ============================================================================

# Writes a file only if it doesn't exist or content has changed
write_if_changed() {
    local path="$1"
    local content="$2"
    if [ -f "$path" ] && [ "$(cat "$path")" = "$content" ]; then
        return 0  # unchanged
    fi
    printf '%s\n' "$content" > "$path"
    return 1  # written
}

# Fetches a GPG key (handles both armored .asc and binary .gpg)
fetch_gpg_key() {
    local url="$1"
    local dest="$2"
    if [ -f "$dest" ]; then
        return 0
    fi
    info "Fetching GPG key: $url"
    local tmp
    tmp=$(mktemp)
    curl -fsSL "$url" -o "$tmp"
    # Detect if armored (ASCII) and dearmor if needed
    if file "$tmp" | grep -q "PGP public key block\|OpenPGP Public Key\|ASCII"; then
        gpg --dearmor < "$tmp" > "$dest"
    else
        cp "$tmp" "$dest"
    fi
    chmod 644 "$dest"
    rm -f "$tmp"
}

add_repos() {
    echo ""
    echo ">>> [3/8] Adding third-party repositories..."

    install -m 0755 -d /etc/apt/keyrings

    # --- Standard .list repos ---
    for entry in "${REPOS[@]}"; do
        IFS='|' read -r name gpg_url gpg_dest repo_line <<< "$entry"
        info "Configuring repo: $name"
        fetch_gpg_key "$gpg_url" "$gpg_dest"
        local list_file="/etc/apt/sources.list.d/${name}.list"
        if write_if_changed "$list_file" "$repo_line"; then
            : # no change
        else
            info "Written: $list_file"
        fi
    done

    # --- DEB822 .sources repos ---
    for entry in "${REPOS_DEB822[@]}"; do
        IFS='|' read -r name gpg_url gpg_dest uris suites components architectures <<< "$entry"
        info "Configuring DEB822 repo: $name"
        fetch_gpg_key "$gpg_url" "$gpg_dest"
        local sources_file="/etc/apt/sources.list.d/${name}.sources"
        local content="Types: deb
URIs: $uris
Suites: $suites
Components: $components"
        [ -n "$architectures" ] && content+="
Architectures: $architectures"
        content+="
Signed-By: $gpg_dest"
        if write_if_changed "$sources_file" "$content"; then
            : # no change
        else
            info "Written: $sources_file"
        fi
    done

    apt-get update -y
    log "Repositories configured"
}

# ============================================================================
# SECTION 0: Pre-flight checks
# ============================================================================
preflight() {
    echo "========================================="
    echo "  Debian Provisioning Script"
    echo "========================================="
    echo ""

    if [ "$(id -u)" -ne 0 ]; then
        fail "This script must be run as root. Use: sudo $0"
        exit 1
    fi

    if [ ! -f /etc/linuxmint/info ] && [ ! -f /etc/debian_version ]; then
        warn "This doesn't appear to be Debian. Continue anyway? (y/n)"
        read -r response
        if [ "$response" != "y" ]; then
            exit 1
        fi
    fi

    export DEBIAN_FRONTEND=noninteractive
    log "Pre-flight checks passed"
}

# ============================================================================
# SECTION 1: System update & enable non-free/contrib repos
# ============================================================================
system_update() {
    echo ""
    echo ">>> [1/8] Updating system and enabling repositories..."
    apt-get update -y
    apt-get upgrade -y

    sed -i 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/official-package-repositories.list 2>/dev/null || true

    apt-get update -y
    log "System updated and non-free repos enabled"
}

# ============================================================================
# SECTION 2: Install prerequisites
# ============================================================================
install_prerequisites() {
    echo ""
    echo ">>> [2/8] Installing prerequisites..."
    apt-get install -y \
        curl wget gnupg2 ca-certificates lsb-release apt-transport-https \
        software-properties-common dirmngr unzip file
    log "Prerequisites installed"
}

# ============================================================================
# SECTION 4: Install apt packages
# ============================================================================
install_apt_packages() {
    echo ""
    echo ">>> [4/8] Installing apt packages..."

    info "Enabling i386 multiarch for Steam..."
    dpkg --add-architecture i386 2>/dev/null || true
    apt-get update -y 2>/dev/null || true

    local debian_packages=(
        7zip age bat bear bison brightnessctl build-essential clang clinfo
        cmake curl direnv doxygen efibootmgr fd-find ffmpeg fonts-firacode fzf
        gcc-mingw-w64-x86-64 git git-filter-repo imagemagick jq lua5.4 luarocks
        mesa-utils mesa-vulkan-drivers meson neofetch net-tools
        ninja-build nmap nsis openssl pass pkg-config poppler-utils putty
        python3-pip python3-netifaces qemu-system-x86 qemu-utils ripgrep
        screen sqlite3 stow texlive-full tree vulkan-tools wayland-protocols
        wget xclip zoxide
        sway swaybg swayidle swaylock waybar fuzzel wl-mirror mako-notifier kanshi
        gnome-tweaks gparted
        ibus-table-cangjie-big ibus-table-cangjie3 ibus-table-cangjie5
        libchewing3 libchewing3-data libm17n-0 libopencc-data libopencc1.1
        libotf1 libpinyin-data libpinyin15 m17n-db libmarisa0
        libadwaita-1-dev libavahi-client-dev libavahi-gobject-dev
        libavcodec-dev libavformat-dev libavutil-dev libcurl4-openssl-dev
        libdrm-dev libegl1-mesa-dev libgbm-dev libgdk-pixbuf2.0-0 libgl1-mesa-dev
        libgles2-mesa-dev libgstreamer-plugins-base1.0-dev libgstrtspserver-1.0-dev
        libgtk-3-dev libgtk-4-dev libgudev-1.0-dev libinput-dev libjson-glib-dev
        libnm-dev libpixman-1-dev libpng-dev libportal-gtk4-dev libprotobuf-c-dev
        libpulse-dev libqt5charts5-dev libqt5serialport5-dev libsimde-dev
        libsoup-3.0-dev libssl-dev libsystemd-dev libvulkan-dev libwayland-dev
        libx11-xcb-dev libxcb-composite0-dev libxcb-cursor0 libxcb-cursor-dev
        libxcb-icccm4-dev libxcb-image0-dev libxcb-render0-dev libxcb-xfixes0-dev
        libxcb-xinput-dev libxcursor-dev libxi-dev libxinerama-dev
        libxkbcommon-dev libxrandr-dev libxxf86vm-dev
        qtconnectivity5-dev spirv-headers spirv-tools
        chromium iwd vainfo wev
        k6
    )

    info "Installing Debian bookworm packages..."
    for pkg in "${debian_packages[@]}"; do
        if apt-get install -y "$pkg" 2>/dev/null; then
            :
        else
            warn "Could not install: $pkg"
            FAILED_PACKAGES+=("$pkg")
        fi
    done

    local third_party_packages=(
        code
        docker-ce docker-compose-plugin
        tailscale
        beekeeper-studio
        gh git-lfs
        task
        cmake
        intel-basekit intel-gsc intel-media-va-driver-non-free intel-opencl-icd
        dotnet-sdk-10.0 aspnetcore-runtime-10.0
        spotify-client
    )

    info "Installing third-party repo packages..."
    for pkg in "${third_party_packages[@]}"; do
        if apt-get install -y "$pkg" 2>/dev/null; then
            :
        else
            warn "Could not install: $pkg"
            FAILED_PACKAGES+=("$pkg")
        fi
    done

    local best_effort_packages=(
        grimshot libwebkit2gtk-4.1-dev
        libwebkitgtk-6.0-dev libwebkitgtk-6.0-4
        libmfx-gen1 libze1 libze-intel-gpu1
        libva-glx2 libncurses5 libtinfo5
    )

    info "Installing best-effort packages..."
    for pkg in "${best_effort_packages[@]}"; do
        apt-get install -y "$pkg" 2>/dev/null || warn "Not available: $pkg (skipping)"
    done

    log "apt package installation complete"
}

# ============================================================================
# SECTION 5: Flatpak
# ============================================================================
install_flatpaks() {
    echo ""
    echo ">>> [5/8] Installing Flatpak applications..."

    apt-get install -y flatpak
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

    local flatpak_apps=(
        "com.discordapp.Discord"
        "com.bitwarden.desktop"
        "com.jgraph.drawio.desktop"
        "com.notesnook.Notesnook"
        "com.orama_interactive.Pixelorama"
        "com.rtosta.zapzap"
        "com.tutanota.Tutanota"
        "me.proton.Pass"
        "org.gnome.NetworkDisplays"
        "org.localsend.localsend_app"
    )

    for app in "${flatpak_apps[@]}"; do
        info "Installing $app..."
        flatpak install -y --noninteractive flathub "$app" 2>/dev/null || warn "Failed: $app"
    done

    log "Flatpak installation complete"
}

# ============================================================================
# SECTION 6: Dev toolchains
# ============================================================================
install_toolchains() {
    echo ""
    echo ">>> [6/8] Installing dev toolchains..."

    local USER_HOME="/home/olyxz"
    local USER_NAME="olyxz"

    # nvm
    info "Installing nvm..."
    [ -f "$USER_HOME/.nvm/nvm.sh" ] || \
        su - "$USER_NAME" -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash'
    su - "$USER_NAME" -c '
        export NVM_DIR="$HOME/.nvm"; source "$NVM_DIR/nvm.sh"
        nvm ls v22.22.0 >/dev/null 2>&1 || nvm install v22.22.0
        nvm ls v24.13.0 >/dev/null 2>&1 || nvm install v24.13.0
        nvm alias default v22.22.0
    '
    log "nvm installed"

    # Bob + Neovim
    info "Installing Bob (neovim version manager)..."
    if [ ! -f "$USER_HOME/.local/bin/bob" ]; then
        su - "$USER_NAME" -c '
            curl -fsSL https://github.com/MordechaiHadad/bob/releases/latest/download/bob-linux-x86_64.zip -o /tmp/bob.zip
            cd /tmp && unzip -o bob.zip
            mkdir -p ~/.local/bin
            cp /tmp/bob-linux-x86_64/bob ~/.local/bin/bob
            chmod +x ~/.local/bin/bob
            rm -rf /tmp/bob.zip /tmp/bob-linux-x86_64
        '
    fi
    su - "$USER_NAME" -c '
        export PATH="$HOME/.local/bin:$PATH"
        bob list 2>/dev/null | grep -q "nightly\|latest" || (bob install latest && bob use latest)
    ' || warn "Bob neovim install failed — run manually after login"
    log "Neovim installed via Bob"

    # Rust
    info "Installing Rust..."
    [ -f "$USER_HOME/.cargo/bin/rustc" ] || \
        su - "$USER_NAME" -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y'
    log "Rust installed"

    # Go
    info "Installing Go..."
    if [ ! -f /usr/local/go/bin/go ]; then
        GO_VERSION="1.24.3"
        curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
        rm -rf /usr/local/go
        tar -C /usr/local -xzf /tmp/go.tar.gz
        rm /tmp/go.tar.gz
        echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
    fi
    log "Go installed"

    # Opencode
    info "Installing Opencode..."
    [ -f "$USER_HOME/.opencode/bin/opencode" ] || \
        su - "$USER_NAME" -c 'curl -fsSL https://opencode.ai/install | bash'
    log "Opencode installed"

    # Zed
    info "Installing Zed..."
    [ -f "$USER_HOME/.local/bin/zed" ] || \
        su - "$USER_NAME" -c 'curl -f https://zed.dev/install.sh | sh'
    log "Zed installed"

    # Devbox
    info "Installing Devbox..."
    [ -f /usr/local/bin/devbox ] || \
        su - "$USER_NAME" -c 'curl -fsSL https://get.jetify.com/devbox | bash'
    log "Devbox installed"

    # SDKMAN + Java
    info "Installing SDKMAN..."
    if [ ! -f "$USER_HOME/.sdkman/bin/sdkman-init.sh" ]; then
        su - "$USER_NAME" -c 'curl -s "https://get.sdkman.io" | bash'
    fi
    su - "$USER_NAME" -c '
        export SDKMAN_DIR="$HOME/.sdkman"
        source "$SDKMAN_DIR/bin/sdkman-init.sh"
        sdk list java | grep -q "8.0.482-tem"  || sdk install java 8.0.482-tem
        sdk list java | grep -q "21.0.6-tem"   || sdk install java 21.0.6-tem
    ' || warn "SDKMAN Java install failed"
    log "SDKMAN + Java installed"

    info "Installing lf"
    env CGO_ENABLED=0 go install -trimpath -ldflags="-s -w" github.com/gokcehan/lf@latest
    log "lf installed"

    # k9s
    info "Installing k9s..."
    [ -f /usr/local/bin/k9s ] || \
        curl -fsSL https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz \
        | tar -xzf - -C /usr/local/bin k9s
    log "k9s installed"

    # Docker post-install
    usermod -aG docker olyxz
    systemctl enable --now docker
    systemctl enable --now tailscaled

    log "Dev toolchains installed"
}

# ============================================================================
# SECTION 7: Dotfiles
# ============================================================================
setup_dotfiles() {
    echo ""
    echo ">>> [7/8] Setting up dotfiles..."

    local USER_HOME="/home/olyxz"
    local USER_NAME="olyxz"
    local DOTFILES_DIR="$USER_HOME/.dotfiles"

    if [ ! -d "$DOTFILES_DIR/.git" ]; then
        su - "$USER_NAME" -c "git clone https://github.com/Olyxz16/dotfiles $DOTFILES_DIR"
    else
        info "Dotfiles already cloned, skipping"
    fi

    su - "$USER_NAME" -c "cd $DOTFILES_DIR && stow bash nvim sway waybar yazi lf"
    log "Dotfiles configured"
}

# ============================================================================
# SECTION 8: Summary
# ============================================================================
post_install() {
    echo ""
    echo ">>> [8/8] Provisioning complete!"

    if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
        echo -e "${YELLOW}Failed packages (${#FAILED_PACKAGES[@]}):${NC}"
        for pkg in "${FAILED_PACKAGES[@]}"; do
            echo "  - $pkg"
        done
    fi

    echo ""
    echo -e "${BLUE}=== Post-install steps ===${NC}"
    echo "  - Log out and back in for Docker group to take effect"
    echo "  - Run 'tailscale up' to connect"
    echo -e "${GREEN}Done!${NC}"
}

# ============================================================================
# Main
# ============================================================================
main() {
    preflight
    system_update
    install_prerequisites
    add_repos
    install_apt_packages
    install_flatpaks
    install_toolchains
    setup_dotfiles
    post_install
}

main "$@"
