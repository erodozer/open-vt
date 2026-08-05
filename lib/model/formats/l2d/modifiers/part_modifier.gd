extends "res://lib/model/modifier.gd"

var model
var part: StringName

@export_range(0.0, 1.0) var opacity: float = 1.0 :
	set(v):
		model.set("parts/%s" % part, v)

func _init(m, p) -> void:
	self.model = m
	self.part = p
