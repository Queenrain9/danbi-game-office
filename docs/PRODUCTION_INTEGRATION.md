# Canonical construction integration v1

The existing Compiler, Build Farm and Static Fidelity Gate scheduled prompts use `tools/fidelity/production.py` and `tools/fidelity/construction.py` from `Queenrain9/danbi-game-office/main`. This is a small standard library foundation, not a generic game engine. It converts explicit screen percent boxes and node paths to a declarative Godot scene, checks source/requirement/binding/implementation references, and packages **static** test evidence. Game-specific rules remain in reviewed GDScript. Runtime feel is reserved for the human playtest.

The Compiler automation was paused before this integration and remains paused. The Builder and Gate schedules remain enabled. No existing game was reclassified or promoted.


## Per-game GitHub project archive

Every production game has a durable GitHub project root under `projects/<slug>/`. The detailed convention is in `docs/PROJECT_ARCHIVE_CONVENTION.md`.

Supabase remains the operational database for live queue selection, status transitions, UUID identity, Blueprint hashes and run bookkeeping. GitHub is the durable, human-browsable project archive. A completed artifact should not survive only as a database row.

Expected stage archive paths:

- `projects/<slug>/game-design/`
- `projects/<slug>/wireframe/`
- `projects/<slug>/implementation/`
- `projects/<slug>/build/`
- `projects/<slug>/fidelity/`
- `projects/<slug>/playtest/`
- `projects/<slug>/visual/`

The active Build Farm construction path remains `builds/<slug>/` for compatibility. Do not move or rename it during an active pipeline. When a final game commit is fixed, archive an exact mirror under `projects/<slug>/build/godot/` without replacing `job.last_commit`; evidence-only archive commits are not game commits.

The Project Archive Reconciler is allowed to backfill or refresh missing archive mirrors after the production stage completes. Archive repair must never rewrite Game Design/Wireframe meaning, Contract requirements, approved Blueprint content, build identity, evidence identity or review verdicts. A GitHub/archive outage is operational, not a semantic game blocker.

Before introducing any new stage-specific GitHub location, prefer the per-game project tree above rather than creating another top-level archive silo.

## Scheduled pipeline run ledger

Every scheduled production job that reads this document must record its execution independently from artifact creation. This lets the CEO dashboard distinguish "no work this hour" from "the automation did not run".

Canonical job names:
- `implementation_contract`
- `build_farm`
- `fidelity_gate`

The canonical default is **explicit DML**, not a SELECT-wrapped write-side-effect RPC. This avoids scheduled-run security checks mistaking operational writes hidden inside SELECT for read-only work.

At the very start of a scheduled run, before lease acquisition or candidate selection, insert a `running` ledger row and keep the returned id for the entire execution:

```sql
insert into public.danbi_pipeline_runs(
  job_name, run_key, status, started_at, finished_at,
  produced_count, summary, error_summary, metadata, updated_at
)
values(
  '<job_name>',
  null,
  'running',
  now(),
  null,
  0,
  null,
  null,
  jsonb_build_object('source','chat_automation'),
  now()
)
returning id;
```

Use the returned id as `run_id`. For Build Farm, the same execution identity should also make the production lease owner unique, for example:

`build-farm-hourly:<run_id>`

If the ledger insert itself is unavailable because of an operational/tool/security failure, do **not** mark the game or Blueprint blocked. Generate one fresh execution UUID for that run, keep it fixed for the lifetime of the run, and use it anywhere a per-execution owner is required. Continue only when doing so does not weaken source or lease safety.

A crash or forced interruption may intentionally leave a `running` row so the dashboard can detect stale execution state.

Before every normal return, including "no candidate", lease-unavailable exits, PARTIAL completion, and handled failures, update the same ledger row explicitly:

