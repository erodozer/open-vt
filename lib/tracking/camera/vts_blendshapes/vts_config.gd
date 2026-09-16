extends Control

const SocketTracker = preload("res://lib/tracking/net/socket_tracker.gd")
const Collections = preload("res://lib/utils/collections.gd")
const VtsTracker = preload("./vts_tracker.gd")

var tracker: VtsTracker
var server: SocketTracker

func _ready() -> void:
	server.connection_status.connect(
		func (status):
			match status:
				SocketTracker.ConnectionStatus.OFF:
					%ActiveIndicator.text = "Off"
					%ActiveIndicator.modulate = Color.RED
				SocketTracker.ConnectionStatus.ON:
					%ActiveIndicator.text = "On"
					%ActiveIndicator.modulate = Color.WHITE
				SocketTracker.ConnectionStatus.WAIT:
					%ActiveIndicator.text = "Waiting..."
					%ActiveIndicator.modulate = Color.WHITE
	)
	%Connect.pressed.connect(_on_connect_pressed)
	%Disconnect.pressed.connect(_on_disconnect_pressed)
	
func _on_connect_pressed() -> void:
	server.client_host = %Hostname.text
	server.start()
	
func _on_disconnect_pressed() -> void:
	server.stop()

func save_settings(settings: Dictionary):
	var trackers = settings.get("trackers", {})
	var config = trackers.get("vts_blendshapes", {})
	config["client_host"] = %Hostname.text
	
	trackers["vts_blendshapes"] = config
	settings["trackers"] = trackers

func load_settings(settings: Dictionary):
	%Hostname.text = Collections.path(settings, "trackers.vts_blendshapes.client_host", "0.0.0.0")
