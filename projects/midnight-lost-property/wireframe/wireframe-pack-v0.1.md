# Midnight Lost Property — Interaction Wireframe Pack v0.1

## Pack Overview
Target: Mobile / portrait
Primary Interaction: 물건 회전·핀치·hotspot 조사 + 단서 long-press drag 비교 + 판정 confirm swipe
Core Screen: Inspection Desk

## Interaction Principles
- 물건 조사 영역을 화면의 최우선 터치 공간으로 유지
- 읽기보다 조작→단서 생성→비교 순서를 시각적으로 강조
- 되돌릴 수 없는 판정은 tap 선택 뒤 별도 confirm swipe로 분리
- 질문 예산·단서 수·현재 단계는 항상 가시화

## Screen Flow
{
  "normal": [
    "night_desk",
    "case_intake",
    "inspection_desk",
    "visitor_interview",
    "evidence_review",
    "decision_confirm",
    "outcome"
  ],
  "loop": "outcome→case_intake until 3 cases",
  "finish": "third outcome→shift_summary",
  "exception": "inspection↔visitor_interview once; decision blocked below 2 clues"
}

## Screens
### 01. Night Desk
Purpose: 근무 시작과 오늘 사건 수 확인
States: ready
Regions: [{"id":"header","label":"Shift Header","x":5,"y":4,"w":90,"h":9,"role":"shift metadata"},{"id":"desk","label":"Night Desk","x":7,"y":17,"w":86,"h":58,"role":"primary scene"},{"id":"footer","label":"Start Area","x":7,"y":80,"w":86,"h":14,"role":"primary action"}]
Components: [{"id":"shift_title","label":"MIDNIGHT SHIFT","type":"label","box":{"x":10,"y":7,"w":55,"h":6},"state_binding":""},{"id":"case_counter","label":"0 / 3 cases","type":"status","box":{"x":70,"y":7,"w":20,"h":6},"state_binding":""},{"id":"start_shift","label":"근무 시작","type":"button","box":{"x":18,"y":83,"w":64,"h":9},"state_binding":"ready"}]
Interactions: [{"trigger":"tap","target":"start_shift","precondition":"ready","action":"첫 사건 로드","state_change":"Intake","feedback":"button depress + light haptic","invalid_input":"중복 tap 무시"}]
Transitions: [{"from":"ready","to":"case_intake","trigger":"tap start_shift","condition":"always","animation":"short fade"}]
Feedback: ["짧은 역 안내음"]
Edge Cases: []
Implementation Notes: ["Control 기반 세로 레이아웃","ShiftController가 case index 소유"]

### 02. Case Intake
Purpose: 발견 장소·시간을 읽고 조사 시작
States: intake
Regions: [{"id":"meta","label":"Case Meta","x":6,"y":5,"w":88,"h":16,"role":"case facts"},{"id":"item","label":"Item Preview","x":10,"y":25,"w":80,"h":43,"role":"lost item preview"},{"id":"action","label":"Action","x":8,"y":74,"w":84,"h":18,"role":"continue"}]
Components: [{"id":"case_meta","label":"발견 장소 / 시간","type":"panel","box":{"x":9,"y":8,"w":82,"h":11},"state_binding":""},{"id":"item_preview","label":"분실물","type":"object","box":{"x":18,"y":28,"w":64,"h":36},"state_binding":""},{"id":"inspect_btn","label":"조사 시작","type":"button","box":{"x":18,"y":78,"w":64,"h":9},"state_binding":"intake"}]
Interactions: [{"trigger":"tap","target":"inspect_btn","precondition":"case loaded","action":"Inspection 진입","state_change":"Inspection","feedback":"fade + light haptic","invalid_input":"로딩 중 입력 차단"}]
Transitions: [{"from":"intake","to":"inspection","trigger":"tap inspect_btn","condition":"always","animation":"short fade"}]
Feedback: []
Edge Cases: ["사건 데이터 누락 시 시작 비활성"]
Implementation Notes: ["CaseData 바인딩"]

