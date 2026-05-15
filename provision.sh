#!/usr/bin/env bash
# ============================================================================
# This script:
#   1. Updates the system & enables non-free repos
#   2. Adds third-party apt repositories (adapted for Debian bookworm)
#   3. Installs packages from apt (including Steam, Neovim via Bob, no Discord deb)
#   4. Installs Flatpak applications (including Discord for auto-updates)
#   5. Installs dev toolchains (nvm, Bob/neovim, rustup, Go, SDKMAN)
#   6. Restores pip & npm packages (from backup files)
#   7. Prints manual installation instructions for what it can't automate
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
# SECTION 0: Pre-flight checks
# ============================================================================
preflight() {
    echo "========================================="
    echo "  Debian Installation script"
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

    # Enable contrib, non-free, and non-free-firmware on all relevant lines
    sed -i 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/official-package-repositories.list 2>/dev/null || true
    sed -i '/^# deb-src/s/^# //' /etc/apt/sources.list.d/official-package-repositories.list 2>/dev/null || true

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
        software-properties-common dirmngr unzip
    log "Prerequisites installed"
}

# ============================================================================
# SECTION 3: Add third-party apt repositories
# ============================================================================
add_repos() {
    echo ""
    echo ">>> [3/8] Adding third-party repositories..."

    install -m 0755 -d /etc/apt/keyrings

    # --- Docker CE ---
    # NOTE: LMDE's VERSION_CODENAME is "faye", not "bookworm". Hardcode bookworm.
    # Uses DEB822 .sources format per official Docker docs.
    info "Adding Docker CE repository..."
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: bookworm
Components: stable
Architectures: amd64
Signed-By: /etc/apt/keyrings/docker.asc
EOF

    # --- Ghostty ---
    info "Adding Ghostty repository"
    warn "Ghostty installation is community-only, be careful"
    sudo curl -fsSL https://debian.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | sudo gpg --dearmor -o /usr/share/keyrings/debian.griffo.io.gpg
    echo "deb [signed-by=/usr/share/keyrings/debian.griffo.io.gpg] https://debian.griffo.io/apt $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/debian.griffo.io.list

    # --- VS Code ---
    info "Adding VS Code repository..."
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list

    # --- Tailscale ---
    info "Adding Tailscale repository..."
    curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
    curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list >/dev/null

    # --- K6 ---
    curl -fsSL https://dl.k6.io/key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/k6-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list

    # --- GitHub CLI ---
    # Suite is "stable main" per official docs, NOT "debian bookworm main"
    info "Adding GitHub CLI repository..."
    wget -qO /etc/apt/keyrings/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list

    # --- Git LFS ---
    info "Adding Git LFS repository..."
    curl -fsSL https://packagecloud.io/github/git-lfs/gpgkey | gpg --dearmor -o /etc/apt/keyrings/github_git-lfs-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/github_git-lfs-archive-keyring.gpg] https://packagecloud.io/github/git-lfs/debian/ bookworm main" > /etc/apt/sources.list.d/git-lfs.list

    # --- Kitware (CMake) ---
    # NOTE: Kitware only supports Ubuntu repos. Use noble (24.04) on Debian bookworm.
    info "Adding Kitware CMake repository..."
    curl -fsSL https://apt.kitware.com/keys/kitware-archive-latest.asc | gpg --dearmor -o /usr/share/keyrings/kitware-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ noble main" > /etc/apt/sources.list.d/kitware.list

    # --- Task (Go Task runner) ---
    info "Adding Task repository..."
    curl -fsSL https://dl.cloudsmith.io/public/task/task/gpg.key | gpg --dearmor -o /usr/share/keyrings/task-task-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/task-task-archive-keyring.gpg] https://dl.cloudsmith.io/public/task/task/deb/debian bookworm main" > /etc/apt/sources.list.d/task.list

    # --- Intel oneAPI ---
    info "Adding Intel oneAPI repository..."
    curl -fsSL https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor -o /usr/share/keyrings/oneapi-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" > /etc/apt/sources.list.d/intel-oneapi.list

    # --- .NET / Microsoft ---
    info "Adding Microsoft .NET repository..."
    if [ ! -f /etc/apt/sources.list.d/microsoft-prod.list ]; then
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/debian/12/prod bookworm main" > /etc/apt/sources.list.d/microsoft-prod.list
    fi

    # --- Beekeeper Studio ---
    info "Adding Beekeeper Studio repository..."
    curl -fsSL https://deb.beekeeperstudio.io/beekeeper.key | gpg --dearmor -o /usr/share/keyrings/beekeeper.gpg
    echo "deb [signed-by=/usr/share/keyrings/beekeeper.gpg] https://deb.beekeeperstudio.io stable main" > /etc/apt/sources.list.d/beekeeper-studio.list

}

