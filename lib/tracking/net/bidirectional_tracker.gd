## Extended UDP Tracker type w/ a polling action for performing keep-alive/handshakes
extends "./udp_tracker.gd"

var client_host: String
var client_port: int

var _poller: Timer
var handshake_frequency: float = 1 # attempts per second to request a handshake

signal try_handshake(peer: PacketPeerUDP)

func start():
	if not super.start():
		return false
	
	var err = server.set_dest_address(client_host, client_port)
	if err != OK:
		push_error("could not connect to vts server at ", client_host, client_port)
		stop()
		return false
		
	_poller = Timer.new()
	_poller.timeout.connect(
		func ():
			if server == null:
				return
			if not server.is_bound():
				push_warning("client is closed")
				stop()
				return
			try_handshake.emit(server)
	)
	add_child(_poller)
	
	_poller.start()
		
	return true

func stop():
	super.stop()
	if _poller != null:
		_poller.stop()
		remove_child(_poller)
		_poller = null
	
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
		
	connection_status.emit(ConnectionStatus.ON)
	
	packet_received.emit(data)
	
