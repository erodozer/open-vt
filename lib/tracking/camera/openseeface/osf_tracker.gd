extends "res://lib/tracking/net/udp_tracker.gd"

const utils = preload("res://lib/utils.gd")
const OpenSeeData = preload("./osf_data.gd")

const OSF_PORT = 11573

var osf_pid: int
var camera: int
var model: int

# controls
var blink_sync: bool = false

func _ready():
	super._ready()
	port = OSF_PORT
	
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if osf_pid > 0:
			OS.kill(osf_pid)

func create_config() -> Node:
	var panel = preload("./osf_config.tscn").instantiate()
	panel.tracker = self
	return panel

func start():
	if osf_pid > 0:
		return
	
	var opened = super.start()
	if not opened:
		return
	
	var executable
	if OS.has_feature("linux"):
		executable = ProjectSettings.globalize_path("res://bin/openseeface/facetracker")
	elif OS.has_feature("windows"):
		executable = ProjectSettings.globalize_path("res://bin/openseeface/facetracker.exe")
		camera = 1
	else:
		push_error("OpenSeeFace is unsupported on this platform")
		return
	osf_pid = OS.create_process(
		executable,
		["-s", "1", "-c", camera, "-m", model]
	)
	print("openseeface process: %d" % osf_pid)

func stop():
	if osf_pid > 0:
		print("closing openseeface process: %d" % osf_pid)
		OS.kill(osf_pid)
		osf_pid = -1
		
	super.stop()
	
func _packet_received(data: PackedByteArray):
	var osf_data = OpenSeeData.new()
	osf_data.read_osf_data(data)
	
	_update_data(osf_data)

func _update(_delta: float) -> void:
	# blend ranges based on sample rate
	var progress = clamp(inverse_lerp(last_update, last_update + (1000.0 / fps), Time.get_ticks_msec()), 0.0, 1.0)
	
	# dereference so that the socket thread can safely replace them
	var a = prev_data
	var b = curr_data
	
	if a == null or b == null:
		return
		
	# compute additional landmarks
	
	var eyeLeft = lerp(a.eyeLeftXY, b.eyeLeftXY, progress)
	var eyeRight = lerp(a.eyeRightXY, b.eyeRightXY, progress)
	
	# sync blinking (disables winking)
	var leftOpen = lerp(a.leftEyeOpen, b.leftEyeOpen, progress)
	var rightOpen = lerp(a.rightEyeOpen, b.rightEyeOpen, progress)
	if blink_sync:
		leftOpen = rightOpen
		
	var mapping = {
		Inputs.FACE_POSITION_X: clamp(b.translation.x, -15, 15),
		Inputs.FACE_POSITION_Y: clamp(b.translation.y, -15, 15),
		Inputs.FACE_POSITION_Z: clamp(b.translation.z, -10, 10),
		Inputs.FACE_ANGLE_X: clamp(lerp(a.rotation.y, b.rotation.y, progress), -30, 30),
		Inputs.FACE_ANGLE_Y: clamp(-lerp(a.rotation.x, b.rotation.x, progress), -30, 30),
		Inputs.FACE_ANGLE_Z: clamp(lerp(a.rotation.z, b.rotation.z, progress), -30, 30),
		Inputs.MOUTH_OPEN: clamp(lerp(a.mouthOpen, b.mouthOpen, progress), 0.0, 1.0),
		Inputs.MOUTH_SMILE: clamp(lerp(a.mouthWide, b.mouthWide, progress), 0.0, 1.0),
		Inputs.EYE_OPEN_LEFT: leftOpen,
		Inputs.EYE_OPEN_RIGHT: rightOpen,
		Inputs.EYE_LEFT_X: eyeLeft.x,
		Inputs.EYE_LEFT_Y: eyeLeft.y,
		Inputs.EYE_RIGHT_X: eyeRight.x,
		Inputs.EYE_RIGHT_Y: eyeRight.y,
	}
	
	# adjust to ranges
	for i in Inputs:
		var ord = Inputs[i]
		if ord in mapping:
			pass
			#mapping[ord] = lerp(Ranges[ord].x, Ranges[ord].y, clamp(mapping[ord], 0.0, 1.0))
	
	parameters.merge(mapping, true)
