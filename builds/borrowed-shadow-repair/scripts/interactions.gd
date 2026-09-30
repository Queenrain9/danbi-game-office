extends Control

var pressed := false
var hold_elapsed := 0.0
var last_angle := 0.0
var touches:Dictionary={}
var twist_start_angle:=0.0
var twist_piece_angle:=0.0

func root_game(): return get_node_or_null("/root/AppRoot")

func _ready() -> void:
    set_process(true)
    set_process_input(true)
    if name in ["symptom_targets", "piece_tray", "silhouette", "seam_canvas", "hold_test"]:
        mouse_filter = Control.MOUSE_FILTER_STOP
    queue_redraw()

func _process(delta: float) -> void:
    if name == "hold_test" and pressed:
        hold_elapsed += delta
        queue_redraw()
        if hold_elapsed >= 0.6:
            pressed = false
            var game = root_game()
            if game: game.complete_pose_test()

func _gui_input(event: InputEvent) -> void:
    var game = root_game()
    if not game or game.input_locked: return
    if event is InputEventScreenTouch:
        if event.pressed: touches[event.index]=event.position
        else: touches.erase(event.index)
        if name=="piece_tray" and event.pressed and touches.size()==1: game.begin_piece_drag(_piece_index_at(event.position))
        elif name=="piece_tray" and not event.pressed and touches.size()==0: game.end_piece_drag(event.position+global_position)
        if touches.size()==2:
            var pts=touches.values(); twist_start_angle=(pts[1]-pts[0]).angle(); twist_piece_angle=game.piece_angles[game.selected_piece] if game.selected_piece>=0 else 0.0
        accept_event(); return
    if event is InputEventScreenDrag:
        if touches.has(event.index): touches[event.index]=event.position
        if name=="piece_tray" and touches.size()==1: game.update_piece_drag(event.position+global_position)
        elif name=="piece_tray" and touches.size()==2 and game.selected_piece>=0:
            var pts=touches.values(); var delta=rad_to_deg((pts[1]-pts[0]).angle()-twist_start_angle); game.piece_angles[game.selected_piece]=twist_piece_angle+delta; game.piece_nodes[game.selected_piece].rotation_degrees=game.piece_angles[game.selected_piece]
        accept_event(); return
    if name == "symptom_targets" and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        game.diagnose_at(event.position); accept_event()
    elif name == "piece_tray":
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
            pressed = event.pressed
            if pressed: game.begin_piece_drag(_piece_index_at(event.position))
            else: game.end_piece_drag(event.global_position)
            accept_event()
        elif event is InputEventMouseMotion and pressed:
            game.update_piece_drag(event.global_position); accept_event()

    elif name == "silhouette" and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
        game.end_piece_drag(event.global_position); accept_event()
    elif name == "seam_canvas":
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
            pressed = event.pressed
            if pressed: game.begin_trace()
            else: game.end_trace()
            accept_event()
        elif event is InputEventMouseMotion and pressed:
            game.update_trace(event.position, size); queue_redraw(); accept_event()
    elif name == "hold_test" and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        pressed = event.pressed
        hold_elapsed = 0.0 if pressed else hold_elapsed
        if pressed: game.set_state("holding")
        elif hold_elapsed < 0.6: game.set_state("idle")
        queue_redraw(); accept_event()

func _piece_index_at(p:Vector2)->int:
    var game=root_game(); if not game:return -1
    var width=maxf(size.x/float(maxi(game.required_pieces,1)),1.0)
    return clampi(int(p.x/width),0,game.required_pieces-1)

