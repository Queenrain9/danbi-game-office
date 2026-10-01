extends SceneTree
# Locked INPUT v1.0. Rules remain in unchanged upstream rules_smoke.gd.
# Synthetic gestures route through production input; debug_step controls rule time.
var game
var failures = 0
const MOVE = Vector2(134,790)
const AIM = Vector2(406,790)
const CAST = Vector2(94,924)
const REDIRECT = Vector2(270,924)
const SPLIT = Vector2(446,924)
const PAUSE = Vector2(494,70)
const RESUME = Vector2(270,380)

func check(id:String, ok:bool) -> void:
    if ok:
        print("INPUT PASS ",id)
    else:
        failures += 1
        push_error("INPUT FAIL " + id)

func snap() -> Dictionary:
    return game.debug_snapshot().duplicate(true)

func ui() -> Dictionary:
    return game.debug_ui_snapshot()

func pointer(phase:String, p:Vector2, seq:int, ms:int, pid:int=1) -> void:
    game.debug_pointer({"phase":phase,"position":p,"sequence_id":seq,"time_ms":ms,"pointer_id":pid})

func reset(name:String="WAVE2_INITIAL") -> void:
    game.debug_load_fixture(name)

func tap(p:Vector2) -> bool:
    return game.debug_tap(p)

func last_action(kind:String, angle:float) -> bool:
    var h = ui().dispatch_history
    if h.is_empty():
        return false
    var a = h[-1]
    return a.get("type","") == kind and abs(float(a.get("angle_degrees",-999)) - angle) < 0.01

