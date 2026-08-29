# omagiff

Omarchy integration for [giff](https://github.com/bahdotsh/giff), a terminal git
diff viewer with a file list pane and side-by-side comparison.

It does three things:

- **Themes it.** giff follows your active Omarchy theme, and re-themes itself
  whenever you switch.
- **Gives it a window.** `omagiff` opens giff in its own window, shaped to the
  workspace layout, so `q` or `SUPER + W` closes just that window and not the
  terminal you launched it from.
- **Fixes it.** Omarchy's global git settings otherwise make giff report
  "No changes." in every repository.

No fork and no patch — giff is used through its own config file and CLI, so
`cargo install giff` keeps working and updates never need rebasing.

## Install

```bash
cargo install giff
git clone https://github.com/schotime/omagiff && cd omagiff
./install.sh
```

That installs two scripts to `~/.local/bin`, a theme template to
`~/.config/omarchy/themed/`, and points `~/.config/giff/config.toml` at the
generated palette. Nothing is added to your shell config and no Hyprland config
is edited. `./uninstall.sh` reverses all of it.

## Use

```bash
omagiff                  # open giff in its own window
omagiff --float          # force a centred float at 90% of the monitor
omagiff --tile           # force a full-width tiled column  (--wide is an alias)
omagiff --auto           # follow the workspace layout (the default)
omagiff --float HEAD~1   # flags combine with giff's own arguments

omagiff-run              # giff inline in the current terminal
```

With no flag the window follows the layout of the workspace it lands on: a
full-width tiled column under the `scrolling` layout, otherwise a centred float
at 90% of the monitor.

With no revision, giff diffs unstaged tracked changes only, which reports
"No changes." when everything is staged. `omagiff` passes `HEAD` instead, so
staged and unstaged both show. Give it your own refs and they are used as-is.

## How it works

**Theming.** `themed/giff.toml.tpl` is an Omarchy user template. Omarchy renders
it to `~/.local/state/omarchy/current/theme/giff.toml` on every theme switch,
filling in giff's 26 color keys from the theme's `colors.toml`.
`~/.config/giff/config.toml` is a symlink to that file, and giff re-reads its
config on every launch, so the next `omagiff` is themed. Nothing runs in the
background.

**The window.** `omagiff` detects the workspace layout, applies a matching
Hyprland window rule for app-id `TUI.giff`, then hands off to
`omarchy-launch-tui`, which detaches the process and preserves the working
directory so giff opens on the repo you launched it from. The window runs
`omagiff-run`, which is also usable on its own.

## Compatibility notes

Three things about giff on Omarchy that this works around:

- Omarchy sets `diff.mnemonicPrefix = true` globally, so `git diff` labels paths
  `i/` and `w/`. giff's parser only matches `a/` and `b/`, so it finds no files
  and reports "No changes." in every repository. `omagiff-run` overrides the
  setting for giff's own git calls, leaving normal `git diff` untouched.
- Hyprland maps the window at the terminal's default size and resizes it
  immediately after, but giff draws its first frame and then blocks on input, so
  it would show an 80-column layout in a full-width window until the next
  keypress. `omagiff-run` waits for the terminal size to settle before starting
  giff.
- The default revision, as above.

The first two are upstream bugs rather than configuration problems.

## Requires

Omarchy, Hyprland, `jq`, and giff. Tested against all 22 stock Omarchy themes,
light and dark.