func _draw() -> void:
    var game = root_game()
    if not game: return
    if name == "symptom_targets":
        draw_rect(Rect2(Vector2.ZERO, size), Color("#332b45"), true)
        for x in [0.22, 0.52, 0.78]:
            draw_circle(Vector2(size.x*x, size.y*0.5), 18.0, Color("#d36f7a") if not game.diagnosed else Color("#e7b55d"))
    elif name == "piece_tray":
        draw_rect(Rect2(Vector2.ZERO, size), Color("#201c30"), true)
        draw_string(ThemeDB.fallback_font, Vector2(12, 28), "조각 %d/%d · 드래그해 중앙 앵커에 놓기" % [game.snapped_pieces, game.required_pieces], HORIZONTAL_ALIGNMENT_LEFT, size.x-24, 17, Color("#efe7d0"))
    elif name == "silhouette":
        draw_rect(Rect2(Vector2.ZERO, size), Color("#1d1930"), true)
        var c := size * 0.5
        draw_circle(c, 110.0, Color(0.45,0.35,0.65,0.25))
        draw_arc(c, 110.0, 0, TAU, 48, Color("#8d78b8"), 4.0)
        draw_string(ThemeDB.fallback_font, Vector2(36, 42), "회전 오차 ≤12° · 위치 오차 ≤18px", HORIZONTAL_ALIGNMENT_CENTER, size.x-72, 18, Color("#efe7d0"))
        if game.current_state == "snap_candidate": draw_arc(c, 125.0, 0, TAU, 48, Color("#e7b55d"), 8.0)
    elif name == "seam_canvas":
        draw_rect(Rect2(Vector2.ZERO, size), Color("#211c31"), true)
        var a := Vector2(24, size.y*0.35)
        var b := Vector2(size.x-24, size.y*0.65)
        draw_line(a,b,Color(0.55,0.47,0.72,0.35),42.0)
        draw_dashed_line(a,b,Color("#efe7d0"),4.0,12.0)
        draw_string(ThemeDB.fallback_font, Vector2(20, 36), "밝은 선을 따라 드래그 · 허용 편차 20px", HORIZONTAL_ALIGNMENT_CENTER, size.x-40, 18, Color("#efe7d0"))
    elif name == "hold_test" and pressed:
        var ratio := clampf(hold_elapsed / 0.6, 0.0, 1.0)
        draw_arc(size*0.5, minf(size.x,size.y)*0.35, -PI/2, -PI/2+TAU*ratio, 40, Color("#e7b55d"), 8.0)

func on_night_workshop_01_item() -> void:
    var game=root_game()
    if game: game.transition_night_workshop_01()
func on_customer_intake_01_item() -> void:
    var game=root_game()
    if game: game.diagnose_at(Vector2.ZERO)
func on_shadow_workbench_01_item() -> void:
    var game=root_game()
    if game: game.begin_piece_drag(0)
func on_shadow_workbench_02_item() -> void:
    var game=root_game()
    if game: game.rotate_piece(15.0)
func on_shadow_workbench_03_n_15() -> void:
    var game=root_game()
    if game: game.rotate_piece(-15.0 if get_viewport().gui_get_focus_owner() and get_viewport().gui_get_focus_owner().name == "rotate_left" else 15.0)
func on_shadow_workbench_04_snap() -> void:
    var game=root_game()
    if game:
        var target = game.get_node("Screens/shadow_workbench/silhouette")
        game.end_piece_drag(target.get_global_rect().get_center())
func on_stitch_mode_01_n_20px_corridor() -> void:
    var game=root_game()
    if game: game.begin_trace()
func on_stitch_mode_02_seam() -> void:
    var game=root_game()
    if game: game.end_trace()
func on_pose_test_01_item() -> void:
    var game=root_game()
    if game: game.complete_pose_test()
func on_rework_overlay_01_anchor() -> void:
    var game=root_game()
    if game: game.transition_rework_overlay_01()
func on_result_01_item() -> void:
    var game=root_game()
    if game: game.transition_result_01()

func input_customer_intake_01(event: InputEvent) -> void: _gui_input(event)
func input_shadow_workbench_01(event: InputEvent) -> void: _gui_input(event)
func input_shadow_workbench_02(event: InputEvent) -> void: _gui_input(event)
func input_shadow_workbench_04(event: InputEvent) -> void: _gui_input(event)
func input_stitch_mode_01(event: InputEvent) -> void: _gui_input(event)
func input_stitch_mode_02(event: InputEvent) -> void: _gui_input(event)
func input_pose_test_01(event: InputEvent) -> void: _gui_input(event)

func apply_inp_01() -> void:
    pass

func apply_inp_02() -> void:
    pass

func apply_inp_03() -> void:
    pass

func apply_inp_04() -> void:
    pass

func apply_inp_05() -> void:
    pass