func _initialize() -> void:
    var scene = load("res://scenes/main.tscn")
    check("BOOT",scene != null)
    if scene == null:
        quit(1)
        return
    game = scene.instantiate()
    root.add_child(game)
    await process_frame
    for method in ["debug_tap","debug_drag","debug_pointer","debug_ui_snapshot","debug_snapshot","debug_load_fixture","debug_step"]:
        check("HOOK_"+method,game.has_method(method))
    if failures > 0:
        quit(1)
        return

    # Initial Brief is the production entry screen.
    check("ENTRY",ui().screen == "S1_WAVE2_BRIEF")
    check("START",tap(Vector2(270,830)))
    var initial = snap()
    check("WAVE2_ONLY",ui().screen == "S2_ARENA" and initial.wave_index == 2)
    tap(Vector2(270,120))
    check("BACKGROUND",snap() == initial)

    reset()
    pointer("down",MOVE,10,0)
    pointer("move",MOVE+Vector2(16,0),10,40)
    check("MOVE_DEADZONE_INCLUSIVE",ui().move_vector == Vector2.ZERO)
    pointer("move",MOVE+Vector2(48,0),10,60)
    check("MOVE_HALF_SCALE",ui().move_vector.distance_to(Vector2(0.5,0)) < 0.001)
    pointer("move",MOVE+Vector2(80,0),10,80)
    check("MOVE_SATURATION",ui().move_vector.distance_to(Vector2.RIGHT) < 0.001)
    var tick0 = snap().rule_tick
    game.debug_step(0.1)
    check("MOVE_CLOCK",snap().rule_tick == tick0+6)
    pointer("cancel",MOVE+Vector2(80,0),10,180)
    check("MOVE_CANCEL",ui().move_vector == Vector2.ZERO)

    reset()
    pointer("down",AIM,20,0,2)
    pointer("move",AIM+Vector2(0,16),20,20,2)
    check("AIM_DEADZONE",abs(float(ui().aim_degrees)) < 0.01)
    pointer("move",AIM+Vector2(0,80),20,40,2)
    pointer("up",AIM+Vector2(0,80),20,80,2)
    check("AIM_RETAINED",abs(float(ui().aim_degrees)-90.0) < 0.01 and snap().projectiles.is_empty())
    var mana0 = snap().mana
    check("CAST_ACCEPTED",tap(CAST))
    check("CAST_MAP",last_action("cast",90.0))
    check("INPUT_TO_RULE",snap().mana == mana0-1 and snap().projectiles.size() == 1)
    var after_cast = snap()
    check("COOLDOWN_DISABLED",tap(CAST) == false and snap() == after_cast)
    game.debug_step(0.35)
    check("CAST_DURING_EFFECT",tap(CAST) and last_action("cast",90.0))
    check("SECOND_CAST_RULE",snap().projectiles.size() == 2)

    # Move and aim are independently captured; extra pointer cannot steal pad.
    reset()
    pointer("down",MOVE,30,0,1)
    pointer("move",MOVE+Vector2(80,0),30,20,1)
    pointer("down",AIM,31,20,2)
    pointer("move",AIM+Vector2(0,80),31,40,2)
    pointer("down",MOVE,32,40,3)
    pointer("move",MOVE+Vector2(-80,0),32,60,3)
    check("MULTITOUCH",ui().move_vector.distance_to(Vector2.RIGHT)<0.001 and abs(float(ui().aim_degrees)-90.0)<0.01)
    tap(PAUSE)
    check("PAUSE_CAPTURE_CANCEL",ui().screen == "S3_PAUSE" and ui().move_vector == Vector2.ZERO and ui().pointer_capture_count == 0)
    var paused = snap()
    game.debug_step(1.0)
    tap(CAST)
    check("PAUSE_FREEZE",snap() == paused)
    tap(RESUME)
    pointer("up",AIM+Vector2(0,80),31,100,2)
    check("STALE_RELEASE",snap().projectiles.is_empty() and ui().pointer_capture_count == 0)

    # Tap boundaries and duplicate release. Gesture time is input metadata only.
    reset()
    pointer("down",CAST,40,0)
    pointer("up",CAST+Vector2(12,0),40,500)
    check("TAP_BOUNDARY",last_action("cast",0.0) and snap().projectiles.size() == 1)
    game.debug_step(0.35)
    var before_duplicate = snap()
    pointer("up",CAST+Vector2(12,0),40,500)
    check("DUPLICATE_RELEASE",snap() == before_duplicate)
    for pair in [[12.01,500],[0.0,501]]:
        reset()
        var before = snap()
        pointer("down",CAST,41,0)
        pointer("up",CAST+Vector2(pair[0],0),41,int(pair[1]))
        check("TAP_OUTSIDE_"+str(pair),snap() == before)
    reset()
    var unchanged = snap()
    pointer("down",CAST,42,0)
    pointer("move",CAST+Vector2(100,0),42,30)
    pointer("up",CAST,42,80)
    check("DRAG_OFF_NO_FALLBACK",snap() == unchanged)
    pointer("down",CAST,43,100)
    pointer("cancel",CAST,43,120)
    pointer("up",CAST,43,180)
    check("POINTER_CANCEL",snap() == unchanged)

    reset("TEST_CAP8")
    var cap_state = snap()
    check("CAP_DISABLED",tap(CAST) == false and snap() == cap_state)
    reset("TEST_REDIRECT")
    var charge0 = snap().redirect_charges
    check("REDIRECT_LAUNCH",tap(REDIRECT) and last_action("redirect",0.0))
    check("REDIRECT_NO_EARLY_COST",snap().redirect_charges == charge0)
    game.debug_step(0.2)
    check("REDIRECT_RULE_OBSERVED",snap().redirect_charges == charge0-1)

    reset("TEST_SPLIT_POSITIVE")
    game.debug_drag([AIM,AIM+Vector2(0,80)],0.1)
    charge0 = snap().split_charges
    check("SPLIT_LAUNCH",tap(SPLIT) and last_action("split",90.0))
    check("SPLIT_NO_EARLY_COST",snap().split_charges == charge0)
    game.debug_step(0.2)
    check("SPLIT_RULE_OBSERVED",snap().split_charges == charge0-1)
    reset("TEST_SPLIT_CAP8")
    game.debug_drag([AIM,AIM+Vector2(0,80)],0.1)
    charge0 = snap().split_charges
    check("SPLIT_CAP_LAUNCH",tap(SPLIT))
    game.debug_step(0.2)
    check("SPLIT_CAP_NO_COST",snap().split_charges == charge0)

    # Existing contact fixture drives authoritative failure; no forced result hook.
    reset("TEST_CONTACT")
    for i in range(10):
        if snap().result != null:
            break
        game.debug_step(1.0)
    check("RESULT_FROM_RULE",snap().result != null and ui().screen == "S4_RESULT")
    var terminal = snap()
    tap(CAST)
    tap(REDIRECT)
    game.debug_drag([MOVE,MOVE+Vector2(80,0)],0.1)
    check("TERMINAL_BLOCKS",snap() == terminal)
    check("RESULT_RETRY",tap(Vector2(150,800)))
    check("RETRY_WAVE2",snap() == initial and ui().screen == "S2_ARENA" and abs(float(ui().aim_degrees))<0.01)
    tap(PAUSE)
    tap(Vector2(270,620))
    check("BACK_TO_BRIEF",ui().screen == "S1_WAVE2_BRIEF")
    tap(Vector2(270,830))
    tap(CAST)
    tap(PAUSE)
    tap(Vector2(270,500))
    check("PAUSE_RETRY",snap() == initial and ui().screen == "S2_ARENA")

    print("INPUT SMOKE ", "PASS" if failures == 0 else "FAIL")
    quit(0 if failures == 0 else 1)
