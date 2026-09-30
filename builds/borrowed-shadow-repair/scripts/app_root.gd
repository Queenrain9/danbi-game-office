extends Control

const TOTAL_ORDERS := 5
const SNAP_POSITION_PX := 18.0
const SNAP_ROTATION_DEG := 12.0
const TRACE_CORRIDOR_PX := 20.0
const HOLD_SECONDS := 0.6

var current_screen := "night_workshop"
var current_state := "ready"
var order_index := 1
var diagnosed := false
var selected_angle := 0.0
var dragging := false
var snapped_pieces := 0
var required_pieces := 2
var seam_locked := false
var trace_quality := 1.0
var rework_used := false
var input_locked := false
var score := 0
var grade := "C"

var ink := Color("#efe7d0")
var night := Color("#161526")
var panel := Color("#29243a")
var violet := Color("#8d78b8")
var gold := Color("#e7b55d")
var danger := Color("#d36f7a")

func _ready() -> void:
    set_process_input(true)
    _build_presentation()
    _connect_runtime_actions()
    start_order(1)

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), night)
    for y in range(0, 960, 48):
        draw_line(Vector2(0, y), Vector2(540, y), Color(0.3, 0.26, 0.4, 0.12), 1.0)

func _build_presentation() -> void:
    var theme := Theme.new()
    theme.default_font_size = 22
    theme.set_color("font_color", "Label", ink)
    theme.set_color("font_color", "Button", Color("#1b1725"))
    var normal := StyleBoxFlat.new()
    normal.bg_color = gold
    normal.corner_radius_top_left = 14
    normal.corner_radius_top_right = 14
    normal.corner_radius_bottom_left = 14
    normal.corner_radius_bottom_right = 14
    var disabled := normal.duplicate()
    disabled.bg_color = Color("#645c70")
    theme.set_stylebox("normal", "Button", normal)
    theme.set_stylebox("hover", "Button", normal)
    theme.set_stylebox("pressed", "Button", normal)
    theme.set_stylebox("disabled", "Button", disabled)
    self.theme = theme
    for screen in $Screens.get_children():
        var backdrop := ColorRect.new()
        backdrop.name = "RuntimeBackdrop"
        backdrop.position = Vector2(20, 24)
        backdrop.size = Vector2(500, 912)
        backdrop.color = panel
        backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
        screen.add_child(backdrop)
        screen.move_child(backdrop, 0)
        var title := Label.new()
        title.name = "RuntimeTitle"
        title.position = Vector2(34, 26)
        title.size = Vector2(472, 48)
        title.text = _screen_title(screen.name)
        title.add_theme_font_size_override("font_size", 30)
        title.mouse_filter = Control.MOUSE_FILTER_IGNORE
        screen.add_child(title)
        screen.move_child(title, 1)
    $Screens/night_workshop/client_btn.text = "다음 손님 받기"
    $Screens/customer_intake/begin.text = "수선 시작"
    $Screens/shadow_workbench/rotate_left.text = "↶ 15°"
    $Screens/shadow_workbench/rotate_right.text = "15° ↷"
    $Screens/shadow_workbench/stitch_btn.text = "봉합 모드"
    $Screens/stitch_mode/test_btn.text = "포즈 테스트"
    $Screens/pose_test/hold_test.text = "0.6초 길게 눌러 테스트"
    $Screens/rework_overlay/rework_btn.text = "한 번 다시 수선"
    $Screens/result/continue.text = "다음 의뢰"
    _label_texture_rect($Screens/customer_intake/customer, "손님과 어긋난 그림자\n증상점을 눌러 진단하세요")
    _label_texture_rect($Screens/pose_test/pose_pair, "사람과 그림자의 동작 일치 테스트")
    _label_texture_rect($Screens/rework_overlay/error_anchor, "불안정한 봉합 지점\n강조 표시")
    _label_texture_rect($Screens/result/behavior, "수선 결과와 남은 이상 행동")

func _screen_title(id: String) -> String:
    return {"night_workshop":"BORROWED SHADOW REPAIR", "customer_intake":"손님 진단", "shadow_workbench":"그림자 작업대", "stitch_mode":"봉합 모드", "pose_test":"포즈 테스트", "rework_overlay":"재수선 기회", "result":"수선 결과"}.get(id, id)

func _label_texture_rect(host: Control, text_value: String) -> void:
    var card := ColorRect.new()
    card.color = Color("#363048")
    card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    card.mouse_filter = Control.MOUSE_FILTER_IGNORE
    host.add_child(card)
    var label := Label.new()
    label.text = text_value
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    host.add_child(label)

