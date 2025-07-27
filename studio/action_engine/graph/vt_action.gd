extends GraphNode

enum SlotType {
	TRIGGER,
	NUMERIC,
	STRING,
	BOOL
}

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
