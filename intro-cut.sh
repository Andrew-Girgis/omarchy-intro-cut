#!/bin/bash
# Helper for the Intro Cut widget: keeps the bundled mpv script linked into
# mpv and lists the current theme's backgrounds that have an intro clip.
#
#   intro-cut.sh status   link the mpv script, then print the theme's intros as JSON

set -euo pipefail

plugin_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
state_dir="$HOME/.local/state/omarchy"
mpv_scripts="${XDG_CONFIG_HOME:-$HOME/.config}/mpv/scripts"
image_extensions=(jpg jpeg png bmp webp)
# Matches omarchy-theme-bg-boot-intro, which decides what actually plays.
video_extensions=(mp4 m4v mov webm mkv avi)
max_intros=200

# Never replaces a regular file: that is someone's own copy of the script.
link_mpv_script() {
  local source="$plugin_dir/mpv/intro-cut.lua"
  local target="$mpv_scripts/intro-cut.lua"

  command -v mpv >/dev/null 2>&1 || { echo "no-mpv"; return; }
  if [[ -L $target ]]; then
    [[ $(readlink "$target") == "$source" ]] || ln -sfn "$source" "$target"
  elif [[ -e $target ]]; then
    echo "conflict"
    return
  else
    mkdir -p "$mpv_scripts"
    ln -s "$source" "$target"
  fi
  echo "linked"
}

intro_for() {
  local still="$1" stem extension
  stem=${still##*/}
  stem=${stem%.*}
  for extension in "${video_extensions[@]}"; do
    if [[ -f ${still%/*}/intros/$stem.$extension ]]; then
      printf '%s\n' "${still%/*}/intros/$stem.$extension"
      return 0
    fi
  done
  return 1
}

list_intros() {
  local theme="$1" current dir still intro duration count=0
  local -a dirs=() names=()

  current=$(readlink -f "$state_dir/current/background" 2>/dev/null || true)
  # User backgrounds first: that is where this plugin's exports land.
  [[ -n $theme ]] && dirs+=("$HOME/.config/omarchy/backgrounds/$theme")
  dirs+=("$state_dir/current/theme/backgrounds")

  for dir in "${dirs[@]}"; do
    [[ -d $dir ]] || continue
    for extension in "${image_extensions[@]}"; do names+=(-o -iname "*.$extension"); done
    while IFS= read -r -d '' still; do
      intro=$(intro_for "$still") || continue
      (( count++ < max_intros )) || break 2
      duration=$(timeout 5 ffprobe -v error -show_entries format=duration -of csv=p=0 "$intro" 2>/dev/null || true)
      jq -cn --arg still "$still" --arg intro "$intro" --arg duration "$duration" \
        --argjson user "$([[ $dir == "$HOME/.config/"* ]] && echo true || echo false)" \
        --argjson current "$([[ $(readlink -f "$still") == "$current" ]] && echo true || echo false)" \
        '{still: $still, intro: $intro, name: ($still | split("/") | last | sub("\\.[^.]*$"; "")),
          duration: ($duration | tonumber? // null), user: $user, current: $current}'
    done < <(find -L "$dir" -maxdepth 1 -type f \( "${names[@]:1}" \) -print0 2>/dev/null | sort -z)
    names=()
  done
}

status() {
  local theme mpv
  theme=$(cat "$state_dir/current/theme.name" 2>/dev/null || true)
  [[ $theme =~ ^[A-Za-z0-9._-]+$ && $theme != .* ]] || theme=""
  mpv=$(link_mpv_script)

  list_intros "$theme" | jq -cs --arg theme "$theme" --arg mpv "$mpv" \
    --arg exportDir "${theme:+$HOME/.config/omarchy/backgrounds/$theme}" \
    --argjson enabled "$([[ -f $state_dir/toggles/background-intros-off ]] && echo false || echo true)" \
    '{theme: $theme, mpv: $mpv, exportDir: $exportDir, introsEnabled: $enabled, intros: .}'
}

case ${1:-} in
  status) status ;;
  *)
    echo "Usage: intro-cut.sh status" >&2
    exit 1
    ;;
esac
