#!/usr/bin/env bash
#MISE description="Install the fonts in fonts/"
#MISE wait_for=["deps"]
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib/os.sh"

mac_font_dir() { echo ~/Library/Fonts; }
linux_font_dir() { echo "${XDG_DATA_HOME:-$HOME/.local/share}/fonts"; }

dir=$(for_os font_dir)
mkdir -p "$dir"
cp -v "$MISE_CONFIG_ROOT"/fonts/*.ttf "$dir/"
if command -v fc-cache >/dev/null; then fc-cache -f "$dir"; fi
