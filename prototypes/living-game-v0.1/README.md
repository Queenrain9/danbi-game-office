# Living Game Diagnostic Prototype v0.1

이 프로토타입은 "새 게임을 누른 뒤 3~5분간의 행동 자체가 프롬프트가 된다"는 제품 가설을 검증하기 위한 최소 세로 슬라이스다.

## 현재 동작

- 첫 화면: 새 게임 / 내 게임팩
- 8개의 게임 내 상황을 통해 암묵적 선호 신호 수집
- 선택과 반응 시간을 Need Vector로 변환
- 사전 구현된 Game Template/Kernel 후보를 점수화
- 상위 3개 게임 후보 공개
- 하나를 선택하면 Game Genome v0.1 생성
- localStorage에 영구 게임으로 저장
- 내 게임팩에서 이어하기
- 방문 수 / 행동 / 레벨 간단 지속
- Game Genome을 URL hash에 넣는 선물 링크 지원

## 의도적으로 아직 하지 않는 것

- LLM 호출
- 이미지 생성
- Supabase 저장
- 실제 Godot 런타임
- 재방문 기반 자동 Deepening
- 행동 모델 학습

첫 검증 목표는 생성 기술이 아니라 다음 한 문장이다.

> 플레이어가 설문에 답했다고 느끼지 않았는데도, 마지막의 3개 후보가 "지금 다 해보고 싶은데?"라는 반응을 만드는가?

## 다음 단계

1. 실제 플레이 로그를 수집할 수 있게 telemetry schema 추가
2. Probe를 단순 선택 카드가 아닌 짧은 조작형 미니 상황으로 교체
3. 후보 생성기를 규칙 점수 + LLM Game Genome 생성으로 확장
4. Game Kernel 3종을 Godot 공용 Runtime으로 구현
5. 재방문 임계치를 넘은 게임을 기존 danbi-game-office production pipeline의 Deepening Queue로 연결
