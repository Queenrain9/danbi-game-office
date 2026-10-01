extends Control
class_name ScanRail
func depth_from_y(local_y: float) -> float:
	return clampf(local_y / maxf(size.y, 1.0) * 100.0, 0.0, 100.0)
