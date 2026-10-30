# Intro Cut for Omarchy

An Omarchy shell bar widget for making and previewing background intros: the
short clip that plays at login or when you switch to a theme, then settles
on its wallpaper. Plugin ID: `girgie.intro-cut`.

## Requirements

- Omarchy 4.5 or newer (background intros arrived in 4.5).
- `mpv`, `ffmpeg` and `jq` (`sudo pacman -S --needed mpv ffmpeg jq`). `owe`, which plays
  the intros, ships with Omarchy.

## Install

```sh
omarchy plugin add https://github.com/Andrew-Girgis/omarchy-intro-cut --enable
omarchy theme bg intro enable     # if intros aren't on yet
```

Update with `omarchy plugin update girgie.intro-cut`; remove with
`omarchy plugin remove girgie.intro-cut` (then delete `~/.config/mpv/scripts/intro-cut.lua`
if you no longer want the mpv keys).

### Ask an agent to install it

> Install the Omarchy bar widget from https://github.com/Andrew-Girgis/omarchy-intro-cut
> with `omarchy plugin add <url> --enable`. Make sure mpv, ffmpeg and jq are installed and
> that background intros are enabled (`omarchy theme bg intro enable`). Then run
> `~/.config/omarchy/plugins/girgie.intro-cut/intro-cut.sh status` and tell me what it reports.

## Cutting an intro

The plugin ships an mpv script and links it to `~/.config/mpv/scripts/intro-cut.lua`
when the shell loads the plugin. It never replaces a regular file of that name.

1. Open a video in mpv. **Open mpv**, **M** in the panel, or right-clicking the
   bar icon opens an empty mpv window you can drop a file into.
2. Press **l** to mark the start, then **l** again to mark the end (mpv's A-B loop).
3. Press **Shift+X**. Without marks it takes 6 seconds from the current position.

ffmpeg cuts a silent H.264 clip, at most 2560 px wide, then decodes the last
frame *of that clip* as the still, so the intro lands exactly on its wallpaper.
Both go into the current theme's user backgrounds:

```
~/.config/omarchy/backgrounds/<theme>/<name>.png
~/.config/omarchy/backgrounds/<theme>/intros/<name>.mp4
```

Omarchy already includes that directory in the theme's background rotation, and it
plays `intros/<stem>.mp4` for any still with a matching name. Files are
written as hidden `.part` files inside `intros/` and renamed into place,
so a half-written export never appears as a wallpaper. Without a current
theme, exports go to `~/Pictures/Intros`. Omarchy suggests clips of 5–7 seconds.

## The panel

Click the bar icon to list the current theme's backgrounds that have an intro,
both the theme's own and your exports (**Yours**). The wallpaper you're on now is
outlined and marked **Current**.

- **Preview** closes the panel and plays the intro now (`owe intro --start first-frame`).
- **Use** makes the still the wallpaper (`omarchy theme bg set`).

**R** refreshes, **M** opens mpv, **Esc** closes.

## When intros play

Omarchy plays an intro only **at login** or when **switching to a different
theme**. Cycling wallpapers within a theme never plays one. On a theme switch,
Omarchy restores the wallpaper you last used in that theme, so leave a theme on
an intro-backed wallpaper if you want its intro next time. Intros also need
Hyprland animations on and `omarchy theme bg intro enable`.

## Development

```sh
node --test tests/model.test.cjs
tests/helper.test.sh
omarchy plugin validate .
```

See [CONTRIBUTING.md](CONTRIBUTING.md). MIT licence, see [LICENSE](LICENSE).
