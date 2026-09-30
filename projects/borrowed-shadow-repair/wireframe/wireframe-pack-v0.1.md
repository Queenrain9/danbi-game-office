# Borrowed Shadow Repair — Interaction Wireframe Pack v0.1

## Pack Overview
Target: Mobile / portrait
Primary Interaction: 조각 drag/회전/ghost snap + seam trace + 0.6초 Pose Test hold
Core Screen: Shadow Workbench

## Interaction Principles
- 중앙 작업대 60% 이상을 직접 조작 공간으로 확보
- drag가 기본, 회전은 two-finger와 15° 버튼을 동시에 제공
- snap 가능성은 놓기 전에 ghost로 예고
- 봉합과 테스트는 배치 단계와 모드를 분리해 오입력 방지
- 실패는 진행 차단보다 원인 위치를 보여주고 1회 Rework 제공

## Screen Flow
{
  "normal": [
    "night_workshop",
    "customer_intake",
    "shadow_workbench",
    "stitch_mode",
    "pose_test",
    "result"
  ],
  "failure": "first pose_test fail→rework_overlay→shadow_workbench/stitch_mode→pose_test→result",
  "gate": "stitch requires snaps; test requires seams"
}

## Screens
### 01. Night Workshop
Purpose: 의뢰 시작과 현재 진행 확인
States: ready
Regions: [{"id":"header","label":"Workshop Header","x":5,"y":4,"w":90,"h":10,"role":"progress"},{"id":"scene","label":"Workshop","x":7,"y":17,"w":86,"h":57,"role":"scene"},{"id":"action","label":"Next Client","x":8,"y":80,"w":84,"h":14,"role":"start"}]
Components: [{"id":"progress","label":"의뢰 1/5","type":"status","box":{"x":70,"y":7,"w":20,"h":6},"state_binding":""},{"id":"client_btn","label":"다음 손님 받기","type":"button","box":{"x":18,"y":83,"w":64,"h":9},"state_binding":""}]
Interactions: [{"trigger":"tap","target":"client_btn","precondition":"ready","action":"손님 로드","state_change":"Intake","feedback":"fade","invalid_input":"중복 tap 무시"}]
Transitions: [{"from":"ready","to":"customer_intake","trigger":"tap client_btn","condition":"always","animation":"short fade"}]
Feedback: []
Edge Cases: []
Implementation Notes: []

### 02. Customer Intake
Purpose: 증상을 관찰하고 수선 목표를 고정
States: observing, diagnosed
Regions: [{"id":"customer","label":"Customer","x":8,"y":5,"w":84,"h":53,"role":"symptom display"},{"id":"symptoms","label":"Symptoms","x":8,"y":61,"w":84,"h":19,"role":"diagnosis targets"},{"id":"action","label":"Begin","x":10,"y":84,"w":80,"h":12,"role":"continue"}]
Components: [{"id":"customer","label":"손님+어긋난 그림자","type":"object","box":{"x":18,"y":8,"w":64,"h":44},"state_binding":""},{"id":"symptom_targets","label":"증상 포인트","type":"hotspots","box":{"x":12,"y":63,"w":76,"h":14},"state_binding":""},{"id":"begin","label":"수선 시작","type":"button","box":{"x":20,"y":86,"w":60,"h":8},"state_binding":"diagnosed"}]
Interactions: [{"trigger":"tap","target":"symptom target","precondition":"observing","action":"수선 목표 고정","state_change":"diagnosed","feedback":"problem pulse","invalid_input":"비증상 영역은 무반응"}]
Transitions: [{"from":"customer_intake","to":"shadow_workbench","trigger":"tap begin","condition":"diagnosed","animation":"short fade"}]
Feedback: []
Edge Cases: []
Implementation Notes: []

