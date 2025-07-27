extends "res://lib/tracking/tracker.gd"

const RingBuffer = preload("res://lib/utils/ring_buffer.gd")

enum ConnectionStatus {
	OFF,
	WAIT,
	ON
}

var kill_msg = PackedByteArray([-1])

var host: String = "*"
var port: int

var fps: int = 1
var fps_sample: RingBuffer
var last_update: float = Time.get_ticks_msec()

var curr_data
var prev_data

signal connection_status(status: ConnectionStatus)
signal data_received(data)

func _ready():
	fps_sample = RingBuffer.new(10)
	fps_sample.values().fill(1)
	
func start():
	pass
	
func stop():
	pass

func _listen():
	pass
	
func _process(delta: float) -> void:
	_listen()
	
	if prev_data == null or curr_data == null:
		return
	
	_update(delta)
	
func _update(_delta: float) -> void:
	pass
	
func _packet_received(_data: PackedByteArray):
	pass
	
func _update_data(data):
	prev_data = curr_data
	curr_data = data

	var now = Time.get_ticks_msec()
	# estimate avg sample rate
	var delta = 1.0 / ((now - last_update) / 1000.0)
	fps_sample.push(delta)
	fps = 0
	for i in fps_sample.values():
		fps = (fps + i) / 2
	
	last_update = now
	
	data_received.emit(curr_data)
	
func _exit_tree() -> void:
	stop()
