extends Control
enum Screen { HUB, INTAKE, INSPECT, RESULT, SUMMARY }
var screen=Screen.HUB
var case_index=0
var score=0
var correct=0
var critical=0
var slice_depth=50.0
var pins=0
var cases=[
{"label":"NX-104","answer":"PASS","reason":"No hazard relationship."},
{"label":"KR-218","answer":"REPACK","reason":"Dense metal near outer wall."},
{"label":"PX-331","answer":"ISOLATE","reason":"Dense pair linked to power cell."},
{"label":"MT-407","answer":"PASS","reason":"Decoys only."},
{"label":"QV-512","answer":"REPACK","reason":"Dense tool in outer-wall band."},
{"label":"HB-609","answer":"ISOLATE","reason":"Linked dense pair contacts power cell."},
{"label":"AC-774","answer":"PASS","reason":"No linked dense pair."},
{"label":"ZX-880","answer":"REPACK","reason":"Dense plate too close to wall."},
{"label":"DV-901","answer":"PASS","reason":"No power cell contact."},
{"label":"LS-993","answer":"ISOLATE","reason":"Linked pair reaches power cell."}]
var box
var info
var drag_start=Vector2.ZERO
var rotating=false
func _ready(): show_hub()
func clear_ui():
 for c in get_children(): c.queue_free()
func base(title):
 clear_ui()
 var v=VBoxContainer.new()
 v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 v.add_theme_constant_override("separation",12)
 add_child(v)
 var t=Label.new(); t.text=title; t.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 t.add_theme_font_size_override("font_size",24); v.add_child(t)
 return v
func add_button(v,text,call):
 var b=Button.new(); b.text=text; b.custom_minimum_size=Vector2(0,58); b.pressed.connect(call); v.add_child(b)
func show_hub():
 screen=Screen.HUB
 var v=base("PARCEL X-RAY · NIGHT SHIFT")
 var l=Label.new(); l.text="Night Shift 01\n8 parcels · 3 hazard rules"; l.custom_minimum_size=Vector2(0,300); l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; v.add_child(l)
 add_button(v,"START SHIFT",start_shift)
func start_shift():
 case_index=0; score=0; correct=0; critical=0; show_intake()
func show_intake():
 screen=Screen.INTAKE; pins=0; slice_depth=50
 var v=base("PARCEL INTAKE %d / 8" % (case_index+1))
 var l=Label.new(); l.text="LABEL "+cases[case_index].label+"\n\nR1 Dense metal near wall → REPACK\nR2 Dense pair + cable + power cell → ISOLATE\nR3 Otherwise → PASS"; l.custom_minimum_size=Vector2(0,420); v.add_child(l)
 add_button(v,"BEGIN INSPECT",show_inspect)
func show_inspect():
 screen=Screen.INSPECT
 var v=base("X-RAY INSPECTION")
 info=Label.new(); info.text="Drag parcel to rotate · rail scans · tap parcel pins"; v.add_child(info)
 var area=Control.new(); area.custom_minimum_size=Vector2(0,590); v.add_child(area)
 box=Panel.new(); box.position=Vector2(40,40); box.size=Vector2(360,380); box.gui_input.connect(parcel_input); area.add_child(box)
 var bl=Label.new(); bl.name="Readout"; bl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bl.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; bl.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; bl.mouse_filter=Control.MOUSE_FILTER_IGNORE; bl.text=readout(); box.add_child(bl)
 var rail=VSlider.new(); rail.min_value=0; rail.max_value=100; rail.value=50; rail.position=Vector2(430,40); rail.size=Vector2(70,380); rail.value_changed.connect(scan_changed); area.add_child(rail)
 var lanes=HBoxContainer.new(); lanes.position=Vector2(10,470); lanes.size=Vector2(500,70); area.add_child(lanes)
 for name in ["PASS","REPACK","ISOLATE"]:
  var b=Button.new(); b.text=name; b.size_flags_horizontal=Control.SIZE_EXPAND_FILL; b.pressed.connect(classify.bind(name)); lanes.add_child(b)
 var rules=Button.new(); rules.text="? RULES"; rules.position=Vector2(410,0); rules.pressed.connect(show_rules); area.add_child(rules)
 add_button(v,"PAUSE",show_pause)
func readout():
 return "PARCEL / X-RAY\n\nSlice %d%%\nPins %d / 4\n\nRotate view" % [int(slice_depth),pins]
func parcel_input(e):
 if e is InputEventScreenTouch:
  if e.pressed: drag_start=e.position; rotating=false
  else:
   if not rotating and pins<4: pins+=1; info.text="Evidence pin placed · %d/4" % pins
   rotating=false
 elif e is InputEventScreenDrag:
  rotating=true; info.text="ROTATING"
 if box and box.has_node("Readout"): box.get_node("Readout").text=readout()
func scan_changed(v):
 slice_depth=v
 if box and box.has_node("Readout"): box.get_node("Readout").text=readout()
func classify(choice):
 var c=cases[case_index]
 var delta=100 if choice==c.answer else (-180 if choice=="PASS" and c.answer=="ISOLATE" else -80)
 if choice==c.answer: correct+=1
 elif choice=="PASS" and c.answer=="ISOLATE": critical+=1
 score+=delta; show_result(choice,delta)
func show_result(choice,delta):
 screen=Screen.RESULT
 var v=base(("CORRECT" if choice==cases[case_index].answer else "INCORRECT")+" · "+choice)
 var l=Label.new(); l.text="Expected: "+cases[case_index].answer+"\nScore: %d\n\nEVIDENCE\n"+cases[case_index].reason; l.custom_minimum_size=Vector2(0,430); v.add_child(l)
 add_button(v,"NEXT PARCEL" if case_index<7 else "SHIFT SUMMARY",advance)
func advance():
 case_index+=1
 if case_index>=8: show_summary()
 else: show_intake()
func show_summary():
 screen=Screen.SUMMARY
 var v=base("SHIFT SUMMARY")
 var grade="A" if correct>=7 and critical==0 else ("B" if correct>=6 and critical<2 else "C")
 var l=Label.new(); l.text="GRADE "+grade+"\n\nAccuracy %d / 8\nCritical Miss %d\nScore %d" % [correct,critical,score]; l.custom_minimum_size=Vector2(0,430); l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; v.add_child(l)
 add_button(v,"BACK TO HUB",show_hub)
func show_rules():
 var v=base("RULE MANUAL")
 var l=Label.new(); l.text="R1 Dense metal near outer wall → REPACK\n\nR2 Dense pair + cable + power cell → ISOLATE\n\nR3 Otherwise → PASS"; l.custom_minimum_size=Vector2(0,430); v.add_child(l)
 add_button(v,"CLOSE",show_inspect)
func show_pause():
 var v=base("PAUSED")
 add_button(v,"RESUME",show_inspect)
 add_button(v,"QUIT TO HUB",show_hub)
