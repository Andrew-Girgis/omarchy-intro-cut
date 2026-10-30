# Contributing

Thanks for helping. Issues and focused pull requests are welcome.

## Reporting a bug

Open an issue at https://github.com/Andrew-Girgis/omarchy-intro-cut/issues with your Omarchy version
(`omarchy version`), what you did, what you expected, and the output of
`omarchy-shell girgie.intro-cut status`. Leave out tokens, API keys and private paths.

## Working on the plugin

Clone the repo straight into your plugins folder so the shell hot-reloads your edits:

```sh
git clone https://github.com/Andrew-Girgis/omarchy-intro-cut ~/.config/omarchy/plugins/girgie.intro-cut
omarchy plugin enable girgie.intro-cut
```

Before opening a pull request, run:

```sh
node --test tests/model.test.cjs
tests/helper.test.sh
omarchy plugin validate .
```

## Guidelines

- Keep it dependency-free at runtime beyond mpv, ffmpeg, jq and what Omarchy ships.
- Render untrusted text as plain text (`PlainText.qml`, `Model.sharedText` for tooltips).
- Put user-facing strings in `i18n/en.json`.
- Bump `version` in `manifest.json` when behaviour changes.

By contributing you agree that your work is released under the [MIT licence](LICENSE).
