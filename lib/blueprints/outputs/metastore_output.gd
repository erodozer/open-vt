extends "../vt_action.gd"

var var_name = ""
var value = 0.0

func get_type() -> StringName:
	return &"store_write"
	
func _exit_tree() -> void:
	update_store()
	
func unbind(slot: int, node: GraphNode) -> void:
	# look for other storage writers and remove variable from model if it is no longer bound
	pass
	
func bind(slot: int, node: GraphNode) -> void:
	pass
	
func rebind():
	pass
	
func get_input_slot_by_port(port: int) -> int:
	if port == 0:
		return 0
	return -1
	
func get_input_port_by_name(slot: StringName) -> int:
	if slot.to_lower() == "value":
		return 0
	return -1

func get_output_slot_by_port(port: int) -> int:
	return -1

func get_output_port_by_name(slot: StringName) -> int:
	return -1

func serialize():
	return {
		"variable": var_name
	}
	
func deserialize(data: Dictionary):
	%Variable.text = data.get("variable", "")
	update_store()
	
func update_value(slot: int, v: Variant) -> void:
	value = v
	model.set("store/%s" % var_name, value)
	
func update_store() -> void:
	var prev = var_name
	var_name = %Variable.text
	
	# look to see what other writers exist that might be producing the same var
	if not is_inside_tree():
		return
	
	var remove_var = true
	for writer in get_tree().get_nodes_in_group("blueprint:store:write"):
		if writer.model != self.model:
			continue
		
		if writer.var_name == prev:
			remove_var = false

	# clear out the variable from storage if there's no more writers
	if remove_var:
		model.set("store/%s" % prev, null)

func _on_variable_editing_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		update_store()
		update_value(0, value)
