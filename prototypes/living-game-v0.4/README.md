# Living Game v0.4 — Zero-cost Local Adaptive Planner

이 버전은 OpenAI API / Supabase Planner 호출을 제거하고 브라우저 안에서만 동작한다.

## 핵심 구조

`행동 관찰 → 세계 변화 실험 → 실제 반응 평가 → 실험 보상 업데이트 → 다음 변화 선택 → 게임 결정`

장르를 미리 점수화하거나 완성 게임 템플릿 중 하나를 고르지 않는다.

Local Planner는 현재 world model과 최근 행동 telemetry를 바탕으로 여러 mutation 후보를 만들고,
다음 기준을 함께 본다.

- 최근 행동과의 관련성
- 아직 시험하지 않은 변화인지
- 같은 계열 변화가 이전에 반응을 얻었는지
- 현재 세계와 실제로 연결 가능한지
- 탐색 노이즈 / 세션 seed

선택한 mutation 뒤에는 실제 플레이 반응을 측정해 reward를 계산하고,
그 mutation과 category의 평균 보상을 업데이트한다.

즉 완전한 LLM은 아니지만 단순한 `빠르게 움직임 → 레이싱 +1` 규칙도 아니다.

## 비용

- OpenAI API 호출: 0
- Supabase 호출: 0
- 서버 저장: 0
- 실행 위치: 브라우저
- 게임팩 저장: localStorage

## 현재 mutation 문법

### Control
- direct_drag
- inertia
- steer
- click_move
- aim

### Space
- abstract_flat
- top_down_room
- pseudo_depth
- lanes
- world_map

### Entity
- target
- collectible
- companion
- npc
- base
- hazard
- resource_node
- projectile_target

### System
- trail
- chase
- collect
- escort
- deliver
- resource
- upgrade
- build
- dialogue
- projectile
- survival
- trade

### Identity
- dot
- rover
- ship
- creature
- runner
- builder
- courier

## Crystallization

약 60초 이후부터 현재 세계가 충분히 연결되어 있고 최근 실험 반응이 유지되면 게임으로 굳힌다.
너무 오래 실험만 하지 않도록 약 115초 / 9 phase에서 hard stop이 있다.

게임이 확정된 뒤 사용자에게 고르게 하는 것은 동일 게임의 Art Direction 3안뿐이다.
선택 뒤에는 그때의 world model을 그대로 고정해 즉시 플레이한다.

## 다음에 볼 것

1. 점이 충분히 빨리 다른 존재/세계로 바뀌는가
2. 세션마다 실제로 다른 mutation 경로가 나오는가
3. 변화를 넣은 뒤 사용자의 행동이 달라지는 것이 체감되는가
4. 최종 게임이 처음 점 게임의 변형이 아니라 하나의 게임처럼 느껴지는가
5. Local Planner가 반복되는 안전한 조합으로 수렴하지 않는가

v0.4의 목표는 "최종 생성 품질"보다 이 adaptive loop 자체가 성립하는지 검증하는 것이다.
