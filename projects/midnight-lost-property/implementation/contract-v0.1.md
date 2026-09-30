# Midnight Lost Property — Implementation Contract v1.1

Atomic requirements compiled from the current Game Design and Wireframe Pack.

## ACC:1
- Category: acceptance
- Source: `/source/pack/acceptance_criteria/0`
- Verification mode: `manual_playtest`

```json
"8개 화면이 정의된 흐름대로 이동한다"
```

## ACC:2
- Category: acceptance
- Source: `/source/pack/acceptance_criteria/1`
- Verification mode: `manual_playtest`

```json
"Inspection에서 drag/pinch/hotspot이 충돌 없이 동작한다"
```

## ACC:3
- Category: acceptance
- Source: `/source/pack/acceptance_criteria/2`
- Verification mode: `manual_playtest`

```json
"질문 예산이 3→0으로 감소하고 0에서 추가 질문이 차단된다"
```

## ACC:4
- Category: acceptance
- Source: `/source/pack/acceptance_criteria/3`
- Verification mode: `manual_playtest`

```json
"단서 카드를 long-press drag하여 두 비교 슬롯에 배치할 수 있다"
```

## ACC:5
- Category: acceptance
- Source: `/source/pack/acceptance_criteria/4`
- Verification mode: `manual_playtest`

```json
"단서 2개 미만이면 Decision 확정이 불가능하다"
```

## ACC:6
- Category: acceptance
- Source: `/source/pack/acceptance_criteria/5`
- Verification mode: `manual_playtest`

```json
"RETURN/HOLD/REPORT 선택 뒤 confirm swipe 완료 시 판정이 잠긴다"
```

## ACC:7
- Category: acceptance
- Source: `/source/pack/acceptance_criteria/6`
- Verification mode: `manual_playtest`

```json
"세 번째 Outcome 뒤 Shift Summary로 이동한다"
```

## ARC:implementation_order
- Category: architecture
- Source: `/source/pack/developer_handoff/implementation_order`
- Verification mode: `static`

```json
[
  "navigation/state machine",
  "inspection gestures",
  "evidence tray",
  "interview budget",
  "compare drag-drop",
  "decision lock",
  "outcome/summary"
]
```

## ARC:persistence
- Category: architecture
- Source: `/source/pack/developer_handoff/persistence`
- Verification mode: `static`

```json
"shift progress only"
```

## ARC:required_data
- Category: architecture
- Source: `/source/pack/developer_handoff/required_data`
- Verification mode: `static`

```json
[
  "CaseData",
  "EvidenceData",
  "VisitorData",
  "DecisionRule"
]
```

## ARC:reusable
- Category: architecture
- Source: `/source/pack/developer_handoff/reusable`
- Verification mode: `static`

```json
[
  "EvidenceCard",
  "PrimaryButton",
  "StatusChip",
  "DragDropSlot",
  "ConfirmRail"
]
```

## ARC:scene_hierarchy
- Category: architecture
- Source: `/source/pack/developer_handoff/scene_hierarchy`
- Verification mode: `static`

```json
[
  "AppRoot",
  "ShiftController",
  "CaseSceneRouter",
  "HUDLayer",
  "ModalLayer"
]
```

## ARC:state_owner
- Category: architecture
- Source: `/source/pack/developer_handoff/state_owner`
- Verification mode: `static`

```json
"CaseSessionState"
```

## CMP:case_intake:case_meta
- Category: component
- Source: `/source/pack/screens/1/components/0`
- Verification mode: `static`

```json
{
  "id": "case_meta",
  "box": {
    "h": 11,
    "w": 82,
    "x": 9,
    "y": 8
  },
  "type": "panel",
  "label": "발견 장소 / 시간",
  "state_binding": ""
}
```

## CMP:case_intake:inspect_btn
- Category: component
- Source: `/source/pack/screens/1/components/2`
- Verification mode: `static`

```json
{
  "id": "inspect_btn",
  "box": {
    "h": 9,
    "w": 64,
    "x": 18,
    "y": 78
  },
  "type": "button",
  "label": "조사 시작",
  "state_binding": "intake"
}
```

## CMP:case_intake:item_preview
- Category: component
- Source: `/source/pack/screens/1/components/1`
- Verification mode: `static`

```json
{
  "id": "item_preview",
  "box": {
    "h": 36,
    "w": 64,
    "x": 18,
    "y": 28
  },
  "type": "object",
  "label": "분실물",
  "state_binding": ""
}
```

