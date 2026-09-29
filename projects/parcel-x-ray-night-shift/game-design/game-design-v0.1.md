# Parcel X-Ray Night Shift — Playable Game Design Spec v0.1

## 1. Product Definition
심야 택배 허브에서 상자를 손으로 회전하고 엑스레이 단면을 훑어 내부 배치와 위험 규칙을 추론한 뒤 올바른 처리 레인으로 보내는 공간 판독 퍼즐.
Genre / Platform: Inspection Puzzle / Mobile portrait
Session: 상자 35~55초 · Shift 6~9분
Target feel: 플레이어는 야간 물류 허브의 숙련 보안 검사원이다. 겉으로는 평범한 상자를 몇 번의 회전과 단면 스캔만으로 읽어내고, 제한된 검사 시간 안에 위험한 포장과 정상 화물을 구분하는 ‘눈이 좋은 전문가’가 되어야 한다. 빠름보다 정확한 공간 추론과 확신 있는 분류에서 만족을 느낀다.
Non-goals: 실제 공항/물류 X-ray 시뮬레이터; 반사신경 중심 속도 게임; 숨은그림찾기; 현실 위험물 교육

## 2. Player Fantasy
플레이어는 야간 물류 허브의 숙련 보안 검사원이다. 겉으로는 평범한 상자를 몇 번의 회전과 단면 스캔만으로 읽어내고, 제한된 검사 시간 안에 위험한 포장과 정상 화물을 구분하는 ‘눈이 좋은 전문가’가 되어야 한다. 빠름보다 정확한 공간 추론과 확신 있는 분류에서 만족을 느낀다.

## 3. Core Player Verbs
[
  {
    "verb": "Rotate",
    "input": "상자 위 1-finger drag",
    "target": "검사대 상자",
    "condition": "Inspect 상태",
    "state_change": "상자 yaw/pitch 변경",
    "feedback": "상자와 내부 실루엣이 즉시 회전"
  },
  {
    "verb": "Slice Scan",
    "input": "우측 scan rail 세로 swipe",
    "target": "X-ray 단면",
    "condition": "Inspect 상태",
    "state_change": "slice_depth 0~100 변경",
    "feedback": "절단면이 상자 내부를 연속 통과"
  },
  {
    "verb": "Pin Evidence",
    "input": "의심 지점 tap",
    "target": "현재 단면의 물체",
    "condition": "scan active",
    "state_change": "관찰 마커 추가/제거",
    "feedback": "짧은 링+햅틱"
  },
  {
    "verb": "Classify",
    "input": "상자를 하단 레인으로 drag-release",
    "target": "PASS/REPACK/ISOLATE",
    "condition": "상자 미분류",
    "state_change": "판정 잠금",
    "feedback": "레인 snap+결과 stamp"
  }
]

## 4. Core Loop
5~8초 외부 라벨 확인 → 15~30초 상자 회전과 slice scan으로 내부 구조 파악 → 5~10초 규칙 카드와 관찰을 대조 → 상자를 PASS/REPACK/ISOLATE 레인으로 밀어 판정 → 3~5초 결과 피드백 → 다음 상자. 숙련 시 불필요한 스캔을 줄이고 결정 속도를 높인다.

## 5. Round / Session Structure
한 Shift는 8개 상자. 첫 상자 로드 시 시작하며 각 상자는 Intake→Inspect→Classify→Result를 거친다. 상자당 목표 35~55초, Shift 6~9분. 8개 처리 후 정확도·불필요 스캔·위험 누락을 합산한 Shift Summary를 보여주고 다음 Shift로 이동한다.

## 6. Game Rules
{
  "initial_rules": [
    "금속성 고밀도 물체가 완충재 없이 외벽 10% 이내면 REPACK",
    "서로 다른 두 고밀도 물체가 케이블형 구조로 연결되고 전원 셀과 접촉하면 ISOLATE",
    "위험 조건이 없으면 PASS"
  ],
  "scan_budget": {
    "soft_target": 4,
    "hard_limit": null,
    "penalty": "5회째부터 efficiency 점수 감소"
  },
  "scoring": {
    "correct": 100,
    "critical_isolate": 150,
    "wrong_pass": -180,
    "wrong_other": -80,
    "efficient_bonus": "<=3 scan reversals +20",
    "false_pin": -5
  },
  "failure": "Shift 즉시 실패 없음. 위험 상자를 PASS하면 Critical Miss 기록; 2회 이상이면 Shift grade 최대 C.",
  "combo": "연속 3정답부터 +10 accuracy streak, 오답 시 리셋",
  "numbers_are": "MVP 튜닝 가설"
}

## 7. State Model
[
  {
    "id": "intake",
    "enter": "새 상자 로드",
    "inputs": [
      "label tap",
      "begin"
    ],
    "exit": "Begin Inspect",
    "ui": "라벨/규칙 요약"
  },
  {
    "id": "inspect",
    "enter": "Begin",
    "inputs": [
      "rotate",
      "slice swipe",
      "pin"
    ],
    "exit": "레인 drag 시작",
    "ui": "큰 검사대+scan rail+규칙 chip"
  },
  {
    "id": "classifying",
    "enter": "상자 drag가 레인 영역 진입",
    "inputs": [
      "drag",
      "cancel by return"
    ],
    "exit": "valid lane release",
    "ui": "3개 레인 강조"
  },
  {
    "id": "result",
    "enter": "판정 잠금",
    "inputs": [
      "continue"
    ],
    "exit": "다음 상자",
    "ui": "정답/근거/점수"
  },
  {
    "id": "shift_summary",
    "enter": "8개 완료",
    "inputs": [
      "next shift"
    ],
    "exit": "새 Shift",
    "ui": "정확도/critical/efficiency"
  }
]