### 03. Inspection Desk
Purpose: 물건을 회전·확대하고 hotspot에서 물리 단서 획득
States: idle, rotating, zoomed, hotspot_revealed
Regions: [{"id":"meta","label":"Case Meta","x":4,"y":3,"w":92,"h":8,"role":"persistent meta"},{"id":"viewport","label":"Object Viewport","x":4,"y":13,"w":92,"h":58,"role":"primary manipulation"},{"id":"tray","label":"Evidence Tray","x":4,"y":73,"w":92,"h":13,"role":"clues"},{"id":"nav","label":"Mode Nav","x":4,"y":88,"w":92,"h":9,"role":"next/back"}]
Components: [{"id":"object","label":"Lost Item","type":"manipulable","box":{"x":12,"y":19,"w":76,"h":45},"state_binding":"idle|rotating|zoomed"},{"id":"clue_tray","label":"단서 트레이","type":"tray","box":{"x":7,"y":75,"w":86,"h":9},"state_binding":""},{"id":"interview_btn","label":"방문객 질문","type":"button","box":{"x":54,"y":89,"w":40,"h":7},"state_binding":""},{"id":"review_btn","label":"단서 대조","type":"button","box":{"x":7,"y":89,"w":40,"h":7},"state_binding":"clues>=2"}]
Interactions: [{"trigger":"drag","target":"object","precondition":"Inspection","action":"물건 회전","state_change":"rotating","feedback":"surface moves","invalid_input":"viewport 밖 drag는 clamp"},{"trigger":"pinch","target":"object","precondition":"Inspection","action":"확대/축소","state_change":"zoomed","feedback":"scale feedback","invalid_input":"min/max clamp"},{"trigger":"tap","target":"hotspot","precondition":"hotspot active","action":"단서 카드 생성","state_change":"hotspot_revealed","feedback":"ring + card pop + light haptic","invalid_input":"비 hotspot은 약한 경계 반응"}]
Transitions: [{"from":"inspection","to":"visitor_interview","trigger":"tap interview_btn","condition":"always","animation":"short fade"},{"from":"inspection","to":"evidence_review","trigger":"tap review_btn","condition":"clues>=2","animation":"short fade"}]
Feedback: ["hotspot ring","clue card pop"]
Edge Cases: ["동일 hotspot 재수집 금지"]
Implementation Notes: ["SubViewport 또는 Control viewport","EvidenceTray 재사용"]

### 04. Visitor Interview
Purpose: 질문 예산 3회 안에서 진술 단서 획득
States: question_ready, answering, budget_empty
Regions: [{"id":"visitor","label":"Visitor","x":5,"y":5,"w":90,"h":35,"role":"speaker"},{"id":"statement","label":"Statement","x":7,"y":43,"w":86,"h":17,"role":"response"},{"id":"questions","label":"Questions","x":6,"y":63,"w":88,"h":25,"role":"choices"},{"id":"nav","label":"Nav","x":6,"y":90,"w":88,"h":7,"role":"return/review"}]
Components: [{"id":"visitor","label":"방문객","type":"portrait","box":{"x":25,"y":8,"w":50,"h":27},"state_binding":""},{"id":"budget","label":"질문 3/3","type":"status","box":{"x":72,"y":5,"w":20,"h":6},"state_binding":""},{"id":"question_cards","label":"질문 카드","type":"list","box":{"x":9,"y":65,"w":82,"h":20},"state_binding":"budget>0"},{"id":"back_inspect","label":"물건 다시 보기","type":"button","box":{"x":7,"y":91,"w":40,"h":6},"state_binding":""},{"id":"review_btn","label":"단서 대조","type":"button","box":{"x":53,"y":91,"w":40,"h":6},"state_binding":"clues>=2"}]
Interactions: [{"trigger":"tap","target":"question_card","precondition":"budget>0","action":"질문 소비·응답 단서 생성","state_change":"answering","feedback":"핵심 구절 강조","invalid_input":"budget=0이면 잠금 사유 표시"}]
Transitions: [{"from":"visitor_interview","to":"inspection","trigger":"tap back_inspect","condition":"return_count<1","animation":"short fade"},{"from":"visitor_interview","to":"evidence_review","trigger":"tap review_btn","condition":"clues>=2","animation":"short fade"}]
Feedback: ["answer highlight"]
Edge Cases: ["Inspection 복귀 1회 제한"]
Implementation Notes: ["QuestionBudget state machine"]

