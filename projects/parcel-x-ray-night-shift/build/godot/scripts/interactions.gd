extends Control
var dragging=false; var drag_start=Vector2.ZERO; var box_start=Vector2.ZERO; var mode=""
func root_game(): return get_parent()
func on_night_hub_01_load_first_parcel(): root_game().start_shift()
func on_parcel_intake_01_enter_inspection(): root_game().enter_inspection()
func on_classification_result_01_advance(): root_game().advance()
func on_shift_summary_01_return_hub(): root_game().show_screen("night_hub")
func on_rule_manual_01_dismiss(): root_game().show_screen(root_game().prior_screen)
func on_pause_01_resume_prior_state(): root_game().resume_game()
func on_pause_02_abandon_shift(): root_game().abandon()
func on_inspection_01_rotate_yaw_pitch(delta=Vector2.ZERO): var p=root_game().get_node("Screens/inspection/xray_box/ParcelView"); p.rotation+=delta.x*0.002
func on_inspection_02_map_y_to_slice_depth(y=0.0): var g=root_game(); if g.scans<4: g.scans+=1; g.get_node("Screens/inspection/scan_plane").position.y=clamp(y,144.0,585.0); g.refresh_hud()
func on_inspection_03_toggle_evidence_pin(pos=Vector2.ZERO): var g=root_game(); if g.scans==0:return; if g.pins.size()<4:g.pins.append(pos); g.refresh_hud()
func on_inspection_04_classify_parcel(lane=""): root_game().classify(lane)
func apply_inp_classify(): return "drag-release lanes"
func apply_inp_pin(): return "tap scanned shape"
func apply_inp_rotate(): return "one-finger drag"
func apply_inp_scan(): return "vertical swipe rail"
func _unhandled_input(e):
 var g=root_game(); if g.screen!="inspection" or g.input_lock:return
 var box=g.get_node("Screens/inspection/xray_box").get_global_rect(); var rail=g.get_node("Screens/inspection/scan_rail").get_global_rect()
 if e is InputEventScreenTouch:
  if e.pressed:
   drag_start=e.position; box_start=g.get_node("Screens/inspection/xray_box").position; dragging=box.has_point(e.position); mode="scan" if rail.has_point(e.position) else "box" if dragging else ""
  else:
   if mode=="box":
    var moved=e.position.distance_to(drag_start)
    if moved<12: on_inspection_03_toggle_evidence_pin(e.position)
    else:
     for lane in ["pass_lane","repack_lane","isolate_lane"]:
      if g.get_node("Screens/inspection/"+lane).get_global_rect().has_point(e.position): on_inspection_04_classify_parcel(lane.trim_suffix("_lane").to_upper()); return
     g.get_node("Screens/inspection/xray_box").position=box_start
   mode=""; dragging=false
 if e is InputEventScreenDrag:
  if mode=="scan": on_inspection_02_map_y_to_slice_depth(e.position.y)
  elif mode=="box":
   if e.position.y<650: on_inspection_01_rotate_yaw_pitch(e.relative)
   else: g.get_node("Screens/inspection/xray_box").position+=e.relative