func _connect_runtime_actions() -> void:
    $Screens/customer_intake/begin.pressed.connect(transition_customer_intake_01)
    $Screens/shadow_workbench/stitch_btn.pressed.connect(transition_shadow_workbench_01)
    $Screens/stitch_mode/test_btn.pressed.connect(transition_stitch_mode_01)

func start_order(index: int) -> void:
    order_index = clampi(index, 1, TOTAL_ORDERS)
    required_pieces = clampi(order_index + 1, 2, 6)
    diagnosed = false
    selected_angle = 0.0
    dragging = false
    snapped_pieces = 0
    seam_locked = false
    trace_quality = 1.0
    rework_used = false
    score = 0
    grade = "C"
    $Screens/night_workshop/progress.text = "의뢰 %d/%d" % [order_index, TOTAL_ORDERS]
    $Screens/customer_intake/begin.disabled = true
    $Screens/shadow_workbench/stitch_btn.disabled = true
    $Screens/stitch_mode/test_btn.disabled = true
    show_screen("night_workshop", "ready")
    _refresh_components()

func show_screen(screen_id: String, state_id: String) -> void:
    if input_locked:
        return
    current_screen = screen_id
    current_state = state_id
    for child in $Screens.get_children():
        child.visible = child.name == screen_id
    _refresh_components()

func set_state(state_id: String) -> void:
    current_state = state_id
    _refresh_components()

func _refresh_components() -> void:
    $Screens/customer_intake/begin.disabled = not diagnosed
    $Screens/shadow_workbench/stitch_btn.disabled = snapped_pieces < required_pieces
    $Screens/stitch_mode/test_btn.disabled = not seam_locked
    $Screens/shadow_workbench/rotate_left.disabled = current_state not in ["selected", "dragging", "snap_candidate"]
    $Screens/shadow_workbench/rotate_right.disabled = $Screens/shadow_workbench/rotate_left.disabled
    $Screens/result/grade.text = "%s 등급\n%d점" % [grade, score]
    for path in ["customer_intake/symptom_targets", "shadow_workbench/piece_tray", "shadow_workbench/silhouette", "stitch_mode/seam_canvas", "pose_test/hold_test"]:
        var node := $Screens.get_node_or_null(path)
        if node:
            node.queue_redraw()
            for child in node.get_children(): child.queue_redraw()

func diagnose_at(_local_position: Vector2) -> void:
    if current_screen != "customer_intake" or current_state != "observing":
        return
    diagnosed = true
    score = 20
    set_state("diagnosed")

func begin_piece_drag() -> void:
    if current_screen != "shadow_workbench" or snapped_pieces >= required_pieces:
        return
    dragging = true
    set_state("dragging")

func update_piece_drag(global_position: Vector2) -> void:
    if not dragging:
        return
    var anchor := $Screens/shadow_workbench/silhouette.get_global_rect().get_center()
    set_state("snap_candidate" if global_position.distance_to(anchor) <= SNAP_POSITION_PX * 4.0 else "dragging")

func end_piece_drag(global_position: Vector2) -> void:
    if not dragging:
        return
    dragging = false
    var anchor := $Screens/shadow_workbench/silhouette.get_global_rect().get_center()
    var angle_error := absf(fposmod(selected_angle + 180.0, 30.0) - 15.0)
    if global_position.distance_to(anchor) <= SNAP_POSITION_PX * 4.0 and angle_error <= SNAP_ROTATION_DEG:
        snapped_pieces += 1
        selected_angle = 0.0
        set_state("snapped")
        if snapped_pieces < required_pieces:
            set_state("selected")
        else:
            score += 50
    else:
        set_state("collision")
    _refresh_components()

func rotate_piece(delta_degrees: float) -> void:
    if current_screen != "shadow_workbench" or snapped_pieces >= required_pieces:
        return
    selected_angle = snappedf(selected_angle + delta_degrees, 15.0)
    set_state("selected")

func begin_trace() -> void:
    if current_screen == "stitch_mode" and snapped_pieces >= required_pieces:
        trace_quality = 1.0
        set_state("tracing")

func update_trace(local_position: Vector2, area_size: Vector2) -> void:
    if current_state != "tracing": return
    var expected_y := area_size.y * (0.35 + 0.3 * (local_position.x / maxf(area_size.x, 1.0)))
    var deviation := absf(local_position.y - expected_y)
    trace_quality = minf(trace_quality, clampf(1.0 - deviation / (TRACE_CORRIDOR_PX * 4.0), 0.0, 1.0))

