extends VBoxContainer

const OsfTracker = preload("./osf_tracker.gd")

@onready var camera: OptionButton = %Camera
@onready var model: OptionButton = %Model

var tracker: OsfTracker

func _ready() -> void:
	# only do this until Godot supports webcams on desktop
	if OS.has_feature("linux"):
		CameraServer.set_monitoring_feeds(true)
		await get_tree().process_frame
		var feeds = CameraServer.feeds()
		for i in feeds:
			%Camera.add_item(i.get_name(), i.get_id())
		if len(feeds) > 0:
			%Camera.select(0)
	#elif OS.has_feature("windows"):
	#	var lines = []
	#	OS.execute("powershell", ["""Get-CimInstance Win32_PnPEntity | ? { $_.service -eq "usbvideo" } | Select-Object -Property PNPDeviceID, Name"""], lines)
	#	var idx = 1
	#	for l in lines[0].split("\r\n"):
	#		pass
	
	tracker.data_received.connect(%PointPreview._on_data_received)
	tracker.connection_status.connect(
		func (status):
			%ActiveIndicator.text = "On" if status == OsfTracker.ConnectionStatus.ON else "Off"
			%ActiveIndicator.modulate = Color.RED if status == OsfTracker.ConnectionStatus.ON else Color.WHITE
			
			%Connect.disabled = status == OsfTracker.ConnectionStatus.ON
			%Disconnect.disabled = status != OsfTracker.ConnectionStatus.ON
			%Camera.disabled = status == OsfTracker.ConnectionStatus.ON
			%Model.disabled = status == OsfTracker.ConnectionStatus.ON
	)
	tracker.start()
	
func _process(_delta: float) -> void:
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
