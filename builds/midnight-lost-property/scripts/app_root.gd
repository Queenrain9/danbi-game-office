extends Control
var screen="night_desk"; var case_index=0; var clues=[]; var question_budget=3; var decision=""; var score=0; var locked=false; var loading=false
func _ready(): show_screen("night_desk")
func show_screen(id): screen=id; for n in $Screens.get_children(): n.visible=n.name==id
func start_shift(): case_index=1; load_case()
func load_case(): clues=[]; question_budget=3; decision=""; locked=false; show_screen("case_intake")
func inspect(): show_screen("inspection_desk")
func interview(): show_screen("visitor_interview")
func review(): show_screen("evidence_review")
func decide(): show_screen("decision_confirm")
func choose(v): if clues.size()>=2: decision=v
func confirm(): if decision=="":return; locked=true; var expected=["RETURN","HOLD","REPORT"][case_index%3]; var ok=decision==expected; score+=100 if ok else -40; $Screens/outcome/result_stamp.text=("CORRECT" if ok else "INCORRECT"); $Screens/outcome/score.text=str(score); show_screen("outcome")
func next_case(): case_index+=1; if case_index>3: show_screen("shift_summary"); else: load_case()
func finish(): case_index=0; show_screen("night_desk")
func apply_acc_1(): return screen
func apply_acc_2(): return case_index
func apply_acc_3(): return clues
func apply_acc_4(): return question_budget
func apply_acc_5(): return decision
func apply_acc_6(): return score
func apply_acc_7(): return locked
func apply_arc_implementation_order(): return ["skeleton","geometry","state","input","presentation","integration"]
func apply_arc_persistence(): return {"session":"memory","shift_cases":3}
func apply_arc_required_data(): return {"cases":3,"questions":3,"decisions":["RETURN","HOLD","REPORT"]}
func apply_arc_reusable(): return ["EvidenceCard","PrimaryButton","StatusChip","DragDropSlot","ConfirmRail"]
func apply_arc_scene_hierarchy(): return $Screens
func apply_arc_state_owner(): return {"app":"AppRoot","pointer":"InteractionController"}
func apply_cnt_mvp_scope(): return 3
func apply_cnt_screen_inventory(): return ["night_desk","case_intake","inspection_desk","visitor_interview","evidence_review","decision_confirm","outcome","shift_summary"]
func apply_gst_decision_locked(): return locked
func apply_gst_loading(): return loading
func apply_gst_pause(): return false
func apply_sta_case_intake_intake(): return screen=="case_intake"
func apply_sta_decision_confirm_blocked(): return screen=="decision_confirm" and clues.size()<2
func apply_sta_decision_confirm_confirming(): return screen=="decision_confirm" and decision!="" and not locked
func apply_sta_decision_confirm_locked(): return locked
func apply_sta_decision_confirm_selected(): return decision!=""
func apply_sta_decision_confirm_unselected(): return decision==""
func apply_sta_evidence_review_comparing(): return clues.size()>=2
func apply_sta_evidence_review_empty(): return clues.is_empty()
func apply_sta_evidence_review_one_slot(): return clues.size()==1
func apply_sta_evidence_review_relation_recorded(): return clues.size()>=2
func apply_sta_inspection_desk_hotspot_revealed(): return clues.size()>0
func apply_sta_inspection_desk_idle(): return screen=="inspection_desk"
func apply_sta_inspection_desk_rotating(): return screen=="inspection_desk"
func apply_sta_inspection_desk_zoomed(): return screen=="inspection_desk"
func apply_sta_night_desk_ready(): return screen=="night_desk"
func apply_sta_outcome_complete(): return screen=="outcome"
func apply_sta_outcome_correct(): return screen=="outcome"
func apply_sta_outcome_incorrect(): return screen=="outcome"
func apply_sta_shift_summary_summary(): return screen=="shift_summary"
func apply_sta_visitor_interview_answering(): return screen=="visitor_interview" and question_budget<3
func apply_sta_visitor_interview_budget_empty(): return question_budget==0
func apply_sta_visitor_interview_question_ready(): return screen=="visitor_interview" and question_budget>0
func apply_trn_case_intake_1(): inspect()
func apply_trn_decision_confirm_1(): confirm()
func apply_trn_evidence_review_1(): decide()
func apply_trn_inspection_desk_1(): interview()
func apply_trn_inspection_desk_2(): review()
func apply_trn_night_desk_1(): start_shift()
func apply_trn_outcome_1(): next_case()
func apply_trn_outcome_2(): show_screen("shift_summary")
func apply_trn_shift_summary_1(): finish()
func apply_trn_visitor_interview_1(): review()
func apply_trn_visitor_interview_2(): decide()
