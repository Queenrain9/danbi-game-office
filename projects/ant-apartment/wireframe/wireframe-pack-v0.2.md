# Ant Apartment — Interaction Wireframe Pack v0.2

## Pack Overview
- Device: mobile phone
- Orientation: portrait
- Core Screen: apartment_room
- Primary Interaction: 정찰 탭 + 페로몬 경로 드래그/waypoint 수정

## Interaction Principles
- 세계 직접 조작 우선
- UI > waypoint > path > world 입력 우선순위 보존
- route validity를 즉시 시각화
- 카메라 제스처와 경로 편집 제스처 충돌 방지
- 위험 의미는 원본 mission data를 표시하고 새 규칙을 발명하지 않음

## Screen Flow
- Normal: mission_select → mission_brief → apartment_room → result

## Screens
### 1. Mission Select
MVP에서 제공되는 mission entry를 선택하고 Brief로 이동.

Components:
- title: Ant Apartment [label] box(5,4,70,6) · static
- mission_list: Mission Cards [list] box(5,16,90,72) · missions
- stars: Stars [counter] box(76,4,19,6) · progress.stars
Interactions:
- tap → available mission card: select mission; state=selected_mission=id; invalid=unavailable card: inert

### 2. Mission Brief
목표와 위험 정보를 읽고 Scout 시작.

Components:
- goal: Deliver 8 food [goal_card] box(5,8,90,24) · mission.goal
- hazard: Hazard Brief [risk_card] box(5,34,90,24) · mission.hazard
- preview: Room Preview [diagram] box(5,60,90,22) · mission.preview
- start: Start Scout [button] box(55,86,40,9) · brief.ready
- back: Back [button] box(5,86,30,9) · nav
Interactions:
- tap → Start Scout: enter apartment room; state=phase=Scout; invalid=disabled while loading

### 3. Apartment Room
Scout→RouteEdit→Haul의 핵심 플레이를 한 world screen에서 수행.

Components:
- goal_counter: Food 0/8 [counter] box(3,2,25,7) · round.delivered
- time: 150s [timer] box(39,2,22,7) · round.time
- survivors: Workers 12 [counter] box(70,2,27,7) · round.survivors
- world: Apartment World / Fog [world_view] box(0,12,100,76) · world.reveal
- scout: Scout Ant [world_entity] box(8,18,84,58) · scout.position
- nest: Nest Endpoint [world_entity] box(6,68,20,16) · world.nest
- food: Food Endpoint [world_entity] box(72,20,22,18) · world.food
- route_layer: Pheromone Route [editable_path] box(4,16,92,66) · route.state
- waypoints: Route Waypoints [hit_targets] box(4,16,92,66) · route.waypoints
- hazard_layer: Hazard / Warning [world_overlay] box(4,16,92,66) · hazard.state
- convoy: Worker Convoy [world_entities] box(4,16,92,66) · convoy.state
- route_budget: Pheromone 100 [meter] box(3,80,35,6) · route.budget
- eta_risk: ETA / Risk [status] box(41,80,32,6) · route.metrics
- dispatch: Dispatch [button] box(75,89,22,8) · route.valid
- pause: Pause [button] box(3,89,22,8) · convoy.paused
- warning_banner: Hazard Warning [banner] box(25,13,50,8) · hazard.warning
State variants:
- Scout Reveal: phase=Scout — Tap walkable revealed floor to scout; discovery reveals nearby map.
- Route Incomplete: phase=RouteEdit && route incomplete — Live path and budget visible.
- Route Valid: route connected && within budget && unblocked — Endpoint snap feedback.
- Blocked / Over Budget: route blocked or over budget — Invalid segment is broken preview.
- Haul Active: phase=Haul && !paused — Workers spawn at Game Design interval and follow active path.
- Hazard Warning: hazard warning active — Direction pulse + medium haptic; no automatic reroute.
Interactions:
- tap → walkable floor destination: set scout destination; state=scout moves; nearby map reveals; invalid=invalid/unwalkable destination does not move scout
- drag → route layer from nest or food: sample waypoints every 12px and preview path; state=route geometry/budget update; invalid=blocked segment becomes broken preview; dispatch disabled
- tap path then drag → waypoint: move waypoint; state=followers switch at next node when applicable; invalid=invalid placement remains broken preview
- long press → route segment: delete segment; state=route becomes incomplete; invalid=dispatch disabled until reconnected
- tap → Dispatch: start workers hauling; state=phase=Haul; invalid=disabled for incomplete/blocked/over-budget route
- tap → Pause: enter pause/route edit overlay; state=convoy.paused=true; invalid=disabled outside Haul
- two-finger pan → world: pan camera; state=camera offset changes; invalid=gesture wins over one-finger route edit
- one-finger pan → world background: pan camera; state=camera offset changes; invalid=ignored during route editing to protect path gesture
- two-finger tap → active route gesture: cancel gesture; state=restore pre-gesture route; invalid=none

### 4. Pause / Route Edit Overlay
Haul 중 convoy pause 상태에서 경로를 수정하고 재개.

