from dataclasses import dataclass, field
from collections import deque

@dataclass
class Mission:
    graph: dict[str, list[str]]
    walls: set[str]
    entrance: str
    relic: str
    alcoves: set[str]
    patrol: list[str]
    tie_break: dict[str, int]
    start_air: int
    clickers: int

@dataclass
class State:
    player: str
    predator: str
    patrol_index: int
    air: int
    clickers: int
    revealed: set[str] = field(default_factory=set)
    relic_collected: bool = False
    predator_mode: str = "Patrol"
    hunt_target: str | None = None
    hunt_steps: int = 0
    result: str | None = None

def shortest_dist(m, start, target):
    q = deque([(start, 0)])
    seen = {start}
    while q:
        n, d = q.popleft()
        if n == target:
            return d
        for nxt in m.graph.get(n, []):
            if nxt in m.walls or nxt in seen:
                continue
            seen.add(nxt)
            q.append((nxt, d + 1))
    return None

def next_step(m, start, target):
    if start == target:
        return start
    candidates = []
    for nxt in m.graph.get(start, []):
        if nxt in m.walls:
            continue
        d = shortest_dist(m, nxt, target)
        if d is not None:
            candidates.append((d, m.tie_break.get(nxt, 9999), nxt))
    return min(candidates)[2] if candidates else start

def reveal(m, origin, radius):
    out = {origin}
    q = deque([(origin, 0)])
    while q:
        n, d = q.popleft()
        if d >= radius:
            continue
        for nxt in m.graph.get(n, []):
            if nxt in out:
                continue
            out.add(nxt)
            if nxt not in m.walls:
                q.append((nxt, d + 1))
    return out

def predator_step(m, s):
    if s.predator_mode == "Hunt" and s.hunt_target:
        s.predator = next_step(m, s.predator, s.hunt_target)
        s.hunt_steps -= 1
        if s.predator == s.hunt_target or s.hunt_steps <= 0:
            opts = []
            for p in m.patrol:
                d = shortest_dist(m, s.predator, p)
                if d is not None:
                    opts.append((d, m.tie_break.get(p, 9999), p))
            target = min(opts)[2]
            if s.predator == target:
                s.predator_mode = "Patrol"
                s.patrol_index = m.patrol.index(target)
                s.hunt_target = None
                s.hunt_steps = 0
    else:
        s.predator_mode = "Patrol"
        s.patrol_index = (s.patrol_index + 1) % len(m.patrol)
        s.predator = m.patrol[s.patrol_index]

def apply_sound(m, s, origin, reveal_radius, hearing):
    s.revealed |= reveal(m, origin, reveal_radius)
    d = shortest_dist(m, s.predator, origin)
    if d is not None and d <= hearing:
        s.predator_mode = "Hunt"
        s.hunt_target = origin
        s.hunt_steps = 3

def finish_action(m, s, hidden=False):
    predator_step(m, s)
    if s.predator == s.player and not hidden:
        s.result = "failure_contact"
        return
    if s.relic_collected and s.player == m.entrance:
        s.result = "success"
        return
    if s.air == 0:
        s.result = "failure_air"

def act(m, s, action):
    if s.result:
        return False
    kind = action[0]
    if kind == "move":
        target = action[1]
        if target not in m.graph.get(s.player, []) or target in m.walls or target not in s.revealed:
            return False
        s.player = target
        s.air -= 1
        if target == m.relic:
            s.relic_collected = True
        finish_action(m, s)
        return True
    if kind == "ping":
        s.air -= 1
        apply_sound(m, s, s.player, 3, 5)
        finish_action(m, s)
        return True
    if kind == "knock":
        s.air -= 1
        apply_sound(m, s, s.player, 5, 8)
        finish_action(m, s)
        return True
    if kind == "clicker":
        target = action[1]
        d = shortest_dist(m, s.player, target)
        if s.clickers <= 0 or target not in s.revealed or target in m.walls or d is None or d > 4:
            return False
        s.clickers -= 1
        s.air -= 1
        apply_sound(m, s, target, 2, 7)
        finish_action(m, s)
        return True
    if kind == "hide":
        if s.player not in m.alcoves:
            return False
        s.air -= 1
        finish_action(m, s, hidden=True)
        return True
    raise ValueError(kind)

def validation_fixture():
    graph = {
        "A": ["B"], "B": ["A", "C"], "C": ["B", "D"],
        "D": ["C", "E"], "E": ["D", "F"], "F": ["E"],
    }
    return Mission(
        graph, set(), "A", "F", {"E"}, ["D", "E", "F", "E"],
        {n: i for i, n in enumerate("ABCDEF")}, 10, 1
    )

def run_checks():
    m = validation_fixture()

    s = State("A", "D", 0, 10, 1, {"A", "B"})
    assert act(m, s, ("ping",))
    assert s.air == 9 and s.predator_mode == "Hunt" and s.hunt_target == "A"
    assert {"A", "B", "C", "D"}.issubset(s.revealed)

    s2 = State("A", "D", 0, 5, 0, {"A"})
    before = (s2.air, s2.predator)
    assert not act(m, s2, ("move", "B"))
    assert (s2.air, s2.predator) == before

    s3 = State("E", "D", 0, 5, 0, {"D", "E", "F"})
    assert act(m, s3, ("hide",))
    assert s3.result is None and s3.air == 4 and s3.predator == "E"

    s4 = State("B", "F", 1, 1, 0, {"A", "B"}, relic_collected=True)
    assert act(m, s4, ("move", "A"))
    assert s4.air == 0 and s4.result == "success"

    print("RULE_CHECKS PASS")
    print("fixture=synthetic_linear_6")
    print("authoring_contract_check=BLOCKED:no authored mission graphs supplied")

if __name__ == "__main__":
    run_checks()
