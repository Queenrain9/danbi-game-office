extends Control

# Fidelity Blueprint 4d81434b… implementation for Pocket Canal Keeper.
# Static structure is kept in main.tscn; this script owns the deterministic
# segment simulation, state transitions, rules, gestures and feedback.

const STAGES := [
	{"name":"Mill Run", "boats":3, "par":9},
	{"name":"Market Bend", "boats":4, "par":12},
	{"name":"Tower Reach", "boats":6, "par":17},
]
const BOAT_TIMEOUT := 45.0
const MAX_STRIKES := 3
const GATE_STATES := ["CLOSED", "HALF", "OPEN"]
const COLORS := {
	"ink": Color("#17323a"), "water": Color("#55b9c5"),
	"paper": Color("#f4efd8"), "accent": Color("#e89b45"),
	"danger": Color("#d95f59"), "safe": Color("#5ca66f"),
}

var screen := "stage_select"
var board_state := "running"
var previous_board_state := "running"
var selected_stage := 0
var unlocked_stage := 0
var operations := 0
var strikes := 0
var elapsed := 0.0
var delivered := 0
var total_boats := 3
var gate_state := 0
var bridge_water_open := true
var lock_level := 0.0
var signal_go := false
var active_boat := 0
var boat_age := 0.0
var selected_boat := -1
var gesture_owner := ""
var gesture_start := Vector2.ZERO
var gesture_last := Vector2.ZERO
var gesture_snapshot := {}
var busy_time := 0.0
var warning_time := 0.0
var status_text := "Canal ready"

func _ready() -> void:
	if name != "AppRoot":
		return
	set_process(true)
	connect_optional("canal_board/pause", "pressed", Callable(self, "open_pause"))
	configure_copy()
	state_model()
	transition_to("stage_select")

func connect_optional(path: String, signal_name: String, callable: Callable) -> void:
	var node := get_node_or_null(path)
	if node and not node.is_connected(signal_name, callable):
		node.connect(signal_name, callable)

func configure_copy() -> void:
	var copy := {
		"stage_select/progress":"CANAL LICENSE · STAGE 1/3",
		"stage_brief/title":"MILL RUN",
		"stage_brief/objective":"Guide every boat through the protected canal.\nMatch gate, bridge and lock states before signaling GO.",
		"stage_brief/rules":"Safety: one boat per narrow segment\nFailure: 3 strikes or a 45s boat timeout\nScore: no strikes + operations under par",
		"stage_brief/back":"BACK", "stage_brief/start":"START SHIFT",
		"canal_board/ops_counter":"OPS 0", "canal_board/pause":"Ⅱ",
		"canal_board/device_status":"Canal ready",
		"canal_board/signal_buoy":"HOLD",
		"boat_inspect_popover/boat_name":"BOAT",
		"boat_inspect_popover/destination":"DESTINATION",
		"boat_inspect_popover/close":"CLOSE",
		"pause_overlay/resume":"RESUME", "pause_overlay/restart":"RESTART",
		"pause_overlay/exit":"EXIT STAGE",
		"stage_result/result_title":"Stage Complete",
		"stage_result/stars":"★★★", "stage_result/retry":"RETRY",
		"stage_result/next":"NEXT",
	}
	for path in copy:
		var node := get_node_or_null(path)
		if node is Label or node is Button:
			node.text = copy[path]
	var meter := get_node_or_null("canal_board/safety_meter")
	if meter:
		meter.max_value = MAX_STRIKES
		meter.value = MAX_STRIKES

func _process(delta: float) -> void:
	if name != "AppRoot" or screen != "canal_board" or board_state == "paused":
		return
	if warning_time > 0.0:
		warning_time = maxf(0.0, warning_time - delta)
	if busy_time > 0.0:
		busy_time = maxf(0.0, busy_time - delta)
		board_state = "device_busy"
		if busy_time == 0.0:
			board_state = "running"
			status_text = "Lock equalized · safe"
	else:
		elapsed += delta
		boat_age += delta
		if boat_age >= BOAT_TIMEOUT:
			add_strike("Boat timed out after 45 seconds")
			boat_age = 0.0
	update_hud()
	queue_redraw()

