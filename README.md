# omagiff

Makes [giff](https://github.com/bahdotsh/giff) — a terminal git diff viewer with a
file list pane and side-by-side comparison — follow your active Omarchy theme.

No fork, no patch. giff already exposes all 26 of its colors as hex overrides;
this is an Omarchy template that fills them in from `colors.toml` on every
theme switch.

## Install

```bash
cargo install giff        # if you don't have it
./install.sh
```

`install.sh` drops the template in `~/.config/omarchy/themed/`, points
`~/.config/giff/config.toml` at the generated file, and renders your current
theme immediately. `./uninstall.sh` reverses all of it and restores any config
you had before.

Note: `cargo install` puts giff in `~/.cargo/bin`, which is not on Omarchy's
default PATH. Add it if `giff` isn't found.

## How it works

1. `~/.config/omarchy/themed/giff.toml.tpl` is an Omarchy **user template**.
   User templates take priority over built-ins and are rendered on every
   `omarchy theme set`.
2. Omarchy writes the result to
   `~/.local/state/omarchy/current/theme/giff.toml`.
3. `~/.config/giff/config.toml` is a symlink to that path. The path is stable
   across theme switches — `omarchy-theme-set` replaces the directory
   contents, not the directory name — and giff re-reads its config on every
   launch, so the next `giff` is themed.

Nothing runs in the background and there is no hook. `{{ mode }}` is exposed by
the template engine, so `base` and `syntax_theme` track light/dark without one.

## Its own window

`giff` opens in its own window instead of taking over the terminal you ran it
from, so `q` or `SUPER + W` closes just that window. The shape follows the
layout of the workspace it lands on:

| workspace layout | result |
|---|---|
| `scrolling` | tiled, resized to a full-width column |
| anything else | centred float at 90% of the monitor |

Two pieces:

- **`bin/omagiff-run`** — what the window actually runs. Carries the
  `diff.mnemonicPrefix` fix, picks a sensible default revision, and waits for
  the terminal grid to settle before starting giff. Run it directly to get giff
  inline in the current terminal instead.
- **`bin/omagiff`** — detects the layout, applies the matching window
  rule, then hands off to `omarchy-launch-tui` under app-id `TUI.giff`.
  `omarchy-launch-tui` provides the detachment (`setsid uwsm-app --
  xdg-terminal-exec`) and preserves the working directory, so giff opens on the
  repo you launched it from. It also discards the launched terminal's output:
  the detached window inherits the launching shell's stdout and stderr, so
  foot's startup chatter (`compositor does not implement the xdg-toplevel-icon
  protocol`) would otherwise print into your prompt. Missing prerequisites are
  checked before that redirect, so real failures still report.

`install.sh` installs both into `~/.local/bin`, which Omarchy already puts on
PATH (`default/bash/envs`) and which is in the systemd user PATH too. So there
is nothing to add to `~/.bashrc` and no Hyprland config to edit — the window
rule is created per launch.

### Forcing a shape

Detection can be overridden per launch. The flag is consumed by the launcher;
everything after it goes to giff untouched.

```bash
omagiff --float          # centred float at 90%, even on a scrolling workspace
omagiff --tile           # full-width tiled column, even on a dwindle workspace
omagiff --wide           # same as --tile
omagiff --auto           # follow the workspace layout (the default)
omagiff --float HEAD~1   # flags combine with giff's own arguments
```

### What it diffs by default

giff with no revision runs a plain `git diff` — **unstaged tracked changes
only**. In a terminal that prints `No changes.`; in a floating window it looks
like the window failed to open, because it flashes shut. Two common states hit
this:

- everything is **staged** (`git add`ed but not committed)
- the only changes are **untracked** files (starship shows these as `?`)

So `omagiff-run` passes `HEAD` when you give it no revision, which covers staged and
unstaged together — what "show me my changes" usually means. giff labels the
panes `HEAD → Working Tree` either way, so nothing looks different. Pass your own
refs (`giff main`, `giff main feature`) and they are used untouched.

When there is genuinely nothing to show, it prints why — naming untracked files
if that is the reason — and holds the window open instead of flashing.

### Why it is built this way

**Window-rule sizes are pixels, not percentages.** `size = { "90%", "90%" }`
parses without error and is then silently ignored — the window stays at the
terminal's default. So 90% is computed against the focused monitor's *logical*
size (physical / scale) and applied before the window maps, via `hyprctl eval`.
That is the same trick `omarchy-launch-about` uses to presize itself, and
recomputing it per launch keeps it right across monitors with different
resolutions or scales.

**The scrolling layout has no window rule for column width.** Only the
`colresize` layoutmsg, which acts on whichever column holds focus. So the
full-width case is applied after the fact: a short background loop waits until
the focused window is `TUI.giff`, then sends `colresize 1.0`. Waiting for focus
rather than for the window to merely exist is what keeps it from widening the
column you were already on.

**The rule is created per launch rather than kept in `hyprland.lua`.** A static
`float` rule would have to be fought by the scrolling case; one rule built fresh
each time, replacing the last, means there is a single source of truth and a
float rule never outlives the workspace it was made for.

**giff must not start before the window is sized.** Hyprland maps the window at
the terminal's default (80x24 for foot) and applies the size rule immediately
after. giff draws its first frame and then blocks in `event::read()`
(`src/ui/event_loop.rs:109`), so it would sit showing an 80-column layout in a
127-column window until the next key or mouse event woke it up. `omagiff-run` polls
`stty size` until it stops changing before exec'ing giff, so the first frame is
already the right size.

## Known issue: giff reports "No changes." on Omarchy

Omarchy sets `diff.mnemonicPrefix = true` globally in
`/usr/share/omarchy/config/git/config`. That makes `git diff` label paths with
`i/` (index) and `w/` (working tree) instead of the usual `a/` and `b/`:

```
diff --git i/src/Foo.cs w/src/Foo.cs
```

giff's parser hardcodes `^diff --git a/(.+) b/(.+)$` (`src/diff.rs:9`), so it
matches nothing, finds no files, and prints `No changes.` in every repo — even
one with uncommitted work. **This affects every Omarchy user**, independent of
theming.

The fix is to override the setting for giff's git calls only, via git's
environment-variable config, leaving normal `git diff` output untouched:

```bash
giff() {
  GIT_CONFIG_COUNT=1 \
  GIT_CONFIG_KEY_0=diff.mnemonicPrefix \
  GIT_CONFIG_VALUE_0=false \
  command giff "$@"
}
```

`install.sh` does **not** add this — it doesn't touch your shell config. Add it
to `~/.bashrc` yourself if you want it.

`--diff-args='--src-prefix=a/ --dst-prefix=b/'` also works, but giff derives its
pane labels from that string, so the left pane ends up captioned with the raw
flags.

The real fix belongs upstream: a tool that parses `git diff` output should pin
the prefixes on its own invocation rather than inherit user config. That would
also cover `diff.noprefix` and custom `diff.srcPrefix`/`dstPrefix`.

## Color choices

Most keys map straight across. Four don't, and the reasons are worth recording
because they're properties of the Omarchy palette, not of any one theme:

| Key | Mapping | Why |
|---|---|---|
| `bg_added` / `bg_removed` | `mix background {green,red} 14%` | Omarchy's red/green are tuned as *foreground* colors. Used raw as full-line backgrounds they overpower the code. |
| `fg_*_marker` | `mix {green,red} bright_foreground 40%` | The `bright_*` slots are not reliably brighter — osaka-jade's `bright_red` is washed out vs `red`, matte-black's is darker. Raw green/red bottoms out at 2.6:1 on its own tinted row; this holds ≥3.7:1. |
| `fg_line_num`, `fg_dim` | `mix muted foreground 65%` | Line numbers are drawn *on* the tinted rows, where plain `muted` hits 1.1:1 in miasma. `dark_foreground` fails the other way (1.4:1 in `white`). |
| `fg_key` | `bright_foreground` | giff uses `fg_key` as the *background* of key badges. Every hue candidate collapses on light themes (`yellow` → 2.1:1 in rose-pine), and `yellow` isn't even yellow in every theme — it's green in osaka-jade, red in matte-black. |

`bg_default` is deliberately left unset so giff uses the terminal's default
background, letting your terminal's own Omarchy colors and its opacity/blur
show through rather than painting over them.

`syntax_theme` can only track `mode`, not the palette — giff uses syntect's
fixed built-in theme set, which is names rather than colors.

## Verified against

All 22 stock Omarchy themes render with every token resolved and every value a
valid `#RRGGBB`, including the light ones (`catppuccin-latte`, `flexoki-light`,
`rose-pine`, `solitude`, `white`) and the extremes (`vantablack`, `hackerman`).
