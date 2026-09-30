extends Control

const ShiftState = preload("res://scripts/shift_state.gd")
const HazardEvaluator = preload("res://scripts/hazard_evaluator.gd")
const GestureRouter = preload("res://scripts/gesture_router.gd")
const CaseData = preload("res://scripts/case_data.gd")

enum Screen { HUB, INTAKE, INSPECT, RESULT, SUMMARY }
enum Gesture { NONE, BOX, SCAN, CLASSIFY }

const SHIFT_SIZE := 8
const DRAG_THRESHOLD := 18.0
const CLASSIFY_THRESHOLD_Y := 440.0
var shift := ShiftState.new()
var gesture_router := GestureRouter.new()

var slice_depth := 50.0
var scan_reversals := 0
var scan_last_direction := 0
var scan_uses := 0
var scan_active := false
var pins: Array[Dictionary] = []
var box_pose := Vector2.ZERO
var input_locked := false
var gesture := Gesture.NONE
var pointer_start := Vector2.ZERO
var pointer_last := Vector2.ZERO
var box_home := Vector2.ZERO
var selected_lane := ""

var play_area: Control
var parcel: Panel
var parcel_visual: Control
var scan_plane: ColorRect
var rail: VSlider
var info: Label
var pin_layer: Control
var lanes: Dictionary = {}

var cases: Array = CaseData.all()
var overlay: Control
var prior_screen := Screen.INSPECT
var hud_layer: Control
var overlay_layer: Control

func _ready() -> void:
 hud_layer = get_node("HUDLayer")
 overlay_layer = get_node("OverlayLayer")
 show_hub()

func clear_ui() -> void:
 for c in hud_layer.get_children():
  c.queue_free()
 lanes.clear()

func base(title: String) -> VBoxContainer:
 clear_ui()
 var v := VBoxContainer.new()
 v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 v.add_theme_constant_override("separation", 10)
 hud_layer.add_child(v)
 var t := Label.new()
 t.text = title
 t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 t.add_theme_font_size_override("font_size", 24)
 v.add_child(t)
 return v

func add_button(parent: Control, text: String, callback: Callable) -> Button:
 var b := Button.new()
 b.text = text
 b.custom_minimum_size = Vector2(0, 54)
 b.pressed.connect(callback)
 parent.add_child(b)
 return b

func show_hub() -> void:
 screen = Screen.HUB
 var v := base("PARCEL X-RAY · NIGHT SHIFT")
 var l := Label.new()
 l.text = "Night Shift 01\n8 parcels · 3 hazard rules\n\nRotate · Slice · Pin · Drag-classify"
 l.custom_minimum_size = Vector2(0, 300)
 l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 v.add_child(l)
 add_button(v, "START SHIFT", start_shift)

func start_shift() -> void:
 shift.begin_shift(cases)
 show_intake()

func show_intake() -> void:
 screen = Screen.INTAKE
 reset_case_state()
 var v := base("PARCEL INTAKE %d / %d" % [shift.case_index + 1, SHIFT_SIZE])
 var l := Label.new()
 l.text = "LABEL  %s\n\nR1  dense object near outer wall → REPACK\nR2  linked dense pair + power contact → ISOLATE\nR3  otherwise → PASS" % shift.current_case().label
 l.custom_minimum_size = Vector2(0, 420)
 l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 v.add_child(l)
 add_button(v, "BEGIN INSPECT", show_inspect)

func reset_case_state() -> void:
 slice_depth = 50.0
 scan_reversals = 0
 scan_last_direction = 0
 scan_uses = 0
 scan_active = false
 pins.clear()
 box_pose = Vector2.ZERO
 input_locked = false
 gesture = Gesture.NONE
 selected_lane = ""

