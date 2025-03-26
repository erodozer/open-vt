extends "./socket_tracker.gd"

var server: UDPServer
var peer: PacketPeerUDP

func start():
	if server != null and server.is_listening():
		return false
	
	server = UDPServer.new()
	var err = server.listen(port, self.host)
	if err != OK:
		push_error("could not open udp server")
		return false
	connection_status.emit(ConnectionStatus.WAIT)
	return true
	
func stop():
	if server == null or not server.is_listening():
		return
	
	# quickly issue a kill message to the listener socket
	server.stop()
	
	connection_status.emit(ConnectionStatus.OFF)
	
	server = null

func _listen():
	if server == null:
		return
		
	if server != null and not server.is_listening():
		server = null
		return
		
	server.poll()
	if server.is_connection_available() and peer == null:
		peer = server.take_connection()
		connection_status.emit(ConnectionStatus.ON)
	
	if peer == null:
		return
	
	if peer.get_available_packet_count() < 0:
		return
	
	var data: PackedByteArray = peer.get_packet()
			
	if data.size() <= 0:
		return
		
	_packet_received(data)
	
