extends SceneTree

var failures := 0
var game

func check(id:String, condition:bool, note:String) -> void:
    if condition:
        print("PASS ", id, " ", note)
    else:
        failures += 1
        push_error("FAIL %s %s" % [id, note])

func snapshot() -> Dictionary:
    return game.debug_snapshot()

func act(a:Dictionary) -> bool:
    return game.debug_act(a)

func replay(actions:Array) -> void:
    for a in actions:
        var ok = act(a)
        check("REPLAY", ok, "authored action accepted: "+str(a))

func _initialize() -> void:
    var scene = load("res://scenes/main.tscn")
    check("BOOT", scene != null, "main scene exists")
    if scene == null:
        quit(1); return
    game = scene.instantiate()
    root.add_child(game)
    await process_frame

    game.debug_load_fixture("M1")
    var initial = snapshot()
    check("M1", initial.mission_id == "M1" and initial.air == 22 and initial.clickers == 0, "authored M1 initial state")

    var before = snapshot().duplicate(true)
    var invalid = act({"type":"move","target":"0,2"})
    check("M2", invalid == false and snapshot() == before, "invalid unrevealed move is no-op")

    game.debug_load_fixture("M1")
    var air0 = game.air
    check("M3", act({"type":"ping"}) and game.air == air0-1, "Ping costs one Air")
    check("M3", game.predator_mode in ["Hunt","ReturnToPatrol","Patrol"], "Ping resolves deterministic predator state")

    game.debug_load_fixture("M1")
    air0 = game.air
    check("M4", act({"type":"move","target":"1,0"}), "setup move")
    check("M4", act({"type":"knock"}) and game.air == air0-2, "Knock accepted with exact Air cost")

    game.debug_load_fixture("M3")
    check("M5", act({"type":"move","target":"1,0"}), "M3 setup")
    check("M5", act({"type":"ping"}), "M3 reveal")
    check("M5", act({"type":"move","target":"2,0"}), "M3 setup 2")
    var c0 = game.clickers
    check("M5", act({"type":"clicker","target":"2,2"}) and game.clickers == c0-1, "remote Clicker cost/origin path")
    check("M5", game.predator_hunt_target == "2,2" or game.predator_mode == "ReturnToPatrol", "Clicker retargets before predator step")

    var routes = {
        "M1":[["move","1,0"],["knock"],["move","2,0"],["move","3,0"],["move","3,1"],["move","3,2"],["move","3,3"],["move","3,2"],["move","2,2"],["move","1,2"],["move","0,2"],["move","0,1"],["move","0,0"]],
        "M2":[["move","1,0"],["knock"],["move","2,0"],["move","2,1"],["move","2,2"],["hide"],["move","3,2"],["move","3,3"],["move","2,3"],["move","1,3"],["move","0,3"],["move","0,2"],["move","0,1"],["move","0,0"]],
        "M3":[["move","1,0"],["ping"],["move","2,0"],["clicker","2,2"],["move","3,0"],["move","3,1"],["move","3,2"],["move","3,3"],["move","2,3"],["move","2,2"],["move","1,2"],["move","0,2"],["move","0,1"],["move","0,0"]]
    }
    var expected_air = {"M1":9,"M2":9,"M3":10}
    for mission in ["M1","M2","M3"]:
        game.debug_load_fixture(mission)
        var actions:Array = []
        for raw in routes[mission]:
            var a = {"type":raw[0]}
            if raw.size() > 1: a["target"] = raw[1]
            actions.append(a)
        replay(actions)
        check("M6", game.predator_mode in ["Patrol","Hunt","ReturnToPatrol"], "AI remains in frozen state machine")
        check("M7", mission != "M2" or game.result == "success", "M2 Hide route survives")
        check("M8", game.result == "success" and game.air == expected_air[mission], mission+" authored route result")

    game.debug_load_fixture("M1")
    act({"type":"move","target":"1,0"})
    game.debug_retry()
    check("M10", snapshot() == initial, "Retry restores complete initial M1 rule state")

    # M9 failure fixtures are supplied by Builder through debug_load_fixture aliases.
    game.debug_load_fixture("TEST_CONTACT_FAILURE")
    check("M9", act({"type":"ping"}) and game.result == "failure_contact", "contact failure reachable")
    game.debug_load_fixture("TEST_AIR_FAILURE")
    check("M9", act({"type":"ping"}) and game.result == "failure_air", "Air failure reachable")

    if failures == 0:
        print("RULE SMOKE PASS")
        quit(0)
    else:
        print("RULE SMOKE FAIL ", failures)
        quit(1)