Components:
- paused_world: Paused Room [context] box(0,0,100,72) · convoy.paused
- route_edit_proxy: Editable Route [editable_path] box(4,12,92,58) · route.state
- budget: Route Budget [meter] box(4,75,40,7) · route.budget
- resume: Resume [button] box(58,86,37,9) · route.valid
- cancel: Cancel Changes [button] box(5,86,42,9) · overlay
State variants:
- Invalid Edit: route invalid — Cannot resume onto invalid route.
Interactions:
- drag/long press → route edit proxy: apply same route edit semantics; state=route changes; invalid=invalid route disables Resume
- tap → Resume: close overlay and resume haul; state=convoy.paused=false; invalid=disabled if invalid
- tap → Cancel Changes: restore overlay-entry route and resume/return; state=route restored; invalid=none

### 5. Result
성공/실패와 음식·생존·시간·예산 기반 정산을 보여주고 다음 행동 제공.

Components:
- outcome: Success / Failure [status] box(15,10,70,12) · result.outcome
- score: Score [large_number] box(20,28,60,12) · result.score
- breakdown: Food / Survivors / Time / Budget [list] box(12,43,76,24) · result.breakdown
- retry: Retry [button] box(8,78,38,10) · result
- next: Next [button] box(54,78,38,10) · progress.next
State variants:
- Failure Result: result failure — Retry remains available.
Interactions:
- tap → Retry: restart selected mission at Brief; state=round reset; invalid=none
- tap → Next: select next mission; state=selected mission changes; invalid=disabled if unavailable

## Global States
- hazard_warning: source hazard warning active → warning banner + direction pulse + medium haptic
- route_invalid: blocked/over-budget/incomplete → broken preview + Dispatch disabled
- round_end: target delivered OR time expired OR no transport-capable ants → input locks then Result

## Input Map
```json
{
  "priority": [
    "UI",
    "waypoint",
    "path",
    "world"
  ],
  "gestures": {
    "tap": [
      "scout destination",
      "Dispatch",
      "Pause"
    ],
    "drag": [
      "draw route",
      "drag waypoint"
    ],
    "long_press": [
      "delete route segment"
    ],
    "two_finger_pan": [
      "camera always"
    ],
    "one_finger_pan": [
      "camera outside route edit"
    ],
    "two_finger_tap": [
      "cancel active route gesture"
    ]
  },
  "conflicts": "two-finger camera gesture overrides single-finger world/path recognition; waypoint hit wins over path",
  "cancel": "two-finger tap or return gesture to start",
  "multitouch": "camera pan supported; path editing remains single-touch"
}
```

## Global Edge Cases
```json
{
  "invalid_route": "broken preview; Dispatch disabled",
  "blocked_route": "warning; no automatic reroute",
  "camera_vs_edit": "one-finger pan disabled during route edit",
  "pause_edit": "Resume disabled until route valid",
  "round_failure": "time expiry or no transport-capable ants transitions to Result"
}
```

## Developer Handoff
```json
{
  "scene_hierarchy": [
    "App",
    "MissionSelect",
    "MissionBrief",
    "ApartmentRoom{HUD,World,RouteLayer,HazardLayer,ConvoyLayer,Controls}",
    "PauseRouteOverlay",
    "Result"
  ],
  "reusable_components": [
    "MissionCard",
    "GoalHUD",
    "WorldEntity",
    "EditablePath",
    "WaypointHandle",
    "HazardOverlay",
    "ConvoyAgent",
    "PrimaryAction",
    "ResultStat"
  ],
  "required_data": [
    "room mission layout",
    "nest/food positions",
    "walkable floor/reveal data",
    "hazard state/pattern from Game Design content",
    "route budget",
    "12 worker agents",
    "timer/score/combo"
  ],
  "state_ownership": {
    "round": "RoundController",
    "phase": "PhaseState",
    "route": "RouteController",
    "camera": "CameraController",
    "convoy": "ConvoyController",
    "hazard": "HazardController"
  },
  "persistence": [
    "mission unlock/star progression if configured"
  ],
  "implementation_order": [
    "room + fog/reveal",
    "route drawing/edit/validity",
    "camera/input arbitration",
    "convoy path following + delivery",
    "hazard state visualization + pause edit",
    "score/result",
    "selection/brief"
  ],
  "notes": [
    "Do not invent hazard collision/loss semantics absent from source; HazardController consumes mission-defined rule data.",
    "Use lightweight agent following to target 12 agents at 60fps."
  ]
}
```

## Acceptance Criteria
- 첫 사용자가 30초 내 Scout에서 food를 발견하고 유효 route 생성 흐름을 이해할 수 있다.
- 경로 draw/edit/delete가 UI > waypoint > path > world 우선순위대로 충돌 없이 동작한다.
- 불완전/blocked/over-budget 경로는 시각적으로 구분되고 Dispatch가 비활성화된다.
- 유효 경로 Dispatch 후 12 workers가 설정된 경로를 따라 운반 상태에 들어간다.
- Haul 중 Pause에서 route를 수정할 수 있고 invalid route에서는 Resume할 수 없다.
- 2초 hazard warning 상태는 banner/direction pulse/haptic으로 표시되며 자동 reroute하지 않는다.
- 성공/실패 조건이 Result로 연결되고 Retry/Next 흐름에 막다른 지점이 없다.
- 모바일에서 12 agents 기준 목표 60fps 검증이 가능하다.
