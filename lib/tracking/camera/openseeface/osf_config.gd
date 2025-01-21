extends VBoxContainer

const OsfTracker = preload("./osf_tracker.gd")

@onready var camera: OptionButton = %Camera
@onready var model: OptionButton = %Model

var tracker: OsfTracker

func _ready() -> void:
	# only do this until Godot supports webcams on desktop
	if OS.has_feature("linux"):
		var lines = []
		OS.execute("v4l2-ctl", ["--list-devices"], lines)
		var idx = 1
		for l in lines[0].split("\n"):
			if "(" in l:
				%Camera.add_item(l, idx)
				idx += 1
	#for i in range(CameraServer.get_feed_count()):
	#	var feed = CameraServer.get_feed(i)
	#	%Camera.add_item(feed.get_name(), feed.get_id())
	%Camera.select(0)
	
	tracker.data_received.connect(%PointPreview._on_data_received)
	tracker.connection_status.connect(
		func (status):
			%ActiveIndicator.text = "On" if status == OsfTracker.ConnectionStatus.ON else "Off"
			%ActiveIndicator.modulate = Color.RED if status == OsfTracker.ConnectionStatus.ON else Color.WHITE
	)
	
func _process(delta: float) -> void:
	if tracker != null:
		%FpsCounter.text = "FPS: %d" % tracker.fps

func _on_blink_sync_toggled(toggled_on: bool) -> void:
	tracker.blink_sync = toggled_on

func _on_connect_pressed() -> void:
	tracker.camera = camera.get_item_id(camera.selected)
	tracker.model = model.get_item_id(model.selected)
	
	tracker.start()

func _on_disconnect_pressed() -> void:
	tracker.stop()
