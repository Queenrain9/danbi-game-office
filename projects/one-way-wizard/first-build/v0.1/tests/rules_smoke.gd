extends SceneTree

var failures := 0
var game

func check(id:String, condition:bool, note:String) -> void:
    if condition:
        print("PASS ", id, " ", note)
    else:
        failures += 1
        push_error("FAIL %s %s" % [id, note])

func approx(a:float,b:float,eps:float=0.002) -> bool:
    return abs(a-b) <= eps

func _initialize() -> void:
    var scene = load("res://scenes/main.tscn")
    check("BOOT", scene != null, "main scene exists")
    if scene == null:
        quit(1); return
    game = scene.instantiate()
    root.add_child(game)
    await process_frame

    game.debug_load_fixture("WAVE2_INITIAL")
    var s0 = game.debug_snapshot()
    game.debug_step(1.0)
    check("M1", game.rule_tick - s0.rule_tick == 60, "fixed 60Hz rule clock")

    game.debug_load_fixture("WAVE2_INITIAL")
    var mana0 = game.mana
    check("M2", game.debug_cast(0.0), "first Bolt cast accepted")
    check("M2", game.mana == mana0-1 and game.projectiles.size() == 1, "valid cast exact cost")
    check("M2", game.debug_cast(0.0) == false, "cast cooldown rejects immediate second cast")

    game.debug_load_fixture("TEST_CAP8")
    mana0 = game.mana
    check("M2", game.debug_cast(0.0) == false and game.mana == mana0 and game.projectiles.size() == 8, "cap8 reject no cost")

    game.debug_load_fixture("TEST_WRAP")
    game.debug_step(0.10)
    var p = game.projectiles[0]
    check("M3", approx(float(p.x),0.012) and approx(float(p.lifetime),17.9), "wrap keeps lifetime clock")

    game.debug_load_fixture("TEST_MANA2")
    game.debug_step(8.0)
    check("M4", game.mana == 4, "mana regen 4s cadence and cap")

    game.debug_load_fixture("TEST_REDIRECT")
    var r0 = game.redirect_charges
    check("M5", game.debug_launch_tool("redirect",0.0), "Redirect pulse launched")
    game.debug_step(0.20)
    check("M5", approx(float(game.projectiles[0].angle_degrees),90.0) and game.redirect_charges == r0-1, "Redirect exact +90 on hit")

    game.debug_load_fixture("TEST_SPLIT_POSITIVE")
    var c0 = game.split_charges
    check("M6", game.debug_launch_tool("split",90.0), "Split pulse launched")
    game.debug_step(0.20)
    check("M6", game.projectiles.size() == 2 and game.split_charges == c0-1, "Split creates one child")
    check("M6", approx(float(game.projectiles[1].angle_degrees),30.0), "positive cross uses +30 child")

    game.debug_load_fixture("TEST_SPLIT_CAP8")
    c0 = game.split_charges
    check("M6", game.debug_launch_tool("split",90.0), "Split pulse can be launched at cap")
    game.debug_step(0.20)
    check("M6", game.projectiles.size() == 8 and game.split_charges == c0, "cap8 Split no child/no charge")

    game.debug_load_fixture("TEST_MERGE_0_30")
    game.debug_step(1.0/60.0)
    check("M7", game.projectiles.size() == 1, "compatible Bolts merge")
    p = game.projectiles[0]
    check("M7", approx(float(p.angle_degrees),15.0) and int(p.damage)==2 and approx(float(p.lifetime),16.0) and bool(p.empowered), "deterministic merge result")

    game.debug_load_fixture("WAVE2_INITIAL")
    game.debug_step(9.61)
    check("M8", game.spawn_cursor == 7 and game.enemies.size() <= 7, "all Wave2 scheduled spawns emitted")

    game.debug_load_fixture("TEST_CONTACT")
    var hp0 = game.hp
    game.debug_step(1.0/60.0)
    check("M9", game.hp == hp0-1, "first contact damages")
    game.debug_step(0.5)
    check("M9", game.hp == hp0-1, "invulnerability blocks repeated contact")

    game.debug_load_fixture("WAVE2_INITIAL")
    var before = game.debug_snapshot().duplicate(true)
    game.debug_pause(true)
    game.debug_step(1.0)
    check("M10", game.debug_snapshot() == before, "Pause freezes rule state")
    game.debug_pause(false)
    game.debug_cast(0.0)
    game.debug_retry()
    check("M10", game.debug_snapshot() == before, "Retry restores Wave2 initial state")

    if failures == 0:
        print("RULE SMOKE PASS")
        quit(0)
    else:
        print("RULE SMOKE FAIL ", failures)
        quit(1)
