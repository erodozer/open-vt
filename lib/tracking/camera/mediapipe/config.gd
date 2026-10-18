extends Control

const Collections = preload("res://lib/utils/collections.gd")
const Tracker = preload("./tracker.gd")

var tracker: Tracker

func _ready() -> void:
	CameraServer.camera_feed_added.connect(_refresh_camera_list)
	CameraServer.camera_feed_removed.connect(_refresh_camera_list)
	%Webcam.item_selected.connect(_refresh_camera_format)
	%Connect.pressed.connect(
		func ():
			var id = %Webcam.get_item_id(%Webcam.selected)
			var fmt = %WebcamFormat.get_item_id(%WebcamFormat.selected)
			var feed = CameraServer.feeds()[id]
			feed.set_format(fmt, {"output": "copy"})
			tracker.feed = feed
			tracker.start()
			
			%Webcam.disabled = true
			%WebcamFormat.disabled = true
	)
	%Disconnect.pressed.connect(
		func ():
			var id = %Webcam.get_item_id(%Webcam.selected)
			var feed = CameraServer.feeds()[id]
			tracker.stop()
			%Webcam.disabled = false
			%WebcamFormat.disabled = false
	)
	_refresh_camera_list()
	
func _refresh_camera_list():
	%Webcam.clear()
	for idx in range(len(CameraServer.feeds())):
		var feed = CameraServer.feeds()[idx]
		var has_rgb = false
		for fmt in feed.formats:
			if "jpeg" in fmt.format.to_lower():
				has_rgb = true
				break
		
		if not has_rgb:
			continue
			
		%Webcam.add_item(feed.get_name(), idx)
		
	%Webcam.selected = 0
	_refresh_camera_format(0)

func _refresh_camera_format(feed_idx):
	var id = %Webcam.get_item_id(feed_idx)
	var feed = CameraServer.feeds()[id]
	%WebcamFormat.clear()
	for i in range(len(feed.formats)):
		var fmt = feed.formats[i]
		if "jpeg" in fmt.format.to_lower():
			%WebcamFormat.add_item(
				"%dx%d %s (%d FPS)" % [fmt.width, fmt.height, fmt.format, fmt.frame_denominator],
				i
			)

func save_settings(settings: Dictionary):
	var trackers = settings.get("trackers", {})
	var config = trackers.get("mediapipe", {})
	# config["camera"] = %Webcam.get_item_text(%Webcam.selected)
	# config["format"] = %WebcamFormat.get_item_id(%WebcamFormat.selected)
	
	trackers["mediapipe"] = config
	settings["trackers"] = trackers

func load_settings(settings: Dictionary):
	pass
	
	#var camera = Collections.path(settings, "trackers.mediapipe.camera", "")
	#if camera:
		#for i in %Webcam.item_count:
			#if %Webcam.get_item_text(i).to_lower() == camera.to_lower():
				#%Webcam.selected = i
				#break

func _process(delta: float) -> void:
	if visible:
		%ActiveIndicator.text = "On" if tracker.camera.camera_is_active else "Off"
		%FpsCounter.text = "FPS: %d" % [tracker.fps]
