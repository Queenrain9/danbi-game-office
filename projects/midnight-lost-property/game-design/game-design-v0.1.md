# Midnight Lost Property — Playable Game Design Spec v0.1

## 1. Product Definition
막차가 끊긴 역의 분실물 창구에서 물건의 물리적 흔적과 방문객 진술을 대조해 반환·보류·신고를 판정하는 세로형 심야 업무 추리 게임. Session: 사건 2~3분 · 3사건 7~10분. Non-goals는 MVP 제외 범위를 따른다.

## 2. Player Fantasy
플레이어는 인적이 끊긴 역의 야간 분실물 담당자다. 물건을 세밀하게 살피고 제한된 질문으로 진술의 빈틈을 찾아, 불완전한 증거에서도 책임 있는 결정을 내리는 숙련감을 느낀다.

## 3. Core Player Verbs
Inspect: 물건 drag 회전·pinch 확대·hotspot tap → 관찰 단서 생성; 핫스폿 링·단서 카드
Question: 질문 카드 tap → 진술 단서 생성; 핵심 구절 강조
Compare: 단서 long-press drag → 일치/모순 관계 기록; 관계 연결선
Decide: 조치 tap 후 confirm swipe → 판정 잠금; 도장·햅틱

## 4. Core Loop
접수 5~10초 → 물건 조사 30~60초 → 방문객 질문 30~45초 → 단서 대조 20~40초 → RETURN/HOLD/REPORT 판정 5초 → 결과 10~20초. 반복 핵심은 관찰→질문→대조→책임 있는 판정.

## 5. Round / Session Structure
한 사건은 Intake→Inspection→Questioning→Review→Decision→Outcome. 사건당 2~3분, 3사건 세션 7~10분. 판정 후 되돌리기 불가. 세 사건 뒤 Shift Summary.

## 6. Game Rules
{
  "clues": "3~5, 결정 최소 2",
  "questions": "기본 3회",
  "decisions": [
    "RETURN",
    "HOLD",
    "REPORT"
  ],
  "score": {
    "correct": 100,
    "supported_reason": 30,
    "unnecessary_question": -5,
    "reckless_return": -40,
    "false_report": -25
  },
  "grades": {
    "S": 330,
    "A": 280,
    "B": 220,
    "C": 0
  },
  "principle": "소유주 맞히기가 아니라 증거 수준에 맞는 조치를 고른다."
}

## 7. State Model
[
  {
    "state": "Intake",
    "enter": "새 사건",
    "input": "접수 확인",
    "exit": "조사 시작",
    "ui": "발견 장소·시간"
  },
  {
    "state": "Inspection",
    "enter": "물건 수령",
    "input": "회전/확대/hotspot",
    "exit": "질문",
    "ui": "물건+단서 트레이"
  },
  {
    "state": "Questioning",
    "enter": "방문객 등장",
    "input": "질문 tap",
    "exit": "Review",
    "ui": "질문 잔여"
  },
  {
    "state": "Review",
    "enter": "검토",
    "input": "단서 비교",
    "exit": "Decision",
    "ui": "비교 보드"
  },
  {
    "state": "Decision",
    "enter": "조치 선택",
    "input": "confirm swipe",
    "exit": "잠금",
    "ui": "3개 조치"
  },
  {
    "state": "Outcome",
    "enter": "잠금 후",
    "input": "계속",
    "exit": "다음 사건",
    "ui": "파장·점수"
  }
]

## 8. Interaction Spec
[
  {
    "object": "lost_item",
    "gesture": "drag rotate / pinch / hotspot tap",
    "error": "핫스폿 외 입력은 약한 경계 반응"
  },
  {
    "object": "question_card",
    "gesture": "tap",
    "error": "예산 0이면 잠금 사유"
  },
  {
    "object": "evidence_card",
    "gesture": "long-press drag to compare",
    "error": "중복 배치 금지"
  },
  {
    "object": "decision",
    "gesture": "tap + horizontal confirm swipe",
    "error": "단서 2개 미만 확정 불가"
  }
]

## 9. Content Model
{
  "unit": "분실물 사건",
  "fields": [
    "물건",
    "발견 장소/시간",
    "방문객 1~2",
    "진실 상태",
    "단서",
    "질문 응답",
    "올바른 조치"
  ],
  "axes": [
    "물건 유형",
    "흔적",
    "관계",
    "거짓말 방식",
    "위험도",
    "조치"
  ]
}

## 10. Difficulty / Variation
초반은 한 방문객과 명백한 물리 단서. 중반은 두 방문객·부분 진실·HOLD가 최선인 불완전 증거. 후반은 위험물·시간 순서 모순·복수의 합리적 설명. 타이머보다 단서 관계 깊이로 난도를 올린다.

## 11. Progression
밤 완료로 새 사건군과 증거 문법을 해금한다. 플레이어 스탯 강화보다 플레이어가 더 복잡한 증거 문법을 배우는 진행.

## 12. Economy
Not required for MVP. 점수와 근무 등급만 사용.

## 13. Screen Inventory
Night Desk — 근무 시작
Case Intake — 발견 정보
Inspection Desk — 물건 조사
Visitor Interview — 제한 질문
Evidence Review — 단서 대조
Decision Confirm — 조치 확인
Outcome — 결과
Shift Summary — 3사건 요약

## 14. Screen Flow
Night Desk→Intake→Inspection→Interview↔Inspection(1회)→Review→Decision→Outcome→다음 사건. 3번째 Outcome 후 Summary. 근거 부족 시 Decision 진입 차단.

## 15. Feedback System
[
  {
    "action": "단서 발견",
    "visual": "링+카드 팝",
    "sound": "짧은 틱",
    "haptic": "light"
  },
  {
    "action": "모순",
    "visual": "끊긴 연결선",
    "sound": "낮은 클릭",
    "haptic": "medium"
  },
  {
    "action": "판정",
    "visual": "도장",
    "sound": "도장음",
    "haptic": "rigid"
  },
  {
    "action": "결과",
    "visual": "점수 정렬",
    "sound": "확인음",
    "haptic": "success"
  }
]

## 16. Visual Direction Brief
세로 화면. 카운터의 물건이 가장 큰 대상이며 상단 사건 메타데이터와 하단 단서 트레이를 고정한다. 어두운 심야역 분위기보다 물건 표면과 단서 판독성을 우선한다.

## 17. MVP Scope
세로 모바일 1개 밤, 완성 사건 5개, 물건 회전/확대/hotspot, 질문 예산, 단서 카드 비교, RETURN/HOLD/REPORT, Outcome, Shift Summary.
NOT IN MVP: 상점/재화, 장편 분기 서사, 음성 연기, 절차 생성 사건, 복수 엔딩, 실시간 타이머, 3D 자유 카메라

## 18. Test Scenarios
30초 내 조사/단서 획득 이해
5사건 중 3건 이상 실제 단서 비교
HOLD가 증거 수준에 따른 정당한 답임을 이해
5사건 후 다음 사건 시작 의향
Outcome만으로 오판 이유 이해

## 19. Known Risks
카드 읽기 퀴즈처럼 보일 위험
논리 사건 제작 비용
작은 화면 정보 밀도
명백한 정답으로 대조가 형식화될 위험

## 20. Wireframe Handoff
8개 화면 정상 플로우와 Inspection↔Interview 복귀
물건 idle/rotate/zoom/hotspot 상태
질문 예산 3→0
단서 long-press drag와 비교 슬롯 상태
3개 판정의 선택/confirm/error
Outcome 정답·오판 피드백
모달 입력 차단
