# Ghost Train Coupler — Interaction Wireframe Pack v0.2

## Pack Overview
- Device: mobile phone
- Orientation: portrait
- Core Screen: yard_puzzle
- Primary Interaction: 레일 제약 객차 드래그 + 커플링/분리

## Interaction Principles
- 객차 직접 조작이 메뉴 조작보다 우선
- 레일 제약은 손가락 오프셋을 보존
- 작은 커플러는 44pt hit area
- 실패 dispatch는 원인만 강조하고 즉시 재편성 복귀

## Screen Flow
- Normal: puzzle_select → yard_brief → yard_puzzle → dispatch_check → result

## Screens
### 1. Puzzle Select
8개 hand-authored yard puzzle의 해금/선택 상태를 보여주고 Brief로 진입.

Components:
- title: Ghost Train Coupler [label] box(5,4,70,6) · static
- progress: Unlocked / 8 [counter] box(75,4,20,6) · progress.unlocked
- puzzle_grid: Puzzle cards 1–8 [grid] box(5,16,90,72) · progress.puzzles
- back: Back [button] box(5,91,24,7) · nav
State variants:
- Locked Puzzle: puzzle.locked — Locked card consumes no selection input.
Interactions:
- tap → unlocked puzzle card: select puzzle; state=selected_puzzle=id; invalid=locked card: no transition

### 2. Yard Brief
선택 퍼즐의 rule cards와 yard preview를 읽고 시작.

Components:
- rule_cards: 2–4 Rule Cards [stack] box(5,7,90,42) · puzzle.rules
- yard_preview: Track / cars preview [diagram] box(5,51,90,34) · puzzle.preview
- back: Back [button] box(5,88,28,8) · nav
- start: Start Yard [button] box(58,88,37,8) · brief.ready
Interactions:
- tap → rule card: expand rule semantics; state=inspected_rule=id; invalid=none
- tap → start: enter yard; state=yard state=idle; invalid=disabled while not loaded

### 3. Yard Puzzle
핵심 shunt/couple/uncouple/switch/inspect/dispatch 조작을 수행.

Components:
- rule_strip: Rule Cards [horizontal_strip] box(2,2,96,14) · rules.status
- rail_canvas: Rail Network [spline_playfield] box(2,19,96,65) · yard.rails
- cars: Cars / consists [draggable_entities] box(4,24,92,52) · yard.cars
- coupler_handles: 44pt Coupler Handles [hit_targets] box(4,24,92,52) · yard.couplers
- switch_levers: Junction Lever [hit_targets] box(8,30,84,38) · yard.switches
- departure_zone: Departure Zone [drop_zone] box(4,69,92,12) · yard.departure_occupancy
- moves: Moves / Par [counter] box(3,88,25,8) · score.moves
- undo: Undo ×3 [button] box(31,88,22,8) · undo.remaining
- dispatch_signal: Dispatch Signal [vertical_swipe_control] box(76,86,20,12) · dispatch.ready
- inspect_callout: Passenger / constraint callout [popover] box(10,20,80,16) · inspect.active
State variants:
- Dragging Consist: state=shunting — Finger offset preserved; connected consist moves as unit.
- Snap / Couple Candidate: compatible end within range — Blue magnetic ghost appears.
- Blocked Route: occupied segment reached — Movement stops before occupied car; bumper feedback.
- Rule Inspected: rule/passenger tapped — Destination/constraint symbols visible.
Interactions:
- drag → car/connected consist: project movement onto rail; snap nearest free stop <=32px; state=position changes; successful new snap counts 1 move; invalid=occupied segment stops motion; release without valid snap returns origin
- release → compatible car end: join consists; state=coupled=true; invalid=incompatible end rejects and remains separate
- tap then outward swipe >=24px → coupler handle: split consist; state=coupled=false; invalid=short/incorrect swipe cancels selection
- tap → switch lever: toggle junction route; state=switch.route toggles; invalid=tap ignored while safety zone occupied
- tap → passenger/car or rule card: show destination/constraint; state=inspect.active=id; invalid=none
- tap → Undo: restore previous shunt state; state=undo-- and state restored; invalid=disabled otherwise
- swipe up >=36px → dispatch signal: lock yard input and validate; state=state=validation; invalid=short swipe cancels; unmet requirements handled by overlay

### 4. Dispatch Check Overlay
Dispatch 동안 입력을 잠그고 규칙을 순차 검증해 성공/실패를 명료하게 표시.

