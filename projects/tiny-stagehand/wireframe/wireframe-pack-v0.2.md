# Tiny Stagehand — Interaction Wireframe Pack v0.2

## Pack Overview
Mobile portrait. Core Screen: Live Performance

## Interaction Principles
- 무대 결과는 항상 상단에서 보임
- 컨트롤은 중단, cue 선읽기는 하단 고정
- active prop drag가 다른 drag보다 우선
- incident는 별도 미니게임이 아니라 동일 화면 overlay

## Screen Flow
{
  "normal": [
    "lobby",
    "briefing",
    "countdown",
    "live",
    "result",
    "lobby|briefing"
  ],
  "branches": [
    "live→pause→live",
    "live→cue_help→live",
    "incident is live variant"
  ],
  "guards": [
    "result on timeline end or continuity 0",
    "help/pause freeze timeline"
  ]
}

## Screens
### 1. Backstage Lobby / Scene Select
Purpose: Scene 선택
Components: scene_card, grade, select
States: lobby
Variants: None
Interactions: tap → select

### 2. Scene Briefing
Purpose: 장면 목표와 cue 종류 확인
Components: scene_title, goal, cue_types, start
States: briefing, countdown
Variants: COUNTDOWN
Interactions: tap → start

### 3. Live Performance
Purpose: 큐를 선읽기하며 조명·커튼·소품·사고를 동시에 운영
Components: continuity, time, pause_btn, stage_preview, actor, prop_mark, light_a, light_b, curtain_rope, prop_1, prop_2, prop_3, cue_now, cue_next, cue_future, help
States: performance, incident_focus
Variants: CUE WINDOW, PROP DRAG, INCIDENT, MISS FEEDBACK
Interactions: vertical drag → light_a/light_b; vertical drag → curtain_rope; 80ms hold then drag → prop_1/2/3 → prop_mark; tap/short drag → incident hotspot; tap → help

### 4. Pause Overlay
Purpose: 공연 정지/재개
Components: scrim, resume, quit
States: paused
Variants: None
Interactions: tap → resume

### 5. Performance Result
Purpose: cue별 결과와 Retry/Next 제공
Components: grade, continuity_final, accuracy, timeline, retry, next
States: result
Variants: None
Interactions: tap → retry; tap → next

### 6. Cue Help Overlay
Purpose: 큐 아이콘과 대응 컨트롤 빠른 확인
Components: scrim, help_panel, close
States: help
Variants: None
Interactions: tap → close

## Global States
[
  {
    "id": "paused",
    "rule": "freeze timeline and controls"
  },
  {
    "id": "input_lock",
    "rule": "countdown/result transition"
  }
]

## Input Map
[
  {
    "use": "prop",
    "input": "80ms hold+drag",
    "priority": 5
  },
  {
    "use": "curtain",
    "input": "vertical drag",
    "priority": 4
  },
  {
    "use": "light",
    "input": "vertical drag",
    "priority": 3
  },
  {
    "use": "incident",
    "input": "tap/short drag in hotspot",
    "priority": 4
  }
]

## Edge Cases
[
  {
    "case": "invalid prop drop",
    "recovery": "return tray"
  },
  {
    "case": "continuity 0",
    "recovery": "immediate result"
  }
]

## Developer Handoff
{
  "scene_hierarchy": [
    "AppRoot",
    "SceneController",
    "StagePreview",
    "BackstageControls",
    "CueStrip",
    "OverlayLayer"
  ],
  "reusable_components": [
    "CueChip",
    "Fader",
    "CurtainRope",
    "PropToken",
    "StageMark",
    "IncidentHotspot",
    "ContinuityMeter"
  ],
  "required_data": [
    "SceneCard",
    "CueEvent",
    "IncidentDefinition"
  ],
  "state_ownership": "SceneController owns timeline/continuity; each control owns pointer gesture",
  "persistence": "best grade/unlock only",
  "implementation_order": [
    "timeline/state",
    "cue strip",
    "faders",
    "curtain",
    "prop snap",
    "incident",
    "scoring/result"
  ]
}

## Acceptance Criteria
- 6개 inventory 화면/overlay가 모두 이동 가능
- Live 한 화면에서 stage/controls/cues가 동시에 보임
- fader/rope/prop gesture가 우선순위대로 충돌 없이 작동
- invalid prop drop은 tray로 복귀
- incident 중 normal controls 유지
- Pause/Cue Help에서 timeline 정지
- continuity 0 또는 timeline end에서 Result 이동
