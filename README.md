# Hammerspoon Workspace Manager

A powerful dual-monitor window management system for macOS built with [Hammerspoon](https://www.hammerspoon.org/). Designed for a two-monitor setup but gracefully handles single-monitor use.

## Features

### Layout Hotkeys
| Key | Action |
|-----|--------|
| `F1` | **AI Layout** — ½ + ¼ + ¼ on left monitor, 4 equal columns on right |
| `F2` | **Even Split** — each monitor divides itself evenly by however many windows are on it |
| `F3` | **Focus Split** — ⅔ main window + remaining share the ⅓ |
| `F4` | **Tag Mode** — click windows to number them (double-click to remove a tag) |
| `F5` | **Layout Palette** — floating panel with visual layout previews |
| `F6` | **Reset Tags** — clear all window tags instantly |

### Window Tagging System
- Press **F4** to enter tag mode
- **Click** any window to assign it the next number — a colored badge appears in the top-left
- **Double-click** a tagged window to remove its tag (remaining tags resequence automatically)
- Press **F4** again to exit tag mode (badges stay visible)
- Press **F6** to clear all tags

### Layout Palette (F5)
A floating dark-mode panel showing clickable layout previews with mini dual-monitor diagrams. Tag your windows first, then pick a layout — windows snap into position in tag order.

**Available layouts:**
- AI Layout — ½ · ¼ · ¼ | 4 equal
- Even Split — equal columns per monitor
- Focus Split — ⅔ main · ⅓ shared
- LG Full · Mi Split — 1 full left, rest on right
- Stack · 3 Right — 2 stacked + sidebar | 3 columns
- Quarters — 4 equal on each monitor

The palette is draggable by the header bar and positioned bottom-right by default.

### Slot Hotkeys
| Key | Action |
|-----|--------|
| `Ctrl+Alt+1–5` | Move focused window to slot 1–5 |
| `Ctrl+Alt+6` | Left 50% of current monitor |
| `Ctrl+Alt+7` | Right 50% of current monitor |
| `Ctrl+Alt+8` | Left 2/3 of current monitor |
| `Ctrl+Alt+L` | Full screen on left monitor |
| `Ctrl+Alt+R` | Full screen on right monitor |
| `Ctrl+Alt+M` | Minimize focused window |
| `Ctrl+Alt+N` | Focus next window |
| `Ctrl+Alt+S` | Swap two slot locations |

### Preset Layouts
Edit `config.lua` to define named presets. Each preset assigns apps to slots 1–5. Presets appear in the menubar icon (⊞).

**Slot positions:**
- Slot 1 = Left monitor, left 2/3
- Slot 2 = Left monitor, right 1/3
- Slot 3 = Right monitor, left 1/3
- Slot 4 = Right monitor, center 1/3
- Slot 5 = Right monitor, right 1/3

## Setup

### Requirements
- macOS 12+
- [Hammerspoon](https://www.hammerspoon.org/) installed

### Install

```bash
# Back up your existing config
cp -r ~/.hammerspoon ~/.hammerspoon.backup

# Clone into your Hammerspoon config directory
git clone https://github.com/YOUR_USERNAME/hammerspoon-workspace.git ~/.hammerspoon
```

Then open Hammerspoon and click **Reload Config**.

### Customize for your monitors

In `init.lua`, find `getLG()` and `getMi()` and update the screen name strings to match your monitor names. You can find your monitor names by running this in the Hammerspoon console:

```lua
for _, s in ipairs(hs.screen.allScreens()) do print(s:name(), s:fullFrame()) end
```

The AI layout uses hardcoded pixel coords for the two-monitor setup. Update the `S` table in `applyAILayout()` to match your resolution.

### Customize presets

Edit `config.lua` — add, remove, or rename presets. Each slot takes an app name exactly as it appears in `/Applications`.

```lua
{
    name = "Daily",
    slots = {
        [1] = "Google Chrome",
        [2] = "Spotify",
        [3] = "Slack",
        [4] = "Terminal",
        [5] = "Microsoft Outlook",
    }
},
```

## File Structure

```
init.lua            — Main config: hotkeys, screen detection, slot system, AI layout
config.lua          — User-editable preset definitions
window_tags.lua     — Window tagging system with floating badge overlays
layout_palette.lua  — Floating layout picker (webview-based, draggable)
```

## License

MIT
