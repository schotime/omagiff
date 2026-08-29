# omagiff — Omarchy theme integration for giff (https://github.com/bahdotsh/giff)
#
# This is an Omarchy user template. It is NOT read directly by giff.
# On every `omarchy theme set`, Omarchy renders it to
#   ~/.local/state/omarchy/current/theme/giff.toml
# and install.sh symlinks ~/.config/giff/config.toml at that path, so giff
# picks up the new palette the next time it launches.
#
# Regenerate by hand at any time with: omarchy-theme-refresh

theme = "omarchy"

[themes.omarchy]

# Follows the theme's own light/dark declaration, so unset keys fall back to
# giff's matching built-in defaults rather than fighting a light palette.
base = "{{ mode }}"

# ── Diff content ─────────────────────────────────────────────────────────
# Omarchy's red/green are tuned as *foreground* colors. Used raw as full-line
# backgrounds they overpower the text, so the row tint is a low blend into the
# theme background and the saturated color is kept for glyphs and markers.
fg_added         = "{{ green }}"
fg_removed       = "{{ red }}"
bg_added         = "{{ mix background green 14% }}"
bg_removed       = "{{ mix background red 14% }}"
# The bright_* slots are NOT reliably brighter than their base color — in
# osaka-jade bright_red (#db9f9c) is washed out next to red (#FF5345), and in
# matte-black it is darker. Blending toward bright_foreground instead keeps the
# hue while guaranteeing the marker lifts off its tinted row: measured across
# all 22 stock themes this never falls below 3.7:1, where raw green/red bottoms
# out at 2.6:1.
fg_added_marker  = "{{ mix green bright_foreground 40% }}"
fg_removed_marker = "{{ mix red bright_foreground 40% }}"

# Line numbers are drawn ON the tinted add/remove rows, so plain {{ muted }}
# disappears there (1.1:1 in miasma). This stays dim but never drops below 3:1.
fg_line_num      = "{{ mix muted foreground 65% }}"

# Accept/reject state is a deliberate user action, so it reads stronger than
# the passive add/remove tint above.
bg_accepted      = "{{ mix background green 24% }}"
bg_rejected      = "{{ mix background red 24% }}"

# ── Text ─────────────────────────────────────────────────────────────────
fg_normal        = "{{ foreground }}"
fg_bright        = "{{ bright_foreground }}"
# Also used as the background of the " i " badge, so it needs contrast against
# the background in both directions; dark_foreground fails that in the white
# theme (1.4:1).
fg_dim           = "{{ mix muted foreground 65% }}"

# fg_key is the BACKGROUND of key badges (giff draws fg_badge text on it), so
# it must contrast with the background. Every hue candidate collapses on the
# light themes — yellow hits 2.1:1 in rose-pine, and osaka-jade's yellow is
# green while matte-black's is red. bright_foreground is the only slot that
# never drops below 6.7:1, giving a reverse-video keycap that always reads.
fg_key           = "{{ bright_foreground }}"

# ── Chrome ───────────────────────────────────────────────────────────────
accent           = "{{ accent }}"
border_focused   = "{{ accent }}"
border_dim       = "{{ muted }}"
fg_separator     = "{{ mix background muted 55% }}"
bg_selection     = "{{ selection_background }}"

# Mixed against the foreground rather than pinned to a named surface color, so
# a raised surface stays raised in both light and dark themes.
bg_header        = "{{ mix background foreground 8% }}"
bg_key_badge     = "{{ mix background foreground 12% }}"
fg_badge         = "{{ background }}"

# ── Modals ───────────────────────────────────────────────────────────────
bg_modal         = "{{ mix background foreground 6% }}"
bg_modal_dim     = "{{ darker_background }}"
border_modal     = "{{ accent }}"

# ── Syntax highlighting ──────────────────────────────────────────────────
# giff uses syntect's built-in theme set, which is a fixed list of names — not
# hex colors — so this can only track the theme's mode, not its palette.
# Other valid values: base16-eighties.dark, base16-mocha.dark, InspiredGitHub,
# "Solarized (dark)", "Solarized (light)".
syntax_theme     = "base16-ocean.{{ mode }}"

# bg_default is deliberately left unset. giff then uses the terminal's default
# background, so Alacritty's own Omarchy colors — and its opacity/blur — show
# through instead of being painted over with an opaque rectangle.
# Uncomment for a hard background:
# bg_default     = "{{ background }}"