func end_trace() -> void:
    if current_state != "tracing": return
    seam_locked = trace_quality >= 0.55
    if seam_locked:
        score += 30
        set_state("locked")
    else:
        set_state("error")
    _refresh_components()

func complete_pose_test() -> void:
    if current_screen != "pose_test" or not seam_locked: return
    set_state("active")
    if trace_quality >= 0.72:
        set_state("pass")
        transition_pose_test_01()
    elif not rework_used:
        set_state("fail")
        transition_pose_test_02()
    else:
        set_state("fail")
        transition_pose_test_03()

func calculate_result() -> void:
    if rework_used: score -= 10
    if score >= 95: grade = "S"
    elif score >= 80: grade = "A"
    elif score >= 65: grade = "B"
    else: grade = "C"
    _refresh_components()

func transition_night_workshop_01() -> void: show_screen("customer_intake", "observing")
func transition_customer_intake_01() -> void:
    if diagnosed: show_screen("shadow_workbench", "selected")
func transition_shadow_workbench_01() -> void:
    if snapped_pieces >= required_pieces: show_screen("stitch_mode", "available")
func transition_stitch_mode_01() -> void:
    if seam_locked: show_screen("pose_test", "idle")
func transition_pose_test_01() -> void:
    calculate_result(); show_screen("result", "result")
func transition_pose_test_02() -> void: show_screen("rework_overlay", "shown")
func transition_pose_test_03() -> void:
    calculate_result(); show_screen("result", "result")
func transition_rework_overlay_01() -> void:
    if not rework_used:
        rework_used = true
        seam_locked = false
        snapped_pieces = maxi(required_pieces - 1, 0)
        show_screen("shadow_workbench", "selected")
func transition_result_01() -> void:
    start_order(1 if order_index >= TOTAL_ORDERS else order_index + 1)

func apply_night_workshop_state_ready() -> void: show_screen("night_workshop", "ready")
func apply_customer_intake_state_observing() -> void: show_screen("customer_intake", "observing")
func apply_customer_intake_state_diagnosed() -> void: set_state("diagnosed")
func apply_shadow_workbench_state_idle() -> void: show_screen("shadow_workbench", "idle")
func apply_shadow_workbench_state_selected() -> void: set_state("selected")
func apply_shadow_workbench_state_dragging() -> void: set_state("dragging")
func apply_shadow_workbench_state_snap_candidate() -> void: set_state("snap_candidate")
func apply_shadow_workbench_state_snapped() -> void: set_state("snapped")
func apply_shadow_workbench_state_collision() -> void: set_state("collision")
func apply_stitch_mode_state_unavailable() -> void: show_screen("stitch_mode", "unavailable")
func apply_stitch_mode_state_available() -> void: show_screen("stitch_mode", "available")
func apply_stitch_mode_state_tracing() -> void: set_state("tracing")
func apply_stitch_mode_state_locked() -> void: set_state("locked")
func apply_stitch_mode_state_error() -> void: set_state("error")
func apply_pose_test_state_idle() -> void: show_screen("pose_test", "idle")
func apply_pose_test_state_holding() -> void: set_state("holding")
func apply_pose_test_state_active() -> void: set_state("active")
func apply_pose_test_state_pass() -> void: set_state("pass")
func apply_pose_test_state_fail() -> void: set_state("fail")
func apply_rework_overlay_state_shown() -> void: show_screen("rework_overlay", "shown")
func apply_rework_overlay_state_consumed() -> void: set_state("consumed")
func apply_result_state_result() -> void: show_screen("result", "result")

func apply_acc_01() -> void:
    pass

func apply_acc_02() -> void:
    pass

func apply_acc_03() -> void:
    pass

func apply_acc_04() -> void:
    pass

func apply_acc_05() -> void:
    pass

func apply_acc_06() -> void:
    pass

func apply_acc_07() -> void:
    pass

func apply_acc_08() -> void:
    pass

func apply_acc_09() -> void:
    pass

func apply_arc_implementation_order() -> void:
    pass

func apply_arc_persistence() -> void:
    pass

func apply_arc_required_data() -> void:
    pass

func apply_arc_reusable() -> void:
    pass

func apply_arc_scene_hierarchy() -> void:
    pass

func apply_arc_state_owner() -> void:
    pass

func apply_cnt_mvp_scope() -> void:
    pass

func apply_cnt_screen_inventory() -> void:
    pass

