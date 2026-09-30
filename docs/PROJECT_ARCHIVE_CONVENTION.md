# Danbi Game Project Archive Convention v1

## Purpose

Every game has one durable, human-browsable GitHub project root:

`projects/<slug>/`

Supabase remains the operational database used by the website and scheduled pipeline to select work and track live status. GitHub is the durable project archive and source-code history. A completed production artifact must not exist only inside the database.

## Standard tree

```text
projects/<slug>/
├─ README.md
├─ manifest.json
├─ game-design/
├─ wireframe/
├─ implementation/
├─ build/
│  ├─ build-manifest.json
│  └─ godot/
├─ fidelity/
│  └─ evidence/
├─ playtest/
└─ visual/
```

Git does not preserve empty directories, so later-stage folders appear when their first artifact is written.

## Stage ownership

- `game-design/`: versioned Game Design Markdown/JSON.
- `wireframe/`: versioned Interaction Wireframe Pack Markdown/JSON.
- `implementation/`: atomic Implementation Contract, sealed Fidelity Blueprint and independent Blueprint-review snapshots.
- `build/`: archive mirror of the exact final Godot game commit plus build metadata. Build Farm may continue constructing at `builds/<slug>/`; the archive copy must never replace `job.last_commit`.
- `fidelity/`: independent review JSON and immutable builder/gate evidence copies.
- `playtest/`: showroom package, concept-art options and human playtest material.
- `visual/`: visual-development specifications and approved production art.

## Safety

1. Do not move/delete legacy canonical build/evidence paths just to make the tree prettier.
2. Preserve DB UUIDs, Blueprint hashes and final-game commits exactly in manifests.
3. Archive copies never change frozen design semantics.
4. GitHub/archive failures are operational failures, not semantic blockers; retry archive work rather than silently losing it.
5. Rebuilds may refresh current archive paths; Git history plus commit/hash metadata preserves provenance.
6. Large release binaries, raw video/audio projects, PSD/source art and other very large binaries should use a later large-asset policy rather than normal Git history.

## Pipeline completion rule

A stage that produces a durable artifact should write the matching `projects/<slug>/...` archive before reporting normal success. Existing legacy rows are backfilled by the 2026-10-01 project-tree normalization.
