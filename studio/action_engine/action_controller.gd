extends Window

signal pressed(idx: int)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for btn in %Buttons.get_children():
		btn.pressed.connect(
			pressed.emit.bind(btn.get_index())
		)
