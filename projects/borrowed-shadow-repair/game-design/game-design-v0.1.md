# Borrowed Shadow Repair — Playable Game Design Spec v0.1

## 1. Product Definition
손님에게서 분리된 그림자의 손상 구조를 작업대에서 직접 맞추고 봉합해 몸과 행동의 이상을 복구하는 세로형 촉각 퍼즐·직업 시뮬레이션. Session: 의뢰 2~4분 · 3의뢰 8~12분. Non-goals는 MVP 제외 범위를 따른다.

## 2. Player Fantasy
플레이어는 밤에만 문을 여는 그림자 수선사다. 손님의 이상 행동을 그림자 구조의 손상으로 진단하고 손으로 조각을 맞추고 봉합해 몸과 그림자를 다시 동기화하는 만족을 느낀다.

## 3. Core Player Verbs
Diagnose: 증상/실루엣 tap → 수선 목표 고정; 문제 부위 맥동
Place: 조각 drag → 위치 변경; ghost snap
Rotate: two-finger twist 또는 15° 버튼 → 각도 변경; 각도 tick
Stitch: seam trace → seam 잠금; 봉합선+medium haptic
Test: 0.6초 hold → 포즈 테스트; 몸/그림자 동시 움직임

## 4. Core Loop
증상 관찰 10~20초 → 2~6개 그림자 조각 drag/rotate 정렬 45~90초 → seam trace 봉합 20~45초 → Pose Test 10초 → 필요 시 1회 재수선 → 결과. 핵심은 정렬→봉합→움직임 검증.

## 5. Round / Session Structure
Intake→Repair→Stitch→Test→Rework 0~1회→Result. 의뢰 2~4분, 3의뢰 8~12분. 첫 Test 실패만 재수선 허용, 두 번째 Test 후 등급 확정.

## 6. Game Rules
{
  "pieces": "초반 2~3, 후반 4~6",
  "snap": {
    "position_px": 18,
    "rotation_deg": 12
  },
  "stitch_trace_deviation_px": 20,
  "rework_limit": 1,
  "score": {
    "alignment": 50,
    "stitch": 30,
    "diagnosis": 20,
    "rework": -10
  },
  "grades": {
    "S": 95,
    "A": 80,
    "B": 65,
    "C": 0
  },
  "failure": "진행 차단 대신 낮은 등급과 잔여 이상 행동"
}

## 7. State Model
[
  {
    "state": "Intake",
    "enter": "손님 등장",
    "input": "증상 관찰",
    "exit": "작업 시작",
    "ui": "손님+증상"
  },
  {
    "state": "Repair",
    "enter": "작업대",
    "input": "drag/rotate",
    "exit": "필수 배치",
    "ui": "조각 트레이+anchor"
  },
  {
    "state": "Stitch",
    "enter": "정렬 seam",
    "input": "trace/undo",
    "exit": "필수 seam 완료",
    "ui": "봉합 가능 경계"
  },
  {
    "state": "Test",
    "enter": "Test hold",
    "input": "hold/release",
    "exit": "pass/Rework",
    "ui": "작업 UI 숨김"
  },
  {
    "state": "Rework",
    "enter": "첫 오류",
    "input": "재배치/봉합",
    "exit": "최종 Test",
    "ui": "오류 anchor 강조"
  },
  {
    "state": "Result",
    "enter": "테스트 종료",
    "input": "계속",
    "exit": "다음 의뢰",
    "ui": "등급+행동 변화"
  }
]

## 8. Interaction Spec
[
  {
    "object": "shadow_piece",
    "gesture": "single-finger drag",
    "error": "겹침 충돌 시 원위치 bounce"
  },
  {
    "object": "rotation",
    "gesture": "two-finger twist / 15° button",
    "error": "미선택 시 disabled"
  },
  {
    "object": "snap",
    "gesture": "18px/12° proximity",
    "error": "잘못된 anchor에는 snap 안 함"
  },
  {
    "object": "stitch",
    "gesture": "seam trace within 20px corridor",
    "error": "이탈 시 취소, 미정렬 seam 시작 차단"
  },
  {
    "object": "test",
    "gesture": "0.6s hold",
    "error": "필수 seam 미완료 시 해당 seam 강조"
  }
]

