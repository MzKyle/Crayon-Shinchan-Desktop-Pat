#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${GODOT_VERSION:-4.6.3-stable}"
TEMPLATE_VERSION="${VERSION/-stable/.stable}"
TOOLS_DIR="$ROOT_DIR/tools/godot"
ARCHIVE="$TOOLS_DIR/Godot_v${VERSION}_export_templates.tpz"
URL="https://github.com/godotengine/godot/releases/download/${VERSION}/Godot_v${VERSION}_export_templates.tpz"
INSTALL_DIR="${GODOT_EXPORT_TEMPLATE_DIR:-$HOME/.local/share/godot/export_templates/$TEMPLATE_VERSION}"

has_templates() {
  [[ -f "$INSTALL_DIR/linux_debug.x86_64" && -f "$INSTALL_DIR/linux_release.x86_64" ]]
}

download_templates() {
  mkdir -p "$TOOLS_DIR"
  if [[ -f "$ARCHIVE" ]]; then
    return
  fi

  echo "Downloading Godot export templates $VERSION."
  echo "This file is large; it may take a while."
  if command -v curl >/dev/null 2>&1; then
    curl -L --fail --progress-bar "$URL" -o "$ARCHIVE"
  elif command -v wget >/dev/null 2>&1; then
    wget "$URL" -O "$ARCHIVE"
  else
    echo "curl or wget is required to download Godot export templates." >&2
    exit 1
  fi
}

install_templates() {
  if ! command -v unzip >/dev/null 2>&1; then
    echo "unzip is required to extract Godot export templates." >&2
    exit 1
  fi

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT

  unzip -o "$ARCHIVE" -d "$tmp_dir" >/dev/null
  mkdir -p "$INSTALL_DIR"

  local name src
  for name in linux_debug.x86_64 linux_release.x86_64; do
    src="$(find "$tmp_dir" -type f -name "$name" | head -n 1)"
    if [[ -z "$src" ]]; then
      echo "Template $name was not found in $ARCHIVE" >&2
      exit 1
    fi
    cp "$src" "$INSTALL_DIR/$name"
    chmod +x "$INSTALL_DIR/$name"
  done
}

if has_templates; then
  echo "Godot export templates already installed: $INSTALL_DIR"
  exit 0
fi

download_templates
install_templates

echo "Installed Godot export templates: $INSTALL_DIR"
