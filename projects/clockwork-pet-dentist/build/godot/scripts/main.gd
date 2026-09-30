extends Control
var screen="patient_select"; var selected=-1; var prior="treatment"; var mode="inspection"; var defects=0; var damage=0; var tool="probe"; var held_part=false; var retainer_released=false; var socket_empty=false; var friction=1.0; var overfill=0.0; var phase=0.0; var fit=1.0; var installed=false; var camera_zoom=1.0; var camera_pan=Vector2.ZERO
func _ready(): show_screen("patient_select")
func show_screen(id): screen=id; for n in get_children(): if n is Control: n.visible=n.name==id
func state_model(): return {"screen":screen,"mode":mode,"selected":selected,"damage":damage,"socket_empty":socket_empty,"installed":installed,"held":held_part}
func rule_model(): return {"patients":3,"defects_per_patient":[1,3],"alignment_tolerance_deg":3,"fit_tolerance":.08,"damage_strikes":3,"score":"repair quality"}
func integration_flow(): return ["patient_select","patient_brief","treatment","part_bench","treatment_result"]
func action_patient_select_0(i=0): selected=i
func input_patient_select_0(i=0): action_patient_select_0(i)
func action_patient_select_1(): if selected>=0: show_screen("patient_brief")
func action_patient_brief_0(): mode="inspection"; defects=0; damage=0; show_screen("treatment")
func action_treatment_0(pan=Vector2.ZERO,zoom=1.0): if not held_part: camera_pan+=pan; camera_zoom=clampf(camera_zoom*zoom,.7,2.0)
func input_treatment_0(pan=Vector2.ZERO,zoom=1.0): action_treatment_0(pan,zoom)
func action_treatment_1(): if tool=="probe": defects+=1
func input_treatment_1(): action_treatment_1()
func action_treatment_2(axis=1.0): if tool=="extractor" and retainer_released and axis>.7: socket_empty=true; held_part=true
func input_treatment_2(axis=1.0): action_treatment_2(axis)
func action_treatment_3(amount=.1): if tool=="oil": friction=maxf(0.0,friction-amount); overfill+=amount
func input_treatment_3(amount=.1): action_treatment_3(amount)
func action_treatment_4(angle=0.0): if socket_empty and held_part: phase=deg_to_rad(roundi(rad_to_deg(angle)/3.0)*3)
func input_treatment_4(angle=0.0): action_treatment_4(angle)
func action_treatment_5(valid=true): if socket_empty and held_part and valid and absf(rad_to_deg(phase))<=3.0: installed=true; socket_empty=false; held_part=false
func input_treatment_5(valid=true): action_treatment_5(valid)
func action_treatment_6(held=.0): if installed and held>=.8: mode="testing"; await get_tree().create_timer(.4).timeout; show_screen("treatment_result")
func input_treatment_6(held=.0): action_treatment_6(held)
func action_part_bench_0(amount=.05): fit=maxf(.0,fit-amount)
func input_part_bench_0(amount=.05): action_part_bench_0(amount)
func action_part_bench_1(): show_screen("treatment")
func action_pause_0(): show_screen(prior)
func action_treatment_result_0(): show_screen("patient_brief")
func action_treatment_result_1(): selected=-1; show_screen("patient_select")
func pause_game(): prior=screen; show_screen("pause")