# Blueprint state/variant/transition bindings.
func state_model() -> Dictionary:
	return {"screen":screen,"board_state":board_state,"input_lock":screen in ["pause_overlay","stage_result"]}

func apply_variant(id: String, enabled: bool = true) -> void:
	if id == "warning_variant": warning_time = 1.2 if enabled else 0.0
	if id == "busy_variant" and enabled: board_state = "device_busy"
	queue_redraw()

func transition_to(target: String) -> void:
	screen = target
	for child in get_children():
		if child is Control:
			child.visible = child.name == target
	if target == "canal_board":
		board_state = "running"
	if target == "pause_overlay":
		board_state = "paused"
	update_hud()
	queue_redraw()

func integration_flow() -> Array[String]:
	return ["stage_select","stage_brief","canal_board","stage_result","stage_brief"]

func rule_model() -> Dictionary:
	return {
		"score":"success + no strikes + under par operations",
		"failure":"3 strikes or 45s boat timeout",
		"success":"all boats delivered",
		"occupancy":"one boat per narrow protected segment",
		"simulation":"deterministic segment graph",
		"boats_per_stage":"3-6",
		"gate_states":GATE_STATES,
		"lock_safety":"unequal-water door command rejected",
	}

func start_stage() -> void:
	operations = 0; strikes = 0; elapsed = 0.0; delivered = 0
	total_boats = int(STAGES[selected_stage].boats)
	gate_state = 0; bridge_water_open = true; lock_level = 0.0
	signal_go = false; active_boat = 0; boat_age = 0.0; selected_boat = -1
	busy_time = 0.0; warning_time = 0.0; status_text = "Boat 1 waiting · configure route"
	transition_to("canal_board")

func finish_stage(success: bool) -> void:
	board_state = "success_pending" if success else "failure_pending"
	transition_to("stage_result")
	var title := get_node_or_null("stage_result/result_title")
	var stars := get_node_or_null("stage_result/stars")
	var next := get_node_or_null("stage_result/next")
	if title: title.text = "Stage Complete" if success else "Stage Failed"
	var star_count := 0
	if success:
		star_count = 1 + int(strikes == 0) + int(operations <= int(STAGES[selected_stage].par))
		unlocked_stage = mini(STAGES.size()-1, maxi(unlocked_stage, selected_stage + 1))
	if stars: stars.text = "★".repeat(star_count) + "☆".repeat(3-star_count)
	if next: next.disabled = not success

func add_strike(reason: String) -> void:
	strikes += 1
	status_text = "STRIKE %d/%d · %s" % [strikes, MAX_STRIKES, reason]
	apply_variant("warning_variant")
	if strikes >= MAX_STRIKES:
		finish_stage(false)

func commit_operation(message: String) -> void:
	operations += 1
	status_text = message

func route_is_safe() -> bool:
	# Deterministic protected-segment interlock: open gate, water bridge,
	# and lock near the boat's alternating destination level.
	var required_level := 0.0 if active_boat % 2 == 0 else 1.0
	return gate_state == 2 and bridge_water_open and absf(lock_level-required_level) < 0.1

func advance_boat() -> void:
	if not route_is_safe():
		add_strike("Unsafe protected-segment entry rejected")
		signal_go = false
		return
	delivered += 1; active_boat += 1; boat_age = 0.0; signal_go = false
	status_text = "Boat delivered safely · %d/%d" % [delivered,total_boats]
	if delivered >= total_boats:
		finish_stage(true)

