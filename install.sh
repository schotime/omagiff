#!/bin/bash
# omagiff — install the Omarchy theme integration for giff.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_SRC="$REPO_DIR/themed/giff.toml.tpl"
TEMPLATE_DST="$HOME/.config/omarchy/themed/giff.toml.tpl"
GENERATED="$HOME/.local/state/omarchy/current/theme/giff.toml"
GIFF_CONFIG="$HOME/.config/giff/config.toml"

if ! command -v omarchy-theme-refresh >/dev/null 2>&1; then
  echo "error: omarchy not found on PATH. omagiff only works on Omarchy." >&2
  exit 1
fi

if ! command -v giff >/dev/null 2>&1; then
  echo "warning: giff is not installed. Install it with: cargo install giff"
fi

# Launcher scripts. Kept on PATH rather than called by absolute path so the
# Hyprland rule, the shell function, and manual runs all reach the same copy.
mkdir -p "$HOME/.local/bin"
for script in omagiff omagiff-run; do
  install -m 755 "$REPO_DIR/bin/$script" "$HOME/.local/bin/$script"
  echo "installed script    -> $HOME/.local/bin/$script"
done

mkdir -p "$(dirname "$TEMPLATE_DST")" "$(dirname "$GIFF_CONFIG")"
install -m 644 "$TEMPLATE_SRC" "$TEMPLATE_DST"
echo "installed template  -> $TEMPLATE_DST"

# giff's config.toml holds nothing but theme selection today, so handing the
# whole file over to Omarchy is safe. Anything already there is still the
# user's, so it is moved aside rather than clobbered.
if [[ -e $GIFF_CONFIG || -L $GIFF_CONFIG ]]; then
  if [[ -L $GIFF_CONFIG && $(readlink -f "$GIFF_CONFIG") == "$(readlink -f "$GENERATED" 2>/dev/null)" ]]; then
    : # already ours
  else
    backup="$GIFF_CONFIG.omagiff-backup.$(date +%Y%m%d%H%M%S)"
    mv "$GIFF_CONFIG" "$backup"
    echo "backed up existing config -> $backup"
  fi
fi

ln -sfn "$GENERATED" "$GIFF_CONFIG"
echo "linked config       -> $GIFF_CONFIG -> $GENERATED"

# The template only renders during a theme set, so render the current theme now.
echo "rendering current theme..."
omarchy-theme-refresh

if [[ -f $GENERATED ]]; then
  echo "done. giff now follows $(omarchy-theme-current 2>/dev/null || echo 'your Omarchy theme')."
else
  echo "error: $GENERATED was not generated. Check 'omarchy-theme-refresh' output." >&2
  exit 1
fi
