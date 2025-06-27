extends "res://lib/popout_panel.gd"

const Tracker = preload("res://lib/tracking/tracker.gd")
const TrackingSystem = preload("res://lib/tracking/tracking_system.gd")
const TrackingInputs = preload("res://lib/tracking/tracker.gd").Inputs

signal update_bg_color(color: Color)

@onready var tracking_system: TrackingSystem = get_tree().get_first_node_in_group("system:tracking")
@onready var transparency_toggle: CheckButton = %TransparencyToggle
@onready var mic_toggle: CheckButton = %MicrophoneToggle
@onready var tracker: OptionButton = %TrackingSource
@onready var fps_option: OptionButton = %FPS

func _get_title():
	return "Settings"

func _ready() -> void:
	if OS.has_feature("openseeface") or OS.is_debug_build():
		tracker.add_item("OpenSeeFace (Webcam)")
		tracker.set_item_metadata(tracker.item_count - 1, preload("res://lib/tracking/camera/openseeface/osf_tracker.gd"))
	
	tracker.add_item("VTubeStudio (iOS/Android)")
	tracker.set_item_metadata(tracker.item_count - 1, preload("res://lib/tracking/camera/vts/vts_tracker.gd"))
	
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
		
	if tracking_system:
		tracking_system.tracker_changed.connect(_on_tracker_system_tracker_changed)
		tracking_system.parameters_updated.connect(_on_tracker_system_parameters_updated)
		tracker.item_selected.connect(
			func (idx):
				var tracker = tracker.get_item_metadata(idx)
				tracking_system.activate_tracker(tracker.new())
		)
		
	if OS.has_feature("linux"):
		#CameraServer.set_monitoring_feeds(true)
		await get_tree().process_frame
		var feeds = CameraServer.feeds()
		for i in feeds:
			var id = i.get_id()
			var name = i.get_name()
			%VirtualWebcam/Value.add_item(i.get_name(), i.get_id() + 1)
		if len(feeds) > 0:
			%VirtualWebcam/Value.select(0)
		var vp = get_tree().get_first_node_in_group("system:stage").capture_viewport
		%VirtualWebcam/V4l2OutputStream.viewport = vp
	else:
		%VirtualWebcam.queue_free()
	
func _on_tracker_system_tracker_changed(new_tracker: Tracker) -> void:
	var config = Control.new()
	if new_tracker != null:
		config = new_tracker.create_config()
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
	tracker.select(data.get("camera", {}).get("tracking", 0))
	fps_option.select(data.get("window", {}).get("fps", 0))
	_on_fps_value_item_selected(fps_option.get_selected_id())
	if tracking_system:
		tracking_system.activate_tracker(
			tracker.get_selected_metadata().new()
		)
		mic_toggle.button_pressed = data.get("microphone", true)
	
func save_settings(data: Dictionary):
	var w = data.get("window", {})
	w["transparent"] = transparency_toggle.button_pressed
	w["fps"] = fps_option.get_selected_id()
	var c = data.get("camera", {})
	c["tracking"] = tracker.get_selected_id()
	data["window"] = w
	data["camera"] = c
	data["microphone"] = mic_toggle.button_pressed

func _on_fps_value_item_selected(index: int) -> void:
	match index:
		0: # 60 FPS
			Engine.max_fps = 60
		1: # 30 FPS
			Engine.max_fps = 30
		_: # Uncapped
			Engine.max_fps = 0

func _on_microphone_toggle_toggled(toggled_on: bool) -> void:
	if not tracking_system:
		return
	tracking_system.voice_tracker.enabled = toggled_on


func _on_loopback_item_selected(index: int) -> void:
	var device_id = %VirtualWebcam/Value.get_item_id(index)
	print("selected /dev/video%d" % device_id)
	%VirtualWebcam/V4l2OutputStream.set_loopback_device("/dev/video%d" % [device_id])
