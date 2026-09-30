# Last Light Caravan — Playable Game Design Spec v0.1

## 1. Product Definition
모바일용 짧은 생존 전략 게임. 해가 지면 지도 정보가 사라지는 것이 아니라 **정찰하지 않은 길의 위험이 끝까지 숨겨진 채**, 하나의 자원인 빛을 이동·야영·비상 대응 사이에 나눠 피난 행렬을 Beacon까지 이끈다. 핵심은 빛을 더 많이 얻는 게임이 아니라 지금 길을 확실히 통과하는 데 쓸지 밤의 사고를 버티기 위해 남길지 결정하는 것이다.

## 2. Player Fantasy
어둠이 세계를 삼키기 전 마지막 피난 행렬의 길잡이가 되어, 낮에 얻은 작은 정보와 빛만으로 사람들을 다음 안전지대로 이끈다.

## 3. Core Player Verbs
정찰: 인접 노드 탭 → 정보 공개. 경로 선택: 연결 노드 탭 → 목적지 지정. 빛 배분: road/camp/reserve에 정수 배분 → 예산 확정. 대응: 현재 incident의 유효 대응 탭 → 자원 소비와 피해/보상 즉시 적용.

## 4. Core Loop
현재 노드 보상 획득 → 낮 정찰 → 다음 노드 선택 → 해질녘 빛 전량 배분 → 야간 이동 → incident 대응 → 야영 결과 → 다음 날 재계획. Beacon 도착 또는 survivor 0까지 반복한다.

## 5. Round / Session Structure
1일이 1라운드이며 2~4분, 한 런은 5~8일/약 15~25분을 목표로 한다. 하루에는 보상 1회, 정찰 1~2회, 이동 1회, incident 1회, 야영 1회만 발생한다.

## 6. Game Rules
Light는 0 이상의 정수이며 낮 보상으로 증가한다. 해질녘 전량을 road/camp/reserve에 배분한다. 지도는 무방향 노드 그래프이고 직접 연결된 노드로만 이동한다. 간선 비용은 1~3 light이며 항상 보인다. road가 비용보다 적으면 출발 불가. camp 1 이상이면 도착 후 1을 써서 안전 야영하고 morale +1(최대5), 0이면 노출 야영으로 morale -1. 남은 road/camp는 소멸, reserve는 최대3까지 다음 날 light로 환원된다.

Survivor는 8명 시작, 최대12, 0이면 즉시 실패. Morale은 3 시작/0~5; 0이면 다음 낮 정찰이 1회, 그 외 2회다. 노드 보상은 supply(light +2~4), gear(rope/guard 1), refuge(survivor +1), bleak(없음), beacon(목표)이다.

Incident: darkness는 reserve2로 무피해, 아니면 survivor-1. predator는 reserve1 또는 guard1로 무피해, 아니면 survivor-2. collapse는 rope1로 무피해, 아니면 survivor-1/morale-1. refugees는 reserve1을 쓰면 survivor+1, 거절하면 변화 없음. fork_signal은 reserve1을 쓰면 다음 인접 노드 최대2개 즉시 정찰, 거절하면 변화 없음. 비용 없는 대응은 항상 선택 가능하므로 soft-lock이 없다.

Beacon 도착 후 incident 해결 시 survivor>=1이면 성공. Pause는 진행을 완전히 정지하며 resume은 동일 state. Retry는 확인 후 런 초기 상태로 되돌린다.

## 7. State Model
MAP_DAY → DUSK_ALLOC → NIGHT_TRAVEL → INCIDENT → CAMP_OR_TERMINAL → MAP_DAY 또는 RESULT. MAP_DAY 경로 선택은 취소 가능, DUSK_ALLOC은 확정 전 back 가능, 이동 시작 후 취소 불가. survivor가 incident 결과로 0이면 camp 처리보다 실패가 우선한다. Beacon은 incident 해결 후 생존자가 있을 때 성공한다.

## 8. Interaction Spec
Pause가 최우선 입력이다. Incident 대기 중에는 incident response만 gameplay 입력으로 받는다. Allocation confirm은 합계=light_pool이고 road>=선택 간선 비용일 때만 valid. Invalid 입력은 state/value를 변경하지 않는다. 대응 선택은 비용과 결과를 한 번에 적용하며 중복 탭을 받지 않는다.

## 9. Content Model
Content unit은 하루. 노드 5종, incident 5종, gear 2종을 MVP 규칙 공간으로 사용한다. 지도는 시작에서 Beacon까지 경로가 반드시 있고 비-Beacon 노드는 1~3개 간선을 가진다. Variation은 분기 수, 간선 비용, 보상, incident, 초기 light/gear, Beacon 거리로 만든다. 런 시작 시 reward/incident는 고정되어 retry 시 같은 시드를 재사용한다.

