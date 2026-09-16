extends Node

const Collections = preload("res://lib/utils/collections.gd")

var tracker

func _on_enabled_toggled(toggled_on: bool) -> void:
	tracker.enabled = toggled_on

func save_settings(settings: Dictionary):
	var trackers = settings.get("trackers", {})
	var config = trackers.get("microphone", {})
	config["enabled"] = %Enabled.button_pressed
	
	trackers["microphone"] = config
	settings["trackers"] = trackers

func load_settings(settings: Dictionary):
	var enabled: bool = Collections.path(settings, "trackers.microphone.enabled", false)
	%Enabled.button_pressed = enabled
