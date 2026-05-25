#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSET_DIR="$ROOT_DIR/assets/effects"
GAME_DIR="$ROOT_DIR/assets/games"
BASE_URL="https://raw.githubusercontent.com/googlefonts/noto-emoji/main/png/128"

mkdir -p "$ASSET_DIR" "$GAME_DIR"

download() {
  local name="$1"
  local file="$2"
  local directory="${3:-$ASSET_DIR}"
  curl -fsSL "$BASE_URL/$file" -o "$directory/$name.png"
}

download heart emoji_u1f496.png
download sparkle emoji_u2728.png
download rice_ball emoji_u1f359.png
download ball emoji_u26bd.png
download sleep emoji_u1f4a4.png
download wave emoji_u1f44b.png
download target emoji_u1f3af.png
download trophy emoji_u1f3c6.png
download stopwatch emoji_u23f1.png
download cookie emoji_u1f36a.png

download rice_ball emoji_u1f359.png "$GAME_DIR"
download ball emoji_u26bd.png "$GAME_DIR"
download target emoji_u1f3af.png "$GAME_DIR"
download trophy emoji_u1f3c6.png "$GAME_DIR"
download stopwatch emoji_u23f1.png "$GAME_DIR"
download cookie emoji_u1f36a.png "$GAME_DIR"

echo "Downloaded effect assets into $ASSET_DIR and game assets into $GAME_DIR"
