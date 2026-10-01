extends Control

const Rules = preload("res://scripts/rules.gd")
var rules := Rules.new()

var screen := "night_hub"
var prior_screen := "inspection"
var case_loaded := false
var current_case: Dictionary = {}
var scans := 0
var scan_reversals := 0
var pins: Array[Vector2] = []
var false_pin_count := 0
var slice_depth := 0.0
var box_yaw := 0.0
var box_pitch := 0.0
var input_lock := false
var classifying := false
var rotating := false
var scanning := false
var shift_available := true

@onready var shift_controller: ParcelShiftController = $ShiftController
@onready var case_router: ParcelCaseRouter = $CaseRouter

func _ready() -> void:
	show_screen("night_hub")
	$Screens/inspection/manual_btn.pressed.connect(open_manual)

func show_screen(id: String) -> void:
	screen = id
	for node in $Screens.get_children():
		node.visible = node.name == id
	input_lock = id in ["classification_result", "rule_manual", "pause"]

func start_shift() -> void:
	shift_controller.reset_shift()
	load_case()

func load_case() -> void:
	shift_controller.begin_case()
	current_case = case_router.case_for_shift(shift_controller.case_index)
	case_loaded = true
	scans = 0
	scan_reversals = 0
	pins.clear()
	false_pin_count = 0
	slice_depth = 0.0
	box_yaw = 0.0
	box_pitch = 0.0
	classifying = false
	rotating = false
	scanning = false
	input_lock = false
	$Screens/parcel_intake/case_counter.text = "%d / 8" % (shift_controller.cases_done + 1)
	$Screens/parcel_intake/label_card.tooltip_text = "%s · %s" % [current_case.id, current_case.label]
	$Screens/parcel_intake/rule_chips.tooltip_text = "REPACK: dense metal unpadded within 10%% wall\nISOLATE: two dense cable-linked objects touch power cell\nPASS: otherwise"
	show_screen("parcel_intake")

func enter_inspection() -> void:
	if not case_loaded:
		return
	input_lock = false
	show_screen("inspection")
	refresh_hud()

func refresh_hud() -> void:
	$Screens/inspection/scan_count.text = "Scans %d/4%s" % [scans, " · efficiency -" + str((scans - 4) * 5) if scans > 4 else ""]
	$Screens/inspection/pin_tray.text = "Evidence Pins %d/4" % pins.size()
	$Screens/inspection/case_rule.tooltip_text = "Current rule set · slice %d%%" % int(slice_depth)
	$Screens/inspection/scan_plane.position.y = lerpf(144.0, 585.0, slice_depth / 100.0)

func record_scan(depth: float, reversed_direction: bool) -> void:
	if input_lock or classifying:
		return
	slice_depth = clampf(depth, 0.0, 100.0)
	scans += 1
	if reversed_direction:
		scan_reversals += 1
	scanning = true
	refresh_hud()

func set_box_pose(yaw_delta: float, pitch_delta: float) -> void:
	if input_lock or classifying:
		return
	rotating = true
	box_yaw = wrapf(box_yaw + yaw_delta, -180.0, 180.0)
	box_pitch = clampf(box_pitch + pitch_delta, -75.0, 75.0)
	var parcel_view = $Screens/inspection/xray_box/ParcelView
	parcel_view.set_pose(Vector2(box_yaw, box_pitch))

func finish_rotation() -> void:
	rotating = false

func toggle_pin(local_position: Vector2) -> bool:
	if input_lock or classifying or not scanning:
		return false
	var parcel_view = $Screens/inspection/xray_box/ParcelView
	if not parcel_view.has_visible_shape_at(local_position, slice_depth):
		parcel_view.show_no_target_pulse()
		return false
	for i in range(pins.size()):
		if pins[i].distance_to(local_position) <= 18.0:
			pins.remove_at(i)
			refresh_hud()
			return true
	if pins.size() >= 4:
		return false
	pins.append(local_position)
	parcel_view.show_pin_feedback(local_position)
	refresh_hud()
	return true

func begin_classifying() -> void:
	if input_lock:
		return
	classifying = true
	$Screens/inspection/pass_lane.modulate = Color(0.8, 0.95, 1.0)
	$Screens/inspection/repack_lane.modulate = Color(1.0, 0.9, 0.65)
	$Screens/inspection/isolate_lane.modulate = Color(1.0, 0.75, 0.75)

func cancel_classifying(origin: Vector2) -> void:
	classifying = false
	$Screens/inspection/xray_box.position = origin
	for lane in [$Screens/inspection/pass_lane, $Screens/inspection/repack_lane, $Screens/inspection/isolate_lane]:
		lane.modulate = Color.WHITE

func classify(lane: String) -> void:
	if input_lock:
		return
	input_lock = true
	classifying = false
	var result := rules.score_classification(current_case, lane, false_pin_count, scans, scan_reversals, shift_controller.correct_streak)
	shift_controller.commit_result(result, scans, scan_reversals)
	$Screens/classification_result/stamp.text = lane if result.correct else "CHECK · " + str(result.correct_lane)
	$Screens/classification_result/score_delta.text = "%+d" % int(result.delta)
	$Screens/classification_result/reason.tooltip_text = str(result.reason)
	$Screens/classification_result/reason.set_meta("explanation", result.reason)
	$Screens/classification_result/evidence_replay.tooltip_text = "Slice %d%% · %d pins · expected %s" % [int(slice_depth), pins.size(), result.correct_lane]
	show_screen("classification_result")

