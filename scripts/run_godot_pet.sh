#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN_PATH=""

if GODOT_BIN_PATH="$("$ROOT_DIR/scripts/setup_godot.sh" 2>/dev/null | tail -n 1)" && [[ -x "$GODOT_BIN_PATH" ]]; then
  export CRAYON_PET_ROOT="$ROOT_DIR"
  export CRAYON_PET_TRANSPARENT="${CRAYON_PET_TRANSPARENT:-1}"
  export CRAYON_PET_ALWAYS_ON_TOP="${CRAYON_PET_ALWAYS_ON_TOP:-1}"
  export CRAYON_PET_BORDERLESS="${CRAYON_PET_BORDERLESS:-1}"
  export CRAYON_PET_MOUSE_PASSTHROUGH="${CRAYON_PET_MOUSE_PASSTHROUGH:-1}"
  exec "$GODOT_BIN_PATH" --path "$ROOT_DIR/godot_pet" "$@"
fi

echo "Godot is not available." >&2
echo "Install or download it with: $ROOT_DIR/scripts/setup_godot.sh" >&2
exit 1