### 05. Evidence Review
Purpose: 물리/진술 단서를 두 슬롯에 놓아 일치·모순 관계 기록
States: empty, one_slot, comparing, relation_recorded
Regions: [{"id":"summary","label":"Case Summary","x":5,"y":4,"w":90,"h":10,"role":"context"},{"id":"board","label":"Compare Board","x":7,"y":17,"w":86,"h":43,"role":"comparison"},{"id":"tray","label":"Evidence Cards","x":5,"y":63,"w":90,"h":22,"role":"draggable cards"},{"id":"action","label":"Decision Entry","x":7,"y":88,"w":86,"h":9,"role":"continue"}]
Components: [{"id":"slot_a","label":"비교 A","type":"dropzone","box":{"x":12,"y":23,"w":32,"h":20},"state_binding":"empty|filled"},{"id":"slot_b","label":"비교 B","type":"dropzone","box":{"x":56,"y":23,"w":32,"h":20},"state_binding":"empty|filled"},{"id":"relation","label":"관계 결과","type":"status","box":{"x":22,"y":47,"w":56,"h":8},"state_binding":"none|match|conflict"},{"id":"evidence_cards","label":"단서 카드","type":"tray","box":{"x":8,"y":65,"w":84,"h":18},"state_binding":""},{"id":"decision_btn","label":"판정하기","type":"button","box":{"x":20,"y":89,"w":60,"h":7},"state_binding":"clues>=2"}]
Interactions: [{"trigger":"long-press drag","target":"evidence_card","precondition":"card available","action":"슬롯에 배치","state_change":"one_slot|comparing","feedback":"slot highlight","invalid_input":"중복 카드면 원위치"},{"trigger":"drop","target":"slot","precondition":"two unique clues","action":"관계 계산/기록","state_change":"relation_recorded","feedback":"line + medium haptic","invalid_input":"부적합 drop bounce"}]
Transitions: [{"from":"evidence_review","to":"decision_confirm","trigger":"tap decision_btn","condition":"clues>=2","animation":"short fade"}]
Feedback: ["match solid line / conflict broken line"]
Edge Cases: ["같은 카드 양 슬롯 금지"]
Implementation Notes: ["DragDropController 재사용"]

### 06. Decision Confirm
Purpose: RETURN/HOLD/REPORT 선택 후 스와이프로 판정 잠금
States: unselected, selected, confirming, locked, blocked
Regions: [{"id":"evidence","label":"Evidence Summary","x":6,"y":5,"w":88,"h":31,"role":"support"},{"id":"choices","label":"Decision Choices","x":6,"y":40,"w":88,"h":24,"role":"choice"},{"id":"confirm","label":"Confirm Rail","x":8,"y":72,"w":84,"h":18,"role":"irreversible confirm"}]
Components: [{"id":"evidence_summary","label":"근거 요약","type":"panel","box":{"x":9,"y":8,"w":82,"h":25},"state_binding":""},{"id":"return","label":"RETURN","type":"button","box":{"x":8,"y":43,"w":26,"h":15},"state_binding":""},{"id":"hold","label":"HOLD","type":"button","box":{"x":37,"y":43,"w":26,"h":15},"state_binding":""},{"id":"report","label":"REPORT","type":"button","box":{"x":66,"y":43,"w":26,"h":15},"state_binding":""},{"id":"confirm_rail","label":"밀어서 확정","type":"slider","box":{"x":12,"y":75,"w":76,"h":10},"state_binding":"disabled|armed"}]
Interactions: [{"trigger":"tap","target":"decision buttons","precondition":"clues>=2","action":"조치 선택","state_change":"selected","feedback":"selected outline","invalid_input":"근거 부족이면 Review 안내"},{"trigger":"horizontal swipe","target":"confirm_rail","precondition":"decision selected","action":"판정 잠금","state_change":"locked","feedback":"stamp + rigid haptic","invalid_input":"중간 release면 rail reset"}]
Transitions: [{"from":"decision_confirm","to":"outcome","trigger":"confirm complete","condition":"always","animation":"short fade"}]
Feedback: ["stamp"]
Edge Cases: ["확정 후 back 차단"]
Implementation Notes: ["DecisionController가 irreversible lock 소유"]

### 07. Outcome
Purpose: 판정의 결과·근거·점수를 이해하고 다음 사건으로 이동
States: correct, incorrect, complete
Regions: [{"id":"result","label":"Result","x":7,"y":5,"w":86,"h":50,"role":"explanation"},{"id":"score","label":"Score","x":10,"y":59,"w":80,"h":17,"role":"scoring"},{"id":"next","label":"Next","x":10,"y":82,"w":80,"h":12,"role":"continue"}]
Components: [{"id":"result_stamp","label":"판정 결과","type":"status","box":{"x":25,"y":9,"w":50,"h":12},"state_binding":""},{"id":"reason","label":"왜 맞았나/틀렸나","type":"panel","box":{"x":10,"y":24,"w":80,"h":28},"state_binding":""},{"id":"score","label":"점수 변화","type":"status","box":{"x":18,"y":61,"w":64,"h":12},"state_binding":""},{"id":"continue","label":"계속","type":"button","box":{"x":20,"y":84,"w":60,"h":8},"state_binding":""}]
Interactions: [{"trigger":"tap","target":"continue","precondition":"outcome shown","action":"다음 사건 또는 요약","state_change":"complete","feedback":"success/neutral haptic","invalid_input":"연타 무시"}]
Transitions: [{"from":"outcome","to":"case_intake","trigger":"tap continue","condition":"case_index<3","animation":"short fade"},{"from":"outcome","to":"shift_summary","trigger":"tap continue","condition":"case_index=3","animation":"short fade"}]
Feedback: ["score count"]
Edge Cases: []
Implementation Notes: ["OutcomePresenter"]

