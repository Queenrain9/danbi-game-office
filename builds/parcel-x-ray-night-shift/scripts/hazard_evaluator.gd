extends RefCounted

static func expected_lane(data:Dictionary) -> String:
 var dense_near_wall := false
 var dense_count := 0
 var has_cable := false
 var has_cell := false
 for o in data.objects:
  var kind := String(o[0])
  if kind in ["metal","tool"]:
   dense_count += 1
   if float(o[1]) <= 0.10 or float(o[1]) >= 0.90: dense_near_wall = true
  elif kind=="cable": has_cable = true
  elif kind=="cell": has_cell = true
 if dense_count >= 2 and has_cable and has_cell and data.get("linked_pair",false) and data.get("power_contact",false):
  return "ISOLATE"
 if dense_near_wall and not data.get("packed",false):
  return "REPACK"
 return "PASS"

static func reason(data:Dictionary) -> String:
 var lane:=expected_lane(data)
 if lane=="ISOLATE": return "Two dense objects are cable-linked and contact a power cell."
 if lane=="REPACK": return "A dense object sits inside the outer-wall band without cushioning."
 return "No active hazard relationship was found."
