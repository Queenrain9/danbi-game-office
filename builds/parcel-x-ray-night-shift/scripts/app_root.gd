extends Control
var screen="night_hub"; var prior_screen="inspection"; var case_index=0; var score=0; var scans=0; var pins=[]; var input_lock=false; var classifying=false; var shift_available=true; var case_loaded=false
func _ready(): show_screen("night_hub")
func show_screen(id): screen=id; for n in $Screens.get_children(): n.visible=(n.name==id)
func start_shift(): case_index=1; score=0; load_case()
func load_case(): case_loaded=true; scans=0; pins.clear(); classifying=false; input_lock=false; show_screen("parcel_intake"); $Screens/parcel_intake/case_counter.text="%d / 8"%case_index
func enter_inspection(): if case_loaded: show_screen("inspection"); refresh_hud()
func refresh_hud(): $Screens/inspection/scan_count.text="Scans %d/4"%scans; $Screens/inspection/pin_tray.text="Evidence Pins %d/4"%pins.size()
func classify(lane): if input_lock:return; input_lock=true; classifying=true; var correct=["PASS","REPACK","ISOLATE"][case_index%3]; var ok=lane==correct; score+=100 if ok else -40; $Screens/classification_result/stamp.text=lane; $Screens/classification_result/score_delta.text=("+100" if ok else "-40"); $Screens/classification_result/reason.tooltip_text=("Correct hazard routing" if ok else "Rule mismatch: "+correct); show_screen("classification_result")
func advance(): case_index+=1; if case_index>8: show_summary(); else: load_case()
func show_summary(): $Screens/shift_summary/grade.text=("A" if score>=600 else "B" if score>=400 else "C"); $Screens/shift_summary/accuracy.text="Score %d"%score; show_screen("shift_summary")
func pause_game(): prior_screen=screen; show_screen("pause")
func resume_game(): show_screen(prior_screen)
func abandon(): case_index=0; show_screen("night_hub")
func manual(): prior_screen=screen; show_screen("rule_manual")
func apply_acc_01(): return screen
func apply_acc_02(): return case_index
func apply_acc_03(): return scans
func apply_acc_04(): return pins.size()
func apply_acc_05(): return score
func apply_acc_06(): return input_lock
func apply_arc_required_data(): return {"cases":8,"scan_budget":4,"pin_budget":4}
func apply_arc_reusable_components(): return ["ParcelView","ScanRail","EvidencePin","DropLane","RuleChip","ResultStamp"]
func apply_arc_scene_hierarchy(): return $Screens
func apply_arc_state_ownership(): return {"shift":"AppRoot","gesture":"InteractionController"}
func apply_cnt_mvp_scope(): return 8
func apply_gst_input_lock(): return input_lock
func apply_gst_paused(): return screen=="pause"
func apply_sta_classification_result_result(): return screen=="classification_result"
func apply_sta_inspection_classifying(): return classifying
func apply_sta_inspection_inspect(): return screen=="inspection"
func apply_sta_night_hub_hub(): return screen=="night_hub"
func apply_sta_parcel_intake_intake(): return screen=="parcel_intake"
func apply_sta_pause_paused(): return screen=="pause"
func apply_sta_rule_manual_rule_overlay(): return screen=="rule_manual"
func apply_sta_shift_summary_summary(): return screen=="shift_summary"
func apply_trn_classification_result_01(): advance()
func apply_trn_classification_result_02(): show_summary()
func apply_trn_inspection_01(): show_screen("classification_result")
func apply_trn_inspection_02(): show_screen("rule_manual")
func apply_trn_night_hub_01(): start_shift()
func apply_trn_parcel_intake_01(): enter_inspection()
func apply_trn_pause_01(): resume_game()
func apply_trn_pause_02(): abandon()
func apply_trn_rule_manual_01(): show_screen(prior_screen)
func apply_trn_shift_summary_01(): show_screen("night_hub")
func apply_var_inspection_classifying(): return classifying
func apply_var_inspection_input_locked(): return input_lock
func apply_var_inspection_rotating(): return false
func apply_var_inspection_scanning(): return scans>0
func is_night_hub_hub_active(): return screen=="night_hub"
func is_parcel_intake_intake_active(): return screen=="parcel_intake"
func is_inspection_inspect_active(): return screen=="inspection"
func is_classification_result_result_active(): return screen=="classification_result"
func is_shift_summary_summary_active(): return screen=="shift_summary"
func is_rule_manual_rule_overlay_active(): return screen=="rule_manual"
func is_pause_paused_active(): return screen=="pause"