### 08. Shift Summary
Purpose: 3사건의 점수와 근무 등급 요약
States: summary
Regions: [{"id":"grade","label":"Grade","x":10,"y":6,"w":80,"h":22,"role":"shift grade"},{"id":"cases","label":"Cases","x":7,"y":31,"w":86,"h":43,"role":"case rows"},{"id":"footer","label":"Footer","x":10,"y":80,"w":80,"h":14,"role":"finish"}]
Components: [{"id":"grade","label":"근무 등급","type":"status","box":{"x":28,"y":10,"w":44,"h":15},"state_binding":""},{"id":"case_rows","label":"사건 3개 요약","type":"list","box":{"x":10,"y":34,"w":80,"h":36},"state_binding":""},{"id":"finish","label":"근무 종료","type":"button","box":{"x":20,"y":83,"w":60,"h":8},"state_binding":""}]
Interactions: [{"trigger":"tap","target":"finish","precondition":"summary","action":"Night Desk 복귀","state_change":"ready","feedback":"fade","invalid_input":"none"}]
Transitions: [{"from":"shift_summary","to":"night_desk","trigger":"tap finish","condition":"always","animation":"short fade"}]
Feedback: []
Edge Cases: []
Implementation Notes: ["ShiftSummaryData"]

## Global States
[
  {
    "id": "loading",
    "rule": "사건 데이터 준비 중 입력 차단"
  },
  {
    "id": "pause",
    "rule": "현재 사건 상태 보존"
  },
  {
    "id": "decision_locked",
    "rule": "판정 후 back/수정 금지"
  }
]

## Input Map
[
  {
    "input": "tap",
    "priority": 3,
    "use": "hotspot/questions/choices/buttons"
  },
  {
    "input": "long-press drag",
    "priority": 4,
    "use": "evidence cards"
  },
  {
    "input": "drag",
    "priority": 2,
    "use": "object rotation"
  },
  {
    "input": "pinch",
    "priority": 5,
    "use": "object zoom"
  },
  {
    "input": "horizontal confirm swipe",
    "priority": 5,
    "use": "irreversible decision"
  }
]

## Global Edge Cases
[
  {
    "case": "clues<2",
    "recovery": "Decision disabled; Review/Inspection 안내"
  },
  {
    "case": "question budget 0",
    "recovery": "cards disabled with reason"
  },
  {
    "case": "duplicate evidence",
    "recovery": "reject and return card"
  },
  {
    "case": "confirmed decision",
    "recovery": "no undo; proceed Outcome"
  }
]

## Developer Handoff
{
  "scene_hierarchy": [
    "AppRoot",
    "ShiftController",
    "CaseSceneRouter",
    "HUDLayer",
    "ModalLayer"
  ],
  "reusable": [
    "EvidenceCard",
    "PrimaryButton",
    "StatusChip",
    "DragDropSlot",
    "ConfirmRail"
  ],
  "required_data": [
    "CaseData",
    "EvidenceData",
    "VisitorData",
    "DecisionRule"
  ],
  "state_owner": "CaseSessionState",
  "persistence": "shift progress only",
  "implementation_order": [
    "navigation/state machine",
    "inspection gestures",
    "evidence tray",
    "interview budget",
    "compare drag-drop",
    "decision lock",
    "outcome/summary"
  ]
}

## Acceptance Criteria
- 8개 화면이 정의된 흐름대로 이동한다
- Inspection에서 drag/pinch/hotspot이 충돌 없이 동작한다
- 질문 예산이 3→0으로 감소하고 0에서 추가 질문이 차단된다
- 단서 카드를 long-press drag하여 두 비교 슬롯에 배치할 수 있다
- 단서 2개 미만이면 Decision 확정이 불가능하다
- RETURN/HOLD/REPORT 선택 뒤 confirm swipe 완료 시 판정이 잠긴다
- 세 번째 Outcome 뒤 Shift Summary로 이동한다
