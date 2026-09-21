extends VtAction

var button_group: ButtonGroup

func _init() -> void:
	button_group = ButtonGroup.new()
	button_group.allow_unpress = true
	button_group.pressed.connect(
		func (button):
			var slot = 0
			if button != null:
				slot = button.get_parent().get_index() - 1
			slot_updated.emit(slot)
	)

func _ready() -> void:
	%InactiveInput.button_group = button_group
	%SlotCount.value_changed.connect(
		func (_value):
			build_slots()
	)

func _build_slots() -> void:
	var count = %SlotCount.value
	var total = get_child_count()
	var current_count = total - 2 # remove hard coded slots from count
	
	if count < current_count:
		for i in range(count + 2, total):
			var slot = get_child(i)
			if button_group.get_pressed_button() == slot.get_node("CheckBox"):
				button_group.reset_state()
			remove_child(slot)
			slot.queue_free()
	elif count > current_count:
		for i in range(current_count, count):
			var slot = HBoxContainer.new()
			slot.name = "%d" % [i + 1]
			add_child(slot)
			
			var label = Label.new()
			label.text = "%d" % [i + 1]
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			slot.add_child(label)
			
			var check = CheckBox.new()
			check.button_group = button_group
			slot.add_child(check, true)
			set_slot_enabled_left(i + 2, true)
			set_slot_enabled_right(i + 2, true)
	size.y = 0

func get_input_slot_by_port(port: int) -> int:
	if port >= 0:
		return port
	return -1

func get_input_port_by_name(slot: StringName) -> int:
	return type_convert(String(slot), TYPE_INT)

func get_output_slot_by_port(port: int) -> int:
	if port >= 0:
		return port
	return -1

func get_output_port_by_name(slot: StringName) -> int:
	if slot == "inactive":
		return 0
	return type_convert(String(slot), TYPE_INT)

func get_type() -> StringName:
	return &"toggle_group"
	
func serialize():
	return {
		"slots": %SlotCount.value
	}

func deserialize(data):
	var slots_count = data.get("slots", 1)
	%SlotCount.set_value_no_signal(slots_count)

func get_value(slot):
	return button_group.get_pressed_button().get_parent().get_index() == slot
	
func invoke_trigger(slot: int):
	var button = get_child(slot + 1).get_node("CheckBox")
	if button == null:
		return
	
	if button.button_pressed:
		%InactiveInput.button_pressed = true
	else:
		button.button_pressed = true
	
func get_input_slot_name(slot: int) -> StringName:
	return "%d" % slot

func get_output_slot_name(slot: int) -> StringName:
	return "%d" % slot