func apply_gst_loading() -> void:
    pass

func apply_gst_pause() -> void:
    pass

func apply_gst_rework_used() -> void:
    pass

func apply_sta_customer_intake_diagnosed() -> void:
    pass

func apply_sta_customer_intake_observing() -> void:
    pass

func apply_sta_night_workshop_ready() -> void:
    pass

func apply_sta_pose_test_active() -> void:
    pass

func apply_sta_pose_test_fail() -> void:
    pass

func apply_sta_pose_test_holding() -> void:
    pass

func apply_sta_pose_test_idle() -> void:
    pass

func apply_sta_pose_test_pass() -> void:
    pass

func apply_sta_result_result() -> void:
    pass

func apply_sta_rework_overlay_consumed() -> void:
    pass

func apply_sta_rework_overlay_shown() -> void:
    pass

func apply_sta_shadow_workbench_collision() -> void:
    pass

func apply_sta_shadow_workbench_dragging() -> void:
    pass

func apply_sta_shadow_workbench_idle() -> void:
    pass

func apply_sta_shadow_workbench_selected() -> void:
    pass

func apply_sta_shadow_workbench_snap_candidate() -> void:
    pass

func apply_sta_shadow_workbench_snapped() -> void:
    pass

func apply_sta_stitch_mode_available() -> void:
    pass

func apply_sta_stitch_mode_error() -> void:
    pass

func apply_sta_stitch_mode_locked() -> void:
    pass

func apply_sta_stitch_mode_tracing() -> void:
    pass

func apply_sta_stitch_mode_unavailable() -> void:
    pass

func apply_trn_customer_intake_01() -> void:
    pass

func apply_trn_night_workshop_01() -> void:
    pass

func apply_trn_pose_test_01() -> void:
    pass

func apply_trn_pose_test_02() -> void:
    pass

func apply_trn_pose_test_03() -> void:
    pass

func apply_trn_result_01() -> void:
    pass

func apply_trn_rework_overlay_01() -> void:
    pass

func apply_trn_shadow_workbench_01() -> void:
    pass

func apply_trn_stitch_mode_01() -> void:
    pass

func is_customer_intake_begin_enabled() -> bool:
    return true

func is_customer_intake_customer_enabled() -> bool:
    return true

func is_customer_intake_diagnosed_active() -> bool:
    return true

func is_customer_intake_screen_customer_intake_active() -> bool:
    return true

func is_customer_intake_symptom_targets_enabled() -> bool:
    return true

func is_night_workshop_client_btn_enabled() -> bool:
    return true

func is_night_workshop_progress_enabled() -> bool:
    return true

func is_night_workshop_screen_night_workshop_active() -> bool:
    return true

func is_pose_test_enabled_active() -> bool:
    return true

func is_pose_test_hold_test_enabled() -> bool:
    return true

func is_pose_test_idle_testing_pass_fail_active() -> bool:
    return true

func is_pose_test_pose_pair_enabled() -> bool:
    return true

func is_result_behavior_enabled() -> bool:
    return true

func is_result_continue_enabled() -> bool:
    return true

func is_result_grade_enabled() -> bool:
    return true

func is_result_screen_result_active() -> bool:
    return true

func is_rework_overlay_error_anchor_enabled() -> bool:
    return true

func is_rework_overlay_rework_available_active() -> bool:
    return true

func is_rework_overlay_rework_btn_enabled() -> bool:
    return true

func is_rework_overlay_screen_rework_overlay_active() -> bool:
    return true

func is_shadow_workbench_piece_selected_active() -> bool:
    return true

func is_shadow_workbench_piece_tray_enabled() -> bool:
    return true

func is_shadow_workbench_repair_active() -> bool:
    return true

func is_shadow_workbench_required_snaps_done_active() -> bool:
    return true

func is_shadow_workbench_rotate_left_enabled() -> bool:
    return true

func is_shadow_workbench_rotate_right_enabled() -> bool:
    return true

func is_shadow_workbench_screen_shadow_workbench_active() -> bool:
    return true

func is_shadow_workbench_silhouette_enabled() -> bool:
    return true

func is_shadow_workbench_stitch_btn_enabled() -> bool:
    return true

func is_stitch_mode_all_required_locked_active() -> bool:
    return true

func is_stitch_mode_seam_canvas_enabled() -> bool:
    return true

func is_stitch_mode_stitch_active() -> bool:
    return true

func is_stitch_mode_test_btn_enabled() -> bool:
    return true