## 8. Interaction Spec
{
  "gesture_priority": [
    "lane drag > box rotate > hotspot tap",
    "scan rail swipe는 rail 영역에서만 시작"
  ],
  "rotate": {
    "hit": "box bounds + 8% padding",
    "cancel": "pointer leaves screen -> last pose 유지",
    "invalid": "UI/rail 위 시작은 무시"
  },
  "scan": {
    "rail": "screen right 12%",
    "mapping": "vertical 0~100 to slice depth",
    "cancel": "release freezes slice",
    "invalid": "상자 drag 중 비활성"
  },
  "pin": {
    "hit": "visible internal shape",
    "max": 4,
    "invalid": "empty slice tap -> faint no-target pulse"
  },
  "classify": {
    "threshold": "box center enters lane and release",
    "cancel": "release outside lane -> spring to table",
    "lock": "valid release 후 입력 잠금"
  }
}

## 9. Content Model
{
  "unit": "Parcel Case",
  "axes": [
    "outer box size 3종",
    "internal object set",
    "object pose",
    "packing material",
    "hazard rule tags",
    "decoy density",
    "label metadata",
    "correct lane"
  ],
  "generation": "수작업 seed case + 데이터 조합. 정답은 hazard evaluator로 사전 검증",
  "mvp": "10개 고정 상자, 내부 primitive 6종, 위험 규칙 3개"
}

## 10. Difficulty / Variation
초반은 한 규칙과 큰 물체, 중반은 가림·회전된 물체와 두 규칙 조합, 후반은 정상처럼 보이는 decoy와 관계 규칙을 추가한다. 시간만 줄이지 않고 필요한 관찰 각도, 단면 해석, 규칙 간 우선순위를 늘린다.

## 11. Progression
Shift grade로 새 검사 규칙과 상자군을 순차 해금한다. 도구 능력치 강화는 MVP에서 제외하고, 플레이어 지식이 늘어나는 progression을 우선한다.

## 12. Economy
Not required. MVP와 핵심 제품에는 재화/상점이 필요하지 않다.

## 13. Screen Inventory
Night Hub / Shift Select
- Parcel Intake
- X-Ray Inspection Table
- Classification Result
- Shift Summary
- Rule Manual Overlay
- Pause

## 14. Screen Flow
Night Hub → Parcel Intake → X-Ray Inspection Table → 상자를 레인에 drop → Classification Result → (남은 상자) Parcel Intake / (8개 완료) Shift Summary → Night Hub. Inspect 중 Rule Manual overlay 가능. 레인 밖 drop은 Inspect로 복귀.

## 15. Feedback System
{
  "rotate": "직접 추종 + 낮은 기계 마찰음",
  "scan": "단면 위치선/내부 단면 강조 + 얇은 scan hum",
  "pin": "ring + light haptic",
  "valid_lane": "레인 outline + magnetic snap",
  "correct": "green이 아닌 check shape/stamp + medium haptic",
  "critical_miss": "경고 stripe + low double haptic + 근거 단면 재현"
}

## 16. Visual Direction Brief
세로 모바일. 상자와 검사대가 화면 60~65%를 차지한다. 카메라는 약한 3/4 탑뷰지만 회전 시 형태 판독이 우선이다. 외부 상자는 저정보, X-ray 내부는 2~3단계 명도 실루엣으로 분리한다. UI는 상단에 case/rule, 우측에 scan rail, 하단에 세 레인. 장식보다 내부 관계가 작은 화면에서 읽히는 것이 우선.

## 17. MVP Scope
세로 모바일 greybox 1개 Shift. 고정 상자 10개 중 8개 출제, primitive 내부 물체 6종, 위험 규칙 3개, 상자 회전, slice scan, evidence pin, 3레인 분류, 결과 설명, Shift Summary까지 실제 플레이 가능하게 구현.
NOT IN MVP: 절차 생성; 경제/상점; 직원 성장; 스토리 캠페인; 복잡한 재질 X-ray; 온라인 랭킹; 상자 개봉 애니메이션

## 18. Test Scenarios
처음 보는 플레이어가 30초 내 회전과 scan rail을 이해한다.
- 규칙 3개로 10개 상자 중 8개 이상을 색이 아닌 공간 관계를 보고 판정한다.
- 상자 1개 평균 판정 시간이 55초를 넘지 않는다.
- 레인 오분류가 drag 조작 실패 때문인 비율이 10% 미만이다.
- 플레이어가 오답 결과에서 어떤 내부 관계를 놓쳤는지 말할 수 있다.

## 19. Known Risks
X-ray가 단순 색/모양 찾기로 퇴화할 위험
- 3D 회전과 단면 스캔 동시 이해 부담
- 작은 화면에서 내부 실루엣 겹침
- 상자 케이스 제작 비용 증가
- 위험 규칙이 텍스트 암기 게임이 될 위험

## 20. Wireframe Handoff
Parcel Intake의 외부 라벨과 Begin 상태
- Inspection 기본/회전/scan/pin 상태
- 우측 scan rail과 단면 깊이 피드백
- PASS/REPACK/ISOLATE drag target과 invalid drop
- Rule Manual overlay
- Result의 정답 근거 단면 재현
- Shift Summary
- 입력 충돌·취소·판정 잠금 상태
