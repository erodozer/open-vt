extends Control

@export var title: String = ""

var is_floating: bool = false
var can_close: bool = true
var window: Window
var popup_position: Vector2

signal on_popout_requested
signal on_popout
signal on_restore_requested
signal on_restore

func restore() -> void:
	can_close = true # force enable closing
	window.close_requested.emit()
	
func popout(persistent: bool = false) -> void:
	if is_floating:
		return
	
	can_close = not persistent
	on_popout_requested.emit()
	
	var position = self.position
	
	var parent = self.get_parent()
	var index = self.get_index()
	window = Window.new()
	window.size = self.size
	window.unresizable = true
	window.transient = true
	window.transparent = true
	window.title = title
	window.initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE
	window.position = popup_position
	
	get_tree().root.add_child(window)
	
	self.reparent(window, false)
	self.position = Vector2i.ZERO
	
	is_floating = true
	
	on_popout.emit()
	
	window.close_requested.connect(
		func ():
			if not can_close:
				return
			on_restore_requested.emit()
			self.reparent(parent)
			parent.move_child(self, index)
			
			self.set_position(position, false)
			popup_position = window.position
			
			window.queue_free()
			on_restore.emit()
			is_floating = false
	)

func load_settings(settings: Dictionary):
	var windows: Dictionary = settings.get("window_positions", {})
	var self_pos: Vector2 = windows.get(self.name, Vector2.ZERO)
	
	popup_position = self_pos
	
func save_settings(settings: Dictionary):
	if window != null:
		popup_position = window.position
		
	var windows: Dictionary = settings.get("window_positions", {})
	windows[self.name] = popup_position
	
	settings["window_positions"] = windows
	
