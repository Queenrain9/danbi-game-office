# Living Game v0.5 — Need Hypothesis Engine

v0.4의 핵심 문제였던 "mutation 반응 점수만 최적화하고 실제 놀이 욕구는 추론하지 않는 구조"를 교체한 버전.

## 핵심 변화

Planner의 핵심 객체가 더 이상 mutation reward가 아니다.

각 세션은 아래 Play Need Hypothesis들을 동시에 유지한다.

- mastery: 숙련
- growth: 성장
- discovery: 발견
- ownership: 소유
- relationship: 관계
- optimization: 최적화
- competition: 경쟁
- expression: 표현
- narrative: 서사
- risk: 위험
- calm: 편안한 반복
- agency: 자유 선택

각 hypothesis는:
- alpha / beta
- evidence
- counter evidence
- test count

를 가진다.

## 루프

행동 관찰
→ 여러 욕구 가설 유지
→ 불확실성이 큰 가설들을 구분할 다음 실험 선택
→ 세계를 실제로 변경
→ 행동 반응 측정
→ 관련 가설 강화/약화
→ 새로운 실험
→ 충분한 증거가 쌓이면 오늘의 핵심 놀이 욕구 확정
→ 현재 world model과 결합해 게임 하나로 crystallize
→ 같은 게임의 Art Direction 3안
→ 즉시 플레이
→ Game Pack 저장

## 중요한 차이

v0.4:
- "어떤 mutation 뒤에 활동량이 늘었나?"

v0.5:
- "왜 그 행동을 했을까?"
- "숙련 때문인가, 경쟁 때문인가?"
- "수집 자체가 좋은가, 성장 재료라서 좋은가?"
- "탐험이 좋은가, 목표가 있을 때만 움직이는가?"
- "NPC가 좋은가, 서사의 다음이 궁금한가?"

다음 실험은 이 가설들을 구분하도록 설계된다.

## 비용

OpenAI API 0회
Supabase 호출 0회
서버 호출 0회
localStorage만 사용

## 현재 한계

언어모델 없이 브라우저 규칙 기반으로 구현되어 있으므로 완전히 새로운 욕구 개념을 발명할 수는 없다.
대신 "장르 분류"가 아니라 사전에 정의된 Play Need hypothesis를 실제 실험으로 검증/반박하는 구조를 검증한다.
