import json
from collections import deque
from dataclasses import dataclass
from pathlib import Path

FIXTURES = Path(__file__).resolve().parents[3] / "game-design" / "expeditions-v0.2.json"

def build_graph(m):
    blocked=set(m["blocked"])
    g={}
    for y in range(m["height"]):
        for x in range(m["width"]):
            n=f"{x},{y}"
            if n in blocked:
                continue
            g[n]=[]
            for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
                xx,yy=x+dx,y+dy
                t=f"{xx},{yy}"
                if 0<=xx<m["width"] and 0<=yy<m["height"] and t not in blocked:
                    g[n].append(t)
    return g

def all_dist(g):
    d={}
    for s in g:
        q=deque([s])
        d[(s,s)]=0
        while q:
            n=q.popleft()
            for t in g[n]:
                if (s,t) not in d:
                    d[(s,t)]=d[(s,n)]+1
                    q.append(t)
    return d

@dataclass
class State:
    player:str
    predator:str
    patrol_index:int
    air:int
    clickers:int
    revealed:set
    relic_collected:bool=False
    mode:str="Patrol"
    hunt_target:str|None=None
    hunt_steps:int=0
    return_target:str|None=None
    result:str|None=None

def run_mission(m):
    g=build_graph(m)
    d=all_dist(g)
    tie={n:i for i,n in enumerate(sorted(g,key=lambda s:(int(s.split(",")[1]),int(s.split(",")[0]))))}
    patrol=m["patrol"]
    s=State(m["entrance"],m["predator_start"],patrol.index(m["predator_start"]),
            m["air"],m["clickers"],{m["entrance"],*g[m["entrance"]]})

    def reveal(origin,radius):
        return {n for n in g if d[(origin,n)]<=radius}

    def next_step(start,target):
        if start==target:
            return start
        return min((d[(n,target)],tie[n],n) for n in g[start])[2]

    def predator_step():
        if s.mode=="Hunt":
            s.predator=next_step(s.predator,s.hunt_target)
            s.hunt_steps-=1
            if s.predator==s.hunt_target or s.hunt_steps<=0:
                s.return_target=min((d[(s.predator,p)],tie[p],p) for p in set(patrol))[2]
                s.hunt_target=None
                s.hunt_steps=0
                if s.predator==s.return_target:
                    s.mode="Patrol"
                    s.patrol_index=patrol.index(s.return_target)
                    s.return_target=None
                else:
                    s.mode="ReturnToPatrol"
        elif s.mode=="ReturnToPatrol":
            s.predator=next_step(s.predator,s.return_target)
            if s.predator==s.return_target:
                s.mode="Patrol"
                s.patrol_index=patrol.index(s.return_target)
                s.return_target=None
        else:
            s.patrol_index=(s.patrol_index+1)%len(patrol)
            s.predator=patrol[s.patrol_index]

    def hear(origin,radius):
        if d[(s.predator,origin)]<=radius:
            s.mode="Hunt"
            s.hunt_target=origin
            s.hunt_steps=3
            s.return_target=None

    used={"ping":0,"knock":0,"clicker":0,"hide":0}
    for turn,action in enumerate(m["success_route"],1):
        kind=action[0]
        hidden=False
        if kind=="move":
            target=action[1]
            assert target in g[s.player] and target in s.revealed
            s.player=target
            s.air-=1
            if target==m["relic"]:
                s.relic_collected=True
        elif kind=="ping":
            used["ping"]+=1
            s.air-=1
            s.revealed |= reveal(s.player,3)
            hear(s.player,5)
        elif kind=="knock":
            used["knock"]+=1
            s.air-=1
            s.revealed |= reveal(s.player,5)
            hear(s.player,8)
        elif kind=="clicker":
            used["clicker"]+=1
            target=action[1]
            assert s.clickers>0 and target in s.revealed and d[(s.player,target)]<=4
            s.clickers-=1
            s.air-=1
            s.revealed |= reveal(target,2)
            hear(target,7)
        elif kind=="hide":
            used["hide"]+=1
            assert s.player in set(m["alcoves"])
            s.air-=1
            hidden=True
        else:
            raise AssertionError(action)

        predator_step()

        if s.predator==s.player and not hidden:
            s.result="failure_contact"
        elif s.relic_collected and s.player==m["entrance"]:
            s.result="success"
        elif s.air==0:
            s.result="failure_air"

        assert s.result not in ("failure_contact","failure_air")
        if s.result=="success":
            assert turn==len(m["success_route"])
            return {"id":m["id"],"class":m["class"],"turns":turn,
                    "air_remaining":s.air,"walkable_nodes":len(g),"used":used}

    raise AssertionError((m["id"],"route did not succeed"))

def main():
    data=json.loads(FIXTURES.read_text(encoding="utf-8"))
    results=[run_mission(m) for m in data["missions"]]
    assert len(results)==6
    by_id={r["id"]:r for r in results}
    assert by_id["M2"]["used"]["hide"]>0
    assert by_id["M3"]["used"]["clicker"]>0
    assert by_id["M6"]["used"]["hide"]>0 and by_id["M6"]["used"]["clicker"]>0
    print("AUTHORED_EXPEDITIONS PASS")
    for r in results:
        print(json.dumps(r,ensure_ascii=False,sort_keys=True))

if __name__=="__main__":
    main()
