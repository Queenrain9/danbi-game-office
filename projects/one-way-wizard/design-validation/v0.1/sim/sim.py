from dataclasses import dataclass
import math

FIXED_DT = 0.05
ARENA_W = 1.0
ARENA_H = 1.0
PROJECTILE_SPEED = 0.22
PROJECTILE_LIFETIME = 18.0
PROJECTILE_CAP = 8
MANA_MAX = 4
MANA_REGEN_SECONDS = 4.0

@dataclass
class Projectile:
    x: float
    y: float
    angle_deg: float
    lifetime: float = PROJECTILE_LIFETIME
    damage: int = 1
    empowered: bool = False

@dataclass
class Sim:
    mana: int = 4
    mana_clock: float = 0.0
    projectiles: list | None = None

    def __post_init__(self):
        if self.projectiles is None:
            self.projectiles = []

def velocity(angle):
    r = math.radians(angle)
    return math.cos(r) * PROJECTILE_SPEED, math.sin(r) * PROJECTILE_SPEED

def cast(sim, x, y, angle):
    if sim.mana <= 0 or len(sim.projectiles) >= PROJECTILE_CAP:
        return False
    # Game Design references "cast cooldown clear" but does not define its duration.
    sim.mana -= 1
    sim.projectiles.append(Projectile(x, y, angle))
    return True

def step(sim, seconds):
    ticks = round(seconds / FIXED_DT)
    assert abs(ticks * FIXED_DT - seconds) < 1e-9
    for _ in range(ticks):
        sim.mana_clock += FIXED_DT
        while sim.mana_clock + 1e-12 >= MANA_REGEN_SECONDS:
            sim.mana_clock -= MANA_REGEN_SECONDS
            sim.mana = min(MANA_MAX, sim.mana + 1)

        keep = []
        for p in sim.projectiles:
            vx, vy = velocity(p.angle_deg)
            p.x = (p.x + vx * FIXED_DT) % ARENA_W
            p.y = (p.y + vy * FIXED_DT) % ARENA_H
            p.lifetime -= FIXED_DT
            if p.lifetime > 1e-9:
                keep.append(p)
        sim.projectiles = keep

def redirect90(p):
    p.angle_deg = (p.angle_deg + 90.0) % 360.0

def split30(sim, p):
    if len(sim.projectiles) >= PROJECTILE_CAP:
        return False
    # +30 is only a temporary test convention. Design must pin the actual side/reference axis.
    sim.projectiles.append(
        Projectile(p.x, p.y, (p.angle_deg + 30.0) % 360.0, p.lifetime, p.damage, p.empowered)
    )
    return True

def merge(a, b):
    if a.empowered or b.empowered:
        return None
    diff = abs((a.angle_deg - b.angle_deg + 180) % 360 - 180)
    if diff > 45.0:
        return None
    return Projectile(
        (a.x + b.x) / 2,
        (a.y + b.y) / 2,
        a.angle_deg,
        min(max(a.lifetime, b.lifetime) + 4.0, 18.0),
        2,
        True,
    )

def run_checks():
    s = Sim()
    assert cast(s, 0.99, 0.5, 0)
    before = s.projectiles[0].lifetime
    step(s, 0.10)
    p = s.projectiles[0]
    assert p.x < 0.05 and abs((before - p.lifetime) - 0.10) < 1e-8

    s2 = Sim()
    s2.projectiles = [Projectile(.5, .5, 0) for _ in range(8)]
    mana = s2.mana
    assert not cast(s2, .5, .5, 0) and s2.mana == mana

    s3 = Sim(mana=2)
    step(s3, 8.0)
    assert s3.mana == 4

    p = Projectile(.5, .5, 0)
    redirect90(p)
    assert p.angle_deg == 90.0

    s4 = Sim(projectiles=[Projectile(.5, .5, 0)])
    assert split30(s4, s4.projectiles[0])
    assert len(s4.projectiles) == 2 and abs(s4.projectiles[1].angle_deg - 30.0) < 1e-8

    a = Projectile(.5, .5, 10, lifetime=10)
    b = Projectile(.5, .5, 40, lifetime=12)
    merged = merge(a, b)
    assert merged and merged.damage == 2 and merged.empowered
    assert abs(merged.lifetime - 16.0) < 1e-8

    print("PARTIAL_RULE_CHECKS PASS")
    print("fixed_dt", FIXED_DT)
    print("blocking_missing=wizard_speed,enemy_speeds,enemy_hp,spawn_cadence,cast_cooldown,pulse_geometry,collision_radii,anchor_hazard_numbers")
    print("split_semantics=AMBIGUOUS: mirrored30 needs reference axis/sign")

if __name__ == "__main__":
    run_checks()