```sql
update public.danbi_pipeline_runs
set
  status='<success|noop|blocked|failed>',
  finished_at=now(),
  produced_count=<actual durable game count>,
  summary='<short summary>',
  error_summary=<error_summary_or_null>,
  updated_at=now()
where id='<run_id>';
```

Status meaning:
- `success`: durable pipeline progress was committed. This also covers a PARTIAL run when durable progress exists; put the checkpoint / `resume_from` and operational issue in `summary`.
- `noop`: the automation executed normally but had no eligible work, or another valid production lease was busy and no durable state changed.
- `blocked`: a real semantic/source integrity blocker in the selected work prevented advancement.
- `failed`: an operational/tool/network/permission/storage failure prevented advancement and no durable pipeline progress was committed.

Do not use operational failures such as transient GitHub/Supabase/tool/permission/storage errors to mark the game itself blocked. Preserve the game checkpoint and report the operational failure in the run ledger instead.

Never create fake output just to make `produced_count > 0`. The run ledger is operational telemetry, not production evidence and not a substitute for existing build/evidence/fidelity records.

The legacy helpers `danbi_start_pipeline_run(...)` and `danbi_finish_pipeline_run(...)` may still exist in the database, but scheduled production prompts should prefer the explicit INSERT/UPDATE path above unless a future canonical revision explicitly changes this policy.

## Canonical reference size

Wireframe geometry is stored as screen percentages, so construction still needs one deterministic pixel canvas for Godot offsets and project settings.

Resolution rule:

1. If the current Wireframe Pack explicitly contains `reference_size: {width, height}` (or the same field in `developer_handoff`), that source value wins.
2. Otherwise, the studio mobile fallback is:
   - `orientation: portrait` → **540 × 960**
   - `orientation: landscape` → **960 × 540**
3. Any other orientation without an explicit size is a real specification blocker.

The Compiler must write the resolved value to `bindings.reference_size`. The Builder must use that exact size in `project.godot`; it must not infer a different viewport from an old build, screenshot, or superseded implementation. This fallback is a studio construction convention, not a reuse of historical game output.

## Semantic component and interaction binding

Wireframe `component.type` values are semantic design types, not Godot class names. The Compiler must resolve them through `SOURCE_COMPONENT_TYPES` in `tools/fidelity/construction.py`; it must not block merely because values such as `status`, `card`, `canvas`, `hotspots`, `interactive_object`, `drop_target`, `preview`, or `slider` are not literal Godot classes.

For interactions, preserve the original Wireframe target text in `bindings.interactions[].source_target` and bind it to concrete spatial components:

- `target_node`: the primary component that owns the input start/handler.
- `related_nodes`: optional additional components participating in the same interaction, such as two rotate buttons or drop lanes.
- `target_selector`: required when the Wireframe names a semantic child/sub-target inside one component (for example `shadow_piece`, `hotspot`, `visible internal shape in xray_box`). The selector preserves what inside the component receives the interaction without inventing another top-level Wireframe component.
- A normal Button tap uses `button_tap_v1` and a `pressed` connection.
- A tap on a hotspot, card, object region, or internal shape uses `explicit_script_v1` plus an explicit `input_handler`; it must not be converted to a Button.
- Structured standard gestures (drag/swipe/hold/pinch/trace and drag→snap completion) compile to a pinned production adapter plus `adapter_host_v1`. Legacy or genuinely game-specific gestures may still use `explicit_script_v1` with a recorded fallback reason.
- Natural-language targets such as “rotate buttons”, “symptom target”, or “visible internal shape in xray_box” are not specification failures when they can be bound explicitly to one or more existing Wireframe components while `source_target` remains unchanged.

This binding layer preserves the source meaning while allowing the Godot implementation to use concrete node paths.

Compiler target resolution follows the reference helper `resolve_interaction_target(screen, source_target)` in `construction.py`:

1. exact component id/label,
2. component id explicitly named inside the natural-language target,
3. singular/plural or shared token match, including legitimate multi-target controls,
4. otherwise, a semantic child target may bind to the **only** interactive spatial host on that screen with `target_selector=source_target`,
5. if more than one plausible owner remains, fail closed instead of guessing.

