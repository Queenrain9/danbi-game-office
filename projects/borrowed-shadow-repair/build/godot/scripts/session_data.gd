extends RefCounted
const SAVE_PATH := "user://borrowed_shadow_progress.json"
var ContractData := [
 {"id":1,"pieces":2,"rotation_lock":false,"stitch_order":[0]},
 {"id":2,"pieces":3,"rotation_lock":false,"stitch_order":[0,1]},
 {"id":3,"pieces":4,"rotation_lock":true,"stitch_order":[0,1]},
 {"id":4,"pieces":5,"rotation_lock":true,"stitch_order":[0,1,2]},
 {"id":5,"pieces":6,"rotation_lock":true,"stitch_order":[0,1,2]}
]
var contracts: Array:
 get: return ContractData
var PieceData := {"min":2,"max":6,"independent_transforms":true}
var AnchorGraph := {"position_tolerance_px":18.0,"rotation_tolerance_deg":12.0}
var SeamGraph := {"corridor_px":20.0,"requires_endpoint":true,"ordered":true}
var TestPose := {"hold_seconds":0.6,"rework_limit":1}
var completed_contracts:Array[int]=[]
var unlocked:=1
func load_progress()->void:
 if not FileAccess.file_exists(SAVE_PATH): return
 var f=FileAccess.open(SAVE_PATH,FileAccess.READ); var d=JSON.parse_string(f.get_as_text())
 if d is Dictionary:
  unlocked=int(d.get("unlocked",1)); completed_contracts.assign(d.get("completed",[]))
func complete_contract(index:int)->void:
 if not completed_contracts.has(index): completed_contracts.append(index)
 unlocked=maxi(unlocked,min(index+1,5))
 var f=FileAccess.open(SAVE_PATH,FileAccess.WRITE); f.store_string(JSON.stringify({"unlocked":unlocked,"completed":completed_contracts}))
