# Living Game v0.3 — Game Invention Prototype

v0.2의 가장 큰 오류였던 "점 게임 몇 종류 중 하나를 고르는 구조"를 제거한 버전이다.

## 이번 버전의 원칙

- 점은 게임 장르가 아니라 최초 입력 장치다.
- 시스템은 처음부터 레이싱/육성/추리 후보를 놓고 좁히지 않는다.
- 일정 간격마다 `현재 세계 상태 + 방금 행동`을 보고 다음에 붙일 게임 문법을 다시 결정한다.
- 붙을 수 있는 문법은 조작, 공간, 엔티티, 시스템, 시간 구조로 분리한다.
- 세션마다 실제로 붙은 문법 조합이 달라지며, 그 결과에서 최종 게임 하나를 기획한다.
- 최종 게임은 미리 정의된 완성 템플릿 ID를 선택하지 않는다.
- 게임이 확정된 뒤 사용자에게 고르게 하는 것은 동일 게임의 Art Direction 3안뿐이다.
- 아트 선택 뒤 해당 세션의 world model을 그대로 고정해 즉시 플레이 가능한 게임으로 이어진다.

## 현재 primitive / mutation 예시

Control:
- direct
- inertia

Space:
- flat
- depth
- worldmap

Entity:
- target
- companion
- npc
- hazards
- base

System:
- trail
- collect
- resource
- upgrade
- dialogue
- projectile
- construction

Time:
- continuous
- rounds

이 목록 자체도 앞으로 고정 장르가 아니라 더 작은 조립 단위로 확장한다.

## 현재 AI 구현

실제 LLM 호출은 아직 넣지 않았다.
행동 telemetry와 현재 world model을 바탕으로 사용 가능한 mutation 후보를 동적으로 평가하는 정책을 사용한다.

다음 단계에서는 이 planner가 다음과 같은 선언형 명령을 생성하게 바꾼다.

```json
{
  "reason": "사용자가 가장자리 탐색과 빠른 곡선 이동을 반복했다",
  "mutation": {
    "kind": "space",
    "op": "add_depth",
    "parameters": {
      "camera": "pseudo_3d"
    }
  }
}
```

핵심은 LLM이 코드를 직접 작성하는 것이 아니라 runtime이 이해하는 합법적 mutation을 선택/조합하게 하는 것이다.
