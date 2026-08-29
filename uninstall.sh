#!/bin/bash
# omagiff — remove the Omarchy theme integration for giff.

set -euo pipefail

TEMPLATE_DST="$HOME/.config/omarchy/themed/giff.toml.tpl"
GIFF_CONFIG="$HOME/.config/giff/config.toml"

[[ -e $TEMPLATE_DST ]] && rm -f "$TEMPLATE_DST" && echo "removed $TEMPLATE_DST"

# Only remove the config if it is our symlink; a real file there is the user's.
if [[ -L $GIFF_CONFIG ]]; then
  rm -f "$GIFF_CONFIG"
  echo "removed symlink $GIFF_CONFIG"
fi

for script in omagiff omagiff-run; do
  [[ -e $HOME/.local/bin/$script ]] && rm -f "$HOME/.local/bin/$script" && echo "removed $HOME/.local/bin/$script"
done

latest_backup=$(ls -1t "$GIFF_CONFIG".omagiff-backup.* 2>/dev/null | head -1 || true)
if [[ -n $latest_backup ]]; then
  mv "$latest_backup" "$GIFF_CONFIG"
  echo "restored $latest_backup -> $GIFF_CONFIG"
fi

command -v omarchy-theme-refresh >/dev/null 2>&1 && omarchy-theme-refresh
echo "done."
