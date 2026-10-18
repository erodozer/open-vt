## Tracker utilizing mediapipe through Burn VtubeTrackers
## https://codeberg.org/MyriadMinds/vtube-trackers

extends "../blendshape_tracker.gd"

const Serializers = preload("res://lib/utils/serializers.gd")
const AtomicValue = preload("res://lib/utils/atomic.gd").AtomicValue

# Burn Instance
var camera: CameraTexture = CameraTexture.new()
var img: AtomicValue = AtomicValue.new()
var result: AtomicValue = AtomicValue.new()

var handle: int = -1
var kill: bool = false

func _ready():
	# perform inference in a worker thread
	handle = WorkerThreadPool.add_task(_inference_task)
	
func _exit_tree() -> void:
	kill = true
	if handle != -1:
		WorkerThreadPool.wait_for_task_completion(handle)
	camera.camera_is_active = false

func create_config() -> Node:
	var panel = preload("./config.tscn").instantiate()
	panel.tracker = self
	return panel

func _inference_task():
	var detector = VtFaceDetection.new()
	
	while not kill:
		var data = img.try_get()
		if data == null:
			continue
		var blendshapes = detector.submit(data)
		result.store(blendshapes)

func _process(delta: float) -> void:
	if camera.camera_is_active:
		img.store(camera.get_image())
		
	var blendshapes = result.try_get()
	if blendshapes:
		_blendshape_to_update(blendshapes)

func _blendshape_to_update(data: Dictionary):
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
