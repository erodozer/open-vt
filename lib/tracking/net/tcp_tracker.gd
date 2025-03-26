extends "./socket_tracker.gd"

var server: TCPServer
var peer: StreamPeerTCP

func start():
	if server != null and server.is_listening():
		return
	
	server = TCPServer.new()
	var err = server.listen(port, host)
	if err != OK:
		return
	
	connection_status.emit(ConnectionStatus.WAIT)
	
func stop():
	if server != null and server.is_listening():
		server.stop()
	server = null
	call_deferred_thread_group("emit_signal", "connection_status", ConnectionStatus.OFF)

func _listen():
	if server == null:
		return
		
	if not server.is_listening():
		return
	
	if server.is_connection_available() and peer == null:
		peer = server.take_connection()
		connection_status.emit(ConnectionStatus.ON)
	
	if peer == null:
		return
		
	peer.poll()
	var is_alive = peer.get_status()
	if is_alive == StreamPeerTCP.Status.STATUS_NONE:
		peer = null
		return
	
	if peer.get_available_bytes() <= 0:
		return
		
	var packet = peer.get_data(peer.get_available_bytes())
	var err = packet[0]
	var data = packet[1]
	if err != OK:
		return
	
	_packet_received(data)
