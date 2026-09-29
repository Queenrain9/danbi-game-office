# PLAYTEST READY audit / Sol handoff — 2026-09-30

## Completed and live: priorities 1–2

User narrowed this session after DB verification: finish audit/guard compatibility; leave construction and validator completion to Sol. Do not interpret the initial tooling as production integration complete.

Inspected GitHub main `f00c0b5956c6952732918d0ffe0becc72779aae7`, all nine live `danbi_*` functions, both triggers, constraints, contract/Blueprint records, both game builds, and sync Edge Function v13. No shared construction/compiler/validator code was committed in this main tree. DB issue records mention an earlier validator, but its source was not in this repository; locate it before integrating/replacing any external tooling.

Actual conflicts:
- `danbi_record_stage`: all stages after skeleton required runtime evidence.
- `danbi_apply_review`: every non-static Blueprint test required runtime evidence to accept VERIFIED.
- `playtest_ready` was already a legal DB token but was absent from the promotion guard. Reproduced unapproved promotion, then rolled it back.
- `building` did not require an approved Blueprint. Promotion checked a contract hash but did not compare all source identities/current source snapshots or require unique final-commit claims.

Applied migration **playtest_ready_static_fidelity_v2** to project `hmblaasagxyntyfrfztg`. Exact SQL in `db/changes/playtest_ready_static_fidelity_v2.sql`; original function definitions in `db/changes/playtest-ready-before.json`.

Changes:
- Keep existing RPC signatures, fidelity-v1 and status tokens. New independent PASS promotes to `playtest_ready`.
- Add job `verification_scope`, `runtime_qa_performed`, `manual_playtest_required`; review `verification_scope`, `manual_test_ids`. Existing rows remain `legacy_unknown`, not retroactively certified.
- Static test = `verification_scope: static`, or legacy `kind: static` if no scope. All other tests remain human-playtest obligations; never relabel an unexecuted runtime test passed.
- Six construction stages still required at the final commit, now with matching static evidence. Each stage needs an explicit static test; `stage` selects it (integration covers all static tests).
- Every requirement needs static coverage; independent gate evidence must match job/hash/commit and have role gate. Manual test IDs are retained on the review.
- Approved/current Blueprint, live source identity/content, complete unique final-commit claims and no static blockers are enforced. Existing independent approval and repair DAG/defect logic remain.
- New helpers are invoker functions with restricted execution (service_role only); existing RPC ACLs are preserved. No RLS or frontend privileges changed.

## Verified

`db/tests/playtest_ready_rollback.sql` ran successfully on the live DB in a transaction that rolled back all fixtures:
- static-only six stages → independent static gate → PLAYTEST READY, with runtime_qa_performed=false;
- manual runtime test remains deferred;
- rejected unapproved build/promotion, stale hash, duplicate claims, runtime test reported as static, Builder evidence used for gate, and changed source snapshot.

The original Tiny Stagehand bypass was separately rechecked and now rejects promotion. Final readback: original two jobs and three contracts unchanged; 106/94/93 requirements unchanged; zero fixture jobs and zero active leases. No actual game was promoted. Existing repair logic was retained, but its entire defect/DAG branch was not newly integration-tested in this session.

Supabase advisors: no new function/RLS warnings. Existing service-only tables have RLS/no public policy (intentional architecture); pre-existing Auth leaked-password protection warning is unrelated and unchanged.

## Production flow and payload contract

Wireframe → atomic Contract + concrete fidelity-v1 Blueprint → independent Blueprint approval → Builder → final Godot commit → six static construction stages + complete claims → independent static review → PLAYTEST READY → human Godot/Xogot playtest.

Claim example (one per requirement, attached to the existing implementation evidence row):

```json
{"requirement_id":"R1","status":"IMPLEMENTED","commit":"<40-character real final SHA>","blueprint_hash":"<approved hash>","implementation_refs":[{"file":"res://scripts/main.gd","symbol":"start_game"},{"file":"res://main.tscn","node_path":"/root/AppRoot"}]}
```