func update_hud() -> void:
	var ops := get_node_or_null("canal_board/ops_counter")
	if ops: ops.text = "OPS %d · BOATS %d/%d" % [operations, delivered, total_boats]
	var status := get_node_or_null("canal_board/device_status")
	if status: status.text = status_text
	var meter := get_node_or_null("canal_board/safety_meter")
	if meter: meter.value = MAX_STRIKES - strikes
	var buoy := get_node_or_null("canal_board/signal_buoy")
	if buoy: buoy.text = "GO" if signal_go else "HOLD"
	var progress := get_node_or_null("stage_select/progress")
	if progress: progress.text = "CANAL LICENSE · %d/3 STAGES" % [unlocked_stage+1]

func open_pause() -> void:
	if screen == "canal_board":
		previous_board_state = board_state
		transition_to("pause_overlay")

# Exact Blueprint action symbols.
func action_stage_select_0() -> void:
	selected_stage = mini(unlocked_stage, selected_stage)
	var title := get_node_or_null("stage_brief/title")
	if title: title.text = str(STAGES[selected_stage].name).to_upper()
	transition_to("stage_brief")

func action_stage_brief_0() -> void: start_stage()
func action_stage_brief_1() -> void: transition_to("stage_select")

func action_canal_board_0() -> void:
	if board_state not in ["running","device_busy"]: return
	gate_state = (gate_state + 1) % GATE_STATES.size()
	commit_operation("Gate snapped %s · water arrows updated" % GATE_STATES[gate_state])

func action_canal_board_1() -> void:
	if delivered < active_boat:
		add_strike("Crossing occupied · bridge rotation rejected")
		return
	bridge_water_open = not bridge_water_open
	busy_time = 0.35
	commit_operation("Bridge set %s" % ("WATER OPEN" if bridge_water_open else "ROAD OPEN"))

func action_canal_board_2(direction: float = 1.0) -> void:
	if gate_state != 0:
		add_strike("Close gate before equalizing lock")
		return
	lock_level = 1.0 if direction < 0.0 else 0.0
	busy_time = 0.7
	commit_operation("Lock equalizing to %s" % ("HIGH" if lock_level > 0.5 else "LOW"))

func action_canal_board_3() -> void:
	if board_state not in ["running","device_busy"]: return
	signal_go = not signal_go
	commit_operation("Signal GO" if signal_go else "Signal HOLD")
	if signal_go: advance_boat()

func action_canal_board_4() -> void:
	if screen != "canal_board": return
	selected_boat = active_boat
	var boat_name := get_node_or_null("boat_inspect_popover/boat_name")
	var destination := get_node_or_null("boat_inspect_popover/destination")
	if boat_name: boat_name.text = "BOAT %02d · %s" % [active_boat+1, "CARGO" if active_boat%2==0 else "FERRY"]
	if destination: destination.text = "DESTINATION · %s POOL" % ("LOW" if active_boat%2==0 else "HIGH")
	transition_to("boat_inspect_popover")

func action_boat_inspect_popover_0() -> void: selected_boat = -1; transition_to("canal_board")
func action_boat_inspect_popover_1() -> void: action_boat_inspect_popover_0()
func action_pause_overlay_0() -> void: transition_to("canal_board"); board_state = previous_board_state
func action_pause_overlay_1() -> void: start_stage()
func action_pause_overlay_2() -> void: transition_to("stage_select")
func action_stage_result_0() -> void: start_stage()
func action_stage_result_1() -> void:
	if board_state == "success_pending" or delivered >= total_boats:
		selected_stage = mini(unlocked_stage, selected_stage + 1)
		transition_to("stage_brief")

# Spatial handlers named by the Blueprint. They preserve active-pointer
# ownership and commit only on release; cancel restores the snapshot.
func input_stage_select_0(event: InputEvent) -> void:
	if is_release(event): action_stage_select_0()

