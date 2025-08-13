extends "../vt_action.gd"

const VALUE_SLOT = 1

@export var curve: Curve

var input: float = 0.0

func _draw() -> void:
	var resolution: float = 64.0
	var x = 0
	var step_size: float = %Operator.size.x / resolution
	var pos = (get_global_transform().affine_inverse() * %Operator.global_position) + Vector2(0, %Operator.size.y)
	for i in range(1, resolution):
		var j = i - 1
		var y1 = curve.sample_baked(float(j) / resolution) * %Operator.size.y
		var y2 = curve.sample_baked(float(i) / resolution) * %Operator.size.y
		
		draw_line(
			pos + Vector2(x, -y1), pos + Vector2(x + step_size, -y2), %Operator.self_modulate, 2.0, true
		)
		
		x += step_size

func update_value(slot, value):
	input = value
	
	slot_updated.emit(0)
	
func get_value(_slot):
	return lerp(
		%Range.min_value,
		%Range.max_value,
		curve.sample_baked(
			inverse_lerp(%Range.min_value, %Range.max_value, input)
		)
	)

func _on_smoothing_value_changed(value: float) -> void:
	curve.set_point_right_tangent(0, 1.0 - value)
	curve.set_point_left_tangent(1, 1.0 - value)
	queue_redraw()
