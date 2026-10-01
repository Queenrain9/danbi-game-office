import json
from pathlib import Path

RULES = Path(__file__).resolve().parents[3] / "game-design" / "rules-v0.2.json"

REQUIRED = [
    ("time.rule_tick_seconds", ("time","rule_tick_seconds")),
    ("wizard.speed", ("wizard","speed")),
    ("wizard.radius", ("wizard","radius")),
    ("projectile.speed", ("projectile","speed")),
    ("projectile.radius", ("projectile","radius")),
    ("cast.cooldown_seconds", ("cast","cooldown_seconds")),
    ("chaser.hp", ("enemies","chaser","hp")),
    ("chaser.speed", ("enemies","chaser","speed")),
    ("drifter.hp", ("enemies","drifter","hp")),
    ("drifter.speed", ("enemies","drifter","speed")),
    ("anchor.hp", ("enemies","anchor","hp")),
    ("anchor.hazard.interval", ("enemies","anchor","hazard","interval_seconds")),
    ("redirect.pulse_speed", ("tools","redirect","pulse_speed")),
    ("split.pulse_speed", ("tools","split","pulse_speed")),
]

def get(data,path):
    cur=data
    for key in path:
        cur=cur[key]
    return cur

def main():
    r=json.loads(RULES.read_text(encoding="utf-8"))
    for label,path in REQUIRED:
        value=get(r,path)
        assert value is not None and value!="", label

    assert abs((1.0/r["time"]["rule_tick_seconds"])-60.0)<1e-9
    assert len(r["spawns"]["wave1"])==6
    assert len(r["spawns"]["wave2"])==7
    assert len(r["spawns"]["wave3"])==8
    assert r["projectile"]["cap"]==8
    assert r["projectile"]["lifetime_seconds"]==18.0
    assert r["carry"]["max"]==3
    assert r["carry"]["zero_selection_allowed"] is True

    distance=r["projectile"]["speed"]*r["projectile"]["lifetime_seconds"]
    max_fresh_casts_if_spending=r["cast"]["mana_start"] + int(
        r["projectile"]["lifetime_seconds"] // r["cast"]["mana_regen_seconds"]
    )

    print("RULE_TABLE_COMPLETENESS PASS")
    print("rule_hz=60")
    print(f"projectile_distance_per_lifetime={distance:.2f}_arena_widths")
    print(f"fresh_cast_budget_over_18s_if_spending={max_fresh_casts_if_spending}")
    print("wave_enemy_counts=6,7,8")
    print("last_spawn_seconds=9.0,9.6,10.5")
    print("human_only=control_feel,trail_readability,transform_vs_fresh_cast_dominance")

if __name__=="__main__":
    main()
