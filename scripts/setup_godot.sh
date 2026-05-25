#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${GODOT_VERSION:-4.6.3-stable}"
TOOLS_DIR="$ROOT_DIR/tools/godot"
ARCHIVE="$TOOLS_DIR/Godot_v${VERSION}_linux.x86_64.zip"
URL="https://github.com/godotengine/godot/releases/download/${VERSION}/Godot_v${VERSION}_linux.x86_64.zip"

candidate_from_env() {
  if [[ -n "${GODOT_BIN:-}" && -x "${GODOT_BIN:-}" ]]; then
    printf '%s\n' "$GODOT_BIN"
    return 0
  fi
  return 1
}

candidate_from_path() {
  local bin
  for bin in godot4 godot; do
    if command -v "$bin" >/dev/null 2>&1; then
      command -v "$bin"
      return 0
    fi
  done
  return 1
}

candidate_from_tools() {
  local found
  found="$(find "$TOOLS_DIR" -maxdepth 1 -type f -name 'Godot_v*_linux.x86_64' -perm -111 2>/dev/null | sort -V | tail -n 1 || true)"
  if [[ -n "$found" ]]; then
    printf '%s\n' "$found"
    return 0
  fi
  return 1
}

download_godot() {
  mkdir -p "$TOOLS_DIR"
  if [[ ! -f "$ARCHIVE" ]]; then
    echo "Downloading Godot $VERSION..."
    if command -v curl >/dev/null 2>&1; then
      curl -L --fail --progress-bar "$URL" -o "$ARCHIVE"
    elif command -v wget >/dev/null 2>&1; then
      wget "$URL" -O "$ARCHIVE"
    else
      echo "curl or wget is required to download Godot." >&2
      exit 1
    fi
  fi

  if ! command -v unzip >/dev/null 2>&1; then
    echo "unzip is required to extract Godot." >&2
    exit 1
  fi

  unzip -o "$ARCHIVE" -d "$TOOLS_DIR" >/dev/null
  chmod +x "$TOOLS_DIR/Godot_v${VERSION}_linux.x86_64"
  printf '%s\n' "$TOOLS_DIR/Godot_v${VERSION}_linux.x86_64"
}

if candidate_from_env; then
  exit 0
fi

if candidate_from_path; then
  exit 0
fi

if candidate_from_tools; then
  exit 0
fi

download_godot
