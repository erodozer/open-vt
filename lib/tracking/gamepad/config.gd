extends PanelContainer

const GamepadTracker = preload("./gamepad_tracker.gd")

@onready var gamepads: OptionButton = %GamepadIndex
@onready var input_rec = %InputRecPopup

var tracker: GamepadTracker

func _ready() -> void:
	var joypads = Input.get_connected_joypads()
	for i in joypads:
		gamepads.add_item(Input.get_joy_name(i), i)
	
	for meta in tracker.keyboard_mapping:
		var label = Label.new()
		label.text = meta.name
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var edit = Button.new()
		edit.text = OS.get_keycode_string(meta.key)
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.focus_mode = Control.FOCUS_NONE
		edit.pressed.connect(
			func ():
				%Modal.show()
				%InputRecPopup.grab_focus()
				
				var pressed: Array = await %InputRecPopup.input_recorded
				
				if len(pressed) > 0:
					var key = pressed[0]
					edit.text = OS.get_keycode_string(key)
					meta.key = key
				%Modal.hide()
		)
		
		%KeytoGamepad.add_child(label)
		%KeytoGamepad.add_child(edit)
	
	_on_gamepad_index_item_selected(gamepads.selected)
	
func _on_gamepad_index_item_selected(index: int) -> void:
	var id = gamepads.get_item_id(index)
	if id == 9999: #kb
		id = -1
	tracker.gamepad_index = id
	%KeytoGamepad.visible = id == -1

func _on_dpad_mapping_toggled(toggled_on: bool) -> void:
	tracker.dpad_to_ls = toggled_on