Example: Midnight Lost Property's `hotspot` tap on the inspection screen resolves to the only `manipulable` Lost Item component with `target_selector="hotspot"`; the source target string remains unchanged.

## Compiler → independent Blueprint review

Export **current full DB rows** for Contract, Wireframe Pack and Game Design to JSON. The Blueprint must keep `schema_version: fidelity-v1`, a frozen `source` with `pack`, `design`, and `requirements`, identical `screens` and `requirements`, plus `hash_algorithm: sha256-canonical-json-v1`. Add `bindings.scene_path`, `reference_size`, `coordinate_space: screen_percent`, `stretch_mode: canvas_items`, explicit `nodes`, `components`, `connections`, `interactions`, `implementations` (one or more `res://` file/node or symbol references per requirement), `reusable_components`, and `tests` with deterministic `checks` and `stage`. Use `construction_pattern` on each node; `registry` lists supported patterns. Every stage needs a static test, every requirement needs static implementation coverage, and executable behavior has a separate manual test. Use zero-based RFC6901 JSON pointers for `bindings.sources`.

Seal a **draft** with:

```sh
python tools/fidelity/construction.py seal --blueprint draft.json --output sealed.json
python tools/fidelity/production.py check-blueprint --blueprint sealed.json --contract contract.json --pack pack.json --design design.json --output blueprint-report.json
```

Re-read DB source before writing. An approved hash is immutable: recompile and independently reapprove any source or binding change. Legacy hashes have an unknown canonical format in this tool; never rewrite an approved Blueprint in place.

## Blueprint review return path

Independent Blueprint review is a loop inside the Implementation room lifecycle, not a terminal queue in the Fidelity room.

Lifecycle:

`draft/missing → pending_review → approved/ready → Build Farm`

If review fails:

`pending_review → blocked/draft → Compiler repair → pending_review`

The Gate must call `danbi_reject_blueprint(contract_id, blueprint_hash, token, issues, review)` for a real Blueprint FAIL. That preserves the same Contract, stores the machine-readable `blueprint_issues` and independent review, and returns the item to the Implementation room as **설계 수정 필요**. A failed Blueprint must not remain indefinitely in `pending_review`.

The Compiler then receives the same Contract as `resume_blocked`, reads the review issues, repairs only the Blueprint construction/trace/coverage defects allowed by the existing source, reseals with a new Blueprint hash when content changed, clears the issue set, and submits it again as `pending_review`. It must never create a replacement Contract merely because independent review failed.

Compiler candidate priority is:
1. `resume_missing`
2. `resume_blocked`
3. `new`

This prevents rejected design work from being starved indefinitely by a continuing stream of new Wireframes while still allowing an interrupted partially-created Contract to complete first.

## Builder → final commit → static evidence

Clone or materialize the repository, review the approved Blueprint, and construct an exact candidate scene:

```sh
python tools/fidelity/construction.py construct --blueprint approved.json --output candidate.tscn
```

Generate game-specific scripts and resources for all referenced rules, state, input, feedback and transitions. Never turn a drag/swipe/hold into a Button tap. Commit the **game files first**, then prepare one unique claim per requirement with `status: IMPLEMENTED`, the final game commit, approved hash, and exact `implementation_refs`. Validate the checked-out project at that immutable commit:

```sh
python tools/fidelity/production.py check-build --blueprint approved.json --contract contract.json --pack pack.json --design design.json --project builds/slug --claims claims.json --commit FINAL_GAME_COMMIT --output static-report.json
```

Commit `static-report.json` outside `builds/slug` at `production/evidence/<job-id>/<final-game-commit>/builder.json`. The extra evidence commit does not replace `job.last_commit`. Check its remote bytes and hash. Then:

```sh
python tools/fidelity/production.py bundle --blueprint approved.json --report static-report.json --artifact-path production/evidence/<job-id>/<final-game-commit>/builder.json --role builder --output builder-payload.json
```

Pass `evidence_run` to `danbi_record_evidence` with the Builder lease. For each of the six `stage_test_ids` keys, call `danbi_record_stage` in order with the **returned evidence UUID**, `passed`, and `detail.verification_scope: static`. Store the claims in `danbi_build_implementation_evidence`. Only after six stages and exact complete claims, set `fidelity_pending`.

## Independent Gate → PLAYTEST READY

Fetch the **original game commit** and DB rows again in a clean checkout. Run `check-build` independently, examine actual source/scene/script meaning for every requirement, and produce a separate Gate report/artifact outside the game path. Use `bundle --role gate` and `danbi_record_evidence` under the Gate lease to obtain its own UUID. Every `VERIFIED` result in `danbi_apply_review` lists the matching Gate UUID in `evidence_ids`; unexecuted manual test IDs remain manual. Static structural presence alone cannot prove that a game-specific action is semantically correct. Partial/missing/conflicting/broken requirements need the existing expected/observed/rationale and ordered repair groups. A clean static report plus independent semantic inspection can promote `playtest_ready`; it does **not** claim runtime QA.

## Explicit boundaries

- The tool parses declarative `.tscn` nodes, script references, simple scalar properties, symbols and resource paths. Dynamic scene creation, instanced/inherited scenes and complex GDScript semantics are not automatically verified. Block for explicit review or extend the parser when needed.
- `modal_scrim_v1` blocks Control mouse input only; `_input` touch handling needs an explicit reviewed lock path. Standard drag/snap/hold/swipe/trace/pinch primitives are supplied by the immutable Interaction Runtime Registry; game-specific state semantics still require reviewed host/action code.
- `check-build` verifies a real Git commit and clean project bytes. The artifact lives in a later separate commit to avoid self-referential hashes.
- The CLI only prepares validation output and RPC payloads. It cannot grant independent approval or write a DB status by itself.
- Both live Blueprints at handoff remain blocked. They require correction, independent approval, a full Godot build and a fresh Gate review before any actual game can be declared PLAYTEST READY.


## Compiler atomicity and self-healing

Implementation Contract + Fidelity Blueprint compilation is one atomic game-level unit:

`source read → Contract checkpoint → Blueprint → validator → blueprint/history write → checkpoint complete`.

A Contract row with `status='draft'` and `blueprint_status='missing'` is a resumable checkpoint, not a failed artifact. The next Compiler run must recover it before creating another new Contract. The database helpers are:

- `danbi_next_compiler_candidate()` — returns `resume_missing` first, then `resume_blocked` review repairs, then a new Wireframe.
- `danbi_compiler_checkpoint(contract_id)` — reports complete only when the Blueprint, 64-character hash, empty issue set, `pending_review|approved` status, and matching `danbi_blueprint_history` row all exist.

Within one scheduled run, game A must reach a complete checkpoint before game B is touched. A raw Contract INSERT is never a successful Compiler completion.

Large Contract/Blueprint payloads must be passed as structured JSON or safely encoded/escaped before JSONB conversion. Do not construct megabyte-scale raw SQL JSON literals from free text. Transport/serialization failures such as an unescaped newline are retryable local failures; they must not become semantic blockers or cause the Compiler to skip to the next game.

A `blueprint_status='blocked'` item is a returned Blueprint review repair. It is retried before new Wireframes so review failures do not accumulate indefinitely. If the issue is truly upstream and cannot be repaired at the Blueprint layer, keep it blocked with explicit issues rather than silently skipping it.


## Interaction Runtime Library v1

Planning language and Godot implementation now meet at a stable semantic boundary.