## CMP:decision_confirm:confirm_rail
- Category: component
- Source: `/source/pack/screens/5/components/4`
- Verification mode: `static`

```json
{
  "id": "confirm_rail",
  "box": {
    "h": 10,
    "w": 76,
    "x": 12,
    "y": 75
  },
  "type": "slider",
  "label": "밀어서 확정",
  "state_binding": "disabled|armed"
}
```

## CMP:decision_confirm:evidence_summary
- Category: component
- Source: `/source/pack/screens/5/components/0`
- Verification mode: `static`

```json
{
  "id": "evidence_summary",
  "box": {
    "h": 25,
    "w": 82,
    "x": 9,
    "y": 8
  },
  "type": "panel",
  "label": "근거 요약",
  "state_binding": ""
}
```

## CMP:decision_confirm:hold
- Category: component
- Source: `/source/pack/screens/5/components/2`
- Verification mode: `static`

```json
{
  "id": "hold",
  "box": {
    "h": 15,
    "w": 26,
    "x": 37,
    "y": 43
  },
  "type": "button",
  "label": "HOLD",
  "state_binding": ""
}
```

## CMP:decision_confirm:report
- Category: component
- Source: `/source/pack/screens/5/components/3`
- Verification mode: `static`

```json
{
  "id": "report",
  "box": {
    "h": 15,
    "w": 26,
    "x": 66,
    "y": 43
  },
  "type": "button",
  "label": "REPORT",
  "state_binding": ""
}
```

## CMP:decision_confirm:return
- Category: component
- Source: `/source/pack/screens/5/components/1`
- Verification mode: `static`

```json
{
  "id": "return",
  "box": {
    "h": 15,
    "w": 26,
    "x": 8,
    "y": 43
  },
  "type": "button",
  "label": "RETURN",
  "state_binding": ""
}
```

## CMP:evidence_review:decision_btn
- Category: component
- Source: `/source/pack/screens/4/components/4`
- Verification mode: `static`

```json
{
  "id": "decision_btn",
  "box": {
    "h": 7,
    "w": 60,
    "x": 20,
    "y": 89
  },
  "type": "button",
  "label": "판정하기",
  "state_binding": "clues>=2"
}
```

## CMP:evidence_review:evidence_cards
- Category: component
- Source: `/source/pack/screens/4/components/3`
- Verification mode: `static`

```json
{
  "id": "evidence_cards",
  "box": {
    "h": 18,
    "w": 84,
    "x": 8,
    "y": 65
  },
  "type": "tray",
  "label": "단서 카드",
  "state_binding": ""
}
```

## CMP:evidence_review:relation
- Category: component
- Source: `/source/pack/screens/4/components/2`
- Verification mode: `static`

```json
{
  "id": "relation",
  "box": {
    "h": 8,
    "w": 56,
    "x": 22,
    "y": 47
  },
  "type": "status",
  "label": "관계 결과",
  "state_binding": "none|match|conflict"
}
```

## CMP:evidence_review:slot_a
- Category: component
- Source: `/source/pack/screens/4/components/0`
- Verification mode: `static`

```json
{
  "id": "slot_a",
  "box": {
    "h": 20,
    "w": 32,
    "x": 12,
    "y": 23
  },
  "type": "dropzone",
  "label": "비교 A",
  "state_binding": "empty|filled"
}
```

## CMP:evidence_review:slot_b
- Category: component
- Source: `/source/pack/screens/4/components/1`
- Verification mode: `static`

```json
{
  "id": "slot_b",
  "box": {
    "h": 20,
    "w": 32,
    "x": 56,
    "y": 23
  },
  "type": "dropzone",
  "label": "비교 B",
  "state_binding": "empty|filled"
}
```

## CMP:inspection_desk:clue_tray
- Category: component
- Source: `/source/pack/screens/2/components/1`
- Verification mode: `static`

```json
{
  "id": "clue_tray",
  "box": {
    "h": 9,
    "w": 86,
    "x": 7,
    "y": 75
  },
  "type": "tray",
  "label": "단서 트레이",
  "state_binding": ""
}
```

## CMP:inspection_desk:interview_btn
- Category: component
- Source: `/source/pack/screens/2/components/2`
- Verification mode: `static`

```json
{
  "id": "interview_btn",
  "box": {
    "h": 7,
    "w": 40,
    "x": 54,
    "y": 89
  },
  "type": "button",
  "label": "방문객 질문",
  "state_binding": ""
}
```

