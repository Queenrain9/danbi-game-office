extends SceneTree

# Non-invasive compatibility probe for the currently audited Borrowed Shadow Repair
# interaction constants. It does NOT mutate builds/borrowed-shadow-repair and is not
# runtime evidence unless this exact script is actually executed and its exit/log saved.
const DragV1=preload("res://drag_v1.gd")
const SnapV1=preload("res://snap_v1.gd")
const HoldV1=preload("res://hold_v1.gd")
const TraceV1=preload("res://trace_v1.gd")

var failures:=0
func check(v:bool,m:String)->void:
    if not v:
        failures+=1
        push_error(m)

func _initialize()->void:
    var drag=DragV1.new()
    drag.configure({"cancel":"return_origin"})
    drag.begin(1,Vector2(100,100),Vector2(200,200))
    check(drag.update(1,Vector2(130,145)).position==Vector2(230,245),"Borrowed Shadow drag delta")
    check(drag.cancel().position==Vector2(200,200),"Borrowed Shadow drag cancel")

    var snap=SnapV1.new()
    check(snap.evaluate_transform(Vector2(18,0),Vector2.ZERO,18.0,12.0,0.0,12.0).snapped,"Borrowed Shadow 18px/12deg boundary")
    check(not snap.evaluate_transform(Vector2(18.1,0),Vector2.ZERO,18.0,0.0,0.0,12.0).snapped,"Borrowed Shadow position outside")
    check(not snap.evaluate_transform(Vector2(10,0),Vector2.ZERO,18.0,12.1,0.0,12.0).snapped,"Borrowed Shadow rotation outside")

    var hold=HoldV1.new()
    hold.configure({"hold_ms":600,"movement_tolerance_px":18.0})
    hold.begin(1000,Vector2.ZERO)
    check(not hold.update(1599,Vector2.ZERO).completed,"Borrowed Shadow hold before 600ms")
    check(hold.update(1600,Vector2.ZERO).completed,"Borrowed Shadow hold at 600ms")

    var trace=TraceV1.new()
    trace.configure([Vector2(24,100),Vector2(270,140),Vector2(516,180)],{"tolerance_px":20.0,"min_coverage":0.9})
    trace.begin(Vector2(24,100))
    check(trace.append_point(Vector2(270,145)).valid,"Borrowed Shadow trace inside 20px corridor")
    check(trace.finish(Vector2(516,180)).passed,"Borrowed Shadow trace completion")

    if failures==0:
        print("BORROWED_SHADOW_ADAPTER_COMPATIBILITY_PASS")
    quit(failures)
