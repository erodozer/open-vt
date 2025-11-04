extends GraphNode

const Stage = preload("res://studio/stage/stage.gd")

enum SlotType {
	TRIGGER,
	NUMERIC,
	STRING,
	BOOL
}

var _inputs = []
var _outputs = []

# handy reference to the stage is directly available to all VtActions
@onready var stage: Stage = get_tree().get_first_node_in_group(Stage.GROUP_NAME)

func _notification(what: int) -> void:
	# BUG godot 4.5 broke port indexes by only indexing them when the graph is drawn
	#  We don't always start with the action graph visible, but it is used for
	#  logic execution.  As such, it's better to implement a workaround that depends
	#  on the immediate tree state
	if what == NOTIFICATION_READY:
		for i in range(0, self.get_child_count()):
			if self.is_slot_enabled_left(i):
				_inputs.append(i)
			if self.is_slot_enabled_right(i):
				_outputs.append(i)

func get_type() -> StringName:
	return "UNKNOWN"

func deserialize(data: Dictionary) -> void:
	pass

func serialize() -> Dictionary:
	return {}

func bind(slot: int, node: GraphNode) -> void:
	pass

func unbind(slot: int, node: GraphNode) -> void:
	pass
	
func reset_value(slot: int) -> void:
	pass

func get_output_type(slot: int) -> SlotType:
	return self.get_slot_type_right(_outputs[slot])
	
func get_input_type(slot: int) -> SlotType:
	return self.get_slot_type_left(_inputs[slot])
	