func advance() -> void:
	if shift_controller.cases_done >= 8:
		show_summary()
	else:
		load_case()

func show_summary() -> void:
	var summary := shift_controller.summary()
	$Screens/shift_summary/grade.text = str(summary.grade)
	$Screens/shift_summary/accuracy.text = "Accuracy\n%d / 8" % shift_controller.correct_count
	$Screens/shift_summary/critical.text = "Critical\n%d" % int(summary.critical_misses)
	$Screens/shift_summary/efficiency.text = "Efficiency\n%d%%" % int(summary.efficiency)
	$Screens/shift_summary.set_meta("score", summary.score)
	show_screen("shift_summary")

func open_manual() -> void:
	if screen != "inspection" or input_lock:
		return
	prior_screen = screen
	show_screen("rule_manual")

func pause_game() -> void:
	if screen in ["inspection", "parcel_intake"]:
		prior_screen = screen
		show_screen("pause")

func resume_game() -> void:
	show_screen(prior_screen)
	input_lock = false

func abandon() -> void:
	shift_controller.reset_shift()
	case_loaded = false
	show_screen("night_hub")

func apply_acc_01(): return ["night_hub","parcel_intake","inspection","classification_result","shift_summary","rule_manual","pause"]
func apply_acc_02(): return {"rotate":true,"scan":true,"pin":true,"classify":true,"priority":["lane drag","box rotate","hotspot tap"]}
func apply_acc_03(): return "release outside lane springs to table"
func apply_acc_04(): return {"rule_manual_blocks_background":true}
func apply_acc_05(): return input_lock
func apply_acc_06(): return shift_controller.cases_done >= 8
func apply_arc_required_data(): return {"ParcelCase":case_router.CASES,"HazardRules":rules,"ShiftProgress":shift_controller}
func apply_arc_reusable_components(): return ["ParcelView","ScanRail","EvidencePin","DropLane","RuleChip","ResultStamp"]
func apply_arc_scene_hierarchy(): return {"AppRoot":self,"ShiftController":shift_controller,"CaseRouter":case_router,"HUDLayer":$HUDLayer,"OverlayLayer":$OverlayLayer}
func apply_arc_state_ownership(): return {"shift":"ShiftController","case_data":"CaseRouter","gesture":"InteractionController"}
func apply_cnt_mvp_scope(): return {"fixed_cases":10,"played_cases":8,"primitive_types":6,"hazard_rules":3}
func apply_gst_input_lock(): return input_lock
func apply_gst_paused(): return screen == "pause"
func apply_sta_classification_result_result(): return screen == "classification_result"
func apply_sta_inspection_classifying(): return screen == "inspection" and classifying
func apply_sta_inspection_inspect(): return screen == "inspection" and not classifying
func apply_sta_night_hub_hub(): return screen == "night_hub"
func apply_sta_parcel_intake_intake(): return screen == "parcel_intake"
func apply_sta_pause_paused(): return screen == "pause"
func apply_sta_rule_manual_rule_overlay(): return screen == "rule_manual"
func apply_sta_shift_summary_summary(): return screen == "shift_summary"
func apply_trn_classification_result_01(): if shift_controller.cases_done < 8: load_case()
func apply_trn_classification_result_02(): if shift_controller.cases_done >= 8: show_summary()
func apply_trn_inspection_01(): return input_lock and screen == "classification_result"
func apply_trn_inspection_02(): open_manual()
func apply_trn_night_hub_01(): start_shift()
func apply_trn_parcel_intake_01(): enter_inspection()
func apply_trn_pause_01(): resume_game()
func apply_trn_pause_02(): abandon()
func apply_trn_rule_manual_01(): resume_game()
func apply_trn_shift_summary_01(): show_screen("night_hub")
func apply_var_inspection_classifying(): return classifying
func apply_var_inspection_input_locked(): return input_lock
func apply_var_inspection_rotating(): return rotating
func apply_var_inspection_scanning(): return scanning
func transition_night_hub_01(): start_shift()
func transition_parcel_intake_01(): enter_inspection()
func transition_inspection_01(): return screen == "classification_result"
func transition_inspection_02(): open_manual()
func transition_classification_result_01(): apply_trn_classification_result_01()
func transition_classification_result_02(): apply_trn_classification_result_02()
func transition_shift_summary_01(): show_screen("night_hub")
func transition_rule_manual_01(): resume_game()
func transition_pause_01(): resume_game()
func transition_pause_02(): abandon()
func is_night_hub_hub_active(): return screen == "night_hub"
func is_parcel_intake_intake_active(): return screen == "parcel_intake"
func is_inspection_inspect_active(): return screen == "inspection" and not classifying
func is_classification_result_result_active(): return screen == "classification_result"
func is_shift_summary_summary_active(): return screen == "shift_summary"
func is_rule_manual_rule_overlay_active(): return screen == "rule_manual"
func is_pause_paused_active(): return screen == "pause"