## CMP:inspection_desk:object
- Category: component
- Source: `/source/pack/screens/2/components/0`
- Verification mode: `static`

```json
{
  "id": "object",
  "box": {
    "h": 45,
    "w": 76,
    "x": 12,
    "y": 19
  },
  "type": "manipulable",
  "label": "Lost Item",
  "state_binding": "idle|rotating|zoomed"
}
```

## CMP:inspection_desk:review_btn
- Category: component
- Source: `/source/pack/screens/2/components/3`
- Verification mode: `static`

```json
{
  "id": "review_btn",
  "box": {
    "h": 7,
    "w": 40,
    "x": 7,
    "y": 89
  },
  "type": "button",
  "label": "단서 대조",
  "state_binding": "clues>=2"
}
```

## CMP:night_desk:case_counter
- Category: component
- Source: `/source/pack/screens/0/components/1`
- Verification mode: `static`

```json
{
  "id": "case_counter",
  "box": {
    "h": 6,
    "w": 20,
    "x": 70,
    "y": 7
  },
  "type": "status",
  "label": "0 / 3 cases",
  "state_binding": ""
}
```

## CMP:night_desk:shift_title
- Category: component
- Source: `/source/pack/screens/0/components/0`
- Verification mode: `static`

```json
{
  "id": "shift_title",
  "box": {
    "h": 6,
    "w": 55,
    "x": 10,
    "y": 7
  },
  "type": "label",
  "label": "MIDNIGHT SHIFT",
  "state_binding": ""
}
```

## CMP:night_desk:start_shift
- Category: component
- Source: `/source/pack/screens/0/components/2`
- Verification mode: `static`

```json
{
  "id": "start_shift",
  "box": {
    "h": 9,
    "w": 64,
    "x": 18,
    "y": 83
  },
  "type": "button",
  "label": "근무 시작",
  "state_binding": "ready"
}
```

## CMP:outcome:continue
- Category: component
- Source: `/source/pack/screens/6/components/3`
- Verification mode: `static`

```json
{
  "id": "continue",
  "box": {
    "h": 8,
    "w": 60,
    "x": 20,
    "y": 84
  },
  "type": "button",
  "label": "계속",
  "state_binding": ""
}
```

## CMP:outcome:reason
- Category: component
- Source: `/source/pack/screens/6/components/1`
- Verification mode: `static`

```json
{
  "id": "reason",
  "box": {
    "h": 28,
    "w": 80,
    "x": 10,
    "y": 24
  },
  "type": "panel",
  "label": "왜 맞았나/틀렸나",
  "state_binding": ""
}
```

## CMP:outcome:result_stamp
- Category: component
- Source: `/source/pack/screens/6/components/0`
- Verification mode: `static`

```json
{
  "id": "result_stamp",
  "box": {
    "h": 12,
    "w": 50,
    "x": 25,
    "y": 9
  },
  "type": "status",
  "label": "판정 결과",
  "state_binding": ""
}
```

## CMP:outcome:score
- Category: component
- Source: `/source/pack/screens/6/components/2`
- Verification mode: `static`

```json
{
  "id": "score",
  "box": {
    "h": 12,
    "w": 64,
    "x": 18,
    "y": 61
  },
  "type": "status",
  "label": "점수 변화",
  "state_binding": ""
}
```

## CMP:shift_summary:case_rows
- Category: component
- Source: `/source/pack/screens/7/components/1`
- Verification mode: `static`

```json
{
  "id": "case_rows",
  "box": {
    "h": 36,
    "w": 80,
    "x": 10,
    "y": 34
  },
  "type": "list",
  "label": "사건 3개 요약",
  "state_binding": ""
}
```

## CMP:shift_summary:finish
- Category: component
- Source: `/source/pack/screens/7/components/2`
- Verification mode: `static`

```json
{
  "id": "finish",
  "box": {
    "h": 8,
    "w": 60,
    "x": 20,
    "y": 83
  },
  "type": "button",
  "label": "근무 종료",
  "state_binding": ""
}
```

## CMP:shift_summary:grade
- Category: component
- Source: `/source/pack/screens/7/components/0`
- Verification mode: `static`

```json
{
  "id": "grade",
  "box": {
    "h": 15,
    "w": 44,
    "x": 28,
    "y": 10
  },
  "type": "status",
  "label": "근무 등급",
  "state_binding": ""
}
```

