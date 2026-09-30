extends RefCounted
func rule_rul_clues(clues): return clues.size()>=2
func rule_rul_decisions(): return ["RETURN","HOLD","REPORT"]
func rule_rul_grades(score): return "A" if score>=240 else "B" if score>=160 else "C"
func rule_rul_principle(): return "decide from corroborated physical and statement evidence"
func rule_rul_questions(): return 3
func rule_rul_score(correct): return 100 if correct else -40