### 03. Shadow Workbench
Purpose: 그림자 조각을 drag/rotate하여 anchor에 정렬
States: idle, selected, dragging, snap_candidate, snapped, collision
Regions: [{"id":"status","label":"Repair Status","x":4,"y":3,"w":92,"h":8,"role":"progress"},{"id":"canvas","label":"Shadow Canvas","x":5,"y":13,"w":90,"h":61,"role":"primary manipulation"},{"id":"tray","label":"Piece Tray","x":5,"y":76,"w":90,"h":12,"role":"pieces"},{"id":"tools","label":"Tools","x":5,"y":90,"w":90,"h":8,"role":"rotate/next"}]
Components: [{"id":"silhouette","label":"Base Silhouette","type":"canvas","box":{"x":10,"y":18,"w":80,"h":50},"state_binding":"repair"},{"id":"piece_tray","label":"조각 트레이","type":"tray","box":{"x":8,"y":78,"w":84,"h":8},"state_binding":""},{"id":"rotate_left","label":"-15°","type":"button","box":{"x":8,"y":90,"w":18,"h":7},"state_binding":"piece_selected"},{"id":"rotate_right","label":"+15°","type":"button","box":{"x":28,"y":90,"w":18,"h":7},"state_binding":"piece_selected"},{"id":"stitch_btn","label":"봉합 모드","type":"button","box":{"x":58,"y":90,"w":34,"h":7},"state_binding":"required_snaps_done"}]
Interactions: [{"trigger":"drag","target":"shadow_piece","precondition":"piece available","action":"조각 이동","state_change":"dragging","feedback":"ghost follows","invalid_input":"충돌 시 원위치 bounce"},{"trigger":"two-finger twist","target":"selected piece","precondition":"selected","action":"연속 회전","state_change":"selected","feedback":"angle tick","invalid_input":"gesture cancel keeps last valid angle"},{"trigger":"tap","target":"rotate buttons","precondition":"selected","action":"15° 회전","state_change":"selected","feedback":"tick + light haptic","invalid_input":"미선택 disabled"},{"trigger":"release","target":"anchor","precondition":"within 18px/12deg","action":"snap","state_change":"snapped","feedback":"ghost bright + magnetic click","invalid_input":"잘못된 anchor는 snap 없음"}]
Transitions: [{"from":"shadow_workbench","to":"stitch_mode","trigger":"tap stitch_btn","condition":"required snaps complete","animation":"short fade"}]
Feedback: ["ghost snap","collision bounce"]
Edge Cases: ["겹침 충돌","잘못된 anchor"]
Implementation Notes: ["PieceController","AnchorGraph","gesture arbitration"]

### 04. Stitch Mode
Purpose: 정렬된 경계를 손가락으로 따라 봉합
States: unavailable, available, tracing, locked, error
Regions: [{"id":"status","label":"Seam Status","x":4,"y":3,"w":92,"h":8,"role":"progress"},{"id":"canvas","label":"Seam Canvas","x":5,"y":13,"w":90,"h":68,"role":"trace area"},{"id":"action","label":"Test","x":7,"y":85,"w":86,"h":11,"role":"next"}]
Components: [{"id":"seam_canvas","label":"정렬된 그림자","type":"canvas","box":{"x":9,"y":17,"w":82,"h":58},"state_binding":"stitch"},{"id":"test_btn","label":"Pose Test","type":"button","box":{"x":20,"y":87,"w":60,"h":8},"state_binding":"all_required_locked"}]
Interactions: [{"trigger":"trace","target":"available seam","precondition":"aligned","action":"20px corridor를 따라 봉합","state_change":"tracing","feedback":"seam closes","invalid_input":"20px 이탈 시 취소·error"},{"trigger":"release","target":"seam end","precondition":"trace valid","action":"seam 잠금","state_change":"locked","feedback":"medium haptic","invalid_input":"불완전 trace reset"}]
Transitions: [{"from":"stitch_mode","to":"pose_test","trigger":"tap test_btn","condition":"all required seams locked","animation":"short fade"}]
Feedback: ["seam progress"]
Edge Cases: ["미정렬 seam 시작 차단"]
Implementation Notes: ["TracePath/Path2D"]

### 05. Pose Test
Purpose: 몸과 그림자의 동기화를 0.6초 hold로 검증
States: idle, holding, active, pass, fail
Regions: [{"id":"stage","label":"Test Stage","x":5,"y":6,"w":90,"h":67,"role":"animation"},{"id":"hold","label":"Hold Control","x":12,"y":78,"w":76,"h":15,"role":"test trigger"}]
Components: [{"id":"pose_pair","label":"몸 + 그림자","type":"animation","box":{"x":15,"y":12,"w":70,"h":53},"state_binding":"idle|testing|pass|fail"},{"id":"hold_test","label":"0.6초 눌러 테스트","type":"hold_button","box":{"x":18,"y":81,"w":64,"h":9},"state_binding":"enabled"}]
Interactions: [{"trigger":"hold 0.6s","target":"hold_test","precondition":"required seams complete","action":"테스트 실행","state_change":"active","feedback":"radial fill then pose animation","invalid_input":"release<0.6s resets"}]
Transitions: [{"from":"pose_test","to":"result","trigger":"test pass","condition":"always","animation":"short fade"},{"from":"pose_test","to":"rework_overlay","trigger":"first test fail","condition":"rework_used=false","animation":"short fade"},{"from":"pose_test","to":"result","trigger":"second test complete","condition":"rework_used=true","animation":"short fade"}]
Feedback: ["body/shadow sync or afterimage"]
Edge Cases: ["필수 seam 미완료면 진입 자체 차단"]
Implementation Notes: ["PoseTestController"]