func show_inspect() -> void:
 screen = Screen.INSPECT
 var v := base("X-RAY INSPECTION")
 info = Label.new()
 info.text = "Drag parcel to rotate · right rail scans · tap visible shapes · drag parcel down to classify"
 info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 v.add_child(info)
 play_area = Control.new()
 play_area.custom_minimum_size = Vector2(0, 660)
 v.add_child(play_area)

 parcel = Panel.new()
 parcel.position = Vector2(52, 40)
 parcel.size = Vector2(340, 360)
 box_home = parcel.position
 parcel.gui_input.connect(_on_parcel_input)
 play_area.add_child(parcel)

 parcel_visual = Control.new()
 parcel_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 parcel_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parcel.add_child(parcel_visual)
 _rebuild_xray()

 scan_plane = ColorRect.new()
 scan_plane.position = Vector2(0, 178)
 scan_plane.size = Vector2(340, 3)
 scan_plane.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parcel.add_child(scan_plane)

 pin_layer = Control.new()
 pin_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 pin_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parcel.add_child(pin_layer)

 rail = VSlider.new()
 rail.min_value = 0
 rail.max_value = 100
 rail.value = slice_depth
 rail.position = Vector2(430, 40)
 rail.size = Vector2(72, 360)
 rail.value_changed.connect(_on_scan_changed)
 rail.gui_input.connect(_on_rail_input)
 play_area.add_child(rail)

 var rules := Button.new()
 rules.text = "? RULES"
 rules.position = Vector2(420, 0)
 rules.size = Vector2(90, 36)
 rules.pressed.connect(show_rules)
 play_area.add_child(rules)

 var lane_row := HBoxContainer.new()
 lane_row.position = Vector2(10, 500)
 lane_row.size = Vector2(510, 100)
 play_area.add_child(lane_row)
 for lane_name in ["PASS", "REPACK", "ISOLATE"]:
  var lane := Panel.new()
  lane.custom_minimum_size = Vector2(160, 96)
  lane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  var label := Label.new()
  label.text = lane_name
  label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  lane.add_child(label)
  lane_row.add_child(lane)
  lanes[lane_name] = lane

 add_button(v, "PAUSE", show_pause)
 _update_inspection_feedback()

func _rebuild_xray() -> void:
 for c in parcel_visual.get_children():
  c.queue_free()
 var data: Dictionary = shift.current_case()
 for i in range(data.objects.size()):
  var o: Array = data.objects[i]
  var depth := float(o[3])
  if abs(depth - slice_depth / 100.0) > 0.22:
   continue
  var shape := ColorRect.new()
  shape.name = "Hotspot_%d" % i
  shape.position = Vector2(float(o[1]) * 280.0 + 18.0, float(o[2]) * 280.0 + 18.0)
  shape.size = Vector2(34, 34) if o[0] != "cable" else Vector2(80, 12)
  shape.mouse_filter = Control.MOUSE_FILTER_IGNORE
  shape.modulate.a = 0.45 + (0.22 - abs(depth - slice_depth / 100.0))
  parcel_visual.add_child(shape)

func _on_parcel_input(event: InputEvent) -> void:
 if input_locked:
  return
 var pos := _event_pos(event)
 if event is InputEventScreenTouch or event is InputEventMouseButton:
  if event.pressed:
   pointer_start = pos
   pointer_last = pos
   gesture_router.begin_box(pos)
   gesture = Gesture.BOX
   selected_lane = ""
  else:
   if gesture == Gesture.CLASSIFY:
    _finish_classification()
   elif gesture == Gesture.BOX:
    if gesture_router.is_tap(pos):
     _try_pin(pos)
   gesture_router.cancel()
   gesture = Gesture.NONE
 elif event is InputEventScreenDrag or event is InputEventMouseMotion:
  if gesture == Gesture.NONE:
   return
  var delta := gesture_router.move(pos)
  pointer_last = pos
  var total := pos - pointer_start
  if gesture == Gesture.BOX and total.y > 80.0:
   gesture = Gesture.CLASSIFY
  if gesture == Gesture.CLASSIFY:
   parcel.position += delta
   selected_lane = _lane_under_parcel()
   info.text = ("CLASSIFY → " + selected_lane) if selected_lane != "" else "Release outside a lane to cancel"
  else:
   box_pose.x = clamp(box_pose.x + delta.x * 0.35, -65.0, 65.0)
   box_pose.y = clamp(box_pose.y + delta.y * 0.25, -35.0, 35.0)
   parcel.rotation = deg_to_rad(box_pose.x * 0.18)
   parcel.scale = Vector2.ONE * (1.0 - abs(box_pose.y) / 700.0)
   parcel_visual.position.x = box_pose.y * 0.35
   info.text = "ROTATING · yaw %.0f · pitch %.0f" % [box_pose.x, box_pose.y]

func _event_pos(event: InputEvent) -> Vector2:
 if event is InputEventScreenTouch or event is InputEventScreenDrag:
  return event.position
 if event is InputEventMouseButton or event is InputEventMouseMotion:
  return event.position
 return Vector2.ZERO

