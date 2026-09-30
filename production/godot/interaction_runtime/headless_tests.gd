extends SceneTree
const DragV1=preload("res://drag_v1.gd")
const SnapV1=preload("res://snap_v1.gd")
const HoldV1=preload("res://hold_v1.gd")
const SwipeV1=preload("res://swipe_v1.gd")
const TraceV1=preload("res://trace_v1.gd")
const PinchV1=preload("res://pinch_v1.gd")
var failures:=0
func check(v:bool,m:String)->void:
    if not v:failures+=1;push_error(m)
func _initialize()->void:
    var d=DragV1.new();d.begin(1,Vector2(10,10),Vector2(100,100));check(d.update(1,Vector2(30,40)).position==Vector2(120,130),"drag");check(d.release(1,Vector2(30,40)).phase=="release","drag release")
    var s=SnapV1.new();check(s.evaluate(Vector2(17,0),Vector2.ZERO,18.0).snapped,"snap in");check(not s.evaluate(Vector2(19,0),Vector2.ZERO,18.0).snapped,"snap out")
    var h=HoldV1.new();h.configure({"hold_ms":600,"movement_tolerance_px":12.0});h.begin(1000,Vector2.ZERO);check(not h.update(1599,Vector2.ZERO).completed,"hold before");check(h.update(1600,Vector2.ZERO).completed,"hold threshold")
    var w=SwipeV1.new();w.configure({"min_distance_px":48.0,"max_duration_ms":700});w.begin(2,Vector2.ZERO,0);var sw=w.release(2,Vector2(80,5),300);check(sw.accepted and sw.direction=="right","swipe")
    var t=TraceV1.new();t.configure([Vector2(0,0),Vector2(50,0),Vector2(100,0)],{"tolerance_px":20.0,"min_coverage":0.9});t.begin(Vector2(0,0));t.append_point(Vector2(50,5));check(t.finish(Vector2(100,0)).passed,"trace")
    var p=PinchV1.new();p.configure({"min_value":0.5,"max_value":2.0});p.touch(1,true,Vector2(0,0),1.0);p.touch(2,true,Vector2(100,0),1.0);check(absf(p.drag(2,Vector2(150,0)).value-1.5)<0.001,"pinch")
    if failures==0:print("DANBI_INTERACTION_RUNTIME_PASS")
    quit(failures)
