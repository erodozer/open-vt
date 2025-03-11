extends Node

const Tracker = preload("res://lib/tracking/tracker.gd")
const Inputs = Tracker.Inputs

enum TrackerType {
	OPENSEEFACE,
	VTUBESTUDIO
}

var parameters = {}

signal tracker_changed(tracker: Tracker)
signal parameters_updated(parameters: Dictionary)

func _ready():
	var mouse_tracker = preload("res://lib/tracking/mouse/mouse_tracker.gd").new()
	mouse_tracker.name = "MouseTracker"
	add_child(mouse_tracker)

	var voice_tracker = preload("res://lib/tracking/microphone/microphone_tracker.tscn").instantiate()
	add_child(voice_tracker)
	
	activate_tracker(TrackerType.OPENSEEFACE)
	
	for i in Tracker.Inputs:
		var ord = Tracker.Inputs[i]
		parameters[ord] = Tracker.Meta.get(ord, {}).get("default", 0)
	parameters.erase(Tracker.Inputs.UNSET)
	
func activate_tracker(id: TrackerType) -> Tracker:
	if has_node("FaceTracker"):
		var prev = get_node("FaceTracker")
		remove_child(prev)
		prev.queue_free()
	
	var tracker
	match id:
		TrackerType.OPENSEEFACE:
			tracker = preload("res://lib/tracking/camera/openseeface/osf_tracker.gd").new()
		TrackerType.VTUBESTUDIO:
			tracker = preload("res://lib/tracking/camera/vts/vts_tracker.gd").new()
		_:
			tracker = null
	
	if tracker:
		tracker.name = "FaceTracker"
		add_child(tracker)
		move_child(tracker, 0)
	tracker_changed.emit(tracker)
	
	return tracker

func _process(_delta: float) -> void:
	# mouse tracking
	for i in get_children():
		parameters.merge(i.parameters, true)
		
	# accumulative adjustments
	parameters.merge(
		{
			Inputs.VOICE_VOLUME_PLUS_MOUTH_OPEN: Tracker.clamp_to_range(parameters.get(Inputs.MOUTH_OPEN, 0) + parameters.get(Inputs.VOICE_VOLUME, 0), Inputs.MOUTH_OPEN),
		}, true
	)
	
	parameters_updated.emit(parameters)
	