- Game Design owns what/why and never names runtime adapters.
- Wireframe may add `interaction_semantics`: `kind`, component ids, axis/cancel/timing/distance/tolerance, and optional `completion:{kind:'snap',target_component_id,tolerance_px,rotation_tolerance_deg}`.
- Blueprint Compiler maps those semantics through `construction.INTERACTION_ADAPTERS`.
- Build Farm copies only used scripts from `production/godot/interaction_runtime/` to `res://runtime/interaction/`.
- Static Fidelity verifies requirement → semantics → adapter id/params → host node/script/action/state.
- Unknown mechanics use `explicit_script_v1` only with `fallback_reason`.

First stable primitives: `drag_v1`, `snap_v1`, `hold_v1`, `swipe_v1`, `trace_v1`, `pinch_v1`.

When Godot CLI is available, run:
`godot --headless --path production/godot/interaction_runtime --script res://headless_tests.gd`

The shared runtime test proves adapter behavior only. Game-specific critical paths can add small headless tests under `builds/<slug>/tests/`. Runtime evidence is additive; never fabricate it when Godot is unavailable.

Legacy Wireframes without `interaction_semantics` and already-approved Blueprints remain valid through `explicit_script_v1`. New structured interactions should compile to `adapter_host_v1` + `adapter_bindings` whenever supported.


## Immutable Interaction Runtime Registry

Reusable Godot interaction code follows the same freeze/hash/reapproval model as Fidelity Blueprints.

Lifecycle:

`candidate → production → deprecated`

- **candidate**: implementation may change while being developed and tested. The Blueprint Compiler never selects it.
- **production**: eligible for new Blueprints and immutable. Promotion requires static/Python tests, the Godot headless suite, a registered SHA-256, validated Godot version, and CI run.
- **deprecated**: cannot be selected for a new Blueprint, but every already-approved Blueprint that pinned it remains valid. A production adapter may only move to deprecated without changing its code/hash.

Frozen code is never patched in place. A bug fix to `drag_v1.gd / DanbiDragV1` becomes a new candidate such as `drag_v2.gd / DanbiDragV2`. Existing games never auto-upgrade; migration means Blueprint recompilation, a changed Blueprint hash, independent reapproval, and a rebuild.

The canonical registry is `production/godot/interaction_runtime/registry.json`. Each frozen entry records at least:

- adapter_id and semantic_kind
- lifecycle status
- versioned source_path and game script_path
- SHA-256
- versioned Godot class_name
- validated_godot versions
- promotion ci_run
- superseded_by

### Hash rule and cross-PC stability

`.gitattributes` fixes Godot/compiler text files to LF. Adapter SHA-256 uses UTF-8 content with CRLF/CR normalized to LF (`sha256-lf-bytes-v1`), matching the bytes Git stores for these text files. This prevents Windows checkout line endings from changing the production identity.

CI runs `construction.py verify-adapter-registry`. It checks the current frozen file bytes against the registered hash and, on push, compares the registry against the previous commit. Once an entry has reached production, immutable fields and SHA-256 cannot change; production may only become deprecated. Updating the file and registry hash together does not bypass the freeze check.

### Blueprint pinning

The Compiler selects only the current `production` adapter for a semantic kind. Every `adapter_bindings[]` entry pins:

- adapter_id
- `adapter_status: production` at compilation time
- adapter_sha256
- adapter_class_name
- source_path and script_path
- semantic targets and parameters

These fields are inside the Blueprint JSON before `sha256-canonical-json-v1` sealing, so changing an adapter/version/hash changes the Blueprint hash and requires independent reapproval.

A later deprecation does not invalidate an approved historical Blueprint: validation accepts its frozen pinned adapter as production-at-compile-time while the registry retains the same immutable hash.

### Historical build verification

`check-build` does **not** compare a game-local adapter to whatever file happens to be current on main. It hashes the adapter copy in the reviewed final game checkout and compares it to the SHA-256 pinned in that Blueprint. This makes old game verification reproducible even after newer adapter versions become production.