Components:
- scrim: Input Lock Scrim [overlay] box(0,0,100,100) · validation.lock
- check_list: Rule Check List [list] box(12,23,76,42) · validation.rules
- status: Checking / Pass / Conflict [status] box(20,67,60,8) · validation.status
- conflict_link: Show Conflict [button] box(25,77,50,8) · validation.failed
State variants:
- Conflict: validation failed — Only violated rule cards pulse; implicated cars outline on underlying yard.
- Ready to Depart: all rules pass — Signal turns green before departure.
Interactions:
- tap → Show Conflict: close overlay and focus violated rule; state=state=yard_idle; violated highlight persists briefly; invalid=none

### 5. Result
moves/score와 다음 행동을 표시.

Components:
- score: Score [large_number] box(20,16,60,14) · result.score
- moves_used: Moves Used / Par [stat] box(12,34,36,10) · result.moves
- breakdown: Score Breakdown [list] box(52,34,36,24) · result.breakdown
- replay: Replay [button] box(10,75,36,10) · result
- next: Next Puzzle [button] box(54,75,36,10) · progress.next
Interactions:
- tap → Replay: reload same puzzle brief; state=selected_puzzle unchanged; invalid=none
- tap → Next: select next unlocked puzzle; state=selected_puzzle=next; invalid=disabled at end

## Global States
- input_lock: dispatch validation active → yard gestures disabled
- departure: validation pass → signal green + consist exits before result

## Input Map
```json
{
  "priority": [
    "overlay controls",
    "coupler handle",
    "switch lever",
    "car/consist drag",
    "rule/passenger inspect",
    "yard background"
  ],
  "gestures": {
    "tap": [
      "inspect",
      "switch",
      "undo"
    ],
    "drag": [
      "rail-constrained shunt"
    ],
    "swipe": [
      "uncouple outward >=24px",
      "dispatch upward >=36px"
    ]
  },
  "cancel": "drag to origin or system cancel restores pre-gesture state",
  "multitouch": "not required in MVP"
}
```

## Global Edge Cases
```json
{
  "collision": "stop before occupied car",
  "invalid_snap": "return to origin without move cost",
  "invalid_switch": "ignore tap while safety zone occupied",
  "invalid_dispatch": "validation fail costs score per Game Design then returns yard",
  "small_coupler": "44pt invisible hit target"
}
```

## Developer Handoff
```json
{
  "scene_hierarchy": [
    "App",
    "PuzzleSelect",
    "YardBrief",
    "YardPuzzle{RuleStrip,RailWorld,ControlBar}",
    "DispatchOverlay",
    "Result"
  ],
  "reusable_components": [
    "RuleCard",
    "RailSpline",
    "CarBody",
    "CouplerHandle",
    "SwitchLever",
    "DispatchSignal",
    "ScoreRow"
  ],
  "required_data": [
    "8 puzzle definitions",
    "rail topology",
    "car set/orientation",
    "passenger constraints",
    "par/move budget",
    "unlock state"
  ],
  "state_ownership": {
    "puzzle": "PuzzleController",
    "yard": "YardState",
    "gesture": "InputController",
    "validation": "RuleValidator",
    "progress": "ProgressStore"
  },
  "persistence": [
    "puzzle unlocks",
    "best score"
  ],
  "implementation_order": [
    "rail projection + collision",
    "car/consist drag + snap",
    "couple/uncouple",
    "switch",
    "rule validation + overlay",
    "score/undo",
    "selection/result"
  ],
  "notes": [
    "Use deterministic rail-stop occupancy; no real train physics.",
    "World geometry is data-driven; UI percent boxes do not replace rail coordinates."
  ]
}
```

## Acceptance Criteria
- 첫 사용자가 20초 내 객차를 레일을 따라 이동시킬 수 있다.
- 드래그 중 객차가 레일을 이탈하지 않고 손가락 오프셋을 유지한다.
- 32px 이내 유효 snap과 occupied collision이 서로 구분된다.
- 호환 커플러만 결합되고 분리는 tap+24px outward swipe로 동작한다.
- switch safety zone 점유 중 lever 입력은 무효다.
- dispatch 중 yard 입력이 잠기며 실패 시 위반 규칙과 관련 객차만 강조된다.
- 성공 dispatch는 출발 애니메이션 후 Result로 전환된다.
- Puzzle Select→Brief→Yard→Result→Next/Replay 전체 루프에 막다른 흐름이 없다.
