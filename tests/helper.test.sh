#!/bin/bash
# Runs intro-cut.sh against a throwaway HOME and checks what it reports and links.
set -euo pipefail
unset XDG_CONFIG_HOME

helper="$(cd "$(dirname "$0")/.." && pwd)/intro-cut.sh"
home=$(mktemp -d)
trap 'rm -rf "$home"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }

state="$home/.local/state/omarchy"
theme_bg="$state/current/theme/backgrounds"
user_bg="$home/.config/omarchy/backgrounds/demo"
mkdir -p "$theme_bg/intros" "$user_bg/intros"
echo demo >"$state/current/theme.name"
touch "$theme_bg/plain.jpg" "$theme_bg/with-intro.jpg" "$theme_bg/intros/with-intro.mp4"
touch "$user_bg/<b>mine.png" "$user_bg/intros/<b>mine.webm" "$user_bg/intros/.mine.part.png"
ln -s "$theme_bg/with-intro.jpg" "$state/current/background"

out=$(HOME=$home "$helper" status)
[[ $(jq -r .theme <<<"$out") == demo ]] || fail "theme"
[[ $(jq -r .mpv <<<"$out") == linked || $(jq -r .mpv <<<"$out") == no-mpv ]] || fail "mpv status"
[[ $(jq -c '[.intros[].name]' <<<"$out") == '["<b>mine","with-intro"]' ]] || fail "intros: $(jq -c '[.intros[].name]' <<<"$out")"
[[ $(jq -c '[.intros[] | [.user, .current]]' <<<"$out") == '[[true,false],[false,true]]' ]] || fail "flags"

if command -v mpv >/dev/null; then
  [[ -L $home/.config/mpv/scripts/intro-cut.lua ]] || fail "mpv script not linked"
  # A user's own regular file is never replaced.
  rm "$home/.config/mpv/scripts/intro-cut.lua"
  echo "-- mine" >"$home/.config/mpv/scripts/intro-cut.lua"
  [[ $(HOME=$home "$helper" status | jq -r .mpv) == conflict ]] || fail "conflict"
  [[ $(cat "$home/.config/mpv/scripts/intro-cut.lua") == "-- mine" ]] || fail "overwrote user script"
fi

# Path-shaped theme names never become directories to scan.
echo "../../etc" >"$state/current/theme.name"
[[ $(HOME=$home "$helper" status | jq -r '.theme, .exportDir' | tr -d '\n') == "" ]] || fail "unsafe theme name"
echo "helper status, linking, and theme-name validation passed"
