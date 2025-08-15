extends Control

@export var editable: bool :
	get():
		return %MinValue.editable
	set(v):
		%MinValue.editable = v
		%MaxValue.editable = v

@export_range(-999.9, 999.9) var min_value: float :
	get():
		return %MinValue.value

@export_range(-999.9, 999.9) var max_value: float :
	get():
		return %MaxValue.value
	set(v):
		assert(v >= max_value, "can not set max below min")
		%MaxValue.value = v

@export var prefix: String = "" :
	get():
		return %MinValue.suffix
	set(v):
		%MinValue.prefix = v
		%MaxValue.prefix = v

@export var suffix: String = "" :
	get():
		return %MinValue.suffix
	set(v):
		%MinValue.suffix = v
		%MaxValue.suffix = v

var value: Vector2 :
	get():
		return Vector2(
			min_value,
			max_value
		)
	set(v):
		assert(v.x <= v.y, "min must be below max")
		%MaxValue.value = v.y
		%MinValue.value = v.x

func _on_min_value_value_changed(value: float) -> void:
	%MaxValue.min_value = value

func _on_max_value_value_changed(value: float) -> void:
	%MinValue.max_value = value
