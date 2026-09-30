# Backseat Alibi — Playable Game Design Spec v0.1

## 1. Product Definition
실시간 도주와 사회 추리를 결합한 세로 모바일 게임. 달리는 경로 자체가 이후 알리바이의 증거가 된다.
## 2. Player Fantasy
도주 차량의 판단 담당자로서 동료들의 불완전한 기억을 실제 경로와 맞춰 검문을 속인다.
## 3. Core Player Verbs
Route, Question, Place/Revise, Commit. 각 행동은 경로 기록·기억 공개·충돌 계산·검문 판정으로 닫힌다.
## 4. Core Loop
경로 선택 → 기억 수집 → 방문 기록에 기억 연결 → 검문 → 추적도 변화 → 3회 반복 → 탈출.
## 5. Round / Session Structure
약 8분, 3개 주행 구간과 3검문. 추적100/이동불능 실패, 마지막 검문 후 탈출 성공.
## 6. Game Rules
도로는 연료1~3과 위험을 가진다. 분기 선택 5초 만료 시 최저 위험 유효 도로 자동 선택. 질문은 동료별 20초 쿨다운. 기억은 장소·시간·순서 제약을 실제 방문 기록과 비교한다. 검문 전 문항 통과 시 추적-15, 실패 문항당 +25. 위험도로 +8, 봉쇄직전 +12. 추적100 즉시 실패.
## 7. State Model
Briefing, Driving, Checkpoint, Paused, Success, Failure. 핵심 변수는 위치, 방문기록, 시간, 연료, 추적도, 공개기억, 연결, 쿨다운.
## 8. Interaction Spec
도로 탭, 좌석+주제 탭, 기억-방문기록 연결/해제, 검문 근거 선택+전체 확정, Pause.
## 9. Content Model
Case는 road_graph/truth_timeline/companions/checkpoints/start/escape. Memory는 장소·시간·순서 제약. 도로 그래프의 실제 방문 순서/시간이 권위 있는 판정축이다.
## 10. Difficulty / Variation
초반 단일 제약·2문항에서 후반 복합 제약·위험 분기·3문항으로 상승.
## 11. Progression
성공으로 5개 사건 티어 순차 해금. 등급은 추적도/연료/오답으로 계산.
## 12. Economy
Not required.
## 13. Screen Inventory
Briefing; Driving; Alibi Board; Checkpoint; Pause; Success; Failure.
## 14. Screen Flow
Briefing→Driving↔Board→Checkpoint를 3회→Escape→Success. 추적100/이동불능→Failure. 결과→Retry/Case Select.
## 15. Feedback System
경로 ETA/위험, 기억 일치/충돌 연결, 검문 근거 대조, 추적도 증감, 결과 원인 요약.
## 16. Visual Direction Brief
세로형 노드 지도 중심. 좌석별 동료 식별. Board와 Checkpoint는 실제 주행 정보 언어를 공유한다.
## 17. MVP Scope + NOT IN MVP
5개 사건 티어, 동료3, 경로/연료/추적도/기억/검문/재시도/Pause 포함. 자유대화·음성·멀티·전투·경제 제외.
## 18. Test Scenarios
연료12/추적20 성공 완주; 추적92+위험8 즉시 실패; 연료2/출구비용3 이동불능; 검문 오답 후 다음 검문으로 회복; Pause 타이머 보존.
## 19. Known Risks
동시 작업 과부하, 기억의 정답카드화, 판정 불투명, 검문 반복감.
## 20. Wireframe Handoff
fun_promise: 달리는 경로 자체가 알리바이 증거가 되어 경로 판단과 증언 정리가 서로 압박한다. Driving은 경로·자원·질문 상태를 동시 전달하고, Board는 실제 기록과 기억 충돌을 직접 보여주며, Checkpoint는 같은 데이터를 재사용한다.
