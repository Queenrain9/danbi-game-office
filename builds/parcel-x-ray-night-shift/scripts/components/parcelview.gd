extends Control
class_name ParcelView

var yaw_pitch := Vector2.ZERO
var last_pin_feedback := Vector2.ZERO
var no_target_pulse := false

func set_pose(pose: Vector2) -> void:
	yaw_pitch = pose
	rotation = deg_to_rad(yaw_pitch.x * 0.08)
	scale = Vector2.ONE * (1.0 - abs(yaw_pitch.y) / 1200.0)
	queue_redraw()

func has_visible_shape_at(local_point: Vector2, slice_depth: float) -> bool:
	var normalized := Vector2(local_point.x / maxf(size.x, 1.0), local_point.y / maxf(size.y, 1.0))
	var inside_primary := normalized.distance_to(Vector2(0.36, 0.42)) <= 0.18
	var inside_secondary := normalized.distance_to(Vector2(0.65, 0.58)) <= 0.14
	var slice_visible := slice_depth >= 5.0 and slice_depth <= 95.0
	return slice_visible and (inside_primary or inside_secondary)

func show_pin_feedback(local_point: Vector2) -> void:
	last_pin_feedback = local_point
	no_target_pulse = false
	queue_redraw()

func show_no_target_pulse() -> void:
	no_target_pulse = true
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.12, 0.16), true)
	draw_circle(size * Vector2(0.36, 0.42), minf(size.x, size.y) * 0.12, Color(0.4, 0.8, 0.95, 0.7))
	draw_circle(size * Vector2(0.65, 0.58), minf(size.x, size.y) * 0.09, Color(0.95, 0.65, 0.35, 0.7))
	if last_pin_feedback != Vector2.ZERO:
		draw_circle(last_pin_feedback, 16.0, Color(1.0, 0.9, 0.25), false, 3.0)
	if no_target_pulse:
		draw_circle(size * 0.5, 24.0, Color(0.6, 0.65, 0.7, 0.45), false, 2.0)
