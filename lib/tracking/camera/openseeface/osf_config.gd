extends Control

const SocketTracker = preload("res://lib/tracking/net/socket_tracker.gd")

var tracker

func _ready() -> void:
	tracker.data_received.connect(%PointPreview._on_data_received)
	tracker.server.connection_status.connect(
		func (status):
			%ActiveIndicator.text = "On" if status == SocketTracker.ConnectionStatus.ON else "Off"
			%ActiveIndicator.modulate = Color.RED if status == SocketTracker.ConnectionStatus.ON else Color.WHITE
			
			%Connect.disabled = status == SocketTracker.ConnectionStatus.ON
			%Disconnect.disabled = status != SocketTracker.ConnectionStatus.ON
	)
	
func _process(_delta: float) -> void:
	if tracker != null:
		%FpsCounter.text = "FPS: %d" % tracker.fps

func _on_blink_sync_toggled(toggled_on: bool) -> void:
	tracker.blink_sync = toggled_on

func _on_connect_pressed() -> void:
	tracker.server.port = %Port.value
	tracker.server.start()

func _on_disconnect_pressed() -> void:
	tracker.server.stop()