# ============================================================================
# SECTION 4: Install apt packages
# ============================================================================
install_apt_packages() {
    echo ""
    echo ">>> [4/8] Installing apt packages..."

    # --- Steam: enable i386 multiarch first ---
    info "Enabling i386 multiarch for Steam..."
    dpkg --add-architecture i386 2>/dev/null || true
    apt-get update -y 2>/dev/null || true

    # Packages available directly in Debian bookworm
    local debian_packages=(
        7zip age bat bear bison brightnessctl build-essential clang clinfo
        cmake curl direnv doxygen efibootmgr fd-find ffmpeg fonts-firacode fzf
        gcc-mingw-w64-x86-64 git git-filter-repo imagemagick jq lua5.4 luarocks
        mesa-utils mesa-vulkan-drivers meson neofetch net-tools
        ninja-build nmap nsis openssl pass pkg-config poppler-utils putty
        python3-pip python3-netifaces qemu-system-x86 qemu-utils ripgrep
        screen sqlite3 stow texlive-full tree vulkan-tools wayland-protocols
        wget xclip zoxide

        # Sway + Waybar (alongside Cinnamon)
        sway swaybg swayidle swaylock waybar

        # Desktop utilities
        gnome-tweaks gparted

        # Input method packages
        ibus-table-cangjie-big ibus-table-cangjie3 ibus-table-cangjie5
        libchewing3 libchewing3-data libm17n-0 libopencc-data libopencc1.1
        libotf1 libpinyin-data libpinyin15 m17n-db libmarisa0

        # Development libraries
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

        # Chromium, iwd, vainfo, wev (wayland event viewer)
        chromium iwd vainfo wev

        k6
    )

    info "Installing Debian bookworm packages..."
    for pkg in "${debian_packages[@]}"; do
        if apt-get install -y "$pkg" 2>/dev/null; then
            : # installed successfully
        else
            warn "Could not install: $pkg"
            FAILED_PACKAGES+=("$pkg")
        fi
    done

    # Packages from third-party repos
    local third_party_packages=(
        code
        docker-ce docker-compose-plugin
        tailscale
        beekeeper-studio
        gh
        git-lfs
        task
        cmake
        intel-basekit intel-gsc intel-media-va-driver-non-free intel-opencl-icd
        dotnet-sdk-10.0 aspnetcore-runtime-10.0
    )

    info "Installing third-party repo packages..."
    for pkg in "${third_party_packages[@]}"; do
        if apt-get install -y "$pkg" 2>/dev/null; then
            : # installed successfully
        else
            warn "Could not install: $pkg"
            FAILED_PACKAGES+=("$pkg")
        fi
    done

    # Best-effort packages (may not be available on bookworm or different naming)
    local best_effort_packages=(
        grimshot
        libwebkit2gtk-4.1-dev
        libwebkitgtk-6.0-dev libwebkitgtk-6.0-4
        libmfx-gen1 libze1 libze-intel-gpu1
        libva-glx2
        libncurses5 libtinfo5
    )

    info "Installing best-effort packages (some may not be available)..."
    for pkg in "${best_effort_packages[@]}"; do
        if apt-get install -y "$pkg" 2>/dev/null; then
            : # installed successfully
        else
            warn "Not available on bookworm: $pkg (skipping)"
            FAILED_PACKAGES+=("$pkg")
        fi
    done

    log "apt package installation complete"
    if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
        echo ""
        warn "The following packages could not be installed:"
        for pkg in "${FAILED_PACKAGES[@]}"; do
            echo "  - $pkg"
        done
    fi
}

# ============================================================================
# SECTION 5: Install Flatpak applications
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
        "me.proton.authenticator"
        "org.gnome.NetworkDisplays"
        "org.localsend.localsend_app"
    )

    for app in "${flatpak_apps[@]}"; do
        info "Installing $app..."
        if flatpak install -y flathub "$app" 2>/dev/null; then
            log "Installed: $app"
        else
            warn "Failed to install: $app"
        fi
    done

    log "Flatpak installation complete"
}

