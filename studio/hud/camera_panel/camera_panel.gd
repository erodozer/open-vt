extends "res://studio/hud/side_panel.gd"

const Tracker = preload("res://lib/tracking/tracker.gd")
const TrackingSystem = preload("res://lib/tracking/tracking_system.gd")
const Collections = preload("res://lib/utils/collections.gd")

const UI_THEMES: Array[Theme] = [
	preload("res://ui/themes/automata.tres"),
	preload("res://ui/themes/dark.res"),
]

signal update_bg_color(color: Color)

func _get_title():
	return "Settings"

func _ready() -> void:
	var face_trackers = %TrackingSource
	var tracking_system = get_tree().get_first_node_in_group("system:tracking")
	if OS.has_feature("openseeface") or OS.is_debug_build():
		face_trackers.add_item("OpenSeeFace (Webcam)")
		face_trackers.set_item_metadata(face_trackers.item_count - 1, preload("res://lib/tracking/camera/openseeface/osf_tracker.gd"))
	
	face_trackers.add_item("VTubeStudio (WiFi)")
	face_trackers.set_item_metadata(face_trackers.item_count - 1, preload("res://lib/tracking/camera/vts/vts_tracker.gd"))
	
	face_trackers.add_item("iOS BlendShapes (VTS)")
	face_trackers.set_item_metadata(face_trackers.item_count - 1, preload("res://lib/tracking/camera/vts_blendshapes/vts_tracker.gd"))
	
	for tracker in tracking_system.get_children():
		var config = tracker.create_config()
		if config != null:
			%Tracking.add_child(config)
	
	Registry.parameter_list_changed.connect(
		func ():
			for c in %ParameterList.get_children():
				c.free()
			
			for i in Registry.parameters():
				var box = HBoxContainer.new()
				var l = Label.new()
				l.text = i.id
				l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				box.add_child(l)
				var v = Label.new()
				v.name = "Value"
				box.add_child(v)
				box.name = i.id
				%ParameterList.add_child.call_deferred(box)
	)
		
	if tracking_system:
		tracking_system.tracker_changed.connect(_on_tracker_system_tracker_changed)
		tracking_system.parameters_updated.connect(_on_tracker_system_parameters_updated)
		
	# conditionally handle virtual webcam controls based on platform availability
	if OS.has_feature("linux"):
		var v4l2_stream = get_tree().get_first_node_in_group("output:v4l2")
		var feeds = v4l2_stream.get_devices()
		
		for feed in feeds:
			%VirtualCameraDevice.add_item(feed.name)
			%VirtualCameraDevice.set_item_metadata(%VirtualCameraDevice.item_count - 1, feed.id)
		if len(feeds) > 0:
			%VirtualCameraDevice.select(0)
		var vp = get_tree().get_first_node_in_group("system:stage").capture_viewport
	else:
		%VirtualWebcam.queue_free()
	
func _on_tracker_system_tracker_changed(new_tracker: Tracker) -> void:
	var config = Control.new()
	if new_tracker != null:
		config = new_tracker.create_config()
	config.name = "Config"
	
	var prev_config = %FaceTracking.get_node("Config")
	if prev_config:
		%FaceTracking.remove_child(prev_config)
		prev_config.queue_free()
	
	%FaceTracking.add_child(config)

func _on_tracker_system_parameters_updated(parameters: Dictionary, _delta) -> void:
	if !is_node_ready():
		return
	for p in Registry.parameters():
		var node = %ParameterList.get_node(NodePath(p.id))
		if node == null:
			continue
		node.get_node("Value").text = "%.02f" % parameters.get(p.id, 0)

func _on_preview_background_color_color_changed(color: Color) -> void:
	update_bg_color.emit(color)

