# One-Way Wizard — Interaction Wireframe Pack v1.0

**FIRST BUILD CONDITIONAL READY · validation_strength=reduced**

Wave2 success does not mechanically require Redirect/Split; fresh-cast dominance has not been ruled out. The playable proceeds specifically to measure whether transformations are desirable in human play.

## Scope and authority

Fixed Wave2 Split Lane only. Frozen rules-v0.2, FIRST_BUILD_SPEC v0.1 and unchanged RULE test own every numeric/game-state meaning. First Build Retry overrides full-game Wave1 Retry by restoring WAVE2_INITIAL. Wave1/Wave3, Anchor, Carry Select, persistent score and final polish stay outside this playable. Merge's existing kernel remains tested upstream; no Merge input button.

## Screens

### S1_WAVE2_BRIEF — Wave2 Brief

Introduce conditional playable, objective and controls. States: ready.

Layout (logical px): {"header":[24,40,492,90],"summary":[24,160,492,150],"controls_legend":[24,350,492,200],"validation_notice":[24,600,492,120],"start":[200,790,140,80]}.

Explain aim is retained; CAST fires one Bolt; tools launch pulses at current aim.

### S2_ARENA — Split Lane Arena

Live projectile reuse and transformation. States: playing, cast_unavailable, tool_unavailable, impact_feedback.

Layout (logical px): {"hud":[24,40,492,100],"arena":{"x":22,"y":154,"w":496,"h":496},"move_pad":{"x":24,"y":690,"w":220,"h":200},"aim_pad":{"x":296,"y":690,"w":220,"h":200},"cast":{"x":24,"y":900,"w":140,"h":48},"redirect":{"x":200,"y":900,"w":140,"h":48},"split":{"x":376,"y":900,"w":140,"h":48}}.

Numeric costs update from production state; failed cast/tool gives explicit reason. Redirect +90 and Split child visualization follows authoritative events; animation never locks inputs. HP damage shield feedback follows existing invulnerability; no extra immunity.

### S3_PAUSE — Pause Overlay

Freeze rules exactly. States: paused.

Layout (logical px): {"panel":[90,280,360,410],"resume":[130,340,280,80],"retry":[130,460,280,80],"brief":[130,580,280,80]}.

Dim arena, show Paused; numeric resources preserved.

### S4_RESULT — Wave2 Result

Authoritative outcome and retry. States: success, failure.

Layout (logical px): {"outcome":[24,160,492,220],"gap_notice":[24,430,492,220],"retry":[70,760,160,80],"brief":[310,760,160,80]}.

Keep conditional notice visible in handoff and representative playtest.


## Interaction

540×960 portrait. Move pad center(134,790), aim pad center(406,790); each independently captures one pointer. Movement magnitude is zero through16px and scales to1 at80px. Releasing/cancelling movement zeros its vector. Aim drag beyond16px retains atan2 direction; releasing aim does not cast. CAST, REDIRECT and SPLIT are explicit taps at(94,924),(270,924),(446,924). Pulses launch at retained aim; no direct projectile selection, homing, auto-fire or coercion to use transformations.

Buttons commit once on release, ≤12px travel and ≤500ms inclusive; drag-off and pointer cancellation never fall back to CAST. Duplicate release never repeats. Production validators own cooldown, resources, cap and hit costs; disabled controls show reason and recheck at release.

## Real-time/presentation boundary

The60Hz production rule clock runs independently of renderFPS and all trails/impact/transform presentation. Valid input is still accepted during effects. Pause freezes exact rule clock/timers, cancels captures and zeros movement; Resume requires a fresh gesture. Focus loss uses the same Pause. Authoritative terminal result immediately blocks gameplay and opens Result. Retry resets fixed Wave2 and clears gestures, aim, trails and observer history.

## Readability/accessibility

Arena(22,154,496,496) shows authored pillars, Wizard, Chasers/Drifters, distinct Bolt/pulse arrowheads, short trails and wrap exit/entry cues. HUD always shows HP, mana, tool charges, projectile count/cap and spawn progress. Tool transformations render authoritative events. Minimum44px controls, ≥16px text and4.5:1 contrast; shapes/labels accompany color. Reduced motion removes shake without changing rule time.

## Locked INPUT interface

INPUT_CONTRACT.json and WIREFRAME_SEMANTIC.json contain exact regions, boundaries and pointer policies. debug_tap, debug_drag and debug_pointer must use real production hit-testing/recognizers and existing production semantic setters. debug_ui_snapshot is read-only; accepted dispatch history exposes mapping for test assertions and is never a separate mutation path.

tests/input_smoke.gd covers navigation, move/aim mapping, multi-touch, threshold boundaries, pointer/drag cancellation, duplicate input, disabled/cap inputs, cast while effects play, Redirect/Split production dispatch, pause/frozen clock, result/retry and input-to-rule observation. Synthetic gesture duration is recognizer metadata; explicit debug_step advances the production clock in existing deterministic fixtures.

Runtime INPUT/RULE execution is pending Builder implementation. This stage freezes the executable acceptance contract and does not claim a runtime pass.

## Upstream lineage

- First Build plan: 3311a727-e6be-4028-ae79-bd6a2e16375b
- Validation reference file SHA-256: 30e8fd88b03a98781dbdd682437a6478b3b2f40f3b8b2ef46e5a47b7ccf79a13
- First Build semantic hash: c3e6b69a6a5c010724e8f7dace82eee1654c6a4e98dc161f34b9bc6a23023e2b
- Unchanged RULE test SHA-256: 4ea207de07329f023ee22665a6521714edbb19df5f352ab53fdfcadba5db96f5

Wireframe semantic hash uses danbi_front_json_hash(WIREFRAME_SEMANTIC.json::jsonb), matching front-pipeline canonical JSON hashing. INPUT test hash is exact UTF-8 file bytes. Markdown is explanatory and excluded from semantic hashing.

## Mandatory representative playtest questions

- Can players read old projectile lanes while moving and aiming?
- Do players voluntarily use Redirect/Split rather than fresh-cast spam?
- Does fresh-cast dominance persist when tools are equally accessible?
- Are transform pulses and toroidal wrap understandable under overlapping trails?

Conditional/reduced status and the gap above must survive Compiler, Build and playtest handoff. A successful Wave2 run does not demonstrate transformation necessity.
