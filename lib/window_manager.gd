## state container for managing popup windows
extends Node

var windows = {}

func get_popup(key: StringName, initializer: Callable):
	if key in windows:
		return windows[key]
		
	var window: Window = initializer.call()
	window.name = key
	windows[key] = window
	get_tree().root.add_child(window)
	window.tree_exiting.connect(close_popup.bind(key))
	return window
	
func close_popup(key: StringName):
	var window = windows.get(key)
	if window:
		window.queue_free()
	windows.erase(key)
	
