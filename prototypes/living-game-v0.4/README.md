# Living Game v0.4 — Real AI Planner

v0.1~v0.3에서 반복된 문제를 끊기 위해 만든 버전.

## v0.4에서 제거한 것

- 미리 정한 완성 게임 후보
- 장르 점수로 결과를 고르는 로직
- buildGameSpec() 같은 결과 매핑 함수
- AI처럼 보이는 로컬 규칙의 가짜 추론
- Planner 실패 시 임의 게임 생성

## 실제 흐름

1. 화면에는 점 하나만 존재.
2. 브라우저는 실제 행동 telemetry를 기록.
3. 일정 시간이 지나면 현재 world model + telemetry + 이전 AI 판단을 Supabase Edge Function에 전달.
4. Edge Function의 실제 LLM Planner가 다음 세계 변경을 JSON으로 결정.
5. 브라우저의 Universal Runtime은 허용된 mutation만 실행.
6. 이 과정을 반복.
7. AI가 충분히 하나의 게임이 되었다고 판단하면 정확히 하나의 Game Design을 crystallize.
8. 사용자는 그 게임의 Art Direction 3안 중 하나만 선택.
9. 현재 world model을 그대로 고정하여 즉시 플레이.
10. Game Pack에 저장.

## AI Planner endpoint

Supabase Edge Function:

`living-game-planner`

이 함수는 `OPENAI_API_KEY`가 Supabase Edge Function Secrets에 있을 때만 실제 AI 호출을 한다.
키가 없으면 HTTP 503 `ai_planner_not_connected`를 반환하며 프론트는 가짜 추론으로 대체하지 않는다.

현재 모델 기본값은 `gpt-5.6-luna`. `LIVING_GAME_MODEL` secret으로 변경 가능.

## Runtime mutation contract

- set_avatar_form
- set_control
- set_space
- add_entity / remove_entity
- add_system / remove_system
- set_goal
- set_time
- change_physics
- change_density
- change_relationship
- change_economy
- change_feedback

AI가 임의 JavaScript/GDScript를 쓰는 구조가 아니라 선언형 변경만 요청한다.

## 다음 단계

- Art Direction 3안의 실제 이미지 생성
- telemetry의 장기 Player Model 연동
- Game Pack 서버 저장
- 재방문 게임만 Deepening Factory로 보내기
- Godot Runtime에 동일 mutation contract 구현