func _on_rail_input(event: InputEvent) -> void:
 if input_locked or gesture == Gesture.CLASSIFY:
  if event is InputEventScreenTouch:
   accept_event()
  return
 if event is InputEventScreenTouch or event is InputEventMouseButton:
  if event.pressed:
   gesture = Gesture.SCAN
   gesture_router.begin_scan(_event_pos(event))
   scan_active = true
   scan_uses += 1
   _update_inspection_feedback()
  else:
   gesture_router.cancel()
   gesture = Gesture.NONE

func _on_scan_changed(value: float) -> void:
 if input_locked or gesture == Gesture.CLASSIFY:
  return
 var direction := sign(value - slice_depth)
 if scan_last_direction != 0 and direction != 0 and direction != scan_last_direction:
  scan_reversals += 1
 scan_last_direction = direction
 slice_depth = value
 if scan_plane:
  scan_plane.position.y = 20.0 + (slice_depth / 100.0) * 320.0
 _rebuild_xray()
 _redraw_pins()
 _update_inspection_feedback()

func _try_pin(local_pos: Vector2) -> void:
 if not scan_active:
  info.text = "SCAN FIRST · evidence pins require an active X-ray slice"
  return
 if pins.size() >= 4:
  info.text = "PIN LIMIT · 4 / 4"
  return
 var hit := _hotspot_at(local_pos)
 if hit < 0:
  info.text = "NO TARGET · pin not placed"
  return
 for i in range(pins.size()):
  if pins[i].object_index == hit:
   pins.remove_at(i)
   _redraw_pins()
   info.text = "Evidence pin removed"
   return
 pins.append({"object_index":hit, "slice":slice_depth})
 _redraw_pins()
 info.text = "Evidence pinned · %d / 4" % pins.size()

func _hotspot_at(local_pos: Vector2) -> int:
 var data: Dictionary = shift.current_case()
 for i in range(data.objects.size()):
  var o: Array = data.objects[i]
  if abs(float(o[3]) - slice_depth / 100.0) > 0.22:
   continue
  var center := Vector2(float(o[1]) * 280.0 + 35.0, float(o[2]) * 280.0 + 35.0)
  if center.distance_to(local_pos) <= 42.0:
   return i
 return -1

func _redraw_pins() -> void:
 if not pin_layer:
  return
 for c in pin_layer.get_children():
  c.queue_free()
 var data: Dictionary = shift.current_case()
 for pin in pins:
  var o: Array = data.objects[int(pin.object_index)]
  if abs(float(o[3]) - slice_depth / 100.0) > 0.24:
   continue
  var mark := Label.new()
  mark.text = "◎"
  mark.position = Vector2(float(o[1]) * 280.0 + 18.0, float(o[2]) * 280.0 + 12.0)
  mark.add_theme_font_size_override("font_size", 28)
  pin_layer.add_child(mark)

func _lane_under_parcel() -> String:
 if parcel.position.y < CLASSIFY_THRESHOLD_Y:
  return ""
 var center := parcel.global_position + parcel.size * 0.5
 for lane_name in lanes:
  var lane: Control = lanes[lane_name]
  if lane.get_global_rect().has_point(center):
   return lane_name
 return ""

func _finish_classification() -> void:
 selected_lane = _lane_under_parcel()
 if selected_lane == "":
  var return_tween:=create_tween()
  return_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
  return_tween.tween_property(parcel,"position",box_home,0.18)
  info.text = "INVALID DROP · parcel returned to table"
  return
 input_locked = true
 var lane:Control=lanes[selected_lane]
 var target:=lane.global_position - play_area.global_position + lane.size*0.5 - parcel.size*0.5
 var snap:=create_tween()
 snap.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
 snap.tween_property(parcel,"position",target,0.12)
 snap.tween_callback(_evaluate.bind(selected_lane))

func expected_lane(data: Dictionary) -> String:
 return HazardEvaluator.expected_lane(data)

func _evaluate(choice: String) -> void:
 var data: Dictionary = shift.current_case()
 var expected := expected_lane(data)
 var false_pins:=0
 for pin in pins:
  var kind:=String(data.objects[int(pin.object_index)][0])
  if kind in ["foam","decoy"]: false_pins += 1
 var result: Dictionary = shift.record(choice, expected, scan_reversals, false_pins)
 show_result(choice, expected, int(result.delta))

