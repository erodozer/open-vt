extends PanelContainer

const VtsTracker = preload("./vts_tracker.gd")

var tracker: VtsTracker

func _ready() -> void:
	print(IP.get_local_addresses())
	%Hostname.text = Array(IP.get_local_addresses()).filter(
		func (ip):
			return ip.begins_with("192")
	)[0]
	tracker.connection_status.connect(
		func (status):
			match status:
				VtsTracker.ConnectionStatus.OFF:
					%ActiveIndicator.text = "Off"
					%ActiveIndicator.modulate = Color.RED
				VtsTracker.ConnectionStatus.ON:
					%ActiveIndicator.text = "On"
					%ActiveIndicator.modulate = Color.WHITE
				VtsTracker.ConnectionStatus.WAIT:
					%ActiveIndicator.text = "Waiting..."
					%ActiveIndicator.modulate = Color.WHITE
	)
	
func _on_connect_pressed() -> void:
	tracker.host = %Hostname.text
	tracker.port = %Port.value
	tracker.start()
	
func _on_disconnect_pressed() -> void:
	tracker.stop()
