extends Control
func depth_from_y(y:float)->float:return clampf(y/size.y*100.0,0.0,100.0)