## 9. Content Model
{
  "unit": "수선 의뢰",
  "fields": [
    "손님",
    "증상",
    "base silhouette",
    "조각",
    "anchor graph",
    "seam graph",
    "rule module",
    "test pose"
  ],
  "modules": [
    "회전 잠금",
    "겹침 레이어",
    "봉합 순서",
    "거울 anchor",
    "test pose 오차"
  ]
}

## 10. Difficulty / Variation
초반 2~3조각 단일 anchor. 중반 4~5조각, 회전 잠금·봉합 순서·겹침. 후반 test pose에서만 드러나는 오차·거울 anchor·복합 증상. 조각 수보다 규칙 조합으로 난도를 올린다.

## 11. Progression
의뢰 완료로 새 수선 규칙을 하나씩 해금한다. 도구는 숫자 강화가 아니라 seam 해제·mirror guide 같은 새 조작 문법을 연다. MVP는 5의뢰 선형 해금.

## 12. Economy
Not required for MVP. 결과 등급과 해금만 사용.

## 13. Screen Inventory
Night Workshop — 의뢰 시작
Customer Intake — 증상/목표
Shadow Workbench — 배치·회전
Stitch Mode — 봉합
Pose Test — 동기화 테스트
Rework Overlay — 오류 수정
Result — 등급/행동 변화

## 14. Screen Flow
Workshop→Intake→Workbench→Stitch→Test. Pass→Result. 첫 오류→Rework→Workbench/Stitch→최종 Test→Result. 필수 seam 미완료면 Test 차단.

## 15. Feedback System
[
  {
    "action": "anchor 접근",
    "visual": "ghost 밝아짐",
    "sound": "soft tick",
    "haptic": "light"
  },
  {
    "action": "snap",
    "visual": "경계 안정",
    "sound": "magnetic click",
    "haptic": "medium"
  },
  {
    "action": "봉합",
    "visual": "seam 닫힘",
    "sound": "천 마찰",
    "haptic": "selection"
  },
  {
    "action": "Test 오류",
    "visual": "몸/그림자 잔상",
    "sound": "wobble",
    "haptic": "warning"
  },
  {
    "action": "복구",
    "visual": "완전 동기화",
    "sound": "resolve",
    "haptic": "success"
  }
]

## 16. Visual Direction Brief
세로 모바일. 중앙 60~70%를 작업대와 그림자 실루엣이 차지한다. 조각 경계와 anchor가 읽히는 명도 차를 사용하고, 초현실성은 장식보다 몸과 그림자의 어긋남/정렬 애니메이션으로 전달한다.

## 17. MVP Scope
세로 모바일 5개 의뢰, 조각 drag, 15° 회전, ghost snap, seam trace, Test hold, 1회 Rework, 결과 등급. 규칙 모듈은 기본 anchor·회전 잠금·봉합 순서.
NOT IN MVP: 상점/재화, 작업실 꾸미기, 장편 NPC 관계, 절차 생성 퍼즐, 복잡한 도구 인벤토리, 다중 손님, 완성 컨셉아트/에셋

## 18. Test Scenarios
20초 내 drag/snap 이해
rotate/snap/stitch 목적 구분
Test 오류 후 15초 내 수정 대상 이해
새 규칙이 기존 조작과 조합되는지
5회 후 새 규칙 기대 여부

## 19. Known Risks
일반 직소 퍼즐화
한 손 사용과 회전 gesture 충돌
실루엣 판독성
고유 아트 의존 시 콘텐츠 비용
Test 인과 피드백 부족

## 20. Wireframe Handoff
7개 화면/오버레이와 Rework 분기
조각 idle/selected/dragging/snap-candidate/snapped
two-finger 회전과 15° 버튼 대안
seam unavailable/available/tracing/locked/error
Test disabled/hold/active
1회 Rework 제한
anchor 오류·충돌·trace 이탈
