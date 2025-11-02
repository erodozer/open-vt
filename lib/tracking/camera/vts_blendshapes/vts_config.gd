extends PanelContainer

const SocketTracker = preload("res://lib/tracking/net/socket_tracker.gd")

var tracker: SocketTracker

func _ready() -> void:
	%Hostname.text = "192.168.88.250"
	tracker.connection_status.connect(
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
	
func _on_connect_pressed() -> void:
	tracker.host = Array(IP.get_local_addresses()).filter(
		func (ip):
			return ip.begins_with("192")
	)[0]
	tracker.client_host = %Hostname.text
	tracker.start()
	
func _on_disconnect_pressed() -> void:
	tracker.stop()
