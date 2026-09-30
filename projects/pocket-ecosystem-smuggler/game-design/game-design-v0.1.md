# Pocket Ecosystem Smuggler — Playable Game Design Spec v0.1

## 1. Product Definition
3x3 여행 가방 속 금지 생태계를 국경 너머로 운반하는 계획형 생태 빌드 전략. 핵심은 작은 공간에서 포식·먹이·온도 결과를 예측해 한 번씩 개입하고, 그 결과 생긴 흔적까지 검문 전에 관리하는 것이다.

## 2. Player Fantasy
나는 위험한 미니 생태계를 숨겨 운반하는 밀수 생태관리자다. 생물을 단순히 살리는 것이 아니라 서로 먹고 먹히는 관계를 이용하면서도 검문관에게 들키지 않을 만큼 깨끗하게 유지한다.

## 3. Core Player Verbs
- **배치** — input: drag/drop; target: 가방 격자 칸; condition: 준비 단계이며 빈 칸 또는 이동 가능한 개체; state_change: 개체/식물의 서식 칸 변경; feedback: 유효 칸 강조, 온도·먹이 영향 미리보기
- **급여** — input: tap then target; target: 생물; condition: 이동 단계이며 먹이 토큰 보유; state_change: 먹이 -1, 허기 감소; feedback: 허기 게이지 변화와 섭식 반응
- **격리** — input: drag to isolation; target: 생물; condition: 격리 칸이 비어 있음; state_change: 포식/번식 상호작용 차단, 해당 칸 용량 점유; feedback: 격리 표식과 차단선
- **은폐** — input: tap action then zone; target: 서식구역; condition: 검문 직전 은폐 행동 1회 사용 가능; state_change: 선택 구역의 흔적 수치 감소; feedback: 흔적 감소와 검문 위험 갱신

## 4. Core Loop
종과 시작 배치를 선택한다 → 이동 구간의 환경 변화를 본다 → 틱을 해결한다 → 틱 사이 한 번 이동/급여/격리로 개입한다 → 3틱 후 흔적을 은폐한다 → 검문을 통과하면 살아남은 생태계로 다음 구간에 진입한다 → 실패하면 구간 시작 상태로 재시도한다.

## 5. Round / Session Structure
한 런은 3개 구간, 구간당 3틱이다. 시작에 구성/배치를 정하고 각 틱 뒤 1회 개입한다. 마지막 틱 뒤 검문 1회가 있다. 3개 구간 통과 시 런 성공. 예상 세션 8–15분.

## 6. Game Rules
- **R1** 가방은 3x3 격자이며 각 칸은 생물/식물 1개를 수용한다. 중앙 1칸은 격리칸으로 전환 가능하며 격리 중 인접 상호작용이 없다.
- **R2** 각 이동 구간은 3틱이다. 매 틱 순서는 환경 변화→먹이 소비→포식 판정→건강 판정이다. 플레이어는 틱 사이마다 행동 1회를 사용한다.
- **R3** 온도는 칸별 정수 0~4. 생물의 허용 범위를 벗어난 틱마다 건강 -1. 건강 0이면 사망하고 흔적 +2.
- **R4** 생물은 매 틱 먹이 1을 요구한다. 해당 종이 먹을 수 있는 인접 먹이 개체/식물이 있으면 자동 소비하고 없으면 허기 +1. 허기 2에서 건강 -1 후 허기 1로 감소한다.
- **R5** 포식자는 인접한 먹이 종 중 우선순위가 가장 높은 1개를 먹는다. 먹힌 개체는 제거되고 포식자의 허기 0, 흔적 +1.
- **R6** 틱 사이 행동은 이동, 급여, 격리/해제 중 하나. 이동은 빈 인접 칸으로만 가능. 급여는 보유 먹이 토큰 1개 소비해 대상 허기 0. 격리는 중앙 칸 대상에게만 적용/해제 가능.
- **R7** 구간 종료 후 검문이 발생한다. 검문 직전 은폐 1회를 사용해 선택한 3칸 연결 구역의 흔적을 최대 2 감소시킨다. 검문 위험=남은 흔적+금지종 수. 위험이 구간 허용치보다 크면 적발.
- **R8** 적발 시 해당 구간 실패. 구간 시작 상태로 되돌리고 동일 구성으로 재시도하며 영구 자원 손실은 없다. 생태계 전멸도 동일하게 구간 실패 처리한다.
- **R9** 구간 성공은 최소 1개의 목표 생물이 생존하고 검문을 통과하는 것. 성공 시 다음 구간을 해금하고 생존 상태를 다음 구간 시작값으로 이어간다.
- **R10** 일시정지는 시뮬레이션 시간을 멈추며 상태를 바꾸지 않는다. 재시작은 현재 구간 시작 스냅샷으로 복구한다.

## 7. State Model
- States: loadout, transit_tick, intervention, checkpoint, segment_result, run_result, paused
- Variables: grid occupancy, temperature[9], health per organism, hunger per animal, food_tokens, trace, segment_index, checkpoint_limit, alive_targets
- Transitions: loadout→transit_tick on depart; transit_tick→intervention after each resolved tick except final; intervention→transit_tick after one action; final transit_tick→checkpoint; checkpoint→segment_result by risk check; failed segment_result→loadout restored from segment snapshot; passed segment_result→next loadout or run_result

## 8. Interaction Spec
- 격자 drag/drop 배치·이동
- 대상 선택형 급여
- 중앙 격리 토글
- 검문 전 3칸 연결 구역 선택 은폐
- pause/retry
- Invalid input: 상태 변화 없이 원위치 복귀하고 불가 이유를 즉시 표시
- Timing: 실시간 반사신경이 아니라 틱 사이 계획형 입력; 판정 중 입력 잠금

