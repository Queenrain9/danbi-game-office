# Canonical construction integration v1

The existing Compiler, Build Farm and Static Fidelity Gate scheduled prompts use `tools/fidelity/production.py` and `tools/fidelity/construction.py` from `Queenrain9/danbi-game-office/main`. This is a small standard library foundation, not a generic game engine. It converts explicit screen percent boxes and node paths to a declarative Godot scene, checks source/requirement/binding/implementation references, and packages **static** test evidence. Game-specific rules remain in reviewed GDScript. Runtime feel is reserved for the human playtest.

The Compiler automation was paused before this integration and remains paused. The Builder and Gate schedules remain enabled. No existing game was reclassified or promoted.


## Scheduled pipeline run ledger

Every scheduled production job that reads this document must record its execution independently from artifact creation. This lets the CEO dashboard distinguish "no work this hour" from "the automation did not run".

Canonical job names:
- `implementation_contract`
- `build_farm`
- `fidelity_gate`

At the very start of a scheduled run, before lease acquisition or candidate selection:

```sql
select public.danbi_start_pipeline_run(
  '<job_name>',
  null,
  jsonb_build_object('source','chat_automation')
) as run_id;
```

Keep the returned `run_id` for the entire execution. A crash or interrupted run intentionally leaves a `running` row so the dashboard can detect a stale execution.

Before every normal return, including "no candidate" and lease-unavailable exits, finish the same run:

```sql
select public.danbi_finish_pipeline_run(
  '<run_id>',
  '<success|noop|blocked|failed>',
  <produced_count>,
  '<short summary>',
  <error_summary_or_null>,
  null
);
```

Status meaning:
- `success`: durable pipeline progress was committed, even if the game remains in the same high-level stage.
- `noop`: the automation executed normally but had no eligible work, or a lease was unavailable and no state changed.
- `blocked`: a real semantic/source/permission/storage blocker prevented the selected work from advancing.
- `failed`: an unexpected execution/tool failure prevented a normal completion.
- Never create fake output just to make `produced_count > 0`.
- The run ledger is operational telemetry, not production evidence and not a substitute for existing build/evidence/fidelity records.

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
- Non-tap gestures (drag/swipe/hold/pinch/trace/release/etc.) use `explicit_script_v1` on the primary target with an explicit reviewed handler.
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
- `modal_scrim_v1` blocks Control mouse input only; `_input` touch handling needs an explicit reviewed lock path. No general drag/swipe/hold/snap/state adapter is claimed yet.
- `check-build` verifies a real Git commit and clean project bytes. The artifact lives in a later separate commit to avoid self-referential hashes.
- The CLI only prepares validation output and RPC payloads. It cannot grant independent approval or write a DB status by itself.
- Both live Blueprints at handoff remain blocked. They require correction, independent approval, a full Godot build and a fresh Gate review before any actual game can be declared PLAYTEST READY.


## Compiler atomicity and self-healing

Implementation Contract + Fidelity Blueprint compilation is one atomic game-level unit:

`source read → Contract checkpoint → Blueprint → validator → blueprint/history write → checkpoint complete`.

A Contract row with `status='draft'` and `blueprint_status='missing'` is a resumable checkpoint, not a failed artifact. The next Compiler run must recover it before creating another new Contract. The database helpers are:

- `danbi_next_compiler_candidate()` — returns `resume_missing` first, then a new Wireframe, and only considers true blocked work after the normal queue can keep moving.
- `danbi_compiler_checkpoint(contract_id)` — reports complete only when the Blueprint, 64-character hash, empty issue set, `pending_review|approved` status, and matching `danbi_blueprint_history` row all exist.

Within one scheduled run, game A must reach a complete checkpoint before game B is touched. A raw Contract INSERT is never a successful Compiler completion.

Large Contract/Blueprint payloads must be passed as structured JSON or safely encoded/escaped before JSONB conversion. Do not construct megabyte-scale raw SQL JSON literals from free text. Transport/serialization failures such as an unescaped newline are retryable local failures; they must not become semantic blockers or cause the Compiler to skip to the next game.

A genuine `blueprint_status='blocked'` item does not starve the rest of production. Its issue record remains available for repair while new eligible Wireframes may continue through the Compiler.


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
