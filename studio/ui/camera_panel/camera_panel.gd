extends "res://lib/popout_panel.gd"

const Tracker = preload("res://lib/tracking/tracker.gd")
const TrackingSystem = preload("res://lib/tracking_system.gd")
const TrackingInputs = preload("res://lib/tracking/tracker.gd").Inputs

signal update_bg_color(color: Color)

@onready var transparency_toggle: CheckButton = %TransparencyToggle

func _get_title():
	return "Settings"

func _ready() -> void:
	for i in TrackingInputs:
		var box = HBoxContainer.new()
		var l = Label.new()
		l.text = i
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(l)
		var v = Label.new()
		v.name = "Value"
		box.add_child(v)
		%ParameterList.add_child(box)
		
	var tracking_system: TrackingSystem = get_tree().get_first_node_in_group("system:tracking")
	if tracking_system:
		tracking_system.tracker_changed.connect(_on_tracker_system_tracker_changed)
			
		%TrackingSource.item_selected.connect(
			func (idx):
				tracking_system.activate_tracker(idx)
		)
	
func _on_tracker_system_tracker_changed(tracker: Tracker) -> void:
	var config = Control.new()
	if tracker != null:
		config = tracker.create_config()
	config.name = "Config"
	
	%Tracking/Config.queue_free()
	await get_tree().process_frame
	%Tracking.add_child(config)

func _on_tracker_system_parameters_updated(parameters: Dictionary) -> void:
	if !is_node_ready():
		return
	for i in TrackingInputs:
		%ParameterList.get_child(TrackingInputs[i]).get_node("Value").text = "%.02f" % parameters.get(TrackingInputs[i], 0)

func _on_preview_background_color_color_changed(color: Color) -> void:
	update_bg_color.emit(color)

func _on_transparency_toggle_toggled(toggled_on: bool) -> void:
	get_tree().get_first_node_in_group("system:stage").toggle_bg(toggled_on)

func load_settings(data: Dictionary):
	transparency_toggle.button_pressed = data.get("window", {}).get("transparent", false)
	
func save_settings(data: Dictionary):
	var w = data.get("window", {})
	w["transparent"] = transparency_toggle.button_pressed
	data["window"] = w
