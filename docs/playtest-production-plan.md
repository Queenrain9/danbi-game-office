# PLAYTEST READY compatibility and construction foundation

Goal: preserve the existing production pipeline; end automation at committed Godot files plus independent static fidelity, leaving runtime QA to human Godot/Xogot playtests.

Audit baseline: main f00c0b5; live Supabase functions inspected 2026-09-30. No shared compiler, validator or construction package exists in this main checkout. Existing game-specific gesture helpers remain untouched.

1. Reproduce the unguarded playtest_ready transition in a rolled-back transaction. Replace runtime requirements with explicit static test evidence and deferred manual tests. Preserve approval, source identity, final commit, exact coverage, independent gate and repair DAG checks. Test with synthetic rows inside rollback; do not promote existing games.
2. Add a small Python standard-library tool under tools/fidelity: exact geometry conversion, explicit node/path rules, pattern registry, scene construction and static validation. No inference of game actions or replacement of gestures. Ambiguous bindings fail closed.
3. Test resource/node/symbol/geometry/traceability failures using fixture mutations. Compare real blocked Blueprints and existing builds without changing their sources or claiming they passed.
4. Commit migrations, tool, tests and a short operating guide to main; verify live function definitions and remote commit. No Godot runtime, screenshot or bot execution.

Review focus: NULL identities; forged/stale claims; source changes after approval; nested scene geometry; unknown gestures/dynamic nodes. Unsupported static proofs stay blocked or inconclusive; gameplay feel remains manual.
