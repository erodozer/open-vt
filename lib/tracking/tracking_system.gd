extends Node

const Tracker = preload("res://lib/tracking/tracker.gd")

var parameters = {}

signal tracker_changed(tracker: Tracker)
signal parameters_updated(parameters: Dictionary, delta: float)

func _ready():
	for i in Registry.parameters():
		parameters[i.id] = i.default_value
	parameters.erase("unset")
	
func activate_tracker(tracker: Tracker):
	if has_node("FaceTracker"):
		var prev = get_node("FaceTracker")
		remove_child(prev)
		prev.queue_free()
	
	if tracker:
		tracker.name = "FaceTracker"
		add_child(tracker)
		move_child(tracker, 0)
	tracker_changed.emit(tracker)
	
	return tracker

func _process(delta: float) -> void:
	parameters.clear()
	
	# mouse tracking
	for i in get_children():
		parameters.merge(i.parameters(), true)
		
	# accumulative adjustments
	parameters.merge(
		{
			"VoiceVolumePlusMouthOpen": Registry.clamp_to_range(parameters.get("MouthOpen", 0) + parameters.get("VoiceVolume", 0), "MouthOpen"),
		}, true
	)
	
	parameters_updated.emit(parameters, delta)
	