## 9. Content Model
- Organism schema: id,type(predator/prey/plant),temp_min,temp_max,max_health,diet,priority,forbidden,target
- Segment schema: temperature_delta_pattern,checkpoint_limit,ticks=3,start_food
- Bag topology: 3x3 topology with orthogonal adjacency and central isolation capability
- Variation axes: 종 조합, 초기 배치, 온도 변화 패턴, 먹이 토큰 수, 검문 허용치, 금지종 수
- MVP species: 최소 3종: 포식자 1, 먹이동물 1, 식물 1. 추가 종은 동일 schema만 사용

## 10. Difficulty / Variation
난도는 새 조작을 추가하지 않고 온도 변화 폭, 먹이 부족, 금지종 수, 검문 허용치, 종 상성 조합으로 상승한다. 1구간은 한 변수 위주, 2구간은 두 변수 충돌, 3구간은 생존과 흔적 관리가 동시에 압박되도록 구성한다.

## 11. Progression
구간 통과로 다음 구간이 해금된다. 런 내 진행은 생존 개체 상태가 이어지는 연속 진행이다. MVP 메타 성장 없음. 런 실패 후 동일 런을 처음부터 재시작할 수 있다.

## 12. Economy
Not required. 먹이 토큰은 구간 내 전술 자원이며 화폐가 아니다.

## 13. Screen Inventory
- Run Setup
- Suitcase Ecosystem
- Checkpoint
- Segment Result
- Run Result
- Pause

## 14. Screen Flow
Run Setup → Suitcase Ecosystem(loadout→tick→intervention 반복) → Checkpoint → Segment Result → 다음 Suitcase Ecosystem 또는 Run Result. 실패 Result → 동일 구간 loadout 복구. Pause는 Suitcase/Checkpoint에서 진입 후 원상 복귀.

## 15. Feedback System
- Prediction: 행동 선택 중 다음 틱의 위험 칸/예상 섭식/온도 이탈을 표시
- Resolution: 틱 종료 시 환경→섭식/포식→건강 변화를 순차적으로 읽히게 표시
- Danger: 건강 1, 허기 1+, 검문 위험 초과 가능성을 경고
- Result: 사망·적발 원인을 단일 문장으로 명시하고 재시도 시 복구 지점을 표시

## 16. Visual Direction Brief
고정 탑다운 가방 시점. 3x3 생태 칸과 인접 관계가 가장 먼저 읽혀야 하며 생물 실루엣, 환경 상태, 위험 피드백의 정보 밀도를 장식보다 우선한다. UI는 세계 위를 가리지 않고 생태 상태를 보조하며 검문은 같은 가방을 다른 의미로 읽는 전환으로 표현한다.

## 17. MVP Scope + NOT IN MVP
MVP: 3x3 가방, 최소 3종, 온도·먹이/허기·건강·포식·흔적, 이동/급여/격리, 3구간 런, 검문/은폐, 실패 복구, pause/retry.
NOT IN MVP: 실시간 액션 전투, 온라인/멀티플레이, 복잡한 유전/번식 시뮬레이션, 상점/화폐 경제, 스토리 캠페인 분기, 9칸을 넘는 가방 확장.

## 18. Test Scenarios
- 성공: 포식자/먹이/식물을 배치하고 3틱 동안 급여·이동으로 목표 생물을 생존시킨 뒤 흔적 2를 은폐해 위험 3≤허용치 3으로 통과한다.
- 실패-검문: 사망으로 흔적이 누적되어 은폐 후 위험 5>허용치 3이 되어 적발되고 구간 시작 상태로 복구된다.
- 실패-전멸: 목표 생물 건강이 0이 되어 마지막 목표가 사망하면 즉시 구간 실패 후 스냅샷 재시도가 가능하다.
- 격리: 중앙 생물을 격리하면 해당 틱 인접 포식 관계가 발생하지 않고 해제 후 다시 발생한다.
- pause/retry: 판정 전 pause는 변수를 유지하고 retry는 구간 시작값을 정확히 복구한다.

## 19. Known Risks
- 자동 포식 순서가 불명확하면 결과가 임의적으로 느껴질 수 있음
- 온도·허기·흔적을 동시에 읽히게 하지 못하면 원인 학습이 어려움
- 검문이 단순 숫자 컷으로만 느껴지면 생태 관리와 은폐가 분리될 수 있음

## 20. Wireframe Handoff
- fun_promise: 작은 가방 안의 먹이사슬을 예측·개입하면서 동시에 검문 흔적을 관리하는 압축된 생태 전략.
- 전체 화면: Run Setup, Suitcase Ecosystem, Checkpoint, Segment Result, Run Result, Pause를 모두 와이어프레임화.
- Suitcase Ecosystem은 loadout/transit resolution/intervention/critical danger 상태를 구분하고 3x3 인접 관계, 온도, 허기, 건강, 흔적, 남은 행동을 읽을 수 있어야 함.
- Checkpoint는 은폐 전/구역 선택/은폐 후/통과/적발 상태와 위험 계산 근거를 보여줄 것.
- 모든 drag/tap의 valid/invalid, 사망, 포식, 온도 피해, 흔적 증가, retry 복구 피드백을 정의할 것.
- variation은 종 조합·초기 배치·온도 패턴·먹이 수·검문 허용치가 바뀌어도 동일 interaction grammar를 유지할 것.
