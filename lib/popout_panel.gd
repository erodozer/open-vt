extends Control

@export var title: String = ""

var is_floating: bool = false
var can_close: bool = true
var window: Window

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
	window.title = title
	
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
			
			window.queue_free()
			on_restore.emit()
			is_floating = false
	)
