# Parcel X-Ray Night Shift — Interaction Wireframe Pack v0.2

## Pack Overview
Mobile portrait. Core Screen: X-Ray Inspection Table

## Interaction Principles
- 검사 대상이 화면의 최대 조작 면적을 차지
- scan rail은 우측 전용 시작 영역
- 분류 drag가 회전보다 우선
- 오입력은 점수보다 즉시 복구 피드백

## Screen Flow
{
  "normal": [
    "night_hub",
    "parcel_intake",
    "inspection",
    "classification_result",
    "parcel_intake|shift_summary",
    "night_hub"
  ],
  "branches": [
    "inspection→rule_manual→inspection",
    "inspection invalid lane drop→inspection"
  ],
  "guards": [
    "result only after valid lane release",
    "summary after 8 cases"
  ]
}

## Screens
### 1. Night Hub / Shift Select
Purpose: Shift 선택과 시작
Components: shift_card, start_shift
States: hub
Variants: None
Interactions: tap → start_shift

### 2. Parcel Intake
Purpose: 외부 라벨과 현재 규칙을 읽고 검사 시작
Components: case_counter, label_card, rule_chips, begin_inspect
States: intake
Variants: None
Interactions: tap → begin_inspect

### 3. X-Ray Inspection Table
Purpose: 회전·단면 스캔·핀·3레인 분류가 일어나는 핵심 화면
Components: case_rule, scan_count, manual_btn, xray_box, scan_plane, scan_rail, pin_tray, pass_lane, repack_lane, isolate_lane
States: inspect, classifying
Variants: ROTATING, SCANNING, CLASSIFYING, LOCKED
Interactions: 1-finger drag → xray_box; vertical swipe → scan_rail; tap → visible internal shape in xray_box; drag-release → xray_box → pass_lane/repack_lane/isolate_lane

### 4. Classification Result
Purpose: 판정·근거·점수를 즉시 설명
Components: stamp, score_delta, evidence_replay, reason, continue
States: result
Variants: None
Interactions: tap → continue

### 5. Shift Summary
Purpose: 8개 처리 성과 요약
Components: grade, accuracy, critical, efficiency, next
States: summary
Variants: None
Interactions: tap → next

### 6. Rule Manual Overlay
Purpose: Inspect 중 규칙 재확인
Components: modal_scrim, rule_panel, close_rule
States: rule_overlay
Variants: None
Interactions: tap → close_rule

### 7. Pause
Purpose: 일시정지와 재개
Components: pause_scrim, resume, quit
States: paused
Variants: None
Interactions: tap → resume; tap → quit

## Global States
[
  {
    "id": "input_lock",
    "rule": "valid classification release through result reveal"
  },
  {
    "id": "paused",
    "rule": "freeze shift state"
  }
]

## Input Map
[
  {
    "use": "classify",
    "input": "drag-release",
    "priority": 5
  },
  {
    "use": "scan",
    "input": "rail swipe",
    "priority": 4
  },
  {
    "use": "rotate",
    "input": "drag",
    "priority": 3
  },
  {
    "use": "pin",
    "input": "tap",
    "priority": 2
  }
]

## Edge Cases
[
  {
    "case": "pointer lost",
    "recovery": "keep last pose/value"
  },
  {
    "case": "invalid lane",
    "recovery": "spring parcel to table"
  }
]

## Developer Handoff
{
  "scene_hierarchy": [
    "AppRoot",
    "ShiftController",
    "CaseRouter",
    "HUDLayer",
    "OverlayLayer"
  ],
  "reusable_components": [
    "ParcelView",
    "ScanRail",
    "EvidencePin",
    "DropLane",
    "RuleChip",
    "ResultStamp"
  ],
  "required_data": [
    "ParcelCase",
    "HazardRules",
    "ShiftProgress"
  ],
  "state_ownership": "ShiftController owns case index/score; Inspection owns transient gesture state",
  "persistence": "shift progress only",
  "implementation_order": [
    "navigation/state",
    "parcel rotation",
    "slice scan",
    "pins",
    "classification drag",
    "result evaluator",
    "summary"
  ]
}

## Acceptance Criteria
- 7개 inventory 화면/overlay가 모두 이동 가능
- Inspection에서 rotate/scan/pin/classify가 서로 충돌 없이 작동
- 유효 레인 밖 release는 table로 복귀
- Rule Manual은 background 입력을 차단
- valid lane release 후 result까지 gameplay 입력 잠금
- 8개 처리 후 Summary로 이동
