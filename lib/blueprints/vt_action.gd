@abstract
class_name VtAction extends GraphNode

const VtModel = preload("res://lib/model/vt_model.gd")

enum SlotType {
	TRIGGER,
	NUMERIC,
	STRING,
	BOOL,
	VECTOR
}

## reference to the bound model is directly available to all VtActions
var model: VtModel:
	set = set_model

func set_model(m: VtModel):
	model = m

## quick name access to the graph this action belongs to
@onready var graph: GraphEdit = get_parent()

# port mappings
# Slot index != Port Index, slots are the children while ports are enabled children
var _slot_to_input: Dictionary[StringName, int] = {}
var _slot_to_output: Dictionary[StringName, int] = {}

@abstract func get_type() -> StringName

func update_value(slot: int, value: Variant) -> void:
	pass

func get_value(slot: int) -> Variant:
	return null
	
func invoke_trigger(slot: int):
	pass
	
## Checks a graph and returns if the action can be spawned.  
## Typically this is used to control if only a single instance of the Action
## should exist in a Blueprint
func can_spawn(graph: GraphEdit) -> bool:
	return true

@abstract func deserialize(data: Dictionary) -> void

@abstract func serialize() -> Dictionary

func bind(slot: int, node: GraphNode) -> void:
	pass

func unbind(slot: int, node: GraphNode) -> void:
	pass
	
func reset_value(slot: int) -> void:
	pass

func get_slot_by_name(slot: StringName) -> int:
	return get_children().find_custom(
		func (f):
			return f.name.to_lower() == slot.to_lower()
	)

@abstract func get_input_port_by_name(slot: StringName) -> int

@abstract func get_output_port_by_name(slot: StringName) -> int

# replaces godot's built in functions because since 4.5 the internal
# port cache has been broken, only populating when the graph is first visible
# because our graphs exist off-screen, we need to provide a method
# of connecting ports even without the internal cache lookup
@abstract func get_input_slot_by_port(port: int) -> int

@abstract func get_output_slot_by_port(port: int) -> int
	
func get_slot_name(slot: int) -> StringName:
	return get_child(slot).name

func get_output_type(slot: int):
	return self.get_slot_type_right(slot)
	
func get_input_type(slot: int):
	return self.get_slot_type_left(slot)