## CMP:visitor_interview:back_inspect
- Category: component
- Source: `/source/pack/screens/3/components/3`
- Verification mode: `static`

```json
{
  "id": "back_inspect",
  "box": {
    "h": 6,
    "w": 40,
    "x": 7,
    "y": 91
  },
  "type": "button",
  "label": "물건 다시 보기",
  "state_binding": ""
}
```

## CMP:visitor_interview:budget
- Category: component
- Source: `/source/pack/screens/3/components/1`
- Verification mode: `static`

```json
{
  "id": "budget",
  "box": {
    "h": 6,
    "w": 20,
    "x": 72,
    "y": 5
  },
  "type": "status",
  "label": "질문 3/3",
  "state_binding": ""
}
```

## CMP:visitor_interview:question_cards
- Category: component
- Source: `/source/pack/screens/3/components/2`
- Verification mode: `static`

```json
{
  "id": "question_cards",
  "box": {
    "h": 20,
    "w": 82,
    "x": 9,
    "y": 65
  },
  "type": "list",
  "label": "질문 카드",
  "state_binding": "budget>0"
}
```

## CMP:visitor_interview:review_btn
- Category: component
- Source: `/source/pack/screens/3/components/4`
- Verification mode: `static`

```json
{
  "id": "review_btn",
  "box": {
    "h": 6,
    "w": 40,
    "x": 53,
    "y": 91
  },
  "type": "button",
  "label": "단서 대조",
  "state_binding": "clues>=2"
}
```

## CMP:visitor_interview:visitor
- Category: component
- Source: `/source/pack/screens/3/components/0`
- Verification mode: `static`

```json
{
  "id": "visitor",
  "box": {
    "h": 27,
    "w": 50,
    "x": 25,
    "y": 8
  },
  "type": "portrait",
  "label": "방문객",
  "state_binding": ""
}
```

## CNT:mvp_scope
- Category: content
- Source: `/source/design/mvp_scope`
- Verification mode: `static`

```json
"세로 모바일 1개 밤, 완성 사건 5개, 물건 회전/확대/hotspot, 질문 예산, 단서 카드 비교, RETURN/HOLD/REPORT, Outcome, Shift Summary."
```

## CNT:screen_inventory
- Category: content
- Source: `/source/design/screen_inventory`
- Verification mode: `static`

```json
[
  "Night Desk — 근무 시작",
  "Case Intake — 발견 정보",
  "Inspection Desk — 물건 조사",
  "Visitor Interview — 제한 질문",
  "Evidence Review — 단서 대조",
  "Decision Confirm — 조치 확인",
  "Outcome — 결과",
  "Shift Summary — 3사건 요약"
]
```

## GST:decision_locked
- Category: global_state
- Source: `/source/pack/global_states/2`
- Verification mode: `static`

```json
{
  "id": "decision_locked",
  "rule": "판정 후 back/수정 금지"
}
```

## GST:loading
- Category: global_state
- Source: `/source/pack/global_states/0`
- Verification mode: `static`

```json
{
  "id": "loading",
  "rule": "사건 데이터 준비 중 입력 차단"
}
```

## GST:pause
- Category: global_state
- Source: `/source/pack/global_states/1`
- Verification mode: `static`

```json
{
  "id": "pause",
  "rule": "현재 사건 상태 보존"
}
```

## INP:1
- Category: input_map
- Source: `/source/pack/input_map/0`
- Verification mode: `manual_playtest`

```json
{
  "use": "hotspot/questions/choices/buttons",
  "input": "tap",
  "priority": 3
}
```

## INP:2
- Category: input_map
- Source: `/source/pack/input_map/1`
- Verification mode: `manual_playtest`

```json
{
  "use": "evidence cards",
  "input": "long-press drag",
  "priority": 4
}
```

## INP:3
- Category: input_map
- Source: `/source/pack/input_map/2`
- Verification mode: `manual_playtest`

```json
{
  "use": "object rotation",
  "input": "drag",
  "priority": 2
}
```

## INP:4
- Category: input_map
- Source: `/source/pack/input_map/3`
- Verification mode: `manual_playtest`

```json
{
  "use": "object zoom",
  "input": "pinch",
  "priority": 5
}
```

## INP:5
- Category: input_map
- Source: `/source/pack/input_map/4`
- Verification mode: `manual_playtest`

