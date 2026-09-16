extends Node

const Collections = preload("res://lib/utils/collections.gd")

var tracker

func _ready():
	var devices = AudioServer.get_input_device_list()
	for d in devices:
		%DeviceList.add_item(d)

func _on_enabled_toggled(toggled_on: bool) -> void:
	tracker.enabled = toggled_on

func _on_device_list_item_selected(index: int) -> void:
	tracker.device = %DeviceList.get_item_text(index)

func save_settings(settings: Dictionary):
	var trackers = settings.get("trackers", {})
	var config = trackers.get("microphone", {})
	config["enabled"] = %Enabled.button_pressed
	config["device"] = %DeviceList.get_item_text(%DeviceList.selected)
	
	trackers["microphone"] = config
	settings["trackers"] = trackers

func load_settings(settings: Dictionary):
	var enabled: bool = Collections.path(settings, "trackers.microphone.enabled", false)
	%Enabled.button_pressed = enabled
	
	await get_tree().process_frame
	var device: String = Collections.path(settings, "trackers.microphone.device", "Default")
	for i in %DeviceList.item_count:
		if %DeviceList.get_item_text(i) == device:
			%DeviceList.select(i)
			break
	
