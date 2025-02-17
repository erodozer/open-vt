extends Control

signal pressed(idx: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for btn in %Buttons.get_children():
		btn.pressed.connect(
			pressed.emit.bind(btn.get_index())
		)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT and Input.is_key_pressed(KEY_SHIFT):
			if not (self.get_parent() is Window):
				popout()

func popout() -> void:
	var parent = self.get_parent()
	var index = self.get_index()
	var position = self.position
	var window = Window.new()
	window.size = self.size
	window.unresizable = true
	window.transient = true
	window.title = "Action Controller"
	parent.add_child(window)
	self.reparent(window, false)
	self.position = Vector2i.ZERO
	
	window.close_requested.connect(
		func ():
			self.reparent(parent)
			parent.move_child(self, index)
			self.position = position
			window.queue_free()
	)
