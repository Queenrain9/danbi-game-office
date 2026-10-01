extends SceneTree

var failures := 0
var game

const M1_CARD := Vector2(270,254)
const OPEN_BRIEF := Vector2(400,835)
const START := Vector2(400,854)
const PAUSE := Vector2(494,67)
const SOUND := Vector2(140,826)
const CLICKER := Vector2(332,826)
const HIDE := Vector2(462,826)
const RESUME := Vector2(270,379)
const RETRY_RESULT := Vector2(146,734)

func check(id:String, condition:bool, note:String) -> void:
    if condition:
        print("PASS ", id, " ", note)
    else:
        failures += 1
        push_error("FAIL %s %s" % [id, note])

func snap() -> Dictionary:
    return game.debug_snapshot()

func tap(p:Vector2) -> bool:
    return game.debug_tap(p)

func swipe(a:Vector2, b:Vector2, duration:float) -> bool:
    return game.debug_swipe(a, b, duration)

func press(p:Vector2, duration:float, release_at:Vector2) -> bool:
    return game.debug_press(p, duration, release_at)

func drag(path:Array[Vector2], duration:float) -> bool:
    return game.debug_drag(path, duration)

func wait_resolve() -> void:
    await create_timer(0.80).timeout

func _initialize() -> void:
    var scene = load("res://scenes/main.tscn")
    check("BOOT", scene != null, "main scene exists")
    if scene == null:
        quit(1)
        return
    game = scene.instantiate()
    root.add_child(game)
    await process_frame

    for method_name in ["debug_tap","debug_swipe","debug_drag","debug_press","debug_ui_snapshot","debug_snapshot","debug_load_fixture","debug_act"]:
        check("HOOK", game.has_method(method_name), method_name + " exists")
    if failures > 0:
        quit(1)
        return

    check("I_NAV", tap(M1_CARD), "select M1")
    check("I_NAV", tap(OPEN_BRIEF), "open brief")
    check("I_NAV", tap(START), "start M1")
    await process_frame
    check("I_NAV", snap()["mission_id"] == "M1", "M1 reached through UI")

    var before := snap().duplicate(true)
    check("I_MOVE", swipe(Vector2(84,216), Vector2(150,216), 0.18), "right swipe accepted")
    var after_move := snap().duplicate(true)
    check("I_MOVE", after_move["player_tile"] == "1,0" and after_move["air"] == before["air"] - 1, "one semantic Move")
    var duplicate_before := snap().duplicate(true)
    var duplicate_ok := swipe(Vector2(208,216), Vector2(274,216), 0.18)
    check("I_LOCK", duplicate_ok == false and snap() == duplicate_before, "duplicate gameplay input rejected during resolve")
    await wait_resolve()

    check("I_PAUSE", tap(PAUSE), "pause opens")
    var paused_before := snap().duplicate(true)
    var blocked := swipe(Vector2(208,216), Vector2(274,216), 0.18)
    check("I_PAUSE", blocked == false and snap() == paused_before, "pause blocks cave swipe")
    check("I_PAUSE", tap(RESUME), "resume closes pause")

    game.debug_load_fixture("M1")
    var initial := snap().duplicate(true)
    check("I_SOUND", press(SOUND, 0.599, SOUND), "599ms accepted")
    var ping_state := snap().duplicate(true)
    check("I_SOUND", ping_state["air"] == initial["air"] - 1, "599ms maps to one sound action")
    await wait_resolve()

    game.debug_load_fixture("M1")
    initial = snap().duplicate(true)
    check("I_SOUND", press(SOUND, 0.600, SOUND), "600ms accepted")
    var knock_state := snap().duplicate(true)
    check("I_SOUND", knock_state["air"] == initial["air"] - 1, "600ms maps to one sound action")
    check("I_SOUND", knock_state["revealed_tiles"].size() >= ping_state["revealed_tiles"].size(), "Knock reveal not smaller than Ping")
    await wait_resolve()

    game.debug_load_fixture("M1")
    initial = snap().duplicate(true)
    var cancelled := press(SOUND, 0.750, Vector2(500,900))
    check("I_CANCEL", cancelled == false and snap() == initial, "drag-off cancels with no rule mutation")

    game.debug_load_fixture("M3")
    game.debug_act({"type":"knock"})
    await wait_resolve()
    var click_before := snap().duplicate(true)
    check("I_CLICKER", drag([CLICKER, Vector2(332,700), Vector2(333,466)], 0.35), "valid Clicker drop accepted")
    var click_after := snap().duplicate(true)
    check("I_CLICKER", click_after["clickers"] == click_before["clickers"] - 1 and click_after["air"] == click_before["air"] - 1, "production drag maps to Clicker")
    await wait_resolve()

    game.debug_load_fixture("M3")
    game.debug_act({"type":"knock"})
    await wait_resolve()
    click_before = snap().duplicate(true)
    var invalid_drop := drag([CLICKER, Vector2(400,720), Vector2(457,591)], 0.35)
    check("I_CLICKER_INVALID", invalid_drop == false and snap() == click_before, "invalid Clicker release changes nothing")

    game.debug_load_fixture("M2")
    game.debug_act({"type":"knock"})
    game.debug_act({"type":"move","target":"1,0"})
    game.debug_act({"type":"move","target":"2,0"})
    game.debug_act({"type":"move","target":"2,1"})
    await wait_resolve()
    var hide_before := snap().duplicate(true)
    check("I_HIDE", tap(HIDE), "Hide accepted on Alcove")
    check("I_HIDE", snap()["air"] == hide_before["air"] - 1, "Hide maps to one rule action")
    await wait_resolve()

    game.debug_load_fixture("TEST_AIR_FAILURE")
    check("I_RESULT", tap(SOUND), "failure action entered via production SOUND")
    await wait_resolve()
    check("I_RESULT", snap()["result"] == "failure_air", "Air failure authoritative")
    check("I_RESULT", tap(RETRY_RESULT), "Result Retry accepted")
    await process_frame
    check("I_RESULT", snap()["result"] == null and snap()["mission_id"] != "", "Retry restored authored mission state")

    if failures == 0:
        print("INPUT SMOKE PASS")
        quit(0)
    else:
        print("INPUT SMOKE FAIL ", failures)
        quit(1)