## 10. Difficulty / Variation
초반은 낮은 간선 비용과 단일 위험 위주. 이후에는 높은 비용 간선과 유용한 보상을 함께 배치해 우회/직행을 고민하게 하고, collapse처럼 특정 gear가 효율적인 위기, refugees/fork_signal처럼 reserve를 생존 외 가치에 쓸 선택을 섞는다. 난이도는 단순 속도가 아니라 빛의 경쟁 용처와 정보 불확실성 조합으로 상승한다.

## 11. Progression
MVP는 6개 route set을 순차 해금한다. 첫 set은 기본 3 incident, 이후 set에서 collapse, refugees, fork_signal 및 높은 분기 지도를 순차 소개한다. 한 set 성공 시 다음 set 해금. 실패해도 해금은 후퇴하지 않는다. 완료 set은 재플레이 가능하다.

## 12. Economy
Not required. 런 외 화폐/상점은 없다.

## 13. Screen Inventory
- Run Map / Day Planning
- Dusk Light Allocation
- Night Travel
- Incident Decision
- Camp Resolution
- Pause / Retry Confirm
- Run Result
- Route Set Select / Progression

## 14. Screen Flow
Route Set Select → Run Map/Day Planning → Dusk Allocation → Night Travel → Incident Decision → Camp Resolution → 다음 Day Planning 반복. Pause는 플레이 상태에서 overlay로 진입해 resume/retry confirm. Success/Failure → Result → retry 또는 Route Set Select. 해금은 Result 확정 시 적용된다.

## 15. Feedback System
유효 선택은 대상과 예상 비용을 보여준다. 무효 입력은 부족한 자원/조건을 표시한다. 미정찰 incident는 ?로 유지한다. 모든 자원 변화는 숫자 delta와 원인을 표시하고, terminal 결과는 원인·남은 생존자·사용 빛·일수를 요약한다.

## 16. Visual Direction Brief
세로 모바일, 간결한 노드 지도 중심. 낮은 지도 정보가 선명하고 밤 이동은 주변 정보가 줄어드는 대비를 사용한다. 핵심 자원 light/survivor/morale/gear는 어떤 플레이 state에서도 판독 가능해야 한다. UI는 지도 위 판단을 보조하되 세계 공간을 좌표로 고정하지 않는다.

## 17. MVP Scope + NOT IN MVP
6개 route set, 노드 5종, incident 5종, gear 2종, light/survivor/morale 자원, 정찰·경로·배분·대응·야영·retry/pause·progression을 포함한다. 각 set은 약 6~10노드 범위로 제작한다.
NOT IN MVP: 실시간 전투, 캐릭터 개별 능력치, 상점/영구 화폐, 절차 생성 무한 모드, 날씨, 장비 제작, 대화 분기.

## 18. Test Scenarios
성공 dry run: light6에서 cost2 경로 선택, road2/camp1/reserve3 배분 → predator에 reserve1 사용 → camp1 안전 야영 → reserve2가 다음 날 light로 환원 → 반복 후 Beacon incident 해결, survivors>0 → RESULT_SUCCESS.
실패 dry run: survivors2에서 predator 진입, reserve0/guard없음 → 피해2 → survivors0 → 즉시 RESULT_FAIL, camp 미처리.
Invalid: light3/cost2인데 road1 배분 후 confirm → state/value 변화 없이 road 부족 표시.
Morale: camp0으로 morale1→0 → 다음 날 정찰 1회만 허용.
Hidden route: 미정찰 인접 노드 이동 → incident는 도착 후 공개되며 비용 없는 피해 수용/거절 선택으로 진행 가능.

## 19. Known Risks
빛 배분이 정답 계산처럼 느껴질 위험; 정찰 가치가 약하면 미정찰 이동이 무의미해질 위험; reserve 환원이 지나치게 강하면 긴장이 줄어들 위험; incident 텍스트가 길어지면 모바일 흐름이 끊길 위험.

## 20. Wireframe Handoff
- fun_promise: 빛 하나가 길을 여는 비용이면서 위기 대응 자원이어서, 지금 길을 확실히 볼지 나중 생존을 위해 남길지 매일 고민하게 한다.
- MAP_DAY: 공개/미공개 노드, 인접성, 간선 비용, 정찰 횟수, survivor/morale/light/gear 상태 표현.
- DUSK_ALLOC: road/camp/reserve의 정수 배분, 합계 검증, road 부족 invalid, back/cancel 표현.
- NIGHT_TRAVEL: 선택 경로 확정 후 입력 잠금과 목적지 도착 전환 표현.
- INCIDENT: 5 incident class 각각의 가능한 대응, 비용 부족 invalid, 수용 피해 선택 및 결과 feedback 표현.
- CAMP_OR_TERMINAL: safe/exposed camp, morale 변화, Beacon success와 survivor-zero failure 우선순위 표현.
- RESULT/progression: success/failure, retry, 다음 route set 해금/선택 표현.
- content variation: 정찰 여부, 간선 cost 1~3, node reward 5종, incident 5종, morale=0 정찰 감소 상태를 모두 대표 wireframe state로 포함.
