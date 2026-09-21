@abstract
class_name VtAction extends GraphNode

const VtModel = preload("res://lib/model/vt_model.gd")
const Serializers = preload("res://lib/utils/serializers.gd")

enum SlotType {
	TRIGGER,
	NUMERIC,
	STRING,
	BOOL,
	VECTOR
}

## only allow more than one binding for certain types
## even for supported types, multiple bindings may result in unexpected behavior due to potentially
## undeterministic order of change emission	
const MultiBindSlotTypes = [
	SlotType.TRIGGER,
	SlotType.NUMERIC
]

var id = ""

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

## For actions that have a variable amount of slots based on user input or graph state.
## This calls the virtual _build_slots function while also handling reconnecting nodes whose port mappings
## may have been affected by shuffling.
func build_slots() -> void:
	var existing_bindings = graph.get_connection_list_from_node(self.name)
	var old_input_mapping: Dictionary[int, String] = {}
	var old_output_mapping: Dictionary[int, String] = {}
	
	# determine existing named bindings based on current port positions
	for e in existing_bindings:
		graph.disconnect_node(e.from_node, e.from_port, e.to_node, e.to_port)
		if e.from_node == self.name:
			var old = get_output_slot_name(get_output_slot_by_port(e.from_port))
			old_output_mapping[e.from_port] = old
		elif e.to_node == self.name:
			var old = get_input_slot_name(get_input_slot_by_port(e.to_port))
			old_input_mapping[e.to_port] = old
	
	# call the virtual function to build the physical slots onto the node
	_build_slots()
	
	# rebind prior connections to new port positions based on name
	for e in existing_bindings:
		if e.from_node == self.name:
			var old: String = old_output_mapping.get(e.from_port, "")
			if old.is_empty():
				continue
			var new_out = get_output_port_by_name(old)
			if new_out >= 0:
				graph.connect_node(e.from_node, new_out, e.to_node, e.to_port)
		elif e.to_node == self.name:
			var old: String = old_input_mapping.get(e.to_port, "")
			if old.is_empty():
				continue
			var new_out = get_input_port_by_name(old)
			if new_out >= 0:
				graph.connect_node(e.from_node, e.from_port, e.to_node, new_out)
	
## virtual function, use to rebuild dynamic slots on a node
func _build_slots() -> void:
	pass

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

## triggers when a slot on this node is connected to by a [VtAction]
func bind(slot: int, node: GraphNode) -> void:
	pass

## triggers when a connection to this slot is severred
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

## replaces godot's built in functions because since 4.5 the internal
## port cache has been broken, only populating when the graph is first visible
## because our graphs exist off-screen, we need to provide a method
## of connecting ports even without the internal cache lookup
@abstract func get_input_slot_by_port(port: int) -> int

@abstract func get_output_slot_by_port(port: int) -> int
	
func get_input_slot_name(slot: int) -> StringName:
	return get_child(slot).name
	
func get_output_slot_name(slot: int) -> StringName:
	return get_child(slot).name

func get_output_type(slot: int):
	return self.get_slot_type_right(slot)
	
func get_input_type(slot: int):
	return self.get_slot_type_left(slot)
