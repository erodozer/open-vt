extends PanelContainer

const PhysicsValueProvider = preload("res://lib/model/formats/l2d/physics_value_provider.gd")

var provider: PhysicsValueProvider :
	set(p):
		provider = p
		%GroupName.text = p.group
		%Strength.set_value_no_signal(p.weight)

func _on_strength_value_changed(value: float) -> void:
	provider.weight = value