### 06. Rework Overlay
Purpose: 첫 실패의 오류 anchor를 알려주고 1회 수정으로 복귀
States: shown, consumed
Regions: [{"id":"backdrop","label":"Dimmed Test","x":0,"y":0,"w":100,"h":100,"role":"blocked background"},{"id":"modal","label":"Rework Modal","x":10,"y":25,"w":80,"h":43,"role":"error explanation"}]
Components: [{"id":"error_anchor","label":"오류 위치 미리보기","type":"preview","box":{"x":20,"y":30,"w":60,"h":20},"state_binding":""},{"id":"rework_btn","label":"1회 재수선","type":"button","box":{"x":20,"y":57,"w":60,"h":9},"state_binding":"rework_available"}]
Interactions: [{"trigger":"tap","target":"rework_btn","precondition":"rework_used=false","action":"오류 anchor 강조 상태로 작업대 복귀","state_change":"consumed","feedback":"warning haptic","invalid_input":"이미 사용했으면 disabled"}]
Transitions: [{"from":"rework_overlay","to":"shadow_workbench","trigger":"tap rework_btn","condition":"always","animation":"short fade"}]
Feedback: ["dim + warning"]
Edge Cases: ["배경 입력 차단"]
Implementation Notes: ["CanvasLayer modal"]

### 07. Result
Purpose: 등급과 손님의 행동 변화 확인
States: result
Regions: [{"id":"grade","label":"Grade","x":10,"y":6,"w":80,"h":20,"role":"score"},{"id":"change","label":"Behavior Change","x":8,"y":30,"w":84,"h":39,"role":"outcome"},{"id":"next","label":"Next","x":10,"y":76,"w":80,"h":17,"role":"continue"}]
Components: [{"id":"grade","label":"등급","type":"status","box":{"x":30,"y":10,"w":40,"h":13},"state_binding":""},{"id":"behavior","label":"복구 전/후","type":"comparison","box":{"x":12,"y":33,"w":76,"h":32},"state_binding":""},{"id":"continue","label":"다음 의뢰","type":"button","box":{"x":20,"y":80,"w":60,"h":9},"state_binding":""}]
Interactions: [{"trigger":"tap","target":"continue","precondition":"result shown","action":"다음 의뢰","state_change":"ready","feedback":"success/neutral haptic","invalid_input":"연타 무시"}]
Transitions: [{"from":"result","to":"night_workshop","trigger":"tap continue","condition":"always","animation":"short fade"}]
Feedback: []
Edge Cases: []
Implementation Notes: []

## Global States
[
  {
    "id": "loading",
    "rule": "의뢰 데이터 준비 중 입력 차단"
  },
  {
    "id": "pause",
    "rule": "조각 위치와 seam 상태 보존"
  },
  {
    "id": "rework_used",
    "rule": "의뢰당 1회만 true 전환"
  }
]

## Input Map
[
  {
    "input": "tap",
    "priority": 2,
    "use": "symptom/buttons/15° rotate"
  },
  {
    "input": "single-finger drag",
    "priority": 4,
    "use": "shadow piece"
  },
  {
    "input": "two-finger twist",
    "priority": 5,
    "use": "selected piece rotation"
  },
  {
    "input": "trace",
    "priority": 5,
    "use": "seam path"
  },
  {
    "input": "hold 0.6s",
    "priority": 5,
    "use": "pose test"
  }
]

## Global Edge Cases
[
  {
    "case": "piece collision",
    "recovery": "last valid position으로 bounce"
  },
  {
    "case": "wrong anchor",
    "recovery": "snap 금지; ghost 미표시"
  },
  {
    "case": "trace leaves 20px corridor",
    "recovery": "trace 취소·error 표시"
  },
  {
    "case": "test before seams",
    "recovery": "button disabled and missing seam pulse"
  },
  {
    "case": "second test fails",
    "recovery": "추가 rework 없이 Result/낮은 등급"
  }
]

## Developer Handoff
{
  "scene_hierarchy": [
    "AppRoot",
    "ContractController",
    "WorkbenchScene",
    "GestureLayer",
    "HUDLayer",
    "ModalLayer"
  ],
  "reusable": [
    "ShadowPiece",
    "AnchorNode",
    "SeamPath",
    "HoldButton",
    "ResultPanel"
  ],
  "required_data": [
    "ContractData",
    "PieceData",
    "AnchorGraph",
    "SeamGraph",
    "TestPose"
  ],
  "state_owner": "ContractSessionState",
  "persistence": "completed contract/unlock only",
  "implementation_order": [
    "flow/state machine",
    "piece drag",
    "rotation",
    "snap",
    "stitch trace",
    "pose test",
    "rework",
    "result"
  ]
}

## Acceptance Criteria
- 7개 화면/오버레이가 정의된 분기대로 이동한다
- 조각은 drag되고 충돌 시 마지막 유효 위치로 복귀한다
- 선택 조각은 two-finger 또는 ±15° 버튼으로 회전한다
- 18px/12° 허용치에서만 ghost snap과 실제 snap이 발생한다
- 정렬되지 않은 seam은 trace를 시작할 수 없다
- trace가 20px corridor를 벗어나면 취소된다
- 필수 seam 완료 전 Pose Test가 비활성이다
- 0.6초 hold 완료 후에만 Test가 실행된다
- 첫 실패만 Rework로 돌아가며 두 번째 Test 후 Result가 확정된다
