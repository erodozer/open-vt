## Tracker utilizing mediapipe through Burn VtubeTrackers
## https://codeberg.org/MyriadMinds/vtube-trackers

extends "../blendshape_tracker.gd"

const Serializers = preload("res://lib/utils/serializers.gd")
const AtomicValue = preload("res://lib/utils/atomic.gd").AtomicValue

# Burn Instance
var camera: CameraTexture = CameraTexture.new()
var feed: CameraFeed :
	set(f):
		feed = f
		camera.camera_feed_id = f.get_id()
		
var image: AtomicValue = AtomicValue.new()
var result: AtomicValue = AtomicValue.new()

var handle: int = -1
var kill: bool = false

func _ready():
	# perform inference in a worker thread
	handle = WorkerThreadPool.add_task(_inference_task)
	smoothing = 1.0
	camera.which_feed = CameraServer.FEED_RGBA_IMAGE
			
func start():
	camera.camera_is_active = true
	feed.frame_changed.connect(_on_frame_changed)
	
func stop():
	feed.frame_changed.disconnect(_on_frame_changed)
	camera.camera_is_active = false
	
func _exit_tree() -> void:
	stop()
	kill = true
	feed.frame_changed.disconnect(_on_frame_changed)
			
	if handle != -1:
		WorkerThreadPool.wait_for_task_completion(handle)

func create_config() -> Node:
	var panel = preload("./config.tscn").instantiate()
	panel.tracker = self
	return panel

func _inference_task():
	var detector = VtFaceDetection.new()
	
	while not kill:
		OS.delay_msec(10)
		if not camera.camera_is_active:
			continue
		var data = image.try_get_changed()
		if data == null:
			continue
		
		var blendshapes = detector.submit(data)
		_blendshape_to_update(blendshapes)
	
func _on_frame_changed():
	image.store(camera.get_image())

func _blendshape_to_update(data: Dictionary):
	if not data:
		return
	if not data.blendshapes:
		return
	
	var v = {}
	for i in range(len(data.blendshapes)):
		v[BLENDSHAPE_ENUM[i]] = data.blendshapes[i]
		
	var t: Transform3D = data.transform
	tracker.set_joint_transform(XRBodyTracker.JOINT_HEAD, Transform3D(
		t.basis,
		Vector3.ZERO
	))
	
	tracker.set_joint_transform(XRBodyTracker.JOINT_ROOT, Transform3D(
		Basis(Quaternion.IDENTITY),
		t.origin
	))
	
	update(v)