```json
{
  "use": "irreversible decision",
  "input": "horizontal confirm swipe",
  "priority": 5
}
```

## INT:case_intake:1
- Category: interaction
- Source: `/source/pack/screens/1/interactions/0`
- Verification mode: `manual_playtest`

```json
{
  "action": "Inspection 진입",
  "target": "inspect_btn",
  "trigger": "tap",
  "feedback": "fade + light haptic",
  "precondition": "case loaded",
  "state_change": "Inspection",
  "invalid_input": "로딩 중 입력 차단"
}
```

## INT:decision_confirm:1
- Category: interaction
- Source: `/source/pack/screens/5/interactions/0`
- Verification mode: `manual_playtest`

```json
{
  "action": "조치 선택",
  "target": "decision buttons",
  "trigger": "tap",
  "feedback": "selected outline",
  "precondition": "clues>=2",
  "state_change": "selected",
  "invalid_input": "근거 부족이면 Review 안내"
}
```

## INT:decision_confirm:2
- Category: interaction
- Source: `/source/pack/screens/5/interactions/1`
- Verification mode: `manual_playtest`

```json
{
  "action": "판정 잠금",
  "target": "confirm_rail",
  "trigger": "horizontal swipe",
  "feedback": "stamp + rigid haptic",
  "precondition": "decision selected",
  "state_change": "locked",
  "invalid_input": "중간 release면 rail reset"
}
```

## INT:evidence_review:1
- Category: interaction
- Source: `/source/pack/screens/4/interactions/0`
- Verification mode: `manual_playtest`

```json
{
  "action": "슬롯에 배치",
  "target": "evidence_card",
  "trigger": "long-press drag",
  "feedback": "slot highlight",
  "precondition": "card available",
  "state_change": "one_slot|comparing",
  "invalid_input": "중복 카드면 원위치"
}
```

## INT:evidence_review:2
- Category: interaction
- Source: `/source/pack/screens/4/interactions/1`
- Verification mode: `manual_playtest`

```json
{
  "action": "관계 계산/기록",
  "target": "slot",
  "trigger": "drop",
  "feedback": "line + medium haptic",
  "precondition": "two unique clues",
  "state_change": "relation_recorded",
  "invalid_input": "부적합 drop bounce"
}
```

## INT:inspection_desk:1
- Category: interaction
- Source: `/source/pack/screens/2/interactions/0`
- Verification mode: `manual_playtest`

```json
{
  "action": "물건 회전",
  "target": "object",
  "trigger": "drag",
  "feedback": "surface moves",
  "precondition": "Inspection",
  "state_change": "rotating",
  "invalid_input": "viewport 밖 drag는 clamp"
}
```

## INT:inspection_desk:2
- Category: interaction
- Source: `/source/pack/screens/2/interactions/1`
- Verification mode: `manual_playtest`

```json
{
  "action": "확대/축소",
  "target": "object",
  "trigger": "pinch",
  "feedback": "scale feedback",
  "precondition": "Inspection",
  "state_change": "zoomed",
  "invalid_input": "min/max clamp"
}
```

## INT:inspection_desk:3
- Category: interaction
- Source: `/source/pack/screens/2/interactions/2`
- Verification mode: `manual_playtest`

```json
{
  "action": "단서 카드 생성",
  "target": "hotspot",
  "trigger": "tap",
  "feedback": "ring + card pop + light haptic",
  "precondition": "hotspot active",
  "state_change": "hotspot_revealed",
  "invalid_input": "비 hotspot은 약한 경계 반응"
}
```

## INT:night_desk:1
- Category: interaction
- Source: `/source/pack/screens/0/interactions/0`
- Verification mode: `manual_playtest`

```json
{
  "action": "첫 사건 로드",
  "target": "start_shift",
  "trigger": "tap",
  "feedback": "button depress + light haptic",
  "precondition": "ready",
  "state_change": "Intake",
  "invalid_input": "중복 tap 무시"
}
```

## INT:outcome:1
- Category: interaction
- Source: `/source/pack/screens/6/interactions/0`
- Verification mode: `manual_playtest`

```json
{
  "action": "다음 사건 또는 요약",
  "target": "continue",
  "trigger": "tap",
  "feedback": "success/neutral haptic",
  "precondition": "outcome shown",
  "state_change": "complete",
  "invalid_input": "연타 무시"
}
```

## INT:shift_summary:1
- Category: interaction
- Source: `/source/pack/screens/7/interactions/0`
- Verification mode: `manual_playtest`

