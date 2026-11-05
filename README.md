# Load Graph

CPU and memory over the last minutes as small graphs: a desktop card with six minutes of both (one bar every 10 s), the
highest point and the load average, and a menu bar item with the last 30 seconds of CPU. Click it for memory and **Open Top**.

- **Asks for:** `run` (Run commands as you): `wol sys stats --json`, the same report the reference Stats plugin reads (a
  helper verb with Read access: no approval sheet), and `foot -e btop` when you press Open Top.
- Nothing is saved: the graphs start again when the shell starts.
- **Files:** `plugin.toml`, `bar.lua`, `card.lua` (medium or large), `icon.png`, `preview.webp`.

## Install

From the Store: **Plugins**, then **Get** on Load Graph. From a release: `wol plugin add wonderlandos.loadgraph-1.0.wolplug --yes` (a file the index did not sign is marked
unreviewed), then `wol plugin enable wonderlandos.loadgraph`.

## Tests

`.tests/case-*.json` are runs of the scripts in the WolOS plugin runtime (wol-lua, the shell's sandbox and Lua API) with
fixture answers for `wol.run`: nothing on the machine runs. Each case lists the steps (render, popover, click, change,
query) and the text the result must and must not contain; the runner (`plugtest`, wol-lua with fixture services) is
not published yet. `wol plugin check` on a copy of the folder named after the id is the lint.

## Release

`.github/workflows/hub-release.yml` turns a pushed tag `v<plugin.toml version>` (`v1.0`) into a GitHub release with
`wonderlandos.loadgraph-<version>.wolplug`, checked by the hub's own hubcheck first (wonderlandos/hub `wol-release.yml`, pinned).

Licence: GPL-2.0-or-later.
