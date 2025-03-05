extends PanelContainer

const Tracker = preload("res://lib/tracking/tracker.gd")
const TrackingSystem = preload("res://lib/tracking_system.gd")
const TrackingInputs = preload("res://lib/tracking/tracker.gd").Inputs

signal toggle_bg_transparency(enabled: bool)
signal update_bg_color(color: Color)

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
		
	%TrackingSource.item_selected.connect(
		func (idx):
			var trackingSystem: TrackingSystem = get_tree().get_first_node_in_group("system:tracking")
			trackingSystem.activate_tracker(idx)
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
	toggle_bg_transparency.emit(toggled_on)