func load_settings(data: Dictionary):
	_on_background_color_changed(Collections.path(data, "window.background_color", "000000"))
	_on_background_file_selected(Collections.path(data, "window.background_image", ""))
	%BackgroundModeSelector.selected = Collections.path(data, "window.background_mode", 0)
	_on_background_mode_selected(%BackgroundModeSelector.selected)

	%FPS.select(Collections.path(data, "window.fps", 0))
	_on_fps_value_item_selected(%FPS.get_selected_id())
	%UITheme.select(Collections.path(data, "window.theme", 0))
	_on_ui_theme_item_selected(%UITheme.selected)
	
	var tracking_system = get_tree().get_first_node_in_group("system:tracking")
	if tracking_system:
		var source = Collections.path(data, "trackers.source", 0)
		await get_tree().process_frame
		%TrackingSource.select(source)
		tracking_system.activate_tracker(
			%TrackingSource.get_selected_metadata().new()
		)
	
func save_settings(data: Dictionary):
	var w = data.get("window", {})
	w["background_mode"] = %BackgroundModeSelector.selected
	w["background_image"] = %BackgroundImageSelector.get_meta("filepath")
	w["fps"] = %FPS.get_selected_id()
	w["theme"] = %UITheme.selected
	var c = data.get("trackers", {})
	c["source"] = %TrackingSource.get_selected_id()
	data["window"] = w
	data["trackers"] = c
	
func _on_fps_value_item_selected(index: int) -> void:
	match index:
		0: # 60 FPS
			Engine.max_fps = 60
		1: # 30 FPS
			Engine.max_fps = 30
		_: # Uncapped
			Engine.max_fps = 0

func _on_microphone_toggle_toggled(toggled_on: bool) -> void:
	var tracking_system = get_tree().get_first_node_in_group("system:tracking")
	if not tracking_system:
		return	
	tracking_system.get_node("MicrophoneTracker").enabled = toggled_on

func _on_loopback_item_selected(index: int) -> void:
	_on_v4l2_toggled(%V4L2Toggle.button_pressed)

func _on_v4l2_toggled(toggled_on: bool) -> void:
	var v4l2_stream = get_tree().get_first_node_in_group("output:v4l2")
	if toggled_on:
		var index = %VirtualCameraDevice.selected
		if index >= 0:
			var device_id: String = %VirtualCameraDevice.get_item_metadata(index)
			v4l2_stream.loopback_device = device_id
			return
	v4l2_stream.loopback_device = ""

func _on_ui_theme_item_selected(index: int) -> void:
	get_tree().root.propagate_call("set_theme", [UI_THEMES[index]], true)

func _on_background_mode_selected(index: int) -> void:
	%BackgroundImage.visible = index == 1
	%BackgroundColor.visible = index == 2
	
	var stage = get_tree().get_first_node_in_group("system:stage")
	if stage:
		stage.background_mode = index
	
func _on_background_image_selector_pressed() -> void:
	%BackgroundImageSelector/FileDialog.show()

func _on_background_file_selected(path: String) -> void:
	var stage = get_tree().get_first_node_in_group("system:stage")
	if not stage:
		return
	
	stage.background_image = path
	if stage.background_image != path:  # check if file is valid
		return
	%BackgroundImageSelector.text = path.get_file()
	%BackgroundImageSelector.set_meta("filepath", path)

func _on_background_color_changed(color: Color) -> void:
	var stage = get_tree().get_first_node_in_group("system:stage")
	if stage:
		stage.background_color = color

func _on_application_scale_item_selected(index: int) -> void:
	var SCALE_FACTOR = [
		0.5, 1.0, 1.5, 2.0, 3.0, 4.0
	][index]
	ProjectSettings.set_setting("display/window/stretch/scale", SCALE_FACTOR)
	
	get_window().content_scale_factor = SCALE_FACTOR
	get_tree().root.propagate_call(
		"set_content_scale_factor", [SCALE_FACTOR]
	)

func _on_tracking_source_item_selected(index: int) -> void:
	var _tracker = %TrackingSource.get_item_metadata(index)
	var tracking_system = get_tree().get_first_node_in_group("system:tracking")
	tracking_system.activate_tracker(_tracker.new())
