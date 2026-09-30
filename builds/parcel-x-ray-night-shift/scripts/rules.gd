extends RefCounted
func rule_rul_combo(correct_streak=0): return 25 if correct_streak>=3 else 0
func rule_rul_failure(score=0): return score < -100
func rule_rul_hazard_01(case_id=0): return case_id%3==0
func rule_rul_hazard_02(case_id=0): return case_id%3==1
func rule_rul_hazard_03(case_id=0): return case_id%3==2
func rule_rul_scan_budget(scans=0): return scans<4
func rule_rul_scoring_correct(): return 100
func rule_rul_scoring_critical_isolate(): return 150
func rule_rul_scoring_efficient_bonus(scans=0): return 20 if scans<=2 else 0
func rule_rul_scoring_false_pin(): return -10
func rule_rul_scoring_wrong_other(): return -40
func rule_rul_scoring_wrong_pass(): return -80