func show_result(choice: String, expected: String, delta: int) -> void:
 screen = Screen.RESULT
 var v := base(("CORRECT" if choice == expected else "INCORRECT") + " · " + choice)
 var reason := HazardEvaluator.reason(shift.current_case())
 var data: Dictionary = shift.current_case()
 var l := Label.new()
 l.text = "Expected: %s\nScore change: %+d\nTotal: %d\nSlice %.0f%% · Pins %d\n%s" % [expected, delta, shift.score, slice_depth, pins.size(), reason]
 l.custom_minimum_size = Vector2(0, 150)
 l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 v.add_child(l)
 add_evidence_preview(v)
 add_button(v, "NEXT PARCEL" if shift.case_index < SHIFT_SIZE - 1 else "SHIFT SUMMARY", advance)

func add_evidence_preview(parent:Control) -> void:
 var preview:=Panel.new()
 preview.custom_minimum_size=Vector2(0,260)
 parent.add_child(preview)
 var data:Dictionary=shift.current_case()
 for o in data.objects:
  if abs(float(o[3])-slice_depth/100.0)>0.22: continue
  var shape:=ColorRect.new()
  shape.position=Vector2(float(o[1])*420.0+25.0,float(o[2])*190.0+25.0)
  shape.size=Vector2(42,42) if o[0]!="cable" else Vector2(110,14)
  shape.mouse_filter=Control.MOUSE_FILTER_IGNORE
  preview.add_child(shape)
 var line:=ColorRect.new()
 line.position=Vector2(10,20.0+(slice_depth/100.0)*210.0)
 line.size=Vector2(500,3)
 line.mouse_filter=Control.MOUSE_FILTER_IGNORE
 preview.add_child(line)

func advance() -> void:
 if shift.advance(): show_summary()
 else: show_intake()

func show_summary() -> void:
 screen = Screen.SUMMARY
 var v := base("SHIFT SUMMARY")
 var grade := shift.grade()
 var l := Label.new()
 l.text = "GRADE %s\n\nAccuracy %d / %d\nCritical Miss %d\nEfficiency · %d scan reversals\nScore %d" % [grade, shift.correct, SHIFT_SIZE, shift.critical, shift.total_scan_reversals, shift.score]
 l.custom_minimum_size = Vector2(0, 430)
 l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 v.add_child(l)
 add_button(v, "BACK TO HUB", show_hub)

func _modal(title:String, body:String) -> VBoxContainer:
 if overlay: overlay.queue_free()
 overlay = ColorRect.new()
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.mouse_filter = Control.MOUSE_FILTER_STOP
 overlay_layer.add_child(overlay)
 var panel := VBoxContainer.new()
 panel.set_anchors_preset(Control.PRESET_CENTER)
 panel.position = Vector2(55,180)
 panel.size = Vector2(430,520)
 overlay.add_child(panel)
 var h:=Label.new()
 h.text=title
 h.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 panel.add_child(h)
 var l:=Label.new()
 l.text=body
 l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 l.custom_minimum_size=Vector2(0,300)
 panel.add_child(l)
 return panel

func close_overlay() -> void:
 if overlay:
  overlay.queue_free()
  overlay = null

func show_rules() -> void:
 if input_locked or overlay: return
 var p:=_modal("RULE MANUAL","R1\nDense object near outer wall → REPACK\n\nR2\nLinked dense pair + cable + power contact → ISOLATE\n\nR3\nOtherwise → PASS")
 add_button(p,"CLOSE",close_overlay)

func show_pause() -> void:
 if overlay: return
 prior_screen=screen
 var p:=_modal("PAUSED","Shift state is frozen while this overlay blocks gameplay input.")
 add_button(p,"RESUME",close_overlay)
 add_button(p,"QUIT TO HUB",confirm_quit)

func confirm_quit() -> void:
 close_overlay()
 var p:=_modal("ABANDON SHIFT?","Current shift progress will be discarded.")
 add_button(p,"KEEP PLAYING",close_overlay)
 add_button(p,"ABANDON",quit_shift)

func quit_shift() -> void:
 close_overlay()
 show_hub()

func _update_inspection_feedback() -> void:
 if info:
  info.text = "Slice %d%% · Scans %d/4 · Pins %d/4 · Reversals %d" % [int(slice_depth), scan_uses, pins.size(), scan_reversals]
