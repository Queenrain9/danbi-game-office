class_name DanbiSnapV1
extends RefCounted
func evaluate(position:Vector2,target:Vector2,tolerance_px:float)->Dictionary:
    var d:=position.distance_to(target);return {"snapped":d<=tolerance_px,"distance":d,"position":target if d<=tolerance_px else position}
func evaluate_transform(position:Vector2,target:Vector2,tolerance_px:float,rotation_deg:float=0.0,target_rotation_deg:float=0.0,rotation_tolerance_deg:float=360.0)->Dictionary:
    var d:=position.distance_to(target);var re:=absf(wrapf(rotation_deg-target_rotation_deg,-180.0,180.0));var ok:=d<=tolerance_px and re<=rotation_tolerance_deg
    return {"snapped":ok,"distance":d,"rotation_error_deg":re,"position":target if ok else position,"rotation_deg":target_rotation_deg if ok else rotation_deg}
