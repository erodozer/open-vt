extends "res://lib/tracking/tracker.gd"

enum ConnectionStatus {
	OFF,
	WAIT,
	ON
}

var kill_msg = PackedByteArray([-1])

var host: String = "*"
var port: int

signal connection_status(status: ConnectionStatus)
signal packet_received(bytes: PackedByteArray)
	
func start():
	pass
	
func stop():
	pass

func _listen():
	pass
	
func _process(_delta: float) -> void:
	_listen()
	
func _exit_tree() -> void:
	stop()