func input_canal_board_0(event: InputEvent) -> void: handle_gesture("gate", event)
func input_canal_board_1(event: InputEvent) -> void: handle_gesture("bridge", event)
func input_canal_board_2(event: InputEvent) -> void: handle_gesture("lock", event)
func input_canal_board_4(event: InputEvent) -> void:
	if is_release(event): action_canal_board_4()

func handle_gesture(kind: String, event: InputEvent) -> void:
	var pos := event_position(event)
	if is_press(event):
		if gesture_owner != "": return
		gesture_owner = kind; gesture_start = pos; gesture_last = pos
		gesture_snapshot = {"gate":gate_state,"bridge":bridge_water_open,"lock":lock_level,"operations":operations}
	elif is_drag(event) and gesture_owner == kind:
		gesture_last = pos; queue_redraw()
	elif is_release(event) and gesture_owner == kind:
		var delta := pos - gesture_start
		gesture_owner = ""
		if kind == "gate" and delta.length() >= 18.0: action_canal_board_0()
		elif kind == "bridge" and delta.length() >= 18.0: action_canal_board_1()
		elif kind == "lock" and absf(delta.y) >= 18.0: action_canal_board_2(delta.y)
		else: restore_gesture("Gesture cancelled · no operation committed")

func restore_gesture(message: String) -> void:
	if gesture_snapshot.is_empty(): return
	gate_state = gesture_snapshot.gate
	bridge_water_open = gesture_snapshot.bridge
	lock_level = gesture_snapshot.lock
	operations = gesture_snapshot.operations
	status_text = message
	gesture_snapshot.clear()

func event_position(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch or event is InputEventScreenDrag: return event.position
	if event is InputEventMouseButton or event is InputEventMouseMotion: return event.position
	return Vector2.ZERO
func is_press(event: InputEvent) -> bool:
	return (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed)
func is_release(event: InputEvent) -> bool:
	return (event is InputEventScreenTouch and not event.pressed) or (event is InputEventMouseButton and not event.pressed)
func is_drag(event: InputEvent) -> bool:
	return event is InputEventScreenDrag or (event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))

func _gui_input(event: InputEvent) -> void:
	var app := get_tree().root.get_node_or_null("AppRoot")
	if app == null:
		return
	match name:
		"stage_cards": app.input_stage_select_0(event)
		"gate_lever": app.input_canal_board_0(event)
		"bridge_wheel": app.input_canal_board_1(event)
		"lock_control": app.input_canal_board_2(event)
		"boat_layer": app.input_canal_board_4(event)

func _draw() -> void:
	if name != "AppRoot":
		draw_component()
		return
	draw_rect(Rect2(Vector2.ZERO,size),COLORS.paper)
	if screen == "canal_board":
		draw_rect(Rect2(32,172,476,596),COLORS.water.lightened(0.55),true)
		draw_line(Vector2(270,180),Vector2(270,760),COLORS.ink,8)
		if warning_time > 0.0:
			draw_rect(Rect2(108,288,324,336),COLORS.danger, false, 6)

func draw_component() -> void:
	var r := Rect2(Vector2.ZERO,size)
	match name:
		"stage_cards":
			draw_rect(r,COLORS.water.lightened(0.65),true)
			for i in STAGES.size():
				var y := 28.0 + i*150.0
				draw_rect(Rect2(20,y,size.x-40,120),COLORS.safe if i<=unlocked_stage else Color("#a7aaa0"),true)
		"gate_lever":
			draw_circle(size/2.0,minf(size.x,size.y)*0.34,COLORS.accent)
		"bridge_wheel":
			draw_arc(size/2.0,minf(size.x,size.y)*0.35,0,TAU,24,COLORS.ink,8)
		"lock_control":
			draw_rect(Rect2(size.x*0.35,8,size.x*0.3,size.y-16),COLORS.water,true)
		"boat_layer":
			for i in total_boats-delivered:
				draw_circle(Vector2(80+i*55,100+(i%2)*65),18,COLORS.accent)