Test example:

```json
{"id":"STATIC:input:R1","kind":"static","stage":"input","requirement_ids":["R1"],"checks":[{"kind":"symbol","file":"res://scripts/main.gd","symbol":"start_game","symbol_kind":"func"}]}
```

`kind: geometry/state/input/presentation` can also declare `verification_scope: static`. Runtime/gesture/feel tests use `verification_scope: manual_playtest` and do not gate production. They cannot replace requirement static coverage.

DB can enforce evidence structure/relationships; it cannot fetch GitHub objects, parse Godot files or prove claimed artifact hashes. The verifier must check actual commit/files. Stored SHA strings alone are not proof.

## Initial priorities 3–4 code, NOT yet production-integrated

`tools/fidelity/construction.py`: Python standard library prototype for fidelity-v1 with explicit additions. Includes exact percent geometry (no pixel rounding), parent-relative offsets, deterministic `.tscn` nodes/scripts/connections, a small pattern registry, source pointers/hashes, resource/node/symbol/claim checks and Git commit/worktree checks. Does not generate game logic or approve a game. Nine local unittest cases passed, including negative mutations. Run:

```sh
python -m unittest discover -s tests -v
python tools/fidelity/construction.py registry
python tools/fidelity/construction.py validate --blueprint blueprint.json
python tools/fidelity/construction.py construct --blueprint blueprint.json --output candidate.tscn
python tools/fidelity/construction.py validate --blueprint blueprint.json --project builds/GAME --claims claims.json --commit FINAL_SHA --output static-report.json
```

New draft hashes use explicit `hash_algorithm: sha256-canonical-json-v1`; `seal` writes a new draft, never mutates an approved Blueprint. Legacy hashes have an unknown algorithm in this tool; they are blocked for explicit migration rather than silently recomputed. Source references use RFC6901, zero-based arrays. Current Borrowed Shadow has mixed positional/ID-like references that need explicit correction against source.

Current limited patterns: absolute Control, Button.pressed tap, modal mouse scrim, explicit reviewed script. Scrim only blocks Control mouse input; it does NOT yet implement a shared lock for `_input`/touch/gesture handlers. Drag/swipe/hold/snap adapters and state observers are not implemented. Never substitute them with taps.

Conservative parser requires explicit declarative node paths and attached scripts. It does not resolve instanced/inherited scenes, dynamic node creation or autoload paths. Unsupported forms block. Symbol presence is not semantic proof or GDScript syntax/type validation. Structural test results still need independent source/code review; do not automatically mark requirement VERIFIED just because a named function exists.

## Next work for Sol (priorities 3–4)

1. Read this handoff, migration and tool tests. Inspect currently scheduled compiler/builder/gate prompts and find the earlier validator source if it still exists; integrate rather than duplicate. Scheduled prompts were not edited in this session.
2. Review/harden this foundation: adversarial malformed schemas, missing state/action/signal bindings, actual reusable-component use, geometry parent semantics, unsupported static checks, extra/dynamic nodes, and exact source→binding semantics. Expand only concrete gaps.
3. Add canonical input/state/overlay behavior incrementally with source-driven parameters. No runtime automation. Keep each game's action rules in explicit scripts.
4. Wire compiler/Builder/verifier to the same pattern registry and CLI, and new DB claim/static-stage payloads. Define where checks/reports are committed (avoid a report embedding its own containing commit hash).
5. Recompile/review one real Blueprint, then build/verify it end to end. Midnight has no Blueprint; Borrowed Shadow is blocked and contains nonsensical reusable mappings and whole-screen gesture fallbacks; Parcel has empty bindings and an older VBox-generated implementation. Do not clear their blockers or declare them ready merely because DB guards now allow static verification.
6. Extend rolled-back DB tests for defect→repair→re-review and repair DAG cycles; do not rerun the migration unnecessarily. Inspect live definitions before any further DB edits.

No runtime/headless Godot, screenshot diff, auto-play, dashboard redesign, or CI expansion was performed.