# ============================================================================
# SECTION 6: Install dev toolchains
# ============================================================================
install_toolchains() {
    echo ""
    echo ">>> [6/8] Installing dev toolchains..."

    local USER_HOME="/home/olyxz"
    local USER_NAME="olyxz"

    # --- nvm (Node Version Manager) ---
    info "Installing nvm..."
    su - "$USER_NAME" -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash'
    su - "$USER_NAME" -c 'export NVM_DIR="$USER_HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; nvm install v22.22.0 && nvm install v24.13.0 && nvm alias default v22.22.0'
    log "nvm + Node v22.22.0 & v24.13.0 installed"

    # --- Bob (Neovim version manager) ---
    info "Installing Bob (neovim version manager)..."
    su - "$USER_NAME" -c 'curl -fsSL https://github.com/MordechaiHadad/bob/releases/latest/download/bob-linux-x86_64.zip -o /tmp/bob.zip && cd /tmp && unzip -o bob.zip && mkdir -p ~/.local/bin && cp /tmp/bob-linux-x86_64/bob ~/.local/bin/bob && chmod +x ~/.local/bin/bob && rm -rf /tmp/bob.zip /tmp/bob-linux-x86_64' 2>/dev/null || {
        warn "Bob install failed — install manually: https://github.com/MordechaiHadad/bob"
    }
    info "Installing Neovim latest via Bob..."
    su - "$USER_NAME" -c 'export PATH="$USER_HOME/.local/bin:$PATH"; bob install latest && bob use latest' 2>/dev/null || {
        warn "Bob neovim install failed — run 'bob install latest && bob use latest' manually after login"
    }

    # --- Rust (rustup) ---
    info "Installing rustup..."
    su - "$USER_NAME" -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y'
    log "Rust installed via rustup"

    # --- Go ---
    info "Installing Go..."
    apt-get install -y golang-go 2>/dev/null || {
        warn "golang-go not in repos, installing manually..."
        GO_VERSION="1.24.3"
        curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
        rm -rf /usr/local/go
        tar -C /usr/local -xzf /tmp/go.tar.gz
        rm /tmp/go.tar.gz
        echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
    }
    log "Go installed"

    # --- Opencode ---
    info "Installing Opencode..."
    su - "$USER_NAME" -c 'curl -fsSL https://opencode.ai/install | bash'
    log "Opencode installed"

    # --- Zed ---
    info "Installing Zed editor..."
    su - "$USER_NAME" -c 'curl -f https://zed.dev/install.sh | sh'
    log "Zed installed"

    # --- Devbox ---
    info "Installing devbox..."
    su - "$USER_NAME" -c 'curl -fsSL https://get.jetify.com/devbox | bash'
    log "Devbox installed"

    # --- SDKMAN (Java) ---
    info "Installing SDKMAN..."
    su - "$USER_NAME" -c 'curl -s "https://get.sdkman.io" | bash'
    su - "$USER_NAME" -c 'export SDKMAN_DIR="$USER_HOME/.sdkman"; [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ] && source "$HOME/.sdkman/bin/sdkman-init.sh"; sdk install java 8.0.482-tem; sdk install java 21.0.6-tem'
    log "SDKMAN + Java 8 & 21 installed"

    # --- k9s ---
    info "Installing k9s system-wide"
    curl -fsSL https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz | tar -xzf - -C /usr/local/bin k9s
    log "k9s installed"

    # --- Docker post-install ---
    info "Configuring Docker..."
    usermod -aG docker "$USER_NAME"
    systemctl enable docker
    systemctl start docker
    log "Docker configured (user added to docker group)"

    # --- Tailscale ---
    info "Configuring Tailscale..."
    systemctl enable tailscaled
    systemctl start tailscaled
    log "Tailscale enabled (run 'tailscale up' to connect)"

    log "Dev toolchains installed"
}

# ============================================================================
# SECTION 7 : Dotfiles
# ============================================================================

setup_dotfiles() {
    echo ""
    echo ">>> [7/8] Setting up dotfiles..."

    git clone https://github.com/Olyxz16/dotfiles .dotfiles
    cd ~/.dotfiles
    stow bash nvim sway waybar yazi

}

# ============================================================================
# SECTION 8: Post-install configuration & summary
# ============================================================================
post_install() {
    echo ""
    echo ">>> [8/8] Provisionning complete !"

    if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
        echo -e "${YELLOW}Failed packages (${#FAILED_PACKAGES[@]}):${NC}"
        for pkg in "${FAILED_PACKAGES[@]}"; do
            echo "  - $pkg"
        done
        echo ""
    fi

    echo ""
    echo -e "${BLUE}=== Post-install steps ===${NC}"
    echo ""
    echo "  Log out and back in for Docker group to take effect"
    echo ""
    echo -e "${GREEN}Done! Your system is set up.${NC}"
}

# ============================================================================
# Main execution
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