```json
{
  "action": "Night Desk 복귀",
  "target": "finish",
  "trigger": "tap",
  "feedback": "fade",
  "precondition": "summary",
  "state_change": "ready",
  "invalid_input": "none"
}
```

## INT:visitor_interview:1
- Category: interaction
- Source: `/source/pack/screens/3/interactions/0`
- Verification mode: `manual_playtest`

```json
{
  "action": "질문 소비·응답 단서 생성",
  "target": "question_card",
  "trigger": "tap",
  "feedback": "핵심 구절 강조",
  "precondition": "budget>0",
  "state_change": "answering",
  "invalid_input": "budget=0이면 잠금 사유 표시"
}
```

## RUL:clues
- Category: rule
- Source: `/source/design/game_rules/clues`
- Verification mode: `static`

```json
"3~5, 결정 최소 2"
```

## RUL:decisions
- Category: rule
- Source: `/source/design/game_rules/decisions`
- Verification mode: `static`

```json
[
  "RETURN",
  "HOLD",
  "REPORT"
]
```

## RUL:grades
- Category: rule
- Source: `/source/design/game_rules/grades`
- Verification mode: `static`

```json
{
  "A": 280,
  "B": 220,
  "C": 0,
  "S": 330
}
```

## RUL:principle
- Category: rule
- Source: `/source/design/game_rules/principle`
- Verification mode: `static`

```json
"소유주 맞히기가 아니라 증거 수준에 맞는 조치를 고른다."
```

## RUL:questions
- Category: rule
- Source: `/source/design/game_rules/questions`
- Verification mode: `static`

```json
"기본 3회"
```

## RUL:score
- Category: rule
- Source: `/source/design/game_rules/score`
- Verification mode: `static`

```json
{
  "correct": 100,
  "false_report": -25,
  "reckless_return": -40,
  "supported_reason": 30,
  "unnecessary_question": -5
}
```

## STA:case_intake:intake
- Category: state
- Source: `/source/pack/screens/1/states/0`
- Verification mode: `static`

```json
"intake"
```

## STA:decision_confirm:blocked
- Category: state
- Source: `/source/pack/screens/5/states/4`
- Verification mode: `static`

```json
"blocked"
```

## STA:decision_confirm:confirming
- Category: state
- Source: `/source/pack/screens/5/states/2`
- Verification mode: `static`

```json
"confirming"
```

## STA:decision_confirm:locked
- Category: state
- Source: `/source/pack/screens/5/states/3`
- Verification mode: `static`

```json
"locked"
```

## STA:decision_confirm:selected
- Category: state
- Source: `/source/pack/screens/5/states/1`
- Verification mode: `static`

```json
"selected"
```

## STA:decision_confirm:unselected
- Category: state
- Source: `/source/pack/screens/5/states/0`
- Verification mode: `static`

```json
"unselected"
```

## STA:evidence_review:comparing
- Category: state
- Source: `/source/pack/screens/4/states/2`
- Verification mode: `static`

```json
"comparing"
```

## STA:evidence_review:empty
- Category: state
- Source: `/source/pack/screens/4/states/0`
- Verification mode: `static`

```json
"empty"
```

## STA:evidence_review:one_slot
- Category: state
- Source: `/source/pack/screens/4/states/1`
- Verification mode: `static`

```json
"one_slot"
```

## STA:evidence_review:relation_recorded
- Category: state
- Source: `/source/pack/screens/4/states/3`
- Verification mode: `static`

```json
"relation_recorded"
```

## STA:inspection_desk:hotspot_revealed
- Category: state
- Source: `/source/pack/screens/2/states/3`
- Verification mode: `static`

```json
"hotspot_revealed"
```

## STA:inspection_desk:idle
- Category: state
- Source: `/source/pack/screens/2/states/0`
- Verification mode: `static`

```json
"idle"
```

## STA:inspection_desk:rotating
- Category: state
- Source: `/source/pack/screens/2/states/1`
- Verification mode: `static`

```json
"rotating"
```

## STA:inspection_desk:zoomed
- Category: state
- Source: `/source/pack/screens/2/states/2`
- Verification mode: `static`

```json
"zoomed"
```

## STA:night_desk:ready
- Category: state
- Source: `/source/pack/screens/0/states/0`
- Verification mode: `static`

```json
"ready"
```

## STA:outcome:complete
- Category: state
- Source: `/source/pack/screens/6/states/2`
- Verification mode: `static`

