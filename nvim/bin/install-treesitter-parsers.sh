#!/usr/bin/env bash
#
# Install tree-sitter parser grammars for Neovim using the tree-sitter CLI.
#
# Neovim 0.10+ has treesitter highlighting built in (no nvim-treesitter plugin).
# Parsers are shared libraries it loads from 'parser/' on the runtimepath,
# defaulting to  ~/.local/share/nvim/site/parser/
#
# Parsers are shared libraries: ~/.local/share/nvim/site/parser/<lang>.so
# Query files (highlights, injections, ...) also get deployed to
# ~/.local/share/nvim/site/queries/<lang>/ (Neovim's runtime only carries these
# for its own languages, so grammar queries must be provided for the rest).
#
# Usage:
#   ./bin/install-treesitter-parsers.sh            # install everything below
#   ./bin/install-treesitter-parsers.sh tsx css    # install a subset
#   ./bin/install-treesitter-parsers.sh --update    # rebuild from latest grammars
#
# Requirements: git, a C compiler (cc), and the tree-sitter CLI. The CLI is
# fetched as a prebuilt binary if not already on PATH (falls back to cargo).

set -euo pipefail

TS_VERSION="v0.27.0"
NVIM="${NVIM:-nvim}"

# --- Neovim's parser + query dirs (from stdpath; `site` is on the runtimepath) ----------
SITE_DIR="$("$NVIM" --headless -u NONE \
    +'lua io.write(vim.fn.stdpath("data") .. "/site")' +qa)"
PARSER_DIR="$SITE_DIR/parser"
QUERY_DIR="$SITE_DIR/queries"
mkdir -p "$PARSER_DIR" "$QUERY_DIR"

# --- Where we cache clones and a locally-installed CLI -----------------------
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
CACHE_DIR="$DATA_DIR/nvim/treesitter-install"
BIN_DIR="$CACHE_DIR/bin"
mkdir -p "$BIN_DIR"

# --- grammar registry --------------------------------------------------------
# lang  owner/repo  subdir  (subdir empty => repo root)
GRAMMARS="
typescript  tree-sitter/tree-sitter-typescript  typescript
tsx         tree-sitter/tree-sitter-typescript  tsx
javascript  tree-sitter/tree-sitter-javascript
css         tree-sitter/tree-sitter-css
html        tree-sitter/tree-sitter-html
json        tree-sitter/tree-sitter-json
"

# --- helper: get the tree-sitter CLI ----------------------------------------
ensure_ts() {
    if command -v tree-sitter >/dev/null 2>&1; then
        TSCLI="$(command -v tree-sitter)"
        return
    fi
    if [ -x "$BIN_DIR/tree-sitter" ]; then
        TSCLI="$BIN_DIR/tree-sitter"
        return
    fi

    local os arch url
    case "$(uname -s)" in
        Linux*)  os="linux" ;;
        Darwin*) os="macos" ;;
        *) echo "Unsupported OS; install tree-sitter-cli yourself." >&2; exit 1 ;;
    esac
    case "$(uname -m)" in
        x86_64|amd64) arch="x64" ;;
        aarch64|arm64) arch="arm64" ;;
        *) echo "Unsupported arch; install tree-sitter-cli yourself." >&2; exit 1 ;;
    esac

    url="https://github.com/tree-sitter/tree-sitter/releases/download/${TS_VERSION}/tree-sitter-cli-${os}-${arch}.zip"
    local tmp
    tmp="$(mktemp -d)"
    echo "Downloading tree-sitter CLI ${TS_VERSION} ..."
    if command -v curl >/dev/null 2>&1; then
        curl -LfsS -o "$tmp/ts.zip" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$tmp/ts.zip" "$url"
    else
        echo "Need curl or wget to fetch the tree-sitter CLI." >&2; exit 1
    fi
    ( cd "$tmp" && unzip -o -q ts.zip )
    if [ -x "$tmp/tree-sitter" ]; then
        install -m755 "$tmp/tree-sitter" "$BIN_DIR/tree-sitter"
        rm -rf "$tmp"
    else
        rm -rf "$tmp"
        echo "Could not unpack prebuilt CLI; trying cargo instead ..." >&2
        command -v cargo >/dev/null 2>&1 || { echo "cargo unavailable." >&2; exit 1; }
        cargo install tree-sitter-cli --version "${TS_VERSION#v}"
        install -m755 "$HOME/.cargo/bin/tree-sitter" "$BIN_DIR/tree-sitter"
    fi
    TSCLI="$BIN_DIR/tree-sitter"
}

# --- build + install a single language --------------------------------------
build_one() {
    local lang="$1" repo="$2" subdir="$3"
    local clone_dir="$CACHE_DIR/$(basename "$repo")"

    if [ ! -d "$clone_dir/.git" ]; then
        echo "Cloning ${repo} ..."
        git clone --depth 1 "https://github.com/${repo}.git" "$clone_dir"
    elif [ "${REBUILD:-}" = "1" ]; then
        echo "Updating ${repo} ..."
        git -C "$clone_dir" pull --ff-only --depth 1
    fi

    local grammar="$clone_dir/${subdir:+$subdir}"
    local out="$PARSER_DIR/$lang.so"
    echo "Building ${lang} -> ${out}"
    "$TSCLI" build -o "$out" "$grammar"

    # Neovim ships query files for only its own languages. Deploy the grammar's
    # queries (markup like highlights/injections/locals) for this lang too.
    local qsrc="$clone_dir/queries"
    if [ -d "$qsrc" ]; then
        mkdir -p "$QUERY_DIR/$lang"
        cp -n "$qsrc"/*.scm "$QUERY_DIR/$lang/" 2>/dev/null || true
        echo "Deployed queries -> $QUERY_DIR/$lang/ ($(ls "$QUERY_DIR/$lang" 2>/dev/null | wc -l) files)"
    fi
}

ensure_ts

case "${1:-}" in
    --update) REBUILD=1; shift ;;
    all) shift || true ;;
esac

# No language given => install every grammar in the registry.
if [ "$#" -eq 0 ]; then
    # shellcheck disable=SC2013,SC2046
    set -- $(echo "$GRAMMARS" | awk 'NF {print $1}')
fi

built=0
for want in "$@"; do
    matched=0
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        set -- $line
        if [ "$1" = "$want" ]; then
            build_one "$1" "$2" "${3:-}"
            matched=1
            built=1
            break
        fi
    done <<<"$GRAMMARS"
    if [ "$matched" -eq 0 ]; then
        echo "Unknown language: $want (valid: $(echo "$GRAMMARS" | awk 'NF{printf "%s ", $1}'))" >&2
    fi
done

echo
echo "Done. Parsers (and queries) are staged under: $SITE_DIR"
echo "Restart nvim. Check with:     :checkhealth treesitter"
[ "$built" -eq 0 ] && exit 1
exit 0