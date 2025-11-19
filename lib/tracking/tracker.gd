extends Node

var _parameters = {}

func create_config() -> Node:
	return null
	
func reset():
	update({})

func parameters(_time: float = Time.get_ticks_msec()) -> Dictionary:
	return _parameters

func update(updated_parameters: Dictionary):
	_parameters = updated_parameters
