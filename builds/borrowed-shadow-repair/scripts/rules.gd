extends RefCounted

func rule_rul_snap(position_error_px: float = 0.0, rotation_error_deg: float = 0.0) -> bool: return position_error_px <= 18.0 and rotation_error_deg <= 12.0
func rule_rul_score(diagnosis: bool = true, alignment: bool = true, stitch: bool = true, rework: bool = false) -> int: return (20 if diagnosis else 0) + (50 if alignment else 0) + (30 if stitch else 0) - (10 if rework else 0)
func rule_rul_grades(value: int) -> String: return "S" if value >= 95 else ("A" if value >= 80 else ("B" if value >= 65 else "C"))
func rule_rul_pieces(order_index: int = 1) -> int: return clampi(order_index + 1, 2, 6)
func rule_rul_failure() -> String: return "low_grade_with_residual_behavior"
func rule_rul_rework_limit() -> int: return 1
func rule_rul_stitch_trace_deviation_px() -> float: return 20.0
