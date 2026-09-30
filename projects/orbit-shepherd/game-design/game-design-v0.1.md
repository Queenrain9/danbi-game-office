# Orbit Shepherd — Playable Game Design Spec v0.1

## 1. Product Definition
손가락으로 작은 행성의 중력을 켰다 껐다 하며 우주 생물 떼의 궤도를 이어 목적지까지 몰아가는 궤도 목축 게임.

## 2. Player Fantasy
작은 우주 목동이 되어 직접 생물을 조종하지 않고 행성의 중력만 켜고 끄며 무리의 궤도를 읽고, 포획과 스윙바이를 연쇄시켜 흩어진 떼를 목적지로 인도한다.

## 3. Core Player Verbs
- 중력 토글: 행성 탭 → toggleable/PLAYING 판정 → gravity_active 반전 → 중력권·예측선 즉시 갱신.
- 관찰: 시간 경과 → 위치·속도 갱신 → 실제 trail과 미래 예측선 비교.
- 재결집: 토글 연쇄 → 분산 무리를 같은 중력권/진행방향으로 수렴.
- 일시정지/재시작: pause/resume/retry → 시뮬레이션 동결/복원.

## 4. Core Loop
초기 상태 읽기 → 중력 토글 → 궤도 관찰 → 포획/스윙바이/재결집 수정 → 요구 수 도착 → 결과 → 다음 스테이지/재시도.

## 5. Round / Session Structure
N마리, 요구 K, 고정 행성·목표·초기 속도를 로드한다. 3초 관찰 후 실시간 진행. 기본 제한 60초. K 도착 시 성공. timer=0 또는 lost_count>N-K면 실패. 결과에서 retry/next/stage select.

## 6. Game Rules
R1 탭: toggleable=true && PLAYING이면 중력 반전, 아니면 변화 없이 거부 피드백.
R2 매 physics tick: 활성 행성들의 거리 기반 가속 합산 → 위치/속도 갱신. capture_radius에서 안전반경을 지키며 과대 이동량 clamp.
R3 목표 arrival_radius 진입 + 속도≤target_max_speed → ARRIVED, count+1. 속도 초과면 통과.
R4 play_bounds 이탈 → LOST. 라운드 중 복구 없음.
R5 arrived_count≥K → SUCCESS.
R6 timer≤0 또는 lost_count>N-K → FAILURE.
R7 pause → 물리/타이머 동결; resume 계속; retry 초기 스냅샷 복원.

## 7. State Model
Session: STAGE_SELECT, OBSERVE, PLAYING, PAUSED, SUCCESS, FAILURE.
Creature: ACTIVE, ARRIVED, LOST.
Planet: ACTIVE_GRAVITY, INACTIVE_GRAVITY.
Flow: select→observe→playing↔paused→success/failure.

## 8. Interaction Spec
주 조작은 행성 단일 탭. PLAYING에서 다음 physics tick에 반영. 모든 ACTIVE 생물의 짧은 미래 예측을 토글 직후 재계산. 생물 직접 조작 금지.

## 9. Content Model
Stage: initial_creatures, required_arrivals, time_limit, play_bounds, target, planets.
Planet: position, gravity_strength, influence_radius, capture_radius, toggleable, initial_active.
Creature: position, velocity.
Target: position, arrival_radius, max_arrival_speed.
Variation: 행성 수/위치/중력/초기 활성, 생물 시작 위치·속도·무리 크기, 목표/허용속도, 시간, 경계. 연속 2D 월드에서 거리·속도로 판정.

## 10. Difficulty / Variation
초반 1~2 행성과 넓은 목표, 중반 중력권 중첩·분산 무리, 후반 3+ 행성·좁은 도착 조건·서로 다른 하위 무리 속도. 새 조작 없이 예측/수정 난도만 상승.

## 11. Progression
선형 스테이지 해금. 성공 시 다음 스테이지 개방. 별점/영구 능력치 없음. 실패로 해금 손실 없음.

## 12. Economy
Not required.

## 13. Screen Inventory
Stage Select; Gameplay/Observe; Gameplay/Playing; Pause Overlay; Result/Success; Result/Failure.

## 14. Screen Flow
Stage Select → Observe(3초) → Playing → Success/Failure. Playing ↔ Pause. Success: Next/Select. Failure: Retry/Select. Retry는 동일 초기 스냅샷.

## 15. Feedback System
중력 on/off는 행성과 영향권으로 이중 표시. 예측선과 실제 trail 구분. ACTIVE/ARRIVED/LOST 즉시 표시. arrived/K, 시간, 도착 속도 조건 표시. 실패 원인 명시.

## 16. Visual Direction Brief
고정 2D 우주 평면. 행성·목표·생물 무리·궤도 판독 우선. 장식은 궤도를 방해하지 않으며 UI는 핵심 카운트/시간 중심.

## 17. MVP Scope + NOT IN MVP
MVP: 고정 행성 배치, 실시간 2D 중력, 생물 무리, 목표 도착/유실, 예측선, pause/retry, 선형 해금, 난도 variation.
NOT IN MVP: 행성 이동/배치 편집, 생물 드래그, 업그레이드/재화/상점, 절차 생성, 스토리 캠페인, 온라인, 행성 파괴.

## 18. Test Scenarios
성공: N=10,K=7,60초에서 7번째 생물이 허용속도로 목표 진입 → SUCCESS.
유실 실패: N=10,K=7에서 4번째 유실 → 최대 6 도착 가능 → FAILURE.
시간 실패: arrived=6에서 timer=0 → FAILURE.
복구: pause/resume은 상태 보존, retry는 초기값 복원.
무효 입력: 비토글 행성/결과 상태 탭은 중력 변경 없음.

## 19. Known Risks
예측선 오차가 크면 우연처럼 느껴짐. 강한 중력 합산의 수치 불안정. 과도한 분산 시 무리 판단 저하. 도착 속도 조건이 불명확하면 판정이 자의적으로 느껴짐.

## 20. Wireframe Handoff
fun_promise: 탭 한 번으로 궤도가 크게 바뀌되, 플레이어가 변화를 읽고 다음 토글로 수정할 수 있는 우주 목축.
전체 화면/상태, gravity on/off, active/arrived/lost, observe/playing/paused/result를 구분한다. 고유 제스처는 행성 탭과 pause/result 선택뿐. Gameplay에 arrived/K, 시간, 도착속도 조건, 중력권, 예측 궤도, 실제 trail을 표현한다. Variation은 동일 규칙 아래 행성 수/중첩, 무리 분산, 목표 허용치, 시작 속도로 표현한다.