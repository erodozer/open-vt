extends "./socket_tracker.gd"

var server: PacketPeerUDP

# state is switched to ON as soon as first packet is received
var emit_connect = RatelimitedCallable.oneshot(
	connection_status.emit.bind(ConnectionStatus.ON)
)
# limit how many packats are sent throughout the system
# when there is backpressure
var packet_sender = DebounceCallable.new(
	packet_received.emit
)

func start():
	if server != null and server.is_bound():
		return true
	
	stop() # do cleanup just in case
	
	server = PacketPeerUDP.new()
	var err = server.bind(port, host)
	if err != OK:
		push_error("could not open udp server")
		return false
	emit_connect.reset()
	connection_status.emit(ConnectionStatus.WAIT)
	return true
	
func stop():
	if server == null:
		return
	
	# quickly issue a kill message to the listener socket
	server.close()
	
	connection_status.emit(ConnectionStatus.OFF)
	
	server = null

func _listen():
	if server == null:
		return
		
	if not server.is_bound():
		stop()
		return
	
	while server.get_available_packet_count() > 0:
		var data: PackedByteArray = server.get_packet()
				
		if data.size() <= 0:
			continue
	
		emit_connect.exec()
		packet_sender.exec(data)
	packet_sender.trigger() # reset debounce per frame
	
