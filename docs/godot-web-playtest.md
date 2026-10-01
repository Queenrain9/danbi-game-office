# Godot Web playback in the playtest showroom

GitHub Pages deploys the dashboard and Godot Web exports in one artifact. Open
`https://queenrain9.github.io/danbi-game-office/#review`, click a game card in the
searchable library, and click **웹에서 플레이** in its detail dialog. Playback
switches to a dedicated viewport-filling player without nested detail/card
frames or loading instructions; **종료** returns to art previews, and clicking
play again restarts. **새 탭으로 열기** opens the same source build separately.
Closing the dialog or changing rooms unloads the player. Polling preserves the
running game and unsent notes. A/B/C thumbnails show the full image; click a
thumbnail to open the separate art viewer with its description and previous/next
controls. Image viewing and art selection are separate actions. Build metadata
and verdict entry are collapsed until requested. Completed decisions stay in the
library, with status filters and 24 games per page; availability still depends on
the records supplied by the existing sync endpoint (currently fetched up to 100).

## Source and routes

- Canonical source remains `builds/<slug>/`; archived `projects/.../build/godot`
  mirrors are not used.
- The Pages workflow reads the existing public `danbi-game-office-sync` endpoint,
  `view=playtest_showcase`, selecting `ready` showcases and `playtest_ready` builds.
- Committed `projects/<slug>/playtest/showcase.json` records with `status: ready`,
  `project_path`, and `final_commit` are also export candidates, including during
  sync outages. No DB status or art generation is changed.
- Only this repository, canonical `builds/<slug>` paths, and full commit SHAs are
  accepted. `git archive <final_commit> builds/<slug>` exports the recorded source
  version, even if newer work has changed main. Checkout fetches full history.
- `play/manifest.json` records success or failure, source commit, and URL. The UI
  matches canonical path **and exact source commit**, not the DB slug or title
  (the SHOWROOM TEST fixture has a different DB slug).
- Actual artifacts: `play/<slug>/<source-commit>/index.html`, `index.js`,
  `index.wasm`, `index.pck`, icons and audio worklets. These are generated in CI,
  not committed. Keeping each export together avoids renaming/runtime errors.
- Stable entry: `play/<slug>/index.html` redirects to an exported pinned version.
  The showroom uses the pinned URL. Versions remain deployed while eligible live
  or committed records reference them; this is not permanent historical storage.

Example stable URL:
`https://queenrain9.github.io/danbi-game-office/play/clockwork-pet-dentist/index.html`

## Pages compatibility and failure behavior

Godot 4.7.2 and its matching templates are pinned. The shared Web preset disables
threads, extensions, PWA and COI service workers. A temporary project copy adds
a Web Compatibility rendering override. Canonical game files and fidelity
identities are unchanged. This works with standard Pages HTTPS and WebGL 2.0,
without COOP/COEP headers or SharedArrayBuffer. Desktop texture compression is
enabled; mobile VRAM compression is disabled to avoid imposing an ETC2 import
configuration on existing projects.

Per-game import/export errors are recorded as `failed`; partial artifacts are
removed and the dashboard still deploys. The UI shows an unavailable message and
keeps the source link. Export success means files exist, not gameplay QA approval.
The first Clockwork WebAssembly payload is about 40 MB uncompressed; first loads
may take time. C#/GDExtension and threaded games need a separate hosting/export
strategy. Browser audio requires user interaction; save persistence and mobile
browser performance depend on the browser.

## Rebuild and verify

Push main or run **Deploy to GitHub Pages** with `workflow_dispatch` after a
DB-only readiness change. DB polling alone does not build static Web artifacts.
The deployment creates `_site` from tracked source, then adds `_site/play`, so
Godot executables/templates/download caches are never uploaded as site content.

For local verification with matching export templates installed:

```sh
python tools/web/export.py --godot /path/to/godot
python -m http.server 5173
# http://127.0.0.1:5173/#review
python -m unittest discover -s tests -v
node --test tests/web-player.test.cjs
```

`--payload file.json` accepts an offline sync response for reproducible exports;
`--output directory` changes the output directory. Web tests cover readiness,
canonical/foreign paths, pinning, fixture slug differences and failed/stale URLs.
Runtime verification should load the real iframe without COI, click a game
control, and check that A/B/C choice or showroom refresh does not reset it.
