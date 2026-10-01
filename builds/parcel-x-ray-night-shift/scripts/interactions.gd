extends Control

const DRAG_THRESHOLD := 12.0
var mode := ""
var drag_start := Vector2.ZERO
var box_origin := Vector2.ZERO
var last_scan_y := 0.0
var scan_direction := 0
var crossed_drag_threshold := false

func root_game():
	return get_parent()

func on_night_hub_01_load_first_parcel() -> void:
	if root_game().shift_available:
		root_game().start_shift()

func on_parcel_intake_01_enter_inspection() -> void:
	if root_game().case_loaded:
		root_game().enter_inspection()

func on_classification_result_01_advance() -> void:
	root_game().advance()

func on_shift_summary_01_return_hub() -> void:
	root_game().show_screen("night_hub")

func on_rule_manual_01_dismiss() -> void:
	root_game().resume_game()

func on_pause_01_resume_prior_state() -> void:
	root_game().resume_game()

func on_pause_02_abandon_shift() -> void:
	root_game().abandon()

func on_inspection_01_rotate_yaw_pitch(delta: Vector2 = Vector2.ZERO) -> void:
	root_game().set_box_pose(delta.x * 0.35, delta.y * 0.35)

func on_inspection_02_map_y_to_slice_depth(global_y: float = 0.0) -> void:
	var rail = root_game().get_node("Screens/inspection/scan_rail")
	var local_y: float = rail.to_local(Vector2(rail.global_position.x, global_y)).y
	var depth: float = clampf(local_y / maxf(1.0, rail.size.y) * 100.0, 0.0, 100.0)
	var direction := signi(int(global_y - last_scan_y))
	var reversed := scan_direction != 0 and direction != 0 and direction != scan_direction
	if direction != 0:
		scan_direction = direction
	last_scan_y = global_y
	root_game().record_scan(depth, reversed)

func on_inspection_03_toggle_evidence_pin(global_position: Vector2 = Vector2.ZERO) -> void:
	var parcel_view = root_game().get_node("Screens/inspection/xray_box/ParcelView")
	root_game().toggle_pin(parcel_view.to_local(global_position))

func on_inspection_04_classify_parcel(lane: String = "") -> void:
	if lane in ["PASS", "REPACK", "ISOLATE"]:
		root_game().classify(lane)

func apply_inp_classify(): return {"input":"drag-release","priority":1,"cancel":"spring to table","lock":"valid release through result"}
func apply_inp_pin(): return {"input":"tap visible internal shape","priority":3,"max":4,"invalid":"no-target pulse"}
func apply_inp_rotate(): return {"input":"one-finger drag","axes":["yaw","pitch"],"priority":2}
func apply_inp_scan(): return {"input":"vertical swipe","mapping":"0..100","hard_limit":null,"soft_target":4}

func _unhandled_input(event: InputEvent) -> void:
	var game = root_game()
	if event.is_action_pressed("ui_cancel"):
		if game.screen == "pause":
			game.resume_game()
		elif game.screen in ["inspection", "parcel_intake"]:
			game.pause_game()
		return
	if game.screen != "inspection" or game.input_lock:
		return
	var box = game.get_node("Screens/inspection/xray_box")
	var rail = game.get_node("Screens/inspection/scan_rail")
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var position: Vector2 = event.position
		if event.pressed:
			drag_start = position
			box_origin = box.position
			crossed_drag_threshold = false
			if rail.get_global_rect().has_point(position):
				mode = "scan"
				last_scan_y = position.y
				scan_direction = 0
			elif box.get_global_rect().grow(8.0).has_point(position):
				mode = "box"
			else:
				mode = ""
		else:
			if mode == "box":
				if not crossed_drag_threshold:
					on_inspection_03_toggle_evidence_pin(position)
				else:
					var accepted := false
					for lane_name in ["pass_lane", "repack_lane", "isolate_lane"]:
						var lane = game.get_node("Screens/inspection/" + lane_name)
						if lane.get_global_rect().has_point(box.get_global_rect().get_center()):
							on_inspection_04_classify_parcel(lane_name.trim_suffix("_lane").to_upper())
							accepted = true
							break
					if not accepted:
						game.cancel_classifying(box_origin)
				game.finish_rotation()
			elif mode == "scan":
				game.scanning = true
			mode = ""
	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		if mode == "":
			return
		var position: Vector2 = event.position
		var relative: Vector2 = event.relative
		if position.distance_to(drag_start) >= DRAG_THRESHOLD:
			crossed_drag_threshold = true
		if mode == "scan":
			on_inspection_02_map_y_to_slice_depth(position.y)
		elif mode == "box":
			if position.y >= 650.0:
				game.begin_classifying()
				box.position += relative
			elif not game.classifying:
				on_inspection_01_rotate_yaw_pitch(relative)