```json
"complete"
```

## STA:outcome:correct
- Category: state
- Source: `/source/pack/screens/6/states/0`
- Verification mode: `static`

```json
"correct"
```

## STA:outcome:incorrect
- Category: state
- Source: `/source/pack/screens/6/states/1`
- Verification mode: `static`

```json
"incorrect"
```

## STA:shift_summary:summary
- Category: state
- Source: `/source/pack/screens/7/states/0`
- Verification mode: `static`

```json
"summary"
```

## STA:visitor_interview:answering
- Category: state
- Source: `/source/pack/screens/3/states/1`
- Verification mode: `static`

```json
"answering"
```

## STA:visitor_interview:budget_empty
- Category: state
- Source: `/source/pack/screens/3/states/2`
- Verification mode: `static`

```json
"budget_empty"
```

## STA:visitor_interview:question_ready
- Category: state
- Source: `/source/pack/screens/3/states/0`
- Verification mode: `static`

```json
"question_ready"
```

## TRN:case_intake:1
- Category: transition
- Source: `/source/pack/screens/1/transitions/0`
- Verification mode: `static`

```json
{
  "to": "inspection",
  "from": "intake",
  "trigger": "tap inspect_btn",
  "animation": "short fade",
  "condition": "always"
}
```

## TRN:decision_confirm:1
- Category: transition
- Source: `/source/pack/screens/5/transitions/0`
- Verification mode: `static`

```json
{
  "to": "outcome",
  "from": "decision_confirm",
  "trigger": "confirm complete",
  "animation": "short fade",
  "condition": "always"
}
```

## TRN:evidence_review:1
- Category: transition
- Source: `/source/pack/screens/4/transitions/0`
- Verification mode: `static`

```json
{
  "to": "decision_confirm",
  "from": "evidence_review",
  "trigger": "tap decision_btn",
  "animation": "short fade",
  "condition": "clues>=2"
}
```

## TRN:inspection_desk:1
- Category: transition
- Source: `/source/pack/screens/2/transitions/0`
- Verification mode: `static`

```json
{
  "to": "visitor_interview",
  "from": "inspection",
  "trigger": "tap interview_btn",
  "animation": "short fade",
  "condition": "always"
}
```

## TRN:inspection_desk:2
- Category: transition
- Source: `/source/pack/screens/2/transitions/1`
- Verification mode: `static`

```json
{
  "to": "evidence_review",
  "from": "inspection",
  "trigger": "tap review_btn",
  "animation": "short fade",
  "condition": "clues>=2"
}
```

## TRN:night_desk:1
- Category: transition
- Source: `/source/pack/screens/0/transitions/0`
- Verification mode: `static`

```json
{
  "to": "case_intake",
  "from": "ready",
  "trigger": "tap start_shift",
  "animation": "short fade",
  "condition": "always"
}
```

## TRN:outcome:1
- Category: transition
- Source: `/source/pack/screens/6/transitions/0`
- Verification mode: `static`

```json
{
  "to": "case_intake",
  "from": "outcome",
  "trigger": "tap continue",
  "animation": "short fade",
  "condition": "case_index<3"
}
```

## TRN:outcome:2
- Category: transition
- Source: `/source/pack/screens/6/transitions/1`
- Verification mode: `static`

```json
{
  "to": "shift_summary",
  "from": "outcome",
  "trigger": "tap continue",
  "animation": "short fade",
  "condition": "case_index=3"
}
```

## TRN:shift_summary:1
- Category: transition
- Source: `/source/pack/screens/7/transitions/0`
- Verification mode: `static`

```json
{
  "to": "night_desk",
  "from": "shift_summary",
  "trigger": "tap finish",
  "animation": "short fade",
  "condition": "always"
}
```

## TRN:visitor_interview:1
- Category: transition
- Source: `/source/pack/screens/3/transitions/0`
- Verification mode: `static`

```json
{
  "to": "inspection",
  "from": "visitor_interview",
  "trigger": "tap back_inspect",
  "animation": "short fade",
  "condition": "return_count<1"
}
```

## TRN:visitor_interview:2
- Category: transition
- Source: `/source/pack/screens/3/transitions/1`
- Verification mode: `static`

```json
{
  "to": "evidence_review",
  "from": "visitor_interview",
  "trigger": "tap review_btn",
  "animation": "short fade",
  "condition": "clues>=2"
}
```
