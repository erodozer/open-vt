extends Control

const OsfTracker = preload("./osf_tracker.gd")

var tracker: OsfTracker

func _ready() -> void:
	tracker.data_received.connect(%PointPreview._on_data_received)
	tracker.connection_status.connect(
		func (status):
			%ActiveIndicator.text = "On" if status == OsfTracker.ConnectionStatus.ON else "Off"
			%ActiveIndicator.modulate = Color.RED if status == OsfTracker.ConnectionStatus.ON else Color.WHITE
			
			%Connect.disabled = status == OsfTracker.ConnectionStatus.ON
			%Disconnect.disabled = status != OsfTracker.ConnectionStatus.ON
	)
	tracker.start()
	
func _process(_delta: float) -> void:
	if tracker != null:
		%FpsCounter.text = "FPS: %d" % tracker.fps

func _on_blink_sync_toggled(toggled_on: bool) -> void:
	tracker.blink_sync = toggled_on

func _on_connect_pressed() -> void:
	tracker.port = %Port.value
	tracker.start()

func _on_disconnect_pressed() -> void:
	tracker.stop()
