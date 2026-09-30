extends SceneTree
const SnapV1=preload("res://runtime/interaction/snap_v1.gd")
const HoldV1=preload("res://runtime/interaction/hold_v1.gd")
const TraceV1=preload("res://runtime/interaction/trace_v1.gd")
var failures:=0
func check(v:bool,m:String)->void:
    if not v:failures+=1;push_error(m)
func _initialize()->void:
    var s=SnapV1.new();check(s.evaluate_transform(Vector2(18,0),Vector2.ZERO,18.0,12.0,0.0,12.0).snapped,"snap boundary");check(not s.evaluate_transform(Vector2(18.1,0),Vector2.ZERO,18.0,0.0,0.0,12.0).snapped,"snap outside")
    var h=HoldV1.new();h.configure({"hold_ms":600,"movement_tolerance_px":18.0});h.begin(0,Vector2.ZERO);check(h.update(600,Vector2.ZERO).completed,"hold")
    var t=TraceV1.new();t.configure([Vector2(24,100),Vector2(516,180)],{"tolerance_px":20.0,"min_coverage":0.9});t.begin(Vector2(24,100));check(t.finish(Vector2(516,180)).passed,"trace")
    if failures==0:print("BORROWED_SHADOW_ADAPTER_SMOKE_PASS")
    quit(failures)
