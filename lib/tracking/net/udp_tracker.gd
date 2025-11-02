extends "./socket_tracker.gd"

var server: PacketPeerUDP

func start():
	if server != null and server.is_bound():
		return true
	
	stop() # do cleanup just in case
	
	server = PacketPeerUDP.new()
	var err = server.bind(port, host)
	if err != OK:
		push_error("could not open udp server")
		return false
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
		
	if server.get_available_packet_count() < 0:
		return
	
	var data: PackedByteArray = server.get_packet()
			
	if data.size() <= 0:
		return
	
	# state is switched to ON as soon as first packet is received
	connection_status.emit(ConnectionStatus.ON)
	
	packet_received.emit(data)
	
