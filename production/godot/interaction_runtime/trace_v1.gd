class_name DanbiTraceV1
extends RefCounted
var target_points:Array[Vector2]=[]
var tolerance_px:=20.0
var min_coverage:=0.9
var active:=false
var valid:=true
var max_segment:=0
var quality:=1.0
func configure(points:Array[Vector2],params:Dictionary={})->void:target_points=points.duplicate();tolerance_px=float(params.get("tolerance_px",tolerance_px));min_coverage=float(params.get("min_coverage",min_coverage))
func begin(point:Vector2)->Dictionary:active=target_points.size()>=2;valid=active;max_segment=0;quality=1.0;return append_point(point) if active else {"handled":false,"valid":false}
func _segment_distance(point:Vector2,a:Vector2,b:Vector2)->float:
    var ab:=b-a;var denom:=ab.length_squared()
    if denom<=0.000001:return point.distance_to(a)
    var t:=clampf((point-a).dot(ab)/denom,0.0,1.0);return point.distance_to(a+ab*t)
func append_point(point:Vector2)->Dictionary:
    if not active or not valid:return {"handled":false,"valid":false}
    var best:=1.0e12;var best_segment:=0
    for i in range(target_points.size()-1):
        var d:=_segment_distance(point,target_points[i],target_points[i+1])
        if d<best:best=d;best_segment=i
    if best>tolerance_px:valid=false;active=false;quality=0.0;return {"handled":true,"valid":false,"reason":"outside_tolerance","distance":best}
    max_segment=maxi(max_segment,best_segment);quality=minf(quality,1.0-best/maxf(tolerance_px,0.001));var coverage:=float(max_segment+1)/float(maxi(target_points.size()-1,1))
    return {"handled":true,"valid":true,"distance":best,"coverage":coverage,"quality":quality}
func finish(point:Vector2)->Dictionary:
    var last:=append_point(point) if active else {"valid":valid,"coverage":0.0,"quality":quality};var coverage:=float(max_segment+1)/float(maxi(target_points.size()-1,1));var passed:=valid and coverage>=min_coverage and point.distance_to(target_points[-1])<=tolerance_px;active=false
    return {"handled":true,"valid":valid,"passed":passed,"coverage":coverage,"quality":quality,"last":last}
func cancel()->void:active=false;valid=false
